<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
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
request.setAttribute("yearmin", fyear.min());
request.setAttribute("yearmax", fyear.max());
int year1 = tools.getInt(YEAR1, fyear.min());
if (year1 < fyear.min()) year1 = fyear.min();
request.setAttribute(YEAR1, year1);
int year2 = tools.getInt(YEAR2, fyear.max());
if (year2 > fyear.max()) year2 = fyear.max();
if (year2 < year1) year2 = year1;
request.setAttribute(YEAR2, year2);


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
            <div class="center">
                <div class="bislide">
                    Dates :
                    <input name="year1" step="1" value="${year1}" min="${yearmin}" max="${yearmax}" type="range"/>
                    <input name="year2" step="1" value="${year2}" min="${yearmin}" max="${yearmax}" type="range"/>
                    <span class="values"></span>
                </div>
            </div>
            <div class="arelation">
                <fieldset class="multiple left">
                    ${corres1}
                    <input placeholder="Correspondant ?" type="text" class="multiple" data-url="data/corres1.ndjson" id="corres1" data-name="corres1"/>
                </fieldset>
                <div id="relwords" data-url="data/relwords">
                </div>
                <fieldset class="multiple right">
                    ${corres2}
                    <input placeholder="Correspondant ?" type="text" class="multiple" data-url="data/corres2.ndjson" id="corres2" data-name="corres2"/>
                </fieldset>
            </div>
            <div class="center">
                <button type="button" onclick="this.form.q.value=''; this.form.submit();">🞭</button>
                <input name="q" value="${q}" type="text" placeholder="Mot ?"/>
                <button type="submit">▶</button>
            </div>
        </form>
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
    </jsp:body>
</t:elicom>
