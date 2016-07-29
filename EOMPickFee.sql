--Admin Order Data
/*decalre variables*/
var cust varchar2(20)
exec :cust := 'TABCORP'
var ordernum varchar2(20)
exec :ordernum := '1363806'
var stock varchar2(20)
exec :stock := 'COURIER'
var source varchar2(20)
exec :source := 'BSPRINTNSW'
var anal varchar2(20)
exec :anal := '72'
var start_date varchar2(20)
exec :start_date := To_Date('1-Jul-2013')
var end_date varchar2(20)
exec :end_date := To_Date('24-Jul-2013')
var query VARCHAR2(200)
exec :query := '(SELECT LTrim(ST_ORDER)
                                FROM ST INNER JOIN SH ON SH_ORDER = ST_ORDER
                                WHERE /*ST_ORDER IN*/ EXISTS (SELECT LTrim(SH_ORDER) FROM SH WHERE SH_CUST IN(SELECT RM_CUST FROM RM WHERE RM_ANAL = :anal) AND SH_STATUS <> 3)
                                --AND RM_CUST = SH_CUST
                                AND ST_DESP_DATE >= :start_date AND ST_DESP_DATE <= :end_date)'
p_nb_list CONSTANT INTEGER_TT :=
--EXEC :pickslips :=


/*create temp table to hold pickslip numbers*/
DROP TABLE Tmp_Admin_Data_Pickslips


CREATE TABLE Tmp_Admin_Data_Pickslips (vPickslip VARCHAR(200),vPslip VARCHAR(10), vDateDesp VARCHAR(10), vPackages INTEGER, vWeight INTEGER)--           AS 'Customer',


INSERT INTO Tmp_Admin_Data_Pickslips
SELECT LTrim(ST_PICK),LTrim(ST_PSLIP), substr(To_Char(ST_DESP_DATE),0,10), ST_WEIGHT, ST_PACKAGES
FROM ST INNER JOIN SH ON SH_ORDER = ST_ORDER
WHERE ST_DESP_DATE >= :start_date AND ST_DESP_DATE <= :end_date
AND ST_PSLIP <> 'CANCELLED'
AND SH_STATUS <> 3

SELECT *
FROM Tmp_Admin_Data_Pickslips


/* Create another temp table to hold this data */
DROP TABLE Tmp_Admin_Data_Pick_LineCounts

CREATE TABLE Tmp_Admin_Data_Pick_LineCounts (  nCountOfLines INTEGER, vSLPickslipNum VARCHAR(10), vSLOrderNum VARCHAR2(10), vSLPslip VARCHAR(10), vDateDespSL VARCHAR(10)
,vPackagesSL INTEGER, vWeightSL INTEGER)

INSERT INTO Tmp_Admin_Data_Pick_LineCounts
/*Now join to SL and count lines per pick*/
SELECT Count(SL_LINE),LTrim(SL_PICK), LTrim(SL_ORDER), LTrim(SL_PSLIP),TP.vDateDesp, TP.vPackages,TP.vWeight
FROM Tmp_Admin_Data_Pickslips TP LEFT OUTER JOIN SL ON LTrim(SL_PICK) = TP.vPickslip   WHERE SL_PSLIP <> 'CANCELLED'  GROUP BY SL_PICK,SL_ORDER,SL_PSLIP,TP.vDateDesp,TP.vPackages,TP.vWeight


SELECT *
FROM Tmp_Admin_Data_Pick_LineCounts
WHERE vSLPickslipNum = '1275170'

/* Get Pick Fees  */
SELECT  s.SH_CUST                AS "Customer",
        s.SH_SPARE_STR_4         AS "CostCentre",
        s.SH_ORDER               AS "Order",
        t.vSLPickslipNum         AS "Pickslip",
        NULL                     AS "PickNum",
        t.vSLPslip               AS "DespatchNote",
        t.vDateDespSL             AS "DespatchDate",
        CASE    WHEN t.vSLPslip IS NOT NULL THEN 'Pick Fee'
          ELSE ''
          END                      AS "FeeType",
        CASE    WHEN t.vSLPslip IS NOT NULL THEN 'FEEPICK'
          ELSE ''
          END                      AS "Item",
        CASE    WHEN t.vSLPslip IS NOT NULL THEN 'Line Picking Fee'
          ELSE ''
          END                      AS "Description",
        t.nCountOfLines AS "Qty",
         CASE    WHEN t.vSLPslip IS NOT NULL THEN  '1'
          ELSE ''
          END                     AS "UOI",
         CASE   WHEN t.vSLPslip IS NOT NULL THEN '' || (Select RM_XX_FEE16 from RM where RM_CUST = :cust) * nCountOfLines
        ELSE ''
        END                      AS "UnitPrice",
        NULL                     AS "DExcl",
        NULL                     AS "OWUnitPrice",
        NULL                     AS "Excl_Total",
        NULL                     AS "DIncl",
        NULL                     AS "Incl_Total",
        NULL                     AS "ReportingPrice",
        s.SH_ADDRESS             AS "Address",
        s.SH_SUBURB              AS "Address2",
        s.SH_CITY                AS "Suburb",
        s.SH_STATE               AS "State",
        s.SH_POST_CODE           AS "Postcode",
        s.SH_NOTE_1              AS "DeliverTo",
        s.SH_NOTE_2              AS "AttentionTo" ,
        t.vWeightSL              AS "Weight",
        t.vPackagesSL            AS "Packages",
        s.SH_SPARE_DBL_9         AS "OrderSource"



FROM  Tmp_Admin_Data_Pick_LineCounts t LEFT JOIN PWIN175.SH s ON  LTrim(s.SH_ORDER) = t.vSLOrderNum
INNER JOIN RM r ON r.RM_CUST = s.SH_CUST
WHERE  s.SH_STATUS <> 3
AND SH_CUST IN (SELECT RM_CUST FROM RM WHERE RM_ANAL = :anal)
--AND r.RM_ANAL = :anal
GROUP BY  s.SH_ORDER,
          s.SH_SPARE_STR_4,
          s.SH_CUST,
          t.vSLPickslipNum,
          t.vSLPslip,
          t.vDateDespSL,
          s.SH_ADDRESS,
          s.SH_SUBURB,
          s.SH_CITY,
          s.SH_STATE,
          s.SH_POST_CODE,
          s.SH_NOTE_1,
          s.SH_NOTE_2 ,
          s.SH_NUM_LINES,
          t.vWeightSL,
          t.vPackagesSL,
          s.SH_SPARE_DBL_9,
          t.nCountOfLines,
          ROWNUM
--HAVING ROWNUM <= 10
ORDER BY s.SH_ORDER,t.vSLPickslipNum,t.vDateDespSL ASc



/*(SELECT ST_ORDER
                                FROM ST, SH, RM
                                WHERE ST_ORDER = SH_ORDER
                                AND RM_CUST = SH_CUST
                                AND ST_DESP_DATE >= :start_date AND ST_DESP_DATE <= :end_date
                                AND RM_ANAL = :anal
                                --ORDER BY ST_ORDER ASC
                                )*/
