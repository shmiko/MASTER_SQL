/* Tests for Misc Fees EOM  100% July 27th 2015*/
   
/* 1st Test for Misc Fees count  */
SELECT Count(*) FROM TMP_MISC_FEES;

/* 2nd Test for Misc Fees total value  */
SELECT Sum(SELL_EXCL) FROM TMP_MISC_FEES;

/* 3rd Test for Misc Fees Dump  */
SELECT * FROM TMP_MISC_FEES ORDER BY DESPATCHDATE Asc;

/* 1st Test for running all Misc Fees  */
BEGIN
  EOM_REPORT_PKG_TEST.I_EOM_MISC_FEES(100,'01-Jun-2015','30-Jun-2015','VHAAUS','');
END; 
-- should be about 5424 records for a total value of 5545.00
-- RESULT:- Successfully Ran All Misc Fees for the date range 01-Jun-2015 -- 30-Jun-2015 - 0 records inserted in 10.56 Seconds...for customer VHAAUS
-- 
