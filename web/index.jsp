<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@taglib prefix="t" tagdir="/WEB-INF/tags" %>
<%
StringBuilder body = new StringBuilder();
request.setAttribute("body", body); // used by the template tag

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
