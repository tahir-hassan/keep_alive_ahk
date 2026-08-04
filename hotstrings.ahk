#Requires AutoHotkey v2 64-bit
#SingleInstance Force

::atpresent:: {
    day := Integer(FormatTime(, "d"))
    suffix := (day >= 11 && day <= 13) ? "th"
        : (Mod(day, 10) = 1) ? "st"
        : (Mod(day, 10) = 2) ? "nd"
        : (Mod(day, 10) = 3) ? "rd"
        : "th"

    SendText("At present (" . day . suffix . " " . FormatTime(, "MMMM yyyy") . "), ")
}

::mdps:: {
    SendText("``````powershell``````")
    Loop 3 {
        Send "{Left}"
        Sleep 50
    }
    Loop 2 {
        Send "{Enter}"
        Sleep 25
    }
    Send "{Up}"
}