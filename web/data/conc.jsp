<%@ page language="java" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>

<%@ page import="org.apache.lucene.util.automaton.Automaton"%>
<%@ page import="org.apache.lucene.util.automaton.ByteRunAutomaton"%>
<%@ page import="alix.lucene.util.WordsAutomatonBuilder"%>

<%!





%>
<%
//-----------
//data common prelude
response.setHeader("Access-Control-Allow-Origin", "*"); // cross domain fo browsers
long time = System.nanoTime();
JspTools tools = new JspTools(pageContext);
Alix alix = alix(tools, null); //get an alix instance, output errors
if (alix == null) return;
String ext = tools.getStringOf("ext", Set.of(""), "");
boolean first;
//-----------
// parameters
Pars pars = new Pars();
pars.href = "doc.jsp?"; //TODO, centralize nav
pars.left = 50; // left context, chars
request.setAttribute("left", pars.left + 10);
pars.right = 70; // right context, chars
pars.f = tools.getStringOf("f", Set.of("text", "text_orth"), "text"); // 
pars.limit = 200;
pars.q = request.getParameter("q");
pars.start = tools.getInt("start", 1);
final int wc = 20;


// build the query from request params
BooleanQuery.Builder builder = new BooleanQuery.Builder();
Query qFilter = query(alix, tools, Set.of(CORRES, CORRES1, CORRES2, SENDER, RECEIVER, DATE, YEAR1, YEAR2));
if (qFilter != null) {
    builder.add(qFilter, Occur.FILTER);
}


if (pars.q != null) {
    Query qWords = alix.query(pars.f, pars.q);
    if (qWords != null) builder.add(qWords, Occur.MUST);
}
Query query = builder.build();
if (((BooleanQuery)query).clauses().size() < 1) {
    query = new TermQuery(new Term("type", "letter"));
}
else if (((BooleanQuery)query).clauses().size() == 1) {
    query = ((BooleanQuery)query).clauses().get(0).getQuery();
}

pars.sort = (OptionSort) tools.getEnum("sort", OptionSort.date, "alixSort");
TopDocs topDocs = pars.sort.top(alix.searcher(), query);

if (pars.start == 0) {
    // TODO display query stats
}
// no results
if (topDocs == null) {
    return;
}

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
    
    // if search key words 
    String[] lines = null;
    if (forms != null && forms.length > 0) {
        lines = doc.kwic(pars.f, include, href.toString(), 200, pars.left, pars.right, gap, expression, repetitions);
        if (lines == null || lines.length < 1) continue;
    }
    
    // show simple metadata
    out.println("<article class=\"kwic\">");
    out.println("  <header>");
    out.println(" <!-- docId=" + docId + " -->");
    out.print("    <a href=\"" + href + "\">");
    out.print("    <b class=\"n\">"+(i)+")</b>");
    out.print(doc.get("bibl"));
    out.println("</a>");
    out.println("  </header>");
    if (lines != null) {
        out.println("  <div class=\"lines\">");
        for (String l: lines) {
            out.println("    <div class=\"line\"><small>"+ ++occ +".</small>"+l+"</div>");
        }
        out.println("  </div>");
    }
    // list of words
    else {
        out.println("  <div class=\"words\">");
        FormEnum docForms = doc.forms(TEXT, OptionDistrib.CHI2, null);
        docForms.sort(FormEnum.Order.SCORE);
        first = true;
        int n = wc;
        while (docForms.hasNext()) {
            if (n-- == 0) break;
            docForms.next();
            if (docForms.freq() < 1) break;
            if (first) first = false;
            else out.println(", ");
            out.print(docForms.form());
        }
        out.println("  </div>");
        
    }
    
    out.println("</article>");
    out.println("&#10;"); // keep that, may be used as a separator
    out.flush(); // send a result
    if (++docs >= pars.limit) break;
    continue;
}
%>
