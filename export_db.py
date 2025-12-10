import sqlite3
import os

def export_sqlite_to_sql():
    # Connect to SQLite database
    sqlite_conn = sqlite3.connect('db.sqlite3')
    sqlite_cursor = sqlite_conn.cursor()

    # Get all table names
    sqlite_cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
    tables = sqlite_cursor.fetchall()

    # Create SQL file
    with open('database_dump.sql', 'w') as f:
        # Write MySQL specific settings
        f.write("SET FOREIGN_KEY_CHECKS=0;\n\n")
        
        for table in tables:
            table_name = table[0]
            if table_name.startswith('sqlite_'):
                continue
                
            # Get table schema
            sqlite_cursor.execute(f"PRAGMA table_info({table_name})")
            columns = sqlite_cursor.fetchall()
            
            # Create table
            f.write(f"DROP TABLE IF EXISTS `{table_name}`;\n")
            f.write(f"CREATE TABLE `{table_name}` (\n")
            
            column_definitions = []
            for col in columns:
                col_name = col[1]
                col_type = col[2]
                col_notnull = col[3]
                col_default = col[4]
                col_pk = col[5]
                
                # Convert SQLite types to MySQL types
                if col_type == 'INTEGER':
                    col_type = 'INT'
                elif col_type == 'TEXT':
                    col_type = 'TEXT'
                elif col_type == 'REAL':
                    col_type = 'FLOAT'
                elif col_type == 'BLOB':
                    col_type = 'LONGBLOB'
                
                definition = f"`{col_name}` {col_type}"
                if col_notnull:
                    definition += " NOT NULL"
                if col_default is not None:
                    definition += f" DEFAULT '{col_default}'"
                if col_pk:
                    definition += " PRIMARY KEY"
                column_definitions.append(definition)
            
            f.write(",\n".join(column_definitions))
            f.write("\n);\n\n")
            
            # Get table data
            sqlite_cursor.execute(f"SELECT * FROM {table_name}")
            rows = sqlite_cursor.fetchall()
            
            if rows:
                # Get column names
                sqlite_cursor.execute(f"PRAGMA table_info({table_name})")
                columns = [col[1] for col in sqlite_cursor.fetchall()]
                
                # Insert data
                for row in rows:
                    values = []
                    for value in row:
                        if value is None:
                            values.append('NULL')
                        elif isinstance(value, (int, float)):
                            values.append(str(value))
                        else:
                            values.append(f"'{str(value).replace("'", "''")}'")
                    
                    f.write(f"INSERT INTO `{table_name}` (`{'`, `'.join(columns)}`) VALUES ({', '.join(values)});\n")
                f.write("\n")
        
        f.write("SET FOREIGN_KEY_CHECKS=1;\n")

    sqlite_conn.close()

if __name__ == "__main__":
    export_sqlite_to_sql() 