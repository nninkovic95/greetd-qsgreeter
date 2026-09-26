import QtQuick

/* Stub of Quickshell's SystemClock, frozen so screenshots do not change. */
QtObject {
	enum Precision { Hours, Minutes, Seconds }

	property int precision: SystemClock.Seconds
	readonly property date date: new Date(2026, 0, 15, 9, 41, 0)
	readonly property int hours: 9
	readonly property int minutes: 41
	readonly property int seconds: 0
}
