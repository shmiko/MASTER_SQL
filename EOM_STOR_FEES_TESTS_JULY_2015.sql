/* Tests for Storage Fees EOM  100% July 27th 2015*/
/* Need to add slow moving fees  */
/* Need to add secured storage fees  */
/* Need to add slow secured fees  */   

/* 1st Test for Storage Fees count  */
SELECT Count(*) FROM TMP_STOR_FEES;

/* 2nd Test for Storage Fees total value  */
SELECT Sum(SELL_EXCL) FROM TMP_STOR_FEES;

/* 3rd Test for Storage Fees Dump  */
SELECT * FROM TMP_STOR_FEES ORDER BY DESPATCHDATE Asc;

/* Check required table populated by part B of EOM process  */
/* Add a check to see that the table has data and is relevant to the client being reported.  */
SELECT * FROM Tmp_Locn_Cnt_By_Cust;

/* 1st Test for running all Storage Fees  */
BEGIN
  EOM_REPORT_PKG_TEST.H_EOM_STOR_FEES(100,'01-Jun-2015','30-Jun-2015','VHAAUS','');
END; 
-- should be about 5424 records for a total value of 5545.00
-- RESULT:- AA EOM Handeling Fees for all customers for the date range 01-Jun-2015 -- 30-Jun-2015 -  records inserted in 9.38 Seconds...
-- Confirmed above result 1657/11199.25
