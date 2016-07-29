INSERT into Tmp_Group_Cust(sCust,sGroupCust,nLevel,AREA,TERR,RMDBL2 )
SELECT RM_CUST
                            ,(
                              CASE
                                WHEN LEVEL = 1 THEN RM_CUST
                                WHEN LEVEL = 2 THEN RM_PARENT
                                WHEN LEVEL = 3 THEN PRIOR RM_PARENT
                                ELSE NULL
                              END
                            ) AS CC
                            ,LEVEL,RM_AREA,RM_TERR,(Select DV_VALUE FROM TMP_DROP_LIST Where DV_INDEX = TO_NUMBER(RM_DBL_2)- 1) --(Select rm2.RM_DBL_2 From RM rm2 Where rm2.RM_CUST = RM_CUST) ))
                      FROM RM
                      WHERE RM_TYPE = 0
                      AND RM_ACTIVE = 1
                      AND RM_PARENT = 'COLONIALFS'
                      CONNECT BY PRIOR RM_CUST = RM_PARENT
                      START WITH Length(RM_PARENT) <= 1;
                      
INSERT into Tmp_Group_Cust(sCust,sGroupCust,nLevel,AREA,TERR,RMDBL2 )
                          SELECT RM_CUST
                            ,(
                              CASE
                                WHEN LEVEL = 1 THEN RM_CUST
                                WHEN LEVEL = 2 THEN RM_PARENT
                                WHEN LEVEL = 3 THEN PRIOR RM_PARENT
                                ELSE NULL
                              END
                            ) AS CC
                            ,LEVEL,RM_AREA,RM_TERR,(Select MAX(DV_VALUE) FROM TMP_DROP_LIST Where DV_INDEX = TO_NUMBER(RM_DBL_2) -1)
                      FROM RM
                      WHERE RM_TYPE = 0
                      AND RM_ACTIVE = 1
                      --AND Length(RM_GROUP_CUST) <=  1
                      CONNECT BY PRIOR RM_CUST = RM_PARENT
                      START WITH Length(RM_PARENT) <= 1                      
--TO_NUMBER(Select rm2.RM_DBL_2 From RM rm2 Where rm2.RM_CUST = 'BWFA')    




declare
  type final_coll_typ is table of varchar2(100);
  l_final_coll final_coll_typ;
begin
  l_final_coll := final_coll_typ();
  for indx in 1..32 loop

    <some processing logic here>

    
  end loop;

  dbms_output.put_line('Final size: ' || l_final_coll.count);
end;
/
