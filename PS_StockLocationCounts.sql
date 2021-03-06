USE [LiveData]
GO
/****** Object:  UserDefinedFunction [dbo].[ufnGetLocnCountofStocks]    Script Date: 22/12/2016 8:37:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[ufnGetLocnCountofStocks](@Locn varchar(40))  
RETURNS int   
AS   
-- Returns the item count per location.  
BEGIN  
    DECLARE @ret int;  
    SELECT @ret =
		Count(DISTINCT PAPSIZE.[INVENTORY CODE])
        FROM STKLOCLN
            LEFT JOIN STKLOCHD ON STKLOCHD.LOCATION = STKLOCLN.LOCATION AND STKLOCHD.[ChargeForStorage] = 1
            LEFT JOIN PAPSIZE ON PAPSIZE.[DATAFLEX RECNUM ONE] = STKLOCLN.[PAPSIZE RECNUM]
            LEFT JOIN DEBTOR ON DEBTOR.[DATAFLEX RECNUM ONE] = PAPSIZE.[CREDITOR RECNUM]
        WHERE 
            PAPSIZE.ChargeForStorage = 1
            AND ISNULL(PAPSIZE.[CREDITOR RECNUM],0) > 0
            AND ISNULL(DEBTOR.[DATAFLEX RECNUM ONE],0) > 0
            AND STKLOCHD.ChargeForStorage = 1
            AND DEBTOR.ChargeForStorage = 1
            AND STKLOCHD.ChargeForStorage = 1
			AND STKLOCLN.[LOCATION] = @Locn;    
     IF (@ret IS NULL)   
        SET @ret = 0;  
    RETURN @ret;  
END;  
