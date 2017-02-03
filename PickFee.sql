--DECLARE @FromShipDate as date, @ToShipDate as date, @JavelinNumber as varchar(10), 
--@JavelinLetter as varchar(10), @OWNumber as VARCHAR(10), @WMS_OrderNumber as VARCHAR(10),
--@Datetime1 varchar(19), @DateTime2 varchar(19), @customer as varchar(40)
--SELECT @FromShipDate = '01/01/2017'   
--SELECT @ToShipDate = '31/01/2017'			--Note:  Make this +1 days from your last ship date
--SET @JavelinLetter = 'W'
--SET @Datetime1 = CONVERT(VARCHAR, DATEADD(DAY, -33 ,SYSDATETIME()), 121) -- Get System DateTime minus 1 days
--SET @Datetime2 = CONVERT(VARCHAR, DATEADD(DAY, 0 ,SYSDATETIME()), 121)  -- Get System DateTime plus 0 days
--SET @JavelinNumber = @JavelinLetter + '%' -- Note: Use this to get all Javelin Orders
--SET @OWNumber = ''					-- Note: Use this to get a single javelin Order - Tested W1719524
--SET @customer = ''

--If @customer IS NOT NULL Then

/* Pickfees  */
SELECT --TOP 1
	'1'												as Tag,
	'Line Picking Fee'																as "Description",
	Trans.ACT_PPU																	as UnitPrice,
	DEBTOR.[DATAFLEX RECNUM ONE]													as ID,
	DEBTOR.[AC NO]																	as Customer,
	SALES_ORDER.BILL_TO_ID															as CustomerId, 
	SALES_ORDER.CUST_ID																as ParentId, 
	DEBTOR.NAMES																	as Parent, 
	SO_LINE_ITEM.COST_CENTER														as CostCentre,
	SALES_ORDER.SO_ID														as OrderNum, 
	SALES_ORDER.CUST_SO_ID															as OrderWareNum, 
	SO_LINE_ITEM.PO_NO																as CustRef, 

	PACKS.PICK_ID																	as PickSlip,
	PACKS.PICK_ID																	as DespNote,
	PACKS.SHIP_DATE 																as DespDate, 
	'Pick Fee'																		as FeeType, 
	CAST('FEEPICK'	as nvarchar)													as Item, 
	[LiveData].[dbo].[ufnGetPickLineCount](SALES_ORDER.SO_ID)					as Qty,
	'1'																				as UOI, 
	'Each'																			as UnitOfIssDesc, 
	(Trans.ACT_PPU * [LiveData].[dbo].[ufnGetPickLineCount](SALES_ORDER.SO_ID))	as SellExcl, 
	((Trans.ACT_PPU * [LiveData].[dbo].[ufnGetPickLineCount](SALES_ORDER.SO_ID)) *   1.1)			as SellIncl, 
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
FROM  [LiveData].[dbo].[SO_LINE_ITEM]
	INNER JOIN [LiveData].[dbo].SALES_ORDER					ON SALES_ORDER.SO_ID			= SO_LINE_ITEM.SO_ID
	INNER JOIN [LiveData].[dbo].CUSTOMER						ON CUSTOMER.CUST_ID				= SO_LINE_ITEM.CUST_ID
	INNER JOIN [LiveData].[dbo].DEBTOR						ON DEBTOR.[DATAFLEX RECNUM ONE] = CUSTOMER.DEBTOR_RECNUM
	INNER JOIN [LiveData].[dbo].PAPSIZE						ON PAPSIZE.[CODE]				= cast(SO_LINE_ITEM.ITEM_NO as char) 
	INNER JOIN [LiveData].[dbo].RECIPIENT					ON RECIPIENT.RECIP_ID			= SO_LINE_ITEM.SHIP_TO_ID
	INNER JOIN [LiveData].[dbo].FFADDRESS ShipToAddress		ON ShipToAddress.ADDRESS_ID 	= Recipient.DEF_ADDRESS_ID 
	INNER JOIN [LiveData].[dbo].COUNTRY ShipToCountry		ON ShipToCountry.COUNTRY_NUMBER = ShipToAddress.COUNTRY_ID 
	LEFT JOIN [LiveData].[dbo].OrderShipTo					ON OrderShipTo.OrderId			= SALES_ORDER.SO_ID
	INNER JOIN [LiveData].[dbo].FF_TRANS Trans				ON SALES_ORDER.SO_ID 			= Trans.SO_ID 
	INNER JOIN [LiveData].[dbo].FF_TIMELINE Timeline			ON Timeline.TIMELINE_ID 		= Trans.TIMELINE_ID
	INNER JOIN [LiveData].[dbo].SO_LINE_ITEM_PRICE			ON (SO_LINE_ITEM_PRICE.SO_ID	= SO_LINE_ITEM.SO_ID) 
		AND (SO_LINE_ITEM_PRICE.LINE_ITEM_NO = SO_LINE_ITEM.LINE_ITEM_NO)
	LEFT JOIN livedata.dbo.PICK PICKS		ON PICKS.SO_ID					= SALES_ORDER.SO_ID 
	LEFT JOIN [LiveData].[dbo].PACKAGE PACKS		ON PACKS.SO_ID				= SALES_ORDER.SO_ID
WHERE 
	[SO_LINE_ITEM].INVENTORY_CODE	NOT IN	('EMERQSRFEE') -- add other non stock items in here to exclude
	and PICKS.PICK_STATUS = '21'
	AND Trans.ACTIVITY_ID = '17'
Group BY SALES_ORDER.SO_ID,
	Trans.ACT_PPU,
	DEBTOR.[DATAFLEX RECNUM ONE],
	DEBTOR.[AC NO],
	SALES_ORDER.BILL_TO_ID,
	SALES_ORDER.CUST_ID,
	DEBTOR.NAMES, 
	SO_LINE_ITEM.COST_CENTER,
	SALES_ORDER.CUST_SO_ID,
	SO_LINE_ITEM.PO_NO,
	PACKS.PICK_ID,
	PACKS.PICK_ID,
	PACKS.SHIP_DATE,
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