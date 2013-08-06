require 'spec_helper'

module Geoloader
  describe Geoserver do

    before(:each) do
      @geoserver_config = {
        :service_root => 'http://localhost:8080/geoserver/rest',
        :service_user => 'admin',
        :service_password => 'geoserver'
      }
    end


    describe "#new" do
      it "takes a file and sets service root" do
        geoserver = Geoloader::Geoserver.new(@geoserver_config)
        geoserver.should be_an_instance_of Geoserver
      end
    end


  end
end
