# COMP3311 22T1 Ass2 ... print info about cast and crew for Movie

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

usage = "Usage: q3.py 'MovieTitlePattern' [Year]"
db = None

# process command-line args

argc = len(sys.argv)
if argc != 2 and argc != 3:
	print(usage)
	exit(0)
title = sys.argv[1]
year = None
if argc == 3:
	year = sys.argv[2]

	if not year.isnumeric():
		print(usage)
		exit(0)

	

# manipulate database

try:
	db = psycopg2.connect("dbname=imdb")
	# ... add your code here ...
	cur = db.cursor()


	partitle = '[.]*' + title + '[.]*'

	if year is None:
		cur.execute(
			"""
			select m.title, m.start_year, a.local_title,  a.region, a.language,a.extra_info, m.id from movies as m
			left join Aliases as a on a.movie_id = m.id
			where m.title ~* %s order by a.ordering
			""",
			[partitle,]
		)
	else:
		cur.execute(
			"""
			select m.title, m.start_year, a.local_title,  a.region, a.language,a.extra_info, m.id from movies as m
			left join Aliases as a on a.movie_id = m.id
			where  m.title ~* %s and m.start_year = %s order by a.ordering
			""",
			[partitle, year]

		)

	selected_movies = cur.fetchall()

	if len(selected_movies) == 0:
		if year is not None:
			print("No movie matching '{}' {}".format(title, year))
		else:
			print("No movie matching '{}'".format(title, ))

		exit(0)

	elif q2_if_single_movie(selected_movies) :
		# print out all the info 
		movie_id = selected_movies[0][-1]

		print('{} ({})\n==============='.format(
			selected_movies[0][0], 
			selected_movies[0][1]
		))
		
		# find all the actors 
		cur.execute(
			"""
			select n.name, r.played from Acting_roles r 
			join Names n on n.id = r.name_id
			left join Principals p on n.id = p.name_id and r.movie_id = p.movie_id
			where r.movie_id = %s
			order by p.ordering, r.played
			""",
			[movie_id]
		)
		actors = cur.fetchall() 


		
		print('Starring')
		for a in actors:
			print(' {} as {}'.format(a[0], a[1]))

		print('and with')
		cur.execute(
			"""
			select n.name, c.role from Crew_roles c 
			join Names n on n.id = c.name_id 
			left join Principals p on n.id = p.name_id  and c.movie_id = p.movie_id
			where c.movie_id = %s
			order by p.ordering , c.role
			""",
			[movie_id]
		)
		crews = cur.fetchall()
		for c in crews:
			print(' {}: {}'.format(c[0], c[1].capitalize()) )






	
	else:
		if year is None:
			cur.execute(
				"""
				select m.rating ,m.title, m.start_year from movies as m
				where m.title ~* %s order by m.rating desc,m.start_year, m.title
				""",
				[partitle,]
			)
		
		else:

			cur.execute(
				"""
				select m.rating ,m.title, m.start_year from movies as m
				where m.title ~* %s and m.start_year = %s order by m.rating desc,m.start_year, m.title
				""",
				[partitle, year]
			)
		candidates =cur.fetchall()
		
		if year is not None:
			print("Movies matching '{}' {}\n===============".format(title, year))
		else:
			print("Movies matching '{}'\n===============".format(title))
		for c in candidates:
			print("{} {} ({})".format(
				c[0], c[1], c[2]
			))




except psycopg2.Error as err:
	print("DB error: ", err)
finally:
	if db:
		db.close()
