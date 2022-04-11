--DATA SEARCH(drFIND)
    DECLARE
    drFIND                   varchar2(20) := 'BETA';
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
end;



