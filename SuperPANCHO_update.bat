REM Get start time:
for /F "tokens=1-4 delims=:.," %%a in ("%time%") do (
   set /A "start=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100"
)

ECHO OFF
ECHO SuperPANCHO nightly update

SET python_executable="I:\esri\ArcGIS Pro 2.7\bin\Python\envs\arcgispro-py3\python.exe"
SET heat_index_script="D:\UCS_projects\climate_shop\SuperPANCHO\bin\create_heat_index_forecast_shapefile.py"
SET nws_warnings_script="D:\UCS_projects\climate_shop\SuperPANCHO\bin\process_current_nws_warnings.R"
SET rscript_exe=""I:\R-4.0.3\bin\Rscript.exe""

ECHO 1. Create Heat Index shapefile
%python_executable% %heat_index_script% 
ECHO Done.

ECHO 2. Create NWS shapefile
%rscript_exe% -e "source('D:\\UCS_projects\\climate_shop\\SuperPANCHO\\bin\\process_current_nws_warnings.R')"
ECHO Done.

ECHO 3. Create AQI shapefile
%rscript_exe%  -e "source('D:\\UCS_projects\\climate_shop\\SuperPANCHO\\bin\\process_aqi_data.R')"
ECHO Done.

ECHO 4. Create CEJST/NRI shapefile
%rscript_exe%  -e "source('D:\\UCS_projects\\climate_shop\\SuperPANCHO\\bin\\process_cjest_nri_data.R')"
ECHO Done.

ECHO 5. Assemble Census Tract Danger Season shapefile
%rscript_exe%  -e "source('D:\\UCS_projects\\climate_shop\\SuperPANCHO\\bin\\assemble_ct_danger_season_shapefile.R')"
ECHO Done.

ECHO 6. Generate Danger Season County-level summary
%rscript_exe%  -e "source('D:\\UCS_projects\\climate_shop\\SuperPANCHO\\bin\\generate_danger_season_summaries.R')"
ECHO Done.

ECHO 7. Update Danger Season AGOL feature layer
%python_executable% D:\UCS_projects\climate_shop\SuperPANCHO\bin\update_agol_danger_season_feature_layer.py
ECHO Done.



REM Get end time:
for /F "tokens=1-4 delims=:.," %%a in ("%time%") do (
   set /A "end=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100"
)

REM Get elapsed time:
SET /A elapsed=end-start

REM Show elapsed time:
SET /A hh=elapsed/(60*60*100), rest=elapsed%%(60*60*100), mm=rest/(60*100), rest%%=60*100, ss=rest/100, cc=rest%%100
IF %mm% lss 10 SET mm=0%mm%
IF %ss% lss 10 SET ss=0%ss%
IF %cc% lss 10 SET cc=0%cc%
ECHO Processing time: %hh%:%mm%:%ss%,%cc%