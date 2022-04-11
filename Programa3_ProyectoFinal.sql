CREATE PROCEDURE RELATIONAL_INFO(drLOAD varchar2, fileName varchar2) IS
DECLARE
    createDDL VARCHAR2(32767);
    fileDDL   UTL_FILE.FILE_TYPE;
    CURSOR c_createsTable IS
        select dbms_metadata.get_ddl('TABLE', table_name) data
        from ALL_TABLES
        WHERE OWNER = drLOAD;
BEGIN
    fileDDL := UTL_FILE.FOPEN('ORACLE_BASE', fileName, 'W');
    FOR i IN c_createsTable
        LOOP
            createDDL := i.data ||chr(13);
            dbms_output.put_line(createDDL);
            UTL_FILE.PUT(fileDDL, chr(13));
            UTL_FILE.PUT(fileDDL, '--** TABLE **' ||chr(13));
            UTL_FILE.PUT(fileDDL, createDDL);
        end loop;

     UTL_FILE.FCLOSE(fileDDL);

END;