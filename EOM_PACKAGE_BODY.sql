create or replace PACKAGE BODY EOM AS

	/* Y Run this once for each customer including intercompany   
	This merges all the Charges from each of the temp tables   
	Temp Tables Used   
	1. TMP_ALL_FEES   
	*/
  
	PROCEDURE Z3_EOM_RUN_ALL (
		p_array_size_start IN PLS_INTEGER DEFAULT 100
		,start_date IN VARCHAR2 
		,end_date IN VARCHAR2
		,Customer IN VARCHAR2
		,Analysis IN RM.RM_ANAL%TYPE
		,FilterBy IN VARCHAR2
		,Op IN VARCHAR2 DEFAULT 'PAUL'
		,Inter_Y_OR_No IN VARCHAR2 DEFAULT 'N'
		,p_dev_bool in boolean
		,p_intercompany_bool in boolean
		,Debug_Y_OR_N IN VARCHAR2 DEFAULT 'Y'
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
		vRetTblCount INT;
		v_tmp_date VARCHAR2(12) := TO_DATE(end_date, 'DD-MON-YY');     
	BEGIN
	--CHECKPOINT 1;
	nCheckpoint := 1;
    If ((upper(Inter_Y_OR_No) = 'Y') AND (upper(Debug_Y_OR_N) = 'Y')) Then
		If (Op = 'PRJ' or Op = 'PRJ_TEST') Then
			DBMS_OUTPUT.PUT_LINE(Op || ' is running this report in the DEV environment for ' );
			DBMS_OUTPUT.PUT_LINE('date range from ' || start_date || ' to ' || end_date || ' and for ' );
			DBMS_OUTPUT.PUT_LINE('customer ' || Customer || ' and for ' );
			DBMS_OUTPUT.PUT_LINE('intercompany analysis ' || Analysis ||'. This comes from EOM @ checkpoint ' || nCheckpoint || '.' );
		Else
			DBMS_OUTPUT.PUT_LINE(Op || ' is running this report in the TMP environment for '  );
			DBMS_OUTPUT.PUT_LINE('date range from ' || start_date || ' to ' || end_date || ' and for '  );
			DBMS_OUTPUT.PUT_LINE('customer ' || Customer || ' and for '  );
			DBMS_OUTPUT.PUT_LINE( 'intercompany analysis ' || Analysis ||'. This comes from EOM @ checkpoint ' || nCheckpoint || '.' );
		End If;
		DBMS_OUTPUT.PUT_LINE('**************************************************************************************');
    ElsIf (upper(Debug_Y_OR_N) = 'Y') Then
		If (Op = 'PRJ' or Op = 'PRJ_TEST') Then
			DBMS_OUTPUT.PUT_LINE(Op || ' is running this report in the DEV environment for ' );
			DBMS_OUTPUT.PUT_LINE('date range from ' || start_date || ' to ' || end_date || ' and for ' );
			DBMS_OUTPUT.PUT_LINE('customer ' || Customer || '. This comes from EOM @ checkpoint ' || nCheckpoint || '.' );
		Else
			DBMS_OUTPUT.PUT_LINE(Op || ' is running this report in the TMP environment for ' );
			DBMS_OUTPUT.PUT_LINE('date range from ' || start_date || ' to ' || end_date || ' and for ' );
			DBMS_OUTPUT.PUT_LINE('customer ' || Customer || '. This comes from EOM @ checkpoint ' || nCheckpoint || '.' );
		End If;
		DBMS_OUTPUT.PUT_LINE('**************************************************************************************');
    End If;
    
    If (upper(Inter_Y_OR_No) = 'Y') Then
		If (Op = 'PRJ' or Op = 'PRJ_TEST') Then
			v_query  := 'TRUNCATE TABLE "PWIN175"."DEV_ALL_FEES"';
			If (upper(Debug_Y_OR_N) = 'Y') Then
			  DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' TRUNCATE DEV_ALL_FEES. This comes from EOM @ checkpoint ' || nCheckpoint || '.' );
			End If;
		Else
			v_query  := 'TRUNCATE TABLE "PWIN175"."TMP_ALL_FEES"';
			If (upper(Debug_Y_OR_N) = 'Y') Then
				DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' TRUNCATE TMP_ALL_FEES. This comes from EOM @ checkpoint ' || nCheckpoint || '.' );
			End If;
		End If;
    Else
		If (Op = 'PRJ' or Op = 'PRJ_TEST') Then
			v_query  := 'TRUNCATE TABLE "PWIN175"."DEV_ALL_FEES"';
			If (upper(Debug_Y_OR_N) = 'Y') Then
			  DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' TRUNCATE DEV_ALL_FEES. This comes from EOM @ checkpoint ' || nCheckpoint || '.' );
			End If;
		Else
			v_query  := 'TRUNCATE TABLE "PWIN175"."TMP_ALL_FEES"';
			If (upper(Debug_Y_OR_N) = 'Y') Then
			  DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' TRUNCATE TMP_ALL_FEES. This comes from EOM @ checkpoint ' || nCheckpoint || '.' );
			End If;
		End If;
    End If;
	EXECUTE IMMEDIATE v_query;
	sFileName := Customer || '-EOM-ADMIN-ORACLE-' || '-RunBy-' || Op || '-RunOn-' || start_date || '-TO-' || end_date || '-RunAt-' || sFileTime || sFileSuffix;
    DBMS_OUTPUT.PUT_LINE('.........................................END CHECKPOINT ' || nCheckpoint  || '.............................................');
	
    --CHECKPOINT 2;
	nCheckpoint := 2;
    If (upper(Inter_Y_OR_No) = 'Y') Then
		If (Op = 'PRJ' or Op = 'PRJ_TEST') Then
			v_query  := 'TRUNCATE TABLE Dev_Group_Cust';
			If (upper(Debug_Y_OR_N) = 'Y') Then
				DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' TRUNCATE Dev_Group_Cust. This comes from EOM @ checkpoint ' || nCheckpoint || '.' );
			End If;
		Else
			v_query  := 'TRUNCATE TABLE Tmp_Group_Cust';
			If (upper(Debug_Y_OR_N) = 'Y') Then
				DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' TRUNCATE Tmp_Group_Cust. This comes from EOM @ checkpoint ' || nCheckpoint || '.' );
			End If;
		End If; 
    Else
		If (Op = 'PRJ' or Op = 'PRJ_TEST') Then
			v_query  := 'TRUNCATE TABLE Dev_Group_Cust';
			If (upper(Debug_Y_OR_N) = 'Y') Then
				DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' TRUNCATE Dev_Group_Cust. This comes from EOM @ checkpoint ' || nCheckpoint || '.' );
			End If;
		Else
			v_query  := 'TRUNCATE TABLE Tmp_Group_Cust';
			If (upper(Debug_Y_OR_N) = 'Y') Then
				DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' TRUNCATE Tmp_Group_Cust. This comes from EOM @ checkpoint ' || nCheckpoint || '.' );
			End If;
		End If;
    End If;
	EXECUTE IMMEDIATE v_query;
	DBMS_OUTPUT.PUT_LINE('.........................................END CHECKPOINT ' || nCheckpoint  || '.............................................');
    
	nCheckpoint := 2.5;
	--Select (F_EOM_CHECK_LOG(v_tmp_date ,'Tmp_Group_Cust','A_EOM_GROUP_CUST')) INTO v_query_logfile From Dual;--v_query := q'{Select EOM_REPORT_PKG.EOM_CHECK_LOG(TO_CHAR(end_date,'DD-MON-YY') ,'TMP_ALL_FREIGHT_ALL','F_EOM_TMP_ALL_FREIGHT_ALL') }';--q'{INSERT INTO TMP_EOM_LOGS VALUES (SYSTIMESTAMP ,:startdate,:enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','NONE','TMP_ALL_FREIGHT_ALL',:v_time_taken,SYSTIMESTAMP )  }';
	--If UPPER(v_query_logfile) != UPPER(v_tmp_date) Then
    If (upper(Inter_Y_OR_No) = 'Y') Then
		If (Op = 'PRJ' or Op = 'PRJ_TEST') Then
			If F_IS_TABLE_EEMPTY('Dev_Group_Cust') <= 0 Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' Need to run A_EOM_GROUP_CUST(Op) for all customers as table Dev_Group_Cust is empty. This comes from EOM @ checkpoint ' || nCheckpoint || '.' );
				End If;
				EOM_INTERCO_REPORTING.A_EOM_GROUP_CUST(Op);
				Select F_IS_TABLE_EEMPTY('Dev_Group_Cust') INTO vRetTblCount From Dual;
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' Ran A_EOM_GROUP_CUST(Op) for all customers. Table Dev_Group_Cust has ' || vRetTblCount || ' records. This comes from EOM @ checkpoint ' || nCheckpoint || '.' );
				End If;
			Else
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' No Need to run A_EOM_GROUP_CUST(Op) for all customers as table Dev_Group_Cust is full of data - saved another 5 seconds. This comes from EOM @ checkpoint ' || nCheckpoint || '.' );
				End If;
			End If;
		Else
			If F_IS_TABLE_EEMPTY('Tmp_Group_Cust') <= 0 Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' Need to run A_EOM_GROUP_CUST(Op) for all customers as table Tmp _Group_Cust is empty. This comes from EOM @ checkpoint ' || nCheckpoint || '.' );
				End If;
				EOM_INTERCO_REPORTING.A_EOM_GROUP_CUST(Op);
				Select F_IS_TABLE_EEMPTY('Tmp_Group_Cust') INTO vRetTblCount From Dual;
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' Ran A_EOM_GROUP_CUST(Op) for all customers. Table Tmp_Group_Cust has ' || vRetTblCount || ' records. This comes from EOM @ checkpoint ' || nCheckpoint || '.' );
				End If;
			Else
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' No Need to run A_EOM_GROUP_CUST(Op) for all customers as table Tmp_Group_Cust is full of data - saved another 5 seconds. This comes from EOM @ checkpoint ' || nCheckpoint || '.' );
				End If;
			End If;
		End If;
    Else
		If (Op = 'PRJ' or Op = 'PRJ_TEST') Then
			If F_IS_TABLE_EEMPTY('Dev_Group_Cust') <= 0 Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' Need to run A_EOM_GROUP_CUST(Op) for all customers as table Dev_Group_Cust is empty. This comes from EOM @ checkpoint ' || nCheckpoint || '.' );
				End If;
				IQ_EOM_REPORTING.A_EOM_GROUP_CUST(Op);
				Select F_IS_TABLE_EEMPTY('Dev_Group_Cust') INTO vRetTblCount From Dual;
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' Ran A_EOM_GROUP_CUST(Op) for all customers. Table Dev_Group_Cust has ' || vRetTblCount || ' records. This comes from EOM @ checkpoint ' || nCheckpoint || '.' );
				End If;
			Else
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' No Need to run A_EOM_GROUP_CUST(Op) for all customers as table Dev_Group_Cust is full of data - saved another 5 seconds. This comes from EOM @ checkpoint ' || nCheckpoint || '.' );
				End If;
			End If;
		Else
			If F_IS_TABLE_EEMPTY('Tmp_Group_Cust') <= 0 Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' Need to run A_EOM_GROUP_CUST(Op) for all customers as table Tmp_Group_Cust is empty. This comes from EOM @ checkpoint ' || nCheckpoint || '.' );
				End If;
				IQ_EOM_REPORTING.A_EOM_GROUP_CUST(Op);
				Select F_IS_TABLE_EEMPTY('Tmp_Group_Cust') INTO vRetTblCount From Dual;
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' Ran A_EOM_GROUP_CUST(Op) for all customers. Table Tmp_Group_Cust has ' || vRetTblCount || ' records. This comes from EOM @ checkpoint ' || nCheckpoint || '.' );
				End If;
			Else
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' No Need to run A_EOM_GROUP_CUST(Op) for all customers as table Tmp_Group_Cust is full of data - saved another 5 seconds. This comes from EOM @ checkpoint ' || nCheckpoint || '.' );
				End If;
			End If;
		End If;
    End If;
    DBMS_OUTPUT.PUT_LINE('.........................................END CHECKPOINT ' || nCheckpoint  || '.............................................');
	
	nCheckpoint := 3;
	--v_query := q'{SELECT TO_CHAR(LAST_ANALYZED, 'DD-MON-YY') FROM DBA_TABLES WHERE TABLE_NAME = 'TMP_ADMIN_DATA_PICK_LINECOUNTS'}';
	--EXECUTE IMMEDIATE v_query INTO vRtnVal;-- USING sCustomerCode;
	--If F_IS_TABLE_EEMPTY('TMP_ADMIN_DATA_PICK_LINECOUNTS') <= 0 Then
    If (upper(Inter_Y_OR_No) = 'Y') Then
      If (Op = 'PRJ' or Op = 'PRJ_TEST') Then
        Select (EOM_INTERCO_REPORTING.F_EOM_CHECK_LOG(v_tmp_date ,'DEV_ADMIN_DATA_PICK_LINECOUNTS','B_EOM_START_RUN_ONCE_DATA',Op)) INTO v_query_logfile From Dual;--v_query := q'{Select EOM_REPORT_PKG.EOM_CHECK_LOG(TO_CHAR(end_date,'DD-MON-YY') ,'TMP_ALL_FREIGHT_ALL','F_EOM_TMP_ALL_FREIGHT_ALL') }';--q'{INSERT INTO TMP_EOM_LOGS VALUES (SYSTIMESTAMP ,:startdate,:enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','NONE','TMP_ALL_FREIGHT_ALL',:v_time_taken,SYSTIMESTAMP )  }';
        If F_IS_TABLE_EEMPTY('DEV_ADMIN_DATA_PICK_LINECOUNTS') <= 0 Then
			If (upper(Debug_Y_OR_N) = 'Y') Then
				DBMS_OUTPUT.PUT_LINE(nCheckpoint || '  Need to RUN_ONCE B_EOM_START_RUN_ONCE_DATA as DEV_ADMIN_DATA_PICK_LINECOUNTS for all customers as table is empty. result was ' || UPPER(v_query_logfile) || ' and end date was ' ||  UPPER(v_tmp_date) || '. This comes from EOM @ checkpoint ' || nCheckpoint || '.');
			End If;
			EOM_INTERCO_REPORTING.B_EOM_START_RUN_ONCE_DATA(start_date,end_date,Analysis,Customer,0,Op);
        ELSIf UPPER(v_query_logfile) != UPPER(v_tmp_date) Then
			-- If vRtnVal != TO_CHAR(SYSDATE, 'DD-MON-YY') Then
			If (upper(Debug_Y_OR_N) = 'Y') Then
				DBMS_OUTPUT.PUT_LINE('2nd Need to RUN_ONCE TMP_ADMIN_DATA_PICK_LINECOUNTS as B_EOM_START_RUN_ONCE_DATA for all customers as table is empty. result was ' || UPPER(v_query_logfile) || ' and end date was ' ||  UPPER(v_tmp_date) );
			End If;
			EOM_INTERCO_REPORTING.B_EOM_START_RUN_ONCE_DATA(start_date,end_date,Analysis,Customer,0,Op);
			--Else
			--DBMS_OUTPUT.PUT_LINE('2nd No Need to RUN_ONCE TMP_ADMIN_DATA_PICK_LINECOUNTS as B_EOM_START_RUN_ONCE_DATA for all customers as table is full of data - saved another 45 seconds. Last Date match was ' || UPPER(v_query_logfile) || ' and end date was ' ||  UPPER(v_tmp_date) );
        End If;
      Else
        Select (EOM_INTERCO_REPORTING.F_EOM_CHECK_LOG(v_tmp_date ,'TMP_ADMIN_DATA_PICK_LINECOUNTS','B_EOM_START_RUN_ONCE_DATA',Op)) INTO v_query_logfile From Dual;--v_query := q'{Select EOM_REPORT_PKG.EOM_CHECK_LOG(TO_CHAR(end_date,'DD-MON-YY') ,'TMP_ALL_FREIGHT_ALL','F_EOM_TMP_ALL_FREIGHT_ALL') }';--q'{INSERT INTO TMP_EOM_LOGS VALUES (SYSTIMESTAMP ,:startdate,:enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','NONE','TMP_ALL_FREIGHT_ALL',:v_time_taken,SYSTIMESTAMP )  }';
        If F_IS_TABLE_EEMPTY('TMP_ADMIN_DATA_PICK_LINECOUNTS') <= 0 Then
          If (upper(Debug_Y_OR_N) = 'Y') Then
            DBMS_OUTPUT.PUT_LINE(nCheckpoint || '  Need to RUN_ONCE B_EOM_START_RUN_ONCE_DATA as TMP_ADMIN_DATA_PICK_LINECOUNTS for all customers as table is empty. result was ' || UPPER(v_query_logfile) || ' and end date was ' ||  UPPER(v_tmp_date) );
          End If;
          EOM_INTERCO_REPORTING.B_EOM_START_RUN_ONCE_DATA(start_date,end_date,Analysis,Customer,0,Op);
        ELSIf UPPER(v_query_logfile) != UPPER(v_tmp_date) Then
          -- If vRtnVal != TO_CHAR(SYSDATE, 'DD-MON-YY') Then
          If (upper(Debug_Y_OR_N) = 'Y') Then
            DBMS_OUTPUT.PUT_LINE('2nd Need to RUN_ONCE TMP_ADMIN_DATA_PICK_LINECOUNTS as B_EOM_START_RUN_ONCE_DATA for all customers as table is empty. result was ' || UPPER(v_query_logfile) || ' and end date was ' ||  UPPER(v_tmp_date) );
          End If;
          EOM_INTERCO_REPORTING.B_EOM_START_RUN_ONCE_DATA(start_date,end_date,Analysis,Customer,0,Op);
          --Else
          --DBMS_OUTPUT.PUT_LINE('2nd No Need to RUN_ONCE TMP_ADMIN_DATA_PICK_LINECOUNTS as B_EOM_START_RUN_ONCE_DATA for all customers as table is full of data - saved another 45 seconds. Last Date match was ' || UPPER(v_query_logfile) || ' and end date was ' ||  UPPER(v_tmp_date) );
        End If;
      End If;
    Else
      If (Op = 'PRJ' or Op = 'PRJ_TEST') Then
        Select (IQ_EOM_REPORTING.F_EOM_CHECK_LOG(v_tmp_date ,'DEV_ADMIN_DATA_PICK_LINECOUNTS','B_EOM_START_RUN_ONCE_DATA',Op)) INTO v_query_logfile From Dual;--v_query := q'{Select EOM_REPORT_PKG.EOM_CHECK_LOG(TO_CHAR(end_date,'DD-MON-YY') ,'TMP_ALL_FREIGHT_ALL','F_EOM_TMP_ALL_FREIGHT_ALL') }';--q'{INSERT INTO TMP_EOM_LOGS VALUES (SYSTIMESTAMP ,:startdate,:enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','NONE','TMP_ALL_FREIGHT_ALL',:v_time_taken,SYSTIMESTAMP )  }';
        If F_IS_TABLE_EEMPTY('DEV_ADMIN_DATA_PICK_LINECOUNTS') <= 0 Then
          If (upper(Debug_Y_OR_N) = 'Y') Then
            DBMS_OUTPUT.PUT_LINE(nCheckpoint || '  Need to RUN_ONCE B_EOM_START_RUN_ONCE_DATA as DEV_ADMIN_DATA_PICK_LINECOUNTS for all customers as table is empty. result was ' || UPPER(v_query_logfile) || ' and end date was ' ||  UPPER(v_tmp_date) );
          End If;
          IQ_EOM_REPORTING.B_EOM_START_RUN_ONCE_DATA(start_date,end_date,Op);
        ELSIf UPPER(v_query_logfile) != UPPER(v_tmp_date) Then
          -- If vRtnVal != TO_CHAR(SYSDATE, 'DD-MON-YY') Then
          --DBMS_OUTPUT.PUT_LINE('2nd Need to RUN_ONCE TMP_ADMIN_DATA_PICK_LINECOUNTS as B_EOM_START_RUN_ONCE_DATA for all customers as table is empty. result was ' || UPPER(v_query_logfile) || ' and end date was ' ||  UPPER(v_tmp_date) );
          IQ_EOM_REPORTING.B_EOM_START_RUN_ONCE_DATA(start_date,end_date,Op);
          --Else
          --DBMS_OUTPUT.PUT_LINE('2nd No Need to RUN_ONCE TMP_ADMIN_DATA_PICK_LINECOUNTS as B_EOM_START_RUN_ONCE_DATA for all customers as table is full of data - saved another 45 seconds. Last Date match was ' || UPPER(v_query_logfile) || ' and end date was ' ||  UPPER(v_tmp_date) );
        End If;
      Else
        Select (IQ_EOM_REPORTING.F_EOM_CHECK_LOG(v_tmp_date ,'TMP_ADMIN_DATA_PICK_LINECOUNTS','B_EOM_START_RUN_ONCE_DATA',Op)) INTO v_query_logfile From Dual;--v_query := q'{Select EOM_REPORT_PKG.EOM_CHECK_LOG(TO_CHAR(end_date,'DD-MON-YY') ,'TMP_ALL_FREIGHT_ALL','F_EOM_TMP_ALL_FREIGHT_ALL') }';--q'{INSERT INTO TMP_EOM_LOGS VALUES (SYSTIMESTAMP ,:startdate,:enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','NONE','TMP_ALL_FREIGHT_ALL',:v_time_taken,SYSTIMESTAMP )  }';
        If F_IS_TABLE_EEMPTY('TMP_ADMIN_DATA_PICK_LINECOUNTS') <= 0 Then
          If (upper(Debug_Y_OR_N) = 'Y') Then
            DBMS_OUTPUT.PUT_LINE(nCheckpoint || '  Need to RUN_ONCE B_EOM_START_RUN_ONCE_DATA as TMP_ADMIN_DATA_PICK_LINECOUNTS for all customers as table is empty. result was ' || UPPER(v_query_logfile) || ' and end date was ' ||  UPPER(v_tmp_date) );
          End If;
          IQ_EOM_REPORTING.B_EOM_START_RUN_ONCE_DATA(start_date,end_date,Op);
        ELSIf UPPER(v_query_logfile) != UPPER(v_tmp_date) Then
          -- If vRtnVal != TO_CHAR(SYSDATE, 'DD-MON-YY') Then
          --DBMS_OUTPUT.PUT_LINE('2nd Need to RUN_ONCE TMP_ADMIN_DATA_PICK_LINECOUNTS as B_EOM_START_RUN_ONCE_DATA for all customers as table is empty. result was ' || UPPER(v_query_logfile) || ' and end date was ' ||  UPPER(v_tmp_date) );
          IQ_EOM_REPORTING.B_EOM_START_RUN_ONCE_DATA(start_date,end_date,Op);
          --Else
          --DBMS_OUTPUT.PUT_LINE('2nd No Need to RUN_ONCE TMP_ADMIN_DATA_PICK_LINECOUNTS as B_EOM_START_RUN_ONCE_DATA for all customers as table is full of data - saved another 45 seconds. Last Date match was ' || UPPER(v_query_logfile) || ' and end date was ' ||  UPPER(v_tmp_date) );
        End If;
      End If;
    End If;
    
	nCheckpoint := 4;
	If (upper(Inter_Y_OR_No) = 'Y') Then
		If (Op = 'PRJ' or Op = 'PRJ_TEST') Then
			If F_IS_TABLE_EEMPTY('Dev_Locn_Cnt_By_Cust') <= 0 Then
				-- Select (F_EOM_CHECK_LOG(v_tmp_date ,'Tmp_Locn_Cnt_By_Cust','C_EOM_START_ALL_TEMP_STOR_DATA')) INTO v_query_logfile From Dual;--v_query := q'{Select EOM_REPORT_PKG.EOM_CHECK_LOG(TO_CHAR(end_date,'DD-MON-YY') ,'TMP_ALL_FREIGHT_ALL','F_EOM_TMP_ALL_FREIGHT_ALL') }';--q'{INSERT INTO TMP_EOM_LOGS VALUES (SYSTIMESTAMP ,:startdate,:enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','NONE','TMP_ALL_FREIGHT_ALL',:v_time_taken,SYSTIMESTAMP )  }';
				--If UPPER(v_query_logfile) != UPPER(v_tmp_date) OR F_IS_TABLE_EEMPTY('Tmp_Locn_Cnt_By_Cust') <= 0 Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || '  Need to RUN_ONCE C_EOM_START_ALL_TEMP_STOR_DATA as Dev_Locn_Cnt_By_Cust for all customers as table is empty.result was ' || UPPER(v_query_logfile) || ' and end date was ' ||  UPPER(v_tmp_date) );
				End If;
				--EOM_REPORT_PKG.C_EOM_START_CUST_TEMP_DATA(Analysis,Customer);
				EOM_INTERCO_REPORTING.C_EOM_START_ALL_TEMP_STOR_DATA(Analysis,Customer,Op);
			Else
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || '  No Need to RUN_ONCE C_EOM_START_ALL_TEMP_STOR_DATA as Dev_Locn_Cnt_By_Cust for all customers as table is full of data - saved another 65 seconds. Last Date match was ' || UPPER(v_query_logfile) || ' and end date was ' ||  UPPER(v_tmp_date) );
				End If;
			End If;
		Else
			If F_IS_TABLE_EEMPTY('Tmp_Locn_Cnt_By_Cust') <= 0 Then
				-- Select (F_EOM_CHECK_LOG(v_tmp_date ,'Tmp_Locn_Cnt_By_Cust','C_EOM_START_ALL_TEMP_STOR_DATA')) INTO v_query_logfile From Dual;--v_query := q'{Select EOM_REPORT_PKG.EOM_CHECK_LOG(TO_CHAR(end_date,'DD-MON-YY') ,'TMP_ALL_FREIGHT_ALL','F_EOM_TMP_ALL_FREIGHT_ALL') }';--q'{INSERT INTO TMP_EOM_LOGS VALUES (SYSTIMESTAMP ,:startdate,:enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','NONE','TMP_ALL_FREIGHT_ALL',:v_time_taken,SYSTIMESTAMP )  }';
				--If UPPER(v_query_logfile) != UPPER(v_tmp_date) OR F_IS_TABLE_EEMPTY('Tmp_Locn_Cnt_By_Cust') <= 0 Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || '  Need to RUN_ONCE C_EOM_START_ALL_TEMP_STOR_DATA as Tmp_Locn_Cnt_By_Cust for all customers as table is empty.result was ' || UPPER(v_query_logfile) || ' and end date was ' ||  UPPER(v_tmp_date) );
				End If;
				--EOM_REPORT_PKG.C_EOM_START_CUST_TEMP_DATA(Analysis,Customer);
				EOM_INTERCO_REPORTING.C_EOM_START_ALL_TEMP_STOR_DATA(Analysis,Customer,Op);
			Else
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || '  No Need to RUN_ONCE C_EOM_START_ALL_TEMP_STOR_DATA as Tmp_Locn_Cnt_By_Cust for all customers as table is full of data - saved another 65 seconds. Last Date match was ' || UPPER(v_query_logfile) || ' and end date was ' ||  UPPER(v_tmp_date) );
				End If;
			End If;
		End If;
    Else
		If (Op = 'PRJ' or Op = 'PRJ_TEST') Then
			If F_IS_TABLE_EEMPTY('Dev_Locn_Cnt_By_Cust') <= 0 Then
				-- Select (F_EOM_CHECK_LOG(v_tmp_date ,'Tmp_Locn_Cnt_By_Cust','C_EOM_START_ALL_TEMP_STOR_DATA')) INTO v_query_logfile From Dual;--v_query := q'{Select EOM_REPORT_PKG.EOM_CHECK_LOG(TO_CHAR(end_date,'DD-MON-YY') ,'TMP_ALL_FREIGHT_ALL','F_EOM_TMP_ALL_FREIGHT_ALL') }';--q'{INSERT INTO TMP_EOM_LOGS VALUES (SYSTIMESTAMP ,:startdate,:enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','NONE','TMP_ALL_FREIGHT_ALL',:v_time_taken,SYSTIMESTAMP )  }';
				--If UPPER(v_query_logfile) != UPPER(v_tmp_date) OR F_IS_TABLE_EEMPTY('Tmp_Locn_Cnt_By_Cust') <= 0 Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || '  Need to RUN_ONCE C_EOM_START_ALL_TEMP_STOR_DATA as Dev_Locn_Cnt_By_Cust for all customers as table is empty.result was ' || UPPER(v_query_logfile) || ' and end date was ' ||  UPPER(v_tmp_date) );
				End If;
				--EOM_REPORT_PKG.C_EOM_START_CUST_TEMP_DATA(Analysis,Customer);
				IQ_EOM_REPORTING.C_EOM_START_ALL_TEMP_STOR_DATA(Analysis,Customer,Op);
			Else
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || '  No Need to RUN_ONCE C_EOM_START_ALL_TEMP_STOR_DATA as Dev_Locn_Cnt_By_Cust for all customers as table is full of data - saved another 65 seconds. Last Date match was ' || UPPER(v_query_logfile) || ' and end date was ' ||  UPPER(v_tmp_date) );
				End If;
			End If;
		Else
			If F_IS_TABLE_EEMPTY('Tmp_Locn_Cnt_By_Cust') <= 0 Then
				-- Select (F_EOM_CHECK_LOG(v_tmp_date ,'Tmp_Locn_Cnt_By_Cust','C_EOM_START_ALL_TEMP_STOR_DATA')) INTO v_query_logfile From Dual;--v_query := q'{Select EOM_REPORT_PKG.EOM_CHECK_LOG(TO_CHAR(end_date,'DD-MON-YY') ,'TMP_ALL_FREIGHT_ALL','F_EOM_TMP_ALL_FREIGHT_ALL') }';--q'{INSERT INTO TMP_EOM_LOGS VALUES (SYSTIMESTAMP ,:startdate,:enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','NONE','TMP_ALL_FREIGHT_ALL',:v_time_taken,SYSTIMESTAMP )  }';
				--If UPPER(v_query_logfile) != UPPER(v_tmp_date) OR F_IS_TABLE_EEMPTY('Tmp_Locn_Cnt_By_Cust') <= 0 Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || '  Need to RUN_ONCE C_EOM_START_ALL_TEMP_STOR_DATA as Tmp_Locn_Cnt_By_Cust for all customers as table is empty.result was ' || UPPER(v_query_logfile) || ' and end date was ' ||  UPPER(v_tmp_date) );
				End If;
				--EOM_REPORT_PKG.C_EOM_START_CUST_TEMP_DATA(Analysis,Customer);
				IQ_EOM_REPORTING.C_EOM_START_ALL_TEMP_STOR_DATA(Analysis,Customer,Op);
			Else
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || '  No Need to RUN_ONCE C_EOM_START_ALL_TEMP_STOR_DATA as Tmp_Locn_Cnt_By_Cust for all customers as table is full of data - saved another 65 seconds. Last Date match was ' || UPPER(v_query_logfile) || ' and end date was ' ||  UPPER(v_tmp_date) );
				End If;
			End If;
		End If;
    End If;
	DBMS_OUTPUT.PUT_LINE('.........................................END CHECKPOINT ' || nCheckpoint  || '.............................................');
    
	nCheckpoint := 5;
	--  SELECT F_EOM_PROCESS_RUN_CHECK(TO_DATE(end_date, 'DD-MON-YY'),'TMP_ALL_FREIGHT_ALL','F_EOM_TMP_ALL_FREIGHT_ALL','') INTO v_query_logfile FROM DUAL;
	--  SELECT F_EOM_PROCESS_RUN_CHECK(TO_DATE(end_date, 'DD-MON-YY'),'TMP_ALL_FREIGHT_ALL','F_EOM_TMP_ALL_FREIGHT_ALL',Customer)INTO v_query_result2 FROM DUAL;
	--If v_query_logfile = 'RUNBOTH' Then
    If (upper(Inter_Y_OR_No) = 'Y') Then
		EOM_INTERCO_REPORTING.F_EOM_TMP_ALL_FREIGHT_ALL(p_array_size_start,start_date,end_date,Op,Analysis);
		EOM_INTERCO_REPORTING.F8_Z_EOM_RUN_FREIGHT(p_array_size_start,start_date,end_date,Customer,FilterBy,Op,Analysis); 
		If (upper(Debug_Y_OR_N) = 'Y') Then
			DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' Running F_EOM_TMP_ALL_FREIGHT_ALL & F8_Z_EOM_RUN_FREIGHT for ALL based on to date from EOM logs - v_query_logfile is ' || v_query_logfile || '- for end date being ' || TO_DATE(end_date, 'DD-MON-YY') || '.' );
		End If;
    Else
		IQ_EOM_REPORTING.F_EOM_TMP_ALL_FREIGHT_ALL(p_array_size_start,start_date,end_date,Op);
		IQ_EOM_REPORTING.F8_Z_EOM_RUN_FREIGHT(p_array_size_start,start_date,end_date,Customer,FilterBy,Op); 
		If (upper(Debug_Y_OR_N) = 'Y') Then
			DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' Running F_EOM_TMP_ALL_FREIGHT_ALL & F8_Z_EOM_RUN_FREIGHT for ALL based on to date from EOM logs - v_query_logfile is ' || v_query_logfile || '- for end date being ' || TO_DATE(end_date, 'DD-MON-YY') || '.' );
		End If;
    End If;
	--ElsIf v_query_result2  = 'RUNCUST' Then
	--IQ_EOM_REPORTING.F_EOM_TMP_ALL_FREIGHT_ALL(p_array_size_start,start_date,end_date);
	--IQ_EOM_REPORTING.F8_Z_EOM_RUN_FREIGHT(p_array_size_start,start_date,end_date,Customer,FilterBy); 
	--DBMS_OUTPUT.PUT_LINE('Running F_EOM_PROCESS_RUN_CHECK for CUST based on to date from EOM logs - v_query_result2 is ' || v_query_result2 || '- for end date being ' || TO_DATE(end_date, 'DD-MON-YY') || ' and process was F_EOM_TMP_ALL_FREIGHT_ALL' );
	--ElsIf (F_EOM_PROCESS_RUN_CHECK(TO_DATE(end_date, 'DD-MON-YY'),'TMP_ALL_FREIGHT_F','F8_Z_EOM_RUN_FREIGHT',Customer) = 'RUNCUST') Then
	--   IQ_EOM_REPORTING.F8_Z_EOM_RUN_FREIGHT(p_array_size_start,start_date,end_date,Customer,FilterBy);
	--   DBMS_OUTPUT.PUT_LINE('Running F_EOM_PROCESS_RUN_CHECK cust data for customer ' || Customer || ' for end date being ' || TO_DATE(end_date, 'DD-MON-YY') || ' and process was F_EOM_TMP_ALL_FREIGHT_ALL' );
	--Else
	--DBMS_OUTPUT.PUT_LINE('Running F_EOM_PROCESS_RUN_CHECK freight nothing - v_query_result2 is ' || v_query_result2 || ' and v_query_logfile is ' || v_query_logfile || '' );
	--End If;  
	DBMS_OUTPUT.PUT_LINE('.........................................END CHECKPOINT ' || nCheckpoint  || '.............................................');
	
	nCheckpoint := 6;
	-- SELECT F_EOM_PROCESS_RUN_CHECK(TO_DATE(end_date, 'DD-MON-YY'),'TMP_STOR_ALL_FEES','H4_EOM_ALL_STOR_FEES','') INTO v_query_logfile FROM DUAL;
	-- SELECT F_EOM_PROCESS_RUN_CHECK(TO_DATE(end_date, 'DD-MON-YY'),'TMP_STOR_ALL_FEES','H4_EOM_ALL_STOR_FEES',Customer)INTO v_query_result2 FROM DUAL;
	--If v_query_logfile = 'RUNBOTH' Then
    If (upper(Inter_Y_OR_No) = 'Y') Then
      EOM_INTERCO_REPORTING.H4_EOM_ALL_STOR_FEES(p_array_size_start,start_date,end_date,Customer,Analysis,Op);
      EOM_INTERCO_REPORTING.H4_EOM_ALL_STOR(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
      If (upper(Debug_Y_OR_N) = 'Y') Then
            DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' Running H4_EOM_ALL_STOR_FEES & H4_EOM_ALL_STOR for ALL based on to date from EOM logs - v_query_logfile is ' ||  v_query_logfile || '- for end date being ' || TO_DATE(end_date, 'DD-MON-YY') || ' Customer was ' || Customer || ' and Analysis was ' || Analysis ||
            ' and process was H4_EOM_ALL_STOR_FEES' );
      End If;
    Else
      IQ_EOM_REPORTING.H4_EOM_ALL_STOR_FEES(p_array_size_start,start_date,end_date,Customer,Analysis,Op);
      IQ_EOM_REPORTING.H4_EOM_ALL_STOR(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
      If (upper(Debug_Y_OR_N) = 'Y') Then
            DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' Running H4_EOM_ALL_STOR_FEES & H4_EOM_ALL_STOR for ALL based on to date from EOM logs - v_query_logfile is ' || v_query_logfile || '- for end date being ' || TO_DATE(end_date, 'DD-MON-YY') || ' Customer was ' || Customer || ' and Analysis was ' || Analysis ||
          ' and process was H4_EOM_ALL_STOR_FEES' ); 
      End If;
    End If;
	-- DBMS_OUTPUT.PUT_LINE('Running F_EOM_PROCESS_RUN_CHECK for ALL based on to date from EOM logs - v_query_logfile is ' || v_query_logfile || '- for end date being ' || TO_DATE(end_date, 'DD-MON-YY') || ' and process was H4_EOM_ALL_STOR_FEES' );
	--ElsIf v_query_result2 = 'RUNCUST' Then
	-- IQ_EOM_REPORTING.H4_EOM_ALL_STOR(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy);
	-- DBMS_OUTPUT.PUT_LINE('Running F_EOM_PROCESS_RUN_CHECK for CUST based on to date from EOM logs - v_query_result2 is ' || v_query_result2 || '-  for end date being ' || TO_DATE(end_date, 'DD-MON-YY') || ' and process was H4_EOM_ALL_STOR_FEES' );
	-- Else
	-- DBMS_OUTPUT.PUT_LINE('Running F_EOM_PROCESS_RUN_CHECK storage nothing' || 'v_query_result2 is ' || v_query_result2 || '-- v_query_logfile is ' || v_query_logfile || '-' );
	-- End If;
	DBMS_OUTPUT.PUT_LINE('.........................................END CHECKPOINT ' || nCheckpoint  || '.............................................');
	
	nCheckpoint := 71; --E0_ALL_ORD_FEES
    If (upper(Inter_Y_OR_No) = 'Y') Then
      EOM_INTERCO_REPORTING.E0_ALL_ORD_FEES(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
      If (upper(Debug_Y_OR_N) = 'Y') Then
            DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' Running E0_ALL_ORD_FEES for ALL based on to date from EOM logs');
      End If;
    Else
      IQ_EOM_REPORTING.E0_ALL_ORD_FEES(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
      If (upper(Debug_Y_OR_N) = 'Y') Then
            DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' Running E0_ALL_ORD_FEES for ALL based on to date from EOM logs');
      End If;
    End If;
	/*IQ_EOM_REPORTING.E1_PHONE_ORD_FEES(p_array_size_start,start_date,end_date,Customer,Analysis);
	  nCheckpoint := 72;
	  IQ_EOM_REPORTING.E2_EMAIL_ORD_FEES(p_array_size_start,start_date,end_date,Customer,Analysis);
	  nCheckpoint := 73;
	  IQ_EOM_REPORTING.E3_FAX_ORD_FEES(p_array_size_start,start_date,end_date,Customer,Analysis);
	*/  
	DBMS_OUTPUT.PUT_LINE('.........................................END CHECKPOINT ' || nCheckpoint  || '.............................................');	
	
	nCheckpoint := 74;
    If (upper(Inter_Y_OR_No) = 'Y') Then
      EOM_INTERCO_REPORTING.E4_STD_ORD_FEES(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
      If (upper(Debug_Y_OR_N) = 'Y') Then
            DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' Running E4_STD_ORD_FEES for ALL based on to date from EOM logs');
      End If;
    Else
      IQ_EOM_REPORTING.E4_STD_ORD_FEES(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
      If (upper(Debug_Y_OR_N) = 'Y') Then
            DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' Running E4_STD_ORD_FEES for ALL based on to date from EOM logs');
      End If;
    End If;
	DBMS_OUTPUT.PUT_LINE('.........................................END CHECKPOINT ' || nCheckpoint  || '.............................................');
    
	nCheckpoint := 75;
    If (upper(Inter_Y_OR_No) = 'Y') Then
      EOM_INTERCO_REPORTING.E5_DESTOY_ORD_FEES(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
      If (upper(Debug_Y_OR_N) = 'Y') Then
            DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' Running E5_DESTOY_ORD_FEES for ALL based on to date from EOM logs');
      End If;
    Else
      IQ_EOM_REPORTING.E5_DESTOY_ORD_FEES(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
      If (upper(Debug_Y_OR_N) = 'Y') Then
            DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' Running E5_DESTOY_ORD_FEES for ALL based on to date from EOM logs');    
      End If;
    End If;
	DBMS_OUTPUT.PUT_LINE('.........................................END CHECKPOINT ' || nCheckpoint  || '.............................................');
    
	nCheckpoint := 81;
    If (upper(Inter_Y_OR_No) = 'Y') Then
      EOM_INTERCO_REPORTING.G1_SHRINKWRAP_FEES(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
      If (upper(Debug_Y_OR_N) = 'Y') Then
            DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' Running G1_SHRINKWRAP_FEES for ALL based on to date from EOM logs');
      End If;
    Else
      IQ_EOM_REPORTING.G1_SHRINKWRAP_FEES(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
      If (upper(Debug_Y_OR_N) = 'Y') Then
            DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' Running G1_SHRINKWRAP_FEES for ALL based on to date from EOM logs');    
      End If;
    End If;    
	DBMS_OUTPUT.PUT_LINE('.........................................END CHECKPOINT ' || nCheckpoint  || '.............................................');
    
	nCheckpoint := 82;
    If (upper(Inter_Y_OR_No) = 'Y') Then
      EOM_INTERCO_REPORTING.G2_STOCK_FEES(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
      If (upper(Debug_Y_OR_N) = 'Y') Then
            DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' Running G2_STOCK_FEES for ALL based on to date from EOM logs');
      End If;
    Else
      IQ_EOM_REPORTING.G2_STOCK_FEES(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
      If (upper(Debug_Y_OR_N) = 'Y') Then
            DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' Running G2_STOCK_FEES for ALL based on to date from EOM logs');     
      End If;
    End If;
    --nCheckpoint := 83;
	--IQ_EOM_REPORTING.G3_PACKING_FEES(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy);
	DBMS_OUTPUT.PUT_LINE('.........................................END CHECKPOINT ' || nCheckpoint  || '.............................................');      
      
	nCheckpoint := 84;
	If (upper(Inter_Y_OR_No) = 'Y') Then
		If (Op = 'PRJ' or Op = 'PRJ_TEST') Then
			Select (EOM_INTERCO_REPORTING.F_EOM_CHECK_CUST_LOG(Customer ,'DEV_HANDLING_FEES','G4_HANDLING_FEES_F',Op)) INTO v_query_result2 From Dual;
			Select (EOM_INTERCO_REPORTING.F_EOM_CHECK_LOG(v_tmp_date ,'DEV_HANDLING_FEES','G4_HANDLING_FEES_F',Op)) INTO v_query_logfile From Dual;
		Else
			Select (EOM_INTERCO_REPORTING.F_EOM_CHECK_CUST_LOG(Customer ,'TMP_HANDLING_FEES','G4_HANDLING_FEES_F',Op)) INTO v_query_result2 From Dual;
			Select (EOM_INTERCO_REPORTING.F_EOM_CHECK_LOG(v_tmp_date ,'TMP_HANDLING_FEES','G4_HANDLING_FEES_F',Op)) INTO v_query_logfile From Dual;
		End If;
	Else
		If (Op = 'PRJ' or Op = 'PRJ_TEST') Then
			Select (IQ_EOM_REPORTING.F_EOM_CHECK_CUST_LOG(Customer ,'DEV_HANDLING_FEES','G4_HANDLING_FEES_F',Op)) INTO v_query_result2 From Dual;
			Select (IQ_EOM_REPORTING.F_EOM_CHECK_LOG(v_tmp_date ,'DEV_HANDLING_FEES','G4_HANDLING_FEES_F',Op)) INTO v_query_logfile From Dual;
		Else
			Select (IQ_EOM_REPORTING.F_EOM_CHECK_CUST_LOG(Customer ,'TMP_HANDLING_FEES','G4_HANDLING_FEES_F',Op)) INTO v_query_result2 From Dual;
			Select (IQ_EOM_REPORTING.F_EOM_CHECK_LOG(v_tmp_date ,'TMP_HANDLING_FEES','G4_HANDLING_FEES_F',Op)) INTO v_query_logfile From Dual;
		End If;      
	End If;
	If (upper(Debug_Y_OR_N) = 'Y') Then
            DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' Running F_EOM_CHECK_CUST_LOG & F_EOM_CHECK_LOG for ALL based on to date from EOM logs');
    End If;
    If (upper(Inter_Y_OR_No) = 'Y') Then
		If (Op = 'PRJ' or Op = 'PRJ_TEST') Then
			If F_IS_TABLE_EEMPTY('DEV_HANDLING_FEES') <= 0 Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE('7th Need to RUN_ONCE G4_HANDLING_FEES_F for all customers as table is empty. result was ' || UPPER(v_query_result2) 
					|| ' and this cust was ' ||  UPPER(Customer)
					|| ' and to date was ' ||  UPPER(v_query_logfile)
					|| ' and this date was ' ||  UPPER(v_tmp_date) 
					);
				End If;
				EOM_INTERCO_REPORTING.G4_HANDLING_FEES_F(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' 1 Running G4_HANDLING_FEES_F for ALL based on to date from EOM logs as DEV_HANDLING_FEES was empty');
				End If;
			ELSIf UPPER(v_query_result2) != UPPER(Customer) AND UPPER(v_query_logfile) IS NOT NULL AND UPPER(v_query_logfile) != UPPER(v_tmp_date) Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE('7th Need to RUN_ONCE G4_HANDLING_FEES_F for all customers as table is not empty. result was ' || UPPER(v_query_result2) 
					|| ' and this cust was ' ||  UPPER(Customer)
					|| ' and to date was ' ||  UPPER(v_query_logfile)
					|| ' and this date was ' ||  UPPER(v_tmp_date) 
					);
				End If;
				EOM_INTERCO_REPORTING.G4_HANDLING_FEES_F(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' 2 Running G4_HANDLING_FEES_F for ALL based on to date from EOM logs as DEV_HANDLING_FEES was empty');
				End If;
				--ELSIF  UPPER(v_query_result2) = UPPER(Customer) 
				--AND UPPER(v_query_result2) IS NOT NULL 
				--AND UPPER(v_query_logfile) = UPPER(v_tmp_date) Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE('7th No Need to RUN_ONCE G4_HANDLING_FEES_F for all customers as table is not empty. Last Cust match was ' ||  UPPER(v_query_result2) 
					|| ' and this cust was ' ||  UPPER(Customer)
					|| ' and to date was ' ||  UPPER(v_query_logfile)
					|| ' and this date was ' ||  UPPER(v_tmp_date) 
					);
				End If;
			ELSIf UPPER(v_query_result2) IS NULL OR UPPER(v_query_logfile) IS NULL Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE('7th Need to RUN_ONCE G4_HANDLING_FEES_F for all customers as LOGFILE is missing. result was ' || UPPER(v_query_result2) 
					|| ' and this cust was ' ||  UPPER(Customer)
					|| ' and to date was ' ||  UPPER(v_query_logfile)
					|| ' and this date was ' ||  UPPER(v_tmp_date) 
					);
				End If;
				EOM_INTERCO_REPORTING.G4_HANDLING_FEES_F(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' 3 Running G4_HANDLING_FEES_F for ALL based on to date from EOM logs as DEV_HANDLING_FEES was empty');
				End If;
			Else
				EOM_INTERCO_REPORTING.G4_HANDLING_FEES_F(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' 4 Running G4_HANDLING_FEES_F for ALL based on to date from EOM logs as DEV_HANDLING_FEES was empty');
				End If;
				--DBMS_OUTPUT.PUT_LINE('7th No matches for running G4_HANDLING_FEES_F, ran it just in case still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
				-- ' Seconds...for customer ' || Customer);
			END IF;
		Else
			If F_IS_TABLE_EEMPTY('TMP_HANDLING_FEES') <= 0 Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE('7th Need to RUN_ONCE G4_HANDLING_FEES_F for all customers as table is empty. result was ' || UPPER(v_query_result2) 
					|| ' and this cust was ' ||  UPPER(Customer)
					|| ' and to date was ' ||  UPPER(v_query_logfile)
					|| ' and this date was ' ||  UPPER(v_tmp_date) 
					);
				End If;
				EOM_INTERCO_REPORTING.G4_HANDLING_FEES_F(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' 4 Running G4_HANDLING_FEES_F for ALL based on to date from EOM logs as TMP_HANDLING_FEES was empty');
				End If;
			ELSIf UPPER(v_query_result2) != UPPER(Customer) AND UPPER(v_query_logfile) IS NOT NULL AND UPPER(v_query_logfile) != UPPER(v_tmp_date) Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE('7th Need to RUN_ONCE G4_HANDLING_FEES_F for all customers as table is not empty. result was ' || UPPER(v_query_result2) 
					|| ' and this cust was ' ||  UPPER(Customer)
					|| ' and to date was ' ||  UPPER(v_query_logfile)
					|| ' and this date was ' ||  UPPER(v_tmp_date) 
					);
				End If;
				EOM_INTERCO_REPORTING.G4_HANDLING_FEES_F(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' 4 Running G4_HANDLING_FEES_F for ALL based on to date from EOM logs as TMP_HANDLING_FEES was empty');
				End If;
				--ELSIF  UPPER(v_query_result2) = UPPER(Customer) 
				--AND UPPER(v_query_result2) IS NOT NULL 
				--AND UPPER(v_query_logfile) = UPPER(v_tmp_date) Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE('7th No Need to RUN_ONCE G4_HANDLING_FEES_F for all customers as table is not empty. Last Cust match was ' ||  UPPER(v_query_result2) 
					|| ' and this cust was ' ||  UPPER(Customer)
					|| ' and to date was ' ||  UPPER(v_query_logfile)
					|| ' and this date was ' ||  UPPER(v_tmp_date) 
					);
				End If;
			ELSIf UPPER(v_query_result2) IS NULL OR UPPER(v_query_logfile) IS NULL Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE('7th Need to RUN_ONCE G4_HANDLING_FEES_F for all customers as LOGFILE is missing. result was ' || UPPER(v_query_result2) 
					|| ' and this cust was ' ||  UPPER(Customer)
					|| ' and to date was ' ||  UPPER(v_query_logfile)
					|| ' and this date was ' ||  UPPER(v_tmp_date) 
					);
				End If;
				EOM_INTERCO_REPORTING.G4_HANDLING_FEES_F(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' 4 Running G4_HANDLING_FEES_F for ALL based on to date from EOM logs as TMP_HANDLING_FEES was empty');
				End If;
			Else
				EOM_INTERCO_REPORTING.G4_HANDLING_FEES_F(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' 4 Running G4_HANDLING_FEES_F for ALL based on to date from EOM logs as TMP_HANDLING_FEES was empty');
				End If;
				--DBMS_OUTPUT.PUT_LINE('7th No matches for running G4_HANDLING_FEES_F, ran it just in case still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
				-- ' Seconds...for customer ' || Customer);
			END IF;
		End If;
    Else
		If (Op = 'PRJ' or Op = 'PRJ_TEST') Then
			If F_IS_TABLE_EEMPTY('DEV_HANDLING_FEES') <= 0 Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE('7th Need to RUN_ONCE G4_HANDLING_FEES_F for all customers as table is empty. result was ' || UPPER(v_query_result2) 
					|| ' and this cust was ' ||  UPPER(Customer)
					|| ' and to date was ' ||  UPPER(v_query_logfile)
					|| ' and this date was ' ||  UPPER(v_tmp_date) 
					);
				End If;
				IQ_EOM_REPORTING.G4_HANDLING_FEES_F(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' 1 Running G4_HANDLING_FEES_F for ALL based on to date from EOM logs as DEV_HANDLING_FEES was empty');
				End If;
			ELSIf UPPER(v_query_result2) != UPPER(Customer) AND UPPER(v_query_logfile) IS NOT NULL AND UPPER(v_query_logfile) != UPPER(v_tmp_date) Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE('7th Need to RUN_ONCE G4_HANDLING_FEES_F for all customers as table is not empty. result was ' || UPPER(v_query_result2) 
					|| ' and this cust was ' ||  UPPER(Customer)
					|| ' and to date was ' ||  UPPER(v_query_logfile)
					|| ' and this date was ' ||  UPPER(v_tmp_date) 
					);
				End If;
				IQ_EOM_REPORTING.G4_HANDLING_FEES_F(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' 2 Running G4_HANDLING_FEES_F for ALL based on to date from EOM logs as DEV_HANDLING_FEES was empty');
				End If;
				--ELSIF  UPPER(v_query_result2) = UPPER(Customer) 
				--AND UPPER(v_query_result2) IS NOT NULL 
				--AND UPPER(v_query_logfile) = UPPER(v_tmp_date) Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE('7th No Need to RUN_ONCE G4_HANDLING_FEES_F for all customers as table is not empty. Last Cust match was ' ||  UPPER(v_query_result2) 
					|| ' and this cust was ' ||  UPPER(Customer)
					|| ' and to date was ' ||  UPPER(v_query_logfile)
					|| ' and this date was ' ||  UPPER(v_tmp_date) 
					);
				End If;
			ELSIf UPPER(v_query_result2) IS NULL OR UPPER(v_query_logfile) IS NULL Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE('7th Need to RUN_ONCE G4_HANDLING_FEES_F for all customers as LOGFILE is missing. result was ' || UPPER(v_query_result2) 
					|| ' and this cust was ' ||  UPPER(Customer)
					|| ' and to date was ' ||  UPPER(v_query_logfile)
					|| ' and this date was ' ||  UPPER(v_tmp_date) 
					);
				End If;
				IQ_EOM_REPORTING.G4_HANDLING_FEES_F(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' 3 Running G4_HANDLING_FEES_F for ALL based on to date from EOM logs as DEV_HANDLING_FEES was empty');
				End If;
			Else
				IQ_EOM_REPORTING.G4_HANDLING_FEES_F(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' 4 Running G4_HANDLING_FEES_F for ALL based on to date from EOM logs as DEV_HANDLING_FEES was empty');
				End If;
				--DBMS_OUTPUT.PUT_LINE('7th No matches for running G4_HANDLING_FEES_F, ran it just in case still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
				-- ' Seconds...for customer ' || Customer);
			END IF;
		Else
			If F_IS_TABLE_EEMPTY('TMP_HANDLING_FEES') <= 0 Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE('7th Need to RUN_ONCE G4_HANDLING_FEES_F for all customers as table is empty. result was ' || UPPER(v_query_result2) 
					|| ' and this cust was ' ||  UPPER(Customer)
					|| ' and to date was ' ||  UPPER(v_query_logfile)
					|| ' and this date was ' ||  UPPER(v_tmp_date) 
					);
				End If;
				IQ_EOM_REPORTING.G4_HANDLING_FEES_F(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' 4 Running G4_HANDLING_FEES_F for ALL based on to date from EOM logs as TMP_HANDLING_FEES was empty');
				End If;
			ELSIf UPPER(v_query_result2) != UPPER(Customer) AND UPPER(v_query_logfile) IS NOT NULL AND UPPER(v_query_logfile) != UPPER(v_tmp_date) Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE('7th Need to RUN_ONCE G4_HANDLING_FEES_F for all customers as table is not empty. result was ' || UPPER(v_query_result2) 
					|| ' and this cust was ' ||  UPPER(Customer)
					|| ' and to date was ' ||  UPPER(v_query_logfile)
					|| ' and this date was ' ||  UPPER(v_tmp_date) 
					);
				End If;
				IQ_EOM_REPORTING.G4_HANDLING_FEES_F(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' 4 Running G4_HANDLING_FEES_F for ALL based on to date from EOM logs as TMP_HANDLING_FEES was empty');
				End If;
				--ELSIF  UPPER(v_query_result2) = UPPER(Customer) 
				--AND UPPER(v_query_result2) IS NOT NULL 
				--AND UPPER(v_query_logfile) = UPPER(v_tmp_date) Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE('7th No Need to RUN_ONCE G4_HANDLING_FEES_F for all customers as table is not empty. Last Cust match was ' ||  UPPER(v_query_result2) 
					|| ' and this cust was ' ||  UPPER(Customer)
					|| ' and to date was ' ||  UPPER(v_query_logfile)
					|| ' and this date was ' ||  UPPER(v_tmp_date) 
					);
				End If;
			ELSIf UPPER(v_query_result2) IS NULL OR UPPER(v_query_logfile) IS NULL Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE('7th Need to RUN_ONCE G4_HANDLING_FEES_F for all customers as LOGFILE is missing. result was ' || UPPER(v_query_result2) 
					|| ' and this cust was ' ||  UPPER(Customer)
					|| ' and to date was ' ||  UPPER(v_query_logfile)
					|| ' and this date was ' ||  UPPER(v_tmp_date) 
					);
				End If;
				IQ_EOM_REPORTING.G4_HANDLING_FEES_F(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' 4 Running G4_HANDLING_FEES_F for ALL based on to date from EOM logs as TMP_HANDLING_FEES was empty');
				End If;
			Else
				IQ_EOM_REPORTING.G4_HANDLING_FEES_F(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE(nCheckpoint || ' 4 Running G4_HANDLING_FEES_F for ALL based on to date from EOM logs as TMP_HANDLING_FEES was empty');
				End If;
				--DBMS_OUTPUT.PUT_LINE('7th No matches for running G4_HANDLING_FEES_F, ran it just in case still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
				-- ' Seconds...for customer ' || Customer);
			END IF;
		End If;    
    End If;
	DBMS_OUTPUT.PUT_LINE('.........................................END CHECKPOINT ' || nCheckpoint  || '.............................................');
    
	nCheckpoint := 85;
    If (Op = 'PRJ' or Op = 'PRJ_TEST') Then
		If (Op = 'PRJ' or Op = 'PRJ_TEST') Then
			Select (EOM_INTERCO_REPORTING.F_EOM_CHECK_CUST_LOG(Customer ,'DEV_PICK_FEES','G5_PICK_FEES_F',Op)) INTO v_query_result2 From Dual;--v_query := q'{Select IQ_EOM_REPORTING.EOM_CHECK_LOG(TO_CHAR(end_date,'DD-MON-YY') ,'TMP_ALL_FREIGHT_ALL','F_EOM_TMP_ALL_FREIGHT_ALL') }';--q'{INSERT INTO TMP_EOM_LOGS VALUES (SYSTIMESTAMP ,:startdate,:enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','NONE','TMP_ALL_FREIGHT_ALL',:v_time_taken,SYSTIMESTAMP )  }';
			Select (EOM_INTERCO_REPORTING.F_EOM_CHECK_LOG(v_tmp_date ,'DEV_PICK_FEES','G5_PICK_FEES_F',Op)) INTO v_query_logfile From Dual;
			If F_IS_TABLE_EEMPTY('DEV_PICK_FEES') <= 0 Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE('8th Need to RUN_ONCE G5_PICK_FEES_F for all customers as table is  empty. cust result was ' || UPPER(v_query_result2) 
					|| ' and this cust was ' ||  UPPER(Customer)
					|| ' and to date was ' ||  UPPER(v_query_logfile)
					|| ' and this date was ' ||  UPPER(v_tmp_date)
					);
				END IF;
				EOM_INTERCO_REPORTING.G5_PICK_FEES_F(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
			ELSIf UPPER(v_query_result2) != UPPER(Customer) AND UPPER(v_query_result2) IS NOT NULL AND UPPER(v_query_logfile) != UPPER(v_tmp_date) Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE('8th Need to RUN_ONCE G5_PICK_FEES_F for all customers as table is not empty. cust result was ' || UPPER(v_query_result2) 
					|| ' and this cust was ' ||  UPPER(Customer)
					|| ' and to date was ' ||  UPPER(v_query_logfile)
					|| ' and this date was ' ||  UPPER(v_tmp_date)
					);
				END IF;
				EOM_INTERCO_REPORTING.G5_PICK_FEES_F(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
				--ELSIF UPPER(v_query_result2) = UPPER(Customer) 
				--AND UPPER(v_query_result2) IS NOT NULL 
				--AND UPPER(v_query_logfile) = UPPER(v_tmp_date) Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE('8th No Need to RUN_ONCE G5_PICK_FEES_F for all customers as table is not empty. Last Cust match was ' ||  UPPER(v_query_result2) 
					|| ' and this cust was ' ||  UPPER(Customer)
					|| ' and to date was ' ||  UPPER(v_query_logfile)
					|| ' and this date was ' ||  UPPER(v_tmp_date)
					);
				END IF;
			ELSIf UPPER(v_query_result2) IS NULL OR UPPER(v_query_logfile) IS NULL Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE('8th Need to RUN_ONCE G5_PICK_FEES_F for all customers as LOGFILE is missing. cust result was ' || UPPER(v_query_result2) 
					|| ' and this cust was ' ||  UPPER(Customer)
					|| ' and to date was ' ||  UPPER(v_query_logfile)
					|| ' and this date was ' ||  UPPER(v_tmp_date)
					);
				END IF;
				EOM_INTERCO_REPORTING.G5_PICK_FEES_F(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
			Else
				EOM_INTERCO_REPORTING.G5_PICK_FEES_F(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
				--DBMS_OUTPUT.PUT_LINE('8th No matches for running G5_PICK_FEES_F, ran it just in case still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
				--' Seconds...for customer ' || Customer);
			END IF;
		Else
			Select (EOM_INTERCO_REPORTING.F_EOM_CHECK_CUST_LOG(Customer ,'TMP_PICK_FEES','G5_PICK_FEES_F',Op)) INTO v_query_result2 From Dual;--v_query := q'{Select IQ_EOM_REPORTING.EOM_CHECK_LOG(TO_CHAR(end_date,'DD-MON-YY') ,'TMP_ALL_FREIGHT_ALL','F_EOM_TMP_ALL_FREIGHT_ALL') }';--q'{INSERT INTO TMP_EOM_LOGS VALUES (SYSTIMESTAMP ,:startdate,:enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','NONE','TMP_ALL_FREIGHT_ALL',:v_time_taken,SYSTIMESTAMP )  }';
			Select (EOM_INTERCO_REPORTING.F_EOM_CHECK_LOG(v_tmp_date ,'TMP_PICK_FEES','G5_PICK_FEES_F',Op)) INTO v_query_logfile From Dual;
			If F_IS_TABLE_EEMPTY('TMP_PICK_FEES') <= 0 Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE('8th Need to RUN_ONCE G5_PICK_FEES_F for all customers as table is  empty. cust result was ' || UPPER(v_query_result2) 
					|| ' and this cust was ' ||  UPPER(Customer)
					|| ' and to date was ' ||  UPPER(v_query_logfile)
					|| ' and this date was ' ||  UPPER(v_tmp_date)
					);
				END IF;
				EOM_INTERCO_REPORTING.G5_PICK_FEES_F(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
			ELSIf UPPER(v_query_result2) != UPPER(Customer) AND UPPER(v_query_result2) IS NOT NULL AND UPPER(v_query_logfile) != UPPER(v_tmp_date) Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE('8th Need to RUN_ONCE G5_PICK_FEES_F for all customers as table is not empty. cust result was ' || UPPER(v_query_result2) 
					|| ' and this cust was ' ||  UPPER(Customer)
					|| ' and to date was ' ||  UPPER(v_query_logfile)
					|| ' and this date was ' ||  UPPER(v_tmp_date)
					);
				END IF;
				EOM_INTERCO_REPORTING.G5_PICK_FEES_F(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
				--ELSIF UPPER(v_query_result2) = UPPER(Customer) 
				--AND UPPER(v_query_result2) IS NOT NULL 
				--AND UPPER(v_query_logfile) = UPPER(v_tmp_date) Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE('8th No Need to RUN_ONCE G5_PICK_FEES_F for all customers as table is not empty. Last Cust match was ' ||  UPPER(v_query_result2) 
					|| ' and this cust was ' ||  UPPER(Customer)
					|| ' and to date was ' ||  UPPER(v_query_logfile)
					|| ' and this date was ' ||  UPPER(v_tmp_date)
					);
				END IF;
			ELSIf UPPER(v_query_result2) IS NULL OR UPPER(v_query_logfile) IS NULL Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE('8th Need to RUN_ONCE G5_PICK_FEES_F for all customers as LOGFILE is missing. cust result was ' || UPPER(v_query_result2) 
					|| ' and this cust was ' ||  UPPER(Customer)
					|| ' and to date was ' ||  UPPER(v_query_logfile)
					|| ' and this date was ' ||  UPPER(v_tmp_date)
					);
				END IF;
				EOM_INTERCO_REPORTING.G5_PICK_FEES_F(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
			Else
				EOM_INTERCO_REPORTING.G5_PICK_FEES_F(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
				--DBMS_OUTPUT.PUT_LINE('8th No matches for running G5_PICK_FEES_F, ran it just in case still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
				--' Seconds...for customer ' || Customer);
			END IF;
		End If;
	Else
		If (Op = 'PRJ' or Op = 'PRJ_TEST') Then
			Select (IQ_EOM_REPORTING.F_EOM_CHECK_CUST_LOG(Customer ,'DEV_PICK_FEES','G5_PICK_FEES_F',Op)) INTO v_query_result2 From Dual;--v_query := q'{Select IQ_EOM_REPORTING.EOM_CHECK_LOG(TO_CHAR(end_date,'DD-MON-YY') ,'TMP_ALL_FREIGHT_ALL','F_EOM_TMP_ALL_FREIGHT_ALL') }';--q'{INSERT INTO TMP_EOM_LOGS VALUES (SYSTIMESTAMP ,:startdate,:enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','NONE','TMP_ALL_FREIGHT_ALL',:v_time_taken,SYSTIMESTAMP )  }';
			Select (IQ_EOM_REPORTING.F_EOM_CHECK_LOG(v_tmp_date ,'DEV_PICK_FEES','G5_PICK_FEES_F',Op)) INTO v_query_logfile From Dual;
			If F_IS_TABLE_EEMPTY('DEV_PICK_FEES') <= 0 Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE('8th Need to RUN_ONCE G5_PICK_FEES_F for all customers as table is  empty. cust result was ' || UPPER(v_query_result2) 
					|| ' and this cust was ' ||  UPPER(Customer)
					|| ' and to date was ' ||  UPPER(v_query_logfile)
					|| ' and this date was ' ||  UPPER(v_tmp_date)
					);
				End If;
				IQ_EOM_REPORTING.G5_PICK_FEES_F(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
			ELSIf UPPER(v_query_result2) != UPPER(Customer) AND UPPER(v_query_result2) IS NOT NULL AND UPPER(v_query_logfile) != UPPER(v_tmp_date) Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE('8th Need to RUN_ONCE G5_PICK_FEES_F for all customers as table is not empty. cust result was ' || UPPER(v_query_result2) 
					|| ' and this cust was ' ||  UPPER(Customer)
					|| ' and to date was ' ||  UPPER(v_query_logfile)
					|| ' and this date was ' ||  UPPER(v_tmp_date)
					);
				End If;
				IQ_EOM_REPORTING.G5_PICK_FEES_F(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
				--ELSIF UPPER(v_query_result2) = UPPER(Customer) 
				--AND UPPER(v_query_result2) IS NOT NULL 
				--AND UPPER(v_query_logfile) = UPPER(v_tmp_date) Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE('8th No Need to RUN_ONCE G5_PICK_FEES_F for all customers as table is not empty. Last Cust match was ' ||  UPPER(v_query_result2) 
					|| ' and this cust was ' ||  UPPER(Customer)
					|| ' and to date was ' ||  UPPER(v_query_logfile)
					|| ' and this date was ' ||  UPPER(v_tmp_date)
					);
				End If;
			ELSIf UPPER(v_query_result2) IS NULL OR UPPER(v_query_logfile) IS NULL Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE('8th Need to RUN_ONCE G5_PICK_FEES_F for all customers as LOGFILE is missing. cust result was ' || UPPER(v_query_result2) 
					|| ' and this cust was ' ||  UPPER(Customer)
					|| ' and to date was ' ||  UPPER(v_query_logfile)
					|| ' and this date was ' ||  UPPER(v_tmp_date)
					);
				End If;
				IQ_EOM_REPORTING.G5_PICK_FEES_F(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
			Else
				IQ_EOM_REPORTING.G5_PICK_FEES_F(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
				--DBMS_OUTPUT.PUT_LINE('8th No matches for running G5_PICK_FEES_F, ran it just in case still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
				--' Seconds...for customer ' || Customer);
			END IF;
		Else
			Select (IQ_EOM_REPORTING.F_EOM_CHECK_CUST_LOG(Customer ,'TMP_PICK_FEES','G5_PICK_FEES_F',Op)) INTO v_query_result2 From Dual;--v_query := q'{Select IQ_EOM_REPORTING.EOM_CHECK_LOG(TO_CHAR(end_date,'DD-MON-YY') ,'TMP_ALL_FREIGHT_ALL','F_EOM_TMP_ALL_FREIGHT_ALL') }';--q'{INSERT INTO TMP_EOM_LOGS VALUES (SYSTIMESTAMP ,:startdate,:enddate,'F_EOM_TMP_ALL_FREIGHT_ALL','NONE','TMP_ALL_FREIGHT_ALL',:v_time_taken,SYSTIMESTAMP )  }';
			Select (IQ_EOM_REPORTING.F_EOM_CHECK_LOG(v_tmp_date ,'TMP_PICK_FEES','G5_PICK_FEES_F',Op)) INTO v_query_logfile From Dual;
			If F_IS_TABLE_EEMPTY('TMP_PICK_FEES') <= 0 Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE('8th Need to RUN_ONCE G5_PICK_FEES_F for all customers as table is  empty. cust result was ' || UPPER(v_query_result2) 
					|| ' and this cust was ' ||  UPPER(Customer)
					|| ' and to date was ' ||  UPPER(v_query_logfile)
					|| ' and this date was ' ||  UPPER(v_tmp_date)
					);
				END IF;
				IQ_EOM_REPORTING.G5_PICK_FEES_F(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
			ELSIf UPPER(v_query_result2) != UPPER(Customer) AND UPPER(v_query_result2) IS NOT NULL AND UPPER(v_query_logfile) != UPPER(v_tmp_date) Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE('8th Need to RUN_ONCE G5_PICK_FEES_F for all customers as table is not empty. cust result was ' || UPPER(v_query_result2) 
					|| ' and this cust was ' ||  UPPER(Customer)
					|| ' and to date was ' ||  UPPER(v_query_logfile)
					|| ' and this date was ' ||  UPPER(v_tmp_date)
					);
				END IF;
				IQ_EOM_REPORTING.G5_PICK_FEES_F(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
				--ELSIF UPPER(v_query_result2) = UPPER(Customer) 
				--AND UPPER(v_query_result2) IS NOT NULL 
				--AND UPPER(v_query_logfile) = UPPER(v_tmp_date) Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE('8th No Need to RUN_ONCE G5_PICK_FEES_F for all customers as table is not empty. Last Cust match was ' ||  UPPER(v_query_result2) 
					|| ' and this cust was ' ||  UPPER(Customer)
					|| ' and to date was ' ||  UPPER(v_query_logfile)
					|| ' and this date was ' ||  UPPER(v_tmp_date)
					);
				END IF;
			ELSIf UPPER(v_query_result2) IS NULL OR UPPER(v_query_logfile) IS NULL Then
				If (upper(Debug_Y_OR_N) = 'Y') Then
					DBMS_OUTPUT.PUT_LINE('8th Need to RUN_ONCE G5_PICK_FEES_F for all customers as LOGFILE is missing. cust result was ' || UPPER(v_query_result2) 
					|| ' and this cust was ' ||  UPPER(Customer)
					|| ' and to date was ' ||  UPPER(v_query_logfile)
					|| ' and this date was ' ||  UPPER(v_tmp_date)
					);
				END IF;
				IQ_EOM_REPORTING.G5_PICK_FEES_F(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
			Else
				IQ_EOM_REPORTING.G5_PICK_FEES_F(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
				--DBMS_OUTPUT.PUT_LINE('8th No matches for running G5_PICK_FEES_F, ran it just in case still took ' || (round((dbms_utility.get_time-l_start)/100, 6)) ||
				--' Seconds...for customer ' || Customer);
			END IF;
		End If;
	End If;
	DBMS_OUTPUT.PUT_LINE('.........................................END CHECKPOINT ' || nCheckpoint  || '.............................................');
	
	nCheckpoint := 9;
    If (upper(Inter_Y_OR_No) = 'Y') Then
		EOM_INTERCO_REPORTING.I_EOM_MISC_FEES(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
    Else
		EOM_INTERCO_REPORTING.I_EOM_MISC_FEES(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
    End If;
	DBMS_OUTPUT.PUT_LINE('.........................................END CHECKPOINT ' || nCheckpoint  || '.............................................');	
	
	nCheckpoint := 10;
    If (upper(Inter_Y_OR_No) = 'Y') Then
		EOM_INTERCO_REPORTING.K1_PAL_DESP_FEES(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
    Else
		EOM_INTERCO_REPORTING.K1_PAL_DESP_FEES(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
    End If;
	DBMS_OUTPUT.PUT_LINE('.........................................END CHECKPOINT ' || nCheckpoint  || '.............................................');
	
    nCheckpoint := 11;
    If (upper(Inter_Y_OR_No) = 'Y') Then
		EOM_INTERCO_REPORTING.K2_CTN_IN_FEES(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
	Else
		EOM_INTERCO_REPORTING.K2_CTN_IN_FEES(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
    End If;
	DBMS_OUTPUT.PUT_LINE('.........................................END CHECKPOINT ' || nCheckpoint  || '.............................................');
    
    nCheckpoint := 12;
    If (upper(Inter_Y_OR_No) = 'Y') Then
		EOM_INTERCO_REPORTING.K3_PAL_IN_FEES(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
	Else
		EOM_INTERCO_REPORTING.K3_PAL_IN_FEES(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
    End If;
	DBMS_OUTPUT.PUT_LINE('.........................................END CHECKPOINT ' || nCheckpoint  || '.............................................');
    
    nCheckpoint := 13;
    If (upper(Inter_Y_OR_No) = 'Y') Then
		EOM_INTERCO_REPORTING.K4_CTN_DESP_FEES(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
    Else
		EOM_INTERCO_REPORTING.K4_CTN_DESP_FEES(p_array_size_start,start_date,end_date,Customer,Analysis,FilterBy,Op);
    End If;
	DBMS_OUTPUT.PUT_LINE('.........................................END CHECKPOINT ' || nCheckpoint  || '.............................................');
	
	nCheckpoint := 14;
    If (upper(Inter_Y_OR_No) = 'Y') Then
		If ( Customer = 'VHAAUS' ) Then
			nCheckpoint := 14.1;
			EOM_INTERCO_REPORTING.J_EOM_CUSTOMER_FEES_VHA(p_array_size_start,start_date,end_date,Customer,Op);
		ElsIf ( Customer = 'BEYONDBL' ) Then
			nCheckpoint := 14.2;
			EOM_INTERCO_REPORTING.J_EOM_CUSTOMER_FEES_BB(p_array_size_start,start_date,end_date,Customer,Op);
		ElsIf ( Customer = 'WBC' ) Then
			nCheckpoint := 14.3;
			EOM_INTERCO_REPORTING.J_EOM_CUSTOMER_FEES_WBC(p_array_size_start,start_date,end_date,Customer,Op);
		ElsIf ( Customer = 'TABCORP' ) Then
			nCheckpoint := 14.4;
			EOM_INTERCO_REPORTING.J_EOM_CUSTOMER_FEES_TAB(p_array_size_start,start_date,end_date,Customer,Op);
			--ElsIf ( Customer = 'IAG' ) Then
			--nCheckpoint := 60;
			--IQ_EOM_REPORTING.Z_EOM_RUN_IAG(p_array_size_start,start_date,end_date,'CGU',Analysis);
		End If;
    Else
		If ( Customer = 'VHAAUS' ) Then
			nCheckpoint := 14.1;
			IQ_EOM_REPORTING.J_EOM_CUSTOMER_FEES_VHA(p_array_size_start,start_date,end_date,Customer,Op);
		ElsIf ( Customer = 'BEYONDBL' ) Then
			nCheckpoint := 14.2;
			IQ_EOM_REPORTING.J_EOM_CUSTOMER_FEES_BB(p_array_size_start,start_date,end_date,Customer,Op);
		ElsIf ( Customer = 'WBC' ) Then
			nCheckpoint := 14.3;
			IQ_EOM_REPORTING.J_EOM_CUSTOMER_FEES_WBC(p_array_size_start,start_date,end_date,Customer,Op);
		ElsIf ( Customer = 'TABCORP' ) Then
			nCheckpoint := 14.4;
			IQ_EOM_REPORTING.J_EOM_CUSTOMER_FEES_TAB(p_array_size_start,start_date,end_date,Customer,Op);
			--ElsIf ( Customer = 'IAG' ) Then
			--nCheckpoint := 60;
			--IQ_EOM_REPORTING.Z_EOM_RUN_IAG(p_array_size_start,start_date,end_date,'CGU',Analysis);
		End If;
    End IF;
	DBMS_OUTPUT.PUT_LINE('.........................................END CHECKPOINT ' || nCheckpoint  || '.............................................');
      
	nCheckpoint := 99;
    If (upper(Inter_Y_OR_No) = 'Y') Then
		If (Op = 'PRJ' or Op = 'PRJ_TEST') Then
			v_query := 'TRUNCATE TABLE DEV_ALL_FEES';
		Else
			v_query := 'TRUNCATE TABLE TMP_ALL_FEES';
		End If;
	Else
		If (Op = 'PRJ' or Op = 'PRJ_TEST') Then
			v_query := 'TRUNCATE TABLE DEV_ALL_FEES';
		Else
			v_query := 'TRUNCATE TABLE TMP_ALL_FEES';
		End If;
    End If;
	EXECUTE IMMEDIATE v_query;
	COMMIT;
    
    If (upper(Inter_Y_OR_No) = 'Y') Then
		IQ_EOM_REPORTING.Y_EOM_TMP_MERGE_ALL_FEES2(Op);
    Else
		IQ_EOM_REPORTING.Y_EOM_TMP_MERGE_ALL_FEES2(Op);
    End If;
    DBMS_OUTPUT.PUT_LINE('.........................................END CHECKPOINT ' || nCheckpoint  || '.............................................');
		
	nCheckpoint := 100;
    If (upper(Inter_Y_OR_No) = 'Y') Then
		If (Op = 'PRJ' or Op = 'PRJ_TEST') Then
			v_query := 'TRUNCATE TABLE DEV_ALL_FEES_F';
		Else
			v_query := 'TRUNCATE TABLE TMP_ALL_FEES_F';
		End If;
	Else
		If (Op = 'PRJ' or Op = 'PRJ_TEST') Then
			v_query := 'TRUNCATE TABLE DEV_ALL_FEES_F';
		Else
			v_query := 'TRUNCATE TABLE TMP_ALL_FEES_F';
		End If;
    End If;
	EXECUTE IMMEDIATE v_query;
	COMMIT;
    If (upper(Inter_Y_OR_No) = 'Y') Then
		EOM_INTERCO_REPORTING.Y_EOM_TMP_MERGE_ALL_FEES_FINAL(Customer,Op,Analysis);
    Else
		IQ_EOM_REPORTING.Y_EOM_TMP_MERGE_ALL_FEES_FINAL(Customer,Op);
    End If;
	DBMS_OUTPUT.PUT_LINE('.........................................END CHECKPOINT ' || nCheckpoint  || '.............................................');
	
	nCheckpoint := 101;
	If (upper(Inter_Y_OR_No) = 'Y') Then
		----DBMS_OUTPUT.PUT_LINE('START Z TMP_ALL_FEES for ' || sFileName|| ' saved in ' || sPath );
		If ( Customer = 'V-SUPPAR' ) Then
			nCheckpoint := 101.1;
			EOM_INTERCO_REPORTING.J_EOM_CUSTOMER_FEES_SUP(p_array_size_start,start_date,end_date,Customer,sFileName,Op);
		Else
			EOM_INTERCO_REPORTING.Z1_TMP_ALL_FEES_TO_CSV(sFileName,Op);
		End If;
	Else
		If ( Customer = 'V-SUPPAR' ) Then
			nCheckpoint := 101.2;
			IQ_EOM_REPORTING.J_EOM_CUSTOMER_FEES_SUP(p_array_size_start,start_date,end_date,Customer,sFileName,Op);
		Else
			IQ_EOM_REPORTING.Z1_TMP_ALL_FEES_TO_CSV(sFileName,Op);
		End If;
	End If;
	v_query2 :=  SQL%ROWCOUNT;
	-- --DBMS_OUTPUT.PUT_LINE('Z EOM Successfully Ran EOM_RUN_ALL for ' || Customer|| ' in ' ||(round((dbms_utility.get_time-l_start)/100, 2) ||
	--' Seconds...' );
	v_time_taken := TO_CHAR(TO_NUMBER((round((dbms_utility.get_time-l_start)/100, 6))));
    If (upper(Inter_Y_OR_No) = 'Y') Then
		If (Op = 'PRJ' or Op = 'PRJ_TEST') Then
			EOM_INTERCO_REPORTING.EOM_INSERT_LOG(SYSTIMESTAMP ,sysdate,sysdate,'Z_EOM_RUN_ALL','MERGE','DEV',v_time_taken,SYSTIMESTAMP,Customer);
		Else
			EOM_INTERCO_REPORTING.EOM_INSERT_LOG(SYSTIMESTAMP ,sysdate,sysdate,'Z_EOM_RUN_ALL','MERGE','TMP',v_time_taken,SYSTIMESTAMP,Customer);
		End If;
	Else
		If (Op = 'PRJ' or Op = 'PRJ_TEST') Then
			IQ_EOM_REPORTING.EOM_INSERT_LOG(SYSTIMESTAMP ,sysdate,sysdate,'Z_EOM_RUN_ALL','MERGE','DEV',v_time_taken,SYSTIMESTAMP,Customer);
		Else
			IQ_EOM_REPORTING.EOM_INSERT_LOG(SYSTIMESTAMP ,sysdate,sysdate,'Z_EOM_RUN_ALL','MERGE','TMP',v_time_taken,SYSTIMESTAMP,Customer);
		End If;
	End If;
    --DBMS_OUTPUT.PUT_LINE('LAST EOM Successfully Ran EOM_RUN_ALL for the date range '
	-- || start_date || ' -- ' || end_date || ' - ' || v_query2 || ' records inserted in ' ||  (round((dbms_utility.get_time-l_start)/100, 6) ||
	-- ' Seconds... for customer '|| Customer ));
	DBMS_OUTPUT.PUT_LINE('.........................................END CHECKPOINT ' || nCheckpoint  || '.............................................');	
	COMMIT;
    RETURN;
	EXCEPTION
		WHEN OTHERS THEN
			DBMS_OUTPUT.PUT_LINE('EOM_RUN_ALL failed at checkpoint ' || nCheckpoint || ' with error ' || SQLCODE || ' : ' || SQLERRM);
			RAISE;
	END Z3_EOM_RUN_ALL;

END EOM;