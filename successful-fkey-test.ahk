#Requires AutoHotkey v2 64-bit
#SingleInstance Force

; Remap F5+J → Down, F5+K → Up
; as a test so that we can remap F-keys greater than F12
F5 & j:: Send("{Down}")
F5 & k:: Send("{Up}")

; Remap F5 to do nothing because if we are using an F-key as
; a modifier, then the original function needs to be blocked
F5:: {

}
