#! /usr/bin/env python3


"""
COMP3311
24T1
Assignment 2
Pokemon Database

Written by: <Yuet Yat (Xerox) Chan> <z5289835>
Written on: <21/04/2024>

File Name: Q5

Description: Print a formatted (recursive) evolution chain for a given pokemon
"""


import sys
import psycopg2
import helpers


### Helper functions
def get_requirements(cursor, evolution_id):
    cursor.execute(f"""
        SELECT r.assertion, er.inverted
        FROM evolution_requirements er
        JOIN requirements r ON er.requirement = r.id
        WHERE er.evolution = {evolution_id}
        ORDER BY r.id, er.inverted DESC;
    """)
    requirements = cursor.fetchall()
    if not requirements:
        return "None"

    formatted_reqs = []
    for assertion, inverted in requirements:
        condition = "NOT " + assertion if inverted else assertion
        formatted_reqs.append(condition)

    return " AND ".join(formatted_reqs)


def explore_chain(cursor, pokemon_id, explored=None):
    if explored is None:
        explored = set()
        
    if pokemon_id in explored:
        return [], explored
    explored.add(pokemon_id)
    
    cursor.execute(f"SELECT name FROM pokemon WHERE id = {pokemon_id}")
    pokemon_name = cursor.fetchone()[0]



    chain = []
    
    # Fetch pre-evolutions
    cursor.execute(f"""
        SELECT p.id, p.name, e.id
        FROM evolutions e
        JOIN pokemon p ON e.pre_evolution = p.id
        WHERE e.post_evolution = {pokemon_id}
    """)
    pre_evolutions = cursor.fetchall()

    for pre_id, pre_name, evo_id in pre_evolutions:
        if evo_id not in explored:
            explored.add(evo_id)
            sub_pre_chain, explored = explore_chain(cursor, pre_id, explored)
            chain.extend(sub_pre_chain)
            requirements = get_requirements(cursor, evo_id)
            chain.append(f"'{pre_name}' can evolve into '{pokemon_name}' when the following requirements are satisfied:\n        {requirements}")

    # Fetch post-evolutions
    cursor.execute(f"""
        SELECT p.id, p.name, e.id
        FROM evolutions e
        JOIN pokemon p ON e.post_evolution = p.id
        WHERE e.pre_evolution = {pokemon_id}
    """)
    post_evolutions = cursor.fetchall()

    for post_id, post_name, evo_id in post_evolutions:
        if evo_id not in explored:
            explored.add(evo_id)
            requirements = get_requirements(cursor, evo_id)
            chain.append(f"'{pokemon_name}' can evolve into '{post_name}' when the following requirements are satisfied:\n        {requirements}")
            sub_post_chain, explored = explore_chain(cursor, post_id, explored)
            chain.extend(sub_post_chain)

    if not pre_evolutions:
        chain.insert(0, f"'{pokemon_name}' doesn't have any pre-evolutions.")
    if not post_evolutions:
        chain.append(f"'{pokemon_name}' doesn't have any post-evolutions.")

    return chain, explored


### Constants
USAGE = f"Usage: {sys.argv[0]} <pokemon_name>"

def main(db):
    if len(sys.argv) != 2:
        print(USAGE)
        return 1
    # TODO: your code here
    pokemon_name = sys.argv[1]
    cursor = db.cursor()
    
    cursor.execute(f"SELECT id FROM pokemon WHERE name = '{pokemon_name}'")
    #check if pokemon exist
    result = cursor.fetchone()
    if not result:
        print(f"'{pokemon_name}' is not found in the database.")
        exit(1)
    
    pokemon_id = result[0]
    explored = set()
    chain, _ = explore_chain(cursor, pokemon_id, explored)
    for link in chain:
        print(link)
        print()
    
    

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
