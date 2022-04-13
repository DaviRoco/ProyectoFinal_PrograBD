CREATE OR REPLACE PACKAGE drDB IS
    PROCEDURE USER_DB_STRUCTURE(drUSR varchar2);
    PROCEDURE RELATIONAL_INFO(drFKS varchar2);
    PROCEDURE DATA_LOAD(drLOAD varchar2, fileName varchar2);
    PROCEDURE DATA_DICTIONARY(drDATA varchar2);
    PROCEDURE DATA_SEARCH(drFIND varchar2);
END drDB;
CREATE OR REPLACE PACKAGE BODY drDB IS
    --1.USER DB STRUCTURE
    PROCEDURE USER_DB_STRUCTURE(drUSR varchar2) IS
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
    end USER_DB_STRUCTURE;
--2. RELATIONAL INFO
    PROCEDURE RELATIONAL_INFO(drFKS varchar2) IS
        CURSOR c_tables IS
            SELECT table_name
            FROM ALL_TABLES
            WHERE owner = drFKS
            ORDER BY table_name;
    BEGIN
        FOR i IN c_tables
            LOOP
                DBMS_OUTPUT.PUT_LINE(chr(10));
                DBMS_OUTPUT.PUT_LINE(i.table_name || ' : ');

                DECLARE
                    vNombrePkR VARCHAR2(1000);
                    vResult    VARCHAR2(1000);
                    CURSOR c_infoPk IS
                        SELECT a.TABLE_NAME,
                               a.COLUMN_NAME,
                               a.CONSTRAINT_NAME,
                               c.OWNER,
                               c.R_OWNER,
                               c_pk.TABLE_NAME      r_table_name,
                               c_pk.CONSTRAINT_NAME r_pk
                        FROM all_cons_columns a
                                 JOIN all_constraints c ON a.owner = c.owner
                            AND a.constraint_name = c.constraint_name
                                 JOIN all_constraints c_pk ON c.r_owner = c_pk.owner
                            AND c.r_constraint_name = c_pk.constraint_name
                        WHERE c.constraint_type = 'R'
                          AND a.table_name = i.table_name;

                BEGIN
                    FOR j IN c_infoPk
                        LOOP
                            vNombrePkR := '';
                            vResult := '';
                            SELECT column_name
                            INTO vNombrePkR
                            FROM all_cons_columns
                            WHERE constraint_name = (
                                SELECT constraint_name
                                FROM user_constraints
                                WHERE UPPER(table_name) = UPPER(j.r_table_name)
                                  AND CONSTRAINT_TYPE = 'P'
                            );
                            vResult := '(' || vNombrePkR || ')';
                            DBMS_OUTPUT.PUT_LINE(j.COLUMN_NAME || ' --> ' || j.r_table_name || vResult);

                        end loop;

                end;

            end loop;

    end RELATIONAL_INFO;
--3. DATA LOAD
    PROCEDURE DATA_LOAD(drLOAD varchar2, fileName varchar2) IS
        createDDL VARCHAR2(32767);
        path      VARCHAR2(32767);
        fileDDL   UTL_FILE.FILE_TYPE;
        CURSOR c_createsTable IS
            select dbms_metadata.get_ddl('TABLE', table_name) data
            from ALL_TABLES
            WHERE OWNER = drLOAD;
    BEGIN
        fileDDL := UTL_FILE.FOPEN('ORACLE_BASE', fileName, 'W');
        FOR i IN c_createsTable
            LOOP
                createDDL := i.data || chr(13);
                dbms_output.put_line(createDDL);
                UTL_FILE.PUT(fileDDL, chr(13));
                UTL_FILE.PUT(fileDDL, '--** TABLE **' || chr(13));
                UTL_FILE.PUT(fileDDL, createDDL);
            end loop;
        UTL_FILE.FCLOSE(fileDDL);
        DBMS_OUTPUT.PUT_LINE(chr(10));
        DBMS_OUTPUT.PUT_LINE('Puede encontrar el archivo DDL en la siguiente ruta de su computadora');
        select DIRECTORY_PATH
        INTO path
        from ALL_DIRECTORIES
        WHERE DIRECTORY_NAME = 'ORACLE_BASE';
        DBMS_OUTPUT.PUT_LINE(path);
    END DATA_LOAD;

--4. DATA DICTIONARY
    PROCEDURE DATA_DICTIONARY(drDATA varchar2) IS
        tempType VARCHAR2(50);
        CURSOR c_colums IS
            select DISTINCT col.table_name,
                            col.column_name,
                            col.data_type,
                            col.data_length
            from sys.all_tab_columns col
                     join sys.all_tables t on col.owner = t.owner
            where col.owner = drDATA
            order by col.COLUMN_NAME;

    BEGIN
        DBMS_OUTPUT.PUT_LINE(RPAD('Column', 20) || RPAD('Type', 20) || RPAD('Table', 20) || RPAD('Values', 20));
        DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE(chr(10));
        FOR i IN c_colums
            LOOP
                DECLARE
                    rango1 VARCHAR2(2000);
                    rango2 VARCHAR2(2000);
                BEGIN

                    EXECUTE IMMEDIATE 'SELECT ' || i.COLUMN_NAME || ' FROM ' || i.TABLE_NAME || ' ORDER BY ' ||
                                      i.COLUMN_NAME ||
                                      ' ASC FETCH FIRST 1 ROWS ONLY'
                        INTO rango1;

                    EXECUTE IMMEDIATE 'SELECT ' || i.COLUMN_NAME || ' FROM ' || i.TABLE_NAME || ' ORDER BY ' ||
                                      i.COLUMN_NAME ||
                                      ' DESC FETCH FIRST 1 ROWS ONLY'
                        INTO rango2;

                    tempType := UPPER(SUBSTR(i.DATA_TYPE, 1, 1)) || '(' || i.DATA_LENGTH || ')';
                    DBMS_OUTPUT.PUT_LINE(RPAD(i.COLUMN_NAME, 20) || RPAD(tempType, 20) ||
                                         RPAD(i.TABLE_NAME, 20) ||
                                         RPAD(rango1 || '..' || rango2, 20));

                end;
            end loop;
    end DATA_DICTIONARY;

--5. DATA SEARCH
    PROCEDURE DATA_SEARCH(drFIND varchar2) IS
        cantidad_veces_repetidas NUMBER       := 0;
        tipo_data                varchar2(10) := &tipo;
        input_USER               varchar2(50) := &valor;
        col_rownum               varchar2(50);
        col_val                  varchar2(200);
        query_str                varchar2(200);
        TYPE cur_typ IS REF CURSOR;
        encontrar_ROWNUM         cur_typ;
    BEGIN
        IF tipo_data = 'V' THEN
            tipo_data := 'VARCHAR2';
        ELSIF tipo_data = 'C' THEN
            tipo_data := 'CHAR';
        ELSIF tipo_data = 'D' THEN
            tipo_data := 'DATE';
        ELSIF tipo_data = 'N' THEN
            tipo_data := 'NUMBER';
        ELSE
            DBMS_OUTPUT.PUT_LINE('TIPO DE DATO INVÁLIDO');
        END IF;
        DECLARE
            CURSOR info_USERCOLS IS
                SELECT column_name,
                       TABLE_NAME,
                       DATA_TYPE
                FROM ALL_TAB_COLS
                WHERE DATA_TYPE = tipo_data
                  AND OWNER = drFIND;
        BEGIN
            DBMS_OUTPUT.PUT_LINE('type(V/C/D/N): ' || tipo_data);
            DBMS_OUTPUT.PUT_LINE('value ' || input_USER);
            DBMS_OUTPUT.PUT_LINE('Result: ');
            DBMS_OUTPUT.PUT_LINE(RPAD('      Table', 30) || RPAD('  Column', 30) || RPAD(' Rownum', 30));
            DBMS_OUTPUT.PUT_LINE(
                        RPAD('      ------------------------------------------------------------', 30) ||
                        RPAD(' ------------------------------------------------------------', 30) ||
                        RPAD(' ------------------------------------------------------------', 30));
            FOR i in info_USERCOLS
                LOOP
                    EXECUTE IMMEDIATE
                            'SELECT COUNT(*) FROM ' || drFIND || '.' || i.table_name ||
                            ' WHERE ' || i.column_name || ' = :1'
                        INTO cantidad_veces_repetidas
                        USING input_USER;
                    IF cantidad_veces_repetidas > 0 THEN
                        query_str := 'SELECT ROWNUM, ' || i.COLUMN_NAME || ' FROM ' || i.TABLE_NAME;
                        OPEN encontrar_ROWNUM FOR query_str;
                        LOOP
                            FETCH encontrar_ROWNUM INTO col_rownum, col_val;
                            IF (col_val = input_USER) THEN
                                DBMS_OUTPUT.PUT_LINE(RPAD('      ' || i.table_name, 30) ||
                                                     RPAD('  ' || i.column_name, 30) ||
                                                     RPAD(' ' || col_rownum, 30));
                            end if;
                            EXIT WHEN encontrar_ROWNUM%NOTFOUND;
                        END LOOP;
                        CLOSE encontrar_ROWNUM;
                    END IF;
                end loop;
        end;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('ERROR EN EL PROGRAMA');
    end DATA_SEARCH;
END drDB;
-- BEGIN
--     DBMS_OUTPUT.PUT_LINE('Función 1:  CAPI con el texto dAVID --> ' || LTR.CAPI('dAVID'));
--     DBMS_OUTPUT.PUT_LINE(' ');
--     DBMS_OUTPUT.PUT_LINE('Función 2:  PICA con el texto david --> ' || LTR.PICA('david'));
--     DBMS_OUTPUT.PUT_LINE(' ');
--     DBMS_OUTPUT.PUT_LINE('Función 3:  TRABA con el texto vocales y vocal e --> ' || LTR.TRABA('vocales', 'e'));
--     DBMS_OUTPUT.PUT_LINE(' ');
--     DBMS_OUTPUT.PUT_LINE('Función 4:  PALABRAS con el texto Texto de prueba: hola --> ' ||
--                          LTR.PALABRAS('Texto de prueba: hola'));
--     DBMS_OUTPUT.PUT_LINE(' ');
--     DBMS_OUTPUT.PUT_LINE('Función 5:  VOCAL con el texto vocales oooo y vocal o --> ' || LTR.VOCAL('vocales oooo', 'o'));
-- END;