import QtQuick 2.0
import org.kde.plasma.private.volumewin7mixer 1.0

VolumePeaks {
	id: volumePeaks
	peaking: main.dialogVisible
	property real defaultSinkPeakRatio: defaultSinkPeak / 65536
	property int defaultSinkPeakPercent: Math.round(defaultSinkPeakRatio*100)
	property string filename: plasmoid.file("", "code/peak/peak_monitor.py")
	peakCommand: "python3"
	peakCommandArgs: {
		if (mixerItem.mixerItemType == 'Sink' || mixerItem.mixerItemType == 'Source') {
			return [filename, mixerItem.mixerItemType, ''+PulseObject.index]
		} else if (mixerItem.mixerItemType == 'SinkInput' || mixerItem.mixerItemType == 'SourceOutput') {
			return [filename, mixerItem.mixerItemType, ''+PulseObject.deviceIndex, ''+PulseObject.index]
		} else {
			return []
		}
	}
}
