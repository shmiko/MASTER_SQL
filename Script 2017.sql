SELECT RM_CUST FROM RM WHERE RM_ANAL = '22NSWP'
SELECT RM_CUST FROM RM WHERE RM_ANAL = '22NSWP14'
SELECT RM_CUST FROM RM WHERE RM_ANAL = '21VICP'
SELECT RM_CUST FROM RM WHERE RM_ANAL = '21VICF'
select
   object_name,
   object_type,
   last_ddl_time
from
   dba_objects
where object_type = 'TABLE'
and
  object_name Like '%Dev%';
  
 