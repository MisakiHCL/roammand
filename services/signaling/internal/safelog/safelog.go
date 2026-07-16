// SPDX-License-Identifier: AGPL-3.0-only

package safelog

import (
	"io"
	"log"
	"log/slog"
	"time"
)

type Event uint8

const (
	EventServiceFailed Event = iota + 1
	EventHTTPServerError
	EventPublicFrameEncodeFailed
)

type Code uint8

const CodeInternal Code = 1

type Fields struct {
	Code     Code
	Count    uint64
	Duration time.Duration
}

type Logger struct {
	logger *slog.Logger
}

func New(output io.Writer) *Logger {
	if output == nil {
		output = io.Discard
	}
	return &Logger{logger: slog.New(slog.NewTextHandler(output, nil))}
}

func Discard() *Logger {
	return New(io.Discard)
}

func (logger *Logger) Event(event Event, fields Fields) {
	attributes := []any{"event", eventName(event)}
	if fields.Code != 0 {
		attributes = append(attributes, "code", codeName(fields.Code))
	}
	if fields.Count != 0 {
		attributes = append(attributes, "count", fields.Count)
	}
	if fields.Duration != 0 {
		attributes = append(attributes, "duration_ms", fields.Duration.Milliseconds())
	}
	logger.logger.Error("service_event", attributes...)
}

func eventName(event Event) string {
	switch event {
	case EventServiceFailed:
		return "service_failed"
	case EventHTTPServerError:
		return "http_server_error"
	case EventPublicFrameEncodeFailed:
		return "public_frame_encode_failed"
	default:
		return "unknown"
	}
}

func codeName(code Code) string {
	switch code {
	case CodeInternal:
		return "internal"
	default:
		return "unknown"
	}
}

func (logger *Logger) HTTPErrorWriter() io.Writer {
	return httpErrorWriter{logger: logger}
}

func (logger *Logger) HTTPErrorLog() *log.Logger {
	return log.New(logger.HTTPErrorWriter(), "", 0)
}

type httpErrorWriter struct {
	logger *Logger
}

func (writer httpErrorWriter) Write(encoded []byte) (int, error) {
	writer.logger.Event(EventHTTPServerError, Fields{Code: CodeInternal})
	return len(encoded), nil
}
