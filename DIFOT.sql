/*decalre variables These are being declared via the stored procedure - just need to redeclare cust so as we can get the rates*/
var cust varchar2(20)
exec :cust := 'TABCORP'
var ordernum varchar2(20)
exec :ordernum := '1363806'
var stock varchar2(20)
exec :stock := 'COURIER'
var source varchar2(20)
exec :source := 'BSPRINTNSW'
var sAnalysis varchar2(20) /*VerbalOrderEntryFee*/
exec SELECT  RM_ANAL INTO :sAnalysis FROM RM where RM_CUST = :cust;
var anal varchar2(20)
exec :anal := '21VICP'
var start_date varchar2(20)
exec :start_date := To_Date('01-Jan-2014')
var end_date varchar2(20)
exec :end_date := To_Date('28-Feb-2014')
var AdjustedDespDate varchar2(20)
--exec :AdjustedDespDate := To_Date('28-Feb-2014')
var cust2 varchar2(20)
exec :cust2 := 'BEYONDBLUE'
var warehouse varchar2(20)
exec :warehouse := 'SYDNEY'
var warehouse2 varchar2(20)
exec :warehouse2 := 'MELBOURNE'
var month_date varchar2(20)
exec :month_date := substr(:end_date,4,3)
var year_date varchar2(20)
exec :year_date := substr(:end_date,8,2)
var CutOffOrderAddTime number
exec :CutOffOrderAddTime := ('120000')
var CutOffDespTimeSameDay number
exec :CutOffDespTimeSameDay := ('235959')
var CutOffDespTimeNextDay number
exec :CutOffDespTimeNextDay := ('120000')
var AdjustedDespDate varchar2(20)
--exec :AdjustedDespDate





/*Total Despatches by Month all custs grouped by warehouse/grouped cust */  --  1.5s  Total Count 15381

SELECT   r.sCust
        ,r.sGroupCust
        , substr(To_Char(h.SH_ADD_DATE),0,10) AS OrderDate
        , To_Char(h.SH_ADD_DATE, 'DAY') AS OrderDay
        , To_Char(h.SH_ADD_DATE, 'D') AS DayNumber
        ,(CASE
          WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 6 THEN To_Char(h.SH_ADD_DATE + 3)    --Fri
          WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 7 THEN To_Char(h.SH_ADD_DATE + 2)    -- Sat
          WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 1 THEN To_Char(h.SH_ADD_DATE + 1)    --Sun
          ELSE substr(To_Char(h.SH_ADD_DATE),0,10) END) AS Adjusted_Order_AddDate
        , h.SH_ADD_TIME
        , h.SH_ORDER
        , h.SH_CAMPAIGN
        , substr(To_Char(t.ST_PICK_PRINT_DATE),0,10)  AS Pick_Print_Date
        , t.ST_PICK_PRINT_TIME
        , substr(To_Char(t.ST_DESP_DATE),0,10) AS DespDate
        , t.ST_DESP_TIME
        , (CASE
            /*Sunday*/
            WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 7 -- if order was added on a saturday
                AND h.SH_ADD_TIME < :CutOffOrderAddTime   -- if order was in before daily cutoff
                AND substr(To_Char(t.ST_DESP_DATE),0,10) <= SubStr(To_Char(h.SH_ADD_DATE + 2),0,10)   --because it's saturday if desp date less then next monday
                AND t.ST_DESP_TIME <= :CutOffDespTimeSameDay  --if desp time
                THEN 'SUCCESSE7'
            WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 7 -- if order was added on a saturday
                AND h.SH_ADD_TIME > :CutOffOrderAddTime   -- if order was in after daily cutoff
                AND substr(To_Char(t.ST_DESP_DATE),0,10) <= SubStr(To_Char(h.SH_ADD_DATE + 2),0,10)
                AND t.ST_DESP_TIME <= :CutOffDespTimeNextDay  --if desp time
                THEN 'SUCCESSL7'

            /*Saturday*/
            WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 1  -- if order was added on a sunday
                AND h.SH_ADD_TIME < :CutOffOrderAddTime   --if order was in after cutoff
                AND substr(To_Char(t.ST_DESP_DATE),0,10) <= SubStr(To_Char(h.SH_ADD_DATE + 1),0,10) --If desp date was late same day or early next day
                AND t.ST_DESP_TIME <= :CutOffDespTimeSameDay  --If desp time was less that 12pm next day
                THEN 'SUCCESSE1'
            WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 1  -- if order was added on a sunday
                AND h.SH_ADD_TIME > :CutOffOrderAddTime   --if order was in after cutoff
                AND substr(To_Char(t.ST_DESP_DATE),0,10) <= SubStr(To_Char(h.SH_ADD_DATE + 1),0,10) --If desp date was late same day or early next day
                AND t.ST_DESP_TIME <= :CutOffDespTimeNextDay  --If desp time was less that 12pm next day
                THEN 'SUCCESSL1'

            /*Monday*/
            WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 2  -- if order was added on a Monday
                AND h.SH_ADD_TIME < :CutOffOrderAddTime   --if order was in after cutoff
                AND substr(To_Char(t.ST_DESP_DATE),0,10) <= SubStr(To_Char(h.SH_ADD_DATE),0,10) --If desp date was late same day or early next day
                AND t.ST_DESP_TIME <= :CutOffDespTimeSameDay  --If desp time was less that 12pm next day
                THEN 'SUCCESSE2'
            WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 2  -- if order was added on a Monday,Tuesday,Wednesday,Thursday
                AND h.SH_ADD_TIME > :CutOffOrderAddTime   --if order was in after cutoff
                AND substr(To_Char(t.ST_DESP_DATE),0,10) <= SubStr(To_Char(h.SH_ADD_DATE),0,10) --If desp date was late same day or early next day
                AND t.ST_DESP_TIME <= :CutOffDespTimeNextDay  --If desp time was less that 12pm next day
                THEN 'SUCCESSL2'

            /*Tuesday*/
            WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 3  -- if order was added on a Tuesday
                AND h.SH_ADD_TIME < :CutOffOrderAddTime   --if order was in after cutoff
                AND substr(To_Char(t.ST_DESP_DATE),0,10) <= SubStr(To_Char(h.SH_ADD_DATE),0,10) --If desp date was late same day or early next day
                AND t.ST_DESP_TIME <= :CutOffDespTimeSameDay  --If desp time was less that 12pm next day
                THEN 'SUCCESSE3'
            WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 3  -- if order was added on a Tuesday
                AND h.SH_ADD_TIME > :CutOffOrderAddTime   --if order was in after cutoff
                AND substr(To_Char(t.ST_DESP_DATE),0,10) <= SubStr(To_Char(h.SH_ADD_DATE),0,10) --If desp date was late same day or early next day
                AND t.ST_DESP_TIME <= :CutOffDespTimeNextDay  --If desp time was less that 12pm next day
                THEN 'SUCCESSL3'

            /*Wednesday*/
            WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 4  -- if order was added on a Wednesday
                AND h.SH_ADD_TIME < :CutOffOrderAddTime   --if order was in after cutoff
                AND substr(To_Char(t.ST_DESP_DATE),0,10) <= SubStr(To_Char(h.SH_ADD_DATE),0,10) --If desp date was late same day or early next day
                AND t.ST_DESP_TIME <= :CutOffDespTimeSameDay  --If desp time was less that 12pm next day
                THEN 'SUCCESSE4'
            WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 4  -- if order was added on a Wednesday
                AND h.SH_ADD_TIME > :CutOffOrderAddTime   --if order was in after cutoff
                AND substr(To_Char(t.ST_DESP_DATE),0,10) <= SubStr(To_Char(h.SH_ADD_DATE),0,10) --If desp date was late same day or early next day
                AND t.ST_DESP_TIME <= :CutOffDespTimeNextDay  --If desp time was less that 12pm next day
                THEN 'SUCCESSL4'

            /*Thursday*/
            WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 5  -- if order was added on a Thursday
                AND h.SH_ADD_TIME < :CutOffOrderAddTime   --if order was in after cutoff
                AND substr(To_Char(t.ST_DESP_DATE),0,10) <= SubStr(To_Char(h.SH_ADD_DATE),0,10) --If desp date was late same day or early next day
                AND t.ST_DESP_TIME <= :CutOffDespTimeSameDay  --If desp time was less that 12pm next day
                THEN 'SUCCESSE5'
            WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 5  -- if order was added on a Thursday
                AND h.SH_ADD_TIME > :CutOffOrderAddTime   --if order was in after cutoff
                AND substr(To_Char(t.ST_DESP_DATE),0,10) <= SubStr(To_Char(h.SH_ADD_DATE),0,10) --If desp date was late same day or early next day
                AND t.ST_DESP_TIME <= :CutOffDespTimeNextDay  --If desp time was less that 12pm next day
                THEN 'SUCCESSL5'

            /*Friday*/
            WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 6  -- if order was added on a Friday
                AND h.SH_ADD_TIME < :CutOffOrderAddTime   --if order was in after cutoff
                AND substr(To_Char(t.ST_DESP_DATE),0,10) <= SubStr(To_Char(h.SH_ADD_DATE + 3),0,10) --If desp date was late same day or early next day
                AND t.ST_DESP_TIME <= :CutOffDespTimeSameDay  --If desp time was less that 12pm next day
                THEN 'SUCCESSE6'
            WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 6  -- if order was added on a Friday
                AND h.SH_ADD_TIME > :CutOffOrderAddTime   --if order was in after cutoff
                AND substr(To_Char(t.ST_DESP_DATE),0,10) <= SubStr(To_Char(h.SH_ADD_DATE + 3),0,10) --If desp date was late same day or early next day
                AND t.ST_DESP_TIME <= :CutOffDespTimeNextDay  --If desp time was less that 12pm next day
                THEN 'SUCCESSL6'

            ELSE 'FAIL' END) AS "Success/Fail"
FROM  PWIN175.ST t LEFT JOIN SH h ON t.ST_ORDER = h.SH_ORDER
      LEFT JOIN Tmp_Group_Cust r ON r.sCust = h.SH_CUST
WHERE t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
AND t.ST_PSLIP IS NOT NULL
AND h.SH_STATUS <> 3
AND h.SH_CAMPAIGN NOT IN( 'ADMIN','OBSOLETE')
AND sGroupCust = :cust



