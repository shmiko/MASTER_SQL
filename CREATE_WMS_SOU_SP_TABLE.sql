 DECLARE @PRINCIPALTABLE TABLE (
            C_ID int PRIMARY KEY IDENTITY,      
            principalID int,
            [guid] nvarchar(32),
            code nvarchar(255),
            name nvarchar(128),
            parent_groupID int,
            isUpdated int default(0) )