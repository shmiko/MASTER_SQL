SELECT
	CONVERT(bit,0) AS Tag,
	0.0 AS ChargeableAmount,
	DEBTOR.[AC NO] AS CustomerAcNo,
	DEBTOR.NAMES AS CustomerName,
	DEBTOR.[DATAFLEX RECNUM ONE] AS arcustomerid,
	STKLOCHD.[TYPE] AS LocationType,
	SUM(STKLOCLN.QUANTITY) AS QtyInLocationType,
	STKLOCLN.[LOCATION] AS Location,
	SUBQRY.CountOfStocks AS LocationCount,
	PAPSIZE.[INVENTORY CODE]
FROM
	STKLOCLN
	LEFT JOIN STKLOCHD ON STKLOCHD.LOCATION = STKLOCLN.LOCATION AND STKLOCHD.[ChargeForStorage] = 1
	LEFT JOIN PAPSIZE ON PAPSIZE.[DATAFLEX RECNUM ONE] = STKLOCLN.[PAPSIZE RECNUM]
	LEFT JOIN DEBTOR ON DEBTOR.[DATAFLEX RECNUM ONE] = PAPSIZE.[CREDITOR RECNUM]
	LEFT JOIN Mat_StorBill ON Mat_StorBill.AR_CustomerID = DEBTOR.[DATAFLEX RECNUM ONE]
	LEFT JOIN 
	( SELECT Count(DISTINCT PAPSIZE.[INVENTORY CODE]) AS CountOfStocks
	 , STKLOCLN.[LOCATION]--, DEBTOR.NAMES
	 ,MAX(PAPSIZE.[DATAFLEX RECNUM ONE]) AS papsize_recnum
       --                 CASE WHEN STKLOCHD.[TYPE] = 'PS' THEN 'E- Pallets'
       --                   WHEN STKLOCHD.[TYPE] = 'SH' THEN 'F- Shelves'
		--				  ELSE 'unknown'
       --                   END AS "Note",NULL,NULL,NULL,NULL
              FROM STKLOCLN
				LEFT JOIN STKLOCHD ON STKLOCHD.LOCATION = STKLOCLN.LOCATION AND STKLOCHD.[ChargeForStorage] = 1
				LEFT JOIN PAPSIZE ON PAPSIZE.[DATAFLEX RECNUM ONE] = STKLOCLN.[PAPSIZE RECNUM]
				LEFT JOIN DEBTOR ON DEBTOR.[DATAFLEX RECNUM ONE] = PAPSIZE.[CREDITOR RECNUM]
              WHERE --STKLOCLN.QUANTITY > 0
				--AND 
				PAPSIZE.ChargeForStorage = 1
				AND ISNULL(PAPSIZE.[CREDITOR RECNUM],0) > 0
				AND ISNULL(DEBTOR.[DATAFLEX RECNUM ONE],0) > 0
				AND STKLOCHD.ChargeForStorage = 1
				AND DEBTOR.ChargeForStorage = 1
				AND STKLOCHD.ChargeForStorage = 1
				AND DEBTOR.[DATAFLEX RECNUM ONE] = 10 --BUPA
              GROUP BY 
				STKLOCLN.[LOCATION],
				STKLOCHD.[Type]
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
	--AND SUBQRY.DaysInWarehouse > Mat_StorBill.DAYSFREESTORE
	AND DEBTOR.[DATAFLEX RECNUM ONE] = 10 --BUPA
GROUP BY
	STKLOCLN.[LOCATION],
	PAPSIZE.[INVENTORY CODE],
	STKLOCHD.[Type],
	DEBTOR.[DATAFLEX RECNUM ONE],
	DEBTOR.[AC NO],
	DEBTOR.NAMES,
	SUBQRY.CountOfStocks
ORDER BY
	CustomerName, --DEBTOR.[DATAFLEX RECNUM ONE],
	LocationType--, STKLOCHD.[TYPE]	
	  --combined and working