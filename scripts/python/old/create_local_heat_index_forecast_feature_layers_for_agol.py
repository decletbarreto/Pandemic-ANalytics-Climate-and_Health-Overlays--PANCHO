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
from datetime import datetime, timedelta

try:
	start_time = time.time()
	print("Started on " + time.ctime(start_time) + ".")
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
	
	#Get the day 3 Heat Index forecast for today, i.e., the day 3 Heat Index forecast issued three days ago
	date_three_days_ago = datetime.today() - timedelta(days=3)
	date_three_days_ago_formatted = str(date_three_days_ago.strftime("%Y%m%d"))
	max_hi_forecast_url  = "https://ftp.wpc.ncep.noaa.gov/shapefiles/heatindex/" + date_three_days_ago_formatted + "/maxhi_" + date_three_days_ago_formatted + "f072.tar" 
	
	counties_shp         = os.path.join(input_files_dir,"conus_counties_simplified.shp")
	maxhi_current_valid_poly = "maxhi_current_valid_poly" 

	#input files
	#maxhi_f072_latest.tar	
	max_hi_forecast_tar = os.path.join(max_hi_forecast_dir, "maxhi_f072_latest.tar")
		
	#layers
	max_hi_forecast_lyr  = "max_hi_forecast_lyr"

	#output files
	#interpolation_shp  = os.path.join(tmp_dir, "conus_max_temp_forecast_first_day_integer.tif")
	
	#hi_forecast_symbology = os.path.join(input_files_dir, "conus_max_temp_forecast_symbology.lyr") 
	
	#cleanup files before starting
	files_list = [max_hi_forecast_tar]

	print("cleaning up before starting...") 
	for a_file in files_list: 
		if os.path.exists(a_file):
			try:
				os.remove(a_file)
			except:
				print("Exception raised: cannot delete " + a_file + ". Exiting.")
		else:
			print("Does not exist: " + a_file + ".")

	print("cleaning up " + tmp_dir + "...")
	for a_file in os.listdir(tmp_dir):
		if os.path.exists(os.path.join(tmp_dir, a_file)):
			try:
				os.remove(os.path.join(tmp_dir,a_file))
			except:
				print("Exception raised: cannot delete " + a_file + ". Exiting.")
		else:
			print("Does not exist: " + a_file + ".")	
	
	#download latest hi forecast tar
	try:
		print("Downloading " + max_hi_forecast_url + "..." )
		urllib.request.urlretrieve(max_hi_forecast_url, max_hi_forecast_tar)
		print("Downloaded to " + max_hi_forecast_tar)
	
	except:
		print("Could not download " + max_hi_forecast_url + ".")	
		sys.exit()
	
	#untar
	try:
		print("Extracting tar file...")
		tar = tarfile.open(name=max_hi_forecast_tar, mode='r')
		#changing cwd to tmp dir for tar extract
		os.chdir(tmp_dir)
		tar.extractall()
		tar.close()
		print("Extracted to " + max_hi_forecast_tar)
	except:
		print("Could not untar " + max_hi_forecast_tar + ".")
		sys.exit()

	match = fnmatch.filter(os.listdir(tmp_dir), '*.shp')
	max_hi_forecast_shp = os.path.join(tmp_dir, match[0])
	max_hi_forecast_interpolated_tif = os.path.join(tmp_dir, os.path.splitext(match[0])[0] + ".tif")
	max_hi_forecast_interpolated_tif_valid = os.path.join(tmp_dir, "maxhi_current_valid.tif")
	
	max_hi_forecast_interpolated_valid_poly = os.path.join(tmp_dir, maxhi_current_valid_poly)
	max_hi_forecast_interpolated_valid_poly_tmp = os.path.join(tmp_dir, maxhi_current_valid_poly + "_tmp")
	
	#interpolate
	print("Kriging to " + max_hi_forecast_interpolated_tif)
	arcpy.ga.EmpiricalBayesianKriging(max_hi_forecast_shp, "VALUE", "lyr", max_hi_forecast_interpolated_tif, 0.10488, "NONE", 100, 1, 100,\
						"NBRTYPE=StandardCircular RADIUS=13.2608929280799 ANGLE=0 NBR_MAX=15 NBR_MIN=10 SECTOR_TYPE=ONE_SECTOR",\
						"PREDICTION", 0.5, "EXCEED", None, "POWER")
	print("done.")
	sel = arcpy.management.SelectLayerByLocation(counties_shp, "CONTAINS", max_hi_forecast_shp, None, "NEW_SELECTION", "NOT_INVERT")
	
	print("Extracting by mask from " + max_hi_forecast_interpolated_tif + "...")
	out_raster = arcpy.sa.ExtractByMask(max_hi_forecast_interpolated_tif,sel)
	print ("changing raster data type to integer in " + max_hi_forecast_interpolated_tif + "...")
	out_raster_int = arcpy.ia.Int(out_raster)
	
	#sys.exit()
	print("saving raster to " + max_hi_forecast_interpolated_tif_valid + "..." )
	out_raster_int.save(max_hi_forecast_interpolated_tif_valid)
	
	print ("Converting to polygon: " + max_hi_forecast_interpolated_valid_poly + "..." )
	arcpy.conversion.RasterToPolygon(in_raster = max_hi_forecast_interpolated_tif_valid,\
						out_polygon_features = max_hi_forecast_interpolated_valid_poly_tmp,\
						simplify = "NO_SIMPLIFY",\
						raster_field = "Value",\
					create_multipart_features = "SINGLE_OUTER_PART")
	
	
	#Selecting Heat Index values above threshold
	threshold = 100
	print("Selecting Heat Index values above threshold of " + str(threshold))
	qry = "gridcode >= " + str(threshold)
	heat_index_over_threshold_lyr = arcpy.SelectLayerByAttribute_management(max_hi_forecast_interpolated_valid_poly_tmp + ".shp", "NEW_SELECTION", qry)
	
	print("Copying to " + max_hi_forecast_interpolated_valid_poly)
	arcpy.management.CopyFeatures(heat_index_over_threshold_lyr, max_hi_forecast_interpolated_valid_poly, '', None, None, None)
	
	print("zipping shapefiles...")
	time.sleep(sleep_interval)
	#all extensions of shapefile
	shp_extensions = ["cpg", "dbf", "prj", "sbn", "sbx", "shp", "xml", "shx"]
	#use list comprehension to generate the filenames in the shapefile to zip up
	files =  [maxhi_current_valid_poly + "." + x for x in shp_extensions]
	
	poly_zip_filename  = os.path.join(output_files_dir, maxhi_current_valid_poly) + ".zip"
	
	poly_zip = zipfile.ZipFile(poly_zip_filename, 'w')
	for a_file in files:
		try:
			poly_zip.write(filename = os.path.join(tmp_dir, a_file),\
									arcname = a_file,\
									compress_type=zipfile.ZIP_DEFLATED)
			print("Zipped to " + poly_zip_filename)
		except:
			print("can't zip " + a_file)
			continue
	poly_zip.close()

except Exception as inst:
	print(type(inst))    # the exception instance
	print(inst.args)     # arguments stored in .args
	print(inst)          # __str__ allows args to be printed directly,
	e = sys.exc_info()[1]
	print(e.args[0])
finally:
	print("Done.")
	print("--- %s seconds ---" % round((time.time() - start_time)))