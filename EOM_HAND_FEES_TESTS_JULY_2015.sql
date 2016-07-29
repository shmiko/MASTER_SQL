/* Tests for Handling Fees EOM  100% July 27th 2015*/

/* 1st Test for Handling Fees count  */
SELECT Count(*) FROM TMP_HAND_FEES;

/* 2nd Test for Handling Fees total value  */
SELECT Sum(SELL_EXCL) FROM TMP_HAND_FEES;

/* 3rd Test for Handling Fees Dump  */
SELECT * FROM TMP_HAND_FEES ORDER BY DESPATCHDATE Asc;

/* 1st Test for running all Handling Fees  */
BEGIN
  EOM_REPORT_PKG_TEST.G_EOM_HAND_FEES(100,'01-Jun-2015','30-Jun-2015','VHAAUS','');
END; 
-- should be about 8901 records for a total value of 11159.80
-- RESULT:- AA EOM Handeling Fees for all customers for the date range 01-Jun-2015 -- 30-Jun-2015 -  records inserted in 9.38 Seconds...
-- Confirmed above result 8910/11199.25
