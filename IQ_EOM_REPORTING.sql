--------------------------------------------------------
--  File created - Tuesday-August-16-2016   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package IQ_EOM_REPORTING
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "PWIN175"."IQ_EOM_REPORTING" AS 

  /* TODO enter package declarations (types, exceptions, methods etc) here */ 
   PROCEDURE A_EOM_GROUP_CUST;
  
   PROCEDURE EOM_INSERT_LOG (
      v_in_DATETIME    IN  DATE          
      ,v_in_FROM_DATE   IN  DATE          
      ,v_in_TO_DATE     IN  DATE          
      ,v_in_ORIGIN_PROCESS   IN     VARCHAR2 
      ,v_in_ORIGIN_TBL       IN     VARCHAR2 
      ,v_in_DEST_TBL         IN     VARCHAR2 
      ,v_in_TIME_TAKEN       IN     VARCHAR2  
      ,v_in_LAST_TOUCH       IN     TIMESTAMP
      ,v_in_CUST              IN     VARCHAR2
      );
   
   PROCEDURE B_EOM_START_RUN_ONCE_DATA(
         start_date IN VARCHAR2
     ,end_date IN VARCHAR2
     ,sAnalysis IN RM.RM_ANAL%TYPE
     ,sCust IN VARCHAR2
     ,PreData IN RM.RM_ACTIVE%TYPE := 0
       --,gdf_desp_freight_cur OUT sys_refcursor
       );
     
   PROCEDURE C_EOM_START_ALL_TEMP_STOR_DATA
    (
     sAnalysis IN RM.RM_ANAL%TYPE
     ,sCust IN RM.RM_CUST%TYPE := 'VHAAUS'
    );
    
   PROCEDURE F_EOM_TMP_ALL_FREIGHT_ALL (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
    );
    
   PROCEDURE F_EOM_TMP_VAN_FREIGHT_ALL (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
        ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
        ,sCustomerCode IN VARCHAR2
        ,sFilterBy IN VARCHAR2
      ); 
   
   PROCEDURE F8_Z_EOM_RUN_FREIGHT (
         p_array_size IN PLS_INTEGER DEFAULT 100
        ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
        ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
        ,sCustomerCode IN VARCHAR2
        ,sFilterBy IN VARCHAR2
        
      );
   
   PROCEDURE H4_EOM_ALL_STOR_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
      ,sAnalysis IN RM.RM_ANAL%TYPE
    );
     
   PROCEDURE H4_EOM_ALL_STOR (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
      ,sAnalysis IN RM.RM_ANAL%TYPE
        ,sFilterBy IN VARCHAR2
    );
   
   PROCEDURE E0_ALL_ORD_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
      ,sAnalysis IN RM.RM_ANAL%TYPE
        ,sFilterBy IN VARCHAR2
    );
    
    PROCEDURE E4_STD_ORD_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
      ,sAnalysis IN RM.RM_ANAL%TYPE
        ,sFilterBy IN VARCHAR2
    );
   
   PROCEDURE E5_DESTOY_ORD_FEES (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
        ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
        ,sCustomerCode IN VARCHAR2
        ,sAnalysis IN RM.RM_ANAL%TYPE
        ,sFilterBy IN VARCHAR2
      );
   
   PROCEDURE G1_SHRINKWRAP_FEES (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
        ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
        ,sCustomerCode IN VARCHAR2
        ,sAnalysis IN RM.RM_ANAL%TYPE
        ,sFilterBy IN VARCHAR2
        
        -- sCust IN RM.RM_CUST%TYPE
       );
   
   PROCEDURE G2_STOCK_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
      ,sAnalysis IN RM.RM_ANAL%TYPE
        ,sFilterBy IN VARCHAR2
      
      -- sCust IN RM.RM_CUST%TYPE
     );
   
   PROCEDURE G2_STOCK_FEES_SD (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
        ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
        ,sCustomerCode IN VARCHAR2
        ,sAnalysis IN RM.RM_ANAL%TYPE
        ,sFilterBy IN VARCHAR2
      );
   
   PROCEDURE G3_PACKING_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
      ,sAnalysis IN RM.RM_ANAL%TYPE
        ,sFilterBy IN VARCHAR2
      
      -- sCust IN RM.RM_CUST%TYPE
     );
 
   PROCEDURE G4_HANDLING_FEES_F (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
      ,sAnalysis IN RM.RM_ANAL%TYPE
        ,sFilterBy IN VARCHAR2
    ); 
    
    PROCEDURE G4_HANDLING_FEES_F2 (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
        ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
        ,sCustomerCode IN VARCHAR2
        ,sAnalysis IN RM.RM_ANAL%TYPE
        ,sFilterBy IN VARCHAR2
      );
   
   PROCEDURE G5_PICK_FEES_F (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
      ,sAnalysis IN RM.RM_ANAL%TYPE
        ,sFilterBy IN VARCHAR2

      -- sCust IN RM.RM_CUST%TYPE
    ); 
   
   PROCEDURE G5_PICK_FEES_F2 (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
      ,sAnalysis IN RM.RM_ANAL%TYPE

      -- sCust IN RM.RM_CUST%TYPE
    );
    
   PROCEDURE I_EOM_MISC_FEES (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
        ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
        ,sCustomerCode IN VARCHAR2
        ,sAnalysis IN RM.RM_ANAL%TYPE
        ,sFilterBy IN VARCHAR2
      );
      
   PROCEDURE J_EOM_CUSTOMER_FEES (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
        ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
        ,sCustomerCode IN VARCHAR2
      );
      
   PROCEDURE J_EOM_CUSTOMER_FEES_TAB (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
    );
    
   PROCEDURE J_EOM_CUSTOMER_FEES_BB (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
    );
   
   PROCEDURE J_EOM_CUSTOMER_FEES_WBC (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
    );
      
   PROCEDURE J_EOM_CUSTOMER_FEES_VHA (
      p_array_size IN PLS_INTEGER DEFAULT 100
      ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2
    ); 
      
   PROCEDURE K1_PAL_DESP_FEES (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2,
        sAnalysis IN RM.RM_ANAL%TYPE
        ,sFilterBy IN VARCHAR2
        -- sCust IN RM.RM_CUST%TYPE
        );
        
   PROCEDURE K2_CTN_IN_FEES (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2,
        sAnalysis IN RM.RM_ANAL%TYPE
        ,sFilterBy IN VARCHAR2
        -- sCust IN RM.RM_CUST%TYPE
        );
        
   PROCEDURE K3_PAL_IN_FEES (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2,
        sAnalysis IN RM.RM_ANAL%TYPE
        ,sFilterBy IN VARCHAR2
        -- sCust IN RM.RM_CUST%TYPE
        );
   
   PROCEDURE K3_ALL_PAL_IN_FEES (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
        ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
        ,sCustomerCode IN VARCHAR2,
        sAnalysis IN RM.RM_ANAL%TYPE
        ,sFilterBy IN VARCHAR2
      );
        
   PROCEDURE K4_CTN_DESP_FEES (
        p_array_size IN PLS_INTEGER DEFAULT 100
        ,startdate IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,enddate IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCustomerCode IN VARCHAR2,
        sAnalysis IN RM.RM_ANAL%TYPE
        ,sFilterBy IN VARCHAR2
          -- sCust IN RM.RM_CUST%TYPE
        );
        
   PROCEDURE L_DESPATCH_REPORT (
          p_array_size IN PLS_INTEGER DEFAULT 100,
          gds_analysis IN  RM.RM_ANAL%TYPE,
          gds_start_date_in IN VARCHAR2,
          gds_end_date_in IN VARCHAR2
    );
   
   PROCEDURE L_DESPATCH_REPORTB (
          p_array_size IN PLS_INTEGER DEFAULT 100,
          gds_analysis IN  RM.RM_ANAL%TYPE,
          gds_start_date_in IN VARCHAR2,
          gds_end_date_in IN VARCHAR2
    );
    
   PROCEDURE Y_EOM_TMP_MERGE_ALL_FEES (
      p_array_size IN PLS_INTEGER DEFAULT 100
    );
    
   PROCEDURE Y_EOM_TMP_MERGE_ALL_FEES2; 
   PROCEDURE Y_EOM_TMP_MERGE_ALL_FEES_FINAL(sCustomerCode IN VARCHAR2);
   
   PROCEDURE EOM_CHECK_LOG (
       v_in_end_date  VARCHAR2
       ,v_in_tbl  VARCHAR2
       ,v_in_process VARCHAR2
      );
      
   FUNCTION F_EOM_CHECK_LOG( 
       v_in_end_date  VARCHAR2
       ,v_in_tbl  VARCHAR2
       ,v_in_process VARCHAR2
       )
    RETURN VARCHAR2;
    
   FUNCTION F_EOM_CHECK_CUST_LOG( 
       v_in_cust  VARCHAR2
       ,v_in_tbl  VARCHAR2
       ,v_in_process VARCHAR2
       )
    RETURN VARCHAR2;
   
   PROCEDURE Z3_EOM_RUN_ALL (
       p_array_size_start IN PLS_INTEGER DEFAULT 100
      ,start_date IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,end_date IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,sCust_start IN VARCHAR2
      ,sAnalysis_Start IN RM.RM_ANAL%TYPE
        ,sFilterBy IN VARCHAR2
      ,sOp IN VARCHAR2
      );
   
   PROCEDURE Z2_TMP_FEES_TO_CSV( p_filename in varchar2, p_in_table in varchar2 );
   
   PROCEDURE Z1_TMP_ALL_FEES_TO_CSV( p_filename in varchar2 );
   --Procedure Find_Droplist_String(FDS_Droplist IN VARCHAR2, FDS_Integer IN NUMBER,p_array_size IN PLS_INTEGER DEFAULT 100);
   
   PROCEDURE get_stockonhand_curp (
         gsc_cust_in IN Tmp_Group_Cust.sGroupCust%TYPE,
          gsc_src_get_soh_trans OUT sys_refcursor
        );
        
    FUNCTION total_dmd_by_stock2
    ( gsc_stock_in IN NA.NA_STOCK%TYPE)
  RETURN NUMBER;
  
  
  PROCEDURE get_finance_transactions_curp (
        gds_cust_in IN IM.IM_CUST%TYPE,
        gds_src_get_finance_trans OUT sys_refcursor
  );
  
  PROCEDURE EOM_AUTO_RUN_ALL (
      p_array_size_start IN PLS_INTEGER DEFAULT 100
      ,start_date IN VARCHAR2-- := To_Date('1-Jun-2015') or format date as 01-Jun-15 -- use this when you want the date entered automatically
      ,end_date IN VARCHAR2-- := To_Date('30-Jun-2015')
      ,check_date IN VARCHAR2-- := To_Date('30-Jun-15')
      ,sCust_start IN VARCHAR2
      ,sAnalysis_Start IN RM.RM_ANAL%TYPE
      ,sFilterBy IN VARCHAR2
      ,sOp IN VARCHAR2
  );
  
  

END IQ_EOM_REPORTING;

