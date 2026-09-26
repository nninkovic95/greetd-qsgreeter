import QtQuick

import "fakesystem.js" as System

/*
 * Stub of Quickshell's FileView. Reads through XMLHttpRequest (the runner
 * sets QML_XHR_ALLOW_FILE_READ), with session files redirected to fixtures.
 * Loads once the component is complete and whenever `path` changes.
 */
QtObject {
	id: root

	property string path: ""
	property bool preload: true
	property bool blockLoading: false
	property bool watchChanges: false
	property bool printErrors: true

	signal loaded()
	signal fileChanged()
	signal loadFailed(int error)

	property bool _completed: false
	property string _text: ""

	function text() { return root._text; }
	function reload() { root._load(); }

	function _load() {
		if (root.path === "") {
			return;
		}
		const file = System.resolve(root.path);
		const xhr = new XMLHttpRequest();
		xhr.onreadystatechange = function() {
			if (xhr.readyState !== XMLHttpRequest.DONE) {
				return;
			}
			if (xhr.status === 200 || (xhr.status === 0 && xhr.responseText !== "")) {
				root._text = xhr.responseText;
				root.loaded();
			} else {
				console.warn("FileView stub: cannot read " + file);
				root.loadFailed(1);
			}
		};
		xhr.open("GET", "file://" + file);
		xhr.send();
	}

	onPathChanged: {
		if (root._completed) {
			root._load();
		}
	}

	Component.onCompleted: {
		root._completed = true;
		root._load();
	}
}
