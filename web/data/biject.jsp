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
// parameters
final int edgesLimit = 20;

// Get a a BitSet of relevant docs
Query q = query(alix, tools, Set.of(SENDER, Q, RECEIVER, YEAR1, YEAR2));
if (q == null) q = new MatchAllDocsQuery(); // if no query, get all docs


boolean first;
IndexSearcher searcher = alix.searcher();
CollectorBits colBits = new CollectorBits(searcher);
searcher.search(q, colBits);
final BitSet bits = colBits.bits();

if (bits.cardinality() < 1) {
    out.println("NO DOCS FOUND !");
    return;
}

// loop on relevant docs to get edges
FieldFacet corresField = alix.fieldFacet(CORRES);

FieldFacet senderField = alix.fieldFacet(SENDER);
BitSet senderBits = new FixedBitSet(senderField.size()); // to count senders
int[] senderFreqs = new int[senderField.size()];

FieldFacet receiverField = alix.fieldFacet(RECEIVER);
BitSet receiverBits = new FixedBitSet(receiverField.size()); // to count senders
int[] receiverFreqs = new int[receiverField.size()];

EdgeQueue edges = new EdgeQueue(true); // directed graph, 
for (
    int docId = bits.nextSetBit(0), max = bits.length();
    docId < max;
    docId = bits.nextSetBit(docId + 1)
) {
    // get sender ids and receiver id, update freqs
    int[] senderIds = senderField.formIds(docId);
    if (senderIds != null) {
        for (int sid: senderIds) senderFreqs[sid]++;
    }
    int[] receiverIds = receiverField.formIds(docId);
    if (receiverIds != null) {
        for (int rid: receiverIds) receiverFreqs[rid]++;
    }
    
    // update counts

    if (senderIds == null) continue;
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
// min / max counts
long min = Integer.MAX_VALUE;
long max = Integer.MIN_VALUE;
Map<Integer, Long> sendersCount = new HashMap<>(edgesLimit);
Map<Integer, Integer> sendersRels = new HashMap<>(edgesLimit);
Map<Integer, Long> receiversCount = new HashMap<>(edgesLimit);
Map<Integer, Integer> receiversRels = new HashMap<>(edgesLimit);

out.println("  \"edges\": [");
first = true;

int n = 0;
for (Edge edge: edges) {
    if (n == edgesLimit) break;
    if (first) first = false;
    else out.append(",\n");
    final long count = edge.count();
    if (count < min) min = count;
    if (count > max) max = count;
    final int sid = edge.source;
    sendersCount.merge(sid, count, (a, b) -> a + b);
    sendersRels.merge(sid, 1, (a, b) -> a + b);
    final int rid = edge.target;
    receiversCount.merge(rid, count, (a, b) -> a + b);
    receiversRels.merge(rid, 1, (a, b) -> a + b);
    n++;
    out.append("    {\"n\": " + n 
        + ", \"sender\": \"s" + edge.source + "\""
        // + ", \"slabel\": \"" + senderField.form(edge.source) +"\""
        + ", \"receiver\": \"r" + edge.target + "\""
        // + ", \"rlabel\": \"" + receiverField.form(edge.target) +"\""
        + ", \"count\": " + count
    + "}");
}
out.println("\n  ],");
out.flush();


// loop on senders
List<Map.Entry<Integer, Long>> list = new ArrayList<>(sendersCount.entrySet());
Collections.sort(list, new Comparator<Map.Entry<Integer, Long>>() {
    @Override
    public int compare(Map.Entry<Integer, Long> a, Map.Entry<Integer, Long> b) {
        int ret = b.getValue().compareTo(a.getValue());
        if (ret != 0) return ret;
        return a.getKey().compareTo(b.getKey());
    }
});
n = 1;
first = true;
out.println("  \"senders\": [");
for (Map.Entry<Integer, Long> entry : list) {
    final int id = entry.getKey();
    final long count = entry.getValue();
    if (count < min) min = count;
    if (count > max) max = count;
    if (first) first = false;
    else out.append(",\n");
    String form = senderField.form(id);
    out.print("    {\"n\": " + n
        + ", \"id\": \"s" + id + "\""
        + ", \"label\": " + JSONWriter.valueToString(form)
        + ", \"count\": " + count
        + ", \"freq\": " + senderFreqs[id]
        + ", \"rels\": " + sendersRels.get(id)
        + ", \"corres\": " + corresField.formId(form)
        + "}");
    n++;
}
out.println("\n  ],");
out.flush();

//loop on receivers
list = new ArrayList<>(receiversCount.entrySet());
Collections.sort(list, new Comparator<Map.Entry<Integer, Long>>() {
    @Override
    public int compare(Map.Entry<Integer, Long> a, Map.Entry<Integer, Long> b) {
        int ret = b.getValue().compareTo(a.getValue());
        if (ret != 0) return ret;
        return a.getKey().compareTo(b.getKey());
    }
});
n = 1;
first = true;
out.println("  \"receivers\": [");
for (Map.Entry<Integer, Long> entry : list) {
    final int id = entry.getKey();
    final long count = entry.getValue();
    if (count < min) min = count;
    if (count > max) max = count;
    if (first) first = false;
    else out.append(",\n");
    final String form = receiverField.form(id);
    out.print("    {\"n\": " + n
        + ", \"id\": \"r" + id + "\""
        + ", \"label\": " + JSONWriter.valueToString(form)
        + ", \"count\": " + count
        + ", \"freq\": " + receiverFreqs[id]
        + ", \"rels\": " + receiversRels.get(id)
        + ", \"corres\": " + corresField.formId(form)
        + "}");
    n++;
}
out.print("\n  ]");
out.flush();

if (true) {
    out.print("\n}, \"meta\": {");
    out.print("\"time\": \"" + ( (System.nanoTime() - time) / 1000000) + "ms\"");
    out.print(", \"query\": " + JSONWriter.valueToString(q));
    out.print(", \"senders\": " + senderBits.cardinality());
    out.print(", \"receivers\": " + receiverBits.cardinality());
    out.print(", \"min\": " + min);
    out.print(", \"max\": " + max);
    out.print("}");
    out.println("}");
}
out.flush();

%>
