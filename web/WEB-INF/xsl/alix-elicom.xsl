<?xml version="1.0" encoding="UTF-8"?>
<!--
Index TEI/Elicom files in lucene/Alix

LGPL  http://www.gnu.org/licenses/lgpl.html
© 2021 Frederic.Glorieux@fictif.org & Opteos

Reçoit une lettre en un seul fichier
-->
<xsl:transform version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:alix="http://alix.casa"
  xmlns:saxon="http://saxon.sf.net/"


  exclude-result-prefixes="tei saxon"
>
  <xsl:import href="elicom.xsl"/>
  <xsl:output indent="yes" encoding="UTF-8" method="xml"/>
  
  <!-- Name of file, provided by caller -->
  <xsl:param name="filename"/>
  
  <xsl:template match="/">
    <xsl:apply-templates mode="alix"/>
  </xsl:template>
  
  <!-- Default cross all -->
  <xsl:template match="*" mode="alix">
    <xsl:apply-templates select="*" mode="alix"/>
  </xsl:template>
  
  <xsl:template match="text()" mode="alix"/>
  
  
  <!-- One letter by file with meta in <teiHeader> -->
  <xsl:template match="/*" mode="alix">
    <xsl:text>&#10;</xsl:text>
    <alix:document>
      <xsl:attribute name="xml:id">
        <xsl:choose>
          <xsl:when test="$filename != ''">
            <xsl:value-of select="$filename"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:message terminate="no">NO id for this book, will be hard to retrieve</xsl:message>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:apply-templates mode="alix"/>
      <xsl:text>&#10;</xsl:text>
    </alix:document>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>
  
  <xsl:template match="tei:fileDesc" mode="alix">
    <xsl:apply-templates select="tei:titleStmt" mode="alix"/>
  </xsl:template>

  <xsl:template match="tei:titleStmt" mode="alix">
    <xsl:apply-templates select="tei:title[1]" mode="alix"/>
  </xsl:template>
  
  <xsl:template match="tei:fileDesc/tei:titleStmt/tei:title" mode="alix">
    <xsl:text>&#10;  </xsl:text>
    <alix:field name="title" type="meta">
      <xsl:apply-templates mode="value"/>
    </alix:field>
  </xsl:template>
  

  <xsl:template match="tei:body" mode="alix">
    <xsl:apply-templates select=".//tei:persName" mode="alix"/>
    <xsl:apply-templates select=".//tei:placeName" mode="alix"/>
    <xsl:apply-templates select=".//tei:name" mode="alix"/>
    <xsl:apply-templates select=".//tei:rs" mode="alix"/>
    <xsl:text>&#10;  </xsl:text>
    <alix:field name="text" type="text">
      <xsl:text>&#10;</xsl:text>
      <article class="letter">
        <!-- Id ? -->
        <xsl:apply-templates/>
        <xsl:if test=".//tei:note">
          <xsl:processing-instruction name="index_off"/>
          <footer class="footnotes">
            <xsl:apply-templates mode="footnote"/>
          </footer>
          <xsl:processing-instruction name="index_on"/>
        </xsl:if>
      </article>
      <xsl:text>&#10;  </xsl:text>
    </alix:field>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <!-- One or more sender -->
  <xsl:template match="tei:correspAction[@type='sent']/tei:persName" mode="alix">
    <xsl:variable name="value">
      <xsl:call-template name="key"/>
    </xsl:variable>
    <xsl:if test="normalize-space($value) != ''">
      <xsl:text>&#10;  </xsl:text>
      <alix:field type="facet" name="sender" value="{normalize-space($value)}"/>
    </xsl:if>
  </xsl:template>

  <!-- One or more receiver -->
  <xsl:template match="tei:correspAction[@type='received']/tei:persName" mode="alix">
    <xsl:variable name="value">
      <xsl:call-template name="key"/>
    </xsl:variable>
    <xsl:if test="normalize-space($value) != ''">
      <xsl:text>&#10;  </xsl:text>
      <alix:field type="facet" name="receiver" value="{normalize-space($value)}"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="tei:correspAction[@type='sent']/tei:placeName" mode="alix">
    <xsl:variable name="value">
      <xsl:call-template name="key"/>
    </xsl:variable>
    <xsl:if test="normalize-space($value) != ''">
      <xsl:text>&#10;  </xsl:text>
      <alix:field type="category" name="placeSent" value="{normalize-space($value)}"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="tei:correspAction[@type='received']/tei:placeName" mode="alix">
    <xsl:variable name="value">
      <xsl:call-template name="key"/>
    </xsl:variable>
    <xsl:if test="normalize-space($value) != ''">
      <xsl:text>&#10;  </xsl:text>
      <alix:field type="category" name="placeReceived" value="{normalize-space($value)}"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="tei:persName | tei:rs[@type='person']" mode="alix">
    <xsl:variable name="value">
      <xsl:call-template name="key"/>
    </xsl:variable>
    <xsl:if test="normalize-space($value) != ''">
      <xsl:text>&#10;  </xsl:text>
      <alix:field type="facet" name="pers" value="{normalize-space($value)}"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="tei:placeName | tei:rs[@type='place']" mode="alix">
    <xsl:variable name="value">
      <xsl:call-template name="key"/>
    </xsl:variable>
    <xsl:if test="normalize-space($value) != ''">
      <xsl:text>&#10;  </xsl:text>
      <alix:field type="facet" name="place" value="{normalize-space($value)}"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="tei:name | tei:rs" mode="alix">
    <xsl:variable name="value">
      <xsl:call-template name="key"/>
    </xsl:variable>
    <xsl:if test="normalize-space($value) != ''">
      <xsl:text>&#10;  </xsl:text>
      <alix:field type="facet" name="name" value="{normalize-space($value)}"/>
    </xsl:if>
  </xsl:template>
  

  <xsl:template name="key" match="*[@key]" mode="key">
    <xsl:variable name="string">
      <xsl:choose>
        <xsl:when test="@key and normalize-space(@key) != ''">
          <xsl:value-of select="normalize-space(@key)"/>
        </xsl:when>
        <xsl:otherwise>
          <!-- process content to strip notes (but keep typo?) -->
          <xsl:apply-templates mode="value"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!-- Maybe a value in the form : Surname, Firstname (birth, death) -->
    <xsl:variable name="name" select="normalize-space(substring-before(concat(translate($string, ' ', ' '), '('), '('))"/>
    <xsl:choose>
      <!-- Name,  -->
      <xsl:when test="contains($name, ',')">
        <span class="surname">
          <xsl:value-of select="normalize-space(substring-before($name, ','))"/>
        </span>
        <xsl:text>, </xsl:text>
        <xsl:value-of select="normalize-space(substring-after($name, ','))"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="$name"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="*" mode="value">
    <xsl:apply-templates mode="value"/>
  </xsl:template>
  <xsl:template match="tei:emph" mode="value">
    <em>
      <xsl:attribute name="class">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:apply-templates mode="value"/>
    </em>
  </xsl:template>

  <xsl:template match="tei:surname" mode="value">
    <span class="surname">
      <xsl:apply-templates mode="value"/>
    </span>
  </xsl:template>
    

  <xsl:template match="tei:hi" mode="value">
    <xsl:variable name="rend" select="concat(' ', normalize-space(@rend), ' ')"/>
    <xsl:choose>
      <xsl:when test="contains($rend, ' sup ')">
        <sup>
          <xsl:apply-templates mode="value"/>
        </sup>
      </xsl:when>
      <xsl:when test="contains($rend, ' sub ')">
        <sub>
          <xsl:apply-templates mode="value"/>
        </sub>
      </xsl:when>
      <xsl:when test="contains($rend, ' i ')">
        <i>
          <xsl:apply-templates mode="value"/>
        </i>
      </xsl:when>
      <xsl:when test="contains($rend, ' it')">
        <i>
          <xsl:apply-templates mode="value"/>
        </i>
      </xsl:when>
      <xsl:when test="contains($rend, ' b ')">
        <b>
          <xsl:apply-templates mode="value"/>
        </b>
      </xsl:when>
      <xsl:when test="contains($rend, ' bold ')">
        <b>
          <xsl:apply-templates mode="value"/>
        </b>
      </xsl:when>
      <xsl:when test="contains($rend, ' strong ')">
        <strong>
          <xsl:apply-templates mode="value"/>
        </strong>
      </xsl:when>
      <xsl:when test="not(@rend)">
        <i>
          <xsl:apply-templates mode="value"/>
        </i>
      </xsl:when>
      <xsl:otherwise>
        <span class="normalize-space(@rend)">
          <xsl:apply-templates mode="value"/>
        </span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  

  <xsl:template match="tei:note" mode="value"/>
  
  <xsl:template match="tei:correspAction[@type='sent']/tei:date" mode="alix">
    <xsl:variable name="value">
      <xsl:call-template name="alix:date"/>
    </xsl:variable>
    <!-- if more than one, let it cry ? -->
    <xsl:if test="normalize-space($value) != ''">
      <xsl:text>&#10;  </xsl:text>
      <alix:field type="int" name="dateSent" value="{normalize-space($value)}"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="tei:correspAction[@type='received']/tei:date" mode="alix">
    <xsl:variable name="value">
      <xsl:call-template name="alix:date"/>
    </xsl:variable>
    <!-- if more than one, let it cry ? -->
    <xsl:if test="normalize-space($value) != ''">
      <xsl:text>&#10;  </xsl:text>
      <alix:field type="int" name="dateReceived" value="{normalize-space($value)}"/>
    </xsl:if>
  </xsl:template>
  
  <!-- Get a date from as an int -->
  <xsl:template name="alix:date">
    <xsl:choose>
      <xsl:when test="@when">
        <xsl:apply-templates select="@when" mode="date-int"/>
      </xsl:when>
      <xsl:when test="@from">
        <xsl:apply-templates select="@from" mode="date-int"/>
      </xsl:when>
      <xsl:when test="@notBefore">
        <xsl:apply-templates select="@notBefore" mode="date-int"/>
      </xsl:when>
      <xsl:when test="@to">
        <xsl:apply-templates select="@to" mode="date-int"/>
      </xsl:when>
      <xsl:when test="@notAfter">
        <xsl:apply-templates select="@notAfter" mode="date-int"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="date-int" match="@*" mode="date-int">
    <!-- TODO negative years -->
    <xsl:param name="value" select="."/>
    <xsl:variable name="int" select="
        translate(
          substring($value, 1, 10),
          '-',
          ''
        )
    "/>
    <xsl:if test="string(number($int)) != 'NaN'">
      <xsl:value-of select="substring(concat($int, '0000000'), 1, 8)"/>
    </xsl:if>
  </xsl:template>
    
  





</xsl:transform>
