--Admin Order Data
/*decalre variables*/
var cust varchar2(20)
exec :cust := 'SUPERPART'
var ordernum varchar2(20)
exec :ordernum := '1370684'
var stock varchar2(20)
exec :stock := 'COURIER'

var stockexclude  varchar2(20)
exec :stockexclude := 'FEE%'


var source varchar2(20)
exec :source := 'BSPRINTNSW'
var anal varchar2(20)
exec :anal := '69'
var start_date varchar2(20)
exec :start_date := To_Date('8-Jul-2013')
var end_date varchar2(20)
exec :end_date := To_Date('14-Jul-2013')



INSERT into Tmp_Admin_Data(
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
            vOrderSource )



/*Get Handeling Fee*/
SELECT    s.SH_CUST                AS "Customer",
          s.SH_SPARE_STR_4         AS "CostCentre",
          s.SH_ORDER               AS "Order",
          t.ST_PICK                AS "Pickslip",
          d.SD_XX_PICKLIST_NUM     AS "PickNum",
          t.ST_PSLIP               AS "DespatchNote",
          t.ST_DESP_DATE           AS "DespatchDate",
  CASE    WHEN (t.ST_PSLIP IS NOT NULL) THEN 'Handeling Fee is '
          ELSE ''
          END                      AS "FeeType",
          d.SD_STOCK               AS "Item",
          d.SD_DESC                AS "Description",
  CASE    WHEN d.SD_LINE IS NOT NULL THEN  '1'
          ELSE ''
          END                     AS "Qty",
  CASE    WHEN d.SD_LINE IS NOT NULL THEN  '1'
          ELSE ''
          END                     AS "UOI",
  CASE    WHEN (t.ST_PSLIP IS NOT NULL) THEN '' ||  (Select RM_XX_FEE06 from RM where RM_CUST = :cust)
          ELSE ''
          END                      AS "UnitPrice",
          d.SD_EXCL                AS "DExcl",
          d.SD_XX_OW_UNIT_PRICE    AS "OWUnitPrice",
          Sum(s.SH_EXCL)           AS "Excl_Total",
          d.SD_INCL                AS "DIncl",
          Sum(s.SH_INCL)           AS "Incl_Total",
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
          s.SH_SPARE_DBL_9         AS "OrderSource"
FROM      PWIN175.SD d
          INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
          INNER JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER
          INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
          INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
WHERE     s.SH_ORDER = d.SD_ORDER
AND       s.SH_STATUS <> 3
AND       r.RM_ANAL = :anal
AND       s.SH_ORDER = t.ST_ORDER
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
--ORDER BY  s.SH_ORDER Asc







SELECT * FROM Tmp_Admin_Data