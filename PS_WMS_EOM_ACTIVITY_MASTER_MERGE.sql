DECLARE @FromShipDate as date, @ToShipDate as date, @JavelinNumber as varchar(10), 
@JavelinLetter as varchar(10), @OWNumber as VARCHAR(10), @WMS_OrderNumber as VARCHAR(10),
@Datetime1 varchar(19), @DateTime2 varchar(19), @customer as varchar(40)
SET @Datetime1 = CONVERT(VARCHAR, DATEADD(DAY, -33 ,SYSDATETIME()), 121) -- Get System DateTime minus 1 days
SET @Datetime2 = CONVERT(VARCHAR, DATEADD(DAY, 0 ,SYSDATETIME()), 121)  -- Get System DateTime plus 0 days
SELECT @FromShipDate = '09/01/2016'   
SELECT @ToShipDate = '12/16/2016'			--Note:  Make this +1 days from your last ship date
SET @JavelinLetter = 'W'
--SET @JavelinNumber = @JavelinLetter + '%' -- Note: Use this to get all Javelin Orders
SET @OWNumber = ''					-- Note: Use this to get a single javelin Order - Tested W1719524
SET @customer = ''
SELECT --TOP 1
	'1'																				as Tag,
	'Line Picking Fee'																as "Description",
	Trans.ACT_PPU																	as UnitPrice,
	DEBTOR.[DATAFLEX RECNUM ONE]													as ID,
	DEBTOR.[AC NO]																	as Customer,
	SALES_ORDER.BILL_TO_ID															as CustomerId, 
	SALES_ORDER.CUST_ID																as ParentId, 
	DEBTOR.NAMES																	as Parent, 
	SO_LINE_ITEM.COST_CENTER														as CostCentre,
	SALES_ORDER.SO_ID																as OrderNum, 
	SALES_ORDER.CUST_SO_ID															as OrderWareNum, 
	ISNULL(SO_LINE_ITEM.PO_NO,'')													as CustRef, 
	PACKS.PICK_ID																	as PickSlip,
	PACKS.PICK_ID																	as DespNote,
	CONVERT(VARCHAR(8),PACKS.SHIP_DATE,3) 											as DespDate, 
	'Pick Fee'																		as FeeType, 
	CAST('FEEPICK'	as nvarchar)													as Item, 
	[LiveData].[dbo].[ufnGetPickLineCount](SALES_ORDER.SO_ID)						as Qty,
	'1'																				as UOI, 
	'Each'																			as UnitOfIssDesc, 
	(Trans.ACT_PPU * [LiveData].[dbo].[ufnGetPickLineCount](SALES_ORDER.SO_ID))		as SellExcl, 
	((Trans.ACT_PPU * [LiveData].[dbo].[ufnGetPickLineCount](SALES_ORDER.SO_ID)) *   1.1)			
																					as SellIncl, 
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
	INNER JOIN [LiveData].[dbo].SALES_ORDER											ON SALES_ORDER.SO_ID			= SO_LINE_ITEM.SO_ID
	INNER JOIN [LiveData].[dbo].CUSTOMER											ON CUSTOMER.CUST_ID				= SO_LINE_ITEM.CUST_ID
	INNER JOIN [LiveData].[dbo].DEBTOR												ON DEBTOR.[DATAFLEX RECNUM ONE] = CUSTOMER.DEBTOR_RECNUM
	INNER JOIN [LiveData].[dbo].PAPSIZE												ON PAPSIZE.[CODE]				= cast(SO_LINE_ITEM.ITEM_NO as char) 
	INNER JOIN [LiveData].[dbo].RECIPIENT											ON RECIPIENT.RECIP_ID			= SO_LINE_ITEM.SHIP_TO_ID
	INNER JOIN [LiveData].[dbo].FFADDRESS ShipToAddress								ON ShipToAddress.ADDRESS_ID 	= Recipient.DEF_ADDRESS_ID 
	INNER JOIN [LiveData].[dbo].COUNTRY ShipToCountry								ON ShipToCountry.COUNTRY_NUMBER = ShipToAddress.COUNTRY_ID 
	LEFT JOIN [LiveData].[dbo].OrderShipTo											ON OrderShipTo.OrderId			= SALES_ORDER.SO_ID
	INNER JOIN [LiveData].[dbo].FF_TRANS Trans										ON SALES_ORDER.SO_ID 			= Trans.SO_ID 
	INNER JOIN [LiveData].[dbo].FF_TIMELINE Timeline								ON Timeline.TIMELINE_ID 		= Trans.TIMELINE_ID
	INNER JOIN [LiveData].[dbo].SO_LINE_ITEM_PRICE									ON (SO_LINE_ITEM_PRICE.SO_ID	= SO_LINE_ITEM.SO_ID) 
		AND (SO_LINE_ITEM_PRICE.LINE_ITEM_NO = SO_LINE_ITEM.LINE_ITEM_NO)
	LEFT JOIN livedata.dbo.PICK PICKS												ON PICKS.SO_ID					= SALES_ORDER.SO_ID 
	LEFT JOIN [LiveData].[dbo].PACKAGE PACKS										ON PACKS.SO_ID					= SALES_ORDER.SO_ID
WHERE 
	[SO_LINE_ITEM].INVENTORY_CODE	NOT IN	('EMERQSRFEE') -- add other non stock items in here to exclude
	and PICKS.PICK_STATUS = '21'
	AND Trans.ACTIVITY_ID = '17'
	--and (PACKS.SHIP_DATE > = @Datetime1 and PACKS.SHIP_DATE <= @Datetime2)
	and SO_LINE_ITEM.COST_CENTER IS NOT NULL
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
	CONVERT(VARCHAR(8),PACKS.SHIP_DATE,3),
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

UNION 
/* handling fees */
SELECT --TOP 1
	'2'																				as Tag,
	'Despatch Handeling Fee'														as "Description",
	Trans.ACT_PPU																	as UnitPrice,
	DEBTOR.[DATAFLEX RECNUM ONE]													as ID,
	DEBTOR.[AC NO]																	as Customer,
	SALES_ORDER.BILL_TO_ID															as CustomerId, 
	SALES_ORDER.CUST_ID																as ParentId, 
	DEBTOR.NAMES																	as Parent, 
	SO_LINE_ITEM.COST_CENTER														as CostCentre,
	SALES_ORDER.SO_ID																as OrderNum, 
	SALES_ORDER.CUST_SO_ID															as OrderWareNum, 
	ISNULL(SO_LINE_ITEM.PO_NO,'')													as CustRef, 
	PACKS.PICK_ID																	as PickSlip,
	PACKS.PICK_ID																	as DespNote,
	CONVERT(VARCHAR(8),PACKS.SHIP_DATE,3) 											as DespDate, 
	'Handeling Fee'																	as FeeType, 
	CAST('FEEHANDLING'	as nvarchar)												as Item, 
	[LiveData].[dbo].[ufnGetPickLineCount](SALES_ORDER.SO_ID)						as Qty,
	'1'																				as UOI, 
	'Each'																			as UnitOfIssDesc, 
	(Trans.ACT_PPU)																	as SellExcl, 
	((Trans.ACT_PPU) *   1.1)			
																					as SellIncl, 
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
	INNER JOIN [LiveData].[dbo].SALES_ORDER											ON SALES_ORDER.SO_ID			= SO_LINE_ITEM.SO_ID
	INNER JOIN [LiveData].[dbo].CUSTOMER											ON CUSTOMER.CUST_ID				= SO_LINE_ITEM.CUST_ID
	INNER JOIN [LiveData].[dbo].DEBTOR												ON DEBTOR.[DATAFLEX RECNUM ONE] = CUSTOMER.DEBTOR_RECNUM
	INNER JOIN [LiveData].[dbo].PAPSIZE												ON PAPSIZE.[CODE]				= cast(SO_LINE_ITEM.ITEM_NO as char) 
	INNER JOIN [LiveData].[dbo].RECIPIENT											ON RECIPIENT.RECIP_ID			= SO_LINE_ITEM.SHIP_TO_ID
	INNER JOIN [LiveData].[dbo].FFADDRESS ShipToAddress								ON ShipToAddress.ADDRESS_ID 	= Recipient.DEF_ADDRESS_ID 
	INNER JOIN [LiveData].[dbo].COUNTRY ShipToCountry								ON ShipToCountry.COUNTRY_NUMBER = ShipToAddress.COUNTRY_ID 
	LEFT JOIN [LiveData].[dbo].OrderShipTo											ON OrderShipTo.OrderId			= SALES_ORDER.SO_ID
	INNER JOIN [LiveData].[dbo].FF_TRANS Trans										ON SALES_ORDER.SO_ID 			= Trans.SO_ID 
	INNER JOIN [LiveData].[dbo].FF_TIMELINE Timeline								ON Timeline.TIMELINE_ID 		= Trans.TIMELINE_ID
	INNER JOIN [LiveData].[dbo].SO_LINE_ITEM_PRICE									ON (SO_LINE_ITEM_PRICE.SO_ID	= SO_LINE_ITEM.SO_ID) 
		AND (SO_LINE_ITEM_PRICE.LINE_ITEM_NO = SO_LINE_ITEM.LINE_ITEM_NO)
	LEFT JOIN livedata.dbo.PICK PICKS												ON PICKS.SO_ID					= SALES_ORDER.SO_ID 
	LEFT JOIN [LiveData].[dbo].PACKAGE PACKS										ON PACKS.SO_ID					= SALES_ORDER.SO_ID
WHERE 
	[SO_LINE_ITEM].INVENTORY_CODE	NOT IN	('EMERQSRFEE') -- add other non stock items in here to exclude
	and PICKS.PICK_STATUS = '21'
	AND Trans.ACTIVITY_ID LIKE '23'
	--and (PACKS.SHIP_DATE > = @Datetime1 and PACKS.SHIP_DATE <= @Datetime2)
	and SO_LINE_ITEM.COST_CENTER IS NOT NULL
Group BY SALES_ORDER.SO_ID,
	PACKS.PICK_ID,
	Trans.ACT_PPU,
	DEBTOR.[DATAFLEX RECNUM ONE],
	DEBTOR.[AC NO],
	SALES_ORDER.BILL_TO_ID,
	SALES_ORDER.CUST_ID,
	DEBTOR.NAMES, 
	SO_LINE_ITEM.COST_CENTER,
	SALES_ORDER.CUST_SO_ID,
	SO_LINE_ITEM.PO_NO,
	--PACKS.PICK_ID,
	CONVERT(VARCHAR(8),PACKS.SHIP_DATE,3),
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

UNION
/* order entry fees */
SELECT 
	'3'																				as Tag,
	o.ORIGIN_NAME + ' Order Entry Fee'												as "Description",
	po.SOOriginCharge																as UnitPrice,
	DEBTOR.[DATAFLEX RECNUM ONE]													as ID,
	DEBTOR.[AC NO]																	as Customer,
	SALES_ORDER.BILL_TO_ID															as CustomerId, 
	SALES_ORDER.CUST_ID																as ParentId, 
	DEBTOR.NAMES																	as Parent, 
	SALES_ORDER.[COMPANY CODE]														as CostCentre,
	SALES_ORDER.SO_ID																as OrderNum, 
	SALES_ORDER.CUST_SO_ID															as OrderWareNum, 
	ISNULL(SO_LINE_ITEM.PO_NO,'')													as CustRef, 
	''																				as PickSlip,
	''																				as DespNote,
	CONVERT(VARCHAR(8),SALES_ORDER.CREATED_DATE,3)									as DespDate, 
	o.ORIGIN_NAME + ' Order Entry Fee'												as FeeType, 
	CAST('FEEORDER'	as nvarchar)													as Item, 
	'1'																				as Qty,
	'1'																				as UOI, 
	'Each'																			as UnitOfIssDesc, 
	po.SOOriginCharge 																as SellExcl, 
	(po.SOOriginCharge *  1.1)														as SellIncl, 
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
	INNER JOIN [LiveData].[dbo].SO_LINE_ITEM										ON SALES_ORDER.SO_ID			= SO_LINE_ITEM.SO_ID
	INNER JOIN [LiveData].[dbo].CUSTOMER											ON CUSTOMER.CUST_ID				= SALES_ORDER.CUST_ID
	INNER JOIN [LiveData].[dbo].DEBTOR												ON DEBTOR.[DATAFLEX RECNUM ONE] = CUSTOMER.DEBTOR_RECNUM
	INNER JOIN [LiveData].[dbo].RECIPIENT											ON RECIPIENT.RECIP_ID			= SALES_ORDER.SHIP_TO_ID
	INNER JOIN [LiveData].[dbo].FFADDRESS ShipToAddress								ON ShipToAddress.ADDRESS_ID 	= Recipient.DEF_ADDRESS_ID 
	INNER JOIN [LiveData].[dbo].COUNTRY ShipToCountry								ON ShipToCountry.COUNTRY_NUMBER = ShipToAddress.COUNTRY_ID 
	LEFT JOIN [LiveData].[dbo].OrderShipTo											ON OrderShipTo.OrderId			= SALES_ORDER.SO_ID
	LEFT JOIN [LiveData].[dbo].PACKAGE												ON PACKAGE.SO_ID				= SALES_ORDER.SO_ID
	INNER JOIN [LiveData].[dbo].FF_TRANS Trans										ON SALES_ORDER.SO_ID 			= Trans.SO_ID 
	INNER JOIN [LiveData].[dbo].FF_TIMELINE Timeline								ON Timeline.TIMELINE_ID 		= Trans.TIMELINE_ID
	LEFT OUTER JOIN livedata.dbo.FFPROJECT ffp										ON ffp.PROJ_ID					= SALES_ORDER.PROJ_ID
	LEFT OUTER JOIN livedata.dbo.SO_ORIGIN o										ON o.SO_ORIGIN_ID				= SALES_ORDER.SO_ORIGIN_ID
	LEFT OUTER JOIN livedata.dbo.ProjSOOrigin po									ON po.SOOriginId				= SALES_ORDER.SO_ORIGIN_ID
Where DEBTOR.[AC NO] <> 'HOUSEACC'
	and SALES_ORDER.SO_ORIGIN_ID <> '0'
	and po.SOOriginCharge <> '0'
	--and (SALES_ORDER.CREATED_DATE > = @Datetime1 and SALES_ORDER.CREATED_DATE <= @Datetime2)
Group By
	SALES_ORDER.SO_ID,
	o.ORIGIN_NAME,
	po.SOOriginCharge,
	DEBTOR.[DATAFLEX RECNUM ONE],
	DEBTOR.[AC NO],
	SALES_ORDER.BILL_TO_ID, 
	SALES_ORDER.CUST_ID, 
	DEBTOR.NAMES,
	SALES_ORDER.[COMPANY CODE],
	SALES_ORDER.CUST_SO_ID, 
	SO_LINE_ITEM.PO_NO, 
	CONVERT(VARCHAR(8),SALES_ORDER.CREATED_DATE,3),
	po.SOOriginCharge,
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

UNION
/* emergency fees */
SELECT
	'4'																				as Tag,
	'Emergency Fee'																	as "Description",
	Trans.ACT_PPU																	as UnitPrice,
	DEBTOR.[DATAFLEX RECNUM ONE]													as ID,
	DEBTOR.[AC NO]																	as Customer,
	SALES_ORDER.BILL_TO_ID															as CustomerId, 
	SALES_ORDER.CUST_ID																as ParentId, 
	DEBTOR.NAMES																	as Parent, 
	SALES_ORDER.[COMPANY CODE]														as CostCentre,
	SALES_ORDER.SO_ID																as OrderNum, 
	SALES_ORDER.CUST_SO_ID															as OrderWareNum, 
	ISNULL(SO_LINE_ITEM.PO_NO,'')													as CustRef, 
	''																				as PickSlip,
	''																				as DespNote,
	CONVERT(VARCHAR(8),SALES_ORDER.CREATED_DATE,3)									as DespDate, 
	'Emergency Fee'																	as FeeType, 
	CAST('EMERQSRFEE'	as nvarchar)												as Item, 
	'1'																				as Qty,
	'1'																				as UOI, 
	'Each'																			as UnitOfIssDesc, 
	 
	Trans.ACT_PPU 																	as SellExcl, 
	(Trans.ACT_PPU *  1.1)															as SellIncl, 
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
	INNER JOIN [LiveData].[dbo].SO_LINE_ITEM										ON SALES_ORDER.SO_ID			= SO_LINE_ITEM.SO_ID
	INNER JOIN [LiveData].[dbo].CUSTOMER											ON CUSTOMER.CUST_ID				= SALES_ORDER.CUST_ID
	INNER JOIN [LiveData].[dbo].DEBTOR												ON DEBTOR.[DATAFLEX RECNUM ONE] = CUSTOMER.DEBTOR_RECNUM
	INNER JOIN [LiveData].[dbo].RECIPIENT											ON RECIPIENT.RECIP_ID			= SALES_ORDER.SHIP_TO_ID
	INNER JOIN [LiveData].[dbo].FFADDRESS ShipToAddress								ON ShipToAddress.ADDRESS_ID 	= Recipient.DEF_ADDRESS_ID 
	INNER JOIN [LiveData].[dbo].COUNTRY ShipToCountry								ON ShipToCountry.COUNTRY_NUMBER = ShipToAddress.COUNTRY_ID 
	LEFT JOIN [LiveData].[dbo].OrderShipTo											ON OrderShipTo.OrderId			= SALES_ORDER.SO_ID
	LEFT JOIN [LiveData].[dbo].PACKAGE												ON PACKAGE.SO_ID				= SALES_ORDER.SO_ID
	INNER JOIN [LiveData].[dbo].FF_TRANS Trans										ON SALES_ORDER.SO_ID 			= Trans.SO_ID 
	INNER JOIN [LiveData].[dbo].FF_TIMELINE Timeline								ON Timeline.TIMELINE_ID 		= Trans.TIMELINE_ID
	LEFT JOIN [LiveData].[dbo].PACKAGE PACKS										ON PACKS.SO_ID					= SALES_ORDER.SO_ID
	LEFT JOIN livedata.dbo.PICK PICKS												ON PICKS.SO_ID					= SALES_ORDER.SO_ID 
WHERE -- (SALES_ORDER.CREATED_DATE > = @Datetime1 and SALES_ORDER.CREATED_DATE <= @Datetime2)
	--AND 
	[SO_LINE_ITEM].INVENTORY_CODE	=	'EMERQSRFEE' -- add other non stock items in here to exclude
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

	
UNION



/* Item */
SELECT '5',
	SO_LINE_ITEM.ITEM_DESCRIPTION													as Description,
	SO_LINE_ITEM_PRICE.UNIT_PRICE													as UnitPrice,
	DEBTOR.[DATAFLEX RECNUM ONE]													as ID,
	DEBTOR.[AC NO]																	as Customer,
	SALES_ORDER.BILL_TO_ID															as CustomerId, 
	SALES_ORDER.CUST_ID																as ParentId, 
	DEBTOR.NAMES																	as Parent, 
	SO_LINE_ITEM.COST_CENTER														as CostCentre,
	SALES_ORDER.SO_ID																as OrderNum, 
	SALES_ORDER.CUST_SO_ID															as OrderWareNum, 
	ISNULL(SO_LINE_ITEM.PO_NO,'')													as CustRef, 
	SO_LINE_ITEM.PICK_ID															as PickSlip,
	ISNULL(OrderShipTo.ShippingComment,'')											as DespNote,
	CONVERT(VARCHAR(8),PACKAGE.SHIP_DATE,3) 										as DespDate, 
	'Item'																			as FeeType, 
	CAST(PAPSIZE.[INVENTORY CODE] as nvarchar)										as Item, 
	SO_LINE_ITEM.PACK_QTY															as Qty,
	PAPSIZE.[UNIT OF ISSUE]															as UOI,
	PAPSIZE.[UNIT ISSUE DESC]														as UnitOfIssDesc, 
	((SO_LINE_ITEM_PRICE.UNIT_PRICE * SO_LINE_ITEM.PACK_QTY))		
																					as SellExcl, 
	((SO_LINE_ITEM_PRICE.UNIT_PRICE * SO_LINE_ITEM.PACK_QTY) 
		* 1.1)																		as SellIncl, 
	RECIPIENT.COMPANY_NAME															as DeliverTo, 
	(RECIPIENT.FIRST_NAME 
		+ ' ' 
		+ RECIPIENT.LAST_NAME)														as AttentionTo, 
	ISNULL(ShipToAddress.ADDR_1,'')													as Address1, 
	ISNULL(ShipToAddress.ADDR_2,'')													as Address3, 
	ISNULL(ShipToAddress.ADDR_3,'')													as Address3, 
	ISNULL(ShipToAddress.CITY,'')													as Suburb, 
	ISNULL(ShipToAddress.STATE_CODE,'')												as "State", 
	ISNULL(ShipToAddress.ZIP_CODE,'')												as PostCode, 
	ISNULL(ShipToCountry.COUNTRY_NAME,'')											as Country, 
	(SELECT SUM(ACTUAL_WEIGHT) 
	 FROM [LiveData].[dbo].PACKAGE 
	 WHERE PICK_ID = SO_LINE_ITEM.PICK_ID)											as Weight, 
	(SELECT COUNT(1) 
	 FROM [LiveData].[dbo].PACKAGE 
	 WHERE PACKAGE.PICK_ID=SO_LINE_ITEM.PICK_ID)									as Packages
FROM  [LiveData].[dbo].[SO_LINE_ITEM]
	INNER JOIN [LiveData].[dbo].SALES_ORDER											ON SALES_ORDER.SO_ID			= SO_LINE_ITEM.SO_ID
	INNER JOIN [LiveData].[dbo].[RECIPIENT]											ON RECIPIENT.RECIP_ID			= SALES_ORDER.SHIP_TO_ID
	INNER JOIN [LiveData].[dbo].FFADDRESS ShipToAddress								ON ShipToAddress.ADDRESS_ID 	= Recipient.DEF_ADDRESS_ID 
	INNER JOIN [LiveData].[dbo].COUNTRY ShipToCountry								ON ShipToCountry.COUNTRY_NUMBER = ShipToAddress.COUNTRY_ID 
	INNER JOIN [LiveData].[dbo].CUSTOMER											ON CUSTOMER.CUST_ID				= SO_LINE_ITEM.CUST_ID
	INNER JOIN [LiveData].[dbo].DEBTOR												ON DEBTOR.[DATAFLEX RECNUM ONE] = CUSTOMER.DEBTOR_RECNUM
	INNER JOIN [LiveData].[dbo].PAPSIZE												ON PAPSIZE.[CODE]				= cast(SO_LINE_ITEM.ITEM_NO as char) 
	LEFT JOIN [LiveData].[dbo].OrderShipTo											ON OrderShipTo.OrderId			= SALES_ORDER.SO_ID
	LEFT JOIN [LiveData].[dbo].PACKAGE												ON PACKAGE.SO_ID				= SALES_ORDER.SO_ID
	INNER JOIN [LiveData].[dbo].SO_LINE_ITEM_PRICE									ON (SO_LINE_ITEM_PRICE.SO_ID	= SO_LINE_ITEM.SO_ID) 
		AND (SO_LINE_ITEM_PRICE.LINE_ITEM_NO = SO_LINE_ITEM.LINE_ITEM_NO)
	LEFT JOIN livedata.dbo.PICK PICKS												ON PICKS.SO_ID					= SALES_ORDER.SO_ID 
WHERE ISNULL(SO_LINE_ITEM.PICK_ID, '0') >		0 
	AND ISNULL(SO_LINE_ITEM.ITEM_NO,0)	<>		0 
	--and (PACKAGE.SHIP_DATE > = @Datetime1 and PACKAGE.SHIP_DATE <= @Datetime2)
	and PICKS.PICK_STATUS = '21'
	and SO_LINE_ITEM.[PACK_QTY] >= 1


UNION 
/* Shipping */
SELECT 
	'6'				as Tag,
	'Ship Ref:' + PACKAGE.TRACKING_NO												as Description,
	SO_CHARGE.AMOUNT																as UnitPrice, 
	DEBTOR.[DATAFLEX RECNUM ONE]													as ID,
	DEBTOR.[AC NO]																	as Customer,
	SALES_ORDER.BILL_TO_ID															as CustomerId, 
	SALES_ORDER.CUST_ID																as ParentId, 
	DEBTOR.NAMES																	as Parent, 
	''																				as CostCentre,
	SALES_ORDER.SO_ID																as OrderNum, 
	SALES_ORDER.CUST_SO_ID															as OrderWareNum, 
	''																				as CustRef, 
	PACKAGE.PICK_ID																	as PickSlip,
	''																				as DespNote, 
	CONVERT(VARCHAR(8),PACKAGE.SHIP_DATE,3)											as DespDate, 
	'Shipping'																		as FeeType, 
	cast('COURIER' as nvarchar)														as Item, 
	'1'																				as Qty,
	'1'																				as UOI	, 
	'Each'																			as UnitOfIssDesc, 
	SO_CHARGE.AMOUNT																as SellExcl, 
	(SO_CHARGE.AMOUNT *  1.1)														as SellIncl, 
	ISNULL(Recipient.COMPANY_NAME,'')												as DeliverTo, 
	ISNULL((RECIPIENT.FIRST_NAME 
		+ ' ' 
		+ RECIPIENT.LAST_NAME),'')													as AttentionTo,  
	ISNULL(ShipToAddress.ADDR_1,'')													as Address1, 
	ISNULL(ShipToAddress.ADDR_2,'')													as Address3, 
	ISNULL(ShipToAddress.ADDR_3,'')													as Address3, 
	ISNULL(ShipToAddress.CITY,'')													as Suburb, 
	ISNULL(ShipToAddress.STATE_CODE,'')												as "State", 
	ISNULL(ShipToAddress.ZIP_CODE,'')												as PostCode, 
	ISNULL(ShipToCountry.COUNTRY_NAME,'')											as Country,
	PACKAGE.ACTUAL_WEIGHT															as Weight, 
	'1'																				as Packages
FROM [LiveData].[dbo].SO_CHARGE
	INNER JOIN [LiveData].[dbo].SALES_ORDER											ON SALES_ORDER.SO_ID			= SO_CHARGE.SO_ID
	INNER JOIN [LiveData].[dbo].RECIPIENT											ON RECIPIENT.RECIP_ID			= SALES_ORDER.SHIP_TO_ID
	INNER JOIN [LiveData].[dbo].FFADDRESS ShipToAddress								ON ShipToAddress.ADDRESS_ID 	= Recipient.DEF_ADDRESS_ID 
	INNER JOIN [LiveData].[dbo].COUNTRY ShipToCountry								ON ShipToCountry.COUNTRY_NUMBER = ShipToAddress.COUNTRY_ID 
	INNER JOIN [LiveData].[dbo].CUSTOMER											ON CUSTOMER.CUST_ID				= SALES_ORDER.CUST_ID
	INNER JOIN [LiveData].[dbo].DEBTOR												ON DEBTOR.[DATAFLEX RECNUM ONE] = CUSTOMER.DEBTOR_RECNUM
	LEFT JOIN [LiveData].[dbo].PACKAGE												ON PACKAGE.PACKAGE_ID			= SO_CHARGE.PackageID
	LEFT JOIN [LiveData].[dbo].SHIPPING_MODE										ON SHIPPING_MODE.SHIP_MODE_ID	= PACKAGE.SHIP_MODE_ID
	LEFT JOIN livedata.dbo.PICK PICKS												ON PICKS.SO_ID					= SO_CHARGE.SO_ID 
WHERE ISNULL(SO_CHARGE.SO_ID, '0')		>		0 
	--and (PACKAGE.SHIP_DATE > = @Datetime1 and PACKAGE.SHIP_DATE <= @Datetime2)
	and PICKS.PICK_STATUS = '21'
	and PACKAGE.SHIP_DATE IS NOT NULL
Order by SALES_ORDER.SO_ID,1 ASC