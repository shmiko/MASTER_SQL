USE [LiveData]
GO

INSERT INTO [dbo].[Charges]
           ([CustomerID]
           ,[chargeType]
           ,[charge]
           ,[frequency])
     VALUES
           ('31BUPA','ADMIN FEE', 200, 'MONTHLY'),
		   ('V-BROINV','ADMIN FEE', 100,'MONTHLY'),
		   ('V-WEXAU ','ADMIN FEE',180,'MONTHLY')
GO


