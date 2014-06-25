' SQL Server performance analysis script.

' This script looks at the threads spawned by the SQL Server process
' Each thread is profiled to determine if its CPU utilization is above the threshold.
' For each thread that falls into this category, the SQL SPID is obtained and output to the screen

' Run sp_who2 or use the SQL Activity Monitor to get the command for this SPID
' SQL Command output can be scripted, but it will be difficult to read in a command prompt
On Error Resume Next

Const iMaxCPUUtilization = 80
Const adOpenStatic = 3
Const adLockOptimistic = 3
Const forAppending = 8
Const forWriting = 2
Const forReading = 1

sFile="F:\Perf_logs\High_CPU_Sessions.txt"

' Get the WMI connection
Set objService = GetObject( _
    "Winmgmts:{impersonationlevel=impersonate}!\Root\Cimv2")
    
' Establish a SQL Connection.   Use integrated authentication to the localhost
Set objConnection = CreateObject("ADODB.Connection")
Set objRecordSet = CreateObject("ADODB.Recordset")

objConnection.Open _
    "Provider=SQLOLEDB;Data Source=localhost;" & _
        "Trusted_Connection=Yes;Initial Catalog=master;" & _
             "Integrated Security=SSPI;"

set objFSO = CreateObject("Scripting.FileSystemObject")

dim objTextWriter

if not objFSO.FileExists(sFile) Then
    set objFile = objFSO.CreateTextFile(sFile)
    'set objTextWriter =  objFSO.OpenTextFile(sFile, forAppending, True)
    'objTextWriter.WriteLine("Date, Name, IDProcess, IDThread, SQL SPID, SQL Status, SQL CMD, SQL DB, PercentProcessorTime")
    objFile.WriteLine("Date, Name, IDProcess, IDThread, SQL SPID, SQL Status, SQL CMD, SQL DB, PercentProcessorTime")
    objFile.Close
    set objFile = nothing
end if


set objTextWriter = objFSO.OpenTextFile(sFile, forAppending, True)

strComputer = "."
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")
Set colItems = objWMIService.ExecQuery("Select * from Win32_PerfFormattedData_PerfProc_Thread",,48)
Wscript.Echo "Date, Name, IDProcess, IDThread, SQL SPID, SQL Status, SQL CMD, SQL DB, PercentProcessorTime"
For Each objItem in colItems
    if (objItem.PercentProcessorTime > 60) And (InStr(1, objItem.Name, "sqlservr", 1)) Then
    
        'wscript.echo "running sql query for KPID ", objItem.IDThread
        objRecordSet.Open "select p.spid, p.kpid, p.status, p.hostname, p.dbid, p.cmd, d.name " & _
              "from master..sysprocesses p inner join master..sysdatabases d " & _
                "on p.dbid = d.dbid " & _
                  "where kpid = " & objItem.IDThread & _
                    "order by kpid", _
              objConnection, adOpenStatic, adLockOptimistic
        
        objRecordset.MoveFirst    
        
        WScript.Echo Now(), ",", objItem.Name, ",", objItem.IDProcess, ",", objItem.IDThread, ",", objRecordSet("spid"), ",", _
                     objRecordSet("status"), ",", objRecordSet("cmd"), ",", objRecordSet("name"), ",", objItem.PercentProcessorTime
        
        objTextWriter.WriteLine(Now() & "," & objItem.Name & "," & objItem.IDProcess & "," & objItem.IDThread & "," & objRecordSet("spid") & "," & _
                     objRecordSet("status") & "," & objRecordSet("cmd") & "," & objRecordSet("name") & "," & objItem.PercentProcessorTime)
        objRecordSet.Close
      
    End If

Next

'clean it up
ObjConnection.Close
objTextWriter.Close

set objTextWriter = nothing
set objFile = nothing
set objFSO = nothing
set objWMIService = nothing
set colItems = nothing
set objRecordSet = nothing
set objRecordSet = nothing

