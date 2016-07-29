

CREATE OR REPLACE PACKAGE eom_report_pkg
IS



  --TYPE t_ref_cursor IS REF CURSOR;

  --/*decalre variables These are being declared via the stored procedure - just need to redeclare cust so as we can get the rates*/
  cust                  CONSTANT VARCHAR2(20) := 'TABCORP';
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



  FUNCTION BREAK_UNIT_PRICE
                  ( rm_cust_in IN rm.RM_GROUP_CUST%TYPE,
                    stock_in   IN Tmp_Admin_Data_BreakPrices.vIIStock%TYPE)
  RETURN NUMBER;

  FUNCTION F_BREAK_UNIT_PRICE2
                  ( rm_cust_in IN II.II_CUST%TYPE,
                    stock_in   IN II.II_STOCK%TYPE)
  RETURN NUMBER;

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
    EXECUTE IMMEDIATE     'TRUNCATE  TABLE Tmp_Group_Cust';


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


  --List cust and name
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


  --List cust name, group cust and level
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

   PROCEDURE DESP_STOCK_GET    (
              cdsg_date_from_in IN  SH.SH_ADD_DATE%TYPE,
              cdsg_date_to_in IN  SH.SH_EDIT_DATE%TYPE,
              cdsg_cust_in IN RM.RM_CUST%TYPE
              ) AS

   CURSOR cdsg_cur IS
   SELECT    SH.SH_CUST,  RM.RM_PARENT, SH.SH_ORDER,  SH.SH_SPARE_STR_5,SH.SH_CUST_REF,SH.SH_ADDRESS,SH.SH_SUBURB,
          SH.SH_CITY, SH.SH_STATE , SH.SH_POST_CODE , SH.SH_NOTE_1 ,SH.SH_NOTE_2 ,SH.SH_SPARE_DBL_9
     FROM      PWIN175.SH INNER JOIN PWIN175.RM  ON RM.RM_CUST  = SH.SH_CUST
  WHERE SH.SH_STATUS <> 3
  AND     RM.RM_CUST = cdsg_cust_in
     AND       SH.SH_ADD_DATE >= cdsg_date_from_in AND SH.SH_ADD_DATE <= cdsg_date_to_in
     GROUP BY SH.SH_CUST,  RM.RM_PARENT, SH.SH_ORDER,  SH.SH_SPARE_STR_5,SH.SH_CUST_REF,SH.SH_ADDRESS,SH.SH_SUBURB,
          SH.SH_CITY, SH.SH_STATE , SH.SH_POST_CODE , SH.SH_NOTE_1 ,SH.SH_NOTE_2 ,SH.SH_SPARE_DBL_9;
    cdsg_rec cdsg_cur%ROWTYPE;
  BEGIN
    OPEN cdsg_cur;
    FETCH cdsg_cur INTO cdsg_rec;
    WHILE cdsg_cur%FOUND
    LOOP
      DBMS_OUTPUT.PUT_LINE(cdsg_rec.SH_CUST || ',' || cdsg_rec.RM_PARENT || ',' || cdsg_rec.SH_SPARE_STR_5 || ',' || cdsg_rec.SH_ORDER || ',' || cdsg_rec.SH_SPARE_DBL_9 || ',' || cdsg_rec.SH_NOTE_2 || ',' || cdsg_rec.SH_NOTE_1 || ',' || cdsg_rec.SH_CITY );
      FETCH cdsg_cur INTO cdsg_rec;
    END LOOP;
  CLOSE cdsg_cur;
END DESP_STOCK_GET;




FUNCTION BREAK_UNIT_PRICE
                  ( rm_cust_in IN rm.RM_GROUP_CUST%TYPE,
                    stock_in   IN Tmp_Admin_Data_BreakPrices.vIIStock%TYPE)
  RETURN NUMBER
  IS
    /*Internal  UPPER status code */
    --status_int sh.sh_status%TYPE:=Upper(status_in);

    /*Parameterised cursor returns total orders */
    CURSOR break_price_cur IS
      SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = stock_in AND vIICust = rm_cust_in;


      /*Return value for function */
      return_value NUMBER;
  BEGIN
    OPEN break_price_cur;
    FETCH break_price_cur INTO return_value;
    IF break_price_cur%NOTFOUND
    THEN
      CLOSE break_price_cur;
      RETURN NULL;
    ELSE
      CLOSE break_price_cur;
      RETURN return_value;
    END IF;
  END BREAK_UNIT_PRICE;

FUNCTION F_BREAK_UNIT_PRICE2
                  ( rm_cust_in IN rm.RM_GROUP_CUST%TYPE,
                    stock_in   IN Tmp_Admin_Data_BreakPrices.vIIStock%TYPE)
  RETURN NUMBER
  IS
    /*Internal  UPPER status code */
    --status_int sh.sh_status%TYPE:=Upper(status_in);

    /*Parameterised cursor returns total orders */
    CURSOR break_price_cur IS
      SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = stock_in AND vIICust = rm_cust_in;


      /*Return value for function */
      return_value NUMBER;
  BEGIN
    OPEN break_price_cur;
    FETCH break_price_cur INTO return_value;
    IF break_price_cur%NOTFOUND
    THEN
      CLOSE break_price_cur;
      RETURN NULL;
    ELSE
      CLOSE break_price_cur;
      RETURN return_value;
    END IF;
  END F_BREAK_UNIT_PRICE2;

FUNCTION F_BREAK_UNIT_PRICE2
                  ( rm_cust_in IN II.II_CUST%TYPE,
                    stock_in   IN II.II_STOCK%TYPE)
  RETURN NUMBER

  AS

  price_break NUMBER;

  BEGIN
    IF stock_in IS NOT NULL THEN
        SELECT II_BREAK_LCL
        INTO  price_break
           FROM II
           WHERE II_BREAK_LCL > 0.000001
        AND II_STOCK = stock_in
           AND II_CUST= rm_cust_in;
        --price_in := II.II_BREAK_LCL;
        RETURN price_break;
    ELSE
      RETURN 'N/A';
    END IF;
  END F_BREAK_UNIT_PRICE2;


END eom_report_pkg;
/

/*TESTING
--Test total_orders function
SELECT RM_PARENT As Customer ,
  CASE
    WHEN report_pkg.total_orders('TABCORP',3,'1-Apr-2014') > 1  THEN report_pkg.total_orders('TABCORP',3,'1-Apr-2014')
    ELSE NULL
    END AS "Todays Orders"
FROM RM
WHERE RM_PARENT = 'TABCORP'
GROUP BY :cust



--Test total_despatches function

SELECT :cust As Customer ,
  CASE
    WHEN total_despatches(:cust,:status,:start_date) > :order_limit  THEN total_despatches(:cust,:status,:start_date)
    ELSE NULL
    END AS "Todays Orders"
FROM RM
WHERE RM_PARENT = :cust
GROUP BY :cust

var total_despatches NUMBER
EXEC SELECT eom_report_pkg.total_despatches('TABCORP',3,'1-Apr-2014') INTO :total_despatches FROM DUAL;

var total_despatches2 NUMBER
EXEC :total_despatches := total_despatches(:cust,:status,:start_date);

/*Test EXECUTE GROUP_CUST_START;
EXECUTE report_pkg.GROUP_CUST_START;        */


/*Test EXECUTE GROUP_CUST_START;
EXECUTE report_pkg.GROUP_CUST_GET(:cust);
EXECUTE report_pkg.GROUP_CUST_GET('RTA');

-- Calling the function from an anonymous block
  --BEGIN
  -- GROUP_CUST_LIST(CUST);
  --END;
--EXECUTE report_pkg.GROUP_CUST_LIST(:cust)


SELECT :cust As Customer ,
  CASE
    WHEN total_orders(:cust,:status,:start_date) > :order_limit  THEN total_orders(:cust,:status,:start_date)
    ELSE NULL
    END AS "Todays Orders"
FROM RM
WHERE RM_PARENT = :cust
GROUP BY :cust


EXECUTE eom_report_pkg.DESP_STOCK_GET('1-Apr-2014','7-Apr_2014','RTA')


var breakprice NUMBER
breakprice = 1
exec SELECT   eom_report_pkg.F_BREAK_UNIT_PRICE2('WAGVICAG','500290') INTO :breakprice FROM DUAL;

*/

create or replace PROCEDURE get_desp_stocks (
               gds_cust_in IN IM.IM_CUST%TYPE,
               gds_cust_not_in IN  IM.IM_CUST%TYPE,
               gds_nx_ext_type_in IN NI.NI_NV_EXT_TYPE%TYPE,
               gds_stock_not_in IN IM.IM_STOCK%TYPE,
               gds_stock_not_in2 IN IM.IM_STOCK%TYPE,
               gds_start_date_in IN SH.SH_EDIT_DATE%TYPE,
               gds_end_date_in IN SH.SH_ADD_DATE%TYPE
               --gds_src_get_desp_stocks  IN  OUT sys_refcursor
)
AS
CURSOR gds_src_get_desp_stocks IS
     SELECT    SH.SH_CUST
                        ,SH.SH_ORDER
                     ,substr(To_Char(ST.ST_DESP_DATE),0,10)
                  ,SD.SD_STOCK
                        ,SD.SD_DESC
                       , CASE  WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in   AND IM.IM_OWNED_BY = 0 THEN SD.SD_SELL_PRICE
                               WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in   AND IM.IM_OWNED_BY = 1 THEN NI.NI_SELL_VALUE/NI_NX_QUANTITY
                      WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in   AND eom_report_pkg.F_BREAK_UNIT_PRICE2(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NOT NULL THEN eom_report_pkg.F_BREAK_UNIT_PRICE2(RM_GROUP_CUST,SD_STOCK)
                               WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in   AND eom_report_pkg.F_BREAK_UNIT_PRICE2(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NULL THEN  SD_XX_OW_UNIT_PRICE
                               ELSE NULL
                               END
                     ,IM.IM_BRAND
     FROM  PWIN175.SD
                 RIGHT JOIN PWIN175.SH  ON SH.SH_ORDER  = SD.SD_ORDER
                 LEFT JOIN PWIN175.ST  ON ST.ST_PICK  = SD.SD_LAST_PICK_NUM
        LEFT JOIN PWIN175.SL   ON SL.SL_PICK   = ST.ST_PICK
                 INNER JOIN PWIN175.RM  ON RM.RM_CUST  = SH.SH_CUST
                 INNER JOIN PWIN175.IM  ON IM.IM_STOCK = SD.SD_STOCK
        INNER JOIN PWIN175.NI  ON NI.NI_NV_EXT_KEY = SL.SL_UID
  WHERE NI.NI_STRENGTH = 3 AND NI.NI_DATE = ST.ST_DESP_DATE AND NI.NI_STOCK = SD_STOCK AND NI.NI_STATUS <> 0
     AND     SH.SH_STATUS <> 3
  AND     IM.IM_CUST IN (gds_cust_in)
     AND       SH.SH_ORDER = ST.ST_ORDER
  AND       ST.ST_DESP_DATE >= TO_DATE(gds_start_date_in) AND ST.ST_DESP_DATE <= TO_DATE(gds_end_date_in)
     --AND       ST.ST_DESP_DATE >= '10-APR-2014' AND ST.ST_DESP_DATE <= '15-APR-2014'

     AND       SD.SD_LAST_PICK_NUM = ST.ST_PICK
     GROUP BY  SH.SH_CUST,SH.SH_ORDER,
                     ST.ST_DESP_DATE,
                     SD.SD_DESC,SD.SD_STOCK,SD.SD_XX_OW_UNIT_PRICE,SD.SD_SELL_PRICE,
            IM.IM_BRAND,IM.IM_OWNED_BY,IM.IM_CUST,
            NI.NI_SELL_VALUE,NI.NI_NX_QUANTITY,
            RM.RM_GROUP_CUST;
            gds_rec gds_src_get_desp_stocks%ROWTYPE;
  BEGIN
    OPEN  gds_src_get_desp_stocks;
    FETCH gds_src_get_desp_stocks INTO  gds_rec;
    WHILE gds_src_get_desp_stocks%FOUND
    LOOP
      Dbms_Output.PUT_LINE('Row: '||gds_src_get_desp_stocks%ROWCOUNT||' # '|| gds_rec.SH_ORDER);
      FETCH gds_src_get_desp_stocks INTO gds_rec;
    END LOOP;
    CLOSE gds_src_get_desp_stocks;
    Dbms_Output.PUT_LINE('finished for cust '||gds_cust_in );
END get_desp_stocks;

BEGIN
get_desp_stocks('LUXOTTICA','TABCORP',1080105,'COURIER','COURIERS','20-APR-2014','28-APR-2014');
END;


BEGIN
  eom_report_pkg.get_desp_stocks('LUXOTTICA','TABCORP',1080105,'COURIER','COURIERS','20-APR-2014','28-APR-2014');
END;




*********************************************************************************************************************************


create or replace PACKAGE eom_report_pkg
IS

    TYPE custtype IS RECORD
      (
      cust    VARCHAR2(20)
      ,coynum VARCHAR2(20)
      ,rep    VARCHAR2(20)
      ,bank   VARCHAR2(20)
      );

    /* /*  TYPE lov_oty AS OBJECT
      (
      brand_tx VARCHAR2(10)
      ,desc_tx VARCHAR2(25)
      );
    */
    TYPE myBrandType IS RECORD
      (
      brand_tx VARCHAR2(10)
      ,desc_tx VARCHAR2(25)
      );

    --/*decalre variables These are being declared via the stored procedure - just need to redeclare cust so as we can get the rates*/
    cust                  CONSTANT VARCHAR2(20) := 'TABCORP';
    ordernum              CONSTANT VARCHAR2(20) := '1363806';
    stock                 CONSTANT VARCHAR2(20) := 'COURIER';
    source                CONSTANT VARCHAR2(20) := 'BSPRINTNSW';
    sAnalysis             CONSTANT VARCHAR2(20) := '21VICP';
    anal                  CONSTANT VARCHAR2(20) := '21VICP';
    start_date            CONSTANT VARCHAR2(20) := To_Date('01-Jan-2014');
    end_date              CONSTANT VARCHAR2(20) := To_Date('28-Feb-2014');
    AdjustedDespDate      CONSTANT VARCHAR2(20) := To_Date('28-Feb-2014');
    AnotherCust           CONSTANT VARCHAR2(20) := 'BEYONDBLUE';
    warehouse             CONSTANT VARCHAR2(20) := 'SYDNEY';
    AnotherWwarehouse     CONSTANT VARCHAR2(20) := 'MELBOURNE';
    month_date            CONSTANT VARCHAR2(20) := substr(end_date,4,3);
    year_date             CONSTANT VARCHAR2(20) := substr(end_date,8,2);
    closed_status         CONSTANT VARCHAR2(1)  := 'C';
    open_status           CONSTANT VARCHAR2(1)  := 'O';
    active_status         CONSTANT VARCHAR2(1)  := 'A';
    inactive_status       CONSTANT VARCHAR2(1)  := 'I';

    CutOffOrderAddTime    CONSTANT NUMBER       := ('120000');
    CutOffDespTimeSameDay CONSTANT NUMBER       := ('235959');
    CutOffDespTimeNextDay CONSTANT NUMBER       := ('120000');
    status                CONSTANT NUMBER       := 3;
    order_limit           CONSTANT NUMBER       := 1;
    min_difference        CONSTANT NUMBER       := 1;
    max_difference        CONSTANT NUMBER       := 100;

    starting_date         CONSTANT DATE         := SYSDATE;
    ending_date           CONSTANT DATE         := ADD_MONTHS (SYSDATE, 120);
    earliest_date         CONSTANT DATE         := SYSDATE;
    latest_date           CONSTANT DATE         := ADD_MONTHS (SYSDATE, 120);


    TYPE stock_rec_type IS RECORD
      (
      gv_Cust_type       RM.RM_CUST%TYPE
      ,gv_OrderNum_type   SH.SH_ORDER%TYPE
      ,gv_DespDate_type   ST.ST_DESP_DATE%TYPE
      ,gv_Stock_type      SD.SD_STOCK%TYPE
      ,gv_UnitPrice_type  NUMBER(10,4)
      ,gv_Brand_type      IM.IM_BRAND%TYPE
      );

    TYPE stock_ref_cur IS REF CURSOR RETURN stock_rec_type;

    FUNCTION total_orders
      (
      rm_cust_in IN rm.rm_cust%TYPE
      ,status_in IN sh.sh_status%TYPE:=NULL
      ,sh_add_in IN sh.sh_add_date%TYPE
      )
      RETURN NUMBER;

    FUNCTION total_despatches
      (
      d_rm_cust_in IN rm.rm_cust%TYPE
      ,d_status_in IN sh.sh_status%TYPE:=NULL
      ,st_add_in IN st.st_desp_date%TYPE
      )
      RETURN NUMBER;

    PROCEDURE GROUP_CUST_START;

    PROCEDURE GROUP_CUST_GET
      (
      gc_customer_in IN rm.rm_cust%TYPE
      );

    PROCEDURE GROUP_CUST_LIST
      (
      tgc_customer_in IN rm.rm_cust%TYPE
      );

    PROCEDURE DESP_STOCK_GET
      (
      cdsg_date_from_in IN  SH.SH_ADD_DATE%TYPE
      ,cdsg_date_to_in IN  SH.SH_EDIT_DATE%TYPE
      ,cdsg_cust_in IN RM.RM_CUST%TYPE
      );

    FUNCTION F_BREAK_UNIT_PRICE
      (
      rm_cust_in IN II.II_CUST%TYPE
      ,stock_in   IN II.II_STOCK%TYPE
      )
      RETURN NUMBER;

    PROCEDURE get_desp_stocks_cur_p
      (
               gds_cust_in IN IM.IM_CUST%TYPE
               ,gds_cust_not_in IN  IM.IM_CUST%TYPE
               ,gds_stock_not_in IN IM.IM_STOCK%TYPE
               ,gds_stock_not_in2 IN IM.IM_STOCK%TYPE
               ,gds_start_date_in IN SH.SH_EDIT_DATE%TYPE
               ,gds_end_date_in IN SH.SH_ADD_DATE%TYPE
               ,desp_stock_list_cur_var IN OUT stock_ref_cur
      );

    PROCEDURE get_desp_stocks_curp
      (
               gds_cust_in IN IM.IM_CUST%TYPE
               ,gds_cust_not_in IN  IM.IM_CUST%TYPE
               --,gds_nx_ext_type_in IN NI.NI_NV_EXT_TYPE%TYPE
               ,gds_stock_not_in IN IM.IM_STOCK%TYPE
               ,gds_stock_not_in2 IN IM.IM_STOCK%TYPE
               ,gds_start_date_in IN SH.SH_EDIT_DATE%TYPE
               ,gds_end_date_in IN SH.SH_ADD_DATE%TYPE
               ,gds_src_get_desp_stocks OUT sys_refcursor
      );

    PROCEDURE myproc_test_via_PHP
      (
      p1 IN NUMBER
      ,p2 IN OUT NUMBER
      );

    PROCEDURE list_stocks
      (
      cat IN IM.IM_CAT%TYPE
      );

    PROCEDURE quick_function_test
      (
      p_rc OUT SYS_REFCURSOR
      );

    PROCEDURE test_get_brand;

    FUNCTION f_getDisplay
      (
      i_column_tx VARCHAR2
      ,i_table_select_tx VARCHAR2
      ,i_field_tx VARCHAR2
      ,i_value_tx VARCHAR2
      )
      RETURN VARCHAR2;

    FUNCTION f_getDisplay_from_type_bind
      (
      i_first_col IN VARCHAR2
      ,i_value_tx IN VARCHAR2
      )
      RETURN myBrandType;

    FUNCTION f_getDisplay_oty
      (
      i_column_tx VARCHAR2
      ,i_column2_tx VARCHAR2
      ,i_table_select_tx VARCHAR2
      ,i_field_tx VARCHAR2
      ,i_value_tx NUMBER
      )
      RETURN VARCHAR2;

    FUNCTION get_cust_stocks
      (
      r_coy_num in VARCHAR
      )
      RETURN sys_refcursor;

    /* FUNCTION populate_custs
      (
      coynum in VARCHAR := null
      )
      RETURN  custtype;
    */

    FUNCTION refcursor_function
      RETURN SYS_REFCURSOR;


END eom_report_pkg;



create or replace PACKAGE BODY eom_report_pkg
AS

    --TYPE myBrandTableType AS TABLE OF myBrandType;

    --TYPE t_custtype AS TABLE OF custtype;

    --Get TotalOrders for day for cust
    FUNCTION total_orders
      (
      rm_cust_in IN rm.rm_cust%TYPE
      ,status_in IN sh.sh_status%TYPE:=NULL
      ,sh_add_in IN sh.sh_add_date%TYPE
      )
    RETURN NUMBER
    IS
      --Internal  UPPER status code
      status_int sh.sh_status%TYPE:=Upper(status_in);

      --Parameterised cursor returns total orders
      CURSOR order_cur
        (
        status_in IN sh.sh_status%TYPE
        )   IS
        SELECT Count(SH_ORDER)
          FROM SH
        WHERE sh.sh_cust = rm_cust_in
        AND sh_status NOT LIKE status_in
        AND sh.sh_add_date >= sh_add_in;

        --Return value for function
        return_value NUMBER;
    BEGIN
      OPEN order_cur(status_int);
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
      (
      d_rm_cust_in IN rm.rm_cust%TYPE
      ,d_status_in IN sh.sh_status%TYPE:=NULL
      ,st_add_in IN st.st_desp_date%TYPE
      )
    RETURN NUMBER
    IS
      --Internal  UPPER status code
      status_int2 sh.sh_status%TYPE:=Upper(d_status_in);

      --Parameterised cursor returns total orders
      CURSOR desp_cur
        (
        status_in IN sh.sh_status%TYPE
        )   IS
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
      EXECUTE IMMEDIATE     'TRUNCATE  TABLE Tmp_Group_Cust';


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

    --List cust and name
    PROCEDURE GROUP_CUST_GET
      (
      gc_customer_in IN rm.rm_cust%TYPE
      )
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

    --List cust name, group cust and level
    PROCEDURE GROUP_CUST_LIST
      (
      tgc_customer_in IN rm.rm_cust%TYPE
      )
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

    PROCEDURE DESP_STOCK_GET
      (
      cdsg_date_from_in IN  SH.SH_ADD_DATE%TYPE
      ,cdsg_date_to_in IN  SH.SH_EDIT_DATE%TYPE
      ,cdsg_cust_in IN RM.RM_CUST%TYPE
      ) AS
     CURSOR cdsg_cur IS
     SELECT    SH.SH_CUST,  RM.RM_PARENT, SH.SH_ORDER,  SH.SH_SPARE_STR_5,SH.SH_CUST_REF,SH.SH_ADDRESS,SH.SH_SUBURB,
      SH.SH_CITY, SH.SH_STATE , SH.SH_POST_CODE , SH.SH_NOTE_1 ,SH.SH_NOTE_2 ,SH.SH_SPARE_DBL_9
    FROM      PWIN175.SH INNER JOIN PWIN175.RM  ON RM.RM_CUST  = SH.SH_CUST
    WHERE SH.SH_STATUS <> 3
    AND     RM.RM_CUST = cdsg_cust_in
    AND       SH.SH_ADD_DATE >= cdsg_date_from_in AND SH.SH_ADD_DATE <= cdsg_date_to_in
    GROUP BY SH.SH_CUST,  RM.RM_PARENT, SH.SH_ORDER,  SH.SH_SPARE_STR_5,SH.SH_CUST_REF,SH.SH_ADDRESS,SH.SH_SUBURB,
      SH.SH_CITY, SH.SH_STATE , SH.SH_POST_CODE , SH.SH_NOTE_1 ,SH.SH_NOTE_2 ,SH.SH_SPARE_DBL_9;
      cdsg_rec cdsg_cur%ROWTYPE;
    BEGIN
      OPEN cdsg_cur;
      FETCH cdsg_cur INTO cdsg_rec;
      WHILE cdsg_cur%FOUND
      LOOP
        DBMS_OUTPUT.PUT_LINE(cdsg_rec.SH_CUST || ',' || cdsg_rec.RM_PARENT || ',' || cdsg_rec.SH_SPARE_STR_5 || ',' || cdsg_rec.SH_ORDER || ',' || cdsg_rec.SH_SPARE_DBL_9 || ',' || cdsg_rec.SH_NOTE_2 || ',' || cdsg_rec.SH_NOTE_1 || ',' || cdsg_rec.SH_CITY );
        FETCH cdsg_cur INTO cdsg_rec;
      END LOOP;
    CLOSE cdsg_cur;
    END DESP_STOCK_GET;

    FUNCTION F_BREAK_UNIT_PRICE
      (
      rm_cust_in IN II.II_CUST%TYPE
      ,stock_in   IN II.II_STOCK%TYPE
      )
    RETURN NUMBER

    AS

    price_break NUMBER;

    BEGIN
      IF stock_in IS NOT NULL THEN
          SELECT II_BREAK_LCL
          INTO  price_break
          FROM II
          WHERE II_BREAK_LCL > 0.000001
          AND II_STOCK = stock_in
          AND II_CUST= rm_cust_in;
          --price_in := II.II_BREAK_LCL;
          RETURN price_break;
      ELSE
        RETURN 'N/A';
      END IF;
    END F_BREAK_UNIT_PRICE;

    PROCEDURE get_desp_stocks_cur_p
      (
      gds_cust_in IN IM.IM_CUST%TYPE
      ,gds_cust_not_in IN  IM.IM_CUST%TYPE
      ,gds_stock_not_in IN IM.IM_STOCK%TYPE
      ,gds_stock_not_in2 IN IM.IM_STOCK%TYPE
      ,gds_start_date_in IN SH.SH_EDIT_DATE%TYPE
      ,gds_end_date_in IN SH.SH_ADD_DATE%TYPE
      ,desp_stock_list_cur_var IN OUT stock_ref_cur
      )
    AS
    BEGIN
        OPEN desp_stock_list_cur_var FOR
        SELECT    SH.SH_CUST
                 ,SH.SH_ORDER
                 ,substr(To_Char(ST.ST_DESP_DATE),0,10)
                 ,SD.SD_STOCK
                 ,SD.SD_DESC
                /*,CASE  WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in   AND IM.IM_OWNED_BY = 0 THEN SD.SD_SELL_PRICE
                        WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in   AND IM.IM_OWNED_BY = 1 THEN NI.NI_SELL_VALUE/NI_NX_QUANTITY
                        WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in   AND eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NOT NULL THEN eom_report_pkg.F_BREAK_UNIT_PRICE(RM_GROUP_CUST,SD_STOCK)
                        WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in   AND eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NULL THEN  SD_XX_OW_UNIT_PRICE
                        ELSE NULL
                        END,*/
                 ,IM.IM_BRAND
    FROM  PWIN175.SD
          RIGHT JOIN PWIN175.SH  ON SH.SH_ORDER  = SD.SD_ORDER
          LEFT JOIN PWIN175.ST  ON ST.ST_PICK  = SD.SD_LAST_PICK_NUM
          LEFT JOIN PWIN175.SL   ON SL.SL_PICK   = ST.ST_PICK
          INNER JOIN PWIN175.RM  ON RM.RM_CUST  = SH.SH_CUST
          INNER JOIN PWIN175.IM  ON IM.IM_STOCK = SD.SD_STOCK
          INNER JOIN PWIN175.NI  ON NI.NI_NV_EXT_KEY = SL.SL_UID
    WHERE NI.NI_STRENGTH = 3 AND NI.NI_DATE = ST.ST_DESP_DATE AND NI.NI_STOCK = SD_STOCK AND NI.NI_STATUS <> 0
    AND     SH.SH_STATUS <> 3
    AND     IM.IM_CUST IN (gds_cust_in)
    AND       SH.SH_ORDER = ST.ST_ORDER
    AND       ST.ST_DESP_DATE >= gds_start_date_in AND ST.ST_DESP_DATE <= gds_end_date_in
    AND       SD.SD_LAST_PICK_NUM = ST.ST_PICK
    GROUP BY  SH.SH_CUST,SH.SH_ORDER,
              ST.ST_DESP_DATE,
              SD.SD_DESC,SD.SD_STOCK,SD.SD_XX_OW_UNIT_PRICE,SD.SD_SELL_PRICE,
              IM.IM_BRAND,IM.IM_OWNED_BY,IM.IM_CUST,
              NI.NI_SELL_VALUE,NI.NI_NX_QUANTITY,
              RM.RM_GROUP_CUST;
    END get_desp_stocks_cur_p;

      PROCEDURE get_desp_stocks_curp (
               gds_cust_in IN IM.IM_CUST%TYPE,
               gds_cust_not_in IN  IM.IM_CUST%TYPE,
               --gds_nx_ext_type_in IN NI.NI_NV_EXT_TYPE%TYPE,
               gds_stock_not_in IN IM.IM_STOCK%TYPE,
               gds_stock_not_in2 IN IM.IM_STOCK%TYPE,
               gds_start_date_in IN SH.SH_EDIT_DATE%TYPE,
               gds_end_date_in IN SH.SH_ADD_DATE%TYPE,
               gds_src_get_desp_stocks OUT sys_refcursor
)
AS
BEGIN
      OPEN gds_src_get_desp_stocks FOR

     SELECT     SH.SH_CUST   AS "Customer"
            ,RM.RM_PARENT   AS "Parent"
            ,CASE
              WHEN IM.IM_CUST <> gds_cust_not_in AND SH.SH_SPARE_STR_4 IS NULL THEN SH.SH_CUST
              WHEN IM.IM_CUST <> gds_cust_not_in THEN SH.SH_SPARE_STR_4
              WHEN IM.IM_CUST =  gds_cust_not_in THEN IM.IM_XX_COST_CENTRE01
              ELSE IM.IM_XX_COST_CENTRE01
                     END AS "CostCentre"
           ,SH.SH_ORDER AS "Order"
           ,SH.SH_SPARE_STR_5         AS "OrderwareNum"
           ,SH.SH_CUST_REF            AS "CustomerRef"
           ,ST.ST_PICK                AS "Pickslip"
           ,SD.SD_XX_PICKLIST_NUM     AS "PickNum"
           ,ST.ST_PSLIP               AS "DespatchNote"
           ,substr(To_Char(ST.ST_DESP_DATE),0,10) AS "DespatchDate"
           ,CASE   WHEN SD.SD_STOCK IS NOT NULL THEN SD.SD_STOCK
                     ELSE NULL
                     END                       AS "FeeType"
           ,SD.SD_STOCK               AS "Item"
           ,SD.SD_DESC                AS "Description"
           ,SL.SL_PSLIP_QTY           AS "Qty"
           ,SD.SD_QTY_UNIT            AS "UOI"
           ,CASE WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in   AND IM.IM_OWNED_BY = 0 THEN SD.SD_SELL_PRICE
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in   AND IM.IM_OWNED_BY = 1 THEN NI.NI_SELL_VALUE/NI_NX_QUANTITY
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in    AND eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NOT NULL THEN eom_report_pkg.F_BREAK_UNIT_PRICE(RM_GROUP_CUST,SD_STOCK)
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in    AND eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NULL THEN  SD.SD_XX_OW_UNIT_PRICE
                 ELSE NULL
                 END AS "Batch/UnitPrice"
           ,CASE WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in THEN To_Number(IM.IM_REPORTING_PRICE)
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  THEN  eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK)
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  AND eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NULL THEN  SD.SD_XX_OW_UNIT_PRICE
                 ELSE NULL
                 END                        AS "OWUnitPrice"
           ,CASE WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in AND IM.IM_OWNED_BY = 0 THEN SD.SD_SELL_PRICE * SL.SL_PSLIP_QTY
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in AND IM.IM_OWNED_BY = 1 THEN (NI.NI_SELL_VALUE/NI.NI_NX_QUANTITY) * SL.SL_PSLIP_QTY
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  AND eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NOT NULL THEN  eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) * SL.SL_PSLIP_QTY
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  AND eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NULL THEN  SD.SD_XX_OW_UNIT_PRICE * SL.SL_PSLIP_QTY
                 ELSE NULL
                 END          AS "DExcl"
           ,CASE WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in THEN To_Number(IM.IM_REPORTING_PRICE)
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  THEN  eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK)
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  AND eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NULL THEN  SD.SD_XX_OW_UNIT_PRICE
                 ELSE NULL
                 END                       AS "Excl_Total"
           ,CASE WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in AND IM.IM_OWNED_BY = 0 THEN (SD.SD_SELL_PRICE * SL.SL_PSLIP_QTY) * 1.1
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in AND IM.IM_OWNED_BY = 1 THEN ((NI.NI_SELL_VALUE/NI.NI_NX_QUANTITY) * SL.SL_PSLIP_QTY) * 1.1
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  AND eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NOT NULL THEN  (eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) * SL.SL_PSLIP_QTY) * 1.1
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  AND eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NULL THEN  (SD.SD_XX_OW_UNIT_PRICE * SL.SL_PSLIP_QTY) * 1.1
                 ELSE NULL
                 END          AS "DIncl"
           ,CASE WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in AND IM.IM_OWNED_BY = 0 THEN (SD.SD_SELL_PRICE * SL.SL_PSLIP_QTY) * 1.1
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in AND IM.IM_OWNED_BY = 1 THEN ((NI.NI_SELL_VALUE/NI.NI_NX_QUANTITY) * SL.SL_PSLIP_QTY) * 1.1
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  AND eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NOT NULL THEN  (eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) * SL.SL_PSLIP_QTY) * 1.1
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  AND eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NULL THEN  (SD.SD_XX_OW_UNIT_PRICE * SL.SL_PSLIP_QTY) * 1.1
                 ELSE NULL
                 END          AS "Incl_Total"
              ,CASE WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in THEN To_Number(IM.IM_REPORTING_PRICE)
                          WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  THEN  eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK)
                          WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  AND eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NULL THEN  SD.SD_XX_OW_UNIT_PRICE
                          ELSE NULL
                          END                    AS "ReportingPrice"
           ,SH.SH_ADDRESS             AS "Address"
           ,SH.SH_SUBURB              AS "Address2"
           ,SH.SH_CITY                AS "Suburb"
           ,SH.SH_STATE               AS "State"
           ,SH.SH_POST_CODE           AS "Postcode"
           ,SH.SH_NOTE_1              AS "DeliverTo"
           ,SH.SH_NOTE_2              AS "AttentionTo"
           ,ST.ST_WEIGHT              AS "Weight"
           ,ST.ST_PACKAGES            AS "Packages"
           ,SH.SH_SPARE_DBL_9         AS "OrderSource"
           ,NULL AS "Pallet/Shelf Space"
           ,NULL AS "Locn"
           ,NULL AS "AvailSOH"
           ,NULL AS "CountOfStocks"
           ,NULL AS "Email"
           ,IM.IM_BRAND AS Brand
           ,NULL AS OwnedBy
           ,NULL AS sProfile
           ,NULL AS WaiveFee
           ,NULL AS "Cost"
     FROM  PWIN175.SD
                 RIGHT JOIN PWIN175.SH  ON SH.SH_ORDER  = SD.SD_ORDER
                 LEFT JOIN PWIN175.ST  ON ST.ST_PICK  = SD.SD_LAST_PICK_NUM
        LEFT JOIN PWIN175.SL   ON SL.SL_PICK   = ST.ST_PICK
                 INNER JOIN PWIN175.RM  ON RM.RM_CUST  = SH.SH_CUST
                 INNER JOIN PWIN175.IM  ON IM.IM_STOCK = SD.SD_STOCK
        INNER JOIN PWIN175.NI  ON NI.NI_NV_EXT_KEY = SL.SL_UID
  WHERE NI.NI_STRENGTH = 3 AND NI.NI_DATE = ST.ST_DESP_DATE AND NI.NI_STOCK = SD_STOCK AND NI.NI_STATUS <> 0
     AND     SH.SH_STATUS <> 3
  AND     IM.IM_CUST IN (gds_cust_in)
     AND       SH.SH_ORDER = ST.ST_ORDER
  AND       ST.ST_DESP_DATE >= gds_start_date_in AND ST.ST_DESP_DATE <= gds_end_date_in
     --AND       ST.ST_DESP_DATE >= '10-APR-2014' AND ST.ST_DESP_DATE <= '15-APR-2014'
     AND       SD.SD_LAST_PICK_NUM = ST.ST_PICK
     GROUP BY  SH.SH_CUST,SH.SH_ORDER,SH.SH_ADDRESS,SH.SH_SUBURB,SH.SH_CITY,SH.SH_STATE,SH.SH_POST_CODE,SH.SH_NOTE_1,SH.SH_NOTE_2,SH.SH_CAMPAIGN, SH.SH_SPARE_STR_4,SH.SH_SPARE_DBL_9,SH.SH_CUST_REF,SH.SH_SPARE_STR_5,
                     ST.ST_DESP_DATE,ST.ST_WEIGHT,ST.ST_PACKAGES,ST.ST_PSLIP,ST.ST_PICK,
                     SD.SD_DESC,SD.SD_STOCK,SD.SD_XX_OW_UNIT_PRICE,SD.SD_SELL_PRICE,SD.SD_LINE,SD.SD_EXCL,SD.SD_INCL,SD.SD_QTY_ORDER,SD.SD_QTY_UNIT,SD.SD_XX_PICKLIST_NUM,
            IM.IM_BRAND,IM.IM_OWNED_BY,IM.IM_CUST,IM.IM_XX_COST_CENTRE01,IM.IM_REPORTING_PRICE,
            NI.NI_SELL_VALUE,NI.NI_NX_QUANTITY,
            RM.RM_GROUP_CUST,RM.RM_PARENT,
            SL.SL_PSLIP_QTY;





   /*         gds_rec gds_src_get_desp_stocks%ROWTYPE;
  BEGIN
    OPEN  gds_src_get_desp_stocks;
    FETCH gds_src_get_desp_stocks INTO  gds_rec;
    WHILE gds_src_get_desp_stocks%FOUND
    LOOP
      Dbms_Output.PUT_LINE('Row: '||gds_src_get_desp_stocks%ROWCOUNT||' # '|| gds_rec.SH_ORDER);
      FETCH gds_src_get_desp_stocks INTO gds_rec;
    END LOOP;
    CLOSE gds_src_get_desp_stocks;
    Dbms_Output.PUT_LINE('finished for cust '||gds_cust_in );    */
END get_desp_stocks_curp;

    PROCEDURE myproc_test_via_PHP
      (
      p1 IN NUMBER
      ,p2 IN OUT NUMBER
      ) AS
    BEGIN
      p2 := p1 * 2;
      DBMS_OUTPUT.PUT_LINE(p2);
    END;

    PROCEDURE list_stocks
      (
      cat IN IM.IM_CAT%TYPE
      ) IS
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

    PROCEDURE quick_function_test( p_rc OUT SYS_REFCURSOR )AS
    BEGIN
      OPEN p_rc
        for select 1 col1
              from dual;
      CLOSE p_rc;
    END;

    FUNCTION f_getDisplay
      (
      i_column_tx VARCHAR2
      ,i_table_select_tx VARCHAR2
      ,i_field_tx VARCHAR2
      ,i_value_tx VARCHAR2
      )
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

    FUNCTION f_getDisplay_from_type_bind
      (
      i_first_col IN VARCHAR2
      ,i_value_tx IN VARCHAR2
      )
       RETURN myBrandType
       IS
            v_out_tx myBrandType;
            v_sql_tx VARCHAR2(2000);
       BEGIN
      v_sql_tx := ' SELECT myBrandType ( '||i_first_col||',' ||
                     '    u.IR_DESC '||
                    ') FROM IR u '||
                     ' WHERE u.IR_BRAND = :5';

       EXECUTE IMMEDIATE v_sql_tx INTO v_out_tx
       USING i_value_tx;
          RETURN v_out_tx;
    END f_getDisplay_from_type_bind;

    FUNCTION f_getDisplay_oty
      (
      i_column_tx VARCHAR2
      ,i_column2_tx VARCHAR2
      ,i_table_select_tx VARCHAR2
      ,i_field_tx VARCHAR2
      ,i_value_tx NUMBER
      )
      RETURN VARCHAR2
      IS
        v_out_tx VARCHAR2(2000);
        v_sql_tx VARCHAR2(2000);
      BEGIN
      EXECUTE IMMEDIATE 'SELECT myBrandType(IR_BRAND,IR_DESC) FROM IR WHERE IR_BRAND = ''AAS_ACIRT''' INTO v_out_tx
        USING i_value_tx;
      RETURN v_out_tx;
    END f_getDisplay_oty;

    FUNCTION get_cust_stocks(r_coy_num in VARCHAR) RETURN sys_refcursor is
      v_rc sys_refcursor;
    BEGIN
      OPEN v_rc FOR 'SELECT RM_CUST, RM_COY_NUM, RM_REP, RM_STD_CB_BANK FROM RM WHERE RM_PARENT = :coynum' using r_coy_num;
      RETURN v_rc;
    END;

    /*FUNCTION populate_custs(coynum in VARCHAR := null)
      RETURN  custtype is
              v_custtype custtype := custtype();  -- Declare a local table structure and initialize it
              v_cnt     number := 0;
              v_rc    sys_refcursor;
              v_cust   VARCHAR2(20);
              v_coynum   VARCHAR2(20);
              v_rep    VARCHAR2(20);
              v_bank VARCHAR(20);

       BEGIN
          v_rc := get_cust_stocks(coynum);
          loop
            fetch v_rc into v_cust, v_coynum, v_rep, v_bank;
            exit when v_rc%NOTFOUND;
            v_custtype.extend;
            v_cnt := v_cnt + 1;
            v_custtype(v_cnt) := custtype(v_cust, v_coynum, v_rep, v_bank);
          end loop;
          close v_rc;
          RETURN v_custtype;
        END;
    */

    FUNCTION refcursor_function
      RETURN SYS_REFCURSOR AS c SYS_REFCURSOR;
    BEGIN
      OPEN c FOR
        select RM_CUST, RM_NAME, RM_XX_PARENT
        from pwin175.RM
        where RM_PARENT = 'TABCORP';
      RETURN c;
    END;

    -- Calling the function from a MAIN BODY
    --variable v_ref_cursor refcursor;
    --exec :v_ref_cursor := refcursor_function();
    --print :v_ref_cursor

    PROCEDURE test_get_brand IS
      brand myBrandType;
    BEGIN
      brand := f_getDisplay_from_type_bind ('u.IR_BRAND','AAS');
      DBMS_OUTPUT.PUT_LINE(brand.brand_tx|| ' - ' ||brand.desc_tx);
    END;

END eom_report_pkg;



**********************************************************************************************************************************************************************************************************

TESTING

--Run in SQL+
variable desp_stock_cv refcursor;
exec EOM_REPORT_PKG.get_desp_stocks_curp('LUXOTTICA','TABCORP','COURIER','COURIERS','13-APR-2014','28-APR-2014',:desp_stock_cv);
print desp_stock_cv;
