
SELECT  (CASE
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'S' THEN 'SYDNEY'
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'H' THEN 'SYDNEY'
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'R' THEN 'SYDNEY'
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'M' THEN 'MELBOURNE'
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'O' THEN 'OBSOLETE'
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'D' THEN 'DMMETLIFE'
            ELSE 'NOLOCN'
            END) AS Warehouse,
        sGroupCust,

         Count(*) AS Total,
         'A- Orders' AS "Type"
FROM Tmp_Group_Cust r INNER JOIN SH h ON RTrim(h.SH_CUST) = RTrim(r.sCust)
     INNER JOIN SD d ON d.SD_ORDER = h.SH_ORDER
     --INNER JOIN IM m ON m.IM_STOCK = d.SD_STOCK
     INNER JOIN RM r2 ON r2.RM_CUST = h.SH_CUST
WHERE h.SH_ADD_DATE >= '01-FEB-2015' AND h.SH_ADD_DATE <= '01-FEB-2016'
AND h.SH_STATUS <> 3
AND h.SH_CAMPAIGN NOT LIKE 'ADMIN'
AND h.SH_CAMPAIGN NOT LIKE 'OBSOLETE'
AND d.SD_DISPLAY = 1
AND r2.RM_ACTIVE = 1   --This was the problem
GROUP BY ROLLUP (
                ( CASE
                  WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'S' THEN 'SYDNEY'
                  WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'H' THEN 'SYDNEY'
                  WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'R' THEN 'SYDNEY'
                  WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'M' THEN 'MELBOURNE'
                  WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'O' THEN 'OBSOLETE'
                  WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'D' THEN 'DMMETLIFE'
                  ELSE 'NOLOCN'
                  END
                ),
                sGroupCust
                )
ORDER BY 1,2 ASC;



/*Total Orders by Month all custs grouped by warehouse/Cust/top level parent */  --  2.38s  Returns 4482 rows this gives the correct totals - grand total is 15538

SELECT  (CASE
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'S' THEN 'SYDNEY'
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'H' THEN 'SYDNEY'
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'R' THEN 'SYDNEY'
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'M' THEN 'MELBOURNE'
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'O' THEN 'OBSOLETE'
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'D' THEN 'DMMETLIFE'
            ELSE 'NOLOCN'
            END) AS Warehouse,
        sCust,
        sGroupCust,

         Count(*) AS Total,
         'A- Orders' AS "Type"
FROM SH h INNER JOIN Tmp_Group_Cust r ON r.sCust = h.SH_CUST
     INNER JOIN SD d ON d.SD_ORDER = h.SH_ORDER
     INNER JOIN RM r2 ON r2.RM_CUST = h.SH_CUST
WHERE h.SH_ADD_DATE >= '01-FEB-2015' AND h.SH_ADD_DATE <= '01-FEB-2016'
AND h.SH_STATUS <> 3
AND h.SH_CAMPAIGN NOT IN( 'ADMIN','OBSOLETE')
AND d.SD_DISPLAY = 1
AND r2.RM_ACTIVE = 1   --This was the problem
GROUP BY ROLLUP (
                ( CASE
                  WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'S' THEN 'SYDNEY'
                  WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'H' THEN 'SYDNEY'
                  WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'R' THEN 'SYDNEY'
                  WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'M' THEN 'MELBOURNE'
                  WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'O' THEN 'OBSOLETE'
                  WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'D' THEN 'DMMETLIFE'
                  ELSE 'NOLOCN'
                  END
                ),
                sGroupCust,
                sCust
                )
ORDER BY 1,2 ASC;



/*ORDER COUNT CHECKS*/
  --The above 3 queries should total to this query   15538
  SELECT Count(h.SH_ORDER)
  FROM SH h INNER JOIN Tmp_Group_Cust r ON r.sCust = h.SH_CUST
  INNER JOIN SD d ON d.SD_ORDER = h.SH_ORDER
  INNER JOIN RM r2 ON r2.RM_CUST = h.SH_CUST
  WHERE h.SH_ADD_DATE >= '01-FEB-2015' AND h.SH_ADD_DATE <= '01-FEB-2016'
  AND h.SH_STATUS <> 3
  AND h.SH_CAMPAIGN NOT IN( 'ADMIN','OBSOLETE')
  AND d.SD_DISPLAY = 1
  AND r2.RM_ACTIVE = 1   --This was the problem

  --Even with distinct right join 15538
  SELECT Count(DISTINCT h.SH_ORDER)
  --SELECT h.SH_ORDER,SH_CUST,SH_CAMPAIGN, substr(To_Char(h.SH_ADD_DATE),0,10) AS AddDate
  FROM SH h RIGHT JOIN Tmp_Group_Cust r ON r.sCust = h.SH_CUST
  INNER JOIN SD d ON d.SD_ORDER = h.SH_ORDER
  INNER JOIN RM r2 ON r2.RM_CUST = h.SH_CUST
  WHERE h.SH_ADD_DATE >= '01-FEB-2015' AND h.SH_ADD_DATE <= '01-FEB-2016'
  AND h.SH_STATUS <> 3
  AND h.SH_CAMPAIGN NOT IN( 'ADMIN','OBSOLETE')
  AND d.SD_DISPLAY = 1
  AND r2.RM_ACTIVE = 1   --This was the problem

  --Total Order Count Matches to Prism output and above query with sd join     15538
  SELECT Count(h.SH_ORDER)
  --SELECT h.SH_ORDER,SH_CUST,SH_CAMPAIGN, substr(To_Char(h.SH_ADD_DATE),0,10) AS AddDate
  FROM SH h INNER JOIN Tmp_Group_Cust r ON r.sCust = h.SH_CUST
  INNER JOIN SD d ON d.SD_ORDER = h.SH_ORDER
  INNER JOIN RM r2 ON r2.RM_CUST = h.SH_CUST
  WHERE h.SH_ADD_DATE >= '01-FEB-2015' AND h.SH_ADD_DATE <= '01-FEB-2016'
  AND h.SH_STATUS <> 3
  AND h.SH_CAMPAIGN NOT IN( 'ADMIN','OBSOLETE')
  AND d.SD_DISPLAY = 1
  AND r2.RM_ACTIVE = 1   --This was the problem

/*END ORDER COUNT CHECKS */


UNION ALL

/*Total Despatches by Month all custs grouped by cust */  --  1.5s

SELECT (
          CASE
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'S' THEN 'SYDNEY'
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'H' THEN 'SYDNEY'
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'R' THEN 'SYDNEY'
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'M' THEN 'MELBOURNE'
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'O' THEN 'OBSOLETE'
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'D' THEN 'DMMETLIFE'
            ELSE 'NOLOCN'
            END) AS Warehouse,
             sGroupCust,
            Count(*) AS Total,
            'B- Despatches' AS "Type"
FROM PWIN175.SL s INNER JOIN SH h ON s.SL_ORDER = h.SH_ORDER
    RIGHT JOIN Tmp_Group_Cust r ON r.sCust = h.SH_CUST
    INNER JOIN SD d ON d.SD_ORDER = h.SH_ORDER
    INNER JOIN RM r2 ON r2.RM_CUST = h.SH_CUST
    INNER JOIN IL l ON l.IL_LOCN = s.SL_LOCN
    INNER JOIN ST t ON t.ST_PICK = s.SL_PICK
WHERE s.SL_EDIT_DATE >= '01-FEB-2015' AND s.SL_EDIT_DATE <= '01-FEB-2016'
AND s.SL_LINE = 1
AND s.SL_PSLIP IS NOT NULL
AND h.SH_STATUS <> 3
AND h.SH_CAMPAIGN NOT IN( 'ADMIN','OBSOLETE')
AND r2.RM_ACTIVE = 1   --This was the problem
GROUP BY ROLLUP ((CASE
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'S' THEN 'SYDNEY'
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'H' THEN 'SYDNEY'
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'R' THEN 'SYDNEY'
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'M' THEN 'MELBOURNE'
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'O' THEN 'OBSOLETE'
            WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'D' THEN 'DMMETLIFE'
            ELSE 'NOLOCN'
            END),
             sGroupCust )
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
WHERE s.SL_EDIT_DATE >= '01-FEB-2015' AND s.SL_EDIT_DATE <= '01-FEB-2016'
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
AND   e.NE_DATE >= '01-FEB-2015' AND e.NE_DATE <= '01-FEB-2016'
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
ORDER BY 2,1,4;
/*This one works and is the master for spaces occupied monthly by cust by warehouse. */

