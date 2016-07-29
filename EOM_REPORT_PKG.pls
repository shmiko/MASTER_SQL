create or replace PACKAGE BODY EOM_REPORT_PKG
AS
   --TYPE myBrandTableType AS TABLE OF myBrandType;

 --TYPE t_custtype AS TABLE OF custtype;

  --Get TotalOrders for day for cust
  FUNCTION total_orders
    ( rm_cust_in IN rm.rm_cust%TYPE,
    status_in IN sh.sh_status%TYPE:=NULL,
    sh_add_in IN sh.sh_add_date%TYPE)
  RETURN NUMBER
  IS
    --Internal  UPPER status code
    status_int sh.sh_status%TYPE:=Upper(status_in);

    --Parameterised cursor returns total orders
    CURSOR order_cur (status_in IN sh.sh_status%TYPE)   IS
      SELECT Count(SH_ORDER)
      FROM SH LEFT JOIN Tmp_Group_Cust r ON r.sCust = sh.SH_CUST
      WHERE r.sCust = rm_cust_in
      AND sh_status NOT LIKE status_in
      AND sh.sh_add_date >= sh_add_in;


      --Return value for function
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
      DBMS_OUTPUT.PUT_LINE('Order Count is ' + return_value + ' for customer ' + rm_cust_in + '.');
    END IF;
  END total_orders;

  --Get TotalDespatches for day for cust
  FUNCTION total_despatches
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
      FROM ST,SH LEFT JOIN Tmp_Group_Cust r ON r.sCust = sh.SH_CUST
      WHERE ST_ORDER = SH_ORDER
      AND r.sCust = d_rm_cust_in
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
      DBMS_OUTPUT.PUT_LINE('Despatch Count is ' + return_desp_value + ' for customer ' + d_rm_cust_in + '.');
    END IF;
  END total_despatches;


	FUNCTION get_usage_3_months
                    (
                    gds_cust_in IN IM.IM_CUST%TYPE
                    ,gds_stock_in IN IM.IM_STOCK%TYPE
                    )
    RETURN NUMBER
    AS
    nMonthsUsage NUMBER;
    nCheckpoint  NUMBER;

    BEGIN
      nCheckpoint := 1;
      DBMS_OUTPUT.PUT_LINE('Usage for 3 months.');
      IF gds_cust_in IS NOT NULL THEN
         SELECT SUM(NI_QUANTITY)
         INTO nMonthsUsage
         FROM NI RIGHT JOIN IM ON IM_STOCK = NI_STOCK
         WHERE NI_ADD_DATE >= SYSDATE - 90
               AND NI_ADD_DATE <= SYSDATE
               AND IM_CUST = gds_cust_in
               AND IM_STOCK = gds_stock_in
               AND NI_TRAN_TYPE = 3
               AND NI_STATUS >= 3
               AND NI_STATUS <= 4;
         RETURN nMonthsUsage;
         DBMS_OUTPUT.PUT_LINE('Usage for 3 months is ' + nMonthsUsage);
      ELSE
        RETURN NULL;
      END IF;

    EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('usage failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END get_usage_3_months;

  FUNCTION get_usage_6_months
                    (
                    gds_cust_in IN IM.IM_CUST%TYPE
                    ,gds_stock_in IN IM.IM_STOCK%TYPE
                    )
    RETURN NUMBER
    AS
    nMonthsUsage NUMBER;
    nCheckpoint  NUMBER;

    BEGIN
      nCheckpoint := 1;
      DBMS_OUTPUT.PUT_LINE('Usage for 3 months.');
      IF gds_cust_in IS NOT NULL THEN
         SELECT SUM(NI_QUANTITY)
         INTO nMonthsUsage
         FROM NI RIGHT JOIN IM ON IM_STOCK = NI_STOCK
         WHERE NI_ADD_DATE >= SYSDATE - 180
               AND NI_ADD_DATE <= SYSDATE
               AND IM_CUST = gds_cust_in
               AND IM_STOCK = gds_stock_in
               AND NI_TRAN_TYPE = 3
               AND NI_STATUS >= 3
               AND NI_STATUS <= 4;
         RETURN nMonthsUsage;
         DBMS_OUTPUT.PUT_LINE('Usage for 3 months is ' + nMonthsUsage);
      ELSE
        RETURN NULL;
      END IF;

    EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('usage failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END get_usage_6_months;

  FUNCTION get_usage_12_months
                    (
                    gds_cust_in IN IM.IM_CUST%TYPE
                    ,gds_stock_in IN IM.IM_STOCK%TYPE
                    )
    RETURN NUMBER
    AS
    nMonthsUsage NUMBER;
    nCheckpoint  NUMBER;

    BEGIN
      nCheckpoint := 1;
      DBMS_OUTPUT.PUT_LINE('Usage for 3 months.');
      IF gds_cust_in IS NOT NULL THEN
         SELECT SUM(NI_QUANTITY)
         INTO nMonthsUsage
         FROM NI RIGHT JOIN IM ON IM_STOCK = NI_STOCK
         WHERE NI_ADD_DATE >= SYSDATE - 360
               AND NI_ADD_DATE <= SYSDATE
               AND IM_CUST = gds_cust_in
               AND IM_STOCK = gds_stock_in
               AND NI_TRAN_TYPE = 3
               AND NI_STATUS >= 3
               AND NI_STATUS <= 4;
         RETURN nMonthsUsage;
         DBMS_OUTPUT.PUT_LINE('Usage for 3 months is ' + nMonthsUsage);
      ELSE
        RETURN NULL;
      END IF;

    EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('usage failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END get_usage_12_months;

  --Group Cust Procedure - Creates temp table of all customers grouped into top level parent
  PROCEDURE GROUP_CUST_START AS
    nCheckpoint  NUMBER;
  BEGIN

    nCheckpoint := 1;
    EXECUTE IMMEDIATE	'TRUNCATE  TABLE Tmp_Group_Cust';


    nCheckpoint := 2;
    EXECUTE IMMEDIATE 'INSERT into Tmp_Group_Cust(sCust,sGroupCust,nLevel )
                        SELECT RM_CUST
                          ,(
                            CASE
                              WHEN LEVEL = 1 THEN RM_CUST
                              WHEN LEVEL = 2 THEN RM_PARENT
                              WHEN LEVEL = 3 THEN PRIOR RM_PARENT
                              ELSE NULL
                            END
                          ) AS CC
                          ,LEVEL
                    FROM RM
                    WHERE RM_TYPE = 0
                    AND RM_ACTIVE = 1
                    --AND Length(RM_GROUP_CUST) <=  1
                    CONNECT BY PRIOR RM_CUST = RM_PARENT
                    START WITH Length(RM_PARENT) <= 1';


    DBMS_OUTPUT.PUT_LINE('Successfully truncated, recreated AND populated Tmp_Group_Cust');


    RETURN;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('GROUP_CUST_START failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END GROUP_CUST_START;

  --List cust and name
  PROCEDURE GROUP_CUST_GET
    (gc_customer_in IN rm.rm_cust%TYPE)
    AS
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
      DBMS_OUTPUT.PUT_LINE(gc_rec.rm_cust || '-' || gc_rec.rm_name);
      FETCH gc_cur INTO gc_rec;
    END LOOP;
    CLOSE gc_cur;
  END GROUP_CUST_GET;

  --List cust name, group cust and level
  PROCEDURE GROUP_CUST_LIST
    (tgc_customer_in IN rm.rm_cust%TYPE)
    AS
      nCheckpoint  NUMBER;
    CURSOR tgc_cur IS
      SELECT tgc.sCust, tgc.sGroupCust, tgc.nLevel
      FROM Tmp_Group_Cust tgc
      WHERE tgc.sCust = tgc_customer_in;

    tgc_rec tgc_cur%ROWTYPE;
  BEGIN

    nCheckpoint := 1;
    OPEN tgc_cur;
    FETCH tgc_cur INTO tgc_rec;
    WHILE(tgc_cur%FOUND)
    LOOP
      DBMS_OUTPUT.PUT_LINE(tgc_rec.sCust || ' ' || tgc_rec.sGroupCust || ' - Level ' || tgc_rec.nLevel);
      FETCH tgc_cur INTO tgc_rec;
    END LOOP;
    CLOSE tgc_cur;

    --EXECUTE IMMEDIATE 'SELECT * FROM Tmp_Group_Cust';

    RETURN;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('GROUP_CUST failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END GROUP_CUST_LIST;

  PROCEDURE DESP_STOCK_GET    (
              cdsg_date_from_in IN  SH.SH_ADD_DATE%TYPE,
              cdsg_date_to_in IN  SH.SH_EDIT_DATE%TYPE,
              cdsg_cust_in IN RM.RM_CUST%TYPE
              ) AS

   CURSOR cdsg_cur IS
   SELECT    SH.SH_CUST,  RM.RM_PARENT, SH.SH_ORDER,  SH.SH_SPARE_STR_5,SH.SH_CUST_REF,SH.SH_ADDRESS,SH.SH_SUBURB,
		SH.SH_CITY, SH.SH_STATE , SH.SH_POST_CODE , SH.SH_NOTE_1 ,SH.SH_NOTE_2 ,SH.SH_SPARE_DBL_9
	FROM      PWIN175.SH INNER JOIN PWIN175.RM  ON RM.RM_CUST  = SH.SH_CUST
  WHERE SH.SH_STATUS <> 3
  AND     RM.RM_CUST = cdsg_cust_in
	AND       SH.SH_ADD_DATE >= cdsg_date_from_in AND SH.SH_ADD_DATE <= cdsg_date_to_in
	GROUP BY SH.SH_CUST,  RM.RM_PARENT, SH.SH_ORDER,  SH.SH_SPARE_STR_5,SH.SH_CUST_REF,SH.SH_ADDRESS,SH.SH_SUBURB,
		SH.SH_CITY, SH.SH_STATE , SH.SH_POST_CODE , SH.SH_NOTE_1 ,SH.SH_NOTE_2 ,SH.SH_SPARE_DBL_9;
    cdsg_rec cdsg_cur%ROWTYPE;
  BEGIN
    OPEN cdsg_cur;
    FETCH cdsg_cur INTO cdsg_rec;
    WHILE cdsg_cur%FOUND
    LOOP
      DBMS_OUTPUT.PUT_LINE(cdsg_rec.SH_CUST || ',' || cdsg_rec.RM_PARENT || ',' || cdsg_rec.SH_SPARE_STR_5 || ',' || cdsg_rec.SH_ORDER || ',' || cdsg_rec.SH_SPARE_DBL_9 || ',' || cdsg_rec.SH_NOTE_2 || ',' || cdsg_rec.SH_NOTE_1 || ',' || cdsg_rec.SH_CITY );
      FETCH cdsg_cur INTO cdsg_rec;
    END LOOP;
  CLOSE cdsg_cur;
 END DESP_STOCK_GET;


 PROCEDURE GET_IAGRACV_PDS    (
																  iagracv_date_from_in 	IN  SD.SD_ADD_DATE%TYPE,
																  iagracv_date_to_in 		IN  SD.SD_EDIT_DATE%TYPE,
                                  iagracv_cur IN OUT sys_refcursor
																  )
	AS
	--CURSOR iagracv_cur IS
  v_query           CLOB;
	 BEGIN
     v_query := q'{  SELECT 'PDS' AS "SCAN"
              ,SD.SD_ORDER
              ,SD.SD_LINE
              ,SD.SD_STOCK
              ,SD.SD_ADD_DATE
              ,SD.SD_LAST_PICK_NUM
              ,SD.SD_ADD_TIME
              ,SD.SD_ADD_OP
              ,SD.SD_LOCN
              ,SD.SD_QTY_ORDER
              ,SD.SD_QTY_DEMAND
              ,SD.SD_QTY_DESP
              ,SD.SD_QTY_UNIT
              ,SD.SD_DESC
              ,IU.IU_TO_METRIC * SD.SD_QTY_ORDER  AS "SinglesQTY"
              ,NULL AS "PASS/FAIL"
              ,NULL AS "OriginalPromoQty"
              ,IA_ALT_STOCK AS "IA_ALT_STOCK"
              ,IA_STOCK AS "IA_STOCK"
              ,IM_XX_CC01_QTY  AS "SPDS_QTY"
              ,NULL  AS "PDS_STOCK"

        FROM SD
          INNER JOIN IU ON IU.IU_UNIT =  SD.SD_QTY_UNIT
          INNER JOIN IM ON IM.IM_STOCK = SD.SD_STOCK
          LEFT OUTER JOIN IA ON SD.SD_STOCK = IA.IA_STOCK
        WHERE SD.SD_ADD_DATE >= :iagracv_date_from_in1 AND SD.SD_ADD_DATE <= :iagracv_date_to_in1
        AND IM_CUST IN ('RACV','IAG')
        --AND SD.SD_LAST_PICK_NUM IS NOT NULL
        AND IA_STOCK IS NOT NULL
        --AND SD.SD_ORDER = '   1540276'
        AND     SD.SD_STATUS <> 3
        AND IA_ADD_OP = 'PRJ'



        UNION ALL

        SELECT 'SPDS' AS "SCAN"
          ,SD.SD_ORDER
          ,SD.SD_LINE
          ,SD.SD_STOCK
          ,SD.SD_ADD_DATE
          ,SD.SD_LAST_PICK_NUM
          ,SD.SD_ADD_TIME
          ,SD.SD_ADD_OP
          ,SD.SD_LOCN
          ,SD.SD_QTY_ORDER
          ,SD.SD_QTY_DEMAND
          ,SD.SD_QTY_DESP
          ,SD.SD_QTY_UNIT
          ,SD.SD_DESC
          ,IU.IU_TO_METRIC * SD.SD_QTY_ORDER  AS "SinglesQTY"
          ,CASE    WHEN (To_Number((SELECT IM_XX_CC01_QTY
                                      FROM IM
                                      LEFT OUTER JOIN IA ON IA_STOCK = IM.IM_STOCK
                                      WHERE  IA_ADD_OP = 'PRJ'
                                      AND IA_STOCK = (SELECT D4.SD_STOCK
                                                        FROM SD D4
                                                        LEFT OUTER JOIN IA ON IA_STOCK = D4.SD_STOCK
                                                        WHERE D4.SD_ORDER = SD.SD_ORDER
                                                        AND IA_ADD_OP = 'PRJ'
                                                        AND IA_ALT_STOCK = SD.SD_STOCK AND rownum <= 1 ))
                                      *
                                    (SELECT D5.SD_QTY_ORDER
                                      FROM SD D5
                                      LEFT OUTER JOIN IA ON IA_STOCK = D5.SD_STOCK
                                      WHERE D5.SD_ORDER = SD.SD_ORDER
                                      AND IA_ADD_OP = 'PRJ'
                                      AND IA_ALT_STOCK = SD.SD_STOCK AND rownum <= 1 )) ) = SD.SD_QTY_ORDER THEN  'PASS'
                  ELSE 'FAIL' END AS "PASS/FAIL"
          ,(SELECT IM_XX_CC01_QTY
            FROM IM
            INNER JOIN IA ON IA_STOCK = IM.IM_STOCK
            WHERE  IA_ADD_OP = 'PRJ'
            AND IA_ALT_STOCK = SD.SD_STOCK ) AS "OriginalPromoQty"
          ,NULL AS "IA_ALT_STOCK"
          ,NULL AS "IA_STOCK"
          ,To_Number((SELECT IM_XX_CC01_QTY
                        FROM IM
                        LEFT OUTER JOIN IA ON IA_STOCK = IM.IM_STOCK
                        WHERE  IA_ADD_OP = 'PRJ'
                        AND IA_STOCK = (SELECT D4.SD_STOCK
                                          FROM SD D4
                                          LEFT OUTER JOIN IA ON IA_STOCK = D4.SD_STOCK
                                          WHERE D4.SD_ORDER = SD.SD_ORDER
                                          AND IA_ADD_OP = 'PRJ'
                                          AND IA_ALT_STOCK = SD.SD_STOCK AND rownum <= 1 ))
                        *
                      (SELECT D5.SD_QTY_ORDER
                        FROM SD D5
                        LEFT OUTER JOIN IA ON IA_STOCK = D5.SD_STOCK
                        WHERE D5.SD_ORDER = SD.SD_ORDER
                        AND IA_ADD_OP = 'PRJ'
                        AND IA_ALT_STOCK = SD.SD_STOCK AND rownum <= 1 )) AS "EXP SPDS_QTY"
                ,(SELECT SD_STOCK
              FROM SD D3
              INNER JOIN IA ON IA_STOCK = D3.SD_STOCK
              WHERE SD_ORDER = SD.SD_ORDER
              AND IA_ADD_OP = 'PRJ'
              AND IA_ALT_STOCK = SD.SD_STOCK AND rownum <= 1 )  AS "PDS_STOCK"
          FROM SD
        INNER JOIN IU ON IU.IU_UNIT =  SD.SD_QTY_UNIT
        INNER JOIN IM ON IM.IM_STOCK = SD.SD_STOCK
        INNER JOIN IA ON SD.SD_STOCK = IA.IA_ALT_STOCK
          WHERE SD.SD_ADD_DATE >= :iagracv_date_from_in2 AND SD.SD_ADD_DATE <= :iagracv_date_to_in2
          AND IM_CUST IN ('RACV','IAG')
        --AND SD.SD_ORDER = '   1540276'
          AND SD.SD_STATUS <> 3

        UNION ALL

        SELECT 'NEITHER' AS "SCAN"
              ,SD.SD_ORDER
              ,SD.SD_LINE
              ,SD.SD_STOCK
              ,SD.SD_ADD_DATE
              ,SD.SD_LAST_PICK_NUM
              ,SD.SD_ADD_TIME
              ,SD.SD_ADD_OP
              ,SD.SD_LOCN
              ,SD.SD_QTY_ORDER
              ,SD.SD_QTY_DEMAND
              ,SD.SD_QTY_DESP
              ,SD.SD_QTY_UNIT
              ,SD.SD_DESC
              ,IU.IU_TO_METRIC * SD.SD_QTY_ORDER  AS "SinglesQTY"
              --,NULL  AS "ExpPromoSinglesQTY"
              ,NULL AS "PASS/FAIL"
              ,NULL AS "OriginalPromoQty"
              ,NULL AS "IA_ALT_STOCK"
              ,NULL AS "IA_STOCK"
              ,NULL  AS "SPDS_QTY"
              ,NULL AS "PDS_STOCK"
        FROM SD
          INNER JOIN IU ON IU.IU_UNIT =  SD.SD_QTY_UNIT
          INNER JOIN IM ON IM.IM_STOCK = SD.SD_STOCK
          --LEFT OUTER JOIN IA ON SD.SD_STOCK != IA.IA_ALT_STOCK AND  SD.SD_STOCK != IA.IA_STOCK
        WHERE SD.SD_ADD_DATE >= :iagracv_date_from_in3 AND SD.SD_ADD_DATE <= :iagracv_date_to_in3
        AND IM_CUST IN ('RACV','IAG')
        --AND SD.SD_LAST_PICK_NUM IS NOT NULL
        --AND IA_ALT_STOCK IS NULL
        AND SD.SD_STATUS <> 3
        --AND SD.SD_ORDER = '   1540276' --AND SD.SD_ORDER <= '   1558484'
        AND SD_STOCK NOT IN (SELECT IM_STOCK
                          FROM  IM INNER JOIN IA ON IM_STOCK = IA_STOCK
                          WHERE IA_ADD_OP = 'PRJ' AND IM_XX_CC01_QTY > 0)
        AND SD_STOCK NOT IN (SELECT IM_STOCK
                          FROM  IM INNER JOIN IA ON IM_STOCK = IA_ALT_STOCK) ORDER BY 6,1,3 Asc   }';
     --iagracv_rec iagracv_cur;
  --iagracv_rec iagracv_cur%ROWTYPE;
  --BEGIN
   -- OPEN iagracv_cur;
   -- FETCH iagracv_cur INTO iagracv_rec;
   -- WHILE iagracv_cur%FOUND
   -- LOOP
    OPEN iagracv_cur FOR v_query
     USING iagracv_date_from_in, iagracv_date_to_in, iagracv_date_from_in, iagracv_date_to_in,iagracv_date_from_in,iagracv_date_to_in;
     DBMS_OUTPUT.PUT_LINE('Successfully inserted fresh freight data - get all data as no pre selections');


		--DBMS_OUTPUT.PUT_LINE(SD.SD_ORDER || ',' || iagracv_rec.SD_LINE || ',' || iagracv_rec.SD_STOCK || ',' || iagracv_rec.SD_ADD_DATE || ',' || iagracv_rec.SD_LAST_PICK_NUM || ',' || iagracv_rec.SD_ADD_TIME
    --|| ',' || iagracv_rec.SD_ADD_OP || ',' || iagracv_rec.SD_LOCN || ',' || iagracv_rec.SD_QTY_ORDER || ',' || iagracv_rec.SD_QTY_DEMAND || ',' || iagracv_rec.SD_QTY_DESP
    --|| ',' || iagracv_rec.SD_QTY_UNIT || ',' || iagracv_rec.IA_ALT_STOCK || ',' || iagracv_rec.IA_STOCK || ',' || iagracv_rec.SPDS_QTY  || ',' || iagracv_rec.PDS_STOCK);
   --   FETCH iagracv_cur INTO iagracv_rec;
   -- END LOOP;
 -- CLOSE iagracv_cur;
 END GET_IAGRACV_PDS;

  PROCEDURE GET_IAGRACV_PDS_DEBUG    (
																  iagracv_date_from_in 	IN  SD.SD_ADD_DATE%TYPE,
																  iagracv_date_to_in 		IN  SD.SD_EDIT_DATE%TYPE
                                  --iagracv_cur IN OUT sys_refcursor
																  )
	AS
	CURSOR iagracv_cur IS
  SELECT 'PDS' AS "SCAN"
              ,SD.SD_ORDER
              ,SD.SD_LINE
              ,SD.SD_STOCK
              ,SD.SD_ADD_DATE
              ,SD.SD_LAST_PICK_NUM
              ,SD.SD_ADD_TIME
              ,SD.SD_ADD_OP
              ,SD.SD_LOCN
              ,SD.SD_QTY_ORDER
              ,SD.SD_QTY_DEMAND
              ,SD.SD_QTY_DESP
              ,SD.SD_QTY_UNIT
              ,SD.SD_DESC
              ,IU.IU_TO_METRIC * SD.SD_QTY_ORDER  AS "SinglesQTY"
              ,NULL AS "PASS/FAIL"
              ,NULL AS "OriginalPromoQty"
              ,IA_ALT_STOCK AS "IA_ALT_STOCK"
              ,IA_STOCK AS "IA_STOCK"
              ,IM_XX_CC01_QTY  AS "SPDS_QTY"
              ,NULL  AS "PDS_STOCK"

        FROM SD
          INNER JOIN IU ON IU.IU_UNIT =  SD.SD_QTY_UNIT
          INNER JOIN IM ON IM.IM_STOCK = SD.SD_STOCK
          LEFT OUTER JOIN IA ON SD.SD_STOCK = IA.IA_STOCK
        WHERE SD.SD_ADD_DATE >= iagracv_date_from_in AND SD.SD_ADD_DATE <= iagracv_date_to_in
        AND IM_CUST IN ('RACV','IAG')
        --AND SD.SD_LAST_PICK_NUM IS NOT NULL
        AND IA_STOCK IS NOT NULL
        --AND SD.SD_ORDER = '   1540276'
        AND     SD.SD_STATUS <> 3
        AND IA_ADD_OP = 'PRJ'



        UNION ALL

        SELECT 'SPDS' AS "SCAN"
          ,SD.SD_ORDER
          ,SD.SD_LINE
          ,SD.SD_STOCK
          ,SD.SD_ADD_DATE
          ,SD.SD_LAST_PICK_NUM
          ,SD.SD_ADD_TIME
          ,SD.SD_ADD_OP
          ,SD.SD_LOCN
          ,SD.SD_QTY_ORDER
          ,SD.SD_QTY_DEMAND
          ,SD.SD_QTY_DESP
          ,SD.SD_QTY_UNIT
          ,SD.SD_DESC
          ,IU.IU_TO_METRIC * SD.SD_QTY_ORDER  AS "SinglesQTY"
          ,CASE    WHEN (To_Number((SELECT IM_XX_CC01_QTY
                                      FROM IM
                                      LEFT OUTER JOIN IA ON IA_STOCK = IM.IM_STOCK
                                      WHERE  IA_ADD_OP = 'PRJ'
                                      AND IA_STOCK = (SELECT D4.SD_STOCK
                                                        FROM SD D4
                                                        LEFT OUTER JOIN IA ON IA_STOCK = D4.SD_STOCK
                                                        WHERE D4.SD_ORDER = SD.SD_ORDER
                                                        AND IA_ADD_OP = 'PRJ'
                                                        AND IA_ALT_STOCK = SD.SD_STOCK AND rownum <= 1 ))
                                      *
                                    (SELECT D5.SD_QTY_ORDER
                                      FROM SD D5
                                      LEFT OUTER JOIN IA ON IA_STOCK = D5.SD_STOCK
                                      WHERE D5.SD_ORDER = SD.SD_ORDER
                                      AND IA_ADD_OP = 'PRJ'
                                      AND IA_ALT_STOCK = SD.SD_STOCK AND rownum <= 1 )) ) = SD.SD_QTY_ORDER THEN  'PASS'
                  ELSE 'FAIL' END AS "PASS/FAIL"
          ,(SELECT IM_XX_CC01_QTY
            FROM IM
            INNER JOIN IA ON IA_STOCK = IM.IM_STOCK
            WHERE  IA_ADD_OP = 'PRJ'
            AND IA_ALT_STOCK = SD.SD_STOCK ) AS "OriginalPromoQty"
          ,NULL AS "IA_ALT_STOCK"
          ,NULL AS "IA_STOCK"
          ,To_Number((SELECT IM_XX_CC01_QTY
                        FROM IM
                        LEFT OUTER JOIN IA ON IA_STOCK = IM.IM_STOCK
                        WHERE  IA_ADD_OP = 'PRJ'
                        AND IA_STOCK = (SELECT D4.SD_STOCK
                                          FROM SD D4
                                          LEFT OUTER JOIN IA ON IA_STOCK = D4.SD_STOCK
                                          WHERE D4.SD_ORDER = SD.SD_ORDER
                                          AND IA_ADD_OP = 'PRJ'
                                          AND IA_ALT_STOCK = SD.SD_STOCK AND rownum <= 1 ))
                        *
                      (SELECT D5.SD_QTY_ORDER
                        FROM SD D5
                        LEFT OUTER JOIN IA ON IA_STOCK = D5.SD_STOCK
                        WHERE D5.SD_ORDER = SD.SD_ORDER
                        AND IA_ADD_OP = 'PRJ'
                        AND IA_ALT_STOCK = SD.SD_STOCK AND rownum <= 1 )) AS "EXP SPDS_QTY"
                ,(SELECT SD_STOCK
              FROM SD D3
              INNER JOIN IA ON IA_STOCK = D3.SD_STOCK
              WHERE SD_ORDER = SD.SD_ORDER
              AND IA_ADD_OP = 'PRJ'
              AND IA_ALT_STOCK = SD.SD_STOCK AND rownum <= 1 )  AS "PDS_STOCK"
          FROM SD
        INNER JOIN IU ON IU.IU_UNIT =  SD.SD_QTY_UNIT
        INNER JOIN IM ON IM.IM_STOCK = SD.SD_STOCK
        INNER JOIN IA ON SD.SD_STOCK = IA.IA_ALT_STOCK
          WHERE SD.SD_ADD_DATE >= iagracv_date_from_in AND SD.SD_ADD_DATE <= iagracv_date_to_in
          AND IM_CUST IN ('RACV','IAG')
        --AND SD.SD_ORDER = '   1540276'
          AND SD.SD_STATUS <> 3

        UNION ALL

        SELECT 'NEITHER' AS "SCAN"
              ,SD.SD_ORDER
              ,SD.SD_LINE
              ,SD.SD_STOCK
              ,SD.SD_ADD_DATE
              ,SD.SD_LAST_PICK_NUM
              ,SD.SD_ADD_TIME
              ,SD.SD_ADD_OP
              ,SD.SD_LOCN
              ,SD.SD_QTY_ORDER
              ,SD.SD_QTY_DEMAND
              ,SD.SD_QTY_DESP
              ,SD.SD_QTY_UNIT
              ,SD.SD_DESC
              ,IU.IU_TO_METRIC * SD.SD_QTY_ORDER  AS "SinglesQTY"
              --,NULL  AS "ExpPromoSinglesQTY"
              ,NULL AS "PASS/FAIL"
              ,NULL AS "OriginalPromoQty"
              ,NULL AS "IA_ALT_STOCK"
              ,NULL AS "IA_STOCK"
              ,NULL  AS "SPDS_QTY"
              ,NULL AS "PDS_STOCK"
        FROM SD
          INNER JOIN IU ON IU.IU_UNIT =  SD.SD_QTY_UNIT
          INNER JOIN IM ON IM.IM_STOCK = SD.SD_STOCK
          --LEFT OUTER JOIN IA ON SD.SD_STOCK != IA.IA_ALT_STOCK AND  SD.SD_STOCK != IA.IA_STOCK
        WHERE SD.SD_ADD_DATE >= iagracv_date_from_in AND SD.SD_ADD_DATE <= iagracv_date_to_in
        AND IM_CUST IN ('RACV','IAG')
        --AND SD.SD_LAST_PICK_NUM IS NOT NULL
        --AND IA_ALT_STOCK IS NULL
        AND SD.SD_STATUS <> 3
        --AND SD.SD_ORDER = '   1540276' --AND SD.SD_ORDER <= '   1558484'
        AND SD_STOCK NOT IN (SELECT IM_STOCK
                          FROM  IM INNER JOIN IA ON IM_STOCK = IA_STOCK
                          WHERE IA_ADD_OP = 'PRJ' AND IM_XX_CC01_QTY > 0)
        AND SD_STOCK NOT IN (SELECT IM_STOCK
                          FROM  IM INNER JOIN IA ON IM_STOCK = IA_ALT_STOCK) ORDER BY 6,1,3 Asc;
  iagracv_rec iagracv_cur%ROWTYPE;
  BEGIN
    OPEN iagracv_cur;
    FETCH iagracv_cur INTO iagracv_rec;
    WHILE iagracv_cur%FOUND
    LOOP
    --OPEN iagracv_cur FOR v_query
     --USING iagracv_date_from_in, iagracv_date_to_in, iagracv_date_from_in, iagracv_date_to_in,iagracv_date_from_in,iagracv_date_to_in;
     --DBMS_OUTPUT.PUT_LINE('Successfully inserted fresh freight data - get all data as no pre selections');


		DBMS_OUTPUT.PUT_LINE(iagracv_rec.SD_ORDER || ',' || iagracv_rec.SD_LINE || ',' || iagracv_rec.SD_STOCK || ',' || iagracv_rec.SD_ADD_DATE || ',' || iagracv_rec.SD_LAST_PICK_NUM || ',' || iagracv_rec.SD_ADD_TIME
    || ',' || iagracv_rec.SD_ADD_OP || ',' || iagracv_rec.SD_LOCN || ',' || iagracv_rec.SD_QTY_ORDER || ',' || iagracv_rec.SD_QTY_DEMAND || ',' || iagracv_rec.SD_QTY_DESP
    || ',' || iagracv_rec.SD_QTY_UNIT || ',' || iagracv_rec.IA_ALT_STOCK || ',' || iagracv_rec.IA_STOCK || ',' || iagracv_rec.SPDS_QTY  || ',' || iagracv_rec.PDS_STOCK);
      FETCH iagracv_cur INTO iagracv_rec;
    END LOOP;
  CLOSE iagracv_cur;
 END GET_IAGRACV_PDS_DEBUG;


  FUNCTION F_BREAK_UNIT_PRICE
                  ( rm_cust_in IN II.II_CUST%TYPE,
                    stock_in   IN II.II_STOCK%TYPE)
  RETURN NUMBER

  AS

  price_break NUMBER;

  BEGIN
    IF stock_in IS NOT NULL THEN
        SELECT II_BREAK_LCL
        INTO  price_break
	      FROM II
	      WHERE II_BREAK_LCL > 0.000001
        AND II_STOCK = stock_in
	      AND II_CUST= rm_cust_in;
        --price_in := II.II_BREAK_LCL;
        RETURN price_break;
    ELSE
      RETURN 'N/A';
    END IF;
  END F_BREAK_UNIT_PRICE;

  PROCEDURE get_desp_stocks_cur_p
                      (
                          gds_cust_in IN IM.IM_CUST%TYPE,
                          gds_cust_not_in IN  IM.IM_CUST%TYPE,
                          gds_stock_not_in IN IM.IM_STOCK%TYPE,
                          gds_stock_not_in2 IN IM.IM_STOCK%TYPE,
                          gds_start_date_in IN SH.SH_EDIT_DATE%TYPE,
                          gds_end_date_in IN SH.SH_ADD_DATE%TYPE,
                          desp_stock_list_cur_var IN OUT stock_ref_cur
                        )
  AS
  BEGIN
      OPEN desp_stock_list_cur_var FOR
    	SELECT    SH.SH_CUST
			         ,SH.SH_ORDER
		           ,substr(To_Char(ST.ST_DESP_DATE),0,10)
	             ,SD.SD_STOCK
			         ,SD.SD_DESC
			        /*,CASE  WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in   AND IM.IM_OWNED_BY = 0 THEN SD.SD_SELL_PRICE
			                WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in   AND IM.IM_OWNED_BY = 1 THEN NI.NI_SELL_VALUE/NI_NX_QUANTITY
                      WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in   AND eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NOT NULL THEN eom_report_pkg.F_BREAK_UNIT_PRICE(RM_GROUP_CUST,SD_STOCK)
			                WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in   AND eom_report_pkg.F_BREAK_UNIT_PRICE(RM.RM_GROUP_CUST,SD.SD_STOCK) IS NULL THEN  SD_XX_OW_UNIT_PRICE
			                ELSE NULL
			                END,*/
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
 	AND       SD.SD_LAST_PICK_NUM = ST.ST_PICK
	GROUP BY  SH.SH_CUST,SH.SH_ORDER,
			      ST.ST_DESP_DATE,
			      SD.SD_DESC,SD.SD_STOCK,SD.SD_XX_OW_UNIT_PRICE,SD.SD_SELL_PRICE,
            IM.IM_BRAND,IM.IM_OWNED_BY,IM.IM_CUST,
            NI.NI_SELL_VALUE,NI.NI_NX_QUANTITY,
            RM.RM_GROUP_CUST;
 END get_desp_stocks_cur_p;


  PROCEDURE get_desp_stocks_curp (
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
  nbreakpoint   NUMBER;
BEGIN
  nbreakpoint := 1;
  EXECUTE IMMEDIATE 'BEGIN eom_report_pkg.GROUP_CUST_START; END;';
  OPEN gds_src_get_desp_stocks FOR
  SELECT     SH.SH_CUST   AS "Customer"
            ,Tmp_Group_Cust.sGroupCust   AS "Parent"
            ,CASE
              WHEN IM.IM_CUST <> gds_cust_not_in AND SH.SH_SPARE_STR_4 IS NULL THEN SH.SH_CUST
              WHEN IM.IM_CUST <> gds_cust_not_in THEN SH.SH_SPARE_STR_4
              WHEN IM.IM_CUST =  gds_cust_not_in THEN IM.IM_XX_COST_CENTRE01
              ELSE IM.IM_XX_COST_CENTRE01
			      END AS "CostCentre"
           ,SH.SH_ORDER AS "Order"
           ,SH.SH_SPARE_STR_5         AS "OrderwareNum"
           ,SH.SH_CUST_REF            AS "CustomerRef"
           ,ST.ST_PICK                AS "Pickslip"
           ,SD.SD_XX_PICKLIST_NUM     AS "PickNum"
           ,ST.ST_PSLIP               AS "DespatchNote"
           ,substr(To_Char(ST.ST_DESP_DATE),0,10) AS "DespatchDate"
           ,CASE   WHEN SD.SD_STOCK IS NOT NULL THEN SD.SD_STOCK
			      ELSE NULL
			      END                       AS "FeeType"
           ,SD.SD_STOCK               AS "Item"
           ,SD.SD_DESC                AS "Description"
           ,SL.SL_PSLIP_QTY           AS "Qty"
           ,SD.SD_QTY_UNIT            AS "UOI"
           ,CASE WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in   AND IM.IM_OWNED_BY = 0 THEN SD.SD_SELL_PRICE
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in   AND IM.IM_OWNED_BY = 1 THEN NI.NI_SELL_VALUE/NI_NX_QUANTITY
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in    AND eom_report_pkg.F_BREAK_UNIT_PRICE(Tmp_Group_Cust.sGroupCust,SD.SD_STOCK) IS NOT NULL THEN eom_report_pkg.F_BREAK_UNIT_PRICE(Tmp_Group_Cust.sGroupCust,SD_STOCK)
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in    AND eom_report_pkg.F_BREAK_UNIT_PRICE(Tmp_Group_Cust.sGroupCust,SD.SD_STOCK) IS NULL THEN  SD.SD_XX_OW_UNIT_PRICE
                 ELSE NULL
                 END AS "Batch/UnitPrice"
           ,CASE WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in THEN To_Number(IM.IM_REPORTING_PRICE)
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  THEN  eom_report_pkg.F_BREAK_UNIT_PRICE(Tmp_Group_Cust.sGroupCust,SD.SD_STOCK)
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  AND eom_report_pkg.F_BREAK_UNIT_PRICE(Tmp_Group_Cust.sGroupCust,SD.SD_STOCK) IS NULL THEN  SD.SD_XX_OW_UNIT_PRICE
                 ELSE NULL
                 END                        AS "OWUnitPrice"
           ,CASE WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in AND IM.IM_OWNED_BY = 0 THEN SD.SD_SELL_PRICE * SL.SL_PSLIP_QTY
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in AND IM.IM_OWNED_BY = 1 THEN (NI.NI_SELL_VALUE/NI.NI_NX_QUANTITY) * SL.SL_PSLIP_QTY
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  AND eom_report_pkg.F_BREAK_UNIT_PRICE(Tmp_Group_Cust.sGroupCust,SD.SD_STOCK) IS NOT NULL THEN  eom_report_pkg.F_BREAK_UNIT_PRICE(Tmp_Group_Cust.sGroupCust,SD.SD_STOCK) * SL.SL_PSLIP_QTY
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  AND eom_report_pkg.F_BREAK_UNIT_PRICE(Tmp_Group_Cust.sGroupCust,SD.SD_STOCK) IS NULL THEN  SD.SD_XX_OW_UNIT_PRICE * SL.SL_PSLIP_QTY
                 ELSE NULL
                 END          AS "DExcl"
           ,CASE WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in THEN To_Number(IM.IM_REPORTING_PRICE)
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  THEN  eom_report_pkg.F_BREAK_UNIT_PRICE(Tmp_Group_Cust.sGroupCust,SD.SD_STOCK)
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  AND eom_report_pkg.F_BREAK_UNIT_PRICE(Tmp_Group_Cust.sGroupCust,SD.SD_STOCK) IS NULL THEN  SD.SD_XX_OW_UNIT_PRICE
                 ELSE NULL
                 END                       AS "Excl_Total"
           ,CASE WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in AND IM.IM_OWNED_BY = 0 THEN (SD.SD_SELL_PRICE * SL.SL_PSLIP_QTY) * 1.1
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in AND IM.IM_OWNED_BY = 1 THEN ((NI.NI_SELL_VALUE/NI.NI_NX_QUANTITY) * SL.SL_PSLIP_QTY) * 1.1
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  AND eom_report_pkg.F_BREAK_UNIT_PRICE(Tmp_Group_Cust.sGroupCust,SD.SD_STOCK) IS NOT NULL THEN  (eom_report_pkg.F_BREAK_UNIT_PRICE(Tmp_Group_Cust.sGroupCust,SD.SD_STOCK) * SL.SL_PSLIP_QTY) * 1.1
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  AND eom_report_pkg.F_BREAK_UNIT_PRICE(Tmp_Group_Cust.sGroupCust,SD.SD_STOCK) IS NULL THEN  (SD.SD_XX_OW_UNIT_PRICE * SL.SL_PSLIP_QTY) * 1.1
                 ELSE NULL
                 END          AS "DIncl"
           ,CASE WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in AND IM.IM_OWNED_BY = 0 THEN (SD.SD_SELL_PRICE * SL.SL_PSLIP_QTY) * 1.1
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in AND IM.IM_OWNED_BY = 1 THEN ((NI.NI_SELL_VALUE/NI.NI_NX_QUANTITY) * SL.SL_PSLIP_QTY) * 1.1
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  AND eom_report_pkg.F_BREAK_UNIT_PRICE(Tmp_Group_Cust.sGroupCust,SD.SD_STOCK) IS NOT NULL THEN  (eom_report_pkg.F_BREAK_UNIT_PRICE(Tmp_Group_Cust.sGroupCust,SD.SD_STOCK) * SL.SL_PSLIP_QTY) * 1.1
                 WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  AND eom_report_pkg.F_BREAK_UNIT_PRICE(Tmp_Group_Cust.sGroupCust,SD.SD_STOCK) IS NULL THEN  (SD.SD_XX_OW_UNIT_PRICE * SL.SL_PSLIP_QTY) * 1.1
                 ELSE NULL
                 END          AS "Incl_Total"
	         ,CASE WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST <> gds_cust_not_in THEN To_Number(IM.IM_REPORTING_PRICE)
			           WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  THEN  eom_report_pkg.F_BREAK_UNIT_PRICE(Tmp_Group_Cust.sGroupCust,SD.SD_STOCK)
			           WHEN SD.SD_STOCK IS NOT NULL AND IM.IM_CUST = gds_cust_not_in  AND eom_report_pkg.F_BREAK_UNIT_PRICE(Tmp_Group_Cust.sGroupCust,SD.SD_STOCK) IS NULL THEN  SD.SD_XX_OW_UNIT_PRICE
			           ELSE NULL
			           END                    AS "ReportingPrice"
           ,SH.SH_ADDRESS             AS "Address"
           ,SH.SH_SUBURB              AS "Address2"
           ,SH.SH_CITY                AS "Suburb"
           ,SH.SH_STATE               AS "State"
           ,SH.SH_POST_CODE           AS "Postcode"
           ,SH.SH_NOTE_1              AS "DeliverTo"
           ,SH.SH_NOTE_2              AS "AttentionTo"
           ,ST.ST_WEIGHT              AS "Weight"
           ,ST.ST_PACKAGES            AS "Packages"
           ,SH.SH_SPARE_DBL_9         AS "OrderSource"
           ,NULL AS "Pallet/Shelf Space"
           ,NULL AS "Locn"
           ,NULL AS "AvailSOH"
           ,NULL AS "CountOfStocks"
           ,NULL AS "Email"
           ,IM.IM_BRAND AS Brand
           ,NULL AS OwnedBy
           ,NULL AS sProfile
           ,NULL AS WaiveFee
           ,NULL AS "Cost"
           ,SH.SH_ADD_DATE As "OrderDate"
           ,ST.ST_PICK_PRINT_DATE As "PickPrintedDate"
           ,ST.ST_ADD_OP As "PickOp"
           ,ST.ST_ADD_DATE As "PickDate"
	FROM  PWIN175.SD
			  RIGHT JOIN PWIN175.SH  ON SH.SH_ORDER  = SD.SD_ORDER
			  LEFT JOIN PWIN175.ST  ON ST.ST_PICK  = SD.SD_LAST_PICK_NUM
        LEFT JOIN PWIN175.SL   ON SL.SL_PICK   = ST.ST_PICK
			  --INNER JOIN PWIN175.RM  ON RM.RM_CUST  = SH.SH_CUST
        INNER JOIN Tmp_Group_Cust ON Tmp_Group_Cust.sCust = SH.SH_CUST
			  INNER JOIN PWIN175.IM  ON IM.IM_STOCK = SD.SD_STOCK
        INNER JOIN PWIN175.NI  ON NI.NI_NV_EXT_KEY = SL.SL_UID
  WHERE NI.NI_STRENGTH = 3 AND NI.NI_DATE = ST.ST_DESP_DATE AND NI.NI_STOCK = SD_STOCK AND NI.NI_STATUS <> 0
	AND     SH.SH_STATUS <> 3
  AND     sGroupCust IN (gds_cust_in)
	AND       SH.SH_ORDER = ST.ST_ORDER
  AND       ST.ST_DESP_DATE >= gds_start_date_in AND ST.ST_DESP_DATE <= gds_end_date_in
 	--AND       ST.ST_DESP_DATE >= '10-APR-2014' AND ST.ST_DESP_DATE <= '15-APR-2014'
	AND       SD.SD_LAST_PICK_NUM = ST.ST_PICK
	GROUP BY  SH.SH_CUST,SH.SH_ORDER,SH.SH_ADD_DATE,SH.SH_ADDRESS,SH.SH_SUBURB,SH.SH_CITY,SH.SH_STATE,SH.SH_POST_CODE,SH.SH_NOTE_1,SH.SH_NOTE_2,SH.SH_CAMPAIGN, SH.SH_SPARE_STR_4,SH.SH_SPARE_DBL_9,SH.SH_CUST_REF,SH.SH_SPARE_STR_5,
			      ST.ST_ADD_DATE,ST.ST_ADD_OP,ST.ST_PICK_PRINT_DATE,ST.ST_DESP_DATE,ST.ST_WEIGHT,ST.ST_PACKAGES,ST.ST_PSLIP,ST.ST_PICK,
			      SD.SD_DESC,SD.SD_STOCK,SD.SD_XX_OW_UNIT_PRICE,SD.SD_SELL_PRICE,SD.SD_LINE,SD.SD_EXCL,SD.SD_INCL,SD.SD_QTY_ORDER,SD.SD_QTY_UNIT,SD.SD_XX_PICKLIST_NUM,
            IM.IM_BRAND,IM.IM_OWNED_BY,IM.IM_CUST,IM.IM_XX_COST_CENTRE01,IM.IM_REPORTING_PRICE,
            NI.NI_SELL_VALUE,NI.NI_NX_QUANTITY,
            --RM.RM_GROUP_CUST,RM.RM_PARENT,
            Tmp_Group_Cust.sGroupCust,
            SL.SL_PSLIP_QTY;





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
 EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('LUX Stock query failed at checkpoint ' || nbreakpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
 END get_desp_stocks_curp;


  PROCEDURE get_finance_transactions_curp (
			gds_cust_in IN IM.IM_CUST%TYPE,
			gds_start_date_in IN SH.SH_EDIT_DATE%TYPE,
			gds_end_date_in IN SH.SH_ADD_DATE%TYPE,
			gds_src_get_finance_trans OUT sys_refcursor
)
AS
  nbreakpoint   NUMBER;
BEGIN
  nbreakpoint := 1;
  OPEN gds_src_get_finance_trans FOR
  SELECT IM_CUST, NI_STOCK,NI_DATE
    , CASE
        WHEN NI_TRAN_TYPE = 0 THEN 'ORDER'
        WHEN NI_TRAN_TYPE = 1 THEN 'RECEIPT'
        WHEN NI_TRAN_TYPE = 2 THEN 'STOCKTAKE'
        WHEN NI_TRAN_TYPE = 3 THEN 'ISSUE'
        WHEN NI_TRAN_TYPE = 4 THEN 'TRANSFER'
        WHEN NI_TRAN_TYPE = 5 THEN 'ADJUST'
        WHEN NI_TRAN_TYPE = 6 THEN 'DEMAND'
     END AS TransactionType
     ,CASE
        WHEN NI_STATUS = 0 THEN 'EXTERNAL'
        WHEN NI_STATUS = 1 THEN 'LIVE POSITIVE'
        WHEN NI_STATUS = 2 THEN 'LIVE NEGATIVE'
        WHEN NI_STATUS = 3 THEN 'DEAD POSITIVE'
        WHEN NI_STATUS = 4 THEN 'LIVE POSITIVE'
        WHEN NI_STATUS = 5 THEN 'REVERSED'
     END AS Status
     ,CASE
        WHEN NI_STRENGTH = 0 THEN 'VOLATILE'
        WHEN NI_STRENGTH = 1 THEN 'TENTATIVE'
        WHEN NI_STRENGTH = 2 THEN 'EXPECTED'
        WHEN NI_STRENGTH = 3 THEN 'ACTUAL'
     END AS Strength,
     CASE
          WHEN IM_OWNED_By = 0 THEN 'COMPANY'
          WHEN IM_OWNED_By = 1 THEN 'CUSTOMER'
      END                       AS "OwnedBy"
     ,NI_QUANTITY,NI_EXT_KEY, NI_LOCN
  FROM NI RIGHT JOIN IM ON IM_STOCK = NI_STOCK
  WHERE NI_ADD_DATE >= gds_start_date_in AND NI_ADD_DATE <= gds_end_date_in AND IM_CUST = gds_cust_in;
 EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('LUX Stock query failed at checkpoint ' || nbreakpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
 END get_finance_transactions_curp;



 PROCEDURE get_stockonhand_curp (
			gsc_cust_in IN IM.IM_CUST%TYPE,
			--gsc_start_date_in IN SH.SH_EDIT_DATE%TYPE,
			--gsc_end_date_in IN SH.SH_ADD_DATE%TYPE,
			gsc_warehouse_in IN VARCHAR2,
			gsc_src_get_soh_trans OUT sys_refcursor
    )
AS
  nbreakpoint   NUMBER;
BEGIN
  nbreakpoint := 1;
  OPEN gsc_src_get_soh_trans FOR
  SELECT IM_CUST, NI_STOCK,NI_DATE
    , CASE
        WHEN NI_TRAN_TYPE = 0 THEN 'ORDER'
        WHEN NI_TRAN_TYPE = 1 THEN 'RECEIPT'
        WHEN NI_TRAN_TYPE = 2 THEN 'STOCKTAKE'
        WHEN NI_TRAN_TYPE = 3 THEN 'ISSUE'
        WHEN NI_TRAN_TYPE = 4 THEN 'TRANSFER'
        WHEN NI_TRAN_TYPE = 5 THEN 'ADJUST'
        WHEN NI_TRAN_TYPE = 6 THEN 'DEMAND'
     END AS TransactionType
     ,CASE
        WHEN NI_STATUS = 0 THEN 'EXTERNAL'
        WHEN NI_STATUS = 1 THEN 'LIVE POSITIVE'
        WHEN NI_STATUS = 2 THEN 'LIVE NEGATIVE'
        WHEN NI_STATUS = 3 THEN 'DEAD POSITIVE'
        WHEN NI_STATUS = 4 THEN 'LIVE POSITIVE'
        WHEN NI_STATUS = 5 THEN 'REVERSED'
     END AS Status
     ,CASE
        WHEN NI_STRENGTH = 0 THEN 'VOLATILE'
        WHEN NI_STRENGTH = 1 THEN 'TENTATIVE'
        WHEN NI_STRENGTH = 2 THEN 'EXPECTED'
        WHEN NI_STRENGTH = 3 THEN 'ACTUAL'
     END AS Strength,
      CASE
          WHEN IM_OWNED_By = 0 THEN 'COMPANY'
          WHEN IM_OWNED_By = 1 THEN 'CUSTOMER'
      END                       AS "OwnedBy"
     ,NI_QUANTITY,NI_AVAIL_ACTUAL,NI_EXT_KEY,NI_ID, NI_LOCN
  FROM NI RIGHT JOIN IM ON IM_STOCK = NI_STOCK
  WHERE IM_CUST = gsc_cust_in AND EOM_REPORT_PKG.f_GetWarehouse_from_SD(NI_LOCN) LIKE substr(gsc_warehouse_in,1)
  AND NI_AVAIL_ACTUAL > 0;
  --HAVING EOM_REPORT_PKG.f_GetWarehouse_from_SD(NI_LOCN) LIKE :warehouse_in;
 EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Stock On Hand query failed at checkpoint ' || nbreakpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
 END get_stockonhand_curp;


  FUNCTION f_GetWarehouse_from_SD
		(
		  v_sd_locn_in VARCHAR2
		  )
    RETURN VARCHAR2

  IS

      v_rtn_value VARCHAR2(50);

      v_wh_locn_1 CONSTANT VARCHAR2(50) := 'SYDNEY';
      v_wh_locn_2 CONSTANT VARCHAR2(50) := 'MELBOURNE';
      v_wh_locn_3 CONSTANT VARCHAR2(50) := 'OBSOLETE';
      v_wh_locn_4 CONSTANT VARCHAR2(50) := 'DMMETLIFE';
      v_wh_locn_5 CONSTANT VARCHAR2(50) := 'FLOOR';
      v_wh_locn_6 CONSTANT VARCHAR2(50) := 'HOMEBUSH';
  BEGIN
		  IF        Upper(SubStr(v_sd_locn_in,0,1)) = 'S' 	THEN v_rtn_value := v_wh_locn_1;-- RETURN v_rtn_value;
		  ELSIF 	Upper(SubStr(v_sd_locn_in,0,1)) = 'H' 	THEN v_rtn_value := v_wh_locn_1;--  RETURN v_rtn_value;
		  ELSIF  	Upper(SubStr(v_sd_locn_in,0,1)) = 'R' 	THEN v_rtn_value := v_wh_locn_1;--  RETURN v_rtn_value;
		  ELSIF  	Upper(SubStr(v_sd_locn_in,0,1)) = 'M' 	THEN v_rtn_value := v_wh_locn_2;--  RETURN v_rtn_value;
		  ELSIF  	Upper(SubStr(v_sd_locn_in,0,1)) = 'O' 	THEN v_rtn_value := v_wh_locn_3;--  RETURN v_rtn_value;
		  ELSIF  	Upper(SubStr(v_sd_locn_in,0,1)) = 'D' 	THEN v_rtn_value := v_wh_locn_4;--  RETURN v_rtn_value;
		  ELSIF  	Upper(v_sd_locn_in) = 'FLOORM' 		      THEN v_rtn_value := v_wh_locn_2;--  RETURN v_rtn_value;
		  ELSIF  	Upper(v_sd_locn_in) = 'FLOORS' 		      THEN v_rtn_value := v_wh_locn_1;--  RETURN v_rtn_value;
		  ELSIF  	Upper(v_sd_locn_in) = 'FLOOR' 			    THEN v_rtn_value := v_wh_locn_5;--  RETURN v_rtn_value;
      --ELSE      v_rtn_value := NULL                                                    ;--  RETURN v_rtn_value;
		  END IF;
      RETURN v_rtn_value;
	  END f_GetWarehouse_from_SD;

  FUNCTION f_GetFreightZone_RTA
      (
		  v_spare_int_9_in NUMBER
		  )
    RETURN VARCHAR2
    IS
      v_rtn_value VARCHAR2(50);
      v_zone_1 CONSTANT VARCHAR2(50) := 'SYDNEY METRO';
      v_zone_2 CONSTANT VARCHAR2(50) := 'OUTSIDE SYDNEY METRO';
      v_zone_3 CONSTANT VARCHAR2(50) := 'NSW COUNTRY';
      v_zone_4 CONSTANT VARCHAR2(50) := 'DMMETLIFE';
      v_zone_5 CONSTANT VARCHAR2(50) := 'OTHER CITIES';
      v_zone_6 CONSTANT VARCHAR2(50) := 'INTERSTATE';
    BEGIN
      IF v_spare_int_9_in = 1 THEN v_rtn_value := v_zone_1;
        ELSIF v_spare_int_9_in = 2 THEN v_rtn_value := v_zone_2;
         ELSIF v_spare_int_9_in = 3 THEN v_rtn_value := v_zone_3;
          ELSIF v_spare_int_9_in = 4 THEN v_rtn_value := v_zone_4;
           ELSIF v_spare_int_9_in = 5 THEN v_rtn_value := v_zone_5;
            ELSIF v_spare_int_9_in = 6 THEN v_rtn_value := v_zone_6;
       END IF;
      RETURN v_rtn_value;
    END f_GetFreightZone_RTA;

  PROCEDURE get_desp_freight_curp (
			gdf_cust_in IN IM.IM_CUST%TYPE,
			gdf_stock_in IN IM.IM_STOCK%TYPE,
			gdf_warehouse_in IN VARCHAR2,
			gdf_start_date_in IN SH.SH_EDIT_DATE%TYPE,
			gdf_end_date_in IN SH.SH_ADD_DATE%TYPE,
			gdf_desp_freight_cur OUT sys_refcursor
)
AS
  nbreakpoint   NUMBER;
  v_query           CLOB;
BEGIN
  nbreakpoint := 1;
  If gdf_warehouse_in IS NULL AND gdf_cust_in IS NULL THEN
    v_query := q'{
      select    s.SH_CUST                AS "Customer",
          r.RM_PARENT              AS "Parent",
          s.SH_SPARE_STR_4         AS "CostCentre",
          s.SH_ORDER               AS "Order",
          s.SH_SPARE_STR_5         AS "OrderwareNum",
          s.SH_CUST_REF            AS "CustomerRef",
          t.ST_PICK                AS "Pickslip",
          d.SD_XX_PICKLIST_NUM     AS "PickNum",
          t.ST_PSLIP               AS "DespatchNote",
          substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
          'Freight Fee' AS "FeeType",
          d.SD_STOCK               AS "Item",
          --'="' || To_Char(d.SD_DESC) || '"'               AS "Description",
           To_Char(d.SD_DESC)   AS "Description",
          CASE  WHEN d.SD_LINE IS NOT NULL THEN  1
                ELSE NULL
                END                     AS "Qty",
          CASE  WHEN d.SD_LINE IS NOT NULL THEN  '1'
                ELSE NULL
                END                      AS "UOI",

          CASE  WHEN d.SD_STOCK like :stock AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT <> 'BORBUI' AND r.RM_PARENT <> 'BEYONDBLUE') THEN d.SD_SELL_PRICE
                WHEN d.SD_STOCK like :stock1 AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT = 'BORBUI' OR r.RM_PARENT = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.125) And (t.ST_SPARE_DBL_1 > 0.00) THEN 1.70
                WHEN d.SD_STOCK like :stock2 AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT = 'BORBUI' OR r.RM_PARENT = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.250) And (t.ST_SPARE_DBL_1 > 0.126) THEN 2.30
                WHEN d.SD_STOCK like :stock3 AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT = 'BORBUI' OR r.RM_PARENT = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.500) And (t.ST_SPARE_DBL_1 > 0.251) THEN 3.40
                WHEN d.SD_STOCK like :stock4 AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT = 'BORBUI' OR r.RM_PARENT = 'BEYONDBLUE') AND (t.ST_WEIGHT > 0.01) THEN d.SD_SELL_PRICE
                ELSE d.SD_SELL_PRICE
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
          t.ST_SPARE_DBL_1              AS "Post Weight",
          t.ST_PACKAGES            AS "Packages",
          s.SH_SPARE_DBL_9         AS "OrderSource",
          NULL AS "Pallet/Shelf Space",
          NULL AS "Locn",
          0 AS "AvailSOH",
          0 AS "CountOfStocks",
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
                ELSE ''
                END AS Email,
                'N/A' AS Brand,
             NULL AS    OwnedBy,
             NULL AS    sProfile,
             NULL AS    WaiveFee,
             d.SD_COST_PRICE As   Cost,
             d.SD_NOTE_1 AS OriginalIFSCost,
             EOM_REPORT_PKG.f_GetWarehouse_from_SD(d.SD_LOCN) AS Warehouse,
             EOM_REPORT_PKG.f_GetFreightZone_RTA(s.SH_SPARE_INT_9) AS "Zone"
    FROM      PWIN175.SD d
          INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
          INNER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_PICK))  = LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM))
          INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
    WHERE     s.SH_ORDER = d.SD_ORDER
    AND       d.SD_STOCK LIKE :stock5
    AND       s.SH_ORDER = t.ST_ORDER
    AND       d.SD_SELL_PRICE >= 0.1
    AND       t.ST_DESP_DATE >= :start_date  AND t.ST_DESP_DATE <=  :end_date
    AND   d.SD_ADD_OP LIKE 'SERV%'
   -- HAVING EOM_REPORT_PKG.f_GetWarehouse_from_SD(d.SD_LOCN) LIKE :warehouse

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
          t.ST_WEIGHT,t.ST_SPARE_DBL_1,
          t.ST_PACKAGES,
          s.SH_SPARE_DBL_9,
          r.RM_PARENT,
          s.SH_SPARE_STR_5,
          s.SH_CUST_REF,
          s.SH_SPARE_STR_3,
          s.SH_SPARE_STR_1,
          t.ST_SPARE_DBL_1,
          d.SD_XX_PSLIP_NUM,
          d.SD_ADD_DATE,
          d.SD_XX_PICKLIST_NUM,
          d.SD_COST_PRICE,
          d.SD_NOTE_1,
          d.SD_LOCN,s.SH_SPARE_INT_9

  UNION ALL


     select    s.SH_CUST                AS "Customer",
            r.RM_PARENT              AS "Parent",
            s.SH_SPARE_STR_4         AS "CostCentre",
            s.SH_ORDER               AS "Order",
            s.SH_SPARE_STR_5         AS "OrderwareNum",
            s.SH_CUST_REF            AS "CustomerRef",
            t.ST_PICK                AS "Pickslip",
            d.SD_XX_PICKLIST_NUM     AS "PickNum",
            t.ST_PSLIP               AS "DespatchNote",
            substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
            'Manual Freight Fee' AS "FeeType",
            d.SD_STOCK               AS "Item",
            --'="' || To_Char(d.SD_DESC) || '"'               AS "Description",
             To_Char(d.SD_DESC)   AS "Description",
            CASE  WHEN d.SD_LINE IS NOT NULL THEN  1
                  ELSE NULL
                  END                     AS "Qty",
            CASE  WHEN d.SD_LINE IS NOT NULL THEN  '1'
                  ELSE NULL
                  END                      AS "UOI",
            d.SD_SELL_PRICE          AS "UnitPrice",
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
            t.ST_SPARE_DBL_1              AS "Post Weight",
            t.ST_PACKAGES            AS "Packages",
            s.SH_SPARE_DBL_9         AS "OrderSource",
            NULL AS "Pallet/Shelf Space",
            NULL AS "Locn",
            0 AS "AvailSOH",
            0 AS "CountOfStocks",
            CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
                  ELSE ''
                  END AS Email,
                  'N/A' AS Brand,
               NULL AS    OwnedBy,
               NULL AS    sProfile,
               NULL AS    WaiveFee,
               d.SD_COST_PRICE As   Cost,
               d.SD_NOTE_1 AS OriginalIFSCost,
               EOM_REPORT_PKG.f_GetWarehouse_from_SD(d.SD_LOCN) AS Warehouse,
               EOM_REPORT_PKG.f_GetFreightZone_RTA(s.SH_SPARE_INT_9) AS "Zone"
      FROM      PWIN175.SD d
            INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
            INNER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_ORDER))  = LTRIM(RTRIM(d.SD_ORDER))
            INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
      WHERE     s.SH_ORDER = d.SD_ORDER
      AND       d.SD_STOCK IN ('COURIERM','COURIERS','COURIER','DETENTIONTIMEM','DETENTIONTIMES','FREIGHTDUTY')
      AND       s.SH_ORDER = t.ST_ORDER
      AND       d.SD_SELL_PRICE >= 0.1
      AND       d.SD_ADD_DATE >= :start_date2 AND d.SD_ADD_DATE <= :end_date2
      AND   d.SD_ADD_OP NOT LIKE 'SERV%' AND d.SD_ADD_OP NOT LIKE 'PRJ%'
      --HAVING EOM_REPORT_PKG.f_GetWarehouse_from_SD(d.SD_LOCN) LIKE :warehouse2
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
            t.ST_WEIGHT,t.ST_SPARE_DBL_1,
            t.ST_PACKAGES,
            s.SH_SPARE_DBL_9,
            r.RM_PARENT,
            s.SH_SPARE_STR_5,
            s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,d.SD_COST_PRICE,d.SD_NOTE_1, d.SD_LOCN,s.SH_SPARE_INT_9
     }';
     OPEN gdf_desp_freight_cur FOR v_query
     USING gdf_stock_in, gdf_stock_in, gdf_stock_in, gdf_stock_in, gdf_stock_in, gdf_stock_in, gdf_start_date_in, gdf_end_date_in, gdf_start_date_in, gdf_end_date_in;
     DBMS_OUTPUT.PUT_LINE('Successfully inserted fresh freight data - get all data as no pre selections');
  ELSIF  gdf_warehouse_in IS NOT NULL AND gdf_cust_in IS NOT NULL THEN
         v_query := q'{
      select    s.SH_CUST                AS "Customer",
          r.RM_PARENT              AS "Parent",
          s.SH_SPARE_STR_4         AS "CostCentre",
          s.SH_ORDER               AS "Order",
          s.SH_SPARE_STR_5         AS "OrderwareNum",
          s.SH_CUST_REF            AS "CustomerRef",
          t.ST_PICK                AS "Pickslip",
          d.SD_XX_PICKLIST_NUM     AS "PickNum",
          t.ST_PSLIP               AS "DespatchNote",
          substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
          'Freight Fee' AS "FeeType",
          d.SD_STOCK               AS "Item",
          --'="' || To_Char(d.SD_DESC) || '"'               AS "Description",
           To_Char(d.SD_DESC)   AS "Description",
          CASE  WHEN d.SD_LINE IS NOT NULL THEN  1
                ELSE NULL
                END                     AS "Qty",
          CASE  WHEN d.SD_LINE IS NOT NULL THEN  '1'
                ELSE NULL
                END                      AS "UOI",

          CASE  WHEN d.SD_STOCK like :stock AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT <> 'BORBUI' AND r.RM_PARENT <> 'BEYONDBLUE') THEN d.SD_SELL_PRICE
                WHEN d.SD_STOCK like :stock1 AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT = 'BORBUI' OR r.RM_PARENT = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.125) And (t.ST_SPARE_DBL_1 > 0.00) THEN 1.70
                WHEN d.SD_STOCK like :stock2 AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT = 'BORBUI' OR r.RM_PARENT = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.250) And (t.ST_SPARE_DBL_1 > 0.126) THEN 2.30
                WHEN d.SD_STOCK like :stock3 AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT = 'BORBUI' OR r.RM_PARENT = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.500) And (t.ST_SPARE_DBL_1 > 0.251) THEN 3.40
                WHEN d.SD_STOCK like :stock4 AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT = 'BORBUI' OR r.RM_PARENT = 'BEYONDBLUE') AND (t.ST_WEIGHT > 0.01) THEN d.SD_SELL_PRICE
                ELSE d.SD_SELL_PRICE
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
          t.ST_SPARE_DBL_1              AS "Post Weight",
          t.ST_PACKAGES            AS "Packages",
          s.SH_SPARE_DBL_9         AS "OrderSource",
          NULL AS "Pallet/Shelf Space",
          NULL AS "Locn",
          0 AS "AvailSOH",
          0 AS "CountOfStocks",
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
                ELSE ''
                END AS Email,
                'N/A' AS Brand,
             NULL AS    OwnedBy,
             NULL AS    sProfile,
             NULL AS    WaiveFee,
             d.SD_COST_PRICE As   Cost,
             d.SD_NOTE_1 AS OriginalIFSCost,
             EOM_REPORT_PKG.f_GetWarehouse_from_SD(d.SD_LOCN) AS Warehouse,
             EOM_REPORT_PKG.f_GetFreightZone_RTA(s.SH_SPARE_INT_9) AS "Zone"
    FROM      PWIN175.SD d
          INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
          INNER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_PICK))  = LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM))
          INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
    WHERE     s.SH_ORDER = d.SD_ORDER
    AND       d.SD_STOCK LIKE :stock5
    AND       s.SH_ORDER = t.ST_ORDER
    AND       d.SD_SELL_PRICE >= 0.1
    AND       t.ST_DESP_DATE >= :start_date  AND t.ST_DESP_DATE <=  :end_date
    AND   d.SD_ADD_OP LIKE 'SERV%'
     AND r.RM_PARENT = :cust
    HAVING EOM_REPORT_PKG.f_GetWarehouse_from_SD(d.SD_LOCN) LIKE :warehouse

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
          t.ST_WEIGHT,t.ST_SPARE_DBL_1,
          t.ST_PACKAGES,
          s.SH_SPARE_DBL_9,
          r.RM_PARENT,
          s.SH_SPARE_STR_5,
          s.SH_CUST_REF,
          s.SH_SPARE_STR_3,
          s.SH_SPARE_STR_1,
          t.ST_SPARE_DBL_1,
          d.SD_XX_PSLIP_NUM,
          d.SD_ADD_DATE,
          d.SD_XX_PICKLIST_NUM,
          d.SD_COST_PRICE,
          d.SD_NOTE_1,
          d.SD_LOCN,s.SH_SPARE_INT_9

  UNION ALL


     select    s.SH_CUST                AS "Customer",
            r.RM_PARENT              AS "Parent",
            s.SH_SPARE_STR_4         AS "CostCentre",
            s.SH_ORDER               AS "Order",
            s.SH_SPARE_STR_5         AS "OrderwareNum",
            s.SH_CUST_REF            AS "CustomerRef",
            t.ST_PICK                AS "Pickslip",
            d.SD_XX_PICKLIST_NUM     AS "PickNum",
            t.ST_PSLIP               AS "DespatchNote",
            substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
            'Manual Freight Fee' AS "FeeType",
            d.SD_STOCK               AS "Item",
            --'="' || To_Char(d.SD_DESC) || '"'               AS "Description",
             To_Char(d.SD_DESC)   AS "Description",
            CASE  WHEN d.SD_LINE IS NOT NULL THEN  1
                  ELSE NULL
                  END                     AS "Qty",
            CASE  WHEN d.SD_LINE IS NOT NULL THEN  '1'
                  ELSE NULL
                  END                      AS "UOI",
            d.SD_SELL_PRICE          AS "UnitPrice",
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
            t.ST_SPARE_DBL_1              AS "Post Weight",
            t.ST_PACKAGES            AS "Packages",
            s.SH_SPARE_DBL_9         AS "OrderSource",
            NULL AS "Pallet/Shelf Space",
            NULL AS "Locn",
            0 AS "AvailSOH",
            0 AS "CountOfStocks",
            CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
                  ELSE ''
                  END AS Email,
                  'N/A' AS Brand,
               NULL AS    OwnedBy,
               NULL AS    sProfile,
               NULL AS    WaiveFee,
               d.SD_COST_PRICE As   Cost,
               d.SD_NOTE_1 AS OriginalIFSCost,
               EOM_REPORT_PKG.f_GetWarehouse_from_SD(d.SD_LOCN) AS Warehouse,
               EOM_REPORT_PKG.f_GetFreightZone_RTA(s.SH_SPARE_INT_9) AS "Zone"
      FROM      PWIN175.SD d
            INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
            INNER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_ORDER))  = LTRIM(RTRIM(d.SD_ORDER))
            INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
      WHERE     s.SH_ORDER = d.SD_ORDER
      AND       d.SD_STOCK IN ('COURIERM','COURIERS','COURIER','DETENTIONTIMEM','DETENTIONTIMES','FREIGHTDUTY')
      AND       s.SH_ORDER = t.ST_ORDER
      AND       d.SD_SELL_PRICE >= 0.1
      AND       d.SD_ADD_DATE >= :start_date2 AND d.SD_ADD_DATE <= :end_date2
      AND   d.SD_ADD_OP NOT LIKE 'SERV%' AND d.SD_ADD_OP NOT LIKE 'PRJ%'
       AND r.RM_PARENT = :cust
      HAVING EOM_REPORT_PKG.f_GetWarehouse_from_SD(d.SD_LOCN) LIKE :warehouse2
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
            t.ST_WEIGHT,t.ST_SPARE_DBL_1,
            t.ST_PACKAGES,
            s.SH_SPARE_DBL_9,
            r.RM_PARENT,
            s.SH_SPARE_STR_5,
            s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,d.SD_COST_PRICE,d.SD_NOTE_1, d.SD_LOCN,s.SH_SPARE_INT_9
      }';
      OPEN gdf_desp_freight_cur FOR v_query
      USING gdf_stock_in, gdf_stock_in, gdf_stock_in, gdf_stock_in, gdf_stock_in, gdf_stock_in, gdf_start_date_in, gdf_end_date_in, gdf_cust_in, gdf_warehouse_in, gdf_start_date_in, gdf_end_date_in, gdf_cust_in, gdf_warehouse_in;
      DBMS_OUTPUT.PUT_LINE('Successfully inserted fresh freight data matching to customer and warehouse');
   ELSIF  gdf_warehouse_in IS NULL AND gdf_cust_in IS NOT NULL THEN
         v_query := q'{
          select    s.SH_CUST                AS "Customer",
          r.RM_PARENT              AS "Parent",
          s.SH_SPARE_STR_4         AS "CostCentre",
          s.SH_ORDER               AS "Order",
          s.SH_SPARE_STR_5         AS "OrderwareNum",
          s.SH_CUST_REF            AS "CustomerRef",
          t.ST_PICK                AS "Pickslip",
          d.SD_XX_PICKLIST_NUM     AS "PickNum",
          t.ST_PSLIP               AS "DespatchNote",
          substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
          'Freight Fee' AS "FeeType",
          d.SD_STOCK               AS "Item",
          --'="' || To_Char(d.SD_DESC) || '"'               AS "Description",
           To_Char(d.SD_DESC)   AS "Description",
          CASE  WHEN d.SD_LINE IS NOT NULL THEN  1
                ELSE NULL
                END                     AS "Qty",
          CASE  WHEN d.SD_LINE IS NOT NULL THEN  '1'
                ELSE NULL
                END                      AS "UOI",

          CASE  WHEN d.SD_STOCK like :stock AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT <> 'BORBUI' AND r.RM_PARENT <> 'BEYONDBLUE') THEN d.SD_SELL_PRICE
                WHEN d.SD_STOCK like :stock1 AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT = 'BORBUI' OR r.RM_PARENT = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.125) And (t.ST_SPARE_DBL_1 > 0.00) THEN 1.70
                WHEN d.SD_STOCK like :stock2 AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT = 'BORBUI' OR r.RM_PARENT = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.250) And (t.ST_SPARE_DBL_1 > 0.126) THEN 2.30
                WHEN d.SD_STOCK like :stock3 AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT = 'BORBUI' OR r.RM_PARENT = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.500) And (t.ST_SPARE_DBL_1 > 0.251) THEN 3.40
                WHEN d.SD_STOCK like :stock4 AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT = 'BORBUI' OR r.RM_PARENT = 'BEYONDBLUE') AND (t.ST_WEIGHT > 0.01) THEN d.SD_SELL_PRICE
                ELSE d.SD_SELL_PRICE
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
          t.ST_SPARE_DBL_1              AS "Post Weight",
          t.ST_PACKAGES            AS "Packages",
          s.SH_SPARE_DBL_9         AS "OrderSource",
          NULL AS "Pallet/Shelf Space",
          NULL AS "Locn",
          0 AS "AvailSOH",
          0 AS "CountOfStocks",
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
                ELSE ''
                END AS Email,
                'N/A' AS Brand,
             NULL AS    OwnedBy,
             NULL AS    sProfile,
             NULL AS    WaiveFee,
             d.SD_COST_PRICE As   Cost,
             d.SD_NOTE_1 AS OriginalIFSCost,
             EOM_REPORT_PKG.f_GetWarehouse_from_SD(d.SD_LOCN) AS Warehouse,
             EOM_REPORT_PKG.f_GetFreightZone_RTA(s.SH_SPARE_INT_9) AS "Zone"
    FROM      PWIN175.SD d
          INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
          INNER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_PICK))  = LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM))
          INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
    WHERE     s.SH_ORDER = d.SD_ORDER
    AND       d.SD_STOCK LIKE :stock5
    AND       s.SH_ORDER = t.ST_ORDER
    AND       d.SD_SELL_PRICE >= 0.1
    AND       t.ST_DESP_DATE >= :start_date  AND t.ST_DESP_DATE <=  :end_date
    AND   d.SD_ADD_OP LIKE 'SERV%'
    AND r.RM_PARENT = :cust
    --HAVING EOM_REPORT_PKG.f_GetWarehouse_from_SD(d.SD_LOCN) LIKE :warehouse

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
          t.ST_WEIGHT,t.ST_SPARE_DBL_1,
          t.ST_PACKAGES,
          s.SH_SPARE_DBL_9,
          r.RM_PARENT,
          s.SH_SPARE_STR_5,
          s.SH_CUST_REF,
          s.SH_SPARE_STR_3,
          s.SH_SPARE_STR_1,
          t.ST_SPARE_DBL_1,
          d.SD_XX_PSLIP_NUM,
          d.SD_ADD_DATE,
          d.SD_XX_PICKLIST_NUM,
          d.SD_COST_PRICE,
          d.SD_NOTE_1,
          d.SD_LOCN,s.SH_SPARE_INT_9

  UNION ALL


     select    s.SH_CUST                AS "Customer",
            r.RM_PARENT              AS "Parent",
            s.SH_SPARE_STR_4         AS "CostCentre",
            s.SH_ORDER               AS "Order",
            s.SH_SPARE_STR_5         AS "OrderwareNum",
            s.SH_CUST_REF            AS "CustomerRef",
            t.ST_PICK                AS "Pickslip",
            d.SD_XX_PICKLIST_NUM     AS "PickNum",
            t.ST_PSLIP               AS "DespatchNote",
            substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
            'Manual Freight Fee' AS "FeeType",
            d.SD_STOCK               AS "Item",
            --'="' || To_Char(d.SD_DESC) || '"'               AS "Description",
             To_Char(d.SD_DESC)   AS "Description",
            CASE  WHEN d.SD_LINE IS NOT NULL THEN  1
                  ELSE NULL
                  END                     AS "Qty",
            CASE  WHEN d.SD_LINE IS NOT NULL THEN  '1'
                  ELSE NULL
                  END                      AS "UOI",
            d.SD_SELL_PRICE          AS "UnitPrice",
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
            t.ST_SPARE_DBL_1              AS "Post Weight",
            t.ST_PACKAGES            AS "Packages",
            s.SH_SPARE_DBL_9         AS "OrderSource",
            NULL AS "Pallet/Shelf Space",
            NULL AS "Locn",
            0 AS "AvailSOH",
            0 AS "CountOfStocks",
            CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
                  ELSE ''
                  END AS Email,
                  'N/A' AS Brand,
               NULL AS    OwnedBy,
               NULL AS    sProfile,
               NULL AS    WaiveFee,
               d.SD_COST_PRICE As   Cost,
               d.SD_NOTE_1 AS OriginalIFSCost,
               EOM_REPORT_PKG.f_GetWarehouse_from_SD(d.SD_LOCN) AS Warehouse,
               EOM_REPORT_PKG.f_GetFreightZone_RTA(s.SH_SPARE_INT_9) AS "Zone"
      FROM      PWIN175.SD d
            INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
            INNER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_ORDER))  = LTRIM(RTRIM(d.SD_ORDER))
            INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
      WHERE     s.SH_ORDER = d.SD_ORDER
      AND       d.SD_STOCK IN ('COURIERM','COURIERS','COURIER','DETENTIONTIMEM','DETENTIONTIMES','FREIGHTDUTY')
      AND       s.SH_ORDER = t.ST_ORDER
      AND       d.SD_SELL_PRICE >= 0.1
      AND       d.SD_ADD_DATE >= :start_date2 AND d.SD_ADD_DATE <= :end_date2
      AND   d.SD_ADD_OP NOT LIKE 'SERV%' AND d.SD_ADD_OP NOT LIKE 'PRJ%'
      AND r.RM_PARENT = :cust
     -- HAVING EOM_REPORT_PKG.f_GetWarehouse_from_SD(d.SD_LOCN) LIKE :warehouse2
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
            t.ST_WEIGHT,t.ST_SPARE_DBL_1,
            t.ST_PACKAGES,
            s.SH_SPARE_DBL_9,
            r.RM_PARENT,
            s.SH_SPARE_STR_5,
            s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,d.SD_COST_PRICE,d.SD_NOTE_1, d.SD_LOCN,s.SH_SPARE_INT_9
      }';
      OPEN gdf_desp_freight_cur FOR v_query
      USING gdf_stock_in, gdf_stock_in, gdf_stock_in, gdf_stock_in, gdf_stock_in, gdf_stock_in, gdf_start_date_in, gdf_end_date_in, gdf_cust_in, gdf_start_date_in, gdf_end_date_in, gdf_cust_in;
      DBMS_OUTPUT.PUT_LINE('Successfully inserted fresh freight data matching to customer only');
  ELSIF  gdf_warehouse_in IS NOT NULL AND gdf_cust_in IS NULL THEN
         v_query := q'{
          select    s.SH_CUST                AS "Customer",
          r.RM_PARENT              AS "Parent",
          s.SH_SPARE_STR_4         AS "CostCentre",
          s.SH_ORDER               AS "Order",
          s.SH_SPARE_STR_5         AS "OrderwareNum",
          s.SH_CUST_REF            AS "CustomerRef",
          t.ST_PICK                AS "Pickslip",
          d.SD_XX_PICKLIST_NUM     AS "PickNum",
          t.ST_PSLIP               AS "DespatchNote",
          substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
          'Freight Fee' AS "FeeType",
          d.SD_STOCK               AS "Item",
          --'="' || To_Char(d.SD_DESC) || '"'               AS "Description",
           To_Char(d.SD_DESC)   AS "Description",
          CASE  WHEN d.SD_LINE IS NOT NULL THEN  1
                ELSE NULL
                END                     AS "Qty",
          CASE  WHEN d.SD_LINE IS NOT NULL THEN  '1'
                ELSE NULL
                END                      AS "UOI",

          CASE  WHEN d.SD_STOCK like :stock AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT <> 'BORBUI' AND r.RM_PARENT <> 'BEYONDBLUE') THEN d.SD_SELL_PRICE
                WHEN d.SD_STOCK like :stock1 AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT = 'BORBUI' OR r.RM_PARENT = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.125) And (t.ST_SPARE_DBL_1 > 0.00) THEN 1.70
                WHEN d.SD_STOCK like :stock2 AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT = 'BORBUI' OR r.RM_PARENT = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.250) And (t.ST_SPARE_DBL_1 > 0.126) THEN 2.30
                WHEN d.SD_STOCK like :stock3 AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT = 'BORBUI' OR r.RM_PARENT = 'BEYONDBLUE') AND (t.ST_SPARE_DBL_1 <= 0.500) And (t.ST_SPARE_DBL_1 > 0.251) THEN 3.40
                WHEN d.SD_STOCK like :stock4 AND d.SD_SELL_PRICE >= 1 AND (r.RM_PARENT = 'BORBUI' OR r.RM_PARENT = 'BEYONDBLUE') AND (t.ST_WEIGHT > 0.01) THEN d.SD_SELL_PRICE
                ELSE d.SD_SELL_PRICE
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
          t.ST_SPARE_DBL_1              AS "Post Weight",
          t.ST_PACKAGES            AS "Packages",
          s.SH_SPARE_DBL_9         AS "OrderSource",
          NULL AS "Pallet/Shelf Space",
          NULL AS "Locn",
          0 AS "AvailSOH",
          0 AS "CountOfStocks",
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
                ELSE ''
                END AS Email,
                'N/A' AS Brand,
             NULL AS    OwnedBy,
             NULL AS    sProfile,
             NULL AS    WaiveFee,
             d.SD_COST_PRICE As   Cost,
             d.SD_NOTE_1 AS OriginalIFSCost,
             EOM_REPORT_PKG.f_GetWarehouse_from_SD(d.SD_LOCN) AS Warehouse,
             EOM_REPORT_PKG.f_GetFreightZone_RTA(s.SH_SPARE_INT_9) AS "Zone"
    FROM      PWIN175.SD d
          INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
          INNER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_PICK))  = LTRIM(RTRIM(d.SD_XX_PICKLIST_NUM))
          INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
    WHERE     s.SH_ORDER = d.SD_ORDER
    AND       d.SD_STOCK LIKE :stock5
    AND       s.SH_ORDER = t.ST_ORDER
    AND       d.SD_SELL_PRICE >= 0.1
    AND       t.ST_DESP_DATE >= :start_date  AND t.ST_DESP_DATE <=  :end_date
    AND   d.SD_ADD_OP LIKE 'SERV%'
    HAVING EOM_REPORT_PKG.f_GetWarehouse_from_SD(d.SD_LOCN) LIKE :warehouse

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
          t.ST_WEIGHT,t.ST_SPARE_DBL_1,
          t.ST_PACKAGES,
          s.SH_SPARE_DBL_9,
          r.RM_PARENT,
          s.SH_SPARE_STR_5,
          s.SH_CUST_REF,
          s.SH_SPARE_STR_3,
          s.SH_SPARE_STR_1,
          t.ST_SPARE_DBL_1,
          d.SD_XX_PSLIP_NUM,
          d.SD_ADD_DATE,
          d.SD_XX_PICKLIST_NUM,
          d.SD_COST_PRICE,
          d.SD_NOTE_1,
          d.SD_LOCN,s.SH_SPARE_INT_9

  UNION ALL


     select    s.SH_CUST                AS "Customer",
            r.RM_PARENT              AS "Parent",
            s.SH_SPARE_STR_4         AS "CostCentre",
            s.SH_ORDER               AS "Order",
            s.SH_SPARE_STR_5         AS "OrderwareNum",
            s.SH_CUST_REF            AS "CustomerRef",
            t.ST_PICK                AS "Pickslip",
            d.SD_XX_PICKLIST_NUM     AS "PickNum",
            t.ST_PSLIP               AS "DespatchNote",
            substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
            'Manual Freight Fee' AS "FeeType",
            d.SD_STOCK               AS "Item",
            --'="' || To_Char(d.SD_DESC) || '"'               AS "Description",
             To_Char(d.SD_DESC)   AS "Description",
            CASE  WHEN d.SD_LINE IS NOT NULL THEN  1
                  ELSE NULL
                  END                     AS "Qty",
            CASE  WHEN d.SD_LINE IS NOT NULL THEN  '1'
                  ELSE NULL
                  END                      AS "UOI",
            d.SD_SELL_PRICE          AS "UnitPrice",
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
            t.ST_SPARE_DBL_1              AS "Post Weight",
            t.ST_PACKAGES            AS "Packages",
            s.SH_SPARE_DBL_9         AS "OrderSource",
            NULL AS "Pallet/Shelf Space",
            NULL AS "Locn",
            0 AS "AvailSOH",
            0 AS "CountOfStocks",
            CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
                  ELSE ''
                  END AS Email,
                  'N/A' AS Brand,
               NULL AS    OwnedBy,
               NULL AS    sProfile,
               NULL AS    WaiveFee,
               d.SD_COST_PRICE As   Cost,
               d.SD_NOTE_1 AS OriginalIFSCost,
               EOM_REPORT_PKG.f_GetWarehouse_from_SD(d.SD_LOCN) AS Warehouse,
               EOM_REPORT_PKG.f_GetFreightZone_RTA(s.SH_SPARE_INT_9) AS "Zone"
      FROM      PWIN175.SD d
            INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
            INNER JOIN PWIN175.ST t  ON LTRIM(RTRIM(t.ST_ORDER))  = LTRIM(RTRIM(d.SD_ORDER))
            INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
      WHERE     s.SH_ORDER = d.SD_ORDER
      AND       d.SD_STOCK IN ('COURIERM','COURIERS','COURIER','DETENTIONTIMEM','DETENTIONTIMES','FREIGHTDUTY')
      AND       s.SH_ORDER = t.ST_ORDER
      AND       d.SD_SELL_PRICE >= 0.1
      AND       d.SD_ADD_DATE >= :start_date2 AND d.SD_ADD_DATE <= :end_date2
      AND   d.SD_ADD_OP NOT LIKE 'SERV%' AND d.SD_ADD_OP NOT LIKE 'PRJ%'
      HAVING EOM_REPORT_PKG.f_GetWarehouse_from_SD(d.SD_LOCN) LIKE :warehouse2
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
            t.ST_WEIGHT,t.ST_SPARE_DBL_1,
            t.ST_PACKAGES,
            s.SH_SPARE_DBL_9,
            r.RM_PARENT,
            s.SH_SPARE_STR_5,
            s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,d.SD_COST_PRICE,d.SD_NOTE_1, d.SD_LOCN,s.SH_SPARE_INT_9
      }';
      OPEN gdf_desp_freight_cur FOR v_query
      USING gdf_stock_in, gdf_stock_in, gdf_stock_in, gdf_stock_in, gdf_stock_in, gdf_stock_in, gdf_start_date_in, gdf_end_date_in, gdf_warehouse_in, gdf_start_date_in, gdf_end_date_in, gdf_warehouse_in;
      DBMS_OUTPUT.PUT_LINE('Successfully inserted fresh freight data matching to warehouse only');
  END IF;

 END get_desp_freight_curp;

  PROCEDURE myproc_test_via_PHP(p1 IN NUMBER, p2 IN OUT NUMBER) AS
  BEGIN
    p2 := p1 * 2;
    DBMS_OUTPUT.PUT_LINE(p2);
  END;

  PROCEDURE list_stocks(cat IN IM.IM_CAT%TYPE) IS
      TYPE cur_typ IS REF CURSOR;
      cur_list_stocks   cur_typ;
      query_str   VARCHAR2(1000);
      stock_name    VARCHAR2(20);
      cat_name     VARCHAR2(20);
  BEGIN
      query_str := 'SELECT IM_STOCK, IM_CUST FROM IM WHERE IM_CAT = cat';
      -- find stocks who belong to the selected cat
      OPEN cur_list_stocks FOR query_str USING cat;
      LOOP
          FETCH cur_list_stocks INTO stock_name, cat_name;
          EXIT WHEN cur_list_stocks%NOTFOUND;
          dbms_Output.PUT_LINE( stock_name || ' EXISTS IN category ' || cat_name);
      END LOOP;
      CLOSE cur_list_stocks;
  END;

  procedure quick_function_test( p_rc OUT SYS_REFCURSOR )AS
  BEGIN
    OPEN p_rc
      for select 1 col1
            from dual;
    CLOSE p_rc;
  END;

  FUNCTION f_getDisplay
    (i_column_tx VARCHAR2,
     i_table_select_tx VARCHAR2,
     i_field_tx VARCHAR2,
     i_value_tx VARCHAR2)
    RETURN VARCHAR2
    IS
      v_out_tx VARCHAR2(2000);
      v_sql_tx VARCHAR2(2000);
    BEGIN
      v_sql_tx := 'SELECT ' ||
                  i_column_tx||
                  ' FROM '||i_table_select_tx||
                  ' WHERE '||i_field_tx||' =:4';
    EXECUTE IMMEDIATE v_sql_tx INTO v_out_tx
      USING i_value_tx;
    RETURN v_out_tx;
  END f_getDisplay;

  FUNCTION f_getDisplay_from_type_bind
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

  PROCEDURE test_get_brand IS
    brand myBrandType;
  BEGIN
    brand := f_getDisplay_from_type_bind ('u.IR_BRAND','AAS');
    DBMS_OUTPUT.PUT_LINE(brand.brand_tx|| ' - ' ||brand.desc_tx);
  END;



  FUNCTION f_getDisplay_oty
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

  function get_cust_stocks(r_coy_num in VARCHAR) return sys_refcursor is
    v_rc sys_refcursor;
  begin
    open v_rc for 'SELECT RM_CUST, RM_COY_NUM, RM_REP, RM_STD_CB_BANK FROM RM WHERE RM_PARENT = :coynum' using r_coy_num;
    return v_rc;
  end;

  /*function populate_custs(coynum in VARCHAR := null)
    return  custtype is
            v_custtype custtype := custtype();  -- Declare a local table structure and initialize it
            v_cnt     number := 0;
            v_rc    sys_refcursor;
            v_cust   VARCHAR2(20);
            v_coynum   VARCHAR2(20);
            v_rep    VARCHAR2(20);
            v_bank VARCHAR(20);

     begin
        v_rc := get_cust_stocks(coynum);
        loop
          fetch v_rc into v_cust, v_coynum, v_rep, v_bank;
          exit when v_rc%NOTFOUND;
          v_custtype.extend;
          v_cnt := v_cnt + 1;
          v_custtype(v_cnt) := custtype(v_cust, v_coynum, v_rep, v_bank);
        end loop;
        close v_rc;
        return v_custtype;
      end;
  */
  FUNCTION refcursor_function
    RETURN SYS_REFCURSOR AS c SYS_REFCURSOR;
  BEGIN
    OPEN c FOR
      select RM_CUST, RM_NAME, RM_XX_PARENT
      from pwin175.RM
      where RM_PARENT = 'TABCORP';
    RETURN c;
  END;

  -- Calling the function from a MAIN BODY
  --variable v_ref_cursor refcursor;
  --exec :v_ref_cursor := refcursor_function();
  --print :v_ref_cursor




   --EOM Create Temp Tables and populate with fresh data
  PROCEDURE EOM_CREATE_TEMP_DATA (p_pick_status IN NUMBER, p_status IN VARCHAR2, sAnalysis IN VARCHAR2, start_date IN VARCHAR2,end_date IN VARCHAR2  ) AS
		nCheckpoint   NUMBER;
		v_query       VARCHAR2(1000);
	BEGIN

	/* Truncate all temp tables*/
		nCheckpoint := 1;
		v_query := 'TRUNCATE TABLE Tmp_Group_Cust';
		EXECUTE IMMEDIATE v_query;

		nCheckpoint := 2;
		v_query := 'TRUNCATE TABLE Tmp_Admin_Data_BreakPrices';
		EXECUTE IMMEDIATE v_query;

		nCheckpoint := 3;
		v_query := 'TRUNCATE TABLE Tmp_Admin_Data_Pickslips';
		EXECUTE IMMEDIATE	v_query;

		nCheckpoint := 4;
		v_query := 'TRUNCATE TABLE Tmp_Admin_Data_Pick_LineCounts';
		EXECUTE IMMEDIATE v_query;

		nCheckpoint := 5;
		v_query := 'TRUNCATE TABLE Tmp_Batch_Price_SL_Stock';
		EXECUTE IMMEDIATE v_query;

		nCheckpoint := 6;
		v_query := 'TRUNCATE TABLE Tmp_Locn_Cnt_By_Cust';
		EXECUTE IMMEDIATE v_query;

		nCheckpoint := 7;
		v_query := 'TRUNCATE TABLE tbl_AdminData';
		EXECUTE IMMEDIATE v_query;

		nCheckpoint := 8;
		v_query := 'TRUNCATE TABLE Tmp_Log_stats';
		EXECUTE IMMEDIATE v_query;

		nCheckpoint := 9;
		v_query := 'TRUNCATE TABLE Tmp_Cust_Reporting';
		EXECUTE IMMEDIATE v_query;

		DBMS_OUTPUT.PUT_LINE('Successfully truncated all temporary tables');

	/* Run Group Cust Procedure*/
		--nCheckpoint := 10;
		--EXECUTE IMMEDIATE 'EXECUTE eom_report_pkg.GROUP_CUST_START';

		--DBMS_OUTPUT.PUT_LINE('Successfully truncated, recreated AND populated Tmp_Group_Cust');

    EXECUTE IMMEDIATE v_query; /* INTO v_out_tx
      USING i_value_tx;*/
	/*Insert fresh temp data*/
		nCheckpoint := 11;
		EXECUTE IMMEDIATE 'INSERT INTO Tmp_Admin_Data_BreakPrices
							SELECT II_STOCK,II_CUST,II_BREAK_LCL
							FROM II INNER JOIN IM ON IM_STOCK = II_STOCK
							AND II_BREAK_LCL > 0.000001';

		nCheckpoint := 12;
    /* v_query := 'SELECT ' ||
                  i_column_tx||
                  ' FROM '||i_table_select_tx||
                  ' WHERE '||i_field_tx||' =:4';*/
    EXECUTE IMMEDIATE q'{INSERT INTO Tmp_Admin_Data_Pickslips
							SELECT LTrim(ST_PICK),LTrim(ST_PSLIP), substr(To_Char(ST_DESP_DATE),0,10), ST_WEIGHT, ST_PACKAGES,ST_XX_NUM_PAL_SW,ST_XX_NUM_PALLETS,ST_XX_NUM_CARTONS
							FROM ST LEFT JOIN SH ON SH_ORDER = ST_ORDER
							WHERE ST_DESP_DATE >= '1-Apr-2014' AND ST_DESP_DATE <= '30-Apr-2014'	--AND ST_PSLIP != 'CANCELLED'
							AND SH_STATUS <> 3}';

		nCheckpoint := 13;
		EXECUTE IMMEDIATE q'{INSERT INTO Tmp_Admin_Data_Pick_LineCounts
							SELECT MAX(SL_LINE),LTrim(SL_PICK), LTrim(SL_ORDER), LTrim(SL_PSLIP),TP.vDateDesp, TP.vPackages,TP.vWeight,TP.vST_XX_NUM_PAL_SW,TP.vST_XX_NUM_PALLETS,TP.vST_XX_NUM_CARTONS
							FROM Tmp_Admin_Data_Pickslips TP RIGHT JOIN SL ON LTrim(SL_PICK) = TP.vPickslip WHERE SL_EDIT_DATE >= '1-Apr-2014' AND SL_EDIT_DATE <= '30-Apr-2014'
							GROUP BY SL_PICK,SL_ORDER,SL_PSLIP,TP.vDateDesp,TP.vPackages,TP.vWeight,TP.vST_XX_NUM_PAL_SW,TP.vST_XX_NUM_PALLETS,TP.vST_XX_NUM_CARTONS}';

		nCheckpoint := 14;
		v_query := q'{INSERT INTO Tmp_Batch_Price_SL_Stock(vBatchStock,vBatchPickNum,vUnitPrice,vDExcl, vQuantity)
						SELECT nz.NI_STOCK, LTrim(RTrim(nz.NI_SL_PSLIP)), CAST((NX_SELL_VALUE/NX_QUANTITY) AS DECIMAL(22,2)) AS "UnitPrice", CAST(xz.NX_SELL_VALUE AS DECIMAL(22,2)), xz.NX_QUANTITY
						FROM  NX xz INNER JOIN NI nz ON nz.NI_NX_MOVEMENT = xz.NX_MOVEMENT
						INNER JOIN NE ez ON ez.NE_ENTRY = nz.NI_ENTRY AND ez.NE_PRICE_ENTRY = xz.NX_ENTRY
						WHERE ez.NE_NV_EXT_TYPE = 1810105
						AND ez.NE_STRENGTH = 3
						AND xz.NX_SELL_VALUE > 0 AND xz.NX_SELL_VALUE IS NOT NULL
						AND xz.NX_QUANTITY > 0
						AND ez.NE_ADD_DATE >= '1-Apr-2014'
						GROUP BY nz.NI_STOCK, nz.NI_SL_PSLIP, xz.NX_SELL_VALUE, xz.NX_QUANTITY}';
		EXECUTE IMMEDIATE v_query; /*  INTO v_out_tx
      USING i_value_tx;; */

		nCheckpoint := 15;
		v_query := q'{INSERT INTO Tmp_Locn_Cnt_By_Cust
						SELECT Count(DISTINCT NI_STOCK) AS CountOfStocks, IL_LOCN, IM_CUST
						FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
						INNER JOIN IM ON IM_STOCK = NI_STOCK
						WHERE IM_CUST IN (SELECT RM_CUST FROM RM WHERE /*RM_PARENT = ' '  AND*/ RM_ANAL = '21VICP' AND RM_TYPE = 0 AND RM_ACTIVE = 1 )
						AND IM_ACTIVE = 1
						AND NI_AVAIL_ACTUAL >= '1'
						AND NI_STATUS <> 0
						GROUP BY IL_LOCN, IM_CUST}';
		EXECUTE IMMEDIATE v_query;

		--nCheckpoint := 16;
		--v_query = q'{}';
		--EXECUTE IMMEDIATE v_query;


		DBMS_OUTPUT.PUT_LINE('Successfully inserted fresh temporary data');


    RETURN;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END EOM_CREATE_TEMP_DATA;

    --EOM Create Temp Tables and populate with fresh data
  PROCEDURE EOM_CREATE_TEMP_DATA_BIND
    (
     sAnalysis IN RM.RM_ANAL%TYPE
     ,start_date IN ST.ST_DESP_DATE%TYPE
     ,end_date IN ST.ST_DESP_DATE%TYPE
     )
     AS
    v_out_tx          VARCHAR2(2000);
    v_query           VARCHAR2(2000);
		nCheckpoint       NUMBER;
		p_status          NUMBER := 3;
    p_ST_PSLIP        ST.ST_PSLIP%TYPE := 'CANCELLED';
    p_NE_NV_EXT_TYPE  NE.NE_NV_EXT_TYPE%TYPE := 1810105;
    p_NE_STRENGTH     NE.NE_STRENGTH%TYPE := 3;
    p_NI_STATUS       NI.NI_STATUS%TYPE := 0;
    p_NI_AVAIL_ACTUAL NI.NI_AVAIL_ACTUAL%TYPE := 0;
    p_IM_ACTIVE       IM.IM_ACTIVE%TYPE := 1;
    p_RM_TYPE         RM.RM_TYPE%TYPE := 0;
    p_SH_STATUS       SH.SH_STATUS%TYPE := 3;
	BEGIN

	/* Truncate all temp tables*/
		nCheckpoint := 1;
		v_query := 'TRUNCATE TABLE Tmp_Group_Cust';
		EXECUTE IMMEDIATE v_query;

		nCheckpoint := 2;
		v_query := 'TRUNCATE TABLE Tmp_Admin_Data_BreakPrices';
		EXECUTE IMMEDIATE v_query;

		nCheckpoint := 3;
		v_query := 'TRUNCATE TABLE Tmp_Admin_Data_Pickslips';
		EXECUTE IMMEDIATE	v_query;

		nCheckpoint := 4;
		v_query := 'TRUNCATE TABLE Tmp_Admin_Data_Pick_LineCounts';
		EXECUTE IMMEDIATE v_query;

		nCheckpoint := 5;
		v_query := 'TRUNCATE TABLE Tmp_Batch_Price_SL_Stock';
		EXECUTE IMMEDIATE v_query;

		nCheckpoint := 6;
		v_query := 'TRUNCATE TABLE Tmp_Locn_Cnt_By_Cust';
		EXECUTE IMMEDIATE v_query;

		nCheckpoint := 7;
		v_query := 'TRUNCATE TABLE tbl_AdminData';
		EXECUTE IMMEDIATE v_query;

		nCheckpoint := 8;
		v_query := 'TRUNCATE TABLE Tmp_Log_stats';
		EXECUTE IMMEDIATE v_query;

		nCheckpoint := 9;
		v_query := 'TRUNCATE TABLE Tmp_Cust_Reporting';
		EXECUTE IMMEDIATE v_query;

		DBMS_OUTPUT.PUT_LINE('Successfully truncated all temporary tables');

	/* Run Group Cust Procedure*/
		nCheckpoint := 10;
		EXECUTE IMMEDIATE 'BEGIN eom_report_pkg.GROUP_CUST_START; END;';

		DBMS_OUTPUT.PUT_LINE('Successfully truncated, recreated AND populated Tmp_Group_Cust');

	/*Insert fresh temp data*/
		nCheckpoint := 11;
		EXECUTE IMMEDIATE 'INSERT INTO Tmp_Admin_Data_BreakPrices
							SELECT II_STOCK,II_CUST,II_BREAK_LCL
							FROM II INNER JOIN IM ON IM_STOCK = II_STOCK
							AND II_BREAK_LCL > 0.000001';

		nCheckpoint := 12;
    EXECUTE IMMEDIATE q'{INSERT INTO Tmp_Admin_Data_Pickslips
							SELECT LTrim(ST_PICK),LTrim(ST_PSLIP), substr(To_Char(ST_DESP_DATE),0,10), ST_WEIGHT, ST_PACKAGES,ST_XX_NUM_PAL_SW,ST_XX_NUM_PALLETS,ST_XX_NUM_CARTONS
							FROM ST LEFT JOIN SH ON SH_ORDER = ST_ORDER
							WHERE ST_DESP_DATE >= :v_start_date AND ST_DESP_DATE <= :v_end_date	AND ST_PSLIP != 'CANCELLED'
							AND SH_STATUS <> 3}'
              USING start_date, end_date;

		nCheckpoint := 13;
		EXECUTE IMMEDIATE q'{INSERT INTO Tmp_Admin_Data_Pick_LineCounts
							SELECT MAX(SL_LINE),LTrim(SL_PICK), LTrim(SL_ORDER), LTrim(SL_PSLIP),TP.vDateDesp, TP.vPackages,TP.vWeight,TP.vST_XX_NUM_PAL_SW,TP.vST_XX_NUM_PALLETS,TP.vST_XX_NUM_CARTONS
							FROM Tmp_Admin_Data_Pickslips TP RIGHT JOIN SL ON LTrim(SL_PICK) = TP.vPickslip WHERE SL_EDIT_DATE >= :v_start_date AND SL_EDIT_DATE <= :v_end_date
							GROUP BY SL_PICK,SL_ORDER,SL_PSLIP,TP.vDateDesp,TP.vPackages,TP.vWeight,TP.vST_XX_NUM_PAL_SW,TP.vST_XX_NUM_PALLETS,TP.vST_XX_NUM_CARTONS}'
		USING start_date, end_date;

		nCheckpoint := 14;
		v_query := q'{INSERT INTO Tmp_Batch_Price_SL_Stock(vBatchStock,vBatchPickNum,vUnitPrice,vDExcl, vQuantity)
						SELECT nz.NI_STOCK, LTrim(RTrim(nz.NI_SL_PSLIP)), CAST((NX_SELL_VALUE/NX_QUANTITY) AS DECIMAL(22,2)) AS "UnitPrice", CAST(xz.NX_SELL_VALUE AS DECIMAL(22,2)), xz.NX_QUANTITY
						FROM  NX xz INNER JOIN NI nz ON nz.NI_NX_MOVEMENT = xz.NX_MOVEMENT
						INNER JOIN NE ez ON ez.NE_ENTRY = nz.NI_ENTRY AND ez.NE_PRICE_ENTRY = xz.NX_ENTRY
						WHERE ez.NE_NV_EXT_TYPE = :v_p_NE_NV_EXT_TYPE
						AND ez.NE_STRENGTH = :v_p_NE_STRANGTH
						AND xz.NX_SELL_VALUE > 0 AND xz.NX_SELL_VALUE IS NOT NULL
						AND xz.NX_QUANTITY > :v_p_NI_AVAIL_ACTUAL
						AND ez.NE_ADD_DATE >= :v_start_date
						GROUP BY nz.NI_STOCK, nz.NI_SL_PSLIP, xz.NX_SELL_VALUE, xz.NX_QUANTITY}';
		EXECUTE IMMEDIATE v_query USING p_NE_NV_EXT_TYPE, p_NE_STRENGTH, p_NI_AVAIL_ACTUAL, start_date;

		nCheckpoint := 15;
		v_query := q'{INSERT INTO Tmp_Locn_Cnt_By_Cust
						SELECT Count(DISTINCT NI_STOCK) AS CountOfStocks, IL_LOCN, IM_CUST
						FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
						INNER JOIN IM ON IM_STOCK = NI_STOCK
						WHERE IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_ANAL = :sAnalysis AND RM_TYPE = :v_p_RM_TYPE AND RM_ACTIVE = :v_p_IM_ACTIVE )
						AND IM_ACTIVE = :v_p_IM_ACTIVE
						AND NI_AVAIL_ACTUAL >= :v_p_NI_AVAIL_ACTUAL
						AND NI_STATUS <> :v_p_NI_STATUS
						GROUP BY IL_LOCN, IM_CUST}';
		EXECUTE IMMEDIATE v_query USING sAnalysis,p_RM_TYPE,p_IM_ACTIVE,p_IM_ACTIVE,p_NI_AVAIL_ACTUAL,p_NI_STATUS;

		--nCheckpoint := 16;
		--v_query = q'{}';
		--EXECUTE IMMEDIATE v_query;


		DBMS_OUTPUT.PUT_LINE('Successfully inserted fresh temporary data');


    RETURN;
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END EOM_CREATE_TEMP_DATA_BIND;

  PROCEDURE EOM_CREATE_TEMP_LOG_DATA
        (
        start_date IN SH.SH_ADD_DATE%TYPE
        ,end_date  IN SH.SH_ADD_DATE%TYPE
        ,cust      IN VARCHAR2
        ,warehouse IN VARCHAR2
        ,gds_src_get_desp_stocks OUT sys_refcursor
        )
     AS
    v_out_tx          VARCHAR2(2000);
    v_query           CLOB;
    v_query2          VARCHAR2(8000);
    v_sql_clob        CLOB;
    nCheckpoint       NUMBER;
    p_status          NUMBER                    := 3;
    p_ST_PSLIP        ST.ST_PSLIP%TYPE          := 'CANCELLED';
    p_NE_NV_EXT_TYPE  NE.NE_NV_EXT_TYPE%TYPE    := 1810105;
    p_NE_STRENGTH     NE.NE_STRENGTH%TYPE       := 3;
    p_NI_STATUS       NI.NI_STATUS%TYPE         := 0;
    p_NI_AVAIL_ACTUAL NI.NI_AVAIL_ACTUAL%TYPE   := 0;
    p_IM_ACTIVE       IM.IM_ACTIVE%TYPE         := 1;
    p_RM_TYPE         RM.RM_TYPE%TYPE           := 0;
    p_SH_STATUS       SH.SH_STATUS%TYPE         := 3;
    BEGIN

    /* Truncate all temp tables*/
        nCheckpoint := 1;
        v_query := 'TRUNCATE TABLE Tmp_Log_stats';
        EXECUTE IMMEDIATE v_query;

    /* Run Group Cust Procedure*/
		nCheckpoint := 10;
		EXECUTE IMMEDIATE 'BEGIN eom_report_pkg.GROUP_CUST_START; END;';

		--DBMS_OUTPUT.PUT_LINE('Successfully truncated, recreated AND populated Tmp_Group_Cust');
     COMMIT;

    /*Insert fresh temp data*/
        nCheckpoint := 2;


   If cust IS NULL AND warehouse IS NULL THEN
        v_query := q'{

                            SELECT   EOM_REPORT_PKG.f_GetWarehouse_from_SD(d.SD_LOCN) AS Warehouse,
                                        sGroupCust,
                                        Count(DISTINCT(SD_ORDER)) AS Total,
                                        --Count(DISTINCT(SD_ORDER)) AS SDCount,
                                        'A- Orders' AS "Type"--, Count(SD_ORDER) AS SDCount
                            FROM SH h LEFT JOIN Tmp_Group_Cust r ON r.sCust = h.SH_CUST
                                 RIGHT JOIN SD d ON d.SD_ORDER = h.SH_ORDER
                                 INNER JOIN RM r2 ON r2.RM_CUST = h.SH_CUST
                            WHERE h.SH_ADD_DATE >= :sh_start_date AND h.SH_ADD_DATE <= :sh_end_date
                            AND h.SH_STATUS <> 3
                            AND h.SH_CAMPAIGN NOT IN( 'ADMIN','OBSOLETE')
                            --AND d.SD_DISPLAY = 1
                            --AND d.SD_STOCK NOT IN('COURIER','COURIERM','COURIERS')
                            AND r2.RM_ACTIVE = 1   --This was the problem
                            AND r.sGroupCust LIKE '%'
                            GROUP BY ROLLUP ( (EOM_REPORT_PKG.f_GetWarehouse_from_SD(d.SD_LOCN)),sGroupCust  )
                            HAVING EOM_REPORT_PKG.f_GetWarehouse_from_SD(d.SD_LOCN) LIKE :warehouseO
                                OR EOM_REPORT_PKG.f_GetWarehouse_from_SD(d.SD_LOCN) LIKE '%'

                       UNION ALL


                            SELECT    EOM_REPORT_PKG.f_GetWarehouse_from_SD(s.SL_LOCN) AS Warehouse,
                                         sGroupCust,
                                        Count(*) AS Total,
                                        'B- Despatches' AS "Type"
                                       --t.ST_PICK,
                                       --h.SH_CAMPAIGN
                            FROM  PWIN175.ST t INNER JOIN SL s ON s.SL_PICK = t.ST_PICK
                                  INNER JOIN SH h ON h.SH_ORDER = t.ST_ORDER--RIGHT JOIN SD d ON d.SD_ORDER = h.SH_ORDER
                                  LEFT JOIN Tmp_Group_Cust r ON r.sCust = h.SH_CUST
                                  INNER JOIN RM r2 ON r2.RM_CUST = h.SH_CUST
                                  --RIGHT JOIN SL s ON s.SL_PICK = t.ST_PICK

                            WHERE t.ST_DESP_DATE >= :st_start_date AND t.ST_DESP_DATE <= :st_end_date
                            AND s.SL_LINE = 1
                            AND t.ST_PSLIP IS NOT NULL AND t.ST_PSLIP <> 'CANCELLED'
                            AND h.SH_STATUS <> 3
                            AND h.SH_CAMPAIGN NOT IN( 'ADMIN','OBSOLETE')
                            AND r2.RM_ACTIVE = 1   --This was the problem
                            AND r.sGroupCust LIKE '%'
                            GROUP BY ROLLUP ((EOM_REPORT_PKG.f_GetWarehouse_from_SD(s.SL_LOCN)), sGroupCust )
                            HAVING EOM_REPORT_PKG.f_GetWarehouse_from_SD(s.SL_LOCN) LIKE :warehouseD
                                  OR EOM_REPORT_PKG.f_GetWarehouse_from_SD(s.SL_LOCN) LIKE '%'


            UNION ALL
             SELECT    EOM_REPORT_PKG.f_GetWarehouse_from_SD(s.SL_LOCN)  AS Warehouse,
                                        sGroupCust AS Customer,
                                        Count(*) AS Total,
                                        'C- Lines' AS "Type"
                            FROM  PWIN175.SL s INNER JOIN SH h ON s.SL_ORDER = h.SH_ORDER
                                  LEFT JOIN Tmp_Group_Cust r ON r.sCust = h.SH_CUST
                                  --RIGHT JOIN SD d ON d.SD_ORDER = h.SH_ORDER
                                  INNER JOIN RM r2 ON r2.RM_CUST = h.SH_CUST
                                  --INNER JOIN IL l ON l.IL_LOCN = s.SL_LOCN
                                  INNER JOIN ST t ON t.ST_PICK = s.SL_PICK
                            WHERE s.SL_EDIT_DATE >= :sl_start_date AND s.SL_EDIT_DATE <= :sl_end_date
                            AND s.SL_PSLIP IS NOT NULL
                            AND h.SH_CAMPAIGN NOT IN( 'ADMIN','OBSOLETE')
                            AND r2.RM_ACTIVE = 1   --This was the problem
                            AND r.sGroupCust LIKE '%'
                            GROUP BY  ROLLUP (EOM_REPORT_PKG.f_GetWarehouse_from_SD(s.SL_LOCN), sGroupCust)
                            HAVING EOM_REPORT_PKG.f_GetWarehouse_from_SD(s.SL_LOCN) LIKE :warehouseL
                                  OR EOM_REPORT_PKG.f_GetWarehouse_from_SD(s.SL_LOCN) LIKE '%'


           UNION ALL

            SELECT (CASE
                                    WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
                                    WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
                                    END) AS Warehouse,

                                    i.IM_CUST AS Cust,
                                   Count(NE_ENTRY) AS Total,
                                   'D- Receipts'  AS "Type"
                            FROM  NA n INNER JOIN IL l ON l.IL_UID = n.NA_EXT_KEY
                                       INNER JOIN NE e ON e.NE_ACCOUNT = n.NA_ACCOUNT
                                       INNER JOIN IM i ON i.IM_STOCK = n.NA_STOCK
                            WHERE n.NA_EXT_TYPE = 1210067
                            AND   l.IL_IN_LOCN NOT IN ('OBSOLETEMEL','OBSOLETESYD','PASTHISTORY', 'CANBERRA')
                            AND   IL_PHYSICAL = 1
                            AND   e.NE_QUANTITY >= '1'
                            AND   e.NE_TRAN_TYPE =  1
                            AND   e.NE_STRENGTH = 3
                            AND   (e.NE_STATUS = 1 OR e.NE_STATUS = 3)
                            AND   e.NE_DATE >= :ne_start_date AND e.NE_DATE <= :ne_end_date
                            AND i.IM_CUST LIKE '%'
                            GROUP BY ((CASE
                                    WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
                                    WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
                                    END)
                            ,i.IM_CUST)
                            HAVING (CASE
                            WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
                            WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
                            END) Like :warehouseR  OR  (CASE
                            WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
                            WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
                            END) Like '%'

         UNION ALL
            SELECT
                                   (CASE
                                    WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
                                    WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
                                    END) AS Warehouse,
                                   i.IM_CUST AS Cust,
                                   Count(DISTINCT l.IL_LOCN) AS Total,  -- test a self join to rid the distinct
                                   (CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                                                                                    ELSE 'F- Shelves'
                                    END) AS "Type"
                            FROM  NA n INNER JOIN IL l ON l.IL_UID = n.NA_EXT_KEY
                                       INNER JOIN NE e ON e.NE_ACCOUNT = n.NA_ACCOUNT
                                       INNER JOIN IM i ON i.IM_STOCK = n.NA_STOCK
                                       --LEFT JOIN Tmp_Group_Cust r ON r.sGroupCust = i.IM_CUST
                            WHERE n.NA_EXT_TYPE = 1210067
                            AND e.NE_AVAIL_ACTUAL >= '1'
                            AND l.IL_IN_LOCN NOT IN ('OBSOLETEMEL','OBSOLETESYD','PASTHISTORY', 'CANBERRA')
                            AND e.NE_STATUS =  1
                            AND e.NE_STRENGTH = 3
                            AND i.IM_CUST LIKE '%'
                            GROUP BY  ((CASE
                                              WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
                                              WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
                                              END),i.IM_CUST, (CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                                                                                              ELSE 'F- Shelves'
                                              END) )
                            HAVING (CASE
                                WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
                                WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
                                END) Like :warehousePS  OR  (CASE
                                WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
                                WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
                                END) Like '%'

                            ORDER BY 1,2,4
                            }';
           OPEN gds_src_get_desp_stocks FOR  v_query
          -- USING start_date, end_date, warehouse, start_date, end_date, warehouse, start_date, end_date, warehouse, start_date, end_date, warehouse;
           USING start_date, end_date, warehouse, start_date, end_date, warehouse, start_date, end_date, warehouse, start_date, end_date, warehouse, warehouse;
           DBMS_OUTPUT.PUT_LINE('Successfully inserted fresh temporary data for pallets and shelves using NO warehouse and customer filters - should have passed NULL values and returned all data');
 ELSE
         v_query := q'{

                            SELECT   EOM_REPORT_PKG.f_GetWarehouse_from_SD(d.SD_LOCN) AS Warehouse,
                                        sGroupCust,
                                        Count(DISTINCT(SD_ORDER)) AS Total,
                                        --Count(DISTINCT(SD_ORDER)) AS SDCount,
                                        'A- Orders' AS "Type"--, Count(SD_ORDER) AS SDCount
                            FROM SH h LEFT JOIN Tmp_Group_Cust r ON r.sCust = h.SH_CUST
                                 RIGHT JOIN SD d ON d.SD_ORDER = h.SH_ORDER
                                 INNER JOIN RM r2 ON r2.RM_CUST = h.SH_CUST
                            WHERE h.SH_ADD_DATE >= :sh_start_date AND h.SH_ADD_DATE <= :sh_end_date
                            AND h.SH_STATUS <> 3
                            AND h.SH_CAMPAIGN NOT IN( 'ADMIN','OBSOLETE')
                            --AND d.SD_DISPLAY = 1
                            --AND d.SD_STOCK NOT IN('COURIER','COURIERM','COURIERS')
                            AND r2.RM_ACTIVE = 1   --This was the problem
                            AND r.sGroupCust = :GroupCustO
                            GROUP BY ROLLUP ( (EOM_REPORT_PKG.f_GetWarehouse_from_SD(d.SD_LOCN)),sGroupCust  )
                            HAVING EOM_REPORT_PKG.f_GetWarehouse_from_SD(d.SD_LOCN) LIKE :warehouseO


                       UNION ALL


                            SELECT    EOM_REPORT_PKG.f_GetWarehouse_from_SD(s.SL_LOCN) AS Warehouse,
                                         sGroupCust,
                                        Count(*) AS Total,
                                        'B- Despatches' AS "Type"
                                       --t.ST_PICK,
                                       --h.SH_CAMPAIGN
                            FROM  PWIN175.ST t INNER JOIN SL s ON s.SL_PICK = t.ST_PICK
                                  INNER JOIN SH h ON h.SH_ORDER = t.ST_ORDER--RIGHT JOIN SD d ON d.SD_ORDER = h.SH_ORDER
                                  LEFT JOIN Tmp_Group_Cust r ON r.sCust = h.SH_CUST
                                  INNER JOIN RM r2 ON r2.RM_CUST = h.SH_CUST
                                  --RIGHT JOIN SL s ON s.SL_PICK = t.ST_PICK

                            WHERE t.ST_DESP_DATE >= :st_start_date AND t.ST_DESP_DATE <= :st_end_date
                            AND s.SL_LINE = 1
                            AND t.ST_PSLIP IS NOT NULL AND t.ST_PSLIP <> 'CANCELLED'
                            AND h.SH_STATUS <> 3
                            AND h.SH_CAMPAIGN NOT IN( 'ADMIN','OBSOLETE')
                            AND r2.RM_ACTIVE = 1   --This was the problem
                            AND r.sGroupCust = :GroupCustD
                            GROUP BY ROLLUP ((EOM_REPORT_PKG.f_GetWarehouse_from_SD(s.SL_LOCN)), sGroupCust )
                            HAVING EOM_REPORT_PKG.f_GetWarehouse_from_SD(s.SL_LOCN) LIKE :warehouseD


            UNION ALL
             SELECT    EOM_REPORT_PKG.f_GetWarehouse_from_SD(s.SL_LOCN)  AS Warehouse,
                                        sGroupCust AS Customer,
                                        Count(*) AS Total,
                                        'C- Lines' AS "Type"
                            FROM  PWIN175.SL s INNER JOIN SH h ON s.SL_ORDER = h.SH_ORDER
                                  LEFT JOIN Tmp_Group_Cust r ON r.sCust = h.SH_CUST
                                  --RIGHT JOIN SD d ON d.SD_ORDER = h.SH_ORDER
                                  INNER JOIN RM r2 ON r2.RM_CUST = h.SH_CUST
                                  --INNER JOIN IL l ON l.IL_LOCN = s.SL_LOCN
                                  INNER JOIN ST t ON t.ST_PICK = s.SL_PICK
                            WHERE s.SL_EDIT_DATE >= :sl_start_date AND s.SL_EDIT_DATE <= :sl_end_date
                            AND s.SL_PSLIP IS NOT NULL
                            AND h.SH_CAMPAIGN NOT IN( 'ADMIN','OBSOLETE')
                            AND r2.RM_ACTIVE = 1   --This was the problem
                            AND r.sGroupCust = :GroupCustL
                            GROUP BY  ROLLUP (EOM_REPORT_PKG.f_GetWarehouse_from_SD(s.SL_LOCN), sGroupCust)
                            HAVING EOM_REPORT_PKG.f_GetWarehouse_from_SD(s.SL_LOCN) LIKE :warehouseL


           UNION ALL

            SELECT (CASE
                                    WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
                                    WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
                                    END) AS Warehouse,

                                    i.IM_CUST AS Cust,
                                   Count(NE_ENTRY) AS Total,
                                   'D- Receipts'  AS "Type"
                            FROM  NA n INNER JOIN IL l ON l.IL_UID = n.NA_EXT_KEY
                                       INNER JOIN NE e ON e.NE_ACCOUNT = n.NA_ACCOUNT
                                       INNER JOIN IM i ON i.IM_STOCK = n.NA_STOCK
                            WHERE n.NA_EXT_TYPE = 1210067
                            AND   l.IL_IN_LOCN NOT IN ('OBSOLETEMEL','OBSOLETESYD','PASTHISTORY', 'CANBERRA')
                            AND   IL_PHYSICAL = 1
                            AND   e.NE_QUANTITY >= '1'
                            AND   e.NE_TRAN_TYPE =  1
                            AND   e.NE_STRENGTH = 3
                            AND   (e.NE_STATUS = 1 OR e.NE_STATUS = 3)
                            AND   e.NE_DATE >= :ne_start_date AND e.NE_DATE <= :ne_end_date
                            AND i.IM_CUST = :GroupCustR
                            GROUP BY ((CASE
                                    WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
                                    WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
                                    END)
                            ,i.IM_CUST)
                            HAVING (CASE
                            WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
                            WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
                            END) Like :warehouseR

         UNION ALL
            SELECT
                                   (CASE
                                    WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
                                    WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
                                    END) AS Warehouse,
                                   i.IM_CUST AS Cust,
                                   Count(DISTINCT l.IL_LOCN) AS Total,  -- test a self join to rid the distinct
                                   (CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                                                                                    ELSE 'F- Shelves'
                                    END) AS "Type"
                            FROM  NA n INNER JOIN IL l ON l.IL_UID = n.NA_EXT_KEY
                                       INNER JOIN NE e ON e.NE_ACCOUNT = n.NA_ACCOUNT
                                       INNER JOIN IM i ON i.IM_STOCK = n.NA_STOCK
                                       --LEFT JOIN Tmp_Group_Cust r ON r.sGroupCust = i.IM_CUST
                            WHERE n.NA_EXT_TYPE = 1210067
                            AND e.NE_AVAIL_ACTUAL >= '1'
                            AND l.IL_IN_LOCN NOT IN ('OBSOLETEMEL','OBSOLETESYD','PASTHISTORY', 'CANBERRA')
                            AND e.NE_STATUS =  1
                            AND e.NE_STRENGTH = 3
                            AND i.IM_CUST = :GroupCustPS
                            GROUP BY  ((CASE
                                              WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
                                              WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
                                              END),i.IM_CUST, (CASE WHEN Upper(substr(l.IL_NOTE_2,0,1)) = 'Y' THEN 'E- Pallets'
                                                                                              ELSE 'F- Shelves'
                                              END) )
                            HAVING (CASE
                                WHEN l.IL_IN_LOCN IS NOT NULL THEN l.IL_IN_LOCN
                                WHEN l.IL_IN_LOCN IS NULL THEN l.IL_LOCN
                                END) Like :warehousePS

                            ORDER BY 1,2,4
                            }';
           OPEN gds_src_get_desp_stocks FOR  v_query
           USING start_date, end_date, cust, warehouse, start_date, end_date, cust, warehouse, start_date, end_date, cust, warehouse,start_date, end_date, cust, warehouse, cust, warehouse;
           DBMS_OUTPUT.PUT_LINE('Successfully inserted fresh temporary data for pallets and shelves using warehouse and customer filters');
   END IF;
    --    EXECUTE IMMEDIATE v_query;
        --DBMS_OUTPUT.PUT_LINE('Successfully inserted fresh temporary data for pallets and shelves');

    --COMMIT;
    --RETURN;

  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;
  END EOM_CREATE_TEMP_LOG_DATA;


END EOM_REPORT_PKG;