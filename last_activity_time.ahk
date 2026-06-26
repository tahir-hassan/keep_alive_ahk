class LastActivityTime {
    __New() {
        this.lastTimeActive := A_TickCount
    }

    Update() {
        this.lastTimeActive := A_TickCount
    }

    Get() {
        return this.lastTimeActive
    }
}