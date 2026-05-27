import QuartzCore

/// Monotonic millisecond clock. Injected so playback is deterministic in tests.
protocol Clock: AnyObject {
    var nowMs: Double { get }
}

final class HostClock: Clock {
    var nowMs: Double { CACurrentMediaTime() * 1000 }
}

final class TestClock: Clock {
    var nowMs: Double = 0
    func advance(_ ms: Double) { nowMs += ms }
}
