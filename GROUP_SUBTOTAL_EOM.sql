SELECT CUSTOMER,NULL ,NULL


,PARENT,COSTCENTRE,ORDERNUM,ORDERWARENUM,CUSTREF,PICKSLIP
,DESPNOTE,DESPDATE,ORDERDATE,FEETYPE,ITEM,DESCRIPTION,QTY,UOI,UNITPRICE
,OWUNITPRICE,SELLEXCL,SELLINCL,REPORTINGPRICE,PREMARKUPSELL,COSTPRICE
,ADDRESS,ADDRESS2,SUBURB,STATE,POSTCODE,DELIVERTO,ATTENTIONTO,WEIGHT
,PACKAGES,ORDERSOURCE,ILNOTE2,NILOCN,COUNTOFSTOCKS,EMAIL,BRAND,OWNEDBY
,SPROFILE,WAIVEFEE,COST,PAYMENTTYPE,CAMPAIGN,ADDDATE,ADDOP,XXFREIGHT
FROM TMP_ALL_FEES_F

GROUP BY (CUSTOMER

,PARENT,COSTCENTRE,ORDERNUM,ORDERWARENUM,CUSTREF,PICKSLIP
,DESPNOTE,DESPDATE,ORDERDATE,FEETYPE,ITEM,DESCRIPTION,QTY,UOI,UNITPRICE
,OWUNITPRICE,SELLEXCL,SELLINCL,REPORTINGPRICE,PREMARKUPSELL,COSTPRICE
,ADDRESS,ADDRESS2,SUBURB,STATE,POSTCODE,DELIVERTO,ATTENTIONTO,WEIGHT
,PACKAGES,ORDERSOURCE,ILNOTE2,NILOCN,COUNTOFSTOCKS,EMAIL,BRAND,OWNEDBY
,SPROFILE,WAIVEFEE,COST,PAYMENTTYPE,CAMPAIGN,ADDDATE,ADDOP,XXFREIGHT)
UNION ALL
SELECT CUSTOMER ,SUM(SELLEXCL),Count(*),CUSTOMER || ' TOTALS',NULL,NULL,NULL,NULL,NULL
,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
,NULL,NULL,NULL,NULL,NULL,NULL
,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL  FROM TMP_ALL_FEES_F GROUP BY ROLLUP  ((CUSTOMER))
--GROUP BY CUSTOMER
ORDER BY CUSTOMER;
