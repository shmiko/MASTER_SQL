var cust varchar2(20)
exec :cust := 'RTA'
var cust2 varchar2(20)
exec :cust2 := 'BEYONDBLUE'
var ordernum varchar2(20)
exec :ordernum := '1363806'
var stock varchar2(20)
exec :stock := 'COURIER'
var source varchar2(20)
exec :source := 'BSPRINTNSW'
var anal varchar2(20)
exec :anal := '21VICP'
var start_date varchar2(20)
exec :start_date := To_Date('01-Jan-2014')
var end_date varchar2(20)
exec :end_date := To_Date('31-Jan-2014')
var warehouse varchar2(20)
exec :warehouse := 'SYDNEY'
var warehouse2 varchar2(20)
exec :warehouse2 := 'MELBOURNE'
var month_date varchar2(20)
exec :month_date := substr(:end_date,4,3)
var year_date varchar2(20)
exec :year_date := substr(:end_date,8,2)

/*Full Union Query takes 17.1s */

/*Total Despatches by Month all custs grouped by cust   --Need to add splits by warehouse   .8s
select  (CASE
            WHEN RM_PARENT = ' ' THEN SH_CUST
            WHEN RM_PARENT != ' ' THEN RM_PARENT
            ELSE NULL END) AS Cust,
            NULL AS Warehouse,
            count(ST_ORDER) AS Total,
            'Despatches' AS "Type"
FROM PWIN175.ST INNER JOIN SH ON SH_ORDER = ST_ORDER
      INNER JOIN RM ON RM_CUST = SH_CUST
WHERE ST_DESP_DATE >= :start_date AND ST_DESP_DATE <= :end_date AND ST_PSLIP <> 'CANCELLED'
GROUP BY  (CASE WHEN RM_PARENT = ' ' THEN SH_CUST
            WHEN RM_PARENT != ' ' THEN RM_PARENT
            ELSE NULL END)
--ORDER BY 1




UNION ALL


/*Total Orders by Month all custs grouped by cust  --Need to add splits by warehouse           .6s
select  (CASE
            WHEN RM_PARENT = ' ' THEN SH_CUST
            WHEN RM_PARENT != ' ' THEN RM_PARENT
            ELSE NULL END) AS Cust,
            NULL AS Warehouse,
            count(SH_ORDER) AS Total,
            'Orders' AS "Type"
FROM PWIN175.SH INNER JOIN RM ON RM_CUST = SH_CUST
WHERE SH_ADD_DATE >= :start_date AND SH_ADD_DATE <= :end_date AND SH_STATUS <> 3
GROUP BY  (CASE WHEN RM_PARENT = ' ' THEN SH_CUST
            WHEN RM_PARENT != ' ' THEN RM_PARENT
            ELSE NULL END)
ORDER BY 1

UNION ALL     */


/*Total Orders by Month all custs grouped by cust */  --  <1s

SELECT (CASE
            WHEN r.RM_PARENT = ' ' THEN h.SH_CUST
            WHEN r.RM_PARENT != ' ' THEN r.RM_PARENT
            ELSE NULL END) AS Cust,
            (CASE
                WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'S' THEN 'SYDNEY'
                WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'H' THEN 'SYDNEY'
                WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'R' THEN 'SYDNEY'
                WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'M' THEN 'MELBOURNE'
                WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'O' THEN 'OBSOLETE'
                --ELSE LTrim((SELECT IM_STD_VLOCN FROM IM WHERE IM_STOCK = d.SD_STOCK))
                ELSE m.IM_STD_VLOCN
                --ELSE Upper(SubStr(d.SD_LOCN,0,1)) END)
                -- ELSE NULL
                END) AS Warehouse,
            --d.SD_LOCN AS Warehouse,
            Count(*) AS Total,
            'A- Orders' AS "Type"
FROM SH h INNER JOIN RM r ON r.RM_CUST = h.SH_CUST
      INNER JOIN SD d ON d.SD_ORDER = h.SH_ORDER
      INNER JOIN IM m ON m.IM_STOCK = d.SD_STOCK
WHERE h.SH_ADD_DATE >= :start_date AND h.SH_ADD_DATE <= :end_date
AND d.SD_LINE = 1 -- OR d.SD_LINE = 2 OR d.SD_LINE =
AND h.SH_STATUS <> 3
AND h.SH_CAMPAIGN NOT LIKE 'ADMIN'
AND h.SH_CAMPAIGN NOT LIKE 'OBSOLETE'
GROUP BY (CASE
          WHEN r.RM_PARENT = ' ' THEN h.SH_CUST
          WHEN r.RM_PARENT != ' ' THEN r.RM_PARENT
          ELSE NULL END),
          --d.SD_LOCN,
          (CASE
                WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'S' THEN 'SYDNEY'
                WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'H' THEN 'SYDNEY'
                WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'R' THEN 'SYDNEY'
                WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'M' THEN 'MELBOURNE'
                WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'O' THEN 'OBSOLETE'
                --ELSE LTrim((SELECT IM_STD_VLOCN FROM IM WHERE IM_STOCK = d.SD_STOCK))
                ELSE m.IM_STD_VLOCN
                --ELSE Upper(SubStr(d.SD_LOCN,0,1)) END)
                -- ELSE NULL
                END)-- m.IM_STD_VLOCN--, d.SD_STOCK  */
--ORDER BY 1

UNION ALL

/*Total Despatches by Month all custs grouped by cust */  --  4.33s

SELECT (CASE
            WHEN r.RM_PARENT = ' ' THEN h.SH_CUST
            WHEN r.RM_PARENT != ' ' THEN r.RM_PARENT
            ELSE NULL END) AS Cust,
            l.IL_IN_LOCN AS Warehouse,
            Count(*) AS Total,
            'B- Despatches' AS "Type"
FROM PWIN175.SL s INNER JOIN SH h ON s.SL_ORDER = h.SH_ORDER
    INNER JOIN RM r ON r.RM_CUST = h.SH_CUST
    INNER JOIN IL l ON l.IL_LOCN = s.SL_LOCN
    INNER JOIN ST t ON t.ST_PICK = s.SL_PICK
--WHERE SL_ORDER = '   1504767' --AND SL_LINE = 1
WHERE s.SL_EDIT_DATE >= :start_date AND s.SL_EDIT_DATE <= :end_date
AND h.SH_CAMPAIGN NOT LIKE 'ADMIN'
AND h.SH_CAMPAIGN NOT LIKE 'OBSOLETE'
AND l.IL_IN_LOCN NOT LIKE '%HISTORY'
AND l.IL_IN_LOCN <> 'OBSOLETEMEL'
AND l.IL_IN_LOCN <> 'OBSOLETESYD'
AND l.IL_IN_LOCN <> 'CANBERRA'
--OR l.IL_IN_LOCN = :warehouse2
AND s.SL_PSLIP IS NOT NULL
AND SL_LINE = 1
GROUP BY l.IL_IN_LOCN,(CASE
            WHEN r.RM_PARENT = ' ' THEN h.SH_CUST
            WHEN r.RM_PARENT != ' ' THEN r.RM_PARENT
            ELSE NULL END)
--ORDER BY 1

UNION ALL

/*Total Lines by Month all custs grouped by cust */  --  4.33s

SELECT (CASE
            WHEN r.RM_PARENT = ' ' THEN h.SH_CUST
            WHEN r.RM_PARENT != ' ' THEN r.RM_PARENT
            ELSE NULL END) AS Cust,
            l.IL_IN_LOCN AS Warehouse,
            Count(*) AS Total,
            'C- Lines' AS "Type"
FROM PWIN175.SL s INNER JOIN SH h ON s.SL_ORDER = h.SH_ORDER
    INNER JOIN RM r ON r.RM_CUST = h.SH_CUST
    INNER JOIN IL l ON l.IL_LOCN = s.SL_LOCN
    INNER JOIN ST t ON t.ST_PICK = s.SL_PICK
--WHERE SL_ORDER = '   1504767' --AND SL_LINE = 1
WHERE s.SL_EDIT_DATE >= :start_date AND s.SL_EDIT_DATE <= :end_date
AND s.SL_PSLIP IS NOT NULL
AND h.SH_CAMPAIGN NOT LIKE 'ADMIN'
AND h.SH_CAMPAIGN NOT LIKE 'OBSOLETE'
AND l.IL_IN_LOCN NOT LIKE '%HISTORY'
AND l.IL_IN_LOCN <> 'OBSOLETEMEL'
AND l.IL_IN_LOCN <> 'OBSOLETESYD'
AND l.IL_IN_LOCN <> 'CANBERRA'
--OR l.IL_IN_LOCN = :warehouse2
--AND SL_LINE = 1
GROUP BY l.IL_IN_LOCN,(CASE
            WHEN r.RM_PARENT = ' ' THEN h.SH_CUST
            WHEN r.RM_PARENT != ' ' THEN r.RM_PARENT
            ELSE NULL END)
--ORDER BY 1



UNION ALL

/*This should list Total receipts by type grouped by warehouse for all customers */ --1.38s
SELECT i.IM_CUST AS Cust,
       l.IL_IN_LOCN AS Warehouse,
       Count(e.NE_ENTRY) AS Total,                          -- test a self join to rid the distinct
       'D- Receipts'  AS "Type"
FROM  NA n INNER JOIN IL l ON l.IL_UID = n.NA_EXT_KEY
           INNER JOIN NE e ON e.NE_ACCOUNT = n.NA_ACCOUNT
           INNER JOIN IM i ON i.IM_STOCK = n.NA_STOCK
WHERE e.NE_QUANTITY >= '1'
AND   e.NE_TRAN_TYPE =  1 --receipt
AND l.IL_IN_LOCN NOT LIKE '%HISTORY'
AND l.IL_IN_LOCN <> 'OBSOLETEMEL'
AND l.IL_IN_LOCN <> 'OBSOLETESYD'
AND l.IL_IN_LOCN <> 'CANBERRA'
AND   e.NE_STRENGTH = 3
AND   n.NA_EXT_TYPE = 1210067
AND   (e.NE_STATUS = 1 OR e.NE_STATUS = 3)
AND   e.NE_DATE >= :start_date AND e.NE_DATE <= :end_date
AND   IL_PHYSICAL = 1
GROUP BY i.IM_CUST, l.IL_IN_LOCN
--ORDER BY l.IL_IN_LOCN,i.IM_CUST Asc

UNION ALL

/*This should list Total spaces by type grouped by warehouse for all customers */ --11.90s  - now 4.2s
SELECT i.IM_CUST AS Cust,
       l.IL_IN_LOCN AS Warehouse,
       Count(DISTINCT l.IL_LOCN) AS Total,                          -- test a self join to rid the distinct
       (CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                                                        ELSE 'F- Shelves'
        END) AS "Type"
FROM  NA n INNER JOIN IL l ON l.IL_UID = n.NA_EXT_KEY
           INNER JOIN NE e ON e.NE_ACCOUNT = n.NA_ACCOUNT
           INNER JOIN IM i ON i.IM_STOCK = n.NA_STOCK
WHERE n.NA_EXT_TYPE = 1210067
AND e.NE_AVAIL_ACTUAL >= '1'
AND l.IL_IN_LOCN NOT LIKE '%HISTORY'
AND l.IL_IN_LOCN <> 'OBSOLETEMEL'
AND l.IL_IN_LOCN <> 'OBSOLETESYD'
AND l.IL_IN_LOCN <> 'CANBERRA'
--AND Upper(SubStr(l.IL_IN_LOCN, 0,1)) <> 'O'
--OR l.IL_IN_LOCN = :warehouse2
AND e.NE_STATUS =  1
AND e.NE_STRENGTH = 3
GROUP BY i.IM_CUST, l.IL_IN_LOCN,(CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                                                        ELSE 'F- Shelves'
        END)
ORDER BY 1,4
/*This one works and is the master for spaces occupied monthly by cust by warehouse. */

