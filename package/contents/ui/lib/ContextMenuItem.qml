import QtQuick 2.0

import org.kde.plasma.components 2.0 as PlasmaComponents

PlasmaComponents.MenuItem {
	id: contextMenuItem

	Component.onDestruction: {
		// console.log('contextMenuItem.onDestruction', contextMenuItem, contextMenuItem.visualParent)
	}
}
