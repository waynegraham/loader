require 'spec_helper'

module Geoloader
  describe Geonetwork do

    before(:each) do
      @geonetwork_options = {
        :service_root => 'http://localhost:8080/geonetwork'
      }
    end

    describe "#new" do
      it "takes a file and sets service root" do
        geonetwork = Geoloader::Geonetwork.new(@geonetwork_options)
        geonetwork.should be_an_instance_of Geonetwork
      end
    end


  end
end
