/*Set Stored Procedure*/

CREATE OR REPLACE
      PROCEDURE EOM_STATS_SP_EXEC IS
                s_cmd  VARCHAR(20);
                s_sql  VARCHAR2(80);
                start_date VARCHAR(20);
                end_date  VARCHAR(20);
                nCheckpoint  NUMBER;
BEGIN

              nCheckpoint := 1;
              start_date := To_Date('1-Jan-2014');
              end_date  := To_Date('31-Jan-2014');
              s_sql := ' SELECT (CASE WHEN r.RM_PARENT = " " THEN h.SH_CUST ';
              s_sql := s_sql + ' WHEN r.RM_PARENT != " " THEN r.RM_PARENT';
              s_sql := s_sql + 'ELSE NULL END) AS Cust, ';
              s_sql := s_sql + '(CASE ';
              s_sql := s_sql + 'WHEN Upper(SubStr(d.SD_LOCN,0,1)) = "S" THEN "SYDNEY" ';
              s_sql := s_sql + 'WHEN Upper(SubStr(d.SD_LOCN,0,1)) = "H" THEN "SYDNEY" ';
              s_sql := s_sql + 'WHEN Upper(SubStr(d.SD_LOCN,0,1)) = "R" THEN "SYDNEY" ';
              s_sql := s_sql + 'WHEN Upper(SubStr(d.SD_LOCN,0,1)) = "M" THEN "MELBOURNE" ';
              s_sql := s_sql + 'WHEN Upper(SubStr(d.SD_LOCN,0,1)) = "O" THEN "OBSOLETE" ';
              s_sql := s_sql + 'ELSE m.IM_STD_VLOCN ';
              s_sql := s_sql + 'END) AS Warehouse, ';
              s_sql := s_sql + 'Count(*) AS Total, ';
              s_sql := s_sql + '"A- Orders" AS "Type" ';
              s_sql := s_sql + 'FROM SH h INNER JOIN RM r ON r.RM_CUST = h.SH_CUST ';
              s_sql := s_sql + 'INNER JOIN SD d ON d.SD_ORDER = h.SH_ORDER ';
              s_sql := s_sql + 'INNER JOIN IM m ON m.IM_STOCK = d.SD_STOCK ';
              s_sql := s_sql + 'WHERE h.SH_ADD_DATE >= :start_date AND h.SH_ADD_DATE <= :end_date ';
              s_sql := s_sql + 'AND d.SD_LINE = 1 ';
              s_sql := s_sql + 'AND h.SH_STATUS <> 3 ';
              s_sql := s_sql + 'AND h.SH_CAMPAIGN NOT LIKE "ADMIN" ';
              s_sql := s_sql + 'AND h.SH_CAMPAIGN NOT LIKE "OBSOLETE" ';
              s_sql := s_sql + 'GROUP BY ROLLUP ((CASE ';
              s_sql := s_sql + 'WHEN Upper(SubStr(d.SD_LOCN,0,1)) = "S" THEN "SYDNEY" ';
              s_sql := s_sql + 'WHEN Upper(SubStr(d.SD_LOCN,0,1)) = "H" THEN "SYDNEY" ';
              s_sql := s_sql + 'WHEN Upper(SubStr(d.SD_LOCN,0,1)) = "R" THEN "SYDNEY" ';
              s_sql := s_sql + 'WHEN Upper(SubStr(d.SD_LOCN,0,1)) = "M" THEN "MELBOURNE" ';
              s_sql := s_sql + 'WHEN Upper(SubStr(d.SD_LOCN,0,1)) = "O" THEN "OBSOLETE" ';
              s_sql := s_sql + 'ELSE m.IM_STD_VLOCN ';
              s_sql := s_sql + 'END),(CASE ';
              s_sql := s_sql + 'WHEN r.RM_PARENT = " " THEN h.SH_CUST ';
              s_sql := s_sql + 'WHEN r.RM_PARENT != " " THEN r.RM_PARENT ';
              s_sql := s_sql + 'ELSE NULL END)) ';
              s_sql := s_sql + 'ORDER BY 2,1 ';

  EXECUTE IMMEDIATE 	s_sql;




  RETURN;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('EOM_STATS failed at checkpoint ' || nCheckpoint ||
                         ' with error ' || SQLCODE || ' : ' || s_sql);
    RAISE;
END EOM_STATS_SP_EXEC;







