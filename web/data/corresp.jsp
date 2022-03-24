<%@ page language="java" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="../jsp/elicom.jsp" %>


<%@ page import="java.util.*" %>
<%@ page import="java.util.regex.*" %>

<%@ page import="org.json.*" %>

<%@ page import="org.apache.lucene.analysis.Analyzer"%>
<%@ page import="org.apache.lucene.document.Document"%>
<%@ page import="org.apache.lucene.index.IndexReader"%>
<%@ page import="org.apache.lucene.index.Term"%>
<%@ page import="org.apache.lucene.search.*"%>
<%@ page import="org.apache.lucene.search.BooleanClause.Occur"%>
<%@ page import="org.apache.lucene.util.BitSet"%>

<%@ page import="alix.lucene.Alix" %>
<%@ page import="alix.lucene.analysis.MetaAnalyzer" %>
<%@ page import="alix.lucene.search.*" %>
<%@ page import="alix.web.*" %>

<%!
final static String SENDER = "sender";
final static String RECEIVER = "receiver";
final static Pattern QSPLIT = Pattern.compile("[\\?\\*\\p{L}]+");

%>
<%
// -----------
// data common prelude
long time = System.nanoTime();
JspTools tools = new JspTools(pageContext);
response.setHeader("Access-Control-Allow-Origin", "*"); // cross domain fo browsers
String ext = tools.getStringList("ext", Arrays.asList(new String[]{"", ".ndjson", ".js", ".json"}), "");
String mime = pageContext.getServletContext().getMimeType("a" + ext);
if (mime != null) response.setContentType(mime);
//get an alix instance, output errors
Alix alix = alix(tools, null); 
if (alix == null) {
  return;
}
// -----------

// the field to get a list from
String field = tools.getStringList("f", Arrays.asList(new String[]{SENDER, RECEIVER}), null);
// bad field, send an error ?
if (field == null) {
    out.println("{\"errors\":" + Error.FIELD_NOTFOUND.json() + "}");
    response.setStatus(Error.FIELD_NOTFOUND.status());
    return;
}
String fieldFilter = RECEIVER;
if (RECEIVER.equals(field)) {
    fieldFilter = SENDER;
}


// parameters




String callback = tools.getString("callback", null);
if (!ext.equals(".js")) {
    callback = null;
}
if (callback != null) {
    if (!callback.matches("^\\w+$")) {
        out.println("{\"errors\":" + Error.XSS.json() + "}");
        response.setStatus(Error.XSS.status());
        return;
    }
    out.print(JspTools.escape(callback) +"(");
}

// get a doc filter 
BitSet filter = null;
int clauses = 0;
BooleanQuery.Builder qbuild = new BooleanQuery.Builder();
String[] ids = request.getParameterValues(fieldFilter + "id");
if (ids != null) {
    final FieldFacet facet = alix.fieldFacet(fieldFilter, TEXT);
    for (String id: ids) {
        int facetId = -1;
        try {
            facetId = Integer.parseInt(id);
        }
        catch (Exception e) {
            // output error ?
            continue;
        }
        String value = facet.form(facetId);
        clauses++;
        qbuild.add(new TermQuery(new Term(fieldFilter, value)), Occur.MUST);
    }
}
// get a bitset filter from results of the query
if (clauses > 0) {
    IndexSearcher searcher = alix.searcher();
    CollectorBits qbits = new CollectorBits(searcher);
    searcher.search(qbuild.build(), qbits);
    filter = qbits.bits();
}

// first line
if (".js".equals(ext) || ".json".equals(ext)) {
    out.print("{");
    out.println("  \"data\": [");
}
int limit = tools.getInt("limit", 20);
Pattern hi = null; // hilite 
String q = tools.getString("q", null);
if (q != null) {
    Matcher m = QSPLIT.matcher(q);
    boolean first = true;
    StringBuilder sb = new StringBuilder();
    int parts = 0;
    while (m.find()) {
        if (first) {
            first = false;
        }
        else {
            sb.append("|");
        }
        String group = m.group();
        if (group.length() <= 3) {
            sb.append("\\b");
        }
        sb.append(group);
        parts++;
    }
    if (parts > 0) {
        String re = sb.toString();
        re = re.replaceAll("\\?", "\\\\p{L}").replaceAll("\\*", "\\\\p{L}*");
        try {
            hi = Pattern.compile(re);
        }
        finally{}
    }
}

final FieldFacet facet = alix.fieldFacet(field, TEXT);
FormEnum results = facet.results(filter);
if (filter != null) {
    results.sort(FormEnum.Order.hits);
}
else {
    results.sort(FormEnum.Order.docs);
}
boolean first = true;

// final Chain form = new Chain();
final Chain copy = new Chain();
final StringBuilder hilited = new StringBuilder();
int n = 1;
while (results.hasNext()) {
    results.next();
    final String form = results.form();
    // filter by regex
    if (hi != null) {
        copy.copy(form);
        Char.deligat(copy); // normalize æ,
        String test = Char.toLowASCII((CharSequence)copy); // search pattern in lower ASCII
        Matcher matcher = hi.matcher(test.toString());
        int lastEnd = 0;
        hilited.setLength(0);
        while (matcher.find()) {
            hilited.append(copy.subSequence(lastEnd, matcher.start()));
            hilited.append("<b>");
            hilited.append(copy.subSequence(matcher.start(), matcher.end()));
            hilited.append("</b>");
            lastEnd = matcher.end();
        }
        if (lastEnd == 0) { // nothing found
            continue;
        }
        else if (lastEnd < copy.length()) {
            hilited.append(copy.subSequence(lastEnd, form.length()));
        }
    }
    if (first) {
        first = false;
    }
    else if (".js".equals(ext) || ".json".equals(ext)) {
        out.println(",");
    }
    else {
        out.println();
    }
    out.print("    {");
    out.print("\"n\":" + n);
    out.print(", \"hits\":");
    if (filter != null) {
        out.println(results.hits());
    }
    else {
        out.print(results.docs());
    }
    out.print(", " + "\"form\":" + JSONWriter.valueToString(form));
    if (hi != null) {
        out.print(", " + "\"hilited\":" + JSONWriter.valueToString(hilited.toString()));
    }
    out.print("}");
    if (--limit < 0) {
        break;
    }
    n++;
}

// get terms for doc filter


// last line
if (".js".equals(ext) || ".json".equals(ext)) {
    out.print("\n], \"meta\": {");
    out.print("\"time\": \"" + ( (System.nanoTime() - time) / 1000000) + "ms\"");
    if (hi != null) {
        out.print(", \"hi\": " + JSONWriter.valueToString(hi.pattern()));
    }
    out.print("}");
    out.println("}");
}

if (callback != null) {
    out.print(");");
}
out.println();

%>