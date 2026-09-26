import QtQuick
import QtQuick.Controls

import qs.Theme

/**
 * CustomButton.qml
 * Base style button for IconButton and TextButton
 */
Button {
	id: root

	/** Button colorscheme (inactive, hover, pressed) */
	property ButtonColors theme: ButtonColors {}

	/** Override default radius */
	property alias radius: backgroundRect.radius

	hoverEnabled: true

	// Reachable with Tab, but a click leaves keyboard focus where it was
	focusPolicy: Qt.TabFocus

	icon.color: root.theme.foreground.inactive
	palette.buttonText: root.theme.foreground.inactive

	// A focused Button only reacts to Space; Return and the keypad's Enter
	// activate it too, as they select a user and submit the password
	Keys.onReturnPressed: root.clicked()
	Keys.onEnterPressed: root.clicked()

	background: Rectangle {
		id: backgroundRect
		radius: (Math.max(root.height, root.width) / 2)
		color: root.theme.background.inactive

		/* Keyboard focus ring, only when focus came from the keyboard */
		border.width: root.visualFocus ? Theme.style.borderWidth : 0
		border.color: Theme.colors.primary

		Behavior on color {
			ColorAnimation {
				duration: Theme.style.animationSpeedShort
			}
		}
	}

	states: [
		State {
			name: "hover"
			when: root.hovered && !root.pressed

			PropertyChanges {
				backgroundRect.color: root.theme.background.hover
				root.icon.color: root.theme.foreground.hover
				root.palette.buttonText: root.theme.foreground.hover
			}
		},
		State {
			name: "pressed"
			when: root.pressed

			PropertyChanges {
				backgroundRect.color: root.theme.background.pressed
				root.icon.color: root.theme.foreground.pressed
				root.palette.buttonText: root.theme.foreground.pressed
			}
		}
	]
}
