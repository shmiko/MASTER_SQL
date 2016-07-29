/* Tests for Customer Fees EOM  100% July 27th 2015*/
   
/* 1st Test for Customer Fees count  */
SELECT Count(*) FROM TMP_CUSTOMER_FEES;

/* 2nd Test for Customer Fees total value  */
SELECT Sum(SELL_EXCL) FROM TMP_CUSTOMER_FEES;

/* 3rd Test for Customer Fees Dump  */
SELECT * FROM TMP_CUSTOMER_FEES ORDER BY DESPATCHDATE Asc;

/* 1st Test for running all Customer Fees  */
BEGIN
  EOM_REPORT_PKG_TEST.J_EOM_CUSTOMER_FEES(100,'01-Jun-2015','30-Jun-2015','RTA','');
  EOM_REPORT_PKG_TEST.J_EOM_CUSTOMER_BB(100,'01-Jun-2015','30-Jun-2015','BEYONDBLUE','');
  EOM_REPORT_PKG_TEST.J_EOM_CUSTOMER_TAB(100,'01-Jun-2015','30-Jun-2015','TABCORP','');
  EOM_REPORT_PKG_TEST.J_EOM_CUSTOMER_VHA(100,'01-Jun-2015','30-Jun-2015','VHAAUS','');
END; 
-- should be about 5424 records for a total value of 5545.00
-- RESULT:- Successfully Ran All Customer Specific Fees for the date range 01-Jun-2015 -- 30-Jun-2015 - 0 records inserted in 9.2 Seconds...for customer VHAAUS
-- 
  
 