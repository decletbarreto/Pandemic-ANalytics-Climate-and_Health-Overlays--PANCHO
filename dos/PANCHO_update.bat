ECHO OFF
ECHO PANCHO nightly update
REM ECHO 1. Process NDFD Temperature Forecast Rasters
REM "C:\Program Files\R\R-3.6.3\bin\Rscript.exe" -e "source('D:\\Users\\climate_dashboard\\Documents\\climate_dashboard\\scripts\\r\\process_NDFD_temperature_forecast_rasters.R')"
REM ECHO Done.

ECHO 1. Create Local Heat Index Feature Layers for AGOL
D:\Users\climate_dashboard\ArcGISPro\bin\Python\envs\arcgispro-py3\python.exe D:\Users\climate_dashboard\Documents\climate_dashboard\scripts\python\create_local_heat_index_forecast_feature_layers_for_agol.py
ECHO Done.

ECHO 2. Create NYT COVID-19 trends and Google Mobility Report Feature Layers
D:\Users\climate_dashboard\ArcGISPro\bin\Python\envs\arcgispro-py3\python.exe D:\Users\climate_dashboard\Documents\climate_dashboard\scripts\python\process_nytimes_case_data_and_google_mobility_data.py
ECHO Done.

ECHO 3. Generate COVID-19 counties shapefile 
"C:\Program Files\R\R-3.6.3\bin\Rscript.exe" -e "source('D:\\Users\\climate_dashboard\\Documents\\climate_dashboard\\scripts\\r\\process_covid19_cases_data.R')"
ECHO Done.

ECHO 4. Update AGOL Feature Layers
D:\Users\climate_dashboard\ArcGISPro\bin\Python\envs\arcgispro-py3\python.exe D:\Users\climate_dashboard\Documents\climate_dashboard\scripts\python\update_agol_feature_layers.py
ECHO PANCHO update completed.

ECHO 5. Copy to Dropbox
REM COVID cases in counties
copy D:\Users\climate_dashboard\Documents\climate_dashboard\data\output_files\covid_and_temperature\*.* D:\Users\climate_dashboard\Dropbox\data\covid19\daily_PANCHO_updates
REM Max Heat Index final
copy D:\Users\climate_dashboard\Documents\climate_dashboard\data\tmp\HI_forecast\maxhi_counties_join_final.* D:\Users\climate_dashboard\Dropbox\data\covid19\daily_PANCHO_updates
