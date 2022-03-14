<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="jsp/elicom.jsp" %>
<%@taglib prefix="t" tagdir="/WEB-INF/tags" %>

<%@ page import="org.apache.lucene.document.Document"%>
<%@ page import="org.apache.lucene.index.IndexReader"%>
<%@ page import="org.apache.lucene.index.Term"%>
<%@ page import="org.apache.lucene.search.*"%>
<%@ page import="org.apache.lucene.util.BitSet"%>
<%@ page import="org.apache.lucene.util.SparseFixedBitSet"%>

<%
JspTools tools = new JspTools(pageContext);
StringBuilder body = new StringBuilder();
request.setAttribute("body", body); // used by the template tag
Alix alix = alix(tools, body); // get an alix instance, body could be populated by errors

// count of words for seealso query
int formLen = tools.getInt("words", 30);


while(alix != null) {
    
    
    String id = request.getParameter("id");
    if (id == null) {
        body.append("<h1 class=\"error\">Aucun document demandé</h1>");
        break;
    }
    int docId = alix.getDocId(id);
    if (docId < 0) {
        body.append("<h1 class=\"error\">Document \"" + id + "\" non trouvé</h1>");
        break;
    }
    final Doc doc = new Doc(alix, docId);
    request.setAttribute("title", doc.doc().get("bibl")); // transmitted to template

    body.append("<div class=\"text\">\n");
    body.append("<div class=\"bibl\">");
    body.append(doc.doc().get("bibl"));
    body.append("</div>\n");
    
    StringBuilder keywords = new StringBuilder();
    keywords.append("<p class=\"keywords\">");
    // get specific forms
    final String text = "text";
    final String f = tools.getString("f", text);
    FormEnum forms = doc.results(f, OptionDistrib.g.scorer(), OptionCat.NOSTOP.tags());
    forms.sort(FormEnum.Order.score, formLen);
    formLen = forms.limit(); // if less than requested
    int[] formIds = new int[formLen];
    forms.reset();
    BooleanQuery.Builder qBuilder = new BooleanQuery.Builder();
    int i = 0;
    boolean first = true;
    while(forms.hasNext()) {
        forms.next();
        if (first) {
            first = false;
        }
        else {
            keywords.append(", ");
        }
        keywords.append(forms.form());
        
        Query tq = new TermQuery(new Term(f, forms.form()));
        qBuilder.add(tq, BooleanClause.Occur.SHOULD);
    }
    keywords.append("</p>");
    
    final String q = request.getParameter("q");
    if (q == null) {
        body.append(doc.doc().get(text));
    }
    else {
        String[] terms = alix.tokenize(q, f);
        body.append(doc.hilite(f, terms));
    }
    body.append("</div>\n");
    Query mlt = qBuilder.build();
    body.append("<nav class=\"seealso\">\n");
    body.append("<h5>Sur les mêmes sujets…</h5>\n");
    IndexSearcher searcher = alix.searcher();
    TopDocs topDocs;
    topDocs = searcher.search(mlt, 20);
    ScoreDoc[] hits = topDocs.scoreDocs;
    final String href = "?id=";
    final HashSet<String> DOC_SHORT = new HashSet<String>(Arrays.asList(new String[] {Names.ALIX_ID, Names.ALIX_BOOKID, "bibl"}));
    for (ScoreDoc hit: hits) {
        if (hit.doc == docId) continue;
        Document aDoc = alix.reader().document(hit.doc, DOC_SHORT);
        body.append("<a class=\"bibl\" href=\"" + href + aDoc.get(Names.ALIX_ID) +"\">");
        body.append(aDoc.get("bibl"));
        body.append("</a>");
    }
    break; // !! KEEP IT
}
%>
<t:elicom>
    <jsp:attribute name="title">${title} [Elicom]</jsp:attribute>
    <jsp:attribute name="hrefHome"></jsp:attribute>
    <jsp:body>${body}</jsp:body>
</t:elicom>