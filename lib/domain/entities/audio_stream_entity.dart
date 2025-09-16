import 'package:equatable/equatable.dart';

class AudioStreamEntity extends Equatable {
  final String id;
  final String trackName;
  final String filePath;
  final Duration duration;
  final Duration currentPosition;
  final AudioStreamState state;
  final double volume;
  final String deviceId;

  const AudioStreamEntity({
    required this.id,
    required this.trackName,
    required this.filePath,
    required this.duration,
    required this.currentPosition,
    required this.state,
    required this.volume,
    required this.deviceId,
  });

  AudioStreamEntity copyWith({
    String? id,
    String? trackName,
    String? filePath,
    Duration? duration,
    Duration? currentPosition,
    AudioStreamState? state,
    double? volume,
    String? deviceId,
  }) {
    return AudioStreamEntity(
      id: id ?? this.id,
      trackName: trackName ?? this.trackName,
      filePath: filePath ?? this.filePath,
      duration: duration ?? this.duration,
      currentPosition: currentPosition ?? this.currentPosition,
      state: state ?? this.state,
      volume: volume ?? this.volume,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  double get progress {
    if (duration.inMilliseconds == 0) return 0.0;
    return currentPosition.inMilliseconds / duration.inMilliseconds;
  }

  @override
  List<Object?> get props => [
        id,
        trackName,
        filePath,
        duration,
        currentPosition,
        state,
        volume,
        deviceId,
      ];
}

enum AudioStreamState {
  stopped,
  loading,
  buffering,
  playing,
  paused,
  error,
}
