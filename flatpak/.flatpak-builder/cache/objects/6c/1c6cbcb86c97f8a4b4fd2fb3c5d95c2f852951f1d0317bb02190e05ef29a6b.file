<?xml version="1.0"?>
<xsl:stylesheet
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xsd="http://www.w3.org/2001/XMLSchema"
	xmlns="http://www.w3.org/1999/xhtml"
	xmlns:gv="urn:graphviz"
	version="1.0">
	
	<xsl:output method="html" />
	
	<xsl:variable name="arguments" select="document('arguments.xml')" />
	
	<xsl:template match="/">
		<html>
			<head>
				<title>Node, Edge and Graph Attributes</title>
				<style>
					body
						{
							margin: 0px;
							padding: 0px;
							overflow: hidden;
							
							font-family: Georgia;
						}
						
					code
						{
							font-family: Courier;
						}
						
					a
						{
							text-decoration: none;
						}
						
					a:hover
						{
							text-decoration: underline;
						}
						
					#indices
						{
							position: absolute;
							left: 0px;
							width: 200px;
							top: 0px;
							bottom: 0px;										/* IE doesn't use this */
							height: expression(offsetParent.offsetHeight);	/* only IE uses this */
							overflow: auto;
							
							background: #EEEEEE
						}
						
					#contents
						{
							position: absolute;
							left: 210px;
							right:0px;											/* IE doesn't use this */
							width: expression(offsetParent.offsetWidth-210);	/* only IE uses this */
							top: 0px;
							bottom: 0px;										/* IE doesn't use this */
							height: expression(offsetParent.offsetHeight);	/* only IE uses this */
							overflow: auto;
						}
						
					.val
						{
							font-family: Courier;
							color: green;
						}
						
					.attr
						{
							font-family: Courier;
							font-weight: bold;
						}
						
					.comp
						{
						}
						
					.layout
						{
						}
						
					.format
						{
						}
						
					.note
						{
						}
						
					.missing
						{
							color: lightgray;
						}
						
					.heading
						{
							padding-left: 5px;
							padding-right: 5px;
							padding-top: 10px;
							padding-bottom: 2px;
							
							color: gray;
							font-weight: bold;
							font-size: 60%;
						}
						
					.text
						{
							padding-left: 20px;
							padding-bottom: 10px;
							padding-right: 10px;
						}
						
					.index
						{
							padding-left: 20px;
							padding-right: 5px;
							padding-top: 2px;
							padding-bottom: 2px;
							
							display: block;
							font-size: 80%;
							
							color: blue;
						}
						
					.index_selected
						{
							background: #8888FF;
							color: white;
						}
						
					.content
						{
							display: none;
						}
						
					.content_selected
						{
							display: block;
						}
				</style>
				
				<script>
					<xsl:text disable-output-escaping="yes">
						var lastSelected = null;
						
						function addClass (element, newClass)
							{
								if (element)
									{
										var classes = element.className.split (" ");
										for (var i = 0; i &lt; classes.length; ++i)
											if (classes [i] == newClass)
												break;
												
										if (i == classes.length)
											{
												classes.push (newClass);
												element.className = classes.join (" ");
											}
									}
							}
							
						function removeClass (element, oldClass)
							{
								if (element)
									{
										var classes = element.className.split (" ");
										for (var i = 0; i &lt; classes.length; ++i)
											if (classes [i] == oldClass)
												{
													classes.splice (i, 1);
													element.className = classes.join (" ");
													break;
												}
									}
							}
						
						
						function select (selected)
							{
								if (selected != lastSelected)
									{
										// deselect the last selection
										if (lastSelected)
											{
												removeClass (document.getElementById ("index_" + lastSelected.replace (':', '_')), "index_selected");
												removeClass (document.getElementById ("content_" + lastSelected.replace (':', '_')), "content_selected");
											}
									
										lastSelected = selected;
										
										var selectedIndex = document.getElementById ("index_" + lastSelected.replace (':', '_'));
										addClass (selectedIndex, "index_selected");
										
										// ensure selected index is visible in indices source list
										if (selectedIndex)
											{
												var indexTop = selectedIndex.offsetTop;
												var indexBottom = indexTop + selectedIndex.offsetHeight;
												var indicesTop = selectedIndex.offsetParent.scrollTop;
												var indicesBottom = indicesTop + selectedIndex.offsetParent.offsetHeight;
												if (indexBottom &lt; indicesTop || indexTop &gt; indicesBottom)
													selectedIndex.scrollIntoView ();
											}
										
										// display the content associated with the selected index
										addClass (document.getElementById ("content_" + lastSelected.replace (':', '_')), "content_selected");
									}
								return true;
							
							}
							
						function hashed ()
							{
								// check if we navigated to a new internal location e.g. via the back button
								// if so we need to update the selection
								// NOTE: this means there are no real anchors in the HTML at all, we're just simulating them
								var hash = window.location.hash;
								if (hash &amp;&amp; hash.charAt (0) == '#')
									select (hash.substr (1));
								else
									select ("h:introduction");
								return true;
							}
						
						function clicked (event)
							{
								// check to see if an internal link was clicked, if so we need to update the selection
								// NOTE: this is not strictly necessary since hashed () will catch it but it helps with the responsiveness
								var	clickedElement = event.target;
								if (!clickedElement)
									clickedElement = event.srcElement;
								switch (clickedElement.tagName)
									{
										case 'a':
										case 'A':
											var oldHref = window.location.href;
											var oldHash = oldHref.indexOf ('#');
											if (oldHash == -1)
												oldHash = oldHref.length;
												
											var newHref = clickedElement.href;
											var newHash = newHref.indexOf ('#');
											if (newHash == -1)
												newHash = newHref.length;
												
											if (oldHref.substr (0, oldHash) == newHref.substr (0, newHash))
												{
													if (newHash &lt; newHref.length)
														select (newHref.substr (newHash + 1));
													else
														select ("h:introduction");
												}
											break;
									}
								return true;
							}
							
						function loaded ()
							{
								hashed ();
								window.setInterval ("hashed ()", 1000);
								return true;
							}
					</xsl:text>
				</script>
				
			</head>
			<body onload="return loaded ()" onclick="return clicked (event)">
				<div id="indices">

					<!-- display all the attribute type names -->
					<div class="heading">NOTES</div>
					<xsl:for-each select="/xsd:schema/xsd:annotation[@id]">
						<a id="index_h_{@id}" class="index note" href="#h:{@id}">
							<xsl:value-of select="@id" />
						</a>
					</xsl:for-each>
									
					<!-- display all the attribute names -->
					<div class="heading">ATTRIBUTES</div>
					<xsl:for-each select="/xsd:schema/xsd:attribute">
						<a id="index_d_{@name}" class="index attr" href="#d:{@name}">
							<xsl:value-of select="@name" />
						</a>
					</xsl:for-each>
					
					<!-- display all the attribute type names -->
					<div class="heading">TYPES</div>
					<xsl:for-each select="/xsd:schema/xsd:simpleType">
						<a id="index_k_{@name}" class="index type" href="#k:{@name}">
							<xsl:value-of select="@name" />
						</a>
					</xsl:for-each>
					


				</div>
				<div id="contents">
	
					<!-- note content -->
					<xsl:for-each select="/xsd:schema/xsd:annotation[@id]">
						<div id="content_h_{@id}" class="content">
							<div class="text">
								<xsl:apply-templates select="xsd:documentation/*" mode="html" />
							</div>
						</div>
					</xsl:for-each>
								
					<!-- attribute content -->
					<xsl:for-each select="/xsd:schema/xsd:attribute">
						<div id="content_d_{@name}" class="content">
						
							<!-- display the layouts this attribute applies to -->
							<div class="heading">LAYOUTS</div>
							<div class="text">
								<xsl:variable name="attributeLayouts" select="@gv:layouts" />
								<xsl:for-each select="$arguments/xsd:schema/xsd:simpleType[@name='layout']/xsd:restriction/xsd:enumeration">
									<span class="layout">
										<xsl:attribute name="class">layout <xsl:if test="$attributeLayouts and not(contains(concat(' ',$attributeLayouts,' '),concat(' ',@value,' ')))">missing</xsl:if></xsl:attribute>
										<xsl:value-of select="@value" />
									</span>
									<xsl:text> </xsl:text>
								</xsl:for-each>
							</div>							
							
							<!-- display the components this attribute is used by -->
							<div class="heading">COMPONENTS</div>
							<div class="text">
								<xsl:variable name="attributeName" select="@name" />
								<xsl:for-each select="/xsd:schema/xsd:complexType">
									<span class="comp">
										<xsl:attribute name="class">comp <xsl:if test="not(xsd:attribute[@ref=$attributeName])">missing</xsl:if></xsl:attribute>
										<xsl:value-of select="@name" />
									</span>
									<xsl:text> </xsl:text>
								</xsl:for-each>
							</div>

							<!-- display the formats this attribute can output -->
							<div class="heading">FORMATS</div>
							<div class="text">
								<xsl:choose>
									<xsl:when test="@gv:formats">
										<span class="format"><xsl:value-of select="@gv:formats" /></span>
									</xsl:when>
									<xsl:otherwise>
										<span class="format missing">all</span>
									</xsl:otherwise>
								</xsl:choose>
							</div>
							
							<!-- display the type of this attribute -->
							<div class="heading">TYPE</div>
							<div class="text">
								<xsl:choose>
									<xsl:when test="@type='xsd:anyURI'">
										<span class="type">URL</span>
									</xsl:when>
									<xsl:when test="@type='xsd:boolean'">
										<span class="type">bool</span>
									</xsl:when>
									<xsl:when test="@type='xsd:decimal'">
										<span class="type">double</span>
									</xsl:when>
									<xsl:when test="@type='xsd:integer'">
										<span class="type">int</span>
									</xsl:when>
									<xsl:when test="@type='xsd:string'">
										<span class="type">string</span>
									</xsl:when>
									<xsl:when test="not(contains(@type,':'))">
										<a class="type" href="#k:{@type}"><xsl:value-of select="@type" /></a>
									</xsl:when>
								</xsl:choose>
							</div>
							
							<!-- display the attribute default or none if missing -->
							<div class="heading">DEFAULT</div>
							<div class="text">
								<xsl:choose>
									<xsl:when test="@default">
										<span class="val">
											<xsl:value-of select="@default" />
										</span>
									</xsl:when>
									<xsl:otherwise>
										<span class="val missing">none</span>
									</xsl:otherwise>
								</xsl:choose>
							</div>
							
							<!-- display the description from the documentation bits -->
							<div class="heading">DESCRIPTION</div>
							<div class="text">
								<xsl:apply-templates select="xsd:annotation/xsd:documentation/*" mode="html" />
							</div>
							
						</div>
					</xsl:for-each>
					
					<!-- attribute type content -->
					<xsl:for-each select="/xsd:schema/xsd:simpleType">
						<div id="content_k_{@name}" class="content">
						
							<!-- display the values if this is an enumeration -->
							<xsl:if test="xsd:restriction/xsd:enumeration">
								<div class="heading">VALUES</div>
								<div class="text">
									<xsl:for-each select="xsd:restriction/xsd:enumeration">
										<span class="val"><xsl:value-of select="@value" /></span>
										<xsl:text> </xsl:text>
									</xsl:for-each>
								</div>
							</xsl:if>
							
							<!-- display the description from the documentation bits -->
							<div class="heading">DESCRIPTION</div>
							<div class="text">
								<xsl:apply-templates select="xsd:annotation/xsd:documentation/*" mode="html" />
							</div>
						</div>
					</xsl:for-each>



				</div>
			</body>
		</html>
	</xsl:template>
	

	

	<xsl:template match="html:a[@rel='attr']" mode="html" xmlns:html="http://www.w3.org/1999/xhtml">
		<a href="#d:{text()}" class="attr">
			<xsl:apply-templates select="@*|node()" mode="html" />
		</a>
	</xsl:template>
	
	<xsl:template match="html:a[@rel='type']" mode="html" xmlns:html="http://www.w3.org/1999/xhtml">
		<a href="#k:{text()}" class="type">
			<xsl:apply-templates select="@*|node()" mode="html" />
		</a>
	</xsl:template>

	<xsl:template match="html:a[@rel='note']" mode="html" xmlns:html="http://www.w3.org/1999/xhtml">
		<a href="#h:{text()}" class="note">
			<xsl:apply-templates select="@*|node()" mode="html" />
		</a>
	</xsl:template>
	
	<xsl:template match="@*|node()" mode="html">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="html" />
		</xsl:copy>
	</xsl:template>
	
	
</xsl:stylesheet>