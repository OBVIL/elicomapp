<%@tag description="Elicom template" pageEncoding="UTF-8"%>
<%@attribute name="hrefHome" type="java.lang.String" required="true" %>
<%@attribute name="title" type="java.lang.String" required="true" %>
<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8"/>
        <title>${title}</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes"/>
        <link href="${hrefHome}static/alix.css" rel="stylesheet"/>
    </head>
    <body>
        <header id="header">
            Onglets
        </header>
        <main id="main">
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