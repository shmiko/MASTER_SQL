/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP 100 [CUST_ID]
      ,[FIELD_ID]
      ,[FIELD_NAME]
      ,[FIELD_VALUE]
      ,[SO_ADDL_ID]
      ,[SO_ID]
  FROM [LiveData].[dbo].[SO_ADDL]