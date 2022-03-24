<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>

<%@ page import="java.text.*"%>
<%@ page import="java.util.*"%>
<%@ page import="java.io.IOException"%>

<%@ page import="org.apache.lucene.analysis.Analyzer"%>
<%@ page import="org.apache.lucene.document.Document"%>
<%@ page import="org.apache.lucene.index.IndexReader"%>
<%@ page import="org.apache.lucene.index.Term"%>
<%@ page import="org.apache.lucene.search.*"%>

<%@ page import="alix.fr.Tag" %>
<%@ page import="alix.lucene.Alix" %>
<%@ page import="alix.lucene.search.*" %>
<%@ page import="alix.Names" %>
<%@ page import="alix.util.*" %>
<%@ page import="alix.web.*" %>
<%@ page import="alix.web.Error" %>

<%!
/** Load bases from WEB-INF/, one time */
static {
    if (!Webinf.bases) {
        Webinf.bases();
    }
}

final String TEXT = "text";


/** Get an alix instance */
public Alix alix(JspTools tools, StringBuilder html) throws IOException
{
    //test if Alix available with at least on base
    if (Alix.pool.size() < 1) {
        if (html != null) {
            html.append(Error.BASE_NONE.html() + "\n");
        }
        else {
            tools.out.println("{\"errors\":" + Error.BASE_NONE.json() + "}");
        }
        tools.response.setStatus(Error.BASE_NONE.status());
        return null;
    }
    Alix alix = (Alix) tools.getMap("base", Alix.pool, null, "alix.base");
    String baseName = tools.request().getParameter("base");
    if (alix == null && baseName != null) {
        if (html != null) {
            html.append(Error.BASE_NOTFOUND.html(baseName));
        }
        else {
            tools.out.println("{\"errors\":" + Error.BASE_NOTFOUND.json(baseName) + "}");
        }
        tools.response.setStatus(Error.BASE_NOTFOUND.status());
        return null;
    }
    else if (alix == null) {
        baseName = (String) Alix.pool.keySet().toArray()[0];
        alix = Alix.pool.get(baseName);
    }
    return alix;
}

/** Carry multiple parameters accross pages and  */
public class Pars {
    String q; // word query
    String f; // a possible field name (lemma or forms)
    int start; // start record in search results
    int hpp; // hits per page
    int left; // coocs, left context in words
    int right; // coocs, right context in words
    
    // not verified
    OptionCat cat; // word categories to filter
    OptionOrder order;// order in list of terms and facets
    int limit; // results, limit of result to show
    int dist; // wordnet, context width in words
    int nodes; // number of nodes in wordnet
    boolean expression; // kwic, filter multi word expression
    // too much scoring algo
    OptionDistrib distrib; // ranking algorithm, tf-idf like
    OptionMI mi; // proba kind of scoring, not tf-idf, [2, 2]

    String href;
    String[] forms;
    OptionSort sort;

}


%>