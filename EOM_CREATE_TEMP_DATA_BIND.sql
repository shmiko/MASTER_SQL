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
		--v_query := 'TRUNCATE TABLE Tmp_Cust_Reporting';
		--EXECUTE IMMEDIATE v_query;
	
		DBMS_OUTPUT.PUT_LINE('Successfully truncated all temporary tables');

	/* Run Group Cust Procedure*/
		nCheckpoint := 10;
		EXECUTE IMMEDIATE 'BEGIN eom_report_pkg.GROUP_CUST_START; END;';
	
		DBMS_OUTPUT.PUT_LINE('Successfully truncated, recreated AND populated Tmp_Group_Cust');

	/*Insert fresh temp data*/
		nCheckpoint := 11;                  
		EXECUTE IMMEDIATE 'INSERT INTO Tmp_Admin_Data_BreakPrices
							SELECT II_STOCK,II_CUST,II_BREAK_LCL,NULL,NULL,NULL,NULL
							FROM II INNER JOIN IM ON IM_STOCK = II_STOCK
							AND II_BREAK_LCL > 0.000001';	
										
		nCheckpoint := 12;
    EXECUTE IMMEDIATE q'{INSERT INTO Tmp_Admin_Data_Pickslips
							SELECT LTrim(ST_PICK),LTrim(ST_PSLIP), substr(To_Char(ST_DESP_DATE),0,10), ST_WEIGHT, ST_PACKAGES,ST_XX_NUM_PAL_SW,ST_XX_NUM_PALLETS,ST_XX_NUM_CARTONS,NULL,NULL,NULL,NULL
							FROM ST LEFT JOIN SH ON SH_ORDER = ST_ORDER
							WHERE ST_DESP_DATE >= :v_start_date AND ST_DESP_DATE <= :v_end_date	AND ST_PSLIP != 'CANCELLED'
							AND SH_STATUS <> 3}' 
              USING start_date, end_date;
	
		nCheckpoint := 13;
		EXECUTE IMMEDIATE q'{INSERT INTO Tmp_Admin_Data_Pick_LineCounts  
							SELECT MAX(SL_LINE),LTrim(SL_PICK), LTrim(SL_ORDER), LTrim(SL_PSLIP),TP.vDateDesp, TP.vPackages,TP.vWeight,TP.vST_XX_NUM_PAL_SW,TP.vST_XX_NUM_PALLETS,TP.vST_XX_NUM_CARTONS,NULL,NULL,NULL,NULL
							FROM Tmp_Admin_Data_Pickslips TP RIGHT JOIN SL ON LTrim(SL_PICK) = TP.vPickslip WHERE SL_EDIT_DATE >= :v_start_date AND SL_EDIT_DATE <= :v_end_date AND SL_PSLIP != 'CANCELLED'
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
						SELECT Count(DISTINCT NI_STOCK) AS CountOfStocks, IL_LOCN, IM_CUST,NULL,NULL,NULL,NULL,NULL
						FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
						INNER JOIN IM ON IM_STOCK = NI_STOCK
						WHERE IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_PARENT = ' '  AND RM_ANAL = :v_analysis AND RM_TYPE = 0 AND RM_ACTIVE = 1 )
						AND IM_ACTIVE = 1
						AND NI_AVAIL_ACTUAL >= '1'
						AND NI_STATUS <> 0
						GROUP BY IL_LOCN, IM_CUST}';
		EXECUTE IMMEDIATE v_query using sAnalysis;
		
		DBMS_OUTPUT.PUT_LINE('Successfully inserted fresh temporary data');


    RETURN;
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END EOM_CREATE_TEMP_DATA_BIND;