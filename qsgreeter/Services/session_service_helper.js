/**
 * Parse contents from a .desktop file
 *
 * @param contents {string} Plain text contents of the file
 * @return {Object} An object with the parsed key-value pairs
 */
function parseDesktopFile(contents) {
	const result = {};
	if (!contents || typeof contents !== "string") {
		return result;
	}

	const lines = contents.split(/\r?\n/);
	const keyValueRegex = /^\s*([a-zA-Z0-9\-\[\]@_]+)\s*=\s*(.*)$/;

	// Only the main group counts, [Desktop Action ...] groups have their own Name and Exec
	let inEntry = false;
	for (let line of lines) {
		line = line.trim();

		// Skip comments
		if (!line || line.startsWith("#")) {
			continue;
		}

		// Group header
		if (line.startsWith("[")) {
			inEntry = (line === "[Desktop Entry]");
			continue;
		}
		if (!inEntry) {
			continue;
		}

		// Get Key=value pairs
		const match = line.match(keyValueRegex);
		if (!match) continue;

		result[match[1].trim()] = match[2].trim();
	}

	return result;
}

/**
 * Name of a session for the given locale: Name[lang_COUNTRY], then
 * Name[lang], then Name
 *
 * @param props {Object} Parsed .desktop file
 * @param localeName {string} Locale name such as "es_ES"
 * @return {string} Display name, empty when the file has none
 */
function localizedName(props, localeName) {
	const full = localeName.replace(/[.@].*$/, "");
	const lang = full.split("_")[0];
	return props["Name[" + full + "]"] ?? props["Name[" + lang + "]"] ?? props.Name ?? "";
}
