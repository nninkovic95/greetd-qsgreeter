import QtQuick
import Quickshell.Services.Greetd

/**
 * LoginService.qml
 * Service for managing login and launch
 */
QtObject {
	id: root

	/* State of the current login attempt, reset by clear() */
	property var _username: undefined
	property var _password: undefined
	property var _sessionExec: undefined

	/** True while greetd is authenticating on our behalf */
	property bool _active: false

	/** Issued when bad password is provided */
	signal failure()

	/** Greetd issued a message */
	signal message(message: string)

	/**
	 * Start a login attempt
	 *
	 * @param user {object} (org.freedesktop.Account) user object as key-value pairs
	 * @param password {string} String with password to use
	 * @param session {object} Session .desktop file as key-value pairs
	 */
	function login(user: var, password: string, session: var) {
		root._username = user.UserName;
		root._password = password;
		root._sessionExec = session.Exec;
		root._active = true;
		Greetd.createSession(root._username);
	}

	/** Clear internal state and cancel the greetd session */
	function clear() {
		root._active = false;
		root._username = undefined;
		root._password = undefined;
		root._sessionExec = undefined;
		Greetd.cancelSession();
	}

	/* Handle Greetd events */
	property Connections _greetdConnection: Connections {
		target: Greetd

		function onAuthMessage(message, error, responseRequired, echoResponse) {
			if (responseRequired) {
				// Answer prompts by kind, never by prompt text: secret prompts
				// (echoResponse false) get the stored password, visible ones
				// get an empty string
				Greetd.respond(echoResponse ? "" : root._password);
			} else if (!error) {
				// Informational message: show it, the conversation continues
				root.message(message);
			}
			// Error messages are ignored
		}

		function onAuthFailure(_) {
			console.error("Authentication failed for " + root._username);
			root.clear();
			root.failure();
		}

		function onReadyToLaunch() {
			console.log("Launching session " + root._sessionExec);
			// From here the session belongs to greetd, never cancel it
			root._active = false;
			Greetd.launch([root._sessionExec]);
		}
	}

	/*
	 * This service dies with the login page. If greetd is still
	 * authenticating, cancel: a success arriving afterwards would leave
	 * greetd in ReadyToLaunch with nobody to launch the session, and
	 * every later attempt would be ignored.
	 */
	Component.onDestruction: {
		if (root._active) {
			root.clear();
		}
	}
}
