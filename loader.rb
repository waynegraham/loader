#! /usr/bin/env ruby

require 'pp'
require "gdal-ruby/gdal"
require "gdal-ruby/gdalconst"
require "gdal-ruby/osr"

require "nokogiri"

require 'rest_client'
require 'awesome_print'

require 'curb'

require 'rgeoserver'

require 'rspec'







$DEBUG = true

geoserver_options = {
  :service_root => 'http://localhost:8080/geoserver/rest',
  :service_user => 'admin',
  :service_password => 'geoserver'
}

file = "1937_16_44.tif"

loader = Geoloader::Geoserver.new(geoserver_options)
loader.workspace!('foo')

gdal = Geoloader::Geotiff.new

warped = gdal.remove_border(file)
ap warped

translated = gdal.add_header(warped)
ap translated

final_file = gdal.rename(translated)

ap loader.add_raster(final_file)
ap gdal.cleanup

#describe Geoloader::Geotiff do
  #it "should shell for gdalwarp" do
    #gdal = Geoloader::Geotiff.new
    #gdal.should_receive("system").with("gdalwarp")
    #gdal.remove_border(file)
  #end
#end
