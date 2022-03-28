<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="java.io.File"%>
<%
String path = (String)request.getAttribute("path");
String realPath = pageContext.getServletContext().getRealPath(path + ".html");
request.setAttribute("info", realPath);
String include = "/404.html";
if (realPath != null) {
    if (new File(realPath).exists()) {
        include = path + ".html";
    }
}
request.setAttribute("include", include);
%>
<t:elicom>
    <jsp:attribute name="title">${title} [Elicom]</jsp:attribute>
    <jsp:attribute name="head">
    </jsp:attribute>
    <jsp:body>
        <div class="text">
            <jsp:include page="${include}"/>
        </div>
    </jsp:body>
</t:elicom>