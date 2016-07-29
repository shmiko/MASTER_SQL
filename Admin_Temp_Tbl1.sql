--Admin Order Data


CREATE TABLE Tmp_Admin_Data
(       vSH_ORDER VARCHAR(255), vSH_CUST VARCHAR(255), vST_PICK VARCHAR(255), vST_DESP_DATE VARCHAR(255), vSD_STOCK VARCHAR(255), vSD_LINE VARCHAR(255), vStock VARCHAR(255), vFeeDesc VARCHAR(255), vFee VARCHAR(255)
)




/*decalre variables*/
var cust varchar2(20)
exec :cust := 'TABCORP'
var stock varchar2(20)
exec :stock := 'COURIER'
var source varchar2(20)
exec :source := 'BSPRINTNSW'
var anal varchar2(20)
exec :anal := '72'
var start_date varchar2(20)
exec :start_date := To_Date('26-Jun-2013')
var end_date varchar2(20)
exec :end_date := To_Date('30-Jun-2013')




INSERT into Tmp_Admin_Data(vSH_ORDER, vSH_CUST, vST_PICK, vST_DESP_DATE, vSD_STOCK, vSD_LINE, vStock, vFeeDesc, vFee)
VALUES ('232323','Cust','Pick','Date', 'PickFee','1','Pickfee','Pickfee','5'),

SELECT DISTINCT s.SH_ORDER, s.SH_CUST, t.ST_PICK, t.ST_DESP_DATE,d.SD_STOCK AS "SD_STOCK", d.SD_LINE,
          CASE   /* Get Stock*/
	        WHEN ((r.RM_XX_FEE01 IS NOT NULL) AND (s.SH_SPARE_DBL_9 = 1 OR s.SH_SPARE_DBL_9 = 3 OR s.SH_SPARE_DBL_9 = 2 OR s.SH_SPARE_DBL_9 = 4)) THEN 'OrderEntry'
          WHEN ((r.RM_XX_FEE08 IS NOT NULL) AND (i.IM_TYPE = 'BB_PACK')) THEN 'Packing'
          WHEN ((r.RM_XX_FEE25 IS NOT NULL) AND (s.SH_NOTE_1 = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE')) THEN 'Destruction'
          WHEN ((r.RM_XX_FEE16 IS NOT NULL) AND (d.SD_STOCK NOT like 'COURIER%')) THEN 'Pick'
          WHEN ((r.RM_XX_FEE06 IS NOT NULL) AND (d.SD_LINE IS NOT NULL)) THEN 'Handeling'
          WHEN d.SD_STOCK like 'COURIER%' THEN 'Freight'
          ELSE d.SD_STOCK
          --ELSE
          END AS "SD_STOCK"




FROM pwin175.SH s
INNER JOIN PWIN175.RM r ON r.RM_CUST  = s.SH_CUST
,pwin175.ST t
INNER JOIN PWIN175.SD d ON d.SD_ORDER  = t.ST_ORDER
INNER JOIN PWIN175.IM i ON i.IM_STOCK = d.SD_STOCK


WHERE r.RM_ANAL = :anal
AND LTRIM(RTRIM(ST_PICK)) = LTRIM(RTRIM(SD_XX_PICKLIST_NUM))
AND s.SH_ORDER = t.ST_ORDER
AND ((d.SD_LAST_PICK_NUM = t.ST_PICK OR d.SD_XX_PICKLIST_NUM = t.ST_PICK OR d.SD_STOCK = :stock ))
AND (t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date)
AND s.SH_ORDER = '   1287140'



  IF (SELECT vSH_ORDER FROM Tmp_Admin_Data WHERE vSH_ORDER='232323')= IS NOT NULL
      UPDATE
            Tmp_Admin_Data
      SET
            vSH_ORDER='123456'
      WHERE
            vSH_ORDER='232323'

  ELSE

      INSERT into Tmp_Admin_Data(vSH_ORDER, vSH_CUST, vST_PICK, vST_DESP_DATE, vSD_STOCK, vSD_LINE, vStock, vFeeDesc, vFee)
      VALUES ('232323','Cust','Pick','Date', 'PickFee','1','Pickfee','Pickfee','5')


GROUP BY SH_ORDER, SH_CUST, ST_PICK, ST_DESP_DATE,SH_NUM_LINES, SH_ADDRESS, SH_SUBURB, SH_CITY,
SH_STATE, SH_POST_CODE, SH_NOTE_1, SH_CAMPAIGN, SH_NOTE_2 , ST_WEIGHT, ST_PACKAGES,SD_STOCK,SD_SELL_PRICE,
SH_SPARE_DBL_9,ST_XX_NUM_PALLETS,ST_XX_NUM_CARTONS,ST_XX_NUM_PAL_SW , SD_LINE ,RM_XX_FEE01,RM_XX_FEE08,
RM_XX_FEE25,RM_XX_FEE16,RM_XX_FEE06,IM_TYPE
ORDER BY SH_ORDER, SD_LINE


select *  from Tmp_Admin_Data

drop table Tmp_Admin_Data



--End Admin Order Data







SELECT DISTINCT
     T1.MyField1,
     T1.MyField2,
     T1.MyField3,
     T1.MyField4,
     T1.MyField5
FROM
     MyTable T1
LEFT OUTER JOIN MyTable T2 ON
     T2.MyField1 = T1.MyField1 AND
     T2.MyField2 = T1.MyField2 AND
     T2.MyField3 = T1.MyField3 AND
     (
          T2.MyField4 > T1.MyField4 OR
          (
               T2.MyField4 = T1.MyField4 AND
               T2.MyField5 > T1.MyField5
          )
     )
WHERE
     T2.MyField1 IS NULL