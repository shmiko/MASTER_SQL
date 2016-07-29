--Admin Order Data
/*Set Stored Procedure*/

CREATE OR REPLACE PROCEDURE GROUP_CUST_START AS
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

  --nCheckpoint := 4;
  --EXECUTE IMMEDIATE 'SELECT * FROM Tmp_Group_Cust';
  --Gets executed from GROUP_CUST



  DBMS_OUTPUT.PUT_LINE('Successfully truncated, recreated AND populated Tmp_Group_Cust');


  RETURN;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('GROUP_CUST_START failed at checkpoint ' || nCheckpoint ||
                         ' with error ' || SQLCODE || ' : ' || SQLERRM);
    RAISE;
END GROUP_CUST_START;



/*SELECT * FROM Tmp_Admin_Data
ORDER BY vOrder,vPickslip Asc    */





EXECUTE GROUP_CUST_START;