 --1.USER DB STRUCTURE
    DECLARE
        drUSR varchar2(50) := 'BETA';
        table_space        varchar2(20);
        quota              number;
        cantidad_tablas    number := 0;
        cantidad_views     number := 0;
        cantidad_synonyms  number := 0;
        cantidad_sequences number := 0;
        CURSOR tables_Usuario IS
            SELECT table_name
            FROM ALL_TABLES
            WHERE OWNER = drUSR;
        CURSOR views_Usuario IS
            SELECT view_name
            FROM ALL_VIEWS
            WHERE OWNER = drUSR;
        CURSOR sequences_Usuario IS
            SELECT sequence_name
            FROM ALL_SEQUENCES
            WHERE SEQUENCE_OWNER = drUSR;
        CURSOR synonyms_Usuario IS
            SELECT synonym_name
            FROM ALL_SYNONYMS
            WHERE OWNER = drUSR;
    BEGIN
        SELECT TABLESPACE_NAME
        into table_space
        FROM ALL_TABLES
        WHERE OWNER = drUSR FETCH FIRST ROW ONLY;
        BEGIN
            SELECT MAX_BYTES INTO quota FROM DBA_TS_QUOTAS WHERE USERNAME = drUSR AND TABLESPACE_NAME = table_space;
            IF (quota = -1) THEN
                DBMS_OUTPUT.PUT_LINE('USER: ' || drUSR || '         TableSpace: ' || table_space ||
                                     '           Quota: Unlimited');
            ELSE
                DBMS_OUTPUT.PUT_LINE('USER: ' || drUSR || '         TableSpace: ' || table_space ||
                                     '           Quota: ' ||
                                     quota);
            end if;
        end;
        FOR i in tables_Usuario
            LOOP
                cantidad_tablas := cantidad_tablas + 1;
            end loop;
        FOR i in views_Usuario
            LOOP
                cantidad_views := cantidad_views + 1;
            end loop;
        FOR i in sequences_Usuario
            LOOP
                cantidad_sequences := cantidad_sequences + 1;
            end loop;
        FOR i in synonyms_Usuario
            LOOP
                cantidad_synonyms := cantidad_synonyms + 1;
            end loop;
        DBMS_OUTPUT.PUT_LINE(' Tables: ' || cantidad_tablas || '   Views: ' || cantidad_views || '      Synonyms: ' ||
                             cantidad_synonyms ||
                             '      Sequences: ' || cantidad_sequences);
        DBMS_OUTPUT.PUT_LINE('-----------------------------------------------------------------------------------------------------------');
        DECLARE
            cantidad_filas number;
        BEGIN
            FOR i in tables_Usuario
                LOOP
                    SELECT NUM_ROWS
                    into cantidad_filas
                    FROM ALL_TABLES
                    WHERE TABLE_NAME = i.TABLE_NAME
                      AND OWNER = drUSR;
                    DBMS_OUTPUT.PUT_LINE('Table: ' || i.TABLE_NAME || '  ' || cantidad_filas || ' rows');
                    DBMS_OUTPUT.PUT_LINE(RPAD('Column', 20) || RPAD('Null?', 20) || RPAD('Type', 20) ||
                                         RPAD('Key', 20) ||
                                         RPAD('F.Table', 20));
                    DBMS_OUTPUT.PUT_LINE('-----------------------------------------------------------------------------------------------------------');
                    DECLARE
                        tipoKey varchar2(10);
                        fTable  varchar2(30);
                        CURSOR columns_tables IS
                            SELECT column_name,
                                   data_type,
                                   data_length,
                                   CASE NULLABLE
                                       WHEN 'N' THEN 'Not null'
                                       WHEN 'Y' THEN ' '
                                       END                                         as nullable,
                                   (SELECT cols.column_name
                                    FROM all_constraints cons,
                                         all_cons_columns cols
                                    WHERE cols.table_name = i.TABLE_NAME
                                      AND cons.constraint_type = 'P'
                                      AND cons.constraint_name = cols.constraint_name
                                      AND cons.owner = cols.owner
                                      AND cons.OWNER = drUSR FETCH FIRST ROW ONLY) AS pKey
                            FROM ALL_TAB_COLS
                            WHERE table_name = i.TABLE_NAME
                              AND OWNER = drUSR;
                        CURSOR Fkeys IS
                            SELECT a.column_name, c_pk.table_name r_table_name
                            FROM all_cons_columns a
                                     JOIN all_constraints c ON a.owner = c.owner
                                AND a.constraint_name = c.constraint_name
                                     JOIN all_constraints c_pk ON c.r_owner = c_pk.owner
                                AND c.r_constraint_name = c_pk.constraint_name
                            WHERE c.constraint_type = 'R'
                              AND a.table_name = i.TABLE_NAME;
                    BEGIN
                        FOR j in columns_tables
                            LOOP
                                IF (j.pKey = j.COLUMN_NAME) THEN
                                    tipoKey := 'PK';
                                ELSE
                                    FOR k in Fkeys
                                        LOOP
                                            IF (k.column_name = j.column_name) THEN
                                                tipoKey := 'FK';
                                                fTable := k.r_table_name;
                                            end if;
                                        end loop;
                                end if;
                                DBMS_OUTPUT.PUT_LINE(RPAD(j.COLUMN_NAME, 20) || RPAD(j.nullable, 20) ||
                                                     RPAD(j.DATA_TYPE || '(' || j.DATA_LENGTH || ')', 20)
                                    || RPAD(tipoKey, 20) || RPAD(fTable, 20));
                                tipoKey := ' ';
                                fTable := ' ';
                            end loop;
                    end;
                    DBMS_OUTPUT.PUT_LINE(' ');
                    DBMS_OUTPUT.PUT_LINE(' ');
                end loop;
        end;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('USUARIO NO TIENE SUFICIENTE INFORMACIÓN PARA HACER UN DESCRIBE DE LA ESTRUCTURA');
    end;