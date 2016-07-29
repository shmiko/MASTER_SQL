/* First run this file with variables set in header - declare variables - drop tables, recreate tables, insert into tables - then query tables */
/* EOM_INVOICING_CREATE_TABLES.sql */
--Admin Order Data by Parent or Customer
/*decalre variables These are being declared via the stored procedure - just need to redeclare cust so as we can get the rates*/
var cust varchar2(20)
exec :cust := 'LUXOTTICA'
var cust2 varchar2(20)
exec :cust := 'TABCORP'
var ordernum varchar2(20)
exec :ordernum := '1363806'
var stock varchar2(20)
exec :stock := 'COURIER'
var stock2 VARCHAR2(50)
EXEC :stock2 := 'FEE*'
var source varchar2(20)
exec :source := 'BSPRINTNSW'
var sAnalysis varchar2(20) /*VerbalOrderEntryFee*/
exec SELECT  RM_ANAL INTO :sAnalysis FROM RM where RM_CUST = :cust;
var anal varchar2(20)
exec :anal := '49'
var start_date varchar2(20)
exec :start_date := To_Date('31-Mar-2014')
var end_date varchar2(20)
exec :end_date := To_Date('1-Apr-2014')
var nx NUMBER
EXEC :nx := 1810105

DECLARE CURSOR TestCursor IS SELECT XR_CODE FROM XR WHERE XR_CODE LIKE 'PRJ_%';
  tgc_rec TestCursor%TYPE;
  OPEN TestCUrsor;
  FETCH TestCursor INTO  tgc_rec;
  WHILE(TestCursor%FOUND)
    LOOP
      DBMS_OUTPUT.PUT_LINE(tgc_rec.XR_CODE);
      --FETCH TestCursor INTO  tgc_rec;
    END LOOP
  CLOSE TestCursor;

/*Stocks*/
DECLARE
  TYPE DespStkCurTyp IS REF CURSOR;
  cdsg_stock_cust_in IM.IM_CUST%TYPE;
  cdsg_nx_in NI.NI_NV_EXT_TYPE%TYPE;
  cdsg_line_stock_in SD.SD_STOCK%TYPE;
  cdsg_date_from_in  ST.ST_DESP_DATE%TYPE;
  cdsg_date_to_in  ST.ST_DESP_DATE%TYPE;
  cdsg_cust_in RM.RM_CUST%TYPE;
  sql_stmt VARCHAR2(2000);
  DespStk_cv DespStkCurTyp;

BEGIN
  DespStk_rec DespStkCurTyp%ROWTYPE;

  CREATE OR REPLACE PROCEDURE DESP_STOCK_GET    (
              cdsg_stock_cust_in IN IM.IM_CUST%TYPE,
              cdsg_nx_in IN NI.NI_NV_EXT_TYPE%TYPE,
              cdsg_line_stock_in IN SD.SD_STOCK%TYPE,
              cdsg_date_from_in IN  ST.ST_DESP_DATE%TYPE,
              cdsg_date_to_in IN  ST.ST_DESP_DATE%TYPE,
              cdsg_cust_in IN RM.RM_CUST%TYPE
              ) AS
   CURSOR cdsg_cur IS
 sql_stmt := 'SELECT    SH_CUST,SH_ORDER,
			  RM_PARENT,
	        CASE    WHEN IM_CUST <> cdsg_stock_cust_in THEN SH_SPARE_STR_4
			            WHEN IM_CUST = cdsg_stock_cust_in THEN IM_XX_COST_CENTRE01
			            ELSE IM_XX_COST_CENTRE01
			            END                      AS "CostCentre",
		      SH_ORDER               AS "Order",
		      SH_SPARE_STR_5         AS "OrderwareNum",
		      SH_CUST_REF            AS "CustomerRef",
		      ST_PICK                AS "Pickslip",
		      SD_XX_PICKLIST_NUM     AS "PickNum",
		      ST_PSLIP               AS "DespatchNote",
			        substr(To_Char(ST_DESP_DATE),0,10)            AS "DespatchDate",
	        CASE   WHEN SD_STOCK IS NOT NULL THEN SD_STOCK
			            ELSE NULL
			            END                      AS "FeeType",
			        SD_STOCK               AS "Item",
			        SD_DESC                AS "Description",
			        SL_PSLIP_QTY           AS "Qty",
			        SD_QTY_UNIT            AS "UOI",
	 /*  CASE   WHEN SD_STOCK IS NOT NULL AND IM_CUST <> cdsg_stock_cust_in AND IM_OWNED_BY = 0 THEN SD_SELL_PRICE
			      WHEN SD_STOCK IS NOT NULL AND IM_CUST <> cdsg_stock_cust_in AND IM_OWNED_BY = 1 THEN NI_SELL_VALUE/NI_NX_QUANTITY
            WHEN SD_STOCK IS NOT NULL AND IM_CUST = cdsg_stock_cust_in AND BREAK_UNIT_PRICE(RM_GROUP_CUST,SD_STOCK) IS NOT NULL THEN BREAK_UNIT_PRICE(RM_GROUP_CUST,SD_STOCK)
			      WHEN SD_STOCK IS NOT NULL AND IM_CUST = cdsg_stock_cust_in AND BREAK_UNIT_PRICE(RM_GROUP_CUST,SD_STOCK) IS NULL THEN  SD_XX_OW_UNIT_PRICE
			      ELSE NULL
			      END                        AS "Batch/UnitPrice",
	   /*CASE   WHEN SD_STOCK IS NOT NULL AND IM_CUST <> cdsg_stock_cust_in THEN To_Number(IM_REPORTING_PRICE)
			      WHEN SD_STOCK IS NOT NULL AND IM_CUST = cdsg_stock_cust_in THEN  BREAK_UNIT_PRICE(RM_GROUP_CUST,SD_STOCK)
			      WHEN SD_STOCK IS NOT NULL AND IM_CUST = cdsg_stock_cust_in AND (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = SD_STOCK AND vIICust = RM_GROUP_CUST) IS NULL THEN  SD_XX_OW_UNIT_PRICE
			      ELSE NULL
			      END                        AS "OWUnitPrice",
      CASE  WHEN SD_STOCK IS NOT NULL AND IM_CUST <> cdsg_stock_cust_in AND IM_OWNED_BY = 0 THEN SD_SELL_PRICE * SD_QTY_DESP
			      WHEN SD_STOCK IS NOT NULL AND IM_CUST <> cdsg_stock_cust_in AND IM_OWNED_BY = 1 THEN (NI_SELL_VALUE/NI_NX_QUANTITY) * SD_QTY_DESP
            WHEN SD_STOCK IS NOT NULL AND IM_CUST = cdsg_stock_cust_in AND BREAK_UNIT_PRICE(RM_GROUP_CUST,SD_STOCK) IS NOT NULL THEN  BREAK_UNIT_PRICE(RM_GROUP_CUST,SD_STOCK) * SD_QTY_DESP
			      WHEN SD_STOCK IS NOT NULL AND IM_CUST = cdsg_stock_cust_in AND BREAK_UNIT_PRICE(RM_GROUP_CUST,SD_STOCK) IS NULL THEN  SD_XX_OW_UNIT_PRICE * SD_QTY_DESP
			      ELSE NULL
			      END          AS "DExcl",

	   CASE   WHEN SD_STOCK IS NOT NULL AND IM_CUST <> cdsg_stock_cust_in THEN To_Number(IM_REPORTING_PRICE)
			      WHEN SD_STOCK IS NOT NULL AND IM_CUST = cdsg_stock_cust_in THEN  BREAK_UNIT_PRICE(RM_GROUP_CUST,SD_STOCK)
			      WHEN SD_STOCK IS NOT NULL AND IM_CUST = cdsg_stock_cust_in AND BREAK_UNIT_PRICE(RM_GROUP_CUST,SD_STOCK) IS NULL THEN  SD_XX_OW_UNIT_PRICE
			      ELSE NULL
			      END                       AS "Excl_Total",
	  CASE    WHEN SD_STOCK IS NOT NULL AND IM_CUST <> cdsg_stock_cust_in AND IM_OWNED_BY = 0 THEN (SD_SELL_PRICE * SD_QTY_DESP) * 1.1
			      WHEN SD_STOCK IS NOT NULL AND IM_CUST <> cdsg_stock_cust_in AND IM_OWNED_BY = 1  THEN  ((NI_SELL_VALUE/NI_NX_QUANTITY) * SD_QTY_DESP) * 1.1
            WHEN SD_STOCK IS NOT NULL AND IM_CUST = cdsg_stock_cust_in AND BREAK_UNIT_PRICE(RM_GROUP_CUST,SD_STOCK) IS NOT NULL THEN  (BREAK_UNIT_PRICE(RM_GROUP_CUST,SD_STOCK) * SD_QTY_DESP) * 1.1
			      WHEN SD_STOCK IS NOT NULL AND IM_CUST = cdsg_stock_cust_in AND BREAK_UNIT_PRICE(RM_GROUP_CUST,SD_STOCK) IS NULL THEN  (SD_XX_OW_UNIT_PRICE * SD_QTY_DESP) * 1.1
			      ELSE NULL
			      END          AS "DIncl",
	   CASE   WHEN SD_STOCK IS NOT NULL AND IM_CUST <> cdsg_stock_cust_in AND IM_OWNED_BY = 0 THEN (SD_SELL_PRICE * SD_QTY_DESP) * 1.1
			      WHEN SD_STOCK IS NOT NULL AND IM_CUST <> cdsg_stock_cust_in AND IM_OWNED_BY = 1 THEN  ((NI_SELL_VALUE/NI_NX_QUANTITY) * SD_QTY_DESP) * 1.1
            WHEN SD_STOCK IS NOT NULL AND IM_CUST = cdsg_stock_cust_in AND BREAK_UNIT_PRICE(RM_GROUP_CUST,SD_STOCK) IS NOT NULL THEN  (BREAK_UNIT_PRICE(RM_GROUP_CUST,SD_STOCK) * SD_QTY_DESP) * 1.1
			      WHEN SD_STOCK IS NOT NULL AND IM_CUST = cdsg_stock_cust_in AND BREAK_UNIT_PRICE(RM_GROUP_CUST,SD_STOCK) IS NULL THEN  (SD_XX_OW_UNIT_PRICE * SD_QTY_DESP) * 1.1
			      ELSE NULL
			      END          AS "Incl_Total",
	  CASE    WHEN SD_STOCK IS NOT NULL AND IM_CUST <> cdsg_stock_cust_in THEN To_Number(IM_REPORTING_PRICE)
			      WHEN SD_STOCK IS NOT NULL AND IM_CUST = cdsg_stock_cust_in THEN  BREAK_UNIT_PRICE(RM_GROUP_CUST,SD_STOCK)
			      WHEN SD_STOCK IS NOT NULL AND IM_CUST = cdsg_stock_cust_in AND BREAK_UNIT_PRICE(RM_GROUP_CUST,SD_STOCK) IS NULL THEN  SD_XX_OW_UNIT_PRICE
			      ELSE NULL
			      END                    AS "ReportingPrice", */
		SH_ADDRESS             AS "Address",
		SH_SUBURB              AS "Address2",
		SH_CITY                AS "Suburb",
		SH_STATE               AS "State",
		SH_POST_CODE           AS "Postcode",
		SH_NOTE_1              AS "DeliverTo",
		SH_NOTE_2              AS "AttentionTo" ,
		ST_WEIGHT              AS "Weight",
		ST_PACKAGES            AS "Packages",
		SH_SPARE_DBL_9         AS "OrderSource",
		NULL AS "Pallet/Shelf Space", /*Pallet/Space*/
		NULL AS "Locn", /*Locn*/
		0 AS "AvailSOH",/*Avail SOH*/
		0 AS "CountOfStocks",
    IM_BRAND AS Brand
	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON SH_ORDER  = SD_ORDER
			  INNER JOIN PWIN175.ST t  ON ST_ORDER  = SH_ORDER
        INNER JOIN PWIN175.SL l  ON SL_PICK   = ST_PICK
			  INNER JOIN PWIN175.RM r  ON RM_CUST  = SH_CUST
			  INNER JOIN PWIN175.IM i  ON IM_STOCK = SD_STOCK
        INNER JOIN PWIN175.NI n  ON NI_NV_EXT_KEY = SL_UID
        WHERE NI_NV_EXT_TYPE = cdsg_nx_in AND NI_STRENGTH = 3 AND NI_DATE = ST_DESP_DATE AND NI_STOCK = SD_STOCK AND NI_STATUS <> 0
	      AND   SH_STATUS <> 3
        AND   IM_CUST = cdsg_cust_in
	      AND   SH_ORDER = ST_ORDER
	      AND   SD_STOCK NOT LIKE cdsg_line_stock_in
	      AND   ST_DESP_DATE >= cdsg_date_from_in AND ST_DESP_DATE <= cdsg_date_to_in
	      AND   SD_LAST_PICK_NUM = ST_PICK
	GROUP BY  SH_CUST,
			  SH_NOTE_1,
			  SH_CAMPAIGN,
			  SH_SPARE_STR_4,
			  IM_XX_COST_CENTRE01,
			  IM_CUST,
			  RM_PARENT,
			  SH_ORDER,
			  ST_PICK,
			  SD_XX_PICKLIST_NUM,
			  IM_REPORTING_PRICE,
			  IM_NOMINAL_VALUE,
			  ST_PSLIP,
			  ST_DESP_DATE,
			  SD_QTY_ORDER,
			  SD_QTY_UNIT,
			  SD_STOCK,
			  SD_DESC,
			  SD_LINE,
			  SD_EXCL,
			  SD_INCL,
			  SD_SELL_PRICE,
			  SD_XX_OW_UNIT_PRICE,
			  SD_QTY_ORDER,
			  SD_QTY_ORDER,
			  SH_ADDRESS,
			  SH_SUBURB,
			  SH_CITY,
			  SH_STATE,
			  SH_POST_CODE,
			  SH_NOTE_1,
			  SH_NOTE_2,
			  ST_WEIGHT,
			  ST_PACKAGES,
			  SH_SPARE_DBL_9,
			  RM_GROUP_CUST,
			  RM_PARENT,
			  SH_SPARE_STR_5,
			  SH_CUST_REF,SH_SPARE_STR_3,SH_SPARE_STR_1,
			  SD_SELL_PRICE,
			  IM_OWNED_BY,
			  SD_QTY_DESP,
        NI_SELL_VALUE,
        NI_NX_QUANTITY,
              IM_BRAND,
              SL_PSLIP_QTY';
  OPEN DespStk_cv FOR SQL_stmt;
  LOOP
    FETCH DespStk_cv INTO DespStk_rec;
    EXIT WHEN DespStk_cv%NOTFOUND;
  END LOOP;
  CLOSE DespStk_cv;
 END;
    cdsg_rec cdsg_cur%ROWTYPE;
    cdsg_rec cdsg_cur%ROWTYPE;
  BEGIN
    DBMS_OUTPUT.PUT_LINE('Customer,Order');
    OPEN cdsg_cur;
    FETCH cdsg_cur INTO cdsg_rec;
    WHILE cdsg_cur%FOUND
    LOOP
      DBMS_OUTPUT.PUT_LINE(cdsg_rec.sh_cust || ',' || cdsg_rec.sh_order);--(1 || ',' || 2 );

      --FETCH cdsg_cur INTO cdsg_rec;
    END LOOP;
  CLOSE cdsg_cur;
 END DESP_STOCK_GET;

      --DBMS_OUTPUT.PUT_LINE(gc_rec.Customer || ',' || gc_rec.Parent || ',' || gc_rec.OrderwareNum || ',' || "gc_rec.Order" || ',' || gc_rec.PickNum || ',' || gc_rec.FeeType || ',' || gc_rec.Item || ',' || gc_rec.Description );
      --Customer	Parent	CostCentre	Order	OrderwareNum	CustomerRef	Pickslip	PickNum	DespatchNote	DespatchDate	FeeType	Item	Description	Qty	UOI	Batch/UnitPrice	OWUnitPrice	DExcl	Excl_Total	DIncl	Incl_Total	ReportingPrice	Address	Address2	Suburb	State	Postcode	DeliverTo	AttentionTo	Weight	Packages	OrderSource	Pallet/Shelf Space	Locn	AvailSOH	CountOfStocks	EMAIL	BRAND
      --Passing
      /*  cdsg_stock_cust_in IN IM.IM_CUST%TYPE,
        cdsg_nx_in IN NI.NI_NV_EXT_TYPE%TYPE,
        cdsg_line_stock_in IN SD.SD_STOCK%TYPE,
        cdsg_date_from_in IN  ST.ST_DESP_DATE%TYPE,
        cdsg_date_to_in IN  ST.ST_DESP_DATE%TYPE,
        cdsg_cust_in IN RM.RM_CUST%TYPE,
        cdsg_cust_in2 IN RM.RM_CUST%TYPE  */

EXECUTE DESP_STOCK_GET    (:cust2,:nx,:stock,:start_date,:end_date,:cust);


EXECUTE DESP_STOCK_GET ('TABCORP',1810105,'COURIER','2-Apr-2014','8-Apr-2014','LUXOTTICA')



DECLARE
   PROCEDURE fetch_all_rows (limit_in IN PLS_INTEGER)
   IS
      CURSOR source_cur
      IS
         SELECT *
           FROM IM WHERE IM_CUST = 'ZIONS';

      TYPE source_aat IS TABLE OF source_cur%ROWTYPE
         INDEX BY PLS_INTEGER;

      l_source   source_aat;
      l_start    PLS_INTEGER;
      l_end      PLS_INTEGER;
      l_stop     PLS_INTEGER;
      cdsg_rec source_cur%ROWTYPE;
   BEGIN
        --OPEN source_cur;
        --FETCH source_cur INTO cdsg_rec;
        --WHILE source_cur%FOUND
        --WHILE l_stop < 11
        --LOOP
        --    DBMS_OUTPUT.PUT_LINE(cdsg_rec.IM_CUST );
        --    l_stop := 10;
        --END LOOP;

      DBMS_SESSION.free_unused_user_memory;
      --show_pga_memory (limit_in || ' - BEFORE');
      l_start := DBMS_UTILITY.get_cpu_time;

      OPEN source_cur;

      LOOP
         FETCH source_cur
         BULK COLLECT INTO l_source LIMIT limit_in;
         --DBMS_OUTPUT.put_line ( l_source.IM_CUST );
         --DBMS_OUTPUT.PUT_LINE(cdsg_rec.IM_CUST );

         EXIT WHEN l_source.COUNT = 0;
      END LOOP;

      CLOSE source_cur;

      l_end := DBMS_UTILITY.get_cpu_time;
      DBMS_OUTPUT.put_line ( 'Elapsed CPU time for limit of '
                            || limit_in
                            || ' = '
                            || TO_CHAR (l_end - l_start)
                           );
      --show_pga_memory (limit_in || ' - AFTER');
   END fetch_all_rows;
BEGIN
   --fetch_all_rows (1);
   --fetch_all_rows (5);
   --fetch_all_rows (25);
   --fetch_all_rows (50);
   --fetch_all_rows (75);
   --fetch_all_rows (100);
   fetch_all_rows (1000);
   --fetch_all_rows (10000);
   --fetch_all_rows (100000);
END;
/