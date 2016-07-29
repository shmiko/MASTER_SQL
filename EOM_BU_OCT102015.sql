create or replace PACKAGE BODY EOM_REPORT_PKG_TEST
AS
  /*   A Group all customer down 3 tiers - this makes getting all children and grandchildren simples   */
  /*   Temp Tables Used   */
  /*   1. Tmp_Group_Cust   */
  /*   Runs in about 5 seconds   */
  /*   Tested and Working 17/7/15   */
  PROCEDURE A_EOM_GROUP_CUST AS
    nCheckpoint  NUMBER;
    l_start number default dbms_utility.get_time;
    v_query2 VARCHAR2(32767);
    v_time_taken VARCHAR2(205);

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


    --DBMS_OUTPUT.PUT_LINE('Successfully truncated, recreated AND populated Tmp_Group_Cust');
     v_query2 :=  SQL%ROWCOUNT;
    -- DBMS_OUTPUT.PUT_LINE('A EOM Group Cust temp tables  - There was ' || v_query2 || ' records inserted in ' ||  (round((dbms_utility.get_time-l_start)/100, 6) ||
    --  ' Seconds...' ));
    v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));

    EOM_INSERT_LOG(SYSTIMESTAMP ,NULL,NULL,'A_EOM_GROUP_CUST','RM','Tmp_Group_Cust',v_time_taken,SYSTIMESTAMP,NULL);
    DBMS_OUTPUT.PUT_LINE('A_EOM_GROUP_CUST for the date range '
    || F_FIRST_DAY_PREV_MONTH || ' -- ' || F_LAST_DAY_PREV_MONTH || ' - ' || v_query2
    || ' records inserted in ' ||  (round((dbms_utility.get_time-l_start)/100, 6)
    || ' Seconds...for all customers '));
    RETURN;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('A_EOM_GROUP_CUST failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END A_EOM_GROUP_CUST;

  /*   B Run this once for all customer data   */
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
     start_date IN VARCHAR2
     ,end_date IN VARCHAR2
     ,sAnalysis IN RM.RM_ANAL%TYPE
     ,sCust IN VARCHAR2
     ,PreData IN RM.RM_ACTIVE%TYPE := 0
     --,gdf_desp_freight_cur OUT sys_refcursor
     )
  AS
    --v_out_tx          VARCHAR2(32767);
    --v_query3           VARCHAR2(32767);
		v_query2          VARCHAR2(32767);
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
    l_start number default dbms_utility.get_time;
    tst_pick_counts tst_tmp_Admin_Data_Pick_Counts;
    v_time_taken VARCHAR2(205);

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
		--v_query := 'TRUNCATE TABLE Tmp_Batch_Price_SL_Stock';
		--EXECUTE IMMEDIATE v_query;




    /*Insert fresh temp data*/
		nCheckpoint := 11;
		EXECUTE IMMEDIATE 'INSERT INTO Tmp_Admin_Data_BreakPrices
							SELECT II_STOCK,II_CUST,II_BREAK_LCL,NULL,NULL,NULL,NULL
							FROM II INNER JOIN IM ON IM_STOCK = II_STOCK
							AND II_BREAK_LCL > 0.000001';

		nCheckpoint := 12;
    v_query := q'{INSERT INTO Tmp_Admin_Data_Pickslips
							SELECT LTrim(ST_PICK),LTrim(ST_PSLIP), substr(To_Char(ST_DESP_DATE),0,10), ST_WEIGHT, ST_PACKAGES,ST_XX_NUM_PAL_SW,ST_XX_NUM_PALLETS,ST_XX_NUM_CARTONS,NULL,NULL,NULL,NULL
							FROM ST LEFT JOIN SH ON SH_ORDER = ST_ORDER
							WHERE ST_DESP_DATE >= :start_date AND ST_DESP_DATE <= :end_date
              AND ST_PSLIP != 'CANCELLED'
							AND SH_STATUS <> 3}';
    EXECUTE IMMEDIATE v_query USING start_date,end_date;
		nCheckpoint := 13;
		v_query := q'{INSERT INTO Tmp_Admin_Data_Pick_LineCounts
							SELECT MAX(SL_LINE),LTrim(SL_PICK), LTrim(SL_ORDER), LTrim(SL_PSLIP),TP.vDateDesp, TP.vPackages,TP.vWeight,TP.vST_XX_NUM_PAL_SW,TP.vST_XX_NUM_PALLETS,TP.vST_XX_NUM_CARTONS,NULL,NULL,NULL,NULL
							FROM Tmp_Admin_Data_Pickslips TP RIGHT JOIN SL ON LTrim(SL_PICK) = TP.vPickslip
              WHERE SL_EDIT_DATE >= :start_date AND SL_EDIT_DATE <= :end_date
              AND SL_PSLIP != 'CANCELLED'
							GROUP BY SL_PICK,SL_ORDER,SL_PSLIP,TP.vDateDesp,TP.vPackages,TP.vWeight,TP.vST_XX_NUM_PAL_SW,TP.vST_XX_NUM_PALLETS,TP.vST_XX_NUM_CARTONS}';
      EXECUTE IMMEDIATE v_query USING start_date,end_date;
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

   v_query2 :=  SQL%ROWCOUNT;
     --DBMS_OUTPUT.PUT_LINE('B_EOM_START_RUN_ONCE_DATA for date range ' || start_date || ' -- ' || end_date || 'for customer '|| sCust || ' - There was ' || v_query2 || ' records inserted in ' ||  (round((dbms_utility.get_time-l_start)/100, 6) ||
     -- ' Seconds...' ));
     v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
    EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,start_date,end_date,'B_EOM_START_RUN_ONCE_DATA','ST/SL','TMP_ADMIN_DATA_PICK_LINECOUNTS',v_time_taken,SYSTIMESTAMP,NULL);

    DBMS_OUTPUT.PUT_LINE('B_EOM_START_RUN_ONCE_DATA for the date range '
    || start_date || ' -- ' || end_date || ' - ' || v_query2
    || ' records inserted in ' ||  (round((dbms_utility.get_time-l_start)/100, 6)
    || ' Seconds...for all customers '));
	 If F_IS_TABLE_EEMPTY('TMP_ADMIN_DATA_PICK_LINECOUNTS') <= 0 Then
     DBMS_OUTPUT.PUT_LINE('B_EOM_START_RUN_ONCE_DATA as table is empty...Is it Really?????' );
     --EOM_REPORT_PKG_TEST.B_EOM_START_RUN_ONCE_DATA(start_date,end_date,sAnalysis_Start,sCust_start,0);
    End If;
 RETURN;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('B_EOM_START_RUN_ONCE_DATA failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
END B_EOM_START_RUN_ONCE_DATA;

  /*   C Run this once for each customer   */
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
    v_time_taken VARCHAR2(205);
		v_query2          VARCHAR2(32767);
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
    l_start number default dbms_utility.get_time;

  BEGIN

/* Truncate all temp tables*/


		nCheckpoint := 6;
		v_query := 'TRUNCATE TABLE Tmp_Locn_Cnt_By_Cust';
		EXECUTE IMMEDIATE v_query;

		nCheckpoint := 7;
		v_query := 'TRUNCATE TABLE tbl_AdminData';
		EXECUTE IMMEDIATE v_query;


		--DBMS_OUTPUT.PUT_LINE('Successfully truncated all temporary tables');



	/*Insert fresh temp data*/

   nCheckpoint := 15;
   If (sAnalysis IS NOT NULL) Then
    --EOM_REPORT_PKG_TEST.CC_EOM_TEMP_DATA_LOCATIONS(sAnalysis);
      v_query := q'{INSERT INTO Tmp_Locn_Cnt_By_Cust
						SELECT Count(DISTINCT NI_STOCK) AS CountOfStocks, IL_LOCN, IM_CUST,
                      CASE WHEN Upper(substr(IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                        ELSE 'F- Shelves'
                        END AS "Note",NULL,NULL,NULL,NULL
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


		DBMS_OUTPUT.PUT_LINE('Successfully inserted Tmp_Locn_Cnt_By_Cust fresh temporary data by analysis' || sAnalysis);


    RETURN;
    COMMIT;
    -- RETURN;
   ELSIF (sAnalysis IS NULL) AND (sCust IS NOT NULL) Then
		v_query := q'{INSERT INTO Tmp_Locn_Cnt_By_Cust
						SELECT Count(DISTINCT NI_STOCK) AS CountOfStocks, IL_LOCN, IM_CUST,
                      CASE WHEN Upper(substr(IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                        ELSE 'F- Shelves'
                        END AS "Note",NULL,NULL,NULL,NULL
						FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
						INNER JOIN IM ON IM_STOCK = NI_STOCK
						WHERE IM_CUST IN :customer
						AND IM_ACTIVE = :v_p_IM_ACTIVE
						AND NI_AVAIL_ACTUAL >= :v_p_NI_AVAIL_ACTUAL
						AND NI_STATUS <> :v_p_NI_STATUS
						GROUP BY IL_LOCN, IM_CUST,IL_NOTE_2}';
        /*(SELECT RM_CUST FROM RM WHERE RM_ANAL = :sAnalysis AND RM_TYPE = :v_p_RM_TYPE AND RM_ACTIVE = :v_p_IM_ACTIVE )*/
		EXECUTE IMMEDIATE v_query USING sCust,p_IM_ACTIVE,p_NI_AVAIL_ACTUAL,p_NI_STATUS;

		--DBMS_OUTPUT.PUT_LINE('Successfully inserted Tmp_Locn_Cnt_By_Cust fresh temporary data  by customer' || sCust);
    v_query2 :=  SQL%ROWCOUNT;
    -- DBMS_OUTPUT.PUT_LINE('C_EOM_START_CUST_TEMP_DATA temp tables for ' || sCust || ' - There was ' || v_query2 || ' records inserted in ' ||  (round((dbms_utility.get_time-l_start)/100, 6) ||
    --  ' Seconds...' ));
    RETURN;
    -- v_query2 :=  SQL%ROWCOUNT;

    COMMIT;
    v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
    EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,NULL,NULL,'C_EOM_START_CUST_TEMP_DATA','IL/NI','Tmp_Locn_Cnt_By_Cust',v_time_taken,SYSTIMESTAMP,sCust);

    DBMS_OUTPUT.PUT_LINE('C_EOM_START_CUST_TEMP_DATA for the date range '
    || F_FIRST_DAY_PREV_MONTH || ' -- ' || F_LAST_DAY_PREV_MONTH || ' - ' || v_query2
    || ' records inserted in ' ||  (round((dbms_utility.get_time-l_start)/100, 6)
    || ' Seconds...for customer ' || sCust));

	  END IF;

 EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
END C_EOM_START_CUST_TEMP_DATA;

   /*   C Run this once for each customer   */
  /*   This gets all the storage data   */
  /*   Temp Tables Used   */
  /*   1. Tmp_Locn_Cnt_By_Cust   */
  /*   2. tbl_AdminData   */
  /*   Runs in about 20 seconds    */
  /*   Tested and Working 17/7/15   */
  PROCEDURE C_EOM_START_ALL_TEMP_STOR_DATA
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
    v_time_taken VARCHAR2(205);
    v_query2          VARCHAR2(32767);
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
    l_start number default dbms_utility.get_time;

  BEGIN

/* Truncate all temp tables*/


		--nCheckpoint := 6;
		--v_query := 'TRUNCATE TABLE Tmp_Locn_Cnt_By_Cust';
		--EXECUTE IMMEDIATE v_query;

		--nCheckpoint := 7;
		--v_query := 'TRUNCATE TABLE tbl_AdminData';
		--EXECUTE IMMEDIATE v_query;


		--DBMS_OUTPUT.PUT_LINE('Successfully truncated all temporary tables');



	/*Insert fresh temp data*/

   nCheckpoint := 15;

		v_query := q'{INSERT INTO Tmp_Locn_Cnt_By_Cust
						SELECT Count(DISTINCT NI_STOCK) AS CountOfStocks, IL_LOCN, IM_CUST,
                      CASE WHEN Upper(substr(IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                        ELSE 'F- Shelves'
                        END AS "Note",NULL,NULL,NULL,NULL
						FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
						INNER JOIN IM ON IM_STOCK = NI_STOCK
						WHERE IM_ACTIVE = 1
						AND NI_AVAIL_ACTUAL >= 1
						AND NI_STATUS <> 3
						GROUP BY IL_LOCN, IM_CUST,IL_NOTE_2}';
        /*(SELECT RM_CUST FROM RM WHERE RM_ANAL = :sAnalysis AND RM_TYPE = :v_p_RM_TYPE AND RM_ACTIVE = :v_p_IM_ACTIVE )*/
    If F_IS_TABLE_EEMPTY('Tmp_Locn_Cnt_By_Cust') <= 0 Then
      EXECUTE IMMEDIATE v_query;-- USING p_IM_ACTIVE,p_NI_AVAIL_ACTUAL,p_NI_STATUS;
    Else
      DBMS_OUTPUT.PUT_LINE('C_EOM_START_ALL_TEMP_STOR_DATA table is not empty still took ' || (round((dbms_utility.get_time-l_start)/100, 6)));
    End If;
		--DBMS_OUTPUT.PUT_LINE('Successfully inserted Tmp_Locn_Cnt_By_Cust fresh temporary data  by customer' || sCust);

    -- DBMS_OUTPUT.PUT_LINE('C_EOM_START_CUST_TEMP_DATA temp tables for ' || sCust || ' - There was ' || v_query2 || ' records inserted in ' ||  (round((dbms_utility.get_time-l_start)/100, 6) ||
    --  ' Seconds...' ));
    RETURN;
    v_query2 :=  SQL%ROWCOUNT;

    COMMIT;
    --IF v_query2 > 0 THEN
    If F_IS_TABLE_EEMPTY('Tmp_Locn_Cnt_By_Cust') <= 0 Then
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,sysdate,sysdate,'C_EOM_START_ALL_TEMP_STOR_DATA','IL/NI','Tmp_Locn_Cnt_By_Cust',v_time_taken,SYSTIMESTAMP,NULL);
      DBMS_OUTPUT.PUT_LINE('C_EOM_START_ALL_TEMP_STOR_DATA for the date range '
      || F_FIRST_DAY_PREV_MONTH || ' -- ' || F_LAST_DAY_PREV_MONTH || ' - ' || v_query2
      || ' records inserted in ' ||  (round((dbms_utility.get_time-l_start)/100, 6)
      || ' Seconds...for customer ' || sCust));
    Else
      DBMS_OUTPUT.PUT_LINE('C_EOM_START_ALL_TEMP_STOR_DATA rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)));
    End If;

 EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
END C_EOM_START_ALL_TEMP_STOR_DATA;



  /*   D Run this once for each customer   */
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

  /*   E1_PHONE_ORD_FEES Run this once for each customer   */
  /*   This gets all the Phone Order Related Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_PHONE_ORD_FEES   */
  /*   Prism Rate Field Used   */
  /*   A. RM_XX_FEE03   */
  PROCEDURE E1_PHONE_ORD_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
      ,sAnalysis IN RM.RM_ANAL%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_PHONE_ORD_FEES%ROWTYPE;
    l_data ARRAY;
    v_time_taken VARCHAR2(205);
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
    l_start number default dbms_utility.get_time;

    QueryTable5 VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE03,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode5}';
      sCust_Rates5 RM.RM_XX_FEE03%TYPE;/*1 PhoneOrderEntryFee*/
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
			  substr(To_Char(s.SH_ADD_DATE),0,10),
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
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  sCust_Rates5--(Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN sCust_Rates5-- (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN sCust_Rates5-- (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN  sCust_Rates5--(Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust)
			  ELSE NULL
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN sCust_Rates5 * 1.1-- (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
			  ELSE NULL
			  END,
        CASE    WHEN s.SH_SPARE_DBL_9 = 1 THEN sCust_Rates5 * 1.1-- (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
			  ELSE NULL
			  END,
			  NULL,
			  REPLACE(s.SH_ADDRESS, ','),REPLACE(s.SH_SUBURB, ','),
			  s.SH_CITY,s.SH_STATE,
			  s.SH_POST_CODE,REPLACE(s.SH_NOTE_1, ','),
			  REPLACE(s.SH_NOTE_2, ','),
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
        s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
        d.SD_NOTE_1,d.SD_COST_PRICE,
        d.SD_XX_FREIGHT_CHG
	FROM      PWIN175.SH s
			  INNER JOIN PWIN175.SD d ON d.SD_ORDER  = s.SH_ORDER
			  INNER JOIN PWIN175.IM i ON i.IM_STOCK = d.SD_STOCK
			  --//INNER JOIN PWIN175.ST t ON t.ST_ORDER = s.SH_ORDER AND t.ST_PICK = s.SH_LAST_PICK_NUM
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
			  --LEFT JOIN PWIN175.RM r2 ON r2.RM_ANAL = r.RM_ANAL AND r2.RM_CUST = :cust
	WHERE (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
  --AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
 --AND       t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate
  AND       s.SH_ADD_DATE >= startdate AND s.SH_ADD_DATE <= enddate
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL -- so as to stop charging twice for the same order fee when the despatches have been split
	AND       s.SH_SPARE_DBL_9 = 1
	AND       d.SD_LINE = 1
  --AND (SELECT To_Number(regexp_substr(RM_XX_FEE03,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) > 0.1
	GROUP BY   s.SH_CUST,r.sGroupCust,i.IM_CUST,s.SH_SPARE_STR_4,i.IM_XX_COST_CENTRE01,
        s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,s.SH_SPARE_DBL_9,d.SD_LINE,
        s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_NOTE_2,s.SH_SPARE_STR_3,
        i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4,s.SH_SPARE_STR_1,
        --t.ST_PACKAGES,t.ST_WEIGHT,t.ST_ORDER,t.ST_PICK,
        i.IM_OWNED_By,i.IM_PROFILE,
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
        d.SD_NOTE_1,d.SD_COST_PRICE,
        d.SD_XX_FREIGHT_CHG,s.SH_ADD_DATE,d.SD_COST_PRICE,
        s.SH_LAST_PICK_NUM,r.sCust,s.SH_PREV_PSLIP_NUM,i.IM_TYPE,s.SH_STATUS,
        i.IM_BRAND,d.SD_LAST_PICK_NUM,s.SH_CAMPAIGN,d.SD_ORDER,d.SD_STOCK;


    BEGIN
    nCheckpoint := 10;

    EXECUTE IMMEDIATE QueryTable5 INTO sCust_Rates5 USING sCustomerCode;/*1 PhoneOrderEntryFee*/

      nCheckpoint := 11;
      v_query := 'TRUNCATE TABLE TMP_PHONE_ORD_FEES';
      EXECUTE IMMEDIATE v_query;

    IF sCust_Rates5 IS NOT NULL THEN
      --DBMS_OUTPUT.PUT_LINE('E1_PHONE_ORD_FEES rates are $' || sCust_Rates5 || '. Prism rate field is RM_XX_FEE03.');

    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;

        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_PHONE_ORD_FEES VALUES l_data(i);
        --USING sCust;

        EXIT WHEN c%NOTFOUND;

        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
--       FOR i IN l_data.FIRST .. l_data.LAST LOOP
--        DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
--      END LOOP;
    v_query2 :=  SQL%ROWCOUNT;
    COMMIT;
    IF v_query2 > 0 THEN
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'E1_PHONE_ORD_FEES','SH','TMP_PHONE_ORD_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
      DBMS_OUTPUT.PUT_LINE('E1_PHONE_ORD_FEES for the date range '
      || startdate || ' -- ' || enddate || ' - ' || v_query2
      || ' records inserted into table TMP_PHONE_ORD_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
      || ' Seconds...for customer ' || sCustomerCode );
    Else
      DBMS_OUTPUT.PUT_LINE('E1_PHONE_ORD_FEES rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
  Else
      DBMS_OUTPUT.PUT_LINE('E1_PHONE_ORD_FEES rates are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('E1_PHONE_ORD_FEES failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;

  END E1_PHONE_ORD_FEES;

  /*   E2_EMAIL_ORD_FEES Run this once for each customer   */
  /*   This gets all the Email Order Related Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_EMAIL_ORD_FEES   */
  /*   Prism Rate Field Used   */
  /*   A. RM_XX_FEE02   */
  PROCEDURE E2_EMAIL_ORD_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
      ,sAnalysis IN RM.RM_ANAL%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_EMAIL_ORD_FEES%ROWTYPE;
    l_data ARRAY;
    v_time_taken VARCHAR2(205);
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
    nbreakpoint   NUMBER;
    l_start number default dbms_utility.get_time;
    QueryTable4 VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE02,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode4}';
  sCust_Rates4 RM.RM_XX_FEE02%TYPE;/*EmailOrderEntryFee*/
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
			  NULL                    AS "DespNote",
			  NULL  AS "DespDate",
			  substr(To_Char(s.SH_ADD_DATE),0,10) AS "OrderDate",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  'EmailOrderEntryFee'
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
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN sCust_Rates4--(Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = sCustomerCode)
			  ELSE NULL
			  END                     AS "UnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN sCust_Rates4--(Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = sCustomerCode)
			  ELSE NULL
			  END                     AS "OWUnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN   sCust_Rates4--(Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = sCustomerCode)
			  ELSE NULL
			  END                     AS "DExcl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  sCust_Rates4--(Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = sCustomerCode)
			  ELSE NULL
			  END                     AS "Excl_Total",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN   sCust_Rates4 * 1.1--(Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = sCustomerCode) * 1.1
			  ELSE NULL
			  END                     AS "DIncl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 3 THEN  sCust_Rates4 * 1.1-- (Select To_Number(rm3.RM_XX_FEE02) from RM rm3 where rm3.RM_CUST = sCustomerCode) * 1.1
			  ELSE NULL
			  END                     AS "Incl_Total",
			  NULL                    AS "ReportingPrice",
			  REPLACE(s.SH_ADDRESS, ',')            AS "Address",
			  REPLACE(s.SH_SUBURB, ',')             AS "Address2",
			  s.SH_CITY               AS "Suburb",
			  s.SH_STATE              AS "State",
			  s.SH_POST_CODE          AS "Postcode",
			  REPLACE(s.SH_NOTE_1, ',')             AS "DeliverTo",
			  REPLACE(s.SH_NOTE_2, ',')             AS "AttentionTo" ,
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
           i.IM_OWNED_By,i.IM_PROFILE,
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
        d.SD_NOTE_1,d.SD_COST_PRICE,
        d.SD_XX_FREIGHT_CHG
	FROM      PWIN175.SH s
			  INNER JOIN PWIN175.SD d ON d.SD_ORDER  = s.SH_ORDER
			  INNER JOIN PWIN175.IM i ON i.IM_STOCK = d.SD_STOCK
			  --INNER JOIN PWIN175.ST t ON t.ST_ORDER = s.SH_ORDER AND t.ST_PICK = s.SH_LAST_PICK_NUM
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
			  --LEFT JOIN PWIN175.RM r2 ON r2.RM_ANAL = r.RM_ANAL AND r2.RM_CUST = :cust
	WHERE (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
  --AND       t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate
  AND       s.SH_ADD_DATE >= startdate AND s.SH_ADD_DATE <= enddate
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	AND       s.SH_SPARE_DBL_9 = 3
	AND       d.SD_LINE = 1
	AND (SELECT To_Number(regexp_substr(RM_XX_FEE02,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) > 0.1
	GROUP BY   s.SH_CUST,r.sGroupCust,i.IM_CUST,s.SH_SPARE_STR_4,i.IM_XX_COST_CENTRE01,
        s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,s.SH_SPARE_DBL_9,d.SD_LINE,
        s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_NOTE_2,s.SH_SPARE_STR_3,
        i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4,s.SH_SPARE_STR_1,
        --t.ST_PACKAGES,t.ST_WEIGHT,t.ST_ORDER,t.ST_PICK,t.ST_DESP_DATE,
        i.IM_OWNED_By,i.IM_PROFILE,
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
        d.SD_NOTE_1,d.SD_COST_PRICE,
        d.SD_XX_FREIGHT_CHG,s.SH_ADD_DATE,d.SD_COST_PRICE,
        s.SH_LAST_PICK_NUM,r.sCust,s.SH_PREV_PSLIP_NUM,i.IM_TYPE,s.SH_STATUS,
        i.IM_BRAND,d.SD_LAST_PICK_NUM,s.SH_CAMPAIGN,d.SD_ORDER,d.SD_STOCK;




    BEGIN

    nCheckpoint := 10;
    EXECUTE IMMEDIATE QueryTable4 INTO sCust_Rates4 USING sCustomerCode;/*EmailOrderEntryFee*/

    nCheckpoint := 11;
    v_query := 'TRUNCATE TABLE TMP_EMAIL_ORD_FEES';
    EXECUTE IMMEDIATE v_query;


    IF sCust_Rates4 IS NOT NULL THEN
     -- DBMS_OUTPUT.PUT_LINE('E2_EMAIL_ORD_FEES rates are $' || sCust_Rates4 || '.Prism rate field is RM_XX_FEE02.');

    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;

        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_EMAIL_ORD_FEES VALUES l_data(i);
        --USING sCust;

        EXIT WHEN c%NOTFOUND;

        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;

    v_query2 :=  SQL%ROWCOUNT;
    COMMIT;

    IF v_query2 > 0 THEN
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'E2_EMAIL_ORD_FEES','SH','TMP_EMAIL_ORD_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
      DBMS_OUTPUT.PUT_LINE('E2_EMAIL_ORD_FEES for the date range '
      || startdate || ' -- ' || enddate || ' - ' || v_query2
      || ' records inserted into table TMP_EMAIL_ORD_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
      || ' Seconds...for customer ' || sCustomerCode );
    Else
      DBMS_OUTPUT.PUT_LINE('E2_EMAIL_ORD_FEES rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
  Else
    DBMS_OUTPUT.PUT_LINE('E2_EMAIL_ORD_FEES rates are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
  END IF;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('E2_EMAIL_ORD_FEES failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END E2_EMAIL_ORD_FEES;

  /*   E3_FAX_ORD_FEES Run this once for each customer   */
  /*   This gets all the Fax Order Related Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_FAX_ORD_FEES   */
  /*   Prism Rate Field Used   */
  /*   A. RM_XX_FEE07   */
  PROCEDURE E3_FAX_ORD_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
      ,sAnalysis IN RM.RM_ANAL%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_FAX_ORD_FEES%ROWTYPE;
    l_data ARRAY;
    v_time_taken VARCHAR2(205);
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
    nbreakpoint   NUMBER;
    l_start number default dbms_utility.get_time;
    QueryTable3 VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE07,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode3}';
  sCust_Rates3 RM.RM_XX_FEE07%TYPE;/*FaxOrderEntryFee*/

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
			  NULL                    AS "DespNote",
			  NULL  AS "DespDate",
			  substr(To_Char(s.SH_ADD_DATE),0,10) AS "OrderDate",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  'FaxOrderEntryFee'
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
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN sCust_Rates3-- (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCustomerCode)
			  ELSE NULL
			  END                     AS "UnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN sCust_Rates3--(Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCustomerCode)
			  ELSE NULL
			  END                     AS "OWUnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN sCust_Rates3--(Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCustomerCode)
			  ELSE NULL
			  END                     AS "DExcl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN sCust_Rates3--(Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCustomerCode)
			  ELSE NULL
			  END                     AS "Excl_Total",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN   sCust_Rates3 * 1.1--(Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCustomerCode) * 1.1
			  ELSE NULL
			  END                     AS "DIncl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN sCust_Rates3 * 1.1--(Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCustomerCode) * 1.1
			  ELSE NULL
			  END                     AS "Incl_Total",
			  NULL                    AS "ReportingPrice",
			  REPLACE(s.SH_ADDRESS, ',')            AS "Address",
			  REPLACE(s.SH_SUBURB, ',')             AS "Address2",
			  REPLACE(s.SH_CITY, ',')               AS "Suburb",
			  s.SH_STATE              AS "State",
			  s.SH_POST_CODE          AS "Postcode",
			  REPLACE(s.SH_NOTE_1, ',')             AS "DeliverTo",
			  REPLACE(s.SH_NOTE_2, ',')             AS "AttentionTo" ,
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
          i.IM_OWNED_By,i.IM_PROFILE,
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
        d.SD_NOTE_1,d.SD_COST_PRICE,
        d.SD_XX_FREIGHT_CHG
	FROM      PWIN175.SH s
			  INNER JOIN PWIN175.SD d ON d.SD_ORDER  = s.SH_ORDER
			  INNER JOIN PWIN175.IM i ON i.IM_STOCK = d.SD_STOCK
			  --INNER JOIN PWIN175.ST t ON t.ST_ORDER = s.SH_ORDER AND t.ST_PICK = s.SH_LAST_PICK_NUM
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
			  --LEFT JOIN PWIN175.RM r2 ON r2.RM_ANAL = r.RM_ANAL AND r2.RM_CUST = :cust
	WHERE (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
  --AND       t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate
  AND       s.SH_ADD_DATE >= startdate AND s.SH_ADD_DATE <= enddate
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	AND       s.SH_SPARE_DBL_9 = 2
	AND       d.SD_LINE = 1
	AND (SELECT To_Number(regexp_substr(RM_XX_FEE07,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) > 0.1
	GROUP BY   s.SH_CUST,r.sGroupCust,i.IM_CUST,s.SH_SPARE_STR_4,i.IM_XX_COST_CENTRE01,
        s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,s.SH_SPARE_DBL_9,d.SD_LINE,
        s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_NOTE_2,s.SH_SPARE_STR_3,
        i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4,s.SH_SPARE_STR_1,
        --t.ST_PACKAGES,t.ST_WEIGHT,t.ST_ORDER,t.ST_PICK,t.ST_DESP_DATE,
        i.IM_OWNED_By,i.IM_PROFILE,
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
        d.SD_NOTE_1,d.SD_COST_PRICE,
        d.SD_XX_FREIGHT_CHG,s.SH_ADD_DATE,d.SD_COST_PRICE,
        s.SH_LAST_PICK_NUM,r.sCust,s.SH_PREV_PSLIP_NUM,i.IM_TYPE,s.SH_STATUS,
        i.IM_BRAND,d.SD_LAST_PICK_NUM,s.SH_CAMPAIGN,d.SD_ORDER,d.SD_STOCK;




    BEGIN
    nCheckpoint := 10;
    EXECUTE IMMEDIATE QueryTable3 INTO sCust_Rates3 USING sCustomerCode;/*FaxOrderEntryFee*/
    nCheckpoint := 11;
    v_query := 'TRUNCATE TABLE TMP_FAX_ORD_FEES';
    EXECUTE IMMEDIATE v_query;

    IF sCust_Rates3 IS NOT NULL THEN
      --DBMS_OUTPUT.PUT_LINE('E3_FAX_ORD_FEES rates are $' || sCust_Rates3 || '. Prism field is RM_XX_FEE07.');

    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;

        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_FAX_ORD_FEES VALUES l_data(i);
        --USING sCust;

        EXIT WHEN c%NOTFOUND;

        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
    v_query2 :=  SQL%ROWCOUNT;
    COMMIT;

    IF v_query2 > 0 THEN
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'E3_FAX_ORD_FEES','SH','TMP_FAX_ORD_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
      DBMS_OUTPUT.PUT_LINE('E3_FAX_ORD_FEES for the date range '
      || startdate || ' -- ' || enddate || ' - ' || v_query2
      || ' records inserted into table TMP_FAX_ORD_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
      || ' Seconds...for customer ' || sCustomerCode );
    Else
      DBMS_OUTPUT.PUT_LINE('E3_FAX_ORD_FEES rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
  Else
      DBMS_OUTPUT.PUT_LINE('E3_FAX_ORD_FEES rates are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
  END IF;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('E3_FAX_ORD_FEES failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END E3_FAX_ORD_FEES;

  /*   E3_MAN_ORD_FEES Run this once for each customer   */
  /*   This gets all the Fax Order Related Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_MAN_ORD_FEES   */
  /*   Prism Rate Field Used   */
  /*   A. RM_XX_FEE01   */
  PROCEDURE E3_MAN_ORD_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
      ,sAnalysis IN RM.RM_ANAL%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_MAN_ORD_FEES%ROWTYPE;
    l_data ARRAY;
    v_time_taken VARCHAR2(205);
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
    nbreakpoint   NUMBER;
    l_start number default dbms_utility.get_time;
    QueryTable3 VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE01,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode3}';
  sCust_Rates3 RM.RM_XX_FEE07%TYPE;/*FaxOrderEntryFee*/

    CURSOR c
    IS

  /*ManOrderEntryFee*/
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
			  NULL                    AS "DespNote",
			  NULL  AS "DespDate",
			  substr(To_Char(s.SH_ADD_DATE),0,10) AS "OrderDate",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  'ManOrderEntryFee'
			  ELSE ''
			  END                     AS "FeeType",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  'FEEORDERENTRYS'
			  ELSE ''
			  END                     AS "Item",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  'Man Order Entry Fee'
			  ELSE ''
			  END                     AS "Description",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  1
			  ELSE NULL
			  END                     AS "Qty",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN  '1'
			  ELSE ''
			  END                     AS "UOI",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN sCust_Rates3-- (Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCustomerCode)
			  ELSE NULL
			  END                     AS "UnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN sCust_Rates3--(Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCustomerCode)
			  ELSE NULL
			  END                     AS "OWUnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN sCust_Rates3--(Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCustomerCode)
			  ELSE NULL
			  END                     AS "DExcl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN sCust_Rates3--(Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCustomerCode)
			  ELSE NULL
			  END                     AS "Excl_Total",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN   sCust_Rates3 * 1.1--(Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCustomerCode) * 1.1
			  ELSE NULL
			  END                     AS "DIncl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 2 THEN sCust_Rates3 * 1.1--(Select To_Number(rm3.RM_XX_FEE07) from RM rm3 where rm3.RM_CUST = sCustomerCode) * 1.1
			  ELSE NULL
			  END                     AS "Incl_Total",
			  NULL                    AS "ReportingPrice",
			  REPLACE(s.SH_ADDRESS, ',')            AS "Address",
			  REPLACE(s.SH_SUBURB, ',')             AS "Address2",
			  REPLACE(s.SH_CITY, ',')               AS "Suburb",
			  s.SH_STATE              AS "State",
			  s.SH_POST_CODE          AS "Postcode",
			  REPLACE(s.SH_NOTE_1, ',')             AS "DeliverTo",
			  REPLACE(s.SH_NOTE_2, ',')             AS "AttentionTo" ,
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
           i.IM_OWNED_By,i.IM_PROFILE,
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
        d.SD_NOTE_1,d.SD_COST_PRICE,
        d.SD_XX_FREIGHT_CHG
	FROM      PWIN175.SH s
			  INNER JOIN PWIN175.SD d ON d.SD_ORDER  = s.SH_ORDER
			  INNER JOIN PWIN175.IM i ON i.IM_STOCK = d.SD_STOCK
			  --INNER JOIN PWIN175.ST t ON t.ST_ORDER = s.SH_ORDER AND t.ST_PICK = s.SH_LAST_PICK_NUM
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
			  --LEFT JOIN PWIN175.RM r2 ON r2.RM_ANAL = r.RM_ANAL AND r2.RM_CUST = :cust
	WHERE (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
  --AND       t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate
  AND       s.SH_ADD_DATE >= startdate AND s.SH_ADD_DATE <= enddate
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	AND       s.SH_SPARE_DBL_9 = 2
	AND       d.SD_LINE = 1
	--AND (SELECT To_Number(regexp_substr(RM_XX_FEE07,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) > 0.1
	GROUP BY   s.SH_CUST,r.sGroupCust,i.IM_CUST,s.SH_SPARE_STR_4,i.IM_XX_COST_CENTRE01,
        s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,s.SH_SPARE_DBL_9,d.SD_LINE,
        s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_NOTE_2,s.SH_SPARE_STR_3,
        i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4,s.SH_SPARE_STR_1,
        --t.ST_PACKAGES,t.ST_WEIGHT,t.ST_ORDER,t.ST_PICK,t.ST_DESP_DATE,
        i.IM_OWNED_By,i.IM_PROFILE,
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
        d.SD_NOTE_1,d.SD_COST_PRICE,
        d.SD_XX_FREIGHT_CHG,s.SH_ADD_DATE,d.SD_COST_PRICE,
        s.SH_LAST_PICK_NUM,r.sCust,s.SH_PREV_PSLIP_NUM,i.IM_TYPE,s.SH_STATUS,s.SH_ADD_DATE,
        i.IM_BRAND,d.SD_LAST_PICK_NUM,s.SH_CAMPAIGN,d.SD_ORDER,d.SD_STOCK;




    BEGIN
    nCheckpoint := 10;
    EXECUTE IMMEDIATE QueryTable3 INTO sCust_Rates3 USING sCustomerCode;/*FaxOrderEntryFee*/
    nCheckpoint := 11;
    v_query := 'TRUNCATE TABLE TMP_MAN_ORD_FEES';
    EXECUTE IMMEDIATE v_query;

    IF sCust_Rates3 IS NOT NULL THEN
      --DBMS_OUTPUT.PUT_LINE('E3_MAN_ORD_FEES rates are $' || sCust_Rates3 || '. Prism field is RM_XX_FEE01.');

    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;

        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_MAN_ORD_FEES VALUES l_data(i);
        --USING sCust;

        EXIT WHEN c%NOTFOUND;

        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
    v_query2 :=  SQL%ROWCOUNT;
    COMMIT;

    IF v_query2 > 0 THEN
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'E3_MAN_ORD_FEES','SH','TMP_MAN_ORD_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
      DBMS_OUTPUT.PUT_LINE('E3_MAN_ORD_FEES for the date range '
      || startdate || ' -- ' || enddate || ' - ' || v_query2
      || ' records inserted into table TMP_MAN_ORD_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
      || ' Seconds...for customer ' || sCustomerCode );
    Else
      DBMS_OUTPUT.PUT_LINE('E3_MAN_ORD_FEES rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
  Else
      DBMS_OUTPUT.PUT_LINE('E3_MAN_ORD_FEES rates are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
  END IF;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('E3_MAN_ORD_FEES failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END E3_MAN_ORD_FEES;


  /*   E4_VERBAL_ORD_FEES Run this once for each customer   */
  /*   This gets all the Verbal Order Related Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_VERBAL_ORD_FEES   */
  /*   Prism Rate Field Used   */
  /*   A. RM_XX_FEE01   */
  PROCEDURE E4_VERBAL_ORD_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
      ,sAnalysis IN RM.RM_ANAL%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_VERBAL_ORD_FEES%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_time_taken VARCHAR2(205);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
    nbreakpoint   NUMBER;
    l_start number default dbms_utility.get_time;
    QueryTable2 VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE01,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode}';
    sCust_Rates2 RM.RM_XX_FEE01%TYPE;/*VerbalOrderEntryFee*/

     CURSOR c
    IS

  /*VerbalOrderEntryFee*/
	SELECT    s.SH_CUST               AS "Customer",
			  r.sGroupCust              AS "Parent",
			  s.SH_SPARE_STR_4         AS "CostCentre",
			  s.SH_ORDER              AS "Order",
			  s.SH_SPARE_STR_5         AS "OrderwareNum",
			  s.SH_CUST_REF            AS "CustomerRef",
			  NULL               AS "Pickslip",
			  NULL                    AS "DespNote",
			  NULL  AS "DespDate",
			  substr(To_Char(s.SH_ADD_DATE),0,10) AS "OrderDate",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 OR  s.SH_SPARE_DBL_9 = 9 THEN  'OrderEntryFee'
			  ELSE ''
			  END                     AS "FeeType",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 OR  s.SH_SPARE_DBL_9 = 9 THEN  'FEEORDERENTRYS'
			  ELSE ''
			  END                     AS "Item",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 OR  s.SH_SPARE_DBL_9 = 9 THEN  'Order Entry Fee'
			  ELSE ''
			  END                     AS "Description",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 OR  s.SH_SPARE_DBL_9 = 9 THEN  1
			  ELSE NULL
			  END                     AS "Qty",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 OR  s.SH_SPARE_DBL_9 = 9 THEN  '1'
			  ELSE ''
			  END                     AS "UOI",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 OR  s.SH_SPARE_DBL_9 = 9 THEN  sCust_Rates2--(Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = sCustomerCode)
			  ELSE NULL
			  END                     AS "UnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 OR  s.SH_SPARE_DBL_9 = 9 THEN  sCust_Rates2--(Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = sCustomerCode)
			  ELSE NULL
			  END                     AS "OWUnitPrice",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 OR  s.SH_SPARE_DBL_9 = 9 THEN  sCust_Rates2--(Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = sCustomerCode)
			  ELSE NULL
			  END                     AS "DExcl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 OR  s.SH_SPARE_DBL_9 = 9 THEN  sCust_Rates2--(Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = sCustomerCode)
			  ELSE NULL
			  END                     AS "Excl_Total",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 OR  s.SH_SPARE_DBL_9 = 9 THEN   sCust_Rates2 * 1.1--(Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = sCustomerCode) * 1.1
			  ELSE NULL
			  END                     AS "DIncl",
	  CASE    WHEN s.SH_SPARE_DBL_9 = 4 OR  s.SH_SPARE_DBL_9 = 9 THEN sCust_Rates2 * 1.1--(Select To_Number(rm3.RM_XX_FEE01) from RM rm3 where rm3.RM_CUST = sCustomerCode) * 1.1
			  ELSE NULL
			  END                     AS "Incl_Total",
			  NULL                    AS "ReportingPrice",
			  REPLACE(s.SH_ADDRESS, ',')            AS "Address",
			  REPLACE(s.SH_SUBURB, ',')             AS "Address2",
			  REPLACE(s.SH_CITY, ',')               AS "Suburb",
			  s.SH_STATE              AS "State",
			  s.SH_POST_CODE          AS "Postcode",
			  REPLACE(s.SH_NOTE_1, ',')             AS "DeliverTo",
			  REPLACE(s.SH_NOTE_2, ',')             AS "AttentionTo" ,
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
              NULL AS Brand,
           NULL AS    OwnedBy,
           NULL AS    sProfile,

        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
        d.SD_NOTE_1,d.SD_COST_PRICE,
        d.SD_XX_FREIGHT_CHG
	FROM      PWIN175.SH s
			  INNER JOIN PWIN175.SD d ON d.SD_ORDER  = s.SH_ORDER
			  --INNER JOIN PWIN175.IM i ON i.IM_STOCK = d.SD_STOCK
			  --INNER JOIN PWIN175.ST t ON t.ST_ORDER = s.SH_ORDER --AND t.ST_PICK = s.SH_LAST_PICK_NUM
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
			  --LEFT JOIN PWIN175.RM r2 ON r2.RM_ANAL = r.RM_ANAL AND r2.RM_CUST = :cust
	WHERE (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
  --AND       t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate
  AND       s.SH_ADD_DATE >= startdate AND s.SH_ADD_DATE <= enddate
	--AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	AND       s.SH_SPARE_DBL_9 = 4 OR  s.SH_SPARE_DBL_9 = 9
	AND       d.SD_LINE = 1;
 /* --AND (SELECT To_Number(regexp_substr(RM_XX_FEE01,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) > 0.1
	/*GROUP BY  s.SH_CUST,r.sGroupCust,i.IM_CUST,s.SH_SPARE_STR_4,i.IM_XX_COST_CENTRE01,
        s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,t.ST_DESP_DATE,s.SH_SPARE_DBL_9,d.SD_LINE,
        s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_NOTE_2,s.SH_SPARE_STR_3,
        i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4,s.SH_SPARE_STR_1,
        d.SD_ORDER,d.SD_STOCK,t.ST_ORDER,t.ST_PICK,s.SH_LAST_PICK_NUM,r.sCust,s.SH_PREV_PSLIP_NUM,i.IM_TYPE,s.SH_STATUS,
        i.IM_BRAND,t.ST_WEIGHT,t.ST_PACKAGES,d.SD_LAST_PICK_NUM,s.SH_CAMPAIGN;
*/



    BEGIN
    nCheckpoint := 10;
    EXECUTE IMMEDIATE QueryTable2 INTO sCust_Rates2 USING sCustomerCode;/*VerbalOrderEntryFee*/
    --DBMS_OUTPUT.PUT_LINE('E4_VERBAL_ORD_FEES rates are $' || sCust_Rates2 || '. Prism rate field is .');
    nCheckpoint := 11;
    v_query := 'TRUNCATE TABLE TMP_VERBAL_ORD_FEES';
    EXECUTE IMMEDIATE v_query;

    IF sCust_Rates2 IS NOT NULL THEN
      --DBMS_OUTPUT.PUT_LINE('E4_VERBAL_ORD_FEES rates are $' || sCust_Rates2 || '. Prism rate field is .');

    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;

        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_VERBAL_ORD_FEES VALUES l_data(i);
        --USING sCust;

        EXIT WHEN c%NOTFOUND;

        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
    v_query2 :=  SQL%ROWCOUNT;
    COMMIT;

    IF v_query2 > 0 THEN
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'E4_VERBAL_ORD_FEES','SH','TMP_VERBAL_ORD_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
      DBMS_OUTPUT.PUT_LINE('E4_VERBAL_ORD_FEES for the date range '
      || startdate || ' -- ' || enddate || ' - ' || v_query2
      || ' records inserted into table TMP_VERBAL_ORD_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
      || ' Seconds...for customer ' || sCustomerCode );
    Else
      DBMS_OUTPUT.PUT_LINE('E4_VERBAL_ORD_FEES rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
  Else
      DBMS_OUTPUT.PUT_LINE('E4_VERBAL_ORD_FEES rates are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
  END IF;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('E4_VERBAL_ORD_FEES failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
    RAISE;
  END E4_VERBAL_ORD_FEES;


  /*   E5_DESTOY_ORD_FEES Run this once for each customer   */
  /*   This gets all the Destruction Order Related Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_DESTROY_ORD_FEES   */
  /*   Prism Rate Field Used   */
  /*   A. RM_XX_FEE25   */
  PROCEDURE E5_DESTOY_ORD_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
      ,sAnalysis IN RM.RM_ANAL%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_DESTROY_ORD_FEES%ROWTYPE;
    l_data ARRAY;
    v_time_taken VARCHAR2(205);
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
    nbreakpoint   NUMBER;
    l_start number default dbms_utility.get_time;
    QueryTable VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode1}';
  sCust_Rates RM.RM_XX_FEE25%TYPE;/*Destruction Fee*/

     CURSOR c
    IS

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
			  t.ST_PICK                AS "PickNum",
			  t.ST_PSLIP               AS "DespNote",
			  substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
        substr(To_Char(s.SH_ADD_DATE),0,10) AS "OrderDate",
	  CASE    WHEN s.SH_NOTE_1 = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN 'Destruction Fee is '
			  ELSE NULL
			  END                      AS "FeeType",
	  CASE    WHEN d.SD_LINE IS NOT NULL THEN  'DESTRUCTION'
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
	  CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN sCust_Rates--(SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) -- (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust)
			 ELSE NULL
			 END                      AS "UnitPrice",
	  CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN sCust_Rates--(SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) -- (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust)
			 ELSE NULL
			 END                                      AS "OWUnitPrice",
			CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN sCust_Rates--(SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) -- (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust)
			 ELSE NULL
			 END                      AS "DExcl",
			  CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN sCust_Rates--(SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) -- (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust)
			 ELSE NULL
			 END                                 AS "Excl_Total",
	   CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN sCust_Rates * 1.1--(SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * 1.1-- (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust) * 1.1
			 ELSE NULL
			 END                      AS "DIncl",
	   CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN sCust_Rates * 1.1--(SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * 1.1 --  (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust)  * 1.1
			 ELSE NULL
			 END                      AS "Incl_Total",
	  CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN (Select To_Number(i.IM_REPORTING_PRICE) from IM i where i.IM_STOCK = d.SD_STOCK)
			  ELSE NULL
			  END                      AS "ReportingPrice",
			  REPLACE(s.SH_ADDRESS, ',')             AS "Address",
			  REPLACE(s.SH_SUBURB, ',')              AS "Address2",
			  REPLACE(s.SH_CITY, ',')                AS "Suburb",
			  s.SH_STATE               AS "State",
			  s.SH_POST_CODE           AS "Postcode",
			  REPLACE(s.SH_NOTE_1, ',')              AS "DeliverTo",
			  REPLACE(s.SH_NOTE_2, ',')              AS "AttentionTo" ,
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
            i.IM_OWNED_By,i.IM_PROFILE,
              s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
              s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
              d.SD_NOTE_1,d.SD_COST_PRICE,
              d.SD_XX_FREIGHT_CHG
	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
	WHERE
 -- SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) > 0
  --AND
  (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
  AND       (s.SH_NOTE_1 = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE')
	AND       s.SH_STATUS <> 3
	AND       d.SD_LINE = 1
	AND       s.SH_ORDER = t.ST_ORDER
	AND       t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate;



    BEGIN
    nCheckpoint := 10;
    EXECUTE IMMEDIATE QueryTable INTO sCust_Rates USING sCustomerCode;/*Destruction Fee*/

    nCheckpoint := 11;
    v_query := 'TRUNCATE TABLE TMP_DESTROY_ORD_FEES';
    EXECUTE IMMEDIATE v_query;

    IF sCust_Rates IS NOT NULL THEN
     -- DBMS_OUTPUT.PUT_LINE('E5_DESTROY_ORD_FEES rates are $' || sCust_Rates || '. Prism rate field is RM_XX_FEE25');


    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;

        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_DESTROY_ORD_FEES VALUES l_data(i);
        --USING sCust;

        EXIT WHEN c%NOTFOUND;

        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
    v_query2 :=  SQL%ROWCOUNT;
    COMMIT;
    IF v_query2 > 0 THEN
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'E5_DESTOY_ORD_FEES','SH','TMP_DESTROY_ORD_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
      DBMS_OUTPUT.PUT_LINE('E5_DESTOY_ORD_FEES for the date range '
      || startdate || ' -- ' || enddate || ' - ' || v_query2
      || ' records inserted into table TMP_DESTROY_ORD_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
      || ' Seconds...for customer ' || sCustomerCode );
    Else
      DBMS_OUTPUT.PUT_LINE('E5_DESTOY_ORD_FEES rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
  Else
      DBMS_OUTPUT.PUT_LINE('E5_DESTOY_ORD_FEES rates are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
  END IF;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('E5_DESTOY_ORD_FEES failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END E5_DESTOY_ORD_FEES;

   /*   F_EOM_TMP_AUTO_FREIGHT_ALL Run this once for each customer   */
  /*   This gets all the IFS freight and Manual Freight data   */
  /*   Temp Tables Used   */
  /*   1. TMP_FREIGHT   */
  PROCEDURE F_EOM_TMP_AUTO_FREIGHT_ALL (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_FREIGHT%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    v_time_taken VARCHAR2(205);
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

   -- if start_date IS NOT NULL then

    CURSOR c
    --(
      --start_date IN ST.ST_DESP_DATE%TYPE
    -- ,end_date IN ST.ST_DESP_DATE%TYPE
    --sCust IN RM.RM_CUST%TYPE
     --)

     IS




/* freight fees*/
		 select    s.SH_CUST                AS "Customer",
			  r.sGroupCust              AS "Parent",
			  s.SH_SPARE_STR_4         AS "CostCentre",
			  s.SH_ORDER               AS "Order",
			  s.SH_SPARE_STR_5         AS "OrderwareNum",
			  s.SH_CUST_REF            AS "CustomerRef",
			  t.ST_PICK                AS "PickNum",
			  t.ST_PSLIP               AS "DespNote",
			  substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
        substr(To_Char(s.SH_ADD_DATE),0,10) AS "OrderDate",
	      CASE  WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 0.1 THEN 'Freight Fee'
			          ELSE 'UnPricedAutoFreight'
			          END                      AS "FeeType",
			  d.SD_STOCK               AS "Item",
			  --'="' || To_Char(d.SD_DESC) || '"'               AS "Description",
	      REPLACE(d.SD_DESC,',','|')              AS "Description",
	      CASE  WHEN d.SD_LINE IS NOT NULL THEN  1
			        ELSE NULL
			        END                     AS "Qty",
	      CASE  WHEN d.SD_LINE IS NOT NULL THEN  '1'
			        ELSE NULL
			        END                      AS "UOI",

        f_calc_freight_fee(d.SD_SELL_PRICE,TRIM(d.SD_NOTE_1),sCustomerCode,d.SD_ORDER) AS "UnitPriceMarkedUp",
        CASE  WHEN d.SD_SELL_PRICE >= 1 THEN f_calc_freight_fee(d.SD_SELL_PRICE,TRIM(d.SD_NOTE_1),sCustomerCode,d.SD_ORDER)
			  ELSE d.SD_SELL_PRICE
        END AS "OWUnitPrice",
        CASE  WHEN d.SD_SELL_PRICE >= 1 THEN f_calc_freight_fee(d.SD_SELL_PRICE,TRIM(d.SD_NOTE_1),sCustomerCode,d.SD_ORDER)
			  ELSE d.SD_EXCL
        END AS "DExcl",
			  CASE  WHEN d.SD_SELL_PRICE >= 1 THEN f_calc_freight_fee(d.SD_SELL_PRICE,TRIM(d.SD_NOTE_1),sCustomerCode,d.SD_ORDER) * 1.1
			  ELSE d.SD_INCL
        END AS "DIncl",
        d.SD_XX_FREIGHT_CHG                   AS "ReportingPrice",
        CASE  WHEN regexp_substr(SD_NOTE_1,'\d') IS NOT NULL THEN TO_NUMBER(SD_NOTE_1) --TO_NUMBER(d.SD_NOTE_1,'fm999999.99999999','nls_numeric_characters = ''.,''')
			  ELSE TO_NUMBER('999')
        END AS "ReportingPrice",
			  d.SD_COST_PRICE           AS "COSTPRICE",
			  REPLACE(s.SH_ADDRESS, ',')             AS "Address",
			  REPLACE(s.SH_SUBURB, ',')              AS "Address2",
			  REPLACE(s.SH_CITY, ',')                AS "Suburb",
			  s.SH_STATE               AS "State",
			  s.SH_POST_CODE           AS "Postcode",
			  REPLACE(s.SH_NOTE_1, ',')              AS "DeliverTo",
			  REPLACE(s.SH_NOTE_2, ',')              AS "AttentionTo" ,
			  t.ST_WEIGHT              AS "Weight",
			  t.ST_PACKAGES            AS "Packages",
			  s.SH_SPARE_DBL_9         AS "OrderSource",
			  NULL AS "Pallet/Shelf Space", /*Pallet/Space*/
				NULL AS "Locn", /*Locn*/
				--0 AS "AvailSOH",/*Avail SOH*/
				0, --to_number(d.SD_SELL_PRICE) AS "CountOfStocks",
        CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			        ELSE ''
			        END AS Email,
              'N/A' AS Brand,
        d.SD_ADD_DATE,d.SD_ADD_OP,
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
        CASE  WHEN SD_NOTE_1 IS NOT NULL THEN  SD_NOTE_1
			        ELSE ''
			        END AS NOTE1,d.SD_COST_PRICE,
        d.SD_XX_FREIGHT_CHG
	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_PICK))  = LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM))
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
        --INNER JOIN PWIN175.SD d2 ON d.SD_ORDER  = d2.SD_ORDER
	WHERE     --s.SH_ORDER = d.SD_ORDER
	--AND       r.RM_ANAL = :sAnalysis
	--AND
  (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
	AND       d.SD_STOCK IN ('COURIERM','COURIERS','COURIER')
  --and (d.SD_DESC != d2.SD_DESC AND d.SD_LINE != d2.SD_LINE)
	--AND       s.SH_ORDER = t.ST_ORDER
	--AND       d.SD_SELL_PRICE >= 0.1
	AND       t.ST_PSLIP != 'CANCELLED'
  AND       d.SD_ADD_DATE >= startdate AND d.SD_ADD_DATE <= enddate
  --AND   d.SD_ADD_OP LIKE 'SERV%'
  AND   d.SD_ADD_OP = 'SERV2'
  --AND s.SH_ORDER LIKE '   1769147'

	GROUP BY  s.SH_CUST,
			  s.SH_SPARE_STR_4,
			  s.SH_ORDER,
			  t.ST_PICK,
			  d.SD_XX_PICKLIST_NUM,d.SD_XX_FREIGHT_CHG,
			  t.ST_PSLIP,
			  t.ST_DESP_DATE,d.SD_ORDER,
			  d.SD_STOCK,
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
        d.SD_NOTE_1,d.SD_COST_PRICE,
        d.SD_XX_FREIGHT_CHG,d.SD_ADD_DATE,d.SD_ADD_OP,
			  d.SD_DESC,
			  d.SD_LINE,
			  d.SD_EXCL,
			  d.SD_INCL,
			  d.SD_NOTE_1,
			  d.SD_SELL_PRICE,
			  d.SD_XX_OW_UNIT_PRICE,
			  d.SD_QTY_ORDER,s.SH_CAMPAIGN,
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
			  s.SH_SPARE_STR_5,s.SH_ADD_DATE,
			  s.SH_CUST_REF,
        s.SH_SPARE_STR_3,
        s.SH_SPARE_STR_1,
        t.ST_SPARE_DBL_1,
        d.SD_XX_PSLIP_NUM,
          d.SD_ADD_DATE,
          d.SD_XX_PICKLIST_NUM,
          d.SD_COST_PRICE,s.SH_CAMPAIGN;


    --USING ;
    nbreakpoint   NUMBER;
    l_start number default dbms_utility.get_time;
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
        --DBMS_OUTPUT.PUT_LINE(l_data(10) || '.' );
        INSERT INTO TMP_FREIGHT VALUES l_data(i);
        --USING sCust;

        EXIT WHEN c%NOTFOUND;

        END LOOP;
        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
       --FOR i IN l_data.FIRST .. l_data.LAST LOOP
        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
      --END LOOP;
  v_query2 :=  SQL%ROWCOUNT;
  COMMIT;

    IF v_query2 > 0 THEN
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'F_EOM_TMP_AUTO_FREIGHT_ALL','SD','TMP_FREIGHT',v_time_taken,SYSTIMESTAMP,sCustomerCode);
      DBMS_OUTPUT.PUT_LINE('F_EOM_TMP_AUTO_FREIGHT_ALL for the date range '
      || startdate || ' -- ' || enddate || ' - ' || v_query2
      || ' records inserted into table TMP_FREIGHT in ' || round((dbms_utility.get_time-l_start)/100, 6)
      || ' Seconds...for customer ' || sCustomerCode );
    Else
      DBMS_OUTPUT.PUT_LINE('F_EOM_TMP_AUTO_FREIGHT_ALL rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('F_EOM_TMP_AUTO_FREIGHT_ALL failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;

  END F_EOM_TMP_AUTO_FREIGHT_ALL;

  /*   F_EOM_TMP_MAN_FREIGHT_ALL Run this once for each customer   */
  /*   This gets all the IFS freight and Manual Freight data   */
  /*   Temp Tables Used   */
  /*   1. TMP_FREIGHT   TO TEST AS MANUAL*/
  PROCEDURE F_EOM_TMP_MAN_FREIGHT_ALL (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
    )
    IS

    TYPE ARRAY IS TABLE OF TMP_M_FREIGHT%ROWTYPE;
    l_data ARRAY;
    v_time_taken VARCHAR2(205);
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

   -- if start_date IS NOT NULL then

    CURSOR c
    --(
      --start_date IN ST.ST_DESP_DATE%TYPE
    -- ,end_date IN ST.ST_DESP_DATE%TYPE
    --sCust IN RM.RM_CUST%TYPE
     --)

     IS




/* F_EOM_TMP_MAN_FREIGHT_ALL freight fees*/
		 select    s.SH_CUST                AS "Customer",
			  r.sGroupCust              AS "Parent",
			  s.SH_SPARE_STR_4         AS "CostCentre",
			  s.SH_ORDER               AS "Order",
			  s.SH_SPARE_STR_5         AS "OrderwareNum",
			  s.SH_CUST_REF            AS "CustomerRef",
			 t.ST_PICK                AS "PickNum",
			  t.ST_PSLIP               AS "DespNote",
			  substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
        substr(To_Char(s.SH_ADD_DATE),0,10) AS "OrderDate",
	      CASE  WHEN  d.SD_SELL_PRICE >= 0.1  THEN 'Manual Freight Fee'
			          ELSE 'UnPricedManualFreight'
			          END                      AS "FeeType",
			  d.SD_STOCK               AS "Item",
			  REPLACE(d.SD_DESC,',','|')              AS "Description",
	      --'="' || To_Char(d.SD_DESC) || '"'               AS "Description",
	      CASE  WHEN d.SD_LINE IS NOT NULL THEN  1
			        ELSE NULL
			        END                     AS "Qty",
	      CASE  WHEN d.SD_LINE IS NOT NULL THEN  '1'
			        ELSE NULL
			        END                      AS "UOI",

        f_calc_freight_fee(d.SD_SELL_PRICE,TRIM(d.SD_NOTE_1),sCustomerCode,d.SD_ORDER) AS "UnitPriceMarkedUp",
        CASE  WHEN d.SD_SELL_PRICE >= 1 THEN f_calc_freight_fee(d.SD_SELL_PRICE,TRIM(d.SD_NOTE_1),sCustomerCode,d.SD_ORDER)
			  ELSE d.SD_SELL_PRICE
        END AS "OWUnitPrice",
        CASE  WHEN d.SD_SELL_PRICE >= 1 THEN f_calc_freight_fee(d.SD_SELL_PRICE,TRIM(d.SD_NOTE_1),sCustomerCode,d.SD_ORDER)
			  ELSE d.SD_EXCL
        END AS "DExcl",
			  CASE  WHEN d.SD_SELL_PRICE >= 1 THEN f_calc_freight_fee(d.SD_SELL_PRICE,TRIM(d.SD_NOTE_1),sCustomerCode,d.SD_ORDER) * 1.1
			  ELSE d.SD_INCL
        END AS "DIncl",
        d.SD_XX_FREIGHT_CHG                   AS "ReportingPrice",
         CASE  WHEN regexp_substr(SD_NOTE_1,'\d') IS NOT NULL THEN TO_NUMBER(SD_NOTE_1) --TO_NUMBER(d.SD_NOTE_1,'fm999999.99999999','nls_numeric_characters = ''.,''')
			  ELSE TO_NUMBER('999')
        END AS "ReportingPrice",
			  d.SD_COST_PRICE           AS "COSTPRICE",
			  REPLACE(s.SH_ADDRESS, ',')             AS "Address",
			  REPLACE(s.SH_SUBURB, ',')              AS "Address2",
			  REPLACE(s.SH_CITY, ',')                AS "Suburb",
			  s.SH_STATE               AS "State",
			  s.SH_POST_CODE           AS "Postcode",
			  REPLACE(s.SH_NOTE_1, ',')              AS "DeliverTo",
			  REPLACE(s.SH_NOTE_2, ',')              AS "AttentionTo" ,
			  t.ST_WEIGHT              AS "Weight",
			  t.ST_PACKAGES            AS "Packages",
			  s.SH_SPARE_DBL_9         AS "OrderSource",
			  NULL AS "Pallet/Shelf Space", /*Pallet/Space*/
				NULL AS "Locn", /*Locn*/
				--0 AS "AvailSOH",/*Avail SOH*/
				0, --to_number(d.SD_SELL_PRICE) AS "CountOfStocks",
        CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			        ELSE ''
			        END AS Email,
              'N/A' AS Brand,
            d.SD_ADD_DATE,d.SD_ADD_OP,
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
        d.SD_NOTE_1,d.SD_COST_PRICE,
        d.SD_XX_FREIGHT_CHG
	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_PICK))  = LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM))
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
        --INNER JOIN PWIN175.SD d2 ON d.SD_ORDER  = d2.SD_ORDER
	WHERE     --s.SH_ORDER = d.SD_ORDER
	--AND       r.RM_ANAL = :sAnalysis
	--AND
  (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
	AND
  d.SD_STOCK IN ('COURIERM','COURIERS','COURIER','DETENTIONTIMEM','DETENTIONTIMES','FREIGHTDUTY')
	--and (d.SD_DESC != d2.SD_DESC AND d.SD_LINE != d2.SD_LINE)
 -- AND LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM)) IS NOT NULL
  --AND       s.SH_ORDER = t.ST_ORDER
	--AND       d.SD_SELL_PRICE >= 0.1
	AND       t.ST_PSLIP != 'CANCELLED'
  AND       d.SD_ADD_DATE >= startdate AND d.SD_ADD_DATE <= enddate
  --AND   d.SD_ADD_OP IN ('PJ','RV','PRJ')
  AND   d.SD_ADD_OP = 'RV'
 -- AND
  --d.SD_ORDER >= '   1740626' AND  d.SD_ORDER <= '   1740626'

	GROUP BY  s.SH_CUST,
			  s.SH_SPARE_STR_4,s.SH_CAMPAIGN,
			  s.SH_ORDER,
			  t.ST_PICK,
			  d.SD_XX_PICKLIST_NUM,
			  t.ST_PSLIP,
			  t.ST_DESP_DATE,
			  d.SD_STOCK,d.SD_ADD_OP,
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
			  s.SH_NOTE_1,s.SH_ADD_DATE,
			  s.SH_NOTE_2,d.SD_ORDER,d.SD_XX_FREIGHT_CHG,
			  t.ST_WEIGHT,
			  t.ST_PACKAGES,
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
        d.SD_NOTE_1,d.SD_COST_PRICE,
        d.SD_XX_FREIGHT_CHG,
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
          d.SD_COST_PRICE,s.SH_CAMPAIGN;


--USING ;
    nbreakpoint   NUMBER;
    l_start number default dbms_utility.get_time;
    BEGIN

    nCheckpoint := 1;
      v_query := 'TRUNCATE TABLE TMP_M_FREIGHT';
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
        --DBMS_OUTPUT.PUT_LINE(l_data(10) || '.' );
        INSERT INTO TMP_M_FREIGHT VALUES l_data(i);
        --USING sCust;

        EXIT WHEN c%NOTFOUND;

        END LOOP;
        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
       --FOR i IN l_data.FIRST .. l_data.LAST LOOP
        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
      --END LOOP;
  v_query2 :=  SQL%ROWCOUNT;
  COMMIT;

    IF v_query2 > 0 THEN
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'F_EOM_TMP_MAN_FREIGHT_ALL','SD','TMP_M_FREIGHT',v_time_taken,SYSTIMESTAMP,sCustomerCode);
      DBMS_OUTPUT.PUT_LINE('F_EOM_TMP_MAN_FREIGHT_ALL for the date range '
      || startdate || ' -- ' || enddate || ' - ' || v_query2
      || ' records inserted into table TMP_M_FREIGHT in ' || round((dbms_utility.get_time-l_start)/100, 6)
      || ' Seconds...for customer ' || sCustomerCode );
    Else
      DBMS_OUTPUT.PUT_LINE('F_EOM_TMP_MAN_FREIGHT_ALL rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('F_EOM_TMP_MAN_FREIGHT_ALL failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;

  END F_EOM_TMP_MAN_FREIGHT_ALL;

   /*   F_EOM_TMP_MAN_FREIGHT_ALL Run this once for each customer   */
  /*   This gets all Freight data for queries   */
  /*   Temp Tables Used   */
  /*   1. TMP_ALL_FREIGHT_ALL   TO TEST AS MANUAL*/
  PROCEDURE F_EOM_TMP_ALL_FREIGHT_ALL (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
     -- ,sCustomerCode IN VARCHAR2
    )
    IS

    TYPE ARRAY IS TABLE OF TMP_ALL_FREIGHT_ALL%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
    v_time_taken VARCHAR2(205);
    v_run_datetime  VARCHAR2(205);
		nCheckpoint       NUMBER;
		sCourierm         VARCHAR2(20) := 'COURIERM';
    sCouriers         VARCHAR2(20) := 'COURIERS';
    sCourier         VARCHAR2(20) := 'COURIER%';
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




/* F_EOM_TMP_ALL_FREIGHT_ALL freight fees*/
		 select    s.SH_CUST                AS "Customer",
			  r.sGroupCust              AS "Parent",
			  s.SH_SPARE_STR_4         AS "CostCentre",
			  s.SH_ORDER               AS "Order",
			  s.SH_SPARE_STR_5         AS "OrderwareNum",
			  s.SH_CUST_REF            AS "CustomerRef",
			 t.ST_PICK                AS "PickNum",
			  t.ST_PSLIP               AS "DespNote",
			  substr(To_Char(d.SD_ADD_DATE),0,10)            AS "DespatchDate",
        substr(To_Char(s.SH_ADD_DATE),0,10) AS "OrderDate",
	      CASE  WHEN  d.SD_SELL_PRICE >= 0.1 AND   d.SD_ADD_OP = 'RV'  THEN 'Manual Freight Fee'
              WHEN  d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 0.1 AND LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM)) IS NOT NULL AND d.SD_ADD_OP = 'SERV2' THEN 'Freight Fee'
              WHEN  d.SD_ADD_OP != 'RV' AND   d.SD_ADD_OP != 'SERV2' AND d.SD_XX_FREIGHT_CHG > 0.1 THEN 'XX Manual Freight Fee'
              WHEN  d.SD_ADD_OP = 'SERV2' AND d.SD_XX_FREIGHT_CHG > 0.1 THEN 'XX? Manual Freight Fee'
              WHEN  d.SD_ADD_OP != 'RV' AND   d.SD_ADD_OP != 'SERV2' AND d.SD_SELL_PRICE >= 0.1 THEN 'Other Manual Freight Fee'
			          ELSE 'UnPricedManualFreight'
			          END                      AS "FeeType",
			  d.SD_STOCK               AS "Item",
			  REPLACE(d.SD_DESC,',','|')              AS "Description",
	      --'="' || To_Char(d.SD_DESC) || '"'               AS "Description",
	      CASE  WHEN d.SD_LINE IS NOT NULL THEN  1
			        ELSE NULL
			        END                     AS "Qty",
	      CASE  WHEN d.SD_LINE IS NOT NULL THEN  '1'
			        ELSE NULL
			        END                      AS "UOI",

        CASE  WHEN  d.SD_SELL_PRICE >= 0.1 AND   d.SD_ADD_OP = 'RV'  THEN f_calc_freight_fee(d.SD_SELL_PRICE,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER)
              WHEN  d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 0.1 AND LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM)) IS NOT NULL AND d.SD_ADD_OP = 'SERV2' THEN f_calc_freight_fee(d.SD_SELL_PRICE,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER)
              WHEN  d.SD_ADD_OP != 'RV' AND   d.SD_ADD_OP != 'SERV2' AND d.SD_XX_FREIGHT_CHG > 0.1 THEN f_calc_freight_fee(d.SD_XX_FREIGHT_CHG,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER)
              WHEN  d.SD_ADD_OP = 'SERV2' AND d.SD_XX_FREIGHT_CHG > 0.1 THEN f_calc_freight_fee(d.SD_XX_FREIGHT_CHG,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER)
               WHEN  d.SD_ADD_OP != 'RV' AND   d.SD_ADD_OP != 'SERV2' AND d.SD_SELL_PRICE >= 0.1 THEN f_calc_freight_fee(d.SD_SELL_PRICE,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER)
          ELSE TO_NUMBER('999')
        END AS "UnitPriceMarkedUp",
        d.SD_SELL_PRICE  AS "OWUnitPrice",
        CASE  WHEN d.SD_SELL_PRICE >= 1 THEN f_calc_freight_fee(d.SD_SELL_PRICE,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER)
			  ELSE d.SD_EXCL
        END AS "DExcl",
			  CASE  WHEN d.SD_SELL_PRICE >= 1 THEN f_calc_freight_fee(d.SD_SELL_PRICE,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER) * 1.1
			  ELSE d.SD_INCL
        END AS "DIncl",
        d.SD_XX_FREIGHT_CHG                   AS "ReportingPrice",
         CASE  WHEN regexp_substr(SD_NOTE_1,'\d') IS NOT NULL THEN TO_NUMBER(SD_NOTE_1) --TO_NUMBER(d.SD_NOTE_1,'fm999999.99999999','nls_numeric_characters = ''.,''')
			  ELSE TO_NUMBER('999')
        END AS "ReportingPrice",
			  d.SD_COST_PRICE           AS "COSTPRICE",
			  REPLACE(s.SH_ADDRESS, ',')             AS "Address",
			  REPLACE(s.SH_SUBURB, ',')              AS "Address2",
			  REPLACE(s.SH_CITY, ',')                AS "Suburb",
			  s.SH_STATE               AS "State",
			  s.SH_POST_CODE           AS "Postcode",
			  REPLACE(s.SH_NOTE_1, ',')              AS "DeliverTo",
			  REPLACE(s.SH_NOTE_2, ',')              AS "AttentionTo" ,
			  t.ST_WEIGHT              AS "Weight",
			  t.ST_PACKAGES            AS "Packages",
			  s.SH_SPARE_DBL_9         AS "OrderSource",
			  NULL AS "Pallet/Shelf Space", /*Pallet/Space*/
				NULL AS "Locn", /*Locn*/
				--0 AS "AvailSOH",/*Avail SOH*/
				0, --to_number(d.SD_SELL_PRICE) AS "CountOfStocks",
        CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			        ELSE ''
			        END AS Email,
              'N/A' AS Brand,
            null,null,
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
        d.SD_ADD_DATE,d.SD_ADD_OP,
        d.SD_XX_FREIGHT_CHG
	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  LEFT OUTER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_PICK))  = LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM))
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
        --INNER JOIN PWIN175.SD d2 ON d.SD_ORDER  = d2.SD_ORDER
	WHERE     --s.SH_ORDER = d.SD_ORDER
	--AND       r.RM_ANAL = :sAnalysis
	--AND
  --(r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
	--AND
  d.SD_STOCK IN ('COURIERM','COURIERS','COURIER','DETENTIONTIMEM','DETENTIONTIMES','FREIGHTDUTY')
	--and (d.SD_DESC != d2.SD_DESC AND d.SD_LINE != d2.SD_LINE)
 -- AND LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM)) IS NOT NULL
  --AND       s.SH_ORDER = t.ST_ORDER
	--AND       d.SD_SELL_PRICE >= 0.1
	--AND       t.ST_PSLIP != 'CANCELLED'
  AND       d.SD_ADD_DATE >= startdate AND d.SD_ADD_DATE <= enddate
  --AND   d.SD_ADD_OP IN ('PJ','RV','PRJ')
  --AND   d.SD_ADD_OP = 'RV'
 -- AND
  --d.SD_ORDER >= '   1740626' AND  d.SD_ORDER <= '   1740626'

	GROUP BY  s.SH_CUST,
			  s.SH_SPARE_STR_4,s.SH_CAMPAIGN,
			  s.SH_ORDER,
			  t.ST_PICK,
			  d.SD_XX_PICKLIST_NUM,
			  t.ST_PSLIP,
			  t.ST_DESP_DATE,
			  d.SD_STOCK,d.SD_ADD_OP,
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
			  s.SH_NOTE_1,s.SH_ADD_DATE,
			  s.SH_NOTE_2,d.SD_ORDER,d.SD_XX_FREIGHT_CHG,
			  t.ST_WEIGHT,
			  t.ST_PACKAGES,
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
        d.SD_NOTE_1,d.SD_COST_PRICE,
        d.SD_XX_FREIGHT_CHG,
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
          d.SD_COST_PRICE,s.SH_CAMPAIGN;


--USING ;
    nbreakpoint   NUMBER;
    l_start number default dbms_utility.get_time;

    BEGIN
   v_run_datetime := '';--SELECT CURRENT_TIMESTAMP from DUAL; --To_Char(sysdate) || To_Char(l_start);
    nCheckpoint := 1;
      v_query := 'TRUNCATE TABLE TMP_ALL_FREIGHT_ALL';
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
        --DBMS_OUTPUT.PUT_LINE(l_data(10) || '.' );
        INSERT INTO TMP_ALL_FREIGHT_ALL VALUES l_data(i);
        --USING sCust;

        EXIT WHEN c%NOTFOUND;

        END LOOP;
        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
       --FOR i IN l_data.FIRST .. l_data.LAST LOOP
        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).unitprice || '.' );
       --END LOOP;
  v_query2 :=  SQL%ROWCOUNT;
  v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
  COMMIT;

    IF v_query2 > 0 THEN
        nCheckpoint := 100;
        v_query := '';
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','TMP_FREIGHT','TMP_ALL_FREIGHT_ALL',v_time_taken,SYSTIMESTAMP,NULL);--q'{INSERT INTO TMP_EOM_LOGS VALUES (SYSTIMESTAMP ,:startdate,:enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','NONE','TMP_ALL_FREIGHT_ALL',:v_time_taken,SYSTIMESTAMP )  }';
        --EXECUTE IMMEDIATE v_query USING startdate,enddate,v_time_taken;
      DBMS_OUTPUT.PUT_LINE('F_EOM_TMP_ALL_FREIGHT_ALL for the date range '
      || startdate || ' -- ' || enddate || ' - ' || v_query2
      || ' records inserted into table TMP_ALL_FREIGHT_ALL in ' || round((dbms_utility.get_time-l_start)/100, 6)
      || ' Seconds...for all customers, log file has been updated ' );
    Else
      DBMS_OUTPUT.PUT_LINE('F_EOM_TMP_ALL_FREIGHT_ALL rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for all customers ');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('F_EOM_TMP_ALL_FREIGHT_ALL failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;

  END F_EOM_TMP_ALL_FREIGHT_ALL;


  /*   F_EOM_TMP_MAN_FREIGHT_ALL Run this once for each customer   */
  /*   This gets all the IFS freight and Manual Freight data   */
  /*   Temp Tables Used   */
  /*   1. TMP_M_XX_FREIGHT   TO TEST AS MANUAL*/
  PROCEDURE F_EOM_TMP_MAN_XX_FREIGHT (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_M_XX_FREIGHT%ROWTYPE;
    l_data ARRAY;
    v_time_taken VARCHAR2(205);
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

   -- if start_date IS NOT NULL then

    CURSOR c
    --(
      --start_date IN ST.ST_DESP_DATE%TYPE
    -- ,end_date IN ST.ST_DESP_DATE%TYPE
    --sCust IN RM.RM_CUST%TYPE
     --)

     IS




/* F_EOM_TMP_MAN_XX_FREIGHT freight fees*/
		 select    s.SH_CUST                AS "Customer",
			  r.sGroupCust              AS "Parent",
			  s.SH_SPARE_STR_4         AS "CostCentre",
			  s.SH_ORDER               AS "Order",
			  s.SH_SPARE_STR_5         AS "OrderwareNum",
			  s.SH_CUST_REF            AS "CustomerRef",
			  NULL                AS "PickNum",
			  NULL               AS "DespNote",
			  substr(To_Char(d.SD_ADD_DATE),0,10)            AS "DespatchDate",
        substr(To_Char(s.SH_ADD_DATE),0,10) AS "OrderDate",
	      CASE  WHEN d.SD_XX_FREIGHT_CHG >= 0.1  THEN 'XX Manual Freight Fee'
			          ELSE 'UnPricedXXFreight'
			          END                      AS "FeeType",
			  d.SD_STOCK               AS "Item",
			  REPLACE(d.SD_DESC,',','|')              AS "Description",
	      --'="' || To_Char(d.SD_DESC) || '"'               AS "Description",
	      CASE  WHEN d.SD_LINE IS NOT NULL THEN  1
			        ELSE NULL
			        END                     AS "Qty",
	      CASE  WHEN d.SD_LINE IS NOT NULL THEN  '1'
			        ELSE NULL
			        END                      AS "UOI",




        f_calc_freight_fee(d.SD_XX_FREIGHT_CHG,TRIM(d.SD_NOTE_1),sCustomerCode,d.SD_ORDER) AS "UnitPriceMarkedUp",
        CASE  WHEN d.SD_SELL_PRICE >= 1 THEN f_calc_freight_fee(d.SD_XX_FREIGHT_CHG,TRIM(d.SD_NOTE_1),sCustomerCode,d.SD_ORDER)
			  ELSE d.SD_XX_FREIGHT_CHG
        END AS "OWUnitPrice",
        CASE  WHEN d.SD_XX_FREIGHT_CHG >= 1 THEN f_calc_freight_fee(d.SD_XX_FREIGHT_CHG,TRIM(d.SD_NOTE_1),sCustomerCode,d.SD_ORDER)
			  ELSE d.SD_EXCL
        END AS "DExcl",
			  CASE  WHEN d.SD_XX_FREIGHT_CHG >= 1 THEN f_calc_freight_fee(d.SD_XX_FREIGHT_CHG,TRIM(d.SD_NOTE_1),sCustomerCode,d.SD_ORDER) * 1.1
			  ELSE d.SD_INCL
        END AS "DIncl",
        d.SD_XX_FREIGHT_CHG                   AS "ReportingPrice",
         CASE  WHEN regexp_substr(SD_NOTE_1,'\d') IS NOT NULL THEN TO_NUMBER(SD_NOTE_1) --TO_NUMBER(d.SD_NOTE_1,'fm999999.99999999','nls_numeric_characters = ''.,''')
			  ELSE TO_NUMBER('999')
        END AS "ReportingPrice",
			  d.SD_COST_PRICE           AS "COSTPRICE",
			  REPLACE(s.SH_ADDRESS, ',')             AS "Address",
			  REPLACE(s.SH_SUBURB, ',')              AS "Address2",
			  REPLACE(s.SH_CITY, ',')                AS "Suburb",
			  s.SH_STATE               AS "State",
			  s.SH_POST_CODE           AS "Postcode",
			  REPLACE(s.SH_NOTE_1, ',')              AS "DeliverTo",
			  REPLACE(s.SH_NOTE_2, ',')              AS "AttentionTo" ,
			  NULL              AS "Weight",
			  NULL            AS "Packages",
			  s.SH_SPARE_DBL_9         AS "OrderSource",
			  NULL AS "Pallet/Shelf Space", /*Pallet/Space*/
				NULL AS "Locn", /*Locn*/
				--0 AS "AvailSOH",/*Avail SOH*/
				0, --to_number(d.SD_SELL_PRICE) AS "CountOfStocks",
        CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			        ELSE ''
			        END AS Email,
              'N/A' AS Brand,
            d.SD_ADD_DATE,d.SD_ADD_OP,
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
        d.SD_NOTE_1,d.SD_COST_PRICE,
        d.SD_XX_FREIGHT_CHG
	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  --INNER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_PICK))  = LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM))
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
        --INNER JOIN PWIN175.SD d2 ON d.SD_ORDER  = d2.SD_ORDER
	WHERE     --s.SH_ORDER = d.SD_ORDER
	--AND       r.RM_ANAL = :sAnalysis
	--AND
  (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
	AND
  d.SD_STOCK = 'COURIER'--IN ('COURIERM','COURIERS','COURIER','DETENTIONTIMEM','DETENTIONTIMES','FREIGHTDUTY')
	--and (d.SD_DESC != d2.SD_DESC AND d.SD_LINE != d2.SD_LINE)

  --AND       s.SH_ORDER = t.ST_ORDER
	--AND       d.SD_XX_FREIGHT_CHG >= 0.1
	--AND       t.ST_PSLIP != 'CANCELLED'
  AND       d.SD_ADD_DATE >= startdate AND d.SD_ADD_DATE <= enddate
  AND   d.SD_ADD_OP NOT LIKE 'SERV%'
  AND   d.SD_ADD_OP != 'RV' -- AND
  --d.SD_ORDER >= '   1740626' AND  d.SD_ORDER <= '   1740626'
	GROUP BY  s.SH_CUST,
			  s.SH_SPARE_STR_4,s.SH_CAMPAIGN,
			  s.SH_ORDER,
			  --t.ST_PICK,
			  d.SD_XX_PICKLIST_NUM,
			  --t.ST_PSLIP,
			  --t.ST_DESP_DATE,
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
			  s.SH_CITY,d.SD_ADD_OP,
			  s.SH_STATE,
			  s.SH_POST_CODE,
			  s.SH_NOTE_1,s.SH_ADD_DATE,
			  s.SH_NOTE_2,d.SD_ORDER,d.SD_XX_FREIGHT_CHG,
			 -- t.ST_WEIGHT,
			  --t.ST_PACKAGES,
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
        d.SD_NOTE_1,d.SD_COST_PRICE,
        d.SD_XX_FREIGHT_CHG,
			  s.SH_SPARE_DBL_9,
			  r.sGroupCust,
			  s.SH_SPARE_STR_5,
			  s.SH_CUST_REF,
        s.SH_SPARE_STR_3,
        s.SH_SPARE_STR_1,
       -- t.ST_SPARE_DBL_1,
        d.SD_XX_PSLIP_NUM,
          d.SD_ADD_DATE,
          d.SD_XX_PICKLIST_NUM,
          d.SD_COST_PRICE,s.SH_CAMPAIGN;


--USING ;
    nbreakpoint   NUMBER;
    l_start number default dbms_utility.get_time;
    BEGIN

    nCheckpoint := 1;
      v_query := 'TRUNCATE TABLE TMP_M_XX_FREIGHT';
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
        --DBMS_OUTPUT.PUT_LINE(l_data(10) || '.' );
        INSERT INTO TMP_M_XX_FREIGHT VALUES l_data(i);
        --USING sCust;

        EXIT WHEN c%NOTFOUND;

        END LOOP;
        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
       --FOR i IN l_data.FIRST .. l_data.LAST LOOP
        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
      --END LOOP;
  v_query2 :=  SQL%ROWCOUNT;
  COMMIT;

    IF v_query2 > 0 THEN
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'F_EOM_TMP_MAN_XX_FREIGHT','SD','TMP_M_XX_FREIGHT',v_time_taken,SYSTIMESTAMP,sCustomerCode);
      DBMS_OUTPUT.PUT_LINE('F_EOM_TMP_MAN_XX_FREIGHT for the date range '
      || startdate || ' -- ' || enddate || ' - ' || v_query2
      || ' records inserted into table TMP_M_XX_FREIGHT in ' || round((dbms_utility.get_time-l_start)/100, 6)
      || ' Seconds...for customer ' || sCustomerCode );
    Else
      DBMS_OUTPUT.PUT_LINE('F_EOM_TMP_MAN_XX_FREIGHT rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('F_EOM_TMP_MAN_XX_FREIGHT failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;

  END F_EOM_TMP_MAN_XX_FREIGHT;

  /*   F_EOM_TMP_MAN_FREIGHT_ALL Run this once for each customer   */
  /*   This gets all the IFS freight and Manual Freight data   */
  /*   Temp Tables Used   */
  /*   1. TMP_V_FREIGHT   TO TEST AS MANUAL*/
  PROCEDURE F_EOM_TMP_VAN_FREIGHT_ALL (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_V_FREIGHT%ROWTYPE;
    l_data ARRAY;
    v_time_taken VARCHAR2(205);
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

   -- if start_date IS NOT NULL then

    CURSOR c
    --(
      --start_date IN ST.ST_DESP_DATE%TYPE
    -- ,end_date IN ST.ST_DESP_DATE%TYPE
    --sCust IN RM.RM_CUST%TYPE
     --)

     IS




/* Van Manual freight fees*/
		 select    s.SH_CUST                AS "Customer",
			  r.sGroupCust              AS "Parent",
			  s.SH_SPARE_STR_4         AS "CostCentre",
			  s.SH_ORDER               AS "Order",
			  s.SH_SPARE_STR_5         AS "OrderwareNum",
			  s.SH_CUST_REF            AS "CustomerRef",
			  d.SD_XX_PICKLIST_NUM                AS "PickNum",
			  d.SD_XX_PSLIP_NUM               AS "DespNote",
			  d.SD_ADD_DATE            AS "DespatchDate",
        substr(To_Char(s.SH_ADD_DATE),0,10) AS "OrderDate",
	      CASE  WHEN d.SD_STOCK = 'COURIER' AND d.SD_SELL_PRICE >= 0.1  THEN 'Van Freight Fee'
			          ELSE 'UnPricedVanFreight'
			          END                      AS "FeeType",
			  d.SD_STOCK               AS "Item",
			  REPLACE(d.SD_DESC,',','|')              AS "Description",
	      --'="' || To_Char(d.SD_DESC) || '"'               AS "Description",
	      CASE  WHEN d.SD_LINE IS NOT NULL THEN  1
			        ELSE NULL
			        END                     AS "Qty",
	      CASE  WHEN d.SD_LINE IS NOT NULL THEN  '1'
			        ELSE NULL
			        END                      AS "UOI",

        f_calc_freight_fee(d.SD_SELL_PRICE,TRIM(d.SD_NOTE_1),sCustomerCode,d.SD_ORDER) AS "UnitPriceMarkedUp",
        CASE  WHEN d.SD_SELL_PRICE >= 1 THEN f_calc_freight_fee(d.SD_SELL_PRICE,TRIM(d.SD_NOTE_1),sCustomerCode,d.SD_ORDER)
			  ELSE d.SD_SELL_PRICE
        END AS "OWUnitPrice",
        CASE  WHEN d.SD_SELL_PRICE >= 1 THEN f_calc_freight_fee(d.SD_SELL_PRICE,TRIM(d.SD_NOTE_1),sCustomerCode,d.SD_ORDER)
			  ELSE d.SD_EXCL
        END AS "DExcl",
			  CASE  WHEN d.SD_SELL_PRICE >= 1 THEN f_calc_freight_fee(d.SD_SELL_PRICE,TRIM(d.SD_NOTE_1),sCustomerCode,d.SD_ORDER) * 1.1
			  ELSE d.SD_INCL
        END AS "DIncl",
        d.SD_XX_FREIGHT_CHG                   AS "ReportingPrice",
         CASE  WHEN regexp_substr(SD_NOTE_1,'\d') IS NOT NULL THEN TO_NUMBER(SD_NOTE_1) --TO_NUMBER(d.SD_NOTE_1,'fm999999.99999999','nls_numeric_characters = ''.,''')
			  ELSE TO_NUMBER('999')
        END AS "ReportingPrice",
			  d.SD_COST_PRICE           AS "COSTPRICE",
			  REPLACE(s.SH_ADDRESS, ',')             AS "Address",
			  REPLACE(s.SH_SUBURB, ',')              AS "Address2",
			  REPLACE(s.SH_CITY, ',')                AS "Suburb",
			  s.SH_STATE               AS "State",
			  s.SH_POST_CODE           AS "Postcode",
			  REPLACE(s.SH_NOTE_1, ',')              AS "DeliverTo",
			  REPLACE(s.SH_NOTE_2, ',')              AS "AttentionTo" ,
			  NULL              AS "Weight",
			  NULL            AS "Packages",
			  s.SH_SPARE_DBL_9         AS "OrderSource",
			  NULL AS "Pallet/Shelf Space", /*Pallet/Space*/
				NULL AS "Locn", /*Locn*/
				--0 AS "AvailSOH",/*Avail SOH*/
				0, --to_number(d.SD_SELL_PRICE) AS "CountOfStocks",
        CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			        ELSE ''
			        END AS Email,
              'N/A' AS Brand,
          d.SD_ADD_DATE,d.SD_ADD_OP,
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
        d.SD_NOTE_1,d.SD_COST_PRICE,
        d.SD_XX_FREIGHT_CHG
	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  --INNER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_PICK))  = LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM))
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
        --INNER JOIN PWIN175.SD d2 ON d.SD_ORDER  = d2.SD_ORDER
	WHERE     --s.SH_ORDER = d.SD_ORDER
	--AND       r.RM_ANAL = :sAnalysis
	--AND
  (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
	AND
  d.SD_STOCK = 'COURIER'
	--and UPPER(d.SD_DESC)  = 'Courier , Ref van' or LOWER(d.SD_DESC)  = 'Courier , Ref van'
  AND LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM)) IS NULL

  --AND       s.SH_ORDER = t.ST_ORDER
	--AND       d.SD_SELL_PRICE >= 0.1
	--AND       t.ST_PSLIP != 'CANCELLED'
  AND       d.SD_ADD_DATE >= startdate AND d.SD_ADD_DATE <= enddate
  AND   d.SD_ADD_OP NOT LIKE 'SERV%'
  AND   d.SD_ADD_OP != 'RV'
 -- AND
  --d.SD_ORDER >= '   1740626' AND  d.SD_ORDER <= '   1740626'

	GROUP BY  s.SH_CUST,
			  s.SH_SPARE_STR_4,
			  s.SH_ORDER,
			  --t.ST_PICK,
			  d.SD_XX_PICKLIST_NUM,
			  --t.ST_PSLIP,
			  --t.ST_DESP_DATE,
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
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
        d.SD_NOTE_1,d.SD_COST_PRICE,
        d.SD_XX_FREIGHT_CHG,
			  s.SH_ADDRESS,
			  s.SH_SUBURB,
			  s.SH_CITY,
			  s.SH_STATE,
			  s.SH_POST_CODE,
			  s.SH_NOTE_1,
			  s.SH_NOTE_2,d.SD_ORDER,d.SD_XX_FREIGHT_CHG,
			  --t.ST_WEIGHT,
			 -- t.ST_PACKAGES,
			  s.SH_SPARE_DBL_9,s.SH_CAMPAIGN,
			  r.sGroupCust,
			  s.SH_SPARE_STR_5,
			  s.SH_CUST_REF,
        s.SH_SPARE_STR_3,d.SD_ADD_OP,
        s.SH_SPARE_STR_1,s.SH_ADD_DATE,
       -- t.ST_SPARE_DBL_1,
        d.SD_XX_PSLIP_NUM,
          d.SD_ADD_DATE,
          d.SD_XX_PICKLIST_NUM,
          d.SD_COST_PRICE,s.SH_CAMPAIGN;


--USING ;
    nbreakpoint   NUMBER;
    l_start number default dbms_utility.get_time;
    BEGIN

    nCheckpoint := 1;
      v_query := 'TRUNCATE TABLE TMP_V_FREIGHT';
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
        --DBMS_OUTPUT.PUT_LINE(l_data(10) || '.' );
        INSERT INTO TMP_V_FREIGHT VALUES l_data(i);
        --USING sCust;

        EXIT WHEN c%NOTFOUND;

        END LOOP;
        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
       --FOR i IN l_data.FIRST .. l_data.LAST LOOP
        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
      --END LOOP;
  v_query2 :=  SQL%ROWCOUNT;
  COMMIT;

    IF v_query2 > 0 THEN
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'F_EOM_TMP_VAN_FREIGHT_ALL','SD','TMP_V_FREIGHT',v_time_taken,SYSTIMESTAMP,sCustomerCode);
      DBMS_OUTPUT.PUT_LINE('F_EOM_TMP_VAN_FREIGHT_ALL for the date range '
      || startdate || ' -- ' || enddate || ' - ' || v_query2
      || ' records inserted into table TMP_V_FREIGHT in ' || round((dbms_utility.get_time-l_start)/100, 6)
      || ' Seconds...for customer ' || sCustomerCode );
    Else
      DBMS_OUTPUT.PUT_LINE('F_EOM_TMP_VAN_FREIGHT_ALL rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('F_EOM_TMP_VAN_FREIGHT_ALL failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;

  END F_EOM_TMP_VAN_FREIGHT_ALL;


  /*   F_ALL_FREIGHT This gets all the IFS freight and Manual Freight data   */
  /*   Temp Tables Used 1. TMP_FREIGHT   */
  /****************************************/
  /*   Working as of 24th July 15  */
  /*   This runs a combined query  */
  /*   to get manual freight and IFS freight    */
  /*   at the same time, takes ave 4 seconds for 1 client  */
  PROCEDURE F_ALL_FREIGHT (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_FREIGHT%ROWTYPE;
    l_data ARRAY;
    v_time_taken VARCHAR2(205);
    v_out_tx          VARCHAR2(2000);
    SQLQuery         VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          NUMBER;
		nCheckpoint       NUMBER;
		sCourierm         VARCHAR2(20) := 'COURIERM';
    sCouriers         VARCHAR2(20) := 'COURIERS';
    sCourier         VARCHAR2(20) := 'COURIER%';
    sServ8             VARCHAR2(20) := 'SERV8';
    sServ3             VARCHAR2(20) := 'SERV%';
    --sCust2    VARCHAR2(20) := sCust;
    --end_date2 ST.ST_DESP_DATE%TYPE := end_date;
    --DBMS_OUTPUT.PUT_LINE(start_date || ' - ' || end_date || '.' || sCust );
    sFileName VARCHAR2(560);
   -- if start_date IS NOT NULL then

    CURSOR c
    --(
      --start_date IN ST.ST_DESP_DATE%TYPE
    -- ,end_date IN ST.ST_DESP_DATE%TYPE
    --sCust IN RM.RM_CUST%TYPE
     --)

     IS

/*All freight fees*/
		 select  DISTINCT s.SH_CUST                AS "Customer",
			  r.sGroupCust              AS "Parent",
			  s.SH_SPARE_STR_4         AS "CostCentre",
			  s.SH_ORDER               AS "Order",
			  s.SH_SPARE_STR_5         AS "OrderwareNum",
			  s.SH_CUST_REF            AS "CustomerRef",
			  t.ST_PICK                AS "PickNum",
			  t.ST_PSLIP               AS "DespNote",
			  substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
        substr(To_Char(s.SH_ADD_DATE),0,10) AS "OrderDate",
	      CASE  WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 0.1  AND t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate  AND   d.SD_ADD_OP LIKE 'SERV%' THEN 'Freight Fee'
              WHEN d.SD_STOCK IN ('COURIERM','COURIERS','COURIER','DETENTIONTIMEM','DETENTIONTIMES','FREIGHTDUTY') AND d.SD_SELL_PRICE >= 0.1  AND d.SD_ADD_DATE >= startdate AND d.SD_ADD_DATE <= enddate  AND   d.SD_ADD_OP NOT LIKE 'SERV%' THEN 'Manual Freight Fee'
              ELSE NULL
			        END                      AS "FeeType",
			  d.SD_STOCK               AS "Item",
			 -- '="' || To_Char(d.SD_DESC) || '"'               AS "Description",
	      REPLACE(d.SD_DESC,',','|')              AS "Description",
        CASE  WHEN d.SD_LINE IS NOT NULL THEN  1
			        ELSE NULL
			        END                     AS "Qty",
	      CASE  WHEN d.SD_LINE IS NOT NULL THEN  '1'
			        ELSE NULL
			        END                      AS "UOI",

        CASE  WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.sGroupCust <> 'BORBUI' AND r.sGroupCust <> 'BEYONDBLUE') THEN d.SD_SELL_PRICE
			        WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.sGroupCust = 'BORBUI' OR r.sGroupCust = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.125) And (t.ST_SPARE_DBL_1 > 0.00) THEN 1.70
              WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.sGroupCust = 'BORBUI' OR r.sGroupCust = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.250) And (t.ST_SPARE_DBL_1 > 0.126) THEN 2.30
              WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.sGroupCust = 'BORBUI' OR r.sGroupCust = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.500) And (t.ST_SPARE_DBL_1 > 0.251) THEN 3.40
              WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.sGroupCust = 'BORBUI' OR r.sGroupCust = 'BEYONDBLUE') AND (t.ST_WEIGHT > 0.01) THEN d.SD_SELL_PRICE
              ELSE d.SD_SELL_PRICE
			        END                      AS "UnitPrice",
			  d.SD_XX_OW_UNIT_PRICE    AS "OWUnitPrice",
			  d.SD_EXCL                AS "DExcl",
			  Sum(d.SD_EXCL)           AS "Excl_Total",
			  d.SD_INCL                AS "DIncl",
			  Sum(d.SD_INCL)           AS "Incl_Total",
			  NULL                     AS "ReportingPrice",
			  REPLACE(s.SH_ADDRESS, ',')             AS "Address",
			  REPLACE(s.SH_SUBURB, ',')              AS "Address2",
			  REPLACE(s.SH_CITY, ',')                AS "Suburb",
			  s.SH_STATE               AS "State",
			  s.SH_POST_CODE           AS "Postcode",
			  REPLACE(s.SH_NOTE_1, ',')              AS "DeliverTo",
			  REPLACE(s.SH_NOTE_2, ',')              AS "AttentionTo" ,
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
              'N/A' AS Brand,
            'N/A','N/A',
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
        d.SD_NOTE_1,d.SD_COST_PRICE,
        d.SD_XX_FREIGHT_CHG
	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_PICK))  = LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM))
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
	WHERE  (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
	AND      ( (d.SD_STOCK IN ('COURIERM','COURIERS','COURIER')  AND       t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate) OR
            (d.SD_STOCK IN ('COURIERM','COURIERS','COURIER','DETENTIONTIMEM','DETENTIONTIMES','FREIGHTDUTY') AND d.SD_ADD_DATE >= startdate AND d.SD_ADD_DATE <= enddate))
	AND       s.SH_ORDER = t.ST_ORDER
	AND       d.SD_SELL_PRICE >= 0.1
	AND       t.ST_PSLIP != 'CANCELLED'
 -- AND   d.SD_ADD_OP LIKE 'SERV%'
  --AND s.SH_ORDER LIKE '   1377018'

	GROUP BY  s.SH_CUST,
			  s.SH_SPARE_STR_4,
			  s.SH_ORDER,
			  t.ST_PICK,
			  d.SD_XX_PICKLIST_NUM,
			  t.ST_PSLIP,
			  t.ST_DESP_DATE,
			  d.SD_STOCK,
			  d.SD_DESC,
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
        d.SD_NOTE_1,d.SD_COST_PRICE,
        d.SD_XX_FREIGHT_CHG,
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
			  s.SH_SPARE_STR_5,s.SH_ADD_DATE,
			  s.SH_CUST_REF,
        s.SH_SPARE_STR_3,
        s.SH_SPARE_STR_1,
        t.ST_SPARE_DBL_1,
        d.SD_XX_PSLIP_NUM,
          d.SD_ADD_DATE,
          d.SD_XX_PICKLIST_NUM,SD_ADD_OP,
          d.SD_COST_PRICE,s.SH_CAMPAIGN;


--USING ;
    nbreakpoint   NUMBER;
    l_start number default dbms_utility.get_time;
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
        --DBMS_OUTPUT.PUT_LINE(l_data(10) || '.' );
        INSERT INTO TMP_FREIGHT VALUES l_data(i);
        --USING sCust;

        EXIT WHEN c%NOTFOUND;

        END LOOP;
        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
       --FOR i IN l_data.FIRST .. l_data.LAST LOOP
        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
      --END LOOP;
  v_query2 :=  SQL%ROWCOUNT;
  COMMIT;

    IF v_query2 > 0 THEN
     -- If F_IS_TABLE_EEMPTY('TMP_FREIGHT') > 0 Then
        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
        EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'F_ALL_FREIGHT','SD','TMP_FREIGHT',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        sFileName := sCustomerCode || '-F_ALL_FREIGHT-ORACLE-' || startdate || '-TO-' || enddate || '.csv';
        Z2_TMP_FEES_TO_CSV(sFileName,'TMP_FREIGHT');
        DBMS_OUTPUT.PUT_LINE('Z2_TMP_FEES_TO_CSV for ' || sFileName || '.' );
      --End If;
      DBMS_OUTPUT.PUT_LINE('F_ALL_FREIGHT for the date range '
      || startdate || ' -- ' || enddate || ' - ' || v_query2
      || ' records inserted into table TMP_FREIGHT in ' || round((dbms_utility.get_time-l_start)/100, 6)
      || ' Seconds...for customer ' || sCustomerCode );
    Else
      DBMS_OUTPUT.PUT_LINE('F_ALL_FREIGHT rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('F_ALL_FREIGHT failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;

  END F_ALL_FREIGHT;

  /*   F_Z_EOM_RUN_ALL_FREIGHT Run this once for each customer including intercompany   */
  /*   This just runs all the above procedures from a single source   */
  /*   No Specific Temp Tables Used   */
  PROCEDURE F_Z_EOM_RUN_ALL_FREIGHT (
      p_array_size_start IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
      , sAnalysis_Start IN RM.RM_ANAL%TYPE
  )
  AS
    nCheckpoint  NUMBER;
    v_time_taken VARCHAR2(205);
    l_start number default dbms_utility.get_time;
    v_query2 VARCHAR2(32767);
    sFileName VARCHAR2(560);
    sFileTime VARCHAR2(56)  := TO_CHAR(SYSDATE,'YYYYMMDD HH24MISS');
  BEGIN

    /*nCheckpoint := 1;
    	EOM_REPORT_PKG_TEST.A_EOM_GROUP_CUST();

    nCheckpoint := 2;
     EOM_REPORT_PKG_TEST.B_EOM_START_RUN_ONCE_DATA(start_date_start,end_date_start,sAnalysis_Start,sCust_start);
  */
    nCheckpoint := 3;
    --set timing on;
     --EOM_REPORT_PKG_TEST.C_EOM_START_CUST_TEMP_DATA(sAnalysis_Start,sCust_start);

    --nCheckpoint := 4;
    --EXECUTE IMMEDIATE EOM_REPORT_PKG_TEST.D_EOM_GET_CUST_RATES(p_array_size_start,start_date_start,end_date_start,sCust_start);
    If ( sAnalysis_Start IS NULL ) Then
      nCheckpoint := 5;
      EOM_REPORT_PKG_TEST.F_ALL_FREIGHT(p_array_size_start,startdate,enddate,sCustomerCode);


     ElsIf (sAnalysis_Start IS NOT NULL) AND (sCustomerCode IS NOT NULL) Then
      nCheckpoint := 5;
      --EOM_REPORT_PKG_TEST.F_EOM_TMP_ALL_FREIGHT_ALL_IC(p_array_size_start,startdate,enddate,sCustomerCode,sAnalysis_Start);



     End If;
     --nCheckpoint := 13;
     --EOM_REPORT_PKG_TEST.EOM_TMP_MERGE_ALL_FEES();
    v_query2 :=  SQL%ROWCOUNT;

    --IF v_query2 > 0 THEN
     If F_IS_TABLE_EEMPTY('TMP_FREIGHT') > 0 Then
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'F_Z_EOM_RUN_ALL_FREIGHT','SD','TMP_FREIGHT',v_time_taken,SYSTIMESTAMP,sCustomerCode);
      sFileName := sCustomerCode || '-H1_EOM_FREIGHT_FEES-ORACLE-' || startdate || '-TO-' || enddate || '-RunOn-' || sFileTime || '.csv';
      Z2_TMP_FEES_TO_CSV(sFileName,'TMP_FREIGHT');
      --DBMS_OUTPUT.PUT_LINE('Z2_TMP_FEES_TO_CSV for ' || sFileName || '.' );
      DBMS_OUTPUT.PUT_LINE('F_Z_EOM_RUN_ALL_FREIGHT for the date range '
      || startdate || ' -- ' || enddate || ' - ' || v_query2
      || ' records inserted into table TMP_FREIGHT in ' || round((dbms_utility.get_time-l_start)/100, 6)
      || ' Seconds...for customer ' || sCustomerCode );
    Else
      DBMS_OUTPUT.PUT_LINE('F_Z_EOM_RUN_ALL_FREIGHT rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
    RETURN;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('F_Z_EOM_RUN_ALL_FREIGHT failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END F_Z_EOM_RUN_ALL_FREIGHT;

  /*   F_Z_EOM_RUN_ALL_FREIGHT Run this once for each customer including intercompany   */
  /*   This just runs all the above procedures from a single source   */
  /*   No Specific Temp Tables Used   */
  PROCEDURE F_Z_EOM_RUN_BOTH_FREIGHT (
      p_array_size_start IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
      , sAnalysis_Start IN RM.RM_ANAL%TYPE
  )
  AS
    nCheckpoint  NUMBER;
    v_time_taken VARCHAR2(205);
    l_start number default dbms_utility.get_time;
    v_query2 VARCHAR2(32767);
    sFileName VARCHAR2(560);
    sFileTime VARCHAR2(56)  := TO_CHAR(SYSDATE,'YYYYMMDD HH24MISS');
  BEGIN

    /*nCheckpoint := 1;
    	EOM_REPORT_PKG_TEST.A_EOM_GROUP_CUST();

    nCheckpoint := 2;
     EOM_REPORT_PKG_TEST.B_EOM_START_RUN_ONCE_DATA(start_date_start,end_date_start,sAnalysis_Start,sCust_start);
  */
    nCheckpoint := 3;
    --set timing on;
     --EOM_REPORT_PKG_TEST.C_EOM_START_CUST_TEMP_DATA(sAnalysis_Start,sCust_start);

    --nCheckpoint := 4;
    --EXECUTE IMMEDIATE EOM_REPORT_PKG_TEST.D_EOM_GET_CUST_RATES(p_array_size_start,start_date_start,end_date_start,sCust_start);
    If ( sAnalysis_Start IS NULL ) Then
      nCheckpoint := 5;
      EOM_REPORT_PKG_TEST.F_EOM_TMP_MAN_FREIGHT_ALL(p_array_size_start,startdate,enddate,sCustomerCode);
      EOM_REPORT_PKG_TEST.F_EOM_TMP_AUTO_FREIGHT_ALL(p_array_size_start,startdate,enddate,sCustomerCode);
      EOM_REPORT_PKG_TEST.F_EOM_TMP_VAN_FREIGHT_ALL(p_array_size_start,startdate,enddate,sCustomerCode);
      EOM_REPORT_PKG_TEST.F_EOM_TMP_MAN_XX_FREIGHT(p_array_size_start,startdate,enddate,sCustomerCode);
      EOM_REPORT_PKG_TEST.Y_EOM_MERGE_ALL_FREIGHT(p_array_size_start);

     ElsIf (sAnalysis_Start IS NOT NULL) AND (sCustomerCode IS NOT NULL) Then
      nCheckpoint := 5;
      --EOM_REPORT_PKG_TEST.F_EOM_TMP_ALL_FREIGHT_ALL_IC(p_array_size_start,startdate,enddate,sCustomerCode,sAnalysis_Start);



     End If;
     --nCheckpoint := 13;
     --EOM_REPORT_PKG_TEST.EOM_TMP_MERGE_ALL_FEES();
    v_query2 :=  SQL%ROWCOUNT;

    --IF v_query2 > 0 THEN
     If F_IS_TABLE_EEMPTY('TMP_FREIGHT') > 0 Then
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'F_Z_EOM_RUN_ALL_FREIGHT','SD','TMP_ALL_FREIGHT',v_time_taken,SYSTIMESTAMP,sCustomerCode);
      sFileName := sCustomerCode || '-H1_BOTH_FREIGHT_FEES-ORACLE-' || startdate || '-TO-' || enddate || '-RunOn-' || sFileTime || '.csv';
      Z2_TMP_FEES_TO_CSV(sFileName,'TMP_ALL_FREIGHT_F');
      --DBMS_OUTPUT.PUT_LINE('Z2_TMP_FEES_TO_CSV for ' || sFileName || '.' );
      DBMS_OUTPUT.PUT_LINE('F_Z_EOM_RUN_ALL_FREIGHT for the date range '
      || startdate || ' -- ' || enddate || ' - ' || v_query2
      || ' records inserted into table TMP_ALL_FREIGHT in ' || round((dbms_utility.get_time-l_start)/100, 6)
      || ' Seconds...for customer ' || sCustomerCode );
    Else
      DBMS_OUTPUT.PUT_LINE('F_Z_EOM_RUN_ALL_FREIGHT rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
    RETURN;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('F_Z_EOM_RUN_ALL_FREIGHT failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END F_Z_EOM_RUN_BOTH_FREIGHT;

  /*   F_Z_EOM_RUN_ALL_FREIGHT Run this once for each customer including intercompany   */
  /*   This just runs all the above procedures from a single source   */
  /*   No Specific Temp Tables Used   */
  PROCEDURE F8_Z_EOM_RUN_FREIGHT (
        p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_ALL_FREIGHT_F%ROWTYPE;
    l_data ARRAY;
    v_time_taken VARCHAR2(205);
    v_out_tx          VARCHAR2(2000);
    SQLQuery         VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          NUMBER;
		nCheckpoint       NUMBER;
		sCourierm         VARCHAR2(20) := 'COURIERM';
    sCouriers         VARCHAR2(20) := 'COURIERS';
    sCourier         VARCHAR2(20) := 'COURIER%';
    sServ8             VARCHAR2(20) := 'SERV8';
    sServ3             VARCHAR2(20) := 'SERV%';
    --sCust2    VARCHAR2(20) := sCust;
    --end_date2 ST.ST_DESP_DATE%TYPE := end_date;
    --DBMS_OUTPUT.PUT_LINE(start_date || ' - ' || end_date || '.' || sCust );
    sFileName VARCHAR2(560);
    sFileTime VARCHAR2(56)  := TO_CHAR(SYSDATE,'YYYYMMDD HH24MISS');
   -- if start_date IS NOT NULL then

    CURSOR c
    --(
      --start_date IN ST.ST_DESP_DATE%TYPE
    -- ,end_date IN ST.ST_DESP_DATE%TYPE
    --sCust IN RM.RM_CUST%TYPE
     --)

     IS

/*All freight fees*/
		 select  *
	FROM  TMP_ALL_FREIGHT_ALL t
	WHERE  t.Customer = sCustomerCode OR t.parent = sCustomerCode;



--USING ;
    nbreakpoint   NUMBER;
    l_start number default dbms_utility.get_time;
    BEGIN

    nCheckpoint := 1;
      v_query := 'TRUNCATE TABLE TMP_ALL_FREIGHT_F';
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
        --DBMS_OUTPUT.PUT_LINE(l_data(10) || '.' );
        INSERT INTO TMP_ALL_FREIGHT_F VALUES l_data(i);
        --USING sCust;

        EXIT WHEN c%NOTFOUND;

        END LOOP;
        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
       --FOR i IN l_data.FIRST .. l_data.LAST LOOP
        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
      --END LOOP;
  v_query2 :=  SQL%ROWCOUNT;
  COMMIT;

    IF v_query2 > 0 THEN
     -- If F_IS_TABLE_EEMPTY('TMP_FREIGHT') > 0 Then
        --sFileName := sCustomerCode || '-F8_Z_EOM_RUN_FREIGHT' || startdate || '-TO-' || enddate || '.csv';
        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
        EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'F8_Z_EOM_RUN_FREIGHT','TMP_ALL_FREIGHT_ALL','TMP_ALL_FREIGHT_F',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        sFileName := sCustomerCode || '-F8_Z_EOM_RUN_FREIGHT-' || startdate || '-TO-' || enddate || '-RunOn-' || sFileTime || '.csv';

        Z2_TMP_FEES_TO_CSV(sFileName,'TMP_ALL_FREIGHT_F');
        DBMS_OUTPUT.PUT_LINE('Z2_TMP_FEES_TO_CSV for ' || sFileName || '.' );
      --End If;
      DBMS_OUTPUT.PUT_LINE('F8_Z_EOM_RUN_FREIGHT for the date range '
      || startdate || ' -- ' || enddate || ' - ' || v_query2
      || ' records inserted into table TMP_ALL_FREIGHT_F in ' || round((dbms_utility.get_time-l_start)/100, 6)
      || ' Seconds...for customer ' || sCustomerCode );
    Else
      DBMS_OUTPUT.PUT_LINE('F8_Z_EOM_RUN_FREIGHT rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('F8_Z_EOM_RUN_FREIGHT failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;
  END F8_Z_EOM_RUN_FREIGHT;

  /*   G1_SHRINKWRAP_FEES Run this once for each customer   */
  /*   This gets all the Handeling Related Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_SHRINKWRAP_FEES  ShrinkWrap Fee */
  /*   Prism Rate Field Used   */
  /*   A. RM_XX_FEE18   */
  PROCEDURE G1_SHRINKWRAP_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
      ,sAnalysis IN RM.RM_ANAL%TYPE

      -- sCust IN RM.RM_CUST%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_SHRINKWRAP_FEES%ROWTYPE;
    l_data ARRAY;
    v_time_taken VARCHAR2(205);
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
    --end_date2 ST.ST_DESP_DATE%TYPE := end_date;
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
			  t.ST_PICK                AS "PickNum",
			  t.ST_PSLIP               AS "DespNote",
			  substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
        substr(To_Char(s.SH_ADD_DATE),0,10) AS "OrderDate",
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
        CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)
        ELSE null
        END                      AS "UnitPrice",
        CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)
        ELSE null
        END                                           AS "OWUnitPrice",
        CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1  THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)
        ELSE NULL
        END                        AS "DExcl",
        CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN   (SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)
        ELSE NULL
        END                                            AS "Excl_Total",
        CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)  * 1.1
        ELSE NULL
        END                                           AS "DIncl",
        CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)  * 1.1
        ELSE NULL
        END                                           AS "Incl_Total",
        CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)
        ELSE null
        END                                           AS "ReportingPrice",
			  REPLACE(s.SH_ADDRESS, ',')             AS "Address",
			  REPLACE(s.SH_SUBURB, ',')              AS "Address2",
			  REPLACE(s.SH_CITY, ',')                AS "Suburb",
			  s.SH_STATE               AS "State",
			  s.SH_POST_CODE           AS "Postcode",
			  REPLACE(s.SH_NOTE_1, ',')              AS "DeliverTo",
			  REPLACE(s.SH_NOTE_2, ',')              AS "AttentionTo" ,
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
        i.IM_OWNED_By,i.IM_PROFILE,
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
        d.SD_NOTE_1,d.SD_COST_PRICE,
        d.SD_XX_FREIGHT_CHG
	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
	WHERE  s.SH_STATUS <> 3
  AND (SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0.1
	AND       (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
	AND       s.SH_ORDER = t.ST_ORDER
	AND       (ST_XX_NUM_PAL_SW >= 1)
	AND       d.SD_LINE = 1
--	AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
  AND       t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate

	GROUP BY  s.SH_CUST,
        r.sGroupCust,
        r.sCust,
			  s.SH_NOTE_1,
			  s.SH_CAMPAIGN,
			  s.SH_SPARE_STR_4,
			  s.SH_ORDER,
			  t.ST_PICK,
			  d.SD_XX_PICKLIST_NUM,s.SH_CAMPAIGN,
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
			  d.SD_XX_OW_UNIT_PRICE,s.SH_ADD_DATE,
			  d.SD_QTY_ORDER,
			  d.SD_QTY_ORDER,
			  s.SH_ADDRESS,
			  s.SH_SUBURB,
			  s.SH_CITY, i.IM_OWNED_By,i.IM_PROFILE,
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
        d.SD_NOTE_1,d.SD_COST_PRICE,
        d.SD_XX_FREIGHT_CHG,
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


    QueryTable VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode5}';
    sCust_Rates RM.RM_XX_FEE18%TYPE;/*1 PickFee*/
    l_start number default dbms_utility.get_time;
   BEGIN
        nCheckpoint := 10;
        EXECUTE IMMEDIATE QueryTable INTO sCust_Rates USING sCustomerCode;/*1 PickFee*/

        nCheckpoint := 11;
        v_query := 'TRUNCATE TABLE TMP_SHRINKWRAP_FEES';
        EXECUTE IMMEDIATE v_query;

        IF To_Number(regexp_substr(sCust_Rates,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) != 0 Then
        --DBMS_OUTPUT.PUT_LINE('G1_SHRINKWRAP_FEES rates are $' || sCust_Rates || '. Prism rate field is RM_XX_FEE18');

        nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCustomerCode || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;

        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_SHRINKWRAP_FEES VALUES l_data(i);
        --USING sCust;
        EXIT WHEN c%NOTFOUND;
        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
        -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        --END LOOP;
        v_query2 :=  SQL%ROWCOUNT;
    COMMIT;

     IF v_query2 > 0 THEN
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'G1_SHRINKWRAP_FEES','ST','TMP_SHRINKWRAP_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
      DBMS_OUTPUT.PUT_LINE('G1_SHRINKWRAP_FEES for the date range '
      || startdate || ' -- ' || enddate || ' - ' || v_query2
      || ' records inserted into table TMP_SHRINKWRAP_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
      || ' Seconds...for customer ' || sCustomerCode );
    Else
      DBMS_OUTPUT.PUT_LINE('G1_SHRINKWRAP_FEES rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
  Else
      DBMS_OUTPUT.PUT_LINE('G1_SHRINKWRAP_FEES rates are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
    EXCEPTION
        WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('G1_SHRINKWRAP_FEES failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
    RAISE;
  END G1_SHRINKWRAP_FEES;

  /*   G2_STOCK_FEES Run this once for each customer   */
  /*   This gets all the Handeling Related Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_STOCK_FEES  Stocks */
  PROCEDURE G2_STOCK_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
      ,sAnalysis IN RM.RM_ANAL%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_STOCK_FEES%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_time_taken VARCHAR2(205);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
    nbreakpoint   NUMBER;
     CURSOR c
    IS
    /*Stocks*/
    SELECT
          s.SH_CUST                AS "Customer",
          r.sGroupCust              AS "Parent",
          CASE   WHEN i.IM_CUST <> 'TABCORP' AND s.SH_SPARE_STR_4 IS NULL THEN s.SH_CUST
          WHEN i.IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
          WHEN i.IM_CUST = 'TABCORP' THEN i.IM_XX_COST_CENTRE01
          ELSE i.IM_XX_COST_CENTRE01
          END                      AS "CostCentre",
          s.SH_ORDER               AS "Order",
          s.SH_SPARE_STR_5         AS "OrderwareNum",
          s.SH_CUST_REF            AS "CustomerRef",
          t.ST_PICK                AS "PickNum",
			  t.ST_PSLIP               AS "DespNote",
			  substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
        substr(To_Char(s.SH_ADD_DATE),0,10) AS "OrderDate",
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
          REPLACE(s.SH_ADDRESS, ',')             AS "Address",
          REPLACE(s.SH_SUBURB, ',')              AS "Address2",
          REPLACE(s.SH_CITY, ',')                AS "Suburb",
          s.SH_STATE               AS "State",
          s.SH_POST_CODE           AS "Postcode",
          REPLACE(s.SH_NOTE_1, ',')              AS "DeliverTo",
          REPLACE(s.SH_NOTE_2, ',')              AS "AttentionTo" ,
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
          NULL AS PaymentType,s.SH_CAMPAIGN,NULL,NULL,NULL
    FROM      PWIN175.SD d
			  RIGHT JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  LEFT JOIN PWIN175.ST t  ON t.ST_PICK  = d.SD_LAST_PICK_NUM
        LEFT JOIN PWIN175.SL l   ON l.SL_PICK   = t.ST_PICK
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
        INNER JOIN PWIN175.NI n  ON n.NI_NV_EXT_KEY = l.SL_UID
    WHERE NI_NV_EXT_TYPE = 1810105 AND NI_STRENGTH = 3 AND NI_DATE = t.ST_DESP_DATE AND NI_STOCK = d.SD_STOCK AND NI_STATUS <> 0
        AND     s.SH_STATUS <> 3
        AND     i.IM_CUST  = sCustomerCode
        AND       s.SH_ORDER = t.ST_ORDER
        --AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
        AND       t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate
        AND       d.SD_LAST_PICK_NUM = t.ST_PICK;
    l_start number default dbms_utility.get_time;
   BEGIN

        nCheckpoint := 1;
        v_query := 'TRUNCATE TABLE TMP_STOCK_FEES';
        EXECUTE IMMEDIATE v_query;

        nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCustomerCode || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;

        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_STOCK_FEES VALUES l_data(i);
        --USING sCust;
        EXIT WHEN c%NOTFOUND;
        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
        -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        --END LOOP;
        v_query2 :=  SQL%ROWCOUNT;
    COMMIT;

     IF v_query2 > 0 THEN
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'G2_STOCK_FEES','SD','TMP_STOCK_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
      DBMS_OUTPUT.PUT_LINE('G2_STOCK_FEES for the date range '
      || startdate || ' -- ' || enddate || ' - ' || v_query2
      || ' records inserted into table TMP_STOCK_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
      || ' Seconds...for customer ' || sCustomerCode );
    Else
      DBMS_OUTPUT.PUT_LINE('G2_STOCK_FEES rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
    EXCEPTION
        WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('G2_STOCK_FEES failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
    RAISE;
  END G2_STOCK_FEES;

  /*   G3_PACKING_FEES Run this once for each customer   */
  /*   This gets all the Handeling Related Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_PACKING_FEES   Packing Fee  */
  /*   Prism Rate Field Used   */
  /*   A. RM_XX_FEE08 & RM_XX_FEE09   */
  PROCEDURE G3_PACKING_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
      ,sAnalysis IN RM.RM_ANAL%TYPE

      -- sCust IN RM.RM_CUST%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_PACKING_FEES%ROWTYPE;
    l_data ARRAY;
    v_time_taken VARCHAR2(205);
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
    nbreakpoint   NUMBER;
     CURSOR c
    IS
    /* Packing Fee  */
    SELECT
        s.SH_CUST                AS "Customer",
			  r.sGroupCust              AS "Parent",
			  i.IM_XX_COST_CENTRE01         AS "CostCentre",
			  s.SH_ORDER               AS "Order",
			  s.SH_SPARE_STR_5         AS "OrderwareNum",
			  s.SH_CUST_REF            AS "CustomerRef",
			  t.ST_PICK                AS "PickNum",
			  t.ST_PSLIP               AS "DespNote",
			  substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
        substr(To_Char(s.SH_ADD_DATE),0,10) AS "OrderDate",
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
        CASE   WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN (SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) -- (Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode)
        WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) -- (Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCustomerCode)
        ELSE NULL
        END                      AS "UnitPrice",
        CASE   WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN (SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) --(Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode)
        WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) -- (Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCustomerCode)
        ELSE NULL
        END                                          AS "OWUnitPrice",
        CASE  WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN (SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP -- (Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode)  * d.SD_QTY_DESP
        WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP --- (Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCustomerCode)  * d.SD_QTY_DESP
        ELSE NULL
        END                      AS "DExcl",
        CASE   WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP --(Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode)
        WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP -- (Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCustomerCode)
        ELSE NULL
        END                                          AS "Excl_Total",
        CASE WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1 -- ((Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1
        WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1 --  ((Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1
        ELSE NULL
        END                      AS "DIncl",
        CASE WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN  ((SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1 -- ((Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1
        WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1 -- ((Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1
        ELSE NULL
        END                      AS "Incl_Total",
        CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN (Select i.IM_REPORTING_PRICE from IM i where i.IM_STOCK = d.SD_STOCK)
        ELSE NULL
        END                      AS "ReportingPrice",
        REPLACE(s.SH_ADDRESS,',')             AS "Address",
        REPLACE(s.SH_SUBURB,',')              AS "Address2",
        REPLACE(s.SH_CITY, ',')                AS "Suburb",
        s.SH_STATE               AS "State",
        s.SH_POST_CODE           AS "Postcode",
        REPLACE(s.SH_NOTE_1, ',')              AS "DeliverTo",
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
        s.SH_SPARE_INT_4 AS PaymentType,s.SH_CAMPAIGN,NULL,NULL,NULL
    FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER  AND t.ST_PICK = d.SD_LAST_PICK_NUM
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
        INNER JOIN RM ON RM_CUST = i.IM_CUST
    WHERE     Upper(i.IM_XX_QTY_PER_PACK) IN ('INNER','OUTER')
        AND       i.IM_CUST = sCustomerCode
        AND       s.SH_STATUS <> 3
        AND       s.SH_ORDER = t.ST_ORDER
        --AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date;
        AND       d.SD_ADD_DATE >= startdate AND d.SD_ADD_DATE <= enddate;

  QueryTable VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode5}';
  sCust_Rates RM.RM_XX_FEE08%TYPE;/*1 PackingInner*/
  QueryTable2 VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode5}';
  sCust_Rates2 RM.RM_XX_FEE09%TYPE;/*1 PackingOuter*/
  l_start number default dbms_utility.get_time;
   BEGIN
       nCheckpoint := 10;
      EXECUTE IMMEDIATE QueryTable INTO sCust_Rates USING sCustomerCode;/*1 PackingInner*/
      EXECUTE IMMEDIATE QueryTable2 INTO sCust_Rates2 USING sCustomerCode;/*1 PackingOuter*/

      nCheckpoint := 11;
      v_query := 'TRUNCATE TABLE TMP_PACKING_FEES';
      EXECUTE IMMEDIATE v_query;

      IF To_Number(regexp_substr(sCust_Rates,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) != 0 Then
        --DBMS_OUTPUT.PUT_LINE('G3_PACKING_FEES Inner rates are $' || sCust_Rates || '. G3_PACKING_FEES Outer rates are $' || sCust_Rates2 || '. Prism rate fields are RM_XX_FEE08 * RM_XX_FEE09.');

        nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCustomerCode || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;

        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_PACKING_FEES VALUES l_data(i);
        --USING sCust;
        EXIT WHEN c%NOTFOUND;
        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
        -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        --END LOOP;
        v_query2 :=  SQL%ROWCOUNT;
    COMMIT;

        IF v_query2 > 0 THEN
          v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'G3_PACKING_FEES','SL','TMP_PACKING_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
          DBMS_OUTPUT.PUT_LINE('G3_PACKING_FEES for the date range '
          || startdate || ' -- ' || enddate || ' - ' || v_query2
          || ' records inserted into table TMP_PACKING_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
          || ' Seconds...for customer ' || sCustomerCode );
        Else
          DBMS_OUTPUT.PUT_LINE('G3_PACKING_FEES rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
          ' Seconds...for customer ' || sCustomerCode);
        END IF;
     Else
      DBMS_OUTPUT.PUT_LINE('G3_PACKING_FEES rates are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
    EXCEPTION
        WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('G3_PACKING_FEES failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
    RAISE;
  END G3_PACKING_FEES;

  /*   G4_HANDLING_FEES Run this once for each customer   */
  /*   This gets all the Handeling Related Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_HANDLING_FEES   Handling Fee  */
  /*   Prism Rate Field Used   */
  /*   A. RM_XX_FEE06   */
  PROCEDURE G4_HANDLING_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
      ,sAnalysis IN RM.RM_ANAL%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_HANDLING_FEES%ROWTYPE;
    l_data ARRAY;
    v_time_taken VARCHAR2(205);
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		nbreakpoint   NUMBER;
     CURSOR c
    IS
    /*Handeling Fee*/
	  SELECT
          s.SH_CUST            AS "Customer",
          r.sGroupCust            AS "Parent",
          s.SH_SPARE_STR_4          AS "CostCentre",
          s.SH_ORDER               AS "Order",
          s.SH_SPARE_STR_5         AS "OrderwareNum",
          s.SH_CUST_REF            AS "CustomerRef",
          t.vSLPickslipNum         AS "Pickslip",
          t.vSLPslip                      AS "DespatchNote",
          t.vDateDespSL               AS "DespatchNote",
          s.SH_ADD_DATE             AS "OrderDate",
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
          CASE    WHEN t.vSLPslip IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)
			    ELSE NULL
			    END                      AS "UnitPrice",
          CASE    WHEN t.vSLPslip IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)
			    ELSE NULL
			    END                                      AS "OWUnitPrice",
          CASE    WHEN t.vSLPslip IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)
			    ELSE NULL
			    END                      AS "DExcl",
          CASE    WHEN t.vSLPslip IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)
			    ELSE NULL
			    END                                 AS "Excl_Total",
          CASE    WHEN t.vSLPslip IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * 1.1
			    ELSE NULL
			    END                      AS "DIncl",
          CASE    WHEN t.vSLPslip IS NOT NULL THEN   (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)  * 1.1
			    ELSE NULL
			    END                      AS "Incl_Total",
          CASE    WHEN t.vSLPslip IS NOT NULL THEN  (Select To_Number(i.IM_REPORTING_PRICE) from IM i where i.IM_STOCK = 'COURIERM')
			    ELSE NULL
			    END                      AS "ReportingPrice",
          REPLACE(s.SH_ADDRESS, ',')             AS "Address",
			    REPLACE(s.SH_SUBURB, ',')              AS "Address2",
			    REPLACE(s.SH_CITY, ',')                AS "Suburb",
			    s.SH_STATE               AS "State",
			    s.SH_POST_CODE           AS "Postcode",
			    REPLACE(s.SH_NOTE_1, ',')              AS "DeliverTo",
			    REPLACE(s.SH_NOTE_2, ',')              AS "AttentionTo" ,
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
          s.SH_SPARE_INT_4 AS PaymentType,s.SH_CAMPAIGN,NULL,NULL,NULL
      FROM  Tmp_Admin_Data_Pick_LineCounts t LEFT JOIN PWIN175.SH s ON  LTrim(s.SH_ORDER) = LTrim(t.vSLOrderNum)
          LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
		  WHERE  s.SH_STATUS <> 3
          AND (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
          AND (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) > 0.1
          AND t.vSLPslip <> 'CANCELLED'
	  GROUP BY
        s.SH_ORDER,r.sGroupCust,r.sCust,s.SH_SPARE_STR_4,s.SH_CUST,t.vSLPickslipNum,t.vSLPslip,
			  t.vDateDespSL,s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_ADD_DATE,
			  s.SH_NOTE_2,t.vWeightSL,t.vPackagesSL,s.SH_SPARE_DBL_9,t.nCountOfLines,r.sGroupCust,
        s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,s.SH_SPARE_INT_4,s.SH_SPARE_STR_5,s.SH_CAMPAIGN,NULL,NULL,NULL;

  QueryTable VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode5}';
  sCust_Rates RM.RM_XX_FEE06%TYPE;
  l_start number default dbms_utility.get_time;
   BEGIN
      nCheckpoint := 10;
      EXECUTE IMMEDIATE QueryTable INTO sCust_Rates USING sCustomerCode;

      nCheckpoint := 11;
      v_query := 'TRUNCATE TABLE TMP_HANDLING_FEES';
      EXECUTE IMMEDIATE v_query;

      IF To_Number(regexp_substr(sCust_Rates,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) != 0 Then
        --DBMS_OUTPUT.PUT_LINE('G4_HANDLING_FEES rates are $' || sCust_Rates || '. Prism rate field is RM_XX_FEE06.');

        nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCustomerCode || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;

        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_HANDLING_FEES VALUES l_data(i);
        --USING sCust;
        EXIT WHEN c%NOTFOUND;
        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
        -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        --END LOOP;
        v_query2 :=  SQL%ROWCOUNT;
    COMMIT;

       IF v_query2 > 0 THEN
          v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'G4_HANDLING_FEES','SL','TMP_HANDLING_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
          DBMS_OUTPUT.PUT_LINE('G4_HANDLING_FEES for the date range '
          || startdate || ' -- ' || enddate || ' - ' || v_query2
          || ' records inserted into table TMP_HANDLING_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
          || ' Seconds...for customer ' || sCustomerCode );
        Else
          DBMS_OUTPUT.PUT_LINE('G4_HANDLING_FEES rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
          ' Seconds...for customer ' || sCustomerCode);
        END IF;
    Else
      DBMS_OUTPUT.PUT_LINE('G4_HANDLING_FEES rates are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
    EXCEPTION
        WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('G4_HANDLING_FEES failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
    RAISE;
  END G4_HANDLING_FEES;

  /*   G4_HANDLING_FEES Run this once for each customer   */
  /*   This gets all the Handeling Related Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_HANDLING_FEES   Handling Fee  */
  /*   Prism Rate Field Used   */
  /*   A. RM_XX_FEE06   */
  PROCEDURE G4_HANDLING_FEES_F (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
      ,sAnalysis IN RM.RM_ANAL%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_HANDLING_FEES%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_time_taken VARCHAR2(205);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		nbreakpoint   NUMBER;
     CURSOR c
    IS
    /*Handeling Fee*/
	  SELECT
          s.SH_CUST            AS "Customer",
          r.sGroupCust            AS "Parent",
          s.SH_SPARE_STR_4          AS "CostCentre",
          s.SH_ORDER               AS "Order",
          s.SH_SPARE_STR_5         AS "OrderwareNum",
          s.SH_CUST_REF            AS "CustomerRef",
          t.ST_PICK         AS "Pickslip",
          t.ST_PSLIP                      AS "DespatchNote",
          t.ST_DESP_DATE               AS "DespatchNote",
          s.SH_ADD_DATE             AS "OrderDate",
          CASE    WHEN t.ST_PSLIP IS NOT NULL THEN 'Handeling Fee is '
			    ELSE NULL
			    END                      AS "FeeType",
          CASE    WHEN t.ST_PSLIP IS NOT NULL THEN  'Handeling'
			    ELSE NULL
			    END                     AS "Item",
          CASE    WHEN t.ST_PSLIP IS NOT NULL THEN  'Handeling Fee'
			    ELSE NULL
			    END                     AS "Description",
          CASE    WHEN t.ST_PSLIP IS NOT NULL THEN  1
			    ELSE NULL
			    END                     AS "Qty",
          CASE    WHEN t.ST_PSLIP IS NOT NULL THEN  '1'
			    ELSE ''
			    END                     AS "UOI",
          CASE    WHEN t.ST_PSLIP IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)
			    ELSE NULL
			    END                      AS "UnitPrice",
          CASE    WHEN t.ST_PSLIP IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)
			    ELSE NULL
			    END                                      AS "OWUnitPrice",
          CASE    WHEN t.ST_PSLIP IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)
			    ELSE NULL
			    END                      AS "DExcl",
          CASE    WHEN t.ST_PSLIP IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)
			    ELSE NULL
			    END                                 AS "Excl_Total",
          CASE    WHEN t.ST_PSLIP IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * 1.1
			    ELSE NULL
			    END                      AS "DIncl",
          CASE    WHEN t.ST_PSLIP IS NOT NULL THEN   (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)  * 1.1
			    ELSE NULL
			    END                      AS "Incl_Total",
          CASE    WHEN t.ST_PSLIP IS NOT NULL THEN  (Select To_Number(i.IM_REPORTING_PRICE) from IM i where i.IM_STOCK = 'COURIERM')
			    ELSE NULL
			    END                      AS "ReportingPrice",
          REPLACE(s.SH_ADDRESS, ',')             AS "Address",
			    REPLACE(s.SH_SUBURB, ',')              AS "Address2",
			    REPLACE(s.SH_CITY, ',')                AS "Suburb",
			    s.SH_STATE               AS "State",
			    s.SH_POST_CODE           AS "Postcode",
			    REPLACE(s.SH_NOTE_1, ',')              AS "DeliverTo",
			    REPLACE(s.SH_NOTE_2, ',')              AS "AttentionTo" ,
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
          NULL As   Cost,
          s.SH_SPARE_INT_4 AS PaymentType,s.SH_CAMPAIGN,NULL,NULL,NULL
      FROM  ST t LEFT JOIN PWIN175.SH s ON  LTrim(s.SH_ORDER) = LTrim(t.ST_ORDER)
          LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
		  WHERE  s.SH_STATUS <> 3
          AND (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
          AND (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) > 0.1
          AND t.ST_PSLIP <> 'CANCELLED'
           AND t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate
	  GROUP BY
        s.SH_ORDER,r.sGroupCust,r.sCust,s.SH_SPARE_STR_4,s.SH_CUST,t.ST_PICK,t.ST_PSLIP,
			  t.ST_DESP_DATE,s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_ADD_DATE,
			  s.SH_NOTE_2,t.ST_WEIGHT,t.ST_PACKAGES,s.SH_SPARE_DBL_9,r.sGroupCust,
        s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,s.SH_SPARE_INT_4,s.SH_SPARE_STR_5,s.SH_CAMPAIGN,NULL,NULL,NULL;

  QueryTable VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode5}';
  sCust_Rates RM.RM_XX_FEE06%TYPE;
  l_start number default dbms_utility.get_time;
   BEGIN
      nCheckpoint := 10;
      EXECUTE IMMEDIATE QueryTable INTO sCust_Rates USING sCustomerCode;

      nCheckpoint := 11;
      v_query := 'TRUNCATE TABLE TMP_HANDLING_FEES';
      EXECUTE IMMEDIATE v_query;

      IF To_Number(regexp_substr(sCust_Rates,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) != 0 Then
        --DBMS_OUTPUT.PUT_LINE('G4_HANDLING_FEES rates are $' || sCust_Rates || '. Prism rate field is RM_XX_FEE06.');

        nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCustomerCode || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;

        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_HANDLING_FEES VALUES l_data(i);
        --USING sCust;
        EXIT WHEN c%NOTFOUND;
        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
        -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        --END LOOP;
        v_query2 :=  SQL%ROWCOUNT;
    COMMIT;

       IF v_query2 > 0 THEN
          v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'G4_HANDLING_FEES_F','SL','TMP_HANDLING_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
          DBMS_OUTPUT.PUT_LINE('G4_HANDLING_FEES_F for the date range '
          || startdate || ' -- ' || enddate || ' - ' || v_query2
          || ' records inserted into table TMP_HANDLING_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
          || ' Seconds...for customer ' || sCustomerCode );
        Else
          DBMS_OUTPUT.PUT_LINE('G4_HANDLING_FEES_F rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
          ' Seconds...for customer ' || sCustomerCode);
        END IF;
    Else
      DBMS_OUTPUT.PUT_LINE('G4_HANDLING_FEES_F rates are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
    EXCEPTION
        WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('G4_HANDLING_FEES_F failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
    RAISE;
  END G4_HANDLING_FEES_F;

  /*   G5_PICK_FEES Run this once for each customer   */
  /*   This gets all the Handeling Related Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_PICK_FEES   Pick Fee  */
  /*   Prism Rate Field Used   */
  /*   A. RM_XX_FEE16   */
  PROCEDURE G5_PICK_FEES_F (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
      ,sAnalysis IN RM.RM_ANAL%TYPE

      -- sCust IN RM.RM_CUST%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_PICK_FEES%ROWTYPE;
    l_data ARRAY;
    v_time_taken VARCHAR2(205);
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		nbreakpoint   NUMBER;

     CURSOR c
    IS
  /* Pick fees  */

	SELECT  s.SH_CUST                AS "Customer",
			r.sGroupCust              AS "Parent",
			s.SH_SPARE_STR_4         AS "CostCentre",
			s.SH_ORDER               AS "Order",
			s.SH_SPARE_STR_5         AS "OrderwareNum",
			s.SH_CUST_REF            AS "CustomerRef",
			t.ST_PICK         AS "Pickslip",
          t.ST_PSLIP                      AS "DespatchNote",
          t.ST_DESP_DATE               AS "DespatchNote",
          s.SH_ADD_DATE             AS "OrderDate",
			CASE    WHEN t.ST_PSLIP IS NOT NULL THEN 'Pick Fee'
			  ELSE NULL
			  END                      AS "FeeType",
			CASE    WHEN t.ST_PSLIP IS NOT NULL THEN 'FEEPICK'
			  ELSE NULL
			  END                      AS "Item",
			CASE    WHEN t.ST_PSLIP IS NOT NULL THEN 'Line Picking Fee'
			  ELSE NULL
			  END                      AS "Description",
        (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK)           AS "Qty",
			 CASE    WHEN t.ST_PSLIP IS NOT NULL THEN  '1'
			  ELSE ''
			  END                     AS "UOI",
			 CASE    WHEN t.ST_PSLIP IS NOT NULL  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)
			  ELSE NULL
			  END                      AS "UnitPrice",
		    CASE  WHEN t.ST_PSLIP IS NOT NULL  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)
              ELSE NULL
			        END                                      AS "OWUnitPrice",
			CASE  WHEN t.ST_PSLIP IS NOT NULL  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)  * (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK)
				     ELSE NULL
				      END                      AS "DExcl",
					CASE  WHEN t.ST_PSLIP IS NOT NULL   THEN (SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)  * (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK)
				     ELSE NULL
			        END                                 AS "Excl_Total",
		  CASE    WHEN t.ST_PSLIP IS NOT NULL  THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)  * (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK)) * 1.1
				      ELSE NULL
				      END                      AS "DIncl",
		  CASE    WHEN t.ST_PSLIP IS NOT NULL  THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)  * (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK)) * 1.1
				      ELSE NULL
				      END                      AS "Incl_Total",
		  CASE    WHEN t.ST_PSLIP IS NOT NULL  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)  * (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK)
				      ELSE NULL
				      END                      AS "ReportingPrice",
			REPLACE(s.SH_ADDRESS, ',')             AS "Address",
			REPLACE(s.SH_SUBURB, ',')              AS "Address2",
			REPLACE(s.SH_CITY, ',')                AS "Suburb",
			s.SH_STATE               AS "State",
			s.SH_POST_CODE           AS "Postcode",
			REPLACE(s.SH_NOTE_1, ',')              AS "DeliverTo",
			REPLACE(s.SH_NOTE_2, ',')              AS "AttentionTo" ,
			t.ST_WEIGHT              AS "Weight",
			t.ST_PACKAGES            AS "Packages",
			s.SH_SPARE_DBL_9         AS "OrderSource",
			NULL                     AS "Pallet/Shelf Space",
			  NULL                     AS "Locn",
			  (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK)                     AS "CountOfStocks",
        CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			        ELSE ''
			        END AS Email,
              'N/A' AS Brand,
           NULL AS    OwnedBy,
           NULL AS    sProfile,
           NULL AS    WaiveFee,
           NULL As   Cost,
           s.SH_SPARE_INT_4 AS PaymentType,s.SH_CAMPAIGN,NULL,NULL,NULL

	FROM  ST t LEFT JOIN PWIN175.SH s ON  s.SH_ORDER = t.ST_ORDER
  INNER JOIN SL l ON l.SL_PICK = t.ST_PICK
	LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
	WHERE   s.SH_STATUS <> 3
  AND (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
  AND (SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) > 0.1
  AND t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate

	GROUP BY  s.SH_ORDER,
			  r.sGroupCust,
        r.sCust,
			  s.SH_SPARE_STR_4,
			  s.SH_CUST,
			  t.ST_PICK,
			  t.ST_PSLIP,
			  t.ST_DESP_DATE,
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
			  t.ST_WEIGHT,
			  t.ST_PACKAGES,
			  s.SH_SPARE_DBL_9,
			  s.SH_ADD_DATE,
			  r.sGroupCust,
			  s.SH_SPARE_STR_5,
			  s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,s.SH_SPARE_INT_4,s.SH_CAMPAIGN;

    QueryTable VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode5}';
    sCust_Rates RM.RM_XX_FEE16%TYPE;/*1 PickFee*/
    l_start number default dbms_utility.get_time;
   BEGIN
    nCheckpoint := 10;
    EXECUTE IMMEDIATE QueryTable INTO sCust_Rates USING sCustomerCode;/*1 PickFee*/

    nCheckpoint := 11;
    v_query := 'TRUNCATE TABLE TMP_PICK_FEES';
    EXECUTE IMMEDIATE v_query;

    IF To_Number(regexp_substr(sCust_Rates,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) != 0 Then
       -- l_start number default dbms_utility.get_time;

       -- DBMS_OUTPUT.PUT_LINE('G5_PICK_FEES rates are $' || sCust_Rates || '. Prism rate field is RM_XX_FEE16.');


        nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCustomerCode || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;

        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_PICK_FEES VALUES l_data(i);
        --USING sCust;
        EXIT WHEN c%NOTFOUND;
        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
        -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        --END LOOP;
        v_query2 :=  SQL%ROWCOUNT;
    COMMIT;

    IF v_query2 > 0 THEN
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'G5_PICK_FEES_F','ST','TMP_PICK_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
      DBMS_OUTPUT.PUT_LINE('G5_PICK_FEES_F for the date range '
      || startdate || ' -- ' || enddate || ' - ' || v_query2
      || ' records inserted into table TMP_PICK_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
      || ' Seconds...for customer ' || sCustomerCode );
    Else
      DBMS_OUTPUT.PUT_LINE('G5_PICK_FEES_F rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
     Else
      DBMS_OUTPUT.PUT_LINE('G5_PICK_FEES_F rates are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
    EXCEPTION
        WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('G5_PICK_FEES_F failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
    RAISE;
  END G5_PICK_FEES_F;

  /*   G5_PICK_FEES Run this once for each customer   */
  /*   This gets all the Handeling Related Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_PICK_FEES   Pick Fee  */
  /*   Prism Rate Field Used   */
  /*   A. RM_XX_FEE16   */
  PROCEDURE G5_PICK_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
      ,sAnalysis IN RM.RM_ANAL%TYPE

      -- sCust IN RM.RM_CUST%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_PICK_FEES%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_time_taken VARCHAR2(205);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		nbreakpoint   NUMBER;

     CURSOR c
    IS
  /* Pick fees  */

	SELECT  s.SH_CUST                AS "Customer",
			r.sGroupCust              AS "Parent",
			s.SH_SPARE_STR_4         AS "CostCentre",
			s.SH_ORDER               AS "Order",
			s.SH_SPARE_STR_5         AS "OrderwareNum",
			s.SH_CUST_REF            AS "CustomerRef",
			t.vSLPickslipNum         AS "Pickslip",
          t.vSLPslip                      AS "DespatchNote",
          t.vDateDespSL               AS "DespatchNote",
          s.SH_ADD_DATE             AS "OrderDate",
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
			 CASE    WHEN t.vSLPslip IS NOT NULL  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)
			  ELSE NULL
			  END                      AS "UnitPrice",
		    CASE  WHEN t.vSLPslip IS NOT NULL  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)
              ELSE NULL
			        END                                      AS "OWUnitPrice",
			CASE  WHEN t.vSLPslip IS NOT NULL  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)  * t.nCountOfLines
				     ELSE NULL
				      END                      AS "DExcl",
					CASE  WHEN t.vSLPslip IS NOT NULL   THEN (SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)  * t.nCountOfLines
				     ELSE NULL
			        END                                 AS "Excl_Total",
		  CASE    WHEN t.vSLPslip IS NOT NULL  THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)  * t.nCountOfLines) * 1.1
				      ELSE NULL
				      END                      AS "DIncl",
		  CASE    WHEN t.vSLPslip IS NOT NULL  THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)  * t.nCountOfLines) * 1.1
				      ELSE NULL
				      END                      AS "Incl_Total",
		  CASE    WHEN t.vSLPslip IS NOT NULL  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)  * t.nCountOfLines
				      ELSE NULL
				      END                      AS "ReportingPrice",
			REPLACE(s.SH_ADDRESS, ',')             AS "Address",
			REPLACE(s.SH_SUBURB, ',')              AS "Address2",
			REPLACE(s.SH_CITY, ',')                AS "Suburb",
			s.SH_STATE               AS "State",
			s.SH_POST_CODE           AS "Postcode",
			REPLACE(s.SH_NOTE_1, ',')              AS "DeliverTo",
			REPLACE(s.SH_NOTE_2, ',')              AS "AttentionTo" ,
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
           s.SH_SPARE_INT_4 AS PaymentType,s.SH_CAMPAIGN,NULL,NULL,NULL

	FROM  Tmp_Admin_Data_Pick_LineCounts t LEFT JOIN PWIN175.SH s ON  LTrim(s.SH_ORDER) = t.vSLOrderNum
	LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
	WHERE   s.SH_STATUS <> 3
  AND (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
  AND (SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) > 0.1

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
			  t.nCountOfLines,s.SH_ADD_DATE,
			  r.sGroupCust,
			  s.SH_SPARE_STR_5,
			  s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,s.SH_SPARE_INT_4,s.SH_CAMPAIGN;

    QueryTable VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode5}';
    sCust_Rates RM.RM_XX_FEE16%TYPE;/*1 PickFee*/
    l_start number default dbms_utility.get_time;
   BEGIN
    nCheckpoint := 10;
    EXECUTE IMMEDIATE QueryTable INTO sCust_Rates USING sCustomerCode;/*1 PickFee*/

    nCheckpoint := 11;
    v_query := 'TRUNCATE TABLE TMP_PICK_FEES';
    EXECUTE IMMEDIATE v_query;

    IF To_Number(regexp_substr(sCust_Rates,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) != 0 Then
       -- l_start number default dbms_utility.get_time;

        DBMS_OUTPUT.PUT_LINE('G5_PICK_FEES rates are $' || sCust_Rates || '. Prism rate field is RM_XX_FEE16.');


        nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCustomerCode || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;

        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_PICK_FEES VALUES l_data(i);
        --USING sCust;
        EXIT WHEN c%NOTFOUND;
        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
        -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        --END LOOP;
        v_query2 :=  SQL%ROWCOUNT;
    COMMIT;

    IF v_query2 > 0 THEN
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'G5_PICK_FEES','ST','TMP_PICK_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
      DBMS_OUTPUT.PUT_LINE('G5_PICK_FEES for the date range '
      || startdate || ' -- ' || enddate || ' - ' || v_query2
      || ' records inserted into table TMP_PICK_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
      || ' Seconds...for customer ' || sCustomerCode );
    Else
      DBMS_OUTPUT.PUT_LINE('G5_PICK_FEES rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
     Else
      DBMS_OUTPUT.PUT_LINE('G5_PICK_FEES rates are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
    EXCEPTION
        WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('G5_PICK_FEES failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
    RAISE;
  END G5_PICK_FEES;

  /*   H1_EOM_STD_STOR_FEES Run this once for each customer   */
  /*   This gets all the Std Storage Related Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_STOR_FEES   */
  /*   Prism Rate Field Used   */
  /*   A. RM_XX_FEE11 & RM_XX_FEE12   */
  PROCEDURE H1_EOM_STD_STOR_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
      ,sAnalysis IN RM.RM_ANAL%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_STOR_FEES%ROWTYPE;
    l_data ARRAY;
    v_time_taken VARCHAR2(205);
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		nbreakpoint   NUMBER;
    sFileName VARCHAR2(560);
    sFileTime VARCHAR2(56)  := TO_CHAR(SYSDATE,'YYYYMMDD HH24MISS');
     CURSOR c
    IS
  /* EOM Storage Fees */
	select IM_CUST AS "Customer",
	  IM_CUST AS "Parent",
	  IM_XX_COST_CENTRE01     AS "CostCentre",
	  NULL               AS "Order",
	  NULL               AS "OrderwareNum",
	  NULL               AS "CustomerRef",
	  NULL         AS "Pickslip",
    NULL                      AS "DespatchNote",
    NULL               AS "DespatchNote",
    NULL             AS "OrderDate",
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
        (SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS
			WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				(SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS
	    ELSE 0
	    END AS "UnitPrice",
		  CASE
			WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
        (SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS
			WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				(SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS
	    ELSE 0
	    END AS "OWUnitPrice",
			CASE
			WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
        (SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS
			WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				(SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS
	    ELSE 0
      END AS "DExcl",
			CASE
			WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
        (SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS
			WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				--r1.RM_XX_FEE12 / tmp.NCOUNTOFSTOCKS
       (SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
	    ELSE 0
      END AS "Excl_Total",
		 CASE WHEN (l1.IL_NOTE_2 like 'Yes'  OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN
				((SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS )  * 1.1
			ELSE
				((SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS )  * 1.1
	    END AS "DIncl",
			 CASE WHEN (l1.IL_NOTE_2 like 'Yes'  OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN
				((SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS )  * 1.1
			ELSE
				((SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS )  * 1.1
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
           NULL AS PaymentType,NULL,NULL,NULL,NULL

	FROM NI n1 INNER JOIN IM ON IM_STOCK = n1.NI_STOCK
	INNER JOIN IL l1 ON l1.IL_LOCN = n1.NI_LOCN
  INNER JOIN Tmp_Locn_Cnt_By_Cust tmp ON tmp.SLOCN = l1.IL_LOCN
  --INNER JOIN RM R1 ON RM_CUST = IM_CUST
  LEFT JOIN Tmp_Group_Cust r ON r.sCust = IM_CUST
	WHERE  (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
	AND IM_ACTIVE = 1
  --AND IM_CUST = sCustomerCode
	AND n1.NI_AVAIL_ACTUAL >= '1'
	AND n1.NI_STATUS <> 0
  AND F_CONFIRM_SLOW_MOVER(IM_STOCK) >= SYSDATE - 90;
  --palett
    CURSOR po
    IS



  /* EOM Storage Fees */
	select IM_CUST AS "Customer",
	  IM_CUST AS "Parent",
	  IM_XX_COST_CENTRE01     AS "CostCentre",
	  NULL               AS "Order",
	  NULL               AS "OrderwareNum",
	  NULL               AS "CustomerRef",
	  NULL         AS "Pickslip",
    NULL                      AS "DespatchNote",
    NULL               AS "DespatchNote",
    NULL             AS "OrderDate",
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
        (SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS
			--WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				--r1.RM_XX_FEE12 / tmp.NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS
	    ELSE 0
	    END AS "UnitPrice",
		  CASE
			WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
        (SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS
			--WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				--r1.RM_XX_FEE12 / tmp.NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS
	    ELSE 0
	    END AS "OWUnitPrice",
			CASE
			WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
        (SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS
		--	WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
			--	r1.RM_XX_FEE12 / tmp.NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS
	    ELSE 0
      END AS "DExcl",
			CASE
			WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
        (SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS
			----WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				--r1.RM_XX_FEE12 / tmp.NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS
	    ELSE 0
      END AS "Excl_Total",
		 CASE WHEN (l1.IL_NOTE_2 like 'Yes'  OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN
				((SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS )  * 1.1
			--ELSE
				--(r1.RM_XX_FEE12 / tmp.NCOUNTOFSTOCKS )  * 1.1
	    END AS "DIncl",
			 CASE WHEN (l1.IL_NOTE_2 like 'Yes'  OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN
				((SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS )  * 1.1
			--ELSE
				--(r1.RM_XX_FEE12 / tmp.NCOUNTOFSTOCKS )  * 1.1
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
           NULL AS PaymentType,NULL,NULL,NULL,NULL

	FROM NI n1 INNER JOIN IM ON IM_STOCK = n1.NI_STOCK
	INNER JOIN IL l1 ON l1.IL_LOCN = n1.NI_LOCN
  INNER JOIN Tmp_Locn_Cnt_By_Cust tmp ON tmp.SLOCN = l1.IL_LOCN
  --INNER JOIN RM R1 ON RM_CUST = IM_CUST
  LEFT JOIN Tmp_Group_Cust r ON r.sCust = IM_CUST
	WHERE  (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
	AND IM_ACTIVE = 1
  --AND IM_CUST = sCustomerCode
	AND n1.NI_AVAIL_ACTUAL >= '1'
	AND n1.NI_STATUS <> 0
  AND F_CONFIRM_SLOW_MOVER(IM_STOCK) >= SYSDATE - 90;

  --shelf
    CURSOR so
    IS



  /* EOM Storage Fees */
	select IM_CUST AS "Customer",
	  IM_CUST AS "Parent",
	  IM_XX_COST_CENTRE01     AS "CostCentre",
	  NULL               AS "Order",
	  NULL               AS "OrderwareNum",
	  NULL               AS "CustomerRef",
	  NULL         AS "Pickslip",
    NULL                      AS "DespatchNote",
    NULL               AS "DespatchNote",
    NULL             AS "OrderDate",
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
			--WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
        --r1.RM_XX_FEE11 / tmp.NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS
			WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				(SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS
	    ELSE 0
	    END AS "UnitPrice",
		  CASE
			--WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
        --r1.RM_XX_FEE11 / tmp.NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS
			WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				(SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS
	    ELSE 0
	    END AS "OWUnitPrice",
			CASE
			--WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
      --  r1.RM_XX_FEE11 / tmp.NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS
			WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				(SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS
	    ELSE 0
      END AS "DExcl",
			CASE
			--WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
        --r1.RM_XX_FEE11 / tmp.NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS
			WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				(SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS
	    ELSE 0
      END AS "Excl_Total",
		 CASE
    -- WHEN (l1.IL_NOTE_2 like 'Yes'  OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
			--	(r1.RM_XX_FEE11 / tmp.NCOUNTOFSTOCKS )  * 1.1
			WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				((SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS )  * 1.1
	    END AS "DIncl",
			 CASE
      -- WHEN (l1.IL_NOTE_2 like 'Yes'  OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')THEN
				--(r1.RM_XX_FEE11 / tmp.NCOUNTOFSTOCKS )  * 1.1
			WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				((SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS )  * 1.1
	    END AS "Incl_Total",
	   CASE
     WHEN l1.IL_LOCN IS NOT NULL THEN (Select To_Number(i.IM_REPORTING_PRICE) from IM i where i.IM_STOCK = 'COURIERM')
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
           NULL AS PaymentType,NULL,NULL,NULL,NULL

	FROM NI n1 INNER JOIN IM ON IM_STOCK = n1.NI_STOCK
	INNER JOIN IL l1 ON l1.IL_LOCN = n1.NI_LOCN
  INNER JOIN Tmp_Locn_Cnt_By_Cust tmp ON tmp.SLOCN = l1.IL_LOCN
  --INNER JOIN RM R1 ON RM_CUST = IM_CUST
  LEFT JOIN Tmp_Group_Cust r ON r.sCust = IM_CUST
	WHERE  (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
	AND IM_ACTIVE = 1
  --AND IM_CUST = sCustomerCode
	AND n1.NI_AVAIL_ACTUAL >= '1'
	AND n1.NI_STATUS <> 0
  AND F_CONFIRM_SLOW_MOVER(IM_STOCK) >= SYSDATE - 90;

  QueryTable VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode}';
  sCust_Rates RM.RM_XX_FEE11%TYPE;
  QueryTable2 VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode}';
  sCust_Rates2 RM.RM_XX_FEE12%TYPE;
  l_start number default dbms_utility.get_time;
  BEGIN
  nCheckpoint := 10;
  EXECUTE IMMEDIATE QueryTable INTO sCust_Rates USING sCustomerCode;
  EXECUTE IMMEDIATE QueryTable2 INTO sCust_Rates2 USING sCustomerCode;


  nCheckpoint := 11;
  v_query := 'TRUNCATE TABLE TMP_STOR_FEES';
  EXECUTE IMMEDIATE v_query;

  IF To_Number(regexp_substr(sCust_Rates,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0
   AND To_Number(regexp_substr(sCust_Rates2,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0 THEN
   DBMS_OUTPUT.PUT_LINE('H1_EOM_STD_STOR_FEES Std Pallet Storage rates are $' || sCust_Rates || '. Std Shelf Storage rates are $' || sCust_Rates2 || '. Prism rate fields are RM_XX_FEE11 & RM_XX_FEE12.');



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
      v_query2 :=  SQL%ROWCOUNT;
      COMMIT;
      If F_IS_TABLE_EEMPTY('TMP_STOR_FEES') > 0 Then

        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
        EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'H1A_EOM_STD_STOR_FEES','IL','TMP_STOR_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        sFileName := sCustomerCode || '-H1A_EOM_STD_STOR_FEES-' || startdate || '-TO-' || enddate || '-RunOn-' || sFileTime ||  '.csv';
        Z2_TMP_FEES_TO_CSV(sFileName,'TMP_STOR_FEES');
        DBMS_OUTPUT.PUT_LINE('Z2_TMP_FEES_TO_CSV for ' || sFileName || '.' );
        --COMMIT;
        DBMS_OUTPUT.PUT_LINE('H1A_EOM_STD_STOR_FEES Fees for the date range '
            || startdate || ' -- ' || enddate || ' - ' || v_query2 || ' records inserted into table TMP_STOR_FEES in ' || (round((dbms_utility.get_time-l_start)/100, 6) ||
            ' Seconds...for customer ' || sCustomerCode ));

      Else
        DBMS_OUTPUT.PUT_LINE('H1A_EOM_STD_STOR_FEES Std Shelf Storage Fees rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
        ' Seconds...for customer ' || sCustomerCode);
      END IF;

        --COMMIT;
        --palett
    ELSIF To_Number(regexp_substr(sCust_Rates,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0
   AND To_Number(regexp_substr(sCust_Rates2,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) = 0 THEN
   DBMS_OUTPUT.PUT_LINE('H1_EOM_STD_STOR_FEES Std Pallet Storage rates are $' || sCust_Rates || '. Prism rate field is RM_XX_FEE11.');

        nCheckpoint := 1;
          v_query := 'TRUNCATE TABLE TMP_STOR_FEES';
          EXECUTE IMMEDIATE v_query;

        nCheckpoint := 2;
            OPEN po;
            --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
            LOOP
            FETCH po BULK COLLECT INTO l_data LIMIT p_array_size;

            FORALL i IN 1..l_data.COUNT
            --DBMS_OUTPUT.PUT_LINE(i || '.' );
            INSERT INTO TMP_STOR_FEES VALUES l_data(i);
            --USING sCust;

            EXIT WHEN po%NOTFOUND;

            END LOOP;
           -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            CLOSE po;
          -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
            --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          --END LOOP;
      v_query2 :=  SQL%ROWCOUNT;
      COMMIT;
      If F_IS_TABLE_EEMPTY('TMP_STOR_FEES') > 0 Then

        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
        EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'H1B_EOM_STD_STOR_FEES','IL','TMP_STOR_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        sFileName := sCustomerCode || '-H1B_EOM_STD_STOR_FEES-' || startdate || '-TO-' || enddate || '-RunOn-' || sFileTime ||  '.csv';
        Z2_TMP_FEES_TO_CSV(sFileName,'TMP_STOR_FEES');
        DBMS_OUTPUT.PUT_LINE('Z2_TMP_FEES_TO_CSV for ' || sFileName || '.' );
        --COMMIT;
        DBMS_OUTPUT.PUT_LINE('H1B_EOM_STD_STOR_FEES Std Pallet Storage Fees for the date range '
            || startdate || ' -- ' || enddate || ' - ' || v_query2 || ' records inserted into table TMP_STOR_FEES in ' || (round((dbms_utility.get_time-l_start)/100, 6) ||
            ' Seconds...for customer ' || sCustomerCode ));

      Else
        DBMS_OUTPUT.PUT_LINE('H1B_EOM_STD_STOR_FEES Std Shelf Storage Fees rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
        ' Seconds...for customer ' || sCustomerCode);
      END IF;

        --COMMIT;
        --shelf
    ELSIF To_Number(regexp_substr(sCust_Rates,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) = 0
   AND To_Number(regexp_substr(sCust_Rates2,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0 THEN
   DBMS_OUTPUT.PUT_LINE('H1_EOM_STD_STOR_FEES Std Shelf Storage rates are $' || sCust_Rates2 || '. Prism rate field is RM_XX_FEE12.');

        nCheckpoint := 1;
          v_query := 'TRUNCATE TABLE TMP_STOR_FEES';
          EXECUTE IMMEDIATE v_query;

        nCheckpoint := 2;
            OPEN so;
            --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
            LOOP
            FETCH so BULK COLLECT INTO l_data LIMIT p_array_size;

            FORALL i IN 1..l_data.COUNT
            --DBMS_OUTPUT.PUT_LINE(i || '.' );
            INSERT INTO TMP_STOR_FEES VALUES l_data(i);
            --USING sCust;

            EXIT WHEN so%NOTFOUND;

            END LOOP;
           -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            CLOSE so;
          -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
            --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          --END LOOP;
      v_query2 :=  SQL%ROWCOUNT;
      COMMIT;

       If F_IS_TABLE_EEMPTY('TMP_STOR_FEES') > 0 Then

        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
        EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'ZZZ H1_EOM_STD_STOR_FEES','IL','TMP_STOR_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        sFileName := sCustomerCode || '-H1_EOM_STD_STOR_FEES-' || startdate || '-TO-' || enddate || '-RunOn-' || sFileTime ||  '.csv';
        Z2_TMP_FEES_TO_CSV(sFileName,'TMP_STOR_FEES');
        DBMS_OUTPUT.PUT_LINE('Z2_TMP_FEES_TO_CSV for ' || sFileName || '.' );
        --COMMIT;
        DBMS_OUTPUT.PUT_LINE('ZZZ H1_EOM_STD_STOR_FEES Std Shelf Storage Fees for the date range '
        || startdate || ' -- ' || enddate || ' - ' || v_query2
        || ' records inserted into table TMP_STOR_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
        || ' Seconds...for customer ' || sCustomerCode );

      Else
        DBMS_OUTPUT.PUT_LINE('H1C_EOM_STD_STOR_FEES Std Shelf Storage Fees rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
        ' Seconds...for customer ' || sCustomerCode);
      END IF;
    Else
      DBMS_OUTPUT.PUT_LINE('H1_EOM_STD_STOR_FEES Std Pallet Storage rates & H1_EOM_STD_STOR_FEES Std Shelf Storage rates are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('H1_EOM_STD_STOR_FEES failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;

  END H1_EOM_STD_STOR_FEES;

  /*   H1_EOM_STD_STOR_FEES Run this once for each customer   */
  /*   This gets all the Std Storage Related Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_STOR_FEES   */
  /*   Prism Rate Field Used   */
  /*   A. RM_XX_FEE11 & RM_XX_FEE12   */
  PROCEDURE H4_EOM_ALL_STOR_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
      ,sAnalysis IN RM.RM_ANAL%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_STOR_ALL_FEES%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    v_time_taken VARCHAR2(205);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		nbreakpoint   NUMBER;
    sFileName VARCHAR2(560);
    sFileTime VARCHAR2(56)  := TO_CHAR(SYSDATE,'YYYYMMDD HH24MISS');
     CURSOR c
    IS
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
		n1.NI_STOCK AS "Item",
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
      END AS "Excl_Total",
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
      END AS "Incl_Total",
    TO_NUMBER(IM_REPORTING_PRICE),
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
		n1.NI_LOCN AS "Locn",
		tmp.NCOUNTOFSTOCKS AS CountCustStocks,
    NULL AS Email,
    IM_BRAND AS Brand,
    IM_OWNED_By AS    OwnedBy,
    IM_PROFILE AS    sProfile,
    NULL AS    WaiveFee,
    NULL As   Cost,
    NULL AS PaymentType,NULL,NULL,NULL,NULL

	FROM NI n1 INNER JOIN IM ON IM_STOCK = n1.NI_STOCK
	INNER JOIN IL l1 ON l1.IL_LOCN = n1.NI_LOCN
  INNER JOIN Tmp_Locn_Cnt_By_Cust tmp ON tmp.SLOCN = l1.IL_LOCN
  LEFT JOIN Tmp_Group_Cust r ON r.sCust = IM_CUST
	WHERE  IM_ACTIVE = 1
  AND n1.NI_AVAIL_ACTUAL >= '1'
	AND n1.NI_STATUS <> 0GROUP BY l1.IL_LOCN,IM_CUST,IM_BRAND,IM_OWNED_By,IM_PROFILE,l1.IL_NOTE_2,n1.NI_LOCN,n1.NI_STOCK,
	tmp.NCOUNTOFSTOCKS,IM_REPORTING_PRICE,r.sGroupCust,IM_LEVEL_UNIT,IM_XX_COST_CENTRE01,IM_STOCK;

  QueryTable VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode}';
  sCust_Rates RM.RM_XX_FEE11%TYPE;
  QueryTable2 VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode}';
  sCust_Rates2 RM.RM_XX_FEE12%TYPE;
  l_start number default dbms_utility.get_time;
  BEGIN



  nCheckpoint := 11;
  v_query := 'TRUNCATE TABLE TMP_STOR_ALL_FEES';
  EXECUTE IMMEDIATE v_query;




        nCheckpoint := 2;
            OPEN c;
            --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
            LOOP
            FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;

            FORALL i IN 1..l_data.COUNT
            --DBMS_OUTPUT.PUT_LINE(i || '.' );
            INSERT INTO TMP_STOR_ALL_FEES VALUES l_data(i);
            --USING sCust;

            EXIT WHEN c%NOTFOUND;

            END LOOP;
           -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            CLOSE c;
          -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
            --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          --END LOOP;
      v_query2 :=  SQL%ROWCOUNT;
      COMMIT;
      If F_IS_TABLE_EEMPTY('TMP_STOR_ALL_FEES') > 0 Then

        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
        EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'H4A_EOM_ALL_STOR_FEES','IL','TMP_STOR_ALL_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        sFileName := sCustomerCode || '-H4A_EOM_ALL_STOR_FEES-' || startdate || '-TO-' || enddate || '-RunOn-' || sFileTime ||  '.csv';
        Z2_TMP_FEES_TO_CSV(sFileName,'TMP_STOR_ALL_FEES');
        DBMS_OUTPUT.PUT_LINE('Z2_TMP_FEES_TO_CSV for ' || sFileName || '.' );
        --COMMIT;
        DBMS_OUTPUT.PUT_LINE('H4A_EOM_ALL_STOR_FEES Fees for the date range '
            || startdate || ' -- ' || enddate || ' - ' || v_query2 || ' records inserted into table TMP_ALL_STOR_FEES in ' || (round((dbms_utility.get_time-l_start)/100, 6) ||
            ' Seconds...for customer ' || sCustomerCode ));

      Else
        DBMS_OUTPUT.PUT_LINE('H4A_EOM_ALL_STOR_FEES Std Shelf Storage Fees rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
        ' Seconds...for customer ' || sCustomerCode);
      END IF;

        --COMMIT;
        --palett

  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('H4_EOM_ALL_STOR_FEES failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;

  END H4_EOM_ALL_STOR_FEES;

   /*   H1_EOM_STD_STOR_FEES Run this once for each customer   */
  /*   This gets all the Std Storage Related Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_STOR_FEES   */
  /*   Prism Rate Field Used   */
  /*   A. RM_XX_FEE11 & RM_XX_FEE12   */
  PROCEDURE H4_EOM_ALL_STOR (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
      ,sAnalysis IN RM.RM_ANAL%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_STOR_ALL_FEES%ROWTYPE;
    l_data ARRAY;
    v_time_taken VARCHAR2(205);
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		nbreakpoint   NUMBER;
    sFileName VARCHAR2(560);
    sFileTime VARCHAR2(56)  := TO_CHAR(SYSDATE,'YYYYMMDD HH24MISS');
     CURSOR c
      IS
      /* EOM Storage Fees */
      select *
      FROM TMP_STOR_ALL_FEES t
      WHERE  t.Customer = sCustomerCode OR t.parent = sCustomerCode;
    CURSOR c2
      IS
      /* EOM Storage Fees */
      select *
      FROM TMP_STOR_ALL_FEES t
      WHERE  t.Customer = sCustomerCode OR t.parent = sCustomerCode
      OR t.Customer = 'CGU' OR t.parent = 'CGU';

 -- QueryTable VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode}';
  --sCust_Rates RM.RM_XX_FEE11%TYPE;
  --QueryTable2 VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode}';
 -- sCust_Rates2 RM.RM_XX_FEE12%TYPE;
  l_start number default dbms_utility.get_time;
  BEGIN



  nCheckpoint := 11;
  v_query := 'TRUNCATE TABLE TMP_STOR_FEES';
  EXECUTE IMMEDIATE v_query;




        nCheckpoint := 2;
        If (sCustomerCode != 'IAG') Then
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
          Else
             OPEN c2;
            --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
            LOOP
            FETCH c2 BULK COLLECT INTO l_data LIMIT p_array_size;

            FORALL i IN 1..l_data.COUNT
            --DBMS_OUTPUT.PUT_LINE(i || '.' );
            INSERT INTO TMP_STOR_FEES VALUES l_data(i);
            --USING sCust;

            EXIT WHEN c2%NOTFOUND;

            END LOOP;
           -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            CLOSE c2;
          -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
            --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          --END LOOP;
          End If;
      v_query2 :=  SQL%ROWCOUNT;
      COMMIT;
      If F_IS_TABLE_EEMPTY('TMP_STOR_FEES') > 0 Then

        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
        EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'H4_EOM_ALL_STOR','IL','TMP_STOR_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        sFileName := sCustomerCode || '-H4_EOM_ALL_STOR-' || startdate || '-TO-' || enddate || '-RunOn-' || sFileTime ||  '.csv';
        Z2_TMP_FEES_TO_CSV(sFileName,'TMP_STOR_FEES');
        DBMS_OUTPUT.PUT_LINE('Z2_TMP_FEES_TO_CSV for ' || sFileName || '.' );
        --COMMIT;
        DBMS_OUTPUT.PUT_LINE('H4_EOM_ALL_STOR Fees for the date range '
            || startdate || ' -- ' || enddate || ' - ' || v_query2 || ' records inserted into table TMP_STOR_FEES in ' || (round((dbms_utility.get_time-l_start)/100, 6) ||
            ' Seconds...for customer ' || sCustomerCode ));

      Else
        DBMS_OUTPUT.PUT_LINE('H4_EOM_ALL_STOR Std Shelf Storage Fees rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
        ' Seconds...for customer ' || sCustomerCode);
      END IF;

        --COMMIT;
        --palett

  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('H4_EOM_ALL_STOR_FEES failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;

  END H4_EOM_ALL_STOR;



  /*   H2_EOM_SLOW_STOR_FEES Run this once for each customer   */
  /*   This gets all the Slow Storage Related Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_SLOW_STOR_FEES   */
  /*   Prism Rate Field Used   */
  /*   A. RM_SPARE_CHAR_3 & RM_XX_FEE30   */
  PROCEDURE H2_EOM_SLOW_STOR_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
      ,sAnalysis IN RM.RM_ANAL%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_SLOW_STOR_FEES%ROWTYPE;
    l_data ARRAY;
    v_time_taken VARCHAR2(205);
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		nbreakpoint   NUMBER;
    sFilename VARCHAR2(560);
    sFileTime VARCHAR2(56)  := TO_CHAR(SYSDATE,'YYYYMMDD HH24MISS');
     CURSOR c
    IS


  /* EOM Slow Moving Storage Fees */
	select IM_CUST AS "Customer",
	  IM_CUST AS "Parent",
	  IM_XX_COST_CENTRE01     AS "CostCentre",
	  NULL               AS "Order",
	  NULL               AS "OrderwareNum",
	  NULL               AS "CustomerRef",
	  NULL               AS "Pickslip",
    NULL               AS "DespNote",
    NULL  AS "DespDate",
    NULL AS "OrderDate",
		CASE /*Fee Type*/
			WHEN (l1.IL_NOTE_2 like 'Yes'
				OR l1.IL_NOTE_2 LIKE 'YES'
				OR l1.IL_NOTE_2 LIKE 'yes')
			THEN 'FEEPALLETSLOW'
			ELSE 'FEESHELFSLOW'
			END AS "FeeType",
		n1.NI_STOCK AS "Item",
		CASE /*explanation of charge*/
			WHEN (l1.IL_NOTE_2 like 'Yes'	OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN 'Slow Moving Pallet Space Utilisation Fee (per month) is split across ' || tmp.NCOUNTOFSTOCKS || ' stock(s)'
			ELSE 'Slow Moving Shelf SPace Utilisation Fee (per month) is split across ' ||	tmp.NCOUNTOFSTOCKS  || ' stock(s)'
			END AS "Description",
	   CASE   WHEN l1.IL_NOTE_2 IS NOT NULL THEN  1
			  ELSE 0
			  END                     AS "Qty",
		IM_LEVEL_UNIT AS "UOI", /*UOI*/
	   CASE
			WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
       (SELECT To_Number(regexp_substr(RM_SPARE_CHAR_3,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS
			WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				(SELECT To_Number(regexp_substr(RM_XX_FEE30,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
        --(SELECT To_Number(regexp_substr(RM_XX_FEE30,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)  / tmp.NCOUNTOFSTOCKS
	    ELSE 0
	    END AS "UnitPrice",
		  CASE
			WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
        (SELECT To_Number(regexp_substr(RM_SPARE_CHAR_3,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS
			WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				(SELECT To_Number(regexp_substr(RM_XX_FEE30,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS
	    ELSE 0
	    END AS "OWUnitPrice",
			CASE
			WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
        (SELECT To_Number(regexp_substr(RM_XX_FEE30,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS
			WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				(SELECT To_Number(regexp_substr(RM_XX_FEE30,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS
	    ELSE 0
      END AS "DExcl",
			CASE
			WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
        (SELECT To_Number(regexp_substr(RM_SPARE_CHAR_3,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS
			WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				(SELECT To_Number(regexp_substr(RM_XX_FEE30,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS
	    ELSE 0
      END AS "Excl_Total",
		 CASE WHEN (l1.IL_NOTE_2 like 'Yes'  OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN
				((SELECT To_Number(regexp_substr(RM_SPARE_CHAR_3,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS )  * 1.1
			ELSE
				((SELECT To_Number(regexp_substr(RM_XX_FEE30,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS )  * 1.1
	    END AS "DIncl",
			 CASE WHEN (l1.IL_NOTE_2 like 'Yes'  OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN
				((SELECT To_Number(regexp_substr(RM_SPARE_CHAR_3,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS )  * 1.1
			ELSE
				((SELECT To_Number(regexp_substr(RM_XX_FEE30,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS )  * 1.1
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
           NULL AS PaymentType,NULL,NULL,NULL,NULL

	FROM NI n1 INNER JOIN IM ON IM_STOCK = n1.NI_STOCK
	INNER JOIN IL l1 ON l1.IL_LOCN = n1.NI_LOCN
  INNER JOIN Tmp_Locn_Cnt_By_Cust tmp ON tmp.SLOCN = l1.IL_LOCN
  --INNER JOIN RM R1 ON RM_CUST = IM_CUST
  LEFT JOIN Tmp_Group_Cust r ON r.sCust = IM_CUST
	WHERE  (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
	AND IM_ACTIVE = 1
  --AND IM_CUST = sCustomerCode
	AND n1.NI_AVAIL_ACTUAL >= '1'
	AND n1.NI_STATUS <> 0
  AND F_CONFIRM_SLOW_MOVER(IM_STOCK) <= SYSDATE - 90;

    QueryTable VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE30,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode}';
    sCust_Rates RM.RM_XX_FEE30%TYPE;
    QueryTable2 VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_SPARE_CHAR_3,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode}';
    sCust_Rates2 RM.RM_SPARE_CHAR_3%TYPE;
    l_start number default dbms_utility.get_time;
  BEGIN

    nCheckpoint := 10;
    EXECUTE IMMEDIATE QueryTable INTO sCust_Rates USING sCustomerCode;
    EXECUTE IMMEDIATE QueryTable2 INTO sCust_Rates2 USING sCustomerCode;

    nCheckpoint := 1;
    v_query := 'TRUNCATE TABLE TMP_SLOW_STOR_FEES';
    EXECUTE IMMEDIATE v_query;
      --no longer truncating, just adding another type of the same charges

    IF To_Number(regexp_substr(sCust_Rates,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) != 0
      AND To_Number(regexp_substr(sCust_Rates2,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) != 0 THEN
    DBMS_OUTPUT.PUT_LINE('H2_EOM_SLOW_STOR_FEES Slow Pallet Storage Rates are $' || sCust_Rates || '.H2_EOM_SLOW_STOR_FEES Slow Shelf Storage Rates are $' || sCust_Rates2 || '. Prism rate fields are RM_XX_FEE30 & RM_SPARE_CHAR_3.');


    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;

        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_SLOW_STOR_FEES VALUES l_data(i);
        --USING sCust;

        EXIT WHEN c%NOTFOUND;

        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
      -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
      --END LOOP;
  v_query2 :=  SQL%ROWCOUNT;
  COMMIT;

      --IF v_query2 > 0 THEN

         If F_IS_TABLE_EEMPTY('TMP_SLOW_STOR_FEES') > 0 Then

          v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'H2_EOM_SLOW_STOR_FEES','IL','TMP_SLOW_STOR_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
          sFileName := sCustomerCode || '-H2_EOM_SLOW_STOR_FEES-' || startdate || '-TO-' || enddate || '-RunOn-' || sFileTime ||  '.csv';
          Z2_TMP_FEES_TO_CSV(sFileName,'TMP_SLOW_STOR_FEES');
          DBMS_OUTPUT.PUT_LINE('Z2_TMP_FEES_TO_CSV for ' || sFileName || '.' );
        --END IF;
        DBMS_OUTPUT.PUT_LINE('H2_EOM_SLOW_STOR_FEES for the date range '
        || startdate || ' -- ' || enddate || ' - ' || v_query2
        || ' records inserted into table TMP_SLOW_STOR_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
        || ' Seconds...for customer ' || sCustomerCode );
      Else
        DBMS_OUTPUT.PUT_LINE('H2_EOM_SLOW_STOR_FEES rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
        ' Seconds...for customer ' || sCustomerCode);
      END IF;
   Else
    DBMS_OUTPUT.PUT_LINE('H2_EOM_SLOW_STOR_FEES Rates are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);

   END IF;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('H2_EOM_SLOW_STOR_FEES fees processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;

  END H2_EOM_SLOW_STOR_FEES;

  /*   H3_EOM_SEC_STOR_FEES Run this once for each customer   */
  /*   This gets all the Std Storage Related Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_SEC_STOR_FEES   */
  /*   Prism Rate Field Used   */
  /*   A. RM_XX_FEE02   */
  PROCEDURE H3_EOM_SEC_STOR_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
      ,sAnalysis IN RM.RM_ANAL%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_SEC_STOR_FEES%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    v_time_taken VARCHAR2(205);
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
    --end_date2 ST.ST_DESP_DATE%TYPE := end_date;
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
	  NULL               AS "Pickslip",
    NULL               AS "DespNote",
    NULL  AS "DespDate",
    NULL AS "OrderDate",
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
        (SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS
			WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				(SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS
	    ELSE 0
	    END AS "UnitPrice",
		  CASE
			WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
        (SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS
			WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				(SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS
	    ELSE 0
	    END AS "OWUnitPrice",
			CASE
			WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
        (SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS
			WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				(SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS
	    ELSE 0
      END AS "DExcl",
			CASE
			WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
        (SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS
			WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				(SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS
	    ELSE 0
      END AS "Excl_Total",
		 CASE WHEN (l1.IL_NOTE_2 like 'Yes'  OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN
				((SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS )  * 1.1
			ELSE
				((SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS )  * 1.1
	    END AS "DIncl",
			 CASE WHEN (l1.IL_NOTE_2 like 'Yes'  OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN
				((SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS )  * 1.1
			ELSE
				((SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS )  * 1.1
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
           NULL AS PaymentType,NULL,NULL,NULL,NULL

	FROM NI n1 INNER JOIN IM ON IM_STOCK = n1.NI_STOCK
	INNER JOIN IL l1 ON l1.IL_LOCN = n1.NI_LOCN
  INNER JOIN Tmp_Locn_Cnt_By_Cust tmp ON tmp.SLOCN = l1.IL_LOCN
  --INNER JOIN RM R1 ON RM_CUST = IM_CUST
  LEFT JOIN Tmp_Group_Cust r ON r.sCust = IM_CUST
	WHERE  (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
	AND IM_ACTIVE = 1
  --AND IM_CUST = sCustomerCode
	AND n1.NI_AVAIL_ACTUAL >= '1'
	AND n1.NI_STATUS <> 0;

  --Palett Only
    CURSOR po
    IS
/* EOM Storage Fees */
	select IM_CUST AS "Customer",
	  IM_CUST AS "Parent",
	  IM_XX_COST_CENTRE01     AS "CostCentre",
	  NULL               AS "Order",
	  NULL               AS "OrderwareNum",
	  NULL               AS "CustomerRef",
	  NULL               AS "Pickslip",
    NULL               AS "DespNote",
    NULL  AS "DespDate",
    NULL AS "OrderDate",
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
        (SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS
			--WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				--r1.RM_XX_FEE12 / tmp.NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS
	    ELSE 0
	    END AS "UnitPrice",
		  CASE
			WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
        (SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS
			--WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				--r1.RM_XX_FEE12 / tmp.NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS
	    ELSE 0
	    END AS "OWUnitPrice",
			CASE
			WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
        (SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS
			--WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				--r1.RM_XX_FEE12 / tmp.NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS
	    ELSE 0
      END AS "DExcl",
			CASE
			WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
       (SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS
			--WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				--r1.RM_XX_FEE12 / tmp.NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS
	    ELSE 0
      END AS "Excl_Total",
		 CASE WHEN (l1.IL_NOTE_2 like 'Yes'  OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN
				((SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS )  * 1.1
			--ELSE
				--(r1.RM_XX_FEE12 / tmp.NCOUNTOFSTOCKS )  * 1.1
	    END AS "DIncl",
			 CASE WHEN (l1.IL_NOTE_2 like 'Yes'  OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN
				((SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS )  * 1.1
			--ELSE
				--(r1.RM_XX_FEE12 / tmp.NCOUNTOFSTOCKS )  * 1.1
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
           NULL AS PaymentType,NULL,NULL,NULL,NULL

	FROM NI n1 INNER JOIN IM ON IM_STOCK = n1.NI_STOCK
	INNER JOIN IL l1 ON l1.IL_LOCN = n1.NI_LOCN
  INNER JOIN Tmp_Locn_Cnt_By_Cust tmp ON tmp.SLOCN = l1.IL_LOCN
  --INNER JOIN RM R1 ON RM_CUST = IM_CUST
  LEFT JOIN Tmp_Group_Cust r ON r.sCust = IM_CUST
	WHERE  (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
	AND IM_ACTIVE = 1
  --AND IM_CUST = sCustomerCode
	AND n1.NI_AVAIL_ACTUAL >= '1'
	AND n1.NI_STATUS <> 0;


   --Shelf Only
    CURSOR so
    IS



/* EOM Storage Fees */
	select IM_CUST AS "Customer",
	  IM_CUST AS "Parent",
	  IM_XX_COST_CENTRE01     AS "CostCentre",
	  NULL               AS "Order",
	  NULL               AS "OrderwareNum",
	  NULL               AS "CustomerRef",
	  NULL               AS "Pickslip",
    NULL               AS "DespNote",
    NULL  AS "DespDate",
    NULL AS "OrderDate",
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
			--WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
        --r1.RM_XX_FEE11 / tmp.NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS
			WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				(SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS
	    ELSE 0
	    END AS "UnitPrice",
		  CASE
			----WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
        --r1.RM_XX_FEE11 / tmp.NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS
			WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				(SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS
	    ELSE 0
	    END AS "OWUnitPrice",
			CASE
			--WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
        --r1.RM_XX_FEE11 / tmp.NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS
			WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				(SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS
	    ELSE 0
      END AS "DExcl",
			CASE
			--WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes') THEN
        --r1.RM_XX_FEE11 / tmp.NCOUNTOFSTOCKS
				--SELECT To_Number(RM_XX_FEE11) FROM RM where RM_CUST = 'TABCORP' 	/ tmp.NCOUNTOFSTOCKS
			WHEN (l1.IL_NOTE_2 not like 'Yes' OR l1.IL_NOTE_2 NOT LIKE 'YES' OR l1.IL_NOTE_2 NOT LIKE 'yes') THEN
				(SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS
        --SELECT To_Number(RM_XX_FEE12) FROM RM where RM_CUST = 'TABCORP'  / tmp.NCOUNTOFSTOCKS
	    ELSE 0
      END AS "Excl_Total",
		 CASE
     WHEN (l1.IL_NOTE_2 like 'Yes'  OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN
				--(r1.RM_XX_FEE11 / tmp.NCOUNTOFSTOCKS )  * 1.1
			--ELSE
				((SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS )  * 1.1
	    END AS "DIncl",
			 CASE WHEN (l1.IL_NOTE_2 like 'Yes'  OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN
				--(r1.RM_XX_FEE11 / tmp.NCOUNTOFSTOCKS )  * 1.1
			--ELSE
				((SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) / tmp.NCOUNTOFSTOCKS )  * 1.1
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
           NULL AS PaymentType,NULL,NULL,NULL,NULL

	FROM NI n1 INNER JOIN IM ON IM_STOCK = n1.NI_STOCK
	INNER JOIN IL l1 ON l1.IL_LOCN = n1.NI_LOCN
  INNER JOIN Tmp_Locn_Cnt_By_Cust tmp ON tmp.SLOCN = l1.IL_LOCN
 --INNER JOIN RM R1 ON RM_CUST = IM_CUST
  LEFT JOIN Tmp_Group_Cust r ON r.sCust = IM_CUST
	WHERE  (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
	AND IM_ACTIVE = 1
  --AND IM_CUST = sCustomerCode
	AND n1.NI_AVAIL_ACTUAL >= '1'
	AND n1.NI_STATUS <> 0;

  QueryTable VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode}';
  sCust_Rates RM.RM_XX_FEE11%TYPE;
  QueryTable2 VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode}';
  sCust_Rates2 RM.RM_XX_FEE12%TYPE;
  l_start number default dbms_utility.get_time;
  BEGIN
  nCheckpoint := 10;
  EXECUTE IMMEDIATE QueryTable INTO sCust_Rates USING sCustomerCode;
  EXECUTE IMMEDIATE QueryTable2 INTO sCust_Rates2 USING sCustomerCode;
  nCheckpoint := 11;
  v_query := 'TRUNCATE TABLE TMP_SEC_STOR_FEES';
  EXECUTE IMMEDIATE v_query;
  --both
   IF To_Number(regexp_substr(sCust_Rates,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0
   AND To_Number(regexp_substr(sCust_Rates2,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0 THEN
   DBMS_OUTPUT.PUT_LINE('H3_EOM_SEC_STOR_FEES Secure Shelf Storage Rates  are $' || sCust_Rates2 || '.');


        nCheckpoint := 2;
            OPEN c;
            --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
            LOOP
            FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;

            FORALL i IN 1..l_data.COUNT
            --DBMS_OUTPUT.PUT_LINE(i || '.' );
            INSERT INTO TMP_SEC_STOR_FEES VALUES l_data(i);
            --USING sCust;

            EXIT WHEN c%NOTFOUND;

            END LOOP;
           -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            CLOSE c;
          -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
            --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          --END LOOP;
      v_query2 :=  SQL%ROWCOUNT;
      COMMIT;
      --RETURN;
      DBMS_OUTPUT.PUT_LINE('H3_EOM_SEC_STOR_FEES EOM Sec Storage Fees the date range '
      || startdate || ' -- ' || enddate || ' - ' || v_query2 || ' records inserted into table TMP_SEC_STOR_FEES in ' || (round((dbms_utility.get_time-l_start)/100, 6) ||
      ' Seconds...for customer ' || sCustomerCode ));
        --COMMIT;
  --palett
   ElsIf To_Number(regexp_substr(sCust_Rates,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0
   AND To_Number(regexp_substr(sCust_Rates2,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) = 0 THEN
   DBMS_OUTPUT.PUT_LINE('H3_EOM_SEC_STOR_FEES Secure Palett Storage Rates are $' || sCust_Rates || '.');


        nCheckpoint := 2;
            OPEN po;
            --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
            LOOP
            FETCH po BULK COLLECT INTO l_data LIMIT p_array_size;

            FORALL i IN 1..l_data.COUNT
            --DBMS_OUTPUT.PUT_LINE(i || '.' );
            INSERT INTO TMP_SEC_STOR_FEES VALUES l_data(i);
            --USING sCust;

            EXIT WHEN po%NOTFOUND;

            END LOOP;
           -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            CLOSE po;
          -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
            --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          --END LOOP;
      v_query2 :=  SQL%ROWCOUNT;
      COMMIT;
      --RETURN;
      DBMS_OUTPUT.PUT_LINE('H3_EOM_SEC_STOR_FEES EOM Sec Palett Storage Fees the date range '
          || startdate || ' -- ' || enddate || ' - ' || v_query2 || ' records inserted into table TMP_SEC_STOR_FEES in ' || (round((dbms_utility.get_time-l_start)/100, 6) ||
          ' Seconds...for customer ' || sCustomerCode ));
        --COMMIT;
    --shelf
    ElsIf To_Number(regexp_substr(sCust_Rates,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) = 0
    AND To_Number(regexp_substr(sCust_Rates2,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) > 0 THEN
    DBMS_OUTPUT.PUT_LINE('H3_EOM_SEC_STOR_FEES Secure Shelf Storage Rates  are $' || sCust_Rates2 || '.');



        nCheckpoint := 2;
            OPEN so;
            --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
            LOOP
            FETCH so BULK COLLECT INTO l_data LIMIT p_array_size;

            FORALL i IN 1..l_data.COUNT
            --DBMS_OUTPUT.PUT_LINE(i || '.' );
            INSERT INTO TMP_SEC_STOR_FEES VALUES l_data(i);
            --USING sCust;

            EXIT WHEN so%NOTFOUND;

            END LOOP;
           -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            CLOSE so;
          -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
            --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          --END LOOP;
      v_query2 :=  SQL%ROWCOUNT;
      COMMIT;

      IF v_query2 > 0 THEN
        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
        EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'H3_EOM_SEC_STOR_FEES','IL','TMP_SEC_STOR_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        DBMS_OUTPUT.PUT_LINE('H3_EOM_SEC_STOR_FEES for the date range '
        || startdate || ' -- ' || enddate || ' - ' || v_query2
        || ' records inserted into table TMP_SEC_STOR_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
        || ' Seconds...for customer ' || sCustomerCode );
      Else
        DBMS_OUTPUT.PUT_LINE('H3_EOM_SEC_STOR_FEES rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
        ' Seconds...for customer ' || sCustomerCode);
      END IF;
    Else
    DBMS_OUTPUT.PUT_LINE('H3_EOM_SEC_STOR_FEES are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);

   END IF;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('H3_EOM_SEC_STOR_FEES failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;

  END H3_EOM_SEC_STOR_FEES;

  /*   I_EOM_MISC_FEES Run this once for each customer   */
  /*   This gets all the Miscellaneous Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_MISC_FEES   */
  /*   Prism Rate Field Used   */
  /*   A. RM_XX_FEE02   */
  PROCEDURE I_EOM_MISC_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
      ,sAnalysis IN RM.RM_ANAL%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_MISC_FEES%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    v_time_taken VARCHAR2(205);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		nbreakpoint   NUMBER;
    nCountCustStocks NUMBER := 10;
    l_start number default dbms_utility.get_time;
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
			  NULL               AS "Pickslip",
    NULL               AS "DespNote",
    NULL  AS "DespDate",
    NULL AS "OrderDate",
	  CASE    WHEN RD_CUST IS NOT NULL THEN 'DB Maint fee '
			  ELSE ''
			  END                      AS "FeeType",
			  'DB Maint'               AS "Item",
			  'DB Maint fee '                AS "Description",
       TO_NUMBER( (SELECT Count(RD_CODE) FROM PWIN175.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN175.RM WHERE (RM_PARENT = sCustomerCode) AND SubStr(RD_CODE,0,2) NOT LIKE 'WH'  AND RD_CODE <> 'DIRECT')))  AS "Qty",
	  '1'           AS "UOI",
	   (SELECT To_Number(regexp_substr(RM_XX_FEE21,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)          AS "UnitPrice",
	   (SELECT To_Number(regexp_substr(RM_XX_FEE21,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)                    AS "OWUnitPrice",
	   (SELECT To_Number(regexp_substr(RM_XX_FEE21,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * (SELECT Count(RD_CODE) FROM PWIN175.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN175.RM WHERE (RM_PARENT = sCustomerCode) AND SubStr(RD_CODE,0,2) NOT LIKE 'WH'  AND RD_CODE <> 'DIRECT'))         AS "DExcl",
	   (SELECT To_Number(regexp_substr(RM_XX_FEE21,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * (SELECT Count(RD_CODE) FROM PWIN175.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN175.RM WHERE (RM_PARENT = sCustomerCode) AND SubStr(RD_CODE,0,2) NOT LIKE 'WH'  AND RD_CODE <> 'DIRECT'))      AS "Excl_Total",
		( (SELECT To_Number(regexp_substr(RM_XX_FEE21,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * (SELECT Count(RD_CODE) FROM PWIN175.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN175.RM WHERE (RM_PARENT = sCustomerCode) AND SubStr(RD_CODE,0,2) NOT LIKE 'WH'  AND RD_CODE <> 'DIRECT'))) * 1.1         AS "DIncl",
	  ( (SELECT To_Number(regexp_substr(RM_XX_FEE21,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * (SELECT Count(RD_CODE) FROM PWIN175.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN175.RM WHERE (RM_PARENT = sCustomerCode) AND SubStr(RD_CODE,0,2) NOT LIKE 'WH'  AND RD_CODE <> 'DIRECT'))) * 1.1        AS "Incl_Total",
		 (SELECT To_Number(regexp_substr(RM_XX_FEE21,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)                     AS "ReportingPrice",
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
           NULL AS PaymentType,NULL,NULL,NULL,NULL


	FROM  PWIN175.RM INNER JOIN RD  ON RD_CUST  = RM_CUST
	WHERE  (SELECT To_Number(regexp_substr(RM_XX_FEE21,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) > 0
	AND     (RM_PARENT = sCustomerCode OR RM_CUST = sCustomerCode)
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
			  NULL               AS "Pickslip",
    NULL               AS "DespNote",
    NULL  AS "DespDate",
    NULL AS "OrderDate",
	  CASE    WHEN RM_CUST IS NOT NULL THEN 'Stock Maint fee '
			  ELSE ''
			  END                      AS "FeeType",
			  'Stock Maint'               AS "Item",
			  'Stock Maint fee '                AS "Description",
        total_count_by_cust(sCustomerCode)  AS "Qty",
	  '1'           AS "UOI",
	   (SELECT To_Number(regexp_substr(RM_XX_FEE20,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)          AS "UnitPrice",
	  (SELECT To_Number(regexp_substr(RM_XX_FEE20,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)                    AS "OWUnitPrice",
	  (SELECT To_Number(regexp_substr(RM_XX_FEE20,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)  * total_count_by_cust(sCustomerCode)         AS "DExcl",
	  (SELECT To_Number(regexp_substr(RM_XX_FEE20,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)  * total_count_by_cust(sCustomerCode)      AS "Excl_Total",
		( (SELECT To_Number(regexp_substr(RM_XX_FEE20,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)  * total_count_by_cust(sCustomerCode)) * 1.1         AS "DIncl",
	  ( (SELECT To_Number(regexp_substr(RM_XX_FEE20,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)  * total_count_by_cust(sCustomerCode)) * 1.1        AS "Incl_Total",
		(SELECT To_Number(regexp_substr(RM_XX_FEE20,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)                     AS "ReportingPrice",
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
				total_count_by_cust(sCustomerCode) AS "CountOfStocks",
        NULL AS Email,
        'N/A' AS Brand,
           NULL AS    OwnedBy,
           NULL AS    sProfile,
           NULL AS    WaiveFee,
           NULL As   Cost,
           NULL AS PaymentType,NULL,NULL,NULL,NULL


	FROM  PWIN175.RM
	WHERE   (SELECT To_Number(regexp_substr(RM_XX_FEE20,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)  > 0
	AND     (RM_CUST = sCustomerCode)
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
			 NULL               AS "Pickslip",
    NULL               AS "DespNote",
    NULL  AS "DespDate",
    NULL AS "OrderDate",
	  CASE    WHEN RM_CUST IS NOT NULL THEN 'Admin fee '
			  ELSE ''
			  END                      AS "FeeType",
			  'Admin'                   AS "Item",
			  'Admin fee '                AS "Description",
       CASE    WHEN RM_CUST IS NOT NULL THEN 1
			  ELSE 0
			  END                      AS "Qty",
	   '1'           AS "UOI",
	      (SELECT To_Number(regexp_substr(RM_XX_FEE19,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)   AS "UnitPrice",
	  (SELECT To_Number(regexp_substr(RM_XX_FEE19,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)  AS "OWUnitPrice",
	   (SELECT To_Number(regexp_substr(RM_XX_FEE19,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)  AS "DExcl",
	   (SELECT To_Number(regexp_substr(RM_XX_FEE19,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)  AS "Excl_Total",
		( (SELECT To_Number(regexp_substr(RM_XX_FEE19,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)  * 1.1)         AS "DIncl",
	  ((SELECT To_Number(regexp_substr(RM_XX_FEE19,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * 1.1)        AS "Incl_Total",
		 (SELECT To_Number(regexp_substr(RM_XX_FEE19,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)                    AS "ReportingPrice",
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
           NULL AS PaymentType,NULL,NULL,NULL,NULL


	FROM  PWIN175.RM
	WHERE    (SELECT To_Number(regexp_substr(RM_XX_FEE19,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) > 0
	AND     RM_CUST = sCustomerCode
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
        --DBMS_OUTPUT.PUT_LINE(sCustomerCode || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;

        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_MISC_FEES VALUES l_data(i);
        --USING sCustomerCode;

        EXIT WHEN c%NOTFOUND;

        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
      -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
      --END LOOP;
  v_query2 :=  SQL%ROWCOUNT;
  COMMIT;

    IF v_query2 > 0 THEN
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'I_EOM_MISC_FEES','RM','TMP_MISC_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
      DBMS_OUTPUT.PUT_LINE('I_EOM_MISC_FEES for the date range '
      || startdate || ' -- ' || enddate || ' - ' || v_query2
      || ' records inserted into table TMP_MISC_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
      || ' Seconds...for customer ' || sCustomerCode );
    Else
      DBMS_OUTPUT.PUT_LINE('I_EOM_MISC_FEES rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('I_EOM_MISC_FEES failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;

  END I_EOM_MISC_FEES;

  /*   J_EOM_CUSTOMER_FEES Run this once for each customer   */
  /*   This gets all the Customer Specific Charges   */
  /*   Temp Tables Used   */
  /*   1. TMP_CUSTOMER_FEES   */
  /*   Prism Rate Field Used   */
  /*   A. RM_XX_FEE08 & RM_XX_FEE09   */
  PROCEDURE J_EOM_CUSTOMER_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_CUSTOMER_FEES%ROWTYPE;
    l_data ARRAY;
    v_time_taken VARCHAR2(205);
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
    l_start number default dbms_utility.get_time;


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
			  t.ST_PSLIP     AS "PickNum",
			  substr(To_Char(t.ST_DESP_DATE),0,10)               AS "DespatchNote",
			  substr(To_Char(s.SH_ADD_DATE),0,10)            AS "OrderDate",
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
	   CASE   WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN (SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) -- (Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode)
			 WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) -- (Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCustomerCode)
			 ELSE NULL
			 END                      AS "UnitPrice",
	   CASE   WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN (SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) --(Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode)
			 WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) -- (Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCustomerCode)
			 ELSE NULL
			 END                                          AS "OWUnitPrice",
			  CASE  WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN (SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP -- (Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode)  * d.SD_QTY_DESP
			 WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP --- (Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCustomerCode)  * d.SD_QTY_DESP
			 ELSE NULL
			 END                      AS "DExcl",
			  CASE   WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP --(Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode)
			 WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP -- (Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCustomerCode)
			 ELSE NULL
			 END                                          AS "Excl_Total",
		CASE WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1 -- ((Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1
			 WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1 --  ((Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1
			 ELSE NULL
			 END                      AS "DIncl",
		CASE WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN  ((SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1 -- ((Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1
			 WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1 -- ((Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1
			 ELSE NULL
			 END                      AS "Incl_Total",
	  CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN (Select i.IM_REPORTING_PRICE from IM i where i.IM_STOCK = d.SD_STOCK)
			  ELSE NULL
			  END                      AS "ReportingPrice",
			  REPLACE(s.SH_ADDRESS, ',')             AS "Address",
			  REPLACE(s.SH_SUBURB, ',')              AS "Address2",
			  REPLACE(s.SH_CITY, ',')                AS "Suburb",
			  s.SH_STATE               AS "State",
			  s.SH_POST_CODE           AS "Postcode",
			  REPLACE(s.SH_NOTE_1, ',')              AS "DeliverTo",
			  REPLACE(s.SH_NOTE_2, ',')              AS "AttentionTo" ,
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
            i.IM_OWNED_By,i.IM_PROFILE,
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
        d.SD_NOTE_1,d.SD_COST_PRICE,
        d.SD_XX_FREIGHT_CHG



	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER  AND t.ST_PICK = d.SD_LAST_PICK_NUM
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
        INNER JOIN RM ON RM_CUST = i.IM_CUST
	WHERE     Upper(i.IM_XX_QTY_PER_PACK) IN ('INNER','OUTER')
	AND       i.IM_CUST = sCustomerCode
	AND       s.SH_STATUS <> 3
	AND       s.SH_ORDER = t.ST_ORDER
	AND       t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate

  --AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
	GROUP BY  s.SH_CUST,
			  s.SH_SPARE_STR_4,
			  s.SH_ORDER,
			  t.ST_PICK,
			  d.SD_XX_PICKLIST_NUM,
			  t.ST_PSLIP,
			  t.ST_DESP_DATE,
			  i.IM_XX_QTY_PER_PACK,
			  d.SD_STOCK,
			  d.SD_DESC,
			  d.SD_LINE, i.IM_OWNED_By,i.IM_PROFILE,
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
        d.SD_NOTE_1,d.SD_COST_PRICE,
        d.SD_XX_FREIGHT_CHG,
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
			  s.SH_SPARE_DBL_9,s.SH_ADD_DATE,
			  d.SD_QTY_DESP,
			  r.sGroupCust,
			  i.IM_XX_COST_CENTRE01,
			  s.SH_SPARE_STR_5,
			  s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,i.IM_BRAND,s.SH_SPARE_INT_4,s.SH_CAMPAIGN

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
			  NULL            AS "DespatchDate",
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
			  REPLACE(s.SH_ADDRESS, ',')             AS "Address",
			  REPLACE(s.SH_SUBURB, ',')              AS "Address2",
			  REPLACE(s.SH_CITY, ',')                AS "Suburb",
			  s.SH_STATE               AS "State",
			  s.SH_POST_CODE           AS "Postcode",
			  REPLACE(s.SH_NOTE_1, ',')              AS "DeliverTo",
			  REPLACE(s.SH_NOTE_2, ',')              AS "AttentionTo" ,
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
           i.IM_OWNED_By,i.IM_PROFILE,
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
        d.SD_NOTE_1,d.SD_COST_PRICE,
        d.SD_XX_FREIGHT_CHG


	FROM      PWIN175.SH s
			  INNER JOIN PWIN175.SD d ON d.SD_ORDER  = s.SH_ORDER
			  INNER JOIN PWIN175.IM i ON i.IM_STOCK = d.SD_STOCK
			  INNER JOIN PWIN175.ST t ON t.ST_ORDER = s.SH_ORDER AND t.ST_PICK = s.SH_LAST_PICK_NUM
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
	WHERE     s.SH_ORDER = d.SD_ORDER
	AND       (d.SD_STOCK = 'EMERQSRFEE' AND s.SH_CAMPAIGN = 'TABSPEC')
	AND       s.SH_STATUS <> 3
  AND      (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
	--AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
	AND       t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate
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
			  d.SD_EXCL, i.IM_OWNED_By,i.IM_PROFILE,
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
        d.SD_NOTE_1,d.SD_COST_PRICE,
        d.SD_XX_FREIGHT_CHG,
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
              i.IM_BRAND,i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4,s.SH_CAMPAIGN

  UNION ALL
/*BB PackingFee*/
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
			  NULL,
        CASE    WHEN (i.IM_TYPE = 'BB_PACK' AND (d.SD_STOCK NOT like 'COURIER%' AND d.SD_STOCK NOT like 'FEE%'))  THEN 'Packing Fee'
        ELSE NULL
        END    AS "FeeType",
        d.SD_STOCK    AS "Item",
        d.SD_DESC     AS "Description",
        l.SL_PSLIP_QTY   AS "Qty",
        d.SD_QTY_UNIT    AS "UOI",
        CASE
        WHEN i.IM_TYPE = 'BB_PACK'   THEN (Select To_Number(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode)
        ELSE NULL
        END    AS "UnitPrice",
        CASE
        WHEN i.IM_TYPE = 'BB_PACK'   THEN (Select To_Number(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode)
        ELSE NULL
        END   AS "OWUnitPrice",
        CASE
        WHEN i.IM_TYPE = 'BB_PACK'  THEN ((Select To_Number(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode) * l.SL_PSLIP_QTY )
        ELSE NULL
        END     AS "DExcl",
        CASE
        WHEN i.IM_TYPE = 'BB_PACK'   THEN (Select To_Number(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode)
        ELSE NULL
        END      AS "Excl_Total",
        CASE
        WHEN i.IM_TYPE = 'BB_PACK'  THEN (Select To_Number(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode)   * 1.1
        ELSE NULL
        END      AS "DIncl",
        CASE
			  WHEN i.IM_TYPE = 'BB_PACK'  THEN (Select To_Number(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode)  * 1.1
        ELSE NULL
        END          AS "Incl_Total",
        CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN (Select To_Number(i.IM_REPORTING_PRICE) from IM i where i.IM_STOCK = d.SD_STOCK)
			  ELSE NULL
			  END    AS "ReportingPrice",
			  REPLACE(s.SH_ADDRESS, ',')             AS "Address",
			  REPLACE(s.SH_SUBURB, ',')              AS "Address2",
			  REPLACE(s.SH_CITY, ',')                AS "Suburb",
			  s.SH_STATE               AS "State",
			  s.SH_POST_CODE           AS "Postcode",
			  REPLACE(s.SH_NOTE_1, ',')              AS "DeliverTo",
			  REPLACE(s.SH_NOTE_2, ',')              AS "AttentionTo" ,
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
        s.SH_SPARE_INT_4 AS PaymentType,s.SH_CAMPAIGN,NULL,NULL,NULL


	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER  AND t.ST_PICK = d.SD_LAST_PICK_NUM
        LEFT JOIN PWIN175.SL l   ON l.SL_PICK   = t.ST_PICK

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
  AND     sCustomerCode = 'BEYONDBLUE'
 -- AND    nRM_XX_FEE08 > 0
  AND (SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) > 0.1
	AND       s.SH_STATUS <> 3
	AND       d.SD_STOCK NOT IN ('EMERQSRFEE','COURIER%','FEE%','FEE*','COURIER*','COURIER')
	AND       s.SH_ORDER = t.ST_ORDER
	--AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
	AND       t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate
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
        d.SD_LAST_PICK_NUM,i.IM_STOCK,r.sCust,s.SH_STATUS,s.SH_CAMPAIGN
 /* UNION ALL
 /*PhotoOrderFee*/
	/*SELECT
      s.SH_CUST AS "Customer",r.sGroupCust AS "Parent",s.SH_SPARE_STR_4 AS "CostCentre",
      s.SH_ORDER AS "Order",s.SH_SPARE_STR_5 AS "OrderwareNum",s.SH_CUST_REF AS "CustomerRef",
      NULL AS "Pickslip",NULL AS "PickNum",NULL AS "DespatchNote",substr(To_Char(t.ST_DESP_DATE),0,10) AS "DespatchDate",
      'OrderPhotoFee' AS "FeeType",'PHOTOFEEORDER' AS "Item",'Photo Fee' AS "Description",1 AS "Qty",'1' AS "UOI",
      (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = 'VHAAUS')  AS "UnitPrice",
      (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = 'VHAAUS')   AS "OWUnitPrice",
      (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = 'VHAAUS')   AS "DExcl",
      (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = 'VHAAUS')   AS "Excl_Total",
      (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = 'VHAAUS')   AS "DIncl",
      (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = 'VHAAUS')   AS "Incl_Total",
      NULL AS "ReportingPrice",
      REPLACE(s.SH_ADDRESS, ',') AS "Address",REPLACE(s.SH_SUBURB, ',') AS "Address2",REPLACE(s.SH_CITY, ',') AS "Suburb",s.SH_STATE AS "State",
      s.SH_POST_CODE AS "Postcode",REPLACE(s.SH_NOTE_1, ',') AS "DeliverTo",REPLACE(s.SH_NOTE_2, ',') AS "AttentionTo" ,0 AS "Weight",0 AS "Packages",
      s.SH_SPARE_DBL_9 AS "OrderSource",NULL AS "Pallet/Shelf Space",NULL AS "Locn",0 AS "CountOfStocks",
      CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
      ELSE ''
      END AS Email,
      'N/A' AS Brand,i.IM_OWNED_By AS OwnedBy,i.IM_PROFILE AS sProfile,NULL AS WaiveFee,d.SD_COST_PRICE As   Cost,s.SH_SPARE_INT_4 AS PaymentType
	FROM      PWIN175.SH s
			  INNER JOIN PWIN175.SD d ON d.SD_ORDER  = s.SH_ORDER
			  INNER JOIN PWIN175.IM i ON i.IM_STOCK = d.SD_STOCK
			  INNER JOIN PWIN175.ST t ON t.ST_ORDER = s.SH_ORDER AND t.ST_PICK = s.SH_LAST_PICK_NUM
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
			  --LEFT JOIN PWIN175.RM r2 ON r2.RM_ANAL = r.RM_ANAL AND r2.RM_CUST = :cust
	WHERE (r.sGroupCust = 'VHAAUS' OR r.sCust = 'VHAAUS')
  --AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
  AND       t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	AND       UPPER(s.SH_CUST_REF) = 'STORE EXPANSION'
	AND       d.SD_LINE = 1
  --AND sCustomerCode = 'VHAAUS'
	AND (SELECT To_Number(regexp_substr(RM_XX_FEE32_1,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = 'VHAAUS') > 0.1
	GROUP BY  s.SH_CUST,r.sGroupCust,i.IM_CUST,s.SH_SPARE_STR_4,i.IM_XX_COST_CENTRE01,i.IM_STOCK,
        s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,t.ST_DESP_DATE,s.SH_SPARE_DBL_9,d.SD_LINE,
        s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_NOTE_2,s.SH_SPARE_STR_3,
        i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4,s.SH_SPARE_STR_1,
        d.SD_ORDER,d.SD_STOCK,t.ST_ORDER,t.ST_PICK,s.SH_LAST_PICK_NUM,r.sCust,s.SH_PREV_PSLIP_NUM,i.IM_TYPE,s.SH_STATUS,
        i.IM_BRAND,t.ST_WEIGHT,t.ST_PACKAGES,d.SD_LAST_PICK_NUM
 ;
 SELECT
      s.SH_CUST AS "Customer",r.sGroupCust AS "Parent",s.SH_SPARE_STR_4 AS "CostCentre",
      s.SH_ORDER AS "Order",s.SH_SPARE_STR_5 AS "OrderwareNum",s.SH_CUST_REF AS "CustomerRef",
      NULL AS "Pickslip",NULL AS "PickNum",NULL AS "DespatchNote",substr(To_Char(t.ST_DESP_DATE),0,10) AS "DespatchDate",
      'OrderPhotoFee' AS "FeeType",'PHOTOFEEORDER' AS "Item",'Photo Fee' AS "Description",1 AS "Qty",'1' AS "UOI",
      (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = 'VHAAUS')  AS "UnitPrice",
      (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = 'VHAAUS')   AS "OWUnitPrice",
      (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = 'VHAAUS')   AS "DExcl",
      (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = 'VHAAUS')   AS "Excl_Total",
      (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = 'VHAAUS')   AS "DIncl",
      (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = 'VHAAUS')   AS "Incl_Total",
      NULL AS "ReportingPrice",
      REPLACE(s.SH_ADDRESS, ',') AS "Address",REPLACE(s.SH_SUBURB, ',') AS "Address2",REPLACE(s.SH_CITY, ',') AS "Suburb",s.SH_STATE AS "State",
      s.SH_POST_CODE AS "Postcode",REPLACE(s.SH_NOTE_1, ',') AS "DeliverTo",REPLACE(s.SH_NOTE_2, ',') AS "AttentionTo" ,0 AS "Weight",0 AS "Packages",
      s.SH_SPARE_DBL_9 AS "OrderSource",NULL AS "Pallet/Shelf Space",NULL AS "Locn",0 AS "CountOfStocks",
      CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
      ELSE ''
      END AS Email,
      'N/A' AS Brand,i.IM_OWNED_By AS OwnedBy,i.IM_PROFILE AS sProfile,NULL AS WaiveFee,d.SD_COST_PRICE As   Cost,s.SH_SPARE_INT_4 AS PaymentType
	FROM      PWIN175.SH s
			  INNER JOIN PWIN175.SD d ON d.SD_ORDER  = s.SH_ORDER
			  INNER JOIN PWIN175.IM i ON i.IM_STOCK = d.SD_STOCK
			  INNER JOIN PWIN175.ST t ON t.ST_ORDER = s.SH_ORDER AND t.ST_PICK = s.SH_LAST_PICK_NUM
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
			  --LEFT JOIN PWIN175.RM r2 ON r2.RM_ANAL = r.RM_ANAL AND r2.RM_CUST = :cust
	WHERE (r.sGroupCust = 'VHAAUS' OR r.sCust = 'VHAAUS')
  --AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
  AND       t.ST_DESP_DATE >= '01-Jun-2015' AND t.ST_DESP_DATE <= '30-Jun-2015'
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	AND       UPPER(s.SH_CUST_REF) = 'STORE EXPANSION'
	AND       d.SD_LINE = 1
  --AND sCustomerCode = 'VHAAUS'
	AND (SELECT To_Number(regexp_substr(RM_XX_FEE32_1,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = 'VHAAUS') > 0.1
	GROUP BY  s.SH_CUST,r.sGroupCust,i.IM_CUST,s.SH_SPARE_STR_4,i.IM_XX_COST_CENTRE01,i.IM_STOCK,
        s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,t.ST_DESP_DATE,s.SH_SPARE_DBL_9,d.SD_LINE,
        s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_NOTE_2,s.SH_SPARE_STR_3,
        i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4,s.SH_SPARE_STR_1,
        d.SD_ORDER,d.SD_STOCK,t.ST_ORDER,t.ST_PICK,s.SH_LAST_PICK_NUM,r.sCust,s.SH_PREV_PSLIP_NUM,i.IM_TYPE,s.SH_STATUS,
        i.IM_BRAND,t.ST_WEIGHT,t.ST_PACKAGES,d.SD_LAST_PICK_NUM*/
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
  v_query2 :=  SQL%ROWCOUNT;
  COMMIT;
  --RETURN;
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'J_EOM_CUSTOMER_FEES','RM','TMP_CUSTOMER_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
      DBMS_OUTPUT.PUT_LINE('J_EOM_CUSTOMER_FEES for the date range '
      || startdate || ' -- ' || enddate || ' - ' || v_query2 || ' records inserted in ' ||  (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('J_EOM_CUSTOMER_FEES failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;

  END J_EOM_CUSTOMER_FEES;

  /*   J Run this once for each Tabcorp   */
  /*   This gets Emergency Fees and Inner/Outer Packing Charges   */
  /*   Temp Tables Used   */
  /*   1. TMP_CUSTOMER_FEES   */
  /*   Prism Rate Field Used   */
  /*   A. RM_XX_FEE08 & RM_XX_FEE09   */
  PROCEDURE J_EOM_CUSTOMER_FEES_TAB (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_CUSTOMER_FEES%ROWTYPE;
    l_data ARRAY;
    v_time_taken VARCHAR2(205);
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
    l_start number default dbms_utility.get_time;

    CURSOR c

     IS
        /*Emergency Fee*/
	SELECT    s.SH_CUST                AS "Customer",
			  r.sGroupCust              AS "Parent",
			  i.IM_XX_COST_CENTRE01 AS "CostCentre",
			  s.SH_ORDER               AS "Order",
			  s.SH_SPARE_STR_5         AS "OrderwareNum",
			  s.SH_CUST_REF            AS "CustomerRef",
			  NULL                      AS "Pickslip",
			  NULL                    AS "PickNum",
			  NULL                    AS "DespatchNote",
			  To_Char(t.ST_DESP_DATE)            AS "DespatchDate",
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
			  REPLACE(s.SH_ADDRESS, ',')             AS "Address",
			  REPLACE(s.SH_SUBURB, ',')              AS "Address2",
			  REPLACE(s.SH_CITY, ',')                AS "Suburb",
			  s.SH_STATE               AS "State",
			  s.SH_POST_CODE           AS "Postcode",
			  REPLACE(s.SH_NOTE_1, ',')              AS "DeliverTo",
			  REPLACE(s.SH_NOTE_2, ',')              AS "AttentionTo" ,
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
           s.SH_SPARE_INT_4 AS PaymentType,s.SH_CAMPAIGN,NULL,NULL,NULL


	FROM      PWIN175.SH s
			  INNER JOIN PWIN175.SD d ON d.SD_ORDER  = s.SH_ORDER
			  INNER JOIN PWIN175.IM i ON i.IM_STOCK = d.SD_STOCK
			  INNER JOIN PWIN175.ST t ON t.ST_ORDER = s.SH_ORDER AND t.ST_PICK = s.SH_LAST_PICK_NUM
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
	WHERE     s.SH_ORDER = d.SD_ORDER
	AND       (d.SD_STOCK = 'EMERQSRFEE' AND s.SH_CAMPAIGN = 'TABSPEC')
	AND       s.SH_STATUS <> 3
  AND      (r.sGroupCust = 'TABCORP' OR r.sCust = 'TABCORP')
	--AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
	AND       t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate
  AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL --(SELECT Count(tt.ST_ORDER) FROM PWIN175.ST tt WHERE LTrim(tt.ST_ORDER) = LTrim(s.SH_ORDER)) = 1
	GROUP BY  s.SH_CUST,
			  s.SH_NOTE_1,
			  s.SH_CAMPAIGN,
			  s.SH_SPARE_STR_4,
			  s.SH_ORDER,
			  --t.ST_PICK,
			  --d.SD_XX_PICKLIST_NUM,
			  t.ST_DESP_DATE,
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
	   CASE   WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN (SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) -- (Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode)
			 WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) -- (Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCustomerCode)
			 ELSE NULL
			 END                      AS "UnitPrice",
	   CASE   WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN (SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) --(Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode)
			 WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) -- (Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCustomerCode)
			 ELSE NULL
			 END                                          AS "OWUnitPrice",
			  CASE  WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN (SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP -- (Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode)  * d.SD_QTY_DESP
			 WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP --- (Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCustomerCode)  * d.SD_QTY_DESP
			 ELSE NULL
			 END                      AS "DExcl",
			  CASE   WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP --(Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode)
			 WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP -- (Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCustomerCode)
			 ELSE NULL
			 END                                          AS "Excl_Total",
		CASE WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1 -- ((Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1
			 WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1 --  ((Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1
			 ELSE NULL
			 END                      AS "DIncl",
		CASE WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN  ((SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1 -- ((Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1
			 WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1 -- ((Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1
			 ELSE NULL
			 END                      AS "Incl_Total",
	  CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN (Select i.IM_REPORTING_PRICE from IM i where i.IM_STOCK = d.SD_STOCK)
			  ELSE NULL
			  END                      AS "ReportingPrice",
			  REPLACE(s.SH_ADDRESS, ',')             AS "Address",
			  REPLACE(s.SH_SUBURB, ',')              AS "Address2",
			  REPLACE(s.SH_CITY, ',')                AS "Suburb",
			  s.SH_STATE               AS "State",
			  s.SH_POST_CODE           AS "Postcode",
			  REPLACE(s.SH_NOTE_1, ',')              AS "DeliverTo",
			  REPLACE(s.SH_NOTE_2, ',')              AS "AttentionTo" ,
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
           s.SH_SPARE_INT_4 AS PaymentType,s.SH_CAMPAIGN,NULL,NULL,NULL
	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER  AND t.ST_PICK = d.SD_LAST_PICK_NUM
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
        INNER JOIN RM ON RM_CUST = i.IM_CUST
	WHERE     Upper(i.IM_XX_QTY_PER_PACK) IN ('INNER','OUTER')
	AND       i.IM_CUST = sCustomerCode
	AND       s.SH_STATUS <> 3
	AND       s.SH_ORDER = t.ST_ORDER
	AND       t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate
  GROUP BY  s.SH_CUST,s.SH_SPARE_STR_4,s.SH_ORDER,t.ST_PICK,d.SD_XX_PICKLIST_NUM,
			  t.ST_PSLIP,t.ST_DESP_DATE,i.IM_XX_QTY_PER_PACK,d.SD_STOCK,d.SD_DESC,
			  d.SD_LINE,d.SD_EXCL,d.SD_INCL,d.SD_SELL_PRICE,d.SD_XX_OW_UNIT_PRICE,
			  d.SD_QTY_ORDER,d.SD_QTY_ORDER,s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,
			  s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_NOTE_2,t.ST_WEIGHT,t.ST_PACKAGES,
			  s.SH_SPARE_DBL_9,d.SD_QTY_DESP,r.sGroupCust,i.IM_XX_COST_CENTRE01,
			  s.SH_SPARE_STR_5,s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,i.IM_BRAND,s.SH_SPARE_INT_4;

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
  v_query2 :=  SQL%ROWCOUNT;
  COMMIT;

   IF v_query2 > 0 THEN
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'J_EOM_CUSTOMER_FEES_TAB','RM','TMP_CUSTOMER_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
      DBMS_OUTPUT.PUT_LINE('J_EOM_CUSTOMER_FEES_TAB for the date range '
      || startdate || ' -- ' || enddate || ' - ' || v_query2
      || ' records inserted into table TMP_CUSTOMER_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
      || ' Seconds...for customer ' || sCustomerCode );
    Else
      DBMS_OUTPUT.PUT_LINE('J_EOM_CUSTOMER_FEES_TAB rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('J_EOM_CUSTOMER_FEES_TAB failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;

  END J_EOM_CUSTOMER_FEES_TAB;

  /*   J Run this once for BeyondBlue   */
  /*   This gets all the Customer Specific Charges   */
  /*   Temp Tables Used   */
  /*   1. TMP_CUSTOMER_FEES   */
  /*   Prism Rate Field Used   */
  /*   A. RM_XX_FEE08   */
  PROCEDURE J_EOM_CUSTOMER_FEES_BB (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_CUSTOMER_FEES%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    v_time_taken VARCHAR2(205);
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
    l_start number default dbms_utility.get_time;


    CURSOR c
    --(
      --start_date IN ST.ST_DESP_DATE%TYPE
    -- ,end_date IN ST.ST_DESP_DATE%TYPE
    --sCust IN RM.RM_CUST%TYPE
     --)
     IS


/*BB PackingFee */

SELECT    s.SH_CUST               AS "Customer",
			  r.sGroupCust              AS "Parent",
			  CASE    WHEN i.IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
			  WHEN i.IM_CUST = 'TABCORP' THEN i.IM_XX_COST_CENTRE01
			  ELSE s.SH_SPARE_STR_4
			  END                      AS "CostCentre",
			  s.SH_ORDER              AS "Order",
			  s.SH_SPARE_STR_5         AS "OrderwareNum",
			  s.SH_CUST_REF            AS "CustomerRef",
			  t.ST_PICK                AS "Pickslip",
			  t.ST_PSLIP     AS "DespatchNote",
			  substr(To_Char(t.ST_DESP_DATE),0,10)               AS "DespatchDate",
			  substr(To_Char(s.SH_ADD_DATE),0,10)            AS "OrdDate",
        CASE    WHEN (i.IM_TYPE = 'BB_PACK' AND (d.SD_STOCK NOT like 'COURIER%' AND d.SD_STOCK NOT like 'FEE%'))  THEN 'Packing Fee'
        ELSE NULL
        END    AS "FeeType",
        d.SD_STOCK    AS "Item",
        d.SD_DESC     AS "Description",
        l.SL_PSLIP_QTY   AS "Qty",
        d.SD_QTY_UNIT    AS "UOI",
        CASE
        WHEN i.IM_TYPE = 'BB_PACK'   THEN (Select To_Number(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode)
        ELSE NULL
        END    AS "UnitPrice",
        CASE
        WHEN i.IM_TYPE = 'BB_PACK'   THEN (Select To_Number(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode)
        ELSE NULL
        END   AS "OWUnitPrice",
        CASE
        WHEN i.IM_TYPE = 'BB_PACK'  THEN ((Select To_Number(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode) * l.SL_PSLIP_QTY )
        ELSE NULL
        END     AS "DExcl",
        CASE
        WHEN i.IM_TYPE = 'BB_PACK'   THEN (Select To_Number(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode)
        ELSE NULL
        END      AS "Excl_Total",
        CASE
        WHEN i.IM_TYPE = 'BB_PACK'  THEN (Select To_Number(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode)   * 1.1
        ELSE NULL
        END      AS "DIncl",
        CASE
			  WHEN i.IM_TYPE = 'BB_PACK'  THEN (Select To_Number(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode)  * 1.1
        ELSE NULL
        END          AS "Incl_Total",
        CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN (Select To_Number(i.IM_REPORTING_PRICE) from IM i where i.IM_STOCK = d.SD_STOCK)
			  ELSE NULL
			  END    AS "ReportingPrice",
			  REPLACE(s.SH_ADDRESS, ',')             AS "Address",
			  REPLACE(s.SH_SUBURB, ',')              AS "Address2",
			  REPLACE(s.SH_CITY, ',')                AS "Suburb",
			  s.SH_STATE               AS "State",
			  s.SH_POST_CODE           AS "Postcode",
			  REPLACE(s.SH_NOTE_1, ',')              AS "DeliverTo",
			  REPLACE(s.SH_NOTE_2, ',')              AS "AttentionTo" ,
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
         i.IM_OWNED_By,i.IM_PROFILE,
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
        d.SD_NOTE_1,d.SD_COST_PRICE,
        d.SD_XX_FREIGHT_CHG
   FROM      PWIN175.SD d
			  RIGHT JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  LEFT JOIN PWIN175.ST t  ON t.ST_PICK  = d.SD_LAST_PICK_NUM
        LEFT JOIN PWIN175.SL l   ON l.SL_PICK   = t.ST_PICK
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
        INNER JOIN PWIN175.NI n  ON n.NI_NV_EXT_KEY = l.SL_UID

    WHERE NI_NV_EXT_TYPE = 1810105 AND NI_STRENGTH = 3 AND NI_DATE = t.ST_DESP_DATE AND NI_STOCK = d.SD_STOCK AND NI_STATUS <> 0
        AND     s.SH_STATUS <> 3
        AND     i.IM_CUST  = 'BEYONDBLUE'
        AND       s.SH_ORDER = t.ST_ORDER
        AND       i.IM_TYPE = 'BB_PACK'
        AND        t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate
        AND       d.SD_LAST_PICK_NUM = t.ST_PICK
        AND (Select To_Number(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode) > 0.1

UNION ALL


 /*Pallet In Fee*/
	SELECT    IM_CUST                AS "Customer",
			  RM_PARENT              AS "Parent",
			  IM_XX_COST_CENTRE01       AS "CostCentre",
			  NI_QJ_NUMBER               AS "Order",
			  NULL         AS "OrderwareNum",
			  NULL            AS "CustomerRef",
			  NULL                AS "Pickslip",
			  NULL     AS "DespatchNote",
			  NULL               AS "DespatchDate",
			  substr(To_Char(NE_DATE),0,10)            AS "OrdDate",
	  CASE    WHEN NE_ENTRY IS NOT NULL THEN 'Pallet In Fee '
			  ELSE ''
			  END                      AS "FeeType",
			  IM_STOCK               AS "Item",
			  IM_DESC                AS "Description",
	      NE_QUANTITY          AS "Qty",
	      IM_LEVEL_UNIT          AS "UOI",
	  CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) -- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "UnitPrice",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) -- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "OWUnitPrice",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * NE_QUANTITY-- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "DExcl",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * NE_QUANTITY --  (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "Excl_Total",
		CASE    WHEN NE_ENTRY IS NOT NULL THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * NE_QUANTITY )* 1.1 --  (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust) * 1.1
			  ELSE NULL
			  END                      AS "DIncl",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * NE_QUANTITY )* 1.1-- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust) * 1.1
			  ELSE NULL
			  END                      AS "Incl_Total",
			  CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) -- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
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
           NULL AS PaymentType,NULL,NULL,NULL,NULL

	FROM      PWIN175.IM
			  INNER JOIN PWIN175.NA  ON NA_STOCK = IM_STOCK
			  INNER JOIN PWIN175.IL  ON IL_UID = NA_EXT_KEY
			  INNER JOIN PWIN175.NE  ON NE_ACCOUNT  = NA_ACCOUNT
			  INNER JOIN PWIN175.NI  ON NI_ENTRY = NE_ENTRY
			  INNER JOIN PWIN175.RM  ON RM_CUST  = IM_CUST
	WHERE  (SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) > 0
	AND     IM_CUST = sCustomerCode
	AND       NA_EXT_TYPE = 1210067
	AND       NE_TRAN_TYPE = 1
  AND     NE_NV_EXT_TYPE = 3010144
--	AND       IM_MAIN_SUPP <> 'BSPGA'
	AND       (NE_STATUS = 1 OR NE_STATUS = 3)
	--AND       TO_CHAR(NE_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(NE_DATE,'YYYY-MM-DD') <= end_date
	AND       Upper(IL_NOTE_2) = 'YES' AND IL_PHYSICAL = 1
  AND       NE_DATE >= startdate AND NE_DATE <= enddate ;

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
  v_query2 :=  SQL%ROWCOUNT;
  COMMIT;
  --RETURN;
  --DBMS_OUTPUT.PUT_LINE('J_EOM_CUSTOMER_FEES_BB for the date range '
    --  || startdate || ' -- ' || enddate || ' - ' || v_query2 || ' records inserted in ' ||  (round((dbms_utility.get_time-l_start)/100, 6)) ||
      --' Seconds...for customer ' || sCustomerCode);
  IF v_query2 > 0 THEN
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'J_EOM_CUSTOMER_FEES_BB','RM','TMP_CUSTOMER_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
      DBMS_OUTPUT.PUT_LINE('J_EOM_CUSTOMER_FEES_BB for the date range '
      || startdate || ' -- ' || enddate || ' - ' || v_query2
      || ' records inserted into table TMP_CUSTOMER_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
      || ' Seconds...for customer ' || sCustomerCode );
    Else
      DBMS_OUTPUT.PUT_LINE('J_EOM_CUSTOMER_FEES_BB rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('J_EOM_CUSTOMER_FEES_BB at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;

  END J_EOM_CUSTOMER_FEES_BB;

  /*   J Run this once for BeyondBlue   */
  /*   This gets all the Customer Specific Charges   */
  /*   Temp Tables Used   */
  /*   1. TMP_CUSTOMER_FEES   */
  /*   Prism Rate Field Used   */
  /*   A. RM_XX_FEE32_1   */
  PROCEDURE J_EOM_CUSTOMER_FEES_VHA (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_CUSTOMER_FEES%ROWTYPE;
    l_data ARRAY;
    v_time_taken VARCHAR2(205);
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
    l_start number default dbms_utility.get_time;


    CURSOR c
    --(
      --start_date IN ST.ST_DESP_DATE%TYPE
    -- ,end_date IN ST.ST_DESP_DATE%TYPE
    --sCust IN RM.RM_CUST%TYPE
     --)
     IS
  SELECT
      s.SH_CUST AS "Customer",r.sGroupCust AS "Parent",s.SH_SPARE_STR_4 AS "CostCentre",
      s.SH_ORDER AS "Order",s.SH_SPARE_STR_5 AS "OrderwareNum",s.SH_CUST_REF AS "CustomerRef",
      t.ST_PICK AS "Pickslip",t.ST_PSLIP AS "DespNum",substr(To_Char(t.ST_DESP_DATE),0,10) AS "DespatchDate",substr(To_Char(s.SH_ADD_DATE),0,10) AS "OrdDate",
      'StoreExpansionFee' AS "FeeType",'STREXPFEEORDER' AS "Item",'Store Expansion Fee' AS "Description",1 AS "Qty",'1' AS "UOI",
      (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = 'VHAAUS')  AS "UnitPrice",
      (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = 'VHAAUS')   AS "OWUnitPrice",
      (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = 'VHAAUS')   AS "DExcl",
      (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = 'VHAAUS')   AS "Excl_Total",
      (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = 'VHAAUS')   AS "DIncl",
      (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = 'VHAAUS')   AS "Incl_Total",
      NULL AS "ReportingPrice",
      REPLACE(s.SH_ADDRESS, ',') AS "Address",REPLACE(s.SH_SUBURB, ',') AS "Address2",REPLACE(s.SH_CITY, ',') AS "Suburb",s.SH_STATE AS "State",
      s.SH_POST_CODE AS "Postcode",REPLACE(s.SH_NOTE_1, ',') AS "DeliverTo",REPLACE(s.SH_NOTE_2, ',') AS "AttentionTo" ,0 AS "Weight",0 AS "Packages",
      s.SH_SPARE_DBL_9 AS "OrderSource",NULL AS "Pallet/Shelf Space",NULL AS "Locn",0 AS "CountOfStocks",
      CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
      ELSE ''
      END AS Email,
      'N/A' AS Brand, i.IM_OWNED_By,i.IM_PROFILE,
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
        d.SD_NOTE_1,d.SD_COST_PRICE,
        d.SD_XX_FREIGHT_CHG

	FROM      PWIN175.SH s
			  INNER JOIN PWIN175.SD d ON d.SD_ORDER  = s.SH_ORDER
			  INNER JOIN PWIN175.IM i ON i.IM_STOCK = d.SD_STOCK
			  INNER JOIN PWIN175.ST t ON t.ST_ORDER = s.SH_ORDER --AND t.ST_PICK = s.SH_LAST_PICK_NUM
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
			  --LEFT JOIN PWIN175.RM r2 ON r2.RM_ANAL = r.RM_ANAL AND r2.RM_CUST = :cust
	WHERE (r.sGroupCust = 'VHAAUS' OR r.sCust = 'VHAAUS')
  --AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
  AND       t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate
	AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	AND       UPPER(s.SH_CUST_REF) Like 'STORE EXPANSION%'
	AND       d.SD_LINE = 1
  AND t.ST_PSLIP != 'CANCELLED'
  --AND sCustomerCode = 'VHAAUS'
	AND (SELECT To_Number(regexp_substr(RM_XX_FEE32_1,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = 'VHAAUS') > 0.1
	GROUP BY  s.SH_CUST,r.sGroupCust,i.IM_CUST,s.SH_SPARE_STR_4,i.IM_XX_COST_CENTRE01,i.IM_STOCK,
        s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,t.ST_DESP_DATE,s.SH_SPARE_DBL_9,d.SD_LINE,
        s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_NOTE_2,s.SH_SPARE_STR_3,
        i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4,s.SH_SPARE_STR_1,s.SH_ADD_DATE,
        d.SD_ORDER,d.SD_STOCK,t.ST_ORDER,t.ST_PICK,s.SH_LAST_PICK_NUM,r.sCust,s.SH_PREV_PSLIP_NUM,i.IM_TYPE,s.SH_STATUS,
        i.IM_BRAND,t.ST_WEIGHT,t.ST_PACKAGES,d.SD_LAST_PICK_NUM,t.ST_PSLIP,s.SH_CAMPAIGN, i.IM_OWNED_By,i.IM_PROFILE,
        s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
        s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
        d.SD_NOTE_1,d.SD_COST_PRICE,
        d.SD_XX_FREIGHT_CHG
  ORDER BY t.ST_PICK
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
  v_query2 :=  SQL%ROWCOUNT;
  COMMIT;

  IF v_query2 > 0 THEN
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'J_EOM_CUSTOMER_FEES_VHA','RM','TMP_CUSTOMER_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
      DBMS_OUTPUT.PUT_LINE('J_EOM_CUSTOMER_FEES_VHA for the date range '
      || startdate || ' -- ' || enddate || ' - ' || v_query2
      || ' records inserted into table TMP_CUSTOMER_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
      || ' Seconds...for customer ' || sCustomerCode );
    Else
      DBMS_OUTPUT.PUT_LINE('J_EOM_CUSTOMER_FEES_VHA rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('J_EOM_CUSTOMER_FEES_VHA failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;

  END J_EOM_CUSTOMER_FEES_VHA;



  /*   K1_PAL_DESP_FEES Run this once for each customer   */
  /*   This gets all the Pallet Desp Charges   */
  /*   Temp Tables Used   */
  /*   1. TMP_PAL_DESP_FEES   */
  /*   Prism Rate Field Used   */
  /*   A. RM_XX_FEE17   */
  PROCEDURE K1_PAL_DESP_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2,
      sAnalysis IN RM.RM_ANAL%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_PAL_CTN_FEES%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    v_time_taken VARCHAR2(205);
    SQLQuery          VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
    l_start number default dbms_utility.get_time;


    CURSOR c

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
			  t.ST_PSLIP     AS "PickNum",
			  substr(To_Char(t.ST_DESP_DATE),0,10)               AS "DespatchNote",
			  substr(To_Char(s.SH_ADD_DATE),0,10)            AS "DespatchDate",
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
	  CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE17,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) -- (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = sCustomerCode)
			 ELSE NULL
			 END                      AS "UnitPrice",
	  CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE17,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) -- (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = sCustomerCode)
			 ELSE NULL
			 END                                           AS "OWUnitPrice",
	  CASE   WHEN t.ST_XX_NUM_PALLETS >= 1  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE17,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)* t.ST_XX_NUM_PALLETS -- (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = sCustomerCode)
			 ELSE NULL
			 END                        AS "DExcl",
	CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE17,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)* t.ST_XX_NUM_PALLETS -- (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = sCustomerCode)
			 ELSE NULL
			 END                                            AS "Excl_Total",
	  CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE17,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * t.ST_XX_NUM_PALLETS) * 1.1-- (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = sCustomerCode)  * 1.1
			 ELSE NULL
			 END                                           AS "DIncl",
	  CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE17,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * t.ST_XX_NUM_PALLETS) * 1.1-- (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = sCustomerCode)  * 1.1
			 ELSE NULL
			 END                                           AS "Incl_Total",
			  CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE17,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) -- (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = sCustomerCode)
			 ELSE NULL
			 END                                           AS "ReportingPrice",
			  REPLACE(s.SH_ADDRESS, ',')             AS "Address",
			  REPLACE(s.SH_SUBURB, ',')              AS "Address2",
			  REPLACE(s.SH_CITY, ',')                AS "Suburb",
			  s.SH_STATE               AS "State",
			  s.SH_POST_CODE           AS "Postcode",
			  REPLACE(s.SH_NOTE_1, ',')              AS "DeliverTo",
			  REPLACE(s.SH_NOTE_2, ',')              AS "AttentionTo" ,
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
           s.SH_SPARE_INT_4 AS PaymentType,s.SH_CAMPAIGN,NULL,NULL,NULL
	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
	WHERE (SELECT To_Number(regexp_substr(RM_XX_FEE17,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) > 0
	AND       s.SH_STATUS <> 3
	AND      (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
	AND       s.SH_ORDER = t.ST_ORDER
  AND       (ST_XX_NUM_PALLETS >= 1)
	AND       d.SD_LINE = 1
	AND       t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate;

    QueryTable VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE17,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode5}';
    sCust_Rates RM.RM_XX_FEE17%TYPE;
  BEGIN
    nCheckpoint := 10;
    EXECUTE IMMEDIATE QueryTable INTO sCust_Rates USING sCustomerCode;

    nCheckpoint := 11;
     v_query := 'TRUNCATE TABLE TMP_PAL_DESP_FEES';
      EXECUTE IMMEDIATE v_query;

    IF To_Number(regexp_substr(sCust_Rates,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) != 0 Then

      --DBMS_OUTPUT.PUT_LINE('K1_PAL_DESP_FEES rates are $' || sCust_Rates || '. Prism rate field is RM_XX_FEE17');

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

    v_query2 :=  SQL%ROWCOUNT;
  COMMIT;
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'K1_PAL_DESP_FEES','ST','TMP_PAL_CTN_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
      DBMS_OUTPUT.PUT_LINE('K1_PAL_DESP_FEES for the date range '
        || startdate || ' -- ' || enddate || ' - ' || v_query2
        || ' records inserted into table TMP_PAL_CTN_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
        || ' Seconds...for customer ' || sCustomerCode );
     Else
      DBMS_OUTPUT.PUT_LINE('K1_PAL_DESP_FEES rates are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;

    --COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('K_EOM_PAL_CTN_FEES Failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;

  END K1_PAL_DESP_FEES;

  /*   K2_CTN_IN_FEES Run this once for each customer   */
  /*   This gets all the Carton In Charges   */
  /*   Temp Tables Used   */
  /*   1. TMP_CTN_IN_FEES   */
  /*   Prism Rate Field Used   */
  /*   A. RM_XX_FEE13   */
  PROCEDURE K2_CTN_IN_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2,
      sAnalysis IN RM.RM_ANAL%TYPE
      -- sCust IN RM.RM_CUST%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_CTN_IN_FEES%ROWTYPE;
    l_data ARRAY;
    v_time_taken VARCHAR2(205);
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
    l_start number default dbms_utility.get_time;
    CURSOR c
     IS

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
	      1          AS "Qty",
	      IM_LEVEL_UNIT          AS "UOI",
	  CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr( RM_XX_FEE13,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) -- (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = sCustomerCode)
			  ELSE NULL
			  END                      AS "UnitPrice",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE13,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) --  (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = sCustomerCode)
			  ELSE NULL
			  END                      AS "OWUnitPrice",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE13,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * 1-- (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = sCustomerCode)
			  ELSE NULL
			  END                      AS "DExcl",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE13,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)* 1 --  (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = sCustomerCode)
			  ELSE NULL
			  END                      AS "Excl_Total",
		CASE    WHEN NE_ENTRY IS NOT NULL THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE13,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * 1 )* 1.1 --  (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = sCustomerCode) * 1.1
			  ELSE NULL
			  END                      AS "DIncl",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE13,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * 1 )* 1.1 -- (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = sCustomerCode) * 1.1
			  ELSE NULL
			  END                      AS "Incl_Total",
			  CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE13,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) -- (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = sCustomerCode)
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
           NULL AS PaymentType,NULL,NULL,NULL,NULL


	FROM      PWIN175.IM
			  INNER JOIN PWIN175.NA  ON NA_STOCK = IM_STOCK
			  INNER JOIN PWIN175.IL  ON IL_UID = NA_EXT_KEY
			  INNER JOIN PWIN175.NE  ON NE_ACCOUNT  = NA_ACCOUNT
			  INNER JOIN PWIN175.NI  ON NI_ENTRY = NE_ENTRY
			  INNER JOIN PWIN175.RM  ON RM_CUST  = IM_CUST
	WHERE (SELECT To_Number(regexp_substr(RM_XX_FEE13,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) > 0
	AND     IM_CUST = sCustomerCode
	AND       NA_EXT_TYPE = 1210067
	AND       NE_TRAN_TYPE = 1
  AND     NE_NV_EXT_TYPE = 3010144
--	AND       IM_MAIN_SUPP <> 'BSPGA'
	AND       (NE_STATUS = 1 OR NE_STATUS = 3)
	--AND       TO_CHAR(NE_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(NE_DATE,'YYYY-MM-DD') <= end_date
	AND       Upper(IL_NOTE_2) = 'No' AND IL_PHYSICAL = 1
  AND       NE_DATE >= startdate AND NE_DATE <= enddate;
    QueryTable VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE13,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode5}';
    sCust_Rates RM.RM_XX_FEE13%TYPE;
  BEGIN
    nCheckpoint := 10;
    EXECUTE IMMEDIATE QueryTable INTO sCust_Rates USING sCustomerCode;

     nCheckpoint := 11;
      v_query := 'TRUNCATE TABLE TMP_CTN_IN_FEES';
      EXECUTE IMMEDIATE v_query;

    IF To_Number(regexp_substr(sCust_Rates,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) != 0 Then

    --DBMS_OUTPUT.PUT_LINE('K2_CTN_IN_FEES rates are $' || sCust_Rates || '. Prism rate field is RM_XX_FEE13');

    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;

        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_CTN_IN_FEES VALUES l_data(i);
        --USING sCust;

        EXIT WHEN c%NOTFOUND;

        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
      -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
      --  DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
      --END LOOP;

    v_query2 :=  SQL%ROWCOUNT;
  COMMIT;
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'K2_CTN_IN_FEES','ST','TMP_CTN_IN_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
      DBMS_OUTPUT.PUT_LINE('K2_CTN_IN_FEES for the date range '
        || startdate || ' -- ' || enddate || ' - ' || v_query2
        || ' records inserted into table TMP_CTN_IN_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
        || ' Seconds...for customer ' || sCustomerCode );
     Else
      DBMS_OUTPUT.PUT_LINE('K2_CTN_IN_FEES rates are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('K2_CTN_IN_FEES Failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;

  END K2_CTN_IN_FEES;


  /*   K3_PAL_IN_FEES Run this once for each customer   */
  /*   This gets all the Pallet In Charges   */
  /*   Temp Tables Used   */
  /*   1. TMP_PAL_IN_FEES   */
  /*   Prism Rate Field Used   */
  /*   A. RM_XX_FEE14   */
  PROCEDURE K3_PAL_IN_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2,
      sAnalysis IN RM.RM_ANAL%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_PAL_IN_FEES%ROWTYPE;
    l_data ARRAY;
    v_time_taken VARCHAR2(205);
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
    l_start number default dbms_utility.get_time;
    CURSOR c
    IS
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
	      1          AS "Qty",
	      IM_LEVEL_UNIT          AS "UOI",
	  CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) -- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "UnitPrice",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) -- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "OWUnitPrice",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * 1-- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "DExcl",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * 1 --  (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
			  ELSE NULL
			  END                      AS "Excl_Total",
		CASE    WHEN NE_ENTRY IS NOT NULL THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * 1 )* 1.1 --  (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust) * 1.1
			  ELSE NULL
			  END                      AS "DIncl",
	   CASE    WHEN NE_ENTRY IS NOT NULL THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * 1 )* 1.1-- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust) * 1.1
			  ELSE NULL
			  END                      AS "Incl_Total",
			  CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) -- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
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
           NULL AS PaymentType,NULL,NULL,NULL,NULL

	FROM      PWIN175.IM
			  INNER JOIN PWIN175.NA  ON NA_STOCK = IM_STOCK
			  INNER JOIN PWIN175.IL  ON IL_UID = NA_EXT_KEY
			  INNER JOIN PWIN175.NE  ON NE_ACCOUNT  = NA_ACCOUNT
			  INNER JOIN PWIN175.NI  ON NI_ENTRY = NE_ENTRY
			  INNER JOIN PWIN175.RM  ON RM_CUST  = IM_CUST
	WHERE  (SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) > 0
	AND     IM_CUST = sCustomerCode
	AND       NA_EXT_TYPE = 1210067
	AND       NE_TRAN_TYPE = 1
  AND     NE_NV_EXT_TYPE = 3010144
--	AND       IM_MAIN_SUPP <> 'BSPGA'
	AND       (NE_STATUS = 1 OR NE_STATUS = 3)
	--AND       TO_CHAR(NE_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(NE_DATE,'YYYY-MM-DD') <= end_date
	AND       Upper(IL_NOTE_2) = 'YES' AND IL_PHYSICAL = 1
  AND       NE_DATE >= startdate AND NE_DATE <= enddate ;
    QueryTable VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode5}';
    sCust_Rates RM.RM_XX_FEE14%TYPE;
  BEGIN
    nCheckpoint := 10;
    EXECUTE IMMEDIATE QueryTable INTO sCust_Rates USING sCustomerCode;

    nCheckpoint := 11;
      v_query := 'TRUNCATE TABLE TMP_PAL_IN_FEES';
      EXECUTE IMMEDIATE v_query;

    IF To_Number(regexp_substr(sCust_Rates,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) != 0 Then

     -- DBMS_OUTPUT.PUT_LINE('K3_PAL_IN_FEES rates are $' || sCust_Rates || '. Prism rate field is RM_XX_FEE14.');

    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;

        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_PAL_IN_FEES VALUES l_data(i);
        --USING sCust;

        EXIT WHEN c%NOTFOUND;

        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
      -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
      --  DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
      --END LOOP;

    v_query2 :=  SQL%ROWCOUNT;
  COMMIT;
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'K3_PAL_IN_FEES','ST','TMP_PAL_IN_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
      DBMS_OUTPUT.PUT_LINE('K3_PAL_IN_FEES for the date range '
        || startdate || ' -- ' || enddate || ' - ' || v_query2
        || ' records inserted into table TMP_PAL_IN_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
        || ' Seconds...for customer ' || sCustomerCode );
     Else
      DBMS_OUTPUT.PUT_LINE('K3_PAL_IN_FEES rates are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('K3_PAL_IN_FEES Failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;

  END K3_PAL_IN_FEES;

  /*   K4_CTN_DESP_FEES Run this once for each customer   */
  /*   This gets all the Carton Despatch Charges   */
  /*   Temp Tables Used   */
  /*   1. TMP_CTN_DESP_FEES   */
  /*   Prism Rate Field Used   */
  /*   A. RM_XX_FEE15   */
  PROCEDURE K4_CTN_DESP_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
        ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2,
      sAnalysis IN RM.RM_ANAL%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_CTN_DESP_FEES%ROWTYPE;
    v_time_taken VARCHAR2(205);
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
    l_start number default dbms_utility.get_time;
    CURSOR c
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
			  t.ST_PSLIP     AS "PickNum",
			  substr(To_Char(t.ST_DESP_DATE),0,10)               AS "DespatchNote",
			  substr(To_Char(s.SH_ADD_DATE),0,10)            AS "DespatchDate",
	  CASE    WHEN t.ST_XX_NUM_CARTONS >= 1 THEN 'Carton Despatch Fee is '
			  ELSE ''
			  END                      AS "FeeType",
	  CASE    WHEN t.ST_XX_NUM_CARTONS >= 1 THEN  'Carton Despatch'
			  ELSE NULL
			  END                     AS "Item",
	  CASE    WHEN t.ST_XX_NUM_CARTONS >= 1 THEN  'Carton Despatch Fee'
			  ELSE NULL
			  END                     AS "Description",
	  CASE    WHEN t.ST_XX_NUM_CARTONS >= 1 THEN  t.ST_XX_NUM_CARTONS
			  ELSE NULL
			  END                     AS "Qty",
	  CASE    WHEN t.ST_XX_NUM_CARTONS >= 1 THEN  '1'
			  ELSE ''
			  END                     AS "UOI",
	  CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) --To_Number(f_get_fee('RM_XX_FEE15',sCust))-- f_get_fee('RM_XX_FEE15',sCust)
			 ELSE null
			 END                      AS "UnitPrice",
	  CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) --f_get_fee('RM_XX_FEE15',sCust) --To_Number(f_get_fee('RM_XX_FEE15',sCust))
    ELSE null
			 END                                           AS "OWUnitPrice",
	 CASE   WHEN t.ST_XX_NUM_CARTONS >= 1  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)* t.ST_XX_NUM_CARTONS --f_get_fee('RM_XX_FEE15',sCust) --To_Number(f_get_fee('RM_XX_FEE15',sCust))
   ELSE NULL
			 END                        AS "DExcl",
			  CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)* t.ST_XX_NUM_CARTONS --f_get_fee('RM_XX_FEE15',sCust) --To_Number(f_get_fee('RM_XX_FEE15',sCust))
        ELSE NULL
			 END                                            AS "Excl_Total",
	  CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)* t.ST_XX_NUM_CARTONS) * 1.1 --f_get_fee('RM_XX_FEE15',sCust) --To_Number(f_get_fee('RM_XX_FEE15',sCust))
    ELSE NULL
			 END                                           AS "DIncl",
	  CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * t.ST_XX_NUM_CARTONS) * 1.1--f_get_fee('RM_XX_FEE15',sCust) --f_get_fee('RM_XX_FEE15',sCust) --To_Number(f_get_fee('RM_XX_FEE15',sCust)) * 1.1
    ELSE NULL
			 END                                           AS "Incl_Total",
			  CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) --f_get_fee('RM_XX_FEE15',sCust) --To_Number(f_get_fee('RM_XX_FEE15',sCust))
        ELSE null
			 END                                           AS "ReportingPrice",
			  REPLACE(s.SH_ADDRESS, ',')             AS "Address",
			  REPLACE(s.SH_SUBURB, ',')              AS "Address2",
			  REPLACE(s.SH_CITY, ',')                AS "Suburb",
			  s.SH_STATE               AS "State",
			  s.SH_POST_CODE           AS "Postcode",
			  REPLACE(s.SH_NOTE_1, ',')              AS "DeliverTo",
			  REPLACE(s.SH_NOTE_2, ',')              AS "AttentionTo" ,
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
           s.SH_SPARE_INT_4 AS PaymentType,s.SH_CAMPAIGN,NULL,NULL,NULL
	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
	WHERE  --f_get_fee('RM_XX_FEE15',sCust) > 0
  --To_Number(f_get_fee('RM_XX_FEE15',sCust)) > 0
 (SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) > 0
	AND       s.SH_STATUS <> 3
	AND       (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
	AND       s.SH_ORDER = t.ST_ORDER
	AND       (ST_XX_NUM_CARTONS >= 1)
	AND       d.SD_LINE = 1

	--AND   TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date;
  AND       t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate;


  QueryTable VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode}';
  sCust_Rates RM.RM_XX_FEE15%TYPE;
  BEGIN
    nCheckpoint := 10;
    EXECUTE IMMEDIATE QueryTable INTO sCust_Rates USING sCustomerCode;

    nCheckpoint := 11;
      v_query := 'TRUNCATE TABLE TMP_CTN_DESP_FEES';
      EXECUTE IMMEDIATE v_query;

    IF To_Number(regexp_substr(sCust_Rates,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) != 0 THEN
   -- DBMS_OUTPUT.PUT_LINE('K4_CTN_DESP_FEES Rates are ' || sCust_Rates || '. Prism rate field is RM_XX_FEE15');




    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;

        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_CTN_DESP_FEES VALUES l_data(i);
        --USING sCust;

        EXIT WHEN c%NOTFOUND;

        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
      -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
      --END LOOP;

  COMMIT;
  v_query2 :=  SQL%ROWCOUNT;

    v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
    EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'K4_CTN_DESP_FEES','ST','TMP_CTN_DESP_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
    DBMS_OUTPUT.PUT_LINE('K4_CTN_DESP_FEES for the date range '
    || startdate || ' -- ' || enddate || ' - ' || v_query2
    || ' records inserted into table TMP_CTN_DESP_FEES in ' || (round((dbms_utility.get_time-l_start)/100, 6)
    || ' Seconds...for customer ' || sCustomerCode ));
  Else
      DBMS_OUTPUT.PUT_LINE('K4_CTN_DESP_FEES rates are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('K4_CTN_DESP_FEES Failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;

  END K4_CTN_DESP_FEES;

  /*   Y Run this once for each customer including intercompany   */
  /*   This merges all the Charges from each of the temp tables   */
  /*   Temp Tables Used   */
  /*   1. TMP_ALL_FEES   */
  PROCEDURE Y_EOM_TMP_MERGE_ALL_FEES (
   p_array_size IN PLS_INTEGER DEFAULT 100
   )
    IS
    TYPE ARRAY IS TABLE OF TMP_ALL_FEES_F%ROWTYPE;
    l_data ARRAY;
    v_time_taken VARCHAR2(205);
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
          --Select * From TMP_FREIGHT
          --UNION ALL
          --Select * From TMP_M_FREIGHT
          --UNION ALL
          --Select * From TMP_M_XX_FREIGHT
          --UNION ALL
          Select * From TMP_ALL_FREIGHT_F WHERE FEETYPE != 'UnPricedManualFreight'
          UNION ALL
          Select * From TMP_HANDLING_FEES
          UNION ALL
          Select * From TMP_PICK_FEES
          UNION ALL
          Select * From TMP_SHRINKWRAP_FEES
          UNION ALL
          Select * From TMP_STOCK_FEES
          UNION ALL
          Select * From TMP_PACKING_FEES
          UNION ALL
          Select * From TMP_MISC_FEES
          UNION ALL
          Select * From TMP_PHONE_ORD_FEES
          UNION ALL
          Select * From TMP_FAX_ORD_FEES
          UNION ALL
          Select * From TMP_MAN_ORD_FEES
          UNION ALL
          Select * From TMP_DESTROY_ORD_FEES
          UNION ALL
          Select * From TMP_EMAIL_ORD_FEES
          UNION ALL
          Select * From TMP_PAL_DESP_FEES
          UNION ALL
          Select * From TMP_PAL_IN_FEES
          UNION ALL
          Select * From TMP_CTN_IN_FEES
          UNION ALL
          Select * From TMP_CTN_DESP_FEES
          UNION ALL
          Select * From TMP_STOR_FEES WHERE FEETYPE != 'UNKNOWN'
          --UNION ALL
          --Select * From TMP_SLOW_STOR_FEES
          --UNION ALL
          --Select * From TMP_SEC_STOR_FEES

              ;



    BEGIN

    nCheckpoint := 1;
      v_query := 'TRUNCATE TABLE TMP_ALL_FEES_F';
      EXECUTE IMMEDIATE v_query;

    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;

        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_ALL_FEES_F VALUES l_data(i);
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
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,sysdate,sysdate,'Y_EOM_TMP_MERGE_ALL_FEES','TMP','TMP_ALL_FEES_F',v_time_taken,SYSTIMESTAMP,NULL);

  DBMS_OUTPUT.PUT_LINE('Y_EOM_TMP_MERGE_ALL_FEES and dump data in ' ||  (round((dbms_utility.get_time-l_start)/100, 6) ||
      ' Seconds...' ));

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Y_EOM_TMP_MERGE_ALL_FEES failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;

  END Y_EOM_TMP_MERGE_ALL_FEES;

  /*   Y Run this once for each customer including intercompany   */
  /*   This merges all the Charges from each of the temp tables   */
  /*   Temp Tables Used   */
  /*   1. TMP_ALL_FEES   */
  PROCEDURE Y_EOM_MERGE_ALL_FREIGHT (
   p_array_size IN PLS_INTEGER DEFAULT 100
   )
    IS
    TYPE ARRAY IS TABLE OF TMP_ALL_FREIGHT_F%ROWTYPE;
    l_data ARRAY;
    v_time_taken VARCHAR2(205);
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
          Select * From TMP_M_FREIGHT
          UNION ALL
          Select * From TMP_M_XX_FREIGHT
          UNION ALL
          Select * From TMP_V_FREIGHT;


    BEGIN

    nCheckpoint := 1;
      v_query := 'TRUNCATE TABLE TMP_ALL_FREIGHT_F';
      EXECUTE IMMEDIATE v_query;

    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;

        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_ALL_FREIGHT_F VALUES l_data(i);
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
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,sysdate,sysdate,'Y_EOM_MERGE_ALL_FREIGHT','TMP FREIGHT','TMP_ALL_FREIGHT_F',v_time_taken,SYSTIMESTAMP,NULL);

  DBMS_OUTPUT.PUT_LINE('Y_EOM_MERGE_ALL_FREIGHT and dump data in ' ||  (round((dbms_utility.get_time-l_start)/100, 6) ||
      ' Seconds...' ));

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Y_EOM_MERGE_ALL_FREIGHT failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;

  END Y_EOM_MERGE_ALL_FREIGHT;

  /*   Z Run this once for each customer including intercompany   */
  /*   This just runs all the above procedures from a single source   */
  /*   No Specific Temp Tables Used
       Tables used:
       TMP_ALL_FEES
       Tmp_Group_Cust


  */
  PROCEDURE Z_EOM_RUN_ALL (
      p_array_size_start IN PLS_INTEGER DEFAULT 100
      ,start_date IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,end_date IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCust_start IN VARCHAR2
      ,sAnalysis_Start IN RM.RM_ANAL%TYPE
  )
  AS
    nCheckpoint  NUMBER;
    sFileName VARCHAR2(560);
    v_time_taken VARCHAR2(205);
    l_start number default dbms_utility.get_time;
    v_query2 VARCHAR2(32767);
    tst_pick_counts tst_tmp_Admin_Data_Pick_Counts;
    sFileSuffix VARCHAR2(60):= '.csv';
    sFileTime VARCHAR2(56)  := TO_CHAR(SYSDATE,'YYYYMMDD HH24MISS');
    sPath VARCHAR2(60) :=  'EOM_ADMIN_ORDERS';
    v_query           VARCHAR2(2000);
    v_query_result VARCHAR2(22);
    v_query_result2 VARCHAR2(22);
     vRtnVal VARCHAR2(40);
     v_tmp_date VARCHAR2(12) := TO_DATE(end_date, 'DD-MON-YY');
  BEGIN
    nCheckpoint := 1;
      v_query  := 'TRUNCATE TABLE "PWIN175"."TMP_ALL_FEES"';
      EXECUTE IMMEDIATE v_query;

    sFileName := sCust_start || '-EOM-ADMIN-ORACLE-' || start_date || '-TO-' || end_date || '-RunOn-' || sFileTime || sFileSuffix;

    nCheckpoint := 2;
      v_query  := 'TRUNCATE TABLE Tmp_Group_Cust';
      EXECUTE IMMEDIATE v_query;
      --Select (F_EOM_CHECK_LOG(v_tmp_date ,'Tmp_Group_Cust','A_EOM_GROUP_CUST')) INTO v_query_result From Dual;--v_query := q'{Select EOM_REPORT_PKG_TEST.EOM_CHECK_LOG(TO_CHAR(end_date,'DD-MON-YY') ,'TMP_ALL_FREIGHT_ALL','F_EOM_TMP_ALL_FREIGHT_ALL') }';--q'{INSERT INTO TMP_EOM_LOGS VALUES (SYSTIMESTAMP ,:startdate,:enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','NONE','TMP_ALL_FREIGHT_ALL',:v_time_taken,SYSTIMESTAMP )  }';
      --If UPPER(v_query_result) != UPPER(v_tmp_date) Then
      If F_IS_TABLE_EEMPTY('Tmp_Group_Cust') <= 0 Then
        DBMS_OUTPUT.PUT_LINE('1st Need to run Tmp_Group_Cust for all customers as table is empty.' );
        EOM_REPORT_PKG_TEST.A_EOM_GROUP_CUST();
      Else
        DBMS_OUTPUT.PUT_LINE('1st No Need to run Tmp_Group_Cust for all customers as table is full of data - saved another 5 seconds.' );
      End If;

    nCheckpoint := 3;
      --v_query := q'{SELECT TO_CHAR(LAST_ANALYZED, 'DD-MON-YY') FROM DBA_TABLES WHERE TABLE_NAME = 'TMP_ADMIN_DATA_PICK_LINECOUNTS'}';
      --EXECUTE IMMEDIATE v_query INTO vRtnVal;-- USING sCustomerCode;
      --If F_IS_TABLE_EEMPTY('TMP_ADMIN_DATA_PICK_LINECOUNTS') <= 0 Then
      Select (F_EOM_CHECK_LOG(v_tmp_date ,'TMP_ADMIN_DATA_PICK_LINECOUNTS','B_EOM_START_RUN_ONCE_DATA')) INTO v_query_result From Dual;--v_query := q'{Select EOM_REPORT_PKG_TEST.EOM_CHECK_LOG(TO_CHAR(end_date,'DD-MON-YY') ,'TMP_ALL_FREIGHT_ALL','F_EOM_TMP_ALL_FREIGHT_ALL') }';--q'{INSERT INTO TMP_EOM_LOGS VALUES (SYSTIMESTAMP ,:startdate,:enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','NONE','TMP_ALL_FREIGHT_ALL',:v_time_taken,SYSTIMESTAMP )  }';
      If UPPER(v_query_result) != UPPER(v_tmp_date) Then
      -- If vRtnVal != TO_CHAR(SYSDATE, 'DD-MON-YY') Then
       DBMS_OUTPUT.PUT_LINE('2nd Need to RUN_ONCE TMP_ADMIN_DATA_PICK_LINECOUNTS as B_EOM_START_RUN_ONCE_DATA for all customers as table is empty. result was ' || UPPER(v_query_result) || ' and end date was ' ||  UPPER(v_tmp_date) );
       EOM_REPORT_PKG_TEST.B_EOM_START_RUN_ONCE_DATA(start_date,end_date,sAnalysis_Start,sCust_start,0);
      Else
        DBMS_OUTPUT.PUT_LINE('2nd No Need to RUN_ONCE TMP_ADMIN_DATA_PICK_LINECOUNTS as B_EOM_START_RUN_ONCE_DATA for all customers as table is full of data - saved another 45 seconds. Last Date match was ' || UPPER(v_query_result) || ' and end date was ' ||  UPPER(v_tmp_date) );
      End If;

    nCheckpoint := 4;
    --set timing on; Tmp_Locn_Cnt_By_Cust
    If F_IS_TABLE_EEMPTY('Tmp_Locn_Cnt_By_Cust') <= 0 Then
   -- Select (F_EOM_CHECK_LOG(v_tmp_date ,'Tmp_Locn_Cnt_By_Cust','C_EOM_START_ALL_TEMP_STOR_DATA')) INTO v_query_result From Dual;--v_query := q'{Select EOM_REPORT_PKG_TEST.EOM_CHECK_LOG(TO_CHAR(end_date,'DD-MON-YY') ,'TMP_ALL_FREIGHT_ALL','F_EOM_TMP_ALL_FREIGHT_ALL') }';--q'{INSERT INTO TMP_EOM_LOGS VALUES (SYSTIMESTAMP ,:startdate,:enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','NONE','TMP_ALL_FREIGHT_ALL',:v_time_taken,SYSTIMESTAMP )  }';
    --If UPPER(v_query_result) != UPPER(v_tmp_date) OR F_IS_TABLE_EEMPTY('Tmp_Locn_Cnt_By_Cust') <= 0 Then
       DBMS_OUTPUT.PUT_LINE('3rd Need to RUN_ONCE Tmp_Locn_Cnt_By_Cust as C_EOM_START_ALL_TEMP_STOR_DATA for all customers as table is empty.result was ' || UPPER(v_query_result) || ' and end date was ' ||  UPPER(v_tmp_date) );
     --EOM_REPORT_PKG_TEST.C_EOM_START_CUST_TEMP_DATA(sAnalysis_Start,sCust_start);
     EOM_REPORT_PKG_TEST.C_EOM_START_ALL_TEMP_STOR_DATA(sAnalysis_Start,sCust_start);
    Else
      DBMS_OUTPUT.PUT_LINE('3rd No Need to RUN_ONCE Tmp_Locn_Cnt_By_Cust as C_EOM_START_ALL_TEMP_STOR_DATA for all customers as table is full of data - saved another 65 seconds. Last Date match was ' || UPPER(v_query_result) || ' and end date was ' ||  UPPER(v_tmp_date) );
    End If;

    nCheckpoint := 45;
      DBMS_OUTPUT.PUT_LINE('4th EOM Customer Rates are caluclated on the fly...' );

    nCheckpoint := 5;
      --DBMS_OUTPUT.PUT_LINE('5th EOM freight table checking last date...' || v_tmp_date );
      Select (F_EOM_CHECK_LOG(v_tmp_date ,'TMP_ALL_FREIGHT_ALL','F_EOM_TMP_ALL_FREIGHT_ALL')) INTO v_query_result From Dual;--v_query := q'{Select EOM_REPORT_PKG_TEST.EOM_CHECK_LOG(TO_CHAR(end_date,'DD-MON-YY') ,'TMP_ALL_FREIGHT_ALL','F_EOM_TMP_ALL_FREIGHT_ALL') }';--q'{INSERT INTO TMP_EOM_LOGS VALUES (SYSTIMESTAMP ,:startdate,:enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','NONE','TMP_ALL_FREIGHT_ALL',:v_time_taken,SYSTIMESTAMP )  }';
      Select (F_EOM_CHECK_CUST_LOG(sCust_start ,'TMP_ALL_FREIGHT_F','F8_Z_EOM_RUN_FREIGHT')) INTO v_query_result2 From Dual;--v_query := q'{Select EOM_REPORT_PKG_TEST.EOM_CHECK_LOG(TO_CHAR(end_date,'DD-MON-YY') ,'TMP_ALL_FREIGHT_ALL','F_EOM_TMP_ALL_FREIGHT_ALL') }';--q'{INSERT INTO TMP_EOM_LOGS VALUES (SYSTIMESTAMP ,:startdate,:enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','NONE','TMP_ALL_FREIGHT_ALL',:v_time_taken,SYSTIMESTAMP )  }';
      If UPPER(v_query_result) != UPPER(v_tmp_date)
      AND UPPER(v_query_result) IS NOT NULL
      AND UPPER(v_query_result2) != UPPER(sCust_start)
      Then
        DBMS_OUTPUT.PUT_LINE(''
          || 'this suggests that BOTH the bulk freight data AND the customer freight data is NOT fresh - re run both!!!'
          || ' 5th Need to RUN_ONCE F_EOM_TMP_ALL_FREIGHT_ALL & F8_Z_EOM_RUN_FREIGHT for all customers as table is not empty.'
          || ' Last Cust match was ' ||  UPPER(v_query_result2)
          || ' and this cust was ' ||  UPPER(sCust_start)
          || ' and to date was ' ||  UPPER(v_query_result)
          || ' and this date was ' ||  UPPER(v_tmp_date)
          );
        EOM_REPORT_PKG_TEST.F_EOM_TMP_ALL_FREIGHT_ALL(p_array_size_start,start_date,end_date);
        EOM_REPORT_PKG_TEST.F8_Z_EOM_RUN_FREIGHT(p_array_size_start,start_date,end_date,sCust_start);
      ELSIF  UPPER(v_query_result2) = UPPER(sCust_start)
        AND UPPER(v_query_result) IS NOT NULL
        AND UPPER(v_query_result) = UPPER(v_tmp_date)
        Then
          --this suggests that BOTH the bulk storage data AND the customer storage data is fresh - STOP
          DBMS_OUTPUT.PUT_LINE(''
          || 'this suggests that BOTH the bulk freight data AND the customer freight data is fresh - STOP!!!'
          || ' 5th No Need to RUN_ONCE F_EOM_TMP_ALL_FREIGHT_ALL & F8_Z_EOM_RUN_FREIGHT for all customers as table is not empty.'
          || ' Last Cust match was ' ||  UPPER(v_query_result2)
          || ' and this cust was ' ||  UPPER(sCust_start)
          || ' and to date was ' ||  UPPER(v_query_result)
          || ' and this date was ' ||  UPPER(v_tmp_date)
          );
        ELSIf UPPER(v_query_result) != UPPER(v_tmp_date)
        AND UPPER(v_query_result) IS NOT NULL
        --AND UPPER(v_query_result2) != UPPER(sCuststart)
        Then
          --this suggests that the bulk storage data is NOT fresh BUT the customer storage data is fresh - re run both
          DBMS_OUTPUT.PUT_LINE(''
          || 'this suggests that the bulk freight data is NOT fresh BUT the customer freight data is fresh - re run both!!!'
          || ' 5th Need to RUN_ONCE F_EOM_TMP_ALL_FREIGHT_ALL & F8_Z_EOM_RUN_FREIGHT for all customers as table is from different dates and different customer.'
          || ' Last Cust match was ' ||  UPPER(v_query_result)
          || ' and this cust was ' ||  UPPER(sCust_start)
          || ' and to date was ' ||  UPPER(v_query_result2)
          || ' and this date was ' ||  UPPER(v_tmp_date)
          );
          EOM_REPORT_PKG_TEST.F_EOM_TMP_ALL_FREIGHT_ALL(p_array_size_start,start_date,end_date);
          EOM_REPORT_PKG_TEST.F8_Z_EOM_RUN_FREIGHT(p_array_size_start,start_date,end_date,sCust_start);
        ELSIf UPPER(v_query_result) = UPPER(v_tmp_date)
        AND UPPER(v_query_result) IS NOT NULL
        AND UPPER(v_query_result2) != UPPER(sCust_start)
        Then
          --this suggests that the bulk storage data is fresh BUT the customer storage data is NOT fresh - re run just cust data
          DBMS_OUTPUT.PUT_LINE(''
          || 'this suggests that the bulk freight data is fresh BUT the customer freight data is NOT fresh - re run just cust data!!!'
          || '6th Need to RUN_ONCE F8_Z_EOM_RUN_FREIGHT for customer ' || UPPER(sCust_start) || ' as table data is for a different customer.'
          || ' Last Cust match was ' ||  UPPER(v_query_result2)
          || ' and this cust was ' ||  UPPER(sCust_start)
          || ' and to date was ' ||  UPPER(v_query_result)
          || ' and this date was ' ||  UPPER(v_tmp_date)
          );
          --EOM_REPORT_PKG_TEST.F_EOM_TMP_ALL_FREIGHT_ALL(p_array_size_start,start_date,end_date);
          EOM_REPORT_PKG_TEST.F8_Z_EOM_RUN_FREIGHT(p_array_size_start,start_date,end_date,sCust_start);
        Else
          DBMS_OUTPUT.PUT_LINE('5th No matches for running F_EOM_TMP_ALL_FREIGHT_ALL & F8_Z_EOM_RUN_FREIGHT,'
          || 'still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) || 'Seconds...'
          || ' for customer ' || sCust_start);
        End If;

      nCheckpoint := 6;
        Select (F_EOM_CHECK_LOG(v_tmp_date ,'TMP_STOR_ALL_FEES','H4_EOM_ALL_STOR_FEES')) INTO v_query_result From Dual;--v_query := q'{Select EOM_REPORT_PKG_TEST.EOM_CHECK_LOG(TO_CHAR(end_date,'DD-MON-YY') ,'TMP_ALL_FREIGHT_ALL','F_EOM_TMP_ALL_FREIGHT_ALL') }';--q'{INSERT INTO TMP_EOM_LOGS VALUES (SYSTIMESTAMP ,:startdate,:enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','NONE','TMP_ALL_FREIGHT_ALL',:v_time_taken,SYSTIMESTAMP )  }';
        Select (F_EOM_CHECK_CUST_LOG(sCust_start ,'TMP_STOR_FEES','H4_EOM_ALL_STORS')) INTO v_query_result2 From Dual;--v_query := q'{Select EOM_REPORT_PKG_TEST.EOM_CHECK_LOG(TO_CHAR(end_date,'DD-MON-YY') ,'TMP_ALL_FREIGHT_ALL','F_EOM_TMP_ALL_FREIGHT_ALL') }';--q'{INSERT INTO TMP_EOM_LOGS VALUES (SYSTIMESTAMP ,:startdate,:enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','NONE','TMP_ALL_FREIGHT_ALL',:v_time_taken,SYSTIMESTAMP )  }';
        If UPPER(v_query_result) != UPPER(v_tmp_date)
        AND UPPER(v_query_result) IS NOT NULL
        AND UPPER(v_query_result2) != UPPER(sCust_start)
        Then
          --this suggests that BOTH the bulk storage data AND the customer storage data is NOT fresh - re run both
          DBMS_OUTPUT.PUT_LINE(''
          || 'this suggests that BOTH the bulk storage data AND the customer storage data is NOT fresh - re run both!!!'
          || ' 6th Need to RUN_ONCE H4_EOM_ALL_STOR_FEES & H4_EOM_ALL_STOR for all customers as table is not empty. Last Cust match was ' ||  UPPER(v_query_result)
          || ' and this cust was ' ||  UPPER(sCust_start)
          || ' and to date was ' ||  UPPER(v_query_result2)
          || ' and this date was ' ||  UPPER(v_tmp_date)
          );
          EOM_REPORT_PKG_TEST.H4_EOM_ALL_STOR_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
          EOM_REPORT_PKG_TEST.H4_EOM_ALL_STOR(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
        ELSIF  UPPER(v_query_result2) = UPPER(sCust_start)
        AND UPPER(v_query_result) IS NOT NULL
        AND UPPER(v_query_result) = UPPER(v_tmp_date)
        Then
          --this suggests that BOTH the bulk storage data AND the customer storage data is fresh - STOP
          DBMS_OUTPUT.PUT_LINE(''
          || 'this suggests that BOTH the bulk storage data AND the customer storage data is fresh - STOP!!!'
          || ' 6th No Need to RUN_ONCE H4_EOM_ALL_STOR_FEES & H4_EOM_ALL_STOR for all customers as table is not empty. Last Cust match was ' ||  UPPER(v_query_result)
          || ' and this cust was ' ||  UPPER(sCust_start)
          || ' and to date was ' ||  UPPER(v_query_result2)
          || ' and this date was ' ||  UPPER(v_tmp_date)
          );
        ELSIf UPPER(v_query_result) != UPPER(v_tmp_date)
        AND UPPER(v_query_result) IS NOT NULL
        --AND UPPER(v_query_result2) != UPPER(sCuststart)
        Then
          --this suggests that the bulk storage data is NOT fresh BUT the customer storage data is fresh - re run both
          DBMS_OUTPUT.PUT_LINE(''
          || 'this suggests that the bulk storage data is NOT fresh BUT the customer storage data is fresh - re run both!!!'
          || ' 6th Need to RUN_ONCE H4_EOM_ALL_STOR_FEES & H4_EOM_ALL_STOR for all customers as table is from different dates and different customer.
          Last Cust match was ' ||  UPPER(v_query_result)
          || ' and this cust was ' ||  UPPER(sCust_start)
          || ' and to date was ' ||  UPPER(v_query_result2)
          || ' and this date was ' ||  UPPER(v_tmp_date)
          );
          EOM_REPORT_PKG_TEST.H4_EOM_ALL_STOR_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
          EOM_REPORT_PKG_TEST.H4_EOM_ALL_STOR(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
        ELSIf UPPER(v_query_result) = UPPER(v_tmp_date)
        AND UPPER(v_query_result) IS NOT NULL
        AND UPPER(v_query_result2) != UPPER(sCust_start)
        Then
          --this suggests that the bulk storage data is fresh BUT the customer storage data is NOT fresh - re run just cust data
          DBMS_OUTPUT.PUT_LINE(''
          || 'this suggests that the bulk storage data is fresh BUT the customer storage data is NOT fresh - re run just cust data!!!'
          || '6th Need to RUN_ONCE H4_EOM_ALL_STOR for customer ' || UPPER(sCust_start) || ' as table data is for a different customer.
          Last Cust match was ' ||  UPPER(v_query_result)
          || ' and this cust was ' ||  UPPER(sCust_start)
          || ' and to date was ' ||  UPPER(v_query_result2)
          || ' and this date was ' ||  UPPER(v_tmp_date)
          );
          --EOM_REPORT_PKG_TEST.H4_EOM_ALL_STOR_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
          EOM_REPORT_PKG_TEST.H4_EOM_ALL_STOR(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
        Else
          DBMS_OUTPUT.PUT_LINE('6th No matches for running H4_EOM_ALL_STOR_FEES & H4_EOM_ALL_STOR,'
          || 'still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) || 'Seconds...'
          || ' for customer ' || sCust_start);
        End If;

      nCheckpoint := 71;
      EOM_REPORT_PKG_TEST.E1_PHONE_ORD_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
      nCheckpoint := 72;
      EOM_REPORT_PKG_TEST.E2_EMAIL_ORD_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
      nCheckpoint := 73;
      EOM_REPORT_PKG_TEST.E3_FAX_ORD_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
      nCheckpoint := 74;
      EOM_REPORT_PKG_TEST.E3_MAN_ORD_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
      nCheckpoint := 75;
      EOM_REPORT_PKG_TEST.E5_DESTOY_ORD_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);

      nCheckpoint := 81;
      EOM_REPORT_PKG_TEST.G1_SHRINKWRAP_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
      nCheckpoint := 82;
      EOM_REPORT_PKG_TEST.G2_STOCK_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
      nCheckpoint := 83;
      EOM_REPORT_PKG_TEST.G3_PACKING_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);


      nCheckpoint := 84;
      Select (F_EOM_CHECK_CUST_LOG(sCust_start ,'TMP_HANDLING_FEES','G4_HANDLING_FEES_F')) INTO v_query_result From Dual;
      Select (F_EOM_CHECK_LOG(v_tmp_date ,'TMP_HANDLING_FEES','G4_HANDLING_FEES_F')) INTO v_query_result2 From Dual;
      If UPPER(v_query_result) != UPPER(sCust_start)
      AND UPPER(v_query_result) IS NOT NULL
      AND UPPER(v_query_result2) != UPPER(v_tmp_date) Then
        DBMS_OUTPUT.PUT_LINE('7th Need to RUN_ONCE G4_HANDLING_FEES_F for all customers as table is not empty. result was ' || UPPER(v_query_result)
        || ' and this cust was ' ||  UPPER(sCust_start)
        || ' and to date was ' ||  UPPER(v_query_result2)
        || ' and this date was ' ||  UPPER(v_tmp_date)
        );
        EOM_REPORT_PKG_TEST.G4_HANDLING_FEES_F(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
      ELSIF  UPPER(v_query_result) = UPPER(sCust_start)
      AND UPPER(v_query_result) IS NOT NULL
      AND UPPER(v_query_result2) = UPPER(v_tmp_date) Then
        DBMS_OUTPUT.PUT_LINE('7th No Need to RUN_ONCE G4_HANDLING_FEES_F for all customers as table is not empty. Last Cust match was ' ||  UPPER(v_query_result)
        || ' and this cust was ' ||  UPPER(sCust_start)
        || ' and to date was ' ||  UPPER(v_query_result2)
        || ' and this date was ' ||  UPPER(v_tmp_date)
        );
      Else
        EOM_REPORT_PKG_TEST.G4_HANDLING_FEES_F(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
        DBMS_OUTPUT.PUT_LINE('7th No matches for running G4_HANDLING_FEES_F, ran it just in case still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
        ' Seconds...for customer ' || sCust_start);
      END IF;


      nCheckpoint := 85;
      Select (F_EOM_CHECK_CUST_LOG(sCust_start ,'TMP_PICK_FEES','G5_PICK_FEES_F')) INTO v_query_result From Dual;--v_query := q'{Select EOM_REPORT_PKG_TEST.EOM_CHECK_LOG(TO_CHAR(end_date,'DD-MON-YY') ,'TMP_ALL_FREIGHT_ALL','F_EOM_TMP_ALL_FREIGHT_ALL') }';--q'{INSERT INTO TMP_EOM_LOGS VALUES (SYSTIMESTAMP ,:startdate,:enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','NONE','TMP_ALL_FREIGHT_ALL',:v_time_taken,SYSTIMESTAMP )  }';
      Select (F_EOM_CHECK_LOG(v_tmp_date ,'TMP_PICK_FEES','G5_PICK_FEES_F')) INTO v_query_result2 From Dual;
      If UPPER(v_query_result) != UPPER(sCust_start)
      AND UPPER(v_query_result) IS NOT NULL
      AND UPPER(v_query_result2) != UPPER(v_tmp_date) Then
        DBMS_OUTPUT.PUT_LINE('8th Need to RUN_ONCE G5_PICK_FEES_F for all customers as table is not empty. cust result was ' || UPPER(v_query_result)
        || ' and this cust was ' ||  UPPER(sCust_start)
        || ' and to date was ' ||  UPPER(v_query_result2)
        || ' and this date was ' ||  UPPER(v_tmp_date)
         );
        EOM_REPORT_PKG_TEST.G5_PICK_FEES_F(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
      ELSIF UPPER(v_query_result) = UPPER(sCust_start)
      AND UPPER(v_query_result) IS NOT NULL
      AND UPPER(v_query_result2) = UPPER(v_tmp_date) Then
        DBMS_OUTPUT.PUT_LINE('8th No Need to RUN_ONCE G5_PICK_FEES_F for all customers as table is not empty. Last Cust match was ' ||  UPPER(v_query_result)
        || ' and this cust was ' ||  UPPER(sCust_start)
        || ' and to date was ' ||  UPPER(v_query_result2)
        || ' and this date was ' ||  UPPER(v_tmp_date)
        );
      Else
        EOM_REPORT_PKG_TEST.G5_PICK_FEES_F(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
        DBMS_OUTPUT.PUT_LINE('8th No matches for running G5_PICK_FEES_F, ran it just in case still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
        ' Seconds...for customer ' || sCust_start);
      END IF;
      nCheckpoint := 9;
      EOM_REPORT_PKG_TEST.I_EOM_MISC_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);

      nCheckpoint := 10;
      EOM_REPORT_PKG_TEST.K1_PAL_DESP_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
      nCheckpoint := 11;
      EOM_REPORT_PKG_TEST.K2_CTN_IN_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
      nCheckpoint := 12;
      EOM_REPORT_PKG_TEST.K3_PAL_IN_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
      nCheckpoint := 13;
      EOM_REPORT_PKG_TEST.K4_CTN_DESP_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);


     If ( sCust_start = 'VHAAUS' ) Then
        nCheckpoint := 14;
        EOM_REPORT_PKG_TEST.J_EOM_CUSTOMER_FEES_VHA(p_array_size_start,start_date,end_date,sCust_start);
      ElsIf ( sCust_start = 'BEYONDBLUE' ) Then
        nCheckpoint := 15;
        EOM_REPORT_PKG_TEST.J_EOM_CUSTOMER_FEES_BB(p_array_size_start,start_date,end_date,sCust_start);
      ElsIf ( sCust_start = 'TABCORP' ) Then
        nCheckpoint := 16;
        EOM_REPORT_PKG_TEST.J_EOM_CUSTOMER_FEES_TAB(p_array_size_start,start_date,end_date,sCust_start);
      --ElsIf ( sCust_start = 'IAG' ) Then
        --nCheckpoint := 60;
        --EOM_REPORT_PKG_TEST.Z_EOM_RUN_IAG(p_array_size_start,start_date,end_date,'CGU',sAnalysis_Start);
      End If;


     nCheckpoint := 99;
     EOM_REPORT_PKG_TEST.Y_EOM_TMP_MERGE_ALL_FEES();

     nCheckpoint := 100;
      --DBMS_OUTPUT.PUT_LINE('START Z TMP_ALL_FEES for ' || sFileName|| ' saved in ' || sPath );
      Z1_TMP_ALL_FEES_TO_CSV(sFileName);

    v_query2 :=  SQL%ROWCOUNT;
   -- DBMS_OUTPUT.PUT_LINE('Z EOM Successfully Ran EOM_RUN_ALL for ' || sCust_start|| ' in ' ||(round((dbms_utility.get_time-l_start)/100, 2) ||
    --' Seconds...' );
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,sysdate,sysdate,'Z_EOM_RUN_ALL','MERGE','NULL',v_time_taken,SYSTIMESTAMP,sCust_start);
      DBMS_OUTPUT.PUT_LINE('LAST EOM Successfully Ran EOM_RUN_ALL for the date range '
      || start_date || ' -- ' || end_date || ' - ' || v_query2 || ' records inserted in ' ||  (round((dbms_utility.get_time-l_start)/100, 6) ||
      ' Seconds... for customer '|| sCust_start ));
    RETURN;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM_RUN_ALL failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END Z_EOM_RUN_ALL;


  /*   Z Run this once for each customer including intercompany   */
  /*   This just runs all the above procedures from a single source   */
  /*   No Specific Temp Tables Used   */
  PROCEDURE Z_EOM_RUN_IAG (
      p_array_size_start IN PLS_INTEGER DEFAULT 100
      ,start_date IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,end_date IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCust_start IN VARCHAR2
      ,sAnalysis_Start IN RM.RM_ANAL%TYPE
  )
  AS
    nCheckpoint  NUMBER;
    sFileName VARCHAR2(560);
    l_start number default dbms_utility.get_time;
    v_time_taken VARCHAR2(205);
    v_query2 VARCHAR2(32767);
    tst_pick_counts tst_tmp_Admin_Data_Pick_Counts;
    sFileSuffix VARCHAR2(60):= '.csv';
    sFileTime VARCHAR2(56)  := TO_CHAR(SYSDATE,'YYYYMMDD HH24MISS');
    sPath VARCHAR2(60) :=  'EOM_ADMIN_ORDERS';
    v_query           VARCHAR2(2000);

  BEGIN

      nCheckpoint := 1;
      EOM_REPORT_PKG_TEST.A_EOM_GROUP_CUST();
      EOM_REPORT_PKG_TEST.B_EOM_START_RUN_ONCE_DATA(start_date,end_date,sAnalysis_Start,sCust_start,0);
      EOM_REPORT_PKG_TEST.C_EOM_START_CUST_TEMP_DATA(sAnalysis_Start,sCust_start);
      nCheckpoint := 82;
      EOM_REPORT_PKG_TEST.H1_EOM_STD_STOR_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
      EOM_REPORT_PKG_TEST.H2_EOM_SLOW_STOR_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
      nCheckpoint := 83;
      --EOM_REPORT_PKG_TEST.H3_EOM_SEC_STOR_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);

    v_query2 :=  SQL%ROWCOUNT;
   -- DBMS_OUTPUT.PUT_LINE('Z EOM Successfully Ran EOM_RUN_ALL for ' || sCust_start|| ' in ' ||(round((dbms_utility.get_time-l_start)/100, 2) ||
    --' Seconds...' );
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,start_date,end_date,'Z_EOM_RUN_IAG','MERGE','NULL',v_time_taken,SYSTIMESTAMP,sCust_start);
      DBMS_OUTPUT.PUT_LINE('Z EOM Successfully Ran Z_EOM_RUN_IAG for the date range '
      || start_date || ' -- ' || end_date || ' - ' || v_query2 || ' records inserted in ' ||  (round((dbms_utility.get_time-l_start)/100, 6) ||
      ' Seconds... for customer '|| sCust_start ));
    RETURN;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Z_EOM_RUN_IAG failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END Z_EOM_RUN_IAG;

  /*  Z Run this once for each customer including intercompany   */
  /*   This just runs all the above procedures from a single source   */
  /*   No Specific Temp Tables Used   */
  PROCEDURE Z_EOM_RUN_ALL2 (
      p_array_size_start IN PLS_INTEGER DEFAULT 100
        ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
        ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
        ,sCust_start IN RM.RM_CUST%TYPE,
      sAnalysis_Start IN RM.RM_ANAL%TYPE
  )
  AS
    nCheckpoint  NUMBER;
    v_time_taken VARCHAR2(205);
    l_start number default dbms_utility.get_time;
  BEGIN

      nCheckpoint := 1;
      EOM_REPORT_PKG_TEST.F_EOM_TMP_MAN_FREIGHT_ALL(p_array_size_start,start_date,end_date,sCust_start);

      nCheckpoint := 2;
      EOM_REPORT_PKG_TEST.F_EOM_TMP_AUTO_FREIGHT_ALL(p_array_size_start,start_date,end_date,sCust_start);


    RETURN;
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,start_date,end_date,'Z_EOM_RUN_ALL2','MERGE','NULL',v_time_taken,SYSTIMESTAMP,NULL);

  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM_RUN_ALL2 failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END Z_EOM_RUN_ALL2;

  /*   ZZ PRESENTATION LAYER - TO BE COMPLETED   */
  /*   This will read customer query columns from a table   */
  /*   and query the specific temp table in the clients req format   */
  PROCEDURE ZZ_EOM_CUST_QRY_TMP(
     sCust IN RM.RM_CUST%TYPE
     ,sQueryType IN VARCHAR2-- := 'ALL'
     ,src_tmp_qry OUT SYS_REFCURSOR
     )
    AS
      SQLQuery2  VARCHAR2(6000);
      l_start number default dbms_utility.get_time;
      v_time_taken VARCHAR2(205);
      SQLQuery1  VARCHAR2(600);
      SQLQuery3  VARCHAR2(6000);
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
    Else --if sCust IS NULL Then
      SQLQuery2 := 'SELECT '|| '*' ||
              ' FROM ' || QueryTable
              /*||' WHERE CUSTOMER = '
              || '''' || sCust || ''''
              || ' OR PARENT = '
              || '''' || sCust || ''''*/
              ;
    End If;
    SQLQuery3 := 'SELECT '|| 'TMP_ALL_FEES.WEIGHT' || '|,'
    ||	'TMP_ALL_FEES.ATTENTIONTO' || '|,' ||	'TMP_ALL_FEES.DELIVERTO'|| '|,'
    ||	'TMP_ALL_FEES.POSTCODE'|| '|,' ||	'TMP_ALL_FEES.STATE'|| '|,' ||	'TMP_ALL_FEES.SUBURB'|| '|,'
    ||	'TMP_ALL_FEES.ADDRESS2'|| '|,' ||	'TMP_ALL_FEES.ADDRESS'|| '|,' ||	'TMP_ALL_FEES.REPORTINGPRICE'|| '|,'
    ||	'TMP_ALL_FEES.SELL_INCL_TOTAL'|| '|,' ||	'TMP_ALL_FEES.SELL_INCL'|| '|,' ||	'TMP_ALL_FEES.SELL_EXCL_TOTAL'|| '|,'
    ||	'TMP_ALL_FEES.SELL_EXCL'|| '|,' ||	'TMP_ALL_FEES.OW_UNIT_SELL_PRICE'|| '|,' ||	'TMP_ALL_FEES.UNITPRICE'|| '|,'
    ||	'TMP_ALL_FEES.UOI'|| '|,' ||	'TMP_ALL_FEES.QTY'|| '|,' ||	'TMP_ALL_FEES.DESCRIPTION'|| '|,' ||	'TMP_ALL_FEES.ITEM'|| '|,'
    ||	'TMP_ALL_FEES.FEETYPE'|| '|,' ||	'TMP_ALL_FEES.DESPATCHDATE'|| '|,' ||	'TMP_ALL_FEES.DESPATCHNOTE'|| '|,'
    ||	'TMP_ALL_FEES.PICKNUM'|| '|,' ||	'TMP_ALL_FEES.PICKSLIP'|| '|,' ||	'TMP_ALL_FEES.CUSTREF'|| '|,' ||	'TMP_ALL_FEES.ORDERWARENUM'|| '|,'
    ||	'TMP_ALL_FEES.ORDERNUM'|| '|,' ||	'TMP_ALL_FEES.TMP_ALL_FEES.COSTCENTRE'|| '|,' ||	'TMP_ALL_FEES.PARENT'|| '|,' ||	'TMP_ALL_FEES.CUSTOMER'|| '|,'
    ||	'TMP_ALL_FEES.PAYMENTTYPE'|| '|,' ||	'TMP_ALL_FEES.TMP_ALL_FEES.COST'|| '|,' ||	'TMP_ALL_FEES.WAIVEFEE'|| '|,' ||	'TMP_ALL_FEES.SPROFILE'|| '|,'
    ||	'TMP_ALL_FEES.OWNEDBY'|| '|,' ||	'TMP_ALL_FEES.TMP_ALL_FEES.BRAND'|| '|,' ||	'TMP_ALL_FEES.EMAIL'|| '|,' ||	'TMP_ALL_FEES.COUNTOFSTOCKS'|| '|,'
    ||	'TMP_ALL_FEES.NILOCN'|| '|,' ||	'TMP_ALL_FEES.TMP_ALL_FEES.ILNOTE2'|| '|,' ||	'TMP_ALL_FEES.ORDERSOURCE'|| '|,' ||	'TMP_ALL_FEES.PACKAGES' || '|,'
    ||	'TMP_ALL_FEES.CAMPAIGN'|| '|,' ||	'TMP_ALL_FEES.TMP_ALL_FEES.SPARE1'|| '|,' ||	'TMP_ALL_FEES.SPARE2'|| '|,' ||	'TMP_ALL_FEES.SPARE3' ||
    ' FROM ' || v_qry_tbl_3;

    DBMS_OUTPUT.PUT_LINE('SQLQuery2 is ' || SQLQuery2 || ' for customer ' || sCust);
    --DBMS_OUTPUT.PUT_LINE('SQLQuery3 is ' || SQLQuery3 );

    nCheckpoint := 3;
    OPEN src_tmp_qry FOR
    SQLQuery2;
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,sysdate,sysdate,'ZZ_EOM_CUST_QRY_TMP','FORMATTING','TMP_ALL_FEES',v_time_taken,SYSTIMESTAMP,sCust);

  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END ZZ_EOM_CUST_QRY_TMP;

  /*   ZZ This will read customer query columns from a table   */
  /*   and query the final temp table in the clients req format   */
  --spool c:\test0.csv
  PROCEDURE ZZ_EOM_CUST_QRY_ALL_TMP(
     sCust IN RM.RM_CUST%TYPE
     ,src_tmp_qry OUT SYS_REFCURSOR
     )
    AS
      v_time_taken VARCHAR2(205);
      SQLQuery2  VARCHAR2(6000);
      SQLQuery1  VARCHAR2(600);
      QueryTable VARCHAR2(60);
      nCheckpoint   NUMBER;
      l_start number default dbms_utility.get_time;
      sCust_Columns TMP_CUST_REPORTING.SHEADERS%TYPE;
      v_qry_tbl_1 CONSTANT VARCHAR2(50) := 'TMP_ADMIN';
      v_qry_tbl_2 CONSTANT VARCHAR2(50) := 'TMP_FREIGHT';
      v_qry_tbl_3 CONSTANT VARCHAR2(50) := 'TMP_ALL_FEES';

     -- column dt new_val dateAdded;
      --select to_char(sysdate,’yyyymmdd’) dt from dual;
      --sFileSuffix := '.csv';
      --sFileName := sCust || sFileSuffix ;
     -- spool 'C:\' || sysdate || '.csv'
   BEGIN

      nCheckpoint := 8;
      --DUMP_TABLE_TO_CSV(sCust,sPath,sFileName);

      --select * from scott.emp;


      SQLQuery2 := 'SELECT '|| '*' ||
              ' FROM ' || v_qry_tbl_3
              /*||' WHERE CUSTOMER = '
              || sCust || ' OR PARENT = '
               || sCust*/
               ;

    DBMS_OUTPUT.PUT_LINE('done for ' || sCust);
    --nCheckpoint := 3;
    OPEN src_tmp_qry  FOR
    SQLQuery2;
    --spool off
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,sysdate,sysdate,'ZZ_EOM_CUST_QRY_ALL_TMP','FORMATTING','TMP_ALL_FEES',v_time_taken,SYSTIMESTAMP,NULL);

  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END ZZ_EOM_CUST_QRY_ALL_TMP;


  Procedure Z1_TMP_ALL_FEES_TO_CSV( p_filename in varchar2 )
    is
        l_output        utl_file.file_type;
        l_theCursor     integer default dbms_sql.open_cursor;
        l_columnValue   varchar2(4000);
        l_status        integer;
        l_query         varchar2(1000)
                       default 'select * from TMP_ALL_FEES_F';
       l_colCnt        number := 0;
       l_separator     varchar2(1);
       l_descTbl       dbms_sql.desc_tab;
       v_time_taken VARCHAR2(205);
        sPath VARCHAR2(60) :=  'EOM_ADMIN_ORDERS';
        l_start number default dbms_utility.get_time;
   begin
       l_output := utl_file.fopen( 'EOM_ADMIN_ORDERS', p_filename, 'w' );
       execute immediate 'alter session set nls_date_format=''dd-mon-yyyy hh24:mi:ss''';

       dbms_sql.parse(  l_theCursor,  l_query, dbms_sql.native );
       dbms_sql.describe_columns( l_theCursor, l_colCnt, l_descTbl );

       for i in 1 .. l_colCnt loop
           utl_file.put( l_output, l_separator || '"' || l_descTbl(i).col_name || '"');
           dbms_sql.define_column( l_theCursor, i, l_columnValue, 4000 );
           l_separator := ',';
       end loop;
       utl_file.new_line( l_output );

       l_status := dbms_sql.execute(l_theCursor);

       while ( dbms_sql.fetch_rows(l_theCursor) > 0 ) loop
           l_separator := '';
           for i in 1 .. l_colCnt loop
               dbms_sql.column_value( l_theCursor, i, l_columnValue );
               utl_file.put( l_output, l_separator || l_columnValue );
               l_separator := ',';
           end loop;
           utl_file.new_line( l_output );
       end loop;
       dbms_sql.close_cursor(l_theCursor);
       utl_file.fclose( l_output );

       execute immediate 'alter session set nls_date_format=''dd-MON-yy'' ';
      -- v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
       --EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,sysdate,sysdate,'Z1_TMP_ALL_FEES_TO_CSV','CSV','TMP_ALL_FEES_F',v_time_taken,SYSTIMESTAMP,sCustomerCode);

       DBMS_OUTPUT.PUT_LINE('Z TMP_ALL_FEES for ' || p_filename || ' saved in ' || sPath );
    exception
       when others then
           execute immediate 'alter session set nls_date_format=''dd-MON-yy'' ';
      raise;
   end Z1_TMP_ALL_FEES_TO_CSV;



  Procedure Z2_TMP_FEES_TO_CSV( p_filename in varchar2, p_in_table in varchar2 )
    is
        l_output        utl_file.file_type;
        l_theCursor     integer default dbms_sql.open_cursor;
        l_columnValue   varchar2(4000);
        l_status        integer;
        l_query         varchar2(1000)
                       default 'select /* csv */ * from ' || p_in_table;
       l_colCnt        number := 0;
       l_separator     varchar2(1);
       l_descTbl       dbms_sql.desc_tab;
       v_time_taken VARCHAR2(205);
        sPath VARCHAR2(60) :=  'EOM_ADMIN_ORDERS';
        l_start number default dbms_utility.get_time;
   begin
       l_output := utl_file.fopen( 'EOM_ADMIN_ORDERS', p_filename, 'w' );
       execute immediate 'alter session set nls_date_format=''dd-mon-yyyy hh24:mi:ss''';

       dbms_sql.parse(  l_theCursor,  l_query, dbms_sql.native );
       dbms_sql.describe_columns( l_theCursor, l_colCnt, l_descTbl );

       for i in 1 .. l_colCnt loop
           utl_file.put( l_output, l_separator || '"' || l_descTbl(i).col_name || '"');
           dbms_sql.define_column( l_theCursor, i, l_columnValue, 4000 );
           l_separator := ',';
       end loop;
       utl_file.new_line( l_output );

       l_status := dbms_sql.execute(l_theCursor);

       while ( dbms_sql.fetch_rows(l_theCursor) > 0 ) loop
           l_separator := '';
           for i in 1 .. l_colCnt loop
               dbms_sql.column_value( l_theCursor, i, l_columnValue );
               utl_file.put( l_output, l_separator || l_columnValue );
               l_separator := ',';
           end loop;
           utl_file.new_line( l_output );
       end loop;
       dbms_sql.close_cursor(l_theCursor);
       utl_file.fclose( l_output );

       execute immediate 'alter session set nls_date_format=''dd-MON-yy'' ';
       --v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
       --EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,sysdate,sysdate,'Z2_TMP_FEES_TO_CSV','CSV',p_in_table,v_time_taken,SYSTIMESTAMP,sCustomerCode);

       DBMS_OUTPUT.PUT_LINE('Z2_TMP_FEES_TO_CSV for ' || p_filename || ' saved in ' || sPath || ', data was from ' || p_in_table );
    exception
       when others then
           execute immediate 'alter session set nls_date_format=''dd-MON-yy'' ';
      raise;
   end Z2_TMP_FEES_TO_CSV;

    PROCEDURE EOM_CHECK_LOG (
       v_in_end_date  VARCHAR2
       ,v_in_tbl  VARCHAR2
       ,v_in_process VARCHAR2
      -- ,gds_src_get_desp_stocks OUT sys_refcursor
      ) AS
       v_query VARCHAR2(500);
       v_time_taken VARCHAR2(205);
      v_query_result VARCHAR2(500);
    BEGIN
      v_query  := q'{Select /*+INDEX(TMP_EOM_LOGS LAST_TOUCHED)*/ TO_DATE From TMP_EOM_LOGS Where DEST_TBL = :v_in_tbl AND ROWNUM <= 1   }';
      --,gds_src_get_desp_stocks OUT sys_refcursor
      EXECUTE IMMEDIATE v_query INTO v_query_result USING v_in_tbl;
      If v_query_result != v_in_end_date Then
        DBMS_OUTPUT.PUT_LINE(v_in_process || '_EOM_CHECK_LOG for table ' || v_in_tbl || ' has a different end date data range being '|| v_query_result || ' as such the process ' || v_in_process || ' will need to be rerun with fresh data to match end date of '  || v_in_end_date );
      Else
        DBMS_OUTPUT.PUT_LINE(v_in_process || '_EOM_CHECK_LOG for table ' || v_in_tbl || ' has a the same end date data range being '|| v_query_result || ' as such the process ' || v_in_process || ' will NOT need to be rerun with fresh data - THUS saving up to 2 minutes!' );
      End If;
      --RETURN v_query_result;
    EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM ORDERS failed  with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
    END EOM_CHECK_LOG;

    PROCEDURE EOM_INSERT_LOG (
      v_in_DATETIME    IN  DATE
      ,v_in_FROM_DATE   IN  DATE
      ,v_in_TO_DATE           IN  DATE
      ,v_in_ORIGIN_PROCESS   IN     VARCHAR2
      ,v_in_ORIGIN_TBL       IN     VARCHAR2
      ,v_in_DEST_TBL         IN     VARCHAR2
      ,v_in_TIME_TAKEN       IN     VARCHAR2
      ,v_in_LAST_TOUCH       IN     TIMESTAMP
      ,v_in_CUST              IN     VARCHAR2
      ) AS
    BEGIN
     INSERT INTO TMP_EOM_LOGS
     VALUES (v_in_DATETIME,v_in_FROM_DATE,v_in_TO_DATE,v_in_ORIGIN_PROCESS,v_in_ORIGIN_TBL,v_in_DEST_TBL,v_in_TIME_TAKEN,v_in_LAST_TOUCH,v_in_CUST );
   /* DBMS_OUTPUT.PUT_LINE('EOM_INSERT_LOG for the date ' || v_in_DATETIME
        || ' the FROM_DAATE field was set to ' || v_in_FROM_DATE
        || ' the TO_DAATE field was set to ' || v_in_TO_DATE
        || ' the Calling Process field was set to ' || v_in_ORIGIN_PROCESS
        || ' the Origin Table field was set to ' || v_in_ORIGIN_TBL
        || ' the Destination Table field was set to ' || v_in_DEST_TBL
        || ' the Time Taken field was set to ' || v_in_TIME_TAKEN
        || ' the last touch field was set to ' || v_in_LAST_TOUCH
        || ' the last touch field was set to ' || v_in_CUST
        || '. The log file has been updated ' );*/
     RETURN;
    EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM ORDERS failed at checkpoint  with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
   END EOM_INSERT_LOG;


    FUNCTION F_EOM_CHECK_LOG(
       v_in_end_date  VARCHAR2
       ,v_in_tbl  VARCHAR2
       ,v_in_process VARCHAR2
       )
    RETURN VARCHAR2
    AS
    v_rtn_val VARCHAR2(200);
    v_time_taken VARCHAR2(205);
    v_rtn_rslt VARCHAR2(200);
    BEGIN
      --DBMS_OUTPUT.PUT_LINE(' No Table name has been entered, nothing to return??? table was ' || v_in_tbl );
      --need to allow for customer based query changes as well as last date range
          Select /*+INDEX(TMP_EOM_LOGS LAST_TOUCHED)*/ TO_DATE
          INTO  v_rtn_rslt
          FROM TMP_EOM_LOGS Where DEST_TBL = v_in_tbl AND ROWNUM <= 1;
          RETURN v_rtn_rslt;
    END F_EOM_CHECK_LOG;

    FUNCTION F_EOM_CHECK_CUST_LOG(
       v_in_cust  VARCHAR2
       ,v_in_tbl  VARCHAR2
       ,v_in_process VARCHAR2
       )
    RETURN VARCHAR2
    AS
    v_rtn_val VARCHAR2(200);
    v_time_taken VARCHAR2(205);
    v_rtn_rslt VARCHAR2(200);
    BEGIN
      --DBMS_OUTPUT.PUT_LINE(' No Table name has been entered, nothing to return??? table was ' || v_in_tbl );
      --need to allow for customer based query changes as well as last date range
          Select /*+INDEX(TMP_EOM_LOGS LAST_TOUCHED)*/ CUST --using this field to populate from table with customer code from query
          INTO  v_rtn_rslt
          FROM TMP_EOM_LOGS Where DEST_TBL = v_in_tbl AND ROWNUM <= 1;
          RETURN v_rtn_rslt;
    END F_EOM_CHECK_CUST_LOG;

END EOM_REPORT_PKG_TEST;