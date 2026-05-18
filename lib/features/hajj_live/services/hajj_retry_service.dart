import 'dart:async';

class HajjRetryService {
  Timer? _timer;
  int _currentAttempt = 0;
  
  void startRetry({
    required List<int> intervals,
    required int maxRetries,
    required Function(int attempt, int nextRetryIn) onRetry,
    required Function() onMaxRetriesReached,
    required Future<bool> Function() task,
  }) {
    _cancelTimer();
    _currentAttempt = 0;
    _executeTask(intervals, maxRetries, onRetry, onMaxRetriesReached, task);
  }

  void _executeTask(
    List<int> intervals,
    int maxRetries,
    Function(int attempt, int nextRetryIn) onRetry,
    Function() onMaxRetriesReached,
    Future<bool> Function() task,
  ) async {
    final success = await task();
    if (success) {
      _currentAttempt = 0;
      return;
    }

    if (_currentAttempt >= maxRetries) {
      onMaxRetriesReached();
      return;
    }

    final waitTime = _currentAttempt < intervals.length 
        ? intervals[_currentAttempt] 
        : intervals.last;
    
    _currentAttempt++;
    onRetry(_currentAttempt, waitTime);

    _timer = Timer(Duration(seconds: waitTime), () {
      _executeTask(intervals, maxRetries, onRetry, onMaxRetriesReached, task);
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _cancelTimer();
  }
}
