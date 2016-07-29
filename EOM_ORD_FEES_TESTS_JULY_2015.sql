/* Tests for Order Fees EOM  100% July 24th 2015*/

/* 1st Test for Order Fees count  */
SELECT Count(*) FROM TMP_ORD_FEES;

/* 2nd Test for Order Fees total value  */
SELECT Sum(SELL_EXCL) FROM TMP_ORD_FEES;

/* 3rd Test for Order Fees Dump  */
SELECT * FROM TMP_ORD_FEES ORDER BY DESPATCHDATE Asc;

/* 1st Test for running all Order Fees  */
BEGIN
  EOM_REPORT_PKG_TEST.F_EOM_TMP_ALL_ORD_FEES(100,'01-Jun-2015','30-Jun-2015','VHAAUS','');
END; 
-- should be about 50 records for a total value of 1014.52
-- RESULT:- AA EOM Temp AUTO Freight for all customers for the date range 01-Jun-2015 -- 30-Jun-2015 - 50 records inserted in 1.86 Seconds...
-- Confirmed above result 50/1014.52
