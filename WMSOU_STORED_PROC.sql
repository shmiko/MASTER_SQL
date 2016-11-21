USE [bsg_support]
GO
/****** Object:  StoredProcedure [dbo].[WMS2JAV_SOU]    Script Date: 21/11/2016 3:45:58 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[WMS2JAV_SOU](@Customer VARCHAR(8),@EditDate DATETIME) 
AS BEGIN
SET NOCOUNT ON;
SELECT 
--'SOH' SOH,
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
--Need a procedure to check all lines for status' that may ultimateley affect the ehader status, such as awaiting which the WMS doesn't recognise
CASE WHEN stath.[STATUS_DESC] in ('Sales Order Created','Sales Order Open') then 'Live'
	 WHEN stath.[STATUS_DESC] = 'Sales Order Complete' then 'Despatched'
	 WHEN stath.[STATUS_DESC] = 'Sales Order Cancel' then 'Cancelled'
	 WHEN stath.[STATUS_DESC] = 'Sales Order Line Item Shipped' then 'Closed'
	 WHEN stath.[STATUS_DESC] = 'Sales Order Line Item Released and Pick Confirmed' then 'Awaiting'
	 ELSE ''
END AS  OrderStatus,
--cast(Ord.CREATED_DATE as time) OrderTime, 
ISNULL(Sol.INVENTORY_CODE,'') InventoryCode, 
ISNULL(Sku.[PO UOM DESC],'') UOM,
ISNULL(Sol.[REVISION_CODE],'') ID,
ISNULL(Sol.[GROSS_QTY],0) OrdQty,
ISNULL(Sol.BO_QTY,0) BOQty, 
null InvQty,
CASE WHEN statl.[STATUS_DESC] in ('Sales Order Line Item Committed','Sales Order Line Item Released','Sales Order Line Item Released Pending Pick Confirmation','','Confirmed for Pick Order') then 'Live'
	 WHEN statl.[STATUS_DESC] = 'Sales Order Line Item Shipped' then 'Despatched'
	 WHEN statl.[STATUS_DESC] = 'Sales Order Line Item Cancelled' then 'Cancelled'
	 WHEN statl.[STATUS_DESC] = 'SOE_CLOSED' then 'Closed'
	 WHEN statl.[STATUS_DESC] = 'Sales Order Line Item Released and Pick Confirmed' then 'Awaiting'
	 ELSE ''
END AS LineStatus
FROM LiveData.dbo.SALES_ORDER Ord with (nolock) 
INNER JOIN LiveData.dbo.BATCH Inp with (nolock) ON Ord.BATCH_ID = Inp.BATCH_ID 
left outer join  LiveData.dbo.RECIPIENT OrderBy with (nolock) On OrderBy.RECIP_ID = Ord.ORDER_BY_ID 
left outer join LiveData.dbo.RECIPIENT ShipTo with (nolock) On ShipTo.RECIP_ID = Ord.SHIP_TO_ID 
INNER JOIN LiveData.dbo.FFADDRESS ShipToAddress with (nolock) on ShipToAddress.ADDRESS_ID = ShipTo.DEF_ADDRESS_ID 
INNER JOIN LiveData.dbo.COUNTRY ShipToCountry with (nolock) on ShipToCountry.COUNTRY_ID = ShipToAddress.COUNTRY_ID 
INNER JOIN LiveData.dbo.SO_LINE_ITEM Sol with (nolock) ON Ord.SO_ID = SOl.SO_ID 
left outer join LiveData.dbo.DEBTOR Cust with (nolock)  ON Cust.[DATAFLEX RECNUM ONE] = Ord.CUST_ID
INNER JOIN LiveData.dbo.PAPSIZE Sku with (nolock) ON Sku.[INVENTORY CODE] = Sol.INVENTORY_CODE
left outer join LiveData.dbo.FFSTATUS statl on statl.STATUS_ID = sol.STATUS_ID 
left outer join LiveData.dbo.FFSTATUS stath on stath.STATUS_ID = Ord.STATUS_ID 
WHERE Ord.[MODIFIED_DATE] = @EditDate
AND Cust.[AC NO] = @Customer

ORDER BY cast(Ord.[MODIFIED_DATE] as Date) Desc
END