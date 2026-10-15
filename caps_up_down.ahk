#Requires AutoHotkey v2 64-bit
#SingleInstance Force

StrEq(stringA, stringB) {
	return StrCompare(stringA, stringB, true) = 0
}

class CB {
	static Clear() {
		A_Clipboard := ""
	}

	static WaitGet() {
		ClipWait(1)
		return A_Clipboard
	}

	static WaitSet(value) {
		A_Clipboard := ""
		A_Clipboard := value
		ClipWait
	}
}

class HandyToolTip {
	static ToolTipID := 5

	/*
	Old method of positioning the tooltip near the bottom of the window:
	
		CoordMode "ToolTip", "Screen"
		x := (A_ScreenWidth / 4) * 1
		y := (A_ScreenHeight / 8) * 7
	*/
	static Show(message) {
		WinGetClientPos &x, &y, , &h, "A"
		CoordMode "ToolTip", "Screen"
		ToolTip message, x, (y + h), this.ToolTipID
	}

	static Hide() {
		ToolTip "", 0, 0, this.ToolTipID
	}
}

class HandyCliArgs {
	static Cancel := "--cancel"
	static ToggleTranscription := "--toggle-transcription"
}

class LangUtils {
	static CanChangeCase(word) {
		if (StrEq("I", word)) {
			return false
		} else if (StrLen(word) > 1 && StringUtils.IsAllCapitalized(word)) {
			return false
		} else {
			return true
		}
	}

	;; Returns string
	static FormatAsSentence(text, startOfSentence) {
		if (startOfSentence) {
			return StrUpper(StringUtils.FirstChar(text)) . StringUtils.ButFirstChar(text)
		} else {
			;; Because this recording is a continuation of the previous recording,
			;; we want to lowercase the first letter if possible.
			words := StringUtils.Words(text)
			firstWord := words[1]
			canChange := this.CanChangeCase(firstWord)

			if canChange {
				return StrLower(StringUtils.FirstChar(text)) . StringUtils.ButFirstChar(text)
			} else {
				return text
			}
		}
	}
}

class FormatUtils {
	static PascalCase(str) {
		return Trim(StrReplace(StrTitle(str), " ", ""))
	}

	static CamelCase(str) {
		pascal := this.PascalCase(str)
		if StrLen(pascal) > 0 {
			firstChar := StringUtils.FirstChar(pascal)
			firstLower := StrLower(firstChar)
			rest := StringUtils.ButFirstChar(pascal)
			return firstLower . rest
		}
		return pascal
	}

	static DashCase(str) {
		return Trim(StrLower(StrReplace(str, " ", "-")))
	}
}

class PunctuationChars {
	static EndPunctuationCharacters := ".?!"
	static NonEndPunctuationCharacters := ",:"

	static IsEndPunctuationChar(character) {
		return InStr(this.EndPunctuationCharacters, character)
	}

	static IsNonEndPunctuationChar(character) {
		return InStr(this.NonEndPunctuationCharacters, character)
	}

	static IsPunctuationChar(character) {
		return this.IsEndPunctuationChar(character) || this.IsNonEndPunctuationChar(character)
	}
}


class StringUtils {

	static Words(str) {
		return StrSplit(str, A_Space)
	}

	static WrapText(str, maxLineLen) {
		result := ""
		words := this.Words(str)
		currentLineLen := 0
		for word in words {
			wordLen := StrLen(word)
			requiredSpaces := currentLineLen = 0 ? 0 : 1
			willSpillOver := currentLineLen + requiredSpaces + wordLen > maxLineLen
			if willSpillOver {
				result := result . "`n" . word
				currentLineLen := wordLen
			} else if requiredSpaces = 0 {
				result := result . word
				currentLineLen := wordLen
			} else {
				result := result . " " . word
				currentLineLen := currentLineLen + 1 + wordLen
			}
		}
		return result
	}

	static FirstWord(str) {
		return StrSplit(str, A_Space)[1]
	}

	static IsAllCapitalized(str) {
		return StrEq(str, StrUpper(str))
	}

	static FirstChar(str) {
		if StrLen(str) > 0 {
			return SubStr(str, 1, 1)
		}
		return ""
	}
	static ButFirstChar(str) {
		if StrLen(str) > 1 {
			return SubStr(str, 2)
		}

		return ""
	}
	static LastChar(str) {
		return SubStr(str, -1)
	}
	static ButLastChar(str) {
		if StrLen(str) > 0 {
			return SubStr(str, 1, -1)
		} else {
			return ""
		}
	}
	static AddPunctuation(str, mark) {
		str := Trim(str)
		lastChar := this.LastChar(str)
		if (lastChar = mark) {
			return str
		} else if (PunctuationChars.IsPunctuationChar(lastChar)) {
			return (this.ButLastChar(str) . mark)
		} else {
			return str . mark
		}
	}

	static TogglePunctuation(str, mark) {
		str := Trim(str)
		;; Last character of the string.
		lastChar := this.LastChar(str)
		if (StrEq(lastChar, mark)) {
			;; If the last character is the same as the mark that we want to add, then we should remove it
			return this.ButLastChar(str)
		} else if (PunctuationChars.IsPunctuationChar(lastChar)) {
			;; If the last character is a punctuation mark which is not the same as that mark that we want to add, then we replace the last punctuation mark with the mark.
			return this.ButLastChar(str) . mark
		} else {
			;; otherwise the last character is neither a punctuation mark nor is it the same as the mark that we want to add therefore we can add the mark.
			return str . mark
		}
	}

	static ToggleFirstLetterCase(str) {
		str := Trim(str)
		first := this.FirstChar(str)
		rest := this.ButFirstChar(str)
		firstLower := StrLower(first)
		firstUpper := StrUpper(first)
		if (StrEq(first, firstLower)) {
			return firstUpper . rest
		} else {
			return firstLower . rest
		}
	}

	static JoinArray(arr, separator) {
		joined := ""
		for i, val in arr
			joined .= (i > 1 ? separator : "") val
		return joined
	}
}

class SentenceState {
	static SentenceEnded := true

	static GetSentenceEnded() {
		return this.SentenceEnded
	}

	static SetSentenceEnded(ended) {
		this.SentenceEnded := ended
	}
}

class OutsidePunctuationHandler {
	static Bound := Array()
	static IsTesting := false

	static Bind() {
		for _, c in StrSplit(PunctuationChars.EndPunctuationCharacters) {
			Hotkey ("~" . c), this.OnEndPunctuationCharacter.Bind(this), "Off"
			this.Bound.Push(("~" . c))
		}

		for _, c in StrSplit(PunctuationChars.NonEndPunctuationCharacters) {
			Hotkey ("~" . c), this.OnNonEndPunctuationCharacter.Bind(this), "Off"
			this.Bound.Push(("~" . c))
		}
	}

	static _SetHotKeysOption(opt) {
		for bound in this.Bound {
			Hotkey bound, , opt
		}
	}

	static On() {
		this._SetHotKeysOption("On")
	}

	static Off() {
		this._SetHotKeysOption("Off")
	}

	static OnEndPunctuationCharacter(ThisHotkey) {
		if this.IsTesting && ThisHotkey = "~!" {
			MsgBox ("TESTING: " . ThisHotkey)
		}
		SentenceState.SetSentenceEnded(true)
	}

	static OnNonEndPunctuationCharacter(ThisHotkey) {
		SentenceState.SetSentenceEnded(false)
	}
}

;; This class should not in any way depend on the sentence state class
class TranscribedText {
	__New()
	{
		this.Items := Array()
	}

	Add(text) {
		this.Items.Push(text)
	}

	Any() {
		return this.Items.Length > 0
	}

	AddIfNotEmpty(text, externalSentenceEnded) {
		if IsSet(text) && (text != "") {
			text := Trim(text)

			startOfSentence := this.Any() ? this.LastEnds() : externalSentenceEnded
			textToAdd := LangUtils.FormatAsSentence(text, startOfSentence)
			this.Add(textToAdd)
		}
	}

	RemoveLast() {
		return this.Items.Pop()
	}

	GetText() {
		return StringUtils.JoinArray(this.Items, " ")
	}

	Count() {
		return this.Items.Length
	}

	LastEnds() {
		if this.Any() {
			lastItem := this.Items[this.Items.Length]
			lastChar := StringUtils.LastChar(lastItem)
			return PunctuationChars.IsEndPunctuationChar(lastChar)
		}

		return true
	}

	ToggleCasing() {
		if (this.Any()) {
			last := this.RemoveLast()
			lastModified := StringUtils.ToggleFirstLetterCase(last)
			this.Add(lastModified)
		}
	}

	FormatLast(character) {
		if (this.Any()) {
			last := this.RemoveLast()
			if IsSet(last) {
				lastModified := ""
				if StrEq(character, "c") {
					lastModified := FormatUtils.CamelCase(last)
				} else if StrEq(character, "p") {
					lastModified := FormatUtils.PascalCase(last)

				} else if (StrEq(character, "-")) {
					lastModified := FormatUtils.DashCase(last)
				} else {
					lastModified := last
				}
				this.Add(lastModified)
			}
		}
	}

	AddPunctuation(mark) {
		if (this.Any()) {
			last := this.RemoveLast()
			lastModified := StringUtils.AddPunctuation(last, mark)
			this.Add(lastModified)
		}
	}

	TogglePunctuation(mark) {
		if (this.Any()) {
			last := this.RemoveLast()
			lastModified := StringUtils.TogglePunctuation(last, mark)
			this.Add(lastModified)
		}
	}
}


class Dandy {
	static IsRecording := false
	static IsPaused := false
	static IsFormatting := false
	static IsStoppingOrStarting := false
	static CurrentlyTranscribedText := TranscribedText()
	static Hook := DandyHook()
	static Log := Array()
	static FormatMenuItems := [
		"<ESC> - go back",
		"c - camelCase paste",
		"p - PascalCase paste",
		"- - dash and lowercase paste",
	]
	static PauseMenuItems := [
		"<SPC> - resume",
		". ? - end sentence",
		", - comma",
		"u - change case",
		"f - format menu"
	]
	static RecordingMenuItems := [
		"<SPC> - pause",
		". ? - end sentence, pause",
		", - comma, pause",
		"f - format menu",
	]

	static InvokeHandyCli(argument) {
		RunWait 'C:\Users\tahir\AppData\Local\Handy\handy.exe ' . argument
	}

	static StartHandy() {
		CB.Clear()
		this.IsStoppingOrStarting := true
		this.InvokeHandyCli(HandyCliArgs.Cancel)
		HandyToolTip.Hide()
		this.InvokeHandyCli(HandyCliArgs.ToggleTranscription)
	}

	static _joinNl(arr) {
		return StringUtils.JoinArray(arr, "`n")
	}

	static _joinNlNl(arr) {
		return StringUtils.JoinArray(arr, "`n`n")
	}

	static AddLog(text) {
		this.Log.Push(text)
	}

	static GetMenuItemsForState() {
		if this.IsFormatting {
			return this.FormatMenuItems
		} else if this.IsPaused {
			return this.PauseMenuItems
		} else if this.IsRecording {
			return this.RecordingMenuItems
		} else {
			return Array()
		}
	}

	static SetMenuState() {
		if (this.IsPaused || this.IsRecording || this.IsFormatting) {
			tooltipTextArr := Array()

			if (this.Log.Length > 0) {
				tooltipTextArr.Push(this._joinNl(this.Log))
			}

			if (this.CurrentlyTranscribedText.Count() > 0) {
				currentTranscribedText := this.CurrentlyTranscribedText.GetText()
				wrappedTranscribedText := StringUtils.WrapText(currentTranscribedText, 100)
				tooltipTextArr.Push(wrappedTranscribedText)
			}

			menuItems := this.GetMenuItemsForState()
			tooltipTextArr.Push(StringUtils.JoinArray(menuItems, "   "))

			stateText := this.IsPaused ? "Recording is paused." : "Currently recording..."
			tooltipTextArr.Push(stateText)

			totalText := this._joinNlNl(tooltipTextArr)
			HandyToolTip.Show(totalText)
		} else {
			HandyToolTip.Hide()
		}
	}

	static Recording_Paused_Formatting_StoppingStarting(rec, pau, formatting, ing) {
		this.IsRecording := rec
		this.IsPaused := pau
		this.IsFormatting := formatting
		this.IsStoppingOrStarting := ing

		this.SetMenuState()
	}

	static StartTranscription() {
		if (!this.IsRecording && !this.IsPaused) {
			try {
				this.Log := Array()
				this.CurrentlyTranscribedText := TranscribedText()
				this.Hook := DandyHook()
				this.StartHandy()
				this.Hook.Start()
			} finally {
				this.Recording_Paused_Formatting_StoppingStarting(true, false, false, false)
			}
		}
	}

	static EndHandyTranscription() {
		this.IsStoppingOrStarting := true
		this.InvokeHandyCli(HandyCliArgs.ToggleTranscription)
		handyResult := CB.WaitGet()
		return handyResult
	}

	static ShowFormatMenu() {
		this.Recording_Paused_Formatting_StoppingStarting(false, true, true, false)
	}

	static PauseTranscription() {
		if (this.IsRecording) {
			try {
				handyResult := this.EndHandyTranscription()
				this.CurrentlyTranscribedText.AddIfNotEmpty(handyResult, SentenceState.GetSentenceEnded())
			} finally {
				this.Recording_Paused_Formatting_StoppingStarting(false, true, false, false)
			}
		}
	}

	static ResumeTranscription() {
		if (this.IsPaused) {
			try {
				this.StartHandy()
			} finally {
				this.Recording_Paused_Formatting_StoppingStarting(true, false, false, false)
			}
		}
	}

	static IsPostPauseActionChar(character) {
		return StrEq(character, "u")
	}

	static IsFormattingRequestChar(character) {
		return StrEq(character, "f")
	}

	static _StopTranscription(copyToClipboard) {
		if (this.IsRecording || this.IsPaused) {
			try {
				if (this.IsRecording) {
					handyResult := this.EndHandyTranscription()
					this.CurrentlyTranscribedText.AddIfNotEmpty(handyResult, SentenceState.GetSentenceEnded())
				}

				if (copyToClipboard && this.CurrentlyTranscribedText.Any()) {
					text := this.CurrentlyTranscribedText.GetText()
					CB.WaitSet(text)
					Send "^v"
					SentenceState.SetSentenceEnded(this.CurrentlyTranscribedText.LastEnds())
				}
			} finally {
				this.Hook.Stop()
				this.Recording_Paused_Formatting_StoppingStarting(false, false, false, false)
			}
		}
	}

	static FormatTranscription(character) {
		this.CurrentlyTranscribedText.FormatLast(character)
		this._StopTranscription(true)
	}


	static CharacterAction(character) {
		if (character = ' ') {
			if (this.IsRecording) {
				this.PauseTranscription()
			} else if (this.IsPaused) {
				this.ResumeTranscription()
			}
		} else if (PunctuationChars.IsPunctuationChar(character)) {
			; if you are currently recording. Pause it.
			wasPaused := false
			if (this.IsRecording) {
				this.PauseTranscription()
				wasPaused := true
			}

			if (wasPaused) {
				this.CurrentlyTranscribedText.AddPunctuation(character)
			} else {
				this.CurrentlyTranscribedText.TogglePunctuation(character)
			}
			this.SetMenuState()
		} else if (this.IsPostPauseActionChar(character)) {
			if (this.IsPaused) {
				this.CurrentlyTranscribedText.ToggleCasing()
			}
			this.SetMenuState()
		} else if (this.IsPaused && this.IsFormattingRequestChar(character)) {
			this.ShowFormatMenu()
			; unrecognized character
		} else if (this.IsRecording && this.IsFormattingRequestChar(character)) {
			this.PauseTranscription()
			this.ShowFormatMenu()
		} else if (this.IsFormatting) {
			this.FormatTranscription(character)
		}
	}

	static StopTranscription() {
		this._StopTranscription(true)
	}

	static CancelTranscription() {
		this._StopTranscription(false)
	}
	static ToggleTranscription() {
		while (this.IsStoppingOrStarting) {
			Sleep 25
		}
		if (this.IsRecording || this.IsPaused) {
			this.StopTranscription()
		} else {
			this.StartTranscription()
		}
	}
}

class DandyHook {
	__New() {
		; L0 disables collection of text
		this.InputHookObj := InputHook("L0")
		onCharFunc := (hookObj, character) => this.OnChar(hookObj, character)
		this.InputHookObj.OnChar := onCharFunc
	}

	Start() {
		this.InputHookObj.Start()
		OutsidePunctuationHandler.Off()
	}

	Stop() {
		this.InputHookObj.Stop()
		OutsidePunctuationHandler.On()
	}

	OnChar(hookObj, character) {
		if (character = "`r" || character = "`n") {
			Dandy.StopTranscription()
		} else if (character = Chr(0x1b)) {
			Dandy.CancelTranscription()
		} else {
			Dandy.CharacterAction(character)
		}
	}
}

SetCapsLockState "AlwaysOff"

CapsLock & Space:: {
	Dandy.ToggleTranscription()
}

CapsLock:: {

}

; Remap CapsLock+J → Down, CapsLock+K → Up
CapsLock & j:: Send("{Down}")
CapsLock & k:: Send("{Up}")

+CapsLock:: {

}

^CapsLock:: {

}

^+!CapsLock:: {
	SetCapsLockState(!GetKeyState("CapsLock", "T"))
}

OutsidePunctuationHandler.Bind()
OutsidePunctuationHandler.On()