<%@ tag description="Elicom template" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ tag import="alix.web.JspTools" %>
<%@ tag import="alix.web.Link" %>
<%@attribute name="hrefHome" type="java.lang.String" required="true" %>
<%@attribute name="title" type="java.lang.String" required="true" %>
<%@attribute name="head" fragment="true" %>
<%@attribute name="header" fragment="true" %>
<%@attribute name="inc" fragment="true" %>
<%!

static public enum Tab implements Link {
    index("Présentation", "apropos", "Présentation", new String[]{}),
    explore("Explorer les correspondances", "", "Présentation", new String[]{}),
    kwic(null, "conc.jsp", null, new String[]{"q"}),
    doc(null, "doc.jsp", null, new String[]{"q"}),
    about("Aide et contact", "aide", null, null),
    ;

    final public String href;
    public String href() { return href; }
    final public String label;
    public String label() { return label; }
    final public String hint;
    public String hint() { return hint; }
    final public String[] pars;
    public String[] pars() { return pars; }
    
    private Tab(final String label, final String href, final String hint, final String[] pars) {
        this.label = label ;
        this.href = href;
        this.hint = hint;
        if (pars == null) this.pars = new String[0];
        else this.pars = pars;
    }


}
%>
<%
JspTools tools = new JspTools((javax.servlet.jsp.PageContext)jspContext);
String q = tools.getString("q", "");
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
                <%= Tab.about.nav(request, (String)request.getAttribute("hrefHome")) %>
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