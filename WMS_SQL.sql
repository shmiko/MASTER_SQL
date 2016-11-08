SQL Queries for Reports
New-EOM FULFILLMENT REPORT.sql
SELECT  [t1].[CUST_RECIP_ID] AS [OrderByRecipientID], [t1].[LAST_NAME] AS [OrderByLastName],
[t5].CUST_RECIP_ID ShipToRecipientID,
[t5].LAST_NAME ShipToLastName, 
[t0].[CUST_SO_ID] AS [CustomerSOID],  
[t0].[DOC_ID] AS [DocID],
[t0].[SO_ID] AS [OrderID], 
[t0].[LINE_ITEM_NO] AS [LineItemNo], 
ISNULL([t6].SO_TYPE_NAME,'') TransactionType,
[t0]. [INVENTORY_CODE] AS [InventoryCode], 
[t2].[DESCRIPTION1] AS [Description1], 
[t2].[DESCRIPTION2] AS [Description2], 
[t2].[DESCRIPTION3] AS [Description3], 
[t0].[STATUS_DATE] AS [ShippedDate], 
[t3].[UNIT_PRICE] AS [UnitPrice],
[t0].OUTPUT_BATCH_ID AS [ReleaseBatchID],
[t0].[PICK_QTY] AS [ShippedQty], 
  (CONVERT(Float,[t0].[PICK_QTY])) * [t3].[UNIT_PRICE] AS [TotalPrice] ,
(SELECT ISNULL(SUM([t8].RETURN_QTY),0) FROM [RETURN] as [t7]  INNER JOIN [RETURN_ITEM_RMA] [t8] ON [t7].[RETURN_ID] = [t8].RETURN_ID
WHERE [t7].SO_ID = [t0].SO_ID AND [t8].ITEM_NO = [t0].ITEM_NO)
  as ReturnedQuantity
FROM [SO_LINE_ITEM] AS [t0] 
INNER JOIN [PAPSIZE] AS [t2] ON (CONVERT(NVarChar,[t0].[ITEM_NO])) = [t2].[CODE] 
INNER JOIN [SALES_ORDER] as [t4] ON [t0].SO_ID = [t4].SO_ID
INNER JOIN [RECIPIENT] AS [t5] on [t0].SHIP_TO_ID = [t5].RECIP_ID
INNER JOIN [RECIPIENT] AS [t1] ON [t4].[ORDER_BY_ID] = [t1].[RECIP_ID] 
INNER JOIN [SO_LINE_ITEM_PRICE] AS [t3] ON ([t0].[SO_ID] = [t3].[SO_ID]) AND ([t0].[LINE_ITEM_NO] = [t3].[LINE_ITEM_NO]) 
LEFT OUTER JOIN SO_TYPE [t6] ON [t4].SO_TYPE_ID = [t6].SO_TYPE_ID
WHERE ([t0].[STATUS_ID] = 27) AND ([t0].[STATUS_DATE] BETWEEN '03/01/2014' and '03/31/2014')
New-EOM GOODS RECEIPT REPORT.sql
SELECT   
ISNULL(AUD.[DATE],'01/01/2000') as HistDate,
            isnull(s1.[DESCRIPTION],'') AS [GROUP],
            isnull(s2.[DESCRIPTION],'') AS FAMILY,
            isnull(s3.[DESCRIPTION],'') AS CATEGORY,
        Isnull(level2.Description,'') as WebLevel2,
        Isnull(level3.Description,'') as WebLevel3,
            AUD.[ORDER NO],
            itm.[CODE],
            itm.[INVENTORY CODE] ,
            ITM.DESCRIPTION1 ,
            ITM.DESCRIPTION2,
            ITM.DESCRIPTION3,
            AUD.[REFERENCE],
            ISNULL(AUD.[QUANTITY],0) AS QUANTITY ,

      ('$' + convert(varchar(20),ISNULL(AUD.[COST]/isnull(AUD.[QUANTITY],1),0),10))   as [UNIT PRICE],

      ('$' + convert(varchar(20),ISNULL(AUD.[COST],0),10))   as [TOTAL VALUE],
            CASE
              WHEN AUD.[TYPE] = 'PR'
                  THEN 'Receipt-PO'
              WHEN AUD.[TYPE] = 'IR'
                  THEN 'Initial Receipts'
              WHEN AUD.[TYPE] = 'FR'
                  THEN 'Receipt'
              WHEN AUD.[TYPE] = 'MR'
                  THEN 'Manufacture Receipts'
              WHEN AUD.[TYPE] = 'RP'
                  THEN 'PO return'
            WHEN AUD.[TYPE] = 'FV'
                  THEN 'Ship To Vendor'
            END  as TypeOfReceipt

FROM PAPSIZE  as Itm 
left join stkhist as Aud
on itm.[dataflex recnum one] = Aud.[papsize recnum]
left outer join ESTIMATE as est  on est.[job number] = aud.[job no]  and  est.[job number] > 0
LEFT OUTER JOIN STKCATEG
As s1 on Itm.[CATEGORY1] = s1.[DATAFLEX RECNUM ONE]
LEFT OUTER JOIN STKCATEG
As s2 on Itm.[CATEGORY2] = s2.[DATAFLEX RECNUM ONE]
LEFT OUTER JOIN STKCATEG
As s3 on Itm.[CATEGORY3] = s3.[DATAFLEX RECNUM ONE]
LEFT OUTER JOIN StkLevel as level1
ON itm.[LEVELID1]  = level1.StkLevelId
LEFT OUTER JOIN StkLevel as level2
ON itm.[LEVELID2]  = level2.StkLevelId
LEFT OUTER JOIN StkLevel as level3
ON itm.[LEVELID3]  = level3.StkLevelId

where  Aud.[DATE]   between '03/01/2014' and '03/20/2014'
and  aud.type in ( 'ZZ','PR','IR','FR','MR','FV','RP' ) and  itm.[CREDITOR RECNUM] = 8
and  (ITM.[STOCK TYPE] IN ( 'Z' ,'F' )) and  ITM.[creditor recnum] = 8 and  itm.[STOCK TYPE] <> 'M'

New-EOM STOCK ON HAND.sql
DECLARE @UpToDate DateTime = '4/23/2014' ----- DATE FORMAT OF DB

-----DECLARE @ItemCode Integer = 4245 -------- THIS IS PAPSIZE CODE = no single quotes around value!!!!!!!

Select 


Cast(StkItem.[INVENTORY CODE]as varchar) as [INV_CODE], 

cast(StkItem.[CODE] as varchar) as StkItemCode, 

ISNULL(StkItem.[DESCRIPTION1],'') AS DESCRIPTION1, 

ISNULL(StkItem.[DESCRIPTION2],'') AS DESCRIPTION2 ,

ISNULL(StkItem.[DESCRIPTION3],'') AS DESCRIPTION3 ,

ISNULL(STKCATEG.[DESCRIPTION],'')as [GROUP],

ISNULL(StkItem.[SORT FIELD2],'') AS [SUBCATEGORY], 

ISNULL(StkItem.[UNIT ISSUE DESC],'') AS [UOMDesc] , 

ISNULL(StkItem.[UNIT OF ISSUE],'') AS [Unit Of Conversion] , 

ISNULL((

SELECT SUM([QTY COMMIT]) 

FROM STKSKIDRSV outRSV

LEFT JOIN SO_LINE_ITEM

ON SO_LINE_ITEM.SO_ID = outRSV.[SO ID] 

AND SO_LINE_ITEM.LINE_ITEM_NO = outRSV.[LINE ITEM ID]

WHERE CAST( outRSV.[PAPSIZE CODE] as varchar) = cast(StkItem.[CODE] as varchar)

AND [PICK DATE] <= @UpToDate )

, 0) -

ISNULL((

(SELECT ISNULL( SUM( SO_LINE_ITEM.[PACK_QTY]),0)

FROM STKSKIDRSV

LEFT JOIN SO_LINE_ITEM

ON SO_LINE_ITEM.SO_ID = STKSKIDRSV.[SO ID]

AND SO_LINE_ITEM.LINE_ITEM_NO = STKSKIDRSV.[LINE ITEM ID]

WHERE cast(SO_LINE_ITEM.ITEM_NO as varchar) = cast(StkItem.[CODE]as varchar)

AND [STATUS_DATE] <= @UpToDate and STKSKIDRSV.[PICK DATE] < = @UpToDate

AND [STATUS_ID] = 27)

)

, 0) as [HARD COMMITED AS OF DATE], 

 

ISNULL(LinkedHist.[TOT QTY],0) - 

(ISNULL((

SELECT SUM([QTY COMMIT]) 

FROM STKSKIDRSV outRSV

LEFT JOIN SO_LINE_ITEM

ON SO_LINE_ITEM.SO_ID = outRSV.[SO ID] 

AND SO_LINE_ITEM.LINE_ITEM_NO = outRSV.[LINE ITEM ID]

WHERE CAST( outRSV.[PAPSIZE CODE] as varchar) =CAST( StkItem.[CODE] as varchar)

AND [PICK DATE] <= @UpToDate )

, 0) -

ISNULL((

(SELECT ISNULL( SUM( SO_LINE_ITEM.[PACK_QTY]),0)

FROM STKSKIDRSV

LEFT JOIN SO_LINE_ITEM

ON SO_LINE_ITEM.SO_ID = STKSKIDRSV.[SO ID]

AND SO_LINE_ITEM.LINE_ITEM_NO = STKSKIDRSV.[LINE ITEM ID]

WHERE cast(SO_LINE_ITEM.ITEM_NO as varchar) = cast(StkItem.[CODE] as varchar)

AND [STATUS_DATE] <= @UpToDate and STKSKIDRSV.[PICK DATE] < = @UpToDate

AND [STATUS_ID] = 27)

)

, 0)) as [AVAIL ON HAND AS OF DATE],

ISNULL((SELECT SUM(ISNULL(ORDERLIN.[QTY],0)) 

FROM ORDERLIN 

WHERE ORDERLIN.[PAPSIZE RECNUM] = LinkedHist.[DATAFLEX RECNUM ONE]

AND ORDERLIN.[DELIVERY DATE] < = @UpToDate),0) 

as [QTY ON ORDER AS UP TO DATE],

ISNULL((

SELECT SUM([QTY COMMIT]) 

FROM STKSKIDRSV outRSV

LEFT JOIN SO_LINE_ITEM

ON SO_LINE_ITEM.SO_ID = outRSV.[SO ID] 

AND SO_LINE_ITEM.LINE_ITEM_NO = outRSV.[LINE ITEM ID]

WHERE cast(outRSV.[PAPSIZE CODE] as varchar) = cast(StkItem.[CODE] as varchar)

AND [PICK DATE] <= @UpToDate )

, 0) as [TOTAL COMMIT UP TO DATE], 


ISNULL(LinkedHist.[TOT QTY],0) as [QTY ON HAND AS OF DATE],

('$' + convert(varchar(20),ISNULL(LinkedHist.[TOT COST],0),10)) as [VALUE ON HAND AS OF DATE], 

('$' + convert(varchar(20),ISNULL(LinkedHist.[AV PRICE],0),10)) as [UNIT SELL AVG PRICE AS OF DATE] 

 
from PAPSIZE

as StkItem 

LEFT OUTER JOIN STKCATEG

ON STKCATEG.[DATAFLEX RECNUM ONE] = StkItem.CATEGORY1

LEFT OUTER JOIN DEBTOR as LinkedDebtor 

ON StkItem.[CREDITOR RECNUM] = LinkedDebtor.[DATAFLEX RECNUM ONE] 

LEFT OUTER JOIN CREDITOR AS LinkedVendor on StkItem.[DEBTOR RECNUM] = LinkedVendor.[DATAFLEX RECNUM ONE] 

LEFT JOIN STKHIST AS LinkedHist 

on StkItem.[dataflex recnum one] = LinkedHist.[papsize recnum] 

and LinkedHist.[date] <=@UpToDate

and LinkedHist.[dataflex recnum one] in 

( select top 1 f.[dataflex recnum one] from stkhist as f 

where StkItem.[dataflex recnum one] = f.[papsize recnum]

and f.[date] <= @UpToDate order by f.[date] desc ) 

WHERE 

StkItem.[STOCK TYPE] <>'M'

Inventory on Hand with $.sql
Select ISNULL(a.[TOTAL AVAIL],0) AS [AVAIL ON HAND], ISNULL(a.[AVERAGE PRICE],0) as [AVERAGE PRICE], a.[CODE], 
ISNULL(a.[CREDITOR RECNUM],0) AS [CREDITOR RECNUM], ISNULL(a.[DEBTOR RECNUM],0) AS [DEBTOR RECNUM], 
 ISNULL(a.[DESCRIPTION1],'') AS DESCRIPTION1, 
ISNULL(a.[DESCRIPTION2],'') AS DESCRIPTION2 ,
ISNULL(a.[DESCRIPTION3],'') AS DESCRIPTION3 ,a.[HOUSE STOCK], a.[INVENTORY CODE], 
isnull(a.MEASURE,0) as MEASURE, a.[PAPERCOL RECNUM], a.[PAPER CATEGORY], 
ISNULL(a.[PRODUCT CODE],0) AS [PRODUCT CODE], 
ISNULL(a.[QTY ON HAND],0) as [QTY ON HAND], 
isnull(a.[QTY ON ORDER],0) AS [QTY ON ORDER], a.[DATAFLEX RECNUM ONE], 
ISNULL(a.[REVISION CODE],'') as [REVISION CODE], 
 ISNULL(a.[SHIP CLASS],'') AS [SHIP CLASS],a.[SIZE1],a.[SIZE2],a.[SORT FIELD1], a.[SORT FIELD2], 
 ISNULL(a.[STATUS],'') AS [STATUS] , ISNULL(a.[STOCK TYPE], '') AS [STOCK TYPE],  isnull(a.[TOTAL COMMIT],0) as [TOTAL COMMIT], 
 ISNULL(a.[VALUE ON HAND],0) AS [VALUE ON HAND], 
 ISNULL(a.[UNIT OF ISSUE],0) AS UOM , 
 ISNULL(a.[CHARGE METHOD],'') AS ChargeMethod , 
 ISNULL(a.[PRICING METHOD],'') AS PricingMethod , 
 ISNULL(a.[FIXED MARK UP],0) AS FixedMarkup , 
 ISNULL(a.[STANDARD COST],0) AS StandardCost , 
 ISNULL(a.[UNIT ISSUE DESC],'') AS UOMDesc , 
 ISNULL(a.[SELL PRICE],0) AS [UNIT SELL] , 
 a.[LEVELID1],a.[LEVELID2],a.[LEVELID3],a.[LEVELID4],
 a.[LAST DATE], a.[EXPIRY DATE] as [EXPIRY DATE],  a.[SORT FIELD1] As SORTFIELD1,  isnull(b.[ac no],'') as Customercode , isnull(b.[names],'') as customername , b.[DATAFLEX RECNUM ONE], b.[SALESREP] as CustSalesrep, 
 isnull(c.[ac no],'') as vendorcode, isnull(c.[names],'')  as vendorname, c.[dataflex recnum one] 
 from PAPSIZE as a  LEFT OUTER JOIN DEBTOR as b on a.[CREDITOR RECNUM] = b.[DATAFLEX RECNUM ONE] 
 LEFT OUTER JOIN CREDITOR AS c on a.[DEBTOR RECNUM] = c.[DATAFLEX RECNUM ONE] 
 where  a.[stock type] in ('F') and  a.[STOCK TYPE] <> 'M'    and ( a.[ACTIVE] <> 'N' OR a.[ACTIVE] ='' OR a.[ACTIVE] IS NULL )  and  ISNULL(a.[TRACK TYPE],'') <> 'M'  and  a.[COMPANY CODE] = '01' AND  a.[PLANT CODE] = '0100' and  ISNULL(a.[STOCK TYPE],'') <> 'M' and (a.[MASTER DATE] <= ' 02/27/2014' or a.[MASTER DATE] is null)
LOT PRICE MOVEMENT RUN DAILY.sql

DECLARE @DateStartFrom DateTime = '03/01/2014'
DECLARE @DateUpTo DateTime = '04/30/2014'

SELECT    BigReserv.[PAPSIZE CODE] as InvItemCode,  
          BigItem.[INVENTORY CODE] as InventoryCode,
          BigReserv.[LOT NO] as LotNo, 
          (isnull(BigLot.[PRICE PER 1000],0)/1000) as LotPricePer1000,  
          isnull(BigReserv.[QTY COMMIT],0) as QtyCommited, 
          BigReserv.[SO ID] as SalesOrderNo,  
          BigReserv.[LINE ITEM ID] as SalesOrderLineNo,  
          Case 
             When BigReserv.[STATUS] = 'X'
             Then 'Shipped'
             Else
                'Committed'
          End as ShippedStatus,
        
          BigReserv.[PICK DATE] 
,(SELECT (COUNT ( DISTINCT (isnull(DetailedLot.[PRICE PER 1000],0) ) ))
  FROM  
  STKSKIDRSV  as DetailedReserv
  
   LEFT JOIN STKLOT as DetailedLot 
 
  ON DetailedReserv.[LOT NO] = DetailedLot.[LOT NO]
  WHERE 
  
  DetailedReserv.[PAPSIZE CODE] = BigReserv.[PAPSIZE CODE] 
  AND
  ( DetailedReserv.[PICK DATE] BETWEEN @DateStartFrom  and @DateUpTo)) as PriceVarCnt
From STKSKIDRSV as BigReserv

LEFT OUTER JOIN STKLOT as BigLot
ON BigLot.[LOT NO] = BigReserv.[LOT NO]

LEFT JOIN PAPSIZE as BigItem
  ON cast(BigItem.CODE as varchar) = cast(BigReserv.[PAPSIZE CODE] as varchar)

WHERE (BigReserv.[PICK DATE]     BETWEEN @DateStartFrom and @DateUpTo) 

and (SELECT (COUNT ( DISTINCT (isnull(DetailedLot.[PRICE PER 1000],0) ) ))
  FROM  
  STKSKIDRSV  as DetailedReserv
  
  
   LEFT JOIN STKLOT as DetailedLot 
 
  ON DetailedReserv.[LOT NO] = DetailedLot.[LOT NO]
  WHERE 
  
  DetailedReserv.[PAPSIZE CODE] = BigReserv.[PAPSIZE CODE] 
  AND
  ( DetailedReserv.[PICK DATE] BETWEEN @DateStartFrom and @DateUpTo)) > 1
ORDER BY BigReserv.[PAPSIZE CODE],BigReserv.[LOT NO]

MONTH END FULFILLMENT SUMMARY.sql
select sol.cust_id, d.[AC NO], d.NAMES, sol.so_id 'OrderNo', sol.line_item_no, sol.PO_NO 'PO', oby.CUST_RECIP_ID 'Order By', sto.CUST_RECIP_ID 'Ship To', bto.CUST_RECIP_ID 'Bill To', inventory_code, item_description, order_qty 'Order Qty', bo_qty 'BackOrder Qty',
isnull(pack_qty,0) 'Package Qty',sol.status_id, st.STATUS_NAME 'Status', sol.created_date, sol.modified_date, sop.unit_price, sop.discount , (order_qty * sop.UNIT_PRICE) - sop.discount 'Total Price', sol.pick_id, isnull((select SUM(ACTUAL_CHARGE) from PACKAGE where pick_id = sol.PICK_ID),0) 'Total Package Charge', (select count(PACKAGE_ID) from PACKAGE where pick_id = sol.PICK_ID) 'Package Count', ad.field_name 'Order Variable', ad.FIELD_VALUE 'Variable Value'
from so_line_item sol
left outer join so_line_item_price sop on sop.so_id = sol.so_id and sop.line_item_no = sol.line_item_no left outer join FFSTATUS st on st.STATUS_ID = sol.STATUS_ID left outer join so_addl ad on ad.so_id = sol.so_id left outer join CUSTOMER c on c.cust_id = sol.cust_id left outer join debtor d on d.[dataflex recnum one] = c.debtor_recnum left outer join SALES_ORDER s on s.SO_ID = sol.SO_ID left outer join RECIPIENT oby on s.ORDER_BY_ID = oby.RECIP_ID left outer join RECIPIENT sto on s.SHIP_TO_ID = sto.RECIP_ID left outer join RECIPIENT bto on s.BILL_TO_ID = bto.RECIP_ID where (sol.CREATED_DATE >= '2014-02-03' and sol.CREATED_DATE <= '2014-12-31') order by sol.CUST_ID, sol.SO_ID
Monthly Sales Order.sql
select sol.cust_id, d.[AC NO], d.NAMES, sol.so_id 'OrderNo', sol.line_item_no, sol.PO_NO 'PO', oby.CUST_RECIP_ID 'Order By', sto.CUST_RECIP_ID 'Ship To', bto.CUST_RECIP_ID 'Bill To', inventory_code, item_description, order_qty 'Order Qty', bo_qty 'BackOrder Qty',
isnull(pack_qty,0) 'Package Qty',sol.status_id, st.STATUS_NAME 'Status', sol.created_date, sol.modified_date, sop.unit_price, sop.discount , (order_qty * sop.UNIT_PRICE) - sop.discount 'Total Price', sol.pick_id, isnull((select SUM(ACTUAL_CHARGE) from PACKAGE where pick_id = sol.PICK_ID),0) 'Total Package Charge', (select count(PACKAGE_ID) from PACKAGE where pick_id = sol.PICK_ID) 'Package Count', ad.field_name 'Order Variable', ad.FIELD_VALUE 'Variable Value'
from so_line_item sol
left outer join so_line_item_price sop on sop.so_id = sol.so_id and sop.line_item_no = sol.line_item_no left outer join FFSTATUS st on st.STATUS_ID = sol.STATUS_ID left outer join so_addl ad on ad.so_id = sol.so_id left outer join CUSTOMER c on c.cust_id = sol.cust_id left outer join debtor d on d.[dataflex recnum one] = c.debtor_recnum left outer join SALES_ORDER s on s.SO_ID = sol.SO_ID left outer join RECIPIENT oby on s.ORDER_BY_ID = oby.RECIP_ID left outer join RECIPIENT sto on s.SHIP_TO_ID = sto.RECIP_ID left outer join RECIPIENT bto on s.BILL_TO_ID = bto.RECIP_ID where (sol.CREATED_DATE >= '2011-01-01' and sol.CREATED_DATE <= '2014-12-31') order by sol.CUST_ID, sol.SO_ID
Recipients without Email.sql
select * from recipient where email = ''
Replenishment Report.sql

DECLARE @MonthAgoFromCurrentDate datetime = DATEADD(MONTH,-1,GETDATE())
DECLARE @CurrentDate datetime = GETDATE() ---- use in select between..... 
DECLARE @YearCurrentStartDate datetime = DATEADD(yy, DATEDIFF(yy,0,getdate()), 0) ----- used in selection betweennnn
DECLARE @YearLastEndReportDate datetime = Dateadd(YEAR, -1,GETDATE())
DECLARE @YearLastStartDate datetime = DATEADD(yy, -1, @YearCurrentStartDate) 
DECLARE @CurrentMonthFirstDate DateTime  = CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(GETDATE())-1),GETDATE()),101)


--SELECT @MonthAgoFromCurrentDate as MonthAgoFromCurrentDate
--SELECT @CurrentDate   as CurrentDate
--SELECT @YearCurrentStartDate   as YearCurrentStartDate
--SELECT @YearLastEndReportDate   as YearLastEndReportDate 
--SELECT @YearLastStartDate   as YearLastStartDate

--SELECT @CurrentMonthFirstDate   as CurrentMonthFirstDate



SELECT SelectedPapsize.[EXTERNAL ITEM NO] as GWPMCode,

SelectedPapsize.[INVENTORY CODE]  as BUNNCode ,

(SelectedPapsize.[DESCRIPTION1] + isnull(SelectedPapsize.DESCRIPTION2,'') + ISNULL( SelectedPapsize.[DESCRIPTION3],'') ) as Description,

isnull(SelectedPapsize.[QTY ON HAND] ,0) as QtyOnHand,

isnull(SelectedPapsize.[AVAIL ON HAND] ,0)as QtyAval,
CASE 
  WHEN  isnull(SelectedPapsize.[AVAIL ON HAND],0)  = 0 
      THEN 1
  ELSE
   isnull(SelectedPapsize.[QTY ON HAND],0)/isnull(SelectedPapsize.[AVAIL ON HAND],1)       
END  as Est_Mths_Avail,


isnull(SelectedPapsize.[SELL PRICE],0) as Sell_Price,

ISNULL(SelectedPapsize.[QTY ON ORDER],0) as Qty_On_Order,

        isnull((SELECT SUM(MnthHist.[QUANTITY]* (-1))

                        FROM STKHIST as MnthHist

                        LEft JOIN PAPSIZE as MnthPapsize

                        ON MnthHist.[PAPSIZE RECNUM] = MnthPapsize.[DATAFLEX RECNUM ONE]

                        WHERE MnthPapsize.[CODE] = SelectedPapsize.[CODE]

                        AND  (MnthHist.TYPE = 'FV'

                                OR MnthHist.TYPE = 'FC'

                                OR MnthHist.TYPE = 'FS'

                                OR MnthHist.TYPE = 'JC')

                        AND  ( MnthHist.DATE between @CurrentMonthFirstDate AND @CurrentDate )) ,0)      as Qty_Issued_MNTH_To_Date,

            isnull((SELECT SUM(YearHist.[QUANTITY]* (-1))

            FROM STKHIST as YearHist

            LEft JOIN PAPSIZE as YearPapsize

            ON YearHist.[PAPSIZE RECNUM] = YearPapsize.[DATAFLEX RECNUM ONE]

            WHERE YearPapsize.[CODE] = SelectedPapsize.[CODE]

            AND  (YearHist.TYPE = 'FV'

                    OR YearHist.TYPE = 'FC'

                    OR YearHist.TYPE = 'FS'

                    OR YearHist.TYPE = 'JC')

            AND  ( YearHist.DATE between @YearCurrentStartDate AND @CurrentDate)),0)       as Qty_Issued_YEAR_To_Date,

            isnull((SELECT SUM(LastYearHist.[QUANTITY]* (-1))

            FROM STKHIST as LastYearHist

            LEft JOIN PAPSIZE as LastYearPapsize

            ON LastYearHist.[PAPSIZE RECNUM] = LastYearPapsize.[DATAFLEX RECNUM ONE]

            WHERE LastYearPapsize.[CODE] = SelectedPapsize.[CODE]

            AND  (LastYearHist.TYPE = 'FV'

                    OR LastYearHist.TYPE = 'FC'

                    OR LastYearHist.TYPE = 'FS'

                    OR LastYearHist.TYPE = 'JC')

            AND  ( LastYearHist.DATE between @YearLastStartDate AND @YearLastEndReportDate )),0)       as Qty_Issued_PREVIOUS_YEAR_To_Date,

                       

        SelectedPapsize.[MIN LEVEL] as Min_Level_Qty,

        ISNULL((SELECT Top 1 ReceiptStkHist.QUANTITY from STKHIST as ReceiptStkHist

                  LEFT JOIN PAPSIZE as ReceiptPapsize

                  ON ReceiptStkHist.[PAPSIZE RECNUM] = ReceiptPapsize.[DATAFLEX RECNUM ONE]

                  WHERE ReceiptPapsize.[CODE] = SelectedPapsize.[CODE]

                        AND   (ReceiptStkHist.TYPE = 'FR'

                            OR ReceiptStkHist.TYPE = 'PR'

                            OR ReceiptStkHist.TYPE = 'IR')

                        AND  ReceiptStkHist.DATE <= @CurrentDate),0) as Last_Receipt_Qty,

                       

          ISNULL( (SELECT Top 1 ReceiptStkHist.DATE from STKHIST as ReceiptStkHist

                  LEFT JOIN PAPSIZE as ReceiptPapsize

                  ON ReceiptStkHist.[PAPSIZE RECNUM] = ReceiptPapsize.[DATAFLEX RECNUM ONE]

                  WHERE ReceiptPapsize.[CODE] = SelectedPapsize.[CODE]

                        AND   (ReceiptStkHist.TYPE = 'FR'

                            OR ReceiptStkHist.TYPE = 'PR'

                            OR ReceiptStkHist.TYPE = 'IR')

                        AND  ReceiptStkHist.DATE <= @CurrentDate) ,'')as Last_Receipt_Date,              

                        

                        

       ISNULL( (SELECT Top 1 IssueStkHist.DATE from STKHIST as IssueStkHist

                  LEFT JOIN PAPSIZE as ReceiptPapsize

                  ON IssueStkHist.[PAPSIZE RECNUM] = ReceiptPapsize.[DATAFLEX RECNUM ONE]

                  WHERE ReceiptPapsize.[CODE] = SelectedPapsize.[CODE]

                        AND   (IssueStkHist.TYPE = 'FV'

                            OR IssueStkHist.TYPE = 'FC'

                            OR IssueStkHist.TYPE = 'FS'

                            OR IssueStkHist.TYPE = 'JC')

                        AND  IssueStkHist.DATE <= @CurrentDate) ,'') as Last_Issue_Date,

                              ISNULL(GroupCategory.[DESCRIPTION],'') as GroupDescr,       

                              ISNULL(FamilyCategory.[DESCRIPTION] ,'')as FamilyDescr,   

                              ISNULL(CategoryCategory.[DESCRIPTION],'') as CategoryDescr,        

                              ISNULL(SelectedPapsize.EmailReplenish,'') as  EmailReplanisher

              

FROM PAPSIZE as SelectedPapsize 

LEFT OUTER JOIN

STKCATEG as GroupCategory

ON GroupCategory.[DATAFLEX RECNUM ONE] = isnull(SelectedPapsize.CATEGORY1,0)

LEFT OUTER JOIN

STKCATEG as FamilyCategory

ON FamilyCategory.[DATAFLEX RECNUM ONE] = isnull(SelectedPapsize.CATEGORY2,0)

LEFT OUTER JOIN

STKCATEG as CategoryCategory

ON CategoryCategory.[DATAFLEX RECNUM ONE] = isnull(SelectedPapsize.CATEGORY3,0)


WHERE isnull(SelectedPapsize.[QTY ON HAND],0) < isnull(SelectedPapsize.[MIN LEVEL],0)
ORDER BY SelectedPapsize.[INVENTORY CODE]

Items Need Attention After Batch Physical.sql

SELECT DISTINCT PAPSIZE.[INVENTORY CODE] FROM PAPSIZE
LEFT OUTER JOIN
STKHIST
ON 
STKHIST.[PAPSIZE RECNUM] = PAPSIZE.[DATAFLEX RECNUM ONE]
WHERE
STKHIST.[TYPE]='ST'
AND isnull(STKHIST.[COST] ,0)= 0 and ISNULL(STKHIST.QUANTITY,0) <> 0
AND PAPSIZE.[LOT TRACKING] = 'Y'
ORDER BY
PAPSIZE.[INVENTORY CODE]

SQL Query for All Items Last Receipt Date and Last Issue Date (and specific customer – optional)
DECLARE @MonthAgoFromCurrentDate datetime = DATEADD(MONTH,-1,GETDATE())
DECLARE @CurrentDate datetime = GETDATE() ---- use in select between.....
DECLARE @YearCurrentStartDate datetime = DATEADD(yy, DATEDIFF(yy,0,getdate()), 0) ----- used in selection betweennnn
DECLARE @YearLastEndReportDate datetime = Dateadd(YEAR, -1,GETDATE())
DECLARE @YearLastStartDate datetime = DATEADD(yy, -1, @YearCurrentStartDate)
DECLARE @CurrentMonthFirstDate DateTime = CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(GETDATE())-1),GETDATE()),101)
 
 
 
SELECT
ISNULL(DEBTOR.[AC NO],'') as CustomerAcNo,
SelectedPapsize.[EXTERNAL ITEM NO] as External_ItemNo,
SelectedPapsize.[INVENTORY CODE] as Papsize_Inventory_Code ,
SelectedPapsize.[CODE] as Papsize_Code ,
(SelectedPapsize.[DESCRIPTION1] + isnull(SelectedPapsize.DESCRIPTION2,'') + ISNULL( SelectedPapsize.[DESCRIPTION3],'') ) as Description,
isnull(SelectedPapsize.[QTY ON HAND] ,0) as QtyOnHand,
isnull(SelectedPapsize.[AVAIL ON HAND] ,0)as QtyAval,
CASE
WHEN isnull(SelectedPapsize.[AVAIL ON HAND],0) = 0
THEN 1
ELSE
isnull(SelectedPapsize.[QTY ON HAND],0)/isnull(SelectedPapsize.[AVAIL ON HAND],1)
END as Est_Mths_Avail,
 
isnull(SelectedPapsize.[SELL PRICE],0) as Sell_Price,
ISNULL(SelectedPapsize.[QTY ON ORDER],0) as Qty_On_Order,
isnull((SELECT SUM(MnthHist.[QUANTITY]* (-1))
FROM STKHIST as MnthHist
LEft JOIN PAPSIZE as MnthPapsize
ON MnthHist.[PAPSIZE RECNUM] = MnthPapsize.[DATAFLEX RECNUM ONE]
WHERE MnthPapsize.[CODE] = SelectedPapsize.[CODE]
AND (MnthHist.TYPE = 'FV'
OR MnthHist.TYPE = 'FC'
OR MnthHist.TYPE = 'FS'
OR MnthHist.TYPE = 'JC')
AND ( MnthHist.DATE between @CurrentMonthFirstDate AND @CurrentDate )) ,0) as Qty_Issued_MNTH_To_Date,
isnull((SELECT SUM(YearHist.[QUANTITY]* (-1))
FROM STKHIST as YearHist
LEft JOIN PAPSIZE as YearPapsize
ON YearHist.[PAPSIZE RECNUM] = YearPapsize.[DATAFLEX RECNUM ONE]
WHERE YearPapsize.[CODE] = SelectedPapsize.[CODE]
AND (YearHist.TYPE = 'FV'
OR YearHist.TYPE = 'FC'
OR YearHist.TYPE = 'FS'
OR YearHist.TYPE = 'JC')
AND ( YearHist.DATE between @YearCurrentStartDate AND @CurrentDate)),0) as Qty_Issued_YEAR_To_Date,
isnull((SELECT SUM(LastYearHist.[QUANTITY]* (-1))
FROM STKHIST as LastYearHist
LEft JOIN PAPSIZE as LastYearPapsize
ON LastYearHist.[PAPSIZE RECNUM] = LastYearPapsize.[DATAFLEX RECNUM ONE]
WHERE LastYearPapsize.[CODE] = SelectedPapsize.[CODE]
AND (LastYearHist.TYPE = 'FV'
OR LastYearHist.TYPE = 'FC'
OR LastYearHist.TYPE = 'FS'
OR LastYearHist.TYPE = 'JC')
AND ( LastYearHist.DATE between @YearLastStartDate AND @YearLastEndReportDate )),0) asQty_Issued_PREVIOUS_YEAR_To_Date,
 
isnull(SelectedPapsize.[MIN LEVEL],0) as Min_Level_Qty,
ISNULL((SELECT Top 1 ReceiptStkHist.QUANTITY from STKHIST as ReceiptStkHist
LEFT JOIN PAPSIZE as ReceiptPapsize
ON ReceiptStkHist.[PAPSIZE RECNUM] = ReceiptPapsize.[DATAFLEX RECNUM ONE]
WHERE ReceiptPapsize.[CODE] = SelectedPapsize.[CODE]
AND (ReceiptStkHist.TYPE = 'FR'
OR ReceiptStkHist.TYPE = 'PR'
OR ReceiptStkHist.TYPE = 'IR')
AND ReceiptStkHist.DATE <= @CurrentDate),0) as Last_Receipt_Qty,
 
ISNULL( (SELECT Top 1 ReceiptStkHist.DATE from STKHIST as ReceiptStkHist
LEFT JOIN PAPSIZE as ReceiptPapsize
ON ReceiptStkHist.[PAPSIZE RECNUM] = ReceiptPapsize.[DATAFLEX RECNUM ONE]
WHERE ReceiptPapsize.[CODE] = SelectedPapsize.[CODE]
AND (ReceiptStkHist.TYPE = 'FR'
OR ReceiptStkHist.TYPE = 'PR'
OR ReceiptStkHist.TYPE = 'IR')
AND ReceiptStkHist.DATE <= @CurrentDate) ,'')as Last_Receipt_Date,
 
 
ISNULL( (SELECT Top 1 IssueStkHist.DATE from STKHIST as IssueStkHist
LEFT JOIN PAPSIZE as ReceiptPapsize
ON IssueStkHist.[PAPSIZE RECNUM] = ReceiptPapsize.[DATAFLEX RECNUM ONE]
WHERE ReceiptPapsize.[CODE] = SelectedPapsize.[CODE]
AND (IssueStkHist.TYPE = 'FV'
OR IssueStkHist.TYPE = 'FC'
OR IssueStkHist.TYPE = 'FS'
OR IssueStkHist.TYPE = 'JC')
AND IssueStkHist.DATE <= @CurrentDate) ,'') as Last_Issue_Date,
ISNULL(GroupCategory.[DESCRIPTION],'') as GroupDescr,
ISNULL(FamilyCategory.[DESCRIPTION] ,'')as FamilyDescr,
ISNULL(CategoryCategory.[DESCRIPTION],'') as CategoryDescr,
ISNULL(SelectedPapsize.EmailReplenish,'') as EmailReplanisher
 
FROM PAPSIZE as SelectedPapsize
LEFT OUTER JOIN
STKCATEG as GroupCategory
ON GroupCategory.[DATAFLEX RECNUM ONE] = isnull(SelectedPapsize.CATEGORY1,0)
LEFT OUTER JOIN
STKCATEG as FamilyCategory
ON FamilyCategory.[DATAFLEX RECNUM ONE] = isnull(SelectedPapsize.CATEGORY2,0)
LEFT OUTER JOIN
STKCATEG as CategoryCategory
ON CategoryCategory.[DATAFLEX RECNUM ONE] = isnull(SelectedPapsize.CATEGORY3,0)
LEFT OUTER JOIN
DEBTOR
ON DEBTOR.[DATAFLEX RECNUM ONE] = isnull(SelectedPapsize.[CREDITOR RECNUM],0)
WHERE 
SelectedPapsize.[STOCK TYPE] <> 'M' and isnull(SelectedPapsize.[ACTIVE],'') <> 'N'
AND          ISNULL(DEBTOR.[AC NO],'')  =  ‘NORMA’
 
ORDER BY SelectedPapsize.[INVENTORY CODE]

Remove the yellow highlighted line if no specific single customer report is desired.  If the SQL query is for one customer only, please enter the Debtor AC NO where ‘NORMA’ is shown and leave this line of code in.


SQL to Correct Blank Country Code (Monarch Integration)

UPDATE FFADDRESS set FFADDRESS.COUNTRY_ID = 840 where isnull(FFADDRESS.COUNTRY_ID,0) = 0
SQL Query to Get Avg Price from Tables

SELECT PAPSIZE.CODE,papsize.[INVENTORY CODE],PAPSIZE.[AVERAGE PRICE] as CurrentInvAvgPrice,   STKHIST.[AV PRICE] as HistoricalAvgPrice,STKHIST.TYPE,STKHIST.DATE,    * FROM STKHIST
    LEFT JOIN PAPSIZE 
    ON PAPSIZE.[DATAFLEX RECNUM ONE] = STKHIST.[PAPSIZE RECNUM]
    WHERE isnull(STKHIST.[AV PRICE],0) <> 0 and PAPSIZE.[STOCK TYPE] <> 'M'           order by PAPSIZE.CODE, STKHIST.DATE, STKHIST.[DATAFLEX RECNUM ONE]
Order History SQL

SELECT Ord.SO_ID HeaderLink, 
ISNULL(Ord.CUST_SO_ID,'') CustomerOrderID, 
ISNULL(Inp.CUST_BATCH_ID ,'') CustomerBatchID, 
ISNULL(OrderBy.CUST_RECIP_ID,'') OrderByCustomerRecipientID, 
ISNULL(OrderBy.FIRST_NAME,'') OrderByFirstName, 
ISNULL(OrderBy.MIDDLE_NAME,'') OrderByMiddleName, 
ISNULL(OrderBy.LAST_NAME,'') OrderByLastName, 
ISNULL(OrderBy.COMPANY_NAME,'') OrderByCompanyName, 
ISNULL(OrderByCorpStruct1.CS_NAME,'') OrderbyCorpStruct1Name, 
ISNULL(OrderByCorpStruct2.CS_NAME,'') OrderbyCorpStruct2Name, 
ISNULL(OrderByCorpStruct3.CS_NAME,'') OrderbyCorpStruct3Name, 
ISNULL(OrderByCorpStruct4.CS_NAME,'') OrderbyCorpStruct4Name, 
ISNULL(OrderByCorpLevel1.CL_NAME,'') OrderbyCorpLevel1Name, 
ISNULL(OrderByCorpLevel2.CL_NAME,'') OrderbyCorpLevel2Name, 
ISNULL(OrderByCorpLevel4.CL_NAME,'') OrderbyCorpLevel3Name, 
ISNULL(OrderByCorpLevel4.CL_NAME,'') OrderbyCorpLevel4Name, 
ISNULL(OrderByAddress.ADDR_1,'') OrderByAddress1, 
ISNULL(OrderByAddress.ADDR_2,'') OrderByAddress1, 
ISNULL(OrderByAddress.ADDR_3,'') OrderByAddress1, 
ISNULL(OrderByAddress.CITY,'') OrderByCity, 
ISNULL(OrderByAddress.STATE_CODE,'') OrderByStateCode, 
ISNULL(OrderByAddress.ZIP_CODE,'') OrderByZipCode, 
ISNULL(OrderByAddress.CountyName,'') OrderByCountyName, 
ISNULL(OrderByCountry.COUNTRY_CODE3,'') OrderByCountry, 
ISNULL(ShipTo.CUST_RECIP_ID,'') ShipToCustomerRecipientID, 
ISNULL(ShipTo.FIRST_NAME,'') ShipToFirstName,
ISNULL(ShipTo.MIDDLE_NAME,'') ShipToMiddleName, 
ISNULL(ShipTo.LAST_NAME,'') ShipToLastName, 
ISNULL(ShipTo.COMPANY_NAME,'') ShipToCompanyName, 
ISNULL(ShipToCorpStruct1.CS_NAME,'') ShipToCorpStruct1Name, 
ISNULL(ShipToCorpStruct2.CS_NAME,'') ShipToCorpStruct2Name, 
ISNULL(ShipToCorpStruct3.CS_NAME,'') ShipToCorpStruct3Name, 
ISNULL(ShipToCorpStruct4.CS_NAME,'') ShipToCorpStruct4Name, 
ISNULL(ShipToCorpLevel1.CL_NAME,'') ShipToCorpLevel1Name, 
ISNULL(ShipToCorpLevel2.CL_NAME,'') ShipToCorpLevel2Name, 
ISNULL(ShipToCorpLevel4.CL_NAME,'') ShipToCorpLevel3Name, 
ISNULL(ShipToCorpLevel4.CL_NAME,'') ShipToCorpLevel4Name, 
ISNULL(ShipToAddress.ADDR_1,'') ShipToAddress1, 
ISNULL(ShipToAddress.ADDR_2,'') ShipToAddress1, 
ISNULL(ShipToAddress.ADDR_3,'') ShipToAddress1, 
ISNULL(ShipToAddress.CITY,'') ShipToCity, 
ISNULL(ShipToAddress.STATE_CODE,'') ShipToStateCode, 
ISNULL(ShipToAddress.ZIP_CODE,'') ShipToZipCode, 
ISNULL(ShipToAddress.CountyName,'') ShipToCountyName, 
ISNULL(ShipToCountry.COUNTRY_CODE3,'') ShipToCountry, 
ISNULL(BillTo.CUST_RECIP_ID,'') BillToCustomerRecipientID, 
ISNULL(BillTo.FIRST_NAME,'') BillToFirstName, 
ISNULL(BillTo.MIDDLE_NAME,'') BillToMiddleName, 
ISNULL(BillTo.LAST_NAME,'') BillToLastName, 
ISNULL(BillTo.COMPANY_NAME,'') BillToCompanyName, 
ISNULL(BillToCorpStruct1.CS_NAME,'') BillToCorpStruct1Name, 
ISNULL(BillToCorpStruct2.CS_NAME,'') BillToCorpStruct2Name, 
ISNULL(BillToCorpStruct3.CS_NAME,'') BillToCorpStruct3Name, 
ISNULL(BillToCorpStruct4.CS_NAME,'') BillToCorpStruct4Name, 
ISNULL(BillToCorpLevel1.CL_NAME,'') BillToCorpLevel1Name, 
ISNULL(BillToCorpLevel2.CL_NAME,'') BillToCorpLevel2Name, 
ISNULL(BillToCorpLevel4.CL_NAME,'') BillToCorpLevel3Name, 
ISNULL(BillToCorpLevel4.CL_NAME,'') BillToCorpLevel4Name, 
ISNULL(BillToAddress.ADDR_1,'') BillToAddress1, 
ISNULL(BillToAddress.ADDR_2,'') BillToAddress1, 
ISNULL(BillToAddress.ADDR_3,'') BillToAddress1, 
ISNULL(BillToAddress.CITY,'') BillToCity, 
ISNULL(BillToAddress.STATE_CODE,'') BillToStateCode, 
ISNULL(BillToAddress.ZIP_CODE,'') BillToZipCode,
ISNULL(BillToAddress.CountyName,'') BillToCountyName, 
ISNULL(BillToCountry.COUNTRY_CODE3,'') BillToCountry, 
proj.proj_name, 
Ord.SO_ID DetailLink, 
Sol.INVENTORY_CODE InventoryCode, 
SOl.ORDER_QTY + ISNULL(Sol.BO_QTY,0) OrderQty 
FROM SALES_ORDER Ord 
INNER JOIN BATCH Inp ON Ord.BATCH_ID = Inp.BATCH_ID 
INNER JOIN RECIPIENT OrderBy On OrderBy.RECIP_ID = Ord.ORDER_BY_ID 
INNER JOIN FFADDRESS OrderByAddress on OrderByAddress.ADDRESS_ID = Orderby.DEF_ADDRESS_ID 
INNER JOIN COUNTRY OrderByCountry on OrderByCountry.COUNTRY_ID = OrderByAddress.COUNTRY_ID 
LEFT OUTER JOIN ( SELECT CS_ID, CS_NAME FROM CORP_STRUCT WHERE CS_LEVEL = 1 ) AS OrderByCorpStruct1 ON OrderBy.CORP_STRUCT_1 = OrderByCorpStruct1.CS_ID 
LEFT OUTER JOIN ( SELECT CS_ID, CS_NAME FROM CORP_STRUCT WHERE CS_LEVEL = 2 ) AS OrderByCorpStruct2 ON OrderBy.CORP_STRUCT_2 = OrderByCorpStruct2.CS_ID 
LEFT OUTER JOIN ( SELECT CS_ID, CS_NAME FROM CORP_STRUCT WHERE CS_LEVEL = 3 ) AS OrderByCorpStruct3 ON OrderBy.CORP_STRUCT_3 = OrderByCorpStruct3.CS_ID 
LEFT OUTER JOIN ( SELECT CS_ID, CS_NAME FROM CORP_STRUCT WHERE CS_LEVEL = 4 ) AS OrderByCorpStruct4 ON OrderBy.CORP_STRUCT_4 = OrderByCorpStruct4.CS_ID 
LEFT OUTER JOIN ( SELECT CL_ID, CL_NAME FROM CORP_LEVEL WHERE CL_LEVEL = 1 ) AS OrderByCorpLevel1 ON OrderBy.CORP_LEVEL_1 = OrderByCorpLevel1.CL_ID 
LEFT OUTER JOIN ( SELECT CL_ID, CL_NAME FROM CORP_LEVEL WHERE CL_LEVEL = 2 ) AS OrderByCorpLevel2 ON OrderBy.CORP_LEVEL_2 = OrderByCorpLevel2.CL_ID 
LEFT OUTER JOIN ( SELECT CL_ID, CL_NAME FROM CORP_LEVEL WHERE CL_LEVEL = 3 ) AS OrderByCorpLevel3 ON OrderBy.CORP_LEVEL_3 = OrderByCorpLevel3.CL_ID 
LEFT OUTER JOIN ( SELECT CL_ID, CL_NAME FROM CORP_LEVEL WHERE CL_LEVEL = 4 ) AS OrderByCorpLevel4 ON OrderBy.CORP_LEVEL_4 = OrderByCorpLevel4.CL_ID 
INNER JOIN RECIPIENT ShipTo On ShipTo.RECIP_ID = Ord.SHIP_TO_ID 
INNER JOIN FFADDRESS ShipToAddress on ShipToAddress.ADDRESS_ID = ShipTo.DEF_ADDRESS_ID 
INNER JOIN COUNTRY ShipToCountry on ShipToCountry.COUNTRY_ID = ShipToAddress.COUNTRY_ID 
LEFT OUTER JOIN ( SELECT CS_ID, CS_NAME FROM CORP_STRUCT WHERE CS_LEVEL = 1 ) AS ShipToCorpStruct1 ON ShipTo.CORP_STRUCT_1 = ShipToCorpStruct1.CS_ID 
LEFT OUTER JOIN ( SELECT CS_ID, CS_NAME FROM CORP_STRUCT WHERE CS_LEVEL = 2 ) AS ShipToCorpStruct2 ON ShipTo.CORP_STRUCT_2 = ShipToCorpStruct2.CS_ID 
LEFT OUTER JOIN ( SELECT CS_ID, CS_NAME FROM CORP_STRUCT WHERE CS_LEVEL = 3 ) AS ShipToCorpStruct3 ON ShipTo.CORP_STRUCT_3 = ShipToCorpStruct3.CS_ID 
LEFT OUTER JOIN ( SELECT CS_ID, CS_NAME FROM CORP_STRUCT WHERE CS_LEVEL = 4 ) AS ShipToCorpStruct4 ON ShipTo.CORP_STRUCT_4 = ShipToCorpStruct4.CS_ID 
LEFT OUTER JOIN ( SELECT CL_ID, CL_NAME FROM CORP_LEVEL WHERE CL_LEVEL = 1 ) AS ShipToCorpLevel1 ON ShipTo.CORP_LEVEL_1 = ShipToCorpLevel1.CL_ID 
LEFT OUTER JOIN ( SELECT CL_ID, CL_NAME FROM CORP_LEVEL WHERE CL_LEVEL = 2 ) AS ShipToCorpLevel2 ON ShipTo.CORP_LEVEL_2 = ShipToCorpLevel2.CL_ID 
LEFT OUTER JOIN ( SELECT CL_ID, CL_NAME FROM CORP_LEVEL WHERE CL_LEVEL = 3 ) AS ShipToCorpLevel3 ON ShipTo.CORP_LEVEL_3 = ShipToCorpLevel3.CL_ID 
LEFT OUTER JOIN ( SELECT CL_ID, CL_NAME FROM CORP_LEVEL WHERE CL_LEVEL = 4 ) AS ShipToCorpLevel4 ON ShipTo.CORP_LEVEL_4 = ShipToCorpLevel4.CL_ID 

INNER JOIN RECIPIENT BillTo On BillTo.RECIP_ID = Ord.BILL_TO_ID 
INNER JOIN FFADDRESS BillToAddress on BillToAddress.ADDRESS_ID = BillTo.DEF_ADDRESS_ID 
INNER JOIN COUNTRY BillToCountry on BillToCountry.COUNTRY_ID = BillToAddress.COUNTRY_ID 
LEFT OUTER JOIN ( SELECT CS_ID, CS_NAME FROM CORP_STRUCT WHERE CS_LEVEL = 1 ) AS BillToCorpStruct1 ON BillTo.CORP_STRUCT_1 = BillToCorpStruct1.CS_ID 
LEFT OUTER JOIN ( SELECT CS_ID, CS_NAME FROM CORP_STRUCT WHERE CS_LEVEL = 2 ) AS BillToCorpStruct2 ON BillTo.CORP_STRUCT_2 = BillToCorpStruct2.CS_ID 
LEFT OUTER JOIN ( SELECT CS_ID, CS_NAME FROM CORP_STRUCT WHERE CS_LEVEL = 3 ) AS BillToCorpStruct3 ON BillTo.CORP_STRUCT_3 = BillToCorpStruct3.CS_ID 
LEFT OUTER JOIN ( SELECT CS_ID, CS_NAME FROM CORP_STRUCT WHERE CS_LEVEL = 4 ) AS BillToCorpStruct4 ON BillTo.CORP_STRUCT_4 = BillToCorpStruct4.CS_ID 
LEFT OUTER JOIN ( SELECT CL_ID, CL_NAME FROM CORP_LEVEL WHERE CL_LEVEL = 1 ) AS BillToCorpLevel1 ON BillTo.CORP_LEVEL_1 = BillToCorpLevel1.CL_ID 
LEFT OUTER JOIN ( SELECT CL_ID, CL_NAME FROM CORP_LEVEL WHERE CL_LEVEL = 2 ) AS BillToCorpLevel2 ON BillTo.CORP_LEVEL_2 = BillToCorpLevel2.CL_ID 
LEFT OUTER JOIN ( SELECT CL_ID, CL_NAME FROM CORP_LEVEL WHERE CL_LEVEL = 3 ) AS BillToCorpLevel3 ON BillTo.CORP_LEVEL_3 = BillToCorpLevel3.CL_ID 
LEFT OUTER JOIN ( SELECT CL_ID, CL_NAME FROM CORP_LEVEL WHERE CL_LEVEL = 4 ) AS BillToCorpLevel4 ON BillTo.CORP_LEVEL_4 = BillToCorpLevel4.CL_ID 
INNER JOIN SO_LINE_ITEM Sol ON Ord.SO_ID = SOl.SO_ID 
INNER JOIN FFPROJECT proj ON Ord.PROJ_ID = proj.PROJ_ID 
WHERE proj.PROJ_NAME = 'Fulfillment' 

 
Items with their Attributes – Campaign users only


SELECT        PAPSIZE.[INVENTORY CODE] AS InventoryCode, PAPSIZE.CODE AS ItemNo, PAPSIZE.DESCRIPTION1 AS InventoryDescription, CampaignLine.FWSet, CampaignLine.FWShip, CampaignLine.POGCode, CampaignLine.DistributionNotes, CampaignLine.DistributionQty, CampaignLine.OversQty, CampaignLine.FlatSize, 
                         CampaignLine.FinishSize, CampaignLine.NumberOfPages, PAPSIZE.[QTY ON HAND] AS OnHand, PAPSIZE.[QTY ON ORDER] AS OnOrder, 
                         Campaign.CampaignCode, Campaign.CampaignDescription, Campaign.CompanyCode, 
                         Campaign.UDFTemplateID, Campaign.CustomerID, CampaignLine.SalesOrderID, 
                         CampaignLine.SalesOrderLineID AS SalesOrderLineItemID, CampaignLine.HowTo, CampaignLine.ColorSide1, 
                         CampaignLine.ColorSide2, CampaignLine.SameArtFrontBack, CampaignLine.Stock, CampaignLine.FinishingBindery, CampaignLine.Printer, 
                         CampaignLine.AssetName, SO_LINE_ITEM.MISJobNumber AS SalesOrderMISJobNo, PAPSIZE.POP AS POD, 
                         PAPSIZE.[COMMIT ON HAND] AS CommittedOnHand, PAPSIZE.[COMMIT ON ORDER] AS CommittedOnOrder, CampaignLineAttributes.AttributeName AS LayoutName, 
                         CampaignLineAttributes.DistributionQuantity AS LayoutQuantity, Campaign.CreatedDate, CampaignLine.SignType, PAPSIZE.LOCATION AS InventoryLocation, 
                         PAPSIZE.[MASTER DATE] AS InventoryCreatedDate, CampaignLine.PONumber, CampaignLine.NeedDate, PAPSIZE.[UNIT ISSUE DESC] AS UOMDescription, 
                         PAPSIZE.[UNIT OF ISSUE] AS UOMConversion, 
                         INVENTORY_GROUP.[DESCRIPTION] AS GroupDescription, 
                         INVENTORY_FAMILY.[DESCRIPTION]  AS FamilyDescription, 
                         INVENTORY_CATEGORY.[DESCRIPTION]  AS CategoryDescription
FROM            CampaignLine INNER JOIN
                         PAPSIZE ON CampaignLine.InventoryItemID = PAPSIZE.[DATAFLEX RECNUM ONE] INNER JOIN
                         Campaign ON CampaignLine.CampaignID = Campaign.CampaignID LEFT OUTER JOIN
                         SO_LINE_ITEM ON CampaignLine.SalesOrderLineID = SO_LINE_ITEM.SO_LINE_ITEM_ID LEFT OUTER JOIN
                         CampaignLineAttributes ON CampaignLine.CampaignLineID = CampaignLineAttributes.CampaignLineID
                        LEFT JOIN STKCATEG AS INVENTORY_GROUP ON INVENTORY_GROUP.[DATAFLEX RECNUM ONE] = PAPSIZE.CATEGORY1
                                    LEFT JOIN STKCATEG AS INVENTORY_FAMILY ON INVENTORY_FAMILY.[DATAFLEX RECNUM ONE] = PAPSIZE.CATEGORY2
                                    LEFT JOIN STKCATEG AS INVENTORY_CATEGORY ON INVENTORY_CATEGORY.[DATAFLEX RECNUM ONE] = PAPSIZE.CATEGORY3
WHERE  Campaign.IsActive = 'TRUE'
ORDER BY PAPSIZE.[INVENTORY CODE]

Planned Orders by Campaign Code – Campaign Customers Only


SELECT        RECIPIENT.StoreNum as StoreNumber, CUST_RECIP_ID AS Receipient, Campaign.CampaignCode, 
                PAPSIZE.[INVENTORY CODE] AS InventoryCode, PAPSIZE.DESCRIPTION1 AS InventoryDescription, DistributionQuantity,
                         CampaignLine.POGCode, LMCode, 
                         CampaignLine.PONumber, CampaignLine.NeedDate, PROJ_NAME AS ProjectName
FROM            CampaignLineStores INNER JOIN RECIPIENT ON CampaignLineStores.RecipientID = RECIPIENT.RECIP_ID 
                        INNER JOIN CampaignLine ON CampaignLineStores.CampaignLineID = CampaignLine.CampaignLineID
                        INNER JOIN PAPSIZE on CampaignLine.InventoryItemID = PAPSIZE.[DATAFLEX RECNUM ONE]
                        INNER JOIN Campaign ON CampaignLineStores.CampaignID = Campaign.CampaignID
                        INNER JOIN FFPROJECT ON CampaignLineStores.ProjectID = FFPROJECT.PROJ_ID  
WHERE Campaign.CampaignCode = 'your campaign' AND ISNULL(DistributionSalesOrderID,0) = 0 
ORDER BY CUST_RECIP_ID, PAPSIZE.[INVENTORY CODE]
Planned Orders by Customer – Campaign Customers only
SELECT        RECIPIENT.StoreNum as StoreNumber, CUST_RECIP_ID AS Receipient, Campaign.CampaignCode, 
                PAPSIZE.[INVENTORY CODE] AS InventoryCode, PAPSIZE.DESCRIPTION1 AS InventoryDescription, DistributionQuantity,
                         CampaignLine.POGCode, LMCode, 
                         CampaignLine.PONumber, CampaignLine.NeedDate, PROJ_NAME AS ProjectName
FROM            CampaignLineStores INNER JOIN RECIPIENT ON CampaignLineStores.RecipientID = RECIPIENT.RECIP_ID 
                        INNER JOIN CampaignLine ON CampaignLineStores.CampaignLineID = CampaignLine.CampaignLineID
                        INNER JOIN PAPSIZE on CampaignLine.InventoryItemID = PAPSIZE.[DATAFLEX RECNUM ONE]
                        INNER JOIN Campaign ON CampaignLineStores.CampaignID = Campaign.CampaignID
                        INNER JOIN FFPROJECT ON CampaignLineStores.ProjectID = FFPROJECT.PROJ_ID  
WHERE CampaignLineStores.CustomerID = 5 AND ISNULL(DistributionSalesOrderID,0) = 0 
ORDER BY CUST_RECIP_ID, PAPSIZE.[INVENTORY CODE]
web report cc transaction report

SELECT          MISJObNumber as JobNumber, PKG.SO_ID as OrderID, PKG.Tracking_NO as TrackingNumber, 
                SM.SHIP_MODE_DESC AS ShippingDescription, CC_TYPE_NAME as CreditCardType, 
                LI_P.Item_No as ItemID,
                Item_Description as [Item Description],
                LI.[PACK_QTY] as Qty, 
                Unit_Price AS UnitPrice,
                PACK_QTY * Unit_Price as SubTotal,
                ISNULL(PRICE_PER_UNIT,0) as HandlingCharge,
                (Select IsNull(SUM(AMOUNT),0) from SO_CHARGE SC Where SC.[SO_ID] = PKG.[SO_ID] and SC.[CHARGE_TYPE] = 'S') as Freight, 
                (PACK_QTY *  Unit_Price) + Cast(ISNULL(PRICE_PER_UNIT,0) as float) + (Select IsNull(SUM(AMOUNT),0) from SO_CHARGE SC Where SC.[SO_ID] = PKG.[SO_ID] and SC.[CHARGE_TYPE] = 'S') as  FinalSum
  FROM [SO_LINE_ITEM_PRICE] LI_P
  INNER JOIN  CREDIT_CARD_TYPE CCT on LI_P.CC_TYPE_ID = CCT.CC_TYPE_ID  
  INNER JOIN SO_LINE_ITEM as LI on LI_P.SO_ID =  LI.SO_ID
  INNER JOIN SALES_ORDER ON LI.SO_ID = SALES_ORDER.SO_ID
  INNER JOIN Package PKG on LI_P.SO_ID = PKG.SO_ID  
  INNER JOIN SHIPPING_MODE SM on SM.[SHIP_MODE_ID] = PKG.[SHIP_MODE_ID]
  INNER JOIN SO_CHARGE SC  on LI_P.[SO_ID] = SC.[SO_ID]
  LEFT JOIN FF_TRANS ff  on LI_P.[SO_ID] = FF.[SO_ID]
  LEFT JOIN PRICELIST_DTL PL_DTL on ff.ACTIVITY_ID =  PL_DTL.ACTIVITY_ID
  INNER JOIN SHIP_PROFILE SP on SP.[PROJ_ID] = PKG.[PROJ_ID] AND SP.[SHIP_MODE_ID] = PKG.[SHIP_MODE_ID] AND SP.[DEFAULT] = 'Y'
  where CC_NO IS NOT NULL  AND LI.STATUS_ID  = 27 AND
                  (PKG.[SHIP_DATE] >= '11/1/2013' AND PKG.[SHIP_DATE] < '11/30/2013' )
                  AND SALES_ORDER.CUST_ID = 42           
GROUP BY PKG.SO_ID,MISJObNumber,PKG.Tracking_NO,CC_NO,CC_TYPE_NAME,UNIT_PRICE,LI_P.Item_No,Item_Description,  
                                LI.[ORDER_QTY], LI.[PACK_QTY], Unit_Price, SM.SHIP_MODE_DESC,PRICE_PER_UNIT,PL_DTL.ACTIVITY_ID,PL_DTL.PRICELIST_ID
                                
 
Sql query to create a report for new stores to know how to layout their stores. Need stores with recipient attribute group 1 (group number changes every month) tied to inventory codes with POG/LM assigned to the recipient sorted by store>Group>Family with Layout. 

SELECT RECIPIENT.CUST_RECIP_ID AS Store, RECIPIENT.StoreNum AS StoreNo, 
         PAPSIZE.[INVENTORY CODE] AS ReorderNo, PAPSIZE.DESCRIPTION1 AS ItemDescription, 
         CampaignLine.POGCode,  CampaignLineAttributes.AttributeName AS Layout,
         CampaignLineAttributes.DistributionQuantity LayoutQty,
         INVENTORY_GROUP.[DESCRIPTION] AS ItemGroup, INVENTORY_FAMILY.[DESCRIPTION]  AS ItemFamily, 
         INVENTORY_CATEGORY.[DESCRIPTION]  AS ItemCategory, CampaignLine.SignType, CampaignLine.FinishSize,     CampaignLine.FlatSize,
         PAPSIZE.LOCATION AS DefaultLocation, PAPSIZE.MEASURE AS UOM
FROM CampaignLineAttributes INNER JOIN CampaignLine ON CampaignLineAttributes.CampaignLineID = CampaignLine.CampaignLineID INNER JOIN RecipientLayoutModules ON  CampaignLine.POGCode = RecipientLayoutModules.POGCode AND CampaignLineAttributes.AttributeName = RecipientLayoutModules.LayoutModule
INNER JOIN PAPSIZE ON CampaignLine.InventoryItemID = PAPSIZE.[DATAFLEX RECNUM ONE]
INNER JOIN AttributeRecipValues ON RecipientLayoutModules.RecipientID = AttributeRecipValues.RecipientID
INNER JOIN Attributes ON Attributes.AttributesId = AttributeRecipValues.AttributesId
INNER JOIN RECIPIENT ON RECIPIENT.RECIP_ID = RecipientLayoutModules.RecipientID
LEFT JOIN STKCATEG AS INVENTORY_GROUP ON INVENTORY_GROUP.[DATAFLEX RECNUM ONE] = PAPSIZE.CATEGORY1
      LEFT JOIN STKCATEG AS INVENTORY_FAMILY ON INVENTORY_FAMILY.[DATAFLEX RECNUM ONE] = PAPSIZE.CATEGORY2
      LEFT JOIN STKCATEG AS INVENTORY_CATEGORY ON INVENTORY_CATEGORY.[DATAFLEX RECNUM ONE] = PAPSIZE.CATEGORY3
WHERE CampaignLine.InventoryItemID <> 0 
        AND Attributes.AttributesName = 'Group' 
        AND AttributeRecipValues.AttributeRecipValue = '1'
ORDER BY RECIPIENT.CUST_RECIP_ID, INVENTORY_GROUP.[DESCRIPTION], INVENTORY_FAMILY.[DESCRIPTION], INVENTORY_CATEGORY.[DESCRIPTION]
Label Data - Ace & Receiving (Group), Ace Documentation (POG)
SELECT DISTINCT RECIPIENT.CUST_RECIP_ID AS RecipientID, CampaignLine.POGCode, CampaignLineStores.LMCode, 
      IsNull(CAT1.[DESCRIPTION],'') as PapGroup, IsNull(Cat2.[DESCRIPTION],'') as PapFamily, IsNull(Cat3.[DESCRIPTION],'') as PapCategory
FROM CampaignLineStores INNER JOIN CampaignLine ON CampaignLineStores.CampaignLineID = CampaignLine.CampaignLineID 
    INNER JOIN RECIPIENT ON CampaignLineStores.RecipientID = RECIPIENT.RECIP_ID
    Inner Join PAPSIZE as PS on CampaignLineStores.ItemID = PS.[DATAFLEX RECNUM ONE]
      LEFT OUTER JOIN STKCATEG AS Cat1 ON Cat1.[DATAFLEX RECNUM ONE] = PS.CATEGORY1
      LEFT OUTER JOIN STKCATEG AS Cat2 ON Cat2.[DATAFLEX RECNUM ONE] = PS.CATEGORY2
      LEFT OUTER JOIN STKCATEG AS Cat3 ON Cat3.[DATAFLEX RECNUM ONE] = PS.CATEGORY3 
WHERE CampaignLineStores.DistributionSalesOrderID = 276106
ORDER BY RECIPIENT.CUST_RECIP_ID, CampaignLine.POGCode, CampaignLineStores.LMCode
Shipping and Returns Transactions SQL Query – sorted by SO ID, Line No
SELECT 
StkHistMine.date as DateOfTheTransaction,
TypeOftransaction =
Case  StkHistMine.[TYPE] 
WHEN 'FS' 
    Then  
       'Shipping'
WHEN 'RR' 
    Then  
       'Return'      
 END   ,
      
      
[t1].[CUST_RECIP_ID] AS [OrderByRecipientID], 
[t1].[LAST_NAME] AS [OrderByLastName],
[t5].LAST_NAME ShipToLastName, 
[t0].[CUST_SO_ID] AS [CustomerSOID],  
isnull([t0].[DOC_ID] ,'') AS [DocID],
[t0].[SO_ID] AS [OrderID], 
[t0].[LINE_ITEM_NO] AS [LineItemNo],
[t0]. [INVENTORY_CODE] AS [InventoryCode], 
[t2].[DESCRIPTION1] AS [Description1],
[t2].[DESCRIPTION2] AS [Description2], 
 [t2].[DESCRIPTION3] AS [Description3], 
 [t0].[STATUS_DATE] AS [ShippedDate], 
 [t3].[UNIT_PRICE] AS [UnitPrice],
  [t0].[PICK_QTY] AS [ShippedQty], 
 (CONVERT(Float,[t0].[PICK_QTY])) * [t3].[UNIT_PRICE] AS [TotalPrice] ,

 (CONVERT(Float,StkHistMine.[QUANTITY])) * [t3].[UNIT_PRICE]  *  (-1)  AS [TotalTransactionAmt] ,
(CONVERT(Float,StkHistMine.[QUANTITY]))  * (-1) AS [TotalTransactionQty] 
  FROM STKHIST as StkHistMine
LEFT JOIN  PAPSIZE AS [t2]
ON 
[t2].[DATAFLEX RECNUM ONE] = StkHistMine.[PAPSIZE RECNUM]
LEFT OUTER JOIN 
SO_LINE_ITEM  AS [t0] 
ON
[t0].[Pick_ID] = StkHistMine.[PickID]
AND
[t0].[LINE_ITEM_NO] = StkHistMine.[ORDER LINE NO]
AND
[t0].[SO_ID] = StkHistMine.[ORDER NO]
AND
Cast([t0].[ITEM_NO] as varchar) = cast([t2].[CODE] as varchar)
INNER JOIN [SALES_ORDER] as [t4] ON [t0].SO_ID = [t4].SO_ID
INNER JOIN [RECIPIENT] AS [t5]
on [t0].SHIP_TO_ID = [t5].RECIP_ID
INNER JOIN [RECIPIENT] AS [t1] 
ON [t4].[ORDER_BY_ID] = [t1].[RECIP_ID] 
INNER JOIN [SO_LINE_ITEM_PRICE] AS [t3] ON ([t0].[SO_ID] = [t3].[SO_ID]) AND ([t0].[LINE_ITEM_NO] = [t3].[LINE_ITEM_NO])
WHERE 
StkHistMine.[type]  = 'FS' 
OR  
 StkHistMine.[type]  = 'RR' 
AND  ([t0].[STATUS_ID] = 27) 
AND ([t0].[STATUS_DATE] BETWEEN '05/01/2014' and '05/28/2014') ----- this is date from the Order Related data
ORDER BY [t0].[SO_ID], [t0].[LINE_ITEM_NO]
SQL Query to Sort All Fields for the OrderByRecipientID  
SELECT 
StkHistMine.date as DateOfTheTransaction,
TypeOftransaction =
Case  StkHistMine.[TYPE] 
WHEN 'FS' 
    Then  
       'Shipping'
WHEN 'RR' 
    Then  
       'Return'      
 END   ,
      
      
[t1].[CUST_RECIP_ID] AS [OrderByRecipientID], 
[t1].[LAST_NAME] AS [OrderByLastName],
[t5].LAST_NAME ShipToLastName, 
[t0].[CUST_SO_ID] AS [CustomerSOID],  
isnull([t0].[DOC_ID] ,'') AS [DocID],
[t0].[SO_ID] AS [OrderID], 
[t0].[LINE_ITEM_NO] AS [LineItemNo],
[t0]. [INVENTORY_CODE] AS [InventoryCode], 
[t2].[DESCRIPTION1] AS [Description1],
[t2].[DESCRIPTION2] AS [Description2], 
 [t2].[DESCRIPTION3] AS [Description3], 
 [t0].[STATUS_DATE] AS [ShippedDate], 
 [t3].[UNIT_PRICE] AS [UnitPrice],
  [t0].[PICK_QTY] AS [ShippedQty], 
 (CONVERT(Float,[t0].[PICK_QTY])) * [t3].[UNIT_PRICE] AS [TotalPrice] ,

 (CONVERT(Float,StkHistMine.[QUANTITY])) * [t3].[UNIT_PRICE]  *  (-1)  AS [TotalTransactionAmt] ,
(CONVERT(Float,StkHistMine.[QUANTITY]))  * (-1) AS [TotalTransactionQty] 
  FROM STKHIST as StkHistMine
LEFT JOIN  PAPSIZE AS [t2]
ON 
[t2].[DATAFLEX RECNUM ONE] = StkHistMine.[PAPSIZE RECNUM]
LEFT OUTER JOIN 
SO_LINE_ITEM  AS [t0] 
ON
[t0].[Pick_ID] = StkHistMine.[PickID]
AND
[t0].[LINE_ITEM_NO] = StkHistMine.[ORDER LINE NO]
AND
[t0].[SO_ID] = StkHistMine.[ORDER NO]
AND
Cast([t0].[ITEM_NO] as varchar) = cast([t2].[CODE] as varchar)
INNER JOIN [SALES_ORDER] as [t4] ON [t0].SO_ID = [t4].SO_ID
INNER JOIN [RECIPIENT] AS [t5]
on [t0].SHIP_TO_ID = [t5].RECIP_ID
INNER JOIN [RECIPIENT] AS [t1] 
ON [t4].[ORDER_BY_ID] = [t1].[RECIP_ID] 
INNER JOIN [SO_LINE_ITEM_PRICE] AS [t3] ON ([t0].[SO_ID] = [t3].[SO_ID]) AND ([t0].[LINE_ITEM_NO] = [t3].[LINE_ITEM_NO])
WHERE 
StkHistMine.[type]  = 'FS' 
OR  
 StkHistMine.[type]  = 'RR' 
AND  ([t0].[STATUS_ID] = 27) 
AND ([t0].[STATUS_DATE] BETWEEN '05/01/2014' and '05/28/2014') ----- this is date from the Order Related data
ORDER BY [t1].[CUST_RECIP_ID], [t0].[SO_ID], [t0].[LINE_ITEM_NO]

SQL Query to Report on Item Nomination with Group/Family/Category
SELECT
       ItemNom.[NOM_DESC] AS [Availability Group],
       COALESCE(Category1.[DESCRIPTION], '') AS [Primary Category],
       COALESCE(Category2.[DESCRIPTION], '') AS [Secondary Category],
       COALESCE(Category3.[DESCRIPTION], '') AS [Tertiary Category],
       COALESCE(Category4.[DESCRIPTION], '') AS [Quaternary Category],
       StkItem.[Stk_HdrCode] AS [Item Code],
       StkItem.[RevisionCode] AS [Rev Code],
       StkItem.[DESCRIPTION1] AS [Item Name],
       StkItem.[UnitIssueDesc] AS [UOM],
       COALESCE(ItemNomItem.[MIN_ORD_QTY], 0) AS [Min Order Qty],
       COALESCE(ItemNomItem.[ORD_QTY_OF], 0) AS [Order Qty Step],
       COALESCE(ItemNomItem.[ORDER_LIMIT], 0) AS [Max Order Qty]
FROM
       (((((([printstream].[dbo].[ITEM_NOM_ITEM] AS ItemNomItem JOIN [printstream].[dbo].[ITEM_NOM] AS ItemNom ON ItemNomItem.[NOM_ID]=ItemNom.[NOM_ID] AND ItemNomItem.[CUST_ID]=ItemNom.[CUST_ID])
              JOIN [printstream].[dbo].[Stk_Item] AS StkItem ON ItemNomItem.[ITEM_ID]=StkItem.[Stk_HdrID])
                     JOIN [printstream].[dbo].[NOM_GROUP_ITEM] AS NomGroupItem ON ItemNomItem.[CUST_ID] = NomGroupItem.[CUST_ID] AND ItemNomItem.[NOM_ID] = NomGroupItem.[NOM_ID] AND ItemNomItem.[ITEM_ID]=NomGroupItem.[ITEM_ID])
                           JOIN [printstream].[dbo].[NOM_GROUP_ITEM] AS Category1 ON NomGroupItem.NOM_ID = Category1.NOM_ID AND NomGroupItem.LEVEL_1_GROUP_ID = Category1.LEVEL_1_GROUP_ID AND Category1.LEVEL_1_GROUP_ID <> '0' AND Category1.LEVEL_2_GROUP_ID = '0' AND Category1.LEVEL_3_GROUP_ID = '0' AND Category1.LEVEL_4_GROUP_ID = '0' AND Category1.ITEM_ID = '0')
                                  LEFT JOIN [printstream].[dbo].[NOM_GROUP_ITEM] AS Category2 ON NomGroupItem.NOM_ID = Category2.NOM_ID AND NomGroupItem.LEVEL_1_GROUP_ID = Category2.LEVEL_1_GROUP_ID AND NomGroupItem.LEVEL_2_GROUP_ID = Category2.LEVEL_2_GROUP_ID AND Category2.LEVEL_2_GROUP_ID <> '0' AND Category2.LEVEL_3_GROUP_ID = '0' AND Category2.LEVEL_4_GROUP_ID = '0' AND Category2.ITEM_ID = '0')
                                         LEFT JOIN [printstream].[dbo].[NOM_GROUP_ITEM] AS Category3 ON NomGroupItem.NOM_ID = Category3.NOM_ID AND NomGroupItem.LEVEL_1_GROUP_ID = Category3.LEVEL_1_GROUP_ID AND NomGroupItem.LEVEL_2_GROUP_ID = Category3.LEVEL_2_GROUP_ID AND NomGroupItem.LEVEL_3_GROUP_ID = Category3.LEVEL_3_GROUP_ID AND Category3.LEVEL_3_GROUP_ID <> '0' AND Category3.LEVEL_4_GROUP_ID = '0' AND Category3.ITEM_ID = '0')
                                                LEFT JOIN [printstream].[dbo].[NOM_GROUP_ITEM] AS Category4 ON NomGroupItem.NOM_ID = Category4.NOM_ID AND NomGroupItem.LEVEL_1_GROUP_ID = Category4.LEVEL_1_GROUP_ID AND NomGroupItem.LEVEL_2_GROUP_ID = Category4.LEVEL_2_GROUP_ID AND NomGroupItem.LEVEL_3_GROUP_ID = Category4.LEVEL_3_GROUP_ID AND NomGroupItem.LEVEL_4_GROUP_ID = Category4.LEVEL_4_GROUP_ID AND Category4.LEVEL_4_GROUP_ID <> '0' AND Category4.ITEM_ID = '0'
WHERE
       ItemNom.[CUST_ID] = '6'
       AND ItemNomItem.[ACTIVE] = 1
       AND ItemNomItem.[SHOW_ON_WEB] = 1
       AND StkItem.[ACTIVE] = 'Y'
       AND ItemNom.[NOM_DESC] NOT LIKE '%internal%'
ORDER BY
       ItemNom.[NOM_DESC],
       Category1.SEQUENCE,
       Category2.SEQUENCE,
       Category3.SEQUENCE,
       Category4.SEQUENCE,
       NomGroupItem.[DESCRIPTION]

Campaign with last updated Item (includes G/F/C)
SELECT        PAPSIZE.[INVENTORY CODE] AS InventoryCode, PAPSIZE.DESCRIPTION1 AS InventoryDescription, CampaignLine.FWSet, CampaignLine.FWShip, 
                         CampaignLine.POGCode, CampaignLine.DistributionNotes, CampaignLine.DistributionQty, CampaignLine.OversQty, CampaignLine.FlatSize, 
                         CampaignLine.FinishSize, CampaignLine.NumberOfPages, PAPSIZE.[QTY ON HAND] AS OnHand, PAPSIZE.[QTY ON ORDER] AS OnOrder, 
                         Campaign.CampaignCode, Campaign.CampaignDescription,  
                         PAPSIZE.CODE AS ItemNo, PAPSIZE.POP AS POD, 
                         PAPSIZE.[COMMIT ON HAND] AS CommittedOnHand, PAPSIZE.[COMMIT ON ORDER] AS CommittedOnOrder, INVENTORY_GROUP.[DESCRIPTION] AS ItemGroup, 
                         INVENTORY_FAMILY.[DESCRIPTION] AS ItemFamily, INVENTORY_CATEGORY.[DESCRIPTION] AS ItemCategory, Campaign.CreatedDate AS CampaignCreatedDate, CampaignLine.SignType, 
                         PAPSIZE.LOCATION AS InventoryLocation, PAPSIZE.[MASTER DATE] AS InventoryCreatedDate, CampaignLine.PONumber, CampaignLine.NeedDate, 
                         PAPSIZE.[UNIT ISSUE DESC] AS UOMDescription, PAPSIZE.[UNIT OF ISSUE] AS UOMConversion, CampaignLine.HowTo, CampaignLine.ColorSide1, 
                         CampaignLine.ColorSide2, CampaignLine.SameArtFrontBack, CampaignLine.Stock, CampaignLine.FinishingBindery, CampaignLine.Printer, 
                         CampaignLine.AssetName, AssetLocation
FROM            CampaignLine INNER JOIN
                         PAPSIZE ON CampaignLine.InventoryItemID = PAPSIZE.[DATAFLEX RECNUM ONE] INNER JOIN
                         Campaign ON CampaignLine.CampaignID = Campaign.CampaignID
                         LEFT JOIN STKCATEG AS INVENTORY_GROUP ON INVENTORY_GROUP.[DATAFLEX RECNUM ONE] = PAPSIZE.CATEGORY1
                                    LEFT JOIN STKCATEG AS INVENTORY_FAMILY ON INVENTORY_FAMILY.[DATAFLEX RECNUM ONE] = PAPSIZE.CATEGORY2
                           LEFT JOIN STKCATEG AS INVENTORY_CATEGORY ON INVENTORY_CATEGORY.[DATAFLEX RECNUM ONE] = PAPSIZE.CATEGORY3
WHERE     CampaignLine.IsLastCampaign = 'TRUE' AND CampaignLine.POGCode = 'KDART'
ORDER BY PAPSIZE.[INVENTORY CODE]
 
SQL to Update Ship Profile in Project
SELECT PROJ_ID,PROJ_NAME FROM FFPROJECT
WHERE ISNULL(PRICED_FF,0) = 0
this should give all the NON-Merchandise projects
SELECT [INVENTORY CODE] InventoryCode ,[DESCRIPTION1],[DESCRIPTION2],[DESCRIPTION3], ISNULL([CATEGORY1],0) GroupID,
ISNULL([CATEGORY2],0) FamilyID , ISNULL([CATEGORY3],0) CategoryID,
CASE  ISNULL(ACTIVE,'N')
WHEN 'N' THEN 'No'
ELSE 'Yes'
END Active
FROM PAPSIZE
UPDATE SHIP_PROFILE SET SHIP_PROFILE.SHIP_MODE_DESC = 
      (SELECT SHIPPING_MODE.SHIP_MODE_DESC FROM SHIPPING_MODE WHERE SHIPPING_MODE.SHIP_MODE_ID = SHIP_PROFILE.SHIP_MODE_ID)
SQL Query for Inventory Expiry Report with Expiration Date for Each Inventory Code Displayed
SELECT  PAPSIZE.[CODE]as InventoryItemNumber, 
PAPSIZE.[INVENTORY CODE] as InventoryCOde, 
DEBTOR.[NAMES] as CustomerName, 
STKCATEG1.[Description] as GroupDescr,

STKCATEG2.[Description] as FamilyDescr,
STKCATEG3.[Description] as CategoryDescr,

PAPSIZE.[QTY ON HAND] as QtyOnHand,
PAPSIZE.[COMMIT ON HAND] as QtyCommitted,
PAPSIZE.[QTY ON ORDER] as QtyOnOrder,
ISNULL(PAPSIZE.[QTY ON HAND],0) + isnull(PAPSIZE.[QTY ON ORDER],0) as QtyAval,

PAPSIZE.[EXPIRY DATE] as ExpirationDate
FROM PAPSIZE
LEFT JOIN DEBTOR
ON DEBTOR.[DATAFLEX RECNUM ONE] = PAPSIZE.[CREDITOR RECNUM]
LEFT JOIN STKCATEG  as STKCATEG1
ON STKCATEG1.[DATAFLEX RECNUM ONE] = PAPSIZE.[CATEGORY1]
LEFT JOIN STKCATEG  as STKCATEG2
ON STKCATEG2.[DATAFLEX RECNUM ONE] = PAPSIZE.[CATEGORY2]
LEFT  JOIN STKCATEG  as STKCATEG3
ON STKCATEG3.[DATAFLEX RECNUM ONE]  = PAPSIZE.[CATEGORY3]

SQL Query to Report on Campaign Items – All Items All Attributes
SELECT DISTINCT PAPSIZE.[INVENTORY CODE] AS InventoryCode, PAPSIZE.DESCRIPTION1 AS InventoryDescription, CampaignLine.FWSet, CampaignLine.FWShip,
                         CampaignLine.POGCode, CampaignLine.DistributionNotes, CampaignLine.DistributionQty, CampaignLine.OversQty, CampaignLine.FlatSize,
                         CampaignLine.FinishSize, CampaignLine.NumberOfPages, PAPSIZE.[QTY ON HAND] AS OnHand, PAPSIZE.[QTY ON ORDER] AS OnOrder,
                         Campaign.CampaignCode, Campaign.CampaignDescription, 
                         PAPSIZE.CODE AS ItemNo, PAPSIZE.POP AS POD,
                         PAPSIZE.[COMMIT ON HAND] AS CommittedOnHand, PAPSIZE.[COMMIT ON ORDER] AS CommittedOnOrder, INVENTORY_GROUP.[DESCRIPTION] AS ItemGroup,
                         INVENTORY_FAMILY.[DESCRIPTION] AS ItemFamily, INVENTORY_CATEGORY.[DESCRIPTION] AS ItemCategory, Campaign.CreatedDate AS CampaignCreatedDate, CampaignLine.SignType,
                         PAPSIZE.LOCATION AS InventoryLocation, PAPSIZE.[MASTER DATE] AS InventoryCreatedDate, CampaignLine.PONumber, CampaignLine.NeedDate,
                         PAPSIZE.[UNIT ISSUE DESC] AS UOMDescription, PAPSIZE.[UNIT OF ISSUE] AS UOMConversion, CampaignLine.HowTo, CampaignLine.ColorSide1,
                         CampaignLine.ColorSide2, CampaignLine.SameArtFrontBack, CampaignLine.Stock, CampaignLine.FinishingBindery, CampaignLine.Printer,
                         CampaignLine.AssetName, AssetLocation, 
                         isnull(PAPSIZE.[MISTemplateID],'') as MISTemplateID, 
                         PAPSIZE.[EXPIRY DATE] as ExpirationDate,
                         ISNULL(PAPSIZE.POP,'') as POD,
                         isnull(PAPSIZE.[PartialPOD],'') as PArtialPOD,
                         ISNULL(PAPSIZE.[WEIGHT],0) as ItemWeight,
                         ISNULL(PAPSIZE.[MAX USE QTY],0) as MaxItemBalance,
                         ISNULL(PAPSIZE.[MIN RUN QTY],0) as MinItemBalance,
                         ISNULL(PAPSIZE.[SELL PRICE],0) As SellPrice,
                         JOBTYPE.[PRODUCT CODE] as SalesClassID, 
                         JOBTYPE.[DESCR] as SalesClassDescr
                        
FROM            CampaignLine INNER JOIN
                         PAPSIZE ON CampaignLine.InventoryItemID = PAPSIZE.[DATAFLEX RECNUM ONE] INNER JOIN
                         Campaign ON CampaignLine.CampaignID = Campaign.CampaignID
                         LEFT JOIN STKCATEG AS INVENTORY_GROUP ON INVENTORY_GROUP.[DATAFLEX RECNUM ONE] = PAPSIZE.CATEGORY1
                                    LEFT JOIN STKCATEG AS INVENTORY_FAMILY ON INVENTORY_FAMILY.[DATAFLEX RECNUM ONE] = PAPSIZE.CATEGORY2
                           LEFT JOIN STKCATEG AS INVENTORY_CATEGORY ON INVENTORY_CATEGORY.[DATAFLEX RECNUM ONE] = PAPSIZE.CATEGORY3
                           LEFT OUTER JOIN JOBTYPE
                           ON
                           JOBTYPE.[PRODUCT CODE] = PAPSIZE.[PRODUCT CODE]
ORDER BY PAPSIZE.[INVENTORY CODE]
 
Shipping Across Customers Report
(replace the values highlighted with the appropriate ones)
(query last updated on: 10/28/2014)

SELECT 
        PKG.SHIP_DATE AS ShipDate, PKG.PACKAGE_ID AS PackageID, PKG.ACTUAL_WEIGHT AS PackageWt, ISNULL(PKG.ACTUAL_CHARGE, 0) + ISNULL(PKG.THIRD_BILL_CHARGE, 0) AS PackageCharge, 
		PKG.TRACKING_NO AS TrackingNo,   
		case when IsNull(PKG.THIRD_BILL_NO,'') <> '' Then PKG.THIRD_BILL_NO
			When ISNULL(PKG.CollectAcct,'') <> '' Then PKG.CollectAcct
			When ISNULL(PKG.PrePaidAcct,'') <> '' Then PKG.PrePaidAcct
			Else '' End AS ThirdPartyAcct, 
		DATEDIFF(minute, S.CREATED_DATE, PKG.SHIP_DATE) AS HoursToProcess, SP.BILL_NAME AS BillingComments, SM.SHIP_MODE_NAME AS ShipModeName, 
        CASE WHEN IsNull(PKG.[THIRD_BILL_NO], '') <> '' THEN PKG.[ACTUAL_CHARGE] ELSE 0 END AS ThirdPartyShipCost, 
		CASE WHEN IsNull(PKG.[THIRD_BILL_NO], '') = '' THEN PKG.[ACTUAL_CHARGE] ELSE 0 END AS NormalShipCost, 
		PKG.NEGOTIATED_CHARGE AS NegotiatedCost, PKG.THIRD_BILL_CHARGE AS ThirdPartyBillCharge, PKG.SURCHARGE AS Surcharge, 
        CASE WHEN PKG.[THIRD_BILL_CHARGE] > 0 THEN '3rd Party/Prepaid' WHEN PKG.[THIRD_BILL_NO] <> '' THEN PKG.[THIRD_BILL_NO] ELSE '' END AS ThirdPartyPrepaid,
        PICK.PICK_STATUS AS PickStatus, PICK.PICK_ID AS PickID,
            (SELECT        ISNULL(SUM(AMOUNT), 0) AS Expr1
            FROM            SO_CHARGE AS SC
            WHERE        (SO_ID = PKG.SO_ID) AND (CHARGE_TYPE = 'S')) AS Freight, S.CREATED_DATE AS OrderCreatedDate, S.SO_ID AS SalesOrderID, 
        S.CUST_SO_ID AS CustSOID, OBR.CUST_RECIP_ID, OBR.FIRST_NAME AS OrderByFName, OBR.MIDDLE_NAME AS OrderByMName, 
        OBR.LAST_NAME AS OrderByLName, OBR.COMPANY_NAME AS OrderByCompany, OBR.TITLE AS OrderByTitle, SBR.CUST_RECIP_ID AS CUST_SHIP_TO_ID, 
        SBR.FIRST_NAME AS ShipToFName, SBR.MIDDLE_NAME AS ShipToMName, SBR.LAST_NAME AS ShipToLName, SBR.COMPANY_NAME AS ShipToCompany, 
        OBA.ADDR_1 AS OrderByAdd1, OBA.ADDR_2 AS OrderByAdd2, OBA.ADDR_3 AS OrderByAdd3, OBA.CITY AS OrderByCity, OBA.STATE_CODE AS OrderByState, 
        OBA.ZIP_CODE AS OrderByZip, OC.COUNTRY_CODE3 AS OrderByCountry, SBA.ADDR_1 AS ShipToAdd1, SBA.ADDR_2 AS ShipToAdd2, SBA.ADDR_3 AS ShipToAdd3, 
        SBA.CITY AS ShipToCity, SBA.STATE_CODE AS ShipToState, SBA.ZIP_CODE AS ShipToZip, SC.COUNTRY_CODE3 AS ShipToCountry,
            (SELECT        ISNULL(SUM(ACT_PPU * ACT_QTY), 0) AS ActyChgs
            FROM            FF_TRANS
            WHERE        (SO_ID = S.SO_ID)) AS ConsActivityCharges, 
		LI.ITEM_NO AS ItemNo, LI.PACK_QTY AS ShipQty, PAP.[INVENTORY CODE] AS InventoryCode, 
        PAP.[REVISION CODE] AS RevisionCode, PAP.DESCRIPTION1 AS ItemDescription, PAP.[PRODUCT CODE] AS ProductCode, P.PROJ_NAME AS ProjectName, 
        P.CalcEstShipCharge, D.NAMES AS CustomerName, SO.ORIGIN_NAME AS OriginName, SPR.SHIPPER_NAME AS ShipperName, 
        SM.SHIP_MODE_DESC AS ShipModeDesc, PKG.CUST_ID AS CustomerID, PKG.PROJ_ID AS ProjectID, S.SHIP_TO_ID AS ShipToID, ISNULL(OBR.CUST_RECIP_ID, '') 
        + ' : ' + ISNULL(OBR.FIRST_NAME, '') + ' ' + ISNULL(OBR.MIDDLE_NAME, '') + ' ' + ISNULL(OBR.LAST_NAME, '') AS OrderByName, ISNULL(SBR.CUST_RECIP_ID, '') 
        + ' : ' + ISNULL(SBR.FIRST_NAME, '') + ' ' + ISNULL(SBR.MIDDLE_NAME, '') + ' ' + ISNULL(SBR.LAST_NAME, '') AS ShipToName, ISNULL(OBA.CITY, '') 
        + ' ' + ISNULL(OBA.STATE_CODE, '') + ' ' + ISNULL(OBA.ZIP_CODE, '') AS OrderByCityStateZip, ISNULL(SBA.CITY, '') + ' ' + ISNULL(SBA.STATE_CODE, '') 
        + ' ' + ISNULL(SBA.ZIP_CODE, '') AS ShipToCityStateZip, OBR.EMAIL AS OrderByEmail, SBR.EMAIL AS ShipToEmail, S.NEED_DATE AS NeedDate, 
        ISNULL(SBA.ADDR_1, '') + ' ' + ISNULL(SBA.ADDR_2, '') + ' ' + ISNULL(SBA.ADDR_3, '') AS ShipToAddress, LI.JOB_NO AS JobNo, LI.ORDER_QTY AS OrderQty, 
        LI.LINE_ITEM_NO AS LineItemNo, 
		CASE WHEN UPPER(ISNULL(PKG.SHIP_TO_COUNTRY, '')) = 'UNITED STATES' OR UPPER(ISNULL(PKG.SHIP_TO_COUNTRY, '')) = 'US' THEN 1 ELSE 0 END AS USAShip, 
		CASE WHEN UPPER(ISNULL(PKG.SHIP_TO_COUNTRY, '')) = 'UNITED STATES' OR UPPER(ISNULL(PKG.SHIP_TO_COUNTRY, '')) = 'US' THEN 0 ELSE 1 END AS ForShip, 
		CASE WHEN LI.BO_STATUS = 2 THEN 1 ELSE 0 END AS NoOfBOShipments, 
        CASE WHEN LI.BO_STATUS = 2 THEN 0 ELSE 1 END AS NoOfShipments, 
		ISNULL(PKG.SHIP_TO_COUNTRY, '') AS ShipToCountryPackage, ISNULL(LI.BO_STATUS, 0) AS BackOrderStaus, 
		ISNULL(LI.BO_QTY, 0) AS BackOrderQty, 0 AS USAItems, 0 AS ForItems, 0 AS NoOfLineItems, 0 AS NoOfBOLineItems,
            (SELECT        SUM(ACTUAL_CHARGE) AS Expr1
            FROM            PACKAGE AS PK
            WHERE        (ISNULL(THIRD_BILL_NO, '') <> '') AND (SO_ID = PKG.SO_ID)) AS SOThirdPartyShipCost,
            (SELECT        SUM(ACTUAL_CHARGE) AS Expr1
            FROM            PACKAGE AS PK
            WHERE        (ISNULL(THIRD_BILL_NO, '') = '') AND (SO_ID = PKG.SO_ID)) AS SONormalShipCost,
            (SELECT        SUM(ACTUAL_CHARGE) AS Expr1
            FROM            PACKAGE AS PK
            WHERE        (SO_ID = PKG.SO_ID)) AS SOTotalShipCost, LI.STATUS_ID AS LineItemStatus,
            (SELECT        COUNT(PACKAGE_ID) AS Expr1
            FROM            PACKAGE AS PK
            WHERE        (SO_ID = PKG.SO_ID)) AS PackageCount, SBR.TITLE AS ShipToTitle, STS.STATUS_NAME AS SOStatus, STSL.STATUS_NAME AS LIStatus, 
        STYP.SO_TYPE_NAME AS SOTypeName,   IsNull(LI.[MISJobNumber],0) as MISJobNumber, IsNull(LI.[MISSubJobNumber],0)  as MISSubJobNumber, 
		IsNull(LI.[MISComponent],0) as MISComponent, IsNull(PKG.ProofOfDelivery,'') as ProofOfDelivery
FROM    PACKAGE AS PKG 
	INNER JOIN PICK ON PICK.PICK_ID = PKG.PICK_ID 
	INNER JOIN SALES_ORDER AS S ON S.SO_ID = PKG.SO_ID 
	INNER JOIN SO_LINE_ITEM AS LI ON LI.SO_ID = PKG.SO_ID AND LI.OUTPUT_BATCH_ID = PKG.OUTPUT_BATCH_ID AND LI.PICK_ID = PKG.PICK_ID 
	LEFT OUTER JOIN PAPSIZE AS PAP ON LI.STKHEADR_RECNUM = PAP.[STKHEADR RECNUM] 
	LEFT OUTER JOIN SO_ORIGIN AS SO ON SO.SO_ORIGIN_ID = S.SO_ORIGIN_ID 
	INNER JOIN CUSTOMER AS CUST ON CUST.CUST_ID = PKG.CUST_ID 
	INNER JOIN DEBTOR AS D ON D.[DATAFLEX RECNUM ONE] = CUST.DEBTOR_RECNUM 
	INNER JOIN FFPROJECT AS P ON P.PROJ_ID = PKG.PROJ_ID 
	LEFT OUTER JOIN SHIPPING_MODE AS SM ON SM.SHIP_MODE_ID = PKG.SHIP_MODE_ID 
	LEFT OUTER JOIN SHIPPER AS SPR ON SPR.SHIPPER_ID = SM.SHIPPER_ID 
	LEFT OUTER JOIN SHIP_PROFILE AS SP ON SP.PROJ_ID = PKG.PROJ_ID AND SP.SHIP_MODE_ID = PKG.SHIP_MODE_ID AND SP.[DEFAULT] = 'Y' 
	INNER JOIN RECIPIENT AS SBR ON SBR.RECIP_ID = S.SHIP_TO_ID 
	INNER JOIN RECIPIENT AS OBR ON OBR.RECIP_ID = S.ORDER_BY_ID 
	INNER JOIN FFADDRESS AS SBA ON SBA.ADDRESS_ID = SBR.DEF_ADDRESS_ID 
	INNER JOIN FFADDRESS AS OBA ON OBA.ADDRESS_ID = OBR.DEF_ADDRESS_ID 
	INNER JOIN COUNTRY AS SC ON SC.COUNTRY_NUMBER = SBA.COUNTRY_ID 
	INNER JOIN COUNTRY AS OC ON OC.COUNTRY_NUMBER = OBA.COUNTRY_ID 
	INNER JOIN FFSTATUS AS STS ON STS.STATUS_ID = S.STATUS_ID 
	INNER JOIN FFSTATUS AS STSL ON STSL.STATUS_ID = LI.STATUS_ID 
	LEFT OUTER JOIN SO_TYPE AS STYP ON STYP.SO_TYPE_ID = S.SO_TYPE_ID 
WHERE  (PKG.[COMPANY CODE] = '01') AND (PKG.[PLANT CODE] = '0100')  AND 
	LI.STATUS_ID = 27  AND (PKG.[SHIP_DATE] >= '10/20/2014' AND PKG.[SHIP_DATE] < '10/28/2014 11:59 PM') 


sql query to pull the inventory balance on hand for each item and its respective mis job number and quantity
SELECT PAPSIZE.[CODE] as Inventory_Code, PAPSIZE.[INVENTORY CODE] as PAPSIZE_InventoryCode, PAPSIZE.[QTY ON HAND] as QtyOnHand,
STKROLLS.[QTY] as SkidQtyOnHand, STKROLLS.[DATAFLEX RECNUM ONE] as SkidID, STKROLLS.[MISJobNUmber] as MISJobNUmberForSkid
FROM STKROLLS
LEFT JOIN PAPSIZE
ON 
STKROLLS.[PAPSIZE RECNUM] = PAPSIZE.[DATAFLEX RECNUM ONE]
ORDER BY PAPSIZE.CODE


Fulfillment Order Turn Time Query
DECLARE @Date_ShipFromDate AS DATE
DECLARE @Date_ShipToDate AS DATE
DECLARE @Numeric_MaxReleaseToShipMins AS Integer
DECLARE @Numeric_MaxOrderToReleaseMins AS Integer
DECLARE @Numeric_MaxOrderToShipMins AS Integer

SET @Date_ShipFromDate = '09/01/2011'
SET @Date_ShipToDate = '10/01/2012'
SET @Numeric_MaxReleaseToShipMins = 1000
SET @Numeric_MaxOrderToReleaseMins = 1000
SET @Numeric_MaxOrderToShipMins = 1000


SELECT
	CONVERT(nvarchar(30), PACKAGE.CREATED_DATE, 20) AS PkgShipDate,  
	CONVERT(nvarchar(30), PICK.CREATED_DATE, 20) AS ReleaseDate,  
	CONVERT(nvarchar(30), SALES_ORDER.CREATED_DATE, 20) AS OrderDate,  

	PACKAGE.SO_ID AS SalesOrderID,
	PACKAGE.CUST_ID AS CustomerID,
	PACKAGE.PACKAGE_ID AS PkgID,
	PACKAGE.PICK_ID AS PickID,
	CASE
		WHEN PICK.PICK_STATUS = 18 THEN '18-Released'
		WHEN PICK.PICK_STATUS = 19 THEN '19-Inventory Transfer Completed'
		WHEN PICK.PICK_STATUS = 20 THEN '20-Pick Confirmation Done'
		WHEN PICK.PICK_STATUS = 21 THEN '21-Shipped'
		WHEN PICK.PICK_STATUS = 22 THEN '22-Pick Cancelled'
		WHEN PICK.PICK_STATUS = 23 THEN '23-On Hold'
	END AS PickStatus,	
	CAST(DATEDIFF(minute, PICK.CREATED_DATE, PACKAGE.CREATED_DATE) AS Decimal(10,2)) AS ReleaseToShipMins,
	CAST(DATEDIFF(minute, SALES_ORDER.CREATED_DATE, PICK.CREATED_DATE) AS Decimal(10,2)) AS OrderToReleaseMins,
	CAST(DATEDIFF(minute, SALES_ORDER.CREATED_DATE, PACKAGE.CREATED_DATE) AS Decimal(10,2)) AS OrderToShipMins,
	FFPROJECT.PROJ_NAME AS ProjectName,
	DEBTOR.NAMES AS CustomerName,
	-- Comment out the following SO_LINE_ITEM related lines if you do not need to see sales order line item details - i.e. just one query row per package
	SO_LINE_ITEM.ITEM_NO AS ItemNo,
	SO_LINE_ITEM.INVENTORY_CODE AS InventoryCode,
	SO_LINE_ITEM.ITEM_DESCRIPTION AS ItemDescription,
	SO_LINE_ITEM.ORDER_QTY AS OrderQty,
	CASE
		WHEN ISNULL(SO_LINE_ITEM.BO_STATUS,0) = 0 THEN '0-Never BackOrdered'
		WHEN ISNULL(SO_LINE_ITEM.BO_STATUS,0) = 1 THEN '1-Still on BackOrder'
		WHEN ISNULL(SO_LINE_ITEM.BO_STATUS,0) = 2 THEN '2-Was BackOrdered'		
	END AS BackOrderFlag

FROM
	PACKAGE
	INNER JOIN PICK ON PICK.PICK_ID = PACKAGE.PICK_ID
	INNER JOIN SALES_ORDER ON SALES_ORDER.SO_ID = PICK.SO_ID
	-- Comment out the following line if you do not need to see sales order line item details - i.e. just one query row per package
	INNER JOIN SO_LINE_ITEM ON SO_LINE_ITEM.PICK_ID = PICK.PICK_ID
	INNER JOIN FFPROJECT ON FFPROJECT.PROJ_ID = SALES_ORDER.PROJ_ID
	INNER JOIN CUSTOMER ON CUSTOMER.CUST_ID = FFPROJECT.CUST_ID
	INNER JOIN DEBTOR ON DEBTOR.[DATAFLEX RECNUM ONE] = CUSTOMER.DEBTOR_RECNUM

WHERE
	PACKAGE.CREATED_DATE >= @Date_ShipFromDate
	AND PACKAGE.CREATED_DATE < @Date_ShipToDate
	-- Gavin added these to filter out unusually long turn times that may be errors 
	-- Comment out these following three lines if you want to see ALL data
	AND (@Numeric_MaxReleaseToShipMins > 0 AND DATEDIFF(minute, PICK.CREATED_DATE, PACKAGE.CREATED_DATE) <= @Numeric_MaxReleaseToShipMins)
	AND (@Numeric_MaxOrderToReleaseMins > 0 AND DATEDIFF(minute, SALES_ORDER.CREATED_DATE, PICK.CREATED_DATE) <= @Numeric_MaxOrderToReleaseMins)
	AND (@Numeric_MaxOrderToShipMins > 0 AND DATEDIFF(minute, SALES_ORDER.CREATED_DATE, PACKAGE.CREATED_DATE) <= @Numeric_MaxOrderToShipMins)

ORDER BY
	PACKAGE.SO_ID,
	PACKAGE.PICK_ID,
	PACKAGE.PACKAGE_ID,
	-- Comment out the following line if you do not need to see sales order line item details - i.e. just one query row per package
	SO_LINE_ITEM.ITEM_NO

Query for High velocity inventory items	
SELECT top 100
   SUM((STKHIST.QUANTITY)*-1) as 'Qty Used',
   COUNT(PAPSIZE.[INVENTORY CODE]) as 'Transactions',
   (PAPSIZE.[INVENTORY CODE]) as 'Inventory Code', 
   PAPSIZE.DESCRIPTION1 as 'Inventory Description',
   CASE 
      WHEN PAPSIZE.[STOCK TYPE] = 'F' AND PAPSIZE.[SHIP CLASS] <> 'F' THEN 'Customer Owned'
      WHEN PAPSIZE.[STOCK TYPE] = 'F' AND PAPSIZE.[SHIP CLASS] = 'F' THEN 'Finished Goods'
      WHEN PAPSIZE.[STOCK TYPE] = 'P' THEN 'Paper'
      WHEN PAPSIZE.[STOCK TYPE] = 'R' THEN 'Raw Materials'
      WHEN PAPSIZE.[STOCK TYPE] = 'M' THEN 'Postage Inventory'
   END AS InventoryType,
   ISNULL(PAPSIZE.[LOCATION],'') AS 'PickLocation',
   ISNULL(STKLOCHD.[TYPE],'') AS LocationType,
   ISNULL(STKLOCHD.[SORT SEQUENCE],0) AS WalkSequence,
   DEBTOR.NAMES as 'CustomerName'
FROM 
   STKHIST
   LEFT JOIN PAPSIZE ON STKHIST.[PAPSIZE RECNUM] = PAPSIZE.[DATAFLEX RECNUM ONE]
   LEFT JOIN DEBTOR ON DEBTOR.[DATAFLEX RECNUM ONE] = PAPSIZE.[CREDITOR RECNUM]
   LEFT JOIN STKLOCHD ON STKLOCHD.LOCATION = PAPSIZE.LOCATION

WHERE 
   STKHIST.TYPE IN ('JC','FS','KP','FC','FV')
   AND STKHIST.[DATE] >= '01/01/2000'
   AND STKHIST.[DATE] <= '01/01/2014'
   
   AND (PAPSIZE.[STOCK TYPE] + PAPSIZE.[SHIP CLASS]) IN ('F','P','R','FF')

GROUP BY 
   PAPSIZE.[STOCK TYPE],
   PAPSIZE.[SHIP CLASS],
   PAPSIZE.[INVENTORY CODE], 
   PAPSIZE.DESCRIPTION1,
   PAPSIZE.[LOCATION],
   STKLOCHD.[TYPE],
   STKLOCHD.[SORT SEQUENCE],
   DEBTOR.[NAMES]

ORDER BY 
   COUNT(PAPSIZE.[INVENTORY CODE]) DESC,
   SUM(STKHIST.QUANTITY) DESC,
   InventoryType,
   PAPSIZE.[INVENTORY CODE] ASC

 
Pick confirmation query to show items by package quantities
[enter pick ID in highlighted area below]
select PackageItem.PickId, PackageItem.PackageId, 
ISNULL(Package.[ACTUAL_CHARGE], 0.00) as ActualCharge, ISNULL(Package.[ACTUAL_WEIGHT], 0) as ActualWeight, 
ISNULL(Package.[NEGOTIATED_CHARGE], 0.00) as NegotiatedCharge, ISNULL(Package.[TRACKING_NO], '') as TrackingNumber, 
PackageItem.ItemNo, PackageItem.PackageQty, PAPSIZE.[INVENTORY CODE], PAPSIZE.[DESCRIPTION1]
FROM PackageItem
INNER JOIN PAPSIZE ON CONVERT(VARCHAR(15), PackageItem.ItemNo) = CONVERT(varchar(15), PAPSIZE.CODE)
RIGHT JOIN PACKAGE ON PACKAGE.PACKAGE_ID = PackageItem.PackageId
where PackageItem.PickID = 32036
Order By PickID, PackageID
Query for Date Range of Package ID Information
Declare @FromShipDate Datetime
Declare @ToShipDate Datetime

SET @FromShipDate = '10/01/2014'
SET @ToShipDate = '11/28/2014'

select PackageItem.CreatedDate, PICK.PICK_BY as PickedBy, PackageItem.PickId, PackageItem.PackageId, 
ISNULL(Package.[ACTUAL_CHARGE], 0.00) as ActualCharge, ISNULL(Package.[ACTUAL_WEIGHT], 0) as ActualWeight, 
ISNULL(Package.[NEGOTIATED_CHARGE], 0.00) as NegotiatedCharge, ISNULL(Package.[TRACKING_NO], '') as TrackingNumber, 
PackageItem.ItemNo, PackageItem.PackageQty, PAPSIZE.[INVENTORY CODE], PAPSIZE.[DESCRIPTION1]
FROM PackageItem
INNER JOIN PICK ON PICK.PICK_ID = PackageItem.PickId
INNER JOIN PAPSIZE ON CONVERT(VARCHAR(15), PackageItem.ItemNo) = CONVERT(varchar(15), PAPSIZE.CODE)
RIGHT JOIN PACKAGE ON PACKAGE.PACKAGE_ID = PackageItem.PackageId
where (PackageItem.CreatedDate >= @FromShipDate) AND (PackageItem.CreatedDate <= @ToShipDate)
Order By CreatedDate, PickID, PackageID
SQL Query to list all recipient-based shipping profiles with third party shipping:

SELECT     SHIP_PROFILE.ACTIVE, SHIP_PROFILE.BILL_NAME, SHIP_PROFILE.BILL_NO, SHIP_PROFILE.DELIVERY_ACKN, 
                      SHIP_PROFILE.INS_AMOUNT, SHIP_PROFILE.INSURANCE, SHIP_PROFILE.RECIP_ID, SHIP_PROFILE.SAT_DELIVERY, 
                      SHIP_PROFILE.SHIP_MODE_DESC, SHIP_PROFILE.SHIP_MODE_ID, SHIP_PROFILE.RESIDENTIAL, SHIP_PROFILE.SHIP_CONF, 
                      SHIP_PROFILE.CollectAcct, SHIP_PROFILE.PrePaidAcct, SHIP_PROFILE.AccountType, FFADDRESS.ADDR_1, FFADDRESS.CITY, FFADDRESS.STATE_CODE, 
                      FFADDRESS.ZIP_CODE, RECIPIENT.FIRST_NAME, RECIPIENT.LAST_NAME
FROM         SHIP_PROFILE INNER JOIN
                      RECIPIENT ON SHIP_PROFILE.RECIP_ID = RECIPIENT.RECIP_ID INNER JOIN
                      FFADDRESS ON SHIP_PROFILE.ADDRESS_ID = FFADDRESS.ADDRESS_ID
WHERE     (SHIP_PROFILE.RECIP_ID > 0) AND AccountType=3
If you want ALL recipient based shipping profile remove the highlighted line above and you will get all (the above is just third party)
 
 
SQL Query for Inventory Transactions for One Item
DECLARE @DateFrom nvarchar(50)
DECLARE @DateTo nvarchar(50)
DECLARE @PrinstreamID nvarchar(50)
Set @PrinstreamID = '33432'
Set @DateFrom = '01/01/2014'
Set @DateTo = '01/01/2015'
SELECT PAPSIZE.[CODE] as PrinstreamID,
PAPSIZE.[INVENTORY CODE] as ProductCode, STKHIST.MISJobNumber, 
STKHIST.TYPE as TransactionType, 
STKHIST.[QUANTITY] ,STKHIST.DATE
FROM STKHIST

LEFT JOIN PAPSIZE
ON 
PAPSIZE.[DATAFLEX RECNUM ONE] = STKHIST.[PAPSIZE RECNUM]
WHERE
STKHIST.[date] Between @DateFrom  and  @DateTo
AND 
PAPSIZE.[CODE]  = @PrinstreamID

SELECT
	CONVERT(bit,0) AS Tag,
	0.0 AS ChargeableAmount,
	DEBTOR.[AC NO] AS CustomerAcNo,
	DEBTOR.NAMES AS CustomerName,
	DEBTOR.[DATAFLEX RECNUM ONE] AS arcustomerid,
	STKLOCHD.[TYPE] AS LocationType,
	SUM(STKLOCLN.QUANTITY) AS QtyInLocationType,
	COUNT(STKLOCHD.[TYPE]) AS LocationCount,
FROM
	STKLOCLN
	LEFT JOIN STKLOCHD ON STKLOCHD.LOCATION - STKLOCLN.LOCATION
		AND STKLOCHD.[ChargeForStorage] = 1
	LEFT JOIN PAPSIZE ON PAPSIZE.[DATAFLEX RECNUM ONE] = STKLOCLN.[PAPSIZE RECNUM]
	LEFT JOIN DEBTOR ON DEBTOR.[DATAFLEX RECNUM ONE] = PAPSIZE.[CREDITOR RECNUM]
	LEFT JOIN Mat_StorBill ON Mat_StorBill.AR_CustomerID = DEBTOR.[DATAFLEX RECNUM ONE]
	LEFT JOIN 
	(SELECT
		PAPSIZE_2.[CREDITOR RECNUM],
		PAPSIZE_2.[INVENTORY CODE],
		PAPSIZE_2.[MASTER DATE] AS ItemCreationDate,
		DATEDIFF(DAY,PAPSIZE_2.[MASTER DATE], GETDATE()) AS DaysInWarehouse,
		MAX(PAPSIZE_2.[DATAFLEX RECNUM ONE]) AS papsize_recnum
	FROM
		PAPSIZE AS PAPSIZE_2
	WHERE 
		ISNULL(PAPSIZE_2.[CREDITOR RECNUM],0) > 0
		AND PAPSIZE_2.ChargeForStorage = 1
			AND (PAPSIZE_2.[STOCK TYPE] = 'F'
				AND (PAPSIZE_2.[SHIP CLASS] = ''
					OR PAPSIZE_2.[SHIP CLASS] IS NULL)
					)
		AND PAPSIZE_2.[COMPANY CODE] = '01'
		AND PAPSIZE_2.[PLANT CODE] = '0100'
		AND PAPSIZE_2.[STOCK TYPE] <> 'M'
	GROUP BY 
		PAPSIZE_2.[CREDITOR RECNUM],
		PAPSIZE_2.[INVENTORY CODE],
		PAPSIZE_2.[MASTER DATE]
		) AS subQry
	ON SUBQRY.PAPSIZE_RECNUM = PAPSIZE.[DATAFLEX RECNUM ONE]
WHERE 
	STKLOCLN.QUANTITY > 0
	AND PAPSIZE.ChargeForStorage = 1
	AND ISNULL(PAPSIZE.[CREDITOR RECNUM],0) > 0
	AND ISNULL(DEBTOR.[DATAFLEX RECNUM ONE],0) > 0
	--AND PAPSIZE.[STOCK TYPE] = 'F'
	--AND ISNULL(PAPSIZE.[SHIP CLASS],'') = ''
	AND STKLOCHD.ChargeForStorage = 1
	AND Mat_StorBill.DAYSFREESTORE > 0
	AND STKLOCHD.ChargeForStorage = 1
	AND DEBTOR.ChargeForStorage = 1
	AND SUBQRY.DaysInWarehouse > Mat_StorBill.DAYSFREESTORE
GROUP BY
	STKLOCHD.[Type],
	DEBTOR.[DATAFLEX RECNUM ONE],
	DEBTOR.[AC NO],
	DEBTOR.NAMES
ORDER BY
	CustomerName, DEBTOR.[DATAFLEX RECNUM ONE]
	