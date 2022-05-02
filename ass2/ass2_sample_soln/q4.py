# COMP3311 22T1 Ass2 ... get Name's biography/filmography

import sys
import psycopg2

# define any local helper functions here

def name_to_str(id, name, birth_year, death_year):
	if birth_year is None:
		return f'{name} (???)'
	elif death_year is None:
		return f'{name} ({birth_year}-)'
	else:
		return f'{name} ({birth_year}-{death_year})'

def print_name_detail(id: int, name: str, cur):
	cur.execute(f'select * from personal_rate({id})')
	rate = cur.fetchone()
	rate = 0 if rate[0] is None else rate[0]
	
	print(f'Personal Rating: {rate}')
	print('Top 3 Genres:')

	cur.execute(f'select * from get_top3({id})')
	top3 = cur.fetchall()
	if top3 is not None:
		for r in top3:
			print(f" {r[0]}")
	print('===============')

	cur.execute(f'''
		select m.id, m.title, m.start_year
		from principals p
		join movies m on p.movie_id = m.id
		where p.name_id = {id}
		order by m.start_year, title
		''')
	all_mids = cur.fetchall()
	for mid, title, start_year in all_mids:
		print(f'{title} ({start_year})')
		cur.execute(f'''
			select played
			from acting_roles
			where name_id = {id} and movie_id = {mid}
			order by played
			''')
		for (playing,) in cur.fetchall():
			print(f' playing {playing}')

		cur.execute(f'''
			select role
			from crew_roles
			where name_id = {id} and movie_id = {mid}
			order by role
			''')
		for (role,) in cur.fetchall():
			role_str = role.replace('_', ' ').capitalize()
			print(f' as {role_str}')


def search_by_name(name: str, cur):
	sql = f'''
		select * from Names
		where name ilike '%{name}%'
		order by name asc, birth_year asc, id asc
		'''
	cur.execute(sql)
	results = cur.fetchall()

	if len(results) == 0:
		print('No name matching %r' % name)
	elif len(results) == 1:
		print(f"Filmography for {name_to_str(*results[0])}")
		print("===============")
		id, name = results[0][:2]
		print_name_detail(id, name, cur)
	elif len(results) > 1:	
		print(f"Names matching '{name}'")
		print("===============")
		for r in results:
			print(name_to_str(*r))


def search_by_name_year(name: str, year: int, cur):
	sql = f'''
		select * from Names
		where name ilike '%{name}%' and birth_year = {year}
		order by name asc, birth_year asc, id asc
		'''
	cur.execute(sql)
	
	results = cur.fetchall()
	if len(results) == 0:
		print('No name matching %r %d' % (name, year))
	elif len(results) == 1:
		print(f"Filmography for {name_to_str(*results[0])}")
		print("===============")
		id, name = results[0][:2]
		print_name_detail(id, name, cur)

# set up some globals

usage = "Usage: q4.py 'NamePattern' [Year]"
db = None

# process command-line args

argc = len(sys.argv)

name = ''
year = None
exit_flag = False

if argc == 1 or argc > 3:
	exit_flag = True
elif argc == 2:
	name = sys.argv[1]
elif argc == 3:
	name = sys.argv[1]
	try:
		year = int(sys.argv[2])
	except:
		exit_flag = True

if exit_flag:
	print(usage)
	exit(0)

# manipulate database

try:
	db = psycopg2.connect("dbname=imdb")
	cur = db.cursor()
	if year is None:
		search_by_name(name, cur)
	else:
		search_by_name_year(name, year, cur)
except psycopg2.Error as err:
	print("DB error: ", err)
finally:
	if db:
		db.close()

