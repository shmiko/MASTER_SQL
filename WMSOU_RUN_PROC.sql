USE [bsg_support]
GO

DECLARE	@return_value int

EXEC	@return_value = [dbo].[WMS2JAV_SOU]
		@EditDate = N'2016-11-14 12:40:07.00'

SELECT	'Return Value' = @return_value

GO