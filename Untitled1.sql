Select  f1.DESPDATE,f1.ORDERNUM,f1.DESPNOTE,f1.CUSTOMER,
            f1.ATTENTIONTO,f1.ADDRESS,f1.ADDRESS2,f1.SUBURB,f1.STATE,f1.POSTCODE,
            f1.ITEM,f1.DESCRIPTION,f1.QTY
                 ,CASE   WHEN f1.FEETYPE like 'Stock' AND LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE THEN (Select f2.SELLEXCL From DEV_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND f2.FEETYPE = 'Pick Fee'  AND ROWNUM = 1 ) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
                        ELSE 0
                        END AS "Line Charge"
                ,CASE   WHEN f1.FEETYPE like 'Stock' AND LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE THEN (Select f2.SELLEXCL From DEV_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND f2.FEETYPE = 'Handeling Fee is ' ) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
                        ELSE 0
                        END AS "Order Despatch Charge"
                ,CASE   WHEN f1.FEETYPE like 'Stock' AND (LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE)  --AND  ((ADDRESS  NOT LIKE '%Casselden%' Or ADDRESS   NOT LIKE '%2 Lonsdale%')
                          --OR (ADDRESS2   NOT LIKE '%Casselden%' Or ADDRESS2   NOT LIKE '%2 Lonsdale%')) 
                        THEN (Select f2.SELLEXCL From DEV_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND (f2.FEETYPE like 'Freight Fee' OR f2.FEETYPE like 'Manual Freight Fee') AND ROWNUM = 1) --AND ((UPPER(ADDRESS) NOT LIKE '%CASSELDEN%' Or UPPER(ADDRESS) NOT LIKE '2 LONSDALE%') OR (UPPER(ADDRESS2) NOT LIKE '%CASSELDEN%' Or UPPER(ADDRESS2) NOT LIKE '2 LONSDALE%')) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
                        ELSE 0
                        END AS "Freight Charge",
          REPLACE(IM_XX_QTY_PER_PACK,'Box of ','') As "QTY",
          NULL 
          
          From TMP_ALL_FEES_F f1, IM
          Where f1.FEETYPE = 'Stock'
          AND f1.ITEM = IM_STOCK;