SET ECHO off 
REM NAME:TFSTSFRM.SQL 
REM USAGE:"@path/tfstsfgm" 
REM ------------------------------------------------------------------------ 
REM REQUIREMENTS: 
REM    SELECT ON DBA_FREE_SPACE 
REM ------------------------------------------------------------------------ 
REM PURPOSE: 
REM    The following is a script that will determine how many extents 
REM    of contiguous free space you have in Oracle as well as the  
REM total amount of free space you have in each tablespace. From  
REM    these results you can detect how fragmented your tablespace is.  
REM   
REM    The ideal situation is to have one large free extent in your  
REM    tablespace. The more extents of free space there are in the  
REM    tablespace, the more likely you  will run into fragmentation  
REM    problems. The size of the free extents is also  very important.  
REM    If you have a lot of small extents (too small for any next   
REM    extent size) but the total bytes of free space is large, then  
REM    you may want to consider defragmentation options.  
REM ------------------------------------------------------------------------ 
REM DISCLAIMER: 
REM    This script is provided for educational purposes only. It is NOT  
REM    supported by Oracle World Wide Technical Support. 
REM    The script has been tested and appears to work as intended. 
REM    You should always run new scripts on a test instance initially. 
REM ------------------------------------------------------------------------ 
REM Main text of script follows: 
 
create table SPACE_TEMP (   
 TABLESPACE_NAME        CHAR(30),   
 CONTIGUOUS_BYTES       NUMBER)   
/   
   
declare   
  cursor query is select *   
          from dba_free_space   
                  order by tablespace_name, block_id;   
  this_row        query%rowtype;   
  previous_row    query%rowtype;   
total           number;   
   
begin   
  open query;   
  fetch query into this_row;   
  previous_row := this_row;   
  total := previous_row.bytes;   
  loop   
 fetch query into this_row;   
     exit when query%notfound;   
     if this_row.block_id = previous_row.block_id + previous_row.blocks then   
        total := total + this_row.bytes;   
        insert into SPACE_TEMP (tablespace_name)   
                  values (previous_row.tablespace_name);   
     else   
        insert into SPACE_TEMP values (previous_row.tablespace_name,   
               total);   
        total := this_row.bytes;   
     end if;   
previous_row := this_row;   
  end loop;   
  insert into SPACE_TEMP values (previous_row.tablespace_name,   
                           total);   
end;   
.   
/   
   
set pagesize 60   
set newpage 0   
set echo off   
ttitle center 'Contiguous Extents Report'  skip 3   
break on "TABLESPACE NAME" skip page duplicate   
spool contig_free_space.lis   
rem   
column "CONTIGUOUS BYTES"       format 999,999,999   
column "COUNT"                  format 999   
column "TOTAL BYTES"            format 999,999,999   
column "TODAY"   noprint new_value new_today format a1   
rem   
select TABLESPACE_NAME  "TABLESPACE NAME",   
       CONTIGUOUS_BYTES "CONTIGUOUS BYTES"   
from SPACE_TEMP   
where CONTIGUOUS_BYTES is not null   
order by TABLESPACE_NAME, CONTIGUOUS_BYTES desc;   
   
select tablespace_name, count(*) "# OF EXTENTS",   
         sum(contiguous_bytes) "TOTAL BYTES"    
from space_temp   
group by tablespace_name;   
   
spool off   
   
drop table SPACE_TEMP   
/   
