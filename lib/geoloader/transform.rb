require 'nokogiri'

module Geoloader
  class Transform


    # Converts an ESRI ArcCatalog xml file to ISO 19139
    #
    # @param [String] input_file Input file
    # @param [String] output_file Output file
    def self.from_arcgis(input_file, output_file)
      doc = Nokogiri::XML(File.read(input_file))
      xsl = Nokogiri::XSLT(File.read('./iso19139.xsl'))
      File.open(output_file, 'w') { |f| f << xsl.transform(doc) }
    end
  end
end
