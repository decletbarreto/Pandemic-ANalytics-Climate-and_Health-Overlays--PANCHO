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
		
		service_snippet = 'Confirmed COVID-19 cases as of ' + today_formatted + " at " + today_time_formatted + "." 
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

def update_temperature_forecast_feature_layer(conn,feature_layer_name, shapefile, day):
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
		
		service_snippet = 'Forecast of daily maximum temperature (' + u"\N{DEGREE SIGN}" + 'Fahrenheit) for ' + today_formatted + "." 
		service_description = 'This feature layer shows daily maximum forecast temperatures for ' + today_formatted + ', based on NOAA NWS\'s National Digital Forecast Database (NDFD) rasters.' + \
					'Decimal values were rounded to the nearest whole number and data are symbolized in ten' + u"\N{DEGREE SIGN}" + 'Fahrenheit increments.'   
		service_terms_of_use = 'Use it for good, never for evil.'
		service_credits = 'Temperature data by NOAA NWS National Digital Forecast Database (NDFD, https://www.weather.gov/mdl/ndfd_home). Map feature layer elaborated by Union of Concerned Scientists'
		service_tags = ['NOAA','temperature forecast', 'NDFD', 'NWS', 'UCS', 'Union of Concerned Scientists']
		
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

def update_heat_index_forecast_feature_layer(conn,feature_layer_name, shapefile, day):
	try:
		#search for the feature layer
		print("searching feature layer: " + feature_layer_name)
		search_results = conn.content.search(feature_layer_name, item_type='Feature Layer')
		
		#empty search result
		if search_results == []:
			print("Feature Layer " + feature_layer_name + " not found in AGOL. Check the name.")
			return(0)
		print("found " + feature_layer_name)
		proper_index = [i for i, s in enumerate(search_results) if '"'+feature_layer_name+'"' in str(s)]
		found_item = search_results[proper_index[0]]
		
		print("getting item")
		get_item = conn.content.get(found_item.id)
		#retrieve the item as a FeatureLayerCollection object from the API
		print("retrieving item")
		feature_layerCollection = FeatureLayerCollection.fromitem(get_item)
		print("Overwriting feature layer " + feature_layer_name + " with " + shapefile + "...")
		#overwrite feature layer with latest zipped shapefile
		feature_layerCollection.manager.overwrite(shapefile)
		print("Success.")
		
		print("updating metadata...")
		
		
		today = date.today() + timedelta(days=day)
		today_formatted = str(today.strftime("%B %d, %Y"))
		
		service_snippet = 'Forecast of daily maximum temperature (' + u"\N{DEGREE SIGN}" + 'Fahrenheit) for ' + today_formatted + "." 
		service_description = 'This feature layer shows a Heat Index 3-day forecast for ' + today_formatted + ', based on NOAA NWS\'s National Digital Forecast Database (NDFD) rasters.' + \
					'Decimal values were rounded to the nearest whole number and data are symbolized in ten' + u"\N{DEGREE SIGN}" + 'Fahrenheit increments.'   
		service_terms_of_use = 'Use it for good, never for evil.'
		service_credits = 'Temperature data by NOAA NWS National Digital Forecast Database (NDFD, https://www.weather.gov/mdl/ndfd_home). Map feature layer elaborated by Union of Concerned Scientists'
		service_tags = ['NOAA','temperature forecast', 'NDFD', 'NWS', 'UCS', 'Union of Concerned Scientists']
		
		# Create update dict
		item_properties = {'snippet' : service_snippet,
		                   'description' : service_description,
		                   'licenseInfo' : service_terms_of_use,
		                   'accessInformation' : service_credits,
		                   'tags' : service_tags}
		#get_item.update(item_properties)

		
	except Exception as inst:
		print(type(inst))    # the exception instance
		print(inst.args)     # arguments stored in .args
		print(inst)          # __str__ allows args to be printed directly,
		e = sys.exc_info()[1]
		print(e.args[0])