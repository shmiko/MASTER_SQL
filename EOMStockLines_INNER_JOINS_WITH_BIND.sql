/* First run this file with variables set in header - declare variables - drop tables, recreate tables, insert into tables - then query tables */
/* EOM_INVOICING_CREATE_TABLES.sql */
--Admin Order Data by Parent or Customer
/*decalre variables These are being declared via the stored procedure - just need to redeclare cust so as we can get the rates*/

var cust2 varchar2(20)
exec :cust2 := 'TABCORP'
var nx NUMBER
EXEC :nx := 1810105
var cust varchar2(20)
exec :cust := 'TABCORP'
var ordernum varchar2(20)
exec :ordernum := '1363806'
var stock varchar2(20)
exec :stock := 'COURIER*'
var stock2 varchar2(20)
exec :stock2 := 'FEE*'
var source varchar2(20)
exec :source := 'BSPRINTNSW'
var sAnalysis varchar2(20) /*VerbalOrderEntryFee*/
exec SELECT  RM_ANAL INTO :sAnalysis FROM RM where RM_CUST = :cust;
var anal varchar2(20)
exec :anal := '72'
var start_date varchar2(20)
exec :start_date := To_Date('2-Apr-2014')
var end_date varchar2(20)
exec :end_date := To_Date('8-Apr-2014')

 --EXEC EOM_INVOICING();--:cust,:ordernum,:stock,:source,:sAnalysis,:start_date,:end_date);

/*insert into temp admin data table*/
INSERT into tbl_AdminData
				(Customer ,Parent ,CostCentre ,OrderNum ,OrderwareNum ,CustRef ,Pickslip ,PickNum ,  DespatchNote ,DespatchDate ,FeeType ,Item ,Description ,Qty ,UOI ,UnitPrice ,OW_Unit_Sell_Price ,Sell_Excl ,Sell_Excl_Total ,Sell_Incl ,Sell_Incl_Total ,ReportingPrice ,Address ,Address2 ,Suburb ,State ,Postcode , DeliverTo ,AttentionTo ,Weight ,Packages ,OrderSource ,ILNOTE2 ,NILOCN ,NIAVAILACTUAL ,CountOfStocks , Email , Brand , OwnedBy  , sProfile , WaiveFee , Cost )

/*insert into temp admin data table*/



/*Stocks*/

	SELECT    s.SH_CUST                AS "Customer",
			  r.RM_PARENT              AS "Parent",
	   CASE    WHEN i.IM_CUST <> :cust2 THEN s.SH_SPARE_STR_4
			      WHEN i.IM_CUST = :cust2 THEN i.IM_XX_COST_CENTRE01
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
	   CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> :cust2 AND i.IM_OWNED_BY = 0 THEN d.SD_SELL_PRICE
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> :cust2 AND i.IM_OWNED_BY = 1 THEN n.NI_SELL_VALUE/n.NI_NX_QUANTITY
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = :cust2 AND eom_report_pkg.F_BREAK_UNIT_PRICE2(r.RM_GROUP_CUST,d.SD_STOCK) IS NOT NULL THEN eom_report_pkg.F_BREAK_UNIT_PRICE2(r.RM_GROUP_CUST,d.SD_STOCK)
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = :cust2 AND eom_report_pkg.F_BREAK_UNIT_PRICE2(r.RM_GROUP_CUST,d.SD_STOCK) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			      ELSE NULL
			      END                        AS "Batch/UnitPrice",
	   CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> :cust2 THEN To_Number(i.IM_REPORTING_PRICE)
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = :cust2 THEN  eom_report_pkg.F_BREAK_UNIT_PRICE2(r.RM_GROUP_CUST,d.SD_STOCK)
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = :cust2 AND (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			      ELSE NULL
			      END                        AS "OWUnitPrice",
      CASE  WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> :cust2 AND i.IM_OWNED_BY = 0 THEN d.SD_SELL_PRICE * d.SD_QTY_DESP
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> :cust2 AND i.IM_OWNED_BY = 1 THEN (n.NI_SELL_VALUE/n.NI_NX_QUANTITY) * d.SD_QTY_DESP
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = :cust2 AND eom_report_pkg.F_BREAK_UNIT_PRICE2(r.RM_GROUP_CUST,d.SD_STOCK) IS NOT NULL THEN  eom_report_pkg.F_BREAK_UNIT_PRICE2(r.RM_GROUP_CUST,d.SD_STOCK) * d.SD_QTY_DESP
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = :cust2 AND eom_report_pkg.F_BREAK_UNIT_PRICE2(r.RM_GROUP_CUST,d.SD_STOCK) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE * d.SD_QTY_DESP
			      ELSE NULL
			      END          AS "DExcl",

	   CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> :cust2 THEN To_Number(i.IM_REPORTING_PRICE)
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = :cust2 THEN  eom_report_pkg.F_BREAK_UNIT_PRICE2(r.RM_GROUP_CUST,d.SD_STOCK)
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = :cust2 AND eom_report_pkg.F_BREAK_UNIT_PRICE2(r.RM_GROUP_CUST,d.SD_STOCK) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			      ELSE NULL
			      END                       AS "Excl_Total",
	  CASE    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> :cust2 AND i.IM_OWNED_BY = 0 THEN (d.SD_SELL_PRICE * d.SD_QTY_DESP) * 1.1
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> :cust2 AND i.IM_OWNED_BY = 1  THEN  ((n.NI_SELL_VALUE/n.NI_NX_QUANTITY) * d.SD_QTY_DESP) * 1.1
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = :cust2 AND eom_report_pkg.F_BREAK_UNIT_PRICE2(r.RM_GROUP_CUST,d.SD_STOCK) IS NOT NULL THEN  (eom_report_pkg.F_BREAK_UNIT_PRICE2(r.RM_GROUP_CUST,d.SD_STOCK) * d.SD_QTY_DESP) * 1.1
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = :cust2 AND eom_report_pkg.F_BREAK_UNIT_PRICE2(r.RM_GROUP_CUST,d.SD_STOCK) IS NULL THEN  (d.SD_XX_OW_UNIT_PRICE * d.SD_QTY_DESP) * 1.1
			      ELSE NULL
			      END          AS "DIncl",
	   CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> :cust2 AND i.IM_OWNED_BY = 0 THEN (d.SD_SELL_PRICE * d.SD_QTY_DESP) * 1.1
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> :cust2 AND i.IM_OWNED_BY = 1 THEN  ((n.NI_SELL_VALUE/n.NI_NX_QUANTITY) * d.SD_QTY_DESP) * 1.1
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = :cust2 AND eom_report_pkg.F_BREAK_UNIT_PRICE2(r.RM_GROUP_CUST,d.SD_STOCK) IS NOT NULL THEN  (eom_report_pkg.F_BREAK_UNIT_PRICE2(r.RM_GROUP_CUST,d.SD_STOCK) * d.SD_QTY_DESP) * 1.1
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = :cust2 AND eom_report_pkg.F_BREAK_UNIT_PRICE2(r.RM_GROUP_CUST,d.SD_STOCK) IS NULL THEN  (d.SD_XX_OW_UNIT_PRICE * d.SD_QTY_DESP) * 1.1
			      ELSE NULL
			      END          AS "Incl_Total",
	  CASE    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> :cust2 THEN To_Number(i.IM_REPORTING_PRICE)
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = :cust2 THEN  eom_report_pkg.F_BREAK_UNIT_PRICE2(r.RM_GROUP_CUST,d.SD_STOCK)
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = :cust2 AND eom_report_pkg.F_BREAK_UNIT_PRICE2(r.RM_GROUP_CUST,d.SD_STOCK) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
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
    CASE   WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			     ELSE ''
			     END AS Email,
    i.IM_BRAND AS Brand,
    NULL AS OwnedBy,
    NULL AS sProfile,
    NULL AS WaiveFee,
    NULL AS Cost
	FROM      PWIN175.SD d
			  RIGHT JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER
        LEFT JOIN PWIN175.SL l  ON l.SL_PICK   = t.ST_PICK
			  INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
        INNER JOIN PWIN175.NI n  ON n.NI_NV_EXT_KEY = l.SL_UID
  WHERE NI_NV_EXT_TYPE = :nx AND NI_STRENGTH = 3 AND NI_DATE = t.ST_DESP_DATE AND NI_STOCK = d.SD_STOCK AND NI_STATUS <> 0
	AND     s.SH_STATUS <> 3
  AND     i.IM_CUST IN (:cust)
	AND       s.SH_ORDER = t.ST_ORDER
	--AND       d.SD_STOCK NOT IN (:stock,:stock2)
  AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
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
              l.SL_PSLIP_QTY   --2.6s


	--HAVING    Sum(s.SH_ORDER) <> 1




/*SELECT * FROM tbl_AdminData
ORDER BY OrderNum,Pickslip Asc  */

 --3s