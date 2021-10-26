<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="jsp/prelude.jsp" %>
<%!
/** A filter for documents */
final static Query LETTER_QUERY = new TermQuery(new Term("type", "letter"));
final static HashSet<String> LETTER_FIELDS = new HashSet<String>(Arrays.asList(new String[] {
  Alix.ID, "date", "sender", "receiver", "pbs", "title"
}));


%>
<%
// Prepare request here to get stats
FieldText ftext = alix.fieldText("text"); // get stats on tex of letter
final int limit = 2000;
Query query = alix.query(pars.field.name(), pars.q);
if (query == null) {
  query = LETTER_QUERY;
}

%>
<!DOCTYPE html>
<html>
  <head>
    <%@ include file="local/head.jsp"%>
    <title><%= alix.props.get("label") %> [Elicom]</title>
  </head>
  <body>
    <header id="header" class="top accueil">
      <%@ include file="local/tabs.jsp"%>
    </header>
    
    <main>
      <table class="sortable" style="width: 100%;">
        <thead>
          <tr>
            <th />
            <th title="Date d’envoi" class="num">Date</th>
            <th title="Expéditeurs">De</th>
            <th title="Destinataire">À</th>
            <th title="Taille en page">Pages</th>
            <th title="Taille en mots">Mots</th>
            <th width="90%" style="max-width: 99%"> </th>
            <th/>
          </tr>
        </thead>
        <tbody>
          <%
          IndexSearcher searcher = alix.searcher();
          TopDocs topDocs = pars.sort.top(searcher, query, limit);
          ScoreDoc[] hits = topDocs.scoreDocs;

          // get stats by doc
          Doc doc = null;
          String[] forms = null;
          if (pars.q != null) {
            forms = alix.forms(pars.q, pars.field.name());
          }
          final String href = "doc.jsp?q=" + pars.q + "&amp;id="; // href link
          boolean zero = false;
          int no = 1;
          String value;
          for (ScoreDoc hit: hits) {
            final int docId = hit.doc;
            doc = new Doc(alix, docId, LETTER_FIELDS);
            out.println("<tr>");
            out.println("<td class=\"no left\">" + no + "</td>");
            // date
            out.print("<td>");
            value = doc.get("date");
            if (value != null) {
              String year = value.substring(0, 4);
              if (!year.equals("0000")) out.print(year);
              String month = value.substring(4, 6);
              if (!month.equals("00")) out.print("-"+month);
              String day = value.substring(6, 8);
              if (!day.equals("00")) out.print("-"+day);
            }
            out.println("</td>");
            // sender
            out.print("<td>");
            value = doc.get("sender");
            if (value != null) out.print(value);
            out.println("</td>");
            // receiver
            out.print("<td>");
            value = doc.get("receiver");
            if (value != null) out.print(value);
            out.println("</td>");
            // pages
            out.print("<td>");
            value = doc.get("pbs");
            if (value != null) out.print(value);
            out.println("</td>");
            // size in words
            out.print("<td>");
            out.print(frdec.format(ftext.docOccs(docId)));
            out.println("</td>");

            out.println("<td/>");
            out.println("<td class=\"no right\">" + (no++) + "</td>");
            out.println("</tr>");
          }
          %>
      </table>
    </main>
    <%@ include file="local/footer.jsp"%>
  </body>
</html>