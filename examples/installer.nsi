Unicode true
SetCompressor /SOLID lzma
RequestExecutionLevel user

!define UNINSTALL_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${IDENTIFIER}"

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
Section
    SetOutPath "$INSTDIR"
    File /r "${SOURCE}\*"
    File "${UNINSTALLER}"
    CreateShortCut "$SMPROGRAMS\${NAME}.lnk" "$INSTDIR\${NAME}.exe"
    WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayName" "${NAME}"
    WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayVersion" "${VERSION}"
    WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayIcon" "$INSTDIR\${NAME}.exe"
    WriteRegStr HKCU "${UNINSTALL_KEY}" "InstallLocation" "$INSTDIR"
    WriteRegStr HKCU "${UNINSTALL_KEY}" "UninstallString" '"$INSTDIR\uninstall.exe"'
    WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoModify" 1
    WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoRepair" 1
SectionEnd
!endif

Section "Uninstall"
    Delete "$SMPROGRAMS\${NAME}.lnk"
    DeleteRegKey HKCU "${UNINSTALL_KEY}"
    RMDir /r "$INSTDIR"
SectionEnd
