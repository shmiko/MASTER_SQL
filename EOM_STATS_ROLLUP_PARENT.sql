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
exec :start_date := To_Date('01-May-2016')
var end_date varchar2(20)
exec :end_date := To_Date('31-May-2016')
var warehouse varchar2(20)
exec :warehouse := '*'
var warehouse2 varchar2(20)
exec :warehouse2 := 'MELBOURNE'
var month_date varchar2(20)
exec :month_date := substr(:end_date,4,3)
var year_date varchar2(20)
exec :year_date := substr(:end_date,8,2)



set timing on

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
INSERT INTO Tmp_Log_stats (sWarehouse, sCust, nTotal, sType, campaign, spare1,spare2,spare3)

SELECT     EOM_REPORT_PKG.f_GetWarehouse_from_SD(d.SD_LOCN) AS Warehouse,
            sGroupCust,
            Count(DISTINCT(SD_ORDER)) AS Total,
            --Count(DISTINCT(SD_ORDER)) AS SDCount,
            'A- Orders' AS "Type",NULL,NULL,NULL,null--, Count(SD_ORDER) AS SDCount
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
GROUP BY ROLLUP ( EOM_REPORT_PKG.f_GetWarehouse_from_SD(d.SD_LOCN),
                sGroupCust  )
HAVING EOM_REPORT_PKG.f_GetWarehouse_from_SD(d.SD_LOCN) LIKE :warehouse
      OR EOM_REPORT_PKG.f_GetWarehouse_from_SD(d.SD_LOCN) LIKE '%'
                             --151 rows in 2.92sec
--ORDER BY 1,2 ASC



UNION ALL

/*Total Despatches by Month all custs grouped by warehouse/grouped cust */  --  1.5s  Total Count 15381  --126   --1.34 s  126

SELECT       EOM_REPORT_PKG.f_GetWarehouse_from_SD(s.SL_LOCN) AS Warehouse,
             sGroupCust,
            Count(*) AS Total,
            'B- Despatches' AS "Type"      ,NULL,NULL,NULL,null
           --t.ST_PICK,
           --h.SH_CAMPAIGN
FROM  PWIN175.ST t INNER JOIN SL s ON s.SL_PICK = t.ST_PICK
      INNER JOIN SH h ON h.SH_ORDER = t.ST_ORDER--RIGHT JOIN SD d ON d.SD_ORDER = h.SH_ORDER
      LEFT JOIN Tmp_Group_Cust r ON r.sCust = h.SH_CUST
      INNER JOIN RM r2 ON r2.RM_CUST = h.SH_CUST
      --RIGHT JOIN SL s ON s.SL_PICK = t.ST_PICK
WHERE t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
AND s.SL_LINE = 1
AND t.ST_PSLIP IS NOT NULL AND t.ST_PSLIP <> 'CANCELLED'
AND h.SH_STATUS <> 3
AND h.SH_CAMPAIGN NOT IN( 'ADMIN','OBSOLETE')
AND r2.RM_ACTIVE = 1   --This was the problem
GROUP BY ROLLUP ((EOM_REPORT_PKG.f_GetWarehouse_from_SD(s.SL_LOCN)), sGroupCust )
HAVING EOM_REPORT_PKG.f_GetWarehouse_from_SD(s.SL_LOCN) LIKE :warehouse
      OR EOM_REPORT_PKG.f_GetWarehouse_from_SD(s.SL_LOCN) LIKE '%'
--ORDER BY 2


UNION ALL

/*Total Lines by Month all custs grouped by warehouse/top level grouped cust */  --  7.8s   total count 62068

SELECT  EOM_REPORT_PKG.f_GetWarehouse_from_SD(s.SL_LOCN) AS Warehouse,
            sGroupCust AS Customer,
            Count(*) AS Total,
            'C- Lines' AS "Type"    ,NULL,NULL,NULL,null
FROM  PWIN175.SL s INNER JOIN SH h ON s.SL_ORDER = h.SH_ORDER
      LEFT JOIN Tmp_Group_Cust r ON r.sCust = h.SH_CUST
      --RIGHT JOIN SD d ON d.SD_ORDER = h.SH_ORDER
      INNER JOIN RM r2 ON r2.RM_CUST = h.SH_CUST
      --INNER JOIN IL l ON l.IL_LOCN = s.SL_LOCN
      INNER JOIN ST t ON t.ST_PICK = s.SL_PICK
WHERE s.SL_EDIT_DATE >= :start_date AND s.SL_EDIT_DATE <= :end_date
AND s.SL_PSLIP IS NOT NULL
AND h.SH_CAMPAIGN NOT IN( 'ADMIN','OBSOLETE')
AND r2.RM_ACTIVE = 1   --This was the problem
GROUP BY ROLLUP (EOM_REPORT_PKG.f_GetWarehouse_from_SD(s.SL_LOCN),
          sGroupCust)
HAVING EOM_REPORT_PKG.f_GetWarehouse_from_SD(s.SL_LOCN) LIKE :warehouse
      OR EOM_REPORT_PKG.f_GetWarehouse_from_SD(s.SL_LOCN) LIKE '%'

UNION ALL



/*This should list Total receipts by type grouped by warehouse for all customers */ --1.1s   Total is 2643
SELECT (CASE
        WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
        WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
        END) AS Warehouse,

        i.IM_CUST AS Cust,
       Count(NE_ENTRY) AS Total,
       'D- Receipts'  AS "Type"   ,NULL,NULL,NULL,null
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
GROUP BY ((CASE
        WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
        WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
        END)
,i.IM_CUST)
HAVING (CASE
        WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
        WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
        END) Like :warehouse  OR  (CASE
        WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
        WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
        END) Like '%'
--ORDER BY 1


UNION ALL

/*This should list Total spaces by type grouped by warehouse for all customers */ --13.00s Total is 15131
SELECT
       (CASE
        WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
        WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
        END) AS Warehouse,
       i.IM_CUST AS Cust,
       Count(DISTINCT l.IL_LOCN) AS Total,  -- test a self join to rid the distinct
       (CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                                                        ELSE 'F- Shelves'
        END) AS "Type"      ,NULL,NULL,NULL,null
FROM  NA n INNER JOIN IL l ON l.IL_UID = n.NA_EXT_KEY
           INNER JOIN NE e ON e.NE_ACCOUNT = n.NA_ACCOUNT
           INNER JOIN IM i ON i.IM_STOCK = n.NA_STOCK
           --LEFT JOIN Tmp_Group_Cust r ON r.sGroupCust = i.IM_CUST
WHERE n.NA_EXT_TYPE = 1210067
AND e.NE_AVAIL_ACTUAL >= '1'
AND l.IL_IN_LOCN NOT IN ('OBSOLETEMEL','OBSOLETESYD','PASTHISTORY', 'CANBERRA')
AND e.NE_STATUS =  1
AND e.NE_STRENGTH = 3
--AND i.IM_CUST = 'D-NATPRE'
GROUP BY  ((CASE
                  WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
                  WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
                  END),i.IM_CUST, (CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                                                                  ELSE 'F- Shelves'
                  END) )
HAVING (CASE
        WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
        WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
        END) Like :warehouse  OR  (CASE
        WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
        WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
        END) Like '%'

ORDER BY 1,2,4
/*This one works and is the master for spaces occupied monthly by cust by warehouse. */

--set timing off

/*SELECT * FROM TMP_FREIGHT
   ORDER BY 1,2,4   */


select
		  IM_CUST AS "Customer", IM_CUST AS "Parent",
	    CASE /*Fee Type*/
			  WHEN (l1.IL_NOTE_2 like 'Yes'
				  OR l1.IL_NOTE_2 LIKE 'YES'
				  OR l1.IL_NOTE_2 LIKE 'yes')
			  THEN 'FEEPALLETS'
			  ELSE 'FEESHELFS'
			  END AS "FeeType",
      n1.NA_STOCK AS "Item",
		  CASE   WHEN l1.IL_NOTE_2 IS NOT NULL THEN  1
			    ELSE NULL
			    END                     AS "Qty", IM_LEVEL_UNIT AS "UOI", /*UOI*/
	      l1.IL_NOTE_2 AS "Pallet/Space"
          , l1.IL_LOCN ,



    FROM  NA n1 INNER JOIN IL l1 ON l1.IL_UID = n1.NA_EXT_KEY
      INNER JOIN NE e ON e.NE_ACCOUNT = n1.NA_ACCOUNT
      INNER JOIN IM  ON  IM_STOCK = n1.NA_STOCK
      INNER JOIN Tmp_Locn_Cnt_By_Cust ON sLocn = l1.IL_LOCN  AND sCust = IM_CUST

                    WHERE n1.NA_EXT_TYPE = 1210067
                      AND e.NE_AVAIL_ACTUAL >= '1'
                      AND l1.IL_IN_LOCN NOT IN ('OBSOLETEMEL','OBSOLETESYD','PASTHISTORY', 'CANBERRA')
                      AND e.NE_STATUS =  1
                      AND e.NE_STRENGTH = 3
                      AND  IM_CUST LIKE '%D-%'

    SELECT Count(DISTINCT NI_STOCK) AS CountOfStocks, IL_LOCN, IM_CUST
						FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
						INNER JOIN IM ON IM_STOCK = NI_STOCK
						WHERE IM_CUST LIKE '%D-%'
						AND IM_ACTIVE = 1
						AND NI_AVAIL_ACTUAL >= '1'
						AND NI_STATUS <> 0
						GROUP BY IL_LOCN, IM_CUST
            ORDER BY 3,2,1





    v_query := q'{INSERT INTO Tmp_Locn_Cnt_By_Cust
						SELECT Count(DISTINCT NI_STOCK) AS CountOfStocks, IL_LOCN, IM_CUST,
                      CASE WHEN Upper(substr(IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                        ELSE 'F- Shelves'
                        END AS "Note"  ,NULL,NULL,NULL,null
						FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
						INNER JOIN IM ON IM_STOCK = NI_STOCK
						WHERE IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_ANAL = :sAnalysis AND RM_TYPE = :v_p_RM_TYPE AND RM_ACTIVE = :v_p_IM_ACTIVE )
						AND IM_ACTIVE = :v_p_IM_ACTIVE
						AND NI_AVAIL_ACTUAL >= :v_p_NI_AVAIL_ACTUAL
						AND NI_STATUS <> :v_p_NI_STATUS
						GROUP BY IL_LOCN, IM_CUST,IL_NOTE_2
            }';
	/*  FROM NI n1 INNER JOIN IM ON IM_STOCK = n1.NI_STOCK
	  INNER JOIN IL l1 ON l1.IL_LOCN = n1.NI_LOCN
    INNER JOIN Tmp_Locn_Cnt_By_Cust ON sLocn = l1.IL_LOCN  AND sCust = IM_CUST
    --WHERE IM_CUST = 'NSWFIRE' /*IN (SELECT RM_CUST FROM RM WHERE RM_ANAL = '22NSWP') */ /*AND    */
  /*  WHERE IM_ACTIVE = 1
	  AND IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_PARENT = ' '  AND RM_ANAL = :sAnalysis AND RM_TYPE = 0 AND RM_ACTIVE = 1 )
	  AND n1.NI_AVAIL_ACTUAL >= '1' AND n1.NI_STATUS <> 0
   -- AND n1.NI_EXT_TYPE = 1210067
                      AND l1.IL_IN_LOCN NOT IN ('OBSOLETEMEL','OBSOLETESYD','PASTHISTORY', 'CANBERRA')
                    --AND n1.NI_STATUS =  1
                      AND n1.NI_STRENGTH = 3      */
	  GROUP BY n1.NA_STOCK,IM_CUST,
            ,l1.IL_LOCN,l1.IL_NOTE_2
            ,IM_LEVEL_UNIT ,IM_BRAND,IM_OWNED_By,IM_PROFILE


SELECT Count(DISTINCT NI_STOCK) AS CountOfStocks, IL_LOCN, IM_CUST, IM_STOCK, IM_XX_ABSTRACT2, IM_DESC, NI_AVAIL_ACTUAL,
                      F_DM_LAST_REC_DATE(IM_STOCK),
                      F_DM_LAST_USE_DATE(IM_STOCK)
						        FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
						        INNER JOIN IM ON IM_STOCK = NI_STOCK
						        WHERE IM_CUST LIKE '%D-%'
                    --OR IM_CUST LIKE :cust
						        AND IM_ACTIVE = 1
						        AND NI_AVAIL_ACTUAL >= '1'
						        AND NI_STATUS <> 0
						        GROUP BY IL_LOCN, IM_CUST, IM_STOCK, IM_XX_ABSTRACT2, IM_DESC, NI_AVAIL_ACTUAL
                    ORDER BY 3



