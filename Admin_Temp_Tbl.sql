--Admin Order Data
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


CREATE TABLE Tmp_Admin_Data
(       vSH_ORDER VARCHAR(255), vSH_CUST VARCHAR(255), vST_PICK VARCHAR(255), vST_DESP_DATE VARCHAR(255), vNUMLINE VARCHAR(255), vSH_ADDRESS VARCHAR(255), vSH_SUBURB VARCHAR(255),
        vSH_CITY VARCHAR(255), vSH_STATE VARCHAR(255), vSH_POST_CODE VARCHAR(255), vSH_NOTE_1 VARCHAR(255), vSH_NOTE_2 VARCHAR(255), vST_WEIGHT VARCHAR(255), vST_PACKAGES VARCHAR(255),
        vSD_STOCK VARCHAR(255), vSD_LINE VARCHAR(255), vOrderFee VARCHAR(255), vStockUnitPrice VARCHAR(255), vDestructionFee VARCHAR(255), vEmergencyFee VARCHAR(255), vPalletFee VARCHAR(255),
        vCartonFee VARCHAR(255), vShrinkWrapFee VARCHAR(255), vHandelingFee VARCHAR(255), vFreightPickFee  VARCHAR(255)
)

INSERT into Tmp_Admin_Data(vSH_ORDER, vSH_CUST, vST_PICK, vST_DESP_DATE, vNUMLINE, vSH_ADDRESS, vSH_SUBURB,
        vSH_CITY, vSH_STATE, vSH_POST_CODE, vSH_NOTE_1, vSH_NOTE_2, vST_WEIGHT, vST_PACKAGES,
        vSD_STOCK, vSD_LINE, vOrderFee, vStockUnitPrice, vDestructionFee, vEmergencyFee, vPalletFee,
        vCartonFee, vShrinkWrapFee, vHandelingFee, vFreightPickFee)

SELECT DISTINCT s.SH_ORDER, s.SH_CUST, t.ST_PICK, t.ST_DESP_DATE, s.SH_NUM_LINES,s.SH_ADDRESS, s.SH_SUBURB, s.SH_CITY,
s.SH_STATE, s.SH_POST_CODE, s.SH_NOTE_1, s.SH_NOTE_2 , t.ST_WEIGHT, t.ST_PACKAGES,d.SD_STOCK, d.SD_LINE,
       CASE   /* Get Order Fees*/
	        WHEN s.SH_SPARE_DBL_9 = 1 OR s.SH_SPARE_DBL_9 = 3 OR s.SH_SPARE_DBL_9 = 2 OR s.SH_SPARE_DBL_9 = 4 THEN /*'OrderFee is '*/ '' ||  (Select RM_XX_FEE01 from RM where RM_CUST = 'BEYONDBLUE')
          ELSE ''
          END AS "OrderFee",
	  	--CASE   /* Get Packing Fees If stock is of type BB_PACK then charge sRM_XX_FEE08.AsDouble * SL_PSLIP_QTY  */
	       -- WHEN i.IM_TYPE = 'BB_PACK'  THEN /*'Packing Fee is '*/ '' ||  (Select RM_XX_FEE08 from RM where RM_CUST = 'BEYONDBLUE')
         -- ELSE ''
         -- END AS "PackingFee",
      CASE   /* Get Unit Prices*/
	        WHEN d.SD_SELL_PRICE < 0.1 THEN /*'Unit Price is '*/ '' ||  (Select i.IM_REPORTING_PRICE from IM i where i.IM_STOCK = d.SD_STOCK)
          ELSE ''
          END AS "StockUnitPrice",
      CASE  /* Get Destruction Fees*/
	        WHEN s.SH_NOTE_1 = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN /*'Destruction Fee is '*/'' ||  (Select RM_XX_FEE25 from RM where RM_CUST = 'BEYONDBLUE')
          ELSE ''
          END AS "DestructionFee",
      CASE  /* Get Emergency Fees*/
	        WHEN d.SD_STOCK = 'EMERQSRFEE' OR s.SH_CAMPAIGN = 'TABSPEC' THEN /*'Emergency Fee is '*/'' || CAST(d.SD_SELL_PRICE AS VARCHAR(20))
          ELSE ''
          END AS "EmergencyFee",
      CASE  /* Get Pallet Despatch Fees*/
	        WHEN ST_XX_NUM_PALLETS >= 1 THEN /*'Pallet Fee is '*/'' ||  (Select RM_XX_FEE17 from RM where RM_CUST = 'BEYONDBLUE' )
          ELSE ''
          END AS "PalletFee",
      CASE  /* Get Carton Despatch Fees*/
	        WHEN ST_XX_NUM_CARTONS >= 1 THEN /*'Carton Fee is '*/'' ||  (Select RM_XX_FEE15 from RM where RM_CUST = 'BEYONDBLUE' )
          ELSE ''
          END AS "CartonFee",
      CASE  /* Get ShrinkWrap Fees*/
	        WHEN ST_XX_NUM_PAL_SW >= 1 THEN /*'ShrinkWrap Fee is '*/'' ||  (Select RM_XX_FEE18 from RM where RM_CUST = 'BEYONDBLUE' )
          ELSE ''
          END AS "ShrinkWrapFee",
      CASE  /* Get Handeling Fees*/
	        WHEN d.SD_LINE = 1 THEN /*'Handeling Fee is '*/'' ||  (Select RM_XX_FEE06 from RM where RM_CUST = 'BEYONDBLUE')
          ELSE ''
          END AS "HandelingFee",
      CASE   /* Get Freight Fees*/
          WHEN d.SD_STOCK like 'COURIER%' THEN /*'Freight Fee is '*/ '' || CAST(d.SD_SELL_PRICE AS VARCHAR(20))
          ELSE /*'Pick Fee is '*/'' ||  (Select RM_XX_FEE16 from RM where RM_CUST = 'BEYONDBLUE')
          END AS "Freight/PickFee"

FROM PWIN175.ST t
--PWIN175.SD d
INNER JOIN PWIN175.SD d ON d.SD_ORDER  = t.ST_ORDER
/*    AND ( d.SD_XX_PSLIP_NUM = t.ST_PSLIP
    OR d.SD_LAST_PSLIP_NUM = t.ST_PSLIP)
    AND (d.SD_STOCK = 'COURIER')--  OR d.SD_STOCK LIKE '%') */
INNER JOIN PWIN175.IM i ON i.IM_STOCK = d.SD_STOCK
INNER JOIN PWIN175.SH s ON s.SH_ORDER = d.SD_ORDER

--INNER JOIN PWIN175.SL l ON l.SL_PICK = t.ST_PICK
INNER JOIN PWIN175.RM r ON r.RM_CUST  = s.SH_CUST

WHERE r.RM_ANAL = '75'
AND ((d.SD_LAST_PICK_NUM = t.ST_PICK OR d.SD_XX_PICKLIST_NUM = t.ST_PICK OR d.SD_STOCK = 'COURIER' ))
AND t.ST_DESP_DATE >= To_Date('1-Jun-2013') AND t.ST_DESP_DATE <= To_Date('3-Jun-2013')
--AND s.SH_ORDER = '   1344426'
GROUP BY SH_ORDER, SH_CUST, ST_PICK, ST_DESP_DATE,SH_NUM_LINES, SH_ADDRESS, SH_SUBURB, SH_CITY,
SH_STATE, SH_POST_CODE, SH_NOTE_1, SH_CAMPAIGN, SH_NOTE_2 , ST_WEIGHT, ST_PACKAGES,SD_STOCK,SD_SELL_PRICE,
SH_SPARE_DBL_9,ST_XX_NUM_PALLETS,ST_XX_NUM_CARTONS,ST_XX_NUM_PAL_SW , SD_LINE ,IM_TYPE
ORDER BY SH_ORDER, SD_LINE


select *  from Tmp_Admin_Data

drop table Tmp_Admin_Data



--End Admin Order Data
