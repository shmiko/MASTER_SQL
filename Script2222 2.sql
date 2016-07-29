create or replace PROCEDURE DM_CUSTOMER_STORAGE_COUNTS
        (
        cust      IN VARCHAR2
        ,gds_src_get_locn_stocks OUT sys_refcursor
        )
     AS
    v_out_tx          VARCHAR2(2000);
    v_query           CLOB;
    nCheckpoint       NUMBER;


    BEGIN


  /*decalre variables*/
     /*  create table if required

     CREATE TABLE Tmp_dm_stats (vCntOfStocks NUMBER, vLocn VARCHAR(20), vCust VARCHAR(20));

     */

    /* Truncate all temp tables*/
        nCheckpoint := 1;
        v_query := 'TRUNCATE TABLE Tmp_dm_stats';
        EXECUTE IMMEDIATE v_query;

    /* Run Group Cust Procedure*/
		--//nCheckpoint := 10;
		--//EXECUTE IMMEDIATE 'BEGIN eom_report_pkg.GROUP_CUST_START; END;';

		--DBMS_OUTPUT.PUT_LINE('Successfully truncated, recreated AND populated Tmp_Group_Cust');
     COMMIT;

    /*Insert fresh temp data*/
        nCheckpoint := 2;



        v_query := q'{  SELECT Count(DISTINCT NI_STOCK) AS CountOfStocks, IL_LOCN, IM_CUST, IM_STOCK, IM_XX_ABSTRACT2, IM_DESC, NI_AVAIL_ACTUAL,
                      F_DM_LAST_REC_DATE(IM_STOCK),
                      F_DM_LAST_USE_DATE(IM_STOCK)
						        FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
						        INNER JOIN IM ON IM_STOCK = NI_STOCK
						        WHERE IM_CUST LIKE '%D-%'
                    OR IM_CUST LIKE :cust
						        AND IM_ACTIVE = 1
						        AND NI_AVAIL_ACTUAL >= '1'
						        AND NI_STATUS <> 0
						        GROUP BY IL_LOCN, IM_CUST, IM_STOCK, IM_XX_ABSTRACT2, IM_DESC, NI_AVAIL_ACTUAL
                    ORDER BY 3



                      }';
           OPEN gds_src_get_locn_stocks FOR  v_query
          -- USING start_date, end_date, warehouse, start_date, end_date, warehouse, start_date, end_date, warehouse, start_date, end_date, warehouse;
           USING cust;
           DBMS_OUTPUT.PUT_LINE('Successfully inserted new temporary data for dm customer storage counts');

  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM processing failed at dm customer storage counts ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END DM_CUSTOMER_STORAGE_COUNTS;



