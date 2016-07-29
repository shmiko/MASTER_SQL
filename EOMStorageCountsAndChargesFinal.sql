var cust varchar2(20)
exec :cust := 'TABCORP'
var ordernum varchar2(20)
exec :ordernum := '1363806'
var stock varchar2(20)
exec :stock := 'COURIER'
var source varchar2(20)
exec :source := 'BSPRINTNSW'
var anal varchar2(20)
exec :anal := '49'
var start_date varchar2(20)
exec :start_date := To_Date('7-Aug-2013')
var end_date varchar2(20)
exec :end_date := To_Date('7-Aug-2013')



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


SELECT * FROM RD,RM WHERE RM_CUST = RD_CUST AND RM_PARENT IN ('FRESER','GREFRE')

DROP TABLE  Tmp_Locn_Cnt_By_Cust

CREATE TABLE Tmp_Locn_Cnt_By_Cust ( nCountOfStocks NUMBER, sLocn VARCHAR2(10))

INSERT INTO Tmp_Locn_Cnt_By_Cust (

SELECT Count(DISTINCT NI_STOCK) AS CountOfStocks, IL_LOCN
			FROM IL INNER JOIN NI  ON IL_LOCN = NI_LOCN
			INNER JOIN IM ON IM_STOCK = NI_STOCK
			WHERE IM_CUST = :cust   AND IM_ACTIVE = 1
			AND NI_AVAIL_ACTUAL >= '1'
			AND NI_STATUS <> 0
      GROUP BY IL_LOCN    )

SELECT * FROM Tmp_Locn_Cnt_By_Cust




/* EOM Storage Fees */
	select IM_CUST AS "Customer",
	  IM_CUST AS "Parent",
	  IM_XX_COST_CENTRE01     AS "CostCentre",
	  NULL               AS "Order",
	  NULL               AS "OrderwareNum",
	  NULL               AS "CustomerRef",
	  NULL                AS "Pickslip",
	  NULL                AS "PickNum",
	  NULL               AS "DespatchNote",
	  (select SubStr(To_Char(last_day(SYSDATE)),0,10) from dual) AS "DespatchDate", /*Made Date*/
		CASE /*Fee Type*/
			WHEN (l1.IL_NOTE_2 like 'Yes'
				OR l1.IL_NOTE_2 LIKE 'YES'
				OR l1.IL_NOTE_2 LIKE 'yes')
			THEN 'FEEPALLETS'
			ELSE 'FEESHELFS'
			END AS "FeeType",
		n1.NI_STOCK AS "Item",
		CASE /*explanation of charge*/
			WHEN (l1.IL_NOTE_2 like 'Yes'	OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN 'Pallet Space Utilisation Fee (per month) is split across ' || nCountOfStocks || ' stock(s)'
			ELSE 'Shelf SPace Utilisation Fee (per month) is split across ' ||	nCountOfStocks  || ' stock(s)'
			END AS "Description",
	  IM_LEVEL_UNIT AS "UOI", /*UOI*/
	   CASE   WHEN l1.IL_NOTE_2 IS NOT NULL THEN  1
			  ELSE NULL
			  END                     AS "Qty",
		 CASE  /*unit price*/
			WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN
				(:nRM_XX_FEE11 	/ nCountOfStocks )
			ELSE
				(:nRM_XX_FEE12  / nCountOfStocks )
	    END AS "UnitPrice",
		  CASE WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN
				(:nRM_XX_FEE11 	/ nCountOfStocks )
			ELSE
				(:nRM_XX_FEE12  / nCountOfStocks )
	    END AS "DExcl",
			CASE  /*unit price*/
			WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN
				(:nRM_XX_FEE11 	/ nCountOfStocks )
			ELSE
				(:nRM_XX_FEE12  / nCountOfStocks )
	    END AS "OWUnitPrice",
			CASE  /*unit price*/
			WHEN (l1.IL_NOTE_2 like 'Yes' OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN
				(:nRM_XX_FEE11 	/ nCountOfStocks )
			ELSE
				(:nRM_XX_FEE12  / nCountOfStocks )
	    END AS "Excl_Total",
		 CASE WHEN (l1.IL_NOTE_2 like 'Yes'  OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN
				(:nRM_XX_FEE11 	/ nCountOfStocks )  * 1.1
			ELSE
				(:nRM_XX_FEE12  / nCountOfStocks )  * 1.1
	    END AS "DIncl",
			 CASE WHEN (l1.IL_NOTE_2 like 'Yes'  OR l1.IL_NOTE_2 LIKE 'YES' OR l1.IL_NOTE_2 LIKE 'yes')
			THEN
				(:nRM_XX_FEE11 	/ nCountOfStocks )  * 1.1
			ELSE
				(:nRM_XX_FEE12  / nCountOfStocks )  * 1.1
	    END AS "Incl_Total",
	   CASE    WHEN l1.IL_LOCN IS NOT NULL THEN (Select To_Number(i.IM_REPORTING_PRICE) from IM i where i.IM_STOCK = 'COURIERM')
			  ELSE NULL
			  END                      AS "ReportingPrice",
			  NULL             AS "Address",
			  NULL              AS "Address2",
			  NULL                AS "Suburb",
			  NULL               AS "State",
			  NULL           AS "Postcode",
			  NULL              AS "DeliverTo",
			  NULL              AS "AttentionTo" ,
			  0              AS "Weight",
			  0            AS "Packages",
			  0         AS "OrderSource",
	  l1.IL_NOTE_2 AS "Pallet/Space", /*Pallet/Space*/
		n1.NI_LOCN AS "Locn", /*Locn*/
		n1.NI_AVAIL_ACTUAL AS "Avail SOH",/*Avail SOH*/
		nCountOfStocks AS CountCustStocks
	FROM NI n1 INNER JOIN IM ON IM_STOCK = n1.NI_STOCK
	INNER JOIN IL l1 ON l1.IL_LOCN = n1.NI_LOCN
  INNER JOIN Tmp_Locn_Cnt_By_Cust ON sLocn = l1.IL_LOCN
	WHERE IM_CUST = :cust
		  AND IM_ACTIVE = 1
				--AND IM_CUST = :cust
	AND n1.NI_AVAIL_ACTUAL >= '1'
	AND n1.NI_STATUS <> 0
	GROUP BY IM_CUST,IM_XX_COST_CENTRE01,n1.NI_LOCN,n1.NI_AVAIL_ACTUAL,5,6,n1.NI_STOCK,8,9,10,11,12,l1.IL_NOTE_2,n1.NI_MADE_DATE,IM_LEVEL_UNIT,l1.IL_LOCN,nCountOfStocks


