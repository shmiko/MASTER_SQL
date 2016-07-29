/*RUN THIS VIA SQL DEVELOPER or if SQL TOOLS run as SQLPLUS*/
--This will activate the LUX web query - same as per the web page
variable desp_stock_cv refcursor;
exec EOM_REPORT_PKG.get_desp_stocks_curp('RACV','TABCORP','COURIER','COURIERS','3-JUL-2014','3-JUL-2014',:desp_stock_cv);
print desp_stock_cv;


--DESP_STOCK_GET
--variable DESP_STOCK_GET_cv refcursor;
exec EOM_REPORT_PKG.DESP_STOCK_GET('3-JUL-2014','3-JUL-2014','RACV');
--print DESP_STOCK_GET_cv;


variable finance_trans_cv refcursor;
exec EOM_REPORT_PKG.get_finance_transactions_curp('AAMI','1-JUL-2014','16-JUL-2014',:finance_trans_cv);
print finance_trans_cv;

variable finance_soh_cv refcursor;
exec EOM_REPORT_PKG.get_stockonhand_curp('AAMI','MELBOURNE',:finance_soh_cv);
print finance_soh_cv;

--GET_IAGRACV_PDS
variable iagracv_cv refcursor;
exec EOM_REPORT_PKG.GET_IAGRACV_PDS('26-MAY-2014','31-MAY-2014',:iagracv_cv);
print iagracv_cv;

exec EOM_REPORT_PKG.GET_IAGRACV_PDS_DEBUG('5-AUG-2014','5-AUG-2014');



exec DM_CUSTOMER_STORAGE_COUNTS('5-AUG-2014','5-AUG-2014');

  exec F_GET_FEE('RM_XX_FEE15','LUXOTTICA');


variable rate NUMBER
EXEC SELECT F_GET_FEE('RM_XX_FEE15','LUXOTTICA') INTO :rate FROM DUAL;
Print rate;


--GET_IAGRACV_PDS2 doesn't show any neither stocks
variable iagracv_cv refcursor;
exec EOM_REPORT_PKG.GET_IAGRACV_PDS3('8-AUG-2014','8-AUG-2014',:iagracv_cv);
print iagracv_cv;

variable iagracv_cv refcursor;
exec EOM_REPORT_PKG.GET_IAGRACV_PDS_DEBUG2('31-JUL-2014','31-JUL-2014',:iagracv_cv);
print iagracv_cv;

exec EOM_REPORT_PKG.GET_IAGRACV_PDS_DEBUG2('26-MAY-2014','31-JUL-2014');

variable temp_data_cv refcursor;
exec EOM_GET_TEMP_DATA('1-SEP-2014','19-SEP-2014','21VICP',:temp_data_cv);
print temp_data_cv;

--FREIGHT BY CUST and WAREHOUSE
variable desp_freight_cv refcursor;
exec  EOM_REPORT_PKG.get_desp_freight_curp('RTA','COURIER','SYDNEY','1-JUN-2013', '31-May-2014',:desp_freight_cv);
print desp_freight_cv;

--FREIGHT BY NEITHER CUST and WAREHOUSE
variable desp_freight_cv refcursor;
exec  EOM_REPORT_PKG.get_desp_freight_curp(NULL,NULL,'SYDNEY','1-JUN-2013', '31-May-2014',:desp_freight_cv);
print desp_freight_cv

--FREIGHT BY CUST and NOT WAREHOUSE
variable desp_freight_cv refcursor;
exec  EOM_REPORT_PKG.get_desp_freight_curp('RTA',NULL,'SYDNEY','1-JUN-2013', '31-May-2014',:desp_freight_cv);
print desp_freight_cv;


exec EOM_REPORT_PKG_TEST.set_admin_eom_vars('TABCORP','TABCORP',NULL,NULL,55,'RTA','1-JUN-2014','10-JUN-2014');

var freight_zone VARCHAR2(500)
EXEC SELECT EOM_REPORT_PKG.f_GetFreightZone_RTA(6) INTO :freight_zone FROM DUAL;
Print freight_zone;

--test empty locn count
var stock_count_in_locn NUMBER
EXEC SELECT total_soh_by_locn('','S5C12-28','Yes','SYDNEY') INTO :stock_count_in_locn FROM DUAL;
Print stock_count_in_locn;


variable desp_freight_cv refcursor;
EXEC EOM_REPORT_PKG_PROD.OWUSER4(:desp_freight_cv);
Print desp_freight_cv;




var stock_count_in_locn NUMBER
EXEC SELECT total_count_by_locn('','S5C12-28','Yes','SYDNEY') INTO :stock_count_in_locn FROM DUAL;
Print stock_count_in_locn;

var F_GET_PDS_COUNTS_NUM NUMBER
EXEC SELECT F_GET_PDS_COUNTS2('1540507','1-May-2014','31-JUL-2014','IA_STOCK') INTO :F_GET_PDS_COUNTS_NUM FROM DUAL;
Print F_GET_PDS_COUNTS_NUM;

var F_RATE VARCHAR2(10)
EXEC SELECT EOM_REPORT_PKG_PROD.f_Get_Charge_from_SD('RTA',1)INTO :F_RATE FROM DUAL;
Print F_RATE;


var F_GET_PDS_COUNTS_NUM NUMBER
EXEC SELECT EOM_REPORT_PKG.F_GET_PDS_COUNTS('1540507','1-May-2014','31-JUL-2014','IA_STOCK') INTO :F_GET_PDS_COUNTS_NUM FROM DUAL;
Print F_GET_PDS_COUNTS_NUM;


var warehouse VARCHAR2(500)
EXEC SELECT EOM_REPORT_PKG.f_GetWarehouse_from_SD('FLOORS') INTO :warehouse FROM DUAL;
Print warehouse;

variable desp_freight_cv refcursor;
exec get_desp_freight_curp_t('COURIER','SYDNEY','1-May-2014', '31-May-2014',:desp_freight_cv);
print desp_freight_cv;

exec GROUP_CUST_START;




--EXECUTE EOM_REPORT_PKG.GROUP_CUST_START;
EXECUTE EOM_REPORT_PKG.EOM_CREATE_TEMP_DATA_BIND('22NSWP','1-AUG-2014','31-AUG-2014');

variable log_stats_cv refcursor;
EXECUTE EOM_REPORT_PKG_PROD.EOM_CREATE_TEMP_LOG_DATA_VALUE('1-AUG-2014','31-AUG-2014',NULL,NULL,:log_stats_cv);
print log_stats_cv;

--EXECUTE EOM_REPORT_PKG.GROUP_CUST_START; LOCATION DATA
EXECUTE EOM_REPORT_PKG_PROD.eom_create_temp_data_locations('22NSWP','1-AUG-2014','31-AUG-2014');


variable log_stats_cv refcursor;
exec EOM_REPORT_PKG.EOM_CREATE_TEMP_LOG_DATA('1-Jun-2014', '30-Jun-2014',NULL,NULL,:log_stats_cv);
print log_stats_cv;


variable log_stats_cv refcursor;
exec EOM_REPORT_PKG.EOM_CREATE_TEMP_LOG_DATA('1-May-2014', '31-May-2014','RTA','SYDNEY',:log_stats_cv);
print log_stats_cv;


variable log_stats_cv refcursor;
exec EOM_CREATE_TEMP_LOG_DATA_TST2('1-May-2014', '31-May-2014','RTA','SYDNEY',:log_stats_cv);
--exec EOM_CREATE_TEMP_LOG_DATA_TST2('1-May-2014', '31-May-2014',NULL,NULL,:log_stats_cv);
print log_stats_cv;


variable log_stats_cv refcursor;
exec EOM_CREATE_TEMP_LOG_DATA2('1-May-2014', '31-May-2014',NULL,NULL,:log_stats_cv);
print log_stats_cv;



var ord_cnt refcursor
EXEC Select F_DAILY_ORDER_COUNT2() INTO :ord_cnt FROM DUAL;
Print ord_cnt;



variable log_stats_cv refcursor;
exec EOM_CREATE_TEMP_LOG_DATA_TST('1-May-2014', '31-May-2014',NULL,NULL,:log_stats_cv);
print log_stats_cv;


variable log_stats_cv refcursor;
exec EOM_CREATE_TEMP_LOG_DATA_TST('1-May-2014', '31-May-2014','RTA','SYDNEY',:log_stats_cv);
print log_stats_cv;


var stotal_soh_by_stock VARCHAR2(500)
EXEC SELECT EOM_REPORT_PKG_PROD.total_soh_by_stock('ANZ-L2196/1111') INTO :stotal_soh_by_stock FROM DUAL;
Print stotal_soh_by_stock;



