--SELECT DISTINCT(s1.machine),s1.username 
--FROM  v$session s1;


SET PAUSE ON
SET PAUSE 'Press Return to Continue'
SET PAGESIZE 200
SET LINESIZE 300

select p.spid "Thread", s.sid "SID-Top Sessions",
substr(s.osuser,1,15) "OS User", substr(s.program,1,25) "Program Running"
from v$process p, v$session s
where p.addr=s.paddr AND substr(s.program,1,25) = 'SQL Developer'
order by substr(s.osuser,1,15);
