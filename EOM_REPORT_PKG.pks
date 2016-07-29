CREATE OR REPLACE PACKAGE PWIN175.EOM_REPORT_PKG
IS

    TYPE custtype IS RECORD
      (
      cust    VARCHAR2(20)
      ,coynum VARCHAR2(20)
      ,rep    VARCHAR2(20)
      ,bank   VARCHAR2(20)
      );
                                                
    /* /*  TYPE lov_oty AS OBJECT
      (
      brand_tx VARCHAR2(10)
      ,desc_tx VARCHAR2(25)
      );
    */
    TYPE myBrandType IS RECORD 
      (
      brand_tx VARCHAR2(10)
      ,desc_tx VARCHAR2(25)
      );

    --/*decalre variables These are being declared via the stored procedure - just need to redeclare cust so as we can get the rates*/
    NOTcust               CONSTANT VARCHAR2(20) := 'TABCORP';
    ordernum              CONSTANT VARCHAR2(20) := '1363806';
    stock                 CONSTANT VARCHAR2(20) := 'COURIER';
    source                CONSTANT VARCHAR2(20) := 'BSPRINTNSW';
    sAnalysis                      VARCHAR2(20) := '21VICP';
    anal                  CONSTANT VARCHAR2(20) := '21VICP';
    start_date                     VARCHAR2(20) := To_Date('01-Apr-2014');
    end_date                       VARCHAR2(20) := To_Date('28-Apr-2014');
    AdjustedDespDate      CONSTANT VARCHAR2(20) := To_Date('28-Feb-2014');
    AnotherCust           CONSTANT VARCHAR2(20) := 'BEYONDBLUE';
    warehouse             CONSTANT VARCHAR2(20) := 'SYDNEY';
    AnotherWwarehouse     CONSTANT VARCHAR2(20) := 'MELBOURNE';
    month_date            CONSTANT VARCHAR2(20) := substr(end_date,4,3);
    year_date             CONSTANT VARCHAR2(20) := substr(end_date,8,2); 
    closed_status         CONSTANT VARCHAR2(1)  := 'C';
    open_status           CONSTANT VARCHAR2(1)  := 'O';
    active_status         CONSTANT VARCHAR2(1)  := 'A';
    inactive_status       CONSTANT VARCHAR2(1)  := 'I';
    
    no_cancelled_picks    CONSTANT VARCHAR2(12) := 'CANCELLED';
    CutOffOrderAddTime    CONSTANT NUMBER       := ('120000');
    CutOffDespTimeSameDay CONSTANT NUMBER       := ('235959');
    CutOffDespTimeNextDay CONSTANT NUMBER       := ('120000');
    status                CONSTANT NUMBER       := 3;
    order_limit           CONSTANT NUMBER       := 1;
    min_difference        CONSTANT NUMBER       := 1;
    max_difference        CONSTANT NUMBER       := 100;
   
    starting_date         CONSTANT DATE         := SYSDATE;
    ending_date           CONSTANT DATE         := ADD_MONTHS (SYSDATE, 120);
    earliest_date         CONSTANT DATE         := SYSDATE;
    latest_date           CONSTANT DATE         := ADD_MONTHS (SYSDATE, 120);

 
    TYPE stock_rec_type IS RECORD 
      (
      gv_Cust_type       RM.RM_CUST%TYPE
      ,gv_OrderNum_type   SH.SH_ORDER%TYPE
      ,gv_DespDate_type   ST.ST_DESP_DATE%TYPE
      ,gv_Stock_type      SD.SD_STOCK%TYPE
      ,gv_UnitPrice_type  NUMBER(10,4)
      ,gv_Brand_type      IM.IM_BRAND%TYPE
      );
                                  
    TYPE stock_ref_cur IS REF CURSOR RETURN stock_rec_type;
  
    FUNCTION total_orders
      ( 
      rm_cust_in IN rm.rm_cust%TYPE
      ,status_in IN sh.sh_status%TYPE:=NULL
      ,sh_add_in IN sh.sh_add_date%TYPE
      )
      RETURN NUMBER;

    FUNCTION total_despatches
      ( 
      d_rm_cust_in IN rm.rm_cust%TYPE
      ,d_status_in IN sh.sh_status%TYPE:=NULL
      ,st_add_in IN st.st_desp_date%TYPE
      )
      RETURN NUMBER;

    PROCEDURE GROUP_CUST_START;

    PROCEDURE GROUP_CUST_GET
      (
      gc_customer_in IN rm.rm_cust%TYPE
      );

    PROCEDURE GROUP_CUST_LIST
      (
      tgc_customer_in IN rm.rm_cust%TYPE
      );

    PROCEDURE DESP_STOCK_GET    
      (
      cdsg_date_from_in IN  SH.SH_ADD_DATE%TYPE
      ,cdsg_date_to_in IN  SH.SH_EDIT_DATE%TYPE
      ,cdsg_cust_in IN RM.RM_CUST%TYPE
      );

    FUNCTION F_BREAK_UNIT_PRICE
      ( 
      rm_cust_in IN II.II_CUST%TYPE
      ,stock_in   IN II.II_STOCK%TYPE
      )
      RETURN NUMBER;
   
    PROCEDURE get_desp_stocks_cur_p 
      (
			gds_cust_in IN IM.IM_CUST%TYPE
			,gds_cust_not_in IN  IM.IM_CUST%TYPE
			,gds_stock_not_in IN IM.IM_STOCK%TYPE
			,gds_stock_not_in2 IN IM.IM_STOCK%TYPE
			,gds_start_date_in IN SH.SH_EDIT_DATE%TYPE
			,gds_end_date_in IN SH.SH_ADD_DATE%TYPE
			,desp_stock_list_cur_var IN OUT stock_ref_cur
      );
  
    PROCEDURE get_desp_stocks_curp 
      (
			gds_cust_in IN IM.IM_CUST%TYPE
			,gds_cust_not_in IN  IM.IM_CUST%TYPE
			--,gds_nx_ext_type_in IN NI.NI_NV_EXT_TYPE%TYPE
			,gds_stock_not_in IN IM.IM_STOCK%TYPE
			,gds_stock_not_in2 IN IM.IM_STOCK%TYPE
			,gds_start_date_in IN SH.SH_EDIT_DATE%TYPE
			,gds_end_date_in IN SH.SH_ADD_DATE%TYPE
			,gds_src_get_desp_stocks OUT sys_refcursor
      );
  
    PROCEDURE myproc_test_via_PHP
      (
      p1 IN NUMBER
      ,p2 IN OUT NUMBER
      );
  
    PROCEDURE list_stocks
      (
      cat IN IM.IM_CAT%TYPE
      );
  
    PROCEDURE quick_function_test
      ( 
      p_rc OUT SYS_REFCURSOR 
      );
  
    PROCEDURE test_get_brand;
    
    FUNCTION f_getDisplay
      (
      i_column_tx VARCHAR2
      ,i_table_select_tx VARCHAR2
      ,i_field_tx VARCHAR2
      ,i_value_tx VARCHAR2
      )
      RETURN VARCHAR2;
    
    FUNCTION f_getDisplay_from_type_bind
      (
      i_first_col IN VARCHAR2
      ,i_value_tx IN VARCHAR2
      )
      RETURN myBrandType;
              
    FUNCTION f_getDisplay_oty
      (
      i_column_tx VARCHAR2
      ,i_column2_tx VARCHAR2
      ,i_table_select_tx VARCHAR2
      ,i_field_tx VARCHAR2
      ,i_value_tx NUMBER
      )
      RETURN VARCHAR2;
        
    FUNCTION get_cust_stocks
      (
      r_coy_num in VARCHAR
      ) 
      RETURN sys_refcursor;
    
    /* FUNCTION populate_custs
      (
      coynum in VARCHAR := null
      )
      RETURN  custtype;
    */
        
    FUNCTION refcursor_function 
      RETURN SYS_REFCURSOR;
  
    PROCEDURE EOM_CREATE_TEMP_DATA 
        (
        p_pick_status IN NUMBER
        , p_status IN VARCHAR2
        , sAnalysis IN VARCHAR2
        , start_date IN VARCHAR2
        ,end_date IN VARCHAR2  
        );
  
    PROCEDURE EOM_CREATE_TEMP_DATA_BIND 
        (sAnalysis IN RM.RM_ANAL%TYPE
        , start_date IN ST.ST_DESP_DATE%TYPE
        , end_date IN ST.ST_DESP_DATE%TYPE 
        );

    PROCEDURE EOM_CREATE_TEMP_LOG_DATA 
        (
        start_date IN SH.SH_ADD_DATE%TYPE
        ,end_date  IN SH.SH_ADD_DATE%TYPE 
        );
        
        
END EOM_REPORT_PKG;
/