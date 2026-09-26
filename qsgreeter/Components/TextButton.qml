import QtQuick
import QtQuick.Controls

import qs.Theme

/**
 * TextButton.qml
 * Pill-shaped button with a text label, i.e dialog Accept/Cancel
 */
CustomButton {
	padding: (Theme.style.buttonSize / 4)
	display: AbstractButton.TextOnly
}
