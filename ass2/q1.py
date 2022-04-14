# COMP3311 22T1 Ass2 ... print num_of_movies, name of top N people with most movie directed
# Christopher Luong April 2022

import sys
import psycopg2

# define any local helper functions here

# set up some globals

usage = "Usage: q1.py [N]"
db = None

query = """
	select count(name) as count, name
	from names n join crew_roles c on n.id = c.name_id
	where c.role = 'director'
	group by name
	order by count desc, name;
"""

def printError(usage):
	print(usage)
	exit()

# process command-line args


argc = len(sys.argv)

if argc > 2: # Too many args
	printError(usage)

if argc == 1: # filename is only argument
	num = 10
else:
	try:
		num = int(sys.argv[1])
	except:
		printError(usage) # arg is not a number

if num < 1:
	printError(usage)

# manipulate database

try:
	db = psycopg2.connect("dbname=imdb")
	cur = db.cursor()
	cur.execute(query)
	for tuple in cur.fetchmany(num):
		numFilms, name = tuple
		print(f"{numFilms} {name}")	
except psycopg2.Error as err:
	print("DB error: ", err)
finally:
	if cur:
		cur.close()
		db.close()
