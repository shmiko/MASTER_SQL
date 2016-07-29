
  create or replace function get_cust_stocks(r_coy_num in VARCHAR)
  return sys_refcursor is
    v_rc sys_refcursor;
  begin
    open v_rc for 'SELECT RM_CUST, RM_COY_NUM, RM_REP, RM_STD_CB_BANK FROM RM WHERE RM_PARENT = :coynum' using r_coy_num;
    return v_rc;
  end;
  /

/*   --this is for SQLPLUS
   var rc refcursor
   exec :rc := get_cust_stocks('RTA');
   print rc;
   --do the print again
   print rc; --not declared

   declare
      v_rc    sys_refcursor;
    begin
      v_rc := get_cust_stocks('RTA');  -- This returns an open cursor
      dbms_output.put_line('Rows: '||v_rc%ROWCOUNT);
      close v_rc;
   end;
   --no rows returned as we have not fetched any data yet.


   --So let's fetch all our data and display it..
   declare
     v_rc    sys_refcursor;
     v_cust   VARCHAR2(20);
     v_coynum   VARCHAR2(20);
     v_rep    VARCHAR2(20);
     v_bank VARCHAR(20);
    begin
      v_rc := get_cust_stocks('RTA');  -- This returns an open cursor
      dbms_output.put_line('Pre Fetch: Rows: '||v_rc%ROWCOUNT);
      fetch v_rc into v_cust, v_coynum, v_rep, v_bank;
      dbms_output.put_line('Post Fetch: Rows: '||v_rc%ROWCOUNT);
      close v_rc;
    end;
    /
    --SHows 2 counts before (0) and after (1)
    --This works in SQL tools
*/
    --Now loop through cursor to display data
    declare
      v_rc    sys_refcursor;
      v_cust   VARCHAR2(20);
      v_coynum   VARCHAR2(20);
      v_rep    VARCHAR2(20);
      v_bank VARCHAR(20);
    begin
      v_rc := get_cust_stocks('RTA');  -- This returns an open cursor
      loop
      fetch v_rc into v_cust, v_coynum, v_rep, v_bank;
      exit when v_rc%NOTFOUND;  -- Exit the loop when we've run out of data
        dbms_output.put_line('Row: '||v_rc%ROWCOUNT||' # '||v_cust||','||v_coynum||','||v_rep||','||v_bank);
      end loop;
      close v_rc;
    end;
    /
    --This shows row count and data per row
    --this takes 50ms
/*
    --this is for SQLPLUS
    var rc refcursor
    exec :rc := get_cust_stocks('RTA');
    print rc;


    --Now test the same via sql
    SELECT RM_CUST, RM_COY_NUM, RM_REP, RM_STD_CB_BANK FROM RM WHERE RM_PARENT = 'RTA'
    --this takes 15ms

    --And what happens if we try and fetch more data after it's finished, just like we tried to do in SQL*Plus..
    --Run this in SQL Tools
    declare
      v_rc    sys_refcursor;
      v_cust   VARCHAR2(20);
      v_coynum   VARCHAR2(20);
      v_rep    VARCHAR2(20);
      v_bank VARCHAR(20);
    begin
      v_rc := get_cust_stocks('RTA');  -- This returns an open cursor
      loop
        fetch v_rc into v_cust, v_coynum, v_rep, v_bank;
        exit when v_rc%NOTFOUND;  -- Exit the loop when we've run out of data
        dbms_output.put_line('Row: '||v_rc%ROWCOUNT||' # '||v_cust||','||v_coynum||','||v_rep||','||v_bank);
      end loop;
      close v_rc;
      fetch v_rc into v_cust, v_coynum, v_rep, v_bank;
    end;
    /

    --Perhaps we can just select from it?
    select * from get_cust_stocks('RTA');
    --ORA-00933: SQL command not properly ended

    --Nope.  How about if we tell SQL to treat it as a table?
    select * from table(get_cust_stocks('RTA'));
    --ORA-00932: inconsistent datatypes: expected - got CURSOR

    --What about using it as a set of data in an IN condition?
    select * from RM where RM_CUST in (get_cust_stocks('RTA'));
    --ORA-00932: inconsistent datatypes: expected - got CURSOR

*/
    --create a TYPE structure
    create or replace type custtype as object(cust varchar2(20),
                                              coynum varchar2(20),
                                              rep   varchar2(20),
                                              bank   varchar2(20));
    /

    create or replace type t_custtype as table of custtype;
    /


    --we have a structure to hold a record and a type that is a table of that structure
    create or replace function populate_custs(coynum in VARCHAR := null)
    return  t_custtype is
            v_custtype t_custtype := t_custtype();  -- Declare a local table structure and initialize it
            v_cnt     number := 0;
            v_rc    sys_refcursor;
            v_cust   VARCHAR2(20);
            v_coynum   VARCHAR2(20);
            v_rep    VARCHAR2(20);
            v_bank VARCHAR(20);

     begin
        v_rc := get_cust_stocks(coynum);
        loop
          fetch v_rc into v_cust, v_coynum, v_rep, v_bank;
          exit when v_rc%NOTFOUND;
          v_custtype.extend;
          v_cnt := v_cnt + 1;
          v_custtype(v_cnt) := custtype(v_cust, v_coynum, v_rep, v_bank);
        end loop;
        close v_rc;
        return v_custtype;
      end;
      /

      --So now we have something in an structure that SQL understands, we should be able to query directly from it..
      select * from table(populate_custs('RTA'));
      --Displays table data

      --Now get RM data and lookup what is in new table type
      select * from RM where RM_CUST in (select cust from table(populate_custs('RTA')));
      --We've successfully taken our ref cursor (pointer) and used it to fetch the data back that we want in a structure that SQL can understand.



    SELECT * FROM YP WHERE YP_CODE = 'FULFILCHK'