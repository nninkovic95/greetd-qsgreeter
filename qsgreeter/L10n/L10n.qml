pragma Singleton

import QtQuick
import Quickshell

import qs.Config

import "locale.js" as LocaleHelper

/**
 * L10n.qml
 * Global localization strings
 */
Singleton {
	id: l10n

	/* Defaults are English, a translation file overrides the keys it has */
	property string dateMessage: "Today is"
	property string dateFormat: "yyyy-MM-dd"
	property string dialogConfirmAction: "Confirm action"
	property string dialogAccept: "Accept"
	property string dialogCancel: "Cancel"
	property string dialogShutdown: "Are you sure you want to shutdown?"
	property string dialogReboot: "Are you sure you want to reboot?"
	property string userListError: "Unable to retrieve users from D-Bus"
	property string userListEmpty: "No user accounts found"
	property string userWelcome: "Welcome back, %1"
	property string userPrompt: "Login for %1"
	property string passwordPlaceholder: "Password"
	property string passwordError: "Wrong password"
	property string sessionListError: "No Wayland sessions found"

	ConfigLoader {
		target: l10n
		src: Quickshell.shellDir + "/" + LocaleHelper.getLocalePath()
	}
}
