require 'rubygems'
require 'nokogiri'
require 'rest_client'
require 'awesome_print'

module Geoloader
  # Provides client interface to GeoNetwork's REST API
  # @see http://geonetwork-opensource.org/manuals/2.8.0/eng/developer/xml_services XML Services documentation
  class Geonetwork
    # @see http://geonetwork-opensource.org/manuals/2.8.0/eng/developer/xml_services/services_site_info_forwarding.html#status Valid status descriptions
    GEONETWORK_STATUS_CODES = %w{unknown draft approved retired submitted rejected}

    # @see  http://geonetwork-opensource.org/manuals/2.8.0/eng/developer/xml_services/services_site_info_forwarding.html#xml-info Valid info tags
    GEONETWORK_INFO_CODES = %w{site users groups sources schemas categories operations regions status}

    # @param [Hash] options provides `:service_root` URL
    def initialize options = {}
      @service_root = options[:service_root] || GeoMDTK::Config.geonetwork.service_root
      ap({:service_root => @service_root})
    end

   
  end
end
