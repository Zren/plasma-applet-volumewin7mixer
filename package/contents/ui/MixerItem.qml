import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0
import QtQuick.Controls 2.0 as QQC2

import org.kde.draganddrop 2.0
import org.kde.kquickcontrolsaddons 2.0 as KAddons
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

import org.kde.plasma.private.volume 0.1 as PlasmaVolume

import "lib"
import "./code/Icon.js" as Icon
import "./code/PulseObjectCommands.js" as PulseObjectCommands

PlasmaComponents.ListItem {
	id: mixerItem
	width: mixerItemWidth + (showChannels ? numChannels * (channelSliderWidth + volumeSliderRow.spacing) : 0) + background.margins.left + background.margins.right
	checked: dropArea.containsDrag
	opacity: !main.draggedStream || dropArea.canBeDroppedOn ? 1 : 0.4
	separatorVisible: false
	property string mixerItemType: ''
	property int mixerItemWidth: 100
	property int volumeSliderWidth: 50
	property int channelSliderWidth: volumeSliderWidth
	property bool isVolumeBoosted: false
	readonly property bool hasChannels: typeof PulseObject.channels !== 'undefined'
	readonly property int numChannels: hasChannels ? PulseObject.channels.length : 0
	readonly property string canShowChannels: hasChannels && ("" + PulseObject.channels != "QVariant(QList<qlonglong>)") // Plasma 5.9 and below used QList<qlonglong> which is unreadable.
	property bool showChannels: false
	readonly property bool hasModuleLoopback: PulseObjectCommands.hasLoopbackModuleId(PulseObject)
	readonly property bool hasModuleEchoCancel: PulseObjectCommands.hasEchoCancelModuleId(PulseObject)

	property bool ignoreValueChanges: false
	function shouldIgnoreVolumeChanges() {
		return slider.ignoreValueChanges || channelRepeater.hasChannelIgnoreValueChanges()
	}

	Keys.onUpPressed: PulseObjectCommands.increaseVolume(PulseObject)
	Keys.onDownPressed: PulseObjectCommands.decreaseVolume(PulseObject)
	Keys.onPressed: {
		// AlsaMixer keybindings
		if (event.key == Qt.Key_M) { PulseObjectCommands.toggleMute(PulseObject)
		} else if (event.key == Qt.Key_0) { PulseObjectCommands.setPercent(PulseObject, 0)
		} else if (event.key == Qt.Key_1) { PulseObjectCommands.setPercent(PulseObject, 10)
		} else if (event.key == Qt.Key_2) { PulseObjectCommands.setPercent(PulseObject, 20)
		} else if (event.key == Qt.Key_3) { PulseObjectCommands.setPercent(PulseObject, 30)
		} else if (event.key == Qt.Key_4) { PulseObjectCommands.setPercent(PulseObject, 40)
		} else if (event.key == Qt.Key_5) { PulseObjectCommands.setPercent(PulseObject, 50)
		} else if (event.key == Qt.Key_6) { PulseObjectCommands.setPercent(PulseObject, 60)
		} else if (event.key == Qt.Key_7) { PulseObjectCommands.setPercent(PulseObject, 70)
		} else if (event.key == Qt.Key_8) { PulseObjectCommands.setPercent(PulseObject, 80)
		} else if (event.key == Qt.Key_9) { PulseObjectCommands.setPercent(PulseObject, 90)
		} else if (event.key == Qt.Key_Return) { makeDeviceDefault()
		} else if (event.key == Qt.Key_Menu) { contextMenu.showBelow(iconLabelButton)
		} else { return // don't accept the key press
		}
		event.accepted = true
	}

	function makeDeviceDefault() {
		if (typeof PulseObject.default !== "undefined") {
			PulseObject.default = true
			if (plasmoid.configuration.moveAllAppsOnSetDefault) {
				// console.log(appsModel, appsModel.count)
				for (var i = 0; i < appsModel.count; i++) {
					var stream = appsModel.get(i)
					stream = stream.PulseObject
					// console.log(i, stream, stream.name, stream.deviceIndex, PulseObject.index)
					stream.deviceIndex = PulseObject.index
				}
			}
			if (plasmoid.configuration.closeOnSetDefault) {
				main.closeDialog(false)
			}
		}
	}

	function playFeedback() {
		if (mixerItemType == 'Sink') {
			main.playFeedback(PulseObject.index)
		}
	}

	function setActivePort(portIndex) {
		PulseObject.activePortIndex = portIndex
	}

	function getCard() {
		// console.log(filteredCardModel, filteredCardModel.count)
		for (var i = 0; i < filteredCardModel.count; i++) {
			var card = filteredCardModel.get(i)
			// console.log(i, card, card.Index, card.Name, card.ActiveProfileIndex, Object.keys(card))
			if (PulseObject.cardIndex == card.Index) {
				return card
			}
		}
		return null
	}

	function setCardProfile(profileIndex) {
		// console.log('setCardProfile', profileIndex)
		var card = getCard()
		// console.log('card.ActiveProfileIndex', card.ActiveProfileIndex, '=>', profileIndex)
		card.PulseObject.activeProfileIndex = profileIndex
	}

	PlasmaCore.FrameSvgItem {
		id: background
		imagePath: "widgets/listitem"
		prefix: "normal"
		visible: false
	}

	function startsWith(a, b) {
		return a.indexOf(b) === 0
	}

	function endsWith(a, b) {
		return a.lastIndexOf(b) === a.length - b.length
	}

	readonly property var invalidPortIndex: 4294967295

	property string icon: {
		if (mixerItemType == 'SinkInput') {
			// App
			var client = PulseObject.client
			// Virtual streams don't have a valid client object, force a default icon for them
			if (client) {
				if (client.properties['application.icon_name']) {
					return client.properties['application.icon_name'].toLowerCase()
				} else if (client.properties['application.process.binary']) {
					var binary = client.properties['application.process.binary'].toLowerCase()
					// FIXME: I think this should do a reverse-desktop-file lookup
					// or maybe appdata could be used?
					// At any rate we need to attempt mapping binary to desktop file
					// such that we could get the icon.
					if (binary === 'chrome' || binary === 'chromium' || binary === 'chrome (deleted)') {
						return 'google-chrome'
					}
					return binary
				}
				return 'unknown'
			} else {
				return 'audio-card'
			}
		} else if (mixerItemType == 'Sink') {
			// Speaker
			if (PulseObject.properties['device.form_factor'] === 'headset') {
				// While the device.icon_name='audio-headset-usb', the icon
				// is not in the Breeze icon theme.
				return 'audio-headphones'
			}
			if (PulseObject.activePortIndex != invalidPortIndex) { // not "Invalid Port" (eg: echo-cancel)
				var portName = PulseObject.ports[PulseObject.activePortIndex].name
				if (portName.indexOf('headphones') >= 0) { // Eg: analog-output-headphones
					return 'audio-headphones'
				}
			}
			if (startsWith(PulseObject.name, 'alsa_output.') && PulseObject.name.indexOf('.hdmi-') >= 0) {
				// return Qt.resolvedUrl('../icons/hdmi.svg')
				return 'video-television'
			}
			if (PulseObject.name.indexOf('bluez_sink.') === 0) {
				return 'preferences-system-bluetooth'
			}
			return 'kmix' // looks like a speaker
		} else if (mixerItemType == 'Source') {
			// Microphone
			return 'mic-on'
		} else if (mixerItemType == 'SourceOutput') {
			// Recording Apps
			return 'mic-on'
		} else {
			return 'unknown'
		}
	}

	property string label: {
		var name = PulseObject.name
		if (PulseObject.properties['device.class'] === 'filter') {
			if (endsWith(name, '.echo-cancel')) { // Same for input and ouput stream
				// pactl load-module module-echo-cancel
				var inputName = PulseObject.properties['device.master_device']
				var inputLabel = labelFor(inputName)
				return i18n("%1 (Echo Cancelled)", inputLabel)
			}
		} else if (PulseObject.properties['media.role'] === 'abstract') {
			if (startsWith(name, 'Loopback to ')) {
				// microphone
			} else if (startsWith(name, 'Loopback from ')) {
				// speaker
			}
		}

		// PulseObject.properties['device.class'] === 'sound'
		if (startsWith(name, 'alsa_input.')) {
			if (name.indexOf('.analog-') >= 0) {
				return i18n("Mic")
			}
		} else if (name.indexOf('alsa_output.') === 0) {
			if (PulseObject.properties['device.form_factor'] === 'headset') {
				return i18n("Headset")
			} else if (name.indexOf('.analog-') >= 0) {
				return i18n("Speaker")
			} else if (name.indexOf('.hdmi-') >= 0) {
				return i18n("HDMI")
			}
		}

		var appName = PulseObject.properties['application.name']
		if (appName) {
			return appName
		}

		if (PulseObject.description) {
			return PulseObject.description
		}

		return name
	}

	property bool showDefaultDeviceIndicator: false
	readonly property bool isDevice: mixerItemType == 'Sink' || mixerItemType == 'Source'
	readonly property bool isDefaultDevice: {
		if (typeof PulseObject.default === 'boolean') {
			return PulseObject.default
		} else {
			return false
		}
	}
	property bool usingDefaultDevice: {
		if (typeof PulseObject.deviceIndex !== 'undefined') {
			if (mixerItemType == 'SinkInput') {
				return PulseObject.deviceIndex === sinkModel.defaultSink.index
			} else if (mixerItemType == 'SourceOutput') {
				return PulseObject.deviceIndex === sourceModel.defaultSource.index
			} else {
				return false
			}
		} else {
			return true // Just pretend it's linked to the default so we don't show that it's not.
		}
	}

	property string tooltipSubText: {
		// maximum of 8 visible lines. Extra lines are cut off.
		var lines = []
		function addLine(key, value) {
			if (typeof value === 'undefined') return
			if (typeof value === 'string' && value.length === 0) return
			lines.push('<b>' + key + ':</b> ' + value)
		}
		addLine(i18n("Name"), PulseObject.name)
		addLine(i18n("Description"), PulseObject.description)
		addLine(i18n("Volume"), Math.round(PulseObjectCommands.volumePercent(PulseObject.volume)) + "%")
		if (typeof PulseObject.activePortIndex !== 'undefined' && PulseObject.activePortIndex != invalidPortIndex) {
			addLine(i18n("Port"), '[' + PulseObject.activePortIndex +'] ' + PulseObject.ports[PulseObject.activePortIndex].description)
		}
		if (typeof PulseObject.deviceIndex !== 'undefined') {
			if (!usingDefaultDevice) {
				addLine(i18n("Device"), '[' + PulseObject.deviceIndex + '] ')
			}
		}
		function addPropertyLine(key) {
			addLine(key, PulseObject.properties[key])
		}
		addPropertyLine('alsa.mixer_name')
		addPropertyLine('application.process.binary')
		addPropertyLine('application.process.id')
		addPropertyLine('application.process.user')

		// for (var key in PulseObject.properties) {
		// 	lines.push('<b>' + key + ':</b> ' + PulseObject.properties[key])
		// }
		return lines.join('<br>')
	}

	DropArea {
		id: dropArea
		anchors.fill: parent
		property bool canBeDroppedOn: {
			if (main.draggedStream) {
				if (main.draggedStreamType == 'SinkInput') {
					return mixerItemType == 'Sink'
				} else if (main.draggedStreamType == 'Source') {
					return mixerItemType == 'SourceOutput'
				}
			}
			return false
		}

		enabled: canBeDroppedOn
		onDrop: {
			console.log('DropArea.onDrop')
			console.log(main.draggedStream, '=>', PulseObject)
			// logPulseObj(main.draggedStream)
			// logPulseObj(PulseObject)
			if (main.draggedStreamType == 'SinkInput') {
				main.draggedStream.deviceIndex = PulseObject.index
			} else if (main.draggedStreamType == 'Source') {
				PulseObject.deviceIndex = main.draggedStream.index
			}
		}
	}

	function logObj(obj) {
		for (var key in obj) {
			if (typeof obj[key] === 'function') continue
			console.log(obj, key, obj[key])
		}
	}

	function logPulseObj(obj) {
		logObj(obj)
		if (typeof obj.ports !== 'undefined') {
			for (var i = 0; i < obj.ports.length; i++) {
				logObj(obj.ports[i])
			}
		}
		if (typeof obj.properties !== 'undefined') {
			logObj(obj.properties)
		}
		if (typeof obj.client !== 'undefined') {
			logObj(obj.client)
			logObj(obj.client.properties)
		}
	}

	Row {
		id: volumeSliderRow
		// anchors.fill: parent
		height: parent.height
		width: parent.width
		spacing: 10


		ColumnLayout {
			// anchors.fill: parent
			width: mixerItem.mixerItemWidth
			height: parent.height

			PlasmaCore.ToolTipArea {
				id: tooltip
				Layout.fillWidth: true
				Layout.preferredHeight: iconLabelButton.height
				mainText: mixerItem.label
				subText: tooltipSubText
				icon: mixerItem.icon

				DragArea {
					id: dragArea
					anchors.fill: parent
					delegate: iconLabelButton // parent
					enabled: mixerItemType == 'SinkInput' || mixerItemType == 'Source'

					mimeData {
						source: mixerItem
					}

					onDragStarted: {
						console.log('DragArea.onDragStarted')
						main.startDrag(PulseObject, mixerItemType)
					}
					onDrop: {
						console.log('DragArea.onDrop')
						main.clearDrag()
					}

					// PlasmaComponents.ToolButton {
					// Item {
					IconLabelButton {
						id: iconLabelButton
						// anchors.fill: parent
						width: parent.width
						iconItemSource: mixerItem.icon
						iconItemOverlays: {
							if (mixerItem.usingDefaultDevice) {
								return []
							} else {
								return ['emblem-unlocked']
							}
						}
						iconItemHeight: mixerItem.volumeSliderWidth
						labelText: mixerItem.label

						onClicked: {
							if (mixerItem.isDevice && plasmoid.configuration.setDefaultOnClickIcon) {
								mixerItem.makeDeviceDefault()
							} else {
								contextMenu.showBelow(iconLabelButton)
							}
						}

						PlasmaComponents.RadioButton {
							id: defaultDeviceRadioButton
							visible: mixerItem.showDefaultDeviceIndicator
							anchors.left: parent.left
							anchors.top: parent.top
							anchors.margins: units.smallSpacing
							checked: mixerItem.isDefaultDevice
							onClicked: {
								mixerItem.makeDeviceDefault()
								checked = Qt.binding(function(){ return mixerItem.isDefaultDevice })
							}

							QQC2.ToolTip {
								visible: defaultDeviceRadioButton.hovered
								text: {
									if (defaultDeviceRadioButton.checked) {
										return i18n("Is default device")
									} else {
										return i18n("Make default device")
									}
								}
								delay: 0
							}
						}
					}
				}
			}

			Item {
				Layout.fillWidth: true
				Layout.fillHeight: true
				
				// VolumeSlider {
				VerticalVolumeSlider {
					id: slider
					height: parent.height
					width: mixerItem.volumeSliderWidth
					anchors.horizontalCenter: parent.horizontalCenter

					// Helper properties to allow async slider updates.
					// While we are sliding we must not react to value updates
					// as otherwise we can easily end up in a loop where value
					// changes trigger volume changes trigger value changes.
					readonly property int volume: PulseObject.volume
					
					property bool ready: false
					property bool ignoreValueChanges: false

					Layout.fillWidth: true

					minimumValue: 0
					// FIXME: I do wonder if exposing max through the model would be useful at all
					maximumValue: mixerItem.isVolumeBoosted ? 98304 : 65536
					stepSize: maximumValue / maxPercentage
					visible: PulseObject.hasVolume
					enabled: typeof PulseObject.volumeWritable === 'undefined' || PulseObject.volumeWritable

					opacity: {
						return enabled && PulseObject.muted ? 0.5 : 1
					}

					onVolumeChanged: {
						// console.log('oldIgnoreValueChanges = slider.ignoreValueChanges', slider.ignoreValueChanges)
						var oldIgnoreValueChanges = slider.ignoreValueChanges
						slider.ignoreValueChanges = true
						mixerItem.ignoreValueChanges = mixerItem.shouldIgnoreVolumeChanges()
						if (!mixerItem.isVolumeBoosted && PulseObject.volume > 66000) {
							mixerItem.isVolumeBoosted = true
						}
						value = PulseObject.volume
						// console.log('slider.ignoreValueChanges = oldIgnoreValueChanges', slider.ignoreValueChanges, oldIgnoreValueChanges)
						slider.ignoreValueChanges = oldIgnoreValueChanges
						mixerItem.ignoreValueChanges = mixerItem.shouldIgnoreVolumeChanges()
					}

					onValueChanged: {
						// console.log('onValueChanged', slider.ready && !mixerItem.ignoreValueChanges ? 'set' : 'ignored', -1, value)
						if (slider.ready && !mixerItem.ignoreValueChanges) {
							// console.log('setVolume', value)
							PulseObjectCommands.setVolume(PulseObject, value)

							if (!pressed) {
								updateTimer.restart()
							}
						}
					}

					property bool playFeedbackOnUpdate: false
					onPressedChanged: {
						if (pressed) {
							playFeedbackOnUpdate = true
						} else {
							// Make sure to sync the volume once the button was
							// released.
							// Otherwise it might be that the slider is at v10
							// whereas PA rejected the volume change and is
							// still at v15 (e.g.).
							updateTimer.restart()
						}
					}

					Timer {
						id: updateTimer
						interval: 200
						onTriggered: {
							slider.value = PulseObject.volume

							// Done dragging, play feedback
							if (slider.playFeedbackOnUpdate) {
								mixerItem.playFeedback()
							}

							if (!slider.pressed) {
								slider.playFeedbackOnUpdate = false
							}
						}
					}

					// Block wheel events
					KAddons.MouseEventListener {
						anchors.fill: parent
						acceptedButtons: Qt.MidButton

						property int wheelDelta: 0
						onWheelMoved: {
							wheelDelta += wheel.delta
						
							// Magic number 120 for common "one click"
							// See: http://qt-project.org/doc/qt-5/qml-qtquick-wheelevent.html#angleDelta-prop
							while (wheelDelta >= 120) {
								wheelDelta -= 120
								PulseObjectCommands.increaseVolume(PulseObject)
								mixerItem.playFeedback()
							}
							while (wheelDelta <= -120) {
								wheelDelta += 120
								PulseObjectCommands.decreaseVolume(PulseObject)
								mixerItem.playFeedback()
							}
						}
					}

					Component.onCompleted: {
						slider.ready = true
						mixerItem.isVolumeBoosted = PulseObject.volume > 66000 // 100% is 65863.68, not 65536... Bleh. Just trigger at a round number.
					}

				}
			}

			PlasmaComponents.ToolButton {
				id: muteButton
				Layout.maximumWidth: mixerItem.volumeSliderWidth
				Layout.maximumHeight: mixerItem.volumeSliderWidth
				Layout.minimumWidth: Layout.maximumWidth
				Layout.minimumHeight: Layout.maximumHeight
				Layout.alignment: Qt.AlignHCenter

				PlasmaCore.IconItem {
					anchors.fill: parent
					readonly property bool isMic: mixerItemType == 'Source' || mixerItemType == 'SourceOutput'
					readonly property string prefix: isMic ? 'microphone-sensitivity' : 'audio-volume'
					source: Icon.name(PulseObject.volume, PulseObject.muted, prefix)

					// From ToolButtonStyle:
					active: parent.hovered
					colorGroup: parent.hovered || !parent.flat ? PlasmaCore.Theme.ButtonColorGroup : PlasmaCore.ColorScope.colorGroup
				}
				
				onClicked: {
					// logPulseObj(PulseObject)
					PulseObject.muted = !PulseObject.muted
				}
			}
		}


		Repeater {
			id: channelRepeater
			model: showChannels && hasChannels ? PulseObject.channels : 0

			function hasChannelIgnoreValueChanges() {
				for (var i = 0; i < count; i++) {
					var item = itemAt(i)
					if (item && item.ignoreValueChanges) {
						return true
					}
				}
				return false
			}

			ColumnLayout {
				id: channelColumn
				// anchors.fill: parent
				width: mixerItem.channelSliderWidth
				height: parent.height

				property bool ignoreValueChanges: false

				PlasmaCore.ToolTipArea {
					Layout.fillWidth: true
					Layout.preferredHeight: iconLabelButton.height

					IconLabelButton {
						anchors.fill: parent
						iconItemHeight: mixerItem.volumeSliderWidth
						labelText: PulseObject.channels[index]
					}
				} // ToolTipArea
				
				Item {
					Layout.fillWidth: true
					Layout.fillHeight: true

					VerticalVolumeSlider {
						id: channelSlider
						width: mixerItem.channelSliderWidth
						height: parent.height
						// enabled: false
						// anchors.horizontalCenter: parent.horizontalCenter
						
						showVisualFeedback: false

						// Helper properties to allow async slider updates.
						// While we are sliding we must not react to value updates
						// as otherwise we can easily end up in a loop where value
						// changes trigger volume changes trigger value changes.
						readonly property int volume: PulseObject.channelVolumes[index]

						property bool ready: false
						readonly property bool isChannelBoosted: volume > 66000

						value: volume
						minimumValue: 0
						// FIXME: I do wonder if exposing max through the model would be useful at all
						maximumValue: mixerItem.isVolumeBoosted || isChannelBoosted ? 98304 : 65536

						onVolumeChanged: {
							// console.log('onVolumeChanged', index, volume)
							// console.log('oldIgnoreValueChanges = channelColumn.ignoreValueChanges', channelColumn.ignoreValueChanges)
							var oldIgnoreValueChanges = channelColumn.ignoreValueChanges
							channelColumn.ignoreValueChanges = true
							mixerItem.ignoreValueChanges = mixerItem.shouldIgnoreVolumeChanges()
							// if (!mixerItem.isVolumeBoosted && volume > 66000) {
							// 	mixerItem.isVolumeBoosted = true
							// }
							value = volume
							// console.log('channelColumn.ignoreValueChanges = oldIgnoreValueChanges', channelColumn.ignoreValueChanges, oldIgnoreValueChanges)
							channelColumn.ignoreValueChanges = oldIgnoreValueChanges
							mixerItem.ignoreValueChanges = mixerItem.shouldIgnoreVolumeChanges()
						}

						onValueChanged: {
							// console.log('onValueChanged', channelSlider.ready && !mixerItem.ignoreValueChanges ? 'set' : 'ignored', index, value)
							if (channelSlider.ready && !mixerItem.ignoreValueChanges) {
								// console.log('setChannelVolume', index, Math.floor(value))
								PulseObject.setChannelVolume(index, Math.floor(value))

								if (!pressed) {
									channelUpdateTimer.restart()
								}
							}
						}

						function playFeedback() {
							mixerItem.playFeedback()
						}

						property bool playFeedbackOnUpdate: false
						onPressedChanged: {
							if (pressed) {
								playFeedbackOnUpdate = true
							} else {
								// Make sure to sync the volume once the button was
								// released.
								// Otherwise it might be that the slider is at v10
								// whereas PA rejected the volume change and is
								// still at v15 (e.g.).
								channelUpdateTimer.restart()
							}
						}

						Timer {
							id: channelUpdateTimer
							interval: 200
							onTriggered: {
								channelSlider.value = channelSlider.volume

								// Done dragging, play feedback
								if (channelSlider.playFeedbackOnUpdate) {
									channelSlider.playFeedback()
								}

								if (!channelSlider.pressed) {
									channelSlider.playFeedbackOnUpdate = false
								}
							}
						}

						// Block wheel events
						KAddons.MouseEventListener {
							anchors.fill: parent
							acceptedButtons: Qt.MidButton

							property int wheelDelta: 0
							onWheelMoved: {
								wheelDelta += wheel.delta
							
								// Magic number 120 for common "one click"
								// See: http://qt-project.org/doc/qt-5/qml-qtquick-wheelevent.html#angleDelta-prop
								while (wheelDelta >= 120) {
									wheelDelta -= 120
									PulseObjectCommands.increaseChannelVolume(PulseObject, index)
									channelSlider.playFeedback()
								}
								while (wheelDelta <= -120) {
									wheelDelta += 120
									PulseObjectCommands.decreaseChannelVolume(PulseObject, index)
									channelSlider.playFeedback()
								}
							}
						}

						Component.onCompleted: {
							channelSlider.ready = true
							// mixerItem.isVolumeBoosted = volume > 66000 // 100% is 65863.68, not 65536... Bleh. Just trigger at a round number.
						}
					}
				}

				Item {
					Layout.fillWidth: true
					Layout.preferredHeight: muteButton.height
				}
				
			}
		}
	}


	
	// https://github.com/KDE/plasma-framework/blob/master/src/declarativeimports/plasmacomponents/qmenu.cpp
	// Example: https://github.com/KDE/plasma-desktop/blob/master/applets/taskmanager/package/contents/ui/ContextMenu.qml
	ContextMenu {
		id: contextMenu

		onBeforeOpen: {
			// Mute
			var menuItem = newMenuItem()
			menuItem.text = i18ndc("plasma_applet_org.kde.plasma.volume", "Checkable switch for (un-)muting sound output.", "Mute")
			menuItem.checkable = true
			menuItem.checked = PulseObject.muted
			menuItem.clicked.connect(function() {
				PulseObject.muted = !PulseObject.muted
			})
			contextMenu.addMenuItem(menuItem)

			// Volume Boost
			var menuItem = newMenuItem()
			menuItem.text = i18n("Volume Boost (150% Volume)")
			menuItem.checkable = true
			menuItem.checked = mixerItem.isVolumeBoosted
			menuItem.clicked.connect(function() {
				mixerItem.isVolumeBoosted = !mixerItem.isVolumeBoosted
			})
			contextMenu.addMenuItem(menuItem)

			// Default
			if (typeof PulseObject.default === "boolean") {
				var menuItem = newMenuItem()
				menuItem.text = i18ndc("plasma_applet_org.kde.plasma.volume", "Checkable switch to change the current default output.", "Default")
				menuItem.checkable = true
				menuItem.checked = PulseObject.default
				menuItem.clicked.connect(function() {
					mixerItem.makeDeviceDefault()
				})
				contextMenu.addMenuItem(menuItem)
			}

			// Channels
			if (mixerItem.hasChannels) {
				var menuItem = newMenuItem()
				menuItem.text = i18n("Show Channels")
				menuItem.checkable = true
				menuItem.checked = mixerItem.showChannels
				menuItem.clicked.connect(function() {
					mixerItem.showChannels = !mixerItem.showChannels
				})
				contextMenu.addMenuItem(menuItem)
			}

			// Ports
			if (PulseObject.ports && PulseObject.ports.length > 1) {
				var sectionItem = newMenuItem()
				sectionItem.text = i18ndc("plasma_applet_org.kde.plasma.volume", "Heading for a list of ports of a device (for example built-in laptop speakers or a plug for headphones)", "Ports")
				sectionItem.section = true
				contextMenu.addMenuItem(sectionItem)

				for (var i = 0; i < PulseObject.ports.length; i++) {
					var port = PulseObject.ports[i]
					var menuItem = newMenuItem()
					if (typeof PlasmaVolume.Port !== "undefined" && port.availability == PlasmaVolume.Port.Unavailable) {
						if (port.name == "analog-output-speaker" || port.name == "analog-input-microphone-internal") {
							menuItem.text = i18ndc("plasma_applet_org.kde.plasma.volume", "Port is unavailable", "%1 (unavailable)", port.description)
						} else {
							menuItem.text = i18ndc("plasma_applet_org.kde.plasma.volume", "Port is unplugged", "%1 (unplugged)", port.description)
						}
					} else {
						menuItem.text = port.description
					}
					menuItem.checkable = true
					menuItem.checked = i === PulseObject.activePortIndex
					menuItem.clicked.connect(mixerItem.setActivePort.bind(null, i))
					contextMenu.addMenuItem(menuItem)
				}
			}

			// Profiles
			if (typeof PulseObject.cardIndex === "number") {
				contextMenu.addMenuItem(newSeperator())
				var card = mixerItem.getCard()
				if (card) {
					var subMenu = newSubMenu()
					subMenu.text = i18n("Profile")
					subMenu.parent = contextMenu
					contextMenu.addMenuItem(subMenu)

					var availableProfiles = card.Profiles
					// console.log(availableProfiles, availableProfiles.count, availableProfiles.length)
					for (var i = 0; i < availableProfiles.length; i++) {
						var profile = availableProfiles[i]
						// console.log('profile', i, profile.name, profile.description, '(priority: ' + profile.priority + ')')
						var menuItem = subMenu.newMenuItem()
						menuItem.text = profile.description
						// menuItem.enabled = profile.available // Plasma 5.13?
						menuItem.checkable = true
						menuItem.checked = card.ActiveProfileIndex === i
						menuItem.clicked.connect(mixerItem.setCardProfile.bind(null, i))
						
						subMenu.addMenuItem(menuItem)
					}
				}
			}

			// Modules: Source
			if (mixerItemType == 'Source') {
				contextMenu.addMenuItem(newSeperator())

				// module-echo-cancel
				var menuItem = newMenuItem()
				menuItem.text = i18n("Echo Cancellation")
				menuItem.enabled = !PulseObjectCommands.hasIdProperty(PulseObject, 'echo_cancel.source')
				menuItem.checkable = true
				menuItem.checked = mixerItem.hasModuleEchoCancel
				menuItem.clicked.connect(function() {
					PulseObjectCommands.toggleModuleEchoCancel(PulseObject)
				})
				contextMenu.addMenuItem(menuItem)

				// module-loopback
				var menuItem = newMenuItem()
				menuItem.text = i18n("Listen to Device")
				menuItem.enabled = !mixerItem.hasModuleEchoCancel && !PulseObjectCommands.hasIdProperty(PulseObject, 'loopback.source')
				menuItem.checkable = true
				menuItem.checked = mixerItem.hasModuleLoopback
				menuItem.clicked.connect(function() {
					PulseObjectCommands.toggleModuleLoopback(PulseObject)
				})
				contextMenu.addMenuItem(menuItem)
			}

			// Properties
			contextMenu.addMenuItem(newSeperator())
			var menuItem = newMenuItem()
			menuItem.text = i18n("Properties")
			menuItem.clicked.connect(function() {
				mixerItem.showPropertiesDialog()
				main.closeDialog(false)
			})
		}
	}

	MouseArea {
		acceptedButtons: Qt.RightButton
		anchors.fill: parent

		onClicked: contextMenu.show(mouse.x, mouse.y)
	}

	function showPropertiesDialog() {
		var qml = 'import QtQuick 2.0; \
		PulseObjectDialog { \
			pulseObject: PulseObject \
		} '
		var dialog = Qt.createQmlObject(qml, mixerItem)
		dialog.visible = true
	}
}
