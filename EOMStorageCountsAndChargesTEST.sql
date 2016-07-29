/*decalre variables*/
var cust varchar2(20)
exec :cust := 'TABCORP'
var stock varchar2(20)
exec :stock := 'COURIER'
var source varchar2(20)
exec :source := 'BSPRINTNSW'
var anal varchar2(20)
exec :anal := '72'
var start_date varchar2(20)
exec :start_date := To_Date('26-Jun-2013')
var end_date varchar2(20)
exec :end_date := To_Date('30-Jun-2013')


--This should combine the first count with the 2nd results
SELECT IM_CUST AS "Customer",IM_XX_COST_CENTRE01 AS "Catalogue Owner",n1.NI_LOCN AS "Locn",n1.NI_AVAIL_ACTUAL AS "Avail SOH",
                CASE
                  WHEN (l1.IL_NOTE_2 like 'Yes'
                        OR l1.IL_NOTE_2 LIKE 'YES'
                        OR l1.IL_NOTE_2 LIKE 'yes')
                   THEN 'FEEPALLETS'
                   ELSE 'FEESHELFS'
                   END AS "Fee Type", n1.NI_STOCK AS "Item",
               CASE
                  WHEN (l1.IL_NOTE_2 like 'Yes'
                        OR l1.IL_NOTE_2 LIKE 'YES'
                        OR l1.IL_NOTE_2 LIKE 'yes')
                   THEN 'Pallet Space Utilisation Fee (per month)'
                   ELSE 'Shelf Utilisation Fee'
                   END AS "Description",
               CASE
                  WHEN (l1.IL_NOTE_2 like 'Yes'
                        OR l1.IL_NOTE_2 LIKE 'YES'
                        OR l1.IL_NOTE_2 LIKE 'yes')
                   THEN 'Pallet Fee is for ' ||
                    (
                      SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
                      FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
                          INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
                      WHERE Stock.IM_CUST = :cust  AND Stock.IM_ACTIVE = 1
                      AND NView.NI_AVAIL_ACTUAL >= '1'
                      AND NView.NI_STATUS <> 0
                      AND Locations.IL_LOCN = n1.NI_LOCN
                    ) || ' stock(s)'
                  ELSE 'Shelf Fee is for ' ||
                    (
                      SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
                      FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
                          INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
                      WHERE Stock.IM_CUST = :cust  AND Stock.IM_ACTIVE = 1
                      AND NView.NI_AVAIL_ACTUAL >= '1'
                      AND NView.NI_STATUS <> 0
                      AND Locations.IL_LOCN = n1.NI_LOCN
                    )  || ' stock(s)'
                  END AS "FeeDescription",
               CASE  WHEN (l1.IL_NOTE_2 like 'Yes'
                        OR l1.IL_NOTE_2 LIKE 'YES'
                        OR l1.IL_NOTE_2 LIKE 'yes')
                   THEN
                (Select CAST(RM_XX_FEE11 AS decimal(10,5))
                  FROM RM
                  WHERE RM_CUST = :cust
                ) /
                (
                  SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
                  FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
                      INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
                  WHERE Stock.IM_CUST = :cust  AND Stock.IM_ACTIVE = 1
                  AND NView.NI_AVAIL_ACTUAL >= '1'
                  AND NView.NI_STATUS <> 0
                  AND Locations.IL_LOCN = n1.NI_LOCN
                )
               ELSE
                (Select CAST(RM_XX_FEE12 AS decimal(10,5))
                  FROM RM
                  WHERE RM_CUST = :cust
                ) /
                (
                  SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
                  FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
                      INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
                  WHERE Stock.IM_CUST = :cust  AND Stock.IM_ACTIVE = 1
                  AND NView.NI_AVAIL_ACTUAL >= '1'
                  AND NView.NI_STATUS <> 0
                  AND Locations.IL_LOCN = n1.NI_LOCN
                )
               END AS "Unit Price",
               CASE  WHEN (l1.IL_NOTE_2 like 'Yes'
                        OR l1.IL_NOTE_2 LIKE 'YES'
                        OR l1.IL_NOTE_2 LIKE 'yes')
                   THEN
                (Select CAST(RM_XX_FEE11 AS decimal(10,5))
                  FROM RM
                  WHERE RM_CUST = :cust
                ) /
                (
                  SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
                  FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
                      INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
                  WHERE Stock.IM_CUST = :cust  AND Stock.IM_ACTIVE = 1
                  AND NView.NI_AVAIL_ACTUAL >= '1'
                  AND NView.NI_STATUS <> 0
                  AND Locations.IL_LOCN = n1.NI_LOCN
                )
               ELSE
                (Select CAST(RM_XX_FEE12 AS decimal(10,5))
                  FROM RM
                  WHERE RM_CUST = :cust
                ) /
                (
                  SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
                  FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
                      INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
                  WHERE Stock.IM_CUST = :cust  AND Stock.IM_ACTIVE = 1
                  AND NView.NI_AVAIL_ACTUAL >= '1'
                  AND NView.NI_STATUS <> 0
                  AND Locations.IL_LOCN = n1.NI_LOCN
                )
               END AS "Excl",
                l1.IL_NOTE_2 AS "Pallet/Space", n1.NI_MADE_DATE AS "Desp Date", IM_LEVEL_UNIT AS "UOI",(SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
                 FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
                      INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
                 WHERE Stock.IM_CUST = :cust  AND Stock.IM_ACTIVE = 1
                 AND NView.NI_AVAIL_ACTUAL >= '1'
                 AND NView.NI_STATUS <> 0
                 AND Locations.IL_LOCN = n1.NI_LOCN
                 /*GROUP BY Locations.IL_LOCN
                 ORDER BY Locations.IL_LOCN*/) CountCustStocks


FROM NI n1 INNER JOIN IM ON IM_STOCK = n1.NI_STOCK
INNER JOIN IL l1 ON l1.IL_LOCN = n1.NI_LOCN
WHERE IM_ACTIVE = 1 AND IM_CUST = :cust
AND n1.NI_AVAIL_ACTUAL >= '1'
AND n1.NI_STATUS <> 0
GROUP BY IM_CUST,IM_XX_COST_CENTRE01,n1.NI_LOCN,n1.NI_AVAIL_ACTUAL,5,6,n1.NI_STOCK,8,9,10,11,l1.IL_NOTE_2,n1.NI_MADE_DATE,IM_LEVEL_UNIT
ORDER BY n1.NI_STOCK,n1.NI_LOCN

