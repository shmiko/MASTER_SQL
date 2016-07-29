SET serveroutput ON
DECLARE 
  nCheckpoint NUMBER;
  sResult VARCHAR(255);
  sCust VARCHAR(20) := 'VHAAUS';
--  start_date VARCHAR(20) := '01-Jun-2015'; -- use this format when using ST_DESP_DATE unformatted
--  end_date VARCHAR(20) := '30-Jun-2015';
--   start_date VARCHAR(20) := '2015-06-01'; -- use this when ST_DESP_DATE is formatted
--  end_date VARCHAR(20) := '2015-06-30';
  start_date VARCHAR(20) := F_FIRST_DAY_PREV_MONTH; -- use this when you want the date entered automatically
  end_date VARCHAR(20) := F_LAST_DAY_PREV_MONTH;
BEGIN    
  nCheckpoint := 1;
  SELECT To_Number(regexp_substr(RM_XX_FEE32_1,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO sResult FROM RM where RM_CUST = sCust;
 
  DBMS_OUTPUT.put_line ('Shrinkwrap charges, run from '  || start_date || ' to ' || end_date || ' : ' || sResult || ' run for customer ' || sCust);
 EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EOM order fees processing failed at checkpoint ' || nCheckpoint ||
                          ' with error ' || SQLCODE || ' : ' || SQLERRM);

      RAISE;
End;
/
Select * From Tmp_Admin_Data_Pickslips;
SELECT * FROM Tmp_Admin_Data_Pick_LineCounts;
SELECT * FROM Tmp_Locn_Cnt_By_Cust;
SELECT * FROM TMP_FREIGHT;
SELECT Count(*) FROM TMP_FREIGHT;
Select * from TMP_ORD_FEES;
Select Count(*) From TMP_ORD_FEES;
SELECT * FROM Tmp_Group_Cust;
Truncate table Tmp_Group_Cust;
SELECT Count(*) FROM Tmp_Group_Cust;
