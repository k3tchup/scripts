set echo off
conn &1 &2 &3
set termout off
set pages 90 lines 120
define db_name="NOT CONNECTED"
column db_name new_value db_name noprint 
define usr=" "
column usr new_value usr noprint
select name "db_name" from v$database ; 
select user "usr" from dual;
set termout on
set sqlprompt "&usr@&db_name> " 
set echo on
