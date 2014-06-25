select substr(username, 1, 10) username, 
substr(default_tablespace, 1, 15) "def ts",
substr(temporary_tablespace, 1, 15) "temp ts", 
substr(profile, 1, 10) profile,
substr(account_status, 1, 10) "acc stat"
from dba_users
order by username
/
