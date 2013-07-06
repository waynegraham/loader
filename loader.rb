#! /usr/bin/env ruby

require 'pp'
require "gdal-ruby/gdal"
require "gdal-ruby/gdalconst"
require "gdal-ruby/osr"

require "nokogiri"

class GdalWrapper

  def initialize(file)
    @gdalfile = Gdal::Gdal.open(file)
  end

  #returns basic size info as a hash
  def size()
    {
      "x" => @gdalfile.RasterXSize,
      "y" => @gdalfile.RasterYSize,
      "bands" => @bands.length,
      "data_type" => @bands[0].data_type()
    }
  end

  #x dimention size
  def xsize()
    @gdalfile.RasterXSize
  end

  #y dim size
  def ysize()
    @gdalfile.RasterYSize
  end

  # gets the projection
  def get_projection
    @gdalfile.get_projection
  end

  #gets the geo transform (wld file traditionally)
  # Returns an array with this information: 
  # [Origin (top left corner), X pixel size, Rotation (0 if north is up),Y
  # Origin (top left corner), Rotation (0 if north is up), Y pixel size *-1 
  # (its negitive)]
  def get_geo_transform()
    @gdalfile.get_geo_transform
  end

  def get_extents
    transform = @gdalfile.get_geo_transform

    #[274785.0, 30.0, 0.0, 4906905.0, 0.0, -30.0]
    #[(0)Origin (top left corner), (1) X pixel size, (2) Rotation (0 if north
    #is up),(3)Y Origin (top left corner), (4) Rotation (0 if north is up), (5)
    #Y pixel size]

    {
      "xmin" => transform[0].to_f.round(6),
      "ymin"=> transform[3].to_f.round(6) + ysize().to_f.round(6) * transform[5].to_f.round(6),
      "ymax" => transform[3].to_f.round(6),
      "xmax" => transform[0].to_f.round(6) + xsize().to_f * transform[1].to_f.round(6)
    }
  end

  def file_modified

  end

end

class Metadata < GdalWrapper

  def to_iso19139
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.MD_Metadata('xmlns' => 'http://www.isotc211.org/2005/gmd', 
               'xmlns:gco' => 'http://www.isotc211.org/2005/gco',
               'xmlns:gts' => "http://www.isotc211.org/2005/gts",
               'xmlns:srv' => "http://www.isotc211.org/2005/srv",
               'xmlns:gml' => "http://www.opengis.net/gml"
              ) do
        xml.language do
          xml.LanguageCode(
            :codeList => 'http://www.loc.gov/standards/iso639-2/php/code_list.php',
            :codeListValue => 'eng',
            :codeSpace => 'ISO639-2'
          ) { xml.text "eng" }
        end
        xml.characterSet do
          xml.MD_CharacterSetCode(
            :codeList => "http://www.isotc211.org/2005/resources/Codelist/gmxCodelists.xml#MD_CharacterSetCode",
            :codeListValue => "utf8",
            :codeSpace => "ISOTC211/19115"
          ) { xml.text "utf8" }
        end

        xml.hierarchyLevel do
         xml.MD_ScopeCode(
            :codeList => "http://www.isotc211.org/2005/resources/Codelist/gmxCodelists.xml#MD_ScopeCode",
            :codeListValue => "dataset",
            :codeSpace => "ISOTC211/19115"
          ) { xml.text "dataset" }
        end

        xml.hierarchyLevelName do
          xml['gco'].CharacterString "dataset"
        end

        # TODO contact info
        xml.contact do
          xml.CI_ResponsibleParty do
            xml.organizationName do
              xml['gco'].CharacterString "Scholars' Lab, University of Virginia Libraries"
            end
            xml.contactInfo do
              xml.CI_Contact do
                xml.phone do
                  xml.CI_Telephone do
                    xml.voice do
                      xml['gco'].CharacterString "1-434-243-8800"
                    end
                  end
                end
                xml.address do
                  xml.deliveryPoint do
                    xml['gco'].CharacterString "Alderman Library"
                  end
                  xml.city do
                    xml['gco'].CharacterString "Charlottesville"
                  end
                  xml.postalCode do
                    xml['gco'].CharacterString "22902"
                  end
                  xml.country do
                     xml['gco'].CharacterString "USA"
                  end
                end
                xml.onlineResource do
                  xml.CI_OnlineResource do
                    xml.linkage do
                      xml.URL "http://scholarslab.org"
                    end
                    xml.name do
                      xml['gco'].CharacterString "Scholars' Lab Web site"
                    end
                    xml.description do
                      xml['gco'].CharacterString "Scholars' Lab Web site"
                    end
                  end
                end
              end
            end
            xml.role do
              xml.CI_RoleCode(
                :codeListValue => "pointOfContact",
                :codeList => "http://www.isotc211.org/2005/resources/codeList.xml#CI_RoleCode"
              )
            end
          end
        end

        xml.dateStamp do
          # TODO get file update time
          xml['gco'].Date Time.now.strftime("%FT%R")
        end

        xml.metadataStandardName do
          xml['gco'].CharacterString "ISO 19139 Geographic Information - Metadata - Implementation Specification"
        end

        xml.metadataStandardVersion do
          xml['gco'].CharacterString "2007"
        end

        xml.spatialRepresentationInfo do
          xml.MD_Georectified do
            xml.numberOfDimensions do
              xml['gco'].Integer 2
            end

            xml.axisDimensionProperties do
              xml.MD_Dimension do
                xml.dimensionName do
                  xml.MD_DimensionNameTypeCode(
                    :codeList => "http://www.isotc211.org/2005/resources/Codelist/gmxCodelists.xml#MD_DimensionNameTypeCode",
                    :codeListValue => "column",
                    :codeSpace => "ISOTC211/19115"
                  ) { xml.text "column" }
                end
                xml.dimensionSize do
                  # TODO get width
                  xml['gco'].Integer @gdalfile.RasterXSize
                end
              end
            end
          end
        end

      end
    end

    builder
  end

end




#Dir["*.tif"].each do |file|
#pp file
##GdalFile.new(file, 'r')
#end


file = Metadata.new('1937_16_44.tif')

pp file.get_extents['xmin']
#pp file.get_projection

puts file.to_iso19139.to_xml
#pp file.size


