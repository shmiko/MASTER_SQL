var cust varchar2(20)
exec :cust := 'TABCORP'
var cust2 varchar2(20)
exec :cust2 := 'TABCORP'
var ordernum varchar2(20)
exec :ordernum := '1363806'
var stock varchar2(20)
exec :stock := 'COURIER'
var source varchar2(20)
exec :source := 'BSPRINTNSW'
var anal varchar2(20)
exec :anal := '21VICP'
var start_date varchar2(20)
exec :start_date := To_Date('01-Dec-2013')
var end_date varchar2(20)
exec :end_date := To_Date('31-Mar-2014')
var warehouse varchar2(20)
exec :warehouse := 'SYDNEY'
var warehouse2 varchar2(20)
exec :warehouse2 := 'MELBOURNE'
var month_date varchar2(20)
exec :month_date := substr(:end_date,4,3)
var year_date varchar2(20)
exec :year_date := substr(:end_date,8,2)



--All Lines by Month all custs by warehouse/top level grouped cust   --  11s   total count 62068
--Jason will use this in addition to the grouped data as he need the splits for TABCORP - set cust2 var as TABCORP first




SELECT DISTINCT IL_IN_LOCN, SD_STOCK,To_Number(SL_PICK),SL_ORDER
    FROM SL s1 INNER JOIN SD ON  SD_LINE = s1.SL_ORDER_LINE AND SD_ORDER = s1.SL_ORDER
    LEFT JOIN Tmp_Group_Cust r ON r.sCust = SD_CUST
    INNER JOIN IL ON IL_LOCN = s1.SL_LOCN
WHERE s1.SL_EDIT_DATE >= :start_date AND s1.SL_EDIT_DATE <= :end_date
AND   s1.SL_PSLIP IS NOT NULL
AND ((SELECT SH_CAMPAIGN FROM SH WHERE SH_ORDER = SD_ORDER) NOT IN( 'ADMIN','OBSOLETE'))
AND sGroupCust = :cust2
--AND SD_ORDER = '   1459419'
GROUP BY IL_IN_LOCN, SD_STOCK , To_Number(SL_PICK),SL_ORDER




