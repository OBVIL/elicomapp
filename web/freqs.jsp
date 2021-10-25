<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="jsp/prelude.jsp" %>
<%
pars.limit = tools.getInt("limit", 200);
if (pars.limit < 0) pars.limit = 1;
if (pars.limit > 1000) pars.limit = 1000;
FormEnum results = freqList(alix, pars);
results.sort(pars.order.sorter(), pars.limit);
%>
<!DOCTYPE html>
<html>
  <head>
   <%@ include file="local/head.jsp"%>
    <title><%=alix.props.get("label")%> [Elicom]</title>
  </head>
  <body>
    <header id="top">
      <%@ include file="local/tabs.jsp"%>
      <form class="search" action="#">
        <a  class="icon" href="csv.jsp?<%= tools.url(new String[]{"q", "cat", "book", "left", "right", "distrib", "mi"}) %>"><img src="static/icon_csv.svg" alt="Export intégral des données au format "></a>
        <a class="icon" href="tableur.jsp?<%= tools.url(new String[]{"q", "cat", "book", "left", "right", "distrib", "mi", "limit"}) %>"><img src="static/icon_excel.svg" alt="Export des données visibles pour Excel"></a>
        <label for="cat" title="Filtrer les mots par catégories grammaticales">filtre</label>
        <select name="cat" onchange="this.form.submit()">
          <option/>
          <%=pars.cat.options()%>
        </select>
             <%
             /*
        <label for="distrib" title="Algorithme d’ordre des mots sélectionné">Score</label>
        <select name="distrib" onchange="this.form.submit()">
          <option/>
          pars.distrib.options()
        </select>
             
               if (pars.book == null && pars.q == null) out.println (pars.ranking.options("occs bm25 tfidf"));
                    // else out.println (pars.ranking.options("occs bm25 tfidf g chi2"));
                    else out.println (pars.ranking.options());
                    <label for="mi" title="Algorithme de score pour les liens">Dépendance</label>
                    <select name="mi" onchange="this.form.submit()">
                      <option/>
                      pars.mi.options()
                    </select>

                    */
             %>
        <label for="order" title="Sélectionner et ordonner le tableau selon une colonne">rangés par</label>
        <select name="order" onchange="this.form.submit()">
          <option/>
          <%
          if (pars.book != null || pars.q != null) out.println(pars.order.options("freq hits score occs docs"));
          else out.println(pars.order.options("freq hits score "));
          %>
        </select>
      </form>
    </header>
    <main>
      <table class="sortable" width="100%">
        <caption>
        Lecture :
        <%
        String title = null;
        if (pars.book != null && !pars.book.trim().equals("")) {
          int docId = alix.getDocId(pars.book);
          Document doc = reader.document(docId, BOOK_FIELDS);
          title = doc.get("title");
        }
        boolean multiw = false;
        if (pars.q != null && pars.q.trim().contains(" ")) multiw=true;

        
        if (results.limit() < 1) {
          if (pars.q != null && title != null) out.println("<b>"+pars.q+"</b> — introuvable dans <em>"+title+"</em>");
          else if (pars.q != null) out.println("<b>"+pars.q+"</b> — introuvable dans le copus");
          else out.println("Cas non prévu par le développeur. Bug ?");
        }
        else {
          int rank = 1;
          out.println("au rang "+(rank + 1)+" la graphie <strong>"+results.formByRank(rank)+"</strong> ");
          if (pars.book != null && !pars.book.trim().equals("")) out.println("<br/>— dans <em>" +title+"</em>");
          if (pars.q != null) out.println("<br/>— au voisinage de <em>" + pars.q + "</em> ("+pars.left+ " mots à gauche, " + pars.right + " mots à droite)");
          out.println("<br/>— " + frdec.format(results.freqByRank(rank)) + " occurrences");
          if (pars.q != null || pars.book != null) out.println(" (sur " + frdec.format(results.occsByRank(rank)) + " dans la totalité du corpus)");
          out.println("<br/>— " + frdec.format(results.hitsByRank(rank)) +" textes trouvés");
          if (pars.q != null || pars.book != null) out.println(" (sur les " + frdec.format(results.docsByRank(rank)) +" du corpus qui contiennent ce mot)");
        }
        %>
        </caption>
        <thead>
          <tr>
            <th/>
            <th title="Forme graphique indexée" class="form">Graphie</th>
            <th title="Catégorie grammaticale">Catégorie</th>
            <th title="Nombre d’occurrences trouvées" class="num"> Occurrences</th>
            <% if (pars.book != null || pars.q != null) out.println("<th title=\"Sur total des occurences de cette graphie\" class=\"all\">/occurrences</td>"); %>
            <th title="Nombre de chapitres-articles contenant la grahie" class="num"> Textes</th>
            <% if (pars.book != null || pars.q != null) out.println("<th title=\"Nombre total de textes contenant le mot\" class=\"all\">/textes</th>"); %>
            <th title="Score de pertinence selon l’algorithme" class="num"> Score</th>
            <th width="100%"/>
            <th/>
          </tr>
        </thead>
        <tbody>
          <%
            // todo, book selector
          String urlForm = "conc.jsp?" + tools.url(new String[]{"book"}) + "&amp;q=";
          // String urlOccs = "kwic.jsp?" + tools.url(new String[]{"left", "right", "ranking"}) + "&amp;q=";
          int no = 0;
          results.reset();
          while (results.hasNext()) {
            results.next();
            no++;
            String term = results.form();
            int flag = results.tag();
            String css = "word";
            if (flag == Tag.SUB.flag) css = "SUB";
            else if (flag == Tag.ADJ.flag) css = "ADJ";
            else if (flag == Tag.VERB.flag) css = "VERB";
            else if (Tag.NAME.sameParent(flag)) css = "NAME";
            // .replace('_', ' ') ?
            out.println("  <tr>");
            out.println("    <td class=\"no left\">"  + no + "</td>");
            out.println("    <td class=\"form\">");
            out.print("      <a");
            out.print(" class=\"" + css + "\"");
            out.print(" href=\"" + urlForm + JspTools.escUrl(term) + "\"");
            out.print(">");
            out.print(term);
            out.print("</a>");
            out.println("    </td>");
            
            out.print("    <td class=\"cat lo\">");
            out.print(Tag.label(flag));
            out.println("</td>");
            
            out.print("    <td class=\"num\">");
            out.print(frdec.format(results.freq()));
            out.println("</td>");

            if (pars.book != null || pars.q != null) {
              out.print("    <td class=\"all\">");
              out.print("/ "+frdec.format(results.occs()));
              out.println("</td>");
            }

            out.print("    <td class=\"num\">");
            if (results.hits() > 0) out.print(frdec.format(results.hits()));
            out.println("</td>");
            
            if (pars.book != null || pars.q != null) {
              out.print("    <td class=\"all\">");
              out.print("/ "+frdec.format(results.docs()));
              out.println("</td>");
            }
            out.print("    <td class=\"num\">");
            out.print(formatScore(results.score()));
            out.println("</td>");
            
            out.println("    <td></td>");
            out.println("    <td class=\"no right\">" + no + "</td>");
            out.println("  </tr>");
          }
          %>
        </tbody>
      </table>
    </main>
    <%@ include file="local/footer.jsp"%>
    <a id="totop" href="#top">△</a>
    <script src="<%= hrefHome %>vendor/sortable.js">//</script>
  </body>
  <!-- <%= ((System.nanoTime() - time) / 1000000.0) %> ms  -->
</html>
