Select DV_VALUE FROM TMP_DROP_LIST Where DV_INDEX = (Select RM_DBL_2 From RM Where RM_CUST = 'BWFA') - 1;

 Procedure Find_Droplist_String(FDS_Droplist IN VARCHAR2, FDS_Integer IN NUMBER,p_array_size IN PLS_INTEGER DEFAULT 100)
        IS
        Pth_Size1	Number:=9;
        FDS_Count1 Number	 := 0;
        FDS_Pos1 Number	 := 0;
        FDS_Pos2 Number	 := 0;
        FDS_NumItems Number	 := 0;
        FDS_UserValue VARCHAR2(2000);
        FDS_TempString VARCHAR2(2000);
        FDS_Answer VARCHAR2(9);
        FDS_Char VARCHAR2(9);
        QueryTable VARCHAR2(600);
        nCheckpoint       NUMBER;
        v_query VARCHAR2(2000);
        TYPE ARRAY IS TABLE OF TMP_ALL_FEES_F%ROWTYPE;
        l_data ARRAY;
     BEGIN   
        FDS_Char  := ',';
       
        nCheckpoint := 1;
        
        QueryTable := q'{Select DV_USER_VALUE From DV Where DV_CODE = :FDS_Droplist }';
        EXECUTE IMMEDIATE QueryTable INTO FDS_UserValue USING FDS_Droplist;
        
        FOR FDS_Count1 IN 1..FDS_UserValue - 1 LOOP
          If SUBSTR(FDS_UserValue,FDS_Count1,1) = FDS_Char Then
            FDS_NumItems := FDS_NumItems + 1;
          END IF;
        END LOOP;
        
        nCheckpoint := 2;
        If (FDS_Integer + 1 <= FDS_NumItems) Then
          If (FDS_Integer > 0) Then
            FDS_TempString := FDS_UserValue;
            FOR FDS_Count1 IN 1..FDS_Integer LOOP
              FDS_Pos1 := FDS_Pos1 + INSTR(FDS_TempString,FDS_Char) + 1;
              FDS_TempString := SUBSTR(FDS_UserValue,FDS_Pos1,1);
              DBMS_OUTPUT.PUT_LINE(FDS_TempString || ' is FDS_TempString '  ); 
            END LOOP;
          Else
            FDS_Pos1 := 0;
          END IF;
          FDS_TempString := FDS_UserValue;
          FOR FDS_Count1 IN 1..FDS_Integer LOOP
            If INSTR(FDS_TempString,FDS_Char) = -1 Then
              FDS_Pos2 := FDS_Pos2 + (LENGTH(FDS_TempString) + 1);
            Else
              FDS_Pos2 := FDS_Pos2 + INSTR(FDS_TempString,FDS_Char) + 1;
              FDS_TempString := SUBSTR(FDS_UserValue,FDS_Pos2,1);
            END IF;
             DBMS_OUTPUT.PUT_LINE(FDS_TempString || ' is FDS_TempString '  ); 
          END LOOP;
          FDS_Pos2 := FDS_Pos2 - 1;
          FDS_Answer := SUBSTR(FDS_UserValue,FDS_Pos2 - FDS_Pos1,1);
          DBMS_OUTPUT.PUT_LINE(FDS_Answer || ' is FDS_Answer '  );         
        END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Find_Droplist_String failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
       WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Find_Droplist_String Failed at checkpoint ' || nCheckpoint ||
                            ' with error ' || SQLCODE || ' : ' || SQLERRM);
        RAISE;
    End Find_Droplist_String;
    
    
    Describe PACKAGE IQ_EOM_REPORTING