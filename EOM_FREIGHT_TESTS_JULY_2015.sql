/* Tests for Order Fees EOM  100% July 24th 2015*/

/* 1st Test for Order Fees count  */
SELECT Count(*) FROM TMP_ORD_FEES;

/* 2nd Test for Order Fees total value  */
SELECT Sum(SELL_EXCL) FROM TMP_ORD_FEES;
/* 56/$140 */

/* 3rd Test for Order Fees Dump  */
SELECT * /* csv */ FROM TMP_ALL_FREIGHT;

/* 1st Test for running all Order Fees  */
BEGIN
  EOM_REPORT_PKG_TEST.E_EOM_TMP_ALL_ORD_FEES(100,'01-Jun-2015','30-Jun-2015','VHAAUS','');
END; 
-- should be about 56 records for a total value of 140
-- RESULT:- Successfully Ran All Order Fees for the date range 01-Jun-2015 -- 30-Jun-2015 - 56 records inserted in 2.33 Seconds...for customer VHAAUS
-- Confirmed above result 56/140
