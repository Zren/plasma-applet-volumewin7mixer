.pragma library
.import "./Icon.js" as Icon

function isDummyOutput(output) {
	// DEFAULT_SINK_NAME in module-always-sink.c
	return output && output.name === "auto_null"
}

function iconNameForStream(pulseObject) {
	return pulseObject ? Icon.name(pulseObject.volume, pulseObject.muted) : Icon.name(0, true)
}
