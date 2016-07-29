create or replace FUNCTION F_IS_TABLE_EEMPTY
                  ( v_table_in IN VARCHAR2)
  RETURN VARCHAR2
  AS
  TYPE tst_tmp_Admin_Data_Pickslips is table of  Tmp_Admin_Data_Pickslips%rowtype INDEX BY BINARY_INTEGER;
  test_tbl tst_tmp_Admin_Data_Pickslips;
  v_rtn_value VARCHAR2;
  BEGIN
    DBMS_OUTPUT.PUT_LINE('The count of the temp table is  ' || test_tbl.count);
        SELECT COUNT(*)
        INTO v_rtn_value
        FROM  tmp_Admin_Data_Pickslips;
        RETURN v_rtn_value;
        DBMS_OUTPUT.PUT_LINE('3 The count of the temp table is ' || v_rtn_value);
  END F_IS_TABLE_EEMPTY;