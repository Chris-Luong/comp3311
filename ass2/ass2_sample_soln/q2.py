# COMP3311 22T1 Ass2 ... print info about different releases for Movie

import sys
import psycopg2

def q2_if_single_movie(movies):
    # assume the last element is movie id 
    id = movies[0][-1]
    for movie in movies:
        if movie[-1] != id :
            return False

    return True        


def q2_get_alter_info(title, region, language, extra_info):
    title = "'"+ title +"'"
    if region is None and language is None:
        if extra_info is None:
            return title
        else:
            return title  + ' (' + extra_info +')'
    
    result = title + ' ('
    if region is not None:
        result += 'region: '+ region.strip() 
    
    if language is not None:
        if len(result) > len(title)+1:
            result += ', '
        result += 'language: ' + language.strip()
    
    result += ')'
    return result

# define any local helper functions here

# set up some globals

usage = "Usage: q2.py 'PartialMovieTitle'"
db = None

# process command-line args

argc = len(sys.argv)
if argc != 2:
	print(usage)
	exit(0)

partitle = sys.argv[1]
# manipulate database

try:
	db = psycopg2.connect("dbname=imdb")
	# ... add your code here ...
	cur= db.cursor()

	# try exact match 
	cur.execute(
		"""
		select m.title, m.start_year, a.local_title,  a.region, a.language,a.extra_info, m.id from movies as m
		left join Aliases as a on a.movie_id = m.id
		where lower(m.title) like %s order by a.ordering
		""",
		['%' + partitle.lower() + '%',]
	)

	selected_movies = cur.fetchall()

	if len(selected_movies) == 0:
		print("No movie matching '{}'".format(partitle))
		exit(0)

	elif q2_if_single_movie(selected_movies) :
		if len(selected_movies) == 1 and selected_movies[0][2] == None:
			print('{} ({}) has no alternative releases'.format(
				selected_movies[0][0],
				selected_movies[0][1]
			))
			exit(0)


		print('{} ({}) was also released as'.format(
			selected_movies[0][0],
			selected_movies[0][1]
		))
		for m in selected_movies:
			release_info = q2_get_alter_info(m[2],m[3],m[4],m[5], )
			print(release_info)
	
	else:
		cur.execute(
			"""
			select m.rating ,m.title, m.start_year from movies as m
			where lower(m.title) like %s order by m.rating desc,m.start_year, m.title
			""",
			['%' + partitle.lower() + '%']
		)
		candidates =cur.fetchall()
		
		print("Movies matching '{}'\n===============".format(partitle))
		for c in candidates:
			print("{} {} ({})".format(
				c[0], c[1], c[2]
			))


except psycopg2.Error as err:
	print("DB error: ", err)
finally:
	if db:
		db.close()
