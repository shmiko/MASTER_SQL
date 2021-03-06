DECLARE @FromShipDate as date
DECLARE @ToShipDate as date
DECLARE @JavelinNumber as varchar(10)
DECLARE @JavelinLetter as varchar(10)
DECLARE @OWNumber as VARCHAR(10)
DECLARE @OrdNumber as int
SELECT @FromShipDate = '09/01/2016'   
SELECT @ToShipDate = '12/16/2016'			--Note:  Make this +1 days from your last ship date
SET @JavelinLetter = 'W'
--SET @JavelinNumber = @JavelinLetter + '%' -- Note: Use this to get all Javelin Orders
SET @OWNumber = 'W1686439'					-- Note: Use this to get a single javelin Order
SET @OrdNumber = 2227

/* Misc Charges */
SELECT
	DEBTOR.[DATAFLEX RECNUM ONE]					as "1ID",
	DEBTOR.[AC NO]									as "2Customer",
	DEBTOR.NAMES									AS "TEMP-CustomerName",
	SALES_ORDER.BILL_TO_ID							as "3CustomerId", 
	SALES_ORDER.CUST_ID								as "4ParentId", 
	DEBTOR.NAMES									as "5Parent", 
	SO_LINE_ITEM.COST_CENTER						as "6CostCentre",
	SALES_ORDER.SO_ID								as "7OrderNum", 
	SALES_ORDER.CUST_SO_ID							as "8OrderWareNum", 
	SO_LINE_ITEM.PO_NO								as "9CustRef", 
	SO_LINE_ITEM.PICK_ID							as "10PickSlip",
	OrderShipTo.ShippingComment						as "11DespNote",
	(SELECT TOP (1) SHIP_DATE 
	 FROM PACKAGE 
	 WHERE PICK_ID=SO_LINE_ITEM.PICK_ID)			as "12DespDate", 
	'Misc Charges'									as "13FeeType", 
	SO_LINE_ITEM.ITEM_NO							as "14Item", 
	'Misc Charges'									as "TEMP-InventoryCode",
	SO_LINE_ITEM.ITEM_DESCRIPTION					as "15Description", 
	SO_LINE_ITEM.PACK_QTY							as "16Qty",
	'1'												as "TEMP-OrderQty",
	PAPSIZE.[UNIT OF ISSUE]							as "17UOI",
	PAPSIZE.[UNIT ISSUE DESC]						as "18UnitOfIssDesc", 
	SO_LINE_ITEM_PRICE.UNIT_PRICE					as "19UnitPrice", 
	((SO_LINE_ITEM_PRICE.UNIT_PRICE * SO_LINE_ITEM.PACK_QTY) 
		+ SO_LINE_ITEM_PRICE.SHIPPING_HANDLING)		as "20SellExcl", 
	((SO_LINE_ITEM_PRICE.UNIT_PRICE * SO_LINE_ITEM.PACK_QTY) 
		+ SO_LINE_ITEM_PRICE.SHIPPING_HANDLING 
		+ ISNULL(SO_LINE_ITEM_PRICE.SALES_TAX,0))	as "21SellIncl", 
	RECIPIENT.CUST_RECIP_ID							as "TEMP-OrderByCustomerRecipientID",
	RECIPIENT.COMPANY_NAME							as "22DeliverTo", 
	(RECIPIENT.FIRST_NAME 
		+ ' ' 
		+ RECIPIENT.LAST_NAME)						as "23AttentionTo", 
	ISNULL(ShipToAddress.ADDR_1,'') 				as "24Address1", 
	ISNULL(ShipToAddress.ADDR_2,'') 				as "25Address3", 
	ISNULL(ShipToAddress.ADDR_3,'') 				as "26Address3", 
	ISNULL(ShipToAddress.CITY,'') 					as "27Suburb", 
	ISNULL(ShipToAddress.STATE_CODE,'') 			as "28State", 
	ISNULL(ShipToAddress.ZIP_CODE,'')				as "29PostCode", 
	ISNULL(ShipToCountry.COUNTRY_NAME,'')			as "30Country",
	(SELECT SUM(ACTUAL_WEIGHT) 
	 FROM PACKAGE 
	 WHERE PICK_ID = SO_LINE_ITEM.PICK_ID)			as "31Weight", 
	(SELECT COUNT(1) 
	 FROM PACKAGE 
	 WHERE PACKAGE.PICK_ID=SO_LINE_ITEM.PICK_ID)	as "32Packages"
FROM  SO_LINE_ITEM
	INNER JOIN SALES_ORDER			ON SALES_ORDER.SO_ID			= SO_LINE_ITEM.SO_ID
	INNER JOIN CUSTOMER				ON CUSTOMER.CUST_ID				= SO_LINE_ITEM.CUST_ID
	INNER JOIN DEBTOR				ON DEBTOR.[DATAFLEX RECNUM ONE] = CUSTOMER.DEBTOR_RECNUM
	INNER JOIN PAPSIZE				ON PAPSIZE.[CODE]				= cast(SO_LINE_ITEM.ITEM_NO as char) 
	INNER JOIN RECIPIENT			ON RECIPIENT.RECIP_ID			= SO_LINE_ITEM.SHIP_TO_ID
	INNER JOIN FFADDRESS 			ShipToAddress		ON ShipToAddress.ADDRESS_ID 		= Recipient.DEF_ADDRESS_ID 
	INNER JOIN COUNTRY 				ShipToCountry		ON ShipToCountry.COUNTRY_NUMBER 		= ShipToAddress.COUNTRY_ID 
	LEFT JOIN OrderShipTo			ON OrderShipTo.OrderId			= SALES_ORDER.SO_ID
	LEFT JOIN PACKAGE				ON PACKAGE.SO_ID				= SALES_ORDER.SO_ID
	INNER JOIN SO_LINE_ITEM_PRICE	ON (SO_LINE_ITEM_PRICE.SO_ID	= SO_LINE_ITEM.SO_ID) 
		AND (SO_LINE_ITEM_PRICE.LINE_ITEM_NO = SO_LINE_ITEM.LINE_ITEM_NO)
WHERE ISNULL(SO_LINE_ITEM.PICK_ID, '0') >		0 
	AND ISNULL(SO_LINE_ITEM.ITEM_NO,0)	<>		0 
	AND (SO_LINE_ITEM.CREATED_DATE		>=		@FromShipDate 
	AND SO_LINE_ITEM.CREATED_DATE		<=		@ToShipDate)
	AND (SALES_ORDER.CUST_SO_ID			LIKE	@JavelinNumber
	OR  SALES_ORDER.CUST_SO_ID			=		@OWNumber)
	AND SO_LINE_ITEM.INVENTORY_CODE		IN ('EMERQSRFEE')

UNION 


/* Stocks */
SELECT 
	Account.[DATAFLEX RECNUM ONE]				as ID,
	Account.[AC NO]								as Customer,
	Account.NAMES								AS CustomerName,
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
	FROM PACKAGE 
	WHERE PICK_ID = Sol.PICK_ID)		as "Weight", 
	(SELECT COUNT(1) 
	FROM PACKAGE 
	WHERE PACKAGE.PICK_ID=Sol.PICK_ID)	as "Packages" 
FROM SALES_ORDER Ord 
	INNER JOIN 			BATCH 				Inp					ON Ord.BATCH_ID 					= Inp.BATCH_ID 
	INNER JOIN 			RECIPIENT 			OrderBy				ON OrderBy.RECIP_ID 				= Ord.ORDER_BY_ID 
	INNER JOIN 			FFADDRESS 			OrderByAddress 		ON OrderByAddress.ADDRESS_ID 		= Orderby.DEF_ADDRESS_ID 
	INNER JOIN 			COUNTRY 			OrderByCountry		ON OrderByCountry.COUNTRY_ID 		= OrderByAddress.COUNTRY_ID 
	INNER JOIN 			RECIPIENT 			Recipient			ON Recipient.RECIP_ID 				= Ord.SHIP_TO_ID 
	INNER JOIN 			FFADDRESS 			ShipToAddress		ON ShipToAddress.ADDRESS_ID 		= Recipient.DEF_ADDRESS_ID 
	INNER JOIN 			COUNTRY 			ShipToCountry		ON ShipToCountry.COUNTRY_NUMBER 		= ShipToAddress.COUNTRY_ID 
	INNER JOIN 			SO_LINE_ITEM 		Sol					ON Ord.SO_ID 						= SOl.SO_ID 
	INNER JOIN 			PAPSIZE				Sku					ON Sku.[CODE] 						= cast(Sol.ITEM_NO as char) 
	INNER JOIN 			CUSTOMER			Customer			ON Customer.CUST_ID 				= Sol.CUST_ID
	INNER JOIN 			DEBTOR				Account				ON Account.[DATAFLEX RECNUM ONE] 	= Customer.DEBTOR_RECNUM
	LEFT OUTER JOIN 	OrderShipTo			OrdShipTo			ON OrdShipTo.OrderId 				= Ord.SO_ID
	INNER JOIN 			FF_TRANS			Trans				ON Ord.SO_ID 						= Trans.SO_ID 
	INNER JOIN 			FF_TIMELINE			Timeline			ON Timeline.TIMELINE_ID 			= Trans.TIMELINE_ID
	INNER JOIN 			SO_LINE_ITEM_PRICE	Prices				ON (Prices.SO_ID 					= Sol.SO_ID) 
																AND (Prices.LINE_ITEM_NO			= Sol.LINE_ITEM_NO)
	--LEFT OUTER  JOIN			PACKAGE				Pack				ON Pack.SO_ID						= Ord.SO_ID
--WHERE Ord.SO_ID = 2227 

WHERE  --ISNULL(Sol.PICK_ID, '0') >		0 
	 ISNULL(Sol.ITEM_NO,0)	<>		0 
	AND (Sol.CREATED_DATE		>=		@FromShipDate 
	AND Sol.CREATED_DATE		<=		@ToShipDate)
	--AND Ord.CUST_SO_ID			=	@JavelinNumber
	AND (Ord.CUST_SO_ID			LIKE	@JavelinNumber
	OR  Ord.CUST_SO_ID			=		@OWNumber)
	AND  Trans.[LINE_ITEM_NO]	=		Sol.LINE_ITEM_NO
	AND Sol.INVENTORY_CODE		NOT IN ('EMERQSRFEE')

UNION

/* Pickfees  */
SELECT TOP 1
	DEBTOR.[DATAFLEX RECNUM ONE]													as ID,
	DEBTOR.[AC NO]																	as Customer,
	DEBTOR.NAMES																	AS CustomerName,
	SALES_ORDER.BILL_TO_ID															as CustomerId, 
	SALES_ORDER.CUST_ID																as ParentId, 
	DEBTOR.NAMES																	as Parent, 
	SO_LINE_ITEM.COST_CENTER														as CostCentre,
	SALES_ORDER.SO_ID																as OrderNum, 
	SALES_ORDER.CUST_SO_ID															as OrderWareNum, 
	SO_LINE_ITEM.PO_NO																as CustRef, 
	SO_LINE_ITEM.PICK_ID															as PickSlip,
	SO_LINE_ITEM.PICK_ID															as DespNote,
	Trans.TIME_START																as DespDate, 
	'PickFee'																		as FeeType, 
	Trans.TIMELINE_ID																as Item, 
	'PickFee'																		as InventoryCode,
	ACTIVITIES.InvoiceDescr															as "Description", 
	[bsg_support].[dbo].[ufnGetPickLineCount](SALES_ORDER.SO_ID)					as Qty,
	[bsg_support].[dbo].[ufnGetPickLineCount](SALES_ORDER.SO_ID)					as OrderQty,
	'1'																				as UOI, 
	'Each'																			as UnitOfIssDesc, 
	Trans.ACT_PPU																	as UnitPrice, 
	(Trans.ACT_PPU * [bsg_support].[dbo].[ufnGetPickLineCount](SALES_ORDER.SO_ID))	as SellExcl, 
	((Trans.ACT_PPU * [bsg_support].[dbo].[ufnGetPickLineCount](SALES_ORDER.SO_ID)) 
												+ ISNULL(Trans.SalesTax,0))			as SellIncl, 
	RECIPIENT.CUST_RECIP_ID															as OrderByCustomerRecipientID, 
	ISNULL(Recipient.COMPANY_NAME,'')												as DeliverTo, 
	ISNULL((RECIPIENT.FIRST_NAME 
		+ ' ' 
		+ RECIPIENT.LAST_NAME),'')													as AttentionTo,
	ISNULL(ShipToAddress.ADDR_1,'') 												as Address1, 
	ISNULL(ShipToAddress.ADDR_2,'') 												as Address3, 
	ISNULL(ShipToAddress.ADDR_3,'') 												as Address3, 
	ISNULL(ShipToAddress.CITY,'') 													as Suburb, 
	ISNULL(ShipToAddress.STATE_CODE,'') 											as "State", 
	ISNULL(ShipToAddress.ZIP_CODE,'')												as PostCode, 
	ISNULL(ShipToCountry.COUNTRY_NAME,'')											as Country,
	'0'																				as "Weight", 
	'0'																				as "Packages"
	--[SO_LINE_ITEM].INVENTORY_CODE
FROM  [SO_LINE_ITEM]
	INNER JOIN SALES_ORDER					ON SALES_ORDER.SO_ID			= SO_LINE_ITEM.SO_ID
	INNER JOIN CUSTOMER						ON CUSTOMER.CUST_ID				= SO_LINE_ITEM.CUST_ID
	INNER JOIN DEBTOR						ON DEBTOR.[DATAFLEX RECNUM ONE] = CUSTOMER.DEBTOR_RECNUM
	INNER JOIN PAPSIZE						ON PAPSIZE.[CODE]				= cast(SO_LINE_ITEM.ITEM_NO as char) 
	INNER JOIN RECIPIENT					ON RECIPIENT.RECIP_ID			= SO_LINE_ITEM.SHIP_TO_ID
	INNER JOIN FFADDRESS ShipToAddress		ON ShipToAddress.ADDRESS_ID 		= Recipient.DEF_ADDRESS_ID 
	INNER JOIN COUNTRY ShipToCountry		ON ShipToCountry.COUNTRY_NUMBER 		= ShipToAddress.COUNTRY_ID 
	LEFT JOIN OrderShipTo					ON OrderShipTo.OrderId			= SALES_ORDER.SO_ID
	LEFT JOIN PACKAGE						ON PACKAGE.SO_ID				= SALES_ORDER.SO_ID
	INNER JOIN FF_TRANS Trans				ON SALES_ORDER.SO_ID 						= Trans.SO_ID 
	INNER JOIN FF_TIMELINE Timeline			ON Timeline.TIMELINE_ID 			= Trans.TIMELINE_ID
	INNER JOIN ACTIVITIES					ON ACTIVITIES.ACTIVITY_ID		= Trans.ACTIVITY_ID
	INNER JOIN SO_LINE_ITEM_PRICE			ON (SO_LINE_ITEM_PRICE.SO_ID	= SO_LINE_ITEM.SO_ID) 
		AND (SO_LINE_ITEM_PRICE.LINE_ITEM_NO = SO_LINE_ITEM.LINE_ITEM_NO)
WHERE (SO_LINE_ITEM.CREATED_DATE		>=		@FromShipDate 
	AND SO_LINE_ITEM.CREATED_DATE		<=		@ToShipDate)
	AND (SALES_ORDER.CUST_SO_ID			LIKE	@JavelinNumber
	OR  SALES_ORDER.CUST_SO_ID			=		@OWNumber)
	AND Trans.[LINE_ITEM_NO]			=		[SO_LINE_ITEM].LINE_ITEM_NO
	AND ACTIVITIES.ACTIVITY_ID = 17 -- Pick Fee
	AND [SO_LINE_ITEM].INVENTORY_CODE	NOT IN	('EMERQSRFEE') -- add other non stock items in here to exclude

UNION


/* Despatch fees  */ ---This is NOT Working
SELECT TOP 1
	DEBTOR.[DATAFLEX RECNUM ONE]													as ID,
	DEBTOR.[AC NO]																	as Customer,
	DEBTOR.NAMES																	AS CustomerName,
	SALES_ORDER.BILL_TO_ID															as CustomerId, 
	SALES_ORDER.CUST_ID																as ParentId, 
	DEBTOR.NAMES																	as Parent, 
	SO_LINE_ITEM.COST_CENTER														as CostCentre,
	SALES_ORDER.SO_ID																as OrderNum, 
	SALES_ORDER.CUST_SO_ID															as OrderWareNum, 
	SO_LINE_ITEM.PO_NO																as CustRef, 
	SO_LINE_ITEM.PICK_ID															as PickSlip,
	SO_LINE_ITEM.PICK_ID															as DespNote,
	Trans.TIME_START																as DespDate, 
	'PickFee'																		as FeeType, 
	Trans.TIMELINE_ID																as Item, 
	'PickFee'																		as InventoryCode,
	ACTIVITIES.InvoiceDescr															as "Description", 
	[bsg_support].[dbo].[ufnGetPickLineCount](SALES_ORDER.SO_ID)					as Qty,
	[bsg_support].[dbo].[ufnGetPickLineCount](SALES_ORDER.SO_ID)					as OrderQty,
	'1'																				as UOI, 
	'Each'																			as UnitOfIssDesc, 
	Trans.ACT_PPU																	as UnitPrice, 
	(Trans.ACT_PPU * [bsg_support].[dbo].[ufnGetPickLineCount](SALES_ORDER.SO_ID))	as SellExcl, 
	((Trans.ACT_PPU * [bsg_support].[dbo].[ufnGetPickLineCount](SALES_ORDER.SO_ID)) 
												+ ISNULL(Trans.SalesTax,0))			as SellIncl, 
	RECIPIENT.CUST_RECIP_ID															as OrderByCustomerRecipientID, 
	ISNULL(Recipient.COMPANY_NAME,'')												as DeliverTo, 
	ISNULL((RECIPIENT.FIRST_NAME 
		+ ' ' 
		+ RECIPIENT.LAST_NAME),'')													as AttentionTo,
	ISNULL(ShipToAddress.ADDR_1,'') 												as Address1, 
	ISNULL(ShipToAddress.ADDR_2,'') 												as Address3, 
	ISNULL(ShipToAddress.ADDR_3,'') 												as Address3, 
	ISNULL(ShipToAddress.CITY,'') 													as Suburb, 
	ISNULL(ShipToAddress.STATE_CODE,'') 											as "State", 
	ISNULL(ShipToAddress.ZIP_CODE,'')												as PostCode, 
	ISNULL(ShipToCountry.COUNTRY_NAME,'')											as Country,
	'0'																				as "Weight", 
	'0'																				as "Packages"
	--[SO_LINE_ITEM].INVENTORY_CODE
FROM  [SO_LINE_ITEM]
	INNER JOIN SALES_ORDER					ON SALES_ORDER.SO_ID			= SO_LINE_ITEM.SO_ID
	INNER JOIN CUSTOMER						ON CUSTOMER.CUST_ID				= SO_LINE_ITEM.CUST_ID
	INNER JOIN DEBTOR						ON DEBTOR.[DATAFLEX RECNUM ONE] = CUSTOMER.DEBTOR_RECNUM
	INNER JOIN PAPSIZE						ON PAPSIZE.[CODE]				= cast(SO_LINE_ITEM.ITEM_NO as char) 
	INNER JOIN RECIPIENT					ON RECIPIENT.RECIP_ID			= SO_LINE_ITEM.SHIP_TO_ID
	INNER JOIN FFADDRESS ShipToAddress		ON ShipToAddress.ADDRESS_ID 	= Recipient.DEF_ADDRESS_ID 
	INNER JOIN COUNTRY ShipToCountry		ON ShipToCountry.COUNTRY_NUMBER = ShipToAddress.COUNTRY_ID 
	LEFT JOIN OrderShipTo					ON OrderShipTo.OrderId			= SALES_ORDER.SO_ID
	LEFT JOIN PACKAGE						ON PACKAGE.SO_ID				= SALES_ORDER.SO_ID
	INNER JOIN FF_TRANS Trans				ON SALES_ORDER.SO_ID 			= Trans.SO_ID 
	INNER JOIN FF_TIMELINE Timeline			ON Timeline.TIMELINE_ID 		= Trans.TIMELINE_ID
	INNER JOIN ACTIVITIES					ON ACTIVITIES.ACTIVITY_ID		= Trans.ACTIVITY_ID
	INNER JOIN SO_LINE_ITEM_PRICE			ON (SO_LINE_ITEM_PRICE.SO_ID	= SO_LINE_ITEM.SO_ID) 
		AND (SO_LINE_ITEM_PRICE.LINE_ITEM_NO = SO_LINE_ITEM.LINE_ITEM_NO)
WHERE (SO_LINE_ITEM.CREATED_DATE		>=		@FromShipDate 
	AND SO_LINE_ITEM.CREATED_DATE		<=		@ToShipDate)
	AND (SALES_ORDER.CUST_SO_ID			LIKE	@JavelinNumber
	OR  SALES_ORDER.CUST_SO_ID			=		@OWNumber)
	AND Trans.[LINE_ITEM_NO]			=		[SO_LINE_ITEM].LINE_ITEM_NO
	AND ACTIVITIES.ACTIVITY_ID = 23 -- Order Despatch Handling Fee
	AND [SO_LINE_ITEM].INVENTORY_CODE	NOT IN	('EMERQSRFEE') -- add other non stock items in here to exclude

UNION

/* Shipping */
SELECT TOP 1
	DEBTOR.[DATAFLEX RECNUM ONE]					as ID,
	DEBTOR.[AC NO]									as Customer,
	DEBTOR.NAMES									AS CustomerName,
	SALES_ORDER.BILL_TO_ID							as CustomerId, 
	SALES_ORDER.CUST_ID								as ParentId, 
	DEBTOR.NAMES									as Parent, 
	''												as CostCentre,
	SALES_ORDER.SO_ID								as OrderNum, 
	SALES_ORDER.CUST_SO_ID							as OrderWareNum, 
	''												as CustRef, 
	PACKAGE.PICK_ID									as PickSlip,
	PACKAGE.PICK_ID									as DespNote, 
	PACKAGE.SHIP_DATE								as DespDate, 
	'Shipping'										as FeeType, 
	[SO_LINE_ITEM].ITEM_NO							as Item, 
	[SO_LINE_ITEM].INVENTORY_CODE					as InventoryCode, 
	SHIPPING_MODE.SHIP_MODE_DESC					as "Description", 
	'1'												as Qty,
	''												as OrderQty,
	''												as UOI	, 
	''												as UnitOfIssDesc, 
	SO_CHARGE.AMOUNT								as UnitPrice, 
	SO_CHARGE.AMOUNT								as SellExcl, 
	(SO_CHARGE.AMOUNT 
	+ ISNULL(SO_CHARGE.SALES_TAX,0))				as SellIncl, 
	RECIPIENT.CUST_RECIP_ID							as OrderByCustomerRecipientID,
	ISNULL(Recipient.COMPANY_NAME,'')				as DeliverTo, 
	ISNULL((RECIPIENT.FIRST_NAME 
		+ ' ' 
		+ RECIPIENT.LAST_NAME),'')					as AttentionTo,
	ISNULL(ShipToAddress.ADDR_1,'')					as Address1, 
	ISNULL(ShipToAddress.ADDR_2,'')					as Address3, 
	ISNULL(ShipToAddress.ADDR_3,'')					as Address3, 
	ISNULL(ShipToAddress.CITY,'')					as Suburb, 
	ISNULL(ShipToAddress.STATE_CODE,'')				as "State", 
	ISNULL(ShipToAddress.ZIP_CODE,'')				as PostCode, 
	ISNULL(ShipToCountry.COUNTRY_NAME,'')			as Country,
	PACKAGE.ACTUAL_WEIGHT							as "Weight", 
	'1'												as Packages
FROM [LiveData].[dbo].SO_CHARGE
	INNER JOIN [LiveData].[dbo].SALES_ORDER			ON SALES_ORDER.SO_ID			= SO_CHARGE.SO_ID
	INNER JOIN [LiveData].[dbo].CUSTOMER			ON CUSTOMER.CUST_ID				= SALES_ORDER.CUST_ID
	INNER JOIN [SO_LINE_ITEM]						ON SALES_ORDER.SO_ID			= SO_LINE_ITEM.SO_ID
	INNER JOIN RECIPIENT							ON RECIPIENT.RECIP_ID			= SO_LINE_ITEM.SHIP_TO_ID
	INNER JOIN FFADDRESS ShipToAddress				ON ShipToAddress.ADDRESS_ID 	= Recipient.DEF_ADDRESS_ID 
	INNER JOIN COUNTRY ShipToCountry				ON ShipToCountry.COUNTRY_NUMBER = ShipToAddress.COUNTRY_ID 
	INNER JOIN [LiveData].[dbo].DEBTOR				ON DEBTOR.[DATAFLEX RECNUM ONE] = CUSTOMER.DEBTOR_RECNUM
	LEFT JOIN [LiveData].[dbo].PACKAGE				ON PACKAGE.PACKAGE_ID			= SO_CHARGE.PackageID
	LEFT JOIN [LiveData].[dbo].SHIPPING_MODE		ON SHIPPING_MODE.SHIP_MODE_ID	= PACKAGE.SHIP_MODE_ID
WHERE ISNULL(SO_CHARGE.SO_ID, '0')		>		0 
	--AND (SO_CHARGE.MODIFIED_DATE		>=		@FromShipDate 
	--AND SO_CHARGE.MODIFIED_DATE			<=		@ToShipDate)
	AND SALES_ORDER.CUST_SO_ID			=		'W1686439' --@OWNumber
	--AND  SALES_ORDER.SO_ID			=		@OrdNumber