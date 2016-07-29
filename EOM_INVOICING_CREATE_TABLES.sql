/*decalre variables These are being declared via the stored procedure - just need to redeclare cust so as we can get the rates*/

var cust varchar2(20)
exec :cust := 'LINK'
var nx NUMBER
EXEC :nx := 1810105
var cust2 varchar2(20)
exec :cust2 := 'TABCORP'

var ordernum varchar2(20)
exec :ordernum := '1363806'
var stock varchar2(20)
exec :stock := 'COURIER'
var source varchar2(20)
exec :source := 'BSPRINTNSW'
var sAnalysis varchar2(20) /*VerbalOrderEntryFee*/
exec SELECT  RM_ANAL INTO :sAnalysis FROM RM where RM_CUST = :cust;
var anal varchar2(20)
exec :anal := '22NSWP'
var start_date varchar2(20)
exec :start_date := To_Date('1-Jul-2014')
var end_date varchar2(20)
exec :end_date := To_Date('31-Jul-2014')


/*decalre variables*/



--Drops
/* Drop Temp Grp Cust Table */
  --select * from Tmp_Group_Cust;
  --DROP TABLE Tmp_Group_Cust;
    TRUNCATE TABLE Tmp_Group_Cust;
/* Drop Temp Grp Cust Table */

/* Drop table to hold II values */
	TRUNCATE TABLE Tmp_Admin_Data_BreakPrices;
/* Drop table to hold II values */

/*drop temp table to hold pickslip numbers*/
	TRUNCATE TABLE Tmp_Admin_Data_Pickslips;
/*drop temp table to hold pickslip numbers*/

/* Drop temp table to hold SL line data */
	TRUNCATE TABLE Tmp_Admin_Data_Pick_LineCounts;
/* Drop temp table to hold SL line data */

/*Drop temp table for batch prices*/
	TRUNCATE TABLE  Tmp_Batch_Price_SL_Stock;
/*Drop temp table for batch prices*/

/* drop temp table for location counts */
  TRUNCATE TABLE  Tmp_Locn_Cnt_By_Cust;
/* drop temp table for location counts */

/*Drop temp admin data table*/
	TRUNCATE TABLE tbl_AdminData;
  --DROP TABLE tbl_AdminData;
/*Drop temp admin data table*/

/*Drop temp Tmp_Log_stats*/
  TRUNCATE TABLE Tmp_Log_stats;
/*Drop temp Tmp_Log_stats*/

/*Truncate Tmp_Cust_Reporting*/
  --DROP TABLE Tmp_Cust_Reporting;

  TRUNCATE TABLE Tmp_Cust_Reporting;
/*Truncate Tmp_Cust_Reporting*/

--Creates
/* Create Temp Group Cust Table */
  --CREATE TABLE Tmp_Group_Cust ( sGroupCust VARCHAR2(20), sCust VARCHAR2(20), nLevel NUMBER);
/* Create Temp Group Cust Table */

/* Create table to hold II values */
	--CREATE TABLE Tmp_Admin_Data_BreakPrices (vIIStock VARCHAR(30), vIICust VARCHAR(20), vUnitPrice NUMBER);
/* Create table to hold II values */

/*create temp table to hold pickslip numbers*/
	--CREATE TABLE Tmp_Admin_Data_Pickslips (vPickslip VARCHAR(200),vPslip VARCHAR(10), vDateDesp DATE, vPackages NUMBER,
                                        --vWeight NUMBER, vST_XX_NUM_PAL_SW NUMBER,vST_XX_NUM_PALLETS NUMBER, vST_XX_NUM_CARTONS NUMBER);
/*create temp table to hold pickslip numbers*/

/* Create temp table to hold SL line data */
	--CREATE TABLE Tmp_Admin_Data_Pick_LineCounts (  nCountOfLines NUMBER, vSLPickslipNum VARCHAR(10), vSLOrderNum VARCHAR2(10), vSLPslip VARCHAR(10), vDateDespSL VARCHAR(255)
	--,vPackagesSL NUMBER, vWeightSL NUMBER,vST_XX_NUM_PAL_SW_SL NUMBER,vST_XX_NUM_PALLETS_SL NUMBER, vST_XX_NUM_CARTONS_SL NUMBER);
/* Create temp table to hold SL line data */

/*Create temp table for batch prices*/
	--CREATE TABLE Tmp_Batch_Price_SL_Stock ( vBatchStock VARCHAR(30), vBatchPickNum VARCHAR(10), vDExcl NUMBER, vUnitPrice NUMBER, vQuantity NUMBER);
/*Create temp table for batch prices*/

/*Create Tmp_Locn_Cnt_By_Cust*/
  --CREATE TABLE Tmp_Locn_Cnt_By_Cust ( nCountOfStocks NUMBER, sLocn VARCHAR2(20), sCust VARCHAR2(20), sNote VARCHAR(20));
/*Create temp table for batch prices*/

/*create temp admin data table
	CREATE global temporary TABLE tbl_AdminData
	(       Customer VARCHAR(255),Parent VARCHAR(255),CostCentre VARCHAR(255),OrderNum VARCHAR(255),OrderwareNum VARCHAR(255),CustRef VARCHAR(255),Pickslip VARCHAR(255),PickNum VARCHAR(255),
			    DespatchNote VARCHAR(255),DespatchDate VARCHAR(255),FeeType VARCHAR(255),Item VARCHAR(255),Description VARCHAR(255),Qty NUMBER,UOI VARCHAR(255),UnitPrice NUMBER,OW_Unit_Sell_Price NUMBER,Sell_Excl NUMBER,
			    Sell_Excl_Total NUMBER,Sell_Incl NUMBER,Sell_Incl_Total NUMBER,ReportingPrice NUMBER,Address VARCHAR(255),Address2 VARCHAR(255),Suburb VARCHAR(255),State VARCHAR(255),Postcode VARCHAR(255),
			    DeliverTo VARCHAR(255),AttentionTo VARCHAR(255),Weight NUMBER,Packages NUMBER,OrderSource INTEGER,ILNOTE2 VARCHAR(255),NILOCN VARCHAR(255),CountOfStocks NUMBER, Email VARCHAR2(255), Brand VARCHAR2(255),
          OwnedBy VARCHAR2(255) , sProfile VARCHAR2(255), WaiveFee VARCHAR2(255), Cost VARCHAR(255), PaymentType VARCHAR(255)
  );
/*create temp admin data table*/

/*Drop temp Tmp_Log_stats*/
  --DROP TABLE Tmp_Log_stats
  --CREATE TABLE Tmp_Log_stats (sWarehouse VARCHAR2(50), sCust VARCHAR2(50), nTotal NUMBER, sType VARCHAR2(50));
/*Drop temp Tmp_Log_stats*/

  --CREATE TABLE  Drop Table Tmp_Stock_Changes (sStock VARCHAR2(20),sCust VARCHAR2(20),sGoInactiveOld VARCHAR2(20), sGoInactiveNew VARCHAR2(20))


  ----CREATE global temporary TABLE  Tmp_Cust_Reporting (sCust VARCHAR2(20),sHeaders VARCHAR2(1000));
   --Select * From  Tmp_Cust_Reporting
--Inserts
/* Insert data into Temp Group Cust Table
  INSERT into Tmp_Group_Cust(sCust,sGroupCust,nLevel )
                SELECT RM_CUST
                        ,(
                          CASE
                            WHEN LEVEL = 1 THEN RM_CUST
                            WHEN LEVEL = 2 THEN RM_PARENT
                            WHEN LEVEL = 3 THEN PRIOR RM_PARENT
                            WHEN LEVEL = 4 THEN 'COLESGROUP'
                            ELSE 'STILLNOGROUPCUST'
                          END
                        ) AS CC
                        ,LEVEL
                  FROM RM
                  WHERE RM_TYPE = 0
                  AND RM_ACTIVE = 1
                  --AND Length(RM_GROUP_CUST) <=  1
                  CONNECT BY PRIOR RM_CUST = RM_PARENT
                  START WITH Length(RM_PARENT) <= 1 ;
                  SET AUTOTRACE ON EXPLAIN;  */
  ---Converted to procedure GROUP_CUST_START
  EXECUTE eom_report_pkg.GROUP_CUST_START;


/* Insert data into Temp Group Cust Table */

/* Insert into table to hold II values */
	INSERT INTO Tmp_Admin_Data_BreakPrices
	SELECT II_STOCK,II_CUST,II_BREAK_LCL
	FROM II INNER JOIN IM ON IM_STOCK = II_STOCK
	AND II_BREAK_LCL > 0.000001
	WHERE IM_CUST= 'TABCORP';
  --WHERE IM_CUST = 'TABCORP'
/* Insert into table to hold II values */

/*insert into temp table to hold pickslip numbers*/  --3sec
	INSERT INTO Tmp_Admin_Data_Pickslips
	--SELECT LTrim(ST_PICK),LTrim(ST_PSLIP), substr(To_Char(ST_DESP_DATE),0,10), ST_WEIGHT, ST_PACKAGES,ST_XX_NUM_PAL_SW,ST_XX_NUM_PALLETS,ST_XX_NUM_CARTONS
	--FROM ST INNER JOIN SH ON SH_ORDER = ST_ORDER
	--WHERE ST_DESP_DATE >= :start_date AND ST_DESP_DATE <= :end_date
	--AND ST_PSLIP <> 'CANCELLED'
	--AND SH_STATUS <> 3; -- 2757190 rows .5 sec

  SELECT LTrim(ST_PICK),LTrim(ST_PSLIP), substr(To_Char(ST_DESP_DATE),0,10), ST_WEIGHT, ST_PACKAGES,ST_XX_NUM_PAL_SW,ST_XX_NUM_PALLETS,ST_XX_NUM_CARTONS
	FROM ST LEFT JOIN SH ON SH_ORDER = ST_ORDER
	WHERE ST_DESP_DATE >= :start_date AND ST_DESP_DATE <= :end_date
	AND ST_PSLIP <> 'CANCELLED'
	AND SH_STATUS <> 3;
  --17263 in .5s  Correct

/*insert into temp table to hold pickslip numbers*/

/* Insert into temp table to hold SL line data */
	INSERT INTO Tmp_Admin_Data_Pick_LineCounts  --17263 in 1.69s
	SELECT MAX(SL_LINE),LTrim(SL_PICK), LTrim(SL_ORDER), LTrim(SL_PSLIP),TP.vDateDesp, TP.vPackages,TP.vWeight,TP.vST_XX_NUM_PAL_SW,TP.vST_XX_NUM_PALLETS,TP.vST_XX_NUM_CARTONS--,SL_PICK_QTY, SL_ORDER_LINE
	FROM Tmp_Admin_Data_Pickslips TP RIGHT JOIN SL ON LTrim(SL_PICK) = TP.vPickslip   WHERE SL_PSLIP <> 'CANCELLED' AND SL_EDIT_DATE >= :start_date AND SL_EDIT_DATE <= :end_date
  GROUP BY SL_PICK,SL_ORDER,SL_PSLIP,TP.vDateDesp,TP.vPackages,TP.vWeight,TP.vST_XX_NUM_PAL_SW,TP.vST_XX_NUM_PALLETS,TP.vST_XX_NUM_CARTONS;
/* Insert into temp table to hold SL line data */

/*Insert into temp table for batch prices  -- 50s*/
	INSERT INTO Tmp_Batch_Price_SL_Stock(vBatchStock,vBatchPickNum,vUnitPrice,vDExcl, vQuantity)
	SELECT nz.NI_STOCK, LTrim(RTrim(nz.NI_SL_PSLIP)), CAST((NX_SELL_VALUE/NX_QUANTITY) AS DECIMAL(22,2)) AS "UnitPrice", CAST(xz.NX_SELL_VALUE AS DECIMAL(22,2)), xz.NX_QUANTITY
	--Count(ROWNUM) AS "RecordCount"
	FROM  NX xz INNER JOIN NI nz ON nz.NI_NX_MOVEMENT = xz.NX_MOVEMENT
	INNER JOIN NE ez ON ez.NE_ENTRY = nz.NI_ENTRY AND ez.NE_PRICE_ENTRY = xz.NX_ENTRY
	WHERE ez.NE_NV_EXT_TYPE = 1810105
	AND ez.NE_STRENGTH = 3
	AND xz.NX_SELL_VALUE > 0 AND xz.NX_SELL_VALUE IS NOT NULL
	AND xz.NX_QUANTITY > 0
	AND ez.NE_ADD_DATE >= :start_date
	--AND ez.NE_NV_EXT_KEY = (SELECT SL_UID FROM SL WHERE LTrim(RTrim(SL_PICK)) = '2607366')-- AND SL_ORDER_LINE  = 1)
	GROUP BY nz.NI_STOCK, nz.NI_SL_PSLIP, xz.NX_SELL_VALUE, xz.NX_QUANTITY;
/*Insert into temp table for batch prices*/

/*Insert into SELECT * FROM Tmp_Locn_Cnt_By_Cust  -- 13s*/
  INSERT INTO Tmp_Locn_Cnt_By_Cust

  SELECT Count(DISTINCT NI_STOCK) AS CountOfStocks, IL_LOCN, IM_CUST
			FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
			INNER JOIN IM ON IM_STOCK = NI_STOCK
			WHERE IM_CUST IN (SELECT RM_CUST FROM RM WHERE /*RM_PARENT = ' '  AND*/ RM_ANAL = :sAnalysis AND RM_TYPE = 0 AND RM_ACTIVE = 1 )
      AND IM_ACTIVE = 1
			AND NI_AVAIL_ACTUAL >= '1'
			AND NI_STATUS <> 0
      GROUP BY IL_LOCN, IM_CUST;
       --2408 rows in 1.12 sec

/*Insert into Tmp_Locn_Cnt_By_Cust*/

                        --Select * From  Tmp_Cust_Reporting
/* Insert into Tmp_Cust_Reporting
	INSERT INTO Tmp_Cust_Reporting (sCust, sHeaders )
  VALUES ('LUXOTTICA',
		'Parent As Invoice#,
		OrderNum As SourceSalesOrder,
		OrderwareNum As Helium#,
		DespatchNote As Despatch#,
		FeeType As FeeType,
		Item As Item,
		Description As Description,
		Qty As Qty,
		UOI As UOI,
		UnitPrice As UnitPrice,
		Sell_Excl As "Exclusive",
		Sell_Incl As Inclusive,
		Parent As CostCenter,
		CostCentre As CostCenterOwner,
		Weight As Weight,
		Packages As Noofpackages ,
		Email As OrdererEmail,
		AttentionTo As Attnto,
		Address As Address,
		Address2 As Address2,
		Suburb As City,
		State As State,
		PostCode As PostCode,
		NILOCN As Locn,
		CountOfStocks As LineNo' )




--	SELECT II_STOCK,II_CUST,II_BREAK_LCL
--	FROM II INNER JOIN IM ON IM_STOCK = II_STOCK
--	AND II_BREAK_LCL > 0.000001
--	WHERE IM_CUST= :cust;
/* Insert into table to hold II values */


--Queries
/*
/*query temp table to hold pickslip numbers*/
	--SELECT * FROM Tmp_Admin_Data_Pickslips WHERE VPICKSLIP = '2699569' ;
/*query temp table to hold pickslip numbers*/

/* query table to hold II values */
	--SELECT * FROM Tmp_Admin_Data_BreakPrices WHERE VIISTOCK = '500290';
/* query table to hold II values */

/* query temp table to hold SL line data */
	--SELECT * FROM Tmp_Admin_Data_Pick_LineCounts;
/* query temp table to hold SL line data */

/*query temp table for batch prices*/
	--SELECT * FROM Tmp_Batch_Price_SL_Stock;
/*query temp table for batch prices*/

/*query temp Tmp_Locn_Cnt_By_Cust*/
  --SELECT * FROM Tmp_Locn_Cnt_By_Cust WHERE sCust = 'NSWFIRE';
/*query temp Tmp_Locn_Cnt_By_Cust     Select count(*) From tbl_AdminData */

/*query temp group cust table */
  --SELECT * FROM Tmp_Group_Cust where sCust = '31ZMYER295'
/*query temp group cust table */

/*query temp Tmp_Log_stats */
  --SELECT * FROM Tmp_Log_stats WHERE sCust = 'RTA'
  --SELECT * FROM Tmp_Log_stats WHERE sCust = 'TABCORP'
/*query temp Tmp_Log_stats */

   --SELECT (SELECT sHEADERS FROM Tmp_Cust_Reporting Where LTRIM(sCust) = :cust ) FROM tbl_AdminData' from Tmp_Cust_Reporting;
   --SELECT * FROM tbl_AdminData;
 /*  SELECT * FROM Tmp_Cust_Reporting Where LTRIM(sCust) = :cust



 SELECT Parent As Invoice#,
		Customer As Child,
		OrderNum As SourceSalesOrder,
		Parent As CostCenter,
		CostCentre As CostCenterOwner,
		OrderwareNum As OnlineOrder#,
		CustRef As CustRef,
		OrderSource As OrderSource,
		Pickslip As Picklist#,
		DespatchNote As Despatch#,
		DespatchDate As DespDate,
		FeeType As FeeType,
		Item As Item,
		Description As Description,
		NILOCN As Locn,
		Qty As Qty,
		UOI As UOI,
		UnitPrice As UnitPrice,
		Cost	As BatchPrice,
		Sell_Excl As "Exclusive",
		Sell_Incl As Inclusive,
		sProfile As "Profile",
		Email As OrdererEmail,
		AttentionTo As Attnto,
		Address As Address,
		Address2 As Address2,
		Suburb As City,
		State As State,
		PostCode As PostCode,
		Weight As Weight,
		Packages As Cartons ,
		OwnedBy As OwnedBy,
		WaiveFee As FormOwner,
    Cost AS CostPrice
    FROM tbl_AdminData
    ORDER BY sProfile,Cost,OrderNum,Pickslip Asc





 	INSERT INTO Tmp_Cust_Reporting (sCust, sHeaders )
  VALUES ('LUXOTTICA',
		'Parent As Invoice#,
		Customer As Child,
		OrderNum As SourceSalesOrder,
		Parent As CostCenter,
		CostCentre As CostCenterOwner,
		OrderwareNum As Online Order #,
		CustRef As Ref,
		OrderSource As Order Source,
		Pickslip As Picklist #,
		DespatchNote As Despatch#,
		DespatchDate As Desp Date,
		FeeType As FeeType,
		Item As Item,
		Description As Description,
		NILOCN As Locn,
		Qty As Qty,
		UOI As UOI,
		UnitPrice As UnitPrice,
		Cost	As Batch Price,
		Sell_Excl As "Exclusive",
		Sell_Incl As Inclusive,
		sProfile As "Profile",
		Email As OrdererEmail,
		AttentionTo As Attnto,
		Address As Address,
		Address2 As Address2,
		Suburb As City,
		State As State,
		PostCode As PostCode,
		Weight As Weight,
		Packages As Cartons ,
		OwnedBy As OwnedBy,
		WaiveFee As Form Owner'
		)

                                                     */