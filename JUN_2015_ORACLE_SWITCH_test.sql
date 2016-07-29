/*  1st IC Test 22NSWP   */
--1212121

  /*  Run validated PL/SQL and then SQLPlus script  */
  EXECUTE EOM_REPORT_PKG_PROD.EOM_CREATE_TEMP_DATA_BIND('22NSWP','1-JUN-2015','30-JUN-2015');
  THEN RUN AdminEOMMasterLINKVIC.sql
  CHECK tbl_AdminData -Dump TO excel
  CHECK exlusive, unit price, qty
  START_TIME:
  END_TIME:
  RUN_TIME:
  /*  Run new PL/SQL  */
  EXECUTE EOM_REPORT_PKG_TEST.Z_EOM_RUN_ALL('1-JUN-2015','30-JUN-2015','','22NSWP');
  CHECK TMP_ALL_FEES -Dump TO excel
  CHECK exlusive, unit price, qty
  START_TIME:
  END_TIME:
  RUN_TIME:
  /*  Compare to Dynamic Admin Order  */
  CHECK exlusive, unit price, qty




/*  2nd Cust Test BEYONDBLUE   */

  /*  Run validated PL/SQL and then SQLPlus script  */
  EXECUTE EOM_REPORT_PKG_PROD.EOM_CREATE_TEMP_DATA_BIND('75','1-JUN-2015','30-JUN-2015');
  THEN RUN AdminEOMMaster2015All.sql
  CHECK tbl_AdminData -Dump TO excel
  CHECK exlusive, unit price, qty
  START_TIME:
  END_TIME:
  RUN_TIME:
  /*  Run new PL/SQL  */
  EXECUTE EOM_REPORT_PKG_TEST.Z_EOM_RUN_ALL('1-JUN-2015','30-JUN-2015','BEYONDBLUE','');
  CHECK TMP_ALL_FEES -Dump TO excel
  CHECK exlusive, unit price, qty
  START_TIME:
  END_TIME:
  RUN_TIME:
  /*  Compare to Dynamic Admin Order  */
  CHECK exlusive, unit price, qty




/*  3rd Cust Test COL_KMART   */

  /*  Run validated PL/SQL and then SQLPlus script  */
  EXECUTE EOM_REPORT_PKG_PROD.EOM_CREATE_TEMP_DATA_BIND('21VICP','1-JUN-2015','30-JUN-2015');
  THEN RUN AdminEOMMaster2015All.sql
  CHECK tbl_AdminData -Dump TO excel
  CHECK exlusive, unit price, qty
  START_TIME:
  END_TIME:
  RUN_TIME:
  /*  Run new PL/SQL  */
  EXECUTE EOM_REPORT_PKG_TEST.Z_EOM_RUN_ALL('1-JUN-2015','30-JUN-2015','COL_KMART','');
  CHECK TMP_ALL_FEES -Dump TO excel
  CHECK exlusive, unit price, qty
  START_TIME:
  END_TIME:
  RUN_TIME:
  /*  Compare to Dynamic Admin Order  */
  CHECK exlusive, unit price, qty




/*  4th Cust Test HOMTIM   */

  /*  Run validated PL/SQL and then SQLPlus script  */
  EXECUTE EOM_REPORT_PKG_PROD.EOM_CREATE_TEMP_DATA_BIND('21VICP','1-JUN-2015','30-JUN-2015');
  THEN RUN AdminEOMMaster2015All.sql
  CHECK tbl_AdminData -Dump TO excel
  CHECK exlusive, unit price, qty
  START_TIME:
  END_TIME:
  RUN_TIME:
  /*  Run new PL/SQL  */
  EXECUTE EOM_REPORT_PKG_TEST.Z_EOM_RUN_ALL('1-JUN-2015','30-JUN-2015','HOMTIM','');
  CHECK TMP_ALL_FEES -Dump TO excel
  CHECK exlusive, unit price, qty
  START_TIME:
  END_TIME:
  RUN_TIME:
  /*  Compare to Dynamic Admin Order  */
  CHECK exlusive, unit price, qty




/*  5th IC Test 21VICP   */

  /*  Run validated PL/SQL and then SQLPlus script  */
  EXECUTE EOM_REPORT_PKG_PROD.EOM_CREATE_TEMP_DATA_BIND('21VICP','1-JUN-2015','30-JUN-2015');
  THEN RUN AdminEOMMaster2015All.sql
  CHECK tbl_AdminData -Dump TO excel
  CHECK exlusive, unit price, qty
  START_TIME:
  END_TIME:
  RUN_TIME:
  /*  Run new PL/SQL  */
  EXECUTE EOM_REPORT_PKG_TEST.Z_EOM_RUN_ALL('1-JUN-2015','30-JUN-2015','','21VICP');
  CHECK TMP_ALL_FEES -Dump TO excel
  CHECK exlusive, unit price, qty
  START_TIME:
  END_TIME:
  RUN_TIME:
  /*  Compare to Dynamic Admin Order  */
  CHECK exlusive, unit price, qty
