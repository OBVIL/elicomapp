<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@taglib prefix="t" tagdir="/WEB-INF/tags" %>
<%@ page import="java.text.*"%>
<%@ page import="java.util.*"%>
<%@ page import="org.apache.lucene.document.Document"%>
<%@ page import="org.apache.lucene.index.IndexReader"%>
<%@ page import="org.apache.lucene.index.Term"%>
<%@ page import="org.apache.lucene.search.*"%>
<%@ page import="org.apache.lucene.util.BitSet"%>
<%@ page import="org.apache.lucene.util.SparseFixedBitSet"%>
<%@ page import="alix.Names" %>
<%@ page import="alix.fr.Tag" %>
<%@ page import="alix.lucene.Alix" %>
<%@ page import="alix.lucene.search.*" %>
<%@ page import="alix.util.*" %>
<%@ page import="alix.web.*" %>
<%
JspTools tools = new JspTools(pageContext);
// count of words for seealso query
int formLen = tools.getInt("words", 30);

StringBuilder body = new StringBuilder();
while(true) {
    if (Alix.pool.size() < 1) {
        body.append("<h1 class=\"error\">Problème d’installation, êtes-vous sûr qu’il y a une a une base indexée ?</h1>\n");
        break;
    }
    Alix alix = (Alix) tools.getMap("base", Alix.pool, null, "alix.base");
    String baseName = request.getParameter("base");
    if (alix == null && baseName != null) {
        body.append("<h1 class=\"error\">Base \"" + baseName + "\" indiponible</h1>");
        break;
    }
    baseName = (String) Alix.pool.keySet().toArray()[0];
    alix = Alix.pool.get(baseName);
    String id = tools.getString("id", null);
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
    final String q = tools.getString("q", null);
    final String text = "text";
    final String f = tools.getString("f", text);
    if (q == null) {
        body.append(doc.doc().get(text));
    }
    else {
        String[] terms = alix.tokenize(q, f);
        body.append(doc.hilite(f, terms));
    }
    body.append("</div>\n");
    // get specific forms
    FormEnum forms = doc.results(f, OptionDistrib.g.scorer(), OptionCat.NOSTOP.tags());
    forms.sort(FormEnum.Order.score, formLen);
    formLen = forms.limit(); // if less than requested
    int[] formIds = new int[formLen];
    forms.reset();
    BooleanQuery.Builder qBuilder = new BooleanQuery.Builder();
    int i = 0;
    while(forms.hasNext()) {
        forms.next();
        Query tq = new TermQuery(new Term(f, forms.form()));
        qBuilder.add(tq, BooleanClause.Occur.SHOULD);
    }
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
    break;
}
request.setAttribute("body", body);
%>
<t:elicom>
    <jsp:attribute name="title">${title} [Elicom]</jsp:attribute>
    <jsp:attribute name="hrefHome"></jsp:attribute>
    <jsp:body>${body}</jsp:body>
</t:elicom>