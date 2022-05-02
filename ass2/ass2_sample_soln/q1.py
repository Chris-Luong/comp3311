# COMP3311 22T1 Ass2 ... print num_of_movies, name of top N people with most movie directed

import sys
import psycopg2

# define any local helper functions here

# set up some globals

usage = "Usage: q1.py [N]"



# process command-line args
argc = len(sys.argv)

if (argc == 1):
	n = 10
elif argc == 2 and sys.argv[1].isdigit() and int(sys.argv[1]) > 0:
	n = int(sys.argv[1])
else:
	print(usage)
	exit(1)

# manipulate database

try:
	db = psycopg2.connect("dbname=imdb")
	cur = db.cursor()
	query = '''
	SELECT count(*), names.name
	FROM crew_roles INNER JOIN names ON crew_roles.name_id = names.id
	WHERE role = 'director' 
	GROUP BY names.id 
	ORDER BY count(*) DESC,
	names.name ASC
	limit %s;
	'''
	cur.execute(query, [n])
	for rec in cur.fetchall():
		print(rec[0],rec[1])
except psycopg2.Error as err:
	print("DB error: ", err)
finally:
	if db:
		db.close()
