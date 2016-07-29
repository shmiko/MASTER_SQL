/* First run this file with variables set in header - declare variables - drop tables, recreate tables, insert into tables - then query tables */
/* EOM_INVOICING_CREATE_TABLES.sql */
--Admin Order Data by Parent or Customer
/*decalre variables These are being declared via the stored procedure - just need to redeclare cust so as we can get the rates*/
var cust varchar2(20)
exec :cust := 'LUXOTTICA'
var cust2 varchar2(20)
exec :cust := 'TABCORP'
var ordernum varchar2(20)
exec :ordernum := '1363806'
var stock varchar2(20)
exec :stock := 'COURIER'
var stock2 VARCHAR2(50)
EXEC :stock2 := 'FEE*'
var source varchar2(20)
exec :source := 'BSPRINTNSW'
var sAnalysis varchar2(20) /*VerbalOrderEntryFee*/
exec SELECT  RM_ANAL INTO :sAnalysis FROM RM where RM_CUST = :cust;
var anal varchar2(20)
exec :anal := '49'
var start_date varchar2(20)
exec :start_date := To_Date('31-Mar-2014')
var end_date varchar2(20)
exec :end_date := To_Date('1-Apr-2014')
var nx NUMBER
EXEC :nx := 1810105
var query VARCHAR2(2000)
EXEC :query := 'SELECT    SH.SH_CUST,  RM.RM_PARENT, SH.SH_ORDER,  SH.SH_SPARE_STR_5,SH.SH_CUST_REF,SH.SH_ADDRESS,SH.SH_SUBURB,SH.SH_CITY, SH.SH_STATE , SH.SH_POST_CODE , SH.SH_NOTE_1 ,SH.SH_NOTE_2 ,SH.SH_SPARE_DBL_9 FROM      PWIN175.SH INNER JOIN PWIN175.RM  ON RM.RM_CUST  = SH.SH_CUST WHERE SH.SH_STATUS <> 3 AND     RM.RM_CUST = cdsg_cust_in AND       SH.SH_ADD_DATE >= cdsg_date_from_in AND SH.SH_ADD_DATE <= cdsg_date_to_in GROUP BY SH.SH_CUST,  RM.RM_PARENT, SH.SH_ORDER,  SH.SH_SPARE_STR_5,SH.SH_CUST_REF,SH.SH_ADDRESS,SH.SH_SUBURB, SH.SH_CITY, SH.SH_STATE , SH.SH_POST_CODE , SH.SH_NOTE_1 ,SH.SH_NOTE_2 ,SH.SH_SPARE_DBL_9'

/*Stocks*/
  CREATE OR REPLACE PROCEDURE DESP_STOCK_GET    (
              cdsg_date_from_in IN  SH.SH_ADD_DATE%TYPE,
              cdsg_date_to_in IN  SH.SH_EDIT_DATE%TYPE,
              cdsg_cust_in IN RM.RM_CUST%TYPE
              ) AS

   CURSOR cdsg_cur IS
   SELECT    SH.SH_CUST,  RM.RM_PARENT, SH.SH_ORDER,  SH.SH_SPARE_STR_5,SH.SH_CUST_REF,SH.SH_ADDRESS,SH.SH_SUBURB,
		SH.SH_CITY, SH.SH_STATE , SH.SH_POST_CODE , SH.SH_NOTE_1 ,SH.SH_NOTE_2 ,SH.SH_SPARE_DBL_9
	FROM      PWIN175.SH INNER JOIN PWIN175.RM  ON RM.RM_CUST  = SH.SH_CUST
  WHERE SH.SH_STATUS <> 3
  AND     RM.RM_CUST = cdsg_cust_in
	AND       SH.SH_ADD_DATE >= cdsg_date_from_in AND SH.SH_ADD_DATE <= cdsg_date_to_in
	GROUP BY SH.SH_CUST,  RM.RM_PARENT, SH.SH_ORDER,  SH.SH_SPARE_STR_5,SH.SH_CUST_REF,SH.SH_ADDRESS,SH.SH_SUBURB,
		SH.SH_CITY, SH.SH_STATE , SH.SH_POST_CODE , SH.SH_NOTE_1 ,SH.SH_NOTE_2 ,SH.SH_SPARE_DBL_9;
    cdsg_rec cdsg_cur%ROWTYPE;
  BEGIN
    OPEN cdsg_cur;
    FETCH cdsg_cur INTO cdsg_rec;
    WHILE cdsg_cur%FOUND
    LOOP
      DBMS_OUTPUT.PUT_LINE(cdsg_rec.SH_CUST || ',' || cdsg_rec.RM_PARENT || ',' || cdsg_rec.SH_SPARE_STR_5 || ',' || cdsg_rec.SH_ORDER || ',' || cdsg_rec.SH_SPARE_DBL_9 || ',' || cdsg_rec.SH_NOTE_2 || ',' || cdsg_rec.SH_NOTE_1 || ',' || cdsg_rec.SH_CITY );
      FETCH cdsg_cur INTO cdsg_rec;
    END LOOP;
  CLOSE cdsg_cur;
 END DESP_STOCK_GET;


   /* OPEN gc_cur;
    FETCH gc_cur INTO gc_rec;
    WHILE(gc_cur%FOUND)
    LOOP
      DBMS_OUTPUT.PUT_LINE(gc_rec.Customer || ',' || gc_rec.Parent || ',' || gc_rec.OrderwareNum || ',' || "gc_rec.Order" || ',' || gc_rec.PickNum || ',' || gc_rec.FeeType || ',' || gc_rec.Item || ',' || gc_rec.Description );
      FETCH gc_cur INTO gc_rec;
    END LOOP;
    CLOSE gc_cur;
  END CUST_DESP_STOCK_GET;  */
--Customer	Parent	CostCentre	Order	OrderwareNum	CustomerRef	Pickslip	PickNum	DespatchNote	DespatchDate	FeeType	Item	Description	Qty	UOI	Batch/UnitPrice	OWUnitPrice	DExcl	Excl_Total	DIncl	Incl_Total	ReportingPrice	Address	Address2	Suburb	State	Postcode	DeliverTo	AttentionTo	Weight	Packages	OrderSource	Pallet/Shelf Space	Locn	AvailSOH	CountOfStocks	EMAIL	BRAND

 EXECUTE DESP_STOCK_GET ('2-Apr-2014','8-Apr-2014','LUXOTTICA')