
import arcpy
import os
import time
from arcpy import env
from arcpy.sa import *
import arcpy.ia
import zipfile
import fnmatch
import sys


try:
	os.system("taskkill /F /IM ArcGISPro.exe")

except Exception as inst:
	print(type(inst))    # the exception instance
	print(inst.args)     # arguments stored in .args
	print(inst)          # __str__ allows args to be printed directly,
	e = sys.exc_info()[1]
	print(e.args[0])
finally:
	print("Done.")
	#print("--- %s seconds ---" % round((time.time() - start_time)))