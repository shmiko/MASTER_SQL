DECLARE	@StartEditDate DATETIME,@EndEditDate DATETIME,@Customer varchar(8)
	Set	@StartEditDate = N'2016-11-14 12:40:07.00'
	Set	@EndEditDate = N'2016-11-21 12:40:07.00'	
	Set @Customer = 'N-WESIND'
	SELECT 
		--SH Records as SOH
		'SOH' SOH,
		ISNULL(Cust.[DATAFLEX RECNUM ONE],'') customerID,
		CASE WHEN Cust.StoreNum = 'IVEO' Then 'IVE'
			 ELSE '1DB'
		END AS supplier,
		ISNULL(soaddl.FIELD_VALUE,'') externalReference,
		Ord.SO_ID orderNumber,
		ISNULL(Cust.[AC NO],'') customerID2,
		Ord.CUST_ID As customerReference,
		'' As orderDescription,
		COALESCE(OrderBy.FIRST_NAME,'') + ' ' + COALESCE(OrderBy.LAST_NAME,'') ForAttention, 
		ISNULL(OrderBy.COMPANY_NAME,'') DeliverTo, 
		'' As DelCode,
		ISNULL(ShipToAddress.ADDR_1,'') ShipToAddress1, 
		ISNULL(ShipToAddress.ADDR_2,'') + ' ' + ISNULL(ShipToAddress.ADDR_3,'') ShipToAddress2, 
		ISNULL(ShipToAddress.CITY,'') ShipToCity, 
		ISNULL(ShipToAddress.STATE_CODE,'') ShipToStateCode, 
		ISNULL(ShipToCountry.COUNTRY_CODE3,'') ShipToCountry,
		ISNULL(ShipToAddress.ZIP_CODE,'') ShipToZipCode, 
		'' Rep,
		Ord.[NEED_DATE] RequiredDate,
		cast(Ord.CREATED_DATE as Date) OrderAddDate, 
		CAST(Ord.CREATED_DATE AS TIME(0)) OrderAddTime,
		Ord.[CREATED_BY] OrderAddedBy,
		CASE WHEN stath.[STATUS_DESC] in ('Sales Order Created','Sales Order Open') then 'Live'
			 WHEN stath.[STATUS_DESC] = 'Sales Order Complete' then 'Despatched'
			 WHEN stath.[STATUS_DESC] = 'Sales Order Cancel' then 'Cancelled'
			 WHEN stath.[STATUS_DESC] = 'Sales Order Line Item Shipped' then 'Closed' -- ???
			 WHEN stath.[STATUS_DESC] = 'Sales Order Line Item Released and Pick Confirmed' then 'Awaiting'
			 ELSE ''
		END AS  OrderStatus,
		'' As SpareString2,
		'' As SpareString4,
		'' As ProjectCode,
		'' As Campaign,
		--SD Records as SOL
		'SOL' SOL,
		ISNULL(Cust.[AC NO],'') customerID3,
		CASE WHEN Cust.StoreNum = 'IVEO' Then 'IVE'
			 ELSE '1DB'
		END AS supplier2,
		ISNULL(Ord.[EXTERNAL_CMT],'') externalReference2,
		Sol.LINE_ITEM_NO As LineNumber,
		ISNULL(Sol.INVENTORY_CODE,'') sku, 
		ISNULL(Sku.Description1, '') As SkuDescription,
		Sol.ITEM_NOTES As SkuNote1,
		'' As SkuNote2,
		ISNULL(Sku.[PO UOM DESC],'') UOM,
		ISNULL(Sol.[REVISION_CODE],'') SkuVersion,
		'' As WarehouseLocation,
		ISNULL(Sol.[GROSS_QTY],0) LineOrderQTY,
		ISNULL(Sol.BO_QTY,0) LineBackOrderQTY,
		'' As LineDespQTY, 
		null As LineInvoiceQTY,
		CASE WHEN statl.[STATUS_DESC] in ('Sales Order Line Item Committed','Sales Order Line Item Released','Confirmed for Pick Order') then 'Live'
			 WHEN statl.[STATUS_DESC] = 'Sales Order Line Item Shipped' then 'Despatched'
			 WHEN statl.[STATUS_DESC] = 'Sales Order Line Item Cancelled' then 'Cancelled'
			 WHEN statl.[STATUS_DESC] = 'SOE_CLOSED' then 'Closed' -- ???
			 WHEN statl.[STATUS_DESC] in ('Sales Order Line Item Released Pending Pick Confirmation','Sales Order Line Item Released and Pick Confirmed') then 'Awaiting'
			 ELSE ''
		END AS LineStatus
	FROM					LiveData.dbo.SALES_ORDER Ord with (nolock) 
		INNER JOIN			LiveData.dbo.BATCH Inp with (nolock) ON Ord.BATCH_ID = Inp.BATCH_ID 
		left outer join		LiveData.dbo.RECIPIENT OrderBy with (nolock) On OrderBy.RECIP_ID = Ord.ORDER_BY_ID 
		left outer join		LiveData.dbo.RECIPIENT ShipTo with (nolock) On ShipTo.RECIP_ID = Ord.SHIP_TO_ID 
		INNER JOIN			LiveData.dbo.FFADDRESS ShipToAddress with (nolock) on ShipToAddress.ADDRESS_ID = ShipTo.DEF_ADDRESS_ID 
		INNER JOIN			LiveData.dbo.COUNTRY ShipToCountry with (nolock) on ShipToCountry.COUNTRY_ID = ShipToAddress.COUNTRY_ID 
		INNER JOIN			LiveData.dbo.SO_LINE_ITEM Sol with (nolock) ON Ord.SO_ID = SOl.SO_ID 
		left outer join		LiveData.dbo.DEBTOR Cust with (nolock)  ON Cust.[DATAFLEX RECNUM ONE] = Ord.CUST_ID
		INNER JOIN			LiveData.dbo.PAPSIZE Sku with (nolock) ON Sku.[INVENTORY CODE] = Sol.INVENTORY_CODE
		left outer join		LiveData.dbo.FFSTATUS statl with (nolock) on statl.STATUS_ID = sol.STATUS_ID 
		left outer join		LiveData.dbo.FFSTATUS stath with (nolock) on stath.STATUS_ID = Ord.STATUS_ID 
		inner join			LiveData.dbo.FFProject ff with (nolock) on (ff.CUST_ID = Cust.[DATAFLEX RECNUM ONE] and ff.ACTIVE = 1)
		inner join			LiveData.dbo.PROJ_VAR_FIELDS pvf with (nolock) on (pvf.CUST_ID = Cust.[DATAFLEX RECNUM ONE] and pvf.PROJ_ID = ff.PROJ_ID)
		inner join			LiveData.dbo.VAR_FIELDS vf with (nolock) on (vf.CUST_ID = Cust.[DATAFLEX RECNUM ONE] and vf.FIELD_ID = pvf.FIELD_ID and vf.ACTIVE = 1)
		inner join			LiveData.dbo.SO_ADDL soaddl  with (nolock) on soaddl.SO_ID = Ord.SO_ID 
	WHERE Ord.[MODIFIED_DATE] >= @StartEditDate AND Ord.[MODIFIED_DATE] <= @EndEditDate
	AND Cust.[AC NO] = @Customer
	AND soaddl.FIELD_NAME = 'EXTREFERENCE'
	ORDER BY cast(Ord.[MODIFIED_DATE] as Date) Desc;