from dataclasses import dataclass
from enum import Enum
import json
from pydoc import text
from typing import Any
from unittest.mock import DEFAULT


@dataclass
class LogEntry:
    severity: str
    short_message: str
    text: str
    data: dict[str, Any] | None = None

    def format(self) -> str:
        return json.dumps({
            "severity": self.severity,
            "message": self.short_message,
            "text": self.text,
            "data": self.data if self.data is not None else {},
        })
    
class Severity(Enum):
  DEFAULT = "DEFAULT"
  DEBUG = "DEBUG"
  INFO = "INFO"
  NOTICE = "NOTICE"
  WARNING = "WARNING"
  ERROR = "ERROR"
  CRITICAL = "CRITICAL"
  ALERT = "ALERT"
  EMERGENCY = "EMERGENCY"
  

class Logger:
    @staticmethod
    def default(short_message: str, text: str, data: dict[str, Any] | None = None) -> None:
        print(LogEntry(Severity.DEFAULT.value, short_message, text, data).format())

    @staticmethod
    def debug(short_message: str, text: str, data: dict[str, Any] | None = None) -> None:
        print(LogEntry(Severity.DEBUG.value, short_message, text, data).format())
    @staticmethod
    def info(short_message: str, text: str, data: dict[str, Any] | None = None
    ) -> None:
        print(LogEntry(Severity.INFO.value, short_message, text, data).format())
    @staticmethod
    def warning(short_message: str, text: str, data: dict[str, Any] | None = None
    ) -> None:
        print(LogEntry(Severity.WARNING.value, short_message, text, data).format())
    @staticmethod
    def error(short_message: str, text: str, data: dict[str, Any] | None = None) -> None:
        print(LogEntry(Severity.ERROR.value, short_message, text, data).format())

    @staticmethod
    def critical(short_message: str, text: str, data: dict[str, Any] | None = None
    ) -> None:
        print(LogEntry(Severity.CRITICAL.value, short_message, text, data).format()) 

    @staticmethod
    def alert(short_message: str, text: str, data: dict[str, Any] | None = None
    ) -> None:
        print(LogEntry(Severity.ALERT.value, short_message, text, data).format())

    @staticmethod
    def emergency(short_message: str, text: str, data: dict[str, Any] | None = None
    ) -> None:
        print(LogEntry(Severity.EMERGENCY.value, short_message, text, data).format())