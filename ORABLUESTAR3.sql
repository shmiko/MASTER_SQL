create or replace PROCEDURE EOM_GET_TEMP_DATA
        (
        start_date IN SH.SH_ADD_DATE%TYPE
        ,end_date  IN SH.SH_ADD_DATE%TYPE
        ,analysis IN RM.RM_ANAL%TYPE := NULL
        ,gds_src_get_desp_stocks OUT sys_refcursor
        )
     AS
    v_out_tx          VARCHAR2(2000);
    v_query           CLOB;
   
    nCheckpoint       NUMBER;
   

    BEGIN

    
  /*decalre variables*/


    /* Truncate all temp tables*/
    nCheckpoint := 1;
		EXECUTE IMMEDIATE 'BEGIN EOM_CREATE_TEMP_LOG_ORDERS(:start_dateO,:end_dateO,:sanalysisO); END;'
    USING start_date, end_date,analysis;
    

    /*Insert fresh temp data*/
        nCheckpoint := 2;



        v_query := q'{

                      Select * From Tmp_Log_Cnts ORDER BY 1,2,3;

                      }';
           OPEN gds_src_get_desp_stocks FOR  v_query;
           DBMS_OUTPUT.PUT_LINE('Successfully inserted fresh temporary data for pallets and shelves using NO warehouse and customer filters - should have passed NULL values and returned all data');
 
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END EOM_GET_TEMP_DATA;