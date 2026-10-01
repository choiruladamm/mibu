import 'package:flutter/foundation.dart';

class HomeViewModel extends ChangeNotifier {
  int _counter = 0;
  int get counter => _counter;

  void increment() {
    _counter++;
    notifyListeners();
  }
}
