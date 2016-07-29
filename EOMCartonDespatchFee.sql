--Admin Order Data
/*decalre variables*/
var cust varchar2(20)
exec :cust := 'TABCORP'
var ordernum varchar2(20)
exec :ordernum := '1370684'
var stock varchar2(20)
exec :stock := 'COURIER'

var stockexclude  varchar2(20)
exec :stockexclude := 'FEE%'


var source varchar2(20)
exec :source := 'BSPRINTNSW'
var anal varchar2(20)
exec :anal := '72'
var start_date varchar2(20)
exec :start_date := To_Date('1-Jul-2013')
var end_date varchar2(20)
exec :end_date := To_Date('7-Jul-2013')


/* Select RM_XX_FEE15 from RM where RM_CUST = :cust  AND regexp_like(RM.RM_XX_FEE15, '[0-9]+\.[0-9]{1,2}')   */
 /*Get Carton Despatch Fee*/
SELECT    s.SH_CUST                AS "Customer",
          s.SH_SPARE_STR_4         AS "CostCentre",
          s.SH_ORDER               AS "Order",
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
           ) > 0
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
          --,Rate
HAVING    Sum(s.SH_ORDER) <> 1  --AND (Select RM_XX_FEE15 from RM where RM_CUST = :cust ) IS NOT null


