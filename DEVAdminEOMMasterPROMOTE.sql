  /* First run this file with variables set in header - declare variables - drop tables, recreate tables, insert into tables - then query tables */
  /* EOM_INVOICING_CREATE_TABLES.sql */
/*decalre variables These are being declared via the stored procedure - just need to redeclare cust so as we can get the rates*/

--SELECT RM_ANAL FROM RM WHERE RM_CUST = 'G-VICPROMO'
var cust varchar2(20)
exec :cust := 'G-VICPROMO'
var nx NUMBER
EXEC :nx := 1810105
var cust2 varchar2(20)
exec :cust2 := 'LINK14'
var ordernum varchar2(20)
exec :ordernum := '1363806'
var stock varchar2(20)
exec :stock := 'COURIER'
var source varchar2(20)
exec :source := 'BSPRINTN'
var sAnalysis varchar2(20) /*VerbalOrderEntryFee*/
exec SELECT  RM_ANAL INTO :sAnalysis FROM RM where RM_CUST = :cust;
var anal varchar2(20)
exec :anal := 'VICP'
var start_date varchar2(20)
exec :start_date := To_Date('1-Jan-2017')
var end_date varchar2(20)
exec :end_date := To_Date('31-Jan-2017')



    --run this first
    TRUNCATE TABLE  dev_AdminData;
    --run this first
    --EXECUTE EOM_REPORT_PKG.DEV_CREATE_TEMP_DATA_BIND('VICP','1-Jan-2017','31-Jan-2017');   --15 minutes  for all customers
    --now run 1 of these -change variables at top first for each run
    --EXECUTE DEV_TEMP_LOCN_ALL_CUST();         --  1:25 minutes
    --  The Below for one client LINK in the middle of a business day took 1:09 minutes

  /*SELECT  RM_ANAL FROM RM WHERE RM_CUST = 'LINK' */

    var nCountCustStocks NUMBER /*VerbalOrderEntryFee*/
    exec SELECT  Count(IM_STOCK) INTO :nCountCustStocks FROM IM where IM_CUST = :cust AND IM_ACTIVE = 1;



    var nRM_XX_FEE01 NUMBER /*VerbalOrderEntryFee*/
    exec SELECT  To_Number(regexp_substr(RM_XX_FEE01,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE01 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE02 NUMBER /*EmailOrderEntryFee*/
    exec SELECT  To_Number(regexp_substr(RM_XX_FEE02,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE02 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE03 NUMBER /*PhoneOrderEntryFee*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE03,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE03 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE04 NUMBER /*PhoneOrderEntryFee*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE04,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE04 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE05 NUMBER /*PhoneOrderEntryFee*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE05,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE05 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE06 NUMBER /*Handeling Fee*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE06 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE07 NUMBER /*FaxOrderEntryFee*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE07,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE07 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE08 NUMBER /*InnerPackingFee*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE08 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE09 NUMBER /*OuterPackingFee*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE09 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE10 NUMBER /*FTPOrderEntryFee*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE10,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE10 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE11 NUMBER /*Pallet Storage Fee*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE11 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE12 NUMBER /*Shelf Storage Fee*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE12 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE13 NUMBER /*Carton In Fee*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE13,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE13 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE14 NUMBER /*Pallet In Fee*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE14 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE15 NUMBER /*Carton Despatch Fee*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE15 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE16 NUMBER /*Pick Fee*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE16 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE17 NUMBER /*Pallet Despatch Fee*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE17,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE17 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE18 NUMBER /*ShrinkWrap Fee*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE18 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE19 NUMBER /*Admin Fee*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE19,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE19 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE20 NUMBER /*Stock Maintenance Fee*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE20,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE20 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE21 NUMBER /*DB Maintenance Fee*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE21,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE21 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE22 NUMBER /*Bin Monthly Storage Fee*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE22,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE22 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE23 NUMBER /*Daily Delivery Fee*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE23,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE23 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE24 NUMBER /*Carton Destruction Fee*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE24,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE24 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE25 NUMBER /*Pallet Destruction Fee*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE25 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE26 NUMBER /*Additional Pallet Destruction Fee*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE26,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE26 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE27 NUMBER /*Order Fee*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE27,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE27 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE28 NUMBER /*Pallet Secured Storage Fee*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE28,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE28 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE29 NUMBER /*Pallet Slow Moving Secured Fee*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE29,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE29 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE30 NUMBER /*Shelf Slow Moving Fee*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE30,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE30 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE31 NUMBER /*Secured Shelf Storage Fee*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE31,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE31 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE32 NUMBER /*Pallet Archive Monthly Fee*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE32,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE32 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE33 NUMBER /*Shelf Archive Monthly Fee*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE33,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE33 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE34 NUMBER /*Manual Report Run Fee*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE34,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE34 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE35 NUMBER /*Kitting Fee P/H*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE35,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE35 FROM RM where RM_CUST = :cust;

    var nRM_XX_FEE36 NUMBER /*Pick Fee 2nd Scale*/
    exec SELECT To_Number(regexp_substr(RM_XX_FEE36,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE36 FROM RM where RM_CUST = :cust;

    var nRM_SPARE_CHAR_3 NUMBER /*Pallet Slow Moving Fee*/
    exec SELECT To_Number(regexp_substr(RM_SPARE_CHAR_3,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_SPARE_CHAR_3 FROM RM where RM_CUST = :cust;

    var nRM_SPARE_CHAR_5 NUMBER /*System Maintenance Fee*/
    exec SELECT To_Number(regexp_substr(RM_SPARE_CHAR_5,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_SPARE_CHAR_5 FROM RM where RM_CUST = :cust;

    var nRM_SPARE_CHAR_4 NUMBER /*Stocktake Fee P/H*/
    exec SELECT To_Number(regexp_substr(RM_SPARE_CHAR_4,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_SPARE_CHAR_4 FROM RM where RM_CUST = :cust;

    var nRM_XX_ADMIN_CHG NUMBER /*Shelf Slow Moving Secured Fee*/
    exec SELECT To_Number(regexp_substr(RM_XX_ADMIN_CHG,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_ADMIN_CHG FROM RM where RM_CUST = :cust;

   -- var nRM_XX_PALLET_CHG NUMBER /*Return Per Pallet Fee*/
   -- exec SELECT To_Number(regexp_substr(RM_XX_PALLET_CHG,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_PALLET_CHG FROM RM where RM_CUST = :cust;

   -- var nRM_XX_SHELF_CHG NUMBER /*Return Per Shelf Fee*/
   -- exec SELECT To_Number(regexp_substr(RM_XX_SHELF_CHG,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_SHELF_CHG FROM RM where RM_CUST = :cust;

   -- var nRM_XX_FEE31_1 NUMBER /*Minimun Monthly Charge Fee*/
   -- exec SELECT To_Number(regexp_substr(RM_XX_FEE31_1,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE31_1 FROM RM where RM_CUST = :cust;

  --  var nRM_XX_FEE32_1 NUMBER /*UnallocatedFee*/
   -- exec SELECT To_Number(regexp_substr(RM_XX_FEE32_1,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE32_1 FROM RM where RM_CUST = :cust;

   -- var nRM_XX_FEE33_1 NUMBER /*UnallocatedFee*/
   -- exec SELECT To_Number(regexp_substr(RM_XX_FEE33_1,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE33_1 FROM RM where RM_CUST = :cust;

   -- var nRM_XX_FEE34_1 NUMBER /*UnallocatedFee*/
   -- exec SELECT To_Number(regexp_substr(RM_XX_FEE34_1,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE34_1 FROM RM where RM_CUST = :cust;

   -- var nRM_XX_FEE35_1 NUMBER /*UnallocatedFee*/
   -- exec SELECT To_Number(regexp_substr(RM_XX_FEE35_1,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE35_1 FROM RM where RM_CUST = :cust;

    --var nRM_XX_FEE36_1 NUMBER /*UnallocatedFee*/
   -- exec SELECT To_Number(regexp_substr(RM_XX_FEE36_1,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE36_1 FROM RM where RM_CUST = :cust;
  /*decalre variables*/


   --SELECT * FROM tbl_AdminData
    --TRUNCATE TABLE tbl_AdminData
  --EXEC EOM_INVOICING();--:cust,:ordernum,:stock,:source,:sAnalysis,:start_date,:end_date);
    --SET TIMING ON;

  /*insert into temp admin data table   */

	  INSERT into Dev_AdminData( --Select * From Tmp_Cust_Reporting )
				  Customer,
				  Parent,
				  CostCentre,
				  OrderNum,
				  OrderwareNum,
				  CustRef,
				  Pickslip,
				  PickNum,
				  DespatchNote,
				  DespatchDate,
				  FeeType,
				  Item,
				  Description,
				  Qty,
				  UOI,
				  UnitPrice,
				  OW_Unit_Sell_Price,
				  Sell_Excl,
				  Sell_Excl_Total,
				  Sell_Incl,
				  Sell_Incl_Total,
				  ReportingPrice,
				  Address,
				  Address2,
				  Suburb,
				  State,
				  Postcode,
				  DeliverTo,
				  AttentionTo,
				  Weight,
				  Packages,
				  OrderSource,
				  ILNOTE2,
				  NILOCN,
				  CountOfStocks,
          Email,
          Brand,
          OwnedBy,
          sProfile,
          WaiveFee,
          Cost,
          PaymentType


				  )
  /*insert into temp admin data table*/

  /*freight fees*/             --8 secs
	  select    s.SH_CUST           AS "Customer",
			    r.RM_PARENT              AS "Parent",
         -- r.RM_ANAL,
			    s.SH_SPARE_STR_4         AS "CostCentre",
			    s.SH_ORDER               AS "Order",
			    s.SH_SPARE_STR_5         AS "OrderwareNum",
			    s.SH_CUST_REF            AS "CustomerRef",
			    d.SD_XX_PICKLIST_NUM     AS "Pickslip",
			    d.SD_XX_PICKLIST_NUM         AS "PickNum",
			    d.SD_XX_PSLIP_NUM               AS "DespatchNote",
			    substr(To_Char(d.SD_ADD_DATE),0,10)            AS "DespatchDate",
	        CASE  WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 THEN 'Freight Fee'
                WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE < 1 THEN 'Unpriced Freight'
			          ELSE To_Char(d.SD_DESC)
			          END                      AS "FeeType",
			    d.SD_STOCK               AS "Item",
			    '="' || To_Char(d.SD_DESC) || '"'               AS "Description",
	        CASE  WHEN d.SD_LINE IS NOT NULL THEN  1
			          ELSE NULL
			          END                     AS "Qty",
	        CASE  WHEN d.SD_LINE IS NOT NULL THEN  '1'
			          ELSE NULL
			          END                      AS "UOI",

          CASE  WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT <> 'BORBUI' AND r.RM_PARENT <> 'BEYONDBLUE') THEN d.SD_SELL_PRICE
			          WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT = 'BORBUI' OR r.RM_PARENT = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.125) And (t.ST_SPARE_DBL_1 > 0.00) THEN 1.70
                WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT = 'BORBUI' OR r.RM_PARENT = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.250) And (t.ST_SPARE_DBL_1 > 0.126) THEN 2.30
                WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT = 'BORBUI' OR r.RM_PARENT = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.500) And (t.ST_SPARE_DBL_1 > 0.251) THEN 3.40
                WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT = 'BORBUI' OR r.RM_PARENT = 'BEYONDBLUE') AND (t.ST_WEIGHT > 0.01) THEN d.SD_SELL_PRICE
                ELSE NULL
			          END                AS "UnitPrice",
			    d.SD_XX_OW_UNIT_PRICE    AS "OWUnitPrice",
			    d.SD_EXCL                AS "DExcl",
			    Sum(d.SD_EXCL)           AS "Excl_Total",
			    d.SD_INCL                AS "DIncl",
			    Sum(d.SD_INCL)           AS "Incl_Total",
			    NULL                     AS "ReportingPrice",
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
				  0 AS "CountOfStocks",
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			          ELSE ''
			          END AS Email,
                'N/A' AS Brand,
           NULL AS    OwnedBy,
           NULL AS    sProfile,
           NULL AS    WaiveFee,
           d.SD_COST_PRICE As   Cost,
           NULL AS PaymentType

	  FROM      PWIN171.SD d
			    INNER JOIN PWIN171.SH s  ON s.SH_ORDER  = d.SD_ORDER
			    INNER JOIN PWIN171.ST t  ON LTRIM(RTRIM(t.ST_PICK))  = LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM))
			    INNER JOIN PWIN171.RM r  ON r.RM_CUST  = s.SH_CUST
	  WHERE     s.SH_ORDER = d.SD_ORDER
	  AND       r.RM_ANAL = :sAnalysis
	  	AND       d.SD_STOCK IN ('COURIERM','COURIERS','COURIER')
	AND       s.SH_ORDER = t.ST_ORDER
	AND       d.SD_SELL_PRICE >= 0.1
	AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
  AND   d.SD_ADD_OP LIKE 'SERV%'


	  GROUP BY  s.SH_CUST, r.RM_ANAL,
			    s.SH_SPARE_STR_4,
			    s.SH_ORDER,
			    t.ST_PICK,
			    d.SD_XX_PICKLIST_NUM,
			    t.ST_PSLIP,
			    t.ST_DESP_DATE,
			    d.SD_STOCK,
			    d.SD_DESC,
			    d.SD_LINE,
			    d.SD_EXCL,
			    d.SD_INCL,
			    d.SD_NOTE_1,
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
			    r.RM_PARENT,
			    s.SH_SPARE_STR_5,
			    s.SH_CUST_REF,
          s.SH_SPARE_STR_3,
          s.SH_SPARE_STR_1,
          t.ST_SPARE_DBL_1,
          d.SD_XX_PSLIP_NUM,
          d.SD_ADD_DATE,
          d.SD_XX_PICKLIST_NUM,
          d.SD_COST_PRICE




	  UNION ALL

  /*freight fees*/



  /*Manual freight fees*/
	  select    s.SH_CUST                AS "Customer",
			    r.RM_PARENT              AS "Parent",
			    s.SH_SPARE_STR_4         AS "CostCentre",
			    s.SH_ORDER               AS "Order",
			    s.SH_SPARE_STR_5         AS "OrderwareNum",
			    s.SH_CUST_REF            AS "CustomerRef",
			    t.ST_PICK                AS "Pickslip",
			    d.SD_XX_PICKLIST_NUM     AS "PickNum",
			    t.ST_PSLIP               AS "DespatchNote",
			    substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	        CASE  WHEN d.SD_STOCK IN ('COURIERM','COURIERS','COURIER','DETENTIONTIMEM','DETENTIONTIMES','FREIGHTDUTY') AND d.SD_SELL_PRICE >= 1  THEN 'Manual Freight Fee'
			          WHEN d.SD_STOCK IN ('COURIERM','COURIERS','COURIER','DETENTIONTIMEM','DETENTIONTIMES','FREIGHTDUTY') AND d.SD_SELL_PRICE < 1 THEN 'Unpriced Freight'
			          ELSE NULL
			          END                      AS "FeeType",
			    d.SD_STOCK               AS "Item",
			    '="' || To_Char(d.SD_DESC) || '"'               AS "Description",
	        CASE  WHEN d.SD_LINE IS NOT NULL THEN  1
			          ELSE NULL
			          END                     AS "Qty",
	        CASE  WHEN d.SD_LINE IS NOT NULL THEN  '1'
			          ELSE NULL
			          END                      AS "UOI",
			    d.SD_SELL_PRICE          AS "UnitPrice",
			    d.SD_XX_OW_UNIT_PRICE    AS "OWUnitPrice",
			    d.SD_EXCL                AS "DExcl",
			    Sum(d.SD_EXCL)           AS "Excl_Total",
			    d.SD_INCL                AS "DIncl",
			    Sum(d.SD_INCL)           AS "Incl_Total",
			    NULL                     AS "ReportingPrice",
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
				  0 AS "CountOfStocks",
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			          ELSE ''
			          END AS Email,
                'N/A' AS Brand,
           NULL AS    OwnedBy,
           NULL AS    sProfile,
           NULL AS    WaiveFee,
           d.SD_COST_PRICE As   Cost,
           NULL AS PaymentType


           FROM      PWIN171.SD d
			    INNER JOIN PWIN171.SH s  ON s.SH_ORDER  = d.SD_ORDER
			          INNER JOIN PWIN171.ST t  ON LTRIM(RTRIM(t.ST_PICK))  = LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM))
			          INNER JOIN PWIN171.RM r  ON r.RM_CUST  = s.SH_CUST
	        WHERE     s.SH_ORDER = d.SD_ORDER
	  AND       r.RM_ANAL = :sAnalysis
    --	AND       (r.RM_PARENT = :cust OR r.RM_CUST = :cust)
	  AND       d.SD_STOCK IN ('COURIERM','COURIERS','COURIER','DETENTIONTIMEM','DETENTIONTIMES','FREIGHTDUTY')
	  AND       s.SH_ORDER = t.ST_ORDER
	  	AND       d.SD_SELL_PRICE >= 0.1
  --AND d.SD_ADD_DATE = '2-MAY-2014' AND d.SD_ADD_OP = 'PRJ'
	AND       d.SD_ADD_DATE >= :start_date AND d.SD_ADD_DATE <= :end_date
  AND   d.SD_ADD_OP NOT LIKE 'SERV%'

	  GROUP BY  s.SH_CUST,
			    s.SH_SPARE_STR_4,
			    s.SH_ORDER,
			    t.ST_PICK,
			    d.SD_XX_PICKLIST_NUM,
			    t.ST_PSLIP,
			    t.ST_DESP_DATE,
			    d.SD_STOCK,
			    d.SD_DESC,
			    d.SD_LINE,
			    d.SD_EXCL,
			    d.SD_INCL,
			    d.SD_NOTE_1,
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
			    r.RM_PARENT,
			    s.SH_SPARE_STR_5,
			    s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,d.SD_COST_PRICE







	  UNION ALL
  /*manual freight fees*/

  /*PhoneOrderEntryFee*/
	  SELECT    s.SH_CUST               AS "Customer",
			    r.RM_PARENT              AS "Parent",
			    CASE    WHEN i.IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
			    WHEN i.IM_CUST = 'TABCORP' THEN i.IM_XX_COST_CENTRE01
			    ELSE s.SH_SPARE_STR_4
			    END                      AS "CostCentre",
			    s.SH_ORDER              AS "Order",
			    s.SH_SPARE_STR_5         AS "OrderwareNum",
			    s.SH_CUST_REF            AS "CustomerRef",
			    NULL               AS "Pickslip",
			    NULL                    AS "PickNum",
			    NULL              AS "DespatchNote",
			    substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  'OrderEntryFee'
			    ELSE ''
			    END                     AS "FeeType",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  'FEEORDERENTRYS'
			    ELSE ''
			    END                     AS "Item",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  'Phone Order Entry Fee'
			    ELSE ''
			    END                     AS "Description",
	    CASE    WHEN d.SD_LINE = 1 THEN  1
			    ELSE NULL
			    END                     AS "Qty",
	    CASE    WHEN d.SD_LINE = 1 THEN  '1'
			    ELSE ''
			    END                     AS "UOI",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  :nRM_XX_FEE03 --(Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = :cust)
			    ELSE NULL
			    END                     AS "UnitPrice",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  :nRM_XX_FEE03 --(Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = :cust)
			    ELSE NULL
			    END                     AS "OWUnitPrice",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  :nRM_XX_FEE03 --(Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = :cust)
			    ELSE NULL
			    END                     AS "DExcl",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  :nRM_XX_FEE03 --(Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = :cust)
			    ELSE NULL
			    END                     AS "Excl_Total",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN   :nRM_XX_FEE03 * 1.1--(Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = :cust) * 1.1
			    ELSE NULL
			    END                     AS "DIncl",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  :nRM_XX_FEE03 * 1.1--(Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = :cust) * 1.1
			    ELSE NULL
			    END                     AS "Incl_Total",
			    NULL                    AS "ReportingPrice",
			    s.SH_ADDRESS            AS "Address",
			    s.SH_SUBURB             AS "Address2",
			    s.SH_CITY               AS "Suburb",
			    s.SH_STATE              AS "State",
			    s.SH_POST_CODE          AS "Postcode",
			    s.SH_NOTE_1             AS "DeliverTo",
			    s.SH_NOTE_2             AS "AttentionTo" ,
			    0             AS "Weight",
			    0           AS "Packages",
			    s.SH_SPARE_DBL_9        AS "OrderSource",
			    NULL AS "Pallet/Shelf Space", /*Pallet/Space*/
				  NULL AS "Locn", /*Locn*/
				  0 AS "CountOfStocks",
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			          ELSE ''
			          END AS Email,
                'N/A' AS Brand,
           i.IM_OWNED_By AS    OwnedBy,
           i.IM_PROFILE AS    sProfile,
           s.SH_XX_FEE_WAIVE AS    WaiveFee,
           d.SD_COST_PRICE As   Cost,
           s.SH_SPARE_INT_4 AS PaymentType
	  FROM      PWIN171.SH s
			    INNER JOIN PWIN171.SD d ON d.SD_ORDER  = s.SH_ORDER
			    INNER JOIN PWIN171.IM i ON i.IM_STOCK = d.SD_STOCK
			    INNER JOIN PWIN171.ST t ON t.ST_ORDER = s.SH_ORDER AND t.ST_PICK = s.SH_LAST_PICK_NUM
			    INNER JOIN PWIN171.RM r ON r.RM_CUST  = s.SH_CUST
			    --LEFT JOIN PWIN171.RM r2 ON r2.RM_ANAL = r.RM_ANAL AND r2.RM_CUST = :cust
	  WHERE r.RM_ANAL = :sAnalysis
    AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
	  AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	  AND       s.SH_SPARE_DBL_9 = 1
	  AND       d.SD_LINE = 1
	  --AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> 0
	  --AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> '0'
	  --AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) IS NOT NULL
	  AND     :nRM_XX_FEE03 > 0
	  GROUP BY  s.SH_CUST,
			    s.SH_ADD_DATE,
			    s.SH_SPARE_STR_4,
			    s.SH_ORDER,
			    s.SH_PREV_PSLIP_NUM,
			    t.ST_DESP_DATE,
			    s.SH_SPARE_DBL_9,
			    d.SD_LINE,
			    s.SH_ADDRESS,
			    s.SH_SUBURB,
			    s.SH_CITY,
			    s.SH_STATE,
			    s.SH_POST_CODE,
			    s.SH_NOTE_1,
			    s.SH_NOTE_2,
			    s.SH_SPARE_DBL_9,
			    r.RM_PARENT,
			    i.IM_CUST,
			    i.IM_XX_COST_CENTRE01,
			    s.SH_SPARE_STR_5,
			    s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4






	  UNION ALL
  /*PhoneOrderEntryFee*/

  /*EmailOrderEntryFee*/
	  SELECT    s.SH_CUST               AS "Customer",
			    r.RM_PARENT              AS "Parent",
			    CASE    WHEN i.IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
			    WHEN i.IM_CUST = 'TABCORP' THEN i.IM_XX_COST_CENTRE01
			    ELSE s.SH_SPARE_STR_4
			    END                      AS "CostCentre",
			    s.SH_ORDER              AS "Order",
			    s.SH_SPARE_STR_5         AS "OrderwareNum",
			    s.SH_CUST_REF            AS "CustomerRef",
			    NULL               AS "Pickslip",
			    NULL                    AS "PickNum",
			    NULL              AS "DespatchNote",
			    substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  'OrderEntryFee'
			    ELSE ''
			    END                     AS "FeeType",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  'FEEORDERENTRYS'
			    ELSE ''
			    END                     AS "Item",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  'Email Order Entry Fee'
			    ELSE ''
			    END                     AS "Description",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 3  THEN  1
			    ELSE NULL
			    END                     AS "Qty",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  '1'
			    ELSE ''
			    END                     AS "UOI",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN :nRM_XX_FEE02 -- (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = :cust)
			    ELSE NULL
			    END                     AS "UnitPrice",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN :nRM_XX_FEE02 --  (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = :cust)
			    ELSE NULL
			    END                     AS "OWUnitPrice",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  :nRM_XX_FEE02 -- (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = :cust)
			    ELSE NULL
			    END                     AS "DExcl",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN :nRM_XX_FEE02 --  (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = :cust)
			    ELSE NULL
			    END                     AS "Excl_Total",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  :nRM_XX_FEE02 * 1.1 --  (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = :cust) * 1.1
			    ELSE NULL
			    END                     AS "DIncl",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  :nRM_XX_FEE02 * 1.1 -- (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = :cust) * 1.1
			    ELSE NULL
			    END                     AS "Incl_Total",
			    NULL                    AS "ReportingPrice",
			    s.SH_ADDRESS            AS "Address",
			    s.SH_SUBURB             AS "Address2",
			    s.SH_CITY               AS "Suburb",
			    s.SH_STATE              AS "State",
			    s.SH_POST_CODE          AS "Postcode",
			    s.SH_NOTE_1             AS "DeliverTo",
			    s.SH_NOTE_2             AS "AttentionTo" ,
			    0             AS "Weight",
			    0           AS "Packages",
			    s.SH_SPARE_DBL_9        AS "OrderSource",
			    NULL AS "Pallet/Shelf Space", /*Pallet/Space*/
				  NULL AS "Locn", /*Locn*/

				  0 AS "CountOfStocks",
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			          ELSE ''
			          END AS Email,
                'N/A' AS Brand,
           i.IM_OWNED_By AS    OwnedBy,
           i.IM_PROFILE AS    sProfile,
           s.SH_XX_FEE_WAIVE AS    WaiveFee,
           d.SD_COST_PRICE As   Cost,
           s.SH_SPARE_INT_4 AS PaymentType
	  FROM      PWIN171.SH s
			    INNER JOIN PWIN171.SD d ON d.SD_ORDER  = s.SH_ORDER
			    INNER JOIN PWIN171.IM i ON i.IM_STOCK = d.SD_STOCK
			    INNER JOIN PWIN171.ST t ON t.ST_ORDER = s.SH_ORDER AND t.ST_PICK = s.SH_LAST_PICK_NUM
			    INNER JOIN PWIN171.RM r ON r.RM_CUST  = s.SH_CUST
			    --LEFT JOIN PWIN171.RM r2 ON r2.RM_ANAL = r.RM_ANAL AND r2.RM_CUST = :cust
	  WHERE (r.RM_ANAL = :sAnalysis)
    AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
	  AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	  AND       s.SH_SPARE_DBL_9 = 3
	  AND       d.SD_LINE = 1
	  --AND       Select rm3.RM_XX_FEE02 from RM rm3 where To_Number(regexp_substr(rm3.RM_XX_FEE02,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0 AND rm3.RM_CUST = :cust
	  AND      :nRM_XX_FEE02 > 0 --AND rm3.RM_CUST = :cust
	  --AND       (Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust) <> 0
	  --AND       (Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust) <> '0'
	  --AND       (Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust) IS NOT NULL
	  GROUP BY  s.SH_CUST,
			    s.SH_ADD_DATE,
			    s.SH_SPARE_STR_4,
			    s.SH_ORDER,
			    s.SH_PREV_PSLIP_NUM,
			    t.ST_DESP_DATE,
			    s.SH_SPARE_DBL_9,
			    d.SD_LINE,
			    s.SH_ADDRESS,
			    s.SH_SUBURB,
			    s.SH_CITY,
			    s.SH_STATE,
			    s.SH_POST_CODE,
			    s.SH_NOTE_1,
			    s.SH_NOTE_2,
			    s.SH_SPARE_DBL_9,
			    r.RM_PARENT,
			    i.IM_CUST,
			    i.IM_XX_COST_CENTRE01,
			    s.SH_SPARE_STR_5,
			    s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4






	  UNION ALL
  /*EmailOrderEntryFee*/

  /*FaxOrderEntryFee*/
	  SELECT    s.SH_CUST               AS "Customer",
			    r.RM_PARENT              AS "Parent",
			    CASE    WHEN i.IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
			    WHEN i.IM_CUST = 'TABCORP' THEN i.IM_XX_COST_CENTRE01
			    ELSE s.SH_SPARE_STR_4
			    END                      AS "CostCentre",
			    s.SH_ORDER              AS "Order",
			    s.SH_SPARE_STR_5         AS "OrderwareNum",
			    s.SH_CUST_REF            AS "CustomerRef",
			    NULL               AS "Pickslip",
			    NULL                    AS "PickNum",
			    NULL              AS "DespatchNote",
			    substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  'OrderEntryFee'
			    ELSE ''
			    END                     AS "FeeType",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  'FEEORDERENTRYS'
			    ELSE ''
			    END                     AS "Item",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  'Fax Order Entry Fee'
			    ELSE ''
			    END                     AS "Description",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  1
			    ELSE NULL
			    END                     AS "Qty",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  '1'
			    ELSE ''
			    END                     AS "UOI",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  :nRM_XX_FEE07 -- (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = :cust)
			    ELSE NULL
			    END                     AS "UnitPrice",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN :nRM_XX_FEE07 -- (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = :cust)
			    ELSE NULL
			    END                     AS "OWUnitPrice",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN :nRM_XX_FEE07 -- (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = :cust)
			    ELSE NULL
			    END                     AS "DExcl",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN :nRM_XX_FEE07 -- (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = :cust)
			    ELSE NULL
			    END                     AS "Excl_Total",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  :nRM_XX_FEE07 * 1.1 -- (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = :cust) * 1.1
			    ELSE NULL
			    END                     AS "DIncl",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN :nRM_XX_FEE07 * 1.1 -- (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = :cust) * 1.1
			    ELSE NULL
			    END                     AS "Incl_Total",
			    NULL                    AS "ReportingPrice",
			    s.SH_ADDRESS            AS "Address",
			    s.SH_SUBURB             AS "Address2",
			    s.SH_CITY               AS "Suburb",
			    s.SH_STATE              AS "State",
			    s.SH_POST_CODE          AS "Postcode",
			    s.SH_NOTE_1             AS "DeliverTo",
			    s.SH_NOTE_2             AS "AttentionTo" ,
			    0             AS "Weight",
			    0           AS "Packages",
			    s.SH_SPARE_DBL_9        AS "OrderSource",
			    NULL AS "Pallet/Shelf Space", /*Pallet/Space*/
				  NULL AS "Locn", /*Locn*/

				  0 AS "CountOfStocks",
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			          ELSE ''
			          END AS Email,
                'N/A' AS Brand,
           i.IM_OWNED_By AS    OwnedBy,
           i.IM_PROFILE AS    sProfile,
           s.SH_XX_FEE_WAIVE AS    WaiveFee,
           d.SD_COST_PRICE As   Cost,
           s.SH_SPARE_INT_4 AS PaymentType
	  FROM      PWIN171.SH s
			    INNER JOIN PWIN171.SD d ON d.SD_ORDER  = s.SH_ORDER
			    INNER JOIN PWIN171.IM i ON i.IM_STOCK = d.SD_STOCK
			    INNER JOIN PWIN171.ST t ON t.ST_ORDER = s.SH_ORDER AND t.ST_PICK = s.SH_LAST_PICK_NUM
			    INNER JOIN PWIN171.RM r ON r.RM_CUST  = s.SH_CUST
			    --LEFT JOIN PWIN171.RM r2 ON r2.RM_ANAL = r.RM_ANAL AND r2.RM_CUST = :cust
	  WHERE (r.RM_ANAL = :sAnalysis)
    AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
	  AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	  AND       s.SH_SPARE_DBL_9 = 2
	  AND       d.SD_LINE = 1
	  --AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> 0
	  --AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> '0'
	  --AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) IS NOT NULL
	  AND      :nRM_XX_FEE07 > 0
	  GROUP BY  s.SH_CUST,
			    s.SH_ADD_DATE,
			    s.SH_SPARE_STR_4,
			    s.SH_ORDER,
			    s.SH_PREV_PSLIP_NUM,
			    t.ST_DESP_DATE,
			    s.SH_SPARE_DBL_9,
			    d.SD_LINE,
			    s.SH_ADDRESS,
			    s.SH_SUBURB,
			    s.SH_CITY,
			    s.SH_STATE,
			    s.SH_POST_CODE,
			    s.SH_NOTE_1,
			    s.SH_NOTE_2,
			    s.SH_SPARE_DBL_9,
			    r.RM_PARENT,
			    i.IM_CUST,
			    i.IM_XX_COST_CENTRE01,
			    s.SH_SPARE_STR_5,
			    s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4






	  UNION ALL
  /*FaxOrderEntryFee*/

  /*VerbalOrderEntryFee*/
	  SELECT    s.SH_CUST               AS "Customer",
			    r.RM_PARENT              AS "Parent",
			    CASE    WHEN i.IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
			    WHEN i.IM_CUST = 'TABCORP' THEN i.IM_XX_COST_CENTRE01
			    ELSE s.SH_SPARE_STR_4
			    END                      AS "CostCentre",
			    s.SH_ORDER              AS "Order",
			    s.SH_SPARE_STR_5         AS "OrderwareNum",
			    s.SH_CUST_REF            AS "CustomerRef",
			    NULL               AS "Pickslip",
			    NULL                    AS "PickNum",
			    NULL              AS "DespatchNote",
			    substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  'OrderEntryFee'
			    ELSE ''
			    END                     AS "FeeType",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  'FEEORDERENTRYS'
			    ELSE ''
			    END                     AS "Item",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  'Phone Order Entry Fee'
			    ELSE ''
			    END                     AS "Description",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  1
			    ELSE NULL
			    END                     AS "Qty",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  '1'
			    ELSE ''
			    END                     AS "UOI",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN :nRM_XX_FEE01 -- (Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = :cust)
			    ELSE NULL
			    END                     AS "UnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN :nRM_XX_FEE01 -- (Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = :cust)
			    ELSE NULL
			    END                     AS "OWUnitPrice",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN :nRM_XX_FEE01 -- (Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = :cust)
			    ELSE NULL
			    END                     AS "DExcl",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN :nRM_XX_FEE01 -- (Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = :cust)
			    ELSE NULL
			    END                     AS "Excl_Total",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN :nRM_XX_FEE01 * 1.1 --  (Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = :cust) * 1.1
			    ELSE NULL
			    END                     AS "DIncl",
	    CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN :nRM_XX_FEE01 * 1.1-- (Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = :cust) * 1.1
			    ELSE NULL
			    END                     AS "Incl_Total",
			    NULL                    AS "ReportingPrice",
			    s.SH_ADDRESS            AS "Address",
			    s.SH_SUBURB             AS "Address2",
			    s.SH_CITY               AS "Suburb",
			    s.SH_STATE              AS "State",
			    s.SH_POST_CODE          AS "Postcode",
			    s.SH_NOTE_1             AS "DeliverTo",
			    s.SH_NOTE_2             AS "AttentionTo" ,
			    NULL             AS "Weight",
			    NULL           AS "Packages",
			    s.SH_SPARE_DBL_9        AS "OrderSource",
			    NULL AS "Pallet/Shelf Space", /*Pallet/Space*/
				  NULL AS "Locn", /*Locn*/

				  0 AS "CountOfStocks",
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			          ELSE ''
			          END AS Email,
                'N/A' AS Brand,
           i.IM_OWNED_By AS    OwnedBy,
           i.IM_PROFILE AS    sProfile,
           s.SH_XX_FEE_WAIVE AS    WaiveFee,
           d.SD_COST_PRICE As   Cost,
           s.SH_SPARE_INT_4 AS PaymentType
	  FROM      PWIN171.SH s
			    INNER JOIN PWIN171.SD d ON d.SD_ORDER  = s.SH_ORDER
			    INNER JOIN PWIN171.IM i ON i.IM_STOCK = d.SD_STOCK
			    INNER JOIN PWIN171.ST t ON t.ST_ORDER = s.SH_ORDER AND t.ST_PICK = s.SH_LAST_PICK_NUM
			    INNER JOIN PWIN171.RM r ON r.RM_CUST  = s.SH_CUST
			    --LEFT JOIN PWIN171.RM r2 ON r2.RM_ANAL = r.RM_ANAL AND r2.RM_CUST = :cust
	  WHERE (r.RM_ANAL = :sAnalysis)
    AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
	  AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	  AND       s.SH_SPARE_DBL_9 = 4
	  AND       d.SD_LINE = 1
	  --AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> 0
	  --AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> '0'
	  --AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) IS NOT NULL
	  AND     :nRM_XX_FEE01 > 0
	  GROUP BY  s.SH_CUST,
			    s.SH_ADD_DATE,
			    s.SH_SPARE_STR_4,
			    s.SH_ORDER,
			    s.SH_PREV_PSLIP_NUM,
			    t.ST_DESP_DATE,
			    s.SH_SPARE_DBL_9,
			    d.SD_LINE,
			    s.SH_ADDRESS,
			    s.SH_SUBURB,
			    s.SH_CITY,
			    s.SH_STATE,
			    s.SH_POST_CODE,
			    s.SH_NOTE_1,
			    s.SH_NOTE_2,
			    s.SH_SPARE_DBL_9,
			    r.RM_PARENT,
			    i.IM_CUST,
			    i.IM_XX_COST_CENTRE01,
			    s.SH_SPARE_STR_5,
			    s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4






	  UNION ALL
  /*VerbalOrderEntryFee*/

  /*BB PackingFee*/
	  SELECT    s.SH_CUST                AS "Customer",
			    r.RM_PARENT              AS "Parent",
			    s.SH_SPARE_STR_4         AS "CostCentre",
			    s.SH_ORDER               AS "Order",
			    s.SH_SPARE_STR_5         AS "OrderwareNum",
			    s.SH_CUST_REF            AS "CustomerRef",
			    t.ST_PICK                AS "Pickslip",
			    d.SD_XX_PICKLIST_NUM     AS "PickNum",
			    t.ST_PSLIP               AS "DespatchNote",
			    substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	    CASE    WHEN (i.IM_TYPE = 'BB_PACK' AND (d.SD_STOCK NOT like 'COURIER%' AND d.SD_STOCK NOT like 'FEE%'))  THEN 'Packing Fee'
			    ELSE NULL
			    END                      AS "FeeType",
			    d.SD_STOCK               AS "Item",
			    d.SD_DESC                AS "Description",
	    CASE    WHEN d.SD_LINE IS NOT NULL THEN  1
			    ELSE NULL
			    END                     AS "Qty",
	    CASE    WHEN d.SD_LINE IS NOT NULL THEN  '1'
			    ELSE ''
			    END                     AS "UOI",

	    CASE
			    WHEN i.IM_TYPE = 'BB_PACK'   THEN :nRM_XX_FEE08 --(Select To_Number(RM_XX_FEE08) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "UnitPrice",
	    CASE
			    WHEN i.IM_TYPE = 'BB_PACK'   THEN :nRM_XX_FEE08 --(Select To_Number(RM_XX_FEE08) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                                          AS "OWUnitPrice",
			    CASE
			    WHEN i.IM_TYPE = 'BB_PACK'  THEN :nRM_XX_FEE08 --(Select To_Number(RM_XX_FEE08) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "DExcl",
			    CASE
			    WHEN i.IM_TYPE = 'BB_PACK'   THEN :nRM_XX_FEE08 --(Select To_Number(RM_XX_FEE08) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                                          AS "Excl_Total",
		  CASE
			    WHEN i.IM_TYPE = 'BB_PACK'  THEN :nRM_XX_FEE08  * 1.1--(Select To_Number(RM_XX_FEE08) from RM where RM_CUST = :cust)   * 1.1
			  ELSE NULL
			  END                      AS "DIncl",
		  CASE
			    WHEN i.IM_TYPE = 'BB_PACK'  THEN :nRM_XX_FEE08 * 1.1--(Select To_Number(RM_XX_FEE08) from RM where RM_CUST = :cust)  * 1.1
			  ELSE NULL
			  END                      AS "Incl_Total",
	    CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN (Select To_Number(i.IM_REPORTING_PRICE) from IM i where i.IM_STOCK = d.SD_STOCK)
			    ELSE NULL
			    END                      AS "ReportingPrice",
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

				  0 AS "CountOfStocks",
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			          ELSE ''
			          END AS Email,
                i.IM_BRAND AS Brand,
           i.IM_OWNED_By AS    OwnedBy,
           i.IM_PROFILE AS    sProfile,
           s.SH_XX_FEE_WAIVE AS    WaiveFee,
           d.SD_COST_PRICE As   Cost,
           s.SH_SPARE_INT_4 AS PaymentType


	  FROM      PWIN171.SD d
			    INNER JOIN PWIN171.SH s  ON s.SH_ORDER  = d.SD_ORDER
			    INNER JOIN PWIN171.ST t  ON t.ST_ORDER  = s.SH_ORDER  --AND t.ST_PICK = d.SD_LAST_PICK_NUM
			    INNER JOIN PWIN171.RM r  ON r.RM_CUST  = s.SH_CUST
			    INNER JOIN PWIN171.IM i  ON i.IM_STOCK = d.SD_STOCK
	  /*WHERE     (Select rmP.RM_XX_FEE08
			    from RM rmP
			    where To_Number(regexp_substr(rmP.RM_XX_FEE08, '^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0 AND rmp.RM_CUST = :cust)  > 0
					  --To_Number(regexp_substr(r2.RM_XX_FEE01,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0   */
	  AND       s.SH_ORDER = d.SD_ORDER
	  AND       i.IM_TYPE = 'BB_PACK'
	  --AND       r.RM_ANAL = :sAnalysis
	  AND     (r.RM_CUST = 'BEYONDBLUE' OR r.RM_PARENT = 'BEYONDBLUE')
    AND :CUST = 'BEYONDBLUE'
    AND    :nRM_XX_FEE08 > 0
	  AND       s.SH_STATUS <> 3
	  AND       d.SD_STOCK NOT IN ('EMERQSRFEE','COURIER%','FEE%','FEE*','COURIER*','COURIER')
	  AND       s.SH_ORDER = t.ST_ORDER
	  AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
	  GROUP BY  s.SH_CUST,
			    s.SH_SPARE_STR_4,
			    s.SH_ORDER,
			    t.ST_PICK,
			    d.SD_XX_PICKLIST_NUM,
			    t.ST_PSLIP,
			    t.ST_DESP_DATE,
			    i.IM_TYPE,
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
			    r.RM_PARENT,
			    s.SH_SPARE_STR_5,
			    s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,i.IM_BRAND,i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4

	  --HAVING    Sum(s.SH_ORDER) <> 1


	  UNION ALL


  /*BB PackingFee*/

  /*Destruction Fee*/
	  SELECT    s.SH_CUST                AS "Customer",
			    r.RM_PARENT              AS "Parent",
			    CASE    WHEN IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
			    WHEN IM_CUST = 'TABCORP' THEN IM_XX_COST_CENTRE01
			    ELSE s.SH_SPARE_STR_4
			    END                      AS "CostCentre",
			    s.SH_ORDER               AS "Order",
			    s.SH_SPARE_STR_5         AS "OrderwareNum",
			    s.SH_CUST_REF            AS "CustomerRef",
			    t.ST_PICK                AS "Pickslip",
			    d.SD_XX_PICKLIST_NUM     AS "PickNum",
			    t.ST_PSLIP               AS "DespatchNote",
			    substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	    CASE    WHEN s.SH_NOTE_1 = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN 'Destruction Fee is '
			    ELSE NULL
			    END                      AS "FeeType",
	    CASE    WHEN d.SD_LINE IS NOT NULL THEN  'DESTRUCT'
			    ELSE NULL
			    END                     AS "Item",
	    CASE    WHEN d.SD_LINE IS NOT NULL THEN  'Destruction Fee'
			    ELSE NULL
			    END                     AS "Description",
	    CASE    WHEN d.SD_LINE IS NOT NULL THEN  1
			    ELSE NULL
			    END                     AS "Qty",
	    CASE    WHEN d.SD_LINE IS NOT NULL THEN  '1'
			    ELSE ''
			    END                     AS "UOI",
	    CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN :nRM_XX_FEE25 -- (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "UnitPrice",
	    CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN :nRM_XX_FEE25 -- (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                                      AS "OWUnitPrice",
			  CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN :nRM_XX_FEE25 -- (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "DExcl",
			  CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN :nRM_XX_FEE25 -- (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                                 AS "Excl_Total",
	    CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN :nRM_XX_FEE25 * 1.1-- (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust) * 1.1
			  ELSE NULL
			  END                      AS "DIncl",
	    CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN :nRM_XX_FEE25 * 1.1 --  (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust)  * 1.1
			  ELSE NULL
			  END                      AS "Incl_Total",
	    CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN (Select To_Number(i.IM_REPORTING_PRICE) from IM i where i.IM_STOCK = d.SD_STOCK)
			    ELSE NULL
			    END                      AS "ReportingPrice",
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

				  0 AS "CountOfStocks",
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			          ELSE ''
			          END AS Email,
                i.IM_BRAND AS Brand,
           i.IM_OWNED_By AS    OwnedBy,
           i.IM_PROFILE AS    sProfile,
           s.SH_XX_FEE_WAIVE AS    WaiveFee,
           d.SD_COST_PRICE As   Cost,
           s.SH_SPARE_INT_4 AS PaymentType


	  FROM      PWIN171.SD d
			    INNER JOIN PWIN171.SH s  ON s.SH_ORDER  = d.SD_ORDER
			    INNER JOIN PWIN171.ST t  ON t.ST_ORDER  = s.SH_ORDER
			    INNER JOIN PWIN171.RM r  ON r.RM_CUST  = s.SH_CUST
			    INNER JOIN PWIN171.IM i  ON i.IM_STOCK = d.SD_STOCK
	  WHERE  :nRM_XX_FEE25 > 0
    AND       (r.RM_ANAL = :sAnalysis)
    AND       (s.SH_NOTE_1 = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE')
	  AND       s.SH_STATUS <> 3
	  AND       d.SD_LINE = 1
	  --AND       r.RM_ANAL = :sAnalysis
	  AND       s.SH_ORDER = t.ST_ORDER
	  AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
	  GROUP BY  s.SH_CUST,
			    s.SH_NOTE_1,
			    s.SH_CAMPAIGN,
			    s.SH_SPARE_STR_4,
			    s.SH_ORDER,
			    t.ST_PICK,
			    d.SD_XX_PICKLIST_NUM,
			    t.ST_PSLIP,
			    t.ST_DESP_DATE,
			    i.IM_TYPE,
			    IM_CUST,
			    IM_XX_COST_CENTRE01,
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
			    r.RM_PARENT,
			    s.SH_SPARE_STR_5,
			    s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,i.IM_BRAND,i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
           s.SH_SPARE_INT_4

	  --HAVING    Sum(s.SH_ORDER) <> 1




	  UNION ALL
  /*Destruction Fee*/

  /*Emergency Fee*/
	  SELECT    s.SH_CUST                AS "Customer",
			    r.RM_PARENT              AS "Parent",
			    CASE    WHEN IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
			    WHEN IM_CUST = 'TABCORP' THEN IM_XX_COST_CENTRE01
			    ELSE s.SH_SPARE_STR_4
			    END                      AS "CostCentre",
			    s.SH_ORDER               AS "Order",
			    s.SH_SPARE_STR_5         AS "OrderwareNum",
			    s.SH_CUST_REF            AS "CustomerRef",
			    NULL                      AS "Pickslip",
			    NULL                    AS "PickNum",
			    NULL                    AS "DespatchNote",
			    substr(To_Char(s.SH_ADD_DATE),0,10)            AS "DespatchDate",
	    CASE    WHEN d.SD_STOCK = 'EMERQSRFEE' AND s.SH_CAMPAIGN = 'TABSPEC' THEN 'Emergency Fee'
			    ELSE NULL
			    END                      AS "FeeType",
	    CASE    WHEN d.SD_LINE IS NOT NULL THEN  'Emergency'
			    ELSE NULL
			    END                     AS "Item",
	    CASE    WHEN d.SD_LINE IS NOT NULL THEN  'Emergency Fee'
			    ELSE NULL
			    END                     AS "Description",
	    CASE    WHEN d.SD_LINE IS NOT NULL THEN  1
			    ELSE NULL
			    END                     AS "Qty",
	    CASE    WHEN d.SD_LINE IS NOT NULL THEN  '1'
			    ELSE ''
			    END                     AS "UOI",
		  CASE  WHEN d.SD_STOCK = 'EMERQSRFEE' AND s.SH_CAMPAIGN = 'TABSPEC' THEN d.SD_SELL_PRICE
			    ELSE NULL
			    END                      AS "UnitPrice",
		  d.SD_XX_OW_UNIT_PRICE                     AS "OWUnitPrice",
	    CASE  WHEN d.SD_STOCK = 'EMERQSRFEE' AND s.SH_CAMPAIGN = 'TABSPEC' THEN d.SD_EXCL
			    ELSE NULL
			    END                      AS "DExcl",
			    CASE   WHEN d.SD_STOCK = 'EMERQSRFEE' AND s.SH_CAMPAIGN = 'TABSPEC' THEN Sum(d.SD_EXCL)
			    ELSE NULL
			    END                      AS "Excl_Total",
		  CASE  WHEN d.SD_STOCK = 'EMERQSRFEE' AND s.SH_CAMPAIGN = 'TABSPEC' THEN d.SD_INCL
			    ELSE NULL
			    END                      AS "DIncl",
		  CASE  WHEN d.SD_STOCK = 'EMERQSRFEE' AND s.SH_CAMPAIGN = 'TABSPEC' THEN Sum(d.SD_INCL)
			    ELSE NULL
			    END                      AS "Incl_Total",
	    CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN (Select To_Number(i.IM_REPORTING_PRICE) from IM i where i.IM_STOCK = d.SD_STOCK)
			    ELSE NULL
			    END                      AS "ReportingPrice",
			    s.SH_ADDRESS             AS "Address",
			    s.SH_SUBURB              AS "Address2",
			    s.SH_CITY                AS "Suburb",
			    s.SH_STATE               AS "State",
			    s.SH_POST_CODE           AS "Postcode",
			    s.SH_NOTE_1              AS "DeliverTo",
			    s.SH_NOTE_2              AS "AttentionTo" ,
			    NULL                     AS "Weight",
			    NULL                     AS "Packages",
			    s.SH_SPARE_DBL_9         AS "OrderSource",
			    NULL                     AS "Pallet/Shelf Space", /*Pallet/Space*/
				  NULL                     AS "Locn", /*Locn*/
				  0                     AS "CountOfStocks",
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			          ELSE ''
			          END AS Email,
                i.IM_BRAND AS Brand,
           i.IM_OWNED_By AS    OwnedBy,
           i.IM_PROFILE AS    sProfile,
           s.SH_XX_FEE_WAIVE AS    WaiveFee,
           d.SD_COST_PRICE As   Cost,
           s.SH_SPARE_INT_4 AS PaymentType


	  FROM      PWIN171.SH s
			    INNER JOIN PWIN171.SD d ON d.SD_ORDER  = s.SH_ORDER
			    INNER JOIN PWIN171.IM i ON i.IM_STOCK = d.SD_STOCK
			    INNER JOIN PWIN171.ST t ON t.ST_ORDER = s.SH_ORDER AND t.ST_PICK = s.SH_LAST_PICK_NUM
			    INNER JOIN PWIN171.RM r ON r.RM_CUST  = s.SH_CUST
	  WHERE     s.SH_ORDER = d.SD_ORDER
	  AND       (d.SD_STOCK = 'EMERQSRFEE' AND s.SH_CAMPAIGN = 'TABSPEC')
	  AND       s.SH_STATUS <> 3
    AND       (r.RM_ANAL = :sAnalysis)
	  AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
	  AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL --(SELECT Count(tt.ST_ORDER) FROM PWIN171.ST tt WHERE LTrim(tt.ST_ORDER) = LTrim(s.SH_ORDER)) = 1
	  GROUP BY  s.SH_CUST,
			    s.SH_NOTE_1,
			    s.SH_CAMPAIGN,
			    s.SH_SPARE_STR_4,
			    s.SH_ORDER,
			    --t.ST_PICK,
			    --d.SD_XX_PICKLIST_NUM,
			    --t.ST_PSLIP,
			    s.SH_ADD_DATE,
			    i.IM_TYPE,
			    IM_CUST,
			    IM_XX_COST_CENTRE01,
			    d.SD_STOCK,
			    d.SD_DESC,
			    d.SD_LINE,
			    d.SD_EXCL,
			    d.SD_INCL,
			    d.SD_ADD_DATE,
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
			    --t.ST_WEIGHT,
			    --t.ST_PACKAGES,
			    s.SH_SPARE_DBL_9,
			    r.RM_PARENT,
			    s.SH_SPARE_STR_5,
			    s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,i.IM_BRAND,i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
           s.SH_SPARE_INT_4

	  --HAVING    Sum(s.SH_ORDER) <> 1



	  UNION ALL
  /*Emergency Fee*/

  /*Pallet Despatch Fee*/
	  SELECT    s.SH_CUST                AS "Customer",
			    r.RM_PARENT              AS "Parent",
			    CASE    WHEN IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
			    WHEN IM_CUST = 'TABCORP' THEN IM_XX_COST_CENTRE01
			    ELSE s.SH_SPARE_STR_4
			    END                      AS "CostCentre",
			    s.SH_ORDER               AS "Order",
			    s.SH_SPARE_STR_5         AS "OrderwareNum",
			    s.SH_CUST_REF            AS "CustomerRef",
			    t.ST_PICK                AS "Pickslip",
			    d.SD_XX_PICKLIST_NUM     AS "PickNum",
			    t.ST_PSLIP               AS "DespatchNote",
			    substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	    CASE    WHEN t.ST_XX_NUM_PALLETS >= 1 THEN 'Pallet Despatch Fee is '
			    ELSE NULL
			    END                      AS "FeeType",
	    CASE     WHEN t.ST_XX_NUM_PALLETS >= 1 THEN  'Pallet Despatch'
			    ELSE NULL
			    END                     AS "Item",
	    CASE     WHEN t.ST_XX_NUM_PALLETS >= 1 THEN  'Pallet Despatch Fee'
			    ELSE NULL
			    END                     AS "Description",
	    CASE    WHEN t.ST_XX_NUM_PALLETS >= 1 THEN  t.ST_XX_NUM_PALLETS
			    ELSE NULL
			    END                     AS "Qty",
	    CASE     WHEN t.ST_XX_NUM_PALLETS >= 1 THEN  '1'
			    ELSE ''
			    END                     AS "UOI",
	    CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN :nRM_XX_FEE17 -- (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "UnitPrice",
	    CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN :nRM_XX_FEE17 -- (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                                           AS "OWUnitPrice",
	    CASE   WHEN t.ST_XX_NUM_PALLETS >= 1  THEN :nRM_XX_FEE17 -- (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                        AS "DExcl",
	  CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN :nRM_XX_FEE17 -- (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                                            AS "Excl_Total",
	    CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN :nRM_XX_FEE17 * 1.1-- (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = :cust)  * 1.1
			  ELSE NULL
			  END                                           AS "DIncl",
	    CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN :nRM_XX_FEE17 * 1.1-- (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = :cust)  * 1.1
			  ELSE NULL
			  END                                           AS "Incl_Total",
			    CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN :nRM_XX_FEE17 -- (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                                           AS "ReportingPrice",
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
			    NULL AS "Pallet/Shelf Space",
				  NULL AS "Locn",
				  0 AS "CountOfStocks",
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			          ELSE ''
			          END AS Email,
                i.IM_BRAND AS Brand,
           i.IM_OWNED_By AS    OwnedBy,
           i.IM_PROFILE AS    sProfile,
           s.SH_XX_FEE_WAIVE AS    WaiveFee,
           d.SD_COST_PRICE As   Cost,
           s.SH_SPARE_INT_4 AS PaymentType
	  FROM      PWIN171.SD d
			    INNER JOIN PWIN171.SH s  ON s.SH_ORDER  = d.SD_ORDER
			    INNER JOIN PWIN171.ST t  ON t.ST_ORDER  = s.SH_ORDER
			    INNER JOIN PWIN171.RM r  ON r.RM_CUST  = s.SH_CUST
			    INNER JOIN PWIN171.IM i  ON i.IM_STOCK = d.SD_STOCK
	  WHERE :nRM_XX_FEE17 > 0
	  AND       s.SH_STATUS <> 3
	  AND      (r.RM_ANAL = :sAnalysis)
	  AND       s.SH_ORDER = t.ST_ORDER
    AND       (ST_XX_NUM_PALLETS >= 1)
	  AND       d.SD_LINE = 1
	  AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
	  GROUP BY  s.SH_CUST,
			    s.SH_NOTE_1,
			    s.SH_CAMPAIGN,
			    s.SH_SPARE_STR_4,
			    s.SH_ORDER,
			    t.ST_PICK,
			    d.SD_XX_PICKLIST_NUM,
			    t.ST_PSLIP,
			    t.ST_DESP_DATE,
			    t.ST_XX_NUM_PALLETS,
			    i.IM_TYPE,
			    IM_XX_COST_CENTRE01,
			    IM_CUST,
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
			    r.RM_PARENT,
			    s.SH_SPARE_STR_5,
			    s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,i.IM_BRAND,i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
           s.SH_SPARE_INT_4



	  UNION ALL
  /*Pallet Despatch Fee*/

  /*Carton Despatch Fee*/
	  SELECT    s.SH_CUST                AS "Customer",
			    r.RM_PARENT              AS "Parent",
			    CASE    WHEN IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
			    WHEN IM_CUST = 'TABCORP' THEN IM_XX_COST_CENTRE01
			    ELSE s.SH_SPARE_STR_4
			    END                      AS "CostCentre",
			    s.SH_ORDER               AS "Order",
			    s.SH_SPARE_STR_5         AS "OrderwareNum",
			    s.SH_CUST_REF            AS "CustomerRef",
			    t.ST_PICK                AS "Pickslip",
			    d.SD_XX_PICKLIST_NUM     AS "PickNum",
			    t.ST_PSLIP               AS "DespatchNote",
			    substr(To_Char(t.ST_DESP_DATE),0,10)           AS "DespatchDate",
	    CASE    WHEN t.ST_XX_NUM_CARTONS >= 1 THEN 'Carton Despatch Fee is '
			    ELSE ''
			    END                      AS "FeeType",
	    CASE    WHEN t.ST_XX_NUM_CARTONS >= 1 THEN  d.SD_STOCK
			    ELSE NULL
			    END                     AS "Item",
	    CASE    WHEN t.ST_XX_NUM_CARTONS >= 1 THEN  d.SD_DESC
			    ELSE NULL
			    END                     AS "Description",
	    CASE    WHEN t.ST_XX_NUM_CARTONS >= 1 THEN  t.ST_XX_NUM_CARTONS
			    ELSE NULL
			    END                     AS "Qty",
	    CASE    WHEN t.ST_XX_NUM_CARTONS >= 1 THEN  '1'
			    ELSE ''
			    END                     AS "UOI",
	    CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN :nRM_XX_FEE15 --  (Select To_Number(RM_XX_FEE15) from RM where RM_CUST = :cust)
			  ELSE null
			  END                      AS "UnitPrice",
	    CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN :nRM_XX_FEE15 --  (Select To_Number(RM_XX_FEE15) from RM where RM_CUST = :cust)
			  ELSE null
			  END                                           AS "OWUnitPrice",
	  CASE   WHEN t.ST_XX_NUM_CARTONS >= 1  THEN :nRM_XX_FEE15 -- (Select To_Number(RM_XX_FEE15) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                        AS "DExcl",
			    CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN :nRM_XX_FEE15 -- (Select To_Number(RM_XX_FEE15) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                                            AS "Excl_Total",
	    CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN :nRM_XX_FEE15 * 1.1-- (Select To_Number(RM_XX_FEE15) from RM where RM_CUST = :cust)  * 1.1
			  ELSE NULL
			  END                                           AS "DIncl",
	    CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN :nRM_XX_FEE15 * 1.1 -- (Select To_Number(RM_XX_FEE15) from RM where RM_CUST = :cust)  * 1.1
			  ELSE NULL
			  END                                           AS "Incl_Total",
			    CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN :nRM_XX_FEE15 --  (Select To_Number(RM_XX_FEE15) from RM where RM_CUST = :cust)
			  ELSE null
			  END                                           AS "ReportingPrice",
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
			    NULL AS "Pallet/Shelf Space",
				  NULL AS "Locn",
				  0 AS "CountOfStocks",
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			          ELSE ''
			          END AS Email,
                i.IM_BRAND AS Brand,
           i.IM_OWNED_By AS    OwnedBy,
           i.IM_PROFILE AS    sProfile,
           s.SH_XX_FEE_WAIVE AS    WaiveFee,
           d.SD_COST_PRICE As   Cost,
           s.SH_SPARE_INT_4 AS PaymentType
	  FROM      PWIN171.SD d
			    INNER JOIN PWIN171.SH s  ON s.SH_ORDER  = d.SD_ORDER
			    INNER JOIN PWIN171.ST t  ON t.ST_ORDER  = s.SH_ORDER
			    INNER JOIN PWIN171.RM r  ON r.RM_CUST  = s.SH_CUST
			    INNER JOIN PWIN171.IM i  ON i.IM_STOCK = d.SD_STOCK
	  WHERE  :nRM_XX_FEE15 > 0
	  AND       s.SH_STATUS <> 3
	  AND       (r.RM_ANAL = :sAnalysis)
	  AND       s.SH_ORDER = t.ST_ORDER
	  AND       (ST_XX_NUM_CARTONS >= 1)
	  AND       d.SD_LINE = 1

	  AND   t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
	  GROUP BY  s.SH_CUST,
			    s.SH_NOTE_1,
			    s.SH_CAMPAIGN,
			    s.SH_SPARE_STR_4,
			    s.SH_ORDER,
			    t.ST_PICK,
			    d.SD_XX_PICKLIST_NUM,
			    t.ST_PSLIP,
			    t.ST_DESP_DATE,
			    t.ST_XX_NUM_CARTONS,
			    i.IM_TYPE,
			    IM_CUST,
			    IM_XX_COST_CENTRE01,
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
			    r.RM_PARENT,
			    s.SH_SPARE_STR_5,
			    s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,
                i.IM_BRAND,i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
           s.SH_SPARE_INT_4


	  UNION ALL
  /*Carton Despatch Fee*/

  /*ShrinkWrap Fee*/
	  SELECT    s.SH_CUST                AS "Customer",
			    r.RM_PARENT              AS "Parent",
			    CASE    WHEN IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
			    WHEN IM_CUST = 'TABCORP' THEN IM_XX_COST_CENTRE01
			    ELSE s.SH_SPARE_STR_4
			    END                      AS "CostCentre",
			    s.SH_ORDER               AS "Order",
			    s.SH_SPARE_STR_5         AS "OrderwareNum",
			    s.SH_CUST_REF            AS "CustomerRef",
			    t.ST_PICK                AS "Pickslip",
			    d.SD_XX_PICKLIST_NUM     AS "PickNum",
			    t.ST_PSLIP               AS "DespatchNote",
			    substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	    CASE    WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN 'ShrinkWrap Fee'
			    ELSE NULL
			    END                      AS "FeeType",
	    CASE    WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  'ShrinkWrap'
			    ELSE NULL
			    END                     AS "Item",
	    CASE    WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  'ShrinkWraping Fee'
			    ELSE NULL
			    END                     AS "Description",
	    CASE    WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  t.ST_XX_NUM_PAL_SW
			    ELSE NULL
			    END                     AS "Qty",
	    CASE    WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  '1'
			    ELSE ''
			    END                     AS "UOI",
	    CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  :nRM_XX_FEE18 --  (Select To_Number(RM_XX_FEE18) from RM where RM_CUST = :cust)
			  ELSE null
			  END                      AS "UnitPrice",
	    CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  :nRM_XX_FEE18 --  (Select To_Number(RM_XX_FEE18) from RM where RM_CUST = :cust)
			  ELSE null
			  END                                           AS "OWUnitPrice",
	    CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1  THEN :nRM_XX_FEE18 -- (Select To_Number(RM_XX_FEE18) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                        AS "DExcl",
			  CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  :nRM_XX_FEE18 -- (Select To_Number(RM_XX_FEE18) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                                            AS "Excl_Total",
	    CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  :nRM_XX_FEE18 * 1.1-- (Select To_Number(RM_XX_FEE18) from RM where RM_CUST = :cust)  * 1.1
			  ELSE NULL
			  END                                           AS "DIncl",
	    CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN :nRM_XX_FEE18 * 1.1-- (Select To_Number(RM_XX_FEE18) from RM where RM_CUST = :cust)  * 1.1
			  ELSE NULL
			  END                                           AS "Incl_Total",
			    CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  :nRM_XX_FEE18 --  (Select To_Number(RM_XX_FEE18) from RM where RM_CUST = :cust)
			  ELSE null
			  END                                           AS "ReportingPrice",
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
			    NULL AS "Pallet/Shelf Space",
				  NULL AS "Locn",
				  0 AS "CountOfStocks",
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			          ELSE ''
			          END AS Email,
                IM_BRAND AS Brand,
           i.IM_OWNED_By AS    OwnedBy,
           i.IM_PROFILE AS    sProfile,
           s.SH_XX_FEE_WAIVE AS    WaiveFee,
           d.SD_COST_PRICE As   Cost,
           s.SH_SPARE_INT_4 AS PaymentType
	  FROM      PWIN171.SD d
			    INNER JOIN PWIN171.SH s  ON s.SH_ORDER  = d.SD_ORDER
			    INNER JOIN PWIN171.ST t  ON t.ST_ORDER  = s.SH_ORDER
			    INNER JOIN PWIN171.RM r  ON r.RM_CUST  = s.SH_CUST
			    INNER JOIN PWIN171.IM i  ON i.IM_STOCK = d.SD_STOCK
	  WHERE  :nRM_XX_FEE18 > 0
	  AND       s.SH_STATUS <> 3
	  AND       (r.RM_ANAL = :sAnalysis)
	  AND       s.SH_ORDER = t.ST_ORDER
	  AND       (ST_XX_NUM_PAL_SW >= 1)
	  AND       d.SD_LINE = 1
	  AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
	  GROUP BY  s.SH_CUST,
			    s.SH_NOTE_1,
			    s.SH_CAMPAIGN,
			    s.SH_SPARE_STR_4,
			    s.SH_ORDER,
			    t.ST_PICK,
			    d.SD_XX_PICKLIST_NUM,
			    t.ST_PSLIP,
			    t.ST_DESP_DATE,
			    t.ST_XX_NUM_PAL_SW,
			    i.IM_TYPE,
			    IM_CUST,
			    IM_XX_COST_CENTRE01,
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
			    r.RM_PARENT,
			    s.SH_SPARE_STR_5,
			    s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,
                IM_BRAND,i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
           s.SH_SPARE_INT_4

	  --HAVING    Sum(s.SH_ORDER) <> 1




	  UNION ALL

  /*ShrinkWrap Fee*/

  /*Pallet In Fee*/
	  SELECT    IM_CUST                AS "Customer",
			    RM_PARENT              AS "Parent",
			    IM_XX_COST_CENTRE01       AS "CostCentre",
			    NI_QJ_NUMBER               AS "Order",
			    NULL         AS "OrderwareNum",
			    NULL            AS "CustomerRef",
			    NULL                     AS "Pickslip",
			    NULL                     AS "PickNum",
			    NULL                     AS "DespatchNote",
			    substr(To_Char(NE_ADD_DATE),0,10)                     AS "DespatchDate",
	    CASE    WHEN NE_ENTRY IS NOT NULL THEN 'Pallet In Fee '
			    ELSE ''
			    END                      AS "FeeType",
			    IM_STOCK               AS "Item",
			    IM_DESC                AS "Description",
	        NE_QUANTITY          AS "Qty",
	        IM_LEVEL_UNIT          AS "UOI",

	    CASE    WHEN NE_ENTRY IS NOT NULL THEN :nRM_XX_FEE14 -- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
			    ELSE NULL
			    END                      AS "UnitPrice",
	    CASE    WHEN NE_ENTRY IS NOT NULL THEN  :nRM_XX_FEE14 -- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
			    ELSE NULL
			    END                      AS "OWUnitPrice",
	    CASE    WHEN NE_ENTRY IS NOT NULL THEN  :nRM_XX_FEE14 -- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
			    ELSE NULL
			    END                      AS "DExcl",
	    CASE    WHEN NE_ENTRY IS NOT NULL THEN :nRM_XX_FEE14 --  (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
			    ELSE NULL
			    END                      AS "Excl_Total",
		  CASE    WHEN NE_ENTRY IS NOT NULL THEN :nRM_XX_FEE14 * 1.1 --  (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust) * 1.1
			    ELSE NULL
			    END                      AS "DIncl",
	    CASE    WHEN NE_ENTRY IS NOT NULL THEN :nRM_XX_FEE14 * 1.1-- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust) * 1.1
			    ELSE NULL
			    END                      AS "Incl_Total",
			    CASE    WHEN NE_ENTRY IS NOT NULL THEN :nRM_XX_FEE14 -- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
			    ELSE NULL
			    END                                           AS "ReportingPrice",
			    NULL                     AS "Address",
			    NULL                     AS "Address2",
			    NULL                     AS "Suburb",
			    NULL                     AS "State",
			    NULL                     AS "Postcode",
			    NULL                     AS "DeliverTo",
			    NULL                     AS "AttentionTo" ,
			    NULL                     AS "Weight",
			    NULL                     AS "Packages",
			    NULL                     AS "OrderSource",
			    IL_NOTE_2 AS "Pallet/Shelf Space",
				  IL_LOCN AS "Locn",
				  0 AS "CountOfStocks",
          NULL AS Email,
                IM_BRAND AS Brand,
           IM_OWNED_By AS    OwnedBy,
           IM_PROFILE AS    sProfile,
           NULL AS    WaiveFee,
           NULL As   Cost,
           NULL AS PaymentType

	  FROM      PWIN171.IM
			    INNER JOIN PWIN171.NA  ON NA_STOCK = IM_STOCK
			    INNER JOIN PWIN171.IL  ON IL_UID = NA_EXT_KEY
			    INNER JOIN PWIN171.NE  ON NE_ACCOUNT  = NA_ACCOUNT
			    INNER JOIN PWIN171.NI  ON NI_ENTRY = NE_ENTRY
			    INNER JOIN PWIN171.RM  ON RM_CUST  = IM_CUST
	  WHERE  :nRM_XX_FEE14 > 0
	  AND     IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_ANAL = :sAnalysis AND RM_TYPE = 0 AND RM_ACTIVE = 1 )
	  AND       NA_EXT_TYPE = 1210067
	  AND       NE_TRAN_TYPE = 1
	  AND       IM_MAIN_SUPP <> 'BSPGA'
	  AND       (NE_STATUS = 1 OR NE_STATUS = 3)
	  AND       NE_DATE >= :start_date AND NE_DATE <= :end_date
	  AND       Upper(IL_NOTE_2) = 'Yes' AND IL_PHYSICAL = 1
	  GROUP BY  IM_CUST,
			    IM_XX_COST_CENTRE01,
			    NI_QJ_NUMBER,
			    NE_ENTRY,
			    IM_STOCK,
			    IM_DESC,
			    NE_DATE,
			    RM_PARENT,
			    IL_LOCN,
          NE_AVAIL_ACTUAL,
          IL_NOTE_2,
          NE_QUANTITY,
          IM_LEVEL_UNIT,
          NE_ADD_DATE,
                IM_BRAND,IM_OWNED_By,IM_PROFILE



	  UNION ALL
  /*Pallet In Fee*/

  /*Carton In Fee*/
	  SELECT    IM_CUST                AS "Customer",
			    RM_PARENT              AS "Parent",
			    IM_XX_COST_CENTRE01       AS "CostCentre",
			    NI_QJ_NUMBER               AS "Order",
			    NULL         AS "OrderwareNum",
			    NULL            AS "CustomerRef",
			    NULL                     AS "Pickslip",
			    NULL                     AS "PickNum",
			    NULL                     AS "DespatchNote",
			    substr(To_Char(NE_ADD_DATE),0,10)                     AS "DespatchDate",
	    CASE    WHEN NE_ENTRY IS NOT NULL THEN 'Carton In Fee '
			    ELSE ''
			    END                      AS "FeeType",
			    IM_STOCK               AS "Item",
			    IM_DESC                AS "Description",
	        NE_QUANTITY          AS "Qty",
	        IM_LEVEL_UNIT          AS "UOI",
	    CASE    WHEN NE_ENTRY IS NOT NULL THEN :nRM_XX_FEE13 -- (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = :cust)
			    ELSE NULL
			    END                      AS "UnitPrice",
	    CASE    WHEN NE_ENTRY IS NOT NULL THEN :nRM_XX_FEE13 --  (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = :cust)
			    ELSE NULL
			    END                      AS "OWUnitPrice",
	    CASE    WHEN NE_ENTRY IS NOT NULL THEN  :nRM_XX_FEE13 -- (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = :cust)
			    ELSE NULL
			    END                      AS "DExcl",
	    CASE    WHEN NE_ENTRY IS NOT NULL THEN :nRM_XX_FEE13 --  (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = :cust)
			    ELSE NULL
			    END                      AS "Excl_Total",
		  CASE    WHEN NE_ENTRY IS NOT NULL THEN :nRM_XX_FEE13 * 1.1 --  (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = :cust) * 1.1
			    ELSE NULL
			    END                      AS "DIncl",
	    CASE    WHEN NE_ENTRY IS NOT NULL THEN :nRM_XX_FEE13 * 1.1 -- (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = :cust) * 1.1
			    ELSE NULL
			    END                      AS "Incl_Total",
			    CASE    WHEN NE_ENTRY IS NOT NULL THEN :nRM_XX_FEE13 -- (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = :cust)
			    ELSE NULL
			    END                                           AS "ReportingPrice",
			    NULL                     AS "Address",
			    NULL                     AS "Address2",
			    NULL                     AS "Suburb",
			    NULL                     AS "State",
			    NULL                     AS "Postcode",
			    NULL                     AS "DeliverTo",
			    NULL                     AS "AttentionTo" ,
			    NULL                     AS "Weight",
			    NULL                     AS "Packages",
			    NULL                     AS "OrderSource",
			    IL_NOTE_2 AS "Pallet/Shelf Space",
				  IL_LOCN AS "Locn",
				  0 AS "CountOfStocks",
          NULL AS Email,
                IM_BRAND AS Brand,
           IM_OWNED_By AS    OwnedBy,
           IM_PROFILE AS    sProfile,
           NULL AS    WaiveFee,
           NULL As   Cost,
           NULL AS PaymentType


	  FROM      PWIN171.IM
			    INNER JOIN PWIN171.NA  ON NA_STOCK = IM_STOCK
			    INNER JOIN PWIN171.IL  ON IL_UID = NA_EXT_KEY
			    INNER JOIN PWIN171.NE  ON NE_ACCOUNT  = NA_ACCOUNT
			    INNER JOIN PWIN171.NI  ON NI_ENTRY = NE_ENTRY
			    INNER JOIN PWIN171.RM  ON RM_CUST  = IM_CUST
	  WHERE :nRM_XX_FEE13 > 0
	  AND     IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_ANAL = :sAnalysis AND RM_TYPE = 0 AND RM_ACTIVE = 1 )
	  AND       NA_EXT_TYPE = 1210067
	  AND       NE_TRAN_TYPE = 1
	  AND       IM_MAIN_SUPP <> 'BSPGA'
	  AND       (NE_STATUS = 1 OR NE_STATUS = 3)
	  AND       NE_DATE >= :start_date AND NE_DATE <= :end_date
	  AND       Upper(IL_NOTE_2) = 'No' AND IL_PHYSICAL = 1
	  GROUP BY  IM_CUST,
			    IM_XX_COST_CENTRE01,
			    NI_QJ_NUMBER,
			    NE_ENTRY,
			    IM_STOCK,
			    IM_DESC,
			    NE_DATE,
			    RM_PARENT,
			    IL_LOCN,
          NE_AVAIL_ACTUAL,
          IL_NOTE_2,
          NE_QUANTITY,
          IM_LEVEL_UNIT,
          NE_ADD_DATE,
                IM_BRAND,IM_OWNED_By,IM_PROFILE



	  UNION ALL
  /*Carton In Fee*/

  /* Pick Fees  */
	  SELECT  s.SH_CUST                AS "Customer",
			  r.RM_PARENT              AS "Parent",
			  s.SH_SPARE_STR_4         AS "CostCentre",
			  s.SH_ORDER               AS "Order",
			  s.SH_SPARE_STR_5         AS "OrderwareNum",
			  s.SH_CUST_REF            AS "CustomerRef",
			  t.vSLPickslipNum         AS "Pickslip",
			  NULL                     AS "PickNum",
			  t.vSLPslip               AS "DespatchNote",
			  t.vDateDespSL             AS "DespatchDate",
			  CASE    WHEN t.vSLPslip IS NOT NULL THEN 'Pick Fee'
			    ELSE NULL
			    END                      AS "FeeType",
			  CASE    WHEN t.vSLPslip IS NOT NULL THEN 'FEEPICK'
			    ELSE NULL
			    END                      AS "Item",
			  CASE    WHEN t.vSLPslip IS NOT NULL THEN 'Line Picking Fee'
			    ELSE NULL
			    END                      AS "Description",
			  t.nCountOfLines           AS "Qty",
			  CASE    WHEN t.vSLPslip IS NOT NULL THEN  '1'
			    ELSE ''
			    END                     AS "UOI",
			  CASE    WHEN :nRM_XX_FEE36 IS NOT NULL AND t.vSLPslip IS NOT NULL  AND t.nCountOfLines < = 5  THEN :nRM_XX_FEE16
                WHEN :nRM_XX_FEE36 IS NOT NULL AND t.vSLPslip IS NOT NULL  AND t.nCountOfLines > 5  THEN :nRM_XX_FEE36
			          ELSE :nRM_XX_FEE16
			          END                      AS "UnitPrice",
		    CASE  WHEN :nRM_XX_FEE36 IS NOT NULL AND t.vSLPslip IS NOT NULL  AND t.nCountOfLines < = 5  THEN :nRM_XX_FEE16
                WHEN :nRM_XX_FEE36 IS NOT NULL AND t.vSLPslip IS NOT NULL  AND t.nCountOfLines > 5  THEN :nRM_XX_FEE36
			          ELSE :nRM_XX_FEE16
			          END                                      AS "OWUnitPrice",
				  CASE  WHEN :nRM_XX_FEE36 IS NOT NULL AND t.vSLPslip IS NOT NULL  AND t.nCountOfLines < = 5  THEN :nRM_XX_FEE16  * t.nCountOfLines
				        WHEN :nRM_XX_FEE36 IS NOT NULL AND t.vSLPslip IS NOT NULL  AND t.nCountOfLines > 5  THEN :nRM_XX_FEE36 * t.nCountOfLines
                ELSE :nRM_XX_FEE16 * t.nCountOfLines
				        END                      AS "DExcl",
				  CASE  WHEN :nRM_XX_FEE36 IS NOT NULL AND t.vSLPslip IS NOT NULL  AND t.nCountOfLines < = 5  THEN :nRM_XX_FEE16  * t.nCountOfLines
				        WHEN :nRM_XX_FEE36 IS NOT NULL AND t.vSLPslip IS NOT NULL  AND t.nCountOfLines > 5  THEN :nRM_XX_FEE36 * t.nCountOfLines
			          ELSE :nRM_XX_FEE16 * t.nCountOfLines
			          END                                 AS "Excl_Total",
		    CASE    WHEN :nRM_XX_FEE36 IS NOT NULL AND t.vSLPslip IS NOT NULL  AND t.nCountOfLines < = 5  THEN (:nRM_XX_FEE16  * t.nCountOfLines) * 1.1
				        WHEN :nRM_XX_FEE36 IS NOT NULL AND t.vSLPslip IS NOT NULL  AND t.nCountOfLines > 5  THEN (:nRM_XX_FEE36 * t.nCountOfLines) * 1.1
				        ELSE (:nRM_XX_FEE16 * t.nCountOfLines) * 1.1

				        END                      AS "DIncl",
		    CASE    WHEN :nRM_XX_FEE36 IS NOT NULL AND t.vSLPslip IS NOT NULL  AND t.nCountOfLines < = 5  THEN (:nRM_XX_FEE16  * t.nCountOfLines) * 1.1
				        WHEN :nRM_XX_FEE36 IS NOT NULL AND t.vSLPslip IS NOT NULL  AND t.nCountOfLines > 5  THEN (:nRM_XX_FEE36 * t.nCountOfLines) * 1.1
				        ELSE (:nRM_XX_FEE16 * t.nCountOfLines) * 1.1

				        END                      AS "Incl_Total",
		    CASE    WHEN t.vSLPslip IS NOT NULL THEN  (Select To_Number(i.IM_REPORTING_PRICE) from IM i where i.IM_STOCK = 'COURIERM')
				        ELSE NULL
				        END                      AS "ReportingPrice",
			  s.SH_ADDRESS             AS "Address",
			  s.SH_SUBURB              AS "Address2",
			  s.SH_CITY                AS "Suburb",
			  s.SH_STATE               AS "State",
			  s.SH_POST_CODE           AS "Postcode",
			  s.SH_NOTE_1              AS "DeliverTo",
			  s.SH_NOTE_2              AS "AttentionTo" ,
			  t.vWeightSL              AS "Weight",
			  t.vPackagesSL            AS "Packages",
			  s.SH_SPARE_DBL_9         AS "OrderSource",
			  NULL                     AS "Pallet/Shelf Space",
			    NULL                     AS "Locn",
			    0                     AS "CountOfStocks",
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			          ELSE ''
			          END AS Email,
                'N/A' AS Brand,
           NULL AS    OwnedBy,
           NULL AS    sProfile,
           NULL AS    WaiveFee,
           NULL As   Cost,
           s.SH_SPARE_INT_4 AS PaymentType

	  FROM  Dev_Admin_Data_Pick_LineCounts t LEFT JOIN PWIN171.SH s ON  LTrim(s.SH_ORDER) = t.vSLOrderNum
	  INNER JOIN RM r ON r.RM_CUST = s.SH_CUST
	  WHERE  :nRM_XX_FEE16 > 0
	  AND  s.SH_STATUS <> 3
    AND (r.RM_ANAL = :sAnalysis)
    AND t.vSLPslip <> 'CANCELLED'
	  GROUP BY  s.SH_ORDER,
			    s.SH_SPARE_STR_4,
			    s.SH_CUST,
			    t.vSLPickslipNum,
			    t.vSLPslip,
			    t.vDateDespSL,
			    s.SH_EXCL,
			    s.SH_INCL,
			    s.SH_ADDRESS,
			    s.SH_SUBURB,
			    s.SH_CITY,
			    s.SH_STATE,
			    s.SH_POST_CODE,
			    s.SH_NOTE_1,
			    s.SH_NOTE_2 ,
			    s.SH_NUM_LINES,
			    t.vWeightSL,
			    t.vPackagesSL,
			    s.SH_SPARE_DBL_9,
			    t.nCountOfLines,
			    r.RM_PARENT,
			    s.SH_SPARE_STR_5,
			    s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,
           s.SH_SPARE_INT_4






	  UNION ALL
  /* Pick Fees  */

  /*Handeling Fee*/
	  SELECT    s.SH_CUST                AS "Customer",
			    r.RM_PARENT              AS "Parent",
			    s.SH_SPARE_STR_4          AS "CostCentre",
			    s.SH_ORDER               AS "Order",
			    s.SH_SPARE_STR_5         AS "OrderwareNum",
			    s.SH_CUST_REF            AS "CustomerRef",
			    t.vSLPickslipNum         AS "Pickslip",
			  NULL                     AS "PickNum",
			  t.vSLPslip               AS "DespatchNote",
			  t.vDateDespSL             AS "DespatchDate",
	    CASE    WHEN t.vSLPslip IS NOT NULL THEN 'Handeling Fee is '
			    ELSE NULL
			    END                      AS "FeeType",
	    CASE    WHEN t.vSLPslip IS NOT NULL THEN  'Handeling'
			    ELSE NULL
			    END                     AS "Item",
	    CASE    WHEN t.vSLPslip IS NOT NULL THEN  'Handeling Fee'
			    ELSE NULL
			    END                     AS "Description",
	    CASE    WHEN t.vSLPslip IS NOT NULL THEN  1
			    ELSE NULL
			    END                     AS "Qty",
	    CASE    WHEN t.vSLPslip IS NOT NULL THEN  '1'
			    ELSE ''
			    END                     AS "UOI",
	    CASE    WHEN t.vSLPslip IS NOT NULL THEN :nRM_XX_FEE06 -- (Select To_Number(RM_XX_FEE06) from RM where RM_CUST = :cust)
			    ELSE NULL
			    END                      AS "UnitPrice",
	    CASE    WHEN t.vSLPslip IS NOT NULL THEN :nRM_XX_FEE06 -- (Select To_Number(RM_XX_FEE06) from RM where RM_CUST = :cust)
			    ELSE NULL
			    END                                      AS "OWUnitPrice",
			  CASE    WHEN t.vSLPslip IS NOT NULL THEN  :nRM_XX_FEE06 -- (Select To_Number(RM_XX_FEE06) from RM where RM_CUST = :cust)
			    ELSE NULL
			    END                      AS "DExcl",
			  CASE    WHEN t.vSLPslip IS NOT NULL THEN :nRM_XX_FEE06 -- (Select To_Number(RM_XX_FEE06) from RM where RM_CUST = :cust)
			    ELSE NULL
			    END                                 AS "Excl_Total",
	    CASE    WHEN t.vSLPslip IS NOT NULL THEN :nRM_XX_FEE06 -- (Select To_Number(RM_XX_FEE06) from RM where RM_CUST = :cust) * 1.1
			    ELSE NULL
			    END                      AS "DIncl",
	    CASE    WHEN t.vSLPslip IS NOT NULL THEN :nRM_XX_FEE06 * 1.1 --  (Select To_Number(RM_XX_FEE06) from RM where RM_CUST = :cust)  * 1.1
			    ELSE NULL
			    END                      AS "Incl_Total",
	    CASE    WHEN t.vSLPslip IS NOT NULL THEN :nRM_XX_FEE06 * 1.1-- (Select To_Number(i.IM_REPORTING_PRICE) from IM i where i.IM_STOCK = 'COURIERM')
			    ELSE NULL
			    END                      AS "ReportingPrice",
			  s.SH_ADDRESS             AS "Address",
			    s.SH_SUBURB              AS "Address2",
			    s.SH_CITY                AS "Suburb",
			    s.SH_STATE               AS "State",
			    s.SH_POST_CODE           AS "Postcode",
			    s.SH_NOTE_1              AS "DeliverTo",
			    s.SH_NOTE_2              AS "AttentionTo" ,
			  t.vWeightSL              AS "Weight",
			  t.vPackagesSL            AS "Packages",
			  s.SH_SPARE_DBL_9         AS "OrderSource",
			  NULL AS "Pallet/Shelf Space", /*Pallet/Space*/
				  NULL AS "Locn", /*Locn*/

				  0 AS "CountOfStocks",
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			          ELSE ''
			          END AS Email,
                'N/A' AS Brand,
           NULL AS    OwnedBy,
           NULL AS    sProfile,
           NULL AS    WaiveFee,
           NULL As   Cost,
           s.SH_SPARE_INT_4 AS PaymentType



	  FROM  Dev_Admin_Data_Pick_LineCounts t LEFT JOIN PWIN171.SH s ON  LTrim(s.SH_ORDER) = LTrim(t.vSLOrderNum)
	  INNER JOIN RM r ON r.RM_CUST = s.SH_CUST
		  WHERE  :nRM_XX_FEE06 > 0
	  AND  s.SH_STATUS <> 3
    AND (r.RM_ANAL = :sAnalysis)
    AND t.vSLPslip <> 'CANCELLED'
	  GROUP BY  s.SH_ORDER,
			    s.SH_SPARE_STR_4,
			    s.SH_CUST,
			    t.vSLPickslipNum,
			    t.vSLPslip,
			    t.vDateDespSL,
			    s.SH_ADDRESS,
			    s.SH_SUBURB,
			    s.SH_CITY,
			    s.SH_STATE,
			    s.SH_POST_CODE,
			    s.SH_NOTE_1,
			    s.SH_NOTE_2,
			    t.vWeightSL,
			    t.vPackagesSL,
			    s.SH_SPARE_DBL_9,
			    t.nCountOfLines,
			    r.RM_PARENT,
			    s.SH_SPARE_STR_5,
			    s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,
           s.SH_SPARE_INT_4







	  UNION ALL
  /*Handeling Fee*/

  /*Stocks*/


	  SELECT    s.SH_CUST                AS "Customer",
			    r.RM_PARENT              AS "Parent",
	    CASE    WHEN i.IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
			    WHEN i.IM_CUST = 'TABCORP' THEN i.IM_XX_COST_CENTRE01
			    ELSE i.IM_XX_COST_CENTRE01
			    END                      AS "CostCentre",
			    s.SH_ORDER               AS "Order",
			    s.SH_SPARE_STR_5         AS "OrderwareNum",
			    s.SH_CUST_REF            AS "CustomerRef",
			    t.ST_PICK                AS "Pickslip",
			    d.SD_XX_PICKLIST_NUM     AS "PickNum",
			    t.ST_PSLIP               AS "DespatchNote",
			    --NULL AS "DespatchDate",
			    substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	    CASE    WHEN d.SD_STOCK IS NOT NULL THEN 'Stock'
			    ELSE NULL
			    END                      AS "FeeType",
			    d.SD_STOCK               AS "Item",
			    d.SD_DESC                AS "Description",
			    l.SL_PSLIP_QTY           AS "DespQty",
			    d.SD_QTY_UNIT            AS "UOI",
			    /* We need to get a 3 tiered looup for the stockunit prices, fist get th eprice from thE BATCH if company owned otherwise get the unit price from the sd sell price otherwise get it from the ow xx */
	    CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN d.SD_SELL_PRICE --company owned
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1 AND n.NI_NX_QUANTITY > 0 THEN n.NI_SELL_VALUE/n.NI_NX_QUANTITY
              WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NOT NULL THEN  (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			        ELSE NULL
			        END                        AS "Batch/UnitPrice",

		  /*CASE    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1 THEN d.SD_SELL_PRICE --customer owned
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN (SELECT NX_SELL_VALUE FROM  NX INNER JOIN NE ON NE_PRICE_ENTRY = NX_ENTRY INNER JOIN NI ON NI_ENTRY = NE_ENTRY AND NX_MOVEMENT = NI_NX_MOVEMENT
																								                                                  WHERE NE_NV_EXT_TYPE = 1810105  AND NE_STRENGTH = 3 AND NE_NV_EXT_KEY = (SELECT SL_UID FROM SL WHERE LTrim(RTrim(SL_PICK)) = LTrim(RTrim(t.ST_PICK)) AND SL_ORDER_LINE  = d.SD_LINE)
																								                                                  AND NE_DATE = t.ST_DESP_DATE
																								                                                  AND NE_STOCK = d.SD_STOCK)
			        --WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NOT NULL THEN  (SELECT To_Number(vUnitPrice) * d.SD_QTY_DESP FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE  * d.SD_QTY_DESP
			        ELSE NULL
			        END                        AS "DExcl",*/
	    CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN To_Number(i.IM_REPORTING_PRICE)
			    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN  (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
			    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			    ELSE NULL
			    END                        AS "OWUnitPrice",
        CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN d.SD_SELL_PRICE * d.SD_QTY_DESP--customer owned
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1 AND n.NI_NX_QUANTITY > 0 THEN (n.NI_SELL_VALUE/n.NI_NX_QUANTITY) * d.SD_QTY_DESP
              WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NOT NULL THEN  (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) * d.SD_QTY_DESP
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE * d.SD_QTY_DESP
			        ELSE NULL
			        END          AS "DExcl",

	    CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN To_Number(i.IM_REPORTING_PRICE)
			    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN  (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
			    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			    ELSE NULL
			    END                       AS "Excl_Total",
	    CASE     WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN (d.SD_SELL_PRICE * d.SD_QTY_DESP) * 1.1--customer owned
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1  AND n.NI_NX_QUANTITY > 0 THEN  ((n.NI_SELL_VALUE/n.NI_NX_QUANTITY) * d.SD_QTY_DESP) * 1.1
              WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NOT NULL THEN  ((SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) * d.SD_QTY_DESP) * 1.1
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  (d.SD_XX_OW_UNIT_PRICE * d.SD_QTY_DESP) * 1.1
			        ELSE NULL
			        END          AS "DIncl",
	    CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN (d.SD_SELL_PRICE * d.SD_QTY_DESP) * 1.1--customer owned
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1 AND n.NI_NX_QUANTITY > 0 THEN  ((n.NI_SELL_VALUE/n.NI_NX_QUANTITY) * d.SD_QTY_DESP) * 1.1
              WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NOT NULL THEN  ((SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) * d.SD_QTY_DESP) * 1.1
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  (d.SD_XX_OW_UNIT_PRICE * d.SD_QTY_DESP) * 1.1
			        ELSE NULL
			        END          AS "Incl_Total",
	    CASE    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN To_Number(i.IM_REPORTING_PRICE)
			    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN  (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
			    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			    ELSE NULL
			    END                      AS "ReportingPrice",
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

				  0 AS "CountOfStocks",
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			          ELSE ''
			          END AS Email,
                i.IM_BRAND AS Brand,
           i.IM_OWNED_By AS    OwnedBy,
           i.IM_PROFILE AS    sProfile,
           SH_XX_FEE_WAIVE AS    WaiveFee,
           d.SD_COST_PRICE As   Cost,
          NULL AS PaymentType

	  FROM      PWIN171.SD d
			    INNER JOIN PWIN171.SH s  ON s.SH_ORDER  = d.SD_ORDER
			    INNER JOIN PWIN171.ST t  ON t.ST_ORDER  = s.SH_ORDER
          INNER JOIN PWIN171.SL l  ON l.SL_PICK   = t.ST_PICK
			    INNER JOIN PWIN171.RM r  ON r.RM_CUST  = s.SH_CUST
			    INNER JOIN PWIN171.IM i  ON i.IM_STOCK = d.SD_STOCK
          INNER JOIN PWIN171.NI n  ON n.NI_NV_EXT_KEY = l.SL_UID
    WHERE NI_NV_EXT_TYPE = 1810105 AND NI_STRENGTH = 3 AND NI_DATE = t.ST_DESP_DATE AND NI_STOCK = d.SD_STOCK AND NI_STATUS <> 0
	  AND     s.SH_STATUS <> 3
    AND       s.SH_ORDER = t.ST_ORDER
	  AND       d.SD_STOCK NOT LIKE 'COURIER'
	  AND       d.SD_STOCK NOT LIKE 'FEE*'
	  AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
	 -- AND       d.SD_LAST_PICK_NUM = t.ST_PICK
    AND     i.IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_ANAL = :sAnalysis AND RM_TYPE = 0 AND RM_ACTIVE = 1 )
    --AND     EXISTS (SELECT RM_CUST FROM RM WHERE RM_ANAL = :sAnalysis AND RM_TYPE = 0 AND RM_ACTIVE = 1 )
--(SELECT RM_CUST FROM RM WHERE RM_ANAL = :sAnalysis)
   -- AND s.SH_ORDER = '   1739062'
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
                i.IM_BRAND,l.SL_PSLIP_QTY,i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE

	  --HAVING    Sum(s.SH_ORDER) <> 1



	  UNION ALL
  /*Stocks*/

  /* EOM Storage Fees */
	 -- SELECT Count(DISTINCT Item) FROM  tbl_AdminData  WHERE FeeType LIKE 'PALL%'
    /*	  INSERT into tbl_AdminData( --Select * From Tmp_Cust_Reporting )
				  Customer,
				  Parent,
				  CostCentre,
				  OrderNum,
				  OrderwareNum,
				  CustRef,
				  Pickslip,
				  PickNum,
				  DespatchNote,
				  DespatchDate,
				  FeeType,
				  Item,
				  Description,
				  Qty,
				  UOI,
				  UnitPrice,
				  OW_Unit_Sell_Price,
				  Sell_Excl,
				  Sell_Excl_Total,
				  Sell_Incl,
				  Sell_Incl_Total,
				  ReportingPrice,
				  Address,
				  Address2,
				  Suburb,
				  State,
				  Postcode,
				  DeliverTo,
				  AttentionTo,
				  Weight,
				  Packages,
				  OrderSource,
				  ILNOTE2,
				  NILOCN,
				  NIAVAILACTUAL,
				  CountOfStocks,
          Email,
          Brand,
          OwnedBy,
          sProfile,
          WaiveFee,
          Cost,
          PaymentType


				  )

    (*/
   select
		  IM_CUST AS "Customer", IM_CUST AS "Parent",
	    IM_XX_COST_CENTRE01     AS "CostCentre",NULL  AS "Order",NULL   AS "OrderwareNum",
	    NULL  AS "CustomerRef",NULL  AS "Pickslip",
	    NULL  AS "PickNum",NULL  AS "DespatchNote",
	    (select SubStr(To_Char(last_day(SYSDATE)),0,10) from dual) AS "DespatchDate", /*Made Date*/
		  CASE /*Fee Type*/
			  WHEN (l1.IL_NOTE_2 like 'Yes'
				  OR l1.IL_NOTE_2 LIKE 'YES'
				  OR l1.IL_NOTE_2 LIKE 'yes')
			  THEN 'FEEPALLETS'
			  ELSE 'FEESHELFS'
			  END AS "FeeType",
      n1.NA_STOCK AS "Item",
		  CASE /*explanation of charge*/
			  WHEN (l1.IL_NOTE_2 like 'Yes'	OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			  THEN 'Pallet Space Utilisation Fee (per month) is split across ' || nCountOfStocks || ' stock(s)'
			  ELSE 'Shelf SPace Utilisation Fee (per month) is split across ' ||	nCountOfStocks  || ' stock(s)'
			  END AS "Description",
	    CASE   WHEN l1.IL_NOTE_2 IS NOT NULL THEN  1
			    ELSE NULL
			    END                     AS "Qty", IM_LEVEL_UNIT AS "UOI", /*UOI*/
	    CASE  /*unit price*/
			  WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			  THEN
				  (:nRM_XX_FEE11 	/ nCountOfStocks )
			  ELSE
				  (:nRM_XX_FEE12  / nCountOfStocks )
	      END AS "UnitPrice",
		    CASE  /*unit price*/
			  WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			  THEN
				  (:nRM_XX_FEE11 	/ nCountOfStocks )
			  ELSE
				  (:nRM_XX_FEE12  / nCountOfStocks )
	      END AS "OWUnitPrice",
			  CASE WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			  THEN
				  (:nRM_XX_FEE11 	/ nCountOfStocks )
			  ELSE
				  (:nRM_XX_FEE12  / nCountOfStocks )
	      END AS "DExcl",
			  CASE  /*unit price*/
			  WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			  THEN
				  (:nRM_XX_FEE11 	/ nCountOfStocks )
			  ELSE
				  (:nRM_XX_FEE12  / nCountOfStocks )
	      END AS "Excl_Total",
		  CASE WHEN (l1.IL_NOTE_2 like 'Yes'  OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			  THEN
				  (:nRM_XX_FEE11 	/ nCountOfStocks )  * 1.1
			  ELSE
				  (:nRM_XX_FEE12  / nCountOfStocks )  * 1.1
	      END AS "DIncl",
			  CASE WHEN (l1.IL_NOTE_2 like 'Yes'  OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			  THEN
				  (:nRM_XX_FEE11 	/ nCountOfStocks )  * 1.1
			  ELSE
				  (:nRM_XX_FEE12  / nCountOfStocks )  * 1.1
	      END AS "Incl_Total",
	    CASE    WHEN l1.IL_LOCN IS NOT NULL THEN (Select To_Number(i.IM_REPORTING_PRICE) from IM i where i.IM_STOCK = 'COURIERM')
			    ELSE NULL
			    END     AS "ReportingPrice",NULL  AS "Address",
			    NULL   AS "Address2",NULL   AS "Suburb",
			    NULL    AS "State",NULL  AS "Postcode",
			    NULL    AS "DeliverTo",NULL  AS "AttentionTo" ,
			    0    AS "Weight",0   AS "Packages",
			    0    AS "OrderSource",l1.IL_NOTE_2 AS "Pallet/Space"
          , l1.IL_LOCN ,

		  nCountOfStocks AS CountCustStocks,NULL AS Email,IM_BRAND AS Brand,
           IM_OWNED_By AS    OwnedBy,
           IM_PROFILE AS    sProfile,
           NULL AS    WaiveFee,
           NULL As   Cost,
           NULL AS PaymentType

    FROM  NA n1 INNER JOIN IL l1 ON l1.IL_UID = n1.NA_EXT_KEY
      INNER JOIN NE e ON e.NE_ACCOUNT = n1.NA_ACCOUNT
      INNER JOIN IM  ON  IM_STOCK = n1.NA_STOCK
      INNER JOIN Dev_Locn_Cnt_By_Cust ON sLocn = l1.IL_LOCN  AND sCust = IM_CUST

                    WHERE n1.NA_EXT_TYPE = 1210067
                      AND e.NE_AVAIL_ACTUAL >= '1'
                      AND l1.IL_IN_LOCN NOT IN ('OBSOLETEMEL','OBSOLETESYD','PASTHISTORY', 'CANBERRA')
                      AND e.NE_STATUS =  1
                      AND e.NE_STRENGTH = 3
                      AND  IM_CUST LIKE '%'



	/*  FROM NI n1 INNER JOIN IM ON IM_STOCK = n1.NI_STOCK
	  INNER JOIN IL l1 ON l1.IL_LOCN = n1.NI_LOCN
    INNER JOIN Tmp_Locn_Cnt_By_Cust ON sLocn = l1.IL_LOCN  AND sCust = IM_CUST
    --WHERE IM_CUST = 'NSWFIRE' /*IN (SELECT RM_CUST FROM RM WHERE RM_ANAL = '22NSWP') */ /*AND    */
  /*  WHERE IM_ACTIVE = 1
	  AND IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_PARENT = ' '  AND RM_ANAL = :sAnalysis AND RM_TYPE = 0 AND RM_ACTIVE = 1 )
	  AND n1.NI_AVAIL_ACTUAL >= '1' AND n1.NI_STATUS <> 0
   -- AND n1.NI_EXT_TYPE = 1210067
                      AND l1.IL_IN_LOCN NOT IN ('OBSOLETEMEL','OBSOLETESYD','PASTHISTORY', 'CANBERRA')
                    --AND n1.NI_STATUS =  1
                      AND n1.NI_STRENGTH = 3      */
	  GROUP BY n1.NA_STOCK,IM_CUST,IM_XX_COST_CENTRE01
            ,l1.IL_LOCN,l1.IL_NOTE_2
            ,IM_LEVEL_UNIT ,IM_BRAND,IM_OWNED_By,IM_PROFILE
            ,5,6,8,9,10,11,12,nCountOfStocks


  /* EOM Storage Fees

  SELECT *,
  CASE WHEN SNOTE = 'E- Pallets' Then NCOUNTOFSTOCKS * 15
  ELSE NCOUNTOFSTOCKS * 7.5
  END As "Value"
  SELECT * FROM Tmp_Locn_Cnt_By_Cust WHERE sCust = 'CSAHS' AND sLocn = 'R2GL17-18'    */


  UNION ALL


  /*DB Maintenance Fee*/
	  SELECT    RM_CUST                AS "Customer",
			    RM_PARENT              AS "Parent",
			    NULL       AS "CostCentre",
			    NULL               AS "Order",
			    NULL         AS "OrderwareNum",
			    NULL            AS "CustomerRef",
			    NULL                     AS "Pickslip",
			    NULL                     AS "PickNum",
			    NULL                     AS "DespatchNote",
			    NULL                     AS "DespatchDate",
	    CASE    WHEN RD_CUST IS NOT NULL THEN 'DB Maint fee '
			    ELSE ''
			    END                      AS "FeeType",
			    'DB Maint'               AS "Item",
			    'DB Maint fee '                AS "Description",
          (SELECT Count(RD_CODE) FROM PWIN171.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN171.RM WHERE (RM_PARENT = :cust) AND SubStr(RD_CODE,0,2) NOT LIKE 'WH'  AND RD_CODE <> 'DIRECT'))  AS "Qty",
	    '1'           AS "UOI",
	    :nRM_XX_FEE21          AS "UnitPrice",
	    :nRM_XX_FEE21                    AS "OWUnitPrice",
	    :nRM_XX_FEE21 * (SELECT Count(RD_CODE) FROM PWIN171.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN171.RM WHERE (RM_PARENT = :cust) AND SubStr(RD_CODE,0,2) NOT LIKE 'WH'  AND RD_CODE <> 'DIRECT'))         AS "DExcl",
	    :nRM_XX_FEE21 * (SELECT Count(RD_CODE) FROM PWIN171.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN171.RM WHERE (RM_PARENT = :cust) AND SubStr(RD_CODE,0,2) NOT LIKE 'WH'  AND RD_CODE <> 'DIRECT'))      AS "Excl_Total",
		  (:nRM_XX_FEE21 * (SELECT Count(RD_CODE) FROM PWIN171.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN171.RM WHERE (RM_PARENT = :cust) AND SubStr(RD_CODE,0,2) NOT LIKE 'WH'  AND RD_CODE <> 'DIRECT'))) * 1.1         AS "DIncl",
	    (:nRM_XX_FEE21 * (SELECT Count(RD_CODE) FROM PWIN171.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN171.RM WHERE (RM_PARENT = :cust) AND SubStr(RD_CODE,0,2) NOT LIKE 'WH'  AND RD_CODE <> 'DIRECT'))) * 1.1        AS "Incl_Total",
		  :nRM_XX_FEE21                     AS "ReportingPrice",
			    NULL                     AS "Address",
			    NULL                     AS "Address2",
			    NULL                     AS "Suburb",
			    NULL                     AS "State",
			    NULL                     AS "Postcode",
			    NULL                     AS "DeliverTo",
			    NULL                     AS "AttentionTo" ,
			    0                     AS "Weight",
			    0                     AS "Packages",
			    0                     AS "OrderSource",
			    NULL AS "Pallet/Shelf Space",
				  NULL AS "Locn",
				  0 AS "CountOfStocks",
          NULL AS Email,
          'N/A' AS Brand,
           NULL AS    OwnedBy,
           NULL AS    sProfile,
           NULL AS    WaiveFee,
           NULL As   Cost,
           NULL AS PaymentType


	  FROM  PWIN171.RM INNER JOIN RD  ON RD_CUST  = RM_CUST
	  WHERE  :nRM_XX_FEE21 > 0
	  AND    RM_PARENT IN (SELECT RM_CUST FROM RM WHERE RM_PARENT = ' '  AND RM_ANAL = :sAnalysis AND RM_TYPE = 0 AND RM_ACTIVE = 1 )
    --AND (SELECT Count(RD_CODE) FROM PWIN171.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN171.RM WHERE RM_PARENT = :cust  AND SubStr(RD_CODE,0,2) NOT LIKE 'WH') AND RD_CODE <> 'DIRECT' > 0)
    GROUP BY  RM_CUST,
			    RM_PARENT,
			    RD_CUST,
			    RM_XX_FEE21





	  UNION ALL
  /*DB Maintenance Fee*/

  /*Stock Maint Charges including Stocktake and Kitting*/
      SELECT    RM_CUST                AS "Customer",
			    NULL              AS "Parent",
			    NULL       AS "CostCentre",
			    NULL               AS "Order",
			    NULL         AS "OrderwareNum",
			    NULL            AS "CustomerRef",
			    NULL                     AS "Pickslip",
			    NULL                     AS "PickNum",
			    NULL                     AS "DespatchNote",
			    NULL                     AS "DespatchDate",
	    CASE    WHEN RM_CUST IS NOT NULL THEN 'Stock Maint fee '
			    ELSE ''
			    END                      AS "FeeType",
			    'Stock Maint'               AS "Item",
			    'Stock Maint fee '                AS "Description",
          :nCountCustStocks  AS "Qty",
	    '1'           AS "UOI",
	    :nRM_XX_FEE20          AS "UnitPrice",
	    :nRM_XX_FEE20                   AS "OWUnitPrice",
	    :nRM_XX_FEE20 * :nCountCustStocks         AS "DExcl",
	    :nRM_XX_FEE20 * :nCountCustStocks      AS "Excl_Total",
		  (:nRM_XX_FEE20 * :nCountCustStocks) * 1.1         AS "DIncl",
	    (:nRM_XX_FEE20 * :nCountCustStocks) * 1.1        AS "Incl_Total",
		  :nRM_XX_FEE20                    AS "ReportingPrice",
			    NULL                     AS "Address",
			    NULL                     AS "Address2",
			    NULL                     AS "Suburb",
			    NULL                     AS "State",
			    NULL                     AS "Postcode",
			    NULL                     AS "DeliverTo",
			    NULL                     AS "AttentionTo" ,
			    0                     AS "Weight",
			    0                     AS "Packages",
			    0                     AS "OrderSource",
			    NULL AS "Pallet/Shelf Space",
				  NULL AS "Locn",
				  :nCountCustStocks AS "CountOfStocks",
          NULL AS Email,
          'N/A' AS Brand,
           NULL AS    OwnedBy,
           NULL AS    sProfile,
           NULL AS    WaiveFee,
           NULL As   Cost,
           NULL AS PaymentType

	  FROM  PWIN171.RM
	  WHERE   :nRM_XX_FEE20 > 0
	  AND     RM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_ANAL = :sAnalysis)
    GROUP BY  RM_CUST


	  UNION ALL

  /*Stock Maint Charges including Stocktake and Kitting*/

  /*Admin Charges*/
    	  SELECT    RM_CUST                AS "Customer",
			    NULL              AS "Parent",
			    NULL       AS "CostCentre",
			    NULL               AS "Order",
			    NULL         AS "OrderwareNum",
			    NULL            AS "CustomerRef",
			    NULL                     AS "Pickslip",
			    NULL                     AS "PickNum",
			    NULL                     AS "DespatchNote",
			    NULL                     AS "DespatchDate",
	    CASE    WHEN RM_CUST IS NOT NULL THEN 'Admin fee '
			    ELSE ''
			    END                      AS "FeeType",
			    'Admin'                   AS "Item",
			    'Admin fee '                AS "Description",
        CASE    WHEN RM_CUST IS NOT NULL THEN 1
			    ELSE NULL
			    END                      AS "Qty",
	    '1'           AS "UOI",
	      :nRM_XX_FEE19  AS "UnitPrice",
	    :nRM_XX_FEE19  AS "OWUnitPrice",
	    :nRM_XX_FEE19  AS "DExcl",
	    :nRM_XX_FEE19  AS "Excl_Total",
		  (:nRM_XX_FEE19  * 1.1)         AS "DIncl",
	    (:nRM_XX_FEE19 * 1.1)        AS "Incl_Total",
		  :nRM_XX_FEE19                    AS "ReportingPrice",
			    NULL                     AS "Address",
			    NULL                     AS "Address2",
			    NULL                     AS "Suburb",
			    NULL                     AS "State",
			    NULL                     AS "Postcode",
			    NULL                     AS "DeliverTo",
			    NULL                     AS "AttentionTo" ,
			    0                     AS "Weight",
			    0                     AS "Packages",
			    0                     AS "OrderSource",
			    NULL AS "Pallet/Shelf Space",
				  NULL AS "Locn",

				  0 AS "CountOfStocks",
          NULL AS Email,
          'N/A' AS Brand,
           NULL AS    OwnedBy,
           NULL AS    sProfile,
           NULL AS    WaiveFee,
           NULL As   Cost,
           NULL AS PaymentType

	  FROM  PWIN171.RM
	  WHERE     :nRM_XX_FEE19 > 0
	  AND     RM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_ANAL = :sAnalysis AND RM_TYPE = 0 AND RM_ACTIVE = 1 )
  GROUP BY  RM_CUST

	  UNION ALL

  /*Admin Charges*/


  /*Report Generation Charges*/
    	  SELECT    :Cust                AS "Customer",
			    NULL              AS "Parent",
			    NULL       AS "CostCentre",
			    NULL               AS "Order",
			    NULL         AS "OrderwareNum",
			    NULL            AS "CustomerRef",
			    NULL                     AS "Pickslip",
			    NULL                     AS "PickNum",
			    NULL                     AS "DespatchNote",
			    NULL                     AS "DespatchDate",
	    CASE    WHEN RM_CUST IS NOT NULL THEN 'Manual Report fee '
			    ELSE ''
			    END                      AS "FeeType",
			    'MANREPORTF'                   AS "Item",
			    'Manual Report fee '                AS "Description",
        CASE    WHEN RM_CUST IS NOT NULL THEN 1
			    ELSE NULL
			    END                      AS "Qty",
	    '1'           AS "UOI",
	      :nRM_XX_FEE34  AS "UnitPrice",
	    :nRM_XX_FEE34  AS "OWUnitPrice",
	    :nRM_XX_FEE34  AS "DExcl",
	    :nRM_XX_FEE34  AS "Excl_Total",
		  (:nRM_XX_FEE34  * 1.1)         AS "DIncl",
	    (:nRM_XX_FEE34 * 1.1)        AS "Incl_Total",
		  :nRM_XX_FEE34                    AS "ReportingPrice",
			    NULL                     AS "Address",
			    NULL                     AS "Address2",
			    NULL                     AS "Suburb",
			    NULL                     AS "State",
			    NULL                     AS "Postcode",
			    NULL                     AS "DeliverTo",
			    NULL                     AS "AttentionTo" ,
			    0                     AS "Weight",
			    0                     AS "Packages",
			    0                     AS "OrderSource",
			    NULL AS "Pallet/Shelf Space",
				  NULL AS "Locn",
				  0 AS "CountOfStocks",
          NULL AS Email,
          'N/A' AS Brand,
           NULL AS    OwnedBy,
           NULL AS    sProfile,
           NULL AS    WaiveFee,
           NULL As   Cost,
           NULL AS PaymentType

	  FROM  PWIN171.YN INNER JOIN RM ON RM_CUST = YN_OBJECT
	  WHERE     :nRM_XX_FEE34 > 0
    AND YN_ADD_DATE >= :start_date AND YN_ADD_DATE <= :end_date
    AND YN_TYPE = 'MANREPORTF'
	  AND     RM_CUST = 'BORBUI' OR RM_PARENT = 'BORBUI'
  GROUP BY  RM_CUST

	  UNION ALL

  /*Report Generation Charges*/



  /*Tabcorp Inner/Outer PackingFee*/
	  SELECT    s.SH_CUST                AS "Customer",
			    r.RM_PARENT              AS "Parent",
			    i.IM_XX_COST_CENTRE01         AS "CostCentre",
			    s.SH_ORDER               AS "Order",
			    s.SH_SPARE_STR_5         AS "OrderwareNum",
			    s.SH_CUST_REF            AS "CustomerRef",
			    t.ST_PICK                AS "Pickslip",
			    d.SD_XX_PICKLIST_NUM     AS "PickNum",
			    t.ST_PSLIP               AS "DespatchNote",
			    substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	    CASE    WHEN (i.IM_XX_QTY_PER_PACK IS NOT NULL AND (d.SD_STOCK NOT like 'COURIER%' AND d.SD_STOCK NOT like 'FEE%'))  THEN 'Packing Fee'
			    ELSE NULL
			    END                      AS "FeeType",
			    d.SD_STOCK               AS "Item",
			    d.SD_DESC                AS "Description",
	    CASE    WHEN d.SD_LINE IS NOT NULL THEN  1
			    ELSE NULL
			    END                     AS "Qty",
	    CASE    WHEN d.SD_LINE IS NOT NULL THEN  '1'
			    ELSE ''
			    END                     AS "UOI",
	    CASE   WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN :nRM_XX_FEE08 -- (Select RM_XX_FEE08 from RM where RM_CUST = :cust)
			  WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN :nRM_XX_FEE09 --  (Select RM_XX_FEE09 from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "UnitPrice",
	    CASE   WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN :nRM_XX_FEE08 -- (Select RM_XX_FEE08 from RM where RM_CUST = :cust)
			  WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN :nRM_XX_FEE09 --  (Select RM_XX_FEE09 from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                                          AS "OWUnitPrice",
			    CASE  WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN :nRM_XX_FEE08 -- (Select RM_XX_FEE08 from RM where RM_CUST = :cust)  * d.SD_QTY_DESP
			  WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN :nRM_XX_FEE09 --  (Select RM_XX_FEE09 from RM where RM_CUST = :cust)  * d.SD_QTY_DESP
			  ELSE NULL
			  END                      AS "DExcl",
			    CASE   WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN :nRM_XX_FEE08 -- (Select RM_XX_FEE08 from RM where RM_CUST = :cust)
			  WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN :nRM_XX_FEE09 --  (Select RM_XX_FEE09 from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                                          AS "Excl_Total",
		  CASE WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN :nRM_XX_FEE08 * 1.1--  ((Select RM_XX_FEE08 from RM where RM_CUST = :cust) * d.SD_QTY_DESP) * 1.1
			  WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN :nRM_XX_FEE09 * 1.1--  ((Select RM_XX_FEE09 from RM where RM_CUST = :cust) * d.SD_QTY_DESP) * 1.1
			  ELSE NULL
			  END                      AS "DIncl",
		  CASE WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN :nRM_XX_FEE08 * 1.1 --  ((Select RM_XX_FEE08 from RM where RM_CUST = :cust) * d.SD_QTY_DESP) * 1.1
			  WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN :nRM_XX_FEE09 * 1.1--  ((Select RM_XX_FEE09 from RM where RM_CUST = :cust) * d.SD_QTY_DESP) * 1.1
			  ELSE NULL
			  END                      AS "Incl_Total",
	    CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN (Select i.IM_REPORTING_PRICE from IM i where i.IM_STOCK = d.SD_STOCK)
			    ELSE NULL
			    END                      AS "ReportingPrice",
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

				  0 AS "CountOfStocks",
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			          ELSE ''
			          END AS Email,
          i.IM_BRAND AS Brand,
           NULL AS    OwnedBy,
           NULL AS    sProfile,
           NULL AS    WaiveFee,
           NULL As   Cost,
           s.SH_SPARE_INT_4 AS PaymentType


	  FROM      PWIN171.SD d
			    INNER JOIN PWIN171.SH s  ON s.SH_ORDER  = d.SD_ORDER
			    INNER JOIN PWIN171.ST t  ON t.ST_ORDER  = s.SH_ORDER  --AND t.ST_PICK = d.SD_LAST_PICK_NUM
			    INNER JOIN PWIN171.RM r  ON r.RM_CUST  = s.SH_CUST
			    INNER JOIN PWIN171.IM i  ON i.IM_STOCK = d.SD_STOCK

	  WHERE     Upper(i.IM_XX_QTY_PER_PACK) IN ('INNER','OUTER')
	  AND       i.IM_CUST = :cust
	  AND       s.SH_STATUS <> 3
	  AND       s.SH_ORDER = t.ST_ORDER
	  AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
	  GROUP BY  s.SH_CUST,
			    s.SH_SPARE_STR_4,
			    s.SH_ORDER,
			    t.ST_PICK,
			    d.SD_XX_PICKLIST_NUM,
			    t.ST_PSLIP,
			    t.ST_DESP_DATE,
			    i.IM_XX_QTY_PER_PACK,
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
			    d.SD_QTY_DESP,
			    r.RM_PARENT,
			    i.IM_XX_COST_CENTRE01,
			    s.SH_SPARE_STR_5,
			    s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,i.IM_BRAND,
           s.SH_SPARE_INT_4
  /*Tabcorp Inner/Outer PackingFee*/

  --DROP TABLE Tmp_Admin_Data2

  /*SELECT * FROM dev_AdminData
  ORDER BY OrderNum,Pickslip Asc  */

    /*SELECT * FROM TMP_ALL_FEES
  ORDER BY OrderNum,Pickslip Asc  */

  --SELECT * FROM Dev_Admin_Data_Pick_LineCounts

