var cust varchar2(20)
exec :cust := 'TABCORP'
var cust2 varchar2(20)
exec :cust2 := 'TABCORP'
var ordernum varchar2(20)
exec :ordernum := '1363806'
var stock varchar2(20)
exec :stock := 'COURIER'
var source varchar2(20)
exec :source := 'BSPRINTNSW'
var anal varchar2(20)
exec :anal := '21VICP'
var start_date varchar2(20)
exec :start_date := To_Date('01-Dec-2013')
var end_date varchar2(20)
exec :end_date := To_Date('31-Mar-2014')
var warehouse varchar2(20)
exec :warehouse := 'SYDNEY'
var warehouse2 varchar2(20)
exec :warehouse2 := 'MELBOURNE'
var month_date varchar2(20)
exec :month_date := substr(:end_date,4,3)
var year_date varchar2(20)
exec :year_date := substr(:end_date,8,2)



/*
SELECT NI_STOCK, NI_TRAN_TYPE, NI_QUANTITY, NI_DATE, IM_CUST, NI_STRENGTH, NI_STATUS
FROM NI INNER JOIN IM ON IM_STOCK = NI_STOCK
WHERE NI_TRAN_TYPE IN (  1 ,3,4,5)
AND   NI_STRENGTH = 3
AND   (NI_STATUS = 1 OR NI_STATUS = 3)
AND NI_ADD_DATE >= :start_date AND NI_ADD_DATE <= :end_date
AND IM_CUST = 'CROWN'
                 */
--SELECT * FROM NI WHERE NI_CUST = 'CROWN'
--Clear All Data
--Must run EOM_INVOICING_CREATE_TABLES first
TRUNCATE TABLE Tmp_Log_stats;
--Total Union Query takes 20s
/*Total Orders by Month all custs grouped by warehouse/top level parent */  --  2.12s
INSERT INTO Tmp_Log_stats (sCust, sWarehouse, nGrpID, nTotal, sType)

/*SELECT   CASE Grouping(l.IL_IN_LOCN)
          WHEN 1 THEN 'All Warehouses in all states'
          ELSE l.IL_IN_LOCN
          END AS Warehouse,
       CASE Grouping(r.sGroupCust)
        WHEN 1 THEN 'All Custs in ' ||
                                       (CASE
                                        WHEN l.IL_IN_LOCN IS NULL THEN 'all states.'
                                        ELSE l.IL_IN_LOCN
                                        END )
        ELSE r.sGroupCust
        END AS Customer,

            Count(DISTINCT(SD_ORDER)) AS Total,
            --Count(DISTINCT(SD_ORDER)) AS SDCount,
            'A- Orders' AS "Type"--, Count(SD_ORDER) AS SDCount
FROM SH h LEFT JOIN Tmp_Group_Cust r ON r.sCust = h.SH_CUST
     RIGHT JOIN SD d ON d.SD_ORDER = h.SH_ORDER
     INNER JOIN RM r2 ON r2.RM_CUST = h.SH_CUST
      INNER JOIN IL l ON l.IL_LOCN = d.SD_LOCN

WHERE h.SH_ADD_DATE >= :start_date AND h.SH_ADD_DATE <= :end_date
AND h.SH_STATUS <> 3
AND h.SH_CAMPAIGN NOT IN( 'ADMIN','OBSOLETE')
--AND d.SD_DISPLAY = 1
--AND d.SD_STOCK NOT IN('COURIER','COURIERM','COURIERS')
AND r2.RM_ACTIVE = 1   --This was the problem
--AND r.sGroupCust = 'TOYFIN'
GROUP BY ROLLUP (l.IL_IN_LOCN, sGroupCust  )
                             --151 rows in 2.92sec
ORDER BY 1,2 ASC   */


SELECT    CASE Grouping(r.sGroupCust)
        WHEN 1 THEN 'All Custs in ' ||
                                       (CASE
                                        WHEN (CASE
                                                WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'S' THEN 'SYDNEY'
                                                WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'H' THEN 'SYDNEY'
                                                WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'R' THEN 'SYDNEY'
                                                WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'M' THEN 'MELBOURNE'
                                                WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'O' THEN 'OBSOLETE'
                                                WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'D' THEN 'DMMETLIFE'
                                                WHEN Upper(d.SD_LOCN) = 'FLOORM' THEN 'MELBOURNE'
                                                WHEN Upper(d.SD_LOCN) = 'FLOORS' THEN 'SYDNEY'
                                                WHEN Upper(d.SD_LOCN) = 'FLOOR' THEN 'FLOOR'
                                                ELSE d.SD_LOCN
                                                END) IS NULL THEN 'all states.'
                                        ELSE (CASE
                                                WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'S' THEN 'SYDNEY'
                                                WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'H' THEN 'SYDNEY'
                                                WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'R' THEN 'SYDNEY'
                                                WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'M' THEN 'MELBOURNE'
                                                WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'O' THEN 'OBSOLETE'
                                                WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'D' THEN 'DMMETLIFE'
                                                WHEN Upper(d.SD_LOCN) = 'FLOORM' THEN 'MELBOURNE'
                                                WHEN Upper(d.SD_LOCN) = 'FLOORS' THEN 'SYDNEY'
                                                WHEN Upper(d.SD_LOCN) = 'FLOOR' THEN 'FLOOR'
                                                ELSE d.SD_LOCN
                                                END)
                                        END )
        ELSE r.sGroupCust
        END AS Customer,
        CASE
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'S' THEN 'SYDNEY'
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'H' THEN 'SYDNEY'
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'R' THEN 'SYDNEY'
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'M' THEN 'MELBOURNE'
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'O' THEN 'OBSOLETE'
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'D' THEN 'DMMETLIFE'
            WHEN Upper(d.SD_LOCN) = 'FLOORM' THEN 'MELBOURNE'
            WHEN Upper(d.SD_LOCN) = 'FLOORS' THEN 'SYDNEY'
            WHEN Upper(d.SD_LOCN) = 'FLOOR' THEN 'FLOOR'
            ELSE d.SD_LOCN
            END AS Warehouse,
             GROUPING_ID(r.sGroupCust) AS Grp_Id,
            Count(DISTINCT(SD_ORDER)) AS Total,
            --Count(DISTINCT(SD_ORDER)) AS SDCount,
            'A- Orders' AS "Type"--, Count(SD_ORDER) AS SDCount
FROM SH h LEFT JOIN Tmp_Group_Cust r ON r.sCust = h.SH_CUST
     RIGHT JOIN SD d ON d.SD_ORDER = h.SH_ORDER
     INNER JOIN RM r2 ON r2.RM_CUST = h.SH_CUST
WHERE h.SH_ADD_DATE >= :start_date AND h.SH_ADD_DATE <= :end_date
AND h.SH_STATUS <> 3
AND h.SH_CAMPAIGN NOT IN( 'ADMIN','OBSOLETE')
--AND d.SD_DISPLAY = 1
--AND d.SD_STOCK NOT IN('COURIER','COURIERM','COURIERS')
AND r2.RM_ACTIVE = 1   --This was the problem
--AND r.sGroupCust = 'TOYFIN'
GROUP BY ROLLUP (
                ( CASE
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'S' THEN 'SYDNEY'
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'H' THEN 'SYDNEY'
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'R' THEN 'SYDNEY'
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'M' THEN 'MELBOURNE'
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'O' THEN 'OBSOLETE'
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'D' THEN 'DMMETLIFE'
            WHEN Upper(d.SD_LOCN) = 'FLOORM' THEN 'MELBOURNE'
            WHEN Upper(d.SD_LOCN) = 'FLOORS' THEN 'SYDNEY'
            WHEN Upper(d.SD_LOCN) = 'FLOOR' THEN 'FLOOR'
            ELSE d.SD_LOCN
            END
                ),
                sGroupCust)
--ORDER BY 2,3  Asc


UNION ALL

/*Total Despatches by Month all custs grouped by warehouse/grouped cust   --  1.5s  Total Count 15381  --126   --1.34 s  126
--155 rows in 2.67s
SELECT   CASE Grouping(r.sGroupCust)
            WHEN 1 THEN 'All Custs in ' ||
                                       (CASE
                                        WHEN l.IL_IN_LOCN IS NULL THEN 'all states.'
                                        ELSE l.IL_IN_LOCN
                                        END )
            ELSE r.sGroupCust
        END AS Customer,
        CASE Grouping(l.IL_IN_LOCN)
          WHEN 1 THEN 'All Warehouses in all states'
          ELSE l.IL_IN_LOCN
        END AS Warehouse,
        Count(*) AS Total,
        'B- Despatches' AS "Type"
FROM  PWIN175.ST t INNER JOIN SL s ON s.SL_PICK = t.ST_PICK
      INNER JOIN SH h ON h.SH_ORDER = t.ST_ORDER
      LEFT JOIN Tmp_Group_Cust r ON r.sCust = h.SH_CUST
      INNER JOIN RM r2 ON r2.RM_CUST = h.SH_CUST
      INNER JOIN IL l ON l.IL_LOCN = s.SL_LOCN
WHERE t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
AND s.SL_LINE = 1
AND t.ST_PSLIP IS NOT NULL AND t.ST_PSLIP <> 'CANCELLED'
AND h.SH_STATUS <> 3
AND h.SH_CAMPAIGN NOT IN( 'ADMIN','OBSOLETE')
GROUP BY ROLLUP ( l.IL_IN_LOCN, sGroupCust )
                                                */


/*Total Despatches by Month all custs grouped by warehouse/grouped cust GROUPING_ID*/  --  1.5s  Total Count 15381  --126   --1.34 s  126
--155 rows in 2.77s

SELECT   CASE Grouping(r.sGroupCust)
        WHEN 1 THEN 'All Custs in ' ||
                                       (CASE
                                        WHEN l.IL_IN_LOCN IS NULL THEN 'all states.'
                                        ELSE l.IL_IN_LOCN
                                        END )
        ELSE r.sGroupCust
        END AS Customer,
        CASE Grouping(l.IL_IN_LOCN)
          WHEN 1 THEN 'All Warehouses in all states'
          ELSE l.IL_IN_LOCN
          END AS Warehouse,

       GROUPING_ID(r.sGroupCust,l.IL_IN_LOCN) AS Grp_Id,
            Count(*) AS Total,
            'B- Despatches' AS "Type"
           --t.ST_PICK,
           --h.SH_CAMPAIGN
FROM  PWIN175.ST t INNER JOIN SL s ON s.SL_PICK = t.ST_PICK
      INNER JOIN SH h ON h.SH_ORDER = t.ST_ORDER--RIGHT JOIN SD d ON d.SD_ORDER = h.SH_ORDER
      LEFT JOIN Tmp_Group_Cust r ON r.sCust = h.SH_CUST
      INNER JOIN RM r2 ON r2.RM_CUST = h.SH_CUST
       INNER JOIN IL l ON l.IL_LOCN = s.SL_LOCN

      --RIGHT JOIN SL s ON s.SL_PICK = t.ST_PICK

WHERE t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
AND s.SL_LINE = 1
AND t.ST_PSLIP IS NOT NULL AND t.ST_PSLIP <> 'CANCELLED'
AND h.SH_STATUS <> 3
AND h.SH_CAMPAIGN NOT IN( 'ADMIN','OBSOLETE')
AND r2.RM_ACTIVE = 1   --This was the problem
GROUP BY ROLLUP ( l.IL_IN_LOCN, sGroupCust )
--HAVING GROUPING_ID(r.sGroupCust,l.IL_IN_LOCN) > 0



/*Total Despatches by Month all custs grouped by warehouse only   --  1.5s  Total Count 15381  --126   --1.34 s  126

SELECT   CASE Grouping(r.sGroupCust)
        WHEN 1 THEN 'All Custs in ' ||
                                       (CASE
                                        WHEN l.IL_IN_LOCN IS NULL THEN 'all states.'
                                        ELSE l.IL_IN_LOCN
                                        END )
        ELSE r.sGroupCust
        END AS Customer,
        CASE Grouping(l.IL_IN_LOCN)
          WHEN 1 THEN 'All Warehouses in all states'
          ELSE l.IL_IN_LOCN
          END AS Warehouse,

       GROUPING_ID(r.sGroupCust,l.IL_IN_LOCN) AS Grp_Id,
            Count(*) AS Total,
            'B- Despatches' AS "Type"
           --t.ST_PICK,
           --h.SH_CAMPAIGN
FROM  PWIN175.ST t INNER JOIN SL s ON s.SL_PICK = t.ST_PICK
      INNER JOIN SH h ON h.SH_ORDER = t.ST_ORDER--RIGHT JOIN SD d ON d.SD_ORDER = h.SH_ORDER
      LEFT JOIN Tmp_Group_Cust r ON r.sCust = h.SH_CUST
      INNER JOIN RM r2 ON r2.RM_CUST = h.SH_CUST
       INNER JOIN IL l ON l.IL_LOCN = s.SL_LOCN

      --RIGHT JOIN SL s ON s.SL_PICK = t.ST_PICK

WHERE t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
AND s.SL_LINE = 1
AND t.ST_PSLIP IS NOT NULL AND t.ST_PSLIP <> 'CANCELLED'
AND h.SH_STATUS <> 3
AND h.SH_CAMPAIGN NOT IN( 'ADMIN','OBSOLETE')
AND r2.RM_ACTIVE = 1   --This was the problem
GROUP BY ROLLUP ( l.IL_IN_LOCN, sGroupCust )
HAVING GROUPING_ID(r.sGroupCust,l.IL_IN_LOCN) > 0      */


UNION ALL

/*Total Lines by Month all custs grouped by warehouse/top level grouped cust */  --  7.8s   total count 62068

SELECT   CASE Grouping(r.sGroupCust)
        WHEN 1 THEN 'All Custs in ' ||
                                       (CASE
                                        WHEN l.IL_IN_LOCN IS NULL THEN 'all states.'
                                        ELSE l.IL_IN_LOCN
                                        END )
        ELSE r.sGroupCust
        END AS Customer,
        CASE Grouping(l.IL_IN_LOCN)
          WHEN 1 THEN 'All Warehouses in all states'
          ELSE l.IL_IN_LOCN
          END AS Warehouse,

        GROUPING_ID(r.sGroupCust,l.IL_IN_LOCN) AS Grp_Id,
            Count(*) AS Total,
            'C- Lines' AS "Type"
FROM  PWIN175.SL s INNER JOIN SH h ON s.SL_ORDER = h.SH_ORDER
      LEFT JOIN Tmp_Group_Cust r ON r.sCust = h.SH_CUST
      --RIGHT JOIN SD d ON d.SD_ORDER = h.SH_ORDER
      INNER JOIN RM r2 ON r2.RM_CUST = h.SH_CUST
      INNER JOIN IL l ON l.IL_LOCN = s.SL_LOCN
      INNER JOIN ST t ON t.ST_PICK = s.SL_PICK
WHERE s.SL_EDIT_DATE >= :start_date AND s.SL_EDIT_DATE <= :end_date
AND s.SL_PSLIP IS NOT NULL
AND h.SH_CAMPAIGN NOT IN( 'ADMIN','OBSOLETE')
AND r2.RM_ACTIVE = 1   --This was the problem
GROUP BY ROLLUP (l.IL_IN_LOCN,r.sGroupCust)





--All Lines by Month all custs by warehouse/top level grouped cust   --  11s   total count 62068
--Jason will use this in addition to the grouped data as he need the splits for TABCORP - set cust2 var as TABCORP first
 /*
SELECT (CASE
            WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'S' THEN 'SYDNEY'
            WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'H' THEN 'SYDNEY'
            WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'R' THEN 'SYDNEY'
            WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'M' THEN 'MELBOURNE'
            WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'O' THEN 'OBSOLETE'
            WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'D' THEN 'DMMETLIFE'
            WHEN Upper(s.SL_LOCN) = 'FLOORM' THEN 'MELBOURNE'
            WHEN Upper(s.SL_LOCN) = 'FLOORS' THEN 'SYDNEY'
            WHEN Upper(s.SL_LOCN) = 'FLOOR' THEN 'FLOOR'
            ELSE 'NOLOCN'
            END) AS Warehouse,
            sGroupCust,
            sCust,
            h.SH_ORDER,
            s.SL_PICK,
            s.SL_PSLIP,
            d.SD_STOCK,
            Count(*) AS Total,
            'C- Lines' AS "Type"
FROM  PWIN175.SL s INNER JOIN SH h ON s.SL_ORDER = h.SH_ORDER
      LEFT JOIN Tmp_Group_Cust r ON r.sCust = h.SH_CUST
      LEFT JOIN SD d ON d.SD_ORDER = h.SH_ORDER
      INNER JOIN RM r2 ON r2.RM_CUST = h.SH_CUST
      --INNER JOIN IL l ON l.IL_LOCN = s.SL_LOCN
      INNER JOIN ST t ON t.ST_PICK = s.SL_PICK
WHERE s.SL_EDIT_DATE >= :start_date AND s.SL_EDIT_DATE <= :end_date
AND s.SL_PSLIP IS NOT NULL
AND h.SH_CAMPAIGN NOT IN( 'ADMIN','OBSOLETE')
AND r2.RM_ACTIVE = 1   --This was the problem
AND sGroupCust = :cust2
GROUP BY ((CASE
            WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'S' THEN 'SYDNEY'
            WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'H' THEN 'SYDNEY'
            WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'R' THEN 'SYDNEY'
            WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'M' THEN 'MELBOURNE'
            WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'O' THEN 'OBSOLETE'
            WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'D' THEN 'DMMETLIFE'
            WHEN Upper(s.SL_LOCN) = 'FLOORM' THEN 'MELBOURNE'
            WHEN Upper(s.SL_LOCN) = 'FLOORS' THEN 'SYDNEY'
            WHEN Upper(s.SL_LOCN) = 'FLOOR' THEN 'FLOOR'
            ELSE 'NOLOCN'
            END),
            sGroupCust,
            sCust,
            h.SH_ORDER,
            s.SL_PICK,
            s.SL_PSLIP,
            d.SD_STOCK)

SELECT DISTINCT (d.SD_STOCK),(CASE
            WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'S' THEN 'SYDNEY'
            WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'H' THEN 'SYDNEY'
            WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'R' THEN 'SYDNEY'
            WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'M' THEN 'MELBOURNE'
            WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'O' THEN 'OBSOLETE'
            WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'D' THEN 'DMMETLIFE'
            WHEN Upper(s.SL_LOCN) = 'FLOORM' THEN 'MELBOURNE'
            WHEN Upper(s.SL_LOCN) = 'FLOORS' THEN 'SYDNEY'
            WHEN Upper(s.SL_LOCN) = 'FLOOR' THEN 'FLOOR'
            ELSE 'NOLOCN'
            END) AS Warehouse,
            sGroupCust,
            sCust,
            h.SH_ORDER,
            s.SL_PICK,
            s.SL_PSLIP,
            d.SD_STOCK,
            s.SL_PICK_QTY,
           -- Count(*) AS Total,
            'C- Lines' AS "Type"
FROM  PWIN175.SL s INNER JOIN SH h ON s.SL_ORDER = h.SH_ORDER
      LEFT JOIN Tmp_Group_Cust r ON r.sCust = h.SH_CUST
      LEFT JOIN SD d ON d.SD_ORDER = h.SH_ORDER
      --INNER JOIN RM r2 ON r2.RM_CUST = h.SH_CUST
      --INNER JOIN IL l ON l.IL_LOCN = s.SL_LOCN
      INNER JOIN ST t ON t.ST_PICK = s.SL_PICK
WHERE s.SL_EDIT_DATE >= :start_date AND s.SL_EDIT_DATE <= :end_date
AND s.SL_PSLIP IS NOT NULL
AND h.SH_CAMPAIGN NOT IN( 'ADMIN','OBSOLETE')
AND r2.RM_ACTIVE = 1   --This was the problem
AND sGroupCust = :cust2
AND h.SH_ORDEr = '   1459419'
GROUP BY ((CASE
            WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'S' THEN 'SYDNEY'
            WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'H' THEN 'SYDNEY'
            WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'R' THEN 'SYDNEY'
            WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'M' THEN 'MELBOURNE'
            WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'O' THEN 'OBSOLETE'
            WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'D' THEN 'DMMETLIFE'
            WHEN Upper(s.SL_LOCN) = 'FLOORM' THEN 'MELBOURNE'
            WHEN Upper(s.SL_LOCN) = 'FLOORS' THEN 'SYDNEY'
            WHEN Upper(s.SL_LOCN) = 'FLOOR' THEN 'FLOOR'
            ELSE 'NOLOCN'
            END),
            sGroupCust,
            sCust,
            h.SH_ORDER,
            s.SL_PICK,
            s.SL_PSLIP,
            d.SD_STOCK,s.SL_PICK_QTY)   */


SELECT DISTINCT(SD_STOCK), SL_LINE,SL_ORDER,SL_PICK, SL_PICK_QTY,  IL_IN_LOCN AS Warehouse,

           --Count(SELECT s.SL_LINE FROM SL s INNER JOIN IL l ON l.IL_LOCN = s.SL_LOCN WHERE s.SL_PICK = s1.SL_PICK AND l.IL_IN_LOCN = 'MELBOURNE') AS MTotal,
           --Count(SELECT s2.SL_LINE FROM SL s2 INNER JOIN IL l ON l.IL_LOCN = s2.SL_LOCN WHERE s2.SL_PICK = s1.SL_PICK AND l.IL_IN_LOCN = 'SYDNEY')  AS STotal,
            Count(SL_LINE) OVER (PARTITION BY IL_IN_LOCN) AS avg_dept_sal,


          'C- Lines' AS "Type"
    FROM SL s1 INNER JOIN SD ON  SD_LINE = s1.SL_ORDER_LINE
                  AND SD_ORDER = s1.SL_ORDER
    LEFT JOIN Tmp_Group_Cust r ON r.sCust = SD_CUST
    INNER JOIN IL ON IL_LOCN = s1.SL_LOCN
WHERE s1.SL_EDIT_DATE >= :start_date AND s1.SL_EDIT_DATE <= :end_date
AND   s1.SL_PSLIP IS NOT NULL
AND ((SELECT SH_CAMPAIGN FROM SH WHERE SH_ORDER = SD_ORDER) NOT IN( 'ADMIN','OBSOLETE'))
AND sGroupCust = :cust2
AND SD_ORDER = '   1459419'
GROUP BY ROLLUP (s1.SL_ORDER),s1.SL_ORDER, s1.SL_LINE,s1.SL_PICK, s1.SL_PICK_QTY, SD_STOCK,IL_IN_LOCN

UNION ALL

/*This should list Total receipts by type grouped by warehouse for all customers */ --1.1s   Total is 2643
SELECT  CASE Grouping(i.IM_CUST)
        WHEN 1 THEN 'All Custs in ' ||
                                       (CASE
                                        WHEN l.IL_IN_LOCN IS NULL THEN 'all states.'
                                        ELSE l.IL_IN_LOCN
                                        END )
        ELSE i.IM_CUST
        END AS Customer,
        CASE Grouping(l.IL_IN_LOCN)
          WHEN 1 THEN 'All Warehouses in all states'
          ELSE l.IL_IN_LOCN
          END AS Warehouse,
       GROUPING_ID(i.IM_CUST,l.IL_IN_LOCN) AS Grp_Id,
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
--AND IM_CUST = 'CROWN'
GROUP BY ROLLUP (l.IL_IN_LOCN,i.IM_CUST)
--ORDER BY 1


UNION ALL

/*This should list Total spaces by type grouped by warehouse for all customers */ --13.00s Total is 15131
/*SELECT
      CASE Grouping(i.IM_CUST)
        WHEN 1 THEN 'All Custs in ' ||
                                       (CASE
                                        WHEN l.IL_IN_LOCN IS NULL THEN 'all states.'
                                        ELSE l.IL_IN_LOCN
                                        END )
        ELSE i.IM_CUST
        END AS Customer,
       CASE Grouping(l.IL_IN_LOCN)
          WHEN 1 THEN 'All Warehouses in all states'
          ELSE l.IL_IN_LOCN
          END AS Warehouse,
       Count(DISTINCT l.IL_LOCN) AS Total,  -- test a self join to rid the distinct
       (CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                                                        ELSE 'F- Shelves'
        END) AS "Type"
FROM  NA n INNER JOIN IL l ON l.IL_UID = n.NA_EXT_KEY
           INNER JOIN NE e ON e.NE_ACCOUNT = n.NA_ACCOUNT
           INNER JOIN IM i ON i.IM_STOCK = n.NA_STOCK
          -- INNER JOIN Tmp_Group_Cust r ON r.sGroupCust = i.IM_CUST

WHERE n.NA_EXT_TYPE = 1210067
AND e.NE_AVAIL_ACTUAL >= '1'
AND l.IL_IN_LOCN NOT IN ('OBSOLETEMEL','OBSOLETESYD','PASTHISTORY', 'CANBERRA')
AND e.NE_STATUS =  1
AND e.NE_STRENGTH = 3
--AND i.IM_CUST = :cust
GROUP BY ROLLUP (i.IM_CUST,
       l.IL_IN_LOCN ,
       (CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                                                        ELSE 'F- Shelves'
        END) )



GROUP BY ROLLUP (l.IL_IN_LOCN,i.IM_CUST,CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                                                        ELSE 'F- Shelves'
        END )
HAVING  (CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                                                        ELSE 'F- Shelves'
        END ) IS NOT NULL   AND sWarehouse
/*((CASE
                  WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
                  WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
                  END),
                  i.IM_CUST )
                  , (CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                                                        ELSE 'F- Shelves'
        END)
ORDER BY 1,2,4    */
/*This one works and is the master for spaces occupied monthly by cust by warehouse. */
--243 rows in 2.1 s
/*SELECT
       CASE Grouping(i.IM_CUST)
        WHEN 1 THEN 'All Custs in ' ||
                                       (CASE
                                        WHEN l.IL_IN_LOCN IS NULL THEN 'all states.'
                                        ELSE l.IL_IN_LOCN
                                        END )
        ELSE i.IM_CUST
        END AS Customer,

      CASE
          WHEN l.IL_IN_LOCN IS NULL AND l.IL_LOCN IS NULL THEN 'NOLOCN'
            WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
            WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
            ELSE l.IL_IN_LOCN
          END AS Warehouse,

       GROUPING_ID(l.IL_IN_LOCN,i.IM_CUST,l.IL_LOCN,CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                                                        ELSE 'F- Shelves'
                                                     END) AS Grp_Id,

       Count(DISTINCT l.IL_LOCN) AS Total,

       (CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                                                        ELSE 'F- Shelves'
        END) AS "Type"

FROM  NA n INNER JOIN IL l ON l.IL_UID = n.NA_EXT_KEY
           INNER JOIN NE e ON e.NE_ACCOUNT = n.NA_ACCOUNT
           INNER JOIN IM i ON i.IM_STOCK = n.NA_STOCK
           --LEFT JOIN Tmp_Group_Cust r ON r.sGroupCust = i.IM_CUST

WHERE n.NA_EXT_TYPE = 1210067
AND e.NE_AVAIL_ACTUAL >= '1'
AND l.IL_IN_LOCN NOT IN ('OBSOLETEMEL','OBSOLETESYD','PASTHISTORY', 'CANBERRA')
AND e.NE_STATUS =  1
AND e.NE_STRENGTH = 3
--AND i.IM_CUST = :cust

GROUP BY i.IM_CUST,l.IL_IN_LOCN,l.IL_LOCN,CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                                                        ELSE 'F- Shelves'
                                                     END, ROLLUP (i.IM_CUST,l.IL_IN_LOCN,l.IL_LOCN,CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                                                        ELSE 'F- Shelves'
                                                     END)
 Grouping SETS(i.IM_CUST,l.IL_IN_LOCN,l.IL_LOCN,l.IL_NOTE_2),
                i.IM_CUST,
                  CASE
                        WHEN l.IL_IN_LOCN IS NULL AND l.IL_LOCN IS NULL THEN 'NOLOCN'
                        WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
                        WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
                        ELSE l.IL_IN_LOCN
                    END,
                 CASE
                    WHEN l.IL_IN_LOCN IS NULL THEN 'all states.'
                    ELSE l.IL_IN_LOCN
                 END
                      */


SELECT i.IM_CUST AS Cust,
       (CASE
        WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
        WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
        END) AS Warehouse,
       NULL AS Grp_Id,

       Count(DISTINCT l.IL_LOCN) AS Total,  -- test a self join to rid the distinct
       (CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                                                        ELSE 'F- Shelves'
        END) AS "Type"
FROM  NA n INNER JOIN IL l ON l.IL_UID = n.NA_EXT_KEY
           INNER JOIN NE e ON e.NE_ACCOUNT = n.NA_ACCOUNT
           INNER JOIN IM i ON i.IM_STOCK = n.NA_STOCK
           --LEFT JOIN Tmp_Group_Cust r ON r.sGroupCust = i.IM_CUST
WHERE n.NA_EXT_TYPE = 1210067
AND e.NE_AVAIL_ACTUAL >= '1'
AND l.IL_IN_LOCN NOT IN ('OBSOLETEMEL','OBSOLETESYD','PASTHISTORY', 'CANBERRA')
AND e.NE_STATUS =  1
AND e.NE_STRENGTH = 3
--AND i.IM_CUST = :cust
GROUP BY ROLLUP ((CASE
                  WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
                  WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
                  END),i.IM_CUST, (CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                                                                  ELSE 'F- Shelves'
                  END) )
HAVING i.IM_CUST IS NULL
AND (CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
          ELSE 'F- Shelves'
     END) IS NULL
AND (CASE
        WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
        WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
        END) IS NOT NULL
OR i.IM_CUST IS NOT NULL
AND (CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
          ELSE 'F- Shelves'
     END) IS NOT NULL

ORDER BY 1,2,4



/*
SELECT
       (CASE
        WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
        WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
        END) AS Warehouse,
       i.IM_CUST AS Cust,
       Count(DISTINCT l.IL_LOCN) AS Total,  -- test a self join to rid the distinct
       (CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                                                        ELSE 'F- Shelves'
        END) AS "Type"
FROM  NA n INNER JOIN IL l ON l.IL_UID = n.NA_EXT_KEY
           INNER JOIN NE e ON e.NE_ACCOUNT = n.NA_ACCOUNT
           INNER JOIN IM i ON i.IM_STOCK = n.NA_STOCK
           --LEFT JOIN Tmp_Group_Cust r ON r.sGroupCust = i.IM_CUST
WHERE n.NA_EXT_TYPE = 1210067
AND e.NE_AVAIL_ACTUAL >= '1'
AND l.IL_IN_LOCN NOT IN ('OBSOLETEMEL','OBSOLETESYD','PASTHISTORY', 'CANBERRA')
AND e.NE_STATUS =  1
AND e.NE_STRENGTH = 3
--AND i.IM_CUST = :cust
GROUP BY ROLLUP ((CASE
                  WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
                  WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
                  END),i.IM_CUST, (CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                                                                  ELSE 'F- Shelves'
                  END) )
/*SELECT * FROM Tmp_Log_stats
   ORDER BY 1,2,4   */

