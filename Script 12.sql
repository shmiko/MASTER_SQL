CREATE OR REPLACE TYPE myBrandType AS OBJECT
  (brand_tx VARCHAR2(10), desc_tx VARCHAR2(25))
  /

CREATE OR REPLACE TYPE myBrandTableType AS TABLE OF myBrandType
/

CREATE OR REPLACE FUNCTION f_getDisplay_oty
	(i_column_tx VARCHAR2,
   i_column2_tx VARCHAR2,
	 i_table_select_tx VARCHAR2,
	 i_field_tx VARCHAR2,
   i_value_tx NUMBER)
	RETURN myBrandTableType
	IS
		v_out_tx myBrandTableType;
		v_sql_tx VARCHAR2(2000);
	BEGIN
    v_out_tx := myBrandTableType();
		v_sql_tx := 'SELECT lov_oty('||
		            i_column_tx||','||i_column2_tx||
		            ') FROM '||i_table_select_tx||
		            ' WHERE '||i_column_tx||' =:5';
	EXECUTE IMMEDIATE v_sql_tx INTO v_out_tx
		USING i_value_tx;
	RETURN v_out_tx;
  DBMS_OUTPUT.PUT_LINE(i_value_tx);
END f_getDisplay_oty;


CREATE OR REPLACE FUNCTION f_getDisplay_oty
	(i_column_tx VARCHAR2,
   i_column2_tx VARCHAR2,
	 i_table_select_tx VARCHAR2,
	 i_field_tx VARCHAR2,
   i_value_tx NUMBER)
	RETURN VARCHAR2
	IS
		v_out_tx VARCHAR2(2000);
		v_sql_tx VARCHAR2(2000);
	BEGIN
		v_sql_tx := 'SELECT lov_oty('||
		            'IR_BRAND,'||i_column2_tx||
		            ') FROM '||i_table_select_tx||
		            --' WHERE '||i_column_tx||' =:5';
                'WHERE ID = 155';
	EXECUTE IMMEDIATE v_sql_tx INTO v_out_tx
		USING i_value_tx;
	RETURN v_out_tx;
END f_getDisplay_oty;



CREATE OR REPLACE FUNCTION f_getDisplay_oty
	(i_column_tx VARCHAR2,
   i_column2_tx VARCHAR2,
	 i_table_select_tx VARCHAR2,
	 i_field_tx VARCHAR2,
   i_value_tx NUMBER)
	RETURN VARCHAR2
	IS
		v_out_tx VARCHAR2(2000);
		v_sql_tx VARCHAR2(2000);
	BEGIN
	EXECUTE IMMEDIATE 'SELECT myBrandType(IR_BRAND,IR_DESC) FROM IR WHERE IR_BRAND = ''AAS_ACIRT''' INTO v_out_tx
		USING i_value_tx;
	RETURN v_out_tx;
END f_getDisplay_oty;

var total_despatches2_tx VARCHAR2(500)
EXEC SELECT f_getDisplay_oty('ID','IR_DESC','IR','IR_BRAND',155) INTO :total_despatches2_tx FROM DUAL;



CREATE OR REPLACE TYPE provider.user_rec IS OBJECT (
        id NUMBER(10, 0),
        name VARCHAR2(200),
        login VARCHAR2(40)
);

CREATE OR REPLACE FUNCTION provider.get_user(p_id IN NUMBER) RETURN user_rec IS
        ret user_rec;
BEGIN
        SELECT user_rec(
                        u.id,
                        u.name,
                        u.login
                  )
        INTO ret
        FROM users u
        WHERE u.id = p_id;

        RETURN ret;
END;

CREATE OR REPLACE PROCEDURE consume.test_get_user IS
    user user_rec;
BEGIN
    user := get_user(1);
    dbms_output.put_line(user.name);
END;


DEFINE lov_oty


--Returning Data from a Dynamic Query into a Record

CREATE OR REPLACE PROCEDURE obtain_job_info(min_sal NUMBER DEFAULT 0,
  max_sal NUMBER DEFAULT 0)
AS
  sql_text VARCHAR2(1000);
  TYPE job_tab IS TABLE OF jobs%ROWTYPE;
  job_list job_tab;
  job_elem jobs%ROWTYPE;
  max_sal_temp NUMBER;
  filter_flag BOOLEAN := FALSE;
  cursor_var NUMBER;
  TYPE cur_type IS REF CURSOR;
  cur cur_type;
BEGIN
  sql_text := 'SELECT * ' ||
              'FROM JOBS WHERE ' ||
              'min_salary >= :min_sal ' ||
              'and max_salary <= :max_sal';
  IF max_sal = 0 THEN
    SELECT max(max_salary)
    INTO max_sal_temp
    FROM JOBS;
  ELSE
    max_sal_temp := max_sal;
  END IF;
  OPEN cur FOR sql_text USING min_sal, max_sal_temp;
  FETCH cur BULK COLLECT INTO job_list;
  CLOSE cur;
  FOR i IN job_list.FIRST .. job_list.LAST LOOP
    DBMS_OUTPUT.PUT_LINE(job_list(i).job_id || ' - ' || job_list(i).job_title);
  END LOOP;
END;









/*
BEGIN
 EOM_REPORT_PKG.DESP_STOCK_GET('01-APR-2014','15-APR-2014','RTA');
END;



BEGIN
 get_desp_stocks('RTA','TABCORP',1080105,'COURIER','COURIERS','2014-04-01','2014-04-15');
END;

BEGIN
 get_desp_stocks('RTA','TABCORP',1080105,'COURIER','COURIERS','2-APR-2014','14-APR-2014');
END;

*/

var cust2 varchar2(20)
exec :cust2 := 'LUXOTTICA'
var nx NUMBER
EXEC :nx := 1810105
var cust varchar2(20)
exec :cust := 'LUXOTTICA'
var ordernum varchar2(20)
exec :ordernum := '1363806'
var stock varchar2(20)
exec :stock := 'COURIER'
var source varchar2(20)
exec :source := 'BSPRINTNSW'
var sAnalysis varchar2(20) /*VerbalOrderEntryFee*/
exec SELECT  RM_ANAL INTO :sAnalysis FROM RM where RM_CUST = :cust;
var anal varchar2(20)
exec :anal := '49'
var start_date varchar2(20)
exec :start_date := To_Date('16-Apr-2014')
var end_date varchar2(20)
exec :end_date := To_Date('22-Apr-2014')


	SELECT    s.SH_CUST
			         ,s.SH_ORDER
		           ,substr(To_Char(t.ST_DESP_DATE),0,10)
	             ,d.SD_STOCK
			         ,d.SD_DESC
			        , CASE  WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> :cust2   AND i.IM_OWNED_BY = 0 THEN d.SD_SELL_PRICE
			                WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> :cust2   AND i.IM_OWNED_BY = 1 THEN n.NI_SELL_VALUE/n.NI_NX_QUANTITY
                      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = :cust2   AND eom_report_pkg.F_BREAK_UNIT_PRICE2(r.RM_GROUP_CUST,d.SD_STOCK) IS NOT NULL THEN eom_report_pkg.F_BREAK_UNIT_PRICE2(r.RM_GROUP_CUST,d.SD_STOCK)
			                WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = :cust2   AND eom_report_pkg.F_BREAK_UNIT_PRICE2(r.RM_GROUP_CUST,d.SD_STOCK) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			                ELSE NULL
			                END AS UnitPrice
		           ,i.IM_BRAND
 FROM      PWIN175.SD d
			  RIGHT JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  LEFT JOIN PWIN175.ST t  ON t.ST_PICK  = d.SD_LAST_PICK_NUM
        LEFT JOIN PWIN175.SL l   ON l.SL_PICK   = t.ST_PICK
			  INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
        INNER JOIN PWIN175.NI n  ON n.NI_NV_EXT_KEY = l.SL_UID

 WHERE n.NI_NV_EXT_TYPE = :nx AND n.NI_STRENGTH = 3 AND n.NI_DATE = t.ST_DESP_DATE AND n.NI_STOCK = d.SD_STOCK AND n.NI_STATUS <> 0
	AND     s.SH_STATUS <> 3
  AND     i.IM_CUST IN (:cust)
	AND       s.SH_ORDER = t.ST_ORDER
	--AND       d.SD_STOCK NOT IN (:stock,:stock2)
  AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
	AND       d.SD_LAST_PICK_NUM = t.ST_PICK
	GROUP BY  s.SH_CUST,s.SH_ORDER,
			      t.ST_DESP_DATE,
			      d.SD_DESC,d.SD_STOCK,d.SD_XX_OW_UNIT_PRICE,d.SD_SELL_PRICE,
            i.IM_BRAND,i.IM_OWNED_BY,i.IM_CUST,
            n.NI_SELL_VALUE,n.NI_NX_QUANTITY
            ,r.RM_GROUP_CUST;
            --gds_rec gds_src_get_desp_stocks%ROWTYPE;


/*
BEGIN
 EOM_REPORT_PKG.DESP_STOCK_GET('01-APR-2014','15-APR-2014','RTA');
END;



BEGIN
 get_desp_stocks('RTA','TABCORP',1080105,'COURIER','COURIERS','2014-04-01','2014-04-15');
END;

BEGIN
 get_desp_stocks('RTA','TABCORP',1080105,'COURIER','COURIERS','2-APR-2014','14-APR-2014');
END;

*/
	SELECT    SH.SH_CUST
			         ,SH.SH_ORDER
		           ,substr(To_Char(ST.ST_DESP_DATE),0,10)
	             ,SD.SD_STOCK
			         ,SD.SD_DESC
			        , CASE  WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> 'TABCORP'   AND IM.IM_OWNED_BY = 0 THEN SD.SD_SELL_PRICE
			                WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> 'TABCORP'   AND IM.IM_OWNED_BY = 1 THEN NI.NI_SELL_VALUE/NI_NX_QUANTITY
                      WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = 'TABCORP'   AND eom_report_pkg.F_BREAK_UNIT_PRICE2(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NOT NULL THEN eom_report_pkg.F_BREAK_UNIT_PRICE2(RM_GROUP_CUST,SD_STOCK)
			                WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = 'TABCORP'   AND eom_report_pkg.F_BREAK_UNIT_PRICE2(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NULL THEN  SD_XX_OW_UNIT_PRICE
			                ELSE NULL
			                END
		           ,IM.IM_BRAND
	FROM  PWIN175.SD
			  RIGHT JOIN PWIN175.SH  ON SH.SH_ORDER  = SD.SD_ORDER
			  LEFT JOIN PWIN175.ST  ON ST.ST_PICK  = SD.SD_LAST_PICK_NUM
        LEFT JOIN PWIN175.SL   ON SL.SL_PICK   = ST.ST_PICK
			  INNER JOIN PWIN175.RM  ON RM.RM_CUST  = SH.SH_CUST
			  INNER JOIN PWIN175.IM  ON IM.IM_STOCK = SD.SD_STOCK
        INNER JOIN PWIN175.NI  ON NI.NI_NV_EXT_KEY = SL.SL_UID
  WHERE  NI.NI_STRENGTH = 3 AND NI.NI_DATE = ST.ST_DESP_DATE AND NI.NI_STOCK = SD_STOCK AND NI.NI_STATUS <> 0
	AND     SH.SH_STATUS <> 3
  AND     IM.IM_CUST in ('LUXOTTICA') --IN (gds_cust_in)
	AND       SH.SH_ORDER = ST.ST_ORDER
 -- AND       ST.ST_DESP_DATE >= gds_start_date_in AND ST.ST_DESP_DATE <= gds_end_date_in
 	AND       ST.ST_DESP_DATE >=  To_Date('1-Apr-2014') AND ST.ST_DESP_DATE <=  To_Date('16-Apr-2014')

	AND       SD.SD_LAST_PICK_NUM = ST.ST_PICK
	GROUP BY  SH.SH_CUST,SH.SH_ORDER,
			      ST.ST_DESP_DATE,
			      SD.SD_DESC,SD.SD_STOCK,SD.SD_XX_OW_UNIT_PRICE,SD.SD_SELL_PRICE,
            IM.IM_BRAND,IM.IM_OWNED_BY,IM.IM_CUST,
            NI.NI_SELL_VALUE,NI.NI_NX_QUANTITY,
            RM.RM_GROUP_CUST;
            --gds_rec gds_src_get_desp_stocks%ROWTYPE;



 BEGIN
  eom_report_pkg.get_desp_stocks('LUXOTTICA','TABCORP',1080105,'COURIER','COURIERS','20-APR-2014','28-APR-2014');
END;
BEGIN
  eom_report_pkg.get_desp_stocks('LUXOTTICA','TABCORP','COURIER','COURIERS','13-APR-2014','28-APR-2014');
END;






CREATE OR REPLACE FUNCTION f_getDisplay_from_type_bind
     (i_first_col IN VARCHAR2,
   i_value_tx IN VARCHAR2
   )
     RETURN myBrandType
     IS
          v_out_tx myBrandType;
          v_sql_tx VARCHAR2(2000);
     BEGIN
    v_sql_tx := ' SELECT myBrandType ( '||i_first_col||',' ||
                   '    u.IR_DESC '||
                  ') FROM IR u '||
                   ' WHERE u.IR_BRAND = :5';

     EXECUTE IMMEDIATE v_sql_tx INTO v_out_tx
     USING i_value_tx;
        RETURN v_out_tx;
END f_getDisplay_from_type_bind;


CREATE OR REPLACE PROCEDURE test_get_brand IS
  brand myBrandType;
BEGIN
  brand := f_getDisplay_from_type_bind ('u.IR_BRAND','AAS');
  DBMS_OUTPUT.PUT_LINE(brand.brand_tx|| ' - ' ||brand.desc_tx);
END;

EXEC test_get_brand ();


CREATE OR REPLACE PROCEDURE myproc_test_via_PHP(p1 IN NUMBER, p2 IN OUT NUMBER) AS
BEGIN
  p2 := p1 * 2;
END;

EXEC  myproc_test_via_PHP(8,1);


SELECT * FROM IR WHERE IR_BRAND LIKE 'AAS%'



CREATE OR REPLACE PROCEDURE get_desp_stocks_cur (
			gds_cust_in IN IM.IM_CUST%TYPE,
			gds_cust_not_in IN  IM.IM_CUST%TYPE,
			--gds_nx_ext_type_in IN NI.NI_NV_EXT_TYPE%TYPE,
			gds_stock_not_in IN IM.IM_STOCK%TYPE,
			gds_stock_not_in2 IN IM.IM_STOCK%TYPE,
			gds_start_date_in IN SH.SH_EDIT_DATE%TYPE,
			gds_end_date_in IN SH.SH_ADD_DATE%TYPE,
			gds_src_get_desp_stocks OUT sys_refcursor
)
AS
BEGIN
      OPEN gds_src_get_desp_stocks FOR

	SELECT    SH.SH_CUST
			         ,SH.SH_ORDER
		           ,substr(To_Char(ST.ST_DESP_DATE),0,10)
	             ,SD.SD_STOCK
			         ,SD.SD_DESC
			        ,CASE  WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in   AND IM.IM_OWNED_BY = 0 THEN SD.SD_SELL_PRICE
			                WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in   AND IM.IM_OWNED_BY = 1 THEN NI.NI_SELL_VALUE/NI_NX_QUANTITY
                      WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in   AND eom_report_pkg.F_BREAK_UNIT_PRICE2(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NOT NULL THEN eom_report_pkg.F_BREAK_UNIT_PRICE2(RM_GROUP_CUST,SD_STOCK)
			                WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in   AND eom_report_pkg.F_BREAK_UNIT_PRICE2(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NULL THEN  SD_XX_OW_UNIT_PRICE
			                ELSE NULL
			                END AS "Price"
		           ,IM.IM_BRAND
	FROM  PWIN175.SD
			  RIGHT JOIN PWIN175.SH  ON SH.SH_ORDER  = SD.SD_ORDER
			  LEFT JOIN PWIN175.ST  ON ST.ST_PICK  = SD.SD_LAST_PICK_NUM
        LEFT JOIN PWIN175.SL   ON SL.SL_PICK   = ST.ST_PICK
			  INNER JOIN PWIN175.RM  ON RM.RM_CUST  = SH.SH_CUST
			  INNER JOIN PWIN175.IM  ON IM.IM_STOCK = SD.SD_STOCK
        INNER JOIN PWIN175.NI  ON NI.NI_NV_EXT_KEY = SL.SL_UID
  WHERE NI.NI_STRENGTH = 3 AND NI.NI_DATE = ST.ST_DESP_DATE AND NI.NI_STOCK = SD_STOCK AND NI.NI_STATUS <> 0
	AND     SH.SH_STATUS <> 3
  AND     IM.IM_CUST IN (gds_cust_in)
	AND       SH.SH_ORDER = ST.ST_ORDER
  AND       ST.ST_DESP_DATE >= gds_start_date_in AND ST.ST_DESP_DATE <= gds_end_date_in
 	--AND       ST.ST_DESP_DATE >= '10-APR-2014' AND ST.ST_DESP_DATE <= '15-APR-2014'

	AND       SD.SD_LAST_PICK_NUM = ST.ST_PICK
	GROUP BY  SH.SH_CUST,SH.SH_ORDER,
			      ST.ST_DESP_DATE,
			      SD.SD_DESC,SD.SD_STOCK,SD.SD_XX_OW_UNIT_PRICE,SD.SD_SELL_PRICE,
            IM.IM_BRAND,IM.IM_OWNED_BY,IM.IM_CUST,
            NI.NI_SELL_VALUE,NI.NI_NX_QUANTITY,
            RM.RM_GROUP_CUST;
   /*         gds_rec gds_src_get_desp_stocks%ROWTYPE;
  BEGIN
    OPEN  gds_src_get_desp_stocks;
    FETCH gds_src_get_desp_stocks INTO  gds_rec;
    WHILE gds_src_get_desp_stocks%FOUND
    LOOP
      Dbms_Output.PUT_LINE('Row: '||gds_src_get_desp_stocks%ROWCOUNT||' # '|| gds_rec.SH_ORDER);
      FETCH gds_src_get_desp_stocks INTO gds_rec;
    END LOOP;
    CLOSE gds_src_get_desp_stocks;
    Dbms_Output.PUT_LINE('finished for cust '||gds_cust_in );    */
 END get_desp_stocks_cur;





DECLARE
 des_cur EOM_REPORT_PKG.stock_ref_cur%TYPE;
BEGIN
  eom_report_pkg.get_desp_stocks_cur_p('LUXOTTICA','TABCORP','COURIER','COURIERS','13-APR-2014','28-APR-2014',:des_cur);
END;

EXEC get_desp_stocks_cur_p('LUXOTTICA','TABCORP','COURIER','COURIERS','13-APR-2014','28-APR-2014',:des_cur);

DECLARE
desp_stock_cv REFCURSOR;
BEGIN
  get_desp_stocks_cur_p('LUXOTTICA','TABCORP','COURIER','COURIERS','13-APR-2014','28-APR-2014',:desp_stock_cv);
END;

variable desp_stock_cv refcursor;
exec EOM_REPORT_PKG.get_desp_stocks_cur_p('LUXOTTICA','TABCORP','COURIER','COURIERS','13-APR-2014','28-APR-2014',:desp_stock_cv);
print desp_stock_cv;









SELECT NI_STOCK, NI_TRAN_TYPE,NI_QUANTITY,NI_DATE,NI_STATUS,NI_STRENGTH,IM_CUST
FROM NI RIGHT JOIN IM ON IM_STOCK = NI_STOCK
WHERE NI_ADD_DATE >= '1-APR-2014' AND IM_CUST = 'CROWN'


                           SELECT * FROM SD WHERE SD_ORDER = '   1520759'


select * from dba_objects
   where object_type in ( 'PACKAGE', 'PACKAGE BODY' )


   Select text
from all_source
where owner = 'PWIN175'
and type in ( 'PACKAGE', 'PACKAGE BODY' )
and name = 'EOM_REPORT_PKG'




EXECUTE eom_report_pkg.EOM_CREATE_TEMP_DATA_BIND('21VICP','1-May-2014', '31-May-2014');



var nOrderFee NUMBER
EXEC SELECT EOM_REPORT_PKG_TEST.EmailOrderEntryFee('RTA') INTO :nOrderFee FROM DUAL;


EXEC EOM_REPORT_PKG_TEST.set_admin_eom_vars('AAS', NULL,NULL,NULL,72,NULL);





