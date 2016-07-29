var cust varchar2(20)
exec :cust := '21BUDGET'
var status NUMBER
EXEC :status := 0
var start_date varchar2(20)
exec :start_date := To_Date('7-Apr-2014')
var order_limit NUMBER
EXEC :order_limit := 1;



--Get TotalDespatches for day for cust

CREATE OR REPLACE  FUNCTION total_despatches
    ( d_rm_cust_in IN rm.rm_cust%TYPE,
    d_status_in IN sh.sh_status%TYPE:=NULL,
    st_add_in IN st.st_desp_date%TYPE)
  RETURN NUMBER
  IS
    --Internal  UPPER status code
    status_int2 sh.sh_status%TYPE:=Upper(d_status_in);

    --Parameterised cursor returns total orders
    CURSOR desp_cur (status_in IN sh.sh_status%TYPE)   IS
      SELECT Count(SH_ORDER)
        FROM ST,SH
      WHERE ST_ORDER = SH_ORDER
      AND sh.sh_cust = d_rm_cust_in
      AND sh_status NOT LIKE d_status_in
      AND st.st_desp_date >= st_add_in;


      --Return value for function
      return_desp_value NUMBER;
  BEGIN
    OPEN desp_cur (status_int2);
    FETCH desp_cur INTO return_desp_value;
    IF desp_cur%NOTFOUND
    THEN
      CLOSE desp_cur;
      RETURN NULL;
    ELSE
      CLOSE desp_cur;
      RETURN return_desp_value;
    END IF;
  END total_despatches;



SELECT RM_NAME ,
  CASE
    WHEN total_despatches(:cust,:status,:start_date) > :order_limit  THEN total_despatches(:cust,:status,:start_date)
    ELSE NULL
    END AS "Todays Orders"
FROM RM
WHERE RM_CUST = :cust

var total_despatches NUMBER
exec SELECT  total_despatches(:cust,:status,:start_date) INTO :total_despatches FROM DUAL;

var total_despatches2 NUMBER
EXEC :total_despatches := total_despatches(:cust,:status,:start_date);
