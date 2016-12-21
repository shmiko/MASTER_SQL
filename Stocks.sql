DECLARE @FromShipDate as date
DECLARE @ToShipDate as date
DECLARE @JavelinNumber as varchar(10)
DECLARE @JavelinLetter as varchar(10)
DECLARE @OWNumber as VARCHAR(10)
SELECT @FromShipDate = '09/01/2016'   
SELECT @ToShipDate = '12/16/2016'			--Note:  Make this +1 days from your last ship date
SET @JavelinLetter = 'W'
--SET @JavelinNumber = @JavelinLetter + '%' -- Note: Use this to get all Javelin Orders
SET @OWNumber = 'W1693170'					-- Note: Use this to get a single javelin Order


/* Stocks */
SELECT 
	Account.[DATAFLEX RECNUM ONE]				as ID,
	Account.[AC NO]								as Customer,
	Ord.BILL_TO_ID								as CustomerId, 
	Ord.CUST_ID									as ParentId, 
	Account.NAMES								as Parent, 
	Sol.COST_CENTER								as CostCentre,
	Ord.SO_ID									as OrderNum, 
	Ord.CUST_SO_ID								as OrderWareNum, 
	Sol.PO_NO									as CustRef, 
	Sol.PICK_ID									as PickSlip,
	OrdShipTo.ShippingComment					as DespNote,
	Trans.TIME_START							as DespDate, 
	'Stock'										as FeeType, 
	Sol.ITEM_NO									as Item, 
	Sol.INVENTORY_CODE							as InventoryCode, 
	Sol.ITEM_DESCRIPTION						as "Description", 
	Sol.PACK_QTY								as Qty,
	SOl.ORDER_QTY + ISNULL(Sol.BO_QTY,0)		as OrderQty,
	Sku.[UNIT OF ISSUE]							as UOI,
	Sku.[UNIT ISSUE DESC]						as UnitOfIssDesc, 
	Prices.UNIT_PRICE							as UnitPrice, 
	((Prices.UNIT_PRICE * Sol.PACK_QTY) 
		+ Prices.SHIPPING_HANDLING)				as SellExcl, 
	((Prices.UNIT_PRICE * Sol.PACK_QTY) 
		+ Prices.SHIPPING_HANDLING 
		+ ISNULL(Prices.SALES_TAX,0))			as SellIncl, 
	ISNULL(OrderBy.CUST_RECIP_ID,'')			as OrderByCustomerRecipientID, 
	--ISNULL(Recipient.CUST_RECIP_ID,'')		as RecipientID, 
	ISNULL(Recipient.COMPANY_NAME,'')			as DeliverTo, 
	ISNULL(RECIPIENT.LAST_NAME,'')				as AttentionTo,
	ISNULL(ShipToAddress.ADDR_1,'') 			as Address1, 
	ISNULL(ShipToAddress.ADDR_2,'') 			as Address3, 
	ISNULL(ShipToAddress.ADDR_3,'') 			as Address3, 
	ISNULL(ShipToAddress.CITY,'') 				as Suburb, 
	ISNULL(ShipToAddress.STATE_CODE,'') 		as "State", 
	ISNULL(ShipToAddress.ZIP_CODE,'')			as PostCode, 
	ISNULL(ShipToCountry.COUNTRY_NAME,'')		as Country,
	(SELECT SUM(ACTUAL_WEIGHT) 
	FROM [LiveData].[dbo].PACKAGE 
	WHERE PICK_ID = Sol.PICK_ID)		as "Weight", 
	(SELECT COUNT(1) 
	FROM [LiveData].[dbo].PACKAGE 
	WHERE PACKAGE.PICK_ID=Sol.PICK_ID)	as "Packages" 
FROM SALES_ORDER Ord 
	INNER JOIN 			BATCH 				Inp					ON Ord.BATCH_ID 					= Inp.BATCH_ID 
	INNER JOIN 			RECIPIENT 			OrderBy				ON OrderBy.RECIP_ID 				= Ord.ORDER_BY_ID 
	INNER JOIN 			FFADDRESS 			OrderByAddress 		ON OrderByAddress.ADDRESS_ID 		= Orderby.DEF_ADDRESS_ID 
	INNER JOIN 			COUNTRY 			OrderByCountry		ON OrderByCountry.COUNTRY_ID 		= OrderByAddress.COUNTRY_ID 
	INNER JOIN 			RECIPIENT 			Recipient			ON Recipient.RECIP_ID 				= Ord.SHIP_TO_ID 
	INNER JOIN 			FFADDRESS 			ShipToAddress		ON ShipToAddress.ADDRESS_ID 		= Recipient.DEF_ADDRESS_ID 
	INNER JOIN 			COUNTRY 			ShipToCountry		ON ShipToCountry.COUNTRY_ID 		= ShipToAddress.COUNTRY_ID 
	INNER JOIN 			SO_LINE_ITEM 		Sol					ON Ord.SO_ID 						= SOl.SO_ID 
	INNER JOIN 			PAPSIZE				Sku					ON Sku.[CODE] 						= cast(Sol.ITEM_NO as char) 
	INNER JOIN 			CUSTOMER			Customer			ON Customer.CUST_ID 				= Sol.CUST_ID
	INNER JOIN 			DEBTOR				Account				ON Account.[DATAFLEX RECNUM ONE] 	= Customer.DEBTOR_RECNUM
	LEFT OUTER JOIN 	OrderShipTo			OrdShipTo			ON OrdShipTo.OrderId 				= Ord.SO_ID
	INNER JOIN 			FF_TRANS			Trans				ON Ord.SO_ID 						= Trans.SO_ID 
	INNER JOIN 			FF_TIMELINE			Timeline			ON Timeline.TIMELINE_ID 			= Trans.TIMELINE_ID
	INNER JOIN 			SO_LINE_ITEM_PRICE	Prices				ON (Prices.SO_ID 					= Sol.SO_ID) 
																AND (Prices.LINE_ITEM_NO			= Sol.LINE_ITEM_NO)
	LEFT JOIN			PACKAGE				Pack				ON Pack.SO_ID						= Ord.SO_ID


WHERE ISNULL(Sol.PICK_ID, '0')	>		0 
	AND ISNULL(Sol.ITEM_NO,0)	<>		0 
	AND (Sol.CREATED_DATE		>=		@FromShipDate 
	AND Sol.CREATED_DATE		<=		@ToShipDate)
	AND (Ord.CUST_SO_ID			LIKE	@JavelinNumber
	OR  Ord.CUST_SO_ID			=		@OWNumber)
	AND Trans.[LINE_ITEM_NO]	=		Sol.LINE_ITEM_NO
	AND Sol.INVENTORY_CODE		NOT IN ('EMERQSRFEE')