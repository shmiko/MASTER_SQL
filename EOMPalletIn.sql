--Admin Order Data
/*decalre variables*/
var cust varchar2(20)
exec :cust := 'CONNECTVIC'
var ordernum varchar2(20)
exec :ordernum := '1359866'
var stock varchar2(20)
exec :stock := 'COURIER'

var stockexclude  varchar2(20)
exec :stockexclude := 'FEE%'


var source varchar2(20)
exec :source := 'BSPRINTNSW'
var anal varchar2(20)
exec :anal := '21VICP'
var start_date varchar2(20)
exec :start_date := To_Date('20-May-2013')
var end_date varchar2(20)
exec :end_date := To_Date('26-May-2013')



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
            vOrderSource,
            vIL_NOTE_2,
            vNI_LOCN,
            vNI_AVAIL_ACTUAL,
            vCountOfStocks

            )



/*Get Pallet In Fee*/
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
  CASE    WHEN NE_ENTRY IS NOT NULL THEN  '1'
          ELSE ''
          END                     AS "Qty",
  CASE    WHEN NE_ENTRY IS NOT NULL THEN  '1'
          ELSE ''
          END                     AS "UOI",
  CASE    WHEN NE_ENTRY IS NOT NULL THEN '' ||  (Select RM_XX_FEE14 from RM where RM_CUST = :cust)
          ELSE ''
          END                      AS "UnitPrice",
   CASE    WHEN NE_ENTRY IS NOT NULL THEN '' ||  (Select RM_XX_FEE14 from RM where RM_CUST = :cust)
          ELSE ''
          END                      AS "DExcl",
   CASE    WHEN NE_ENTRY IS NOT NULL THEN '' ||  (Select RM_XX_FEE14 from RM where RM_CUST = :cust)
          ELSE ''
          END                      AS "OWUnitPrice",
   CASE    WHEN NE_ENTRY IS NOT NULL THEN '' ||  (Select RM_XX_FEE14 from RM where RM_CUST = :cust)
          ELSE ''
          END                      AS "Excl_Total",
    CASE    WHEN NE_ENTRY IS NOT NULL THEN '' ||  (Select RM_XX_FEE14 from RM where RM_CUST = :cust) * 1.1
          ELSE ''
          END                      AS "DIncl",
   CASE    WHEN NE_ENTRY IS NOT NULL THEN '' || (Select RM_XX_FEE14 from RM where RM_CUST = :cust) * 1.1
          ELSE ''
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
	        NULL AS "Locn",
	        NULL AS "AvailSOH",
	        NULL AS "CountOfStocks"

FROM      PWIN175.IM
          INNER JOIN PWIN175.NA  ON NA_STOCK = IM_STOCK
          INNER JOIN PWIN175.IL  ON IL_UID = NA_EXT_KEY
          INNER JOIN PWIN175.NE  ON NE_ACCOUNT  = NA_ACCOUNT
          INNER JOIN PWIN175.NI  ON NI_ENTRY = NE_ENTRY
          INNER JOIN PWIN175.RM  ON RM_CUST  = IM_CUST
WHERE     (Select rmP.RM_XX_FEE14
           from RM rmP
            where To_Number(regexp_substr(rmP.RM_XX_FEE14, '^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0 AND rmp.RM_CUST = :cust)  > 0
AND     IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_PARENT = ' '  AND RM_ANAL = :anal AND RM_TYPE = 0 AND RM_ACTIVE = 1 )

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
          NE_DATE