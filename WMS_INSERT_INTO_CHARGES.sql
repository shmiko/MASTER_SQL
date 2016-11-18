USE [LiveData]
GO

/*CREATE TABLE Charges
(
Charges_ID int not null,
CustomerID char(8) not null,
chargeType varchar(50),
charge float,
frequency varchar(20),
PRIMARY KEY (Charges_ID)
);*/

INSERT INTO [dbo].[Charges]
           ([Charges_ID]
           ,[CustomerID]
           ,[chargeType]
           ,[charge]
           ,[frequency])
     VALUES
           (4
           ,'31BUPA'
           ,'Pallet Storage Fee'
           ,16.00
           ,'Monthly'),
		   (5
           ,'V-BROINV'
           ,'Pallet Storage Fee'
           ,15.00
           ,'Monthly'), 
		   (6
           ,'V-WEXAU'
           ,'Pallet Storage Fee'
           ,15.00
           ,'Monthly'),
		   (7
           ,'31BUPA'
           ,'Shelf Storage Fee'
           ,8.00
           ,'Monthly'),
		   (8
           ,'V-BROINV'
           ,'Shelf Storage Fee'
           ,7.50
           ,'Monthly'), 
		   (9
           ,'V-WEXAU'
           ,'Shelf Storage Fee'
           ,7.50
           ,'Monthly')
GO

SELECT TOP 10 [Charges_ID]
      ,[CustomerID]
      ,[chargeType]
      ,[charge]
      ,[frequency]
   FROM [LiveData].[dbo].[Charges]
GO

