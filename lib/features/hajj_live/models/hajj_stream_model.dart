enum StreamStatus {
  coming_soon,
  live,
  ended,
  error
}

class HajjStreamModel {
  final StreamStatus status;
  final bool isLive;
  final String startTime;
  final String streamUrl;
  final String streamId;
  final String streamPlatform;
  final String title;
  final String subtitle;
  final String description;
  final String thumbnailUrl;
  final String scheduledDate;
  final String scheduledTimeUtc;
  final String comingSoonMessage;
  final String errorMessage;
  final String streamEndedMessage;
  final HajjRetryConfig retryConfig;
  final String lastUpdated;

  HajjStreamModel({
    required this.status,
    required this.isLive,
    required this.startTime,
    required this.streamUrl,
    required this.streamId,
    required this.streamPlatform,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.thumbnailUrl,
    required this.scheduledDate,
    required this.scheduledTimeUtc,
    required this.comingSoonMessage,
    required this.errorMessage,
    required this.streamEndedMessage,
    required this.retryConfig,
    required this.lastUpdated,
  });

  factory HajjStreamModel.fromJson(Map<String, dynamic> json) {
    final data = json['hajj_live'] ?? json; // allow top-level or nested
    
    bool isLive = data['isLive'] ?? false;
    String streamUrl = data['streamUrl'] ?? '';
    String startTime = data['startTime'] ?? '';

    StreamStatus status;
    if (data['status'] != null) {
      switch (data['status']) {
        case 'live':
          status = StreamStatus.live;
          break;
        case 'ended':
          status = StreamStatus.ended;
          break;
        case 'error':
          status = StreamStatus.error;
          break;
        case 'coming_soon':
        default:
          status = StreamStatus.coming_soon;
          break;
      }
    } else {
      if (isLive) {
        status = StreamStatus.live;
      } else {
        status = StreamStatus.coming_soon;
      }
    }

    return HajjStreamModel(
      status: status,
      isLive: isLive,
      startTime: startTime,
      streamUrl: streamUrl,
      streamId: data['stream_id'] ?? '',
      streamPlatform: data['stream_platform'] ?? 'youtube',
      title: data['title'] ?? 'Watch Hajj Live',
      subtitle: data['subtitle'] ?? 'Live from Makkah',
      description: data['description'] ?? 'Join millions of Muslims in performing the holy pilgrimage of Hajj.',
      thumbnailUrl: data['thumbnail_url'] ?? '',
      scheduledDate: data['scheduled_date'] ?? '',
      scheduledTimeUtc: data['scheduled_time_utc'] ?? '',
      comingSoonMessage: data['coming_soon_message'] ?? '',
      errorMessage: data['error_message'] ?? '',
      streamEndedMessage: data['stream_ended_message'] ?? '',
      retryConfig: HajjRetryConfig.fromJson(data['retry_config'] ?? {}),
      lastUpdated: data['last_updated'] ?? '',
    );
  }

  factory HajjStreamModel.error(String message) {
    return HajjStreamModel(
      status: StreamStatus.error,
      isLive: false,
      startTime: '',
      streamUrl: '',
      streamId: '',
      streamPlatform: 'youtube',
      title: 'Error',
      subtitle: '',
      description: '',
      thumbnailUrl: '',
      scheduledDate: '',
      scheduledTimeUtc: '',
      comingSoonMessage: '',
      errorMessage: message,
      streamEndedMessage: '',
      retryConfig: HajjRetryConfig(maxRetries: 5, retryIntervalsSeconds: [5, 15, 30, 60, 120]),
      lastUpdated: '',
    );
  }
}

class HajjRetryConfig {
  final int maxRetries;
  final List<int> retryIntervalsSeconds;

  HajjRetryConfig({
    required this.maxRetries,
    required this.retryIntervalsSeconds,
  });

  factory HajjRetryConfig.fromJson(Map<String, dynamic> json) {
    return HajjRetryConfig(
      maxRetries: json['max_retries'] ?? 5,
      retryIntervalsSeconds: List<int>.from(json['retry_intervals_seconds'] ?? [5, 15, 30, 60, 120]),
    );
  }
}
