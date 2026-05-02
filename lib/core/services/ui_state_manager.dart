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
  Future<void> Function()? _lastFailedTask;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOffline => _isOffline;
  bool get canRetry => _lastFailedTask != null;

  UIStateManager() {
    _initConnectivity();
  }

  /// Retries the last task that failed.
  Future<void> retryLastTask() async {
    if (_lastFailedTask != null) {
      final task = _lastFailedTask!;
      _lastFailedTask = null; // Clear it before running
      notifyListeners();
      await runTask(task);
    }
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
  /// If it's a [Failure], it sets the error message and optionally stores a retry task.
  /// Returns true if success, false if failure.
  bool handleResult<T>(Result<T> result, {bool showErrorMessage = true, Future<void> Function()? retryTask}) {
    if (result is Failure) {
      _lastFailedTask = retryTask;
      if (showErrorMessage) {
        setError((result as Failure).message);
      }
      return false;
    }
    _lastFailedTask = null;
    notifyListeners();
    return true;
  }

  /// Executes an async task with automatic loading state management.
  /// If it fails, it stores the task for a potential retry.
  Future<T?> runTask<T>(Future<T> Function() task, {bool showLoading = true}) async {
    if (showLoading) setLoading(true);
    try {
      final result = await task();
      _lastFailedTask = null;
      notifyListeners();
      return result;
    } catch (e) {
      _lastFailedTask = () async { await task(); };
      setError(e.toString());
      return null;
    } finally {
      if (showLoading) setLoading(false);
    }
  }
}
