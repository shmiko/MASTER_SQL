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


/* Items */
SELECT
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
	(SELECT TOP (1) SHIP_DATE 
	 FROM [LiveData].[dbo].PACKAGE 
	 WHERE PICK_ID=SO_LINE_ITEM.PICK_ID)			as DespDate, 
	'Item'											as FeeType, 
	SO_LINE_ITEM.ITEM_NO							as Item, 
	SO_LINE_ITEM.ITEM_DESCRIPTION					as Description, 
	SO_LINE_ITEM.PACK_QTY							as Qty,
	PAPSIZE.[UNIT OF ISSUE]							as UOI,
	PAPSIZE.[UNIT ISSUE DESC]						as UnitOfIssDesc, 
	SO_LINE_ITEM_PRICE.UNIT_PRICE					as UnitPrice, 
	((SO_LINE_ITEM_PRICE.UNIT_PRICE * SO_LINE_ITEM.PACK_QTY) 
		+ SO_LINE_ITEM_PRICE.SHIPPING_HANDLING)		as SellExcl, 
	((SO_LINE_ITEM_PRICE.UNIT_PRICE * SO_LINE_ITEM.PACK_QTY) 
		+ SO_LINE_ITEM_PRICE.SHIPPING_HANDLING 
		+ ISNULL(SO_LINE_ITEM_PRICE.SALES_TAX,0))	as SellIncl, 
	RECIPIENT.COMPANY_NAME							as DeliverTo, 
	(RECIPIENT.FIRST_NAME 
		+ ' ' 
		+ RECIPIENT.LAST_NAME)						as AttentionTo, 
	(SELECT SUM(ACTUAL_WEIGHT) 
	 FROM [LiveData].[dbo].PACKAGE 
	 WHERE PICK_ID = SO_LINE_ITEM.PICK_ID)			as Weight, 
	(SELECT COUNT(1) 
	 FROM [LiveData].[dbo].PACKAGE 
	 WHERE PACKAGE.PICK_ID=SO_LINE_ITEM.PICK_ID)	as Packages
FROM  [LiveData].[dbo].[SO_LINE_ITEM]
	INNER JOIN [LiveData].[dbo].SALES_ORDER			ON SALES_ORDER.SO_ID			= SO_LINE_ITEM.SO_ID
	INNER JOIN [LiveData].[dbo].CUSTOMER			ON CUSTOMER.CUST_ID				= SO_LINE_ITEM.CUST_ID
	INNER JOIN [LiveData].[dbo].DEBTOR				ON DEBTOR.[DATAFLEX RECNUM ONE] = CUSTOMER.DEBTOR_RECNUM
	INNER JOIN [LiveData].[dbo].PAPSIZE				ON PAPSIZE.[CODE]				= cast(SO_LINE_ITEM.ITEM_NO as char) 
	INNER JOIN[LiveData].[dbo].RECIPIENT			ON RECIPIENT.RECIP_ID			= SO_LINE_ITEM.SHIP_TO_ID
	LEFT JOIN [LiveData].[dbo].OrderShipTo			ON OrderShipTo.OrderId			= SALES_ORDER.SO_ID
	LEFT JOIN [LiveData].[dbo].PACKAGE				ON PACKAGE.SO_ID				= SALES_ORDER.SO_ID
	INNER JOIN [LiveData].[dbo].SO_LINE_ITEM_PRICE	ON (SO_LINE_ITEM_PRICE.SO_ID	= SO_LINE_ITEM.SO_ID) 
		AND (SO_LINE_ITEM_PRICE.LINE_ITEM_NO = SO_LINE_ITEM.LINE_ITEM_NO)
WHERE ISNULL(SO_LINE_ITEM.PICK_ID, '0') >		0 
	AND ISNULL(SO_LINE_ITEM.ITEM_NO,0)	<>		0 
	AND (SO_LINE_ITEM.CREATED_DATE		>=		@FromShipDate 
	AND SO_LINE_ITEM.CREATED_DATE		<=		@ToShipDate)
	AND (SALES_ORDER.CUST_SO_ID			LIKE	@JavelinNumber
	OR  SALES_ORDER.CUST_SO_ID			=		@OWNumber)