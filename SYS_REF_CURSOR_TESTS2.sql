 CREATE OR REPLACE PROCEDURE get_desp_stocks (
			gds_cust_in IN VARCHAR2, -- IM.IM_CUST%TYPE,
			gds_cust_not_in IN  VARCHAR2, -- IM.IM_CUST%TYPE,
			gds_nx_ext_type_in IN NUMBER, --NI.NI_NV_EXT_TYPE%TYPE,
			gds_stock_not_in IN VARCHAR2, -- IM.IM_STOCK%TYPE,
			gds_stock_not_in2 IN VARCHAR2, -- IM.IM_STOCK%TYPE,
			gds_start_date_in IN DATE, --ST.ST_DESP_DATE%TYPE,
			gds_end_date_in IN DATE, --ST.ST_DESP_DATE%TYPE,
			gds_src_get_desp_stocks  IN  OUT sys_refcursor
)
AS
BEGIN
	OPEN gds_src_get_desp_stocks FOR
	q'{SELECT    s.SH_CUST                AS "Customer",
			         s.SH_ORDER               AS "Order",
		           substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	             d.SD_STOCK               AS "Item",
			         d.SD_DESC                AS "Description",
			         CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> ' ||gds_cust_not_in || '  AND i.IM_OWNED_BY = 0 THEN d.SD_SELL_PRICE
			                WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> ' ||gds_cust_not_in || '  AND i.IM_OWNED_BY = 1 THEN n.NI_SELL_VALUE/n.NI_NX_QUANTITY
                      WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = ' ||gds_cust_not_in || '  AND eom_report_pkg.F_BREAK_UNIT_PRICE2(r.RM_GROUP_CUST,d.SD_STOCK) IS NOT NULL THEN eom_report_pkg.F_BREAK_UNIT_PRICE2(r.RM_GROUP_CUST,d.SD_STOCK)
			                WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = ' ||gds_cust_not_in || '  AND eom_report_pkg.F_BREAK_UNIT_PRICE2(r.RM_GROUP_CUST,d.SD_STOCK) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			                ELSE NULL
			                END                        AS "Batch/UnitPrice",
		           i.IM_BRAND AS Brand
	FROM  PWIN175.SD d
			  RIGHT JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  LEFT JOIN PWIN175.ST t  ON t.ST_PICK  = d.SD_LAST_PICK_NUM
        LEFT JOIN PWIN175.SL l   ON l.SL_PICK   = t.ST_PICK
			  INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
        INNER JOIN PWIN175.NI n  ON n.NI_NV_EXT_KEY = l.SL_UID
  WHERE NI_NV_EXT_TYPE = ' || gds_nx_ext_type_in || 'AND NI_STRENGTH = 3 AND NI_DATE = t.ST_DESP_DATE AND NI_STOCK = d.SD_STOCK AND NI_STATUS <> 0
	AND     s.SH_STATUS <> 3
  AND     i.IM_CUST IN (' || gds_cust_in|| ')
	AND       s.SH_ORDER = t.ST_ORDER
	AND       t.ST_DESP_DATE >= ' ||gds_start_date_in || ' AND t.ST_DESP_DATE <= ' ||gds_end_date_in || '
	AND       d.SD_LAST_PICK_NUM = t.ST_PICK
	GROUP BY  s.SH_CUST,s.SH_ORDER,
			      t.ST_DESP_DATE,
			      d.SD_DESC,d.SD_STOCK,d.SD_XX_OW_UNIT_PRICE,d.SD_SELL_PRICE,
            i.IM_BRAND,i.IM_OWNED_BY,i.IM_CUST,
            n.NI_SELL_VALUE,n.NI_NX_QUANTITY,
            r.RM_GROUP_CUST }';
 END get_desp_stocks;
/




  declare
     v_src     sys_refcursor;

     v_cust     VARCHAR2(120);
     v_order    VARCHAR2(120);
     v_despdate VARCHAR2(120);
     v_stock    VARCHAR2(120);
     v_desc     VARCHAR2(120);
     v_price    NUMBER;
     v_brand    VARCHAR2(120);
    begin
      v_src := get_desp_stocks(gds_cust_in => 'TABCORP',
                               gds_cust_not_in => 'TABCORP',
                               gds_nx_ext_type_in => 1810105,
                               gds_stock_not_in => 'COURIERS',
                               gds_stock_not_in2 => 'COURIERM',
                               gds_start_date_in => '2014-04-01',
                               gds_end_date_in => '2014-04-08',
                               gds_src_get_desp_stocks => v_src);  -- This returns an open cursor
      dbms_output.put_line('Pre Fetch: Rows: '||v_src%ROWCOUNT);
      fetch v_src into v_cust,v_order, v_despdate, v_stock, v_desc, v_price, v_brand;
      dbms_output.put_line('Post Fetch: Rows: '||v_src%ROWCOUNT);
      close v_src;
    end;
    /

  variable get_desp_stocks_cur refcursor;
  execute get_desp_stocks('TABCORP','TABCORP',1810105,'COURIERS','COURIERM','1-APR-2014','8-APR-2014',:get_desp_stocks_cur);
  print get_desp_stocks_cur;





 create or replace procedure quick_function_test( p_rc OUT SYS_REFCURSOR )AS
 BEGIN
 OPEN p_rc
   for select 1 col1
         from dual;
 CLOSE p_rc
 END quick_function_test;
 /

  variable rc refcursor;
  exec quick_function_test( :rc );
  print rc;


