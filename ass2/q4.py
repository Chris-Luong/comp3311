# COMP3311 22T1 Ass2 ... get Name's biography/filmography
# Christopher Luong April 2022

import sys
import psycopg2

# define any local helper functions here

# set up some globals

usage = "Usage: q4.py 'NamePattern' [Year]"
db = None

searchQueryNoYear = """
    select distinct n.id, n.name, n.birth_year, n.death_year
    from names n
    where n.name ~* '%s'
    group by n.id, name, birth_year, death_year
    order by name, birth_year, n.id;
"""

searchQueryWithYear = """
    select distinct n.id, n.name, n.birth_year, n.death_year
    from names n
    where n.name ~* '%s' and n.birth_year = %s
    group by n.id, name, birth_year, death_year
    order by name, birth_year, n.id;
"""

personalRatingQuery= """
	with temp as 
	(select distinct m.rating
	from movies m join principals p on p.movie_id = m.id
	join names n on n.id = p.name_id
	where n.id = %s)
	select round(cast(avg(rating) as decimal),1) from temp;
""" # get the id not the name for personal rating thing OR LOOP THRU FETCHALL AND GET AVG

def doFunction():
	print("dfsd")
	# Make dictionary of genres as key and count as values?

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
			print(f"No name matching '{data[0]}' {data[1]}")
		else:
			print(f"No name matching '{searchPhrase}'")
	elif cur.rowcount > 1:
		if hasYear:
			print(f"Names matching '{data[0]}' {data[1]}")
		else:
			print(f"Names matching '{searchPhrase}'")
		print("===============")
		for tuple in cur.fetchall():
			id, name, birthYear, deathYear = tuple
			if birthYear == None:
				print(f"{name} (???)")
			elif deathYear == None:
				print(f"{name} ({birthYear}-)")
			else:
				print(f"{name} ({birthYear}-{deathYear})")
	else:
		id, name, birthYear, deathYear = cur.fetchone()
		if birthYear == None:
			print(f"{name} (???)")
		elif deathYear == None:
			print(f"{name} ({birthYear}-)")
		else:
			print(f"{name} ({birthYear}-{deathYear})")
		# do function thiung
except psycopg2.Error as err:
	print("DB error: ", err)
finally:
	if db:
		cur.close()
		db.close()

