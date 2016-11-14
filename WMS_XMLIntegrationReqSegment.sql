/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP 1000 [XMLIntegrationReqSegmentID]
      ,[RequestID]
      ,[SegmentNo]
      ,[MessageSegment]
      ,[TransNumber]
  FROM [LiveData].[dbo].[XMLIntegrationReqSegment]
  Order By [XMLIntegrationReqSegmentID] Desc