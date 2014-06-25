iDaysOld = 2
strPath = "E:\SQLBackup"

Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objFolder = objFSO.GetFolder(strPath)
Set colSubfolders = objFolder.Subfolders
Set colFiles = objFolder.Files

For Each objFile in colFiles  
   If objFile.DateLastModified < (Date() - iDaysOld) Then
       MsgBox "Dir: " & objFolder.Name & vbCrLf & "File: " & objFile.Name
       'objFile.Delete
   End If
Next

For Each objSubfolder in colSubfolders
   Set colFiles = objSubfolder.Files
   For Each objFile in colFiles
       If objFile.DateLastModified < (Date() - iDaysOld) Then
           MsgBox "Dir: " & objSubfolder.Name & vbCrLf & "File: " & objFile.Name
           'objFile.Delete
       End If
   Next
Next
