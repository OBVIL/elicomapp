<%@ page language="java" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%!


private String html(FormEnum forms) {
    String form = forms.form();
    String html = "<a title=\"" + form + "\">" + form +"</a>";
    return html;
}

final static TagFilter tagsStrict = new TagFilter().nostop(true).setGroup(Tag.SUB).setGroup(Tag.NAME);

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
String fname = tools.getString("f", TEXT);
FieldText ftext = alix.fieldText(fname);
TagFilter tags = null;
OptionCat cat = (OptionCat) tools.getEnum("cat", OptionCat.NOSTOP);
if (cat != null) tags = cat.tags();
final int limit = 30;

//--------
// data

FormEnum forms = null;
Query q = query(alix, tools, Set.of(SENDER, RECEIVER, YEAR1, YEAR2));

BitSet filter = null;
if (q != null) {
    IndexSearcher searcher = alix.searcher();
    CollectorBits colBits = new CollectorBits(searcher);
    searcher.search(q, colBits);
    filter = colBits.bits();
    if (filter.cardinality() < 1) filter = null;
}
if (filter == null) {
    forms = ftext.forms(null, tagsStrict, OptionDistrib.TFIDF);
}
else {
    forms = ftext.forms(filter, tagsStrict, OptionDistrib.TFIDF);
}
forms.sort(FormEnum.Order.SCORE, limit);
while (forms.hasNext()) {
    forms.next();
    out.println(html(forms));
}
// FormEnum forms = 

%> 