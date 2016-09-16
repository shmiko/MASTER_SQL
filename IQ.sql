Select DESPDATE,
       ORDERNUM,
       DESPNOTE,
       CUSTOMER,
       ATTENTIONTO,
       ADDRESS,
       ADDRESS2,
       SUBURB,
       STATE,
       POSTCODE,
       FEETYPE,
       ITEM,
       DESCRIPTION,
       QTY,
       SELLEXCL,
       LAG(SELLEXCL, 1, 0) OVER (ORDER BY SELLEXCL) AS SDSELL_prev,
       LEAD(SELLEXCL, 1, 0) OVER (ORDER BY SELLEXCL) AS "Handling Fee",
       LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL) AS "Line Fee",
--       CASE   WHEN FEETYPE like 'Freight Fee' OR FEETYPE like 'Manual Freight Fee' AND LAG(DESPNOTE, 1, 0) OVER (ORDER BY DESPNOTE) != DESPNOTE THEN SELLEXCL
--              ELSE NULL
--              END AS "Freight Charge",
       CASE   WHEN FEETYPE like 'Stock' AND LAG(DESPNOTE, 1, 0) OVER (ORDER BY DESPNOTE) != DESPNOTE AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LAG(SELLEXCL, 1, 0) OVER (ORDER BY SELLEXCL)
              ELSE NULL
              END AS "Line Charge"
--       CASE   WHEN FEETYPE like 'Handeling Fee is ' AND LAG(DESPNOTE, 1, 0) OVER (ORDER BY DESPNOTE) != DESPNOTE  THEN SELLEXCL
--              ELSE NULL
--              END AS "Order Despatch Charge",
--       CASE   WHEN FEETYPE like 'Pick Fee ' AND LAG(DESPNOTE, 1, 0) OVER (ORDER BY DESPNOTE) != DESPNOTE  THEN SELLEXCL
--              ELSE NULL
--              END AS "Line Charge" 

From TMP_ALL_FEES_F
Where ORDERNUM = '   1969424' AND DESPNOTE = '   2287094';
--AND FEETYPE = 'Stock'
--Order By FEETYPE;