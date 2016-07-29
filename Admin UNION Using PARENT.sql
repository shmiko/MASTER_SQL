--Admin Order Data by Parent or Customer
/*decalre variables*/
	var cust varchar2(20)
exec :cust := 'LUXOTTICA'
var ordernum varchar2(20)
exec :ordernum := '1363806'
var stock varchar2(20)
exec :stock := 'COURIER'
var source varchar2(20)
exec :source := 'BSPRINTNSW'
var anal varchar2(20)
exec :anal := '49'
var start_date varchar2(20)
exec :start_date := To_Date('7-Aug-2013')
var end_date varchar2(20)
exec :end_date := To_Date('7-Aug-2013')


  --Declare Rates
  DECLARE
   var nRM_XX_FEE03 varchar2(20) --Manual Order Entry Fee
   exec SELECT RM_XX_FEE03 INTO :nRM_XX_FEE03 FROM RM where RM_CUST = :cust;
  BEGIN
   SELECT RM_XX_FEE03 INTO nRM_XX_FEE03 FROM RM where RM_CUST = :cust;
  END;


/*decalre variables*/

/* Drop table to hold II values */
	DROP TABLE Tmp_Admin_Data_BreakPrices
/* Drop table to hold II values */

/* Create table to hold II values */
	CREATE TABLE Tmp_Admin_Data_BreakPrices (vIIStock VARCHAR(30), vIICust VARCHAR(20), vUnitPrice NUMBER)--           AS 'Customer',
/* Create table to hold II values */

/* Insert into table to hold II values */
	INSERT INTO Tmp_Admin_Data_BreakPrices
	SELECT II_STOCK,II_CUST,II_BREAK_LCL
	FROM II INNER JOIN IM ON IM_STOCK = II_STOCK
	AND II_BREAK_LCL > 0.000001
	WHERE IM_CUST= 'TABCORP'
/* Insert into table to hold II values */

/* query table to hold II values */
	SELECT * FROM Tmp_Admin_Data_BreakPrices
/* query table to hold II values */

/*drop temp table to hold pickslip numbers*/
	DROP TABLE Tmp_Admin_Data_Pickslips
/*drop temp table to hold pickslip numbers*/

/*create temp table to hold pickslip numbers*/
	CREATE TABLE Tmp_Admin_Data_Pickslips (vPickslip VARCHAR(200),vPslip VARCHAR(10), vDateDesp DATE, vPackages NUMBER,
                                        vWeight NUMBER, vST_XX_NUM_PAL_SW NUMBER,vST_XX_NUM_PALLETS NUMBER, vST_XX_NUM_CARTONS NUMBER)--           AS 'Customer',
/*create temp table to hold pickslip numbers*/

/*insert into temp table to hold pickslip numbers*/
	INSERT INTO Tmp_Admin_Data_Pickslips
	SELECT LTrim(ST_PICK),LTrim(ST_PSLIP), substr(To_Char(ST_DESP_DATE),0,10), ST_WEIGHT, ST_PACKAGES,ST_XX_NUM_PAL_SW,ST_XX_NUM_PALLETS,ST_XX_NUM_CARTONS
	FROM ST INNER JOIN SH ON SH_ORDER = ST_ORDER
	WHERE ST_DESP_DATE >= :start_date AND ST_DESP_DATE <= :end_date
	AND ST_PSLIP <> 'CANCELLED'
	AND SH_STATUS <> 3
/*insert into temp table to hold pickslip numbers*/

/*query temp table to hold pickslip numbers*/
	SELECT *
	FROM Tmp_Admin_Data_Pickslips
/*query temp table to hold pickslip numbers*/

/* Drop temp table to hold SL line data */
	DROP TABLE Tmp_Admin_Data_Pick_LineCounts
/* Drop temp table to hold SL line data */

/* Create temp table to hold SL line data */
	CREATE TABLE Tmp_Admin_Data_Pick_LineCounts (  nCountOfLines NUMBER, vSLPickslipNum VARCHAR(10), vSLOrderNum VARCHAR2(10), vSLPslip VARCHAR(10), vDateDespSL VARCHAR(255)
	,vPackagesSL NUMBER, vWeightSL NUMBER,vST_XX_NUM_PAL_SW_SL NUMBER,vST_XX_NUM_PALLETS_SL NUMBER, vST_XX_NUM_CARTONS_SL NUMBER,vST_PICK_QTY NUMBER, vSL_ORDER_LINE NUMBER)
/* Create temp table to hold SL line data */

/* Insert into temp table to hold SL line data */
	INSERT INTO Tmp_Admin_Data_Pick_LineCounts
	SELECT Count(SL_LINE),LTrim(SL_PICK), LTrim(SL_ORDER), LTrim(SL_PSLIP),TP.vDateDesp, TP.vPackages,TP.vWeight,TP.vST_XX_NUM_PAL_SW,TP.vST_XX_NUM_PALLETS,TP.vST_XX_NUM_CARTONS,SL_PICK_QTY, SL_ORDER_LINE
	FROM Tmp_Admin_Data_Pickslips TP LEFT OUTER JOIN SL ON LTrim(SL_PICK) = TP.vPickslip   WHERE SL_PSLIP <> 'CANCELLED'  GROUP BY SL_PICK,SL_ORDER,SL_PSLIP,TP.vDateDesp,TP.vPackages,TP.vWeight,TP.vST_XX_NUM_PAL_SW,TP.vST_XX_NUM_PALLETS,TP.vST_XX_NUM_CARTONS,SL_PICK_QTY, SL_ORDER_LINE
/* Insert into temp table to hold SL line data */

/* query temp table to hold SL line data */
	SELECT * FROM Tmp_Admin_Data_Pick_LineCounts;
/* query temp table to hold SL line data */

/*Drop temp table for batch prices*/
	DROP TABLE  Tmp_Batch_Price_SL_Stock
/*Drop temp table for batch prices*/

/*Create temp table for batch prices*/
	CREATE TABLE Tmp_Batch_Price_SL_Stock ( vBatchStock VARCHAR(30), vBatchPickNum VARCHAR(10), vDExcl NUMBER, vUnitPrice NUMBER, vQuantity NUMBER)
/*Create temp table for batch prices*/

/*Insert into temp table for batch prices*/
	INSERT INTO Tmp_Batch_Price_SL_Stock(vBatchStock,vBatchPickNum,vUnitPrice,vDExcl, vQuantity)
	SELECT nz.NI_STOCK, LTrim(RTrim(nz.NI_SL_PSLIP)), CAST((NX_SELL_VALUE/NX_QUANTITY) AS DECIMAL(22,2)) AS "UnitPrice", CAST(xz.NX_SELL_VALUE AS DECIMAL(22,2)), xz.NX_QUANTITY
	--Count(ROWNUM) AS "RecordCount"
	FROM  NX xz INNER JOIN NI nz ON nz.NI_NX_MOVEMENT = xz.NX_MOVEMENT
	INNER JOIN NE ez ON ez.NE_ENTRY = nz.NI_ENTRY AND ez.NE_PRICE_ENTRY = xz.NX_ENTRY
	WHERE ez.NE_NV_EXT_TYPE = 1810105
	AND ez.NE_STRENGTH = 3
	AND xz.NX_SELL_VALUE > 0 AND xz.NX_SELL_VALUE IS NOT NULL
	AND xz.NX_QUANTITY > 0
	AND ez.NE_ADD_DATE >= :start_date
	--AND ez.NE_NV_EXT_KEY = (SELECT SL_UID FROM SL WHERE LTrim(RTrim(SL_PICK)) = '2607366')-- AND SL_ORDER_LINE  = 1)
	GROUP BY nz.NI_STOCK, nz.NI_SL_PSLIP, xz.NX_SELL_VALUE, xz.NX_QUANTITY
/*Insert into temp table for batch prices*/

/*query temp table for batch prices*/
	SELECT * FROM Tmp_Batch_Price_SL_Stock
/*query temp table for batch prices*/

/*Drop temp admin data table*/
	DROP TABLE Tmp_Admin_Data2
/*Drop temp admin data table*/

/*create temp admin data table*/
	CREATE TABLE Tmp_Admin_Data2
	(       Customer VARCHAR(255),--           AS "Customer",
			Parent VARCHAR(255),--             AS "Parent",
			CostCentre VARCHAR(255),--         AS "CostCentre",
			OrderNum VARCHAR(255),--           AS "Order",
			OrderwareNum VARCHAR(255),--       AS "Order",
			CustRef VARCHAR(255),--            AS "CustRef"
			Pickslip VARCHAR(255),--           AS "Pickslip",
			PickNum VARCHAR(255),--            AS "PickNum",
			DespatchNote VARCHAR(255),--       AS "DespatchNote",
			DespatchDate VARCHAR(255),--       AS "DespatchDate",
			FeeType VARCHAR(255),--            AS "FeeType",
			Item VARCHAR(255),--               AS "Item",
			Description VARCHAR(255),--        AS "Description",
			Qty NUMBER,--                AS "Qty",
			UOI VARCHAR(255),--                AS "UOI",
			Unit_Sell_Price NUMBER,--          AS "UnitPrice",
			OW_Unit_Sell_Price NUMBER,--        AS "OWUnitPrice",
			Sell_Excl NUMBER,--         AS "Excl_Total",
			Sell_Excl_Total NUMBER,--              AS "DIncl",
			Sell_Incl NUMBER,--         AS "Incl_Total",
			Sell_Incl_Total NUMBER,
			ReportingPrice NUMBER,--     AS "ReportingPrice",
			Address VARCHAR(255),--            AS "Address",
			Address2 VARCHAR(255),--           AS "Address2",
			Suburb VARCHAR(255),--             AS "Suburb",
			State VARCHAR(255),--              AS "State",
			Postcode VARCHAR(255),--           AS "Postcode",
			DeliverTo VARCHAR(255),--          AS "DeliverTo",
			AttentionTo VARCHAR(255),--        AS "AttentionTo" ,
			Weight NUMBER,--             AS "Weight",
			Packages NUMBER,--           AS "Packages",
			OrderSource INTEGER,--        AS "OrderSource",
			ILNOTE2 VARCHAR(255),--          AS "Palett/Shelf",
			NILOCN VARCHAR(255),--            AS "Location",
			NIAVAILACTUAL NUMBER,--    AS "SOH",
			CountOfStocks NUMBER     -- AS "Count"


	)
/*create temp admin data table*/

/*insert into temp admin data table*/
	INSERT into Tmp_Admin_Data2(
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
				Unit_Sell_Price,
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
				CountOfStocks

				)
/*insert into temp admin data table*/

/*freight fees*/
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
	  CASE    WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1  THEN 'Freight Fee'
			  ELSE To_Char(d.SD_DESC)
			  END                      AS "FeeType",
			  d.SD_STOCK               AS "Item",
			  '="' || To_Char(d.SD_DESC) || '"'               AS "Description",
	  CASE    WHEN d.SD_LINE IS NOT NULL THEN  1
			  ELSE NULL
			  END                     AS "Qty",
	  CASE    WHEN d.SD_LINE IS NOT NULL THEN  '1'
			  ELSE NULL
			  END                      AS "UOI",
			  d.SD_SELL_PRICE          AS "SellUnitPrice",
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
				NULL AS "AvailSOH",/*Avail SOH*/
				NULL AS "CountOfStocks"
	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_PICK))  = LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM))
			  INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
	WHERE     s.SH_ORDER = d.SD_ORDER
	--AND       r.RM_ANAL = :anal
	AND       (r.RM_PARENT = :cust OR r.RM_CUST = :cust)
	AND       d.SD_STOCK = :stock
	AND       s.SH_ORDER = t.ST_ORDER
	AND       d.SD_SELL_PRICE >= 1
	AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date


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
			  s.SH_CUST_REF




	UNION ALL

/*freight fees*/

/*manual freight fees*/
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
	      CASE    WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1  THEN 'Freight Fee'
			      ELSE To_Char(d.SD_DESC)
			      END                      AS "FeeType",
			      d.SD_STOCK               AS "Item",
			      '="' || To_Char(d.SD_DESC) || '"'               AS "Description",
	      CASE    WHEN d.SD_LINE IS NOT NULL THEN  1
			      ELSE NULL
			      END                     AS "Qty",
	      CASE    WHEN d.SD_LINE IS NOT NULL THEN  '1'
			      ELSE NULL
			      END                      AS "UOI",
			  d.SD_SELL_PRICE          AS "SellUnitPrice",
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
				NULL AS "AvailSOH",/*Avail SOH*/
				NULL AS "CountOfStocks"
	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_ORDER))  = LTRIM(RTRIM(d.SD_ORDER))
			  INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
	WHERE     s.SH_ORDER = d.SD_ORDER
	--AND       r.RM_ANAL = :anal
	AND       (r.RM_PARENT = :cust OR r.RM_CUST = :cust)
	AND       d.SD_STOCK IN ('COURIERM','COURIERS','COURIER','DETENTIONTIMEM','DETENTIONTIMES','FREIGHTDUTY')
	AND       s.SH_ORDER = t.ST_ORDER
	AND       d.SD_SELL_PRICE >= 1
	AND       d.SD_ADD_DATE >= '2-Aug-2013'
	--AND       d.SD_ADD_DATE >= :start_date AND d.SD_ADD_DATE <= :end_date
	AND       d.SD_ADD_OP NOT LIKE 'SERV%'


	GROUP BY  s.SH_CUST,
			  s.SH_SPARE_STR_4,
			  s.SH_ORDER,
			  t.ST_PICK,
			  d.SD_XX_PICKLIST_NUM,
			  t.ST_PSLIP,
			  d.SD_ADD_DATE,
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
			  d.SD_ADD_OP,
			  t.ST_DESP_DATE




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
			  END                     AS "DExcl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  :nRM_XX_FEE03 --(Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = :cust)
			  ELSE NULL
			  END                     AS "OWUnitPrice",
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
			  NULL             AS "Weight",
			  NULL           AS "Packages",
			  s.SH_SPARE_DBL_9        AS "OrderSource",
			  NULL AS "Pallet/Shelf Space", /*Pallet/Space*/
				NULL AS "Locn", /*Locn*/
				NULL AS "AvailSOH",/*Avail SOH*/
				NULL AS "CountOfStocks"
	FROM      PWIN175.SH s
			  INNER JOIN PWIN175.SD d ON d.SD_ORDER  = s.SH_ORDER
			  INNER JOIN PWIN175.IM i ON i.IM_STOCK = d.SD_STOCK
			  INNER JOIN PWIN175.ST t ON t.ST_ORDER = s.SH_ORDER AND t.ST_PICK = s.SH_LAST_PICK_NUM
			  INNER JOIN PWIN175.RM r ON r.RM_CUST  = s.SH_CUST
			  --LEFT JOIN PWIN175.RM r2 ON r2.RM_ANAL = r.RM_ANAL AND r2.RM_CUST = :cust
	WHERE (r.RM_PARENT = :cust OR r.RM_CUST = :cust)
  AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	AND       s.SH_SPARE_DBL_9 = 1
	AND       d.SD_LINE = 1
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> 0
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> '0'
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) IS NOT NULL
	AND       To_Number(regexp_substr(r.RM_XX_FEE03,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0
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
			  s.SH_CUST_REF





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
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = :cust)
			  ELSE NULL
			  END                     AS "UnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = :cust)
			  ELSE NULL
			  END                     AS "DExcl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = :cust)
			  ELSE NULL
			  END                     AS "OWUnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = :cust)
			  ELSE NULL
			  END                     AS "Excl_Total",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN   (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = :cust) * 1.1
			  ELSE NULL
			  END                     AS "DIncl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = :cust) * 1.1
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
				NULL AS "AvailSOH",/*Avail SOH*/
				NULL AS "CountOfStocks"
	FROM      PWIN175.SH s
			  INNER JOIN PWIN175.SD d ON d.SD_ORDER  = s.SH_ORDER
			  INNER JOIN PWIN175.IM i ON i.IM_STOCK = d.SD_STOCK
			  INNER JOIN PWIN175.ST t ON t.ST_ORDER = s.SH_ORDER AND t.ST_PICK = s.SH_LAST_PICK_NUM
			  INNER JOIN PWIN175.RM r ON r.RM_CUST  = s.SH_CUST
			  --LEFT JOIN PWIN175.RM r2 ON r2.RM_ANAL = r.RM_ANAL AND r2.RM_CUST = :cust
	WHERE (r.RM_PARENT = :cust OR r.RM_CUST = :cust)
  AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	AND       s.SH_SPARE_DBL_9 = 3
	AND       d.SD_LINE = 1
	--AND       Select rm3.RM_XX_FEE02 from RM rm3 where To_Number(regexp_substr(rm3.RM_XX_FEE02,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0 AND rm3.RM_CUST = :cust
	AND       To_Number(regexp_substr(r.RM_XX_FEE02,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0 --AND rm3.RM_CUST = :cust
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
			  s.SH_CUST_REF





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
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = :cust)
			  ELSE NULL
			  END                     AS "UnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = :cust)
			  ELSE NULL
			  END                     AS "DExcl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = :cust)
			  ELSE NULL
			  END                     AS "OWUnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = :cust)
			  ELSE NULL
			  END                     AS "Excl_Total",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN   (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = :cust) * 1.1
			  ELSE NULL
			  END                     AS "DIncl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = :cust) * 1.1
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
				NULL AS "AvailSOH",/*Avail SOH*/
				NULL AS "CountOfStocks"
	FROM      PWIN175.SH s
			  INNER JOIN PWIN175.SD d ON d.SD_ORDER  = s.SH_ORDER
			  INNER JOIN PWIN175.IM i ON i.IM_STOCK = d.SD_STOCK
			  INNER JOIN PWIN175.ST t ON t.ST_ORDER = s.SH_ORDER AND t.ST_PICK = s.SH_LAST_PICK_NUM
			  INNER JOIN PWIN175.RM r ON r.RM_CUST  = s.SH_CUST
			  --LEFT JOIN PWIN175.RM r2 ON r2.RM_ANAL = r.RM_ANAL AND r2.RM_CUST = :cust
	WHERE (r.RM_PARENT = :cust OR r.RM_CUST = :cust)
  AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	AND       s.SH_SPARE_DBL_9 = 2
	AND       d.SD_LINE = 1
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> 0
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> '0'
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) IS NOT NULL
	AND       To_Number(regexp_substr(r.RM_XX_FEE07,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0
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
			  s.SH_CUST_REF





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
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = :cust)
			  ELSE NULL
			  END                     AS "UnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = :cust)
			  ELSE NULL
			  END                     AS "DExcl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = :cust)
			  ELSE NULL
			  END                     AS "OWUnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = :cust)
			  ELSE NULL
			  END                     AS "Excl_Total",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN   (Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = :cust) * 1.1
			  ELSE NULL
			  END                     AS "DIncl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = :cust) * 1.1
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
				NULL AS "AvailSOH",/*Avail SOH*/
				NULL AS "CountOfStocks"
	FROM      PWIN175.SH s
			  INNER JOIN PWIN175.SD d ON d.SD_ORDER  = s.SH_ORDER
			  INNER JOIN PWIN175.IM i ON i.IM_STOCK = d.SD_STOCK
			  INNER JOIN PWIN175.ST t ON t.ST_ORDER = s.SH_ORDER AND t.ST_PICK = s.SH_LAST_PICK_NUM
			  INNER JOIN PWIN175.RM r ON r.RM_CUST  = s.SH_CUST
			  --LEFT JOIN PWIN175.RM r2 ON r2.RM_ANAL = r.RM_ANAL AND r2.RM_CUST = :cust
	WHERE (r.RM_PARENT = :cust OR r.RM_CUST = :cust)
  AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	AND       s.SH_SPARE_DBL_9 = 4
	AND       d.SD_LINE = 1
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> 0
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> '0'
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) IS NOT NULL
	AND       To_Number(regexp_substr(r.RM_XX_FEE01,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0
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
			  s.SH_CUST_REF





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
			   WHEN i.IM_TYPE = 'BB_PACK'   THEN (Select To_Number(RM_XX_FEE08) from RM where RM_CUST = :cust)
			 ELSE NULL
			 END                      AS "UnitPrice",
	   CASE
			   WHEN i.IM_TYPE = 'BB_PACK'  THEN (Select To_Number(RM_XX_FEE08) from RM where RM_CUST = :cust)
			 ELSE NULL
			 END                      AS "DExcl",
			  NULL                    AS "OWUnitPrice",
			  NULL                    AS "Excl_Total",
		CASE
			   WHEN i.IM_TYPE = 'BB_PACK'  THEN (Select To_Number(RM_XX_FEE08) from RM where RM_CUST = :cust)   * 1.1
			 ELSE NULL
			 END                      AS "DIncl",
		CASE
			   WHEN i.IM_TYPE = 'BB_PACK'  THEN (Select To_Number(RM_XX_FEE08) from RM where RM_CUST = :cust)  * 1.1
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
				NULL AS "AvailSOH",/*Avail SOH*/
				NULL AS "CountOfStocks"


	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER  AND t.ST_PICK = d.SD_LAST_PICK_NUM
			  INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
	/*WHERE     (Select rmP.RM_XX_FEE08
			   from RM rmP
			   where To_Number(regexp_substr(rmP.RM_XX_FEE08, '^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0 AND rmp.RM_CUST = :cust)  > 0
					 --To_Number(regexp_substr(r2.RM_XX_FEE01,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0   */
	AND       s.SH_ORDER = d.SD_ORDER
	AND       i.IM_TYPE = 'BB_PACK'
	AND       r.RM_ANAL = :anal
	AND     (r.RM_CUST = 'BEYONDBLUE' OR r.RM_PARENT = 'BEYONDBLUE')
  AND     To_Number(regexp_substr(r.RM_XX_FEE08, '^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0
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
			  s.SH_CUST_REF

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
	  CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN  (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust)
			 ELSE NULL
			 END                      AS "UnitPrice",
	  CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN  (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust)
			 ELSE NULL
			 END                      AS "DExcl",
			 NULL                AS "OWUnitPrice",
			 NULL           AS "Excl_Total",
	   CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN  (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust) * 1.1
			 ELSE NULL
			 END                      AS "DIncl",
	   CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN   (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust)  * 1.1
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
				NULL AS "AvailSOH",/*Avail SOH*/
				NULL AS "CountOfStocks"


	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER
			  INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
	WHERE     To_Number(regexp_substr(r.RM_XX_FEE25, '^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0
  AND       (r.RM_PARENT = :cust OR r.RM_CUST = :cust)
  AND       (s.SH_NOTE_1 = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE')
	AND       s.SH_STATUS <> 3
	AND       d.SD_LINE = 1
	AND       r.RM_ANAL = :anal
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
			  s.SH_CUST_REF

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
		CASE  WHEN d.SD_STOCK = 'EMERQSRFEE' AND s.SH_CAMPAIGN = 'TABSPEC' THEN d.SD_EXCL
			  ELSE NULL
			  END                      AS "DExcl",
			  d.SD_XX_OW_UNIT_PRICE                     AS "OWUnitPrice",
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
				NULL                     AS "AvailSOH",/*Avail SOH*/
				NULL                     AS "CountOfStocks"


	FROM      PWIN175.SH s
			  INNER JOIN PWIN175.SD d ON d.SD_ORDER  = s.SH_ORDER
			  INNER JOIN PWIN175.IM i ON i.IM_STOCK = d.SD_STOCK
			  INNER JOIN PWIN175.ST t ON t.ST_ORDER = s.SH_ORDER AND t.ST_PICK = s.SH_LAST_PICK_NUM
			  INNER JOIN PWIN175.RM r ON r.RM_CUST  = s.SH_CUST
	WHERE     s.SH_ORDER = d.SD_ORDER
	AND       (d.SD_STOCK = 'EMERQSRFEE' AND s.SH_CAMPAIGN = 'TABSPEC')
	AND       s.SH_STATUS <> 3
  AND       (r.RM_PARENT = :cust OR r.RM_CUST = :cust)
	AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL --(SELECT Count(tt.ST_ORDER) FROM PWIN175.ST tt WHERE LTrim(tt.ST_ORDER) = LTrim(s.SH_ORDER)) = 1
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
			  s.SH_CUST_REF

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
	  CASE    WHEN t.ST_XX_NUM_PALLETS >= 1 THEN 'Pallet Fee is '
			  ELSE NULL
			  END                      AS "FeeType",
	  CASE    WHEN d.SD_LINE IS NOT NULL THEN  'Pallet'
			  ELSE NULL
			  END                     AS "Item",
	  CASE    WHEN d.SD_LINE IS NOT NULL THEN  'Pallet Fee'
			  ELSE NULL
			  END                     AS "Description",
	  CASE    WHEN t.ST_XX_NUM_PALLETS >= 1 THEN  t.ST_XX_NUM_PALLETS
			  ELSE NULL
			  END                     AS "Qty",
	  CASE    WHEN d.SD_LINE IS NOT NULL THEN  '1'
			  ELSE ''
			  END                     AS "UOI",
	  CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN  (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = :cust)
			 ELSE NULL
			 END                      AS "UnitPrice",
	  CASE   WHEN t.ST_XX_NUM_PALLETS >= 1  THEN  (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = :cust)
			 ELSE NULL
			 END                        AS "DExcl",
			 NULL                     AS "OWUnitPrice",
	  CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN  (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = :cust)
			 ELSE NULL
			 END                                            AS "Excl_Total",
	  CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN  (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = :cust)  * 1.1
			 ELSE NULL
			 END                                           AS "DIncl",
	  CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN  (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = :cust)  * 1.1
			 ELSE NULL
			 END                                           AS "Incl_Total",
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
			  NULL AS "Pallet/Shelf Space",
				NULL AS "Locn",
				NULL AS "AvailSOH",
				NULL AS "CountOfStocks"
	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER
			  INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
	WHERE     To_Number(regexp_substr(r.RM_XX_FEE17, '^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0
	AND       s.SH_STATUS <> 3
	AND      (r.RM_PARENT = :cust OR r.RM_CUST = :cust)
	AND       s.SH_ORDER = t.ST_ORDER
	--AND       (ST_XX_NUM_PALLETS >= 1)
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
			  s.SH_CUST_REF

	--HAVING    Sum(s.SH_ORDER) <> 1  --AND  (Select LENGTH(TRIM(TRANSLATE(RM_XX_FEE17, ' +-.123456789', ''))) from RM where RM_CUST = :cust ) IS NULL


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
	  CASE    WHEN t.ST_XX_NUM_CARTONS >= 1 THEN 'Carton Fee is '
			  ELSE NULL
			  END                      AS "FeeType",
	  CASE    WHEN d.SD_LINE IS NOT NULL THEN  'Carton'
			  ELSE NULL
			  END                     AS "Item",
	  CASE    WHEN d.SD_LINE IS NOT NULL THEN  'Carton Fee'
			  ELSE NULL
			  END                     AS "Description",
	  CASE    WHEN t.ST_XX_NUM_CARTONS >= 1 THEN  t.ST_XX_NUM_CARTONS
			  ELSE NULL
			  END                     AS "Qty",
	  CASE    WHEN d.SD_LINE IS NOT NULL THEN  '1'
			  ELSE ''
			  END                     AS "UOI",
	  CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN   (Select To_Number(RM_XX_FEE15) from RM where RM_CUST = :cust)
			 ELSE null
			 END                      AS "UnitPrice",
	  CASE   WHEN t.ST_XX_NUM_CARTONS >= 1  THEN  (Select To_Number(RM_XX_FEE15) from RM where RM_CUST = :cust)
			 ELSE NULL
			 END                        AS "DExcl",
			 NULL                     AS "OWUnitPrice",
	  CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN  (Select To_Number(RM_XX_FEE15) from RM where RM_CUST = :cust)
			 ELSE NULL
			 END                                            AS "Excl_Total",
	  CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN  (Select To_Number(RM_XX_FEE15) from RM where RM_CUST = :cust)  * 1.1
			 ELSE NULL
			 END                                           AS "DIncl",
	  CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN  (Select To_Number(RM_XX_FEE15) from RM where RM_CUST = :cust)  * 1.1
			 ELSE NULL
			 END                                           AS "Incl_Total",
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
			  NULL AS "Pallet/Shelf Space",
				NULL AS "Locn",
				NULL AS "AvailSOH",
				NULL AS "CountOfStocks"
	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER
			  INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
	WHERE     To_Number(regexp_substr(r.RM_XX_FEE15, '^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0
	AND       s.SH_STATUS <> 3
	AND       (r.RM_PARENT = :cust OR r.RM_CUST = :cust)
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
			  s.SH_CUST_REF

			  --,Rate
	--HAVING    Sum(s.SH_ORDER) <> 1  --AND (Select RM_XX_FEE15 from RM where RM_CUST = :cust ) IS NOT null


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
	  CASE    WHEN d.SD_LINE IS NOT NULL THEN  'ShrinkWrap'
			  ELSE NULL
			  END                     AS "Item",
	  CASE    WHEN d.SD_LINE IS NOT NULL THEN  'ShrinkWraping Fee'
			  ELSE NULL
			  END                     AS "Description",
	  CASE    WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  t.ST_XX_NUM_PAL_SW
			  ELSE NULL
			  END                     AS "Qty",
	  CASE    WHEN d.SD_LINE IS NOT NULL THEN  '1'
			  ELSE ''
			  END                     AS "UOI",
	  CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN   (Select To_Number(RM_XX_FEE18) from RM where RM_CUST = :cust)
			 ELSE null
			 END                      AS "UnitPrice",
	  CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1  THEN  (Select To_Number(RM_XX_FEE18) from RM where RM_CUST = :cust)
			 ELSE NULL
			 END                        AS "DExcl",
			 NULL                     AS "OWUnitPrice",
	  CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN   (Select To_Number(RM_XX_FEE18) from RM where RM_CUST = :cust)
			 ELSE NULL
			 END                                            AS "Excl_Total",
	  CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN   (Select To_Number(RM_XX_FEE18) from RM where RM_CUST = :cust)  * 1.1
			 ELSE NULL
			 END                                           AS "DIncl",
	  CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  (Select To_Number(RM_XX_FEE18) from RM where RM_CUST = :cust)  * 1.1
			 ELSE NULL
			 END                                           AS "Incl_Total",
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
			  NULL AS "Pallet/Shelf Space",
				NULL AS "Locn",
				NULL AS "AvailSOH",
				NULL AS "CountOfStocks"
	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER
			  INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
	WHERE     To_Number(regexp_substr(r.RM_XX_FEE18, '^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0
	AND       s.SH_STATUS <> 3
	AND       (r.RM_PARENT = :cust OR r.RM_CUST = :cust)
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
			  s.SH_CUST_REF

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
			  NULL                     AS "DespatchDate",
	  CASE    WHEN NE_ENTRY IS NOT NULL THEN 'Pallet In Fee '
			  ELSE ''
			  END                      AS "FeeType",
			  IM_STOCK               AS "Item",
			  IM_DESC                AS "Description",
	  CASE    WHEN NE_ENTRY IS NOT NULL THEN  1
			  ELSE NULL
			  END                     AS "Qty",
	  CASE    WHEN NE_ENTRY IS NOT NULL THEN  '1'
			  ELSE ''
			  END                     AS "UOI",
	  CASE    WHEN NE_ENTRY IS NOT NULL THEN  (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "UnitPrice",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN   (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "DExcl",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN   (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "OWUnitPrice",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN   (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "Excl_Total",
		CASE    WHEN NE_ENTRY IS NOT NULL THEN   (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust) * 1.1
			  ELSE NULL
			  END                      AS "DIncl",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN  (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust) * 1.1
			  ELSE NULL
			  END                      AS "Incl_Total",
			  NULL                     AS "ReportingPrice",
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
			  NULL AS "Pallet/Shelf Space",
				IL_LOCN AS "Locn",
				NULL AS "AvailSOH",
				NULL AS "CountOfStocks"
	FROM      PWIN175.IM
			  INNER JOIN PWIN175.NA  ON NA_STOCK = IM_STOCK
			  INNER JOIN PWIN175.IL  ON IL_UID = NA_EXT_KEY
			  INNER JOIN PWIN175.NE  ON NE_ACCOUNT  = NA_ACCOUNT
			  INNER JOIN PWIN175.NI  ON NI_ENTRY = NE_ENTRY
			  INNER JOIN PWIN175.RM  ON RM_CUST  = IM_CUST
	WHERE     To_Number(regexp_substr(RM_XX_FEE14, '^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0
	AND     IM_CUST = :cust
	AND       NA_EXT_TYPE = 1210067
	AND       NE_TRAN_TYPE = 1
	--AND       RM_ANAL = :anal
	AND       (NE_STATUS = 1 OR NE_STATUS = 3)
	AND       NE_DATE >= :start_date AND NE_DATE <= :end_date
	AND       IL_NOTE_2 = 'Yes' AND IL_PHYSICAL = 1
	GROUP BY  IM_CUST,
			  IM_XX_COST_CENTRE01,
			  NI_QJ_NUMBER,
			  NE_ENTRY,
			  IM_STOCK,
			  IM_DESC,
			  NE_DATE,
			  RM_PARENT,
			  IL_LOCN



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
			  NULL                     AS "DespatchDate",
	  CASE    WHEN NE_ENTRY IS NOT NULL THEN 'Carton In Fee '
			  ELSE ''
			  END                      AS "FeeType",
			  IM_STOCK               AS "Item",
			  IM_DESC                AS "Description",
	  CASE    WHEN NE_ENTRY IS NOT NULL THEN  1
			  ELSE NULL
			  END                     AS "Qty",
	  CASE    WHEN NE_ENTRY IS NOT NULL THEN  '1'
			  ELSE ''
			  END                     AS "UOI",
	  CASE    WHEN NE_ENTRY IS NOT NULL THEN  (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "UnitPrice",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN   (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "DExcl",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN   (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "OWUnitPrice",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN   (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "Excl_Total",
		CASE    WHEN NE_ENTRY IS NOT NULL THEN   (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = :cust) * 1.1
			  ELSE NULL
			  END                      AS "DIncl",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN  (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = :cust) * 1.1
			  ELSE NULL
			  END                      AS "Incl_Total",
			  NULL                     AS "ReportingPrice",
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
			  NULL AS "Pallet/Shelf Space",
				IL_LOCN AS "Locn",
				NULL AS "AvailSOH",
				NULL AS "CountOfStocks"

	FROM      PWIN175.IM
			  INNER JOIN PWIN175.NA  ON NA_STOCK = IM_STOCK
			  INNER JOIN PWIN175.IL  ON IL_UID = NA_EXT_KEY
			  INNER JOIN PWIN175.NE  ON NE_ACCOUNT  = NA_ACCOUNT
			  INNER JOIN PWIN175.NI  ON NI_ENTRY = NE_ENTRY
			  INNER JOIN PWIN175.RM  ON RM_CUST  = IM_CUST
	WHERE     To_Number(regexp_substr(RM_XX_FEE13, '^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0
	AND     IM_CUST = :cust
	AND       NA_EXT_TYPE = 1210067
	AND       NE_TRAN_TYPE = 1
	--AND       RM_ANAL = :anal
	AND       (NE_STATUS = 1 OR NE_STATUS = 3)
	AND       NE_DATE >= :start_date AND NE_DATE <= :end_date
	AND       IL_NOTE_2 = 'No' AND IL_PHYSICAL = 1
	GROUP BY  IM_CUST,
			  IM_XX_COST_CENTRE01,
			  NI_QJ_NUMBER,
			  NE_ENTRY,
			  IM_STOCK,
			  IM_DESC,
			  NE_DATE,
			  RM_PARENT,
			  IL_LOCN



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
			 CASE    WHEN t.vSLPslip IS NOT NULL THEN  (Select To_Number(RM_XX_FEE16) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "UnitPrice",
		  CASE    WHEN t.vSLPslip IS NOT NULL THEN   (Select To_Number(RM_XX_FEE16) from RM where RM_CUST = :cust) * t.nCountOfLines
				  ELSE NULL
				  END                      AS "DExcl",
				NULL                AS "OWUnitPrice",
				NULL           AS "Excl_Total",
		  CASE    WHEN t.vSLPslip IS NOT NULL THEN  ((Select To_Number(RM_XX_FEE16) from RM where RM_CUST = :cust) * t.nCountOfLines) * 1.1
				  ELSE NULL
				  END                      AS "DIncl",
		  CASE    WHEN t.vSLPslip IS NOT NULL THEN   ((Select To_Number(RM_XX_FEE16) from RM where RM_CUST = :cust) * t.nCountOfLines)  * 1.1
				  ELSE NULL
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
			  NULL                     AS "AvailSOH",
			  NULL                     AS "CountOfStocks"
	FROM  Tmp_Admin_Data_Pick_LineCounts t LEFT JOIN PWIN175.SH s ON  LTrim(s.SH_ORDER) = t.vSLOrderNum
	INNER JOIN RM r ON r.RM_CUST = s.SH_CUST
	WHERE     To_Number(regexp_substr(r.RM_XX_FEE16, '^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0
	AND  s.SH_STATUS <> 3
  AND (r.RM_PARENT = :cust OR r.RM_CUST = :cust)

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
			  s.SH_CUST_REF






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
	  CASE    WHEN t.vSLPslip IS NOT NULL THEN  (Select To_Number(RM_XX_FEE06) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "UnitPrice",
	  CASE    WHEN t.vSLPslip IS NOT NULL THEN   (Select To_Number(RM_XX_FEE06) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "DExcl",
			 NULL                AS "OWUnitPrice",
			 NULL           AS "Excl_Total",
	  CASE    WHEN t.vSLPslip IS NOT NULL THEN  (Select To_Number(RM_XX_FEE06) from RM where RM_CUST = :cust) * 1.1
			  ELSE NULL
			  END                      AS "DIncl",
	   CASE    WHEN t.vSLPslip IS NOT NULL THEN   (Select To_Number(RM_XX_FEE06) from RM where RM_CUST = :cust)  * 1.1
			  ELSE NULL
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
			NULL AS "Pallet/Shelf Space", /*Pallet/Space*/
				NULL AS "Locn", /*Locn*/
				NULL AS "AvailSOH",/*Avail SOH*/
				NULL AS "CountOfStocks"


	FROM  Tmp_Admin_Data_Pick_LineCounts t LEFT JOIN PWIN175.SH s ON  LTrim(s.SH_ORDER) = t.vSLOrderNum
	INNER JOIN RM r ON r.RM_CUST = s.SH_CUST
		WHERE     To_Number(regexp_substr(r.RM_XX_FEE06, '^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0
	AND  s.SH_STATUS <> 3
  AND (r.RM_PARENT = :cust OR r.RM_CUST = :cust)

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
			  s.SH_CUST_REF

	--HAVING    Sum(s.SH_ORDER) <> 1





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
			  d.SD_QTY_DESP           AS "Qty",
			  d.SD_QTY_UNIT            AS "UOI",
			  /* We need to get a 3 tiered looup for the stockunit prices, fist get th eprice from thE BATCH if company owned otherwise get the unit price from the sd sell price otherwise get it from the ow xx */
	   CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN d.SD_SELL_PRICE --customer owned
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1  AND (SELECT (NX_SELL_VALUE/NX_QUANTITY)
																								                                          FROM PWIN175.NE INNER JOIN NX ON NX_ENTRY = NE_ENTRY
																								                                          WHERE NE_NV_EXT_TYPE = 1810105 AND NE_STRENGTH = 3 AND NE_NV_EXT_KEY = (SELECT SL_UID FROM SL WHERE LTrim(SL_PICK) = t.ST_PICK AND SL_ORDER_LINE  = d.SD_LINE)
																								                                          AND NE_DATE = t.ST_DESP_DATE AND NE_STOCK = d.SD_STOCK) > 0 THEN (SELECT (NX_SELL_VALUE/NX_QUANTITY)
																								                                                                                                            FROM PWIN175.NE INNER JOIN NX ON NX_ENTRY = NE_ENTRY
																								                                                                                                            WHERE NE_NV_EXT_TYPE = 1810105 AND NE_STRENGTH = 3 AND NE_NV_EXT_KEY = (SELECT SL_UID FROM SL WHERE LTrim(SL_PICK) = t.ST_PICK AND SL_ORDER_LINE  = d.SD_LINE)
																								                                                                                                            AND NE_DATE = t.ST_DESP_DATE AND NE_STOCK = d.SD_STOCK)
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NOT NULL THEN  (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			      ELSE NULL
			      END                        AS "UnitPrice",
     CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN d.SD_SELL_PRICE * d.SD_QTY_DESP--customer owned
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1  AND (SELECT NX_SELL_VALUE
																								                                                FROM PWIN175.NE INNER JOIN NX ON NX_ENTRY = NE_ENTRY
																								                                                WHERE NE_NV_EXT_TYPE = 1810105 AND NE_STRENGTH = 3 AND NE_NV_EXT_KEY = (SELECT SL_UID FROM SL WHERE LTrim(SL_PICK) = t.ST_PICK AND SL_ORDER_LINE  = d.SD_LINE)
																								                                                AND NE_DATE = t.ST_DESP_DATE AND NE_STOCK = d.SD_STOCK) > 0 THEN  (SELECT NX_SELL_VALUE
																								                                                                                                                  FROM PWIN175.NE INNER JOIN NX ON NX_ENTRY = NE_ENTRY
																								                                                                                                                  WHERE NE_NV_EXT_TYPE = 1810105 AND NE_STRENGTH = 3 AND NE_NV_EXT_KEY = (SELECT SL_UID FROM SL WHERE LTrim(SL_PICK) = t.ST_PICK AND SL_ORDER_LINE  = d.SD_LINE)
																								                                                                                                                  AND NE_DATE = t.ST_DESP_DATE AND NE_STOCK = d.SD_STOCK) * d.SD_QTY_DESP
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NOT NULL THEN  (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) * d.SD_QTY_DESP
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE * d.SD_QTY_DESP
			      ELSE NULL
			      END          AS "DExcl",
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
	   CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN To_Number(i.IM_REPORTING_PRICE)
			  WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN  (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
			  WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			  ELSE NULL
			  END                       AS "Excl_Total",
	  CASE     WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN (d.SD_SELL_PRICE * d.SD_QTY_DESP) * 1.1--customer owned
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1  AND (SELECT NX_SELL_VALUE
																								                                                FROM PWIN175.NE INNER JOIN NX ON NX_ENTRY = NE_ENTRY
																								                                                WHERE NE_NV_EXT_TYPE = 1810105 AND NE_STRENGTH = 3 AND NE_NV_EXT_KEY = (SELECT SL_UID FROM SL WHERE LTrim(SL_PICK) = t.ST_PICK AND SL_ORDER_LINE  = d.SD_LINE)
																								                                                AND NE_DATE = t.ST_DESP_DATE AND NE_STOCK = d.SD_STOCK) > 0 THEN  ((SELECT NX_SELL_VALUE
																								                                                                                                                  FROM PWIN175.NE INNER JOIN NX ON NX_ENTRY = NE_ENTRY
																								                                                                                                                  WHERE NE_NV_EXT_TYPE = 1810105 AND NE_STRENGTH = 3 AND NE_NV_EXT_KEY = (SELECT SL_UID FROM SL WHERE LTrim(SL_PICK) = t.ST_PICK AND SL_ORDER_LINE  = d.SD_LINE)
																								                                                                                                                  AND NE_DATE = t.ST_DESP_DATE AND NE_STOCK = d.SD_STOCK) * d.SD_QTY_DESP) * 1.1
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NOT NULL THEN  ((SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) * d.SD_QTY_DESP) * 1.1
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  (d.SD_XX_OW_UNIT_PRICE * d.SD_QTY_DESP) * 1.1
			      ELSE NULL
			      END          AS "DIncl",
	   CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN (d.SD_SELL_PRICE * d.SD_QTY_DESP) * 1.1--customer owned
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1  AND (SELECT NX_SELL_VALUE
																								                                                FROM PWIN175.NE INNER JOIN NX ON NX_ENTRY = NE_ENTRY
																								                                                WHERE NE_NV_EXT_TYPE = 1810105 AND NE_STRENGTH = 3 AND NE_NV_EXT_KEY = (SELECT SL_UID FROM SL WHERE LTrim(SL_PICK) = t.ST_PICK AND SL_ORDER_LINE  = d.SD_LINE)
																								                                                AND NE_DATE = t.ST_DESP_DATE AND NE_STOCK = d.SD_STOCK) > 0 THEN  ((SELECT NX_SELL_VALUE
																								                                                                                                                  FROM PWIN175.NE INNER JOIN NX ON NX_ENTRY = NE_ENTRY
																								                                                                                                                  WHERE NE_NV_EXT_TYPE = 1810105 AND NE_STRENGTH = 3 AND NE_NV_EXT_KEY = (SELECT SL_UID FROM SL WHERE LTrim(SL_PICK) = t.ST_PICK AND SL_ORDER_LINE  = d.SD_LINE)
																								                                                                                                                  AND NE_DATE = t.ST_DESP_DATE AND NE_STOCK = d.SD_STOCK) * d.SD_QTY_DESP) * 1.1
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NOT NULL THEN  ((SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) * d.SD_QTY_DESP) * 1.1
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  (d.SD_XX_OW_UNIT_PRICE * d.SD_QTY_DESP) * 1.1
			      ELSE NULL
			      END          AS "Incl_Total",
	  CASE    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN To_Number(i.IM_REPORTING_PRICE)
			  WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN  (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
			  WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
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
				NULL AS "AvailSOH",/*Avail SOH*/
				NULL AS "CountOfStocks"

	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER
			  INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
	WHERE     s.SH_STATUS <> 3
  AND (r.RM_PARENT = :cust OR r.RM_CUST = :cust)
	AND       s.SH_ORDER = t.ST_ORDER
	AND       d.SD_STOCK NOT LIKE 'COURIER'
	AND       d.SD_STOCK NOT LIKE 'FEE*'
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
			  s.SH_CUST_REF,
			  d.SD_SELL_PRICE,
			  i.IM_OWNED_BY,
			  d.SD_QTY_DESP

	--HAVING    Sum(s.SH_ORDER) <> 1



	UNION ALL
/*Stocks*/

/* EOM Storage Fees */
	select IM_CUST AS "Customer",
	  IM_CUST AS "Parent",
	  IM_XX_COST_CENTRE01     AS "CostCentre",
	  NULL               AS "Order",
	  NULL               AS "OrderwareNum",
	  NULL               AS "CustomerRef",
	  NULL                AS "Pickslip",
	  NULL                AS "PickNum",
	  NULL               AS "DespatchNote",
	  (select SubStr(To_Char(last_day(SYSDATE)),0,10) from dual) AS "DespatchDate", /*Made Date*/
		CASE /*Fee Type*/
			WHEN (l1.IL_NOTE_2 like 'Yes'
				OR l1.IL_NOTE_2 LIKE 'YES'
				OR l1.IL_NOTE_2 LIKE 'yes')
			THEN 'FEEPALLETS'
			ELSE 'FEESHELFS'
			END AS "FeeType",
		n1.NI_STOCK AS "Item",
		CASE /*explanation of charge*/
			WHEN (l1.IL_NOTE_2 like 'Yes'	OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN 'Pallet Space Utilisation Fee (per month) is split across ' ||
				((SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
				FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
				INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
				WHERE Stock.IM_CUST = :cust
		    AND Stock.IM_ACTIVE = 1
				AND NView.NI_AVAIL_ACTUAL >= '1'
				AND NView.NI_STATUS <> 0
				AND Locations.IL_LOCN = n1.NI_LOCN)) || ' stock(s)'
			ELSE 'Shelf Utilisation Fee is split across ' ||
				((SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
				FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
				INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
				WHERE Stock.IM_CUST = :cust
		    AND Stock.IM_ACTIVE = 1
				AND NView.NI_AVAIL_ACTUAL >= '1'
				AND NView.NI_STATUS <> 0
				AND Locations.IL_LOCN = n1.NI_LOCN))  || ' stock(s)'
			END AS "Description",
	  IM_LEVEL_UNIT AS "UOI", /*UOI*/
	   CASE   WHEN l1.IL_NOTE_2 IS NOT NULL THEN  1
			  ELSE NULL
			  END                     AS "Qty",
		 CASE  /*unit price*/
			WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN
				((Select To_Number(RM_XX_FEE11)
				  FROM RM
				  WHERE RM_CUST = :cust)
				/
				(SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
				FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
				INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
				WHERE Stock.IM_CUST = :cust
		    AND Stock.IM_ACTIVE = 1
				AND NView.NI_AVAIL_ACTUAL >= '1'
				AND NView.NI_STATUS <> 0
				AND Locations.IL_LOCN = n1.NI_LOCN))
			ELSE
				((Select To_Number(RM_XX_FEE12)
				  FROM RM
				  WHERE RM_CUST = :cust)
        /
				(SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
				FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
				INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
				WHERE Stock.IM_CUST = :cust
		    AND Stock.IM_ACTIVE = 1
				AND NView.NI_AVAIL_ACTUAL >= '1'
				AND NView.NI_STATUS <> 0
				AND Locations.IL_LOCN = n1.NI_LOCN))
			END AS "UnitPrice",
		  CASE WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN
				((Select To_Number(RM_XX_FEE11)
				  FROM RM
				  WHERE RM_CUST = :cust)
				/
				(SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
				FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
				INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
				WHERE Stock.IM_CUST = :cust
		    AND Stock.IM_ACTIVE = 1
				AND NView.NI_AVAIL_ACTUAL >= '1'
				AND NView.NI_STATUS <> 0
				AND Locations.IL_LOCN = n1.NI_LOCN))
			ELSE
				((Select To_Number(RM_XX_FEE12)
				  FROM RM
				  WHERE RM_CUST = :cust)
        /
				(SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
				FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
				INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
			  WHERE Stock.IM_CUST = :cust
		    AND Stock.IM_ACTIVE = 1
				AND NView.NI_AVAIL_ACTUAL >= '1'
				AND NView.NI_STATUS <> 0
				AND Locations.IL_LOCN = n1.NI_LOCN))
			END AS "DExcl",
			CASE  /*unit price*/
			WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN
				((Select To_Number(RM_XX_FEE11)
				  FROM RM
				  WHERE RM_CUST = :cust)
				/
				(SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
				FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
				INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
				WHERE Stock.IM_CUST = :cust
		    AND Stock.IM_ACTIVE = 1
				AND NView.NI_AVAIL_ACTUAL >= '1'
				AND NView.NI_STATUS <> 0
				AND Locations.IL_LOCN = n1.NI_LOCN))
			ELSE
				((Select To_Number(RM_XX_FEE12)
				  FROM RM
				  WHERE RM_CUST = :cust)
        /
				(SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
				FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
				INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
				WHERE Stock.IM_CUST = :cust
		    AND Stock.IM_ACTIVE = 1
				AND NView.NI_AVAIL_ACTUAL >= '1'
				AND NView.NI_STATUS <> 0
				AND Locations.IL_LOCN = n1.NI_LOCN))
			END                 AS "OWUnitPrice",
			CASE  /*unit price*/
			WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN
				((Select To_Number(RM_XX_FEE11)
				  FROM RM
				  WHERE RM_CUST = :cust)
				/
				(SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
				FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
				INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
				WHERE Stock.IM_CUST = :cust
		    AND Stock.IM_ACTIVE = 1
				AND NView.NI_AVAIL_ACTUAL >= '1'
				AND NView.NI_STATUS <> 0
				AND Locations.IL_LOCN = n1.NI_LOCN))
			ELSE
				((Select To_Number(RM_XX_FEE12)
				  FROM RM
				  WHERE RM_CUST = :cust)
        /
				(SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
				FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
				INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
				WHERE Stock.IM_CUST = :cust
		    AND Stock.IM_ACTIVE = 1
				AND NView.NI_AVAIL_ACTUAL >= '1'
				AND NView.NI_STATUS <> 0
				AND Locations.IL_LOCN = n1.NI_LOCN))
			END                AS "Excl_Total",
		 CASE WHEN (l1.IL_NOTE_2 like 'Yes'  OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN
				(
        (( Select TO_NUMBER(RM_XX_FEE11)
				    FROM RM
				    WHERE RM_CUST = :cust)
				/
				(SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
				FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
				INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
				WHERE Stock.IM_CUST = :cust
		    AND Stock.IM_ACTIVE = 1
				AND NView.NI_AVAIL_ACTUAL >= '1'
				AND NView.NI_STATUS <> 0
				AND Locations.IL_LOCN = n1.NI_LOCN))
         * 1.1 )
			ELSE
				(
        ((Select TO_NUMBER(RM_XX_FEE12)
				  FROM RM
				  WHERE RM_CUST = :cust)
				/
				(SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
				FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
				INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
				WHERE Stock.IM_CUST = :cust
		    AND Stock.IM_ACTIVE = 1
				AND NView.NI_AVAIL_ACTUAL >= '1'
				AND NView.NI_STATUS <> 0
				AND Locations.IL_LOCN = n1.NI_LOCN))
        * 1.1 )
			END AS "DIncl",
			 CASE WHEN (l1.IL_NOTE_2 like 'Yes'  OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN
				(
        (( Select TO_NUMBER(RM_XX_FEE11)
				    FROM RM
				    WHERE RM_CUST = :cust)
				/
				(SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
				FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
				INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
				WHERE Stock.IM_CUST = :cust
		    AND Stock.IM_ACTIVE = 1
				AND NView.NI_AVAIL_ACTUAL >= '1'
				AND NView.NI_STATUS <> 0
				AND Locations.IL_LOCN = n1.NI_LOCN))
         * 1.1 )
			ELSE
				(
        ((Select TO_NUMBER(RM_XX_FEE12)
				  FROM RM
				  WHERE RM_CUST = :cust)
				/
				(SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
				FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
				INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
				WHERE Stock.IM_CUST = :cust
		    AND Stock.IM_ACTIVE = 1
				AND NView.NI_AVAIL_ACTUAL >= '1'
				AND NView.NI_STATUS <> 0
				AND Locations.IL_LOCN = n1.NI_LOCN))
        * 1.1 )
			END AS "Incl_Total",
	   CASE    WHEN l1.IL_LOCN IS NOT NULL THEN (Select To_Number(i.IM_REPORTING_PRICE) from IM i where i.IM_STOCK = 'COURIERM')
			  ELSE NULL
			  END                      AS "ReportingPrice",
			  NULL             AS "Address",
			  NULL              AS "Address2",
			  NULL                AS "Suburb",
			  NULL               AS "State",
			  NULL           AS "Postcode",
			  NULL              AS "DeliverTo",
			  NULL              AS "AttentionTo" ,
			  NULL              AS "Weight",
			  NULL            AS "Packages",
			  NULL         AS "OrderSource",
	  l1.IL_NOTE_2 AS "Pallet/Space", /*Pallet/Space*/
		n1.NI_LOCN AS "Locn", /*Locn*/
		n1.NI_AVAIL_ACTUAL AS "Avail SOH",/*Avail SOH*/
		(SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
		FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
			INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
		WHERE Stock.IM_CUST = :cust
			AND NView.NI_AVAIL_ACTUAL >= '1'
			AND NView.NI_STATUS <> 0
			AND Locations.IL_LOCN = n1.NI_LOCN
		)  CountCustStocks
	FROM NI n1 INNER JOIN IM ON IM_STOCK = n1.NI_STOCK
	INNER JOIN IL l1 ON l1.IL_LOCN = n1.NI_LOCN
	WHERE IM_CUST = :cust
		  AND IM_ACTIVE = 1
				--AND IM_CUST = :cust
	AND n1.NI_AVAIL_ACTUAL >= '1'
	AND n1.NI_STATUS <> 0
	GROUP BY IM_CUST,IM_XX_COST_CENTRE01,n1.NI_LOCN,n1.NI_AVAIL_ACTUAL,5,6,n1.NI_STOCK,8,9,10,11,12,l1.IL_NOTE_2,n1.NI_MADE_DATE,IM_LEVEL_UNIT,l1.IL_LOCN





	UNION ALL
/* EOM Storage Fees */

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
        '1'           AS "UOI",
	  (SELECT Count(RD_CODE) FROM PWIN175.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN175.RM WHERE (RM_PARENT = :cust) AND SubStr(RD_CODE,0,2) NOT LIKE 'WH'  AND RD_CODE <> 'DIRECT'))  AS "Qty",
	  (Select To_Number(RM_XX_FEE21) from RM where RM_CUST = :cust)          AS "UnitPrice",
	  (Select To_Number(RM_XX_FEE21) from RM where RM_CUST = :cust) * (SELECT Count(RD_CODE) FROM PWIN175.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN175.RM WHERE (RM_PARENT = :cust) AND SubStr(RD_CODE,0,2) NOT LIKE 'WH'  AND RD_CODE <> 'DIRECT'))         AS "DExcl",
	  (Select To_Number(RM_XX_FEE21) from RM where RM_CUST = :cust)                    AS "OWUnitPrice",
	  (Select To_Number(RM_XX_FEE21) from RM where RM_CUST = :cust) * (SELECT Count(RD_CODE) FROM PWIN175.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN175.RM WHERE (RM_PARENT = :cust) AND SubStr(RD_CODE,0,2) NOT LIKE 'WH'  AND RD_CODE <> 'DIRECT'))      AS "Excl_Total",
		((Select To_Number(RM_XX_FEE21) from RM where RM_CUST = :cust) * (SELECT Count(RD_CODE) FROM PWIN175.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN175.RM WHERE (RM_PARENT = :cust) AND SubStr(RD_CODE,0,2) NOT LIKE 'WH'  AND RD_CODE <> 'DIRECT'))) * 1.1         AS "DIncl",
	  ((Select To_Number(RM_XX_FEE21) from RM where RM_CUST = :cust) * (SELECT Count(RD_CODE) FROM PWIN175.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN175.RM WHERE (RM_PARENT = :cust) AND SubStr(RD_CODE,0,2) NOT LIKE 'WH'  AND RD_CODE <> 'DIRECT'))) * 1.1        AS "Incl_Total",
		(Select To_Number(RM_XX_FEE21) from RM where RM_CUST = :cust)                     AS "ReportingPrice",
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
			  NULL AS "Pallet/Shelf Space",
				NULL AS "Locn",
				NULL AS "AvailSOH",
				NULL AS "CountOfStocks"

	FROM  PWIN175.RM INNER JOIN RD  ON RD_CUST  = RM_CUST
	WHERE     To_Number(regexp_substr(RM_XX_FEE21, '^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0
	AND     (RM_PARENT = :cust OR RM_CUST = :cust)
  --AND (SELECT Count(RD_CODE) FROM PWIN175.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN175.RM WHERE RM_PARENT = :cust  AND SubStr(RD_CODE,0,2) NOT LIKE 'WH') AND RD_CODE <> 'DIRECT' > 0)
  GROUP BY  RM_CUST,
			  RM_PARENT,
			  RD_CUST,
			  RM_XX_FEE21






	UNION ALL
/*DB Maintenance Fee*/

/*Stock Maint Charges including Stocktake and Kitting*/
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
	  CASE    WHEN RD_CUST IS NOT NULL THEN 'Stock Maint fee '
			  ELSE ''
			  END                      AS "FeeType",
			  'Stock Maint'               AS "Item",
			  'Stock Maint fee '                AS "Description",
        '1'           AS "UOI",
	  (SELECT Count(RD_CODE) FROM PWIN175.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN175.RM WHERE (RM_PARENT = :cust) AND SubStr(RD_CODE,0,2) NOT LIKE 'WH'  AND RD_CODE <> 'DIRECT'))  AS "Qty",
	  (Select To_Number(RM_XX_FEE20) from RM where RM_CUST = :cust)          AS "UnitPrice",
	  (Select To_Number(RM_XX_FEE20) from RM where RM_CUST = :cust) * (SELECT Count(RD_CODE) FROM PWIN175.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN175.RM WHERE (RM_PARENT = :cust) AND SubStr(RD_CODE,0,2) NOT LIKE 'WH'  AND RD_CODE <> 'DIRECT'))         AS "DExcl",
	  (Select To_Number(RM_XX_FEE20) from RM where RM_CUST = :cust)                   AS "OWUnitPrice",
	  (Select To_Number(RM_XX_FEE20) from RM where RM_CUST = :cust) * (SELECT Count(RD_CODE) FROM PWIN175.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN175.RM WHERE (RM_PARENT = :cust) AND SubStr(RD_CODE,0,2) NOT LIKE 'WH'  AND RD_CODE <> 'DIRECT'))      AS "Excl_Total",
		((Select To_Number(RM_XX_FEE20) from RM where RM_CUST = :cust) * (SELECT Count(RD_CODE) FROM PWIN175.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN175.RM WHERE (RM_PARENT = :cust) AND SubStr(RD_CODE,0,2) NOT LIKE 'WH'  AND RD_CODE <> 'DIRECT'))) * 1.1         AS "DIncl",
	  ((Select To_Number(RM_XX_FEE20) from RM where RM_CUST = :cust) * (SELECT Count(RD_CODE) FROM PWIN175.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN175.RM WHERE (RM_PARENT = :cust) AND SubStr(RD_CODE,0,2) NOT LIKE 'WH'  AND RD_CODE <> 'DIRECT'))) * 1.1        AS "Incl_Total",
		(Select To_Number(RM_XX_FEE20) from RM where RM_CUST = :cust)                    AS "ReportingPrice",
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
			  NULL AS "Pallet/Shelf Space",
				NULL AS "Locn",
				NULL AS "AvailSOH",
				NULL AS "CountOfStocks"

	FROM  PWIN175.RM INNER JOIN RD  ON RD_CUST  = RM_CUST
	WHERE     To_Number(regexp_substr(RM_XX_FEE21, '^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0
	AND     (RM_PARENT = :cust OR RM_CUST = :cust)
  --AND (SELECT Count(RD_CODE) FROM PWIN175.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN175.RM WHERE RM_PARENT = :cust  AND SubStr(RD_CODE,0,2) NOT LIKE 'WH') AND RD_CODE <> 'DIRECT' > 0)
  GROUP BY  RM_CUST,
			  RM_PARENT,
			  RD_CUST,
			  RM_XX_FEE20
	UNION ALL

/*Stock Maint Charges including Stocktake and Kitting*/

/*Admin Charges*/
    	SELECT    IM_CUST                AS "Customer",
			  RM_PARENT              AS "Parent",
			  IM_XX_COST_CENTRE01       AS "CostCentre",
			  NULL               AS "Order",
			  NULL         AS "OrderwareNum",
			  NULL            AS "CustomerRef",
			  NULL                     AS "Pickslip",
			  NULL                     AS "PickNum",
			  NULL                     AS "DespatchNote",
			  NULL                     AS "DespatchDate",
	  CASE    WHEN IM_CUST IS NOT NULL THEN 'Admin fee '
			  ELSE ''
			  END                      AS "FeeType",
			  'Admin'                   AS "Item",
			  'Admin fee '                AS "Description",
        '1'           AS "UOI",
	     CASE    WHEN IM_CUST IS NOT NULL THEN 1
			  ELSE NULL
			  END                      AS "Qty",
	  (Select To_Number(RM_XX_FEE19) from RM where RM_CUST = :cust)  AS "UnitPrice",
	  (Select To_Number(RM_XX_FEE19) from RM where RM_CUST = :cust)  AS "DExcl",
	  (Select To_Number(RM_XX_FEE19) from RM where RM_CUST = :cust)  AS "OWUnitPrice",
	  (Select To_Number(RM_XX_FEE19) from RM where RM_CUST = :cust)  AS "Excl_Total",
		((Select To_Number(RM_XX_FEE19) from RM where RM_CUST = :cust)  * 1.1)         AS "DIncl",
	  ((Select To_Number(RM_XX_FEE19) from RM where RM_CUST = :cust) * 1.1)        AS "Incl_Total",
		(Select To_Number(RM_XX_FEE19) from RM where RM_CUST = :cust)                    AS "ReportingPrice",
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
			  NULL AS "Pallet/Shelf Space",
				NULL AS "Locn",
				NULL AS "AvailSOH",
				NULL AS "CountOfStocks"

	FROM  PWIN175.IM INNER JOIN RM  ON RM_CUST  = IM_CUST
	WHERE     To_Number(regexp_substr(RM_XX_FEE20, '^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0
	AND     (RM_PARENT = :cust OR RM_CUST = :cust)
 GROUP BY  RM_CUST,
			  RM_PARENT,
			  RM_XX_FEE19,
        IM_XX_COST_CENTRE01,
        IM_CUST

	UNION ALL

/*Admin Charges*/



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
	  CASE    WHEN d.SD_LINE IS NOT NULL THEN  '1'
			  ELSE NULL
			  END                     AS "Qty",
	  CASE    WHEN d.SD_LINE IS NOT NULL THEN  '1'
			  ELSE NULL
			  END                     AS "UOI",
	  CASE   WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN '' ||  (Select RM_XX_FEE08 from RM where RM_CUST = :cust)
			 WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN '' ||  (Select RM_XX_FEE09 from RM where RM_CUST = :cust)
			 ELSE ''
			 END                      AS "UnitPrice",
	   CASE  WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN '' ||  (Select RM_XX_FEE08 from RM where RM_CUST = :cust)  * d.SD_QTY_DESP
			 WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN '' ||  (Select RM_XX_FEE09 from RM where RM_CUST = :cust)  * d.SD_QTY_DESP
			 ELSE ''
			 END                      AS "DExcl",
			  NULL                    AS "OWUnitPrice",
			  NULL                    AS "Excl_Total",
		CASE WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN '' ||  ((Select RM_XX_FEE08 from RM where RM_CUST = :cust) * d.SD_QTY_DESP) * 1.1
			 WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN '' ||  ((Select RM_XX_FEE09 from RM where RM_CUST = :cust) * d.SD_QTY_DESP) * 1.1
			 ELSE ''
			 END                      AS "DIncl",
		CASE WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN '' ||  ((Select RM_XX_FEE08 from RM where RM_CUST = :cust) * d.SD_QTY_DESP) * 1.1
			 WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN '' ||  ((Select RM_XX_FEE09 from RM where RM_CUST = :cust) * d.SD_QTY_DESP) * 1.1
			 ELSE ''
			 END                      AS "Incl_Total",
	  CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN ''  || (Select i.IM_REPORTING_PRICE from IM i where i.IM_STOCK = d.SD_STOCK)
			  ELSE ''
			  END                      AS "ReportingPrice",
			  s.SH_ADDRESS             AS "Address",
			  s.SH_SUBURB              AS "Address2",
			  s.SH_CITY                AS "Suburb",
			  s.SH_STATE               AS "State",
			  s.SH_POST_CODE           AS "Postcode",
			  s.SH_NOTE_1              AS "DeliverTo",
			  s.SH_NOTE_2              AS "AttentionTo" ,
			  To_Char(t.ST_WEIGHT)              AS "Weight",
			  To_Char(t.ST_PACKAGES)            AS "Packages",
			  To_Char(s.SH_SPARE_DBL_9)         AS "OrderSource",
			  NULL AS "Pallet/Shelf Space", /*Pallet/Space*/
				NULL AS "Locn", /*Locn*/
				NULL AS "AvailSOH",/*Avail SOH*/
				NULL AS "CountOfStocks"


	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER  AND t.ST_PICK = d.SD_LAST_PICK_NUM
			  INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK

	WHERE     Upper(i.IM_XX_QTY_PER_PACK) IN ('INNER','OUTER')
	AND       r.RM_ANAL = :anal
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
			  s.SH_CUST_REF
/*Tabcorp Inner/Outer PackingFee*/


SELECT * FROM Tmp_Admin_Data2
ORDER BY OrderNum,Pickslip Asc