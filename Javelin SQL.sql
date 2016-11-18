
USE [bspga_csf]
GO
/****** Object:  StoredProcedure [dbo].[SOLine_Report]    Script Date: 11/16/2016 16:09:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:        <Author,,Name>
-- Create date: <Create Date,,>
-- Description:   <Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[SOLine_Report]
      @CustID varchar(50), @StartDate datetime, @EndDate datetime
AS
BEGIN
      -- SET NOCOUNT ON added to prevent extra result sets from
      -- interfering with SELECT statements.
      SET NOCOUNT ON;

      --#1 Get Parent Security Group record from Principal Table
      --DECLARE @CustID varchar(50), @StartDate datetime, @EndDate datetime
      --SET @StartDate = '2015-02-22 00:00:00'
      --SET @EndDate = '2015-03-25 23:59:59' 
      --SET @CustID = 'ISA-BEYONDBLUE'
      DECLARE @toBeUpdated int
      -- C_ID [int PRIMARY KEY IDENTITY] will increment by 1 for each new record ADDED. By default, the starting value for IDENTITY is 1
      DECLARE @PRINCIPALTABLE TABLE (
            C_ID int PRIMARY KEY IDENTITY,      
            principalID int,
            [guid] nvarchar(32),
            code nvarchar(255),
            name nvarchar(128),
            parent_groupID int,
            isUpdated int default(0) )
      /**** Insert records into @PRINCIPALTABLE where p.CLASS like '%GROUP%' ****/
      INSERT INTO @PRINCIPALTABLE (principalID, [guid], code, name, parent_groupID, isUpdated)
            SELECT p.PRINCIPALID, p.guid, p.CODE, p.NAME, p.PARENT_GROUPID, 0
            FROM  BSPGA_csf.dbo.PRINCIPAL p with (nolock)
            WHERE (p.CODE = @CustID and p.CLASS like '%GROUP%')
      /**** Display #1 results of @PRINCIPALTABLE ****/
      --SELECT * FROM @PRINCIPALTABLE

      --#2 Get Child Security Group records
      /**** Capture the number of records in @PRINCIPALTABLE WHERE isUpdated = 0 ****/
      /**** USE this result (@toBeUpdated) continue inserting CHILD records to @PRINCIPALTABLE ****/
      SELECT @toBeUpdated = COUNT(*) FROM @PRINCIPALTABLE WHERE isUpdated = 0
      WHILE @toBeUpdated > 0
      BEGIN
            -- Pick 1 record at a time
            UPDATE b SET b.isUpdated = 2
            FROM (SELECT top 1 PRINCIPALID FROM @PRINCIPALTABLE WHERE isUpdated = 0) child
            INNER JOIN @PRINCIPALTABLE b ON child.PRINCIPALID = b.PRINCIPALID
            
            --Find children where isUpdated = 2. Insert childs records into @PRINCIPALTABLE where p.CLASS like '%GROUP%' and p.PARENT_GROUPID = @PRINCIPALTABLE.principalID
            INSERT INTO @PRINCIPALTABLE (principalID, [guid], code, name, parent_groupID, isUpdated)
                  SELECT p.PRINCIPALID, p.guid, p.CODE, p.NAME, p.PARENT_GROUPID, 0
                  FROM BSPGA_csf.dbo.PRINCIPAL p with (nolock)
                  WHERE p.CLASS like '%GROUP%' and p.PARENT_GROUPID in (SELECT principalID FROM @PRINCIPALTABLE WHERE isUpdated = 2)
            
            --Where the record with isUpdated = 2 to isUpdated = 1 (this disables the Pick 1 record at a time above)
            UPDATE b SET b.isUpdated = 1
            FROM (SELECT top 1 PRINCIPALID FROM @PRINCIPALTABLE WHERE isUpdated = 2) child
            INNER JOIN @PRINCIPALTABLE b ON child.PRINCIPALID = b.PRINCIPALID
            SELECT @toBeUpdated = COUNT(*) FROM @PRINCIPALTABLE WHERE isUpdated = 0; -- continue ITERATION until @toBeUpdated =0
      END
      /**** Display #2 new results of @PRINCIPALTABLE ****/
      --SELECT * FROM @PRINCIPALTABLE

      -- ***** Find User PROFILE and PASSWORD - excluding BSPG Internal Users like [Admin. , SuperUser. & User.] ***** --
      Select p.NAME as 'SECURITY GROUP',
            rh.REQUISITIONNUMBER, COALESCE(rh.CUSTREF, '') as 'REF#', ROUND(rh.GROSSTOTAL, 2) AS 'GROSSTOTAL',
            --r5.requisitionnumber as 'PO Number', r5.externalorderID as 'Prism OrdNo', 
            c.NAME, c.ACCOUNTNO,
            usertable.CODE as 'USERNAME', usertable.NAME, 
            rh.SUBMITDATE, rh.DUEDATE,
            COALESCE(soh.ADDITIONALINFO2, '') as 'CONTACT', COALESCE(soh.ADDITIONALINFO4, '') as 'EMAIL',
            COALESCE(fs.CARRIER, '') as 'CARRIER', COALESCE(fs.TRACKINGNUMBER, '') as 'TRACKINGNUMBER',
            CASE rh.STATUSCODE
                  WHEN 'D' THEN 'Draft'
                  WHEN 'U' THEN 'Unprocessed'
                  WHEN 'T' THEN 'Template'
                  WHEN 'N' THEN 'New'
                  WHEN 'P' THEN 'Pending'
                  WHEN 'C' THEN 'Confirmed'
                  WHEN 'S' THEN 'Shipped'
                  WHEN 'R' THEN 'Received'
                  WHEN 'CL' THEN 'Closed'
                  WHEN 'X' THEN 'Cancelled'
                  WHEN 'RJ' THEN 'Rejected'
                  WHEN 'F' THEN 'Failed'
            END as 'ORDER STATUS',
            rh.CONTACTCOMPANYNAME, ra.LINE1 as 'ADDRESS LINE1', ra.LINE2 as 'ADDRESS LINE2', ra.CITY, ra.STATE, ra.POSTZIPCODE, ra.COUNTRYNAME
            --fs.EXTERNALFREIGHTSUMMARYID, ca.INTEGRATIONURI + fs.TRACKINGNUMBER
            --rl.LINENUMBER, rl.PRODUCTID, rl.PRODUCTCODECOPY, CAST(rl.QUANTITY as bigint) as 'QUANTITY', CAST(rl.SHIPPEDQUANTITY as bigint) as 'SHIPPEDQUANTITY', rl.STATUS
      from @PRINCIPALTABLE p
            -- Get Users
            inner join BSPGA_csf.dbo.principal usertable with (nolock) on (usertable.parent_groupID = p.principalID and usertable.class like '%USER%')
            -- Get Header Orders
            left join BSPGA_netorder.dbo.requisition_header rh with (nolock) on rh.userguid = usertable.guid
            left join BSPGA_netorder.dbo.CUSTOMER c with (nolock) ON c.CUSTOMERID = rh.CUSTOMERID
            -- Get ADDITIONALINFO2 & 3
            left join BSPGA_netorder.dbo.so_header_ext soh with (nolock) on rh.REQUISITIONID = soh.REQUISITIONID
            -- Get POD - FREIGHT INFO
            left join BSPGA_netorder.dbo.freightsummary fs with (nolock) on rh.REQUISITIONID = fs.REQUISITIONID
            --left join BSPGA_netorder.dbo.CARRIER ca with (nolock) on ca.CARRIERID = fs.CARRIERID
            -- Get Delivery Address 
            left join BSPGA_netorder.dbo.requisition_address ra with (nolock) on ra.requisitionaddressID = rh.deliveryaddressID
            /*
            -- Get Line Orders
            left join BSPGA_netorder.dbo.requisition_line rl with (nolock) on rh.REQUISITIONID = rl.REQUISITIONID
            left join BSPGA_netorder.dbo.requisition_line_link r4 with (nolock) on rl.requisitionlineID = r4.SRCLINEID
            left join BSPGA_netorder.dbo.requisition_header r5 with (nolock) on r5.requisitionID = r4.trgrequisitionID
            left join BSPGA_netorder.dbo.PRODUCT prod with (nolock) on prod.PRODUCTID = rl.PRODUCTID
            */
      WHERE 
            rh.REQUISITIONNUMBER like 'W%' and (not rh.STATUSCODE in ('D','U','T')) and (rh.submitdate >= @StartDate and rh.submitdate <= @EndDate)
      order by rh.SUBMITDATE
END

--EXEC SOLine_Report 'ISA-BEYONDBLUE', '2015-01-26 00:00:00', '2015-03-27 23:59:59'

