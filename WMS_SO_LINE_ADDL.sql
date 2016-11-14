/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP 10 [CUST_ID]
      ,[FIELD_ID]
      ,[FIELD_NAME]
      ,[FIELD_VALUE]
      ,[LINE_ITEM_NO]
      ,[NOM_ID]
      ,[SO_ID]
      ,[SO_LINE_ADDL_ID]
  FROM [LiveData].[dbo].[SO_LINE_ADDL]
  ORDER BY SO_ID Desc
  --WHERE SO_ID = 355