Select  f1.DESPDATE,f1.ORDERNUM,f1.DESPNOTE,f1.CUSTOMER,
            f1.ATTENTIONTO,f1.ADDRESS,f1.ADDRESS2,f1.SUBURB,f1.STATE,f1.POSTCODE,
            f1.ITEM,f1.DESCRIPTION,f1.QTY
                 ,CASE   WHEN f1.FEETYPE like 'Stock' AND LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE THEN (Select f2.SELLEXCL From DEV_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND f2.FEETYPE = 'Pick Fee'  AND ROWNUM = 1) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
                        ELSE 0
                        END AS "Line Charge"
                ,CASE   WHEN f1.FEETYPE like 'Stock' AND LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE THEN (Select f2.SELLEXCL From DEV_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND f2.FEETYPE = 'Handeling Fee is ' ) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
                        ELSE 0
                        END AS "Order Despatch Charge"
                ,CASE   WHEN f1.FEETYPE like 'Stock' AND (LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE)  AND  ((ADDRESS  NOT LIKE '%Casselden%' Or ADDRESS   NOT LIKE '%2 Lonsdale%')
                          OR (ADDRESS2   NOT LIKE '%Casselden%' Or ADDRESS2   NOT LIKE '%2 Lonsdale%')) 
                        THEN (Select f2.SELLEXCL From DEV_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND (f2.FEETYPE like 'Freight Fee' OR f2.FEETYPE like 'Manual Freight Fee') AND ROWNUM = 1) --AND ((UPPER(ADDRESS) NOT LIKE '%CASSELDEN%' Or UPPER(ADDRESS) NOT LIKE '2 LONSDALE%') OR (UPPER(ADDRESS2) NOT LIKE '%CASSELDEN%' Or UPPER(ADDRESS2) NOT LIKE '2 LONSDALE%')) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
                        ELSE 0
                        END AS "Freight Charge",
          REPLACE(IM_XX_QTY_PER_PACK,'Box of ','') As "QTY",
          NULL 
          
          From DEV_ALL_FEES_F f1, IM
          Where f1.FEETYPE = 'Stock'
          AND f1.ITEM = IM_STOCK
          
          UNION ALL
          --Monday or the first day of the week
          Select TO_CHAR(TRUNC(CURRENT_DATE, 'DAY') -7),NULL,NULL,NULL,
            NULL,NULL,NULL,NULL,NULL,NULL,
            NULL,
           CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,0,'DEV') > 0
          Then 'Daily Van Freight'
          ELSE NULL
          END AS  "Description",
          Case WHEN
          F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,0,'DEV') > 0 
          Then
          F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,0,'DEV') 
          END AS "Qty"
         ,0,0,
          CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,0,'DEV') > 0 
          Then 30.71
          ELSE 0
          END AS  "Freight Charge Cost",NULL,NULL
          From DEV_ALL_FEES_F f1
          Where f1.FEETYPE = 'Freight Fee' 
           AND ((ADDRESS  LIKE '%Casselden%' Or ADDRESS  LIKE '%2 Lonsdale%')
          OR (ADDRESS2  LIKE '%Casselden%' Or ADDRESS2  LIKE '%2 Lonsdale%'))
          --Group by TRUNC(CURRENT_DATE, 'DAY') -6
          AND f1.DESPDATE = TRUNC(CURRENT_DATE, 'DAY') -7
          And ROWNUM = 1
          
          UNION ALL
          
          --Tuesday or the first day of the week
          Select TO_CHAR(TRUNC(CURRENT_DATE, 'DAY') -6),NULL,NULL,NULL,
            NULL,NULL,NULL,NULL,NULL,NULL,
            NULL,
           CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,1,'DEV') > 0
          Then 'Daily Van Freight'
          ELSE NULL
          END AS  "Description",
          Case WHEN
          F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,1,'DEV') > 0 
          Then
          F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,1,'DEV') 
          END AS "Qty"
         ,0,0,
          CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,1,'DEV') > 0 
          Then 30.71
          ELSE 0
          END AS  "Freight Charge Cost",NULL,NULL
          From DEV_ALL_FEES_F f1
          Where f1.FEETYPE = 'Freight Fee' 
           AND ((ADDRESS  LIKE '%Casselden%' Or ADDRESS  LIKE '%2 Lonsdale%')
          OR (ADDRESS2  LIKE '%Casselden%' Or ADDRESS2  LIKE '%2 Lonsdale%'))
          AND f1.DESPDATE = TRUNC(CURRENT_DATE, 'DAY') -6
          And ROWNUM = 1
          
          UNION ALL
          
          --Wednesday or the first day of the week
          Select TO_CHAR(TRUNC(CURRENT_DATE, 'DAY') -5),NULL,NULL,NULL,
            NULL,NULL,NULL,NULL,NULL,NULL,
            NULL,
           CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,2,'DEV') > 0
          Then 'Daily Van Freight'
          ELSE NULL
          END AS  "Description",
          Case WHEN
          F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,2,'DEV') > 0 
          Then
          F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,2,'DEV') 
          END AS "Qty"
         ,0,0,
          CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,2,'DEV') > 0 
          Then 30.71
          ELSE 0
          END AS  "Freight Charge Cost",NULL,NULL
          From DEV_ALL_FEES_F f1
          Where f1.FEETYPE = 'Freight Fee' 
           AND ((ADDRESS  LIKE '%Casselden%' Or ADDRESS  LIKE '%2 Lonsdale%')
          OR (ADDRESS2  LIKE '%Casselden%' Or ADDRESS2  LIKE '%2 Lonsdale%'))
          AND f1.DESPDATE = TRUNC(CURRENT_DATE, 'DAY') -5
          And ROWNUM = 1
          
          UNION ALL
          
          --Thursday or the first day of the week
          Select TO_CHAR(TRUNC(CURRENT_DATE, 'DAY') -4),NULL,NULL,NULL,
            NULL,NULL,NULL,NULL,NULL,NULL,
            NULL,
           CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,3,'DEV') > 0
          Then 'Daily Van Freight'
          ELSE NULL
          END AS  "Description",
          Case WHEN
          F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,3,'DEV') > 0 
          Then
          F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,3,'DEV') 
          END AS "Qty"
         ,0,0,
          CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,3,'DEV') > 0 
          Then 30.71
          ELSE 0
          END AS  "Freight Charge Cost",NULL,NULL
          From DEV_ALL_FEES_F f1
          Where f1.FEETYPE = 'Freight Fee' 
           AND ((ADDRESS  LIKE '%Casselden%' Or ADDRESS  LIKE '%2 Lonsdale%')
          OR (ADDRESS2  LIKE '%Casselden%' Or ADDRESS2  LIKE '%2 Lonsdale%'))
          AND f1.DESPDATE = TRUNC(CURRENT_DATE, 'DAY') -4
          And ROWNUM = 1
          
          UNION ALL
          
          --Friday or the first day of the week
          Select TO_CHAR(TRUNC(CURRENT_DATE, 'DAY') -3),NULL,NULL,NULL,
            NULL,NULL,NULL,NULL,NULL,NULL,
            NULL,
           CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,4,'DEV') > 0
          Then 'Daily Van Freight'
          ELSE NULL
          END AS  "Description",
          Case WHEN
          F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,4,'DEV') > 0 
          Then
          F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,4,'DEV') 
          END AS "Qty"
         ,0,0,
          CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,4,'DEV') > 0 
          Then 30.71
          ELSE 0
          END AS  "Freight Charge Cost",NULL,NULL
          From DEV_ALL_FEES_F f1
          Where f1.FEETYPE = 'Freight Fee' 
           AND ((ADDRESS  LIKE '%Casselden%' Or ADDRESS  LIKE '%2 Lonsdale%')
          OR (ADDRESS2  LIKE '%Casselden%' Or ADDRESS2  LIKE '%2 Lonsdale%'))
          AND f1.DESPDATE = TRUNC(CURRENT_DATE, 'DAY') -3
          And ROWNUM = 1
          
          UNION ALL
          
          --Facilitate ctn/pallet charges - 3 lines
          Select TO_CHAR(TRUNC(CURRENT_DATE, 'DAY') -3),NULL,NULL,NULL,
          NULL,NULL,NULL,NULL,NULL,NULL,
          NULL,
          'Destory Pallet Charge' AS  "Description",
          '1' AS "Qty"
          ,0,0,
          38.80 AS  "Pallet Charge Cost",NULL,NULL
          From DUAL
          Where ROWNUM = 1
          
           UNION ALL
          
          --Facilitate ctn/pallet charges - 3 lines
          Select TO_CHAR(TRUNC(CURRENT_DATE, 'DAY') -3),NULL,NULL,NULL,
          NULL,NULL,NULL,NULL,NULL,NULL,
          NULL,
          'Extra Destory Pallet Charge' AS  "Description",
          '1' AS "Qty"
          ,0,0,
          14.55 AS  "Extra Pallet Charge Cost",NULL,NULL
          From DUAL
          Where ROWNUM = 1
          
           UNION ALL
          
          --Facilitate ctn/pallet charges - 3 lines
          Select TO_CHAR(TRUNC(CURRENT_DATE, 'DAY') -3),NULL,NULL,NULL,
          NULL,NULL,NULL,NULL,NULL,NULL,
          NULL,
          'Destory Carton Charge' AS  "Description",
          '1' AS "Qty"
          ,0,0,
          2.43 AS  "Carton Charge Cost",NULL,NULL
          From DUAL
          Where ROWNUM = 1
