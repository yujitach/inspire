<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" xmlns:m="http://www.loc.gov/MARC21/slim">
	<xsl:template match="m:collection">
		<results>
		<xsl:for-each select="m:record">
			<document>
			<xsl:call-template name="inspire_key"/>
			<xsl:call-template name="spires_key"/>
			<xsl:call-template name="spires_tex_key"/>
			<xsl:call-template name="title"/>
			<xsl:call-template name="authaffgrp"/>
			<xsl:call-template name="collaboration"/>
			<xsl:call-template name="abstract"/>
			<xsl:call-template name="eprint"/>
			<xsl:call-template name="pages"/>
			<xsl:call-template name="journal"/>
			<xsl:call-template name="date"/>
			</document>
		</xsl:for-each>
		</results>
	</xsl:template>
	<xsl:template name="inspire_key">
		<inspire_key>
		<xsl:value-of select="m:controlfield"/>
		</inspire_key>
	</xsl:template>
	<xsl:template name="spires_key">
		<xsl:for-each select="m:datafield[@tag='970']">
			<spires_key>
				<xsl:value-of select="substring(m:subfield,8)"/>
			</spires_key>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="spires_tex_key">
		<xsl:for-each select="m:datafield[@tag='035']">
			<xsl:if test="m:subfield[@code='9']='SPIRESTeX'">
				<spires_tex_key>
					<xsl:value-of select="m:subfield[@code='z']"/>
				</spires_tex_key>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="authaffgrp">
		<authaffgrp>
			<xsl:for-each select="m:datafield[@tag='100']">
				<author>
					<xsl:value-of select="m:subfield"/>
				</author>
			</xsl:for-each>
			<xsl:for-each select="m:datafield[@tag='700']">				
				<author>
					<xsl:value-of select="m:subfield"/>
				</author>
			</xsl:for-each>
		</authaffgrp>
	</xsl:template>
	<xsl:template name="collaboration">
		<xsl:for-each select="m:datafield[@tag='710']">
			<collaboration>
				<xsl:value-of select="m:subfield"/>
			</collaboration>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="abstract">
		<xsl:for-each select="m:datafield[@tag='520']">
                        <xsl:if test="m:subfield[@code='9']='arXiv'">
                            <abstract>
                                    <xsl:value-of select="m:subfield[@code='a']"/>
                            </abstract>
                        </xsl:if>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="eprint">
		<xsl:for-each select="m:datafield[@tag='037']">
			<xsl:if test="m:subfield[@code='9']='arXiv'">
				<eprint>
					<xsl:value-of select="m:subfield[@code='a']"/>
				</eprint>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="title">
		<xsl:for-each select="m:datafield[@tag='245']">
			<title>
				<xsl:value-of select="m:subfield[@code='a']"/>
			</title>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="pages">
		<xsl:for-each select="m:datafield[@tag='300']">
			<pages>
				<xsl:value-of select="m:subfield"/>
			</pages>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="journal">
		<xsl:for-each select="m:datafield[@tag='773']">
			<xsl:if test="m:subfield[@code='p']!=''">
			<journal>
				<name>
					<xsl:value-of select="m:subfield[@code='p']"/>
				</name>
				<volume>
					<xsl:value-of select="m:subfield[@code='v']"/>
				</volume>
				<page>
					<xsl:value-of select="m:subfield[@code='c']"/>
				</page>
				<year>
					<xsl:value-of select="m:subfield[@code='y']"/>
				</year>
			</journal>
			<doi>
				<xsl:value-of select="m:subfield[@code='a']"/>
			</doi>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="date">
	    <xsl:for-each select="m:datafield[@tag='961']">
		<xsl:if test="m:subfield[@code='x']!=''">
		    <xsl:variable name="date" select="translate(m:subfield,'-','')"/>
		    <date>
			<xsl:choose>
			    <xsl:when test="string-length($date)=8">
				<xsl:value-of select="$date"/>
			    </xsl:when>
			    <xsl:when test="string-length($date)=6">
				<xsl:value-of select="concat($date,'00')"/>
			    </xsl:when>
			</xsl:choose>
		    </date>
		</xsl:if>
	    </xsl:for-each>
	</xsl:template>
</xsl:stylesheet>
