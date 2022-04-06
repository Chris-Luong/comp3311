# COMP3311 22T1 Ass2 ... print info about cast and crew for Movie

import sys
import psycopg2

# define any local helper functions here

# set up some globals

usage = "Usage: q3.py 'MovieTitlePattern' [Year]"
db = None

# process command-line args

argc = len(sys.argv)

# manipulate database

try:
	db = psycopg2.connect("dbname=imdb")
	# ... add your code here ...
except psycopg2.Error as err:
	print("DB error: ", err)
finally:
	if db:
		db.close()
