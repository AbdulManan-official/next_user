import 'package:flutter/foundation.dart';
import '../models/service_model.dart';
import '../services/user_service.dart';

/// Controller managing user dashboard state and services.
class UserController extends ChangeNotifier {
  UserController({UserService? userService})
      : _userService = userService ?? UserService.instance;

  final UserService _userService;
  List<ServiceModel> _services = [];
  bool _isLoading = false;

  List<ServiceModel> get services => _services;
  bool get isLoading => _isLoading;

  Future<void> loadServices() async {
    _isLoading = true;
    notifyListeners();

    try {
      _services = await _userService.fetchFeaturedServices();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
