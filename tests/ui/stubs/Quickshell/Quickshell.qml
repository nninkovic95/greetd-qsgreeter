pragma Singleton

import QtQuick

import "Io/env.js" as Env

/* Stub of Quickshell's global singleton: only what the greeter reads. */
QtObject {
	/** Directory holding shell.qml, without a trailing slash */
	readonly property string shellDir: Env.shellDir
}
