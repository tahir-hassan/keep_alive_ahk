#Requires AutoHotkey v2 64-bit
#SingleInstance Force

SetCapsLockState "AlwaysOff"

; Remap CapsLock+J → Down, CapsLock+K → Up
CapsLock & j::Send("{Down}")
CapsLock & k::Send("{Up}")

; Shift+CapsLock → toggle CapsLock (normal CapsLock behavior)
+CapsLock::SetCapsLockState(!GetKeyState("CapsLock", "T"))
