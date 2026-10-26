#Requires AutoHotkey v2.0
#SingleInstance Force

BlurGui() {
    g := Gui("+AlwaysOnTop -Caption +ToolWindow +Resize", "BlurOverlay")
    g.BackColor := "000000" ; Base tint color


	SetTitleBarDark(self) {
		bg := 0x000000
		; Dark mode: Windows 10 (20H1+) and 11. Makes buttons/icons light, and the bar dark
		DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", self.Hwnd, "Int", 20, "Int*", 1, "Int", 4)
		; Exact caption color: Windows 11 only (build 22000+)
		DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", self.Hwnd, "Int", 35, "UInt*", bg, "Int", 4)
		; Caption text color: Windows 11 only
		; Optional: border color, same as the title bar so there's no visible outline
		DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", self.Hwnd, "Int", 34, "UInt*", bg, "Int", 4)
	}

	SetBlurLevel(self, darkness) {
		tint := (darkness << 24)          ; 0xAA000000 = black tint with alpha AA
		accent := Buffer(16, 0)
		NumPut("Int",  4,    accent, 0)   ; 4 = acrylic (respects the tint alpha)
		NumPut("Int",  0,    accent, 4)
		NumPut("UInt", tint, accent, 8)

		data := Buffer(3 * A_PtrSize, 0)
		NumPut("Int",  19,          data, 0)
		NumPut("Ptr",  accent.Ptr,  data, A_PtrSize)
		NumPut("UPtr", accent.Size, data, 2 * A_PtrSize)
		DllCall("user32\SetWindowCompositionAttribute", "Ptr", self.Hwnd, "Ptr", data)
	}

	ShowAt(self, x, y, width, height) {
		self.IsShown := true
		self.Show()
		self.SetTitleBarDark()
		WinMove(x, y, width, height, self.Hwnd)
	}

	XHide(self) {
		self.IsShown := false
		self.Hide()
	}

	XShow(self) {
		self.IsShown := true
		self.Show()
	}

	ShowForWindow(self, windowInfo) {
		self.ShowAt(windowInfo.X, windowInfo.Y, windowInfo.Width, windowInfo.Height)
		self.TargetWindow := windowInfo.Hwnd
		self.SetBlurLevel(150)
	}

	g.TargetWindow := 0
	g.IsShown := false
	g.XHide := XHide
	g.XShow := XShow
	g.ShowAt := ShowAt
	g.SetTitleBarDark := SetTitleBarDark
	g.SetBlurLevel := SetBlurLevel
	g.ShowForWindow := ShowForWindow

	return g
}

GetActiveBlurrableWindow() {
	targetHwnd := WinExist("A")
	if !targetHwnd {
		return 0
	} 

	; Prevent trying to blur the desktop or taskbar
	winClass := WinGetClass("ahk_id " targetHwnd)
	if (winClass = "Shell_TrayWnd" || winClass = "Progman" || winClass = "WorkerW") {
		return 0
	}

	; Get the target window's position and size
	WinGetClientPos(&outX, &outY, &outW, &outH, "ahk_id " targetHwnd)

	info := {}
	info.Hwnd := targetHwnd
	info.X := outX
	info.Y := outY
	info.Width := outW
	info.Height := outH
	return info
}

blurUI := BlurGui()

^Space:: {
	global blurUI

	if blurUI.IsShown {
		blurUI.XHide()
	} else {
		targetWin := GetActiveBlurrableWindow()
		if targetWin != 0 {
			if targetWin.Hwnd == blurUI.TargetWindow {
				blurUI.XShow()
			} else {
				blurUI.ShowForWindow(targetWin)
			}
		}
	}
}

