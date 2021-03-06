USE [LiveData]
GO
/****** Object:  UserDefinedFunction [dbo].[ufnGetPickLineCount]    Script Date: 22/12/2016 2:20:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[ufnGetPickLineCount](@SO_ID varchar(10))  
RETURNS int   
AS   
-- Returns the stock level for the product.  
BEGIN  
    DECLARE @ret int;  
    SELECT @ret = COUNT(*)
	FROM  LiveData.dbo.[SO_LINE_ITEM]
		INNER JOIN LiveData.dbo.SALES_ORDER ON SALES_ORDER.SO_ID = SO_LINE_ITEM.SO_ID
    WHERE SALES_ORDER.SO_ID = @SO_ID
	AND [SO_LINE_ITEM].INVENTORY_CODE NOT IN ('EMERQSRFEE');   
     IF (@ret IS NULL)   
        SET @ret = 0;  
    RETURN @ret;  
END;  
