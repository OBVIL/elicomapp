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
String ext = tools.getStringOf("ext", Set.of(".txt"), ".txt");
String mime = pageContext.getServletContext().getMimeType("a" + ext);
if (mime != null) response.setContentType(mime);
//-----------
// parameters

//-------
// global variables

FieldInt fdate = alix.fieldInt(DATE);
int min = fdate.min();
int max = fdate.max();
float span = max - min;
// -------
boolean first = true;
// get a list of docId in date order from a query
Query q = query(alix, tools, Set.of(CORRES, CORRES1, CORRES2, DATE, Q, RECEIVER, SENDER, YEAR1, YEAR2));
if (q == null) q = new TermQuery(new Term("type", "letter")); // if no query, get all text docs
Sort sort = new Sort(new SortField(DATE, SortField.Type.INT));
TopDocs td = alix.searcher().search(q, Integer.MAX_VALUE, sort, false);
ScoreDoc[] docs = td.scoreDocs;

final int hits = docs.length;

if (hits < 1) {
    return; // no docs found
}

out.println(min);
out.println(max);
out.println(hits);
for (int n = 0; n < hits; n++) {
    final int date = (Integer)((FieldDoc)docs[n]).fields[0];
    out.println(date);
    /*
    final String title = FieldInt.int2date(date);
    final float left = Math.round( 10000.0f * (date - min) / span ) / 100.0f;
    out.println("{\"left\": \"" + left + "%\", \"title\":" +  JSONWriter.valueToString(title) +"}");
    */
}



%>



