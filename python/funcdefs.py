from datetime import datetime

def TruncateWebLayer(gis=None, target=None):
	try:
		lyr = arcgis.features.FeatureLayer(target, gis)
		#get feature count
		count = lyr.query(return_count_only=True)
		if count != 0:
			lyr.manager.truncate()
			print ("Successfully truncated layer: " + str(target))
		else:
			print ("No features to truncate.")
	except:
		print("Failed truncating: " + str(target))
		sys.exit()

def search_item(conn,layer_name):
	search_results = conn.content.search(layer_name, item_type='Feature Layer')
	proper_index = [i for i, s in enumerate(search_results) if '"'+layer_name+'"' in str(s)]
	found_item = search_results[proper_index[0]]
	get_item = conn.content.get(found_item.id)
	return get_item

def update_covid19_cases_feature_layer(conn, feature_layer_name, shapefile, day):
	try:
		#search for the feature layer
		print("searching feature layer: " + feature_layer_name)
		search_results = conn.content.search(feature_layer_name, item_type='Feature Layer')
		
		#empty search result
		if search_results == []:
			print("Feature Layer " + feature_layer_name + " not found in AGOL. Check the name.")
			return(0)
		proper_index = [i for i, s in enumerate(search_results) if '"'+feature_layer_name+'"' in str(s)]
		found_item = search_results[proper_index[0]]
		get_item = conn.content.get(found_item.id)
		#retrieve the item as a FeatureLayerCollection object from the API
		feature_layerCollection = FeatureLayerCollection.fromitem(get_item)
		print("Overwriting feature layer " + feature_layer_name + " with " + shapefile + "...")
		#overwrite feature layer with latest zipped shapefile
		feature_layerCollection.manager.overwrite(shapefile)
		print("Success.")		
		print("updating metadata...")
				
		today = date.today() + timedelta(days=day)
		today_formatted = str(today.strftime("%B %d, %Y"))
		now = datetime.now()
		today_time_formatted = str(now.strftime("%H:%M"))
		
		service_snippet = 'Confired COVID-19 cases as of ' + today_formatted + " at " + today_time_formatted + "." 
		service_description = 'This feature layer shows .'   
		service_terms_of_use = 'Use it for good, never for evil.'
		service_credits = 'Temperature data by NOAA NWS National Digital Forecast Database (NDFD, https://www.weather.gov/mdl/ndfd_home). Map feature layer elaborated by Union of Concerned Scientists'
		service_tags = ['COVID19','UCS', 'Union of Concerned Scientists']
		
		# Create update dict
		item_properties = {'snippet' : service_snippet,
		                   'description' : service_description,
		                   'licenseInfo' : service_terms_of_use,
		                   'accessInformation' : service_credits,
		                   'tags' : service_tags}
		get_item.update(item_properties)

		
	except Exception as inst:
		print(type(inst))    # the exception instance
		print(inst.args)     # arguments stored in .args
		print(inst)          # __str__ allows args to be printed directly,
		e = sys.exc_info()[1]
		print(e.args[0])   	

def update_heat_index_forecast_feature_layer(conn, day):
	try:	
		prjPath = r"D:\Users\climate_dashboard\Documents\climate_dashboard\maps\heat_index_forecast.aprx"
		sd_fs_name = "heat_index_forecast"
		username = "jdeclet_barreto_ucsusa"
		print("Updating " + sd_fs_name)
		# Set sharing options
		shrOrg = True
		shrEveryone = True
		shrGroups = ""

		# Local paths to create temporary content
		relPath = os.path.dirname(prjPath)
		sddraft = os.path.join(relPath, "service_definitions", "heat_index_forecast_update.sddraft")
		sd = os.path.join(relPath, "heat_index_forecast_update.sd")
		
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
						enable_editing = False)
		arcpy.StageService_server(in_service_definition_draft = sddraft, out_service_definition = sd)

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
		
		print("Updating metadata...")				
		today = date.today() + timedelta(days=day)
		today_formatted = str(today.strftime("%B %d, %Y"))
		date_three_days_ago = datetime.today() - timedelta(days=3)
		date_three_days_ago_formatted = str(date_three_days_ago.strftime("%Y%m%d"))
		
		service_snippet = 'Forecast of daily maximum Heat Index (' + u"\N{DEGREE SIGN}" + 'Fahrenheit) for ' + today_formatted + "." 
		service_description = 'This feature layer shows the Heat Index forecast for ' + date_three_days_ago_formatted + ', based on the NOAA Weather Prediction Center (https://ftp.wpc.ncep.noaa.gov/shapefiles/heatindex/).'
		service_terms_of_use = 'Use it for good, never for evil.'
		service_credits = 'Heat Index day 3 forecast data by NOAA Weather Prediction Center (https://ftp.wpc.ncep.noaa.gov/shapefiles/heatindex/). Map feature layer elaborated by Union of Concerned Scientists'
		service_tags = ['heat index forecast', 'WPC', 'NOAA', 'UCS', 'Union of Concerned Scientists']
		
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


def update_covid19_cases_feature_layer2(conn):
	try:	
		prjPath = r"D:\Users\climate_dashboard\Documents\climate_dashboard\maps\covid19_cases_by_county.aprx"
		sd_fs_name = "conus_covid19_cases_counties"
		username = "jdeclet_barreto_ucsusa"
		print("Updating " + sd_fs_name)
		# Set sharing options
		shrOrg = True
		shrEveryone = True
		shrGroups = ""

		# Local paths to create temporary content
		relPath = os.path.dirname(prjPath)
		sddraft = os.path.join(relPath, "service_definitions", "conus_covid19_cases_counties_update.sddraft")
		sd = os.path.join(relPath, "conus_covid19_cases_counties_update.sd")
		
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
						folder_name = "PANCHO" , \
						overwrite_existing_service = True, \
						copy_data_to_server = True, \
						allow_exporting = True, \
						enable_editing = False)
		arcpy.StageService_server(in_service_definition_draft = sddraft, out_service_definition = sd)

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
		
		print("Updating metadata...")				
		yesterday = date.today() - timedelta(days=1)
		yesterday_formatted = str(today.strftime("%B %d, %Y"))
				
		service_snippet = 'Confirmed COVID-19 cases as of ' + yesterday_formatted + "." 
		service_description = 'This feature layer shows the total number of confirmed COVID-19 cases in each county as reported by the Center for Systems Science and Engineering (CSSE) at Johns Hopkins University (https://github.com/CSSEGISandData/COVID-19).'
		service_terms_of_use = 'Use it for good, never for evil.'
		service_credits = 'Data obtained from the Center for Systems Science and Engineering (CSSE) at Johns Hopkins University (https://github.com/CSSEGISandData/COVID-19). Map feature layer elaborated by Union of Concerned Scientists'
		service_tags = ['heat index forecast', 'WPC', 'NOAA', 'UCS', 'Union of Concerned Scientists']
		
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
