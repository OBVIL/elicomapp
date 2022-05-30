<%@ page language="java" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%!

%>
<%

//-----------
//data common prelude
response.setHeader("Access-Control-Allow-Origin", "*"); // cross domain fo browsers
long time = System.nanoTime();
JspTools tools = new JspTools(pageContext);
Alix alix = alix(tools, null); 
if (alix == null) return; // errors has been sent
String ext = tools.getStringOf("ext", Set.of(".json"), ".txt");
String mime = pageContext.getServletContext().getMimeType("a" + ext);
if (mime != null) response.setContentType(mime);
//-----------
boolean first;
// Get a a BitSet of relevant docs
Query q = query(alix, tools, Set.of(CORRES, CORRES1, CORRES2, DATE, SENDER, Q, RECEIVER, YEAR1, YEAR2));
if (q == null) q = new MatchAllDocsQuery(); // if no query, get all docs
IndexSearcher searcher = alix.searcher();
CollectorBits colBits = new CollectorBits(searcher);
searcher.search(q, colBits);
final BitSet bits = colBits.bits();
// loop on relevant docs to get edges
FieldFacet senderField = alix.fieldFacet(SENDER);
BitSet senderBits = new FixedBitSet(senderField.size()); // to count senders
FieldFacet receiverField = alix.fieldFacet(RECEIVER);
BitSet receiverBits = new FixedBitSet(receiverField.size()); // to count senders
EdgeQueue edges = new EdgeQueue(true); // directed graph, 
for (
    int docId = bits.nextSetBit(0), max = bits.length();
    docId < max;
    docId = bits.nextSetBit(docId + 1)
) {
    // get sender ids and receiver id
    int[] senderIds = senderField.formIds(docId);
    if (senderIds == null) continue;
    int[] receiverIds = receiverField.formIds(docId);
    if (receiverIds == null) continue;
    for (int sid: senderIds) {
        senderBits.set(sid);
        for (int rid: receiverIds) {
            receiverBits.set(rid);
            edges.push(sid, rid);
        }
    }
}

out.println("{ \"data\": {");


// display the biggest relations, and collect the correspondants
Map<Integer, Long> senders = new HashMap<>();
Map<Integer, Long> receivers = new HashMap<>();
out.println("  \"edges\": [");
first = true;
int limit = 20;
int n = 1;
for (Edge edge: edges) {
    if (limit-- == 0) break;
    if (first) first = false;
    else out.append(",\n");
    long count = edge.count();
    int sid = edge.source;
    if (!senders.containsKey(sid)) {
        senders.put(sid, count);
    }
    else {
        senders.put(sid, senders.get(sid) + count);
    }
    int rid = edge.target;
    if (!receivers.containsKey(rid)) {
        receivers.put(rid, count);
    }
    else {
        receivers.put(rid, receivers.get(rid) + count);
    }
    out.append("    {\"n\": " + n 
        + ", \"sender\": \"s" + edge.source + "\""
        // + ", \"slabel\": \"" + senderField.form(edge.source) +"\""
        + ", \"receiver\": \"r" + edge.target + "\""
        // + ", \"rlabel\": \"" + receiverField.form(edge.target) +"\""
        + ", \"count\": " + edge.count() 
    + "}");
    n++;
}
out.println("\n  ],");
out.flush();

// loop on senders
List<Map.Entry<Integer, Long>> list = new ArrayList<>(senders.entrySet());
Collections.sort(list, new Comparator<Map.Entry<Integer, Long>>() {
    @Override
    public int compare(Map.Entry<Integer, Long> a, Map.Entry<Integer, Long> b) {
        return b.getValue().compareTo(a.getValue());
    }
});
n = 1;
first = true;
out.println("  \"senders\": [");
for (Map.Entry<Integer, Long> entry : list) {
    final int id = entry.getKey();
    if (first) first = false;
    else out.append(",\n");
    out.print("    {\"n\": " + n
        + ", \"id\": \"s" + id + "\""
        + ", \"label\": " + JSONWriter.valueToString(senderField.form(id))
        + ", \"count\": " + entry.getValue()
        + "}");
    n++;
}
out.println("\n  ],");
out.flush();

//loop on receivers
list = new ArrayList<>(receivers.entrySet());
Collections.sort(list, new Comparator<Map.Entry<Integer, Long>>() {
    @Override
    public int compare(Map.Entry<Integer, Long> a, Map.Entry<Integer, Long> b) {
        return b.getValue().compareTo(a.getValue());
    }
});
n = 1;
first = true;
out.println("  \"receivers\": [");
for (Map.Entry<Integer, Long> entry : list) {
    final int id = entry.getKey();
    if (first) first = false;
    else out.append(",\n");
    out.print("    {\"n\": " + n
        + ", \"id\": \"s" + id + "\""
        + ", \"label\": " + JSONWriter.valueToString(receiverField.form(id))
        + ", \"count\": " + entry.getValue()
        + "}");
    n++;
}
out.print("\n  ]");
out.flush();


// DocIdSetIterator.NO_MORE_DOCS
/* 
// Collect edges

EdgeQueue edges = new EdgeQueue(true);
// loop on all senders
for (int docId = 0, max = alix.reader().maxDoc(); docId < max ; docId++) {
    if (indie) indies++;
}

// record nodes 


// list all senders
StringBuilder senders = new StringBuilder();
FieldFacet senderField = alix.fieldFacet(SENDER);
FormEnum forms = senderField.forms();
forms.sort(FormEnum.Order.DOCS);
int n = 1;
int s1 = -1;
while (forms.hasNext()) {
    forms.next();
    if (s1 < 0) s1 = forms.formId();
    senders.append("<div");
    senders.append(" id=\"s" + forms.formId() + "\"");
    senders.append(">");
    senders.append(forms.form());
    senders.append(" —</div>\n");
}
request.setAttribute("senders", senders);
//list all receivers
StringBuilder receivers = new StringBuilder();
FieldFacet receiverField = alix.fieldFacet(RECEIVER);
forms = receiverField.forms();
forms.sort(FormEnum.Order.DOCS);
int r1 = -1;
while (forms.hasNext()) {
    forms.next();
    if (r1 < 0) r1 = forms.formId();
    receivers.append("<div");
    receivers.append(" id=\"r" + forms.formId() + "\"");
    receivers.append(">— ");
    receivers.append(forms.form());
    receivers.append("</div>\n");
}
request.setAttribute("receivers", receivers);

int indies = 0;

// Voltaire, 2624 letters indies


StringBuilder rels = new StringBuilder();
request.setAttribute("rels", rels);
*/
if (true) {
    out.print("\n}, \"meta\": {");
    out.print("\"time\": \"" + ( (System.nanoTime() - time) / 1000000) + "ms\"");
    out.print(", \"query\": " + JSONWriter.valueToString(q));
    out.print(", \"senders\": " + senderBits.cardinality());
    out.print(", \"receivers\": " + receiverBits.cardinality());
    out.print("}");
    out.println("}");
}
out.flush();

%>
