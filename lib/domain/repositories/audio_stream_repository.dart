import '../entities/audio_stream_entity.dart';

abstract class AudioStreamRepository {
  Future<String?> pickAudioFile();
  Future<bool> playAudio(String deviceId, String filePath);
  Future<void> pauseAudio();
  Future<void> resumeAudio();
  Future<void> stopAudio();
  Future<void> seekTo(Duration position);
  Future<void> setVolume(double volume);
  Stream<AudioStreamEntity> getAudioStreamState();
  Future<bool> isBluetoothAudioSupported(String deviceId);
}
