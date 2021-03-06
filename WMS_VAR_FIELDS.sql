/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP 100 [ACTIVE]
      ,[CUST_ID]
      ,[FIELD_ASSOC]
      ,[FIELD_DESC]
      ,[FIELD_ID]
      ,[FIELD_NAME]
      ,[FIELD_TYPE]
      ,[FIELD_WIDTH]
      ,[VAR_FIELD_NUM]
      ,[ReportSeqNo]
  FROM [LiveData].[dbo].[VAR_FIELDS]
  WHERE CUST_ID = 8



  DECLARE @ACCTNO varchar(8), @PROJNAME varchar(21)
Set @ACCTNO = 'HOUSEACC'
Set @PROJNAME = 'Sales Orders'
select d.[AC NO], c.CUST_ID, ff.PROJ_ID, pvf.FIELD_ORDER, vf.FIELD_NAME
FROM LiveData.dbo.Debtor d with (nolock)
      inner join LiveData.dbo.Customer c with (nolock) on (c.DEBTOR_RECNUM = d.[DATAFLEX RECNUM ONE] and c.ACTIVE = 1)
      inner join LiveData.dbo.FFProject ff with (nolock) on (ff.CUST_ID = c.CUST_ID and ff.ACTIVE = 1)
      inner join LiveData.dbo.PROJ_VAR_FIELDS pvf with (nolock) on (pvf.CUST_ID =  c.CUST_ID and pvf.PROJ_ID = ff.PROJ_ID)
      inner join LiveData.dbo.VAR_FIELDS vf with (nolock) on (vf.CUST_ID = c.CUST_ID and vf.FIELD_ID = pvf.FIELD_ID and vf.ACTIVE = 1)
where d.[AC NO] = @ACCTNO and ff.PROJ_NAME = @PROJNAME and d.ACTIVE = 'Y' 
order by d.[AC NO], ff.PROJ_ID, pvf.FIELD_ORDER

