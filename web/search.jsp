<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="jsp/elicom.jsp" %>
<%@taglib prefix="t" tagdir="/WEB-INF/tags" %>

<%@ page import="org.apache.lucene.util.automaton.Automaton"%>
<%@ page import="org.apache.lucene.util.automaton.ByteRunAutomaton"%>
<%@ page import="alix.lucene.util.WordsAutomatonBuilder"%>

<%!

public String kwic(final Alix alix, final TopDocs topDocs, Pars pars) throws IOException, NoSuchFieldException
{
    if (topDocs == null) {
        return null;
    }
    StringBuilder sb = new StringBuilder();
    String[] forms = alix.tokenize(pars.q, pars.f);
    boolean repetitions = false;
    ByteRunAutomaton include = null;
    if (forms != null) {
        Automaton automaton = WordsAutomatonBuilder.buildFronStrings(forms);
        if (automaton != null) include = new ByteRunAutomaton(automaton);
        if (forms.length == 1) repetitions = true;
    }
    // get the index in results
    ScoreDoc[] scoreDocs = topDocs.scoreDocs;

  
    // where to start loop ?
    int i = pars.start - 1; // private index in results start at 0
    int max = scoreDocs.length;
    if (i < 0) {
        i = 0;
    }
    else if (i > max) {
        i = 0;
    }
    // loop on docs
    int docs = 0;
    final int gap = 5;
  

    // be careful, if one term, no expression possible, this will loop till the end of corpus
    boolean expression = false;
    if (forms == null) expression = false;
    else expression = pars.expression;
    int occ = 0;
    while (i < max) {
        final int docId = scoreDocs[i].doc;
        i++; // loop now
        final Doc doc = new Doc(alix, docId);
        String type = doc.doc().get(Names.ALIX_TYPE);
        if (type.equals(Names.BOOK)) continue;
        // if (doc.doc().get(pars.field.name()) == null) continue; // not a good test, field may be indexed but not store
        String href = pars.href + "&amp;q=" + JspTools.escUrl(pars.q) + "&amp;id=" + doc.id() + "&amp;start=" + i + "&amp;sort=" + pars.sort.name();
        
        // show simple metadata
        sb.append("<!-- docId=" + docId + " -->\n");
        if (forms == null || forms.length == 0) {
            sb.append("<article class=\"kwic\">\n");
            sb.append("<header>\n");
            sb.append("<small>"+(i)+".</small> ");
            sb.append("<a href=\"" + href + "\">");
            sb.append(doc.get("bibl"));
            sb.append("</a>");
            sb.append("</header>");
            sb.append("</article>");
            if (++docs >= pars.hpp) break;
            continue;
        }
    
        String[] lines = null;
        lines = doc.kwic(pars.f, include, href.toString(), 200, pars.left, pars.right, gap, expression, repetitions);
        if (lines == null || lines.length < 1) continue;
        // doc.kwic(field, include, 50, 50, 100);
        sb.append("<article class=\"kwic\">\n");
        sb.append("<header>\n");
        sb.append("<b>"+(i)+"</b> ");
        
        sb.append("<a href=\""+href+"\">");
        sb.append(doc.get("bibl"));
        sb.append("</a></header>\n");
        for (String l: lines) {
            sb.append("<div class=\"line\"><small>"+ ++occ +"</small>"+l+"</div>");
        }
        sb.append("</article>");
        if (++docs >= pars.hpp) {
            break;
        }
    }
    return sb.toString();
}



%>
<%

JspTools tools = new JspTools(pageContext);
StringBuilder body = new StringBuilder();
request.setAttribute("body", body); // used by the template tag
Alix alix = alix(tools, body); // get an alix instance, body could be populated by errors


Pars pars = new Pars();
pars.left = 50; // left context, chars
request.setAttribute("left", pars.left + 10);
pars.right = 70; // right context, chars
pars.f = tools.getString("f", Arrays.asList("text", "text_orth")); // 
pars.hpp = 100;
pars.q = request.getParameter("q");
pars.start = tools.getInt("start", 1);


// build query and get results
long nanos = System.nanoTime();
Query query = null;
Query qWords = null;
while (alix != null) {
    if (pars.q != null) {
        qWords = alix.query(pars.f, pars.q);
    }
    
    if (qWords != null) {
        query = qWords;
    }
    else {
        query = new TermQuery(new Term("type", "letter"));
    }
    
    pars.sort = (OptionSort) tools.getEnum("sort", OptionSort.date, "alixSort");
    TopDocs topDocs = pars.sort.top(alix.searcher(), query);
    
    
    // alix.props.get("label")
    
    body.append("<div>\n");
    // prev / next nav
    body.append("<form>\n");
    body.append("<input type=\"hidden\" name=\"q\" value=\"" + JspTools.escape(pars.q) + "\">\n");
    if (pars.start > 1 && pars.q != null) {
        int n = Math.max(1, pars.start - pars.hpp);
        body.append("<button name=\"next\" type=\"submit\" onclick=\"this.form['start'].value=" + n + "\">◀</button>\n");
    }
    if (topDocs != null) {
        long max = topDocs.totalHits.value;
        body.append("<input  name=\"start\" value=\"" + pars.start + "\" autocomplete=\"off\" class=\"start num3\"/>\n");
        body.append("<span class=\"hits\"> / " + max + "</span>\n");
        int n = pars.start + pars.hpp;
        if (n < max) {
            body.append("<button name=\"next\" type=\"submit\" onclick=\"this.form['start'].value=" + n + "\">▶</button>");
        }
    }
    body.append("</form>\n");
    /*
    
                <select name="sort"
                    onchange="this.form['start'].value=''; this.form.submit()"
                    title="Ordre">
                    <option />
                    pars.sort.options()
                </select>
    */
    pars.href = "doc.jsp?"; // TODO, centralize nav
    body.append(kwic(alix, topDocs, pars));
    body.append("</div>\n");
    break;
}
%>
<t:elicom>
    <jsp:attribute name="title">${title} [Elicom]</jsp:attribute>
    <jsp:attribute name="hrefHome"></jsp:attribute>
    <jsp:attribute name="head">
    <style>
span.left {
    display: inline-block;
    text-align: right;
    width: ${left}ex;
    padding-right: 1ex;
}
    </style>
    </jsp:attribute>
    <jsp:body>
        <form class="row">
            <div>
                <label>Expéditeur</label>
                <div class="senders">
                    <!-- input  -->
                </div>
                <input type="text"/>
                <div class="suggest">
                    <!-- dynamic suggestion -->
                </div>
            </div>
            <div>
                <input placeholder="Mots clés"/>
                <div class="suggest">
                    <!-- suggestion of terms -->
                </div>
                <div>
                    <label>De</label>
                    <input size="4"/>
                    <label>à</label>
                    <input size="4"/>
                </div>
            </div>
            <div>
                <label>Destinataire</label>
                <div class="receivers">
                    <!-- input  -->
                </div>
                <input type="text"/>
                <div class="suggest">
                    <!-- dynamic suggestion -->
                </div>
            </div>
        </form>
        <div>Lieux : …</div>
        <div>Graphe</div>
        <div>Concordance infinie</div>
    </jsp:body>
</t:elicom>
