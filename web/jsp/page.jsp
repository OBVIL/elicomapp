<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@taglib prefix="t" tagdir="/WEB-INF/tags" %>
<%@ page import="java.io.File"%>

<%
String hrefHome = "";
String path = (String)request.getAttribute("path");
if (path != null) {
    for (int i = 1, len = path.length(); i < len; i++) {
        if (path.charAt(i) == '/') {
            hrefHome += "../";
        }
    }
}
request.setAttribute("hrefHome", hrefHome);

File file = new File(pageContext.getServletContext().getRealPath(path+".html"));
String include = path + ".html";
if (!file.exists()) {
    include = "/404.html";
}

request.setAttribute("info", file);
request.setAttribute("include", include);
%>
<t:elicom>
    <jsp:attribute name="title">${title} [Elicom]</jsp:attribute>
    <jsp:attribute name="hrefHome">${hrefHome}</jsp:attribute>
    <jsp:attribute name="head">
    </jsp:attribute>
    <jsp:body>
        <p>${path}</p>
        <p>${info}</p>
        <jsp:include page="${include}"/>
    </jsp:body>
</t:elicom>