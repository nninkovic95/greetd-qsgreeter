/**
 * Output from GDBUS call looks something like this:
 * `([objectpath '/org/freedesktop/Accounts/User1000'],)`
 *
 * This function parses those names into actual D-Bus
 * paths to gather user info
 *
 * @param {string} stdout `gdbus call` raw output
 * @returns {string[]} array of paths
 */
function parseUserList(stdout) {
	if (!stdout || typeof stdout !== "string") return [];
	const pathRegex = /'([^']+)'/g;
	const paths = [];
	let match;
	while ((match = pathRegex.exec(stdout)) !== null) {
		paths.push(match[1]);
	}
	return paths;
}

/**
 * Output from `gdbus call ... GetAll` is a GVariant text dump such as
 * `({'Uid': <uint64 1000>, 'RealName': <"Dana O'Brien">, ...},)`.
 * Parse the top-level keys into a json object.
 *
 * Values are scanned bracket by bracket, skipping quoted strings, so a
 * `>` or a quote inside a value (nested dictionaries, names with an
 * apostrophe) does not derail the keys after it.
 *
 * @param {string} stdout `gdbus call` raw output
 */
function parseUserData(stdout) {
	const user = {};
	if (!stdout || typeof stdout !== "string") return user;

	// match 'Key': < and scan to the matching >
	const keyRegex = /'([^']+)':\s*</g;
	let match;
	while ((match = keyRegex.exec(stdout)) !== null) {
		const start = keyRegex.lastIndex;
		let i = start;
		let depth = 1;
		let quote = null;
		for (; i < stdout.length && depth > 0; i++) {
			const c = stdout[i];
			if (quote) {
				if (c === "\\") i++;
				else if (c === quote) quote = null;
			} else if (c === "'" || c === '"') {
				quote = c;
			} else if (c === "<") {
				depth++;
			} else if (c === ">") {
				depth--;
			}
		}
		user[match[1]] = parseValue(stdout.slice(start, i - 1).trim());
		keyRegex.lastIndex = i;
	}

	return user;
}

/**
 * Convert one GVariant text value
 *
 * @param {string} val Text between < and >
 */
function parseValue(val) {
	const quote = val[0];
	// Strings, single or double quoted, with backslash escapes
	if ((quote === "'" || quote === '"') && val.length >= 2 && val.endsWith(quote)) {
		return val.slice(1, -1).replace(/\\(.)/g, function(_, c) {
			return c === "n" ? "\n" : (c === "t" ? "\t" : c);
		});
	}
	// Booleans
	if (val === "true" || val === "false") {
		return (val === "true");
	}
	// Numbers, optionally typed: <1>, <uint64 1000>, <int64 -5>, <double 0.5>
	const num = val.match(/^(?:[a-z0-9]+\s+)?(-?\d+(?:\.\d+)?)$/);
	if (num) {
		return Number(num[1]);
	}
	// Keep as string for fallback
	return val;
}
