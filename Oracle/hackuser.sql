rem *********************************************************************
rem * Copyright © Oracle-Consultant.co.uk 2001, all rights reserved     *
rem *                                                                   *
rem * Name     : hackuser.sql                                           *
rem * Synopsis : Script to hack into an account that you don't know     *
rem *            password for.                                          *
rem *            Note that you must have "alter user" privilege to      *
rem *            run this.                                              *
rem * Source   : http://www.oracle-consultant.co.uk                     *
rem *                                                                   *
rem * Oracle-Consultant.co.uk are not responsible for any liability     *
rem * that may arise from the use of this code. Support can be obtained *
rem * by emailing script_support@oracle-consultant.co.uk                *
rem * Note: This script is best viewed in a fixed-width font.           *
rem *********************************************************************

rem 
rem Alters given user's password to "WELCOME", and creates script to revert password to
rem original setting
rem 
 
set heading  off 
set verify   off 
set feedback off 
 
prompt 
accept username char prompt 'Enter username to hack into: '
 
prompt  
prompt Creating revert.sql in the current working directory
prompt 

set termout off 
spool       revert.sql 

select 'alter user &&username identified by values '||
       ''''||
       password||
       ''''||
       ';' 
from   sys.dba_users
where  username = upper('&&username')
/

spool       off 
set termout on 
 
prompt  
prompt Altering user password to 'welcome'
prompt 

set termout off 
 
alter user    &&username
identified by welcome
/
 
set termout on 
prompt 
prompt ************************************************* 
prompt   The file revert.sql is in the current working   
prompt   directory.  Run it to reset the password.   
prompt ************************************************* 
prompt 
prompt
