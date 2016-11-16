--CREATE VIEW EOM AS

SELECT
                CASE 
				WHEN STKLOCHD.[TYPE] = 'BP' Then 'Pallet Storage Fee (' + CAST([dbo].[ufnGetLocnCountofStocks](STKLOCLN.[LOCATION]) AS VARCHAR) + ' x $' + CAST((Select Charges.charge from Charges where Charges.CustomerID = DEBTOR.[AC NO] AND Charges.chargeType = 'Pallet Storage Fee')/[dbo].[ufnGetLocnCountofStocks](STKLOCLN.[LOCATION]) AS VARCHAR) + ' ea)'
				WHEN STKLOCHD.[TYPE] = 'SH' Then 'Shelf Storage Fee (' + CAST([dbo].[ufnGetLocnCountofStocks](STKLOCLN.[LOCATION]) AS VARCHAR) + ' x $' + CAST((Select Charges.charge from Charges where Charges.CustomerID = DEBTOR.[AC NO] AND Charges.chargeType = 'Shelf Storage Fee')/[dbo].[ufnGetLocnCountofStocks](STKLOCLN.[LOCATION]) AS VARCHAR) + ' ea)'
				ELSE 'Storage Charges'
				END AS Description,
				CASE 
				WHEN (Select Charges.charge from Charges where Charges.CustomerID = DEBTOR.[AC NO] AND Charges.chargeType = 'Pallet Storage Fee') > 0 Then (Select Charges.charge from Charges where Charges.CustomerID = DEBTOR.[AC NO] AND Charges.chargeType = 'Pallet Storage Fee')/[dbo].[ufnGetLocnCountofStocks](STKLOCLN.[LOCATION])
				WHEN (Select Charges.charge from Charges where Charges.CustomerID = DEBTOR.[AC NO] AND Charges.chargeType = 'Shelf Storage Fee') > 0 Then (Select Charges.charge from Charges where Charges.CustomerID = DEBTOR.[AC NO] AND Charges.chargeType = 'Shelf Storage Fee')/[dbo].[ufnGetLocnCountofStocks](STKLOCLN.[LOCATION])
				ELSE 0
				END AS ChargeableAmount,
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
                AND STKLOCHD.ChargeForStorage = 1
                AND Mat_StorBill.DAYSFREESTORE > 0
                AND STKLOCHD.ChargeForStorage = 1
                AND DEBTOR.ChargeForStorage = 1


ORDER BY
                CustomerName,
                LocationType;