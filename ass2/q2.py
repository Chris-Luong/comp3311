# COMP3311 22T1 Ass2 ... print info about different releases for Movie
# Christopher Luong April 2022

import sys
import psycopg2

# define any local helper functions here

def findAliases(tuple):
	"""
	If only 1 movie is returned, list out its aliases
	with some extra information.

	Cases:
	- Region and language
	- Region
	- Language, no region
	- Extra info, no region or language
	- Just the alias (no region, language or extra info)
	"""
	# Get rid of leading and trailing spaces
	region = str(tuple[1]).strip()
	language = str(tuple[2]).strip()
	extra_info = str(tuple[3]).strip()

	if tuple[1] is not None and tuple[2] is not None:
		print(f"'{tuple[0]}' (region: {region}, language: {language})")
	elif tuple[1] is not None:
		print(f"'{tuple[0]}' (region: {region})")
	elif tuple[2] is not None:
		print(f"'{tuple[0]}' (language: {language})")
	elif tuple[3] is not None:
		print(f"'{tuple[0]}' ({extra_info})")
	else:
		print(f"'{tuple[0]}'")

# set up some globals

usage = "Usage: q2.py 'PartialMovieTitle'"
db = None

searchQuery = """
	select m.rating, m.title, m.start_year, m.id
	from movies m
	where title ~* '%s'
	order by rating desc, start_year, title;
"""

aliasQuery = """
	select a.local_title, a.region, a.language, a.extra_info
	from movies m join aliases a on a.movie_id = m.id
	where m.id = %s
	order by a.ordering;
"""

# process command-line args


argc = len(sys.argv)
if argc == 2:
	searchPhrase = str(sys.argv[1]).replace("'", "''")
else:
	print(usage)
	exit()

# manipulate database

try:
	db = psycopg2.connect("dbname=imdb")
	cur = db.cursor()
	cur.execute(searchQuery % searchPhrase)
	if cur.rowcount < 1: # Empty list
		print(f"No movie matching '{searchPhrase}'")
		exit()
	elif cur.rowcount == 1: # Find aliases
		rating, title, year, id = cur.fetchone()
		cur.execute(aliasQuery % id)

		if cur.rowcount < 1:
			print(f"{title} ({year}) has no alternative releases")
			exit()
		print(f"{title} ({year}) was also released as")
		for tuple in cur.fetchall():
			findAliases(tuple)
		exit()

	print(f"Movies matching '{searchPhrase}'")
	print("===============")
	
	for tuple in cur.fetchall():
		rating, title, year, id = tuple
		print(f"{rating} {title} ({year})")
except psycopg2.Error as err:
	print("DB error: ", err)
finally:
	if db:
		cur.close()
		db.close()
