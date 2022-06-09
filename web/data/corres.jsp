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
String ext = tools.getStringOf("ext", Set.of("", ".ndjson", ".js", ".json"), "");
String mime = pageContext.getServletContext().getMimeType("a" + ext);
if (mime != null) response.setContentType(mime);
//get an alix instance, output errors
// -----------

// the field to get a list from
final String F = "f";
String fpar = tools.getStringOf(F, Set.of(CORRES1, CORRES2, RECEIVER, SENDER), null);


if (fpar == null) {
    out.println("{\"errors\":" + Error.FIELD_NOTFOUND.json(F, request.getParameter(F)) + "}");
    response.setStatus(Error.FIELD_NOTFOUND.status());
    return;
}
String fname = fpar;
Set<Integer> idHide = tools.getIntSet(fpar); // ids to not display
Set<String> qpars = null;
if (RECEIVER.equals(fpar)) {
    idHide = tools.getIntSet(fpar);
    qpars = Set.of(Q, SENDER, YEAR1, YEAR2);
}
else if (SENDER.equals(fpar)) {
    qpars = Set.of(Q, RECEIVER, YEAR1, YEAR2);
    idHide = tools.getIntSet(fpar);
}
else if (CORRES1.equals(fpar)) {
    fname = CORRES;
    qpars = Set.of(Q, CORRES2, YEAR1, YEAR2);
    idHide = tools.getIntSet(CORRES1);
    idHide.addAll(tools.getIntSet(CORRES2));
}
else if (CORRES2.equals(fpar)) {
    fname = CORRES;
    qpars = Set.of(Q, CORRES1, YEAR1, YEAR2);
    idHide = tools.getIntSet(fpar);
    idHide = tools.getIntSet(CORRES1);
    idHide.addAll(tools.getIntSet(CORRES2));
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
// field from which to build a query filter
Query qFilter = query(alix, tools, qpars);
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

final FieldFacet facet = alix.fieldFacet(fname);
FormEnum forms = facet.forms(filter);
if (filter != null) {
    forms.sort(FormEnum.Order.HITS);
}
else {
    forms.sort(FormEnum.Order.DOCS);
}
boolean first = true;

// final Chain form = new Chain();
final Chain copy = new Chain();
final StringBuilder hilited = new StringBuilder();
int n = 1;
while (forms.hasNext()) {
    forms.next();
    final int formId = forms.formId();
    if (idHide.contains(formId)) continue;
    final String form = forms.form();
    
    // zero score
    if (filter != null && forms.hits() < 1) {
        break;
    }
    
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
    out.print(", \"id\":" + forms.formId());
    out.print(", \"hits\":");
    if (filter != null) {
        out.print(forms.hits());
    }
    else {
        out.print(forms.docs());
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
out.println("");
if (".js".equals(ext) || ".json".equals(ext)) {
    out.print("], \"meta\": ");
}
out.print("{");
out.print("\"time\": \"" + ( (System.nanoTime() - time) / 1000000) + "ms\"");
out.print(", \"query\": " + JSONWriter.valueToString(qFilter));
out.print(", \"cardinality\": " + forms.cardinality());
if (hi != null) {
    out.print(", \"hi\": " + JSONWriter.valueToString(hi.pattern()));
}
out.print("}");
if (".js".equals(ext) || ".json".equals(ext)) {
    out.println("}");
}

if (callback != null) {
    out.print(");");
}
%>