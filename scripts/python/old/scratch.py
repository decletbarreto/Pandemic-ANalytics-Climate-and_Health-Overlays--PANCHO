def search_item(conn,layer_name):
	search_results = conn.content.search(layer_name, item_type='Feature Layer')
	proper_index = [i for i, s in enumerate(search_results) if '"'+layer_name+'"' in str(s)]
	found_item = search_results[proper_index[0]]
	get_item = conn.content.get(found_item.id)
	return get_item
    
conn = GIS("https://www.arcgis.com", username="jdeclet_barreto_ucsusa", password="mijito13")
item = search_item(conn, 'conus_max_temp_forecast_second_day')

conus_max_temp_forecast_second_day_feature_layer_url = "https://services7.arcgis.com/Bj1zEDlg8rTU341s/arcgis/rest/services/conus_max_temp_forecast_second_day/FeatureServer/0" 

lyr = arcgis.features.FeatureLayer('conus_max_temp_forecast_second_day', conn)
TruncateWebLayer(gis=conn, target=conus_max_temp_forecast_second_day_feature_layer_url)