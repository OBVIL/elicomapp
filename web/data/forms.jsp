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
String ext = tools.getStringOf("ext", Set.of(".ndjson", ".js", ".json"), ".js");
String mime = pageContext.getServletContext().getMimeType("a" + ext);
if (mime != null) response.setContentType(mime);
// get an alix instance, errors will be outputed
Alix alix = alix(tools, null); 
if (alix == null) {
    return;
}
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
// -----------
// parameters
String fname = tools.getString(F, null);
int limit = tools.getInt("limit", 20);
String glob = tools.getString("glob", null); // highlighter in terms
//-----------
// check parameters
if (fname == null) {
    out.println("{\"errors\":" + Error.FIELD_NONE.json(F) + "}");
    response.setStatus(Error.FIELD_NOTFOUND.status());
    return;
}
String ftype = alix.ftype(fname);
if (Names.NOTFOUND.equals(ftype)) {
    out.println("{\"errors\":" + Error.FIELD_NOTFOUND.json(F, fname) + "}");
    response.setStatus(Error.FIELD_NOTFOUND.status());
    return;
}
// !Names.FACET.equals(ftype) 
if (!Names.FACET.equals(ftype) && !Names.TEXT.equals(ftype)) {
// if (true) {
    out.println("{\"errors\":" + Error.FIELD_BADTYPE.json(F, fname, ftype) + "}");
    response.setStatus(Error.FIELD_NOTFOUND.status());
    org.apache.lucene.index.FieldInfos fieldInfos = org.apache.lucene.index.FieldInfos.getMergedFieldInfos(alix.reader());
    org.apache.lucene.index.FieldInfo info = fieldInfos.fieldInfo(fname);
    out.println("indexOptions="+info.getIndexOptions());
    out.println("docValues="+info.getDocValuesType());
    return;
}

// get a field by type
FieldText ftext = null;
FieldFacet facet = null;
if (Names.TEXT.equals(ftype)) {
    ftext = alix.fieldText(fname);
}
else if (Names.FACET.equals(ftype)) {
    facet = alix.fieldFacet(fname, null);
}

BitSet filter = null;
// A generic way for filtering ?
// Query qFilter = query(alix, tools, GRAPH_PARS);
// BitSet filter = filter(alix, qFilter);

// first line
if (".js".equals(ext) || ".json".equals(ext)) {
    out.print("{");
    out.println("  \"data\": [");
}
Pattern hi = null; // hilite 
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

FormEnum results = null;
if (facet != null) {
    results = facet.forms(filter);
}
else if (ftext != null) {
    results = ftext.forms(filter);
}
// better sort order ?
if (ftext != null) {
    results.sort(FormEnum.Order.FREQ);
}
else if (filter != null) {
    results.sort(FormEnum.Order.HITS);
}
else {
    results.sort(FormEnum.Order.DOCS);
}
boolean first = true;

// final Chain form = new Chain();
final Chain copy = new Chain();
final StringBuilder hilited = new StringBuilder();
int rank = 1;
while (results.hasNext()) {
    results.next();
    final int formId = results.formId();
    // filter values ?
    // if (idSet.contains(formId)) continue;
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
    out.print("\"rank\":" + rank);
    out.print(", \"text\":" + JSONWriter.valueToString(form));
    out.print(", \"id\":" + results.formId());
    out.print(", \"occs\":" + results.occs());
    out.print(", \"freq\":" + results.freq());
    out.print(", \"docs\":" + results.docs());
    out.print(", \"hits\":" + results.hits());
    if (hi != null) {
        out.print(", " + "\"html\":" + JSONWriter.valueToString(hilited.toString()));
    }
    out.print("}");
    if (--limit <= 0) {
        break;
    }
    rank++;
}

// get terms for doc filter


// last line
if (".js".equals(ext) || ".json".equals(ext)) {
    out.print("\n], \"meta\": {");
    out.print("\"time\": \"" + ( (System.nanoTime() - time) / 1000000) + "ms\"");
    /*
    if (qFilter != null) {
        out.print(", \"filter\": " + JSONWriter.valueToString(qFilter));
    }
    */
    out.print(", \"field\":" +  JSONWriter.valueToString(results.name));
    out.print(", \"type\":" +  JSONWriter.valueToString(ftype));
    out.print(", \"docsAll\":" + results.docs);
    out.print(", \"occsAll\":" + results.occs);
    out.print(", \"values\":" + results.maxForm);
    if (hi != null) {
        out.print(", \"hi\":" + JSONWriter.valueToString(hi.pattern()));
    }
    out.print("}");
    out.println("}");
}

if (callback != null) {
    out.print(");");
}
%>