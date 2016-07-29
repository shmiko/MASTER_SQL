var cust varchar2(20)
exec :cust := '21ANZWLTH'
var cust2 varchar2(20)
exec :cust2 := 'BEYONDBLUE'
var ordernum varchar2(20)
exec :ordernum := '1363806'
var stock varchar2(20)
exec :stock := 'COURIER'
var source varchar2(20)
exec :source := 'BSPRINTNSW'
var sAnalysis varchar2(20) /*VerbalOrderEntryFee*/
exec SELECT  RM_ANAL INTO :sAnalysis FROM RM where RM_CUST = :cust;
var anal varchar2(20)
exec :anal := '72'
var start_date varchar2(20)
exec :start_date := To_Date('01-Mar-2014')
var end_date varchar2(20)
exec :end_date := To_Date('31-Mar-2014')
var warehouse varchar2(20)
exec :warehouse := 'SYDNEY'
var warehouse2 varchar2(20)
exec :warehouse2 := 'MELBOURNE'

/*Total Despatches by Month all custs */
select  TO_CHAR(ST_DESP_DATE,'yyyy') AS "SalesYear",
        LTrim(TO_CHAR(ST_DESP_DATE,'MM')) AS "MONTHLY_SALES" ,
        LTrim(TO_CHAR(ST_DESP_DATE,'Month')) AS "MONTHS" ,
        count(ST_ORDER) AS TotalDespatches
FROM PWIN175.ST
WHERE ST_DESP_DATE >= :start_date AND ST_DESP_DATE <= :end_date AND ST_PSLIP <> 'CANCELLED'
GROUP BY TO_CHAR(ST_DESP_DATE,'yyyy') ,LTrim(TO_CHAR(ST_DESP_DATE,'MM')),LTrim(TO_CHAR(ST_DESP_DATE,'Month'))
order by 1

/*Total Despatches by Month by custs */
select  RM_PARENT, SH_CUST,substr(To_Char(ST_DESP_DATE),0,10)            AS "DespatchDate",
         --CASE
         --   WHEN RM_PARENT = ' ' THEN 'No Parent'
         --   ELSE NULL END AS "PC",
        CASE
            WHEN RM_PARENT = ' ' THEN SH_CUST
            WHEN RM_PARENT != ' ' THEN RM_PARENT
            ELSE NULL END AS "Cust",
        TO_CHAR(ST_DESP_DATE,'yyyy') AS "SalesYear",
        LTrim(TO_CHAR(ST_DESP_DATE,'MM')) AS "MONTHLY_SALES" ,
        LTrim(TO_CHAR(ST_DESP_DATE,'Month')) AS "MONTHS" ,
        count(ST_ORDER) AS TotalDespatches
FROM PWIN175.ST INNER JOIN SH ON SH_ORDEr = ST_ORDER
      INNER JOIN RM ON RM_CUST = SH_CUST
WHERE ST_DESP_DATE >= '1-Feb-2014'  AND ST_DESP_DATE <= '28-Feb-2014' AND ST_PSLIP <> 'CANCELLED'
AND  RM_PARENT = :cust OR SH_CUST = :cust
GROUP BY RM_PARENT, SH_CUST,TO_CHAR(ST_DESP_DATE,'yyyy') ,LTrim(TO_CHAR(ST_DESP_DATE,'MM')),LTrim(TO_CHAR(ST_DESP_DATE,'Month')),ST_DESP_DATE
order by 1

/*Total Despatches by Month by cust */
SELECT (CASE
            WHEN RM_PARENT = ' ' THEN SH_CUST
            WHEN RM_PARENT != ' ' THEN RM_PARENT
            ELSE NULL END),-- AS "Cust",
            (select count(ST_ORDER) AS TotalDespatches
            FROM PWIN175.ST INNER JOIN SH ON SH_ORDEr = ST_ORDER
                  INNER JOIN RM ON RM_CUST = SH_CUST
            WHERE ST_DESP_DATE >= '1-Feb-2014'  AND ST_DESP_DATE <= '28-Feb-2014' AND ST_PSLIP <> 'CANCELLED'
            AND  RM_PARENT = :cust OR SH_CUST = :cust) AS DespatchCount
FROM RM INNER JOIN SH ON SH_CUST = RM_CUST
WHERE RM_PARENT = :cust OR SH_CUST = :cust
GROUP BY (CASE
            WHEN RM_PARENT = ' ' THEN SH_CUST
            WHEN RM_PARENT != ' ' THEN RM_PARENT
            ELSE NULL END),RM_PARENT, SH_CUST
ORDER BY 1


/*Total Despatches by Month by ALL cust */
SELECT (CASE
            WHEN RM_PARENT = ' ' THEN SH_CUST
            WHEN RM_PARENT != ' ' THEN RM_PARENT
            ELSE NULL END),-- AS "Cust",
            (select count(ST_ORDER) AS TotalDespatches
            FROM PWIN175.ST INNER JOIN SH ON SH_ORDEr = ST_ORDER
                  INNER JOIN RM ON RM_CUST = SH_CUST
            WHERE ST_DESP_DATE >= '1-Feb-2014'  AND ST_DESP_DATE <= '28-Feb-2014' AND ST_PSLIP <> 'CANCELLED'
            AND  RM_PARENT = r.RM_PARENT OR SH_CUST = r.RM_CUST) AS DespatchCount
FROM RM r INNER JOIN SH s ON s.SH_CUST = r.RM_CUST
--WHERE RM_PARENT = :cust OR SH_CUST = :cust
GROUP BY (CASE
            WHEN r.RM_PARENT = ' ' THEN s.SH_CUST
            WHEN r.RM_PARENT != ' ' THEN r.RM_PARENT
            ELSE NULL END),r.RM_PARENT, s.SH_CUST,r.RM_CUST
ORDER BY 1

/*Total Despatches by Month by cust */
SELECT RM_PARENT,
            (select count(ST_ORDER) AS TotalDespatches
            FROM PWIN175.ST INNER JOIN SH ON SH_ORDEr = ST_ORDER
                  INNER JOIN RM ON RM_CUST = SH_CUST
            WHERE ST_DESP_DATE >= '1-Feb-2014'  AND ST_DESP_DATE <= '28-Feb-2014' AND ST_PSLIP <> 'CANCELLED'
            AND  RM_PARENT = :cust OR SH_CUST = :cust) AS DespatchCount
FROM RM INNER JOIN SH ON SH_CUST = RM_CUST
WHERE RM_PARENT = :cust OR SH_CUST = :cust
AND RM_PARENT <> ' '
GROUP BY RM_PARENT
ORDER BY 1

/*Total Despatches by Month all custs */
SELECT r.RM_PARENT,
            (select count(ST_ORDER) AS TotalDespatches
            FROM PWIN175.ST INNER JOIN SH ON SH_ORDEr = ST_ORDER
                  INNER JOIN RM ON RM_CUST = SH_CUST
            WHERE ST_DESP_DATE >= '1-Feb-2014'  AND ST_DESP_DATE <= '28-Feb-2014' AND ST_PSLIP <> 'CANCELLED'
            AND  RM_PARENT = r.RM_PARENT OR SH_CUST = r.RM_CUST) AS DespatchCount
FROM RM r INNER JOIN SH s ON s.SH_CUST = r.RM_CUST
WHERE r.RM_PARENT <> ' '
GROUP BY r.RM_PARENT,r.RM_CUST
ORDER BY 1








/*Total Orders by Month  all custs */
select  TO_CHAR(SH_ADD_DATE,'yyyy') AS "SalesYear",
        LTrim(TO_CHAR(SH_ADD_DATE,'MM')) AS "MONTHLY_SALES" ,
        LTrim(TO_CHAR(SH_ADD_DATE,'Month')) AS "MONTHS" ,
        count(SH_ORDER) AS TotalOrders,
        Sum(SH_EXCL) AS "TotalValue"
FROM PWIN175.SH
WHERE SH_ADD_DATE >= :start_date AND SH_ADD_DATE <= :end_date AND SH_STATUS <> 3
GROUP BY TO_CHAR(SH_ADD_DATE,'yyyy') ,LTrim(TO_CHAR(SH_ADD_DATE,'MM')),LTrim(TO_CHAR(SH_ADD_DATE,'Month'))
order by 1


/*Total Lines by Month  all custs */
select  TO_CHAR(SL_EDIT_DATE,'yyyy') AS "SalesYear",
        LTrim(TO_CHAR(SL_EDIT_DATE,'MM')) AS "MONTHLY_SALES" ,
        LTrim(TO_CHAR(SL_EDIT_DATE,'Month')) AS "MONTHS" ,
        count(SL_ORDER) AS TotalOrders
FROM PWIN175.SL
WHERE SL_EDIT_DATE >= :start_date AND SL_EDIT_DATE <= :end_date
GROUP BY TO_CHAR(SL_EDIT_DATE,'yyyy') ,LTrim(TO_CHAR(SL_EDIT_DATE,'MM')),LTrim(TO_CHAR(SL_EDIT_DATE,'Month'))
order by 1


/*Storage SPaces filter by cust - list number of stocks by cust in locn*/  --10sec correct
SELECT Count(NI_STOCK) AS CountOfStocks, IL_LOCN, IL_IN_LOCN,
--SELECT NI_STOCK, IL_LOCN, IL_IN_LOCN,
      CASE WHEN Upper(IL_NOTE_2) = 'YES' THEN 'P' ELSE 'S' END AS "LocType", IM_CUST
			FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
			INNER JOIN IM ON IM_STOCK = NI_STOCK
			WHERE IM_ACTIVE = 1
      AND   IM_CUST = :cust
			AND NI_AVAIL_ACTUAL >= '1'
			AND NI_STATUS <> 0
      GROUP BY NI_STOCK,IL_LOCN,IL_NOTE_2, IM_CUST,IL_IN_LOCN


/*Storage SPaces filter by cust - list number of stocks by cust in locn*/
SELECT Count(DISTINCT NI_LOCN) AS CountOfStocks,
      IM_CUST,NI_LOCN
			FROM NI INNER JOIN IM ON IM_STOCK = NI_STOCK
			WHERE IM_ACTIVE = 1
      --AND   IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_TYPE = 0 AND RM_ACTIVE = 1 ) -- 89597 all custs
--:cust
       --AND IM_CUST IN (SELECT DISTINCT sGroupCust FROM Tmp_Group_Cust) --959 filtered by top level parent
			AND NI_AVAIL_ACTUAL >= '1'
			AND NI_STATUS <> 0
      GROUP BY IM_CUST,NI_LOCN
      HAVING Count(DISTINCT NI_LOCN) > 1

/*Storage SPaces total by cust - this give just a total*/
SELECT Count(DISTINCT IL_LOCN) AS CountOfSpaces, IM_CUST
      FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
			INNER JOIN IM ON IM_STOCK = NI_STOCK
			WHERE IM_ACTIVE = 1
      --AND   IM_CUST = :cust
			AND NI_AVAIL_ACTUAL >= '1'
			AND NI_STATUS <> 0
      AND substr(IL_NOTE_2,0,1) = 'Y'
      GROUP BY IM_CUST


/*Storage SPaces total by cust - this give just a total per shelves and pallets*/
SELECT IM_CUST,
      (SELECT Count(DISTINCT IL_LOCN)
        FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
			  INNER JOIN IM ON IM_STOCK = NI_STOCK
			  WHERE IM_ACTIVE = 1
        AND   IM_CUST = :cust
        AND Upper(substr(IL_NOTE_2,0,1)) = 'Y'
			  AND NI_AVAIL_ACTUAL >= '1'
			  AND NI_STATUS <> 0
        GROUP BY IM_CUST) AS CountOfPallets ,
      (SELECT Count(DISTINCT IL_LOCN)
        FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
			  INNER JOIN IM ON IM_STOCK = NI_STOCK
			  WHERE IM_ACTIVE = 1
        AND   IM_CUST = :cust
        AND Upper(substr(IL_NOTE_2,0,1)) = 'N'
			  AND NI_AVAIL_ACTUAL >= '1'
			  AND NI_STATUS <> 0
        GROUP BY IM_CUST) AS CountOfShelf
      FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
			INNER JOIN IM ON IM_STOCK = NI_STOCK
			WHERE IM_ACTIVE = 1
      AND   IM_CUST = :cust
			AND NI_AVAIL_ACTUAL >= '1'
			AND NI_STATUS <> 0
      GROUP BY IM_CUST


/*Storage SPaces total range cust - this give just a total per shelves and pallets*/
SELECT m.IM_CUST,
      (SELECT Count(DISTINCT l2.IL_LOCN)
        FROM IL l2 INNER JOIN NI n2  ON l2.IL_LOCN = n2.NI_LOCN
			  INNER JOIN IM i ON i.IM_STOCK = n2.NI_STOCK
			  WHERE i.IM_ACTIVE = 1
        AND   i.IM_CUST = m.IM_CUST
        AND Upper(substr(IL_NOTE_2,0,1)) = 'Y'
			  AND n2.NI_AVAIL_ACTUAL >= '1'
			  AND n2.NI_STATUS <> 0
        GROUP BY i.IM_CUST) AS CountOfPallets ,
      (SELECT Count(DISTINCT IL_LOCN)
        FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
			  INNER JOIN IM ON IM_STOCK = NI_STOCK
			  WHERE IM_ACTIVE = 1
        AND   IM_CUST = m.IM_CUST
        AND Upper(substr(IL_NOTE_2,0,1)) = 'N'
			  AND NI_AVAIL_ACTUAL >= '1'
			  AND NI_STATUS <> 0
        GROUP BY IM_CUST) AS CountOfShelf
      FROM IL l INNER JOIN NI n ON l.IL_LOCN = n.NI_LOCN
			INNER JOIN IM m ON m.IM_STOCK = n.NI_STOCK
			WHERE m.IM_ACTIVE = 1
      AND   m.IM_CUST >= :cust AND m.IM_CUST <= :cust2
			AND n.NI_AVAIL_ACTUAL >= '1'
			AND n.NI_STATUS <> 0
      GROUP BY m.IM_CUST
      ORDER BY m.IM_CUST ASC

/*Storage SPaces total all cust - this give just a total per shelves and pallets by Warehouse*/
SELECT m.IM_CUST,
      (SELECT Count(DISTINCT l2.IL_LOCN)
        FROM IL l2 INNER JOIN NI n2  ON l2.IL_LOCN = n2.NI_LOCN
			  INNER JOIN IM i ON i.IM_STOCK = n2.NI_STOCK
			  WHERE i.IM_ACTIVE = 1
        AND   i.IM_CUST = m.IM_CUST
        AND Upper(substr(IL_NOTE_2,0,1)) = 'Y'
			  AND n2.NI_AVAIL_ACTUAL >= '1'
			  AND n2.NI_STATUS <> 0
        GROUP BY i.IM_CUST) AS CountOfPallets ,
      (SELECT Count(DISTINCT IL_LOCN)
        FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
			  INNER JOIN IM ON IM_STOCK = NI_STOCK
			  WHERE IM_ACTIVE = 1
        AND   IM_CUST = m.IM_CUST
        AND Upper(substr(IL_NOTE_2,0,1)) = 'N'
			  AND NI_AVAIL_ACTUAL >= '1'
			  AND NI_STATUS <> 0
        GROUP BY IM_CUST) AS CountOfShelf
      FROM IL l INNER JOIN NI n ON l.IL_LOCN = n.NI_LOCN
			INNER JOIN IM m ON m.IM_STOCK = n.NI_STOCK
			WHERE m.IM_ACTIVE = 1
      AND n.NI_AVAIL_ACTUAL >= '1'
      --AND l.IL_IN_LOCN = :warehouse
      AND l.IL_IN_LOCN = :warehouse2
			AND n.NI_STATUS <> 0
      GROUP BY m.IM_CUST
      ORDER BY m.IM_CUST Asc
/*Use this one for Jason/Lawrence Reporting


/*Storage SPaces total all customers - this give just a total per shelves and pallets grouped by cust*/
SELECT IM_CUST,
      (SELECT Count(DISTINCT IL_LOCN)
        FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
			  INNER JOIN IM ON IM_STOCK = NI_STOCK
			  WHERE IM_ACTIVE = 1
        --AND   IM_CUST = :cust
        AND Upper(substr(IL_NOTE_2,0,1)) = 'Y'
			  AND NI_AVAIL_ACTUAL >= '1'
			  AND NI_STATUS <> 0) AS CountOfPallets ,
      (SELECT Count(DISTINCT IL_LOCN)
        FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
			  INNER JOIN IM ON IM_STOCK = NI_STOCK
			  WHERE IM_ACTIVE = 1
        --AND   IM_CUST = :cust
        AND Upper(substr(IL_NOTE_2,0,1)) = 'N'
			  AND NI_AVAIL_ACTUAL >= '1'
			  AND NI_STATUS <> 0) AS CountOfSpaces
      FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
			INNER JOIN IM ON IM_STOCK = NI_STOCK
			WHERE IM_ACTIVE = 1
      --AND   IM_CUST = :cust
			AND NI_AVAIL_ACTUAL >= '1'
			AND NI_STATUS <> 0
      GROUP BY IM_CUST



/*Storage SPaces total all cust - this give just a total per shelves and pallets by BOTH Warehouse*/
SELECT m.IM_CUST,l.IL_IN_LOCN,
SUM(CASE WHEN Upper(substr(IL_NOTE_2,0,1)) = 'Y' THEN 1 ELSE 0 END) AS CountOfPallets ,
SUM(CASE WHEN Upper(substr(IL_NOTE_2,0,1)) = 'N' THEN 1 ELSE 0 END) AS CountOfShelves
FROM  IL l INNER JOIN NI n ON l.IL_LOCN = n.NI_LOCN
      left outer JOIN IM m ON m.IM_STOCK = n.NI_STOCK
WHERE m.IM_ACTIVE = 1
AND n.NI_AVAIL_ACTUAL >= '1'
AND l.IL_IN_LOCN = :warehouse2
--OR l.IL_IN_LOCN = :warehouse2
AND n.NI_STATUS <> 0
GROUP BY m.IM_CUST,l.IL_IN_LOCN
ORDER BY l.IL_IN_LOCN,m.IM_CUST DESC


/*This should list all stocks within the location we are counting */
SELECT l.IL_LOCN AS Locn, i.IM_STOCK AS Stock, l.IL_NOTE_2 AS LocnType,
CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'P' ELSE 'S' END AS CountOfPS
--SUM(CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 1 ELSE 0 END) AS CountOfPallets ,
--SUM(CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'N' THEN 1 ELSE 0 END) AS CountOfShelves
FROM  IM i--, NA n, IL l, NE e
      INNER JOIN NA n ON n.NA_STOCK = i.IM_STOCK
      INNER JOIN IL l ON l.IL_UID = n.NA_EXT_KEY
      INNEr JOIN NE e ON e.NE_STOCK = i.IM_STOCK
WHERE i.IM_CUST = :cust
--AND n.NA_STOCK = i.IM_STOCK
AND   n.NA_EXT_TYPE = 1210067
--AND l.IL_UID = n.NA_EXT_KEY
AND e.NE_AVAIL_ACTUAL >= '1'
AND e.NE_ACCOUNT = n.NA_ACCOUNT
--AND l.IL_IN_LOCN = :warehouse
--OR l.IL_IN_LOCN = :warehouse2
AND e.NE_STATUS =  1
AND e.NE_STRENGTH = 1
--AND e.NE_NA_EXT_TYPE = n.NA_EXT_TYPE
--AND e.NE_NA_EXT_KEY = n.NA_EXT_KEY
--AND   i.IM_CUST = 'ZIONS'
--AND i.IM_STOCK = 'ZNSSBE3'

GROUP BY i.IM_CUST,l.IL_IN_LOCN, l.IL_LOCN, i.IM_STOCK, l.IL_NOTE_2
ORDER BY l.IL_IN_LOCN,i.IM_CUST DESC



/*This should list all stocks within the location we are counting */
SELECT l.IL_LOCN AS Locn, l.IL_NOTE_2 AS LocnType, n.NA_STOCK AS Stock, n.NA_ACCOUNT AS Account,
e.NE_STATUS, e.NE_STRENGTH, e.NE_REVERSES, Count(*), i.IM_CUST,
SUM(CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 1 ELSE 0 END) AS CountOfPallets
--SUM(CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'N' THEN 1 ELSE 0 END) AS CountOfShelves,
--CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'P' ELSE 'S' END AS CountOfPS
FROM  NA n, IL l, NE e, IM i
WHERE n.NA_STOCK = i.IM_STOCK
AND   n.NA_EXT_TYPE = 1210067

AND l.IL_UID = n.NA_EXT_KEY
AND e.NE_AVAIL_ACTUAL >= '1'
AND e.NE_ACCOUNT = n.NA_ACCOUNT
--AND l.IL_IN_LOCN = :warehouse
AND l.IL_IN_LOCN = :warehouse2
AND e.NE_STATUS =  1
AND e.NE_STRENGTH = 3
--AND e.NE_NA_EXT_TYPE = n.NA_EXT_TYPE
--AND e.NE_NA_EXT_KEY = n.NA_EXT_KEY
--AND   i.IM_CUST = :cust
--AND i.IM_STOCK = 'ZNSSBE3'

GROUP BY i.IM_CUST,l.IL_IN_LOCN, l.IL_LOCN, n.NA_STOCK, l.IL_NOTE_2,n.NA_ACCOUNT,e.NE_STATUS, e.NE_STRENGTH, e.NE_REVERSES
ORDER BY l.IL_IN_LOCN,i.IM_CUST DESC
/*needs a self join to stop counting dupes*/


/*This should list Total spaces by type grouped by warehouse and by customer */
SELECT i.IM_CUST, l.IL_IN_LOCN, Count(DISTINCT l.IL_LOCN), --Upper(l.IL_NOTE_2)
--SUM(CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN Count(DISTINCT l.IL_LOCN) ELSE 0 END) AS CountOfPallets,
--SUM(CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'N' THEN Count(DISTINCT l.IL_LOCN) ELSE 0 END) AS CountOfShelves,
--Sum(Count(DISTINCT l.IL_LOCN))
CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'P' ELSE 'S' END AS CountOfPS
FROM  NA n, IL l, NE e, IM i
WHERE n.NA_STOCK = i.IM_STOCK
AND   n.NA_EXT_TYPE = 1210067
AND l.IL_UID = n.NA_EXT_KEY
AND e.NE_AVAIL_ACTUAL >= '1'
AND e.NE_ACCOUNT = n.NA_ACCOUNT
--AND l.IL_IN_LOCN = :warehouse
--OR l.IL_IN_LOCN = :warehouse2
AND e.NE_STATUS =  1
AND e.NE_STRENGTH = 3
--AND e.NE_NA_EXT_TYPE = n.NA_EXT_TYPE
--AND e.NE_NA_EXT_KEY = n.NA_EXT_KEY
AND   i.IM_CUST = 'TABCORP'
--AND i.IM_STOCK = 'ZNSSBE3'

GROUP BY i.IM_CUST, l.IL_IN_LOCN, Upper(substr(l.IL_NOTE_2,0,1)) --, --Upper(l.IL_NOTE_2)--, Sum(Count(DISTINCT l.IL_LOCN))
--, l.IL_LOCN, n.NA_STOCK, l.IL_NOTE_2,n.NA_ACCOUNT,e.NE_STATUS, e.NE_STRENGTH, e.NE_REVERSES
ORDER BY l.IL_IN_LOCN,i.IM_CUST DESC


/*This should list Total spaces by type grouped by warehouse for all customers */
SELECT i.IM_CUST, l.IL_IN_LOCN, Count(DISTINCT l.IL_LOCN), --Upper(l.IL_NOTE_2)
--SUM(CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN Count(DISTINCT l.IL_LOCN) ELSE 0 END) AS CountOfPallets,
--SUM(CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'N' THEN Count(DISTINCT l.IL_LOCN) ELSE 0 END) AS CountOfShelves,
--Sum(Count(DISTINCT l.IL_LOCN))
CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'P' ELSE 'S' END AS CountOfPS
FROM  NA n, IL l, NE e, IM i
WHERE n.NA_STOCK = i.IM_STOCK
AND   n.NA_EXT_TYPE = 1210067
AND l.IL_UID = n.NA_EXT_KEY
AND e.NE_AVAIL_ACTUAL >= '1'
AND e.NE_ACCOUNT = n.NA_ACCOUNT
--AND l.IL_IN_LOCN = :warehouse
--OR l.IL_IN_LOCN = :warehouse2
AND e.NE_STATUS =  1
AND e.NE_STRENGTH = 3
--AND e.NE_NA_EXT_TYPE = n.NA_EXT_TYPE
--AND e.NE_NA_EXT_KEY = n.NA_EXT_KEY
AND   i.IM_CUST = 'TABCORP'
--AND i.IM_STOCK = 'ZNSSBE3'

GROUP BY i.IM_CUST, l.IL_IN_LOCN, Upper(substr(l.IL_NOTE_2,0,1)) --, --Upper(l.IL_NOTE_2)--, Sum(Count(DISTINCT l.IL_LOCN))
--, l.IL_LOCN, n.NA_STOCK, l.IL_NOTE_2,n.NA_ACCOUNT,e.NE_STATUS, e.NE_STRENGTH, e.NE_REVERSES
ORDER BY l.IL_IN_LOCN,i.IM_CUST DESC




/*Storage SPaces total all cust - this give just a total per shelves and pallets by Warehouse*/

SELECT m.IM_CUST,l.IL_IN_LOCN,
      (SELECT Count(DISTINCT l2.IL_LOCN)
        FROM IL l2 INNER JOIN NI n2  ON l2.IL_LOCN = n2.NI_LOCN
			  INNER JOIN IM i ON i.IM_STOCK = n2.NI_STOCK
			  WHERE i.IM_ACTIVE = 1
        AND   i.IM_CUST = 'RTA'
        AND Upper(substr(IL_NOTE_2,0,1)) = 'Y'
			  AND n2.NI_AVAIL_ACTUAL >= '1'
			  AND n2.NI_STATUS <> 0
        AND l2.IL_IN_LOCN = :warehouse
        OR l2.IL_IN_LOCN = :warehouse2
        GROUP BY i.IM_CUST) AS CountOfPallets ,
      (SELECT Count(DISTINCT IL_LOCN)
        FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
			  INNER JOIN IM ON IM_STOCK = NI_STOCK
			  WHERE IM_ACTIVE = 1
        AND   IM_CUST = m.IM_CUST
        AND Upper(substr(IL_NOTE_2,0,1)) = 'N'
			  AND NI_AVAIL_ACTUAL >= '1'
			  AND NI_STATUS <> 0
        AND IL_IN_LOCN = :warehouse
        OR IL_IN_LOCN = :warehouse2
        GROUP BY IM_CUST) AS CountOfShelf
      FROM IL l INNER JOIN NI n ON l.IL_LOCN = n.NI_LOCN
			left outer JOIN IM m ON m.IM_STOCK = n.NI_STOCK
			WHERE m.IM_ACTIVE = 1
      AND n.NI_AVAIL_ACTUAL >= '1'
      AND l.IL_IN_LOCN = :warehouse
      OR l.IL_IN_LOCN = :warehouse2
			AND n.NI_STATUS <> 0
      AND   m.IM_CUST = 'RTA'
      GROUP BY m.IM_CUST,l.IL_IN_LOCN
      ORDER BY l.IL_IN_LOCN,m.IM_CUST Desc
/*Use this one for Jason/Lawrence Reporting     */

/*test for pallet count */
SELECT Count(DISTINCT l2.IL_LOCN),l2.IL_IN_LOCN,i.IM_CUST
        FROM IL l2 INNER JOIN NI n2  ON l2.IL_LOCN = n2.NI_LOCN
			  INNER JOIN IM i ON i.IM_STOCK = n2.NI_STOCK
			  WHERE i.IM_ACTIVE = 1
        AND   i.IM_CUST = 'RTA'
        AND Upper(substr(IL_NOTE_2,0,1)) = 'Y'
			  AND n2.NI_AVAIL_ACTUAL >= '1'
			  AND n2.NI_STATUS <> 0
        AND l2.IL_IN_LOCN = :warehouse
        OR l2.IL_IN_LOCN = :warehouse2
        GROUP BY i.IM_CUST,l2.IL_IN_LOCN AS CountOfPallets


/*This should list Total spaces by type grouped by warehouse by 1 customers */
SELECT i.IM_CUST, l.IL_LOCN, Count(l.IL_IN_LOCN),l.IL_IN_LOCN, --Upper(l.IL_NOTE_2)
--SUM(CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN Count(DISTINCT l.IL_LOCN) ELSE 0 END) AS CountOfPallets,
--SUM(CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'N' THEN Count(DISTINCT l.IL_LOCN) ELSE 0 END) AS CountOfShelves,
--Sum(Count(DISTINCT l.IL_LOCN))
CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'P' ELSE 'S' END AS CountOfPS,n.NA_STOCK
FROM  NA n, IL l, NE e, IM i
WHERE n.NA_STOCK = i.IM_STOCK
AND   n.NA_EXT_TYPE = 1210067
AND l.IL_UID = n.NA_EXT_KEY
AND e.NE_AVAIL_ACTUAL >= '1'
AND e.NE_ACCOUNT = n.NA_ACCOUNT
--AND l.IL_IN_LOCN = :warehouse
--OR l.IL_IN_LOCN = :warehouse2
AND e.NE_STATUS =  1
AND e.NE_STRENGTH = 3
--AND e.NE_NA_EXT_TYPE = n.NA_EXT_TYPE
--AND e.NE_NA_EXT_KEY = n.NA_EXT_KEY
AND   i.IM_CUST IN ('21COCACOLA','21FINEDU','21IOOF','21ROADFILM','21TRANSER','31PRIIFE','41FKP')
--AND i.IM_STOCK = 'ZNSSBE3'

GROUP BY i.IM_CUST, l.IL_IN_LOCN,l.IL_LOCN, (CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'P' ELSE 'S' END),n.NA_STOCK --, --Upper(l.IL_NOTE_2)--, Sum(Count(DISTINCT l.IL_LOCN))
--, l.IL_LOCN, n.NA_STOCK, l.IL_NOTE_2,n.NA_ACCOUNT,e.NE_STATUS, e.NE_STRENGTH, e.NE_REVERSES
ORDER BY l.IL_IN_LOCN,i.IM_CUST DESC



/*This should list Total receipts by type grouped by warehouse for all customers */ --1.1s   Total is 2643
SELECT l.IL_IN_LOCN AS Warehouse,
       i.IM_CUST AS Cust,
       Count(e.NE_ENTRY) AS Total,
       'D- Receipts'  AS "Type"
FROM  NA n INNER JOIN IL l ON l.IL_UID = n.NA_EXT_KEY
           INNER JOIN NE e ON e.NE_ACCOUNT = n.NA_ACCOUNT
           INNER JOIN IM i ON i.IM_STOCK = n.NA_STOCK
WHERE n.NA_EXT_TYPE = 1210067
AND   l.IL_IN_LOCN NOT IN ('OBSOLETEMEL','OBSOLETESYD','PASTHISTORY', 'CANBERRA')
AND   IL_PHYSICAL = 1
AND   e.NE_QUANTITY >= '1'
AND   e.NE_TRAN_TYPE =  1
AND   e.NE_STRENGTH = 3
AND   (e.NE_STATUS = 1 OR e.NE_STATUS = 3)
AND   e.NE_DATE >= :start_date AND e.NE_DATE <= :end_date
AND IM_CUST = :cust
GROUP BY ROLLUP (l.IL_IN_LOCN,i.IM_CUST)
--ORDER BY 2,1

