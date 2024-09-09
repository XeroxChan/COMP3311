#! /usr/bin/env python3


"""
COMP3311
24T1
Assignment 2
Pokemon Database

Written by: <Yuet Yat (Xerox) Chan> <z5289835>
Written on: <20/04/2024>

File Name: Q1.py

Description: List the number of pokemon and the number of locations in each game
"""


import sys
import psycopg2
import helpers


### Constants
USAGE = f"Usage: {sys.argv[0]}"

def main(db):
    if len(sys.argv) != 1:
        print(USAGE)
        return 1

    # TODO: your code here
    #cursor
    cur = db.cursor()
    #obtain data from helper view
    qry = """
    select * from numbers_of_pl
    """
    #execute query
    cur.execute(qry)
    #formatted header
    print(f"{'Region':<6} {'Game':<17} {'#Pokemon':<8} {'#Locations'}")
    #get the result from the helper view and print according to format
    for tup in cur.fetchall():
        #assign variables from column
    	RegionName, GameName, Pokemon, Locations = tup
    	print(f"{RegionName:<6} {GameName:<17} {Pokemon:<8} {Locations}")
    
if __name__ == '__main__':
    exit_code = 0
    db = None
    try:
        db = psycopg2.connect(dbname="pkmon")
        exit_code = main(db)
    except psycopg2.Error as err:
        print("DB error: ", err)
        exit_code = 1
    except Exception as err:
        print("Internal Error: ", err)
        raise err
    finally:
        if db is not None:
            db.close()
    sys.exit(exit_code)
