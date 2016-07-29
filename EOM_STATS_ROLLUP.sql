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

/*Full Union Query takes 17.1s to 22.67s */



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
                ELSE m.IM_STD_VLOCN
                END) AS Warehouse,
              Count(*) AS Total,
            'A- Orders' AS "Type"
FROM SH h INNER JOIN RM r ON r.RM_CUST = h.SH_CUST
      INNER JOIN SD d ON d.SD_ORDER = h.SH_ORDER
      INNER JOIN IM m ON m.IM_STOCK = d.SD_STOCK
WHERE h.SH_ADD_DATE >= :start_date AND h.SH_ADD_DATE <= :end_date
AND d.SD_LINE = 1
AND h.SH_STATUS <> 3
AND h.SH_CAMPAIGN NOT LIKE 'ADMIN'
AND h.SH_CAMPAIGN NOT LIKE 'OBSOLETE'
GROUP BY ROLLUP ((CASE
                WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'S' THEN 'SYDNEY'
                WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'H' THEN 'SYDNEY'
                WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'R' THEN 'SYDNEY'
                WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'M' THEN 'MELBOURNE'
                WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'O' THEN 'OBSOLETE'
                ELSE m.IM_STD_VLOCN
                END),(CASE
          WHEN r.RM_PARENT = ' ' THEN h.SH_CUST
          WHEN r.RM_PARENT != ' ' THEN r.RM_PARENT
          ELSE NULL END))
--ORDER BY 2,1

UNION ALL

/*Total Despatches by Month all custs grouped by cust */  --  1.5s

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
WHERE s.SL_EDIT_DATE >= :start_date AND s.SL_EDIT_DATE <= :end_date
AND h.SH_CAMPAIGN NOT LIKE 'ADMIN'
AND h.SH_CAMPAIGN NOT LIKE 'OBSOLETE'
AND s.SL_PSLIP IS NOT NULL
AND SL_LINE = 1
GROUP BY ROLLUP (l.IL_IN_LOCN,(CASE
            WHEN r.RM_PARENT = ' ' THEN h.SH_CUST
            WHEN r.RM_PARENT != ' ' THEN r.RM_PARENT
            ELSE NULL END) )
--ORDER BY 2,1

UNION ALL

/*Total Lines by Month all custs grouped by cust */  --  5.7s

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
WHERE s.SL_EDIT_DATE >= :start_date AND s.SL_EDIT_DATE <= :end_date
AND s.SL_PSLIP IS NOT NULL
AND h.SH_CAMPAIGN NOT LIKE 'ADMIN'
AND h.SH_CAMPAIGN NOT LIKE 'OBSOLETE'
GROUP BY ROLLUP (l.IL_IN_LOCN,(CASE
            WHEN r.RM_PARENT = ' ' THEN h.SH_CUST
            WHEN r.RM_PARENT != ' ' THEN r.RM_PARENT
            ELSE NULL END))
--ORDER BY 2,1



UNION ALL

/*This should list Total receipts by type grouped by warehouse for all customers */ --1.1s
SELECT i.IM_CUST AS Cust,
       l.IL_IN_LOCN AS Warehouse,
       Count(e.NE_ENTRY) AS Total,
       'D- Receipts'  AS "Type"
FROM  NA n INNER JOIN IL l ON l.IL_UID = n.NA_EXT_KEY
           INNER JOIN NE e ON e.NE_ACCOUNT = n.NA_ACCOUNT
           INNER JOIN IM i ON i.IM_STOCK = n.NA_STOCK
WHERE e.NE_QUANTITY >= '1'
AND   e.NE_TRAN_TYPE =  1
AND l.IL_IN_LOCN NOT IN ('OBSOLETEMEL','OBSOLETESYD')
AND   e.NE_STRENGTH = 3
AND   n.NA_EXT_TYPE = 1210067
AND   (e.NE_STATUS = 1 OR e.NE_STATUS = 3)
AND   e.NE_DATE >= :start_date AND e.NE_DATE <= :end_date
AND   IL_PHYSICAL = 1
GROUP BY ROLLUP (l.IL_IN_LOCN,i.IM_CUST)
--ORDER BY 2,1

UNION ALL

/*This should list Total spaces by type grouped by warehouse for all customers */ --11.00s
SELECT i.IM_CUST AS Cust,
       l.IL_IN_LOCN AS Warehouse,
       Count(DISTINCT l.IL_LOCN) AS Total,  -- test a self join to rid the distinct
       (CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                                                        ELSE 'F- Shelves'
        END) AS "Type"
FROM  NA n INNER JOIN IL l ON l.IL_UID = n.NA_EXT_KEY
           INNER JOIN NE e ON e.NE_ACCOUNT = n.NA_ACCOUNT
           INNER JOIN IM i ON i.IM_STOCK = n.NA_STOCK
WHERE n.NA_EXT_TYPE = 1210067
AND e.NE_AVAIL_ACTUAL >= '1'
AND l.IL_IN_LOCN NOT IN ('OBSOLETEMEL','OBSOLETESYD')
AND e.NE_STATUS =  1
AND e.NE_STRENGTH = 3
GROUP BY ROLLUP (l.IL_IN_LOCN, (CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                                                        ELSE 'F- Shelves'
        END) ,i.IM_CUST   )
ORDER BY 2,1,4
/*This one works and is the master for spaces occupied monthly by cust by warehouse. */



--This give a heirarchial view of 1 customers grouped by parent/grandparent, levels in column
SELECT RM_NAME, RM_CUST, RM_PARENT, LEVEL
FROM RM
START WITH RM_CUST = 'TABCORP'
CONNECT BY PRIOR RM_CUST = RM_PARENT
ORDER SIBLINGS BY RM_NAME




--This give a heirarchial view of all customers grouped by parent/grandparent, levels in column
SELECT RM_NAME, RM_CUST, RM_PARENT, LEVEL
FROM RM
WHERE RM_TYPE = 0
AND RM_ACTIVE = 1
START WITH RM_PARENT LIKE '% %'
CONNECT BY PRIOR RM_CUST = RM_PARENT
ORDER SIBLINGS BY RM_NAME



--This give a heirarchial view of all customers grouped by parent/grandparent, levels are padded
SELECT
   CONCAT
   (
      LPAD
      (
         ' ',
         LEVEL*4-4
      ),
      RM_CUST
   ) Cust
FROM
   RM
WHERE RM_TYPE = 0
AND RM_ACTIVE = 1
CONNECT BY PRIOR RM_CUST = RM_PARENT
START WITH RM_PARENT LIKE '% %'
--ORDER SIBLINGS BY RM_CUST


--This give a heirarchial view of 1 customers grouped by parent/grandparent, levels are padded
SELECT
   CONCAT
   (
      LPAD
      (
         ' ',
         LEVEL*4-4
      ),
      RM_CUST
   ) Cust
FROM
   RM
WHERE RM_TYPE = 0
AND RM_ACTIVE = 1
CONNECT BY PRIOR RM_CUST = RM_PARENT
START WITH RM_PARENT LIKE '% %'
--ORDER SIBLINGS BY RM_CUST








--Count for all customer, this should match the total output of the above parent selects
SELECT Count(*)
FROM RM
WHERE RM_TYPE = 0
AND RM_ACTIVE = 1