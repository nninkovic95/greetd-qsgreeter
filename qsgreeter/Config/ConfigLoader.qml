import QtQuick
import Quickshell.Io

import "config.js" as Config

/**
 * ConfigLoader.qml
 * Load properties from a .json file into a QtObject type
 */
FileView {
	id: root

	/** Filename path */
	property alias src: root.path

	/** QtObject to apply JSON properties to */
	property QtObject target

	/** On object initialization finish */
	signal finished()

	preload: true
	blockLoading: true
	watchChanges: true

	onFileChanged: root.reload()
	onLoaded: {
		Config.apply(root.text(), root.target);
		root.finished();
	}
}
