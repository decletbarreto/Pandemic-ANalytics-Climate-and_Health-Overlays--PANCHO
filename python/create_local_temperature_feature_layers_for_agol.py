# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
#create feature layers for AGOL
print("Starting process: Create Feature Layers for UCS AGOL.") 

import arcpy
import os
import time
from arcpy import env
from arcpy.sa import *
import arcpy.ia
import zipfile
import fnmatch
import sys

try:
	start_time = time.time()
	print("Started on " + time.ctime(start_time) + ".")
	sleep_interval =.33
	arcpy.env.overwriteOutput = True
	# Local variables:
	#[from to newvalue]
	remap_values = RemapRange([[-30, 29, 20], [30, 39, 30], [40, 49, 40], [50, 59, 50], [60, 69, 60], [70, 79, 70], [80, 89, 80], [90, 99, 90], [101, 104, 100], [105, 120, 105]])


	base_dir         = r"D:\Users\climate_dashboard\Documents\climate_dashboard"

	data_dir         = "data"
	tmp_dir          = os.path.join(base_dir, data_dir, "raster_tmp")
	output_files_dir = os.path.join(base_dir, data_dir, "output_files")
	input_files_dir  = os.path.join(base_dir, data_dir, "input_files")
	temperature_forecast_shp_dir = "temperature_forecast_shp"
	env.workspace    = tmp_dir
	zip_files_dir    = os.path.join(output_files_dir, temperature_forecast_shp_dir)

	conus_covid19_cases_counties_shp  = r"D:\Users\climate_dashboard\Documents\climate_dashboard\data\output_files\covid_and_temperature\conus_covid19_cases_counties.shp"
	conus_covid19_cases_counties_shp2 = r"D:\Users\climate_dashboard\Documents\climate_dashboard\data\output_files\covid_and_temperature\conus_covid19_cases_counties2.shp"

	#input files
	conus_max_temp_forecast_first_day_tif  = os.path.join(output_files_dir, "conus_max_temp_forecast_first_day.tif")
	conus_max_temp_forecast_second_day_tif = os.path.join(output_files_dir, "conus_max_temp_forecast_second_day.tif")
	conus_max_temp_forecast_third_day_tif  = os.path.join(output_files_dir, "conus_max_temp_forecast_third_day.tif")
	conus_max_temp_forecast_seven_day_tif  = os.path.join(output_files_dir, "conus_max_temp_forecast_seven_day.tif")
	
	#layers
	conus_max_temp_forecast_first_day_lyr  = "conus_max_temp_forecast_first_day_lyr"
	conus_max_temp_forecast_second_day_lyr = "conus_max_temp_forecast_second_day_lyr"
	conus_max_temp_forecast_third_day_lyr  = "conus_max_temp_forecast_third_day_lyr"
	conus_max_temp_forecast_seven_day_lyr  = "conus_max_temp_forecast_seven_day_lyr"

	#output files
	conus_max_temp_forecast_first_day_int_tif  = os.path.join(tmp_dir, "conus_max_temp_forecast_first_day_integer.tif")
	conus_max_temp_forecast_second_day_int_tif = os.path.join(tmp_dir, "conus_max_temp_forecast_second_day_integer.tif")
	conus_max_temp_forecast_third_day_int_tif  = os.path.join(tmp_dir, "conus_max_temp_forecast_third_day_integer.tif")
	conus_max_temp_forecast_seven_day_int_tif  = os.path.join(tmp_dir, "conus_max_temp_forecast_seven_day_integer.tif")

	conus_max_temp_forecast_first_day_reclass_tif  = os.path.join(tmp_dir, "conus_max_temp_forecast_first_day_reclass.tif")
	conus_max_temp_forecast_second_day_reclass_tif = os.path.join(tmp_dir, "conus_max_temp_forecast_second_day_reclass.tif")
	conus_max_temp_forecast_third_day_reclass_tif  = os.path.join(tmp_dir, "conus_max_temp_forecast_third_day_reclass.tif")
	conus_max_temp_forecast_seven_day_reclass_tif  = os.path.join(tmp_dir, "conus_max_temp_forecast_seven_day_reclass.tif")

	n1 = "conus_max_temp_forecast_first_day"
	n2 = "conus_max_temp_forecast_second_day"
	n3 = "conus_max_temp_forecast_third_day"
	n4 = "conus_max_temp_forecast_seven_day.shp"

	conus_max_temp_forecast_first_day_poly   = os.path.join(output_files_dir, temperature_forecast_shp_dir, n1)
	conus_max_temp_forecast_second_day_poly  = os.path.join(output_files_dir, temperature_forecast_shp_dir, n2)
	conus_max_temp_forecast_third_day_poly   = os.path.join(output_files_dir, temperature_forecast_shp_dir, n3)
	conus_max_temp_forecast_seven_day_poly   = os.path.join(output_files_dir, temperature_forecast_shp_dir, n4)

	conus_max_temp_forecast_first_day_poly_zip_filename  = os.path.join(output_files_dir, temperature_forecast_shp_dir, n1) + ".zip"
	conus_max_temp_forecast_second_day_poly_zip_filename = os.path.join(output_files_dir, temperature_forecast_shp_dir, n2) + ".zip"
	conus_max_temp_forecast_third_day_poly_zip_filename  = os.path.join(output_files_dir, temperature_forecast_shp_dir, n3) + ".zip"
	conus_max_temp_forecast_seven_day_poly_zip_filename  = os.path.join(output_files_dir, temperature_forecast_shp_dir, n4) + ".zip"

	max_temp_symbology = os.path.join(input_files_dir, "conus_max_temp_forecast_symbology.lyr") 
	conus_max_temp_forecast_seven_day_shp = "D:\\Users\\climate_dashboard\\Documents\\climate_dashboard\\data\\output_files\\temperature_forecast_shp\\conus_max_temp_forecast_seven_day.shp"
	conus_max_temp_forecast_seven_day_stats_in_counties = os.path.join(output_files_dir, temperature_forecast_shp_dir, "conus_max_temp_forecast_seven_day.dbf")

	#cleanup files before starting
	files_list = [conus_max_temp_forecast_first_day_int_tif,\
			conus_max_temp_forecast_second_day_int_tif,\
			conus_max_temp_forecast_third_day_int_tif,\
			conus_max_temp_forecast_seven_day_int_tif,\
			conus_max_temp_forecast_first_day_reclass_tif,\
			conus_max_temp_forecast_second_day_reclass_tif,\
			conus_max_temp_forecast_third_day_reclass_tif,\
			conus_max_temp_forecast_seven_day_reclass_tif,\
			conus_max_temp_forecast_first_day_poly,\
			conus_max_temp_forecast_second_day_poly,\
			conus_max_temp_forecast_third_day_poly,\
			conus_max_temp_forecast_seven_day_poly,\
			conus_max_temp_forecast_first_day_poly_zip_filename,\
			conus_max_temp_forecast_second_day_poly_zip_filename,\
			conus_max_temp_forecast_third_day_poly_zip_filename,\
			conus_max_temp_forecast_seven_day_poly_zip_filename]

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
	
	time.sleep(sleep_interval)

	print("Converting C to F in " + conus_max_temp_forecast_first_day_tif) 
	raster_first_day = arcpy.ia.UnitConversion(conus_max_temp_forecast_first_day_tif, from_unit = 'Celsius', to_unit = 'Fahrenheit' )
	print ("changing raster data type to integer in " + conus_max_temp_forecast_first_day_tif + "...")
	raster_first_day = arcpy.ia.Int(raster_first_day)
	
	print("Converting C to F in " + conus_max_temp_forecast_second_day_tif) 
	raster_second_day = arcpy.ia.UnitConversion(conus_max_temp_forecast_second_day_tif, from_unit = 'Celsius', to_unit = 'Fahrenheit' )
	print ("changing raster data type to integer in " + conus_max_temp_forecast_second_day_tif + "...")
	raster_second_day = arcpy.ia.Int(raster_second_day)

	print("Converting C to F in " + conus_max_temp_forecast_third_day_tif) 
	raster_third_day = arcpy.ia.UnitConversion(conus_max_temp_forecast_third_day_tif, from_unit = 'Celsius', to_unit = 'Fahrenheit' )
	print ("changing raster data type to integer in " + conus_max_temp_forecast_third_day_tif + "...")
	raster_third_day = arcpy.ia.Int(raster_third_day)

	print("Converting C to F in " + conus_max_temp_forecast_seven_day_tif) 
	raster_seven_day = arcpy.ia.UnitConversion(conus_max_temp_forecast_seven_day_tif, from_unit = 'Celsius', to_unit = 'Fahrenheit' )
	#print ("changing raster data type to integer in " + conus_max_temp_forecast_seven_day_tif + "...")
	#raster_seven_day = arcpy.ia.Int(raster_seven_day)
	time.sleep(sleep_interval)

	#Reclassing raster
	print("reclassing " + conus_max_temp_forecast_first_day_int_tif)
	time.sleep(sleep_interval)
	reclass_first = arcpy.sa.Reclassify(in_raster = raster_first_day, reclass_field = "Value", remap = remap_values, missing_values = "DATA")
	print("reclassing " + conus_max_temp_forecast_second_day_int_tif)
	time.sleep(sleep_interval)
	reclass_second = arcpy.sa.Reclassify(in_raster = raster_second_day, reclass_field = "Value", remap = remap_values, missing_values = "DATA")
	print("reclassing " + conus_max_temp_forecast_third_day_int_tif)
	time.sleep(sleep_interval)
	reclass_third = arcpy.sa.Reclassify(in_raster = raster_third_day, reclass_field = "Value", remap = remap_values, missing_values = "DATA")
	
	#print("reclassing " + conus_max_temp_forecast_seven_day_int_tif)
	#time.sleep(sleep_interval)
	#reclass_seven = arcpy.sa.Reclassify(in_raster = raster_seven_day, reclass_field = "Value", remap = remap_values, missing_values = "DATA")

	#convert reclassed raster to polygon
	print("Converting reclassed rasters to polygon...")
	time.sleep(sleep_interval)
	arcpy.conversion.RasterToPolygon(in_raster = reclass_first,\
					out_polygon_features = conus_max_temp_forecast_first_day_poly,\
					simplify = "NO_SIMPLIFY",\
					raster_field = "Value",\
					create_multipart_features = "SINGLE_OUTER_PART")
	
	arcpy.conversion.RasterToPolygon(in_raster = reclass_second,\
					out_polygon_features = conus_max_temp_forecast_second_day_poly,\
					simplify = "NO_SIMPLIFY",\
					raster_field = "Value",\
					create_multipart_features = "SINGLE_OUTER_PART")
					
	arcpy.conversion.RasterToPolygon(in_raster = reclass_third,\
					out_polygon_features = conus_max_temp_forecast_third_day_poly,\
					simplify = "NO_SIMPLIFY",\
					raster_field = "Value",\
					create_multipart_features = "SINGLE_OUTER_PART")
					
	#seven day raster is vectorized as-is, no integer reclass.
	#arcpy.conversion.RasterToPolygon(in_raster = raster_seven_day,\
	#				out_polygon_features = conus_max_temp_forecast_seven_day_poly,\
	#				simplify = "NO_SIMPLIFY",\
	#				raster_field = "Value",\
	#				create_multipart_features = "SINGLE_OUTER_PART")

	print("Converting seven-day forecast raster to polygon...")
	#calculate seven-day forecast max in counties
	
	#conus_covid19_cases_counties_shp = "D:\\Users\\climate_dashboard\\Documents\\climate_dashboard\\data\\output_files\\covid_and_temperature\\conus_covid19_cases_counties.shp"

	print("Zonal stats of seven-day forecast raster in counties...")
	# Process: Spatial Join (Spatial Join) 
	#conus_covid19_cases_counties = "D:\\Users\\climate_dashboard\\Documents\\ArcGIS\\Projects\\MyProject1\\MyProject1.gdb\\conus_covid19_cases_counties"
	#arcpy.SpatialJoin_analysis(target_features=conus_covid19_cases_counties_shp, join_features=conus_max_temp_forecast_seven_day_shp, out_feature_class=conus_covid19_cases_counties_shp2, join_operation="JOIN_ONE_TO_ONE", join_type="KEEP_ALL", field_mapping="GEOID \"GEOID\" true true false 80 Text 0 0,First,#,D:\\Users\\climate_dashboard\\Documents\\climate_dashboard\\data\\output_files\\covid_and_temperature\\conus_covid19_cases_counties.shp,GEOID,0,80;STATE_F \"STATE_F\" true true false 80 Text 0 0,First,#,D:\\Users\\climate_dashboard\\Documents\\climate_dashboard\\data\\output_files\\covid_and_temperature\\conus_covid19_cases_counties.shp,STATE_F,0,80;COUNTYN \"COUNTYN\" true true false 80 Text 0 0,First,#,D:\\Users\\climate_dashboard\\Documents\\climate_dashboard\\data\\output_files\\covid_and_temperature\\conus_covid19_cases_counties.shp,COUNTYN,0,80;NAMELSA \"NAMELSA\" true true false 80 Text 0 0,First,#,D:\\Users\\climate_dashboard\\Documents\\climate_dashboard\\data\\output_files\\covid_and_temperature\\conus_covid19_cases_counties.shp,NAMELSA,0,80;OBJECTI \"OBJECTI\" true true false 9 Long 0 9,First,#,D:\\Users\\climate_dashboard\\Documents\\climate_dashboard\\data\\output_files\\covid_and_temperature\\conus_covid19_cases_counties.shp,OBJECTI,-1,-1;name \"name\" true true false 80 Text 0 0,First,#,D:\\Users\\climate_dashboard\\Documents\\climate_dashboard\\data\\output_files\\covid_and_temperature\\conus_covid19_cases_counties.shp,name,0,80;State \"State\" true true false 80 Text 0 0,First,#,D:\\Users\\climate_dashboard\\Documents\\climate_dashboard\\data\\output_files\\covid_and_temperature\\conus_covid19_cases_counties.shp,State,0,80;NCA4_rg \"NCA4_rg\" true true false 80 Text 0 0,First,#,D:\\Users\\climate_dashboard\\Documents\\climate_dashboard\\data\\output_files\\covid_and_temperature\\conus_covid19_cases_counties.shp,NCA4_rg,0,80;Confrmd \"Confrmd\" true true false 9 Long 0 9,First,#,D:\\Users\\climate_dashboard\\Documents\\climate_dashboard\\data\\output_files\\covid_and_temperature\\conus_covid19_cases_counties.shp,Confrmd,-1,-1;cnty_fr \"cnty_fr\" true true false 9 Long 0 9,First,#,D:\\Users\\climate_dashboard\\Documents\\climate_dashboard\\data\\output_files\\covid_and_temperature\\conus_covid19_cases_counties.shp,cnty_fr,-1,-1;Id \"Id\" true true false 10 Long 0 10,First,#,D:\\Users\\climate_dashboard\\Documents\\climate_dashboard\\data\\output_files\\temperature_forecast_shp\\conus_max_temp_forecast_seven_day.shp,Id,-1,-1;gridcode \"gridcode\" true true false 10 Long 0 10,Max,#,D:\\Users\\climate_dashboard\\Documents\\climate_dashboard\\data\\output_files\\temperature_forecast_shp\\conus_max_temp_forecast_seven_day.shp,gridcode,-1,-1", match_option="WITHIN", search_radius="", distance_field_name="")
	arcpy.sa.ZonalStatisticsAsTable(	in_zone_data =conus_covid19_cases_counties_shp,\
					zone_field = "GEOID",\
					in_value_raster = raster_seven_day,\
					out_table = conus_max_temp_forecast_seven_day_stats_in_counties,
					statistics_type = "ALL")

	#join zonal stats to covid19_cases_counties
	time.sleep(sleep_interval)
	print("join zonal stats to covid19_cases_counties")
	print("conus_max_temp_forecast_seven_day_stats_in_counties" + conus_max_temp_forecast_seven_day_stats_in_counties)
	
	arcpy.JoinField_management(in_data = conus_covid19_cases_counties_shp,\
			in_field = "GEOID",\
			join_table = conus_max_temp_forecast_seven_day_stats_in_counties,\
			join_field = "GEOID",\
			fields = ["MAX", "MEAN"])
					
	print("zipping shapefiles...")
	time.sleep(sleep_interval)
	#all extensions of shapefile
	shp_extensions = ["cpg", "dbf", "prj", "sbn", "sbx", "shp", "xml", "shx"]
	#use list comprehension to generate the filenames in the shapefile to zip up
	files =  [n1 + "." + x for x in shp_extensions]
	#first day
	conus_max_temp_forecast_first_day_poly_zip = zipfile.ZipFile(conus_max_temp_forecast_first_day_poly_zip_filename, 'w')
	for a_file in files:
		try:
			conus_max_temp_forecast_first_day_poly_zip.write(filename = os.path.join(zip_files_dir, a_file),\
									arcname = a_file,\
									compress_type=zipfile.ZIP_DEFLATED)
		except:
			print("can't zip " + a_file)
			continue
	conus_max_temp_forecast_first_day_poly_zip.close()
	
	#second day
	files =  [n2 + "." + x for x in shp_extensions]
	conus_max_temp_forecast_second_day_poly_zip = zipfile.ZipFile(conus_max_temp_forecast_second_day_poly_zip_filename, 'w')
	for a_file in files:
		try:
			conus_max_temp_forecast_second_day_poly_zip.write(filename = os.path.join(zip_files_dir, a_file),\
										arcname = a_file,\
										compress_type=zipfile.ZIP_DEFLATED)
		except:
			print("can't zip " + a_file)
			continue
	conus_max_temp_forecast_second_day_poly_zip.close()
	
	#third day
	files =  [n3 + "." + x for x in shp_extensions]
	conus_max_temp_forecast_third_day_poly_zip = zipfile.ZipFile(conus_max_temp_forecast_third_day_poly_zip_filename, 'w')
	for a_file in files:
		try:
			conus_max_temp_forecast_third_day_poly_zip.write(filename = os.path.join(zip_files_dir, a_file),\
									arcname = a_file,\
									compress_type=zipfile.ZIP_DEFLATED)
		except:
			print("can't zip " + a_file)
			continue
	conus_max_temp_forecast_third_day_poly_zip.close()
	
	#seven-day
	files =  [n4 + "." + x for x in shp_extensions]
	conus_max_temp_forecast_seven_day_poly_zip = zipfile.ZipFile(conus_max_temp_forecast_seven_day_poly_zip_filename, 'w')
	for a_file in files:
		try:
			conus_max_temp_forecast_seven_day_poly_zip.write(filename = os.path.join(zip_files_dir, a_file),\
									arcname = a_file,\
									compress_type=zipfile.ZIP_DEFLATED)
		except:
			print("can't zip " + a_file)
			continue
	conus_max_temp_forecast_seven_day_poly_zip.close()



except Exception as inst:
	print(type(inst))    # the exception instance
	print(inst.args)     # arguments stored in .args
	print(inst)          # __str__ allows args to be printed directly,
	e = sys.exc_info()[1]
	print(e.args[0])
finally:
	print("Done.")
	print("--- %s seconds ---" % round((time.time() - start_time)))