import QtQuick

/* Stub of Quickshell's StdioCollector: the whole stream in `text`. */
QtObject {
	property string text: ""
	property bool waitForEnd: true

	signal streamFinished()

	function _reset() { text = ""; }
	function _feed(data) { text += data; }
	function _finish() { streamFinished(); }
}
