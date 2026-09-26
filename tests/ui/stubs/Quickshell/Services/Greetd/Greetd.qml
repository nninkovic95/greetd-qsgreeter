pragma Singleton

import QtQuick

/*
 * Stub of Quickshell's Greetd singleton, with one PAM conversation: a secret
 * "Password:" prompt, then success for `password` and failure for anything
 * else. Replies arrive on a later event loop turn, as they would from greetd.
 * Like Quickshell, createSession is ignored unless no session is in progress,
 * and launch unless the session is ready to launch. A failed attempt is
 * followed by greetd's usual reply to the cancel Quickshell then sends (the
 * PAM worker has already exited), which Quickshell forwards as `error`.
 */
QtObject {
	id: root

	/** The password the fake PAM stack accepts */
	property string password: "hunter2"

	/** What greetd answers to the cancel_session that follows a failed attempt */
	readonly property string cancelError: "unable to send message: Connection refused (os error 111)"

	readonly property bool available: true
	property int state: GreetdState.Inactive

	/** Every call the greeter made, in order: { call, args } */
	property var calls: []

	/** The command passed to a successful launch(), or null */
	property var launchedCommand: null

	/** The environment passed with it, or null */
	property var launchedEnvironment: null

	signal authMessage(string message, bool error, bool responseRequired, bool echoResponse)
	signal authFailure(string message)
	signal readyToLaunch()
	signal launched()
	signal error(string message)

	property var _queue: []
	property Timer _tick: Timer {
		interval: 0
		onTriggered: {
			const pending = root._queue;
			root._queue = [];
			pending.forEach(fn => fn());
		}
	}

	function _later(fn) {
		root._queue.push(fn);
		root._tick.start();
	}

	function _record(call, args) {
		root.calls.push({ call: call, args: args });
		root.callsChanged();
	}

	function createSession(user) {
		root._record("createSession", [user]);
		if (root.state !== GreetdState.Inactive) {
			return;
		}
		root.state = GreetdState.Authenticating;
		root._later(() => root.authMessage("Password: ", false, true, false));
	}

	function respond(response) {
		root._record("respond", [response]);
		if (root.state !== GreetdState.Authenticating) {
			return;
		}
		root._later(() => {
			if (response === root.password) {
				root.state = GreetdState.ReadyToLaunch;
				root.readyToLaunch();
			} else {
				root.state = GreetdState.Inactive;
				root.authFailure("Authentication failure");
				// Quickshell cancels the session on a failure; greetd's reply
				// to that cancel arrives once the greeter has handled the failure
				root._later(() => root.error(root.cancelError));
			}
		});
	}

	function cancelSession() {
		root._record("cancelSession", []);
		root.state = GreetdState.Inactive;
	}

	function launch(command, environment, quit) {
		root._record("launch", [command]);
		if (root.state !== GreetdState.ReadyToLaunch) {
			return;
		}
		root.state = GreetdState.Launching;
		root.launchedCommand = command;
		root.launchedEnvironment = environment ?? [];
		root.launched();
	}
}
