import 'package:web/web.dart' as web;
import 'dart:js_interop';

JSFunction? _visibilityListener;
JSFunction? _blurListener;

void setupWebVisibilityListeners(void Function() onViolation) {
  _visibilityListener = ((web.Event e) {
    if (web.document.hidden) {
      onViolation();
    }
  }).toJS;
  
  _blurListener = ((web.Event e) {
    onViolation();
  }).toJS;

  web.document.addEventListener('visibilitychange', _visibilityListener as web.EventListener);
  web.window.addEventListener('blur', _blurListener as web.EventListener);
}

void removeWebVisibilityListeners() {
  if (_visibilityListener != null && _blurListener != null) {
    web.document.removeEventListener('visibilitychange', _visibilityListener as web.EventListener);
    web.window.removeEventListener('blur', _blurListener as web.EventListener);
  }
}

void requestWebFullscreen() {
  try {
    web.document.documentElement?.requestFullscreen();
  } catch (_) {}
}

void exitWebFullscreen() {
  try {
    web.document.exitFullscreen();
  } catch (_) {}
}
