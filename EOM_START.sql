--Admin Order Data
/*Set Stored Procedure*/
var cust varchar2(20)
exec :cust := 'LUXOTTICA'
CREATE TABLE Tmp_Admin_Data_Cust (vCust VARCHAR(200))

DECLARE
  v_num1 NUMBER := 5;
  v_num2 NUMBER := 3;
  v_temp NUMBER;


BEGIN

   IF v_num1 > v_num2 THEN
      INSERT INTO Tmp_Admin_Data_Cust(SELECT RM_CUST FROM RM WHERE RM_CUST = 'LUXOTTICA');
   END IF;



END; EOM_TEST;


SELECT * FROM Tmp_Admin_Data_Cust

