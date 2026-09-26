import QtQuick

/* Stub of Quickshell's SplitParser: one `read` per piece between markers. */
QtObject {
	property string splitMarker: "\n"

	signal read(string data)

	property string _buffer: ""

	function _reset() { _buffer = ""; }

	function _feed(data) {
		_buffer += data;
		let at;
		while ((at = _buffer.indexOf(splitMarker)) !== -1) {
			const piece = _buffer.substring(0, at);
			_buffer = _buffer.substring(at + splitMarker.length);
			read(piece);
		}
	}

	function _finish() {
		if (_buffer !== "") {
			const rest = _buffer;
			_buffer = "";
			read(rest);
		}
	}
}
