#! /usr/bin/env python3

# COMP3311 23T1 Final Exam
# Q5: Print details of accounts at a named branch

import sys
import psycopg2

### Constants
USAGE = f"Usage: {sys.argv[0]} <branch name>"

### Globals
db = None

### Queries

### replace this line with any query templates ###

### Command-line args
if len(sys.argv) != 2:
    print(USAGE, file=sys.stderr)
    sys.exit(1)
suburb = sys.argv[1]


try:
    ### replace this line with your Python code ###

except psycopg2.Error as err:
    print("DB error: ", err)
except Exception as err:
    print("Internal Error: ", err)
    raise err
finally:
    if db is not None:
        db.close()
sys.exit(0)

### replace this line by any helper functions ###
