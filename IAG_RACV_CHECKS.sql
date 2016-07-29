--Get all stocks where there is an alternate SPDS in use
SELECT IM_STOCK, IA_ALT_STOCK, IM_XX_CC01_QTY
FROM IM INNER JOIN IA ON IM_STOCK = IA_STOCK
WHERE IA_ADD_OP = 'PRJ' AND IM_XX_CC01_QTY > 0

--Get Count of above stocks
SELECT Count(*) AS TotalStocks --IM_STOCK, IA_ALT_STOCK, IM_XX_CC01_QTY
FROM IM INNER JOIN IA ON IM_STOCK = IA_STOCK
WHERE IA_ADD_OP = 'PRJ' AND IM_XX_CC01_QTY > 0


--List ALL orders with PDS
SELECT SD_ORDER ,SD_STOCK, SD_ADD_DATE, SD_LAST_PICK_NUM,  SD_ADD_TIME, SD_ADD_OP, SD_LOCN
FROM SD
WHERE SD_STOCK IN (SELECT IM_STOCK
FROM IM INNER JOIN IA ON IM_STOCK = IA_STOCK
WHERE IA_ADD_OP = 'PRJ' AND IM_XX_CC01_QTY > 0)
AND SD_ADD_DATE = '1-May-2014'

ORDER BY 1,3,6 DESC


--List ALL orders with and without PDS
SELECT SD_ORDER ,SD_STOCK, SD_ADD_DATE, SD_LAST_PICK_NUM,  SD_ADD_TIME, SD_ADD_OP, SD_LOCN, IA_ALT_STOCK, IM_XX_CC01_QTY, SH_CUST, sGroupCust, SD_LINE
FROM   SD INNER       JOIN SH             ON SH_ORDER = SD_ORDER
          LEFT        JOIN Tmp_Group_Cust ON sCust    = SH_CUST
          INNER       JOIN IM             ON IM_STOCK = SD_STOCK
          LEFT OUTER  JOIN IA             ON IM_STOCK = IA_STOCK
WHERE SD_ADD_DATE > '25-May-2014' AND SD_STOCK NOT LIKE 'COURIER%'
AND sGroupCust IN ('RACV','IAG')

ORDER BY 1,3,6 DESC



--Count Total orders with PDS
SELECT Count(SD_ORDER) AS TotalSPDSOrders
FROM SD
WHERE SD_STOCK IN (SELECT IM_STOCK
FROM IM INNER JOIN IA ON IM_STOCK = IA_STOCK
WHERE IA_ADD_OP = 'PRJ' AND IM_XX_CC01_QTY > 0)
AND SD_ADD_DATE >= '12-Aug-2014'



SELECT SH_ORDER, SH_ADD_DATE FROM SH WHERE SH_ORDER.LTRIM = '172'  AND ROWNUM = 1




--Get total count for all IAG/RACV Orders For Given Period
var nOrderCount NUMBER
EXEC SELECT EOM_REPORT_PKG.total_orders('IAG',3, '26-May-2014') INTO :nOrderCount FROM DUAL;
Print nOrderCount;

var nOrderCountR NUMBER
EXEC SELECT EOM_REPORT_PKG.total_orders('RACV',3, '26-May-2014') INTO :nOrderCountR FROM DUAL;
Print nOrderCountR;


--Get total count for all IAG/RACV Despatches For Given Period
var nDespCount NUMBER
EXEC SELECT EOM_REPORT_PKG.total_despatches('IAG',3, '26-May-2014') INTO :nDespCount FROM DUAL;
Print nDespCount;

var nDespCountR NUMBER
EXEC SELECT EOM_REPORT_PKG.total_despatches('RACV',3, '26-May-2014') INTO :nDespCountR FROM DUAL;
Print nDespCountR;

--Get total order count for PDS orders SINCE SET DATE
SELECT SD_STOCK, SD_ADD_DATE, SD_LAST_PICK_NUM, SD_ORDER , SD_ADD_TIME, SD_ADD_OP, SD_LOCN
FROM SD
WHERE SD_STOCK IN (SELECT IM_STOCK
FROM IM INNER JOIN IA ON IM_STOCK = IA_STOCK
WHERE IA_ADD_OP = 'PRJ' AND IM_XX_CC01_QTY > 0)
--AND SD_ADD_DATE >= SYSDATE    - 2
--AND SD_ORDER >= '   1550725'
AND SD_ADD_DATE >= '19-Aug-2014'
ORDER BY 2 ASC



--Run this first so as we get the latest sorted customer list

var start_date varchar2(20)
exec :start_date := To_Date('1-Jul-2014')
var end_date varchar2(20)
exec :end_date := To_Date('29-Jul-2014')


EXECUTE eom_report_pkg.GROUP_CUST_START;
SELECT * FROM Tmp_Group_Cust
/*1*/
--Get all despatch data
SELECT  d.SD_ORDER,d.SD_STOCK,d.SD_ADD_DATE,d.SD_LAST_PICK_NUM,d.SD_ADD_TIME,d.SD_ADD_OP,d.SD_LOCN,d.SD_LINE
        ,s.SH_CUST,g.sGroupCust
        ,t.ST_DESP_DATE
FROM    PWIN175.SD d
			  LEFT  JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  RIGHT JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER
        LEFT  JOIN PWIN175.SL l  ON l.SL_PICK   = t.ST_PICK
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
        INNER JOIN PWIN175.NI n  ON n.NI_NV_EXT_KEY = l.SL_UID
        INNER JOIN Tmp_Group_Cust g ON g.sCust    = s.SH_CUST
  WHERE   NI_NV_EXT_TYPE = 1810105 AND NI_STRENGTH = 3 AND NI_DATE = t.ST_DESP_DATE AND NI_STOCK = d.SD_STOCK AND NI_STATUS <> 0
	AND     s.SH_STATUS <> 3
  AND     t.ST_ADD_DATE > :start_date AND t.ST_ADD_DATE < :end_date
  AND     sGroupCust IN ('RACV','IAG')
	ORDER BY 1 DESC


/*2*/
--Get all despatch data including S/PDS
SELECT  d.SD_ORDER ,d.SD_STOCK, d.SD_ADD_DATE, d.SD_LAST_PICK_NUM,  d.SD_ADD_TIME,d.SD_ADD_OP, d.SD_LOCN, d.SD_LINE
        , s.SH_CUST, g.sGroupCust
        ,t.ST_DESP_DATE
        --,a.IA_ALT_STOCK, i.IM_XX_CC01_QTY

FROM    PWIN175.SD d
			  LEFT JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  RIGHT JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER
        LEFT JOIN PWIN175.SL l   ON l.SL_PICK   = t.ST_PICK
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
        INNER JOIN PWIN175.NI n  ON n.NI_NV_EXT_KEY = l.SL_UID
        INNER JOIN Tmp_Group_Cust g ON g.sCust    = s.SH_CUST
        INNER JOIN IA a ON i.IM_STOCK = a.IA_STOCK
  WHERE   NI_NV_EXT_TYPE = 1810105 AND NI_STRENGTH = 3 AND NI_DATE = t.ST_DESP_DATE AND NI_STOCK = d.SD_STOCK AND NI_STATUS <> 0
	AND     s.SH_STATUS <> 3
  --AND     s.SH_ORDER = t.ST_ORDER
	AND     d.SD_ADD_DATE > :start_date AND d.SD_ADD_DATE < :end_date
  AND     sGroupCust IN ('RACV','IAG')
	--AND     d.SD_LAST_PICK_NUM = t.ST_PICK
  ORDER BY 1 DESC

/*3*/
--Get all despatch data where SPDS was missed
SELECT  d.SD_ORDER ,d.SD_STOCK, d.SD_ADD_DATE, d.SD_LAST_PICK_NUM,  d.SD_ADD_TIME,d.SD_ADD_OP, d.SD_LOCN, d.SD_LINE
        , s.SH_CUST, g.sGroupCust
        ,t.ST_DESP_DATE
        --,a.IA_ALT_STOCK, i.IM_XX_CC01_QTY
FROM    PWIN175.SD d
			  LEFT JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  RIGHT JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER
        LEFT JOIN PWIN175.SL l   ON l.SL_PICK   = t.ST_PICK
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
        INNER JOIN PWIN175.NI n  ON n.NI_NV_EXT_KEY = l.SL_UID
        INNER JOIN Tmp_Group_Cust g ON g.sCust    = s.SH_CUST
        INNER JOIN IA a ON i.IM_STOCK = a.IA_STOCK
  WHERE   NI_NV_EXT_TYPE = 1810105 AND NI_STRENGTH = 3 AND NI_DATE = t.ST_DESP_DATE AND NI_STOCK = d.SD_STOCK AND NI_STATUS <> 0
	AND     s.SH_STATUS <> 3
  --AND     s.SH_ORDER = t.ST_ORDER
	AND     d.SD_ADD_DATE > :start_date AND d.SD_ADD_DATE < :end_date
  AND     sGroupCust IN ('RACV','IAG')
	--AND     d.SD_LAST_PICK_NUM = t.ST_PICK
  ORDER BY 1 DESC

/*4*/
--Get all despatch data where manually fulfilled
SELECT  d.SD_ORDER ,d.SD_STOCK, d.SD_ADD_DATE, d.SD_LAST_PICK_NUM,  d.SD_ADD_TIME,d.SD_ADD_OP, d.SD_LOCN, d.SD_LINE
        , s.SH_CUST, g.sGroupCust
        ,t.ST_DESP_DATE
        --,a.IA_ALT_STOCK, i.IM_XX_CC01_QTY
FROM    PWIN175.SD d
			  LEFT JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  RIGHT JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER
        LEFT JOIN PWIN175.SL l   ON l.SL_PICK   = t.ST_PICK
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
        INNER JOIN PWIN175.NI n  ON n.NI_NV_EXT_KEY = l.SL_UID
        INNER JOIN Tmp_Group_Cust g ON g.sCust    = s.SH_CUST
        INNER JOIN IA a ON i.IM_STOCK = a.IA_STOCK
  WHERE   NI_NV_EXT_TYPE = 1810105 AND NI_STRENGTH = 3 AND NI_DATE = t.ST_DESP_DATE AND NI_STOCK = d.SD_STOCK AND NI_STATUS <> 0
	AND     s.SH_STATUS <> 3
  --AND     s.SH_ORDER = t.ST_ORDER
	AND     d.SD_ADD_DATE > :start_date AND d.SD_ADD_DATE < :end_date
  AND     sGroupCust IN ('RACV','IAG')
	--AND     d.SD_LAST_PICK_NUM = t.ST_PICK
  ORDER BY 1 DESC

/*5*/
--Get all despatch data where manually fulfilled and where PDS was included
SELECT  d.SD_ORDER ,d.SD_STOCK, d.SD_ADD_DATE, d.SD_LAST_PICK_NUM,  d.SD_ADD_TIME,d.SD_ADD_OP, d.SD_LOCN, d.SD_LINE
        , s.SH_CUST, g.sGroupCust
        ,t.ST_DESP_DATE
        --,a.IA_ALT_STOCK, i.IM_XX_CC01_QTY
FROM    PWIN175.SD d
			  LEFT JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  RIGHT JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER
        LEFT JOIN PWIN175.SL l   ON l.SL_PICK   = t.ST_PICK
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
        INNER JOIN PWIN175.NI n  ON n.NI_NV_EXT_KEY = l.SL_UID
        INNER JOIN Tmp_Group_Cust g ON g.sCust    = s.SH_CUST
        INNER JOIN IA a ON i.IM_STOCK = a.IA_STOCK
  WHERE   NI_NV_EXT_TYPE = 1810105 AND NI_STRENGTH = 3 AND NI_DATE = t.ST_DESP_DATE AND NI_STOCK = d.SD_STOCK AND NI_STATUS <> 0
	AND     s.SH_STATUS <> 3
  --AND     s.SH_ORDER = t.ST_ORDER
	AND     d.SD_ADD_DATE > :start_date AND d.SD_ADD_DATE < :end_date
  AND     sGroupCust IN ('RACV','IAG')
	--AND     d.SD_LAST_PICK_NUM = t.ST_PICK
  ORDER BY 1 DESC

/*6*/
--Get all despatch data where manually fulfilled and where SPDS was missed
SELECT  d.SD_ORDER ,d.SD_STOCK, d.SD_ADD_DATE, d.SD_LAST_PICK_NUM,  d.SD_ADD_TIME,d.SD_ADD_OP, d.SD_LOCN, d.SD_LINE
        , s.SH_CUST, g.sGroupCust
        ,t.ST_DESP_DATE
        --,a.IA_ALT_STOCK, i.IM_XX_CC01_QTY
FROM    PWIN175.SD d
			  LEFT JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  RIGHT JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER
        LEFT JOIN PWIN175.SL l   ON l.SL_PICK   = t.ST_PICK
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
        INNER JOIN PWIN175.NI n  ON n.NI_NV_EXT_KEY = l.SL_UID
        INNER JOIN Tmp_Group_Cust g ON g.sCust    = s.SH_CUST
        INNER JOIN IA a ON i.IM_STOCK = a.IA_STOCK
  WHERE   NI_NV_EXT_TYPE = 1810105 AND NI_STRENGTH = 3 AND NI_DATE = t.ST_DESP_DATE AND NI_STOCK = d.SD_STOCK AND NI_STATUS <> 0
	AND     s.SH_STATUS <> 3
  --AND     s.SH_ORDER = t.ST_ORDER
	AND     d.SD_ADD_DATE > :start_date AND d.SD_ADD_DATE < :end_date
  AND     sGroupCust IN ('RACV','IAG')
	--AND     d.SD_LAST_PICK_NUM = t.ST_PICK
  ORDER BY 1 DESC


