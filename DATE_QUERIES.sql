 select 1 + TRUNC (CURRENT_DATE)
  - TRUNC (CURRENT_DATE, 'IW') From DUAl;
  
  Select  LAST_DAY( CURRENT_DATE ) From DUAl;
  
  Select NEXT_DAY( CURRENT_DATE, 'SUNDAY' ) - 7 From DUAl;
  
  select case to_char (sysdate, 'FmDay', 'nls_date_language=english')
          when 'Monday' then 1
          when 'Tuesday' then 2
          when 'Wednesday' then 3
          when 'Thursday' then 4
          when 'Friday' then 5
          when 'Saturday' then 6
          when 'sunday' then 7
       end d
  from dual;
  
  
  
  create or replace FUNCTION F_GET_DAY_LAST_OF_MONTH(
        startdate IN VARCHAR2
        )
  RETURN DATE
  RESULT_CACHE 
  RELIES_ON (S)
  AS

  Last_of_the_month NUMBER; -- 0 is true and 1 if false
  nbreakpoint   NUMBER;
  BEGIN
    nbreakpoint := 1;
        Select  LAST_DAY( startdate )
        INTO  Last_of_the_month	     
        From DUAL;
         DBMS_OUTPUT.PUT_LINE('F_IS_DAY_LAST_OF_MONTH succeded at checkpoint ' || nbreakpoint ||
                          ' with result ' || Last_of_the_month || '.');
        RETURN Last_of_the_month;
        
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('F_IS_DAY_LAST_OF_MONTH failed at checkpoint ' || nbreakpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);
      RAISE;  
  END F_GET_DAY_LAST_OF_MONTH;