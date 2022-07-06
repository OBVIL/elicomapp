<%@ page language="java" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%!


private String html(FormEnum forms) {
    String form = forms.form();
    String html = "<a title=\"" + form + "\">" + form +"</a>";
    return html;
}


%>
<%
// -----------
// data common prelude
response.setHeader("Access-Control-Allow-Origin", "*"); // cross domain fo browsers
long time = System.nanoTime();
JspTools tools = new JspTools(pageContext);
String ext = tools.getStringOf("ext", Set.of(".html", ""), "");
String mime = pageContext.getServletContext().getMimeType("a" + ext);
if (mime != null) response.setContentType(mime);
// get an alix instance, errors will be outputed
Alix alix = alix(tools, null); 
if (alix == null) {
    return;
}
//-----------
// parameters
final String q = tools.getString(Q, null);
String fname = tools.getString("f", TEXT);
FieldText ftext = alix.fieldText(fname);
TagFilter tags = null;
OptionCat cat = (OptionCat) tools.getEnum("cat", OptionCat.NOSTOP);
if (cat != null) tags = cat.tags();
final int limit = 30;

//--------
// data

FormEnum forms = null;
Query qfilter = query(alix, tools, Set.of(SENDER, RECEIVER, YEAR1, YEAR2));

BitSet filter = null;
if (qfilter != null) {
    IndexSearcher searcher = alix.searcher();
    CollectorBits colBits = new CollectorBits(searcher);
    searcher.search(qfilter, colBits);
    filter = colBits.bits();
    if (filter.cardinality() < 1) filter = null;
}

String[] words = alix.tokenize(q, TEXT);
int[] pivotIds = ftext.formIds(words, filter);

/*
if (q == null) {
    dic = ftext.forms(filter, cat.tags(), distrib);
    dic.sort(OptionOrder.SCORE.order(), count);
} 
else if (pivotIds == null) {
    // what should be done here ?
}
*/

if (pivotIds != null && pivotIds.length > 0) {
    final int left = 5;
    final int right = 5;
    OptionMI mi = OptionMI.JACCARD;
    FieldRail rail = alix.fieldRail(fname);
    forms = ftext.forms();
    forms.filter = filter; // corpus
    forms.tags = tags;
    long found = rail.coocs(forms, pivotIds, left, right, mi); // populate the wordlist
}
else if (filter == null) {
    forms = ftext.forms(null, tags, OptionDistrib.TFIDF);
}
else {
    forms = ftext.forms(filter, tags, OptionDistrib.TFIDF);
}
forms.sort(FormEnum.Order.SCORE, limit);
if (pivotIds != null) Arrays.sort(pivotIds);
while (forms.hasNext()) {
    forms.next();
    if (forms.freq() < 1) break;
    // pass found 
    if (pivotIds != null && Arrays.binarySearch(pivotIds, forms.formId()) >= 0 ) continue;
    out.println(html(forms));
}

%> 