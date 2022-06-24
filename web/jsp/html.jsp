<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="java.io.File"%>
<%
String base = request.getParameter("base");
String p = request.getParameter("page");


do {
    String path = "/html/" + base + "/" + p + ".html";
    String realPath = pageContext.getServletContext().getRealPath(path);
    if (realPath != null && new File(realPath).exists()) {
        request.setAttribute("include", path);
        break;
    }
    path = "/html/" + p + ".html";
    realPath = pageContext.getServletContext().getRealPath(path);
    if (realPath != null && new File(realPath).exists()) {
        request.setAttribute("include", path);
        break;
    }
    request.setAttribute("include", "/html/404.html");
    
} while (false);
%>
<tag:template>
    <jsp:attribute name="title">${title} [Elicom]</jsp:attribute>
    <jsp:attribute name="head">
    </jsp:attribute>
    <jsp:body>
        <div class="text">
            <jsp:include page="${include}"/>
        </div>
    </jsp:body>
</tag:template>
