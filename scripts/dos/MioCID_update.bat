ECHO OFF
ECHO MioCID update
ECHO 1. Process NDFD Temperature Forecast Rasters
"C:\Program Files\R\R-3.6.3\bin\Rscript.exe" -e "source('D:\\Users\\climate_dashboard\\Documents\\climate_dashboard\\scripts\\r\\process_NDFD_temperature_forecast_rasters.R')"
ECHO Done.

ECHO 2. Generate COVID-19 counties shapefile 
"C:\Program Files\R\R-3.6.3\bin\Rscript.exe" -e "source('D:\\Users\\climate_dashboard\\Documents\\climate_dashboard\\scripts\\r\\process_covid19_cases_data.R')"
ECHO Done.

ECHO 3. Create Local Heat Index Feature Layers for AGOL
D:\Users\climate_dashboard\ArcGISPro\bin\Python\envs\arcgispro-py3\python.exe D:\Users\climate_dashboard\Documents\climate_dashboard\scripts\python\create_local_heat_index_forecast_feature_layers_for_agol.py
ECHO Done.

ECHO 4. Update AGOL Feature Layers
D:\Users\climate_dashboard\ArcGISPro\bin\Python\envs\arcgispro-py3\python.exe D:\Users\climate_dashboard\Documents\climate_dashboard\scripts\python\update_agol_feature_layers.py
ECHO MioCID update completed.

ECHO 5. Copy to Dropbox
copy D:\Users\climate_dashboard\Documents\climate_dashboard\data\output_files\covid_and_temperature\*.* D:\Users\climate_dashboard\Dropbox\data\covid19
copy D:\Users\climate_dashboard\Documents\climate_dashboard\data\output_files\maxhi_current_valid_poly.zip D:\Users\climate_dashboard\Dropbox\data\covid19
copy D:\Users\climate_dashboard\Documents\climate_dashboard\data\tmp\HI_forecast\maxhi_current_valid_poly.* D:\Users\climate_dashboard\Dropbox\data\covid19
