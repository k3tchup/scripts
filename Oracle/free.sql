rem *********************************************************************
rem * Copyright © Oracle-Consultant.co.uk 2001, all rights reserved     *
rem *                                                                   *
rem * Name     : free.sql                                               *
rem * Synopsis : Shows the fill rates of tablespaces and datafiles      *
rem * Source   : http://www.oracle-consultant.co.uk                     *
rem *                                                                   *
rem * Oracle-Consultant.co.uk are not responsible for any liability     *
rem * that may arise from the use of this code. Support can be obtained *
rem * by emailing script_support@oracle-consultant.co.uk                *
rem * Note: This script is best viewed in a fixed-width font.           *
rem *********************************************************************

break on report
compute sum of tbs_size_mb on report
compute sum of used        on report
compute sum of avail       on report

column tsname       format a20         heading 'Tablespace Name'
column tbs_size_mb  format 999,999     heading 'Size|(MB)'
column used         format 999,999     heading 'Used|(MB)'
column avail        format 999,999     heading 'Free|(MB)'
column used_visual  format a11         heading 'Used'
column pct_used     format 999         heading '% Used'
column flname       format a50         heading 'Filename'
column siz          format 999,999,990 heading 'File Size|(MB)'
column maxsiz       format 999,999,990 heading 'Max Size|(MB)'
column pctmax       format 990         heading 'Pct|Max'

set linesize  1000
set trimspool on
set pagesize  32000
set verify    off
set feedback  off

PROMPT
PROMPT *************************
PROMPT *** TABLESPACE STATUS ***
PROMPT *************************

SELECT   df.tablespace_name                           tsname
,        sum(df.bytes)/1024/1024                      tbs_size_mb
,        nvl(sum(e.used_bytes)/1024/1024,0)           used
,        nvl(sum(f.free_bytes)/1024/1024,0)           avail
,        rpad(' '||rpad('X',round(sum(e.used_bytes)
         *10/sum(df.bytes),0), 'X'),11,'-')           used_visual
,        nvl((sum(e.used_bytes)*100)/sum(df.bytes),0) pct_used
FROM     sys.dba_data_files df
,        (SELECT   file_id
          ,        sum(nvl(bytes,0)) used_bytes
          FROM     sys.dba_extents
          GROUP BY file_id) e
,        (SELECT   max(bytes) free_bytes
          ,        file_id
          FROM     dba_free_space
          GROUP BY file_id) f
WHERE    e.file_id(+) = df.file_id
AND      df.file_id   = f.file_id(+)
GROUP BY df.tablespace_name
ORDER BY 6
/

clear breaks

PROMPT
PROMPT ***********************
PROMPT *** DATAFILE STATUS ***
PROMPT ***********************

select file_name                                          flname
,      tablespace_name                                    tsname
,      bytes/1024/1024                                    siz
,      decode(maxbytes,0,0,maxbytes/1024/1024)            maxsiz
,      decode(maxbytes,0,0,bytes/maxbytes*100)            pctmax
from   dba_data_files
/

column tsname      clear
column tbs_size_mb clear
column used        clear
column avail       clear
column used_visual clear
column pct_used    clear
column flname      clear
column siz         clear
column maxsiz      clear
column pctmax      clear
