USE [LiveData]
GO
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
				 CAST([bsg_support].[dbo].[ufnGetStockSOH] (PAPSIZE.[INVENTORY CODE]) AS INT) AS QtyInLocation,   
				[bsg_support].[dbo].[ufnGetLocnCountofStocks](STKLOCLN.[LOCATION]) AS LocationCount,          
                STKLOCLN.[LOCATION] AS Location,
                PAPSIZE.[INVENTORY CODE]
FROM
                [LiveData].[dbo].STKLOCLN
                LEFT JOIN [LiveData].[dbo].STKLOCHD ON STKLOCHD.LOCATION = STKLOCLN.LOCATION AND STKLOCHD.[ChargeForStorage] = 1
                LEFT JOIN [LiveData].[dbo].PAPSIZE ON PAPSIZE.[DATAFLEX RECNUM ONE] = STKLOCLN.[PAPSIZE RECNUM]
                LEFT JOIN [LiveData].[dbo].DEBTOR ON DEBTOR.[DATAFLEX RECNUM ONE] = PAPSIZE.[CREDITOR RECNUM]
                LEFT JOIN [LiveData].[dbo].Mat_StorBill ON Mat_StorBill.AR_CustomerID = DEBTOR.[DATAFLEX RECNUM ONE]
               
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
                --AND DEBTOR.[DATAFLEX RECNUM ONE] = 10 --BUPA

ORDER BY
                CustomerName, --DEBTOR.[DATAFLEX RECNUM ONE],
                LocationType;--, STKLOCHD.[TYPE]            
                  --combined and working
--OUTPUT TO 'c:\\test\\Printstreamsales.csv'; 
 --INTO OUTFILE 'c:\\test\\Printstreamsales.csv' FIELDS TERMINATED BY ',' LINES TERMINATED BY 'n';