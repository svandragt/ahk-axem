; Axem (AutoHotkey Script Manager -AHKSM)
; Language:       English
;
; Synopsis: test
#NoEnv
DetectHiddenWindows On  ; Allows a script's hidden main window to be detected.	
SetTitleMatchMode 2  ; Avoids the need to specify the full path of the file below.
SendMode Input
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#Include Anchor.ahk ; Thanks to Titan for their Anchoring & functions tools http://www.autohotkey.net/~Titan/
#Include Functions.ahk

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
	Gui Destroy
	EnableCheckboxEvents=0
	Gui, +Resize
	Gui, Add, Text,, Scripts found in %ScanFolder%:
	winget,ls,list,AutoHotkey ahk_class AutoHotkey
	
	Gui, Add, ListView, r20 w740 Count20 Checked AltSubmit gMyListView vMyListView, Script|Synopsis
	GuiControl, -Redraw, MyListView ; for performance reasons
	Loop, %ScanFolder%\*.ahk, , 1 
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
	EnableCheckboxEvents=1
	GuiControl, +Redraw, MyListView
	
	Gui, Add, Button, Section xs vRescan, &Rescan
	Gui, Add, Button, ys vChangeFolder, &Change Folder
	Gui, Add, Button, ys Default vHide, &Hide
	 
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

GuiSize:  ; Expand or shrink the ListView in response to the user's resizing of the window.
if A_EventInfo = 1  ; The window has been minimized.  No action needed.
    return
; Otherwise, the window has been resized or maximized. Resize the ListView to match.
Anchor("MyListView", "wh")
Anchor("Rescan", "y",true)
Anchor("ChangeFolder", "y",true)
Anchor("Hide", "y",true)


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
		Menu,Options,Add,Explore...,ShowFolder
    Menu,Options,Show, %A_GuiX%, %A_GuiY%	
} 
else if A_GuiEvent = I
{
	If EnableCheckboxEvents=1 
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

Wait:
