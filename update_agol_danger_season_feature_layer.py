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
#execfile(r'D:\Users\climate_dashboard\Documents\climate_dashboard\scripts\python\funcdefs.py')

today = date.today()
today_formatted = str(today.strftime("%B %d, %Y"))

arcpy.env.overwriteOutput = True

base_dir         = r"D:\UCS_projects\climate_shop\SuperPANCHO"
data_dir         = "data"
tmp_dir          = os.path.join(base_dir, data_dir, "tmp")
#output_files_dir = os.path.join(base_dir, data_dir, "output_files")
#input_files_dir  = os.path.join(base_dir, data_dir, "input_files")
#temperature_forecast_shp_dir = "temperature_forecast_shp"
env.workspace    = tmp_dir
#zip_files_dir    = os.path.join(output_files_dir, temperature_forecast_shp_dir)
#temp_local_json  = os.path.join(tmp_dir, "temp_local_json.json")

#forecast_first_day_feature_layer_name    = "conus_max_temp_forecast_first_day"
#forecast_second_day_feature_layer_name   = "conus_max_temp_forecast_second_day"
#forecast_third_day_feature_layer_name    = "conus_max_temp_forecast_third_day"
#covid19_cases_feature_layer_name         = "conus_covid19_cases_counties" 
climate_justice_indicators_feature_layer_name        = "climate_justice_indicators"
climate_justice_indicators_points_feature_layer_name = "climate_justice_indicators_points"

#heat_index_forecast_zip_filename		     = os.path.join(output_files_dir, "maxhi_current_valid_poly") + ".zip"

def update_danger_season_feature_layer(conn):
	try:	
		prjPath = r"D:\UCS_projects\climate_shop\SuperPANCHO\maps\danger_season.aprx"
		sd_fs_name = "danger_season_WFL1"
		username = "jdeclet_barreto_ucsusa"
		print("Updating " + sd_fs_name)
		# Set sharing options
		shrOrg = True
		shrEveryone = True
		shrGroups = ""

		# Local paths to create temporary content
		relPath = os.path.dirname(prjPath)
		sddraft = os.path.join(relPath, "service_definitions", "danger_season.sddraft")
		sd = os.path.join(relPath, "danger_season_update.sd")
		
		# Create a new SDDraft and stage to SD
		print("Creating SD file from " + prjPath)		
		print("SD draft: " + sddraft)
		arcpy.env.overwriteOutput = True
		
		try:
			print("Getting project object from map path...")
			prj = arcpy.mp.ArcGISProject(prjPath)
			print("Listing maps...")
			mp = prj.listMaps()[0]
			print("map name: " +  mp.name)
			print("Creating web layer SD draft...")
			arcpy.mp.CreateWebLayerSDDraft(	map_or_layers = mp,\
						out_sddraft   = sddraft,\
						service_name = sd_fs_name,\
						server_type = "MY_HOSTED_SERVICES", \
						service_type = "FEATURE_ACCESS", \
						folder_name = "PANCHO" , \
						overwrite_existing_service = True, \
						copy_data_to_server = True, \
						allow_exporting = True, \
						enable_editing = False)
			print("Staging service...")
			arcpy.StageService_server(in_service_definition_draft = sddraft, out_service_definition = sd)

			# Find the SD, update it, publish /w overwrite and set sharing and metadata
			print("Search for original SD on portal...")
			sdItem = conn.content.search("{} AND owner:{}".format(sd_fs_name, username), item_type="Service Definition")[0]
			print("Found SD: {}, ID: {} n Uploading and overwriting...".format(sdItem.title, sdItem.id))
			sdItem.update(data=sd)
			print("Overwriting existing feature service...")
			fs = sdItem.publish(overwrite=True)
		
		except Exception as inst:
			print(type(inst))    # the exception instance
			print(inst.args)     # arguments stored in .args
			print(inst)          # __str__ allows args to be printed directly,
			e = sys.exc_info()[1]
			print("sddraft: " + sddraft)
			print("sd_fs_name: " + sd_fs_name)
			print("mp: " + mp.name)
			print(e.args[0])
			
		
		if shrOrg or shrEveryone or shrGroups:
		  print("Setting sharing options...")
		  fs.share(org=shrOrg, everyone=shrEveryone, groups=shrGroups)
		print("Finished updating: {} - ID: {}".format(fs.title, fs.id))
		
		print("Updating metadata...")				
		yesterday = date.today() - timedelta(days=1)
		yesterday_formatted = str(today.strftime("%B %d, %Y"))
				
		service_snippet = 'Danger Season 2022 created on' + yesterday_formatted + "." 
		service_description = 'This feature layer shows...).'
		service_terms_of_use = 'Use it for good, never for evil.'
		service_credits = 'Data obtained from... Map feature layer elaborated by Union of Concerned Scientists'
		service_tags = ['climate', 'UCS', 'Union of Concerned Scientists']
		
		# Create update dict
		item_properties = {'snippet'		: service_snippet,
		                   'description' 	: service_description,
		                   'licenseInfo' 	: service_terms_of_use,
		                   'accessInformation' 	: service_credits,
		                   'tags' 		: service_tags}
		#update service definition and feature layer metadata
		sdItem.update(item_properties)
		fs.update(item_properties)
		
	except Exception as inst:
		print(type(inst))    # the exception instance
		print(inst.args)     # arguments stored in .args
		print(inst)          # __str__ allows args to be printed directly,
		e = sys.exc_info()[1]
		print(e.args[0])

def main():	
	print("Starting process: Update Danger Season 2022 Feature Layers for UCS AGOL...") 
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
		update_danger_season_feature_layer(conn = conn)
		
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


