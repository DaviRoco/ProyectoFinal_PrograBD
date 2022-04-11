--2. RELATIONAL INFO
DECLARE
    drFKS varchar2(50) := 'BETA';
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
end ;