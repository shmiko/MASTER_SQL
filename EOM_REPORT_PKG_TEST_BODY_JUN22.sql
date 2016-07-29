--------------------------------------------------------
--  File created - Wednesday-July-22-2015   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package Body EOM_REPORT_PKG_TEST
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PWIN175"."EOM_REPORT_PKG_TEST" 
AS
  /*   Group all customer down 3 tiers - this makes getting all children and grandchildren simples   */
  /*   Temp Tables Used   */
  /*   1. Tmp_Group_Cust   */
  /*   Runs in about 5 seconds   */
  /*   Tested and Working 17/7/15   */
  PROCEDURE A_EOM_GROUP_CUST AS
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
  END A_EOM_GROUP_CUST;
  
  /*   Run this once for all customer data   */
  /*   This gets Break Prices, Pickslip Data, Pick Line Data, Batch Prices   */
  /*   Temp Tables Used   */
  /*   1. Tmp_Admin_Data_BreakPrices   */
  /*   2. Tmp_Admin_Data_Pickslips   */
  /*   3. Tmp_Admin_Data_Pick_LineCounts   */
  /*   4. Tmp_Batch_Price_SL_Stock   */
  /*   Runs in about 240 seconds    */
  /*   Tested and Working 17/7/15   */
  PROCEDURE B_EOM_START_RUN_ONCE_DATA
    (
     start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
     ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
     ,sAnalysis IN RM.RM_ANAL%TYPE
     ,sCust IN RM.RM_CUST%TYPE := 'VHAAUS'
     ,PreData IN RM.RM_ACTIVE%TYPE := 0
     --,gdf_desp_freight_cur OUT sys_refcursor
     ) 
  AS
    --v_out_tx          VARCHAR2(32767);
    --v_query3           VARCHAR2(32767);
		--v_query2          VARCHAR2(32767);
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
							WHERE TO_CHAR(ST_DESP_DATE,'YYYY-MM-DD') >= F_FIRST_DAY_PREV_MONTH AND TO_CHAR(ST_DESP_DATE,'YYYY-MM-DD') <= F_LAST_DAY_PREV_MONTH	AND ST_PSLIP != 'CANCELLED'
							AND SH_STATUS <> 3}';
	
		nCheckpoint := 13;
		EXECUTE IMMEDIATE q'{INSERT INTO Tmp_Admin_Data_Pick_LineCounts  
							SELECT MAX(SL_LINE),LTrim(SL_PICK), LTrim(SL_ORDER), LTrim(SL_PSLIP),TP.vDateDesp, TP.vPackages,TP.vWeight,TP.vST_XX_NUM_PAL_SW,TP.vST_XX_NUM_PALLETS,TP.vST_XX_NUM_CARTONS
							FROM Tmp_Admin_Data_Pickslips TP RIGHT JOIN SL ON LTrim(SL_PICK) = TP.vPickslip WHERE TO_CHAR(SL_EDIT_DATE,'YYYY-MM-DD') >= F_FIRST_DAY_PREV_MONTH AND TO_CHAR(SL_EDIT_DATE,'YYYY-MM-DD') <= F_LAST_DAY_PREV_MONTH AND SL_PSLIP != 'CANCELLED' 
							GROUP BY SL_PICK,SL_ORDER,SL_PSLIP,TP.vDateDesp,TP.vPackages,TP.vWeight,TP.vST_XX_NUM_PAL_SW,TP.vST_XX_NUM_PALLETS,TP.vST_XX_NUM_CARTONS}';
    
		/*nCheckpoint := 14;
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
		EXECUTE IMMEDIATE v_query USING p_NE_NV_EXT_TYPE, p_NE_STRENGTH, p_NI_AVAIL_ACTUAL, start_date;*/
    
   
		
		DBMS_OUTPUT.PUT_LINE('Successfully inserted fresh temporary data');
	 
 RETURN;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE; 
END B_EOM_START_RUN_ONCE_DATA;   


  /*   Run this once for each customer   */
  /*   This gets all the storage data   */
  /*   Temp Tables Used   */
  /*   1. Tmp_Locn_Cnt_By_Cust   */
  /*   2. tbl_AdminData   */
  /*   Runs in about 20 seconds    */
  /*   Tested and Working 17/7/15   */
  PROCEDURE C_EOM_START_CUST_TEMP_DATA
    (
     --start_date IN ST.ST_DESP_DATE%TYPE := '2015-04-06'
     --,end_date IN ST.ST_DESP_DATE%TYPE := '2015-04-13'
     sAnalysis IN RM.RM_ANAL%TYPE
     --,
     ,sCust IN RM.RM_CUST%TYPE := 'VHAAUS'
     --,PreData IN RM.RM_ACTIVE%TYPE := 0
     --,gdf_desp_freight_cur OUT sys_refcursor
     ) 
  AS
    --v_out_tx          VARCHAR2(32767);
    --v_query3           VARCHAR2(32767);
		--v_query2          VARCHAR2(32767);
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
		
		
		nCheckpoint := 6;
		v_query := 'TRUNCATE TABLE Tmp_Locn_Cnt_By_Cust';
		EXECUTE IMMEDIATE v_query;
		
		nCheckpoint := 7;
		v_query := 'TRUNCATE TABLE tbl_AdminData';
		EXECUTE IMMEDIATE v_query;
		
		
		DBMS_OUTPUT.PUT_LINE('Successfully truncated all temporary tables');

	

	/*Insert fresh temp data*/

   nCheckpoint := 15;
   If (sAnalysis IS NOT NULL) Then
    EOM_REPORT_PKG_TEST.EOM_CREATE_TEMP_DATA_LOCATIONS(sAnalysis);
     /* v_query := q'{INSERT INTO Tmp_Locn_Cnt_By_Cust
						SELECT Count(DISTINCT NI_STOCK) AS CountOfStocks, IL_LOCN, IM_CUST, 
                      CASE WHEN Upper(substr(IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                        ELSE 'F- Shelves'
                        END AS "Note"
						FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
						INNER JOIN IM ON IM_STOCK = NI_STOCK
						WHERE IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_ANAL = :sAnalysis AND RM_TYPE = :v_p_RM_TYPE AND RM_ACTIVE = :v_p_IM_ACTIVE )
						AND IM_ACTIVE = :v_p_IM_ACTIVE
						AND NI_AVAIL_ACTUAL >= :v_p_NI_AVAIL_ACTUAL
						AND NI_STATUS <> :v_p_NI_STATUS
						GROUP BY IL_LOCN, IM_CUST,IL_NOTE_2
            }';
            --(SELECT RM_CUST FROM RM WHERE RM_ANAL = :sAnalysis AND RM_TYPE = :v_p_RM_TYPE AND RM_ACTIVE = :v_p_IM_ACTIVE )
		EXECUTE IMMEDIATE v_query USING sAnalysis,p_RM_TYPE,p_IM_ACTIVE,p_IM_ACTIVE,p_NI_AVAIL_ACTUAL,p_NI_STATUS;

	
		DBMS_OUTPUT.PUT_LINE('Successfully inserted Tmp_Locn_Cnt_By_Cust fresh temporary data by analysis' || sAnalysis);*/


    RETURN;
    COMMIT;
   -- RETURN;
   ELSIF (sAnalysis IS NULL) AND (sCust IS NOT NULL) Then
		v_query := q'{INSERT INTO Tmp_Locn_Cnt_By_Cust
						SELECT Count(DISTINCT NI_STOCK) AS CountOfStocks, IL_LOCN, IM_CUST, 
                      CASE WHEN Upper(substr(IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                        ELSE 'F- Shelves'
                        END AS "Note"
						FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
						INNER JOIN IM ON IM_STOCK = NI_STOCK
						WHERE IM_CUST IN :customer 
						AND IM_ACTIVE = :v_p_IM_ACTIVE
						AND NI_AVAIL_ACTUAL >= :v_p_NI_AVAIL_ACTUAL
						AND NI_STATUS <> :v_p_NI_STATUS
						GROUP BY IL_LOCN, IM_CUST,IL_NOTE_2}';
        /*(SELECT RM_CUST FROM RM WHERE RM_ANAL = :sAnalysis AND RM_TYPE = :v_p_RM_TYPE AND RM_ACTIVE = :v_p_IM_ACTIVE )*/
		EXECUTE IMMEDIATE v_query USING sCust,p_IM_ACTIVE,p_NI_AVAIL_ACTUAL,p_NI_STATUS;
		
		DBMS_OUTPUT.PUT_LINE('Successfully inserted Tmp_Locn_Cnt_By_Cust fresh temporary data  by customer' || sCust);
    RETURN;
    COMMIT;
	  END IF;

 EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE; 
END C_EOM_START_CUST_TEMP_DATA;   

  /*   Run this once for each customer   */
  /*   This gets all the customer charges and rates to charge   */
  /*   Currently Not Used!!!!!!!   */
  /*   No Tables Used - Just sets variables for each charge type   */
  PROCEDURE D_EOM_GET_CUST_RATES
    (
     --start_date IN ST.ST_DESP_DATE%TYPE := '2015-04-06'
     --,end_date IN ST.ST_DESP_DATE%TYPE := '2015-04-13'
     --,sAnalysis IN RM.RM_ANAL%TYPE
    -- sFeeField IN VARCHAR2,
     sCust IN RM.RM_CUST%TYPE,
     nRM_XX_FEE01 OUT NUMBER,--; /*VerbalOrderEntryFee*/
      nRM_XX_FEE02 OUT NUMBER, /*EmailOrderEntryFee*/
      nRM_XX_FEE03 OUT NUMBER, /*PhoneOrderEntryFee*/
      nRM_XX_FEE04 OUT NUMBER, /*PhoneOrderEntryFee*/
      nRM_XX_FEE05 OUT NUMBER, /*PhoneOrderEntryFee*/
      nRM_XX_FEE06 OUT NUMBER, /*Handeling Fee*/
      nRM_XX_FEE07 OUT NUMBER, /*FaxOrderEntryFee*/
      nRM_XX_FEE08 OUT NUMBER, /*InnerPackingFee*/
      nRM_XX_FEE09 OUT NUMBER, /*OuterPackingFee*/
      nRM_XX_FEE10 OUT NUMBER, /*FTPOrderEntryFee*/
      nRM_XX_FEE11 OUT NUMBER, /*Pallet Storage Fee*/
      nRM_XX_FEE12 OUT NUMBER, /*Shelf Storage Fee*/
      nRM_XX_FEE13 OUT NUMBER, /*Carton In Fee*/
      nRM_XX_FEE14 OUT NUMBER, /*Pallet In Fee*/
      nRM_XX_FEE15 OUT NUMBER, /*Carton Despatch Fee*/
      nRM_XX_FEE16 OUT NUMBER, /*Pick Fee*/
      nRM_XX_FEE17 OUT NUMBER, /*Pallet Despatch Fee*/
      nRM_XX_FEE18 OUT NUMBER, /*ShrinkWrap Fee*/
      nRM_XX_FEE19 OUT NUMBER, /*Admin Fee*/
      nRM_XX_FEE20 OUT NUMBER, /*Stock Maintenance Fee*/
      nRM_XX_FEE21 OUT NUMBER, /*DB Maintenance Fee*/
      nRM_XX_FEE22 OUT NUMBER, /*Bin Monthly Storage Fee*/
      nRM_XX_FEE23 OUT NUMBER, /*Daily Delivery Fee*/
      nRM_XX_FEE24 OUT NUMBER, /*Carton Destruction Fee*/
      nRM_XX_FEE25 OUT NUMBER, /*Pallet Destruction Fee*/
      nRM_XX_FEE26 OUT NUMBER, /*Additional Pallet Destruction Fee*/
      nRM_XX_FEE27 OUT NUMBER, /*Order Fee*/
      nRM_XX_FEE28 OUT NUMBER, /*Pallet Secured Storage Fee*/
      nRM_XX_FEE29 OUT NUMBER, /*Pallet Slow Moving Secured Fee*/
      nRM_XX_FEE30 OUT NUMBER, /*Shelf Slow Moving Fee*/
      nRM_XX_FEE31 OUT NUMBER, /*Secured Shelf Storage Fee*/
      nRM_XX_FEE32 OUT NUMBER, /*Pallet Archive Monthly Fee*/
      nRM_XX_FEE33 OUT NUMBER, /*Shelf Archive Monthly Fee*/
      nRM_XX_FEE34 OUT NUMBER, /*Manual Report Run Fee*/
      nRM_XX_FEE35 OUT NUMBER, /*Kitting Fee P/H*/
      nRM_XX_FEE36 OUT NUMBER, /*Pick Fee 2nd Scale*/
      nRM_SPARE_CHAR_3 OUT NUMBER, /*Pallet Slow Moving Fee*/
      nRM_SPARE_CHAR_5 OUT NUMBER, /*System Maintenance Fee*/
      nRM_SPARE_CHAR_4 OUT NUMBER, /*Stocktake Fee P/H*/
      nRM_XX_ADMIN_CHG OUT NUMBER, /*Shelf Slow Moving Secured Fee*/
      nRM_XX_PALLET_CHG OUT NUMBER, /*Return Per Pallet Fee*/
      nRM_XX_SHELF_CHG OUT NUMBER, /*Return Per Shelf Fee*/
      nRM_XX_FEE31_1 OUT NUMBER, /*Minimun Monthly Charge Fee*/
      nRM_XX_FEE32_1 OUT NUMBER, /*UnallocatedFee*/
      nRM_XX_FEE33_1 OUT NUMBER, /*UnallocatedFee*/
      nRM_XX_FEE34_1 OUT NUMBER, /*UnallocatedFee*/
      nRM_XX_FEE35_1 OUT NUMBER, /*UnallocatedFee*/
      nRM_XX_FEE36_1 OUT NUMBER /*UnallocatedFee*/--,
      --PreData IN RM.RM_ACTIVE%TYPE := 0
     --,gdf_desp_freight_cur OUT sys_refcursor
     ) 
  AS
    --v_out_tx          VARCHAR2(32767);
    --v_query3           VARCHAR2(32767);
		--v_query2          VARCHAR2(32767);
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
  
    v_cust  VARCHAR2(20);
  
    /*the_variable VARCHAR2(30);
    BEGIN
      the_variable := '&the_variable';
      dbms_output.put_line(the_variable);
    END;*/

  BEGIN
  

	nCheckpoint := 1000;
    SELECT To_Number(regexp_substr(RM_XX_FEE01,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE01 FROM RM where RM_CUST = sCust;
    --DBMS_OUTPUT.PUT_LINE('success RM_XX_FEE01 should be $' || nRM_XX_FEE01 || ' for customer ' || sCust);
                          
   SELECT  To_Number(regexp_substr(RM_XX_FEE02,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE02 FROM RM where RM_CUST = sCust;
   --DBMS_OUTPUT.PUT_LINE('success RM_XX_FEE02 should be $' || nRM_XX_FEE02 || ' for customer ' || sCust);
   
 SELECT To_Number(regexp_substr(RM_XX_FEE03,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE03 FROM RM where RM_CUST = sCust;

 SELECT To_Number(regexp_substr(RM_XX_FEE04,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE04 FROM RM where RM_CUST = sCust;

   SELECT To_Number(regexp_substr(RM_XX_FEE05,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE05 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE06 FROM RM where RM_CUST = sCust;

   --SELECT To_Number(regexp_substr(RM_XX_FEE01,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE01 FROM RM where RM_CUST = sCust;
   SELECT To_Number(regexp_substr(RM_XX_FEE07,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE07 FROM RM where RM_CUST = sCust;
  --DBMS_OUTPUT.PUT_LINE('success RM_XX_FEE07 should be $' || nRM_XX_FEE07 || ' for customer ' || sCust);

  SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE08 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE09 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_FEE10,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE10 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE11 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE12 FROM RM where RM_CUST = sCust;

 SELECT To_Number(regexp_substr(RM_XX_FEE13,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE13 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE14 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE15 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE16 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_FEE17,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE17 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE18 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_FEE19,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE19 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_FEE20,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE20 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_FEE21,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE21 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_FEE22,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE22 FROM RM where RM_CUST = sCust;
  --DBMS_OUTPUT.PUT_LINE('success RM_XX_FEE22 should be $' || nRM_XX_FEE22 || ' for customer ' || sCust);

  SELECT To_Number(regexp_substr(RM_XX_FEE23,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE23 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_FEE24,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE24 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE25 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_FEE26,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE26 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_FEE27,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE27 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_FEE28,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE28 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_FEE29,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE29 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_FEE30,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE30 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_FEE31,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE31 FROM RM where RM_CUST = sCust;

   SELECT To_Number(regexp_substr(RM_XX_FEE32,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE32 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_FEE33,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE33 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_FEE34,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE34 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_FEE35,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE35 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_FEE36,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE36 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_SPARE_CHAR_3,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_SPARE_CHAR_3 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_SPARE_CHAR_5,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_SPARE_CHAR_5 FROM RM where RM_CUST = sCust;
  --DBMS_OUTPUT.PUT_LINE('success RM_SPARE_CHAR_5 should be $' || nRM_SPARE_CHAR_5 || ' for customer ' || sCust);

  SELECT To_Number(regexp_substr(RM_SPARE_CHAR_4,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_SPARE_CHAR_4 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_ADMIN_CHG,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_ADMIN_CHG FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_PALLET_CHG,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_PALLET_CHG FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_SHELF_CHG,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_SHELF_CHG FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_FEE31_1,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE31_1 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_FEE32_1,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE32_1 FROM RM where RM_CUST = sCust;
  --DBMS_OUTPUT.PUT_LINE('success RM_XX_FEE32_1 should be $' || nRM_XX_FEE32_1 || ' for customer ' || sCust);

  SELECT To_Number(regexp_substr(RM_XX_FEE33_1,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE33_1 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_FEE34_1,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE34_1 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_FEE35_1,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE35_1 FROM RM where RM_CUST = sCust;

  SELECT To_Number(regexp_substr(RM_XX_FEE36_1,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE36_1 FROM RM where RM_CUST = sCust;

  RETURN;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE; 
  END D_EOM_GET_CUST_RATES;
  
  
  /*   Run this once for each customer   */
  /*   This gets all the IFS freight and Manual Freight data   */
  /*   Temp Tables Used   */
  /*   1. TMP_FREIGHT   */
  PROCEDURE EOM_TMP_ALL_FREIGHT_ALL_CUST (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,start_date IN VARCHAR2 -- use this when you want the date entered automatically
      ,end_date IN VARCHAR2
      ,sClient IN VARCHAR2,
      sAnalysis IN RM.RM_ANAL%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_FREIGHT%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    SQLQuery          VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		sCourierm         VARCHAR2(20) := 'COURIERM';
    sCouriers         VARCHAR2(20) := 'COURIERS';
    sCourier          VARCHAR2(20) := 'COURIER%';
    sServ8             VARCHAR2(20) := 'SERV8';
    sServ3             VARCHAR2(20) := 'SERV%';
    --sCust2    VARCHAR2(20) := sCust;
    --end_date2 ST.ST_DESP_DATE%TYPE := end_date;
    --DBMS_OUTPUT.PUT_LINE(start_date || ' - ' || end_date || '.' || sCust );
      
   -- if start_date IS NOT NULL then
        
    CURSOR c 
    --(
      --start_date IN ST.ST_DESP_DATE%TYPE
    -- ,end_date IN ST.ST_DESP_DATE%TYPE
    --sCust IN RM.RM_CUST%TYPE
     --)
     
     IS 
    
       
    	 select    s.SH_CUST                AS "Customer",
			  r.sGroupCust              AS "Parent",
			  s.SH_SPARE_STR_4         AS "CostCentre",
			  s.SH_ORDER               AS "Order",
			  s.SH_SPARE_STR_5         AS "OrderwareNum",
			  s.SH_CUST_REF            AS "CustomerRef",
			  t.ST_PICK                AS "Pickslip",
			  d.SD_XX_PICKLIST_NUM     AS "PickNum",
			  t.ST_PSLIP               AS "DespatchNote",
			  TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD')            AS "DespatchDate",
	      CASE  WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 0.1 THEN 'Freight Fee'
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
       -- d.SD_SELL_PRICE          AS "UnitPrice",
       CASE  WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.sGroupCust <> 'BORBUI' AND r.sGroupCust <> 'BEYONDBLUE') THEN d.SD_SELL_PRICE
			        WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.sGroupCust = 'BORBUI' OR r.sGroupCust = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.125) And (t.ST_SPARE_DBL_1 > 0.00) THEN 1.70
              WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.sGroupCust = 'BORBUI' OR r.sGroupCust = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.250) And (t.ST_SPARE_DBL_1 > 0.126) THEN 2.30
              WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.sGroupCust = 'BORBUI' OR r.sGroupCust = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.500) And (t.ST_SPARE_DBL_1 > 0.251) THEN 3.40
              WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.sGroupCust = 'BORBUI' OR r.sGroupCust = 'BEYONDBLUE') AND (t.ST_WEIGHT > 0.01) THEN d.SD_SELL_PRICE
              ELSE NULL
			        END                      AS "UnitPrice",
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
			--	0 AS "AvailSOH",/*Avail SOH*/
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
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
	WHERE     s.SH_ORDER = d.SD_ORDER
  AND t.ST_PSLIP != 'CANCELLED'
	--AND       r.RM_ANAL = :sAnalysis
	--AND      r.sGroupCust = sShary --'VHAAUS'
  AND       r.sGroupCust = sClient OR r.sCust = sClient
	AND       d.SD_STOCK IN ('COURIERM','COURIERS','COURIER')
	AND       s.SH_ORDER = t.ST_ORDER
	AND       d.SD_SELL_PRICE >= 0.1
	--AND       t.ST_DESP_DATE >= start_date
  AND       t.ST_DESP_DATE >= start_date AND t.ST_DESP_DATE <= end_date
  --AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
  AND   d.SD_ADD_OP LIKE 'SERV%'
  
 /* 	WHERE     r.sGroupCust = :sCust OR r.sCust = :sCust
	AND       d.SD_STOCK LIKE :sCourier -- (:courier1,:courier2,:courier3)
	AND       s.SH_ORDER = t.ST_ORDER
	AND       d.SD_SELL_PRICE >= 0.1
	AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
  AND   d.SD_ADD_OP LIKE :sServ3;
  USING sCust,sCust,sCourier,start_date,end_date,sServ3;

 -- OPEN c(sCust,
  
  --AND s.SH_ORDER LIKE '   1377018'*/

	GROUP BY  sCust,
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
			  r.sGroupCust,
			  s.SH_SPARE_STR_5,
			  s.SH_CUST_REF,
        s.SH_SPARE_STR_3,
        s.SH_SPARE_STR_1,
        t.ST_SPARE_DBL_1,
        d.SD_XX_PSLIP_NUM,
          d.SD_ADD_DATE,
          d.SD_XX_PICKLIST_NUM,
          d.SD_COST_PRICE,s.SH_CUST
   
   
   UNION ALL

/*freight fees*/



/*Manual freight fees*/
	 select    s.SH_CUST                AS "Customer",
			  r.sGroupCust              AS "Parent",
			  s.SH_SPARE_STR_4         AS "CostCentre",
			  s.SH_ORDER               AS "Order",
			  s.SH_SPARE_STR_5         AS "OrderwareNum",
			  s.SH_CUST_REF            AS "CustomerRef",
			  t.ST_PICK                AS "Pickslip",
			  d.SD_XX_PICKLIST_NUM     AS "PickNum",
			  t.ST_PSLIP               AS "DespatchNote",
			  TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD')            AS "DespatchDate",
--	      CASE  WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 0.1 THEN 'Freight Fee'
--			          ELSE To_Char(d.SD_DESC)
--			          END                      AS "FeeType",
        CASE  WHEN d.SD_STOCK IN ('COURIERM','COURIERS','COURIER','DETENTIONTIMEM','DETENTIONTIMES','FREIGHTDUTY') AND d.SD_SELL_PRICE >= 0.1  THEN 'Manual Freight Fee'
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
			--	0 AS "AvailSOH",/*Avail SOH*/
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
              INNER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_ORDER))  = LTRIM(RTRIM(d.SD_ORDER))
              LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
        WHERE     s.SH_ORDER = d.SD_ORDER
        AND t.ST_PSLIP != 'CANCELLED'
         --	AND       r.RM_ANAL NOT IN ('21VICP','22NSWP')-- :sAnalysis
       -- AND       r.sGroupCust like sShary
        AND       r.sGroupCust = sClient OR r.sCust = sClient
        AND       d.SD_STOCK IN ('COURIERM','COURIERS','COURIER','DETENTIONTIMEM','DETENTIONTIMES','FREIGHTDUTY')
        AND       s.SH_ORDER = t.ST_ORDER
        AND       d.SD_SELL_PRICE >= 0.1
        --AND d.SD_ADD_DATE = '2-MAY-2014' AND d.SD_ADD_OP = 'PRJ'
       AND       t.ST_DESP_DATE >= start_date AND t.ST_DESP_DATE <= end_date
        --AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
        --AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= F_FIRST_DAY_PREV_MONTH AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= F_LAST_DAY_PREV_MONTH
        AND   d.SD_ADD_OP NOT LIKE 'SERV%' /*AND d.SD_ADD_OP NOT LIKE 'RV%'      */


        GROUP BY  sCust,
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
			  r.sGroupCust,
			  s.SH_SPARE_STR_5,
			  s.SH_CUST_REF,
        s.SH_SPARE_STR_3,
        s.SH_SPARE_STR_1,
        t.ST_SPARE_DBL_1,
        d.SD_XX_PSLIP_NUM,
          d.SD_ADD_DATE,
          d.SD_XX_PICKLIST_NUM,
          d.SD_COST_PRICE,s.SH_CUST;
          --HAVING d.SD_STOCK IN ('COURIERM','COURIERS','COURIER','DETENTIONTIMEM','DETENTIONTIMES','FREIGHTDUTY')
         --- AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date;

--USING ;
    nbreakpoint   NUMBER;

    BEGIN
    
    nCheckpoint := 1;
      v_query := 'TRUNCATE TABLE TMP_FREIGHT';
      EXECUTE IMMEDIATE v_query;
    COMMIT;
    --DBMS_OUTPUT.PUT_LINE('AA EOM Temp Freight table truncated ' 
    --  || start_date || ' -- ' || end_date);
    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sShary || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
        
        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_FREIGHT VALUES l_data(i); 
        --USING sCust;
        
        EXIT WHEN c%NOTFOUND;

        END LOOP;
        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
       --FOR i IN l_data.FIRST .. l_data.LAST LOOP
        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
      --END LOOP;

  COMMIT;
  --RETURN;
  DBMS_OUTPUT.PUT_LINE('AA EOM Temp Freight for all customers for the date range ' 
      || start_date || ' -- ' || end_date);
    --COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM Freight processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;

  END EOM_TMP_ALL_FREIGHT_ALL_CUST;
  
  
  /*   Run this once for each intercompany customer   */
  /*   This gets all the IFS freight and Manual Freight data   */
  /*   Temp Tables Used   */
  /*   1. TMP_FREIGHT   */
  PROCEDURE EOM_TMP_ALL_FREIGHT_ALL_IC (
      p_array_size IN PLS_INTEGER DEFAULT 100
        ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
        ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
        ,sCust IN RM.RM_CUST%TYPE,
      sAnalysis IN RM.RM_ANAL%TYPE
      -- sCust IN RM.RM_CUST%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_FREIGHT%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		sCourierm         VARCHAR2(20) := 'COURIERM';
    sCouriers         VARCHAR2(20) := 'COURIERS';
    sCourier         VARCHAR2(20) := 'COURIER%';
    sServ8             VARCHAR2(20) := 'SERV8';
    sServ3             VARCHAR2(20) := 'SERV%';
    --sCust2    VARCHAR2(20) := sCust;
    --end_date2 ST.ST_DESP_DATE%TYPE := end_date;
    --DBMS_OUTPUT.PUT_LINE(start_date || ' - ' || end_date || '.' || sCust );
      


    CURSOR c 
    --(
      --start_date IN ST.ST_DESP_DATE%TYPE
    -- ,end_date IN ST.ST_DESP_DATE%TYPE
    --sCust IN RM.RM_CUST%TYPE
     --)
     IS 
    	 select    s.SH_CUST           AS "Customer",
			    r.RM_PARENT              AS "Parent",
			  s.SH_SPARE_STR_4         AS "CostCentre",
			  s.SH_ORDER               AS "Order",
			  s.SH_SPARE_STR_5         AS "OrderwareNum",
			  s.SH_CUST_REF            AS "CustomerRef",
			  t.ST_PICK                AS "Pickslip",
			  d.SD_XX_PICKLIST_NUM     AS "PickNum",
			  t.ST_PSLIP               AS "DespatchNote",
			  substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	      CASE  WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 0.1 THEN 'Freight Fee'
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
			--	0 AS "AvailSOH",/*Avail SOH*/
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
	  AND       r.RM_ANAL = sAnalysis
	  	AND       d.SD_STOCK IN ('COURIERM','COURIERS','COURIER')
	AND       s.SH_ORDER = t.ST_ORDER
	AND       d.SD_SELL_PRICE >= 0.1
	AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= F_FIRST_DAY_PREV_MONTH AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= F_LAST_DAY_PREV_MONTH
  AND   d.SD_ADD_OP LIKE 'SERV%'
  
 /* 	WHERE     r.sGroupCust = :sCust OR r.sCust = :sCust
	AND       d.SD_STOCK LIKE :sCourier -- (:courier1,:courier2,:courier3)
	AND       s.SH_ORDER = t.ST_ORDER
	AND       d.SD_SELL_PRICE >= 0.1
	AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
  AND   d.SD_ADD_OP LIKE :sServ3;
  USING sCust,sCust,sCourier,start_date,end_date,sServ3;

 -- OPEN c(sCust,
  
  --AND s.SH_ORDER LIKE '   1377018'*/

	GROUP BY  s.SH_CUST,r.RM_PARENT,
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
			  --r.sGroupCust,
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
			--	0 AS "AvailSOH",/*Avail SOH*/
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
          AND       r.RM_ANAL = sAnalysis
          --	AND       (r.RM_PARENT = :cust OR r.RM_CUST = :cust)
          AND       d.SD_STOCK IN ('COURIERM','COURIERS','COURIER','DETENTIONTIMEM','DETENTIONTIMES','FREIGHTDUTY')
          AND       s.SH_ORDER = t.ST_ORDER
          AND       d.SD_SELL_PRICE >= 0.1
          --AND d.SD_ADD_DATE = '2-MAY-2014' AND d.SD_ADD_OP = 'PRJ'
          AND       TO_CHAR(d.SD_ADD_DATE,'YYYY-MM-DD') >= F_FIRST_DAY_PREV_MONTH AND TO_CHAR(d.SD_ADD_DATE,'YYYY-MM-DD') <= F_LAST_DAY_PREV_MONTH
          AND   d.SD_ADD_OP NOT LIKE 'SERV%'


        GROUP BY  s.SH_CUST,r.RM_PARENT,
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
			  --r.sGroupCust,
			  s.SH_SPARE_STR_5,
			  s.SH_CUST_REF,
        s.SH_SPARE_STR_3,
        s.SH_SPARE_STR_1,
        t.ST_SPARE_DBL_1,
        d.SD_XX_PSLIP_NUM,
          d.SD_ADD_DATE,
          d.SD_XX_PICKLIST_NUM,
          d.SD_COST_PRICE;
       
  
          --USING start_date; 
--USING ;
    nbreakpoint   NUMBER;

    BEGIN
    
    nCheckpoint := 1;
      v_query := 'TRUNCATE TABLE TMP_FREIGHT';
      EXECUTE IMMEDIATE v_query;
    
    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
        
        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_FREIGHT VALUES l_data(i); 
        --USING sCust;
        
        EXIT WHEN c%NOTFOUND;

        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
      -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
      --END LOOP;

  COMMIT;
  --RETURN;
  DBMS_OUTPUT.PUT_LINE('EOM Temp Freight for all inter company for the date range ' 
      || start_date || ' -- ' || end_date);
    --COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM Freight processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;

  END EOM_TMP_ALL_FREIGHT_ALL_IC;
 
  /*   Run this once for each customer   */
  /*   This gets all the Order Related Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_ORD_FEES   */
  PROCEDURE EOM_PHONE_ORD_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
      -- ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
      -- ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
      --  start_date IN VARCHAR2(20) := '01-Jun-2015'; -- use this format when using ST_DESP_DATE unformatted
      --  end_date IN VARCHAR2(20) := '30-Jun-2015';
      --,   start_date IN VARCHAR2 := '2015-06-01' -- use this when ST_DESP_DATE is formatted
       --, end_date IN VARCHAR2 := '2015-06-30'
      ,start_date IN VARCHAR2 := F_FIRST_DAY_PREV_MONTH -- use this when you want the date entered automatically
      ,end_date IN VARCHAR2 := F_LAST_DAY_PREV_MONTH
      ,sCust IN RM.RM_CUST%TYPE
      ,sAnalysis IN RM.RM_ANAL%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_ORD_FEES%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		sCourierm         VARCHAR2(20) := 'COURIERM';
    sCouriers         VARCHAR2(20) := 'COURIERS';
    sCourier         VARCHAR2(20) := 'COURIER%';
    sServ8             VARCHAR2(20) := 'SERV8';
    sServ3             VARCHAR2(20) := 'SERV%';
    nRM_XX_FEE01  NUMBER; /*VerbalOrderEntryFee*/
    nRM_XX_FEE02  NUMBER; /*EmailOrderEntryFee*/
    nRM_XX_FEE03  NUMBER; /*PhoneOrderEntryFee*/
    nRM_XX_FEE04  NUMBER; /*PhoneOrderEntryFee*/
    nRM_XX_FEE05  NUMBER; /*PhoneOrderEntryFee*/
    nRM_XX_FEE06  NUMBER; /*Handeling Fee*/
    nRM_XX_FEE07  NUMBER; /*FaxOrderEntryFee*/
    nRM_XX_FEE08  NUMBER; /*InnerPackingFee*/
    nRM_XX_FEE09  NUMBER; /*OuterPackingFee*/
    nRM_XX_FEE10  NUMBER; /*FTPOrderEntryFee*/
    nRM_XX_FEE32_1  NUMBER; /*UnallocatedFee*/
    nRM_XX_FEE25  NUMBER; /*Pallet Destruction Fee*/
    --p2_array_size PLS_INTEGER := D_EOM_GET_CUST_RATES('TABCORP',0);
    --Type rates IS VARRAY(35) OF INTEGER;
    --rates := D_EOM_GET_CUST_RATES('TABCORP');
    --sCust2    VARCHAR2(20) := sCust;
    --end_date2 ST.ST_DESP_DATE%TYPE := end_date;
    nbreakpoint   NUMBER;
    --DBMS_OUTPUT.PUT_LINE(start_date || ' - ' || end_date || '.' || sCust );
    --BEGIN
     --D_EOM_GET_CUST_RATES('TABCORP');
    --END
    --BEGIN
    /*
      SELECT To_Number(regexp_substr(RM_XX_FEE01,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE01 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE02,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE02 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE03,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE03 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE04,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE04 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE05,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE05 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE06 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE07,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE07 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE08 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE09 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE10,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE10 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE32_1,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE32_1 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE25 FROM RM where RM_CUST = sCust;
    --END;
   */ 
   

      
      
    
     --END;
     CURSOR c 
    IS 
    	/*PhoneOrderEntryFee*/
    SELECT    s.SH_CUST,r.sGroupCust,
			  CASE    WHEN i.IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
			  WHEN i.IM_CUST = 'TABCORP' THEN i.IM_XX_COST_CENTRE01
			  ELSE s.SH_SPARE_STR_4
			  END,
			  s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,
			  NULL,NULL,NULL,
			  substr(To_Char(t.ST_DESP_DATE),0,10),
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  'OrderEntryFee'
			  ELSE ''
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  'FEEORDERENTRYS'
			  ELSE ''
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  'Phone Order Entry Fee'
			  ELSE ''
			  END,
        CASE    WHEN d.SD_LINE = 1 THEN  1
			  ELSE NULL
			  END,
        CASE    WHEN d.SD_LINE = 1 THEN  '1'
			  ELSE ''
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
			  ELSE NULL
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
			  ELSE NULL
			  END,
			  NULL,
			  s.SH_ADDRESS,s.SH_SUBURB,
			  s.SH_CITY,s.SH_STATE,
			  s.SH_POST_CODE,s.SH_NOTE_1,
			  s.SH_NOTE_2,
        0,0,
			  s.SH_SPARE_DBL_9,
			  NULL,NULL,
				0,
        CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
        ELSE ''
        END,
        'N/A',
        i.IM_OWNED_By,i.IM_PROFILE,
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4
	FROM      PWIN175.SH s
			  INNER JOIN PWIN175.SD d ON d.SD_ORDER  = s.SH_ORDER
			  INNER JOIN PWIN175.IM i ON i.IM_STOCK = d.SD_STOCK
			  INNER JOIN PWIN175.ST t ON t.ST_ORDER = s.SH_ORDER AND t.ST_PICK = s.SH_LAST_PICK_NUM
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
			  --LEFT JOIN PWIN175.RM r2 ON r2.RM_ANAL = r.RM_ANAL AND r2.RM_CUST = :cust
	WHERE (r.sGroupCust = sCust OR r.sCust = sCust)
  AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
  --AND       t.ST_DESP_DATE >= start_date AND t.ST_DESP_DATE <= end_date
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	AND       s.SH_SPARE_DBL_9 = 1
	AND       d.SD_LINE = 1
  AND (SELECT To_Number(regexp_substr(RM_XX_FEE03,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0.1
	GROUP BY   s.SH_CUST,r.sGroupCust,i.IM_CUST,s.SH_SPARE_STR_4,i.IM_XX_COST_CENTRE01,
        s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,t.ST_DESP_DATE,s.SH_SPARE_DBL_9,d.SD_LINE,
        s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_NOTE_2,s.SH_SPARE_STR_3,
        i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4,s.SH_SPARE_STR_1,
        d.SD_ORDER,d.SD_STOCK,t.ST_ORDER,t.ST_PICK,s.SH_LAST_PICK_NUM,r.sCust,s.SH_PREV_PSLIP_NUM,i.IM_TYPE,s.SH_STATUS,
        i.IM_BRAND,t.ST_WEIGHT,t.ST_PACKAGES,d.SD_LAST_PICK_NUM
        
        
 
;

    BEGIN
    

    nCheckpoint := 1;
      v_query := 'TRUNCATE TABLE TMP_ORD_FEES';
      EXECUTE IMMEDIATE v_query;
    
    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
        
        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_ORD_FEES VALUES l_data(i); 
        --USING sCust;
        
        EXIT WHEN c%NOTFOUND;

        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
--       FOR i IN l_data.FIRST .. l_data.LAST LOOP
--        DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
--      END LOOP;

  COMMIT;
  --RETURN;
  DBMS_OUTPUT.PUT_LINE('EOM Temp Order Fees for all customers for the date range ' 
      || start_date || ' -- ' || end_date  || ' run for customer ' || sCust);
    --COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM Temp Order Fees processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;

  END EOM_PHONE_ORD_FEES;
  
  /*   Run this once for each customer   */
  /*   This gets all the Order Related Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_ORD_FEES   */
  PROCEDURE EOM_EMAIL_ORD_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
      -- ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
      -- ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
      --  start_date IN VARCHAR2(20) := '01-Jun-2015'; -- use this format when using ST_DESP_DATE unformatted
      --  end_date IN VARCHAR2(20) := '30-Jun-2015';
        , start_date IN VARCHAR2 := '2015-06-01' -- use this when ST_DESP_DATE is formatted
        ,end_date IN VARCHAR2 := '2015-06-30'
--      ,start_date IN VARCHAR2 := F_FIRST_DAY_PREV_MONTH -- use this when you want the date entered automatically
--      ,end_date IN VARCHAR2 := F_LAST_DAY_PREV_MONTH
      ,sCust IN RM.RM_CUST%TYPE
      ,sAnalysis IN RM.RM_ANAL%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_ORD_FEES%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		sCourierm         VARCHAR2(20) := 'COURIERM';
    sCouriers         VARCHAR2(20) := 'COURIERS';
    sCourier         VARCHAR2(20) := 'COURIER%';
    sServ8             VARCHAR2(20) := 'SERV8';
    sServ3             VARCHAR2(20) := 'SERV%';
    nRM_XX_FEE01  NUMBER; /*VerbalOrderEntryFee*/
    nRM_XX_FEE02  NUMBER; /*EmailOrderEntryFee*/
    nRM_XX_FEE03  NUMBER; /*PhoneOrderEntryFee*/
    nRM_XX_FEE04  NUMBER; /*PhoneOrderEntryFee*/
    nRM_XX_FEE05  NUMBER; /*PhoneOrderEntryFee*/
    nRM_XX_FEE06  NUMBER; /*Handeling Fee*/
    nRM_XX_FEE07  NUMBER; /*FaxOrderEntryFee*/
    nRM_XX_FEE08  NUMBER; /*InnerPackingFee*/
    nRM_XX_FEE09  NUMBER; /*OuterPackingFee*/
    nRM_XX_FEE10  NUMBER; /*FTPOrderEntryFee*/
    nRM_XX_FEE32_1  NUMBER; /*UnallocatedFee*/
    nRM_XX_FEE25  NUMBER; /*Pallet Destruction Fee*/
    --p2_array_size PLS_INTEGER := D_EOM_GET_CUST_RATES('TABCORP',0);
    --Type rates IS VARRAY(35) OF INTEGER;
    --rates := D_EOM_GET_CUST_RATES('TABCORP');
    --sCust2    VARCHAR2(20) := sCust;
    end_date2 ST.ST_DESP_DATE%TYPE := end_date;
    nbreakpoint   NUMBER;
    --DBMS_OUTPUT.PUT_LINE(start_date || ' - ' || end_date || '.' || sCust );
    --BEGIN
     --D_EOM_GET_CUST_RATES('TABCORP');
    --END
    --BEGIN
    /*
      SELECT To_Number(regexp_substr(RM_XX_FEE01,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE01 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE02,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE02 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE03,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE03 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE04,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE04 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE05,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE05 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE06 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE07,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE07 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE08 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE09 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE10,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE10 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE32_1,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE32_1 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE25 FROM RM where RM_CUST = sCust;
    --END;
   */ 
   

      
      
    
     --END;
     CURSOR c 
    IS 
    

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
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "UnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "OWUnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN   (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "DExcl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "Excl_Total",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN   (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
			  ELSE NULL
			  END                     AS "DIncl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN   (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
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
	WHERE (r.sGroupCust = sCust OR r.sCust = sCust)
  AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
  --AND       t.ST_DESP_DATE >= start_date AND t.ST_DESP_DATE <= end_date
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	AND       s.SH_SPARE_DBL_9 = 3
	AND       d.SD_LINE = 1
	--AND       Select rm3.RM_XX_FEE02 from RM rm3 where To_Number(regexp_substr(rm3.RM_XX_FEE02,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0 AND rm3.RM_CUST = :cust
  AND (SELECT To_Number(regexp_substr(RM_XX_FEE02,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0.1
	--AND      nRM_XX_FEE02 > 0 --AND rm3.RM_CUST = :cust
	--AND       (Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust) <> 0
	--AND       (Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust) <> '0'
	--AND       (Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust) IS NOT NULL
	GROUP BY  s.SH_CUST,r.sGroupCust,i.IM_CUST,s.SH_SPARE_STR_4,i.IM_XX_COST_CENTRE01,
        s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,t.ST_DESP_DATE,s.SH_SPARE_DBL_9,d.SD_LINE,
        s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_NOTE_2,s.SH_SPARE_STR_3,
        i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4,s.SH_SPARE_STR_1,
        d.SD_ORDER,d.SD_STOCK,t.ST_ORDER,t.ST_PICK,s.SH_LAST_PICK_NUM,r.sCust,s.SH_PREV_PSLIP_NUM,i.IM_TYPE,s.SH_STATUS,
        i.IM_BRAND,t.ST_WEIGHT,t.ST_PACKAGES,d.SD_LAST_PICK_NUM

 
/*EmailOrderEntryFee*/

	
;

    BEGIN
    

    nCheckpoint := 1;
      v_query := 'TRUNCATE TABLE TMP_ORD_FEES';
      EXECUTE IMMEDIATE v_query;
    
    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
        
        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_ORD_FEES VALUES l_data(i); 
        --USING sCust;
        
        EXIT WHEN c%NOTFOUND;

        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
--       FOR i IN l_data.FIRST .. l_data.LAST LOOP
--        DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
--      END LOOP;

  COMMIT;
  --RETURN;
  DBMS_OUTPUT.PUT_LINE('EOM Temp Order Fees for all customers for the date range ' 
      || start_date || ' -- ' || end_date  || ' run for customer ' || sCust);
    --COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM Temp Order Fees processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;

  END EOM_EMAIL_ORD_FEES;
  
  /*   Run this once for each customer   */
  /*   This gets all the Order Related Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_ORD_FEES   */
  PROCEDURE EOM_FAX_ORD_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
      -- ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
      -- ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
      --  start_date IN VARCHAR2(20) := '01-Jun-2015'; -- use this format when using ST_DESP_DATE unformatted
      --  end_date IN VARCHAR2(20) := '30-Jun-2015';
      --   start_date IN VARCHAR2(20) := '2015-06-01'; -- use this when ST_DESP_DATE is formatted
      --  end_date IN VARCHAR2(20) := '2015-06-30';
      ,start_date IN VARCHAR2 := F_FIRST_DAY_PREV_MONTH -- use this when you want the date entered automatically
      ,end_date IN VARCHAR2 := F_LAST_DAY_PREV_MONTH
      ,sCust IN RM.RM_CUST%TYPE
      ,sAnalysis IN RM.RM_ANAL%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_ORD_FEES%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		sCourierm         VARCHAR2(20) := 'COURIERM';
    sCouriers         VARCHAR2(20) := 'COURIERS';
    sCourier         VARCHAR2(20) := 'COURIER%';
    sServ8             VARCHAR2(20) := 'SERV8';
    sServ3             VARCHAR2(20) := 'SERV%';
    nRM_XX_FEE01  NUMBER; /*VerbalOrderEntryFee*/
    nRM_XX_FEE02  NUMBER; /*EmailOrderEntryFee*/
    nRM_XX_FEE03  NUMBER; /*PhoneOrderEntryFee*/
    nRM_XX_FEE04  NUMBER; /*PhoneOrderEntryFee*/
    nRM_XX_FEE05  NUMBER; /*PhoneOrderEntryFee*/
    nRM_XX_FEE06  NUMBER; /*Handeling Fee*/
    nRM_XX_FEE07  NUMBER; /*FaxOrderEntryFee*/
    nRM_XX_FEE08  NUMBER; /*InnerPackingFee*/
    nRM_XX_FEE09  NUMBER; /*OuterPackingFee*/
    nRM_XX_FEE10  NUMBER; /*FTPOrderEntryFee*/
    nRM_XX_FEE32_1  NUMBER; /*UnallocatedFee*/
    nRM_XX_FEE25  NUMBER; /*Pallet Destruction Fee*/
    --p2_array_size PLS_INTEGER := D_EOM_GET_CUST_RATES('TABCORP',0);
    --Type rates IS VARRAY(35) OF INTEGER;
    --rates := D_EOM_GET_CUST_RATES('TABCORP');
    --sCust2    VARCHAR2(20) := sCust;
    end_date2 ST.ST_DESP_DATE%TYPE := end_date;
    nbreakpoint   NUMBER;
    --DBMS_OUTPUT.PUT_LINE(start_date || ' - ' || end_date || '.' || sCust );
    --BEGIN
     --D_EOM_GET_CUST_RATES('TABCORP');
    --END
    --BEGIN
    /*
      SELECT To_Number(regexp_substr(RM_XX_FEE01,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE01 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE02,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE02 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE03,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE03 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE04,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE04 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE05,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE05 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE06 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE07,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE07 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE08 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE09 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE10,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE10 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE32_1,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE32_1 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE25 FROM RM where RM_CUST = sCust;
    --END;
   */ 
   

      
      
    
     --END;
     CURSOR c 
    IS 
    

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
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "UnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "OWUnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "DExcl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "Excl_Total",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN   (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
			  ELSE NULL
			  END                     AS "DIncl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
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
	WHERE (r.sGroupCust = sCust OR r.sCust = sCust)
  AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
 -- AND       t.ST_DESP_DATE >= start_date AND t.ST_DESP_DATE <= end_date
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	AND       s.SH_SPARE_DBL_9 = 2
	AND       d.SD_LINE = 1
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> 0
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> '0'
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) IS NOT NULL
	--AND      nRM_XX_FEE07 > 0
  AND (SELECT To_Number(regexp_substr(RM_XX_FEE07,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0.1
	GROUP BY   s.SH_CUST,r.sGroupCust,i.IM_CUST,s.SH_SPARE_STR_4,i.IM_XX_COST_CENTRE01,
        s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,t.ST_DESP_DATE,s.SH_SPARE_DBL_9,d.SD_LINE,
        s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_NOTE_2,s.SH_SPARE_STR_3,
        i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4,s.SH_SPARE_STR_1,
        d.SD_ORDER,d.SD_STOCK,t.ST_ORDER,t.ST_PICK,s.SH_LAST_PICK_NUM,r.sCust,s.SH_PREV_PSLIP_NUM,i.IM_TYPE,s.SH_STATUS,
        i.IM_BRAND,t.ST_WEIGHT,t.ST_PACKAGES,d.SD_LAST_PICK_NUM

  
/*FaxOrderEntryFee*/

;

    BEGIN
    

    nCheckpoint := 1;
      v_query := 'TRUNCATE TABLE TMP_ORD_FEES';
      EXECUTE IMMEDIATE v_query;
    
    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
        
        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_ORD_FEES VALUES l_data(i); 
        --USING sCust;
        
        EXIT WHEN c%NOTFOUND;

        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
--       FOR i IN l_data.FIRST .. l_data.LAST LOOP
--        DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
--      END LOOP;

  COMMIT;
  --RETURN;
  DBMS_OUTPUT.PUT_LINE('EOM Temp Order Fees for all customers for the date range ' 
      || start_date || ' -- ' || end_date  || ' run for customer ' || sCust);
    --COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM Temp Order Fees processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;

  END EOM_FAX_ORD_FEES;
  
  /*   Run this once for each customer   */
  /*   This gets all the Order Related Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_ORD_FEES   */
  PROCEDURE EOM_VERBAL_ORD_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
      -- ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
      -- ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
      --  start_date IN VARCHAR2(20) := '01-Jun-2015'; -- use this format when using ST_DESP_DATE unformatted
      --  end_date IN VARCHAR2(20) := '30-Jun-2015';
      --   start_date IN VARCHAR2(20) := '2015-06-01'; -- use this when ST_DESP_DATE is formatted
      --  end_date IN VARCHAR2(20) := '2015-06-30';
      ,start_date IN VARCHAR2 := F_FIRST_DAY_PREV_MONTH -- use this when you want the date entered automatically
      ,end_date IN VARCHAR2 := F_LAST_DAY_PREV_MONTH
      ,sCust IN RM.RM_CUST%TYPE
      ,sAnalysis IN RM.RM_ANAL%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_ORD_FEES%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		sCourierm         VARCHAR2(20) := 'COURIERM';
    sCouriers         VARCHAR2(20) := 'COURIERS';
    sCourier         VARCHAR2(20) := 'COURIER%';
    sServ8             VARCHAR2(20) := 'SERV8';
    sServ3             VARCHAR2(20) := 'SERV%';
    nRM_XX_FEE01  NUMBER; /*VerbalOrderEntryFee*/
    nRM_XX_FEE02  NUMBER; /*EmailOrderEntryFee*/
    nRM_XX_FEE03  NUMBER; /*PhoneOrderEntryFee*/
    nRM_XX_FEE04  NUMBER; /*PhoneOrderEntryFee*/
    nRM_XX_FEE05  NUMBER; /*PhoneOrderEntryFee*/
    nRM_XX_FEE06  NUMBER; /*Handeling Fee*/
    nRM_XX_FEE07  NUMBER; /*FaxOrderEntryFee*/
    nRM_XX_FEE08  NUMBER; /*InnerPackingFee*/
    nRM_XX_FEE09  NUMBER; /*OuterPackingFee*/
    nRM_XX_FEE10  NUMBER; /*FTPOrderEntryFee*/
    nRM_XX_FEE32_1  NUMBER; /*UnallocatedFee*/
    nRM_XX_FEE25  NUMBER; /*Pallet Destruction Fee*/
    --p2_array_size PLS_INTEGER := D_EOM_GET_CUST_RATES('TABCORP',0);
    --Type rates IS VARRAY(35) OF INTEGER;
    --rates := D_EOM_GET_CUST_RATES('TABCORP');
    --sCust2    VARCHAR2(20) := sCust;
    end_date2 ST.ST_DESP_DATE%TYPE := end_date;
    nbreakpoint   NUMBER;
    --DBMS_OUTPUT.PUT_LINE(start_date || ' - ' || end_date || '.' || sCust );
    --BEGIN
     --D_EOM_GET_CUST_RATES('TABCORP');
    --END
    --BEGIN
    /*
      SELECT To_Number(regexp_substr(RM_XX_FEE01,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE01 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE02,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE02 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE03,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE03 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE04,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE04 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE05,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE05 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE06 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE07,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE07 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE08 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE09 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE10,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE10 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE32_1,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE32_1 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE25 FROM RM where RM_CUST = sCust;
    --END;
   */ 
   

      
      
    
     --END;
     CURSOR c 
    IS 
    

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
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  'Verbal Order Entry Fee'
			  ELSE ''
			  END                     AS "Description",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  1
			  ELSE NULL
			  END                     AS "Qty",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  '1'
			  ELSE ''
			  END                     AS "UOI",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "UnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "OWUnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "DExcl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "Excl_Total",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN   (Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
			  ELSE NULL
			  END                     AS "DIncl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN (Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
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
	WHERE (r.sGroupCust = sCust OR r.sCust = sCust)
  AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
  --AND       t.ST_DESP_DATE >= start_date AND t.ST_DESP_DATE <= end_date
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	AND       s.SH_SPARE_DBL_9 = 4
	AND       d.SD_LINE = 1
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> 0
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> '0'
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) IS NOT NULL
	--AND     nRM_XX_FEE01 > 0
  AND (SELECT To_Number(regexp_substr(RM_XX_FEE01,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0.1
	GROUP BY  s.SH_CUST,r.sGroupCust,i.IM_CUST,s.SH_SPARE_STR_4,i.IM_XX_COST_CENTRE01,
        s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,t.ST_DESP_DATE,s.SH_SPARE_DBL_9,d.SD_LINE,
        s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_NOTE_2,s.SH_SPARE_STR_3,
        i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4,s.SH_SPARE_STR_1,
        d.SD_ORDER,d.SD_STOCK,t.ST_ORDER,t.ST_PICK,s.SH_LAST_PICK_NUM,r.sCust,s.SH_PREV_PSLIP_NUM,i.IM_TYPE,s.SH_STATUS,
        i.IM_BRAND,t.ST_WEIGHT,t.ST_PACKAGES,d.SD_LAST_PICK_NUM
  --UNION ALL
/*Verbal Order Fee*/

  
;

    BEGIN
    

    nCheckpoint := 1;
      v_query := 'TRUNCATE TABLE TMP_ORD_FEES';
      EXECUTE IMMEDIATE v_query;
    
    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
        
        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_ORD_FEES VALUES l_data(i); 
        --USING sCust;
        
        EXIT WHEN c%NOTFOUND;

        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
--       FOR i IN l_data.FIRST .. l_data.LAST LOOP
--        DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
--      END LOOP;

  COMMIT;
  --RETURN;
  DBMS_OUTPUT.PUT_LINE('EOM Temp Order Fees for all customers for the date range ' 
      || start_date || ' -- ' || end_date  || ' run for customer ' || sCust);
    --COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM Temp Order Fees processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;

  END EOM_VERBAL_ORD_FEES;
  
  /*   Run this once for each customer   */
  /*   This gets all the Order Related Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_ORD_FEES   */
  PROCEDURE EOM_TMP_ALL_ORD_FEES_ALL_CUST5 (
      p_array_size IN PLS_INTEGER DEFAULT 100
      -- ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
      -- ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
      --  start_date IN VARCHAR2(20) := '01-Jun-2015'; -- use this format when using ST_DESP_DATE unformatted
      --  end_date IN VARCHAR2(20) := '30-Jun-2015';
      --   start_date IN VARCHAR2(20) := '2015-06-01'; -- use this when ST_DESP_DATE is formatted
      --  end_date IN VARCHAR2(20) := '2015-06-30';
      ,start_date IN VARCHAR2 := F_FIRST_DAY_PREV_MONTH -- use this when you want the date entered automatically
      ,end_date IN VARCHAR2 := F_LAST_DAY_PREV_MONTH
      ,sCust IN RM.RM_CUST%TYPE
      ,sAnalysis IN RM.RM_ANAL%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_ORD_FEES%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		sCourierm         VARCHAR2(20) := 'COURIERM';
    sCouriers         VARCHAR2(20) := 'COURIERS';
    sCourier         VARCHAR2(20) := 'COURIER%';
    sServ8             VARCHAR2(20) := 'SERV8';
    sServ3             VARCHAR2(20) := 'SERV%';
    nRM_XX_FEE01  NUMBER; /*VerbalOrderEntryFee*/
    nRM_XX_FEE02  NUMBER; /*EmailOrderEntryFee*/
    nRM_XX_FEE03  NUMBER; /*PhoneOrderEntryFee*/
    nRM_XX_FEE04  NUMBER; /*PhoneOrderEntryFee*/
    nRM_XX_FEE05  NUMBER; /*PhoneOrderEntryFee*/
    nRM_XX_FEE06  NUMBER; /*Handeling Fee*/
    nRM_XX_FEE07  NUMBER; /*FaxOrderEntryFee*/
    nRM_XX_FEE08  NUMBER; /*InnerPackingFee*/
    nRM_XX_FEE09  NUMBER; /*OuterPackingFee*/
    nRM_XX_FEE10  NUMBER; /*FTPOrderEntryFee*/
    nRM_XX_FEE32_1  NUMBER; /*UnallocatedFee*/
    nRM_XX_FEE25  NUMBER; /*Pallet Destruction Fee*/
    --p2_array_size PLS_INTEGER := D_EOM_GET_CUST_RATES('TABCORP',0);
    --Type rates IS VARRAY(35) OF INTEGER;
    --rates := D_EOM_GET_CUST_RATES('TABCORP');
    --sCust2    VARCHAR2(20) := sCust;
    end_date2 ST.ST_DESP_DATE%TYPE := end_date;
    nbreakpoint   NUMBER;
    --DBMS_OUTPUT.PUT_LINE(start_date || ' - ' || end_date || '.' || sCust );
    --BEGIN
     --D_EOM_GET_CUST_RATES('TABCORP');
    --END
    --BEGIN
    /*
      SELECT To_Number(regexp_substr(RM_XX_FEE01,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE01 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE02,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE02 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE03,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE03 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE04,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE04 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE05,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE05 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE06 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE07,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE07 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE08 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE09 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE10,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE10 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE32_1,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE32_1 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE25 FROM RM where RM_CUST = sCust;
    --END;
   */ 
   

      
      
    
     --END;
     CURSOR c 
    IS 
    	/*PhoneOrderEntryFee*/
    SELECT    s.SH_CUST,r.sGroupCust,
			  CASE    WHEN i.IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
			  WHEN i.IM_CUST = 'TABCORP' THEN i.IM_XX_COST_CENTRE01
			  ELSE s.SH_SPARE_STR_4
			  END,
			  s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,
			  NULL,NULL,NULL,
			  substr(To_Char(t.ST_DESP_DATE),0,10),
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  'OrderEntryFee'
			  ELSE ''
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  'FEEORDERENTRYS'
			  ELSE ''
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  'Phone Order Entry Fee'
			  ELSE ''
			  END,
        CASE    WHEN d.SD_LINE = 1 THEN  1
			  ELSE NULL
			  END,
        CASE    WHEN d.SD_LINE = 1 THEN  '1'
			  ELSE ''
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
			  ELSE NULL
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
			  ELSE NULL
			  END,
			  NULL,
			  s.SH_ADDRESS,s.SH_SUBURB,
			  s.SH_CITY,s.SH_STATE,
			  s.SH_POST_CODE,s.SH_NOTE_1,
			  s.SH_NOTE_2,
        0,0,
			  s.SH_SPARE_DBL_9,
			  NULL,NULL,
				0,
        CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
        ELSE ''
        END,
        'N/A',
        i.IM_OWNED_By,i.IM_PROFILE,
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4
	FROM      PWIN175.SH s
			  INNER JOIN PWIN175.SD d ON d.SD_ORDER  = s.SH_ORDER
			  INNER JOIN PWIN175.IM i ON i.IM_STOCK = d.SD_STOCK
			  INNER JOIN PWIN175.ST t ON t.ST_ORDER = s.SH_ORDER AND t.ST_PICK = s.SH_LAST_PICK_NUM
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
			  --LEFT JOIN PWIN175.RM r2 ON r2.RM_ANAL = r.RM_ANAL AND r2.RM_CUST = :cust
	WHERE (r.sGroupCust = sCust OR r.sCust = sCust)
  AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
  --AND       t.ST_DESP_DATE >= start_date AND t.ST_DESP_DATE <= end_date
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	AND       s.SH_SPARE_DBL_9 = 1
	AND       d.SD_LINE = 1
  AND (SELECT To_Number(regexp_substr(RM_XX_FEE03,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0.1
	GROUP BY   s.SH_CUST,r.sGroupCust,i.IM_CUST,s.SH_SPARE_STR_4,i.IM_XX_COST_CENTRE01,
        s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,t.ST_DESP_DATE,s.SH_SPARE_DBL_9,d.SD_LINE,
        s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_NOTE_2,s.SH_SPARE_STR_3,
        i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4,s.SH_SPARE_STR_1,
        d.SD_ORDER,d.SD_STOCK,t.ST_ORDER,t.ST_PICK,s.SH_LAST_PICK_NUM,r.sCust,s.SH_PREV_PSLIP_NUM,i.IM_TYPE,s.SH_STATUS,
        i.IM_BRAND,t.ST_WEIGHT,t.ST_PACKAGES,d.SD_LAST_PICK_NUM
        
        
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
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "UnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "OWUnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN   (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "DExcl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "Excl_Total",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN   (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
			  ELSE NULL
			  END                     AS "DIncl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN   (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
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
	WHERE (r.sGroupCust = sCust OR r.sCust = sCust)
  AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
  --AND       t.ST_DESP_DATE >= start_date AND t.ST_DESP_DATE <= end_date
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	AND       s.SH_SPARE_DBL_9 = 3
	AND       d.SD_LINE = 1
	--AND       Select rm3.RM_XX_FEE02 from RM rm3 where To_Number(regexp_substr(rm3.RM_XX_FEE02,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0 AND rm3.RM_CUST = :cust
  AND (SELECT To_Number(regexp_substr(RM_XX_FEE02,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0.1
	--AND      nRM_XX_FEE02 > 0 --AND rm3.RM_CUST = :cust
	--AND       (Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust) <> 0
	--AND       (Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust) <> '0'
	--AND       (Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust) IS NOT NULL
	GROUP BY  s.SH_CUST,r.sGroupCust,i.IM_CUST,s.SH_SPARE_STR_4,i.IM_XX_COST_CENTRE01,
        s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,t.ST_DESP_DATE,s.SH_SPARE_DBL_9,d.SD_LINE,
        s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_NOTE_2,s.SH_SPARE_STR_3,
        i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4,s.SH_SPARE_STR_1,
        d.SD_ORDER,d.SD_STOCK,t.ST_ORDER,t.ST_PICK,s.SH_LAST_PICK_NUM,r.sCust,s.SH_PREV_PSLIP_NUM,i.IM_TYPE,s.SH_STATUS,
        i.IM_BRAND,t.ST_WEIGHT,t.ST_PACKAGES,d.SD_LAST_PICK_NUM

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
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "UnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "OWUnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "DExcl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "Excl_Total",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN   (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
			  ELSE NULL
			  END                     AS "DIncl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
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
	WHERE (r.sGroupCust = sCust OR r.sCust = sCust)
  AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
 -- AND       t.ST_DESP_DATE >= start_date AND t.ST_DESP_DATE <= end_date
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	AND       s.SH_SPARE_DBL_9 = 2
	AND       d.SD_LINE = 1
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> 0
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> '0'
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) IS NOT NULL
	--AND      nRM_XX_FEE07 > 0
  AND (SELECT To_Number(regexp_substr(RM_XX_FEE07,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0.1
	GROUP BY   s.SH_CUST,r.sGroupCust,i.IM_CUST,s.SH_SPARE_STR_4,i.IM_XX_COST_CENTRE01,
        s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,t.ST_DESP_DATE,s.SH_SPARE_DBL_9,d.SD_LINE,
        s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_NOTE_2,s.SH_SPARE_STR_3,
        i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4,s.SH_SPARE_STR_1,
        d.SD_ORDER,d.SD_STOCK,t.ST_ORDER,t.ST_PICK,s.SH_LAST_PICK_NUM,r.sCust,s.SH_PREV_PSLIP_NUM,i.IM_TYPE,s.SH_STATUS,
        i.IM_BRAND,t.ST_WEIGHT,t.ST_PACKAGES,d.SD_LAST_PICK_NUM

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
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "UnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "OWUnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "DExcl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "Excl_Total",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN   (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
			  ELSE NULL
			  END                     AS "DIncl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
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
	WHERE (r.sGroupCust = sCust OR r.sCust = sCust)
  AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
  --AND       t.ST_DESP_DATE >= start_date AND t.ST_DESP_DATE <= end_date
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	AND       s.SH_SPARE_DBL_9 = 4
	AND       d.SD_LINE = 1
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> 0
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> '0'
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) IS NOT NULL
	--AND     nRM_XX_FEE01 > 0
  AND (SELECT To_Number(regexp_substr(RM_XX_FEE32_1,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0.1
	GROUP BY  s.SH_CUST,r.sGroupCust,i.IM_CUST,s.SH_SPARE_STR_4,i.IM_XX_COST_CENTRE01,
        s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,t.ST_DESP_DATE,s.SH_SPARE_DBL_9,d.SD_LINE,
        s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_NOTE_2,s.SH_SPARE_STR_3,
        i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4,s.SH_SPARE_STR_1,
        d.SD_ORDER,d.SD_STOCK,t.ST_ORDER,t.ST_PICK,s.SH_LAST_PICK_NUM,r.sCust,s.SH_PREV_PSLIP_NUM,i.IM_TYPE,s.SH_STATUS,
        i.IM_BRAND,t.ST_WEIGHT,t.ST_PACKAGES,d.SD_LAST_PICK_NUM
  UNION ALL


  
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
	  CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN (SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust)
			 ELSE NULL
			 END                      AS "UnitPrice",
	  CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN (SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust)
			 ELSE NULL
			 END                                      AS "OWUnitPrice",
			CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN (SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust)
			 ELSE NULL
			 END                      AS "DExcl",
			  CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN (SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust)
			 ELSE NULL
			 END                                 AS "Excl_Total",
	   CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN (SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * 1.1-- (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust) * 1.1
			 ELSE NULL
			 END                      AS "DIncl",
	   CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN (SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * 1.1 --  (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust)  * 1.1
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
	WHERE  (SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0
  AND       (r.sGroupCust = sCust OR r.sCust = sCust)
  AND       (s.SH_NOTE_1 = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE')
	AND       s.SH_STATUS <> 3
	AND       d.SD_LINE = 1
	--AND       r.RM_ANAL = :sAnalysis
	AND       s.SH_ORDER = t.ST_ORDER
	AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
  --AND       t.ST_DESP_DATE >= start_date AND t.ST_DESP_DATE <= end_date
	
;

    BEGIN
    

    nCheckpoint := 1;
      v_query := 'TRUNCATE TABLE TMP_ORD_FEES';
      EXECUTE IMMEDIATE v_query;
    
    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
        
        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_ORD_FEES VALUES l_data(i); 
        --USING sCust;
        
        EXIT WHEN c%NOTFOUND;

        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
--       FOR i IN l_data.FIRST .. l_data.LAST LOOP
--        DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
--      END LOOP;

  COMMIT;
  --RETURN;
  DBMS_OUTPUT.PUT_LINE('EOM Temp Order Fees for all customers for the date range ' 
      || start_date || ' -- ' || end_date  || ' run for customer ' || sCust);
    --COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM Temp Order Fees processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;

  END EOM_TMP_ALL_ORD_FEES_ALL_CUST5;
  
  /*   Run this once for each customer   */
  /*   This gets all the Order Related Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_ORD_FEES   */
  PROCEDURE EOM_TMP_ALL_ORD_FEES_ALL_CUST (
      p_array_size IN PLS_INTEGER DEFAULT 100
      -- ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
      -- ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
      --  start_date IN VARCHAR2(20) := '01-Jun-2015'; -- use this format when using ST_DESP_DATE unformatted
      --  end_date IN VARCHAR2(20) := '30-Jun-2015';
      --   start_date IN VARCHAR2(20) := '2015-06-01'; -- use this when ST_DESP_DATE is formatted
      --  end_date IN VARCHAR2(20) := '2015-06-30';
      ,start_date IN VARCHAR2 := F_FIRST_DAY_PREV_MONTH -- use this when you want the date entered automatically
      ,end_date IN VARCHAR2 := F_LAST_DAY_PREV_MONTH
      ,sCust IN RM.RM_CUST%TYPE
      ,sAnalysis IN RM.RM_ANAL%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_ORD_FEES%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		sCourierm         VARCHAR2(20) := 'COURIERM';
    sCouriers         VARCHAR2(20) := 'COURIERS';
    sCourier         VARCHAR2(20) := 'COURIER%';
    sServ8             VARCHAR2(20) := 'SERV8';
    sServ3             VARCHAR2(20) := 'SERV%';
    nRM_XX_FEE01  NUMBER; /*VerbalOrderEntryFee*/
    nRM_XX_FEE02  NUMBER; /*EmailOrderEntryFee*/
    nRM_XX_FEE03  NUMBER; /*PhoneOrderEntryFee*/
    nRM_XX_FEE04  NUMBER; /*PhoneOrderEntryFee*/
    nRM_XX_FEE05  NUMBER; /*PhoneOrderEntryFee*/
    nRM_XX_FEE06  NUMBER; /*Handeling Fee*/
    nRM_XX_FEE07  NUMBER; /*FaxOrderEntryFee*/
    nRM_XX_FEE08  NUMBER; /*InnerPackingFee*/
    nRM_XX_FEE09  NUMBER; /*OuterPackingFee*/
    nRM_XX_FEE10  NUMBER; /*FTPOrderEntryFee*/
    nRM_XX_FEE32_1  NUMBER; /*UnallocatedFee*/
    nRM_XX_FEE25  NUMBER; /*Pallet Destruction Fee*/
    --p2_array_size PLS_INTEGER := D_EOM_GET_CUST_RATES('TABCORP',0);
    --Type rates IS VARRAY(35) OF INTEGER;
    --rates := D_EOM_GET_CUST_RATES('TABCORP');
    --sCust2    VARCHAR2(20) := sCust;
    end_date2 ST.ST_DESP_DATE%TYPE := end_date;
    nbreakpoint   NUMBER;
    --DBMS_OUTPUT.PUT_LINE(start_date || ' - ' || end_date || '.' || sCust );
    --BEGIN
     --D_EOM_GET_CUST_RATES('TABCORP');
    --END
    --BEGIN
    /*
      SELECT To_Number(regexp_substr(RM_XX_FEE01,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE01 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE02,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE02 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE03,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE03 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE04,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE04 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE05,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE05 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE06 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE07,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE07 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE08 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE09 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE10,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE10 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE32_1,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE32_1 FROM RM where RM_CUST = sCust;
      SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO nRM_XX_FEE25 FROM RM where RM_CUST = sCust;
    --END;
   */ 
   

      
      
    
     --END;
     CURSOR c 
    IS 
    	/*PhoneOrderEntryFee*/
    SELECT    s.SH_CUST,r.sGroupCust,
			  CASE    WHEN i.IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
			  WHEN i.IM_CUST = 'TABCORP' THEN i.IM_XX_COST_CENTRE01
			  ELSE s.SH_SPARE_STR_4
			  END,
			  s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,
			  NULL,NULL,NULL,
			  substr(To_Char(t.ST_DESP_DATE),0,10),
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  'OrderEntryFee'
			  ELSE ''
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  'FEEORDERENTRYS'
			  ELSE ''
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  'Phone Order Entry Fee'
			  ELSE ''
			  END,
        CASE    WHEN d.SD_LINE = 1 THEN  1
			  ELSE NULL
			  END,
        CASE    WHEN d.SD_LINE = 1 THEN  '1'
			  ELSE ''
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
			  ELSE NULL
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
			  ELSE NULL
			  END,
			  NULL,
			  s.SH_ADDRESS,s.SH_SUBURB,
			  s.SH_CITY,s.SH_STATE,
			  s.SH_POST_CODE,s.SH_NOTE_1,
			  s.SH_NOTE_2,
        0,0,
			  s.SH_SPARE_DBL_9,
			  NULL,NULL,
				0,
        CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
        ELSE ''
        END,
        'N/A',
        i.IM_OWNED_By,i.IM_PROFILE,
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4
	FROM      PWIN175.SH s
			  INNER JOIN PWIN175.SD d ON d.SD_ORDER  = s.SH_ORDER
			  INNER JOIN PWIN175.IM i ON i.IM_STOCK = d.SD_STOCK
			  INNER JOIN PWIN175.ST t ON t.ST_ORDER = s.SH_ORDER AND t.ST_PICK = s.SH_LAST_PICK_NUM
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
			  --LEFT JOIN PWIN175.RM r2 ON r2.RM_ANAL = r.RM_ANAL AND r2.RM_CUST = :cust
	WHERE (r.sGroupCust = sCust OR r.sCust = sCust)
  AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
  --AND       t.ST_DESP_DATE >= start_date AND t.ST_DESP_DATE <= end_date
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	AND       s.SH_SPARE_DBL_9 = 1
	AND       d.SD_LINE = 1
  AND (SELECT To_Number(regexp_substr(RM_XX_FEE03,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0.1
	GROUP BY   s.SH_CUST,r.sGroupCust,i.IM_CUST,s.SH_SPARE_STR_4,i.IM_XX_COST_CENTRE01,
        s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,t.ST_DESP_DATE,s.SH_SPARE_DBL_9,d.SD_LINE,
        s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_NOTE_2,s.SH_SPARE_STR_3,
        i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4,s.SH_SPARE_STR_1,
        d.SD_ORDER,d.SD_STOCK,t.ST_ORDER,t.ST_PICK,s.SH_LAST_PICK_NUM,r.sCust,s.SH_PREV_PSLIP_NUM,i.IM_TYPE,s.SH_STATUS,
        i.IM_BRAND,t.ST_WEIGHT,t.ST_PACKAGES,d.SD_LAST_PICK_NUM
        
        
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
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "UnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "OWUnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN   (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "DExcl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "Excl_Total",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN   (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
			  ELSE NULL
			  END                     AS "DIncl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN   (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
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
	WHERE (r.sGroupCust = sCust OR r.sCust = sCust)
  AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
  --AND       t.ST_DESP_DATE >= start_date AND t.ST_DESP_DATE <= end_date
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	AND       s.SH_SPARE_DBL_9 = 3
	AND       d.SD_LINE = 1
	--AND       Select rm3.RM_XX_FEE02 from RM rm3 where To_Number(regexp_substr(rm3.RM_XX_FEE02,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0 AND rm3.RM_CUST = :cust
  AND (SELECT To_Number(regexp_substr(RM_XX_FEE02,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0.1
	--AND      nRM_XX_FEE02 > 0 --AND rm3.RM_CUST = :cust
	--AND       (Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust) <> 0
	--AND       (Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust) <> '0'
	--AND       (Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust) IS NOT NULL
	GROUP BY  s.SH_CUST,r.sGroupCust,i.IM_CUST,s.SH_SPARE_STR_4,i.IM_XX_COST_CENTRE01,
        s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,t.ST_DESP_DATE,s.SH_SPARE_DBL_9,d.SD_LINE,
        s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_NOTE_2,s.SH_SPARE_STR_3,
        i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4,s.SH_SPARE_STR_1,
        d.SD_ORDER,d.SD_STOCK,t.ST_ORDER,t.ST_PICK,s.SH_LAST_PICK_NUM,r.sCust,s.SH_PREV_PSLIP_NUM,i.IM_TYPE,s.SH_STATUS,
        i.IM_BRAND,t.ST_WEIGHT,t.ST_PACKAGES,d.SD_LAST_PICK_NUM

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
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "UnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "OWUnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "DExcl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "Excl_Total",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN   (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
			  ELSE NULL
			  END                     AS "DIncl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
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
	WHERE (r.sGroupCust = sCust OR r.sCust = sCust)
  AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
 -- AND       t.ST_DESP_DATE >= start_date AND t.ST_DESP_DATE <= end_date
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	AND       s.SH_SPARE_DBL_9 = 2
	AND       d.SD_LINE = 1
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> 0
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> '0'
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) IS NOT NULL
	--AND      nRM_XX_FEE07 > 0
  AND (SELECT To_Number(regexp_substr(RM_XX_FEE07,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0.1
	GROUP BY   s.SH_CUST,r.sGroupCust,i.IM_CUST,s.SH_SPARE_STR_4,i.IM_XX_COST_CENTRE01,
        s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,t.ST_DESP_DATE,s.SH_SPARE_DBL_9,d.SD_LINE,
        s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_NOTE_2,s.SH_SPARE_STR_3,
        i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4,s.SH_SPARE_STR_1,
        d.SD_ORDER,d.SD_STOCK,t.ST_ORDER,t.ST_PICK,s.SH_LAST_PICK_NUM,r.sCust,s.SH_PREV_PSLIP_NUM,i.IM_TYPE,s.SH_STATUS,
        i.IM_BRAND,t.ST_WEIGHT,t.ST_PACKAGES,d.SD_LAST_PICK_NUM

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
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "UnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "OWUnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "DExcl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "Excl_Total",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN   (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
			  ELSE NULL
			  END                     AS "DIncl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
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
	WHERE (r.sGroupCust = sCust OR r.sCust = sCust)
  AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
  --AND       t.ST_DESP_DATE >= start_date AND t.ST_DESP_DATE <= end_date
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	AND       s.SH_SPARE_DBL_9 = 4
	AND       d.SD_LINE = 1
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> 0
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> '0'
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) IS NOT NULL
	--AND     nRM_XX_FEE01 > 0
  AND (SELECT To_Number(regexp_substr(RM_XX_FEE32_1,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0.1
	GROUP BY  s.SH_CUST,r.sGroupCust,i.IM_CUST,s.SH_SPARE_STR_4,i.IM_XX_COST_CENTRE01,
        s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,t.ST_DESP_DATE,s.SH_SPARE_DBL_9,d.SD_LINE,
        s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_NOTE_2,s.SH_SPARE_STR_3,
        i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4,s.SH_SPARE_STR_1,
        d.SD_ORDER,d.SD_STOCK,t.ST_ORDER,t.ST_PICK,s.SH_LAST_PICK_NUM,r.sCust,s.SH_PREV_PSLIP_NUM,i.IM_TYPE,s.SH_STATUS,
        i.IM_BRAND,t.ST_WEIGHT,t.ST_PACKAGES,d.SD_LAST_PICK_NUM
  UNION ALL


  
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
	  CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN (SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust)
			 ELSE NULL
			 END                      AS "UnitPrice",
	  CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN (SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust)
			 ELSE NULL
			 END                                      AS "OWUnitPrice",
			CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN (SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust)
			 ELSE NULL
			 END                      AS "DExcl",
			  CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN (SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust)
			 ELSE NULL
			 END                                 AS "Excl_Total",
	   CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN (SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * 1.1-- (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust) * 1.1
			 ELSE NULL
			 END                      AS "DIncl",
	   CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN (SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * 1.1 --  (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust)  * 1.1
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
	WHERE  (SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0
  AND       (r.sGroupCust = sCust OR r.sCust = sCust)
  AND       (s.SH_NOTE_1 = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE')
	AND       s.SH_STATUS <> 3
	AND       d.SD_LINE = 1
	--AND       r.RM_ANAL = :sAnalysis
	AND       s.SH_ORDER = t.ST_ORDER
	AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
  --AND       t.ST_DESP_DATE >= start_date AND t.ST_DESP_DATE <= end_date
	
;

    BEGIN
    

    nCheckpoint := 1;
      v_query := 'TRUNCATE TABLE TMP_ORD_FEES';
      EXECUTE IMMEDIATE v_query;
    
    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
        
        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_ORD_FEES VALUES l_data(i); 
        --USING sCust;
        
        EXIT WHEN c%NOTFOUND;

        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
--       FOR i IN l_data.FIRST .. l_data.LAST LOOP
--        DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
--      END LOOP;

  COMMIT;
  --RETURN;
  DBMS_OUTPUT.PUT_LINE('EOM Temp Order Fees for all customers for the date range ' 
      || start_date || ' -- ' || end_date  || ' run for customer ' || sCust);
    --COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM Temp Order Fees processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;

  END EOM_TMP_ALL_ORD_FEES_ALL_CUST;
  
  /*   Run this once for each intercompany customer   */
  /*   This gets all the Order Related Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_ORD_FEES   */
  PROCEDURE EOM_TMP_ALL_ORD_FEES_ALL_IC (
      p_array_size IN PLS_INTEGER DEFAULT 100
        ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
        ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
        ,sCust IN RM.RM_CUST%TYPE,
      sAnalysis IN RM.RM_ANAL%TYPE
      
      -- sCust IN RM.RM_CUST%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_ORD_FEES%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		sCourierm         VARCHAR2(20) := 'COURIERM';
    sCouriers         VARCHAR2(20) := 'COURIERS';
    sCourier         VARCHAR2(20) := 'COURIER%';
    sServ8             VARCHAR2(20) := 'SERV8';
    sServ3             VARCHAR2(20) := 'SERV%';
    nRM_XX_FEE01  NUMBER; /*VerbalOrderEntryFee*/
    nRM_XX_FEE02  NUMBER; /*EmailOrderEntryFee*/
    nRM_XX_FEE03  NUMBER; /*PhoneOrderEntryFee*/
    nRM_XX_FEE04  NUMBER; /*PhoneOrderEntryFee*/
    nRM_XX_FEE05  NUMBER; /*PhoneOrderEntryFee*/
    nRM_XX_FEE06  NUMBER; /*Handeling Fee*/
    nRM_XX_FEE07  NUMBER; /*FaxOrderEntryFee*/
    nRM_XX_FEE08  NUMBER; /*InnerPackingFee*/
    nRM_XX_FEE09  NUMBER; /*OuterPackingFee*/
    nRM_XX_FEE10  NUMBER; /*FTPOrderEntryFee*/
    nRM_XX_FEE32_1  NUMBER; /*UnallocatedFee*/
    nRM_XX_FEE25  NUMBER; /*Pallet Destruction Fee*/
    --p2_array_size PLS_INTEGER := D_EOM_GET_CUST_RATES('TABCORP',0);
    --Type rates IS VARRAY(35) OF INTEGER;
    --rates := D_EOM_GET_CUST_RATES('TABCORP');
    --sCust2    VARCHAR2(20) := sCust;
    end_date2 ST.ST_DESP_DATE%TYPE := end_date;
    nbreakpoint   NUMBER;
   
     CURSOR c 
    IS 
    	/*PhoneOrderEntryFee*/
        SELECT    s.SH_CUST               AS "Customer",
			    r.RM_PARENT              AS "Parent",
			  CASE    WHEN i.IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
			  WHEN i.IM_CUST = 'TABCORP' THEN i.IM_XX_COST_CENTRE01
			  ELSE s.SH_SPARE_STR_4
			  END,
			  s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,
			  NULL,NULL,NULL,
			  substr(To_Char(t.ST_DESP_DATE),0,10),
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  'OrderEntryFee'
			  ELSE ''
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  'FEEORDERENTRYS'
			  ELSE ''
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  'Phone Order Entry Fee'
			  ELSE ''
			  END,
        CASE    WHEN d.SD_LINE = 1 THEN  1
			  ELSE NULL
			  END,
        CASE    WHEN d.SD_LINE = 1 THEN  '1'
			  ELSE ''
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
			  ELSE NULL
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
			  ELSE NULL
			  END,
			  NULL,
			  s.SH_ADDRESS,s.SH_SUBURB,
			  s.SH_CITY,s.SH_STATE,
			  s.SH_POST_CODE,s.SH_NOTE_1,
			  s.SH_NOTE_2,
        0,0,
			  s.SH_SPARE_DBL_9,
			  NULL,NULL,
				0,
        CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
        ELSE ''
        END,
        'N/A',
        i.IM_OWNED_By,i.IM_PROFILE,
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4
	FROM      PWIN175.SH s
			    INNER JOIN PWIN175.SD d ON d.SD_ORDER  = s.SH_ORDER
			    INNER JOIN PWIN175.IM i ON i.IM_STOCK = d.SD_STOCK
			    INNER JOIN PWIN175.ST t ON t.ST_ORDER = s.SH_ORDER AND t.ST_PICK = s.SH_LAST_PICK_NUM
			    INNER JOIN PWIN175.RM r ON r.RM_CUST  = s.SH_CUST
			    --LEFT JOIN PWIN175.RM r2 ON r2.RM_ANAL = r.RM_ANAL AND r2.RM_CUST = :cust
	  WHERE r.RM_ANAL = sAnalysis
  AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	AND       s.SH_SPARE_DBL_9 = 1
	AND       d.SD_LINE = 1
  AND (SELECT To_Number(regexp_substr(RM_XX_FEE03,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0.1
	GROUP BY   s.SH_CUST,i.IM_CUST,s.SH_SPARE_STR_4,i.IM_XX_COST_CENTRE01,r.RM_PARENT,
        s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,t.ST_DESP_DATE,s.SH_SPARE_DBL_9,d.SD_LINE,
        s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_NOTE_2,s.SH_SPARE_STR_3,
        i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4,s.SH_SPARE_STR_1,
        d.SD_ORDER,d.SD_STOCK,t.ST_ORDER,t.ST_PICK,s.SH_LAST_PICK_NUM,s.SH_PREV_PSLIP_NUM,i.IM_TYPE,s.SH_STATUS,
        i.IM_BRAND,t.ST_WEIGHT,t.ST_PACKAGES,d.SD_LAST_PICK_NUM
        
        
  UNION ALL
/*PhoneOrderEntryFee*/

/*EmailOrderEntryFee*/
	SELECT    s.SH_CUST               AS "Customer",
			    r.RM_PARENT              AS "Parent",
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
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "UnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "OWUnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN   (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "DExcl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "Excl_Total",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN   (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
			  ELSE NULL
			  END                     AS "DIncl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN   (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
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
			    INNER JOIN PWIN175.RM r ON r.RM_CUST  = s.SH_CUST
			    --LEFT JOIN PWIN175.RM r2 ON r2.RM_ANAL = r.RM_ANAL AND r2.RM_CUST = :cust
	  WHERE (r.RM_ANAL = sAnalysis)
  AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	AND       s.SH_SPARE_DBL_9 = 3
	AND       d.SD_LINE = 1
	--AND       Select rm3.RM_XX_FEE02 from RM rm3 where To_Number(regexp_substr(rm3.RM_XX_FEE02,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0 AND rm3.RM_CUST = :cust
  AND (SELECT To_Number(regexp_substr(RM_XX_FEE02,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0.1
	--AND      nRM_XX_FEE02 > 0 --AND rm3.RM_CUST = :cust
	--AND       (Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust) <> 0
	--AND       (Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust) <> '0'
	--AND       (Select rm3.RM_XX_FEE02 from RM rm3 where rm3.RM_CUST = :cust) IS NOT NULL
	GROUP BY  s.SH_CUST,i.IM_CUST,s.SH_SPARE_STR_4,i.IM_XX_COST_CENTRE01,r.RM_PARENT,
        s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,t.ST_DESP_DATE,s.SH_SPARE_DBL_9,d.SD_LINE,
        s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_NOTE_2,s.SH_SPARE_STR_3,
        i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4,s.SH_SPARE_STR_1,
        d.SD_ORDER,d.SD_STOCK,t.ST_ORDER,t.ST_PICK,s.SH_LAST_PICK_NUM,s.SH_PREV_PSLIP_NUM,i.IM_TYPE,s.SH_STATUS,
        i.IM_BRAND,t.ST_WEIGHT,t.ST_PACKAGES,d.SD_LAST_PICK_NUM

 UNION ALL
/*EmailOrderEntryFee*/

/*FaxOrderEntryFee*/
	SELECT     s.SH_CUST               AS "Customer",
			    r.RM_PARENT              AS "Parent",
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
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "UnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "OWUnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "DExcl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "Excl_Total",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN   (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
			  ELSE NULL
			  END                     AS "DIncl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
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
			    INNER JOIN PWIN175.RM r ON r.RM_CUST  = s.SH_CUST
			    --LEFT JOIN PWIN175.RM r2 ON r2.RM_ANAL = r.RM_ANAL AND r2.RM_CUST = :cust
	  WHERE (r.RM_ANAL = sAnalysis)
  AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	AND       s.SH_SPARE_DBL_9 = 2
	AND       d.SD_LINE = 1
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> 0
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> '0'
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) IS NOT NULL
	--AND      nRM_XX_FEE07 > 0
  AND (SELECT To_Number(regexp_substr(RM_XX_FEE07,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0.1
	GROUP BY   s.SH_CUST,i.IM_CUST,s.SH_SPARE_STR_4,i.IM_XX_COST_CENTRE01,r.RM_PARENT,
        s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,t.ST_DESP_DATE,s.SH_SPARE_DBL_9,d.SD_LINE,
        s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_NOTE_2,s.SH_SPARE_STR_3,
        i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4,s.SH_SPARE_STR_1,
        d.SD_ORDER,d.SD_STOCK,t.ST_ORDER,t.ST_PICK,s.SH_LAST_PICK_NUM,s.SH_PREV_PSLIP_NUM,i.IM_TYPE,s.SH_STATUS,
        i.IM_BRAND,t.ST_WEIGHT,t.ST_PACKAGES,d.SD_LAST_PICK_NUM

   UNION ALL
/*FaxOrderEntryFee*/

/*VerbalOrderEntryFee*/
	SELECT     s.SH_CUST               AS "Customer",
			    r.RM_PARENT              AS "Parent",
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
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "UnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "OWUnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "DExcl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN  (Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END                     AS "Excl_Total",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN   (Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
			  ELSE NULL
			  END                     AS "DIncl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 THEN (Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
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
			    INNER JOIN PWIN175.RM r ON r.RM_CUST  = s.SH_CUST
			    --LEFT JOIN PWIN175.RM r2 ON r2.RM_ANAL = r.RM_ANAL AND r2.RM_CUST = :cust
	  WHERE (r.RM_ANAL = sAnalysis)
  AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	AND       s.SH_SPARE_DBL_9 = 4
	AND       d.SD_LINE = 1
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> 0
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) <> '0'
	--AND       (Select rm3.RM_XX_FEE07 from RM rm3 where rm3.RM_CUST = :cust) IS NOT NULL
	--AND     nRM_XX_FEE01 > 0
  AND (SELECT To_Number(regexp_substr(RM_XX_FEE01,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0.1
	GROUP BY  s.SH_CUST,i.IM_CUST,s.SH_SPARE_STR_4,i.IM_XX_COST_CENTRE01,r.RM_PARENT,
        s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,t.ST_DESP_DATE,s.SH_SPARE_DBL_9,d.SD_LINE,
        s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_NOTE_2,s.SH_SPARE_STR_3,
        i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4,s.SH_SPARE_STR_1,
        d.SD_ORDER,d.SD_STOCK,t.ST_ORDER,t.ST_PICK,s.SH_LAST_PICK_NUM,s.SH_PREV_PSLIP_NUM,i.IM_TYPE,s.SH_STATUS,
        i.IM_BRAND,t.ST_WEIGHT,t.ST_PACKAGES,d.SD_LAST_PICK_NUM
  UNION ALL
/*PhotoFee*/

  
/*Destruction Fee*/
	SELECT     s.SH_CUST               AS "Customer",
			    r.RM_PARENT              AS "Parent",
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
	  CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN (SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust)
			 ELSE NULL
			 END                      AS "UnitPrice",
	  CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN (SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust)
			 ELSE NULL
			 END                                      AS "OWUnitPrice",
			CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN (SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust)
			 ELSE NULL
			 END                      AS "DExcl",
			  CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN (SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust)
			 ELSE NULL
			 END                                 AS "Excl_Total",
	   CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN (SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * 1.1-- (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust) * 1.1
			 ELSE NULL
			 END                      AS "DIncl",
	   CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN (SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * 1.1 --  (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust)  * 1.1
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
			    INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
			    INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
	 WHERE  (SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0
  AND      (r.RM_ANAL = sAnalysis)
  AND       (s.SH_NOTE_1 = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE')
	AND       s.SH_STATUS <> 3
	AND       d.SD_LINE = 1
	--AND       r.RM_ANAL = :sAnalysis
	AND       s.SH_ORDER = t.ST_ORDER
	AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
	
;

    BEGIN
    

    nCheckpoint := 1;
      v_query := 'TRUNCATE TABLE TMP_ORD_FEES';
      EXECUTE IMMEDIATE v_query;
    
    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
        
        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_ORD_FEES VALUES l_data(i); 
        --USING sCust;
        
        EXIT WHEN c%NOTFOUND;

        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
       FOR i IN l_data.FIRST .. l_data.LAST LOOP
        DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
      END LOOP;

  COMMIT;
  --RETURN;
  DBMS_OUTPUT.PUT_LINE('EOM Temp Order Fees for all customers for the date range ' 
      || start_date || ' -- ' || end_date);
    --COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM order fees processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;

  END EOM_TMP_ALL_ORD_FEES_ALL_IC;
 
  /*   Run this once for each customer   */
  /*   This gets all the Handeling Related Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_HAND_FEES   */
  PROCEDURE EOM_TMP_ALL_HAND_FEES_ALL_CUST (
      p_array_size IN PLS_INTEGER DEFAULT 100
        ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
        ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
        ,sCust IN RM.RM_CUST%TYPE,
      sAnalysis IN RM.RM_ANAL%TYPE
      
      -- sCust IN RM.RM_CUST%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_HAND_FEES%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		sCourierm         VARCHAR2(20) := 'COURIERM';
    sCouriers         VARCHAR2(20) := 'COURIERS';
    sCourier         VARCHAR2(20) := 'COURIER%';
    sServ8             VARCHAR2(20) := 'SERV8';
    sServ3             VARCHAR2(20) := 'SERV%';
    
    --p2_array_size PLS_INTEGER := D_EOM_GET_CUST_RATES('TABCORP',0);
    --Type rates IS VARRAY(35) OF INTEGER;
    --rates := D_EOM_GET_CUST_RATES('TABCORP');
    --sCust2    VARCHAR2(20) := sCust;
    end_date2 ST.ST_DESP_DATE%TYPE := end_date;
    nbreakpoint   NUMBER;
   
     CURSOR c 
    IS 
   /*ShrinkWrap Fee*/
	SELECT    s.SH_CUST,
			  r.sGroupCust,
			  CASE    WHEN IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
			  WHEN IM_CUST = 'TABCORP' THEN IM_XX_COST_CENTRE01
			  ELSE s.SH_SPARE_STR_4
			  END,
			  s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,
			  t.ST_PICK,d.SD_XX_PICKLIST_NUM,
			  t.ST_PSLIP,
			  substr(To_Char(t.ST_DESP_DATE),0,10),
        CASE    WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN 'ShrinkWrap Despatch Fee'
        ELSE NULL
        END                      AS "FeeType",
        CASE    WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  'ShrinkWrap Despatch'
        ELSE NULL
        END                     AS "Item",
        CASE    WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  'ShrinkWraping Despatch Fee'
        ELSE NULL
        END                     AS "Description",
        CASE    WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  t.ST_XX_NUM_PAL_SW
        ELSE NULL
        END                     AS "Qty",
        CASE    WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  '1'
        ELSE ''
        END                     AS "UOI",
        CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)
        ELSE null
        END                      AS "UnitPrice",
        CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)
        ELSE null
        END                                           AS "OWUnitPrice",
        CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1  THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)
        ELSE NULL
        END                        AS "DExcl",
        CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN   (SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)
        ELSE NULL
        END                                            AS "Excl_Total",
        CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  * 1.1
        ELSE NULL
        END                                           AS "DIncl",
        CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  * 1.1
        ELSE NULL
        END                                           AS "Incl_Total",
        CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)
        ELSE null
        END                                           AS "ReportingPrice",
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
	WHERE  s.SH_STATUS <> 3
  AND (SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0.1
	AND       (r.sGroupCust = sCust OR r.sCust = sCust)
	AND       s.SH_ORDER = t.ST_ORDER
	AND       (ST_XX_NUM_PAL_SW >= 1)
	AND       d.SD_LINE = 1
	AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date

	GROUP BY  s.SH_CUST,
        r.sGroupCust,
        r.sCust,
			  s.SH_NOTE_1,
			  s.SH_CAMPAIGN,
			  s.SH_SPARE_STR_4,
			  s.SH_ORDER,
			  t.ST_PICK,
			  d.SD_XX_PICKLIST_NUM,
			  t.ST_PSLIP,
			  t.ST_DESP_DATE,
			  t.ST_XX_NUM_PAL_SW,
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
			  s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,
              i.IM_BRAND,i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4


      UNION ALL

	SELECT  s.SH_CUST                AS "Customer",
			r.sGroupCust              AS "Parent",
			s.SH_SPARE_STR_4         AS "CostCentre",
			s.SH_ORDER               AS "Order",
			s.SH_SPARE_STR_5         AS "OrderwareNum",
			s.SH_CUST_REF            AS "CustomerRef",
			t.vSLPickslipNum         AS "Pickslip",
			NULL                     AS "PickNum",
			t.vSLPslip               AS "DespatchNote",
			t.vDateDespSL             AS "DespatchDate",
			CASE    WHEN t.vSLPslip IS NOT NULL THEN 'Pick Fee'
			  ELSE NULL
			  END                      AS "FeeType",
			CASE    WHEN t.vSLPslip IS NOT NULL THEN 'FEEPICK'
			  ELSE NULL
			  END                      AS "Item",
			CASE    WHEN t.vSLPslip IS NOT NULL THEN 'Line Picking Fee'
			  ELSE NULL
			  END                      AS "Description",
        t.nCountOfLines           AS "Qty",
			 CASE    WHEN t.vSLPslip IS NOT NULL THEN  '1'
			  ELSE ''
			  END                     AS "UOI",
			 CASE    WHEN t.vSLPslip IS NOT NULL  AND t.nCountOfLines < = 5  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)

        WHEN t.vSLPslip IS NOT NULL  AND t.nCountOfLines > 5  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE36,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)
 
			  ELSE NULL
			  END                      AS "UnitPrice",
		    CASE  WHEN t.vSLPslip IS NOT NULL  AND t.nCountOfLines < = 5  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)
              WHEN t.vSLPslip IS NOT NULL  AND t.nCountOfLines > 5  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE36,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)
			        ELSE NULL
			        END                                      AS "OWUnitPrice",
			CASE  WHEN t.vSLPslip IS NOT NULL  AND t.nCountOfLines < = 5  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  * t.nCountOfLines
				      WHEN t.vSLPslip IS NOT NULL  AND t.nCountOfLines > 5  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE36,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * t.nCountOfLines
              ELSE NULL
				      END                      AS "DExcl",
					CASE  WHEN t.vSLPslip IS NOT NULL  AND t.nCountOfLines < = 5  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  * t.nCountOfLines
				      WHEN t.vSLPslip IS NOT NULL  AND t.nCountOfLines > 5  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE36,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * t.nCountOfLines
			        ELSE NULL
			        END                                 AS "Excl_Total",
		  CASE    WHEN t.vSLPslip IS NOT NULL  AND t.nCountOfLines < = 5  THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  * t.nCountOfLines) * 1.1
				      WHEN t.vSLPslip IS NOT NULL  AND t.nCountOfLines > 5  THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE36,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * t.nCountOfLines) * 1.1
				      ELSE NULL
				      END                      AS "DIncl",
		  CASE    WHEN t.vSLPslip IS NOT NULL  AND t.nCountOfLines < = 5  THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  * t.nCountOfLines) * 1.1
				      WHEN t.vSLPslip IS NOT NULL  AND t.nCountOfLines > 5  THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE36,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * t.nCountOfLines) * 1.1
				      ELSE NULL
				      END                      AS "Incl_Total",
		  CASE    WHEN t.vSLPslip IS NOT NULL  AND t.nCountOfLines < = 5  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  * t.nCountOfLines
				      WHEN t.vSLPslip IS NOT NULL  AND t.nCountOfLines > 5  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE36,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * t.nCountOfLines
			        ELSE NULL
				      END                      AS "ReportingPrice",
			s.SH_ADDRESS             AS "Address",
			s.SH_SUBURB              AS "Address2",
			s.SH_CITY                AS "Suburb",
			s.SH_STATE               AS "State",
			s.SH_POST_CODE           AS "Postcode",
			s.SH_NOTE_1              AS "DeliverTo",
			s.SH_NOTE_2              AS "AttentionTo" ,
			t.vWeightSL              AS "Weight",
			t.vPackagesSL            AS "Packages",
			s.SH_SPARE_DBL_9         AS "OrderSource",
			NULL                     AS "Pallet/Shelf Space",
			  NULL                     AS "Locn",
			  0                     AS "CountOfStocks",
        CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			        ELSE ''
			        END AS Email,
              'N/A' AS Brand,
           NULL AS    OwnedBy,
           NULL AS    sProfile,
           NULL AS    WaiveFee,
           NULL As   Cost,
           s.SH_SPARE_INT_4 AS PaymentType

	FROM  Tmp_Admin_Data_Pick_LineCounts t LEFT JOIN PWIN175.SH s ON  LTrim(s.SH_ORDER) = t.vSLOrderNum
	LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
	WHERE   s.SH_STATUS <> 3
  AND (r.sGroupCust = sCust OR r.sCust = sCust)
  AND (SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0.1
	
	GROUP BY  s.SH_ORDER,
			  r.sGroupCust,
        r.sCust,
			  s.SH_SPARE_STR_4,
			  s.SH_CUST,
			  t.vSLPickslipNum,
			  t.vSLPslip,
			  t.vDateDespSL,
			  s.SH_EXCL,
			  s.SH_INCL,
			  s.SH_ADDRESS,
			  s.SH_SUBURB,
			  s.SH_CITY,
			  s.SH_STATE,
			  s.SH_POST_CODE,
			  s.SH_NOTE_1,
			  s.SH_NOTE_2 ,
			  s.SH_NUM_LINES,
			  t.vWeightSL,
			  t.vPackagesSL,
			  s.SH_SPARE_DBL_9,
			  t.nCountOfLines,
			  r.sGroupCust,
			  s.SH_SPARE_STR_5,
			  s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,s.SH_SPARE_INT_4

  UNION ALL
  
    /*Handeling Fee*/
	  SELECT    s.SH_CUST                AS "Customer",
			     r.sGroupCust              AS "Parent",
			   s.SH_SPARE_STR_4          AS "CostCentre",
			    s.SH_ORDER               AS "Order",
			    s.SH_SPARE_STR_5         AS "OrderwareNum",
			    s.SH_CUST_REF            AS "CustomerRef",
			    t.vSLPickslipNum         AS "Pickslip",
			  NULL                     AS "PickNum",
			  t.vSLPslip               AS "DespatchNote",
			  t.vDateDespSL             AS "DespatchDate",
	    CASE    WHEN t.vSLPslip IS NOT NULL THEN 'Handeling Fee is '
			    ELSE NULL
			    END                      AS "FeeType",
	    CASE    WHEN t.vSLPslip IS NOT NULL THEN  'Handeling'
			    ELSE NULL
			    END                     AS "Item",
	    CASE    WHEN t.vSLPslip IS NOT NULL THEN  'Handeling Fee'
			    ELSE NULL
			    END                     AS "Description",
	    CASE    WHEN t.vSLPslip IS NOT NULL THEN  1
			    ELSE NULL
			    END                     AS "Qty",
	    CASE    WHEN t.vSLPslip IS NOT NULL THEN  '1'
			    ELSE ''
			    END                     AS "UOI",
	    CASE    WHEN t.vSLPslip IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)
			    ELSE NULL
			    END                      AS "UnitPrice",
	    CASE    WHEN t.vSLPslip IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)
			    ELSE NULL
			    END                                      AS "OWUnitPrice",
			  CASE    WHEN t.vSLPslip IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)
			    ELSE NULL
			    END                      AS "DExcl",
			  CASE    WHEN t.vSLPslip IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)
			    ELSE NULL
			    END                                 AS "Excl_Total",
	    CASE    WHEN t.vSLPslip IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * 1.1
			    ELSE NULL
			    END                      AS "DIncl",
	    CASE    WHEN t.vSLPslip IS NOT NULL THEN   (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  * 1.1
			    ELSE NULL
			    END                      AS "Incl_Total",
	    CASE    WHEN t.vSLPslip IS NOT NULL THEN  (Select To_Number(i.IM_REPORTING_PRICE) from IM i where i.IM_STOCK = 'COURIERM')
			    ELSE NULL
			    END                      AS "ReportingPrice",
			  s.SH_ADDRESS             AS "Address",
			    s.SH_SUBURB              AS "Address2",
			    s.SH_CITY                AS "Suburb",
			    s.SH_STATE               AS "State",
			    s.SH_POST_CODE           AS "Postcode",
			    s.SH_NOTE_1              AS "DeliverTo",
			    s.SH_NOTE_2              AS "AttentionTo" ,
			  t.vWeightSL              AS "Weight",
			  t.vPackagesSL            AS "Packages",
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
           NULL As   Cost,
           s.SH_SPARE_INT_4 AS PaymentType



	  FROM  Tmp_Admin_Data_Pick_LineCounts t LEFT JOIN PWIN175.SH s ON  LTrim(s.SH_ORDER) = LTrim(t.vSLOrderNum)
	  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
		  WHERE  s.SH_STATUS <> 3
    AND (r.sGroupCust = sCust OR r.sCust = sCust)
     AND (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0.1
    AND t.vSLPslip <> 'CANCELLED'
	  GROUP BY   s.SH_ORDER,
			  r.sGroupCust,
        r.sCust,
			  s.SH_SPARE_STR_4,
			  s.SH_CUST,
			  t.vSLPickslipNum,
			  t.vSLPslip,
			  t.vDateDespSL,
			  s.SH_ADDRESS,
			  s.SH_SUBURB,
			  s.SH_CITY,
			  s.SH_STATE,
			  s.SH_POST_CODE,
			  s.SH_NOTE_1,
			  s.SH_NOTE_2,
			  t.vWeightSL,
			  t.vPackagesSL,
			  s.SH_SPARE_DBL_9,
			  t.nCountOfLines,
			  r.sGroupCust,
			  s.SH_SPARE_STR_5,
			  s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,s.SH_SPARE_INT_4



  	UNION ALL
/*Handeling Fee*/

/*Stocks*/

SELECT    s.SH_CUST                AS "Customer",
			  r.sGroupCust              AS "Parent",
	   CASE   WHEN i.IM_CUST <> 'TABCORP' AND s.SH_SPARE_STR_4 IS NULL THEN s.SH_CUST
            WHEN i.IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
			      WHEN i.IM_CUST = 'TABCORP' THEN i.IM_XX_COST_CENTRE01
			      ELSE i.IM_XX_COST_CENTRE01
			      END                      AS "CostCentre",
		 s.SH_ORDER               AS "Order",
		 s.SH_SPARE_STR_5         AS "OrderwareNum",
		 s.SH_CUST_REF            AS "CustomerRef",
		 t.ST_PICK                AS "Pickslip",
		 d.SD_XX_PICKLIST_NUM     AS "PickNum",
		 t.ST_PSLIP               AS "DespatchNote",
			  substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	   CASE    WHEN d.SD_STOCK IS NOT NULL THEN 'Stock'
			    ELSE NULL
			    END                      AS "FeeType",
			  d.SD_STOCK               AS "Item",
			  d.SD_DESC                AS "Description",
			  l.SL_PSLIP_QTY           AS "Qty",
			  d.SD_QTY_UNIT            AS "UOI",
	   CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN n.NI_SELL_VALUE/n.NI_NX_QUANTITY --TO_NUMBER(d.SD_SELL_PRICE)
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1 THEN n.NI_SELL_VALUE/n.NI_NX_QUANTITY
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK) IS NOT NULL THEN eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK)
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			      ELSE NULL
			      END                        AS "Batch/UnitPrice",
	   CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN To_Number(i.IM_REPORTING_PRICE)
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN  eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK)
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			      ELSE NULL
			      END                        AS "OWUnitPrice",
      CASE  WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN d.SD_SELL_PRICE * l.SL_PSLIP_QTY
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1 THEN (n.NI_SELL_VALUE/n.NI_NX_QUANTITY) * l.SL_PSLIP_QTY
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK) IS NOT NULL THEN  eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK) * l.SL_PSLIP_QTY
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE * l.SL_PSLIP_QTY
			      ELSE NULL
			      END          AS "DExcl",

	   CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN To_Number(i.IM_REPORTING_PRICE)
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN  eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK)
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			      ELSE NULL
			      END                       AS "Excl_Total",
	  CASE    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN (d.SD_SELL_PRICE * l.SL_PSLIP_QTY) * 1.1
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1  THEN  ((n.NI_SELL_VALUE/n.NI_NX_QUANTITY) * l.SL_PSLIP_QTY) * 1.1
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK) IS NOT NULL THEN  (eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK) * l.SL_PSLIP_QTY) * 1.1
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK) IS NULL THEN  (d.SD_XX_OW_UNIT_PRICE * l.SL_PSLIP_QTY) * 1.1
			      ELSE NULL
			      END          AS "DIncl",
	   CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN (d.SD_SELL_PRICE * l.SL_PSLIP_QTY) * 1.1
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1 THEN  ((n.NI_SELL_VALUE/n.NI_NX_QUANTITY) * l.SL_PSLIP_QTY) * 1.1
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK) IS NOT NULL THEN  (eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK) * l.SL_PSLIP_QTY) * 1.1
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK) IS NULL THEN  (d.SD_XX_OW_UNIT_PRICE * l.SL_PSLIP_QTY) * 1.1
			      ELSE NULL
			      END          AS "Incl_Total",
	  CASE    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN To_Number(i.IM_REPORTING_PRICE)
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN  eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK)
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			      ELSE NULL
			      END                    AS "ReportingPrice",
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
    CASE   WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			     ELSE ''
			     END AS Email,
    i.IM_BRAND AS Brand,
    NULL AS OwnedBy,
    NULL AS sProfile,
    NULL AS WaiveFee,
    NULL AS Cost,
    NULL AS PaymentType
	FROM      PWIN175.SD d
			  RIGHT JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  LEFT JOIN PWIN175.ST t  ON t.ST_PICK  = d.SD_LAST_PICK_NUM
        LEFT JOIN PWIN175.SL l   ON l.SL_PICK   = t.ST_PICK
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
        INNER JOIN PWIN175.NI n  ON n.NI_NV_EXT_KEY = l.SL_UID
  WHERE NI_NV_EXT_TYPE = 1810105 AND NI_STRENGTH = 3 AND NI_DATE = t.ST_DESP_DATE AND NI_STOCK = d.SD_STOCK AND NI_STATUS <> 0
	AND     s.SH_STATUS <> 3
  AND     i.IM_CUST  = sCust
	AND       s.SH_ORDER = t.ST_ORDER
	AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
	AND       d.SD_LAST_PICK_NUM = t.ST_PICK
	GROUP BY  s.SH_CUST,
			  s.SH_NOTE_1,
			  s.SH_CAMPAIGN,
			  s.SH_SPARE_STR_4,
			  i.IM_XX_COST_CENTRE01,
			  i.IM_CUST,
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
			  r.sGroupCust,
			  s.SH_SPARE_STR_5,
			  s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,
			  d.SD_SELL_PRICE,
			  i.IM_OWNED_BY,
			  d.SD_QTY_DESP,
        n.NI_SELL_VALUE,
        n.NI_NX_QUANTITY,
              i.IM_BRAND,
              l.SL_PSLIP_QTY   --2.6s
 
    UNION ALL
    
    SELECT    s.SH_CUST                AS "Customer",
			  r.sGroupCust              AS "Parent",
			  i.IM_XX_COST_CENTRE01         AS "CostCentre",
			  s.SH_ORDER               AS "Order",
			  s.SH_SPARE_STR_5         AS "OrderwareNum",
			  s.SH_CUST_REF            AS "CustomerRef",
			  t.ST_PICK                AS "Pickslip",
			  d.SD_XX_PICKLIST_NUM     AS "PickNum",
			  t.ST_PSLIP               AS "DespatchNote",
			  substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	  CASE    WHEN (i.IM_XX_QTY_PER_PACK IS NOT NULL AND (d.SD_STOCK NOT like 'COURIER%' AND d.SD_STOCK NOT like 'FEE%'))  THEN 'Packing Fee'
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
	   CASE   WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN (SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCust)
			 WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCust)
			 ELSE NULL
			 END                      AS "UnitPrice",
	   CASE   WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN (SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) --(Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCust)
			 WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCust)
			 ELSE NULL
			 END                                          AS "OWUnitPrice",
			  CASE  WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN (SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * d.SD_QTY_DESP -- (Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCust)  * d.SD_QTY_DESP
			 WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * d.SD_QTY_DESP --- (Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCust)  * d.SD_QTY_DESP
			 ELSE NULL
			 END                      AS "DExcl",
			  CASE   WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * d.SD_QTY_DESP --(Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCust)
			 WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * d.SD_QTY_DESP -- (Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCust)
			 ELSE NULL
			 END                                          AS "Excl_Total",
		CASE WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * d.SD_QTY_DESP) * 1.1 -- ((Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCust) * d.SD_QTY_DESP) * 1.1
			 WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * d.SD_QTY_DESP) * 1.1 --  ((Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCust) * d.SD_QTY_DESP) * 1.1
			 ELSE NULL
			 END                      AS "DIncl",
		CASE WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN  ((SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * d.SD_QTY_DESP) * 1.1 -- ((Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCust) * d.SD_QTY_DESP) * 1.1
			 WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * d.SD_QTY_DESP) * 1.1 -- ((Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCust) * d.SD_QTY_DESP) * 1.1
			 ELSE NULL
			 END                      AS "Incl_Total",
	  CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN (Select i.IM_REPORTING_PRICE from IM i where i.IM_STOCK = d.SD_STOCK)
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
           NULL AS    OwnedBy,
           NULL AS    sProfile,
           NULL AS    WaiveFee,
           NULL As   Cost,
           s.SH_SPARE_INT_4 AS PaymentType



	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER  AND t.ST_PICK = d.SD_LAST_PICK_NUM
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
        INNER JOIN RM ON RM_CUST = i.IM_CUST
	WHERE     Upper(i.IM_XX_QTY_PER_PACK) IN ('INNER','OUTER')
	AND       i.IM_CUST = sCust
	AND       s.SH_STATUS <> 3
	AND       s.SH_ORDER = t.ST_ORDER
	AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
	

	
;

    BEGIN
    

    nCheckpoint := 1;
      v_query := 'TRUNCATE TABLE TMP_HAND_FEES';
      EXECUTE IMMEDIATE v_query;
    
    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
        
        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_HAND_FEES VALUES l_data(i); 
        --USING sCust;
        
        EXIT WHEN c%NOTFOUND;

        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
      -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
      --END LOOP;

  COMMIT;
  --RETURN;
  DBMS_OUTPUT.PUT_LINE('EOM Temp Handeling Fees for all customers for the date range ' 
      || start_date || ' -- ' || end_date);
    --COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM Handeling fees processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;

  END EOM_TMP_ALL_HAND_FEES_ALL_CUST;
  
  /*   Run this once for each intercompany customer   */
  /*   This gets all the Handeling Related Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_HAND_FEES   */
  PROCEDURE EOM_TMP_ALL_HAND_FEES_ALL_IC (
      p_array_size IN PLS_INTEGER DEFAULT 100
        ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
        ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
        ,sCust IN RM.RM_CUST%TYPE,
      sAnalysis IN RM.RM_ANAL%TYPE
      
      -- sCust IN RM.RM_CUST%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_HAND_FEES%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		sCourierm         VARCHAR2(20) := 'COURIERM';
    sCouriers         VARCHAR2(20) := 'COURIERS';
    sCourier         VARCHAR2(20) := 'COURIER%';
    sServ8             VARCHAR2(20) := 'SERV8';
    sServ3             VARCHAR2(20) := 'SERV%';
    
    --p2_array_size PLS_INTEGER := D_EOM_GET_CUST_RATES('TABCORP',0);
    --Type rates IS VARRAY(35) OF INTEGER;
    --rates := D_EOM_GET_CUST_RATES('TABCORP');
    --sCust2    VARCHAR2(20) := sCust;
    end_date2 ST.ST_DESP_DATE%TYPE := end_date;
    nbreakpoint   NUMBER;
   
     CURSOR c 
    IS 
   /*ShrinkWrap Fee*/
	SELECT    s.SH_CUST                AS "Customer",
			    r.RM_PARENT              AS "Parent",
			  CASE    WHEN IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
			  WHEN IM_CUST = 'TABCORP' THEN IM_XX_COST_CENTRE01
			  ELSE s.SH_SPARE_STR_4
			  END,
			  s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,
			  t.ST_PICK,d.SD_XX_PICKLIST_NUM,
			  t.ST_PSLIP,
			  substr(To_Char(t.ST_DESP_DATE),0,10),
        CASE    WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN 'ShrinkWrap Despatch Fee'
        ELSE NULL
        END                      AS "FeeType",
        CASE    WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  'ShrinkWrap Despatch'
        ELSE NULL
        END                     AS "Item",
        CASE    WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  'ShrinkWraping Despatch Fee'
        ELSE NULL
        END                     AS "Description",
        CASE    WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  t.ST_XX_NUM_PAL_SW
        ELSE NULL
        END                     AS "Qty",
        CASE    WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  '1'
        ELSE ''
        END                     AS "UOI",
        CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)
        ELSE null
        END                      AS "UnitPrice",
        CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)
        ELSE null
        END                                           AS "OWUnitPrice",
        CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1  THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)
        ELSE NULL
        END                        AS "DExcl",
        CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN   (SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)
        ELSE NULL
        END                                            AS "Excl_Total",
        CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  * 1.1
        ELSE NULL
        END                                           AS "DIncl",
        CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  * 1.1
        ELSE NULL
        END                                           AS "Incl_Total",
        CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)
        ELSE null
        END                                           AS "ReportingPrice",
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
			    INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
			    INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
	  WHERE  (SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0.1
	  AND       s.SH_STATUS <> 3
	  AND       (r.RM_ANAL = sAnalysis)
	AND       s.SH_ORDER = t.ST_ORDER
	AND       (ST_XX_NUM_PAL_SW >= 1)
	AND       d.SD_LINE = 1
	AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date

	GROUP BY  s.SH_CUST,
        s.SH_NOTE_1,r.RM_PARENT,
			  s.SH_CAMPAIGN,
			  s.SH_SPARE_STR_4,
			  s.SH_ORDER,
			  t.ST_PICK,
			  d.SD_XX_PICKLIST_NUM,
			  t.ST_PSLIP,
			  t.ST_DESP_DATE,
			  t.ST_XX_NUM_PAL_SW,
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
			  --r.sGroupCust,
			  s.SH_SPARE_STR_5,
			  s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,
              i.IM_BRAND,i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4


      UNION ALL

	SELECT  s.SH_CUST                AS "Customer",
			  r.RM_PARENT              AS "Parent",
			s.SH_SPARE_STR_4         AS "CostCentre",
			s.SH_ORDER               AS "Order",
			s.SH_SPARE_STR_5         AS "OrderwareNum",
			s.SH_CUST_REF            AS "CustomerRef",
			t.vSLPickslipNum         AS "Pickslip",
			NULL                     AS "PickNum",
			t.vSLPslip               AS "DespatchNote",
			t.vDateDespSL             AS "DespatchDate",
			CASE    WHEN t.vSLPslip IS NOT NULL THEN 'Pick Fee'
			  ELSE NULL
			  END                      AS "FeeType",
			CASE    WHEN t.vSLPslip IS NOT NULL THEN 'FEEPICK'
			  ELSE NULL
			  END                      AS "Item",
			CASE    WHEN t.vSLPslip IS NOT NULL THEN 'Line Picking Fee'
			  ELSE NULL
			  END                      AS "Description",
        t.nCountOfLines           AS "Qty",
			 CASE    WHEN t.vSLPslip IS NOT NULL THEN  '1'
			  ELSE ''
			  END                     AS "UOI",
			 CASE    WHEN t.vSLPslip IS NOT NULL  AND t.nCountOfLines < = 5  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)

        WHEN t.vSLPslip IS NOT NULL  AND t.nCountOfLines > 5  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE36,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)
 
			  ELSE NULL
			  END                      AS "UnitPrice",
		    CASE  WHEN t.vSLPslip IS NOT NULL  AND t.nCountOfLines < = 5  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)
              WHEN t.vSLPslip IS NOT NULL  AND t.nCountOfLines > 5  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE36,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)
			        ELSE NULL
			        END                                      AS "OWUnitPrice",
			CASE  WHEN t.vSLPslip IS NOT NULL  AND t.nCountOfLines < = 5  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  * t.nCountOfLines
				      WHEN t.vSLPslip IS NOT NULL  AND t.nCountOfLines > 5  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE36,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * t.nCountOfLines
              ELSE NULL
				      END                      AS "DExcl",
					CASE  WHEN t.vSLPslip IS NOT NULL  AND t.nCountOfLines < = 5  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  * t.nCountOfLines
				      WHEN t.vSLPslip IS NOT NULL  AND t.nCountOfLines > 5  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE36,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * t.nCountOfLines
			        ELSE NULL
			        END                                 AS "Excl_Total",
		  CASE    WHEN t.vSLPslip IS NOT NULL  AND t.nCountOfLines < = 5  THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  * t.nCountOfLines) * 1.1
				      WHEN t.vSLPslip IS NOT NULL  AND t.nCountOfLines > 5  THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE36,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * t.nCountOfLines) * 1.1
				      ELSE NULL
				      END                      AS "DIncl",
		  CASE    WHEN t.vSLPslip IS NOT NULL  AND t.nCountOfLines < = 5  THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  * t.nCountOfLines) * 1.1
				      WHEN t.vSLPslip IS NOT NULL  AND t.nCountOfLines > 5  THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE36,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * t.nCountOfLines) * 1.1
				      ELSE NULL
				      END                      AS "Incl_Total",
		  CASE    WHEN t.vSLPslip IS NOT NULL  AND t.nCountOfLines < = 5  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  * t.nCountOfLines
				      WHEN t.vSLPslip IS NOT NULL  AND t.nCountOfLines > 5  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE36,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * t.nCountOfLines
			        ELSE NULL
				      END                      AS "ReportingPrice",
			s.SH_ADDRESS             AS "Address",
			s.SH_SUBURB              AS "Address2",
			s.SH_CITY                AS "Suburb",
			s.SH_STATE               AS "State",
			s.SH_POST_CODE           AS "Postcode",
			s.SH_NOTE_1              AS "DeliverTo",
			s.SH_NOTE_2              AS "AttentionTo" ,
			t.vWeightSL              AS "Weight",
			t.vPackagesSL            AS "Packages",
			s.SH_SPARE_DBL_9         AS "OrderSource",
			NULL                     AS "Pallet/Shelf Space",
			  NULL                     AS "Locn",
			  0                     AS "CountOfStocks",
        CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			        ELSE ''
			        END AS Email,
              'N/A' AS Brand,
           NULL AS    OwnedBy,
           NULL AS    sProfile,
           NULL AS    WaiveFee,
           NULL As   Cost,
           s.SH_SPARE_INT_4 AS PaymentType

	FROM  Tmp_Admin_Data_Pick_LineCounts t LEFT JOIN PWIN175.SH s ON  LTrim(s.SH_ORDER) = t.vSLOrderNum
	  INNER JOIN RM r ON r.RM_CUST = s.SH_CUST
	  WHERE  (SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0.1
	  AND  s.SH_STATUS <> 3
    AND (r.RM_ANAL = sAnalysis)
    AND t.vSLPslip <> 'CANCELLED'
	GROUP BY  s.SH_ORDER,r.RM_PARENT,
			  s.SH_SPARE_STR_4,
			  s.SH_CUST,
			  t.vSLPickslipNum,
			  t.vSLPslip,
			  t.vDateDespSL,
			  s.SH_EXCL,
			  s.SH_INCL,
			  s.SH_ADDRESS,
			  s.SH_SUBURB,
			  s.SH_CITY,
			  s.SH_STATE,
			  s.SH_POST_CODE,
			  s.SH_NOTE_1,
			  s.SH_NOTE_2 ,
			  s.SH_NUM_LINES,
			  t.vWeightSL,
			  t.vPackagesSL,
			  s.SH_SPARE_DBL_9,
			  t.nCountOfLines,
			  --r.sGroupCust,
			  s.SH_SPARE_STR_5,
			  s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,s.SH_SPARE_INT_4

  UNION ALL
  
    /*Handeling Fee*/
	  SELECT    s.SH_CUST                AS "Customer",
			    r.RM_PARENT              AS "Parent",
			   s.SH_SPARE_STR_4          AS "CostCentre",
			    s.SH_ORDER               AS "Order",
			    s.SH_SPARE_STR_5         AS "OrderwareNum",
			    s.SH_CUST_REF            AS "CustomerRef",
			    t.vSLPickslipNum         AS "Pickslip",
			  NULL                     AS "PickNum",
			  t.vSLPslip               AS "DespatchNote",
			  t.vDateDespSL             AS "DespatchDate",
	    CASE    WHEN t.vSLPslip IS NOT NULL THEN 'Handeling Fee is '
			    ELSE NULL
			    END                      AS "FeeType",
	    CASE    WHEN t.vSLPslip IS NOT NULL THEN  'Handeling'
			    ELSE NULL
			    END                     AS "Item",
	    CASE    WHEN t.vSLPslip IS NOT NULL THEN  'Handeling Fee'
			    ELSE NULL
			    END                     AS "Description",
	    CASE    WHEN t.vSLPslip IS NOT NULL THEN  1
			    ELSE NULL
			    END                     AS "Qty",
	    CASE    WHEN t.vSLPslip IS NOT NULL THEN  '1'
			    ELSE ''
			    END                     AS "UOI",
	    CASE    WHEN t.vSLPslip IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)
			    ELSE NULL
			    END                      AS "UnitPrice",
	    CASE    WHEN t.vSLPslip IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)
			    ELSE NULL
			    END                                      AS "OWUnitPrice",
			  CASE    WHEN t.vSLPslip IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)
			    ELSE NULL
			    END                      AS "DExcl",
			  CASE    WHEN t.vSLPslip IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)
			    ELSE NULL
			    END                                 AS "Excl_Total",
	    CASE    WHEN t.vSLPslip IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * 1.1
			    ELSE NULL
			    END                      AS "DIncl",
	    CASE    WHEN t.vSLPslip IS NOT NULL THEN   (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  * 1.1
			    ELSE NULL
			    END                      AS "Incl_Total",
	    CASE    WHEN t.vSLPslip IS NOT NULL THEN  (Select To_Number(i.IM_REPORTING_PRICE) from IM i where i.IM_STOCK = 'COURIERM')
			    ELSE NULL
			    END                      AS "ReportingPrice",
			  s.SH_ADDRESS             AS "Address",
			    s.SH_SUBURB              AS "Address2",
			    s.SH_CITY                AS "Suburb",
			    s.SH_STATE               AS "State",
			    s.SH_POST_CODE           AS "Postcode",
			    s.SH_NOTE_1              AS "DeliverTo",
			    s.SH_NOTE_2              AS "AttentionTo" ,
			  t.vWeightSL              AS "Weight",
			  t.vPackagesSL            AS "Packages",
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
           NULL As   Cost,
           s.SH_SPARE_INT_4 AS PaymentType



	  FROM  Tmp_Admin_Data_Pick_LineCounts t LEFT JOIN PWIN175.SH s ON  LTrim(s.SH_ORDER) = LTrim(t.vSLOrderNum)
	  INNER JOIN RM r ON r.RM_CUST = s.SH_CUST
		  WHERE  (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0.1
	  AND  s.SH_STATUS <> 3
    AND (r.RM_ANAL = sAnalysis)
    AND t.vSLPslip <> 'CANCELLED'
	  GROUP BY   s.SH_ORDER,r.RM_PARENT,
			  --r.sGroupCust,
        --r.sCust,
			  s.SH_SPARE_STR_4,
			  s.SH_CUST,
			  t.vSLPickslipNum,
			  t.vSLPslip,
			  t.vDateDespSL,
			  s.SH_ADDRESS,
			  s.SH_SUBURB,
			  s.SH_CITY,
			  s.SH_STATE,
			  s.SH_POST_CODE,
			  s.SH_NOTE_1,
			  s.SH_NOTE_2,
			  t.vWeightSL,
			  t.vPackagesSL,
			  s.SH_SPARE_DBL_9,
			  t.nCountOfLines,
			  --r.sGroupCust,
			  s.SH_SPARE_STR_5,
			  s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,s.SH_SPARE_INT_4



  	UNION ALL
/*Handeling Fee*/

/*Stocks*/

SELECT    s.SH_CUST                AS "Customer",
			    r.RM_PARENT              AS "Parent",
	   CASE   WHEN i.IM_CUST <> 'TABCORP' AND s.SH_SPARE_STR_4 IS NULL THEN s.SH_CUST
            WHEN i.IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
			      WHEN i.IM_CUST = 'TABCORP' THEN i.IM_XX_COST_CENTRE01
			      ELSE i.IM_XX_COST_CENTRE01
			      END                      AS "CostCentre",
		 s.SH_ORDER               AS "Order",
		 s.SH_SPARE_STR_5         AS "OrderwareNum",
		 s.SH_CUST_REF            AS "CustomerRef",
		 t.ST_PICK                AS "Pickslip",
		 d.SD_XX_PICKLIST_NUM     AS "PickNum",
		 t.ST_PSLIP               AS "DespatchNote",
			  substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	   CASE    WHEN d.SD_STOCK IS NOT NULL THEN 'Stock'
			    ELSE NULL
			    END                      AS "FeeType",
			  d.SD_STOCK               AS "Item",
			  d.SD_DESC                AS "Description",
			  l.SL_PSLIP_QTY           AS "Qty",
			  d.SD_QTY_UNIT            AS "UOI",
	   CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN n.NI_SELL_VALUE/n.NI_NX_QUANTITY --TO_NUMBER(d.SD_SELL_PRICE)
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1 THEN n.NI_SELL_VALUE/n.NI_NX_QUANTITY
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND eom_report_pkg.F_BREAK_UNIT_PRICE('TABCORP',d.SD_STOCK) IS NOT NULL THEN eom_report_pkg.F_BREAK_UNIT_PRICE('TABCORP',d.SD_STOCK)
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND eom_report_pkg.F_BREAK_UNIT_PRICE('TABCORP',d.SD_STOCK) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			      ELSE NULL
			      END                        AS "Batch/UnitPrice",
	   CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN To_Number(i.IM_REPORTING_PRICE)
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN  eom_report_pkg.F_BREAK_UNIT_PRICE('TABCORP',d.SD_STOCK)
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND eom_report_pkg.F_BREAK_UNIT_PRICE('TABCORP',d.SD_STOCK) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			      ELSE NULL
			      END                        AS "OWUnitPrice",
      CASE  WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN d.SD_SELL_PRICE * l.SL_PSLIP_QTY
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1 THEN (n.NI_SELL_VALUE/n.NI_NX_QUANTITY) * l.SL_PSLIP_QTY
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND eom_report_pkg.F_BREAK_UNIT_PRICE('TABCORP',d.SD_STOCK) IS NOT NULL THEN  eom_report_pkg.F_BREAK_UNIT_PRICE('TABCORP',d.SD_STOCK) * l.SL_PSLIP_QTY
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND eom_report_pkg.F_BREAK_UNIT_PRICE('TABCORP',d.SD_STOCK) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE * l.SL_PSLIP_QTY
			      ELSE NULL
			      END          AS "DExcl",

	   CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN To_Number(i.IM_REPORTING_PRICE)
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN  eom_report_pkg.F_BREAK_UNIT_PRICE('TABCORP',d.SD_STOCK)
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND eom_report_pkg.F_BREAK_UNIT_PRICE('TABCORP',d.SD_STOCK) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			      ELSE NULL
			      END                       AS "Excl_Total",
	  CASE    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN (d.SD_SELL_PRICE * l.SL_PSLIP_QTY) * 1.1
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1  THEN  ((n.NI_SELL_VALUE/n.NI_NX_QUANTITY) * l.SL_PSLIP_QTY) * 1.1
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND eom_report_pkg.F_BREAK_UNIT_PRICE('TABCORP',d.SD_STOCK) IS NOT NULL THEN  (eom_report_pkg.F_BREAK_UNIT_PRICE('TABCORP',d.SD_STOCK) * l.SL_PSLIP_QTY) * 1.1
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND eom_report_pkg.F_BREAK_UNIT_PRICE('TABCORP',d.SD_STOCK) IS NULL THEN  (d.SD_XX_OW_UNIT_PRICE * l.SL_PSLIP_QTY) * 1.1
			      ELSE NULL
			      END          AS "DIncl",
	   CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN (d.SD_SELL_PRICE * l.SL_PSLIP_QTY) * 1.1
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1 THEN  ((n.NI_SELL_VALUE/n.NI_NX_QUANTITY) * l.SL_PSLIP_QTY) * 1.1
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND eom_report_pkg.F_BREAK_UNIT_PRICE('TABCORP',d.SD_STOCK) IS NOT NULL THEN  (eom_report_pkg.F_BREAK_UNIT_PRICE('TABCORP',d.SD_STOCK) * l.SL_PSLIP_QTY) * 1.1
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND eom_report_pkg.F_BREAK_UNIT_PRICE('TABCORP',d.SD_STOCK) IS NULL THEN  (d.SD_XX_OW_UNIT_PRICE * l.SL_PSLIP_QTY) * 1.1
			      ELSE NULL
			      END          AS "Incl_Total",
	  CASE    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN To_Number(i.IM_REPORTING_PRICE)
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN  eom_report_pkg.F_BREAK_UNIT_PRICE('TABCORP',d.SD_STOCK)
			      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND eom_report_pkg.F_BREAK_UNIT_PRICE('TABCORP',d.SD_STOCK) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			      ELSE NULL
			      END                    AS "ReportingPrice",
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
    CASE   WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			     ELSE ''
			     END AS Email,
    i.IM_BRAND AS Brand,
    NULL AS OwnedBy,
    NULL AS sProfile,
    NULL AS WaiveFee,
    NULL AS Cost,
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
	  AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
	  AND       d.SD_LAST_PICK_NUM = t.ST_PICK
    AND     i.IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_ANAL = sAnalysis AND RM_TYPE = 0 AND RM_ACTIVE = 1 )
	GROUP BY  s.SH_CUST,r.RM_PARENT,
			  s.SH_NOTE_1,
			  s.SH_CAMPAIGN,
			  s.SH_SPARE_STR_4,
			  i.IM_XX_COST_CENTRE01,
			  i.IM_CUST,
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
			  --r.sGroupCust,
			  s.SH_SPARE_STR_5,
			  s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,
			  d.SD_SELL_PRICE,
			  i.IM_OWNED_BY,
			  d.SD_QTY_DESP,
        n.NI_SELL_VALUE,
        n.NI_NX_QUANTITY,
              i.IM_BRAND,
              l.SL_PSLIP_QTY   --2.6s
 
   

	
;

    BEGIN
    

    nCheckpoint := 1;
      v_query := 'TRUNCATE TABLE TMP_HAND_FEES';
      EXECUTE IMMEDIATE v_query;
    
    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
        
        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_HAND_FEES VALUES l_data(i); 
        --USING sCust;
        
        EXIT WHEN c%NOTFOUND;

        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
      -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
      --END LOOP;

  COMMIT;
  --RETURN;
  DBMS_OUTPUT.PUT_LINE('EOM Temp Handeling Fees for all customers for the date range ' 
      || start_date || ' -- ' || end_date);
    --COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM Handeling fees processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;

  END EOM_TMP_ALL_HAND_FEES_ALL_IC;
  
  /*   Run this once for each customer   */
  /*   This gets all the Storage Related Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_STOR_FEES   */
  PROCEDURE EOM_TMP_ALL_STOR_FEES_ALL_CUST (
      p_array_size IN PLS_INTEGER DEFAULT 100
        ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
        ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
        ,sCust IN RM.RM_CUST%TYPE,
      sAnalysis IN RM.RM_ANAL%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_STOR_FEES%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		sCourierm         VARCHAR2(20) := 'COURIERM';
    sCouriers         VARCHAR2(20) := 'COURIERS';
    sCourier         VARCHAR2(20) := 'COURIER%';
    sServ8             VARCHAR2(20) := 'SERV8';
    sServ3             VARCHAR2(20) := 'SERV%';
    
    --p2_array_size PLS_INTEGER := D_EOM_GET_CUST_RATES('TABCORP',0);
    --Type rates IS VARRAY(35) OF INTEGER;
    --rates := D_EOM_GET_CUST_RATES('TABCORP');
    --sCust2    VARCHAR2(20) := sCust;
    end_date2 ST.ST_DESP_DATE%TYPE := end_date;
    nbreakpoint   NUMBER;
    
     CURSOR c 
    IS 
 
   
/* EOM Storage Fees */
	select IM_CUST AS "Customer",
	  IM_CUST AS "Parent",
	  IM_XX_COST_CENTRE01     AS "CostCentre",
	  NULL               AS "Order",
	  NULL               AS "OrderwareNum",
	  NULL               AS "CustomerRef",
	  NULL                AS "Pickslip",
	  NULL                AS "PickNum",
	  NULL               AS "DespatchNote",
	  (select SubStr(To_Char(last_day(SYSDATE)),0,10) from dual) AS "DespatchDate", /*Made Date*/
		CASE /*Fee Type*/
			WHEN (l1.IL_NOTE_2 like 'Yes'
				OR l1.IL_NOTE_2 LIKE 'YES'
				OR l1.IL_NOTE_2 LIKE 'yes')
			THEN 'FEEPALLETS'
			ELSE 'FEESHELFS'
			END AS "FeeType",
		n1.NI_STOCK AS "Item",
		CASE /*explanation of charge*/
			WHEN (l1.IL_NOTE_2 like 'Yes'	OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN 'Pallet Space Utilisation Fee (per month) is split across ' || tmp.NCOUNTOFSTOCKS || ' stock(s)'
			ELSE 'Shelf SPace Utilisation Fee (per month) is split across ' ||	tmp.NCOUNTOFSTOCKS  || ' stock(s)'
			END AS "Description",
	   CASE   WHEN l1.IL_NOTE_2 IS NOT NULL THEN  1
			  ELSE 0
			  END                     AS "Qty",
		IM_LEVEL_UNIT AS "UOI", /*UOI*/
	   CASE 
			WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
        r1.RM_XX_FEE11 / tmp.NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS 
			WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				r1.RM_XX_FEE12 / tmp.NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS 
	    ELSE 0
	    END AS "UnitPrice",
		  CASE   
			WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
        r1.RM_XX_FEE11 / tmp.NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS 
			WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				r1.RM_XX_FEE12 / tmp.NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS 
	    ELSE 0
	    END AS "OWUnitPrice",
			CASE 
			WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
        r1.RM_XX_FEE11 / tmp.NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS 
			WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				r1.RM_XX_FEE12 / tmp.NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS 
	    ELSE 0
      END AS "DExcl",
			CASE 
			WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
        r1.RM_XX_FEE11 / tmp.NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS 
			WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				r1.RM_XX_FEE12 / tmp.NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS 
	    ELSE 0
      END AS "Excl_Total", 
		 CASE WHEN (l1.IL_NOTE_2 like 'Yes'  OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN
				(r1.RM_XX_FEE11 / tmp.NCOUNTOFSTOCKS )  * 1.1
			ELSE
				(r1.RM_XX_FEE12 / tmp.NCOUNTOFSTOCKS )  * 1.1
	    END AS "DIncl",
			 CASE WHEN (l1.IL_NOTE_2 like 'Yes'  OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN
				(r1.RM_XX_FEE11 / tmp.NCOUNTOFSTOCKS )  * 1.1
			ELSE
				(r1.RM_XX_FEE12 / tmp.NCOUNTOFSTOCKS )  * 1.1
	    END AS "Incl_Total",
	   CASE    WHEN l1.IL_LOCN IS NOT NULL THEN (Select To_Number(i.IM_REPORTING_PRICE) from IM i where i.IM_STOCK = 'COURIERM')
			  ELSE NULL
			  END                      AS "ReportingPrice",
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
	  l1.IL_NOTE_2 AS "Pallet/Space", /*Pallet/Space*/
		n1.NI_LOCN AS "Locn", /*Locn*/
		--n1.NI_AVAIL_ACTUAL AS "Avail SOH",
		tmp.NCOUNTOFSTOCKS AS CountCustStocks,
    NULL AS Email,
              IM_BRAND AS Brand,
           IM_OWNED_By AS    OwnedBy,
           IM_PROFILE AS    sProfile,
           NULL AS    WaiveFee,
           NULL As   Cost,
           NULL AS PaymentType

	FROM NI n1 INNER JOIN IM ON IM_STOCK = n1.NI_STOCK
	INNER JOIN IL l1 ON l1.IL_LOCN = n1.NI_LOCN
  INNER JOIN Tmp_Locn_Cnt_By_Cust tmp ON tmp.SLOCN = l1.IL_LOCN
  INNER JOIN RM R1 ON RM_CUST = IM_CUST
	WHERE IM_ACTIVE = 1
  AND IM_CUST = sCust
	AND n1.NI_AVAIL_ACTUAL >= '1'
	AND n1.NI_STATUS <> 0

  --GROUP BY IM_CUST,IM_XX_COST_CENTRE01,n1.NI_LOCN,5,6,
 -- n1.NI_STOCK,8,9,10,11,12,l1.IL_NOTE_2,IM_LEVEL_UNIT,l1.IL_LOCN,nCountOfStocks,IM_BRAND,IM_OWNED_By,IM_PROFILE


/* EOM Storage Fees */


	
;

    BEGIN
    

    nCheckpoint := 1;
      v_query := 'TRUNCATE TABLE TMP_STOR_FEES';
      EXECUTE IMMEDIATE v_query;
    
    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
        
        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_STOR_FEES VALUES l_data(i); 
        --USING sCust;
        
        EXIT WHEN c%NOTFOUND;

        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
      -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
      --END LOOP;

  COMMIT;
  --RETURN;
  DBMS_OUTPUT.PUT_LINE('EOM Storage Fees for all customers for the date range ' 
      || start_date || ' -- ' || end_date);
    --COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM Storage fees processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;

  END EOM_TMP_ALL_STOR_FEES_ALL_CUST;
  
  /*   Run this once for each intercompany customer   */
  /*   This gets all the Storage Related Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_STOR_FEES   */
  PROCEDURE EOM_TMP_ALL_STOR_FEES_ALL_IC (
      p_array_size IN PLS_INTEGER DEFAULT 100
        ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
        ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
        ,sCust IN RM.RM_CUST%TYPE,
      sAnalysis IN RM.RM_ANAL%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_STOR_FEES%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		sCourierm         VARCHAR2(20) := 'COURIERM';
    sCouriers         VARCHAR2(20) := 'COURIERS';
    sCourier         VARCHAR2(20) := 'COURIER%';
    sServ8             VARCHAR2(20) := 'SERV8';
    sServ3             VARCHAR2(20) := 'SERV%';
    
    --p2_array_size PLS_INTEGER := D_EOM_GET_CUST_RATES('TABCORP',0);
    --Type rates IS VARRAY(35) OF INTEGER;
    --rates := D_EOM_GET_CUST_RATES('TABCORP');
    --sCust2    VARCHAR2(20) := sCust;
    end_date2 ST.ST_DESP_DATE%TYPE := end_date;
    nbreakpoint   NUMBER;
    
     CURSOR c 
    IS 
 
   
/* EOM Storage Fees */
	select IM_CUST AS "Customer",
	  IM_CUST AS "Parent",
	  IM_XX_COST_CENTRE01     AS "CostCentre",
	  NULL               AS "Order",
	  NULL               AS "OrderwareNum",
	  NULL               AS "CustomerRef",
	  NULL                AS "Pickslip",
	  NULL                AS "PickNum",
	  NULL               AS "DespatchNote",
	  (select SubStr(To_Char(last_day(SYSDATE)),0,10) from dual) AS "DespatchDate", /*Made Date*/
		CASE /*Fee Type*/
			WHEN (l1.IL_NOTE_2 like 'Yes'
				OR l1.IL_NOTE_2 LIKE 'YES'
				OR l1.IL_NOTE_2 LIKE 'yes')
			THEN 'FEEPALLETS'
			ELSE 'FEESHELFS'
			END AS "FeeType",
		n1.NI_STOCK AS "Item",
		CASE /*explanation of charge*/
			WHEN (l1.IL_NOTE_2 like 'Yes'	OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN 'Pallet Space Utilisation Fee (per month) is split across ' || NCOUNTOFSTOCKS || ' stock(s)'
			ELSE 'Shelf SPace Utilisation Fee (per month) is split across ' ||	NCOUNTOFSTOCKS  || ' stock(s)'
			END AS "Description",
	   CASE   WHEN l1.IL_NOTE_2 IS NOT NULL THEN  1
			  ELSE 0
			  END                     AS "Qty",
		IM_LEVEL_UNIT AS "UOI", /*UOI*/
	   CASE 
			WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
        (SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) / NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS 
			WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				(SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) / NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS 
	    ELSE 0
	    END AS "UnitPrice",
		  CASE   
			WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
        (SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) / NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS 
			WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				(SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) / NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS 
	    ELSE 0
	    END AS "OWUnitPrice",
			CASE 
			WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
        (SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) / NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS 
			WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				(SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) / NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS 
	    ELSE 0
      END AS "DExcl",
			CASE 
			WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
        (SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) / NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS 
			WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				(SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) / NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS 
	    ELSE 0
      END AS "Excl_Total", 
		 CASE WHEN (l1.IL_NOTE_2 like 'Yes'  OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN
				((SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) / NCOUNTOFSTOCKS )  * 1.1
			ELSE
				((SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) / NCOUNTOFSTOCKS )  * 1.1
	    END AS "DIncl",
			 CASE WHEN (l1.IL_NOTE_2 like 'Yes'  OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN
				((SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) / NCOUNTOFSTOCKS )  * 1.1
			ELSE
				((SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) / NCOUNTOFSTOCKS )  * 1.1
	    END AS "Incl_Total",
	   CASE    WHEN l1.IL_LOCN IS NOT NULL THEN (Select To_Number(i.IM_REPORTING_PRICE) from IM i where i.IM_STOCK = 'COURIERM')
			  ELSE NULL
			  END                      AS "ReportingPrice",
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
	  l1.IL_NOTE_2 AS "Pallet/Space", /*Pallet/Space*/
		n1.NI_LOCN AS "Locn", /*Locn*/
		--n1.NI_AVAIL_ACTUAL AS "Avail SOH",
		NCOUNTOFSTOCKS AS CountCustStocks,
    NULL AS Email,
              IM_BRAND AS Brand,
           IM_OWNED_By AS    OwnedBy,
           IM_PROFILE AS    sProfile,
           NULL AS    WaiveFee,
           NULL As   Cost,
           NULL AS PaymentType

/*	FROM NI n1 INNER JOIN IM ON IM_STOCK = n1.NI_STOCK
	INNER JOIN IL l1 ON l1.IL_LOCN = n1.NI_LOCN
  INNER JOIN Tmp_Locn_Cnt_By_Cust tmp ON tmp.SLOCN = l1.IL_LOCN
  INNER JOIN RM R1 ON RM_CUST = IM_CUST
	WHERE IM_ACTIVE = 1
  AND IM_CUST = 'TABCORP'
	AND n1.NI_AVAIL_ACTUAL >= '1'
	AND n1.NI_STATUS <> 0*/
  
  
  FROM NI n1 INNER JOIN IM ON IM_STOCK = n1.NI_STOCK
	  INNER JOIN IL l1 ON l1.IL_LOCN = n1.NI_LOCN
    INNER JOIN Tmp_Locn_Cnt_By_Cust ON sLocn = l1.IL_LOCN  AND sCust = IM_CUST
    INNER JOIN RM R1 ON RM_CUST = IM_CUST
    --WHERE IM_CUST = 'NSWFIRE' /*IN (SELECT RM_CUST FROM RM WHERE RM_ANAL = '22NSWP') */ /*AND    */
   WHERE IM_ACTIVE = 1
	  AND IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_PARENT = ' '  AND RM_ANAL = sAnalysis AND RM_TYPE = 0 AND RM_ACTIVE = 1 )
	  AND n1.NI_AVAIL_ACTUAL >= '1' AND n1.NI_STATUS <> 0
   -- AND n1.NI_EXT_TYPE = 1210067
    AND l1.IL_IN_LOCN NOT IN ('OBSOLETEMEL','OBSOLETESYD','PASTHISTORY', 'CANBERRA')
  --AND n1.NI_STATUS =  1
    AND n1.NI_STRENGTH = 3 

  --GROUP BY IM_CUST,IM_XX_COST_CENTRE01,n1.NI_LOCN,5,6,
 -- n1.NI_STOCK,8,9,10,11,12,l1.IL_NOTE_2,IM_LEVEL_UNIT,l1.IL_LOCN,nCountOfStocks,IM_BRAND,IM_OWNED_By,IM_PROFILE


/* EOM Storage Fees */


	
;

    BEGIN
    

    nCheckpoint := 1;
      v_query := 'TRUNCATE TABLE TMP_STOR_FEES';
      EXECUTE IMMEDIATE v_query;
    
    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
        
        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_STOR_FEES VALUES l_data(i); 
        --USING sCust;
        
        EXIT WHEN c%NOTFOUND;

        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
      -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
      --END LOOP;

  COMMIT;
  --RETURN;
  DBMS_OUTPUT.PUT_LINE('EOM Storage Fees for all customers for the date range ' 
      || start_date || ' -- ' || end_date);
    --COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM Storage fees processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;

  END EOM_TMP_ALL_STOR_FEES_ALL_IC;

  /*   Run this once for each customer   */
  /*   This gets all the Miscellaneous Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_MISC_FEES   */
  PROCEDURE EOM_TMP_ALL_MISC_FEES_ALL_CUST (
      p_array_size IN PLS_INTEGER DEFAULT 100
        ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
        ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
        ,sCust IN RM.RM_CUST%TYPE,
      sAnalysis IN RM.RM_ANAL%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_MISC_FEES%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		sCourierm         VARCHAR2(20) := 'COURIERM';
    sCouriers         VARCHAR2(20) := 'COURIERS';
    sCourier         VARCHAR2(20) := 'COURIER%';
    sServ8             VARCHAR2(20) := 'SERV8';
    sServ3             VARCHAR2(20) := 'SERV%';
    
    --p2_array_size PLS_INTEGER := D_EOM_GET_CUST_RATES('TABCORP',0);
    --Type rates IS VARRAY(35) OF INTEGER;
    --rates := D_EOM_GET_CUST_RATES('TABCORP');
    --sCust2    VARCHAR2(20) := sCust;
    end_date2 ST.ST_DESP_DATE%TYPE := end_date;
    nbreakpoint   NUMBER;
    nCountCustStocks NUMBER := 10;
    --Select 
     CURSOR c 
    IS 
 
  
/*DB Maintenance Fee*/
	SELECT    RM_CUST                AS "Customer",
			  RM_PARENT              AS "Parent",
			  NULL       AS "CostCentre",
			  NULL               AS "Order",
			  NULL         AS "OrderwareNum",
			  NULL            AS "CustomerRef",
			  NULL                     AS "Pickslip",
			  NULL                     AS "PickNum",
			  NULL                     AS "DespatchNote",
			  NULL                     AS "DespatchDate",
	  CASE    WHEN RD_CUST IS NOT NULL THEN 'DB Maint fee '
			  ELSE ''
			  END                      AS "FeeType",
			  'DB Maint'               AS "Item",
			  'DB Maint fee '                AS "Description",
       TO_NUMBER( (SELECT Count(RD_CODE) FROM PWIN175.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN175.RM WHERE (RM_PARENT = sCust) AND SubStr(RD_CODE,0,2) NOT LIKE 'WH'  AND RD_CODE <> 'DIRECT')))  AS "Qty",
	  '1'           AS "UOI",
	   (SELECT To_Number(regexp_substr(RM_XX_FEE21,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)          AS "UnitPrice",
	   (SELECT To_Number(regexp_substr(RM_XX_FEE21,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)                    AS "OWUnitPrice",
	   (SELECT To_Number(regexp_substr(RM_XX_FEE21,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * (SELECT Count(RD_CODE) FROM PWIN175.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN175.RM WHERE (RM_PARENT = sCust) AND SubStr(RD_CODE,0,2) NOT LIKE 'WH'  AND RD_CODE <> 'DIRECT'))         AS "DExcl",
	   (SELECT To_Number(regexp_substr(RM_XX_FEE21,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * (SELECT Count(RD_CODE) FROM PWIN175.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN175.RM WHERE (RM_PARENT = sCust) AND SubStr(RD_CODE,0,2) NOT LIKE 'WH'  AND RD_CODE <> 'DIRECT'))      AS "Excl_Total",
		( (SELECT To_Number(regexp_substr(RM_XX_FEE21,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * (SELECT Count(RD_CODE) FROM PWIN175.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN175.RM WHERE (RM_PARENT = sCust) AND SubStr(RD_CODE,0,2) NOT LIKE 'WH'  AND RD_CODE <> 'DIRECT'))) * 1.1         AS "DIncl",
	  ( (SELECT To_Number(regexp_substr(RM_XX_FEE21,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * (SELECT Count(RD_CODE) FROM PWIN175.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN175.RM WHERE (RM_PARENT = sCust) AND SubStr(RD_CODE,0,2) NOT LIKE 'WH'  AND RD_CODE <> 'DIRECT'))) * 1.1        AS "Incl_Total",
		 (SELECT To_Number(regexp_substr(RM_XX_FEE21,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)                     AS "ReportingPrice",
			  NULL                     AS "Address",
			  NULL                     AS "Address2",
			  NULL                     AS "Suburb",
			  NULL                     AS "State",
			  NULL                     AS "Postcode",
			  NULL                     AS "DeliverTo",
			  NULL                     AS "AttentionTo" ,
			  0                     AS "Weight",
			  0                     AS "Packages",
			  0                     AS "OrderSource",
			  NULL AS "Pallet/Shelf Space",
				NULL AS "Locn",
				--0 AS "AvailSOH",
				0 AS "CountOfStocks",
        NULL AS Email,
        'N/A' AS Brand,
           NULL AS    OwnedBy,
           NULL AS    sProfile,
           NULL AS    WaiveFee,
           NULL As   Cost,
           NULL AS PaymentType


	FROM  PWIN175.RM INNER JOIN RD  ON RD_CUST  = RM_CUST
	WHERE  (SELECT To_Number(regexp_substr(RM_XX_FEE21,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0
	AND     (RM_PARENT = sCust OR RM_CUST = sCust)
  --AND (SELECT Count(RD_CODE) FROM PWIN175.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN175.RM WHERE RM_PARENT = :cust  AND SubStr(RD_CODE,0,2) NOT LIKE 'WH') AND RD_CODE <> 'DIRECT' > 0)
  GROUP BY  RM_CUST,
			  RM_PARENT,
			  RD_CUST
			  





	UNION ALL
/*DB Maintenance Fee*/

/*Stock Maint Charges including Stocktake and Kitting*/
    SELECT    RM_CUST                AS "Customer",
			  NULL              AS "Parent",
			  NULL       AS "CostCentre",
			  NULL               AS "Order",
			  NULL         AS "OrderwareNum",
			  NULL            AS "CustomerRef",
			  NULL                     AS "Pickslip",
			  NULL                     AS "PickNum",
			  NULL                     AS "DespatchNote",
			  NULL                     AS "DespatchDate",
	  CASE    WHEN RM_CUST IS NOT NULL THEN 'Stock Maint fee '
			  ELSE ''
			  END                      AS "FeeType",
			  'Stock Maint'               AS "Item",
			  'Stock Maint fee '                AS "Description",
        total_count_by_cust(sCust)  AS "Qty",
	  '1'           AS "UOI",
	   (SELECT To_Number(regexp_substr(RM_XX_FEE20,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)          AS "UnitPrice",
	  (SELECT To_Number(regexp_substr(RM_XX_FEE20,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)                    AS "OWUnitPrice",
	  (SELECT To_Number(regexp_substr(RM_XX_FEE20,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  * total_count_by_cust(sCust)         AS "DExcl",
	  (SELECT To_Number(regexp_substr(RM_XX_FEE20,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  * total_count_by_cust(sCust)      AS "Excl_Total",
		( (SELECT To_Number(regexp_substr(RM_XX_FEE20,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  * total_count_by_cust(sCust)) * 1.1         AS "DIncl",
	  ( (SELECT To_Number(regexp_substr(RM_XX_FEE20,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  * total_count_by_cust(sCust)) * 1.1        AS "Incl_Total",
		(SELECT To_Number(regexp_substr(RM_XX_FEE20,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)                     AS "ReportingPrice",
			  NULL                     AS "Address",
			  NULL                     AS "Address2",
			  NULL                     AS "Suburb",
			  NULL                     AS "State",
			  NULL                     AS "Postcode",
			  NULL                     AS "DeliverTo",
			  NULL                     AS "AttentionTo" ,
			  0                     AS "Weight",
			  0                     AS "Packages",
			  0                     AS "OrderSource",
			  NULL AS "Pallet/Shelf Space",
				NULL AS "Locn",
				--0 AS "AvailSOH",
				total_count_by_cust(sCust) AS "CountOfStocks",
        NULL AS Email,
        'N/A' AS Brand,
           NULL AS    OwnedBy,
           NULL AS    sProfile,
           NULL AS    WaiveFee,
           NULL As   Cost,
           NULL AS PaymentType


	FROM  PWIN175.RM
	WHERE   (SELECT To_Number(regexp_substr(RM_XX_FEE20,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  > 0
	AND     (RM_CUST = sCust)
  GROUP BY  RM_CUST


	UNION ALL

/*Stock Maint Charges including Stocktake and Kitting*/

/*Admin Charges*/
    	SELECT    RM_CUST                AS "Customer",
			  NULL              AS "Parent",
			  NULL       AS "CostCentre",
			  NULL               AS "Order",
			  NULL         AS "OrderwareNum",
			  NULL            AS "CustomerRef",
			  NULL                     AS "Pickslip",
			  NULL                     AS "PickNum",
			  NULL                     AS "DespatchNote",
			  NULL                     AS "DespatchDate",
	  CASE    WHEN RM_CUST IS NOT NULL THEN 'Admin fee '
			  ELSE ''
			  END                      AS "FeeType",
			  'Admin'                   AS "Item",
			  'Admin fee '                AS "Description",
       CASE    WHEN RM_CUST IS NOT NULL THEN 1
			  ELSE 0
			  END                      AS "Qty",
	   '1'           AS "UOI",
	      (SELECT To_Number(regexp_substr(RM_XX_FEE19,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)   AS "UnitPrice",
	  (SELECT To_Number(regexp_substr(RM_XX_FEE19,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  AS "OWUnitPrice",
	   (SELECT To_Number(regexp_substr(RM_XX_FEE19,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  AS "DExcl",
	   (SELECT To_Number(regexp_substr(RM_XX_FEE19,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  AS "Excl_Total",
		( (SELECT To_Number(regexp_substr(RM_XX_FEE19,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  * 1.1)         AS "DIncl",
	  ((SELECT To_Number(regexp_substr(RM_XX_FEE19,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * 1.1)        AS "Incl_Total",
		 (SELECT To_Number(regexp_substr(RM_XX_FEE19,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)                    AS "ReportingPrice",
			  NULL                     AS "Address",
			  NULL                     AS "Address2",
			  NULL                     AS "Suburb",
			  NULL                     AS "State",
			  NULL                     AS "Postcode",
			  NULL                     AS "DeliverTo",
			  NULL                     AS "AttentionTo" ,
			  0                     AS "Weight",
			  0                     AS "Packages",
			  0                     AS "OrderSource",
			  NULL AS "Pallet/Shelf Space",
				NULL AS "Locn",
				--0 AS "AvailSOH",
				0 AS "CountOfStocks",
        NULL AS Email,
        'N/A' AS Brand,
           NULL AS    OwnedBy,
           NULL AS    sProfile,
           NULL AS    WaiveFee,
           NULL As   Cost,
           NULL AS PaymentType


	FROM  PWIN175.RM
	WHERE    (SELECT To_Number(regexp_substr(RM_XX_FEE19,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0
	AND     RM_CUST = sCust
 GROUP BY  RM_CUST

--	UNION ALL

/*Admin Charges*/



	
;

    BEGIN
    

    nCheckpoint := 1;
      v_query := 'TRUNCATE TABLE TMP_MISC_FEES';
      EXECUTE IMMEDIATE v_query;
    
    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
        
        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_MISC_FEES VALUES l_data(i); 
        --USING sCust;
        
        EXIT WHEN c%NOTFOUND;

        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
      -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
      --END LOOP;

  COMMIT;
  --RETURN;
  DBMS_OUTPUT.PUT_LINE('EOM Misc Fees for all customers for the date range ' 
      || start_date || ' -- ' || end_date);
    --COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM Misc fees processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;

  END EOM_TMP_ALL_MISC_FEES_ALL_CUST;
  
  /*   Run this once for each intercompany customer   */
  /*   This gets all the Miscellaneous Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_MISC_FEES   */
  PROCEDURE EOM_TMP_ALL_MISC_FEES_ALL_IC (
      p_array_size IN PLS_INTEGER DEFAULT 100
        ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
        ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
        ,sCust IN RM.RM_CUST%TYPE,
      sAnalysis IN RM.RM_ANAL%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_MISC_FEES%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		sCourierm         VARCHAR2(20) := 'COURIERM';
    sCouriers         VARCHAR2(20) := 'COURIERS';
    sCourier         VARCHAR2(20) := 'COURIER%';
    sServ8             VARCHAR2(20) := 'SERV8';
    sServ3             VARCHAR2(20) := 'SERV%';
    
    --p2_array_size PLS_INTEGER := D_EOM_GET_CUST_RATES('TABCORP',0);
    --Type rates IS VARRAY(35) OF INTEGER;
    --rates := D_EOM_GET_CUST_RATES('TABCORP');
    --sCust2    VARCHAR2(20) := sCust;
    end_date2 ST.ST_DESP_DATE%TYPE := end_date;
    nbreakpoint   NUMBER;
    nCountCustStocks NUMBER := 10;
    --Select 
     CURSOR c 
    IS 
 
  
/*DB Maintenance Fee*/
	SELECT    RM_CUST                AS "Customer",
			  RM_PARENT              AS "Parent",
			  NULL       AS "CostCentre",
			  NULL               AS "Order",
			  NULL         AS "OrderwareNum",
			  NULL            AS "CustomerRef",
			  NULL                     AS "Pickslip",
			  NULL                     AS "PickNum",
			  NULL                     AS "DespatchNote",
			  NULL                     AS "DespatchDate",
	  CASE    WHEN RD_CUST IS NOT NULL THEN 'DB Maint fee '
			  ELSE ''
			  END                      AS "FeeType",
			  'DB Maint'               AS "Item",
			  'DB Maint fee '                AS "Description",
       TO_NUMBER( (SELECT Count(RD_CODE) FROM PWIN175.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN175.RM WHERE (RM_PARENT = sCust) AND SubStr(RD_CODE,0,2) NOT LIKE 'WH'  AND RD_CODE <> 'DIRECT')))  AS "Qty",
	  '1'           AS "UOI",
	   (SELECT To_Number(regexp_substr(RM_XX_FEE21,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)          AS "UnitPrice",
	   (SELECT To_Number(regexp_substr(RM_XX_FEE21,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)                    AS "OWUnitPrice",
	   (SELECT To_Number(regexp_substr(RM_XX_FEE21,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * (SELECT Count(RD_CODE) FROM PWIN175.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN175.RM WHERE (RM_PARENT = sCust) AND SubStr(RD_CODE,0,2) NOT LIKE 'WH'  AND RD_CODE <> 'DIRECT'))         AS "DExcl",
	   (SELECT To_Number(regexp_substr(RM_XX_FEE21,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * (SELECT Count(RD_CODE) FROM PWIN175.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN175.RM WHERE (RM_PARENT = sCust) AND SubStr(RD_CODE,0,2) NOT LIKE 'WH'  AND RD_CODE <> 'DIRECT'))      AS "Excl_Total",
		( (SELECT To_Number(regexp_substr(RM_XX_FEE21,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * (SELECT Count(RD_CODE) FROM PWIN175.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN175.RM WHERE (RM_PARENT = sCust) AND SubStr(RD_CODE,0,2) NOT LIKE 'WH'  AND RD_CODE <> 'DIRECT'))) * 1.1         AS "DIncl",
	  ( (SELECT To_Number(regexp_substr(RM_XX_FEE21,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * (SELECT Count(RD_CODE) FROM PWIN175.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN175.RM WHERE (RM_PARENT = sCust) AND SubStr(RD_CODE,0,2) NOT LIKE 'WH'  AND RD_CODE <> 'DIRECT'))) * 1.1        AS "Incl_Total",
		 (SELECT To_Number(regexp_substr(RM_XX_FEE21,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)                     AS "ReportingPrice",
			  NULL                     AS "Address",
			  NULL                     AS "Address2",
			  NULL                     AS "Suburb",
			  NULL                     AS "State",
			  NULL                     AS "Postcode",
			  NULL                     AS "DeliverTo",
			  NULL                     AS "AttentionTo" ,
			  0                     AS "Weight",
			  0                     AS "Packages",
			  0                     AS "OrderSource",
			  NULL AS "Pallet/Shelf Space",
				NULL AS "Locn",
				--0 AS "AvailSOH",
				0 AS "CountOfStocks",
        NULL AS Email,
        'N/A' AS Brand,
           NULL AS    OwnedBy,
           NULL AS    sProfile,
           NULL AS    WaiveFee,
           NULL As   Cost,
           NULL AS PaymentType


	FROM  PWIN175.RM INNER JOIN RD  ON RD_CUST  = RM_CUST
	WHERE  (SELECT To_Number(regexp_substr(RM_XX_FEE21,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0
	AND    RM_PARENT IN (SELECT RM_CUST FROM RM WHERE RM_PARENT = ' '  AND RM_ANAL = sAnalysis AND RM_TYPE = 0 AND RM_ACTIVE = 1 )
  --AND (SELECT Count(RD_CODE) FROM PWIN175.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN175.RM WHERE RM_PARENT = :cust  AND SubStr(RD_CODE,0,2) NOT LIKE 'WH') AND RD_CODE <> 'DIRECT' > 0)
  GROUP BY  RM_CUST,
			  RM_PARENT,
			  RD_CUST
			  





	UNION ALL
/*DB Maintenance Fee*/

/*Stock Maint Charges including Stocktake and Kitting*/
    SELECT    RM_CUST                AS "Customer",
			  NULL              AS "Parent",
			  NULL       AS "CostCentre",
			  NULL               AS "Order",
			  NULL         AS "OrderwareNum",
			  NULL            AS "CustomerRef",
			  NULL                     AS "Pickslip",
			  NULL                     AS "PickNum",
			  NULL                     AS "DespatchNote",
			  NULL                     AS "DespatchDate",
	  CASE    WHEN RM_CUST IS NOT NULL THEN 'Stock Maint fee '
			  ELSE ''
			  END                      AS "FeeType",
			  'Stock Maint'               AS "Item",
			  'Stock Maint fee '                AS "Description",
        total_count_by_cust(sCust)  AS "Qty",
	  '1'           AS "UOI",
	   (SELECT To_Number(regexp_substr(RM_XX_FEE20,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)          AS "UnitPrice",
	  (SELECT To_Number(regexp_substr(RM_XX_FEE20,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)                    AS "OWUnitPrice",
	  (SELECT To_Number(regexp_substr(RM_XX_FEE20,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  * total_count_by_cust(sCust)         AS "DExcl",
	  (SELECT To_Number(regexp_substr(RM_XX_FEE20,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  * total_count_by_cust(sCust)      AS "Excl_Total",
		( (SELECT To_Number(regexp_substr(RM_XX_FEE20,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  * total_count_by_cust(sCust)) * 1.1         AS "DIncl",
	  ( (SELECT To_Number(regexp_substr(RM_XX_FEE20,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  * total_count_by_cust(sCust)) * 1.1        AS "Incl_Total",
		(SELECT To_Number(regexp_substr(RM_XX_FEE20,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)                     AS "ReportingPrice",
			  NULL                     AS "Address",
			  NULL                     AS "Address2",
			  NULL                     AS "Suburb",
			  NULL                     AS "State",
			  NULL                     AS "Postcode",
			  NULL                     AS "DeliverTo",
			  NULL                     AS "AttentionTo" ,
			  0                     AS "Weight",
			  0                     AS "Packages",
			  0                     AS "OrderSource",
			  NULL AS "Pallet/Shelf Space",
				NULL AS "Locn",
				--0 AS "AvailSOH",
				total_count_by_cust(sCust) AS "CountOfStocks",
        NULL AS Email,
        'N/A' AS Brand,
           NULL AS    OwnedBy,
           NULL AS    sProfile,
           NULL AS    WaiveFee,
           NULL As   Cost,
           NULL AS PaymentType


	FROM  PWIN175.RM
	WHERE   (SELECT To_Number(regexp_substr(RM_XX_FEE20,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  > 0
	AND    RM_PARENT IN (SELECT RM_CUST FROM RM WHERE RM_PARENT = ' '  AND RM_ANAL = sAnalysis AND RM_TYPE = 0 AND RM_ACTIVE = 1 )
  GROUP BY  RM_CUST


	UNION ALL

/*Stock Maint Charges including Stocktake and Kitting*/

/*Admin Charges*/
    	SELECT    RM_CUST                AS "Customer",
			  NULL              AS "Parent",
			  NULL       AS "CostCentre",
			  NULL               AS "Order",
			  NULL         AS "OrderwareNum",
			  NULL            AS "CustomerRef",
			  NULL                     AS "Pickslip",
			  NULL                     AS "PickNum",
			  NULL                     AS "DespatchNote",
			  NULL                     AS "DespatchDate",
	  CASE    WHEN RM_CUST IS NOT NULL THEN 'Admin fee '
			  ELSE ''
			  END                      AS "FeeType",
			  'Admin'                   AS "Item",
			  'Admin fee '                AS "Description",
       CASE    WHEN RM_CUST IS NOT NULL THEN 1
			  ELSE 0
			  END                      AS "Qty",
	   '1'           AS "UOI",
	      (SELECT To_Number(regexp_substr(RM_XX_FEE19,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)   AS "UnitPrice",
	  (SELECT To_Number(regexp_substr(RM_XX_FEE19,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  AS "OWUnitPrice",
	   (SELECT To_Number(regexp_substr(RM_XX_FEE19,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  AS "DExcl",
	   (SELECT To_Number(regexp_substr(RM_XX_FEE19,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  AS "Excl_Total",
		( (SELECT To_Number(regexp_substr(RM_XX_FEE19,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)  * 1.1)         AS "DIncl",
	  ((SELECT To_Number(regexp_substr(RM_XX_FEE19,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * 1.1)        AS "Incl_Total",
		 (SELECT To_Number(regexp_substr(RM_XX_FEE19,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust)                    AS "ReportingPrice",
			  NULL                     AS "Address",
			  NULL                     AS "Address2",
			  NULL                     AS "Suburb",
			  NULL                     AS "State",
			  NULL                     AS "Postcode",
			  NULL                     AS "DeliverTo",
			  NULL                     AS "AttentionTo" ,
			  0                     AS "Weight",
			  0                     AS "Packages",
			  0                     AS "OrderSource",
			  NULL AS "Pallet/Shelf Space",
				NULL AS "Locn",
				--0 AS "AvailSOH",
				0 AS "CountOfStocks",
        NULL AS Email,
        'N/A' AS Brand,
           NULL AS    OwnedBy,
           NULL AS    sProfile,
           NULL AS    WaiveFee,
           NULL As   Cost,
           NULL AS PaymentType


	FROM  PWIN175.RM
	WHERE    (SELECT To_Number(regexp_substr(RM_XX_FEE19,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0
	AND    RM_PARENT IN (SELECT RM_CUST FROM RM WHERE RM_PARENT = ' '  AND RM_ANAL = sAnalysis AND RM_TYPE = 0 AND RM_ACTIVE = 1 )
 GROUP BY  RM_CUST

--	UNION ALL

/*Admin Charges*/



	
;

    BEGIN
    

    nCheckpoint := 1;
      v_query := 'TRUNCATE TABLE TMP_MISC_FEES';
      EXECUTE IMMEDIATE v_query;
    
    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
        
        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_MISC_FEES VALUES l_data(i); 
        --USING sCust;
        
        EXIT WHEN c%NOTFOUND;

        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
      -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
      --END LOOP;

  COMMIT;
  --RETURN;
  DBMS_OUTPUT.PUT_LINE('EOM Misc Fees for all customers for the date range ' 
      || start_date || ' -- ' || end_date);
    --COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM Misc fees processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;

  END EOM_TMP_ALL_MISC_FEES_ALL_IC;
 
  /*   Run this once for each customer   */
  /*   This gets all the Customer Specific Charges   */
  /*   Temp Tables Used   */
  /*   1. TMP_CUSTOMER_FEES   */
  PROCEDURE EOM_TMP_CUSTOMER_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
        ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
        ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
        ,sCust IN RM.RM_CUST%TYPE
      -- sCust IN RM.RM_CUST%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_CUSTOMER_FEES%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		sCourierm         VARCHAR2(20) := 'COURIERM';
    sCouriers         VARCHAR2(20) := 'COURIERS';
    sCourier         VARCHAR2(20) := 'COURIER%';
    sServ8             VARCHAR2(20) := 'SERV8';
    sServ3             VARCHAR2(20) := 'SERV%';
    --sCust2    VARCHAR2(20) := sCust;
    end_date2 ST.ST_DESP_DATE%TYPE := end_date;
    --DBMS_OUTPUT.PUT_LINE(start_date || ' - ' || end_date || '.' || sCust );
      


    CURSOR c 
    --(
      --start_date IN ST.ST_DESP_DATE%TYPE
    -- ,end_date IN ST.ST_DESP_DATE%TYPE
    --sCust IN RM.RM_CUST%TYPE
     --)
     IS 
   
  
/*Tabcorp Inner/Outer PackingFee*/
	SELECT    s.SH_CUST                AS "Customer",
			  r.sGroupCust              AS "Parent",
			  i.IM_XX_COST_CENTRE01         AS "CostCentre",
			  s.SH_ORDER               AS "Order",
			  s.SH_SPARE_STR_5         AS "OrderwareNum",
			  s.SH_CUST_REF            AS "CustomerRef",
			  t.ST_PICK                AS "Pickslip",
			  d.SD_XX_PICKLIST_NUM     AS "PickNum",
			  t.ST_PSLIP               AS "DespatchNote",
			  substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	  CASE    WHEN (i.IM_XX_QTY_PER_PACK IS NOT NULL AND (d.SD_STOCK NOT like 'COURIER%' AND d.SD_STOCK NOT like 'FEE%'))  THEN 'Packing Fee'
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
	   CASE   WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN (SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCust)
			 WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCust)
			 ELSE NULL
			 END                      AS "UnitPrice",
	   CASE   WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN (SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) --(Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCust)
			 WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCust)
			 ELSE NULL
			 END                                          AS "OWUnitPrice",
			  CASE  WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN (SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * d.SD_QTY_DESP -- (Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCust)  * d.SD_QTY_DESP
			 WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * d.SD_QTY_DESP --- (Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCust)  * d.SD_QTY_DESP
			 ELSE NULL
			 END                      AS "DExcl",
			  CASE   WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * d.SD_QTY_DESP --(Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCust)
			 WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * d.SD_QTY_DESP -- (Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCust)
			 ELSE NULL
			 END                                          AS "Excl_Total",
		CASE WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * d.SD_QTY_DESP) * 1.1 -- ((Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCust) * d.SD_QTY_DESP) * 1.1
			 WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * d.SD_QTY_DESP) * 1.1 --  ((Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCust) * d.SD_QTY_DESP) * 1.1
			 ELSE NULL
			 END                      AS "DIncl",
		CASE WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN  ((SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * d.SD_QTY_DESP) * 1.1 -- ((Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCust) * d.SD_QTY_DESP) * 1.1
			 WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * d.SD_QTY_DESP) * 1.1 -- ((Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCust) * d.SD_QTY_DESP) * 1.1
			 ELSE NULL
			 END                      AS "Incl_Total",
	  CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN (Select i.IM_REPORTING_PRICE from IM i where i.IM_STOCK = d.SD_STOCK)
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
           NULL AS    OwnedBy,
           NULL AS    sProfile,
           NULL AS    WaiveFee,
           NULL As   Cost,
           s.SH_SPARE_INT_4 AS PaymentType



	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER  AND t.ST_PICK = d.SD_LAST_PICK_NUM
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
        INNER JOIN RM ON RM_CUST = i.IM_CUST
	WHERE     Upper(i.IM_XX_QTY_PER_PACK) IN ('INNER','OUTER')
	AND       i.IM_CUST = sCust
	AND       s.SH_STATUS <> 3
	AND       s.SH_ORDER = t.ST_ORDER
	AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
	/*GROUP BY  s.SH_CUST,
			  s.SH_SPARE_STR_4,
			  s.SH_ORDER,
			  t.ST_PICK,
			  d.SD_XX_PICKLIST_NUM,
			  t.ST_PSLIP,
			  t.ST_DESP_DATE,
			  i.IM_XX_QTY_PER_PACK,
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
			  d.SD_QTY_DESP,
			  r.sGroupCust,
			  i.IM_XX_COST_CENTRE01,
			  s.SH_SPARE_STR_5,
			  s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,i.IM_BRAND,s.SH_SPARE_INT_4*/
        
        UNION ALL
        
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
  AND      (r.sGroupCust = sCust OR r.sCust = sCust)
	AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL --(SELECT Count(tt.ST_ORDER) FROM PWIN175.ST tt WHERE LTrim(tt.ST_ORDER) = LTrim(s.SH_ORDER)) = 1
	GROUP BY  s.SH_CUST,
			  s.SH_NOTE_1,
			  s.SH_CAMPAIGN,
			  s.SH_SPARE_STR_4,
			  s.SH_ORDER,
			  --t.ST_PICK,
			  --d.SD_XX_PICKLIST_NUM,
			  --t.ST_PSLIP,
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
			  --t.ST_WEIGHT,
			  --t.ST_PACKAGES,
			  s.SH_SPARE_DBL_9,
			  r.sGroupCust,
			  s.SH_SPARE_STR_5,
			  s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,
              i.IM_BRAND,i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4
        
  UNION ALL      
/*BB PackingFee*/
	SELECT    s.SH_CUST,r.sGroupCust,s.SH_SPARE_STR_4,
			  s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,
			  t.ST_PICK,d.SD_XX_PICKLIST_NUM,t.ST_PSLIP,
			  substr(To_Char(t.ST_DESP_DATE),0,10),
        CASE    WHEN (i.IM_TYPE = 'BB_PACK' AND (d.SD_STOCK NOT like 'COURIER%' AND d.SD_STOCK NOT like 'FEE%'))  THEN 'Packing Fee'
        ELSE NULL
        END,
        d.SD_STOCK,
        d.SD_DESC,
        CASE    WHEN d.SD_LINE IS NOT NULL THEN  1
        ELSE NULL
        END,
        CASE    WHEN d.SD_LINE IS NOT NULL THEN  '1'
        ELSE ''
        END,
        CASE
        WHEN i.IM_TYPE = 'BB_PACK'   THEN (Select To_Number(RM_XX_FEE08) from RM where RM_CUST = sCust)
        ELSE NULL
        END,
        CASE
        WHEN i.IM_TYPE = 'BB_PACK'   THEN (Select To_Number(RM_XX_FEE08) from RM where RM_CUST = sCust)
        ELSE NULL
        END,
        CASE
        WHEN i.IM_TYPE = 'BB_PACK'  THEN (Select To_Number(RM_XX_FEE08) from RM where RM_CUST = sCust)
        ELSE NULL
        END,
        CASE
        WHEN i.IM_TYPE = 'BB_PACK'   THEN (Select To_Number(RM_XX_FEE08) from RM where RM_CUST = sCust)
        ELSE NULL
        END,
        CASE
        WHEN i.IM_TYPE = 'BB_PACK'  THEN (Select To_Number(RM_XX_FEE08) from RM where RM_CUST = sCust)   * 1.1
        ELSE NULL
        END,
        CASE
			  WHEN i.IM_TYPE = 'BB_PACK'  THEN (Select To_Number(RM_XX_FEE08) from RM where RM_CUST = sCust)  * 1.1
        ELSE NULL
        END,
        CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN (Select To_Number(i.IM_REPORTING_PRICE) from IM i where i.IM_STOCK = d.SD_STOCK)
			  ELSE NULL
			  END,
			  s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,
			  s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1 ,
			  s.SH_NOTE_2,t.ST_WEIGHT,t.ST_PACKAGES,
			  s.SH_SPARE_DBL_9,
			  NULL,
				NULL,
				0,
        CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
        ELSE ''
        END,
        i.IM_BRAND,i.IM_OWNED_BY,i.IM_PROFILE,
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4


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
  AND     sCust = 'BEYONDBLUE'
 -- AND    nRM_XX_FEE08 > 0
  AND (SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0.1
	AND       s.SH_STATUS <> 3
	AND       d.SD_STOCK NOT IN ('EMERQSRFEE','COURIER%','FEE%','FEE*','COURIER*','COURIER')
	AND       s.SH_ORDER = t.ST_ORDER
	AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
	GROUP BY  s.SH_CUST,r.sGroupCust,s.SH_SPARE_STR_4,
			  s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,
			  t.ST_PICK,d.SD_XX_PICKLIST_NUM,t.ST_PSLIP,
        t.ST_DESP_DATE,i.IM_TYPE,d.SD_STOCK,d.SD_DESC,
        d.SD_LINE,i.IM_TYPE,s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,
			  s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1 ,
			  s.SH_NOTE_2,t.ST_WEIGHT,t.ST_PACKAGES,
			  s.SH_SPARE_DBL_9,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,
        i.IM_BRAND,i.IM_OWNED_BY,i.IM_PROFILE,
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4,
        d.SD_LAST_PICK_NUM,i.IM_STOCK,r.sCust,s.SH_STATUS
        
-- UNION ALL
/*BB PackingFee*/
        
              
              ;
 	
    
    BEGIN
    
    nCheckpoint := 1;
      v_query := 'TRUNCATE TABLE TMP_CUSTOMER_FEES';
      EXECUTE IMMEDIATE v_query;
    
    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
        
        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_CUSTOMER_FEES VALUES l_data(i); 
        --USING sCust;
        
        EXIT WHEN c%NOTFOUND;

        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
     --  FOR i IN l_data.FIRST .. l_data.LAST LOOP
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
     -- END LOOP;

  COMMIT;
  --RETURN;
  DBMS_OUTPUT.PUT_LINE('EOM Customer Only Fees for all customer for the date range ' 
      || start_date || ' -- ' || end_date);
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM Customer Only Fees for all customer for the date range ' 
      || start_date || ' -- ' || end_date);
      RAISE;

  END EOM_TMP_CUSTOMER_FEES;
  
  /*   Run this once for each customer   */
  /*   This gets all the Pallet and Carton Charges   */
  /*   Temp Tables Used   */
  /*   1. TMP_PAL_CTN_FEES   */
  PROCEDURE EOM_TMP_PAL_CTN_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
        ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
        ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
        ,sCust IN RM.RM_CUST%TYPE,
      sAnalysis IN RM.RM_ANAL%TYPE
      -- sCust IN RM.RM_CUST%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_PAL_CTN_FEES%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		sCourierm         VARCHAR2(20) := 'COURIERM';
    sCouriers         VARCHAR2(20) := 'COURIERS';
    sCourier         VARCHAR2(20) := 'COURIER%';
    sServ8             VARCHAR2(20) := 'SERV8';
    sServ3             VARCHAR2(20) := 'SERV%';
    --sCust2    VARCHAR2(20) := sCust;
    end_date2 ST.ST_DESP_DATE%TYPE := end_date;
    --DBMS_OUTPUT.PUT_LINE(start_date || ' - ' || end_date || '.' || sCust );
      


    CURSOR c 
    --(
      --start_date IN ST.ST_DESP_DATE%TYPE
    -- ,end_date IN ST.ST_DESP_DATE%TYPE
    --sCust IN RM.RM_CUST%TYPE
     --)
     IS 
   
 



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
	  CASE    WHEN t.ST_XX_NUM_PALLETS >= 1 THEN 'Pallet Despatch Fee is '
			  ELSE NULL
			  END                      AS "FeeType",
	  CASE     WHEN t.ST_XX_NUM_PALLETS >= 1 THEN  'Pallet Despatch'
			  ELSE NULL
			  END                     AS "Item",
	  CASE     WHEN t.ST_XX_NUM_PALLETS >= 1 THEN  'Pallet Despatch Fee'
			  ELSE NULL
			  END                     AS "Description",
	  CASE    WHEN t.ST_XX_NUM_PALLETS >= 1 THEN  t.ST_XX_NUM_PALLETS
			  ELSE NULL
			  END                     AS "Qty",
	  CASE     WHEN t.ST_XX_NUM_PALLETS >= 1 THEN  '1'
			  ELSE ''
			  END                     AS "UOI",
	  CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE17,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = sCust)
			 ELSE NULL
			 END                      AS "UnitPrice",
	  CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE17,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = sCust)
			 ELSE NULL
			 END                                           AS "OWUnitPrice",
	  CASE   WHEN t.ST_XX_NUM_PALLETS >= 1  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE17,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = sCust)
			 ELSE NULL
			 END                        AS "DExcl",
	CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE17,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = sCust)
			 ELSE NULL
			 END                                            AS "Excl_Total",
	  CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE17,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * 1.1-- (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = sCust)  * 1.1
			 ELSE NULL
			 END                                           AS "DIncl",
	  CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE17,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * 1.1-- (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = sCust)  * 1.1
			 ELSE NULL
			 END                                           AS "Incl_Total",
			  CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE17,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = sCust)
			 ELSE NULL
			 END                                           AS "ReportingPrice",
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
			--	0 AS "AvailSOH",
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
	WHERE (SELECT To_Number(regexp_substr(RM_XX_FEE17,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0
	AND       s.SH_STATUS <> 3
	AND      (r.sGroupCust = sCust OR r.sCust = sCust)
	AND       s.SH_ORDER = t.ST_ORDER
  AND       (ST_XX_NUM_PALLETS >= 1)
	AND       d.SD_LINE = 1
	AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
  

  	UNION ALL

 
/*Carton In Fee*/
	SELECT    IM_CUST                AS "Customer",
			  RM_PARENT              AS "Parent",
			  IM_XX_COST_CENTRE01       AS "CostCentre",
			  NI_QJ_NUMBER               AS "Order",
			  NULL         AS "OrderwareNum",
			  NULL            AS "CustomerRef",
			  NULL                     AS "Pickslip",
			  NULL                     AS "PickNum",
			  NULL                     AS "DespatchNote",
			  substr(To_Char(NE_ADD_DATE),0,10)                     AS "DespatchDate",
	 CASE    WHEN NE_ENTRY IS NOT NULL THEN 'Carton In Fee '
			  ELSE ''
			  END                      AS "FeeType",
			  IM_STOCK               AS "Item",
			  IM_DESC                AS "Description",
	      NE_QUANTITY          AS "Qty",
	      IM_LEVEL_UNIT          AS "UOI",
	  CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE13,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = sCust)
			  ELSE NULL
			  END                      AS "UnitPrice",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE13,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) --  (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = sCust)
			  ELSE NULL
			  END                      AS "OWUnitPrice",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE13,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = sCust)
			  ELSE NULL
			  END                      AS "DExcl",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE13,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) --  (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = sCust)
			  ELSE NULL
			  END                      AS "Excl_Total",
		CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE13,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * 1.1 --  (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = sCust) * 1.1
			  ELSE NULL
			  END                      AS "DIncl",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE13,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * 1.1 -- (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = sCust) * 1.1
			  ELSE NULL
			  END                      AS "Incl_Total",
			  CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE13,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = sCust)
			  ELSE NULL
			  END                                           AS "ReportingPrice",
			  NULL                     AS "Address",
			  NULL                     AS "Address2",
			  NULL                     AS "Suburb",
			  NULL                     AS "State",
			  NULL                     AS "Postcode",
			  NULL                     AS "DeliverTo",
			  NULL                     AS "AttentionTo" ,
			  NULL                     AS "Weight",
			  NULL                     AS "Packages",
			  NULL                     AS "OrderSource",
			  IL_NOTE_2 AS "Pallet/Shelf Space",
				IL_LOCN AS "Locn",
				--NE_AVAIL_ACTUAL AS "AvailSOH",
				0 AS "CountOfStocks",
        NULL AS Email,
              IM_BRAND AS Brand,
           IM_OWNED_By AS    OwnedBy,
           IM_PROFILE AS    sProfile,
           NULL AS    WaiveFee,
           NULL As   Cost,
           NULL AS PaymentType


	FROM      PWIN175.IM
			  INNER JOIN PWIN175.NA  ON NA_STOCK = IM_STOCK
			  INNER JOIN PWIN175.IL  ON IL_UID = NA_EXT_KEY
			  INNER JOIN PWIN175.NE  ON NE_ACCOUNT  = NA_ACCOUNT
			  INNER JOIN PWIN175.NI  ON NI_ENTRY = NE_ENTRY
			  INNER JOIN PWIN175.RM  ON RM_CUST  = IM_CUST
	WHERE (SELECT To_Number(regexp_substr(RM_XX_FEE13,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0
	AND     IM_CUST = sCust
	AND       NA_EXT_TYPE = 1210067
	AND       NE_TRAN_TYPE = 1
  AND     NE_NV_EXT_TYPE = 3010144
--	AND       IM_MAIN_SUPP <> 'BSPGA'
	AND       (NE_STATUS = 1 OR NE_STATUS = 3)
	AND       TO_CHAR(NE_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(NE_DATE,'YYYY-MM-DD') <= end_date
	AND       Upper(IL_NOTE_2) = 'No' AND IL_PHYSICAL = 1
  
  UNION ALL
  /*Pallet In Fee*/
	SELECT    IM_CUST                AS "Customer",
			  RM_PARENT              AS "Parent",
			  IM_XX_COST_CENTRE01       AS "CostCentre",
			  NI_QJ_NUMBER               AS "Order",
			  NULL         AS "OrderwareNum",
			  NULL            AS "CustomerRef",
			  NULL                     AS "Pickslip",
			  NULL                     AS "PickNum",
			  NULL                     AS "DespatchNote",
			  substr(To_Char(NE_ADD_DATE),0,10) AS "DespatchDate",
	  CASE    WHEN NE_ENTRY IS NOT NULL THEN 'Pallet In Fee '
			  ELSE ''
			  END                      AS "FeeType",
			  IM_STOCK               AS "Item",
			  IM_DESC                AS "Description",
	      NE_QUANTITY          AS "Qty",
	      IM_LEVEL_UNIT          AS "UOI",
	  CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "UnitPrice",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "OWUnitPrice",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "DExcl",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) --  (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "Excl_Total",
		CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * 1.1 --  (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust) * 1.1
			  ELSE NULL
			  END                      AS "DIncl",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * 1.1-- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust) * 1.1
			  ELSE NULL
			  END                      AS "Incl_Total",
			  CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                                           AS "ReportingPrice",
			  NULL                     AS "Address",
			  NULL                     AS "Address2",
			  NULL                     AS "Suburb",
			  NULL                     AS "State",
			  NULL                     AS "Postcode",
			  NULL                     AS "DeliverTo",
			  NULL                     AS "AttentionTo" ,
			  NULL                     AS "Weight",
			  NULL                     AS "Packages",
			  NULL                     AS "OrderSource",
			  IL_NOTE_2 AS "Pallet/Shelf Space",
				IL_LOCN AS "Locn",
				--NE_AVAIL_ACTUAL AS "AvailSOH",
				0 AS "CountOfStocks",
        NULL AS Email,
              IM_BRAND AS Brand,
           IM_OWNED_By AS    OwnedBy,
           IM_PROFILE AS    sProfile,
           NULL AS    WaiveFee,
           NULL As   Cost,
           NULL AS PaymentType

	FROM      PWIN175.IM
			  INNER JOIN PWIN175.NA  ON NA_STOCK = IM_STOCK
			  INNER JOIN PWIN175.IL  ON IL_UID = NA_EXT_KEY
			  INNER JOIN PWIN175.NE  ON NE_ACCOUNT  = NA_ACCOUNT
			  INNER JOIN PWIN175.NI  ON NI_ENTRY = NE_ENTRY
			  INNER JOIN PWIN175.RM  ON RM_CUST  = IM_CUST
	WHERE  (SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0
	AND     IM_CUST = sCust
	AND       NA_EXT_TYPE = 1210067
	AND       NE_TRAN_TYPE = 1
  AND     NE_NV_EXT_TYPE = 3010144
--	AND       IM_MAIN_SUPP <> 'BSPGA'
	AND       (NE_STATUS = 1 OR NE_STATUS = 3)
	AND       TO_CHAR(NE_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(NE_DATE,'YYYY-MM-DD') <= end_date
	AND       Upper(IL_NOTE_2) = 'YES' AND IL_PHYSICAL = 1
        
              ;

    
    BEGIN
    
    nCheckpoint := 1;
      v_query := 'TRUNCATE TABLE TMP_PAL_CTN_FEES';
      EXECUTE IMMEDIATE v_query;
    
    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
        
        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_PAL_CTN_FEES VALUES l_data(i); 
        --USING sCust;
        
        EXIT WHEN c%NOTFOUND;

        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
      -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
      --  DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
      --END LOOP;

  COMMIT;
  --RETURN;
  DBMS_OUTPUT.PUT_LINE('EOM Pallet/Carton Fees for all customer for the date range ' 
      || start_date || ' -- ' || end_date);
    --COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM Pallet/Carton Fees Failed');
      RAISE;

  END EOM_TMP_PAL_CTN_FEES;
  
  /*   Run this once for each intercompany customer   */
  /*   This gets all the Pallet and Carton Charges   */
  /*   Temp Tables Used   */
  /*   1. TMP_PAL_CTN_FEES   */
  PROCEDURE EOM_TMP_PAL_CTN_FEES_IC (
      p_array_size IN PLS_INTEGER DEFAULT 100
        ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
        ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
        ,sCust IN RM.RM_CUST%TYPE,
      sAnalysis IN RM.RM_ANAL%TYPE
      -- sCust IN RM.RM_CUST%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_PAL_CTN_FEES%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		sCourierm         VARCHAR2(20) := 'COURIERM';
    sCouriers         VARCHAR2(20) := 'COURIERS';
    sCourier         VARCHAR2(20) := 'COURIER%';
    sServ8             VARCHAR2(20) := 'SERV8';
    sServ3             VARCHAR2(20) := 'SERV%';
    --sCust2    VARCHAR2(20) := sCust;
    end_date2 ST.ST_DESP_DATE%TYPE := end_date;
    --DBMS_OUTPUT.PUT_LINE(start_date || ' - ' || end_date || '.' || sCust );
      


    CURSOR c 
    --(
      --start_date IN ST.ST_DESP_DATE%TYPE
    -- ,end_date IN ST.ST_DESP_DATE%TYPE
    --sCust IN RM.RM_CUST%TYPE
     --)
     IS 
   
 



	/*Pallet Despatch Fee*/
	  SELECT    s.SH_CUST                AS "Customer",
			    RM_PARENT              AS "Parent",
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
	  CASE    WHEN t.ST_XX_NUM_PALLETS >= 1 THEN 'Pallet Despatch Fee is '
			  ELSE NULL
			  END                      AS "FeeType",
	  CASE     WHEN t.ST_XX_NUM_PALLETS >= 1 THEN  'Pallet Despatch'
			  ELSE NULL
			  END                     AS "Item",
	  CASE     WHEN t.ST_XX_NUM_PALLETS >= 1 THEN  'Pallet Despatch Fee'
			  ELSE NULL
			  END                     AS "Description",
	  CASE    WHEN t.ST_XX_NUM_PALLETS >= 1 THEN  t.ST_XX_NUM_PALLETS
			  ELSE NULL
			  END                     AS "Qty",
	  CASE     WHEN t.ST_XX_NUM_PALLETS >= 1 THEN  '1'
			  ELSE ''
			  END                     AS "UOI",
	  CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE17,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = sCust)
			 ELSE NULL
			 END                      AS "UnitPrice",
	  CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE17,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = sCust)
			 ELSE NULL
			 END                                           AS "OWUnitPrice",
	  CASE   WHEN t.ST_XX_NUM_PALLETS >= 1  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE17,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = sCust)
			 ELSE NULL
			 END                        AS "DExcl",
	CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE17,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = sCust)
			 ELSE NULL
			 END                                            AS "Excl_Total",
	  CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE17,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * 1.1-- (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = sCust)  * 1.1
			 ELSE NULL
			 END                                           AS "DIncl",
	  CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE17,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * 1.1-- (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = sCust)  * 1.1
			 ELSE NULL
			 END                                           AS "Incl_Total",
			  CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE17,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = sCust)
			 ELSE NULL
			 END                                           AS "ReportingPrice",
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
			--	0 AS "AvailSOH",
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
			  --LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
        INNER JOIN PWIN175.RM  ON RM_CUST  = IM_CUST

	WHERE (SELECT To_Number(regexp_substr(RM_XX_FEE17,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0
	AND       s.SH_STATUS <> 3
	AND      (RM_ANAL = sAnalysis)
	AND       s.SH_ORDER = t.ST_ORDER
  AND       (ST_XX_NUM_PALLETS >= 1)
	AND       d.SD_LINE = 1
	AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
  

  	UNION ALL

 
/*Carton In Fee*/
	SELECT    IM_CUST                AS "Customer",
			  RM_PARENT              AS "Parent",
			  IM_XX_COST_CENTRE01       AS "CostCentre",
			  NI_QJ_NUMBER               AS "Order",
			  NULL         AS "OrderwareNum",
			  NULL            AS "CustomerRef",
			  NULL                     AS "Pickslip",
			  NULL                     AS "PickNum",
			  NULL                     AS "DespatchNote",
			  substr(To_Char(NE_ADD_DATE),0,10)                     AS "DespatchDate",
	 CASE    WHEN NE_ENTRY IS NOT NULL THEN 'Carton In Fee '
			  ELSE ''
			  END                      AS "FeeType",
			  IM_STOCK               AS "Item",
			  IM_DESC                AS "Description",
	      NE_QUANTITY          AS "Qty",
	      IM_LEVEL_UNIT          AS "UOI",
	  CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE13,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = sCust)
			  ELSE NULL
			  END                      AS "UnitPrice",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE13,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) --  (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = sCust)
			  ELSE NULL
			  END                      AS "OWUnitPrice",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE13,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = sCust)
			  ELSE NULL
			  END                      AS "DExcl",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE13,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) --  (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = sCust)
			  ELSE NULL
			  END                      AS "Excl_Total",
		CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE13,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * 1.1 --  (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = sCust) * 1.1
			  ELSE NULL
			  END                      AS "DIncl",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE13,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * 1.1 -- (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = sCust) * 1.1
			  ELSE NULL
			  END                      AS "Incl_Total",
			  CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE13,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = sCust)
			  ELSE NULL
			  END                                           AS "ReportingPrice",
			  NULL                     AS "Address",
			  NULL                     AS "Address2",
			  NULL                     AS "Suburb",
			  NULL                     AS "State",
			  NULL                     AS "Postcode",
			  NULL                     AS "DeliverTo",
			  NULL                     AS "AttentionTo" ,
			  NULL                     AS "Weight",
			  NULL                     AS "Packages",
			  NULL                     AS "OrderSource",
			  IL_NOTE_2 AS "Pallet/Shelf Space",
				IL_LOCN AS "Locn",
				--NE_AVAIL_ACTUAL AS "AvailSOH",
				0 AS "CountOfStocks",
        NULL AS Email,
              IM_BRAND AS Brand,
           IM_OWNED_By AS    OwnedBy,
           IM_PROFILE AS    sProfile,
           NULL AS    WaiveFee,
           NULL As   Cost,
           NULL AS PaymentType


	FROM      PWIN175.IM
			  INNER JOIN PWIN175.NA  ON NA_STOCK = IM_STOCK
			  INNER JOIN PWIN175.IL  ON IL_UID = NA_EXT_KEY
			  INNER JOIN PWIN175.NE  ON NE_ACCOUNT  = NA_ACCOUNT
			  INNER JOIN PWIN175.NI  ON NI_ENTRY = NE_ENTRY
			  INNER JOIN PWIN175.RM  ON RM_CUST  = IM_CUST
	WHERE (SELECT To_Number(regexp_substr(RM_XX_FEE13,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0
	AND     IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_ANAL = sAnalysis AND RM_TYPE = 0 AND RM_ACTIVE = 1 )
	AND       NA_EXT_TYPE = 1210067
	AND       NE_TRAN_TYPE = 1
  AND     NE_NV_EXT_TYPE = 3010144
--	AND       IM_MAIN_SUPP <> 'BSPGA'
	AND       (NE_STATUS = 1 OR NE_STATUS = 3)
	AND       TO_CHAR(NE_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(NE_DATE,'YYYY-MM-DD') <= end_date
	AND       Upper(IL_NOTE_2) = 'No' AND IL_PHYSICAL = 1
  
  UNION ALL
  /*Pallet In Fee*/
	SELECT    IM_CUST                AS "Customer",
			  RM_PARENT              AS "Parent",
			  IM_XX_COST_CENTRE01       AS "CostCentre",
			  NI_QJ_NUMBER               AS "Order",
			  NULL         AS "OrderwareNum",
			  NULL            AS "CustomerRef",
			  NULL                     AS "Pickslip",
			  NULL                     AS "PickNum",
			  NULL                     AS "DespatchNote",
			  substr(To_Char(NE_ADD_DATE),0,10) AS "DespatchDate",
	  CASE    WHEN NE_ENTRY IS NOT NULL THEN 'Pallet In Fee '
			  ELSE ''
			  END                      AS "FeeType",
			  IM_STOCK               AS "Item",
			  IM_DESC                AS "Description",
	      NE_QUANTITY          AS "Qty",
	      IM_LEVEL_UNIT          AS "UOI",
	  CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "UnitPrice",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "OWUnitPrice",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "DExcl",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) --  (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "Excl_Total",
		CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * 1.1 --  (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust) * 1.1
			  ELSE NULL
			  END                      AS "DIncl",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) * 1.1-- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust) * 1.1
			  ELSE NULL
			  END                      AS "Incl_Total",
			  CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) -- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                                           AS "ReportingPrice",
			  NULL                     AS "Address",
			  NULL                     AS "Address2",
			  NULL                     AS "Suburb",
			  NULL                     AS "State",
			  NULL                     AS "Postcode",
			  NULL                     AS "DeliverTo",
			  NULL                     AS "AttentionTo" ,
			  NULL                     AS "Weight",
			  NULL                     AS "Packages",
			  NULL                     AS "OrderSource",
			  IL_NOTE_2 AS "Pallet/Shelf Space",
				IL_LOCN AS "Locn",
				--NE_AVAIL_ACTUAL AS "AvailSOH",
				0 AS "CountOfStocks",
        NULL AS Email,
              IM_BRAND AS Brand,
           IM_OWNED_By AS    OwnedBy,
           IM_PROFILE AS    sProfile,
           NULL AS    WaiveFee,
           NULL As   Cost,
           NULL AS PaymentType

	FROM      PWIN175.IM
			  INNER JOIN PWIN175.NA  ON NA_STOCK = IM_STOCK
			  INNER JOIN PWIN175.IL  ON IL_UID = NA_EXT_KEY
			  INNER JOIN PWIN175.NE  ON NE_ACCOUNT  = NA_ACCOUNT
			  INNER JOIN PWIN175.NI  ON NI_ENTRY = NE_ENTRY
			  INNER JOIN PWIN175.RM  ON RM_CUST  = IM_CUST
	WHERE  (SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0
	AND     IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_ANAL = sAnalysis AND RM_TYPE = 0 AND RM_ACTIVE = 1 )
	AND       NA_EXT_TYPE = 1210067
	AND       NE_TRAN_TYPE = 1
  AND     NE_NV_EXT_TYPE = 3010144
--	AND       IM_MAIN_SUPP <> 'BSPGA'
	AND       (NE_STATUS = 1 OR NE_STATUS = 3)
	AND       TO_CHAR(NE_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(NE_DATE,'YYYY-MM-DD') <= end_date
	AND       Upper(IL_NOTE_2) = 'YES' AND IL_PHYSICAL = 1
        
              ;

    
    BEGIN
    
    nCheckpoint := 1;
      v_query := 'TRUNCATE TABLE TMP_PAL_CTN_FEES';
      EXECUTE IMMEDIATE v_query;
    
    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
        
        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_PAL_CTN_FEES VALUES l_data(i); 
        --USING sCust;
        
        EXIT WHEN c%NOTFOUND;

        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
      -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
      --  DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
      --END LOOP;

  COMMIT;
  --RETURN;
  DBMS_OUTPUT.PUT_LINE('EOM Pallet/Carton Fees for all customer for the date range ' 
      || start_date || ' -- ' || end_date);
    --COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM Pallet/Carton Fees Failed');
      RAISE;

  END EOM_TMP_PAL_CTN_FEES_IC;
 
  /*   Run this once for each customer   */
  /*   This gets all the Carton Despatch Charges   */
  /*   Temp Tables Used   */
  /*   1. TMP_CTN_FEES   */
  PROCEDURE EOM_TMP_CTN_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
        ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
        ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
        ,sCust IN RM.RM_CUST%TYPE,
      sAnalysis IN RM.RM_ANAL%TYPE
      -- sCust IN RM.RM_CUST%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_CTN_FEES%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		sCourierm         VARCHAR2(20) := 'COURIERM';
    sCouriers         VARCHAR2(20) := 'COURIERS';
    sCourier         VARCHAR2(20) := 'COURIER%';
    sServ8             VARCHAR2(20) := 'SERV8';
    sServ3             VARCHAR2(20) := 'SERV%';
    --sCust2    VARCHAR2(20) := sCust;
    end_date2 ST.ST_DESP_DATE%TYPE := end_date;
    --DBMS_OUTPUT.PUT_LINE(start_date || ' - ' || end_date || '.' || sCust );
    l_start number default dbms_utility.get_time;  


    CURSOR c 
    --(
      --start_date IN ST.ST_DESP_DATE%TYPE
    -- ,end_date IN ST.ST_DESP_DATE%TYPE
    --sCust IN RM.RM_CUST%TYPE
     --)
     IS 
   

/*Carton Despatch Fee*/
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
			  substr(To_Char(t.ST_DESP_DATE),0,10)           AS "DespatchDate",
	  CASE    WHEN t.ST_XX_NUM_CARTONS >= 1 THEN 'Carton Despatch Fee is '
			  ELSE ''
			  END                      AS "FeeType",
	  CASE    WHEN t.ST_XX_NUM_CARTONS >= 1 THEN  d.SD_STOCK
			  ELSE NULL
			  END                     AS "Item",
	  CASE    WHEN t.ST_XX_NUM_CARTONS >= 1 THEN  d.SD_DESC
			  ELSE NULL
			  END                     AS "Description",
	  CASE    WHEN t.ST_XX_NUM_CARTONS >= 1 THEN  t.ST_XX_NUM_CARTONS
			  ELSE NULL
			  END                     AS "Qty",
	  CASE    WHEN t.ST_XX_NUM_CARTONS >= 1 THEN  '1'
			  ELSE ''
			  END                     AS "UOI",
	  CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) --To_Number(f_get_fee('RM_XX_FEE15',sCust))-- f_get_fee('RM_XX_FEE15',sCust)
			 ELSE null
			 END                      AS "UnitPrice",
	  CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) --f_get_fee('RM_XX_FEE15',sCust) --To_Number(f_get_fee('RM_XX_FEE15',sCust))  
    ELSE null
			 END                                           AS "OWUnitPrice",
	 CASE   WHEN t.ST_XX_NUM_CARTONS >= 1  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) --f_get_fee('RM_XX_FEE15',sCust) --To_Number(f_get_fee('RM_XX_FEE15',sCust))  
   ELSE NULL
			 END                        AS "DExcl",
			  CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) --f_get_fee('RM_XX_FEE15',sCust) --To_Number(f_get_fee('RM_XX_FEE15',sCust))  
        ELSE NULL
			 END                                            AS "Excl_Total",
	  CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) --f_get_fee('RM_XX_FEE15',sCust) --To_Number(f_get_fee('RM_XX_FEE15',sCust))  
    ELSE NULL
			 END                                           AS "DIncl",
	  CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) --f_get_fee('RM_XX_FEE15',sCust) --f_get_fee('RM_XX_FEE15',sCust) --To_Number(f_get_fee('RM_XX_FEE15',sCust)) * 1.1  
    ELSE NULL
			 END                                           AS "Incl_Total",
			  CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) --f_get_fee('RM_XX_FEE15',sCust) --To_Number(f_get_fee('RM_XX_FEE15',sCust))  
        ELSE null
			 END                                           AS "ReportingPrice",
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
				--0 AS "AvailSOH",
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
	WHERE  --f_get_fee('RM_XX_FEE15',sCust) > 0
  --To_Number(f_get_fee('RM_XX_FEE15',sCust)) > 0
 (SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0
	AND       s.SH_STATUS <> 3
	AND       (r.sGroupCust = sCust OR r.sCust = sCust)
	AND       s.SH_ORDER = t.ST_ORDER
	AND       (ST_XX_NUM_CARTONS >= 1)
	AND       d.SD_LINE = 1

	AND   TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date;
  
  BEGIN
    
    nCheckpoint := 1;
      v_query := 'TRUNCATE TABLE TMP_CTN_FEES';
      EXECUTE IMMEDIATE v_query;
    
    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
        
        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_CTN_FEES VALUES l_data(i); 
        --USING sCust;
        
        EXIT WHEN c%NOTFOUND;

        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
       FOR i IN l_data.FIRST .. l_data.LAST LOOP
        DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
      END LOOP;

  COMMIT;
  --RETURN;
  DBMS_OUTPUT.PUT_LINE('EOM Carton Fees for all customer for the date range ' 
      || start_date || ' -- ' || end_date);
    --COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM Carton Fees Failed');
      RAISE;

  END EOM_TMP_CTN_FEES;
  
  /*   Run this once for each intercompany customer   */
  /*   This gets all the Carton Despatch Charges   */
  /*   Temp Tables Used   */
  /*   1. TMP_CTN_FEES   */
  PROCEDURE EOM_TMP_CTN_FEES_IC (
      p_array_size IN PLS_INTEGER DEFAULT 10
        ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
        ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
        ,sCust IN RM.RM_CUST%TYPE,
      sAnalysis IN RM.RM_ANAL%TYPE
      -- sCust IN RM.RM_CUST%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_CTN_FEES%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		sCourierm         VARCHAR2(20) := 'COURIERM';
    sCouriers         VARCHAR2(20) := 'COURIERS';
    sCourier         VARCHAR2(20) := 'COURIER%';
    sServ8             VARCHAR2(20) := 'SERV8';
    sServ3             VARCHAR2(20) := 'SERV%';
    --sCust2    VARCHAR2(20) := sCust;
    end_date2 ST.ST_DESP_DATE%TYPE := end_date;
    --DBMS_OUTPUT.PUT_LINE(start_date || ' - ' || end_date || '.' || sCust );
    l_start number default dbms_utility.get_time;  


    CURSOR c 
    --(
      --start_date IN ST.ST_DESP_DATE%TYPE
    -- ,end_date IN ST.ST_DESP_DATE%TYPE
    --sCust IN RM.RM_CUST%TYPE
     --)
     IS 
   

/*Carton Despatch Fee*/
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
			  substr(To_Char(t.ST_DESP_DATE),0,10)           AS "DespatchDate",
	  CASE    WHEN t.ST_XX_NUM_CARTONS >= 1 THEN 'Carton Despatch Fee is '
			  ELSE ''
			  END                      AS "FeeType",
	  CASE    WHEN t.ST_XX_NUM_CARTONS >= 1 THEN  d.SD_STOCK
			  ELSE NULL
			  END                     AS "Item",
	  CASE    WHEN t.ST_XX_NUM_CARTONS >= 1 THEN  d.SD_DESC
			  ELSE NULL
			  END                     AS "Description",
	  CASE    WHEN t.ST_XX_NUM_CARTONS >= 1 THEN  t.ST_XX_NUM_CARTONS
			  ELSE NULL
			  END                     AS "Qty",
	  CASE    WHEN t.ST_XX_NUM_CARTONS >= 1 THEN  '1'
			  ELSE ''
			  END                     AS "UOI",
	  CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) --To_Number(f_get_fee('RM_XX_FEE15',sCust))-- f_get_fee('RM_XX_FEE15',sCust)
			 ELSE null
			 END                      AS "UnitPrice",
	  CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) --f_get_fee('RM_XX_FEE15',sCust) --To_Number(f_get_fee('RM_XX_FEE15',sCust))  
    ELSE null
			 END                                           AS "OWUnitPrice",
	 CASE   WHEN t.ST_XX_NUM_CARTONS >= 1  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) --f_get_fee('RM_XX_FEE15',sCust) --To_Number(f_get_fee('RM_XX_FEE15',sCust))  
   ELSE NULL
			 END                        AS "DExcl",
			  CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) --f_get_fee('RM_XX_FEE15',sCust) --To_Number(f_get_fee('RM_XX_FEE15',sCust))  
        ELSE NULL
			 END                                            AS "Excl_Total",
	  CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) --f_get_fee('RM_XX_FEE15',sCust) --To_Number(f_get_fee('RM_XX_FEE15',sCust))  
    ELSE NULL
			 END                                           AS "DIncl",
	  CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) --f_get_fee('RM_XX_FEE15',sCust) --f_get_fee('RM_XX_FEE15',sCust) --To_Number(f_get_fee('RM_XX_FEE15',sCust)) * 1.1  
    ELSE NULL
			 END                                           AS "Incl_Total",
			  CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) --f_get_fee('RM_XX_FEE15',sCust) --To_Number(f_get_fee('RM_XX_FEE15',sCust))  
        ELSE null
			 END                                           AS "ReportingPrice",
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
				--0 AS "AvailSOH",
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
	WHERE  --f_get_fee('RM_XX_FEE15',sCust) > 0
  --To_Number(f_get_fee('RM_XX_FEE15',sCust)) > 0
 (SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0
	AND       s.SH_STATUS <> 3
	AND       (r.sGroupCust = sCust OR r.sCust = sCust)
	AND       s.SH_ORDER = t.ST_ORDER
	AND       (ST_XX_NUM_CARTONS >= 1)
	AND       d.SD_LINE = 1

	AND   TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date;
  
  BEGIN
    
    nCheckpoint := 1;
      v_query := 'TRUNCATE TABLE TMP_CTN_FEES';
      EXECUTE IMMEDIATE v_query;
    
    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
        
        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_CTN_FEES VALUES l_data(i); 
        --USING sCust;
        
        EXIT WHEN c%NOTFOUND;

        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
       FOR i IN l_data.FIRST .. l_data.LAST LOOP
        DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
      END LOOP;

  COMMIT;
  --RETURN;
  DBMS_OUTPUT.PUT_LINE('EOM Carton Fees for all customer for the date range ' 
      || start_date || ' -- ' || end_date);
    --COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM Carton Fees Failed');
      RAISE;

  END EOM_TMP_CTN_FEES_IC;
 
  /*   Run this once for each customer including intercompany   */
  /*   This merges all the Charges from each of the temp tables   */
  /*   Temp Tables Used   */
  /*   1. TMP_ALL_FEES   */
  PROCEDURE EOM_TMP_MERGE_ALL_FEES (
   p_array_size IN PLS_INTEGER DEFAULT 100
   )
    IS
    TYPE ARRAY IS TABLE OF TMP_ALL_FEES%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		sCourierm         VARCHAR2(20) := 'COURIERM';
    sCouriers         VARCHAR2(20) := 'COURIERS';
    sCourier         VARCHAR2(20) := 'COURIER%';
    sServ8             VARCHAR2(20) := 'SERV8';
    sServ3             VARCHAR2(20) := 'SERV%';
    --sCust2    VARCHAR2(20) := sCust;
   -- end_date2 ST.ST_DESP_DATE%TYPE := end_date;
    --DBMS_OUTPUT.PUT_LINE(start_date || ' - ' || end_date || '.' || sCust );
     l_start number default dbms_utility.get_time; 


    CURSOR c 
    --(
      --start_date IN ST.ST_DESP_DATE%TYPE
    -- ,end_date IN ST.ST_DESP_DATE%TYPE
    --sCust IN RM.RM_CUST%TYPE
     --)
     IS 
          --Insert Into TMP_ALL_FEES 
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
 
    
              ;

    
    BEGIN
    
    nCheckpoint := 1;
      v_query := 'TRUNCATE TABLE TMP_ALL_FEES';
      EXECUTE IMMEDIATE v_query;
    
    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
        
        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_ALL_FEES VALUES l_data(i); 
        --USING sCust;
        
        EXIT WHEN c%NOTFOUND;

        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
     --  FOR i IN l_data.FIRST .. l_data.LAST LOOP
     --   DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
      --END LOOP;

  COMMIT;
  --RETURN;
  
  dbms_output.put_line
    (round((dbms_utility.get_time-l_start)/100, 2) ||
    ' Seconds...' );
    
  DBMS_OUTPUT.PUT_LINE('EOM Merge All Fees for all customer for the date range '); 
     ---- || start_date || ' -- ' || end_date);
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM Merge All  Fees for all customer for the date range ' );
    --  || start_date || ' -- ' || end_date);
      RAISE;

  END EOM_TMP_MERGE_ALL_FEES;
  
  /*   Run this once for each intercompany customer   */
  /*   This gets all the intercompany storage Charges   */
  /*   Temp Tables Used   */
  /*   1. Tmp_Locn_Cnt_By_Cust   */
  PROCEDURE EOM_CREATE_TEMP_DATA_LOCATIONS (
     sAnalysis IN RM.RM_ANAL%TYPE
     ) 
     
  IS
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
    l_start number default dbms_utility.get_time;
	BEGIN

	/* Truncate all temp tables*/
		nCheckpoint := 1;
    v_query := 'TRUNCATE TABLE Tmp_Locn_Cnt_By_Cust';
		EXECUTE IMMEDIATE v_query;
		
		nCheckpoint := 2;
		v_query := q'{INSERT INTO Tmp_Locn_Cnt_By_Cust
						SELECT Count(DISTINCT NI_STOCK) AS CountOfStocks, IL_LOCN, IM_CUST, 
                      CASE WHEN Upper(substr(IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                        ELSE 'F- Shelves'
                        END AS "Note"
						FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
						INNER JOIN IM ON IM_STOCK = NI_STOCK
						WHERE IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_ANAL = :sAnalysis AND RM_TYPE = :v_p_RM_TYPE AND RM_ACTIVE = :v_p_IM_ACTIVE )
						AND IM_ACTIVE = :v_p_IM_ACTIVE
						AND NI_AVAIL_ACTUAL >= :v_p_NI_AVAIL_ACTUAL
						AND NI_STATUS <> :v_p_NI_STATUS
						GROUP BY IL_LOCN, IM_CUST,IL_NOTE_2
            }';
		EXECUTE IMMEDIATE v_query USING sAnalysis,p_RM_TYPE,p_IM_ACTIVE,p_IM_ACTIVE,p_NI_AVAIL_ACTUAL,p_NI_STATUS;

	
		DBMS_OUTPUT.PUT_LINE('Successfully inserted fresh temporary data');


    RETURN;
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END EOM_CREATE_TEMP_DATA_LOCATIONS;

  /*   Run this once for each customer including intercompany   */
  /*   This just runs all the above procedures from a single source   */
  /*   No Specific Temp Tables Used   */
  PROCEDURE Z_EOM_RUN_ALL (
      p_array_size_start IN PLS_INTEGER DEFAULT 100
        ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
        ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
        ,sCust_start IN RM.RM_CUST%TYPE,
      sAnalysis_Start IN RM.RM_ANAL%TYPE
  )
  AS
    nCheckpoint  NUMBER;
    l_start number default dbms_utility.get_time;
  BEGIN
    
    /*nCheckpoint := 1;
    	EOM_REPORT_PKG_TEST.A_EOM_GROUP_CUST();

    nCheckpoint := 2;
     EOM_REPORT_PKG_TEST.B_EOM_START_RUN_ONCE_DATA(start_date_start,end_date_start,sAnalysis_Start,sCust_start);
  */
    nCheckpoint := 3;
    --set timing on;
     EOM_REPORT_PKG_TEST.C_EOM_START_CUST_TEMP_DATA(sAnalysis_Start,sCust_start);
    
    --nCheckpoint := 4;
    --EXECUTE IMMEDIATE EOM_REPORT_PKG_TEST.D_EOM_GET_CUST_RATES(p_array_size_start,start_date_start,end_date_start,sCust_start);
    If ( sAnalysis_Start IS NULL ) Then
      nCheckpoint := 5;
      EOM_REPORT_PKG_TEST.EOM_TMP_ALL_FREIGHT_ALL_CUST(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
    
      nCheckpoint := 6;
      EOM_REPORT_PKG_TEST.EOM_TMP_ALL_ORD_FEES_ALL_CUST(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
    
      nCheckpoint := 7;
      EOM_REPORT_PKG_TEST.EOM_TMP_ALL_HAND_FEES_ALL_CUST(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
      DBMS_OUTPUT.PUT_LINE('Successfully Ran EOM_RUN_ALL');
      dbms_output.put_line
      (round((dbms_utility.get_time-l_start)/100, 2) ||
      ' Seconds...' );

      nCheckpoint := 8;
      EOM_REPORT_PKG_TEST.EOM_TMP_ALL_MISC_FEES_ALL_CUST(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
    
      nCheckpoint := 9;
      EOM_REPORT_PKG_TEST.EOM_TMP_ALL_STOR_FEES_ALL_CUST(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
      DBMS_OUTPUT.PUT_LINE('Successfully Ran EOM_RUN_ALL');
      dbms_output.put_line
      (round((dbms_utility.get_time-l_start)/100, 2) ||
      ' Seconds...' );
    
    
      nCheckpoint := 10;
      EOM_REPORT_PKG_TEST.EOM_TMP_CUSTOMER_FEES(p_array_size_start,start_date,end_date,sCust_start);
    
      --nCheckpoint := 11;
      --EOM_REPORT_PKG_TEST.EOM_TMP_PAL_CTN_FEES(p_array_size_start,start_date,end_date,sCust_start);
     
      nCheckpoint := 12;
      EOM_REPORT_PKG_TEST.EOM_TMP_CTN_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
      
     ElsIf (sAnalysis_Start IS NOT NULL) AND (sCust_start IS NOT NULL) Then
      nCheckpoint := 5;
      EOM_REPORT_PKG_TEST.EOM_TMP_ALL_FREIGHT_ALL_IC(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
    
      nCheckpoint := 6;
      EOM_REPORT_PKG_TEST.EOM_TMP_ALL_ORD_FEES_ALL_IC(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
    
      nCheckpoint := 7;
      EOM_REPORT_PKG_TEST.EOM_TMP_ALL_HAND_FEES_ALL_IC(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
      DBMS_OUTPUT.PUT_LINE('Successfully Ran EOM_RUN_ALL');
      dbms_output.put_line
      (round((dbms_utility.get_time-l_start)/100, 2) ||
      ' Seconds...' );

      nCheckpoint := 8;
      EOM_REPORT_PKG_TEST.EOM_TMP_ALL_MISC_FEES_ALL_IC(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
    
      nCheckpoint := 9;
      EOM_REPORT_PKG_TEST.EOM_TMP_ALL_STOR_FEES_ALL_IC(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
      DBMS_OUTPUT.PUT_LINE('Successfully Ran EOM_RUN_ALL');
      dbms_output.put_line
      (round((dbms_utility.get_time-l_start)/100, 2) ||
      ' Seconds...' );
    
      --nCheckpoint := 11;
      --EOM_REPORT_PKG_TEST.EOM_TMP_PAL_CTN_FEES(p_array_size_start,start_date,end_date,sCust_start);
     
      nCheckpoint := 12;
      EOM_REPORT_PKG_TEST.EOM_TMP_CTN_FEES_IC(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
     
     
     End If;
     nCheckpoint := 13;
     EOM_REPORT_PKG_TEST.EOM_TMP_MERGE_ALL_FEES();
    
    DBMS_OUTPUT.PUT_LINE('Successfully Ran EOM_RUN_ALL');
    dbms_output.put_line
    (round((dbms_utility.get_time-l_start)/100, 2) ||
    ' Seconds...' );

    RETURN;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM_RUN_ALL failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END Z_EOM_RUN_ALL;
  
  /*   PRESENTATION LAYER - TO BE COMPLETED   */
  /*   This will read customer query columns from a table   */
  /*   and query the specific temp table in the clients req format   */
  PROCEDURE ZZ_EOM_CUST_QRY_TMP(
     sCust IN RM.RM_CUST%TYPE
     ,sQueryType IN VARCHAR2
     ,src_tmp_qry OUT SYS_REFCURSOR
     ) 
    AS  
      SQLQuery2  VARCHAR2(6000);
      SQLQuery1  VARCHAR2(600);
      QueryTable VARCHAR2(60);
      nCheckpoint   NUMBER;
      sCust_Columns TMP_CUST_REPORTING.SHEADERS%TYPE;
      v_qry_tbl_1 CONSTANT VARCHAR2(50) := 'TMP_ADMIN';
      v_qry_tbl_2 CONSTANT VARCHAR2(50) := 'TMP_FREIGHT';
      v_qry_tbl_3 CONSTANT VARCHAR2(50) := 'TMP_ALL_FEES';
   BEGIN
    nCheckpoint := 0;
    If sQueryType = 'ADMIN' THEN QueryTable := v_qry_tbl_1;
    ElSIF sQueryType = 'FREIGHT' THEN QueryTable := v_qry_tbl_2; 
    ElSIF sQueryType = 'ALL' THEN QueryTable := v_qry_tbl_3; 
    END IF;
    --DBMS_OUTPUT.PUT_LINE('sQueryType is ' || sQueryType);
    nCheckpoint := 1;
    SQLQuery1 := 'Select SHEADERS FROM TMP_CUST_REPORTING where SCUST = :sCust1';
    EXECUTE IMMEDIATE SQLQuery1 INTO sCust_Columns USING sCust; 
    DBMS_OUTPUT.PUT_LINE('sCust_Columns are ' || sCust_Columns);
    DBMS_OUTPUT.PUT_LINE('QueryTable is ' || QueryTable);
    DBMS_OUTPUT.PUT_LINE('SQLQuery1 is ' || SQLQuery1);
    --If sQueryType != 'ALL' Then
    nCheckpoint := 2;
    If sCust_Columns IS NOT NULL Then
      SQLQuery2 := 'SELECT '|| sCust_Columns ||
              ' FROM ' || QueryTable ||' WHERE CUSTOMER = ' 
              || '''' || sCust || ''''
              || ' OR PARENT = '
              || '''' || sCust || '''';
    Else
      SQLQuery2 := 'SELECT '|| '*' ||
              ' FROM ' || QueryTable ||' WHERE CUSTOMER = ' 
              || '''' || sCust || ''''
              || ' OR PARENT = '
              || '''' || sCust || '''';
    End If;
    DBMS_OUTPUT.PUT_LINE('SQLQuery is ' || SQLQuery2);
    nCheckpoint := 3;
    OPEN src_tmp_qry FOR
    SQLQuery2;
    
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END ZZ_EOM_CUST_QRY_TMP;
 
  /*   This will read customer query columns from a table   */
  /*   and query the final temp table in the clients req format   */
  PROCEDURE ZZ_EOM_CUST_QRY_ALL_TMP(
     sCust IN RM.RM_CUST%TYPE
     ,src_tmp_qry OUT SYS_REFCURSOR
     ) 
    AS  
      SQLQuery2  VARCHAR2(6000);
      SQLQuery1  VARCHAR2(600);
      QueryTable VARCHAR2(60);
      nCheckpoint   NUMBER;
      sCust_Columns TMP_CUST_REPORTING.SHEADERS%TYPE;
      v_qry_tbl_1 CONSTANT VARCHAR2(50) := 'TMP_ADMIN';
      v_qry_tbl_2 CONSTANT VARCHAR2(50) := 'TMP_FREIGHT';
      v_qry_tbl_3 CONSTANT VARCHAR2(50) := 'TMP_ALL_FEES';
   BEGIN
      SQLQuery2 := 'SELECT '|| '*' ||
              ' FROM ' || v_qry_tbl_3 ||' WHERE CUSTOMER = ' 
              || '''' || sCust || ''''
              || ' OR PARENT = '
              || '''' || sCust || '''';
    
    DBMS_OUTPUT.PUT_LINE('SQLQuery is ' || SQLQuery2);
    nCheckpoint := 3;
    OPEN src_tmp_qry FOR
    SQLQuery2;
    
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END ZZ_EOM_CUST_QRY_ALL_TMP;
 
END EOM_REPORT_PKG_TEST;

/
