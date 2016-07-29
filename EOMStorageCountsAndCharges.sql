  /*decalre variables*/
var cust varchar2(20)
exec :cust := 'CONNECTVIC'
var stock varchar2(20)
exec :stock := 'COURIER'
var source varchar2(20)
exec :source := 'BSPRINTNSW'
var anal varchar2(20)
exec :anal := '21VICP'
var start_date varchar2(20)
exec :start_date := To_Date('1-Jul-2013')
var end_date varchar2(20)
exec :end_date := To_Date('30-Jul-2013')

SELECT * FROM  Tmp_Admin_Data


select last_day(To_Date(sysdate)) from dual

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


