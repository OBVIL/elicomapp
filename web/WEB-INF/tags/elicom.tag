<%@ tag description="Elicom template" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ tag import="alix.web.JspTools" %>
<%@ tag import="alix.web.Link" %>
<%@attribute name="title" type="java.lang.String" required="true" %>
<%@attribute name="head" fragment="true" %>
<%@attribute name="header" fragment="true" %>
<%@attribute name="inc" fragment="true" %>
<%!

static public String link(final String hrefHome, final String path, final String href, final String label, final String hint)
{
    StringBuilder sb = new StringBuilder();
    sb.append("<a");
    sb.append(" href=\"");
    if ("".equals(href) && "".equals(hrefHome)) {
        sb.append("./");
    }
    else if ("".equals(href)) {
        sb.append(hrefHome);
    }
    else {
        sb.append(hrefHome).append(href);
    }
    boolean first = true;
    /* ? 
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
    sb.append(" class=\"tab");
    if (path.equals("/"+href)) {
        sb.append(" selected");
        // index ?
    }
    sb.append("\"");
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
        <jsp:invoke fragment="head"/>
    </head>
    <body>
        <header id="header">
            <nav class="tabs">
                <%= link(hrefHome, path, "apropos", "Présentation", null) %>
                <%= link(hrefHome, path, "", "Explorer les correspondances", null) %>
                <%= link(hrefHome, path, "aide", "Aide et contact", null) %>
            </nav>
            <jsp:invoke fragment="header"/>
        </header>
        <main id="main">
            <jsp:invoke fragment="inc"/>
            <jsp:doBody/>
        </main>
        <footer id="footer">
            <nav>
                <a>Contact</a>
                <a>Crédits</a>
                <a>Principe de transciption</a>
                <a>©</a>
            </nav>
        </footer>
    </body>
</html>