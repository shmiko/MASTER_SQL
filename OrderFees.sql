DECLARE @Datetime1 varchar(19), @DateTime2 varchar(19)
SET @Datetime1 = CONVERT(VARCHAR, DATEADD(DAY, -33 ,SYSDATETIME()), 121) -- Get System DateTime minus 1 days
SET @Datetime2 = CONVERT(VARCHAR, DATEADD(DAY, 0 ,SYSDATETIME()), 121)  -- Get System DateTime plus 0 days

/* order entry fees */
SELECT 
	'3'																				as Tag,
	o.ORIGIN_NAME + ' Order Entry Fee'																as "Description",
	po.SOOriginCharge																as UnitPrice,
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
	CONVERT(VARCHAR(8),SALES_ORDER.CREATED_DATE,3)																as DespDate, 
	o.ORIGIN_NAME + ' Order Entry Fee'																as FeeType, 
	CAST('FEEORDER'	as nvarchar)													as Item, 
	--''																				as InventoryCode,
	 
	'1'																				as Qty,
	--[bsg_support].[dbo].[ufnGetPickLineCount](SALES_ORDER.SO_ID)					as OrderQty,
	'1'																				as UOI, 
	'Each'																			as UnitOfIssDesc, 
	 
	po.SOOriginCharge 	as SellExcl, 
	(po.SOOriginCharge *  1.1)														as SellIncl, 
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

	LEFT OUTER JOIN livedata.dbo.FFPROJECT ffp on ffp.PROJ_ID = SALES_ORDER.PROJ_ID
	LEFT OUTER JOIN livedata.dbo.SO_ORIGIN o on o.SO_ORIGIN_ID = SALES_ORDER.SO_ORIGIN_ID
	LEFT OUTER JOIN livedata.dbo.ProjSOOrigin po on po.SOOriginId = SALES_ORDER.SO_ORIGIN_ID
Where DEBTOR.[AC NO] <> 'HOUSEACC'
	and SALES_ORDER.SO_ORIGIN_ID <> '0'
	and po.SOOriginCharge <> '0'
	and (SALES_ORDER.CREATED_DATE > = @Datetime1 and SALES_ORDER.CREATED_DATE <= @Datetime2)
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
	Order by SALES_ORDER.SO_ID,1 ASC