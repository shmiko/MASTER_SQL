SELECT
                CONVERT(bit,0) AS Tag,
                0.0 AS ChargeableAmount,
                DEBTOR.[AC NO] AS CustomerAcNo,
                DEBTOR.NAMES AS CustomerName,
                DEBTOR.[DATAFLEX RECNUM ONE] AS arcustomerid,
                STKLOCHD.[TYPE] AS LocationType,
				 CAST([dbo].[ufnGetStockSOH] (PAPSIZE.[INVENTORY CODE]) AS INT) AS QtyInLocation,   
				[dbo].[ufnGetLocnCountofStocks](STKLOCLN.[LOCATION]) AS LocationCount,          
                STKLOCLN.[LOCATION] AS Location,
                PAPSIZE.[INVENTORY CODE]
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
                --AND DEBTOR.[DATAFLEX RECNUM ONE] = 12

ORDER BY
                CustomerName, --DEBTOR.[DATAFLEX RECNUM ONE],
                LocationType--, STKLOCHD.[TYPE]            
                  --combined and working
