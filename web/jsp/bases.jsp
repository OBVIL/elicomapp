<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%
// list of bases
StringBuilder sb = new StringBuilder();
sb.append("\n<ul>");
for (Map.Entry<String, Alix> entry : Alix.pool.entrySet()) {
    String corpusId = entry.getKey();
    sb.append("\n    <li>");
    sb.append("<a href=\"" + corpusId + "/\">");
    sb.append(entry.getValue().props.get("label"));
    sb.append("</a>");
    sb.append("</li>");
}
sb.append("\n</ul>\n");
// load page as a string
String path = pageContext.getServletContext().getRealPath("/html/bases.html");
String html = Files.readString(Paths.get(path));
html = html.replace("${bases}", sb.toString());
request.setAttribute("html", html);
%>
<tag:template>
    <jsp:attribute name="title">Bases installées [Elicom]</jsp:attribute>
    <jsp:body>
    ${path}
        <div class="text">
            ${html}
        </div>
    </jsp:body>
</tag:template>
