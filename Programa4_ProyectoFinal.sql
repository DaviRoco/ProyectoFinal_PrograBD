CREATE PROCEDURE DATA_DICTIONARY(drDATA varchar2) IS
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
end;