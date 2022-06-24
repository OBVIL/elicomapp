<%@ tag description="Elicom template" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ tag import="alix.web.JspTools" %>
<%@ tag import="alix.web.Link" %>
<%@attribute name="title" type="java.lang.String" required="true" %>
<%@attribute name="head" fragment="true" %>
<%@attribute name="header" fragment="true" %>
<%@attribute name="inc" fragment="true" %>
<%!

static public String link(final String path, String href, final String label, final String hint)
{
    StringBuilder sb = new StringBuilder();
    sb.append("<a");
    sb.append(" class=\"tab");
    if (path.equals("/"+href)) {
        sb.append(" selected");
        // index ?
    }
    sb.append("\"");
    if ("".equals(href)) href=".";
    sb.append(" href=\"").append(href);
    /* no pars
    boolean first = true;
    for (String par: tab.pars()) {
        String value = request.getParameter(par);
        if (value == null) continue;
        value = JspTools.escape(value);
        if (first) {
            first = false;
            sb.append("?");
        }
        else {
            sb.append("&amp;");
        }
        sb.append(par).append("=").append(value);
    }
    */
    sb.append("\"");
    if (hint != null) sb.append(" title=\"").append(hint).append("\"");
    sb.append(">");
    sb.append(label);
    sb.append("</a>");
    return sb.toString();
}

%>
<%
JspTools tools = new JspTools((javax.servlet.jsp.PageContext)jspContext);
String q = tools.getString("q", "");
String path = (String)request.getAttribute("path");
String page = path.substring(path.lastIndexOf("/"));

String hrefHome = (String)request.getAttribute("hrefHome");



%>
<!DOCTYPE html>
<html lang="fr">
    <head>
        <meta charset="UTF-8"/>
        <title>${title}</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes"/>
        <link href="${hrefHome}vendor/teinte.css" rel="stylesheet"/>
        <link href="${hrefHome}static/alix.css" rel="stylesheet"/>
        <link href="${hrefHome}static/elicom.css" rel="stylesheet"/>
        <jsp:invoke fragment="head"/>
    </head>
    <body>
        <header id="header">
            <%  %>
            <nav class="tabs">
                <%= link(path, hrefHome + ".", "⌂", null) %>
                <%= link(page, "about", "Présentation", null) %>
                <%= link(page, "", "Explorer les correspondances", null) %>
                <%= link(page, "help", "Aide et contact", null) %>
            </nav>
            <jsp:invoke fragment="header"/>
        </header>
        <main id="main">
            <jsp:invoke fragment="inc"/>
            <jsp:doBody/>
        </main>
        <footer id="footer">
            <nav>
            </nav>
        </footer>
        <script src="${hrefHome}static/elicom.js">//</script>
    </body>
</html>