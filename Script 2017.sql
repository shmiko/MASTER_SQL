SELECT RM_CUST FROM RM WHERE RM_ANAL = '22NSWP'



select
   object_name,
   object_type,
   last_ddl_time
from
   dba_objects
where object_type = 'TABLE'
and
  object_name Like '%Dev%';