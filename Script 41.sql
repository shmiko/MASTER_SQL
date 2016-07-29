 SELECT    s.SH_CUST                AS "Customer",
			    r.RM_PARENT              AS "Parent",
	    CASE    WHEN i.IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
			    WHEN i.IM_CUST = 'TABCORP' THEN i.IM_XX_COST_CENTRE01
			    ELSE i.IM_XX_COST_CENTRE01
			    END                      AS "CostCentre",
			    s.SH_ORDER               AS "Order",
			    s.SH_SPARE_STR_5         AS "OrderwareNum",
			    s.SH_CUST_REF            AS "CustomerRef",
			    t.ST_PICK                AS "Pickslip",
			    d.SD_XX_PICKLIST_NUM     AS "PickNum",
			    t.ST_PSLIP               AS "DespatchNote",
			    --NULL AS "DespatchDate",
			    substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	    CASE    WHEN d.SD_STOCK IS NOT NULL THEN 'Stock'
			    ELSE NULL
			    END                      AS "FeeType",
			    d.SD_STOCK               AS "Item",
			    d.SD_DESC                AS "Description",
			    l.SL_PSLIP_QTY           AS "DespQty",
			    d.SD_QTY_UNIT            AS "UOI",
			    /* We need to get a 3 tiered looup for the stockunit prices, fist get th eprice from thE BATCH if company owned otherwise get the unit price from the sd sell price otherwise get it from the ow xx */
	    CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN d.SD_SELL_PRICE --company owned
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1 AND n.NI_NX_QUANTITY > 0 THEN n.NI_SELL_VALUE/n.NI_NX_QUANTITY
              WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NOT NULL THEN  (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			        ELSE NULL
			        END                        AS "Batch/UnitPrice",

		  /*CASE    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1 THEN d.SD_SELL_PRICE --customer owned
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN (SELECT NX_SELL_VALUE FROM  NX INNER JOIN NE ON NE_PRICE_ENTRY = NX_ENTRY INNER JOIN NI ON NI_ENTRY = NE_ENTRY AND NX_MOVEMENT = NI_NX_MOVEMENT
																								                                                  WHERE NE_NV_EXT_TYPE = 1810105  AND NE_STRENGTH = 3 AND NE_NV_EXT_KEY = (SELECT SL_UID FROM SL WHERE LTrim(RTrim(SL_PICK)) = LTrim(RTrim(t.ST_PICK)) AND SL_ORDER_LINE  = d.SD_LINE)
																								                                                  AND NE_DATE = t.ST_DESP_DATE
																								                                                  AND NE_STOCK = d.SD_STOCK)
			        --WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NOT NULL THEN  (SELECT To_Number(vUnitPrice) * d.SD_QTY_DESP FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE  * d.SD_QTY_DESP
			        ELSE NULL
			        END                        AS "DExcl",*/
	    CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN To_Number(i.IM_REPORTING_PRICE)
			    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN  (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
			    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			    ELSE NULL
			    END                        AS "OWUnitPrice",
        CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN d.SD_SELL_PRICE * d.SD_QTY_DESP--customer owned
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1 AND n.NI_NX_QUANTITY > 0 THEN (n.NI_SELL_VALUE/n.NI_NX_QUANTITY) * d.SD_QTY_DESP
              WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NOT NULL THEN  (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) * d.SD_QTY_DESP
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE * d.SD_QTY_DESP
			        ELSE NULL
			        END          AS "DExcl",

	    CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN To_Number(i.IM_REPORTING_PRICE)
			    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN  (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
			    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			    ELSE NULL
			    END                       AS "Excl_Total",
	    CASE     WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN (d.SD_SELL_PRICE * d.SD_QTY_DESP) * 1.1--customer owned
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1  AND n.NI_NX_QUANTITY > 0 THEN  ((n.NI_SELL_VALUE/n.NI_NX_QUANTITY) * d.SD_QTY_DESP) * 1.1
              WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NOT NULL THEN  ((SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) * d.SD_QTY_DESP) * 1.1
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  (d.SD_XX_OW_UNIT_PRICE * d.SD_QTY_DESP) * 1.1
			        ELSE NULL
			        END          AS "DIncl",
	    CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN (d.SD_SELL_PRICE * d.SD_QTY_DESP) * 1.1--customer owned
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1 AND n.NI_NX_QUANTITY > 0 THEN  ((n.NI_SELL_VALUE/n.NI_NX_QUANTITY) * d.SD_QTY_DESP) * 1.1
              WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NOT NULL THEN  ((SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) * d.SD_QTY_DESP) * 1.1
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  (d.SD_XX_OW_UNIT_PRICE * d.SD_QTY_DESP) * 1.1
			        ELSE NULL
			        END          AS "Incl_Total",
	    CASE    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN To_Number(i.IM_REPORTING_PRICE)
			    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN  (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
			    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
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

				  0 AS "CountOfStocks",
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			          ELSE ''
			          END AS Email,
                i.IM_BRAND AS Brand,
           i.IM_OWNED_By AS    OwnedBy,
           i.IM_PROFILE AS    sProfile,
           SH_XX_FEE_WAIVE AS    WaiveFee,
           d.SD_COST_PRICE As   Cost,
          NULL AS PaymentType

	  FROM      PWIN175.SD d
			    INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			    INNER JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER
          INNER JOIN PWIN175.SL l  ON l.SL_PICK   = t.ST_PICK
			    INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
			    INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
          INNER JOIN PWIN175.NI n  ON n.NI_NV_EXT_KEY = l.SL_UID
    WHERE NI_NV_EXT_TYPE = 1810105 AND NI_STRENGTH = 3 AND NI_DATE = t.ST_DESP_DATE AND NI_STOCK = d.SD_STOCK AND NI_STATUS <> 0
	  AND     s.SH_STATUS <> 3
    AND       s.SH_ORDER = t.ST_ORDER
	  AND       d.SD_STOCK NOT LIKE 'COURIER'
	  AND       d.SD_STOCK NOT LIKE 'FEE*'
	  AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
	  AND       d.SD_LAST_PICK_NUM = t.ST_PICK
    AND     i.IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_ANAL = :sAnalysis AND RM_TYPE = 0 AND RM_ACTIVE = 1 )
    --AND     EXISTS (SELECT RM_CUST FROM RM WHERE RM_ANAL = :sAnalysis AND RM_TYPE = 0 AND RM_ACTIVE = 1 )
--(SELECT RM_CUST FROM RM WHERE RM_ANAL = :sAnalysis)
	  GROUP BY  s.SH_CUST,
			    s.SH_NOTE_1,
			    s.SH_CAMPAIGN,
			    s.SH_SPARE_STR_4,
			    i.IM_XX_COST_CENTRE01,
			    i.IM_CUST,
			    r.RM_PARENT,
			    s.SH_ORDER,
			    t.ST_PICK,
			    d.SD_XX_PICKLIST_NUM,
			    i.IM_REPORTING_PRICE,
			    i.IM_NOMINAL_VALUE,
			    t.ST_PSLIP,
			    t.ST_DESP_DATE,
			    d.SD_QTY_ORDER,
			    d.SD_QTY_UNIT,
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
			    r.RM_GROUP_CUST,
			    r.RM_PARENT,
			    s.SH_SPARE_STR_5,
			    s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,
			    d.SD_SELL_PRICE,
			    i.IM_OWNED_BY,
			    d.SD_QTY_DESP,
          n.NI_SELL_VALUE,
          n.NI_NX_QUANTITY,
                i.IM_BRAND,l.SL_PSLIP_QTY,i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE







SELECT * FROM Tmp_Group_Cust;





























































































































               SELECT * FROM tbl_AdminData


 SELECT Count(*) FROM Tmp_Admin_Data_Pick_LineCounts


 SELECT Count(*) FROM RM WHERE RM_XX_FEE01B01 = 1 AND RM_ACTIVE = 1




TRUNCATE TABLE TMP_FREIGHT

TRUNCATE TABLE TMP_HAND_FEES

TRUNCATE TABLE TMP_MISC_FEES

TRUNCATE TABLE TMP_ORD_FEES

TRUNCATE TABLE TMP_PAL_CTN_FEES

TRUNCATE TABLE TMP_CTN_FEES

TRUNCATE TABLE TMP_STOR_FEES

Select * From TMP_FREIGHT
UNION ALL
Select * From TMP_HAND_FEES
UNION ALL
Select * From TMP_MISC_FEES
UNION ALL
Select * From TMP_ORD_FEES
UNION ALL
Select * From TMP_PAL_CTN_FEES
UNION ALL
Select * From TMP_CTN_FEES
UNION ALL
Select * From TMP_STOR_FEES


SELECT * FROM VN
