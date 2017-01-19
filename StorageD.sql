SELECT
                CONVERT(bit,0)													as Tag,
                DEBTOR.[AC NO]													as CustomerAcNo,
				DEBTOR.NAMES													as CustomerName,
                DEBTOR.[DATAFLEX RECNUM ONE]									as arcustomerid,     
				''																as ParentId, 
				''																as Parent, 
				''																as CostCentre,
				''																as OrderNum, 
				''																as OrderWareNum, 
				''																as CustRef, 
				''																as PickSlip,
				''																as DespNote, 
				''																as DespDate, 
				STKLOCHD.[TYPE]													as LocationType, 
				PAPSIZE.[INVENTORY CODE]										as Sku, 
				''																as "Description",
				CAST([dbo].[ufnGetStockSOH] (PAPSIZE.[INVENTORY CODE]) AS INT) 	as QtyInLocation,  
				''																as UOI	, 
				[dbo].[ufnGetLocnCountofStocks](STKLOCLN.[LOCATION])			as LocationCount, 
				0.0																as ChargeableAmount,
				''																as SellExcl, 
				''																as SellIncl, 
				--''																as OrderByCustomerRecipientID,
				''																as DeliverTo, 
				''																as AttentionTo,
				''																as Address1, 
				''																as Address2, 
				''																as Address3, 
				''																as Suburb, 
				''																as "State", 
				''																as PostCode, 
				''																as Country,
				''																as "Weight", 
				''																as Packages,
				STKLOCLN.[LOCATION]												as "Location" 
												
FROM
                STKLOCLN
                LEFT JOIN STKLOCHD ON STKLOCHD.LOCATION = STKLOCLN.LOCATION AND STKLOCHD.[ChargeForStorage] = 1
                LEFT JOIN PAPSIZE ON PAPSIZE.[DATAFLEX RECNUM ONE] = STKLOCLN.[PAPSIZE RECNUM]
                LEFT JOIN DEBTOR ON DEBTOR.[DATAFLEX RECNUM ONE] = PAPSIZE.[CREDITOR RECNUM]
                LEFT JOIN Mat_StorBill ON Mat_StorBill.AR_CustomerID = DEBTOR.[DATAFLEX RECNUM ONE]
               
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
                --AND SUBQRY.DaysInWarehouse > Mat_StorBill.DAYSFREESTORE
               -- AND DEBTOR.[DATAFLEX RECNUM ONE] = 10 --BUPA

ORDER BY
                CustomerName, --DEBTOR.[DATAFLEX RECNUM ONE],
                LocationType--, STKLOCHD.[TYPE]            
                  --combined and working
