#! /usr/bin/env python3


"""
COMP3311
24T1
Assignment 2
Pokemon Database

Written by: <Yuet Yat (Xerox) Chan> <z5289835>
Written on: <20/04/2024>

File Name: Q2

Description: List all locations where a specific pokemon can be found
"""


import sys
import psycopg2
import helpers

### Constants
USAGE = f"Usage: {sys.argv[0]} <pokemon_name>"


def main(db):
    if len(sys.argv) != 2:
        print(USAGE)
        return 1

    pokemon_name = sys.argv[1]
    #cursor
    
    # TODO: your code here
    #cursor
    cur1 = db.cursor()
    get_pokemon_id_qry = f"""
    select pokemon_to_id('{pokemon_name}')
    """
    #get pokemon_id
    cur1.execute(get_pokemon_id_qry)
    result = cur1.fetchone()
    
    #check if pokemon exist
    if result != None:
        pokemon_id = result[0]
    elif result == None:
        print(f'Pokemon "{pokemon_name}" does not exist')
        exit(1)
    #query to get information from database using helper fuinction from helpers.sql
    Q2_qry = f"""
    select * from Q2({pokemon_id})
    """
    cur2 = db.cursor()
    cur2.execute(Q2_qry)
    
    result = cur2.fetchall()
    #pokemon exist but has no encounters
    if len(result) == 0:
        print(f'Pokemon "{pokemon_name}" is not encounterable in any game')
        exit(1)
    #pokemon exist and has encounters
    else:
        #list with header to append cleaned data from result
        result_data = [["Game", "Location", "Rarity", "MinLevel", "MaxLevel", "Requirements"]]
        cleaned_data = []
        #clean data from result of sql
        for line in result:
            current_data = []
            #Region
            current_data.append(line[0])
            #Game
            current_data.append(line[1])
            #Location
            current_data.append(line[2])
            #Rarity
            Rarity_int = int(line[3])
            if Rarity_int >= 21:
                Rarity = 'Common'
            elif 6 <= Rarity_int <= 20:
                Rarity = 'Uncommon'
            elif 1 <= Rarity_int <= 5:
                Rarity = 'Rare'
            elif Rarity_int == 0:
                Rarity = 'Limited'
            current_data.append(Rarity)
            #Level
            level_range = line[4].replace("(","").replace(")","").split(',')
            #MinLevel
            current_data.append(level_range[0])
            #MaxLevel
            current_data.append(level_range[1])
            #Inverted Requirements
            #current_data.append(line[5])
            #requirement id
            requirements_id = str(line[6])
            current_data.append(requirements_id)
            requirements = line[7]
            if line[5] == False:
                 current_data.append(requirements)
            #Inverted
            elif line[5] == True:
                 requirements = 'Not ' + requirements
                 current_data.append(requirements)

            #add to cleaned data
            cleaned_data.append(current_data)
            current_data = []
        #print(cleaned_data)
        #sorting data
        region_order = {
            'Kanto': 0,
            'Johto': 1,
            'Hoenn': 2,
            'Sinnoh': 3,
            'Unova': 4,
            'Kalos': 5,
            'Alola': 6,
            'Galar': 7,
            'Hisui': 8,
            'Paldea': 9
        }
        sorted_data = sorted(cleaned_data, key = lambda x: (region_order[x[0]], x[1], x[2], x[3], int(x[4]), int(x[5]), x[7]))

        #combine
        grouped_entries = {}
        # Grouping entries by the first six columns
        for entry in sorted_data:
            key = tuple(entry[:7])  # Creating a key from the first six columns
            if key not in grouped_entries:
                grouped_entries[key] = set()
            grouped_entries[key].add(entry[7])  # Adding the requirement to the set for uniqueness
    
        # Creating a list of combined entries
        combined_data = []
        for key, requirements in grouped_entries.items():
            combined_data.append(list(key) + [', '.join(sorted(requirements))])

        #extract every item but region
        columns_to_extract = [1, 2, 3, 4, 5, 7]
        extracted_data = [ [entry[i] for i in columns_to_extract] for entry in combined_data]

        #append it to the result
        result_list = result_data + extracted_data

        #prepare for dynamically formatted string
        num_columns = len(result_list[0])
        max_widths = [0] * num_columns
        #determin max length of each column
        for row in result_list:
            for i in range(num_columns):
                max_widths[i] = max(max_widths[i], len(row[i]))
        format_str = ' '.join(f"{{:<{width}}}" for width in max_widths)


        # Create a dictionary where keys are tuples from sublists
        unique_dict = {tuple(item): item for item in result_list}

        # Extract the values (original sublists) from the dictionary
        unique_list = list(unique_dict.values())
        
        for row in unique_list:
            print(format_str.format(*row))
    
    
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
