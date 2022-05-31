<%@ page language="java" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="alix.util.Edge" %>
<%@ page import="alix.util.EdgeSquare" %>

<%!



%>
<%
//-----------
//data common prelude
response.setHeader("Access-Control-Allow-Origin", "*"); // cross domain fo browsers
long time = System.nanoTime();
JspTools tools = new JspTools(pageContext);
Alix alix = alix(tools, null); 
if (alix == null) {
    return;
}
String ext = tools.getStringOf("ext", Set.of(""), "");
String mime = pageContext.getServletContext().getMimeType("a" + ext);
if (mime != null) response.setContentType(mime);
//-----------
// parameters
String field = tools.getString("f", TEXT);
TagFilter tags = null;
OptionCat cat = (OptionCat) tools.getEnum("cat", OptionCat.NOSTOP);
if (cat != null) tags = cat.tags();

// number of words between corres
final int wordCount = tools.getInt("words", 50);
final int hstop = tools.getInt("hstop", -1);
OptionDistrib distrib = (OptionDistrib) tools.getEnum("distrib", OptionDistrib.TFIDF);
OptionMI mi = (OptionMI) tools.getEnum("mi", OptionMI.JACCARD);
//-----------
// check parameters
//-----------
int wc;
boolean first;

final FieldText ftext = alix.fieldText(field);
final FieldInt fyear = alix.fieldInt(YEAR);

final Set<Integer> corres1 = tools.getIntSet("corres1");
final Set<Integer> corres2 = tools.getIntSet("corres2");
if (corres1.size() < 1 && corres2.size() < 1) {
    out.println("<div class=\"center\">");
    // mots
    FormEnum forms = ftext.forms(null, tags, OptionDistrib.TFIDF);
    forms.sort(FormEnum.Order.SCORE);
    wc = wordCount * 2;
    first = true;
    while (forms.hasNext()) {
        forms.next();
        if (--wc < 0) break;
        int formId = forms.formId();
        if (first) first = false;
        else out.println(", ");
        out.print("<a class=\"w\" title=\"fréquence : " + forms.freq() + ", score : " + forms.score() +", rang : " + formId +"\">" + forms.form() + "</a>");
    }
    out.println("</div>");
    
    return;
}

final FieldFacet corresFacet = alix.fieldFacet(CORRES);
final List<String> c1Forms = new ArrayList<>(corres1.size());
for (int formId: corres1) {
    String form = corresFacet.form(formId);
    if (form == null) continue;
    c1Forms.add(form);
}
final List<String> c2Forms = new ArrayList<>(corres2.size());
for (int formId: corres2) {
    String form = corresFacet.form(formId);
    if (form == null) continue;
    c2Forms.add(form);
}
final FieldFacet senderFacet = alix.fieldFacet(SENDER);
final FieldFacet receiverFacet = alix.fieldFacet(RECEIVER);

Query qYear = yearQuery(alix, tools);


BooleanQuery.Builder builder;
BooleanQuery.Builder b;
Query q;

// build left query

builder = new BooleanQuery.Builder();

b = new BooleanQuery.Builder();
for (String form: c1Forms) b.add(new TermQuery(new Term(SENDER, form)), Occur.SHOULD);
q = rewrite(b.build());
if (q != null) builder.add(q, Occur.MUST);

b = new BooleanQuery.Builder();
for (String form: c2Forms) b.add(new TermQuery(new Term(RECEIVER, form)), Occur.SHOULD);
q = rewrite(b.build());
if (q != null) builder.add(q, Occur.MUST);

if (qYear != null) builder.add(qYear, Occur.MUST);
Query leftQuery = rewrite(builder.build());

//build right query

builder = new BooleanQuery.Builder();
b = new BooleanQuery.Builder();
for (String form: c1Forms) b.add(new TermQuery(new Term(RECEIVER, form)), Occur.SHOULD);
q = rewrite(b.build());
if (q != null) builder.add(q, Occur.MUST);

b = new BooleanQuery.Builder();
for (String form: c2Forms) b.add(new TermQuery(new Term(SENDER, form)), Occur.SHOULD);
q = rewrite(b.build());
if (q != null) builder.add(q, Occur.MUST);

if (qYear != null) builder.add(qYear, Occur.MUST);
Query rightQuery = rewrite(builder.build());


int[] minmax;
FormEnum forms;



// left
BitSet leftFilter = filter(alix, leftQuery);
FormEnum leftForms = ftext.forms(leftFilter, tags, distrib);
out.println("<div class=\"left\" style=\"text-align: left\">");
out.print("<h5 title=\"" + leftQuery +"\">" + leftFilter.cardinality() + " lettres ");
minmax = fyear.minmax(leftFilter);
out.print( ((minmax[0]==Integer.MAX_VALUE)?"":minmax[0]) + "–" + ((minmax[1]==Integer.MIN_VALUE)?"":minmax[1]));
out.println("</h5>");
if (leftFilter.cardinality() > 0) {
    leftForms.sort(FormEnum.Order.SCORE);
    wc = wordCount;
    first = true;
    forms = leftForms;
    while (forms.hasNext()) {
        forms.next();
        if (--wc < 0) break;
        int formId = forms.formId();
        if (first) first = false;
        else out.println(", ");
        out.print("<a class=\"w\" title=\"fréquence : " + forms.freq() + ", score : " + forms.score() +", rang : " + formId +"\">" + forms.form() + "</a>");
    }
}


out.println("</div>");

/*
// center
out.println("<div class=\"center\" style=\"text-align: center\">");
out.print("<h5>Mots partagés</h5>");
TopArray top = new TopArray(wordCount);
double leftCeil = leftForms.scoreByRank(wordCount);
double rightCeil = rightForms.scoreByRank(wordCount);
for (int formId = 0, max = ftext.maxForm; formId < max; formId++) {
    double leftScore = leftForms.score(formId);
    if (leftScore > leftCeil) continue;
    double rightScore = rightForms.score(formId);
    if (rightScore > rightCeil) continue;
    double score = (leftScore + rightScore) / 2;
    top.push(formId, score);
}
first = true;
for (IdScore rec: top) {
    final int formId = rec.id();
    if (first) first = false;
    else out.println(", ");
    out.print("<a class=\"w\" title=\"fréquences : " + leftForms.freq(formId) + ", " + rightForms.freq(formId) + " score : " + rec.score() +", rang : " + formId +"\">" + ftext.form(formId) + "</a>");
    
}
out.println("</div>");
*/

// right
out.println("<div class=\"right\" style=\"text-align: right\">");
BitSet rightFilter = filter(alix, rightQuery);
out.print("<h5 title=\"" + rightQuery +"\">" + rightFilter.cardinality() + " lettres ");
minmax = fyear.minmax(rightFilter);
out.print( ((minmax[0]==Integer.MAX_VALUE)?"":minmax[0]) + "–" + ((minmax[1]==Integer.MIN_VALUE)?"":minmax[1]));
out.println("</h5>");

if (rightFilter.cardinality() > 0) {
    FormEnum rightForms = ftext.forms(rightFilter, tags, distrib);
    rightForms.sort(FormEnum.Order.SCORE);

    wc = wordCount;
    first = true;
    forms = rightForms;
    while (forms.hasNext()) {
        forms.next();
        int formId = forms.formId();
        if (--wc < 0) break;
        if (first) first = false;
        else out.println(", ");
        out.print("<a class=\"w\" title=\"fréquence : " + forms.freq() + ", score : " + forms.score() +", rang : " + formId +"\">" + forms.form() + "</a>");
    }
    
}
out.println("</div>");

%>



