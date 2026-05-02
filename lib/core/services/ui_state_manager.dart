import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:moodtrack/core/error/result.dart';

/// A central manager to handle global loading states and error notifications.
class UIStateManager extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOffline = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOffline => _isOffline;

  UIStateManager() {
    _initConnectivity();
  }

  void _initConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.contains(ConnectivityResult.none) || results.isEmpty;
      if (_isOffline != offline) {
        _isOffline = offline;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  /// Sets the global loading state.
  void setLoading(bool loading) {
    if (_isLoading == loading) return;
    _isLoading = loading;
    notifyListeners();
  }

  /// Sets an error message and notifies listeners.
  void setError(String message) {
    _errorMessage = message;
    notifyListeners();
    // Auto-clear error after notifying so it doesn't persist across rebuilds
    _errorMessage = null;
  }

  /// Automatically handles a [Result] object. 
  /// If it's a [Failure], it sets the error message.
  /// Returns true if success, false if failure.
  bool handleResult<T>(Result<T> result, {bool showErrorMessage = true}) {
    if (result is Failure) {
      if (showErrorMessage) {
        setError((result as Failure).message);
      }
      return false;
    }
    return true;
  }

  /// Executes an async task with automatic loading state management.
  Future<T?> runTask<T>(Future<T> Function() task, {bool showLoading = true}) async {
    if (showLoading) setLoading(true);
    try {
      final result = await task();
      return result;
    } catch (e) {
      setError(e.toString());
      return null;
    } finally {
      if (showLoading) setLoading(false);
    }
  }
}
