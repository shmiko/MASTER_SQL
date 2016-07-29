create or replace PROCEDURE CUSTDATA AS
  CURSOR rm_cur IS
    SELECT r.rm_cust, r.rm_name
    FROM rm r
    WHERE r.rm_cust LIKE 'RTA%'
    ORDER BY r.rm_cust;
  rm_rec rm_cur%ROWTYPE;
BEGIN
  OPEN rm_cur;
  FETCH rm_cur INTO rm_rec;
  WHILE(rm_cur%FOUND)
  LOOP
    DBMS_OUTPUT.PUT_LINE(rm_rec.rm_cust || ' ' || rm_rec.rm_name);
    FETCH rm_cur INTO rm_rec;
  END LOOP;
  CLOSE rm_cur;
END CUSTDATA;

-- Calling the function from a MAIN BODY
--BEGIN
--  CUSTDATA();
--END;

