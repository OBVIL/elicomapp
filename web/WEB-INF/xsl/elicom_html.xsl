<?xml version='1.0' encoding='UTF-8'?>
<xsl:transform version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns="http://www.w3.org/1999/xhtml" 
  xmlns:tei="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="tei">
  <xsl:output encoding="UTF-8" indent="yes" media-type="text/html" method="xml" omit-xml-declaration="yes"/>

  
  <xsl:template match="tei:TEI">
    <article class="elicom letter">
      
      <header>
        <h1>
          <xsl:apply-templates select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title/node()"/>
        </h1>
        <xsl:apply-templates select="tei:teiHeader"/>
      </header>
      <div class="text">
        <xsl:apply-templates select="tei:text"/>
      </div>
      <footer class="footnotes">
        <xsl:apply-templates select="tei:text" mode="footnote"/>
      </footer>
    </article>
  </xsl:template>

  <xsl:template match="
      tei:text
    | tei:body
    ">
    <xsl:apply-templates/>
  </xsl:template>
  <xsl:template match="tei:teiHeader">
    <div class="teiHeader">
      <xsl:apply-templates select="tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msIdentifier"/>
      <xsl:apply-templates select="tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:listBibl"/>
    </div>
  </xsl:template>
  <xsl:template match="
      tei:opener
    | tei:closer
    | tei:address
    | tei:addrLine
    | tei:postscript
    | tei:opener/tei:stamp
    | tei:closer/tei:stamp
    | tei:body/tei:stamp
    ">
    <div class="{local-name()}">
      <xsl:apply-templates/>
    </div>
  </xsl:template>
  <xsl:template match="tei:p">
    <p>
      <xsl:apply-templates/>
    </p>
    
  </xsl:template>
  <xsl:template match="
      tei:dateline
    | tei:salute
    | tei:signed
    
    ">
    <p class="{local-name()}">
      <xsl:apply-templates/>
    </p>
    
  </xsl:template>
  <xsl:template match="
      tei:date
    | tei:persName
    | tei:placeName
    | tei:rs
    | tei:stamp
    ">
    <span class="{normalize-space(concat(local-name(), ' ', @type))}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  
  <xsl:template match="tei:del">
    <del class="{normalize-space(concat(local-name(), ' ', @type))}">
      <xsl:apply-templates/>
    </del>
  </xsl:template>
  <xsl:template match="tei:add">
    <ins class="{normalize-space(concat(local-name(), ' ', @type))}">
      <xsl:apply-templates/>
    </ins>
  </xsl:template>
  <xsl:template match="tei:hi">
    <xsl:variable name="rend" select="concat(' ', normalize-space(@rend), ' ')"/>
    <xsl:choose>
      <xsl:when test="contains($rend, ' sup ')">
        <sup>
          <xsl:apply-templates/>
        </sup>
      </xsl:when>
      <xsl:when test="contains($rend, ' sub ')">
        <sub>
          <xsl:apply-templates/>
        </sub>
      </xsl:when>
      <xsl:when test="contains($rend, ' i ')">
        <i>
          <xsl:apply-templates/>
        </i>
      </xsl:when>
      <xsl:when test="contains($rend, ' it')">
        <i>
          <xsl:apply-templates/>
        </i>
      </xsl:when>
      <xsl:when test="contains($rend, ' b ')">
        <b>
          <xsl:apply-templates/>
        </b>
      </xsl:when>
      <xsl:when test="contains($rend, ' bold ')">
        <b>
          <xsl:apply-templates/>
        </b>
      </xsl:when>
      <xsl:when test="contains($rend, ' strong ')">
        <strong>
          <xsl:apply-templates/>
        </strong>
      </xsl:when>
      <xsl:when test="not(@rend)">
        <i>
          <xsl:apply-templates/>
        </i>
      </xsl:when>
      <xsl:otherwise>
        <span class="normalize-space(@rend)">
          <xsl:apply-templates/>
        </span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="tei:emph">
    <em>
      <xsl:apply-templates/>
    </em>
  </xsl:template>

  <xsl:template match="tei:figure">
    <figure>
      <xsl:apply-templates/>
    </figure>
  </xsl:template>
  
  <xsl:template match="tei:quote">
    <blockquote>
      <xsl:if test="@type">
        <xsl:attribute name="class">
          <xsl:value-of select="@type"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates/>
    </blockquote>
  </xsl:template>

  <xsl:template match="tei:label">
    <h4>
      <xsl:if test="@type">
        <xsl:attribute name="class">
          <xsl:value-of select="@type"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates/>
    </h4>
  </xsl:template>
  
  <xsl:template match="tei:lg">
    <div class="lg">
      <xsl:apply-templates/>
    </div>
  </xsl:template>
  
  <xsl:template match="tei:l">
    <div class="l">
      <xsl:apply-templates/>
    </div>
  </xsl:template>
  
  <xsl:template match="tei:msIdentifier">
    <div class="{local-name()}">
      <xsl:for-each select="*">
        <xsl:apply-templates select="."/>
        <xsl:choose>
          <xsl:when test="position() = last()"/>
          <xsl:otherwise> ; </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
      <xsl:text>.</xsl:text>
    </div>
  </xsl:template>

  <xsl:template match="
    tei:msIdentifier/*
    ">
    <span class="{local-name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  
  <xsl:template match="tei:pb" name="pb">
    <xsl:variable name="facs" select="@facs"/>
    <xsl:choose>
      <!-- https://gallica.bnf.fr/ark:/12148/bpt6k1526131p/f104.image -->
      <xsl:when test="contains($facs, 'gallica.bnf.fr/ark:/')">
        <a class="pb facs" href="{$facs}" target="_blank">
          <span class="n">
            <xsl:if test="translate(@n, '1234567890', '') = ''">p. </xsl:if>
            <xsl:value-of select="@n"/>
          </span>
          <img src="{substring-before($facs, '/ark:/')}/iiif/ark:/{substring-after(substring-before(concat($facs, '.image'), '.image'), '/ark:/')}/full/150,/0/native.jpg" data-bigger="{substring-before($facs, '/ark:/')}/iiif/ark:/{substring-after(substring-before(concat($facs, '.image'), '.image'), '/ark:/')}/full/700,/0/native.jpg"/>
        </a>
      </xsl:when>
      <!-- https://api.nakala.fr/iiif/10.34847/nkl.6cb2wtu4/ff9fc9b1a015b0ab1757a3313140c16bced56a55/full/full/0/default.jpg -->
      <xsl:when test="contains($facs, '/full/full/0/')">
        <a class="pb facs" href="{$facs}" target="_blank">
          <span class="n">
            <xsl:if test="translate(@n, '1234567890', '') = ''">p. </xsl:if>
            <xsl:value-of select="@n"/>
          </span>
          <img src="{substring-before($facs, '/full/full/0/')}/full/150,/0/{substring-after($facs, '/full/full/0/')}" data-bigger="{substring-before($facs, '/full/full/0/')}/full/700,/0/{substring-after($facs, '/full/full/0/')}"/>
        </a>
      </xsl:when>
      <xsl:otherwise>
        <span class="pb">
          <xsl:text>[</xsl:text>
          <xsl:if test="translate(@n, '1234567890', '') = ''">p. </xsl:if>
          <xsl:value-of select="@n"/>
          <xsl:text>]</xsl:text>
        </span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Line Break -->
  <xsl:template match="tei:lb">
    <br/>
  </xsl:template>

  <xsl:template match="tei:list">
    <ul>
      <xsl:apply-templates/>
    </ul>
  </xsl:template>

  <xsl:template match="tei:item">
    <li>
      <xsl:apply-templates/>
    </li>
  </xsl:template>
  
  <!-- Spaces vertical or horizontal -->
  <xsl:template match="tei:space">
    <xsl:variable name="nbsp">                             </xsl:variable>
    <xsl:choose>
      <xsl:when test="text() != ''">
        <samp>
          <xsl:value-of select="substring($nbsp, 1, string-length(.))"/>
        </samp>
      </xsl:when>
      <xsl:when test="@extent">
        <samp class="space" style="{@extent}"/>
      </xsl:when>
      <xsl:when test="@unit = 'chars'">
        <samp>
          <xsl:value-of select="substring($nbsp, 1, @quantity)"/>
        </samp>
      </xsl:when>
      <xsl:otherwise>
        <samp class="space" style="width:2em;">    </samp>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates/>
  </xsl:template>
  

  <xsl:template match="tei:table">
    <table>
      <xsl:apply-templates/>
    </table>
  </xsl:template>

  <xsl:template match="tei:row">
    <tr>
      <xsl:apply-templates/>
    </tr>
  </xsl:template>

  <xsl:template match="tei:cell">
    <td>
      <xsl:apply-templates/>
    </td>
  </xsl:template>

  <xsl:template match="tei:cell[@role='label']">
    <th>
      <xsl:apply-templates/>
    </th>
  </xsl:template>
  
  <!-- Footnotes -->
  <xsl:template match="*" mode="footnote">
    <xsl:apply-templates select="*" mode="footnote"/>
  </xsl:template>
  <xsl:template name="id">
    <xsl:choose>
      <xsl:when test="self::tei:note">
        <xsl:text>fn</xsl:text>
        <xsl:call-template name="n"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="generate-id()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="n">
    <xsl:choose>
      <xsl:when test="true()">
        <xsl:number from="tei:text" level="any"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:number from="tei:text" level="any"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="tei:ref">
    <a>
      <xsl:attribute name="href">
        <xsl:call-template name="href"/>
      </xsl:attribute>
      <xsl:apply-templates/>
    </a>
  </xsl:template>
  <xsl:template name="href">
    <xsl:param name="url" select="@target"/>
    <xsl:choose>
      <xsl:when test="starts-with($url, 'http')">
        <xsl:value-of select="$url"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$url"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!-- note in body without call -->
  <xsl:template match="tei:body/tei:note"/>
  <xsl:template match="tei:note">
    <a class="fncall">
      <xsl:attribute name="href">
        <xsl:text>#</xsl:text>
        <xsl:call-template name="id"/>
      </xsl:attribute>
      <xsl:call-template name="n"/>
    </a>
  </xsl:template>
  <xsl:template match="tei:note" mode="footnote">
    <aside class="footnote">
      <a class="fnmarker">
        <xsl:attribute name="id">
          <xsl:call-template name="id"/>
        </xsl:attribute>
        <xsl:attribute name="href">
          <xsl:text>#</xsl:text>
          <xsl:call-template name="id"/>
          <xsl:text>_</xsl:text>
        </xsl:attribute>
        <xsl:call-template name="n"/>
        <xsl:text>.</xsl:text>
      </a>
      <div class="fnbody">
        <xsl:apply-templates/>
      </div>
    </aside>
  </xsl:template>
  <!-- Temp problems in SQL import -->
  <xsl:template match="tei:sup">
    <sup>
      <xsl:apply-templates/>
    </sup>
  </xsl:template>
  
  <!-- specific Voltaire -->
  <xsl:template match="tei:ptr"/>
  
  <!-- See unknow elements -->
  <xsl:template match="*">
    <xsl:message terminate="no">
      <xsl:text>&lt;</xsl:text>
      <xsl:value-of select="name()"/>
      <xsl:text>&gt;</xsl:text>
    </xsl:message>
    <xsl:apply-templates/>
  </xsl:template>
</xsl:transform>
