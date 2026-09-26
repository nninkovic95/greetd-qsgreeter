pragma Singleton

import QtQuick

/*
 * Stub of Quickshell's Greetd singleton, with one PAM conversation: a secret
 * "Password:" prompt, then success for `password` and failure for anything
 * else. Replies arrive on a later event loop turn, as they would from greetd.
 * Like Quickshell, createSession is ignored unless no session is in progress,
 * and launch unless the session is ready to launch.
 */
QtObject {
	id: root

	enum State { Inactive, Authenticating, ReadyToLaunch, Launching }

	/** The password the fake PAM stack accepts */
	property string password: "hunter2"

	readonly property bool available: true
	property int state: Greetd.Inactive

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
		if (root.state !== Greetd.Inactive) {
			return;
		}
		root.state = Greetd.Authenticating;
		root._later(() => root.authMessage("Password: ", false, true, false));
	}

	function respond(response) {
		root._record("respond", [response]);
		if (root.state !== Greetd.Authenticating) {
			return;
		}
		root._later(() => {
			if (response === root.password) {
				root.state = Greetd.ReadyToLaunch;
				root.readyToLaunch();
			} else {
				root.state = Greetd.Inactive;
				root.authFailure("Authentication failure");
			}
		});
	}

	function cancelSession() {
		root._record("cancelSession", []);
		root.state = Greetd.Inactive;
	}

	function launch(command, environment, quit) {
		root._record("launch", [command]);
		if (root.state !== Greetd.ReadyToLaunch) {
			return;
		}
		root.state = Greetd.Launching;
		root.launchedCommand = command;
		root.launchedEnvironment = environment ?? [];
		root.launched();
	}
}
