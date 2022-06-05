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
TagFilter tags = OptionCat.NOSTOP.tags().clear(0);
int rows = tools.getInt("rows", 5, 100, 10);
int cols = tools.getInt("cols", 1, 50, 15);
OptionDistrib distrib = OptionDistrib.BM25;

//-------
// global variables

FieldText ftext = alix.fieldText(TEXT);
// -------
boolean first = true;
// get a list of docId in date order from a query
Query q = query(alix, tools, Set.of(CORRES, CORRES1, CORRES2, DATE, SENDER, RECEIVER, YEAR1, YEAR2));
if (q == null) q = new TermQuery(new Term("type", "letter")); // if no query, get all text docs
Sort sort = new Sort(new SortField(YEAR, SortField.Type.INT));
TopDocs td = alix.searcher().search(q, Integer.MAX_VALUE, sort, false);
ScoreDoc[] docs = td.scoreDocs;



final int hits = docs.length;

if (hits < 1) {
    return; // no docs found
}
if (hits < rows) {
    cols = hits;
}

double part = (double) (hits + 1) / cols;
double cumul = part;
int year1 = Integer.MIN_VALUE;
first = true;
// prepare the classifier for each col
int[] classifier = new int[alix.maxDoc()];
Arrays.fill(classifier, -1); // -1 is empty, do not forget
int col = 0;
String[] header = new String[cols];


for (int n = 0; n < hits; n++) {
    final int docId = docs[n].doc;
    classifier[docId] = col;
    if (year1 == Integer.MIN_VALUE) year1 = (Integer)((FieldDoc)docs[n]).fields[0];
    if (n < cumul && n!= hits - 1) continue;
    
    // a column;
    int year2 = (Integer)((FieldDoc)docs[n]).fields[0];
    
    if (cols == 1) {
        header[col] = ""+year1+"…"+year2; 
    }
    if (n == hits - 1) {
        header[col] = ""+year2; 
    }
    else {
        header[col] = ""+year1;
    }
    year1 = Integer.MIN_VALUE;
    col++;
    cumul = part * (col + 1);
}

// get dics from the classifier
FormEnum[] dics = ftext.forms(cols, classifier, tags, OptionDistrib.TFIDF); // 200 ms


// loop on all call
for(col = 0; col < cols; col++) {
    out.println("<div class=\"colchron\">");
    if (cols == 1) out.println("<header>" + header[col] + "</header>");
    else if (col == 0) out.println("<header class=\"first\">" + header[col] + "…</header>");
    else if (col == cols-1) out.println("<header class=\"last\">…" + header[col] + "</header>");
    else out.println("<header>" + header[col] + "…</header>");
    FormEnum forms = dics[col];
    // forms.score(OptionDistrib.BM25);
    forms.sort(FormEnum.Order.SCORE, rows); // limit rows is nmore efficient
    int wc = rows;
    while (forms.hasNext()) {
        forms.next();
        if (--wc < 0) break;
        int formId = forms.formId();
        out.print("<a class=\"w\" title=\"fréquence : " + forms.freq() + ", score : " + forms.score() +", rang : " + formId +", tag :" + Tag.label(forms.tag()) +"\">" + forms.form() + "</a> ");
    }
    out.println("</div>");
    out.flush();
}

out.println( "<!-- " + (System.nanoTime() - time) / 1000000 + "ms -->");

%>



