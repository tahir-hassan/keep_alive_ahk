#Include "point.ahk"

class MousePointTracker {

    __New(onMousePointChanged) {
        this.lastMousePoint := Point(0, 0)
        this.onMousePointChanged := onMousePointChanged
        this.interval := 1000
        this.timer := this.MouseTimer.Bind(this)
    }

    Start() {
        SetTimer this.timer, this.interval
    }
    Stop() {
        SetTimer this.timer, 0
    }

    GetMousePoint() {
        MouseGetPos(&x, &y)
        return Point(x, y)
    }

    MouseTimer() {
        currentMousePoint := this.GetMousePoint()
        mouseStill := this.lastMousePoint.Equals(currentMousePoint)
        if !mouseStill {
            (this.onMousePointChanged)()
        }
        this.lastMousePoint := currentMousePoint
    }
}