<?xml version='1.0' encoding='UTF-8'?>
<xsl:transform version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns="http://www.w3.org/1999/xhtml" 
  xmlns:tei="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="tei">
  <xsl:output encoding="UTF-8" indent="yes" media-type="text/html" method="xml"/>
  <xsl:param name="theme">theme/</xsl:param>
  <xsl:template match="/*">
    <html>
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>
          <xsl:value-of select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title"/>
        </title>
        <link rel="stylesheet" id="twenty-twenty-one-style-css" href="{$theme}style.css?ver=1.2" media="all"/>
        <!-- Hook -->
        <link rel="stylesheet" id="rougemont-css" href="{$theme}delacroix.css" media="all"/>
        <meta charset="UTF-8"/>
        <link rel="preconnect" href="https://fonts.gstatic.com"/>
        <link href="https://fonts.googleapis.com/css2?family=Bodoni+Moda:ital,wght@0,400;0,700;1,400;1,700&amp;family=Oswald:wght@300&amp;display=swap" rel="stylesheet"/>
        
      </head>
      <body class="page-template-default page page-id-8 page-parent custom-background wp-embed-responsive is-light-theme has-background-white singular has-main-navigation">
        <div id="page" class="site">
          <header id="masthead" class="site-header has-title-and-tagline has-menu" role="banner">
            <div class="site-branding">
              <h1 class="site-title">Correspondance</h1>
              <p class="site-description">d’Eugène Delacroix</p>
            </div>
            <nav id="site-navigation" class="primary-navigation" role="navigation" aria-label="Menu principal">
              <div class="menu-button-container">
                <button id="primary-mobile-menu" class="button" aria-controls="primary-menu-list" aria-expanded="false">
                  <span class="dropdown-icon open">Menu <svg class="svg-icon" width="24" height="24" aria-hidden="true" role="img" focusable="false" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" clip-rule="evenodd" d="M4.5 6H19.5V7.5H4.5V6ZM4.5 12H19.5V13.5H4.5V12ZM19.5 18H4.5V19.5H19.5V18Z" fill="currentColor"/></svg>
                  </span>
                  <span class="dropdown-icon close">Fermer <svg class="svg-icon" width="24" height="24" aria-hidden="true" role="img" focusable="false" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" clip-rule="evenodd" d="M12 10.9394L5.53033 4.46973L4.46967 5.53039L10.9393 12.0001L4.46967 18.4697L5.53033 19.5304L12 13.0607L18.4697 19.5304L19.5303 18.4697L13.0607 12.0001L19.5303 5.53039L18.4697 4.46973L12 10.9394Z" fill="currentColor"/></svg>
                  </span>
                </button>
                <!-- #primary-mobile-menu -->
              </div>
              <!-- .menu-button-container -->
              <div class="primary-menu-container">
                <ul id="primary-menu-list" class="menu-wrapper">
                  <li class="menu-item menu-item-type-custom menu-item-object-custom current-menu-item current_page_item menu-item-home menu-item-34">
                    <a class="tab">Les lettres</a>
                  </li>
                  <li class="menu-item menu-item-type-custom menu-item-object-custom current-menu-item current_page_item menu-item-home menu-item-34">
                    <a class="tab">Index</a>
                  </li>
                  <li class="menu-item menu-item-type-custom menu-item-object-custom current-menu-item current_page_item menu-item-home menu-item-34">
                    <a class="tab">Lab</a>
                  </li>
                  <li class="menu-item menu-item-type-custom menu-item-object-custom current-menu-item current_page_item menu-item-home menu-item-34">
                    <a class="tab">À propos</a>
                  </li>
                </ul>
              </div>
            </nav>
            <form>
              <input name="q"/>
            </form>
          </header>
          <div id="content" class="site-content">
            
            <div id="primary" class="content-area">
              <main id="main" class="site-main" role="main">
                
                <article class="page type-page status-publish hentry entry">
                  
                  <header class="entry-header alignwide">
                    <h1 class="entry-title">
                      <xsl:apply-templates select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title/node()"/>
                    </h1>
                    <!-- ça passe ? -->
                    <xsl:apply-templates select="tei:teiHeader"/>
                    
                  </header><!-- .entry-header -->
                  
                  <div class="entry-content">
                    <div class="letter">
                      <xsl:apply-templates select="tei:text"/>
                    </div>
                    <footer class="footnotes">
                      <xsl:apply-templates select="tei:text" mode="footnote"/>
                    </footer>
                  </div><!-- .entry-content -->
                  
                </article><!-- #post-8 -->
              </main><!-- #main -->
            </div>
            <footer id="colophon" class="site-footer" role="contentinfo">
              
              
                   
              
              
              <nav aria-label="Menu secondaire" class="footer-navigation">
                <ul class="footer-navigation-wrapper">
                  <li class="menu-item menu-item-type-custom menu-item-object-custom menu-item-home"><a><span>Remerciements</span></a></li>
                  <li class="menu-item menu-item-type-post_type menu-item-object-page current-menu-item page_item"><a aria-current="page"><span>Contact</span></a></li>
                  <li class="menu-item menu-item-type-post_type menu-item-object-page current-menu-item page_item"><a aria-current="page"><span>Crédits</span></a></li>
                  <li class="menu-item menu-item-type-post_type menu-item-object-page current-menu-item page_item"><a aria-current="page"><span>Principes de transcription</span></a></li>
                  <li class="menu-item menu-item-type-post_type menu-item-object-page current-menu-item page_item"><a aria-current="page"><span>©</span></a></li>
                </ul><!-- .footer-navigation-wrapper -->
              </nav><!-- .footer-navigation -->
              <div class="site-info">
                <div class="site-name">
                  <a>Correspondance d’Eugène Delacroix</a>
                </div><!-- .site-name -->
                <div class="powered-by">
                  Fièrement propulsé par <a href="https://fr.wordpress.org/">WordPress</a>			</div><!-- .powered-by -->
                
              </div><!-- .site-info -->
            </footer>
          </div>
        </div>
      </body>
    </html>
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
    
    ">
    <span class="{local-name()}">
      <xsl:apply-templates/>
    </span>
    
  </xsl:template>
  <xsl:template match="tei:hi">
    <xsl:variable name="el">
      <xsl:choose>
        <xsl:when test="@rend = 'it'">i</xsl:when>
        <xsl:when test="@rend = 'i'">i</xsl:when>
        <xsl:when test="@rend = 'u'">u</xsl:when>
        <xsl:otherwise>em</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:element name="{$el}">
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>
  
  <!-- 
  <msIdentifier>
    <country>Pays-Bas</country>
    <settlement>Amsterdam</settlement>
    <institution>Bibliothèque de l’Université</institution>
    <idno>OTM hs. 43 Dz 47 a</idno>
  </msIdentifier>
  
  -->
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
  <xsl:template match="*">
    <b class="el">&lt;<xsl:value-of select="name()"/>&gt;</b>
    <xsl:apply-templates/>
    <b class="el">&lt;/<xsl:value-of select="name()"/>&gt;</b>
  </xsl:template>
</xsl:transform>
