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
WHERE t.ST_DESP_DATE >= '01-Dec-2016' AND t.ST_DESP_DATE <= '07-Dec-2016'
AND s.SL_LINE = 1
AND t.ST_PSLIP IS NOT NULL AND t.ST_PSLIP <> 'CANCELLED'
AND h.SH_STATUS <> 3
AND h.SH_CAMPAIGN NOT IN( 'ADMIN','OBSOLETE')
AND r2.RM_ACTIVE = 1   --This was the problem
GROUP BY ROLLUP ((EOM_REPORT_PKG.f_GetWarehouse_from_SD(s.SL_LOCN)), sGroupCust )
HAVING EOM_REPORT_PKG.f_GetWarehouse_from_SD(s.SL_LOCN) LIKE 'SYDNEY'
      OR EOM_REPORT_PKG.f_GetWarehouse_from_SD(s.SL_LOCN) LIKE '%' ;