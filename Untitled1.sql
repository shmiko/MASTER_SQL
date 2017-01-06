Connecting to the database PWIN175. TMP as PAUL
1 TRUNCATE TMP_ALL_FEES.
2 TRUNCATE Tmp_Group_Cust.
F_IS_TABLE_EEMPTY --- The count of the Tmp_Group_Cust table is 0
2 Need to run A_EOM_GROUP_CUST(sOp) for all customers as table Tmp_Group_Cust is empty.
F_IS_TABLE_EEMPTY --- The count of the Tmp_Group_Cust table is 76494
2 Ran A_EOM_GROUP_CUST(sOp) for all customers. Table Tmp_Group_Cust has 76494 records.
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
F_IS_TABLE_EEMPTY --- The count of the TMP_ADMIN_DATA_PICK_LINECOUNTS table is 19346
F_IS_TABLE_EEMPTY --- The count of the Tmp_Locn_Cnt_By_Cust table is 15403
4  No Need to RUN_ONCE C_EOM_START_ALL_TEMP_STOR_DATA as Tmp_Locn_Cnt_By_Cust for all customers as table is full of data - saved another 65 seconds. Last Date match was 31/DEC/16 and end date was 31/DEC/16
5 Running F_EOM_TMP_ALL_FREIGHT_ALL & F8_Z_EOM_RUN_FREIGHT for ALL based on to date from EOM logs - v_query_logfile is 31/DEC/16- for end date being 31/DEC/16.
F_IS_TABLE_EEMPTY --- The count of the TMP_STOR_ALL_FEES table is 0
F_IS_TABLE_EEMPTY --- The count of the TMP_STOR_FEES table is 0
6 Running H4_EOM_ALL_STOR_FEES & H4_EOM_ALL_STOR for ALL based on to date from EOM logs - v_query_logfile is 31/DEC/16- for end date being 31/DEC/16 sCust_start was CONNECTVIC and sAnalysis_Start was 21VICP and process was H4_EOM_ALL_STOR_FEES
71 Running E0_ALL_ORD_FEES for ALL based on to date from EOM logs
74 Running E4_STD_ORD_FEES for ALL based on to date from EOM logs
75 Running E5_DESTOY_ORD_FEES for ALL based on to date from EOM logs
81 Running G1_SHRINKWRAP_FEES for ALL based on to date from EOM logs
0 - record count.
82 Running G2_STOCK_FEES for ALL based on to date from EOM logs
84 Running F_EOM_CHECK_CUST_LOG & F_EOM_CHECK_LOG for ALL based on to date from EOM logs
F_IS_TABLE_EEMPTY --- The count of the TMP_HANDLING_FEES table is 0
84 4 Running G4_HANDLING_FEES_F for ALL based on to date from EOM logs as TMP_HANDLING_FEES was empty
F_IS_TABLE_EEMPTY --- The count of the TMP_PICK_FEES table is 0
Process exited.
Disconnecting from the database PWIN175.


DEV as PRJ
Connecting to the database IQ. 
1 TRUNCATE DEV_ALL_FEES.
2 TRUNCATE Dev_Group_Cust.
F_IS_TABLE_EEMPTY --- The count of the Dev_Group_Cust table is 0
2 Need to run A_EOM_GROUP_CUST(sOp) for all customers as table Dev_Group_Cust is empty.
F_IS_TABLE_EEMPTY --- The count of the Dev_Group_Cust table is 76494
2 Ran A_EOM_GROUP_CUST(sOp) for all customers. Table Dev_Group_Cust has 76494 records.
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
F_IS_TABLE_EEMPTY --- The count of the DEV_ADMIN_DATA_PICK_LINECOUNTS table is 19346
F_IS_TABLE_EEMPTY --- The count of the Dev_Locn_Cnt_By_Cust table is 15403
4  No Need to RUN_ONCE C_EOM_START_ALL_TEMP_STOR_DATA as Dev_Locn_Cnt_By_Cust for all customers as table is full of data - saved another 65 seconds. Last Date match was  and end date was 31/DEC/16
5 Running F_EOM_TMP_ALL_FREIGHT_ALL & F8_Z_EOM_RUN_FREIGHT for ALL based on to date from EOM logs - v_query_logfile is - for end date being 31/DEC/16.
PRJ - . And sAnalysis is 21VICP
F_IS_TABLE_EEMPTY --- The count of the DEV_STOR_ALL_FEES table is 0
H4A_EOM_ALL_STOR_FEES Fees FAILED for the date range 01-Dec-2016 -- 31-Dec-2016 - 0 records inserted into table TMP_ALL_STOR_FEES in .4 Seconds...for customer CONNECTVIC
F_IS_TABLE_EEMPTY --- The count of the DEV_STOR_FEES table is 0
6 Running H4_EOM_ALL_STOR_FEES & H4_EOM_ALL_STOR for ALL based on to date from EOM logs - v_query_logfile is - for end date being 31/DEC/16 sCust_start was CONNECTVIC and sAnalysis_Start was 21VICP and process was H4_EOM_ALL_STOR_FEES
71 Running E0_ALL_ORD_FEES for ALL based on to date from EOM logs
74 Running E4_STD_ORD_FEES for ALL based on to date from EOM logs
75 Running E5_DESTOY_ORD_FEES for ALL based on to date from EOM logs
81 Running G1_SHRINKWRAP_FEES for ALL based on to date from EOM logs
0 - record count.
82 Running G2_STOCK_FEES for ALL based on to date from EOM logs
84 Running F_EOM_CHECK_CUST_LOG & F_EOM_CHECK_LOG for ALL based on to date from EOM logs
F_IS_TABLE_EEMPTY --- The count of the DEV_HANDLING_FEES table is 4054
84 4 Running G4_HANDLING_FEES_F for ALL based on to date from EOM logs as DEV_HANDLING_FEES was empty
F_IS_TABLE_EEMPTY --- The count of the DEV_PICK_FEES table is 0
Process exited.
Disconnecting from the database IQ.
