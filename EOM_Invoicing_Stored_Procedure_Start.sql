--Admin Order Data
/*Set Stored Procedure*/

CREATE OR REPLACE PROCEDURE EOM_INVOICING (
                                           p_ordernum IN VARCHAR2 := '1363806',
                                           p_stock IN VARCHAR2 := 'COURIER',
                                           p_source IN VARCHAR2 := 'BSPRINTNSW',
                                           p_anal IN VARCHAR2 := '72'

                                          )  AUTHID CURRENT_USER   AS
  nCheckpoint  NUMBER;
  p_cust VARCHAR2(30);
  p_start_date  VARCHAR2(20); --:= '1-Jul-2013'
  p_end_date  VARCHAR2(20);-- := '7-Jul-2013'


BEGIN

  --start_date IN  varchar2 :=  '1-Jul-2013';

  --INSERT INTO departments VALUES (deptid, dname, mgrid, locid);
  p_cust := 'TABCORP';
  nCheckpoint := 1;
  p_end_date := '7-Jul-2013';
  p_start_date := '1-Jul-2013';

  BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE Tmp_Admin_Data_BreakPrices';
  EXCEPTION
        WHEN OTHERS THEN
              IF SQLCODE != -942 THEN
                    RAISE;
              END IF;
  END;

  nCheckpoint := 2;

  EXECUTE IMMEDIATE 'CREATE TABLE Tmp_Admin_Data_BreakPrices (vIIStock VARCHAR(30), vIICust VARCHAR(20), vUnitPrice NUMBER)';

  nCheckpoint := 3;

  EXECUTE IMMEDIATE 'INSERT INTO Tmp_Admin_Data_BreakPrices
	                    SELECT II_STOCK,II_CUST,II_BREAK_LCL
	                    FROM II INNER JOIN IM ON IM_STOCK = II_STOCK
	                    AND II_BREAK_LCL > 0.000001
                      AND II_CUST = p_cust' ;

  nCheckpoint := 4;

  BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE Tmp_Admin_Data_Pickslips';
  EXCEPTION
        WHEN OTHERS THEN
              IF SQLCODE != -942 THEN
                    RAISE;
              END IF;
  END;




  nCheckpoint := 5;

  EXECUTE IMMEDIATE 'CREATE TABLE Tmp_Admin_Data_Pickslips (vPickslip VARCHAR(200),vPslip VARCHAR(10), vDateDesp DATE, vPackages NUMBER,
                                        vWeight NUMBER, vST_XX_NUM_PAL_SW NUMBER,vST_XX_NUM_PALLETS NUMBER, vST_XX_NUM_CARTONS NUMBER)';

  nCheckpoint := 6;

  EXECUTE IMMEDIATE 'INSERT INTO Tmp_Admin_Data_Pickslips
	SELECT LTrim(ST_PICK),LTrim(ST_PSLIP), substr(To_Char(ST_DESP_DATE),0,10), ST_WEIGHT, ST_PACKAGES,ST_XX_NUM_PAL_SW,ST_XX_NUM_PALLETS,ST_XX_NUM_CARTONS
	FROM ST INNER JOIN SH ON SH_ORDER = ST_ORDER
	WHERE (ST_DESP_DATE >= p_start_date AND ST_DESP_DATE <= p_end_date)
	AND  LTRIM(substr(ST_PSLIP,0,1)) > 0
	AND (SH_STATUS <> 3)';

  nCheckpoint := 7;

  BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE Tmp_Admin_Data_Pick_LineCounts';
  EXCEPTION
        WHEN OTHERS THEN
              IF SQLCODE != -942 THEN
                    RAISE;
              END IF;
  END;




  nCheckpoint := 8;

  EXECUTE IMMEDIATE 'CREATE TABLE Tmp_Admin_Data_Pick_LineCounts (  nCountOfLines NUMBER, vSLPickslipNum VARCHAR(10), vSLOrderNum VARCHAR2(10), vSLPslip VARCHAR(10), vDateDespSL VARCHAR(255)
	,vPackagesSL NUMBER, vWeightSL NUMBER,vST_XX_NUM_PAL_SW_SL NUMBER,vST_XX_NUM_PALLETS_SL NUMBER, vST_XX_NUM_CARTONS_SL NUMBER,vST_PICK_QTY NUMBER, vSL_ORDER_LINE NUMBER)';


  nCheckpoint := 9;

  EXECUTE IMMEDIATE 'INSERT INTO Tmp_Admin_Data_Pick_LineCounts
	SELECT Count(SL_LINE),LTrim(SL_PICK), LTrim(SL_ORDER), LTrim(SL_PSLIP),TP.vDateDesp, TP.vPackages,TP.vWeight,TP.vST_XX_NUM_PAL_SW,TP.vST_XX_NUM_PALLETS,TP.vST_XX_NUM_CARTONS,SL_PICK_QTY, SL_ORDER_LINE
	FROM Tmp_Admin_Data_Pickslips TP LEFT OUTER JOIN SL ON LTrim(SL_PICK) = TP.vPickslip   WHERE SL_PSLIP <> "CANCELLED"  GROUP BY SL_PICK,SL_ORDER,SL_PSLIP,TP.vDateDesp,TP.vPackages,TP.vWeight,TP.vST_XX_NUM_PAL_SW,TP.vST_XX_NUM_PALLETS,TP.vST_XX_NUM_CARTONS,SL_PICK_QTY, SL_ORDER_LINE';

  nCheckpoint := 10;

  BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE  Tmp_Batch_Price_SL_Stock';
  EXCEPTION
        WHEN OTHERS THEN
              IF SQLCODE != -942 THEN
                    RAISE;
              END IF;
  END;




  nCheckpoint := 11;

  EXECUTE IMMEDIATE 'CREATE TABLE Tmp_Batch_Price_SL_Stock ( vBatchStock VARCHAR(30), vBatchPickNum VARCHAR(10), vDExcl NUMBER, vUnitPrice NUMBER, vQuantity NUMBER)';

  nCheckpoint := 12;

  EXECUTE IMMEDIATE 'INSERT INTO Tmp_Batch_Price_SL_Stock(vBatchStock,vBatchPickNum,vUnitPrice,vDExcl, vQuantity)
	SELECT nz.NI_STOCK, LTrim(RTrim(nz.NI_SL_PSLIP)), CAST((NX_SELL_VALUE/NX_QUANTITY) AS DECIMAL(22,2)) AS "UnitPrice", CAST(xz.NX_SELL_VALUE AS DECIMAL(22,2)), xz.NX_QUANTITY
	--Count(ROWNUM) AS "RecordCount"
	FROM  NX xz INNER JOIN NI nz ON nz.NI_NX_MOVEMENT = xz.NX_MOVEMENT
	INNER JOIN NE ez ON ez.NE_ENTRY = nz.NI_ENTRY AND ez.NE_PRICE_ENTRY = xz.NX_ENTRY
	WHERE ez.NE_NV_EXT_TYPE = 1810105
	AND ez.NE_STRENGTH = 3
	AND xz.NX_SELL_VALUE > 0 AND xz.NX_SELL_VALUE IS NOT NULL
	AND xz.NX_QUANTITY > 0
	AND ez.NE_ADD_DATE >= start_date
	--AND ez.NE_NV_EXT_KEY = (SELECT SL_UID FROM SL WHERE LTrim(RTrim(SL_PICK)) = "2607366")-- AND SL_ORDER_LINE  = 1)
	GROUP BY nz.NI_STOCK, nz.NI_SL_PSLIP, xz.NX_SELL_VALUE, xz.NX_QUANTITY';

  nCheckpoint := 13;

  BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE Tmp_Admin_Data';
  EXCEPTION
        WHEN OTHERS THEN
              IF SQLCODE != -942 THEN
                    RAISE;
              END IF;
  END;



  nCheckpoint := 14;

  EXECUTE IMMEDIATE 'CREATE TABLE Tmp_Admin_Data2
	(       Customer VARCHAR(255),--           AS "Customer",
			Parent VARCHAR(255),--             AS "Parent",
			CostCentre VARCHAR(255),--         AS "CostCentre",
			OrderNum VARCHAR(255),--           AS "Order",
			OrderwareNum VARCHAR(255),--       AS "Order",
			CustRef VARCHAR(255),--            AS "CustRef"
			Pickslip VARCHAR(255),--           AS "Pickslip",
			PickNum VARCHAR(255),--            AS "PickNum",
			DespatchNote VARCHAR(255),--       AS "DespatchNote",
			DespatchDate VARCHAR(255),--       AS "DespatchDate",
			FeeType VARCHAR(255),--            AS "FeeType",
			Item VARCHAR(255),--               AS "Item",
			Description VARCHAR(255),--        AS "Description",
			Qty NUMBER,--                AS "Qty",
			UOI VARCHAR(255),--                AS "UOI",
			Unit_Sell_Price NUMBER,--          AS "UnitPrice",
			OW_Unit_Sell_Price NUMBER,--        AS "OWUnitPrice",
			Sell_Excl NUMBER,--         AS "Excl_Total",
			Sell_Excl_Total NUMBER,--              AS "DIncl",
			Sell_Incl NUMBER,--         AS "Incl_Total",
			Sell_Incl_Total NUMBER,
			ReportingPrice NUMBER,--     AS "ReportingPrice",
			Address VARCHAR(255),--            AS "Address",
			Address2 VARCHAR(255),--           AS "Address2",
			Suburb VARCHAR(255),--             AS "Suburb",
			State VARCHAR(255),--              AS "State",
			Postcode VARCHAR(255),--           AS "Postcode",
			DeliverTo VARCHAR(255),--          AS "DeliverTo",
			AttentionTo VARCHAR(255),--        AS "AttentionTo" ,
			Weight NUMBER,--             AS "Weight",
			Packages NUMBER,--           AS "Packages",
			OrderSource INTEGER,--        AS "OrderSource",
			ILNOTE2 VARCHAR(255),--          AS "Palett/Shelf",
			NILOCN VARCHAR(255),--            AS "Location",
			NIAVAILACTUAL NUMBER,--    AS "SOH",
			CountOfStocks NUMBER     -- AS "Count")';





  RETURN;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('EOM_INVOICING failed at checkpoint ' || nCheckpoint ||
                         ' with error ' || SQLCODE || ' : ' || SQLERRM);
    RAISE;
END EOM_INVOICING;








/*SELECT * FROM Tmp_Admin_Data
ORDER BY vOrder,vPickslip Asc    */