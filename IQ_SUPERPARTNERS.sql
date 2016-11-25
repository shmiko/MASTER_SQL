Select QD_JOB_NUM,'|',QD_DES_SEQ, '|', QD_FIN_GOOD,'|', IM_REPORTING_PRICE,'|', QQ_UNIT_PRC,'|',QD_EDIT_DATE,'|', IM_CUST,'|', RM_PARENT  FROM QD, QM, IM,QQ, RM 
Where QD_JOB_NUM = QM_JOB_NUM AND QD_FIN_GOOD = IM_STOCK
AND QM_JOB_NUM = QQ_JOB_NUM
AND IM_CUST = RM_CUST
AND IM_ACTIVE = 1
AND QD_EDIT_DATE >= '01-JUN-2016' AND QD_EDIT_DATE <= '09-SEP-2016'
AND QQ_COLUMN = 4 
AND QQ_UNIT_PRC != IM_REPORTING_PRICE;


Select IM_STOCK, IM_REPORTING_PRICE From IM Where IM_EDIT_DATE = '19-Sep-2016' and IM_EDIT_OP = 'PRJ';

Select * From TMP_ALL_FEES_F;

Select Count(*) From TMP_ALL_FEES_F
Where ((ADDRESS LIKE '%Casselden%' Or ADDRESS LIKE '%Lonsdale%')
      OR (ADDRESS2 LIKE '%Casselden%' Or ADDRESS2 LIKE '%Lonsdale%'));
      
      Select Count(*) 
        --INTO  freight_count	     
        From TMP_ALL_FEES_F f3 Where ((f3.ADDRESS LIKE '%Casselden%' Or f3.ADDRESS LIKE '%Lonsdale%') OR (f3.ADDRESS2 LIKE '%Casselden%' Or f3.ADDRESS2 LIKE '%Lonsdale%')) 
        AND f3.DESPDATE = '10-Sep-2016'
         AND to_char(f3.DESPDATE, 'D') in (1,2,3,4,5);
        RETURN freight_count;
      
 select to_char (date '2016-09-20', 'D') d from dual;
 
 Select Count(*) From TMP_ALL_FEES_F f3 Where ((f3.ADDRESS LIKE '%Casselden%' Or f3.ADDRESS LIKE '%Lonsdale%') OR (f3.ADDRESS2 LIKE '%Casselden%' Or f3.ADDRESS2 LIKE '%Lonsdale%'))
      
Select f1.DESPDATE,f1.ORDERNUM,f1.DESPNOTE,f1.CUSTOMER,f1.ATTENTIONTO,f1.ADDRESS,f1.ADDRESS2,f1.SUBURB,f1.STATE,
             f1.POSTCODE,--f1.FEETYPE,
             f1.ITEM,f1.DESCRIPTION,f1.QTY,
             CASE   WHEN f1.FEETYPE like 'Stock' AND LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE THEN (Select f2.SELLEXCL From TMP_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND f2.FEETYPE = 'Pick Fee' ) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
                    ELSE 0
                    END AS "Line Charge",
            CASE   WHEN f1.FEETYPE like 'Stock' AND LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE THEN (Select f2.SELLEXCL From TMP_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND f2.FEETYPE = 'Handeling Fee is ' ) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
                    ELSE 0
                    END AS "Order Despatch Charge",
            CASE   WHEN f1.FEETYPE like 'Stock' AND LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE THEN (Select f2.SELLEXCL From TMP_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND (f2.FEETYPE like 'Freight Fee' OR f2.FEETYPE like 'Manual Freight Fee') ) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
                    ELSE 0
                    END AS "Freight Charge",
            --Daily Van Freight        
            CASE   WHEN (Select Count(*) From TMP_ALL_FEES_F f3 Where ((f3.ADDRESS LIKE '%Casselden%' Or f3.ADDRESS LIKE '%Lonsdale%') OR (f3.ADDRESS2 LIKE '%Casselden%' Or f3.ADDRESS2 LIKE '%Lonsdale%'))) THEN '30.71'
                    ELSE 0
                    END AS "Daily Flat Rate Freight Charge"
      From TMP_ALL_FEES_F f1
      Where f1.FEETYPE = 'Stock' 
      AND ((ADDRESS NOT LIKE '%Casselden%' Or ADDRESS NOT LIKE '%Lonsdale%')
      OR (ADDRESS2 NOT LIKE '%Casselden%' Or ADDRESS2 NOT LIKE '%Lonsdale%'));
      
Select  
       EXTRACT(DAY FROM TO_DATE(DESPDATE)),
       Count(ORDERNUM),DESPDATE
      From TMP_ALL_FEES_F
      Where FEETYPE = 'Stock' 
      AND ((ADDRESS  LIKE '%Casselden%' Or ADDRESS  LIKE '%Lonsdale%')
      OR (ADDRESS2  LIKE '%Casselden%' Or ADDRESS2  LIKE '%Lonsdale%'))
      GROUP BY EXTRACT(DAY FROM TO_DATE(DESPDATE)),DESPDATE;
      
Select  
       --EXTRACT(DAY FROM TO_DATE(DESPDATE)),
      Count(ORDERNUM)--,TRUNC(sysdate, 'DAY') -7
      From TMP_ALL_FEES_F
      Where FEETYPE = 'Freight Fee' 
      AND DESPDATE = To_Char(TRUNC(sysdate, 'DAY') -6) 
      AND ((ADDRESS  LIKE '%Casselden%' Or ADDRESS  LIKE '%Lonsdale%')
      OR (ADDRESS2  LIKE '%Casselden%' Or ADDRESS2  LIKE '%Lonsdale%'));
      --GROUP BY TRUNC(sysdate, 'DAY') -7;
      
Select  
--EXTRACT(DAY FROM TO_DATE(DESPDATE)),
Count(ORDERNUM),DESPDATE,
CASE WHEN F_DAILY_FREIGHT_COUNT2(DESPDATE,NULL,0) > 0 
Then "Daily Van Freight"
ELSE NULL
END AS  "Freight Charge"
From TMP_ALL_FEES_F
Where FEETYPE = 'Freight Fee' 
AND (InStr(UPPER(ADDRESS),'CASSELDEN') > 1 AND InStr(UPPER(ADDRESS2),'2 LONSDALE') > 1 )
GROUP BY 
--EXTRACT(DAY FROM TO_DATE(DESPDATE)),
DESPDATE;      
      
Select NULL,NULL,NULL,NULL,
NULL,NULL,NULL,NULL,NULL,NULL,
F_DAILY_FREIGHT_COUNT2(TRUNC(sysdate, 'DAY') -6,NULL,0) As "Qty",
CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(sysdate, 'DAY') -6,NULL,0) > 0 
Then  'Daily Van Freight'
ELSE NULL
END AS  "Freight Charge",
NULL,NULL,NULL,
CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(sysdate, 'DAY') -6,NULL,0) > 0 
Then '30.71'
ELSE NULL
END AS  "Freight Charge Cost"
From TMP_ALL_FEES_F
Where FEETYPE = 'Freight Fee' 
AND ((ADDRESS  LIKE '%Casselden%' Or ADDRESS  LIKE '%Lonsdale%')
OR (ADDRESS2  LIKE '%Casselden%' Or ADDRESS2  LIKE '%Lonsdale%'))
Group by TRUNC(sysdate, 'DAY') -6;


Select F_DAILY_FREIGHT_COUNT2('12/Sep/2016','12/Sep/2016',0) As Start_of_the_prev_week2 From Dual;

Select TO_CHAR(TRUNC(CURRENT_DATE, 'DAY') -6) From Dual;   

Select TRUNC(CURRENT_DATE, 'DAY') -6 From Dual

Select F_DAILY_FREIGHT_COUNT2(TO_CHAR(TRUNC(sysdate, 'DAY') -6),TO_CHAR(TRUNC(sysdate, 'DAY') -6),0) As Start_of_the_prev_week2 From Dual;
Select TO_CHAR(TRUNC(sysdate, 'DAY') -6) From Dual;       
Select  F_DAILY_FREIGHT_COUNT2(TRUNC(sysdate, 'DAY') -6,TO_CHAR(TRUNC(sysdate, 'DAY') -6),0) As "Qty",
        CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(sysdate, 'DAY') -6,TO_CHAR(TRUNC(sysdate, 'DAY') -6),0) > 0 
        Then 'Daily Van Freight'
        ELSE NULL
        END AS "Freight Charge",
        CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(sysdate, 'DAY') -6,TO_CHAR(TRUNC(sysdate, 'DAY') -6),0) > 0 
        Then '30.71'
        ELSE NULL
        END AS "Freight Charge Cost"
From TMP_ALL_FEES_F
Where FEETYPE = 'Freight Fee' 
AND (InStr(UPPER(ADDRESS),'CASSELDEN') > 1 AND InStr(UPPER(ADDRESS2),'2 LONSDALE') > 1 )

Select * From TMP_ALL_FEES_F
Select  f1.DESPDATE,f1.ORDERNUM,f1.DESPNOTE,f1.CUSTOMER,
        f1.ATTENTIONTO,f1.ADDRESS,f1.ADDRESS2,f1.SUBURB,f1.STATE,f1.POSTCODE,
        f1.ITEM,f1.DESCRIPTION,f1.QTY
             ,CASE   WHEN f1.FEETYPE like 'Stock' AND LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE 
             THEN (Select f2.SELLEXCL From TMP_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND f2.FEETYPE = 'Pick Fee' ) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
                    ELSE 0
                    END AS "Line Charge"
            ,CASE   WHEN f1.FEETYPE like 'Stock' AND LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE THEN (Select f2.SELLEXCL From TMP_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND f2.FEETYPE = 'Handeling Fee is ' ) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
                    ELSE 0
                    END AS "Order Despatch Charge"
--            ,CASE   WHEN f1.FEETYPE like 'Stock' AND LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE THEN (Select f2.SELLEXCL From TMP_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND (f2.FEETYPE like 'Freight Fee' OR f2.FEETYPE like 'Manual Freight Fee') ) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
--                    ELSE 0
--                    END AS "Freight Charge"
            --Daily Van Freight      
            -- (Select Count(*) From TMP_ALL_FEES_F Where ((ADDRESS LIKE '%Casselden%' Or ADDRESS LIKE '%Lonsdale%') OR (ADDRESS2 LIKE '%Casselden%' Or ADDRESS2 LIKE '%Lonsdale%'))) THEN '30.71'
            /*  CASE  WHEN F_DAILY_FREIGHT_COUNT(startdate,enddate) >= 1 AND to_char(DESPDATE, 'D') = 1 THEN '30.71' --monday
                    WHEN F_DAILY_FREIGHT_COUNT(startdate,enddate) >= 1 AND to_char(DESPDATE, 'D') = 2 THEN '30.71' --tuesday
                    WHEN F_DAILY_FREIGHT_COUNT(startdate,enddate) >= 1 AND to_char(DESPDATE, 'D') = 3 THEN '30.71' --wednesday
                    WHEN F_DAILY_FREIGHT_COUNT(startdate,enddate) >= 1 AND to_char(DESPDATE, 'D') = 4 THEN '30.71' --thursday
                    WHEN F_DAILY_FREIGHT_COUNT(startdate,enddate) >= 1 AND to_char(DESPDATE, 'D') = 5 THEN '30.71' --friday
                    ELSE 0
                    END AS "Daily Flat Rate Freight Charge"*/
      From TMP_ALL_FEES_F f1
      Where f1.FEETYPE = 'Stock' 
      AND (InStr(UPPER(ADDRESS),'CASSELDEN') < 1 AND InStr(UPPER(ADDRESS2),'2 LONSDALE') < 1 )
      
      
select country, 
       count(*) as members , 
       trunc(joined, 'MM')
  from table
 group by country,
          trunc(joined, 'MM')
      
create or replace FUNCTION F_IS_DAY_FIRST_OF_MONTH(
        startdate IN VARCHAR2
        )
  RETURN NUMBER
  RESULT_CACHE 
  RELIES_ON (S)
  AS

  Start_of_the_month NUMBER; -- 0 is true and 1 if false
  nbreakpoint   NUMBER;
  BEGIN
    nbreakpoint := 1;
        Select 
        CASE WHEN TO_DATE(startdate) = TRUNC(sysdate, 'MONTH') --Start_of_the_month 
             THEN 0
             ELSE 1
             END AS "Start_of_the_month
        INTO  Start_of_the_month	     
        From DUAL;
        RETURN Start_of_the_month;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('F_IS_DAY_FIRST_OF_MONTH failed at checkpoint ' || nbreakpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;  
  END F_IS_DAY_FIRST_OF_MONTH;      
  
  
 SELECT       EOM_REPORT_PKG.f_GetWarehouse_from_SD(s.SL_LOCN) AS Warehouse,
             sGroupCust,"
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
      
      
Select NULL,NULL,NULL,NULL,
      NULL,NULL,NULL,NULL,NULL,NULL,
      Case WHEN
        F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,0) > 0 
      Then
        F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,0) 
      END AS "Qty",
      CASE WHEN 
        F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,0) > 0
      Then 'Daily Van Freight'
      ELSE NULL
      END AS  "Freight Charge",
      NULL,NULL,NULL,
      CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,0) > 0 
      Then '30.71'
      ELSE NULL
      END AS  "Freight Charge Cost"
      From TMP_ALL_FEES_F f1
      Where f1.FEETYPE = 'Freight Fee' 
       AND ((ADDRESS  LIKE '%Casselden%' Or ADDRESS  LIKE '%Lonsdale%')
      OR (ADDRESS2  LIKE '%Casselden%' Or ADDRESS2  LIKE '%Lonsdale%'))
      Group by TRUNC(CURRENT_DATE, 'DAY') -6; 
      
Select NULL,NULL,NULL,NULL,
      NULL,NULL,NULL,NULL,NULL,NULL,
      Case WHEN
      F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,4) > 0 
      Then
      F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,4) 
      END AS "Qty",
      CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,4) > 0
      Then 'Daily Van Freight'
      ELSE NULL
      END AS  "Freight Charge"
      ,NULL,NULL,NULL,
      CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,4) > 0 
      Then '30.71'
      ELSE NULL
      END AS  "Freight Charge Cost"
      From TMP_ALL_FEES_F f1
      Where f1.FEETYPE = 'Freight Fee' 
       AND ((ADDRESS  LIKE '%Casselden%' Or ADDRESS  LIKE '%Lonsdale%')
      OR (ADDRESS2  LIKE '%Casselden%' Or ADDRESS2  LIKE '%Lonsdale%'))
      Group by TRUNC(CURRENT_DATE, 'DAY') -6 + 4;
      
     SELECT  TRUNC(CURRENT_TIMESTAMP, 'DAY') -6 FROM Dual;
SELECT SYSTIMESTAMP From Dual;
Select TRUNC(SYSTIMESTAMP, 'DAY') -6 From Dual; 

Select TRUNC (SYSDATE,'DAY') From Dual;

select trunc(to_date('2016-09-23', 'YYYY-MM-DD') + (49 - 1) * 7, 'WW') from dual;



Select
TRUNC(sysdate, 'MONTH') Start_of_the_month,
TRUNC(sysdate+30, 'MONTH')-1 End_of_the_month,
TRUNC(sysdate, 'DAY') -7 Start_of_the_prev_week,   -- start previous week
To_Char(TRUNC(sysdate, 'DAY') -7) Start_of_the_prev_week2,   -- start previous week

TRUNC(sysdate, 'DAY') -3 End_of_the_prev_week,   -- end previous week
TRUNC(sysdate, 'DAY') Start_of_the_week,  -- starting Monday
TRUNC(sysdate+6, 'DAY')-3 End_of_the_week     -- finish Friday
from dual;

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
          
          From DEV_ALL_FEES_F f1, IM
          Where f1.FEETYPE = 'Stock'
          AND f1.ITEM = IM_STOCK
          
          
          //test