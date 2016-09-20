Select f1.DESPDATE,
       f1.ORDERNUM,
       f1.DESPNOTE,
       f1.CUSTOMER,
       f1.ATTENTIONTO,
       f1.ADDRESS,
       f1.ADDRESS2,
       f1.SUBURB,
       f1.STATE,
       f1.POSTCODE,
       --f1.FEETYPE,
       f1.ITEM,
       f1.DESCRIPTION,
       f1.QTY,
--       f1.SELLEXCL,
       --LAG(SELLEXCL, 1, 0) OVER (ORDER BY SELLEXCL) AS SDSELL_prev,
       --LEAD(SELLEXCL, 1, 0) OVER (ORDER BY SELLEXCL) AS "Handling Fee",
       --LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL) AS "Line Fee",
--       CASE   WHEN FEETYPE like 'Freight Fee' OR FEETYPE like 'Manual Freight Fee' AND LAG(DESPNOTE, 1, 0) OVER (ORDER BY DESPNOTE) != DESPNOTE THEN SELLEXCL
--              ELSE NULL
--              END AS "Freight Charge",
       CASE   WHEN f1.FEETYPE like 'Stock' AND LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE THEN (Select f2.SELLEXCL From TMP_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND f2.FEETYPE = 'Pick Fee' ) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
              ELSE 0
              END AS "Line Charge",
      CASE   WHEN f1.FEETYPE like 'Stock' AND LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE THEN (Select f2.SELLEXCL From TMP_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND f2.FEETYPE = 'Handeling Fee is ' ) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
              ELSE 0
              END AS "Order Despatch Charge",
      CASE   WHEN f1.FEETYPE like 'Stock' AND LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE THEN (Select f2.SELLEXCL From TMP_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND (f2.FEETYPE like 'Freight Fee' OR f2.FEETYPE like 'Manual Freight Fee') ) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
              ELSE 0
              END AS "Freight Charge"
--       CASE   WHEN FEETYPE like 'Handeling Fee is ' AND LAG(DESPNOTE, 1, 0) OVER (ORDER BY DESPNOTE) != DESPNOTE  THEN SELLEXCL
--              ELSE NULL
--              END AS "Order Despatch Charge",
--       CASE   WHEN FEETYPE like 'Pick Fee ' AND LAG(DESPNOTE, 1, 0) OVER (ORDER BY DESPNOTE) != DESPNOTE  THEN SELLEXCL
--              ELSE NULL
--              END AS "Line Charge" 

From TMP_ALL_FEES_F f1
Where 
--f1.ORDERNUM = '   1969424' AND f1.DESPNOTE = '   2287094'
--AND 
f1.FEETYPE = 'Stock';
--Order By FEETYPE;