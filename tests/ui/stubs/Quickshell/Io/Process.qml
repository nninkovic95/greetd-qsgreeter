import QtQuick

import "fakesystem.js" as System

/*
 * Stub of Quickshell's Process. Starts when `running` becomes true (or is
 * true at completion), answers from the fake system on the next event loop
 * turn, feeds stdout, then emits `exited`. A command with no fixture never
 * emits `exited`, like a command Quickshell fails to start.
 */
QtObject {
	id: root

	property var command: []
	property bool running: false
	property var environment: ({})
	property string workingDirectory: ""
	property QtObject stdout: null
	property QtObject stderr: null

	signal started()
	signal exited(int exitCode, int exitStatus)

	property bool _completed: false
	property bool _pending: false

	property Timer _tick: Timer {
		interval: 0
		onTriggered: root._run()
	}

	function startDetached() {
		System.runDetached(root.command);
	}

	function _start() {
		if (root._pending) {
			return;
		}
		root._pending = true;
		root._tick.start();
	}

	function _run() {
		root._pending = false;
		const result = System.run(root.command);
		if (result === null) {
			root.running = false;
			return;
		}
		if (root.stdout) {
			root.stdout._reset();
		}
		root.started();
		if (root.stdout) {
			root.stdout._feed(result.stdout);
			root.stdout._finish();
		}
		root.running = false;
		root.exited(result.exitCode, 0);
	}

	onRunningChanged: {
		if (root.running && root._completed) {
			root._start();
		}
	}

	Component.onCompleted: {
		root._completed = true;
		if (root.running) {
			root._start();
		}
	}
}
