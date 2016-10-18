USE PWIN171
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

 USING PWIN171
 SELECT RM_CUST
                          ,(
                            CASE
                              WHEN LEVEL = 1 THEN RM_CUST
                              WHEN LEVEL = 2 THEN RM_PARENT
                              WHEN LEVEL = 3 THEN PRIOR RM_PARENT
                              ELSE NULL
                            END
                          ) AS CC
                          ,LEVEL
                    FROM PWIN771.RM
                    WHERE RM_TYPE = 0
                    AND RM_ACTIVE = 1
                    --AND Length(RM_GROUP_CUST) <=  1
                    CONNECT BY PRIOR RM_CUST = RM_PARENT
                    START WITH Length(RM_PARENT) <= 1;

Select * From DEV_GROUP_CUST
Where sCUST like 'G-%'

AND AREA = 'FROST';

USE PWIN171
Select * From RM
Where RM_CUST like 'G-%'
AND RM_ANAL = 'VICP'
AND RM_AREA = 'FROST';

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
    
    
 /* EOM Storage Fees */
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
  
    FROM NI n1 INNER JOIN IM ON IM_STOCK = n1.NI_STOCK AND IM_CUST = sCustomerCode
    INNER JOIN IL l1 ON l1.IL_LOCN = n1.NI_LOCN
    INNER JOIN Dev_Locn_Cnt_By_Cust tmp ON tmp.SLOCN = l1.IL_LOCN
    LEFT JOIN Dev_Group_Cust r ON r.sCust = sCustomerCode
    WHERE  IM_ACTIVE = 1
    AND n1.NI_AVAIL_ACTUAL >= '1'
    AND n1.NI_STATUS <> 0
    AND tmp.SCUST = sCustomerCode
    GROUP BY l1.IL_LOCN,IM_CUST,IM_BRAND,IM_OWNED_By,IM_PROFILE,l1.IL_NOTE_2,n1.NI_LOCN,n1.NI_STOCK,
    tmp.NCOUNTOFSTOCKS,IM_REPORTING_PRICE,r.sGroupCust,IM_LEVEL_UNIT,IM_XX_COST_CENTRE01,IM_STOCK,IM_STD_COST,IM_LAST_COST;
    
    
create or replace PACKAGE EOM_REPORT_PKG
IS

       TYPE custtype IS RECORD
      (
      cust    VARCHAR2(20)
      ,coynum VARCHAR2(20)
      ,rep    VARCHAR2(20)
      ,bank   VARCHAR2(20)
      );
                                                
    /* /*  TYPE lov_oty AS OBJECT
      (
      brand_tx VARCHAR2(10)
      ,desc_tx VARCHAR2(25)
      );
    */
    TYPE myBrandType IS RECORD 
      (
      brand_tx VARCHAR2(10)
      ,desc_tx VARCHAR2(25)
      );

    --/*decalre variables These are being declared via the stored procedure - just need to redeclare cust so as we can get the rates*/
    NOTcust               CONSTANT VARCHAR2(20) := 'TABCORP';
    ordernum              CONSTANT VARCHAR2(20) := '1363806';
    stock                 CONSTANT VARCHAR2(20) := 'COURIER';
    source                CONSTANT VARCHAR2(20) := 'BSPRINTNSW';
    sAnalysis                      VARCHAR2(20) := '21VICP';
    anal                  CONSTANT VARCHAR2(20) := '21VICP';
    start_date                     VARCHAR2(20) := To_Date('01-Apr-2014');
    end_date                       VARCHAR2(20) := To_Date('28-Apr-2014');
    AdjustedDespDate      CONSTANT VARCHAR2(20) := To_Date('28-Feb-2014');
    AnotherCust           CONSTANT VARCHAR2(20) := 'BEYONDBLUE';
    warehouse             CONSTANT VARCHAR2(20) := 'SYDNEY';
    AnotherWwarehouse     CONSTANT VARCHAR2(20) := 'MELBOURNE';
    month_date            CONSTANT VARCHAR2(20) := substr(end_date,4,3);
    year_date             CONSTANT VARCHAR2(20) := substr(end_date,8,2); 
    closed_status         CONSTANT VARCHAR2(1)  := 'C';
    open_status           CONSTANT VARCHAR2(1)  := 'O';
    active_status         CONSTANT VARCHAR2(1)  := 'A';
    inactive_status       CONSTANT VARCHAR2(1)  := 'I';
    
    no_cancelled_picks    CONSTANT VARCHAR2(12) := 'CANCELLED';
    CutOffOrderAddTime    CONSTANT NUMBER       := ('120000');
    CutOffDespTimeSameDay CONSTANT NUMBER       := ('235959');
    CutOffDespTimeNextDay CONSTANT NUMBER       := ('120000');
    status                CONSTANT NUMBER       := 3;
    order_limit           CONSTANT NUMBER       := 1;
    min_difference        CONSTANT NUMBER       := 1;
    max_difference        CONSTANT NUMBER       := 100;
   
    starting_date         CONSTANT DATE         := SYSDATE;
    ending_date           CONSTANT DATE         := ADD_MONTHS (SYSDATE, 120);
    earliest_date         CONSTANT DATE         := SYSDATE;
    latest_date           CONSTANT DATE         := ADD_MONTHS (SYSDATE, 120);

 
    TYPE stock_rec_type IS RECORD 
      (
      gv_Cust_type       RM.RM_CUST%TYPE
      ,gv_OrderNum_type   SH.SH_ORDER%TYPE
      ,gv_DespDate_type   ST.ST_DESP_DATE%TYPE
      ,gv_Stock_type      SD.SD_STOCK%TYPE
      ,gv_UnitPrice_type  NUMBER(10,4)
      ,gv_Brand_type      IM.IM_BRAND%TYPE
      );
                                  
    TYPE stock_ref_cur IS REF CURSOR RETURN stock_rec_type;
  
    FUNCTION total_orders
      ( 
      rm_cust_in IN rm.rm_cust%TYPE
      ,status_in IN sh.sh_status%TYPE:=NULL
      ,sh_add_in IN sh.sh_add_date%TYPE
      )
      RETURN NUMBER;

    FUNCTION total_despatches
      ( 
      d_rm_cust_in IN rm.rm_cust%TYPE
      ,d_status_in IN sh.sh_status%TYPE:=NULL
      ,st_add_in IN st.st_desp_date%TYPE
      )
      RETURN NUMBER;
      
    FUNCTION get_usage_3_months
                    ( 
                    gds_cust_in IN IM.IM_CUST%TYPE
                    ,gds_stock_in IN IM.IM_STOCK%TYPE
                    )
    RETURN NUMBER;
    
     FUNCTION get_usage_6_months
                    ( 
                    gds_cust_in IN IM.IM_CUST%TYPE
                    ,gds_stock_in IN IM.IM_STOCK%TYPE
                    )
    RETURN NUMBER;
    
     FUNCTION get_usage_12_months
                    ( 
                    gds_cust_in IN IM.IM_CUST%TYPE
                    ,gds_stock_in IN IM.IM_STOCK%TYPE
                    )
    RETURN NUMBER;

    PROCEDURE GROUP_CUST_START;
    
    PROCEDURE DEV_GROUP_CUST_START;

    PROCEDURE GROUP_CUST_GET
      (
      gc_customer_in IN rm.rm_cust%TYPE
      );

    PROCEDURE GROUP_CUST_LIST
      (
      tgc_customer_in IN rm.rm_cust%TYPE
      );

    PROCEDURE DESP_STOCK_GET    
      (
      cdsg_date_from_in IN  SH.SH_ADD_DATE%TYPE
      ,cdsg_date_to_in IN  SH.SH_EDIT_DATE%TYPE
      ,cdsg_cust_in IN RM.RM_CUST%TYPE
      );
      
     PROCEDURE GET_IAGRACV_PDS    (
																  iagracv_date_from_in 	IN  SD.SD_ADD_DATE%TYPE,
																  iagracv_date_to_in 		IN  SD.SD_ADD_DATE%TYPE,
                                  iagracv_cur IN OUT sys_refcursor
																  ) ; 
                                  
    PROCEDURE GET_IAGRACV_PDS_DEBUG    (
																  iagracv_date_from_in 	IN  SD.SD_ADD_DATE%TYPE,
																  iagracv_date_to_in 		IN  SD.SD_EDIT_DATE%TYPE
                                  --iagracv_cur IN OUT sys_refcursor
																  );
                                  
    PROCEDURE GET_IAGRACV_PDS2    (
																  iagracv_date_from_in 	IN  SD.SD_ADD_DATE%TYPE,
																  iagracv_date_to_in 		IN  SD.SD_EDIT_DATE%TYPE,
                                  iagracv_cur IN OUT sys_refcursor
																  );
                                  
     PROCEDURE GET_IAGRACV_PDS3    (
																  iagracv_date_from_in 	IN  SD.SD_ADD_DATE%TYPE,
																  iagracv_date_to_in 		IN  SD.SD_ADD_DATE%TYPE,
                                  iagracv_cur IN OUT sys_refcursor
																  );
     
     FUNCTION F_BREAK_UNIT_PRICE
      ( 
      rm_cust_in IN II.II_CUST%TYPE
      ,stock_in   IN II.II_STOCK%TYPE
      )
      RETURN NUMBER;
      
     
   
    PROCEDURE get_desp_stocks_cur_p 
      (
			gds_cust_in IN IM.IM_CUST%TYPE
			,gds_cust_not_in IN  IM.IM_CUST%TYPE
			,gds_stock_not_in IN IM.IM_STOCK%TYPE
			,gds_stock_not_in2 IN IM.IM_STOCK%TYPE
			,gds_start_date_in IN SH.SH_EDIT_DATE%TYPE
			,gds_end_date_in IN SH.SH_ADD_DATE%TYPE
			--,gds_sStockIn IN IM.IM_STOCK%TYPE
			,desp_stock_list_cur_var IN OUT stock_ref_cur
      );
  
    PROCEDURE get_desp_stocks_curp 
      (
			gds_cust_in IN IM.IM_CUST%TYPE,
			gds_cust_not_in IN  IM.IM_CUST%TYPE,
			--gds_nx_ext_type_in IN NI.NI_NV_EXT_TYPE%TYPE,
			gds_stock_not_in IN IM.IM_STOCK%TYPE,
			gds_stock_not_in2 IN IM.IM_STOCK%TYPE,
			gds_start_date_in IN SH.SH_EDIT_DATE%TYPE,
			gds_end_date_in IN SH.SH_ADD_DATE%TYPE,
      gds_sStockIn IN IM.IM_STOCK%TYPE,
			gds_src_get_desp_stocks OUT sys_refcursor
      );
    
    
    
    PROCEDURE get_desp_stocks (
			gds_start_date_in IN SH.SH_EDIT_DATE%TYPE,
			gds_end_date_in IN SH.SH_ADD_DATE%TYPE,
      gds_sStockIn IN IM.IM_STOCK%TYPE,
			gds_get_desp_stocks OUT sys_refcursor
    );
    
      
    PROCEDURE get_finance_transactions_curp (
			gds_cust_in IN IM.IM_CUST%TYPE,
			gds_start_date_in IN SH.SH_EDIT_DATE%TYPE,
			gds_end_date_in IN SH.SH_ADD_DATE%TYPE,
			gds_src_get_finance_trans OUT sys_refcursor
    );
    
    PROCEDURE get_prj_transactions_curp (
			gds_cust_in IN IM.IM_CUST%TYPE,
			gds_start_date_in IN SH.SH_EDIT_DATE%TYPE,
			gds_end_date_in IN SH.SH_ADD_DATE%TYPE,
			gds_src_get_finance_trans OUT sys_refcursor
    );
    
    
     FUNCTION total_soh_by_stock
    ( gsc_stock_in IN NI.NI_STOCK%TYPE)
  RETURN NUMBER;

    
    PROCEDURE get_stockonhand_curp (
			gsc_cust_in IN IM.IM_CUST%TYPE,
			--gsc_start_date_in IN SH.SH_EDIT_DATE%TYPE,
			--gsc_end_date_in IN SH.SH_ADD_DATE%TYPE,
      gsc_warehouse_in IN VARCHAR2,
			gsc_src_get_soh_trans OUT sys_refcursor
    );
    
    PROCEDURE get_desp_freight_curp (
			gdf_cust_in IN IM.IM_CUST%TYPE,
			gdf_stock_in IN IM.IM_STOCK%TYPE,
			gdf_warehouse_in IN VARCHAR2,
			gdf_start_date_in IN SH.SH_EDIT_DATE%TYPE,
			gdf_end_date_in IN SH.SH_ADD_DATE%TYPE,
			gdf_desp_freight_cur OUT sys_refcursor
      );
  
    PROCEDURE myproc_test_via_PHP
      (
      p1 IN NUMBER
      ,p2 IN OUT NUMBER
      );
  
    PROCEDURE list_stocks
      (
      cat IN IM.IM_CAT%TYPE
      );
  
    PROCEDURE quick_function_test
      ( 
      p_rc OUT SYS_REFCURSOR 
      );
  
    PROCEDURE test_get_brand;
    
    FUNCTION f_getDisplay
      (
      i_column_tx VARCHAR2
      ,i_table_select_tx VARCHAR2
      ,i_field_tx VARCHAR2
      ,i_value_tx VARCHAR2
      )
      RETURN VARCHAR2;
    
    FUNCTION f_getDisplay_from_type_bind
      (
      i_first_col IN VARCHAR2
      ,i_value_tx IN VARCHAR2
      )
      RETURN myBrandType;
              
    FUNCTION f_getDisplay_oty
      (
      i_column_tx VARCHAR2
      ,i_column2_tx VARCHAR2
      ,i_table_select_tx VARCHAR2
      ,i_field_tx VARCHAR2
      ,i_value_tx NUMBER
      )
      RETURN VARCHAR2;
      
      
  /*  PROCEDURE get_pick_stats_curp (
      gds_SL_PICK_in2 IN SL.SL_PICK%TYPE,
			--gds_SL_EDIT_DATE_start_in IN SL.SL_EDIT_DATE%TYPE,
			gds_src_get_pick_cnt OUT sys_refcursor
      );*/
        
    FUNCTION get_cust_stocks
      (
      r_coy_num in VARCHAR
      ) 
      RETURN sys_refcursor;
    
    /* FUNCTION populate_custs
      (
      coynum in VARCHAR := null
      )
      RETURN  custtype;
    */
        
    FUNCTION refcursor_function 
      RETURN SYS_REFCURSOR;
  
    PROCEDURE EOM_CREATE_TEMP_DATA 
        (
        p_pick_status IN NUMBER
        , p_status IN VARCHAR2
        , sAnalysis IN VARCHAR2
        , start_date IN VARCHAR2
        ,end_date IN VARCHAR2  
        );
  
    PROCEDURE EOM_CREATE_TEMP_DATA_BIND 
        (sAnalysis IN RM.RM_ANAL%TYPE
        , start_date IN ST.ST_DESP_DATE%TYPE
        , end_date IN ST.ST_DESP_DATE%TYPE 
        );
        
    PROCEDURE DEV_CREATE_TEMP_DATA_BIND 
    (
     sAnalysis IN RM.RM_ANAL%TYPE
     ,start_date IN ST.ST_DESP_DATE%TYPE
     ,end_date IN ST.ST_DESP_DATE%TYPE 
     ) ;
        
    PROCEDURE EOM_CREATE_TEMP_DATA_LOCATIONS 
    (
     sAnalysis IN RM.RM_ANAL%TYPE
     ,start_date IN ST.ST_DESP_DATE%TYPE
     ,end_date IN ST.ST_DESP_DATE%TYPE 
     );
        
   FUNCTION f_GetWarehouse_from_SD
      (
		  v_sd_locn_in VARCHAR2
		  )
    RETURN VARCHAR2;
    
    FUNCTION f_GetFreightZone_RTA
      (
		  v_spare_int_9_in NUMBER
		  )
    RETURN VARCHAR2;

   PROCEDURE EOM_CREATE_TEMP_LOG_DATA
        (
        start_date IN SH.SH_ADD_DATE%TYPE
        ,end_date  IN SH.SH_ADD_DATE%TYPE
        ,cust       IN VARCHAR2
        ,warehouse IN VARCHAR2
        ,gds_src_get_desp_stocks OUT sys_refcursor
        );
        
        
END EOM_REPORT_PKG;



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
  
    FROM NI n1 INNER JOIN IM ON IM_STOCK = n1.NI_STOCK --AND IM_CUST = tmp.SCUST
    INNER JOIN IL l1 ON l1.IL_LOCN = n1.NI_LOCN
    INNER JOIN Dev_Locn_Cnt_By_Cust tmp ON tmp.SLOCN = l1.IL_LOCN
    LEFT JOIN Dev_Group_Cust r ON r.sCust = tmp.SCUST
    WHERE  IM_ACTIVE = 1
    AND n1.NI_AVAIL_ACTUAL >= '1'
    AND n1.NI_STATUS <> 0
    --AND tmp.SCUST = sCustomerCode
    AND   tmp.SCUST IN (SELECT RM_CUST FROM RM WHERE RM_ANAL = 'VICP' AND RM_TYPE = 0 AND RM_ACTIVE = 1 )
    GROUP BY l1.IL_LOCN,IM_CUST,IM_BRAND,IM_OWNED_By,IM_PROFILE,l1.IL_NOTE_2,n1.NI_LOCN,n1.NI_STOCK,
    tmp.NCOUNTOFSTOCKS,IM_REPORTING_PRICE,r.sGroupCust,IM_LEVEL_UNIT,IM_XX_COST_CENTRE01,IM_STOCK,IM_STD_COST,IM_LAST_COST;
    
    TRUNCATE TABLE DEV_STOR_ALL_FEES;
    
    
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