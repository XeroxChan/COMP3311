#! /usr/bin/env python3
# COMP3311 23T1 Final Exam
# Print details of accounts at a named branch

import sys
import psycopg2

### Constants
USAGE = f"Usage: {sys.argv[0]} <branch name>"

### Globals
db = None
Seed = None
rng = None

### Queries

getBranch = "select id,assets from Branches where location = %s"
getAccounts = '''
select c.id,  c.given||' '||c.family as name, c.lives_in, a.id, a.balance
from   Accounts a 
       join Held_by h on h.account = a.id
       join Customers c on h.customer = c.id
where  a.held_at = %s
order  by a.id
'''

### Command-line args
if len(sys.argv) != 2:
	print(USAGE, file=sys.stderr)
	sys.exit(1)
suburb = sys.argv[1]


try:
	db = psycopg2.connect(dbname="bank")

	### your code goes here ###

	cur = db.cursor()
	cur.execute(getBranch, [suburb])
	b = cur.fetchone()
	if b is None:
		print(f"No such branch {suburb}")
		sys.exit(1)
	bid,assets = b
	print(f"{suburb} branch ({bid}) holds")

	total = 0
	cur.execute(getAccounts, [bid])
	for t in cur.fetchall():
		cid,cname,cburb,aid,balance = t
		total += balance
		print(f"- account {aid} owned by {cname} from {cburb} with ${balance}")

	print(f"Assets: ${assets}")
	if total != assets:
		print(f"Discrepancy between assets and sum of account balances")

except psycopg2.Error as err:
	print("DB error: ", err)
except Exception as err:
	print("Internal Error: ", err)
	raise err
finally:
	if db is not None:
		db.close()
sys.exit(0)


# Put helper functions here
