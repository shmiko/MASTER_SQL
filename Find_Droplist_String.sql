  CREATE OR REPLACE Procedure Find_Droplist_String
      (
      FDS_Droplist DV.DV_CODE%TYPE
      ,FDS_Integer Number
      )
    AS
    FDS_Count1 NUMBER := 0;
    FDS_NumItems NUMBER := 0;
    FDS_TempString VARCHAR2(108) := NULL;
    FDS_Answer VARCHAR2(8) := NULL;
    FDS_Pos1 NUMBER := 0;
    FDS_Pos2 NUMBER := 0;
    
    CURSOR FDS_cur IS
      SELECT DV.DV_USER_VALUE
      FROM DV
      WHERE DV.DV_CODE = FDS_Droplist;
      
      
     FDS_rec FDS_cur%ROWTYPE; 
    BEGIN
      OPEN FDS_cur;
      FETCH FDS_cur INTO FDS_rec;
      WHILE FDS_Count1 < (StrLen.FDS_rec - 1) LOOP
       /* --If (SubStr(FDS_rec,FDS_Count1, 1) = ",") Then*/
          FDS_NumItems := FDS_NumItems + 1;
        /*--END IF;*/
       END LOOP;
       
      If (FDS_Integer + 1 <= FDS_NumItems) Then 
        If (FDS_Integer > 0) Then
          FDS_TempString := FDS_UserValue;
          WHILE FDS_Count1 < FDS_Integer LOOP
            FDS_Pos1 := FDS_Pos1 + INSTR(FDS_TempString,',') + 1;
            FDS_TempString := SubStr(FDS_UserValue,FDS_Pos1, 1000);
          END LOOP;
        ELSE 
          FDS_Pos1 := 0;
        END IF;
      END IF;
      FDS_TempString := FDS_UserValue;
      WHILE FDS_Count1 < (FDS_Integer + 1) LOOP
        If (INSTR(FDS_TempString,',') = -1) Then
          FDS_Pos2 := FDS_Pos2 + StrLen.FDS_TempString + 1;
        ELSE
          FDS_Pos2 := FDS_Pos2 + INSTR(FDS_TempString,',') + 1;
          FDS_TempString := SubStr(FDS_UserValue,FDS_Pos2, 1000);
        END IF;
      END LOOP;
      
      FDS_Pos2 := FDS_Pos2 - 1;
      FDS_Answer := FDS_UserValue.SubString( FDS_Pos1, FDS_Pos2 - FDS_Pos1 );
      
      --WHILE (FDS_cur%FOUND)
      --  LOOP
        DBMS_OUTPUT.PUT_LINE('The droplist Value is ' || FDS_rec.DV_USER_VALUE || 'and or ' || FDS_Answer );  
      --FETCH FDS_cur INTO FDS_rec;
    --END LOOP;
    CLOSE FDS_cur;
  END Find_Droplist_String;
  
--EXECUTE Find_Droplist_String('22','1-Jun-2014','17-Jun-2014');
  
  