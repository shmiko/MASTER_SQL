USE LiveData
SELECT Ord.SO_ID HeaderLink, 
ISNULL(Ord.CUST_SO_ID,'') CustomerOrderID, 
ISNULL(Inp.CUST_BATCH_ID ,'') CustomerBatchID, 
ISNULL(OrderBy.CUST_RECIP_ID,'') OrderByCustomerRecipientID, 
ISNULL(OrderBy.FIRST_NAME,'') OrderByFirstName, 
ISNULL(OrderBy.MIDDLE_NAME,'') OrderByMiddleName, 
ISNULL(OrderBy.LAST_NAME,'') OrderByLastName, 
ISNULL(OrderBy.COMPANY_NAME,'') OrderByCompanyName, 
ISNULL(OrderByCorpStruct1.CS_NAME,'') OrderbyCorpStruct1Name, 
ISNULL(OrderByCorpStruct2.CS_NAME,'') OrderbyCorpStruct2Name, 
ISNULL(OrderByCorpStruct3.CS_NAME,'') OrderbyCorpStruct3Name, 
ISNULL(OrderByCorpStruct4.CS_NAME,'') OrderbyCorpStruct4Name, 
ISNULL(OrderByCorpLevel1.CL_NAME,'') OrderbyCorpLevel1Name, 
ISNULL(OrderByCorpLevel2.CL_NAME,'') OrderbyCorpLevel2Name, 
ISNULL(OrderByCorpLevel4.CL_NAME,'') OrderbyCorpLevel3Name, 
ISNULL(OrderByCorpLevel4.CL_NAME,'') OrderbyCorpLevel4Name, 
ISNULL(OrderByAddress.ADDR_1,'') OrderByAddress1, 
ISNULL(OrderByAddress.ADDR_2,'') OrderByAddress1, 
ISNULL(OrderByAddress.ADDR_3,'') OrderByAddress1, 
ISNULL(OrderByAddress.CITY,'') OrderByCity, 
ISNULL(OrderByAddress.STATE_CODE,'') OrderByStateCode, 
ISNULL(OrderByAddress.ZIP_CODE,'') OrderByZipCode, 
ISNULL(OrderByAddress.CountyName,'') OrderByCountyName, 
ISNULL(OrderByCountry.COUNTRY_CODE3,'') OrderByCountry, 
ISNULL(ShipTo.CUST_RECIP_ID,'') ShipToCustomerRecipientID, 
ISNULL(ShipTo.FIRST_NAME,'') ShipToFirstName,
ISNULL(ShipTo.MIDDLE_NAME,'') ShipToMiddleName, 
ISNULL(ShipTo.LAST_NAME,'') ShipToLastName, 
ISNULL(ShipTo.COMPANY_NAME,'') ShipToCompanyName, 
ISNULL(ShipToCorpStruct1.CS_NAME,'') ShipToCorpStruct1Name, 
ISNULL(ShipToCorpStruct2.CS_NAME,'') ShipToCorpStruct2Name, 
ISNULL(ShipToCorpStruct3.CS_NAME,'') ShipToCorpStruct3Name, 
ISNULL(ShipToCorpStruct4.CS_NAME,'') ShipToCorpStruct4Name, 
ISNULL(ShipToCorpLevel1.CL_NAME,'') ShipToCorpLevel1Name, 
ISNULL(ShipToCorpLevel2.CL_NAME,'') ShipToCorpLevel2Name, 
ISNULL(ShipToCorpLevel4.CL_NAME,'') ShipToCorpLevel3Name, 
ISNULL(ShipToCorpLevel4.CL_NAME,'') ShipToCorpLevel4Name, 
ISNULL(ShipToAddress.ADDR_1,'') ShipToAddress1, 
ISNULL(ShipToAddress.ADDR_2,'') ShipToAddress1, 
ISNULL(ShipToAddress.ADDR_3,'') ShipToAddress1, 
ISNULL(ShipToAddress.CITY,'') ShipToCity, 
ISNULL(ShipToAddress.STATE_CODE,'') ShipToStateCode, 
ISNULL(ShipToAddress.ZIP_CODE,'') ShipToZipCode, 
ISNULL(ShipToAddress.CountyName,'') ShipToCountyName, 
ISNULL(ShipToCountry.COUNTRY_CODE3,'') ShipToCountry, 
ISNULL(BillTo.CUST_RECIP_ID,'') BillToCustomerRecipientID, 
ISNULL(BillTo.FIRST_NAME,'') BillToFirstName, 
ISNULL(BillTo.MIDDLE_NAME,'') BillToMiddleName, 
ISNULL(BillTo.LAST_NAME,'') BillToLastName, 
ISNULL(BillTo.COMPANY_NAME,'') BillToCompanyName, 
ISNULL(BillToCorpStruct1.CS_NAME,'') BillToCorpStruct1Name, 
ISNULL(BillToCorpStruct2.CS_NAME,'') BillToCorpStruct2Name, 
ISNULL(BillToCorpStruct3.CS_NAME,'') BillToCorpStruct3Name, 
ISNULL(BillToCorpStruct4.CS_NAME,'') BillToCorpStruct4Name, 
ISNULL(BillToCorpLevel1.CL_NAME,'') BillToCorpLevel1Name, 
ISNULL(BillToCorpLevel2.CL_NAME,'') BillToCorpLevel2Name, 
ISNULL(BillToCorpLevel4.CL_NAME,'') BillToCorpLevel3Name, 
ISNULL(BillToCorpLevel4.CL_NAME,'') BillToCorpLevel4Name, 
ISNULL(BillToAddress.ADDR_1,'') BillToAddress1, 
ISNULL(BillToAddress.ADDR_2,'') BillToAddress1, 
ISNULL(BillToAddress.ADDR_3,'') BillToAddress1, 
ISNULL(BillToAddress.CITY,'') BillToCity, 
ISNULL(BillToAddress.STATE_CODE,'') BillToStateCode, 
ISNULL(BillToAddress.ZIP_CODE,'') BillToZipCode,
ISNULL(BillToAddress.CountyName,'') BillToCountyName, 
ISNULL(BillToCountry.COUNTRY_CODE3,'') BillToCountry, 
proj.proj_name, 
Ord.SO_ID DetailLink, 
Sol.INVENTORY_CODE InventoryCode, 
SOl.ORDER_QTY + ISNULL(Sol.BO_QTY,0) OrderQty 
FROM SALES_ORDER Ord 
INNER JOIN BATCH Inp ON Ord.BATCH_ID = Inp.BATCH_ID 
INNER JOIN RECIPIENT OrderBy On OrderBy.RECIP_ID = Ord.ORDER_BY_ID 
INNER JOIN FFADDRESS OrderByAddress on OrderByAddress.ADDRESS_ID = Orderby.DEF_ADDRESS_ID 
INNER JOIN COUNTRY OrderByCountry on OrderByCountry.COUNTRY_ID = OrderByAddress.COUNTRY_ID 
LEFT OUTER JOIN ( SELECT CS_ID, CS_NAME FROM CORP_STRUCT WHERE CS_LEVEL = 1 ) AS OrderByCorpStruct1 ON OrderBy.CORP_STRUCT_1 = OrderByCorpStruct1.CS_ID 
LEFT OUTER JOIN ( SELECT CS_ID, CS_NAME FROM CORP_STRUCT WHERE CS_LEVEL = 2 ) AS OrderByCorpStruct2 ON OrderBy.CORP_STRUCT_2 = OrderByCorpStruct2.CS_ID 
LEFT OUTER JOIN ( SELECT CS_ID, CS_NAME FROM CORP_STRUCT WHERE CS_LEVEL = 3 ) AS OrderByCorpStruct3 ON OrderBy.CORP_STRUCT_3 = OrderByCorpStruct3.CS_ID 
LEFT OUTER JOIN ( SELECT CS_ID, CS_NAME FROM CORP_STRUCT WHERE CS_LEVEL = 4 ) AS OrderByCorpStruct4 ON OrderBy.CORP_STRUCT_4 = OrderByCorpStruct4.CS_ID 
LEFT OUTER JOIN ( SELECT CL_ID, CL_NAME FROM CORP_LEVEL WHERE CL_LEVEL = 1 ) AS OrderByCorpLevel1 ON OrderBy.CORP_LEVEL_1 = OrderByCorpLevel1.CL_ID 
LEFT OUTER JOIN ( SELECT CL_ID, CL_NAME FROM CORP_LEVEL WHERE CL_LEVEL = 2 ) AS OrderByCorpLevel2 ON OrderBy.CORP_LEVEL_2 = OrderByCorpLevel2.CL_ID 
LEFT OUTER JOIN ( SELECT CL_ID, CL_NAME FROM CORP_LEVEL WHERE CL_LEVEL = 3 ) AS OrderByCorpLevel3 ON OrderBy.CORP_LEVEL_3 = OrderByCorpLevel3.CL_ID 
LEFT OUTER JOIN ( SELECT CL_ID, CL_NAME FROM CORP_LEVEL WHERE CL_LEVEL = 4 ) AS OrderByCorpLevel4 ON OrderBy.CORP_LEVEL_4 = OrderByCorpLevel4.CL_ID 
INNER JOIN RECIPIENT ShipTo On ShipTo.RECIP_ID = Ord.SHIP_TO_ID 
INNER JOIN FFADDRESS ShipToAddress on ShipToAddress.ADDRESS_ID = ShipTo.DEF_ADDRESS_ID 
INNER JOIN COUNTRY ShipToCountry on ShipToCountry.COUNTRY_ID = ShipToAddress.COUNTRY_ID 
LEFT OUTER JOIN ( SELECT CS_ID, CS_NAME FROM CORP_STRUCT WHERE CS_LEVEL = 1 ) AS ShipToCorpStruct1 ON ShipTo.CORP_STRUCT_1 = ShipToCorpStruct1.CS_ID 
LEFT OUTER JOIN ( SELECT CS_ID, CS_NAME FROM CORP_STRUCT WHERE CS_LEVEL = 2 ) AS ShipToCorpStruct2 ON ShipTo.CORP_STRUCT_2 = ShipToCorpStruct2.CS_ID 
LEFT OUTER JOIN ( SELECT CS_ID, CS_NAME FROM CORP_STRUCT WHERE CS_LEVEL = 3 ) AS ShipToCorpStruct3 ON ShipTo.CORP_STRUCT_3 = ShipToCorpStruct3.CS_ID 
LEFT OUTER JOIN ( SELECT CS_ID, CS_NAME FROM CORP_STRUCT WHERE CS_LEVEL = 4 ) AS ShipToCorpStruct4 ON ShipTo.CORP_STRUCT_4 = ShipToCorpStruct4.CS_ID 
LEFT OUTER JOIN ( SELECT CL_ID, CL_NAME FROM CORP_LEVEL WHERE CL_LEVEL = 1 ) AS ShipToCorpLevel1 ON ShipTo.CORP_LEVEL_1 = ShipToCorpLevel1.CL_ID 
LEFT OUTER JOIN ( SELECT CL_ID, CL_NAME FROM CORP_LEVEL WHERE CL_LEVEL = 2 ) AS ShipToCorpLevel2 ON ShipTo.CORP_LEVEL_2 = ShipToCorpLevel2.CL_ID 
LEFT OUTER JOIN ( SELECT CL_ID, CL_NAME FROM CORP_LEVEL WHERE CL_LEVEL = 3 ) AS ShipToCorpLevel3 ON ShipTo.CORP_LEVEL_3 = ShipToCorpLevel3.CL_ID 
LEFT OUTER JOIN ( SELECT CL_ID, CL_NAME FROM CORP_LEVEL WHERE CL_LEVEL = 4 ) AS ShipToCorpLevel4 ON ShipTo.CORP_LEVEL_4 = ShipToCorpLevel4.CL_ID 

INNER JOIN RECIPIENT BillTo On BillTo.RECIP_ID = Ord.BILL_TO_ID 
INNER JOIN FFADDRESS BillToAddress on BillToAddress.ADDRESS_ID = BillTo.DEF_ADDRESS_ID 
INNER JOIN COUNTRY BillToCountry on BillToCountry.COUNTRY_ID = BillToAddress.COUNTRY_ID 
LEFT OUTER JOIN ( SELECT CS_ID, CS_NAME FROM CORP_STRUCT WHERE CS_LEVEL = 1 ) AS BillToCorpStruct1 ON BillTo.CORP_STRUCT_1 = BillToCorpStruct1.CS_ID 
LEFT OUTER JOIN ( SELECT CS_ID, CS_NAME FROM CORP_STRUCT WHERE CS_LEVEL = 2 ) AS BillToCorpStruct2 ON BillTo.CORP_STRUCT_2 = BillToCorpStruct2.CS_ID 
LEFT OUTER JOIN ( SELECT CS_ID, CS_NAME FROM CORP_STRUCT WHERE CS_LEVEL = 3 ) AS BillToCorpStruct3 ON BillTo.CORP_STRUCT_3 = BillToCorpStruct3.CS_ID 
LEFT OUTER JOIN ( SELECT CS_ID, CS_NAME FROM CORP_STRUCT WHERE CS_LEVEL = 4 ) AS BillToCorpStruct4 ON BillTo.CORP_STRUCT_4 = BillToCorpStruct4.CS_ID 
LEFT OUTER JOIN ( SELECT CL_ID, CL_NAME FROM CORP_LEVEL WHERE CL_LEVEL = 1 ) AS BillToCorpLevel1 ON BillTo.CORP_LEVEL_1 = BillToCorpLevel1.CL_ID 
LEFT OUTER JOIN ( SELECT CL_ID, CL_NAME FROM CORP_LEVEL WHERE CL_LEVEL = 2 ) AS BillToCorpLevel2 ON BillTo.CORP_LEVEL_2 = BillToCorpLevel2.CL_ID 
LEFT OUTER JOIN ( SELECT CL_ID, CL_NAME FROM CORP_LEVEL WHERE CL_LEVEL = 3 ) AS BillToCorpLevel3 ON BillTo.CORP_LEVEL_3 = BillToCorpLevel3.CL_ID 
LEFT OUTER JOIN ( SELECT CL_ID, CL_NAME FROM CORP_LEVEL WHERE CL_LEVEL = 4 ) AS BillToCorpLevel4 ON BillTo.CORP_LEVEL_4 = BillToCorpLevel4.CL_ID 
INNER JOIN SO_LINE_ITEM Sol ON Ord.SO_ID = SOl.SO_ID 
INNER JOIN FFPROJECT proj ON Ord.PROJ_ID = proj.PROJ_ID 
WHERE Ord.SO_ID = 2227 
