import QtQuick

/** 
 * Style.qml
 * Styling properties from configuration file
 */
QtObject {
	id: root

	// Multiply every numeric value by this percentage (except animations)
	property real scale: 1.0

	// Use the locale for clock format, if false use 24 hrs format
	property bool clockLocale: false

	// Text font for clock
	property string fontFamilyHeading: "monospace"

	// Text font for regular text
	property string fontFamilyParagraph: "sans-serif"

	// Text size for clock
	property int fontSizeHeading: 55

	// Text font size for regular text
	property int fontSizeParagraph: 16

	// When set to false, borders are not drawn, instead
	// task is delegated to compositor
	property bool borderEnable: false
	
	// Outer window border (applies to dialogs and comboboxes)
	property int borderWidth: 2

	// Outer window border radius (applies to dialogs and comboboxes)
	property int borderRadius: 10

	// Space between elements and border
	property int borderMargin: 40

	// Size of the bottom poweroff/reboot buttons
	property int buttonSize: 50
	
	// Space between action buttons
	property int buttonSpacing: 15

	// Spacing between account icons
	property int accountSpacing: 30

	// Size of the account icon
	property int accountSize: 150

	// Password/Session prompts 
	property int promptSpacing: 8

	// Password/Session prompt width
	property int promptSize: 200

	// Password/Session prompt padding between input and text
	property int promptInputPadding: 8

	// Password/Session prompt dialog border radius
	property int promptInputRadius: 10

	// Password/Session prompt border width
	property int promptInputBorderWidth: 1
	
	// Element scale grow and shrink on hover/click
	property real animationBounce: 0.2

	// Duration for short animations
	property int animationSpeedShort: 150

	// Duration for large animations
	property int animationSpeedLarge: 300

	/* Values behind the last applyScale(), raw and as written, keyed by property */
	property var _raw: ({})
	property var _scaled: ({})

	/**
	 * Apply scale to every numeric field (except scale itself and the
	 * animation timings). Safe to call again after a reload: a property
	 * still holding the value written last time is scaled from its
	 * remembered raw value rather than compounded.
	 *
	 * The fields are pixel sizes, so the result is rounded to whole pixels
	 * (an int property would otherwise truncate 2 * 0.4 to 0) and a size
	 * that was set never scales away completely: a 1 px border stays drawn.
	 */
	function applyScale() {
		const scale = root.scale;
		for (const prop in root) {
			const value = root[prop];
			if (typeof value !== "number" || prop === "scale" || prop.includes("animation")) {
				continue;
			}
			const raw = (prop in root._scaled && root._scaled[prop] === value) ? root._raw[prop] : value;
			root._raw[prop] = raw;
			root[prop] = (raw > 0) ? Math.max(1, Math.round(raw * scale)) : Math.round(raw * scale);
			root._scaled[prop] = root[prop];
		}
	}
}
