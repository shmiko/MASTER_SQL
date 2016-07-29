--Admin Order Data
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
exec :start_date := To_Date('1-Jul-2013')
var end_date varchar2(20)
exec :end_date := To_Date('30-Jul-2013')





/* Create table to hold II values */
DROP TABLE Tmp_Admin_Data_BreakPrices


CREATE TABLE Tmp_Admin_Data_BreakPrices (vIIStock VARCHAR(30), vIICust VARCHAR(20), vUnitPrice VARCHAR(20))--           AS 'Customer',

INSERT INTO Tmp_Admin_Data_BreakPrices
SELECT II_STOCK,II_CUST,To_Char(TO_NUMBER(II_BREAK_LCL))
FROM II INNER JOIN IM ON IM_STOCK = II_STOCK
WHERE IM_CUST= 'TABCORP'

SELECT * FROM Tmp_Admin_Data_BreakPrices


/*create temp table to hold pickslip numbers*/
DROP TABLE Tmp_Admin_Data_Pickslips


CREATE TABLE Tmp_Admin_Data_Pickslips (vPickslip VARCHAR(200),vPslip VARCHAR(10), vDateDesp VARCHAR(10), vPackages INTEGER, vWeight INTEGER, vST_XX_NUM_PAL_SW VARCHAR(10),vST_XX_NUM_PALLETS VARCHAR(10), vST_XX_NUM_CARTONS VARCHAR(10))--           AS 'Customer',


INSERT INTO Tmp_Admin_Data_Pickslips
SELECT LTrim(ST_PICK),LTrim(ST_PSLIP), substr(To_Char(ST_DESP_DATE),0,10), ST_WEIGHT, ST_PACKAGES,ST_XX_NUM_PAL_SW,ST_XX_NUM_PALLETS,ST_XX_NUM_CARTONS
FROM ST INNER JOIN SH ON SH_ORDER = ST_ORDER
WHERE ST_DESP_DATE >= :start_date AND ST_DESP_DATE <= :end_date
AND ST_PSLIP <> 'CANCELLED'
AND SH_STATUS <> 3

SELECT *
FROM Tmp_Admin_Data_Pickslips


/* Create another temp table to hold this data */
DROP TABLE Tmp_Admin_Data_Pick_LineCounts

CREATE TABLE Tmp_Admin_Data_Pick_LineCounts (  nCountOfLines INTEGER, vSLPickslipNum VARCHAR(10), vSLOrderNum VARCHAR2(10), vSLPslip VARCHAR(10), vDateDespSL VARCHAR(10)
,vPackagesSL INTEGER, vWeightSL INTEGER,vST_XX_NUM_PAL_SW_SL VARCHAR(10),vST_XX_NUM_PALLETS_SL VARCHAR(10), vST_XX_NUM_CARTONS_SL VARCHAR(10))

INSERT INTO Tmp_Admin_Data_Pick_LineCounts
/*Now join to SL and count lines per pick*/
SELECT Count(SL_LINE),LTrim(SL_PICK), LTrim(SL_ORDER), LTrim(SL_PSLIP),TP.vDateDesp, TP.vPackages,TP.vWeight,TP.vST_XX_NUM_PAL_SW,TP.vST_XX_NUM_PALLETS,TP.vST_XX_NUM_CARTONS
FROM Tmp_Admin_Data_Pickslips TP LEFT OUTER JOIN SL ON LTrim(SL_PICK) = TP.vPickslip   WHERE SL_PSLIP <> 'CANCELLED'  GROUP BY SL_PICK,SL_ORDER,SL_PSLIP,TP.vDateDesp,TP.vPackages,TP.vWeight,TP.vST_XX_NUM_PAL_SW,TP.vST_XX_NUM_PALLETS,TP.vST_XX_NUM_CARTONS








/*Drop temp table*/
DROP TABLE Tmp_Admin_Data


/*create temp table*/
CREATE TABLE Tmp_Admin_Data
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
        Qty VARCHAR(255),--                AS "Qty",
        UOI VARCHAR(255),--                AS "UOI",
        UnitPrice VARCHAR(255),--          AS "UnitPrice",
        DExcl VARCHAR(255),--              AS "DExcl",
        OWUnitPrice VARCHAR(255),--        AS "OWUnitPrice",
        Excl_Total VARCHAR(255),--         AS "Excl_Total",
        DIncl VARCHAR(255),--              AS "DIncl",
        Incl_Total VARCHAR(255),--         AS "Incl_Total",
        ReportingPrice VARCHAR(255),--     AS "ReportingPrice",
        Address VARCHAR(255),--            AS "Address",
        Address2 VARCHAR(255),--           AS "Address2",
        Suburb VARCHAR(255),--             AS "Suburb",
        State VARCHAR(255),--              AS "State",
        Postcode VARCHAR(255),--           AS "Postcode",
        DeliverTo VARCHAR(255),--          AS "DeliverTo",
        AttentionTo VARCHAR(255),--        AS "AttentionTo" ,
        Weight VARCHAR(255),--             AS "Weight",
        Packages VARCHAR(255),--           AS "Packages",
        OrderSource VARCHAR(255),--        AS "OrderSource",
        ILNOTE2 VARCHAR(255),--          AS "Palett/Shelf",
        NILOCN VARCHAR(255),--            AS "Location",
        NIAVAILACTUAL VARCHAR(255),--    AS "SOH",
        CountOfStocks VARCHAR(255)     -- AS "Count"


)

DECLARE

BEGIN

   IF :cust = 'LUXOTTICA' THEN
            INSERT into Tmp_Admin_Data(
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
                        DExcl,
                        OWUnitPrice,
                        Excl_Total,
                        DIncl,
                        Incl_Total,
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


            /* get freight fees*/
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
                        ELSE d.SD_DESC
                        END                      AS "FeeType",
                        d.SD_STOCK               AS "Item",
                        d.SD_DESC                AS "Description",
                CASE    WHEN d.SD_LINE IS NOT NULL THEN  1
                        ELSE NULL
                        END                     AS "Qty",
                CASE    WHEN d.SD_LINE IS NOT NULL THEN  '1'
                        ELSE NULL
                        END                     AS "UOI",
                CASE    WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 THEN '' || CAST(d.SD_SELL_PRICE AS VARCHAR(20))
                        ELSE CAST(d.SD_SELL_PRICE AS VARCHAR(20)) --|| (Select RM_XX_FEE16 from RM where RM_CUST = :cust)
                        END                      AS "UnitPrice",
                        CAST(d.SD_EXCL AS VARCHAR(20))                AS "DExcl",
                        CAST(d.SD_XX_OW_UNIT_PRICE AS VARCHAR(20))    AS "OWUnitPrice",
                        CAST(Sum(s.SH_EXCL) AS VARCHAR(20))           AS "Excl_Total",
                        CAST(d.SD_INCL AS VARCHAR(20))                AS "DIncl",
                        CAST(Sum(s.SH_INCL) AS VARCHAR(20))           AS "Incl_Total",
                CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN 'Stock Unit Price is '  || (Select i.IM_REPORTING_PRICE from IM i where i.IM_STOCK = d.SD_STOCK)
                        ELSE d.SD_NOTE_1
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
                        INNER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_PICK))  = LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM))
                        INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
              WHERE     r.RM_ANAL = :anal
              --AND       r.RM_CUST IN ("LUXOTTICA","BRIGHT","BUDGET","OPSM","LAUBMAN","SUNGLASS")
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




            ;

ELSE
        INSERT into Tmp_Admin_Data(
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
                        DExcl,
                        OWUnitPrice,
                        Excl_Total,
                        DIncl,
                        Incl_Total,
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


            /* get freight fees*/
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
                        ELSE d.SD_DESC
                        END                      AS "FeeType",
                        d.SD_STOCK               AS "Item",
                        d.SD_DESC                AS "Description",
                CASE    WHEN d.SD_LINE IS NOT NULL THEN  1
                        ELSE NULL
                        END                     AS "Qty",
                CASE    WHEN d.SD_LINE IS NOT NULL THEN  '1'
                        ELSE NULL
                        END                     AS "UOI",
                CASE    WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 THEN '' || CAST(d.SD_SELL_PRICE AS VARCHAR(20))
                        ELSE CAST(d.SD_SELL_PRICE AS VARCHAR(20)) --|| (Select RM_XX_FEE16 from RM where RM_CUST = :cust)
                        END                      AS "UnitPrice",
                        CAST(d.SD_EXCL AS VARCHAR(20))                AS "DExcl",
                        CAST(d.SD_XX_OW_UNIT_PRICE AS VARCHAR(20))    AS "OWUnitPrice",
                        CAST(Sum(s.SH_EXCL) AS VARCHAR(20))           AS "Excl_Total",
                        CAST(d.SD_INCL AS VARCHAR(20))                AS "DIncl",
                        CAST(Sum(s.SH_INCL) AS VARCHAR(20))           AS "Incl_Total",
                CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN 'Stock Unit Price is '  || (Select i.IM_REPORTING_PRICE from IM i where i.IM_STOCK = d.SD_STOCK)
                        ELSE d.SD_NOTE_1
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
                        INNER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_PICK))  = LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM))
                        INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
              WHERE     r.RM_ANAL = :anal
              AND       r.RM_CUST IN ('LUXOTTICA','BRIGHT','BUDGET','OPSM','LAUBMAN','SUNGLASS')
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




            ;


END IF;

SELECT * FROM Tmp_Admin_Data
ORDER BY OrderNum,Pickslip Asc