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




            UNION ALL




            /*Get PhoneOrderEntryFee*/
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
              CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select rm3.RM_XX_FEE03 from RM rm3 where rm3.RM_CUST = :cust)
                      ELSE ''
                      END                     AS "UnitPrice",
              CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select rm3.RM_XX_FEE03 from RM rm3 where rm3.RM_CUST = :cust)
                      ELSE ''
                      END                     AS "DExcl",
              CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select rm3.RM_XX_FEE03 from RM rm3 where rm3.RM_CUST = :cust)
                      ELSE ''
                      END                     AS "OWUnitPrice",
              CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select rm3.RM_XX_FEE03 from RM rm3 where rm3.RM_CUST = :cust)
                      ELSE ''
                      END                     AS "Excl_Total",
              CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN   TO_CHAR((Select rm3.RM_XX_FEE03 from RM rm3 where rm3.RM_CUST = :cust) * 1.1)
                      ELSE ''
                      END                     AS "DIncl",
              CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  TO_CHAR((Select rm3.RM_XX_FEE03 from RM rm3 where rm3.RM_CUST = :cust) * 1.1)
                      ELSE ''
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
            WHERE        r.RM_ANAL = :anal
            AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
            AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
            AND       s.SH_SPARE_DBL_9 = 1
            AND       d.SD_LINE = 1
            AND       (Select rm3.RM_XX_FEE03 from RM rm3 where rm3.RM_CUST = :cust) <> 0
            AND       (Select rm3.RM_XX_FEE03 from RM rm3 where rm3.RM_CUST = :cust) <> '0'
            AND       (Select rm3.RM_XX_FEE03 from RM rm3 where rm3.RM_CUST = :cust) IS NOT NULL
            AND       (Select rm3.RM_XX_FEE03 from RM rm3 where rm3.RM_CUST = :cust) <> ' '
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



            /*Get EmailOrderEntryFee*/
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
              CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  (Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust)
                      ELSE ''
                      END                     AS "UnitPrice",
              CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  (Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust)
                      ELSE ''
                      END                     AS "DExcl",
              CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  (Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust)
                      ELSE ''
                      END                     AS "OWUnitPrice",
              CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  (Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust)
                      ELSE ''
                      END                     AS "Excl_Total",
              CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN   TO_CHAR((Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust) * 1.1)
                      ELSE ''
                      END                     AS "DIncl",
              CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  TO_CHAR((Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust) * 1.1)
                      ELSE ''
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
            WHERE        r.RM_ANAL = :anal
            AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
            AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
            AND       s.SH_SPARE_DBL_9 = 3
            AND       d.SD_LINE = 1
            AND       (Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust) <> 0
            AND       (Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust) <> '0'
            AND       (Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust) IS NOT NULL
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


            /*Get FaxOrderEntryFee*/
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
              CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust)
                      ELSE ''
                      END                     AS "UnitPrice",
              CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust)
                      ELSE ''
                      END                     AS "DExcl",
              CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust)
                      ELSE ''
                      END                     AS "OWUnitPrice",
              CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust)
                      ELSE ''
                      END                     AS "Excl_Total",
              CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN   TO_CHAR((Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) * 1.1)
                      ELSE ''
                      END                     AS "DIncl",
              CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  TO_CHAR((Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) * 1.1)
                      ELSE ''
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
            WHERE        r.RM_ANAL = :anal
            AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
            AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
            AND       s.SH_SPARE_DBL_9 = 2
            AND       d.SD_LINE = 1
            AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> 0
            AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> '0'
            AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) IS NOT NULL
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



            /*Get VerbalOrderEntryFee*/
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
              CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select rm3.RM_XX_FEE01 from RM rm3 where rm3.RM_CUST = :cust)
                      ELSE ''
                      END                     AS "UnitPrice",
              CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select rm3.RM_XX_FEE01 from RM rm3 where rm3.RM_CUST = :cust)
                      ELSE ''
                      END                     AS "DExcl",
              CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select rm3.RM_XX_FEE01 from RM rm3 where rm3.RM_CUST = :cust)
                      ELSE ''
                      END                     AS "OWUnitPrice",
              CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select rm3.RM_XX_FEE01 from RM rm3 where rm3.RM_CUST = :cust)
                      ELSE ''
                      END                     AS "Excl_Total",
              CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN   TO_CHAR((Select rm3.RM_XX_FEE01 from RM rm3 where rm3.RM_CUST = :cust) * 1.1)
                      ELSE ''
                      END                     AS "DIncl",
              CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  TO_CHAR((Select rm3.RM_XX_FEE01 from RM rm3 where rm3.RM_CUST = :cust) * 1.1)
                      ELSE ''
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
            WHERE        r.RM_ANAL = :anal
            AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
            AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
            AND       s.SH_SPARE_DBL_9 = 4
            AND       d.SD_LINE = 1
            AND       (Select rm3.RM_XX_FEE01 from RM rm3 where rm3.RM_CUST = :cust) <> 0
            AND       (Select rm3.RM_XX_FEE01 from RM rm3 where rm3.RM_CUST = :cust) <> '0'
            AND       (Select rm3.RM_XX_FEE01 from RM rm3 where rm3.RM_CUST = :cust) IS NOT NULL
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


            /*Get BB PackingFee*/
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
                      ELSE NULL
                      END                     AS "UOI",

              CASE    /* Get Packing Fees If stock is of type BB_PACK then charge sRM_XX_FEE08.AsDouble * SL_PSLIP_QTY  */
	                  WHEN i.IM_TYPE = 'BB_PACK'   THEN '' ||  (Select RM_XX_FEE08 from RM where RM_CUST = :cust)
                    ELSE ''
                    END                      AS "UnitPrice",
              CASE    /* Get Packing Fees If stock is of type BB_PACK then charge sRM_XX_FEE08.AsDouble * SL_PSLIP_QTY  */
	                  WHEN i.IM_TYPE = 'BB_PACK'  THEN '' ||  (Select RM_XX_FEE08 from RM where RM_CUST = :cust)
                    ELSE ''
                    END                      AS "DExcl",
                      NULL                    AS "OWUnitPrice",
                      NULL                    AS "Excl_Total",
                CASE    /* Get Packing Fees If stock is of type BB_PACK then charge sRM_XX_FEE08.AsDouble * SL_PSLIP_QTY  */
	                  WHEN i.IM_TYPE = 'BB_PACK'  THEN '' ||  (Select RM_XX_FEE08 from RM where RM_CUST = :cust)   * 1.1
                    ELSE ''
                    END                      AS "DIncl",
                CASE    /* Get Packing Fees If stock is of type BB_PACK then charge sRM_XX_FEE08.AsDouble * SL_PSLIP_QTY  */
	                  WHEN i.IM_TYPE = 'BB_PACK'  THEN '' ||  (Select RM_XX_FEE08 from RM where RM_CUST = :cust)  * 1.1
                    ELSE ''
                    END                      AS "Incl_Total",
              CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN 'Stock Unit Price is '  || (Select i.IM_REPORTING_PRICE from IM i where i.IM_STOCK = d.SD_STOCK)
                      ELSE ''
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
            WHERE     (Select rmP.RM_XX_FEE08
                      from RM rmP
                      where rmP.RM_CUST = :cust
                      AND regexp_like(rmP.RM_XX_FEE08, '[0-9]+\.[0-9]{1,2}')
                      /* AND (rmP.RM_CUST = r.RM_CUST OR rmP.RM_CUST = r.RM_PARENT)*/) > 0
            AND       s.SH_ORDER = d.SD_ORDER
            AND       i.IM_TYPE = 'BB_PACK'
            AND       r.RM_ANAL = :anal
            AND (RM_CUST = 'BEYONDBLUE' OR RM_PARENT = 'BEYONDBLUE')
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





            /*Get Destruction Fee*/
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
                      ELSE NULL
                      END                     AS "UOI",
              CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN '' ||  (Select RM_XX_FEE25 from RM where RM_CUST = :cust)
                    ELSE ''
                    END                      AS "UnitPrice",
              CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN '' ||  (Select RM_XX_FEE25 from RM where RM_CUST = :cust)
                    ELSE ''
                    END                      AS "DExcl",
                    NULL                AS "OWUnitPrice",
                    NULL           AS "Excl_Total",
              CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN '' ||  (Select RM_XX_FEE25 from RM where RM_CUST = :cust) * 1.1
                    ELSE ''
                    END                      AS "DIncl",
              CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN '' ||  (Select RM_XX_FEE25 from RM where RM_CUST = :cust)  * 1.1
                    ELSE ''
                    END                      AS "Incl_Total",
              CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN 'Stock Unit Price is '  || (Select i.IM_REPORTING_PRICE from IM i where i.IM_STOCK = d.SD_STOCK)
                      ELSE ''
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
            WHERE     (Select rmP.RM_XX_FEE18
                      from RM rmP
                      where rmP.RM_CUST = :cust
                      AND regexp_like(rmP.RM_XX_FEE25, '[0-9]+\.[0-9]{1,2}')
                      /*AND (rmP.RM_CUST = r.RM_CUST OR rmP.RM_CUST = r.RM_PARENT)*/) > 0
            AND       s.SH_ORDER = d.SD_ORDER
            AND       (s.SH_NOTE_1 = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE')
            AND       s.SH_STATUS <> 3
            AND       d.SD_LINE = 1
            AND       r.RM_ANAL = :anal
            --AND       r.RM_PARENT = :cust
            --AND       d.SD_STOCK NOT IN ('EMERQSRFEE','COURIER%','FEE%','FEE*','COURIER*','COURIER')
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

            /*Get Emergency Fee*/
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
                      ELSE NULL
                      END                     AS "UOI",
                CASE  WHEN d.SD_STOCK = 'EMERQSRFEE' AND s.SH_CAMPAIGN = 'TABSPEC' THEN '' || CAST(d.SD_SELL_PRICE AS VARCHAR(20))
                      ELSE ''
                      END                      AS "UnitPrice",
                CASE  WHEN d.SD_STOCK = 'EMERQSRFEE' AND s.SH_CAMPAIGN = 'TABSPEC' THEN '' || CAST(d.SD_SELL_PRICE AS VARCHAR(20))
                      ELSE ''
                      END                      AS "DExcl",
                      NULL                     AS "OWUnitPrice",
              CASE   WHEN d.SD_STOCK = 'EMERQSRFEE' AND s.SH_CAMPAIGN = 'TABSPEC' THEN '' || TO_CHAR(Sum(d.SD_SELL_PRICE))
                      ELSE ''
                      END                      AS "Excl_Total",
                CASE  WHEN d.SD_STOCK = 'EMERQSRFEE' AND s.SH_CAMPAIGN = 'TABSPEC' THEN '' || TO_CHAR(d.SD_SELL_PRICE * 1.1)
                      ELSE ''
                      END                      AS "DIncl",
                CASE  WHEN d.SD_STOCK = 'EMERQSRFEE' AND s.SH_CAMPAIGN = 'TABSPEC' THEN '' || TO_CHAR(Sum(d.SD_SELL_PRICE * 1.1))
                      ELSE ''
                      END                      AS "Incl_Total",
              CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN 'Stock Unit Price is '  || (Select i.IM_REPORTING_PRICE from IM i where i.IM_STOCK = d.SD_STOCK)
                      ELSE ''
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
            AND       r.RM_ANAL = :anal
            --AND       s.SH_ORDER = t.ST_ORDER
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

            /*Get Pallet Despatch Fee*/
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
                      ELSE NULL
                      END                     AS "UOI",
              CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN '' ||  (Select RM_XX_FEE17 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE17, '[0-9]+\.[0-9]{1,2}'))
                    ELSE null
                    END                      AS "UnitPrice",
              CASE   WHEN t.ST_XX_NUM_PALLETS >= 1  THEN '' || (Select RM_XX_FEE17 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE17, '[0-9]+\.[0-9]{1,2}')) *  ST_XX_NUM_PALLETS
                    ELSE NULL
                    END                        AS "DExcl",
                    NULL                     AS "OWUnitPrice",
              CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN '' ||  (Select RM_XX_FEE17 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE17, '[0-9]+\.[0-9]{1,2}')) *  ST_XX_NUM_PALLETS
                    ELSE ''
                    END                                            AS "Excl_Total",
              CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN '' ||  ((Select RM_XX_FEE17 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE17, '[0-9]+\.[0-9]{1,2}')) *  ST_XX_NUM_PALLETS) * 1.1
                    ELSE ''
                    END                                           AS "DIncl",
              CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN '' ||  ((Select RM_XX_FEE17 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE17, '[0-9]+\.[0-9]{1,2}')) *  ST_XX_NUM_PALLETS) * 1.1
                    ELSE ''
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
            WHERE     (Select rmP.RM_XX_FEE17
                      from RM rmP
                      where rmP.RM_CUST = :cust
                      AND regexp_like(rmP.RM_XX_FEE17, '[0-9]+\.[0-9]{1,2}')
                      /*AND (rmP.RM_CUST = r.RM_CUST OR rmP.RM_CUST = r.RM_PARENT)*/) > 0
            AND s.SH_ORDER = d.SD_ORDER

            AND       s.SH_STATUS <> 3
            AND       r.RM_ANAL = :anal
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


            /* Select RM_XX_FEE15 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE15, '[0-9]+\.[0-9]{1,2}')   */
            /*Get Carton Despatch Fee*/
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
              CASE    WHEN t.ST_XX_NUM_CARTONS >= 1 THEN  ST_XX_NUM_CARTONS
                      ELSE NULL
                      END                     AS "Qty",
              CASE    WHEN d.SD_LINE IS NOT NULL THEN  '1'
                      ELSE NULL
                      END                     AS "UOI",
              CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN '' ||  (Select RM_XX_FEE15 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE15, '[0-9]+\.[0-9]{1,2}'))
                    ELSE null
                    END                      AS "UnitPrice",
              CASE   WHEN t.ST_XX_NUM_CARTONS >= 1  THEN '' || (Select RM_XX_FEE15 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE15, '[0-9]+\.[0-9]{1,2}')) *  ST_XX_NUM_CARTONS
                    ELSE NULL
                    END                        AS "DExcl",
                    NULL                     AS "OWUnitPrice",
              CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN '' ||  (Select RM_XX_FEE15 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE15, '[0-9]+\.[0-9]{1,2}')) *  ST_XX_NUM_CARTONS
                    ELSE ''
                    END                                            AS "Excl_Total",
              CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN '' ||  ((Select RM_XX_FEE15 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE15, '[0-9]+\.[0-9]{1,2}')) *  ST_XX_NUM_CARTONS) * 1.1
                    ELSE ''
                    END                                           AS "DIncl",
              CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN '' ||  ((Select RM_XX_FEE15 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE15, '[0-9]+\.[0-9]{1,2}')) *  ST_XX_NUM_CARTONS) * 1.1
                    ELSE ''
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
            WHERE     (Select rmP.RM_XX_FEE15
                      from RM rmP
                      where rmP.RM_CUST = :cust
                      AND regexp_like(rmP.RM_XX_FEE15, '[0-9]+\.[0-9]{1,2}')
                      /* AND (rmP.RM_CUST = r.RM_CUST OR rmP.RM_CUST = r.RM_PARENT)*/) > 0
            AND       s.SH_STATUS <> 3
            AND       r.RM_ANAL = :anal
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


            /*Get ShrinkWrap Fee*/
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
              CASE    WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  ST_XX_NUM_PAL_SW
                      ELSE NULL
                      END                     AS "Qty",
              CASE    WHEN d.SD_LINE IS NOT NULL THEN  '1'
                      ELSE NULL
                      END                     AS "UOI",
              CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN '' ||  (Select RM_XX_FEE18 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE18, '[0-9]+\.[0-9]{1,2}'))
                    ELSE null
                    END                      AS "UnitPrice",
              CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1  THEN '' || (Select RM_XX_FEE18 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE18, '[0-9]+\.[0-9]{1,2}')) *  ST_XX_NUM_PAL_SW
                    ELSE NULL
                    END                        AS "DExcl",
                    NULL                     AS "OWUnitPrice",
              CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN '' ||  (Select RM_XX_FEE18 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE18, '[0-9]+\.[0-9]{1,2}')) *  ST_XX_NUM_PAL_SW
                    ELSE ''
                    END                                            AS "Excl_Total",
              CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN '' ||  ((Select RM_XX_FEE18 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE18, '[0-9]+\.[0-9]{1,2}')) *  ST_XX_NUM_PAL_SW) * 1.1
                    ELSE ''
                    END                                           AS "DIncl",
              CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN '' ||  ((Select RM_XX_FEE18 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE18, '[0-9]+\.[0-9]{1,2}')) *  ST_XX_NUM_PAL_SW) * 1.1
                    ELSE ''
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
            WHERE     (Select rmP.RM_XX_FEE18
                      from RM rmP
                      where rmP.RM_CUST = :cust
                      AND regexp_like(rmP.RM_XX_FEE18, '[0-9]+\.[0-9]{1,2}')
                      /*AND (rmP.RM_CUST = r.RM_CUST OR rmP.RM_CUST = r.RM_PARENT)*/) > 0
            AND       s.SH_STATUS <> 3
            AND       r.RM_ANAL = :anal
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


            /* Get Pick Fees  */
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
                      ELSE NULL
                      END                     AS "UOI",
                    CASE    WHEN t.vSLPslip IS NOT NULL THEN '' ||  (Select RM_XX_FEE16 from RM where RM_CUST = :cust)
                      ELSE ''
                      END                      AS "UnitPrice",
                  CASE    WHEN t.vSLPslip IS NOT NULL THEN '' ||  (Select RM_XX_FEE16 from RM where RM_CUST = :cust) * t.nCountOfLines
                          ELSE ''
                          END                      AS "DExcl",
                        NULL                AS "OWUnitPrice",
                        NULL           AS "Excl_Total",
                  CASE    WHEN t.vSLPslip IS NOT NULL THEN '' ||  ((Select RM_XX_FEE16 from RM where RM_CUST = :cust) * t.nCountOfLines) * 1.1
                          ELSE ''
                          END                      AS "DIncl",
                  CASE    WHEN t.vSLPslip IS NOT NULL THEN '' ||  ((Select RM_XX_FEE16 from RM where RM_CUST = :cust) * t.nCountOfLines)  * 1.1
                          ELSE ''
                          END                      AS "Incl_Total",
                  CASE    WHEN t.vSLPslip IS NOT NULL THEN ''  || (Select i.IM_REPORTING_PRICE from IM i where i.IM_STOCK = 'COURIERM')
                          ELSE ''
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
            WHERE  s.SH_STATUS <> 3
            AND SH_CUST IN (SELECT RM_CUST FROM RM WHERE RM_ANAL = :anal)
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


            /*Get Handeling Fee*/
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
                      ELSE NULL
                      END                     AS "UOI",
              CASE    WHEN t.vSLPslip IS NOT NULL THEN '' ||  (Select RM_XX_FEE06 from RM where RM_CUST = :cust)
                      ELSE ''
                      END                      AS "UnitPrice",
              CASE    WHEN t.vSLPslip IS NOT NULL THEN '' ||  (Select RM_XX_FEE06 from RM where RM_CUST = :cust)
                      ELSE ''
                      END                      AS "DExcl",
                    NULL                AS "OWUnitPrice",
                    NULL           AS "Excl_Total",
              CASE    WHEN t.vSLPslip IS NOT NULL THEN '' ||  (Select RM_XX_FEE06 from RM where RM_CUST = :cust) * 1.1
                      ELSE ''
                      END                      AS "DIncl",
              CASE    WHEN t.vSLPslip IS NOT NULL THEN '' ||  (Select RM_XX_FEE06 from RM where RM_CUST = :cust)  * 1.1
                      ELSE ''
                      END                      AS "Incl_Total",
              CASE    WHEN t.vSLPslip IS NOT NULL THEN ''  || (Select i.IM_REPORTING_PRICE from IM i where i.IM_STOCK = 'COURIERM')
                      ELSE ''
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
            WHERE  s.SH_STATUS <> 3
            AND SH_CUST IN (SELECT RM_CUST FROM RM WHERE RM_ANAL = :anal)
            --AND r.RM_ANAL = :anal
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

            /*Get Stock Lines*/




            SELECT    s.SH_CUST                AS "Customer",
                      r.RM_PARENT              AS "Parent",
              CASE    WHEN i.IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
                      WHEN i.IM_CUST = 'TABCORP' THEN IM_XX_COST_CENTRE01
                      ELSE IM_XX_COST_CENTRE01
                      END                      AS "CostCentre",
                      s.SH_ORDER               AS "Order",
                      s.SH_SPARE_STR_5         AS "OrderwareNum",
                      s.SH_CUST_REF            AS "CustomerRef",
                      t.ST_PICK                AS "Pickslip",
                      d.SD_XX_PICKLIST_NUM     AS "PickNum",
                      t.ST_PSLIP               AS "DespatchNote",
                      substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
              CASE    WHEN d.SD_STOCK IS NOT NULL THEN 'Stock'
                      ELSE NULL
                      END                      AS "FeeType",
                      d.SD_STOCK               AS "Item",
                      d.SD_DESC                AS "Description",
                      d.SD_QTY_ORDER           AS "Qty",
                      d.SD_QTY_UNIT            AS "UOI",
              CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN CAST(i.IM_REPORTING_PRICE AS VARCHAR(20))
                      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN ''  || (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
                      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN ''  || d.SD_XX_OW_UNIT_PRICE
                      ELSE ''
                      END                        AS "UnitPrice",
              CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN CAST(i.IM_REPORTING_PRICE AS VARCHAR(20))
                      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN ''  || (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
                      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN ''  || d.SD_XX_OW_UNIT_PRICE
                      ELSE ''
                      END                        AS "DExcl",
              CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN CAST(i.IM_REPORTING_PRICE AS VARCHAR(20))
                      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN ''  || (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
                      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN ''  || d.SD_XX_OW_UNIT_PRICE
                      ELSE ''
                      END                        AS "OWUnitPrice",
              CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN CAST(i.IM_REPORTING_PRICE AS VARCHAR(20))
                      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN ''  || (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
                      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN ''  || d.SD_XX_OW_UNIT_PRICE
                      ELSE ''
                      END                       AS "Excl_Total",
              CASE    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN CAST(i.IM_REPORTING_PRICE AS VARCHAR(20))
                      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN ''  || (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
                      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN ''  || d.SD_XX_OW_UNIT_PRICE
                      ELSE ''
                      END                        AS "DIncl",
              CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN CAST(i.IM_REPORTING_PRICE AS VARCHAR(20))
                      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN ''  || (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
                      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN ''  || d.SD_XX_OW_UNIT_PRICE
                      ELSE ''
                      END                       AS "Incl_Total",
              CASE    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN CAST(i.IM_REPORTING_PRICE AS VARCHAR(20))
                      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN ''  || (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
                      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN ''  || d.SD_XX_OW_UNIT_PRICE
                      ELSE ''
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
            WHERE     IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_PARENT = ' '  AND RM_ANAL = :anal AND RM_TYPE = 0 AND RM_ACTIVE = 1 )
            AND       s.SH_STATUS <> 3
            AND       r.RM_ANAL = :anal
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
                      s.SH_CUST_REF

            --HAVING    Sum(s.SH_ORDER) <> 1



            UNION ALL


            /* Get EOM Storage Fees */
            select IM_CUST AS "Customer",
              (SELECT RM_PARENT FROM RM WHERE RM_CUST = IM_CUST) AS "Parent",
              IM_XX_COST_CENTRE01     AS "CostCentre",
              NULL               AS "Order",
              NULL               AS "OrderwareNum",
              NULL               AS "CustomerRef",
              NULL                AS "Pickslip",
              NULL                AS "PickNum",
              NULL               AS "DespatchNote",
              substr(To_Char(n1.NI_MADE_DATE),0,10) AS "DespatchDate", /*Made Date*/
	            CASE /*Fee Type*/
		            WHEN (l1.IL_NOTE_2 like 'Yes'
			            OR l1.IL_NOTE_2 LIKE 'YES'
			            OR l1.IL_NOTE_2 LIKE 'yes')
		            THEN 'FEEPALLETS'
		            ELSE 'FEESHELFS'
		            END AS "FeeType",
                n1.NI_STOCK AS "Item",
	            CASE /*explanation of charge*/
		            WHEN (l1.IL_NOTE_2 like 'Yes'
			            OR l1.IL_NOTE_2 LIKE 'YES'
			            OR l1.IL_NOTE_2 LIKE 'yes')
		            THEN 'Pallet Space Utilisation Fee (per month) is split across ' ||
			            CAST((SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
			            FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
			            INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
			            WHERE Stock.IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_PARENT = ' '  AND RM_ANAL = :anal AND RM_TYPE = 0 AND RM_ACTIVE = 1 )  AND Stock.IM_ACTIVE = 1
			            AND NView.NI_AVAIL_ACTUAL >= '1'
			            AND NView.NI_STATUS <> 0
			            AND Locations.IL_LOCN = n1.NI_LOCN) AS VARCHAR(20)) || ' stock(s)'
		            ELSE 'Shelf Utilisation Fee is split across ' ||
			            CAST((SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
			            FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
			            INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
			            WHERE Stock.IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_PARENT = ' '  AND RM_ANAL = :anal AND RM_TYPE = 0 AND RM_ACTIVE = 1 )  AND Stock.IM_ACTIVE = 1
			            AND NView.NI_AVAIL_ACTUAL >= '1'
			            AND NView.NI_STATUS <> 0
			            AND Locations.IL_LOCN = n1.NI_LOCN)  AS VARCHAR(20))  || ' stock(s)'
		            END AS "Description",
              CASE   WHEN l1.IL_NOTE_2 IS NOT NULL THEN  1
                      ELSE NULL
                      END                     AS "Qty",
                IM_LEVEL_UNIT AS "UOI", /*UOI*/
              CASE  /*unit price*/
		            WHEN (l1.IL_NOTE_2 like 'Yes'
			            OR l1.IL_NOTE_2 LIKE 'YES'
			            OR l1.IL_NOTE_2 LIKE 'yes')
		            THEN
			            CAST((Select CAST(RM_XX_FEE11 AS decimal(10,5))
			            FROM RM
			            WHERE RM_CUST = :cust)
			            /
			            (SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
			            FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
			            INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
			            WHERE Stock.IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_PARENT = ' '  AND RM_ANAL = :anal AND RM_TYPE = 0 AND RM_ACTIVE = 1 )  AND Stock.IM_ACTIVE = 1
			            AND NView.NI_AVAIL_ACTUAL >= '1'
			            AND NView.NI_STATUS <> 0
			            AND Locations.IL_LOCN = n1.NI_LOCN) AS VARCHAR(20))
		            ELSE
			            CAST((Select CAST(RM_XX_FEE12 AS decimal(10,5))
			            FROM RM
			            WHERE RM_CUST = :cust
			            ) /
			            (
			            SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
			            FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
			            INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
			            WHERE Stock.IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_PARENT = ' '  AND RM_ANAL = :anal AND RM_TYPE = 0 AND RM_ACTIVE = 1 )  AND Stock.IM_ACTIVE = 1
			            AND NView.NI_AVAIL_ACTUAL >= '1'
			            AND NView.NI_STATUS <> 0
			            AND Locations.IL_LOCN = n1.NI_LOCN
			            )AS VARCHAR(20))
		            END AS "UnitPrice",
                CASE WHEN (l1.IL_NOTE_2 like 'Yes'
			            OR l1.IL_NOTE_2 LIKE 'YES'
			            OR l1.IL_NOTE_2 LIKE 'yes')
		            THEN
			            CAST((Select CAST(RM_XX_FEE11 AS decimal(10,5))
			            FROM RM
			            WHERE RM_CUST = :cust)
			            /
			            (SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
			            FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
			            INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
			            WHERE Stock.IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_PARENT = ' '  AND RM_ANAL = :anal AND RM_TYPE = 0 AND RM_ACTIVE = 1 )  AND Stock.IM_ACTIVE = 1
			            AND NView.NI_AVAIL_ACTUAL >= '1'
			            AND NView.NI_STATUS <> 0
			            AND Locations.IL_LOCN = n1.NI_LOCN) AS VARCHAR(20))
		            ELSE
			            CAST((Select CAST(RM_XX_FEE12 AS decimal(10,5))
			            FROM RM
			            WHERE RM_CUST = :cust
			            ) /
			            (
			            SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
			            FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
			            INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
			            WHERE Stock.IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_PARENT = ' '  AND RM_ANAL = :anal AND RM_TYPE = 0 AND RM_ACTIVE = 1 )  AND Stock.IM_ACTIVE = 1
			            AND NView.NI_AVAIL_ACTUAL >= '1'
			            AND NView.NI_STATUS <> 0
			            AND Locations.IL_LOCN = n1.NI_LOCN
			            )AS VARCHAR(20))
		            END AS "DExcl",
                    NULL                AS "OWUnitPrice",
                    NULL           AS "Excl_Total",
                CASE WHEN (l1.IL_NOTE_2 like 'Yes'
			            OR l1.IL_NOTE_2 LIKE 'YES'
			            OR l1.IL_NOTE_2 LIKE 'yes')
		            THEN
			            CAST(((Select CAST(RM_XX_FEE11 AS decimal(10,5))
			            FROM RM
			            WHERE RM_CUST = :cust)
			            /
			            (SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
			            FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
			            INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
			            WHERE Stock.IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_PARENT = ' '  AND RM_ANAL = :anal AND RM_TYPE = 0 AND RM_ACTIVE = 1 ) AND Stock.IM_ACTIVE = 1
			            AND NView.NI_AVAIL_ACTUAL >= '1'
			            AND NView.NI_STATUS <> 0
			            AND Locations.IL_LOCN = n1.NI_LOCN)) * 1.1 AS VARCHAR(20))
		            ELSE
			            CAST((Select CAST(RM_XX_FEE12 AS decimal(10,5))
			            FROM RM
			            WHERE RM_CUST = :cust
			            ) /
			            (
			            SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
			            FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
			            INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
			            WHERE Stock.IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_PARENT = ' '  AND RM_ANAL = :anal AND RM_TYPE = 0 AND RM_ACTIVE = 1 )  AND Stock.IM_ACTIVE = 1
			            AND NView.NI_AVAIL_ACTUAL >= '1'
			            AND NView.NI_STATUS <> 0
			            AND Locations.IL_LOCN = n1.NI_LOCN
			            )AS VARCHAR(20))
		            END AS "DIncl",
                    NULL           AS "Incl_Total",
              CASE    WHEN l1.IL_NOTE_2 IS NOT NULL THEN ''  || (Select i.IM_REPORTING_PRICE from IM i where i.IM_STOCK = 'COURIERM')
                      ELSE ''
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
	            WHERE Stock.IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_PARENT = ' '  AND RM_ANAL = :anal AND RM_TYPE = 0 AND RM_ACTIVE = 1 )  AND Stock.IM_ACTIVE = 1
		            AND NView.NI_AVAIL_ACTUAL >= '1'
		            AND NView.NI_STATUS <> 0
		            AND Locations.IL_LOCN = n1.NI_LOCN
	            )  CountCustStocks
            FROM NI n1 INNER JOIN IM ON IM_STOCK = n1.NI_STOCK
            INNER JOIN IL l1 ON l1.IL_LOCN = n1.NI_LOCN
            WHERE IM_ACTIVE = 1
            AND IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_PARENT = ' '  AND RM_ANAL = :anal AND RM_TYPE = 0 AND RM_ACTIVE = 1 )
            --AND IM_CUST = :cust
            AND n1.NI_AVAIL_ACTUAL >= '1'
            AND n1.NI_STATUS <> 0
            GROUP BY IM_CUST,IM_XX_COST_CENTRE01,n1.NI_LOCN,n1.NI_AVAIL_ACTUAL,5,6,n1.NI_STOCK,8,9,10,11,12,l1.IL_NOTE_2,n1.NI_MADE_DATE,IM_LEVEL_UNIT



            UNION ALL

            /*Get Tabcorp Inner/Outer PackingFee*/
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

            WHERE     (
                        ((Select rmP.RM_XX_FEE08
                        from RM rmP
                        where rmP.RM_CUST = :cust
                        AND regexp_like(rmP.RM_XX_FEE08, '[0-9]+\.[0-9]{1,2}')
                      /* AND (rmP.RM_CUST = r.RM_CUST OR rmP.RM_CUST = r.RM_PARENT)*/) > 0 )
                        OR
                        ((Select rmP.RM_XX_FEE09
                        from RM rmP
                        where rmP.RM_CUST = :cust
                        AND regexp_like(rmP.RM_XX_FEE09, '[0-9]+\.[0-9]{1,2}')
                        /* AND (rmP.RM_CUST = r.RM_CUST OR rmP.RM_CUST = r.RM_PARENT)*/) > 0 )
                        OR
                        ((Select rmP.RM_XX_FEE02
                        from RM rmP
                        where rmP.RM_CUST = :cust
                        AND regexp_like(rmP.RM_XX_FEE02, '[0-9]+\.[0-9]{1,2}')
                        /* AND (rmP.RM_CUST = r.RM_CUST OR rmP.RM_CUST = r.RM_PARENT)*/) > 0 )
                        OR
                        ((Select rmP.RM_XX_FEE01
                        from RM rmP
                        where rmP.RM_CUST = :cust
                        AND regexp_like(rmP.RM_XX_FEE01, '[0-9]+\.[0-9]{1,2}')
                        /* AND (rmP.RM_CUST = r.RM_CUST OR rmP.RM_CUST = r.RM_PARENT)*/) > 0 )
                        )

            AND       s.SH_ORDER = d.SD_ORDER
            AND       Upper(i.IM_XX_QTY_PER_PACK) IN ('INNER','OUTER')
            AND       r.RM_ANAL = '72'
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
                      s.SH_CUST_REF   ;

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




            UNION ALL




            /*Get PhoneOrderEntryFee*/
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
              CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select rm3.RM_XX_FEE03 from RM rm3 where rm3.RM_CUST = :cust)
                      ELSE ''
                      END                     AS "UnitPrice",
              CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select rm3.RM_XX_FEE03 from RM rm3 where rm3.RM_CUST = :cust)
                      ELSE ''
                      END                     AS "DExcl",
              CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select rm3.RM_XX_FEE03 from RM rm3 where rm3.RM_CUST = :cust)
                      ELSE ''
                      END                     AS "OWUnitPrice",
              CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select rm3.RM_XX_FEE03 from RM rm3 where rm3.RM_CUST = :cust)
                      ELSE ''
                      END                     AS "Excl_Total",
              CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN   TO_CHAR((Select rm3.RM_XX_FEE03 from RM rm3 where rm3.RM_CUST = :cust) * 1.1)
                      ELSE ''
                      END                     AS "DIncl",
              CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  TO_CHAR((Select rm3.RM_XX_FEE03 from RM rm3 where rm3.RM_CUST = :cust) * 1.1)
                      ELSE ''
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
            WHERE        r.RM_ANAL = :anal
            AND       r.RM_CUST IN ('LUXOTTICA','BRIGHT','BUDGET','OPSM','LAUBMAN','SUNGLASS')
            AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
            AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
            AND       s.SH_SPARE_DBL_9 = 1
            AND       d.SD_LINE = 1
            AND       (Select rm3.RM_XX_FEE03 from RM rm3 where rm3.RM_CUST = :cust) <> 0
            AND       (Select rm3.RM_XX_FEE03 from RM rm3 where rm3.RM_CUST = :cust) <> '0'
            AND       (Select rm3.RM_XX_FEE03 from RM rm3 where rm3.RM_CUST = :cust) IS NOT NULL
            AND       (Select rm3.RM_XX_FEE03 from RM rm3 where rm3.RM_CUST = :cust) <> ' '
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



            /*Get EmailOrderEntryFee*/
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
              CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  (Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust)
                      ELSE ''
                      END                     AS "UnitPrice",
              CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  (Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust)
                      ELSE ''
                      END                     AS "DExcl",
              CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  (Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust)
                      ELSE ''
                      END                     AS "OWUnitPrice",
              CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  (Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust)
                      ELSE ''
                      END                     AS "Excl_Total",
              CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN   TO_CHAR((Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust) * 1.1)
                      ELSE ''
                      END                     AS "DIncl",
              CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  TO_CHAR((Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust) * 1.1)
                      ELSE ''
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
            WHERE        r.RM_ANAL = :anal
            AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
            AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
            AND       s.SH_SPARE_DBL_9 = 3
            AND       d.SD_LINE = 1
            AND       (Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust) <> 0
            AND       (Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust) <> '0'
            AND       (Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust) IS NOT NULL
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


            /*Get FaxOrderEntryFee*/
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
              CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust)
                      ELSE ''
                      END                     AS "UnitPrice",
              CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust)
                      ELSE ''
                      END                     AS "DExcl",
              CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust)
                      ELSE ''
                      END                     AS "OWUnitPrice",
              CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust)
                      ELSE ''
                      END                     AS "Excl_Total",
              CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN   TO_CHAR((Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) * 1.1)
                      ELSE ''
                      END                     AS "DIncl",
              CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  TO_CHAR((Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) * 1.1)
                      ELSE ''
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
            WHERE        r.RM_ANAL = :anal
            AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
            AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
            AND       s.SH_SPARE_DBL_9 = 2
            AND       d.SD_LINE = 1
            AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> 0
            AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> '0'
            AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) IS NOT NULL
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



            /*Get VerbalOrderEntryFee*/
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
              CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select rm3.RM_XX_FEE01 from RM rm3 where rm3.RM_CUST = :cust)
                      ELSE ''
                      END                     AS "UnitPrice",
              CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select rm3.RM_XX_FEE01 from RM rm3 where rm3.RM_CUST = :cust)
                      ELSE ''
                      END                     AS "DExcl",
              CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select rm3.RM_XX_FEE01 from RM rm3 where rm3.RM_CUST = :cust)
                      ELSE ''
                      END                     AS "OWUnitPrice",
              CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select rm3.RM_XX_FEE01 from RM rm3 where rm3.RM_CUST = :cust)
                      ELSE ''
                      END                     AS "Excl_Total",
              CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN   TO_CHAR((Select rm3.RM_XX_FEE01 from RM rm3 where rm3.RM_CUST = :cust) * 1.1)
                      ELSE ''
                      END                     AS "DIncl",
              CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  TO_CHAR((Select rm3.RM_XX_FEE01 from RM rm3 where rm3.RM_CUST = :cust) * 1.1)
                      ELSE ''
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
            WHERE        r.RM_ANAL = :anal
            AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
            AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
            AND       s.SH_SPARE_DBL_9 = 4
            AND       d.SD_LINE = 1
            AND       (Select rm3.RM_XX_FEE01 from RM rm3 where rm3.RM_CUST = :cust) <> 0
            AND       (Select rm3.RM_XX_FEE01 from RM rm3 where rm3.RM_CUST = :cust) <> '0'
            AND       (Select rm3.RM_XX_FEE01 from RM rm3 where rm3.RM_CUST = :cust) IS NOT NULL
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


            /*Get BB PackingFee*/
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
                      ELSE NULL
                      END                     AS "UOI",

              CASE    /* Get Packing Fees If stock is of type BB_PACK then charge sRM_XX_FEE08.AsDouble * SL_PSLIP_QTY  */
	                  WHEN i.IM_TYPE = 'BB_PACK'   THEN '' ||  (Select RM_XX_FEE08 from RM where RM_CUST = :cust)
                    ELSE ''
                    END                      AS "UnitPrice",
              CASE    /* Get Packing Fees If stock is of type BB_PACK then charge sRM_XX_FEE08.AsDouble * SL_PSLIP_QTY  */
	                  WHEN i.IM_TYPE = 'BB_PACK'  THEN '' ||  (Select RM_XX_FEE08 from RM where RM_CUST = :cust)
                    ELSE ''
                    END                      AS "DExcl",
                      NULL                    AS "OWUnitPrice",
                      NULL                    AS "Excl_Total",
                CASE    /* Get Packing Fees If stock is of type BB_PACK then charge sRM_XX_FEE08.AsDouble * SL_PSLIP_QTY  */
	                  WHEN i.IM_TYPE = 'BB_PACK'  THEN '' ||  (Select RM_XX_FEE08 from RM where RM_CUST = :cust)   * 1.1
                    ELSE ''
                    END                      AS "DIncl",
                CASE    /* Get Packing Fees If stock is of type BB_PACK then charge sRM_XX_FEE08.AsDouble * SL_PSLIP_QTY  */
	                  WHEN i.IM_TYPE = 'BB_PACK'  THEN '' ||  (Select RM_XX_FEE08 from RM where RM_CUST = :cust)  * 1.1
                    ELSE ''
                    END                      AS "Incl_Total",
              CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN 'Stock Unit Price is '  || (Select i.IM_REPORTING_PRICE from IM i where i.IM_STOCK = d.SD_STOCK)
                      ELSE ''
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
            WHERE     (Select rmP.RM_XX_FEE08
                      from RM rmP
                      where rmP.RM_CUST = :cust
                      AND regexp_like(rmP.RM_XX_FEE08, '[0-9]+\.[0-9]{1,2}')
                      /* AND (rmP.RM_CUST = r.RM_CUST OR rmP.RM_CUST = r.RM_PARENT)*/) > 0
            AND       s.SH_ORDER = d.SD_ORDER
            AND       i.IM_TYPE = 'BB_PACK'
            AND       r.RM_ANAL = :anal
            AND (RM_CUST = 'BEYONDBLUE' OR RM_PARENT = 'BEYONDBLUE')
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





            /*Get Destruction Fee*/
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
                      ELSE NULL
                      END                     AS "UOI",
              CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN '' ||  (Select RM_XX_FEE25 from RM where RM_CUST = :cust)
                    ELSE ''
                    END                      AS "UnitPrice",
              CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN '' ||  (Select RM_XX_FEE25 from RM where RM_CUST = :cust)
                    ELSE ''
                    END                      AS "DExcl",
                    NULL                AS "OWUnitPrice",
                    NULL           AS "Excl_Total",
              CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN '' ||  (Select RM_XX_FEE25 from RM where RM_CUST = :cust) * 1.1
                    ELSE ''
                    END                      AS "DIncl",
              CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN '' ||  (Select RM_XX_FEE25 from RM where RM_CUST = :cust)  * 1.1
                    ELSE ''
                    END                      AS "Incl_Total",
              CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN 'Stock Unit Price is '  || (Select i.IM_REPORTING_PRICE from IM i where i.IM_STOCK = d.SD_STOCK)
                      ELSE ''
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
            WHERE     (Select rmP.RM_XX_FEE18
                      from RM rmP
                      where rmP.RM_CUST = :cust
                      AND regexp_like(rmP.RM_XX_FEE25, '[0-9]+\.[0-9]{1,2}')
                      /*AND (rmP.RM_CUST = r.RM_CUST OR rmP.RM_CUST = r.RM_PARENT)*/) > 0
            AND       s.SH_ORDER = d.SD_ORDER
            AND       (s.SH_NOTE_1 = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE')
            AND       s.SH_STATUS <> 3
            AND       d.SD_LINE = 1
            AND       r.RM_ANAL = :anal
            --AND       r.RM_PARENT = :cust
            --AND       d.SD_STOCK NOT IN ('EMERQSRFEE','COURIER%','FEE%','FEE*','COURIER*','COURIER')
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

            /*Get Emergency Fee*/
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
                      ELSE NULL
                      END                     AS "UOI",
                CASE  WHEN d.SD_STOCK = 'EMERQSRFEE' AND s.SH_CAMPAIGN = 'TABSPEC' THEN '' || CAST(d.SD_SELL_PRICE AS VARCHAR(20))
                      ELSE ''
                      END                      AS "UnitPrice",
                CASE  WHEN d.SD_STOCK = 'EMERQSRFEE' AND s.SH_CAMPAIGN = 'TABSPEC' THEN '' || CAST(d.SD_SELL_PRICE AS VARCHAR(20))
                      ELSE ''
                      END                      AS "DExcl",
                      NULL                     AS "OWUnitPrice",
              CASE   WHEN d.SD_STOCK = 'EMERQSRFEE' AND s.SH_CAMPAIGN = 'TABSPEC' THEN '' || TO_CHAR(Sum(d.SD_SELL_PRICE))
                      ELSE ''
                      END                      AS "Excl_Total",
                CASE  WHEN d.SD_STOCK = 'EMERQSRFEE' AND s.SH_CAMPAIGN = 'TABSPEC' THEN '' || TO_CHAR(d.SD_SELL_PRICE * 1.1)
                      ELSE ''
                      END                      AS "DIncl",
                CASE  WHEN d.SD_STOCK = 'EMERQSRFEE' AND s.SH_CAMPAIGN = 'TABSPEC' THEN '' || TO_CHAR(Sum(d.SD_SELL_PRICE * 1.1))
                      ELSE ''
                      END                      AS "Incl_Total",
              CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN 'Stock Unit Price is '  || (Select i.IM_REPORTING_PRICE from IM i where i.IM_STOCK = d.SD_STOCK)
                      ELSE ''
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
            AND       r.RM_ANAL = :anal
            --AND       s.SH_ORDER = t.ST_ORDER
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

            /*Get Pallet Despatch Fee*/
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
                      ELSE NULL
                      END                     AS "UOI",
              CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN '' ||  (Select RM_XX_FEE17 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE17, '[0-9]+\.[0-9]{1,2}'))
                    ELSE null
                    END                      AS "UnitPrice",
              CASE   WHEN t.ST_XX_NUM_PALLETS >= 1  THEN '' || (Select RM_XX_FEE17 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE17, '[0-9]+\.[0-9]{1,2}')) *  ST_XX_NUM_PALLETS
                    ELSE NULL
                    END                        AS "DExcl",
                    NULL                     AS "OWUnitPrice",
              CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN '' ||  (Select RM_XX_FEE17 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE17, '[0-9]+\.[0-9]{1,2}')) *  ST_XX_NUM_PALLETS
                    ELSE ''
                    END                                            AS "Excl_Total",
              CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN '' ||  ((Select RM_XX_FEE17 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE17, '[0-9]+\.[0-9]{1,2}')) *  ST_XX_NUM_PALLETS) * 1.1
                    ELSE ''
                    END                                           AS "DIncl",
              CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN '' ||  ((Select RM_XX_FEE17 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE17, '[0-9]+\.[0-9]{1,2}')) *  ST_XX_NUM_PALLETS) * 1.1
                    ELSE ''
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
            WHERE     (Select rmP.RM_XX_FEE17
                      from RM rmP
                      where rmP.RM_CUST = :cust
                      AND regexp_like(rmP.RM_XX_FEE17, '[0-9]+\.[0-9]{1,2}')
                      /*AND (rmP.RM_CUST = r.RM_CUST OR rmP.RM_CUST = r.RM_PARENT)*/) > 0
            AND s.SH_ORDER = d.SD_ORDER

            AND       s.SH_STATUS <> 3
            AND       r.RM_ANAL = :anal
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


            /* Select RM_XX_FEE15 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE15, '[0-9]+\.[0-9]{1,2}')   */
            /*Get Carton Despatch Fee*/
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
              CASE    WHEN t.ST_XX_NUM_CARTONS >= 1 THEN  ST_XX_NUM_CARTONS
                      ELSE NULL
                      END                     AS "Qty",
              CASE    WHEN d.SD_LINE IS NOT NULL THEN  '1'
                      ELSE NULL
                      END                     AS "UOI",
              CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN '' ||  (Select RM_XX_FEE15 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE15, '[0-9]+\.[0-9]{1,2}'))
                    ELSE null
                    END                      AS "UnitPrice",
              CASE   WHEN t.ST_XX_NUM_CARTONS >= 1  THEN '' || (Select RM_XX_FEE15 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE15, '[0-9]+\.[0-9]{1,2}')) *  ST_XX_NUM_CARTONS
                    ELSE NULL
                    END                        AS "DExcl",
                    NULL                     AS "OWUnitPrice",
              CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN '' ||  (Select RM_XX_FEE15 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE15, '[0-9]+\.[0-9]{1,2}')) *  ST_XX_NUM_CARTONS
                    ELSE ''
                    END                                            AS "Excl_Total",
              CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN '' ||  ((Select RM_XX_FEE15 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE15, '[0-9]+\.[0-9]{1,2}')) *  ST_XX_NUM_CARTONS) * 1.1
                    ELSE ''
                    END                                           AS "DIncl",
              CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN '' ||  ((Select RM_XX_FEE15 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE15, '[0-9]+\.[0-9]{1,2}')) *  ST_XX_NUM_CARTONS) * 1.1
                    ELSE ''
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
            WHERE     (Select rmP.RM_XX_FEE15
                      from RM rmP
                      where rmP.RM_CUST = :cust
                      AND regexp_like(rmP.RM_XX_FEE15, '[0-9]+\.[0-9]{1,2}')
                      /* AND (rmP.RM_CUST = r.RM_CUST OR rmP.RM_CUST = r.RM_PARENT)*/) > 0
            AND       s.SH_STATUS <> 3
            AND       r.RM_ANAL = :anal
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


            /*Get ShrinkWrap Fee*/
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
              CASE    WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  ST_XX_NUM_PAL_SW
                      ELSE NULL
                      END                     AS "Qty",
              CASE    WHEN d.SD_LINE IS NOT NULL THEN  '1'
                      ELSE NULL
                      END                     AS "UOI",
              CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN '' ||  (Select RM_XX_FEE18 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE18, '[0-9]+\.[0-9]{1,2}'))
                    ELSE null
                    END                      AS "UnitPrice",
              CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1  THEN '' || (Select RM_XX_FEE18 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE18, '[0-9]+\.[0-9]{1,2}')) *  ST_XX_NUM_PAL_SW
                    ELSE NULL
                    END                        AS "DExcl",
                    NULL                     AS "OWUnitPrice",
              CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN '' ||  (Select RM_XX_FEE18 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE18, '[0-9]+\.[0-9]{1,2}')) *  ST_XX_NUM_PAL_SW
                    ELSE ''
                    END                                            AS "Excl_Total",
              CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN '' ||  ((Select RM_XX_FEE18 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE18, '[0-9]+\.[0-9]{1,2}')) *  ST_XX_NUM_PAL_SW) * 1.1
                    ELSE ''
                    END                                           AS "DIncl",
              CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN '' ||  ((Select RM_XX_FEE18 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE18, '[0-9]+\.[0-9]{1,2}')) *  ST_XX_NUM_PAL_SW) * 1.1
                    ELSE ''
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
            WHERE     (Select rmP.RM_XX_FEE18
                      from RM rmP
                      where rmP.RM_CUST = :cust
                      AND regexp_like(rmP.RM_XX_FEE18, '[0-9]+\.[0-9]{1,2}')
                      /*AND (rmP.RM_CUST = r.RM_CUST OR rmP.RM_CUST = r.RM_PARENT)*/) > 0
            AND       s.SH_STATUS <> 3
            AND       r.RM_ANAL = :anal
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


            /* Get Pick Fees  */
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
                      ELSE NULL
                      END                     AS "UOI",
                    CASE    WHEN t.vSLPslip IS NOT NULL THEN '' ||  (Select RM_XX_FEE16 from RM where RM_CUST = :cust)
                      ELSE ''
                      END                      AS "UnitPrice",
                  CASE    WHEN t.vSLPslip IS NOT NULL THEN '' ||  (Select RM_XX_FEE16 from RM where RM_CUST = :cust) * t.nCountOfLines
                          ELSE ''
                          END                      AS "DExcl",
                        NULL                AS "OWUnitPrice",
                        NULL           AS "Excl_Total",
                  CASE    WHEN t.vSLPslip IS NOT NULL THEN '' ||  ((Select RM_XX_FEE16 from RM where RM_CUST = :cust) * t.nCountOfLines) * 1.1
                          ELSE ''
                          END                      AS "DIncl",
                  CASE    WHEN t.vSLPslip IS NOT NULL THEN '' ||  ((Select RM_XX_FEE16 from RM where RM_CUST = :cust) * t.nCountOfLines)  * 1.1
                          ELSE ''
                          END                      AS "Incl_Total",
                  CASE    WHEN t.vSLPslip IS NOT NULL THEN ''  || (Select i.IM_REPORTING_PRICE from IM i where i.IM_STOCK = 'COURIERM')
                          ELSE ''
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
            WHERE  s.SH_STATUS <> 3
            AND SH_CUST IN (SELECT RM_CUST FROM RM WHERE RM_ANAL = :anal)
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


            /*Get Handeling Fee*/
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
                      ELSE NULL
                      END                     AS "UOI",
              CASE    WHEN t.vSLPslip IS NOT NULL THEN '' ||  (Select RM_XX_FEE06 from RM where RM_CUST = :cust)
                      ELSE ''
                      END                      AS "UnitPrice",
              CASE    WHEN t.vSLPslip IS NOT NULL THEN '' ||  (Select RM_XX_FEE06 from RM where RM_CUST = :cust)
                      ELSE ''
                      END                      AS "DExcl",
                    NULL                AS "OWUnitPrice",
                    NULL           AS "Excl_Total",
              CASE    WHEN t.vSLPslip IS NOT NULL THEN '' ||  (Select RM_XX_FEE06 from RM where RM_CUST = :cust) * 1.1
                      ELSE ''
                      END                      AS "DIncl",
              CASE    WHEN t.vSLPslip IS NOT NULL THEN '' ||  (Select RM_XX_FEE06 from RM where RM_CUST = :cust)  * 1.1
                      ELSE ''
                      END                      AS "Incl_Total",
              CASE    WHEN t.vSLPslip IS NOT NULL THEN ''  || (Select i.IM_REPORTING_PRICE from IM i where i.IM_STOCK = 'COURIERM')
                      ELSE ''
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
            WHERE  s.SH_STATUS <> 3
            AND SH_CUST IN (SELECT RM_CUST FROM RM WHERE RM_ANAL = :anal)
            --AND r.RM_ANAL = :anal
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

            /*Get Stock Lines*/




            SELECT    s.SH_CUST                AS "Customer",
                      r.RM_PARENT              AS "Parent",
              CASE    WHEN i.IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
                      WHEN i.IM_CUST = 'TABCORP' THEN IM_XX_COST_CENTRE01
                      ELSE IM_XX_COST_CENTRE01
                      END                      AS "CostCentre",
                      s.SH_ORDER               AS "Order",
                      s.SH_SPARE_STR_5         AS "OrderwareNum",
                      s.SH_CUST_REF            AS "CustomerRef",
                      t.ST_PICK                AS "Pickslip",
                      d.SD_XX_PICKLIST_NUM     AS "PickNum",
                      t.ST_PSLIP               AS "DespatchNote",
                      substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
              CASE    WHEN d.SD_STOCK IS NOT NULL THEN 'Stock'
                      ELSE NULL
                      END                      AS "FeeType",
                      d.SD_STOCK               AS "Item",
                      d.SD_DESC                AS "Description",
                      d.SD_QTY_ORDER           AS "Qty",
                      d.SD_QTY_UNIT            AS "UOI",
              CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN CAST(i.IM_REPORTING_PRICE AS VARCHAR(20))
                      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN ''  || (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
                      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN ''  || d.SD_XX_OW_UNIT_PRICE
                      ELSE ''
                      END                        AS "UnitPrice",
              CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN CAST(i.IM_REPORTING_PRICE AS VARCHAR(20))
                      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN ''  || (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
                      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN ''  || d.SD_XX_OW_UNIT_PRICE
                      ELSE ''
                      END                        AS "DExcl",
              CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN CAST(i.IM_REPORTING_PRICE AS VARCHAR(20))
                      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN ''  || (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
                      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN ''  || d.SD_XX_OW_UNIT_PRICE
                      ELSE ''
                      END                        AS "OWUnitPrice",
              CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN CAST(i.IM_REPORTING_PRICE AS VARCHAR(20))
                      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN ''  || (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
                      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN ''  || d.SD_XX_OW_UNIT_PRICE
                      ELSE ''
                      END                       AS "Excl_Total",
              CASE    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN CAST(i.IM_REPORTING_PRICE AS VARCHAR(20))
                      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN ''  || (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
                      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN ''  || d.SD_XX_OW_UNIT_PRICE
                      ELSE ''
                      END                        AS "DIncl",
              CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN CAST(i.IM_REPORTING_PRICE AS VARCHAR(20))
                      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN ''  || (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
                      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN ''  || d.SD_XX_OW_UNIT_PRICE
                      ELSE ''
                      END                       AS "Incl_Total",
              CASE    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN CAST(i.IM_REPORTING_PRICE AS VARCHAR(20))
                      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN ''  || (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
                      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN ''  || d.SD_XX_OW_UNIT_PRICE
                      ELSE ''
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
            WHERE     IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_PARENT = ' '  AND RM_ANAL = :anal AND RM_TYPE = 0 AND RM_ACTIVE = 1 )
            AND       s.SH_STATUS <> 3
            AND       r.RM_ANAL = :anal
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
                      s.SH_CUST_REF

            --HAVING    Sum(s.SH_ORDER) <> 1



            UNION ALL


            /* Get EOM Storage Fees */
            select IM_CUST AS "Customer",
              (SELECT RM_PARENT FROM RM WHERE RM_CUST = IM_CUST) AS "Parent",
              IM_XX_COST_CENTRE01     AS "CostCentre",
              NULL               AS "Order",
              NULL               AS "OrderwareNum",
              NULL               AS "CustomerRef",
              NULL                AS "Pickslip",
              NULL                AS "PickNum",
              NULL               AS "DespatchNote",
              substr(To_Char(n1.NI_MADE_DATE),0,10) AS "DespatchDate", /*Made Date*/
	            CASE /*Fee Type*/
		            WHEN (l1.IL_NOTE_2 like 'Yes'
			            OR l1.IL_NOTE_2 LIKE 'YES'
			            OR l1.IL_NOTE_2 LIKE 'yes')
		            THEN 'FEEPALLETS'
		            ELSE 'FEESHELFS'
		            END AS "FeeType",
                n1.NI_STOCK AS "Item",
	            CASE /*explanation of charge*/
		            WHEN (l1.IL_NOTE_2 like 'Yes'
			            OR l1.IL_NOTE_2 LIKE 'YES'
			            OR l1.IL_NOTE_2 LIKE 'yes')
		            THEN 'Pallet Space Utilisation Fee (per month) is split across ' ||
			            CAST((SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
			            FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
			            INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
			            WHERE Stock.IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_PARENT = ' '  AND RM_ANAL = :anal AND RM_TYPE = 0 AND RM_ACTIVE = 1 )  AND Stock.IM_ACTIVE = 1
			            AND NView.NI_AVAIL_ACTUAL >= '1'
			            AND NView.NI_STATUS <> 0
			            AND Locations.IL_LOCN = n1.NI_LOCN) AS VARCHAR(20)) || ' stock(s)'
		            ELSE 'Shelf Utilisation Fee is split across ' ||
			            CAST((SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
			            FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
			            INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
			            WHERE Stock.IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_PARENT = ' '  AND RM_ANAL = :anal AND RM_TYPE = 0 AND RM_ACTIVE = 1 )  AND Stock.IM_ACTIVE = 1
			            AND NView.NI_AVAIL_ACTUAL >= '1'
			            AND NView.NI_STATUS <> 0
			            AND Locations.IL_LOCN = n1.NI_LOCN)  AS VARCHAR(20))  || ' stock(s)'
		            END AS "Description",
              CASE   WHEN l1.IL_NOTE_2 IS NOT NULL THEN  1
                      ELSE NULL
                      END                     AS "Qty",
                IM_LEVEL_UNIT AS "UOI", /*UOI*/
              CASE  /*unit price*/
		            WHEN (l1.IL_NOTE_2 like 'Yes'
			            OR l1.IL_NOTE_2 LIKE 'YES'
			            OR l1.IL_NOTE_2 LIKE 'yes')
		            THEN
			            CAST((Select CAST(RM_XX_FEE11 AS decimal(10,5))
			            FROM RM
			            WHERE RM_CUST = :cust)
			            /
			            (SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
			            FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
			            INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
			            WHERE Stock.IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_PARENT = ' '  AND RM_ANAL = :anal AND RM_TYPE = 0 AND RM_ACTIVE = 1 )  AND Stock.IM_ACTIVE = 1
			            AND NView.NI_AVAIL_ACTUAL >= '1'
			            AND NView.NI_STATUS <> 0
			            AND Locations.IL_LOCN = n1.NI_LOCN) AS VARCHAR(20))
		            ELSE
			            CAST((Select CAST(RM_XX_FEE12 AS decimal(10,5))
			            FROM RM
			            WHERE RM_CUST = :cust
			            ) /
			            (
			            SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
			            FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
			            INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
			            WHERE Stock.IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_PARENT = ' '  AND RM_ANAL = :anal AND RM_TYPE = 0 AND RM_ACTIVE = 1 )  AND Stock.IM_ACTIVE = 1
			            AND NView.NI_AVAIL_ACTUAL >= '1'
			            AND NView.NI_STATUS <> 0
			            AND Locations.IL_LOCN = n1.NI_LOCN
			            )AS VARCHAR(20))
		            END AS "UnitPrice",
                CASE WHEN (l1.IL_NOTE_2 like 'Yes'
			            OR l1.IL_NOTE_2 LIKE 'YES'
			            OR l1.IL_NOTE_2 LIKE 'yes')
		            THEN
			            CAST((Select CAST(RM_XX_FEE11 AS decimal(10,5))
			            FROM RM
			            WHERE RM_CUST = :cust)
			            /
			            (SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
			            FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
			            INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
			            WHERE Stock.IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_PARENT = ' '  AND RM_ANAL = :anal AND RM_TYPE = 0 AND RM_ACTIVE = 1 )  AND Stock.IM_ACTIVE = 1
			            AND NView.NI_AVAIL_ACTUAL >= '1'
			            AND NView.NI_STATUS <> 0
			            AND Locations.IL_LOCN = n1.NI_LOCN) AS VARCHAR(20))
		            ELSE
			            CAST((Select CAST(RM_XX_FEE12 AS decimal(10,5))
			            FROM RM
			            WHERE RM_CUST = :cust
			            ) /
			            (
			            SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
			            FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
			            INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
			            WHERE Stock.IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_PARENT = ' '  AND RM_ANAL = :anal AND RM_TYPE = 0 AND RM_ACTIVE = 1 )  AND Stock.IM_ACTIVE = 1
			            AND NView.NI_AVAIL_ACTUAL >= '1'
			            AND NView.NI_STATUS <> 0
			            AND Locations.IL_LOCN = n1.NI_LOCN
			            )AS VARCHAR(20))
		            END AS "DExcl",
                    NULL                AS "OWUnitPrice",
                    NULL           AS "Excl_Total",
                CASE WHEN (l1.IL_NOTE_2 like 'Yes'
			            OR l1.IL_NOTE_2 LIKE 'YES'
			            OR l1.IL_NOTE_2 LIKE 'yes')
		            THEN
			            CAST(((Select CAST(RM_XX_FEE11 AS decimal(10,5))
			            FROM RM
			            WHERE RM_CUST = :cust)
			            /
			            (SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
			            FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
			            INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
			            WHERE Stock.IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_PARENT = ' '  AND RM_ANAL = :anal AND RM_TYPE = 0 AND RM_ACTIVE = 1 ) AND Stock.IM_ACTIVE = 1
			            AND NView.NI_AVAIL_ACTUAL >= '1'
			            AND NView.NI_STATUS <> 0
			            AND Locations.IL_LOCN = n1.NI_LOCN)) * 1.1 AS VARCHAR(20))
		            ELSE
			            CAST((Select CAST(RM_XX_FEE12 AS decimal(10,5))
			            FROM RM
			            WHERE RM_CUST = :cust
			            ) /
			            (
			            SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
			            FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
			            INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
			            WHERE Stock.IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_PARENT = ' '  AND RM_ANAL = :anal AND RM_TYPE = 0 AND RM_ACTIVE = 1 )  AND Stock.IM_ACTIVE = 1
			            AND NView.NI_AVAIL_ACTUAL >= '1'
			            AND NView.NI_STATUS <> 0
			            AND Locations.IL_LOCN = n1.NI_LOCN
			            )AS VARCHAR(20))
		            END AS "DIncl",
                    NULL           AS "Incl_Total",
              CASE    WHEN l1.IL_NOTE_2 IS NOT NULL THEN ''  || (Select i.IM_REPORTING_PRICE from IM i where i.IM_STOCK = 'COURIERM')
                      ELSE ''
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
	            WHERE Stock.IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_PARENT = ' '  AND RM_ANAL = :anal AND RM_TYPE = 0 AND RM_ACTIVE = 1 )  AND Stock.IM_ACTIVE = 1
		            AND NView.NI_AVAIL_ACTUAL >= '1'
		            AND NView.NI_STATUS <> 0
		            AND Locations.IL_LOCN = n1.NI_LOCN
	            )  CountCustStocks
            FROM NI n1 INNER JOIN IM ON IM_STOCK = n1.NI_STOCK
            INNER JOIN IL l1 ON l1.IL_LOCN = n1.NI_LOCN
            WHERE IM_ACTIVE = 1
            AND IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_PARENT = ' '  AND RM_ANAL = :anal AND RM_TYPE = 0 AND RM_ACTIVE = 1 )
            --AND IM_CUST = :cust
            AND n1.NI_AVAIL_ACTUAL >= '1'
            AND n1.NI_STATUS <> 0
            GROUP BY IM_CUST,IM_XX_COST_CENTRE01,n1.NI_LOCN,n1.NI_AVAIL_ACTUAL,5,6,n1.NI_STOCK,8,9,10,11,12,l1.IL_NOTE_2,n1.NI_MADE_DATE,IM_LEVEL_UNIT



            UNION ALL

            /*Get Tabcorp Inner/Outer PackingFee*/
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

            WHERE     (
                        ((Select rmP.RM_XX_FEE08
                        from RM rmP
                        where rmP.RM_CUST = :cust
                        AND regexp_like(rmP.RM_XX_FEE08, '[0-9]+\.[0-9]{1,2}')
                      /* AND (rmP.RM_CUST = r.RM_CUST OR rmP.RM_CUST = r.RM_PARENT)*/) > 0 )
                        OR
                        ((Select rmP.RM_XX_FEE09
                        from RM rmP
                        where rmP.RM_CUST = :cust
                        AND regexp_like(rmP.RM_XX_FEE09, '[0-9]+\.[0-9]{1,2}')
                        /* AND (rmP.RM_CUST = r.RM_CUST OR rmP.RM_CUST = r.RM_PARENT)*/) > 0 )
                        OR
                        ((Select rmP.RM_XX_FEE02
                        from RM rmP
                        where rmP.RM_CUST = :cust
                        AND regexp_like(rmP.RM_XX_FEE02, '[0-9]+\.[0-9]{1,2}')
                        /* AND (rmP.RM_CUST = r.RM_CUST OR rmP.RM_CUST = r.RM_PARENT)*/) > 0 )
                        OR
                        ((Select rmP.RM_XX_FEE01
                        from RM rmP
                        where rmP.RM_CUST = :cust
                        AND regexp_like(rmP.RM_XX_FEE01, '[0-9]+\.[0-9]{1,2}')
                        /* AND (rmP.RM_CUST = r.RM_CUST OR rmP.RM_CUST = r.RM_PARENT)*/) > 0 )
                        )

            AND       s.SH_ORDER = d.SD_ORDER
            AND       Upper(i.IM_XX_QTY_PER_PACK) IN ('INNER','OUTER')
            AND       r.RM_ANAL = '72'
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
                      s.SH_CUST_REF   ;


END IF;

SELECT * FROM Tmp_Admin_Data
ORDER BY OrderNum,Pickslip Asc