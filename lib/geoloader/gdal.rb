require "gdal-ruby/gdal"
require "gdal-ruby/gdalconst"
require "gdal-ruby/osr"

module Geoloader
  class Gdal

    attr_accessor :gdal_file

    def initialize(file)
      @gdalfile = Gdal::Gdal.open(file)
    end

    #returns basic size info as a hash
    def size
      {
        "x" => @gdalfile.RasterXSize,
        "y" => @gdalfile.RasterYSize,
        "bands" => @bands.length,
        "data_type" => @bands[0].data_type()
      }
    end

    #x dimention size
    def xsize
      @gdalfile.RasterXSize
    end

    #y dim size
    def ysize
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
    def get_geo_transform
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
