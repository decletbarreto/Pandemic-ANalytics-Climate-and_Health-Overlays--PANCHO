# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
#create feature layers for AGOL
print("Starting process: Create Heat Index Feature Layer for UCS AGOL.") 

import arcpy
import os
import time
from arcpy import env
from arcpy.sa import *
import arcpy.ia
import zipfile
import fnmatch
import sys
import urllib.request
import tarfile
#from datetime import timedelta, date
import pdb
import logging
import datetime
import arcgis
from arcgis.gis import GIS
root_dir  = "D:/Users/climate_dashboard/Documents/climate_dashboard"

try:
    #setup the logger
    today = datetime.date.today().strftime('%Y-%m-%d')
    log_filename =  root_dir + "/log/process_create_local_heat_index_for_agol_" + today + ".log"

    logging.basicConfig(filename=log_filename, level=logging.INFO, format='%(asctime)s %(message)s')
    start_time = time.time()
    msg = "Starting process: Create local Heat Index for AGOL."
    print(msg)
    logging.info(msg)
    msg = "Started on " + time.ctime(start_time) + "."
    print(msg)
    logging.info(msg)
    msg = "ArcGIS Python API version " + arcgis.__version__
    print(msg)
    logging.info(msg)

    sleep_interval =.33
    arcpy.env.overwriteOutput = True
    # Local variables:

    base_dir         = r"D:\Users\climate_dashboard\Documents\climate_dashboard"

    data_dir         = "data"
    tmp_dir          = os.path.join(base_dir, data_dir, "tmp", "HI_forecast")
    output_files_dir = os.path.join(base_dir, data_dir, "output_files")
    input_files_dir  = os.path.join(base_dir, data_dir, "input_files")
    #temperature_forecast_shp_dir = "temperature_forecast_shp"
    env.workspace    = tmp_dir
    #zip_files_dir    = os.path.join(output_files_dir, "HI_forecast")
    max_hi_forecast_dir  = os.path.join(input_files_dir, "HI_forecast")

    #Get the day 3 Heat Index forecast for tomorrow, i.e., the day 3 through 7 Heat Index forecast issued two days ago
    date_two_days_ago = datetime.date.today() - datetime.timedelta(days=2)
    print("Today is " + str(datetime.date.today()))
    date_two_days_ago_formatted = str(date_two_days_ago.strftime("%Y%m%d"))
    max_hi_forecast_url_072  = "https://ftp.wpc.ncep.noaa.gov/shapefiles/heatindex/" + date_two_days_ago_formatted + "/maxhi_" + date_two_days_ago_formatted + "f072.tar" 
    max_hi_forecast_url_096  = "https://ftp.wpc.ncep.noaa.gov/shapefiles/heatindex/" + date_two_days_ago_formatted + "/maxhi_" + date_two_days_ago_formatted + "f096.tar" 
    max_hi_forecast_url_120  = "https://ftp.wpc.ncep.noaa.gov/shapefiles/heatindex/" + date_two_days_ago_formatted + "/maxhi_" + date_two_days_ago_formatted + "f120.tar" 
    max_hi_forecast_url_144  = "https://ftp.wpc.ncep.noaa.gov/shapefiles/heatindex/" + date_two_days_ago_formatted + "/maxhi_" + date_two_days_ago_formatted + "f144.tar" 
    max_hi_forecast_url_168  = "https://ftp.wpc.ncep.noaa.gov/shapefiles/heatindex/" + date_two_days_ago_formatted + "/maxhi_" + date_two_days_ago_formatted + "f168.tar"

    max_hi_url_list = [max_hi_forecast_url_072,max_hi_forecast_url_096,max_hi_forecast_url_120,max_hi_forecast_url_144,max_hi_forecast_url_168]

    counties_shp         = os.path.join(input_files_dir,"conus_counties_simplified.shp")

    #merged heat index shapefiles
    maxhi_forecast_merged =  os.path.join(tmp_dir, "maxhi_forecast_merged")

    #input files
    #maxhi_f072_latest.tar	
    max_hi_forecast_072_tar = os.path.join(max_hi_forecast_dir, "maxhi_f072_latest.tar")
    max_hi_forecast_096_tar = os.path.join(max_hi_forecast_dir, "maxhi_f096_latest.tar")
    max_hi_forecast_120_tar = os.path.join(max_hi_forecast_dir, "maxhi_f120_latest.tar")
    max_hi_forecast_144_tar = os.path.join(max_hi_forecast_dir, "maxhi_f144_latest.tar")
    max_hi_forecast_168_tar = os.path.join(max_hi_forecast_dir, "maxhi_f168_latest.tar")
		
    #layers
    max_hi_forecast_072_lyr  = "max_hi_forecast_072_lyr"
    max_hi_forecast_096_lyr  = "max_hi_forecast_096_lyr"
    max_hi_forecast_120_lyr  = "max_hi_forecast_120_lyr"
    max_hi_forecast_144_lyr  = "max_hi_forecast_144_lyr"
    max_hi_forecast_168_lyr  = "max_hi_forecast_168_lyr"

    #output files
    maxhi_counties_intersect = os.path.join(tmp_dir, "maxhi_counties_intersect.shp")
    maxhi_counties_summary   = os.path.join(tmp_dir, "maxhi_counties_summary.dbf")
    maxhi_counties_join_tmp  = os.path.join(tmp_dir, "maxhi_counties_join_tmp")
    maxhi_counties_join_final= os.path.join(tmp_dir, "maxhi_counties_join_final")

    #cleanup files before starting
    files_list = [max_hi_forecast_072_tar,max_hi_forecast_096_tar,max_hi_forecast_120_tar,max_hi_forecast_144_tar,max_hi_forecast_168_tar]

    msg = "Cleaning up before starting..."
    print(msg)
    logging.info(msg)
    for a_file in files_list: 
        if os.path.exists(a_file):
            try:
                os.remove(a_file)
            except:
                msg = "\tException raised: cannot delete " + a_file + ". Exiting."
                print(msg)
                logging.info(msg)                
        else:
            msg = "\tDoes not exist: " + a_file + "."
            print(msg)
            logging.info(msg) 

    msg = "Cleaning up " + tmp_dir + "..."
    print(msg)
    logging.info(msg)
    for a_file in os.listdir(tmp_dir):
        if os.path.exists(os.path.join(tmp_dir, a_file)):
            try:
                os.remove(os.path.join(tmp_dir,a_file))
            except:
                msg = "\tException raised: cannot delete " + a_file + ". Moving on."
                print(msg)
                logging.info(msg)
        else:
            msg = "\tDoes not exist: " + a_file + "."
            pring(msg)
            logging.info(msg)
	
    #download hi forecast tars
    msg = "Downloading Heat Index forecast tar files..."
    print(msg)
    logging.info(msg)
    try:
        for url, file in zip(max_hi_url_list, files_list):            

            msg = "\tDownloading " + url + "..."
            print(msg)
            logging.info(msg)  
            urllib.request.urlretrieve(url, file)
            msg = "\tDownloaded to " + file
            print(msg)
            logging.info(msg)
	
    except:
        msg = "\tCould not download " + url + "."
        print(msg)
        logging.info(msg)
        sys.exit()
            
    #untar
    msg = "Untaring Heat Index forecast tar files..."
    print(msg)
    logging.info(msg)
                   
    try:
        for file in files_list:
            msg = "\tExtracting tar file..."
            print(msg)
            logging.info(msg)
            tar = tarfile.open(name=file, mode='r')
            #changing cwd to tmp dir for tar extract
            os.chdir(tmp_dir)
            tar.extractall()
            tar.close()
                
            msg ="\tExtracted " + file + " to " + tmp_dir
            print(msg)
            logging.info(msg)
                   
    except:
                   
        msg = "\tCould not untar " + file + "."
        print(msg)
        logging.info(msg)
        sys.exit()

    #match = fnmatch.filter(os.listdir(tmp_dir), '*.shp')
    #get the names of the untar'd shapefiles
    shp_list = fnmatch.filter(os.listdir(tmp_dir), '*.shp')
    interpolated_shp_list = []

    msg = "Processing Heat Index forecast point shapefiles..."
    print(msg)
    logging.info(msg)
    for shp in shp_list:

        #create full path
        max_hi_forecast_shp = os.path.join(tmp_dir, shp)
        max_hi_forecast_interpolated_tif = os.path.join(tmp_dir, os.path.splitext(shp)[0] + ".tif")
        max_hi_forecast_interpolated_tif_valid = os.path.join(tmp_dir, os.path.splitext(shp)[0] + "_valid.tif")
            
        max_hi_forecast_interpolated_valid_poly = os.path.join(tmp_dir, os.path.splitext(shp)[0] + "_valid_poly")
        max_hi_forecast_interpolated_valid_poly_tmp = os.path.join(tmp_dir, os.path.splitext(shp)[0] + "_valid_poly_tmp")
        #pdb.set_trace()
        
        #interpolate
        msg = "\tKriging to " + max_hi_forecast_interpolated_tif
        print(msg)
        logging.info(msg)
        arcpy.ga.EmpiricalBayesianKriging(max_hi_forecast_shp, "VALUE", "lyr", max_hi_forecast_interpolated_tif, 0.10488, "NONE", 100, 1, 100,\
                                        "NBRTYPE=StandardCircular RADIUS=13.2608929280799 ANGLE=0 NBR_MAX=15 NBR_MIN=10 SECTOR_TYPE=ONE_SECTOR",\
                                        "PREDICTION", 0.5, "EXCEED", None, "POWER")
        msg = "\tDone."
        print(msg)
        logging.info(msg)
        sel = arcpy.management.SelectLayerByLocation(counties_shp, "CONTAINS", max_hi_forecast_shp, None, "NEW_SELECTION", "NOT_INVERT")
            
        msg = "\tExtracting by mask from " + max_hi_forecast_interpolated_tif + "..."
        print(msg)
        logging.info(msg)
                   
        out_raster = arcpy.sa.ExtractByMask(max_hi_forecast_interpolated_tif,sel)
        msg = "\tChanging raster data type to integer in " + max_hi_forecast_interpolated_tif + "..."
        print(msg)
        logging.info(msg)
        out_raster_int = arcpy.ia.Int(out_raster)
            
        #sys.exit()
        msg = "\tSaving raster to " + max_hi_forecast_interpolated_tif_valid + "..."
        print(msg)
        logging.info(msg)
        out_raster_int.save(max_hi_forecast_interpolated_tif_valid)
            
        msg = "\tConverting to polygon: " + max_hi_forecast_interpolated_valid_poly + "..."
        print(msg)
        logging.info(msg)
        arcpy.conversion.RasterToPolygon(in_raster = max_hi_forecast_interpolated_tif_valid,\
                                         out_polygon_features = max_hi_forecast_interpolated_valid_poly_tmp,\
                                        simplify = "NO_SIMPLIFY",\
                                        raster_field = "Value",\
                                        create_multipart_features = "SINGLE_OUTER_PART")

        #add shapefiles to list for merge later
        interpolated_shp_list.append(max_hi_forecast_interpolated_valid_poly_tmp + ".shp")

    # merge 5 HI polys
    msg = "Merging polygon shapefiles"
    print(msg)
    logging.info(msg)
    arcpy.Merge_management(interpolated_shp_list, maxhi_forecast_merged, "", "ADD_SOURCE_INFO")
    
    #intersect with counties
    msg = "Intersecting with counties"
    print(msg)
    logging.info(msg)
    arcpy.Intersect_analysis(in_features = [maxhi_forecast_merged + ".shp", counties_shp], out_feature_class = maxhi_counties_intersect,join_attributes = "ALL",output_type = "INPUT")

    #summarize by GEOID, FUN=max gridcode
    msg = "Summarizing max gridcode in counties"
    print(msg)
    logging.info(msg)
    arcpy.analysis.Statistics(maxhi_counties_intersect, maxhi_counties_summary, "gridcode MAX", "GEOID_dbl")
    #pdb.set_trace()
    #join to counties as max HI
    #first make a copy of counties fc
    msg = "Making a copy of counties feature class"
    print(msg)
    logging.info(msg)
    arcpy.CopyFeatures_management(in_features = counties_shp, out_feature_class = maxhi_counties_join_tmp)
    #now join to temporary feature class
    msg = "Joining max gridcode table to temporary feature class"
    print(msg)
    logging.info(msg)
    arcpy.JoinField_management(in_data = maxhi_counties_join_tmp + ".shp", in_field = "GEOID_dbl" ,join_table = maxhi_counties_summary, join_field = "GEOID_dbl", fields =["MAX_gridco"]) 
                                                        
    #Selecting Heat Index values above threshold
    threshold = 100
    msg = "Selecting Heat Index values above threshold of " + str(threshold)
    print(msg)
    logging.info(msg)
    qry = "MAX_gridco >= " + str(threshold)
    heat_index_over_threshold_lyr = arcpy.SelectLayerByAttribute_management(maxhi_counties_join_tmp + ".shp", "NEW_SELECTION", qry)

    msg = "Copying to " + max_hi_forecast_interpolated_valid_poly
    print(msg)
    logging.info(msg)    
    arcpy.management.CopyFeatures(heat_index_over_threshold_lyr, maxhi_counties_join_final, '', None, None, None)

    msg = "zipping shapefiles..."
    print(msg)
    logging.info(msg)
                   
    time.sleep(sleep_interval)
    #all extensions of shapefile
    shp_extensions = ["cpg", "dbf", "prj", "sbn", "sbx", "shp", "xml", "shx"]
    #use list comprehension to generate the filenames in the shapefile to zip up
    files =  [maxhi_counties_join_final + "." + x for x in shp_extensions]
    #pdb.set_trace()	
    poly_zip_filename  = os.path.join(output_files_dir, maxhi_counties_join_final) + ".zip"
	
    poly_zip = zipfile.ZipFile(poly_zip_filename, 'w')
    for a_file in files:
        try:
            poly_zip.write(filename = os.path.join(tmp_dir, a_file), arcname = a_file, compress_type=zipfile.ZIP_DEFLATED)
            msg = "Zipped to " + poly_zip_filename
            print(msg)
            logging.info(msg)
        except:
            msg = "can't zip " + a_file
            print(msg)
            logging.info(msg)
            continue
    poly_zip.close()

except Exception as inst:
    print(type(inst))    # the exception instance
    print(inst.args)     # arguments stored in .args
    print(inst)          # __str__ allows args to be printed directly,
    e = sys.exc_info()[1]
    msg = e.args[0]
    print(msg)
    logging.info(msg)
                   
finally:
    msg = "Done."
    print(msg)
    logging.info(msg)
    msg = "--- %s seconds ---" % round((time.time() - start_time))
    print(msg)
    logging.info(msg)
