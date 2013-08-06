require 'spec_helper'

module Geoloader
  describe Gdal do

    describe "#new" do
      it "takes a file and sets the gdalfile variable" do
        gdal = Geoloader::Gdal.new('foo.tif')
        gdal.should be_an_instance_of Gdal
      end
    end


  end
end
