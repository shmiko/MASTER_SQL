/* First run this file with variables set in header - declare variables - drop tables, recreate tables, insert into tables - then query tables */
/* EOM_INVOICING_CREATE_TABLES.sql */
--Admin Order Data by Parent or Customer
var cust varchar2(20)
exec :cust := 'CPAAUST'
var ordernum varchar2(20)
exec :ordernum := '1363806'
var stock varchar2(20)
exec :stock := 'COURIER'
var source varchar2(20)
exec :source := 'BSPRINTNSW'
var sAnalysis varchar2(20) /*VerbalOrderEntryFee*/
exec SELECT  RM_ANAL INTO :sAnalysis FROM RM where RM_CUST = :cust;
var anal varchar2(20)
exec :anal := '75'
var start_date varchar2(20)
exec :start_date := To_Date('1-Jul-2013')
var end_date varchar2(20)
exec :end_date := To_Date('31-Jul-2013')


  var nCountCustStocks NUMBER /*VerbalOrderEntryFee*/
  exec SELECT  Count(IM_STOCK) INTO :nCountCustStocks FROM IM where IM_CUST = :cust AND IM_ACTIVE = 1;



  var nRM_XX_FEE01 NUMBER /*VerbalOrderEntryFee*/
  exec SELECT  To_Number(regexp_substr(RM_XX_FEE01,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE01 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE02 NUMBER /*EmailOrderEntryFee*/
  exec SELECT  To_Number(regexp_substr(RM_XX_FEE02,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE02 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE03 NUMBER /*PhoneOrderEntryFee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE03,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE03 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE04 NUMBER /*PhoneOrderEntryFee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE04,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE04 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE05 NUMBER /*PhoneOrderEntryFee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE05,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE05 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE06 NUMBER /*Handeling Fee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE06,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE06 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE07 NUMBER /*FaxOrderEntryFee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE07,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE07 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE08 NUMBER /*InnerPackingFee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE08,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE08 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE09 NUMBER /*OuterPackingFee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE09,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE09 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE10 NUMBER /*FTPOrderEntryFee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE10,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE10 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE11 NUMBER /*Pallet Storage Fee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE11,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE11 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE12 NUMBER /*Shelf Storage Fee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE12,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE12 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE13 NUMBER /*Carton In Fee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE13,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE13 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE14 NUMBER /*Pallet In Fee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE14,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE14 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE15 NUMBER /*Carton Despatch Fee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE15,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE15 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE16 NUMBER /*Pick Fee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE16,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE16 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE17 NUMBER /*Pallet Despatch Fee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE17,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE17 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE18 NUMBER /*ShrinkWrap Fee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE18,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE18 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE19 NUMBER /*Admin Fee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE19,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE19 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE20 NUMBER /*Stock Maintenance Fee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE20,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE20 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE21 NUMBER /*DB Maintenance Fee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE21,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE21 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE22 NUMBER /*Bin Monthly Storage Fee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE22,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE22 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE23 NUMBER /*Daily Delivery Fee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE23,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE23 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE24 NUMBER /*Carton Destruction Fee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE24,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE24 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE25 NUMBER /*Pallet Destruction Fee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE25,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE25 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE26 NUMBER /*Additional Pallet Destruction Fee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE26,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE26 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE27 NUMBER /*Order Fee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE27,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE27 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE28 NUMBER /*Pallet Secured Storage Fee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE28,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE28 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE29 NUMBER /*Pallet Slow Moving Secured Fee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE29,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE29 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE30 NUMBER /*Shelf Slow Moving Fee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE30,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE30 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE31 NUMBER /*Secured Shelf Storage Fee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE31,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE31 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE32 NUMBER /*Pallet Archive Monthly Fee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE32,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE32 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE33 NUMBER /*Shelf Archive Monthly Fee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE33,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE33 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE34 NUMBER /*Manual Report Run Fee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE34,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE34 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE35 NUMBER /*Kitting Fee P/H*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE35,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE35 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE36 NUMBER /*Pick Fee 2nd Scale*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE36,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE36 FROM RM where RM_CUST = :cust;

  var nRM_SPARE_CHAR_3 NUMBER /*Pallet Slow Moving Fee*/
  exec SELECT To_Number(regexp_substr(RM_SPARE_CHAR_3,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_SPARE_CHAR_3 FROM RM where RM_CUST = :cust;

  var nRM_SPARE_CHAR_5 NUMBER /*System Maintenance Fee*/
  exec SELECT To_Number(regexp_substr(RM_SPARE_CHAR_5,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_SPARE_CHAR_5 FROM RM where RM_CUST = :cust;

  var nRM_SPARE_CHAR_4 NUMBER /*Stocktake Fee P/H*/
  exec SELECT To_Number(regexp_substr(RM_SPARE_CHAR_4,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_SPARE_CHAR_4 FROM RM where RM_CUST = :cust;

  var nRM_XX_ADMIN_CHG NUMBER /*Shelf Slow Moving Secured Fee*/
  exec SELECT To_Number(regexp_substr(RM_XX_ADMIN_CHG,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_ADMIN_CHG FROM RM where RM_CUST = :cust;

  var nRM_XX_PALLET_CHG NUMBER /*Return Per Pallet Fee*/
  exec SELECT To_Number(regexp_substr(RM_XX_PALLET_CHG,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_PALLET_CHG FROM RM where RM_CUST = :cust;

  var nRM_XX_SHELF_CHG NUMBER /*Return Per Shelf Fee*/
  exec SELECT To_Number(regexp_substr(RM_XX_SHELF_CHG,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_SHELF_CHG FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE31_1 NUMBER /*UnallocatedFee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE31_1,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE31_1 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE32_1 NUMBER /*UnallocatedFee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE32_1,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE32_1 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE33_1 NUMBER /*UnallocatedFee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE33_1,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE33_1 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE34_1 NUMBER /*UnallocatedFee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE34_1,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE34_1 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE35_1 NUMBER /*UnallocatedFee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE35_1,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE35_1 FROM RM where RM_CUST = :cust;

  var nRM_XX_FEE36_1 NUMBER /*UnallocatedFee*/
  exec SELECT To_Number(regexp_substr(RM_XX_FEE36_1,'^[-]?[[:digit:]]*\.?[[:digit:]]*$')) INTO :nRM_XX_FEE36_1 FROM RM where RM_CUST = :cust;
/*decalre variables*/





  var nCountCustStocks NUMBER /*VerbalOrderEntryFee*/
  exec SELECT  Count(IM_STOCK) INTO :nCountCustStocks FROM IM where IM_CUST = :cust AND IM_ACTIVE = 1;

Code for Creating Job is Here
/********************************************* ***************************
***************************************/
BEGIN
sys.dbms_scheduler.create_job(
job_name => ' " "." " ',
job_type => 'STORED_PROCEDURE',
job_action => ' ',
repeat_interval =>
'FREQ=WEEKLY;BYDAY=SAT,SUN;BYHOUR=2;BYMINUTE=0 ;BYSECOND=0',
start_date => to_timestamp_tz('2007-01-25 +5:00', 'YYYY-MM-DD
TZH:TZM'),
job_class => 'DEFAULT_JOB_CLASS',
comments => ' ',
auto_drop => FALSE,
enabled => TRUE);
END;

DROP PROCEDURE Create_Tmp_Admin_Data2

CREATE OR REPLACE PROCEDURE Create_tbl_AdminData (
          NewCustomer IN VARCHAR,NewParent IN VARCHAR,NewCostCentre IN VARCHAR,NewOrderNum IN VARCHAR,NewOrderwareNum IN VARCHAR,NewCustRef IN VARCHAR,NewPickslip IN VARCHAR,NewPickNum IN VARCHAR,
			 NewDespatchNote IN VARCHAR,NewDespatchDate IN VARCHAR,NewFeeType IN VARCHAR,NewItem IN VARCHAR,NewDescription IN VARCHAR,NewQty IN NUMBER,NewUOI IN VARCHAR,NewUnitPrice IN NUMBER,NewOW_Unit_Sell_Price IN NUMBER,NewSell_Excl IN NUMBER,
			 NewSell_Excl_Total IN NUMBER,NewSell_Incl IN NUMBER,NewSell_Incl_Total IN NUMBER,NewReportingPrice IN NUMBER,NewAddress IN VARCHAR,NewAddress2 IN VARCHAR,NewSuburb IN VARCHAR,NewState IN VARCHAR,NewPostcode IN VARCHAR,
			 NewDeliverTo IN VARCHAR,NewAttentionTo IN VARCHAR,NewWeight IN NUMBER,NewPackages IN NUMBER,NewOrderSource IN INTEGER,NewILNOTE2 IN VARCHAR,NewNILOCN IN VARCHAR,NewNIAVAILACTUAL IN NUMBER,NewCountOfStocks IN NUMBER, NewEmail IN VARCHAR)
 AUTHID CURRENT_USER AS

 nCountCustStocks NUMBER;

BEGIN
  nCountCustStocks := 0;

  -- See if some quantity exists at the current location
  -- If not, then raise EXCEPTION and insert a new record
  -- If so, then continue on to the UPDATE statement
  SELECT Count(*)
  INTO   nCountCustStocks
  FROM   tbl_AdminData;

  -- If we get this far, then there must already exist
  -- an inventory record with this locationid and productid
  -- So update the inventory by adding the new quantity.
  IF (nCountCustStocks > 0) THEN
    --Empty table contents
    --TRUNCATE TABLE Tmp_Admin_Data2;
    EXECUTE IMMEDIATE 'DROP TABLE tbl_AdminData';

    --Now recreate Table
 EXECUTE IMMEDIATE '   CREATE TABLE tbl_AdminData
	                  (       Customer VARCHAR(255),Parent VARCHAR(255),CostCentre VARCHAR(255),OrderNum VARCHAR(255),OrderwareNum VARCHAR(255),CustRef VARCHAR(255),Pickslip VARCHAR(255),PickNum VARCHAR(255),
			                      DespatchNote VARCHAR(255),DespatchDate VARCHAR(255),FeeType VARCHAR(255),Item VARCHAR(255),Description VARCHAR(255),Qty NUMBER,UOI VARCHAR(255),UnitPrice NUMBER,OW_Unit_Sell_Price NUMBER,Sell_Excl NUMBER,
			                      Sell_Excl_Total NUMBER,Sell_Incl NUMBER,Sell_Incl_Total NUMBER,ReportingPrice NUMBER,Address VARCHAR(255),Address2 VARCHAR(255),Suburb VARCHAR(255),State VARCHAR(255),Postcode VARCHAR(255),
			                      DeliverTo VARCHAR(255),AttentionTo VARCHAR(255),Weight NUMBER,Packages NUMBER,OrderSource INTEGER,ILNOTE2 VARCHAR(255),NILOCN VARCHAR(255),NIAVAILACTUAL NUMBER,CountOfStocks NUMBER, Email VARCHAR2(255)
                    )';

    --Now ready to re run query


  END IF;

  -- If the first SELECT statement above fails to return any
  -- records at all, then the NO_DATA_FOUND exception will be
  -- signalled. The following code reacts to this exception
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    BEGIN
      --Now ready to re run query - this result should be NULL
      --EXECUTE IMMEDIATE 'SELECT * FROM Tmp_Admin_Data2 ORDER BY OrderNum,Pickslip ASC;'
      INSERT into tbl_AdminData
        /*(
				Customer,
				Parent,
				CostCentre,
				OrderNum,
				OrderwareNum,
				CustRef,
				Pickslip,
				PickNum,
				DespatchNote,
				DespatchDate,
				FeeType,
				Item,
				Description,
				Qty,
				UOI,
				UnitPrice,
				OW_Unit_Sell_Price,
				Sell_Excl,
				Sell_Excl_Total,
				Sell_Incl,
				Sell_Incl_Total,
				ReportingPrice,
				Address,
				Address2,
				Suburb,
				State,
				Postcode,
				DeliverTo,
				AttentionTo,
				Weight,
				Packages,
				OrderSource,
				ILNOTE2,
				NILOCN,
				NIAVAILACTUAL,
				CountOfStocks,
        Email
				)  */

      VALUES ('AUSELE','n/a','n/a','1379163','W1047385','N/A','2624485','n/a','1660943','06-AUG-13','Handeling Fee is ','Handeling','Handeling Fee','1','1','5','5','5','5','5','5.5','5.5','Level 3','565 Bourke Street','Melbourne','Vic','3000','Lumo Energy','Melissa Meaghan','2','14','5','n/a','n/a','0','0','Melissa.Meagher@lumoenergy.com.au')




      (NewCustomer,NewParent,NewCostCentre,NewOrderNum,NewOrderwareNum,NewCustRef,NewPickslip,NewPickNum,
			    NewDespatchNote,NewDespatchDate,NewFeeType,NewItem,NewDescription,NewQty,NewUOI,NewUnitPrice,NewOW_Unit_Sell_Price,NewSell_Excl,
			    NewSell_Excl_Total,NewSell_Incl,NewSell_Incl_Total,NewReportingPrice,NewAddress,NewAddress2,NewSuburb,NewState,NewPostcode,
			    NewDeliverTo,NewAttentionTo,NewWeight,NewPackages,NewOrderSource,NewILNOTE2,NewNILOCN,NewNIAVAILACTUAL,NewCountOfStocks, NewEmail);
    END;
END Create_tbl_AdminData;

EXECUTE Create_tbl_AdminData('AUSELE','n/a','n/a','1379163','W1047385','N/A','2624485','n/a','1660943','06-AUG-13','Handeling Fee is ','Handeling','Handeling Fee','1','1','5','5','5','5','5','5.5','5.5','Level 3','565 Bourke Street','Melbourne','Vic','3000','Lumo Energy','Melissa Meaghan','2','14','5','n/a','n/a','0','0','Melissa.Meagher@lumoenergy.com.au')


  DECLARE
  myCUST  varchar2(20):='APIA';
  CURSOR IM_cur IS
    SELECT IM.IM_STOCK, IM.IM_CUST
    FROM IM
    WHERE IM_CUST = myCUST AND IM_ACTIVE = 1
    ORDER BY IM.IM_STOCK;
  IM_rec IM_cur%ROWTYPE;

  CountOfStocks NUMBER;
   l_start  NUMBER;
BEGIN
   l_start := DBMS_UTILITY.get_time;
  OPEN IM_cur;
  FETCH IM_cur INTO IM_rec;
  WHILE(IM_cur%FOUND)
  LOOP
    CountOfStocks:=0;
    SELECT count(DISTINCT NView.NI_STOCK) INTO CountOfStocks
    FROM IL Locations
      INNER JOIN NI NView ON Locations.IL_LOCN = NView.NI_LOCN
     WHERE NView.NI_STOCK = IM_rec.IM_STOCK AND NView.NI_AVAIL_ACTUAL >= '1' AND NView.NI_STATUS <> 0;

    DBMS_OUTPUT.PUT_LINE(IM_rec.IM_CUST || Chr(9) || IM_rec.IM_STOCK || Chr(9) || CountOfStocks);

    FETCH IM_cur INTO IM_rec;
  END LOOP;
  CLOSE IM_cur;
  DBMS_OUTPUT.put_line('Explicit: ' ||
                       (DBMS_UTILITY.get_time - l_start) || ' hsecs');
END;




CREATE OR REPLACE PROCEDURE create_Tmp_tbl_AdminData
-- use AUTHID CURRENT _USER to execute with the privileges and
-- schema context of the calling user
  AUTHID CURRENT_USER AS
  tabname       VARCHAR2(30); -- variable for table name
  temptabname   VARCHAR2(30); -- temporary variable for table name
  currentdate   VARCHAR2(8);  -- varible for current date
  column_names  VARCHAR2(900); --variable for the create column names
BEGIN
-- extract, format, and insert the year, month, and day from SYSDATE into
-- the currentdate variable
  SELECT TO_CHAR(EXTRACT(YEAR FROM SYSDATE)) ||
     TO_CHAR(EXTRACT(MONTH FROM SYSDATE),'FM09') ||
     TO_CHAR(EXTRACT(DAY FROM SYSDATE),'FM09') INTO currentdate FROM DUAL;
-- construct the log table name with the current date as a suffix
  tabname := 'tbl_AdminData';
  column_names := '(Customer VARCHAR(255),Parent VARCHAR(255),CostCentre VARCHAR(255),OrderNum VARCHAR(255),OrderwareNum VARCHAR(255),CustRef VARCHAR(255),Pickslip VARCHAR(255),PickNum VARCHAR(255),
			    DespatchNote VARCHAR(255),DespatchDate VARCHAR(255),FeeType VARCHAR(255),Item VARCHAR(255),Description VARCHAR(255),Qty NUMBER,UOI VARCHAR(255),UnitPrice NUMBER,OW_Unit_Sell_Price NUMBER,Sell_Excl NUMBER,
			    Sell_Excl_Total NUMBER,Sell_Incl NUMBER,Sell_Incl_Total NUMBER,ReportingPrice NUMBER,Address VARCHAR(255),Address2 VARCHAR(255),Suburb VARCHAR(255),State VARCHAR(255),Postcode VARCHAR(255),
			    DeliverTo VARCHAR(255),AttentionTo VARCHAR(255),Weight NUMBER,Packages NUMBER,OrderSource INTEGER,ILNOTE2 VARCHAR(255),NILOCN VARCHAR(255),NIAVAILACTUAL NUMBER,CountOfStocks NUMBER, Email VARCHAR2(255))';
-- check whether a table already exists with that name
-- if it does NOT exist, then go to exception handler and create table
-- if the table does exist, then note that table already exists
  SELECT TABLE_NAME INTO temptabname FROM USER_TABLES
    WHERE TABLE_NAME = UPPER(tabname);

  DECLARE
    l_count NUMBER;
  BEGIN
    select count(*)
    into l_count
    from tbl_AdminData;
    --where table_name = 'tbl_AdminData';

    if l_count > 0 then
     BEGIN
        --Empty table contents
        --TRUNCATE TABLE Tmp_Admin_Data2;
        EXECUTE IMMEDIATE 'DROP TABLE tbl_AdminData';
        DBMS_OUTPUT.PUT_LINE(tabname || ' has been dropped');
        --Now ready to re run query


        -- use EXECUTE IMMEDIATE to create a table with tabname as the table name
        EXECUTE IMMEDIATE 'CREATE TABLE ' || tabname
                          || column_names ;
        DBMS_OUTPUT.PUT_LINE(tabname || ' hasnt been created');
      END;
    end if;
  END;


  DBMS_OUTPUT.PUT_LINE('Table ' || tabname || ' already exists.');


  EXCEPTION
    WHEN NO_DATA_FOUND THEN
    -- this means the table does not exist because the table name
    -- was not found in USER_TABLES



      BEGIN
-- use EXECUTE IMMEDIATE to create a table with tabname as the table name
        EXECUTE IMMEDIATE 'CREATE TABLE ' || tabname
                         || column_names ;
        DBMS_OUTPUT.PUT_LINE(tabname || ' has been createded');
      END;

END create_Tmp_tbl_AdminData;



CREATE OR REPLACE PROCEDURE create_AdminDataR
-- use AUTHID CURRENT _USER to execute with the privileges and
-- schema context of the calling user
  AUTHID CURRENT_USER AS
  tabname       VARCHAR2(30); -- variable for table name
  temptabname   VARCHAR2(30); -- temporary variable for table name
  currentdate   VARCHAR2(8);  -- varible for current date
  column_names  VARCHAR2(900); --variable for the create column names
BEGIN
-- extract, format, and insert the year, month, and day from SYSDATE into
-- the currentdate variable
  SELECT TO_CHAR(EXTRACT(YEAR FROM SYSDATE)) ||
     TO_CHAR(EXTRACT(MONTH FROM SYSDATE),'FM09') ||
     TO_CHAR(EXTRACT(DAY FROM SYSDATE),'FM09') INTO currentdate FROM DUAL;
-- construct the log table name with the current date as a suffix
  tabname := 'tbl_AdminData';
  column_names := '(Customer VARCHAR(255),Parent VARCHAR(255),CostCentre VARCHAR(255),OrderNum VARCHAR(255),OrderwareNum VARCHAR(255),CustRef VARCHAR(255),Pickslip VARCHAR(255),PickNum VARCHAR(255),
			    DespatchNote VARCHAR(255),DespatchDate VARCHAR(255),FeeType VARCHAR(255),Item VARCHAR(255),Description VARCHAR(255),Qty NUMBER,UOI VARCHAR(255),UnitPrice NUMBER,OW_Unit_Sell_Price NUMBER,Sell_Excl NUMBER,
			    Sell_Excl_Total NUMBER,Sell_Incl NUMBER,Sell_Incl_Total NUMBER,ReportingPrice NUMBER,Address VARCHAR(255),Address2 VARCHAR(255),Suburb VARCHAR(255),State VARCHAR(255),Postcode VARCHAR(255),
			    DeliverTo VARCHAR(255),AttentionTo VARCHAR(255),Weight NUMBER,Packages NUMBER,OrderSource INTEGER,ILNOTE2 VARCHAR(255),NILOCN VARCHAR(255),NIAVAILACTUAL NUMBER,CountOfStocks NUMBER, Email VARCHAR2(255))';
-- check whether a table already exists with that name
-- if it does NOT exist, then go to exception handler and create table
-- if the table does exist, then note that table already exists
  SELECT TABLE_NAME INTO temptabname FROM USER_TABLES
    WHERE TABLE_NAME = UPPER(tabname);


  BEGIN
-- use EXECUTE IMMEDIATE to create a table with tabname as the table name
        EXECUTE IMMEDIATE 'CREATE TABLE ' || tabname
                         || column_names ;
        DBMS_OUTPUT.PUT_LINE(tabname || ' has been createded');
      END;






  DBMS_OUTPUT.PUT_LINE('Table ' || tabname || ' already exists.');


  EXCEPTION
    WHEN NO_DATA_FOUND THEN
    -- this means the table does not exist because the table name
    -- was not found in USER_TABLES

    DECLARE
    l_count NUMBER;
  BEGIN
    select count(*)
    into l_count
    from tbl_AdminData;
    --where table_name = 'tbl_AdminData';

    if l_count > 0 then
     BEGIN
        --Empty table contents
        --TRUNCATE TABLE Tmp_Admin_Data2;
        EXECUTE IMMEDIATE 'DROP TABLE tbl_AdminData';
        DBMS_OUTPUT.PUT_LINE(tabname || ' has been dropped');
        --Now ready to re run query


        -- use EXECUTE IMMEDIATE to create a table with tabname as the table name
        EXECUTE IMMEDIATE 'CREATE TABLE ' || tabname
                          || column_names ;
        DBMS_OUTPUT.PUT_LINE(tabname || ' hasnt been created');
      END;
    end if;
  END;




END create_AdminDataR;



BEGIN
  create_Tmp_tbl_AdminData;
END;


BEGIN
  create_Tmp_tbl_AdminDataR;
END;

    select count(*)
    from tbl_AdminData
    where table_name = 'tbl_AdminData';






DECLARE
  ve_TableNotExists EXCEPTION;
  PRAGMA EXCEPTION_INIT(ve_TableNotExists, -942);
  sqlstring   VARCHAR2(1000);
  s_temptable VARCHAR2(50):= 'ZJXB_work_area';
  rows NUMBER;
BEGIN
  -- Drop Table
  sqlstring := 'DROP TABLE ' || s_temptable;
  EXECUTE IMMEDIATE sqlstring;

--  EXCEPTION
    -- if execute immediate fails, because table not exists, transaction will be committed
--    WHEN OTHERS THEN
--      IF SQLCODE <> -942 THEN
--        RAISE;
--      END IF;

  EXCEPTION
    WHEN ve_TableNotExists THEN
      -- dbms_output.put_line(s_temptable || ' not exist, skipping....');
      -- Create Table
      sqlstring:= 'CREATE GLOBAL TEMPORARY TABLE ' || s_temptable || ' (' ||
        'temp_ID NUMBER, ' ||
        'temp_VM_NAME varchar(17), ' ||
        'temp_VM_SURNAME varchar(71))';
      EXECUTE IMMEDIATE sqlstring;

      -- Populate s_temptable
      sqlstring:= 'INSERT INTO ' || s_temptable || q'[ SELECT vVM.ID, vVM.VM_NAME, vVM.VM_SURNAME FROM pwin175.VM vVM WHERE vVM.ID < 100]';
      EXECUTE IMMEDIATE sqlstring;

      -- Display Number of Records
      EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM ' || s_temptable INTO rows;
      DBMS_OUTPUT.PUT_LINE('Number of records in ' || s_temptable || ' ' || rows);

    WHEN OTHERS THEN
      dbms_output.put_line('Passing here ... ' || ' ' || SQLERRM);
      RAISE;  -- exit the script
END;


SELECT * FROM pwin175.ZJXB_work_area;

-- Executing Create Table as a stand-alone syntax
DROP TABLE ZJXB_work_area;




-- Other scrap

DECLARE
  sqlstring   VARCHAR2(1000);
  s_temptable VARCHAR2(50):= 'ZJXB_work_area';
  v_author ZJXB_work_area%rowtype;
BEGIN
  sqlstring:= 'SELECT * INTO v_author FROM ' || s_temptable;
 EXECUTE IMMEDIATE sqlstring;
  --dbms_output.put_line(v_author.temp_VM_NAME||' '|| v_author.temp_VM_SURNAME);
END;




-- Executing Create Table as a stand-alone syntax

DROP TABLE ZJXB_work_area;

CREATE GLOBAL TEMPORARY TABLE ZJXB_work_area
    INSERT INTO ZJXB_work_area AS SELECT vVM.ID, vVM.VM_NAME, vVM.VM_SURNAME FROM pwin175.VM vVM WHERE vVM.ID < 100;



SELECT * FROM pwin175.ZJXB_work_area



CREATE OR REPLACE PROCEDURE testProc IS
   s_cmd  VARCHAR(20);
   s_sql  VARCHAR2(80);
BEGIN
   --s_cmd := 'DROP TABLE';
   --s_sql := s_cmd + 'ZJXB_work_area';
   --EXECUTE IMMEDIATE s_sql;

   s_cmd := 'CREATE TEMPORARY TABLE';
   s_sql := s_cmd + 'ZJXB_work_area as select vm_name from VM where ID = 20';
   EXECUTE IMMEDIATE s_sql;

EXCEPTION
   -- Use this to trap the ORA-00942: table or view does not exist
   WHEN OTHERS THEN
       NULL;
end testProc;



