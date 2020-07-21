# -*- coding: utf-8 -*-
"""
Created on Thu Jul  2 17:28:28 2020
@author: KDahl
"""
import pandas
import datetime
from datetime import date
import csv
import sys
import time
from datetime import date
from datetime import timedelta
import arcpy
import arcgis
from arcgis.gis import GIS
import urllib.request
import numpy
import pdb

# csvs of nytimes covid case and google mobility data live in different directories
# off of the 'path' branch. likewise, there's a 'county_level_risk' directory for the results

def download_latest_mobility_report():
    try:
        url = 'https://www.gstatic.com/covid19/mobility/Global_Mobility_Report.csv?cachebust=5805f0ab2859cf87'
        local_mobility_report = 'D:/Users/climate_dashboard/Documents/climate_dashboard/data/county_level_risk/Global_Mobility_Report.csv' 
        print("downloading google mobility report data file at " + url + " to " + local_mobility_report)
        urllib.request.urlretrieve(url, local_mobility_report)
    
    except Exception as inst:
        print("Exception downloading Google Mobility Report.")
        print(type(inst))    # the exception instance
        print(inst.args)     # arguments stored in .args
        print(inst)          # __str__ allows args to be printed directly,
        e = sys.exc_info()[1]
        print(e.args[0])
    finally:
        print("Done.")
       
def download_latest_nyt_counties_cases_file():
    try:
        url = 'https://github.com/nytimes/covid-19-data/raw/master/us-counties.csv'
        local_nyt_report = 'D:/Users/climate_dashboard/Documents/climate_dashboard/data/county_level_risk/us-counties.csv' 
        print("downloading NYT covid cases file at " + url + " to " + local_nyt_report)
        urllib.request.urlretrieve(url, local_nyt_report)
    
    except Exception as inst:
        print("Exception downloading NYT covid cases file.")
        print(type(inst))    # the exception instance
        print(inst.args)     # arguments stored in .args
        print(inst)          # __str__ allows args to be printed directly,
        e = sys.exc_info()[1]
        print(e.args[0])
    finally:
        print("Done.")


def id_counties_with_inc_new_cases(county_list, destination_list): # county list supplied by JDB as csv
    # specify path
    #path = 'C:/Users/kdahl/OneDrive - Union of Concerned Scientists/GIS_data/coronavirus/coronavirus data/'
    path = 'D:/Users/climate_dashboard/Documents/climate_dashboard/data/county_level_risk' 
    #date,county,state,fips,cases,deaths
    #2020-01-21,Snohomish,Washington,53061,1,0
    nyt_cases_data_types = {"date" : "str", "county" : "str", "state" : "str", "fips" : "str", "cases": "int", "deaths" : "int"}
    mobility_data_types  = {"country_region_code" : "str",
                            "country_region" : "str" ,
                            "sub_region_1" : "str",
                            "sub_region_2" : "str",
                            "iso_3166_2_code" : "str",
                            "census_fips_code" : "str",
                            "date" : "str",
                            "retail_and_recreation_percent_change_from_baseline" : "str",
                            "grocery_and_pharmacy_percent_change_from_baseline" : "str",
                            "parks_percent_change_from_baseline" : "str",
                            "transit_stations_percent_change_from_baseline" : "str",
                            "workplaces_percent_change_from_baseline" : "str",
                            "residential_percent_change_from_baseline" : "str"}
    
    results_csv_filename = "county_covid_and_mobility_trends.csv"
    csv_header_filename  = "csv_header.csv"
    global_mobility_report_filename = "Global_Mobility_Report.csv"
    nyt_covid_cases_filename = "us-counties.csv"
    
    with open(path + '/' + results_csv_filename ,'w', newline='') as csvfile: # if converting to python3, change to 'w' and add newline=''
            print("opening header...")
            fieldnames_df = pandas.read_csv(path + '/' + csv_header_filename)
            fieldnames = list(fieldnames_df.columns)
            csvwriter = csv.DictWriter(csvfile, fieldnames=fieldnames, delimiter=',')
            csvwriter.writeheader()
            csvwriter = csv.writer(csvfile, delimiter=',')

            #Read in google mobility csv and cast datatypes
            print("reading mobility report")
            mobility_df = pandas.read_csv(path + '/' + global_mobility_report_filename, dtype = mobility_data_types)
            mobility_df['date'] = pandas.to_datetime(mobility_df['date'])
            #print(mobility_df)

            #percent columns from google mobility were read as str. convert to int
            mobility_df["retail_and_recreation_percent_change_from_baseline"] = pandas.to_numeric(mobility_df["retail_and_recreation_percent_change_from_baseline"],
                                                                                                  errors = "coerce")
            mobility_df["grocery_and_pharmacy_percent_change_from_baseline"] = pandas.to_numeric(mobility_df["grocery_and_pharmacy_percent_change_from_baseline"],
                                                                                                  errors = "coerce")
            mobility_df["parks_percent_change_from_baseline"] = pandas.to_numeric(mobility_df["parks_percent_change_from_baseline"],
                                                                                                  errors = "coerce")
            mobility_df["transit_stations_percent_change_from_baseline"] = pandas.to_numeric(mobility_df["transit_stations_percent_change_from_baseline"],
                                                                                                  errors = "coerce")
            mobility_df["workplaces_percent_change_from_baseline"] = pandas.to_numeric(mobility_df["workplaces_percent_change_from_baseline"],
                                                                                                  errors = "coerce")
            mobility_df["residential_percent_change_from_baseline"] = pandas.to_numeric(mobility_df["residential_percent_change_from_baseline"],
                                                                                                  errors = "coerce")
         
            # read in the nytimes cases csv and cast datatypes
            print("\treading NYT file")
            covid_df = pandas.read_csv(path + '/' + nyt_covid_cases_filename, dtype = nyt_cases_data_types)
            covid_df['date'] = pandas.to_datetime(covid_df['date'])  
            n = 1
            print("looping through counties...")
            for fips_code in county_list:
                print("processing " + str(fips_code) + ":" + str(n) + "/" + str(len(county_list)))       
                n = n + 1
                
                #1. COVID CASES
                try:                    
                    # select covid cases rows in county
                    #print("\tselecting covid rows in county")
                    county_covid_data = covid_df.loc[covid_df['fips'] == str(fips_code)]
                    #set empty output values if county not found in covid cases files
                    if county_covid_data.empty:
                        print ("\t" + str(fips_code) + " not found in covid cases data")
                        latest_date                                 = ""
                        seven_days_ago                              = ""
                        cases_latest_date                           = ""
                        cases_seven_days_ago                        = ""
                        past_week_ave_daily_new_cases               = ""
                        previous_week_ave_daily_new_cases           = ""
                        past_week_ave_daily_new_cases_formatted     = ""
                        previous_week_ave_daily_new_cases_formatted = ""

                    #otherwise, calculate.
                    else:
                        #print(county_covid_data)
                        # pull covid data from past 14 days into a new dataframe
                        latest_date       = county_covid_data['date'].max()
                        seven_days_ago    = latest_date - datetime.timedelta(days=7)
                        fourteen_days_ago = latest_date - datetime.timedelta(days=14)

                        #cases_latest_date = county_covid_data[county_covid_data['date']==latest_date]['cases'].iloc[0]
                        #if this df is empty it means there were no cases
                        cases_latest_date = county_covid_data[county_covid_data['date']==latest_date]
                        if cases_latest_date.empty:
                            cases_latest_date = 0
                        else:
                            cases_latest_date = cases_latest_date['cases'].iloc[0]
                            
                        #cases_seven_days_ago = county_covid_data[county_covid_data['date']==seven_days_ago]['cases'].iloc[0]                        cases_seven_days_ago = county_covid_data[county_covid_data['date']==seven_days_ago]['cases']
                        #if this df is empty it means there were no cases seven days ago
                        cases_seven_days_ago = county_covid_data[county_covid_data['date']==seven_days_ago]
                        if cases_seven_days_ago.empty:
                            cases_seven_days_ago = 0
                        else:
                            cases_seven_days_ago = cases_seven_days_ago['cases'].iloc[0]

                        #cases_fourteen_days_ago = county_covid_data[county_covid_data['date']==fourteen_days_ago]['cases'].iloc[0]
                        #if this df is empty it means there were no cases fourteen days ago
                        cases_fourteen_days_ago = county_covid_data[county_covid_data['date']==fourteen_days_ago]
                        if cases_fourteen_days_ago.empty:
                            cases_fourteen_days_ago = 0
                        else:
                            cases_fourteen_days_ago = cases_fourteen_days_ago['cases'].iloc[0]

                        past_week_ave_daily_new_cases = math.ceil((cases_latest_date - cases_seven_days_ago)/7)
                        print('\tLast week ave new daily cases = '+ str(past_week_ave_daily_new_cases))     

                        previous_week_ave_daily_new_cases = math.ceil((cases_seven_days_ago - cases_fourteen_days_ago)/7)
                        print('\tPrevious week ave new daily cases = '+ str(previous_week_ave_daily_new_cases))
                        #pdb.set_trace()
                        #format values for writing
                        #latest_date_formatted = datetime.datetime.strptime(latest_date, '%Y-%m-%d')
                        previous_week_ave_daily_new_cases_formatted = math.ceil(previous_week_ave_daily_new_cases)
                        past_week_ave_daily_new_cases_formatted     = math.ceil(past_week_ave_daily_new_cases)

                        if previous_week_ave_daily_new_cases > past_week_ave_daily_new_cases:
                            covid_new_cases_trend = 'decreasing'
                        if previous_week_ave_daily_new_cases < past_week_ave_daily_new_cases:
                            covid_new_cases_trend = 'increasing'
                        if previous_week_ave_daily_new_cases == past_week_ave_daily_new_cases:
                            covid_new_cases_trend = 'flat'      
                    
                        print('\tAverage daily new cases are ' + covid_new_cases_trend)

                except Exception as inst:
                    print("\tException processing COVID cases data.")
                    print(type(inst))    # the exception instance
                    print(inst.args)     # arguments stored in .args
                    print(inst)          # __str__ allows args to be printed directly,
                    e = sys.exc_info()[1]
                    print("\tlatest_date: " + str(latest_date))
                    print("\tseven_days_ago: " + str(seven_days_ago))
                    print("\tcases_latest_date: " + str(cases_latest_date))
                    print("\tcases_seven_days_ago: " + str(cases_seven_days_ago))
                    print("\tpast_week_ave_daily_new_cases: " + str(past_week_ave_daily_new_cases))
                    print(e.args[0])
                    #pdb.set_trace() 
                
                finally:
                    print("\tDone processing COVID cases data.")
                    #print("--- %s seconds ---" % round((time.time() - start_time)))
                    
                #2. MOBILITY DATA
                try:
                    #pull county mobility data
                    #print("getting county mobility data")
                    county_mobility_data = mobility_df.loc[mobility_df['census_fips_code'] == fips_code]
                    #print (county_mobility_data)
                    mobility_results_df = pandas.DataFrame()                  
                        
                    for destination in destination_list:
                        destination_short = destination.split('_')[0]

                        #set empty output values if county not found in covid cases files
                        if county_mobility_data.empty:
                            #print (str(fips_code) + " not found in mobility data")
                            latest_date_mob   = ""
                            seven_days_ago    = ""
                            fourteen_days_ago = ""
                            past_week_ave_mobility_change = ""
                            previous_week_ave_mobility_change = ""
                            mobility_trend = ""
                            
                        #otherwise, calculate trend
                        else:
                            latest_date_mob = county_mobility_data['date'].max()
                            seven_days_ago = latest_date_mob - datetime.timedelta(days=7)
                            fourteen_days_ago = latest_date_mob - datetime.timedelta(days=14)

                            #get mean current destination value for last week 
                            past_week_ave_mobility_change = county_mobility_data.loc[(county_mobility_data['date'] > seven_days_ago) & (county_mobility_data['date'] <= latest_date_mob), destination].mean()
                            #print("past_week_ave_mobility_change:" + str(past_week_ave_mobility_change))
                            if not(numpy.isnan(past_week_ave_mobility_change)):
                                past_week_ave_mobility_change = round(past_week_ave_mobility_change)

                            #get mean current destination value for second to last week 
                            previous_week_ave_mobility_change = county_mobility_data.loc[(county_mobility_data['date'] > fourteen_days_ago) & (county_mobility_data['date'] <= seven_days_ago), destination].mean()
                            if not(numpy.isnan(previous_week_ave_mobility_change)):
                                previous_week_ave_mobility_change = round(previous_week_ave_mobility_change)
                            
                            if abs(previous_week_ave_mobility_change - past_week_ave_mobility_change) <= 2:
                                mobility_trend = 'flat' 
                            if past_week_ave_mobility_change - previous_week_ave_mobility_change > 2:
                                mobility_trend = 'increasing'
                            if past_week_ave_mobility_change - previous_week_ave_mobility_change < -2:
                                mobility_trend = 'decreasing'
                       
                        #print('mobility around ' + destination_short + ' is ' + mobility_trend)
                        mobility_results_df = mobility_results_df.append({  'destination_type':destination_short,
                                                                        'mobility_trend':mobility_trend,
                                                                        'past_week_ave_mobility':past_week_ave_mobility_change,
                                                                        'previous_week_ave_mobility':previous_week_ave_mobility_change},
                                                                        ignore_index=True)
                        #print(mobility_results_df)
                            
                except Exception as inst:
                    print("\tException processing mobility data.")
                    print(type(inst))    # the exception instance
                    print(inst.args)     # arguments stored in .args
                    print(inst)          # __str__ allows args to be printed directly,
                    e = sys.exc_info()[1]
                    print(e.args[0])
                    
                finally:
                    print("\tDone processing mobility data.")
                    #print("--- %s seconds ---" % round((time.time() - start_time)))
                   
                    
                # write data to csv (this is ugly but too late at night to develop more elegant solution)
                try:
                    csvwriter.writerow([fips_code,
                    covid_new_cases_trend,
                    previous_week_ave_daily_new_cases_formatted,
                    previous_week_ave_daily_new_cases_formatted,
                    latest_date,                  
                    mobility_results_df[mobility_results_df['destination_type']=='retail']['mobility_trend'].iloc[0],
                    mobility_results_df[mobility_results_df['destination_type']=='retail']['past_week_ave_mobility'].iloc[0],
                    mobility_results_df[mobility_results_df['destination_type']=='retail']['previous_week_ave_mobility'].iloc[0],
                    mobility_results_df[mobility_results_df['destination_type']=='parks']['mobility_trend'].iloc[0],                                
                    mobility_results_df[mobility_results_df['destination_type']=='parks']['past_week_ave_mobility'].iloc[0],
                    mobility_results_df[mobility_results_df['destination_type']=='parks']['previous_week_ave_mobility'].iloc[0],
                    mobility_results_df[mobility_results_df['destination_type']=='transit']['mobility_trend'].iloc[0],                                
                    mobility_results_df[mobility_results_df['destination_type']=='transit']['past_week_ave_mobility'].iloc[0],
                    mobility_results_df[mobility_results_df['destination_type']=='transit']['previous_week_ave_mobility'].iloc[0],
                    mobility_results_df[mobility_results_df['destination_type']=='workplaces']['mobility_trend'].iloc[0],                                
                    mobility_results_df[mobility_results_df['destination_type']=='workplaces']['past_week_ave_mobility'].iloc[0],
                    mobility_results_df[mobility_results_df['destination_type']=='workplaces']['previous_week_ave_mobility'].iloc[0],
                    mobility_results_df[mobility_results_df['destination_type']=='residential']['mobility_trend'].iloc[0],                                
                    mobility_results_df[mobility_results_df['destination_type']=='residential']['past_week_ave_mobility'].iloc[0],
                    mobility_results_df[mobility_results_df['destination_type']=='residential']['previous_week_ave_mobility'].iloc[0],
                    latest_date_mob])

                except Exception as inst:
                    print("Exception writing csv.")
                    print(type(inst))    # the exception instance
                    print(inst.args)     # arguments stored in .args
                    print(inst)          # __str__ allows args to be printed directly,
                    e = sys.exc_info()[1]
                    print(e.args[0])
                    #pdb.set_trace()
                    
                finally:
                    print("Done writing to csv.")
                    #print("--- %s seconds ---" % round((time.time() - start_time)))

def main(): 
    print("Starting process: Process NYT covid trends and Google Mobility Report data.") 
    start_time = time.time()
    print("Started on " + time.ctime(start_time) + ".")
    print("ArcGIS Python API version " + arcgis.__version__)    
    
    try:
        #get latest Google Mobility Report
        download_latest_mobility_report()
        #get latest NYT US counties COVID-19 cases file
        download_latest_nyt_counties_cases_file()

        counties_fc = r"D:\Users\climate_dashboard\Documents\climate_dashboard\data\input_files\conus_counties_simplified.shp"
        geoids = []
        print("reading list of county GEOIDs from " + counties_fc)
        cursor = arcpy.da.SearchCursor(counties_fc, ['GEOID'])
        for row in cursor:
            geoids.append(row[0])
        print("done")

   
        id_counties_with_inc_new_cases(geoids[1:40],
                                      ['retail_and_recreation_percent_change_from_baseline',
                                       'parks_percent_change_from_baseline',
                                       'transit_stations_percent_change_from_baseline',
                                       'workplaces_percent_change_from_baseline',
                                       'residential_percent_change_from_baseline'])
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
