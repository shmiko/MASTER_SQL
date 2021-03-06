DECLARE @Datetime1 varchar(19), @DateTime2 varchar(19)
SET @Datetime1 = CONVERT(VARCHAR, DATEADD(DAY, -33 ,SYSDATETIME()), 121) -- Get System DateTime minus 1 days
SET @Datetime2 = CONVERT(VARCHAR, DATEADD(DAY, 0 ,SYSDATETIME()), 121)  -- Get System DateTime plus 0 days

/* order entry fees */
/* emergency fees */
SELECT
	'4'												as Tag,
	'Emergency Fee'														as "Description",
	Trans.ACT_PPU																	as UnitPrice,
	DEBTOR.[DATAFLEX RECNUM ONE]													as ID,
	DEBTOR.[AC NO]																	as Customer,
	SALES_ORDER.BILL_TO_ID															as CustomerId, 
	SALES_ORDER.CUST_ID																as ParentId, 
	DEBTOR.NAMES																	as Parent, 
	SALES_ORDER.[COMPANY CODE]														as CostCentre,
	SALES_ORDER.SO_ID																as OrderNum, 
	SALES_ORDER.CUST_SO_ID															as OrderWareNum, 
	SO_LINE_ITEM.PO_NO																as CustRef, 
	''																	as PickSlip,
	''																	as DespNote,
	CONVERT(VARCHAR(8),SALES_ORDER.CREATED_DATE,3)																	as DespDate, 
	'Emergency Fee'																	as FeeType, 
	CAST('EMERQSRFEE'	as nvarchar)												as Item, 
	--''																				as InventoryCode,
	 
	'1'																				as Qty,
	--[bsg_support].[dbo].[ufnGetPickLineCount](SALES_ORDER.SO_ID)					as OrderQty,
	'1'																				as UOI, 
	'Each'																			as UnitOfIssDesc, 
	 
	Trans.ACT_PPU 	as SellExcl, 
	(Trans.ACT_PPU *  1.1)															as SellIncl, 
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
	'0'																				as "Packages"
	--Trans.ACTIVITY_ID
	--[SO_LINE_ITEM].INVENTORY_CODE
FROM  --[SO_LINE_ITEM]
	--INNER JOIN 
	[LiveData].[dbo].SALES_ORDER					
	INNER JOIN [LiveData].[dbo].SO_LINE_ITEM ON SALES_ORDER.SO_ID = SO_LINE_ITEM.SO_ID
	INNER JOIN [LiveData].[dbo].CUSTOMER						ON CUSTOMER.CUST_ID				= SALES_ORDER.CUST_ID
	INNER JOIN [LiveData].[dbo].DEBTOR						ON DEBTOR.[DATAFLEX RECNUM ONE] = CUSTOMER.DEBTOR_RECNUM
	--INNER JOIN PAPSIZE						ON PAPSIZE.[CODE]				= cast(SO_LINE_ITEM.ITEM_NO as char) 
	INNER JOIN [LiveData].[dbo].RECIPIENT					ON RECIPIENT.RECIP_ID			= SALES_ORDER.SHIP_TO_ID
	INNER JOIN [LiveData].[dbo].FFADDRESS ShipToAddress		ON ShipToAddress.ADDRESS_ID 	= Recipient.DEF_ADDRESS_ID 
	INNER JOIN [LiveData].[dbo].COUNTRY ShipToCountry		ON ShipToCountry.COUNTRY_NUMBER = ShipToAddress.COUNTRY_ID 
	LEFT JOIN [LiveData].[dbo].OrderShipTo					ON OrderShipTo.OrderId			= SALES_ORDER.SO_ID
	LEFT JOIN [LiveData].[dbo].PACKAGE						ON PACKAGE.SO_ID				= SALES_ORDER.SO_ID
	INNER JOIN [LiveData].[dbo].FF_TRANS Trans				ON SALES_ORDER.SO_ID 			= Trans.SO_ID 
	INNER JOIN [LiveData].[dbo].FF_TIMELINE Timeline			ON Timeline.TIMELINE_ID 		= Trans.TIMELINE_ID
	--INNER JOIN SO_LINE_ITEM_PRICE			ON (SO_LINE_ITEM_PRICE.SO_ID	= SO_LINE_ITEM.SO_ID) 
	--	AND (SO_LINE_ITEM_PRICE.LINE_ITEM_NO = SO_LINE_ITEM.LINE_ITEM_NO)
	LEFT JOIN [LiveData].[dbo].PACKAGE PACKS		ON PACKS.SO_ID				= SALES_ORDER.SO_ID
	LEFT JOIN livedata.dbo.PICK PICKS		ON PICKS.SO_ID					= SALES_ORDER.SO_ID 
WHERE  (SALES_ORDER.CREATED_DATE > = @Datetime1 and SALES_ORDER.CREATED_DATE <= @Datetime2)
	
	AND [SO_LINE_ITEM].INVENTORY_CODE	=	'EMERQSRFEE' -- add other non stock items in here to exclude
	--AND Trans.ACTIVITY_ID LIKE '23'
	--and PICKS.PICK_STATUS = '21'
 -- Where SO_ID = '9863'
Group By
	Trans.ACT_PPU,
	DEBTOR.[DATAFLEX RECNUM ONE],
	DEBTOR.[AC NO],
	SALES_ORDER.BILL_TO_ID,
	SALES_ORDER.CUST_ID, 
	DEBTOR.NAMES,
	SALES_ORDER.[COMPANY CODE],
	SALES_ORDER.SO_ID,
	SALES_ORDER.CUST_SO_ID, 
	SO_LINE_ITEM.PO_NO,
	CONVERT(VARCHAR(8),SALES_ORDER.CREATED_DATE,3)	,
	Trans.ACT_PPU,
	Recipient.COMPANY_NAME, 
	RECIPIENT.FIRST_NAME,
	RECIPIENT.LAST_NAME,
	ShipToAddress.ADDR_1, 
	ShipToAddress.ADDR_2,
	ShipToAddress.ADDR_3, 
	ShipToAddress.CITY, 
	ShipToAddress.STATE_CODE, 
	ShipToAddress.ZIP_CODE,
	ShipToCountry.COUNTRY_NAME
	Order by SALES_ORDER.SO_ID,1 ASC