CREATE OR REPLACE PROCEDURE get_desp_freight_curp_t (
			gdf_stock_in IN IM.IM_STOCK%TYPE,
			gdf_warehouse_in IN VARCHAR2,
			gdf_start_date_in IN SH.SH_EDIT_DATE%TYPE,
			gdf_end_date_in IN SH.SH_ADD_DATE%TYPE,
			gdf_desp_freight_cur OUT sys_refcursor
)
AS
  nbreakpoint   NUMBER;
  v_query           VARCHAR2(32000);
BEGIN
  nbreakpoint := 1;

 OPEN gdf_desp_freight_cur FOR
 select     s.SH_CUST                AS "Customer",
            r.RM_PARENT              AS "Parent",
            s.SH_SPARE_STR_4         AS "CostCentre",
            s.SH_ORDER               AS "Order",
            s.SH_SPARE_STR_5         AS "OrderwareNum",
            s.SH_CUST_REF            AS "CustomerRef",
            t.ST_PICK                AS "Pickslip",
            d.SD_XX_PICKLIST_NUM     AS "PickNum",
            t.ST_PSLIP               AS "DespatchNote",
            substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
            'Freight Fee' AS "FeeType",
            d.SD_STOCK               AS "Item",
            d.SD_DESC              AS "Description",
            CASE  WHEN d.SD_LINE IS NOT NULL THEN  1
                  ELSE NULL
                  END                     AS "Qty",
            CASE  WHEN d.SD_LINE IS NOT NULL THEN  '1'
                  ELSE NULL
                  END                      AS "UOI",
            CASE  WHEN d.SD_STOCK like gdf_stock_in AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT <> 'BORBUI' AND r.RM_PARENT <> 'BEYONDBLUE') THEN d.SD_SELL_PRICE
			        WHEN d.SD_STOCK like gdf_stock_in AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT = 'BORBUI' OR r.RM_PARENT = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.125) And (t.ST_SPARE_DBL_1 > 0.00) THEN 1.70
              WHEN d.SD_STOCK like gdf_stock_in AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT = 'BORBUI' OR r.RM_PARENT = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.250) And (t.ST_SPARE_DBL_1 > 0.126) THEN 2.30
              WHEN d.SD_STOCK like gdf_stock_in AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT = 'BORBUI' OR r.RM_PARENT = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.500) And (t.ST_SPARE_DBL_1 > 0.251) THEN 3.40
              WHEN d.SD_STOCK like gdf_stock_in AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT = 'BORBUI' OR r.RM_PARENT = 'BEYONDBLUE') AND (t.ST_WEIGHT > 0.01) THEN d.SD_SELL_PRICE
              ELSE d.SD_SELL_PRICE
			        END                    AS "UnitPrice",
            d.SD_XX_OW_UNIT_PRICE    AS "OWUnitPrice",
            d.SD_EXCL                AS "DExcl",
            Sum(d.SD_EXCL)           AS "Excl_Total",
            d.SD_INCL                AS "DIncl",
            Sum(d.SD_INCL)           AS "Incl_Total",
            NULL                     AS "ReportingPrice",
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
            NULL AS "Pallet/Shelf Space",
            NULL AS "Locn",
            0 AS "AvailSOH",
            0 AS "CountOfStocks",
            'N/A' As Email,
            'N/A' AS Brand,
            NULL AS    OwnedBy,
            NULL AS    sProfile,
            NULL AS    WaiveFee,
            d.SD_COST_PRICE As   Cost,
            d.SD_NOTE_1 AS OriginalIFSCost,
            EOM_REPORT_PKG_TEST.f_GetWarehouse_from_SD(d.SD_LOCN) AS Warehouse
	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_PICK))  = LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM))
			  INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
	WHERE     s.SH_ORDER = d.SD_ORDER
	AND       d.SD_STOCK LIKE gdf_stock_in
	AND       s.SH_ORDER = t.ST_ORDER
	AND       d.SD_SELL_PRICE >= 0.1
	AND       t.ST_DESP_DATE >= gdf_start_date_in  AND t.ST_DESP_DATE <=  gdf_end_date_in
  AND   d.SD_ADD_OP LIKE 'SERV%'
  HAVING EOM_REPORT_PKG_TEST.f_GetWarehouse_from_SD(d.SD_LOCN) LIKE gdf_warehouse_in
	GROUP BY  s.SH_CUST,
			  s.SH_SPARE_STR_4,
			  s.SH_ORDER,
			  t.ST_PICK,
			  d.SD_XX_PICKLIST_NUM,
			  t.ST_PSLIP,
			  t.ST_DESP_DATE,
			  d.SD_STOCK,
			  d.SD_DESC,
			  d.SD_LINE,
			  d.SD_EXCL,
			  d.SD_INCL,
			  d.SD_NOTE_1,
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
			  r.RM_PARENT,
			  s.SH_SPARE_STR_5,
			  s.SH_CUST_REF,
        s.SH_SPARE_STR_3,
        s.SH_SPARE_STR_1,
        t.ST_SPARE_DBL_1,
        d.SD_XX_PSLIP_NUM,
        d.SD_ADD_DATE,
        d.SD_XX_PICKLIST_NUM,
        d.SD_COST_PRICE,
        d.SD_NOTE_1,
        d.SD_LOCN

UNION ALL


 select    s.SH_CUST                AS "Customer",
			  r.RM_PARENT              AS "Parent",
			  s.SH_SPARE_STR_4         AS "CostCentre",
			  s.SH_ORDER               AS "Order",
			  s.SH_SPARE_STR_5         AS "OrderwareNum",
			  s.SH_CUST_REF            AS "CustomerRef",
			  t.ST_PICK                AS "Pickslip",
			  d.SD_XX_PICKLIST_NUM     AS "PickNum",
			  t.ST_PSLIP               AS "DespatchNote",
			  substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	      'Manual Freight Fee' AS "FeeType",
			  d.SD_STOCK               AS "Item",
			  '="' || To_Char(d.SD_DESC) || '"'               AS "Description",
	      CASE  WHEN d.SD_LINE IS NOT NULL THEN  1
			        ELSE NULL
			        END                     AS "Qty",
	      CASE  WHEN d.SD_LINE IS NOT NULL THEN  '1'
			        ELSE NULL
			        END                      AS "UOI",
			  d.SD_SELL_PRICE          AS "UnitPrice",
			  d.SD_XX_OW_UNIT_PRICE    AS "OWUnitPrice",
			  d.SD_EXCL                AS "DExcl",
			  Sum(d.SD_EXCL)           AS "Excl_Total",
			  d.SD_INCL                AS "DIncl",
			  Sum(d.SD_INCL)           AS "Incl_Total",
			  NULL                     AS "ReportingPrice",
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
			  NULL AS "Pallet/Shelf Space",
				NULL AS "Locn",
				0 AS "AvailSOH",
				0 AS "CountOfStocks",
			'N/A' AS Email,
            'N/A' AS Brand,
           NULL AS    OwnedBy,
           NULL AS    sProfile,
           NULL AS    WaiveFee,
           d.SD_COST_PRICE As   Cost,
           d.SD_NOTE_1 AS OriginalIFSCost,
           EOM_REPORT_PKG_TEST.f_GetWarehouse_from_SD(d.SD_LOCN) AS Warehouse
	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_ORDER))  = LTRIM(RTRIM(d.SD_ORDER))
			  INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
	WHERE     s.SH_ORDER = d.SD_ORDER
  AND       d.SD_STOCK IN ('COURIERM','COURIERS','COURIER','DETENTIONTIMEM','DETENTIONTIMES','FREIGHTDUTY')
	AND       s.SH_ORDER = t.ST_ORDER
	AND       d.SD_SELL_PRICE >= 0.1
  AND       d.SD_ADD_DATE >= gdf_start_date_in AND d.SD_ADD_DATE <= gdf_end_date_in
  AND   d.SD_ADD_OP NOT LIKE 'SERV%' AND d.SD_ADD_OP NOT LIKE 'RV%' OR d.SD_ADD_OP NOT LIKE 'PRJ%'
  HAVING EOM_REPORT_PKG_TEST.f_GetWarehouse_from_SD(d.SD_LOCN) LIKE gdf_warehouse_in
	GROUP BY  s.SH_CUST,
			  s.SH_SPARE_STR_4,
			  s.SH_ORDER,
			  t.ST_PICK,
			  d.SD_XX_PICKLIST_NUM,
			  t.ST_PSLIP,
			  t.ST_DESP_DATE,
			  d.SD_STOCK,
			  d.SD_DESC,
			  d.SD_LINE,
			  d.SD_EXCL,
			  d.SD_INCL,
			  d.SD_NOTE_1,
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
			  r.RM_PARENT,
			  s.SH_SPARE_STR_5,
			  s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,d.SD_COST_PRICE,d.SD_NOTE_1, d.SD_LOCN;
 --USING gdf_stock_in, gdf_stock_in, gdf_stock_in, gdf_stock_in, gdf_stock_in, gdf_stock_in, gdf_start_date_in, gdf_end_date_in, gdf_warehouse_in, gdf_start_date_in, gdf_end_date_in, gdf_warehouse_in;
 EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Freight query failed at checkpoint ' || nbreakpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
 END get_desp_freight_curp_t;