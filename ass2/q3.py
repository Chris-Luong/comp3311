# COMP3311 22T1 Ass2 ... print info about cast and crew for Movie
# Christopher Luong April 2022

import sys
import psycopg2

# define any local helper functions here

# set up some globals

usage = "Usage: q3.py 'MovieTitlePattern' [Year]"
db = None

searchQueryNoYear = """
	select m.rating, m.title, m.start_year, m.id
	from movies m
	where title ~* '%s'
	order by rating desc, start_year, title;
"""

searchQueryWithYear = """
	select m.rating, m.title, m.start_year, m.id
	from movies m
	where title ~* '%s' and m.start_year = %s
	order by rating desc, start_year, title;
"""

actorQuery = """
	select distinct p.ordering, n.name, a.played, m.id
	from principals p join names n on n.id = p.name_id
	join movies m on p.movie_id = m.id
	join acting_roles a on m.id = a.movie_id and a.name_id = p.name_id
	where m.id = %s
	order by p.ordering, a.played;
"""

crewQuery = """
	select distinct p.ordering, n.name, c.role, m.id
	from principals p join names n on n.id = p.name_id
	join movies m on p.movie_id = m.id
	join crew_roles c on m.id = c.movie_id and c.name_id = p.name_id
	where m.id = %s
	order by p.ordering, c.role;
"""

def listDetails(movie_id):
	"""
	List details of principal actors and crews.
	Capitalse first letter of crew roles and replace underscore
	with space.
	"""
	print("Starring")
	cur.execute(actorQuery % movie_id)
	for tuple in cur.fetchall():
		ordering, actor, played, id = tuple
		print(f" {actor} as {played}")
	print("and with")
	cur.execute(crewQuery % movie_id)
	for tuple in cur.fetchall():
		ordering, name, role, id = tuple
		print(f" {name}: {role.capitalize().replace(' ', '_')}")

def printError(usage):
	print(usage)
	exit()

# process command-line args

argc = len(sys.argv)
hasYear = False
if argc == 2:
	searchPhrase = str(sys.argv[1]).replace("'", "''")
elif argc == 3:
	try:
		data = (str(sys.argv[1]).replace("'", "''"), int(sys.argv[2]))
		hasYear = True
	except:
		printError(usage)
else:
	printError(usage)

# manipulate database

try:
	db = psycopg2.connect("dbname=imdb")
	cur = db.cursor()
	if hasYear:
		cur.execute(searchQueryWithYear % data)
	else:
		cur.execute(searchQueryNoYear % searchPhrase)
	if cur.rowcount < 1:
		if hasYear:
			print(f"No movie matching '{data[0]}' {data[1]}")
		else:
			print(f"No movie matching '{searchPhrase}'")
		exit()
	elif cur.rowcount > 1: # Print matching movies if there's more than 1 result
		if hasYear:
			print(f"Movies matching '{data[0]}' {data[1]}")
		else:
			print(f"Movies matching '{searchPhrase}'")
		print("===============")
		for tuple in cur.fetchall():
			rating, title, year, id = tuple
			print(f"{rating} {title} ({year})")
	else:
		rating, title, year, id = cur.fetchone()
		print(f"{title} ({year})")
		print("===============")
		listDetails(id)
except psycopg2.Error as err:
	print("DB error: ", err)
finally:
	if db:
		cur.close()
		db.close()
