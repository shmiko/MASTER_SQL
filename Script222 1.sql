SELECT II_STOCK,II_CUST,II_BREAK_LCL
							FROM II INNER JOIN IM ON IM_STOCK = II_STOCK
							AND II_BREAK_LCL > 0.000001
SELECT LTrim(ST_PICK),LTrim(ST_PSLIP), substr(To_Char(ST_DESP_DATE),0,10), ST_WEIGHT, ST_PACKAGES,ST_XX_NUM_PAL_SW,ST_XX_NUM_PALLETS,ST_XX_NUM_CARTONS
							FROM ST LEFT JOIN SH ON SH_ORDER = ST_ORDER
							WHERE ST_DESP_DATE >= '1-Jun-2015' AND ST_DESP_DATE <= '30-Jun-2015'	AND ST_PSLIP != 'CANCELLED'
							AND SH_STATUS <> 3

SELECT MAX(SL_LINE),LTrim(SL_PICK), LTrim(SL_ORDER), LTrim(SL_PSLIP),TP.vDateDesp, TP.vPackages,TP.vWeight,TP.vST_XX_NUM_PAL_SW,TP.vST_XX_NUM_PALLETS,TP.vST_XX_NUM_CARTONS
							FROM Tmp_Admin_Data_Pickslips TP RIGHT JOIN SL ON LTrim(SL_PICK) = TP.vPickslip WHERE SL_EDIT_DATE >= '1-Jun-2015' AND SL_EDIT_DATE <= '30-Jun-2015'
							GROUP BY SL_PICK,SL_ORDER,SL_PSLIP,TP.vDateDesp,TP.vPackages,TP.vWeight,TP.vST_XX_NUM_PAL_SW,TP.vST_XX_NUM_PALLETS,TP.vST_XX_NUM_CARTONS

SELECT nz.NI_STOCK, LTrim(RTrim(nz.NI_SL_PSLIP)), CAST((NX_SELL_VALUE/NX_QUANTITY) AS DECIMAL(22,2)) AS "UnitPrice", CAST(xz.NX_SELL_VALUE AS DECIMAL(22,2)), xz.NX_QUANTITY
						FROM  NX xz INNER JOIN NI nz ON nz.NI_NX_MOVEMENT = xz.NX_MOVEMENT
						INNER JOIN NE ez ON ez.NE_ENTRY = nz.NI_ENTRY AND ez.NE_PRICE_ENTRY = xz.NX_ENTRY
						WHERE ez.NE_NV_EXT_TYPE = 1810105
						AND ez.NE_STRENGTH = 3
						AND xz.NX_SELL_VALUE > 0 AND xz.NX_SELL_VALUE IS NOT NULL
						AND xz.NX_QUANTITY > 1
						AND ez.NE_ADD_DATE >= '1-Jun-2015' AND ez.NE_ADD_DATE <= '30-Jun-2015'
						GROUP BY nz.NI_STOCK, nz.NI_SL_PSLIP, xz.NX_SELL_VALUE, xz.NX_QUANTITY

SELECT LAST_DAY( sysdate ) FROM dual;


SELECT To_Date(LAST_DAY(ADD_MONTHS(sysdate,-1)),'YYYYMMDD')  from dual;


SELECT LAST_DAY(ADD_MONTHS(sysdate,-2)) from dual;

select  to_char(to_date(to_char(LAST_DAY(ADD_MONTHS(sysdate,-1)),'YYYY-MM-DD'),'YYYY-MM-DD'),'YYYY-MM-DD') AS "todate",
        CAST((to_date(to_char(LAST_DAY(ADD_MONTHS(sysdate,-2)),'YYYY-MM-DD'),'YYYY-MM-DD') + 1) AS VARCHAR(10)) AS "Fromdate"  from dual;

select  to_char(to_date(to_char(LAST_DAY(ADD_MONTHS(sysdate,-1)),'YYYY-MM-DD'),'YYYY-MM-DD'),'YYYY-MM-DD') AS "todate",
        to_date(to_char(LAST_DAY(ADD_MONTHS(sysdate,-2)),'YYYY-MM-DD'),'YYYY-MM-DD') + 1 AS "Fromdate"  from dual;



 CAST((NX_SELL_VALUE/NX_QUANTITY) AS DECIMAL(22,2))
select to_date(to_char(LAST_DAY(ADD_MONTHS(sysdate,-2)),'DD-MM-YYYY'),'DD-MM-YYYY'),to_date(to_char(LAST_DAY(ADD_MONTHS(sysdate,-2)),'DD-MM-YYYY'),'DD-MM-YYYY') + 1   from dual;

SELECT to_char(LAST_DAY(ADD_MONTHS(sysdate,-2)) + 1,'YYYY-MM-DD') AS "START DATE", to_char(LAST_DAY(ADD_MONTHS(sysdate,-1)),'YYYY-MM-DD') AS "END DATE" from dual;

select to_char(LAST_DAY(ADD_MONTHS(sysdate,-1)),'DD-MM-YYYY')  from dual;

select to_char(LAST_DAY(ADD_MONTHS(sysdate,-2)),'DD-MM-YYYY')   from dual;



SELECT  Max(LAST_DAY(ADD_MONTHS(SYSDATE, -2)) + level)
FROM    dual
CONNECT BY
    level <= LAST_DAY(ADD_MONTHS(SYSDATE, -1)) - LAST_DAY(ADD_MONTHS(SYSDATE, -2))


SELECT CAST(SYSDATE) AS VARCHAR(10), TO_CHAR(sysdate, 'YYYY-MM-DD') FROM dual


SELECT to_char(sysdate,'YYYYMMDD') FROM dual;


SELECT to_char(sysdate,'YYYY-MM-DD') FROM dual;


select to_char(trunc(trunc(sysdate, 'MM') - 1, 'MM'),'DD-MM-YYYY') "First Day of Last Month",
to_char(trunc(sysdate, 'MM') - 1,'DD-MM-YYYY') "Last Day of Last Month"
from dual



SELECT * FROM Tmp_Admin_Data_Pick_LineCounts






 select    s.SH_CUST                AS "Customer",
			  r.sGroupCust              AS "Parent",
			  s.SH_SPARE_STR_4         AS "CostCentre",
			  s.SH_ORDER               AS "Order",
			  s.SH_SPARE_STR_5         AS "OrderwareNum",
			  s.SH_CUST_REF            AS "CustomerRef",
			  t.ST_PICK                AS "Pickslip",
			  d.SD_XX_PICKLIST_NUM     AS "PickNum",
			  t.ST_PSLIP               AS "DespatchNote",
			  substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	      CASE  WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 0.1 THEN 'Freight Fee'
			          ELSE To_Char(d.SD_DESC)
			          END                      AS "FeeType",
			  d.SD_STOCK               AS "Item",
			  '="' || To_Char(d.SD_DESC) || '"'               AS "Description",
	      CASE  WHEN d.SD_LINE IS NOT NULL THEN  1
			        ELSE NULL
			        END                     AS "Qty",
	      CASE  WHEN d.SD_LINE IS NOT NULL THEN  '1'
			        ELSE NULL
			        END                      AS "UOI",

        CASE  WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.sGroupCust <> 'BORBUI' AND r.sGroupCust <> 'BEYONDBLUE') THEN d.SD_SELL_PRICE
			        WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.sGroupCust = 'BORBUI' OR r.sGroupCust = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.125) And (t.ST_SPARE_DBL_1 > 0.00) THEN 1.70
              WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.sGroupCust = 'BORBUI' OR r.sGroupCust = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.250) And (t.ST_SPARE_DBL_1 > 0.126) THEN 2.30
              WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.sGroupCust = 'BORBUI' OR r.sGroupCust = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.500) And (t.ST_SPARE_DBL_1 > 0.251) THEN 3.40
              WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.sGroupCust = 'BORBUI' OR r.sGroupCust = 'BEYONDBLUE') AND (t.ST_WEIGHT > 0.01) THEN d.SD_SELL_PRICE
              ELSE NULL
			        END                      AS "UnitPrice",
			  d.SD_XX_OW_UNIT_PRICE    AS "OWUnitPrice",
			  d.SD_EXCL                AS "DExcl",
			  Sum(d.SD_EXCL)           AS "Excl_Total",
			  d.SD_INCL                AS "DIncl",
			  Sum(d.SD_INCL)           AS "Incl_Total",
			  NULL                     AS "ReportingPrice",
			  s.SH_ADDRESS             AS "Address",
			  s.SH_SUBURB              AS "Address2",
			  s.SH_CITY                AS "Suburb",
			  s.SH_STATE               AS "State",
			  s.SH_POST_CODE           AS "Postcode",
			  s.SH_NOTE_1              AS "DeliverTo",
			  s.SH_NOTE_2              AS "AttentionTo" ,
			  t.ST_WEIGHT              AS "Weight",
			  t.ST_PACKAGES            AS "Packages",
			  s.SH_SPARE_DBL_9         AS "OrderSource",
			  NULL AS "Pallet/Shelf Space", /*Pallet/Space*/
				NULL AS "Locn", /*Locn*/
			--	0 AS "AvailSOH",/*Avail SOH*/
				0 AS "CountOfStocks",
        CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			        ELSE ''
			        END AS Email,
              'N/A' AS Brand,
           NULL AS    OwnedBy,
           NULL AS    sProfile,
           NULL AS    WaiveFee,
           d.SD_COST_PRICE As   Cost,
           NULL AS PaymentType
	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_PICK))  = LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM))
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
	WHERE     s.SH_ORDER = d.SD_ORDER
	--AND       r.RM_ANAL = :sAnalysis
	AND       (r.sGroupCust = 'IAG' OR r.sCust = 'IAG')
	AND       d.SD_STOCK IN ('COURIERM','COURIERS','COURIER')
	AND       s.SH_ORDER = t.ST_ORDER
	AND       d.SD_SELL_PRICE >= 0.1
	--AND       t.ST_DESP_DATE >= start_date
  AND       t.ST_DESP_DATE >= F_FIRST_DAY_PREV_MONTH AND t.ST_DESP_DATE <= F_LAST_DAY_PREV_MONTH
  AND   d.SD_ADD_OP LIKE 'SERV%'

 /* 	WHERE     r.sGroupCust = :sCust OR r.sCust = :sCust
	AND       d.SD_STOCK LIKE :sCourier -- (:courier1,:courier2,:courier3)
	AND       s.SH_ORDER = t.ST_ORDER
	AND       d.SD_SELL_PRICE >= 0.1
	AND       t.ST_DESP_DATE >= start_date AND t.ST_DESP_DATE <= end_date
  AND   d.SD_ADD_OP LIKE :sServ3;
  USING sCust,sCust,sCourier,start_date,end_date,sServ3;

 -- OPEN c(sCust,

  --AND s.SH_ORDER LIKE '   1377018'*/

	GROUP BY  s.SH_CUST,
			  s.SH_SPARE_STR_4,
			  s.SH_ORDER,
			  t.ST_PICK,
			  d.SD_XX_PICKLIST_NUM,
			  t.ST_PSLIP,
			  t.ST_DESP_DATE,
			  d.SD_STOCK,
			  d.SD_DESC,
			  d.SD_LINE,
			  d.SD_EXCL,
			  d.SD_INCL,
			  d.SD_NOTE_1,
			  d.SD_SELL_PRICE,
			  d.SD_XX_OW_UNIT_PRICE,
			  d.SD_QTY_ORDER,
			  d.SD_QTY_ORDER,
			  s.SH_ADDRESS,
			  s.SH_SUBURB,
			  s.SH_CITY,
			  s.SH_STATE,
			  s.SH_POST_CODE,
			  s.SH_NOTE_1,
			  s.SH_NOTE_2,
			  t.ST_WEIGHT,
			  t.ST_PACKAGES,
			  s.SH_SPARE_DBL_9,
			  r.sGroupCust,
			  s.SH_SPARE_STR_5,
			  s.SH_CUST_REF,
        s.SH_SPARE_STR_3,
        s.SH_SPARE_STR_1,
        t.ST_SPARE_DBL_1,
        d.SD_XX_PSLIP_NUM,
          d.SD_ADD_DATE,
          d.SD_XX_PICKLIST_NUM,
          d.SD_COST_PRICE;


SELECT ST_DESP_DATE, ST_PICK FROM ST
GROUP BY ST_DESP_DATE,ST_PICK
HAVING TO_CHAR(ST_DESP_DATE) >= PWIN175.F_FIRST_DAY_PREV_MONTH AND TO_CHAR(ST_DESP_DATE) <= PWIN175.F_LAST_DAY_PREV_MONTH

SELECT PWIN175.F_FIRST_DAY_PREV_MONTH,PWIN175.F_LAST_DAY_PREV_MONTH,ST_DESP_DATE, ST_PICK FROM ST
WHERE TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= PWIN175.F_FIRST_DAY_PREV_MONTH AND TO_CHAR(ST_DESP_DATE,'YYYY-MM-DD') <= PWIN175.F_LAST_DAY_PREV_MONTH


SELECT * FROM YN WHERE YN_DESC = 9095703


Select * from TMP_ORD_FEES;

SELECT * FROM Tmp_Group_Cust;


SELECT Count(DISTINCT NI_STOCK) AS CountOfStocks, IL_LOCN, IM_CUST, IM_STOCK, IM_XX_ABSTRACT2, IM_DESC, NI_AVAIL_ACTUAL,
                      (Select NI_DATE From n1 NI Where n1.NI_TRAN_TYPE = 1 AND n1.NI_STOCK = 'N000028119' Order By n1.NI_DATE Desc ) As Last Receipt,
                      (Select NI_DATE From n2 NI Where n2.NI_TRAN_TYPE = 3 AND n2.NI_STOCK = 'N000028119' Order By n2.NI_DATE Desc limit(1)) As Last Used Date
						        FROM IL INNER JOIN n NI  ON IL_LOCN = n.NI_LOCN
						        INNER JOIN IM ON IM_STOCK = n.NI_STOCK
						        WHERE IM_CUST LIKE '%D-%'
                    --OR IM_CUST LIKE :cust
						        AND IM_ACTIVE = 1
						        AND n.NI_AVAIL_ACTUAL >= '1'
						        AND n.NI_STATUS <> 0
						        GROUP BY IL_LOCN, IM_CUST
                    ORDER BY 3,2,1







INSERT INTO Tmp_Admin_Data_Pickslips
SELECT LTrim(ST_PICK),LTrim(ST_PSLIP), substr(To_Char(ST_DESP_DATE),0,10), ST_WEIGHT, ST_PACKAGES,ST_XX_NUM_PAL_SW,ST_XX_NUM_PALLETS,ST_XX_NUM_CARTONS
FROM ST LEFT JOIN SH ON SH_ORDER = ST_ORDER
WHERE TO_CHAR(ST_DESP_DATE,'YYYY-MM-DD') >= F_FIRST_DAY_PREV_MONTH AND TO_CHAR(ST_DESP_DATE,'YYYY-MM-DD') <= F_LAST_DAY_PREV_MONTH	AND ST_PSLIP != 'CANCELLED'
AND SH_STATUS <> 3;

Select * From Tmp_Admin_Data_Pickslips;
SELECT * FROM Tmp_Admin_Data_Pick_LineCounts;
SELECT * FROM Tmp_Locn_Cnt_By_Cust;
SELECT * FROM TMP_FREIGHT;
SELECT Count(*) FROM TMP_FREIGHT;
Select * from TMP_ORD_FEES;
Select Count(*) From TMP_ORD_FEES;
SELECT * FROM Tmp_Group_Cust;
Truncate table Tmp_Group_Cust;
SELECT Count(*) FROM Tmp_Group_Cust;

