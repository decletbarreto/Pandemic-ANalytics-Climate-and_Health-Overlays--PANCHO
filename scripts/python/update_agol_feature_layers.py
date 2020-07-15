# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
#create feature layers for AGOL

import arcpy
import arcgis
from arcgis.gis import GIS
import os
import time
from arcpy import env
import fnmatch
import sys
from arcgis.features import FeatureLayerCollection
from datetime import date
from datetime import timedelta
from past.builtins import execfile

#sys.path.insert(1, r'D:\Users\climate_dashboard\Documents\climate_dashboard\scripts\python\funcdefs.py')
#import funcdefs
execfile(r'D:\Users\climate_dashboard\Documents\climate_dashboard\scripts\python\funcdefs.py')

today = date.today()
today_formatted = str(today.strftime("%B %d, %Y"))

arcpy.env.overwriteOutput = True

base_dir         = r"D:\Users\climate_dashboard\Documents\climate_dashboard"
data_dir         = "data"
tmp_dir          = os.path.join(base_dir, data_dir, "raster_tmp")
output_files_dir = os.path.join(base_dir, data_dir, "output_files")
input_files_dir  = os.path.join(base_dir, data_dir, "input_files")
temperature_forecast_shp_dir = "temperature_forecast_shp"
env.workspace    = tmp_dir
zip_files_dir    = os.path.join(output_files_dir, temperature_forecast_shp_dir)
temp_local_json  = os.path.join(tmp_dir, "temp_local_json.json")

forecast_first_day_feature_layer_name    = "conus_max_temp_forecast_first_day"
forecast_second_day_feature_layer_name   = "conus_max_temp_forecast_second_day"
forecast_third_day_feature_layer_name    = "conus_max_temp_forecast_third_day"
covid19_cases_feature_layer_name         = "conus_covid19_cases_counties" 
heat_index_forecast_feature_layer_name   = "maxhi_forecast"

#conus_max_temp_forecast_first_day_poly   = os.path.join(output_files_dir, temperature_forecast_shp_dir, forecast_first_day_feature_layer_name)
#conus_max_temp_forecast_second_day_poly  = os.path.join(output_files_dir, temperature_forecast_shp_dir, forecast_second_day_feature_layer_name)
#conus_max_temp_forecast_third_day_poly   = os.path.join(output_files_dir, temperature_forecast_shp_dir, forecast_third_day_feature_layer_name)

#conus_max_temp_forecast_first_day_poly_zip_filename  = os.path.join(output_files_dir, temperature_forecast_shp_dir, forecast_first_day_feature_layer_name) + ".zip"
#conus_max_temp_forecast_second_day_poly_zip_filename = os.path.join(output_files_dir, temperature_forecast_shp_dir, forecast_second_day_feature_layer_name) + ".zip"
#conus_max_temp_forecast_third_day_poly_zip_filename  = os.path.join(output_files_dir, temperature_forecast_shp_dir, forecast_third_day_feature_layer_name) + ".zip"
covid19_cases_zip_filename                           = os.path.join(output_files_dir, "covid_and_temperature", "confirmed_covid19_cases_in_counties") + ".zip"
heat_index_forecast_zip_filename		     = os.path.join(output_files_dir, "maxhi_current_valid_poly") + ".zip"
#conus_max_temp_forecast_second_day_feature_layer_url = r"https://services7.arcgis.com/Bj1zEDlg8rTU341s/arcgis/rest/services/conus_max_temp_forecast_second_day/FeatureServer/0" 

def main():	
	print("Starting process: Update Feature Layers for UCS AGOL.") 
	start_time = time.time()
	print("Started on " + time.ctime(start_time) + ".")
	print("ArcGIS Python API version " + arcgis.__version__)

	try:
		#login to AGOL
		print("Logging in to AGOL...")		
		conn = GIS("https://www.arcgis.com", username="jdeclet_barreto_ucsusa", password="mijito13")
	except:
		print("Could not login. Bailing out.")
		sys.exit()
	try:		
		#update_temperature_forecast_feature_layer(conn = conn, feature_layer_name = forecast_first_day_feature_layer_name,  shapefile = conus_max_temp_forecast_first_day_poly_zip_filename,  day=0)
		#update_temperature_forecast_feature_layer(conn = conn, feature_layer_name = forecast_second_day_feature_layer_name, shapefile = conus_max_temp_forecast_second_day_poly_zip_filename, day=1)
		#update_temperature_forecast_feature_layer(conn = conn, feature_layer_name = forecast_third_day_feature_layer_name,  shapefile = conus_max_temp_forecast_third_day_poly_zip_filename,  day=2)
		
		#update_covid19_cases_feature_layer(conn = conn, feature_layer_name = covid19_cases_feature_layer_name, shapefile = covid19_cases_zip_filename, day=1)
		update_heat_index_forecast_feature_layer(conn = conn, day=0)
	except Exception as inst:
		print(type(inst))    # the exception instance
		print(inst.args)     # arguments stored in .args
		print(inst)          # __str__ allows args to be printed directly,
		e = sys.exc_info()[1]
		print(e.args[0])   
	finally:
		print("Done.")
		print("--- %s seconds ---" % round((time.time() - start_time)))

if __name__ == '__main__':
	sys.exit(main())


