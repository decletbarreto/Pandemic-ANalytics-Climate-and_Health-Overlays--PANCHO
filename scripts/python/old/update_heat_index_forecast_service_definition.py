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

def main():	
	print("Starting process: Update Feature Layers for UCS AGOL.") 
	start_time = time.time()
	print("Started on " + time.ctime(start_time) + ".")
	print("ArcGIS Python API version " + arcgis.__version__)
	
	prjPath = r"D:\Users\climate_dashboard\Documents\climate_dashboard\maps\HI_forecast.aprx"
	sd_fs_name = "heat_index_forecast"
	username = "jdeclet_barreto_ucsusa"
	# Set sharing options
	shrOrg = True
	shrEveryone = False
	shrGroups = ""
	
	# Local paths to create temporary content
	relPath = os.path.dirname(prjPath)
	sddraft = os.path.join(relPath, "WebUpdate.sddraft")
	sd = os.path.join(relPath, "WebUpdate.sd")

	try:
		#login to AGOL
		print("Logging in to AGOL...")		
		conn = GIS("https://www.arcgis.com", username=username, password="mijito13")
	except:
		print("Could not login. Bailing out.")
		sys.exit()
	try:		
		# Create a new SDDraft and stage to SD
		print("Creating SD file from " + prjPath)		
		arcpy.env.overwriteOutput = True
		prj = arcpy.mp.ArcGISProject(prjPath)
		mp = prj.listMaps()[0]
		arcpy.mp.CreateWebLayerSDDraft(	map_or_layers = mp,\
						out_sddraft   = sddraft,\
						service_name = sd_fs_name,\
						server_type = "MY_HOSTED_SERVICES", \
						service_type = "FEATURE_ACCESS", \
						folder_name = "climate_dashboard" , \
						overwrite_existing_service = True, \
						copy_data_to_server = True, \
						allow_exporting = True, \
						enable_editing = False
)
		arcpy.StageService_server(in_service_definition_draft = sddraft, out_service_definition = sd)

		#data_path = "D:\\Users\\climate_dashboard\\Documents\\climate_dashboard\\data\\output_files" 
		
		
		# Find the SD, update it, publish /w overwrite and set sharing and metadata
		print("Search for original SD on portal...")
		sdItem = conn.content.search("{} AND owner:{}".format(sd_fs_name, username), item_type="Service Definition")[0]
		print("Found SD: {}, ID: {} n Uploading and overwriting...".format(sdItem.title, sdItem.id))
		sdItem.update(data=sd)
		print("Overwriting existing feature service...")
		fs = sdItem.publish(overwrite=True)
		
		if shrOrg or shrEveryone or shrGroups:
		  print("Setting sharing options...")
		  fs.share(org=shrOrg, everyone=shrEveryone, groups=shrGroups)
		print("Finished updating: {} - ID: {}".format(fs.title, fs.id))
		#csv_path = os.path.join(data_path, "maxhi_current_valid_poly")
		csv_properties={'title':'Earthquakes around the world from 1800s to early 1900s',
				'description':'Measurements from globally distributed seismometers',
				'tags':'arcgis, python, earthquake, natural disaster, emergency'}
		#thumbnail_path = os.path.join(data_path, "earthquake.png")

		#earthquake_csv_item = conn.content.add(item_properties=csv_properties, data=csv_path)
		#earthquake_feature_layer_item = earthquake_csv_item.publish()
				     

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



