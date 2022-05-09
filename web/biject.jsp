<%@ page language="java" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%!

%>
<%
JspTools tools = new JspTools(pageContext);
Alix alix = alix(tools, null); 
// list all senders
StringBuilder senders = new StringBuilder();
FieldFacet senderField = alix.fieldFacet(SENDER);
FormEnum forms = senderField.forms();
forms.sort(FormEnum.Order.DOCS);
int n = 1;
while (forms.hasNext()) {
    forms.next();
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
while (forms.hasNext()) {
    forms.next();
    receivers.append("<div");
    receivers.append(" id=\"r" + forms.formId() + "\"");
    receivers.append(">— ");
    receivers.append(forms.form());
    receivers.append("</div>\n");
}
request.setAttribute("receivers", receivers);

// build edges
EdgeQueue edges = new EdgeQueue(true);
// loop on all senders
for (int docId = 0, max = alix.reader().maxDoc(); docId < max ; docId++) {
    int[] senderIds = senderField.formIds(docId);
    if (senderIds == null) continue;
    int[] receiverIds = receiverField.formIds(docId);
    if (receiverIds == null) continue;
    for (int sid: senderIds) {
        for (int rid: receiverIds) {
            edges.push(sid, rid);
        }
    }
}

StringBuilder rels = new StringBuilder();
rels.append("[\n");
boolean first = true;
int limit = -1;
for (Edge edge: edges) {
    if (limit-- == 0) break;
    if (first) first = false;
    else rels.append(",\n");
    rels.append("  {\"sender\":\"s" + edge.source + "\", \"slabel\":\"" + senderField.form(edge.source) +"\", \"receiver\":\"r" + edge.target + "\", \"rlabel\":\"" + receiverField.form(edge.target) +"\", \"count\":" + edge.count() + "}");
}
rels.append("\n]");
request.setAttribute("rels", rels);

%>
<t:elicom>
    <jsp:attribute name="title">${title} [Elicom]</jsp:attribute>
    <jsp:attribute name="head">
<style>
#biject {
    position: relative;
    display: flex;
}
#senders {
    text-align: right;
    white-space: nowrap;
    max-width: 45%;
}
#relations {
    position: relative;
    flex-grow: 4;
    min-width: 100px;
    backgroud-color: #fff;
}
#receivers {
    text-align: left;
    white-space: nowrap;
    max-width: 45%;
}
#senders > *,
#receivers > * {
    overflow: hidden;
}
#relations line {
    stroke: rgba(0, 0, 0, 0.2);
    stroke-width: 2px;
}
</style>
    </jsp:attribute>
    <jsp:body>
        <div id="biject">
            <div id="senders">
                ${senders}
            </div>
            <svg id="relations" xmlns="http://www.w3.org/2000/svg">
            
            </svg>
            <div id="receivers">
                ${receivers}
            </div>
        </div>
        <script>
const svg = document.getElementById("relations");
const ns = svg.namespaceURI;
const x1 = 0;
const x2 = svg.getBoundingClientRect().width;
const rels = ${rels};
for (let i = 0, max = rels.length; i < max; i++) {
    const rel = rels[i];
    const sender = document.getElementById(rel['sender']);
    const y1 = sender.offsetTop + sender.offsetHeight / 2;
    const receiver = document.getElementById(rel['receiver']);
    const y2 = receiver.offsetTop + receiver.offsetHeight / 2;
    
    const line = document.createElementNS(ns,'line');
    line.setAttribute('x1', x1);
    line.setAttribute('y1',y1);
    line.setAttribute('x2', x2);
    line.setAttribute('y2',y2);
    const title = document.createElementNS(ns, "title");
    title.textContent = rel['slabel'] + " -> " + rel['rlabel'];
    line.appendChild(title);
    svg.appendChild(line);
}
        </script>
    </jsp:body>
</t:elicom>