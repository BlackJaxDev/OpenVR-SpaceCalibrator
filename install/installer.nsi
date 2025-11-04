;--------------------------------
;Include Modern UI

	!include "MUI2.nsh"

;--------------------------------
;General

	!define OVERLAY_BASEDIR "..\client_overlay\bin\win64"
	!define DRIVER_RESDIR "..\OpenVR-SpaceCalibratorDriver\01spacecalibrator"

    Name "Nyautomator Space Calibrator"
    OutFile "NyautomatorSpaceCalibratorInstaller.exe"
    InstallDir "$PROGRAMFILES64\NyautomatorSpaceCalibrator"
    InstallDirRegKey HKLM "Software\NyautomatorSpaceCalibrator\Main" ""
	RequestExecutionLevel admin
	ShowInstDetails show
	
;--------------------------------
;Variables

VAR upgradeInstallation

;--------------------------------
;Interface Settings

	!define MUI_ABORTWARNING

;--------------------------------
;Pages

	!insertmacro MUI_PAGE_LICENSE "..\LICENSE"
	!define MUI_PAGE_CUSTOMFUNCTION_PRE dirPre
	!insertmacro MUI_PAGE_DIRECTORY
	!insertmacro MUI_PAGE_INSTFILES
  
	!insertmacro MUI_UNPAGE_CONFIRM
	!insertmacro MUI_UNPAGE_INSTFILES
  
;--------------------------------
;Languages
 
	!insertmacro MUI_LANGUAGE "English"

;--------------------------------
;Macros

;--------------------------------
;Functions

Function dirPre
	StrCmp $upgradeInstallation "true" 0 +2 
		Abort
FunctionEnd

Function .onInit
	StrCpy $upgradeInstallation "false"
 
	ReadRegStr $R0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\NyautomatorSpaceCalibrator" "UninstallString"
	StrCmp $R0 "" done
	
	
	; If SteamVR is already running, display a warning message and exit
	FindWindow $0 "Qt5QWindowIcon" "SteamVR Status"
	StrCmp $0 0 +3
		MessageBox MB_OK|MB_ICONEXCLAMATION \
			"SteamVR is still running. Cannot install this software.$\nPlease close SteamVR and try again."
		Abort
 
	
	MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION \
	"Nyautomator Space Calibrator is already installed. $\n$\nClick `OK` to upgrade the \
		existing installation or `Cancel` to cancel this upgrade." \
		IDOK upgrade
	Abort
 
	upgrade:
		StrCpy $upgradeInstallation "true"
	done:
FunctionEnd

;--------------------------------
;Installer Sections

Section "Install" SecInstall
	
	StrCmp $upgradeInstallation "true" 0 noupgrade 
		DetailPrint "Uninstall previous version..."
		ExecWait '"$INSTDIR\Uninstall.exe" /S _?=$INSTDIR'
		Delete $INSTDIR\Uninstall.exe
		Goto afterupgrade
		
	noupgrade:

	afterupgrade:

	SetOutPath "$INSTDIR"

	File "..\LICENSE"
	File "..\x64\Release\NyautomatorSpaceCalibrator.exe"
	File "..\lib\openvr\lib\win64\openvr_api.dll"
	File "..\OpenVR-SpaceCalibrator\manifest.vrmanifest"
	File "..\OpenVR-SpaceCalibrator\icon.png"

	ExecWait '"$INSTDIR\vcredist_x64.exe" /install /quiet'
	
	Var /GLOBAL vrRuntimePath
	nsExec::ExecToStack '"$INSTDIR\NyautomatorSpaceCalibrator.exe" -openvrpath'
	Pop $0
	Pop $vrRuntimePath
	DetailPrint "VR runtime path: $vrRuntimePath"
	
	; Old beta driver
	StrCmp $upgradeInstallation "true" 0 nocleanupbeta 
		Delete "$vrRuntimePath\drivers\000spacecalibrator\driver.vrdrivermanifest"
		Delete "$vrRuntimePath\drivers\000spacecalibrator\resources\driver.vrresources"
		Delete "$vrRuntimePath\drivers\000spacecalibrator\resources\settings\default.vrsettings"
		Delete "$vrRuntimePath\drivers\000spacecalibrator\bin\win64\driver_000spacecalibrator.dll"
		Delete "$vrRuntimePath\drivers\000spacecalibrator\bin\win64\space_calibrator_driver.log"
		RMdir "$vrRuntimePath\drivers\000spacecalibrator\resources\settings"
		RMdir "$vrRuntimePath\drivers\000spacecalibrator\resources\"
		RMdir "$vrRuntimePath\drivers\000spacecalibrator\bin\win64\"
		RMdir "$vrRuntimePath\drivers\000spacecalibrator\bin\"
		RMdir "$vrRuntimePath\drivers\000spacecalibrator\"
	nocleanupbeta:

	SetOutPath "$vrRuntimePath\drivers\nyautomator_spacecalibrator"
	File "${DRIVER_RESDIR}\driver.vrdrivermanifest"
	SetOutPath "$vrRuntimePath\drivers\nyautomator_spacecalibrator\resources"
	File "${DRIVER_RESDIR}\resources\driver.vrresources"
	SetOutPath "$vrRuntimePath\drivers\nyautomator_spacecalibrator\resources\settings"
	File "${DRIVER_RESDIR}\resources\settings\default.vrsettings"
	SetOutPath "$vrRuntimePath\drivers\nyautomator_spacecalibrator\bin\win64"
	File "..\x64\Release\driver_nyautomator_spacecalibrator.dll"
	
	WriteRegStr HKLM "Software\NyautomatorSpaceCalibrator\Main" "" $INSTDIR
	WriteRegStr HKLM "Software\NyautomatorSpaceCalibrator\Driver" "" $vrRuntimePath
  
	WriteUninstaller "$INSTDIR\Uninstall.exe"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\NyautomatorSpaceCalibrator" "DisplayName" "Nyautomator Space Calibrator"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\NyautomatorSpaceCalibrator" "UninstallString" "$\"$INSTDIR\Uninstall.exe$\""

	CreateShortCut "$SMPROGRAMS\NyautomatorSpaceCalibrator.lnk" "$INSTDIR\NyautomatorSpaceCalibrator.exe"
	
	SetOutPath "$INSTDIR"
	nsExec::ExecToLog '"$INSTDIR\NyautomatorSpaceCalibrator.exe" -installmanifest'
	nsExec::ExecToLog '"$INSTDIR\NyautomatorSpaceCalibrator.exe" -activatemultipledrivers'

SectionEnd

;--------------------------------
;Uninstaller Section

Section "Uninstall"
	; If SteamVR is already running, display a warning message and exit
	FindWindow $0 "Qt5QWindowIcon" "SteamVR Status"
	StrCmp $0 0 +3
		MessageBox MB_OK|MB_ICONEXCLAMATION \
			"SteamVR is still running. Cannot uninstall this software.$\nPlease close SteamVR and try again."
		Abort
	
	SetOutPath "$INSTDIR"
	nsExec::ExecToLog '"$INSTDIR\NyautomatorSpaceCalibrator.exe" -removemanifest'

	Var /GLOBAL vrRuntimePath2
	ReadRegStr $vrRuntimePath2 HKLM "Software\NyautomatorSpaceCalibrator\Driver" ""
	DetailPrint "VR runtime path: $vrRuntimePath2"
	Delete "$vrRuntimePath2\drivers\nyautomator_spacecalibrator\driver.vrdrivermanifest"
	Delete "$vrRuntimePath2\drivers\nyautomator_spacecalibrator\resources\driver.vrresources"
	Delete "$vrRuntimePath2\drivers\nyautomator_spacecalibrator\resources\settings\default.vrsettings"
	Delete "$vrRuntimePath2\drivers\nyautomator_spacecalibrator\bin\win64\driver_nyautomator_spacecalibrator.dll"
	Delete "$vrRuntimePath2\drivers\nyautomator_spacecalibrator\bin\win64\space_calibrator_driver.log"
	RMdir "$vrRuntimePath2\drivers\nyautomator_spacecalibrator\resources\settings"
	RMdir "$vrRuntimePath2\drivers\nyautomator_spacecalibrator\resources\"
	RMdir "$vrRuntimePath2\drivers\nyautomator_spacecalibrator\bin\win64\"
	RMdir "$vrRuntimePath2\drivers\nyautomator_spacecalibrator\bin\"
	RMdir "$vrRuntimePath2\drivers\nyautomator_spacecalibrator\"

	Delete "$INSTDIR\LICENSE"
	Delete "$INSTDIR\NyautomatorSpaceCalibrator.exe"
	Delete "$INSTDIR\openvr_api.dll"
	Delete "$INSTDIR\manifest.vrmanifest"
	Delete "$INSTDIR\icon.png"
	
	DeleteRegKey HKLM "Software\NyautomatorSpaceCalibrator\Main"
	DeleteRegKey HKLM "Software\NyautomatorSpaceCalibrator\Driver"
	DeleteRegKey HKLM "Software\NyautomatorSpaceCalibrator"
	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\NyautomatorSpaceCalibrator"

	Delete "$SMPROGRAMS\NyautomatorSpaceCalibrator.lnk"
SectionEnd

