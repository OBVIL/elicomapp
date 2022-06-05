<%@ page language="java" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="alix.util.Edge" %>
<%@ page import="alix.util.EdgeSquare" %>

<%
/**
 * Words by sender / receiver, not used
 */


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
OptionCat cat = (OptionCat) tools.getEnum("cat", OptionCat.ALL);
if (cat != null) tags = cat.tags();

// number of words between corres
final int wordCount = tools.getInt("words", 50);
final int hstop = tools.getInt("hstop", -1);
OptionDistrib distrib = (OptionDistrib) tools.getEnum("distrib", OptionDistrib.OCCS);
//-----------
// check parameters
//-----------

final FieldText ftext = alix.fieldText(field);
final FieldInt fdate = alix.fieldInt(DATE);

// loop on sender - receiver
final Set<Integer> senderIds = tools.getIntSet("senderid");
final Set<Integer> receiverIds = tools.getIntSet("receiverid");
if (senderIds.size() < 1 && receiverIds.size() < 1) {
    return;
}

Query qdate = dateQuery(DATE, tools.request().getParameter(DATE1), tools.request().getParameter(DATE2));
final FieldFacet senderFacet = alix.fieldFacet(SENDER);
final FieldFacet receiverFacet = alix.fieldFacet(RECEIVER);

final int corrCount = senderIds.size() + receiverIds.size();

boolean first;
// 1-n sender, 0 receiver
if (senderIds.size() > 0 && receiverIds.size() == 0) {
    String receiver = "";
    // loop on each sender, write edges, store nodes, and output
    for (int senderId: senderIds) {
        String sender = senderFacet.form(senderId);
        if (sender == null) continue;
        Query qterm = new TermQuery(new Term(SENDER, sender));
        Query q = null;
        if (qdate != null) {
            q = new BooleanQuery.Builder()
                .add(qdate, Occur.MUST)
                .add(qterm, Occur.MUST)
                .build();
        }
        else {
            q = qterm;
        }
        // TODO, scoring
        BitSet filter = filter(alix, q);
        if (filter == null || filter.cardinality() < 1) continue;
        FormEnum words = ftext.forms(filter, tags, distrib);
        words.sort(FormEnum.Order.SCORE); // sort by hits ?
        
        
        out.println("<div class=\"relation\">");
        out.println("<h5>" + filter.cardinality() + " lettres</h5>");
        out.println("<div class=\"flex\">");
        out.println("  <div class=\"sender\">" + sender + "</div>");
        out.print("  <div class=\"words\">");
        int wc = wordCount;
        first = true;
        while (words.hasNext()) {
            words.next();
            int formId = words.formId();
            if (formId < hstop) continue;
            if (--wc < 0) break;
            
            if (first) first = false;
            else out.print(", ");
            out.print("<a class=\"w\" title=\"rang " + words.formId() +"\">" + words.form() + " <small>(" + words.freq() + ")</small>" + "</a>");
        }
        out.println(".</div>");
        out.println("  <div class=\"receiver\">" + receiver + "</div>");
        out.println("</div>");
        out.println("</div>");
        out.println("&#10;"); // keep that, may be used as a separator
        out.flush();
    }
}
// 0 sender, 1-n receiver
else if (senderIds.size() == 0 && receiverIds.size() > 0) {
    // loop on each sender, write edges, store nodes, and output
    for (int receiverId: receiverIds) {
        String receiver = receiverFacet.form(receiverId);
        if (receiver == null) continue;
        Query qterm = new TermQuery(new Term(RECEIVER, receiver));
        Query q = null;
        if (qdate != null) {
            q = new BooleanQuery.Builder()
                .add(qdate, Occur.MUST)
                .add(qterm, Occur.MUST)
                .build();
        }
        else {
            q = qterm;
        }
        BitSet filter = filter(alix, q);
        if (filter == null || filter.cardinality() < 1) continue;
        FormEnum words = ftext.forms(filter, tags, distrib);
        words.sort(FormEnum.Order.SCORE);
        
        out.println("<div class=\"relation\">");
        out.println("<h5>" + filter.cardinality() + " lettres</h5>");
        out.println("<div class=\"flex\">");
        out.println("<div class=\"sender\">" + "" + "</div>");
        out.print("<div class=\"words\">");
        int wc = wordCount;
        first = true;
        while (words.hasNext()) {
            words.next();
            int formId = words.formId();
            if (formId < hstop) continue;
            if (--wc < 0) break;
            if (first) first = false;
            else out.print(", ");
            out.print("<a class=\"w\" title=\"rang " + words.formId() +"\">" + words.form() + " <small>(" + words.freq() + ")</small>" + "</a>");
        }
        out.println(".</div>");
        out.println("<div class=\"receiver\">" + receiver + "</div>");
        out.println("</div>");
        out.println("</div>");
        out.println("&#10;"); // keep that, may be used as a separator
        out.flush();
    }
}
// 1-n sender, 1-n receiver
else {
    // loop on all sender, 
    for (int senderId: senderIds) {
        String sender = senderFacet.form(senderId);
        if (sender == null) continue;
        Query qsend = new TermQuery(new Term(SENDER, sender));

        for (int receiverId: receiverIds) {
            String receiver = receiverFacet.form(receiverId);
            if (receiver == null) continue;
            // Voltaire -> Voltaire
            if (receiver.equals(sender)) continue;
            BooleanQuery.Builder qbuild = new BooleanQuery.Builder()
                .add(qsend, Occur.MUST)
                .add(new TermQuery(new Term(RECEIVER, receiver)), Occur.MUST);
            if (qdate != null) qbuild.add(qdate, Occur.MUST);
            Query q = qbuild.build();
            BitSet filter = filter(alix, q);
            if (filter == null || filter.cardinality() < 1) continue;
            // loop on terms
            out.println("<div class=\"relation\">");
            out.print("<h5>" + filter.cardinality() + " lettres ");
            int[] minmax = fdate.minmax(filter);
            out.print( FieldInt.year(minmax[0]) + "–" + FieldInt.year(minmax[1]));
            out.println("</h5>");
            out.println("<div class=\"flex\">");
            out.println("<div class=\"sender\">" + sender + "</div>");
            out.print("<div class=\"words\">");
            FormEnum words = ftext.forms(filter, tags, distrib);
            words.sort(FormEnum.Order.SCORE);
            int wc = wordCount;
            first = true;
            while (words.hasNext()) {
                words.next();
                int formId = words.formId();
                if (formId < hstop) continue;
                if (--wc < 0) break;
                if (first) first = false;
                else out.println(", ");
                out.print("<a class=\"w\" title=\"rang " + words.formId() +"\">" + words.form() + " <small>(" + words.freq() + ")</small>" + "</a>");
            }
            out.println(".</div>");
            out.println("<div class=\"receiver\">" + receiver + "</div>");
            out.println("</div>");
            out.println("</div>");
            out.println("&#10;"); // keep that, may be used as a separator
            out.flush();
        }
    }
}

%>



