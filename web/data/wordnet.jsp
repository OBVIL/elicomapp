<%@ page language="java" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="alix.util.Edge" %>
<%@ page import="alix.util.EdgeSquare" %>

<%!
/**
 * Frequent words linked by co-occurrence
 */
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
String ext = tools.getStringInList("ext", Arrays.asList(new String[]{".json", ".js"}), ".json");
String mime = pageContext.getServletContext().getMimeType("a" + ext);
if (mime != null) response.setContentType(mime);
//-----------
// parameters
int nodeLen = tools.getInt("nodes", 50); // count of nodes
int edgeLen = tools.getInt("edges", (int)(nodeLen * 3)); // count of edges
int dist = tools.getInt("dist", 15); // distance between words, too small produce islands for smal texts
String field = tools.getString("f", TEXT);
TagFilter tags = OptionCat.NOSTOP.tags().clearGroup(Tag.VERB);
//-----------
// check parameters
//-----------

final FieldText ftext = alix.fieldText(field);
final FieldRail frail = alix.fieldRail(field);
// define the partition filter
BitSet filter = filter(tools, alix, GRAPH_PARS);
//get nodes and sort them
FormEnum nodes = ftext.results(tags, OptionDistrib.bm25.scorer(), filter);
int[] formIds = nodes.sort(OptionOrder.score.order(), nodeLen);
nodeLen = formIds.length; // if less than requested
//build edges from selected nodes and get the iterator to avoid orphans
EdgeSquare edges =  frail.edges(formIds, dist, filter);
EdgeSquare.EdgeIt edgeIt = (EdgeSquare.EdgeIt)edges.iterator();


// output data
out.println("{ \"data\": {");
boolean first;
out.println("  \"nodes\": [");
first = true;
nodes.reset();
int i = 0;
while(nodes.hasNext()) {
    nodes.next();
    final int formId = nodes.formId();
    // avoid orphans, in short text, common words may have no links with others
    if (edgeIt.top(formId).count() < 1) {
        continue;
    } 
    if (first) {
    	first = false;
    }
    else {
    	out.println(", ");
    }
    int tag = ftext.tag(formId);
    // {id:'n204', label:'coeur', x:-16, y:99, size:86, color:'hsla(0, 86%, 42%, 0.95)'},
    double size = nodes.freq();
    out.print("    {\"id\":\"n" + formId + "\", \"label\":" + JSONWriter.valueToString(ftext.form(formId)) + ", \"size\":" + size); // node.count
    // try a significant positionning ?
    out.print(", \"x\":" + ((int)(Math.random() * 100)) + ", \"y\":" + ((int)(Math.random() * 100)) );
    out.print(", \"color\":\"" + color(tag) + "\"");
    out.print("}");
    i++;
}
out.println("\n  ],");




out.println("  \"edges\": [");
first = true;
int edgeCount = 0;

while(edgeIt.hasNext()) {
    Edge edge = edgeIt.next();
    if (edge == null) break; // may arrive
    if (edge.source == edge.target) {
        continue;
    }
    double score = 0.1;
    if (edge.score() > 0) score = edge.score();
    if (first) first = false;
    else out.println(", ");
    
    out.print("    {\"id\":\"e" + (edgeCount) + "\", \"source\":\"n" + edge.source + "\", \"target\":\"n" + edge.target + "\", \"size\":" + (score) 
        + ", \"title\":" + JSONWriter.valueToString(ftext.form(edge.source)+" -- " + ftext.form(edge.target)) 
        // + ", \"color\":\"rgba(192, 192, 192, 0.2)\""
    // for debug
    // + ", srcLabel:'" + ftext.form(srcId).replace("'", "\\'") + "', srcOccs:" + ftext.formOccs(srcId) + ", dstLabel:'" + ftext.form(dstId).replace("'", "\\'") + "', dstOccs:" + ftext.formOccs(dstId) + ", freq:" + freqList.freq()
    + "}");
    if (++edgeCount >= edgeLen) {
        break;
    }
}
out.println("\n  ]");
if (".js".equals(ext) || ".json".equals(ext)) {
    out.print("\n}, \"meta\": {");
    out.print("\"time\": \"" + ( (System.nanoTime() - time) / 1000000) + "ms\"");
    out.print("}");
    out.println("}");
}
%>



