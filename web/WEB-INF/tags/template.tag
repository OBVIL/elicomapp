<%@ tag description="Elicom template" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ tag import="alix.web.JspTools" %>
<%@ tag import="alix.web.Link" %>
<%@attribute name="title" type="java.lang.String" required="true" %>
<%@attribute name="head" fragment="true" %>
<%@attribute name="header" fragment="true" %>
<%@attribute name="inc" fragment="true" %>
<%!

String path;


static public String link(String href, final String label, boolean selected, final String hint)
{
    StringBuilder sb = new StringBuilder();
    sb.append("<a");
    sb.append(" class=\"tab");
    if (selected) {
        sb.append(" selected");
        // index ?
    }
    sb.append("\"");
    if (href != null) {
        sb.append(" href=\"").append(href);
        // if ("".equals(href)) href=".";
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
    }
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
path = (String)request.getAttribute("path");

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
                <%
boolean selected = false;
selected = ("/".equals(path))?true:false;
out.println(link(hrefHome + ".", "Accueil", selected, null));
String hrefBase = null;
selected = false;
if (path.length() > 2 && path.indexOf('/', 2) > 0) {
    hrefBase = "";
    for (int i = path.indexOf('/', 2) + 1, len = path.length(); i < len; i++) {
        if (path.charAt(i) == '/') {
            hrefBase += "../";
        }
    }
    hrefBase += ".";
    selected = (path.matches("^/[^/]+/$"))?true:false;
}
out.println(link(hrefBase, "Explorer les correspondances", selected, null));


selected = ("/aide".equals(path))?true:false;
out.println(link(hrefHome + "aide", "Aide et contact", selected, null));

                %>
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