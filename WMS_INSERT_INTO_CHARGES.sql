USE [LiveData]
GO

INSERT INTO [dbo].[Charges]
           ([Charges_ID]
           ,[CustomerID]
           ,[chargeType]
           ,[charge]
           ,[frequency])
     VALUES
           (1
           ,'31BUPA'
           ,'ADMIN FEE'
           ,200
           ,'Monthly'),
		   (2
           ,'V-BROINV'
           ,'ADMIN FEE'
           ,100
           ,'Monthly')
GO

SELECT TOP 10 [Charges_ID]
      ,[CustomerID]
      ,[chargeType]
      ,[charge]
      ,[frequency]
   FROM [LiveData].[dbo].[Charges]
GO

