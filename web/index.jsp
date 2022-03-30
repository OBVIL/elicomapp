<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%
JspTools tools = new JspTools(pageContext);
Alix alix = alix(tools, null);
request.setAttribute(Q, JspTools.escape(request.getParameter(Q)));
// populate form
/*
<label class="corres"><a class="inputDel">🞭</a> <input type="hidden" name="receiverid" value="1343"/>Voltaire</label>
*/
for (String field: new String[]{SENDER, RECEIVER}) {
    String[] ids = request.getParameterValues(field+"id");
    if (ids == null) continue;
    StringBuilder sb = new StringBuilder();
    TreeSet<Integer> idSet = new TreeSet<Integer>();
    final FieldFacet facet = alix.fieldFacet(field, TEXT);
    String form = null;
    for (String id: ids) {
        int formId = -1;
        try {
            formId = Integer.parseInt(id);
        }
        catch (Exception e) {
            continue;
        }
        form = facet.form(formId);
        if (form == null) continue;
        if (idSet.contains(formId)) continue;
        idSet.add(formId);
        sb.append("<label class=\"corres\"><a class=\"inputDel\">🞭</a> <input type=\"hidden\" name=\"" + field +"id\" value=\"" + id + "\"/>" + form +"</label>");
    }
    if (form != null) {
        request.setAttribute(field, sb);
    }
}

%>
<t:elicom>
    <jsp:attribute name="title">${title} [Elicom]</jsp:attribute>
    <jsp:attribute name="head">
    <script src="${hrefHome}vendor/sigma/sigma.min.js">//</script>
    <script src="${hrefHome}vendor/sigma/sigma.plugins.dragNodes.js">//</script>
    <script src="${hrefHome}vendor/sigma/sigma.exporters.image.js">//</script>
    <script src="${hrefHome}vendor/sigma/sigma.plugins.animate.js">//</script>
    <script src="${hrefHome}vendor/sigma/sigma.layout.fruchtermanReingold.js">//</script>
    <script src="${hrefHome}vendor/sigma/sigma.layout.forceAtlas2.js">//</script>
    <script src="${hrefHome}vendor/sigma/sigma.layout.noverlap.js">//</script>
    <script src="${hrefHome}static/sigmot.js">//</script>
    <style>
span.left {
    display: inline-block;
    text-align: right;
    width: 50ex;
}
span.right {
    display: inline-block;
    width: 70ex;
    text-align: left;
}
div.line {
    width: 120ex;
    margin-left: auto;
    margin-right: auto;
}

    </style>
    </jsp:attribute>
    <jsp:body>
        <form class="row elicom" name="elicom" action="" autocomplete="off">
            <fieldset class="multiple left">
                <legend>Expéditeur(s)</legend>
                ${sender}
                <input type="text" class="multiple" data-url="data/sender.ndjson" data-name="senderid"/>
            </fieldset>
            <fieldset class="center">
                <legend>Mots clés</legend>
                <input type="text" name="q" autocomplete="off" value="${q}"/>
                <button type="submit">Rechercher</button>
            </fieldset>
            <fieldset class="multiple right">
                <legend>Destinataire(s)</legend>
                ${receiver}
                <input type="text" class="multiple" data-url="data/receiver.ndjson" data-name="receiverid"/>
            </fieldset>
            <!-- 
            <div>
                <input placeholder="Mots clés"/>
                <div>
                    <label>De</label>
                    <input size="4"/>
                    <label>à</label>
                    <input size="4"/>
                </div>
            </div>
        <div>Lieux : …</div>
        <div>Graphe</div>
             -->
        </form>
        <div id="graph" class="graph" oncontextmenu="return false">
        </div>
        <div class="butbar">
            <button class="turnleft but" type="button" title="Rotation vers la gauche">↶</button>
            <button class="turnright but" type="button" title="Rotation vers la droite">↷</button>
            <button class="noverlap but" type="button" title="Écarter les étiquettes">↭</button>
            <button class="zoomout but" type="button" title="Diminuer">–</button>
            <button class="zoomin but" type="button" title="Grossir">+</button>
            <button class="fontdown but" type="button" title="Diminuer le texte">S↓</button>
            <button class="fontup but" type="button" title="Grossir le texte">S↑</button>
            <button class="shot but" type="button" title="Prendre une photo">📷</button>
            <!--
            <button class="colors but" type="button" title="Gris ou couleurs">◐</button>
            <button class="but restore" type="button" title="Recharger">O</button>
            <button class="FR but" type="button" title="Spacialisation Fruchterman Reingold">☆</button>
           -->
            <button class="mix but" type="button" title="Mélanger le graphe">♻</button>
            <button class="atlas2 but" type="button" title="Démarrer ou arrêter la gravité atlas 2">▶</button>
             <!--
             <span class="resize interface" style="cursor: se-resize; font-size: 1.3em; " title="Redimensionner la feuille">⬊</span>
             -->
        </div>
        
        <div id="conc" data-url="data/conc">
        </div>
    </jsp:body>
</t:elicom>
