pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Theme
import qs.Services
import qs.L10n

/**
 * UserList.qml
 *
 * Use `UserService` to display list of users
 */
Item {
	id: root

	/** User was selected, pass user object as param */
	signal selected(user: var)

	UserService {
		id: userService
	}

	states: [
		State {
			name: "busy"
			when: userService.busy
			PropertyChanges {
				busyComponent.opacity: 1
			}
		},
		State {
			name: "error"
			when: !userService.busy && userService.error
			PropertyChanges {
				errorComponent.opacity: 1
			}
		},
		State {
			name: "empty"
			when: !userService.busy && !userService.error && userService.ready && userService.users.length === 0
			PropertyChanges {
				emptyComponent.opacity: 1
			}
		},
		State {
			name: "ready"
			when: !userService.busy && !userService.error && userService.ready && userService.users.length > 0
			PropertyChanges {
				usersComponent.opacity: 1
			}
		}
	]

	transitions: Transition {
		NumberAnimation {
			property: "opacity"
			duration: Theme.style.animationSpeedShort
			easing.type: Easing.InOutQuad
		}
	}

	/* Spin indicator */
	BusyIndicator {
		id: busyComponent
		anchors.centerIn: parent
		width: Theme.style.accountSize
		height: Theme.style.accountSize
		opacity: 0
	}

	/* Error message */
	Placeholder {
		id: errorComponent
		anchors.centerIn: parent
		opacity: 0
		text: L10n.userListError
		padding: 40
	}

	/* No accounts message */
	Placeholder {
		id: emptyComponent
		anchors.centerIn: parent
		opacity: 0
		text: L10n.userListEmpty
	}

	/* Actual list of users */
	RowLayout {
		id: usersComponent
		anchors.centerIn: parent
		spacing: Theme.style.accountSpacing
		opacity: 0

		Repeater {
			model: userService.users
			delegate: UserButton {
				required property int index
				required property var modelData

				realName: modelData.DisplayName
				iconPath: modelData.IconFile

				Layout.preferredWidth: Theme.style.accountSize
				Layout.preferredHeight: Theme.style.accountSize

				onClicked: root.selected(modelData)

				// Default enter action, Return and the keypad's Enter
				Keys.onReturnPressed: root.selected(modelData)
				Keys.onEnterPressed: root.selected(modelData)

				// Focus the first user so Enter selects it
				Component.onCompleted: {
					if (index === 0) {
						forceActiveFocus();
					}
				}
			}
		}
	}
}
