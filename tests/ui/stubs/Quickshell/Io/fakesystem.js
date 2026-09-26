.pragma library

/*
 * The system the greeter sees under test: canned AccountsService replies,
 * the session directory listing, and where files are really read from.
 * Commands are recorded, never executed.
 */

.import "env.js" as Env

const sessionsDir = "/usr/share/wayland-sessions/";

const users = [
	{ path: "/org/freedesktop/Accounts/User1000", Uid: 1000, UserName: "alice", RealName: "Alice Example" },
	{ path: "/org/freedesktop/Accounts/User1001", Uid: 1001, UserName: "bob", RealName: "Bob Example" }
];

/** Every command the greeter asked for, in order: { command, detached } */
var commands = [];

function gdbusUser(user) {
	return "({'Uid': <uint64 " + user.Uid + ">, 'UserName': <'" + user.UserName + "'>, "
		+ "'RealName': <'" + user.RealName + "'>, 'IconFile': <''>, "
		+ "'SystemAccount': <false>, 'Locked': <false>},)\n";
}

/**
 * Run a command against the fake system.
 * @return {{stdout: string, exitCode: int}|null} null when the command does
 *         not exist, which Quickshell reports without an exit
 */
/** Value following `flag` in `command`, or undefined */
function option(command, flag) {
	const at = command.indexOf(flag);
	return at === -1 ? undefined : command[at + 1];
}

function run(command) {
	commands.push({ command: command.slice(), detached: false });
	const args = command.join(" ");

	// Match calls exactly, so a typo in the greeter's command fails the test.
	const accounts = command[0] === "gdbus" && command[1] === "call"
		&& command.indexOf("--system") !== -1
		&& option(command, "--dest") === "org.freedesktop.Accounts";
	const method = option(command, "--method");

	if (accounts && method === "org.freedesktop.Accounts.ListCachedUsers"
			&& option(command, "--object-path") === "/org/freedesktop/Accounts") {
		const paths = users.map(u => "objectpath '" + u.path + "'").join(", ");
		return { stdout: "([" + paths + "],)\n", exitCode: 0 };
	}
	if (accounts && method === "org.freedesktop.DBus.Properties.GetAll"
			&& command.indexOf("org.freedesktop.Accounts.User") !== -1) {
		const path = option(command, "--object-path");
		const user = users.find(u => u.path === path);
		return user ? { stdout: gdbusUser(user), exitCode: 0 }
		            : { stdout: "", exitCode: 1 };
	}
	if (command[0] === "find" && command.indexOf("-maxdepth") !== -1) {
		// find [-H] <dir>... -maxdepth 1 -name '*.desktop': list the fixture
		// directory, report the others as missing (exit code 1) the way find does
		const dirs = command.slice(1, command.indexOf("-maxdepth")).filter(arg => !arg.startsWith("-"));
		const known = dirs.filter(d => d + "/" === sessionsDir);
		return {
			stdout: known.map(d => d + "/hyprland.desktop\n").join(""),
			exitCode: known.length === dirs.length ? 0 : 1
		};
	}

	console.warn("fakesystem: no fixture for command: " + args);
	return null;
}

function runDetached(command) {
	commands.push({ command: command.slice(), detached: true });
}

/** Map a path the greeter reads to the file that stands in for it. */
function resolve(path) {
	let p = String(path);
	if (p.startsWith("file://")) {
		p = decodeURIComponent(p.substring(7));
	}
	if (p.startsWith(sessionsDir)) {
		return Env.fixturesDir + "/wayland-sessions/" + p.substring(sessionsDir.length);
	}
	return p;
}
