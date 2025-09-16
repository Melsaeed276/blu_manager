import '../../domain/entities/audio_stream_entity.dart';

class AudioStreamModel extends AudioStreamEntity {
  const AudioStreamModel({
    required super.id,
    required super.trackName,
    required super.filePath,
    required super.duration,
    required super.currentPosition,
    required super.state,
    required super.volume,
    required super.deviceId,
  });

  factory AudioStreamModel.fromEntity(AudioStreamEntity entity) {
    return AudioStreamModel(
      id: entity.id,
      trackName: entity.trackName,
      filePath: entity.filePath,
      duration: entity.duration,
      currentPosition: entity.currentPosition,
      state: entity.state,
      volume: entity.volume,
      deviceId: entity.deviceId,
    );
  }

  @override
  AudioStreamModel copyWith({
    String? id,
    String? trackName,
    String? filePath,
    Duration? duration,
    Duration? currentPosition,
    AudioStreamState? state,
    double? volume,
    String? deviceId,
  }) {
    return AudioStreamModel(
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

  String get formattedDuration {
    return _formatDuration(duration);
  }

  String get formattedCurrentPosition {
    return _formatDuration(currentPosition);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }
}
