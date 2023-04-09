class NotifyChanges {

  final List<Function> listeners = [];

  NotifyChanges();

  void addListener(Function() listener) {
    if (listeners.contains(listener)) {
      return;
    }
    listeners.add(listener);
  }

  void removeListener(Function() listener) {
    listeners.remove(listener);
  }

  void notifyListeners() {
    listeners.forEach((element) => element());
  }
}