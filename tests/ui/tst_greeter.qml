import QtQuick
import QtTest

import Quickshell.Services.Greetd
import qs.L10n

import "stubs/Quickshell/Io/env.js" as Env
import "stubs/Quickshell/Io/fakesystem.js" as System

/*
 * Runs the real greeter against the stub Quickshell and greetd modules and
 * drives it like a user: pick a user, get the password wrong, then right.
 * A failed check means the greeter did not reach a usable state or lost
 * keyboard focus on the way. Known, non-blocking problems can be printed
 * with the HARNESS-WARNING marker, which run.sh turns into annotations.
 */
TestCase {
	id: tc
	name: "Greeter"

	property var shell: null

	/** Last step that completed; later steps are skipped after a failure */
	property int reached: 0

	/** Step being run, 0 when it was skipped */
	property int attempting: 0

	function needStep(step) {
		tc.attempting = 0;
		if (tc.reached < step - 1) {
			skip("an earlier step failed");
		}
		tc.attempting = step;
	}

	/* A step that started but did not finish failed: keep what the screen showed. */
	function cleanup() {
		if (tc.attempting > 0 && tc.reached < tc.attempting && tc.shell) {
			let done = false;
			tc.shell.contentItem.grabToImage(function(result) {
				result.saveToFile(Env.screenshotsDir + "/failed-step-" + tc.attempting + ".png");
				done = true;
			});
			tryVerify(() => done, 5000);
		}
		tc.attempting = 0;
	}

	/** Visible, and not faded out by any ancestor */
	function shown(item) {
		let opacity = 1;
		for (let i = item; i; i = i.parent) {
			if (!i.visible) {
				return false;
			}
			opacity *= i.opacity;
		}
		return opacity > 0.99;
	}

	function findAll(predicate) {
		const found = [];
		const walk = function(item) {
			if (predicate(item)) {
				found.push(item);
			}
			for (let i = 0; i < item.children.length; i++) {
				walk(item.children[i]);
			}
		};
		walk(tc.shell.contentItem);
		return found;
	}

	function userButtons() {
		return findAll(i => i.realName !== undefined && i.iconPath !== undefined && tc.shown(i));
	}

	function passwordField() {
		return findAll(i => i.echoMode === TextInput.Password && i.placeholderText !== undefined
			&& tc.shown(i))[0] ?? null;
	}

	function sessionPicker() {
		return findAll(i => i.textRole !== undefined && i.displayText !== undefined && tc.shown(i))[0] ?? null;
	}

	function shownText(text) {
		return findAll(i => i.text === text && i.font !== undefined && tc.shown(i)).length > 0;
	}

	function greetdCalls(name) {
		return Greetd.calls.filter(c => c.call === name);
	}

	/** Save the window as <screenshotsDir>/<name>.png */
	function screenshot(name) {
		let done = false;
		let saved = false;
		waitForRendering(tc.shell.contentItem);
		tc.shell.contentItem.grabToImage(function(result) {
			saved = result.saveToFile(Env.screenshotsDir + "/" + name + ".png");
			done = true;
		});
		tryVerify(() => done, 5000, "screenshot " + name + " was never grabbed");
		verify(saved, "could not save screenshot " + name);
	}

	function type(text) {
		for (const ch of text) {
			keyClick(ch);
		}
	}

	function initTestCase() {
		const component = Qt.createComponent(Env.shellDir + "/shell.qml", Component.PreferSynchronous);
		verify(component.status === Component.Ready, "shell.qml did not load: " + component.errorString());
		tc.shell = component.createObject(null);
		verify(tc.shell !== null, "shell.qml could not be created");
		tryVerify(() => tc.shell.visible && tc.shell.contentItem.width > 0, 5000, "the greeter window never appeared");
		tc.shell.requestActivate();
		tryVerify(() => tc.shell.active, 5000, "the greeter window never became active");
	}

	function test_1_user_select() {
		tc.needStep(1);
		tryVerify(() => tc.userButtons().length === System.users.length, 10000,
			"the user list never showed the " + System.users.length + " users (stuck on the spinner or the error box?)");
		compare(tc.userButtons().map(b => b.realName).sort(), System.users.map(u => u.RealName).sort());
		tryVerify(() => tc.userButtons().some(b => b.activeFocus), 5000,
			"no user button has keyboard focus on the user list, so Enter does nothing");
		tc.screenshot("01-user-select");
		tc.reached = 1;
	}

	function test_2_login_screen() {
		tc.needStep(2);
		const alice = tc.userButtons().find(b => b.realName === "Alice Example");
		mouseClick(alice);
		tryVerify(() => tc.passwordField() !== null, 5000, "clicking a user did not show a password field");
		tryVerify(() => tc.sessionPicker() !== null && tc.sessionPicker().displayText === "Hyprland", 5000,
			"the session picker never offered the Hyprland session");
		tryVerify(() => tc.passwordField().activeFocus, 5000,
			"the password field does not have keyboard focus after choosing a user, so typing goes nowhere");
		tc.screenshot("02-login");
		tc.reached = 2;
	}

	function test_3_wrong_password() {
		tc.needStep(3);
		mouseClick(tc.passwordField());
		tryVerify(() => tc.passwordField().activeFocus, 5000, "clicking the password field did not focus it");
		tc.type("wrong");
		compare(tc.passwordField().text, "wrong", "typing did not reach the password field");
		keyClick(Qt.Key_Return);

		tryVerify(() => tc.greetdCalls("createSession").length === 1, 5000, "Enter did not start a greetd session");
		compare(tc.greetdCalls("createSession")[0].args[0], "alice");
		tryVerify(() => tc.greetdCalls("respond").length === 1, 5000, "the greeter never answered the password prompt");
		compare(tc.greetdCalls("respond")[0].args[0], "wrong");
		tryVerify(() => Greetd.state === Greetd.Inactive, 5000, "the failed attempt did not end the greetd session");
		tryVerify(() => tc.shownText(L10n.passwordError), 5000, "no \"" + L10n.passwordError + "\" message after a wrong password");
		verify(tc.passwordField() !== null && tc.passwordField().enabled, "the password field is gone after a failed login");
		compare(tc.passwordField().text, "", "the rejected password was left in the field");
		verify(tc.passwordField().activeFocus, "the password field lost keyboard focus after a failed login");
		tc.screenshot("03-wrong-password");
		tc.reached = 3;
	}

	function test_4_login() {
		tc.needStep(4);
		mouseClick(tc.passwordField());
		tryVerify(() => tc.passwordField().activeFocus, 5000, "the password field cannot be focused after a failed login");
		keyClick(Qt.Key_A, Qt.ControlModifier);
		tc.type(Greetd.password);
		compare(tc.passwordField().text, Greetd.password, "could not retype the password");
		keyClick(Qt.Key_Return);

		tryVerify(() => Greetd.launchedCommand !== null, 5000, "a correct password did not launch a session");
		compare(tc.greetdCalls("createSession").length, 2);
		compare(tc.greetdCalls("createSession")[1].args[0], "alice");
		compare(tc.greetdCalls("respond")[1].args[0], Greetd.password);
		compare(Greetd.launchedCommand, ["Hyprland"]);
		verify(Greetd.launchedEnvironment.indexOf("XDG_SESSION_TYPE=wayland") !== -1,
			"the session was launched without XDG_SESSION_TYPE: " + JSON.stringify(Greetd.launchedEnvironment));
		verify(Greetd.launchedEnvironment.indexOf("XDG_CURRENT_DESKTOP=Hyprland") !== -1,
			"the session was launched without XDG_CURRENT_DESKTOP from DesktopNames: " + JSON.stringify(Greetd.launchedEnvironment));
		tc.reached = 4;
	}

	function cleanupTestCase() {
		const power = System.commands.filter(c => c.command[0] === "systemctl");
		verify(power.length === 0, "the greeter ran a power command: " + JSON.stringify(power));
	}
}
