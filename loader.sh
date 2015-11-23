#! /usr/bin/env bash

shopt -s nullglob

TIFFS="path/to/*.tif*"
WORK_DIR='/tmp'
GS_USER="geoserver_user"
GS_PASS="geoserver_password"
GS_SERVER="http://geoserver:8080/geoserver/rest"
GS_WORKSPACE="workspace"

LOG_FILE="./geoserver-process.log"

logit()
{
  echo "[${USER}][`date`] - ${*}" >> ${LOG_FILE}
}

warped_file()
{
  file=`basename "$1" .tif`
  suffix="_warped.tif"
  echo "$WORK_DIR/$file$suffix"
}

translated_file()
{
  file=`basename "$1" .tif`
  suffix=".tif"
  echo "$WORK_DIR/$file$suffix"
}

remove_border()
{
  warped=$(warped_file $1)
  gdalwarp -srcnodata 256 -dstalpha $1 $warped
  logit "Removed border of $warped"
}

remove_tiff()
{
  rm $1
}

replace_header()
{
  warped=$(warped_file $1)
  translated=$(translated_file $1)
  gdal_translate -of GTiff -a_srs EPSG:4326 $warped $translated
  logit "Added SRS header to $translated"

}

post_tif()
{
  file=`basename "$1" .tif`
  url=$GS_SERVER/workspaces/$GS_WORKSPACE/coveragestores/$file/file.geotiff
  eval curl -u $GS_USER:$GS_PASS -XPUT -H \"Content-type: image/tiff\" --data-binary @$WORK_DIR/$file.tif $url
  err=$?

  if [ $err -ne 0 ]
  then
    logit "Failed with error code $err"
    exit
  else
    logit "Successfully posted $file to $GS_SERVER"
  fi

  remove_tiff $1

}

clean_work_dir()
{
  rm -rf $WORK_DIR/*.tif
  logit "Cleaned up $WORK_DIR"
}


for t in $TIFFS
do
  echo "Processing $t..."
  remove_border $t
  replace_header $t
  post_tif $t

  #clean_work_dir
done
