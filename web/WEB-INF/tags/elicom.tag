<%@tag description="Elicom template" pageEncoding="UTF-8"%>
<%@tag import="alix.web.Webinf" %>
<%@tag import="alix.web.JspTools" %>
<%@attribute name="hrefHome" type="java.lang.String" required="true" %>
<%@attribute name="title" type="java.lang.String" required="true" %>
<%!
/** Load bases from WEB-INF/, one time */
static {
    if (!Webinf.bases) {
        Webinf.bases();
    }
}

static public enum Tab {
    index("<strong>Elicom</strong>", "index.jsp", "Présentation", new String[]{}) { },
    kwic(null, "conc.jsp", null, new String[]{"q"}) { },
    ;

    final public String label;
    final public String href;
    final public String hint;
    final public String[] pars;
    private Tab(final String label, final String href, final String hint, final String[] pars) {
        this.label = label ;
        this.href = href;
        this.hint = hint;
        if (pars == null) this.pars = new String[0];
        else this.pars = pars;
    }

    public static String nav(final HttpServletRequest request)
    {
        StringBuilder sb = new StringBuilder();
        boolean first = true;
        for(Tab tab:Tab.values()) {
            if (tab.label == null) {
                continue;
            }
            tab.a(sb, request);
            sb.append("\n");
        }
        return sb.toString();
    }

    public void a(final StringBuilder sb, final HttpServletRequest request)
    {
        String here = request.getRequestURI();
        here = here.substring(here.lastIndexOf('/')+1);
        
        sb.append("<a");
        sb.append(" href=\"").append(this.href);
        boolean first = true;
        for (String par: pars) {
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
        sb.append("\"");
        if (hint != null) sb.append(" title=\"").append(hint).append("\"");
        sb.append(" class=\"tab");
        if (this.href.equals(here)) sb.append(" selected");
        else if (here.equals("") && this.href.startsWith("index"))  sb.append(" selected");
        sb.append("\"");
        sb.append(">");
        sb.append(label);
        sb.append("</a>");
    }
}
%>
<%
JspTools tools = new JspTools((javax.servlet.jsp.PageContext)jspContext);
String q = tools.getString("q", "");
%>
<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8"/>
        <title>${title}</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes"/>
        <link href="${hrefHome}vendor/teinte.css" rel="stylesheet"/>
        <link href="${hrefHome}static/alix.css" rel="stylesheet"/>
    </head>
    <body>
        <header id="header">
            <nav class="tabs">
                <%= Tab.nav(request) %>
                <form action="<%= Tab.kwic.href %>">
                    <input type="text" value="<%= q %>"/>
                    <button type="submit">▶</button>
                </form>
            </nav>
        </header>
        <main id="main">
            <div class="row">
                <jsp:doBody/>
            </div>
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