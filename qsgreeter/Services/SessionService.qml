pragma ComponentBehavior: Bound

import QtQuick
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

	/** Directory scanned for Wayland session files */
	readonly property string sessionsDir: "/usr/share/wayland-sessions/"

	/** Reload list of available Wayland sessions */
	function reload() {
		root._procListSessions.running = true;
	}

	/** Process to list the session files */
	property Process _procListSessions: Process {
		command: ["ls", "-1", root.sessionsDir]
		stdout: SplitParser {
			onRead: function(data) {
				root.paths.push(root.sessionsDir + data);
			}
		}

		onStarted: {
			root.sessions = [];
			root.paths = [];
		}

		onExited: function(exitCode, exitStatus) {
			if (exitCode !== 0 || root.paths.length === 0) {
				console.error("No Wayland sessions found in " + root.sessionsDir);
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

			path: Qt.resolvedUrl(sessionFile.modelData)
			preload: true

			onLoaded: {
				const props = Helper.parseDesktopFile(sessionFile.text());
				console.log("Session successfully registered: " + props.Name);
				root.sessions.push({
					name: props.Name ?? "",
					path: sessionFile.modelData,
					props: props
				});
				// Files load in any order, keep the default session stable across boots
				root.sessions.sort((a, b) => a.path.localeCompare(b.path));
				root.sessionsChanged();
			}
		}
	}

	/* Automatically load list of sessions */
	Component.onCompleted: {
		root.reload();
	}
}
