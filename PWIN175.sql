CREATE OR REPLACE PROCEDURE EOM_TMP_CTN_FEES_IC (
      p_array_size IN PLS_INTEGER DEFAULT 1000
      ,start_date IN ST.ST_DESP_DATE%TYPE
      ,end_date IN ST.ST_DESP_DATE%TYPE,
      sCust IN RM.RM_CUST%TYPE,
      sAnalysis IN RM.RM_ANAL%TYPE
      -- sCust IN RM.RM_CUST%TYPE
    )
    IS
    TYPE ARRAY IS TABLE OF TMP_CTN_FEES%ROWTYPE;
    l_data ARRAY;
    v_out_tx          VARCHAR2(2000);
    SQLQuery   VARCHAR2(6000);
    v_query           VARCHAR2(2000);
    v_query2          VARCHAR2(32767);
		nCheckpoint       NUMBER;
		sCourierm         VARCHAR2(20) := 'COURIERM';
    sCouriers         VARCHAR2(20) := 'COURIERS';
    sCourier         VARCHAR2(20) := 'COURIER%';
    sServ8             VARCHAR2(20) := 'SERV8';
    sServ3             VARCHAR2(20) := 'SERV%';
    --sCust2    VARCHAR2(20) := sCust;
    end_date2 ST.ST_DESP_DATE%TYPE := end_date;
    --DBMS_OUTPUT.PUT_LINE(start_date || ' - ' || end_date || '.' || sCust );
    l_start number default dbms_utility.get_time;  


    CURSOR c 
    --(
      --start_date IN ST.ST_DESP_DATE%TYPE
    -- ,end_date IN ST.ST_DESP_DATE%TYPE
    --sCust IN RM.RM_CUST%TYPE
     --)
     IS 
   

/*Carton Despatch Fee*/
	SELECT    s.SH_CUST                AS "Customer",
			  r.sGroupCust              AS "Parent",
			   CASE    WHEN IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
			  WHEN IM_CUST = 'TABCORP' THEN IM_XX_COST_CENTRE01
			  ELSE s.SH_SPARE_STR_4
			  END                      AS "CostCentre",
			  s.SH_ORDER               AS "Order",
			  s.SH_SPARE_STR_5         AS "OrderwareNum",
			  s.SH_CUST_REF            AS "CustomerRef",
			  t.ST_PICK                AS "Pickslip",
			  d.SD_XX_PICKLIST_NUM     AS "PickNum",
			  t.ST_PSLIP               AS "DespatchNote",
			  substr(To_Char(t.ST_DESP_DATE),0,10)           AS "DespatchDate",
	  CASE    WHEN t.ST_XX_NUM_CARTONS >= 1 THEN 'Carton Despatch Fee is '
			  ELSE ''
			  END                      AS "FeeType",
	  CASE    WHEN t.ST_XX_NUM_CARTONS >= 1 THEN  d.SD_STOCK
			  ELSE NULL
			  END                     AS "Item",
	  CASE    WHEN t.ST_XX_NUM_CARTONS >= 1 THEN  d.SD_DESC
			  ELSE NULL
			  END                     AS "Description",
	  CASE    WHEN t.ST_XX_NUM_CARTONS >= 1 THEN  t.ST_XX_NUM_CARTONS
			  ELSE NULL
			  END                     AS "Qty",
	  CASE    WHEN t.ST_XX_NUM_CARTONS >= 1 THEN  '1'
			  ELSE ''
			  END                     AS "UOI",
	  CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN  (SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) --To_Number(f_get_fee('RM_XX_FEE15',sCust))-- f_get_fee('RM_XX_FEE15',sCust)
			 ELSE null
			 END                      AS "UnitPrice",
	  CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) --f_get_fee('RM_XX_FEE15',sCust) --To_Number(f_get_fee('RM_XX_FEE15',sCust))  
    ELSE null
			 END                                           AS "OWUnitPrice",
	 CASE   WHEN t.ST_XX_NUM_CARTONS >= 1  THEN (SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) --f_get_fee('RM_XX_FEE15',sCust) --To_Number(f_get_fee('RM_XX_FEE15',sCust))  
   ELSE NULL
			 END                        AS "DExcl",
			  CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) --f_get_fee('RM_XX_FEE15',sCust) --To_Number(f_get_fee('RM_XX_FEE15',sCust))  
        ELSE NULL
			 END                                            AS "Excl_Total",
	  CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) --f_get_fee('RM_XX_FEE15',sCust) --To_Number(f_get_fee('RM_XX_FEE15',sCust))  
    ELSE NULL
			 END                                           AS "DIncl",
	  CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) --f_get_fee('RM_XX_FEE15',sCust) --f_get_fee('RM_XX_FEE15',sCust) --To_Number(f_get_fee('RM_XX_FEE15',sCust)) * 1.1  
    ELSE NULL
			 END                                           AS "Incl_Total",
			  CASE   WHEN t.ST_XX_NUM_CARTONS >= 1 THEN (SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) --f_get_fee('RM_XX_FEE15',sCust) --To_Number(f_get_fee('RM_XX_FEE15',sCust))  
        ELSE null
			 END                                           AS "ReportingPrice",
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
			  NULL AS "Pallet/Shelf Space",
				NULL AS "Locn",
				--0 AS "AvailSOH",
				0 AS "CountOfStocks",
        CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			        ELSE ''
			        END AS Email,
              i.IM_BRAND AS Brand,
           i.IM_OWNED_By AS    OwnedBy,
           i.IM_PROFILE AS    sProfile,
           s.SH_XX_FEE_WAIVE AS    WaiveFee,
           d.SD_COST_PRICE As   Cost,
           s.SH_SPARE_INT_4 AS PaymentType
	FROM      PWIN175.SD d
			  INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			  INNER JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER
			  LEFT JOIN Tmp_Group_Cust r ON r.sCust = s.SH_CUST
			  INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
	WHERE  --f_get_fee('RM_XX_FEE15',sCust) > 0
  --To_Number(f_get_fee('RM_XX_FEE15',sCust)) > 0
 (SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) FROM RM where RM_CUST = sCust) > 0
	AND       s.SH_STATUS <> 3
	AND       (r.sGroupCust = sCust OR r.sCust = sCust)
	AND       s.SH_ORDER = t.ST_ORDER
	AND       (ST_XX_NUM_CARTONS >= 1)
	AND       d.SD_LINE = 1

	AND   t.ST_DESP_DATE >= start_date AND t.ST_DESP_DATE <= end_date;
  
  BEGIN
    
    nCheckpoint := 1;
      v_query := 'TRUNCATE TABLE TMP_CTN_FEES';
      EXECUTE IMMEDIATE v_query;
    
    nCheckpoint := 2;
        OPEN c;
        --DBMS_OUTPUT.PUT_LINE(sCust || '.' );
        LOOP
        FETCH c BULK COLLECT INTO l_data LIMIT p_array_size;
        
        FORALL i IN 1..l_data.COUNT
        --DBMS_OUTPUT.PUT_LINE(i || '.' );
        INSERT INTO TMP_CTN_FEES VALUES l_data(i); 
        --USING sCust;
        
        EXIT WHEN c%NOTFOUND;

        END LOOP;
       -- DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
        CLOSE c;
       FOR i IN l_data.FIRST .. l_data.LAST LOOP
        DBMS_OUTPUT.PUT_LINE(l_data(i).Customer || ' - ' || l_data(i).Parent || '.' );
      END LOOP;

  COMMIT;
  --RETURN;
  DBMS_OUTPUT.PUT_LINE('EOM Carton Fees for all customer for the date range ' 
      || start_date || ' -- ' || end_date);
    --COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM Carton Fees Failed');
      RAISE;

  END EOM_TMP_CTN_FEES_IC;