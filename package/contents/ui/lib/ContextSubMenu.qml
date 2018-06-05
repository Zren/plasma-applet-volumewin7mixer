import QtQuick 2.0

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

// https://github.com/KDE/plasma-framework/blob/master/src/declarativeimports/plasmacomponents/qmenu.cpp
// Example: https://github.com/KDE/plasma-desktop/blob/master/applets/taskmanager/package/contents/ui/ContextMenu.qml
ContextMenuItem {
	id: subMenuItem

	property var subContextMenu: ContextMenu {
		id: subContextMenu

		visualParent: subMenuItem.action

		Component.onDestruction: {
			// console.log('subContextMenu.onDestruction', subContextMenu, subContextMenu.visualParent)
		}
	}
	Component.onDestruction: {
		// console.log('subMenuItem.onDestruction', subMenuItem)
	}

	function newSeperator() {
		return Qt.createQmlObject("ContextMenuItem { separator: true }", subContextMenu);
	}
	function newMenuItem() {
		return Qt.createQmlObject("ContextMenuItem {}", subContextMenu);
	}
	function newSubMenu() {
		return Qt.createQmlObject("ContextSubMenu {}", subContextMenu);
	}

	function addMenuItem(menuItem) {
		// console.log('addMenuItem', menuItem, menuItem.text)
		subContextMenu.addMenuItem(menuItem)
	}
}
