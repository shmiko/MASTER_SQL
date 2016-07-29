  CREATE OR REPLACE PROCEDURE set_xx_vars IS
  BEGIN
    warehouse VARCHAR2(500);
    EXEC SELECT EOM_REPORT_PKG.f_GetWarehouse_from_SD('FLOORS') INTO :warehouse FROM DUAL;
    Print warehouse;
  END set_xx_vars;



BEGIN
 set_xx_vars;
END;






SELECT RMI1.RM_CUST,RMI2.RM_XX_AAE_ACCT FROM PWIN175.RMI1 ,PWIN175.RMI2
WHERE  PWIN175.RMI1.ID = PWIN175.RMI2.ID
AND To_Number(regexp_substr(RM_XX_FEE01,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) >= 0.1;



var warehouse VARCHAR2(500)
EXEC SELECT EOM_REPORT_PKG.f_GetWarehouse_from_SD('FLOORS') INTO :warehouse FROM DUAL;
Print warehouse;




DECLARE
 mydt DATE;
 olddt varchar2(10);
BEGIN
 FOR i IN 2000..2016 loop
  olddt:= '02/04/'||i;
  SELECT last_day(to_date(olddt, 'MM/DD/RRRR'))
  INTO mydt
  FROM dual;
  dbms_output.put_line(olddt||'   '||mydt);
 END loop;
END;




declare

  mytable varchar(32) := 'PWIN175.RMI2';

  cursor s1 (mytable varchar2) is
            select column_name
            from user_tab_columns
            where table_name = 'PWIN175.RMI2' --mytable
            and nullable = 'Y';

  mycolumn varchar2(32);
  query_str varchar2(100);
  mycount number;

begin

  open s1 (mytable);

  loop
     fetch s1 into mycolumn;
           dbms_output.put_line('Column ');
         exit when s1%NOTFOUND;

     query_str := 'select count(*) from ' || mytable || ' where '  || mycolumn || ' is null';

     execute immediate query_str into mycount;

     dbms_output.put_line('Column ' || mycolumn || ' has ' || mycount || ' null values');

  end loop;
end;
/


select a.table_name, column_name,DATA_TYPE,DATA_LENGTH from all_tab_columns a,USER_ALL_TABLES u
where a.TABLE_NAME=u.TABLE_NAME
and column_name like 'RM_XX_FEE%'
order by DATA_LENGTH desc;



begin
    for r in ( select column_name, data_type
               from    user_tab_columns
               where table_name = upper('&&p_1')
               order by column_id )
    loop
        dbms_output.put_line(r.column_name ||' is '|| r.data_type );
    end loop;

end;



