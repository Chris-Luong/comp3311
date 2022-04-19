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
	if not result:
		print("Personal Rating: 0")
		print("Top 3 Genres:")
		return False
	
	genres = {}
	topThreeMaybe = {}
	avgRating = 0
	numElements = 0
	currentMovie = ""

	for tuple in result:
		rating, title, genre, cnt = tuple
		
		createGenreDict(genres, genre, cnt)
		
		if currentMovie == title:
			continue
		currentMovie = title
		avgRating += rating
		numElements += 1
	sortedGenres = sorted(genres.keys())
	avgRating = avgRating / numElements
	# Maybe since there could be less than 3
	topThreeMaybe = sorted(sortedGenres, key=genres.get, reverse=True)[:3]
	
	print(f"Personal Rating: {avgRating:.1f}")
	print("Top 3 Genres:")
	for genre in topThreeMaybe:
		print(f" {genre}")
	return True

def createGenreDict(genres, curGenre, cnt):
	for genre in genres:
		if genre == curGenre:
			return
	genres[curGenre] = cnt

def getMoviesAndRoles(result, hasMovies):
	print("===============")
	if not hasMovies:
		return

	roles = []
	characters = []
	curMovie = None
	curYear = None

	for tuple in result:
		title, year, played, role, id = tuple
		
		if curMovie == None:
			curMovie = title # 	NEED TO PRINT THE LAST MOVIE COS RN ITS PRINTING THE ONE BEFORE
			curYear = year
			createRolesList(roles, role, characters, played)
		elif curMovie != title:
			printMovieDetails(curMovie, curYear, characters, roles)
			curMovie = title
			curYear = year
			characters = []
			roles = []
			createRolesList(roles, role, characters, played)
		else: # curMovie == title
			createRolesList(roles, role, characters, played)
	
	printMovieDetails(curMovie, curYear, characters, roles)

def createRolesList(roles, role, characters, played):
	canAppend = True
	if role is not None:
		roles.append(role)
	if played is not None:
		if not characters:
			characters.append(played)
	else:
		return
	for character in characters:
		if played == character:
			canAppend = False
			break
	if canAppend:
		characters.append(played)

def printMovieDetails(title, year, characters, roles):
	print(f"{title} ({year})")
	for character in characters:
		print(f" playing {character}")
	for role in roles:
		print(f" as {role.capitalize().replace('_', ' ')}")

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
		hasMovies = True
		hasMovies = getRatingAndGenres(res1)
		cur.execute(movieActorCrewQuery % id)
		res2 = cur.fetchall()
		getMoviesAndRoles(res2, hasMovies)
except psycopg2.Error as err:
	print("DB error: ", err)
finally:
	if db:
		cur.close()
		db.close()
