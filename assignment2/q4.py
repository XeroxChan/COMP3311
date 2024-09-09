#! /usr/bin/env python3


"""
COMP3311
24T1
Assignment 2
Pokemon Database

Written by: <Yuet Yat (Xerox) Chan> <z5289835>
Written on: <21/04/2024>

File Name: Q4

Description: Print the best move a given pokemon can use against a given type in a given game for each level from 1 to 100
"""


import sys
import psycopg2
import helpers
import math

### Constants
USAGE = f"Usage: {sys.argv[0]} <Game> <Attacking Pokemon> <Defending Pokemon>"


def main(db):
    ### Command-line args
    if len(sys.argv) != 4:
        print(USAGE)
        return 1
    game_name = sys.argv[1]
    attacking_pokemon_name = sys.argv[2]
    defending_pokemon_name = sys.argv[3]

    # TODO: your code here
    #check atk pokemon exist
    cur1 = db.cursor()
    atk_pokemon_exist_qry = f"""
    select * from pokemon where name = '{attacking_pokemon_name}'
    """
    cur1.execute(atk_pokemon_exist_qry)
    result = cur1.fetchone()
    if result == None:
        print(f'Pokemon "{attacking_pokemon_name}" does not exist')
        exit(1)
    #check def pokemon exist
    cur2 = db.cursor()
    def_pokemon_exist_qry = f"""
    select * from pokemon where name = '{defending_pokemon_name}'
    """
    cur2.execute(def_pokemon_exist_qry)
    result = cur2.fetchone()
    if result == None:
        print(f'Pokemon "{defending_pokemon_name}" does not exist')
        exit(1)
        
    #check if pokemon in game
    cur3 = db.cursor()
    pokemon_in_game_qry = f"""
    select p.name from pokemon p JOIN pokedex pd on pd.national_id = p.id JOIN games g ON g.id = pd.game where g.name = '{game_name}';
    """
    cur3.execute(pokemon_in_game_qry)
    result = cur3.fetchall()
    #get all pokemon names in the game
    cleaned_pokemon_list = [item[0].replace("'", "").replace(",", "") for item in result]
    
    if attacking_pokemon_name not in cleaned_pokemon_list:
        print(f'Pokemon "{attacking_pokemon_name}" is not in "{game_name}"')
        exit(1)
    elif defending_pokemon_name not in cleaned_pokemon_list:
        print(f'Pokemon "{defending_pokemon_name}" is not in "{game_name}"')
        exit(1)

    #get attack pokemon type
    cur4 = db.cursor()
    get_atk_pk_type_qry = f"""
    SELECT * FROM Get_Pokemon_Type('{attacking_pokemon_name}')
    """
    cur4.execute(get_atk_pk_type_qry)
    result = cur4.fetchone()
    atk_pk_type = result[1:]
    
    #get defend pokemon type
    cur5 = db.cursor()
    get_def_pk_type_qry = f"""
    SELECT * FROM Get_Pokemon_Type('{defending_pokemon_name}')
    """
    cur5.execute(get_def_pk_type_qry)
    result = cur5.fetchone()
    def_pk_type = result[1:]
    
    #print(def_pk_type[0]) --> first_type
        
    #get attack pokemon moves
    cur6 = db.cursor()
    get_atk_pk_moves_qry = f"""
    SELECT * FROM MOVE_TO_USE('{game_name}','{attacking_pokemon_name}')
    """
    cur6.execute(get_atk_pk_moves_qry)
    result = cur6.fetchall()
    atk_pk_moves = []
    #put all the moves and their information into a list of lists
    for line in result:
        current_list = []
        #move name
        current_list.append(line[0])
        #move requirment
        cleaned_requirements = line[1].replace(',', ' OR')
        current_list.append(cleaned_requirements)
        #move power
        current_list.append(line[2])
        #move type
        current_list.append(line[3])
        atk_pk_moves.append(current_list)
        current_list = []
        
        
    #get all type effectiveness
    cur7 = db.cursor()
    get_type_effectiveness_qry = """
    SELECT * FROM ATK_DEF_TYPE_EFFECTIVENESS
    """
    cur7.execute(get_type_effectiveness_qry)
    result = cur7.fetchall()
    type_effectiveness = []
    for line in result:
        current_list = []
        #atk type 
        current_list.append(line[0])
        #def type
        current_list.append(line[1])
        #multiplier
        current_list.append(line[2])
        type_effectiveness.append(current_list)
        current_list = []
    
    #convert the type multipliers to list of dicts for easier searching
    type_multipliers = {(effect[0], effect[1]): effect[2] for effect in type_effectiveness}
    
    #modify power
    for move in atk_pk_moves:
        move_type = move[3]
        #if atk pokemon type and move type share the same type
        if move_type == atk_pk_type[0] or move_type == atk_pk_type[1]:
            #round down
            move[2] = math.floor(int(move[2]) * 1.5)
        #apply multiplier if it is not 0
        for atk_type, def_type, multiplier in type_effectiveness:
            #move against def pokemon first type
            if atk_type == move_type and def_type == def_pk_type[0]:
                move[2] = math.floor(int(move[2]) * int(multiplier) / 100)
            #if defending pokemon have second type
            if def_pk_type[1] != None:
                #move against def pokemon first type
                if atk_type == move_type and def_type == def_pk_type[1]:
                    move[2] = math.floor(int(move[2]) * int(multiplier) / 100)

    #sort
    sorted_moves = sorted(atk_pk_moves, key = lambda x : (int(-x[2]), x[0]))
    #print result
    print(f'If "{attacking_pokemon_name}" attacks "{defending_pokemon_name}" in "{game_name}" it\'s available moves are:')
    for moves in sorted_moves:
        print(f'\t{moves[0]}')
        print(f'\t\twould have a relative power of {moves[2]}')
        print(f'\t\tand can be learnt from {moves[1]}')

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
