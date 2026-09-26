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
	property var _sessionEnv: undefined

	/** True while greetd is authenticating on our behalf */
	property bool _active: false

	/** False when the greeter is not running under greetd */
	readonly property bool available: Greetd.available

	/** Issued when bad password is provided */
	signal failure()

	/** Greetd issued a message, `error` is true for PAM error messages and greetd errors */
	signal message(message: string, error: bool)

	/**
	 * Start a login attempt
	 *
	 * @param user {object} (org.freedesktop.Account) user object as key-value pairs
	 * @param password {string} String with password to use
	 * @param session {object} Session entry: name, path and props (the .desktop file as key-value pairs)
	 */
	function login(user: var, password: string, session: var) {
		root._username = user.UserName;
		root._password = password;
		root._sessionExec = session.props.Exec;
		root._sessionEnv = root.sessionEnvironment(session);
		root._active = true;
		Greetd.createSession(root._username);
	}

	/**
	 * Environment for the launched session, as other greeters set it:
	 * the session type, the desktop names from the .desktop file and
	 * the file's own name. greetd itself only sets the seat and VT.
	 */
	function sessionEnvironment(session: var) {
		const env = ["XDG_SESSION_TYPE=wayland"];
		const desktops = session.props.DesktopNames;
		if (desktops) {
			env.push("XDG_CURRENT_DESKTOP=" + desktops.replace(/;+$/, "").split(";").join(":"));
		}
		const file = session.path.split("/").pop().replace(/\.desktop$/, "");
		if (file) {
			env.push("XDG_SESSION_DESKTOP=" + file);
		}
		return env;
	}

	/** Clear internal state and cancel the greetd session */
	function clear() {
		root._active = false;
		root._username = undefined;
		root._password = undefined;
		root._sessionExec = undefined;
		root._sessionEnv = undefined;
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
			} else {
				// Info or error message: show it, the conversation continues
				// (an error is normally followed by an auth failure)
				root.message(message, error);
			}
		}

		function onError(error) {
			// greetd refused a request (for example the session failed to
			// start); quickshell has already dropped the session
			console.error("greetd error: " + error);
			root.clear();
			root.message(error, true);
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
			Greetd.launch([root._sessionExec], root._sessionEnv);
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
