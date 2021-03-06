USE [bsg_support]
GO
/****** Object:  StoredProcedure [dbo].[WMS2JAV_SOU]    Script Date: 21/11/2016 3:45:58 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[WMS2JAV_SOU](@Customer VARCHAR(8) = NULL,@StartEditDate DATETIME,@EndEditDate DATETIME) 
AS BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @PRINCIPALTABLE TABLE (
            C_ID int PRIMARY KEY IDENTITY, 
			soh varchar(3),     
            customerID varchar(10),
            supplier varchar(30),
			externalReference varchar(130),
			orderNumber varchar(8),
            customerID2 varchar(8),
			customerReference varchar(50),
			orderdescription varchar(50),
			forAttention varchar(50),
			deliverTo varchar(50),
			delCode int default(1),
			shipToAddress1 varchar(61),
			shipToAddress2 varchar(122),
			shipToCity varchar(40),
			shipToStateCode varchar(10),
			shipToCountry varchar(25),
			shipToZipCode varchar(11),
			rep varchar(50),
			requiredDate datetime,
			orderAddDate date,
			orderAddTime time,
			orderAddedBy varchar(50),
			orderStatus varchar(10),
			spareString2 varchar(4),
			spareString4 varchar(4),
			projectCode varchar(10),
			campaign varchar(10),
			sol varchar(3),
			customerID3 varchar(10),
            supplier2 varchar(30),
			externalReference2 varchar(130),
			lineNumber int,
			sku varchar(50),
			skuDescription varchar(50),
			skuNote1 varchar(50),
			skuNote2 varchar(50),
			uom varchar(10),
			skuVersion varchar(50),
			warehouseLocation varchar(30),
			lineOrderQTY int,
			lineBackOrderQTY int,
			lineDespQTY int,
			lineInvoiceQTY int,
			lineStatus varchar(10)
			 )
	INSERT INTO @PRINCIPALTABLE (
			soh,     
            customerID,
            supplier,
			externalReference,
			orderNumber,
            customerID2,
			customerReference,
			orderdescription,
			forAttention,
			deliverTo,
			delCode,
			shipToAddress1,
			shipToAddress2,
			shipToCity,
			shipToStateCode,
			shipToCountry,
			shipToZipCode,
			rep,
			requiredDate,
			orderAddDate,
			orderAddTime,
			orderAddedBy,
			orderStatus,
			spareString2,
			spareString4,
			projectCode,
			campaign,
			sol,
			customerID3,
            supplier2,
			externalReference2,
			lineNumber,
			sku,
			skuDescription,
			skuNote1,
			skuNote2,
			uom,
			skuVersion,
			warehouseLocation,
			lineOrderQTY,
			lineBackOrderQTY,
			lineDespQTY,
			lineInvoiceQTY,
			lineStatus)
	SELECT 
		--SH Records as SOH
		'SOH' SOH,
		--ISNULL(Cust.[DATAFLEX RECNUM ONE],'') 
		ISNULL(Cust.[AC NO],'') customer,
		CASE WHEN Cust.StoreNum = 'IVEO' Then 'IVE'
			 ELSE '1DB'
		END AS supplier,
		ISNULL(Ord.[EXTERNAL_CMT],'') externalReference,
		Ord.SO_ID orderNumber,
		ISNULL(Cust.[AC NO],'') customer2,
		'' As customerReference,
		'' As orderdescription,
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
		ISNULL(Cust.[AC NO],'') customer3,
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
	FROM LiveData.dbo.SALES_ORDER Ord with (nolock) 
		INNER JOIN LiveData.dbo.BATCH Inp with (nolock) ON Ord.BATCH_ID = Inp.BATCH_ID 
		left outer join  LiveData.dbo.RECIPIENT OrderBy with (nolock) On OrderBy.RECIP_ID = Ord.ORDER_BY_ID 
		left outer join LiveData.dbo.RECIPIENT ShipTo with (nolock) On ShipTo.RECIP_ID = Ord.SHIP_TO_ID 
		INNER JOIN LiveData.dbo.FFADDRESS ShipToAddress with (nolock) on ShipToAddress.ADDRESS_ID = ShipTo.DEF_ADDRESS_ID 
		INNER JOIN LiveData.dbo.COUNTRY ShipToCountry with (nolock) on ShipToCountry.COUNTRY_ID = ShipToAddress.COUNTRY_ID 
		INNER JOIN LiveData.dbo.SO_LINE_ITEM Sol with (nolock) ON Ord.SO_ID = SOl.SO_ID 
		left outer join LiveData.dbo.DEBTOR Cust with (nolock)  ON Cust.[DATAFLEX RECNUM ONE] = Ord.CUST_ID
		INNER JOIN LiveData.dbo.PAPSIZE Sku with (nolock) ON Sku.[INVENTORY CODE] = Sol.INVENTORY_CODE
		left outer join LiveData.dbo.FFSTATUS statl on statl.STATUS_ID = sol.STATUS_ID 
		left outer join LiveData.dbo.FFSTATUS stath on stath.STATUS_ID = Ord.STATUS_ID 
	WHERE Ord.[MODIFIED_DATE] >= @StartEditDate AND Ord.[MODIFIED_DATE] <= @EndEditDate
	AND Cust.[AC NO] = @Customer
	ORDER BY cast(Ord.[MODIFIED_DATE] as Date) Desc;


END

SELECT * FROM @PRINCIPALTABLE