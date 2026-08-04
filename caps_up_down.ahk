#Requires AutoHotkey v2 64-bit
#SingleInstance Force

SetCapsLockState "AlwaysOff"

CapsLock:: {

}
; Remap CapsLock+J → Down, CapsLock+K → Up
CapsLock & j:: Send("{Down}")
CapsLock & k:: Send("{Up}")

; Shift+CapsLock → toggle CapsLock (normal CapsLock behavior)
;+CapsLock::SetCapsLockState(!GetKeyState("CapsLock", "T"))
+CapsLock:: {

}

^CapsLock:: {

}

^+!CapsLock:: {
	SetCapsLockState(!GetKeyState("CapsLock", "T"))
}

CapsLock & Space:: {
	Send "{RCtrl Down}{Up Down}"
	KeyWait "Space"
	KeyWait "CapsLock"
	Send "{Up Up}{RCtrl Up}"
	A_Clipboard := ".." . A_Clipboard
	Sleep 50
	Send "^v"
}