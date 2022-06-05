<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%!

%>
<%
JspTools tools = new JspTools(pageContext);
Alix alix = alix(tools, null);
request.setAttribute("q", JspTools.escape(request.getParameter(Q)));
// request.setAttribute(Q, JspTools.escape(request.getParameter(Q)));

// populate form with senders and receivers
for (String fpar: new String[]{"corres1", "corres2"}) {
    final String fname = CORRES;
    String[] ids = request.getParameterValues(fpar);
    if (ids == null) continue;
    StringBuilder sb = new StringBuilder();
    TreeSet<Integer> idSet = new TreeSet<Integer>();
    final FieldFacet facet = alix.fieldFacet(fname);
    String form = null;
    for (String id: ids) {
        int formId = -1;
        try {
            formId = Integer.parseInt(id);
        }
        catch (Exception e) {
            continue;
        }
        form = facet.form(formId);
        if (form == null) continue;
        if (idSet.contains(formId)) continue;
        idSet.add(formId);
        sb.append("<label class=\"corres\"><a class=\"inputDel\">🞭</a> <input type=\"hidden\" name=\"" + fpar +"\" value=\"" + id + "\"/>" + form +"</label>");
    }
    if (form != null) {
        request.setAttribute(fpar, sb);
    }
}
OptionCat cat = (OptionCat) tools.getEnum("cat", OptionCat.ALL);
request.setAttribute("cats", cat.options("ALL, NOSTOP, SUB, NAME, VERB, ADJ, ADV"));
OptionDistrib distrib = (OptionDistrib) tools.getEnum("distrib", OptionDistrib.BM25);
request.setAttribute("distribs", distrib.options("OCCS, BM25, TFIDF"));
request.setAttribute("hstop", tools.getInt("hstop", 0));

FieldInt fyear = alix.fieldInt(YEAR);
final int min = fyear.min();
request.setAttribute("yearmin", min);
final int max = fyear.max();
request.setAttribute("yearmax", max);
int year1 = tools.getInt(YEAR1, min, max, min);
request.setAttribute(YEAR1, year1);
int year2 = tools.getInt(YEAR2, min, max, max);
if (year2 < year1) year2 = year1;
request.setAttribute(YEAR2, year2);
// produce a year scale

StringBuilder sb = new StringBuilder();
sb.append("<div class=\"ticks\">\n");
sb.append("<div class=\"first\" style=\"left: 0%\">" + min + "</div>");
// loop in years
final int mod = 10;
int year = fyear.min() + (mod - fyear.min() % mod);
final int span = max - min;
for (; year < (max - mod /2); year += mod) {
    final float left = Math.round(1000.0f * (year - min) / span) / 10;
    sb.append("<div style=\"left: " + left + "%\">" + year + "</div>");
}

sb.append("<div class=\"last\" style=\"right: 0%\">" + max + "</div>");
sb.append("</div>\n");
request.setAttribute("scale", sb);
%>
<t:elicom>
    <jsp:attribute name="title">${title} [Elicom]</jsp:attribute>
    <jsp:attribute name="head">
    <style>
span.left {
    display: inline-block;
    text-align: right;
    width: 50ex;
}
span.right {
    display: inline-block;
    width: 70ex;
    text-align: left;
}
div.line {
    width: 120ex;
    margin-left: auto;
    margin-right: auto;
}

    </style>
    </jsp:attribute>
    <jsp:body>
        <form class="elicom" name="elicom" action="" autocomplete="off">
            <div id="fields" class="center">
                <fieldset class="multiple left">
                    ${corres1}
                    <input placeholder="Correspondant ?" type="text" class="multiple" data-url="data/corres1.ndjson" id="corres1" data-name="corres1"/>
                </fieldset>
                <div class="bislide">
                    Dates :
                    <input name="year1" step="1" value="${year1}" min="${yearmin}" max="${yearmax}" type="range"/>
                    <input name="year2" step="1" value="${year2}" min="${yearmin}" max="${yearmax}" type="range"/>
                    <span class="values"></span>
                </div>
                <fieldset class="multiple right">
                    ${corres2}
                    <input placeholder="Correspondant ?" type="text" class="multiple" data-url="data/corres2.ndjson" id="corres2" data-name="corres2"/>
                </fieldset>
            </div>
            <div class="arelation">
                <div id="relwords" data-url="data/relwords">
                </div>
            </div>
            <div id="navres">
                <div>
                    <div class="meta"> </div>
                    <div class="qline">
                        <button type="button" name="clear">🞭</button>
                        <input name="q" value="${q}" type="text" placeholder="Mot ?"/>
                        <button type="submit">▶</button>
                    </div>
                </div>
                <div id="timeplot">
                    ${scale}
                    <canvas id="chronograph" data-url="data/chronograph.txt" width="2000" height="100" data-min="${yearmin}" data-max="${yearmax}">
                    </canvas>
                </div>
            </div>
            <div id="biject">
                <div class="senders">
                </div>
                <svg class="relations" xmlns="http://www.w3.org/2000/svg">
                </svg>
                <div class="receivers">
                </div>
            </div>
            <div id="conc" data-url="data/conc">
            </div>
        </form>
    </jsp:body>
</t:elicom>
