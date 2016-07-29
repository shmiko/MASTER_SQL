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
        , substr(To_Char(h.SH_ADD_DATE),0,10) AS Order_Date
        , To_Char(h.SH_ADD_DATE, 'DAY') AS Order_Day
        , To_Char(h.SH_ADD_DATE, 'D') AS DayNumber
        ,(CASE
          WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 6 THEN To_Char(h.SH_ADD_DATE + 3)    --Fri
          WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 7 THEN To_Char(h.SH_ADD_DATE + 2)    -- Sat
          WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 1 THEN To_Char(h.SH_ADD_DATE + 1)    --Sun
          ELSE substr(To_Char(h.SH_ADD_DATE),0,10) END) AS Adjusted_Order_AddDate
        , h.SH_ADD_TIME AS Add_Time
        ,(CASE
            WHEN h.SH_ADD_TIME < 120000 THEN 'EARLY_SAME_DAY_DESPATCH_BY_MIDNIGHT'
            ELSE 'LATE_NEXT_DAY_DESPATCH_BY_MIDDAY'
            END) AS Expectations
        , h.SH_ORDER  AS Order_Num
        , h.SH_CAMPAIGN AS Campaign
        , substr(To_Char(t.ST_PICK_PRINT_DATE),0,10)  AS Pick_Print_Date
        , t.ST_PICK_PRINT_TIME AS Pick_Print_Time
        , substr(To_Char(t.ST_DESP_DATE),0,10) AS Desp_Date
        , t.ST_DESP_TIME AS Desp_Time
        , (CASE
            /*Sunday*/
            WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 1 -- if order was added on a sunday
                --AND h.SH_ADD_TIME < :CutOffOrderAddTime   -- if order was in before daily cutoff
                AND substr(To_Char(t.ST_DESP_DATE),0,10) = SubStr(To_Char(h.SH_ADD_DATE + 2),0,10)   --because it's saturday if desp date less then next monday
                --AND t.ST_DESP_TIME <= :CutOffDespTimeSameDay  --if desp time was less than 12 middday  sameday
                THEN 'SUCCESS/E/2D/Sun'
            WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 1 -- if order was added on a sunday
                --AND h.SH_ADD_TIME < :CutOffOrderAddTime   -- if order was in before daily cutoff
                AND substr(To_Char(t.ST_DESP_DATE),0,10) > SubStr(To_Char(h.SH_ADD_DATE + 2),0,10)   --because it's saturday if desp date more then next monday
                --AND t.ST_DESP_TIME > :CutOffDespTimeSameDay  --if desp time was less than 12 midnight  sameday
                THEN 'FAIL/E/>2D/Sun'
            WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 1 -- if order was added on a saturday
                --AND h.SH_ADD_TIME > :CutOffOrderAddTime   -- if order was in after daily cutoff
                AND substr(To_Char(t.ST_DESP_DATE),0,10) < SubStr(To_Char(h.SH_ADD_DATE + 2),0,10)  --because it's saturday if desp date is next tuesday
                --AND t.ST_DESP_TIME <= :CutOffDespTimeSameDay  --If desp time was less that 12 midday
                THEN 'SUCCESS/L/<2D/Sun'
            WHEN
                substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 1
                AND to_date(t.ST_DESP_DATE,'dd-mon-yy')-to_date(h.SH_ADD_DATE,'dd-mon-yy') >= 3
                THEN 'FAIL/>3D/Sat'


           /* WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 7 -- if order was added on a saturday
                AND h.SH_ADD_TIME > :CutOffOrderAddTime   -- if order was in after daily cutoff
                AND substr(To_Char(t.ST_DESP_DATE),0,10) > SubStr(To_Char(h.SH_ADD_DATE + 3),0,10)  --because it's saturday if desp date is after next tuesday
                --AND t.ST_DESP_TIME > :CutOffDespTimeNextDay  --If desp time was less that 12pm next day
                THEN 'FAIL/L/Sat'  */


            /*Saturday*/
            WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 7  -- if order was added on a sat
                AND substr(To_Char(t.ST_DESP_DATE),0,10) = SubStr(To_Char(h.SH_ADD_DATE + 3),0,10) --If desp date was monday
                AND t.ST_DESP_TIME <= :CutOffDespTimeSameDay  --If desp time was less 12 midday
                THEN 'SUCCESS/E/ND/<12/Sat'
            WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 7  -- if order was added on a sat
                AND substr(To_Char(t.ST_DESP_DATE),0,10) = SubStr(To_Char(h.SH_ADD_DATE),0,10) --If desp date was same day
                --AND t.ST_DESP_TIME > :CutOffDespTimeSameDay  --If desp time was after 12 midday
                THEN 'SUCCESS/E/SD/Sat'
            WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 7  -- if order was added on a sat
                AND substr(To_Char(t.ST_DESP_DATE),0,10) >= SubStr(To_Char(h.SH_ADD_DATE + 4),0,10) --If desp date was after monday
                THEN 'FAIL/L/>ND/Sat'
            WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 7  -- if order was added on a sat
                 AND substr(To_Char(t.ST_DESP_DATE),0,10) > SubStr(To_Char(h.SH_ADD_DATE +5),0,10) --If desp date was 4 days or more
                THEN 'FAIL/>4D/Sat'
            WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 7  -- if order was added on a sunday
                --AND h.SH_ADD_TIME > :CutOffOrderAddTime   --if order was in after cutoff
                AND substr(To_Char(t.ST_DESP_DATE),0,10) <= SubStr(To_Char(h.SH_ADD_DATE + 3),0,10) --If desp date was tuesday
                THEN 'SUCCESS/L/<3D/Sun'
            WHEN
                substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 7
                AND to_date(t.ST_DESP_DATE,'dd-mon-yy')-to_date(h.SH_ADD_DATE,'dd-mon-yy') >= 2
                THEN 'FAIL/>D/Sun'


           /* WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 1  -- if order was added on a sunday
                AND h.SH_ADD_TIME > :CutOffOrderAddTime   --if order was in after cutoff
                AND substr(To_Char(t.ST_DESP_DATE),0,10) > SubStr(To_Char(h.SH_ADD_DATE + 2),0,10) --If desp date was after tuesday
                --AND t.ST_DESP_TIME > :CutOffDespTimeNextDay  --If desp time was less that 12pm next day
                THEN 'FAIL/L/Sun'   */


            /*M,T,W,T*/
            WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 2  -- if order was added on a Monday,Tuesday,Wednesday or Thursday
                OR substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 3
                OR substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 4
                OR substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 5
                AND h.SH_ADD_TIME < :CutOffOrderAddTime   --if order was in before cutoff
                AND substr(To_Char(t.ST_DESP_DATE),0,10) = SubStr(To_Char(h.SH_ADD_DATE),0,10) --If desp date was same day
                AND t.ST_DESP_TIME <= :CutOffDespTimeSameDay  --If desp time was less 12 midnight  sameday
                THEN 'SUCCESS/E/SD/<12/MTWT'
            WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 2  -- if order was added on a Monday,Tuesday,Wednesday or Thursday
                OR substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 3
                OR substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 4
                OR substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 5
                AND h.SH_ADD_TIME < :CutOffOrderAddTime   --if order was in before cutoff
                AND substr(To_Char(t.ST_DESP_DATE),0,10) = SubStr(To_Char(h.SH_ADD_DATE),0,10) --If desp date was after same day
                AND t.ST_DESP_TIME > :CutOffDespTimeSameDay  --If desp time was more than 12 midday
                THEN 'FAIL/E/>SD/MTWT'
            WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 2  -- if order was added on a Monday,Tuesday,Wednesday or Thursday
                OR substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 3
                OR substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 4
                OR substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 5
                AND h.SH_ADD_TIME < :CutOffOrderAddTime   --if order was in before cutoff
                AND substr(To_Char(t.ST_DESP_DATE),0,10) >= SubStr(To_Char(h.SH_ADD_DATE + 1),0,10) --If desp date was after same day
                --AND t.ST_DESP_TIME < :CutOffDespTimeSameDay  --If desp time was less 12 midday
                THEN 'FAIL/E/>SD/MTWT'
            WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 2  -- if order was added on a Monday,Tuesday,Wednesday or Thursday
                OR substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 3
                OR substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 4
                OR substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 5
                AND h.SH_ADD_TIME > :CutOffOrderAddTime   --if order was in after cutoff
                AND substr(To_Char(t.ST_DESP_DATE),0,10) = SubStr(To_Char(h.SH_ADD_DATE + 1),0,10) --If desp date next day
                AND t.ST_DESP_TIME <= :CutOffDespTimeSameDay  --If desp time was less that 12pm next day
                THEN 'SUCCESS/L/ND/<12/MTWT'
            WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 2  -- if order was added on a Monday,Tuesday,Wednesday or Thursday
                OR substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 3
                OR substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 4
                OR substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 5
                AND h.SH_ADD_TIME > :CutOffOrderAddTime   --if order was in after cutoff
                AND substr(To_Char(t.ST_DESP_DATE),0,10) = SubStr(To_Char(h.SH_ADD_DATE),0,10) --If desp date same day
                --AND t.ST_DESP_TIME <= :CutOffDespTimeSameDay  --If desp time was less that 12pm next day
                THEN 'SUCCESS/L/SD/MTWT'
            WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 2  -- if order was added on a Monday,Tuesday,Wednesday or Thursday
                OR substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 3
                OR substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 4
                OR substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 5
                AND h.SH_ADD_TIME > :CutOffOrderAddTime   --if order was in after cutoff
                AND substr(To_Char(t.ST_DESP_DATE),0,10) >= SubStr(To_Char(h.SH_ADD_DATE + 2),0,10) --If desp date after next day
                --AND t.ST_DESP_TIME > :CutOffDespTimeNextDay  --If desp time was less that 12pm next day
                THEN 'FAIL/L/>ND/MTWT'
            WHEN
                substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 2
                OR substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 3
                OR substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 4
                OR substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 5
                AND to_date(t.ST_DESP_DATE,'dd-mon-yy')-to_date(h.SH_ADD_DATE,'dd-mon-yy') >= 2
                THEN 'FAIL/>2D/MTWT'

            /*Friday*/
            WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 6  -- if order was added on a Friday
                AND h.SH_ADD_TIME < :CutOffOrderAddTime   --if order was in before cutoff
                AND substr(To_Char(t.ST_DESP_DATE),0,10) = SubStr(To_Char(h.SH_ADD_DATE),0,10) --If desp date was same day
                AND t.ST_DESP_TIME <= :CutOffDespTimeSameDay  --If desp time was less that 12 midnight sameday
                THEN 'SUCCESS/E/SD/<12/F'
            WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 6  -- if order was added on a Friday
                AND h.SH_ADD_TIME < :CutOffOrderAddTime   --if order was in before cutoff
                AND substr(To_Char(t.ST_DESP_DATE),0,10) <> SubStr(To_Char(h.SH_ADD_DATE),0,10) --If desp date was after same day
                --AND t.ST_DESP_TIME > :CutOffDespTimeSameDay  --If desp time was less that 12 midnight  sameday
                THEN 'FAIL/E/>SD/F'
            WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 6  -- if order was added on a Friday
                AND h.SH_ADD_TIME > :CutOffOrderAddTime   --if order was in after cutoff
                AND substr(To_Char(t.ST_DESP_DATE),0,10) <= SubStr(To_Char(h.SH_ADD_DATE + 4),0,10) --If desp date was Monday or earlier
                --AND substr(To_Char(t.ST_DESP_DATE),0,10) <> SubStr(To_Char(h.SH_ADD_DATE + 1),0,10) --If desp date was Monday or earlier AND not Sat
                --AND t.ST_DESP_TIME <= :CutOffDespTimeSameDay  --If desp time was less that 12 midday
                THEN 'SUCCESS/L/<3D/'
            WHEN substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 6  -- if order was added on a Friday
                AND h.SH_ADD_TIME > :CutOffOrderAddTime   --if order was in after cutoff
                AND substr(To_Char(t.ST_DESP_DATE),0,10) > SubStr(To_Char(h.SH_ADD_DATE + 4),0,10) --If desp date was After Monday
                --AND t.ST_DESP_TIME > :CutOffDespTimeNextDay  --If desp time was less that 12pm next day
                THEN 'FAIL/L/>3D/f'
             WHEN
                substr(To_Char(h.SH_ADD_DATE, 'D'),0,10) = 6
                AND to_date(t.ST_DESP_DATE,'dd-mon-yy')-to_date(h.SH_ADD_DATE,'dd-mon-yy') >= 4
                THEN 'FAIL/>4D/Fri'


            /*anyday*/
            WHEN
                --t.ST_DESP_DATE > h.SH_ADD_DATE + 4 --If desp date was 4 days or more
                to_date(t.ST_DESP_DATE,'dd-mon-yy')-to_date(h.SH_ADD_DATE,'dd-mon-yy') > 3
                --SubStr(NUMTODSINTERVAL(t.ST_DESP_DATE - h.SH_ADD_DATE, 'DAY'),1,2) >= 4 -- +4 00:00:00.00
                THEN 'FAIL/>4D'
            WHEN
                (((To_Number(LTrim(TO_CHAR(t.ST_DESP_DATE,'MM'))) - To_Number(LTrim(TO_CHAR(h.SH_ADD_DATE,'MM')))) <> 0)
                --OR (To_Number(LTrim(TO_CHAR(h.SH_ADD_DATE,'MM'))) - To_Number(LTrim(TO_CHAR(t.ST_DESP_DATE,'MM')))) >= -1)
                AND To_Number(LTrim(TO_CHAR(h.SH_ADD_DATE,'DD'))) >=28
                AND To_Number(LTrim(TO_CHAR(h.SH_ADD_DATE,'DD'))) <=31  )
                --h.SH_ADD_DATE > t.ST_DESP_DATE + 4 --If desp date was 4 days or more
                THEN 'FAIL/>4DO'
            ELSE 'FAIL' END) AS "Success/Fail"
            ,To_Number(LTrim(TO_CHAR(h.SH_ADD_DATE,'MM')))  AS MonthNum
            ,To_Number(LTrim(TO_CHAR(h.SH_ADD_DATE,'DD')))  AS OrderDayNum
            ,To_Number(LTrim(TO_CHAR(t.ST_DESP_DATE,'DD')))  AS DespDayNum
            ,(To_Number(LTrim(TO_CHAR(h.SH_ADD_DATE,'MM'))) - To_Number(LTrim(TO_CHAR(t.ST_DESP_DATE,'MM')))) AS MonthNumDiffs_minus_d
            ,(To_Number(LTrim(TO_CHAR(t.ST_DESP_DATE,'MM'))) - To_Number(LTrim(TO_CHAR(h.SH_ADD_DATE,'MM')))) AS MonthNumDiffd_minus_s
            ,(To_Number(LTrim(TO_CHAR(h.SH_ADD_DATE,'DD'))) - To_Number(LTrim(TO_CHAR(t.ST_DESP_DATE,'DD')))) AS DayNumDiffs_minus_d
            ,(To_Number(LTrim(TO_CHAR(t.ST_DESP_DATE,'DD'))) - To_Number(LTrim(TO_CHAR(h.SH_ADD_DATE,'DD')))) AS DayNumDiffd_minus_s
            ,NUMTODSINTERVAL(t.ST_DESP_DATE - h.SH_ADD_DATE, 'DAY') AS DaysDiffDespSinceOrd
            ,to_date(t.ST_DESP_DATE,'dd-mon-yy')-to_date(h.SH_ADD_DATE,'dd-mon-yy') AS DaysDiff

FROM  PWIN175.ST t LEFT JOIN SH h ON t.ST_ORDER = h.SH_ORDER
      LEFT JOIN Tmp_Group_Cust r ON r.sCust = h.SH_CUST
WHERE t.ST_DESP_DATE >= :start_date AND t.ST_DESP_DATE <= :end_date
AND t.ST_PSLIP IS NOT NULL
AND h.SH_STATUS <> 3
AND h.SH_CAMPAIGN NOT IN( 'ADMIN','OBSOLETE')
AND sGroupCust = 'TABCORP' --:cust










