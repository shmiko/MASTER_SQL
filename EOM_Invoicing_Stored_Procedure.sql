--Admin Order Data
/*Set Stored Procedure*/

CREATE OR REPLACE PROCEDURE EOM_INVOICING (p_cust IN VARCHAR2 := 'TABCORP',
                                           p_ordernum IN VARCHAR2 := '1363806',
                                           p_stock IN VARCHAR2 := 'COURIER',
                                           p_source IN VARCHAR2 := 'BSPRINTNSW',
                                           p_anal IN VARCHAR2 := '72',
                                           p_start_date IN VARCHAR2 := To_Date('1-Jul-2013'),
                                           p_end_date IN VARCHAR2 := To_Date('7-Jul-2013')
                                          ) AS
  nCheckpoint  NUMBER;
BEGIN

  nCheckpoint := 1;

  EXECUTE IMMEDIATE 'DROP TABLE Tmp_Admin_Data_Pickslips';

  nCheckpoint := 2;

  EXECUTE IMMEDIATE 'DROP TABLE Tmp_Admin_Data';

  nCheckpoint := 3;

  EXECUTE IMMEDIATE 'CREATE TABLE Tmp_Admin_Data_Pickslips (vPickslip VARCHAR(200),vPslip VARCHAR(10), vDateDesp VARCHAR(10), vPackages INTEGER, vWeight INTEGER, vST_XX_NUM_PAL_SW VARCHAR(10),vST_XX_NUM_PALLETS VARCHAR(10), vST_XX_NUM_CARTONS VARCHAR(10))';

  nCheckpoint := 4;

  EXECUTE IMMEDIATE 'INSERT INTO Tmp_Admin_Data_Pickslips
                    SELECT LTrim(ST_PICK),LTrim(ST_PSLIP), substr(To_Char(ST_DESP_DATE),0,10), ST_WEIGHT, ST_PACKAGES,ST_XX_NUM_PAL_SW,ST_XX_NUM_PALLETS,ST_XX_NUM_CARTONS
                    FROM ST INNER JOIN SH ON SH_ORDER = ST_ORDER
                    WHERE ST_DESP_DATE >= :start_date AND ST_DESP_DATE <= :end_date
                    AND ST_PSLIP <> "CANCELLED"
                    AND SH_STATUS <> 3
                    ';

  nCheckpoint := 5;

  EXECUTE IMMEDIATE 'DROP TABLE Tmp_Admin_Data_Pick_LineCounts';

  nCheckpoint := 6;

  EXECUTE IMMEDIATE 'CREATE TABLE Tmp_Admin_Data_Pick_LineCounts (  nCountOfLines INTEGER, vSLPickslipNum VARCHAR(10), vSLOrderNum VARCHAR2(10), vSLPslip VARCHAR(10), vDateDespSL VARCHAR(10)
                    ,vPackagesSL INTEGER, vWeightSL INTEGER,vST_XX_NUM_PAL_SW_SL VARCHAR(10),vST_XX_NUM_PALLETS_SL VARCHAR(10), vST_XX_NUM_CARTONS_SL VARCHAR(10))
                    ';

  nCheckpoint := 7;

  EXECUTE IMMEDIATE 'INSERT INTO Tmp_Admin_Data_Pick_LineCounts
                    SELECT Count(SL_LINE),LTrim(SL_PICK), LTrim(SL_ORDER), LTrim(SL_PSLIP),TP.vDateDesp, TP.vPackages,TP.vWeight,TP.vST_XX_NUM_PAL_SW,TP.vST_XX_NUM_PALLETS,TP.vST_XX_NUM_CARTONS
                    FROM Tmp_Admin_Data_Pickslips TP LEFT OUTER JOIN SL ON LTrim(SL_PICK) = TP.vPickslip   WHERE SL_PSLIP <> "CANCELLED"  GROUP BY SL_PICK,SL_ORDER,SL_PSLIP,TP.vDateDesp,TP.vPackages,TP.vWeight,TP.vST_XX_NUM_PAL_SW,TP.vST_XX_NUM_PALLETS,TP.vST_XX_NUM_CARTONS
                    ';

  nCheckpoint := 8;

  EXECUTE IMMEDIATE 'CREATE TABLE Tmp_Admin_Data
                      (vCustomer VARCHAR(255),--           AS "Customer",
                      vCostCentre VARCHAR(255),--         AS "CostCentre",
                      vOrder VARCHAR(255),--              AS "Order",
                      vPickslip VARCHAR(255),--           AS "Pickslip",
                      vPickNum VARCHAR(255),--            AS "PickNum",
                      vDespatchNote VARCHAR(255),--       AS "DespatchNote",
                      vDespatchDate VARCHAR(255),--       AS "DespatchDate",
                      vFeeType VARCHAR(255),--            AS "FeeType",
                      vItem VARCHAR(255),--               AS "Item",
                      vDescription VARCHAR(255),--        AS "Description",
                      vQty VARCHAR(255),--                AS "Qty",
                      vUOI VARCHAR(255),--                AS "UOI",
                      vUnitPrice VARCHAR(255),--          AS "UnitPrice",
                      vDExcl VARCHAR(255),--              AS "DExcl",
                      vOWUnitPrice VARCHAR(255),--        AS "OWUnitPrice",
                      vExcl_Total VARCHAR(255),--         AS "Excl_Total",
                      vDIncl VARCHAR(255),--              AS "DIncl",
                      vIncl_Total VARCHAR(255),--         AS "Incl_Total",
                      vReportingPrice VARCHAR(255),--     AS "ReportingPrice",
                      vAddress VARCHAR(255),--            AS "Address",
                      vAddress2 VARCHAR(255),--           AS "Address2",
                      vSuburb VARCHAR(255),--             AS "Suburb",
                      vState VARCHAR(255),--              AS "State",
                      vPostcode VARCHAR(255),--           AS "Postcode",
                      vDeliverTo VARCHAR(255),--          AS "DeliverTo",
                      vAttentionTo VARCHAR(255),--        AS "AttentionTo" ,
                      vWeight VARCHAR(255),--             AS "Weight",
                      vPackages VARCHAR(255),--           AS "Packages",
                      vOrderSource VARCHAR(255),--         AS "OrderSource"
                      vIL_NOTE_2 VARCHAR(255),--           AS "Palett/Shelf"
                      vNI_LOCN VARCHAR(255),--             AS "Location"
                      vNI_AVAIL_ACTUAL VARCHAR(255),--     AS "SOH"
                      vCountOfStocks VARCHAR(255)--       AS "Count"
                    )';

    nCheckpoint := 9;

  EXECUTE IMMEDIATE 'INSERT into Tmp_Admin_Data(
            vCustomer,
            vCostCentre,
            vOrder,
            vPickslip,
            vPickNum,
            vDespatchNote,
            vDespatchDate,
            vFeeType,
            vItem,
            vDescription,
            vQty,
            vUOI,
            vUnitPrice,
            vDExcl,
            vOWUnitPrice,
            vExcl_Total,
            vDIncl,
            vIncl_Total,
            vReportingPrice,
            vAddress,
            vAddress2,
            vSuburb,
            vState,
            vPostcode,
            vDeliverTo,
            vAttentionTo,
            vWeight,
            vPackages,
            vOrderSource,
            vIL_NOTE_2,
            vNI_LOCN,
            vNI_AVAIL_ACTUAL,
            vCountOfStocks

            )


          select    s.SH_CUST                AS "Customer",
                    s.SH_SPARE_STR_4         AS "CostCentre",
                    s.SH_ORDER               AS "Order",
                    t.ST_PICK                AS "Pickslip",
                    d.SD_XX_PICKLIST_NUM     AS "PickNum",
                    t.ST_PSLIP               AS "DespatchNote",
                    substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
            CASE    WHEN d.SD_STOCK like "COURIER%" AND d.SD_SELL_PRICE >= 1  THEN "Freight Fee"
                    ELSE d.SD_DESC
                    END                      AS "FeeType",
                    d.SD_STOCK               AS "Item",
                    d.SD_DESC                AS "Description",
            CASE    WHEN d.SD_LINE IS NOT NULL THEN  1
                    ELSE NULL
                    END                     AS "Qty",
            CASE    WHEN d.SD_LINE IS NOT NULL THEN  "1"
                    ELSE NULL
                    END                     AS "UOI",
            CASE    WHEN d.SD_STOCK like "COURIER%" AND d.SD_SELL_PRICE >= 1 THEN '' || CAST(d.SD_SELL_PRICE AS VARCHAR(20))
                    ELSE CAST(d.SD_SELL_PRICE AS VARCHAR(20)) --|| (Select RM_XX_FEE16 from RM where RM_CUST = :cust)
                    END                      AS "UnitPrice",
                    CAST(d.SD_EXCL AS VARCHAR(20))                AS "DExcl",
                    CAST(d.SD_XX_OW_UNIT_PRICE AS VARCHAR(20))    AS "OWUnitPrice",
                    CAST(Sum(s.SH_EXCL) AS VARCHAR(20))           AS "Excl_Total",
                    CAST(d.SD_INCL AS VARCHAR(20))                AS "DIncl",
                    CAST(Sum(s.SH_INCL) AS VARCHAR(20))           AS "Incl_Total",
            CASE    WHEN d.SD_STOCK NOT like "COURIER%" THEN "Stock Unit Price is "  || (Select i.IM_REPORTING_PRICE from IM i where i.IM_STOCK = d.SD_STOCK)
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
          WHERE     s.SH_ORDER = d.SD_ORDER
          AND       r.RM_ANAL = :anal
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
                    s.SH_SPARE_DBL_9
          HAVING    Sum(s.SH_ORDER) <> 1



          UNION ALL




          SELECT    s.SH_CUST               AS "Customer",
                    s.SH_SPARE_STR_4        AS "CostCentre",
                    s.SH_ORDER              AS "Order",
                    NULL               AS "Pickslip",
                    NULL                    AS "PickNum",
                    NULL              AS "DespatchNote",
                    substr(To_Char(s.SH_ADD_DATE),0,10)            AS "DespatchDate",
            CASE    WHEN s.SH_SPARE_DBL_9 = 1 OR s.SH_SPARE_DBL_9 = 3 OR s.SH_SPARE_DBL_9 = 2 OR s.SH_SPARE_DBL_9 = 4 THEN  "OrderFee"
                    ELSE ''
                    END                     AS "FeeType",
            CASE    WHEN s.SH_SPARE_DBL_9 = 1 OR s.SH_SPARE_DBL_9 = 3 OR s.SH_SPARE_DBL_9 = 2 OR s.SH_SPARE_DBL_9 = 4 THEN  "FEEORDERENTRYS"
                    ELSE ''
                    END                     AS "Item",
            CASE    WHEN s.SH_SPARE_DBL_9 = 1 OR s.SH_SPARE_DBL_9 = 3 OR s.SH_SPARE_DBL_9 = 2 OR s.SH_SPARE_DBL_9 = 4 THEN  "Manual Order Entry Fee"
                    ELSE ''
                    END                     AS "Description",
            CASE    WHEN d.SD_LINE = 1 THEN  1
                    ELSE NULL
                    END                     AS "Qty",
            CASE    WHEN d.SD_LINE = 1 THEN  "1"
                    ELSE ''
                    END                     AS "UOI",
            CASE    WHEN s.SH_SPARE_DBL_9 = 1 OR s.SH_SPARE_DBL_9 = 3 OR s.SH_SPARE_DBL_9 = 2 OR s.SH_SPARE_DBL_9 = 4 THEN  NULL ||  (Select RM_XX_FEE01 from RM where RM_CUST = :cust)
                    ELSE ''
                    END                     AS "UnitPrice",
            CASE    WHEN s.SH_SPARE_DBL_9 = 1 OR s.SH_SPARE_DBL_9 = 3 OR s.SH_SPARE_DBL_9 = 2 OR s.SH_SPARE_DBL_9 = 4 THEN  NULL ||  (Select RM_XX_FEE01 from RM where RM_CUST = :cust)
                    ELSE ''
                    END                     AS "DExcl",
                    NULL                    AS "OWUnitPrice",
                    NULL                    AS "Excl_Total",
            CASE    WHEN s.SH_SPARE_DBL_9 = 1 OR s.SH_SPARE_DBL_9 = 3 OR s.SH_SPARE_DBL_9 = 2 OR s.SH_SPARE_DBL_9 = 4 THEN  NULL ||  (Select RM_XX_FEE01 from RM where RM_CUST = :cust) * 1.1
                    ELSE ''
                    END                     AS "DIncl",
            CASE    WHEN s.SH_SPARE_DBL_9 = 1 OR s.SH_SPARE_DBL_9 = 3 OR s.SH_SPARE_DBL_9 = 2 OR s.SH_SPARE_DBL_9 = 4 THEN  NULL ||  (Select RM_XX_FEE01 from RM where RM_CUST = :cust) * 1.1
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
                    --INNER JOIN PWIN175.ST t ON t.ST_ORDER = s.SH_ORDER
                    INNER JOIN PWIN175.RM r ON r.RM_CUST  = s.SH_CUST
          WHERE     r.RM_ANAL = :anal
          AND       s.SH_ADD_DATE >= :start_date AND s.SH_ADD_DATE <= :end_date
          AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
          AND       (s.SH_SPARE_DBL_9 = 1 OR s.SH_SPARE_DBL_9 = 3 OR s.SH_SPARE_DBL_9 = 2 OR s.SH_SPARE_DBL_9 = 4)
          AND       d.SD_LINE = 1
          GROUP BY  s.SH_CUST,
                    s.SH_ADD_DATE,
                    s.SH_SPARE_STR_4,
                    s.SH_ORDER,
                    s.SH_PREV_PSLIP_NUM,
                    --t.ST_PICK,
                    --t.ST_PSLIP,
                    --t.ST_DESP_DATE,
                    s.SH_SPARE_DBL_9,
                    d.SD_LINE,
                    s.SH_ADDRESS,
                    s.SH_SUBURB,
                    s.SH_CITY,
                    s.SH_STATE,
                    s.SH_POST_CODE,
                    s.SH_NOTE_1,
                    s.SH_NOTE_2,
                    --t.ST_WEIGHT,
                    --t.ST_PACKAGES,
                    s.SH_SPARE_DBL_9



          UNION ALL

          SELECT    s.SH_CUST                AS "Customer",
                    s.SH_SPARE_STR_4         AS "CostCentre",
                    s.SH_ORDER               AS "Order",
                    t.ST_PICK                AS "Pickslip",
                    d.SD_XX_PICKLIST_NUM     AS "PickNum",
                    t.ST_PSLIP               AS "DespatchNote",
                    substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
            CASE    WHEN (i.IM_TYPE = "BB_PACK" AND (d.SD_STOCK NOT like "COURIER%" AND d.SD_STOCK NOT like "FEE%"))  THEN "Packing Fee"
                    ELSE NULL
                    END                      AS "FeeType",
                    d.SD_STOCK               AS "Item",
                    d.SD_DESC                AS "Description",
            CASE    WHEN d.SD_LINE IS NOT NULL THEN  1
                    ELSE NULL
                    END                     AS "Qty",
            CASE    WHEN d.SD_LINE IS NOT NULL THEN  "1"
                    ELSE NULL
                    END                     AS "UOI",

            CASE    /* Get Packing Fees If stock is of type BB_PACK then charge sRM_XX_FEE08.AsDouble * SL_PSLIP_QTY  */
	                WHEN i.IM_TYPE = "BB_PACK"  THEN '' ||  (Select RM_XX_FEE08 from RM where RM_CUST = :cust)
                  ELSE ''
                  END                      AS "UnitPrice",
            CASE    /* Get Packing Fees If stock is of type BB_PACK then charge sRM_XX_FEE08.AsDouble * SL_PSLIP_QTY  */
	                WHEN i.IM_TYPE = "BB_PACK"  THEN '' ||  (Select RM_XX_FEE08 from RM where RM_CUST = :cust)
                  ELSE ''
                  END                      AS "DExcl",
                    NULL                    AS "OWUnitPrice",
                    NULL                    AS "Excl_Total",
              CASE    /* Get Packing Fees If stock is of type BB_PACK then charge sRM_XX_FEE08.AsDouble * SL_PSLIP_QTY  */
	                WHEN i.IM_TYPE = "BB_PACK"  THEN '' ||  (Select RM_XX_FEE08 from RM where RM_CUST = :cust)   * 1.1
                  ELSE ''
                  END                      AS "DIncl",
              CASE    /* Get Packing Fees If stock is of type BB_PACK then charge sRM_XX_FEE08.AsDouble * SL_PSLIP_QTY  */
	                WHEN i.IM_TYPE = "BB_PACK"  THEN '' ||  (Select RM_XX_FEE08 from RM where RM_CUST = :cust)  * 1.1
                  ELSE ''
                  END                      AS "Incl_Total",
            CASE    WHEN d.SD_STOCK NOT like "COURIER%" THEN "Stock Unit Price is"  || (Select i.IM_REPORTING_PRICE from IM i where i.IM_STOCK = d.SD_STOCK)
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
          WHERE     s.SH_ORDER = d.SD_ORDER
          AND       i.IM_TYPE = "BB_PACK"
          AND       r.RM_ANAL = :anal
          AND       s.SH_STATUS <> 3
          AND       d.SD_STOCK NOT IN ("EMERQSRFEE","COURIER%","FEE%","FEE*","COURIER*","COURIER")
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
                    s.SH_SPARE_DBL_9
          HAVING    Sum(s.SH_ORDER) <> 1


          UNION ALL

          SELECT    s.SH_CUST                AS "Customer",
                    s.SH_SPARE_STR_4         AS "CostCentre",
                    s.SH_ORDER               AS "Order",
                    t.ST_PICK                AS "Pickslip",
                    d.SD_XX_PICKLIST_NUM     AS "PickNum",
                    t.ST_PSLIP               AS "DespatchNote",
                    substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
            CASE    WHEN s.SH_NOTE_1 = "DESTROY" OR s.SH_CAMPAIGN = "OBSOLETE" THEN "Destruction Fee is"
                    ELSE NULL
                    END                      AS "FeeType",
            CASE    WHEN d.SD_LINE IS NOT NULL THEN  "DESTRUCT"
                    ELSE NULL
                    END                     AS "Item",
            CASE    WHEN d.SD_LINE IS NOT NULL THEN  "Destruction Fee"
                    ELSE NULL
                    END                     AS "Description",
            CASE    WHEN d.SD_LINE IS NOT NULL THEN  1
                    ELSE NULL
                    END                     AS "Qty",
            CASE    WHEN d.SD_LINE IS NOT NULL THEN  "1"
                    ELSE NULL
                    END                     AS "UOI",
            CASE   WHEN s.SH_NOTE_1 = "DESTROY" OR s.SH_CAMPAIGN = "OBSOLETE" THEN '' ||  (Select RM_XX_FEE25 from RM where RM_CUST = :cust)
                  ELSE ''
                  END                      AS "UnitPrice",
            CASE   WHEN s.SH_NOTE_1 = "DESTROY" OR s.SH_CAMPAIGN = "OBSOLETE" THEN '' ||  (Select RM_XX_FEE25 from RM where RM_CUST = :cust)
                  ELSE ''
                  END                      AS "DExcl",
                  NULL                AS "OWUnitPrice",
                  NULL           AS "Excl_Total",
            CASE   WHEN s.SH_NOTE_1 = "DESTROY" OR s.SH_CAMPAIGN = "OBSOLETE" THEN '' ||  (Select RM_XX_FEE25 from RM where RM_CUST = :cust) * 1.1
                  ELSE ''
                  END                      AS "DIncl",
            CASE   WHEN s.SH_NOTE_1 = "DESTROY" OR s.SH_CAMPAIGN = "OBSOLETE" THEN '' ||  (Select RM_XX_FEE25 from RM where RM_CUST = :cust)  * 1.1
                  ELSE ''
                  END                      AS "Incl_Total",
            CASE    WHEN d.SD_STOCK NOT like "COURIER%" THEN "Stock Unit Price is"  || (Select i.IM_REPORTING_PRICE from IM i where i.IM_STOCK = d.SD_STOCK)
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
                    NULL AS "Pallet/Shelf Space",
	                  NULL AS "Locn",
	                  NULL AS "AvailSOH",
	                  NULL AS "CountOfStocks"


          FROM      PWIN175.SD d
                    INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
                    INNER JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER
                    INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
                    INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
          WHERE     s.SH_ORDER = d.SD_ORDER
          AND       s.SH_STATUS <> 3
          AND       (s.SH_NOTE_1 = "DESTROY" OR s.SH_CAMPAIGN = "OBSOLETE")
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
                    s.SH_SPARE_DBL_9
          HAVING    Sum(s.SH_ORDER) <> 1





          UNION ALL


          SELECT IM_CUST AS "Customer",
            IM_XX_COST_CENTRE01 AS "CostCentre",
            NULL               AS "Order",
            NULL                AS "Pickslip",
            NULL                AS "PickNum",
            NULL               AS "DespatchNote",
            substr(To_Char(n1.NI_MADE_DATE),0,10) AS "DespatchDate", /*Made Date*/
	          CASE /*Fee Type*/
		          WHEN (l1.IL_NOTE_2 like "Yes"
			          OR l1.IL_NOTE_2 LIKE "YES"
			          OR l1.IL_NOTE_2 LIKE "yes")
		          THEN "FEEPALLETS"
		          ELSE "FEESHELFS"
		          END AS "FeeType",
              n1.NI_STOCK AS "Item",
	          CASE
		          WHEN (l1.IL_NOTE_2 like "Yes"
			          OR l1.IL_NOTE_2 LIKE "YES"
			          OR l1.IL_NOTE_2 LIKE "yes")
		          THEN "Pallet Space Utilisation Fee (per month) is split across " ||
			          CAST((SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
			          FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
			          INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
			          WHERE Stock.IM_CUST = :cust  AND Stock.IM_ACTIVE = 1
			          AND NView.NI_AVAIL_ACTUAL >= "1"
			          AND NView.NI_STATUS <> 0
			          AND Locations.IL_LOCN = n1.NI_LOCN) AS VARCHAR(20)) || " stock(s)"
		          ELSE "Shelf Utilisation Fee is split across " ||
			          CAST((SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
			          FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
			          INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
			          WHERE Stock.IM_CUST = :cust  AND Stock.IM_ACTIVE = 1
			          AND NView.NI_AVAIL_ACTUAL >= "1"
			          AND NView.NI_STATUS <> 0
			          AND Locations.IL_LOCN = n1.NI_LOCN)  AS VARCHAR(20))  || " stock(s)"
		          END AS "Description",
            CASE   WHEN l1.IL_NOTE_2 IS NOT NULL THEN  1
                    ELSE NULL
                    END                     AS "Qty",
              IM_LEVEL_UNIT AS "UOI", /*UOI*/
            CASE  /*unit price*/
		          WHEN (l1.IL_NOTE_2 like "Yes"
			          OR l1.IL_NOTE_2 LIKE "YES"
			          OR l1.IL_NOTE_2 LIKE "yes")
		          THEN
			          CAST((Select CAST(RM_XX_FEE11 AS decimal(10,5))
			          FROM RM
			          WHERE RM_CUST = :cust)
			          /
			          (SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
			          FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
			          INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
			          WHERE Stock.IM_CUST = :cust  AND Stock.IM_ACTIVE = 1
			          AND NView.NI_AVAIL_ACTUAL >= "1"
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
			          WHERE Stock.IM_CUST = :cust  AND Stock.IM_ACTIVE = 1
			          AND NView.NI_AVAIL_ACTUAL >= "1"
			          AND NView.NI_STATUS <> 0
			          AND Locations.IL_LOCN = n1.NI_LOCN
			          )AS VARCHAR(20))
		          END AS "UnitPrice",
              CASE WHEN (l1.IL_NOTE_2 like "Yes"
			          OR l1.IL_NOTE_2 LIKE "YES"
			          OR l1.IL_NOTE_2 LIKE "yes")
		          THEN
			          CAST((Select CAST(RM_XX_FEE11 AS decimal(10,5))
			          FROM RM
			          WHERE RM_CUST = :cust)
			          /
			          (SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
			          FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
			          INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
			          WHERE Stock.IM_CUST = :cust  AND Stock.IM_ACTIVE = 1
			          AND NView.NI_AVAIL_ACTUAL >= "1"
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
			          WHERE Stock.IM_CUST = :cust  AND Stock.IM_ACTIVE = 1
			          AND NView.NI_AVAIL_ACTUAL >= "1"
			          AND NView.NI_STATUS <> 0
			          AND Locations.IL_LOCN = n1.NI_LOCN
			          )AS VARCHAR(20))
		          END AS "DExcl",
                  NULL                AS "OWUnitPrice",
                  NULL           AS "Excl_Total",
              CASE WHEN (l1.IL_NOTE_2 like "Yes"
			          OR l1.IL_NOTE_2 LIKE "YES"
			          OR l1.IL_NOTE_2 LIKE "yes")
		          THEN
			          CAST(((Select CAST(RM_XX_FEE11 AS decimal(10,5))
			          FROM RM
			          WHERE RM_CUST = :cust)
			          /
			          (SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
			          FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
			          INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
			          WHERE Stock.IM_CUST = :cust  AND Stock.IM_ACTIVE = 1
			          AND NView.NI_AVAIL_ACTUAL >= "1"
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
			          WHERE Stock.IM_CUST = :cust  AND Stock.IM_ACTIVE = 1
			          AND NView.NI_AVAIL_ACTUAL >= "1"
			          AND NView.NI_STATUS <> 0
			          AND Locations.IL_LOCN = n1.NI_LOCN
			          )AS VARCHAR(20))
		          END AS "DIncl",
                  NULL           AS "Incl_Total",
            CASE    WHEN l1.IL_NOTE_2 IS NOT NULL THEN ''  || (Select i.IM_REPORTING_PRICE from IM i where i.IM_STOCK = "COURIERM")
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
            l1.IL_NOTE_2 AS "Pallet/Space",
	          n1.NI_LOCN AS "Locn",
	          n1.NI_AVAIL_ACTUAL AS "Avail SOH",
	          (SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
	          FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
	          INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
	          WHERE Stock.IM_CUST = :cust  AND Stock.IM_ACTIVE = 1
	          AND NView.NI_AVAIL_ACTUAL >= "1"
	          AND NView.NI_STATUS <> 0
	          AND Locations.IL_LOCN = n1.NI_LOCN
	          ) CountCustStocks
          FROM NI n1 INNER JOIN IM ON IM_STOCK = n1.NI_STOCK
          INNER JOIN IL l1 ON l1.IL_LOCN = n1.NI_LOCN
          WHERE IM_ACTIVE = 1 AND IM_CUST = :cust
          AND n1.NI_AVAIL_ACTUAL >= "1"
          AND n1.NI_STATUS <> 0
          GROUP BY IM_CUST,IM_XX_COST_CENTRE01,n1.NI_LOCN,n1.NI_AVAIL_ACTUAL,5,6,n1.NI_STOCK,8,9,10,11,12,l1.IL_NOTE_2,n1.NI_MADE_DATE,IM_LEVEL_UNIT';






  RETURN;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('EOM_INVOICING failed at checkpoint ' || nCheckpoint ||
                         ' with error ' || SQLCODE || ' : ' || SQLERRM);
    RAISE;
END EOM_INVOICING;








/*SELECT * FROM Tmp_Admin_Data
ORDER BY vOrder,vPickslip Asc    */