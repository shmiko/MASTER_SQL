DROP TABLE Tmp_Storage_Data

CREATE TABLE Tmp_Storage_Data
(       vNI_ENTRY VARCHAR(255),
        vNI_TRAN_TYPE VARCHAR(255),
        vNI_ERA VARCHAR(255),
        vNI_STATUS VARCHAR(255),
        vNI_QUANTITY VARCHAR(255),
        vNE_AVAIL_ACTUAL VARCHAR(255),
        vIL_LOCN VARCHAR(255),
        vIM_STOCK VARCHAR(255),
        vIM_CUST VARCHAR(255),
        vIL_NOTE_2 VARCHAR(255),
        vCOUNT_NE_ENTRY VARCHAR(255),
        vSUM_NE_AVAIL_ACTUAL VARCHAR(255),
        vCOUNT_IL_LOCN VARCHAR(255)
)


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



INSERT into Tmp_Storage_Data( vNI_ENTRY,
                              vNI_TRAN_TYPE,
                              vNI_STATUS,
                              vNI_ERA,
                              vNI_QUANTITY,
                              vNE_AVAIL_ACTUAL,
                              vIL_LOCN,
                              vIM_STOCK,
                              vIM_CUST,
                              vIL_NOTE_2,
                              vCOUNT_NE_ENTRY,
                              vSUM_NE_AVAIL_ACTUAL,
                              vCOUNT_IL_LOCN )
--VALUES ('232323','Cust','Pick','Date', 'PickFee','1','Pickfee','Pickfee','5'),


--Used for getting EOM storage lines*/           /*OK as of Nov 2012    */
--Name: EOM_STORAGE_LINES
SELECT  NI_ENTRY,
        NI_TRAN_TYPE,
        NI_STATUS,
        NI_ERA,
        NI_QUANTITY,
        NE_AVAIL_ACTUAL,
        IL_LOCN,
        IM_STOCK,
        IM_CUST,
        IL_NOTE_2 ,
        Count(NE_ENTRY) AS "NumEntries",
        Sum(NE_AVAIL_ACTUAL) AS "TotalSOH",
        Count(IL_LOCN) AS "NumOfLocns"
FROM PWIN175.NI, PWIN175.NE, PWIN175.IL, PWIN175.IM
WHERE IL_LOCN = NI_LOCN
AND NI_ENTRY = NE_ENTRY
AND NI_STOCK = IM_STOCK
AND IM_CUST = :cust
--AND IM_STOCK IN ('153061','502075','AW003','AW003B','AW003C','AW012B','AW021','TAB2397'   )
AND NE_AVAIL_ACTUAL >= '1'
--AND IM_STOCK = '502075'
GROUP BY NI_ENTRY, NI_TRAN_TYPE,NI_STATUS,NI_ERA, NI_QUANTITY, NE_AVAIL_ACTUAL, IL_LOCN, IM_STOCK, IM_CUST,IL_NOTE_2
ORDER BY IM_STOCK







SELECT vIL_LOCN, Count(*) AS "Num",vIL_NOTE_2,
      CASE   WHEN vIL_NOTE_2 like 'Yes' OR vIL_NOTE_2 LIKE 'YES' OR vIL_NOTE_2 LIKE 'yes' THEN 'Pallet Fee is for  ' ||  Count(*) || ' stock(s)'
            WHEN vIL_NOTE_2 NOT like 'No' OR vIL_NOTE_2 NOT LIKE 'YES' OR vIL_NOTE_2 NOT LIKE 'yes' THEN 'Shelf Fee is '  ||  Count(*) || ' stock(s)'
            ELSE ''
            END AS "FeeDescription",
      CASE   WHEN vIL_NOTE_2 like 'Yes' OR vIL_NOTE_2 LIKE 'YES' OR vIL_NOTE_2 LIKE 'yes' THEN '' || (Select CAST(RM_XX_FEE11 AS decimal(10,5)) from RM where RM_CUST = :cust  ) / Count(*)
            WHEN vIL_NOTE_2 NOT like 'No' OR vIL_NOTE_2  NOT LIKE 'YES' OR vIL_NOTE_2 NOT LIKE 'yes' THEN '' || (Select CAST(RM_XX_FEE12  AS decimal(10,5)) from RM where RM_CUST = :cust ) / Count(*)
            ELSE ''
            END AS "Fee"
FROM Tmp_Storage_Data
GROUP BY vIL_LOCN,vIL_NOTE_2
ORDER BY vIL_LOCN,vIL_NOTE_2





DROP TABLE Tmp_Storage_Data2

CREATE TABLE Tmp_Storage_Data2
            (
                    vIM_STOCK VARCHAR(255),
                    vTotalSum VARCHAR(255),
                    vIL_LOCN VARCHAR(255),
                    vCOUNT_IL_LOCN VARCHAR(255),
                    vStockCount VARCHAR(255),
                    vNE_TRAN_TYPE VARCHAR(255),
                    vNE_STATUS VARCHAR(255),
                    vIL_NOTE_2 VARCHAR(255),
                    vFeeDescription VARCHAR(255),
                    vFee VARCHAR(255)
            )


INSERT into Tmp_Storage_Data2( vIM_STOCK,
                              vTotalSum,
                              vIL_LOCN,
                              vCOUNT_IL_LOCN,
                              vStockCount,
                              vNE_TRAN_TYPE,
                              vNE_STATUS,
                              vIL_NOTE_2,
                              vFeeDescription,
                              vFee
                               )



--SELECT Count(*) AS "SCount"
--FROM
--    (

--SELECT DISTINCT IM_STOCK FROM IM RIGHT INNER JOIN (
      SELECT Count(ROWNUM) AS "LocnCount"
      FROM NA INNER JOIN IL On(IL_UID = NA_EXT_KEY) INNER JOIN NE ON NE_ACCOUNT = NA_ACCOUNT
      WHERE	NA_STOCK IN (SELECT IM_STOCK FROM IM WHERE IM_CUST = :cust AND IM_ACTIVE = 1)
      AND NE_AVAIL_ACTUAL >= '1'
      --AND NA_STOCK IN ( '153053','TAB2728','153049')
      AND IL_LOCN = 'MR287A'
      AND NE_STATUS <> 0
      GROUP BY IL_LOCN
      ORDER BY "LocnCount" -- ) --ON NA_STOCK
--      HAVING Count(NA_STOCK) >= 1

    Select @@RowCount
 --  ) AS counts
--    GROUP BY Count(*)


SELECT Count(vIM_STOCK),vIM_STOCK
FROM  (SELECT Count(*) FROM Tmp_Storage_Data2) AS tblTemp
GROUP BY vIM_STOCK


SELECT 8 = (SELECT Count(*) FROM Tmp_Storage_Data2)
FROM  Tmp_Storage_Data2
GROUP BY



SELECT  Count(ROWNUM) AS "TotalRows", NULL, NULL, NULL, NULL
FROM  Tmp_Storage_Data2

UNION




SELECT  vIM_STOCK,vIL_LOCN,
            CASE  WHEN vIL_NOTE_2 like 'Yes' OR vIL_NOTE_2 LIKE 'YES' OR vIL_NOTE_2 LIKE 'yes' THEN 'Pallet Fee is for  ' ||  Count(ROWNUM) || ' stock(s)'
                  WHEN vIL_NOTE_2 NOT like 'No' OR vIL_NOTE_2 NOT LIKE 'YES' OR vIL_NOTE_2 NOT LIKE 'yes' THEN 'Shelf Fee is '  ||  Count(ROWNUM) || ' stock(s)'
                  ELSE ''
                  END AS "FeeDescription",
            CASE  WHEN vIL_NOTE_2 like 'Yes' OR vIL_NOTE_2 LIKE 'YES' OR vIL_NOTE_2 LIKE 'yes' THEN '' || (Select CAST(RM_XX_FEE11 AS decimal(10,5)) from RM where RM_CUST = :cust  ) / (SELECT  Count(ROWNUM) FROM  Tmp_Storage_Data2)
                  WHEN vIL_NOTE_2 NOT like 'No' OR vIL_NOTE_2  NOT LIKE 'YES' OR vIL_NOTE_2 NOT LIKE 'yes' THEN '' || (Select CAST(RM_XX_FEE12  AS decimal(10,5)) from RM where RM_CUST = :cust ) / (SELECT  Count(ROWNUM) FROM  Tmp_Storage_Data2)
                  ELSE ''
                  END AS "Fee"
FROM  Tmp_Storage_Data2
WHERE vIM_STOCK IN (SELECT DISTINCT IM_STOCK
                    FROM IM
                    WHERE IM_CUST = :cust
                    AND IM_STOCK IN
                                    (
                                      SELECT NA_STOCK,IL_LOCN,IL_NOTE_2,
                                      CASE  WHEN IL_NOTE_2 like 'Yes' OR IL_NOTE_2 LIKE 'YES' OR IL_NOTE_2 LIKE 'yes' THEN 'Pallet Fee is for  ' ||  Count(ROWNUM) || ' stock(s)' || (Select CAST(RM_XX_FEE11 AS decimal(10,5)) from RM where RM_CUST = :cust  ) / (SELECT Count(DISTINCT vIL_LOCN) FROM  Tmp_Storage_Data2 WHERE vIM_STOCK IN (SELECT DISTINCT i2 IM_STOCK FROM IM i2 WHERE i2.IM_CUST = :cust ))
                                            WHEN IL_NOTE_2 NOT like 'Yes' OR IL_NOTE_2 NOT LIKE 'YES' OR IL_NOTE_2 NOT LIKE 'yes' THEN 'Shelf Fee is '  ||  Count(ROWNUM) || ' stock(s)'
                                            ELSE ''
                                            END  ||
                                      CASE  WHEN IL_NOTE_2 like 'Yes' OR IL_NOTE_2 LIKE 'YES' OR IL_NOTE_2 LIKE 'yes' THEN '' || (Select CAST(RM_XX_FEE11 AS decimal(10,5)) from RM where RM_CUST = :cust  ) / (SELECT Count(DISTINCT vIL_LOCN) FROM  Tmp_Storage_Data2 WHERE vIM_STOCK IN (SELECT DISTINCT i2 IM_STOCK FROM IM i2 WHERE i2.IM_CUST = :cust ))
                                            WHEN IL_NOTE_2 NOT like 'Yes' OR IL_NOTE_2  NOT LIKE 'YES' OR IL_NOTE_2 NOT LIKE 'yes' THEN '' || (Select CAST(RM_XX_FEE12  AS decimal(10,5)) from RM where RM_CUST = :cust ) / (SELECT Count(DISTINCT vIL_LOCN) FROM  Tmp_Storage_Data2 WHERE vIM_STOCK IN (SELECT DISTINCT i2 IM_STOCK FROM IM i2 WHERE i2.IM_CUST = :cust ))
                                            ELSE ''
                                            END
                                      FROM NA INNER JOIN IL On(IL_UID = NA_EXT_KEY) AND substr(IL_LOCN,-3,3) NOT LIKE 'OBS'
                                        INNER JOIN NE ON NE_ACCOUNT = NA_ACCOUNT
                                      WHERE	NA_STOCK IN
                                                  (
                                                    SELECT IM_STOCK FROM IM WHERE IM_CUST = :cust AND IM_ACTIVE = 1
                                                  )
                                      AND NE_AVAIL_ACTUAL >= '1'
                                      AND NE_STATUS <> 0
                                      GROUP BY NA_STOCK,IL_LOCN,IL_NOTE_2
                                   )
                  GROUP BY IM_STOCK
                  )
AND vIL_LOCN IN (SELECT DISTINCT IL_LOCN FROM IL WHERE  substr(IL_LOCN,-3,3) NOT LIKE 'OBS')

GROUP BY vIM_STOCK,vIL_LOCN,vIL_NOTE_2



SELECT  vIM_STOCK,vIL_LOCN,
(SELECT Count( DISTINCT vIL_LOCN) FROM  Tmp_Storage_Data2 ) AS "LocationCount",
(SELECT DISTINCT IL_LOCN FROM IL WHERE  substr(IL_LOCN,-3,3) NOT LIKE 'OBS' AND IL_LOCN = vIL_LOCN) AS "Location"
            /*,
            CASE  WHEN vIL_NOTE_2 like 'Yes' OR vIL_NOTE_2 LIKE 'YES' OR vIL_NOTE_2 LIKE 'yes' THEN 'Pallet Fee is for  ' ||  Count(ROWNUM) || ' stock(s)'
                  WHEN vIL_NOTE_2 NOT like 'No' OR vIL_NOTE_2 NOT LIKE 'YES' OR vIL_NOTE_2 NOT LIKE 'yes' THEN 'Shelf Fee is '  ||  Count(ROWNUM) || ' stock(s)'
                  ELSE ''
                  END AS "FeeDescription",
            CASE  WHEN vIL_NOTE_2 like 'Yes' OR vIL_NOTE_2 LIKE 'YES' OR vIL_NOTE_2 LIKE 'yes' THEN '' || (Select CAST(RM_XX_FEE11 AS decimal(10,5)) from RM where RM_CUST = :cust  ) / (SELECT  Count(ROWNUM) FROM  Tmp_Storage_Data2)
                  WHEN vIL_NOTE_2 NOT like 'No' OR vIL_NOTE_2  NOT LIKE 'YES' OR vIL_NOTE_2 NOT LIKE 'yes' THEN '' || (Select CAST(RM_XX_FEE12  AS decimal(10,5)) from RM where RM_CUST = :cust ) / (SELECT  Count(ROWNUM) FROM  Tmp_Storage_Data2)
                  ELSE ''
                  END AS "Fee" */
FROM  Tmp_Storage_Data2
WHERE vIL_LOCN IN (SELECT DISTINCT IL_LOCN FROM IL WHERE  substr(IL_LOCN,-3,3) NOT LIKE 'OBS')
GROUP BY vIM_STOCK,vIL_LOCN,vIL_NOTE_2
ORDER BY vIM_STOCK



SELECT  i.IM_STOCK,
             (
              SELECT Count( DISTINCT vIL_LOCN) FROM  Tmp_Storage_Data2 WHERE vIM_STOCK = i.IM_STOCK
             ) AS "LocationCount",
             (
              SELECT IL_LOCN--DISTINCT IL_LOCN +
              /*CASE  WHEN IL_NOTE_2 like 'Yes' OR IL_NOTE_2 LIKE 'YES' OR IL_NOTE_2 LIKE 'yes' THEN 'Pallet Fee is for  ' ||  Count(ROWNUM) || ' stock(s)' || (Select CAST(RM_XX_FEE11 AS decimal(10,5)) from RM where RM_CUST = :cust  ) / (SELECT Count(DISTINCT vIL_LOCN) FROM  Tmp_Storage_Data2 WHERE vIM_STOCK IN (SELECT DISTINCT i2 IM_STOCK FROM IM i2 WHERE i2.IM_CUST = :cust ))
                    WHEN IL_NOTE_2 NOT like 'Yes' OR IL_NOTE_2 NOT LIKE 'YES' OR IL_NOTE_2 NOT LIKE 'yes' THEN 'Shelf Fee is '  ||  Count(ROWNUM) || ' stock(s)'
                    ELSE ''
                    END  ||
              CASE  WHEN IL_NOTE_2 like 'Yes' OR IL_NOTE_2 LIKE 'YES' OR IL_NOTE_2 LIKE 'yes' THEN '' || (Select CAST(RM_XX_FEE11 AS decimal(10,5)) from RM where RM_CUST = :cust  ) / (SELECT Count(DISTINCT vIL_LOCN) FROM  Tmp_Storage_Data2 WHERE vIM_STOCK IN (SELECT DISTINCT i2 IM_STOCK FROM IM i2 WHERE i2.IM_CUST = :cust ))
                    WHEN IL_NOTE_2 NOT like 'Yes' OR IL_NOTE_2  NOT LIKE 'YES' OR IL_NOTE_2 NOT LIKE 'yes' THEN '' || (Select CAST(RM_XX_FEE12  AS decimal(10,5)) from RM where RM_CUST = :cust ) / (SELECT Count(DISTINCT vIL_LOCN) FROM  Tmp_Storage_Data2 WHERE vIM_STOCK IN (SELECT DISTINCT i2 IM_STOCK FROM IM i2 WHERE i2.IM_CUST = :cust ))
                    ELSE ''
                    END  */
              FROM IL WHERE  substr(IL_LOCN,-3,3) NOT LIKE 'OBS'
              GROUP BY IL_LOCN
              ) AS "Location_FeeDesc_Fee"
FROM  IM i
WHERE i.IM_CUST = :cust
AND i.IM_STOCK IN
                (
                  SELECT NA_STOCK
                  FROM NA INNER JOIN IL On(IL_UID = NA_EXT_KEY)
                    INNER JOIN NE ON NE_ACCOUNT = NA_ACCOUNT
                  WHERE	NA_STOCK = IM_STOCK AND IM_ACTIVE = 1
                  AND NE_AVAIL_ACTUAL >= '1'
                  AND NE_STATUS <> 0
                  GROUP BY NA_STOCK
                )
GROUP BY i.IM_STOCK,2,3
ORDER BY i.IM_STOCK






SELECT *
FROM Tmp_Storage_Data2


/*AND vIM_STOCK IN (SELECT DISTINCT IM_STOCK
                    FROM IM
                    WHERE IM_CUST = :cust
                    AND IM_STOCK IN
                                    (
                                      SELECT NA_STOCK
                                      FROM NA INNER JOIN IL On(IL_UID = NA_EXT_KEY)
                                        INNER JOIN NE ON NE_ACCOUNT = NA_ACCOUNT
                                      WHERE	NA_STOCK IN
                                                  (
                                                    SELECT IM_STOCK FROM IM WHERE IM_CUST = :cust AND IM_ACTIVE = 1
                                                  )
                                      AND NE_AVAIL_ACTUAL >= '1'
                                      AND NE_STATUS <> 0
                                      GROUP BY NA_STOCK,IL_NOTE_2
                                   )
                  GROUP BY IM_STOCK, IM_DESC, IM_CUST
                  )  */


GROUP BY vIM_STOCK,vIL_LOCN,vIL_NOTE_2







 SELECT DISTINCT IM_STOCK, IM_DESC, IM_CUST
 FROM IM
 WHERE IM_CUST = :cust
 AND IM_STOCK IN (SELECT NA_STOCK
                  FROM NA INNER JOIN IL On(IL_UID = NA_EXT_KEY)
                        INNER JOIN NE ON NE_ACCOUNT = NA_ACCOUNT
                  WHERE	NA_STOCK IN (SELECT IM_STOCK FROM IM WHERE IM_CUST = :cust AND IM_ACTIVE = 1)
                  AND NE_AVAIL_ACTUAL >= '1'
                  AND NE_STATUS <> 0
                  GROUP BY NA_STOCK,IL_NOTE_2
                  )
GROUP BY IM_STOCK, IM_DESC, IM_CUST







SELECT a1.NA_STOCK,l1.IL_LOCN,l1.IL_NOTE_2,
CASE
    WHEN (l1.IL_NOTE_2 like 'Yes'
       OR l1.IL_NOTE_2 LIKE 'YES'
       OR l1.IL_NOTE_2 LIKE 'yes')
               THEN 'Pallet Fee is for  ' ||  Count(ROWNUM) || ' stock(s)' ||
                (Select CAST(RM_XX_FEE11 AS decimal(10,5))
                  FROM RM
                  WHERE RM_CUST = :cust
                ) /
                (SELECT COUNT(DISTINCT a2.NA_STOCK) AS "StockCount" --, NE_AVAIL_ACTUAL
                  FROM NA a2 INNER JOIN IL l2 On(l2.IL_UID = NA_EXT_KEY)
                              INNER JOIN NE ON NE_ACCOUNT = a2.NA_ACCOUNT
                                            AND NE_STOCK = a2.NA_STOCK
                              INNER JOIN NA a3 ON (a2.NA_STOCK <> a3.NA_STOCK)
                  /*WHERE	NA_STOCK IN
                                    (
                                      SELECT IM_STOCK FROM IM WHERE IM_CUST = :cust AND IM_ACTIVE = 1
                                     )  */
                  AND NE_AVAIL_ACTUAL >= '1'
                  AND l2.IL_LOCN = IL_LOCN
                  AND NE_STATUS <> 0
                  GROUP BY a2.NA_STOCK
                  )
               ELSE ''
               END AS "FeeDescription"
FROM NA a1 INNER JOIN IL l1 On(l1.IL_UID = a1.NA_EXT_KEY) AND substr(l1.IL_LOCN,-3,3) NOT LIKE 'OBS'
INNER JOIN NE ON NE_ACCOUNT = a1.NA_ACCOUNT
WHERE	a1.NA_STOCK IN
          (
            SELECT IM_STOCK FROM IM WHERE IM_CUST = :cust AND IM_ACTIVE = 1
          )
AND NE_AVAIL_ACTUAL >= '1'
AND NE_STATUS <> 0
GROUP BY a1.NA_STOCK,l1.IL_LOCN,l1.IL_NOTE_2--, "FeeDescription"






--This gets count of active stocks by cust per location where there is available stock
SELECT
Locations.IL_LOCN,
Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
      FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
      INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
      WHERE Stock.IM_CUST = '21BUDGET'  AND Stock.IM_ACTIVE = 1
      AND NI_AVAIL_ACTUAL >= '1'
      AND NI_STATUS <> 0
GROUP BY Locations.IL_LOCN
ORDER BY Locations.IL_LOCN


--This shows active stocks by cust in locations where there is available stock
SELECT NI_STOCK,NI_LOCN,NI_AVAIL_ACTUAL
FROM NI INNER JOIN IM ON IM_STOCK = NI_STOCK
WHERE IM_ACTIVE = 1 AND IM_CUST = '21BUDGET'
AND NI_AVAIL_ACTUAL >= '1'
AND NI_STATUS <> 0
ORDER BY NI_LOCN


--This should combine the first count with the 2nd results
SELECT n1.NI_STOCK,n1.NI_LOCN,n1.NI_AVAIL_ACTUAL,
                (SELECT Count(DISTINCT NView.NI_STOCK) AS CountOfStocks
                 FROM IL Locations INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
                      INNER JOIN IM Stock ON Stock.IM_STOCK = NView.NI_STOCK
                 WHERE Stock.IM_CUST = :cust  AND Stock.IM_ACTIVE = 1
                 AND NView.NI_AVAIL_ACTUAL >= '1'
                 AND NView.NI_STATUS <> 0
                 AND Locations.IL_LOCN = n1.NI_LOCN
                 /*GROUP BY Locations.IL_LOCN
                 ORDER BY Locations.IL_LOCN*/) CountCustStocks,


               CASE  WHEN (l1.IL_NOTE_2 like 'Yes'
                        OR l1.IL_NOTE_2 LIKE 'YES'
                        OR l1.IL_NOTE_2 LIKE 'yes')
                   THEN 'Pallet Fee is ' ||
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
               ELSE ''
               END AS "FeeDescription", l1.IL_NOTE_2
FROM NI n1 INNER JOIN IM ON IM_STOCK = n1.NI_STOCK
INNER JOIN IL l1 ON l1.IL_LOCN = n1.NI_LOCN
WHERE IM_ACTIVE = 1 AND IM_CUST = :cust
AND n1.NI_AVAIL_ACTUAL >= '1'
AND n1.NI_STATUS <> 0
GROUP BY n1.NI_LOCN,n1.NI_STOCK,n1.NI_AVAIL_ACTUAL,3,4,l1.IL_NOTE_2
ORDER BY n1.NI_LOCN


--This gets all stocks in specific location to counter check the above query
-- this should have more than above as there is no cust filter
SELECT NI_STOCK,NI_LOCN,NI_AVAIL_ACTUAL
FROM NI INNER JOIN IM ON IM_STOCK = NI_STOCK
--INNER JOIN IL ON IL_LOCN = NI_LOCN
WHERE IM_ACTIVE = 1 AND  NI_LOCN = 'R5A28-13'
AND NI_AVAIL_ACTUAL >= '1'
AND NI_STATUS <> 0







--Looks good for quick stock by location
SELECT IM_STOCK, NI_AVAIL_ACTUAL, NI_LOCN
FROM IM INNER JOIN NI ON NI_STOCK = IM_STOCK
WHERE IM_STOCK in ( select NA_STOCK from PWIN175.NA  where NA_EXT_KEY = NI_NA_EXT_KEY AND NA_STOCK = IM_STOCK)
AND IM_ACTIVE = 1
AND NI_AVAIL_ACTUAL >= '1'
AND NI_STATUS <> 0
AND NI_LOCN IS NOT NULL


--Get count of stock per cust
SELECT IM_CUST,Count(DISTINCT IM_STOCK) AS StockCount
FROM IM
WHERE IM_ACTIVE = 1
GROUP BY IM_CUST
HAVING StockCount > 1





SELECT Entertainers.EntertainerID,Members.MbrFirstName, Members.MbrLastName, SUM(Engagements.ContractPrice)/(SELECT COUNT(*) FROM Entertainer_Members AS EM2 WHERE EM2.Status <> 3
                                                                                                              AND EM2.EntertainerID = Entertainers.EntertainerID) AS MemberPay
FROM ((Members INNER JOIN Entertainer_Members ON Members.MemberID = Entertainer_Members.MemberID)
INNER JOIN Entertainers
ON Entertainers.EntertainerID =
Entertainer_Members.EntertainerID)
INNER JOIN Engagements
ON Entertainers.EntertainerID =
Engagements.EntertainerID
WHERE Entertainer_Members.Status<>3
GROUP BY Entertainers.EntertainerID,
Members.MbrFirstName, Members.MbrLastName
ORDER BY Members.MbrLastName