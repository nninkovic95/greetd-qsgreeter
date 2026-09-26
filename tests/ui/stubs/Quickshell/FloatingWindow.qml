import QtQuick

/*
 * Stub of Quickshell's FloatingWindow: a plain top-level window at a fixed
 * size, so screenshots are comparable between runs.
 */
Window {
	/** Quickshell takes a size string such as "600x400" */
	property size minimumSize

	minimumWidth: minimumSize.width
	minimumHeight: minimumSize.height
	width: 1280
	height: 800
	visible: true
}
