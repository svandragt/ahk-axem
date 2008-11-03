; Axem (AutoHotkey Script Manager -AHKSM)
; Language:       English
;
; Synopsis: test
; scrollable gui code by Lexikos
; http://www.autohotkey.com/forum/viewtopic.php?p=177673#177673

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
DetectHiddenWindows On  ; Allows a script's hidden main window to be detected.	
SetTitleMatchMode 2  ; Avoids the need to specify the full path of the file below.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

functions()

IgnoreSelf = 0
IniFile = settings.ini
RegRead, Editor, HKEY_CLASSES_ROOT, AutoHotkeyScript\Shell\Edit\Command
If ErrorLevel
	Editor = notepad.exe
Else
	StringTrimRight, Editor, Editor, 3
ScanFolder =
LongFileList =
PathList = 
FileList = 
RunningScripts = 


Menu, tray, NoStandard
Menu, tray, Add, Show Axem,ButtonRescan
Menu, tray, Add,
Menu, tray, Standard
Menu, tray, Default, Show Axem
Gosub,READINI
GoSub, ShowWindow
GoSub, Wait



ShowWindow:
; Create the ListView with two columns, Name and Size:

	Gui Destroy
	Loaded=0
	Gui, +Resize
	Gui, Add, Text,, Scripts found in %ScanFolder%:
	winget,ls,list,AutoHotkey ahk_class AutoHotkey
	
	Gui, Add, ListView, r20 w740 Count20 Checked AltSubmit gMyListView vMyListView, Script|Synopsis
	GuiControl, -Redraw, MyListView
	Loop, %ScanFolder%\*.ahk, , 1  ; Recurse into subfolders.
	{
		Counter := A_Index

		LongFileList = %LongFileList%%A_LoopFileLongPath%`n
		PathList = %PathList%%A_LoopFileDir%`n
	  FileList = %FileList%%A_LoopFileName%`n
		If IgnoreSelf 
			If A_LoopFileLongPath = %A_ScriptFullPath% ; ignore own script
				continue
		FolderLen := StrLen(ScanFolder)+2
		EntryTitle := SubStr(A_LoopFileLongPath, FolderLen)

		%Counter%active=0		
		DisplayCheckbox = 
		Loop,%ls%
		{
			RunningScript := Regexreplace(Wingettitle("ahk_id " ls%a_index%),".*\\(.*)-.*","$1")
			StringTrimRight, RunningScript, RunningScript, 1
			File := GetValue(FileList,Counter)
			If File = %RunningScript%
			{
				DisplayCheckbox = Check
				%Counter%active=1
			}
		}
		FileReadLine, line, %A_LoopFileLongPath%, 1
		if ErrorLevel
				break
		if Substr(line,1,1) = ";" 
			synopsis := Substr(line,2)

		LV_Add(DisplayCheckbox, EntryTitle,synopsis)
	}
	LV_ModifyCol()  ; Auto-size each column to fit its contents.
	Loaded=1
	GuiControl, +Redraw, MyListView
	
	Gui, Add, Button, Section xs, &Rescan
	Gui, Add, Button, ys, &Change Folder
	Gui, Add, Button, ys Default, &Hide
	 
	Menu, FileMenu, Add, &Open    Ctrl+O, ButtonChangeFolder  ; See remarks below about Ctrl+O.
	Menu, FileMenu, Add, E&xit, MenuExit
	Menu, HelpMenu, Add, &Support    F1, MenuOnline
	Menu, ViewMenu, Add, &Reload    Ctrl+R, ButtonRescan  ; See remarks below about Ctrl+O.
	Menu, MyMenuBar, Add, &File, :FileMenu  ; Attach the two sub-menus that were created above.
	Menu, MyMenuBar, Add, &View, :ViewMenu
	Menu, MyMenuBar, Add, &Help, :HelpMenu
	Gui, Menu, MyMenuBar
	 
	Gui, Show,W760 H440 Center,Axem - AutoHotKey Scripts Manager
return

; The following part is needed only if the script will be run on Windows 95/98/Me:
#IfWinActive
$^o::Send ^o
MenuOnline:
	SupportUrl = http://www.donationcoder.com/Forums/bb/index.php?topic=15482.0
	msgbox,4,Visit Online Support,Support on Axem is given via the Donationcoder.com community forums. Do you want to load the following webpage?`n`n%SupportUrl%
	IfMsgBox Yes
    Run, %supporturl%
return

MenuExit:
ExitApp
return

MyListView:
if A_GuiEvent = DoubleClick
{
    LV_GetText(RowText, A_EventInfo)  ; Get the text from the row's first field.
		If %A_EventInfo%active=1
		{
			LV_Modify(A_EventInfo,"-Check")
			%A_EventInfo%active=0
			GoSub, StartStopScript
			}
		Else
		{
			%A_EventInfo%active=1
			LV_Modify(A_EventInfo, "Check")  ; Uncheck all the checkboxes.
			GoSub, StartStopScript
		}
} 
else if A_GuiEvent = RightClick
{
    LV_GetText(RowText, A_EventInfo)  ; Get the text from the row's first field.
		LastRightClicked := A_EventInfo
		Menu,Options,Add,Edit,EditFile
		Menu,Options,Add,Show Folder,ShowFolder
    Menu,Options,Show
		
} 
else if A_GuiEvent = I
{
	If Loaded=1 
	{
		If InStr(ErrorLevel, "C", true) OR InStr(ErrorLevel, "c", true)
		{
	    LV_GetText(RowText, A_EventInfo)  ; Get the text from the row's first field.
			If %A_EventInfo%active=1
			{
				%A_EventInfo%active=0
				GoSub, StartStopScript
				}
			Else
			{
				%A_EventInfo%active=1
				GoSub, StartStopScript
			}
		}
	}
} 
return

EditFile:
	myindex := LastRightClicked
	LongFile := GetValue(LongFileList,myindex)
	run, %editor% "%LongFile%"
return

ShowFolder:
	myindex := LastRightClicked
	Path := GetValue(PathList,myindex)
	run, "%Path%"
return



StartStopScript:
	myindex := A_EventInfo
	LongFile := GetValue(LongFileList,myindex)
	File := GetValue(FileList,myindex)
	GuiControlGet, Status,,Checkbox%myindex%
	If %A_EventInfo%active <> 0
	{
		;start
		run, %LongFile%
	}
	else
		WinClose %File% - AutoHotkey  ; Update this to reflect the script's name (case sensitive).
return


ButtonHide:
	WinHide
return

ButtonChangeFolder:
	FileDelete, %IniFile%
	Gosub, ButtonRescan
return

ButtonRescan:
ScanFolder =
LongFileList =
FileList = 
PIDs = 
RunningScripts = 

Gosub,READINI
GoSub, ShowWindow
GoSub, Wait
return


READINI:
	; Read the stored settings
	IfNotExist, %IniFile% 
		GoSub, WRITEINI
	IniRead, ScanFolder, %IniFile%,General, ScanFolder
return

WRITEINI:
	; Store settings
	Gui +OwnDialogs  ; Force the user to dismiss the FileSelectFile dialog before returning to the main window.
	FileSelectFolder, NewScanFolder, *%A_WorkingDir%, 3, Select an AHK scripts folder to manage
	If NOT ErrorLevel
		ScanFolder := NewScanFolder
	If NOT ScanFolder
	{
		Msgbox, No folder selected, so defaulting to Axem folder
		ScanFolder := A_WorkingDir
		}
	IniWrite, %ScanFolder%, %IniFile%, General, ScanFolder
return

GetValue(var,index)
{
	Loop, parse, var, `n
		If A_Index = %index%
			return %A_LoopField%
}



/*
		Title: Command Functions
			A wrapper set of functions for commands which have an output variable.
		
		Function: Functions
			Dummy function to initialize StdLib inclusion of this file.
			Use this at the top of your script before any other functions in this
			library are called.
		
		Remarks:
			Every command with an output variable has been translated to a function 
			where the 'OutputVar' parameter has been removed and its normal value is 
			returned instead.
			Commands with multiple variables such as 
			FileSelectFile, ImageSearch, MouseGetPos, PixelSearch and SplitPath use
			their ordinary parameters with ByRef.
			IfBetween, IfIn, IfContains and IfIs and their 'not' variations are 
			function counterparts of their non-expression If commands.
		
		License:
			- Version 1.5-r2 by Titan <http://www.autohotkey.net/~Titan/#functions>
			- zlib License <http://www.autohotkey.net/~Titan/zlib.txt>
*/


Functions() {
	Return, true
}

IfBetween(ByRef var, LowerBound, UpperBound) {
	If var between %LowerBound% and %UpperBound%
		Return, true
}
IfNotBetween(ByRef var, LowerBound, UpperBound) {
	If var not between %LowerBound% and %UpperBound%
		Return, true
}
IfIn(ByRef var, MatchList) {
	If var in %MatchList%
		Return, true
}
IfNotIn(ByRef var, MatchList) {
	If var not in %MatchList%
		Return, true
}
IfContains(ByRef var, MatchList) {
	If var contains %MatchList%
		Return, true
}
IfNotContains(ByRef var, MatchList) {
	If var not contains %MatchList%
		Return, true
}
IfIs(ByRef var, type) {
	If var is %type%
		Return, true
}
IfIsNot(ByRef var, type) {
	If var is not %type%
		Return, true
}

ControlGet(Cmd, Value = "", Control = "", WinTitle = "", WinText = "", ExcludeTitle = "", ExcludeText = "") {
	ControlGet, v, %Cmd%, %Value%, %Control%, %WinTitle%, %WinText%, %ExcludeTitle%, %ExcludeText%
	Return, v
}
ControlGetFocus(WinTitle = "", WinText = "", ExcludeTitle = "", ExcludeText = "") {
	ControlGetFocus, v, %WinTitle%, %WinText%, %ExcludeTitle%, %ExcludeText%
	Return, v
}
ControlGetText(Control = "", WinTitle = "", WinText = "", ExcludeTitle = "", ExcludeText = "") {
	ControlGetText, v, %Control%, %WinTitle%, %WinText%, %ExcludeTitle%, %ExcludeText%
	Return, v
}
DriveGet(Cmd, Value = "") {
	DriveGet, v, %Cmd%, %Value%
	Return, v
}
DriveSpaceFree(Path) {
	DriveSpaceFree, v, %Path%
	Return, v
}
EnvGet(EnvVarName) {
	EnvGet, v, %EnvVarName%
	Return, v
}
FileGetAttrib(Filename = "") {
	FileGetAttrib, v, %Filename%
	Return, v
}
FileGetShortcut(LinkFile, ByRef OutTarget = "", ByRef OutDir = "", ByRef OutArgs = "", ByRef OutDescription = "", ByRef OutIcon = "", ByRef OutIconNum = "", ByRef OutRunState = "") {
	FileGetShortcut, %LinkFile%, OutTarget, OutDir, OutArgs, OutDescription, OutIcon, OutIconNum, OutRunState
}
FileGetSize(Filename = "", Units = "") {
	FileGetSize, v, %Filename%, %Units%
	Return, v
}
FileGetTime(Filename = "", WhichTime = "") {
	FileGetTime, v, %Filename%, %WhichTime%
	Return, v
}
FileGetVersion(Filename = "") {
	FileGetVersion, v, %Filename%
	Return, v
}
FileRead(Filename) {
	FileRead, v, %Filename%
	Return, v
}
FileReadLine(Filename, LineNum) {
	FileReadLine, v, %Filename%, %LineNum%
	Return, v
}
FileSelectFile(Options = "", RootDir = "", Prompt = "", Filter = "") {
	FileSelectFile, v, %Options%, %RootDir%, %Prompt%, %Filter%
	Return, v
}
FileSelectFolder(StartingFolder = "", Options = "", Prompt = "") {
	FileSelectFolder, v, %StartingFolder%, %Options%, %Prompt%
	Return, v
}
FormatTime(YYYYMMDDHH24MISS = "", Format = "") {
	FormatTime, v, %YYYYMMDDHH24MISS%, %Format%
	Return, v
}
GetKeyState(WhichKey , Mode = "") {
	GetKeyState, v, %WhichKey%, %Mode%
	Return, v
}
GuiControlGet(Subcommand = "", ControlID = "", Param4 = "") {
	GuiControlGet, v, %Subcommand%, %ControlID%, %Param4%
	Return, v
}
ImageSearch(ByRef OutputVarX, ByRef OutputVarY, X1, Y1, X2, Y2, ImageFile) {
	ImageSearch, OutputVarX, OutputVarY, %X1%, %Y1%, %X2%, %Y2%, %ImageFile%
}
IniRead(Filename, Section, Key, Default = "") {
	IniRead, v, %Filename%, %Section%, %Key%, %Default%
	Return, v
}
Input(Options = "", EndKeys = "", MatchList = "") {
	Input, v, %Options%, %EndKeys%, %MatchList%
	Return, v
}
InputBox(Title = "", Prompt = "", HIDE = "", Width = "", Height = "", X = "", Y = "", Font = "", Timeout = "", Default = "") {
	InputBox, v, %Title%, %Prompt%, %HIDE%, %Width%, %Height%, %X%, %Y%, , %Timeout%, %Default%
	Return, v
}
MouseGetPos(ByRef OutputVarX = "", ByRef OutputVarY = "", ByRef OutputVarWin = "", ByRef OutputVarControl = "", Mode = "") {
	MouseGetPos, OutputVarX, OutputVarY, OutputVarWin, OutputVarControl, %Mode%
}
PixelGetColor(X, Y, RGB = "") {
	PixelGetColor, v, %X%, %Y%, %RGB%
	Return, v
}
PixelSearch(ByRef OutputVarX, ByRef OutputVarY, X1, Y1, X2, Y2, ColorID, Variation = "", Mode = "") {
	PixelSearch, OutputVarX, OutputVarY, %X1%, %Y1%, %X2%, %Y2%, %ColorID%, %Variation%, %Mode%
}
Random(Min = "", Max = "") {
	Random, v, %Min%, %Max%
	Return, v
}
RegRead(RootKey, SubKey, ValueName = "") {
	RegRead, v, %RootKey%, %SubKey%, %ValueName%
	Return, v
}
Run(Target, WorkingDir = "", Mode = "") {
	Run, %Target%, %WorkingDir%, %Mode%, %v%
	Return, v	
}
SoundGet(ComponentType = "", ControlType = "", DeviceNumber = "") {
	SoundGet, v, %ComponentType%, %ControlType%, %DeviceNumber%
	Return, v
}
SoundGetWaveVolume(DeviceNumber = "") {
	SoundGetWaveVolume, v, %DeviceNumber%
	Return, v
}
StatusBarGetText(Part = "", WinTitle = "", WinText = "", ExcludeTitle = "", ExcludeText = "") {
	StatusBarGetText, v, %Part%, %WinTitle%, %WinText%, %ExcludeTitle%, %ExcludeText%
	Return, v
}
SplitPath(ByRef InputVar, ByRef OutFileName = "", ByRef OutDir = "", ByRef OutExtension = "", ByRef OutNameNoExt = "", ByRef OutDrive = "") {
	SplitPath, InputVar, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
}
StringGetPos(ByRef InputVar, SearchText, Mode = "", Offset = "") {
	StringGetPos, v, %InputVar%, %SearchText%, %Mode%, %Offset%
	Return, v
}
StringLeft(ByRef InputVar, Count) {
	StringLeft, v, %InputVar%, %Count%
	Return, v
}
StringLen(ByRef InputVar) {
	StringLen, v, %InputVar%
	Return, v
}
StringLower(ByRef InputVar, T = "") {
	StringLower, v, %InputVar%, %T%
	Return, v
}
StringMid(ByRef InputVar, StartChar, Count , L = "") {
	StringMid, v, %InputVar%, %StartChar%, %Count%, %L%
	Return, v
}
StringReplace(ByRef InputVar, SearchText, ReplaceText = "", All = "") {
	StringReplace, v, %InputVar%, %SearchText%, %ReplaceText%, %All%
	Return, v
}
StringRight(ByRef InputVar, Count) {
	StringRight, v, %InputVar%, %Count%
	Return, v
}
StringTrimLeft(ByRef InputVar, Count) {
	StringTrimLeft, v, %InputVar%, %Count%
	Return, v
}
StringTrimRight(ByRef InputVar, Count) {
	StringTrimRight, v, %InputVar%, %Count%
	Return, v
}
StringUpper(ByRef InputVar, T = "") {
	StringUpper, v, %InputVar%, %T%
	Return, v
}
SysGet(Subcommand, Param3 = "") {
	SysGet, v, %Subcommand%, %Param3%
	Return, v
}
Transform(Cmd, Value1, Value2 = "") {
	Transform, v, %Cmd%, %Value1%, %Value2%
	Return, v
}
WinGet(Cmd = "", WinTitle = "", WinText = "", ExcludeTitle = "", ExcludeText = "") {
	WinGet, v, %Cmd%, %WinTitle%, %WinText%, %ExcludeTitle%, %ExcludeText%
	Return, v
}
WinGetActiveTitle() {
	WinGetActiveTitle, v
	Return, v
}
WinGetClass(WinTitle = "", WinText = "", ExcludeTitle = "", ExcludeText = "") {
	WinGetClass, v, %WinTitle%, %WinText%, %ExcludeTitle%, %ExcludeText%
	Return, v
}
WinGetText(WinTitle = "", WinText = "", ExcludeTitle = "", ExcludeText = "") {
	WinGetText, v, %WinTitle%, %WinText%, %ExcludeTitle%, %ExcludeText%
	Return, v
}
WinGetTitle(WinTitle = "", WinText = "", ExcludeTitle = "", ExcludeText = "") {
	WinGetTitle, v, %WinTitle%, %WinText%, %ExcludeTitle%, %ExcludeText%
	Return, v
}



Wait:
