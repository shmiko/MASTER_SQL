  /* First run this file with variables set in header - declare variables - drop tables, recreate tables, insert into tables - then query tables */
  /* EOM_INVOICING_CREATE_TABLES.sql */
  --Admin Order Data by Parent or Customer
  /*decalre variables These are being declared via the stored procedure - just need to redeclare cust so as we can get the rates*/
  var cust varchar2(20)
  exec :cust := 'CONNECTVIC'
  var ordernum varchar2(20)
  exec :ordernum := '1363806'
  var stock varchar2(20)
  exec :stock := 'COURIER'
  var source varchar2(20)
  exec :source := 'BSPRINTNSW'
  var sAnalysis varchar2(20) /*VerbalOrderEntryFee*/
  exec SELECT  RM_ANAL INTO :sAnalysis FROM RM where RM_CUST = :cust;
  var anal varchar2(20)
  exec :anal := '21VICP'
  var start_date varchar2(20)
  exec :start_date := To_Date('01-Mar-2014')
  var end_date varchar2(20)
  exec :end_date := To_Date('28-Mar-2014')



  /*SELECT  RM_ANAL FROM RM WHERE RM_CUST = 'LINK' */

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

    var nRM_XX_FEE31_1 NUMBER /*Minimun Monthly Charge Fee*/
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



  --EXEC EOM_INVOICING();--:cust,:ordernum,:stock,:source,:anal,:start_date,:end_date);
    --SET TIMING ON;

  /*insert into temp admin data table*/
	  INSERT into tbl_AdminData(
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
          Email,
          Brand

				  )
  /*insert into temp admin data table*/


  /*Stocks*/ --113 secs

	  SELECT    s.SH_CUST                AS "Customer",
			    r.RM_PARENT              AS "Parent",
	    CASE    WHEN i.IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
			    WHEN i.IM_CUST = 'TABCORP' THEN i.IM_XX_COST_CENTRE01
			    ELSE i.IM_XX_COST_CENTRE01
			    END                      AS "CostCentre",
			    s.SH_ORDER               AS "Order",
			    s.SH_SPARE_STR_5         AS "OrderwareNum",
			    s.SH_CUST_REF            AS "CustomerRef",
			    t.ST_PICK                AS "Pickslip",
			    d.SD_XX_PICKLIST_NUM     AS "PickNum",
			    t.ST_PSLIP               AS "DespatchNote",
			    --NULL AS "DespatchDate",
			    substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	    CASE    WHEN d.SD_STOCK IS NOT NULL THEN 'Stock'
			    ELSE NULL
			    END                      AS "FeeType",
			    d.SD_STOCK               AS "Item",
			    d.SD_DESC                AS "Description",
			    l.SL_PSLIP_QTY           AS "DespQty",
			    d.SD_QTY_UNIT            AS "UOI",
			    /* We need to get a 3 tiered looup for the stockunit prices, fist get th eprice from thE BATCH if company owned otherwise get the unit price from the sd sell price otherwise get it from the ow xx */
	    CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN d.SD_SELL_PRICE --company owned
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1 AND n.NI_NX_QUANTITY > 0 THEN n.NI_SELL_VALUE/n.NI_NX_QUANTITY
              WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NOT NULL THEN  (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			        ELSE NULL
			        END                        AS "Batch/UnitPrice",

		  /*CASE    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1 THEN d.SD_SELL_PRICE --customer owned
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN (SELECT NX_SELL_VALUE FROM  NX INNER JOIN NE ON NE_PRICE_ENTRY = NX_ENTRY INNER JOIN NI ON NI_ENTRY = NE_ENTRY AND NX_MOVEMENT = NI_NX_MOVEMENT
																								                                                  WHERE NE_NV_EXT_TYPE = 1810105  AND NE_STRENGTH = 3 AND NE_NV_EXT_KEY = (SELECT SL_UID FROM SL WHERE LTrim(RTrim(SL_PICK)) = LTrim(RTrim(t.ST_PICK)) AND SL_ORDER_LINE  = d.SD_LINE)
																								                                                  AND NE_DATE = t.ST_DESP_DATE
																								                                                  AND NE_STOCK = d.SD_STOCK)
			        --WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NOT NULL THEN  (SELECT To_Number(vUnitPrice) * d.SD_QTY_DESP FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE  * d.SD_QTY_DESP
			        ELSE NULL
			        END                        AS "DExcl",*/
	    CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN To_Number(i.IM_REPORTING_PRICE)
			    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN  (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
			    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			    ELSE NULL
			    END                        AS "OWUnitPrice",
        CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN d.SD_SELL_PRICE * d.SD_QTY_DESP--customer owned
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1 AND n.NI_NX_QUANTITY > 0 THEN (n.NI_SELL_VALUE/n.NI_NX_QUANTITY) * d.SD_QTY_DESP
              WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NOT NULL THEN  (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) * d.SD_QTY_DESP
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE * d.SD_QTY_DESP
			        ELSE NULL
			        END          AS "DExcl",

	    CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN To_Number(i.IM_REPORTING_PRICE)
			    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN  (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
			    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			    ELSE NULL
			    END                       AS "Excl_Total",
	    CASE     WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN (d.SD_SELL_PRICE * d.SD_QTY_DESP) * 1.1--customer owned
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1  AND n.NI_NX_QUANTITY > 0 THEN  ((n.NI_SELL_VALUE/n.NI_NX_QUANTITY) * d.SD_QTY_DESP) * 1.1
              WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NOT NULL THEN  ((SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) * d.SD_QTY_DESP) * 1.1
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  (d.SD_XX_OW_UNIT_PRICE * d.SD_QTY_DESP) * 1.1
			        ELSE NULL
			        END          AS "DIncl",
	    CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN (d.SD_SELL_PRICE * d.SD_QTY_DESP) * 1.1--customer owned
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1 AND n.NI_NX_QUANTITY > 0 THEN  ((n.NI_SELL_VALUE/n.NI_NX_QUANTITY) * d.SD_QTY_DESP) * 1.1
              WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NOT NULL THEN  ((SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) * d.SD_QTY_DESP) * 1.1
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  (d.SD_XX_OW_UNIT_PRICE * d.SD_QTY_DESP) * 1.1
			        ELSE NULL
			        END          AS "Incl_Total",
	    CASE    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN To_Number(i.IM_REPORTING_PRICE)
			    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN  (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
			    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			    ELSE NULL
			    END                      AS "ReportingPrice",
			    s.SH_ADDRESS             AS "Address",
			    s.SH_SUBURB              AS "Address2",
			    s.SH_CITY                AS "Suburb",
			    s.SH_STATE               AS "State",
			    s.SH_POST_CODE           AS "Postcode",
			    s.SH_NOTE_1              AS "DeliverTo",
			    s.SH_NOTE_2              AS "AttentionTo" ,
			    t.ST_WEIGHT              AS "Weight",
			    t.ST_PACKAGES            AS "Packages",
			    s.SH_SPARE_DBL_9         AS "OrderSource",
			    NULL AS "Pallet/Shelf Space", /*Pallet/Space*/
				  NULL AS "Locn", /*Locn*/
				  0 AS "AvailSOH",/*Avail SOH*/
				  0 AS "CountOfStocks",
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			          ELSE ''
			          END AS Email,
                i.IM_BRAND AS Brand

	  FROM      PWIN175.SD d
			    INNER JOIN PWIN175.SH s  ON s.SH_ORDER  = d.SD_ORDER
			    INNER JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER
          INNER JOIN PWIN175.SL l  ON l.SL_PICK   = t.ST_PICK
			    INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
			    INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
          INNER JOIN PWIN175.NI n  ON n.NI_NV_EXT_KEY = l.SL_UID
     WHERE NI_NV_EXT_TYPE = 1810105 AND NI_STRENGTH = 3 AND NI_DATE = t.ST_DESP_DATE AND NI_STOCK = d.SD_STOCK AND NI_STATUS <> 0
	  AND     s.SH_STATUS <> 3
    AND       s.SH_ORDER = t.ST_ORDER
	  AND       d.SD_STOCK NOT LIKE 'COURIER'
	  AND       d.SD_STOCK NOT LIKE 'FEE*'
	  AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
	  AND       d.SD_LAST_PICK_NUM = t.ST_PICK
    AND     i.IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_ANAL = :anal)
	  GROUP BY  s.SH_CUST,
			    s.SH_NOTE_1,
			    s.SH_CAMPAIGN,
			    s.SH_SPARE_STR_4,
			    i.IM_XX_COST_CENTRE01,
			    i.IM_CUST,
			    r.RM_PARENT,
			    s.SH_ORDER,
			    t.ST_PICK,
			    d.SD_XX_PICKLIST_NUM,
			    i.IM_REPORTING_PRICE,
			    i.IM_NOMINAL_VALUE,
			    t.ST_PSLIP,
			    t.ST_DESP_DATE,
			    d.SD_QTY_ORDER,
			    d.SD_QTY_UNIT,
			    d.SD_STOCK,
			    d.SD_DESC,
			    d.SD_LINE,
			    d.SD_EXCL,
			    d.SD_INCL,
			    d.SD_SELL_PRICE,
			    d.SD_XX_OW_UNIT_PRICE,
			    d.SD_QTY_ORDER,
			    d.SD_QTY_ORDER,
			    s.SH_ADDRESS,
			    s.SH_SUBURB,
			    s.SH_CITY,
			    s.SH_STATE,
			    s.SH_POST_CODE,
			    s.SH_NOTE_1,
			    s.SH_NOTE_2,
			    t.ST_WEIGHT,
			    t.ST_PACKAGES,
			    s.SH_SPARE_DBL_9,
			    r.RM_GROUP_CUST,
			    r.RM_PARENT,
			    s.SH_SPARE_STR_5,
			    s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,
			    d.SD_SELL_PRICE,
			    i.IM_OWNED_BY,
			    d.SD_QTY_DESP,
          n.NI_SELL_VALUE,
          n.NI_NX_QUANTITY,
                i.IM_BRAND,l.SL_PSLIP_QTY

	  --HAVING    Sum(s.SH_ORDER) <> 1

  /*Stocks*/

  /*Stocks*/ --113 secs

	  SELECT    s.SH_CUST                AS "Customer",
			    r.RM_PARENT              AS "Parent",
	    CASE    WHEN i.IM_CUST <> 'TABCORP' THEN s.SH_SPARE_STR_4
			    WHEN i.IM_CUST = 'TABCORP' THEN i.IM_XX_COST_CENTRE01
			    ELSE i.IM_XX_COST_CENTRE01
			    END                      AS "CostCentre",
			    s.SH_ORDER               AS "Order",
			    s.SH_SPARE_STR_5         AS "OrderwareNum",
			    s.SH_CUST_REF            AS "CustomerRef",
			    t.ST_PICK                AS "Pickslip",
			    d.SD_XX_PICKLIST_NUM     AS "PickNum",
			    t.ST_PSLIP               AS "DespatchNote",
			    --NULL AS "DespatchDate",
			    substr(To_Char(t.ST_DESP_DATE),0,10)            AS "DespatchDate",
	    CASE    WHEN d.SD_STOCK IS NOT NULL THEN 'Stock'
			    ELSE NULL
			    END                      AS "FeeType",
			    d.SD_STOCK               AS "Item",
			    d.SD_DESC                AS "Description",
			    l.SL_PSLIP_QTY           AS "DespQty",
			    d.SD_QTY_UNIT            AS "UOI",
			   
	    CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN d.SD_SELL_PRICE --company owned
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1 AND n.NI_NX_QUANTITY > 0 THEN n.NI_SELL_VALUE/n.NI_NX_QUANTITY
              WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NOT NULL THEN  (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			        ELSE NULL
			        END                        AS "Batch/UnitPrice",

		 
	    CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN To_Number(i.IM_REPORTING_PRICE)
			    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN  (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
			    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT vUnitPrice FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			    ELSE NULL
			    END                        AS "OWUnitPrice",
        CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN d.SD_SELL_PRICE * d.SD_QTY_DESP--customer owned
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1 AND n.NI_NX_QUANTITY > 0 THEN (n.NI_SELL_VALUE/n.NI_NX_QUANTITY) * d.SD_QTY_DESP
              WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NOT NULL THEN  (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) * d.SD_QTY_DESP
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE * d.SD_QTY_DESP
			        ELSE NULL
			        END          AS "DExcl",

	    CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN To_Number(i.IM_REPORTING_PRICE)
			    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN  (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
			    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			    ELSE NULL
			    END                       AS "Excl_Total",
	    CASE     WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN (d.SD_SELL_PRICE * d.SD_QTY_DESP) * 1.1--customer owned
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1  AND n.NI_NX_QUANTITY > 0 THEN  ((n.NI_SELL_VALUE/n.NI_NX_QUANTITY) * d.SD_QTY_DESP) * 1.1
              WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NOT NULL THEN  ((SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) * d.SD_QTY_DESP) * 1.1
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  (d.SD_XX_OW_UNIT_PRICE * d.SD_QTY_DESP) * 1.1
			        ELSE NULL
			        END          AS "DIncl",
	    CASE   WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 0 THEN (d.SD_SELL_PRICE * d.SD_QTY_DESP) * 1.1--customer owned
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' AND i.IM_OWNED_BY = 1 AND n.NI_NX_QUANTITY > 0 THEN  ((n.NI_SELL_VALUE/n.NI_NX_QUANTITY) * d.SD_QTY_DESP) * 1.1
              WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NOT NULL THEN  ((SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) * d.SD_QTY_DESP) * 1.1
			        WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  (d.SD_XX_OW_UNIT_PRICE * d.SD_QTY_DESP) * 1.1
			        ELSE NULL
			        END          AS "Incl_Total",
	    CASE    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST <> 'TABCORP' THEN To_Number(i.IM_REPORTING_PRICE)
			    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' THEN  (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST)
			    WHEN d.SD_STOCK IS NOT NULL AND i.IM_CUST = 'TABCORP' AND (SELECT To_Number(vUnitPrice) FROM Tmp_Admin_Data_BreakPrices WHERE vIIStock = d.SD_STOCK AND vIICust = r.RM_GROUP_CUST) IS NULL THEN  d.SD_XX_OW_UNIT_PRICE
			    ELSE NULL
			    END                      AS "ReportingPrice",
			    s.SH_ADDRESS             AS "Address",
			    s.SH_SUBURB              AS "Address2",
			    s.SH_CITY                AS "Suburb",
			    s.SH_STATE               AS "State",
			    s.SH_POST_CODE           AS "Postcode",
			    s.SH_NOTE_1              AS "DeliverTo",
			    s.SH_NOTE_2              AS "AttentionTo" ,
			    t.ST_WEIGHT              AS "Weight",
			    t.ST_PACKAGES            AS "Packages",
			    s.SH_SPARE_DBL_9         AS "OrderSource",
			    NULL AS "Pallet/Shelf Space", /*Pallet/Space*/
				  NULL AS "Locn", /*Locn*/
				  0 AS "AvailSOH",/*Avail SOH*/
				  0 AS "CountOfStocks",
          CASE  WHEN regexp_substr(s.SH_SPARE_STR_3,'[a-z]+', 1, 2) IS NOT NULL THEN  s.SH_SPARE_STR_3 || '@' || s.SH_SPARE_STR_1
			          ELSE ''
			          END AS Email,
                i.IM_BRAND AS Brand

	 
     FROM      PWIN175.SH s
			    LEFT JOIN PWIN175.ST t  ON t.ST_ORDER  = s.SH_ORDER
          LEFT JOIN PWIN175.SL l  ON l.SL_PICK   = t.ST_PICK
          LEFT JOIN PWIN175.SD d  ON d.SD_ORDER  = s.SH_ORDER  
			    INNER JOIN PWIN175.RM r  ON r.RM_CUST  = s.SH_CUST
			    INNER JOIN PWIN175.IM i  ON i.IM_STOCK = d.SD_STOCK
          INNER JOIN PWIN175.NI n  ON n.NI_NV_EXT_KEY = l.SL_UID
          
          
   WHERE NI_NV_EXT_TYPE = 1810105 AND NI_STRENGTH = 3 AND NI_DATE = t.ST_DESP_DATE AND NI_STOCK = d.SD_STOCK AND NI_STATUS <> 0
	  AND     s.SH_STATUS <> 3
    AND       s.SH_ORDER = t.ST_ORDER
	  AND       d.SD_STOCK NOT LIKE 'COURIER'
	  AND       d.SD_STOCK NOT LIKE 'FEE*'
	  AND       t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
	  AND       d.SD_LAST_PICK_NUM = t.ST_PICK
    AND     i.IM_CUST IN (SELECT RM_CUST FROM RM WHERE RM_ANAL = :anal)
	  GROUP BY  s.SH_CUST,

			    s.SH_NOTE_1,
			    s.SH_CAMPAIGN,
			    s.SH_SPARE_STR_4,
			    i.IM_XX_COST_CENTRE01,
			    i.IM_CUST,
			    r.RM_PARENT,
			    s.SH_ORDER,
			    t.ST_PICK,
			    d.SD_XX_PICKLIST_NUM,
			    i.IM_REPORTING_PRICE,
			    i.IM_NOMINAL_VALUE,
			    t.ST_PSLIP,
			    t.ST_DESP_DATE,
			    d.SD_QTY_ORDER,
			    d.SD_QTY_UNIT,
			    d.SD_STOCK,
			    d.SD_DESC,
			    d.SD_LINE,
			    d.SD_EXCL,
			    d.SD_INCL,
			    d.SD_SELL_PRICE,
			    d.SD_XX_OW_UNIT_PRICE,
			    d.SD_QTY_ORDER,
			    d.SD_QTY_ORDER,
			    s.SH_ADDRESS,
			    s.SH_SUBURB,
			    s.SH_CITY,
			    s.SH_STATE,
			    s.SH_POST_CODE,
			    s.SH_NOTE_1,
			    s.SH_NOTE_2,
			    t.ST_WEIGHT,
			    t.ST_PACKAGES,
			    s.SH_SPARE_DBL_9,
			    r.RM_GROUP_CUST,
			    r.RM_PARENT,
			    s.SH_SPARE_STR_5,
			    s.SH_CUST_REF,s.SH_SPARE_STR_3,s.SH_SPARE_STR_1,
			    d.SD_SELL_PRICE,
			    i.IM_OWNED_BY,
			    d.SD_QTY_DESP,
          n.NI_SELL_VALUE,
          n.NI_NX_QUANTITY,
                i.IM_BRAND,l.SL_PSLIP_QTY


  --DROP TABLE Tmp_Admin_Data2

  /*SELECT * FROM tbl_AdminData
  ORDER BY OrderNum,Pickslip Asc  */