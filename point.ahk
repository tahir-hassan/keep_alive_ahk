class Point {
    __New(x, y) {
        this.x := x
        this.y := y
    }
    Equals(other) {
        return this.x = other.x && this.y = other.y
    }
}