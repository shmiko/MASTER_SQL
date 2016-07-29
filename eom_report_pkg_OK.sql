CREATE OR REPLACE PACKAGE eom_report_pkg
IS
  --/*decalre variables These are being declared via the stored procedure - just need to redeclare cust so as we can get the rates*/
  cust                  VARCHAR2(20) := 'TABCORP';
  ordernum              CONSTANT VARCHAR2(20) := '1363806';
  stock                 CONSTANT VARCHAR2(20) := 'COURIER';
  source                CONSTANT VARCHAR2(20) := 'BSPRINTNSW';
  sAnalysis             CONSTANT VARCHAR2(20) := '21VICP';
  --/*exec SELECT  RM_ANAL INTO :sAnalysis FROM RM where RM_CUST = :cust;*/
  anal                  CONSTANT VARCHAR2(20) := '21VICP';
  start_date            CONSTANT VARCHAR2(20) := To_Date('01-Jan-2014');
  end_date              CONSTANT VARCHAR2(20) := To_Date('28-Feb-2014');
  AdjustedDespDate      CONSTANT VARCHAR2(20) := To_Date('28-Feb-2014');
  AnotherCust           CONSTANT VARCHAR2(20) := 'BEYONDBLUE';
  warehouse             CONSTANT VARCHAR2(20) := 'SYDNEY';
  AnotherWwarehouse     CONSTANT VARCHAR2(20) := 'MELBOURNE';
  month_date            CONSTANT VARCHAR2(20) := substr(end_date,4,3);
  year_date             CONSTANT VARCHAR2(20) := substr(end_date,8,2);
  CutOffOrderAddTime    CONSTANT NUMBER       := ('120000');
  CutOffDespTimeSameDay CONSTANT NUMBER       := ('235959');
  CutOffDespTimeNextDay CONSTANT NUMBER       := ('120000');
  starting_date         CONSTANT DATE         := SYSDATE;
  ending_date           CONSTANT DATE         := ADD_MONTHS (SYSDATE, 120);
  status                CONSTANT NUMBER       := 3;
  order_limit           CONSTANT NUMBER       := 1;

  closed_status     CONSTANT VARCHAR2(1) := 'C';
  open_status       CONSTANT VARCHAR2(1) := 'O';
  active_status     CONSTANT VARCHAR2(1) := 'A';
  inactive_status   CONSTANT VARCHAR2(1) := 'I';

  min_difference    CONSTANT NUMBER := 1;
  max_difference    CONSTANT NUMBER := 100;

  earliest_date     CONSTANT DATE := SYSDATE;
  latest_date       CONSTANT DATE := ADD_MONTHS (SYSDATE, 120);


   FUNCTION total_orders( rm_cust_in IN rm.rm_cust%TYPE,
    status_in IN sh.sh_status%TYPE:=NULL,
    sh_add_in IN sh.sh_add_date%TYPE)
    RETURN NUMBER;

  FUNCTION total_despatches
    ( d_rm_cust_in IN rm.rm_cust%TYPE,
    d_status_in IN sh.sh_status%TYPE:=NULL,
    st_add_in IN st.st_desp_date%TYPE)
  RETURN NUMBER;

  PROCEDURE GROUP_CUST_START;

  PROCEDURE GROUP_CUST_GET
    (gc_customer_in IN rm.rm_cust%TYPE);

  PROCEDURE GROUP_CUST_LIST
    (tgc_customer_in IN rm.rm_cust%TYPE);





END eom_report_pkg;
/

CREATE OR REPLACE PACKAGE BODY eom_report_pkg
AS
  --Get TotalOrders for day for cust
  FUNCTION total_orders
    ( rm_cust_in IN rm.rm_cust%TYPE,
    status_in IN sh.sh_status%TYPE:=NULL,
    sh_add_in IN sh.sh_add_date%TYPE)
  RETURN NUMBER
  IS
    --Internal  UPPER status code
    status_int sh.sh_status%TYPE:=Upper(status_in);

    --Parameterised cursor returns total orders
    CURSOR order_cur (status_in IN sh.sh_status%TYPE)   IS
      SELECT Count(SH_ORDER)
        FROM SH
      WHERE sh.sh_cust = rm_cust_in
      AND sh_status NOT LIKE status_in
      AND sh.sh_add_date >= sh_add_in;


      --Return value for function
      return_value NUMBER;
  BEGIN
    OPEN order_cur (status_int);
    FETCH order_cur INTO return_value;
    IF order_cur%NOTFOUND
    THEN
      CLOSE order_cur;
      RETURN NULL;
    ELSE
      CLOSE order_cur;
      RETURN return_value;
    END IF;
  END total_orders;


  --Get TotalDespatches for day for cust
  FUNCTION total_despatches
    ( d_rm_cust_in IN rm.rm_cust%TYPE,
    d_status_in IN sh.sh_status%TYPE:=NULL,
    st_add_in IN st.st_desp_date%TYPE)
  RETURN NUMBER
  IS
    --Internal  UPPER status code
    status_int2 sh.sh_status%TYPE:=Upper(d_status_in);

    --Parameterised cursor returns total orders
    CURSOR desp_cur (status_in IN sh.sh_status%TYPE)   IS
      SELECT Count(SH_ORDER)
        FROM ST,SH
      WHERE ST_ORDER = SH_ORDER
      AND sh.sh_cust = d_rm_cust_in
      AND sh_status NOT LIKE d_status_in
      AND st.st_desp_date >= st_add_in;


      --Return value for function
      return_desp_value NUMBER;
  BEGIN
    OPEN desp_cur (status_int2);
    FETCH desp_cur INTO return_desp_value;
    IF desp_cur%NOTFOUND
    THEN
      CLOSE desp_cur;
      RETURN NULL;
    ELSE
      CLOSE desp_cur;
      RETURN return_desp_value;
    END IF;
  END total_despatches;



  --Group Cust Procedure - Creates temp table of all customers grouped into top level parent
  PROCEDURE GROUP_CUST_START AS
    nCheckpoint  NUMBER;
  BEGIN

    nCheckpoint := 1;
    EXECUTE IMMEDIATE	'TRUNCATE  TABLE Tmp_Group_Cust';


    nCheckpoint := 2;
    EXECUTE IMMEDIATE 'INSERT into Tmp_Group_Cust(sCust,sGroupCust,nLevel )
                        SELECT RM_CUST
                          ,(
                            CASE
                              WHEN LEVEL = 1 THEN RM_CUST
                              WHEN LEVEL = 2 THEN RM_PARENT
                              WHEN LEVEL = 3 THEN PRIOR RM_PARENT
                              ELSE NULL
                            END
                          ) AS CC
                          ,LEVEL
                    FROM RM
                    WHERE RM_TYPE = 0
                    AND RM_ACTIVE = 1
                    --AND Length(RM_GROUP_CUST) <=  1
                    CONNECT BY PRIOR RM_CUST = RM_PARENT
                    START WITH Length(RM_PARENT) <= 1';


    DBMS_OUTPUT.PUT_LINE('Successfully truncated, recreated AND populated Tmp_Group_Cust');


    RETURN;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('GROUP_CUST_START failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END GROUP_CUST_START;



  PROCEDURE GROUP_CUST_GET
    (gc_customer_in IN rm.rm_cust%TYPE)
    AS
    CURSOR gc_cur IS
      SELECT r.rm_cust, r.rm_name
      FROM rm r
      WHERE r.rm_cust = gc_customer_in
      ORDER BY r.rm_cust;
    gc_rec gc_cur%ROWTYPE;
  BEGIN
    OPEN gc_cur;
    FETCH gc_cur INTO gc_rec;
    WHILE(gc_cur%FOUND)
    LOOP
      DBMS_OUTPUT.PUT_LINE(gc_rec.rm_cust || '-' || gc_rec.rm_name);
      FETCH gc_cur INTO gc_rec;
    END LOOP;
    CLOSE gc_cur;
  END GROUP_CUST_GET;

  PROCEDURE GROUP_CUST_LIST
    (tgc_customer_in IN rm.rm_cust%TYPE)
    AS
      nCheckpoint  NUMBER;
    CURSOR tgc_cur IS
      SELECT tgc.sCust, tgc.sGroupCust
      FROM Tmp_Group_Cust tgc
      WHERE tgc.sCust = tgc_customer_in;

    tgc_rec tgc_cur%ROWTYPE;
  BEGIN

    nCheckpoint := 1;
    OPEN tgc_cur;
    FETCH tgc_cur INTO tgc_rec;
    WHILE(tgc_cur%FOUND)
    LOOP
      DBMS_OUTPUT.PUT_LINE(tgc_rec.sCust || ' ' || tgc_rec.sGroupCust);
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








END eom_report_pkg;
/

/*
--Test total_orders function
SELECT :cust As Customer ,
  CASE
    WHEN total_orders(:cust,:status,:start_date) > :order_limit  THEN total_orders(:cust,:status,:start_date)
    ELSE NULL
    END AS "Todays Orders"
FROM RM
WHERE RM_PARENT = :cust
GROUP BY :cust



--Test total_despatches function

SELECT :cust As Customer ,
  CASE
    WHEN eom_report_pkg.total_despatches(:cust,:status,:start_date) > :order_limit  THEN eom_report_pkg.total_despatches(:cust,:status,:start_date)
    ELSE NULL
    END AS "Todays Orders"
FROM RM
WHERE RM_PARENT = :cust
GROUP BY :cust

var total_despatches NUMBER
exec SELECT  total_despatches(:cust,:status,:start_date) INTO :total_despatches FROM DUAL;

var total_despatches2 NUMBER
EXEC :total_despatches := total_despatches(:cust,:status,:start_date);      */

/*Test EXECUTE GROUP_CUST_START;
EXECUTE GROUP_CUST_START;        */


/*Test EXECUTE GROUP_CUST_START;
EXECUTE GROUP_CUST_GET(:cust);        */

 -- Calling the function from a MAIN BODY
  --BEGIN
  --EXECUTE eom_report_pkg.GROUP_CUST_LIST(:CUST);
  --END;