PROCEDURE EOM_CREATE
    (
     start_date IN ST.ST_DESP_DATE%TYPE
     ,end_date IN ST.ST_DESP_DATE%TYPE
     ,sCust IN OUT RM.RM_CUST%TYPE
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
    p_NI_AVAIL_ACTUAL NI.NI_AVAIL_ACTUAL%TYPE := 1;
    p_IM_ACTIVE       IM.IM_ACTIVE%TYPE := 1;
    p_RM_TYPE         RM.RM_TYPE%TYPE := 0;
    p_SH_STATUS       SH.SH_STATUS%TYPE := 3;
    nCountCustStocks NUMBER;/*VerbalOrderEntryFee*/
    nRM_XX_FEE01 NUMBER; /*VerbalOrderEntryFee*/
    nRM_XX_FEE02 NUMBER; /*EmailOrderEntryFee*/
    nRM_XX_FEE03 NUMBER; /*PhoneOrderEntryFee*/
    nRM_XX_FEE04 NUMBER; /*PhoneOrderEntryFee*/
    nRM_XX_FEE05 NUMBER; /*PhoneOrderEntryFee*/
    nRM_XX_FEE06 NUMBER; /*Handeling Fee*/
    nRM_XX_FEE07 NUMBER; /*FaxOrderEntryFee*/
    nRM_XX_FEE08 NUMBER; /*InnerPackingFee*/
    nRM_XX_FEE09 NUMBER; /*OuterPackingFee*/
    nRM_XX_FEE10 NUMBER; /*FTPOrderEntryFee*/
    nRM_XX_FEE11 NUMBER; /*Pallet Storage Fee*/
    nRM_XX_FEE12 NUMBER; /*Shelf Storage Fee*/
    nRM_XX_FEE13 NUMBER; /*Carton In Fee*/
    nRM_XX_FEE14 NUMBER; /*Pallet In Fee*/
    nRM_XX_FEE15 NUMBER; /*Carton Despatch Fee*/
    nRM_XX_FEE16 NUMBER; /*Pick Fee*/
    nRM_XX_FEE17 NUMBER; /*Pallet Despatch Fee*/
    nRM_XX_FEE18 NUMBER; /*ShrinkWrap Fee*/
    nRM_XX_FEE19 NUMBER; /*Admin Fee*/
    nRM_XX_FEE20 NUMBER; /*Stock Maintenance Fee*/
    nRM_XX_FEE21 NUMBER; /*DB Maintenance Fee*/
    nRM_XX_FEE22 NUMBER; /*Bin Monthly Storage Fee*/
    nRM_XX_FEE23 NUMBER; /*Daily Delivery Fee*/
    nRM_XX_FEE24 NUMBER; /*Carton Destruction Fee*/
    nRM_XX_FEE25 NUMBER; /*Pallet Destruction Fee*/
    nRM_XX_FEE26 NUMBER; /*Additional Pallet Destruction Fee*/
    nRM_XX_FEE27 NUMBER; /*Order Fee*/
    nRM_XX_FEE28 NUMBER; /*Pallet Secured Storage Fee*/
    nRM_XX_FEE29 NUMBER; /*Pallet Slow Moving Secured Fee*/
    nRM_XX_FEE30 NUMBER; /*Shelf Slow Moving Fee*/
    nRM_XX_FEE31 NUMBER; /*Secured Shelf Storage Fee*/
    nRM_XX_FEE32 NUMBER; /*Pallet Archive Monthly Fee*/
    nRM_XX_FEE33 NUMBER; /*Shelf Archive Monthly Fee*/
    nRM_XX_FEE34 NUMBER; /*Manual Report Run Fee*/
    nRM_XX_FEE35 NUMBER; /*Kitting Fee P/H*/
    nRM_XX_FEE36 NUMBER; /*Pick Fee 2nd Scale*/
    nRM_SPARE_CHAR_3 NUMBER; /*Pallet Slow Moving Fee*/
    nRM_SPARE_CHAR_5 NUMBER; /*System Maintenance Fee*/
    nRM_SPARE_CHAR_4 NUMBER; /*Stocktake Fee P/H*/
    nRM_XX_ADMIN_CHG NUMBER; /*Shelf Slow Moving Secured Fee*/
    nRM_XX_PALLET_CHG NUMBER; /*Return Per Pallet Fee*/
    nRM_XX_SHELF_CHG NUMBER; /*Return Per Shelf Fee*/
    nRM_XX_FEE31_1 NUMBER; /*Minimun Monthly Charge Fee*/
    nRM_XX_FEE32_1 NUMBER; /*UnallocatedFee*/
    nRM_XX_FEE33_1 NUMBER; /*UnallocatedFee*/
    nRM_XX_FEE34_1 NUMBER; /*UnallocatedFee*/
    nRM_XX_FEE35_1 NUMBER; /*UnallocatedFee*/
    nRM_XX_FEE36_1 NUMBER; /*UnallocatedFee*/
  BEGIN
    nCheckpoint := 1;
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
		--v_query := 'TRUNCATE TABLE Tmp_Cust_Reporting';
		--EXECUTE IMMEDIATE v_query;
	
		DBMS_OUTPUT.PUT_LINE('Successfully truncated all temporary tables');

	/* Run Group Cust Procedure*/
		nCheckpoint := 10;
		--EXECUTE IMMEDIATE 'BEGIN eom_report_pkg.GROUP_CUST_START; END;';
	
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
						SELECT Count(DISTINCT NI_STOCK) AS CountOfStocks, IL_LOCN, IM_CUST, 
                      CASE WHEN Upper(substr(IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                        ELSE 'F- Shelves'
                        END AS "Note"
						FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
						INNER JOIN IM ON IM_STOCK = NI_STOCK
						WHERE IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_TYPE = :v_p_RM_TYPE AND RM_ACTIVE = :v_p_IM_ACTIVE )
						AND IM_ACTIVE = :v_p_IM_ACTIVE
						AND NI_AVAIL_ACTUAL >= :v_p_NI_AVAIL_ACTUAL
						AND NI_STATUS <> :v_p_NI_STATUS
						GROUP BY IL_LOCN, IM_CUST,IL_NOTE_2}';
		EXECUTE IMMEDIATE v_query USING p_RM_TYPE,p_IM_ACTIVE,p_IM_ACTIVE,p_NI_AVAIL_ACTUAL,p_NI_STATUS;
		
		DBMS_OUTPUT.PUT_LINE('Successfully inserted fresh temporary data');
    
    nCheckpoint := 16;
    INSERT into tbl_AdminData(
				  Customer,
				  Parent,
				  CostCentre,
				  OrderNum,
				  OrderwareNum,
				  CustRef,
				  Pickslip,
				  PickNum,
				  DespatchNote,
				  DespatchDate,
				  FeeType,
				  Item,
				  Description,
				  Qty,
				  UOI,
				  UnitPrice,
				  OW_Unit_Sell_Price,
				  Sell_Excl,
				  Sell_Excl_Total,
				  Sell_Incl,
				  Sell_Incl_Total,
				  ReportingPrice,
				  Address,
				  Address2,
				  Suburb,
				  State,
				  Postcode,
				  DeliverTo,
				  AttentionTo,
				  Weight,
				  Packages,
				  OrderSource,
				  ILNOTE2,
				  NILOCN,
				  CountOfStocks,
          Email,
          Brand,
          OwnedBy,
          sProfile,
          WaiveFee,
          Cost,
          PaymentType


				  )
  /*insert into temp admin data table*/

  /*freight fees*/             --8 secs
	  select    s.SH_CUST           AS "Customer",
			    r.RM_PARENT              AS "Parent",
			    s.SH_SPARE_STR_4         AS "CostCentre",
			    s.SH_ORDER               AS "Order",
			    s.SH_SPARE_STR_5         AS "OrderwareNum",
			    s.SH_CUST_REF            AS "CustomerRef",
			    d.SD_XX_PICKLIST_NUM     AS "Pickslip",
			    d.SD_XX_PICKLIST_NUM         AS "PickNum",
			    d.SD_XX_PSLIP_NUM               AS "DespatchNote",
			    substr(To_Char(d.SD_ADD_DATE),0,10)            AS "DespatchDate",
	        CASE  WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 THEN 'Freight Fee'
                WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE < 1 THEN 'Unpriced Freight'
			          ELSE To_Char(d.SD_DESC)
			          END                      AS "FeeType",
			    d.SD_STOCK               AS "Item",
			    '="' || To_Char(d.SD_DESC) || '"'               AS "Description",
	        CASE  WHEN d.SD_LINE IS NOT NULL THEN  1
			          ELSE NULL
			          END                     AS "Qty",
	        CASE  WHEN d.SD_LINE IS NOT NULL THEN  '1'
			          ELSE NULL
			          END                      AS "UOI",

          CASE  WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT <> 'BORBUI' AND r.RM_PARENT <> 'BEYONDBLUE') THEN d.SD_SELL_PRICE
			          WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT = 'BORBUI' OR r.RM_PARENT = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.125) And (t.ST_SPARE_DBL_1 > 0.00) THEN 1.70
                WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT = 'BORBUI' OR r.RM_PARENT = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.250) And (t.ST_SPARE_DBL_1 > 0.126) THEN 2.30
                WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT = 'BORBUI' OR r.RM_PARENT = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.500) And (t.ST_SPARE_DBL_1 > 0.251) THEN 3.40
                WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT = 'BORBUI' OR r.RM_PARENT = 'BEYONDBLUE') AND (t.ST_WEIGHT > 0.01) THEN d.SD_SELL_PRICE
                ELSE NULL
			          END                AS "UnitPrice",
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
			    NULL AS "Pallet/Shelf Space", /*Pallet/Space*/
				  NULL AS "Locn", /*Locn*/
				  0 AS "CountOfStocks",
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			          ELSE ''
			          END AS Email,
                'N/A' AS Brand,
           NULL AS    OwnedBy,
           NULL AS    sProfile,
           NULL AS    WaiveFee,
           d.SD_COST_PRICE As   Cost,
           NULL AS PaymentType

	  FROM      PWIN175.SD d
			    INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			    INNER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_PICK))  = LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM))
			    INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
	  WHERE     s.SH_ORDER = d.SD_ORDER
	  AND       r.RM_ANAL = :sAnalysis
	  	AND       d.SD_STOCK IN ('COURIERM','COURIERS','COURIER')
	AND       s.SH_ORDER = t.ST_ORDER
	AND       d.SD_SELL_PRICE >= 0.1
	AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
  AND   d.SD_ADD_OP LIKE 'SERV%'


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
          d.SD_COST_PRICE




	  UNION ALL

  /*freight fees*/



  /*Manual freight fees*/
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
	        CASE  WHEN d.SD_STOCK IN ('COURIERM','COURIERS','COURIER','DETENTIONTIMEM','DETENTIONTIMES','FREIGHTDUTY') AND d.SD_SELL_PRICE >= 1  THEN 'Manual Freight Fee'
			          WHEN d.SD_STOCK IN ('COURIERM','COURIERS','COURIER','DETENTIONTIMEM','DETENTIONTIMES','FREIGHTDUTY') AND d.SD_SELL_PRICE < 1 THEN 'Unpriced Freight'
			          ELSE NULL
			          END                      AS "FeeType",
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
			    NULL AS "Pallet/Shelf Space", /*Pallet/Space*/
				  NULL AS "Locn", /*Locn*/
				  0 AS "CountOfStocks",
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			          ELSE ''
			          END AS Email,
                'N/A' AS Brand,
           NULL AS    OwnedBy,
           NULL AS    sProfile,
           NULL AS    WaiveFee,
           d.SD_COST_PRICE As   Cost,
           NULL AS PaymentType


           FROM      PWIN175.SD d
			    INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			          INNER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_PICK))  = LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM))
			          INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
	        WHERE     s.SH_ORDER = d.SD_ORDER
	  AND       r.RM_ANAL = :sAnalysis
    --	AND       (r.RM_PARENT = :cust OR r.RM_CUST = :cust)
	  AND       d.SD_STOCK IN ('COURIERM','COURIERS','COURIER','DETENTIONTIMEM','DETENTIONTIMES','FREIGHTDUTY')
	  AND       s.SH_ORDER = t.ST_ORDER
	  	AND       d.SD_SELL_PRICE >= 0.1
  --AND d.SD_ADD_DATE = '2-MAY-2014' AND d.SD_ADD_OP = 'PRJ'
	AND       d.SD_ADD_DATE >= :start_date AND d.SD_ADD_DATE <= :end_date
  AND   d.SD_ADD_OP NOT LIKE 'SERV%'

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
			    s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,d.SD_COST_PRICE;
 RETURN;
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
EOM_CREATE;


FUNCTION EOMFee
                    ( 
                    rm_cust_in IN RM.RM_CUST%TYPE,
                    nFEE_FIELD NUMBER
                    )
    RETURN NUMBER
    AS
        nFEE NUMBER;
    BEGIN
      IF rm_cust_in IS NOT NULL THEN
         SELECT   To_Number(regexp_substr(nFEE_FIELD,'^[-]?[[:digit:]]*\.?[[:digit:]]*$'))
          INTO nFEE
             FROM RM where RM_CUST = rm_cust_in;
          RETURN nFEE;
          DBMS_OUTPUT.PUT_LINE(nFEE);
      ELSE
        RETURN NULL;
      END IF;
    END EOMFee; 
    
  
  
  
   PROCEDURE set_admin_eom_vars
      (
      sCust                         IN OUT RM.RM_CUST%TYPE
    /*  ,sCustExclude                 IN  RM.RM_CUST%TYPE := NULL --Use this to exclude Parent when running split cost centres
                                                                -- For example when running AAS Non FUND - this would be set to AAS
                                                                -- and the cust would be AAS NON FUND
      ,sCustCostCenter              IN  RM.RM_CUST%TYPE := NULL
      ,sStockCostCenter             IN  IM.IM_CUST%TYPE := NULL
      ,sAnalysis                    IN  RM.RM_ANAL%TYPE --declare based on sCust/sCostCenter
      ,sSource                      IN  RM.RM_SOURCE%TYPE := NULL
      ,start_date                   IN  ST.ST_DESP_DATE%TYPE  := TRUNC(TO_DATE(SYSDATE), 'MM')
      ,end_date                     IN  ST.ST_DESP_DATE%TYPE  := SYSDATE*/
       
      )
    AS
    nCheckpoint           NUMBER; 
    v_query               VARCHAR2(1000);  
    cust_name             VARCHAR(50);
    TYPE cust_cur_typ IS REF CURSOR;
    cur_cust   cust_cur_typ;
  BEGIN
   -- v_query := 'SELECT RM_CUST FROM RM WHERE RM_CUST = sCust';
    OPEN cur_cust FOR SELECT RM_CUST FROM RM WHERE RM_CUST = sCust;
      LOOP 
        FETCH cur_cust INTO cust_name;
        EXIT WHEN cur_cust%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(cust_name);
      END LOOP;
      CLOSE cur_cust;
  END set_admin_eom_vars;
  
  
  FUNCTION NDS_EOM_QRY
     (nds_select_col_name_1 IN VARCHAR2,
      nds_select_col_name_2 IN VARCHAR2,
      nds_tbl_1 IN VARCHAR2, 
      nds_where_col_name_1 IN VARCHAR2,
      nds_where_col_val_1 IN VARCHAR2
      )
  RETURN VARCHAR2
  IS
     /* Declare and obtain a pointer to a cursor */
     cur INTEGER := DBMS_SQL.OPEN_CURSOR;
  
     /* Variable to receive feedback from package functions */
     fdbk INTEGER;
     /*
     || The return value of the function. Notice that I have
     || to hardcode a size in my declaration.
     */
     return_value VARCHAR2(1000) := NULL;
  BEGIN
     /* 
     || Parse the query. I construct most of the SQL statement from
     || the parameters with concatenation. I also include a single
     || bind variable for the actual foreign key value.
     */
     DBMS_SQL.PARSE 
        (cur, 
         'SELECT ' || nds_select_col_name_1 || nds_select_col_name_2 || 
         '  FROM ' || nds_tbl_1 ||
         ' WHERE ' || nds_where_col_name_1 || ' = :fk_value',
         DBMS_SQL.NATIVE);
  
     /* Bind the variable with a specific value -- the parameter */
     DBMS_SQL.BIND_VARIABLE (cur, 'fk_value', nds_where_col_val_1);
     --DBMS_SQL.BIND_VARIABLE (cur, 'fk_value', nds_where_col_val_1);
     /* Define the column in the cursor for the FK name */
     DBMS_SQL.DEFINE_COLUMN (cur, 1, nds_select_col_name_1, 100);
     DBMS_SQL.DEFINE_COLUMN (cur, 2, nds_select_col_name_2, 100);
     /* Execute the cursor, ignoring the feedback */
     fdbk := DBMS_SQL.EXECUTE (cur);
  
     /* Fetch the row. If feedback is 0, no match found */
     fdbk := DBMS_SQL.FETCH_ROWS (cur);
     IF fdbk > 0
     THEN
        /* Found a match. Extract the value/name for the key */
        DBMS_SQL.COLUMN_VALUE (cur, 1, return_value);
        DBMS_SQL.COLUMN_VALUE (cur, 2, return_value);
     END IF;
     /*
     || Close the cursor and return the description, which 
     || could be NULL if no records were fetched.
     */
     DBMS_SQL.CLOSE_CURSOR (cur);
     RETURN return_value;
  END NDS_EOM_QRY;

  
      
   PROCEDURE DynamicPLSQL (
      p_ID IN VARCHAR2) IS
  
      v_CursorID  INTEGER;
      v_BlockStr  VARCHAR2(500);
      myFirstName VARCHAR2(500);
      v_LastName  VARCHAR2(500);
      v_Dummy     INTEGER;
  
   BEGIN
     v_CursorID := DBMS_SQL.OPEN_CURSOR;
 
     v_BlockStr :=
       'BEGIN
          SELECT first_name, last_name
            INTO :first_name, :last_name
            FROM RM
            WHERE ID = :ID;
        END;';
 
     DBMS_SQL.PARSE(v_CursorID, v_BlockStr, DBMS_SQL.V7);
 
     DBMS_SQL.BIND_VARIABLE(v_CursorID, ':first_name', myFirstName, 30);
     DBMS_SQL.BIND_VARIABLE(v_CursorID, ':last_name', v_LastName, 30);
     DBMS_SQL.BIND_VARIABLE(v_CursorID, ':ID', p_ID);
 
     v_Dummy := DBMS_SQL.EXECUTE(v_CursorID);
 
     DBMS_SQL.VARIABLE_VALUE(v_CursorID, ':first_name', myFirstName);
     DBMS_SQL.VARIABLE_VALUE(v_CursorID, ':last_name', v_LastName);
 
     --INSERT INTO MyTable (num_col, char_col)
     --  VALUES (p_ID, myFirstName || ' ' || v_LastName);
 
     DBMS_SQL.CLOSE_CURSOR(v_CursorID);
 
     COMMIT;
   EXCEPTION
     WHEN OTHERS THEN
       DBMS_SQL.CLOSE_CURSOR(v_CursorID);
       RAISE;
   END DynamicPLSQL;
   
   
   
     --EOM Create Temp Tables and populate with fresh data 
  PROCEDURE EOM_CREATE_TEMP_DATA_BIND_NEW 
    (
     start_date IN ST.ST_DESP_DATE%TYPE
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
    p_NI_AVAIL_ACTUAL NI.NI_AVAIL_ACTUAL%TYPE := 1;
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
		--v_query := 'TRUNCATE TABLE Tmp_Cust_Reporting';
		--EXECUTE IMMEDIATE v_query;
	
		DBMS_OUTPUT.PUT_LINE('Successfully truncated all temporary tables');

	/* Run Group Cust Procedure*/
		nCheckpoint := 10;
		--EXECUTE IMMEDIATE 'BEGIN eom_report_pkg.GROUP_CUST_START; END;';
	
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
						SELECT Count(DISTINCT NI_STOCK) AS CountOfStocks, IL_LOCN, IM_CUST, 
                      CASE WHEN Upper(substr(IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                        ELSE 'F- Shelves'
                        END AS "Note"
						FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
						INNER JOIN IM ON IM_STOCK = NI_STOCK
						WHERE IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_TYPE = :v_p_RM_TYPE AND RM_ACTIVE = :v_p_IM_ACTIVE )
						AND IM_ACTIVE = :v_p_IM_ACTIVE
						AND NI_AVAIL_ACTUAL >= :v_p_NI_AVAIL_ACTUAL
						AND NI_STATUS <> :v_p_NI_STATUS
						GROUP BY IL_LOCN, IM_CUST,IL_NOTE_2}';
		EXECUTE IMMEDIATE v_query USING p_RM_TYPE,p_IM_ACTIVE,p_IM_ACTIVE,p_NI_AVAIL_ACTUAL,p_NI_STATUS;
		
		DBMS_OUTPUT.PUT_LINE('Successfully inserted fresh temporary data');


    RETURN;
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END EOM_CREATE_TEMP_DATA_BIND_NEW;
  
DBMS_OUTPUT.ENABLE(500000);


TRUNCATE TABLE Tmp_Locn_Cnt_By_Cust

SELECT OD_DOC_NUM, OD_STOCK
FROM pwin175.OD
WHERE OD_DOC_NUM = '3476'