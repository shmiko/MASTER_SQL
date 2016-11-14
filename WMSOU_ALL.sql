SELECT 
'SOH' SOH,
Ord.SO_ID SalesOrder,
ISNULL(Cust.[DATAFLEX RECNUM ONE],'') Customer,
ISNULL(Cust.[AC NO],'') CustomerName,
ISNULL(Ord.CUST_SO_ID,'') CustomerOrderID, 
ISNULL(Ord.[EXTERNAL_CMT],'') ExtRef,
ISNULL(OrderBy.CUST_RECIP_ID,'') OrderByCustomerRecipientID, 
ISNULL(OrderBy.FIRST_NAME,'') + ' ' + ISNULL(OrderBy.LAST_NAME,'') ForAttention, 
ISNULL(OrderBy.COMPANY_NAME,'') DeliverTo, 
ISNULL(ShipTo.FIRST_NAME,'') + ' ' + ISNULL(ShipTo.LAST_NAME,'') ShipToName, 
ISNULL(ShipTo.COMPANY_NAME,'') ShipToCompanyName, 
ISNULL(ShipToAddress.ADDR_1,'') ShipToAddress1, 
ISNULL(ShipToAddress.ADDR_2,'') ShipToAddress1, 
ISNULL(ShipToAddress.ADDR_3,'') ShipToAddress1, 
ISNULL(ShipToAddress.CITY,'') ShipToCity, 
ISNULL(ShipToAddress.STATE_CODE,'') ShipToStateCode, 
--ISNULL(ShipToAddress.CountyName,'') ShipToCountyName, 
ISNULL(ShipToCountry.COUNTRY_CODE3,'') ShipToCountry,
ISNULL(ShipToAddress.ZIP_CODE,'') ShipToZipCode, 
'' Rep,
Ord.[NEED_DATE] ReqDate,
cast(Ord.CREATED_DATE as Date) OrderDate, 
CAST(Ord.CREATED_DATE AS TIME(0)) OrderTime,
Ord.[CREATED_BY] AddedBy,
Ord.[STATUS_ID] Status,
'' InventoryCode,
'' UOM,
'' ID,
'' OrdQty,
'' BOQty 
'' InvQty,
Ord.[STATUS_ID] Status,
FROM SALES_ORDER Ord 
INNER JOIN BATCH Inp ON Ord.BATCH_ID = Inp.BATCH_ID 
INNER JOIN RECIPIENT OrderBy On OrderBy.RECIP_ID = Ord.ORDER_BY_ID 
INNER JOIN RECIPIENT ShipTo On ShipTo.RECIP_ID = Ord.SHIP_TO_ID 
INNER JOIN FFADDRESS ShipToAddress on ShipToAddress.ADDRESS_ID = ShipTo.DEF_ADDRESS_ID 
INNER JOIN COUNTRY ShipToCountry on ShipToCountry.COUNTRY_ID = ShipToAddress.COUNTRY_ID 
INNER JOIN SO_LINE_ITEM Sol ON Ord.SO_ID = SOl.SO_ID 
INNER JOIN DEBTOR Cust ON Cust.[DATAFLEX RECNUM ONE] = Ord.CUST_ID
INNER JOIN PAPSIZE Sku ON Sku.[INVENTORY CODE] = Sol.INVENTORY_CODE
--ORDER BY Ord.CREATED_DATE Desc

UNION 

SELECT 
'SOL' SOL,
Sol.[LINE_ITEM_NO] SalesOrderLine,
'' Customer,
''  CustomerName,
''  CustomerOrderID, 
''  ExtRef,
''  OrderByCustomerRecipientID, 
''  OrderByName, 
''  OrderByCompanyName, 
''  ShipToName, 
''  ShipToCompanyName, 
''  ShipToAddress1, 
''  ShipToAddress1, 
''  ShipToAddress1, 
''  ShipToCity, 
''  ShipToStateCode, 
--''  ShipToCountyName, 
''  ShipToCountry,
''  ShipToZipCode, 
'' Rep,
Ord.[NEED_DATE] ReqDate,
cast(Ord.CREATED_DATE as Date) OrderDate, 
CAST(Ord.CREATED_DATE AS TIME(0)) OrderTime,
Ord.[CREATED_BY] AddedBy,
Ord.[STATUS_ID] Status,
--cast(Ord.CREATED_DATE as time) OrderTime, 
ISNULL(Sol.INVENTORY_CODE,'') InventoryCode, 
ISNULL(Sku.[PO UOM DESC],'') UOM,
ISNULL(Sol.[REVISION_CODE],'') ID,
ISNULL(Sol.ORDER_QTY,0) OrdQty,
ISNULL(Sol.BO_QTY,0) BOQty 
'' InvQty,
Sol.[STATUS_ID] Status,
FROM SALES_ORDER Ord 
INNER JOIN BATCH Inp ON Ord.BATCH_ID = Inp.BATCH_ID 
INNER JOIN RECIPIENT OrderBy On OrderBy.RECIP_ID = Ord.ORDER_BY_ID 
INNER JOIN RECIPIENT ShipTo On ShipTo.RECIP_ID = Ord.SHIP_TO_ID 
INNER JOIN FFADDRESS ShipToAddress on ShipToAddress.ADDRESS_ID = ShipTo.DEF_ADDRESS_ID 
INNER JOIN COUNTRY ShipToCountry on ShipToCountry.COUNTRY_ID = ShipToAddress.COUNTRY_ID 
INNER JOIN SO_LINE_ITEM Sol ON Ord.SO_ID = SOl.SO_ID 
INNER JOIN DEBTOR Cust ON Cust.[DATAFLEX RECNUM ONE] = Ord.CUST_ID
INNER JOIN PAPSIZE Sku ON Sku.[INVENTORY CODE] = Sol.INVENTORY_CODE

ORDER BY cast(Ord.CREATED_DATE as Date) Desc