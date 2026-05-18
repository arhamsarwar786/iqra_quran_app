import 'dart:async';
import 'package:flutter/material.dart';
import '../models/hajj_stream_model.dart';
import '../services/hajj_config_service.dart';
import '../services/hajj_retry_service.dart';
import '../services/hajj_time_service.dart';
import '../config/hajj_live_config.dart';

enum HajjLiveStatus { initial, loading, loaded, retrying, error }

class HajjLiveProvider with ChangeNotifier {
  final HajjConfigService _configService = HajjConfigService();
  final HajjRetryService _retryService = HajjRetryService();
  final HajjTimeService _timeService = HajjTimeService();

  HajjLiveStatus _status = HajjLiveStatus.initial;
  HajjStreamModel? _config;
  String? _errorMessage;
  
  // Real-time Countdown
  Duration _remainingTime = Duration.zero;
  Timer? _countdownTimer;
  Timer? _statusRefreshTimer;

  HajjLiveStatus get status => _status;
  HajjStreamModel? get config => _config;
  String? get errorMessage => _errorMessage;
  Duration get remainingTime => _remainingTime;
  bool get isLive => _config?.status == StreamStatus.live || _timeService.isHajjLiveStarted();

  HajjLiveProvider() {
    initialize();
  }

  Future<void> initialize() async {
    await _timeService.initialize();
    _startCountdown();
    await fetchConfig();
    _startStatusRefresh();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingTime = _timeService.getRemainingTime();
      
      // Auto-switch to LIVE if time is up
      if (_remainingTime == Duration.zero && _config?.status != StreamStatus.live) {
        if (_config != null) {
          _config = HajjStreamModel(
            status: StreamStatus.live,
            isLive: true,
            startTime: _config!.startTime,
            streamUrl: _config!.streamUrl,
            streamId: _config!.streamId,
            streamPlatform: _config!.streamPlatform,
            title: _config!.title,
            subtitle: _config!.subtitle,
            description: _config!.description,
            thumbnailUrl: _config!.thumbnailUrl,
            scheduledDate: _config!.scheduledDate,
            scheduledTimeUtc: _config!.scheduledTimeUtc,
            comingSoonMessage: _config!.comingSoonMessage,
            errorMessage: _config!.errorMessage,
            streamEndedMessage: _config!.streamEndedMessage,
            retryConfig: _config!.retryConfig,
            lastUpdated: _config!.lastUpdated,
          );
        }
      }
      
      notifyListeners();
    });
  }

  void _startStatusRefresh() {
    _statusRefreshTimer?.cancel();
    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      refreshConfig(silent: true);
    });
  }

  Future<void> fetchConfig({bool silent = false}) async {
    if (!silent) {
      _status = HajjLiveStatus.loading;
      notifyListeners();
    }

    try {
      _config = await _configService.fetchConfig();
      _status = HajjLiveStatus.loaded;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      if (!silent) {
        _errorMessage = e.toString();
        _status = HajjLiveStatus.error;
        notifyListeners();
      }
    }
  }

  Future<void> refreshConfig({bool silent = false}) async {
    await fetchConfig(silent: silent);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _statusRefreshTimer?.cancel();
    _retryService.dispose();
    super.dispose();
  }
}
