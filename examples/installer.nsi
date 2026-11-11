Unicode true
SetCompressor /SOLID lzma
RequestExecutionLevel user

!define UNINSTALL_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${IDENTIFIER}"
!define MARKER ".xiao-install"

Name "${NAME}"
InstallDir "$LOCALAPPDATA\${NAME}"

!ifdef UNINSTALLER_OUT
OutFile "${WRITER}"
Function .onInit
    WriteUninstaller "${UNINSTALLER_OUT}"
    Quit
FunctionEnd
Section
SectionEnd
!else
OutFile "${OUTFILE}"

Function PrepareFolder
    IfFileExists "$INSTDIR\${MARKER}" upgrade
    ClearErrors
    FindFirst $0 $1 "$INSTDIR\*"
    IfErrors done
    scan:
        StrCmp $1 "" free
        StrCmp $1 "." next
        StrCmp $1 ".." next
        FindClose $0
        MessageBox MB_ICONSTOP "$INSTDIR already holds other files. Choose an empty folder." /SD IDOK
        Abort
    next:
        FindNext $0 $1
        Goto scan
    free:
        FindClose $0
        Goto done
    upgrade:
        RMDir /r "$INSTDIR"
    done:
FunctionEnd

Section
    Call PrepareFolder
    SetOutPath "$INSTDIR"
    FileOpen $0 "$INSTDIR\${MARKER}" w
    FileClose $0
    File /r "${SOURCE}\*"
    File "${UNINSTALLER}"
    CreateShortCut "$SMPROGRAMS\${NAME}.lnk" "$INSTDIR\${EXE}.exe"
    WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayName" "${NAME}"
    WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayVersion" "${VERSION}"
    WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayIcon" "$INSTDIR\${EXE}.exe"
    WriteRegStr HKCU "${UNINSTALL_KEY}" "InstallLocation" "$INSTDIR"
    WriteRegStr HKCU "${UNINSTALL_KEY}" "UninstallString" '"$INSTDIR\uninstall.exe"'
    WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoModify" 1
    WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoRepair" 1
SectionEnd
!endif

Section "Uninstall"
    IfFileExists "$INSTDIR\${MARKER}" owned
    MessageBox MB_ICONSTOP "$INSTDIR was not created by the ${NAME} installer, nothing was removed." /SD IDOK
    Abort
    owned:
    Delete "$SMPROGRAMS\${NAME}.lnk"
    DeleteRegKey HKCU "${UNINSTALL_KEY}"
    RMDir /r "$INSTDIR"
SectionEnd
