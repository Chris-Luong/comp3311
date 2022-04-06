# COMP3311 22T1 Ass2 ... get Name's biography/filmography

import sys
import psycopg2

# define any local helper functions here

# set up some globals

usage = "Usage: q4.py 'NamePattern' [Year]"
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

