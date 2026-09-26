import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Theme
import qs.L10n
import qs.Services

/**
 * UserLogin.qml
 * Show the login screen (password and session) for a selected user
 */
ColumnLayout {
	id: root

	/** User to show */
	required property var user

	/** Currently selected session, follows the picker and the list behind it */
	property var session: root.sessionService.sessions[sessionInput.currentIndex]

	/** Message to show above the prompt */
	property string message: ""

	/** The message is an error, keep it over the wrong-password text and show it in red */
	property bool messageError: false

	/** Wrong password animation */
	property bool badPassword: false

	/** Service for triggering login */
	property LoginService loginService: LoginService {
		onMessage: function(message, error) {
			root.message = message;
			root.messageError = error;
		}

		onFailure: {
			root.badPassword = true;
			passwordInput.clear();
			// An informational message gives way to the failure, an error stays
			if (!root.messageError) {
				root.message = "";
			}
		}
	}

	/** List Wayland sessions */
	property SessionService sessionService: SessionService {}

	/** When user cancels operation (back button) */
	signal cancel

	/** Function to get password prompt with username colored */
	function getUserPrompt(username) {
		// The prompt is styled text, keep the name literal
		const escaped = username.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
		const font = `<font color="${Theme.colors.primary}">${escaped}</font>`;
		return L10n.userPrompt.arg(font);
	}

	/** Make a login attempt with the typed password and the selected session */
	function submit() {
		root.message = "";
		root.messageError = false;
		if (!root.session) {
			root.message = L10n.sessionListError;
			root.messageError = true;
			return;
		}
		if (!root.loginService.available) {
			root.message = L10n.greetdUnavailable;
			root.messageError = true;
			return;
		}
		root.loginService.login(root.user, passwordInput.text, root.session);
	}

	/** Message text */
	Text {
		text: (root.message !== "") ? root.message : (root.badPassword ? L10n.passwordError : "")
		textFormat: Text.PlainText
		visible: root.badPassword || root.message !== ""
		Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
		Layout.bottomMargin: Theme.style.accountSpacing

		color: (root.badPassword || root.messageError) ? Theme.colors.error : Theme.colors.surfaceContrast
		font.family: Theme.style.fontFamilyParagraph
		font.pixelSize: Theme.style.fontSizeParagraph
	}

	RowLayout {
		Layout.alignment: Qt.AlignCenter
		spacing: Theme.style.accountSpacing

		/* Go Back Button */
		IconButton {
			source: Qt.resolvedUrl("../Assets/back.svg")
			onClicked: root.cancel()
		}

		/* User Face Icon */
		UserButton {
			realName: root.user ? root.user.DisplayName : ""
			iconPath: root.user ? root.user.IconFile : ""
			interactive: false

			Layout.preferredWidth: Theme.style.accountSize
			Layout.preferredHeight: Theme.style.accountSize
		}

		/* Prompt, promptSize wide unless its label needs more room (whole pixels, like an implicit size) */
		Column {
			Layout.preferredWidth: Math.max(Theme.style.promptSize, Math.ceil(prompt.implicitWidth))
			spacing: Theme.style.promptSpacing

			Text {
				id: prompt
				textFormat: Text.StyledText
				text: root.user ? root.getUserPrompt(root.user.UserName) : ""
				color: Theme.colors.surfaceContrast
				font.family: Theme.style.fontFamilyParagraph
				font.pixelSize: Theme.style.fontSizeParagraph
			}

			/* Password Prompt */
			RowLayout {
				width: parent.width
				spacing: Theme.style.promptSpacing

				/* Password Input Field */
				TextField {
					id: passwordInput
					Layout.fillWidth: true

					echoMode: TextInput.Password
					placeholderText: L10n.passwordPlaceholder

					padding: Theme.style.promptInputPadding
					color: root.badPassword ? Theme.colors.error : Theme.colors.primary

					background: InputBackground {
						selected: passwordInput.activeFocus
						border.color: root.badPassword
							? Theme.colors.error
							: (passwordInput.activeFocus ? Theme.colors.primary : Theme.colors.surfaceInactive)
					}

					placeholderTextColor: activeFocus
						? Theme.colors.primary
						: (root.badPassword ? Theme.colors.error : Theme.colors.surfaceInactive)

					onActiveFocusChanged: {
						if (activeFocus) {
							root.badPassword = false;
						}
					}

					onTextEdited: {
						root.badPassword = false;
					}

					onAccepted: root.submit()

					Component.onCompleted: {
						forceActiveFocus();
					}

					Behavior on color {
						ColorAnimation {
							duration: Theme.style.animationSpeedShort
						}
					}

					Behavior on placeholderTextColor {
						ColorAnimation {
							duration: Theme.style.animationSpeedShort
						}
					}
				}

				/* Login button */
				IconButton {
					Layout.maximumHeight: passwordInput.height
					radius: Theme.style.promptInputRadius
					source: Qt.resolvedUrl("../Assets/next.svg")
					onClicked: root.submit()
				}
			}

			/* Session picker */
			SessionPicker {
				id: sessionInput
				width: parent.width

				// Each session is an object, show its "name"
				model: root.sessionService.sessions
				textRole: "name"
			}
		}
	}
}
