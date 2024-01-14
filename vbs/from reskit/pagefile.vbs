'********************************************************************
'*
'* File:           PageFile.vbs
'* Created:        March 1999
'* Version:        1.0
'*
'*  Main Function:  Controls Pagefiles on a machine.
'*
'*  1.  PageFile.vbs /L [/S <server>] [/U <username>]
'*                  [/W <password>] [/O <outputfile>]
'*  
'*  2.  PageFile.vbs /R /M <maxsize> /Z <minsize> /P <pagefile> [/B] [/F]
'*                  [/S <server>] [/U <username>] [/W <password>]
'*                  [/O <outputfile>]
'*
'* Copyright (C) 1998 Microsoft Corporation
'*
'********************************************************************
OPTION EXPLICIT

    'Define constants
    CONST CONST_REBOOT_FORCE            = 6
    CONST CONST_REBOOT_NOFORCE          = 2
    CONST CONST_ERROR                   = 0
    CONST CONST_WSCRIPT                 = 1
    CONST CONST_CSCRIPT                 = 2
    CONST CONST_SHOW_USAGE              = 3
    CONST CONST_PROCEED                 = 4
    CONST CONST_LIST                    = "LIST"
    CONST CONST_RESIZE                  = "RESIZE"

    'Declare variables
    Dim intOpMode, i
    Dim strServer, strUserName, strPassword, strOutputFile
    Dim strOldName
    Dim intMin, intMax
    Dim blnReboot, blnForce

    'Make sure the host is csript, if not then abort
    VerifyHostIsCscript()

    'Parse the command line
    intOpMode = intParseCmdLine(strServer      ,  _
                                strUserName    ,  _
                                strPassword    ,  _
                                strOutputFile  ,  _
                                intMin         ,  _
                                intMax         ,  _
                                strOldName     ,  _
                                blnReboot      ,  _
                                blnForce          )

    Select Case intOpMode

        Case CONST_SHOW_USAGE
            Call ShowUsage()

        Case CONST_LIST                 
            Call ListPageFiles(strServer     , _
                               strOutputFile , _
                               strUserName   , _
                               strPassword     )

        Case CONST_RESIZE
            Call ResizePageFile(strServer     , _
                                strOutputFile , _
                                strUserName   , _
                                strPassword   , _
                                strOldName    , _
                                intMax        , _
                                intMin        , _
                                blnReboot     , _
                                blnForce        )

        Case CONST_ERROR
            'Do Nothing

        Case Else                    'Default -- should never happen
            Call Wscript.Echo("Error occurred in passing parameters.")

    End Select

'********************************************************************
'*
'* Sub ListPageFiles()
'*
'* Purpose: Lists data on pagefiles.
'*
'* Input:   strServer           a machine name
'*          strOutputFile       an output file name
'*          strUserName         the current user's name
'*          strPassword         the current user's password
'*
'* Output:  Results are either printed on screen or saved in strOutputFile.
'*
'********************************************************************
Private Sub ListPageFiles(strServer, strOutputFile, strUserName, strPassword)

    ON ERROR RESUME NEXT

    Dim objFileSystem, objOutputFile, objService, WbemObjectSet, objInst

    'Open a text file for output if the file is requested
    If Not IsEmpty(strOutputFile) Then
        If (NOT blnOpenFile(strOutputFile, objOutputFile)) Then
            Call Wscript.Echo ("Could not open an output file.")
            Exit Sub
        End If
    End If

    'Establish a connection with the server.
    If blnConnect("root\cimv2" , _
                   strUserName , _
                   strPassword , _
                   strServer   , _
                   objService  ) Then
        Call Wscript.Echo("")
        Call Wscript.Echo("Please check the server name, " _
                        & "credentials and WBEM Core.")
        Exit Sub
    End If

	Set WbemObjectSet = objService.InstancesOf("Win32_PageFile")
	If blnErrorOccurred(" attempting to get Pagefile Instances.") then
            Exit Sub
        End If

	i = 0
	WScript.Echo WbemObjectSet.Count & " Pagefile(s) detected:"
	For Each objInst In WbemObjectSet
		i = i + 1
		Call WriteLine ("", objOutputFile)
		Call WriteLine ("File " & Cstr(i) & " = " & objInst.Name, _
                                objOutputFile)
		Call WriteLine ("Initial Size: " & objInst.InitialSize & _
                                "M", objOutputFile)
		Call WriteLine ("Maximum Size: " & objInst.MaximumSize & _
                                "M", objOutputFile)
		Call WriteLine ("Free Space: " & objInst.FreeSpace & "M", _
                                 objOutputFile)
		Call WriteLine ("Installed " & strFormatMOFTime _
                               (objInst.InstallDate), objOutputFile)
		Call WriteLine ("Status: " & objInst.Status, objOutputFile)
	Next 

    If IsObject(objOutputFile) Then
        objOutputFile.Close
        Call Wscript.Echo ("Results are saved in file " & strOutputFile & ".")
    End If

End Sub

'********************************************************************
'*
'* Sub ResizePageFile()
'*
'* Purpose: Lists data on pagefiles.
'*
'* Input:   strServer           a machine name
'*          strOutputFile       an output file name
'*          strUserName         the current user's name
'*          strPassword         the current user's password
'*          strOldName          the name of the target pagefile
'*          intMax              the maximum size
'*          intMin              the minimum size
'*          blnReboot           reboot after operation
'*          blnForce            force reboot
'*
'* Output:  Results are either printed on screen or saved in strOutputFile.
'*
'********************************************************************
Private Sub ResizePageFile(strServer     , _
                           strOutputFile , _
                           strUserName   , _
                           strPassword   , _
                           strOldName    , _
                           intMax        , _
                           intMin        , _
                           blnReboot     , _
                           blnForce        )

    ON ERROR RESUME NEXT

    Dim objFileSystem, objOutputFile, objService, obj, objPutResult
    Dim strQuery
    
    'Open a text file for output if the file is requested
    If Not IsEmpty(strOutputFile) Then
        If (NOT blnOpenFile(strOutputFile, objOutputFile)) Then
            Call Wscript.Echo ("Could not open an output file.")
            Exit Sub
        End If
    End If

    'Establish a connection with the server.
    If blnConnect("root\cimv2" , _
                   strUserName , _
                   strPassword , _
                   strServer   , _
                   objService  ) Then
        Call Wscript.Echo("")
        Call Wscript.Echo("Please check the server name, " _
                        & "credentials and WBEM Core.")
        Exit Sub
    End If

	'Ensure query key is nonempty
    If isEmpty(strOldName) then 
        Wscript.echo "The pagefile must have a name to be resized."
        Wscript.quit
    end if
    If isEmpty (intMin) then 
        Wscript.echo "Pagefile resize requested but new size not specified."
        Wscript.quit
    End if
	'Check that sizes are reasonable?

	'Grab PageFile Instance by its filename
	strQuery = "Win32_PageFile=""" & strDoubleBackSlashes _
                   (strOldName) & """"
    set obj = objService.Get (strQuery)
	If blnErrorOccurred(" getting an instance of the PageFile " _
           & strOldName) then Exit Sub

	'Check that sizes are different
    If obj.InitialSize = intMin and obj.MaximumSize = intMax then
        call Print ("Resize already matches existing pagefile.")
        Wscript.quit
    End If

    obj.InitialSize = intMin
    If not isEmpty (intMax) then obj.MaximumSize = intMax

    set objPutResult = obj.Put_(1)
	If blnErrorOccurred(" trying to resize the PageFile") then Exit Sub
    Call WriteLine ("Resize of " & strOldName & " to " _
                & CStr(intMin) & "-" & CStr(intMax) & "M", objOutputFile)

	'Alert user of need to reboot before settings will take effect
    If blnReboot then
        Call Reboot (objService, strServer, blnForce, objOutputFile)
    Else
        Call Print ("The changes will not take effect until server restarts.")
    End If

    If IsObject(objOutputFile) Then
        objOutputFile.Close
        Call Wscript.Echo ("Results are saved in file " & strOutputFile & ".")
    End If

End Sub

'********************************************************************
'*
'* Sub Reboot()
'*
'* Purpose: Lists data on pagefiles.
'*
'* Input:   objService           the WBEM object
'*          strServer            the target machine
'*          blnForce             Force a reboot
'*
'* Output:  Results are either printed on screen or saved in strOutputFile.
'*
'********************************************************************
Sub Reboot (objService, strServer, blnForce, objOutputFile)

    Dim objEnumerator, objInstance
    Dim strQuery, strMessage
    Dim intStatus

    strQuery = "Select * From Win32_OperatingSystem"

    Set objEnumerator = objService.ExecQuery (strQuery,,0)
	If blnErrorOccurred(" during the query.") Then Exit Sub

    For Each objInstance in objEnumerator

        If objInstance is nothing Then
            Exit Sub
        Else
            If blnForce Then
                intStatus = objInstance.Win32ShutDown (CONST_REBOOT_FORCE)
            Else
                intStatus = objInstance.Win32ShutDown (CONST_REBOOT_NOFORCE)
            End If
            If blnErrorOccurred(".") Then
                strMessage = "Failed to reboot machine " & strServer & "."
            Else
                strMessage = "Rebooting machine " & strServer & "..."
            End If
            Call WriteLine( strMessage, objOutputFile)
        End If
    Next

	If blnErrorOccurred(" trying to reboot server " & strServer) Then
	    Exit Sub
	End If

End Sub

'********************************************************************
'*
'* Function intParseCmdLine()
'*
'* Purpose: Parses the command line.
'* Input:   
'*
'* Output:  strServer         a remote server ("" = local server")
'*          strUserName       the current user's name
'*          strPassword       the current user's password
'*          strOutputFile     an output file name
'*
'********************************************************************
Private Function intParseCmdLine(strServer      ,  _
                                 strUserName    ,  _
                                 strPassword    ,  _
                                 strOutputFile  ,  _
                                 intMin         ,  _
                                 intMax         ,  _
                                 strOldName     ,  _
                                 blnReboot      ,  _
                                 blnForce          )

    ON ERROR RESUME NEXT

    Dim strFlag
    Dim intState, intArgIter
    Dim objFileSystem

    If Wscript.Arguments.Count > 0 Then
        strFlag = Wscript.arguments.Item(0)
    End If

    If IsEmpty(strFlag) Then                'No arguments have been received
        intParseCmdLine = CONST_LIST
        Exit Function
    End If

    'Check if the user is asking for help or is just confused
    If (strFlag="help") OR (strFlag="/h") OR (strFlag="\h") OR (strFlag="-h") _
        OR (strFlag = "\?") OR (strFlag = "/?") OR (strFlag = "?") _ 
        OR (strFlag="h") Then
        intParseCmdLine = CONST_SHOW_USAGE
        Exit Function
    End If

    'Retrieve the command line and set appropriate variables
     intArgIter = 0
    Do While intArgIter <= Wscript.arguments.Count - 1
        Select Case Left(LCase(Wscript.arguments.Item(intArgIter)),2)
  
            Case "/s"
                If Not blnGetArg("Server", strServer, intArgIter) Then
                    intParseCmdLine = CONST_ERROR
                    Exit Function
                End If
                intArgIter = intArgIter + 1

            Case "/o"
                If Not blnGetArg("Output File", strOutputFile, intArgIter) Then
                    intParseCmdLine = CONST_ERROR
                    Exit Function
                End If
                intArgIter = intArgIter + 1

            Case "/u"
                If Not blnGetArg("User Name", strUserName, intArgIter) Then
                    intParseCmdLine = CONST_ERROR
                    Exit Function
                End If
                intArgIter = intArgIter + 1

            Case "/w"
                If Not blnGetArg("User Password", strPassword, intArgIter) Then
                    intParseCmdLine = CONST_ERROR
                    Exit Function
                End If
                intArgIter = intArgIter + 1

            Case "/l"
                intParseCmdLine = CONST_LIST
                intArgIter = intArgIter + 1

            Case "/r"
                intParseCmdLine = CONST_RESIZE
                intArgIter = intArgIter + 1

            Case "/p"
                If Not blnGetArg("Page File Name", strOldName, intArgIter) Then
                    intParseCmdLine = CONST_ERROR
                    Exit Function
                End If
                intArgIter = intArgIter + 1

            Case "/m"
                If Not blnGetArg("Max", intMax, intArgIter) Then
                    intParseCmdLine = CONST_ERROR
                    Exit Function
                End If
                intArgIter = intArgIter + 1

            Case "/z"
                If Not blnGetArg("Min", intMin, intArgIter) Then
                    intParseCmdLine = CONST_ERROR
                    Exit Function
                End If
                intArgIter = intArgIter + 1

            Case "/b"
                blnReboot = True
                intArgIter = intArgIter + 1

            Case "/f"
                blnforce = True
                intArgIter = intArgIter + 1

            Case Else 'We shouldn't get here
                Call Wscript.Echo("Invalid or misplaced parameter: " _
                   & Wscript.arguments.Item(intArgIter) & vbCRLF _
                   & "Please check the input and try again," & vbCRLF _
                   & "or invoke with '/?' for help with the syntax.")
                Wscript.Quit

        End Select

    Loop '** intArgIter <= Wscript.arguments.Count - 1

    If IsEmpty(intParseCmdLine) Then 
        intParseCmdLine = CONST_LIST
    End If
    If intParseCmdLine = CONST_RESIZE then
        If IsEmpty(intMax) then            
            intParseCmdLine = CONST_ERROR
            Wscript.Echo ("Missing required argurments.")
            Exit Function
        ElseIf IsEmpty(intMin) then
            intParseCmdLine = CONST_ERROR
            Wscript.Echo ("Missing required argurments.")
            Exit Function
        End If
        if intMin > intMax then
            Wscript.Echo ("The minimum pagefile size must be equal to or less than the maximum")
            Wscript.echo ("pagefile size.")
            intParseCmdLine = CONST_ERROR
            Exit Function
        End if
    End If
    
End Function

'********************************************************************
'*
'* Sub ShowUsage()
'*
'* Purpose: Shows the correct usage to the user.
'*
'* Input:   None
'*
'* Output:  Help messages are displayed on screen.
'*
'********************************************************************
Private Sub ShowUsage()

    Wscript.Echo ""
    Wscript.Echo "Controls Pagefiles on a machine."
    Wscript.Echo ""
    Wscript.Echo "SYNTAX:"
    Wscript.Echo "1.  PageFile.vbs /L [/S <server>] [/U <username>]"
    Wscript.Echo "                [/W <password>] [/O <outputfile>]"
    Wscript.Echo ""
    Wscript.Echo "2.  PageFile.vbs /R /M <maxsize> /Z <minsize> /P " _
               & "<pagefile> [/B] [/F]"
    Wscript.Echo "                [/S <server>] [/U <username>] [/W <password>]"
    Wscript.Echo "                [/O <outputfile>]"
    Wscript.Echo ""
    Wscript.Echo "PARAMETER SPECIFIERS:"
    Wscript.Echo "   /L            List page file data."
    Wscript.Echo "   /R            Change the pafe file size."
    Wscript.Echo "   /B            Reboot."
    Wscript.Echo "   /F            Force Reboot."
    Wscript.Echo "   pagefile      The target pagefile name."
    Wscript.Echo "   maxsize       The largest size the pagefile can grow."
    Wscript.Echo "   minsize       The minimum size of the pagefile."
    Wscript.Echo "   server        A machine name."
    Wscript.Echo "   username      The current user's name."
    Wscript.Echo "   password      Password of the current user."
    Wscript.Echo "   outputfile    The output file name."
    Wscript.Echo ""
    Wscript.Echo "EXAMPLE:"
    Wscript.Echo "1. cscript PageFile.vbs /L"
    Wscript.Echo "   Get the pagefile data for the current machine."
    Wscript.Echo "2. cscript PageFile.vbs /R /M 150 /Z 100 /p " _
               & "c:\pagefile.sys /S MyMachine2"
    Wscript.Echo "   Change the pagefile size on machine MyMachine2."

End Sub

'********************************************************************
'* General Routines
'********************************************************************

'********************************************************************
'*  Function: strDoubleBackSlashes (strIn)
'*
'*  Purpose:  expand path string to use double node-delimiters;
'*            doubles ALL backslashes.
'*
'*  Input:    strIn    path to file or directory
'*  Output:            WMI query-food
'*
'*  eg:      c:\pagefile.sys     becomes   c:\\pagefile.sys
'*  but:     \\server\share\     becomes   \\\\server\\share\\
'*
'********************************************************************
Private Function strDoubleBackSlashes (strIn)
    Dim i, str, strC
    str = ""
    for i = 1 to len (strIn)
        strC = Mid (strIn, i, 1)
        str = str & strC
        if strC = "\" then str = str & strC
    next
    strDoubleBackSlashes = str
End Function

'********************************************************************
'*
'* Function strFormatMOFTime(strDate)
'*
'* Purpose: Formats the date in WBEM to a readable Date
'*
'* Input:   blnB    A WBEM Date
'*
'* Output:  a string 
'*
'********************************************************************

Private Function strFormatMOFTime(strDate)
	Dim str
	str = Mid(strDate,1,4) & "-" _
           & Mid(strDate,5,2) & "-" _
           & Mid(strDate,7,2) & ", " _
           & Mid(strDate,9,2) & ":" _
           & Mid(strDate,11,2) & ":" _
           & Mid(strDate,13,2)
	strFormatMOFTime = str
End Function

'********************************************************************
'*
'* Function strPackString()
'*
'* Purpose: Attaches spaces to a string to increase the length to intWidth.
'*
'* Input:   strString   a string
'*          intWidth    the intended length of the string
'*          blnAfter    Should spaces be added after the string?
'*          blnTruncate specifies whether to truncate the string or not if
'*                      the string length is longer than intWidth
'*
'* Output:  strPackString is returned as the packed string.
'*
'********************************************************************
Private Function strPackString( ByVal strString, _
                                ByVal intWidth,  _
                                ByVal blnAfter,  _
                                ByVal blnTruncate)

    ON ERROR RESUME NEXT

    intWidth      = CInt(intWidth)
    blnAfter      = CBool(blnAfter)
    blnTruncate   = CBool(blnTruncate)

    If Err.Number Then
        Call Wscript.Echo ("Argument type is incorrect!")
        Err.Clear
        Wscript.Quit
    End If

    If IsNull(strString) Then
        strPackString = "null" & Space(intWidth-4)
        Exit Function
    End If

    strString = CStr(strString)
    If Err.Number Then
        Call Wscript.Echo ("Argument type is incorrect!")
        Err.Clear
        Wscript.Quit
    End If

    If intWidth > Len(strString) Then
        If blnAfter Then
            strPackString = strString & Space(intWidth-Len(strString))
        Else
            strPackString = Space(intWidth-Len(strString)) & strString & " "
        End If
    Else
        If blnTruncate Then
            strPackString = Left(strString, intWidth-1) & " "
        Else
            strPackString = strString & " "
        End If
    End If

End Function

'********************************************************************
'* 
'*  Function blnGetArg()
'*
'*  Purpose: Helper to intParseCmdLine()
'* 
'*  Usage:
'*
'*     Case "/s" 
'*       blnGetArg ("server name", strServer, intArgIter)
'*
'********************************************************************
Private Function blnGetArg ( ByVal StrVarName,   _
                             ByRef strVar,       _
                             ByRef intArgIter) 

    blnGetArg = False 'failure, changed to True upon successful completion

    If Len(Wscript.Arguments(intArgIter)) > 2 then
        If Mid(Wscript.Arguments(intArgIter),3,1) = ":" then
            If Len(Wscript.Arguments(intArgIter)) > 3 then
                strVar = Right(Wscript.Arguments(intArgIter), _
                         Len(Wscript.Arguments(intArgIter)) - 3)
                blnGetArg = True
                Exit Function
            Else
                intArgIter = intArgIter + 1
                If intArgIter > (Wscript.Arguments.Count - 1) Then
                    Call Wscript.Echo( "Invalid " & StrVarName & ".")
                    Call Wscript.Echo( "Please check the input and try again.")
                    Exit Function
                End If

                strVar = Wscript.Arguments.Item(intArgIter)
                If Err.Number Then
                    Call Wscript.Echo( "Invalid " & StrVarName & ".")
                    Call Wscript.Echo( "Please check the input and try again.")
                    Exit Function
                End If

                If InStr(strVar, "/") Then
                    Call Wscript.Echo( "Invalid " & StrVarName)
                    Call Wscript.Echo( "Please check the input and try again.")
                    Exit Function
                End If

                blnGetArg = True 'success
            End If
        Else
            strVar = Right(Wscript.Arguments(intArgIter), _
                     Len(Wscript.Arguments(intArgIter)) - 2)
            blnGetArg = True 'success
            Exit Function
        End If
    Else
        intArgIter = intArgIter + 1
        If intArgIter > (Wscript.Arguments.Count - 1) Then
            Call Wscript.Echo( "Invalid " & StrVarName & ".")
            Call Wscript.Echo( "Please check the input and try again.")
            Exit Function
        End If

        strVar = Wscript.Arguments.Item(intArgIter)
        If Err.Number Then
            Call Wscript.Echo( "Invalid " & StrVarName & ".")
            Call Wscript.Echo( "Please check the input and try again.")
            Exit Function
        End If

        If InStr(strVar, "/") Then
            Call Wscript.Echo( "Invalid " & StrVarName)
            Call Wscript.Echo( "Please check the input and try again.")
            Exit Function
        End If
        blnGetArg = True 'success
    End If
End Function

'********************************************************************
'*
'* Function blnConnect()
'*
'* Purpose: Connects to machine strServer.
'*
'* Input:   strServer       a machine name
'*          strNameSpace    a namespace
'*          strUserName     name of the current user
'*          strPassword     password of the current user
'*
'* Output:  objService is returned  as a service object.
'*          strServer is set to local host if left unspecified
'*
'********************************************************************
Private Function blnConnect(ByVal strNameSpace, _
                            ByVal strUserName,  _
                            ByVal strPassword,  _
                            ByRef strServer,    _
                            ByRef objService)

    ON ERROR RESUME NEXT

    Dim objLocator, objWshNet

    blnConnect = False     'There is no error.

    'Create Locator object to connect to remote CIM object manager
    Set objLocator = CreateObject("WbemScripting.SWbemLocator")
    If Err.Number then
        Call Wscript.Echo( "Error 0x" & CStr(Hex(Err.Number)) & _
                           " occurred in creating a locator object." )
        If Err.Description <> "" Then
            Call Wscript.Echo( "Error description: " & Err.Description & "." )
        End If
        Err.Clear
        blnConnect = True     'An error occurred
        Exit Function
    End If

    'Connect to the namespace which is either local or remote
    Set objService = objLocator.ConnectServer (strServer, strNameSpace, _
       strUserName, strPassword)
    ObjService.Security_.impersonationlevel = 3
    If Err.Number then
        Call Wscript.Echo( "Error 0x" & CStr(Hex(Err.Number)) & _
                           " occurred in connecting to server " _
           & strServer & ".")
        If Err.Description <> "" Then
            Call Wscript.Echo( "Error description: " & Err.Description & "." )
        End If
        Err.Clear
        blnConnect = True     'An error occurred
    End If

    'Get the current server's name if left unspecified
    If IsEmpty(strServer) Then
        Set objWshNet = CreateObject("Wscript.Network")
    strServer     = objWshNet.ComputerName
    End If

End Function

'********************************************************************
'*
'* Sub      VerifyHostIsCscript()
'*
'* Purpose: Determines which program is used to run this script.
'*
'* Input:   None
'*
'* Output:  If host is not cscript, then an error message is printed 
'*          and the script is aborted.
'*
'********************************************************************
Sub VerifyHostIsCscript()

    ON ERROR RESUME NEXT

    Dim strFullName, strCommand, i, j, intStatus

    strFullName = WScript.FullName

    If Err.Number then
        Call Wscript.Echo( "Error 0x" & CStr(Hex(Err.Number)) & " occurred." )
        If Err.Description <> "" Then
            Call Wscript.Echo( "Error description: " & Err.Description & "." )
        End If
        intStatus =  CONST_ERROR
    End If

    i = InStr(1, strFullName, ".exe", 1)
    If i = 0 Then
        intStatus =  CONST_ERROR
    Else
        j = InStrRev(strFullName, "\", i, 1)
        If j = 0 Then
            intStatus =  CONST_ERROR
        Else
            strCommand = Mid(strFullName, j+1, i-j-1)
            Select Case LCase(strCommand)
                Case "cscript"
                    intStatus = CONST_CSCRIPT
                Case "wscript"
                    intStatus = CONST_WSCRIPT
                Case Else       'should never happen
                    Call Wscript.Echo( "An unexpected program was used to " _
                                       & "run this script." )
                    Call Wscript.Echo( "Only CScript.Exe or WScript.Exe can " _
                                       & "be used to run this script." )
                    intStatus = CONST_ERROR
                End Select
        End If
    End If

    If intStatus <> CONST_CSCRIPT Then
        Call WScript.Echo( "Please run this script using CScript." & vbCRLF & _
             "This can be achieved by" & vbCRLF & _
             "1. Using ""CScript Pagefile.vbs arguments"" for Windows 95/98 or" _
             & vbCRLF & "2. Changing the default Windows Scripting Host " _
             & "setting to CScript" & vbCRLF & "    using ""CScript " _
             & "//H:CScript //S"" and running the script using" & vbCRLF & _
             "    ""Pagefile.vbs arguments"" for Windows NT/2000." )
        WScript.Quit
    End If

End Sub

'********************************************************************
'*
'* Sub WriteLine()
'* Purpose: Writes a text line either to a file or on screen.
'* Input:   strMessage  the string to print
'*          objFile     an output file object
'* Output:  strMessage is either displayed on screen or written to a file.
'*
'********************************************************************
Sub WriteLine(ByVal strMessage, ByVal objFile)

    On Error Resume Next
    If IsObject(objFile) then        'objFile should be a file object
        objFile.WriteLine strMessage
    Else
        Call Wscript.Echo( strMessage )
    End If

End Sub

'********************************************************************
'* 
'* Function blnErrorOccurred()
'*
'* Purpose: Reports error with a string saying what the error occurred in.
'*
'* Input:   strIn		string saying what the error occurred in.
'*
'* Output:  displayed on screen 
'* 
'********************************************************************
Private Function blnErrorOccurred (ByVal strIn)

    If Err.Number Then
        Call Wscript.Echo( "Error 0x" & CStr(Hex(Err.Number)) & ": " & strIn)
        If Err.Description <> "" Then
            Call Wscript.Echo( "Error description: " & Err.Description)
        End If
        Err.Clear
        blnErrorOccurred = True
    Else
        blnErrorOccurred = False
    End If

End Function

'********************************************************************
'* 
'* Function blnOpenFile
'*
'* Purpose: Opens a file.
'*
'* Input:   strFileName		A string with the name of the file.
'*
'* Output:  Sets objOpenFile to a FileSystemObject and setis it to 
'*            Nothing upon Failure.
'* 
'********************************************************************
Private Function blnOpenFile(ByVal strFileName, ByRef objOpenFile)

    ON ERROR RESUME NEXT

    Dim objFileSystem

    Set objFileSystem = Nothing

    If IsEmpty(strFileName) OR strFileName = "" Then
        blnOpenFile = False
        Set objOpenFile = Nothing
        Exit Function
    End If

    'Create a file object
    Set objFileSystem = CreateObject("Scripting.FileSystemObject")
    If blnErrorOccurred("Could not create filesystem object.") Then
        blnOpenFile = False
        Set objOpenFile = Nothing
        Exit Function
    End If

    'Open the file for output
    Set objOpenFile = objFileSystem.OpenTextFile(strFileName, 8, True)
    If blnErrorOccurred("Could not open") Then
        blnOpenFile = False
        Set objOpenFile = Nothing
        Exit Function
    End If
    blnOpenFile = True

End Function

'********************************************************************
'*                                                                  *
'*                           End of File                            *
'*                                                                  *
'********************************************************************