SELECT 'PDS' AS "SCAN"
                ,SD.SD_ORDER
                ,SD.SD_LINE
                ,SD.SD_STOCK
                ,SD.SD_ADD_DATE
                ,SD.SD_LAST_PICK_NUM
                ,SD.SD_ADD_TIME
                ,SD.SD_ADD_OP
                ,SD.SD_LOCN
                ,SD.SD_QTY_ORDER
                ,SD.SD_QTY_DEMAND
                ,SD.SD_QTY_DESP
                ,SD.SD_QTY_UNIT
                ,SD.SD_DESC
                ,IU.IU_TO_METRIC * SD.SD_QTY_ORDER  AS "SinglesQTY"
                ,NULL AS "PASS/FAIL"
                ,NULL AS "OriginalPromoQty"
                ,IA_ALT_STOCK AS "IA_ALT_STOCK"
                ,IA_STOCK AS "IA_STOCK"
                ,IM_XX_CC01_QTY  AS "SPDS_QTY"
                ,NULL  AS "PDS_STOCK"
          
          FROM SD
            INNER JOIN IU ON IU.IU_UNIT =  SD.SD_QTY_UNIT
            INNER JOIN IM ON IM.IM_STOCK = SD.SD_STOCK
            LEFT OUTER JOIN IA ON SD.SD_STOCK = IA.IA_STOCK
          WHERE SD.SD_ADD_DATE >= '26-MAY-2014' AND SD.SD_ADD_DATE <= '31-JUL-2014'
          AND IM_CUST IN ('RACV','IAG')
          --AND SD.SD_LAST_PICK_NUM IS NOT NULL
          AND IA_STOCK IS NOT NULL
          --AND SD.SD_ORDER > :order_num
          AND     SD.SD_STATUS <> 3
          AND IA_ADD_OP = 'PRJ'
          
          
          
          UNION ALL
          
          SELECT 'SPDS' AS "SCAN"
                ,SD.SD_ORDER
                ,SD.SD_LINE
                ,SD.SD_STOCK
                ,SD.SD_ADD_DATE
                ,SD.SD_LAST_PICK_NUM
                ,SD.SD_ADD_TIME
                ,SD.SD_ADD_OP
                ,SD.SD_LOCN
                ,SD.SD_QTY_ORDER
                ,SD.SD_QTY_DEMAND
                ,SD.SD_QTY_DESP
                ,SD.SD_QTY_UNIT
                ,SD.SD_DESC
                ,IU.IU_TO_METRIC * SD.SD_QTY_ORDER  AS "SinglesQTY"
                ,CASE    WHEN (To_Number((SELECT IM_XX_CC01_QTY
                              FROM IM
                                    LEFT OUTER JOIN IA ON IA_STOCK = IM.IM_STOCK
                              WHERE  IA_ADD_OP = 'PRJ'
                              AND IA_STOCK = (SELECT D4.SD_STOCK
                                              FROM SD D4
                                                    LEFT OUTER JOIN IA ON IA_STOCK = D4.SD_STOCK
                                              WHERE D4.SD_ORDER = SD.SD_ORDER
                                              AND IA_ADD_OP = 'PRJ'
                                              AND IA_ALT_STOCK = SD.SD_STOCK AND rownum = 1)) * (SELECT D5.SD_QTY_ORDER
                                                                                    FROM SD D5
                                                                                          LEFT OUTER JOIN IA ON IA_STOCK = D5.SD_STOCK
                                                                                    WHERE D5.SD_ORDER = SD.SD_ORDER
                                                                                    AND IA_ADD_OP = 'PRJ'
                                                                                    AND IA_ALT_STOCK = SD.SD_STOCK AND rownum = 1)) ) = SD.SD_QTY_ORDER THEN  'PASS'
                  ELSE 'FAIL'
                  END AS "PASS/FAIL"
          
                   ,(SELECT IM_XX_CC01_QTY
                    FROM IM
                    INNER JOIN IA ON IA_STOCK = IM.IM_STOCK
                    WHERE  IA_ADD_OP = 'PRJ'
                    AND IA_ALT_STOCK  IN (SELECT IA_ALT_STOCK FROM IA
                                        WHERE IA_ADD_OP = 'PRJ' AND rownum <= 1) ) AS "OriginalPromoQty"
          
                ,NULL AS "IA_ALT_STOCK"
                ,NULL AS "IA_STOCK"
          
                ,To_Number((SELECT IM_XX_CC01_QTY
                            FROM IM
                                  LEFT OUTER JOIN IA ON IA_STOCK = IM.IM_STOCK
                            WHERE  IA_ADD_OP = 'PRJ'
                            AND IA_STOCK = (SELECT D4.SD_STOCK
                                            FROM SD D4
                                                  LEFT OUTER JOIN IA ON IA_STOCK = D4.SD_STOCK
                                            WHERE D4.SD_ORDER = SD.SD_ORDER
                                            AND IA_ADD_OP = 'PRJ'
                                            AND IA_ALT_STOCK = SD.SD_STOCK AND rownum = 1)) * (SELECT D5.SD_QTY_ORDER
                                                                                  FROM SD D5
                                                                                        LEFT OUTER JOIN IA ON IA_STOCK = D5.SD_STOCK
                                                                                  WHERE D5.SD_ORDER = SD.SD_ORDER
                                                                                  AND IA_ADD_OP = 'PRJ'
                                                                                  AND IA_ALT_STOCK = SD.SD_STOCK AND rownum = 1 ))
                                            AS "EXP SPDS_QTY"
                ,(SELECT SD_STOCK
                  FROM SD D3
                        INNER JOIN IA ON IA_STOCK = D3.SD_STOCK
                  WHERE SD_ORDER = SD.SD_ORDER
                  AND IA_ADD_OP = 'PRJ'
                  AND IA_ALT_STOCK = SD.SD_STOCK AND rownum = 1 )  AS "PDS_STOCK"
          
          
          FROM SD
            INNER JOIN IU ON IU.IU_UNIT =  SD.SD_QTY_UNIT
            INNER JOIN IM ON IM.IM_STOCK = SD.SD_STOCK
            --LEFT OUTER JOIN IA ON SD.SD_STOCK = IA.IA_ALT_STOCK
          WHERE SD.SD_ADD_DATE >= '26-MAY-2014' AND SD.SD_ADD_DATE <= '31-JUL-2014'
          AND IM_CUST IN ('RACV','IAG')
          AND SD.SD_STATUS <> 3
          --AND SD.SD_ORDER > :order_num
          AND    (SELECT SD_STOCK
                  FROM SD D3
                        INNER JOIN IA ON IA_STOCK = D3.SD_STOCK
                  WHERE SD_ORDER = SD.SD_ORDER
                  AND IA_ADD_OP = 'PRJ'
                  AND IA_ALT_STOCK = SD.SD_STOCK AND rownum = 1) IS NOT NULL
          

          UNION ALL
          
           SELECT   'TOTALS' AS "SCAN"
          ,SH_ORDER
          ,SD_MAIN.SD_LINE
          ,SD_MAIN.SD_STOCK
          ,SD_MAIN.SD_ADD_DATE
          ,SD_MAIN.SD_LAST_PICK_NUM
          ,SD_MAIN.SD_ADD_TIME
          ,SD_MAIN.SD_ADD_OP
          ,SD_MAIN.SD_LOCN
          ,SD_MAIN.SD_QTY_ORDER
          ,SD_MAIN.SD_QTY_DEMAND
          ,SD_MAIN.SD_QTY_DESP
          ,SD_MAIN.SD_QTY_UNIT
          ,SD_MAIN.SD_DESC
          ,NULL  AS "SinglesQTY"
          ,NULL  AS "PASS/FAIL"
          ,NULL  AS "OriginalPromoQty"
          ,NULL AS "IA_ALT_STOCK"
          ,NULL AS "IA_STOCK"
          --,NULL AS "IA_ALT_STOCK" 
          --,NULL AS "IA_STOCK"
          ,To_Number((SELECT Count(DISTINCT(SD_PDS.SD_STOCK))
              FROM SD SD_PDS
              WHERE SD_PDS.SD_ADD_DATE >= '26-MAY-2014' AND SD_PDS.SD_ADD_DATE <= '31-JUL-2014'
              AND SD_PDS.SD_STATUS <> 3
              AND SD_PDS.SD_ORDER = SH_ORDER
              AND SD_PDS.SD_STOCK =  (SELECT IA_STOCK
                                          --FROM SD D3
                                          --      INNER JOIN IA ON IA_STOCK = D3.SD_STOCK
                                          --WHERE D3.SD_ORDER = SH_ORDER
                                          FROM IA
                                          WHERE IA_ADD_OP = 'PRJ'
                                          AND IA_STOCK = SD_PDS.SD_STOCK AND rownum = 1)))  As "PDS_Count"  
          ,To_Char((SELECT Count(DISTINCT(SD_SPDS.SD_STOCK))
              FROM SD SD_SPDS
              WHERE SD_SPDS.SD_ADD_DATE >= '26-MAY-2014' AND SD_SPDS.SD_ADD_DATE <= '31-JUL-2014'
              AND SD_SPDS.SD_STATUS <> 3
              AND SD_SPDS.SD_ORDER = SH_ORDER
              AND SD_SPDS.SD_STOCK =  (SELECT IA_ALT_STOCK
                                          --FROM SD D3
                                                --INNER JOIN IA ON IA_ALT_STOCK = D3.SD_STOCK
                                          FROM IA
                                          --WHERE D3.SD_ORDER = SH_ORDER
                                          WHERE IA_ADD_OP = 'PRJ'
                                          AND IA_ALT_STOCK = SD_SPDS.SD_STOCK AND rownum = 1)))  As "SPDS_Count"    
          FROM SH 
            INNER JOIN SD SD_MAIN ON SD_MAIN.SD_ORDER = SH_ORDER
            INNER JOIN IM ON IM.IM_STOCK = SD_MAIN.SD_STOCK
            LEFT OUTER JOIN IA ON SD_MAIN.SD_STOCK = IA.IA_STOCK
          WHERE SD_MAIN.SD_ADD_DATE >= '26-MAY-2014' AND SD_MAIN.SD_ADD_DATE <= '31-JUL-2014'
          AND IM_CUST IN ('RACV','IAG')
          --AND SH_ORDER >= :order_num
          AND SH_STATUS <> 3
          AND SD_MAIN.SD_LINE = 1
          AND IA_STOCK IS NOT NULL


          
          
          
          
          ORDER BY 6,1,3 Asc