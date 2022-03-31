<%@ page language="java" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%!
final static Pattern QSPLIT = Pattern.compile("[\\?\\*\\p{L}]+");
%>
<%
// -----------
// data common prelude
response.setHeader("Access-Control-Allow-Origin", "*"); // cross domain fo browsers
long time = System.nanoTime();
JspTools tools = new JspTools(pageContext);
Alix alix = alix(tools, null); 
if (alix == null) {
  return;
}
String ext = tools.getStringInList("ext", Arrays.asList(new String[]{"", ".ndjson", ".js", ".json"}), "");
String mime = pageContext.getServletContext().getMimeType("a" + ext);
if (mime != null) response.setContentType(mime);
//get an alix instance, output errors
// -----------

// the field to get a list from
final String F = "f";
String field = tools.getStringInList(F, Arrays.asList(new String[]{SENDER, RECEIVER}), null);
if (field == null) {
    out.println("{\"errors\":" + Error.FIELD_NOTFOUND.json(F, request.getParameter(F)) + "}");
    response.setStatus(Error.FIELD_NOTFOUND.status());
    return;
}
String fieldFilter = RECEIVER;
if (RECEIVER.equals(field)) {
    fieldFilter = SENDER;
}
// ids to filter
TreeSet<Integer> idSet = tools.getIntSet(field);





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
// field from which to buil a query filter
Query qFilter = query(alix, tools, GRAPH_PARS);
BitSet filter = filter(alix, qFilter);

// first line
if (".js".equals(ext) || ".json".equals(ext)) {
    out.print("{");
    out.println("  \"data\": [");
}
int limit = tools.getInt("limit", 20);
Pattern hi = null; // hilite 
String glob = tools.getString("glob", null);
if (glob != null) {
    glob = Char.toLowASCII(glob);
    Matcher m = QSPLIT.matcher(glob);
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
    final int formId = results.formId();
    if (idSet.contains(formId)) continue;
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
    hilited.append("<mark>");
    hilited.append(copy.subSequence(matcher.start(), matcher.end()));
    hilited.append("</mark>");
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
    out.print(", \"id\":" + results.formId());
    out.print(", \"hits\":");
    if (filter != null) {
        out.print(results.hits());
    }
    else {
        out.print(results.docs());
    }
    out.print(", " + "\"text\":" + JSONWriter.valueToString(form));
    if (hi != null) {
        out.print(", " + "\"html\":" + JSONWriter.valueToString(hilited.toString()));
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
    out.print(", \"query\": " + JSONWriter.valueToString(qFilter));
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