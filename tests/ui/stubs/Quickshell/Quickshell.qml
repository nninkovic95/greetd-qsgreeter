pragma Singleton

import QtQuick

import "Io/env.js" as Env

/* Stub of Quickshell's global singleton: only what the greeter reads. */
QtObject {
	/** Directory holding shell.qml, without a trailing slash */
	readonly property string shellDir: Env.shellDir

	/** Environment variable, or null when unset; the test runs with none of the ones the greeter reads */
	function env(name) {
		return null;
	}
}
