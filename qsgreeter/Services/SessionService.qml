pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import "session_service_helper.js" as Helper

/**
 * SessionService.qml
 * List Wayland sessions available for login
 */
QtObject {
	id: root

	/**
	 * List of session objects
	 *
	 * Object members:
	 *	- name {string} Display name of the session
	 *	- path {string} Path to the .desktop file
	 *	- props {object} .desktop file properties
	 */
	property var sessions: []

	/** Paths of the Wayland session .desktop files */
	property var paths: []

	/**
	 * Directories scanned for Wayland session files: the wayland-sessions
	 * directory of every entry in XDG_DATA_DIRS (or its default value)
	 */
	readonly property var sessionDirs: {
		const dataDirs = Quickshell.env("XDG_DATA_DIRS") || "/usr/local/share:/usr/share";
		return dataDirs.split(":").filter(dir => dir !== "").map(dir => dir.replace(/\/+$/, "") + "/wayland-sessions");
	}

	/** Reload list of available Wayland sessions */
	function reload() {
		root._procListSessions.running = true;
	}

	/** Add a session to the list */
	function _register(path: string, props: var) {
		console.log("Session successfully registered: " + props.Name);
		root.sessions.push({
			name: Helper.localizedName(props, Qt.locale().name),
			path: path,
			props: props
		});
		// Files load in any order, keep the default session stable across boots
		root.sessions.sort((a, b) => a.path.localeCompare(b.path));
		root.sessionsChanged();
	}

	/** Process to list the .desktop files (find keeps going when a directory is missing) */
	property Process _procListSessions: Process {
		command: ["find"].concat(root.sessionDirs, ["-maxdepth", "1", "-name", "*.desktop"])
		stdout: SplitParser {
			onRead: function(data) {
				root.paths.push(data);
			}
		}

		onStarted: {
			root.sessions = [];
			root.paths = [];
		}

		onExited: function(exitCode, exitStatus) {
			if (root.paths.length === 0) {
				console.error("No Wayland sessions found in " + root.sessionDirs.join(", "));
			}
			console.log("Found Wayland paths: " + root.paths);
			root.pathsChanged();
		}
	}

	/** Create workers that load the session files contents */
	property Instantiator _workerFactory: Instantiator {
		model: root.paths
		delegate: FileView {
			id: sessionFile

			required property string modelData

			/** Parsed file, kept for the TryExec check */
			property var props: ({})

			path: Qt.resolvedUrl(sessionFile.modelData)
			preload: true

			onLoaded: {
				sessionFile.props = Helper.parseDesktopFile(sessionFile.text());
				// Entries that ask not to be shown
				if (sessionFile.props.Hidden === "true" || sessionFile.props.NoDisplay === "true") {
					console.log("Session hidden: " + sessionFile.modelData);
					return;
				}
				// Entries whose program is not installed
				if (sessionFile.props.TryExec) {
					tryExec.running = true;
					return;
				}
				root._register(sessionFile.modelData, sessionFile.props);
			}

			/** Check TryExec with the shell's own lookup */
			property Process tryExec: Process {
				command: ["sh", "-c", "command -v -- \"$0\" >/dev/null 2>&1", sessionFile.props.TryExec ?? ""]

				onExited: function(exitCode, exitStatus) {
					if (exitCode === 0) {
						root._register(sessionFile.modelData, sessionFile.props);
					} else {
						console.log("Session skipped, TryExec not found: " + sessionFile.modelData);
					}
				}
			}
		}
	}

	/* Automatically load list of sessions */
	Component.onCompleted: {
		root.reload();
	}
}
