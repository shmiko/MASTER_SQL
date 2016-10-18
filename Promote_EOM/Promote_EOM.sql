SELECT RM_CUST
      ,(
        CASE
          WHEN LEVEL = 1 THEN RM_CUST
          WHEN LEVEL = 2 THEN RM_PARENT
          WHEN LEVEL = 3 THEN PRIOR RM_PARENT
          ELSE NULL
        END
      ) AS CC
      ,LEVEL,RM_AREA,RM_TERR,(Select MAX(DV_VALUE) FROM TMP_DROP_LIST Where DV_INDEX = TO_NUMBER(RM_DBL_2)),RM_ANAL,RM_SOURCE,RM_GROUP_CUST
FROM RM
WHERE RM_TYPE = 0
AND RM_ACTIVE = 1
--AND Length(RM_GROUP_CUST) <=  1
CONNECT BY PRIOR RM_CUST = RM_PARENT
START WITH Length(RM_PARENT) <= 1;

Select * From DEV_GROUP_CUST
Where sCUST like 'G-%'
AND AREA = 'FROST';

Declare
  start_date VARCHAR2(20) := '01-Sep-2016';
  end_date VARCHAR2(20) := '30-Sep-2016';
Begin
  SELECT LTrim(ST_PICK),LTrim(ST_PSLIP), substr(To_Char(ST_DESP_DATE),0,10), ST_WEIGHT, ST_PACKAGES,ST_XX_NUM_PAL_SW,ST_XX_NUM_PALLETS,ST_XX_NUM_CARTONS,NULL,NULL,NULL,NULL
  FROM ST LEFT JOIN SH ON SH_ORDER = ST_ORDER
  WHERE ST_DESP_DATE >= '01-Sep-2016' AND ST_DESP_DATE <= '30-Sep-2016'
  AND ST_PSLIP != 'CANCELLED'
  AND SH_STATUS <> 3;
End;


select IM_CUST AS "Customer",
      r.sGroupCust AS "Parent",
      IM_XX_COST_CENTRE01     AS "CostCentre",
      NULL               AS "Order",
      NULL               AS "OrderwareNum",
      NULL               AS "CustomerRef",
      NULL         AS "Pickslip",
      NULL                      AS "DespatchNote",
      NULL               AS "DespatchNote",
      NULL             AS "OrderDate",
      CASE /*Fee Type*/
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW'
          THEN 'FEEPALLETS'
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW'
          THEN 'SLOWFEEPALLETS'
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW'
          THEN 'FEESHELFS'
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW'
          THEN 'SLOWFEESHELFS'
        ELSE 'UNKNOWN'
        END AS "FeeType",
      IM_STOCK AS "Item",
      CASE /*explanation of charge*/
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' 
          THEN 'Pallet Space Utilisation Fee (per month) is split across ' || tmp.NCOUNTOFSTOCKS || ' stock(s)'
        ELSE 'Shelf SPace Utilisation Fee (per month) is split across ' ||	tmp.NCOUNTOFSTOCKS  || ' stock(s)'
        END AS "Description",
      CASE   
        WHEN l1.IL_NOTE_2 IS NOT NULL THEN  1
        ELSE 0
        END                     AS "Qty",
      IM_LEVEL_UNIT AS "UOI", 
      CASE
        WHEN UPPER(l1.IL_NOTE_2) = 'YES'  AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --pallet for fast moving
          f_get_fee('RM_XX_FEE11',r.sGroupCust) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --shelf for fast moving
          f_get_fee('RM_XX_FEE12',r.sGroupCust) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',r.sGroupCust) !=0 THEN --pallet for slow moving if slow rate exists
         f_get_fee('RM_SPARE_CHAR_3',r.sGroupCust) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',r.sGroupCust) !=0 THEN --shelf for slow moving if slow rate exists
          f_get_fee('RM_XX_FEE30',r.sGroupCust) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',r.sGroupCust) =0 THEN --pallet for slow moving if slow rate DOESN't exist, revert to normal charge
         f_get_fee('RM_XX_FEE11',r.sGroupCust) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',r.sGroupCust) =0 THEN --shelf for slow moving if slow rate DOESN't exist
          f_get_fee('RM_XX_FEE12',r.sGroupCust) / tmp.NCOUNTOFSTOCKS
        ELSE 999
        END AS "UnitPrice",
      CASE
        WHEN UPPER(l1.IL_NOTE_2) = 'YES'  AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --pallet for fast moving
          f_get_fee('RM_XX_FEE11',r.sGroupCust) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --shelf for fast moving
          f_get_fee('RM_XX_FEE12',r.sGroupCust) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',r.sGroupCust) !=0 THEN --pallet for slow moving if slow rate exists
         f_get_fee('RM_SPARE_CHAR_3',r.sGroupCust) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',r.sGroupCust) !=0 THEN --shelf for slow moving if slow rate exists
          f_get_fee('RM_XX_FEE30',r.sGroupCust) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',r.sGroupCust) =0 THEN --pallet for slow moving if slow rate DOESN't exist, revert to normal charge
         f_get_fee('RM_XX_FEE11',r.sGroupCust) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',r.sGroupCust) =0 THEN --shelf for slow moving if slow rate DOESN't exist
          f_get_fee('RM_XX_FEE12',r.sGroupCust) / tmp.NCOUNTOFSTOCKS
        ELSE 999
        END AS "OWUnitPrice",
      CASE
        WHEN UPPER(l1.IL_NOTE_2) = 'YES'  AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --pallet for fast moving
          f_get_fee('RM_XX_FEE11',r.sGroupCust) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --shelf for fast moving
          f_get_fee('RM_XX_FEE12',r.sGroupCust) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',r.sGroupCust) !=0 THEN --pallet for slow moving if slow rate exists
         f_get_fee('RM_SPARE_CHAR_3',r.sGroupCust) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',r.sGroupCust) !=0 THEN --shelf for slow moving if slow rate exists
          f_get_fee('RM_XX_FEE30',r.sGroupCust) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',r.sGroupCust) =0 THEN --pallet for slow moving if slow rate DOESN't exist, revert to normal charge
         f_get_fee('RM_XX_FEE11',r.sGroupCust) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',r.sGroupCust) =0 THEN --shelf for slow moving if slow rate DOESN't exist
          f_get_fee('RM_XX_FEE12',r.sGroupCust) / tmp.NCOUNTOFSTOCKS
        ELSE 999
        END AS "DExcl",
      CASE 
        WHEN UPPER(l1.IL_NOTE_2) = 'YES'  AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --pallet for fast moving
          (f_get_fee('RM_XX_FEE11',r.sGroupCust) / tmp.NCOUNTOFSTOCKS) * 1.1
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --shelf for fast moving
          (f_get_fee('RM_XX_FEE12',r.sGroupCust) / tmp.NCOUNTOFSTOCKS) * 1.1
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',r.sGroupCust) !=0 THEN --pallet for slow moving if slow rate exists
          (f_get_fee('RM_SPARE_CHAR_3',r.sGroupCust) / tmp.NCOUNTOFSTOCKS) * 1.1
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',r.sGroupCust) !=0 THEN --shelf for slow moving if slow rate exists
          (f_get_fee('RM_XX_FEE30',r.sGroupCust) / tmp.NCOUNTOFSTOCKS) * 1.1
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',r.sGroupCust) =0 THEN --pallet for slow moving if slow rate DOESN't exist, revert to normal charge
          (f_get_fee('RM_XX_FEE11',r.sGroupCust) / tmp.NCOUNTOFSTOCKS) * 1.1
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',r.sGroupCust) =0 THEN --shelf for slow moving if slow rate DOESN't exist
          (f_get_fee('RM_XX_FEE12',r.sGroupCust) / tmp.NCOUNTOFSTOCKS) * 1.1
        ELSE 999
        END AS "DIncl",
      TO_NUMBER(IM_REPORTING_PRICE),
      IM_STD_COST AS "PreMarkUpPrice",
			  IM_LAST_COST           AS "COSTPRICE",
      NULL             AS "Address",
      NULL              AS "Address2",
      NULL                AS "Suburb",
      NULL               AS "State",
      NULL           AS "Postcode",
      NULL              AS "DeliverTo",
      NULL              AS "AttentionTo" ,
      0              AS "Weight",
      0            AS "Packages",
      0         AS "OrderSource",
      l1.IL_NOTE_2 AS "Pallet/Space", 
      l1.IL_LOCN AS "Locn",
      tmp.NCOUNTOFSTOCKS AS CountCustStocks,
      NULL AS Email,
      IM_BRAND AS Brand,
      IM_OWNED_By AS    OwnedBy,
      IM_PROFILE AS    sProfile,
      NULL AS    WaiveFee,
      NULL As   Cost,
      NULL AS PaymentType,NULL,NULL,NULL,NULL
  
    FROM NI n1 INNER JOIN IM ON IM_STOCK = n1.NI_STOCK AND IM_CUST = 'G-VICPROMO'
    INNER JOIN IL l1 ON l1.IL_LOCN = n1.NI_LOCN
    INNER JOIN Dev_Locn_Cnt_By_Cust tmp ON tmp.SLOCN = l1.IL_LOCN
    LEFT JOIN Dev_Group_Cust r ON r.sCust = 'G-VICPROMO'
    WHERE  IM_ACTIVE = 1
    AND n1.NI_AVAIL_ACTUAL >= '1'
    AND n1.NI_STATUS <> 0
    AND tmp.SCUST = 'G-VICPROMO'
    GROUP BY l1.IL_LOCN,IM_CUST,IM_BRAND,IM_OWNED_By,IM_PROFILE,l1.IL_NOTE_2,n1.NI_LOCN,n1.NI_STOCK,
    tmp.NCOUNTOFSTOCKS,IM_REPORTING_PRICE,r.sGroupCust,IM_LEVEL_UNIT,IM_XX_COST_CENTRE01,IM_STOCK,IM_STD_COST,IM_LAST_COST;