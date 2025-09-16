import '../../domain/entities/audio_stream_entity.dart';
import '../../domain/repositories/audio_stream_repository.dart';
import '../datasources/audio_stream_datasource.dart';

class AudioStreamRepositoryImpl implements AudioStreamRepository {
  final AudioStreamDataSource dataSource;

  AudioStreamRepositoryImpl({required this.dataSource});

  @override
  Future<String?> pickAudioFile() {
    return dataSource.pickAudioFile();
  }

  @override
  Future<bool> playAudio(String deviceId, String filePath) {
    return dataSource.playAudio(deviceId, filePath);
  }

  @override
  Future<void> pauseAudio() {
    return dataSource.pauseAudio();
  }

  @override
  Future<void> resumeAudio() {
    return dataSource.resumeAudio();
  }

  @override
  Future<void> stopAudio() {
    return dataSource.stopAudio();
  }

  @override
  Future<void> seekTo(Duration position) {
    return dataSource.seekTo(position);
  }

  @override
  Future<void> setVolume(double volume) {
    return dataSource.setVolume(volume);
  }

  @override
  Stream<AudioStreamEntity> getAudioStreamState() {
    return dataSource.getAudioStreamState();
  }

  @override
  Future<bool> isBluetoothAudioSupported(String deviceId) {
    return dataSource.isBluetoothAudioSupported(deviceId);
  }
}
