<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gmd="http://www.isotc211.org/2005/gmd"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:gts="http://www.isotc211.org/2005/gts"
    xmlns:gco="http://www.isotc211.org/2005/gco"
    xmlns:gml="http://www.opengis.net/gml"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:geonet="http://www.fao.org/geonetwork"
    xsi:schemaLocation="http://www.isotc211.org/2005/gmd http://www.isotc211.org/2005/gmd/gmd.xsd"
    version="2.0">
    
    <xsl:output method="xml" indent="yes" />
    
    <xsl:template match="/">
        <MD_Metadata>
            <fileIdentifier>
                <gco:CharacterString xmlns:srv="http://www.isotc211.org/2005/srv">
                    <xsl:copy-of select="/metadata/dataIdInfo/descKeys/thesaName[@uuidref]" />
                </gco:CharacterString>
            </fileIdentifier>
            <language>
                <gco:CharacterString>
                    <xsl:copy-of select="/metadata/dataIdInfo/dataLang/languageCode[@value]"/>
                </gco:CharacterString>
            </language>
            <characterSet>
                <MD_CharacterSetCode codeListValue="utf8"
                    codeList="http://www.isotc211.org/2005/resources/codeList.xml#MD_CharacterSetCode"
                />
            </characterSet>
            <contact>
                <CI_ResponsibleParty>
                    <organisationName>
                        <gco:CharacterString>Scholars' Lab</gco:CharacterString>
                    </organisationName>
                    <contactInfo>
                        <CI_Contact>
                            <phone>
                                <CI_Telephone>
                                    <voice>
                                        <gco:CharacterString>1-434-243-8800</gco:CharacterString>
                                    </voice>
                                </CI_Telephone>
                            </phone>
                            <address>
                                <CI_Address>
                                    <deliveryPoint>
                                        <gco:CharacterString>Alderman Library, PO Box 400113</gco:CharacterString>
                                    </deliveryPoint>
                                    <city>
                                        <gco:CharacterString>Charlottesville</gco:CharacterString>
                                    </city>
                                    <administrativeArea>
                                        <gco:CharacterString>VA</gco:CharacterString>
                                    </administrativeArea>
                                    <postalCode>
                                        <gco:CharacterString>22904-00113</gco:CharacterString>
                                    </postalCode>
                                    <country>
                                        <gco:CharacterString>USA</gco:CharacterString>
                                    </country>
                                    <electronicMailAddress>
                                        <gco:CharacterString>scholars.lab@gmail.com</gco:CharacterString>
                                    </electronicMailAddress>
                                </CI_Address>
                            </address>
                        </CI_Contact>
                    </contactInfo>
                    <role>
                        <CI_RoleCode codeListValue="pointOfContact" odeList="http://www.isotc211.org/2005/resources/codeList.xml#CI_RoleCode" />
                    </role>
                </CI_ResponsibleParty>
            </contact>
            
            <dateStamp>
                <gco:DateTime xmlns:srv="http://www.isotc211.org/2005/srv">
                    <!-- may need to calculate this from the Esri/CreaDate and Esri/CreaTime -->
                    <xsl:value-of select="current-dateTime()"/>
                </gco:DateTime>
            </dateStamp>
            
            <metadataStandardName>
                <gco:CharacterString xmlns:srv="http://www.isotc211.org/2005/srv">ISO 19115:2003/19139</gco:CharacterString>
            </metadataStandardName>
            <metadataStandardVersion>
                <gco:CharacterString xmlns:srv="http://www.isotc211.org/2005/srv">1.0</gco:CharacterString>
            </metadataStandardVersion>
            
            <referenceSystemInfo>
                <MD_ReferenceSystem>
                    <referenceSystemIdentifier>
                        <RS_Identifier>
                            <code>
                                <gco:CharacterString><xsl:apply-templates select="/metadata/Esri/DataProperties/coordRef"/></gco:CharacterString>
                            </code>
                        </RS_Identifier>
                    </referenceSystemIdentifier>
                </MD_ReferenceSystem>
            </referenceSystemInfo>
            
        </MD_Metadata>
    </xsl:template>
    
    <xsl:template match="coordRef">
        <xsl:variable name="readable">
            <xsl:copy-of select="translate(geogcsn, '_', ' ')"/>
        </xsl:variable>
        <xsl:value-of select="replace($readable, 'GCS ', '')"/>
    </xsl:template>
    


</xsl:stylesheet>