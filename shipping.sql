DECLARE @FromShipDate as date
DECLARE @ToShipDate as date
DECLARE @JavelinNumber as varchar(10)
SELECT @FromShipDate = '09/01/2016'   
SELECT @ToShipDate = '12/16/2016'  --Note:  Make this +1 days from your last ship date
SET @JavelinNumber = 'W1693170'

SELECT DEBTOR.[DATAFLEX RECNUM ONE] as ID,DEBTOR.[AC NO] as Customer,SALES_ORDER.BILL_TO_ID as CustomerId, SALES_ORDER.CUST_ID as ParentId, DEBTOR.NAMES as Parent, '' as CostCentre,
SALES_ORDER.SO_ID as OrderNum, SALES_ORDER.CUST_SO_ID as OrderWareNum, '' as CustRef, PACKAGE.PICK_ID as PickSlip,
'' as DespNote, PACKAGE.SHIP_DATE as DespDate, 'Shipping' as FeeType, 
'' as Item, SHIPPING_MODE.SHIP_MODE_DESC as Description, '1' as Qty,
'' as UOI	, '' as UnitOfIssDesc, SO_CHARGE.AMOUNT as UnitPrice, 
SO_CHARGE.AMOUNT as SellExcl, (SO_CHARGE.AMOUNT + ISNULL(SO_CHARGE.SALES_TAX,0)) as SellIncl, '' as DeliverTo, 
'' as AttentionTo, 
PACKAGE.ACTUAL_WEIGHT as Weight, '1' as Packages
FROM [LiveData].[dbo].SO_CHARGE
	INNER JOIN [LiveData].[dbo].SALES_ORDER ON SALES_ORDER.SO_ID = SO_CHARGE.SO_ID
	INNER JOIN [LiveData].[dbo].CUSTOMER ON CUSTOMER.CUST_ID = SALES_ORDER.CUST_ID
	INNER JOIN [LiveData].[dbo].DEBTOR ON DEBTOR.[DATAFLEX RECNUM ONE] = CUSTOMER.DEBTOR_RECNUM
	LEFT JOIN [LiveData].[dbo].PACKAGE ON PACKAGE.PACKAGE_ID = SO_CHARGE.PackageID
	LEFT JOIN [LiveData].[dbo].SHIPPING_MODE ON SHIPPING_MODE.SHIP_MODE_ID = PACKAGE.SHIP_MODE_ID
WHERE ISNULL(SO_CHARGE.SO_ID, '0') > 0 AND (SO_CHARGE.MODIFIED_DATE >= @FromShipDate AND SO_CHARGE.MODIFIED_DATE <= @ToShipDate)