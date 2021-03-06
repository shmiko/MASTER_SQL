DECLARE @Datetime1 varchar(19), @DateTime2 varchar(19)
SET @Datetime1 = CONVERT(VARCHAR, DATEADD(DAY, -33 ,SYSDATETIME()), 121) -- Get System DateTime minus 1 days
SET @Datetime2 = CONVERT(VARCHAR, DATEADD(DAY, 0 ,SYSDATETIME()), 121)  -- Get System DateTime plus 0 days

SELECT '5',
	--ABS(Checksum(NewID()) % 4) + 3					as Tag,
	--(SELECT CAST(RAND() * 10 AS INT))				as Tag,
	SO_LINE_ITEM.ITEM_DESCRIPTION					as Description,
	SO_LINE_ITEM_PRICE.UNIT_PRICE					as UnitPrice,
	DEBTOR.[DATAFLEX RECNUM ONE]					as ID,
	DEBTOR.[AC NO]									as Customer,
	SALES_ORDER.BILL_TO_ID							as CustomerId, 
	SALES_ORDER.CUST_ID								as ParentId, 
	DEBTOR.NAMES									as Parent, 
	SO_LINE_ITEM.COST_CENTER						as CostCentre,
	SALES_ORDER.SO_ID								as OrderNum, 
	SALES_ORDER.CUST_SO_ID							as OrderWareNum, 
	SO_LINE_ITEM.PO_NO								as CustRef, 
	SO_LINE_ITEM.PICK_ID							as PickSlip,
	OrderShipTo.ShippingComment						as DespNote,
	CONVERT(VARCHAR(8),PACKAGE.SHIP_DATE,3) 			as DespDate, 
	'Item'											as FeeType, 
	CAST(PAPSIZE.[INVENTORY CODE] as nvarchar)		as Item, 
	 
	SO_LINE_ITEM.PACK_QTY							as Qty,
	PAPSIZE.[UNIT OF ISSUE]							as UOI,
	PAPSIZE.[UNIT ISSUE DESC]						as UnitOfIssDesc, 
	 
	((SO_LINE_ITEM_PRICE.UNIT_PRICE * SO_LINE_ITEM.PACK_QTY))		
													as SellExcl, 
	((SO_LINE_ITEM_PRICE.UNIT_PRICE * SO_LINE_ITEM.PACK_QTY) 
		* 1.1)										as SellIncl, 
	RECIPIENT.COMPANY_NAME							as DeliverTo, 
	(RECIPIENT.FIRST_NAME 
		+ ' ' 
		+ RECIPIENT.LAST_NAME)						as AttentionTo, 
	ISNULL(ShipToAddress.ADDR_1,'')					as Address1, 
	ISNULL(ShipToAddress.ADDR_2,'')					as Address3, 
	ISNULL(ShipToAddress.ADDR_3,'')					as Address3, 
	ISNULL(ShipToAddress.CITY,'')					as Suburb, 
	ISNULL(ShipToAddress.STATE_CODE,'')				as "State", 
	ISNULL(ShipToAddress.ZIP_CODE,'')				as PostCode, 
	ISNULL(ShipToCountry.COUNTRY_NAME,'')			as Country, 
	(SELECT SUM(ACTUAL_WEIGHT) 
	 FROM [LiveData].[dbo].PACKAGE 
	 WHERE PICK_ID = SO_LINE_ITEM.PICK_ID)			as Weight, 
	(SELECT COUNT(1) 
	 FROM [LiveData].[dbo].PACKAGE 
	 WHERE PACKAGE.PICK_ID=SO_LINE_ITEM.PICK_ID)	as Packages
FROM  [LiveData].[dbo].[SO_LINE_ITEM]
	INNER JOIN [LiveData].[dbo].SALES_ORDER			ON SALES_ORDER.SO_ID			= SO_LINE_ITEM.SO_ID
	INNER JOIN [LiveData].[dbo].[RECIPIENT]			ON RECIPIENT.RECIP_ID			= SALES_ORDER.SHIP_TO_ID
	INNER JOIN [LiveData].[dbo].FFADDRESS ShipToAddress				ON ShipToAddress.ADDRESS_ID 	= Recipient.DEF_ADDRESS_ID 
	INNER JOIN [LiveData].[dbo].COUNTRY ShipToCountry				ON ShipToCountry.COUNTRY_NUMBER = ShipToAddress.COUNTRY_ID 
	INNER JOIN [LiveData].[dbo].CUSTOMER			ON CUSTOMER.CUST_ID				= SO_LINE_ITEM.CUST_ID
	INNER JOIN [LiveData].[dbo].DEBTOR				ON DEBTOR.[DATAFLEX RECNUM ONE] = CUSTOMER.DEBTOR_RECNUM
	INNER JOIN [LiveData].[dbo].PAPSIZE				ON PAPSIZE.[CODE]				= cast(SO_LINE_ITEM.ITEM_NO as char) 
	--INNER JOIN[LiveData].[dbo].RECIPIENT			ON RECIPIENT.RECIP_ID			= SALES_ORDER.SHIP_TO_ID
	LEFT JOIN [LiveData].[dbo].OrderShipTo			ON OrderShipTo.OrderId			= SALES_ORDER.SO_ID
	LEFT JOIN [LiveData].[dbo].PACKAGE				ON PACKAGE.SO_ID				= SALES_ORDER.SO_ID
	INNER JOIN [LiveData].[dbo].SO_LINE_ITEM_PRICE	ON (SO_LINE_ITEM_PRICE.SO_ID	= SO_LINE_ITEM.SO_ID) 
		AND (SO_LINE_ITEM_PRICE.LINE_ITEM_NO = SO_LINE_ITEM.LINE_ITEM_NO)
	LEFT JOIN livedata.dbo.PICK PICKS				ON PICKS.SO_ID					= SALES_ORDER.SO_ID 
WHERE ISNULL(SO_LINE_ITEM.PICK_ID, '0') >		0 
	AND ISNULL(SO_LINE_ITEM.ITEM_NO,0)	<>		0 
	and (PACKAGE.SHIP_DATE > = @Datetime1 and PACKAGE.SHIP_DATE <= @Datetime2)
	and PICKS.PICK_STATUS = '21'
Order by SALES_ORDER.SO_ID,1 ASC