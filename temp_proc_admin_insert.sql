
create or replace PROCEDURE EOM_CREATE_DATA_TEST (gds_src_get_desp_stocks OUT sys_refcursor) AS

  BEGIN
   --OPEN gds_src_get_desp_stocks FOR
   BULK INSERT into tbl_AdminData
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
      WHERE     r.sGroupCust = 'VHAAUS'
      AND       d.SD_STOCK = 'COURIER' 
      AND       s.SH_ORDER = t.ST_ORDER
      AND       d.SD_SELL_PRICE >= 0.1
      AND       t.ST_DESP_DATE >= '01-May-2015' AND t.ST_DESP_DATE <= '03-May-2015'
      AND   d.SD_ADD_OP LIKE 'SERV%';
      DBMS_OUTPUT.PUT_LINE('E_EOM_CREATE_ADMIN_DATA was successful ' );
 END EOM_CREATE_DATA_TEST;  
 
 
 
 CREATE OR REPLACE PROCEDURE test_proc (p_array_size IN PLS_INTEGER DEFAULT 100)
IS
TYPE ARRAY IS TABLE OF tbl_AdminData%ROWTYPE;
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
END test_proc;
/
