require 'rubygems'
require 'nokogiri'
require 'rest_client'
require 'awesome_print'

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

