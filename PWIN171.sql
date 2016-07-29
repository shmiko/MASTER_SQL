SELECT    s.SH_CUST               AS "Customer",
			  r.sGroupCust              AS "Parent",
			  CASE    WHEN i.IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
			  WHEN i.IM_CUST = 'TABCORP' THEN i.IM_XX_COST_CENTRE01
			  ELSE s.SH_SPARE_STR_4
			  END                      AS "CostCentre",
			  s.SH_ORDER              AS "Order",
			  s.SH_SPARE_STR_5         AS "OrderwareNum",
			  s.SH_CUST_REF            AS "CustomerRef",
			  NULL               AS "Pickslip",
			  NULL                    AS "PickNum",
			  NULL              AS "DespatchNote",
			  substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  'OrderEntryFee'
			  ELSE ''
			  END                     AS "FeeType",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  'FEEORDERENTRYS'
			  ELSE ''
			  END                     AS "Item",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  'Phone Order Entry Fee'
			  ELSE ''
			  END                     AS "Description",
	  CASE    WHEN d.SD_LINE = 1 THEN  1
			  ELSE NULL
			  END                     AS "Qty",
	  CASE    WHEN d.SD_LINE = 1 THEN  '1'
			  ELSE ''
			  END                     AS "UOI",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = 'TABCORP')
			  ELSE NULL
			  END                     AS "UnitPrice",
	 CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = 'TABCORP')
			  ELSE NULL
			  END                     AS "OWUnitPrice",
	   CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = 'TABCORP')
			  ELSE NULL
			  END                     AS "DExcl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = 'TABCORP')
			  ELSE NULL
			  END                     AS "Excl_Total",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = 'TABCORP') * 1.1
			  ELSE NULL
			  END                     AS "DIncl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = 'TABCORP') * 1.1
			  ELSE NULL
			  END                     AS "Incl_Total",
			  NULL                    AS "ReportingPrice",
			  s.SH_ADDRESS            AS "Address",
			  s.SH_SUBURB             AS "Address2",
			  s.SH_CITY               AS "Suburb",
			  s.SH_STATE              AS "State",
			  s.SH_POST_CODE          AS "Postcode",
			  s.SH_NOTE_1             AS "DeliverTo",
			  s.SH_NOTE_2             AS "AttentionTo" ,
			  0             AS "Weight",
			  0           AS "Packages",
			  s.SH_SPARE_DBL_9        AS "OrderSource",
			  NULL AS "Pallet/Shelf Space", /*Pallet/Space*/
				NULL AS "Locn", /*Locn*/
				--0 AS "AvailSOH",/*Avail SOH*/
				0 AS "CountOfStocks",
        CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			        ELSE ''
			        END AS Email,
              'N/A' AS Brand,
           i.IM_OWNED_By AS    OwnedBy,
           i.IM_PROFILE AS    sProfile,
           s.SH_XX_FEE_WAIVE AS    WaiveFee,
           d.SD_COST_PRICE As   Cost,
           s.SH_SPARE_INT_4 AS PaymentType

	FROM      PWIN175.SH s
			  INNER JOIN PWIN175.SD d ON d.SD_ORDER  = s.SH_ORDER
			  INNER JOIN PWIN175.IM i ON i.IM_STOCK = d.SD_STOCK
			  INNER JOIN PWIN175.ST t ON t.ST_ORDER = s.SH_ORDER AND t.ST_PICK = s.SH_LAST_PICK_NUM
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
			  --LEFT JOIN PWIN175.RM r2 ON r2.RM_ANAL = r.RM_ANAL AND r2.RM_CUST = :cust
	WHERE (r.sGroupCust = 'TABCORP' OR r.sCust = 'TABCORP')
  AND       t.ST_DESP_DATE >= '01-MAY-2015' AND t.ST_DESP_DATE <= '30-MAY-2015'
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	AND       s.SH_SPARE_DBL_9 = 1
	AND       d.SD_LINE = 1
  AND (SELECT To_Number(regexp_substr(RM_XX_FEE03,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = 'TABCORP') > 0.1
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> 0
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> '0'
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) IS NOT NULL
	--AND     nRM_XX_FEE03 > 0
	GROUP BY  s.SH_CUST,
			  s.SH_ADD_DATE,
			  s.SH_SPARE_STR_4,
			  s.SH_ORDER,
			  s.SH_PREV_PSLIP_NUM,
			  t.ST_DESP_DATE,
			  s.SH_SPARE_DBL_9,
			  d.SD_LINE,
			  s.SH_ADDRESS,
			  s.SH_SUBURB,
			  s.SH_CITY,
			  s.SH_STATE,
			  s.SH_POST_CODE,
			  s.SH_NOTE_1,
			  s.SH_NOTE_2,
			  s.SH_SPARE_DBL_9,
			  r.sGroupCust,
			  i.IM_CUST,
			  i.IM_XX_COST_CENTRE01,
			  s.SH_SPARE_STR_5,
			  s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4







	UNION ALL
/*PhoneOrderEntryFee*/

/*EmailOrderEntryFee*/
	SELECT    s.SH_CUST               AS "Customer",
			  r.sGroupCust              AS "Parent",
			  CASE    WHEN i.IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
			  WHEN i.IM_CUST = 'TABCORP' THEN i.IM_XX_COST_CENTRE01
			  ELSE s.SH_SPARE_STR_4
			  END                      AS "CostCentre",
			  s.SH_ORDER              AS "Order",
			  s.SH_SPARE_STR_5         AS "OrderwareNum",
			  s.SH_CUST_REF            AS "CustomerRef",
			  NULL               AS "Pickslip",
			  NULL                    AS "PickNum",
			  NULL              AS "DespatchNote",
			  substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  'OrderEntryFee'
			  ELSE ''
			  END                     AS "FeeType",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  'FEEORDERENTRYS'
			  ELSE ''
			  END                     AS "Item",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  'Email Order Entry Fee'
			  ELSE ''
			  END                     AS "Description",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3  THEN  1
			  ELSE NULL
			  END                     AS "Qty",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  '1'
			  ELSE ''
			  END                     AS "UOI",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = 'TABCORP')
			  ELSE NULL
			  END                     AS "UnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = 'TABCORP')
			  ELSE NULL
			  END                     AS "OWUnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN   (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = 'TABCORP')
			  ELSE NULL
			  END                     AS "DExcl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = 'TABCORP')
			  ELSE NULL
			  END                     AS "Excl_Total",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN   (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = 'TABCORP') * 1.1
			  ELSE NULL
			  END                     AS "DIncl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN   (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = 'TABCORP') * 1.1
			  ELSE NULL
			  END                     AS "Incl_Total",
			  NULL                    AS "ReportingPrice",
			  s.SH_ADDRESS            AS "Address",
			  s.SH_SUBURB             AS "Address2",
			  s.SH_CITY               AS "Suburb",
			  s.SH_STATE              AS "State",
			  s.SH_POST_CODE          AS "Postcode",
			  s.SH_NOTE_1             AS "DeliverTo",
			  s.SH_NOTE_2             AS "AttentionTo" ,
			  0             AS "Weight",
			  0           AS "Packages",
			  s.SH_SPARE_DBL_9        AS "OrderSource",
			  NULL AS "Pallet/Shelf Space", /*Pallet/Space*/
				NULL AS "Locn", /*Locn*/
				--0 AS "AvailSOH",/*Avail SOH*/
				0 AS "CountOfStocks",
        CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			        ELSE ''
			        END AS Email,
              'N/A' AS Brand,
           i.IM_OWNED_By AS    OwnedBy,
           i.IM_PROFILE AS    sProfile,
           s.SH_XX_FEE_WAIVE AS    WaiveFee,
           d.SD_COST_PRICE As   Cost,
           s.SH_SPARE_INT_4 AS PaymentType
	FROM      PWIN175.SH s
			  INNER JOIN PWIN175.SD d ON d.SD_ORDER  = s.SH_ORDER
			  INNER JOIN PWIN175.IM i ON i.IM_STOCK = d.SD_STOCK
			  INNER JOIN PWIN175.ST t ON t.ST_ORDER = s.SH_ORDER AND t.ST_PICK = s.SH_LAST_PICK_NUM
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
			  --LEFT JOIN PWIN175.RM r2 ON r2.RM_ANAL = r.RM_ANAL AND r2.RM_CUST = :cust
	WHERE (r.sGroupCust = 'TABCORP' OR r.sCust = 'TABCORP')
  AND       t.ST_DESP_DATE >= '01-MAY-2015' AND t.ST_DESP_DATE <= '30-MAY-2015'
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	AND       s.SH_SPARE_DBL_9 = 3
	AND       d.SD_LINE = 1
	--AND       Select rm3.RM_XX_FEE02 from RM rm3 where To_Number(regexp_substr(rm3.RM_XX_FEE02,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0 AND rm3.RM_CUST = :cust
  AND (SELECT To_Number(regexp_substr(RM_XX_FEE02,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = 'TABCORP') > 0.1
	--AND      nRM_XX_FEE02 > 0 --AND rm3.RM_CUST = :cust
	--AND       (Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust) <> 0
	--AND       (Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust) <> '0'
	--AND       (Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust) IS NOT NULL
	GROUP BY  s.SH_CUST,
			  s.SH_ADD_DATE,
			  s.SH_SPARE_STR_4,
			  s.SH_ORDER,
			  s.SH_PREV_PSLIP_NUM,
			  t.ST_DESP_DATE,
			  s.SH_SPARE_DBL_9,
			  d.SD_LINE,
			  s.SH_ADDRESS,
			  s.SH_SUBURB,
			  s.SH_CITY,
			  s.SH_STATE,
			  s.SH_POST_CODE,
			  s.SH_NOTE_1,
			  s.SH_NOTE_2,
			  s.SH_SPARE_DBL_9,
			  r.sGroupCust,
			  i.IM_CUST,
			  i.IM_XX_COST_CENTRE01,
			  s.SH_SPARE_STR_5,
			  s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4







	UNION ALL
/*EmailOrderEntryFee*/

/*FaxOrderEntryFee*/
	SELECT    s.SH_CUST               AS "Customer",
			  r.sGroupCust              AS "Parent",
			  CASE    WHEN i.IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
			  WHEN i.IM_CUST = 'TABCORP' THEN i.IM_XX_COST_CENTRE01
			  ELSE s.SH_SPARE_STR_4
			  END                      AS "CostCentre",
			  s.SH_ORDER              AS "Order",
			  s.SH_SPARE_STR_5         AS "OrderwareNum",
			  s.SH_CUST_REF            AS "CustomerRef",
			  NULL               AS "Pickslip",
			  NULL                    AS "PickNum",
			  NULL              AS "DespatchNote",
			  substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  'OrderEntryFee'
			  ELSE ''
			  END                     AS "FeeType",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  'FEEORDERENTRYS'
			  ELSE ''
			  END                     AS "Item",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  'Fax Order Entry Fee'
			  ELSE ''
			  END                     AS "Description",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  1
			  ELSE NULL
			  END                     AS "Qty",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  '1'
			  ELSE ''
			  END                     AS "UOI",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = 'TABCORP')
			  ELSE NULL
			  END                     AS "UnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = 'TABCORP')
			  ELSE NULL
			  END                     AS "OWUnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = 'TABCORP')
			  ELSE NULL
			  END                     AS "DExcl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = 'TABCORP')
			  ELSE NULL
			  END                     AS "Excl_Total",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN   (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = 'TABCORP') * 1.1
			  ELSE NULL
			  END                     AS "DIncl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = 'TABCORP') * 1.1
			  ELSE NULL
			  END                     AS "Incl_Total",
			  NULL                    AS "ReportingPrice",
			  s.SH_ADDRESS            AS "Address",
			  s.SH_SUBURB             AS "Address2",
			  s.SH_CITY               AS "Suburb",
			  s.SH_STATE              AS "State",
			  s.SH_POST_CODE          AS "Postcode",
			  s.SH_NOTE_1             AS "DeliverTo",
			  s.SH_NOTE_2             AS "AttentionTo" ,
			  0             AS "Weight",
			  0           AS "Packages",
			  s.SH_SPARE_DBL_9        AS "OrderSource",
			  NULL AS "Pallet/Shelf Space", /*Pallet/Space*/
				NULL AS "Locn", /*Locn*/
				--0 AS "AvailSOH",/*Avail SOH*/
				0 AS "CountOfStocks",
        CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			        ELSE ''
			        END AS Email,
              i.IM_BRAND AS Brand,
           i.IM_OWNED_By AS    OwnedBy,
           i.IM_PROFILE AS    sProfile,
           s.SH_XX_FEE_WAIVE AS    WaiveFee,
           d.SD_COST_PRICE As   Cost,
           s.SH_SPARE_INT_4 AS PaymentType
	FROM      PWIN175.SH s
			  INNER JOIN PWIN175.SD d ON d.SD_ORDER  = s.SH_ORDER
			  INNER JOIN PWIN175.IM i ON i.IM_STOCK = d.SD_STOCK
			  INNER JOIN PWIN175.ST t ON t.ST_ORDER = s.SH_ORDER AND t.ST_PICK = s.SH_LAST_PICK_NUM
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
			  --LEFT JOIN PWIN175.RM r2 ON r2.RM_ANAL = r.RM_ANAL AND r2.RM_CUST = :cust
	WHERE (r.sGroupCust = 'TABCORP' OR r.sCust = 'TABCORP')
  AND       t.ST_DESP_DATE >= '01-MAY-2015' AND t.ST_DESP_DATE <= '30-MAY-2015'
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	AND       s.SH_SPARE_DBL_9 = 2
	AND       d.SD_LINE = 1
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> 0
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> '0'
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) IS NOT NULL
	--AND      nRM_XX_FEE07 > 0
  AND (SELECT To_Number(regexp_substr(RM_XX_FEE07,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = 'TABCORP') > 0.1
	GROUP BY  s.SH_CUST,
			  s.SH_ADD_DATE,
			  s.SH_SPARE_STR_4,
			  s.SH_ORDER,
			  s.SH_PREV_PSLIP_NUM,
			  t.ST_DESP_DATE,
			  s.SH_SPARE_DBL_9,
			  d.SD_LINE,
			  s.SH_ADDRESS,
			  s.SH_SUBURB,
			  s.SH_CITY,
			  s.SH_STATE,
			  s.SH_POST_CODE,
			  s.SH_NOTE_1,
			  s.SH_NOTE_2,
			  s.SH_SPARE_DBL_9,
			  r.sGroupCust,
			  i.IM_CUST,
			  i.IM_XX_COST_CENTRE01,
			  s.SH_SPARE_STR_5,
			  s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,
              i.IM_BRAND,i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4







	UNION ALL
/*FaxOrderEntryFee*/

/*VerbalOrderEntryFee*/
	SELECT    s.SH_CUST               AS "Customer",
			  r.sGroupCust              AS "Parent",
			  CASE    WHEN i.IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
			  WHEN i.IM_CUST = 'TABCORP' THEN i.IM_XX_COST_CENTRE01
			  ELSE s.SH_SPARE_STR_4
			  END                      AS "CostCentre",
			  s.SH_ORDER              AS "Order",
			  s.SH_SPARE_STR_5         AS "OrderwareNum",
			  s.SH_CUST_REF            AS "CustomerRef",
			  NULL               AS "Pickslip",
			  NULL                    AS "PickNum",
			  NULL              AS "DespatchNote",
			  substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  'OrderEntryFee'
			  ELSE ''
			  END                     AS "FeeType",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  'FEEORDERENTRYS'
			  ELSE ''
			  END                     AS "Item",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  'Phone Order Entry Fee'
			  ELSE ''
			  END                     AS "Description",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  1
			  ELSE NULL
			  END                     AS "Qty",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  '1'
			  ELSE ''
			  END                     AS "UOI",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = 'TABCORP')
			  ELSE NULL
			  END                     AS "UnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = 'TABCORP')
			  ELSE NULL
			  END                     AS "OWUnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = 'TABCORP')
			  ELSE NULL
			  END                     AS "DExcl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = 'TABCORP')
			  ELSE NULL
			  END                     AS "Excl_Total",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN   (Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = 'TABCORP') * 1.1
			  ELSE NULL
			  END                     AS "DIncl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN (Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = 'TABCORP') * 1.1
			  ELSE NULL
			  END                     AS "Incl_Total",
			  NULL                    AS "ReportingPrice",
			  s.SH_ADDRESS            AS "Address",
			  s.SH_SUBURB             AS "Address2",
			  s.SH_CITY               AS "Suburb",
			  s.SH_STATE              AS "State",
			  s.SH_POST_CODE          AS "Postcode",
			  s.SH_NOTE_1             AS "DeliverTo",
			  s.SH_NOTE_2             AS "AttentionTo" ,
			  NULL             AS "Weight",
			  NULL           AS "Packages",
			  s.SH_SPARE_DBL_9        AS "OrderSource",
			  NULL AS "Pallet/Shelf Space", /*Pallet/Space*/
				NULL AS "Locn", /*Locn*/
				--0 AS "AvailSOH",/*Avail SOH*/
				0 AS "CountOfStocks",
        CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			        ELSE ''
			        END AS Email,
              i.IM_BRAND AS Brand,
           i.IM_OWNED_By AS    OwnedBy,
           i.IM_PROFILE AS    sProfile,
           s.SH_XX_FEE_WAIVE AS    WaiveFee,
           d.SD_COST_PRICE As   Cost,
           s.SH_SPARE_INT_4 AS PaymentType
	FROM      PWIN175.SH s
			  INNER JOIN PWIN175.SD d ON d.SD_ORDER  = s.SH_ORDER
			  INNER JOIN PWIN175.IM i ON i.IM_STOCK = d.SD_STOCK
			  INNER JOIN PWIN175.ST t ON t.ST_ORDER = s.SH_ORDER AND t.ST_PICK = s.SH_LAST_PICK_NUM
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
			  --LEFT JOIN PWIN175.RM r2 ON r2.RM_ANAL = r.RM_ANAL AND r2.RM_CUST = :cust
	WHERE (r.sGroupCust = 'TABCORP' OR r.sCust = 'TABCORP')
  AND       t.ST_DESP_DATE >= '01-MAY-2015' AND t.ST_DESP_DATE <= '30-MAY-2015'
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	AND       s.SH_SPARE_DBL_9 = 4
	AND       d.SD_LINE = 1
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> 0
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> '0'
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) IS NOT NULL
	--AND     nRM_XX_FEE01 > 0
  AND (SELECT To_Number(regexp_substr(RM_XX_FEE01,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = 'TABCORP') > 0.1
	GROUP BY  s.SH_CUST,
			  s.SH_ADD_DATE,
			  s.SH_SPARE_STR_4,
			  s.SH_ORDER,
			  s.SH_PREV_PSLIP_NUM,
			  t.ST_DESP_DATE,
			  s.SH_SPARE_DBL_9,
			  d.SD_LINE,
			  s.SH_ADDRESS,
			  s.SH_SUBURB,
			  s.SH_CITY,
			  s.SH_STATE,
			  s.SH_POST_CODE,
			  s.SH_NOTE_1,
			  s.SH_NOTE_2,
			  s.SH_SPARE_DBL_9,
			  r.sGroupCust,
			  i.IM_CUST,
			  i.IM_XX_COST_CENTRE01,
			  s.SH_SPARE_STR_5,
			  s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,
              i.IM_BRAND,i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4







	UNION ALL
/*VerbalOrderEntryFee*/



/*PhotoFee*/
	SELECT    s.SH_CUST               AS "Customer",
			  r.sGroupCust              AS "Parent",
			  CASE    WHEN i.IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
			  WHEN i.IM_CUST = 'TABCORP' THEN i.IM_XX_COST_CENTRE01
			  ELSE s.SH_SPARE_STR_4
			  END                      AS "CostCentre",
			  s.SH_ORDER              AS "Order",
			  s.SH_SPARE_STR_5         AS "OrderwareNum",
			  s.SH_CUST_REF            AS "CustomerRef",
			  t.ST_PICK               AS "Pickslip",
			  t.ST_PICK                    AS "PickNum",
			  t.ST_PSLIP              AS "DespatchNote",
			  substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	  CASE    WHEN s.SH_CUST_REF = 'STORE EXPANSION' THEN  'PhotoFee'
			  ELSE ''
			  END                     AS "FeeType",
	  CASE    WHEN s.SH_CUST_REF = 'STORE EXPANSION' THEN  'PHOTOFEEORDER'
			  ELSE ''
			  END                     AS "Item",
	  CASE    WHEN s.SH_CUST_REF = 'STORE EXPANSION' THEN  'Photo Fee'
			  ELSE ''
			  END                     AS "Description",
	  CASE    WHEN s.SH_CUST_REF = 'STORE EXPANSION' THEN  1
			  ELSE NULL
			  END                     AS "Qty",
	  CASE    WHEN s.SH_CUST_REF = 'STORE EXPANSION' THEN  '1'
			  ELSE ''
			  END                     AS "UOI",
	  CASE    WHEN s.SH_CUST_REF = 'STORE EXPANSION' THEN  (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = 'TABCORP')
			  ELSE NULL
			  END                     AS "UnitPrice",
	  CASE    WHEN s.SH_CUST_REF = 'STORE EXPANSION' THEN  (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = 'TABCORP')
			  ELSE NULL
			  END                     AS "OWUnitPrice",
	  CASE    WHEN s.SH_CUST_REF = 'STORE EXPANSION' THEN  (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = 'TABCORP')
			  ELSE NULL
			  END                     AS "DExcl",
	  CASE    WHEN s.SH_CUST_REF = 'STORE EXPANSION' THEN  (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = 'TABCORP')
			  ELSE NULL
			  END                     AS "Excl_Total",
	  CASE    WHEN s.SH_CUST_REF = 'STORE EXPANSION' THEN   (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = 'TABCORP') * 1.1
			  ELSE NULL
			  END                     AS "DIncl",
	  CASE    WHEN s.SH_CUST_REF = 'STORE EXPANSION' THEN  (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = 'TABCORP') * 1.1
			  ELSE NULL
			  END                     AS "Incl_Total",
			  NULL                    AS "ReportingPrice",
			  s.SH_ADDRESS            AS "Address",
			  s.SH_SUBURB             AS "Address2",
			  s.SH_CITY               AS "Suburb",
			  s.SH_STATE              AS "State",
			  s.SH_POST_CODE          AS "Postcode",
			  s.SH_NOTE_1             AS "DeliverTo",
			  s.SH_NOTE_2             AS "AttentionTo" ,
			  NULL             AS "Weight",
			  NULL           AS "Packages",
			  s.SH_SPARE_DBL_9        AS "OrderSource",
			  NULL AS "Pallet/Shelf Space", /*Pallet/Space*/
				NULL AS "Locn", /*Locn*/
				--0 AS "AvailSOH",/*Avail SOH*/
				0 AS "CountOfStocks",
        CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			        ELSE ''
			        END AS Email,
              i.IM_BRAND AS Brand,
           i.IM_OWNED_By AS    OwnedBy,
           i.IM_PROFILE AS    sProfile,
           s.SH_XX_FEE_WAIVE AS    WaiveFee,
           d.SD_COST_PRICE As   Cost,
           s.SH_SPARE_INT_4 AS PaymentType
	FROM      PWIN175.SH s
			  INNER JOIN PWIN175.SD d ON d.SD_ORDER  = s.SH_ORDER
			  INNER JOIN PWIN175.IM i ON i.IM_STOCK = d.SD_STOCK
			  INNER JOIN PWIN175.ST t ON t.ST_ORDER = s.SH_ORDER AND t.ST_PICK = s.SH_LAST_PICK_NUM
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
			  --LEFT JOIN PWIN175.RM r2 ON r2.RM_ANAL = r.RM_ANAL AND r2.RM_CUST = :cust
	WHERE (r.sGroupCust = 'TABCORP' OR r.sCust = 'TABCORP')
  AND       t.ST_DESP_DATE >= '01-MAY-2015' AND t.ST_DESP_DATE <= '30-MAY-2015'
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	AND       s.SH_CUST_REF LIKE 'STORE EXPANSION'
	AND       d.SD_LINE = 1
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> 0
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> '0'
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) IS NOT NULL
	--AND     nRM_XX_FEE32_1 > 0
  AND (SELECT To_Number(regexp_substr(RM_XX_FEE32_1,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = 'TABCORP') > 0.1
	GROUP BY  s.SH_CUST,
			  s.SH_ADD_DATE,
			  s.SH_SPARE_STR_4,
			  s.SH_ORDER,
			  s.SH_PREV_PSLIP_NUM,
			  t.ST_DESP_DATE,
			  s.SH_SPARE_DBL_9,
			  d.SD_LINE,
			  s.SH_ADDRESS,
			  s.SH_SUBURB,
			  s.SH_CITY,
			  s.SH_STATE,
			  s.SH_POST_CODE,
			  s.SH_NOTE_1,
			  s.SH_NOTE_2,
			  s.SH_SPARE_DBL_9,
			  r.sGroupCust,
			  i.IM_CUST,
			  i.IM_XX_COST_CENTRE01,
			  s.SH_SPARE_STR_5,
			  s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,
              i.IM_BRAND,i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4,t.ST_PICK,t.ST_PSLIP







	UNION ALL
/*PhotoFee*/


/*BB PackingFee*/
	SELECT    s.SH_CUST                AS "Customer",
			  r.sGroupCust              AS "Parent",
			  s.SH_SPARE_STR_4         AS "CostCentre",
			  s.SH_ORDER               AS "Order",
			  s.SH_SPARE_STR_5         AS "OrderwareNum",
			  s.SH_CUST_REF            AS "CustomerRef",
			  t.ST_PICK                AS "Pickslip",
			  d.SD_XX_PICKLIST_NUM     AS "PickNum",
			  t.ST_PSLIP               AS "DespatchNote",
			  substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	  CASE    WHEN (i.IM_TYPE = 'BB_PACK' AND (d.SD_STOCK NOT like 'COURIER%' AND d.SD_STOCK NOT like 'FEE%'))  THEN 'Packing Fee'
			  ELSE NULL
			  END                      AS "FeeType",
			  d.SD_STOCK               AS "Item",
			  d.SD_DESC                AS "Description",
	  CASE    WHEN d.SD_LINE IS NOT NULL THEN  1
			  ELSE NULL
			  END                     AS "Qty",
	  CASE    WHEN d.SD_LINE IS NOT NULL THEN  '1'
			  ELSE ''
			  END                     AS "UOI",

	  CASE
			   WHEN i.IM_TYPE = 'BB_PACK'   THEN (Select To_Number(RM_XX_FEE08) from RM where RM_CUST = 'TABCORP')
			 ELSE NULL
			 END                      AS "UnitPrice",
	   CASE
			   WHEN i.IM_TYPE = 'BB_PACK'   THEN (Select To_Number(RM_XX_FEE08) from RM where RM_CUST = 'TABCORP')
			 ELSE NULL
			 END                                          AS "OWUnitPrice",
			  CASE
			   WHEN i.IM_TYPE = 'BB_PACK'  THEN (Select To_Number(RM_XX_FEE08) from RM where RM_CUST = 'TABCORP')
			 ELSE NULL
			 END                      AS "DExcl",
			  CASE
			   WHEN i.IM_TYPE = 'BB_PACK'   THEN (Select To_Number(RM_XX_FEE08) from RM where RM_CUST = 'TABCORP')
			 ELSE NULL
			 END                                          AS "Excl_Total",
		CASE
			   WHEN i.IM_TYPE = 'BB_PACK'  THEN (Select To_Number(RM_XX_FEE08) from RM where RM_CUST = 'TABCORP')   * 1.1
			 ELSE NULL
			 END                      AS "DIncl",
		CASE
			   WHEN i.IM_TYPE = 'BB_PACK'  THEN (Select To_Number(RM_XX_FEE08) from RM where RM_CUST = 'TABCORP')  * 1.1
			 ELSE NULL
			 END                      AS "Incl_Total",
	  CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN (Select To_Number(i.IM_REPORTING_PRICE) from IM i where i.IM_STOCK = d.SD_STOCK)
			  ELSE NULL
			  END                      AS "ReportingPrice",
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
				--0 AS "AvailSOH",/*Avail SOH*/
				0 AS "CountOfStocks",
        CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			        ELSE ''
			        END AS Email,
              i.IM_BRAND AS Brand,
           i.IM_OWNED_By AS    OwnedBy,
           i.IM_PROFILE AS    sProfile,
           s.SH_XX_FEE_WAIVE AS    WaiveFee,
           d.SD_COST_PRICE As   Cost,
           s.SH_SPARE_INT_4 AS PaymentType


	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER  AND t.ST_PICK = d.SD_LAST_PICK_NUM
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
	/*WHERE     (Select rmP.RM_XX_FEE08
			   from RM rmP
			   where To_Number(regexp_substr(rmP.RM_XX_FEE08, '^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0 AND rmp.RM_CUST = :cust)  > 0
					 --To_Number(regexp_substr(r2.RM_XX_FEE01,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0   */
	WHERE       s.SH_ORDER = d.SD_ORDER
	AND       i.IM_TYPE = 'BB_PACK'
	--AND       r.RM_ANAL = :sAnalysis
	AND     (r.sCust = 'BEYONDBLUE' OR r.sGroupCust = 'BEYONDBLUE')
  AND     'TABCORP' = 'BEYONDBLUE'
 -- AND    nRM_XX_FEE08 > 0
  AND (SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = 'TABCORP') > 0.1
	AND       s.SH_STATUS <> 3
	AND       d.SD_STOCK NOT IN ('EMERQSRFEE','COURIER%','FEE%','FEE*','COURIER*','COURIER')
	AND       s.SH_ORDER = t.ST_ORDER
	AND       t.ST_DESP_DATE >= '01-MAY-2015' AND t.ST_DESP_DATE <= '30-MAY-2015'
	GROUP BY  s.SH_CUST,
			  s.SH_SPARE_STR_4,
			  s.SH_ORDER,
			  t.ST_PICK,
			  d.SD_XX_PICKLIST_NUM,
			  t.ST_PSLIP,
			  t.ST_DESP_DATE,
			  i.IM_TYPE,
			  d.SD_STOCK,
			  d.SD_DESC,
			  d.SD_LINE,
			  d.SD_EXCL,
			  d.SD_INCL,
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
			  s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,
              i.IM_BRAND,i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4


	--HAVING    Sum(s.SH_ORDER) <> 1


	UNION ALL


/*BB PackingFee*/

/*Destruction Fee*/
	SELECT    s.SH_CUST                AS "Customer",
			  r.sGroupCust              AS "Parent",
			  CASE    WHEN IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
			  WHEN IM_CUST = 'TABCORP' THEN IM_XX_COST_CENTRE01
			  ELSE s.SH_SPARE_STR_4
			  END                      AS "CostCentre",
			  s.SH_ORDER               AS "Order",
			  s.SH_SPARE_STR_5         AS "OrderwareNum",
			  s.SH_CUST_REF            AS "CustomerRef",
			  t.ST_PICK                AS "Pickslip",
			  d.SD_XX_PICKLIST_NUM     AS "PickNum",
			  t.ST_PSLIP               AS "DespatchNote",
			  substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	  CASE    WHEN s.SH_NOTE_1 = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN 'Destruction Fee is '
			  ELSE NULL
			  END                      AS "FeeType",
	  CASE    WHEN d.SD_LINE IS NOT NULL THEN  'DESTRUCT'
			  ELSE NULL
			  END                     AS "Item",
	  CASE    WHEN d.SD_LINE IS NOT NULL THEN  'Destruction Fee'
			  ELSE NULL
			  END                     AS "Description",
	  CASE    WHEN d.SD_LINE IS NOT NULL THEN  1
			  ELSE NULL
			  END                     AS "Qty",
	  CASE    WHEN d.SD_LINE IS NOT NULL THEN  '1'
			  ELSE ''
			  END                     AS "UOI",
	  CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN  (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = 'TABCORP')
			 ELSE NULL
			 END                      AS "UnitPrice",
	  CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN  (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = 'TABCORP')
			 ELSE NULL
			 END                                      AS "OWUnitPrice",
			CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN  (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = 'TABCORP')
			 ELSE NULL
			 END                      AS "DExcl",
			  CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN  (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = 'TABCORP')
			 ELSE NULL
			 END                                 AS "Excl_Total",
	   CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN  (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = 'TABCORP') * 1.1
			 ELSE NULL
			 END                      AS "DIncl",
	   CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN  (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = 'TABCORP')  * 1.1
			 ELSE NULL
			 END                      AS "Incl_Total",
	  CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN (Select To_Number(i.IM_REPORTING_PRICE) from IM i where i.IM_STOCK = d.SD_STOCK)
			  ELSE NULL
			  END                      AS "ReportingPrice",
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
				--0 AS "AvailSOH",/*Avail SOH*/
				0 AS "CountOfStocks",
        CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			        ELSE ''
			        END AS Email,
              i.IM_BRAND AS Brand,
           i.IM_OWNED_By AS    OwnedBy,
           i.IM_PROFILE AS    sProfile,
           s.SH_XX_FEE_WAIVE AS    WaiveFee,
           d.SD_COST_PRICE As   Cost,
           s.SH_SPARE_INT_4 AS PaymentType



	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
	WHERE   (SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = 'TABCORP') > 0.1
  AND       (r.sGroupCust = 'TABCORP' OR r.sCust = 'TABCORP')
  AND       (s.SH_NOTE_1 = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE')
	AND       s.SH_STATUS <> 3
	AND       d.SD_LINE = 1
	--AND       r.RM_ANAL = :sAnalysis
	AND       s.SH_ORDER = t.ST_ORDER
	AND       t.ST_DESP_DATE >= '01-MAY-2015' AND t.ST_DESP_DATE <= '30-MAY-2015'
	GROUP BY  s.SH_CUST,
			  s.SH_NOTE_1,
			  s.SH_CAMPAIGN,
			  s.SH_SPARE_STR_4,
			  s.SH_ORDER,
			  t.ST_PICK,
			  d.SD_XX_PICKLIST_NUM,
			  t.ST_PSLIP,
			  t.ST_DESP_DATE,
			  i.IM_TYPE,
			  IM_CUST,
			  IM_XX_COST_CENTRE01,
			  d.SD_STOCK,
			  d.SD_DESC,
			  d.SD_LINE,
			  d.SD_EXCL,
			  d.SD_INCL,
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
			  s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
              i.IM_BRAND,s.SH_SPARE_INT_4


	--HAVING    Sum(s.SH_ORDER) <> 1




	UNION ALL
/*Destruction Fee*/

/*Emergency Fee*/
	SELECT    s.SH_CUST                AS "Customer",
			  r.sGroupCust              AS "Parent",
			  CASE    WHEN IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
			  WHEN IM_CUST = 'TABCORP' THEN IM_XX_COST_CENTRE01
			  ELSE s.SH_SPARE_STR_4
			  END                      AS "CostCentre",
			  s.SH_ORDER               AS "Order",
			  s.SH_SPARE_STR_5         AS "OrderwareNum",
			  s.SH_CUST_REF            AS "CustomerRef",
			  NULL                      AS "Pickslip",
			  NULL                    AS "PickNum",
			  NULL                    AS "DespatchNote",
			  substr(To_Char(s.SH_ADD_DATE),0,10)            AS "DespatchDate",
	  CASE    WHEN d.SD_STOCK = 'EMERQSRFEE' AND s.SH_CAMPAIGN = 'TABSPEC' THEN 'Emergency Fee'
			  ELSE NULL
			  END                      AS "FeeType",
	  CASE    WHEN d.SD_LINE IS NOT NULL THEN  'Emergency'
			  ELSE NULL
			  END                     AS "Item",
	  CASE    WHEN d.SD_LINE IS NOT NULL THEN  'Emergency Fee'
			  ELSE NULL
			  END                     AS "Description",
	  CASE    WHEN d.SD_LINE IS NOT NULL THEN  1
			  ELSE NULL
			  END                     AS "Qty",
	  CASE    WHEN d.SD_LINE IS NOT NULL THEN  '1'
			  ELSE ''
			  END                     AS "UOI",
		CASE  WHEN d.SD_STOCK = 'EMERQSRFEE' AND s.SH_CAMPAIGN = 'TABSPEC' THEN d.SD_SELL_PRICE
			  ELSE NULL
			  END                      AS "UnitPrice",
	  d.SD_XX_OW_UNIT_PRICE                     AS "OWUnitPrice",
	   	CASE  WHEN d.SD_STOCK = 'EMERQSRFEE' AND s.SH_CAMPAIGN = 'TABSPEC' THEN d.SD_EXCL
			  ELSE NULL
			  END                      AS "DExcl",
			  CASE   WHEN d.SD_STOCK = 'EMERQSRFEE' AND s.SH_CAMPAIGN = 'TABSPEC' THEN Sum(d.SD_EXCL)
			  ELSE NULL
			  END                      AS "Excl_Total",
		CASE  WHEN d.SD_STOCK = 'EMERQSRFEE' AND s.SH_CAMPAIGN = 'TABSPEC' THEN d.SD_INCL
			  ELSE NULL
			  END                      AS "DIncl",
		CASE  WHEN d.SD_STOCK = 'EMERQSRFEE' AND s.SH_CAMPAIGN = 'TABSPEC' THEN Sum(d.SD_INCL)
			  ELSE NULL
			  END                      AS "Incl_Total",
	  CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN (Select To_Number(i.IM_REPORTING_PRICE) from IM i where i.IM_STOCK = d.SD_STOCK)
			  ELSE NULL
			  END                      AS "ReportingPrice",
			  s.SH_ADDRESS             AS "Address",
			  s.SH_SUBURB              AS "Address2",
			  s.SH_CITY                AS "Suburb",
			  s.SH_STATE               AS "State",
			  s.SH_POST_CODE           AS "Postcode",
			  s.SH_NOTE_1              AS "DeliverTo",
			  s.SH_NOTE_2              AS "AttentionTo" ,
			  NULL                     AS "Weight",
			  NULL                     AS "Packages",
			  s.SH_SPARE_DBL_9         AS "OrderSource",
			  NULL                     AS "Pallet/Shelf Space", /*Pallet/Space*/
				NULL                     AS "Locn", /*Locn*/
				--0                     AS "AvailSOH",/*Avail SOH*/
				0                     AS "CountOfStocks",
        CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			        ELSE ''
			        END AS Email,
              i.IM_BRAND AS Brand,
           i.IM_OWNED_By AS    OwnedBy,
           i.IM_PROFILE AS    sProfile,
           s.SH_XX_FEE_WAIVE AS    WaiveFee,
           d.SD_COST_PRICE As   Cost,
           s.SH_SPARE_INT_4 AS PaymentType


	FROM      PWIN175.SH s
			  INNER JOIN PWIN175.SD d ON d.SD_ORDER  = s.SH_ORDER
			  INNER JOIN PWIN175.IM i ON i.IM_STOCK = d.SD_STOCK
			  INNER JOIN PWIN175.ST t ON t.ST_ORDER = s.SH_ORDER AND t.ST_PICK = s.SH_LAST_PICK_NUM
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
	WHERE     s.SH_ORDER = d.SD_ORDER
	AND       (d.SD_STOCK = 'EMERQSRFEE' AND s.SH_CAMPAIGN = 'TABSPEC')
	AND       s.SH_STATUS <> 3
  AND      (r.sGroupCust = 'TABCORP' OR r.sCust = 'TABCORP')
	AND       t.ST_DESP_DATE >= '01-MAY-2015' AND t.ST_DESP_DATE <= '30-MAY-2015'
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL --(SELECT Count(tt.ST_ORDER) FROM PWIN175.ST tt WHERE LTrim(tt.ST_ORDER) = LTrim(s.SH_ORDER)) = 1
	GROUP BY  s.SH_CUST,
			  s.SH_NOTE_1,
			  s.SH_CAMPAIGN,
			  s.SH_SPARE_STR_4,
			  s.SH_ORDER,
			  t.ST_PICK,
			  d.SD_XX_PICKLIST_NUM,
			  t.ST_PSLIP,
			  s.SH_ADD_DATE,
			  i.IM_TYPE,
			  IM_CUST,
			  IM_XX_COST_CENTRE01,
			  d.SD_STOCK,
			  d.SD_DESC,
			  d.SD_LINE,
			  d.SD_EXCL,
			  d.SD_INCL,
			  d.SD_ADD_DATE,
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
			  s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,
              i.IM_BRAND,i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4;
     