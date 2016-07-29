  PROCEDURE get_employee_info_by_employee_id
  (
  p_employee_id   NUMBER DEFAULT -1
  )
  AS
    -- You need to query the values you're showing into variables. The
    -- variables can have the same name as the column names. Oracle won't
    -- be confused by this, but I usually am - that's why I have the "v_"
    -- prefix for the variable names here. Finally, when declaring the
    -- variable's type, you can reference table.column%TYPE to use the
    -- type of an existing column.
    v_name Employee.Name%TYPE;
    v_email_address Employee.Email_Address%TYPE;
    v_hire_date Employee.Hire_Date%TYPE;
    v_update_date Employee.Update_Date%TYPE;
  BEGIN
    -- Just SELECT away, returning column values into the variables. If
    -- the employee ID isn't found, Oracle will throw and you can pick
    -- up the pieces in the EXCEPTION block below.
    SELECT Name, Email_Address, Hire_Date, Update_Date
      INTO v_name, v_email_address, v_hire_date, v_update_date
      FROM Employee
      WHERE Employee_ID = p_employee_id;
    -- Fallthrough to here means the query above found one (and only one)
    -- row, and therefore it put values into the variables. Print out the
    -- variables.
    --
    -- Also note there wasn't a v_employee_id variable defined, because
    -- you can use your parameter value (p_employee_id) for that.
    DBMS_OUTPUT.PUT_LINE('Employee ID: ' || p_employee_id);
    DBMS_OUTPUT.PUT_LINE('NAME: ' || v_name);
    DBMS_OUTPUT.PUT_LINE('EMAIL_ADDRESS: ' || v_email_address);
    DBMS_OUTPUT.PUT_LINE('HIRE_DATE: ' || v_hire_date);
    DBMS_OUTPUT.PUT_LINE('UPDATE_DATE: ' || v_update_date);
  EXCEPTION
    -- If the query didn't find a row you'll end up here. In this case
    -- there's no need for any type of fancy exception handling; just
    -- reporting that the employee wasn't found is enough.
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Employee number ' || p_employee_id || ' not found.');
  END;




CREATE OR REPLACE PROCEDURE GROUP_CUST_GET
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

EXECUTE GROUP_CUST_GET('RTA')


CREATE OR REPLACE PROCEDURE GROUP_CUST_LIST
    (tgc_customer_in IN rm.rm_cust%TYPE)
    AS
      nCheckpoint  NUMBER;
    CURSOR tgc_cur IS
      SELECT tgc.sCust, tgc.sGroupCust
      FROM Tmp_Group_Cust tgc
      WHERE tgc.sCust = tgc_customer_in;

    tgc_rec tgc_cur%ROWTYPE;
  BEGIN

    nCheckpoint := 1;
    OPEN tgc_cur;
    FETCH tgc_cur INTO tgc_rec;
    WHILE(tgc_cur%FOUND)
    LOOP
      DBMS_OUTPUT.PUT_LINE(tgc_rec.sCust || ' ' || tgc_rec.sGroupCust);
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

EXECUTE GROUP_CUST_LIST('RTA')








SELECT report_pkg.cust As Customer ,
  CASE
    WHEN total_orders(report_pkg.cust,report_pkg.status,report_pkg.start_date) > report_pkg.order_limit  THEN total_orders(report_pkg.cust,report_pkg.status,report_pkg.start_date)
    ELSE NULL
    END AS "Todays Orders"
FROM RM
WHERE RM_PARENT = report_pkg.cust
GROUP BY report_pkg.cust