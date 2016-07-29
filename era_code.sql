create or replace FUNCTION F_LAST_YEAR_ERA_DATE RETURN VARCHAR AS 
  n_era_num NUMBER := 4;
  squery VARCHAR2(100);
  squery2 VARCHAR2(100);
  squery3 VARCHAR2(100);
  s_era_result VARCHAR2(15);
  s_last_year_date VARCHAR2(15);
  s_trimmed_era VARCHAR2(50);
  s_trimmed_era_final VARCHAR2(50);
  n_era_inc NUMBER;
BEGIN
  squery := 'SELECT IC_PERIOD_DATE_' || n_era_num || ' FROM IC';
  --DBMS_OUTPUT.put_line('1st query is ' || squery);
  EXECUTE IMMEDIATE squery INTO s_era_result;
  --squery2 := 'Select SUBSTR(s_era_result,length(s_era_result -2),2) From Dual';
 -- EXECUTE IMMEDIATE squery2 INTO s_last_year_date;
  --DBMS_OUTPUT.put_line(' era result is ' || s_era_result || ' and the query is ' || squery);
  --BEGIN  
    squery2 := 'Select SUBSTR('''|| s_era_result  ||''',length(''' || s_era_result || ''') -1) From Dual';
    --DBMS_OUTPUT.put_line('2nd query2 is ' || squery2 || ' and s_era_result from 1st query is ' || s_era_result );
    EXECUTE IMMEDIATE squery2 INTO s_last_year_date;  
    --DBMS_OUTPUT.put_line(' s_last_year_date is ' || s_last_year_date || ' and the query is ' || squery2 || ' so we need to minus 1 from the year to get 12 months YTD');
    squery3 := 'Select SUBSTR('''|| s_era_result  ||''',1,length(''' || s_era_result || ''') -2) From Dual';
    EXECUTE IMMEDIATE squery3 INTO s_trimmed_era;
    n_era_inc := TO_NUMBER(s_last_year_date) -1;
    s_trimmed_era_final := s_trimmed_era || TO_CHAR(n_era_inc);
    --DBMS_OUTPUT.put_line(' s_trimmed_era is ' || s_trimmed_era || ' add to the year ' || s_last_year_date || ' so we need to minus 1 from the year to get 12 months YTD');
    --DBMS_OUTPUT.put_line(' final result being last years from date is ' || s_trimmed_era_final || '.');
    RETURN s_trimmed_era_final;
  --END;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.put_line('ERR era result is ' || s_era_result || ' and the ist query is ' || squery || ' 2nd query is '|| squery2 || ' and result is ' || s_last_year_date);
  RAISE;
END F_LAST_YEAR_ERA_DATE;