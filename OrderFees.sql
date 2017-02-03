/****** Script for SelectTopNRows command from SSMS  ******/
Select 

so.CUST_ID as CustomerID,
d.[AC NO] as Customer,
so.SO_ID as SOPNo,
so.CUST_SO_ID as JavelinNum,
so.PROJ_ID as SOPProjID,
ffp.PROJ_ID as ProjID,
so.SO_ORIGIN_ID as SOPOriginID,
o.ORIGIN_NAME as SOPOriginName,
po.SOOriginID as projOriginID,
po.SOOriginCharge as projOriginChargeValue


From dbo.SALES_ORDER so
LEFT OUTER JOIN livedata.dbo.FFPROJECT ffp on ffp.PROJ_ID = so.PROJ_ID
LEFT OUTER JOIN livedata.dbo.SO_ORIGIN o on o.SO_ORIGIN_ID = so.SO_ORIGIN_ID
LEFT OUTER JOIN livedata.dbo.ProjSOOrigin po on po.SOOriginId = so.SO_ORIGIN_ID
LEFT OUTER JOIN livedata.dbo.Customer c on c.CUST_ID = so.CUST_ID
LEFT OUTER JOIN livedata.dbo.DEBTOR d ON d.[DATAFLEX RECNUM ONE] = c.DEBTOR_RECNUM

where d.[AC NO] <> 'HOUSEACC'
and so.SO_ORIGIN_ID <> '0'
and po.SOOriginCharge <> '0'
and so.SO_ID = '10906'