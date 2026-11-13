import 'dart:js_interop';

@JS('window.addEventListener')
external void _listen(JSString event, JSFunction listener);
@JS('window.removeEventListener')
external void _remove(JSString event, JSFunction listener);

extension type _StorageChange(JSObject object) implements JSObject {
  external JSString? get key;
}

/// Observe other tabs without writing, polling, or adding a persistence key.
void Function() watchJournal(
  void Function() onChanged, {
  String storageKey = 'mennyiment_drinks_v1',
}) {
  final storage = ((JSObject event) {
    final key = _StorageChange(event).key?.toDart;
    if (key == null || key == 'flutter.$storageKey') onChanged();
  }).toJS;
  final focus = ((JSObject event) => onChanged()).toJS;
  _listen('storage'.toJS, storage);
  _listen('focus'.toJS, focus);
  return () {
    _remove('storage'.toJS, storage);
    _remove('focus'.toJS, focus);
  };
}
