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
          f_get_fee('RM_XX_FEE11','LINK') / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --shelf for fast moving
          f_get_fee('RM_XX_FEE12','LINK') / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3','LINK') !=0 THEN --pallet for slow moving if slow rate exists
         f_get_fee('RM_SPARE_CHAR_3','LINK') / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30','LINK') !=0 THEN --shelf for slow moving if slow rate exists
          f_get_fee('RM_XX_FEE30','LINK') / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3','LINK') =0 THEN --pallet for slow moving if slow rate DOESN't exist, revert to normal charge
         f_get_fee('RM_XX_FEE11','LINK') / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30','LINK') =0 THEN --shelf for slow moving if slow rate DOESN't exist
          f_get_fee('RM_XX_FEE12','LINK') / tmp.NCOUNTOFSTOCKS
        ELSE 999
        END AS "UnitPrice",
      CASE
        WHEN UPPER(l1.IL_NOTE_2) = 'YES'  AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --pallet for fast moving
          f_get_fee('RM_XX_FEE11','LINK') / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --shelf for fast moving
          f_get_fee('RM_XX_FEE12','LINK') / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3','LINK') !=0 THEN --pallet for slow moving if slow rate exists
         f_get_fee('RM_SPARE_CHAR_3','LINK') / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30','LINK') !=0 THEN --shelf for slow moving if slow rate exists
          f_get_fee('RM_XX_FEE30','LINK') / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3','LINK') =0 THEN --pallet for slow moving if slow rate DOESN't exist, revert to normal charge
         f_get_fee('RM_XX_FEE11','LINK') / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30','LINK') =0 THEN --shelf for slow moving if slow rate DOESN't exist
          f_get_fee('RM_XX_FEE12','LINK') / tmp.NCOUNTOFSTOCKS
        ELSE 999
        END AS "OWUnitPrice",
      CASE
        WHEN UPPER(l1.IL_NOTE_2) = 'YES'  AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --pallet for fast moving
          f_get_fee('RM_XX_FEE11','LINK') / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --shelf for fast moving
          f_get_fee('RM_XX_FEE12','LINK') / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3','LINK') !=0 THEN --pallet for slow moving if slow rate exists
         f_get_fee('RM_SPARE_CHAR_3','LINK') / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30','LINK') !=0 THEN --shelf for slow moving if slow rate exists
          f_get_fee('RM_XX_FEE30','LINK') / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3','LINK') =0 THEN --pallet for slow moving if slow rate DOESN't exist, revert to normal charge
         f_get_fee('RM_XX_FEE11','LINK') / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30','LINK') =0 THEN --shelf for slow moving if slow rate DOESN't exist
          f_get_fee('RM_XX_FEE12','LINK') / tmp.NCOUNTOFSTOCKS
        ELSE 999
        END AS "DExcl",
      CASE 
        WHEN UPPER(l1.IL_NOTE_2) = 'YES'  AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --pallet for fast moving
          (f_get_fee('RM_XX_FEE11','LINK') / tmp.NCOUNTOFSTOCKS) * 1.1
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --shelf for fast moving
          (f_get_fee('RM_XX_FEE12','LINK') / tmp.NCOUNTOFSTOCKS) * 1.1
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3','LINK') !=0 THEN --pallet for slow moving if slow rate exists
          (f_get_fee('RM_SPARE_CHAR_3','LINK') / tmp.NCOUNTOFSTOCKS) * 1.1
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30','LINK') !=0 THEN --shelf for slow moving if slow rate exists
          (f_get_fee('RM_XX_FEE30','LINK') / tmp.NCOUNTOFSTOCKS) * 1.1
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3','LINK') =0 THEN --pallet for slow moving if slow rate DOESN't exist, revert to normal charge
          (f_get_fee('RM_XX_FEE11','LINK') / tmp.NCOUNTOFSTOCKS) * 1.1
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30','LINK') =0 THEN --shelf for slow moving if slow rate DOESN't exist
          (f_get_fee('RM_XX_FEE12','LINK') / tmp.NCOUNTOFSTOCKS) * 1.1
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
  
    FROM  NA n1 INNER JOIN IL l1 ON l1.IL_UID = n1.NA_EXT_KEY
      INNER JOIN NE e ON e.NE_ACCOUNT = n1.NA_ACCOUNT
      INNER JOIN IM  ON  IM_STOCK = n1.NA_STOCK

  
  
    --FROM NI n1 INNER JOIN  IM ON IM_STOCK = n1.NI_STOCK --AND IM_CUST = sCustomerCode
    --LEFT OUTER JOIN IL l1 ON l1.IL_LOCN = n1.NI_LOCN
    INNER JOIN  Dev_Locn_Cnt_By_Cust tmp ON tmp.SLOCN = l1.IL_LOCN 
    INNER JOIN  Dev_Group_Cust r ON r.sCust = IM_CUST
    WHERE n1.NA_EXT_TYPE = 1210067
    AND e.NE_AVAIL_ACTUAL >= '1'
    AND l1.IL_IN_LOCN NOT IN ('OBSOLETEMEL','OBSOLETESYD','PASTHISTORY', 'CANBERRA')
    AND e.NE_STATUS =  1
    AND e.NE_STRENGTH = 3

    --AND tmp.SCUST = sCustomerCode
   -- AND l1.IL_LOCN = 'S5B13-10'
    AND r.ANAL = '22NSWP'
    GROUP BY l1.IL_LOCN,IM_CUST,IM_BRAND,IM_OWNED_By,IM_PROFILE,l1.IL_NOTE_2,l1.IL_LOCN,n1.NA_STOCK,
    tmp.NCOUNTOFSTOCKS,IM_REPORTING_PRICE,r.sGroupCust,IM_LEVEL_UNIT,IM_XX_COST_CENTRE01,IM_STOCK,IM_STD_COST,IM_LAST_COST;