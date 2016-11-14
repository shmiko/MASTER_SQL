SELECT Ord.SO_ID SalesOrder, 
ISNULL(Cust.[DATAFLEX RECNUM ONE],'') Customer,
ISNULL(Cust.[AC NO],'') CustomerName,
ISNULL(Ord.CUST_SO_ID,'') CustomerOrderID, 
ISNULL(Ord.[EXTERNAL_CMT],'') ExtRef,
ISNULL(OrderBy.CUST_RECIP_ID,'') OrderByCustomerRecipientID, 
ISNULL(OrderBy.FIRST_NAME,'') + ' ' + ISNULL(OrderBy.LAST_NAME,'') OrderByName, 
ISNULL(OrderBy.COMPANY_NAME,'') OrderByCompanyName, 
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
INNER JOIN RECIPIENT ShipTo On ShipTo.RECIP_ID = Ord.SHIP_TO_ID 
INNER JOIN FFADDRESS ShipToAddress on ShipToAddress.ADDRESS_ID = ShipTo.DEF_ADDRESS_ID 
INNER JOIN COUNTRY ShipToCountry on ShipToCountry.COUNTRY_ID = ShipToAddress.COUNTRY_ID 
INNER JOIN RECIPIENT BillTo On BillTo.RECIP_ID = Ord.BILL_TO_ID 
INNER JOIN FFADDRESS BillToAddress on BillToAddress.ADDRESS_ID = BillTo.DEF_ADDRESS_ID 
INNER JOIN COUNTRY BillToCountry on BillToCountry.COUNTRY_ID = BillToAddress.COUNTRY_ID 
INNER JOIN SO_LINE_ITEM Sol ON Ord.SO_ID = SOl.SO_ID 
INNER JOIN DEBTOR Cust ON Cust.[DATAFLEX RECNUM ONE] = Ord.CUST_ID
INNER JOIN FFPROJECT proj ON Ord.PROJ_ID = proj.PROJ_ID 
WHERE --proj.PROJ_NAME = 'Fulfillment' 
--AND 
Ord.SO_ID = 354
ORDER BY Ord.CREATED_DATE Desc