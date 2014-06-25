set echo off

rem *********************************************************************
rem * Copyright © Oracle-Consultant.co.uk 2001, all rights reserved     *
rem *                                                                   *
rem * Name      : seswait.sql                                           *
rem * Synopsis  : Shows waiting sessions and the events they await      *
rem * Source    : http://www.oracle-consultant.co.uk                    *
rem *                                                                   *
rem * Oracle-Consultant.co.uk are not responsible for any liability     *
rem * that may arise from the use of this code. Support can be obtained *
rem * by emailing script_support@oracle-consultant.co.uk                *
rem * Note: This script is best viewed in a fixed-width font.           *
rem *********************************************************************

set linesize  1000
set pagesize  32000
set trimspool on

column sid      format 999
column username format a15    wrapped
column spid     format a8
column event    format a25    wrapped
column osuser   format a15    wrapped
column machine  format a20    wrapped
column program  format a20    wrapped
column blocks   format 999999

select  sw.sid     sid
,       p.spid     spid
,       s.username username
,       s.osuser   osuser
,       sw.event   event
,       s.machine  machine
,       s.program  program
,       decode(sw.event,'db file sequential read', sw.p3,
                        'db file scattered read',  sw.p3,
                                             null) blocks
from    v$session_wait sw
,       v$session      s
,       v$process      p
where   s.paddr = p.addr
and     event     not in ('pipe get','client message')
and     sw.sid  = s.sid
/

column sid      clear
column username clear
column spid     clear
column event    clear
column osuser   clear
column machine  clear
column program  clear
column blocks   clear
set echo on