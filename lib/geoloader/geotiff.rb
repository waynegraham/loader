# coding: utf-8

module Geoloader
  class Geotiff

    def initialize(work_dir = '/tmp')
      @work_dir = work_dir
    end

    def remove_border(tif_path)
      command = "gdalwarp -srcnodata 0 -dstalpha "
      execute(tif_path, '_warped', command)
    end

    def add_header(tif_path)
      command = "gdal_translate -of GTiff -a_srs EPSG:4326 "
      execute(tif_path, '_translated', command)
    end

    def rename(tif_path)
      new_name = tif_path.gsub(/_warped_translated/,'')
      FileUtils.mv tif_path, "#{new_name}"
      new_name
    end

    def cleanup
      FileUtils.rm Dir.glob("#{@work_dir}/*.tif")
    end

    private

    def execute(tif_file, suffix, command)
      new_file = File.basename(tif_file, '.tif') + "#{suffix}.tif"
      command += "#{tif_file} #{@work_dir}/#{new_file}"
      system command
      "#{@work_dir}/#{new_file}"
    end

  end
end

