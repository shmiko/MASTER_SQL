declare
  TYPE curtype IS REF CURSOR;
  src_cur      curtype;
  curid        NUMBER;
  namevar  VARCHAR2(50);
  numvar   NUMBER;
  datevar  DATE;
  desctab  DBMS_SQL.DESC_TAB;
  colcnt   NUMBER;
  dsql varchar2(1000) := 'select card_no from card_table where rownum = 1';
begin
  OPEN src_cur FOR dsql;

  -- Switch from native dynamic SQL to DBMS_SQL package.
  curid := DBMS_SQL.TO_CURSOR_NUMBER(src_cur);
  DBMS_SQL.DESCRIBE_COLUMNS(curid, colcnt, desctab);

  -- Define columns.
  FOR i IN 1 .. colcnt LOOP
    IF desctab(i).col_type = 2 THEN
      DBMS_SQL.DEFINE_COLUMN(curid, i, numvar);
    ELSIF desctab(i).col_type = 12 THEN
      DBMS_SQL.DEFINE_COLUMN(curid, i, datevar);
    ELSE
      DBMS_SQL.DEFINE_COLUMN(curid, i, namevar, 50);
    END IF;
  END LOOP;

  -- Fetch rows with DBMS_SQL package.
  WHILE DBMS_SQL.FETCH_ROWS(curid) > 0 LOOP
    FOR i IN 1 .. colcnt LOOP
      IF (desctab(i).col_type = 1) THEN
        DBMS_SQL.COLUMN_VALUE(curid, i, namevar);
        dbms_output.put_line(namevar);
      ELSIF (desctab(i).col_type = 2) THEN
        DBMS_SQL.COLUMN_VALUE(curid, i, numvar);
        dbms_output.put_line(numvar);
      ELSIF (desctab(i).col_type = 12) THEN
        DBMS_SQL.COLUMN_VALUE(curid, i, datevar);
        dbms_output.put_line(datevar);
      END IF;
    END LOOP;
  END LOOP;

  DBMS_SQL.CLOSE_CURSOR(curid);

end;

declare
  sCustomerCode VARCHAR2(20) := 'RTA';
  QueryType     VARCHAR2(20) := 'DEV';
  SQLQuery2 VARCHAR2(2560) := 'SELECT * FROM ' 
            || QueryType || '_ALL_FREIGHT_ALL t'  ||' WHERE t.parent = ' 
            || '''' || sCustomerCode || '''';
  dbms_output.put_line(SQLQuery2);
begin
  Execute Immediate SQLQuery2 using QueryType,sCustomerCode;
  IF SQL%ROWCOUNT > 0 THEN
    DBMS_OUTPUT.PUT_LINE('Run for: ' || sCustomerCode 
                        || ' = ' || QueryType);
  END IF;
end;



SQL> declare
  2  
  3    CURSOR my_cursor IS SELECT ename, empno FROM emp;
  4    
  5    my_tab_rec my_cursor%rowtype;
  6  
  7    type tab_type is table of my_cursor%rowtype;
  8  
  9    tab tab_type;
 10  
 11  BEGIN
 12  
 13    OPEN my_cursor;
 14    LOOP
 15       FETCH my_cursor INTO my_tab_rec;
 16       EXIT WHEN my_cursor%NOTFOUND;
 17    END LOOP;
 18    CLOSE my_cursor;
 19  
 20    OPEN my_cursor;
 21       FETCH my_cursor BULK COLLECT INTO tab;
 22    CLOSE my_cursor;
 23  
 24  END;
 25  /


SQL> CREATE OR REPLACE PROCEDURE TEST
2 IS
3 TYPE t_rec IS table of tab1%rowtype index by binary_integer;
4 
5 
6 my_tab_rec t_rec;
7 
8 
9 BEGIN
10 select col1, col2 bulk collect into my_tab_rec from tab1;
11 
12 for i in my_tab_rec.first..my_tab_rec.last
13 loop
14 dbms_output.put_line (my_tab_rec(i).col1);
15 end loop;
16 
17 END;
18 /





CREATE OR REPLACE PROCEDURE salary_raise (raise_percent NUMBER, job VARCHAR2) IS
    TYPE loc_array_type IS TABLE OF VARCHAR2(40)
        INDEX BY binary_integer;
    dml_str VARCHAR2        (200);
    loc_array    loc_array_type;
BEGIN
    -- bulk fetch the list of office locations
    SELECT location BULK COLLECT INTO loc_array
        FROM offices;
    -- for each location, give a raise to employees with the given 'job' 
    FOR i IN loc_array.first..loc_array.last LOOP
        dml_str := 'UPDATE emp_' || loc_array(i) 
        || ' SET sal = sal * (1+(:raise_percent/100))'
        || ' WHERE job = :job_title';
    EXECUTE IMMEDIATE dml_str USING raise_percent, job;
    END LOOP;
END;
/
SHOW ERRORS;
