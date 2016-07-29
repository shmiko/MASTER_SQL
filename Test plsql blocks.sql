
--Using STRONG REF CURSOR for multiple queries - reassinging cur_custs to children
var cust varchar2(20)
exec :cust := 'RTA'
var query varchar2(100)
exec :query := 'SELECT * FROM IM WHERE IM_EDIT_DATE = SYSDATE -1 AND IM_CUST = :cust'
var query2 varchar2(100)
exec :query2 := 'SELECT * FROM RM WHERE RM_CUST = :cust'

DECLARE
  TYPE rc_custs IS REF CURSOR RETURN PWIN175.RM%ROWTYPE;
  cur_custs rc_custs;
  rec_custs PWIN175.RM%ROWTYPE;
BEGIN
  OPEN cur_custs FOR SELECT * FROM PWIN175.RM WHERE RM_CUST = :cust;
  FETCH cur_custs INTO rec_custs;
  WHILE cur_custs%FOUND
  LOOP
    Dbms_Output.PUT_LINE(rec_custs.RM_CUST || ' is ' || rec_custs.RM_NAME);
    FETCH cur_custs INTO rec_custs;
  END LOOP;
  CLOSE cur_custs;
    Dbms_Output.PUT_LINE('--Children--------------------------');
  OPEN cur_custs FOR SELECT * FROM PWIN175.RM WHERE RM_PARENT = :cust;
  FETCH cur_custs INTO rec_custs;
  WHILE cur_custs%FOUND
  LOOP
    Dbms_Output.PUT_LINE(rec_custs.RM_CUST || ' is ' || rec_custs.RM_NAME);
    FETCH cur_custs INTO rec_custs;
  END LOOP;
  CLOSE cur_custs;
END;

--this is using a weak ref cursor without RETURN you can reuse cursor for other queries
DECLARE
  TYPE rc_custs IS REF CURSOR;
  --RETURN PWIN175.RM%ROWTYPE;
  cur_custs rc_custs;
  rec_custs PWIN175.RM%ROWTYPE;
  rec_cust_stocks PWIN175.IM%ROWTYPE;
  l_filter   VARCHAR2 (100) := :cust;
BEGIN
  OPEN cur_custs FOR SELECT * FROM PWIN175.RM WHERE RM_CUST = l_filter;
  FETCH cur_custs INTO rec_custs;
  WHILE cur_custs%FOUND
  LOOP
    Dbms_Output.PUT_LINE(rec_custs.RM_CUST || ' is ' || rec_custs.RM_NAME);
    FETCH cur_custs INTO rec_custs;
  END LOOP;
  CLOSE cur_custs;
    Dbms_Output.PUT_LINE('--Stocks--------------------------');
  OPEN cur_custs FOR SELECT * FROM PWIN175.IM WHERE IM_CUST = l_filter;
  FETCH cur_custs INTO rec_cust_stocks;
  WHILE cur_custs%FOUND
  LOOP
    Dbms_Output.PUT_LINE(rec_cust_stocks.IM_CUST || ' has ' || rec_cust_stocks.IM_STOCK);
    FETCH cur_custs INTO rec_cust_stocks;
  END LOOP;
  CLOSE cur_custs;
END;


--this is using a variable for the query with ref cursor without RETURN - reuseable
DECLARE
  TYPE rc_stocks IS REF CURSOR;
  cur_stocks rc_stocks;
  rec_stocks PWIN175.IM%ROWTYPE;
  rec_cust_stocks PWIN175.IM%ROWTYPE;
  v_query VARCHAR2(100);
  --query2 := SELECT * FROM RM WHERE RM_CUST = :cust;
BEGIN
  v_query := 'SELECT IM_CUST,IM_EDIT_DATE FROM PWIN175.IM WHERE IM_EDIT_DATE >= SYSDATE - 1 GROUP BY IM_CUST,IM_EDIT_DATE ';
  OPEN cur_stocks FOR v_query ;
  FETCH cur_stocks INTO rec_stocks;
  WHILE cur_stocks%FOUND
  LOOP
    Dbms_Output.PUT_LINE(rec_stocks.IM_CUST);
    FETCH cur_stocks INTO rec_stocks;
  END LOOP;
  CLOSE cur_stocks;
    Dbms_Output.PUT_LINE('--Stocks--------------------------');
  --v_query := :query2;
  OPEN cur_stocks FOR SELECT * FROM PWIN175.IM WHERE IM_EDIT_DATE >= SYSDATE - 1;
  FETCH cur_stocks INTO rec_cust_stocks;
  WHILE cur_stocks%FOUND
  LOOP
    Dbms_Output.PUT_LINE(rec_cust_stocks.IM_CUST || ' has ' || rec_cust_stocks.IM_STOCK);
    FETCH cur_stocks INTO rec_cust_stocks;
  END LOOP;
  CLOSE cur_stocks;
END;


--Return multiple rows   BULK COLLECT
DECLARE
   CURSOR cust_cur
   IS
      SELECT *
        FROM RM;

   TYPE custs_aat IS TABLE OF RM%ROWTYPE
      INDEX BY PLS_INTEGER;

   l_custs custs_aat;
BEGIN
   OPEN cust_cur;

   LOOP
      FETCH cust_cur
      BULK COLLECT INTO l_custs LIMIT 100;

      EXIT WHEN l_custs.COUNT = 0;

      FOR indx IN 1 .. l_custs.COUNT
      LOOP
         process_cust ( l_custs ( indx ));
      END LOOP;
   END LOOP;

   CLOSE cust_cur;
END;
/




CREATE OR REPLACE PROCEDURE list_stocks(cat IN IM.IM_CAT%TYPE) IS
    TYPE cur_typ IS REF CURSOR;
    cur_list_stocks   cur_typ;
    query_str   VARCHAR2(1000);
    stock_name    VARCHAR2(20);
    cat_name     VARCHAR2(20);
BEGIN
    query_str := 'SELECT IM_STOCK, IM_CUST FROM IM WHERE IM_CAT = cat';
    -- find stocks who belong to the selected cat
    OPEN cur_list_stocks FOR query_str USING cat;
    LOOP
        FETCH cur_list_stocks INTO stock_name, cat_name;
        EXIT WHEN cur_list_stocks%NOTFOUND;
        dbms_Output.PUT_LINE( stock_name || ' EXISTS IN category ' || cat_name);
    END LOOP;
    CLOSE cur_list_stocks;
END;
/
SHOW ERRORS;


EXECUTE list_stocks('RTA_MARITI');




 PROCEDURE GROUP_CUST_LIST
    (tgc_customer_in IN rm.rm_cust%TYPE)
    AS
      nCheckpoint  NUMBER;
    CURSOR tgc_cur IS
      SELECT tgc.sCust, tgc.sGroupCust, tgc.nLevel
      FROM Tmp_Group_Cust tgc
      WHERE tgc.sCust = tgc_customer_in;

    tgc_rec tgc_cur%ROWTYPE;
  BEGIN

    nCheckpoint := 1;
    OPEN tgc_cur;
    FETCH tgc_cur INTO tgc_rec;
    WHILE(tgc_cur%FOUND)
    LOOP
      DBMS_OUTPUT.PUT_LINE(tgc_rec.sCust || ' ' || tgc_rec.sGroupCust || ' - Level ' || tgc_rec.nLevel);
      FETCH tgc_cur INTO tgc_rec;
    END LOOP;
    CLOSE tgc_cur;

    --EXECUTE IMMEDIATE 'SELECT * FROM Tmp_Group_Cust';

    RETURN;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('GROUP_CUST failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END GROUP_CUST_LIST;




BEGIN
    EXECUTE IMMEDIATE 'SELECT * FROM ALL_OBJECTS,ALL_INDEXES';
END;


SELECT /*csv*/ * FROM PWIN175.XQ;
SELECT /*xml*/ * FROM PWIN175.XQ;
SELECT /*html*/ * FROM PWIN175.XQ;
SELECT /*delimited*/ * FROM PWIN175.XQ;
SELECT /*insert*/ * FROM PWIN175.XQ;
SELECT /*loader*/ * FROM PWIN175.XQ;
SELECT /*fixed*/ * FROM PWIN175.XQ;
SELECT /*text*/ * FROM PWIN175.XQ;



create or replace
PACKAGE example_pkg AS

    /*
    ** Record and nested table for "dual" table
    ** It is global, you can use it in other packages
    */
    TYPE g_dual_ntt IS TABLE OF SYS.DUAL%ROWTYPE;
    g_dual  g_dual_ntt;

    /*
    ** procedure is public. You may want to use it in different parts of your code
    */
    FUNCTION myFunct(param1 VARCHAR2) RETURN SYS_REFCURSOR;

    /*
    ** Example to work with a cursor
    */
    PROCEDURE example_prc;

END example_pkg;

create or replace
PACKAGE BODY example_pkg AS

    FUNCTION myFunct(param1 VARCHAR2) RETURN SYS_REFCURSOR
    AS
        myCursor SYS_REFCURSOR;
    BEGIN
        OPEN myCursor FOR
            SELECT  dummy
            FROM    dual
            WHERE   dummy = param1;

        RETURN(myCursor);
    END myFunct;

    PROCEDURE example_prc
    AS
        myCursor SYS_REFCURSOR;
        l_dual   g_dual_ntt; /* With bulk collect there is no need to initialize the collection */
    BEGIN
        -- Open cursor
        myCursor := myFunct('X');
        -- Fetch from cursor  /  all at onece
        FETCH myCursor BULK COLLECT INTO l_dual;
        -- Close cursor
        CLOSE myCursor;

        DBMS_OUTPUT.PUT_LINE('Print: ');
        FOR indx IN 1..l_dual.COUNT LOOP
            DBMS_OUTPUT.PUT_LINE('element: ' || l_dual(indx).dummy );
        END LOOP;
    END example_prc;

END example_pkg;

EXECUTE example_pkg.example_prc();

/*
Print:
element: X
*/


create or replace
PACKAGE example_pkg AS

    /*
    ** Record and nested table for "dual" table
    ** It is global, you can use it in other packages
    */
    TYPE g_dual_ntt IS TABLE OF SYS.DUAL%ROWTYPE;
    g_dual  g_dual_ntt;

    /*
    ** procedure is public. You may want to use it in different parts of your code
    */
    FUNCTION myFunct(param1 VARCHAR2) RETURN SYS_REFCURSOR;

    /*
    ** Example to work with a cursor
    */
    PROCEDURE example_prc;

END example_pkg;

create or replace
PACKAGE BODY example_pkg AS

    FUNCTION myFunct(param1 VARCHAR2) RETURN SYS_REFCURSOR
    AS
        myCursor SYS_REFCURSOR;
    BEGIN
        OPEN myCursor FOR
            SELECT  dummy
            FROM    dual
            WHERE   dummy = param1;

        RETURN(myCursor);
    END myFunct;

    PROCEDURE example_prc
    AS
        myCursor SYS_REFCURSOR;
        l_dual   g_dual_ntt; /* With bulk collect there is no need to initialize the collection */
    BEGIN
        -- Open cursor
        myCursor := myFunct('X');
        -- Fetch from cursor  /  all at onece
        FETCH myCursor BULK COLLECT INTO l_dual;
        -- Close cursor
        CLOSE myCursor;

        DBMS_OUTPUT.PUT_LINE('Print: ');
        FOR indx IN 1..l_dual.COUNT LOOP
            DBMS_OUTPUT.PUT_LINE('element: ' || l_dual(indx).dummy );
        END LOOP;
    END example_prc;

END example_pkg;

EXECUTE example_pkg.example_prc();

/*
Print:
element: X
*/




create or replace function get_dept_emps(p_deptno in VARCHAR2) return sys_refcursor is
  v_rc sys_refcursor;
begin
  open v_rc for select IM_STOCK, IM_CUST, IM_CAT, IM_DESC from IM where IM_STOCK = p_deptno;-- using p_deptno;
  return v_rc;
END get_dept_emps;
/


DECLARE
  CURSOR cust_cur
BEGIN
  get_dept_emps('EX237S');

END





CREATE OR REPLACE PROCEDURE getivr_proc (
   numOfInstances       IN     NUMBER,
   instanceID           IN     NUMBER,
   IOVOrdersForLookUp      OUT sys_refcursor
)
AS
BEGIN
   OPEN IOVOrdersForLookUp FOR
        SELECT   STG.buid,
                 STG.order_num,
                 ONL.BLACKBOX_ID,
                 STG.CUSTOMER_NUM,
                 ONL.IP_ADDRESS,
                 IS_DPIDExists
          FROM      staging_order_data STG
                 INNER JOIN
                    staging_online_data ONL
                 ON STG.order_num = ONL.order_num AND STG.buid = ONL.buid --,ONL.BLACKBOX_ID
         -- Production defect- to avoid picking up same order by multiple instances
         WHERE   NOT EXISTS
                    (SELECT   1
                       FROM   iov_ctd_msg ctd
                      WHERE   ctd.order_num = STG.order_num
                              AND STG.buid = ctd.buid)
                 AND STG.online_queried_flag = 'Y'
                 AND STG.ADDRESS_TYPE = 'S'
                 AND STG.ORDER_STAGING_STATUS_CODE = 'READY_FOR_IOVATION'
                 AND MOD (TO_CHAR (STG.ORDER_DATE, 'ss'), numOfInstances) =
                       instanceID - 1
      ORDER BY   STG.CUSTOMER_NUM, ONL.IP_ADDRESS, STG.modified_date ASC;
END;
/

CREATE OR REPLACE PROCEDURE getivr_proc (
   numOfInstances       IN     NUMBER,
   instanceID           IN     NUMBER,
   IOVOrdersForLookUp      OUT sys_refcursor
)
AS
BEGIN
   OPEN IOVOrdersForLookUp FOR
        SELECT   STG.buid,
                 STG.order_num,
                 ONL.BLACKBOX_ID,
                 STG.CUSTOMER_NUM,
                 ONL.IP_ADDRESS,
                 IS_DPIDExists
          FROM      staging_order_data STG
                 INNER JOIN
                    staging_online_data ONL
                 ON STG.order_num = ONL.order_num AND STG.buid = ONL.buid --,ONL.BLACKBOX_ID
         -- Production defect- to avoid picking up same order by multiple instances
         WHERE   NOT EXISTS
                    (SELECT   1
                       FROM   iov_ctd_msg ctd
                      WHERE   ctd.order_num = STG.order_num
                              AND STG.buid = ctd.buid)
                 AND STG.online_queried_flag = 'Y'
                 AND STG.ADDRESS_TYPE = 'S'
                 AND STG.ORDER_STAGING_STATUS_CODE = 'READY_FOR_IOVATION'
                 AND MOD (TO_CHAR (STG.ORDER_DATE, 'ss'), numOfInstances) =
                       instanceID - 1
      ORDER BY   STG.CUSTOMER_NUM, ONL.IP_ADDRESS, STG.modified_date ASC;
END;
/



CREATE OR REPLACE PROCEDURE getivr_proc (
   sCust       IN     VARCHAR,
   instanceID           IN     NUMBER,
   IOVOrdersForLookUp      OUT sys_refcursor
)
AS
BEGIN
   OPEN IOVOrdersForLookUp FOR
        SELECT IM_STOCK,IM_CUST, IM_CAT, IM_DESC FROM IM WHERE IM_CUST = getivr_proc.sCust;
END;
/


DECLARE
  v_rc    sys_refcursor;
BEGIN
  v_rc := get_dept_emps(10);  -- This returns an open cursor
  dbms_output.put_line('Rows: '||v_rc%ROWCOUNT);
  close v_rc;
END;



DECLARE
  v_rc    sys_refcursor;
  v_stock varchar2(20);
  v_cust  varchar2(20);
  v_cat   number;
  v_desc   number;
BEGIN
   v_rc := get_dept_emps('ZIONS');  -- This returns an open cursor
   LOOP
   fetch v_rc into v_stock, v_cust, v_cat, v_desc;
   exit when v_rc%NOTFOUND;  -- Exit the loop when we've run out of data
   dbms_output.put_line('Row: '||v_rc%ROWCOUNT||' # '||v_stock||','||v_cust||','||v_cat||','||v_desc);
   end loop;
   close v_rc;
   fetch v_rc into v_stock, v_cust, v_cat, v_desc;
END;


EXECUTE  getivr_proc('ZIONS',0,)


CREATE OR REPLACE FUNCTION f_getDisplay
	(i_column_tx VARCHAR2,
	 i_table_select_tx VARCHAR2,
	 i_field_tx VARCHAR2,
   i_value_tx VARCHAR2)
	RETURN VARCHAR2
	IS
		v_out_tx VARCHAR2(2000);
		v_sql_tx VARCHAR2(2000);
	BEGIN
		v_sql_tx := 'SELECT ' ||
		            i_column_tx||
		            ' FROM '||i_table_select_tx||
		            ' WHERE '||i_field_tx||' =:4';
	EXECUTE IMMEDIATE v_sql_tx INTO v_out_tx
		USING i_value_tx;
	RETURN v_out_tx;
END f_getDisplay;




var total_despatches_tx VARCHAR2(500)
EXEC SELECT f_getDisplay('IR_BRAND','IR','IR_BRAND','AAS_ACIRT') INTO :total_despatches_tx FROM DUAL;


CREATE OR REPLACE TYPE lov_oty AS OBJECT
  (brand_tx VARCHAR2(256), desc_tx VARCHAR2(256));

CREATE OR REPLACE FUNCTION f_getDisplay_oty
	(i_column_tx VARCHAR2,
   i_column2_tx VARCHAR2,
	 i_table_select_tx VARCHAR2,
	 i_field_tx VARCHAR2,
   i_value_tx NUMBER)
	RETURN lov_oty
	IS
		v_out_tx lov_oty;
		v_sql_tx VARCHAR2(2000);
	BEGIN
		v_sql_tx := 'SELECT lov_oty('||
		            i_column_tx||','||i_column2_tx||
		            ') FROM '||i_table_select_tx||
		            ' WHERE '||i_column_tx||' =:5';
	EXECUTE IMMEDIATE v_sql_tx INTO v_out_tx
		USING i_value_tx;
	RETURN v_out_tx;
END f_getDisplay_oty;


CREATE OR REPLACE FUNCTION f_getDisplay_oty
	(i_column_tx VARCHAR2,
   i_column2_tx VARCHAR2,
	 i_table_select_tx VARCHAR2,
	 i_field_tx VARCHAR2,
   i_value_tx NUMBER)
	RETURN lov_oty
	IS
		v_out_tx lov_oty;
		v_sql_tx VARCHAR2(2000);
	BEGIN
		v_sql_tx := 'SELECT lov_oty('||
		            'ID,'||i_column2_tx||
		            ') FROM '||i_table_select_tx||
		            ' WHERE '||i_column_tx||' =:5';
	EXECUTE IMMEDIATE v_sql_tx INTO v_out_tx
		USING i_value_tx;
	RETURN v_out_tx;
END f_getDisplay_oty;

var total_despatches2_tx VARCHAR2(500)
EXEC SELECT f_getDisplay_oty('ID','IR_DESC','IR','IR_BRAND','155') INTO :total_despatches2_tx FROM DUAL;





