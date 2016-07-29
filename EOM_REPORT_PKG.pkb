CREATE OR REPLACE PACKAGE BODY PWIN175.EOM_REPORT_PKG
AS
   --TYPE myBrandTableType AS TABLE OF myBrandType;
  
 --TYPE t_custtype AS TABLE OF custtype;
  
  --Get TotalOrders for day for cust
  FUNCTION total_orders
    ( rm_cust_in IN rm.rm_cust%TYPE,
    status_in IN sh.sh_status%TYPE:=NULL,
    sh_add_in IN sh.sh_add_date%TYPE)
  RETURN NUMBER
  IS
    --Internal  UPPER status code
    status_int sh.sh_status%TYPE:=Upper(status_in);

    --Parameterised cursor returns total orders
    CURSOR order_cur (status_in IN sh.sh_status%TYPE)   IS
      SELECT Count(SH_ORDER)
        FROM SH
      WHERE sh.sh_cust = rm_cust_in
      AND sh_status NOT LIKE status_in
      AND sh.sh_add_date >= sh_add_in;


      --Return value for function
      return_value NUMBER;
  BEGIN
    OPEN order_cur (status_int);
    FETCH order_cur INTO return_value;
    IF order_cur%NOTFOUND
    THEN
      CLOSE order_cur;
      RETURN NULL;
    ELSE
      CLOSE order_cur;
      RETURN return_value;
    END IF;
  END total_orders;

  --Get TotalDespatches for day for cust
  FUNCTION total_despatches
    ( d_rm_cust_in IN rm.rm_cust%TYPE,
    d_status_in IN sh.sh_status%TYPE:=NULL,
    st_add_in IN st.st_desp_date%TYPE)
  RETURN NUMBER
  IS
    --Internal  UPPER status code
    status_int2 sh.sh_status%TYPE:=Upper(d_status_in);

    --Parameterised cursor returns total orders
    CURSOR desp_cur (status_in IN sh.sh_status%TYPE)   IS
      SELECT Count(SH_ORDER)
        FROM ST,SH
      WHERE ST_ORDER = SH_ORDER
      AND sh.sh_cust = d_rm_cust_in
      AND sh_status NOT LIKE d_status_in
      AND st.st_desp_date >= st_add_in;


      --Return value for function
      return_desp_value NUMBER;
  BEGIN
    OPEN desp_cur (status_int2);
    FETCH desp_cur INTO return_desp_value;
    IF desp_cur%NOTFOUND
    THEN
      CLOSE desp_cur;
      RETURN NULL;
    ELSE
      CLOSE desp_cur;
      RETURN return_desp_value;
    END IF;
  END total_despatches;

  --Group Cust Procedure - Creates temp table of all customers grouped into top level parent
  PROCEDURE GROUP_CUST_START AS
    nCheckpoint  NUMBER;
  BEGIN

    nCheckpoint := 1;
    EXECUTE IMMEDIATE	'TRUNCATE  TABLE Tmp_Group_Cust';


    nCheckpoint := 2;
    EXECUTE IMMEDIATE 'INSERT into Tmp_Group_Cust(sCust,sGroupCust,nLevel )
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
                    FROM RM
                    WHERE RM_TYPE = 0
                    AND RM_ACTIVE = 1
                    --AND Length(RM_GROUP_CUST) <=  1
                    CONNECT BY PRIOR RM_CUST = RM_PARENT
                    START WITH Length(RM_PARENT) <= 1';


    DBMS_OUTPUT.PUT_LINE('Successfully truncated, recreated AND populated Tmp_Group_Cust');


    RETURN;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('GROUP_CUST_START failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END GROUP_CUST_START;

  --List cust and name
  PROCEDURE GROUP_CUST_GET
    (gc_customer_in IN rm.rm_cust%TYPE)
    AS
    CURSOR gc_cur IS
      SELECT r.rm_cust, r.rm_name
      FROM rm r
      WHERE r.rm_cust = gc_customer_in
      ORDER BY r.rm_cust;
    gc_rec gc_cur%ROWTYPE;
  BEGIN
    OPEN gc_cur;
    FETCH gc_cur INTO gc_rec;
    WHILE(gc_cur%FOUND)
    LOOP
      DBMS_OUTPUT.PUT_LINE(gc_rec.rm_cust || '-' || gc_rec.rm_name);
      FETCH gc_cur INTO gc_rec;
    END LOOP;
    CLOSE gc_cur;
  END GROUP_CUST_GET;

  --List cust name, group cust and level
  PROCEDURE GROUP_CUST_LIST
    (tgc_customer_in IN rm.rm_cust%TYPE)
    AS
      nCheckpoint  NUMBER;
    CURSOR tgc_cur IS
      SELECT tgc.sCust, tgc.sGroupCust, tgc.nLevel
      FROM Tmp_Group_Cust tgc
      WHERE tgc.sCust = tgc_customer_in;

    tgc_rec tgc_cur%ROWTYPE;
  BEGIN

    nCheckpoint := 1;
    OPEN tgc_cur;
    FETCH tgc_cur INTO tgc_rec;
    WHILE(tgc_cur%FOUND)
    LOOP
      DBMS_OUTPUT.PUT_LINE(tgc_rec.sCust || ' ' || tgc_rec.sGroupCust || ' - Level ' || tgc_rec.nLevel);
      FETCH tgc_cur INTO tgc_rec;
    END LOOP;
    CLOSE tgc_cur;

    --EXECUTE IMMEDIATE 'SELECT * FROM Tmp_Group_Cust';

    RETURN;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('GROUP_CUST failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END GROUP_CUST_LIST;

  PROCEDURE DESP_STOCK_GET    (
              cdsg_date_from_in IN  SH.SH_ADD_DATE%TYPE,
              cdsg_date_to_in IN  SH.SH_EDIT_DATE%TYPE,
              cdsg_cust_in IN RM.RM_CUST%TYPE
              ) AS

   CURSOR cdsg_cur IS
   SELECT    SH.SH_CUST,  RM.RM_PARENT, SH.SH_ORDER,  SH.SH_SPARE_STR_5,SH.SH_CUST_REF,SH.SH_ADDRESS,SH.SH_SUBURB,
		SH.SH_CITY, SH.SH_STATE , SH.SH_POST_CODE , SH.SH_NOTE_1 ,SH.SH_NOTE_2 ,SH.SH_SPARE_DBL_9
	FROM      PWIN175.SH INNER JOIN PWIN175.RM  ON RM.RM_CUST  = SH.SH_CUST
  WHERE SH.SH_STATUS <> 3
  AND     RM.RM_CUST = cdsg_cust_in
	AND       SH.SH_ADD_DATE >= cdsg_date_from_in AND SH.SH_ADD_DATE <= cdsg_date_to_in
	GROUP BY SH.SH_CUST,  RM.RM_PARENT, SH.SH_ORDER,  SH.SH_SPARE_STR_5,SH.SH_CUST_REF,SH.SH_ADDRESS,SH.SH_SUBURB,
		SH.SH_CITY, SH.SH_STATE , SH.SH_POST_CODE , SH.SH_NOTE_1 ,SH.SH_NOTE_2 ,SH.SH_SPARE_DBL_9;
    cdsg_rec cdsg_cur%ROWTYPE;
  BEGIN
    OPEN cdsg_cur;
    FETCH cdsg_cur INTO cdsg_rec;
    WHILE cdsg_cur%FOUND
    LOOP
      DBMS_OUTPUT.PUT_LINE(cdsg_rec.SH_CUST || ',' || cdsg_rec.RM_PARENT || ',' || cdsg_rec.SH_SPARE_STR_5 || ',' || cdsg_rec.SH_ORDER || ',' || cdsg_rec.SH_SPARE_DBL_9 || ',' || cdsg_rec.SH_NOTE_2 || ',' || cdsg_rec.SH_NOTE_1 || ',' || cdsg_rec.SH_CITY );
      FETCH cdsg_cur INTO cdsg_rec;
    END LOOP;
  CLOSE cdsg_cur;
 END DESP_STOCK_GET;

  FUNCTION F_BREAK_UNIT_PRICE
                  ( rm_cust_in IN II.II_CUST%TYPE,
                    stock_in   IN II.II_STOCK%TYPE)
  RETURN NUMBER

  AS

  price_break NUMBER;

  BEGIN
    IF stock_in IS NOT NULL THEN
        SELECT II_BREAK_LCL
        INTO  price_break
	      FROM II
	      WHERE II_BREAK_LCL > 0.000001
        AND II_STOCK = stock_in
	      AND II_CUST= rm_cust_in;
        --price_in := II.II_BREAK_LCL;
        RETURN price_break;
    ELSE
      RETURN 'N/A';
    END IF;
  END F_BREAK_UNIT_PRICE; 

 
  PROCEDURE get_desp_stocks_cur_p 
                      (
                          gds_cust_in IN IM.IM_CUST%TYPE,
                          gds_cust_not_in IN  IM.IM_CUST%TYPE,
                          gds_stock_not_in IN IM.IM_STOCK%TYPE,
                          gds_stock_not_in2 IN IM.IM_STOCK%TYPE,
                          gds_start_date_in IN SH.SH_EDIT_DATE%TYPE,
                          gds_end_date_in IN SH.SH_ADD_DATE%TYPE,
                          desp_stock_list_cur_var IN OUT stock_ref_cur
                        )
  AS
  BEGIN
      OPEN desp_stock_list_cur_var FOR
    	SELECT    SH.SH_CUST
			         ,SH.SH_ORDER
		           ,substr(To_Char(ST.ST_DESP_DATE),0,10)
	             ,SD.SD_STOCK
			         ,SD.SD_DESC
			        /*,CASE  WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in   AND IM.IM_OWNED_BY = 0 THEN SD.SD_SELL_PRICE
			                WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in   AND IM.IM_OWNED_BY = 1 THEN NI.NI_SELL_VALUE/NI_NX_QUANTITY
                      WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in   AND eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NOT NULL THEN eom_report_pkg.F_BREAK_UNIT_PRICE(RM_GROUP_CUST,SD_STOCK)
			                WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in   AND eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NULL THEN  SD_XX_OW_UNIT_PRICE
			                ELSE NULL
			                END,*/
		           ,IM.IM_BRAND
	FROM  PWIN175.SD
			  RIGHT JOIN PWIN175.SH  ON SH.SH_ORDER  = SD.SD_ORDER
			  LEFT JOIN PWIN175.ST  ON ST.ST_PICK  = SD.SD_LAST_PICK_NUM
        LEFT JOIN PWIN175.SL   ON SL.SL_PICK   = ST.ST_PICK
			  INNER JOIN PWIN175.RM  ON RM.RM_CUST  = SH.SH_CUST
			  INNER JOIN PWIN175.IM  ON IM.IM_STOCK = SD.SD_STOCK
        INNER JOIN PWIN175.NI  ON NI.NI_NV_EXT_KEY = SL.SL_UID
  WHERE NI.NI_STRENGTH = 3 AND NI.NI_DATE = ST.ST_DESP_DATE AND NI.NI_STOCK = SD_STOCK AND NI.NI_STATUS <> 0
	AND     SH.SH_STATUS <> 3
  AND     IM.IM_CUST IN (gds_cust_in)
	AND       SH.SH_ORDER = ST.ST_ORDER
  AND       ST.ST_DESP_DATE >= gds_start_date_in AND ST.ST_DESP_DATE <= gds_end_date_in
 	AND       SD.SD_LAST_PICK_NUM = ST.ST_PICK
	GROUP BY  SH.SH_CUST,SH.SH_ORDER,
			      ST.ST_DESP_DATE,
			      SD.SD_DESC,SD.SD_STOCK,SD.SD_XX_OW_UNIT_PRICE,SD.SD_SELL_PRICE,
            IM.IM_BRAND,IM.IM_OWNED_BY,IM.IM_CUST,
            NI.NI_SELL_VALUE,NI.NI_NX_QUANTITY,
            RM.RM_GROUP_CUST;
 END get_desp_stocks_cur_p;
 
 
  PROCEDURE get_desp_stocks_curp (
			gds_cust_in IN IM.IM_CUST%TYPE,
			gds_cust_not_in IN  IM.IM_CUST%TYPE,
			--gds_nx_ext_type_in IN NI.NI_NV_EXT_TYPE%TYPE,
			gds_stock_not_in IN IM.IM_STOCK%TYPE,
			gds_stock_not_in2 IN IM.IM_STOCK%TYPE,
			gds_start_date_in IN SH.SH_EDIT_DATE%TYPE,
			gds_end_date_in IN SH.SH_ADD_DATE%TYPE,
			gds_src_get_desp_stocks OUT sys_refcursor
)
AS
  nbreakpoint   NUMBER;
BEGIN
  nbreakpoint := 1;
  OPEN gds_src_get_desp_stocks FOR
  SELECT     SH.SH_CUST   AS "Customer"
            ,RM.RM_PARENT   AS "Parent"
            ,CASE  
              WHEN IM.IM_CUST <> gds_cust_not_in AND SH.SH_SPARE_STR_4 IS NULL THEN SH.SH_CUST
              WHEN IM.IM_CUST <> gds_cust_not_in THEN SH.SH_SPARE_STR_4
              WHEN IM.IM_CUST =  gds_cust_not_in THEN IM.IM_XX_COST_CENTRE01
              ELSE IM.IM_XX_COST_CENTRE01
			      END AS "CostCentre"
           ,SH.SH_ORDER AS "Order"
           ,SH.SH_SPARE_STR_5         AS "OrderwareNum"
           ,SH.SH_CUST_REF            AS "CustomerRef"
           ,ST.ST_PICK                AS "Pickslip"
           ,SD.SD_XX_PICKLIST_NUM     AS "PickNum"
           ,ST.ST_PSLIP               AS "DespatchNote"
           ,substr(To_Char(ST.ST_DESP_DATE),0,10) AS "DespatchDate"
           ,CASE   WHEN SD.SD_STOCK IS NOT NULL THEN SD.SD_STOCK
			      ELSE NULL
			      END                       AS "FeeType"
           ,SD.SD_STOCK               AS "Item"
           ,SD.SD_DESC                AS "Description"
           ,SL.SL_PSLIP_QTY           AS "Qty"
           ,SD.SD_QTY_UNIT            AS "UOI"
           ,CASE WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in   AND IM.IM_OWNED_BY = 0 THEN SD.SD_SELL_PRICE
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in   AND IM.IM_OWNED_BY = 1 THEN NI.NI_SELL_VALUE/NI_NX_QUANTITY
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in    AND eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NOT NULL THEN eom_report_pkg.F_BREAK_UNIT_PRICE(RM_GROUP_CUST,SD_STOCK)
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in    AND eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NULL THEN  SD.SD_XX_OW_UNIT_PRICE
                 ELSE NULL
                 END AS "Batch/UnitPrice"
           ,CASE WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in THEN To_Number(IM.IM_REPORTING_PRICE)
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  THEN  eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK)
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  AND eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NULL THEN  SD.SD_XX_OW_UNIT_PRICE
                 ELSE NULL
                 END                        AS "OWUnitPrice"
           ,CASE WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in AND IM.IM_OWNED_BY = 0 THEN SD.SD_SELL_PRICE * SL.SL_PSLIP_QTY
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in AND IM.IM_OWNED_BY = 1 THEN (NI.NI_SELL_VALUE/NI.NI_NX_QUANTITY) * SL.SL_PSLIP_QTY
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  AND eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NOT NULL THEN  eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) * SL.SL_PSLIP_QTY
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  AND eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NULL THEN  SD.SD_XX_OW_UNIT_PRICE * SL.SL_PSLIP_QTY
                 ELSE NULL
                 END          AS "DExcl"
           ,CASE WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in THEN To_Number(IM.IM_REPORTING_PRICE)
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  THEN  eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK)
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  AND eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NULL THEN  SD.SD_XX_OW_UNIT_PRICE
                 ELSE NULL
                 END                       AS "Excl_Total"
           ,CASE WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in AND IM.IM_OWNED_BY = 0 THEN (SD.SD_SELL_PRICE * SL.SL_PSLIP_QTY) * 1.1
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in AND IM.IM_OWNED_BY = 1 THEN ((NI.NI_SELL_VALUE/NI.NI_NX_QUANTITY) * SL.SL_PSLIP_QTY) * 1.1
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  AND eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NOT NULL THEN  (eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) * SL.SL_PSLIP_QTY) * 1.1
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  AND eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NULL THEN  (SD.SD_XX_OW_UNIT_PRICE * SL.SL_PSLIP_QTY) * 1.1
                 ELSE NULL
                 END          AS "DIncl"
           ,CASE WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in AND IM.IM_OWNED_BY = 0 THEN (SD.SD_SELL_PRICE * SL.SL_PSLIP_QTY) * 1.1
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in AND IM.IM_OWNED_BY = 1 THEN ((NI.NI_SELL_VALUE/NI.NI_NX_QUANTITY) * SL.SL_PSLIP_QTY) * 1.1
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  AND eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NOT NULL THEN  (eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) * SL.SL_PSLIP_QTY) * 1.1
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  AND eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NULL THEN  (SD.SD_XX_OW_UNIT_PRICE * SL.SL_PSLIP_QTY) * 1.1
                 ELSE NULL
                 END          AS "Incl_Total"
	         ,CASE WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in THEN To_Number(IM.IM_REPORTING_PRICE)
			           WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  THEN  eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK)
			           WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  AND eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NULL THEN  SD.SD_XX_OW_UNIT_PRICE
			           ELSE NULL
			           END                    AS "ReportingPrice"
           ,SH.SH_ADDRESS             AS "Address"
           ,SH.SH_SUBURB              AS "Address2"
           ,SH.SH_CITY                AS "Suburb"
           ,SH.SH_STATE               AS "State"
           ,SH.SH_POST_CODE           AS "Postcode"
           ,SH.SH_NOTE_1              AS "DeliverTo"
           ,SH.SH_NOTE_2              AS "AttentionTo"
           ,ST.ST_WEIGHT              AS "Weight"
           ,ST.ST_PACKAGES            AS "Packages"
           ,SH.SH_SPARE_DBL_9         AS "OrderSource"
           ,NULL AS "Pallet/Shelf Space"
           ,NULL AS "Locn"
           ,NULL AS "AvailSOH"
           ,NULL AS "CountOfStocks"
           ,NULL AS "Email"
           ,IM.IM_BRAND AS Brand
           ,NULL AS OwnedBy
           ,NULL AS sProfile
           ,NULL AS WaiveFee
           ,NULL AS "Cost"
	FROM  PWIN175.SD
			  RIGHT JOIN PWIN175.SH  ON SH.SH_ORDER  = SD.SD_ORDER
			  LEFT JOIN PWIN175.ST  ON ST.ST_PICK  = SD.SD_LAST_PICK_NUM
        LEFT JOIN PWIN175.SL   ON SL.SL_PICK   = ST.ST_PICK
			  INNER JOIN PWIN175.RM  ON RM.RM_CUST  = SH.SH_CUST
			  INNER JOIN PWIN175.IM  ON IM.IM_STOCK = SD.SD_STOCK
        INNER JOIN PWIN175.NI  ON NI.NI_NV_EXT_KEY = SL.SL_UID
  WHERE NI.NI_STRENGTH = 3 AND NI.NI_DATE = ST.ST_DESP_DATE AND NI.NI_STOCK = SD_STOCK AND NI.NI_STATUS <> 0
	AND     SH.SH_STATUS <> 3
  AND     IM.IM_CUST IN (gds_cust_in)
	AND       SH.SH_ORDER = ST.ST_ORDER
  AND       ST.ST_DESP_DATE >= gds_start_date_in AND ST.ST_DESP_DATE <= gds_end_date_in
 	--AND       ST.ST_DESP_DATE >= '10-APR-2014' AND ST.ST_DESP_DATE <= '15-APR-2014'
	AND       SD.SD_LAST_PICK_NUM = ST.ST_PICK
	GROUP BY  SH.SH_CUST,SH.SH_ORDER,SH.SH_ADDRESS,SH.SH_SUBURB,SH.SH_CITY,SH.SH_STATE,SH.SH_POST_CODE,SH.SH_NOTE_1,SH.SH_NOTE_2,SH.SH_CAMPAIGN, SH.SH_SPARE_STR_4,SH.SH_SPARE_DBL_9,SH.SH_CUST_REF,SH.SH_SPARE_STR_5,
			      ST.ST_DESP_DATE,ST.ST_WEIGHT,ST.ST_PACKAGES,ST.ST_PSLIP,ST.ST_PICK,
			      SD.SD_DESC,SD.SD_STOCK,SD.SD_XX_OW_UNIT_PRICE,SD.SD_SELL_PRICE,SD.SD_LINE,SD.SD_EXCL,SD.SD_INCL,SD.SD_QTY_ORDER,SD.SD_QTY_UNIT,SD.SD_XX_PICKLIST_NUM,
            IM.IM_BRAND,IM.IM_OWNED_BY,IM.IM_CUST,IM.IM_XX_COST_CENTRE01,IM.IM_REPORTING_PRICE,
            NI.NI_SELL_VALUE,NI.NI_NX_QUANTITY,
            RM.RM_GROUP_CUST,RM.RM_PARENT,
            SL.SL_PSLIP_QTY;
            
            
            
            
            
   /*         gds_rec gds_src_get_desp_stocks%ROWTYPE;
  BEGIN
    OPEN  gds_src_get_desp_stocks;
    FETCH gds_src_get_desp_stocks INTO  gds_rec;
    WHILE gds_src_get_desp_stocks%FOUND
    LOOP
      Dbms_Output.PUT_LINE('Row: '||gds_src_get_desp_stocks%ROWCOUNT||' # '|| gds_rec.SH_ORDER);
      FETCH gds_src_get_desp_stocks INTO gds_rec;
    END LOOP;
    CLOSE gds_src_get_desp_stocks;
    Dbms_Output.PUT_LINE('finished for cust '||gds_cust_in );    */
 EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('LUX Stock query failed at checkpoint ' || nbreakpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
 END get_desp_stocks_curp; 
 
 PROCEDURE myproc_test_via_PHP(p1 IN NUMBER, p2 IN OUT NUMBER) AS
  BEGIN
    p2 := p1 * 2;
    DBMS_OUTPUT.PUT_LINE(p2);
  END;
  
  PROCEDURE list_stocks(cat IN IM.IM_CAT%TYPE) IS
      TYPE cur_typ IS REF CURSOR;
      cur_list_stocks   cur_typ;
      query_str   VARCHAR2(1000);
      stock_name    VARCHAR2(20);
      cat_name     VARCHAR2(20);
  BEGIN
      query_str := 'SELECT IM_STOCK, IM_CUST FROM IM WHERE IM_CAT = cat';
      -- find stocks who belong to the selected cat
      OPEN cur_list_stocks FOR query_str USING cat;
      LOOP
          FETCH cur_list_stocks INTO stock_name, cat_name;
          EXIT WHEN cur_list_stocks%NOTFOUND;
          dbms_Output.PUT_LINE( stock_name || ' EXISTS IN category ' || cat_name);
      END LOOP;
      CLOSE cur_list_stocks;
  END;
  
  procedure quick_function_test( p_rc OUT SYS_REFCURSOR )AS
  BEGIN
    OPEN p_rc
      for select 1 col1
            from dual;
    CLOSE p_rc;
  END;
  
  
  
  
  FUNCTION f_getDisplay
    (i_column_tx VARCHAR2,
     i_table_select_tx VARCHAR2,
     i_field_tx VARCHAR2,
     i_value_tx VARCHAR2)
    RETURN VARCHAR2
    IS
      v_out_tx VARCHAR2(2000);
      v_sql_tx VARCHAR2(2000);
    BEGIN
      v_sql_tx := 'SELECT ' ||
                  i_column_tx||
                  ' FROM '||i_table_select_tx||
                  ' WHERE '||i_field_tx||' =:4';
    EXECUTE IMMEDIATE v_sql_tx INTO v_out_tx
      USING i_value_tx;
    RETURN v_out_tx;
  END f_getDisplay;
 
 
 
   FUNCTION f_getDisplay_from_type_bind
       (i_first_col IN VARCHAR2,
     i_value_tx IN VARCHAR2
     )
       RETURN myBrandType
       IS
            v_out_tx myBrandType;
            v_sql_tx VARCHAR2(2000);
       BEGIN
      v_sql_tx := ' SELECT myBrandType ( '||i_first_col||',' ||
                     '    u.IR_DESC '||
                    ') FROM IR u '||
                     ' WHERE u.IR_BRAND = :5';
         
       EXECUTE IMMEDIATE v_sql_tx INTO v_out_tx
       USING i_value_tx; 
          RETURN v_out_tx;
  END f_getDisplay_from_type_bind;
  
  
  FUNCTION f_getDisplay_oty
    (i_column_tx VARCHAR2,
     i_column2_tx VARCHAR2,
     i_table_select_tx VARCHAR2,
     i_field_tx VARCHAR2,
     i_value_tx NUMBER)
    RETURN VARCHAR2
    IS
      v_out_tx VARCHAR2(2000);
      v_sql_tx VARCHAR2(2000);
    BEGIN
    EXECUTE IMMEDIATE 'SELECT myBrandType(IR_BRAND,IR_DESC) FROM IR WHERE IR_BRAND = ''AAS_ACIRT''' INTO v_out_tx
      USING i_value_tx;
    RETURN v_out_tx;
  END f_getDisplay_oty;
  
  
  function get_cust_stocks(r_coy_num in VARCHAR) return sys_refcursor is
    v_rc sys_refcursor;
  begin
    open v_rc for 'SELECT RM_CUST, RM_COY_NUM, RM_REP, RM_STD_CB_BANK FROM RM WHERE RM_PARENT = :coynum' using r_coy_num;
    return v_rc;
  end;
  
  
  /*function populate_custs(coynum in VARCHAR := null)
    return  custtype is
            v_custtype custtype := custtype();  -- Declare a local table structure and initialize it
            v_cnt     number := 0;
            v_rc    sys_refcursor;
            v_cust   VARCHAR2(20);
            v_coynum   VARCHAR2(20);
            v_rep    VARCHAR2(20);
            v_bank VARCHAR(20);

     begin
        v_rc := get_cust_stocks(coynum);
        loop
          fetch v_rc into v_cust, v_coynum, v_rep, v_bank;
          exit when v_rc%NOTFOUND;
          v_custtype.extend;
          v_cnt := v_cnt + 1;
          v_custtype(v_cnt) := custtype(v_cust, v_coynum, v_rep, v_bank);
        end loop;
        close v_rc;
        return v_custtype;
      end;
  */
  FUNCTION refcursor_function 
  RETURN SYS_REFCURSOR AS c SYS_REFCURSOR;
  BEGIN
    OPEN c FOR 
      select RM_CUST, RM_NAME, RM_XX_PARENT
      from pwin175.RM
      where RM_PARENT = 'TABCORP';
    RETURN c;
  END;
  
  -- Calling the function from a MAIN BODY
  --variable v_ref_cursor refcursor;
  --exec :v_ref_cursor := refcursor_function(); 
  --print :v_ref_cursor
  
  
  PROCEDURE test_get_brand IS
    brand myBrandType;
  BEGIN
    brand := f_getDisplay_from_type_bind ('u.IR_BRAND','AAS');
    DBMS_OUTPUT.PUT_LINE(brand.brand_tx|| ' - ' ||brand.desc_tx);
  END;
  
   --EOM Create Temp Tables and populate with fresh data 
  PROCEDURE EOM_CREATE_TEMP_DATA (p_pick_status IN NUMBER, p_status IN VARCHAR2, sAnalysis IN VARCHAR2, start_date IN VARCHAR2,end_date IN VARCHAR2  ) AS
		nCheckpoint   NUMBER;
		v_query       VARCHAR2(1000);
	BEGIN

	/* Truncate all temp tables*/
		nCheckpoint := 1;
		v_query := 'TRUNCATE TABLE Tmp_Group_Cust';
		EXECUTE IMMEDIATE v_query;	
	
		nCheckpoint := 2;
		v_query := 'TRUNCATE TABLE Tmp_Admin_Data_BreakPrices';
		EXECUTE IMMEDIATE v_query;	
	
		nCheckpoint := 3;
		v_query := 'TRUNCATE TABLE Tmp_Admin_Data_Pickslips';
		EXECUTE IMMEDIATE	v_query;
	
		nCheckpoint := 4;
		v_query := 'TRUNCATE TABLE Tmp_Admin_Data_Pick_LineCounts';
		EXECUTE IMMEDIATE v_query;
	
		nCheckpoint := 5;
		v_query := 'TRUNCATE TABLE Tmp_Batch_Price_SL_Stock';
		EXECUTE IMMEDIATE v_query;
		
		nCheckpoint := 6;
		v_query := 'TRUNCATE TABLE Tmp_Locn_Cnt_By_Cust';
		EXECUTE IMMEDIATE v_query;
		
		nCheckpoint := 7;
		v_query := 'TRUNCATE TABLE tbl_AdminData';
		EXECUTE IMMEDIATE v_query;
		
		nCheckpoint := 8;
		v_query := 'TRUNCATE TABLE Tmp_Log_stats';
		EXECUTE IMMEDIATE v_query;
		
		nCheckpoint := 9;
		v_query := 'TRUNCATE TABLE Tmp_Cust_Reporting';
		EXECUTE IMMEDIATE v_query;
	
		DBMS_OUTPUT.PUT_LINE('Successfully truncated all temporary tables');

	/* Run Group Cust Procedure*/
		--nCheckpoint := 10;
		--EXECUTE IMMEDIATE 'EXECUTE eom_report_pkg.GROUP_CUST_START';
	
		--DBMS_OUTPUT.PUT_LINE('Successfully truncated, recreated AND populated Tmp_Group_Cust');
       
    EXECUTE IMMEDIATE v_query; /* INTO v_out_tx
      USING i_value_tx;*/
	/*Insert fresh temp data*/
		nCheckpoint := 11;                  
		EXECUTE IMMEDIATE 'INSERT INTO Tmp_Admin_Data_BreakPrices
							SELECT II_STOCK,II_CUST,II_BREAK_LCL
							FROM II INNER JOIN IM ON IM_STOCK = II_STOCK
							AND II_BREAK_LCL > 0.000001';	
										
		nCheckpoint := 12;
    /* v_query := 'SELECT ' ||
                  i_column_tx||
                  ' FROM '||i_table_select_tx||
                  ' WHERE '||i_field_tx||' =:4';*/
    EXECUTE IMMEDIATE q'{INSERT INTO Tmp_Admin_Data_Pickslips
							SELECT LTrim(ST_PICK),LTrim(ST_PSLIP), substr(To_Char(ST_DESP_DATE),0,10), ST_WEIGHT, ST_PACKAGES,ST_XX_NUM_PAL_SW,ST_XX_NUM_PALLETS,ST_XX_NUM_CARTONS
							FROM ST LEFT JOIN SH ON SH_ORDER = ST_ORDER
							WHERE ST_DESP_DATE >= '1-Apr-2014' AND ST_DESP_DATE <= '30-Apr-2014'	--AND ST_PSLIP != 'CANCELLED'
							AND SH_STATUS <> 3}';	
	
		nCheckpoint := 13;
		EXECUTE IMMEDIATE q'{INSERT INTO Tmp_Admin_Data_Pick_LineCounts  
							SELECT MAX(SL_LINE),LTrim(SL_PICK), LTrim(SL_ORDER), LTrim(SL_PSLIP),TP.vDateDesp, TP.vPackages,TP.vWeight,TP.vST_XX_NUM_PAL_SW,TP.vST_XX_NUM_PALLETS,TP.vST_XX_NUM_CARTONS
							FROM Tmp_Admin_Data_Pickslips TP RIGHT JOIN SL ON LTrim(SL_PICK) = TP.vPickslip WHERE SL_EDIT_DATE >= '1-Apr-2014' AND SL_EDIT_DATE <= '30-Apr-2014' 
							GROUP BY SL_PICK,SL_ORDER,SL_PSLIP,TP.vDateDesp,TP.vPackages,TP.vWeight,TP.vST_XX_NUM_PAL_SW,TP.vST_XX_NUM_PALLETS,TP.vST_XX_NUM_CARTONS}'; 	
		
		nCheckpoint := 14;
		v_query := q'{INSERT INTO Tmp_Batch_Price_SL_Stock(vBatchStock,vBatchPickNum,vUnitPrice,vDExcl, vQuantity)
						SELECT nz.NI_STOCK, LTrim(RTrim(nz.NI_SL_PSLIP)), CAST((NX_SELL_VALUE/NX_QUANTITY) AS DECIMAL(22,2)) AS "UnitPrice", CAST(xz.NX_SELL_VALUE AS DECIMAL(22,2)), xz.NX_QUANTITY
						FROM  NX xz INNER JOIN NI nz ON nz.NI_NX_MOVEMENT = xz.NX_MOVEMENT
						INNER JOIN NE ez ON ez.NE_ENTRY = nz.NI_ENTRY AND ez.NE_PRICE_ENTRY = xz.NX_ENTRY
						WHERE ez.NE_NV_EXT_TYPE = 1810105
						AND ez.NE_STRENGTH = 3
						AND xz.NX_SELL_VALUE > 0 AND xz.NX_SELL_VALUE IS NOT NULL
						AND xz.NX_QUANTITY > 0
						AND ez.NE_ADD_DATE >= '1-Apr-2014'
						GROUP BY nz.NI_STOCK, nz.NI_SL_PSLIP, xz.NX_SELL_VALUE, xz.NX_QUANTITY}';
		EXECUTE IMMEDIATE v_query; /*  INTO v_out_tx
      USING i_value_tx;; */

		nCheckpoint := 15;
		v_query := q'{INSERT INTO Tmp_Locn_Cnt_By_Cust
						SELECT Count(DISTINCT NI_STOCK) AS CountOfStocks, IL_LOCN, IM_CUST
						FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
						INNER JOIN IM ON IM_STOCK = NI_STOCK
						WHERE IM_CUST IN (SELECT RM_CUST FROM RM WHERE /*RM_PARENT = ' '  AND*/ RM_ANAL = '21VICP' AND RM_TYPE = 0 AND RM_ACTIVE = 1 )
						AND IM_ACTIVE = 1
						AND NI_AVAIL_ACTUAL >= '1'
						AND NI_STATUS <> 0
						GROUP BY IL_LOCN, IM_CUST}';
		EXECUTE IMMEDIATE v_query;

		--nCheckpoint := 16;
		--v_query = q'{}';
		--EXECUTE IMMEDIATE v_query; 
	
	
		DBMS_OUTPUT.PUT_LINE('Successfully inserted fresh temporary data');


    RETURN;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END EOM_CREATE_TEMP_DATA;
  
    --EOM Create Temp Tables and populate with fresh data 
  PROCEDURE EOM_CREATE_TEMP_DATA_BIND 
    (
     sAnalysis IN RM.RM_ANAL%TYPE
     ,start_date IN ST.ST_DESP_DATE%TYPE
     ,end_date IN ST.ST_DESP_DATE%TYPE 
     ) 
     AS
    v_out_tx          VARCHAR2(2000);
    v_query           VARCHAR2(2000);
		nCheckpoint       NUMBER;
		p_status          NUMBER := 3;
    p_ST_PSLIP        ST.ST_PSLIP%TYPE := 'CANCELLED'; 
    p_NE_NV_EXT_TYPE  NE.NE_NV_EXT_TYPE%TYPE := 1810105;
    p_NE_STRENGTH     NE.NE_STRENGTH%TYPE := 3;
    p_NI_STATUS       NI.NI_STATUS%TYPE := 0;
    p_NI_AVAIL_ACTUAL NI.NI_AVAIL_ACTUAL%TYPE := 0;
    p_IM_ACTIVE       IM.IM_ACTIVE%TYPE := 1;
    p_RM_TYPE         RM.RM_TYPE%TYPE := 0;
    p_SH_STATUS       SH.SH_STATUS%TYPE := 3;
	BEGIN

	/* Truncate all temp tables*/
		nCheckpoint := 1;
		v_query := 'TRUNCATE TABLE Tmp_Group_Cust';
		EXECUTE IMMEDIATE v_query;	
	
		nCheckpoint := 2;
		v_query := 'TRUNCATE TABLE Tmp_Admin_Data_BreakPrices';
		EXECUTE IMMEDIATE v_query;	
	
		nCheckpoint := 3;
		v_query := 'TRUNCATE TABLE Tmp_Admin_Data_Pickslips';
		EXECUTE IMMEDIATE	v_query;
	
		nCheckpoint := 4;
		v_query := 'TRUNCATE TABLE Tmp_Admin_Data_Pick_LineCounts';
		EXECUTE IMMEDIATE v_query;
	
		nCheckpoint := 5;
		v_query := 'TRUNCATE TABLE Tmp_Batch_Price_SL_Stock';
		EXECUTE IMMEDIATE v_query;
		
		nCheckpoint := 6;
		v_query := 'TRUNCATE TABLE Tmp_Locn_Cnt_By_Cust';
		EXECUTE IMMEDIATE v_query;
		
		nCheckpoint := 7;
		v_query := 'TRUNCATE TABLE tbl_AdminData';
		EXECUTE IMMEDIATE v_query;
		
		nCheckpoint := 8;
		v_query := 'TRUNCATE TABLE Tmp_Log_stats';
		EXECUTE IMMEDIATE v_query;
		
		nCheckpoint := 9;
		v_query := 'TRUNCATE TABLE Tmp_Cust_Reporting';
		EXECUTE IMMEDIATE v_query;
	
		DBMS_OUTPUT.PUT_LINE('Successfully truncated all temporary tables');

	/* Run Group Cust Procedure*/
		nCheckpoint := 10;
		EXECUTE IMMEDIATE 'BEGIN eom_report_pkg.GROUP_CUST_START; END;';
	
		DBMS_OUTPUT.PUT_LINE('Successfully truncated, recreated AND populated Tmp_Group_Cust');

	/*Insert fresh temp data*/
		nCheckpoint := 11;                  
		EXECUTE IMMEDIATE 'INSERT INTO Tmp_Admin_Data_BreakPrices
							SELECT II_STOCK,II_CUST,II_BREAK_LCL
							FROM II INNER JOIN IM ON IM_STOCK = II_STOCK
							AND II_BREAK_LCL > 0.000001';	
										
		nCheckpoint := 12;
    EXECUTE IMMEDIATE q'{INSERT INTO Tmp_Admin_Data_Pickslips
							SELECT LTrim(ST_PICK),LTrim(ST_PSLIP), substr(To_Char(ST_DESP_DATE),0,10), ST_WEIGHT, ST_PACKAGES,ST_XX_NUM_PAL_SW,ST_XX_NUM_PALLETS,ST_XX_NUM_CARTONS
							FROM ST LEFT JOIN SH ON SH_ORDER = ST_ORDER
							WHERE ST_DESP_DATE >= :v_start_date AND ST_DESP_DATE <= :v_end_date	AND ST_PSLIP != 'CANCELLED'
							AND SH_STATUS <> 3}' 
              USING start_date, end_date;
	
		nCheckpoint := 13;
		EXECUTE IMMEDIATE q'{INSERT INTO Tmp_Admin_Data_Pick_LineCounts  
							SELECT MAX(SL_LINE),LTrim(SL_PICK), LTrim(SL_ORDER), LTrim(SL_PSLIP),TP.vDateDesp, TP.vPackages,TP.vWeight,TP.vST_XX_NUM_PAL_SW,TP.vST_XX_NUM_PALLETS,TP.vST_XX_NUM_CARTONS
							FROM Tmp_Admin_Data_Pickslips TP RIGHT JOIN SL ON LTrim(SL_PICK) = TP.vPickslip WHERE SL_EDIT_DATE >= :v_start_date AND SL_EDIT_DATE <= :v_end_date 
							GROUP BY SL_PICK,SL_ORDER,SL_PSLIP,TP.vDateDesp,TP.vPackages,TP.vWeight,TP.vST_XX_NUM_PAL_SW,TP.vST_XX_NUM_PALLETS,TP.vST_XX_NUM_CARTONS}' 	
		USING start_date, end_date;
    
		nCheckpoint := 14;
		v_query := q'{INSERT INTO Tmp_Batch_Price_SL_Stock(vBatchStock,vBatchPickNum,vUnitPrice,vDExcl, vQuantity)
						SELECT nz.NI_STOCK, LTrim(RTrim(nz.NI_SL_PSLIP)), CAST((NX_SELL_VALUE/NX_QUANTITY) AS DECIMAL(22,2)) AS "UnitPrice", CAST(xz.NX_SELL_VALUE AS DECIMAL(22,2)), xz.NX_QUANTITY
						FROM  NX xz INNER JOIN NI nz ON nz.NI_NX_MOVEMENT = xz.NX_MOVEMENT
						INNER JOIN NE ez ON ez.NE_ENTRY = nz.NI_ENTRY AND ez.NE_PRICE_ENTRY = xz.NX_ENTRY
						WHERE ez.NE_NV_EXT_TYPE = :v_p_NE_NV_EXT_TYPE
						AND ez.NE_STRENGTH = :v_p_NE_STRANGTH
						AND xz.NX_SELL_VALUE > 0 AND xz.NX_SELL_VALUE IS NOT NULL
						AND xz.NX_QUANTITY > :v_p_NI_AVAIL_ACTUAL
						AND ez.NE_ADD_DATE >= :v_start_date
						GROUP BY nz.NI_STOCK, nz.NI_SL_PSLIP, xz.NX_SELL_VALUE, xz.NX_QUANTITY}';
		EXECUTE IMMEDIATE v_query USING p_NE_NV_EXT_TYPE, p_NE_STRENGTH, p_NI_AVAIL_ACTUAL, start_date;

		nCheckpoint := 15;
		v_query := q'{INSERT INTO Tmp_Locn_Cnt_By_Cust
						SELECT Count(DISTINCT NI_STOCK) AS CountOfStocks, IL_LOCN, IM_CUST
						FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
						INNER JOIN IM ON IM_STOCK = NI_STOCK
						WHERE IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_ANAL = :sAnalysis AND RM_TYPE = :v_p_RM_TYPE AND RM_ACTIVE = :v_p_IM_ACTIVE )
						AND IM_ACTIVE = :v_p_IM_ACTIVE
						AND NI_AVAIL_ACTUAL >= :v_p_NI_AVAIL_ACTUAL
						AND NI_STATUS <> :v_p_NI_STATUS
						GROUP BY IL_LOCN, IM_CUST}';
		EXECUTE IMMEDIATE v_query USING sAnalysis,p_RM_TYPE,p_IM_ACTIVE,p_IM_ACTIVE,p_NI_AVAIL_ACTUAL,p_NI_STATUS;

		--nCheckpoint := 16;
		--v_query = q'{}';
		--EXECUTE IMMEDIATE v_query; 
	
	
		DBMS_OUTPUT.PUT_LINE('Successfully inserted fresh temporary data');


    RETURN;
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END EOM_CREATE_TEMP_DATA_BIND;
  
  
  PROCEDURE EOM_CREATE_TEMP_LOG_DATA 
        (
        start_date IN SH.SH_ADD_DATE%TYPE
        ,end_date  IN SH.SH_ADD_DATE%TYPE 
        ) 
     AS
    v_out_tx          VARCHAR2(2000);
    v_query           VARCHAR2(8000);
    v_query2          VARCHAR2(8000);
    v_sql_clob        CLOB;
    nCheckpoint       NUMBER;
    p_status          NUMBER                    := 3;
    p_ST_PSLIP        ST.ST_PSLIP%TYPE          := 'CANCELLED'; 
    p_NE_NV_EXT_TYPE  NE.NE_NV_EXT_TYPE%TYPE    := 1810105;
    p_NE_STRENGTH     NE.NE_STRENGTH%TYPE       := 3;
    p_NI_STATUS       NI.NI_STATUS%TYPE         := 0;
    p_NI_AVAIL_ACTUAL NI.NI_AVAIL_ACTUAL%TYPE   := 0;
    p_IM_ACTIVE       IM.IM_ACTIVE%TYPE         := 1;
    p_RM_TYPE         RM.RM_TYPE%TYPE           := 0;
    p_SH_STATUS       SH.SH_STATUS%TYPE         := 3;
    BEGIN

    /* Truncate all temp tables*/
        nCheckpoint := 1;
        v_query := 'TRUNCATE TABLE Tmp_Log_stats';
        EXECUTE IMMEDIATE v_query;    
    
    /* Run Group Cust Procedure*/
		nCheckpoint := 10;
		EXECUTE IMMEDIATE 'BEGIN eom_report_pkg.GROUP_CUST_START; END;';
	
		DBMS_OUTPUT.PUT_LINE('Successfully truncated, recreated AND populated Tmp_Group_Cust');
     COMMIT;
    
    /*Insert fresh temp data*/
        nCheckpoint := 2; 
         v_query := q'{INSERT INTO Tmp_Log_stats (sWarehouse, sCust, nTotal, sType)

                            SELECT  (CASE
                                        WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'S' THEN 'SYDNEY'
                                        WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'H' THEN 'SYDNEY'
                                        WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'R' THEN 'SYDNEY'
                                        WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'M' THEN 'MELBOURNE'
                                        WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'O' THEN 'OBSOLETE'
                                        WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'D' THEN 'DMMETLIFE'
                                        WHEN Upper(d.SD_LOCN) = 'FLOORM' THEN 'MELBOURNE'
                                        WHEN Upper(d.SD_LOCN) = 'FLOORS' THEN 'SYDNEY'
                                        WHEN Upper(d.SD_LOCN) = 'FLOOR' THEN 'FLOOR'
                                        WHEN Upper(d.SD_LOCN) = '0' THEN 'SYDNEY'
                                        ELSE d.SD_LOCN
                                        END) AS Warehouse,
                                        sGroupCust,
                                        Count(DISTINCT(SD_ORDER)) AS Total,
                                        --Count(DISTINCT(SD_ORDER)) AS SDCount,
                                        'A- Orders' AS "Type"--, Count(SD_ORDER) AS SDCount
                            FROM SH h LEFT JOIN Tmp_Group_Cust r ON r.sCust = h.SH_CUST
                                 RIGHT JOIN SD d ON d.SD_ORDER = h.SH_ORDER
                                 INNER JOIN RM r2 ON r2.RM_CUST = h.SH_CUST
                            WHERE h.SH_ADD_DATE >= :sh_start_date AND h.SH_ADD_DATE <= :sh_end_date
                            AND h.SH_STATUS <> 3
                            AND h.SH_CAMPAIGN NOT IN( 'ADMIN','OBSOLETE')
                            --AND d.SD_DISPLAY = 1
                            --AND d.SD_STOCK NOT IN('COURIER','COURIERM','COURIERS')
                            AND r2.RM_ACTIVE = 1   --This was the problem
                            --AND r.sGroupCust = 'TOYFIN'
                            GROUP BY ROLLUP (
                                            ( CASE
                                              WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'S' THEN 'SYDNEY'
                                              WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'H' THEN 'SYDNEY'
                                              WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'R' THEN 'SYDNEY'
                                              WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'M' THEN 'MELBOURNE'
                                              WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'O' THEN 'OBSOLETE'
                                              WHEN Upper(SubStr(d.SD_LOCN,0,1)) = 'D' THEN 'DMMETLIFE'
                                              WHEN Upper(d.SD_LOCN) = 'FLOORM' THEN 'MELBOURNE'
                                              WHEN Upper(d.SD_LOCN) = 'FLOORS' THEN 'SYDNEY'
                                              WHEN Upper(d.SD_LOCN) = 'FLOOR' THEN 'FLOOR'
                                              WHEN Upper(d.SD_LOCN) = '0' THEN 'SYDNEY'
                                              ELSE d.SD_LOCN
                                              END
                                            ),
                                            sGroupCust  )
                                                          
                            }'; 
                         EXECUTE IMMEDIATE v_query USING start_date,end_date;                 
                        DBMS_OUTPUT.PUT_LINE('Successfully inserted fresh temporary data');
                        COMMIT;
                  
                         nCheckpoint := 3; 
                          v_query := q'{INSERT INTO Tmp_Log_stats (sWarehouse, sCust, nTotal, sType)
                            /*Total Despatches by Month all custs grouped by warehouse/grouped cust */  

                            SELECT (
                                      CASE
                                        WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'S' THEN 'SYDNEY'
                                        WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'H' THEN 'SYDNEY'
                                        WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'R' THEN 'SYDNEY'
                                        WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'M' THEN 'MELBOURNE'
                                        WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'O' THEN 'OBSOLETE'
                                        WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'D' THEN 'DMMETLIFE'
                                        WHEN Upper(s.SL_LOCN) = 'FLOORM' THEN 'MELBOURNE'
                                        WHEN Upper(s.SL_LOCN) = 'FLOORS' THEN 'SYDNEY'
                                        WHEN Upper(s.SL_LOCN) = 'FLOOR' THEN 'FLOOR'
                                        WHEN Upper(s.SL_LOCN) = '0' THEN 'SYDNEY'
                                        ELSE s.SL_LOCN
                                        END) AS Warehouse,
                                         sGroupCust,
                                        Count(*) AS Total,
                                        'B- Despatches' AS "Type"
                                       --t.ST_PICK,
                                       --h.SH_CAMPAIGN
                            FROM  PWIN175.ST t INNER JOIN SL s ON s.SL_PICK = t.ST_PICK
                                  INNER JOIN SH h ON h.SH_ORDER = t.ST_ORDER--RIGHT JOIN SD d ON d.SD_ORDER = h.SH_ORDER
                                  LEFT JOIN Tmp_Group_Cust r ON r.sCust = h.SH_CUST
                                  INNER JOIN RM r2 ON r2.RM_CUST = h.SH_CUST
                                  --RIGHT JOIN SL s ON s.SL_PICK = t.ST_PICK

                            WHERE t.ST_DESP_DATE >= :st_start_date AND t.ST_DESP_DATE <= :st_end_date
                            AND s.SL_LINE = 1
                            AND t.ST_PSLIP IS NOT NULL AND t.ST_PSLIP <> 'CANCELLED'
                            AND h.SH_STATUS <> 3
                            AND h.SH_CAMPAIGN NOT IN( 'ADMIN','OBSOLETE')
                            AND r2.RM_ACTIVE = 1   --This was the problem
                            GROUP BY ROLLUP ((CASE
                                        WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'S' THEN 'SYDNEY'
                                        WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'H' THEN 'SYDNEY'
                                        WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'R' THEN 'SYDNEY'
                                        WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'M' THEN 'MELBOURNE'
                                        WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'O' THEN 'OBSOLETE'
                                        WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'D' THEN 'DMMETLIFE'
                                        WHEN Upper(s.SL_LOCN) = 'FLOORM' THEN 'MELBOURNE'
                                        WHEN Upper(s.SL_LOCN) = 'FLOORS' THEN 'SYDNEY'
                                        WHEN Upper(s.SL_LOCN) = 'FLOOR' THEN 'FLOOR'
                                        WHEN Upper(s.SL_LOCN) = '0' THEN 'SYDNEY'
                                        ELSE s.SL_LOCN
                                        END),
                                         sGroupCust )



                           }'; 
           EXECUTE IMMEDIATE v_query USING start_date,end_date;                 
          DBMS_OUTPUT.PUT_LINE('Successfully inserted fresh temporary data');
          COMMIT;
          
          
          nCheckpoint := 4; 
          v_query := q'{INSERT INTO Tmp_Log_stats (sWarehouse, sCust, nTotal, sType)
                         SELECT   CASE
                                        WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'S' THEN 'SYDNEY'
                                        WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'H' THEN 'SYDNEY'
                                        WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'R' THEN 'SYDNEY'
                                        WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'M' THEN 'MELBOURNE'
                                        WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'O' THEN 'OBSOLETE'
                                        WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'D' THEN 'DMMETLIFE'
                                        WHEN Upper(s.SL_LOCN) = 'FLOORM' THEN 'MELBOURNE'
                                        WHEN Upper(s.SL_LOCN) = 'FLOORS' THEN 'SYDNEY'
                                        WHEN Upper(s.SL_LOCN) = 'FLOOR' THEN 'FLOOR'
                                        WHEN Upper(s.SL_LOCN) = '0' THEN 'SYDNEY'
                                        ELSE s.SL_LOCN
                                        END AS Warehouse,
                                        sGroupCust AS Customer,
                                        Count(*) AS Total,
                                        'C- Lines' AS "Type"
                            FROM  PWIN175.SL s INNER JOIN SH h ON s.SL_ORDER = h.SH_ORDER
                                  LEFT JOIN Tmp_Group_Cust r ON r.sCust = h.SH_CUST
                                  --RIGHT JOIN SD d ON d.SD_ORDER = h.SH_ORDER
                                  INNER JOIN RM r2 ON r2.RM_CUST = h.SH_CUST
                                  --INNER JOIN IL l ON l.IL_LOCN = s.SL_LOCN
                                  INNER JOIN ST t ON t.ST_PICK = s.SL_PICK
                            WHERE s.SL_EDIT_DATE >= :sl_start_date AND s.SL_EDIT_DATE <= :sl_end_date
                            AND s.SL_PSLIP IS NOT NULL
                            AND h.SH_CAMPAIGN NOT IN( 'ADMIN','OBSOLETE')
                            AND r2.RM_ACTIVE = 1   --This was the problem
                            GROUP BY  (CASE
                                        WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'S' THEN 'SYDNEY'
                                        WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'H' THEN 'SYDNEY'
                                        WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'R' THEN 'SYDNEY'
                                        WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'M' THEN 'MELBOURNE'
                                        WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'O' THEN 'OBSOLETE'
                                        WHEN Upper(SubStr(s.SL_LOCN,0,1)) = 'D' THEN 'DMMETLIFE'
                                        WHEN Upper(s.SL_LOCN) = 'FLOORM' THEN 'MELBOURNE'
                                        WHEN Upper(s.SL_LOCN) = 'FLOORS' THEN 'SYDNEY'
                                        WHEN Upper(s.SL_LOCN) = 'FLOOR' THEN 'FLOOR'
                                        WHEN Upper(s.SL_LOCN) = '0' THEN 'SYDNEY'
                                        ELSE s.SL_LOCN
                                        END ,
                                      sGroupCust)


                         }'; 
           EXECUTE IMMEDIATE v_query USING start_date,end_date;                 
          DBMS_OUTPUT.PUT_LINE('Successfully inserted fresh temporary data');
          COMMIT;

         nCheckpoint := 5; 
          v_query := q'{INSERT INTO Tmp_Log_stats (sWarehouse, sCust, nTotal, sType)
                       
                            /*This should list Total receipts by type grouped by warehouse for all customers */ --1.1s   Total is 2643
                            SELECT (CASE
                                    WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
                                    WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
                                    END) AS Warehouse,

                                    i.IM_CUST AS Cust,
                                   Count(NE_ENTRY) AS Total,
                                   'D- Receipts'  AS "Type"
                            FROM  NA n INNER JOIN IL l ON l.IL_UID = n.NA_EXT_KEY
                                       INNER JOIN NE e ON e.NE_ACCOUNT = n.NA_ACCOUNT
                                       INNER JOIN IM i ON i.IM_STOCK = n.NA_STOCK
                            WHERE n.NA_EXT_TYPE = 1210067
                            AND   l.IL_IN_LOCN NOT IN ('OBSOLETEMEL','OBSOLETESYD','PASTHISTORY', 'CANBERRA')
                            AND   IL_PHYSICAL = 1
                            AND   e.NE_QUANTITY >= '1'
                            AND   e.NE_TRAN_TYPE =  1
                            AND   e.NE_STRENGTH = 3
                            AND   (e.NE_STATUS = 1 OR e.NE_STATUS = 3)
                            AND   e.NE_DATE >= :ne_start_date AND e.NE_DATE <= :ne_end_date
                            --AND IM_CUST = 'CROWN'
                            GROUP BY ((CASE
                                    WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
                                    WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
                                    END)
                            ,i.IM_CUST)
                            --ORDER BY 1


                       }'; 
           EXECUTE IMMEDIATE v_query USING start_date,end_date;                 
          DBMS_OUTPUT.PUT_LINE('Successfully inserted fresh temporary data');
          COMMIT;
          
          nCheckpoint := 6; 
          v_query := q'{INSERT INTO Tmp_Log_stats (sWarehouse, sCust, nTotal, sType)           
            /*This should list Total spaces by type grouped by warehouse for all customers */ --13.00s Total is 15131
                            SELECT
                                   (CASE
                                    WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
                                    WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
                                    END) AS Warehouse,
                                   i.IM_CUST AS Cust,
                                   Count(DISTINCT l.IL_LOCN) AS Total,  -- test a self join to rid the distinct
                                   (CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                                                                                    ELSE 'F- Shelves'
                                    END) AS "Type"
                            FROM  NA n INNER JOIN IL l ON l.IL_UID = n.NA_EXT_KEY
                                       INNER JOIN NE e ON e.NE_ACCOUNT = n.NA_ACCOUNT
                                       INNER JOIN IM i ON i.IM_STOCK = n.NA_STOCK
                                       --LEFT JOIN Tmp_Group_Cust r ON r.sGroupCust = i.IM_CUST
                            WHERE n.NA_EXT_TYPE = 1210067
                            AND e.NE_AVAIL_ACTUAL >= '1'
                            AND l.IL_IN_LOCN NOT IN ('OBSOLETEMEL','OBSOLETESYD','PASTHISTORY', 'CANBERRA')
                            AND e.NE_STATUS =  1
                            AND e.NE_STRENGTH = 3
                            --AND i.IM_CUST = :cust
                            GROUP BY  ((CASE
                                              WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
                                              WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
                                              END),i.IM_CUST, (CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                                                                                              ELSE 'F- Shelves'
                                              END) )
                            ORDER BY 1,2,4
                            }';
                           
        EXECUTE IMMEDIATE v_query;
        DBMS_OUTPUT.PUT_LINE('Successfully inserted fresh temporary data');

    COMMIT;
    RETURN;

  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END EOM_CREATE_TEMP_LOG_DATA;

  
END EOM_REPORT_PKG;
/