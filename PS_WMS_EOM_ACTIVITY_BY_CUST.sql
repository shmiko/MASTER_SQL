DECLARE @Datetime1 varchar(19), @DateTime2 varchar(19)
SET @Datetime1 = CONVERT(VARCHAR, DATEADD(DAY, -33 ,SYSDATETIME()), 121) -- Get System DateTime minus 1 days
SET @Datetime2 = CONVERT(VARCHAR, DATEADD(DAY, 0 ,SYSDATETIME()), 121)  -- Get System DateTime plus 0 days

Select 
s.CUST_ID as CustomerID,
d.[AC NO] as Customer,s.SO_ID as SO#, 
l.CUST_SO_ID as SOJavPrism,
l.LINE_ITEM_NO as SOLineNo,
l.INVENTORY_CODE as LineItemCode,
l.ITEM_DESCRIPTION as LineItemDesc,
s.PICK_ID as PickID, 
s.PICK_STATUS as PickStatus, 
f.STATUS_DESC as StatusDesc,
l.PICK_QTY as LinePickQty,
s.PICK_BY as PickBy, 
s.PACK_DATE as PackDate, 
s.PICK_SHIPPED as PIckShipped,
pp.ACTUAL_CHARGE as ActCharge,
pp.ACTUAL_WEIGHT as ActWeight,
pp.SHIPPED_BY as ShipBy,
pp.SHIP_DATE as ShipDate,
pp.TRACKING_NO as TrackNo,
pp.PACKAGE_ID as PacjkageID,
so.CREATED_DATE as OrderAddDate

From livedata.dbo.PICK s
LEFT OUTER JOIN livedata.dbo.FFPROJECT p ON cast(p.PROJ_ID as varchar) = cast (s.PROJ_ID as varchar)
LEFT OUTER JOIN livedata.dbo.Customer c on c.CUST_ID = s.CUST_ID
LEFT OUTER JOIN livedata.dbo.DEBTOR d ON d.[DATAFLEX RECNUM ONE] = c.DEBTOR_RECNUM
LEFT OUTER JOIN livedata.dbo.FFSTATUS f on f.STATUS_ID = s.PICK_STATUS
LEFT OUTER JOIN livedata.dbo.PACKAGE pp on pp.PICK_ID = s.PICK_ID
LEFT OUTER JOIN livedata.dbo.SO_LINE_ITEM l on l.PICK_ID = s.PICK_ID
LEFT OUTER JOIN livedata.dbo.SALES_ORDER so on so.SO_ID = s.SO_ID

---CUST_ID 9 = Wex, 4= bronw, 11= crown, 6=bupa, 8=racv
-- pickstatus 20 = pickconfirmrequired, 21 = shipped, 18 = pickreleasedforprocessing

Where s.SO_ID = '10906'
--and s.PICK_STATUS <> '21'
--and s.PICK_STATUS = '18'
--and s.PICK_STATUS = '20'
and s.PICK_STATUS = '21'
--and s.PICK_ID = '89736'
and l.INVENTORY_CODE <> 'REDE015' and l.INVENTORY_CODE <> 'REDE050' and l.INVENTORY_CODE <> 'REDE067' and l.INVENTORY_CODE <> 'MOTC034' 
and (so.CREATED_DATE > = @Datetime1 and so.CREATED_DATE <= @Datetime2)
Order by s.SO_ID ASC

