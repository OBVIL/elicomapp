<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%
StringBuilder body = new StringBuilder();
request.setAttribute("body", body); // used by the template tag

%>
<t:elicom>
    <jsp:attribute name="title">${title} [Elicom]</jsp:attribute>
    <jsp:attribute name="head">
    <style>
span.left {
    display: inline-block;
    text-align: right;
    width: 60ex;
    padding-right: 1ex;
}
span.right {
    display: inline-block;
    width: 70ex;
    text-align: left;
}
div.line {
    width: 130ex;
    margin-left: auto;
    margin-right: auto;
}

    </style>
    </jsp:attribute>
    <jsp:body>
        <form class="row elicom" name="elicom" action="">
            <fieldset class="multiple left">
                <legend>Expéditeur(s)</legend>
                <input type="text" class="multiple" data-url="data/sender.ndjson" data-name="senderid"/>
            </fieldset>
            <fieldset class="center">
                <legend>Mots clés</legend>
                <input type="text" name="q"/>
                <button type="submit">Rechercher</button>
            </fieldset>
            <fieldset class="multiple right">
                <legend>Destinataire(s)</legend>
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
        <div id="conc" data-url="data/conc">
        </div>
    </jsp:body>
</t:elicom>
