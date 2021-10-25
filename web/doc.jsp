<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="alix.lucene.search.Doc" %>
<%@ page import="org.apache.lucene.search.similarities.*" %>
<%@ page import="alix.util.Top" %>
<%@include file="jsp/prelude.jsp" %>
<%
// paramétrer
final String BIBL = "title";


// params for the page
int max = 100;
pars.limit = tools.getInt("limit", 50);
if (pars.limit > max) pars.limit = max;
// best words for query, no names
pars.cat = (Cat)tools.getEnum("cat", Cat.STRONG);

int docId = tools.getInt("docid", -1); // get doc by lucene internal docId or persistant String id
String id = tools.getString("id", "");
String q = tools.getString("q", null); // if no doc, get params to navigate in a results series

String field = "text";

Doc doc = null;
try { // load full document
  if (!id.isEmpty()) {
    doc = new Doc(alix, id);
    docId = doc.docId();
  }
  else if (docId >= 0) {
    doc = new Doc(alix, docId);
    id = doc.id();
  }
}
catch (IllegalArgumentException e) { // doc not found
  id = "";
}



// bibl ref with no tags
String title = "";
if (doc != null) title = ML.detag(doc.doc().get("scope"));

SortField sf2 = new SortField(Alix.ID, SortField.Type.STRING);
%>
<!DOCTYPE html>
<html class="document">
  <head>
    <%@ include file="local/head.jsp" %>
    <title>Livres</title>
    <script>
<%
if (doc != null) { // document id is verified, give it to javascript
  out.println("var docLength = " + doc.length(field) + ";");
  out.println("var docId = \""+doc.id()+"\";");
}
%>
    </script>
  </head>
  <body class="document">
    <header>
      <%@ include file="local/tabs.jsp" %>
    </header>
    <main>
      <div class="row">
        <nav class="terms" id="sidebar">
        <%
        Query mlt = null;
        int qmax = 30;
        if (doc != null) {
          out.println(" <h5>Mots clés</h5>");
          BooleanQuery.Builder qBuilder = new BooleanQuery.Builder();
          FormEnum forms = doc.results(field, pars.distrib.scorer(), pars.cat.tags());
          forms.sort(FormEnum.Sorter.score, pars.limit, false);
          int no = 1;
          forms.reset();
          while (forms.hasNext()) {
            forms.next();
            String form = forms.form();
            if (form.trim().isEmpty()) continue;
            out.print("<a title=\"score : " + formatScore(forms.score()) + "\" href=\"?id=" + id + "&amp;q=" + JspTools.escape(form) + "\" class=\"form\">");
            // out.print(dfscore.format(forms.score()) + " ");
            out.print(forms.form());
            out.print(" <small>(" + forms.freq() + ")</small>");
            out.println("</a>");
            if (no < qmax) {
              double width = 5;
              double factor = width *(qmax - no) / (qmax) - width/2;
              float boost = (float)Math.pow(10, factor );
              Query tq = new TermQuery(new Term(field, forms.form()));
              // tq = new BoostQuery(tq, boost);
              qBuilder.add(tq, BooleanClause.Occur.SHOULD);
            }
            no++;
          }
          mlt = qBuilder.build();
        }
        %>
        </nav>
        <div class="text">
    <%
    if (doc != null) {
      out.println("<div class=\"heading\">");
      out.println(doc.doc().get(BIBL));
      out.println("</div>");
      // mlt
      
      
      // hilite
      if (!"".equals(q)) {
        String[] terms = alix.forms(q, field);
        out.print(doc.hilite(field, terms));
      }
      else {
        out.print(doc.doc().get(field));
      }
        }
    %>
        
        </div>
        <nav class="seealso">
          <%
if (mlt != null) {
  out.println("<h5>Sur les mêmes sujets…</h5>");
  IndexSearcher searcher = alix.searcher();
  // out.print(searcher.getSimilarity());
  //test has been done, BM25 seems the best
  // Similarity oldSim = searcher.getSimilarity();
  // searcher.setSimilarity(new LMDirichletSimilarity());
  // searcher.setSimilarity(sim.similarity()); 
  TopDocs topDocs;
  topDocs = searcher.search(mlt, 20);
  // searcher.setSimilarity(oldSim);
  ScoreDoc[] hits = topDocs.scoreDocs;
  final String href = "?id=";
  final HashSet<String> DOC_SHORT = new HashSet<String>(Arrays.asList(new String[] {Alix.ID, Alix.BOOKID, BIBL}));
  for (ScoreDoc hit: hits) {
    if (hit.doc == docId) continue;
    Document aDoc = reader.document(hit.doc, DOC_SHORT);
    out.print("<div class=\"bibl\">");
    out.print("<a href=\"" + href + aDoc.get(Alix.ID) +"\">");
    out.print(aDoc.get(BIBL));
    out.print("</a>");
    out.print("</div>");
  }
}
          %>
          
        </nav>
      </div>
    </main>
    <% out.println("<!-- time\" : \"" + (System.nanoTime() - time) / 1000000.0 + "ms\" -->"); %>
    <script src="<%= hrefHome %>static/alix.js">//</script>
  </body>
</html>
