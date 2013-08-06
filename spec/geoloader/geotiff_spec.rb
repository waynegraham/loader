require 'spec_helper'

module Geoloader
  describe Geotiff do

    describe "#new" do
      it "takes a file and sets working directory" do
        geotiff = Geoloader::Geotiff.new
        geotiff.should be_an_instance_of Geotiff
      end
    end


  end
end
