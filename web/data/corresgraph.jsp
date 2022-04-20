<%@ page language="java" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="alix.util.Edge" %>
<%@ page import="alix.util.EdgeSquare" %>

<%!
static final String PERS = "pers";
static final String WORD = "word";

static class Node {
    final String id;
    final String label;
    final String type;
    public Node(final String id, final String label, final String type) {
        this.id = id;
        this.label = label;
        this.type = type;
    }
}
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
String ext = tools.getStringOf("ext", Set.of(".json", ".js"), ".json");
String mime = pageContext.getServletContext().getMimeType("a" + ext);
if (mime != null) response.setContentType(mime);
//-----------
// parameters
String field = tools.getString("f", TEXT);
TagFilter tags = OptionCat.NOSTOP.tags();
// number of words between corres
final int wordCount = tools.getInt("words", 20);
final int hstop = tools.getInt("hstop", 100);
//-----------
// check parameters
//-----------

final FieldText ftext = alix.fieldText(field);

// loop on sender - receiver
final Set<Integer> senderIds = tools.getIntSet("senderid");
final Set<Integer> receiverIds = tools.getIntSet("receiverid");
if (senderIds.size() < 1 && receiverIds.size() < 1) {
    out.println("{\"errors\": \"At least 1 senderid or 1 receiverid is requested for this graph\"}");
    response.setStatus(400);
    return;
}

boolean first;
Query qdate = dateQuery(DATE, tools.request().getParameter(DATE1), tools.request().getParameter(DATE2));
final FieldFacet senderFacet = alix.fieldFacet(SENDER);
final FieldFacet receiverFacet = alix.fieldFacet(RECEIVER);

int nodeCount = 0;
int edgeCount = 0;


final int corrCount = senderIds.size() + receiverIds.size();
Map<String, Node> nodes = new TreeMap<>();
out.println("{ \"data\": {");
// 1-n sender, 0 receiver
if (senderIds.size() > 0 && receiverIds.size() == 0) {
    int c = 0;
    first = true;
    out.println("  \"edges\": [");
    // loop on each sender, write edges, store nodes, and output
    for (int senderId: senderIds) {
        String label = senderFacet.form(senderId);
        if (label == null) continue;
        // add the sender as a node
        String persId = "c"+ c++;
        nodes.put(persId, new Node(persId, label, PERS));
        Query qterm = new TermQuery(new Term(SENDER, label));
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
        FormEnum words = ftext.forms(filter);
        words.sort(FormEnum.Order.HITS); // sort by hits ?
        
        int wc = wordCount;
        while (words.hasNext()) {
            words.next();
            int formId = words.formId();
            if (formId <= hstop) continue;
            if (--wc < 0) break;
            if (first) first = false;
            else out.println(", ");
            String wordId = "w" + formId;
            nodes.put(wordId, new Node(wordId, words.form(), WORD));
            out.print("    {\"id\":\"e" + (edgeCount++) + "\"");
            out.print(", \"source\":\"" + persId + "\"");
            out.print(", \"target\":\"" + wordId + "\"");
            out.print(", \"size\":" + words.freq());
            out.print(", \"type\":\"" + SENDER + "\"");
            out.print("}");
        }
    }
    out.println("\n  ],");
    out.flush();
}
// 0 sender, 1-n receiver
else if (senderIds.size() == 0 && receiverIds.size() > 0) {
    first = true;
    int c = 0;
    out.println("  \"edges\": [");
    // loop on each sender, write edges, store nodes, and output
    for (int receiverId: receiverIds) {
        String label = receiverFacet.form(receiverId);
        if (label == null) continue;
        // add the sender as a node
        String persId = "c"+ c++;
        nodes.put(persId, new Node(persId, label, PERS));
        Query qterm = new TermQuery(new Term(RECEIVER, label));
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
        FormEnum words = ftext.forms(filter);
        words.sort(FormEnum.Order.HITS); // sort by hits ?
        
        int wc = wordCount;
        while (words.hasNext()) {
            words.next();
            int formId = words.formId();
            if (formId <= hstop) continue;
            if (--wc < 0) break;
            if (first) first = false;
            else out.println(", ");
            final String wid = "w" + formId;
            nodes.put(wid, new Node(wid, words.form(), WORD));
            out.print("    {\"id\":\"e" + (edgeCount++) + "\"");
            out.print(", \"source\":\"" + wid + "\"");
            out.print(", \"target\":\"" + persId + "\"");
            out.print(", \"size\":" + words.freq());
            out.print(", \"type\":\"" + RECEIVER + "\"");
            out.print("}");
        }
    }
    out.println("\n  ],");
    out.flush();
}
// 1-n sender, 1-n receiver
else {
    first = true;
    out.println("  \"edges\": [");
    int wautoid = 0;
    // loop on corres to set their ids
    Map<String, Node> corrs = new HashMap<>(corrCount);
    int c = 0;
    for (int senderId: senderIds) {
        String label = senderFacet.form(senderId);
        if (label == null) continue;
        String id = "c" + c++;
        Node node = new Node(id, label, PERS);
        corrs.put(label, node);
        nodes.put(id, node);
    }
    for (int receiverId: receiverIds) {
        String label = receiverFacet.form(receiverId);
        if (label == null) continue;
        if (corrs.containsKey(label)) continue;
        String id = "c" + c++;
        Node node = new Node(id, label, PERS);
        corrs.put(label, node);
        nodes.put(id, node);
    }
    
    
    // loop on all sender, 
    for (int senderId: senderIds) {
        String label = senderFacet.form(senderId);
        if (label == null) continue;
        Node sender = corrs.get(label);
        Query qsend = new TermQuery(new Term(SENDER, sender.label));

        for (int receiverId: receiverIds) {
            label = receiverFacet.form(receiverId);
            if (label == null) continue;
            Node receiver = corrs.get(label);
            // Voltaire -> Voltaire
            if (receiver == sender) continue;
            BooleanQuery.Builder qbuild = new BooleanQuery.Builder()
                .add(qsend, Occur.MUST)
                .add(new TermQuery(new Term(RECEIVER, receiver.label)), Occur.MUST);
            if (qdate != null) qbuild.add(qdate, Occur.MUST);
            Query q = qbuild.build();
            BitSet filter = filter(alix, q);
            if (filter == null || filter.cardinality() < 1) continue;
            FormEnum words = ftext.forms(filter);
            words.sort(FormEnum.Order.HITS); // sort by hits ?

            // loop on terms
            int wc = wordCount;
            while (words.hasNext()) {
                words.next();
                int formId = words.formId();
                if (formId <= hstop) continue;
                if (--wc < 0) break;
                if (first) first = false;
                else out.println(", ");
                
                String wid = "w" + wautoid++;
                // String wid = "w" + formId;
                nodes.put(wid, new Node(wid, words.form(), WORD));
                // sender -> word
                out.print("    {\"id\":\"e" + (edgeCount++) + "\"");
                out.print(", \"source\":\"" + sender.id + "\"");
                out.print(", \"target\":\"" + wid + "\"");
                out.print(", \"size\":" + words.freq());
                out.print(", \"type\":\"" + SENDER + "\"");
                out.print("}");
                out.println(",");
                // word -> receiver
                out.print("    {\"id\":\"e" + (edgeCount++) + "\"");
                out.print(", \"source\":\"" + wid + "\"");
                out.print(", \"target\":\"" + receiver.id + "\"");
                out.print(", \"size\":" + words.freq());
                out.print(", \"type\":\"" + RECEIVER + "\"");
                out.print("}");
            }

        }
    }
    out.println("\n  ],");
    out.flush();
}

// nodes
out.println("  \"nodes\": [");
first = true;
for (Node node: nodes.values()) {
    if (first) first = false;
    else out.println(", ");
    out.print("    {\"id\":\"" + node.id + "\"");
    out.print(", \"x\":" + ((int)(Math.random() * 100)) + ", \"y\":" + ((int)(Math.random() * 100)) );
    out.print(", \"label\":" + JSONWriter.valueToString(node.label)); // node.count
    if (node.type.equals(PERS)) {
        out.print(", \"size\":" + 10);
    }
    else {
        out.print(", \"size\":" + 10);
    }
    out.print(", \"type\":\"" + node.type + "\"");
    out.print("}");
    
}
out.println("\n  ]");


if (".js".equals(ext) || ".json".equals(ext)) {
    out.print("\n}, \"meta\": {");
    out.print("\"time\": \"" + ( (System.nanoTime() - time) / 1000000) + "ms\"");
    // out.print(", \"query\": " + JSONWriter.valueToString(qFilter));
    out.print("}");
    out.println("}");
}
%>



