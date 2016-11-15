CREATE FUNCTION dbo.ufnGetStockSOH(@Product varchar(40))  
RETURNS int   
AS   
-- Returns the stock level for the product.  
BEGIN  
    DECLARE @ret int;  
    SELECT @ret =
		--Cast(StkItem.[INVENTORY CODE]as varchar) as [INV_CODE],
		ISNULL(LinkedHist.[TOT QTY],0) - (ISNULL((
													SELECT SUM([QTY COMMIT]) 
													FROM STKSKIDRSV outRSV
														LEFT JOIN SO_LINE_ITEM
														ON SO_LINE_ITEM.SO_ID = outRSV.[SO ID] 
														AND SO_LINE_ITEM.LINE_ITEM_NO = outRSV.[LINE ITEM ID]
													WHERE CAST( outRSV.[PAPSIZE CODE] as varchar) = CAST( StkItem.[CODE] as varchar)
														AND [PICK DATE] <= GETDATE() ), 0) - ISNULL(((
																									SELECT ISNULL( SUM( SO_LINE_ITEM.[PACK_QTY]),0)
																									FROM STKSKIDRSV
																										LEFT JOIN SO_LINE_ITEM
																										ON SO_LINE_ITEM.SO_ID = STKSKIDRSV.[SO ID]
																										AND SO_LINE_ITEM.LINE_ITEM_NO = STKSKIDRSV.[LINE ITEM ID]	
																									WHERE cast(SO_LINE_ITEM.ITEM_NO as varchar) = cast(StkItem.[CODE] as varchar)
																										AND [STATUS_DATE] <= GETDATE() and STKSKIDRSV.[PICK DATE] < = GETDATE()
																										AND [STATUS_ID] = 27)), 0)) 
	FROM PAPSIZE as StkItem 
		LEFT OUTER JOIN STKCATEG
		ON STKCATEG.[DATAFLEX RECNUM ONE] = StkItem.CATEGORY1
		LEFT OUTER JOIN DEBTOR as LinkedDebtor 
		ON StkItem.[CREDITOR RECNUM] = LinkedDebtor.[DATAFLEX RECNUM ONE] 
		LEFT OUTER JOIN CREDITOR AS LinkedVendor on StkItem.[DEBTOR RECNUM] = LinkedVendor.[DATAFLEX RECNUM ONE] 
		LEFT JOIN STKHIST AS LinkedHist 
		ON StkItem.[dataflex recnum one] = LinkedHist.[papsize recnum] 
		AND LinkedHist.[date] <= GETDATE()
		AND LinkedHist.[dataflex recnum one] in 
								( SELECT top 1 f.[dataflex recnum one] from stkhist as f 
								WHERE StkItem.[dataflex recnum one] = f.[papsize recnum]
								AND f.[date] <= GETDATE() order by f.[date] desc ) 
	 
    WHERE Cast(StkItem.[INVENTORY CODE]as varchar) = @Product;   
       -- AND p.LocationID = '6';  
     IF (@ret IS NULL)   
        SET @ret = 0;  
    RETURN @ret;  
END;  
GO  

