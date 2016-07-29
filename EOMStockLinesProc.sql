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

  PROCEDURE GROUP_CUST_GET AS
    (gc_customer_in IN rm.rm_cust%TYPE)
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
      DBMS_OUTPUT.PUT_LINE(gc_rec.rm_cust || ' ' || gc_rec.rm_name);
      FETCH gc_cur INTO gc_rec;
    END LOOP;
    CLOSE gc_cur;
  END GROUP_CUST_GET




/*Stocks*/
  PROCEDURE CUST_DESP_STOCK_GET AS (
        cdsg_stock_cust_in IN i.IM_CUST%TYPE,
        cdsg_nx_in IN NI_NV_EXT_TYPE%TYPE,
        cdsg_line_stock_in IN d.SD_STOCK%TYPE,
        cdsg_date_from_in IN  t.ST_DESP_DATE%TYPE,
        cdsg_date_to_in IN  t.ST_DESP_DATE%TYPE,
        cdsg_cust_in IN i.IM_CUST%TYPE
     )
   CURSOR cdsg_cur IS
   SELECT    s.SH_CUST                AS "Customer",
			  r.RM_PARENT              AS "Parent",
	   CASE    WHEN i.IM_CUST <> cdsg_stock_cust_in THEN s.SH_SPARE_STR_4
			      WHEN i.IM_CUST = cdsg_stock_cust_in THEN i.IM_XX_COST_CENTRE01
			      ELSE i.IM_XX_COST_CENTRE01
			      END                      AS "CostCentre",
		 s.SH_ORDER               AS "Order",
		 s.SH_SPARE_STR_5         AS "OrderwareNum",
		 s.SH_CUST_REF            AS "CustomerRef",
		 t.ST_PICK                AS "Pickslip",
		 d.SD_XX_PICKLIST_NUM     AS "PickNum",
		 t.ST_PSLIP               AS "DespatchNote",
			  substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	   CASE   WHEN d.SD_STOCK IS NOT NULL THEN d.SD_STOCK
			      ELSE NULL
			      END                      AS "FeeType",
			  d.SD_STOCK               AS "Item",
			  d.SD_DESC                AS "Description",
			  l.SL_PSLIP_QTY           AS "Qty",
			  d.SD_QTY_UNIT            AS "UOI",
	   CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> cdsg_stock_cust_in AND i.IM_OWNED_BY = 0 THEN d.SD_SELL_PRICE
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> cdsg_stock_cust_in AND i.IM_OWNED_BY = 1 THEN n.NI_SELL_VALUE/n.NI_NX_QUANTITY
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = cdsg_stock_cust_in AND eom_report_pkg.BREAK_UNIT_PRICE(r.RM_GROUP_CUST,d.SD_STOCK) IS NOT NULL THEN eom_report_pkg.BREAK_UNIT_PRICE(r.RM_GROUP_CUST,d.SD_STOCK)
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = cdsg_stock_cust_in AND eom_report_pkg.BREAK_UNIT_PRICE(r.RM_GROUP_CUST,d.SD_STOCK) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			      ELSE NULL
			      END                        AS "Batch/UnitPrice",
	   CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> cdsg_stock_cust_in THEN To_Number(i.IM_REPORTING_PRICE)
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = cdsg_stock_cust_in THEN  eom_report_pkg.BREAK_UNIT_PRICE(r.RM_GROUP_CUST,d.SD_STOCK)
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = cdsg_stock_cust_in AND (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			      ELSE NULL
			      END                        AS "OWUnitPrice",
      CASE  WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> cdsg_stock_cust_in AND i.IM_OWNED_BY = 0 THEN d.SD_SELL_PRICE * d.SD_QTY_DESP
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> cdsg_stock_cust_in AND i.IM_OWNED_BY = 1 THEN (n.NI_SELL_VALUE/n.NI_NX_QUANTITY) * d.SD_QTY_DESP
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = cdsg_stock_cust_in AND eom_report_pkg.BREAK_UNIT_PRICE(r.RM_GROUP_CUST,d.SD_STOCK) IS NOT NULL THEN  eom_report_pkg.BREAK_UNIT_PRICE(r.RM_GROUP_CUST,d.SD_STOCK) * d.SD_QTY_DESP
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = cdsg_stock_cust_in AND eom_report_pkg.BREAK_UNIT_PRICE(r.RM_GROUP_CUST,d.SD_STOCK) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE * d.SD_QTY_DESP
			      ELSE NULL
			      END          AS "DExcl",

	   CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> cdsg_stock_cust_in THEN To_Number(i.IM_REPORTING_PRICE)
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = cdsg_stock_cust_in THEN  eom_report_pkg.BREAK_UNIT_PRICE(r.RM_GROUP_CUST,d.SD_STOCK)
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = cdsg_stock_cust_in AND eom_report_pkg.BREAK_UNIT_PRICE(r.RM_GROUP_CUST,d.SD_STOCK) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			      ELSE NULL
			      END                       AS "Excl_Total",
	  CASE    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> cdsg_stock_cust_in AND i.IM_OWNED_BY = 0 THEN (d.SD_SELL_PRICE * d.SD_QTY_DESP) * 1.1
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> cdsg_stock_cust_in AND i.IM_OWNED_BY = 1  THEN  ((n.NI_SELL_VALUE/n.NI_NX_QUANTITY) * d.SD_QTY_DESP) * 1.1
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = cdsg_stock_cust_in AND eom_report_pkg.BREAK_UNIT_PRICE(r.RM_GROUP_CUST,d.SD_STOCK) IS NOT NULL THEN  (eom_report_pkg.BREAK_UNIT_PRICE(r.RM_GROUP_CUST,d.SD_STOCK) * d.SD_QTY_DESP) * 1.1
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = cdsg_stock_cust_in AND eom_report_pkg.BREAK_UNIT_PRICE(r.RM_GROUP_CUST,d.SD_STOCK) IS NULL THEN  (d.SD_XX_OW_UNIT_PRICE * d.SD_QTY_DESP) * 1.1
			      ELSE NULL
			      END          AS "DIncl",
	   CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> cdsg_stock_cust_in AND i.IM_OWNED_BY = 0 THEN (d.SD_SELL_PRICE * d.SD_QTY_DESP) * 1.1
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> cdsg_stock_cust_in AND i.IM_OWNED_BY = 1 THEN  ((n.NI_SELL_VALUE/n.NI_NX_QUANTITY) * d.SD_QTY_DESP) * 1.1
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = cdsg_stock_cust_in AND eom_report_pkg.BREAK_UNIT_PRICE(r.RM_GROUP_CUST,d.SD_STOCK) IS NOT NULL THEN  (eom_report_pkg.BREAK_UNIT_PRICE(r.RM_GROUP_CUST,d.SD_STOCK) * d.SD_QTY_DESP) * 1.1
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = cdsg_stock_cust_in AND eom_report_pkg.BREAK_UNIT_PRICE(r.RM_GROUP_CUST,d.SD_STOCK) IS NULL THEN  (d.SD_XX_OW_UNIT_PRICE * d.SD_QTY_DESP) * 1.1
			      ELSE NULL
			      END          AS "Incl_Total",
	  CASE    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> cdsg_stock_cust_in THEN To_Number(i.IM_REPORTING_PRICE)
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = cdsg_stock_cust_in THEN  eom_report_pkg.BREAK_UNIT_PRICE(r.RM_GROUP_CUST,d.SD_STOCK)
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = cdsg_stock_cust_in AND eom_report_pkg.BREAK_UNIT_PRICE(r.RM_GROUP_CUST,d.SD_STOCK) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			      ELSE NULL
			      END                    AS "ReportingPrice",
		s.SH_ADDRESS             AS "Address",
		s.SH_SUBURB              AS "Address2",
		s.SH_CITY                AS "Suburb",
		s.SH_STATE               AS "State",
		s.SH_POST_CODE           AS "Postcode",
		s.SH_NOTE_1              AS "DeliverTo",
		s.SH_NOTE_2              AS "AttentionTo" ,
		t.ST_WEIGHT              AS "Weight",
		t.ST_PACKAGES            AS "Packages",
		s.SH_SPARE_DBL_9         AS "OrderSource",
		NULL AS "Pallet/Shelf Space", /*Pallet/Space*/
		NULL AS "Locn", /*Locn*/
		0 AS "AvailSOH",/*Avail SOH*/
		0 AS "CountOfStocks",
    /*CASE   WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			     ELSE ''
			     END AS Email,*/
    i.IM_BRAND AS Brand
	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER
        INNER JOIN PWIN175.SL l  ON l.SL_PICK   = t.ST_PICK
			  INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
        INNER JOIN PWIN175.NI n  ON n.NI_NV_EXT_KEY = l.SL_UID
  WHERE NI_NV_EXT_TYPE = cdsg_nx_in AND NI_STRENGTH = 3 AND NI_DATE = t.ST_DESP_DATE AND NI_STOCK = d.SD_STOCK AND NI_STATUS <> 0
	AND     s.SH_STATUS <> 3
  AND     i.IM_CUST = cdsg_cust_in
	AND       s.SH_ORDER = t.ST_ORDER
	AND       d.SD_STOCK NOT LIKE cdsg_line_stock_in
	AND       t.ST_DESP_DATE >= cdsg_date_from_in AND t.ST_DESP_DATE <= cdsg_date_to_in
	AND       d.SD_LAST_PICK_NUM = t.ST_PICK
	GROUP BY  s.SH_CUST,
			  s.SH_NOTE_1,
			  s.SH_CAMPAIGN,
			  s.SH_SPARE_STR_4,
			  i.IM_XX_COST_CENTRE01,
			  i.IM_CUST,
			  r.RM_PARENT,
			  s.SH_ORDER,
			  t.ST_PICK,
			  d.SD_XX_PICKLIST_NUM,
			  i.IM_REPORTING_PRICE,
			  i.IM_NOMINAL_VALUE,
			  t.ST_PSLIP,
			  t.ST_DESP_DATE,
			  d.SD_QTY_ORDER,
			  d.SD_QTY_UNIT,
			  d.SD_STOCK,
			  d.SD_DESC,
			  d.SD_LINE,
			  d.SD_EXCL,
			  d.SD_INCL,
			  d.SD_SELL_PRICE,
			  d.SD_XX_OW_UNIT_PRICE,
			  d.SD_QTY_ORDER,
			  d.SD_QTY_ORDER,
			  s.SH_ADDRESS,
			  s.SH_SUBURB,
			  s.SH_CITY,
			  s.SH_STATE,
			  s.SH_POST_CODE,
			  s.SH_NOTE_1,
			  s.SH_NOTE_2,
			  t.ST_WEIGHT,
			  t.ST_PACKAGES,
			  s.SH_SPARE_DBL_9,
			  r.RM_GROUP_CUST,
			  r.RM_PARENT,
			  s.SH_SPARE_STR_5,
			  s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,
			  d.SD_SELL_PRICE,
			  i.IM_OWNED_BY,
			  d.SD_QTY_DESP,
        n.NI_SELL_VALUE,
        n.NI_NX_QUANTITY,
              i.IM_BRAND,
              l.SL_PSLIP_QTY;

    cdsg_rec cdsg_cur%ROWTYPE;
  BEGIN

  OPEN cdsg_cur;
  FETCH cdsg_cur INTO cdsg_rec;
  WHILE cdsg_cur%FOUND
  LOOP
    DBMS_OUTPUT.PUT_LINE(cdsg_rec.Customer || ',' || cdsg_rec.Parent || ',' || cdsg_rec.OrderwareNum || ',' || "cdsg_rec.Order" || ',' || cdsg_rec.PickNum || ',' || cdsg_rec.FeeType || ',' || cdsg_rec.Item || ',' || cdsg_rec.Description );
    FETCH cdsg_cur INTO cdsg_rec;
  END LOOP;
  CLOSE cdsg_cur;
 END CUST_DESP_STOCK_GET;


   /* OPEN gc_cur;
    FETCH gc_cur INTO gc_rec;
    WHILE(gc_cur%FOUND)
    LOOP
      DBMS_OUTPUT.PUT_LINE(gc_rec.Customer || ',' || gc_rec.Parent || ',' || gc_rec.OrderwareNum || ',' || "gc_rec.Order" || ',' || gc_rec.PickNum || ',' || gc_rec.FeeType || ',' || gc_rec.Item || ',' || gc_rec.Description );
      FETCH gc_cur INTO gc_rec;
    END LOOP;
    CLOSE gc_cur;
  END CUST_DESP_STOCK_GET;  */
--Customer	Parent	CostCentre	Order	OrderwareNum	CustomerRef	Pickslip	PickNum	DespatchNote	DespatchDate	FeeType	Item	Description	Qty	UOI	Batch/UnitPrice	OWUnitPrice	DExcl	Excl_Total	DIncl	Incl_Total	ReportingPrice	Address	Address2	Suburb	State	Postcode	DeliverTo	AttentionTo	Weight	Packages	OrderSource	Pallet/Shelf Space	Locn	AvailSOH	CountOfStocks	EMAIL	BRAND



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