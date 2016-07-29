/* Tests for ALL Fees EOM  100% July 27th 2015*/
   
/* 1st Test for ALL Fees count  */
SELECT Count(*) FROM TMP_ALL_FEES;

/* 2nd Test for ALL Fees total value  */
SELECT Sum(SELL_EXCL) FROM TMP_ALL_FEES;

/* 3rd Test for ALl Fees Dump  */
SELECT * FROM TMP_ALL_FEES ORDER BY DESPATCHDATE Asc;

/* 1st Test for running all Fees  */
BEGIN
  EOM_REPORT_PKG_TEST.Y_EOM_TMP_MERGE_ALL_FEES();
END; 
-- should be about 5424 records for a total value of 5545.00
-- RESULT:- .44 Seconds...
-- EOM Merge All Fees for all customer for the date range
-- 
  
 