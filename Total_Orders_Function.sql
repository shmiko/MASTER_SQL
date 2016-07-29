--ORDER.status_code = sh_sh_status
--status_code = sh_status
--tot_sales = tot_orders
--company_id_in = rm.rm_cust
--sales_cur = order_cur
var cust varchar2(20)
exec :cust := 'MAPSTORE'
var status NUMBER
EXEC :status := 0
var start_date varchar2(20)
exec :start_date := To_Date('1-Apr-2014')
var order_limit NUMBER
EXEC :order_limit := 10;



CREATE OR REPLACE FUNCTION tot_orders
  ( rm_cust_in IN rm.rm_cust%TYPE,
  status_in IN sh.sh_status%TYPE:=NULL,
  sh_add_in IN sh.sh_add_date%TYPE)
RETURN NUMBER
IS
  /*Internal  UPPER status code */
  status_int sh.sh_status%TYPE:=Upper(status_in);

  /*Parameterised cursor returns total orders */
  CURSOR order_cur (status_in IN sh.sh_status%TYPE)   IS
    SELECT Count(SH_ORDER)
      FROM SH
    WHERE sh.sh_cust = rm_cust_in
    AND sh_status LIKE status_in
    AND sh.sh_add_date >= sh_add_in; --'01-APR-2014';


    /*Return value for function */
    return_value NUMBER;
BEGIN
  OPEN order_cur (status_int);
  FETCH order_cur INTO return_value;
  IF order_cur%NOTFOUND
  THEN
    CLOSE order_cur;
    RETURN NULL;
  ELSE
    CLOSE order_cur;
    RETURN return_value;
  END IF;
END tot_orders;



PROCEDURE GROUP_CUST_GET AS
    (gc_customer_in IN rm.rm_cust%TYPE)
    CURSOR gc_cur IS
      SELECT r.rm_cust, r.rm_name
      FROM rm r
      WHERE r.rm_cust = gc_customer_in
      ORDER BY r.rm_cust;
    gc_rec gc_cur%ROWTYPE;
  BEGIN
    OPEN gc_cur;
    FETCH gc_cur INTO gc_rec;
    WHILE(gc_cur%FOUND)
    LOOP
      DBMS_OUTPUT.PUT_LINE(gc_rec.rm_cust || ' ' || gc_rec.rm_name);
      FETCH gc_cur INTO gc_rec;
    END LOOP;
    CLOSE gc_cur;
  END GROUP_CUST_GET;

create or replace PROCEDURE OWUSER5(c_test out sys_refcursor) AS
BEGIN
  open c_test for
  select vVM.vm_profile, vVM.vm_name, vVM.vm_surname, vVU.vu_cust, vVU.vu_address
  from PWIN175.vm vVM
    inner join PWIN175.vu vVU on vVU.vu_profile = vVM.vm_profile
  where vVM.vm_profile LIKE '19%';
END OWUSER5;

SELECT RM_NAME ,
  CASE
    WHEN tot_orders(:cust,:status,:start_date) > :order_limit  THEN tot_orders(:cust,:status,:start_date)
    ELSE NULL
    END AS "Todays Orders"
FROM RM
WHERE RM_CUST = :cust

var order_totals NUMBER
exec SELECT  tot_orders(:cust,:status,:start_date) INTO :order_totals FROM DUAL;

var order_totals2 NUMBER
EXEC :order_totals2 := tot_orders(:cust,:status,:start_date);

 var rc2 CURSOR
exec owuser5(:rc2);
 EXECUTE  OWUSER5(1)
