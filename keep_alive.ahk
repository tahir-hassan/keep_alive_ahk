#Requires AutoHotkey v2 64-bit
#SingleInstance Force

#Include "point.ahk"
#Include "mouse_point_tracker.ahk"
#Include last_activity_time.ahk
#Include "awake_keeper.ahk"

DllCall("AllocConsole")
TraySetIcon("ghost-pink.png")

global lastActivityTimeObj := LastActivityTime()
global tracker := MousePointTracker(() => lastActivityTimeObj.Update())
tracker.Start()

keys := ["Enter", "Esc", "Space"]
Loop keys.Length {
    Hotkey ("~" . keys[A_Index]), (*) => lastActivityTimeObj.Update()
}

global awakeKeeperObj := AwakeKeeper(lastActivityTimeObj, 2000, 30000)
awakeKeeperObj.Start()