module Geoloader
  class Geoserver

    def initialize ( options = {} )
      @service_root = options[:service_root] || Geoloader::Config.server.service_root
      @service_user = options[:service_user] || Geoloader::Config.server.service_user
      @service_password = options[:service_password] || Geoloader::Config.server.service_password
    end

    def workspace
      @workspace
    end

    def workspace!(workspace)
      @workspace = workspace
    end

    def coverage!(coverage)
      @coverage = coverage
    end

    def coverage!(coverage)
      @workspace = workspace
      @coverage = coverage

      command = "curl -u #{@service_user}:#{@service_password} -v -XPOST -H \"Content-Type: application/xml\""
      command += " -d '<coverageStore><name>#{coverage}</name><workspace>#{@workspace}</workspace>"
      command += "<enabled>true</enabled></coverageStore>'"
      command += " #{@service_root}/workspaces/#{@workspace}/coveragestores"
      system(command)
    end

    def add_raster(file)

      base = File.basename(file, '.tif')
      url =  "#{@service_root}/workspaces/#{@workspace}/coveragestores/#{base}/file.geotiff"

      command = ""
      command += "curl -u #{@service_user}:#{@service_password} -v -XPUT -H \"Content-type: image/tiff\""
      command += " --data-binary @#{file}"
      command += " #{url}"
      system command
    end

  end
end

