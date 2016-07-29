--ORDER.status_code = sh_sh_status
--status_code = sh_status
--tot_sales = tot_orders
--company_id_in = rm.rm_cust
--sales_cur = order_cur
var cust varchar2(20)
exec :cust := 'WAGVICAG'
var status NUMBER
EXEC :status := 0
var start_date varchar2(20)
exec :start_date := To_Date('1-Apr-2014')
var order_limit NUMBER
EXEC :order_limit := 10;
var break_price NUMBER
EXEC :break_price := 0;
var s_query VARCHAR2(200)
EXEC :s_query := 'SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = stock_in AND vIICust = rm_cust_in';

CREATE OR REPLACE FUNCTION BREAK_UNIT_PRICE
                  ( rm_cust_in IN rm.RM_GROUP_CUST%TYPE,
                    stock_in   IN Tmp_Admin_Data_BreakPrices.vIIStock%TYPE)
RETURN NUMBER
IS
  /*Internal  UPPER status code */
  --status_int sh.sh_status%TYPE:=Upper(status_in);

  /*Parameterised cursor returns total orders */
  CURSOR break_price_cur IS
    SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = stock_in AND vIICust = rm_cust_in;


    /*Return value for function */
    return_value NUMBER;
BEGIN
  OPEN break_price_cur;
  FETCH break_price_cur INTO return_value;
  IF break_price_cur%NOTFOUND
  THEN
    CLOSE break_price_cur;
    RETURN NULL;
  ELSE
    CLOSE break_price_cur;
    RETURN return_value;
  END IF;
END BREAK_UNIT_PRICE;




SELECT II_BREAK_LCL ,
  CASE
    WHEN BREAK_UNIT_PRICE('WAGVICAG','500400') > :order_limit  THEN BREAK_UNIT_PRICE('WAGVICAG','500400')
    ELSE NULL
    END AS "Break Price"
FROM II
WHERE II_CUST = :cust
AND II_STOCK = '500400'

var breakprice NUMBER
exec SELECT  BREAK_UNIT_PRICE('WAGVICAG','500400') INTO :breakprice FROM DUAL;

var order_totals2 NUMBER
EXEC :order_totals2 := tot_orders(:cust,:status,:start_date);

EXECUTE BREAK_UNIT_PRICE('WAGVICAG','500400')







SELECT * FROM II WHERE II_CUST = :cust
