@tool
class_name PopulousLogger

## Simple logging utility for Populous addon with log levels
## Provides consistent logging interface with DEBUG, INFO, WARNING, ERROR levels

enum LogLevel {
	DEBUG,
	INFO,
	WARNING,
	ERROR
}

static var log_level: LogLevel = LogLevel.INFO

## Log a debug message (only shown in debug builds)
static func debug(message: String) -> void:
	if log_level <= LogLevel.DEBUG:
		print("[Populous DEBUG] ", message)

## Log an informational message
static func info(message: String) -> void:
	if log_level <= LogLevel.INFO:
		print("[Populous INFO] ", message)

## Log a warning message
static func warning(message: String) -> void:
	if log_level <= LogLevel.WARNING:
		push_warning("Populous: " + message)

## Log an error message
static func error(message: String) -> void:
	if log_level <= LogLevel.ERROR:
		push_error("Populous: " + message)
