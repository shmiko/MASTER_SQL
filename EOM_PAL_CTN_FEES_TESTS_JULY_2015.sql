/* Tests for Pallet/Carton Fees EOM  100% July 27th 2015*/
   
/* 1st Test for Customer Fees count  */
SELECT Count(*) FROM TMP_PAL_CTN_FEES;

/* 2nd Test for Customer Fees total value  */
SELECT Sum(SELL_EXCL) FROM TMP_PAL_CTN_FEES;

/* 3rd Test for Customer Fees Dump  */
SELECT * FROM TMP_PAL_CTN_FEES ORDER BY DESPATCHDATE Asc;

/* 1st Test for running all Customer Fees  */
BEGIN
  EOM_REPORT_PKG_TEST.K_EOM_PAL_CTN_FEES(100,'01-Jun-2015','30-Jun-2015','RTA','');
END; 
-- should be about 5424 records for a total value of 5545.00
-- RESULT:- Successfully Ran All Customer Specific Fees for the date range 01-Jun-2015 -- 30-Jun-2015 - 0 records inserted in 9.2 Seconds...for customer VHAAUS
-- 
  
 