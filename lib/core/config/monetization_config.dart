import 'package:flutter/foundation.dart';

class MonetizationConfig extends ChangeNotifier {
  // Example property
  bool _isMonetized = false;

  bool get isMonetized => _isMonetized;

  void toggleMonetization() {
    _isMonetized = !_isMonetized;
    notifyListeners();
  }
}