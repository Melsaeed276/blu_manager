import '../entities/audio_stream_entity.dart';
import '../repositories/audio_stream_repository.dart';
import '../../core/usecases/usecase.dart';

class PlayAudio extends UseCase<bool, PlayAudioParams> {
  final AudioStreamRepository repository;

  PlayAudio(this.repository);

  @override
  Future<bool> call(PlayAudioParams params) {
    return repository.playAudio(params.deviceId, params.filePath);
  }
}

class PauseAudio extends UseCase<void, NoParams> {
  final AudioStreamRepository repository;

  PauseAudio(this.repository);

  @override
  Future<void> call(NoParams params) {
    return repository.pauseAudio();
  }
}

class ResumeAudio extends UseCase<void, NoParams> {
  final AudioStreamRepository repository;

  ResumeAudio(this.repository);

  @override
  Future<void> call(NoParams params) {
    return repository.resumeAudio();
  }
}

class StopAudio extends UseCase<void, NoParams> {
  final AudioStreamRepository repository;

  StopAudio(this.repository);

  @override
  Future<void> call(NoParams params) {
    return repository.stopAudio();
  }
}

class SeekAudio extends UseCase<void, SeekAudioParams> {
  final AudioStreamRepository repository;

  SeekAudio(this.repository);

  @override
  Future<void> call(SeekAudioParams params) {
    return repository.seekTo(params.position);
  }
}

class SetVolume extends UseCase<void, SetVolumeParams> {
  final AudioStreamRepository repository;

  SetVolume(this.repository);

  @override
  Future<void> call(SetVolumeParams params) {
    return repository.setVolume(params.volume);
  }
}

class PickAudioFile extends UseCase<String?, NoParams> {
  final AudioStreamRepository repository;

  PickAudioFile(this.repository);

  @override
  Future<String?> call(NoParams params) {
    return repository.pickAudioFile();
  }
}

class GetAudioStreamState extends StreamUseCase<AudioStreamEntity, NoParams> {
  final AudioStreamRepository repository;

  GetAudioStreamState(this.repository);

  @override
  Stream<AudioStreamEntity> call(NoParams params) {
    return repository.getAudioStreamState();
  }
}

class CheckBluetoothAudioSupport extends UseCase<bool, CheckBluetoothAudioSupportParams> {
  final AudioStreamRepository repository;

  CheckBluetoothAudioSupport(this.repository);

  @override
  Future<bool> call(CheckBluetoothAudioSupportParams params) {
    return repository.isBluetoothAudioSupported(params.deviceId);
  }
}

// Parameter classes
class PlayAudioParams {
  final String deviceId;
  final String filePath;

  PlayAudioParams({required this.deviceId, required this.filePath});
}

class SeekAudioParams {
  final Duration position;

  SeekAudioParams({required this.position});
}

class SetVolumeParams {
  final double volume;

  SetVolumeParams({required this.volume});
}

class CheckBluetoothAudioSupportParams {
  final String deviceId;

  CheckBluetoothAudioSupportParams({required this.deviceId});
}
