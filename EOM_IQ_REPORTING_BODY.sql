create or replace PACKAGE BODY           "IQ_EOM_REPORTING" AS
    /*   A Group all customer down 3 tiers - this makes getting all children and grandchildren simples   */
    /*   Temp Tables Used   */
    /*   1. Tmp_Group_Cust   */
    /*   Runs in about 5 seconds   */
    /*   Tested and Working 17/7/15   */
    PROCEDURE A_TEMP_CUST_DATA(sOp IN VARCHAR2,Debug_Y_OR_N IN VARCHAR2 DEFAULT 'N') AS
      nCheckpoint  NUMBER;
      l_start number default dbms_utility.get_time;
      v_query2 VARCHAR2(32767);
      v_time_taken VARCHAR2(205);
  
    BEGIN
  
      nCheckpoint := 1;
      If (sOp = 'PRJ' or sOp = 'DEV') Then
        EXECUTE IMMEDIATE	'TRUNCATE  TABLE Dev_Group_Cust';
      Else
        EXECUTE IMMEDIATE	'TRUNCATE  TABLE Tmp_Group_Cust';
      End If;
      nCheckpoint := 2;
      ---Call Find_Droplist_String("FINISHING", QM_SPARE_ENUM_1);
      /*
      
      Procedure Find_Droplist_String(String FDS_Droplist, Number FDS_Integer)
        // Will find the text associated with a droplist value.
        // FDS_Droplist is a string containing the code of the user-defined droplist.
        // FDS_Integer is the value in the droplist field we want.
        // The lowest valid FDS_Integer value is 0 (not 1).
      
        Number	FDS_Count1 = 0;
        Number	FDS_Pos1 = 0;
        Number	FDS_Pos2 = 0;
        Number	FDS_NumItems = 0;
        String	FDS_UserValue = "";
        String	FDS_TempString = "";
        String	FDS_Answer = "";
        FDS_Answer.setSize(Pth_Size1);
      
        // A large droplist may be spread over several records
        Scan DV By DV_CODE_ORDER Choose(DV_CODE, Match, FDS_Droplist)
          FDS_UserValue = FDS_UserValue + DV_USER_VALUE;
        End
      
        // Count the number of items in the list:
        For FDS_Count1 From 0 To FDS_UserValue.StrLen - 1 Do
          If (FDS_UserValue.SubString(FDS_Count1, 1) == ",") Then
            FDS_NumItems = FDS_NumItems + 1;
          End
        End
      
        // If the integer provided is greater than the number of items in the list then we return an empty string:
        If (FDS_Integer + 1 <= FDS_NumItems) Then
      
          If (FDS_Integer > 0) Then
            // Find the position after the leading comma 
            FDS_TempString = FDS_UserValue;
            For FDS_Count1 From 1 To FDS_Integer Do
              // Find the next comma
              FDS_Pos1 = FDS_Pos1 + FDS_TempString.FoundAt(",") + 1;
              // Strip off the last user value so we can find the comma after this one
              FDS_TempString = FDS_UserValue.SubString(FDS_Pos1, 1000);
            End
          Else
            // If the integer is 0 we don't need to find a leading comma 
            FDS_Pos1 = 0;
          End
          // Find the position after the trailing comma 
          FDS_TempString = FDS_UserValue;
          For FDS_Count1 From 1 To FDS_Integer + 1 Do
            If (FDS_TempString.FoundAt(",") == -1) Then
              // We've reached the end of DV_USER_VALUE;
              FDS_Pos2 = FDS_Pos2 + FDS_TempString.StrLen + 1;
            Else
              // Find the next comma
              FDS_Pos2 = FDS_Pos2 + FDS_TempString.FoundAt(",") + 1;
              // Strip off the last user value so we can find the comma after this one
              FDS_TempString = FDS_UserValue.SubString(FDS_Pos2, 1000);
            End
          End
        
          // Strip off that last comma
          FDS_Pos2 = FDS_Pos2 - 1;
          // Our answer is the string in between the two positions we found 
          FDS_Answer = FDS_UserValue.SubString( FDS_Pos1, FDS_Pos2 - FDS_Pos1 );
        End
      End
          
      */
      If (sOp = 'PRJ' or sOp = 'DEV') Then
      EXECUTE IMMEDIATE 'INSERT into DEV_GROUP_CUST(sCust,sGroupCust,nLevel,AREA,TERR,RMDBL2,ANAL,SOURCE,OW_CAT )
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
                      START WITH Length(RM_PARENT) <= 1';
      Else
        EXECUTE IMMEDIATE 'INSERT into Tmp_Group_Cust(sCust,sGroupCust,nLevel,AREA,TERR,RMDBL2,ANAL,SOURCE,OW_CAT )
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
                      START WITH Length(RM_PARENT) <= 1';
      End If;
      If (upper(Debug_Y_OR_N) = 'Y') Then
        If (sOp = 'PRJ' or sOp = 'DEV') Then
          DBMS_OUTPUT.PUT_LINE('Successfully truncated, recreated AND populated Dev_Group_Cust');
        Else
          DBMS_OUTPUT.PUT_LINE('Successfully truncated, recreated AND populated Tmp_Group_Cust');
        End If;
      End If;
      v_query2 := SQL%ROWCOUNT;
      
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      If (sOp = 'PRJ' or sOp = 'DEV') Then
        EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,NULL,NULL,'A_TEMP_CUST_DATA','RM','Dev_Group_Cust2',v_time_taken,SYSTIMESTAMP,NULL);
      Else
        EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,NULL,NULL,'A_TEMP_CUST_DATA','RM','Tmp_Group_Cust2',v_time_taken,SYSTIMESTAMP,NULL);
      End If;
      If (upper(Debug_Y_OR_N) = 'Y') Then
        DBMS_OUTPUT.PUT_LINE('A EOM Group Cust temp tables  - There was ' || v_query2 || ' records inserted in ' ||  (round((dbms_utility.get_time-l_start)/100, 6) || ' Seconds...for all customers '));
      End If;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('A_TEMP_CUST_DATA failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
        RAISE;
    END A_TEMP_CUST_DATA;
  
    /*   B Run this once for all customer data */
    /*   This gets Break Prices, Pickslip Data, Pick Line Data, Batch Prices */
    /*   Temp Tables Used   */
    /*   1. Tmp_Admin_Data_BreakPrices   */
    /*   2. Tmp_Admin_Data_Pickslips   */
    /*   3. Tmp_Admin_Data_Pick_LineCounts   */
    /*   4. Tmp_Batch_Price_SL_Stock   */
    /*   Runs in about 240 seconds    */
    /*   Tested and Working 17/7/15   */
    /* This procedure doesn't need analysis for any 
    intercompany as it gets all data for all custs*/
    PROCEDURE B_EOM_START_RUN_ONCE_DATA
      (
       start_date IN VARCHAR2
       ,end_date IN VARCHAR2
      -- ,sAnalysis IN RM.RM_ANAL%TYPE
       --,sCust IN VARCHAR2
       --,PreData IN RM.RM_ACTIVE%TYPE := 0
       ,sOp IN VARCHAR2
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
      tst_pick_counts tmp_Admin_Data_Pick_LineCounts%ROWTYPE;
      v_time_taken VARCHAR2(205);
  
    BEGIN
  
     
  
  
  
  
      /*Insert fresh temp data*/
      If (sOp = 'PRJ' or sOp = 'DEV') Then
         /* Truncate all temp tables*/
      
        nCheckpoint := 1;
        v_query := 'TRUNCATE TABLE Dev_Admin_Data_BreakPrices';
        EXECUTE IMMEDIATE v_query;
    
        nCheckpoint := 3;
        v_query := 'TRUNCATE TABLE Dev_Admin_Data_Pickslips';
        EXECUTE IMMEDIATE	v_query;
    
        nCheckpoint := 4;
        v_query := 'TRUNCATE TABLE Dev_Admin_Data_Pick_LineCounts';
        EXECUTE IMMEDIATE v_query;
    
        nCheckpoint := 5;
        --v_query := 'TRUNCATE TABLE Tmp_Batch_Price_SL_Stock';
        --EXECUTE IMMEDIATE v_query;
        
        nCheckpoint := 11;
        EXECUTE IMMEDIATE 'INSERT INTO Dev_Admin_Data_BreakPrices
                  SELECT II_STOCK,II_CUST,II_BREAK_LCL,NULL,NULL,NULL,NULL
                  FROM II INNER JOIN IM ON IM_STOCK = II_STOCK
                  AND II_BREAK_LCL > 0.000001';
    
        nCheckpoint := 12;
        v_query := q'{INSERT INTO Dev_Admin_Data_Pickslips
                  SELECT LTrim(ST_PICK),LTrim(ST_PSLIP), substr(To_Char(ST_DESP_DATE),0,10), ST_WEIGHT, ST_PACKAGES,ST_XX_NUM_PAL_SW,ST_XX_NUM_PALLETS,ST_XX_NUM_CARTONS,NULL,NULL,NULL,NULL
                  FROM ST LEFT JOIN SH ON SH_ORDER = ST_ORDER
                  WHERE ST_DESP_DATE >= :start_date AND ST_DESP_DATE <= :end_date
                  AND ST_PSLIP != 'CANCELLED'
                  AND SH_STATUS <> 3}';
        EXECUTE IMMEDIATE v_query USING start_date,end_date;
        nCheckpoint := 13;
        v_query := q'{INSERT INTO Dev_Admin_Data_Pick_LineCounts
                  SELECT MAX(SL_LINE),LTrim(SL_PICK), LTrim(SL_ORDER), LTrim(SL_PSLIP),TP.vDateDesp, TP.vPackages,TP.vWeight,TP.vST_XX_NUM_PAL_SW,TP.vST_XX_NUM_PALLETS,TP.vST_XX_NUM_CARTONS,NULL,NULL,NULL,NULL
                  FROM Dev_Admin_Data_Pickslips TP RIGHT JOIN SL ON LTrim(SL_PICK) = TP.vPickslip
                  WHERE SL_EDIT_DATE >= :start_date AND SL_EDIT_DATE <= :end_date
                  AND SL_PSLIP != 'CANCELLED'
                  GROUP BY SL_PICK,SL_ORDER,SL_PSLIP,TP.vDateDesp,TP.vPackages,TP.vWeight,TP.vST_XX_NUM_PAL_SW,TP.vST_XX_NUM_PALLETS,TP.vST_XX_NUM_CARTONS}';
          EXECUTE IMMEDIATE v_query USING start_date,end_date;
      Else
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
      End If;
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
       ----DBMS_OUTPUT.PUT_LINE('B_EOM_START_RUN_ONCE_DATA for date range ' || start_date || ' -- ' || end_date || 'for customer '|| sCust || ' - There was ' || v_query2 || ' records inserted in ' ||  (round((dbms_utility.get_time-l_start)/100, 6) ||
       -- ' Seconds...' ));
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,start_date,end_date,'B_EOM_START_RUN_ONCE_DATA','ST/SL','TMP_ADMIN_DATA_PICK_LINECOUNTS',v_time_taken,SYSTIMESTAMP,NULL);
      --EOM_INSERT_LOG(SYSTIMESTAMP ,NULL,NULL,'A_TEMP_CUST_DATA','RM','Tmp_Group_Cust2',v_time_taken,SYSTIMESTAMP,NULL,sOp);
      --EOM_INSERT_LOG(SYSTIMESTAMP ,sysdate,sysdate,'ZZ_EOM_CUST_QRY_ALL_TMP','FORMATTING','TMP_ALL_FEES',v_time_taken,SYSTIMESTAMP,NULL);
     
      --DBMS_OUTPUT.PUT_LINE('B_EOM_START_RUN_ONCE_DATA for the date range '
      --|| start_date || ' -- ' || end_date || ' - ' || v_query2
      --|| ' records inserted in ' ||  (round((dbms_utility.get_time-l_start)/100, 6)
      --|| ' Seconds...for all customers '));
     --If F_IS_TABLE_EEMPTY('TMP_ADMIN_DATA_PICK_LINECOUNTS') <= 0 Then
       --DBMS_OUTPUT.PUT_LINE('B_EOM_START_RUN_ONCE_DATA as table is empty...Is it Really?????' );
       --EOM_REPORT_PKG_TEST.B_EOM_START_RUN_ONCE_DATA(start_date,end_date,sAnalysis_Start,sCust_start,0);
     -- End If;
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
    PROCEDURE C_EOM_START_ALL_TEMP_STOR_DATA
      (
       sAnalysis IN RM.RM_ANAL%TYPE
       ,sCust IN RM.RM_CUST%TYPE
       ,sOp IN VARCHAR2
      )
    AS
      v_time_taken VARCHAR2(205);
      v_query2          VARCHAR2(32767);
      v_query           VARCHAR2(2000);
      v_query3           VARCHAR2(2000);
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
    
     nCheckpoint := 15;
     If (sOp = 'PRJ' or sOp = 'DEV') Then
      v_query2 := 'TRUNCATE TABLE Dev_Locn_Cnt_By_Cust';
       EXECUTE IMMEDIATE v_query2;
       COMMIT;
        If F_IS_TABLE_EEMPTY('Dev_Locn_Cnt_By_Cust') = 0 Then
        DBMS_OUTPUT.PUT_LINE('C_EOM_START_ALL_TEMP_STOR_DATA table is now empty');
       End If;
     Else
      v_query2 := 'TRUNCATE TABLE Tmp_Locn_Cnt_By_Cust';
       EXECUTE IMMEDIATE v_query2;
       COMMIT;
        DBMS_OUTPUT.PUT_LINE('C_EOM_START_ALL_TEMP_STOR_DATA table should be empty');
        If F_IS_TABLE_EEMPTY('Tmp_Locn_Cnt_By_Cust') = 0 Then
        DBMS_OUTPUT.PUT_LINE('C_EOM_START_ALL_TEMP_STOR_DATA table is now empty');
       End If;
     End If;
    
    nCheckpoint := 151;
    DBMS_OUTPUT.PUT_LINE('C_EOM_START_ALL_TEMP_STOR_DATA now fill it again using params sOp is ' || sOp || ' and sCust is ' || sCust || ' and sAnalysis is ' || sAnalysis);
     If (sOp = 'PRJ' or sOp = 'DEV') then
      v_query := q'{INSERT INTO Dev_Locn_Cnt_By_Cust
              SELECT Count(DISTINCT NI_STOCK) AS CountOfStocks, IL_LOCN, r.sGroupCust,
                        CASE WHEN Upper(substr(IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                          ELSE 'F- Shelves'
                          END AS "Note",r.ANAL,NULL,NULL,NULL
              FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
              INNER JOIN IM ON IM_STOCK = NI_STOCK
              LEFT JOIN Dev_Group_Cust r ON r.sCust = IM_CUST
              WHERE IM_ACTIVE = 1
              AND NI_AVAIL_ACTUAL >= 1
              AND NI_STATUS <> 3
              GROUP BY r.sGroupCust,IL_LOCN, IM_CUST,IL_NOTE_2,r.ANAL}';
        
         
      Else
         v_query := q'{INSERT INTO Tmp_Locn_Cnt_By_Cust
              SELECT Count(DISTINCT NI_STOCK) AS CountOfStocks, IL_LOCN, r.sGroupCust,
                        CASE WHEN Upper(substr(IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                          ELSE 'F- Shelves'
                          END AS "Note",r.ANAL,NULL,NULL,NULL
              FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
              INNER JOIN IM ON IM_STOCK = NI_STOCK
              LEFT JOIN Tmp_Group_Cust r ON r.sCust = IM_CUST
              WHERE IM_ACTIVE = 1
              AND NI_AVAIL_ACTUAL >= 1
              AND NI_STATUS <> 3
              GROUP BY r.sGroupCust,IL_LOCN, IM_CUST,IL_NOTE_2,r.ANAL}';
        
      End If;
      EXECUTE IMMEDIATE v_query;-- USING sAnalysis;
      COMMIT;
      DBMS_OUTPUT.PUT_LINE('11 C_EOM_START_ALL_TEMP_STOR_DATA , check query-- ' || v_query);

--     If ((sOp = 'PRJ' or sOp = 'DEV') AND (sAnalysis != NULL)) Then
--        v_query := q'{INSERT INTO Dev_Locn_Cnt_By_Cust
--              SELECT Count(DISTINCT NI_STOCK) AS CountOfStocks, IL_LOCN, r.sGroupCust,
--                        CASE WHEN Upper(substr(IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
--                          ELSE 'F- Shelves'
--                          END AS "Note",r.ANAL,NULL,NULL,NULL
--              FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
--              INNER JOIN IM ON IM_STOCK = NI_STOCK
--              LEFT JOIN Dev_Group_Cust r ON r.sCust = IM_CUST
--              WHERE IM_ACTIVE = 1
--              AND NI_AVAIL_ACTUAL >= 1
--              AND NI_STATUS <> 3
--              AND r.ANAL = :sAnalysis
--              GROUP BY r.sGroupCust,IL_LOCN, IM_CUST,IL_NOTE_2,r.ANAL}';
--        EXECUTE IMMEDIATE v_query USING sAnalysis;
--         COMMIT;
--         DBMS_OUTPUT.PUT_LINE('1 C_EOM_START_ALL_TEMP_STOR_DATA , check query-- ' || v_query);
--    ElsIf ((sOp = 'PRJ' or sOp = 'DEV') AND (sAnalysis = NULL)) Then
--        v_query := q'{INSERT INTO Dev_Locn_Cnt_By_Cust
--              SELECT Count(DISTINCT NI_STOCK) AS CountOfStocks, IL_LOCN, r.sGroupCust,
--                        CASE WHEN Upper(substr(IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
--                          ELSE 'F- Shelves'
--                          END AS "Note",r.ANAL,NULL,NULL,NULL
--              FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
--              INNER JOIN IM ON IM_STOCK = NI_STOCK
--              LEFT JOIN Dev_Group_Cust r ON r.sCust = IM_CUST
--              WHERE IM_ACTIVE = 1
--              AND NI_AVAIL_ACTUAL >= 1
--              AND NI_STATUS <> 3
--              GROUP BY r.sGroupCust,IL_LOCN, IM_CUST,IL_NOTE_2,r.ANAL}';
--        EXECUTE IMMEDIATE v_query;-- USING sAnalysis;
--        COMMIT;
--        DBMS_OUTPUT.PUT_LINE('2 C_EOM_START_ALL_TEMP_STOR_DATA , check query-- ' || v_query);
--    ElsIf ((sOp != 'PRJ' or sOp != 'DEV') AND (sAnalysis = NULL)) Then
--      
--       v_query := q'{INSERT INTO Tmp_Locn_Cnt_By_Cust
--              SELECT Count(DISTINCT NI_STOCK) AS CountOfStocks, IL_LOCN, r.sGroupCust,
--                        CASE WHEN Upper(substr(IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
--                          ELSE 'F- Shelves'
--                          END AS "Note",r.ANAL,NULL,NULL,NULL
--              FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
--              INNER JOIN IM ON IM_STOCK = NI_STOCK
--              LEFT JOIN Tmp_Group_Cust r ON r.sCust = IM_CUST
--              WHERE IM_ACTIVE = 1
--              AND NI_AVAIL_ACTUAL >= 1
--              AND NI_STATUS <> 3
--              GROUP BY r.sGroupCust,IL_LOCN, IM_CUST,IL_NOTE_2,r.ANAL}';
--        EXECUTE IMMEDIATE v_query;-- USING sAnalysis;
--        COMMIT;
--        DBMS_OUTPUT.PUT_LINE('3 C_EOM_START_ALL_TEMP_STOR_DATA , check query-- ' || v_query);
--    ElsIf ((sOp != 'PRJ' or sOp != 'DEV') AND (sAnalysis != NULL)) Then
--      --use analysis 
--       v_query := q'{INSERT INTO Tmp_Locn_Cnt_By_Cust
--              SELECT Count(DISTINCT NI_STOCK) AS CountOfStocks, IL_LOCN, r.sGroupCust,
--                        CASE WHEN Upper(substr(IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
--                          ELSE 'F- Shelves'
--                          END AS "Note",r.ANAL,NULL,NULL,NULL
--              FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
--              INNER JOIN IM ON IM_STOCK = NI_STOCK
--              LEFT JOIN Tmp_Group_Cust r ON r.sCust = IM_CUST
--              WHERE IM_ACTIVE = 1
--              AND NI_AVAIL_ACTUAL >= 1
--              AND NI_STATUS <> 3
--              AND r.ANAL = :sAnalysis
--              GROUP BY r.sGroupCust,IL_LOCN, IM_CUST,IL_NOTE_2,r.ANAL}';
--      EXECUTE IMMEDIATE v_query USING sAnalysis; 
--      COMMIT;
--      DBMS_OUTPUT.PUT_LINE('4 C_EOM_START_ALL_TEMP_STOR_DATA , check query-- ' || v_query);
--    End If;
    
      --If F_IS_TABLE_EEMPTY('Tmp_Locn_Cnt_By_Cust') <= 0 Then
        --EXECUTE IMMEDIATE v_query;-- USING p_IM_ACTIVE,p_NI_AVAIL_ACTUAL,p_NI_STATUS;
      --Else
        
      --End If;
      
      RETURN;
      v_query3 :=  SQL%ROWCOUNT;
      COMMIT;
      If (sOp = 'PRJ' or sOp = 'DEV') Then
        If F_IS_TABLE_EEMPTY('Dev_Locn_Cnt_By_Cust') > 0 Then
       
        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
        EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,sysdate,sysdate,'C_EOM_START_ALL_TEMP_STOR_DATA','IL/NI','Dev_Locn_Cnt_By_Cust',v_time_taken,SYSTIMESTAMP,NULL);
        --DBMS_OUTPUT.PUT_LINE('C_EOM_START_ALL_TEMP_STOR_DATA for the date range '
        --|| F_FIRST_DAY_PREV_MONTH || ' -- ' || F_LAST_DAY_PREV_MONTH || ' - ' || v_query2
        -- || ' records inserted in ' ||  (round((dbms_utility.get_time-l_start)/100, 6)
        --|| ' Seconds...for customer ' || sCust));
        Else
          DBMS_OUTPUT.PUT_LINE('C_EOM_START_ALL_TEMP_STOR_DATA rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)));
        End If;
      Else 
        If F_IS_TABLE_EEMPTY('Tmp_Locn_Cnt_By_Cust') > 0 Then
          v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,sysdate,sysdate,'C_EOM_START_ALL_TEMP_STOR_DATA','IL/NI','Tmp_Locn_Cnt_By_Cust',v_time_taken,SYSTIMESTAMP,NULL);
          --DBMS_OUTPUT.PUT_LINE('C_EOM_START_ALL_TEMP_STOR_DATA for the date range '
          --|| F_FIRST_DAY_PREV_MONTH || ' -- ' || F_LAST_DAY_PREV_MONTH || ' - ' || v_query2
         -- || ' records inserted in ' ||  (round((dbms_utility.get_time-l_start)/100, 6)
          --|| ' Seconds...for customer ' || sCust));
        Else
          DBMS_OUTPUT.PUT_LINE('C_EOM_START_ALL_TEMP_STOR_DATA rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)));
        End If;
      End If;
  
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EOM processing failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
        RAISE;
    END C_EOM_START_ALL_TEMP_STOR_DATA;
    
    /*   F_EOM_TMP_ALL_FREIGHT_ALL Run this once for each customer   */
    /*   This gets all Freight data for queries   */
    /*   Temp Tables Used   */
    /*   1. TMP_ALL_FREIGHT_ALL   TO TEST AS MANUAL*/
    PROCEDURE F_EOM_TMP_ALL_FREIGHT_ALL (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
        ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
        ,sOp IN VARCHAR2
        ,Debug_Y_OR_N IN VARCHAR2 DEFAULT 'N'
      )
      IS    
      --If (sOp = 'PRJ' or sOp = 'DEV') Then
      --  TYPE ARRAY IS TABLE OF DEV_ALL_FREIGHT_ALL%ROWTYPE;
     -- Else
        TYPE ARRAY IS TABLE OF TMP_ALL_FREIGHT_ALL%ROWTYPE;
     -- End If;
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
      CURSOR c
      IS
        /* F_EOM_TMP_ALL_FREIGHT_ALL freight fees*/
      SELECT    s.SH_CUST                AS "Customer",
          r.sGroupCust              AS "Parent",
          s.SH_SPARE_STR_4         AS "CostCentre",
          s.SH_ORDER               AS "Order",
          s.SH_SPARE_STR_5         AS "OrderwareNum",
          s.SH_CUST_REF            AS "CustomerRef",
          t.ST_PICK                AS "PickNum",
          t.ST_PSLIP               AS "DespNote",
          substr(To_Char(d.SD_ADD_DATE),0,10)            AS "DespatchDate",
          substr(To_Char(s.SH_ADD_DATE),0,10) AS "OrderDate",
          CASE  WHEN  d.SD_STOCK = 'COURIERM' AND d.SD_SELL_PRICE >= 0.1 AND   d.SD_ADD_OP = 'RV'  THEN 'Manual Freight Fee'
                WHEN  d.SD_STOCK = 'COURIER' AND d.SD_SELL_PRICE >= 0.1 AND LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM)) IS NOT NULL AND d.SD_ADD_OP = 'SERV2' THEN 'Freight Fee'
                WHEN  d.SD_ADD_OP != 'RV' AND   d.SD_ADD_OP != 'SERV2' AND d.SD_XX_FREIGHT_CHG > 0.1 THEN 'XX Manual Freight Fee'
                WHEN  d.SD_ADD_OP = 'SERV2' AND d.SD_XX_FREIGHT_CHG > 0.1 THEN 'XX? Manual Freight Fee'
                WHEN  d.SD_ADD_OP != 'RV' AND   d.SD_ADD_OP != 'SERV2' AND d.SD_SELL_PRICE >= 0.1 THEN 'Other Manual Freight Fee'
                ELSE 'UnPricedManualFreight'
          END                      AS "FeeType",
          d.SD_STOCK               AS "Item",
          REPLACE(d.SD_DESC,',','|')              AS "Description",
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
          CASE  WHEN  d.SD_SELL_PRICE >= 0.1 AND   d.SD_ADD_OP = 'RV'  THEN f_calc_freight_fee(d.SD_SELL_PRICE,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER) 
                WHEN  d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 0.1 AND LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM)) IS NOT NULL AND d.SD_ADD_OP = 'SERV2' THEN f_calc_freight_fee(d.SD_SELL_PRICE,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER) 
                WHEN  d.SD_ADD_OP != 'RV' AND   d.SD_ADD_OP != 'SERV2' AND d.SD_XX_FREIGHT_CHG > 0.1 THEN f_calc_freight_fee(d.SD_XX_FREIGHT_CHG,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER)
                WHEN  d.SD_ADD_OP = 'SERV2' AND d.SD_XX_FREIGHT_CHG > 0.1 THEN f_calc_freight_fee(d.SD_XX_FREIGHT_CHG,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER)
                WHEN  d.SD_ADD_OP != 'RV' AND   d.SD_ADD_OP != 'SERV2' AND d.SD_SELL_PRICE >= 0.1 THEN f_calc_freight_fee(d.SD_SELL_PRICE,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER) 
                ELSE d.SD_EXCL   
          END AS "DExcl",
          CASE  WHEN  d.SD_SELL_PRICE >= 0.1 AND   d.SD_ADD_OP = 'RV'  THEN f_calc_freight_fee(d.SD_SELL_PRICE,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER) * 1.1
                WHEN  d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 0.1 AND LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM)) IS NOT NULL AND d.SD_ADD_OP = 'SERV2' THEN f_calc_freight_fee(d.SD_SELL_PRICE,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER)  * 1.1
                WHEN  d.SD_ADD_OP != 'RV' AND   d.SD_ADD_OP != 'SERV2' AND d.SD_XX_FREIGHT_CHG > 0.1 THEN f_calc_freight_fee(d.SD_XX_FREIGHT_CHG,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER) * 1.1
                WHEN  d.SD_ADD_OP = 'SERV2' AND d.SD_XX_FREIGHT_CHG > 0.1 THEN f_calc_freight_fee(d.SD_XX_FREIGHT_CHG,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER) * 1.1
                WHEN  d.SD_ADD_OP != 'RV' AND   d.SD_ADD_OP != 'SERV2' AND d.SD_SELL_PRICE >= 0.1 THEN f_calc_freight_fee(d.SD_SELL_PRICE,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER)  * 1.1
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
          r.area AS "Pallet/Shelf Space as area", 
          r.rmdbl2 AS "Locn_as rmdbl2", 
          d.SD_LINE, 
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
                ELSE ''
          END AS Email,
          'N/A' AS Brand,
          r.terr,null,
          s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
          s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
          d.SD_ADD_DATE,d.SD_ADD_OP,
          d.SD_XX_FREIGHT_CHG
    FROM  PWIN175.SD d
          INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
          LEFT OUTER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_PICK))  = LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM))
          LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
    WHERE d.SD_STOCK IN ('COURIERM','COURIERS','COURIER','DETENTIONTIMEM','DETENTIONTIMES','FREIGHTDUTY')
    AND   d.SD_ADD_DATE >= startdate AND d.SD_ADD_DATE <= enddate
    GROUP BY  
          s.SH_CUST,s.SH_SPARE_STR_4,s.SH_CAMPAIGN,s.SH_ORDER,s.SH_XX_FEE_WAIVE,s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
          s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_ADD_DATE,s.SH_NOTE_2,
          s.SH_SPARE_DBL_9,s.SH_SPARE_STR_5,s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,
          t.ST_PICK,t.ST_PSLIP,t.ST_DESP_DATE,t.ST_WEIGHT,t.ST_PACKAGES,t.ST_SPARE_DBL_1, 
          d.SD_XX_PICKLIST_NUM,d.SD_QTY_ORDER,d.SD_QTY_ORDER,d.SD_ORDER,d.SD_XX_FREIGHT_CHG,d.SD_COST_PRICE,d.SD_NOTE_1,d.SD_COST_PRICE,
          d.SD_STOCK,d.SD_ADD_OP,d.SD_DESC,d.SD_LINE,d.SD_EXCL,d.SD_INCL,d.SD_NOTE_1,d.SD_SELL_PRICE,d.SD_XX_OW_UNIT_PRICE,d.SD_XX_FREIGHT_CHG,
          d.SD_XX_PSLIP_NUM,d.SD_ADD_DATE,
          r.sGroupCust,r.terr,r.area,r.rmdbl2
          
          UNION ALL
          
          
     SELECT    s.SH_CUST                AS "Customer",
          r.sGroupCust              AS "Parent",
          s.SH_SPARE_STR_4         AS "CostCentre",
          s.SH_ORDER               AS "Order",
          s.SH_SPARE_STR_5         AS "OrderwareNum",
          s.SH_CUST_REF            AS "CustomerRef",
          d.SD_XX_PICKLIST_NUM                AS "PickNum",
          d.SD_XX_PSLIP_NUM               AS "DespNote",
          substr(To_Char(d.SD_ADD_DATE),0,10)            AS "DespatchDate",
          substr(To_Char(s.SH_ADD_DATE),0,10) AS "OrderDate",
          CASE  WHEN d.SD_XX_FREIGHT_CHG >= 0.1  THEN 'XX Van Manual Freight Fee'
			          ELSE 'UnPricedXXFreight'
			          END                      AS "FeeType",
          d.SD_STOCK               AS "Item",
          REPLACE(d.SD_DESC,',','|')              AS "Description",
          CASE  WHEN d.SD_LINE IS NOT NULL THEN  1
                ELSE NULL
          END                     AS "Qty",
          CASE  WHEN d.SD_LINE IS NOT NULL THEN  '1'
                ELSE NULL
          END                      AS "UOI",
         f_calc_freight_fee(d.SD_XX_FREIGHT_CHG,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER) AS "UnitPriceMarkedUp", 
          CASE  WHEN d.SD_SELL_PRICE >= 1 THEN f_calc_freight_fee(d.SD_XX_FREIGHT_CHG,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER)      
          ELSE d.SD_XX_FREIGHT_CHG   
          END AS "OWUnitPrice",
          CASE  WHEN d.SD_XX_FREIGHT_CHG >= 1 THEN f_calc_freight_fee(d.SD_XX_FREIGHT_CHG,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER)      
          ELSE d.SD_EXCL   
          END AS "DExcl",
          CASE  WHEN d.SD_XX_FREIGHT_CHG >= 1 THEN f_calc_freight_fee(d.SD_XX_FREIGHT_CHG,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER) * 1.1     
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
          r.area AS "Pallet/Shelf Space as area", 
          r.rmdbl2 AS "Locn_as rmdbl2", 
          d.SD_LINE, 
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
                ELSE ''
          END AS Email,
          'N/A' AS Brand,
          r.terr AS "ownedby as terr",null,
          s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
          s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
          d.SD_ADD_DATE,d.SD_ADD_OP,
          d.SD_XX_FREIGHT_CHG
    FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
	WHERE d.SD_STOCK = 'COURIER'--IN ('COURIERM','COURIERS','COURIER','DETENTIONTIMEM','DETENTIONTIMES','FREIGHTDUTY')
	AND       d.SD_ADD_DATE >= startdate AND d.SD_ADD_DATE <= enddate
  AND   d.SD_ADD_OP NOT LIKE 'SERV%' 
  AND   d.SD_ADD_OP != 'RV'
    GROUP BY  
          s.SH_CUST,s.SH_SPARE_STR_4,s.SH_CAMPAIGN,s.SH_ORDER,s.SH_XX_FEE_WAIVE,s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
          s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_ADD_DATE,s.SH_NOTE_2,
          s.SH_SPARE_DBL_9,s.SH_SPARE_STR_5,s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,
          --t.ST_PICK,t.ST_PSLIP,t.ST_DESP_DATE,t.ST_WEIGHT,t.ST_PACKAGES,t.ST_SPARE_DBL_1, 
          d.SD_XX_PICKLIST_NUM,d.SD_QTY_ORDER,d.SD_QTY_ORDER,d.SD_ORDER,d.SD_XX_FREIGHT_CHG,d.SD_COST_PRICE,d.SD_NOTE_1,d.SD_COST_PRICE,
          d.SD_STOCK,d.SD_ADD_OP,d.SD_DESC,d.SD_LINE,d.SD_EXCL,d.SD_INCL,d.SD_NOTE_1,d.SD_SELL_PRICE,d.SD_XX_OW_UNIT_PRICE,d.SD_XX_FREIGHT_CHG,
          d.SD_XX_PSLIP_NUM,d.SD_ADD_DATE,
          r.sGroupCust,r.rmdbl2,r.terr,r.area;
     
      CURSOR cDEV
      IS
        /* F_EOM_TMP_ALL_FREIGHT_ALL freight fees*/
      SELECT    s.SH_CUST                AS "Customer",
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
          CASE  WHEN  d.SD_SELL_PRICE >= 0.1 AND   d.SD_ADD_OP = 'RV'  THEN f_calc_freight_fee(d.SD_SELL_PRICE,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER) 
                WHEN  d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 0.1 AND LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM)) IS NOT NULL AND d.SD_ADD_OP = 'SERV2' THEN f_calc_freight_fee(d.SD_SELL_PRICE,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER) 
                WHEN  d.SD_ADD_OP != 'RV' AND   d.SD_ADD_OP != 'SERV2' AND d.SD_XX_FREIGHT_CHG > 0.1 THEN f_calc_freight_fee(d.SD_XX_FREIGHT_CHG,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER)
                WHEN  d.SD_ADD_OP = 'SERV2' AND d.SD_XX_FREIGHT_CHG > 0.1 THEN f_calc_freight_fee(d.SD_XX_FREIGHT_CHG,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER)
                WHEN  d.SD_ADD_OP != 'RV' AND   d.SD_ADD_OP != 'SERV2' AND d.SD_SELL_PRICE >= 0.1 THEN f_calc_freight_fee(d.SD_SELL_PRICE,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER) 
                ELSE d.SD_EXCL   
          END AS "DExcl",
          CASE  WHEN  d.SD_SELL_PRICE >= 0.1 AND   d.SD_ADD_OP = 'RV'  THEN f_calc_freight_fee(d.SD_SELL_PRICE,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER) * 1.1
                WHEN  d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 0.1 AND LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM)) IS NOT NULL AND d.SD_ADD_OP = 'SERV2' THEN f_calc_freight_fee(d.SD_SELL_PRICE,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER)  * 1.1
                WHEN  d.SD_ADD_OP != 'RV' AND   d.SD_ADD_OP != 'SERV2' AND d.SD_XX_FREIGHT_CHG > 0.1 THEN f_calc_freight_fee(d.SD_XX_FREIGHT_CHG,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER) * 1.1
                WHEN  d.SD_ADD_OP = 'SERV2' AND d.SD_XX_FREIGHT_CHG > 0.1 THEN f_calc_freight_fee(d.SD_XX_FREIGHT_CHG,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER) * 1.1
                WHEN  d.SD_ADD_OP != 'RV' AND   d.SD_ADD_OP != 'SERV2' AND d.SD_SELL_PRICE >= 0.1 THEN f_calc_freight_fee(d.SD_SELL_PRICE,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER)  * 1.1
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
          r.area AS "Pallet/Shelf Space as area", 
          r.rmdbl2 AS "Locn_as rmdbl2", 
          d.SD_LINE, 
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
                ELSE ''
          END AS Email,
          'N/A' AS Brand,
          r.terr,null,
          s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
          s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
          d.SD_ADD_DATE,d.SD_ADD_OP,
          d.SD_XX_FREIGHT_CHG
    FROM  PWIN175.SD d
          INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
          LEFT OUTER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_PICK))  = LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM))
          LEFT JOIN Dev_Group_Cust r ON r.sCust = s.SH_CUST
    WHERE d.SD_STOCK IN ('COURIERM','COURIERS','COURIER','DETENTIONTIMEM','DETENTIONTIMES','FREIGHTDUTY')
    AND   d.SD_ADD_DATE >= startdate AND d.SD_ADD_DATE <= enddate
    GROUP BY  
          s.SH_CUST,s.SH_SPARE_STR_4,s.SH_CAMPAIGN,s.SH_ORDER,s.SH_XX_FEE_WAIVE,s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
          s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_ADD_DATE,s.SH_NOTE_2,
          s.SH_SPARE_DBL_9,s.SH_SPARE_STR_5,s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,
          t.ST_PICK,t.ST_PSLIP,t.ST_DESP_DATE,t.ST_WEIGHT,t.ST_PACKAGES,t.ST_SPARE_DBL_1, 
          d.SD_XX_PICKLIST_NUM,d.SD_QTY_ORDER,d.SD_QTY_ORDER,d.SD_ORDER,d.SD_XX_FREIGHT_CHG,d.SD_COST_PRICE,d.SD_NOTE_1,d.SD_COST_PRICE,
          d.SD_STOCK,d.SD_ADD_OP,d.SD_DESC,d.SD_LINE,d.SD_EXCL,d.SD_INCL,d.SD_NOTE_1,d.SD_SELL_PRICE,d.SD_XX_OW_UNIT_PRICE,d.SD_XX_FREIGHT_CHG,
          d.SD_XX_PSLIP_NUM,d.SD_ADD_DATE,
          r.sGroupCust,r.terr,r.area,r.rmdbl2
          
          UNION ALL
          
          
     SELECT    s.SH_CUST                AS "Customer",
          r.sGroupCust              AS "Parent",
          s.SH_SPARE_STR_4         AS "CostCentre",
          s.SH_ORDER               AS "Order",
          s.SH_SPARE_STR_5         AS "OrderwareNum",
          s.SH_CUST_REF            AS "CustomerRef",
          d.SD_XX_PICKLIST_NUM                AS "PickNum",
          d.SD_XX_PSLIP_NUM               AS "DespNote",
          substr(To_Char(d.SD_ADD_DATE),0,10)            AS "DespatchDate",
          substr(To_Char(s.SH_ADD_DATE),0,10) AS "OrderDate",
          CASE  WHEN d.SD_XX_FREIGHT_CHG >= 0.1  THEN 'XX Van Manual Freight Fee'
			          ELSE 'UnPricedXXFreight'
			          END                      AS "FeeType",
          d.SD_STOCK               AS "Item",
          REPLACE(d.SD_DESC,',','|')              AS "Description",
          CASE  WHEN d.SD_LINE IS NOT NULL THEN  1
                ELSE NULL
          END                     AS "Qty",
          CASE  WHEN d.SD_LINE IS NOT NULL THEN  '1'
                ELSE NULL
          END                      AS "UOI",
         f_calc_freight_fee(d.SD_XX_FREIGHT_CHG,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER) AS "UnitPriceMarkedUp", 
          CASE  WHEN d.SD_SELL_PRICE >= 1 THEN f_calc_freight_fee(d.SD_XX_FREIGHT_CHG,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER)      
          ELSE d.SD_XX_FREIGHT_CHG   
          END AS "OWUnitPrice",
          CASE  WHEN d.SD_XX_FREIGHT_CHG >= 1 THEN f_calc_freight_fee(d.SD_XX_FREIGHT_CHG,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER)      
          ELSE d.SD_EXCL   
          END AS "DExcl",
          CASE  WHEN d.SD_XX_FREIGHT_CHG >= 1 THEN f_calc_freight_fee(d.SD_XX_FREIGHT_CHG,TRIM(d.SD_NOTE_1),r.sGroupCust,d.SD_ORDER) * 1.1     
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
          r.area AS "Pallet/Shelf Space as area", 
          r.rmdbl2 AS "Locn_as rmdbl2", 
          d.SD_LINE, 
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
                ELSE ''
          END AS Email,
          'N/A' AS Brand,
          r.terr AS "ownedby as terr",null,
          s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
          s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
          d.SD_ADD_DATE,d.SD_ADD_OP,
          d.SD_XX_FREIGHT_CHG
    FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  LEFT JOIN Dev_Group_Cust r ON r.sCust = s.SH_CUST
	WHERE d.SD_STOCK = 'COURIER'--IN ('COURIERM','COURIERS','COURIER','DETENTIONTIMEM','DETENTIONTIMES','FREIGHTDUTY')
	AND       d.SD_ADD_DATE >= startdate AND d.SD_ADD_DATE <= enddate
  AND   d.SD_ADD_OP NOT LIKE 'SERV%' 
  AND   d.SD_ADD_OP != 'RV'
    GROUP BY  
          s.SH_CUST,s.SH_SPARE_STR_4,s.SH_CAMPAIGN,s.SH_ORDER,s.SH_XX_FEE_WAIVE,s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
          s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_ADD_DATE,s.SH_NOTE_2,
          s.SH_SPARE_DBL_9,s.SH_SPARE_STR_5,s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,
          --t.ST_PICK,t.ST_PSLIP,t.ST_DESP_DATE,t.ST_WEIGHT,t.ST_PACKAGES,t.ST_SPARE_DBL_1, 
          d.SD_XX_PICKLIST_NUM,d.SD_QTY_ORDER,d.SD_QTY_ORDER,d.SD_ORDER,d.SD_XX_FREIGHT_CHG,d.SD_COST_PRICE,d.SD_NOTE_1,d.SD_COST_PRICE,
          d.SD_STOCK,d.SD_ADD_OP,d.SD_DESC,d.SD_LINE,d.SD_EXCL,d.SD_INCL,d.SD_NOTE_1,d.SD_SELL_PRICE,d.SD_XX_OW_UNIT_PRICE,d.SD_XX_FREIGHT_CHG,
          d.SD_XX_PSLIP_NUM,d.SD_ADD_DATE,
          r.sGroupCust,r.rmdbl2,r.terr,r.area;    
          
        nbreakpoint   NUMBER;
        l_start number default dbms_utility.get_time;   
     BEGIN
        v_run_datetime := '';
       -- nCheckpoint := 1;
         
        
        nCheckpoint := 2;
        If (sOp = 'PRJ' or sOp = 'DEV') Then
          v_query := 'TRUNCATE TABLE DEV_ALL_FREIGHT_ALL';
          EXECUTE IMMEDIATE v_query;
          COMMIT;
          
          OPEN cDEV;
          ----DBMS_OUTPUT.PUT_LINE(?? || '.' );
          LOOP
          FETCH cDEV BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(l_data(10) || '.' );
          
          INSERT INTO DEV_ALL_FREIGHT_ALL VALUES l_data(i);
          --USING sCust;
          EXIT WHEN cDEV%NOTFOUND;
  
          END LOOP;
          ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE cDEV;
         --FOR i IN l_data.FIRST .. l_data.LAST LOOP
          ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).unitprice || '.' );
         --END LOOP;
        Else
          v_query := 'TRUNCATE TABLE TMP_ALL_FREIGHT_ALL';
          EXECUTE IMMEDIATE v_query;
          COMMIT;
          
          OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(?? || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(l_data(10) || '.' );
          
          INSERT INTO TMP_ALL_FREIGHT_ALL VALUES l_data(i);
          --USING sCust;
          EXIT WHEN c%NOTFOUND;
  
          END LOOP;
          ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
         --FOR i IN l_data.FIRST .. l_data.LAST LOOP
          ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).unitprice || '.' );
         --END LOOP;
        End If;
        v_query2 :=  SQL%ROWCOUNT;
        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      COMMIT;
      IF v_query2 > 0 THEN
          nCheckpoint := 100;
          v_query := '';
        If (sOp = 'PRJ' or sOp = 'DEV') Then  
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','DEV_FREIGHT','DEV_ALL_FREIGHT_ALL',v_time_taken,SYSTIMESTAMP,NULL);--q'{INSERT INTO TMP_EOM_LOGS VALUES (SYSTIMESTAMP ,:startdate,:enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','NONE','TMP_ALL_FREIGHT_ALL',:v_time_taken,SYSTIMESTAMP )  }';
         If (upper(Debug_Y_OR_N) = 'Y') then
          DBMS_OUTPUT.PUT_LINE('F_EOM_DEV_ALL_FREIGHT_ALL for the date range '
          || startdate || ' -- ' || enddate || ' - ' || v_query2
          || ' records inserted into table DEV_ALL_FREIGHT_ALL in ' || round((dbms_utility.get_time-l_start)/100, 6)
          || ' Seconds...for all customers, log file has been updated ' );
         End If;
        Else
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','TMP_FREIGHT','TMP_ALL_FREIGHT_ALL',v_time_taken,SYSTIMESTAMP,NULL);--q'{INSERT INTO TMP_EOM_LOGS VALUES (SYSTIMESTAMP ,:startdate,:enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','NONE','TMP_ALL_FREIGHT_ALL',:v_time_taken,SYSTIMESTAMP )  }';
          If (upper(Debug_Y_OR_N) = 'Y') then
            DBMS_OUTPUT.PUT_LINE('F_EOM_TMP_ALL_FREIGHT_ALL for the date range '
            || startdate || ' -- ' || enddate || ' - ' || v_query2
            || ' records inserted into table TMP_ALL_FREIGHT_ALL in ' || round((dbms_utility.get_time-l_start)/100, 6)
            || ' Seconds...for all customers, log file has been updated ' );
           End If;
        End If;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('F_EOM_TMP_ALL_FREIGHT_ALL failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
    END F_EOM_TMP_ALL_FREIGHT_ALL;
    
    /*   F_EOM_TMP_COST_MU_FREIGHT_ALL Run this once for each customer   */
    /*   Tis marks up freight based on cost price not sell  */
    /*   This gets all Freight data for queries   */
    /*   Temp Tables Used   */
    /*   1. TMP_ALL_FREIGHT_ALL   TO TEST AS MANUAL*/
    PROCEDURE F_EOM_TMP_COST_MU_FREIGHT_ALL (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
        ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
        ,sOp IN VARCHAR2
      )
      IS    
      --If (sOp = 'PRJ' or sOp = 'DEV') Then
      --  TYPE ARRAY IS TABLE OF DEV_ALL_FREIGHT_ALL%ROWTYPE;
     -- Else
        TYPE ARRAY IS TABLE OF TMP_ALL_FREIGHT_ALL%ROWTYPE;
     -- End If;
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
      CURSOR c
      IS
        /* F_EOM_TMP_ALL_FREIGHT_ALL freight fees*/
      SELECT    s.SH_CUST                AS "Customer",
          r.sGroupCust              AS "Parent",
          s.SH_SPARE_STR_4         AS "CostCentre",
          s.SH_ORDER               AS "Order",
          s.SH_SPARE_STR_5         AS "OrderwareNum",
          s.SH_CUST_REF            AS "CustomerRef",
          t.ST_PICK                AS "PickNum",
          t.ST_PSLIP               AS "DespNote",
          substr(To_Char(d.SD_ADD_DATE),0,10)            AS "DespatchDate",
          substr(To_Char(s.SH_ADD_DATE),0,10) AS "OrderDate",
          CASE  WHEN  d.SD_COST_PRICE >= 0.1 AND   d.SD_ADD_OP = 'RV'  THEN 'Manual Freight Fee'
                WHEN  d.SD_STOCK like 'COURIER%' AND d.SD_COST_PRICE >= 0.1 AND LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM)) IS NOT NULL AND d.SD_ADD_OP = 'SERV2' THEN 'Freight Fee'
                WHEN  d.SD_ADD_OP != 'RV' AND   d.SD_ADD_OP != 'SERV2' AND d.SD_XX_FREIGHT_CHG > 0.1 THEN 'XX Manual Freight Fee'
                WHEN  d.SD_ADD_OP = 'SERV2' AND d.SD_XX_FREIGHT_CHG > 0.1 THEN 'XX? Manual Freight Fee'
                WHEN  d.SD_ADD_OP != 'RV' AND   d.SD_ADD_OP != 'SERV2' AND d.SD_COST_PRICE >= 0.1 THEN 'Other Manual Freight Fee'
                ELSE 'UnPricedManualFreight'
          END                      AS "FeeType",
          d.SD_STOCK               AS "Item",
          REPLACE(d.SD_DESC,',','|')              AS "Description",
          CASE  WHEN d.SD_LINE IS NOT NULL THEN  1
                ELSE NULL
          END                     AS "Qty",
          CASE  WHEN d.SD_LINE IS NOT NULL THEN  '1'
                ELSE NULL
          END                      AS "UOI",
          CASE  WHEN  d.SD_COST_PRICE >= 0.1 THEN d.SD_COST_PRICE *  1.1
                ELSE 0
          END AS "UnitPriceMarkedUp", 
          d.SD_COST_PRICE *  1.1  AS "OWUnitPrice",
          CASE  WHEN  d.SD_SELL_PRICE >= 0.1  THEN (d.SD_COST_PRICE *  1.1) 
                ELSE 0   
          END AS "DExcl",
          CASE  WHEN  d.SD_SELL_PRICE >= 0.1  THEN (d.SD_COST_PRICE *  1.1) * 1.1
                ELSE 0   
          END AS "DIncl",
          d.SD_COST_PRICE *  1.1                   AS "ReportingPrice",
          0 AS "ReportingPrice",
          0           AS "COSTPRICE",
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
          r.area AS "Pallet/Shelf Space as area", 
          r.rmdbl2 AS "Locn_as rmdbl2", 
          d.SD_LINE, 
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
                ELSE ''
          END AS Email,
          'N/A' AS Brand,
          r.terr,null,
          s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
          s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
          d.SD_ADD_DATE,d.SD_ADD_OP,
          d.SD_XX_FREIGHT_CHG
    FROM  PWIN175.SD d
          INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
          LEFT OUTER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_PICK))  = LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM))
          LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
    WHERE d.SD_STOCK IN ('COURIERM','COURIERS','COURIER','DETENTIONTIMEM','DETENTIONTIMES','FREIGHTDUTY')
    AND   d.SD_ADD_DATE >= startdate AND d.SD_ADD_DATE <= enddate
    GROUP BY  
          s.SH_CUST,s.SH_SPARE_STR_4,s.SH_CAMPAIGN,s.SH_ORDER,s.SH_XX_FEE_WAIVE,s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
          s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_ADD_DATE,s.SH_NOTE_2,
          s.SH_SPARE_DBL_9,s.SH_SPARE_STR_5,s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,
          t.ST_PICK,t.ST_PSLIP,t.ST_DESP_DATE,t.ST_WEIGHT,t.ST_PACKAGES,t.ST_SPARE_DBL_1, 
          d.SD_XX_PICKLIST_NUM,d.SD_QTY_ORDER,d.SD_QTY_ORDER,d.SD_ORDER,d.SD_XX_FREIGHT_CHG,d.SD_COST_PRICE,d.SD_NOTE_1,d.SD_COST_PRICE,
          d.SD_STOCK,d.SD_ADD_OP,d.SD_DESC,d.SD_LINE,d.SD_EXCL,d.SD_INCL,d.SD_NOTE_1,d.SD_SELL_PRICE,d.SD_XX_OW_UNIT_PRICE,d.SD_XX_FREIGHT_CHG,
          d.SD_XX_PSLIP_NUM,d.SD_ADD_DATE,
          r.sGroupCust,r.terr,r.area,r.rmdbl2
          
          UNION ALL
          
          
     SELECT    s.SH_CUST                AS "Customer",
          r.sGroupCust              AS "Parent",
          s.SH_SPARE_STR_4         AS "CostCentre",
          s.SH_ORDER               AS "Order",
          s.SH_SPARE_STR_5         AS "OrderwareNum",
          s.SH_CUST_REF            AS "CustomerRef",
          d.SD_XX_PICKLIST_NUM                AS "PickNum",
          d.SD_XX_PSLIP_NUM               AS "DespNote",
          substr(To_Char(d.SD_ADD_DATE),0,10)            AS "DespatchDate",
          substr(To_Char(s.SH_ADD_DATE),0,10) AS "OrderDate",
          CASE  WHEN d.SD_XX_FREIGHT_CHG >= 0.1  THEN 'XX Van Manual Freight Fee'
			          ELSE 'UnPricedXXFreight'
			          END                      AS "FeeType",
          d.SD_STOCK               AS "Item",
          REPLACE(d.SD_DESC,',','|')              AS "Description",
          CASE  WHEN d.SD_LINE IS NOT NULL THEN  1
                ELSE NULL
          END                     AS "Qty",
          CASE  WHEN d.SD_LINE IS NOT NULL THEN  '1'
                ELSE NULL
          END                      AS "UOI",
          d.SD_COST_PRICE *  1.1, 
          CASE  WHEN d.SD_SELL_PRICE >= 1  THEN (d.SD_COST_PRICE *  1.1)   
          ELSE 0   
          END AS "OWUnitPrice",
          CASE  WHEN d.SD_XX_FREIGHT_CHG >= 1  THEN (d.SD_COST_PRICE *  1.1)     
          ELSE 0   
          END AS "DExcl",
          CASE  WHEN d.SD_XX_FREIGHT_CHG >= 1 THEN  (d.SD_COST_PRICE *  1.1) * 1.1  
          ELSE 0   
          END AS "DIncl",
          d.SD_COST_PRICE *  1.1                   AS "ReportingPrice",
          0 AS "ReportingPrice",
          0           AS "COSTPRICE",
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
          r.area AS "Pallet/Shelf Space as area", 
          r.rmdbl2 AS "Locn_as rmdbl2", 
          d.SD_LINE, 
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
                ELSE ''
          END AS Email,
          'N/A' AS Brand,
          r.terr AS "ownedby as terr",null,
          s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
          s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
          d.SD_ADD_DATE,d.SD_ADD_OP,
          d.SD_XX_FREIGHT_CHG
    FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
	WHERE d.SD_STOCK = 'COURIER'--IN ('COURIERM','COURIERS','COURIER','DETENTIONTIMEM','DETENTIONTIMES','FREIGHTDUTY')
	AND       d.SD_ADD_DATE >= startdate AND d.SD_ADD_DATE <= enddate
  AND   d.SD_ADD_OP NOT LIKE 'SERV%' 
  AND   d.SD_ADD_OP != 'RV'
    GROUP BY  
          s.SH_CUST,s.SH_SPARE_STR_4,s.SH_CAMPAIGN,s.SH_ORDER,s.SH_XX_FEE_WAIVE,s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
          s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_ADD_DATE,s.SH_NOTE_2,
          s.SH_SPARE_DBL_9,s.SH_SPARE_STR_5,s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,
          --t.ST_PICK,t.ST_PSLIP,t.ST_DESP_DATE,t.ST_WEIGHT,t.ST_PACKAGES,t.ST_SPARE_DBL_1, 
          d.SD_XX_PICKLIST_NUM,d.SD_QTY_ORDER,d.SD_QTY_ORDER,d.SD_ORDER,d.SD_XX_FREIGHT_CHG,d.SD_COST_PRICE,d.SD_NOTE_1,d.SD_COST_PRICE,
          d.SD_STOCK,d.SD_ADD_OP,d.SD_DESC,d.SD_LINE,d.SD_EXCL,d.SD_INCL,d.SD_NOTE_1,d.SD_SELL_PRICE,d.SD_XX_OW_UNIT_PRICE,d.SD_XX_FREIGHT_CHG,
          d.SD_XX_PSLIP_NUM,d.SD_ADD_DATE,
          r.sGroupCust,r.rmdbl2,r.terr,r.area;
     
      CURSOR cDEV
      IS
        /* F_EOM_TMP_ALL_FREIGHT_ALL freight fees*/
      SELECT    s.SH_CUST                AS "Customer",
          r.sGroupCust              AS "Parent",
          s.SH_SPARE_STR_4         AS "CostCentre",
          s.SH_ORDER               AS "Order",
          s.SH_SPARE_STR_5         AS "OrderwareNum",
          s.SH_CUST_REF            AS "CustomerRef",
          t.ST_PICK                AS "PickNum",
          t.ST_PSLIP               AS "DespNote",
          substr(To_Char(d.SD_ADD_DATE),0,10)            AS "DespatchDate",
          substr(To_Char(s.SH_ADD_DATE),0,10) AS "OrderDate",
          CASE  WHEN  d.SD_COST_PRICE >= 0.1 AND   d.SD_ADD_OP = 'RV'  THEN 'Manual Freight Fee'
                WHEN  d.SD_STOCK like 'COURIER%' AND d.SD_COST_PRICE >= 0.1 AND LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM)) IS NOT NULL AND d.SD_ADD_OP = 'SERV2' THEN 'Freight Fee'
                WHEN  d.SD_ADD_OP != 'RV' AND   d.SD_ADD_OP != 'SERV2' AND d.SD_XX_FREIGHT_CHG > 0.1 THEN 'XX Manual Freight Fee'
                WHEN  d.SD_ADD_OP = 'SERV2' AND d.SD_XX_FREIGHT_CHG > 0.1 THEN 'XX? Manual Freight Fee'
                WHEN  d.SD_ADD_OP != 'RV' AND   d.SD_ADD_OP != 'SERV2' AND d.SD_COST_PRICE >= 0.1 THEN 'Other Manual Freight Fee'
                ELSE 'UnPricedManualFreight'
          END                      AS "FeeType",
          d.SD_STOCK               AS "Item",
          REPLACE(d.SD_DESC,',','|')              AS "Description",
          CASE  WHEN d.SD_LINE IS NOT NULL THEN  1
                ELSE NULL
          END                     AS "Qty",
          CASE  WHEN d.SD_LINE IS NOT NULL THEN  '1'
                ELSE NULL
          END                      AS "UOI",
          CASE  WHEN  d.SD_COST_PRICE >= 0.1  THEN (d.SD_COST_PRICE *  1.1) 
               ELSE 0
          END AS "UnitPriceMarkedUp", 
          d.SD_COST_PRICE * 1.1  AS "OWUnitPrice",
          CASE  WHEN  d.SD_COST_PRICE >= 0.1  THEN (d.SD_COST_PRICE *  1.1) 
                ELSE 0  
          END AS "DExcl",
          CASE  WHEN  d.SD_COST_PRICE >= 0.1  THEN (d.SD_COST_PRICE *  1.1) * 1.1
                ELSE 0   
          END AS "DIncl",
          d.SD_COST_PRICE *  1.1                   AS "ReportingPrice",
          0 AS "ReportingPrice",
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
          r.area AS "Pallet/Shelf Space as area", 
          r.rmdbl2 AS "Locn_as rmdbl2", 
          d.SD_LINE, 
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
                ELSE ''
          END AS Email,
          'N/A' AS Brand,
          r.terr,null,
          s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
          s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
          d.SD_ADD_DATE,d.SD_ADD_OP,
          d.SD_XX_FREIGHT_CHG
    FROM  PWIN175.SD d
          INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
          LEFT OUTER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_PICK))  = LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM))
          LEFT JOIN Dev_Group_Cust r ON r.sCust = s.SH_CUST
    WHERE d.SD_STOCK IN ('COURIERM','COURIERS','COURIER','DETENTIONTIMEM','DETENTIONTIMES','FREIGHTDUTY')
    AND   d.SD_ADD_DATE >= startdate AND d.SD_ADD_DATE <= enddate
    GROUP BY  
          s.SH_CUST,s.SH_SPARE_STR_4,s.SH_CAMPAIGN,s.SH_ORDER,s.SH_XX_FEE_WAIVE,s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
          s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_ADD_DATE,s.SH_NOTE_2,
          s.SH_SPARE_DBL_9,s.SH_SPARE_STR_5,s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,
          t.ST_PICK,t.ST_PSLIP,t.ST_DESP_DATE,t.ST_WEIGHT,t.ST_PACKAGES,t.ST_SPARE_DBL_1, 
          d.SD_XX_PICKLIST_NUM,d.SD_QTY_ORDER,d.SD_QTY_ORDER,d.SD_ORDER,d.SD_XX_FREIGHT_CHG,d.SD_COST_PRICE,d.SD_NOTE_1,d.SD_COST_PRICE,
          d.SD_STOCK,d.SD_ADD_OP,d.SD_DESC,d.SD_LINE,d.SD_EXCL,d.SD_INCL,d.SD_NOTE_1,d.SD_SELL_PRICE,d.SD_XX_OW_UNIT_PRICE,d.SD_XX_FREIGHT_CHG,
          d.SD_XX_PSLIP_NUM,d.SD_ADD_DATE,
          r.sGroupCust,r.terr,r.area,r.rmdbl2
          
          UNION ALL
          
          
     SELECT    s.SH_CUST                AS "Customer",
          r.sGroupCust              AS "Parent",
          s.SH_SPARE_STR_4         AS "CostCentre",
          s.SH_ORDER               AS "Order",
          s.SH_SPARE_STR_5         AS "OrderwareNum",
          s.SH_CUST_REF            AS "CustomerRef",
          d.SD_XX_PICKLIST_NUM                AS "PickNum",
          d.SD_XX_PSLIP_NUM               AS "DespNote",
          substr(To_Char(d.SD_ADD_DATE),0,10)            AS "DespatchDate",
          substr(To_Char(s.SH_ADD_DATE),0,10) AS "OrderDate",
          CASE  WHEN d.SD_XX_FREIGHT_CHG >= 0.1  THEN 'XX Van Manual Freight Fee'
			          ELSE 'UnPricedXXFreight'
			          END                      AS "FeeType",
          d.SD_STOCK               AS "Item",
          REPLACE(d.SD_DESC,',','|')              AS "Description",
          CASE  WHEN d.SD_LINE IS NOT NULL THEN  1
                ELSE NULL
          END                     AS "Qty",
          CASE  WHEN d.SD_LINE IS NOT NULL THEN  '1'
                ELSE NULL
          END                      AS "UOI",
          SD_COST_PRICE * 1.1 AS "UnitPriceMarkedUp", 
          CASE  WHEN d.SD_COST_PRICE >= 1 THEN SD_COST_PRICE * 1.1   
          ELSE 0   
          END AS "OWUnitPrice",
          CASE  WHEN d.SD_XX_FREIGHT_CHG >= 1 THEN SD_COST_PRICE * 1.1      
          ELSE 0   
          END AS "DExcl",
          CASE  WHEN d.SD_XX_FREIGHT_CHG >= 1 THEN (SD_COST_PRICE * 1.1)   * 1.1   
          ELSE 0   
          END AS "DIncl",
          SD_COST_PRICE * 1.1                   AS "ReportingPrice",
          0 AS "ReportingPrice",
          0           AS "COSTPRICE",
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
          r.area AS "Pallet/Shelf Space as area", 
          r.rmdbl2 AS "Locn_as rmdbl2", 
          d.SD_LINE, 
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
                ELSE ''
          END AS Email,
          'N/A' AS Brand,
          r.terr AS "ownedby as terr",null,
          s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
          s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
          d.SD_ADD_DATE,d.SD_ADD_OP,
          d.SD_XX_FREIGHT_CHG
    FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  LEFT JOIN Dev_Group_Cust r ON r.sCust = s.SH_CUST
	WHERE d.SD_STOCK = 'COURIER'--IN ('COURIERM','COURIERS','COURIER','DETENTIONTIMEM','DETENTIONTIMES','FREIGHTDUTY')
	AND       d.SD_ADD_DATE >= startdate AND d.SD_ADD_DATE <= enddate
  AND   d.SD_ADD_OP NOT LIKE 'SERV%' 
  AND   d.SD_ADD_OP != 'RV'
    GROUP BY  
          s.SH_CUST,s.SH_SPARE_STR_4,s.SH_CAMPAIGN,s.SH_ORDER,s.SH_XX_FEE_WAIVE,s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
          s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_ADD_DATE,s.SH_NOTE_2,
          s.SH_SPARE_DBL_9,s.SH_SPARE_STR_5,s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,
          --t.ST_PICK,t.ST_PSLIP,t.ST_DESP_DATE,t.ST_WEIGHT,t.ST_PACKAGES,t.ST_SPARE_DBL_1, 
          d.SD_XX_PICKLIST_NUM,d.SD_QTY_ORDER,d.SD_QTY_ORDER,d.SD_ORDER,d.SD_XX_FREIGHT_CHG,d.SD_COST_PRICE,d.SD_NOTE_1,d.SD_COST_PRICE,
          d.SD_STOCK,d.SD_ADD_OP,d.SD_DESC,d.SD_LINE,d.SD_EXCL,d.SD_INCL,d.SD_NOTE_1,d.SD_SELL_PRICE,d.SD_XX_OW_UNIT_PRICE,d.SD_XX_FREIGHT_CHG,
          d.SD_XX_PSLIP_NUM,d.SD_ADD_DATE,
          r.sGroupCust,r.rmdbl2,r.terr,r.area;    
          
        nbreakpoint   NUMBER;
        l_start number default dbms_utility.get_time;   
     BEGIN
        v_run_datetime := '';
       -- nCheckpoint := 1;
         
        
        nCheckpoint := 2;
        If (sOp = 'PRJ' or sOp = 'DEV') Then
          v_query := 'TRUNCATE TABLE DEV_ALL_FREIGHT_ALL';
          EXECUTE IMMEDIATE v_query;
          COMMIT;
          
          OPEN cDEV;
          ----DBMS_OUTPUT.PUT_LINE(?? || '.' );
          LOOP
          FETCH cDEV BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(l_data(10) || '.' );
          
          INSERT INTO DEV_ALL_FREIGHT_ALL VALUES l_data(i);
          --USING sCust;
          EXIT WHEN cDEV%NOTFOUND;
  
          END LOOP;
          ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE cDEV;
         --FOR i IN l_data.FIRST .. l_data.LAST LOOP
          ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).unitprice || '.' );
         --END LOOP;
        Else
          v_query := 'TRUNCATE TABLE TMP_ALL_FREIGHT_ALL';
          EXECUTE IMMEDIATE v_query;
          COMMIT;
          
          OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(?? || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(l_data(10) || '.' );
          
          INSERT INTO TMP_ALL_FREIGHT_ALL VALUES l_data(i);
          --USING sCust;
          EXIT WHEN c%NOTFOUND;
  
          END LOOP;
          ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
         --FOR i IN l_data.FIRST .. l_data.LAST LOOP
          ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).unitprice || '.' );
         --END LOOP;
        End If;
        v_query2 :=  SQL%ROWCOUNT;
        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      COMMIT;
      IF v_query2 > 0 THEN
          nCheckpoint := 100;
          v_query := '';
        If (sOp = 'PRJ' or sOp = 'DEV') Then  
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','DEV_FREIGHT','DEV_ALL_FREIGHT_ALL',v_time_taken,SYSTIMESTAMP,NULL);--q'{INSERT INTO TMP_EOM_LOGS VALUES (SYSTIMESTAMP ,:startdate,:enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','NONE','TMP_ALL_FREIGHT_ALL',:v_time_taken,SYSTIMESTAMP )  }';
        Else
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','TMP_FREIGHT','TMP_ALL_FREIGHT_ALL',v_time_taken,SYSTIMESTAMP,NULL);--q'{INSERT INTO TMP_EOM_LOGS VALUES (SYSTIMESTAMP ,:startdate,:enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','NONE','TMP_ALL_FREIGHT_ALL',:v_time_taken,SYSTIMESTAMP )  }';
        End If;
        --EXECUTE IMMEDIATE v_query USING startdate,enddate,v_time_taken;
        --DBMS_OUTPUT.PUT_LINE('F_EOM_TMP_ALL_FREIGHT_ALL for the date range '
        --|| startdate || ' -- ' || enddate || ' - ' || v_query2
        --|| ' records inserted into table TMP_ALL_FREIGHT_ALL in ' || round((dbms_utility.get_time-l_start)/100, 6)
        --|| ' Seconds...for all customers, log file has been updated ' );
      --Else
        --DBMS_OUTPUT.PUT_LINE('F_EOM_TMP_ALL_FREIGHT_ALL rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
       -- ' Seconds...for all customers ');
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('F_EOM_TMP_ALL_FREIGHT_ALL failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
    END F_EOM_TMP_COST_MU_FREIGHT_ALL;
    
     
    /*   F_EOM_TMP_MAN_FREIGHT_ALL Run this once for each customer   */
    /*   This gets all the IFS freight and Manual Freight data   */
    /*   Temp Tables Used   */
    /*   1. TMP_V_FREIGHT   TO TEST AS MANUAL*/
    
    /*REMOVE*/
    
    PROCEDURE F_EOM_TMP_VAN_FREIGHT_ALL (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
        ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
        ,sCustomerCode IN VARCHAR2
        ,sFilterBy IN VARCHAR2
        ,sOp IN VARCHAR2
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
      ----DBMS_OUTPUT.PUT_LINE(start_date || ' - ' || end_date || '.' || sCust );
  
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
          r.rmdbl2 AS "Locn", /*Locn*/
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
          d.SD_QTY_ORDER,r.rmdbl2,
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
  
     CURSOR cDEV
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
          r.rmdbl2 AS "Locn", /*Locn*/
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
          LEFT JOIN Dev_Group_Cust r ON r.sCust = s.SH_CUST
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
          d.SD_QTY_ORDER,r.rmdbl2,
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
  
     -- nCheckpoint := 1;
      
      ----DBMS_OUTPUT.PUT_LINE('AA EOM Temp Freight table truncated '
      --  || start_date || ' -- ' || end_date);
      nCheckpoint := 2;
      If (sOp = 'PRJ' or sOp = 'DEV') Then
        v_query := 'TRUNCATE TABLE DEV_V_FREIGHT';
        EXECUTE IMMEDIATE v_query;
        COMMIT;
      
          OPEN cDEV;
          ----DBMS_OUTPUT.PUT_LINE(sShary || '.' );
          LOOP
          FETCH cDEV BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(l_data(10) || '.' );
          INSERT INTO DEV_V_FREIGHT VALUES l_data(i);
          --USING sCust;
  
          EXIT WHEN cDEV%NOTFOUND;
  
          END LOOP;
          ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE cDEV;
         --FOR i IN l_data.FIRST .. l_data.LAST LOOP
          ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        --END LOOP;
      Else
          v_query := 'TRUNCATE TABLE TMP_V_FREIGHT';
          EXECUTE IMMEDIATE v_query;
          COMMIT;
        
          OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(sShary || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(l_data(10) || '.' );
          INSERT INTO TMP_V_FREIGHT VALUES l_data(i);
          --USING sCust;
  
          EXIT WHEN c%NOTFOUND;
  
          END LOOP;
          ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
         --FOR i IN l_data.FIRST .. l_data.LAST LOOP
          ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        --END LOOP;
      End If;
    v_query2 :=  SQL%ROWCOUNT;
    COMMIT;
  
      IF v_query2 > 0 THEN
        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
        EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'F_EOM_TMP_VAN_FREIGHT_ALL','SD','TMP_V_FREIGHT',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        --DBMS_OUTPUT.PUT_LINE('F_EOM_TMP_VAN_FREIGHT_ALL for the date range '
        --|| startdate || ' -- ' || enddate || ' - ' || v_query2
        --|| ' records inserted into table TMP_V_FREIGHT in ' || round((dbms_utility.get_time-l_start)/100, 6)
        --|| ' Seconds...for customer ' || sCustomerCode );
      --Else
        --DBMS_OUTPUT.PUT_LINE('F_EOM_TMP_VAN_FREIGHT_ALL rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
       -- ' Seconds...for customer ' || sCustomerCode);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('F_EOM_TMP_VAN_FREIGHT_ALL failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
  
        RAISE;
  
    END F_EOM_TMP_VAN_FREIGHT_ALL;
            
    /*   F_Z_EOM_RUN_ALL_FREIGHT Run this once for each customer including intercompany   */
    /*   This just runs all the above procedures from a single source   */
    /*   No Specific Temp Tables Used   */
    PROCEDURE F8_Z_EOM_RUN_FREIGHT (
         p_array_size IN PLS_INTEGER DEFAULT 100
        ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
        ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
        ,sCustomerCode IN VARCHAR2
        ,sFilterBy IN VARCHAR2
        ,sOp IN VARCHAR2
        ,Debug_Y_OR_N IN VARCHAR2 DEFAULT 'N'
        ,SaveFreightFile_Y_OR_N IN VARCHAR2 DEFAULT 'N'
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
      ----DBMS_OUTPUT.PUT_LINE(start_date || ' - ' || end_date || '.' || sCust );
      sFileName VARCHAR2(560);
      sFileTime VARCHAR2(56)  := TO_CHAR(SYSDATE,'YYYYMMDD HH24MISS');
        CURSOR c1   
        IS 
        /*All freight fees by Parent*/
        select  *
        FROM  TMP_ALL_FREIGHT_ALL t
        WHERE ROWID IN ( SELECT MAX(ROWID) FROM TMP_ALL_FREIGHT_ALL GROUP BY description )
        and t.parent = sCustomerCode or t.Customer = sCustomerCode;
      
        CURSOR c2        
        IS       
        /*All freight fees by RM_DBL_2*/
        select  *
        FROM  TMP_ALL_FREIGHT_ALL t
        WHERE ROWID IN ( SELECT MAX(ROWID) FROM TMP_ALL_FREIGHT_ALL GROUP BY description )
        AND t.NILOCN = sCustomerCode;
     
        CURSOR c3        
        IS       
        /*All freight fees by territory*/
        select DISTINCT *
        FROM  TMP_ALL_FREIGHT_ALL t
        WHERE ROWID IN ( SELECT MAX(ROWID) FROM TMP_ALL_FREIGHT_ALL GROUP BY description )
        AND t.OWNEDBY = sCustomerCode;
      
        CURSOR c4        
        IS       
        /*All freight fees by area*/
        select  *
        FROM  TMP_ALL_FREIGHT_ALL t
        WHERE ROWID IN ( SELECT MAX(ROWID) FROM TMP_ALL_FREIGHT_ALL GROUP BY description )
        AND t.ILNOTE2 = sCustomerCode;
        
        CURSOR c1Dev   
        IS 
        /*All freight fees by Parent*/
        select  *
        FROM  DEV_ALL_FREIGHT_ALL t
        WHERE ROWID IN ( SELECT MAX(ROWID) FROM DEV_ALL_FREIGHT_ALL GROUP BY description )
        and t.parent = sCustomerCode or t.Customer = sCustomerCode;
        --AND t.parent = sCustomerCode; --AND trim(FEETYPE) != 'Freight Fee';
      
        CURSOR c2Dev        
        IS       
        /*All freight fees by RM_DBL_2*/
        select  *
        FROM  DEV_ALL_FREIGHT_ALL t
        WHERE ROWID IN ( SELECT MAX(ROWID) FROM DEV_ALL_FREIGHT_ALL GROUP BY description )
        AND t.NILOCN = sCustomerCode;
     
        CURSOR c3Dev        
        IS       
        /*All freight fees by territory*/
        select DISTINCT *
        FROM  DEV_ALL_FREIGHT_ALL t
        WHERE ROWID IN ( SELECT MAX(ROWID) FROM DEV_ALL_FREIGHT_ALL GROUP BY description )
        AND t.OWNEDBY = sCustomerCode;
      
        CURSOR c4Dev        
        IS       
        /*All freight fees by area*/
        select  *
        FROM  DEV_ALL_FREIGHT_ALL t
        WHERE ROWID IN ( SELECT MAX(ROWID) FROM DEV_ALL_FREIGHT_ALL GROUP BY description )
        AND t.ILNOTE2 = sCustomerCode;
       
      nbreakpoint   NUMBER;
      l_start number default dbms_utility.get_time;
      BEGIN
      
      --nCheckpoint := 1;
      
      ----DBMS_OUTPUT.PUT_LINE('AA EOM Temp Freight table truncated '
      --  || start_date || ' -- ' || end_date);
      nCheckpoint := 2;
      If (sOp = 'PRJ' or sOp = 'DEV') Then
        v_query := 'TRUNCATE TABLE DEV_ALL_FREIGHT_F';
        EXECUTE IMMEDIATE v_query;
        COMMIT;
        
        If sFilterBy = 'PARENT' or sFilterBy IS NULL then
           OPEN c1Dev;
            ----DBMS_OUTPUT.PUT_LINE(sShary || '.' );
            LOOP
            FETCH c1Dev BULK COLLECT INTO l_data LIMIT p_array_size;
    
            FORALL i IN 1..l_data.COUNT
            ----DBMS_OUTPUT.PUT_LINE(l_data(10) || '.' );
            INSERT INTO DEV_ALL_FREIGHT_F VALUES l_data(i);
            --USING sCust;
    
            EXIT WHEN c1Dev%NOTFOUND;
    
            END LOOP;
            ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            CLOSE c1Dev;
            v_query2 :=  SQL%ROWCOUNT;
        ELSIF sFilterBy = 'RMDBL' then
         OPEN c2Dev;
            ----DBMS_OUTPUT.PUT_LINE(sShary || '.' );
            LOOP
            FETCH c2Dev BULK COLLECT INTO l_data LIMIT p_array_size;
    
            FORALL i IN 1..l_data.COUNT
            ----DBMS_OUTPUT.PUT_LINE(l_data(10) || '.' );
            INSERT INTO DEV_ALL_FREIGHT_F VALUES l_data(i);
            --USING sCust;
    
            EXIT WHEN c2Dev%NOTFOUND;
    
            END LOOP;
            ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            CLOSE c2Dev;
            v_query2 :=  SQL%ROWCOUNT;
        ELSIF sFilterBy = 'TERR'then
         OPEN c3Dev;
            ----DBMS_OUTPUT.PUT_LINE(sShary || '.' );
            LOOP
            FETCH c3Dev BULK COLLECT INTO l_data LIMIT p_array_size;
    
            FORALL i IN 1..l_data.COUNT
            ----DBMS_OUTPUT.PUT_LINE(l_data(10) || '.' );
            INSERT INTO DEV_ALL_FREIGHT_F VALUES l_data(i);
            --USING sCust;
    
            EXIT WHEN c3Dev%NOTFOUND;
    
            END LOOP;
            ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            CLOSE c3Dev;
            v_query2 :=  SQL%ROWCOUNT;
        ELSIF sFilterBy = 'AREA'then
          OPEN c4Dev;
            ----DBMS_OUTPUT.PUT_LINE(sShary || '.' );
            LOOP
            FETCH c4Dev BULK COLLECT INTO l_data LIMIT p_array_size;
    
            FORALL i IN 1..l_data.COUNT
            ----DBMS_OUTPUT.PUT_LINE(l_data(10) || '.' );
            INSERT INTO DEV_ALL_FREIGHT_F VALUES l_data(i);
            --USING sCust;
    
            EXIT WHEN c4Dev%NOTFOUND;
    
            END LOOP;
            ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            CLOSE c4Dev;
            v_query2 :=  SQL%ROWCOUNT;
      ELSE  
        
        nCheckpoint := 2;
         
      
         OPEN c1Dev;
            ----DBMS_OUTPUT.PUT_LINE(sShary || '.' );
            LOOP
            FETCH c1Dev BULK COLLECT INTO l_data LIMIT p_array_size;
    
            FORALL i IN 1..l_data.COUNT
            ----DBMS_OUTPUT.PUT_LINE(l_data(10) || '.' );
            INSERT INTO DEV_ALL_FREIGHT_F VALUES l_data(i);
            --USING sCust;
    
            EXIT WHEN c1Dev%NOTFOUND;
    
            END LOOP;
            ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            CLOSE c1Dev;
            v_query2 :=  SQL%ROWCOUNT;
       END IF; 
    Else
         v_query := 'TRUNCATE TABLE TMP_ALL_FREIGHT_F';
          EXECUTE IMMEDIATE v_query;
          COMMIT;
        If sFilterBy = 'PARENT'  or sFilterBy IS NULL  then
           OPEN c1;
            ----DBMS_OUTPUT.PUT_LINE(sShary || '.' );
            LOOP
            FETCH c1 BULK COLLECT INTO l_data LIMIT p_array_size;
    
            FORALL i IN 1..l_data.COUNT
            ----DBMS_OUTPUT.PUT_LINE(l_data(10) || '.' );
            INSERT INTO TMP_ALL_FREIGHT_F VALUES l_data(i);
            --USING sCust;
    
            EXIT WHEN c1%NOTFOUND;
    
            END LOOP;
            ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            CLOSE c1;
            v_query2 :=  SQL%ROWCOUNT;
        ELSIF sFilterBy = 'RMDBL' then
         OPEN c2;
            ----DBMS_OUTPUT.PUT_LINE(sShary || '.' );
            LOOP
            FETCH c2 BULK COLLECT INTO l_data LIMIT p_array_size;
    
            FORALL i IN 1..l_data.COUNT
            ----DBMS_OUTPUT.PUT_LINE(l_data(10) || '.' );
            INSERT INTO TMP_ALL_FREIGHT_F VALUES l_data(i);
            --USING sCust;
    
            EXIT WHEN c2%NOTFOUND;
    
            END LOOP;
            ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            CLOSE c2;
            v_query2 :=  SQL%ROWCOUNT;
        ELSIF sFilterBy = 'TERR' then
         OPEN c3;
            ----DBMS_OUTPUT.PUT_LINE(sShary || '.' );
            LOOP
            FETCH c3 BULK COLLECT INTO l_data LIMIT p_array_size;
    
            FORALL i IN 1..l_data.COUNT
            ----DBMS_OUTPUT.PUT_LINE(l_data(10) || '.' );
            INSERT INTO TMP_ALL_FREIGHT_F VALUES l_data(i);
            --USING sCust;
    
            EXIT WHEN c3%NOTFOUND;
    
            END LOOP;
            ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            CLOSE c3;
            v_query2 :=  SQL%ROWCOUNT;
        ELSIF sFilterBy = 'AREA'  then
          OPEN c4;
            ----DBMS_OUTPUT.PUT_LINE(sShary || '.' );
            LOOP
            FETCH c4 BULK COLLECT INTO l_data LIMIT p_array_size;
    
            FORALL i IN 1..l_data.COUNT
            ----DBMS_OUTPUT.PUT_LINE(l_data(10) || '.' );
            INSERT INTO TMP_ALL_FREIGHT_F VALUES l_data(i);
            --USING sCust;
    
            EXIT WHEN c4%NOTFOUND;
    
            END LOOP;
            ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            CLOSE c4;
            v_query2 :=  SQL%ROWCOUNT;
      ELSE  
        
        nCheckpoint := 2;
            OPEN c1;
            ----DBMS_OUTPUT.PUT_LINE(sShary || '.' );
            LOOP
            FETCH c1 BULK COLLECT INTO l_data LIMIT p_array_size;
    
            FORALL i IN 1..l_data.COUNT
            ----DBMS_OUTPUT.PUT_LINE(l_data(10) || '.' );
            INSERT INTO TMP_ALL_FREIGHT_F VALUES l_data(i);
            --USING sCust;
    
            EXIT WHEN c1%NOTFOUND;
    
            END LOOP;
            ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            CLOSE c1;
           --FOR i IN l_data.FIRST .. l_data.LAST LOOP
            ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          --END LOOP;
          v_query2 :=  SQL%ROWCOUNT;
       END IF; 
    End if;
    COMMIT;
  
      IF v_query2 > 0 THEN
       -- If F_IS_TABLE_EEMPTY('TMP_FREIGHT') > 0 Then
          --sFileName := sCustomerCode || '-F8_Z_EOM_RUN_FREIGHT' || startdate || '-TO-' || enddate || '.csv';
          v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
          If (sOp = 'PRJ' or sOp = 'DEV') Then
            EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'F8_Z_EOM_RUN_FREIGHT','DEV_ALL_FREIGHT_ALL','DEV_ALL_FREIGHT_F',v_time_taken,SYSTIMESTAMP,sCustomerCode);
             If (upper(SaveFreightFile_Y_OR_N) = 'Y') Then
              sFileName := sCustomerCode || '-F8_Z_EOM_RUN_FREIGHT-' || startdate || '-TO-' || enddate || '-RunOn-' || sFileTime || '.csv';
              Z2_TMP_FEES_TO_CSV(sFileName,'DEV_ALL_FREIGHT_F',sOp);
            End If;
            If (upper(Debug_Y_OR_N) = 'Y') then
              --Z2_TMP_FEES_TO_CSV(sFileName,'DEV_ALL_FREIGHT_F',sOp);
              DBMS_OUTPUT.PUT_LINE('F8_Z_EOM_RUN_FREIGHT for the date range '
              || startdate || ' -- ' || enddate || ' - ' || v_query2
              || ' records inserted into table DEV_ALL_FREIGHT_F in ' || round((dbms_utility.get_time-l_start)/100, 6)
              || ' Seconds...for customer ' || sCustomerCode || ' filtered by ' || sFilterBy );
            End If;
          Else
            EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'F8_Z_EOM_RUN_FREIGHT','TMP_ALL_FREIGHT_ALL','TMP_ALL_FREIGHT_F',v_time_taken,SYSTIMESTAMP,sCustomerCode);
              If (upper(SaveFreightFile_Y_OR_N) = 'Y') Then
                sFileName := sCustomerCode || '-F8_Z_EOM_RUN_FREIGHT-' || startdate || '-TO-' || enddate || '-RunOn-' || sFileTime || '.csv';
                Z2_TMP_FEES_TO_CSV(sFileName,'TMP_ALL_FREIGHT_F',sOp);
              End If;
            If (upper(Debug_Y_OR_N) = 'Y') then
                --Z2_TMP_FEES_TO_CSV(sFileName,'TMP_ALL_FREIGHT_F',sOp);
                DBMS_OUTPUT.PUT_LINE('F8_Z_EOM_RUN_FREIGHT for the date range '
                || startdate || ' -- ' || enddate || ' - ' || v_query2
                || ' records inserted into table TMP_ALL_FREIGHT_F in ' || round((dbms_utility.get_time-l_start)/100, 6)
                || ' Seconds...for customer ' || sCustomerCode || ' filtered by ' || sFilterBy );
              End If;
          End If;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('F8_Z_EOM_RUN_FREIGHT failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
        RAISE;
    END F8_Z_EOM_RUN_FREIGHT;
   
    /*   H1_EOM_STD_STOR_FEES Run this once for each customer   */
    /*   This gets all the Std Storage Related Data   */
    /*   Temp Tables Used   */
    /*   1. TMP_STOR_FEES   */
    /*   Prism Rate Field Used   */
    /*   A. RM_XX_FEE11 & RM_XX_FEE12   */
    
    /*REMOVE*/
    
    PROCEDURE H4_EOM_ALL_STOR_FEES_old (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
        ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
        ,sCustomerCode IN VARCHAR2 DEFAULT ''
        ,sAnalysis IN RM.RM_ANAL%TYPE DEFAULT ''
        ,sOp IN VARCHAR2
        ,p_dev_bool in boolean
        ,p_intercompany_bool in boolean
        ,Debug_Y_OR_N IN VARCHAR2 DEFAULT 'N'
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
      
       CURSOR cAnal
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
          f_get_fee('RM_XX_FEE11',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --shelf for fast moving
          f_get_fee('RM_XX_FEE12',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) !=0 THEN --pallet for slow moving if slow rate exists
         f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',sCustomerCode) !=0 THEN --shelf for slow moving if slow rate exists
          f_get_fee('RM_XX_FEE30',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) =0 THEN --pallet for slow moving if slow rate DOESN't exist, revert to normal charge
         f_get_fee('RM_XX_FEE11',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',sCustomerCode) =0 THEN --shelf for slow moving if slow rate DOESN't exist
          f_get_fee('RM_XX_FEE12',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        ELSE 999
        END AS "UnitPrice",
      CASE
        WHEN UPPER(l1.IL_NOTE_2) = 'YES'  AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --pallet for fast moving
          f_get_fee('RM_XX_FEE11',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --shelf for fast moving
          f_get_fee('RM_XX_FEE12',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) !=0 THEN --pallet for slow moving if slow rate exists
         f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',sCustomerCode) !=0 THEN --shelf for slow moving if slow rate exists
          f_get_fee('RM_XX_FEE30',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) =0 THEN --pallet for slow moving if slow rate DOESN't exist, revert to normal charge
         f_get_fee('RM_XX_FEE11',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',sCustomerCode) =0 THEN --shelf for slow moving if slow rate DOESN't exist
          f_get_fee('RM_XX_FEE12',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        ELSE 999
        END AS "OWUnitPrice",
      CASE
        WHEN UPPER(l1.IL_NOTE_2) = 'YES'  AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --pallet for fast moving
          f_get_fee('RM_XX_FEE11',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --shelf for fast moving
          f_get_fee('RM_XX_FEE12',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) !=0 THEN --pallet for slow moving if slow rate exists
         f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',sCustomerCode) !=0 THEN --shelf for slow moving if slow rate exists
          f_get_fee('RM_XX_FEE30',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) =0 THEN --pallet for slow moving if slow rate DOESN't exist, revert to normal charge
         f_get_fee('RM_XX_FEE11',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',sCustomerCode) =0 THEN --shelf for slow moving if slow rate DOESN't exist
          f_get_fee('RM_XX_FEE12',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        ELSE 999
        END AS "DExcl",
      CASE 
        WHEN UPPER(l1.IL_NOTE_2) = 'YES'  AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --pallet for fast moving
          (f_get_fee('RM_XX_FEE11',sCustomerCode) / tmp.NCOUNTOFSTOCKS) * 1.1
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --shelf for fast moving
          (f_get_fee('RM_XX_FEE12',sCustomerCode) / tmp.NCOUNTOFSTOCKS) * 1.1
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) !=0 THEN --pallet for slow moving if slow rate exists
          (f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) / tmp.NCOUNTOFSTOCKS) * 1.1
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',sCustomerCode) !=0 THEN --shelf for slow moving if slow rate exists
          (f_get_fee('RM_XX_FEE30',sCustomerCode) / tmp.NCOUNTOFSTOCKS) * 1.1
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) =0 THEN --pallet for slow moving if slow rate DOESN't exist, revert to normal charge
          (f_get_fee('RM_XX_FEE11',sCustomerCode) / tmp.NCOUNTOFSTOCKS) * 1.1
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',sCustomerCode) =0 THEN --shelf for slow moving if slow rate DOESN't exist
          (f_get_fee('RM_XX_FEE12',sCustomerCode) / tmp.NCOUNTOFSTOCKS) * 1.1
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
    INNER JOIN Tmp_Locn_Cnt_By_Cust tmp ON tmp.sLocn = l1.IL_LOCN  AND tmp.sCust = IM_CUST
   -- INNER JOIN  Tmp_Locn_Cnt_By_Cust tmp ON tmp.SLOCN = l1.IL_LOCN 
    INNER JOIN  Tmp_Group_Cust r ON r.sCust = IM_CUST
    WHERE n1.NA_EXT_TYPE = 1210067
    AND e.NE_AVAIL_ACTUAL >= '1'
    AND l1.IL_IN_LOCN NOT IN ('OBSOLETEMEL','OBSOLETESYD','PASTHISTORY', 'CANBERRA')
    AND e.NE_STATUS =  1
    AND e.NE_STRENGTH = 3

    --AND tmp.SCUST = sCustomerCode
   -- AND l1.IL_LOCN = 'S5B13-10'
    AND r.ANAL = sAnalysis
    GROUP BY l1.IL_LOCN,IM_CUST,IM_BRAND,IM_OWNED_By,IM_PROFILE,l1.IL_NOTE_2,l1.IL_LOCN,n1.NA_STOCK,
    tmp.NCOUNTOFSTOCKS,IM_REPORTING_PRICE,r.sGroupCust,IM_LEVEL_UNIT,IM_XX_COST_CENTRE01,IM_STOCK,IM_STD_COST,IM_LAST_COST;
      
      CURSOR c
      IS
    /* EOM Storage Fees */
      select IM_CUST AS "Customer",
      sCust AS "Parent",
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
          f_get_fee('RM_XX_FEE11',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --shelf for fast moving
          f_get_fee('RM_XX_FEE12',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) !=0 THEN --pallet for slow moving if slow rate exists
         f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',sCustomerCode) !=0 THEN --shelf for slow moving if slow rate exists
          f_get_fee('RM_XX_FEE30',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) =0 THEN --pallet for slow moving if slow rate DOESN't exist, revert to normal charge
         f_get_fee('RM_XX_FEE11',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',sCustomerCode) =0 THEN --shelf for slow moving if slow rate DOESN't exist
          f_get_fee('RM_XX_FEE12',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        ELSE 999
        END AS "UnitPrice",
      CASE
        WHEN UPPER(l1.IL_NOTE_2) = 'YES'  AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --pallet for fast moving
          f_get_fee('RM_XX_FEE11',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --shelf for fast moving
          f_get_fee('RM_XX_FEE12',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) !=0 THEN --pallet for slow moving if slow rate exists
         f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',sCustomerCode) !=0 THEN --shelf for slow moving if slow rate exists
          f_get_fee('RM_XX_FEE30',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) =0 THEN --pallet for slow moving if slow rate DOESN't exist, revert to normal charge
         f_get_fee('RM_XX_FEE11',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',sCustomerCode) =0 THEN --shelf for slow moving if slow rate DOESN't exist
          f_get_fee('RM_XX_FEE12',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        ELSE 999
        END AS "OWUnitPrice",
      CASE
        WHEN UPPER(l1.IL_NOTE_2) = 'YES'  AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --pallet for fast moving
          f_get_fee('RM_XX_FEE11',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --shelf for fast moving
          f_get_fee('RM_XX_FEE12',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) !=0 THEN --pallet for slow moving if slow rate exists
         f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',sCustomerCode) !=0 THEN --shelf for slow moving if slow rate exists
          f_get_fee('RM_XX_FEE30',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) =0 THEN --pallet for slow moving if slow rate DOESN't exist, revert to normal charge
         f_get_fee('RM_XX_FEE11',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',sCustomerCode) =0 THEN --shelf for slow moving if slow rate DOESN't exist
          f_get_fee('RM_XX_FEE12',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        ELSE 999
        END AS "DExcl",
      CASE 
        WHEN UPPER(l1.IL_NOTE_2) = 'YES'  AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --pallet for fast moving
          (f_get_fee('RM_XX_FEE11',sCustomerCode) / tmp.NCOUNTOFSTOCKS) * 1.1
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --shelf for fast moving
          (f_get_fee('RM_XX_FEE12',sCustomerCode) / tmp.NCOUNTOFSTOCKS) * 1.1
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) !=0 THEN --pallet for slow moving if slow rate exists
          (f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) / tmp.NCOUNTOFSTOCKS) * 1.1
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',sCustomerCode) !=0 THEN --shelf for slow moving if slow rate exists
          (f_get_fee('RM_XX_FEE30',sCustomerCode) / tmp.NCOUNTOFSTOCKS) * 1.1
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) =0 THEN --pallet for slow moving if slow rate DOESN't exist, revert to normal charge
          (f_get_fee('RM_XX_FEE11',sCustomerCode) / tmp.NCOUNTOFSTOCKS) * 1.1
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',sCustomerCode) =0 THEN --shelf for slow moving if slow rate DOESN't exist
          (f_get_fee('RM_XX_FEE12',sCustomerCode) / tmp.NCOUNTOFSTOCKS) * 1.1
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
    INNER JOIN Tmp_Locn_Cnt_By_Cust tmp ON tmp.sLocn = l1.IL_LOCN  AND tmp.sCust = IM_CUST
   -- INNER JOIN  Tmp_Locn_Cnt_By_Cust tmp ON tmp.SLOCN = l1.IL_LOCN 
   -- INNER JOIN  Tmp_Group_Cust r ON r.sCust = IM_CUST
    WHERE n1.NA_EXT_TYPE = 1210067
    AND e.NE_AVAIL_ACTUAL >= '1'
    AND l1.IL_IN_LOCN NOT IN ('OBSOLETEMEL','OBSOLETESYD','PASTHISTORY', 'CANBERRA')
    AND e.NE_STATUS =  1
    AND e.NE_STRENGTH = 3

   -- AND r.sGroupCust = sCustomerCode
   -- AND l1.IL_LOCN = 'S5B13-10'
   -- AND r.ANAL = sAnalysis
    GROUP BY l1.IL_LOCN,IM_CUST,IM_BRAND,IM_OWNED_By,IM_PROFILE,l1.IL_NOTE_2,l1.IL_LOCN,n1.NA_STOCK,
    tmp.NCOUNTOFSTOCKS,IM_REPORTING_PRICE,IM_LEVEL_UNIT,IM_XX_COST_CENTRE01,IM_STOCK,IM_STD_COST,IM_LAST_COST,tmp.sCust; --r.sGroupCust,

    
    CURSOR cDEV
      IS
    /* EOM Storage Fees */
      select IM_CUST AS "Customer",
      sCust AS "Parent",
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
          f_get_fee('RM_XX_FEE11',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --shelf for fast moving
          f_get_fee('RM_XX_FEE12',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) !=0 THEN --pallet for slow moving if slow rate exists
         f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',sCustomerCode) !=0 THEN --shelf for slow moving if slow rate exists
          f_get_fee('RM_XX_FEE30',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) =0 THEN --pallet for slow moving if slow rate DOESN't exist, revert to normal charge
         f_get_fee('RM_XX_FEE11',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',sCustomerCode) =0 THEN --shelf for slow moving if slow rate DOESN't exist
          f_get_fee('RM_XX_FEE12',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        ELSE 999
        END AS "UnitPrice",
      CASE
        WHEN UPPER(l1.IL_NOTE_2) = 'YES'  AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --pallet for fast moving
          f_get_fee('RM_XX_FEE11',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --shelf for fast moving
          f_get_fee('RM_XX_FEE12',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) !=0 THEN --pallet for slow moving if slow rate exists
         f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',sCustomerCode) !=0 THEN --shelf for slow moving if slow rate exists
          f_get_fee('RM_XX_FEE30',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) =0 THEN --pallet for slow moving if slow rate DOESN't exist, revert to normal charge
         f_get_fee('RM_XX_FEE11',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',sCustomerCode) =0 THEN --shelf for slow moving if slow rate DOESN't exist
          f_get_fee('RM_XX_FEE12',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        ELSE 999
        END AS "OWUnitPrice",
      CASE
        WHEN UPPER(l1.IL_NOTE_2) = 'YES'  AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --pallet for fast moving
          f_get_fee('RM_XX_FEE11',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --shelf for fast moving
          f_get_fee('RM_XX_FEE12',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) !=0 THEN --pallet for slow moving if slow rate exists
         f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',sCustomerCode) !=0 THEN --shelf for slow moving if slow rate exists
          f_get_fee('RM_XX_FEE30',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) =0 THEN --pallet for slow moving if slow rate DOESN't exist, revert to normal charge
         f_get_fee('RM_XX_FEE11',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',sCustomerCode) =0 THEN --shelf for slow moving if slow rate DOESN't exist
          f_get_fee('RM_XX_FEE12',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        ELSE 999
        END AS "DExcl",
      CASE 
        WHEN UPPER(l1.IL_NOTE_2) = 'YES'  AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --pallet for fast moving
          (f_get_fee('RM_XX_FEE11',sCustomerCode) / tmp.NCOUNTOFSTOCKS) * 1.1
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --shelf for fast moving
          (f_get_fee('RM_XX_FEE12',sCustomerCode) / tmp.NCOUNTOFSTOCKS) * 1.1
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) !=0 THEN --pallet for slow moving if slow rate exists
          (f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) / tmp.NCOUNTOFSTOCKS) * 1.1
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',sCustomerCode) !=0 THEN --shelf for slow moving if slow rate exists
          (f_get_fee('RM_XX_FEE30',sCustomerCode) / tmp.NCOUNTOFSTOCKS) * 1.1
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) =0 THEN --pallet for slow moving if slow rate DOESN't exist, revert to normal charge
          (f_get_fee('RM_XX_FEE11',sCustomerCode) / tmp.NCOUNTOFSTOCKS) * 1.1
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',sCustomerCode) =0 THEN --shelf for slow moving if slow rate DOESN't exist
          (f_get_fee('RM_XX_FEE12',sCustomerCode) / tmp.NCOUNTOFSTOCKS) * 1.1
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
    INNER JOIN Dev_Locn_Cnt_By_Cust tmp ON tmp.sLocn = l1.IL_LOCN  AND tmp.sCust = IM_CUST
    --INNER JOIN  Dev_Locn_Cnt_By_Cust tmp ON tmp.SLOCN = l1.IL_LOCN 
   -- INNER JOIN  Dev_Group_Cust r ON r.sCust = IM_CUST
    WHERE n1.NA_EXT_TYPE = 1210067
    AND e.NE_AVAIL_ACTUAL >= '1'
    AND l1.IL_IN_LOCN NOT IN ('OBSOLETEMEL','OBSOLETESYD','PASTHISTORY', 'CANBERRA')
    AND e.NE_STATUS =  1
    AND e.NE_STRENGTH = 3

    --AND r.sGroupCust = sCustomerCode
   -- AND l1.IL_LOCN = 'S5B13-10'
    --AND r.ANAL = sAnalysis
    GROUP BY l1.IL_LOCN,IM_CUST,IM_BRAND,IM_OWNED_By,IM_PROFILE,l1.IL_NOTE_2,l1.IL_LOCN,n1.NA_STOCK,
    tmp.NCOUNTOFSTOCKS,IM_REPORTING_PRICE,IM_LEVEL_UNIT,IM_XX_COST_CENTRE01,IM_STOCK,IM_STD_COST,IM_LAST_COST,tmp.sCust; --r.sGroupCust,
    
     CURSOR cDEVAnal
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
          f_get_fee('RM_XX_FEE11',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --shelf for fast moving
          f_get_fee('RM_XX_FEE12',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) !=0 THEN --pallet for slow moving if slow rate exists
         f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',sCustomerCode) !=0 THEN --shelf for slow moving if slow rate exists
          f_get_fee('RM_XX_FEE30',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) =0 THEN --pallet for slow moving if slow rate DOESN't exist, revert to normal charge
         f_get_fee('RM_XX_FEE11',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',sCustomerCode) =0 THEN --shelf for slow moving if slow rate DOESN't exist
          f_get_fee('RM_XX_FEE12',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        ELSE 999
        END AS "UnitPrice",
      CASE
        WHEN UPPER(l1.IL_NOTE_2) = 'YES'  AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --pallet for fast moving
          f_get_fee('RM_XX_FEE11',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --shelf for fast moving
          f_get_fee('RM_XX_FEE12',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) !=0 THEN --pallet for slow moving if slow rate exists
         f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',sCustomerCode) !=0 THEN --shelf for slow moving if slow rate exists
          f_get_fee('RM_XX_FEE30',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) =0 THEN --pallet for slow moving if slow rate DOESN't exist, revert to normal charge
         f_get_fee('RM_XX_FEE11',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',sCustomerCode) =0 THEN --shelf for slow moving if slow rate DOESN't exist
          f_get_fee('RM_XX_FEE12',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        ELSE 999
        END AS "OWUnitPrice",
      CASE
        WHEN UPPER(l1.IL_NOTE_2) = 'YES'  AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --pallet for fast moving
          f_get_fee('RM_XX_FEE11',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --shelf for fast moving
          f_get_fee('RM_XX_FEE12',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) !=0 THEN --pallet for slow moving if slow rate exists
         f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',sCustomerCode) !=0 THEN --shelf for slow moving if slow rate exists
          f_get_fee('RM_XX_FEE30',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) =0 THEN --pallet for slow moving if slow rate DOESN't exist, revert to normal charge
         f_get_fee('RM_XX_FEE11',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',sCustomerCode) =0 THEN --shelf for slow moving if slow rate DOESN't exist
          f_get_fee('RM_XX_FEE12',sCustomerCode) / tmp.NCOUNTOFSTOCKS
        ELSE 999
        END AS "DExcl",
      CASE 
        WHEN UPPER(l1.IL_NOTE_2) = 'YES'  AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --pallet for fast moving
          (f_get_fee('RM_XX_FEE11',sCustomerCode) / tmp.NCOUNTOFSTOCKS) * 1.1
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) != 'SLOW' THEN --shelf for fast moving
          (f_get_fee('RM_XX_FEE12',sCustomerCode) / tmp.NCOUNTOFSTOCKS) * 1.1
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) !=0 THEN --pallet for slow moving if slow rate exists
          (f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) / tmp.NCOUNTOFSTOCKS) * 1.1
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',sCustomerCode) !=0 THEN --shelf for slow moving if slow rate exists
          (f_get_fee('RM_XX_FEE30',sCustomerCode) / tmp.NCOUNTOFSTOCKS) * 1.1
        WHEN UPPER(l1.IL_NOTE_2) = 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_SPARE_CHAR_3',sCustomerCode) =0 THEN --pallet for slow moving if slow rate DOESN't exist, revert to normal charge
          (f_get_fee('RM_XX_FEE11',sCustomerCode) / tmp.NCOUNTOFSTOCKS) * 1.1
        WHEN UPPER(l1.IL_NOTE_2) != 'YES' AND F_CONFIRM_SLOW_MOVER(IM_STOCK) = 'SLOW' AND f_get_fee('RM_XX_FEE30',sCustomerCode) =0 THEN --shelf for slow moving if slow rate DOESN't exist
          (f_get_fee('RM_XX_FEE12',sCustomerCode) / tmp.NCOUNTOFSTOCKS) * 1.1
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
    INNER JOIN Dev_Locn_Cnt_By_Cust tmp ON tmp.sLocn = l1.IL_LOCN  AND tmp.sCust = IM_CUST
    --INNER JOIN  Dev_Locn_Cnt_By_Cust tmp ON tmp.SLOCN = l1.IL_LOCN 
    INNER JOIN  Dev_Group_Cust r ON r.sCust = IM_CUST
    WHERE n1.NA_EXT_TYPE = 1210067
    AND e.NE_AVAIL_ACTUAL >= '1'
    AND l1.IL_IN_LOCN NOT IN ('OBSOLETEMEL','OBSOLETESYD','PASTHISTORY', 'CANBERRA')
    AND e.NE_STATUS =  1
    AND e.NE_STRENGTH = 3

    --AND tmp.SCUST = sCustomerCode
   -- AND l1.IL_LOCN = 'S5B13-10'
    AND r.ANAL = sAnalysis
    GROUP BY l1.IL_LOCN,IM_CUST,IM_BRAND,IM_OWNED_By,IM_PROFILE,l1.IL_NOTE_2,l1.IL_LOCN,n1.NA_STOCK,
    tmp.NCOUNTOFSTOCKS,IM_REPORTING_PRICE,r.sGroupCust,IM_LEVEL_UNIT,IM_XX_COST_CENTRE01,IM_STOCK,IM_STD_COST,IM_LAST_COST;
  
    QueryTable VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode}';
    sCust_Rates RM.RM_XX_FEE11%TYPE;
    QueryTable2 VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode}';
    sCust_Rates2 RM.RM_XX_FEE12%TYPE;
    l_start number default dbms_utility.get_time;
    BEGIN
    
    
    
    nCheckpoint := 11;
    
            
    
    nCheckpoint := 2;      
    If ((sOp = 'PRJ' or sOp = 'DEV') AND (sAnalysis IS NULL)) Then
          v_query := 'TRUNCATE TABLE DEV_STOR_ALL_FEES';
          EXECUTE IMMEDIATE v_query;
          
          OPEN cDEV;
          ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
          LOOP
          FETCH cDEV BULK COLLECT INTO l_data LIMIT p_array_size;

          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO DEV_STOR_ALL_FEES VALUES l_data(i);
          --USING sCust;

          EXIT WHEN cDEV%NOTFOUND;

          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE cDEV;
        -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
          ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        --END LOOP;
        DBMS_OUTPUT.PUT_LINE('finished storage for' || sCustomerCode || ' using cDEV cursor.' );
    ElsIf ((sOp = 'PRJ' or sOp = 'DEV') AND (sAnalysis IS NOT NULL)) Then
          v_query := 'TRUNCATE TABLE DEV_STOR_ALL_FEES';
          EXECUTE IMMEDIATE v_query;
          
          OPEN cDEVAnal;
          ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
          LOOP
          FETCH cDEVAnal BULK COLLECT INTO l_data LIMIT p_array_size;

          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO DEV_STOR_ALL_FEES VALUES l_data(i);
          --USING sCust;

          EXIT WHEN cDEVAnal%NOTFOUND;

          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE cDEVAnal;
        -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
          ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        --END LOOP;
        DBMS_OUTPUT.PUT_LINE('finished storage for' || sCustomerCode || ' using cDEVAnal cursor.' );
    ElsIf ((sOp != 'PRJ' or sOp != 'DEV') AND (sAnalysis IS NULL)) Then
        v_query := 'TRUNCATE TABLE TMP_STOR_ALL_FEES';
        EXECUTE IMMEDIATE v_query;
        
        OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;

          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO TMP_STOR_ALL_FEES VALUES l_data(i);
          --USING sCust;

          EXIT WHEN c%NOTFOUND;

          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
        -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
          ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        --END LOOP;
        DBMS_OUTPUT.PUT_LINE('finished storage for' || sCustomerCode || ' using c cursor.' );
    ElsIf ((sOp != 'PRJ' or sOp != 'DEV') AND (sAnalysis IS NOT NULL)) Then
        v_query := 'TRUNCATE TABLE TMP_STOR_ALL_FEES';
        EXECUTE IMMEDIATE v_query;
        
        OPEN cAnal;
          ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
          LOOP
          FETCH cAnal BULK COLLECT INTO l_data LIMIT p_array_size;

          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO TMP_STOR_ALL_FEES VALUES l_data(i);
          --USING sCust;

          EXIT WHEN cAnal%NOTFOUND;

          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE cAnal;
        -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
          ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        --END LOOP;
        DBMS_OUTPUT.PUT_LINE('finished storage for' || sCustomerCode || ' using canal cursor.' );
    Else
      DBMS_OUTPUT.PUT_LINE('NO SELECTIONS for storage for ' || sCustomerCode || ' using canal cursor. sOp is ' || sOp || ' and sAnalysis is ' || sAnalysis );
    End If;
        v_query2 :=  SQL%ROWCOUNT;
        COMMIT;
        If (sOp = 'PRJ' or sOp = 'DEV') Then
          If F_IS_TABLE_EEMPTY('DEV_STOR_ALL_FEES') > 0 Then
    
            v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
            EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'H4A_EOM_ALL_STOR_FEES','IL','DEV_STOR_ALL_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
            sFileName := sCustomerCode || '-H4A_EOM_ALL_STOR_FEES-' || startdate || '-TO-' || enddate || '-RunOn-' || sFileTime ||  '.csv';
            --Z2_TMP_FEES_TO_CSV(sFileName,'TMP_STOR_ALL_FEES');
            ----DBMS_OUTPUT.PUT_LINE('Z2_TMP_FEES_TO_CSV for ' || sFileName || '.' );
            --COMMIT;
            --DBMS_OUTPUT.PUT_LINE('H4A_EOM_ALL_STOR_FEES Fees for the date range '
                --|| startdate || ' -- ' || enddate || ' - ' || v_query2 || ' records inserted into table TMP_ALL_STOR_FEES in ' || (round((dbms_utility.get_time-l_start)/100, 6) ||
               -- ' Seconds...for customer ' || sCustomerCode ));
      
          --Else
            --DBMS_OUTPUT.PUT_LINE('H4A_EOM_ALL_STOR_FEES Std Shelf Storage Fees rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
            --' Seconds...for customer ' || sCustomerCode);
          END IF;
        Else
          If F_IS_TABLE_EEMPTY('TMP_STOR_ALL_FEES') > 0 Then
    
            v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
            EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'H4A_EOM_ALL_STOR_FEES','IL','TMP_STOR_ALL_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
            sFileName := sCustomerCode || '-H4A_EOM_ALL_STOR_FEES-' || startdate || '-TO-' || enddate || '-RunOn-' || sFileTime ||  '.csv';
           -- Z2_TMP_FEES_TO_CSV(sFileName,'TMP_STOR_ALL_FEES');
            DBMS_OUTPUT.PUT_LINE('Z2_TMP_FEES_TO_CSV for ' || sFileName || '.' );
            --COMMIT;
            --DBMS_OUTPUT.PUT_LINE('H4A_EOM_ALL_STOR_FEES Fees for the date range '
                --|| startdate || ' -- ' || enddate || ' - ' || v_query2 || ' records inserted into table TMP_ALL_STOR_FEES in ' || (round((dbms_utility.get_time-l_start)/100, 6) ||
               -- ' Seconds...for customer ' || sCustomerCode ));
      
          --Else
            --DBMS_OUTPUT.PUT_LINE('H4A_EOM_ALL_STOR_FEES Std Shelf Storage Fees rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
            --' Seconds...for customer ' || sCustomerCode);
          END IF;
        End If;
          --COMMIT;
          --palett
   
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('H_STOR_FEES_B_FEES failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
  
        RAISE;
  
    END H4_EOM_ALL_STOR_FEES_old;
    
    
     /*   H1_EOM_STD_STOR_FEES Run this once for each customer   */
    /*   This gets all the Std Storage Related Data   */
    /*   Temp Tables Used   */
    /*   1. TMP_STOR_FEES   */
    /*   Prism Rate Field Used   */
    /*   A. RM_XX_FEE11 null   */
    PROCEDURE H_STOR_FEES_A (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
        ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
        ,sCustomerCode IN VARCHAR2
        ,sAnalysis IN RM.RM_ANAL%TYPE
        ,sOp IN VARCHAR2
        ,Debug_Y_OR_N IN VARCHAR2 DEFAULT 'N'
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
      r.ANAL AS    WaiveFee,
      NULL As   Cost,
      NULL AS PaymentType,NULL,NULL,NULL,NULL
  
    FROM NI n1 INNER JOIN IM ON IM_STOCK = n1.NI_STOCK AND IM_CUST = sCustomerCode
    INNER JOIN IL l1 ON l1.IL_LOCN = n1.NI_LOCN
    INNER JOIN Tmp_Locn_Cnt_By_Cust tmp ON tmp.SLOCN = l1.IL_LOCN
    LEFT JOIN Tmp_Group_Cust r ON r.sCust = sCustomerCode
    WHERE  IM_ACTIVE = 1
    AND n1.NI_AVAIL_ACTUAL >= '1'
    AND n1.NI_STATUS <> 0
    AND tmp.SCUST = sCustomerCode
    GROUP BY l1.IL_LOCN,IM_CUST,IM_BRAND,IM_OWNED_By,IM_PROFILE,l1.IL_NOTE_2,n1.NI_LOCN,n1.NI_STOCK,r.ANAL,
    tmp.NCOUNTOFSTOCKS,IM_REPORTING_PRICE,r.sGroupCust,IM_LEVEL_UNIT,IM_XX_COST_CENTRE01,IM_STOCK,IM_STD_COST,IM_LAST_COST;

    
     CURSOR canal
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
      r.ANAL AS    WaiveFee,
      NULL As   Cost,
      NULL AS PaymentType,NULL,NULL,NULL,NULL
  
    FROM NI n1 INNER JOIN IM ON IM_STOCK = n1.NI_STOCK --AND IM_CUST = tmp.SCUST
    INNER JOIN IL l1 ON l1.IL_LOCN = n1.NI_LOCN
    INNER JOIN Tmp_Locn_Cnt_By_Cust tmp ON tmp.SLOCN = l1.IL_LOCN
    LEFT JOIN Tmp_Group_Cust r ON r.sCust = tmp.SCUST
    WHERE  IM_ACTIVE = 1
    AND n1.NI_AVAIL_ACTUAL >= '1'
    AND n1.NI_STATUS <> 0
    --AND tmp.SCUST = sCustomerCode
    AND   tmp.SCUST IN (SELECT RM_CUST FROM RM WHERE RM_ANAL = sAnalysis AND RM_TYPE = 0 AND RM_ACTIVE = 1 )
    GROUP BY l1.IL_LOCN,IM_CUST,IM_BRAND,IM_OWNED_By,IM_PROFILE,l1.IL_NOTE_2,n1.NI_LOCN,n1.NI_STOCK,r.ANAL,
    tmp.NCOUNTOFSTOCKS,IM_REPORTING_PRICE,r.sGroupCust,IM_LEVEL_UNIT,IM_XX_COST_CENTRE01,IM_STOCK,IM_STD_COST,IM_LAST_COST;
    
    
    
      CURSOR canalDev
      IS
    /* EOM Storage Fees */
      select IM_CUST AS "Customer",
      r.sGroupCust AS "Parent",
      r.ANAL     AS "CostCentre",
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
      r.ANAL AS    WaiveFee,
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
    AND   tmp.SCUST IN (SELECT RM_CUST FROM RM WHERE RM_ANAL = sAnalysis AND RM_TYPE = 0 AND RM_ACTIVE = 1 )
    GROUP BY l1.IL_LOCN,IM_CUST,IM_BRAND,IM_OWNED_By,IM_PROFILE,l1.IL_NOTE_2,n1.NI_LOCN,n1.NI_STOCK,r.ANAL,
    tmp.NCOUNTOFSTOCKS,IM_REPORTING_PRICE,r.sGroupCust,IM_LEVEL_UNIT,IM_XX_COST_CENTRE01,IM_STOCK,IM_STD_COST,IM_LAST_COST;
    
    CURSOR cDEV
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
      r.ANAL AS    WaiveFee,
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
    GROUP BY l1.IL_LOCN,IM_CUST,IM_BRAND,IM_OWNED_By,IM_PROFILE,l1.IL_NOTE_2,n1.NI_LOCN,n1.NI_STOCK,r.ANAL,
    tmp.NCOUNTOFSTOCKS,IM_REPORTING_PRICE,r.sGroupCust,IM_LEVEL_UNIT,IM_XX_COST_CENTRE01,IM_STOCK,IM_STD_COST,IM_LAST_COST;
  
    QueryTable VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode}';
    sCust_Rates RM.RM_XX_FEE11%TYPE;
    QueryTable2 VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode}';
    sCust_Rates2 RM.RM_XX_FEE12%TYPE;
    l_start number default dbms_utility.get_time;
    BEGIN
    
    
    
    nCheckpoint := 11;
    
            
    
    nCheckpoint := 2;      
    If (sOp = 'PRJ' or sOp = 'DEV') Then
          DBMS_OUTPUT.PUT_LINE(sOp || ' - . And sAnalysis is ' || sAnalysis );
          v_query := 'TRUNCATE TABLE DEV_STOR_ALL_FEES';
          EXECUTE IMMEDIATE v_query;
          If (sAnalysis != '') Then
            OPEN canalDev;
            ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
            LOOP
            FETCH canalDev BULK COLLECT INTO l_data LIMIT p_array_size;
  
            FORALL i IN 1..l_data.COUNT
            ----DBMS_OUTPUT.PUT_LINE(i || '.' );
            INSERT INTO DEV_STOR_ALL_FEES VALUES l_data(i);
            --USING sCust;
  
            EXIT WHEN canalDev%NOTFOUND;
  
            END LOOP;
            DBMS_OUTPUT.PUT_LINE(sAnalysis || ' - .' );
            CLOSE canalDev;
          Else
           OPEN cDEV;
            ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
            LOOP
            FETCH cDEV BULK COLLECT INTO l_data LIMIT p_array_size;
  
            FORALL i IN 1..l_data.COUNT
            ----DBMS_OUTPUT.PUT_LINE(i || '.' );
            INSERT INTO DEV_STOR_ALL_FEES VALUES l_data(i);
            --USING sCust;
  
            EXIT WHEN cDEV%NOTFOUND;
  
            END LOOP;
           -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            CLOSE cDEV;
          End If;
        -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
          ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        --END LOOP;
    Else
        v_query := 'TRUNCATE TABLE TMP_STOR_ALL_FEES';
        EXECUTE IMMEDIATE v_query;
          If (sAnalysis != '') Then
            OPEN canal;
            ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
            LOOP
            FETCH canal BULK COLLECT INTO l_data LIMIT p_array_size;
  
            FORALL i IN 1..l_data.COUNT
            ----DBMS_OUTPUT.PUT_LINE(i || '.' );
            INSERT INTO TMP_STOR_ALL_FEES VALUES l_data(i);
            --USING sCust;
  
            EXIT WHEN canal%NOTFOUND;
  
            END LOOP;
           -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            CLOSE canal;
          Else
            OPEN c;
              ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
              LOOP
              FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
    
              FORALL i IN 1..l_data.COUNT
              ----DBMS_OUTPUT.PUT_LINE(i || '.' );
              INSERT INTO TMP_STOR_ALL_FEES VALUES l_data(i);
              --USING sCust;
    
              EXIT WHEN c%NOTFOUND;
    
              END LOOP;
             -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
              CLOSE c;
            End If;
        -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
          ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        --END LOOP;
    End If;
        v_query2 :=  SQL%ROWCOUNT;
        COMMIT;
        If (sOp = 'PRJ' or sOp = 'DEV') Then
          If F_IS_TABLE_EEMPTY('DEV_STOR_ALL_FEES') > 0 Then
    
            v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
            EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'H4A_EOM_ALL_STOR_FEES','IL','DEV_STOR_ALL_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
            sFileName := sCustomerCode || '-H4A_EOM_ALL_STOR_FEES-' || startdate || '-TO-' || enddate || '-RunOn-' || sFileTime ||  '.csv';
            --Z2_TMP_FEES_TO_CSV(sFileName,'TMP_STOR_ALL_FEES');
            ----DBMS_OUTPUT.PUT_LINE('Z2_TMP_FEES_TO_CSV for ' || sFileName || '.' );
            --COMMIT;
            DBMS_OUTPUT.PUT_LINE('H4A_EOM_ALL_STOR_FEES Fees for the date range '
                || startdate || ' -- ' || enddate || ' - ' || v_query2 || ' records inserted into table TMP_ALL_STOR_FEES in ' || (round((dbms_utility.get_time-l_start)/100, 6) ||
                ' Seconds...for customer ' || sCustomerCode ));
      
          --Else
            --DBMS_OUTPUT.PUT_LINE('H4A_EOM_ALL_STOR_FEES Std Shelf Storage Fees rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
            --' Seconds...for customer ' || sCustomerCode);
          Else
            DBMS_OUTPUT.PUT_LINE('H4A_EOM_ALL_STOR_FEES Fees FAILED for the date range '
                || startdate || ' -- ' || enddate || ' - ' || v_query2 || ' records inserted into table TMP_ALL_STOR_FEES in ' || (round((dbms_utility.get_time-l_start)/100, 6) ||
                ' Seconds...for customer ' || sCustomerCode ));
          END IF;
        Else
          If F_IS_TABLE_EEMPTY('TMP_STOR_ALL_FEES') > 0 Then
    
            v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
            EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'H4A_EOM_ALL_STOR_FEES','IL','TMP_STOR_ALL_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
            sFileName := sCustomerCode || '-H4A_EOM_ALL_STOR_FEES-' || startdate || '-TO-' || enddate || '-RunOn-' || sFileTime ||  '.csv';
            --Z2_TMP_FEES_TO_CSV(sFileName,'TMP_STOR_ALL_FEES');
            ----DBMS_OUTPUT.PUT_LINE('Z2_TMP_FEES_TO_CSV for ' || sFileName || '.' );
            --COMMIT;
            --DBMS_OUTPUT.PUT_LINE('H4A_EOM_ALL_STOR_FEES Fees for the date range '
                --|| startdate || ' -- ' || enddate || ' - ' || v_query2 || ' records inserted into table TMP_ALL_STOR_FEES in ' || (round((dbms_utility.get_time-l_start)/100, 6) ||
               -- ' Seconds...for customer ' || sCustomerCode ));
      
          --Else
            --DBMS_OUTPUT.PUT_LINE('H4A_EOM_ALL_STOR_FEES Std Shelf Storage Fees rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
            --' Seconds...for customer ' || sCustomerCode);
          END IF;
        End If;
          --COMMIT;
          --palett
   
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('H_STOR_FEES_A failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
  
        RAISE;
  
    END H_STOR_FEES_A;
  
  
    /*   H1_EOM_STD_STOR_FEES Run this once for each customer   */
    /*   This gets all the Std Storage Related Data   */
    /*   Temp Tables Used   */
    /*   1. TMP_STOR_FEES   */
    /*   Prism Rate Field Used   */
    /*   A. RM_XX_FEE11 & RM_XX_FEE12   */
    PROCEDURE H_STOR_FEES_B (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
        ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
        ,sCustomerCode IN VARCHAR2
        ,sAnalysis IN RM.RM_ANAL%TYPE
        ,sFilterBy IN VARCHAR2
        ,sOp IN VARCHAR2
        ,Debug_Y_OR_N IN VARCHAR2 DEFAULT 'N'
        ,SaveStorageFile_Y_OR_N IN VARCHAR2 DEFAULT 'N'
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
      
        /* EOM Storage Fees */
        --If (sOp = 'PRJ' or sOp = 'DEV') Then
          CURSOR c
          IS
          select *
          FROM DEV_STOR_ALL_FEES t;
         -- WHERE  t.Customer = sCustomerCode OR t.parent = sCustomerCode;
          
          CURSOR c1
          IS
          /* EOM Storage Fees */
          select *
          FROM DEV_STOR_ALL_FEES t
          WHERE  t.Customer = sCustomerCode OR t.parent = sCustomerCode
          OR t.Customer = 'CGU' OR t.parent = 'CGU';
          
       -- Else
          CURSOR c2
          IS
          select *
          FROM TMP_STOR_ALL_FEES t
          WHERE  t.Customer = sCustomerCode OR t.parent = sCustomerCode;
          
          CURSOR c3
          IS
          /* EOM Storage Fees */
          select *
          FROM TMP_STOR_ALL_FEES t
          WHERE  t.Customer = sCustomerCode OR t.parent = sCustomerCode
          OR t.Customer = 'CGU' OR t.parent = 'CGU';
          
        --End If;
     
      
   -- QueryTable VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode}';
    --sCust_Rates RM.RM_XX_FEE11%TYPE;
    --QueryTable2 VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode}';
   -- sCust_Rates2 RM.RM_XX_FEE12%TYPE;
    l_start number default dbms_utility.get_time;
    BEGIN
    
    
    
    --nCheckpoint := 11;
    
            
    
          
  
          nCheckpoint := 2;
          If (sOp = 'PRJ' or sOp = 'DEV') Then
            v_query := 'TRUNCATE TABLE DEV_STOR_FEES';
            EXECUTE IMMEDIATE v_query;
            If (sCustomerCode != 'IAG') Then
                OPEN c;
                ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
                LOOP
                FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
    
                FORALL i IN 1..l_data.COUNT
                ----DBMS_OUTPUT.PUT_LINE(i || '.' );
                INSERT INTO DEV_STOR_FEES VALUES l_data(i);
                --USING sCust;
    
                EXIT WHEN c%NOTFOUND;
    
                END LOOP;
               -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
                CLOSE c;
              -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
                ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
              --END LOOP;
              Else
                 OPEN c1;
                ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
                LOOP
                FETCH c1 BULK COLLECT INTO l_data LIMIT p_array_size;
    
                FORALL i IN 1..l_data.COUNT
                ----DBMS_OUTPUT.PUT_LINE(i || '.' );
                INSERT INTO DEV_STOR_FEES VALUES l_data(i);
                --USING sCust;
    
                EXIT WHEN c1%NOTFOUND;
    
                END LOOP;
               -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
                CLOSE c1;
              -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
                ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
              --END LOOP;
              End If;
            Else
              v_query := 'TRUNCATE TABLE TMP_STOR_FEES';
              EXECUTE IMMEDIATE v_query;
              If (sCustomerCode != 'IAG') Then
              OPEN c2;
              ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
              LOOP
              FETCH c2 BULK COLLECT INTO l_data LIMIT p_array_size;
  
              FORALL i IN 1..l_data.COUNT
              ----DBMS_OUTPUT.PUT_LINE(i || '.' );
              INSERT INTO TMP_STOR_FEES VALUES l_data(i);
              --USING sCust;
  
              EXIT WHEN c2%NOTFOUND;
  
              END LOOP;
             -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
              CLOSE c2;
            -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
              ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            --END LOOP;
            Else
               OPEN c3;
              ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
              LOOP
              FETCH c3 BULK COLLECT INTO l_data LIMIT p_array_size;
  
              FORALL i IN 1..l_data.COUNT
              ----DBMS_OUTPUT.PUT_LINE(i || '.' );
              INSERT INTO TMP_STOR_FEES VALUES l_data(i);
              --USING sCust;
  
              EXIT WHEN c3%NOTFOUND;
  
              END LOOP;
             -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
              CLOSE c3;
            -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
              ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            --END LOOP;
            End If;
          End If;
        v_query2 :=  SQL%ROWCOUNT;
        COMMIT;
        If (sOp = 'PRJ' or sOp = 'DEV') Then
          If F_IS_TABLE_EEMPTY('DEV_STOR_FEES') > 0 Then
          --add another quick data check to ensure the source data is ok
    
            v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
            EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'H_STOR_FEES_B','IL','DEV_STOR_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
            sFileName := sCustomerCode || '-H_STOR_FEES_B-' || startdate || '-TO-' || enddate || '-RunOn-' || sFileTime ||  '.csv';
            If (upper(SaveStorageFile_Y_OR_N) = 'Y') Then
              Z2_TMP_FEES_TO_CSV(sFileName,'DEV_STOR_FEES',sOp);
            End If;
            --DBMS_OUTPUT.PUT_LINE('Z2_TMP_FEES_TO_CSV for ' || sFileName || '.' );
            --uncomment above if you want to produce an exported file for all storage, about 5MB every time.
            --COMMIT;
            --DBMS_OUTPUT.PUT_LINE('H_STOR_FEES_B Fees for the date range '
                --|| startdate || ' -- ' || enddate || ' - ' || v_query2 || ' records inserted into table TMP_STOR_FEES in ' || (round((dbms_utility.get_time-l_start)/100, 6) ||
               -- ' Seconds...for customer ' || sCustomerCode ));
      
          --Else
            --DBMS_OUTPUT.PUT_LINE('H_STOR_FEES_B Std Shelf Storage Fees rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
           -- ' Seconds...for customer ' || sCustomerCode);
          END IF;
        Else
          If F_IS_TABLE_EEMPTY('TMP_STOR_FEES') > 0 Then
          --add another quick data check to ensure the source data is ok
    
            v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
            EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'H_STOR_FEES_B','IL','TMP_STOR_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
            sFileName := sCustomerCode || '-H_STOR_FEES_B-' || startdate || '-TO-' || enddate || '-RunOn-' || sFileTime ||  '.csv';
            
            If (upper(SaveStorageFile_Y_OR_N) = 'Y') Then
              Z2_TMP_FEES_TO_CSV(sFileName,'TMP_STOR_FEES',sOp);
            End If;
            --Z2_TMP_FEES_TO_CSV(sFileName,'TMP_STOR_FEES',sOp);
            --DBMS_OUTPUT.PUT_LINE('Z2_TMP_FEES_TO_CSV for ' || sFileName || '.' );
            --uncomment above if you want to produce an exported file for all storage, about 5MB every time.
            --COMMIT;
            --DBMS_OUTPUT.PUT_LINE('H_STOR_FEES_B Fees for the date range '
                --|| startdate || ' -- ' || enddate || ' - ' || v_query2 || ' records inserted into table TMP_STOR_FEES in ' || (round((dbms_utility.get_time-l_start)/100, 6) ||
               -- ' Seconds...for customer ' || sCustomerCode ));
      
          --Else
            --DBMS_OUTPUT.PUT_LINE('H_STOR_FEES_B Std Shelf Storage Fees rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
           -- ' Seconds...for customer ' || sCustomerCode);
          END IF;
        End If;
          --COMMIT;
          --palett
   
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('H_STOR_FEES_A failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
  
        RAISE;
  
    END H_STOR_FEES_B;
      
    /*   E0_ALL_ORD_FEES Run this once for each customer   */
    /*   This gets all the Order Related Data   */
    /*   Temp Tables Used   */
    /*   1. TMP_ALL_ORD_FEES   */
    /*   Prism Rate Fields Used   */
    /*   A. RM_XX_FEE01,RM_XX_FEE02,RM_XX_FEE03,RM_XX_FEE07   */
    PROCEDURE E0_ALL_ORD_FEES (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
        ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
        ,sCustomerCode IN VARCHAR2
        ,sAnalysis IN RM.RM_ANAL%TYPE
        ,sFilterBy IN VARCHAR2
        ,sOp IN VARCHAR2
        ,Debug_Y_OR_N IN VARCHAR2 DEFAULT 'N'
      )
      IS
      TYPE ARRAY IS TABLE OF TMP_ALL_ORD_FEES%ROWTYPE;
      l_data ARRAY;
      v_time_taken VARCHAR2(205);
      v_out_tx          VARCHAR2(2000);
      SQLQuery   VARCHAR2(6000);
      v_query           VARCHAR2(2000);
      v_query2          VARCHAR2(32767);
      nCheckpoint       NUMBER;
      nbreakpoint   NUMBER;
      l_start number default dbms_utility.get_time; 
      QueryTable5 VARCHAR2(600) := q'{Select f_get_fee('RM_XX_FEE03',:sCustomerCode) From DUAl}';
      --QueryTable5 VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE03,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode5}';
      sCust_Rates5 RM.RM_XX_FEE03%TYPE;/*1 PhoneOrderEntryFee*/
      QueryTable4 VARCHAR2(600) := q'{Select f_get_fee('RM_XX_FEE02',:sCustomerCode) From DUAl}';
      --QueryTable4 VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE02,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode4}';
      sCust_Rates4 RM.RM_XX_FEE02%TYPE;/*EmailOrderEntryFee*/
      QueryTable3 VARCHAR2(600) := q'{Select f_get_fee('RM_XX_FEE07',:sCustomerCode) From DUAl}';
      --QueryTable3 VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE07,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode3}';
      sCust_Rates3 RM.RM_XX_FEE07%TYPE;/*FaxOrderEntryFee*/
      QueryTable2 VARCHAR2(600) := q'{Select f_get_fee('RM_XX_FEE01',:sCustomerCode) From DUAl}';
      --QueryTable2 VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE01,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode3}';
      sCust_Rates2 RM.RM_XX_FEE07%TYPE;/*ManOrderEntryFee*/
      QueryTable1 VARCHAR2(600) := q'{Select f_get_fee('RM_XX_FEE01',:sCustomerCode) From DUAl}';
      --QueryTable1 VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE01,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode}';
      sCust_Rates1 RM.RM_XX_FEE01%TYPE;/*VerbalOrderEntryFee*/
      CURSOR c
      IS
        /*AllOrderEntryFee*/
      SELECT    s.SH_CUST,r.sGroupCust,
          CASE    WHEN i.IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
          WHEN i.IM_CUST = 'TABCORP' THEN i.IM_XX_COST_CENTRE01
          ELSE s.SH_SPARE_STR_4
          END,
          s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,
          NULL,NULL,NULL,
          substr(To_Char(s.SH_ADD_DATE),0,10),
          CASE  WHEN s.SH_SPARE_DBL_9 = 1 THEN  'OrderEntryFee'
                WHEN s.SH_SPARE_DBL_9 = 3 THEN  'EmailOrderEntryFee'
                WHEN s.SH_SPARE_DBL_9 = 2 THEN  'FaxOrderEntryFee'
                WHEN s.SH_SPARE_DBL_9 = 2 THEN  'ManOrderEntryFee'
                WHEN s.SH_SPARE_DBL_9 = 4 OR  s.SH_SPARE_DBL_9 = 9 THEN  'OrderEntryFee'
                ELSE ''
          END,
          CASE  WHEN s.SH_SPARE_DBL_9 = 1 THEN  'FEEORDERENTRYS'
                WHEN s.SH_SPARE_DBL_9 = 3 THEN  'FEEORDERENTRYS'
                WHEN s.SH_SPARE_DBL_9 = 2 THEN  'FEEORDERENTRYS'
                WHEN s.SH_SPARE_DBL_9 = 2 THEN  'FEEORDERENTRYS'
                WHEN s.SH_SPARE_DBL_9 = 4 OR  s.SH_SPARE_DBL_9 = 9 THEN  'FEEORDERENTRYS'
                ELSE ''
          END,
          CASE  WHEN s.SH_SPARE_DBL_9 = 1 THEN  'Phone Order Entry Fee'
                WHEN s.SH_SPARE_DBL_9 = 3 THEN  'Email Order Entry Fee'
                WHEN s.SH_SPARE_DBL_9 = 2 THEN  'Fax Order Entry Fee'
                WHEN s.SH_SPARE_DBL_9 = 2 THEN  'Man Order Entry Fee'
                WHEN s.SH_SPARE_DBL_9 = 4 OR  s.SH_SPARE_DBL_9 = 9 THEN  'Order Entry Fee'
                ELSE ''
          END,
          CASE  WHEN d.SD_LINE = 1 OR s.SH_SPARE_DBL_9 = 3 OR s.SH_SPARE_DBL_9 = 2  OR s.SH_SPARE_DBL_9 = 2 THEN  1
                WHEN s.SH_SPARE_DBL_9 = 4 OR  s.SH_SPARE_DBL_9 = 9 THEN  1
                ELSE NULL
          END,
          CASE  WHEN d.SD_LINE = 1 THEN  '1'
                ELSE ''
          END,
          CASE  WHEN s.SH_SPARE_DBL_9 = 1 THEN sCust_Rates5--(Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust)
                WHEN s.SH_SPARE_DBL_9 = 3 THEN sCust_Rates4
                WHEN s.SH_SPARE_DBL_9 = 2 THEN sCust_Rates3
                WHEN s.SH_SPARE_DBL_9 = 2 THEN sCust_Rates2
                WHEN s.SH_SPARE_DBL_9 = 4 OR  s.SH_SPARE_DBL_9 = 9 THEN  sCust_Rates1
                ELSE NULL
          END,
          CASE  WHEN s.SH_SPARE_DBL_9 = 1 THEN sCust_Rates5-- (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust)
                WHEN s.SH_SPARE_DBL_9 = 3 THEN sCust_Rates4
                WHEN s.SH_SPARE_DBL_9 = 2 THEN sCust_Rates3
                WHEN s.SH_SPARE_DBL_9 = 2 THEN sCust_Rates2
                WHEN s.SH_SPARE_DBL_9 = 4 OR  s.SH_SPARE_DBL_9 = 9 THEN  sCust_Rates1
                ELSE NULL
          END,
          CASE  WHEN s.SH_SPARE_DBL_9 = 1 THEN sCust_Rates5-- (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust)
                WHEN s.SH_SPARE_DBL_9 = 3 THEN sCust_Rates4
                WHEN s.SH_SPARE_DBL_9 = 2 THEN sCust_Rates3
                WHEN s.SH_SPARE_DBL_9 = 2 THEN sCust_Rates2
                WHEN s.SH_SPARE_DBL_9 = 4 OR  s.SH_SPARE_DBL_9 = 9 THEN  sCust_Rates1
                ELSE NULL
          END,
          CASE  WHEN s.SH_SPARE_DBL_9 = 1 THEN sCust_Rates5 * 1.1-- (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
                WHEN s.SH_SPARE_DBL_9 = 3 THEN sCust_Rates4 * 1.1
                WHEN s.SH_SPARE_DBL_9 = 2 THEN sCust_Rates3 * 1.1
                WHEN s.SH_SPARE_DBL_9 = 2 THEN sCust_Rates2 * 1.1
                WHEN s.SH_SPARE_DBL_9 = 4 OR  s.SH_SPARE_DBL_9 = 9 THEN  sCust_Rates1 * 1.1
                ELSE NULL
          END,
          NULL,
          NULL AS "PreMarkUpPrice",
          NULL           AS "COSTPRICE",     
          REPLACE(s.SH_ADDRESS, ','),REPLACE(s.SH_SUBURB, ','),
          s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,REPLACE(s.SH_NOTE_1, ','),
          REPLACE(s.SH_NOTE_2, ','),
          0,0,s.SH_SPARE_DBL_9,NULL,NULL,0,
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
                ELSE ''
          END,
          'N/A',i.IM_OWNED_By,i.IM_PROFILE,
          s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
          s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
          d.SD_NOTE_1,d.SD_COST_PRICE,d.SD_XX_FREIGHT_CHG
    FROM  PWIN175.SH s
          INNER JOIN PWIN175.SD d ON d.SD_ORDER  = s.SH_ORDER
          INNER JOIN PWIN175.IM i ON i.IM_STOCK = d.SD_STOCK
          --//INNER JOIN PWIN175.ST t ON t.ST_ORDER = s.SH_ORDER AND t.ST_PICK = s.SH_LAST_PICK_NUM
          LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
          --LEFT JOIN PWIN175.RM r2 ON r2.RM_ANAL = r.RM_ANAL AND r2.RM_CUST = :cust
    WHERE ((r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)  AND  (s.SH_CUST != 'WBCMER'))
            --AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
   --AND       t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate
    AND       s.SH_ADD_DATE >= startdate AND s.SH_ADD_DATE <= enddate
    AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL -- so as to stop charging twice for the same order fee when the despatches have been split
    AND       (s.SH_SPARE_DBL_9 = 3 OR s.SH_SPARE_DBL_9 = 2 OR s.SH_SPARE_DBL_9 = 4 OR  s.SH_SPARE_DBL_9 = 9)
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
        
  CURSOR cDEV
      IS
        /*AllOrderEntryFee*/
      SELECT    s.SH_CUST,r.sGroupCust,
          CASE    WHEN i.IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
          WHEN i.IM_CUST = 'TABCORP' THEN i.IM_XX_COST_CENTRE01
          ELSE s.SH_SPARE_STR_4
          END,
          s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,
          NULL,NULL,NULL,
          substr(To_Char(s.SH_ADD_DATE),0,10),
          CASE  WHEN s.SH_SPARE_DBL_9 = 1 THEN  'OrderEntryFee'
                WHEN s.SH_SPARE_DBL_9 = 3 THEN  'EmailOrderEntryFee'
                WHEN s.SH_SPARE_DBL_9 = 2 THEN  'FaxOrderEntryFee'
                WHEN s.SH_SPARE_DBL_9 = 2 THEN  'ManOrderEntryFee'
                WHEN s.SH_SPARE_DBL_9 = 4 OR  s.SH_SPARE_DBL_9 = 9 THEN  'OrderEntryFee'
                ELSE ''
          END,
          CASE  WHEN s.SH_SPARE_DBL_9 = 1 THEN  'FEEORDERENTRYS'
                WHEN s.SH_SPARE_DBL_9 = 3 THEN  'FEEORDERENTRYS'
                WHEN s.SH_SPARE_DBL_9 = 2 THEN  'FEEORDERENTRYS'
                WHEN s.SH_SPARE_DBL_9 = 2 THEN  'FEEORDERENTRYS'
                WHEN s.SH_SPARE_DBL_9 = 4 OR  s.SH_SPARE_DBL_9 = 9 THEN  'FEEORDERENTRYS'
                ELSE ''
          END,
          CASE  WHEN s.SH_SPARE_DBL_9 = 1 THEN  'Phone Order Entry Fee'
                WHEN s.SH_SPARE_DBL_9 = 3 THEN  'Email Order Entry Fee'
                WHEN s.SH_SPARE_DBL_9 = 2 THEN  'Fax Order Entry Fee'
                WHEN s.SH_SPARE_DBL_9 = 2 THEN  'Man Order Entry Fee'
                WHEN s.SH_SPARE_DBL_9 = 4 OR  s.SH_SPARE_DBL_9 = 9 THEN  'Order Entry Fee'
                ELSE ''
          END,
          CASE  WHEN d.SD_LINE = 1 OR s.SH_SPARE_DBL_9 = 3 OR s.SH_SPARE_DBL_9 = 2  OR s.SH_SPARE_DBL_9 = 2 THEN  1
                WHEN s.SH_SPARE_DBL_9 = 4 OR  s.SH_SPARE_DBL_9 = 9 THEN  1
                ELSE NULL
          END,
          CASE  WHEN d.SD_LINE = 1 THEN  '1'
                ELSE ''
          END,
          CASE  WHEN s.SH_SPARE_DBL_9 = 1 THEN sCust_Rates5--(Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust)
                WHEN s.SH_SPARE_DBL_9 = 3 THEN sCust_Rates4
                WHEN s.SH_SPARE_DBL_9 = 2 THEN sCust_Rates3
                WHEN s.SH_SPARE_DBL_9 = 2 THEN sCust_Rates2
                WHEN s.SH_SPARE_DBL_9 = 4 OR  s.SH_SPARE_DBL_9 = 9 THEN  sCust_Rates1
                ELSE NULL
          END,
          CASE  WHEN s.SH_SPARE_DBL_9 = 1 THEN sCust_Rates5-- (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust)
                WHEN s.SH_SPARE_DBL_9 = 3 THEN sCust_Rates4
                WHEN s.SH_SPARE_DBL_9 = 2 THEN sCust_Rates3
                WHEN s.SH_SPARE_DBL_9 = 2 THEN sCust_Rates2
                WHEN s.SH_SPARE_DBL_9 = 4 OR  s.SH_SPARE_DBL_9 = 9 THEN  sCust_Rates1
                ELSE NULL
          END,
          CASE  WHEN s.SH_SPARE_DBL_9 = 1 THEN sCust_Rates5-- (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust)
                WHEN s.SH_SPARE_DBL_9 = 3 THEN sCust_Rates4
                WHEN s.SH_SPARE_DBL_9 = 2 THEN sCust_Rates3
                WHEN s.SH_SPARE_DBL_9 = 2 THEN sCust_Rates2
                WHEN s.SH_SPARE_DBL_9 = 4 OR  s.SH_SPARE_DBL_9 = 9 THEN  sCust_Rates1
                ELSE NULL
          END,
          CASE  WHEN s.SH_SPARE_DBL_9 = 1 THEN sCust_Rates5 * 1.1-- (Select To_Number(rm3.RM_XX_FEE03) from RM rm3 where rm3.RM_CUST = sCust) * 1.1
                WHEN s.SH_SPARE_DBL_9 = 3 THEN sCust_Rates4 * 1.1
                WHEN s.SH_SPARE_DBL_9 = 2 THEN sCust_Rates3 * 1.1
                WHEN s.SH_SPARE_DBL_9 = 2 THEN sCust_Rates2 * 1.1
                WHEN s.SH_SPARE_DBL_9 = 4 OR  s.SH_SPARE_DBL_9 = 9 THEN  sCust_Rates1 * 1.1
                ELSE NULL
          END,
          NULL,
          NULL AS "PreMarkUpPrice",
          NULL           AS "COSTPRICE",     
          REPLACE(s.SH_ADDRESS, ','),REPLACE(s.SH_SUBURB, ','),
          s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,REPLACE(s.SH_NOTE_1, ','),
          REPLACE(s.SH_NOTE_2, ','),
          0,0,s.SH_SPARE_DBL_9,NULL,NULL,0,
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
                ELSE ''
          END,
          'N/A',i.IM_OWNED_By,i.IM_PROFILE,
          s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,
          s.SH_SPARE_INT_4,s.SH_CAMPAIGN,
          d.SD_NOTE_1,d.SD_COST_PRICE,d.SD_XX_FREIGHT_CHG
    FROM  PWIN175.SH s
          INNER JOIN PWIN175.SD d ON d.SD_ORDER  = s.SH_ORDER
          INNER JOIN PWIN175.IM i ON i.IM_STOCK = d.SD_STOCK
          --//INNER JOIN PWIN175.ST t ON t.ST_ORDER = s.SH_ORDER AND t.ST_PICK = s.SH_LAST_PICK_NUM
          LEFT JOIN Dev_Group_Cust r ON r.sCust = s.SH_CUST
          --LEFT JOIN PWIN175.RM r2 ON r2.RM_ANAL = r.RM_ANAL AND r2.RM_CUST = :cust
    WHERE ((r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)  AND  (s.SH_CUST != 'WBCMER'))
            --AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
   --AND       t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate
    AND       s.SH_ADD_DATE >= startdate AND s.SH_ADD_DATE <= enddate
    AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL -- so as to stop charging twice for the same order fee when the despatches have been split
    AND       (s.SH_SPARE_DBL_9 = 3 OR s.SH_SPARE_DBL_9 = 2 OR s.SH_SPARE_DBL_9 = 4 OR  s.SH_SPARE_DBL_9 = 9)
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
      EXECUTE IMMEDIATE QueryTable5 INTO sCust_Rates5 USING sCustomerCode;--phone
      EXECUTE IMMEDIATE QueryTable4 INTO sCust_Rates4 USING sCustomerCode;--email
      EXECUTE IMMEDIATE QueryTable3 INTO sCust_Rates3 USING sCustomerCode;--fax
      EXECUTE IMMEDIATE QueryTable2 INTO sCust_Rates2 USING sCustomerCode;--man
      EXECUTE IMMEDIATE QueryTable1 INTO sCust_Rates1 USING sCustomerCode;--verbal
     -- --DBMS_OUTPUT.PUT_LINE('aE1_PHONE_ORD_FEES rates are $' || sCust_Rates5 || '. Prism rate field is RM_XX_FEE03.');     
     -- --DBMS_OUTPUT.PUT_LINE('aE1_EMAIL_ORD_FEES rates are $' || sCust_Rates4 || '. Prism rate field is RM_XX_FEE02.');
     -- --DBMS_OUTPUT.PUT_LINE('aE1_FAX_ORD_FEES rates are $' || sCust_Rates3 || '. Prism rate field is RM_XX_FEE07.');
     -- --DBMS_OUTPUT.PUT_LINE('aE1_MAN_ORD_FEES rates are $' || sCust_Rates2 || '. Prism rate field is RM_XX_FEE01.');
     -- --DBMS_OUTPUT.PUT_LINE('aE1_.._ORD_FEES rates are $' || sCust_Rates1 || '. Prism rate field is RM_XX_FEE01.');
        --nCheckpoint := 11;
        
        
      IF sCust_Rates5  > 0
      OR sCust_Rates4  > 0
      OR sCust_Rates3  > 0
      OR sCust_Rates2  > 0
      OR sCust_Rates1  > 0
      THEN
        If (upper(Debug_Y_OR_N) = 'Y') Then
          DBMS_OUTPUT.PUT_LINE('E1_PHONE_ORD_FEES rates are $' || sCust_Rates5 || '. Prism rate field is RM_XX_FEE03.');     
          DBMS_OUTPUT.PUT_LINE('E1_EMAIL_ORD_FEES rates are $' || sCust_Rates4 || '. Prism rate field is RM_XX_FEE02.');
          DBMS_OUTPUT.PUT_LINE('E1_FAX_ORD_FEES rates are $' || sCust_Rates3 || '. Prism rate field is RM_XX_FEE07.');
          DBMS_OUTPUT.PUT_LINE('E1_MAN_ORD_FEES rates are $' || sCust_Rates2 || '. Prism rate field is RM_XX_FEE01.');
          DBMS_OUTPUT.PUT_LINE('E1_?_ORD_FEES rates are $' || sCust_Rates1 || '. Prism rate field is RM_XX_FEE01.');
        End If;
        nCheckpoint := 2;
        If (sOp = 'PRJ' or sOp = 'DEV') Then
          v_query := 'TRUNCATE TABLE DEV_ALL_ORD_FEES';
          EXECUTE IMMEDIATE v_query;
          OPEN cDEV;
          ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
          LOOP
          FETCH cDEV BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO DEV_ALL_ORD_FEES VALUES l_data(i);
          --USING sCust;
  
          EXIT WHEN cDEV%NOTFOUND;
  
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE cDEV;
        Else
          v_query := 'TRUNCATE TABLE TMP_ALL_ORD_FEES';
          EXECUTE IMMEDIATE v_query;
          OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO TMP_ALL_ORD_FEES VALUES l_data(i);
          --USING sCust;
  
          EXIT WHEN c%NOTFOUND;
  
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
        End If;
          --       FOR i IN l_data.FIRST .. l_data.LAST LOOP
          --        --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          --      END LOOP;
          v_query2 :=  SQL%ROWCOUNT;
          COMMIT;
      IF v_query2 > 0 THEN
        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
        If (sOp = 'PRJ' or sOp = 'DEV') Then
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'E0_ALL_ORD_FEES','SH','DEV_ALL_ORD_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        Else
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'E0_ALL_ORD_FEES','SH','TMP_ALL_ORD_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        End If;
        If (upper(Debug_Y_OR_N) = 'Y') Then
          DBMS_OUTPUT.PUT_LINE('E0_ALL_ORD_FEES for the date range '
          || startdate || ' -- ' || enddate || ' - ' || v_query2
          || ' records inserted into table TMP_ALL_ORD_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
          || ' Seconds...for customer ' || sCustomerCode );
         End If;
      Else
        If (upper(Debug_Y_OR_N) = 'Y') Then
          DBMS_OUTPUT.PUT_LINE('E0_ALL_ORD_FEES rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
          ' Seconds...for customer ' || sCustomerCode);
       End if;
      END IF;
    --Else
        --DBMS_OUTPUT.PUT_LINE('cE1_PHONE_ORD_FEES rates are $' || sCust_Rates5 || '. Prism rate field is RM_XX_FEE03.');     
        --DBMS_OUTPUT.PUT_LINE('cE1_EMAIL_ORD_FEES rates are $' || sCust_Rates4 || '. Prism rate field is RM_XX_FEE02.');
        --DBMS_OUTPUT.PUT_LINE('cE1_FAX_ORD_FEES rates are $' || sCust_Rates3 || '. Prism rate field is RM_XX_FEE07.');
        --DBMS_OUTPUT.PUT_LINE('cE1_MAN_ORD_FEES rates are $' || sCust_Rates2 || '. Prism rate field is RM_XX_FEE01.');
        --DBMS_OUTPUT.PUT_LINE('cE1_.._ORD_FEES rates are $' || sCust_Rates1 || '. Prism rate field is RM_XX_FEE01.');
        --DBMS_OUTPUT.PUT_LINE('cE0_ALL_ORD_FEES rates are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
       -- ' Seconds...for customer ' || sCustomerCode);
      END IF;
    EXCEPTION
      WHEN VALUE_ERROR THEN
         DBMS_OUTPUT.PUT_LINE('E0_ALL_ORD_FEES failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
      WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('E0_ALL_ORD_FEES failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('E0_ALL_ORD_FEES failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
       --RETURN 0;
      
        RAISE;
    END E0_ALL_ORD_FEES;  
    
    /*   E4_STD_ORD_FEES Run this once for each customer   */
  /*   This gets all the Verbal Order Related Data   */
  /*   Temp Tables Used   */
  /*   1. TMP_VERBAL_ORD_FEES   */
  /*   Prism Rate Field Used   */
  /*   A. RM_XX_FEE01   */
  PROCEDURE E4_STD_ORD_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
      ,sAnalysis IN RM.RM_ANAL%TYPE
      ,sFilterBy IN VARCHAR2
      ,sOp IN VARCHAR2
      ,Debug_Y_OR_N IN VARCHAR2 DEFAULT 'N'
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_STD_ORD_FEES%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_time_taken VARCHAR2(205);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
    nbreakpoint   NUMBER;
    l_start number default dbms_utility.get_time;
    QueryTable2 VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE27,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode}';
    sCust_Rates2 RM.RM_XX_FEE27%TYPE;/*VerbalOrderEntryFee*/

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
       'OrderFee'  AS "FeeType",
      'FEEORDER'    AS "Item",
	  'Order  Fee'     AS "Description",
	  1          AS "Qty",
	  1        AS "UOI",
	 sCust_Rates2        AS "UnitPrice",
	  sCust_Rates2                 AS "OWUnitPrice",
	  sCust_Rates2                AS "DExcl",
	 sCust_Rates2              AS "Excl_Total",
	 sCust_Rates2     * 1.1             AS "DIncl",
	 sCust_Rates2     * 1.1      AS "Incl_Total",
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
	WHERE ((r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)  AND  (s.SH_CUST != 'WBCMER'))
            --AND       t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate
  AND       s.SH_ADD_DATE >= startdate AND s.SH_ADD_DATE <= enddate
	--AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	--AND       s.SH_SPARE_DBL_9 = 4 OR  s.SH_SPARE_DBL_9 = 9
	AND       d.SD_LINE = 1;
 /* --AND (SELECT To_Number(regexp_substr(RM_XX_FEE01,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) > 0.1
	/*GROUP BY  s.SH_CUST,r.sGroupCust,i.IM_CUST,s.SH_SPARE_STR_4,i.IM_XX_COST_CENTRE01,
        s.SH_ORDER,s.SH_SPARE_STR_5,s.SH_CUST_REF,t.ST_DESP_DATE,s.SH_SPARE_DBL_9,d.SD_LINE,
        s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_NOTE_2,s.SH_SPARE_STR_3,
        i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4,s.SH_SPARE_STR_1,
        d.SD_ORDER,d.SD_STOCK,t.ST_ORDER,t.ST_PICK,s.SH_LAST_PICK_NUM,r.sCust,s.SH_PREV_PSLIP_NUM,i.IM_TYPE,s.SH_STATUS,
        i.IM_BRAND,t.ST_WEIGHT,t.ST_PACKAGES,d.SD_LAST_PICK_NUM,s.SH_CAMPAIGN;
*/
     CURSOR cDEV
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
       'OrderFee'  AS "FeeType",
      'FEEORDER'    AS "Item",
	  'Order  Fee'     AS "Description",
	  1          AS "Qty",
	  1        AS "UOI",
	 sCust_Rates2        AS "UnitPrice",
	  sCust_Rates2                 AS "OWUnitPrice",
	  sCust_Rates2                AS "DExcl",
	 sCust_Rates2              AS "Excl_Total",
	 sCust_Rates2     * 1.1             AS "DIncl",
	 sCust_Rates2     * 1.1      AS "Incl_Total",
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
			  LEFT JOIN Dev_Group_Cust r ON r.sCust = s.SH_CUST
			  --LEFT JOIN PWIN175.RM r2 ON r2.RM_ANAL = r.RM_ANAL AND r2.RM_CUST = :cust
	WHERE ((r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)  AND  (s.SH_CUST != 'WBCMER'))
            --AND       t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate
  AND       s.SH_ADD_DATE >= startdate AND s.SH_ADD_DATE <= enddate
	--AND       LTrim(s.SH_PREV_PSLIP_NUM) IS NULL
	--AND       s.SH_SPARE_DBL_9 = 4 OR  s.SH_SPARE_DBL_9 = 9
	AND       d.SD_LINE = 1;
  

    BEGIN
    nCheckpoint := 10;
    EXECUTE IMMEDIATE QueryTable2 INTO sCust_Rates2 USING sCustomerCode;/*VerbalOrderEntryFee*/
    --DBMS_OUTPUT.PUT_LINE('E4_STD_ORD_FEES rates are $' || sCust_Rates2 || '. Prism rate field is .');
   -- nCheckpoint := 11;
    

    IF sCust_Rates2 IS NOT NULL THEN
      --DBMS_OUTPUT.PUT_LINE('E4_STD_ORD_FEES rates are $' || sCust_Rates2 || '. Prism rate field is .');
    
        nCheckpoint := 2;
        If (sOp = 'PRJ' or sOp = 'DEV') Then
          v_query := 'TRUNCATE TABLE DEV_STD_ORD_FEES';
          EXECUTE IMMEDIATE v_query;
          
          OPEN cDEV;
          --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
          LOOP
          FETCH cDEV BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          --DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO DEV_STD_ORD_FEES VALUES l_data(i);
          --USING sCust;
  
          EXIT WHEN cDEV%NOTFOUND;
  
          END LOOP;
         -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE cDEV;
        Else
          v_query := 'TRUNCATE TABLE TMP_STD_ORD_FEES';
          EXECUTE IMMEDIATE v_query;
          
          OPEN c;
          --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          --DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO TMP_STD_ORD_FEES VALUES l_data(i);
          --USING sCust;
  
          EXIT WHEN c%NOTFOUND;
  
          END LOOP;
         -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;

        End If;
      v_query2 :=  SQL%ROWCOUNT;
      COMMIT;
    Else
      DBMS_OUTPUT.PUT_LINE('E4_STD_ORD_FEES no rates');
    End If;
    IF v_query2 > 0 THEN
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      If (sOp = 'PRJ' or sOp = 'DEV') Then
        EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'E4_VERBAL_ORD_FEES','SH','DEV_VERBAL_ORD_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
      Else
        EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'E4_VERBAL_ORD_FEES','SH','TMP_VERBAL_ORD_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
      End If;
      If (upper(Debug_Y_OR_N) = 'Y') Then
        DBMS_OUTPUT.PUT_LINE('E4_STD_ORD_FEES for the date range '
        || startdate || ' -- ' || enddate || ' - ' || v_query2
        || ' records inserted into table TMP_VERBAL_ORD_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
        || ' Seconds...for customer ' || sCustomerCode );
      End If;
    Else
      DBMS_OUTPUT.PUT_LINE('E4_STD_ORD_FEES rates are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
      ' Seconds...for customer ' || sCustomerCode);
    END IF;
  --END IF;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('E4_STD_ORD_FEES failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM || ' customer was ' || sCustomerCode);
    RAISE;
  END E4_STD_ORD_FEES;


    
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
        ,sFilterBy IN VARCHAR2
        ,sOp IN VARCHAR2
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
      CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN sCust_Rates * 1.1--(SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * 1.1-- (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust) * 1.1
         ELSE NULL
         END                      AS "DIncl",
      CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN (Select To_Number(i.IM_REPORTING_PRICE) from IM i where i.IM_STOCK = d.SD_STOCK)
          ELSE NULL
          END                      AS "ReportingPrice",
          NULL,
          NULL,
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
   -- Group By d.SD_STOCK;
    
      CURSOR cDEV
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
      CASE   WHEN s.SH_CAMPAIGN = 'DESTROY' OR s.SH_CAMPAIGN = 'OBSOLETE' THEN sCust_Rates * 1.1--(SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * 1.1-- (Select To_Number(RM_XX_FEE25) from RM where RM_CUST = :cust) * 1.1
         ELSE NULL
         END                      AS "DIncl",
      CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN (Select To_Number(i.IM_REPORTING_PRICE) from IM i where i.IM_STOCK = d.SD_STOCK)
          ELSE NULL
          END                      AS "ReportingPrice",
          NULL,
          NULL,
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
          LEFT JOIN Dev_Group_Cust r ON r.sCust = s.SH_CUST
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
      
      --nCheckpoint := 11;
      
      
      IF sCust_Rates IS NOT NULL THEN
       -- --DBMS_OUTPUT.PUT_LINE('E5_DESTROY_ORD_FEES rates are $' || sCust_Rates || '. Prism rate field is RM_XX_FEE25');
      
  
      nCheckpoint := 2;
          If (sOp = 'PRJ' or sOp = 'DEV') Then
            v_query := 'TRUNCATE TABLE DEV_DESTROY_ORD_FEES';
            EXECUTE IMMEDIATE v_query;
            OPEN cDEV;
            ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
            LOOP
            FETCH cDEV BULK COLLECT INTO l_data LIMIT p_array_size;
    
            FORALL i IN 1..l_data.COUNT
            ----DBMS_OUTPUT.PUT_LINE(i || '.' );
            INSERT INTO DEV_DESTROY_ORD_FEES VALUES l_data(i);
            --USING sCust;
    
            EXIT WHEN cDEV%NOTFOUND;
    
            END LOOP;
           -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            CLOSE cDEV;
          Else
            v_query := 'TRUNCATE TABLE TMP_DESTROY_ORD_FEES';
            EXECUTE IMMEDIATE v_query;
            OPEN c;
            ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
            LOOP
            FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
    
            FORALL i IN 1..l_data.COUNT
            ----DBMS_OUTPUT.PUT_LINE(i || '.' );
            INSERT INTO TMP_DESTROY_ORD_FEES VALUES l_data(i);
            --USING sCust;
    
            EXIT WHEN c%NOTFOUND;
    
            END LOOP;
           -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            CLOSE c;
        End If;

      v_query2 :=  SQL%ROWCOUNT;
      COMMIT;
      IF v_query2 > 0 THEN
        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
        If (sOp = 'PRJ' or sOp = 'DEV') Then
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'E5_DESTOY_ORD_FEES','SH','DEV_DESTROY_ORD_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        Else
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'E5_DESTOY_ORD_FEES','SH','TMP_DESTROY_ORD_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        End if;
        --DBMS_OUTPUT.PUT_LINE('E5_DESTOY_ORD_FEES for the date range '
       -- || startdate || ' -- ' || enddate || ' - ' || v_query2
       -- || ' records inserted into table TMP_DESTROY_ORD_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
       -- || ' Seconds...for customer ' || sCustomerCode );
      --Else
        --DBMS_OUTPUT.PUT_LINE('E5_DESTOY_ORD_FEES rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
       -- ' Seconds...for customer ' || sCustomerCode);
      END IF;
   ---- Else
        --DBMS_OUTPUT.PUT_LINE('E5_DESTOY_ORD_FEES rates are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
        --' Seconds...for customer ' || sCustomerCode);
    END IF;
    EXCEPTION
       WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('E5_DESTOY_ORD_FEES failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('E5_DESTOY_ORD_FEES failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
        RAISE;
    END E5_DESTOY_ORD_FEES;

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
        ,sFilterBy IN VARCHAR2
        ,sOp IN VARCHAR2
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
          CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  f_get_fee('RM_XX_FEE18',sCustomerCode) --(SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)
          ELSE null
          END                      AS "UnitPrice",
          CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  f_get_fee('RM_XX_FEE18',sCustomerCode) --(SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)
          ELSE null
          END                                           AS "OWUnitPrice",
          CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1  THEN  f_get_fee('RM_XX_FEE18',sCustomerCode) --(SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)
          ELSE NULL
          END                        AS "DExcl",
          CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN f_get_fee('RM_XX_FEE18',sCustomerCode)   * 1.1 -- (SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)  * 1.1
          ELSE NULL
          END                                           AS "DIncl",
          CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN f_get_fee('RM_XX_FEE18',sCustomerCode) -- (SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)
          ELSE null
          END                                           AS "ReportingPrice",
          NULL,
          NULL,
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
    FROM  PWIN175.SD d
          INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
          INNER JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER
          LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
          INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
    WHERE  s.SH_STATUS <> 3
    AND f_get_fee('RM_XX_FEE18',sCustomerCode) > 0.1
    AND       (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
    AND       t.ST_XX_NUM_PAL_SW >= 1
    AND       d.SD_LINE = 1
    AND t.ST_PSLIP != 'CANCELLED'
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
  
      CURSOR cDEV
      IS
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
          CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  f_get_fee('RM_XX_FEE18',sCustomerCode) --(SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)
          ELSE null
          END                      AS "UnitPrice",
          CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN  f_get_fee('RM_XX_FEE18',sCustomerCode) --(SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)
          ELSE null
          END                                           AS "OWUnitPrice",
          CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1  THEN  f_get_fee('RM_XX_FEE18',sCustomerCode) --(SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)
          ELSE NULL
          END                        AS "DExcl",
          CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN f_get_fee('RM_XX_FEE18',sCustomerCode)   * 1.1 -- (SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)  * 1.1
          ELSE NULL
          END                                           AS "DIncl",
          CASE   WHEN t.ST_XX_NUM_PAL_SW >= 1 THEN f_get_fee('RM_XX_FEE18',sCustomerCode) -- (SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)
          ELSE null
          END                                           AS "ReportingPrice",
          NULL,
          NULL,
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
          LEFT JOIN Dev_Group_Cust r ON r.sCust = s.SH_CUST
          INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
    WHERE  s.SH_STATUS <> 3
    AND f_get_fee('RM_XX_FEE18',sCustomerCode) > 0.1
    AND       (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
    AND       t.ST_XX_NUM_PAL_SW >= 1
    AND       d.SD_LINE = 1
    AND t.ST_PSLIP != 'CANCELLED'
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
      --QueryTable VARCHAR2(600) := q'{Select f_get_fee('RM_XX_FEE18',:sCustomerCode) From DUAl}';--q'{SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode5}';
      QueryTable VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode5}';
      sCust_Rates RM.RM_XX_FEE18%TYPE;/*1 PickFee*/
      l_start number default dbms_utility.get_time;
     BEGIN
          nCheckpoint := 10;
          EXECUTE IMMEDIATE QueryTable INTO sCust_Rates USING sCustomerCode;/*1 PickFee*/
          
          --nCheckpoint := 11;
          
  
       IF To_Number(regexp_substr(sCust_Rates,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) != 0 Then
          --DBMS_OUTPUT.PUT_LINE('G1_SHRINKWRAP_FEES rates are $' || sCust_Rates || '. Prism rate field is RM_XX_FEE18');
          
          nCheckpoint := 2;
           If (sOp = 'PRJ' or sOp = 'DEV') Then
            v_query := 'TRUNCATE TABLE DEV_SHRINKWRAP_FEES';
            EXECUTE IMMEDIATE v_query;
            OPEN cDEV;
            ----DBMS_OUTPUT.PUT_LINE(sCustomerCode || '.' );
            LOOP
            FETCH cDEV BULK COLLECT INTO l_data LIMIT p_array_size;
    
            FORALL i IN 1..l_data.COUNT
            ----DBMS_OUTPUT.PUT_LINE(i || '.' );
            INSERT INTO DEV_SHRINKWRAP_FEES VALUES l_data(i);
            --USING sCust;
            EXIT WHEN cDEV%NOTFOUND;
            END LOOP;
           -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            CLOSE cDEV;
          Else
            v_query := 'TRUNCATE TABLE TMP_SHRINKWRAP_FEES';
            EXECUTE IMMEDIATE v_query;
             OPEN c;
              ----DBMS_OUTPUT.PUT_LINE(sCustomerCode || '.' );
              LOOP
              FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
      
              FORALL i IN 1..l_data.COUNT
              ----DBMS_OUTPUT.PUT_LINE(i || '.' );
              INSERT INTO TMP_SHRINKWRAP_FEES VALUES l_data(i);
              --USING sCust;
              EXIT WHEN c%NOTFOUND;
              END LOOP;
             -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
              CLOSE c;
          End If;
           --FOR i IN l_data.FIRST .. l_data.LAST LOOP
          --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          --END LOOP;
          v_query2 :=  SQL%ROWCOUNT;
          
      COMMIT;
  
       IF v_query2 > 0 THEN
        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
        If (sOp = 'PRJ' or sOp = 'DEV') Then
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'G1_SHRINKWRAP_FEES','ST','DEV_SHRINKWRAP_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        Else
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'G1_SHRINKWRAP_FEES','ST','TMP_SHRINKWRAP_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        End If;
        --DBMS_OUTPUT.PUT_LINE('G1_SHRINKWRAP_FEES for the date range '
       -- || startdate || ' -- ' || enddate || ' - ' || v_query2
       -- || ' records inserted into table TMP_SHRINKWRAP_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
       -- || ' Seconds...for customer ' || sCustomerCode );
      --Else
        --DBMS_OUTPUT.PUT_LINE('G1_SHRINKWRAP_FEES rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
       -- ' Seconds...for customer ' || sCustomerCode);
      END IF;
    --Else
        --DBMS_OUTPUT.PUT_LINE('G1_SHRINKWRAP_FEES rates are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
       -- ' Seconds...for customer ' || sCustomerCode);
      END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('G1_SHRINKWRAP_FEES failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
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
        ,sFilterBy IN VARCHAR2
        ,sOp IN VARCHAR2
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
            i.IM_CUST              AS "Parent",
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
            REPLACE(d.SD_DESC, ',')                AS "Description",
            l.SL_PSLIP_QTY           AS "Qty",
            d.SD_QTY_UNIT            AS "UOI",
            CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN TO_NUMBER(d.SD_SELL_PRICE)--n.NI_SELL_VALUE/n.NI_NX_QUANTITY --TO_NUMBER(d.SD_SELL_PRICE)
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1 THEN TO_NUMBER(d.SD_SELL_PRICE) --n.NI_SELL_VALUE/n.NI_NX_QUANTITY
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND IU_TO_METRIC = 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) --* d.SD_QTY_DESP --eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK) IS NOT NULL THEN eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK)
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND IU_TO_METRIC != 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) --* d.SD_QTY_DESP -- d.SD_XX_OW_UNIT_PRICE
            ELSE NULL -- 43/50
            END                        AS "Batch/UnitPrice",
            CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN To_Number(i.IM_REPORTING_PRICE)
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN NULL
            ELSE NULL
            END                        AS "OWUnitPrice", -- fix this for tabcorp
            CASE  WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN d.SD_SELL_PRICE * l.SL_PSLIP_QTY
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1 THEN TO_NUMBER(d.SD_SELL_PRICE) * l.SL_PSLIP_QTY--(n.NI_SELL_VALUE/n.NI_NX_QUANTITY)
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND IU_TO_METRIC = 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * l.SL_PSLIP_QTY --eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK) IS NOT NULL THEN eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK)
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND IU_TO_METRIC != 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * l.SL_PSLIP_QTY -- d.SD_XX_OW_UNIT_PRICE
            ELSE NULL
            END          AS "DExcl", 
            CASE    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN (d.SD_SELL_PRICE * l.SL_PSLIP_QTY) * 1.1
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1  THEN  (TO_NUMBER(d.SD_SELL_PRICE) * l.SL_PSLIP_QTY) * 1.1
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND IU_TO_METRIC = 1 THEN (((SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * l.SL_PSLIP_QTY) * 1.1) --eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK) IS NOT NULL THEN eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK)
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND IU_TO_METRIC != 1 THEN (((SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * l.SL_PSLIP_QTY) * 1.1) -- d.SD_XX_OW_UNIT_PRICE
            ELSE NULL
            END          AS "DIncl",
            CASE WHEN sCustomerCode = 'TABCORP' Then eom_report_pkg.F_BREAK_UNIT_PRICE(r.OW_CAT,d.SD_STOCK)
                 WHEN sCustomerCode = 'TABCORP' AND eom_report_pkg.F_BREAK_UNIT_PRICE(r.OW_CAT,d.SD_STOCK) IS NULL Then To_Number(i.IM_REPORTING_PRICE)
            Else To_Number(i.IM_REPORTING_PRICE)      
            END AS "ReportingPrice", -- break 
            IM_STD_COST,
            IM_LAST_COST,
            REPLACE(s.SH_ADDRESS, ',')             AS "Address",
            REPLACE(s.SH_SUBURB, ',')              AS "Address2",
            REPLACE(s.SH_CITY, ',')                AS "Suburb",
            s.SH_STATE               AS "State",
            s.SH_POST_CODE           AS "Postcode",
            REPLACE(s.SH_NOTE_1, ',')              AS "DeliverTo",
            REPLACE(s.SH_NOTE_2, ',')              AS "AttentionTo" ,
            t.ST_WEIGHT              AS "Weight",
            t.ST_PACKAGES            AS "Packages",
            s.SH_SPARE_DBL_9         AS "OrderSource", --nedd function to return text value
            IM_XX_QTY_PER_PACK AS "Inner", /*Pallet/Space*/
            IM_XX_QTY_SHIP_ON_PAL AS "Outer", /*Locn*/
            0 AS "CountOfStocks",
            CASE   WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
            ELSE ''
            END AS Email,
            i.IM_BRAND AS Brand,
            r.OW_CAT AS OwnedBy,
            i.IM_OWNED_BY AS sProfile,
            NULL AS WaiveFee,
            NULL AS Cost,
            NULL AS PaymentType,s.SH_CAMPAIGN,NULL,NULL,SD_XX_ARIBA_LINE_NO
      FROM      SD d
         INNER JOIN SH s  ON s.SH_ORDER  = d.SD_ORDER
          --INNER JOIN ST t  ON t.ST_PICK  = d.SD_LAST_PICK_NUM
          INNER JOIN SL l  ON l.SL_ORDER  = d.SD_ORDER  AND SL_ORDER_LINE = SD_LINE
          INNER JOIN ST t  ON t.ST_PICK  = l.SL_PICK
          INNER JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
          INNER JOIN IM i  ON i.IM_STOCK = d.SD_STOCK
          --INNER JOIN NE n  ON n.NE_STOCK = l.SL_UID
          INNER JOIN IU ON IU_UNIT = i.IM_LEVEL_UNIT
          WHERE SD_STATUS != 3
          AND SL_PSLIP_QTY >= 1
          AND (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
          AND t.ST_PSLIP != 'CANCELLED'
          --AND       s.SH_ORDER = t.ST_ORDER
          --AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
          AND       t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate;
          --AND       d.SD_LAST_PICK_NUM = t.ST_PICK;
          
       CURSOR cDEV
      IS
      /*Stocks*/
      SELECT 
            s.SH_CUST                AS "Customer",
            i.IM_CUST              AS "Parent",
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
            REPLACE(d.SD_DESC, ',')                AS "Description",
            l.SL_PSLIP_QTY           AS "Qty",
            d.SD_QTY_UNIT            AS "UOI",
            CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN TO_NUMBER(d.SD_SELL_PRICE)--n.NI_SELL_VALUE/n.NI_NX_QUANTITY --TO_NUMBER(d.SD_SELL_PRICE)
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1 THEN TO_NUMBER(d.SD_SELL_PRICE) --n.NI_SELL_VALUE/n.NI_NX_QUANTITY
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND IU_TO_METRIC = 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) --* d.SD_QTY_DESP --eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK) IS NOT NULL THEN eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK)
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND IU_TO_METRIC != 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) --* d.SD_QTY_DESP -- d.SD_XX_OW_UNIT_PRICE
            ELSE NULL -- 43/50
            END                        AS "Batch/UnitPrice",
            CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN To_Number(i.IM_REPORTING_PRICE)
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN NULL
            ELSE NULL
            END                        AS "OWUnitPrice", -- fix this for tabcorp
            CASE  WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN d.SD_SELL_PRICE * l.SL_PSLIP_QTY
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1 THEN TO_NUMBER(d.SD_SELL_PRICE) * l.SL_PSLIP_QTY--(n.NI_SELL_VALUE/n.NI_NX_QUANTITY)
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND IU_TO_METRIC = 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * l.SL_PSLIP_QTY --eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK) IS NOT NULL THEN eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK)
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND IU_TO_METRIC != 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * l.SL_PSLIP_QTY -- d.SD_XX_OW_UNIT_PRICE
            ELSE NULL
            END          AS "DExcl", 
            CASE    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN (d.SD_SELL_PRICE * l.SL_PSLIP_QTY) * 1.1
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1  THEN  (TO_NUMBER(d.SD_SELL_PRICE) * l.SL_PSLIP_QTY) * 1.1
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND IU_TO_METRIC = 1 THEN (((SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * l.SL_PSLIP_QTY) * 1.1) --eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK) IS NOT NULL THEN eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK)
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND IU_TO_METRIC != 1 THEN (((SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * l.SL_PSLIP_QTY) * 1.1) -- d.SD_XX_OW_UNIT_PRICE
            ELSE NULL
            END          AS "DIncl",
            CASE WHEN sCustomerCode = 'TABCORP' Then eom_report_pkg.F_BREAK_UNIT_PRICE(r.OW_CAT,d.SD_STOCK)
                 WHEN sCustomerCode = 'TABCORP' AND eom_report_pkg.F_BREAK_UNIT_PRICE(r.OW_CAT,d.SD_STOCK) IS NULL Then To_Number(i.IM_REPORTING_PRICE)
            Else To_Number(i.IM_REPORTING_PRICE)      
            END AS "ReportingPrice", -- break 
            IM_STD_COST,
            IM_LAST_COST,
            REPLACE(s.SH_ADDRESS, ',')             AS "Address",
            REPLACE(s.SH_SUBURB, ',')              AS "Address2",
            REPLACE(s.SH_CITY, ',')                AS "Suburb",
            s.SH_STATE               AS "State",
            s.SH_POST_CODE           AS "Postcode",
            REPLACE(s.SH_NOTE_1, ',')              AS "DeliverTo",
            REPLACE(s.SH_NOTE_2, ',')              AS "AttentionTo" ,
            t.ST_WEIGHT              AS "Weight",
            t.ST_PACKAGES            AS "Packages",
            s.SH_SPARE_DBL_9         AS "OrderSource", --nedd function to return text value
            IM_XX_QTY_PER_PACK AS "Inner", /*Pallet/Space*/
            IM_XX_QTY_SHIP_ON_PAL AS "Outer", /*Locn*/
            0 AS "CountOfStocks",
            CASE   WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
            ELSE ''
            END AS Email,
            i.IM_BRAND AS Brand,
            r.OW_CAT AS OwnedBy,
            i.IM_OWNED_BY AS sProfile,
            NULL AS WaiveFee,
            NULL AS Cost,
            NULL AS PaymentType,s.SH_CAMPAIGN,NULL,NULL,SD_XX_ARIBA_LINE_NO
      FROM      SD d
         INNER JOIN SH s  ON s.SH_ORDER  = d.SD_ORDER
          --INNER JOIN ST t  ON t.ST_PICK  = d.SD_LAST_PICK_NUM
          INNER JOIN SL l  ON l.SL_ORDER  = d.SD_ORDER  AND SL_ORDER_LINE = SD_LINE
          INNER JOIN ST t  ON t.ST_PICK  = l.SL_PICK
          INNER JOIN Dev_Group_Cust r ON r.sCust = s.SH_CUST
          INNER JOIN IM i  ON i.IM_STOCK = d.SD_STOCK
          --INNER JOIN NE n  ON n.NE_STOCK = l.SL_UID
          INNER JOIN IU ON IU_UNIT = i.IM_LEVEL_UNIT
          WHERE SD_STATUS != 3
          AND SL_PSLIP_QTY >= 1
          AND (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
          AND t.ST_PSLIP != 'CANCELLED'
          --AND       s.SH_ORDER = t.ST_ORDER
          --AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
          AND       t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate;
          --AND       d.SD_LAST_PICK_NUM = t.ST_PICK;
      
      l_start number default dbms_utility.get_time;
     BEGIN
  
          --nCheckpoint := 1;
          
  
          nCheckpoint := 2;
          If (sOp = 'PRJ' or sOp = 'DEV') Then
            v_query := 'TRUNCATE TABLE DEV_STOCK_FEES';
            EXECUTE IMMEDIATE v_query;
            OPEN cDEV;
            ----DBMS_OUTPUT.PUT_LINE(sCustomerCode || '.' );
            LOOP
            FETCH cDEV BULK COLLECT INTO l_data LIMIT p_array_size;
    
            FORALL i IN 1..l_data.COUNT
            ----DBMS_OUTPUT.PUT_LINE(i || '.' );
            INSERT INTO DEV_STOCK_FEES VALUES l_data(i);
            --USING sCust;
            EXIT WHEN cDEV%NOTFOUND;
            END LOOP;
           -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            CLOSE cDEV;
          Else
            v_query := 'TRUNCATE TABLE TMP_STOCK_FEES';
            EXECUTE IMMEDIATE v_query;
            OPEN c;
            ----DBMS_OUTPUT.PUT_LINE(sCustomerCode || '.' );
            LOOP
            FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
    
            FORALL i IN 1..l_data.COUNT
            ----DBMS_OUTPUT.PUT_LINE(i || '.' );
            INSERT INTO TMP_STOCK_FEES VALUES l_data(i);
            --USING sCust;
            EXIT WHEN c%NOTFOUND;
            END LOOP;
           -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            CLOSE c;

          End If;
          -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
         -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          --END LOOP;
          v_query2 :=  SQL%ROWCOUNT;
          DBMS_OUTPUT.PUT_LINE(v_query2 || ' - record count.' );
      COMMIT;
  
       IF v_query2 > 0 THEN
        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
        If (sOp = 'PRJ' or sOp = 'DEV') Then
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'G2_STOCK_FEES','SD','DEV_STOCK_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        Else
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'G2_STOCK_FEES','SD','TMP_STOCK_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        End If;
        DBMS_OUTPUT.PUT_LINE('G2_STOCK_FEES for the date range '
        || startdate || ' -- ' || enddate || ' - ' || v_query2
        || ' records inserted into table TMP_STOCK_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
        || ' Seconds...for customer ' || sCustomerCode );
      --Else
        --DBMS_OUTPUT.PUT_LINE('G2_STOCK_FEES rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
       -- ' Seconds...for customer ' || sCustomerCode);
      END IF;
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('G2_STOCK_FEES failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
      WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('G2_STOCK_FEES failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
    END G2_STOCK_FEES;
  
    /*   G2_STOCK_FEES Run this once for each customer   */
    /*   This gets all the Handeling Related Data   */
    /*   Temp Tables Used   */
    /*   1. TMP_STOCK_FEES  Stocks */
    PROCEDURE G2_STOCK_FEES_SD (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
        ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
        ,sCustomerCode IN VARCHAR2
        ,sAnalysis IN RM.RM_ANAL%TYPE
        ,sFilterBy IN VARCHAR2
        ,sOp IN VARCHAR2
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
            i.IM_CUST              AS "Parent",
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
            REPLACE(d.SD_DESC, ',')                AS "Description",
            l.SL_PSLIP_QTY           AS "Qty",
            d.SD_QTY_UNIT            AS "UOI",
            CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN TO_NUMBER(d.SD_SELL_PRICE)--n.NI_SELL_VALUE/n.NI_NX_QUANTITY --TO_NUMBER(d.SD_SELL_PRICE)
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1 THEN TO_NUMBER(d.SD_SELL_PRICE) --n.NI_SELL_VALUE/n.NI_NX_QUANTITY
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND IU_TO_METRIC = 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) --* d.SD_QTY_DESP --eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK) IS NOT NULL THEN eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK)
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND IU_TO_METRIC != 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) --* d.SD_QTY_DESP -- d.SD_XX_OW_UNIT_PRICE
            ELSE NULL -- 43/50
            END                        AS "Batch/UnitPrice",
            CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN To_Number(i.IM_REPORTING_PRICE)
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN NULL
            ELSE NULL
            END                        AS "OWUnitPrice", -- fix this for tabcorp
            CASE  WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN d.SD_SELL_PRICE * l.SL_PSLIP_QTY
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1 THEN TO_NUMBER(d.SD_SELL_PRICE) * l.SL_PSLIP_QTY--(n.NI_SELL_VALUE/n.NI_NX_QUANTITY)
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND IU_TO_METRIC = 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * l.SL_PSLIP_QTY --eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK) IS NOT NULL THEN eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK)
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND IU_TO_METRIC != 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * l.SL_PSLIP_QTY -- d.SD_XX_OW_UNIT_PRICE
            ELSE NULL
            END          AS "DExcl", 
            CASE    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN (d.SD_SELL_PRICE * l.SL_PSLIP_QTY) * 1.1
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1  THEN  (TO_NUMBER(d.SD_SELL_PRICE) * l.SL_PSLIP_QTY) * 1.1
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND IU_TO_METRIC = 1 THEN (((SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * l.SL_PSLIP_QTY) * 1.1) --eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK) IS NOT NULL THEN eom_report_pkg.F_BREAK_UNIT_PRICE(r.sGroupCust,d.SD_STOCK)
            WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND IU_TO_METRIC != 1 THEN (((SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * l.SL_PSLIP_QTY) * 1.1) -- d.SD_XX_OW_UNIT_PRICE
            ELSE NULL
            END          AS "DIncl",
            CASE WHEN sCustomerCode = 'TABCORP' Then eom_report_pkg.F_BREAK_UNIT_PRICE(r.RM_GROUP_CUST,d.SD_STOCK)
                 WHEN sCustomerCode = 'TABCORP' AND eom_report_pkg.F_BREAK_UNIT_PRICE(r.RM_GROUP_CUST,d.SD_STOCK) IS NULL Then To_Number(i.IM_REPORTING_PRICE)
            Else To_Number(i.IM_REPORTING_PRICE)      
            END AS "ReportingPrice", -- break 
            IM_STD_COST,
            IM_LAST_COST,
            REPLACE(s.SH_ADDRESS, ',')             AS "Address",
            REPLACE(s.SH_SUBURB, ',')              AS "Address2",
            REPLACE(s.SH_CITY, ',')                AS "Suburb",
            s.SH_STATE               AS "State",
            s.SH_POST_CODE           AS "Postcode",
            REPLACE(s.SH_NOTE_1, ',')              AS "DeliverTo",
            REPLACE(s.SH_NOTE_2, ',')              AS "AttentionTo" ,
            t.ST_WEIGHT              AS "Weight",
            t.ST_PACKAGES            AS "Packages",
            s.SH_SPARE_DBL_9         AS "OrderSource", --nedd function to return text value
            IM_XX_QTY_PER_PACK AS "Inner", /*Pallet/Space*/
            IM_XX_QTY_SHIP_ON_PAL AS "Outer", /*Locn*/
            0 AS "CountOfStocks",
            CASE   WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
            ELSE ''
            END AS Email,
            i.IM_BRAND AS Brand,
            r.RM_GROUP_CUST AS OwnedBy,
            NULL AS sProfile,
            NULL AS WaiveFee,
            NULL AS Cost,
            NULL AS PaymentType,s.SH_CAMPAIGN,NULL,NULL,NULL
      FROM      SD d
         INNER JOIN SH s  ON s.SH_ORDER  = d.SD_ORDER
          --INNER JOIN ST t  ON t.ST_PICK  = d.SD_LAST_PICK_NUM
          INNER JOIN SL l  ON l.SL_ORDER  = d.SD_ORDER  AND SL_ORDER_LINE = SD_LINE
          INNER JOIN ST t  ON t.ST_PICK  = l.SL_PICK
          INNER JOIN RM r ON r.RM_CUST = s.SH_CUST
          INNER JOIN IM i  ON i.IM_STOCK = d.SD_STOCK
          --INNER JOIN NE n  ON n.NE_STOCK = l.SL_UID
          INNER JOIN IU ON IU_UNIT = i.IM_LEVEL_UNIT
          WHERE SD_STATUS != 3
          AND SL_PSLIP_QTY >= 1
          AND (r.RM_PARENT = sCustomerCode OR r.RM_CUST = sCustomerCode)
          AND t.ST_PSLIP != 'CANCELLED'
          --AND       s.SH_ORDER = t.ST_ORDER
          --AND       TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(t.ST_DESP_DATE,'YYYY-MM-DD') <= end_date
          AND       t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate;
          --AND       d.SD_LAST_PICK_NUM = t.ST_PICK;
      l_start number default dbms_utility.get_time;
     BEGIN
  
         -- nCheckpoint := 1;
         
  
          nCheckpoint := 2;
          If (sOp = 'PRJ' or sOp = 'DEV') Then
             v_query := 'TRUNCATE TABLE DEV_STOCK_FEES';
            EXECUTE IMMEDIATE v_query;
            OPEN c;
            ----DBMS_OUTPUT.PUT_LINE(sCustomerCode || '.' );
            LOOP
            FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
    
            FORALL i IN 1..l_data.COUNT
            ----DBMS_OUTPUT.PUT_LINE(i || '.' );
            INSERT INTO DEV_STOCK_FEES VALUES l_data(i);
            --USING sCust;
            EXIT WHEN c%NOTFOUND;
            END LOOP;
           -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            CLOSE c;
          Else
             v_query := 'TRUNCATE TABLE TMP_STOCK_FEES';
            EXECUTE IMMEDIATE v_query;
            OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(sCustomerCode || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO TMP_STOCK_FEES VALUES l_data(i);
          --USING sCust;
          EXIT WHEN c%NOTFOUND;
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
          End If;
          -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
          ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          --END LOOP;
          v_query2 :=  SQL%ROWCOUNT;
      COMMIT;
  
       IF v_query2 > 0 THEN
        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
        If (sOp = 'PRJ' or sOp = 'DEV') Then
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'G2_STOCK_FEES','SD','DEV_STOCK_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        Else
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'G2_STOCK_FEES','SD','TMP_STOCK_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        End If;
        --DBMS_OUTPUT.PUT_LINE('G2_STOCK_FEES for the date range '
        --|| startdate || ' -- ' || enddate || ' - ' || v_query2
       -- || ' records inserted into table TMP_STOCK_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
       -- || ' Seconds...for customer ' || sCustomerCode );
      --Else
        --DBMS_OUTPUT.PUT_LINE('G2_STOCK_FEES rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
       -- ' Seconds...for customer ' || sCustomerCode);
      END IF;
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('G2_STOCK_FEES failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
      WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('G2_STOCK_FEES failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
    END G2_STOCK_FEES_SD;
  
    
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
        ,sFilterBy IN VARCHAR2
        ,sOp IN VARCHAR2
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
          CASE WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1 -- ((Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1
          WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1 --  ((Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1
          ELSE NULL
          END                      AS "DIncl",
          CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN (Select i.IM_REPORTING_PRICE from IM i where i.IM_STOCK = d.SD_STOCK)
          ELSE NULL
          END                      AS "ReportingPrice",
          NULL,
          NULL,
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
    
    CURSOR cDEV
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
          CASE WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1 -- ((Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1
          WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1 --  ((Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1
          ELSE NULL
          END                      AS "DIncl",
          CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN (Select i.IM_REPORTING_PRICE from IM i where i.IM_STOCK = d.SD_STOCK)
          ELSE NULL
          END                      AS "ReportingPrice",
          NULL,
          NULL,
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
          LEFT JOIN Dev_Group_Cust r ON r.sCust = s.SH_CUST
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
        
       -- nCheckpoint := 11;
        v_query := 'TRUNCATE TABLE TMP_PACKING_FEES';
        EXECUTE IMMEDIATE v_query;
  
        IF To_Number(regexp_substr(sCust_Rates,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) != 0 
        AND sCustomerCode != 'BEYONDBL' OR sCustomerCode != 'TABCORP'
        Then
          ----DBMS_OUTPUT.PUT_LINE('G3_PACKING_FEES Inner rates are $' || sCust_Rates || '. G3_PACKING_FEES Outer rates are $' || sCust_Rates2 || '. Prism rate fields are RM_XX_FEE08 * RM_XX_FEE09.');      
          
          nCheckpoint := 2;
          If (sOp = 'PRJ' or sOp = 'DEV') Then
            v_query := 'TRUNCATE TABLE DEV_PACKING_FEES';
            EXECUTE IMMEDIATE v_query;
            OPEN cDEV;
            ----DBMS_OUTPUT.PUT_LINE(sCustomerCode || '.' );
            LOOP
            FETCH cDEV BULK COLLECT INTO l_data LIMIT p_array_size;
    
            FORALL i IN 1..l_data.COUNT
            ----DBMS_OUTPUT.PUT_LINE(i || '.' );
            INSERT INTO DEV_PACKING_FEES VALUES l_data(i);
            --USING sCust;
            EXIT WHEN cDEV%NOTFOUND;
            END LOOP;
           -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            CLOSE cDEV;
          Else
            v_query := 'TRUNCATE TABLE TMP_PACKING_FEES';
            EXECUTE IMMEDIATE v_query;
            OPEN c;
            ----DBMS_OUTPUT.PUT_LINE(sCustomerCode || '.' );
            LOOP
            FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
    
            FORALL i IN 1..l_data.COUNT
            ----DBMS_OUTPUT.PUT_LINE(i || '.' );
            INSERT INTO TMP_PACKING_FEES VALUES l_data(i);
            --USING sCust;
            EXIT WHEN c%NOTFOUND;
            END LOOP;
           -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            CLOSE c;
        End If;

          -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
          ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          --END LOOP;
          v_query2 :=  SQL%ROWCOUNT;
      COMMIT;
  
          IF v_query2 > 0 THEN
            v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
            If (sOp = 'PRJ' or sOp = 'DEV') Then
              EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'G3_PACKING_FEES','SL','DEV_PACKING_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
            Else
              EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'G3_PACKING_FEES','SL','TMP_PACKING_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
            End If;
            --DBMS_OUTPUT.PUT_LINE('G3_PACKING_FEES for the date range '
            --|| startdate || ' -- ' || enddate || ' - ' || v_query2
           -- || ' records inserted into table TMP_PACKING_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
           -- || ' Seconds...for customer ' || sCustomerCode );
          --Else
            --DBMS_OUTPUT.PUT_LINE('G3_PACKING_FEES rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
           -- ' Seconds...for customer ' || sCustomerCode);
          END IF;
       --Else
        --DBMS_OUTPUT.PUT_LINE('G3_PACKING_FEES rates are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
        --' Seconds...for customer ' || sCustomerCode);
      END IF;
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('G3_PACKING_FEES failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
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
    PROCEDURE G4_HANDLING_FEES_F (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
        ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
        ,sCustomerCode IN VARCHAR2
        ,sAnalysis IN RM.RM_ANAL%TYPE
        ,sFilterBy IN VARCHAR2
        ,sOp IN VARCHAR2
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
            CASE    
              WHEN r.sGroupCust = 'VHAAUS' AND s.SH_CAMPAIGN = 'DIST' 
              AND t.ST_PSLIP IS NOT NULL
              THEN TO_NUMBER('0')
              WHEN t.ST_PSLIP IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)
              ELSE NULL
            END                      AS "UnitPrice",
            CASE    
            WHEN r.sGroupCust = 'VHAAUS' AND s.SH_CAMPAIGN = 'DIST' 
            AND t.ST_PSLIP IS NOT NULL
            THEN TO_NUMBER('0')
            WHEN t.ST_PSLIP IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)
            ELSE NULL
            END                                      AS "OWUnitPrice",
            CASE    
            WHEN r.sGroupCust = 'VHAAUS' AND s.SH_CAMPAIGN = 'DIST' 
            AND t.ST_PSLIP IS NOT NULL
            THEN TO_NUMBER('0')
            WHEN t.ST_PSLIP IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)
            ELSE NULL
            END                      AS "DExcl",
            CASE    
            WHEN r.sGroupCust = 'VHAAUS' AND s.SH_CAMPAIGN = 'DIST' 
            AND t.ST_PSLIP IS NOT NULL
            THEN TO_NUMBER('0')
            WHEN t.ST_PSLIP IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * 1.1
            ELSE NULL
            END                      AS "DIncl",
            CASE    
            WHEN r.sGroupCust = 'VHAAUS' AND s.SH_CAMPAIGN = 'DIST' 
            AND t.ST_PSLIP IS NOT NULL
            THEN TO_NUMBER('0')
            WHEN t.ST_PSLIP IS NOT NULL THEN  (Select To_Number(i.IM_REPORTING_PRICE) from IM i where i.IM_STOCK = 'COURIERM')
            ELSE NULL
            END                      AS "ReportingPrice",
            NULL,
            NULL,
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
      --  FROM  ST t LEFT JOIN PWIN175.SH s ON  LTrim(s.SH_ORDER) = LTrim(t.ST_ORDER)
        --    LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
            
        FROM      SD d
         INNER JOIN SH s  ON s.SH_ORDER  = d.SD_ORDER
          --INNER JOIN ST t  ON t.ST_PICK  = d.SD_LAST_PICK_NUM
          INNER JOIN SL l  ON l.SL_ORDER  = d.SD_ORDER  AND SL_ORDER_LINE = SD_LINE
          INNER JOIN ST t  ON t.ST_PICK  = l.SL_PICK
          INNER JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
          INNER JOIN IM i  ON i.IM_STOCK = d.SD_STOCK
          --INNER JOIN NE n  ON n.NE_STOCK = l.SL_UID
          INNER JOIN IU ON IU_UNIT = i.IM_LEVEL_UNIT    
        WHERE  d.SD_STATUS <> 3
            AND (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
            AND (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) > 0.1
            AND t.ST_PSLIP <> 'CANCELLED'
            AND SL_PSLIP_QTY >= 1
            AND t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate
      GROUP BY
          s.SH_ORDER,r.sGroupCust,r.sCust,s.SH_SPARE_STR_4,s.SH_CUST,t.ST_PICK,t.ST_PSLIP,
          t.ST_DESP_DATE,s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_ADD_DATE,
          s.SH_NOTE_2,t.ST_WEIGHT,t.ST_PACKAGES,s.SH_SPARE_DBL_9,r.sGroupCust,
          s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,s.SH_SPARE_INT_4,s.SH_SPARE_STR_5,s.SH_CAMPAIGN,NULL,NULL,NULL;
    
    CURSOR cDEV
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
            CASE    
              WHEN r.sGroupCust = 'VHAAUS' AND s.SH_CAMPAIGN = 'DIST' 
              AND t.ST_PSLIP IS NOT NULL
              THEN TO_NUMBER('0')
              WHEN t.ST_PSLIP IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)
              ELSE NULL
            END                      AS "UnitPrice",
            CASE    
            WHEN r.sGroupCust = 'VHAAUS' AND s.SH_CAMPAIGN = 'DIST' 
            AND t.ST_PSLIP IS NOT NULL
            THEN TO_NUMBER('0')
            WHEN t.ST_PSLIP IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)
            ELSE NULL
            END                                      AS "OWUnitPrice",
            CASE    
            WHEN r.sGroupCust = 'VHAAUS' AND s.SH_CAMPAIGN = 'DIST' 
            AND t.ST_PSLIP IS NOT NULL
            THEN TO_NUMBER('0')
            WHEN t.ST_PSLIP IS NOT NULL THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)
            ELSE NULL
            END                      AS "DExcl",
            CASE    
            WHEN r.sGroupCust = 'VHAAUS' AND s.SH_CAMPAIGN = 'DIST' 
            AND t.ST_PSLIP IS NOT NULL
            THEN TO_NUMBER('0')
            WHEN t.ST_PSLIP IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * 1.1
            ELSE NULL
            END                      AS "DIncl",
            CASE    
            WHEN r.sGroupCust = 'VHAAUS' AND s.SH_CAMPAIGN = 'DIST' 
            AND t.ST_PSLIP IS NOT NULL
            THEN TO_NUMBER('0')
            WHEN t.ST_PSLIP IS NOT NULL THEN  (Select To_Number(i.IM_REPORTING_PRICE) from IM i where i.IM_STOCK = 'COURIERM')
            ELSE NULL
            END                      AS "ReportingPrice",
            NULL,
            NULL,
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
      --  FROM  ST t LEFT JOIN PWIN175.SH s ON  LTrim(s.SH_ORDER) = LTrim(t.ST_ORDER)
        --    LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
            
        FROM      SD d
         INNER JOIN SH s  ON s.SH_ORDER  = d.SD_ORDER
          --INNER JOIN ST t  ON t.ST_PICK  = d.SD_LAST_PICK_NUM
          INNER JOIN SL l  ON l.SL_ORDER  = d.SD_ORDER  AND SL_ORDER_LINE = SD_LINE
          INNER JOIN ST t  ON t.ST_PICK  = l.SL_PICK
          INNER JOIN Dev_Group_Cust r ON r.sCust = s.SH_CUST
          INNER JOIN IM i  ON i.IM_STOCK = d.SD_STOCK
          --INNER JOIN NE n  ON n.NE_STOCK = l.SL_UID
          INNER JOIN IU ON IU_UNIT = i.IM_LEVEL_UNIT    
        WHERE  d.SD_STATUS <> 3
            AND (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
            AND (SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) > 0.1
            AND t.ST_PSLIP <> 'CANCELLED'
            AND SL_PSLIP_QTY >= 1
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
        
        --nCheckpoint := 11;
        v_query := 'TRUNCATE TABLE TMP_HANDLING_FEES';
        EXECUTE IMMEDIATE v_query;
          
        IF To_Number(regexp_substr(sCust_Rates,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) != 0 Then
          ----DBMS_OUTPUT.PUT_LINE('G4_HANDLING_FEES rates are $' || sCust_Rates || '. Prism rate field is RM_XX_FEE06.');
          
          nCheckpoint := 2;
          If (sOp = 'PRJ' or sOp = 'DEV') Then
             v_query := 'TRUNCATE TABLE DEV_HANDLING_FEES';
            EXECUTE IMMEDIATE v_query;
            OPEN cDEV;
            ----DBMS_OUTPUT.PUT_LINE(sCustomerCode || '.' );
            LOOP
            FETCH cDEV BULK COLLECT INTO l_data LIMIT p_array_size;
    
            FORALL i IN 1..l_data.COUNT
            ----DBMS_OUTPUT.PUT_LINE(i || '.' );
            INSERT INTO DEV_HANDLING_FEES VALUES l_data(i);
            --USING sCust;
            EXIT WHEN cDEV%NOTFOUND;
            END LOOP;
           -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            CLOSE cDEV;
          Else
             v_query := 'TRUNCATE TABLE TMP_HANDLING_FEES';
            EXECUTE IMMEDIATE v_query;
            OPEN c;
            ----DBMS_OUTPUT.PUT_LINE(sCustomerCode || '.' );
            LOOP
            FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
    
            FORALL i IN 1..l_data.COUNT
            ----DBMS_OUTPUT.PUT_LINE(i || '.' );
            INSERT INTO TMP_HANDLING_FEES VALUES l_data(i);
            --USING sCust;
            EXIT WHEN c%NOTFOUND;
            END LOOP;
           -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            CLOSE c;

          End If;
          -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
          ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          --END LOOP;
          v_query2 :=  SQL%ROWCOUNT;
      COMMIT;
  
         IF v_query2 > 0 THEN
            v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
            If (sOp = 'PRJ' or sOp = 'DEV') Then
              EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'G4_HANDLING_FEES_F','SL','DEV_HANDLING_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
            Else
              EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'G4_HANDLING_FEES_F','SL','TMP_HANDLING_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
            End If;
            --DBMS_OUTPUT.PUT_LINE('G4_HANDLING_FEES_F for the date range '
           -- || startdate || ' -- ' || enddate || ' - ' || v_query2
           -- || ' records inserted into table TMP_HANDLING_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
           -- || ' Seconds...for customer ' || sCustomerCode );
          --Else
            --DBMS_OUTPUT.PUT_LINE('G4_HANDLING_FEES_F rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
           -- ' Seconds...for customer ' || sCustomerCode);
          END IF;
      --Else
        --DBMS_OUTPUT.PUT_LINE('G4_HANDLING_FEES_F rates are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
       -- ' Seconds...for customer ' || sCustomerCode);
      END IF;
      EXCEPTION
       WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('G4_HANDLING_FEES_F failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
       WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('G4_HANDLING_FEES_F failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
    END G4_HANDLING_FEES_F;
  
    /*   G4_HANDLING_FEES Run this once for each customer   */
    /*   This gets all the Handeling Related Data   */
    /*   Temp Tables Used   */
    /*   1. TMP_HANDLING_FEES   Handling Fee  */
    /*   Prism Rate Field Used   */
    /*   A. RM_XX_FEE06   */
    PROCEDURE G4_HANDLING_FEES_F2 (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
        ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
        ,sCustomerCode IN VARCHAR2
        ,sAnalysis IN RM.RM_ANAL%TYPE
        ,sFilterBy IN VARCHAR2
        ,sOp IN VARCHAR2
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
            CASE    WHEN t.ST_PSLIP IS NOT NULL THEN 'Pick Fee is '
            ELSE NULL
            END                      AS "FeeType",
            CASE    WHEN t.ST_PSLIP IS NOT NULL THEN  'Picking'
            ELSE NULL
            END                     AS "Item",
            CASE    WHEN t.ST_PSLIP IS NOT NULL THEN  'Pick Fee'
            ELSE NULL
            END                     AS "Description",
            (Select Max(SL_LINE) from SL Where SL_PICK = t.ST_PICK)   AS "Qty",
            CASE    WHEN t.ST_PSLIP IS NOT NULL THEN  '1'
            ELSE ''
            END                     AS "UOI",
            CASE    WHEN t.ST_PSLIP IS NOT NULL  
            AND (Select Max(SL_LINE) from SL Where SL_PICK = t.ST_PICK) 
            > 
            f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) AND f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) > 0
            THEN 
            f_get_fee('RM_XX_FEE36',r.sGroupCust)
            ELSE f_get_fee('RM_XX_FEE16',r.sGroupCust) 
            END                      AS "UnitPrice",
            CASE    WHEN t.ST_PSLIP IS NOT NULL  
            AND (Select Max(SL_LINE) from SL Where SL_PICK = t.ST_PICK) 
            > 
            f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) AND f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) > 0
            THEN 
            f_get_fee('RM_XX_FEE36',r.sGroupCust)
            ELSE f_get_fee('RM_XX_FEE16',r.sGroupCust) 
            END                      AS "OWUnitPrice",
            CASE  WHEN t.ST_PSLIP IS NOT NULL  
            AND (Select Max(SL_LINE) from SL Where SL_PICK = t.ST_PICK) 
            > 
            f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) AND f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) > 0
            THEN  f_get_fee('RM_XX_FEE36',r.sGroupCust)  
            * 
            (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK)
            ELSE f_get_fee('RM_XX_FEE16',r.sGroupCust)  
            * 
            (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK)
            END                      AS "DExcl",
            CASE    WHEN t.ST_PSLIP IS NOT NULL  
            AND (Select Max(SL_LINE) from SL Where SL_PICK = t.ST_PICK) 
            > 
            f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) AND f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) > 0
            THEN (f_get_fee('RM_XX_FEE36',r.sGroupCust)  * (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK)) * 1.1
            ELSE (f_get_fee('RM_XX_FEE16',r.sGroupCust)  * (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK)) * 1.1
            END                      AS "DIncl",
            CASE    WHEN t.ST_PSLIP IS NOT NULL  
            AND (Select Max(SL_LINE) from SL Where SL_PICK = t.ST_PICK) 
            > 
            f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) AND f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) > 0
            THEN f_get_fee('RM_XX_FEE36',r.sGroupCust)  * (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK)
            ELSE (f_get_fee('RM_XX_FEE16',r.sGroupCust)  * (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK))
            END                      AS "ReportingPrice",
            NULL,
            NULL,
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
            (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK) AS "CountOfStocks",
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
        WHERE  s.SH_STATUS != 3
            AND (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
            AND (SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) > 0.1
            AND t.ST_PSLIP != 'CANCELLED'
             AND t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate
      GROUP BY
          s.SH_ORDER,r.sGroupCust,r.sCust,s.SH_SPARE_STR_4,s.SH_CUST,t.ST_PICK,t.ST_PSLIP,
          t.ST_DESP_DATE,s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_ADD_DATE,
          s.SH_NOTE_2,t.ST_WEIGHT,t.ST_PACKAGES,s.SH_SPARE_DBL_9,r.sGroupCust,
          s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,s.SH_SPARE_INT_4,s.SH_SPARE_STR_5,s.SH_CAMPAIGN,NULL,NULL,NULL;
    
    CURSOR cDEV
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
            CASE    WHEN t.ST_PSLIP IS NOT NULL THEN 'Pick Fee is '
            ELSE NULL
            END                      AS "FeeType",
            CASE    WHEN t.ST_PSLIP IS NOT NULL THEN  'Picking'
            ELSE NULL
            END                     AS "Item",
            CASE    WHEN t.ST_PSLIP IS NOT NULL THEN  'Pick Fee'
            ELSE NULL
            END                     AS "Description",
            (Select Max(SL_LINE) from SL Where SL_PICK = t.ST_PICK)   AS "Qty",
            CASE    WHEN t.ST_PSLIP IS NOT NULL THEN  '1'
            ELSE ''
            END                     AS "UOI",
            CASE    WHEN t.ST_PSLIP IS NOT NULL  
            AND (Select Max(SL_LINE) from SL Where SL_PICK = t.ST_PICK) 
            > 
            f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) AND f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) > 0
            THEN 
            f_get_fee('RM_XX_FEE36',r.sGroupCust)
            ELSE f_get_fee('RM_XX_FEE16',r.sGroupCust) 
            END                      AS "UnitPrice",
            CASE    WHEN t.ST_PSLIP IS NOT NULL  
            AND (Select Max(SL_LINE) from SL Where SL_PICK = t.ST_PICK) 
            > 
            f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) AND f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) > 0
            THEN 
            f_get_fee('RM_XX_FEE36',r.sGroupCust)
            ELSE f_get_fee('RM_XX_FEE16',r.sGroupCust) 
            END                      AS "OWUnitPrice",
            CASE  WHEN t.ST_PSLIP IS NOT NULL  
            AND (Select Max(SL_LINE) from SL Where SL_PICK = t.ST_PICK) 
            > 
            f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) AND f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) > 0
            THEN  f_get_fee('RM_XX_FEE36',r.sGroupCust)  
            * 
            (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK)
            ELSE f_get_fee('RM_XX_FEE16',r.sGroupCust)  
            * 
            (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK)
            END                      AS "DExcl",
            CASE    WHEN t.ST_PSLIP IS NOT NULL  
            AND (Select Max(SL_LINE) from SL Where SL_PICK = t.ST_PICK) 
            > 
            f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) AND f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) > 0
            THEN (f_get_fee('RM_XX_FEE36',r.sGroupCust)  * (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK)) * 1.1
            ELSE (f_get_fee('RM_XX_FEE16',r.sGroupCust)  * (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK)) * 1.1
            END                      AS "DIncl",
            CASE    WHEN t.ST_PSLIP IS NOT NULL  
            AND (Select Max(SL_LINE) from SL Where SL_PICK = t.ST_PICK) 
            > 
            f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) AND f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) > 0
            THEN f_get_fee('RM_XX_FEE36',r.sGroupCust)  * (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK)
            ELSE (f_get_fee('RM_XX_FEE16',r.sGroupCust)  * (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK))
            END                      AS "ReportingPrice",
            NULL,
            NULL,
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
            (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK) AS "CountOfStocks",
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
            LEFT JOIN Dev_Group_Cust r ON r.sCust = s.SH_CUST
        WHERE  s.SH_STATUS != 3
            AND (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
            AND (SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) > 0.1
            AND t.ST_PSLIP != 'CANCELLED'
             AND t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate
      GROUP BY
          s.SH_ORDER,r.sGroupCust,r.sCust,s.SH_SPARE_STR_4,s.SH_CUST,t.ST_PICK,t.ST_PSLIP,
          t.ST_DESP_DATE,s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_ADD_DATE,
          s.SH_NOTE_2,t.ST_WEIGHT,t.ST_PACKAGES,s.SH_SPARE_DBL_9,r.sGroupCust,
          s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,s.SH_SPARE_INT_4,s.SH_SPARE_STR_5,s.SH_CAMPAIGN,NULL,NULL,NULL;
    
    QueryTable VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = :sCustomerCode5}';
    sCust_Rates RM.RM_XX_FEE16%TYPE;
    l_start number default dbms_utility.get_time;
     BEGIN
        nCheckpoint := 10;
        EXECUTE IMMEDIATE QueryTable INTO sCust_Rates USING sCustomerCode;
        
        --nCheckpoint := 11;
        
          
        IF To_Number(regexp_substr(sCust_Rates,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) != 0 Then
          ----DBMS_OUTPUT.PUT_LINE('G4_HANDLING_FEES rates are $' || sCust_Rates || '. Prism rate field is RM_XX_FEE06.');
          
          nCheckpoint := 2;
          If (sOp = 'PRJ' or sOp = 'DEV') Then
            v_query := 'TRUNCATE TABLE DEV_PICK_FEES';
            EXECUTE IMMEDIATE v_query;
            OPEN cDEV;
            ----DBMS_OUTPUT.PUT_LINE(sCustomerCode || '.' );
            LOOP
            FETCH cDEV BULK COLLECT INTO l_data LIMIT p_array_size;
    
            FORALL i IN 1..l_data.COUNT
            ----DBMS_OUTPUT.PUT_LINE(i || '.' );
            INSERT INTO DEV_PICK_FEES VALUES l_data(i);
            --USING sCust;
            EXIT WHEN cDEV%NOTFOUND;
            END LOOP;
           -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            CLOSE cDEV;
          Else
            v_query := 'TRUNCATE TABLE TMP_PICK_FEES';
            EXECUTE IMMEDIATE v_query;
            OPEN c;
            ----DBMS_OUTPUT.PUT_LINE(sCustomerCode || '.' );
            LOOP
            FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
    
            FORALL i IN 1..l_data.COUNT
            ----DBMS_OUTPUT.PUT_LINE(i || '.' );
            INSERT INTO TMP_PICK_FEES VALUES l_data(i);
            --USING sCust;
            EXIT WHEN c%NOTFOUND;
            END LOOP;
           -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            CLOSE c;
          End If;
          -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
          ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          --END LOOP;
          v_query2 :=  SQL%ROWCOUNT;
      COMMIT;
  
         IF v_query2 > 0 THEN
            v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
            If (sOp = 'PRJ' or sOp = 'DEV') Then
              EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'G4_HANDLING_FEES_F2','SL','DEV_PICK_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
            Else
              EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'G4_HANDLING_FEES_F2','SL','TMP_PICK_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
            End IF;
            --DBMS_OUTPUT.PUT_LINE('G4_HANDLING_FEES_F2 for the date range '
           -- || startdate || ' -- ' || enddate || ' - ' || v_query2
           -- || ' records inserted into table TMP_PICK_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
           -- || ' Seconds...for customer ' || sCustomerCode );
          --Else
            --DBMS_OUTPUT.PUT_LINE('G4_HANDLING_FEES_F2 rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
           -- ' Seconds...for customer ' || sCustomerCode);
          END IF;
      --Else
        --DBMS_OUTPUT.PUT_LINE('G4_HANDLING_FEES_F2 rates are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
       -- ' Seconds...for customer ' || sCustomerCode);
      END IF;
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('G4_HANDLING_FEES_F failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
       WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('G4_HANDLING_FEES_F2 failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
    END G4_HANDLING_FEES_F2;
 
 
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
        ,sFilterBy IN VARCHAR2
        ,sOp IN VARCHAR2
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
  
    SELECT s.SH_CUST                AS "Customer",
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
         (Select Max(SL_LINE) from SL Where SL_PICK = t.ST_PICK)  AS "Qty",
         CASE    WHEN t.ST_PSLIP IS NOT NULL THEN  '1'
          ELSE ''
          END                     AS "UOI",
        CASE 
          WHEN sCustomerCode = 'VHAAUS' AND s.SH_CAMPAIGN = 'DIST'
            AND t.ST_PSLIP IS NOT NULL
            THEN TO_NUMBER('0')
          WHEN t.ST_PSLIP IS NOT NULL  
            AND (Select Max(SL_LINE) from SL Where SL_PICK = t.ST_PICK) 
            > 
            f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) AND f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) > 0
            THEN 
            f_get_fee('RM_XX_FEE36',r.sGroupCust)
          ELSE f_get_fee('RM_XX_FEE16',r.sGroupCust) 
        END                      AS "UnitPrice",
        CASE    
          WHEN sCustomerCode = 'VHAAUS' AND s.SH_CAMPAIGN = 'DIST'
              AND t.ST_PSLIP IS NOT NULL
              THEN TO_NUMBER('0')
          WHEN t.ST_PSLIP IS NOT NULL  
          AND (Select Max(SL_LINE) from SL Where SL_PICK = t.ST_PICK) 
          > 
          f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) AND f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) > 0
          THEN 
          f_get_fee('RM_XX_FEE36',r.sGroupCust)
          ELSE f_get_fee('RM_XX_FEE16',r.sGroupCust) 
        END                      AS "OWUnitPrice",
        CASE  
        WHEN sCustomerCode = 'VHAAUS' AND s.SH_CAMPAIGN = 'DIST'
            AND t.ST_PSLIP IS NOT NULL
            THEN TO_NUMBER('0')
          WHEN t.ST_PSLIP IS NOT NULL  
          AND (Select Max(SL_LINE) from SL Where SL_PICK = t.ST_PICK) 
          > 
          f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) AND f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) > 0
          THEN  f_get_fee('RM_XX_FEE36',r.sGroupCust)  
          * 
          (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK)
          ELSE f_get_fee('RM_XX_FEE16',r.sGroupCust)  
          * 
          (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK)
        END                      AS "DExcl",
        CASE    
        WHEN sCustomerCode = 'VHAAUS' AND s.SH_CAMPAIGN = 'DIST' 
            AND t.ST_PSLIP IS NOT NULL
            THEN TO_NUMBER('0')
        WHEN t.ST_PSLIP IS NOT NULL  
        AND (Select Max(SL_LINE) from SL Where SL_PICK = t.ST_PICK) 
        > 
        f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) AND f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) > 0
        THEN (f_get_fee('RM_XX_FEE36',r.sGroupCust)  * (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK)) * 1.1
        ELSE (f_get_fee('RM_XX_FEE16',r.sGroupCust)  * (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK)) * 1.1
        END                      AS "DIncl",
        CASE    
        WHEN sCustomerCode = 'VHAAUS' AND s.SH_CAMPAIGN = 'DIST' 
            AND t.ST_PSLIP IS NOT NULL
            THEN TO_NUMBER('0')
        WHEN t.ST_PSLIP IS NOT NULL  
        AND (Select Max(SL_LINE) from SL Where SL_PICK = t.ST_PICK) 
        > 
        f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) AND f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) > 0
        THEN f_get_fee('RM_XX_FEE36',r.sGroupCust)  * (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK)
        ELSE (f_get_fee('RM_XX_FEE16',r.sGroupCust)  * (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK))
        END                      AS "ReportingPrice",
        NULL,
        NULL,
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
  AND t.ST_PSLIP NOT LIKE 'CANCELLED%'
  AND ((r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)   AND  (s.SH_CUST != 'WBCMER'))
  AND (SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = 'BEYONDBL') > 0.1
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
      
      CURSOR cDEV
      IS
    /* Pick fees  */
  
    SELECT s.SH_CUST                AS "Customer",
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
         (Select Max(SL_LINE) from SL Where SL_PICK = t.ST_PICK)  AS "Qty",
         CASE    WHEN t.ST_PSLIP IS NOT NULL THEN  '1'
          ELSE ''
          END                     AS "UOI",
        CASE 
          WHEN sCustomerCode = 'VHAAUS' AND s.SH_CAMPAIGN = 'DIST'
            AND t.ST_PSLIP IS NOT NULL
            THEN TO_NUMBER('0')
          WHEN t.ST_PSLIP IS NOT NULL  
            AND (Select Max(SL_LINE) from SL Where SL_PICK = t.ST_PICK) 
            > 
            f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) AND f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) > 0
            THEN 
            f_get_fee('RM_XX_FEE36',r.sGroupCust)
          ELSE f_get_fee('RM_XX_FEE16',r.sGroupCust) 
        END                      AS "UnitPrice",
        CASE    
          WHEN sCustomerCode = 'VHAAUS' AND s.SH_CAMPAIGN = 'DIST'
              AND t.ST_PSLIP IS NOT NULL
              THEN TO_NUMBER('0')
          WHEN t.ST_PSLIP IS NOT NULL  
          AND (Select Max(SL_LINE) from SL Where SL_PICK = t.ST_PICK) 
          > 
          f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) AND f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) > 0
          THEN 
          f_get_fee('RM_XX_FEE36',r.sGroupCust)
          ELSE f_get_fee('RM_XX_FEE16',r.sGroupCust) 
        END                      AS "OWUnitPrice",
        CASE  
        WHEN sCustomerCode = 'VHAAUS' AND s.SH_CAMPAIGN = 'DIST'
            AND t.ST_PSLIP IS NOT NULL
            THEN TO_NUMBER('0')
          WHEN t.ST_PSLIP IS NOT NULL  
          AND (Select Max(SL_LINE) from SL Where SL_PICK = t.ST_PICK) 
          > 
          f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) AND f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) > 0
          THEN  f_get_fee('RM_XX_FEE36',r.sGroupCust)  
          * 
          (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK)
          ELSE f_get_fee('RM_XX_FEE16',r.sGroupCust)  
          * 
          (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK)
        END                      AS "DExcl",
        CASE    
        WHEN sCustomerCode = 'VHAAUS' AND s.SH_CAMPAIGN = 'DIST' 
            AND t.ST_PSLIP IS NOT NULL
            THEN TO_NUMBER('0')
        WHEN t.ST_PSLIP IS NOT NULL  
        AND (Select Max(SL_LINE) from SL Where SL_PICK = t.ST_PICK) 
        > 
        f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) AND f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) > 0
        THEN (f_get_fee('RM_XX_FEE36',r.sGroupCust)  * (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK)) * 1.1
        ELSE (f_get_fee('RM_XX_FEE16',r.sGroupCust)  * (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK)) * 1.1
        END                      AS "DIncl",
        CASE    
        WHEN sCustomerCode = 'VHAAUS' AND s.SH_CAMPAIGN = 'DIST' 
            AND t.ST_PSLIP IS NOT NULL
            THEN TO_NUMBER('0')
        WHEN t.ST_PSLIP IS NOT NULL  
        AND (Select Max(SL_LINE) from SL Where SL_PICK = t.ST_PICK) 
        > 
        f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) AND f_get_fee('RM_XX_FEE01OR01',r.sGroupCust) > 0
        THEN f_get_fee('RM_XX_FEE36',r.sGroupCust)  * (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK)
        ELSE (f_get_fee('RM_XX_FEE16',r.sGroupCust)  * (Select MAX(SL_LINE) from SL Where SL_PICK = t.ST_PICK))
        END                      AS "ReportingPrice",
        NULL,
        NULL,
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
	LEFT JOIN Dev_Group_Cust r ON r.sCust = s.SH_CUST
	WHERE   s.SH_STATUS <> 3
  AND t.ST_PSLIP NOT LIKE 'CANCELLED%'
  AND ((r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)   AND  (s.SH_CUST != 'WBCMER'))
  AND (SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = 'BEYONDBL') > 0.1
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
      
     -- nCheckpoint := 11;
      
          
      IF To_Number(regexp_substr(sCust_Rates,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) != 0 Then
         -- l_start number default dbms_utility.get_time;
          
         -- --DBMS_OUTPUT.PUT_LINE('G5_PICK_FEES rates are $' || sCust_Rates || '. Prism rate field is RM_XX_FEE16.');
          
  
          nCheckpoint := 2;
           If (sOp = 'PRJ' or sOp = 'DEV') Then
            v_query := 'TRUNCATE TABLE DEV_PICK_FEES';
            EXECUTE IMMEDIATE v_query;
              OPEN cDEV;
              ----DBMS_OUTPUT.PUT_LINE(sCustomerCode || '.' );
              LOOP
              FETCH cDEV BULK COLLECT INTO l_data LIMIT p_array_size;
      
              FORALL i IN 1..l_data.COUNT
              ----DBMS_OUTPUT.PUT_LINE(i || '.' );
              INSERT INTO DEV_PICK_FEES VALUES l_data(i);
              --USING sCust;
              EXIT WHEN cDEV%NOTFOUND;
              END LOOP;
             -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
              CLOSE cDEV;
            Else
              v_query := 'TRUNCATE TABLE TMP_PICK_FEES';
              EXECUTE IMMEDIATE v_query;
              OPEN c;
              ----DBMS_OUTPUT.PUT_LINE(sCustomerCode || '.' );
              LOOP
              FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
      
              FORALL i IN 1..l_data.COUNT
              ----DBMS_OUTPUT.PUT_LINE(i || '.' );
              INSERT INTO TMP_PICK_FEES VALUES l_data(i);
              --USING sCust;
              EXIT WHEN c%NOTFOUND;
              END LOOP;
             -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
              CLOSE c;
          End If;
          -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
          ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          --END LOOP;
          v_query2 :=  SQL%ROWCOUNT;
      COMMIT;
  
      IF v_query2 > 0 THEN
        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
        If (sOp = 'PRJ' or sOp = 'DEV') Then
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'G5_PICK_FEES_F','ST','DEV_PICK_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        Else
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'G5_PICK_FEES_F','ST','TMP_PICK_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        End If;
        --DBMS_OUTPUT.PUT_LINE('G5_PICK_FEES_F for the date range '
       -- || startdate || ' -- ' || enddate || ' - ' || v_query2
       -- || ' records inserted into table TMP_PICK_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
       -- || ' Seconds...for customer ' || sCustomerCode );
      --Else
        --DBMS_OUTPUT.PUT_LINE('G5_PICK_FEES_F rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
       -- ' Seconds...for customer ' || sCustomerCode);
      END IF;
       --Else
        --DBMS_OUTPUT.PUT_LINE('G5_PICK_FEES_F rates are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
       -- ' Seconds...for customer ' || sCustomerCode);
      END IF;
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('G5_PICK_FEES_F failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
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
    PROCEDURE G5_PICK_FEES_F2 (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
      ,sAnalysis IN RM.RM_ANAL%TYPE
      ,sOp IN VARCHAR2
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
  AND t.ST_PSLIP NOT LIKE 'CANCELLED%'
  AND (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
  AND r.sGroupCust != 'WBCMER'
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
    
    --nCheckpoint := 11;
    
        
    IF To_Number(regexp_substr(sCust_Rates,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) != 0 Then
       -- l_start number default dbms_utility.get_time;
        
       -- --DBMS_OUTPUT.PUT_LINE('G5_PICK_FEES rates are $' || sCust_Rates || '. Prism rate field is RM_XX_FEE16.');
        

        nCheckpoint := 2;
        If (sOp = 'PRJ' or sOp = 'DEV') Then
          v_query := 'TRUNCATE TABLE DEV_PICK_FEES';
          EXECUTE IMMEDIATE v_query;
          OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(sCustomerCode || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO DEV_PICK_FEES VALUES l_data(i);
          --USING sCust;
          EXIT WHEN c%NOTFOUND;
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
        Else
          v_query := 'TRUNCATE TABLE TMP_PICK_FEES';
          EXECUTE IMMEDIATE v_query;
          OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(sCustomerCode || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO TMP_PICK_FEES VALUES l_data(i);
          --USING sCust;
          EXIT WHEN c%NOTFOUND;
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
        End If;
        -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
        ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        --END LOOP;
        v_query2 :=  SQL%ROWCOUNT;
    COMMIT;

    IF v_query2 > 0 THEN
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      If (sOp = 'PRJ' or sOp = 'DEV') Then
        EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'G5_PICK_FEES_F','ST','DEV_PICK_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
      Else
        EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'G5_PICK_FEES_F','ST','TMP_PICK_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
      End If;
      --DBMS_OUTPUT.PUT_LINE('G5_PICK_FEES_F for the date range '
     -- || startdate || ' -- ' || enddate || ' - ' || v_query2
     -- || ' records inserted into table TMP_PICK_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
     -- || ' Seconds...for customer ' || sCustomerCode );
    --Else
      --DBMS_OUTPUT.PUT_LINE('G5_PICK_FEES_F rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
     -- ' Seconds...for customer ' || sCustomerCode);
    END IF;
     --Else
      --DBMS_OUTPUT.PUT_LINE('G5_PICK_FEES_F rates are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
     -- ' Seconds...for customer ' || sCustomerCode);
    END IF;
    EXCEPTION
        WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('G5_PICK_FEES_F failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
    RAISE;
  END G5_PICK_FEES_F2;

 
    
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
        ,sFilterBy IN VARCHAR2
        ,sOp IN VARCHAR2
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
      ( (SELECT To_Number(regexp_substr(RM_XX_FEE21,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * (SELECT Count(RD_CODE) FROM PWIN175.RD WHERE RD_CUST IN ( SELECT RM_CUST FROM PWIN175.RM WHERE (RM_PARENT = sCustomerCode) AND SubStr(RD_CODE,0,2) NOT LIKE 'WH'  AND RD_CODE <> 'DIRECT'))) * 1.1         AS "DIncl",
       (SELECT To_Number(regexp_substr(RM_XX_FEE21,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)                     AS "ReportingPrice",
       NULL,
       NULL,
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
      ( (SELECT To_Number(regexp_substr(RM_XX_FEE20,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)  * total_count_by_cust(sCustomerCode)) * 1.1         AS "DIncl",
      (SELECT To_Number(regexp_substr(RM_XX_FEE20,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)                     AS "ReportingPrice",
      NULL,
      NULL,
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
      ( (SELECT To_Number(regexp_substr(RM_XX_FEE19,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)  * 1.1)         AS "DIncl",
       (SELECT To_Number(regexp_substr(RM_XX_FEE19,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)                    AS "ReportingPrice",
       NULL,
       NULL,
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
  
  
      --nCheckpoint := 1;
       
  
      nCheckpoint := 2;
        If (sOp = 'PRJ' or sOp = 'DEV') Then
           v_query := 'TRUNCATE TABLE DEV_MISC_FEES';
          EXECUTE IMMEDIATE v_query;
          OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(sCustomerCode || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO DEV_MISC_FEES VALUES l_data(i);
          --USING sCustomerCode;
  
          EXIT WHEN c%NOTFOUND;
  
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
        Else
           v_query := 'TRUNCATE TABLE TMP_MISC_FEES';
          EXECUTE IMMEDIATE v_query;
          OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(sCustomerCode || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO TMP_MISC_FEES VALUES l_data(i);
          --USING sCustomerCode;
  
          EXIT WHEN c%NOTFOUND;
  
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
        End If;
        -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
          ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        --END LOOP;
    v_query2 :=  SQL%ROWCOUNT;
    COMMIT;
  
      IF v_query2 > 0 THEN
        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
        If (sOp = 'PRJ' or sOp = 'DEV') Then
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'I_EOM_MISC_FEES','RM','DEV_MISC_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        Else
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'I_EOM_MISC_FEES','RM','TMP_MISC_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        End If;
        --DBMS_OUTPUT.PUT_LINE('I_EOM_MISC_FEES for the date range '
       -- || startdate || ' -- ' || enddate || ' - ' || v_query2
       -- || ' records inserted into table TMP_MISC_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
       -- || ' Seconds...for customer ' || sCustomerCode );
      --Else
        --DBMS_OUTPUT.PUT_LINE('I_EOM_MISC_FEES rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
       -- ' Seconds...for customer ' || sCustomerCode);
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
        ,sOp IN VARCHAR2
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
      ----DBMS_OUTPUT.PUT_LINE(start_date || ' - ' || end_date || '.' || sCust );
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
      CASE WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1 -- ((Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1
         WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1 --  ((Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1
         ELSE NULL
         END                      AS "DIncl",
      CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN (Select i.IM_REPORTING_PRICE from IM i where i.IM_STOCK = d.SD_STOCK)
          ELSE NULL
          END                      AS "ReportingPrice",
          NULL,
          NULL,
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
     CASE  WHEN d.SD_STOCK = 'EMERQSRFEE' AND s.SH_CAMPAIGN = 'TABSPEC' THEN d.SD_INCL
          ELSE NULL
          END                      AS "DIncl",
      CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN (Select To_Number(i.IM_REPORTING_PRICE) from IM i where i.IM_STOCK = d.SD_STOCK)
          ELSE NULL
          END                      AS "ReportingPrice",
          NULL,
          NULL,
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
          WHEN i.IM_TYPE = 'BB_PACK'  THEN (Select To_Number(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode)   * 1.1
          ELSE NULL
          END      AS "DIncl",
         CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN (Select To_Number(i.IM_REPORTING_PRICE) from IM i where i.IM_STOCK = d.SD_STOCK)
          ELSE NULL
          END    AS "ReportingPrice",
          NULL,
          NULL,
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
    AND     (r.sCust = 'BEYONDBL' OR r.sGroupCust = 'BEYONDBL')
    AND     sCustomerCode = 'BEYONDBL'
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
  
      --nCheckpoint := 1;
        
  
      nCheckpoint := 2;
      If (sOp = 'PRJ' or sOp = 'DEV') Then
          v_query := 'TRUNCATE TABLE DEV_CUSTOMER_FEES';
          EXECUTE IMMEDIATE v_query;
          OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO DEV_CUSTOMER_FEES VALUES l_data(i);
          --USING sCust;
  
          EXIT WHEN c%NOTFOUND;
  
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
        Else
          v_query := 'TRUNCATE TABLE TMP_CUSTOMER_FEES';
          EXECUTE IMMEDIATE v_query;
          OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO TMP_CUSTOMER_FEES VALUES l_data(i);
          --USING sCust;
  
          EXIT WHEN c%NOTFOUND;
  
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
        End If;
       --  FOR i IN l_data.FIRST .. l_data.LAST LOOP
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
       -- END LOOP;
    v_query2 :=  SQL%ROWCOUNT;
    COMMIT;
    --RETURN;
        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
        If (sOp = 'PRJ' or sOp = 'DEV') Then
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'J_EOM_CUSTOMER_FEES','RM','DEV_CUSTOMER_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        Else
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'J_EOM_CUSTOMER_FEES','RM','TMP_CUSTOMER_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        End IF;
        --DBMS_OUTPUT.PUT_LINE('J_EOM_CUSTOMER_FEES for the date range '
       -- || startdate || ' -- ' || enddate || ' - ' || v_query2 || ' records inserted in ' ||  (round((dbms_utility.get_time-l_start)/100, 6)) ||
       -- ' Seconds...for customer ' || sCustomerCode);
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
        ,sOp IN VARCHAR2
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
      CASE  WHEN d.SD_STOCK = 'EMERQSRFEE' AND s.SH_CAMPAIGN = 'TABSPEC' THEN d.SD_INCL
          ELSE NULL
          END                      AS "DIncl",
      CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN (Select To_Number(i.IM_REPORTING_PRICE) from IM i where i.IM_STOCK = d.SD_STOCK)
          ELSE NULL
          END                      AS "ReportingPrice",
          NULL,
          NULL,
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
                i.IM_BRAND,i.IM_OWNED_By,i.IM_PROFILE,s.SH_XX_FEE_WAIVE,d.SD_COST_PRICE,s.SH_SPARE_INT_4;
   /*    UNION ALL
       Tabcorp Inner/Outer PackingFee
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
    CASE WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'INNER'   THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1 -- ((Select TO_NUMBER(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1
         WHEN Upper(i.IM_XX_QTY_PER_PACK) = 'OUTER'   THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1 --  ((Select TO_NUMBER(RM_XX_FEE09) from RM where RM_CUST = sCustomerCode) * d.SD_QTY_DESP) * 1.1
         ELSE NULL
         END                      AS "DIncl",
      CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN (Select i.IM_REPORTING_PRICE from IM i where i.IM_STOCK = d.SD_STOCK)
          ELSE NULL
          END                      AS "ReportingPrice",
          NULL,
          NULL,
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
    GROUP BY  s.SH_CUST,s.SH_SPARE_STR_4,s.SH_ORDER,t.ST_PICK,d.SD_XX_PICKLIST_NUM,s.SH_CAMPAIGN,
          t.ST_PSLIP,t.ST_DESP_DATE,i.IM_XX_QTY_PER_PACK,d.SD_STOCK,d.SD_DESC,
          d.SD_LINE,d.SD_EXCL,d.SD_INCL,d.SD_SELL_PRICE,d.SD_XX_OW_UNIT_PRICE,
          d.SD_QTY_ORDER,d.SD_QTY_ORDER,s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,
          s.SH_STATE,s.SH_POST_CODE,s.SH_NOTE_1,s.SH_NOTE_2,t.ST_WEIGHT,t.ST_PACKAGES,
          s.SH_SPARE_DBL_9,d.SD_QTY_DESP,r.sGroupCust,i.IM_XX_COST_CENTRE01,
          s.SH_SPARE_STR_5,s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,i.IM_BRAND,s.SH_SPARE_INT_4;*/
  
      BEGIN
  
      --nCheckpoint := 1;
        
  
      nCheckpoint := 2;
      If (sOp = 'PRJ' or sOp = 'DEV') Then
          v_query := 'TRUNCATE TABLE DEV_CUSTOMER_FEES';
          EXECUTE IMMEDIATE v_query;
          OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO DEV_CUSTOMER_FEES VALUES l_data(i);
          --USING sCust;
  
          EXIT WHEN c%NOTFOUND;
  
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
        Else
          v_query := 'TRUNCATE TABLE TMP_CUSTOMER_FEES';
          EXECUTE IMMEDIATE v_query;
          OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO TMP_CUSTOMER_FEES VALUES l_data(i);
          --USING sCust;
  
          EXIT WHEN c%NOTFOUND;
  
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
        End If;
       --  FOR i IN l_data.FIRST .. l_data.LAST LOOP
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
       -- END LOOP;
    v_query2 :=  SQL%ROWCOUNT;
    COMMIT;
  
     IF v_query2 > 0 THEN
        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
        If (sOp = 'PRJ' or sOp = 'DEV') Then
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'J_EOM_CUSTOMER_FEES_TAB','RM','DEV_CUSTOMER_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        Else
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'J_EOM_CUSTOMER_FEES_TAB','RM','TMP_CUSTOMER_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        End If;
        --DBMS_OUTPUT.PUT_LINE('J_EOM_CUSTOMER_FEES_TAB for the date range '
       -- || startdate || ' -- ' || enddate || ' - ' || v_query2
       -- || ' records inserted into table TMP_CUSTOMER_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
       -- || ' Seconds...for customer ' || sCustomerCode );
      --Else
        --DBMS_OUTPUT.PUT_LINE('J_EOM_CUSTOMER_FEES_TAB rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
       -- ' Seconds...for customer ' || sCustomerCode);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('J_EOM_CUSTOMER_FEES_TAB failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
  
        RAISE;
  
    END J_EOM_CUSTOMER_FEES_TAB;
  
    /*   J Run this once for BEYONDBL   */
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
        ,sOp IN VARCHAR2
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
      ----DBMS_OUTPUT.PUT_LINE(start_date || ' - ' || end_date || '.' || sCust );
      l_start number default dbms_utility.get_time;
  
  
      CURSOR c
      --(
        --start_date IN ST.ST_DESP_DATE%TYPE
      -- ,end_date IN ST.ST_DESP_DATE%TYPE
      --sCust IN RM.RM_CUST%TYPE
       --)
       IS
  
  
  /*BB PackingFee
  
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
          WHEN i.IM_TYPE = 'BB_PACK'  THEN (Select To_Number(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode)   * 1.1
          ELSE NULL
          END      AS "DIncl",
          CASE    WHEN d.SD_STOCK NOT like 'COURIER%' THEN (Select To_Number(i.IM_REPORTING_PRICE) from IM i where i.IM_STOCK = d.SD_STOCK)
          ELSE NULL
          END    AS "ReportingPrice",
          NULL,
          NULL,
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
          AND     i.IM_CUST  = 'BEYONDBL'
          AND       s.SH_ORDER = t.ST_ORDER
          AND       i.IM_TYPE = 'BB_PACK'
          AND        t.ST_DESP_DATE >= startdate AND t.ST_DESP_DATE <= enddate
          AND       d.SD_LAST_PICK_NUM = t.ST_PICK
          AND (Select To_Number(RM_XX_FEE08) from RM where RM_CUST = sCustomerCode) > 0.1
  
  UNION ALL
  
  
   Pallet In Fee*/
    SELECT  DISTINCT  IM_CUST                AS "Customer",
          sCustomerCode              AS "Parent",
          IM_XX_COST_CENTRE01       AS "CostCentre",
          NI_QJ_NUMBER               AS "Order",
          NULL         AS "OrderwareNum",
          NULL            AS "CustomerRef",
          NULL                AS "Pickslip",
          NULL     AS "DespatchNote",
          NULL               AS "DespatchDate",
          substr(To_Char(NE_DATE),0,10)            AS "OrdDate",
      CASE    WHEN NE_ENTRY IS NOT NULL THEN 'BB Pallet In Fee '
          ELSE ''
          END                      AS "FeeType",
          IM_STOCK               AS "Item",
          REPLACE(IM_DESC, ',')                     AS "Description",
          NE_QUANTITY          AS "Qty",
          IM_LEVEL_UNIT          AS "UOI",
      CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)-- * NE_QUANTITY)-- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
          ELSE NULL
          END                      AS "UnitPrice",
       NULL                     AS "OWUnitPrice",
       CASE    WHEN NE_ENTRY IS NOT NULL THEN  (((SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * NE_QUANTITY) * IU_TO_METRIC)-- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
          ELSE NULL
          END                      AS "DExcl",
       CASE    WHEN NE_ENTRY IS NOT NULL THEN ((((SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * NE_QUANTITY) * IU_TO_METRIC )* 1.1 )--  (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust) * 1.1
          ELSE NULL
          END                      AS "DIncl",
       CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) -- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
          ELSE NULL
          END                                           AS "ReportingPrice", --qty calc should be based on IU_TO_METRIC
          NULL,
          NULL,
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
          INNER JOIN PWIN175.NE  ON NE_ACCOUNT  = NA_ACCOUNT AND NA_EXT_TYPE = '1210067'
          INNER JOIN PWIN175.NI  ON NI_ENTRY = NE_ENTRY
          INNER JOIN PWIN175.RM  ON RM_CUST  = IM_CUST
          INNER JOIN IU u ON u.IU_UNIT = IM_LEVEL_UNIT
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
      
  
      nCheckpoint := 2;
       If (sOp = 'PRJ' or sOp = 'DEV') Then
           nCheckpoint := 11;
            v_query := 'TRUNCATE TABLE DEV_PAL_IN_FEES';
            EXECUTE IMMEDIATE v_query;
          nCheckpoint := 1;
            v_query := 'TRUNCATE TABLE DEV_CUSTOMER_FEES';
        EXECUTE IMMEDIATE v_query;
          OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO DEV_CUSTOMER_FEES VALUES l_data(i);
          --USING sCust;
  
          EXIT WHEN c%NOTFOUND;
  
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
        Else
           nCheckpoint := 11;
          v_query := 'TRUNCATE TABLE TMP_PAL_IN_FEES';
          EXECUTE IMMEDIATE v_query;
        nCheckpoint := 1;
          v_query := 'TRUNCATE TABLE TMP_CUSTOMER_FEES';
          EXECUTE IMMEDIATE v_query;
          OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO TMP_CUSTOMER_FEES VALUES l_data(i);
          --USING sCust;
  
          EXIT WHEN c%NOTFOUND;
  
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
        End If;
       --  FOR i IN l_data.FIRST .. l_data.LAST LOOP
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
       -- END LOOP;
    v_query2 :=  SQL%ROWCOUNT;
    COMMIT;
    --RETURN;
    ----DBMS_OUTPUT.PUT_LINE('J_EOM_CUSTOMER_FEES_BB for the date range '
      --  || startdate || ' -- ' || enddate || ' - ' || v_query2 || ' records inserted in ' ||  (round((dbms_utility.get_time-l_start)/100, 6)) ||
        --' Seconds...for customer ' || sCustomerCode);
    IF v_query2 > 0 THEN
        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
        If (sOp = 'PRJ' or sOp = 'DEV') Then
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'J_EOM_CUSTOMER_FEES_BB','RM','DEV_CUSTOMER_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        Else
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'J_EOM_CUSTOMER_FEES_BB','RM','TMP_CUSTOMER_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        End If;
        --DBMS_OUTPUT.PUT_LINE('J_EOM_CUSTOMER_FEES_BB for the date range '
        --|| startdate || ' -- ' || enddate || ' - ' || v_query2
        --|| ' records inserted into table TMP_CUSTOMER_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
        --|| ' Seconds...for customer ' || sCustomerCode );
      --Else
        --DBMS_OUTPUT.PUT_LINE('J_EOM_CUSTOMER_FEES_BB rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
       -- ' Seconds...for customer ' || sCustomerCode);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('J_EOM_CUSTOMER_FEES_BB at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
  
        RAISE;
  
    END J_EOM_CUSTOMER_FEES_BB;
  
    /*   J Run this once for WBC Merchant Orders   */
    /*   This gets all the Customer Specific Charges   */
    /*   Temp Tables Used   */
    /*   1. TMP_CUSTOMER_FEES   */
    /*   Prism Rate Field Used   */
    /*   A. RM_XX_FEE27   */
    PROCEDURE J_EOM_CUSTOMER_FEES_WBC (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,startdate IN VARCHAR2
        ,enddate IN VARCHAR2
        ,sCustomerCode IN VARCHAR2
        ,sOp IN VARCHAR2
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
      l_start number default dbms_utility.get_time;
      sCustomerCodeWBC VARCHAR2(20):= 'WBCMER';
      sCust_Rates RM.RM_XX_FEE27%TYPE;
      QueryTable VARCHAR2(600) := q'{Select f_get_fee('RM_XX_FEE27',:sCustomerCodeWBC) From DUAl}';
      CURSOR c
      IS
   /*MerchantOrderEntryFee*/
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
        'MerchantOrderFee'  AS "FeeType",
        'MERCHFEEORDER'    AS "Item",
        'Merchant Order Fee'     AS "Description",
        1        AS "Qty",
        1        AS "UOI",
        sCust_Rates        AS "UnitPrice",
        sCust_Rates        AS "OWUnitPrice",
        sCust_Rates        AS "DExcl",
        sCust_Rates        AS "Excl_Total",
        sCust_Rates     * 1.1             AS "DIncl",
        sCust_Rates     * 1.1      AS "Incl_Total",
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
	FROM  PWIN175.SH s
			  INNER JOIN PWIN175.SD d ON d.SD_ORDER  = s.SH_ORDER
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
	WHERE (r.sGroupCust = sCustomerCode OR r.sCust = sCustomerCode)
  AND       s.SH_ADD_DATE >= startdate AND s.SH_ADD_DATE <= enddate
	AND       d.SD_LINE = 1
  AND       s.SH_CUST = sCustomerCodeWBC; 
      BEGIN
       --nCheckpoint := 1;
       
       nCheckpoint := 2;
         EXECUTE IMMEDIATE QueryTable INTO sCust_Rates USING sCustomerCodeWBC;--Merch Ord Fee
       nCheckpoint := 3;
         If (sOp = 'PRJ' or sOp = 'DEV') Then
           v_query := 'TRUNCATE TABLE DEV_CUSTOMER_FEES';
          EXECUTE IMMEDIATE v_query;
          OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO DEV_CUSTOMER_FEES VALUES l_data(i);
          --USING sCust;
  
          EXIT WHEN c%NOTFOUND;
  
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
        Else
           v_query := 'TRUNCATE TABLE TMP_CUSTOMER_FEES';
          EXECUTE IMMEDIATE v_query;
          OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO TMP_CUSTOMER_FEES VALUES l_data(i);
          --USING sCust;
  
          EXIT WHEN c%NOTFOUND;
  
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
        End If;
        v_query2 :=  SQL%ROWCOUNT;
    COMMIT;  
    IF v_query2 > 0 THEN
        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
        If (sOp = 'PRJ' or sOp = 'DEV') Then
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'J_EOM_CUSTOMER_FEES_WBC','RM','DEV_CUSTOMER_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        Else
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'J_EOM_CUSTOMER_FEES_WBC','RM','TMP_CUSTOMER_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        End If;
    END IF;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('J_EOM_CUSTOMER_FEES_BB at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);  
        RAISE;  
    END J_EOM_CUSTOMER_FEES_WBC;  
    
    
    /*   J Run this once for VHA   */
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
        ,sOp IN VARCHAR2
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
      ----DBMS_OUTPUT.PUT_LINE(start_date || ' - ' || end_date || '.' || sCust );
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
        (Select To_Number(rm3.RM_XX_FEE32_1) from RM rm3 where rm3.RM_CUST = 'VHAAUS')   AS "DIncl",
        NULL AS "ReportingPrice",
        NULL,
        NULL,
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
  
   CURSOR o
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
        'UrgentOnlineOrderFee' AS "FeeType",'STRURGFEEORDER' AS "Item",'Urgent Online Order Fee' AS "Description",1 AS "Qty",'1' AS "UOI",
        (Select To_Number(rm3.RM_XX_FEE05) from RM rm3 where rm3.RM_CUST = 'VHAAUS')  AS "UnitPrice",
        (Select To_Number(rm3.RM_XX_FEE05) from RM rm3 where rm3.RM_CUST = 'VHAAUS')   AS "OWUnitPrice",
        (Select To_Number(rm3.RM_XX_FEE05) from RM rm3 where rm3.RM_CUST = 'VHAAUS')   AS "DExcl",
        (Select To_Number(rm3.RM_XX_FEE05) from RM rm3 where rm3.RM_CUST = 'VHAAUS')   AS "DIncl",
        NULL AS "ReportingPrice",
        NULL,
        NULL,
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
    AND       UPPER(s.SH_CUST_REF) Like '1%'
    AND       d.SD_LINE = 1
    AND t.ST_PSLIP != 'CANCELLED'
    --AND sCustomerCode = 'VHAAUS'
    AND (SELECT To_Number(regexp_substr(RM_XX_FEE05,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = 'VHAAUS') > 0.1
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
  
      --nCheckpoint := 1;
        
  
      nCheckpoint := 2;
          If (sOp = 'PRJ' or sOp = 'DEV') Then
            v_query := 'TRUNCATE TABLE DEV_CUSTOMER_FEES';
          EXECUTE IMMEDIATE v_query;
          OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO DEV_CUSTOMER_FEES VALUES l_data(i);
          --USING sCust;
  
          EXIT WHEN c%NOTFOUND;
  
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
        Else
          v_query := 'TRUNCATE TABLE TMP_CUSTOMER_FEES';
          EXECUTE IMMEDIATE v_query;
          OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO TMP_CUSTOMER_FEES VALUES l_data(i);
          --USING sCust;
  
          EXIT WHEN c%NOTFOUND;
  
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
        End If;
       --  FOR i IN l_data.FIRST .. l_data.LAST LOOP
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
       -- END LOOP;
       
       nCheckpoint := 3;
       If (sOp = 'PRJ' or sOp = 'DEV') Then
          OPEN o;
          ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
          LOOP
          FETCH o BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO DEV_CUSTOMER_FEES VALUES l_data(i);
          --USING sCust;
  
          EXIT WHEN o%NOTFOUND;
  
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE o;
        Else
          OPEN o;
          ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
          LOOP
          FETCH o BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO TMP_CUSTOMER_FEES VALUES l_data(i);
          --USING sCust;
  
          EXIT WHEN o%NOTFOUND;
  
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE o;
        End If;
       --  FOR i IN l_data.FIRST .. l_data.LAST LOOP
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
       -- END LOOP;
       
    v_query2 :=  SQL%ROWCOUNT;
    COMMIT;
  
    IF v_query2 > 0 THEN
        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
        If (sOp = 'PRJ' or sOp = 'DEV') Then
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'J_EOM_CUSTOMER_FEES_VHA','RM','DEV_CUSTOMER_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        Else
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'J_EOM_CUSTOMER_FEES_VHA','RM','TMP_CUSTOMER_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        End If;
        --DBMS_OUTPUT.PUT_LINE('J_EOM_CUSTOMER_FEES_VHA for the date range '
       -- || startdate || ' -- ' || enddate || ' - ' || v_query2
       -- || ' records inserted into table TMP_CUSTOMER_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
       -- || ' Seconds...for customer ' || sCustomerCode );
      --Else
        --DBMS_OUTPUT.PUT_LINE('J_EOM_CUSTOMER_FEES_VHA rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
       -- ' Seconds...for customer ' || sCustomerCode);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('J_EOM_CUSTOMER_FEES_VHA failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
  
        RAISE;
  
    END J_EOM_CUSTOMER_FEES_VHA;
    
    
    /*   J Run this once for Superpartners   */
    /*   This gets all the Customer Specific Charges   */
    /*   Temp Tables Used   */
    /*   1. TMP_CUSTOMER_FEES   */
    /*   Prism Rate Field Used   */
    /*   A. RM_XX_FEE32_1   
        Need to build into freight consolodation for daily flat rate deliveries
        as well to build into carton fees
    */
    PROCEDURE J_EOM_CUSTOMER_FEES_SUP (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
        ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
        ,sCustomerCode IN VARCHAR2
        ,p_filename in varchar2
        ,sOp IN VARCHAR2
      )
      IS
      TYPE ARRAY IS TABLE OF TMP_CUSTOMER_FEES%ROWTYPE;
      l_data ARRAY;
      v_out_tx          VARCHAR2(2000);
      l_query         VARCHAR2(25000);
      v_query           VARCHAR2(2000);
      v_query2          VARCHAR2(32767);
      nCheckpoint       NUMBER;
      sCourierm         VARCHAR2(20) := 'COURIERM';
      sCouriers         VARCHAR2(20) := 'COURIERS';
      sCourier         VARCHAR2(20) := 'COURIER%';
      sServ8             VARCHAR2(20) := 'SERV8';
      sServ3             VARCHAR2(20) := 'SERV%';
      l_output        utl_file.file_type;
      l_theCursor     integer default dbms_sql.open_cursor;
      l_columnValue   varchar2(4000);
      l_status        integer;
      l_colCnt        number := 0;
      l_separator     varchar2(1);
      l_descTbl       dbms_sql.desc_tab;
      v_time_taken VARCHAR2(205);
      sPath VARCHAR2(60) :=  'EOM_ADMIN_ORDERS';
      l_start number default dbms_utility.get_time;
      sFileSuffix VARCHAR2(60):= '.csv';
      sFileTime VARCHAR2(56)  := TO_CHAR(SYSDATE,'YYYYMMDD HH24MISS');
      filename VARCHAR2(260) := sCustomerCode || '-EOM-ADMIN-ORACLE-' || '-RunBy-' || sOp || '-RunOn-' || startdate || '-TO-' || enddate || '-RunAt-' || sFileTime || sFileSuffix;
      
      BEGIN
      
        nCheckpoint := 1;
        DBMS_OUTPUT.PUT_LINE('Checkpoint 1 J_EOM_CUSTOMER_FEES_SUP about to run startdate: ' || startdate ||
                            ' and enddate: ' || enddate || ' for:  ' || sCustomerCode);
--        v_query := 'TRUNCATE TABLE TMP_CUSTOMER_FEES';
--        EXECUTE IMMEDIATE v_query;
  
      nCheckpoint := 2;
      If (sOp = 'PRJ' or sOp = 'DEV') Then
          --run specific formatting query for superpartners
           l_query := q'{
           Select  to_date(f1.DESPDATE,'dd/mm/yyyy'),f1.ORDERNUM,f1.DESPNOTE,f1.CUSTOMER,
            f1.ATTENTIONTO,f1.ADDRESS,f1.ADDRESS2,f1.SUBURB,f1.STATE,f1.POSTCODE,
            f1.ITEM,f1.DESCRIPTION,f1.QTY
                 ,CASE   WHEN f1.FEETYPE like 'Stock' AND LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE THEN (Select f2.SELLEXCL From DEV_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND f2.FEETYPE = 'Pick Fee'  AND ROWNUM = 1 ) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
                        ELSE 0
                        END AS "Line Charge"
                ,CASE   WHEN f1.FEETYPE like 'Stock' AND LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE THEN (Select f2.SELLEXCL From DEV_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND f2.FEETYPE = 'Handeling Fee is ' ) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
                        ELSE 0
                        END AS "Order Despatch Charge"
                ,CASE   WHEN f1.FEETYPE like 'Stock' AND (LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE)  AND  ((ADDRESS  NOT LIKE '%Casselden%' Or ADDRESS   NOT LIKE '%2 Lonsdale%')
                          OR (ADDRESS2   NOT LIKE '%Casselden%' Or ADDRESS2   NOT LIKE '%2 Lonsdale%')) 
                        THEN (Select f2.SELLEXCL From DEV_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND (f2.FEETYPE like 'Freight Fee' OR f2.FEETYPE like 'Manual Freight Fee') AND ROWNUM = 1) --AND ((UPPER(ADDRESS) NOT LIKE '%CASSELDEN%' Or UPPER(ADDRESS) NOT LIKE '2 LONSDALE%') OR (UPPER(ADDRESS2) NOT LIKE '%CASSELDEN%' Or UPPER(ADDRESS2) NOT LIKE '2 LONSDALE%')) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
                        ELSE 0
                        END AS "Freight Charge",
          REPLACE(IM_XX_QTY_PER_PACK,'Box of ','') As "QTY",
          NULL 
          
          From DEV_ALL_FEES_F f1, IM
          Where f1.FEETYPE = 'Stock'
          AND f1.ITEM = IM_STOCK
          
          UNION ALL
           
          --Monday or the first day of the week
          Select NVL(TO_CHAR(TRUNC(CURRENT_DATE, 'DAY') -7),'') DespDate,NULL,NULL,NULL,
            NULL,NULL,NULL,NULL,NULL,NULL,
            NULL,
           CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,0,'DEV') > 0
          Then 'Daily Van Freight'
          ELSE NULL
          END AS  "Description",
          Case WHEN
          F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,0,'DEV') > 0 
          Then
          NVL(F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,0,'DEV'),'') 
          END AS "Qty"
         ,0,0,
          CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,0,'DEV') > 0 
          Then 30.71
          ELSE 0
          END AS  "Freight Cost",NULL,NULL
          From DEV_ALL_FEES_F f1
          Where f1.FEETYPE = 'Freight Fee' 
           AND ((ADDRESS  LIKE '%Casselden%' Or ADDRESS  LIKE '%2 Lonsdale%')
          OR (ADDRESS2  LIKE '%Casselden%' Or ADDRESS2  LIKE '%2 Lonsdale%'))
          --Group by TRUNC(CURRENT_DATE, 'DAY') -6
          AND f1.DESPDATE = TRUNC(CURRENT_DATE, 'DAY') -7
          And ROWNUM = 1
          
          UNION ALL
          
          --Tuesday or the first day of the week
          Select NVL(TO_CHAR(TRUNC(CURRENT_DATE, 'DAY') -6),'') DespDate,NULL,NULL,NULL,
            NULL,NULL,NULL,NULL,NULL,NULL,
            NULL,
           CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,1,'DEV') > 0
          Then 'Daily Van Freight'
          ELSE NULL
          END AS  "Description",
          Case WHEN
          F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,1,'DEV') > 0 
          Then
          NVL(F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,1,'DEV'),'') 
          END AS "Qty"
         ,0,0,
          CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,1,'DEV') > 0 
          Then 30.71
          ELSE 0
          END AS  "Freight Cost",NULL,NULL
          From DEV_ALL_FEES_F f1
          Where f1.FEETYPE = 'Freight Fee' 
           AND ((ADDRESS  LIKE '%Casselden%' Or ADDRESS  LIKE '%2 Lonsdale%')
          OR (ADDRESS2  LIKE '%Casselden%' Or ADDRESS2  LIKE '%2 Lonsdale%'))
          AND f1.DESPDATE = TRUNC(CURRENT_DATE, 'DAY') -6
          And ROWNUM = 1
          
          UNION ALL
          
          --Wednesday or the first day of the week
          Select NVL(TO_CHAR(TRUNC(CURRENT_DATE, 'DAY') -5),'') DespDate,NULL,NULL,NULL,
            NULL,NULL,NULL,NULL,NULL,NULL,
            NULL,
           CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,2,'DEV') > 0
          Then 'Daily Van Freight'
          ELSE NULL
          END AS  "Description",
          Case WHEN
          F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,2,'DEV') > 0 
          Then
          NVL(F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,2,'DEV'),'') 
          END AS "Qty"
         ,0,0,
          CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,2,'DEV') > 0 
          Then 30.71
          ELSE 0
          END AS  "Freight Cost",NULL,NULL
          From DEV_ALL_FEES_F f1
          Where f1.FEETYPE = 'Freight Fee' 
           AND ((ADDRESS  LIKE '%Casselden%' Or ADDRESS  LIKE '%2 Lonsdale%')
          OR (ADDRESS2  LIKE '%Casselden%' Or ADDRESS2  LIKE '%2 Lonsdale%'))
          AND f1.DESPDATE = TRUNC(CURRENT_DATE, 'DAY') -5
          And ROWNUM = 1
          
          UNION ALL
          
          --Thursday or the first day of the week
          Select NVL(TO_CHAR(TRUNC(CURRENT_DATE, 'DAY') -4),'') DespDate,NULL,NULL,NULL,
            NULL,NULL,NULL,NULL,NULL,NULL,
            NULL,
           CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,3,'DEV') > 0
          Then 'Daily Van Freight'
          ELSE NULL
          END AS  "Description",
          Case WHEN
          F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,3,'DEV') > 0 
          Then
          NVL(F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,3,'DEV'),'') 
          END AS "Qty"
         ,0,0,
          CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,3,'DEV') > 0 
          Then 30.71
          ELSE 0
          END AS  "Freight Cost",NULL,NULL
          From DEV_ALL_FEES_F f1
          Where f1.FEETYPE = 'Freight Fee' 
           AND ((ADDRESS  LIKE '%Casselden%' Or ADDRESS  LIKE '%2 Lonsdale%')
          OR (ADDRESS2  LIKE '%Casselden%' Or ADDRESS2  LIKE '%2 Lonsdale%'))
          AND f1.DESPDATE = TRUNC(CURRENT_DATE, 'DAY') -4
          And ROWNUM = 1
          
          UNION ALL
          
          --Friday or the first day of the week
          Select NVL(TO_CHAR(TRUNC(CURRENT_DATE, 'DAY') -3),'') DespDate,NULL,NULL,NULL,
            NULL,NULL,NULL,NULL,NULL,NULL,
            NULL,
           CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,4,'DEV') > 0
          Then 'Daily Van Freight'
          ELSE NULL
          END AS  "Description",
          Case WHEN
          F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,4,'DEV') > 0 
          Then
          NVL(F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,4,'DEV'),'') 
          END AS "Qty"
         ,0,0,
          CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,4,'DEV') > 0 
          Then 30.71
          ELSE 0
          END AS  "Freight Cost",NULL,NULL
          From DEV_ALL_FEES_F f1
          Where f1.FEETYPE = 'Freight Fee' 
           AND ((ADDRESS  LIKE '%Casselden%' Or ADDRESS  LIKE '%2 Lonsdale%')
          OR (ADDRESS2  LIKE '%Casselden%' Or ADDRESS2  LIKE '%2 Lonsdale%'))
          AND f1.DESPDATE = TRUNC(CURRENT_DATE, 'DAY') -3
          And ROWNUM = 1
          
          
         
          
          }'; 
        Else
          --run specific formatting query for superpartners
          l_query := q'{Select  to_date(f1.DESPDATE,'dd/mm/yyyy'),f1.ORDERNUM,f1.DESPNOTE,f1.CUSTOMER,
            f1.ATTENTIONTO,f1.ADDRESS,f1.ADDRESS2,f1.SUBURB,f1.STATE,f1.POSTCODE,
            f1.ITEM,f1.DESCRIPTION,f1.QTY
                 ,CASE   WHEN f1.FEETYPE like 'Stock' AND LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE THEN (Select f2.SELLEXCL From TMP_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND f2.FEETYPE = 'Pick Fee'  AND ROWNUM = 1 ) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
                        ELSE 0
                        END AS "Line Charge"
                ,CASE   WHEN f1.FEETYPE like 'Stock' AND LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE THEN (Select f2.SELLEXCL From TMP_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND f2.FEETYPE = 'Handeling Fee is ' ) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
                        ELSE 0
                        END AS "Order Despatch Charge"
                ,CASE   WHEN f1.FEETYPE like 'Stock' AND (LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE)  AND  ((ADDRESS  NOT LIKE '%Casselden%' Or ADDRESS   NOT LIKE '%2 Lonsdale%')
                          OR (ADDRESS2   NOT LIKE '%Casselden%' Or ADDRESS2   NOT LIKE '%2 Lonsdale%')) 
                        THEN (Select f2.SELLEXCL From TMP_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND (f2.FEETYPE like 'Freight Fee' OR f2.FEETYPE like 'Manual Freight Fee') AND ROWNUM = 1) --AND ((UPPER(ADDRESS) NOT LIKE '%CASSELDEN%' Or UPPER(ADDRESS) NOT LIKE '2 LONSDALE%') OR (UPPER(ADDRESS2) NOT LIKE '%CASSELDEN%' Or UPPER(ADDRESS2) NOT LIKE '2 LONSDALE%')) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
                        ELSE 0
                        END AS "Freight Charge",
          REPLACE(IM_XX_QTY_PER_PACK,'Box of ','') As "QTY",
          NULL 
          
          From DEV_ALL_FEES_F f1, IM
          Where f1.FEETYPE = 'Stock'
          AND f1.ITEM = IM_STOCK
          
          UNION ALL
         --Monday or the first day of the week
          Select TO_DATE(F_GET_FIRST_OF_PREV_WEEK(7),'dd/mm/yyyy'),NULL,NULL,NULL,
            NULL,NULL,NULL,NULL,NULL,NULL,
            NULL,
           CASE WHEN F_DAILY_FREIGHT_COUNT2(NULL,NULL,0,'DEV') > 0
          Then 'Daily Van Freight'
          ELSE NULL
          END AS  "Description",
          Case WHEN
          F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,0,'DEV') > 0 
          Then
          F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,0,'DEV') 
          END AS "Qty"
         ,0,0,
          CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,0,'DEV') > 0 
          Then 30.71
          ELSE 0
          END AS  "Freight Charge Cost",NULL,NULL
          From TMP_ALL_FEES_F f1
          Where f1.FEETYPE = 'Freight Fee' 
           AND ((ADDRESS  LIKE '%Casselden%' Or ADDRESS  LIKE '%2 Lonsdale%')
          OR (ADDRESS2  LIKE '%Casselden%' Or ADDRESS2  LIKE '%2 Lonsdale%'))
          --Group by TRUNC(CURRENT_DATE, 'DAY') -6
          AND f1.DESPDATE = F_GET_FIRST_OF_PREV_WEEK(7)
          And ROWNUM = 1
          GROUP BY f1.DESPDATE
          UNION ALL
          
          --Tuesday or the first day of the week to_date(CURRENT_DATE,'dd/mm/yyyy')
          Select to_date(F_GET_FIRST_OF_PREV_WEEK(6),'dd/mm/yyyy'),NULL,NULL,NULL,
            NULL,NULL,NULL,NULL,NULL,NULL,
            NULL,
           CASE WHEN F_DAILY_FREIGHT_COUNT2(NULL,NULL,1,'DEV') > 0
          Then 'Daily Van Freight'
          ELSE NULL
          END AS  "Description",
          Case WHEN
          F_DAILY_FREIGHT_COUNT2(NULL,NULL,1,'DEV') > 0 
          Then
          F_DAILY_FREIGHT_COUNT2(NULL,NULL,1,'DEV') 
          END AS "Qty"
         ,0,0,
          CASE WHEN F_DAILY_FREIGHT_COUNT2(NULL,NULL,1,'DEV') > 0 
          Then 30.71
          ELSE 0
          END AS  "Freight Charge Cost",NULL,NULL
          From TMP_ALL_FEES_F f1
          Where f1.FEETYPE = 'Freight Fee' 
           AND ((ADDRESS  LIKE '%Casselden%' Or ADDRESS  LIKE '%2 Lonsdale%')
          OR (ADDRESS2  LIKE '%Casselden%' Or ADDRESS2  LIKE '%2 Lonsdale%'))
          AND f1.DESPDATE = F_GET_FIRST_OF_PREV_WEEK(6)
          And ROWNUM = 1
          GROUP BY f1.DESPDATE
          UNION ALL
          
          --Wednesday or the first day of the week
          Select F_GET_FIRST_OF_PREV_WEEK(5),NULL,NULL,NULL,
            NULL,NULL,NULL,NULL,NULL,NULL,
            NULL,
           CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,2,'DEV') > 0
          Then 'Daily Van Freight'
          ELSE NULL
          END AS  "Description",
          Case WHEN
          F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,2,'DEV') > 0 
          Then
          F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,2,'DEV') 
          END AS "Qty"
         ,0,0,
          CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,2,'DEV') > 0 
          Then 30.71
          ELSE 0
          END AS  "Freight Charge Cost",NULL,NULL
          From TMP_ALL_FEES_F f1
          Where f1.FEETYPE = 'Freight Fee' 
           AND ((ADDRESS  LIKE '%Casselden%' Or ADDRESS  LIKE '%2 Lonsdale%')
          OR (ADDRESS2  LIKE '%Casselden%' Or ADDRESS2  LIKE '%2 Lonsdale%'))
          AND f1.DESPDATE = F_GET_FIRST_OF_PREV_WEEK(5)
          And ROWNUM = 1
          GROUP BY f1.DESPDATE
          UNION ALL
          
          --Thursday or the first day of the week
          Select F_GET_FIRST_OF_PREV_WEEK(4),NULL,NULL,NULL,
            NULL,NULL,NULL,NULL,NULL,NULL,
            NULL,
           CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,3,'DEV') > 0
          Then 'Daily Van Freight'
          ELSE NULL
          END AS  "Description",
          Case WHEN
          F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,3,'DEV') > 0 
          Then
          F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,3,'DEV') 
          END AS "Qty"
         ,0,0,
          CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,3,'DEV') > 0 
          Then 30.71
          ELSE 0
          END AS  "Freight Charge Cost",NULL,NULL
          From TMP_ALL_FEES_F f1
          Where f1.FEETYPE = 'Freight Fee' 
           AND ((ADDRESS  LIKE '%Casselden%' Or ADDRESS  LIKE '%2 Lonsdale%')
          OR (ADDRESS2  LIKE '%Casselden%' Or ADDRESS2  LIKE '%2 Lonsdale%'))
          AND f1.DESPDATE = F_GET_FIRST_OF_PREV_WEEK(4)
          And ROWNUM = 1
          GROUP BY f1.DESPDATE
          UNION ALL
          
          --Friday or the first day of the week
          Select F_GET_FIRST_OF_PREV_WEEK(3),NULL,NULL,NULL,
            NULL,NULL,NULL,NULL,NULL,NULL,
            NULL,
            
           CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,4,'DEV') > 0
          Then 'Daily Van Freight'
          ELSE NULL
          END AS  "Description",
          
          Case WHEN
          F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,4,'DEV') > 0 
          Then
          F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,4,'DEV') 
          END AS "Qty"
          
         ,0,0,
         
          CASE WHEN F_DAILY_FREIGHT_COUNT2(TRUNC(CURRENT_DATE, 'DAY') -6,TRUNC(CURRENT_DATE, 'DAY') -6,4,'DEV') > 0 
          Then 30.71
          ELSE 0
          END AS  "Freight Charge Cost",
          
          NULL,NULL
          From TMP_ALL_FEES_F f1
          Where f1.FEETYPE = 'Freight Fee' 
           AND ((ADDRESS  LIKE '%Casselden%' Or ADDRESS  LIKE '%2 Lonsdale%')
          OR (ADDRESS2  LIKE '%Casselden%' Or ADDRESS2  LIKE '%2 Lonsdale%'))
          AND f1.DESPDATE = F_GET_FIRST_OF_PREV_WEEK(3)
          And ROWNUM = 1
          GROUP BY f1.DESPDATE
          UNION ALL
          
          --Facilitate ctn/pallet charges - 3 lines
          Select F_GET_FIRST_OF_PREV_WEEK(7),NULL,NULL,NULL,
            NULL,NULL,NULL,NULL,NULL,NULL,
            NULL,
          'Destory Pallet Charge' AS  "Description",
          1 AS "Qty"
          ,0,0,
          38.80 AS  "Pallet Charge Cost",NULL,NULL
          From DUAL
          
          
           UNION ALL
          
          --Facilitate ctn/pallet charges - 3 lines
          Select F_GET_FIRST_OF_PREV_WEEK(7),NULL,NULL,NULL,
          NULL,NULL,NULL,NULL,NULL,NULL,
          NULL,
          'Extra Destory Pallet Charge' AS  "Description",
          1 AS "Qty"
          ,0,0,
          14.55 AS  "Extra Pallet Charge Cost",NULL,NULL
          From DUAL
          
          
           UNION ALL
          
          --Facilitate ctn/pallet charges - 3 lines
          Select F_GET_FIRST_OF_PREV_WEEK(7),NULL,NULL,NULL,
          NULL,NULL,NULL,NULL,NULL,NULL,
          NULL,
          'Destory Carton Charge' AS  "Description",
          1 AS "Qty"
          ,0,0,
          2.43 AS  "Carton Charge Cost",NULL,NULL
          From DUAL
          }'; 
        End If;
 --exclude addresses Casselden Place and/or Lonsdale Street - using SH_ADDRESS and SH_SUBURB --- run a seperate query to count despatches per day and apply a flat rate charge once only
--Also need to build query to work out cartons based on the following rates $2.43 per carton & 38.80 per pallet thereafetr 14.55 per pallet
--calc is 64 cartons per pallet eg 707 / 64 = 11.05 pallets
--          billed at 1 x pallet @ 38.80
--          10 x pallets @ 14.55
--   			  3 x Cartons @ 2.43         
       l_output := utl_file.fopen( 'EOM_ADMIN_ORDERS', filename, 'w' );
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
       
      v_query2 :=  SQL%ROWCOUNT;
    COMMIT;
  
    IF v_query2 > 0 THEN
        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
        If (sOp = 'PRJ' or sOp = 'DEV') Then
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'J_EOM_CUSTOMER_FEES_SUP','RM','DEV_CUSTOMER_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        Else
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'J_EOM_CUSTOMER_FEES_SUP','RM','TMP_CUSTOMER_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        End If;
        DBMS_OUTPUT.PUT_LINE('J_EOM_CUSTOMER_FEES_VHA for the date range '
        || startdate || ' -- ' || enddate || ' - ' || v_query2
        || ' records inserted into table TMP_CUSTOMER_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
        || ' Seconds...for customer ' || sCustomerCode );
      --Else
        --DBMS_OUTPUT.PUT_LINE('J_EOM_CUSTOMER_FEES_VHA rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
       -- ' Seconds...for customer ' || sCustomerCode);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('J_EOM_CUSTOMER_FEES_SUP failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
  
        RAISE;
  
    END J_EOM_CUSTOMER_FEES_SUP;
                  
      /*   J Run this once for AAS   */
    /*   This gets all the Customer Specific Charges   */
    /*   Temp Tables Used   */
    /*   1. TMP_CUSTOMER_FEES   */
    /*   Prism Rate Field Used   */
    /*   A. RM_XX_FEE32   
        Need to build into freight consolodation for daily flat rate deliveries
        as well to build into carton fees
    */
    PROCEDURE J_EOM_CUSTOMER_FEES_AAS (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
        ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
        ,sCustomerCode IN VARCHAR2
        ,p_filename in varchar2
        ,sOp IN VARCHAR2
      )
      IS
      TYPE ARRAY IS TABLE OF TMP_CUSTOMER_FEES%ROWTYPE;
      l_data ARRAY;
      v_out_tx          VARCHAR2(2000);
      l_query         VARCHAR2(25000);
      v_query           VARCHAR2(2000);
      v_query2          VARCHAR2(32767);
      nCheckpoint       NUMBER;
      sCourierm         VARCHAR2(20) := 'COURIERM';
      sCouriers         VARCHAR2(20) := 'COURIERS';
      sCourier         VARCHAR2(20) := 'COURIER%';
      sServ8             VARCHAR2(20) := 'SERV8';
      sServ3             VARCHAR2(20) := 'SERV%';
      l_output        utl_file.file_type;
      l_theCursor     integer default dbms_sql.open_cursor;
      l_columnValue   varchar2(4000);
      l_status        integer;
      l_colCnt        number := 0;
      l_separator     varchar2(1);
      l_descTbl       dbms_sql.desc_tab;
      v_time_taken VARCHAR2(205);
      sPath VARCHAR2(60) :=  'EOM_ADMIN_ORDERS';
      l_start number default dbms_utility.get_time;
      sFileSuffix VARCHAR2(60):= '.csv';
      sFileTime VARCHAR2(56)  := TO_CHAR(SYSDATE,'YYYYMMDD HH24MISS');
      filename VARCHAR2(260) := sCustomerCode || '-EOM-ADMIN-ORACLE-' || '-RunBy-' || sOp || '-RunOn-' || startdate || '-TO-' || enddate || '-RunAt-' || sFileTime || sFileSuffix;
      
      BEGIN
      
        nCheckpoint := 1;
        DBMS_OUTPUT.PUT_LINE('Checkpoint 1 J_EOM_CUSTOMER_FEES_AAS about to run startdate: ' || startdate ||
                            ' and enddate: ' || enddate || ' for:  ' || sCustomerCode);
--        v_query := 'TRUNCATE TABLE TMP_CUSTOMER_FEES';
--        EXECUTE IMMEDIATE v_query;
  
      nCheckpoint := 2;
      If (sOp = 'PRJ' or sOp = 'DEV') Then
          --run specific formatting query for superpartners
           l_query := q'{Select  f1.DESPDATE,f1.ORDERNUM,f1.DESPNOTE,f1.CUSTOMER,
            f1.ATTENTIONTO,f1.ADDRESS,f1.ADDRESS2,f1.SUBURB,f1.STATE,f1.POSTCODE,
            f1.ITEM,f1.DESCRIPTION,f1.QTY
                 ,CASE   WHEN f1.FEETYPE like 'Stock' AND LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE THEN (Select distinct f2.SELLEXCL From DEV_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND f2.FEETYPE = 'Pick Fee'  AND ROWNUM = 1 ) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
                        ELSE 0
                        END AS "Line Charge"
                ,CASE   WHEN f1.FEETYPE like 'Stock' AND LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE THEN (Select distinct f2.SELLEXCL From DEV_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND f2.FEETYPE = 'Handeling Fee is ' ) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
                        ELSE 0
                        END AS "Order Despatch Charge"
                ,CASE   WHEN f1.FEETYPE like 'Stock' AND (LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE) THEN (Select f2.SELLEXCL From DEV_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND (f2.FEETYPE like 'Freight Fee' OR f2.FEETYPE like 'Manual Freight Fee') AND ROWNUM = 1) --AND ((UPPER(ADDRESS) NOT LIKE '%CASSELDEN%' Or UPPER(ADDRESS) NOT LIKE '2 LONSDALE%') OR (UPPER(ADDRESS2) NOT LIKE '%CASSELDEN%' Or UPPER(ADDRESS2) NOT LIKE '2 LONSDALE%')) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
                        ELSE 0
                        END AS "Freight Charge",
          REPLACE(IM_XX_QTY_PER_PACK,'Box of ','') As "QTY",
          NULL 
          
          From DEV_ALL_FEES_F f1, IM
          Where f1.FEETYPE = 'Stock'
          AND f1.ITEM = IM_STOCK
          
          
          UNION ALL
         
          
          
       Select  f1.DESPDATE,f1.ORDERNUM,f1.DESPNOTE,f1.CUSTOMER,
            f1.ATTENTIONTO,f1.ADDRESS,f1.ADDRESS2,f1.SUBURB,f1.STATE,f1.POSTCODE,
            f1.ITEM,f1.DESCRIPTION,f1.QTY
                 ,CASE   WHEN f1.FEETYPE like 'Pallet In Fee' --AND LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE  THEN f1.SELLEXCL --(Select f2.SELLEXCL From DEV_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND f2.FEETYPE = 'Pallet In Fee' ) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
                        ELSE 0
                        END AS "Pallet In Charge"
                ,CASE   WHEN f1.FEETYPE like 'SLOWFEEPALLETS' --AND LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE  THEN f1.SELLEXCL --(Select f2.SELLEXCL From DEV_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND f2.FEETYPE = 'SLOWFEEPALLETS' ) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
                        ELSE 0
                        END AS "SLOWFEEPALLETS Charge"
                ,CASE   WHEN f1.FEETYPE like 'FEEPALLETS' --AND (LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE)  THEN f1.SELLEXCL --(Select f2.SELLEXCL From DEV_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND (f2.FEETYPE like 'FEEPALLETS') ) --AND ((UPPER(ADDRESS) NOT LIKE '%CASSELDEN%' Or UPPER(ADDRESS) NOT LIKE '2 LONSDALE%') OR (UPPER(ADDRESS2) NOT LIKE '%CASSELDEN%' Or UPPER(ADDRESS2) NOT LIKE '2 LONSDALE%')) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
                        WHEN f1.FEETYPE like 'FEESHELFS' 
                         THEN f1.SELLEXCL
                        ELSE 0
                        END AS "STORAGE Charge",
          REPLACE(IM_XX_QTY_PER_PACK,'Box of ','') As "QTY",
          NULL 
          
          From DEV_ALL_FEES_F f1, IM
          Where f1.FEETYPE IN  ('FEESHELFS','FEEPALLETS','SLOWFEEPALLETS','Pallet In Fee')
          AND f1.ITEM = IM_STOCK
          
          
          }'; 
        Else
          --run specific formatting query for superpartners
          l_query := q'{Select  f1.DESPDATE,f1.ORDERNUM,f1.DESPNOTE,f1.CUSTOMER,
            f1.ATTENTIONTO,f1.ADDRESS,f1.ADDRESS2,f1.SUBURB,f1.STATE,f1.POSTCODE,
            f1.ITEM,f1.DESCRIPTION,f1.QTY
                 ,CASE   WHEN f1.FEETYPE like 'Stock' AND LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE THEN (Select distinct f2.SELLEXCL From TMP_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND f2.FEETYPE = 'Pick Fee'  AND ROWNUM = 1 ) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
                        ELSE 0
                        END AS "Line Charge"
                ,CASE   WHEN f1.FEETYPE like 'Stock' AND LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE THEN (Select distinct f2.SELLEXCL From TMP_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND f2.FEETYPE = 'Handeling Fee is ' ) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
                        ELSE 0
                        END AS "Order Despatch Charge"
                ,CASE   WHEN f1.FEETYPE like 'Stock' AND (LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE) THEN (Select f2.SELLEXCL From TMP_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND (f2.FEETYPE like 'Freight Fee' OR f2.FEETYPE like 'Manual Freight Fee') AND ROWNUM = 1) --AND ((UPPER(ADDRESS) NOT LIKE '%CASSELDEN%' Or UPPER(ADDRESS) NOT LIKE '2 LONSDALE%') OR (UPPER(ADDRESS2) NOT LIKE '%CASSELDEN%' Or UPPER(ADDRESS2) NOT LIKE '2 LONSDALE%')) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
                        ELSE 0
                        END AS "Freight Charge",
          REPLACE(IM_XX_QTY_PER_PACK,'Box of ','') As "QTY",
          NULL 
          
          From TMP_ALL_FEES_F f1, IM
          Where f1.FEETYPE = 'Stock'
          AND f1.ITEM = IM_STOCK
          
          
          
          UNION ALL 
          
          
       Select  f1.DESPDATE,f1.ORDERNUM,f1.DESPNOTE,f1.CUSTOMER,
            f1.ATTENTIONTO,f1.ADDRESS,f1.ADDRESS2,f1.SUBURB,f1.STATE,f1.POSTCODE,
            f1.ITEM,f1.DESCRIPTION,f1.QTY
                 ,CASE   WHEN f1.FEETYPE like 'Pallet In Fee' --AND LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE 
                        THEN f1.SELLEXCL --(Select f2.SELLEXCL From DEV_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND f2.FEETYPE = 'Pallet In Fee' ) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
                        ELSE 0
                        END AS "Pallet In Charge"
                ,CASE   WHEN f1.FEETYPE like 'SLOWFEEPALLETS' --AND LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE 
                        THEN f1.SELLEXCL --(Select f2.SELLEXCL From DEV_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND f2.FEETYPE = 'SLOWFEEPALLETS' ) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
                        ELSE 0
                        END AS "SLOWFEEPALLETS Charge"
                ,CASE   WHEN f1.FEETYPE like 'FEEPALLETS' --AND (LAG(f1.DESPNOTE, 1, 0) OVER (ORDER BY f1.DESPNOTE) != f1.DESPNOTE)  --AND  ((ADDRESS  NOT LIKE '%Casselden%' Or ADDRESS   NOT LIKE '%2 Lonsdale%')
                          --OR (ADDRESS2   NOT LIKE '%Casselden%' Or ADDRESS2   NOT LIKE '%2 Lonsdale%')) 
                        THEN f1.SELLEXCL --(Select f2.SELLEXCL From DEV_ALL_FEES_F f2 Where f2.ORDERNUM = f1.ORDERNUM AND (f2.FEETYPE like 'FEEPALLETS') ) --AND ((UPPER(ADDRESS) NOT LIKE '%CASSELDEN%' Or UPPER(ADDRESS) NOT LIKE '2 LONSDALE%') OR (UPPER(ADDRESS2) NOT LIKE '%CASSELDEN%' Or UPPER(ADDRESS2) NOT LIKE '2 LONSDALE%')) --As "Line Charge"-- AND LAG(FEETYPE, 1, 0) OVER (ORDER BY FEETYPE) = 'Pick Fee'  THEN LEAD(SELLEXCL, 2, 0) OVER (ORDER BY SELLEXCL)
                        WHEN f1.FEETYPE like 'FEESHELFS' 
                         THEN f1.SELLEXCL
                        ELSE 0
                        END AS "STORAGE Charge",
          REPLACE(IM_XX_QTY_PER_PACK,'Box of ','') As "QTY",
          NULL 
          
          From TMP_ALL_FEES_F f1, IM
          Where f1.FEETYPE IN  ('FEESHELFS','FEEPALLETS','SLOWFEEPALLETS','Pallet In Fee')
          AND f1.ITEM = IM_STOCK
          
          }'; 
        End If;
 --exclude addresses Casselden Place and/or Lonsdale Street - using SH_ADDRESS and SH_SUBURB --- run a seperate query to count despatches per day and apply a flat rate charge once only
--Also need to build query to work out cartons based on the following rates $2.43 per carton null80 per pallet thereafetr 14.55 per pallet
--calc is 64 cartons per pallet eg 707 / 64 = 11.05 pallets
--          billed at 1 x pallet @ 38.80
--          10 x pallets @ 14.55
--   			  3 x Cartons @ 2.43         
       l_output := utl_file.fopen( 'EOM_ADMIN_ORDERS', filename, 'w' );
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
       
      v_query2 :=  SQL%ROWCOUNT;
    COMMIT;
  
    IF v_query2 > 0 THEN
        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
        If (sOp = 'PRJ' or sOp = 'DEV') Then
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'J_EOM_CUSTOMER_FEES_AAS','RM','DEV_CUSTOMER_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        Else
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'J_EOM_CUSTOMER_FEES_AAS','RM','TMP_CUSTOMER_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        End If;
        --DBMS_OUTPUT.PUT_LINE('J_EOM_CUSTOMER_FEES_VHA for the date range '
       -- || startdate || ' -- ' || enddate || ' - ' || v_query2
       -- || ' records inserted into table TMP_CUSTOMER_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
       -- || ' Seconds...for customer ' || sCustomerCode );
      --Else
        --DBMS_OUTPUT.PUT_LINE('J_EOM_CUSTOMER_FEES_VHA rates are not empty - but there was no data, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
       -- ' Seconds...for customer ' || sCustomerCode);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('J_EOM_CUSTOMER_FEES_AAS failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
  
        RAISE;
  
    END J_EOM_CUSTOMER_FEES_AAS;
                  
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
        ,sFilterBy IN VARCHAR2
        ,sOp IN VARCHAR2
      )
      IS
      TYPE ARRAY IS TABLE OF TMP_PAL_DESP_FEES%ROWTYPE;
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
     CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE17,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * t.ST_XX_NUM_PALLETS) * 1.1-- (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = sCustomerCode)  * 1.1
         ELSE NULL
         END                                           AS "DIncl",
     CASE   WHEN t.ST_XX_NUM_PALLETS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE17,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) -- (Select To_Number(RM_XX_FEE17) from RM where RM_CUST = sCustomerCode)
         ELSE NULL
         END                                           AS "ReportingPrice",
         NULL,
         NULL,
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
      
      --nCheckpoint := 11;
       
        
      IF To_Number(regexp_substr(sCust_Rates,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) != 0 Then
      
        ----DBMS_OUTPUT.PUT_LINE('K1_PAL_DESP_FEES rates are $' || sCust_Rates || '. Prism rate field is RM_XX_FEE17');
       
      nCheckpoint := 2;
      If (sOp = 'PRJ' or sOp = 'DEV') Then
          v_query := 'TRUNCATE TABLE DEV_PAL_DESP_FEES';
        EXECUTE IMMEDIATE v_query;
          OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO DEV_PAL_DESP_FEES VALUES l_data(i);
          --USING sCust;
  
          EXIT WHEN c%NOTFOUND;
  
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
        Else
          v_query := 'TRUNCATE TABLE TMP_PAL_DESP_FEES';
          EXECUTE IMMEDIATE v_query;
           OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO TMP_PAL_DESP_FEES VALUES l_data(i);
          --USING sCust;
  
          EXIT WHEN c%NOTFOUND;
  
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
        End If;
        -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
        --  --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        --END LOOP;
  
      v_query2 :=  SQL%ROWCOUNT;
    COMMIT;
        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
        If (sOp = 'PRJ' or sOp = 'DEV') Then
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'K1_PAL_DESP_FEES','ST','DEV_PAL_DESP_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        Else
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'K1_PAL_DESP_FEES','ST','TMP_PAL_DESP_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        End If;
        --DBMS_OUTPUT.PUT_LINE('K1_PAL_DESP_FEES for the date range '
          --|| startdate || ' -- ' || enddate || ' - ' || v_query2
         -- || ' records inserted into table TMP_PAL_CTN_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
         -- || ' Seconds...for customer ' || sCustomerCode );
       --Else
        --DBMS_OUTPUT.PUT_LINE('K1_PAL_DESP_FEES rates are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
       -- ' Seconds...for customer ' || sCustomerCode);
      END IF;
  
      --COMMIT;
    EXCEPTION
          WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('K1_PAL_DESP_FEES failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
       WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('K1_PAL_DESP_FEES Failed at checkpoint ' || nCheckpoint ||
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
        ,sFilterBy IN VARCHAR2
        ,sOp IN VARCHAR2
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
       CASE    WHEN NE_ENTRY IS NOT NULL THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE13,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * 1 )* 1.1 --  (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = sCustomerCode) * 1.1
          ELSE NULL
          END                      AS "DIncl",
       CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE13,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) -- (Select To_Number(RM_XX_FEE13) from RM where RM_CUST = sCustomerCode)
          ELSE NULL
          END                                           AS "ReportingPrice",
          NULL,NULL,
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
      
       --nCheckpoint := 11;
       
        
      IF To_Number(regexp_substr(sCust_Rates,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) != 0 Then
       
      ----DBMS_OUTPUT.PUT_LINE('K2_CTN_IN_FEES rates are $' || sCust_Rates || '. Prism rate field is RM_XX_FEE13');
        
      nCheckpoint := 2;
      If (sOp = 'PRJ' or sOp = 'DEV') Then
           v_query := 'TRUNCATE TABLE DEV_CTN_IN_FEES';
          EXECUTE IMMEDIATE v_query;
          OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO DEV_CTN_IN_FEES VALUES l_data(i);
          --USING sCust;
  
          EXIT WHEN c%NOTFOUND;
  
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
      Else
           v_query := 'TRUNCATE TABLE TMP_CTN_IN_FEES';
        EXECUTE IMMEDIATE v_query;
           OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO TMP_CTN_IN_FEES VALUES l_data(i);
          --USING sCust;
  
          EXIT WHEN c%NOTFOUND;
  
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
      End If;
        -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
        --  --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        --END LOOP;
  
      v_query2 :=  SQL%ROWCOUNT;
    COMMIT;
        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
        If (sOp = 'PRJ' or sOp = 'DEV') Then
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'K2_CTN_IN_FEES','ST','DEV_CTN_IN_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        Else
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'K2_CTN_IN_FEES','ST','TMP_CTN_IN_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        End IF;
        --DBMS_OUTPUT.PUT_LINE('K2_CTN_IN_FEES for the date range '
         -- || startdate || ' -- ' || enddate || ' - ' || v_query2
         -- || ' records inserted into table TMP_CTN_IN_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
         -- || ' Seconds...for customer ' || sCustomerCode );
       --Else
        --DBMS_OUTPUT.PUT_LINE('K2_CTN_IN_FEES rates are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
       -- ' Seconds...for customer ' || sCustomerCode);
      END IF;
    EXCEPTION
         WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('K2_CTN_IN_FEES failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
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
        ,sFilterBy IN VARCHAR2
        ,sOp IN VARCHAR2
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
    SELECT  DISTINCT  IM_CUST                AS "Customer",
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
          REPLACE(IM_DESC, ',')                 AS "Description",
          NE_QUANTITY          AS "Qty",
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
       CASE    WHEN NE_ENTRY IS NOT NULL THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) * 1 )* 1.1 --  (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust) * 1.1
          ELSE NULL
          END                      AS "DIncl",
       CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) -- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
          ELSE NULL
          END                                           AS "ReportingPrice",
          NULL,NULL,
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
          INNER JOIN PWIN175.NE  ON NE_ACCOUNT  = NA_ACCOUNT AND NA_EXT_TYPE = '1210067'
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
      
      --nCheckpoint := 11;
       
        
      IF To_Number(regexp_substr(sCust_Rates,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) != 0 
        AND sCustomerCode != 'BEYONDBL' OR sCustomerCode != 'TABCORP' Then
      
       -- --DBMS_OUTPUT.PUT_LINE('K3_PAL_IN_FEES rates are $' || sCust_Rates || '. Prism rate field is RM_XX_FEE14.');
        
      nCheckpoint := 2;
       If (sOp = 'PRJ' or sOp = 'DEV') Then
           v_query := 'TRUNCATE TABLE DEV_PAL_IN_FEES';
        EXECUTE IMMEDIATE v_query;
          OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO DEV_PAL_IN_FEES VALUES l_data(i);
          --USING sCust;
  
          EXIT WHEN c%NOTFOUND;
  
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
        Else
           v_query := 'TRUNCATE TABLE TMP_PAL_IN_FEES';
        EXECUTE IMMEDIATE v_query;
             OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO TMP_PAL_IN_FEES VALUES l_data(i);
          --USING sCust;
  
          EXIT WHEN c%NOTFOUND;
  
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
      End If;
        -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
        --  --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        --END LOOP;
  
      v_query2 :=  SQL%ROWCOUNT;
    COMMIT;
        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
        If (sOp = 'PRJ' or sOp = 'DEV') Then
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'K3_PAL_IN_FEES','ST','DEV_PAL_IN_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        Else
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'K3_PAL_IN_FEES','ST','TMP_PAL_IN_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        End IF;
        --DBMS_OUTPUT.PUT_LINE('K3_PAL_IN_FEES for the date range '
         -- || startdate || ' -- ' || enddate || ' - ' || v_query2
         -- || ' records inserted into table TMP_PAL_IN_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
         -- || ' Seconds...for customer ' || sCustomerCode );
       --Else
        --DBMS_OUTPUT.PUT_LINE('K3_PAL_IN_FEES rates are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
       -- ' Seconds...for customer ' || sCustomerCode);
      END IF;
  
    EXCEPTION
         WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('K3_PAL_IN_FEES failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
       WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('K3_PAL_IN_FEES Failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
        RAISE;
  
    END K3_PAL_IN_FEES;
  
    /*   K3_PAL_IN_FEES Run this once for each customer   */
    /*   This gets all the Pallet In Charges   */
    /*   Temp Tables Used   */
    /*   1. TMP_PAL_IN_FEES   */
    /*   Prism Rate Field Used   */
    /*   A. RM_XX_FEE14   */
    PROCEDURE K3_ALL_PAL_IN_FEES (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
        ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
        ,sCustomerCode IN VARCHAR2,
        sAnalysis IN RM.RM_ANAL%TYPE
        ,sFilterBy IN VARCHAR2
        ,sOp IN VARCHAR2
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
    SELECT  DISTINCT  IM_CUST                AS "Customer",
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
          REPLACE(IM_DESC, ',')                 AS "Description",
          NE_QUANTITY          AS "Qty",
          IM_LEVEL_UNIT          AS "UOI",
      CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(r.RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM r where r.RM_CUST = RM_PARENT) -- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
          ELSE NULL
          END                      AS "UnitPrice",
       CASE    WHEN NE_ENTRY IS NOT NULL THEN  (SELECT To_Number(regexp_substr(r.RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM r where r.RM_CUST = RM_PARENT) -- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
          ELSE NULL
          END                      AS "OWUnitPrice",
       CASE    WHEN NE_ENTRY IS NOT NULL THEN  (SELECT To_Number(regexp_substr(r.RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM r where r.RM_CUST = RM_PARENT) * 1-- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
          ELSE NULL
          END                      AS "DExcl",
       CASE    WHEN NE_ENTRY IS NOT NULL THEN ((SELECT To_Number(regexp_substr(r.RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM r where r.RM_CUST = RM_PARENT) * 1 )* 1.1 --  (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust) * 1.1
          ELSE NULL
          END                      AS "DIncl",
       CASE    WHEN NE_ENTRY IS NOT NULL THEN (SELECT To_Number(regexp_substr(r.RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM r where r.RM_CUST = RM_PARENT) -- (Select To_Number(RM_XX_FEE14) from RM where RM_CUST = :cust)
          ELSE NULL
          END                                           AS "ReportingPrice",
          NULL,NULL,
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
          INNER JOIN PWIN175.NE  ON NE_ACCOUNT  = NA_ACCOUNT AND NA_EXT_TYPE = '1210067'
          INNER JOIN PWIN175.NI  ON NI_ENTRY = NE_ENTRY
          INNER JOIN PWIN175.RM  ON RM_CUST  = IM_CUST
    WHERE  (SELECT To_Number(regexp_substr(r.RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM r where r.RM_CUST = RM_PARENT) > 0
    --AND     IM_CUST = sCustomerCode
    AND       NA_EXT_TYPE = 1210067
    AND       NE_TRAN_TYPE = 1
    AND     NE_NV_EXT_TYPE = 3010144
  --	AND       IM_MAIN_SUPP <> 'BSPGA'
    AND       (NE_STATUS = 1 OR NE_STATUS = 3)
    --AND       TO_CHAR(NE_DATE,'YYYY-MM-DD') >= start_date AND TO_CHAR(NE_DATE,'YYYY-MM-DD') <= end_date
    AND       Upper(IL_NOTE_2) = 'YES' AND IL_PHYSICAL = 1
    AND       NE_DATE >= startdate AND NE_DATE <= enddate ;
      QueryTable VARCHAR2(600) := q'{SELECT To_Number(regexp_substr(r.RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM r where r.RM_CUST = RM_PARENT}';
      sCust_Rates RM.RM_XX_FEE14%TYPE;
    BEGIN
      nCheckpoint := 10;
      EXECUTE IMMEDIATE QueryTable INTO sCust_Rates;-- USING RM_CUST;
      
      --nCheckpoint := 11;
        
        
      IF To_Number(regexp_substr(sCust_Rates,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) != 0 
        AND sCustomerCode != 'BEYONDBL' OR sCustomerCode != 'TABCORP' Then
      
       -- --DBMS_OUTPUT.PUT_LINE('K3_PAL_IN_FEES rates are $' || sCust_Rates || '. Prism rate field is RM_XX_FEE14.');
        
      nCheckpoint := 2;
      If (sOp = 'PRJ' or sOp = 'DEV') Then
          v_query := 'TRUNCATE TABLE DEV_PAL_IN_FEES';
        EXECUTE IMMEDIATE v_query;
          OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO DEV_PAL_IN_FEES VALUES l_data(i);
          --USING sCust;
  
          EXIT WHEN c%NOTFOUND;
  
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
      Else
        v_query := 'TRUNCATE TABLE TMP_PAL_IN_FEES';
        EXECUTE IMMEDIATE v_query;
         OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO TMP_PAL_IN_FEES VALUES l_data(i);
          --USING sCust;
  
          EXIT WHEN c%NOTFOUND;
  
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
      End If;
        -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
        --  --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        --END LOOP;
  
      v_query2 :=  SQL%ROWCOUNT;
    COMMIT;
        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
        If (sOp = 'PRJ' or sOp = 'DEV') Then
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'K3_ALL_PAL_IN_FEES','ST','DEV_PAL_IN_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        Else
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'K3_ALL_PAL_IN_FEES','ST','TMP_PAL_IN_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
        End IF;
        --DBMS_OUTPUT.PUT_LINE('K3_PAL_IN_FEES for the date range '
         -- || startdate || ' -- ' || enddate || ' - ' || v_query2
         -- || ' records inserted into table TMP_PAL_IN_FEES in ' || round((dbms_utility.get_time-l_start)/100, 6)
         -- || ' Seconds...for customer ' || sCustomerCode );
       --Else
        --DBMS_OUTPUT.PUT_LINE('K3_PAL_IN_FEES rates are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
       -- ' Seconds...for customer ' || sCustomerCode);
      END IF;
  
    EXCEPTION
         WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('K3_ALL_PAL_IN_FEES failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
       WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('K3_ALL_PAL_IN_FEES Failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
        RAISE;
  
    END K3_ALL_PAL_IN_FEES;
  
  
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
        ,sFilterBy IN VARCHAR2
        ,sOp IN VARCHAR2
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
     CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN ((SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode)* t.ST_XX_NUM_CARTONS) * 1.1 --f_get_fee('RM_XX_FEE15',sCust) --To_Number(f_get_fee('RM_XX_FEE15',sCust))
      ELSE NULL
         END                                           AS "DIncl",
     CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCustomerCode) --f_get_fee('RM_XX_FEE15',sCust) --To_Number(f_get_fee('RM_XX_FEE15',sCust))
          ELSE null
         END                                           AS "ReportingPrice",
         NULL,NULL,
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
      
      --nCheckpoint := 11;
        
        
      IF To_Number(regexp_substr(sCust_Rates,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) != 0 THEN
     -- --DBMS_OUTPUT.PUT_LINE('K4_CTN_DESP_FEES Rates are ' || sCust_Rates || '. Prism rate field is RM_XX_FEE15');
  
  
        
  
      nCheckpoint := 2;
      If (sOp = 'PRJ' or sOp = 'DEV') Then
          v_query := 'TRUNCATE TABLE DEV_CTN_DESP_FEES';
        EXECUTE IMMEDIATE v_query;
          OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO DEV_CTN_DESP_FEES VALUES l_data(i);
          --USING sCust;
  
          EXIT WHEN c%NOTFOUND;
  
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
      Else
          v_query := 'TRUNCATE TABLE TMP_CTN_DESP_FEES';
        EXECUTE IMMEDIATE v_query;
           OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO TMP_CTN_DESP_FEES VALUES l_data(i);
          --USING sCust;
  
          EXIT WHEN c%NOTFOUND;
  
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
      End If;
        -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        --END LOOP;
  
    COMMIT;
    v_query2 :=  SQL%ROWCOUNT;
  
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
      If (sOp = 'PRJ' or sOp = 'DEV') Then
        EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'K4_CTN_DESP_FEES','ST','DEV_CTN_DESP_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
      Else
        EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,startdate,enddate,'K4_CTN_DESP_FEES','ST','TMP_CTN_DESP_FEES',v_time_taken,SYSTIMESTAMP,sCustomerCode);
      End IF;
      --DBMS_OUTPUT.PUT_LINE('K4_CTN_DESP_FEES for the date range '
     -- || startdate || ' -- ' || enddate || ' - ' || v_query2
     -- || ' records inserted into table TMP_CTN_DESP_FEES in ' || (round((dbms_utility.get_time-l_start)/100, 6)
     -- || ' Seconds...for customer ' || sCustomerCode ));
    --Else
        --DBMS_OUTPUT.PUT_LINE('K4_CTN_DESP_FEES rates are empty - skipped procedure to save time, still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
       -- ' Seconds...for customer ' || sCustomerCode);
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('K4_CTN_DESP_FEES failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
       WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('K4_CTN_DESP_FEES Failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
        RAISE;
  
    END K4_CTN_DESP_FEES;
    
    PROCEDURE L_DESPATCH_REPORT (
          p_array_size IN PLS_INTEGER DEFAULT 100,
          sCustomerCode IN VARCHAR2 DEFAULT '',
          gds_analysis IN  RM.RM_ANAL%TYPE  DEFAULT '',
          gds_start_date_in IN VARCHAR2,
          gds_end_date_in IN VARCHAR2
          ,sOp IN VARCHAR2
    )
    AS
      TYPE ARRAY IS TABLE OF TMP_DESP_REPT%ROWTYPE;
      l_data ARRAY;
      v_time_taken VARCHAR2(205);
      v_out_tx          VARCHAR2(2000);
      SQLQuery   VARCHAR2(6000);
      v_query           VARCHAR2(2000);
      v_query2          VARCHAR2(32767);
      nCheckpoint       NUMBER;
      gds_cust_not_in VARCHAR2(50) := 'TABCORP';
      nbreakpoint   NUMBER;
      sFileName VARCHAR2(560);
      sFileTime VARCHAR2(56)  := TO_CHAR(SYSDATE,'YYYYMMDD HH24MISS');
      date_diff_middle NUMBER := 0;
      days_as_number NUMBER := 0;
      date_diff_next NUMBER := 0;
      gds_next_start_date_in VARCHAR2(56);
      gds_next_end_date_in VARCHAR2(56);
      gds_new_end_date_in VARCHAR2(56);
      l_start number default dbms_utility.get_time;
      
      
       CURSOR cDEVAnal
      IS
      SELECT    substr(To_Char(ST.ST_DESP_DATE),0,10) AS "DespatchDate"
                ,substr(To_Char(SH.SH_ADD_DATE),0,10) AS "OrderDate"
                ,Dev_Group_Cust.sGroupCust   AS "Parent"
                ,SH.SH_CUST AS "Cust"
               ,RM.RM_NAME AS "CustName"
               ,SD.SD_XX_PICKLIST_NUM     AS "PickSlip"
               ,ST.ST_PSLIP               AS "DespatchNote"
               ,SH.SH_ORDER            AS "Order#"
               ,SH.SH_SPARE_STR_5         AS "OrderwareNum"
               ,SH.SH_CUST_REF                AS "Cust Ref"
               ,SD.SD_STOCK               AS "Stock"
               ,SD.SD_DESC                AS "Description"
               ,SD.SD_QTY_ORDER           AS "Qty Ordered"
               ,SD.SD_QTY_UNIT            AS "UOI"
               ,SL.SL_PSLIP_QTY           AS "Qty Despatched"
               ,ST.ST_WEIGHT AS "Weight"
               ,ST.ST_PACKAGES AS "Packages"
               ,IM.IM_REPORTING_PRICE          AS "Price(IM)"
               ,IM.IM_SCALE_LCL                       AS "LCL Scale"
               ,SD.SD_SELL_PRICE         AS "SD_SELL_PRICE"
               ,'FIFO'         AS "FIFO Unit Price"
               ,NI.NI_SELL_VALUE AS "BatchUnitSellPrice"
               ,SD.SD_EXCL AS "Ext GST Sell"
               ,SD.SD_TAX AS "GST"
               ,SD.SD_INCL AS "Incl GST"
               ,SH.SH_ADDRESS             AS "Address"
               ,SH.SH_SUBURB              AS "Address2"
               ,SH.SH_CITY                AS "Suburb"
               ,SH.SH_STATE               AS "State"
               ,SH.SH_POST_CODE           AS "Postcode"
               ,SH.SH_NOTE_2              AS "AttentionTo"
               ,SH.SH_NOTE_1              AS "DeliverTo"
               ,SH.SH_SPARE_STR_4             AS "CostCenter"
               ,NULL            AS "RD_SPARE_STR_1"
               ,SH.SH_SPARE_STR_6         AS "Ordered By"
               ,IM.IM_OWNED_BY AS "OwnedBy"
               ,IM.IM_FINISH AS "Finish"
               ,SD.SD_LINE AS "OWLineNum"
               ,IM.IM_BRAND AS "Finish"
               ,ST.ST_SPARE_INT_1 AS "SentFrom"
               ,NULL
               ,NULL
               ,NULL
               ,NULL
               ,NULL,
               NULL,NULL,NULL,NULL
      FROM  PWIN175.SD
            RIGHT JOIN PWIN175.SH  ON SH.SH_ORDER  = SD.SD_ORDER
            LEFT JOIN PWIN175.ST  ON ST.ST_PICK  = SD.SD_LAST_PICK_NUM
            LEFT JOIN PWIN175.SL   ON SL.SL_PICK   = ST.ST_PICK
            INNER JOIN PWIN175.RM  ON RM.RM_CUST  = SH.SH_CUST
            --INNER JOIN PWIN175.RD  ON RD.RD_CODE  = SH.SH_DEL_CODE
            INNER JOIN Dev_Group_Cust ON Dev_Group_Cust.sCust = SH.SH_CUST
            INNER JOIN PWIN175.IM  ON IM.IM_STOCK = SD.SD_STOCK
            INNER JOIN PWIN175.NI  ON NI.NI_NV_EXT_KEY = SL.SL_UID
      WHERE NI.NI_STRENGTH = 3 AND NI.NI_DATE = ST.ST_DESP_DATE AND NI.NI_STOCK = SD_STOCK AND NI.NI_STATUS <> 0
      AND     SH.SH_STATUS <> 3
      --AND     sGroupCust IN (gds_cust_in)
      AND       SH.SH_ORDER = ST.ST_ORDER
      --AND  SD.SD_STOCK = gds_stock_in
      AND       ST.ST_DESP_DATE >= gds_start_date_in AND ST.ST_DESP_DATE <= gds_new_end_date_in
      AND       RM_ANAL = gds_analysis
      --AND       ST.ST_DESP_DATE >= '10-APR-2014' AND ST.ST_DESP_DATE <= '15-APR-2014'
      AND       SD.SD_LAST_PICK_NUM = ST.ST_PICK
      GROUP BY  SH.SH_CUST,SH.SH_ORDER,SH.SH_ADD_DATE,SH.SH_ADDRESS,SH.SH_SUBURB,SH.SH_CITY,SH.SH_STATE,SH.SH_POST_CODE,SH.SH_NOTE_1,SH.SH_NOTE_2,SH.SH_CAMPAIGN, SH.SH_SPARE_STR_4,SH.SH_SPARE_DBL_9,SH.SH_CUST_REF,SH.SH_SPARE_STR_5,
                ST.ST_ADD_DATE,ST.ST_ADD_OP,ST.ST_PICK_PRINT_DATE,ST.ST_DESP_DATE,ST.ST_WEIGHT,ST.ST_PACKAGES,ST.ST_PSLIP,ST.ST_PICK,
                SD.SD_DESC,SD.SD_STOCK,SD.SD_XX_OW_UNIT_PRICE,SD.SD_SELL_PRICE,SD.SD_LINE,SD.SD_EXCL,SD.SD_INCL,SD.SD_QTY_ORDER,SD.SD_QTY_UNIT,SD.SD_XX_PICKLIST_NUM,
                IM.IM_BRAND,IM.IM_OWNED_BY,IM.IM_CUST,IM.IM_XX_COST_CENTRE01,IM.IM_REPORTING_PRICE,   ST.ST_SPARE_INT_1,
                NI.NI_SELL_VALUE,NI.NI_NX_QUANTITY,ST.ST_SPARE_DBL_1,  SD.SD_TAX, SH.SH_SPARE_STR_6,
                --RM.RM_GROUP_CUST,RM.RM_PARENT,
                Dev_Group_Cust.sGroupCust,RM.RM_NAME,IM.IM_SCALE_LCL,  IM.IM_FINISH,
                SL.SL_PSLIP_QTY,SD.SD_SPARE_STR_4;
                
                
       CURSOR cDEV
      IS
     SELECT    substr(To_Char(ST.ST_DESP_DATE),0,10) AS "DespatchDate"
                ,substr(To_Char(SH.SH_ADD_DATE),0,10) AS "OrderDate"
                ,Dev_Group_Cust.sGroupCust   AS "Parent"
                ,SH.SH_CUST AS "Cust"
               ,RM.RM_NAME AS "CustName"
               ,SD.SD_XX_PICKLIST_NUM     AS "PickSlip"
               ,ST.ST_PSLIP               AS "DespatchNote"
               ,SH.SH_ORDER            AS "Order#"
               ,SH.SH_SPARE_STR_5         AS "OrderwareNum"
               ,SH.SH_CUST_REF                AS "Cust Ref"
               ,SD.SD_STOCK               AS "Stock"
               ,SD.SD_DESC                AS "Description"
               ,SD.SD_QTY_ORDER           AS "Qty Ordered"
               ,SD.SD_QTY_UNIT            AS "UOI"
               ,SL.SL_PSLIP_QTY           AS "Qty Despatched"
               ,ST.ST_WEIGHT AS "Weight"
               ,ST.ST_PACKAGES AS "Packages"
               ,IM.IM_REPORTING_PRICE          AS "Price(IM)"
               ,IM.IM_SCALE_LCL                       AS "LCL Scale"
               ,SD.SD_SELL_PRICE         AS "SD_SELL_PRICE"
               ,'FIFO'         AS "FIFO Unit Price"
               ,NI.NI_SELL_VALUE AS "BatchUnitSellPrice"
               ,SD.SD_EXCL AS "Ext GST Sell"
               ,SD.SD_TAX AS "GST"
               ,SD.SD_INCL AS "Incl GST"
               ,SH.SH_ADDRESS             AS "Address"
               ,SH.SH_SUBURB              AS "Address2"
               ,SH.SH_CITY                AS "Suburb"
               ,SH.SH_STATE               AS "State"
               ,SH.SH_POST_CODE           AS "Postcode"
               ,SH.SH_NOTE_2              AS "AttentionTo"
               ,SH.SH_NOTE_1              AS "DeliverTo"
               ,SH.SH_SPARE_STR_4             AS "CostCenter"
               ,NULL            AS "RD_SPARE_STR_1"
               ,SH.SH_SPARE_STR_6         AS "Ordered By"
               ,IM.IM_OWNED_BY AS "OwnedBy"
               ,IM.IM_FINISH AS "Finish"
               ,SD.SD_LINE AS "OWLineNum"
               ,IM.IM_BRAND AS "Finish"
               ,ST.ST_SPARE_INT_1 AS "SentFrom"
               ,NULL
               ,NULL
               ,NULL
               ,NULL
               ,NULL,
               NULL,NULL,NULL,NULL
      FROM  PWIN175.SD
            RIGHT JOIN PWIN175.SH  ON SH.SH_ORDER  = SD.SD_ORDER
            LEFT JOIN PWIN175.ST  ON ST.ST_PICK  = SD.SD_LAST_PICK_NUM
            LEFT JOIN PWIN175.SL   ON SL.SL_PICK   = ST.ST_PICK
            INNER JOIN PWIN175.RM  ON RM.RM_CUST  = SH.SH_CUST
            --INNER JOIN PWIN175.RD  ON RD.RD_CODE  = SH.SH_DEL_CODE
            INNER JOIN Dev_Group_Cust ON Dev_Group_Cust.sCust = SH.SH_CUST
            INNER JOIN PWIN175.IM  ON IM.IM_STOCK = SD.SD_STOCK
            INNER JOIN PWIN175.NI  ON NI.NI_NV_EXT_KEY = SL.SL_UID
      WHERE NI.NI_STRENGTH = 3 AND NI.NI_DATE = ST.ST_DESP_DATE AND NI.NI_STOCK = SD_STOCK AND NI.NI_STATUS <> 0
      AND     SH.SH_STATUS <> 3
      --AND     sGroupCust IN (gds_cust_in)
      AND       SH.SH_ORDER = ST.ST_ORDER
      --AND  SD.SD_STOCK = gds_stock_in
      AND       ST.ST_DESP_DATE >= '27-Oct-2016' AND ST.ST_DESP_DATE <= '29-Nov-2016'
      AND       Dev_Group_Cust.sGroupCust = 'V-OFFWOR'
      --AND       ST.ST_DESP_DATE >= '10-APR-2014' AND ST.ST_DESP_DATE <= '15-APR-2014'
      AND       SD.SD_LAST_PICK_NUM = ST.ST_PICK
      GROUP BY  SH.SH_CUST,SH.SH_ORDER,SH.SH_ADD_DATE,SH.SH_ADDRESS,SH.SH_SUBURB,SH.SH_CITY,SH.SH_STATE,SH.SH_POST_CODE,SH.SH_NOTE_1,SH.SH_NOTE_2,SH.SH_CAMPAIGN, SH.SH_SPARE_STR_4,SH.SH_SPARE_DBL_9,SH.SH_CUST_REF,SH.SH_SPARE_STR_5,
                ST.ST_ADD_DATE,ST.ST_ADD_OP,ST.ST_PICK_PRINT_DATE,ST.ST_DESP_DATE,ST.ST_WEIGHT,ST.ST_PACKAGES,ST.ST_PSLIP,ST.ST_PICK,
                SD.SD_DESC,SD.SD_STOCK,SD.SD_XX_OW_UNIT_PRICE,SD.SD_SELL_PRICE,SD.SD_LINE,SD.SD_EXCL,SD.SD_INCL,SD.SD_QTY_ORDER,SD.SD_QTY_UNIT,SD.SD_XX_PICKLIST_NUM,
                IM.IM_BRAND,IM.IM_OWNED_BY,IM.IM_CUST,IM.IM_XX_COST_CENTRE01,IM.IM_REPORTING_PRICE,   ST.ST_SPARE_INT_1,
                NI.NI_SELL_VALUE,NI.NI_NX_QUANTITY,ST.ST_SPARE_DBL_1,  SD.SD_TAX, SH.SH_SPARE_STR_6,
                --RM.RM_GROUP_CUST,RM.RM_PARENT,
                Dev_Group_Cust.sGroupCust,RM.RM_NAME,IM.IM_SCALE_LCL,  IM.IM_FINISH,
                SL.SL_PSLIP_QTY,SD.SD_SPARE_STR_4;
  
      CURSOR canal
      IS
      SELECT    substr(To_Char(ST.ST_DESP_DATE),0,10) AS "DespatchDate"
                ,substr(To_Char(SH.SH_ADD_DATE),0,10) AS "OrderDate"
                ,Tmp_Group_Cust.sGroupCust   AS "Parent"
                ,SH.SH_CUST AS "Cust"
               ,RM.RM_NAME AS "CustName"
               ,SD.SD_XX_PICKLIST_NUM     AS "PickSlip"
               ,ST.ST_PSLIP               AS "DespatchNote"
               ,SH.SH_ORDER            AS "Order#"
               ,SH.SH_SPARE_STR_5         AS "OrderwareNum"
               ,SH.SH_CUST_REF                AS "Cust Ref"
               ,SD.SD_STOCK               AS "Stock"
               ,SD.SD_DESC                AS "Description"
               ,SD.SD_QTY_ORDER           AS "Qty Ordered"
               ,SD.SD_QTY_UNIT            AS "UOI"
               ,SL.SL_PSLIP_QTY           AS "Qty Despatched"
               ,ST.ST_WEIGHT AS "Weight"
               ,ST.ST_PACKAGES AS "Packages"
               ,IM.IM_REPORTING_PRICE          AS "Price(IM)"
               ,IM.IM_SCALE_LCL                       AS "LCL Scale"
               ,SD.SD_SELL_PRICE         AS "SD_SELL_PRICE"
               ,'FIFO'         AS "FIFO Unit Price"
               ,NI.NI_SELL_VALUE AS "BatchUnitSellPrice"
               ,SD.SD_EXCL AS "Ext GST Sell"
               ,SD.SD_TAX AS "GST"
               ,SD.SD_INCL AS "Incl GST"
               ,SH.SH_ADDRESS             AS "Address"
               ,SH.SH_SUBURB              AS "Address2"
               ,SH.SH_CITY                AS "Suburb"
               ,SH.SH_STATE               AS "State"
               ,SH.SH_POST_CODE           AS "Postcode"
               ,SH.SH_NOTE_2              AS "AttentionTo"
               ,SH.SH_NOTE_1              AS "DeliverTo"
               ,SH.SH_SPARE_STR_4             AS "CostCenter"
               ,NULL            AS "RD_SPARE_STR_1"
               ,SH.SH_SPARE_STR_6         AS "Ordered By"
               ,IM.IM_OWNED_BY AS "OwnedBy"
               ,IM.IM_FINISH AS "Finish"
               ,SD.SD_LINE AS "OWLineNum"
               ,IM.IM_BRAND AS "Finish"
               ,ST.ST_SPARE_INT_1 AS "SentFrom"
               ,NULL
               ,NULL
               ,NULL
               ,NULL
               ,NULL,
               NULL,NULL,NULL,NULL
      FROM  PWIN175.SD
            RIGHT JOIN PWIN175.SH  ON SH.SH_ORDER  = SD.SD_ORDER
            LEFT JOIN PWIN175.ST  ON ST.ST_PICK  = SD.SD_LAST_PICK_NUM
            LEFT JOIN PWIN175.SL   ON SL.SL_PICK   = ST.ST_PICK
            INNER JOIN PWIN175.RM  ON RM.RM_CUST  = SH.SH_CUST
            --INNER JOIN PWIN175.RD  ON RD.RD_CODE  = SH.SH_DEL_CODE
            INNER JOIN Tmp_Group_Cust ON Tmp_Group_Cust.sCust = SH.SH_CUST
            INNER JOIN PWIN175.IM  ON IM.IM_STOCK = SD.SD_STOCK
            INNER JOIN PWIN175.NI  ON NI.NI_NV_EXT_KEY = SL.SL_UID
      WHERE NI.NI_STRENGTH = 3 AND NI.NI_DATE = ST.ST_DESP_DATE AND NI.NI_STOCK = SD_STOCK AND NI.NI_STATUS <> 0
      AND     SH.SH_STATUS <> 3
      --AND     sGroupCust IN (gds_cust_in)
      AND       SH.SH_ORDER = ST.ST_ORDER
      --AND  SD.SD_STOCK = gds_stock_in
      AND       ST.ST_DESP_DATE >= gds_start_date_in AND ST.ST_DESP_DATE <= gds_new_end_date_in
      AND       RM_ANAL = gds_analysis
      --AND       ST.ST_DESP_DATE >= '10-APR-2014' AND ST.ST_DESP_DATE <= '15-APR-2014'
      AND       SD.SD_LAST_PICK_NUM = ST.ST_PICK
      GROUP BY  SH.SH_CUST,SH.SH_ORDER,SH.SH_ADD_DATE,SH.SH_ADDRESS,SH.SH_SUBURB,SH.SH_CITY,SH.SH_STATE,SH.SH_POST_CODE,SH.SH_NOTE_1,SH.SH_NOTE_2,SH.SH_CAMPAIGN, SH.SH_SPARE_STR_4,SH.SH_SPARE_DBL_9,SH.SH_CUST_REF,SH.SH_SPARE_STR_5,
                ST.ST_ADD_DATE,ST.ST_ADD_OP,ST.ST_PICK_PRINT_DATE,ST.ST_DESP_DATE,ST.ST_WEIGHT,ST.ST_PACKAGES,ST.ST_PSLIP,ST.ST_PICK,
                SD.SD_DESC,SD.SD_STOCK,SD.SD_XX_OW_UNIT_PRICE,SD.SD_SELL_PRICE,SD.SD_LINE,SD.SD_EXCL,SD.SD_INCL,SD.SD_QTY_ORDER,SD.SD_QTY_UNIT,SD.SD_XX_PICKLIST_NUM,
                IM.IM_BRAND,IM.IM_OWNED_BY,IM.IM_CUST,IM.IM_XX_COST_CENTRE01,IM.IM_REPORTING_PRICE,   ST.ST_SPARE_INT_1,
                NI.NI_SELL_VALUE,NI.NI_NX_QUANTITY,ST.ST_SPARE_DBL_1,  SD.SD_TAX, SH.SH_SPARE_STR_6,
                --RM.RM_GROUP_CUST,RM.RM_PARENT,
                Tmp_Group_Cust.sGroupCust,RM.RM_NAME,IM.IM_SCALE_LCL,  IM.IM_FINISH,
                SL.SL_PSLIP_QTY,SD.SD_SPARE_STR_4;
                
                
       CURSOR c
      IS
      SELECT    substr(To_Char(ST.ST_DESP_DATE),0,10) AS "DespatchDate"
                ,substr(To_Char(SH.SH_ADD_DATE),0,10) AS "OrderDate"
                ,Tmp_Group_Cust.sGroupCust   AS "Parent"
                ,SH.SH_CUST AS "Cust"
               ,RM.RM_NAME AS "CustName"
               ,SD.SD_XX_PICKLIST_NUM     AS "PickSlip"
               ,ST.ST_PSLIP               AS "DespatchNote"
               ,SH.SH_ORDER            AS "Order#"
               ,SH.SH_SPARE_STR_5         AS "OrderwareNum"
               ,SH.SH_CUST_REF                AS "Cust Ref"
               ,SD.SD_STOCK               AS "Stock"
               ,SD.SD_DESC                AS "Description"
               ,SD.SD_QTY_ORDER           AS "Qty Ordered"
               ,SD.SD_QTY_UNIT            AS "UOI"
               ,SL.SL_PSLIP_QTY           AS "Qty Despatched"
               ,ST.ST_WEIGHT AS "Weight"
               ,ST.ST_PACKAGES AS "Packages"
               ,IM.IM_REPORTING_PRICE          AS "Price(IM)"
               ,IM.IM_SCALE_LCL                       AS "LCL Scale"
               ,SD.SD_SELL_PRICE         AS "SD_SELL_PRICE"
               ,'FIFO'         AS "FIFO Unit Price"
               ,NI.NI_SELL_VALUE AS "BatchUnitSellPrice"
               ,SD.SD_EXCL AS "Ext GST Sell"
               ,SD.SD_TAX AS "GST"
               ,SD.SD_INCL AS "Incl GST"
               ,SH.SH_ADDRESS             AS "Address"
               ,SH.SH_SUBURB              AS "Address2"
               ,SH.SH_CITY                AS "Suburb"
               ,SH.SH_STATE               AS "State"
               ,SH.SH_POST_CODE           AS "Postcode"
               ,SH.SH_NOTE_2              AS "AttentionTo"
               ,SH.SH_NOTE_1              AS "DeliverTo"
               ,SH.SH_SPARE_STR_4             AS "CostCenter"
               ,NULL            AS "RD_SPARE_STR_1"
               ,SH.SH_SPARE_STR_6         AS "Ordered By"
               ,IM.IM_OWNED_BY AS "OwnedBy"
               ,IM.IM_FINISH AS "Finish"
               ,SD.SD_LINE AS "OWLineNum"
               ,IM.IM_BRAND AS "Finish"
               ,ST.ST_SPARE_INT_1 AS "SentFrom"
               ,NULL
               ,NULL
               ,NULL
               ,NULL
               ,NULL,
               NULL,NULL,NULL,NULL
      FROM  PWIN175.SD
            RIGHT JOIN PWIN175.SH  ON SH.SH_ORDER  = SD.SD_ORDER
            LEFT JOIN PWIN175.ST  ON ST.ST_PICK  = SD.SD_LAST_PICK_NUM
            LEFT JOIN PWIN175.SL   ON SL.SL_PICK   = ST.ST_PICK
            INNER JOIN PWIN175.RM  ON RM.RM_CUST  = SH.SH_CUST
            --INNER JOIN PWIN175.RD  ON RD.RD_CODE  = SH.SH_DEL_CODE
            INNER JOIN Tmp_Group_Cust ON Tmp_Group_Cust.sCust = SH.SH_CUST
            INNER JOIN PWIN175.IM  ON IM.IM_STOCK = SD.SD_STOCK
            INNER JOIN PWIN175.NI  ON NI.NI_NV_EXT_KEY = SL.SL_UID
      WHERE NI.NI_STRENGTH = 3 AND NI.NI_DATE = ST.ST_DESP_DATE AND NI.NI_STOCK = SD_STOCK AND NI.NI_STATUS <> 0
      AND     SH.SH_STATUS <> 3
      --AND     sGroupCust IN (gds_cust_in)
      AND       SH.SH_ORDER = ST.ST_ORDER
      --AND  SD.SD_STOCK = gds_stock_in
      AND       ST.ST_DESP_DATE >= gds_start_date_in AND ST.ST_DESP_DATE <= gds_new_end_date_in
      AND       Tmp_Group_Cust.sGroupCust = sCustomerCode
      --AND       ST.ST_DESP_DATE >= '10-APR-2014' AND ST.ST_DESP_DATE <= '15-APR-2014'
      AND       SD.SD_LAST_PICK_NUM = ST.ST_PICK
      GROUP BY  SH.SH_CUST,SH.SH_ORDER,SH.SH_ADD_DATE,SH.SH_ADDRESS,SH.SH_SUBURB,SH.SH_CITY,SH.SH_STATE,SH.SH_POST_CODE,SH.SH_NOTE_1,SH.SH_NOTE_2,SH.SH_CAMPAIGN, SH.SH_SPARE_STR_4,SH.SH_SPARE_DBL_9,SH.SH_CUST_REF,SH.SH_SPARE_STR_5,
                ST.ST_ADD_DATE,ST.ST_ADD_OP,ST.ST_PICK_PRINT_DATE,ST.ST_DESP_DATE,ST.ST_WEIGHT,ST.ST_PACKAGES,ST.ST_PSLIP,ST.ST_PICK,
                SD.SD_DESC,SD.SD_STOCK,SD.SD_XX_OW_UNIT_PRICE,SD.SD_SELL_PRICE,SD.SD_LINE,SD.SD_EXCL,SD.SD_INCL,SD.SD_QTY_ORDER,SD.SD_QTY_UNIT,SD.SD_XX_PICKLIST_NUM,
                IM.IM_BRAND,IM.IM_OWNED_BY,IM.IM_CUST,IM.IM_XX_COST_CENTRE01,IM.IM_REPORTING_PRICE,   ST.ST_SPARE_INT_1,
                NI.NI_SELL_VALUE,NI.NI_NX_QUANTITY,ST.ST_SPARE_DBL_1,  SD.SD_TAX, SH.SH_SPARE_STR_6,
                --RM.RM_GROUP_CUST,RM.RM_PARENT,
                Tmp_Group_Cust.sGroupCust,RM.RM_NAME,IM.IM_SCALE_LCL,  IM.IM_FINISH,
                SL.SL_PSLIP_QTY,SD.SD_SPARE_STR_4;
                
      
      
     BEGIN
      --nbreakpoint := 1;
      --days_as_number := gds_end_date_in - gds_start_date_in;
      --date_diff_middle := (days_as_number) / 2;
      --date_diff_next := (days_as_number / 2)  + 1 ;
      --gds_new_end_date_in :=   TO_DATE(gds_end_date_in, 'yyyy-mm-dd') - date_diff_middle;
      --gds_next_start_date_in :=  TO_DATE(gds_start_date_in, 'yyyy-mm-dd') + date_diff_next;  -- TO_DATE('2015-09-01', 'yyyy-mm-dd')
      --gds_next_end_date_in := TO_DATE(gds_end_date_in, 'yyyy-mm-dd');
      --DBMS_OUTPUT.PUT_LINE('half way point as a day is ' || date_diff_middle ||
                        --' this report will now start from ' || TO_DATE(gds_start_date_in, 'yyyy-mm-dd') ||
                        --    ' and with new end date for this report is ' || TO_DATE(gds_new_end_date_in, 'yyyy-mm-dd') || ' : and the next report will start from ' || TO_DATE(gds_next_start_date_in, 'yyyy-mm-dd') || '  and end at the original end date being ' || TO_DATE(gds_next_end_date_in, 'yyyy-mm-dd'));
--      	nCheckpoint := 2;
--        
--          If (sOp = 'PRJ' or sOp = 'DEV') Then
--            If (F_IS_TABLE_EEMPTY('Dev_Group_Cust') <= 0) Then
--              v_query  := 'TRUNCATE TABLE Dev_Group_Cust';
--              EXECUTE IMMEDIATE v_query;
--              A_TEMP_CUST_DATA(sOp);
--            End If;
--          Else
--            If (F_IS_TABLE_EEMPTY('Tmp_Group_Cust') <= 0) Then
--              v_query  := 'TRUNCATE TABLE Tmp_Group_Cust';
--              EXECUTE IMMEDIATE v_query;
--              A_TEMP_CUST_DATA(sOp);
--            End If;
--          End If;
--          
  
        
      
      --nbreakpoint := 3; 
      -- If (sOp = 'PRJ' or sOp = 'DEV') Then
      --EXECUTE IMMEDIATE 'BEGIN  A_TEMP_CUST_DATA(:sOp); END;' USING sOP;
         
       --Else
        -- EXECUTE IMMEDIATE 'BEGIN eom_report_pkg.GROUP_CUST_START; END;';
       --End If;
     -- nCheckpoint := 11;
       
  
     
     If (sOp = 'PRJ' or sOp = 'DEV') and (gds_analysis IS NULL) Then
     nCheckpoint := 4;
         DBMS_OUTPUT.PUT_LINE('About to run cDEV ' || sCustomerCode || '_DESPATCH_REPORT '); 
         v_query := 'TRUNCATE TABLE DEV_DESP_REPT';
          EXECUTE IMMEDIATE v_query;
         nCheckpoint := 2;
            OPEN cDEV;
            --DBMS_OUTPUT.PUT_LINE('despatch.' );
            LOOP
            FETCH cDEV BULK COLLECT INTO l_data LIMIT p_array_size;
    
            FORALL i IN 1..l_data.COUNT
            --DBMS_OUTPUT.PUT_LINE(l_data(10) || '.' );
            INSERT INTO DEV_DESP_REPT VALUES l_data(i);
            --USING sCust;
    
            EXIT WHEN cDEV%NOTFOUND;
    
            END LOOP;
            --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
            CLOSE cDEV;
            --FOR i IN l_data.FIRST .. l_data.LAST LOOP
            --  DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
           -- END LOOP;
         -- v_query2 :=  SQL%ROWCOUNT;
          --/COMMIT;
          DBMS_OUTPUT.PUT_LINE('Finished running cDEV ' || sCustomerCode || '_DESPATCH_REPORT' ); 
          
      Elsif (sOp = 'PRJ' or sOp = 'DEV') and (gds_analysis IS NOT NULL) Then
      nCheckpoint := 5;
          DBMS_OUTPUT.PUT_LINE('About to run cDEVAnal ' || sCustomerCode || '_DESPATCH_REPORT ');
           v_query := 'TRUNCATE TABLE DEV_DESP_REPT';
          EXECUTE IMMEDIATE v_query;
           OPEN cDEVAnal;
          ----DBMS_OUTPUT.PUT_LINE(sCustomerCode || '.' );
          LOOP
          FETCH cDEVAnal BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO DEV_DESP_REPT VALUES l_data(i);
          --USING sCust;
          EXIT WHEN cDEVAnal%NOTFOUND;
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE cDEVAnal;
          -- v_query2 :=  SQL%ROWCOUNT;
       Elsif (sOp != 'PRJ' or sOp != 'DEV') and (gds_analysis IS NULL) Then
       nCheckpoint := 6;
           v_query := 'TRUNCATE TABLE TMP_DESP_REPT';
          EXECUTE IMMEDIATE v_query;
           OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(sCustomerCode || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO TMP_DESP_REPT VALUES l_data(i);
          --USING sCust;
          EXIT WHEN c%NOTFOUND;
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
           --v_query2 :=  SQL%ROWCOUNT;
       Elsif (sOp != 'PRJ' or sOp != 'DEV') and (gds_analysis IS NOT NULL) Then
        nCheckpoint := 7;
           v_query := 'TRUNCATE TABLE TMP_DESP_REPT';
          EXECUTE IMMEDIATE v_query;
           OPEN canal;
          ----DBMS_OUTPUT.PUT_LINE(sCustomerCode || '.' );
          LOOP
          FETCH canal BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO TMP_DESP_REPT VALUES l_data(i);
          --USING sCust;
          EXIT WHEN canal%NOTFOUND;
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE canal;
          
      End If;
          -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
          ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          --END LOOP;
       v_query2 :=  SQL%ROWCOUNT;    
      COMMIT; 
      
      IF v_query2 > 0 THEN
        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
        sFileName := sCustomerCode || '_DESPATCH_REPORT-' || gds_start_date_in || '-TO-' || gds_end_date_in || '-RunOn-' || sFileTime || '_A.csv';
          
          If (sOp = 'PRJ' or sOp = 'DEV') Then
            EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,gds_start_date_in,gds_end_date_in,'L_DESPATCH_REPORT','DEV_DESP_REPT','ST',v_time_taken,SYSTIMESTAMP,sCustomerCode);
            Z2_TMP_FEES_TO_CSV(sFileName,'DEV_DESP_REPT',sOp);
          Else
            EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,gds_start_date_in,gds_end_date_in,'L_DESPATCH_REPORT','TMP_DESP_REPT','ST',v_time_taken,SYSTIMESTAMP,sCustomerCode);
            Z2_TMP_FEES_TO_CSV(sFileName,'TMP_DESP_REPT',sOp);
          End If;
         -- DBMS_OUTPUT.PUT_LINE('TMP_DESP_REPT_TO_CSV for ' || sFileName || '. qry count was ' || v_query2 );
    Else
      DBMS_OUTPUT.PUT_LINE(sCustomerCode || '_DESPATCH_REPORT failed at checkpoint ' || nCheckpoint ||  ' due to an empry recordset');
    
    END IF;
     EXCEPTION
        WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('L_DESPATCH_REPORT failed at checkpoint ' || nCheckpoint ||
                              ' with error ' || SQLCODE || ' : ' || SQLERRM);
          RAISE;
     END L_DESPATCH_REPORT; 
 
    PROCEDURE L_DESPATCH_REPORTB (
          p_array_size IN PLS_INTEGER DEFAULT 100,
          gds_analysis IN  RM.RM_ANAL%TYPE,
          gds_start_date_in IN VARCHAR2,
          gds_end_date_in IN VARCHAR2
          ,sOp IN VARCHAR2
    )
    AS
      TYPE ARRAY IS TABLE OF TMP_DESP_REPT2%ROWTYPE;
      l_data ARRAY;
      v_time_taken VARCHAR2(205);
      v_out_tx          VARCHAR2(2000);
      SQLQuery   VARCHAR2(6000);
      v_query           VARCHAR2(2000);
      v_query2          VARCHAR2(32767);
      nCheckpoint       NUMBER;
      gds_cust_not_in VARCHAR2(50) := 'TABCORP';
      nbreakpoint   NUMBER;
      sFileName VARCHAR2(560);
      sFileTime VARCHAR2(56)  := TO_CHAR(SYSDATE,'YYYYMMDD HH24MISS');
      --OPEN gds_src_get_desp_stocks FOR
      CURSOR c
      IS
     SELECT    substr(To_Char(ST.ST_DESP_DATE),0,10) AS "DespatchDate"
                ,substr(To_Char(SH.SH_ADD_DATE),0,10) AS "OrderDate"
                ,Dev_Group_Cust.sGroupCust   AS "Parent"
                ,SH.SH_CUST AS "Cust"
               ,RM.RM_NAME AS "CustName"
               ,SD.SD_XX_PICKLIST_NUM     AS "PickSlip"
               ,ST.ST_PSLIP               AS "DespatchNote"
               ,SH.SH_ORDER            AS "Order#"
               ,SH.SH_SPARE_STR_5         AS "OrderwareNum"
               ,SH.SH_CUST_REF                AS "Cust Ref"
               ,SD.SD_STOCK               AS "Stock"
               ,SD.SD_DESC                AS "Description"
               ,SD.SD_QTY_ORDER           AS "Qty Ordered"
               ,SD.SD_QTY_UNIT            AS "UOI"
               ,SL.SL_PSLIP_QTY           AS "Qty Despatched"
               ,ST.ST_WEIGHT AS "Weight"
               ,ST.ST_PACKAGES AS "Packages"
               ,IM.IM_REPORTING_PRICE          AS "Price(IM)"
               ,IM.IM_SCALE_LCL                       AS "LCL Scale"
               ,SD.SD_SELL_PRICE         AS "SD_SELL_PRICE"
               ,'FIFO'         AS "FIFO Unit Price"
               ,NI.NI_SELL_VALUE AS "BatchUnitSellPrice"
               ,SD.SD_EXCL AS "Ext GST Sell"
               ,SD.SD_TAX AS "GST"
               ,SD.SD_INCL AS "Incl GST"
               ,SH.SH_ADDRESS             AS "Address"
               ,SH.SH_SUBURB              AS "Address2"
               ,SH.SH_CITY                AS "Suburb"
               ,SH.SH_STATE               AS "State"
               ,SH.SH_POST_CODE           AS "Postcode"
               ,SH.SH_NOTE_2              AS "AttentionTo"
               ,SH.SH_NOTE_1              AS "DeliverTo"
               ,SH.SH_SPARE_STR_4             AS "CostCenter"
               ,NULL            AS "RD_SPARE_STR_1"
               ,SH.SH_SPARE_STR_6         AS "Ordered By"
               ,IM.IM_OWNED_BY AS "OwnedBy"
               ,IM.IM_FINISH AS "Finish"
               ,SD.SD_LINE AS "OWLineNum"
               ,IM.IM_BRAND AS "Finish"
               ,ST.ST_SPARE_INT_1 AS "SentFrom"
               ,NULL
               ,NULL
               ,NULL
               ,NULL
               ,NULL,
               NULL,NULL,NULL,NULL
      FROM  PWIN175.SD
            RIGHT JOIN PWIN175.SH  ON SH.SH_ORDER  = SD.SD_ORDER
            LEFT JOIN PWIN175.ST  ON ST.ST_PICK  = SD.SD_LAST_PICK_NUM
            LEFT JOIN PWIN175.SL   ON SL.SL_PICK   = ST.ST_PICK
            INNER JOIN PWIN175.RM  ON RM.RM_CUST  = SH.SH_CUST
            --INNER JOIN PWIN175.RD  ON RD.RD_CODE  = SH.SH_DEL_CODE
            INNER JOIN Dev_Group_Cust ON Dev_Group_Cust.sCust = SH.SH_CUST
            INNER JOIN PWIN175.IM  ON IM.IM_STOCK = SD.SD_STOCK
            INNER JOIN PWIN175.NI  ON NI.NI_NV_EXT_KEY = SL.SL_UID
      WHERE NI.NI_STRENGTH = 3 AND NI.NI_DATE = ST.ST_DESP_DATE AND NI.NI_STOCK = SD_STOCK AND NI.NI_STATUS <> 0
      AND     SH.SH_STATUS <> 3
      --AND     sGroupCust IN (gds_cust_in)
      AND       SH.SH_ORDER = ST.ST_ORDER
      --AND  SD.SD_STOCK = gds_stock_in
      AND       ST.ST_DESP_DATE >= '27-Oct-2016' AND ST.ST_DESP_DATE <= '29-Nov-2016'
      AND       Dev_Group_Cust.sGroupCust = 'V-OFFWOR'
      --AND       ST.ST_DESP_DATE >= '10-APR-2014' AND ST.ST_DESP_DATE <= '15-APR-2014'
      AND       SD.SD_LAST_PICK_NUM = ST.ST_PICK
      GROUP BY  SH.SH_CUST,SH.SH_ORDER,SH.SH_ADD_DATE,SH.SH_ADDRESS,SH.SH_SUBURB,SH.SH_CITY,SH.SH_STATE,SH.SH_POST_CODE,SH.SH_NOTE_1,SH.SH_NOTE_2,SH.SH_CAMPAIGN, SH.SH_SPARE_STR_4,SH.SH_SPARE_DBL_9,SH.SH_CUST_REF,SH.SH_SPARE_STR_5,
                ST.ST_ADD_DATE,ST.ST_ADD_OP,ST.ST_PICK_PRINT_DATE,ST.ST_DESP_DATE,ST.ST_WEIGHT,ST.ST_PACKAGES,ST.ST_PSLIP,ST.ST_PICK,
                SD.SD_DESC,SD.SD_STOCK,SD.SD_XX_OW_UNIT_PRICE,SD.SD_SELL_PRICE,SD.SD_LINE,SD.SD_EXCL,SD.SD_INCL,SD.SD_QTY_ORDER,SD.SD_QTY_UNIT,SD.SD_XX_PICKLIST_NUM,
                IM.IM_BRAND,IM.IM_OWNED_BY,IM.IM_CUST,IM.IM_XX_COST_CENTRE01,IM.IM_REPORTING_PRICE,   ST.ST_SPARE_INT_1,
                NI.NI_SELL_VALUE,NI.NI_NX_QUANTITY,ST.ST_SPARE_DBL_1,  SD.SD_TAX, SH.SH_SPARE_STR_6,
                --RM.RM_GROUP_CUST,RM.RM_PARENT,
                Dev_Group_Cust.sGroupCust,RM.RM_NAME,IM.IM_SCALE_LCL,  IM.IM_FINISH,
                SL.SL_PSLIP_QTY,SD.SD_SPARE_STR_4;
                
      l_start number default dbms_utility.get_time;
      
     BEGIN
     -- nbreakpoint := 1;
     -- EXECUTE IMMEDIATE 'BEGIN eom_report_pkg.GROUP_CUST_START; END;';
     --nCheckpoint := 11;
         
  
     nCheckpoint := 2;
      If (sOp = 'PRJ' or sOp = 'DEV') Then
           v_query := 'TRUNCATE TABLE DEV_DESP_REPT2';
          EXECUTE IMMEDIATE v_query;
          OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(sCustomerCode || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO DEV_DESP_REPT2 VALUES l_data(i);
          --USING sCust;
          EXIT WHEN c%NOTFOUND;
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
      Else
           v_query := 'TRUNCATE TABLE TMP_DESP_REPT2';
          EXECUTE IMMEDIATE v_query;
           OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(sCustomerCode || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO TMP_DESP_REPT2 VALUES l_data(i);
          --USING sCust;
          EXIT WHEN c%NOTFOUND;
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
      End If;
          -- FOR i IN l_data.FIRST .. l_data.LAST LOOP
          ----DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          --END LOOP;
          v_query2 :=  SQL%ROWCOUNT;
      COMMIT; 
      v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
          If (sOp = 'PRJ' or sOp = 'DEV') Then
            EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,gds_start_date_in,gds_end_date_in,'L_DESPATCH_REPORTB','DEV_DESP_REPT2','ST',v_time_taken,SYSTIMESTAMP,'LINK');
            sFileName := 'LINK-L_DESPATCH_REPORTB-' || gds_start_date_in || '-TO-' || gds_end_date_in || '-RunOn-' || sFileTime || '_B.csv';
            Z2_TMP_FEES_TO_CSV(sFileName,'DEV_DESP_REPT2',sOp);
          Else
            EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,gds_start_date_in,gds_end_date_in,'L_DESPATCH_REPORTB','TMP_DESP_REPT2','ST',v_time_taken,SYSTIMESTAMP,'LINK');
            sFileName := 'LINK-L_DESPATCH_REPORTB-' || gds_start_date_in || '-TO-' || gds_end_date_in || '-RunOn-' || sFileTime || '_B.csv';
            Z2_TMP_FEES_TO_CSV(sFileName,'TMP_DESP_REPT2',sOp);
          End If;
          --DBMS_OUTPUT.PUT_LINE('TMP_DESP_REPT_TO_CSV B for ' || sFileName || '.' );
     EXCEPTION
        WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('L_DESPATCH_REPORTB failed at checkpoint ' || nbreakpoint ||
                              ' with error ' || SQLCODE || ' : ' || SQLERRM);
          RAISE;
     END L_DESPATCH_REPORTB; 
 
    
    /* Y Run this once for each customer including intercompany   
       This merges all the Charges from each of the temp tables   
       Temp Tables Used   
       1. TMP_ALL_FEES   */
    PROCEDURE Y_EOM_TMP_MERGE_ALL_FEES (
     p_array_size IN PLS_INTEGER DEFAULT 100
     ,sOp IN VARCHAR2
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
      ----DBMS_OUTPUT.PUT_LINE(start_date || ' - ' || end_date || '.' || sCust );
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
            Select * From TMP_V_FREIGHT
            UNION ALL
            --Select * From TMP_M_XX_FREIGHT
            --UNION ALL          
           -- Select * From TMP_ALL_FREIGHT_F WHERE FEETYPE != 'UnPricedManualFreight'-- AND Trim(FEETYPE)  != 'Freight Fee'
           -- UNION ALL
           -- Select * From TMP_ALL_FREIGHT_F
            --WHERE Trim(FEETYPE) = 'Freight Fee' AND rowid in
            --(select max(rowid) from TMP_ALL_FREIGHT_F WHERE Trim(FEETYPE)  = 'Freight Fee' group by DESPNOTE)
            --UNION ALL
            Select  *
                From TMP_ALL_FREIGHT_F 
                WHERE FEETYPE = 'Freight Fee' AND rowid in
                (select max(rowid) from TMP_ALL_FREIGHT_F WHERE FEETYPE = 'Freight Fee' group by DESPNOTE)   --1114
             UNION ALL
            Select  *
                From TMP_ALL_FREIGHT_F 
                WHERE FEETYPE != 'Freight Fee' AND FEETYPE != 'UnPricedManualFreight' AND FEETYPE != 'Manual Freight' AND rowid in
                (select max(rowid) from TMP_ALL_FREIGHT_F WHERE FEETYPE != 'Freight Fee' group by DESPNOTE) 
            
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
            UNION ALL --TMP_ALL_ORD_FEES
            Select * From TMP_ALL_ORD_FEES
            
            UNION ALL
            Select * From TMP_STD_ORD_FEES
           /* UNION ALL
            Select * From TMP_FAX_ORD_FEES
            UNION ALL
            Select * From TMP_MAN_ORD_FEES
            UNION ALL
            Select * From TMP_EMAIL_ORD_FEES
            UNION ALL,          
            */
            UNION ALL         
            Select * From TMP_DESTROY_ORD_FEES         
            UNION ALL          
            Select * From TMP_PAL_DESP_FEES
            UNION ALL
            Select * From TMP_PAL_IN_FEES
            UNION ALL
            Select * From TMP_CTN_IN_FEES
            UNION ALL
            Select * From TMP_CTN_DESP_FEES
            UNION ALL
            Select * From TMP_CUSTOMER_FEES
            UNION ALL
            Select * From TMP_STOR_FEES WHERE FEETYPE != 'UNKNOWN'
            --UNION ALL
            --Select * From TMP_SLOW_STOR_FEES
            --UNION ALL
            --Select * From TMP_SEC_STOR_FEES
  
                ;
       CURSOR c2
      --(
        --start_date IN ST.ST_DESP_DATE%TYPE
      -- ,end_date IN ST.ST_DESP_DATE%TYPE
      --sCust IN RM.RM_CUST%TYPE
       --)
       IS
            --Insert Into TMP_ALL_FEES
            --Select * From TMP_FREIGHT
            --UNION ALL
            Select * From DEV_V_FREIGHT
            UNION ALL
            --Select * From TMP_M_XX_FREIGHT
            --UNION ALL          
           -- Select * From TMP_ALL_FREIGHT_F WHERE FEETYPE != 'UnPricedManualFreight'-- AND Trim(FEETYPE)  != 'Freight Fee'
           -- UNION ALL
           -- Select * From TMP_ALL_FREIGHT_F
            --WHERE Trim(FEETYPE) = 'Freight Fee' AND rowid in
            --(select max(rowid) from TMP_ALL_FREIGHT_F WHERE Trim(FEETYPE)  = 'Freight Fee' group by DESPNOTE)
            --UNION ALL
            Select  *
                From DEV_ALL_FREIGHT_F 
                WHERE FEETYPE = 'Freight Fee' AND rowid in
                (select max(rowid) from DEV_ALL_FREIGHT_F WHERE FEETYPE = 'Freight Fee' group by DESPNOTE)   --1114
             UNION ALL
            Select  *
                From DEV_ALL_FREIGHT_F 
                WHERE FEETYPE != 'Freight Fee' AND FEETYPE != 'UnPricedManualFreight' AND FEETYPE != 'Manual Freight' AND rowid in
                (select max(rowid) from DEV_ALL_FREIGHT_F WHERE FEETYPE != 'Freight Fee' group by DESPNOTE) 
            
            UNION ALL
            Select * From DEV_HANDLING_FEES
            UNION ALL
            Select * From DEV_PICK_FEES
            UNION ALL
            Select * From DEV_SHRINKWRAP_FEES
            UNION ALL
            Select * From DEV_STOCK_FEES
            UNION ALL
            Select * From DEV_PACKING_FEES
            UNION ALL
            Select * From DEV_MISC_FEES
            UNION ALL --TMP_ALL_ORD_FEES
            Select * From DEV_ALL_ORD_FEES
            
            UNION ALL
            Select * From DEV_STD_ORD_FEES
           /* UNION ALL
            Select * From TMP_FAX_ORD_FEES
            UNION ALL
            Select * From TMP_MAN_ORD_FEES
            UNION ALL
            Select * From TMP_EMAIL_ORD_FEES
            UNION ALL,          
            */
            UNION ALL         
            Select * From DEV_DESTROY_ORD_FEES         
            UNION ALL          
            Select * From DEV_PAL_DESP_FEES
            UNION ALL
            Select * From DEV_PAL_IN_FEES
            UNION ALL
            Select * From DEV_CTN_IN_FEES
            UNION ALL
            Select * From DEV_CTN_DESP_FEES
            UNION ALL
            Select * From DEV_CUSTOMER_FEES
            UNION ALL
            Select * From DEV_STOR_FEES WHERE FEETYPE != 'UNKNOWN'
            --UNION ALL
            --Select * From TMP_SLOW_STOR_FEES
            --UNION ALL
            --Select * From TMP_SEC_STOR_FEES
  
                ;
  
  
  
      BEGIN
  
      
      nCheckpoint := 2;
       If (sOp = 'PRJ' or sOp = 'DEV') Then
          OPEN c2;
          ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
          LOOP
          FETCH c2 BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO DEV_ALL_FEES_F VALUES l_data(i);
          --USING sCust;
  
          EXIT WHEN c2%NOTFOUND;
  
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c2;
      Else
           OPEN c;
          ----DBMS_OUTPUT.PUT_LINE(sCust || '.' );
          LOOP
          FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
  
          FORALL i IN 1..l_data.COUNT
          ----DBMS_OUTPUT.PUT_LINE(i || '.' );
          INSERT INTO TMP_ALL_FEES_F VALUES l_data(i);
          --USING sCust;
  
          EXIT WHEN c%NOTFOUND;
  
          END LOOP;
         -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
          CLOSE c;
      End If;
       --  FOR i IN l_data.FIRST .. l_data.LAST LOOP
       --   --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        --END LOOP;
  
    COMMIT;
    --RETURN;
        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
        If (sOp = 'PRJ' or sOp = 'DEV') Then
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,sysdate,sysdate,'Y_EOM_TMP_MERGE_ALL_FEES','DEV','DEV_ALL_FEES_F',v_time_taken,SYSTIMESTAMP,NULL);
        Else
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,sysdate,sysdate,'Y_EOM_TMP_MERGE_ALL_FEES','TMP','TMP_ALL_FEES_F',v_time_taken,SYSTIMESTAMP,NULL);
        End If;
    --DBMS_OUTPUT.PUT_LINE('Y_EOM_TMP_MERGE_ALL_FEES and dump data in ' ||  (round((dbms_utility.get_time-l_start)/100, 6) ||
     --   ' Seconds...' ));
  
      COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Y_EOM_TMP_MERGE_ALL_FEES failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
        RAISE;
  
    END Y_EOM_TMP_MERGE_ALL_FEES;
    
    /* Y Run this once for each customer including intercompany   
       This merges all the Charges from each of the temp tables   
       Temp Tables Used   
       1. TMP_ALL_FEES   */
    PROCEDURE Y_EOM_TMP_MERGE_ALL_FEES2(sOp IN VARCHAR2) 
      IS
      TYPE ARRAY IS TABLE OF TMP_ALL_FEES%ROWTYPE;
      l_data ARRAY;
      v_time_taken VARCHAR2(205);
      v_out_tx          VARCHAR2(2000);
      SQLQuery   VARCHAR2(6000);
      v_query           VARCHAR2(2000);
      v_query2          VARCHAR2(32767);
      v_query3          VARCHAR2(32767);
      nCheckpoint       NUMBER;
      sCourierm         VARCHAR2(20) := 'COURIERM';
      sCouriers         VARCHAR2(20) := 'COURIERS';
      sCourier         VARCHAR2(20) := 'COURIER%';
      sServ8             VARCHAR2(20) := 'SERV8';
      sServ3             VARCHAR2(20) := 'SERV%';
      --sCust2    VARCHAR2(20) := sCust;
     -- end_date2 ST.ST_DESP_DATE%TYPE := end_date;
      ----DBMS_OUTPUT.PUT_LINE(start_date || ' - ' || end_date || '.' || sCust );
       l_start number default dbms_utility.get_time;
  BEGIN
   v_query3 := q'{INSERT INTO TMP_ALL_FEES
      Select  *
                From TMP_ALL_FREIGHT_F 
                WHERE FEETYPE = 'Freight Fee' AND rowid in
                (select max(rowid) from TMP_ALL_FREIGHT_F WHERE FEETYPE = 'Freight Fee' group by DESPNOTE,COUNTOFSTOCKS)   --1114
             UNION ALL
            Select  *
                From TMP_ALL_FREIGHT_F 
                WHERE FEETYPE != 'Freight Fee' AND FEETYPE != 'UnPricedManualFreight' AND rowid in
                (select max(rowid) from TMP_ALL_FREIGHT_F WHERE FEETYPE != 'Freight Fee' group by DESPNOTE,COUNTOFSTOCKS) 
            UNION ALL
            Select  * From TMP_V_FREIGHT
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
            Select * From TMP_ALL_ORD_FEES
            UNION ALL
            Select * From TMP_STD_ORD_FEES
            UNION ALL         
            Select * From TMP_DESTROY_ORD_FEES         
            UNION ALL          
            Select * From TMP_PAL_DESP_FEES
            UNION ALL
            Select * From TMP_PAL_IN_FEES
            UNION ALL
            Select * From TMP_CTN_IN_FEES
            UNION ALL
            Select * From TMP_CTN_DESP_FEES
            UNION ALL
            Select * From TMP_CUSTOMER_FEES
            UNION ALL
            Select * From TMP_STOR_FEES WHERE FEETYPE != 'UNKNOWN'}';

    v_query2 := q'{INSERT INTO DEV_ALL_FEES
      Select  *
                From DEV_ALL_FREIGHT_F 
                WHERE FEETYPE = 'Freight Fee' AND rowid in
                (select max(rowid) from DEV_ALL_FREIGHT_F WHERE FEETYPE = 'Freight Fee' group by DESPNOTE,COUNTOFSTOCKS)   --1114
             UNION ALL
            Select  *
                From DEV_ALL_FREIGHT_F 
                WHERE FEETYPE != 'Freight Fee' AND FEETYPE != 'UnPricedManualFreight' AND rowid in
                (select max(rowid) from DEV_ALL_FREIGHT_F WHERE FEETYPE != 'Freight Fee' group by DESPNOTE,COUNTOFSTOCKS) 
            UNION ALL
            Select  * From DEV_V_FREIGHT
            UNION ALL
            Select * From DEV_HANDLING_FEES
            UNION ALL
            Select * From DEV_PICK_FEES
            UNION ALL
            Select * From DEV_SHRINKWRAP_FEES
            UNION ALL
            Select * From DEV_STOCK_FEES
            UNION ALL
            Select * From DEV_PACKING_FEES
            UNION ALL
            Select * From DEV_MISC_FEES
            UNION ALL 
            Select * From DEV_ALL_ORD_FEES
            UNION ALL
            Select * From DEV_STD_ORD_FEES
            UNION ALL         
            Select * From DEV_DESTROY_ORD_FEES         
            UNION ALL          
            Select * From DEV_PAL_DESP_FEES
            UNION ALL
            Select * From DEV_PAL_IN_FEES
            UNION ALL
            Select * From DEV_CTN_IN_FEES
            UNION ALL
            Select * From DEV_CTN_DESP_FEES
            UNION ALL
            Select * From DEV_CUSTOMER_FEES
            UNION ALL
            Select * From DEV_STOR_FEES WHERE FEETYPE != 'UNKNOWN'}';
  
  nCheckpoint := 99;
    If (sOp = 'PRJ' or sOp = 'DEV') Then
			v_query := 'TRUNCATE TABLE DEV_ALL_FEES';
		Else
			v_query := 'TRUNCATE TABLE TMP_ALL_FEES';
		End If;
	
	EXECUTE IMMEDIATE v_query;
	COMMIT;
   DBMS_OUTPUT.PUT_LINE('TRUNCATE TABLE DEV_ALL_FEES, sOp is ' || sOp );  
    
  nCheckpoint := 200;
      If (sOp = 'PRJ' or sOp = 'DEV') Then
        EXECUTE IMMEDIATE v_query2;
      Else
        EXECUTE IMMEDIATE v_query3;
      End If;
     --DBMS_OUTPUT.PUT_LINE('v_query2 is ' || v_query2 );  
     
  
    COMMIT;
    --RETURN;
        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
        If (sOp = 'PRJ' or sOp = 'DEV') Then
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,sysdate,sysdate,'Y_EOM_TMP_MERGE_ALL_FEES2','DEV','DEV_ALL_FEES',v_time_taken,SYSTIMESTAMP,NULL);
        Else
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,sysdate,sysdate,'Y_EOM_TMP_MERGE_ALL_FEES2','TMP','TMP_ALL_FEES',v_time_taken,SYSTIMESTAMP,NULL);
        End If;
    --DBMS_OUTPUT.PUT_LINE('Y_EOM_TMP_MERGE_ALL_FEES2 and dump data in ' ||  (round((dbms_utility.get_time-l_start)/100, 6) ||
      --  ' Seconds...' ));
  
      COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Y_EOM_TMP_MERGE_ALL_FEES2 failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
        RAISE;
  
    END Y_EOM_TMP_MERGE_ALL_FEES2;
    
    /* Y Run this once for each customer including intercompany   
       This merges all the Charges from each of the temp tables   
       Temp Tables Used   
       1. TMP_ALL_FEES   */
    PROCEDURE Y_EOM_TMP_MERGE_ALL_FEES_FINAL(sCustomerCode IN VARCHAR2,sOp IN VARCHAR2) 
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
      ----DBMS_OUTPUT.PUT_LINE(start_date || ' - ' || end_date || '.' || sCust );
       l_start number default dbms_utility.get_time;
  BEGIN
  If (sOp = 'PRJ' or sOp = 'DEV') Then
   v_query := q'{INSERT INTO DEV_ALL_FEES_F
                Select  * FROM DEV_ALL_FEES
                WHERE PARENT = :sCust_start OR CUSTOMER = :sCust}';  
  Else
     v_query := q'{INSERT INTO TMP_ALL_FEES_F
                Select  * FROM TMP_ALL_FEES
                WHERE PARENT = :sCust_start OR CUSTOMER = :sCust}';  
  End If;
  nCheckpoint := 2;
      EXECUTE IMMEDIATE v_query USING sCustomerCode,sCustomerCode;

    COMMIT;
    --RETURN;
        v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
        If (sOp = 'PRJ' or sOp = 'DEV') Then
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,sysdate,sysdate,'Y_EOM_TMP_MERGE_ALL_FEES_FINAL','DEV_ALL_FEES','DEV_ALL_FEES_F',v_time_taken,SYSTIMESTAMP,NULL);
        Else
          EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,sysdate,sysdate,'Y_EOM_TMP_MERGE_ALL_FEES_FINAL','TMP_ALL_FEES','TMP_ALL_FEES_F',v_time_taken,SYSTIMESTAMP,NULL);
        End IF;
    --DBMS_OUTPUT.PUT_LINE('Y_EOM_TMP_MERGE_ALL_FEES_FINAL and dump data in ' ||  (round((dbms_utility.get_time-l_start)/100, 6) ||
      --  ' Seconds...' )); 
      COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Y_EOM_TMP_MERGE_ALL_FEES_FINAL failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
        RAISE;
  
    END Y_EOM_TMP_MERGE_ALL_FEES_FINAL;
    
    /* Y Run this once for each customer including intercompany   
       This merges all the Charges from each of the temp tables   
       Temp Tables Used   
       1. TMP_ALL_FEES   
	*/
    PROCEDURE Z3_EOM_RUN_ALL (
      p_array_size_start IN PLS_INTEGER DEFAULT 100
      ,start_date IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,end_date IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCust_start IN VARCHAR2  DEFAULT ''
      ,sAnalysis_Start IN RM.RM_ANAL%TYPE  DEFAULT ''
      ,sFilterBy IN VARCHAR2 
      ,sOp IN VARCHAR2
      ,Debug_Y_OR_N IN VARCHAR2 DEFAULT 'N'
      ,SaveFreightFile_Y_OR_N IN VARCHAR2 DEFAULT 'N'
      ,SaveStorageFile_Y_OR_N IN VARCHAR2 DEFAULT 'N'
		)
	AS
		nCheckpoint  NUMBER;
		sFileName VARCHAR2(560);
		v_time_taken VARCHAR2(205);
		l_start number default dbms_utility.get_time;
		v_query2 VARCHAR2(32767);
		--tst_pick_counts tst_tmp_Admin_Data_Pick_Counts;
		sFileSuffix VARCHAR2(60):= '.csv';
		sFileTime VARCHAR2(56)  := TO_CHAR(SYSDATE,'YYYYMMDD HH24MISS');
		sPath VARCHAR2(60) :=  'EOM_ADMIN_ORDERS';
		v_query VARCHAR2(2000);
		v_query_logfile VARCHAR2(22);
		v_query_result2 VARCHAR2(22);
		vRtnVal VARCHAR2(40);
		v_tmp_date VARCHAR2(12) := TO_DATE(end_date, 'DD-MON-YY');     
	BEGIN
		nCheckpoint := 1;
		If (sOp = 'PRJ' or sOp = 'DEV') Then
			v_query  := 'TRUNCATE TABLE "PWIN175"."DEV_ALL_FEES"';
		Else
			v_query  := 'TRUNCATE TABLE "PWIN175"."TMP_ALL_FEES"';
		End If;
		EXECUTE IMMEDIATE v_query;
		sFileName := sCust_start || '-EOM-ADMIN-ORACLE-' || '-RunBy-' || sOp || '-RunOn-' || start_date || '-TO-' || end_date || '-RunAt-' || sFileTime || sFileSuffix;
   
		nCheckpoint := 2;
		If (sOp = 'PRJ' or sOp = 'DEV') Then
			v_query  := 'TRUNCATE TABLE Dev_Group_Cust';
		Else
			v_query  := 'TRUNCATE TABLE Tmp_Group_Cust';
		End If;
		EXECUTE IMMEDIATE v_query;
    
    --If (sOp = 'PRJ' or sOp = 'DEV') Then
    --DBMS_OUTPUT.PUT_LINE('1st Need to run Tmp_Group_Cust for' || someVariable || ' as table is empty.' );
    --End If;
		--Select (F_EOM_CHECK_LOG(v_tmp_date ,'Tmp_Group_Cust','A_TEMP_CUST_DATA')) INTO v_query_logfile From Dual;--v_query := q'{Select EOM_REPORT_PKG_TEST.EOM_CHECK_LOG(TO_CHAR(end_date,'DD-MON-YY') ,'TMP_ALL_FREIGHT_ALL','F_EOM_TMP_ALL_FREIGHT_ALL') }';--q'{INSERT INTO TMP_EOM_LOGS VALUES (SYSTIMESTAMP ,:startdate,:enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','NONE','TMP_ALL_FREIGHT_ALL',:v_time_taken,SYSTIMESTAMP )  }';
		--If UPPER(v_query_logfile) != UPPER(v_tmp_date) Then
    
    If (sOp = 'PRJ' or sOp = 'DEV') Then
      If F_IS_TABLE_EEMPTY('Dev_Group_Cust') <= 0 Then
        DBMS_OUTPUT.PUT_LINE('1st Need to run Tmp_Group_Cust for all customers as table is empty.' );
        A_TEMP_CUST_DATA(sOp);
      Else
        DBMS_OUTPUT.PUT_LINE('1st No Need to run Tmp_Group_Cust for all customers as table is full of data - saved another 5 seconds.' );
      End If;
    Else
      If F_IS_TABLE_EEMPTY('Tmp_Group_Cust') <= 0 Then
        --DBMS_OUTPUT.PUT_LINE('1st Need to run Tmp_Group_Cust for all customers as table is empty.' );
        A_TEMP_CUST_DATA(sOp);
        --Else
        --DBMS_OUTPUT.PUT_LINE('1st No Need to run Tmp_Group_Cust for all customers as table is full of data - saved another 5 seconds.' );
      End If;
    End If;
		nCheckpoint := 3;
		--v_query := q'{SELECT TO_CHAR(LAST_ANALYZED, 'DD-MON-YY') FROM DBA_TABLES WHERE TABLE_NAME = 'TMP_ADMIN_DATA_PICK_LINECOUNTS'}';
		--EXECUTE IMMEDIATE v_query INTO vRtnVal;-- USING sCustomerCode;
		--If F_IS_TABLE_EEMPTY('TMP_ADMIN_DATA_PICK_LINECOUNTS') <= 0 Then
    If (sOp = 'PRJ' or sOp = 'DEV') Then
      Select (F_EOM_CHECK_LOG(v_tmp_date ,'DEV_ADMIN_DATA_PICK_LINECOUNTS','B_EOM_START_RUN_ONCE_DATA',sOp)) INTO v_query_logfile From Dual;--v_query := q'{Select EOM_REPORT_PKG_TEST.EOM_CHECK_LOG(TO_CHAR(end_date,'DD-MON-YY') ,'TMP_ALL_FREIGHT_ALL','F_EOM_TMP_ALL_FREIGHT_ALL') }';--q'{INSERT INTO TMP_EOM_LOGS VALUES (SYSTIMESTAMP ,:startdate,:enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','NONE','TMP_ALL_FREIGHT_ALL',:v_time_taken,SYSTIMESTAMP )  }';
      If F_IS_TABLE_EEMPTY('DEV_ADMIN_DATA_PICK_LINECOUNTS') <= 0 Then
        		
        DBMS_OUTPUT.PUT_LINE('2nd Need to RUN_ONCE TMP_ADMIN_DATA_PICK_LINECOUNTS as B_EOM_START_RUN_ONCE_DATA for all customers as table is empty. result was ' || UPPER(v_query_logfile) || ' and end date was ' ||  UPPER(v_tmp_date) );
        B_EOM_START_RUN_ONCE_DATA(start_date,end_date,sOp);
      ELSIf UPPER(v_query_logfile) != UPPER(v_tmp_date) Then
        -- If vRtnVal != TO_CHAR(SYSDATE, 'DD-MON-YY') Then
        --DBMS_OUTPUT.PUT_LINE('2nd Need to RUN_ONCE TMP_ADMIN_DATA_PICK_LINECOUNTS as B_EOM_START_RUN_ONCE_DATA for all customers as table is empty. result was ' || UPPER(v_query_logfile) || ' and end date was ' ||  UPPER(v_tmp_date) );
        B_EOM_START_RUN_ONCE_DATA(start_date,end_date,sOp);
        --Else
        --DBMS_OUTPUT.PUT_LINE('2nd No Need to RUN_ONCE TMP_ADMIN_DATA_PICK_LINECOUNTS as B_EOM_START_RUN_ONCE_DATA for all customers as table is full of data - saved another 45 seconds. Last Date match was ' || UPPER(v_query_logfile) || ' and end date was ' ||  UPPER(v_tmp_date) );
      End If;
    Else
      Select (F_EOM_CHECK_LOG(v_tmp_date ,'TMP_ADMIN_DATA_PICK_LINECOUNTS','B_EOM_START_RUN_ONCE_DATA',sOp)) INTO v_query_logfile From Dual;--v_query := q'{Select EOM_REPORT_PKG_TEST.EOM_CHECK_LOG(TO_CHAR(end_date,'DD-MON-YY') ,'TMP_ALL_FREIGHT_ALL','F_EOM_TMP_ALL_FREIGHT_ALL') }';--q'{INSERT INTO TMP_EOM_LOGS VALUES (SYSTIMESTAMP ,:startdate,:enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','NONE','TMP_ALL_FREIGHT_ALL',:v_time_taken,SYSTIMESTAMP )  }';
      If F_IS_TABLE_EEMPTY('TMP_ADMIN_DATA_PICK_LINECOUNTS') <= 0 Then
        --DBMS_OUTPUT.PUT_LINE('2nd Need to RUN_ONCE TMP_ADMIN_DATA_PICK_LINECOUNTS as B_EOM_START_RUN_ONCE_DATA for all customers as table is empty. result was ' || UPPER(v_query_logfile) || ' and end date was ' ||  UPPER(v_tmp_date) );
        B_EOM_START_RUN_ONCE_DATA(start_date,end_date,sOp);
      ELSIf UPPER(v_query_logfile) != UPPER(v_tmp_date) Then
        -- If vRtnVal != TO_CHAR(SYSDATE, 'DD-MON-YY') Then
        --DBMS_OUTPUT.PUT_LINE('2nd Need to RUN_ONCE TMP_ADMIN_DATA_PICK_LINECOUNTS as B_EOM_START_RUN_ONCE_DATA for all customers as table is empty. result was ' || UPPER(v_query_logfile) || ' and end date was ' ||  UPPER(v_tmp_date) );
        B_EOM_START_RUN_ONCE_DATA(start_date,end_date,sOp);
        --Else
        --DBMS_OUTPUT.PUT_LINE('2nd No Need to RUN_ONCE TMP_ADMIN_DATA_PICK_LINECOUNTS as B_EOM_START_RUN_ONCE_DATA for all customers as table is full of data - saved another 45 seconds. Last Date match was ' || UPPER(v_query_logfile) || ' and end date was ' ||  UPPER(v_tmp_date) );
      End If;
    End If;
		nCheckpoint := 4;
		--set timing on; Tmp_Locn_Cnt_By_Cust
		-- If F_IS_TABLE_EEMPTY('Tmp_Locn_Cnt_By_Cust') <= 0 Then
		-- Select (F_EOM_CHECK_LOG(v_tmp_date ,'Tmp_Locn_Cnt_By_Cust','C_EOM_START_ALL_TEMP_STOR_DATA')) INTO v_query_logfile From Dual;--v_query := q'{Select EOM_REPORT_PKG_TEST.EOM_CHECK_LOG(TO_CHAR(end_date,'DD-MON-YY') ,'TMP_ALL_FREIGHT_ALL','F_EOM_TMP_ALL_FREIGHT_ALL') }';--q'{INSERT INTO TMP_EOM_LOGS VALUES (SYSTIMESTAMP ,:startdate,:enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','NONE','TMP_ALL_FREIGHT_ALL',:v_time_taken,SYSTIMESTAMP )  }';
		--If UPPER(v_query_logfile) != UPPER(v_tmp_date) OR F_IS_TABLE_EEMPTY('Tmp_Locn_Cnt_By_Cust') <= 0 Then
		--DBMS_OUTPUT.PUT_LINE('3rd Need to RUN_ONCE Tmp_Locn_Cnt_By_Cust as C_EOM_START_ALL_TEMP_STOR_DATA for all customers as table is empty.result was ' || UPPER(v_query_logfile) || ' and end date was ' ||  UPPER(v_tmp_date) );
		--EOM_REPORT_PKG_TEST.C_EOM_START_CUST_TEMP_DATA(sAnalysis_Start,sCust_start);
    If (sOp = 'PRJ' or sOp = 'DEV') Then
      DBMS_OUTPUT.PUT_LINE('Running C_EOM_START_ALL_TEMP_STOR_DATA , date from is  ' || start_date || ' and to date is ' || end_date || ' and customer is ' || sCust_start  || '.');
    End If;
    C_EOM_START_ALL_TEMP_STOR_DATA(sAnalysis_Start,sCust_start,sOp);
		-- Else
		--DBMS_OUTPUT.PUT_LINE('3rd No Need to RUN_ONCE Tmp_Locn_Cnt_By_Cust as C_EOM_START_ALL_TEMP_STOR_DATA for all customers as table is full of data - saved another 65 seconds. Last Date match was ' || UPPER(v_query_logfile) || ' and end date was ' ||  UPPER(v_tmp_date) );
		--End If;
    
		--nCheckpoint := 45;
		--DBMS_OUTPUT.PUT_LINE('4th EOM Customer Rates are caluclated on the fly...' );
    
		nCheckpoint := 5;
		--  SELECT F_EOM_PROCESS_RUN_CHECK(TO_DATE(end_date, 'DD-MON-YY'),'TMP_ALL_FREIGHT_ALL','F_EOM_TMP_ALL_FREIGHT_ALL','') INTO v_query_logfile FROM DUAL;
		--  SELECT F_EOM_PROCESS_RUN_CHECK(TO_DATE(end_date, 'DD-MON-YY'),'TMP_ALL_FREIGHT_ALL','F_EOM_TMP_ALL_FREIGHT_ALL',sCust_start)INTO v_query_result2 FROM DUAL;
		--If v_query_logfile = 'RUNBOTH' Then
    if ( sCust_start = 'BPAUST' ) Then
      F_EOM_TMP_COST_MU_FREIGHT_ALL(p_array_size_start,start_date,end_date,sOp);
    else
      F_EOM_TMP_ALL_FREIGHT_ALL(p_array_size_start,start_date,end_date,sOp);
    end if;
		F8_Z_EOM_RUN_FREIGHT(p_array_size_start,start_date,end_date,sCust_start,sFilterBy,sOp,Debug_Y_OR_N,SaveFreightFile_Y_OR_N); 
		--DBMS_OUTPUT.PUT_LINE('Running F_EOM_PROCESS_RUN_CHECK for ALL based on to date from EOM logs - v_query_logfile is ' || v_query_logfile || '- for end date being ' || TO_DATE(end_date, 'DD-MON-YY') || ' and process was F_EOM_TMP_ALL_FREIGHT_ALL' );
   
		--ElsIf v_query_result2  = 'RUNCUST' Then
		--IQ_EOM_REPORTING.F_EOM_TMP_ALL_FREIGHT_ALL(p_array_size_start,start_date,end_date);
		--IQ_EOM_REPORTING.F8_Z_EOM_RUN_FREIGHT(p_array_size_start,start_date,end_date,sCust_start,sFilterBy); 
		--DBMS_OUTPUT.PUT_LINE('Running F_EOM_PROCESS_RUN_CHECK for CUST based on to date from EOM logs - v_query_result2 is ' || v_query_result2 || '- for end date being ' || TO_DATE(end_date, 'DD-MON-YY') || ' and process was F_EOM_TMP_ALL_FREIGHT_ALL' );
		--ElsIf (F_EOM_PROCESS_RUN_CHECK(TO_DATE(end_date, 'DD-MON-YY'),'TMP_ALL_FREIGHT_F','F8_Z_EOM_RUN_FREIGHT',sCust_start) = 'RUNCUST') Then
		--   IQ_EOM_REPORTING.F8_Z_EOM_RUN_FREIGHT(p_array_size_start,start_date,end_date,sCust_start,sFilterBy);
		--   DBMS_OUTPUT.PUT_LINE('Running F_EOM_PROCESS_RUN_CHECK cust data for customer ' || sCust_start || ' for end date being ' || TO_DATE(end_date, 'DD-MON-YY') || ' and process was F_EOM_TMP_ALL_FREIGHT_ALL' );
		--Else
		--DBMS_OUTPUT.PUT_LINE('Running F_EOM_PROCESS_RUN_CHECK freight nothing - v_query_result2 is ' || v_query_result2 || ' and v_query_logfile is ' || v_query_logfile || '' );
		--End If;  
     
		nCheckpoint := 6;
		-- SELECT F_EOM_PROCESS_RUN_CHECK(TO_DATE(end_date, 'DD-MON-YY'),'TMP_STOR_ALL_FEES','H_STOR_FEES_A','') INTO v_query_logfile FROM DUAL;
		-- SELECT F_EOM_PROCESS_RUN_CHECK(TO_DATE(end_date, 'DD-MON-YY'),'TMP_STOR_ALL_FEES','H_STOR_FEES_A',sCust_start)INTO v_query_result2 FROM DUAL;
		--If v_query_logfile = 'RUNBOTH' Then
    If (sOp = 'PRJ' or sOp = 'PAUL') Then
      DBMS_OUTPUT.PUT_LINE('Running H_STOR_FEES_A , date from is  ' || start_date || ' and to date is ' || end_date || ' and customer is ' || sCust_start  || '.');
    End If;
		H_STOR_FEES_A(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start,sOp);
		H_STOR_FEES_B(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start,sFilterBy,sOp,Debug_Y_OR_N,SaveStorageFile_Y_OR_N);
		DBMS_OUTPUT.PUT_LINE('Running F_EOM_PROCESS_RUN_CHECK for ALL based on to date from EOM logs - v_query_logfile is ' || 
    v_query_logfile || '- for end date being ' || TO_DATE(end_date, 'DD-MON-YY') || 'sCust_start was ' || sCust_start || ' and sAnalysis_Start was ' || sAnalysis_Start ||
    ' and process was H_STOR_FEES_A' );
		--ElsIf v_query_result2 = 'RUNCUST' Then
		-- IQ_EOM_REPORTING.H_STOR_FEES_B(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start,sFilterBy);
		-- DBMS_OUTPUT.PUT_LINE('Running F_EOM_PROCESS_RUN_CHECK for CUST based on to date from EOM logs - v_query_result2 is ' || v_query_result2 || '-  for end date being ' || TO_DATE(end_date, 'DD-MON-YY') || ' and process was H_STOR_FEES_A' );
		-- Else
		-- DBMS_OUTPUT.PUT_LINE('Running F_EOM_PROCESS_RUN_CHECK storage nothing' || 'v_query_result2 is ' || v_query_result2 || '-- v_query_logfile is ' || v_query_logfile || '-' );
		-- End If;
        
		nCheckpoint := 71; --E0_ALL_ORD_FEES
    If (sOp = 'PRJ' or sOp = 'DEV') Then
      DBMS_OUTPUT.PUT_LINE('Running E0_ALL_ORD_FEES , date from is  ' || start_date || ' and to date is ' || end_date || ' and customer is ' || sCust_start  || '.');
    End If;    
		E0_ALL_ORD_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start,sFilterBy,sOp,Debug_Y_OR_N);
      
		/*IQ_EOM_REPORTING.E1_PHONE_ORD_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
		  nCheckpoint := 72;
		  IQ_EOM_REPORTING.E2_EMAIL_ORD_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
		  nCheckpoint := 73;
		  IQ_EOM_REPORTING.E3_FAX_ORD_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start);
		*/  
		nCheckpoint := 74;
    If (sOp = 'PRJ' or sOp = 'DEV') Then
      DBMS_OUTPUT.PUT_LINE('Running E4_STD_ORD_FEES , date from is  ' || start_date || ' and to date is ' || end_date || ' and customer is ' || sCust_start  || '.');
    End If;     
		E4_STD_ORD_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start,sFilterBy,sOp,Debug_Y_OR_N);

		nCheckpoint := 75;
    If (sOp = 'PRJ' or sOp = 'DEV') Then
      DBMS_OUTPUT.PUT_LINE('Running E5_DESTOY_ORD_FEES , date from is  ' || start_date || ' and to date is ' || end_date || ' and customer is ' || sCust_start  || '.');
    End If;  
		E5_DESTOY_ORD_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start,sFilterBy,sOp);

		nCheckpoint := 81;
    If (sOp = 'PRJ' or sOp = 'DEV') Then
      DBMS_OUTPUT.PUT_LINE('Running G1_SHRINKWRAP_FEES , date from is  ' || start_date || ' and to date is ' || end_date || ' and customer is ' || sCust_start  || '.');
    End If;
		G1_SHRINKWRAP_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start,sFilterBy,sOp);
		nCheckpoint := 82;
     If (sOp = 'PRJ' or sOp = 'DEV') Then
      DBMS_OUTPUT.PUT_LINE('Running G2_STOCK_FEES , date from is  ' || start_date || ' and to date is ' || end_date || ' and customer is ' || sCust_start  || '.');
    End If;   
		G2_STOCK_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start,sFilterBy,sOp);
		--nCheckpoint := 83;
		--IQ_EOM_REPORTING.G3_PACKING_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start,sFilterBy);
      
      
		nCheckpoint := 84;
    If (sOp = 'PRJ' or sOp = 'DEV') Then
  
      Select (F_EOM_CHECK_CUST_LOG(sCust_start ,'DEV_HANDLING_FEES','G4_HANDLING_FEES_F',sOp)) INTO v_query_result2 From Dual;
      Select (F_EOM_CHECK_LOG(v_tmp_date ,'DEV_HANDLING_FEES','G4_HANDLING_FEES_F',sOp)) INTO v_query_logfile From Dual;
    Else
       Select (F_EOM_CHECK_CUST_LOG(sCust_start ,'TMP_HANDLING_FEES','G4_HANDLING_FEES_F',sOp)) INTO v_query_result2 From Dual;
       Select (F_EOM_CHECK_LOG(v_tmp_date ,'TMP_HANDLING_FEES','G4_HANDLING_FEES_F',sOp)) INTO v_query_logfile From Dual;
    End If;
    If (sOp = 'PRJ' or sOp = 'DEV') Then
      If F_IS_TABLE_EEMPTY('DEV_HANDLING_FEES') <= 0 Then
       If (sOp = 'PRJ' or sOp = 'DEV') Then
        DBMS_OUTPUT.PUT_LINE('Running DEV_HANDLING_FEES , date from is  ' || start_date || ' and to date is ' || end_date || ' and customer is ' || sCust_start  || '.');
      End If;  
        --DBMS_OUTPUT.PUT_LINE('7th Need to RUN_ONCE G4_HANDLING_FEES_F for all customers as table is empty. result was ' || UPPER(v_query_result2) 
        --|| ' and this cust was ' ||  UPPER(sCust_start)
        --|| ' and to date was ' ||  UPPER(v_query_logfile)
        --|| ' and this date was ' ||  UPPER(v_tmp_date) 
        -- );
        G4_HANDLING_FEES_F(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start,sFilterBy,sOp);
      ELSIf UPPER(v_query_result2) != UPPER(sCust_start) 
      AND UPPER(v_query_logfile) IS NOT NULL 
      AND UPPER(v_query_logfile) != UPPER(v_tmp_date) Then
        --DBMS_OUTPUT.PUT_LINE('7th Need to RUN_ONCE G4_HANDLING_FEES_F for all customers as table is not empty. result was ' || UPPER(v_query_result2) 
        -- || ' and this cust was ' ||  UPPER(sCust_start)
        -- || ' and to date was ' ||  UPPER(v_query_logfile)
        -- || ' and this date was ' ||  UPPER(v_tmp_date) 
        -- );
        G4_HANDLING_FEES_F(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start,sFilterBy,sOp);
        --ELSIF  UPPER(v_query_result2) = UPPER(sCust_start) 
        --AND UPPER(v_query_result2) IS NOT NULL 
        --AND UPPER(v_query_logfile) = UPPER(v_tmp_date) Then
        --DBMS_OUTPUT.PUT_LINE('7th No Need to RUN_ONCE G4_HANDLING_FEES_F for all customers as table is not empty. Last Cust match was ' ||  UPPER(v_query_result2) 
        -- || ' and this cust was ' ||  UPPER(sCust_start)
        -- || ' and to date was ' ||  UPPER(v_query_logfile)
        -- || ' and this date was ' ||  UPPER(v_tmp_date) 
        -- );
      ELSIf UPPER(v_query_result2) IS NULL 
      OR UPPER(v_query_logfile) IS NULL Then
        --DBMS_OUTPUT.PUT_LINE('7th Need to RUN_ONCE G4_HANDLING_FEES_F for all customers as LOGFILE is missing. result was ' || UPPER(v_query_result2) 
        -- || ' and this cust was ' ||  UPPER(sCust_start)
        -- || ' and to date was ' ||  UPPER(v_query_logfile)
        -- || ' and this date was ' ||  UPPER(v_tmp_date) 
        -- );
        G4_HANDLING_FEES_F(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start,sFilterBy,sOp);
      Else
        G4_HANDLING_FEES_F(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start,sFilterBy,sOp);
        --DBMS_OUTPUT.PUT_LINE('7th No matches for running G4_HANDLING_FEES_F, ran it just in case still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
        -- ' Seconds...for customer ' || sCust_start);
      END IF;
    Else
       If F_IS_TABLE_EEMPTY('TMP_HANDLING_FEES') <= 0 Then
        --DBMS_OUTPUT.PUT_LINE('7th Need to RUN_ONCE G4_HANDLING_FEES_F for all customers as table is empty. result was ' || UPPER(v_query_result2) 
        --|| ' and this cust was ' ||  UPPER(sCust_start)
        --|| ' and to date was ' ||  UPPER(v_query_logfile)
        --|| ' and this date was ' ||  UPPER(v_tmp_date) 
        -- );
        G4_HANDLING_FEES_F(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start,sFilterBy,sOp);
      ELSIf UPPER(v_query_result2) != UPPER(sCust_start) 
      AND UPPER(v_query_logfile) IS NOT NULL 
      AND UPPER(v_query_logfile) != UPPER(v_tmp_date) Then
        --DBMS_OUTPUT.PUT_LINE('7th Need to RUN_ONCE G4_HANDLING_FEES_F for all customers as table is not empty. result was ' || UPPER(v_query_result2) 
        -- || ' and this cust was ' ||  UPPER(sCust_start)
        -- || ' and to date was ' ||  UPPER(v_query_logfile)
        -- || ' and this date was ' ||  UPPER(v_tmp_date) 
        -- );
        G4_HANDLING_FEES_F(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start,sFilterBy,sOp);
        --ELSIF  UPPER(v_query_result2) = UPPER(sCust_start) 
        --AND UPPER(v_query_result2) IS NOT NULL 
        --AND UPPER(v_query_logfile) = UPPER(v_tmp_date) Then
        --DBMS_OUTPUT.PUT_LINE('7th No Need to RUN_ONCE G4_HANDLING_FEES_F for all customers as table is not empty. Last Cust match was ' ||  UPPER(v_query_result2) 
        -- || ' and this cust was ' ||  UPPER(sCust_start)
        -- || ' and to date was ' ||  UPPER(v_query_logfile)
        -- || ' and this date was ' ||  UPPER(v_tmp_date) 
        -- );
      ELSIf UPPER(v_query_result2) IS NULL 
      OR UPPER(v_query_logfile) IS NULL Then
        --DBMS_OUTPUT.PUT_LINE('7th Need to RUN_ONCE G4_HANDLING_FEES_F for all customers as LOGFILE is missing. result was ' || UPPER(v_query_result2) 
        -- || ' and this cust was ' ||  UPPER(sCust_start)
        -- || ' and to date was ' ||  UPPER(v_query_logfile)
        -- || ' and this date was ' ||  UPPER(v_tmp_date) 
        -- );
        G4_HANDLING_FEES_F(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start,sFilterBy,sOp);
      Else
        G4_HANDLING_FEES_F(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start,sFilterBy,sOp);
        --DBMS_OUTPUT.PUT_LINE('7th No matches for running G4_HANDLING_FEES_F, ran it just in case still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
        -- ' Seconds...for customer ' || sCust_start);
      END IF;

    End If;
      
		nCheckpoint := 85;
    If (sOp = 'PRJ' or sOp = 'DEV') Then
      Select (F_EOM_CHECK_CUST_LOG(sCust_start ,'DEV_PICK_FEES','G5_PICK_FEES_F',sOp)) INTO v_query_result2 From Dual;--v_query := q'{Select IQ_EOM_REPORTING.EOM_CHECK_LOG(TO_CHAR(end_date,'DD-MON-YY') ,'TMP_ALL_FREIGHT_ALL','F_EOM_TMP_ALL_FREIGHT_ALL') }';--q'{INSERT INTO TMP_EOM_LOGS VALUES (SYSTIMESTAMP ,:startdate,:enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','NONE','TMP_ALL_FREIGHT_ALL',:v_time_taken,SYSTIMESTAMP )  }';
      Select (F_EOM_CHECK_LOG(v_tmp_date ,'DEV_PICK_FEES','G5_PICK_FEES_F',sOp)) INTO v_query_logfile From Dual;
      If F_IS_TABLE_EEMPTY('DEV_PICK_FEES') <= 0 Then
        --DBMS_OUTPUT.PUT_LINE('8th Need to RUN_ONCE G5_PICK_FEES_F for all customers as table is  empty. cust result was ' || UPPER(v_query_result2) 
        -- || ' and this cust was ' ||  UPPER(sCust_start)
        -- || ' and to date was ' ||  UPPER(v_query_logfile)
        -- || ' and this date was ' ||  UPPER(v_tmp_date)
        --  );
        
      If (sOp = 'PRJ' or sOp = 'DEV') Then
        DBMS_OUTPUT.PUT_LINE('Running G5_PICK_FEES_F , date from is  ' || start_date || ' and to date is ' || end_date || ' and customer is ' || sCust_start  || '.');
      End If;  
        
        G5_PICK_FEES_F(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start,sFilterBy,sOp);
      ELSIf UPPER(v_query_result2) != UPPER(sCust_start) 
      AND UPPER(v_query_result2) IS NOT NULL 
      AND UPPER(v_query_logfile) != UPPER(v_tmp_date) Then
        --DBMS_OUTPUT.PUT_LINE('8th Need to RUN_ONCE G5_PICK_FEES_F for all customers as table is not empty. cust result was ' || UPPER(v_query_result2) 
        --|| ' and this cust was ' ||  UPPER(sCust_start)
        -- || ' and to date was ' ||  UPPER(v_query_logfile)
        -- || ' and this date was ' ||  UPPER(v_tmp_date)
        -- );
        G5_PICK_FEES_F(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start,sFilterBy,sOp);
        --ELSIF UPPER(v_query_result2) = UPPER(sCust_start) 
        --AND UPPER(v_query_result2) IS NOT NULL 
        --AND UPPER(v_query_logfile) = UPPER(v_tmp_date) Then
        --DBMS_OUTPUT.PUT_LINE('8th No Need to RUN_ONCE G5_PICK_FEES_F for all customers as table is not empty. Last Cust match was ' ||  UPPER(v_query_result2) 
        -- || ' and this cust was ' ||  UPPER(sCust_start)
        -- || ' and to date was ' ||  UPPER(v_query_logfile)
        -- || ' and this date was ' ||  UPPER(v_tmp_date)
        -- );
      ELSIf UPPER(v_query_result2) IS NULL 
      OR UPPER(v_query_logfile) IS NULL Then
        --DBMS_OUTPUT.PUT_LINE('8th Need to RUN_ONCE G5_PICK_FEES_F for all customers as LOGFILE is missing. cust result was ' || UPPER(v_query_result2) 
        --|| ' and this cust was ' ||  UPPER(sCust_start)
        -- || ' and to date was ' ||  UPPER(v_query_logfile)
        --|| ' and this date was ' ||  UPPER(v_tmp_date)
        -- );
        G5_PICK_FEES_F(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start,sFilterBy,sOp);
      Else
        G5_PICK_FEES_F(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start,sFilterBy,sOp);
        --DBMS_OUTPUT.PUT_LINE('8th No matches for running G5_PICK_FEES_F, ran it just in case still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
        --' Seconds...for customer ' || sCust_start);
      END IF;
    Else
      Select (F_EOM_CHECK_CUST_LOG(sCust_start ,'TMP_PICK_FEES','G5_PICK_FEES_F',sOp)) INTO v_query_result2 From Dual;--v_query := q'{Select IQ_EOM_REPORTING.EOM_CHECK_LOG(TO_CHAR(end_date,'DD-MON-YY') ,'TMP_ALL_FREIGHT_ALL','F_EOM_TMP_ALL_FREIGHT_ALL') }';--q'{INSERT INTO TMP_EOM_LOGS VALUES (SYSTIMESTAMP ,:startdate,:enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','NONE','TMP_ALL_FREIGHT_ALL',:v_time_taken,SYSTIMESTAMP )  }';
      Select (F_EOM_CHECK_LOG(v_tmp_date ,'TMP_PICK_FEES','G5_PICK_FEES_F',sOp)) INTO v_query_logfile From Dual;
      If F_IS_TABLE_EEMPTY('TMP_PICK_FEES') <= 0 Then
        --DBMS_OUTPUT.PUT_LINE('8th Need to RUN_ONCE G5_PICK_FEES_F for all customers as table is  empty. cust result was ' || UPPER(v_query_result2) 
        -- || ' and this cust was ' ||  UPPER(sCust_start)
        -- || ' and to date was ' ||  UPPER(v_query_logfile)
        -- || ' and this date was ' ||  UPPER(v_tmp_date)
        --  );
        G5_PICK_FEES_F(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start,sFilterBy,sOp);
      ELSIf UPPER(v_query_result2) != UPPER(sCust_start) 
      AND UPPER(v_query_result2) IS NOT NULL 
      AND UPPER(v_query_logfile) != UPPER(v_tmp_date) Then
        --DBMS_OUTPUT.PUT_LINE('8th Need to RUN_ONCE G5_PICK_FEES_F for all customers as table is not empty. cust result was ' || UPPER(v_query_result2) 
        --|| ' and this cust was ' ||  UPPER(sCust_start)
        -- || ' and to date was ' ||  UPPER(v_query_logfile)
        -- || ' and this date was ' ||  UPPER(v_tmp_date)
        -- );
        G5_PICK_FEES_F(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start,sFilterBy,sOp);
        --ELSIF UPPER(v_query_result2) = UPPER(sCust_start) 
        --AND UPPER(v_query_result2) IS NOT NULL 
        --AND UPPER(v_query_logfile) = UPPER(v_tmp_date) Then
        --DBMS_OUTPUT.PUT_LINE('8th No Need to RUN_ONCE G5_PICK_FEES_F for all customers as table is not empty. Last Cust match was ' ||  UPPER(v_query_result2) 
        -- || ' and this cust was ' ||  UPPER(sCust_start)
        -- || ' and to date was ' ||  UPPER(v_query_logfile)
        -- || ' and this date was ' ||  UPPER(v_tmp_date)
        -- );
      ELSIf UPPER(v_query_result2) IS NULL 
      OR UPPER(v_query_logfile) IS NULL Then
        --DBMS_OUTPUT.PUT_LINE('8th Need to RUN_ONCE G5_PICK_FEES_F for all customers as LOGFILE is missing. cust result was ' || UPPER(v_query_result2) 
        --|| ' and this cust was ' ||  UPPER(sCust_start)
        -- || ' and to date was ' ||  UPPER(v_query_logfile)
        --|| ' and this date was ' ||  UPPER(v_tmp_date)
        -- );
        G5_PICK_FEES_F(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start,sFilterBy,sOp);
      Else
        G5_PICK_FEES_F(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start,sFilterBy,sOp);
        --DBMS_OUTPUT.PUT_LINE('8th No matches for running G5_PICK_FEES_F, ran it just in case still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
        --' Seconds...for customer ' || sCust_start);
      END IF;

    End If;
    
		nCheckpoint := 9;
      If (sOp = 'PRJ' or sOp = 'DEV') Then
        DBMS_OUTPUT.PUT_LINE('Running I_EOM_MISC_FEES , date from is  ' || start_date || ' and to date is ' || end_date || ' and customer is ' || sCust_start  || '.');
      End If;  
		I_EOM_MISC_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start,sFilterBy,sOp);

		nCheckpoint := 10;
    If (sOp = 'PRJ' or sOp = 'DEV') Then
      DBMS_OUTPUT.PUT_LINE('Running K1_PAL_DESP_FEES , date from is  ' || start_date || ' and to date is ' || end_date || ' and customer is ' || sCust_start  || '.');
    End If;  
		K1_PAL_DESP_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start,sFilterBy,sOp);
		nCheckpoint := 11;
		If (sOp = 'PRJ' or sOp = 'DEV') Then
      DBMS_OUTPUT.PUT_LINE('Running K2_CTN_IN_FEES , date from is  ' || start_date || ' and to date is ' || end_date || ' and customer is ' || sCust_start  || '.');
    End If;  
		K2_CTN_IN_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start,sFilterBy,sOp);
		nCheckpoint := 12;
		If (sOp = 'PRJ' or sOp = 'DEV') Then
      DBMS_OUTPUT.PUT_LINE('Running K3_PAL_IN_FEES , date from is  ' || start_date || ' and to date is ' || end_date || ' and customer is ' || sCust_start  || '.');
    End If;  
		K3_PAL_IN_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start,sFilterBy,sOp);
		nCheckpoint := 13;
		If (sOp = 'PRJ' or sOp = 'DEV') Then
      DBMS_OUTPUT.PUT_LINE('Running K4_CTN_DESP_FEES , date from is  ' || start_date || ' and to date is ' || end_date || ' and customer is ' || sCust_start  || '.');
    End If;  
		K4_CTN_DESP_FEES(p_array_size_start,start_date,end_date,sCust_start,sAnalysis_Start,sFilterBy,sOp);
    
    If (sOp = 'PRJ' or sOp = 'DEV') Then
			v_query := 'TRUNCATE TABLE DEV_CUSTOMER_FEES';
		Else
			v_query := 'TRUNCATE TABLE TMP_CUSTOMER_FEES';
		End If;
		EXECUTE IMMEDIATE v_query;
		COMMIT;

		If ( sCust_start = 'VHAAUS' ) Then
			nCheckpoint := 14;
			J_EOM_CUSTOMER_FEES_VHA(p_array_size_start,start_date,end_date,sCust_start,sOp);
		ElsIf ( sCust_start = 'BEYONDBL' ) Then
			nCheckpoint := 15;
			J_EOM_CUSTOMER_FEES_BB(p_array_size_start,start_date,end_date,sCust_start,sOp);
		ElsIf ( sCust_start = 'WBC' ) Then
			nCheckpoint := 15;
			J_EOM_CUSTOMER_FEES_WBC(p_array_size_start,start_date,end_date,sCust_start,sOp);
		ElsIf ( sCust_start = 'TABCORP' ) Then
			nCheckpoint := 16;
			J_EOM_CUSTOMER_FEES_TAB(p_array_size_start,start_date,end_date,sCust_start,sOp);
			--ElsIf ( sCust_start = 'IAG' ) Then
			--nCheckpoint := 60;
			--IQ_EOM_REPORTING.Z_EOM_RUN_IAG(p_array_size_start,start_date,end_date,'CGU',sAnalysis_Start);
		End If;

      
		nCheckpoint := 99;
		If (sOp = 'PRJ' or sOp = 'DEV') Then
			v_query := 'TRUNCATE TABLE DEV_ALL_FEES';
		Else
			v_query := 'TRUNCATE TABLE TMP_ALL_FEES';
		End If;
		EXECUTE IMMEDIATE v_query;
		COMMIT;
		Y_EOM_TMP_MERGE_ALL_FEES2(sOp);
    DBMS_OUTPUT.PUT_LINE('TRUNCATE TABLE DEV_ALL_FEES, sOp is ' || sOp );
    
		nCheckpoint := 100;
		If (sOp = 'PRJ' or sOp = 'DEV') Then
			v_query := 'TRUNCATE TABLE DEV_ALL_FEES_F';
		Else
			v_query := 'TRUNCATE TABLE TMP_ALL_FEES_F';
		End If;
		EXECUTE IMMEDIATE v_query;
		COMMIT;
		Y_EOM_TMP_MERGE_ALL_FEES_FINAL(sCust_start,sOp);

		nCheckpoint := 101;
		----DBMS_OUTPUT.PUT_LINE('START Z TMP_ALL_FEES for ' || sFileName|| ' saved in ' || sPath );
		If ( sCust_start = 'V-SUPPAR' ) Then
			nCheckpoint := 151;
			If (sOp = 'PRJ' or sOp = 'DEV') Then
        DBMS_OUTPUT.PUT_LINE('Running J_EOM_CUSTOMER_FEES_SUP , date from is  ' || start_date || ' and to date is ' || end_date || ' and customer is ' || sCust_start  || '.');
      End If;  
		J_EOM_CUSTOMER_FEES_SUP(p_array_size_start,start_date,end_date,sCust_start,sFileName,sOp);
		elsIf ( sCust_start = 'N-AAS' ) Then
			nCheckpoint := 152;
			J_EOM_CUSTOMER_FEES_AAS(p_array_size_start,start_date,end_date,sCust_start,sFileName,sOp);
    Else
			Z1_TMP_ALL_FEES_TO_CSV(sFileName,sOp,Debug_Y_OR_N);
      If (upper(Debug_Y_OR_N) = 'Y') Then
        DBMS_OUTPUT.PUT_LINE('Z EOM Successfully Ran EOM_RUN_ALL for all.' );
      End If;
		End If;
		v_query2 :=  SQL%ROWCOUNT;
		-- --DBMS_OUTPUT.PUT_LINE('Z EOM Successfully Ran EOM_RUN_ALL for ' || sCust_start|| ' in ' ||(round((dbms_utility.get_time-l_start)/100, 2) ||
		--' Seconds...' );
		v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
    If (sOp = 'PRJ' or sOp = 'DEV') Then
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,sysdate,sysdate,'Z_EOM_RUN_ALL','MERGE','DEV',v_time_taken,SYSTIMESTAMP,sCust_start);
		Else
      EOM_REPORT_PKG_TEST.EOM_INSERT_LOG(SYSTIMESTAMP ,sysdate,sysdate,'Z_EOM_RUN_ALL','MERGE','TMP',v_time_taken,SYSTIMESTAMP,sCust_start);
		End If;
    --DBMS_OUTPUT.PUT_LINE('LAST EOM Successfully Ran EOM_RUN_ALL for the date range '
		-- || start_date || ' -- ' || end_date || ' - ' || v_query2 || ' records inserted in ' ||  (round((dbms_utility.get_time-l_start)/100, 6) ||
		-- ' Seconds... for customer '|| sCust_start ));
	COMMIT;
    RETURN;
	EXCEPTION
		WHEN OTHERS THEN
			DBMS_OUTPUT.PUT_LINE('EOM_RUN_ALL failed at checkpoint ' || nCheckpoint || ' with error ' || SQLCODE || ' : ' || SQLERRM);
			RAISE;
	END Z3_EOM_RUN_ALL;

    PROCEDURE EOM_CHECK_LOG (
       v_in_end_date  VARCHAR2
       ,v_in_tbl  VARCHAR2
       ,v_in_process VARCHAR2
       ,sOp IN VARCHAR2
      -- ,gds_src_get_desp_stocks OUT sys_refcursor
      ) AS
       v_query VARCHAR2(500);
       v_time_taken VARCHAR2(205);
      v_query_result VARCHAR2(500);
    BEGIN
      v_query  := q'{Select /*+INDEX(TMP_EOM_LOGS LAST_TOUCHED)*/ TO_DATE From TMP_EOM_LOGS Where DEST_TBL = :v_in_tbl AND ROWNUM <= 1   }';
      --,gds_src_get_desp_stocks OUT sys_refcursor
      EXECUTE IMMEDIATE v_query INTO v_query_result USING v_in_tbl;
      --If v_query_result != v_in_end_date Then
        --DBMS_OUTPUT.PUT_LINE(v_in_process || '_EOM_CHECK_LOG for table ' || v_in_tbl || ' has a different end date data range being '|| v_query_result || ' as such the process ' || v_in_process || ' will need to be rerun with fresh data to match end date of '  || v_in_end_date );   
      --Else
        --DBMS_OUTPUT.PUT_LINE(v_in_process || '_EOM_CHECK_LOG for table ' || v_in_tbl || ' has a the same end date data range being '|| v_query_result || ' as such the process ' || v_in_process || ' will NOT need to be rerun with fresh data - THUS saving up to 2 minutes!' );   
      --End If;
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
     VALUES (v_in_DATETIME,v_in_FROM_DATE,v_in_TO_DATE,v_in_ORIGIN_PROCESS,v_in_ORIGIN_TBL,v_in_DEST_TBL,v_in_TIME_TAKEN,v_in_CUST,v_in_LAST_TOUCH );
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
       ,sOp IN VARCHAR2
       )
    RETURN VARCHAR2
    AS
    v_rtn_val VARCHAR2(200);
    v_time_taken VARCHAR2(205);
    v_rtn_rslt VARCHAR2(200);
    BEGIN
      ----DBMS_OUTPUT.PUT_LINE(' No Table name has been entered, nothing to return??? table was ' || v_in_tbl ); 
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
       ,sOp IN VARCHAR2
       )
    RETURN VARCHAR2
    AS
    v_rtn_val VARCHAR2(200);
    v_time_taken VARCHAR2(205);
    v_rtn_rslt VARCHAR2(200);
    BEGIN
      ----DBMS_OUTPUT.PUT_LINE(' No Table name has been entered, nothing to return??? table was ' || v_in_tbl ); 
      --need to allow for customer based query changes as well as last date range
          Select /*+INDEX(TMP_EOM_LOGS LAST_TOUCHED)*/ CUST --using this field to populate from table with customer code from query
          INTO  v_rtn_rslt
          FROM TMP_EOM_LOGS Where DEST_TBL = v_in_tbl AND ROWNUM <= 1;
          RETURN v_rtn_rslt;
    END F_EOM_CHECK_CUST_LOG;
    
    PROCEDURE Z1_TMP_ALL_FEES_TO_CSV( p_filename in varchar2,sOp IN VARCHAR2,Debug_Y_OR_N IN VARCHAR2 DEFAULT 'N' )
    is
        l_output        utl_file.file_type;
        l_theCursor     integer default dbms_sql.open_cursor;
        l_columnValue   varchar2(4000);
        l_status        integer;
         l_query         varchar2(1000);
       
       l_colCnt        number := 0;
       l_separator     varchar2(1);
       l_descTbl       dbms_sql.desc_tab;
       v_time_taken VARCHAR2(205);
        sPath VARCHAR2(60) :=  'EOM_ADMIN_ORDERS';
        l_start number default dbms_utility.get_time;
   begin
         If (sOp = 'PRJ' or sOp = 'DEV') Then
          l_query  := 'select * from TMP_ALL_FEES_F';
        Else
          l_query  := 'select * from TMP_ALL_FEES_F';
        End IF;
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
       --IQ_EOM_REPORTING.EOM_INSERT_LOG(SYSTIMESTAMP ,sysdate,sysdate,'Z1_TMP_ALL_FEES_TO_CSV','CSV','TMP_ALL_FEES_F',v_time_taken,SYSTIMESTAMP,sCustomerCode);
      If (upper(Debug_Y_OR_N) = 'Y') Then
       DBMS_OUTPUT.PUT_LINE('Z TMP_ALL_FEES for ' || p_filename || ' saved in ' || sPath );
      End If;
    exception
       when others then
           execute immediate 'alter session set nls_date_format=''dd-MON-yy'' ';
      raise;
   end Z1_TMP_ALL_FEES_TO_CSV;
    
    PROCEDURE Z2_TMP_FEES_TO_CSV( p_filename in varchar2, p_in_table in varchar2,sOp IN VARCHAR2  )
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
       --IQ_EOM_REPORTING.EOM_INSERT_LOG(SYSTIMESTAMP ,sysdate,sysdate,'Z2_TMP_FEES_TO_CSV','CSV',p_in_table,v_time_taken,SYSTIMESTAMP,sCustomerCode);
     
       --DBMS_OUTPUT.PUT_LINE('Z2_TMP_FEES_TO_CSV for ' || p_filename || ' saved in ' || sPath || ', data was from ' || p_in_table );
    exception
       when others then
           execute immediate 'alter session set nls_date_format=''dd-MON-yy'' ';
      raise;
   END Z2_TMP_FEES_TO_CSV;
   
     PROCEDURE get_stockonhand_curp (
          gsc_cust_in IN Tmp_Group_Cust.sGroupCust%TYPE,
          gsc_src_get_soh_trans OUT sys_refcursor
          ,sOp IN VARCHAR2
        )
    AS
      nbreakpoint   NUMBER;
    BEGIN
      nbreakpoint := 1;
      OPEN gsc_src_get_soh_trans FOR
      SELECT i.IM_CUST
      , i.IM_STOCK
      ,i.IM_DESC
      ,e.NE_AVAIL_ACTUAL
      , e.NE_QUARANTINED
      ,(SELECT SUM(e2.NE_QUANTITY)
          FROM  NA n2 INNER JOIN NE e2 ON e2.NE_ACCOUNT = n2.NA_ACCOUNT
          WHERE n2.NA_EXT_TYPE = 1210067
          AND e2.NE_QUANTITY < '0'
          AND e2.NE_TRAN_TYPE = 6
          AND n2.NA_STOCK = n.NA_STOCK
          AND e2.NE_STATUS =  4
          AND e2.NE_STRENGTH = 2
         -- AND n2.NA_STOCK = 'SUP10067'
          GROUP BY e2.NE_STOCK) AS "Demand"
      FROM  NA n INNER JOIN IL l ON l.IL_UID = n.NA_EXT_KEY
            INNER JOIN NE e ON e.NE_ACCOUNT = n.NA_ACCOUNT
            INNER JOIN IM i ON i.IM_STOCK = n.NA_STOCK
            --LEFT JOIN Tmp_Group_Cust r ON r.sGroupCust = i.IM_CUST
      WHERE n.NA_EXT_TYPE = 1210067
      AND e.NE_AVAIL_ACTUAL >= '1'
      AND l.IL_IN_LOCN NOT IN ('OBSOLETEMEL','OBSOLETESYD','PASTHISTORY', 'CANBERRA')
      --AND i.IM_STOCK =  'SUP10121'
      AND e.NE_STRENGTH = 3
      AND e.NE_STATUS != 0 AND e.NE_STATUS != 5 
      AND i.IM_CUST = gsc_cust_in --'V-SUPPAR%'
      ORDER BY i.IM_STOCK Asc;
     --GROUP BY IM_STOCK,IM_CUST,NI_TRAN_TYPE,NI_QUANTITY,NI_AVAIL_ACTUAL, NI_QUARANTINED, NI_STOCK,IM_DESC,NI_STRENGTH,NI_STATUS
     
     
     EXCEPTION 
        WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('Stock On Hand query failed at checkpoint ' || nbreakpoint ||
                              ' with error ' || SQLCODE || ' : ' || SQLERRM);
          RAISE;
     END get_stockonhand_curp;
     
     
      FUNCTION total_dmd_by_stock2
        ( gsc_stock_in IN NA.NA_STOCK%TYPE,sOp IN VARCHAR2)
      RETURN NUMBER
      IS
       CURSOR dmd_cur    IS
          SELECT SUM(e.NE_QUANTITY)
          FROM  NA n --INNER JOIN IL l ON l.IL_UID = n.NA_EXT_KEY
                INNER JOIN NE e ON e.NE_ACCOUNT = n.NA_ACCOUNT
                --INNER JOIN IM i ON i.IM_STOCK = n.NA_STOCK
                --LEFT JOIN Tmp_Group_Cust r ON r.sGroupCust = i.IM_CUST
          WHERE n.NA_EXT_TYPE = 1210067
          AND e.NE_QUANTITY < '0'
          AND e.NE_TRAN_TYPE = 6
          AND n.NA_STOCK = gsc_stock_in
          AND e.NE_STATUS =  2 -- 2 for BO live 4 for demand dead
          AND e.NE_STRENGTH = 1 -- 1 for BO 2 for Demand
          GROUP BY e.NE_STOCK;
    
          --Return value for function
          v_rtn_value NUMBER;
      BEGIN
        OPEN dmd_cur;
        FETCH dmd_cur INTO v_rtn_value;
        IF dmd_cur%NOTFOUND
        THEN
          CLOSE dmd_cur;
          RETURN NULL;
        ELSE
          CLOSE dmd_cur;
          RETURN v_rtn_value;
        END IF;
      END total_dmd_by_stock2;
     
     PROCEDURE get_finance_transactions_curp (
			gds_cust_in IN IM.IM_CUST%TYPE,
			gds_src_get_finance_trans OUT sys_refcursor
      ,sOp IN VARCHAR2
)
AS
  nbreakpoint   NUMBER;
BEGIN
  nbreakpoint := 1;
  OPEN gds_src_get_finance_trans FOR
  SELECT DISTINCT IM_CUST, NI_STOCK,NI_DATE
    , CASE
        WHEN NI_TRAN_TYPE = 0 THEN 'ORDER'
        WHEN NI_TRAN_TYPE = 1 THEN 'RECEIPT'
        WHEN NI_TRAN_TYPE = 2 THEN 'STOCKTAKE'
        WHEN NI_TRAN_TYPE = 3 THEN 'ISSUE'
        WHEN NI_TRAN_TYPE = 4 THEN 'TRANSFER'
        WHEN NI_TRAN_TYPE = 5 THEN 'ADJUST'
        WHEN NI_TRAN_TYPE = 6 THEN 'DEMAND'
     END AS TransactionType 
     ,CASE
        WHEN NI_STATUS = 0 THEN 'EXTERNAL'
        WHEN NI_STATUS = 1 THEN 'LIVE POSITIVE'
        WHEN NI_STATUS = 2 THEN 'LIVE NEGATIVE'
        WHEN NI_STATUS = 3 THEN 'DEAD POSITIVE'
        WHEN NI_STATUS = 4 THEN 'LIVE POSITIVE'
        WHEN NI_STATUS = 5 THEN 'REVERSED'
     END AS Status
     ,CASE
        WHEN NI_STRENGTH = 0 THEN 'VOLATILE'
        WHEN NI_STRENGTH = 1 THEN 'TENTATIVE'
        WHEN NI_STRENGTH = 2 THEN 'EXPECTED'
        WHEN NI_STRENGTH = 3 THEN 'ACTUAL'
     END AS Strength,
     CASE
          WHEN IM_OWNED_By = 0 THEN 'COMPANY'
          WHEN IM_OWNED_By = 1 THEN 'CUSTOMER'
      END                       AS "OwnedBy"
     ,NI_QUANTITY,NI_EXT_KEY, NI_LOCN
  FROM NI INNER JOIN IM ON IM_STOCK = NI_STOCK
  INNER JOIN Tmp_Group_Cust r ON r.sGroupCust = IM_CUST
  WHERE r.sGroupCust = gds_cust_in
  AND (NI_STATUS != 5 AND NI_STATUS != 0 AND NI_STATUS != 2)
  AND NI_TRAN_TYPE != 3
  AND IM_ACTIVE = 1;
 EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('LUX Stock query failed at checkpoint ' || nbreakpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
 END get_finance_transactions_curp;
 
 
  PROCEDURE EOM_AUTO_RUN_ALL (
       p_array_size_start IN PLS_INTEGER DEFAULT 100
      ,start_date IN VARCHAR2-- DEFAULT F_GET_FIRST_OF_PREV_MONTH -- or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,end_date IN VARCHAR2-- DEFAULT F_GET_LAST_OF_PREV_MONTH
      ,check_date IN VARCHAR2-- DEFAULT To_Date(CURRENT_DATE)
      ,sCust_start IN VARCHAR2
      ,sAnalysis_Start IN RM.RM_ANAL%TYPE
      ,sFilterBy IN VARCHAR2
      ,sOp IN VARCHAR2
      ,Debug_Y_OR_N  in VARCHAR2
      ,SaveFreightFile_Y_OR_N IN VARCHAR2 DEFAULT 'N'
      ,SaveStorageFile_Y_OR_N IN VARCHAR2 DEFAULT 'N'
  )
  IS
  CURSOR EOM_CUSTS IS
  SELECT RM_CUST FROM RM WHERE RM_XX_EOM_ADMIN = 'ADMIN' AND RM_CUST IN ('MDA','CABS','HOMTIM','VHAAUS');
  i   NUMBER := 0;
  --start_date VARCHAR2(20)    := To_Date(F_GET_FIRST_OF_PREV_MONTH);-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
  --end_date VARCHAR2(20)  := To_Date(F_GET_LAST_OF_PREV_MONTH); -- := To_Date('30-Jun-2015')
  --check_date := To_Date(CURRENT_DATE);
--      ,sCust_start IN VARCHAR2
  --sAnalysis_Start VARCHAR2(20);
  --sFilterBy VARCHAR2(20);
--      ,
  nCheckpoint NUMBER;
  
  BEGIN
      dbms_output.disable();
      nCheckpoint := 1;
      --OPEN EOM_CUSTS;
      --LOOP
      --FETCH EOM_CUSTS BULK COLLECT INTO l_data LIMIT p_array_size;
      ----DBMS_OUTPUT.PUT_LINE(RM_CUST || '.' );
      
      --FORALL i IN 1..l_data.COUNT
      ----DBMS_OUTPUT.PUT_LINE(i || '.' );
      --INSERT INTO TMP_ALL_FEES_F VALUES l_data(i);
      --USING sCust;
      --Z3_EOM_RUN_ALL(p_array_size_start,start_date,end_date,rec.RM_CUST,sAnalysis_Start,sFilterBy);
       
      --EXIT WHEN EOM_CUSTS%NOTFOUND;

      --END LOOP;
     -- --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
      --CLOSE EOM_CUSTS;
       --  FOR i IN l_data.FIRST .. l_data.LAST LOOP
       --   --DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        --END LOOP;
		
     FOR rec IN (SELECT RM_CUST FROM RM WHERE RM_XX_EOM_ADMIN = 'ADMIN' AND RM_CUST NOT IN (Select CUST FROM TMP_EOM_LOGS WHERE ORIGIN_PROCESS = 'Z_EOM_RUN_ALL' AND SubStr(LAST_SUC_FIN,0,9) BETWEEN TO_DATE(CHECK_DATE) - 1  AND TO_DATE(CHECK_DATE) AND CUST IS NOT NULL GROUP BY CUST))
     --('VERO','TYNDALL','CGU','LINK','CNH','PROMINA','COLONIALFS','IAG','V-SUPPAR','LUXOTTICA','BEYONDBL','COL_KMART','AMP','AMEX','AAS'))
     LOOP
        i := i + 1;
        DBMS_OUTPUT.PUT_line ('Running EOM # ' || i || ' cust is  ' || rec.RM_CUST || ' and dates are start ' || start_date  || ' and from ' || end_date || ' .');
        --Now run Z3_EOM_RUN_ALL
        If F_SLOW_DOWN(60) = TRUE THEN
          Z3_EOM_RUN_ALL(p_array_size_start,start_date,end_date,rec.RM_CUST,sAnalysis_Start,sFilterBy,sOp,Debug_Y_OR_N,SaveFreightFile_Y_OR_N,SaveStorageFile_Y_OR_N);
        END IF;
     END LOOP;
     
     --DBMS_OUTPUT.PUT_line ('EOM Auto Run All is done');
     EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EOM Auto Run All failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
        RAISE;
  END EOM_AUTO_RUN_ALL;
  


END IQ_EOM_REPORTING;