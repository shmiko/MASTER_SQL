CREATE OR REPLACE PROCEDURE GROUP_CUST AS
  nCheckpoint  NUMBER;
  CURSOR tgc_cur IS
    SELECT tgc.sCust, tgc.sGroupCust
    FROM Tmp_Group_Cust tgc;
    --WHERE tgc.sCust;

  tgc_rec tgc_cur%ROWTYPE;
BEGIN

  nCheckpoint := 1;
  OPEN tgc_cur;
  FETCH tgc_cur INTO tgc_rec;
  WHILE(tgc_cur%FOUND)
  LOOP
    DBMS_OUTPUT.PUT_LINE(tgc_rec.sCust || ' - ' || tgc_rec.sGroupCust);
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
END GROUP_CUST;

