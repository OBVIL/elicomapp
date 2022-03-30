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
String ext = tools.getStringInList("ext", Arrays.asList(new String[]{""}), "");
//-----------

Pars pars = new Pars();
pars.href = "doc.jsp?"; //TODO, centralize nav
pars.left = 50; // left context, chars
request.setAttribute("left", pars.left + 10);
pars.right = 70; // right context, chars
pars.f = tools.getStringInList("f", Arrays.asList(new String[]{"text", "text_orth"}), "text"); // 
pars.limit = 200;
pars.q = request.getParameter("q");
pars.start = tools.getInt("start", 1);


Query query = null;
Query qWords = null;
Query qFilter = null;

boolean hasFilter = false;
BooleanQuery.Builder filterBuilder = new BooleanQuery.Builder();
for (String field: new String[]{SENDER, RECEIVER}) {
    String[] ids = request.getParameterValues(field + "id");
    if (ids != null) {
        boolean build = true;
        final FieldFacet facet = alix.fieldFacet(field, TEXT);
        BooleanQuery.Builder builder = new BooleanQuery.Builder();
        for (String id: ids) {
    int facetId = -1;
    try {
        facetId = Integer.parseInt(id);
    }
    catch (Exception e) {
        // output error ?
        continue;
    }
    String value = facet.form(facetId);
    build = true;
    hasFilter = true;
    builder.add(new TermQuery(new Term(field, value)), Occur.SHOULD);
        }
        if (build) {
    filterBuilder.add(builder.build(), Occur.MUST);
        }
    }
}
if (hasFilter) {
    qFilter = filterBuilder.build();
}
if (pars.q != null) {
    qWords = alix.query(pars.f, pars.q);
}

if (qFilter != null && qWords != null) {
    query = new BooleanQuery.Builder()
        .add(qFilter, Occur.FILTER)
        .add(qWords, Occur.MUST)
    .build();
}
else if (qWords != null) {
    query = qWords;
}
else if (qFilter != null) {
    query = qFilter;
}
else {
    query = new TermQuery(new Term("type", "letter"));
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
    out.print("    <small>"+(i)+".</small>");
    out.println(" <!-- docId=" + docId + " -->");
    out.print("    <a href=\"" + href + "\">");
    out.print(doc.get("bibl"));
    out.println("</a>");
    out.println("  </header>");
    if (lines != null) {
        for (String l: lines) {
    out.println("  <div class=\"line\"><small>"+ ++occ +"</small>"+l+"</div>");
        }
    }
    
    out.println("</article>");
    out.println("&#10;"); // keep that, may be used as a separator
    out.flush(); // send a result
    if (++docs >= pars.limit) break;
    continue;
}
%>
