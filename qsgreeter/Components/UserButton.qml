import QtQuick
import QtQuick.Effects

import qs.Theme

/**
 * UserButton.qml
 * Show user icon in a circle with name below (or just the icon)
 */
Item {
	id: root

	/** Name to display below icon, if no icon is found then the first initial is used instead */
	required property string realName

	/** Path to icon to display, if null or invalid show user initials instead */
	required property string iconPath

	/** When false the button ignores input and hides the name, acting as a picture only */
	property bool interactive: true

	/** Default colors when no `iconPath` is provided */
	property ButtonColors theme: ButtonColors {}

	/** Signal for button click */
	signal clicked

	implicitWidth: Theme.style.accountSize
	implicitHeight: Theme.style.accountSize

	/* Children */
	Rectangle {
		id: account
		anchors.fill: parent
		radius: (width / 2)
		color: root.theme.background.inactive

		/* Profile Image Fallback */
		Text {
			id: iconText
			text: (root.realName !== "") ? root.realName[0] : ""
			anchors.centerIn: parent
			color: root.theme.foreground.inactive
			font.family: Theme.style.fontFamilyParagraph
			font.pixelSize: (Math.min(parent.width, parent.height) / 2)
			visible: (face.status === Image.Error) || (face.status === Image.Null)
		}

		/* Profile Image, clipped to a circle by `mask` */
		Rectangle {
			id: mask
			anchors.fill: parent
			radius: (width / 2)
			visible: false
		}

		Image {
			id: face
			source: root.iconPath
			asynchronous: true
			visible: false
		}

		MultiEffect {
			anchors.fill: parent
			source: face
			maskEnabled: true
			maskSpreadAtMax: 1.0
			maskSpreadAtMin: 1.0
			maskThresholdMax: 1.0
			maskThresholdMin: 0.5
			maskSource: ShaderEffectSource {
				sourceItem: mask
			}
		}

		/* Animations */
		Behavior on color {
			ColorAnimation {
				duration: Theme.style.animationSpeedShort
			}
		}

		Behavior on scale {
			NumberAnimation {
				duration: Theme.style.animationSpeedLarge
				easing.type: Easing.OutQuad
			}
		}
	}

	Text {
		id: username
		visible: root.interactive
		anchors {
			top: account.bottom
			horizontalCenter: root.horizontalCenter
			topMargin: Theme.style.fontSizeParagraph + (account.height * (account.scale - 1)) / 2
		}
		text: root.realName
		color: root.theme.foreground.inactive
		font.family: Theme.style.fontFamilyParagraph
		font.pixelSize: Theme.style.fontSizeParagraph
	}

	/* Handle Mouse Events */
	HoverHandler {
		id: hover
		enabled: root.interactive
	}

	TapHandler {
		id: tap
		enabled: root.interactive
		onTapped: root.clicked()
	}

	/* States based on mouse movement, the base state is the resting look */
	states: [
		State {
			name: "hover"
			when: hover.hovered && !tap.pressed

			PropertyChanges {
				account.color: root.theme.background.hover
				account.scale: (1 + Theme.style.animationBounce)
				iconText.color: root.theme.foreground.hover
			}
		},
		State {
			name: "pressed"
			when: hover.hovered && tap.pressed

			PropertyChanges {
				account.color: root.theme.background.pressed
				account.scale: 1.0
			}
		}
	]
}
