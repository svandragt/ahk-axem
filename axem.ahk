; Axem (AutoHotkey Script Manager)
; Language:       English
#NoEnv
DetectHiddenWindows On  ; Allows a script's hidden main window to be detected.	
SetTitleMatchMode, 2  ; Avoids the need to specify the full path of the file below.
SendMode Input
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#Include includes\Anchor.ahk ; Thanks to Titan for their Anchoring & functions tools http://www.autohotkey.net/~Titan/
#Include includes\Functions.ahk

functions()
IgnoreSelf = 1
IniFile = settings.ini
RegRead, Editor, HKEY_CLASSES_ROOT, AutoHotkeyScript\Shell\Edit\Command
RegRead, Compiler, HKEY_CLASSES_ROOT, AutoHotkeyScript\Shell\Compile\Command
If ErrorLevel
	Editor = notepad.exe
Else
	StringTrimRight, Editor, Editor, 3
RegRead, Compiler, HKEY_CLASSES_ROOT, AutoHotkeyScript\Shell\Compile\Command
If NOT ErrorLevel
	StringTrimRight, Compiler, Compiler, 4
	
ScanFolder =
LongFileList =
PathList = 
FileList = 


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
			If Instr(A_LoopFileDir,A_ScriptDir) ; ignore own script
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
		else
			synopsis =

		LV_Add(DisplayCheckbox, EntryTitle,synopsis)
	}
	LV_ModifyCol()  ; Auto-size each column to fit its contents.
	EnableCheckboxEvents=1
	GuiControl, +Redraw, MyListView
	
	Gui, Add, Button, Section xs vRescan, &Rescan
	Gui, Add, Button, ys vChangeFolder, &Change Folder
	Gui, Add, Button, ys Default vHide, &Hide
	 
	Menu, FileMenu, Add, &Open `tCtrl+O, ButtonChangeFolder  ; See remarks below about Ctrl+O.
	Menu, FileMenu, Add, E&xit `tAlt-F4, MenuExit
	Menu, HelpMenu, Add, &Support `tF1, MenuOnline
	Menu, ViewMenu, Add, &Reload   `tCtrl+R, ButtonRescan  ; See remarks below about Ctrl+O.
	Menu, MyMenuBar, Add, &File, :FileMenu  ; Attach the two sub-menus that were created above.
	Menu, MyMenuBar, Add, &View, :ViewMenu
	Menu, MyMenuBar, Add, &Help, :HelpMenu
	Gui, Menu, MyMenuBar
	 
	 
	Gui, Show,W760 H440 Center,Axem - AutoHotKey Scripts Manager
return

GuiSize: 
if A_EventInfo = 1  ; The window has been minimized.  No action needed.
{
	GoSub, ButtonHide
  return
}
Anchor("MyListView", "wh")
Anchor("Rescan", "y",true)
Anchor("ChangeFolder", "y",true)
Anchor("Hide", "y",true)
return

#IfWinActive
F1::
MenuOnline:
	SupportUrl = http://www.donationcoder.com/Forums/bb/index.php?topic=15482.0
	msgbox,4,Visit Online Support,Support on Axem is given via the Donationcoder.com community forums. Do you want to load the following webpage?`n`n%SupportUrl%
	IfMsgBox Yes
    Run, %supporturl%
return

#IfWinActive
!F4::
MenuExit:
GoSub, WRITEINI
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
		Menu,Options,Add,
		Menu,Options,Add,Compile,CompileFiles
		Menu,Options,Add,Publish,PublishFiles
		Menu,Options,Add,Compile && Publish,CompileAndPublish
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

CompileAndPublish:
	GoSub, CompileFiles
	GoSub, PublishFiles
return

CompileFiles:
	myindex := LastRightClicked
	LongFile := GetValue(LongFileList,myindex)
	ShortFile := GetValue(FileList,myindex)
	Path := GetValue(PathList,myindex)

	; default publish folder
	CompileFolder = %Path%
	
	; get ahk file
	; change to exe
	; find exe
	; use that as path
	
	CompiledFile := SubStr(ShortFile,1,-3) "exe"
	Loop %CompileFolder%\%CompiledFile%,0,1
	{
		CompileFolder := A_LoopFileDir
		break
	}
	runWait, %compiler% "%LongFile%" /out "%CompileFolder%\%CompiledFile%"
	GoSub, ShowFolder
return

PublishFiles:
	myindex := LastRightClicked
	Path := GetValue(PathList,myindex)
	
	; default publish folder
	PublishFolder = %Path%\publish
	; look for publish.bat if this exist then use their folder as the publish folder
	Loop publish.bat,0,1
	{
   PublishFolder := A_LoopFileDir
	 break
	}
	PublishBat = publish.bat

	IfExist, %PublishBat%
		runWait, %PublishBat%,%PublishFolder%
	Else
	{
		MsgBox,4,No batch file found, No publishing script found.  Add commands to a publishing batch file that are processed when publishing a project. For example you can create a zip file and uploading it via ftp.`n`nCreate and edit %PublishBat%?
		IfMsgBox Yes
			Run, %editor% "%PublishBat%"
	}
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
	GoSub, WRITEINI
	WinHide
return

#IfWinActive
^o::
ButtonChangeFolder:
	Gui +OwnDialogs  ; Force the user to dismiss the FileSelectFile dialog before returning to the main window.
	FileSelectFolder, NewScanFolder, *%A_WorkingDir%, 3, Select an AHK scripts folder to manage
	If NOT ErrorLevel
		ScanFolder := NewScanFolder
	If ScanFolder=
		{
			Msgbox, No folder selected, so defaulting to Axem folder
			ScanFolder := A_WorkingDir
		}
	GoSub, WRITEINI
	Gosub, ButtonRescan
return

#IfWinActive
^r::
ButtonRescan:
LongFileList =
FileList = 

GoSub, ShowWindow
GoSub, Wait
return


READINI:
	; Read the stored settings
	IfNotExist, %IniFile% 
		GoSub, WRITEINI
	IniRead, ScanFolder, %IniFile%,General, ScanFolder
	IniRead, NewIgnoreSelf, %IniFile%,General, IgnoreSelf
	If NewIgnoreSelf=0
		IgnoreSelf=0
return

WRITEINI:
	; Store settings
	if ScanFolder=
		Gosub, ButtonChangeFolder
	IniWrite, %ScanFolder%, %IniFile%, General, ScanFolder
return


GetValue(var,index)
{
	Loop, parse, var, `n
		If A_Index = %index%
			return %A_LoopField%
}

Wait:
