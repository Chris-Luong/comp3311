# COMP3311 22T1 Ass2 ... get Name's biography/filmography
# Christopher Luong April 2022

import sys
import psycopg2

# define any local helper functions here

def getRatingAndGenres(result):
	"""
	For genres etc. param is the res of fetchall
	Loop through to get top genres, skipping duplicates.
	For doing avg, since there are duplicates, have var current movie to check if the same as
    the one you are indexed at. If same, do not add avg calc. Else add to avg calc.
	For genre, array[3], check if current genre is same as any in array. If not,
	compare count and insert accordingly.
	"""
	print("===============")
	# genres = [None] * 3
	# genreCounts = [None] * 3
	genres = {}
	topThree = {}
	avgRating = 0
	numElements = 1
	currentMovie = ""

	for tuple in result:
		rating, title, genre, cnt = tuple
		
		createGenreDict(genres, genre, cnt)
		
		if currentMovie == title:
			continue
		currentMovie = title
		avgRating += rating
		numElements += 1
	
	numElements -= 1
	avgRating = avgRating / numElements
	topThree = sorted(genres, key=genres.get, reverse=True)[:3]
	
	print("Personal Rating: {:.1f}".format(avgRating))
	print("Top 3 Genres:")
	for genre in topThree:
		print(f" {genre}")

	# Make dictionary of genres as key and count as values?

def createGenreDict(genres, curGenre, cnt):
	for genre in genres:
		if genre == curGenre:
			return
	genres[curGenre] = cnt

def getMoviesAndRoles(result):
	"""
	Assumes actor only plays one character and possibly multiple crew roles
	"""
	print("===============")
	roles = []
	character = ""
	curMovie = None
	for tuple in result:
		title, year, played, role, id = tuple
		
		if curMovie == None:
			curMovie = title
			character = played
			createRolesList(roles, role)
		elif curMovie != title:
			printMovieDetails(curMovie, year, character, roles)
			curMovie = title
			character = played
			roles = []
			createRolesList(roles, role)
		else: # curMovie == title
			createRolesList(roles, role)

def createRolesList(roles, role):
	if role is not None:
		roles.append(role.capitalize().replace(' ', '_'))

def printMovieDetails(title, year, played, roles):
	print(f"{title} ({year})")
	if played is not None:
		print(f" playing {played}")
	for role in roles:
		print(f" as {role}")

def printError(usage):
	print(usage)
	exit()

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

genreRatingQuery= """
    with temp as
    (select distinct m.rating, m.title, g.genre
    from movies m join principals p on p.movie_id = m.id
    join movie_genres g on g.movie_id = m.id 
    where p.name_id = %s)
    select t.rating, t.title, t.genre, c.cnt
    from temp t
    join (
        select genre, count(genre) as cnt
        from temp
        group by genre
    ) c on c.genre = t.genre
    order by t.title;
"""

movieActorCrewQuery = """
    select distinct m.title, m.start_year, a.played, c.role, n.id
    from principals p join names n on n.id = p.name_id
    join movies m on p.movie_id = m.id
    full outer join acting_roles a on m.id = a.movie_id and a.name_id = p.name_id
    full outer join crew_roles c on m.id = c.movie_id and c.name_id = p.name_id
    where n.id = %s
    order by start_year;
"""

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
			print(f"Filmography for {name} (???)")
		elif deathYear == None:
			print(f"Filmography for {name} ({birthYear}-)")
		else:
			print(f"Filmography for {name} ({birthYear}-{deathYear})")
		cur.execute(genreRatingQuery % id)
		res1 = cur.fetchall()
		getRatingAndGenres(res1)
		cur.execute(movieActorCrewQuery % id)
		res2 = cur.fetchall()
		getMoviesAndRoles(res2)
except psycopg2.Error as err:
	print("DB error: ", err)
finally:
	if db:
		cur.close()
		db.close()
