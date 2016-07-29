set heading on
set pages 10000
set lines 10000
set trimspool on
set feedback off
spool \\sitfshom01\PROD\host_files\IS\PWCImport\AdminOrders\temp2.csv
SELECT * /* csv */ FROM TMP_ALL_FEES WHERE customer = 'FES_226096' ORDER BY DESPATCHDATE Asc;
spool off
