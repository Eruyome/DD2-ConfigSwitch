#SingleInstance force
#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Persistent ; Stay open in background
SetWorkingDir, %A_ScriptDir%
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.

#Include, %A_ScriptDir%\resources\Version.txt
#Include, %A_ScriptDir%\lib\JSON.ahk
#Include, %A_ScriptDir%\lib\DebugPrintArray.ahk
#Include, %A_ScriptDir%\lib\HotkeyGUI.ahk

MsgWrongAHKVersion := "AutoHotkey v" . AHKVersionRequired . " or later is needed to run this script. `n`nYou are using AutoHotkey v" . A_AhkVersion . " (installed at: " . A_AhkPath . ")`n`nPlease go to http://ahkscript.org to download the most recent version."
If (A_AhkVersion < AHKVersionRequired)
{
    MsgBox, 16, Wrong AutoHotkey Version, % MsgWrongAHKVersion
    ExitApp
}

Lib_RunAsAdmin()
If (!Lib_CreateTempFolder(A_ScriptDir, "DD2-ConfigSwitch")) {
	ExitApp
}
;StartSplashScreen()

class Globals {

	Set(name, value) {
		Globals[name] := value
	}

	Get(name, value_default="") {
		result := Globals[name]
		If (result == "") {
			result := value_default
		}
		return result
	}
}

Globals.Set("AHKVersionRequired", AHKVersionRequired)
Globals.Set("ReleaseVersion", ReleaseVersion)
Globals.Set("SettingsUIWidth", 545)
Globals.Set("SettingsUIHeight", 710)
Globals.Set("SettingsUITitle", "DD2-ConfigSwitch Settings")
Globals.Set("GithubRepo", "DD2-ConfigSwitch")
Globals.Set("GithubUser", "Eruyome")
Globals.Set("ScriptList", [A_ScriptDir "\DD2-ConfigSwitch"])
Globals.Set("UpdateNoteFileList", [[A_ScriptDir "\resources\updates.txt","DD2-ConfigSwitch"]])
Globals.Set("ProjectName", "DD2-ConfigSwitch")

global FilesToCopyToUserFolder	:= []
Loop %A_ScriptDir%\resources\config\*.*
{
	FilesToCopyToUserFolder[A_Index] := "\resources\config\" . A_LoopFileName
}

Globals.Set("overwrittenUserFiles", Lib_HandleUserSettings(Globals.Get("ProjectName"), A_MyDocuments, Globals.Get("ProjectName"), FilesToCopyToUserFolder, A_ScriptDir))
Globals.Set("isDevVersion", Lib_isDevelopmentVersion())
Globals.Set("userDirectory", A_MyDocuments . "\" . Globals.Get("ProjectName") . Globals.Get("isDevVersion"))

Lib_CompareUserFolderWithScriptFolder(Globals.Get("userDirectory"), A_ScriptDir, Globals.Get("ProjectName"))

global UserConfigFiles	:= []
userDir := Globals.Get("userDirectory")
Loop, %userDir%\*.ini
{
	;characters only
	If (InStr(A_LoopFileName, "char_", 0)) {
		UserConfigFiles[A_Index] := A_LoopFileName	
	}	
}

class UserOptions {
	ShowOverlay := 1	
	ShowUpdateNotifications := 0
	UpdateSkipSelection := 0
	UpdateSkipBackup := 0
	CharacterSlot1 := 
	CharacterSlot2 := 
	CharacterSlot3 := 
	CharacterSlot4 := 
	
	ScanUI()
	{
		this.ShowOverlay := GuiGet("ShowOverlay")
		this.ShowUpdateNotifications := GuiGet("ShowUpdateNotifications")
		this.UpdateSkipSelection := GuiGet("UpdateSkipSelection")
		this.UpdateSkipBackup := GuiGet("UpdateSkipBackup")
		this.CharacterSlot1 := GuiGet("CharacterSlot1")
		this.CharacterSlot2 := GuiGet("CharacterSlot2")
		this.CharacterSlot3 := GuiGet("CharacterSlot3")
		this.CharacterSlot4 := GuiGet("CharacterSlot4")
	}
}
Opts := new UserOptions()

class Fonts {

	Init(FontSizeFixed, FontSizeUI)
	{
		this.FontSizeFixed := FontSizeFixed
		this.FontSizeUI := FontSizeUI
		this.FixedFont := this.CreateFixedFont(FontSizeFixed)
		this.UIFont := this.CreateUIFont(FontSizeUI)
	}

	CreateFixedFont(FontSize_)
	{
		Options :=
		If (!(FontSize_ == ""))
		{
			Options = s%FontSize_%
		}
		Gui Font, %Options%, Courier New
		Gui Font, %Options%, Consolas
		Gui Add, Text, HwndHidden,
		SendMessage, 0x31,,,, ahk_id %Hidden%
		return ErrorLevel
	}

	CreateUIFont(FontSize_)
	{
		Options :=
		If (!(FontSize_ == ""))
		{
			Options = s%FontSize_%
		}
		Gui Font, %Options%, Tahoma
		Gui Font, %Options%, Segoe UI
		Gui Add, Text, HwndHidden,
		SendMessage, 0x31,,,, ahk_id %Hidden%
		return ErrorLevel
	}

	Set(NewFont)
	{
		AhkExe := GetAhkExeFilename()
		SendMessage, 0x30, NewFont, 1,, ahk_class tooltips_class32 ahk_exe %AhkExe%
		; Development versions of AHK
		SendMessage, 0x30, NewFont, 1,, ahk_class tooltips_class32 ahk_exe AutoHotkeyA32.exe
		SendMessage, 0x30, NewFont, 1,, ahk_class tooltips_class32 ahk_exe AutoHotkeyU32.exe
		SendMessage, 0x30, NewFont, 1,, ahk_class tooltips_class32 ahk_exe AutoHotkeyU64.exe
	}

	SetFixedFont(FontSize_=-1)
	{
		If (FontSize_ == -1)
		{
			FontSize_ := this.FontSizeFixed
		}
		Else
		{
			this.FontSizeFixed := FontSize_
			this.FixedFont := this.CreateFixedFont(FontSize_)
		}
		this.Set(this.FixedFont)
	}

	SetUIFont(FontSize_=-1)
	{
		If (FontSize_ == -1)
		{
			FontSize_ := this.FontSizeUI
		}
		Else
		{
			this.FontSizeUI := FontSize_
			this.UIFont := this.CreateUIFont(FontSize_)
		}
		this.Set(this.UIFont)
	}

	GetFixedFont()
	{
		return this.FixedFont
	}

	GetUIFont()
	{
		return this.UIFont
	}
}

IfNotExist, %userDirectory%\config.ini
{
	CopyDefaultConfig()
}

; Windows system tray icon
; set before creating the settings UI so it gets used for the settings dialog as well
;Menu, Tray, Icon, %A_ScriptDir%\resources\images\poe-bw.ico

ReadConfig()
Sleep, 100
ReadAllCharacters()
Sleep, 100

global firstUpdateCheck := true
If (!SkipItemInfoUpdateCall) {
	GoSub, CheckForUpdates
}
firstUpdateCheck := false

CreateSettingsUI()
If (StrLen(overwrittenUserFiles)) {
	ShowChangedUserFiles()
}

; Menu tooltip
RelVer := Globals.Get("ReleaseVersion")
Menu, Tray, Tip, DD2-ConfigSwitch %RelVer%

Menu, Tray, NoStandard
Menu, Tray, Add ; Separator
Menu, Tray, Add, % Globals.Get("SettingsUITitle", "DD2-ConfigSwitch Settings"), ShowSettingsUI
Menu, Tray, Add, Check for updates, CheckForUpdates
Menu, Tray, Add, Update Notes, ShowUpdateNotes
Menu, Tray, Add ; Separator
Menu, Tray, Add, Open User Folder, EditOpenUserSettings
Menu, Tray, Add ; Separator
Menu, Tray, Standard
Menu, Tray, Default, % Globals.Get("SettingsUITitle", "DD2-ConfigSwitch Settings")

OpenUserDirFile(Filename)
{
	Filepath := userDirectory . "\" . Filename
	IfExist, % Filepath
	{
		Run, % Filepath
	}
	Else
	{
		MsgBox, 16, Error, File not found.
		return
	}
	return

}

OpenUserSettingsFolder(ProjectName, Dir = "")
{	
	If (!StrLen(Dir)) {
		Dir := Globals.Get("userDirectory")
	}

	If (!InStr(FileExist(Dir), "D")) {
		FileCreateDir, %Dir%        
	}
	Run, Explorer %Dir%
	return
}

StartSplashScreen() {
    SplashTextOn, , 20, DD2-ConfigSwitch, Initializing...
}

AssignHotkey(Key, Label){
	Hotkey, %Key%, %Label%, UseErrorLevel
	If (ErrorLevel)	{
		If (errorlevel = 1)
			str := str . "`nASCII " . Key . " - 1) The Label parameter specifies a nonexistent label name."
		Else If (errorlevel = 2)
			str := str . "`nASCII " . Key . " - 2) The KeyName parameter specifies one or more keys that are either not recognized or not supported by the current keyboard layout/language. Switching to the english layout should solve this for now."
		Else If (errorlevel = 3)
			str := str . "`nASCII " . Key . " - 3) Unsupported prefix key. For example, using the mouse wheel as a prefix in a hotkey such as WheelDown & Enter is not supported."
		Else If (errorlevel = 4)
			str := str . "`nASCII " . Key . " - 4) The KeyName parameter is not suitable for use with the AltTab or ShiftAltTab actions. A combination of two keys is required. For example: RControl & RShift::AltTab."
		Else If (errorlevel = 5)
			str := str . "`nASCII " . Key . " - 5) The command attempted to modify a nonexistent hotkey."
		Else If (errorlevel = 6)
			str := str . "`nASCII " . Key . " - 6) The command attempted to modify a nonexistent variant of an existing hotkey. To solve this, use Hotkey IfWin to set the criteria to match those of the hotkey to be modified."
		Else If (errorlevel = 50)
			str := str . "`nASCII " . Key . " - 50) Windows 95/98/Me: The command completed successfully but the operating system refused to activate the hotkey. This is usually caused by the hotkey being "" ASCII " . int . " - in use"" by some other script or application (or the OS itself). This occurs only on Windows 95/98/Me because on other operating systems, the program will resort to the keyboard hook to override the refusal."
		Else If (errorlevel = 51)
			str := str . "`nASCII " . Key . " - 51) Windows 95/98/Me: The command completed successfully but the hotkey is not supported on Windows 95/98/Me. For example, mouse hotkeys and prefix hotkeys such as a & b are not supported."
		Else If (errorlevel = 98)
			str := str . "`nASCII " . Key . " - 98) Creating this hotkey would exceed the 1000-hotkey-per-script limit (however, each hotkey can have an unlimited number of variants, and there is no limit to the number of hotstrings)."
		Else If (errorlevel = 99)
			str := str . "`nASCII " . Key . " - 99) Out of memory. This is very rare and usually happens only when the operating system has become unstable."
		
		MsgBox, %str%
	}
}

AssignAllHotkeys() {
	;AssignHotkey(Opts.PriceCheckHotKey, "PriceCheck")	
}

GetDelimitedCharacterListString() {
	List := ""
	
	Loop, % UserConfigFiles.Length() {
		name := RegExReplace(UserConfigFiles[A_Index], "i)char_|.ini$")
		List .= name "|"
	}
	Return List
}

CreateSettingsUI()
{
	Global
	/*
	Loop, % 8 {
		%Name%_Ability_%A_Index% := ReadIniValue(ConfigPath, "Hotkeys", "Ability_" A_Index "_Hotkey", %Name%_Ability_%A_Index%)	
	}
	*/
	Files := UserConfigFiles
	Characters := []
	
	TabNames := "General|"
	Loop, % Files.Length() {
		name := RegExReplace(Files[A_Index], "i)char_|.ini$")
		Characters[A_Index] := name
		TabNames .= name "|"
	}
	
	StringTrimRight, TabNames, TabNames, 1
	PreSelect := 1
	Gui, Add, Tab3, Choose%PreSelect%, %TabNames%
	
	; General
	GuiAddGroupBox("General", "x20 y+15 w360 h340 Section")

	; Note: window handles (hwnd) are only needed if a UI tooltip should be attached.
	GuiAddCheckbox("Show Overlays", "xs10 ys20 w210 h30", Opts.ShowOverlay, "ShowOverlay", "ShowOverlayH")
	AddToolTip(ShowOverlayH, "Show Overlays.")
	GuiAddCheckbox("Update: Show Notifications", "xs10 yp+30 w210 h30", Opts.ShowUpdateNotifications, "ShowUpdateNotifications", "ShowUpdateNotificationsH")
	AddToolTip(ShowUpdateNotificationsH, "Notifies you when there's a new release available.")		
	GuiAddCheckbox("Update: Skip folder selection", "xs10 yp+30 w210 h30", Opts.UpdateSkipSelection, "UpdateSkipSelection", "UpdateSkipSelectionH")
	AddToolTip(UpdateSkipSelectionH, "Skips selecting an update location.`nThe current script directory will be used as default.")	
	GuiAddCheckbox("Update: Skip backup", "xs10 yp+30 w210 h30", Opts.UpdateSkipBackup, "UpdateSkipBackup", "UpdateSkipBackupH")
	AddToolTip(UpdateSkipBackupH, "Skips making a backup of the install location/folder.")
	
	CharList := GetDelimitedCharacterListString()
	GuiAddText("Character Slot 1:", "xs10 yp+40 w100 h20 0x0100", "LblCharacterSlot1", "LblCharacterSlot1H")
	AddToolTip(LblCharacterSlot1H, "Select config for Character Slot 1.")
	GuiAddDropDownList(CharList, "x+10 yp-4", Opts.CharacterSlot1, "CharacterSlot1", "CharacterSlot1H")
	
	GuiAddText("Character Slot 2:", "xs10 yp+30 w100 h20 0x0100", "LblCharacterSlot2", "LblCharacterSlot2H")
	AddToolTip(LblCharacterSlot2H, "Select config for Character Slot 2.")
	GuiAddDropDownList(CharList, "x+10 yp-4", Opts.CharacterSlot2, "CharacterSlot2", "CharacterSlot2H")
	
	GuiAddText("Character Slot 3:", "xs10 yp+30 w100 h20 0x0100", "LblCharacterSlot3", "LblCharacterSlot3H")
	GuiAddDropDownList(CharList, "x+10 yp-4", Opts.CharacterSlot3, "CharacterSlot3", "CharacterSlot3H")
	AddToolTip(LblCharacterSlot3H, "Select config for Character Slot 3.")
	
	GuiAddText("Character Slot 4:", "xs10 yp+30 w100 h20 0x0100", "LblCharacterSlot4", "LblCharacterSlot4H")
	AddToolTip(LblCharacterSlot4H, "Select config for Character Slot 4.")
	GuiAddDropDownList(CharList, "x+10 yp-4", Opts.CharacterSlot4, "CharacterSlot4", "CharacterSlot4H")

	
	NextTab := 2
	Gui, Tab, %NextTab%
	;Loop, % 1 {
	Loop, % Characters.Length() {
		;545
		name := Characters[A_Index]
		GuiAddGroupBox("Hotkeys", "x20 y+15 w360 h260 Section")
		
		Loop, % 8 {
			GuiAddEdit(%name%_Ability_%A_Index%, "x27 yp+28 w120 h20 ReadOnly", name "_Ability_" A_Index "", name "_Ability_" A_Index "H")			
			AddToolTip(%name%_Ability_%A_Index%H, "Press key/key combination.`nDefault: " A_Index "")	
			GuiAddButton("Select " name " Ability " A_Index "", "x+10 yp-1", "selectKey")		
		}
		
		NextTab := NextTab + 1
		Gui, Tab, %NextTab%
	}	
	
	Gui, Tab	
	
	GuiAddButton("Save", "x15 y460 w80 h23", "SettingsUI_BtnOk")
	GuiAddButton("Cancel", "x+5 yp+0 w80 h23", "SettingsUI_BtnCancel")
}

ShowSettingsUI()
{
	Fonts.SetUIFont(9)
	SettingsUIWidth := Globals.Get("SettingsUIWidth", 545)
	SettingsUIHeight := Globals.Get("SettingsUIHeight", 710)
	SettingsUITitle := Globals.Get("SettingsUITitle", Globals.Get("ProjectName") " Settings")
	Gui, Show, w%SettingsUIWidth% h%SettingsUIHeight%, %SettingsUITitle%
}

UpdateSettingsUI()
{
	Global

	GuiControl,, ShowOverlay, % Opts.ShowOverlay	
	GuiControl,, ShowUpdateNotifications, % Opts.ShowUpdateNotifications
	GuiControl,, UpdateSkipSelection, % Opts.UpdateSkipSelection
	GuiControl,, UpdateSkipBackup, % Opts.UpdateSkipBackup
	
	GuiControl,, CharacterSlot1, % Opts.CharacterSlot1
	GuiControl,, CharacterSlot2, % Opts.CharacterSlot2
	GuiControl,, CharacterSlot3, % Opts.CharacterSlot3
	GuiControl,, CharacterSlot4, % Opts.CharacterSlot4
}

ShowChangedUserFiles()
{
	Gui, ChangedUserFiles:Destroy
	
	Gui, ChangedUserFiles:Add, Text, , Following user files were changed in the last update and `nwere overwritten (old files were backed up):
	
	Loop, Parse, overwrittenUserFiles, `n
	{
		If (StrLen(A_Loopfield) > 0) {
			Gui, ChangedUserFiles:Add, Text, y+5, %A_LoopField%	
		}		
	}
	Gui, ChangedUserFiles:Add, Button, y+10 gChangedUserFilesWindow_Cancel, Close
	Gui, ChangedUserFiles:Add, Button, x+10 yp+0 gChangedUserFilesWindow_OpenFolder, Open user folder
	Gui, ChangedUserFiles:Show, w300, Changed User Files
	ControlFocus, Close, Changed User Files
}

ReadIniValue(iniFilePath, Section = "General", IniKey="", DefaultValue = "")
{
	IniRead, OutputVar, %iniFilePath%, %Section%, %IniKey%
	If (!OutputVar | RegExMatch(OutputVar, "^ERROR$")) { 
		OutputVar := DefaultValue
        ; Somehow reading some ini-values is not working with IniRead
        ; Fallback for these cases via FileReadLine 
		lastSection := ""        
		Loop {
			FileReadLine, line, %iniFilePath%, %A_Index%
			If ErrorLevel
				break
			
			l := StrLen(IniKey)
			NewStr := SubStr(Trim(line), 1 , l)
			RegExMatch(line, "i)\[(.*)\]", match)
			If (not InStr(line, ";") and match) {
				lastSection := match1
			}
			
			If (NewStr = IniKey and lastSection = Section) {
				RegExMatch(line, "= *(.*)", value)
				If (StrLen(value1) = 0) {
					OutputVar := DefaultValue                    
				}
				Else {
					OutputVar := value1
				}              
                ;MsgBox % "`n`n`n`n" lastSection ": " IniKey  " = " OutputVar 
			}
		}
	}   
	Return OutputVar
}

WriteIniValue(Val, TradeConfigPath, Section_, Key)
{
	IniWrite, %Val%, %TradeConfigPath%, %Section_%, %Key%
	if errorlevel
		msgbox error
}


ReadConfig(ConfigDir = "", ConfigFile = "config.ini")
{
	Global
	If (StrLen(ConfigDir) < 1) {
		ConfigDir := userDirectory
	}
	ConfigPath := StrLen(ConfigDir) > 0 ? ConfigDir . "\" . ConfigFile : ConfigFile

	IfExist, %ConfigPath%
	{
		; General
		Opts.ShowOverlay := ReadIniValue(ConfigPath, "General", "ShowOverlay", Opts.ShowOverlay)
		Opts.ShowUpdateNotifications := ReadIniValue(ConfigPath, "General", "ShowUpdateNotifications", Opts.ShowUpdateNotifications)
		Opts.UpdateSkipSelection := ReadIniValue(ConfigPath, "General", "UpdateSkipSelection", Opts.UpdateSkipSelection)
		Opts.UpdateSkipBackup := ReadIniValue(ConfigPath, "General", "UpdateSkipBackup", Opts.UpdateSkipBackup)
	}
}

ReadCharacter(ConfigFile, ConfigDir = "")
{
	Global
	If (StrLen(ConfigDir) < 1) {
		ConfigDir := Globals.Get("userDirectory")
	}
	ConfigPath := StrLen(ConfigDir) > 0 ? ConfigDir . "\char_" . ConfigFile . ".ini" : "char_" . ConfigFile . ".ini"
	
	IfExist, %ConfigPath%
	{
		Name := ConfigFile
		; Hotkeys
		Loop, % 8 {
			%Name%_Ability_%A_Index% := ReadIniValue(ConfigPath, "Hotkeys", "Ability_" A_Index "_Hotkey", %Name%_Ability_%A_Index%)	
		}
	}
}

ReadAllCharacters() {
	arr := UserConfigFiles
	Loop, % arr.MaxIndex() {
		If (InStr(arr[A_Index], "char_", 0) and InStr(arr[A_Index], ".ini", 0)) {			
			name := RegExReplace(arr[A_Index],  "i)char_")
			name := RegExReplace(name,  "i).ini$")
			ReadCharacter(name)
		}
	}
}

WriteConfig(ConfigDir = "", ConfigFile = "config.ini")
{
	Global
	If (StrLen(ConfigDir) < 1) {
		ConfigDir := Globals.Get("userDirectory")
	}
	ConfigPath := StrLen(ConfigDir) > 0 ? ConfigDir . "\" . ConfigFile : ConfigFile

	Opts.ScanUI()

	; General
	WriteIniValue(Opts.ShowOverlay, ConfigPath, "General", "ShowOverlay")
	WriteIniValue(Opts.ShowUpdateNotifications, ConfigPath, "General", "ShowUpdateNotifications")
	WriteIniValue(Opts.UpdateSkipSelection, ConfigPath, "General", "UpdateSkipSelection")
	WriteIniValue(Opts.UpdateSkipBackup, ConfigPath, "General", "UpdateSkipBackup")
}

WriteCharacter(ConfigFile, ConfigDir = "")
{
	Global
	If (StrLen(ConfigDir) < 1) {
		ConfigDir := Globals.Get("userDirectory")
	}
	ConfigPath := StrLen(ConfigDir) > 0 ? ConfigDir . "\char_" . ConfigFile . ".ini" : "char_" . ConfigFile . ".ini"

	;Opts.ScanUI()
	
	IfExist, %ConfigPath%
	{
		Name := ConfigFile
		; Hotkeys
		Loop, % 8 {
			WriteIniValue(%Name%_Ability_%A_Index%, ConfigPath, "Hotkeys", "Ability_" A_Index "_Hotkey")	
		}
	}
}

CopyDefaultConfig()
{
	userDirectory := Globals.Get("userDirectory")
	FileCopy, %A_ScriptDir%\resources\config\default_config.ini, %userDirectory%\config.ini
}

RemoveConfig()
{
	userDirectory := Globals.Get("userDirectory")
	FileDelete, %userDirectory%\config.ini
}

; ############ GUI #############
StrPrefix(s, prefix) {
	If (s == "") {
		return ""
	} Else {
		If (SubStr(s, 1, StrLen(prefix)) == prefix) {
			return s ; Nothing to do
		} Else {
			return prefix . s
		}
	}
}

GuiSet(ControlID, Param3="", SubCmd="")
{
	If (!(SubCmd == "")) {
		GuiControl, %SubCmd%, %ControlID%, %Param3%
	} Else {
		GuiControl,, %ControlID%, %Param3%
	}
}

GuiGet(ControlID, DefaultValue="")
{
	curVal =
	GuiControlGet, curVal,, %ControlID%, %DefaultValue%
	return curVal
}

GuiAdd(ControlType, Contents, PositionInfo, AssocVar="", AssocHwnd="", AssocLabel="", Param4="", GuiName="")
{
	Global
	Local av, ah, al
	av := StrPrefix(AssocVar, "v")
	al := StrPrefix(AssocLabel, "g")
	ah := StrPrefix(AssocHwnd, "hwnd")
	
	If (ControlType = "GroupBox") {
		Gui, Font, cDA4F49
		Options := Param4
	}
	Else {
		Options := Param4 . " BackgroundTrans "
	}		
	
	GuiName := (StrLen(GuiName) > 0) ? Trim(GuiName) . ":Add" : "Add"
	Gui, %GuiName%, %ControlType%, %PositionInfo% %av% %al% %ah% %Options%, %Contents%
	Gui, Font
}

GuiAddButton(Contents, PositionInfo, AssocLabel="", AssocVar="", AssocHwnd="", Options="", GuiName="")
{
	GuiAdd("Button", Contents, PositionInfo, AssocVar, AssocHwnd, AssocLabel, Options, GuiName)
}

GuiAddGroupBox(Contents, PositionInfo, AssocVar="", AssocHwnd="", AssocLabel="", Options="", GuiName="")
{
	GuiAdd("GroupBox", Contents, PositionInfo, AssocVar, AssocHwnd, AssocLabel, Options, GuiName)
}

GuiAddCheckbox(Contents, PositionInfo, CheckedState=0, AssocVar="", AssocHwnd="", AssocLabel="", Options="", GuiName="")
{
	GuiAdd("Checkbox", Contents, PositionInfo, AssocVar, AssocHwnd, AssocLabel, "Checked" . CheckedState . " " . Options, GuiName)
}

GuiAddText(Contents, PositionInfo, AssocVar="", AssocHwnd="", AssocLabel="", Options="", GuiName="")
{
	; static controls like Text need "0x0100" added to their options for the tooltip to work
	; either add it always here or don't forget to add it manually when using this function
	GuiAdd("Text", Contents, PositionInfo, AssocVar, AssocHwnd, AssocLabel, Options, GuiName)
}

GuiAddEdit(Contents, PositionInfo, AssocVar="", AssocHwnd="", AssocLabel="", Options="", GuiName="")
{
	GuiAdd("Edit", Contents, PositionInfo, AssocVar, AssocHwnd, AssocLabel, Options, GuiName)
}

GuiAddHotkey(Contents, PositionInfo, AssocVar="", AssocHwnd="", AssocLabel="", Options="", GuiName="")
{
	GuiAdd("Hotkey", Contents, PositionInfo, AssocVar, AssocHwnd, AssocLabel, Options, GuiName)
}

GuiAddDropDownList(Contents, PositionInfo, Selected="", AssocVar="", AssocHwnd="", AssocLabel="", Options="", GuiName="")
{
	; usage : add list items as a | delimited string, for example = "item1|item2|item3"
	ListItems := StrSplit(Contents, "|")
	Contents := ""
	Loop % ListItems.MaxIndex() {
		Contents .= Trim(ListItems[A_Index]) . "|"
		; add second | to mark pre-select list item
		If (Trim(ListItems[A_Index]) == Selected) {
			Contents .= "|"
		}
	}
	GuiAdd("DropDownList", Contents, PositionInfo, AssocVar, AssocHwnd, AssocLabel, Options, GuiName)
}

GuiUpdateDropdownList(Contents="", Selected="", AssocVar="", Options="", GuiName="") {
	GuiName := (StrLen(GuiName) > 0) ? Trim(GuiName) . ":" . AssocVar : "" . AssocVar
	
	If (StrLen(Contents) > 0) {
		; usage : add list items as a | delimited string, for example = "item1|item2|item3"
		ListItems := StrSplit(Contents, "|")
		; prepend the list with a pipe to re-create the list instead of appending it
		Contents := "|"
		Loop % ListItems.MaxIndex() {
			Contents .= Trim(ListItems[A_Index]) . "|"
			; add second | to mark pre-select list item
			If (Trim(ListItems[A_Index]) == Selected) {
				Contents .= "|"
			}
		}
		GuiControl, , %GuiName%, %Contents%
	}
	
	If (StrLen(Selected)) > 0 {
		; falls back to "ChooseString" if param3 is not an integer
		GuiControl, Choose, %GuiName% , %Selected%  	
	}	
}

AddToolTip(con, text, Modify=0){
	Static TThwnd, GuiHwnd
	TInfo =
	UInt := "UInt"
	Ptr := (A_PtrSize ? "Ptr" : UInt)
	PtrSize := (A_PtrSize ? A_PtrSize : 4)
	Str := "Str"
	; defines from Windows MFC commctrl.h
	WM_USER := 0x400
	TTM_ADDTOOL := (A_IsUnicode ? WM_USER+50 : WM_USER+4)           ; used to add a tool, and assign it to a control
	TTM_UPDATETIPTEXT := (A_IsUnicode ? WM_USER+57 : WM_USER+12)    ; used to adjust the text of a tip
	TTM_SETMAXTIPWIDTH := WM_USER+24                                ; allows the use of multiline tooltips
	TTF_IDISHWND := 1
	TTF_CENTERTIP := 2
	TTF_RTLREADING := 4
	TTF_SUBCLASS := 16
	TTF_TRACK := 0x0020
	TTF_ABSOLUTE := 0x0080
	TTF_TRANSPARENT := 0x0100
	TTF_PARSELINKS := 0x1000
	If (!TThwnd) {
		Gui, +LastFound
		GuiHwnd := WinExist()
		TThwnd := DllCall("CreateWindowEx"
					,UInt,0
					,Str,"tooltips_class32"
					,UInt,0
					,UInt,2147483648
					,UInt,-2147483648
					,UInt,-2147483648
					,UInt,-2147483648
					,UInt,-2147483648
					,UInt,GuiHwnd
					,UInt,0
					,UInt,0
					,UInt,0)
	}
	; TOOLINFO structure
	cbSize := 6*4+6*PtrSize
	uFlags := TTF_IDISHWND|TTF_SUBCLASS|TTF_PARSELINKS
	VarSetCapacity(TInfo, cbSize, 0)
	NumPut(cbSize, TInfo)
	NumPut(uFlags, TInfo, 4)
	NumPut(GuiHwnd, TInfo, 8)
	NumPut(con, TInfo, 8+PtrSize)
	NumPut(&text, TInfo, 6*4+3*PtrSize)
	NumPut(0,TInfo, 6*4+6*PtrSize)
	DetectHiddenWindows, On
	If (!Modify) {
		DllCall("SendMessage"
			,Ptr,TThwnd
			,UInt,TTM_ADDTOOL
			,Ptr,0
			,Ptr,&TInfo
			,Ptr)
		DllCall("SendMessage"
			,Ptr,TThwnd
			,UInt,TTM_SETMAXTIPWIDTH
			,Ptr,0
			,Ptr,A_ScreenWidth)
	}
	DllCall("SendMessage"
		,Ptr,TThwnd
		,UInt,TTM_UPDATETIPTEXT
		,Ptr,0
		,Ptr,&TInfo
		,Ptr)

}

GetScreenInfo()
{
	SysGet, TotalScreenWidth, 78
	SysGet, TotalscreenHeight, 79
	SysGet, MonitorCount, 80

	Globals.Set("MonitorCount", MonitorCount)
	Globals.Set("TotalScreenWidth", TotalScreenWidth)
	Globals.Set("TotalScreenHeight", TotalscreenHeight)
}

ShowUpdateNotes()
{
	Gui, UpdateNotes:Destroy
	Fonts.SetUIFont(9)

	Files := Globals.Get("UpdateNoteFileList")
	
	TabNames := ""
	Loop, % Files.Length() {
		name := Files[A_Index][2]
		TabNames .= name "|"
	}
	
	StringTrimRight, TabNames, TabNames, 1
	PreSelect := Files.Length()
	Gui, UpdateNotes:Add, Tab3, Choose%PreSelect%, %TabNames%
	
	Loop, % Files.Length() {
		file := Files[A_Index][1]
		FileRead, notes, %file%
		Gui, UpdateNotes:Add, Edit, r50 ReadOnly w700 BackgroundTrans, %notes%		
		
		NextTab := A_Index + 1
		Gui, UpdateNotes:Tab, %NextTab%
	}
	Gui, UpdateNotes:Tab	
	
	SettingsUIWidth := 745
	SettingsUIHeight := 710
	SettingsUITitle := "Update Notes"
	Gui, UpdateNotes:Show, w%SettingsUIWidth% h%SettingsUIHeight%, %SettingsUITitle%
}

GetAhkExeFilename(Default_="AutoHotkey.exe")
{
	AhkExeFilename := Default_
	If (A_AhkPath)
	{
		StringSplit, AhkPathParts, A_AhkPath, \
		Loop, % AhkPathParts0
		{
			IfInString, AhkPathParts%A_Index%, .exe
			{
				AhkExeFilename := AhkPathParts%A_Index%
				Break
			}
		}
	}
	return AhkExeFilename
}

CloseScripts() {
	; Close all active scripts listed in Globals.Get("ScriptList").
	
	scripts := Globals.Get("ScriptList")	
	currentScript := A_ScriptDir . "\" . A_ScriptName
	SplitPath, currentScript, , , ext, currentscript_name_no_ext
	currentScript :=  A_ScriptDir . "\" . currentscript_name_no_ext
	
	DetectHiddenWindows, On 

	Loop, % scripts.Length() {
		scriptPath := scripts[A_Index]
	
		; close current script last (with ExitApp)
		If (currentScript != scriptPath) {
			WinClose, %scriptPath% ahk_class AutoHotkey
		}
	}
	ExitApp
}

DummyRoutine:
	; first subroutine gets called automatically,  not sure why,  too lazy to look it up
Return

ShowUpdateNotes:
	ShowUpdateNotes()
Return

ChangedUserFilesWindow_Cancel:
	Gui, ChangedUserFiles:Cancel
Return

ChangedUserFilesWindow_OpenFolder:
	Gui, ChangedUserFiles:Cancel
	GoSub, EditOpenUserSettings
Return

ShowSettingsUI:
	ReadConfig()
	Sleep, 50
	UpdateSettingsUI()
	Sleep, 50
	ShowSettingsUI()
Return

SettingsUI_BtnOK:
	Global Opts
	Gui, Submit
	Sleep, 50
	WriteConfig()
	;UpdateSettingsUI()
	Fonts.SetFixedFont(10)
Return

SettingsUI_BtnCancel:
	Gui, Cancel
Return

SettingsUI_BtnDefaults:
	Gui, Cancel
	RemoveConfig()
	Sleep, 75
	CopyDefaultConfig()
	Sleep, 75
	ReadConfig()
	Sleep, 75
	Gui, Destroy
	CreateSettingsUI()
	;UpdateSettingsUI()
	ShowSettingsUI()
Return

SelectKey:
	RegExMatch(A_GuiControl, "i)select(.*)ability(.*)", match)
	cName	:= Trim(match1)
	number	:= Trim(match2)
	
	key := %cName%_Ability_%number%

	Hotkey := HotkeyGUI(p_Owner = "", p_Hotkey = %key%, p_Limit = 0, p_OptionalAttrib = False, p_Title = "Select Hotkey")
	GuiControl, , %cName%_Ability_%number%, % Hotkey
	%cName%_Ability_%number% := Hotkey
	Gui, Submit, NoHide
Return

EditOpenUserSettings:
    OpenUserSettingsFolder(Globals.Get("ProjectName"))
Return

CheckForUpdates:
	If (not globalUpdateInfo.repo) {
		global globalUpdateInfo := {}
	}
	If (not SkipItemInfoUpdateCall) {
		globalUpdateInfo.repo := Globals.Get("GithubRepo")
		globalUpdateInfo.user := Globals.Get("GithubUser")
		globalUpdateInfo.releaseVersion	:= Globals.Get("ReleaseVersion")
		globalUpdateInfo.skipSelection	:= Opts.UpdateSkipSelection
		globalUpdateInfo.skipBackup		:= Opts.UpdateSkipBackup
		globalUpdateInfo.skipUpdateCheck	:= Opts.ShowUpdateNotifications
		SplashScreenTitle := "DD2-ConfigSwitch"
	}
	
	hasUpdate := Lib_Update(globalUpdateInfo.user, globalUpdateInfo.repo, globalUpdateInfo.releaseVersion, globalUpdateInfo.skipUpdateCheck, userDirectory, isDevVersion, globalUpdateInfo.skipSelection, globalUpdateInfo.skipBackup)
	If (hasUpdate = "no update" and not firstUpdateCheck) {
		SplashTextOn, , , No update available
		Sleep 2000
		SplashTextOff
	}
Return