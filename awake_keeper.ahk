class AwakeKeeper {
    lastActiveTime := 0
    checkInterval := 0
    actionInterval := 0
    __New(lastActiveTime, checkInterval, actionInterval) {
        this.lastActiveTime := lastActiveTime
        this.checkInterval := checkInterval
        this.actionInterval := actionInterval
        this.timer := this.KeepAwakeTimer.Bind(this)
    }

    KeepAwakeAction() {
        Send "{ScrollLock}"
        Sleep 100
        Send "{ScrollLock}"
        FileAppend("activity done to keep screen awake`n", "*")
        this.lastActiveTime.Update()
    }

    KeepAwakeTimer() {
        currentTime := A_TickCount
        if (currentTime - this.lastActiveTime.Get()) > this.actionInterval {
            this.KeepAwakeAction()
        }
    }

    Start() {
        SetTimer this.timer, this.checkInterval
    }

    Stop() {
        SetTimer this.timer, 0
    }
}