select    s.SH_CUST                AS "Customer",
			  r.sGroupCust              AS "Parent",
			  s.SH_SPARE_STR_4         AS "CostCentre",
			  s.SH_ORDER               AS "Order",
			  s.SH_SPARE_STR_5         AS "OrderwareNum",
			  s.SH_CUST_REF            AS "CustomerRef",
			  t.ST_PICK                AS "Pickslip",
			  d.SD_XX_PICKLIST_NUM     AS "PickNum",
			  t.ST_PSLIP               AS "DespatchNote",
			  substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	      To_Char(d.SD_DESC)       AS "FeeType",
			  d.SD_STOCK               AS "Item",
			  '="' || To_Char(d.SD_DESC) || '"'               AS "Description",
	      '1'                      AS "Qty",
	      '1'                      AS "UOI",
        d.SD_SELL_PRICE          AS "UnitPrice",
			  d.SD_XX_OW_UNIT_PRICE    AS "OWUnitPrice",
			  d.SD_EXCL                AS "DExcl",
			  Sum(d.SD_EXCL)           AS "Excl_Total",
			  d.SD_INCL                AS "DIncl",
			  Sum(d.SD_INCL)           AS "Incl_Total",
			  'N/A'                     AS "ReportingPrice",
			  s.SH_ADDRESS             AS "Address",
			  s.SH_SUBURB              AS "Address2",
			  s.SH_CITY                AS "Suburb",
			  s.SH_STATE               AS "State",
			  s.SH_POST_CODE           AS "Postcode",
			  s.SH_NOTE_1              AS "DeliverTo",
			  s.SH_NOTE_2              AS "AttentionTo" ,
			  t.ST_WEIGHT              AS "Weight",
			  t.ST_PACKAGES            AS "Packages",
			  s.SH_SPARE_DBL_9         AS "OrderSource",
			  'N/A' AS "Pallet/Shelf Space",
				'N/A' AS "Locn",
				0 AS "CountOfStocks",
        s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1   AS Email,
              'N/A' AS Brand,
           'N/A' AS    OwnedBy,
           'N/A' AS    sProfile,
           'N/A' AS    WaiveFee,
           d.SD_COST_PRICE As   Cost,
           'N/A' AS PaymentType




           create or replace procedure pop_addr_details
    (i_addr_style mapping_table.address_style%type
        , i_Address_Line1  in varchar2
        , i_Address_Line2  in varchar2
        , i_Zip_Code  in varchar2
        , i_Tax_Zip Code  in varchar2
        , i_City  in varchar2
        , i_State  in varchar2
        , i_Country  in varchar2
        , i_Tax_Jurisdiction  in varchar2
        , i_Tax_Jurisdiction Other  in varchar2
        , i_Telephone  in varchar2
        , i_Telephone2  in varchar2 )
is
    stmt varchar2(32767);
begin
    stmt := 'insert into adddresses values (address_id';

    for map_rec in ( select column_field_name
                     from mapping_table
                     where address_style = i_addr_style
                     order by col_order )
    loop
        stmt := stmt || ',' || map_rec.column_field_name;
    end loop;

    stmt := stmt || ') values ( address_seq.next_val, :1, :2, :3, :4, :5, :6, :7, :8, :9, :10, :11)';

    execute immedate stmt using i_Address_Line1
                , i_Address_Line2
                , i_Zip_Code
                , i_Tax_Zip Code
                , i_City
                , i_State
                , i_Country
                , i_Tax_Jurisdiction
                , i_Tax_Jurisdiction Other
                , i_Telephone
                , i_Telephone2;
end pop_addr_details;
/



DECLARE

  -- Define a cursor to get the list of tables you want counts for.
  cursor c1 is
  select table_name
  from all_tables
  where owner = 'YOUR_OWNER_HERE';

  -- Dynamically created select.
  stmt varchar2(200);

BEGIN

  -- The cursor for loop implicitly opens and closes the cursor.
  for table_rec in c1
  loop
    -- dynamically build the insert statement.
    stmt := 'insert into temp(table_name,run_date,table_count) ';
    stmt := stmt || 'select ''' || table_rec.table_name || ''','''|| sysdate||''','|| 'count(*) from ' || table_rec.table_name;

    -- Execute the insert statement.
    execute immediate(stmt);

  end loop;
END;
commit;




 SELECT RD_COY_NAME FROM RD WHERE RD_COY_NAME LIKE '%Warehouse K%'





CUSTOMER                VARCHAR2(255)
PARENT                  VARCHAR2(255)
COSTCENTRE              VARCHAR2(255)
ORDERNUM                VARCHAR2(255)
ORDERWARENUM            VARCHAR2(255)
CUSTREF                 VARCHAR2(255)
PICKSLIP                VARCHAR2(255)
PICKNUM                 VARCHAR2(255)
DESPATCHNOTE            VARCHAR2(255)
DESPATCHDATE            VARCHAR2(255)
FEETYPE                 VARCHAR2(255)
ITEM                    VARCHAR2(255)
DESCRIPTION             VARCHAR2(255)
QTY                     NUMBER
UOI                     VARCHAR2(255)
UNITPRICE               NUMBER
OW_UNIT_SELL_PRICE      NUMBER
SELL_EXCL               NUMBER
SELL_EXCL_TOTAL         NUMBER
SELL_INCL               NUMBER
SELL_INCL_TOTAL         NUMBER
REPORTINGPRICE          NUMBER
ADDRESS                 VARCHAR2(255)
ADDRESS2                VARCHAR2(255)
SUBURB                  VARCHAR2(255)
STATE                   VARCHAR2(255)
POSTCODE                VARCHAR2(255)
DELIVERTO               VARCHAR2(255)
ATTENTIONTO             VARCHAR2(255)
WEIGHT                  NUMBER
PACKAGES                NUMBER
ORDERSOURCE             NUMBER(38)
ILNOTE2                 VARCHAR2(255)
NILOCN                  VARCHAR2(255)
COUNTOFSTOCKS           NUMBER
EMAIL                   VARCHAR2(255)
BRAND                   VARCHAR2(255)
OWNEDBY                 VARCHAR2(255)
SPROFILE                VARCHAR2(255)
WAIVEFEE                VARCHAR2(255)
COST                    VARCHAR2(255)
PAYMENTTYPE             VARCHAR2(255)






EXECUTE IMMEDIATE 'BEGIN eom_report_pkg.GROUP_CUST_START; END;';



SELECT RM_CUST, RD_CODE, RD_EMAIL
FROM RM INNER JOIN RD ON RD_CUST = RM_CUST
WHERE RD_IS_MAIN = 1
AND RM_CUST LIKE '21T-%'
AND RD_EMAIL IS NULL




SELECT * FROM Tmp_Group_Cust
SELECT * FROM Tmp_Admin_Data_BreakPrices
SELECT * FROM Tmp_Admin_Data_Pickslips
SELECT * FROM Tmp_Admin_Data_Pick_LineCounts
SELECT * FROM Tmp_Batch_Price_SL_Stock
SELECT * FROM Tmp_Locn_Cnt_By_Cust
SELECT * FROM Tmp_Log_stats



 nCheckpoint := 16;
    EXECUTE IMMEDIATE q'{INSERT into tbl_AdminData
 select s.SH_CUST,r.sGroupCust,s.SH_SPARE_STR_4,s.SH_ORDER,s.SH_SPARE_STR_5,
			  s.SH_CUST_REF,t.ST_PICK,d.SD_XX_PICKLIST_NUM,t.ST_PSLIP,
			  t.ST_DESP_DATE,d.SD_DESC,d.SD_STOCK,d.SD_DESC,1,1,d.SD_SELL_PRICE,
			  d.SD_XX_OW_UNIT_PRICE,d.SD_EXCL,d.SD_EXCL,d.SD_INCL,d.SD_INCL,
			  0,s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,
			  s.SH_NOTE_1,s.SH_NOTE_2,t.ST_WEIGHT,t.ST_PACKAGES,s.SH_SPARE_DBL_9,
			  NULL,NULL,0,s.SH_SPARE_STR_3,NULL,NULL,NULL,NULL,d.SD_COST_PRICE,NULL
	FROM  PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_PICK))  = LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM))
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
	WHERE     s.SH_ORDER = d.SD_ORDER

	AND       (r.sGroupCust = :cust OR r.sCust = :cust2)
	AND       d.SD_STOCK IN ('COURIERM','COURIERS','COURIER')
	AND       s.SH_ORDER = t.ST_ORDER
	AND       d.SD_SELL_PRICE >= 0.1
	AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
  AND   d.SD_ADD_OP LIKE 'SERV%'}'
              USING sCust,sCust,start_date,end_date;

select s.SH_CUST,r.sGroupCust,s.SH_SPARE_STR_4,s.SH_ORDER,s.SH_SPARE_STR_5,
			  s.SH_CUST_REF,t.ST_PICK,d.SD_XX_PICKLIST_NUM,t.ST_PSLIP,
			  t.ST_DESP_DATE,d.SD_DESC,d.SD_STOCK,d.SD_DESC,1,1,d.SD_SELL_PRICE,
			  d.SD_XX_OW_UNIT_PRICE,d.SD_EXCL,d.SD_EXCL,d.SD_INCL,d.SD_INCL,
			  0,s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,
			  s.SH_NOTE_1,s.SH_NOTE_2,t.ST_WEIGHT,t.ST_PACKAGES,s.SH_SPARE_DBL_9,
			  NULL,NULL,0,s.SH_SPARE_STR_3,NULL,NULL,NULL,NULL,d.SD_COST_PRICE,NULL
	FROM  PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_PICK))  = LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM))
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
	WHERE     s.SH_ORDER = d.SD_ORDER

	AND       (r.sGroupCust = 'VHAAUS' OR r.sCust = 'VHAAUS')
	AND       d.SD_STOCK IN ('COURIERM','COURIERS','COURIER')
	AND       s.SH_ORDER = t.ST_ORDER
	AND       d.SD_SELL_PRICE >= 0.1
	AND       t.ST_DESP_DATE >= '01-May-2015' AND t.ST_DESP_DATE <= '21-May-2015'
  AND   d.SD_ADD_OP LIKE 'SERV%';


PROCEDURE C_EOM_START_CUST_TEMP_DATA
    (
     sCust IN RM.RM_CUST%TYPE := 'VHAAUS'
     )
  AS
    v_query           VARCHAR2(2000);
		nCheckpoint       NUMBER;
		p_status          NUMBER := 3;
    p_ST_PSLIP        ST.ST_PSLIP%TYPE := 'CANCELLED';
    p_NE_NV_EXT_TYPE  NE.NE_NV_EXT_TYPE%TYPE := 1810105;
    p_NE_STRENGTH     NE.NE_STRENGTH%TYPE := 3;
    p_NI_STATUS       NI.NI_STATUS%TYPE := 0;
    p_NI_AVAIL_ACTUAL NI.NI_AVAIL_ACTUAL%TYPE := 1;
    p_IM_ACTIVE       IM.IM_ACTIVE%TYPE := 1;
    p_RM_TYPE         RM.RM_TYPE%TYPE := 0;
    p_SH_STATUS       SH.SH_STATUS%TYPE := 3;

  BEGIN

/* Truncate all temp tables*/

		nCheckpoint := 6;
		v_query := 'TRUNCATE TABLE Tmp_Locn_Cnt_By_Cust';
		EXECUTE IMMEDIATE v_query;

		nCheckpoint := 7;
		v_query := 'TRUNCATE TABLE tbl_AdminData';
		EXECUTE IMMEDIATE v_query;

		DBMS_OUTPUT.PUT_LINE('Successfully truncated all temporary tables');

	/*Insert fresh temp data*/

   nCheckpoint := 15;
		v_query := q'{INSERT INTO Tmp_Locn_Cnt_By_Cust
						SELECT Count(DISTINCT NI_STOCK) AS CountOfStocks, IL_LOCN, IM_CUST,
                      CASE WHEN Upper(substr(IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                        ELSE 'F- Shelves'
                        END AS "Note"
						FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
						INNER JOIN IM ON IM_STOCK = NI_STOCK
						WHERE IM_CUST IN :customer
						AND IM_ACTIVE = :v_p_IM_ACTIVE
						AND NI_AVAIL_ACTUAL >= :v_p_NI_AVAIL_ACTUAL
						AND NI_STATUS <> :v_p_NI_STATUS
						GROUP BY IL_LOCN, IM_CUST,IL_NOTE_2}';
    /*(SELECT RM_CUST FROM RM WHERE RM_ANAL = :sAnalysis AND RM_TYPE = :v_p_RM_TYPE AND RM_ACTIVE = :v_p_IM_ACTIVE )*/
		EXECUTE IMMEDIATE v_query USING sCust,p_IM_ACTIVE,p_NI_AVAIL_ACTUAL,p_NI_STATUS;

		DBMS_OUTPUT.PUT_LINE('Successfully inserted fresh temporary data');

 RETURN;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
END C_EOM_START_CUST_TEMP_DATA;





 PROCEDURE E_EOM_CREATE_ADMIN_DATA
    (
     start_date IN ST.ST_DESP_DATE%TYPE
     ,end_date IN ST.ST_DESP_DATE%TYPE
     ,sCust IN RM.RM_CUST%TYPE
     )
  AS
    v_out_tx          VARCHAR2(2000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		sCourierm         VARCHAR2(20) := 'COURIERM';
    sCouriers         VARCHAR2(20) := 'COURIERS';
    sCourier         VARCHAR2(20) := 'COURIER%';
    sServ8             VARCHAR2(20) := 'SERV8';
    sServ3             VARCHAR2(20) := 'SERV%';
  BEGIN


    nCheckpoint := 16;

    EXECUTE IMMEDIATE
    'INSERT into tbl_AdminData
 select s.SH_CUST,r.sGroupCust,s.SH_SPARE_STR_4,s.SH_ORDER,s.SH_SPARE_STR_5,
			  s.SH_CUST_REF,t.ST_PICK,d.SD_XX_PICKLIST_NUM,t.ST_PSLIP,
			  t.ST_DESP_DATE,d.SD_DESC,d.SD_STOCK,d.SD_DESC,1,1,d.SD_SELL_PRICE,
			  d.SD_XX_OW_UNIT_PRICE,d.SD_EXCL,d.SD_EXCL,d.SD_INCL,d.SD_INCL,
			  0,s.SH_ADDRESS,s.SH_SUBURB,s.SH_CITY,s.SH_STATE,s.SH_POST_CODE,
			  s.SH_NOTE_1,s.SH_NOTE_2,t.ST_WEIGHT,t.ST_PACKAGES,s.SH_SPARE_DBL_9,
			  NULL,NULL,0,s.SH_SPARE_STR_3,NULL,NULL,NULL,NULL,d.SD_COST_PRICE,NULL
	FROM  PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_PICK))  = LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM))
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
	WHERE     (r.sGroupCust = :cust ) --OR r.sCust = :cust
	AND       d.SD_STOCK LIKE :courier -- (:courier1,:courier2,:courier3)
	AND       s.SH_ORDER = t.ST_ORDER
	AND       d.SD_SELL_PRICE >= 0.1
	AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
  AND   d.SD_ADD_OP LIKE :SERV3
  ' USING sCust,sCourier,start_date,end_date,sServ3;
 --COMMIT;
 DBMS_OUTPUT.PUT_LINE('E_EOM_CREATE_ADMIN_DATA was successful ' );
 RETURN;
    --COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('E_EOM_CREATE_ADMIN_DATA processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END E_EOM_CREATE_ADMIN_DATA;





SELECT * FROM Tmp_Group_Cust;
SELECT * FROM tbl_AdminData;






set timing on
exec EOM_REPORT_PKG_TEST.test_procC;
set timing off


SELECT Count(*) FROM TMP_ADMIN_DATA_CUST
TRUNCATE TABLE TMP_ADMIN_DATA_CUST;


PROCEDURE test_procA IS

BEGIN
    FOR x IN (SELECT * FROM all_objects)
    LOOP
        INSERT INTO t1
        (owner, object_name, subobject_name, object_id,
        data_object_id, object_type, created, last_ddl_time,
        timestamp, status, temporary, generated, secondary)
        VALUES
        (x.owner, x.object_name, x.subobject_name, x.object_id,
        x.data_object_id, x.object_type, x.created,
        x.last_ddl_time, x.timestamp, x.status, x.temporary,
        x.generated, x.secondary);
    END LOOP;
COMMIT;
END test_procA;




PROCEDURE test_procB (p_array_size IN PLS_INTEGER DEFAULT 100)
IS
TYPE ARRAY IS TABLE OF all_objects%ROWTYPE;
l_data ARRAY;

CURSOR c IS SELECT * FROM all_objects;

BEGIN
    OPEN c;
    LOOP
    FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;

    FORALL i IN 1..l_data.COUNT
    INSERT INTO t1 VALUES l_data(i);

    EXIT WHEN c%NOTFOUND;
    END LOOP;
    CLOSE c;
END test_procB;

  PROCEDURE test_procC
  AS
  TYPE TObjectTable IS TABLE OF tbl_AdminData%ROWTYPE;
  ObjectTable$ TObjectTable;

  BEGIN
     SELECT * BULK COLLECT INTO ObjectTable$
       FROM tbl_AdminData;

       FORALL x in ObjectTable$.First..ObjectTable$.Last
       INSERT INTO t1 VALUES ObjectTable$(x) ;
  END test_procC;

   create or replace procedure fast_proc is
2         type TObjectTable is table of ALL_OBJECTS%ROWTYPE;
3         ObjectTable$ TObjectTable;
4         begin
5         select
6                     * BULK COLLECT INTO ObjectTable$
7         from ALL_OBJECTS;
8
9         forall x in ObjectTable$.First..ObjectTable$.Last
10       insert into t1 values ObjectTable$(x) ;
11       end;












 select    s.SH_CUST                AS "Customer",
			  r.sGroupCust              AS "Parent",
			  s.SH_SPARE_STR_4         AS "CostCentre",
			  s.SH_ORDER               AS "Order",
			  s.SH_SPARE_STR_5         AS "OrderwareNum",
			  s.SH_CUST_REF            AS "CustomerRef",
			  t.ST_PICK                AS "Pickslip",
			  d.SD_XX_PICKLIST_NUM     AS "PickNum",
			  t.ST_PSLIP               AS "DespatchNote",
			  substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	      CASE  WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 0.1 THEN 'Freight Fee'
			          ELSE To_Char(d.SD_DESC)
			          END                      AS "FeeType",
			  d.SD_STOCK               AS "Item",
			  '="' || To_Char(d.SD_DESC) || '"'               AS "Description",
	      CASE  WHEN d.SD_LINE IS NOT NULL THEN  1
			        ELSE NULL
			        END                     AS "Qty",
	      CASE  WHEN d.SD_LINE IS NOT NULL THEN  '1'
			        ELSE NULL
			        END                      AS "UOI",

        CASE  WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.sGroupCust <> 'BORBUI' AND r.sGroupCust <> 'BEYONDBLUE') THEN d.SD_SELL_PRICE
			        WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.sGroupCust = 'BORBUI' OR r.sGroupCust = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.125) And (t.ST_SPARE_DBL_1 > 0.00) THEN 1.70
              WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.sGroupCust = 'BORBUI' OR r.sGroupCust = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.250) And (t.ST_SPARE_DBL_1 > 0.126) THEN 2.30
              WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.sGroupCust = 'BORBUI' OR r.sGroupCust = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.500) And (t.ST_SPARE_DBL_1 > 0.251) THEN 3.40
              WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.sGroupCust = 'BORBUI' OR r.sGroupCust = 'BEYONDBLUE') AND (t.ST_WEIGHT > 0.01) THEN d.SD_SELL_PRICE
              ELSE NULL
			        END                      AS "UnitPrice",
			  d.SD_XX_OW_UNIT_PRICE    AS "OWUnitPrice",
			  d.SD_EXCL                AS "DExcl",
			  Sum(d.SD_EXCL)           AS "Excl_Total",
			  d.SD_INCL                AS "DIncl",
			  Sum(d.SD_INCL)           AS "Incl_Total",
			  NULL                     AS "ReportingPrice",
			  s.SH_ADDRESS             AS "Address",
			  s.SH_SUBURB              AS "Address2",
			  s.SH_CITY                AS "Suburb",
			  s.SH_STATE               AS "State",
			  s.SH_POST_CODE           AS "Postcode",
			  s.SH_NOTE_1              AS "DeliverTo",
			  s.SH_NOTE_2              AS "AttentionTo" ,
			  t.ST_WEIGHT              AS "Weight",
			  t.ST_PACKAGES            AS "Packages",
			  s.SH_SPARE_DBL_9         AS "OrderSource",
			  NULL AS "Pallet/Shelf Space", /*Pallet/Space*/
				NULL AS "Locn", /*Locn*/
			--	0 AS "AvailSOH",/*Avail SOH*/
				0 AS "CountOfStocks",
        CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			        ELSE ''
			        END AS Email,
              'N/A' AS Brand,
           NULL AS    OwnedBy,
           NULL AS    sProfile,
           NULL AS    WaiveFee,
           d.SD_COST_PRICE As   Cost,
           NULL AS PaymentType
	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_PICK))  = LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM))
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
	WHERE     s.SH_ORDER = d.SD_ORDER
	--AND       r.RM_ANAL = :sAnalysis
	AND       (r.sGroupCust = 'TABCORP' OR r.sCust = 'TABCORP')
	AND       d.SD_STOCK IN ('COURIERM','COURIERS','COURIER')
	AND       s.SH_ORDER = t.ST_ORDER
	AND       d.SD_SELL_PRICE >= 0.1
	AND       t.ST_DESP_DATE >= '1-MAY-2015' AND t.ST_DESP_DATE <= '28-MAY-2015'
  AND   d.SD_ADD_OP LIKE 'SERV%'
  --AND s.SH_ORDER LIKE '   1377018'

	GROUP BY  s.SH_CUST,
			  s.SH_SPARE_STR_4,
			  s.SH_ORDER,
			  t.ST_PICK,
			  d.SD_XX_PICKLIST_NUM,
			  t.ST_PSLIP,
			  t.ST_DESP_DATE,
			  d.SD_STOCK,
			  d.SD_DESC,
			  d.SD_LINE,
			  d.SD_EXCL,
			  d.SD_INCL,
			  d.SD_NOTE_1,
			  d.SD_SELL_PRICE,
			  d.SD_XX_OW_UNIT_PRICE,
			  d.SD_QTY_ORDER,
			  d.SD_QTY_ORDER,
			  s.SH_ADDRESS,
			  s.SH_SUBURB,
			  s.SH_CITY,
			  s.SH_STATE,
			  s.SH_POST_CODE,
			  s.SH_NOTE_1,
			  s.SH_NOTE_2,
			  t.ST_WEIGHT,
			  t.ST_PACKAGES,
			  s.SH_SPARE_DBL_9,
			  r.sGroupCust,
			  s.SH_SPARE_STR_5,
			  s.SH_CUST_REF,
        s.SH_SPARE_STR_3,
        s.SH_SPARE_STR_1,
        t.ST_SPARE_DBL_1,
        d.SD_XX_PSLIP_NUM,
          d.SD_ADD_DATE,
          d.SD_XX_PICKLIST_NUM,
          d.SD_COST_PRICE
;




  PROCEDURE myFunc (
     pName   IN VARCHAR2,
     pHeight IN VARCHAR2,
     pTeam   IN VARCHAR2
  )
     RETURN T_CURSOR
  IS
     -- Local Variables
     SQLQuery   VARCHAR2(6000);
     TestCursor T_CURSOR;
  BEGIN
     -- Build SQL query
     SQLQuery := 'WITH t_binds '||
                  ' AS (SELECT :v_name AS bv_name, '||
                             ' :v_height AS bv_height, '||
                             ' :v_team AS bv_team '||
                        ' FROM dual) '||
                 ' SELECT id, '||
                        ' name, '||
                        ' height, '||
                        ' team '||
                   ' FROM MyTable, '||
                        ' t_binds '||
                  ' WHERE id IS NOT NULL';

     -- Build the query WHERE clause based on the parameters passed.
     IF pName IS NOT NULL
     THEN
       SQLQuery := SQLQuery || ' AND Name LIKE bv_name ';
     END IF;

     IF pHeight > 0
     THEN
       SQLQuery := SQLQuery || ' AND Height = bv_height ';
     END IF;

     IF pTeam IS NOT NULL
     THEN
       SQLQuery := SQLQuery || ' AND Team LIKE bv_team ';
     END IF;

     OPEN TestCursor
      FOR SQLQuery
    USING pName,
          pHeight,
          pTeam;

     -- Return the cursor
     RETURN TestCursor;
  END myFunc;

  FUNCTION player_search (
   pName        IN VARCHAR2,
   pHeight      IN NUMBER,
   pTeam        IN VARCHAR2
) RETURN SYS_REFCURSOR
IS
  cursor_name   INTEGER;
  ignore        INTEGER;
  id_var        MyTable.ID%TYPE;
  name_var      MyTable.Name%TYPE;
  height_var    MyTable.Height%TYPE;
  team_var      MyTable.Team%TYPE;
BEGIN
  -- Put together SQLQuery here...

  -- Open the cursor and parse the query
  cursor_name := DBMS_SQL.OPEN_CURSOR;
  DBMS_SQL.PARSE(cursor_name, SQLQuery, DBMS_SQL.NATIVE);

  -- Define the columns that the query returns.
  -- (The last number for columns 2 and 4 is the size of the
  -- VARCHAR2 columns.  Feel free to change them.)
  DBMS_SQL.DEFINE_COLUMN(cursor_name, 1, id_var);
  DBMS_SQL.DEFINE_COLUMN(cursor_name, 2, name_var, 30);
  DBMS_SQL.DEFINE_COLUMN(cursor_name, 3, height_var);
  DBMS_SQL.DEFINE_COLUMN(cursor_name, 4, team_var, 30);

  -- Add bind variables depending on whether they were added to
  -- the query.
  IF pName IS NOT NULL THEN
    DBMS_SQL.BIND_VARIABLE(cursor_name, ':pName', pName);
  END IF;

  IF pHeight > 0 THEN
    DBMS_SQL.BIND_VARIABLE(cursor_name, ':pHeight', pHeight);
  END IF;

  IF pTeam IS NOT NULL THEN
    DBMS_SQL.BIND_VARIABLE(cursor_name, ':pTeam', pTeam);
  END IF;

  -- Run the query.
  -- (The return value of DBMS_SQL.EXECUTE for SELECT queries is undefined,
  -- so we must ignore it.)
  ignore := DBMS_SQL.EXECUTE(cursor_name);

  -- Convert the DBMS_SQL cursor into a PL/SQL REF CURSOR.
  RETURN DBMS_SQL.TO_REFCURSOR(cursor_name);

EXCEPTION
  WHEN OTHERS THEN
    -- Ensure that the cursor is closed.
    IF DBMS_SQL.IS_OPEN(cursor_name) THEN
      DBMS_SQL.CLOSE_CURSOR(cursor_name);
    END IF;
    RAISE;
END;
TRUNCATE TABLE TMP_FREIGHT
SELECT CUSTOMER,PICKSLIP,DESPATCHDATE
--SELECT Count(CUSTOMER)
FROM TMP_FREIGHT
WHERE CUSTOMER = 'TABCORP' OR PARENT = 'TABCORP'

PROCEDURE test_procA IS

  BEGIN
      FOR x IN (SELECT sCust FROM Tmp_Group_Cust)
      LOOP
          INSERT INTO TMP_ADMIN_DATA_CUST
          (VCUST)
          VALUES
          (x.sCust);
      END LOOP;
  COMMIT;
  END test_procA;

  PROCEDURE test_procB (p_array_size IN PLS_INTEGER DEFAULT 100)
    IS
    TYPE ARRAY IS TABLE OF TMP_ADMIN_DATA_CUST%ROWTYPE;
    l_data ARRAY;

    CURSOR c IS SELECT sCust FROM Tmp_Group_Cust;

    BEGIN
        OPEN c;
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;

        FORALL i IN 1..l_data.COUNT
        INSERT INTO TMP_ADMIN_DATA_CUST VALUES l_data(i);

        EXIT WHEN c%NOTFOUND;
        END LOOP;
        CLOSE c;
  END test_procB;

  PROCEDURE test_procC
    AS
    TYPE TObjectTable IS TABLE OF TMP_ADMIN_DATA_CUST%ROWTYPE;
    ObjectTable$ TObjectTable;

    BEGIN
       SELECT sCust BULK COLLECT INTO ObjectTable$
         FROM Tmp_Group_Cust;

         FORALL x in ObjectTable$.First..ObjectTable$.Last
         --DBMS_OUTPUT.PUT_LINE(ObjectTable$(x));
         INSERT INTO TMP_ADMIN_DATA_CUST VALUES ObjectTable$(x) ;
  END test_procC;


  PROCEDURE test_procBFAST (
    p_array_size IN PLS_INTEGER DEFAULT 100,
     start_date IN ST.ST_DESP_DATE%TYPE
     ,end_date IN ST.ST_DESP_DATE%TYPE
     --,sCust IN RM.RM_CUST%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_FREIGHT%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		sCourierm         VARCHAR2(20) := 'COURIERM';
    sCouriers         VARCHAR2(20) := 'COURIERS';
    sCourier         VARCHAR2(20) := 'COURIER%';
    sServ8             VARCHAR2(20) := 'SERV8';
    sServ3             VARCHAR2(20) := 'SERV%';
    --DBMS_OUTPUT.PUT_LINE(start_date || ' - ' || end_date || '.' || sCust );
    CURSOR c
    /*(
      start_date IN ST.ST_DESP_DATE%TYPE
     ,end_date IN ST.ST_DESP_DATE%TYPE
     ,sCust IN RM.RM_CUST%TYPE) */
     IS
    	 select    s.SH_CUST                AS "Customer",
			  r.sGroupCust              AS "Parent",
			  s.SH_SPARE_STR_4         AS "CostCentre",
			  s.SH_ORDER               AS "Order",
			  s.SH_SPARE_STR_5         AS "OrderwareNum",
			  s.SH_CUST_REF            AS "CustomerRef",
			  t.ST_PICK                AS "Pickslip",
			  d.SD_XX_PICKLIST_NUM     AS "PickNum",
			  t.ST_PSLIP               AS "DespatchNote",
			  substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	      CASE  WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 0.1 THEN 'Freight Fee'
			          ELSE To_Char(d.SD_DESC)
			          END                      AS "FeeType",
			  d.SD_STOCK               AS "Item",
			  '="' || To_Char(d.SD_DESC) || '"'               AS "Description",
	      CASE  WHEN d.SD_LINE IS NOT NULL THEN  1
			        ELSE NULL
			        END                     AS "Qty",
	      CASE  WHEN d.SD_LINE IS NOT NULL THEN  '1'
			        ELSE NULL
			        END                      AS "UOI",

        CASE  WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.sGroupCust <> 'BORBUI' AND r.sGroupCust <> 'BEYONDBLUE') THEN d.SD_SELL_PRICE
			        WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.sGroupCust = 'BORBUI' OR r.sGroupCust = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.125) And (t.ST_SPARE_DBL_1 > 0.00) THEN 1.70
              WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.sGroupCust = 'BORBUI' OR r.sGroupCust = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.250) And (t.ST_SPARE_DBL_1 > 0.126) THEN 2.30
              WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.sGroupCust = 'BORBUI' OR r.sGroupCust = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.500) And (t.ST_SPARE_DBL_1 > 0.251) THEN 3.40
              WHEN d.SD_STOCK like 'COURIER%' AND d.SD_SELL_PRICE >= 1 AND (r.sGroupCust = 'BORBUI' OR r.sGroupCust = 'BEYONDBLUE') AND (t.ST_WEIGHT > 0.01) THEN d.SD_SELL_PRICE
              ELSE NULL
			        END                      AS "UnitPrice",
			  d.SD_XX_OW_UNIT_PRICE    AS "OWUnitPrice",
			  d.SD_EXCL                AS "DExcl",
			  Sum(d.SD_EXCL)           AS "Excl_Total",
			  d.SD_INCL                AS "DIncl",
			  Sum(d.SD_INCL)           AS "Incl_Total",
			  NULL                     AS "ReportingPrice",
			  s.SH_ADDRESS             AS "Address",
			  s.SH_SUBURB              AS "Address2",
			  s.SH_CITY                AS "Suburb",
			  s.SH_STATE               AS "State",
			  s.SH_POST_CODE           AS "Postcode",
			  s.SH_NOTE_1              AS "DeliverTo",
			  s.SH_NOTE_2              AS "AttentionTo" ,
			  t.ST_WEIGHT              AS "Weight",
			  t.ST_PACKAGES            AS "Packages",
			  s.SH_SPARE_DBL_9         AS "OrderSource",
			  NULL AS "Pallet/Shelf Space", /*Pallet/Space*/
				NULL AS "Locn", /*Locn*/
			--	0 AS "AvailSOH",/*Avail SOH*/
				0 AS "CountOfStocks",
        CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			        ELSE ''
			        END AS Email,
              'N/A' AS Brand,
           NULL AS    OwnedBy,
           NULL AS    sProfile,
           NULL AS    WaiveFee,
           d.SD_COST_PRICE As   Cost,
           NULL AS PaymentType
	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_PICK))  = LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM))
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
	WHERE     s.SH_ORDER = d.SD_ORDER
	--AND       r.RM_ANAL = :sAnalysis
	AND       (r.sGroupCust = 'TABCORP' OR r.sCust = 'TABCORP')
	AND       d.SD_STOCK IN ('COURIERM','COURIERS','COURIER')
	AND       s.SH_ORDER = t.ST_ORDER
	AND       d.SD_SELL_PRICE >= 0.1
	AND       t.ST_DESP_DATE >= '1-MAY-2015' AND t.ST_DESP_DATE <= '28-MAY-2015'
  AND   d.SD_ADD_OP LIKE 'SERV%'

 /* 	WHERE     r.sGroupCust = :sCust OR r.sCust = :sCust
	AND       d.SD_STOCK LIKE :sCourier -- (:courier1,:courier2,:courier3)
	AND       s.SH_ORDER = t.ST_ORDER
	AND       d.SD_SELL_PRICE >= 0.1
	AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
  AND   d.SD_ADD_OP LIKE :sServ3;
  USING sCust,sCust,sCourier,start_date,end_date,sServ3;

 -- OPEN c(sCust,

  --AND s.SH_ORDER LIKE '   1377018'*/

	GROUP BY  s.SH_CUST,
			  s.SH_SPARE_STR_4,
			  s.SH_ORDER,
			  t.ST_PICK,
			  d.SD_XX_PICKLIST_NUM,
			  t.ST_PSLIP,
			  t.ST_DESP_DATE,
			  d.SD_STOCK,
			  d.SD_DESC,
			  d.SD_LINE,
			  d.SD_EXCL,
			  d.SD_INCL,
			  d.SD_NOTE_1,
			  d.SD_SELL_PRICE,
			  d.SD_XX_OW_UNIT_PRICE,
			  d.SD_QTY_ORDER,
			  d.SD_QTY_ORDER,
			  s.SH_ADDRESS,
			  s.SH_SUBURB,
			  s.SH_CITY,
			  s.SH_STATE,
			  s.SH_POST_CODE,
			  s.SH_NOTE_1,
			  s.SH_NOTE_2,
			  t.ST_WEIGHT,
			  t.ST_PACKAGES,
			  s.SH_SPARE_DBL_9,
			  r.sGroupCust,
			  s.SH_SPARE_STR_5,
			  s.SH_CUST_REF,
        s.SH_SPARE_STR_3,
        s.SH_SPARE_STR_1,
        t.ST_SPARE_DBL_1,
        d.SD_XX_PSLIP_NUM,
          d.SD_ADD_DATE,
          d.SD_XX_PICKLIST_NUM,
          d.SD_COST_PRICE;
--USING ;

    BEGIN
        OPEN c;
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;

        FORALL i IN 1..l_data.COUNT
        INSERT INTO TMP_FREIGHT VALUES l_data(i);


        EXIT WHEN c%NOTFOUND;

        END LOOP;
        CLOSE c;
       FOR i IN l_data.FIRST .. l_data.LAST LOOP
        DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
      END LOOP;

  COMMIT;

  END test_procBFAST;

/*
CURSOR cur_dept IS SELECT * FROM dept ORDER BY deptno;<br />
CURSOR cur_emp (par_dept VARCHAR2) IS<br />
SELECT ename, salary<br />
FROM emp<br />
WHERE deptno = par_dept<br />
ORDER BY ename;<br />*/
