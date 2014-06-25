maxpwdage = 90 'set this according to policy in your organization
warningDays = 10 ' set this according to policy in your organization
smtpserver="smtp.host.com"
sFrom="email"

Set conn= CreateObject("ADODB.Connection")
conn.Provider = "ADsDSOObject"
conn.Open "Active Directory Provider"

Set root = GetObject("LDAP://RootDSE")
adspath = root.Get("DefaultNamingContext")
ldap="<LDAP://" & adspath & ">;(&(objectCategory=User)(!userAccountControl:1.2.840.113556.1.4.803:=2));adspath;Subtree"
Set rs = conn.Execute( ldap)
WScript.Echo "Max Age Date:" & Now - maxpwdage
WScript.Echo "Warning Date:" & Now - warningDays 
Do Until rs.EOF
     path = rs.Fields("adspath").Value
     Set user=GetObject(path)
     WScript.Echo "Processing:" & adspath & ",CN=" & user.FullName
     On Error Resume Next
     dtVal = user.PasswordLastChanged
     If Not Err Then
         On Error GoTo 0
      	 WScript.Echo vbTab & "Password Last Changed:" & dtVal
         pwAge = DateDiff("d",dtVal,Now)
      	 WScript.Echo vbTab & " Password Age in Days:" & pwAge
         if (Not (pwAge > maxpwdage)) And (warningDays >= (maxpwdage - pwAge)) Then
              SendMail user,(maxpwdage - pwAge),sFrom,smtpserver
              wscript.Echo vbTab & vbTab & "Pw Expires for " & user.FullName & " in " & (maxpwdage - pwAge) & " days."
         End If
     Else
          WScript.Echo "Skipping:" & user.cn
     End If
     On Error GoTo 0
     rs.MoveNext ' Keep going down the table
Loop

Function SendMail( user, daysleft, sMailFrom, smtpserver )
     sTo = user.mail
     WScript.Echo vbTab & "Attempting to mail:" & user.Mail
     if sTO = ""  Then
          WScript.Echo vbTab & "No email address:" & user.cn
     Else
          WScript.Echo vbTab & "Mailing:" & user.cn
          With CreateObject("CDO.Message")
               .Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/sendusing") = 2
               .Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/smtpserver") = smtpserver
               .Configuration.Fields.Update
               .From = sMailFrom
               .To = user.mail
               .Subject = user.FullName & ", your Windows Password is expiring soon!!" 
               .HTMLBody = _
                    "Your Password Expires in " & daysLeft & " day(s)" & vbcrlf & _
                    "<h3>Windows users - Press CTRL-ALT-DEL and select the CHANGE A PASSWORD option</h3>" & vbcrlf & _
                    "<h3>Outlook Web Users - Please click (Options) and choose (Change your Password)</h3>" & vbcrlf & _
                    "<h3>This reminder will continue until you change your password</h3>" & vbcrlf & _
                    "<h3> Please do not reply to this email</h3>"
               .Send
           End With
     End If
End Function
