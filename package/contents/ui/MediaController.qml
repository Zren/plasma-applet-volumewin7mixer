import QtQuick 2.4
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0
import QtQuick.Controls.Styles.Plasma 2.0 as PlasmaStyles

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kcoreaddons 1.0 as KCoreAddons

Item {
	id: mediaController
	property bool disablePositionUpdate: false
	property bool keyPressed: false

	Item {
		anchors.fill: parent
		anchors.topMargin: seekRow.height

		Item {
		// PlasmaComponents.ToolButton {
			anchors.fill: parent
			anchors.rightMargin: rightSide.width
			// enabled: mpris2Source.canRaise
			// onClicked: {
			// 	mpris2Source.raise()
			// 	if (plasmoid.hideOnWindowDeactivate) {
			// 		plasmoid.expanded = false
			// 	}
			// }

			Item {
				id: albumArtContainer
				anchors.left: parent.left
				width: height
				height: parent.height

				PlasmaCore.IconItem {
					id: playerIcon
					anchors.fill: parent
					source: mpris2Source.playerIcon
				}

				Image {
					id: albumArt
					anchors.fill: parent
					source: mpris2Source.albumArt
					asynchronous: true
					fillMode: Image.PreserveAspectCrop
					sourceSize: Qt.size(width, height)
					visible: !!mpris2Source.track && status === Image.Ready
				}
			}

			Column {
				id: leftSide
				anchors.fill: parent
				anchors.leftMargin: albumArtContainer.width + (4 * PlasmaCore.Units.devicePixelRatio)
				// anchors.rightMargin: rightSide.width

				// MediaControllerCompact's style
				PlasmaComponents.Label {
					id: track
					width: parent.width
					opacity: 0.9
					height: parent.height / 2

					elide: Text.ElideRight
					text: mpris2Source.track
				}

				PlasmaComponents.Label {
					id: artist
					width: parent.width
					opacity: 0.7
					height: parent.height / 2

					elide: Text.ElideRight
					text: mpris2Source.artist
				}
			}
		}

		Row {
			id: rightSide
			width: childrenRect.width
			height: parent.height
			anchors.right: parent.right
			anchors.verticalCenter: parent.verticalCenter

			// Column {
			// 	width: height
			// 	height: parent.height
			// 	visible: mpris2Source.canGoNext

			// 	IconToolButton {
			// 		width: parent.height
			// 		height: parent.height / 2
			// 		enabled: mpris2Source.canLoop
			// 		source: {
			// 			if (mpris2Source.isLoopingTrack) {
			// 				return "media-repeat-single"
			// 			} else if (mpris2Source.isLoopingPlaylist) {
			// 				return "media-repeat-all"
			// 			} else {
			// 				return "media-repeat-none"
			// 			}
			// 		}
			// 		onClicked: mpris2Source.toggleLoopState()
			// 	}
			// 	 IconToolButton {
			// 		width: parent.height
			// 		height: parent.height / 2
					
			// 		enabled: mpris2Source.canShuffle
			// 		source: "shuffle"
			// 		iconOpacity: mpris2Source.isShuffling ? 1 : 0.5
			// 		onClicked: mpris2Source.toggleShuffle()
			// 	}
			// }
			
			PlasmaComponents.ToolButton {
				iconSource: "media-skip-backward"
				width: height
				height: parent.height
				enabled: mpris2Source.canGoPrevious
				onClicked: {
					seekSlider.value = 0 // Let the media start from beginning. Bug 362473 (org.kde.plasma.mediacontroller)
					mpris2Source.previous()
				}
			}
			PlasmaComponents.ToolButton {
				iconSource: mpris2Source.isPlaying ? "media-playback-pause" : "media-playback-start"
				width: height
				height: parent.height
				enabled: mpris2Source.canControl
				onClicked: mpris2Source.playPause()
			}
			PlasmaComponents.ToolButton {
				iconSource: "media-skip-forward"
				width: height
				height: parent.height
				enabled: mpris2Source.canGoNext
				onClicked: {
					seekSlider.value = 0 // Let the media start from beginning. Bug 362473 (org.kde.plasma.mediacontroller)
					mpris2Source.next()
				}
			}
		}
	}

	RowLayout {
		id: seekRow
		anchors.left: parent.left
		anchors.top: parent.top
		anchors.right: parent.right
		height: config.mediaControllerSliderHeight

		// org.kde.plasma.mediacontroller
		// ensure the layout doesn't shift as the numbers change and measure roughly the longest text that could occur with the current song
		TextMetrics {
			id: timeMetrics
			text: i18ndc("plasma_applet_org.kde.plasma.mediacontroller", "Remaining time for song e.g -5:42", "-%1",
						KCoreAddons.Format.formatDuration(seekSlider.maximumValue / 1000, KCoreAddons.FormatTypes.FoldHours))
			font: theme.smallestFont
		}

		PlasmaComponents.Label {
			visible: plasmoid.configuration.showMediaTimeElapsed
			Layout.preferredWidth: timeMetrics.width
			Layout.fillHeight: true
			verticalAlignment: Text.AlignVCenter
			horizontalAlignment: Text.AlignRight
			text: KCoreAddons.Format.formatDuration(seekSlider.value / 1000, KCoreAddons.FormatTypes.FoldHours)
			opacity: 0.6
			font: theme.smallestFont
		}

		PlasmaComponents.Slider {
			id: seekSlider
			Layout.fillWidth: true
			Layout.fillHeight: true
			enabled: mpris2Source.canSeek
			z: 999
			// style: PlasmaStyles.SliderStyle {
			// 	handle: Item {}
			// }

			// MouseArea {
			// 	id: seekSliderArea
			// 	anchors.fill: parent
			// 	hoverEnabled: true

			// 	acceptedButtons: Qt.NoButton
			// 	propagateComposedEvents: true
			// }
			opacity: hovered ? 1 : 0.75
			Behavior on opacity {
				NumberAnimation { duration: units.longDuration }
			}

			value: 0
			onValueChanged: {
				if (!mediaController.disablePositionUpdate) {
					// delay setting the position to avoid race conditions
					queuedPositionUpdate.restart()
				} else {
					// console.log('onValueChanged skipped')
				}
			}
			onMaximumValueChanged: mpris2Source.retrievePosition()

			Connections {
				target: mpris2Source

				onPositionChanged: {
					// we don't want to interrupt the user dragging the slider
					if (!seekSlider.pressed && !mediaController.keyPressed && !queuedPositionUpdate.running) {
						// we also don't want passive position updates
						mediaController.disablePositionUpdate = true
						// console.log('mpris2Source.position', mpris2Source.position)
						// console.log('\tmpris2Source.length', mpris2Source.length, seekSlider.maximumValue)
						if (seekSlider.maximumValue != mpris2Source.length) { // mpris2Source.onLengthChanged isn't always called.
							seekSlider.maximumValue = mpris2Source.length
						}
						seekSlider.value = mpris2Source.position
						mediaController.disablePositionUpdate = false
					}
				}
				onLengthChanged: {
					mediaController.disablePositionUpdate = true
					// console.log('mpris2Source.length', mpris2Source.length)
					seekSlider.maximumValue = mpris2Source.length
					mediaController.disablePositionUpdate = false
				}
			}


			Timer {
				id: queuedPositionUpdate
				interval: 100
				onTriggered: {
					if (!mediaController.disablePositionUpdate) {
						mpris2Source.setPosition(seekSlider.value)
					} else {
						// console.log('queuedPositionUpdate skipped')
					}
				}
			}

			Timer {
				id: seekTimer
				interval: 1000
				repeat: true
				running: mpris2Source.isPlaying && main.dialogVisible && !mediaController.keyPressed
				onTriggered: {
					// console.log(seekSlider.value, seekSlider.maximumValue,
					// 	seekSlider.pressed ? 'pressed' : '',
					// 	mediaController.disablePositionUpdate ? 'disablePositionUpdate' : '',
					// 	mpris2Source.canSeek ? 'canSeek': '')
					
					// some players don't continuously update the seek slider position via mpris
					// add one second; value in microseconds
					if (!seekSlider.pressed) {
						mediaController.disablePositionUpdate = true
						if (seekSlider.value == seekSlider.maximumValue) {
							mpris2Source.retrievePosition();
						} else {
							seekSlider.value += 1000000
						}
						mediaController.disablePositionUpdate = false
					}
				}
			}
		}

		PlasmaComponents.Label {
			visible: plasmoid.configuration.showMediaTimeLeft
			Layout.preferredWidth: timeMetrics.width
			Layout.fillHeight: true
			verticalAlignment: Text.AlignVCenter
			text: i18nc("Remaining time for song e.g -5:42", "-%1",
						KCoreAddons.Format.formatDuration((seekSlider.maximumValue - seekSlider.value) / 1000, KCoreAddons.FormatTypes.FoldHours))
			opacity: 0.6
			font: theme.smallestFont
		}

		PlasmaComponents.Label {
			visible: plasmoid.configuration.showMediaTotalDuration
			Layout.preferredWidth: timeMetrics.width
			Layout.fillHeight: true
			verticalAlignment: Text.AlignVCenter
			horizontalAlignment: Text.AlignRight
			text: KCoreAddons.Format.formatDuration(seekSlider.maximumValue / 1000, KCoreAddons.FormatTypes.FoldHours)
			opacity: 0.6
			font: theme.smallestFont
		}

	}
}
