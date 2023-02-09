#!/usr/bin/python3

import psycopg2
from psycopg2.extras import RealDictConnection
from psycopg2.errors import UndefinedColumn
import sys
from getpass import getpass

# Funciones

database = ""

def dump_database(conn):
    with conn.cursor() as cur:
        # Funciones
        try:
            cur.execute("""SELECT
                    n.nspname,
                    p.proname,
                    pg_get_functiondef(p.oid) AS function,
                    COALESCE('COMMENT ON FUNCTION ' || p.oid::regprocedure || ' IS ' || quote_literal(obj_description(p.oid, 'pg_proc')), '') AS comment
                FROM   pg_proc p
                JOIN   pg_namespace n ON n.oid = p.pronamespace
                WHERE  n.nspname !~ '^(pg_|information_schema)'
                AND    NOT EXISTS (
                SELECT FROM pg_depend
                WHERE  objid = p.oid
                AND    deptype = 'e'
                )
                AND    not p.proisagg
                ORDER  BY n.nspname, p.proname, function;
            """)
        except UndefinedColumn:
            conn.rollback()
            cur.execute("""SELECT
                    n.nspname,
                    p.proname,
                    pg_get_functiondef(p.oid) AS function,
                    COALESCE('COMMENT ON FUNCTION ' || p.oid::regprocedure || ' IS ' || quote_literal(obj_description(p.oid, 'pg_proc')), '') AS comment
                FROM   pg_proc p
                JOIN   pg_namespace n ON n.oid = p.pronamespace
                WHERE  n.nspname !~ '^(pg_|information_schema)'
                AND    NOT EXISTS (
                    SELECT FROM pg_depend
                    WHERE  objid = p.oid
                    AND    deptype = 'e'
                )
                AND    p.prokind IN ('f', 'p', 'w')
                ORDER  BY n.nspname, p.proname, function;
            """)


        for row in cur.fetchall():
            print("/**********")
            print(" * Function: {nspname}.{proname}\n */\n{function}\n{comment}\n".format(**row))

        # Aggregates
        cur.execute("""SELECT
                n.nspname,
                p.proname,
                format(
                    'CREATE AGGREGATE %s (SFUNC = %s, STYPE = %s%s%s%s%s)',
                    a.aggfnoid::regprocedure,
                    a.aggtransfn,
                    a.aggtranstype::regtype,
                    ', SORTOP = ' || NULLIF(a.aggsortop, 0)::regoper,
                    ', INITCOND = ' || a.agginitval,
                    ', FINALFUNC = ' || NULLIF(a.aggfinalfn, 0),
                    CASE WHEN a.aggfinalextra THEN ', FINALFUNC_EXTRA' END
                ) AS aggregate,
                'COMMENT ON AGGREGATE ' || aggfnoid::regprocedure || ' IS ' || quote_literal(obj_description(aggfnoid, 'pg_proc')) AS comment
            FROM   pg_aggregate a
            JOIN   pg_proc      p ON p.oid = a.aggfnoid
            JOIN   pg_namespace n ON n.oid = p.pronamespace
            WHERE  n.nspname !~ '^(pg_|information_schema)'       -- exclude system schemas
            -- AND    n.nspname = 'public'                        -- or from selected schema only?
            AND    NOT EXISTS (
            SELECT FROM pg_depend 
            WHERE  objid = a.aggfnoid
            AND    deptype = 'e'
            )
            ORDER  BY n.nspname, p.proname;
        """)

        for row in cur.fetchall():
            print("/**********")
            print(" * Aggregate: {nspname}.{proname}\n */\n{aggregate}\n{comment}\n".format(**row))

        # lista de entidades 
        cur.execute("""SELECT
            c.oid,
            n.nspname,
            c.relname,
            CASE c.relkind
            WHEN 'r' THEN 'table' 
            WHEN 'v' THEN 'view' 
            WHEN 'm' THEN 'materialized view' 
            WHEN 'i' THEN 'index' 
            WHEN 'S' THEN 'sequence' 
            WHEN 's' THEN 'special' 
            WHEN 'f' THEN 'foreign table' 
            WHEN 'p' THEN 'table' 
            WHEN 'I' THEN 'index' 
            END as "reltype"
            FROM pg_catalog.pg_class c
                LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
            WHERE c.relkind IN ('r','v','m','S','s','f','p','')
                AND n.nspname !~ '^pg_toast' AND n.nspname !~ '^pg_catalog' AND n.nspname !~ '^information_schema' AND n.nspname !~ '^tiger'
            order by c.relkind, n.nspname, c.relname
        """)

        for row in cur.fetchall():
            print("/**********")
            print(" * {reltype}: {nspname}.{relname}\n */".format(**row))

            if row["reltype"] == 'sequence':
                print('CREATE SEQUENCE {nspname}.{relname};\n'.format(**row))

            elif row["reltype"] == 'table':
                # Tablas
                with conn.cursor() as cur2:
                    cur2.execute(f"""SELECT
                            b.oid as oid,
                            b.nspname as schema_name,
                            b.relname as table_name,
                            a.attname as column_name,
                            pg_catalog.format_type(a.atttypid, a.atttypmod) as column_type,
                            CASE WHEN 
                                (SELECT substring(pg_catalog.pg_get_expr(d.adbin, d.adrelid) for 128)
                                FROM pg_catalog.pg_attrdef d
                                WHERE d.adrelid = a.attrelid AND d.adnum = a.attnum AND a.atthasdef) IS NOT NULL THEN
                                'DEFAULT '|| (SELECT substring(pg_catalog.pg_get_expr(d.adbin, d.adrelid) for 128)
                                            FROM pg_catalog.pg_attrdef d
                                            WHERE d.adrelid = a.attrelid AND d.adnum = a.attnum AND a.atthasdef)
                            ELSE
                                ''
                            END as column_default_value,
                            CASE WHEN a.attnotnull = true THEN 
                                'NOT NULL'
                            ELSE
                                'NULL'
                            END as column_not_null,
                            a.attnum as attnum,
                            e.max_attnum as max_attnum
                        FROM 
                            pg_catalog.pg_attribute a
                            INNER JOIN 
                            (SELECT c.oid,
                                n.nspname,
                                c.relname
                            FROM pg_catalog.pg_class c
                                LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
                            WHERE c.relname ~ ('^({row["relname"]})$')
                                AND n.nspname ~ ('^({row["nspname"]})$')
                                --AND pg_catalog.pg_table_is_visible(c.oid)
                            ORDER BY 2, 3) b
                            ON a.attrelid = b.oid
                            INNER JOIN 
                            (SELECT 
                                a.attrelid,
                                max(a.attnum) as max_attnum
                            FROM pg_catalog.pg_attribute a
                            WHERE a.attnum > 0 
                                AND NOT a.attisdropped
                            GROUP BY a.attrelid) e
                            ON a.attrelid=e.attrelid
                        WHERE a.attnum > 0 
                        AND NOT a.attisdropped
                        ORDER BY a.attnum
                    """)

                    v_table_ddl = ''
                    for row2 in cur2.fetchall():
                        if row2["attnum"] == 1:
                            v_table_ddl = 'CREATE TABLE ' + row2["schema_name"] + '.' + row2["table_name"] + ' (';
                        else:
                            v_table_ddl = v_table_ddl + ',';

                        if row2["attnum"] <= row2["max_attnum"]:
                            v_table_ddl = v_table_ddl + '\n    ' + row2["column_name"] + ' ' + row2["column_type"] + ' ' + row2["column_default_value"] + ' ' + row2["column_not_null"];

                    print(v_table_ddl + "\n);\n")

                    # Constraint de cada tabla
                    cur2.execute(f"""SELECT r.conname, pg_catalog.pg_get_constraintdef(r.oid, true) definition
                        FROM pg_catalog.pg_constraint r
                        WHERE r.conrelid = '{row["oid"]}'
                        ORDER BY 1;""")

                    for row2 in cur2.fetchall():
                        print(f"""ALTER TABLE {row["nspname"]}.{row["relname"]} ADD CONSTRAINT {row2["conname"]}\n    {row2["definition"]};""")
                    print("")

            elif row["reltype"] == 'view':
                with conn.cursor() as cur2:
                    cur2.execute(f"""SELECT pg_catalog.pg_get_viewdef('{row["oid"]}'::pg_catalog.oid, true) as definition;""")

                    row2 = cur2.fetchone()
                    print("CREATE VIEW {nspname}.{relname} AS\n{definition}\n".format(nspname = row['nspname'], relname = row['relname'], definition = row2['definition']))

        # Indices
        cur.execute("""SELECT * FROM pg_indexes WHERE schemaname NOT IN ('tiger', 'pg_catalog') ORDER BY 1,2,3""")

        for row in cur.fetchall():
            print("/**********")
            print(" * Index: {schemaname}.{tablename}.{indexname}\n */\n{indexdef}\n".format(**row))

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <dbname> <dbuser> [<dbhost> [<dbpass> [<dbport>]]]", file=sys.stderr)
        exit()

    dbname = sys.argv[1]
    dbuser = sys.argv[2]
    dbhost = sys.argv[3] if 3 in sys.argv else 'localhost'
    dbpass = sys.argv[4] if 4 in sys.argv else None
    dbport = sys.argv[5] if 5 in sys.argv else 5432
    
    if dbpass is None:
        dbpass = getpass()

    try:
        conn = RealDictConnection("dbname='{0}' user='{1}' host='{2}' password='{3}' port='{4}'".format(dbname, dbuser, dbhost, dbpass, dbport))
    except:
        print("I am unable to connect to the database", file=sys.stderr)
        exit()

    dump_database(conn)
