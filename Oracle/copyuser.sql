SET ECHO off
rem  COPY_USER - copy one user and correct system,role privs and quota's
rem   
rem # Variables:
rem #
rem # owner = user to Copy
rem # new_user = user to create
rem # new_password = new user's password
rem # script_destination = directory where to create the user generation script
rem #
rem #
prompt # Variables:
prompt #
prompt # owner = user to Copy
prompt # new_user = user to create
prompt # new_password = new user's password
prompt # script_destination = directory where to create the user generation script
prompt # 

set heading off feed off verify off wrap ON

rem Create user and set default tablespace and storage

select distinct 'create user &&new_user identified by &&new_password ' ||
	'default tablespace ' || default_tablespace || '
  	temporary tablespace TEMP ;'
from sys.DBA_USERS
where username like upper('&&owner%')
/
spool &&script_destination\&&owner..sql   
/

rem Copy system privileges

select 'grant ' || PRIVILEGE || ' to &&new_user ' || 
	decode(ADMIN_OPTION, 'YES', 'with admin option ;',';')
from sys.DBA_SYS_PRIVS
where grantee like upper('&&owner%')
/

rem Copy role grants

select 'grant '|| GRANTED_ROLE ||' to &&new_user ' ||
	decode(ADMIN_OPTION, 'YES', 'with admin option ;',';')
from sys.DBA_ROLE_PRIVS
where grantee like upper('&&owner%')
/

rem Copy individual table access grants

select 'grant '|| PRIVILEGE ||' on '|| OWNER || '.' || 
	TABLE_NAME || ' to &&new_user ;'
from sys.dba_tab_privs
where grantee like upper('&&owner%')
/

rem set quotas

select distinct 'alter user &&new_user quota '|| BYTES ||' on '|| TABLESPACE_NAME ||';'
from sys.DBA_TS_QUOTAS
where username like upper('&&owner%')
and bytes    > 0
/
spool off
prompt Created script is &&script_destination\&&new_user..sql   
set heading ON feed ON
undefine owner
undefine script_destination
undefine new_user
undefine new_password
