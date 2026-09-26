pragma ComponentBehavior: Bound

import QtQuick
import QtQml.Models
import Quickshell.Io

import "user_service_helper.js" as Helper

/**
 * UserService.qml
 * Service for gathering users and their information
 */
QtObject {
	id: root

	/* List of D-Bus user paths */
	property var paths: []

	/**
	 * Dynamic list of users
	 *
	 * Relevant Properties:
	 *	- Uid
	 *	- UserName
	 *	- RealName
	 *	- IconFile
	 */
	property var users: []

	property bool busy: true /**< Operations are pending */
	property bool ready: false /**< Users were loaded */
	property bool error: false /**< Unable to load users */

	/** Reload list of available system users */
	function reload() {
		root._procListCachedUsers.running = true;
	}

	/** Stop loading and report an error */
	function _fail(reason: string) {
		console.error(reason);
		root.busy = false;
		root.error = true;
		root.usersChanged();
	}

	/** Stop loading and publish the users gathered so far */
	function _finish() {
		console.log(`Finished parsing of <${ root.users.length }> users`);
		root.busy = false;
		root.ready = true;
		root.error = false;
		root.usersChanged();
	}

	/** Call org.freedesktop.Accounts#ListCachedUsers */
	property Process _procListCachedUsers: Process {
		id: listCachedUsers

		/* Set once the command has run, a command that cannot start never emits exited */
		property bool _exited: false

		command: [
			"gdbus", "call", "--system",
			"--dest", "org.freedesktop.Accounts",
			"--object-path", "/org/freedesktop/Accounts",
			"--method", "org.freedesktop.Accounts.ListCachedUsers"
		]
		stdout: StdioCollector {
			id: userListOutput
		}

		onStarted: {
			console.log("Retrieving list of users from D-Bus");
			listCachedUsers._exited = false;
			root.paths = [];
			root.users = [];
			root.busy = true;
			root.ready = false;
			root.error = false;
		}

		onExited: function(exitCode, exitStatus) {
			listCachedUsers._exited = true;
			if (exitCode !== 0) {
				root._fail("Unable to retrieve user list from D-Bus");
				return;
			}
			// Setting the paths starts one worker per user
			root.paths = Helper.parseUserList(userListOutput.text);
			console.log("Listed users: " + root.paths);
			// Nobody to wait for
			if (root.paths.length === 0) {
				root._finish();
			}
		}

		onRunningChanged: {
			if (!listCachedUsers.running && !listCachedUsers._exited) {
				root._fail("Unable to start gdbus, is glib2 installed?");
			}
		}
	}

	/** Call org.freedesktop.Accounts.User for each user */
	property Instantiator _workerFactory: Instantiator {
		model: root.paths
		delegate: Process {
			id: getUser

			required property string modelData

			running: true
			command: [
				"gdbus", "call", "--system",
				"--dest", "org.freedesktop.Accounts",
				"--method", "org.freedesktop.DBus.Properties.GetAll",
				"org.freedesktop.Accounts.User",
				"--object-path", getUser.modelData
			]
			stdout: StdioCollector {
				id: userDataOutput
			}

			onExited: function(exitCode, exitStatus) {
				if (exitCode !== 0) {
					root._fail("Failed to retrieve data for path: " + getUser.modelData);
					return;
				}
				root.users.push(Helper.parseUserData(userDataOutput.text));
				// Publish the list once every user has been parsed
				if (root.users.length >= root.paths.length) {
					root._finish();
				}
			}
		}
	}

	/* Automatically load list of users */
	Component.onCompleted: {
		root.reload();
	}
}
