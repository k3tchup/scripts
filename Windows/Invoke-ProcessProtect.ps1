# process security

Param (
    [Parameter(Mandatory=$true)][UInt32]$processId
)

# To invoke API functionality from PowerShell, you could use Add-Type.  however, this makes the built-in c# compiler
# compile stuff to disk.  this is inefficient and not very sexy

# Function written by Matt Graeber, Twitter: @mattifestation, Blog: http://www.exploit-monday.com/
# http://www.exploit-monday.com/2012/05/accessing-native-windows-api-in.html
Function Get-DelegateType
{
    Param
    (
        [OutputType([Type])]
        
        [Parameter( Position = 0)]
        [Type[]]
        $Parameters = (New-Object Type[](0)),
        
        [Parameter( Position = 1 )]
        [Type]
        $ReturnType = [Void]
    )

    $Domain = [AppDomain]::CurrentDomain
    $DynAssembly = New-Object System.Reflection.AssemblyName('ReflectedDelegate')
    $AssemblyBuilder = $Domain.DefineDynamicAssembly($DynAssembly, [System.Reflection.Emit.AssemblyBuilderAccess]::Run)
    $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('InMemoryModule', $false)
    $TypeBuilder = $ModuleBuilder.DefineType('MyDelegateType', 'Class, Public, Sealed, AnsiClass, AutoClass', [System.MulticastDelegate])
    $ConstructorBuilder = $TypeBuilder.DefineConstructor('RTSpecialName, HideBySig, Public', [System.Reflection.CallingConventions]::Standard, $Parameters)
    $ConstructorBuilder.SetImplementationFlags('Runtime, Managed')
    $MethodBuilder = $TypeBuilder.DefineMethod('Invoke', 'Public, HideBySig, NewSlot, Virtual', $ReturnType, $Parameters)
    $MethodBuilder.SetImplementationFlags('Runtime, Managed')
    
    Write-Output $TypeBuilder.CreateType()
}


# Function written by Matt Graeber, Twitter: @mattifestation, Blog: http://www.exploit-monday.com/
# http://www.exploit-monday.com/2012/05/accessing-native-windows-api-in.html
Function Get-ProcAddress
{
    Param
    (
        [OutputType([IntPtr])]
    
        [Parameter( Position = 0, Mandatory = $True )]
        [String]
        $Module,
        
        [Parameter( Position = 1, Mandatory = $True )]
        [String]
        $Procedure
    )

    # Get a reference to System.dll in the GAC
    $SystemAssembly = [AppDomain]::CurrentDomain.GetAssemblies() |
        Where-Object { $_.GlobalAssemblyCache -And $_.Location.Split('\\')[-1].Equals('System.dll') }
    $UnsafeNativeMethods = $SystemAssembly.GetType('Microsoft.Win32.UnsafeNativeMethods')
    # Get a reference to the GetModuleHandle and GetProcAddress methods
    $GetModuleHandle = $UnsafeNativeMethods.GetMethod('GetModuleHandle')
    $GetProcAddress = $UnsafeNativeMethods.GetMethod('GetProcAddress')
    # Get a handle to the module specified
    $Kern32Handle = $GetModuleHandle.Invoke($null, @($Module))
    $tmpPtr = New-Object IntPtr
    $HandleRef = New-Object System.Runtime.InteropServices.HandleRef($tmpPtr, $Kern32Handle)

    # Return the address of the function
    Write-Output $GetProcAddress.Invoke($null, @([System.Runtime.InteropServices.HandleRef]$HandleRef, $Procedure))
}

# win 32 constants
$constants = @{
    DACL_SECURITY_INFORMATION = 0x4
    ACCESS_SYSTEM_SECURITY = 0x01000000
    SYNCHRONIZE = 0x00100000
    PROCESS_CREATE_PROCESS = 0x0080
    PROCESS_CREATE_THREAD = 0x0002
    PROCESS_DUP_HANDLE = 0x0040
    PROCESS_QUERY_INFORMATION = 0x0400
    PROCESS_QUERY_LIMITED_INFORMATION = 0x1000
    PROCESS_SET_INFORMATION = 0x0200
    PROCESS_SET_QUOTA = 0x0100
    PROCESS_SUSPEND_RESUME = 0x0800
    PROCESS_TERMINATE = 0x0001
    PROCESS_VM_OPERATION = 0x0008
    PROCESS_VM_READ = 0x0010
    PROCESS_VM_WRITE = 0x0020
    DELETE = 0x00010000
    READ_CONTROL = 0x00020000
    WRITE_DAC = 0x00040000
    WRITE_OWNER = 0x00080000
    OBJECT_INHERIT_ACE = 0x1
    TRUSTEE_IS_NAME = 0x1
    TRUSTEE_IS_SID = 0x0
    TRUSTEE_IS_USER = 0x1
    TRUSTEE_IS_WELL_KNOWN_GROUP = 0x5
    TRUSTEE_IS_GROUP = 0x2
}
$Win32Constants = New-Object PSObject -Property $constants
$STANDARD_RIGHTS_REQUIRED = 0x000f0000
$PROCESS_ALL_ACCESS = $STANDARD_RIGHTS_REQUIRED -bor $Win32Constants.SYNCHRONIZE -bor 0xFFF

# enum ACCESS_MODE
# https://msdn.microsoft.com/en-us/library/windows/desktop/aa374899(v=vs.85).aspx
$access = @{
    NOT_USED_ACCESS = 0
    GRANT_ACCESS = 1
    SET_ACCESS = 2
    DENY_ACCESS = 3
    REVOKE_ACCESS = 4
    SET_AUDIT_SUCCESS = 5
    SET_AUDIT_FAILURE = 6
}
$ACCESS_MODE = new-object PSObject -Property $access

# enum SE_OBJECT_TYPE
# https://msdn.microsoft.com/en-us/library/windows/desktop/aa379593(v=vs.85).aspx
$objTypes = @{
    SE_UNKNOWN_OBJECT_TYPE = 0
    SE_FILE_OBJECT = 0x1
    SE_SERVICE  = 0x2
    SE_PRINTER  = 0x3
    SE_REGISTRY_KEY  = 0x4
    SE_LMSHARE  = 0x5
    SE_KERNEL_OBJECT  = 0x6
    SE_WINDOW_OBJECT  = 0x7
    SE_DS_OBJECT  = 0x8
    SE_DS_OBJECT_ALL  = 0x9
    SE_PROVIDER_DEFINED_OBJECT  = 0xa
    SE_WMIGUID_OBJECT  = 0xb
    SE_REGISTRY_WOW64_32KEY  = 0xc
}
$SE_OBJECT_TYPE = new-object PSObject -Property $objTypes

# enum WELL_KNOWN_SID_TYPE
# https://msdn.microsoft.com/en-us/library/windows/desktop/aa379650(v=vs.85).aspx
$sids = @{
    WinNullSid                                   = 0
    WinWorldSid                                  = 1
    WinLocalSid                                  = 2
    WinCreatorOwnerSid                           = 3
    WinCreatorGroupSid                           = 4
    WinCreatorOwnerServerSid                     = 5
    WinCreatorGroupServerSid                     = 6
    WinNtAuthoritySid                            = 7
    WinDialupSid                                 = 8
    WinNetworkSid                                = 9
    WinBatchSid                                  = 10
    WinInteractiveSid                            = 11
    WinServiceSid                                = 12
    WinAnonymousSid                              = 13
    WinProxySid                                  = 14
    WinEnterpriseControllersSid                  = 15
    WinSelfSid                                   = 16
    WinAuthenticatedUserSid                      = 17
    WinRestrictedCodeSid                         = 18
    WinTerminalServerSid                         = 19
    WinRemoteLogonIdSid                          = 20
    WinLogonIdsSid                               = 21
    WinLocalSystemSid                            = 22
    WinLocalServiceSid                           = 23
    WinNetworkServiceSid                         = 24
    WinBuiltinDomainSid                          = 25
    WinBuiltinAdministratorsSid                  = 26
    WinBuiltinUsersSid                           = 27
    WinBuiltinGuestsSid                          = 28
    WinBuiltinPowerUsersSid                      = 29
    WinBuiltinAccountOperatorsSid                = 30
    WinBuiltinSystemOperatorsSid                 = 31
    WinBuiltinPrintOperatorsSid                  = 32
    WinBuiltinBackupOperatorsSid                 = 33
    WinBuiltinReplicatorSid                      = 34
    WinBuiltinPreWindows2000CompatibleAccessSid  = 35
    WinBuiltinRemoteDesktopUsersSid              = 36
    WinBuiltinNetworkConfigurationOperatorsSid   = 37
    WinAccountAdministratorSid                   = 38
    WinAccountGuestSid                           = 39
    WinAccountKrbtgtSid                          = 40
    WinAccountDomainAdminsSid                    = 41
    WinAccountDomainUsersSid                     = 42
    WinAccountDomainGuestsSid                    = 43
    WinAccountComputersSid                       = 44
    WinAccountControllersSid                     = 45
    WinAccountCertAdminsSid                      = 46
    WinAccountSchemaAdminsSid                    = 47
    WinAccountEnterpriseAdminsSid                = 48
    WinAccountPolicyAdminsSid                    = 49
    WinAccountRasAndIasServersSid                = 50
    WinNTLMAuthenticationSid                     = 51
    WinDigestAuthenticationSid                   = 52
    WinSChannelAuthenticationSid                 = 53
    WinThisOrganizationSid                       = 54
    WinOtherOrganizationSid                      = 55
    WinBuiltinIncomingForestTrustBuildersSid     = 56
    WinBuiltinPerfMonitoringUsersSid             = 57
    WinBuiltinPerfLoggingUsersSid                = 58
    WinBuiltinAuthorizationAccessSid             = 59
    WinBuiltinTerminalServerLicenseServersSid    = 60
    WinBuiltinDCOMUsersSid                       = 61
    WinBuiltinIUsersSid                          = 62
    WinIUserSid                                  = 63
    WinBuiltinCryptoOperatorsSid                 = 64
    WinUntrustedLabelSid                         = 65
    WinLowLabelSid                               = 66
    WinMediumLabelSid                            = 67
    WinHighLabelSid                              = 68
    WinSystemLabelSid                            = 69
    WinWriteRestrictedCodeSid                    = 70
    WinCreatorOwnerRightsSid                     = 71
    WinCacheablePrincipalsGroupSid               = 72
    WinNonCacheablePrincipalsGroupSid            = 73
    WinEnterpriseReadonlyControllersSid          = 74
    WinAccountReadonlyControllersSid             = 75
    WinBuiltinEventLogReadersGroup               = 76
    WinNewEnterpriseReadonlyControllersSid       = 77
    WinBuiltinCertSvcDComAccessGroup             = 78
    WinMediumPlusLabelSid                        = 79
    WinLocalLogonSid                             = 80
    WinConsoleLogonSid                           = 81
    WinThisOrganizationCertificateSid            = 82
    WinApplicationPackageAuthoritySid            = 83
    WinBuiltinAnyPackageSid                      = 84
    WinCapabilityInternetClientSid               = 85
    WinCapabilityInternetClientServerSid         = 86
    WinCapabilityPrivateNetworkClientServerSid   = 87
    WinCapabilityPicturesLibrarySid              = 88
    WinCapabilityVideosLibrarySid                = 89
    WinCapabilityMusicLibrarySid                 = 90
    WinCapabilityDocumentsLibrarySid             = 91
    WinCapabilitySharedUserCertificatesSid       = 92
    WinCapabilityEnterpriseAuthenticationSid     = 93
    WinCapabilityRemovableStorageSid             = 94
}
$WELL_KNOWN_SID_TYPE = New-Object PSObject -Property $sids


# win32 structures
# thanks to http://www.exploit-monday.com/2012/07/structs-and-enums-using-reflection.html && https://github.com/PowerShellMafia/PowerSploit 

$Domain = [AppDomain]::CurrentDomain
$DynAssembly = New-Object System.Reflection.AssemblyName('TestAssembly')
$AssemblyBuilder = $Domain.DefineDynamicAssembly($DynAssembly, [System.Reflection.Emit.AssemblyBuilderAccess]::Run)
$ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('TestModule', $False)

# Struct TRUSTEE
# https://msdn.microsoft.com/en-us/library/windows/desktop/aa379636(v=vs.85).aspx
$Attributes = 'AutoLayout, AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'
$TypeBuilder = $ModuleBuilder.DefineType('TRUSTEE', $Attributes, [System.ValueType])
$TypeBuilder.DefineField('pMultipleTrustee', [IntPtr], 'Public') | Out-Null
$TypeBuilder.DefineField('MultipleTrusteeOperation', [UInt32], 'Public') | Out-Null
$TypeBuilder.DefineField('TrusteeForm', [UInt32], 'Public') | Out-Null
$TypeBuilder.DefineField('TrusteeType', [UInt32], 'Public') | Out-Null
$TypeBuilder.DefineField('ptstrName', [IntPtr], 'Public') | Out-Null
$TRUSTEE = $TypeBuilder.CreateType()

# Struct EXPLICIT_ACCESS
# https://msdn.microsoft.com/en-us/library/windows/desktop/aa446627(v=vs.85).aspx
$Attributes = 'AutoLayout, AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'
$TypeBuilder = $ModuleBuilder.DefineType('EXPLICIT_ACCESS', $Attributes, [System.ValueType])
$TypeBuilder.DefineField('grfAccessPermissions', [UInt32], 'Public') | Out-Null
$TypeBuilder.DefineField('grfAccessMode', [UInt32], 'Public') | Out-Null
$TypeBuilder.DefineField('grfInheritance', [UInt32], 'Public') | Out-Null
$TypeBuilder.DefineField('Trustee', $TRUSTEE, 'Public') | Out-Null
$EXPLICIT_ACCESS = $TypeBuilder.CreateType()

# Struct ACL
# https://msdn.microsoft.com/en-us/library/windows/desktop/aa374931(v=vs.85).aspx
$Attributes = 'AutoLayout, AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'
$TypeBuilder = $ModuleBuilder.DefineType('ACL', $Attributes, [System.ValueType])
$TypeBuilder.DefineField('AclRevision', [Byte], 'Public') | Out-Null
$TypeBuilder.DefineField('Sbz1', [Byte], 'Public') | Out-Null
$TypeBuilder.DefineField('AclSize', [UInt16], 'Public') | Out-Null
$TypeBuilder.DefineField('AceCount', [UInt16], 'Public') | Out-Null
$TypeBuilder.DefineField('Sbz2', [UInt16], 'Public') | Out-Null
$ACL = $TypeBuilder.CreateType()

# open actual win32 handle to the process. 
# Get-Process doesn't seem to open the correct handle.
write-verbose "Obtaining process handle via OpenProcess() API Call to process id $processId..."
$OpenProcessAddr = Get-ProcAddress kernel32.dll OpenProcess
	$OpenProcessDelegate = Get-DelegateType @([UInt32], [Bool], [UInt32]) ([IntPtr])
	$OpenProcess = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($OpenProcessAddr, $OpenProcessDelegate)

[IntPtr]$pHandle = [IntPtr]::Zero
$pHandle = $OpenProcess.Invoke($PROCESS_ALL_ACCESS, $false, $processId)
if ($pHandle -eq [IntPtr]::Zero) {
    Throw "Unable to open the handle to the specified process.  You must have SeDebugPrivilege to open the memory space of another process."
} else {
    write-verbose "Obtained handle to process id $processId.  Handle: $pHandle"
}

# configure security for the specified process
<# 
https://forum.sysinternals.com/default-process-dacl-and-newly-created-objects_topic14904.html
https://msdn.microsoft.com/en-us/library/windows/desktop/aa446596(v=vs.85).aspx
1. GetKernelObjectSecurity or GetSecurityInfo- Get the current DACL
2. BuildExplicitAccessWithName - Set new Deny/Allow permissions, and get a New DACL
3. SetEntriesInAcl - Merge the 2 ACLs (The old with the new) (this allows it to maintain its current permissions)
4. SetKernelObjectSecurity - Set the process's access toke = the merged ACL
#>

# get the DACL of the process. 

write-verbose "Getting a pointer to the existing DACL using GetSecurityInfo()..."
# GetSecurityInfo() https://msdn.microsoft.com/en-us/library/windows/desktop/aa446654(v=vs.85).aspx
$GetSecurityInfoAddr = get-ProcAddress advapi32.dll GetSecurityInfo 
    $GetSecurityInfoDelegate = get-DelegateType([IntPtr], [UInt32], [UInt32], [IntPtr].MakeByRefType(), `
                                                [IntPtr].MakeByRefType(), [IntPtr].MakeByRefType(), [IntPtr].MakeByRefType(), `
                                                [IntPtr].MakeByRefType()) ([UInt32])
    $GetSecurityInfo = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($GetSecurityInfoAddr, $GetSecurityInfoDelegate)

[IntPtr]$ppsidOwner = [IntPtr]::Zero
[IntPtr]$ppsidGroup = [IntPtr]::Zero
[IntPtr]$ppDacl = [IntPtr]::Zero
[IntPtr]$ppSacl = [IntPtr]::Zero
[IntPtr]$ppSecurityDescriptor = [IntPtr]::Zero
$retval = $GetSecurityInfo.Invoke($pHandle, $SE_OBJECT_TYPE.SE_KERNEL_OBJECT, $Win32Constants.DACL_SECURITY_INFORMATION, `
                        [ref]$ppsidOwner, [ref]$ppsidGroup, [ref]$ppDacl, [ref]$ppSacl, [ref]$ppSecurityDescriptor)
if ($retval -eq 0 -and $ppDacl -ne [IntPtr]::Zero){
    write-verbose "Successfully retrieved pointer to DACL: $ppDacl."
} else {
    $apiErr = New-Object ComponentModel.Win32Exception
    Throw "Unable to get new DACL: $($apiErr.NativeErrorCode): $($apiErr.Message)" 
}

$CurrentAcl = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ppDacl, [Type]$ACL)
write-verbose "Current DACL: "
write-verbose ($CurrentAcl | out-String)


$GetKernelObjectSecurityAddr = Get-ProcAddress advapi32.dll GetKernelObjectSecurity
    $GetKernelObjectSecurityDelegate = get-DelegateType @([IntPtr], [UInt32], [byte[]], [UInt32], [UInt32].MakeByRefType()) ([Bool])
    $GetKernelObjectSecurity = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($GetKernelObjectSecurityAddr, $GetKernelObjectSecurityDelegate)

# Step 1. Get the size needed for the DACL byte array
write-verbose "Determining DACL size with GetKernelObjectSecurity() API call..."
[Byte[]]$pSecurityDescriptor = New-Object Byte[](0)
[UInt32]$lpnLengthNeeded = 0
$Success = $GetKernelObjectSecurity.Invoke($pHandle, $Win32Constants.DACL_SECURITY_INFORMATION, $pSecurityDescriptor, 0, [ref]$lpnLengthNeeded)
if ($lpnLengthNeeded -le 0) {
    Throw (New-Object ComponentModel.Win32Exception)
} else {
    Write-verbose "DACL size is $lpnLengthNeeded"
}

# Step 2. call GetKernelObjectSecurity() again to get the actual DACL now that we know that size
write-verbose "Getting process DACL with GetKernelObjectSecurity() API call..."
$pSecurityDescriptor = New-Object Byte[]($lpnLengthNeeded)
$Success = $GetKernelObjectSecurity.Invoke($pHandle, $Win32Constants.DACL_SECURITY_INFORMATION, $pSecurityDescriptor, $lpnLengthNeeded, [ref]$lpnLengthNeeded)
if ($Success ) {
    write-verbose "DACL obtained: $pSecurityDescriptor"
} else {
    Throw (New-Object ComponentModel.Win32Exception)
}

# Build a new DACL to deny relevant permissions to Everyone group.  
write-verbose "Building a new DACL with BuildExplicitAccessWithName()..."

# Step 1 - Get the SID to the Everyone group
write-verbose "Getting the SID for the Everyone group..."
$CreateWellKnownSidAddr = get-ProcAddress advapi32.dll CreateWellKnownSid 
    $CreateWellKnownSidDelegate = get-DelegateType @([UInt32], [IntPtr], [IntPtr], [UInt32].MakeByRefType()) ([Bool])
    $CreateWellKnownSid = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($CreateWellKnownSidAddr, $CreateWellKnownSidDelegate)

[UInt32]$RealSize = 2000
$pAllUsersSid = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($RealSize)
$Success = $CreateWellKnownSid.Invoke($WELL_KNOWN_SID_TYPE.WinLocalSystemSid, [IntPtr]::Zero, $pAllUsersSid, [Ref]$RealSize)
if (-not $Success)
{
    Throw (New-Object ComponentModel.Win32Exception)
}
write-verbose "Obtained SID: $pAllUsersSid."

# Step 2 - Build a TRUSTEE object with the SID
write-verbose "Building Trustee object for the Everyone group"
# Everyone group TRUSTEE object
# https://github.com/PowerShellMafia/PowerSploit
$TrusteeSize = [System.Runtime.InteropServices.Marshal]::SizeOf([Type]$TRUSTEE)
$TrusteePtr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($TrusteeSize)
$TrusteeObj = [System.Runtime.InteropServices.Marshal]::PtrToStructure($TrusteePtr, [Type]$TRUSTEE)
[System.Runtime.InteropServices.Marshal]::FreeHGlobal($TrusteePtr)
$TrusteeObj.pMultipleTrustee = [IntPtr]::Zero
$TrusteeObj.MultipleTrusteeOperation = 0
$TrusteeObj.TrusteeForm = $Win32Constants.TRUSTEE_IS_SID
$TrusteeObj.TrusteeType = $Win32Constants.TRUSTEE_IS_WELL_KNOWN_GROUP
$TrusteeObj.ptstrName = $pAllUsersSid

# Step 3 - Build the EXPLICIT_ACCESS structure
write-verbose "Building an EXPLICIT_ACCESS structure"
#https://github.com/PowerShellMafia/PowerSploit
# EXPLICIT_ACCESS object
[IntPtr]$pExplicitAccess = [IntPtr]::Zero
$ExplicitAccessSize = [System.Runtime.InteropServices.Marshal]::SizeOf([Type]$EXPLICIT_ACCESS)
$ExplicitAccessPtr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($ExplicitAccessSize)
$ExplicitAccess = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ExplicitAccessPtr, [Type]$EXPLICIT_ACCESS)
[System.Runtime.InteropServices.Marshal]::FreeHGlobal($ExplicitAccessPtr)
#$ExplicitAccess.grfAccessMode = $ACCESS_MODE.DENY_ACCESS
$ExplicitAccess.grfAccessMode = $ACCESS_MODE.GRANT_ACCESS
# not clear exactly what needs to be dinied.  Just PROCESS_TERMINATE & PROCESS_SUSPEND_RESUME didn't seem to do anything
# https://stackoverflow.com/questions/6185975/prevent-user-process-from-being-killed-with-end-process-from-process-explorer
<#
$ExplicitAccess.grfAccessPermissions =  $PROCESS_ALL_ACCESS -bor `
                                        $Win32Constants.WRITE_DAC -bor `
                                        $Win32Constants.WRITE_OWNER -bor `
                                        $Win32Constants.READ_CONTROL -bor `
                                        $Win32Constants.DELETE  
#>
$ExplicitAccess.grfAccessPermissions = $PROCESS_ALL_ACCESS                                        
$ExplicitAccess.grfInheritance = $Win32Constants.OBJECT_INHERIT_ACE
$ExplicitAccess.Trustee = $TrusteeObj
write-verbose "Built EXPLICIT_ACCESS structure: "
write-verbose ($ExplicitAccess | fl * |  Out-String )

# step 4 - Initialize the DACL
write-verbose "Initializing the EXPLICIT_ACCESS structure with BuildExplicitAccessWithName()..."
# https://msdn.microsoft.com/en-us/library/windows/desktop/aa379576(v=vs.85).aspx
$BuildExplicitAccessWithNameAddr = get-ProcAddress advapi32.dll BuildExplicitAccessWithNameW
    $BuildExplicitAccessWithNameDelegate = Get-DelegateType @($EXPLICIT_ACCESS.MakeByRefType(), [String], [UInt32], [UInt32], [UInt32]) ([Void])
    $BuildExplicitAccessWithName = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($BuildExplicitAccessWithNameAddr, $BuildExplicitAccessWithNameDelegate)

$BuildExplicitAccessWithName.Invoke([ref]$ExplicitAccess, $TrusteeObj.ptstrName, $ExplicitAccess.grfAccessPermissions, $ExplicitAccess.grfAccessMode, $ExplicitAccess.grfInheritance)

# Merge the ACLs
write-verbose "Merging the DACL with the exiting DACL using SetEntriesInAcl()..."
$SetEntriesInAclAddr = get-ProcAddress advapi32.dll SetEntriesInAclW
    $SetEntriesInAclDelegate = get-DelegateType @([UInt32], $EXPLICIT_ACCESS.MakeByRefType(), [IntPtr], [IntPtr].MakeByRefType()) ([UInt32])
    $SetEntriesInAcl = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($SetEntriesInAclAddr, $SetEntriesInAclDelegate)

[IntPtr]$pNewAcl = [IntPtr]::Zero
#[IntPtr]$ppSD = [System.Runtime.InteropServices.Marshal]::AllocHGlobal([System.Runtime.InteropServices.Marshal]::SizeOf([Type]$pSecurityDescriptor)


# get the pointer to the pSecurityDescriptor (which is a byte array)

<#
- this doesn't work, there doesn't appear to be a way in powershell to get the address of the an object, like you can in c or c#, at least not a managed object like byte[]

[IntPtr]$ppSD = [IntPtr]::Zero
#$ppSD = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($pSecurityDescriptor.Length)
# https://msdn.microsoft.com/en-us/library/ms146625(v=vs.110).aspx
#[System.Runtime.InteropServices.Marshal]::Copy($pSecurityDescriptor, 0, $ppSD, $pSecurityDescriptor.Length)
#[System.Runtime.InteropServices.Marshal]::StructureToPtr($pSecurityDescriptor, $ppSD, $false)

$ppSD

# free the pointer 
[System.Runtime.InteropServices.Marshal]::FreeHGlobal($ppSD)
#>

#$retval = $SetEntriesInAcl.Invoke(1, [ref]$ExplicitAccess, $ppDacl, [ref]$pNewAcl)
$retval = $SetEntriesInAcl.Invoke(1, [ref]$ExplicitAccess, [IntPtr]::Zero, [ref]$pNewAcl)
 
if ($pNewAcl -eq [IntPtr]::Zero) {
    $apiErr = New-Object ComponentModel.Win32Exception
    Throw "Unable to get new DACL: $($apiErr.NativeErrorCode): $($apiErr.Message)" 
} else {
    write-verbose "Successfully got new DACL."
}

$NewAcl = [System.Runtime.InteropServices.Marshal]::PtrToStructure($pNewAcl, [Type]$ACL)
write-verbose "New DACL: "
write-verbose ($NewAcl | Out-String)

# finally set the new ACL using SetSecurityInfo()
# https://msdn.microsoft.com/en-us/library/windows/desktop/aa379588(v=vs.85).aspx
write-verbose "Setting new DACL with SetSecurityInfo()..."
$SetSecurityInfoAddr = get-ProcAddress advapi32.dll SetSecurityInfo 
    $SetSecurityInfoDelegate = get-DelegateType @([IntPtr], [UInt32], [UInt32], [IntPtr], [IntPtr], [IntPtr], [IntPtr] )([UInt32])
    $SetSecurityInfo = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($SetSecurityInfoAddr, $SetSecurityInfoDelegate)

$retval = $SetSecurityInfo.Invoke($pHandle, $SE_OBJECT_TYPE.SE_KERNEL_OBJECT, $Win32Constants.DACL_SECURITY_INFORMATION, [IntPtr]::Zero, [IntPtr]::Zero, $pNewAcl, [IntPtr]::Zero)

if ($retval -eq 0) {
    Write-verbose "Successfully changed security for process ID: $processId"
} else {
    $apiErr = New-Object ComponentModel.Win32Exception
    Throw "Unable to get new DACL: $($apiErr.NativeErrorCode): $($apiErr.Message)" 
}



# close the handle to the process
write-verbose "Closing handle $pHandle..."
$CloseHandleAddr = Get-ProcAddress kernel32.dll CloseHandle
    $CloseHandleDelegate = get-DelegateType @([IntPtr]) ([Bool])
    $CloseHandle = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($closeHandleAddr, $CloseHandleDelegate)
$retval = $CloseHandle.Invoke($pHandle)
if ($retval) {
    write-verbose "Handle closed."
} else {
    Throw "Unable to close handle to process $processId."
}