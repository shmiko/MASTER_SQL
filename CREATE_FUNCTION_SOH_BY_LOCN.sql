

create or replace  FUNCTION total_soh_by_locn
    ( d_rm_cust_in IN rm.rm_cust%TYPE,
    l_locn_in IN IL.IL_LOCN%TYPE,
    l_type_in IN IL.IL_NOTE_2%TYPE:=NULL,
    l_within_locn IN IL.IL_IN_LOCN%TYPE)
  RETURN NUMBER
  IS
    --Internal  UPPER status code
    status_int2 sh.sh_status%TYPE:=Upper(l_type_in);
    DBMS_OUTPUT.PUT_LINE('1 Successfully ran total_soh_by_locn ' || l_locn_in || ' type was ' || l_type_in );
    --Parameterised cursor returns total orders
    CURSOR soh_cur (status_in IN IL_IL_NOTE_2%TYPE)   IS
      SELECT SUM(NI_AVAIL_ACTUAL)
       FROM NI INNER JOIN IL ON IL_LOCN = NI_LOCN
      WHERE NI_LOCN = l_locn_in
      AND NI_AVAIL_ACTUAL = 0
      AND (NI_STATUS = 1 OR NI_STATUS = 2)
      AND IL_NOTE_2 LIKE l_type_in
      AND IL_IN_LOCN = l_within_locn
      GROUP BY NI_LOCN,NI_AVAIL_ACTUAL;

      --Return value for function
      v_rtn_value NUMBER;
  BEGIN
    OPEN soh_cur (status_int2);
    FETCH soh_cur INTO v_rtn_value;
    IF soh_cur%NOTFOUND
    THEN
      CLOSE soh_cur;
      RETURN NULL;
    ELSE
      CLOSE soh_cur;
      RETURN v_rtn_value;
      DBMS_OUTPUT.PUT_LINE('total_soh_by_locn Count is ' + v_rtn_value + ' for locn ' + l_locn_in + '.');
    END IF;
  END total_soh_by_locn;

