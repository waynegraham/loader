#! /usr/bin/env ruby

require 'pp'
require "gdal-ruby/gdal"
require "gdal-ruby/gdalconst"
require "gdal-ruby/osr"

require "nokogiri"

require 'rest_client'
require 'awesome_print'


module Geoloader
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
end

module Geoloader
  class Transform
    # Converts an ESRI ArcCatalog xml file to ISO 19139
    #
    # @param [String] input_file Input file
    # @param [String] output_file Output file
    def self.from_arcgis(input_file, output_file)
      system("saxon -xi:on -s:#{input_file} -xsl:iso19139.xsl > #{output_file}")
    end

  end
end

module Geoloader
  class Geonetwork
    GEONETWORK_STATUS_CODES = %w{unknown draft approved retired submitted rejected}

    # @see  http://geonetwork-opensource.org/manuals/2.8.0/eng/developer/xml_services/services_site_info_forwarding.html#xml-info Valid info tags
    GEONETWORK_INFO_CODES = %w{site groups schemas categories operations status}
    #GEONETWORK_INFO_CODES = %w{site users groups sources schemas categories operations regions status}

    # @param [Hash] options provides `:service_root` URL
    def initialize options = {}
      @service_root = options[:service_root] || Geoloader::Config.geonetwork.service_root
      ap({:service_root => @service_root}) if $DEBUG
    end

    # @see  http://geonetwork-opensource.org/manuals/2.8.0/eng/developer/xml_services/services_site_info_forwarding.html#site-information-xml-info Site Information: `xml.info`
    def site_info
      service("xml.info", { :type => 'site' }).xpath('/info/site')
    end

    # Fetches metrics
    def metrics
      service("../../monitor/metrics", { :pretty => 'true' })
    end

    # @yield the UUID (fileIdentifier) for all metadata in the GeoNetwork database
    def each
      xml = service("xml.search", { :remote => 'off', :hitsPerPage => -1 })
      xml.xpath('//uuid/text()').each do |uuid|
        yield uuid.to_s.strip
      end
    end

    # @see http://geonetwork-opensource.org/manuals/2.8.0/eng/developer/xml_services/metadata_xml_search_retrieve.html Metadata retrieval: `xml.metadata.get`
    # @see http://geonetwork-opensource.org/manuals/2.8.0/eng/developer/xml_services/metadata_xml_status.html Metadata status: `xml.metadata.status.get`
    #
    # @param  [String] uuid the UUID (fileIdentifier) in the GeoNetwork database
    # @param  [Boolean] include_status 
    # @return [Struct] with the following fields:
    #    * `:content` as the XML metadata
    #    * `:status` as the status value, 
    def fetch(uuid, include_status = false)
      status = nil
      if include_status
        xml = service('xml.metadata.status.get', { :uuid => uuid })
        xml.xpath('/response/record/statusid') do |id|
          status = GEONETWORK_STATUS_CODES[id.to_i]
        end
      end
      doc = service('xml.metadata.get', { :uuid => uuid })
      if doc.xpath('//geonet:info/schema[text()="iso19139"]').empty?
        raise ArgumentError, "#{uuid} not in ISO 19139 format"
      end

      doc.xpath('/gmd:MD_Metadata/geonet:info').each { |x| x.remove }
      Struct.new(:content, :status).new(doc, status)
    end

    # @see http://geonetwork-opensource.org/manuals/2.8.0/eng/developer/xml_services/services_mef.html#mef-services  MEF Service
    # @see http://geonetwork-opensource.org/manuals/2.8.0/eng/developer/xml_services/csw_services.html CSW service
    # @param [String] uuid
    # @param [String] dir directory into which method will save export file(s)
    # @param [Symbol] format -- Either `:mef` or `:csw`
    def export(uuid, dir = ".", format = :mef)
      case format
      when :mef then
        export_mef(uuid, dir)
      when :csw then
        export_csw(uuid, dir)
      else
        raise ArgumentError, "Unsupported export format #{format}"        
      end
    end

    # @see  http://geonetwork-opensource.org/manuals/2.8.0/eng/developer/xml_services/system_configuration.html#system-configuration 
    #   System Configuration
    # @param types [Array] see {GeoMDTK::GeoNetwork::GEONETWORK_INFO_CODES}
    def info(types = GEONETWORK_INFO_CODES)
      r = {}
      types.each do |t|
        if GEONETWORK_INFO_CODES.include?(t)
          r[t] = service("xml.info", { :type => t })
        else
          raise ArgumentError, "#{t} is not a supported type for xml.info REST service"
        end
      end
      r
    end

    private

    def service(name, params, format = :default)
      if format == :default and name.start_with?('xml.')
        format = :xml
      end
      uri = "#{@service_root}/srv/eng/#{name}"

      ap({ :uri => uri, :params => params, :format => format }) if $DEBUG

      r = RestClient.get uri, :params => params
      if format == :xml
        Nokogiri::XML(r)
      elsif format == :default
        r
      else
        raise ArgumentError, "service requires format valid parameter: #{format}"
      end
    end

    def export_mef(uuid, dir = ".")
      res = service("mef.export", { 
        :uuid => uuid, 
        :version => 'true',
        :relation => 'false'
      })
      fn = "#{dir}/#{uuid}.mef"
      File.open(fn, 'wb') {|f| f.puts(res.body) }
      raise ArgumentError, "MEF #{fn} is missing" unless File.exist? fn
      fn
    end

    def export_csw(uuid, dir = ".")
      res = service("csw", { 
        :request => 'GetRecordById',
        :service => 'CSW',
        :version => '2.0.2',
        :elementSetName => 'full',
        :id => uuid 
      })
      fn = "#{dir}/#{uuid}.csw"
      File.open(fn, 'wb') {|f| f.write(res.body) }
      raise ArgumentError, "CSW #{fn} is missing" unless File.exist? fn
      fn
    end


  end
end

module Geoloader
  class Geoserver

    def initialize ( options = {} )
      @service_root = options[:service_root] || Geoloader::Config.server.service_root
      @service_user = options[:service_user] || Geoloader::Config.server.service_user
      @service_password = options[:service_password] || Geoloader::Config.server.service_password
    end

    def coverage!(workspace, coverage)
      command = "curl -u #{@service_user}:#{@service_password} -v -XPOST -H \"Content-Type: application/xml\""
      command += " -d '<coverageStore><name>#{coverage}</name><workspace>#{workspace}</workspace>"
      command += "<enabled>true</enabled></coverageStore>'"
      command += " #{@service_root}/workspaces/#{workspace}/coveragestores"
      system(command)
    end

    def add_raster(workspace,  file)
      base = File.basename(file, '.tif')
      command = "curl -u #{@service_user}:#{@service_password} -v -XPUT -H \"Content-type: image/tiff\""
      command += " --data-binary @#{file}"
      command +=  " #{@service_root}/workspaces/#{workspace}/coveragestores/#{base}/file.geotiff"
    end

  end
end

#Dir["*.tif"].each do |file|
#pp file
##GdalFile.new(file, 'r')
#end

$DEBUG = true

base = "1937_16_44.tif"
#geotif = Geoloader::GdalWrapper.new("#{base}")
#metadata = "#{base}.xml"
#geonetwork_xml = "#{base}_geonetwork.xml"

#puts geotif.get_extents
#



#ap loader.coverage!('Albemarle', 'AlbemarleAerials')
#ap loader.add_raster('AlbemarleAerials',  base)
##ap loader.add_raster('Albemarle', 'AlbemarleAerials', base)

#e = "curl -u slabadmin:GIS4slab! -v -XPUT -H \"Content-type: image/tiff\" --data-binary @1937_16_44.tif http://libsvr35.lib.virginia.edu:8080/geoserver/rest/workspaces/AlbemarleAerials/coveragestores/1937_16_44/file.geotiff"

#ap e
