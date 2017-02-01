SELECT TOP 1
	DEBTOR.[DATAFLEX RECNUM ONE]													as ID,
	DEBTOR.[AC NO]																	as Customer,
	SALES_ORDER.BILL_TO_ID															as CustomerId, 
	SALES_ORDER.CUST_ID																as ParentId, 
	DEBTOR.NAMES																	as Parent, 
	SALES_ORDER.[COMPANY CODE]														as CostCentre,
	SALES_ORDER.SO_ID																as OrderNum, 
	SALES_ORDER.CUST_SO_ID															as OrderWareNum, 
	SO_LINE_ITEM.PO_NO																as CustRef, 
	SO_LINE_ITEM.PICK_ID															as PickSlip,
	SO_LINE_ITEM.PICK_ID															as DespNote,
	Trans.TIME_START																as DespDate, 
	'Handeling Fee'																	as FeeType, 
	CAST('FEEHANDLING'	as nvarchar)												as Item, 
	--''																				as InventoryCode,
	'Despatch Handeling Fee'														as "Description", 
	'1'																				as Qty,
	--[bsg_support].[dbo].[ufnGetPickLineCount](SALES_ORDER.SO_ID)					as OrderQty,
	'1'																				as UOI, 
	'Each'																			as UnitOfIssDesc, 
	Trans.ACT_PPU																	as UnitPrice, 
	(Trans.ACT_PPU * [bsg_support].[dbo].[ufnGetPickLineCount](SALES_ORDER.SO_ID))	as SellExcl, 
	((Trans.ACT_PPU * [bsg_support].[dbo].[ufnGetPickLineCount](SALES_ORDER.SO_ID)) 
												+ ISNULL(Trans.SalesTax,0))			as SellIncl, 
	--RECIPIENT.CUST_RECIP_ID															as OrderByCustomerRecipientID, 
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
	'0'																				as "Packages",
	Trans.ACTIVITY_ID
	--[SO_LINE_ITEM].INVENTORY_CODE
FROM  --[SO_LINE_ITEM]
	--INNER JOIN 
	SALES_ORDER					
	INNER JOIN SO_LINE_ITEM ON SALES_ORDER.SO_ID = SO_LINE_ITEM.SO_ID
	INNER JOIN CUSTOMER						ON CUSTOMER.CUST_ID				= SALES_ORDER.CUST_ID
	INNER JOIN DEBTOR						ON DEBTOR.[DATAFLEX RECNUM ONE] = CUSTOMER.DEBTOR_RECNUM
	--INNER JOIN PAPSIZE						ON PAPSIZE.[CODE]				= cast(SO_LINE_ITEM.ITEM_NO as char) 
	INNER JOIN RECIPIENT					ON RECIPIENT.RECIP_ID			= SALES_ORDER.SHIP_TO_ID
	INNER JOIN FFADDRESS ShipToAddress		ON ShipToAddress.ADDRESS_ID 	= Recipient.DEF_ADDRESS_ID 
	INNER JOIN COUNTRY ShipToCountry		ON ShipToCountry.COUNTRY_NUMBER = ShipToAddress.COUNTRY_ID 
	LEFT JOIN OrderShipTo					ON OrderShipTo.OrderId			= SALES_ORDER.SO_ID
	LEFT JOIN PACKAGE						ON PACKAGE.SO_ID				= SALES_ORDER.SO_ID
	INNER JOIN FF_TRANS Trans				ON SALES_ORDER.SO_ID 			= Trans.SO_ID 
	INNER JOIN FF_TIMELINE Timeline			ON Timeline.TIMELINE_ID 		= Trans.TIMELINE_ID
	--INNER JOIN SO_LINE_ITEM_PRICE			ON (SO_LINE_ITEM_PRICE.SO_ID	= SO_LINE_ITEM.SO_ID) 
	--	AND (SO_LINE_ITEM_PRICE.LINE_ITEM_NO = SO_LINE_ITEM.LINE_ITEM_NO)
	LEFT JOIN livedata.dbo.PICK PICKS		ON PICKS.SO_ID					= SALES_ORDER.SO_ID 
WHERE --(SO_LINE_ITEM.CREATED_DATE		>=		@FromShipDate 
	--AND SO_LINE_ITEM.CREATED_DATE		<=		@ToShipDate)
	-- (SALES_ORDER.CREATED_DATE > = @Datetime1 and SALES_ORDER.CREATED_DATE <= @Datetime2)
	 (SALES_ORDER.SO_ID	=		'9863')
	--AND Trans.[LINE_ITEM_NO]			=		[SO_LINE_ITEM].LINE_ITEM_NO
	--AND [SO_LINE_ITEM].INVENTORY_CODE	NOT IN	('EMERQSRFEE') -- add other non stock items in here to exclude
	--AND Trans.ACTIVITY_ID LIKE '23'
	--and PICKS.PICK_STATUS = '21'
 -- Where SO_ID = '9863'