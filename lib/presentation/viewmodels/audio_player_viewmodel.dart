import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/audio_stream_entity.dart';
import '../../domain/usecases/audio_stream_usecases.dart';
import '../../core/usecases/usecase.dart';
import '../providers/dependency_injection.dart';

// State for Audio Player
class AudioPlayerState {
  final AudioStreamEntity? currentStream;
  final bool isSupported;
  final String? errorMessage;
  final String? successMessage;

  const AudioPlayerState({
    this.currentStream,
    this.isSupported = false,
    this.errorMessage,
    this.successMessage,
  });

  AudioPlayerState copyWith({
    AudioStreamEntity? currentStream,
    bool? isSupported,
    String? errorMessage,
    String? successMessage,
  }) {
    return AudioPlayerState(
      currentStream: currentStream ?? this.currentStream,
      isSupported: isSupported ?? this.isSupported,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  bool get isPlaying => currentStream?.state == AudioStreamState.playing;
  bool get isPaused => currentStream?.state == AudioStreamState.paused;
  bool get isLoading => currentStream?.state == AudioStreamState.loading ||
                       currentStream?.state == AudioStreamState.buffering;
  bool get hasAudio => currentStream != null;
}

// ViewModel for Audio Player
class AudioPlayerViewModel extends Notifier<AudioPlayerState> {
  @override
  AudioPlayerState build() {
    _initialize();
    return const AudioPlayerState();
  }

  void _initialize() {
    // Listen to audio stream state changes
    ref.read(getAudioStreamStateProvider).call(const NoParams()).listen(
      (audioStream) {
        state = state.copyWith(currentStream: audioStream);
      },
      onError: (error) {
        state = state.copyWith(
          errorMessage: 'Audio stream error: ${error.toString()}',
        );
      },
    );
  }

  Future<void> checkAudioSupport(String deviceId) async {
    try {
      final isSupported = await ref.read(checkBluetoothAudioSupportProvider).call(
        CheckBluetoothAudioSupportParams(deviceId: deviceId),
      );

      state = state.copyWith(isSupported: isSupported);

      if (!isSupported) {
        state = state.copyWith(
          errorMessage: 'This device does not support Bluetooth audio streaming',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isSupported: false,
        errorMessage: 'Failed to check audio support: ${e.toString()}',
      );
    }
  }

  Future<void> playMusic(String deviceId) async {
    try {
      // Pick audio file
      final filePath = await ref.read(pickAudioFileProvider).call(const NoParams());
      if (filePath == null) return;

      // Play audio
      final success = await ref.read(playAudioProvider).call(
        PlayAudioParams(deviceId: deviceId, filePath: filePath),
      );

      if (success) {
        state = state.copyWith(
          successMessage: 'Started streaming music to Bluetooth speaker',
        );
      } else {
        state = state.copyWith(
          errorMessage: 'Failed to start music streaming. Make sure the device supports audio.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Music streaming error: ${e.toString()}',
      );
    }
  }

  Future<void> pauseMusic() async {
    try {
      await ref.read(pauseAudioProvider).call(const NoParams());
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to pause music: ${e.toString()}',
      );
    }
  }

  Future<void> resumeMusic() async {
    try {
      await ref.read(resumeAudioProvider).call(const NoParams());
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to resume music: ${e.toString()}',
      );
    }
  }

  Future<void> stopMusic() async {
    try {
      await ref.read(stopAudioProvider).call(const NoParams());
      state = state.copyWith(
        successMessage: 'Music streaming stopped',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to stop music: ${e.toString()}',
      );
    }
  }

  Future<void> seekTo(Duration position) async {
    try {
      await ref.read(seekAudioProvider).call(SeekAudioParams(position: position));
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to seek: ${e.toString()}',
      );
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await ref.read(setVolumeProvider).call(SetVolumeParams(volume: volume));
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to set volume: ${e.toString()}',
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(
      errorMessage: null,
      successMessage: null,
    );
  }
}
