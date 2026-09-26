pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

import qs.Theme

/**
 * UserSelection.qml
 *
 * Show an `UserList.qml` to choose an user, and then
 * show the `UserLogin.qml` for the selected user
 */
Item {
	id: root

	/** User object when selected, or undefined for displaying list of users */
	property var user: undefined

	/* List of users */
	Component {
		id: userList
		FocusScope {
			UserList {
				anchors.centerIn: parent
				onSelected: function(user) {
					root.user = user;
					// The page keeps its own copy: a page left with Back is
					// still fading out while the next one can be pushed
					stack.push(userLogin, { user: user });
				}
			}
		}
	}

	/* Password prompt for selected user */
	Component {
		id: userLogin
		FocusScope {
			id: loginPage

			/** User this page was pushed for */
			required property var user

			UserLogin {
				user: loginPage.user
				anchors.centerIn: parent

				// Back to the list: nobody is selected any more
				onCancel: {
					root.user = undefined;
					stack.pop();
				}
			}
		}
	}

	StackView {
		id: stack
		initialItem: userList

		/* Animations */
		pushEnter: Transition {
			NumberAnimation {
				property: "opacity"
				easing.type: Easing.InQuint
				duration: Theme.style.animationSpeedLarge
				from: 0.0
				to: 1.0
			}

			NumberAnimation {
				property: "scale"
				easing.type: Easing.InCubic
				duration: Theme.style.animationSpeedLarge
				from: (1 - Theme.style.animationBounce)
				to: 1.0
			}
		}

		pushExit: Transition {
			NumberAnimation {
				property: "opacity"
				easing.type: Easing.OutQuint
				duration: Theme.style.animationSpeedLarge
				from: 1.0
				to: 0.0
			}
		}

		popExit: Transition {
			NumberAnimation {
				property: "opacity"
				easing.type: Easing.OutQuint
				duration: Theme.style.animationSpeedLarge
				from: 1.0
				to: 0.0
			}

			NumberAnimation {
				property: "scale"
				easing.type: Easing.OutCubic
				duration: Theme.style.animationSpeedLarge
				from: 1.0
				to: (1 - Theme.style.animationBounce)
			}
		}

		popEnter: Transition {
			NumberAnimation {
				property: "opacity"
				easing.type: Easing.InQuint
				duration: Theme.style.animationSpeedLarge
				from: 0.0
				to: 1.0
			}
		}
	}
}
