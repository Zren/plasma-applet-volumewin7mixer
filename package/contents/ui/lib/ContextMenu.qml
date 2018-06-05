import QtQuick 2.0

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

// https://github.com/KDE/plasma-framework/blob/master/src/declarativeimports/plasmacomponents/qmenu.cpp
// Example: https://github.com/KDE/plasma-desktop/blob/master/applets/taskmanager/package/contents/ui/ContextMenu.qml
PlasmaComponents.ContextMenu {
	id: contextMenu

	function newSeperator() {
		return Qt.createQmlObject("ContextMenuItem { separator: true }", contextMenu);
	}
	function newMenuItem() {
		return Qt.createQmlObject("ContextMenuItem {}", contextMenu);
	}
	function newSubMenu() {
		return Qt.createQmlObject("ContextSubMenu {}", contextMenu);
	}

	property bool clearBeforeOpen: true
	signal beforeOpen(var menu)

	function removeAllItems() {
		// console.log('removeAllItems', contextMenu)

		// clearMenuItems() causes a segfault when trying to destroy a submenu.
		// So we need to manually destroy it as a workaround.
		for (var i = content.length-1; i >= 0; i--) {
			var item = content[i]
			var isSubMenu = item.hasOwnProperty("subContextMenu")
			// console.log(contextMenu, i, 'destroy', isSubMenu, item.text)
			if (isSubMenu) {
				item.subContextMenu.removeAllItems() // Probably only necessary for a sub-sub-menu.
				item.subContextMenu.destroy() // We need this or it will segfault on the 2nd open.
			}
			removeMenuItem(item) // We need this or it will segfault on the 3rd open.
			item.destroy()
		}
	}

	function doBeforeOpen() {
		// console.log('doBeforeOpen')
		// console.log('doBeforeOpen.content.length', content.length)
		if (clearBeforeOpen) {
			removeAllItems()
			// console.log('doBeforeOpen.clearMenuItems.done')
		}
		beforeOpen(contextMenu)
	}

	function show(x, y) {
		doBeforeOpen()
		open(x, y)
	}

	function showRelative() {
		doBeforeOpen()
		openRelative()
	}

	function showBelow(item) {
		visualParent = item
		placement = PlasmaCore.Types.BottomPosedLeftAlignedPopup
		showRelative()
	}

	Component.onDestruction: {
		// console.log('contextMenu.onDestruction', contextMenu)
	}
}
