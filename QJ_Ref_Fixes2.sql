
                                                YH_CODE_ID in ( select RH_YH_CODE_ID from PWIN175.RH TBLRH  where RH_ACTIVE=1 and RH_USE_IN_QJ!=0 and RH_RM_UID=102389 )





  SELECT RM_CUST, RM_EDIT_OP, RM_EDIT_DATE,RM_ANAL, YH_NAME FROM RM LEFT JOIN RH ON RH_RM_UID = RM_UID INNER JOIN YH ON YH_CODE_ID = RH_YH_CODE_ID WHERE RM_EDIT_DATE >= '1-Sep-2014'



  SELECT QM_UID,QM_CUST_CODE, QM_JOB_NUM,QM_QUOTE_NUM,RJ_EXT_KEY, QM_ADD_DATE, QM_ADD_OP, RM_UID, RI_CODE,RI_DEFAULT_NOTE
  FROM QM
  INNER JOIN RJ ON RJ_EXT_KEY = QM_UID
  INNER JOIN RI ON RI_AVAIL_CODE_ID = RJ_RI_AVAIL_CODE_ID
  INNER JOIN RM ON RM_CUST = QM_CUST_CODE
  WHERE QM_CUST_CODE IN (   SELECT RM_CUST
  FROM RM LEFT INNER JOIN RH ON RH_RM_UID = RM_UID
  INNER JOIN RI ON RI_RH_REF_CODE_ID = RH_REF_CODE_ID
  --INNER JOIN RJ ON RJ_RI_AVAIL_CODE_ID = RI_AVAIL_CODE_ID
  INNER JOIN YH ON YH_CODE_ID = RH_YH_CODE_ID
  WHERE RM_PARENT LIKE 'AMP%'   )
  --AND QM_CUST_CODE = 'FX080'
  AND QM_ADD_DATE >= '25-Jan-2013'
  --AND QM_QUOTE_STATUS IN (3,4,5)
  AND  QM_JOB_STATUS = 12 --IN (5,6,7,8,9,10)
  --AND RI_CODE LIKE 'FD%'
   ORDER BY 1,2


  SELECT QM_UID
  FROM QM
  WHERE QM_NUMBER IN ('    332569','    332571','    332572')
  AND QM_QUOTE_JOB IN (0,1)
   ORDER BY 1,2


  SELECT QM_UID FROM QM WHERE QM_NUMBER = '    332572'



  SELECT RM_CUST,RI_RH_REF_CODE_ID,RH_REF_CODE_ID
  FROM RM LEFT INNER JOIN RH ON RH_RM_UID = RM_UID
  INNER JOIN RI ON RI_RH_REF_CODE_ID = RH_REF_CODE_ID
  --INNER JOIN RJ ON RJ_RI_AVAIL_CODE_ID = RI_AVAIL_CODE_ID
  INNER JOIN YH ON YH_CODE_ID = RH_YH_CODE_ID
  WHERE RM_PARENT LIKE 'AMP%'  AND RI_DEFAULT_IN_QJ = 1


  DELETE FROM RI WHERE RI_RH_REF_CODE_ID = 100008 IN (
     SELECT RI_RH_REF_CODE_ID
    FROM RM LEFT INNER JOIN RH ON RH_RM_UID = RM_UID
    INNER JOIN RI ON RI_RH_REF_CODE_ID = RH_REF_CODE_ID
    --INNER JOIN RJ ON RJ_RI_AVAIL_CODE_ID = RI_AVAIL_CODE_ID
    INNER JOIN YH ON YH_CODE_ID = RH_YH_CODE_ID
    WHERE RM_CUST LIKE 'AMP%'  AND RI_DEFAULT_IN_QJ = 1
    )


  DELETE FROM RH WHERE RH_REF_CODE_ID = 100008 --IN (

    SELECT RH_REF_CODE_ID
  FROM RM LEFT INNER JOIN RH ON RH_RM_UID = RM_UID
  INNER JOIN YH ON YH_CODE_ID = RH_YH_CODE_ID
  WHERE RM_CUST LIKE 'AMP%'

  )


  SELECT RJ_EXT_KEY
  FROM QM
  INNER JOIN RJ ON RJ_EXT_KEY = QM_UID
  INNER JOIN RI ON RI_AVAIL_CODE_ID = RJ_RI_AVAIL_CODE_ID
  INNER JOIN RM ON RM_CUST = QM_CUST_CODE
  WHERE QM_CUST_CODE IN ( SELECT RM_CUST FROM RM WHERE RM_PARENT = 'AMP' AND RM_ACTIVE = 1)
  --AND QM_JOB_STATUS IN (5,6,7,8,9,10)
  ORDER BY 1



  SELECT * FROM RJ WHERE RJ_EXT_KEY IN (
  SELECT QM_UID
  FROM QM
  WHERE QM_CUST_CODE IN ( SELECT RM_CUST FROM RM WHERE RM_PARENT = 'AMP' AND RM_ACTIVE = 1) )
  ORDER BY RJ_EDIT_DATE Desc

  DELETE FROM RJ WHERE RJ_EXT_KEY  IN (
  SELECT QM_UID
  FROM QM
  WHERE QM_CUST_CODE IN ( SELECT RM_CUST FROM RM WHERE RM_PARENT = 'AMP' AND RM_ACTIVE = 1))
  --QM_NUMBER IN ('    337960')--,'    322207')   )




  )

  SELECT QQ_NETT, QQ_JOB_NUM
  FROM QQ INNER JOIN QM ON QQ_JOB_NUM = QM_JOB_NUM
  WHERE QQ_COLUMN = 4 AND QM_CUST_CODE IN ( 'FORWIN','V-NISMOT')  AND QM_ADD_DATE >= '1-JAN-2014'

  SELECT SD_COST_PRICE, SD_SELL_PRICE, SD_NOTE_1, SD_CUST , SD_STOCK, SD_DESC, SD_ADD_DATE , SD_XX_PICKLIST_NUM, ST_DESP_DATE
  FROM SD INNER JOIN ST ON ST_ORDER = SD_ORDER
  WHERE SD_STOCK LIKE 'COURIER%'
  AND ST_DESP_DATE >= '1-Jan-2013' AND ST_DESP_DATE <= '30-Sep-2014'
  AND SD_CUST = 'AU_GMS_LB'






  SELECT * FROM XK  WHERE XK_ADD_DATE > '10-Oct-2014'  AND XK_ADD_DATE < '27-Oct-2014'

  SELECT Count(ST_PICK) FROM ST WHERE ST_ADD_DATE = '27-Oct-2014'




   SELECT * FROM Tmp_Admin_Data_Pick_LineCounts


   SELECT * FROM Tmp_Admin_Data_Pickslips
   ORDER BY VPICKSLIP Desc


   SELECT MAX(SL_LINE),LTrim(SL_PICK), LTrim(SL_ORDER), LTrim(SL_PSLIP),TP.vDateDesp, TP.vPackages,TP.vWeight,TP.vST_XX_NUM_PAL_SW,TP.vST_XX_NUM_PALLETS,TP.vST_XX_NUM_CARTONS
	FROM Tmp_Admin_Data_Pickslips TP RIGHT JOIN SL ON LTrim(SL_PICK) = TP.vPickslip WHERE SL_EDIT_DATE >= '1-Oct-2014' AND SL_EDIT_DATE <= '31-Oct-2014' AND SL_PSLIP != 'CANCELLED'
	GROUP BY SL_PICK,SL_ORDER,SL_PSLIP,TP.vDateDesp,TP.vPackages,TP.vWeight,TP.vST_XX_NUM_PAL_SW,TP.vST_XX_NUM_PALLETS,TP.vST_XX_NUM_CARTONS



  SELECT COUNT(SL_LINE),LTrim(SL_PICK)
	FROM SL  WHERE SL_EDIT_DATE >= '13-Nov-2014'  AND SL_PSLIP != 'CANCELLED'
  --AND SL_PICK = '   2895093'
	GROUP BY SL_PICK
  ORDER BY COUNT(SL_LINE) ASC

  SELECT * FROM SL WHERE SL_PICK = '2895093'


  SELECT * FROM Tmp_Log_Cnts






Select IM_STOCK,IM_DESC,NE_AVAIL_ACTUAL, NI_LOCN, NE_AVAIL_ACTUAL, NE.NE_STATUS, NE.NE_QUANTITY, NE.NE_AVAIL_TENTATIVE, NE.NE_AVAIL_EXPECTED

from NE INNER join IM on IM_STOCK = NE_STOCK

Inner Join NI on NI_ENTRY = NE_ENTRY

Where IM_CUST = 'MMC'

/* NE_STRENGTH = ACTUAL */
And NE_STRENGTH ='3'
And NI_STRENGTH ='3'

/* NE_STATUS = LIVE_POSITIVE */
and NE_STATUS ='1'
And NI_STATUS ='1'

and NE_AVAIL_ACTUAL >0

--And NE_TRAN_TYPE = '1'
--And NI_TRAN_TYPE = '1'

And NI_LOCN is NOT null

and IM_STOCK ='MA-MACOVER003'

Order by NE_STOCK