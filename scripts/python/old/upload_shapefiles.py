import arcgis
from arcgis.gis import GIS
from arcgis.features import FeatureLayerCollection
from arcgis.features import FeatureLayer
import os

def TruncateWebLayer(gis=None, target=None):
    try:
        lyr = arcgis.features.FeatureLayer(target, gis)
        lyr.manager.truncate()
        print ("Successfully truncated layer: " + str(target))
    except:
        print("Failed truncating: " + str(target))
        sys.exit()

#login to AGOL
print("Starting process: Create Feature Layers in UCS AGOL.") 
gis = GIS("https://www.arcgis.com", username="jdeclet_barreto_ucsusa", password="mijito13")

#AGOL item metadata
agol_folder = "climate_dashboard"
covid19_cases_in_counties_service_name= 'counties_covid19_and_temperature'
covid19_cases_in_counties_title = 'title'
covid19_cases_in_counties_description = 'descr'

#covid19 data
covid19_data_path = "A:/climate_dashboard/data/output_files"
conus_covid19_cases_counties_zip_shp_path        = os.path.join(covid19_data_path, "counties_covid19_and_temperature.shp")
counties_covid19_and_temperature_FeatureLayerURL = "https://services7.arcgis.com/Bj1zEDlg8rTU341s/arcgis/rest/services/counties_covid19_and_temperature/FeatureServer/0"
conus_covid19_cases_counties_local_JSON          = os.path.join(covid19_data_path, "counties_covid19_and_temperature.json")


#update covid19 feature layer
#first remove all features from the already published feature layer
TruncateWebLayer(gis, counties_covid19_and_temperature_FeatureLayerURL)
#reference the truncated layer as FeatureLayer object from the ArcGIS Python API
fl = arcgis.features.FeatureLayer(counties_covid19_and_temperature_FeatureLayerURL, gis)

#the URL of a single feature layer within a collection in an AGOL portal
#a feature class on the local system with the same schema as the portal layer

#create a JSON object from the local features
jSON = arcpy.FeaturesToJSON_conversion(conus_covid19_cases_counties_zip_shp_path, conus_covid19_cases_counties_local_JSON)

#create a FeatureSet object from the JSON
fs = arcgis.features.FeatureSet.from_json(open(localJSON).read())

#add/append the local features to the hosted feature layer.
fl.edit_features(adds = fs)

#update metadata for counties_covid19_and_temperature feature layer
#item_prop = {'title':'USA Capitals 2'}
#cities_item.update(item_properties = item_prop, 
#                   thumbnail=os.path.join('data','updating_gis_content','capital_cities.png'))
#cities_item


search_result = gis.content.search("title:counties_covid19_and_temperature", item_type = "Feature Layer")
FLayer = FeatureLayerCollection.fromItem(search_result)
FLayer.manager.overwrite(conus_covid19_cases_counties_zip_shp_path)



#conus_covid19_cases_properties={'title':covid19_cases_in_counties_title,\
#				'description':'Measurements from globally distributed seismometers',\
#				'tags':'covid19',\
#				'type':'Feature Service'}

#conus_covid19_cases_counties_shp = gis.content.add(item_properties = conus_covid19_cases_properties,\
						   data = conus_covid19_cases_counties_zip_shp_path,\
						   )
#published_service = conus_covid19_cases_counties_shp.publish(overwrite=True)


# check if service name is available
#if(gis.content.is_service_name_available(service_name= 'covid19_cases_in_counties', service_type = 'featureService')):

# let us publish an empty service
#	print ("creating covid19_cases_in_counties featureService")
#	empty_service_item = gis.content.create_service(name='covid19_cases_in_counties', service_type='featureService',folder=agol_folder)
#	print(empty_service_item.layers)

#conus_covid19_cases_counties_item = gis.content.add(item_properties=conus_covid19_cases_properties, data=covid19_data_path)

#conus_covid19_cases_counties_shp = "A:\coronavirus_response\data\infection_data\CONUS\conus_covid19_cases_counties.shp"
print (gis)