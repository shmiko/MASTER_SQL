--------------------------------------------------------
--  File created - Wednesday-July-22-2015   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package EOM_REPORT_PKG_TEST
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "PWIN175"."EOM_REPORT_PKG_TEST" 
IS
     PROCEDURE A_EOM_GROUP_CUST;
     
     PROCEDURE B_EOM_START_RUN_ONCE_DATA(
         start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
     ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
     ,sAnalysis IN RM.RM_ANAL%TYPE
     ,sCust IN RM.RM_CUST%TYPE := 'VHAAUS'
     ,PreData IN RM.RM_ACTIVE%TYPE := 0
       --,gdf_desp_freight_cur OUT sys_refcursor
       );
     
     PROCEDURE C_EOM_START_CUST_TEMP_DATA(
       --start_date IN ST.ST_DESP_DATE%TYPE := '2015-04-06'
       --,end_date IN ST.ST_DESP_DATE%TYPE := '2015-04-13'
       sAnalysis IN RM.RM_ANAL%TYPE
       --,
       ,sCust IN RM.RM_CUST%TYPE := 'VHAAUS'
       --,PreData IN RM.RM_ACTIVE%TYPE := 0
       --,gdf_desp_freight_cur OUT sys_refcursor
       );
    
     PROCEDURE D_EOM_GET_CUST_RATES(
     --start_date IN ST.ST_DESP_DATE%TYPE := '2015-04-06'
     --,end_date IN ST.ST_DESP_DATE%TYPE := '2015-04-13'
     --,sAnalysis IN RM.RM_ANAL%TYPE
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
     ) ;
        
    
     PROCEDURE EOM_TMP_ALL_FREIGHT_ALL_CUST (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,start_date IN VARCHAR2 -- use this when you want the date entered automatically
        ,end_date IN VARCHAR2
        ,sClient IN VARCHAR2,
        sAnalysis IN RM.RM_ANAL%TYPE
       );
       
      
     PROCEDURE EOM_TMP_ALL_FREIGHT_ALL_IC (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
        ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
       ,sCust IN RM.RM_CUST%TYPE,
        sAnalysis IN RM.RM_ANAL%TYPE
        -- sCust IN RM.RM_CUST%TYPE
       );
      
     PROCEDURE EOM_PHONE_ORD_FEES (
     p_array_size IN PLS_INTEGER DEFAULT 100
      -- ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
      -- ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
      --  start_date IN VARCHAR2(20) := '01-Jun-2015'; -- use this format when using ST_DESP_DATE unformatted
      --  end_date IN VARCHAR2(20) := '30-Jun-2015';
     -- ,   start_date IN VARCHAR2 := '2015-06-01' -- use this when ST_DESP_DATE is formatted
       --, end_date IN VARCHAR2 := '2015-06-30'
      ,start_date IN VARCHAR2 := F_FIRST_DAY_PREV_MONTH -- use this when you want the date entered automatically
      ,end_date IN VARCHAR2 := F_LAST_DAY_PREV_MONTH
      ,sCust IN RM.RM_CUST%TYPE
      ,sAnalysis IN RM.RM_ANAL%TYPE
       );
       
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
       );
       
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
       );
       
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
       );
       
       
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
       );
       
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
       );
       
     PROCEDURE EOM_TMP_ALL_ORD_FEES_ALL_IC (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
        ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
       ,sCust IN RM.RM_CUST%TYPE,
        sAnalysis IN RM.RM_ANAL%TYPE
        -- sCust IN RM.RM_CUST%TYPE
       );
      
     PROCEDURE EOM_TMP_ALL_HAND_FEES_ALL_CUST (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
        ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
       ,sCust IN RM.RM_CUST%TYPE,
        sAnalysis IN RM.RM_ANAL%TYPE
        
        -- sCust IN RM.RM_CUST%TYPE
       );
       
     PROCEDURE EOM_TMP_ALL_HAND_FEES_ALL_IC (
          p_array_size IN PLS_INTEGER DEFAULT 100
          ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
        ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
       ,sCust IN RM.RM_CUST%TYPE,
          sAnalysis IN RM.RM_ANAL%TYPE
          
          -- sCust IN RM.RM_CUST%TYPE
        );
      
     PROCEDURE EOM_TMP_ALL_STOR_FEES_ALL_CUST (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
        ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
        ,sCust IN RM.RM_CUST%TYPE,
        sAnalysis IN RM.RM_ANAL%TYPE
          
          -- sCust IN RM.RM_CUST%TYPE
        );
        
     PROCEDURE EOM_TMP_ALL_STOR_FEES_ALL_IC (
          p_array_size IN PLS_INTEGER DEFAULT 100
        ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
        ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
        ,sCust IN RM.RM_CUST%TYPE,
          sAnalysis IN RM.RM_ANAL%TYPE
            
            -- sCust IN RM.RM_CUST%TYPE
          );
      
     PROCEDURE EOM_TMP_ALL_MISC_FEES_ALL_CUST (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
        ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
        ,sCust IN RM.RM_CUST%TYPE,
        sAnalysis IN RM.RM_ANAL%TYPE
      );
      
     PROCEDURE EOM_TMP_ALL_MISC_FEES_ALL_IC (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
        ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
        ,sCust IN RM.RM_CUST%TYPE,
        sAnalysis IN RM.RM_ANAL%TYPE
      );
      
     PROCEDURE EOM_TMP_CUSTOMER_FEES (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
        ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
        ,sCust IN RM.RM_CUST%TYPE
        -- sCust IN RM.RM_CUST%TYPE
      );
      
     PROCEDURE EOM_TMP_PAL_CTN_FEES (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
        ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
        , sCust IN RM.RM_CUST%TYPE,
        sAnalysis IN RM.RM_ANAL%TYPE
        -- sCust IN RM.RM_CUST%TYPE
        );
        
     PROCEDURE EOM_TMP_PAL_CTN_FEES_IC (
          p_array_size IN PLS_INTEGER DEFAULT 100
        ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
        ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
        ,sCust IN RM.RM_CUST%TYPE,
          sAnalysis IN RM.RM_ANAL%TYPE
          -- sCust IN RM.RM_CUST%TYPE
          );
      
     PROCEDURE EOM_TMP_CTN_FEES (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
        ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
        ,sCust IN RM.RM_CUST%TYPE,
        sAnalysis IN RM.RM_ANAL%TYPE
          -- sCust IN RM.RM_CUST%TYPE
        );
        
     PROCEDURE EOM_TMP_CTN_FEES_IC (
          p_array_size IN PLS_INTEGER DEFAULT 10
        ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
        ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
        ,sCust IN RM.RM_CUST%TYPE,
          sAnalysis IN RM.RM_ANAL%TYPE
            -- sCust IN RM.RM_CUST%TYPE
          );
      
     PROCEDURE EOM_TMP_MERGE_ALL_FEES (
        p_array_size IN PLS_INTEGER DEFAULT 100
       );
      
     PROCEDURE ZZ_EOM_CUST_QRY_TMP(
          sCust IN RM.RM_CUST%TYPE
         ,sQueryType IN VARCHAR2
         ,src_tmp_qry OUT SYS_REFCURSOR
       );
     
     PROCEDURE Z_EOM_RUN_ALL (
        p_array_size_start IN PLS_INTEGER DEFAULT 100
        ,start_date IN ST.ST_DESP_DATE%TYPE := F_FIRST_DAY_PREV_MONTH--'2015-05-01'
        ,end_date IN ST.ST_DESP_DATE%TYPE := F_LAST_DAY_PREV_MONTH --'2015-05-30'
        ,sCust_start IN RM.RM_CUST%TYPE,
        sAnalysis_Start IN RM.RM_ANAL%TYPE
      );
    
     PROCEDURE EOM_CREATE_TEMP_DATA_LOCATIONS (
        sAnalysis IN RM.RM_ANAL%TYPE
      );
    
     PROCEDURE ZZ_EOM_CUST_QRY_ALL_TMP(
       sCust IN RM.RM_CUST%TYPE
       ,src_tmp_qry OUT SYS_REFCURSOR
     ); 
     
END EOM_REPORT_PKG_TEST;

/
