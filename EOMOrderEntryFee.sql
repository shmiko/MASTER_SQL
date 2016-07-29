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
exec :end_date := To_Date('31-Jul-2013')




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



