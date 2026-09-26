import QtQuick
import QtQuick.Controls

import qs.Theme
import qs.Animations
import qs.L10n

/**
 * ConfirmDialog.qml
 * Show a dialog to confirm an operation
 */
Dialog {
	id: root

	/** Message to show */
	required property string message

	/** Item that had keyboard focus before the dialog opened, focus returns to it on close */
	property Item _focusBefore: null

	anchors.centerIn: parent
	modal: true

	padding: Theme.style.buttonSpacing

	background: Rectangle {
		color: Theme.colors.surface
		radius: Theme.style.borderRadius
		border.width: Theme.style.borderWidth
		border.color: Theme.colors.primary
	}

	enter: PopupEnterTransition {}
	exit: PopupExitTransition {}

	onAboutToShow: {
		const window = root.parent ? root.parent.Window.window : null;
		root._focusBefore = window ? window.activeFocusItem : null;
	}

	// Qt 6.6 leaves focus on the overlay after a modal popup closes
	onClosed: {
		if (root._focusBefore) {
			root._focusBefore.forceActiveFocus();
		}
	}

	Column {
		anchors.fill: parent
		spacing: Theme.style.buttonSpacing

		/* Header Text */
		Item {
			width: parent.width
			height: Theme.style.fontSizeParagraph

			Text {
				anchors.centerIn: parent
				text: L10n.dialogConfirmAction
				color: Theme.colors.primary
				font.family: Theme.style.fontFamilyParagraph
				font.pixelSize: Theme.style.fontSizeParagraph
			}
		}

		/* Dialog Contents */
		Text {
			text: root.message
			color: Theme.colors.surfaceContrast
			font.family: Theme.style.fontFamilyParagraph
			font.pixelSize: Theme.style.fontSizeParagraph
		}

		/* Buttons, full width so the row stays centered */
		Item {
			width: parent.width
			height: buttonRow.height

			Row {
				id: buttonRow
				anchors.centerIn: parent
				spacing: Theme.style.buttonSpacing

				TextButton {
					text: L10n.dialogCancel
					onClicked: root.reject()
					font.family: Theme.style.fontFamilyParagraph
					font.pixelSize: Theme.style.fontSizeParagraph
				}

				TextButton {
					text: L10n.dialogAccept
					onClicked: root.accept()
					font.family: Theme.style.fontFamilyParagraph
					font.pixelSize: Theme.style.fontSizeParagraph
				}
			}
		}
	}
}
