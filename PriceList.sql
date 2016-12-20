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

/* Pickfees  */
SELECT 
	DEBTOR.[DATAFLEX RECNUM ONE]					as ID,
	DEBTOR.[AC NO]									as Customer,
	SALES_ORDER.BILL_TO_ID							as CustomerId, 
	SALES_ORDER.CUST_ID								as ParentId, 
	DEBTOR.NAMES									as Parent, 
	''												as CostCentre,
	SALES_ORDER.SO_ID								as OrderNum, 
	SALES_ORDER.CUST_SO_ID							as OrderWareNum, 
	''												as CustRef, 
	''												as PickSlip,
	''												as DespNote,
	 FF_TRANS.TIME_START							as DespDate, 
	 'PriceList'									as FeeType, 
	FF_TRANS.TIMELINE_ID							as Item, 
	FF_TIMELINE.TIMELINE							as Description, 
	FF_TRANS.ACT_QTY								as Qty,
	''												as UOI, 
	'Each'											as UnitOfIssDesc, 
	FF_TRANS.ACT_PPU								as UnitPrice, 
	(FF_TRANS.ACT_PPU * FF_TRANS.ACT_QTY)			as SellExcl, 
	((FF_TRANS.ACT_PPU * FF_TRANS.ACT_QTY) 
			+ ISNULL(FF_TRANS.SalesTax,0))			as SellIncl, 
	''												as DeliverTo, 
	''												as AttentionTo, 
	'0'												as Weight, 
	'0'												as Packages
FROM [LiveData].[dbo].FF_TRANS
	INNER JOIN [LiveData].[dbo].SALES_ORDER			ON SALES_ORDER.SO_ID			= FF_TRANS.SO_ID
	INNER JOIN [LiveData].[dbo].FF_TIMELINE			ON FF_TIMELINE.TIMELINE_ID		= FF_TRANS.TIMELINE_ID
	INNER JOIN [LiveData].[dbo].CUSTOMER			ON CUSTOMER.CUST_ID				= SALES_ORDER.CUST_ID
	INNER JOIN [LiveData].[dbo].DEBTOR				ON DEBTOR.[DATAFLEX RECNUM ONE] = CUSTOMER.DEBTOR_RECNUM
WHERE ISNULL(FF_TRANS.SO_ID, '0')	>	0 
	AND (FF_TRANS.TIME_START			>=		@FromShipDate 
	AND FF_TRANS.TIME_START				<=		@ToShipDate)
	AND (SALES_ORDER.CUST_SO_ID			like		@JavelinNumber
	OR  SALES_ORDER.CUST_SO_ID			=		@OWNumber)