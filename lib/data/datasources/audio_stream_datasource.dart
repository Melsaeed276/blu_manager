import 'dart:async';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import '../models/audio_stream_model.dart';
import '../../domain/entities/audio_stream_entity.dart';

abstract class AudioStreamDataSource {
  Future<String?> pickAudioFile();
  Future<bool> playAudio(String deviceId, String filePath);
  Future<void> pauseAudio();
  Future<void> resumeAudio();
  Future<void> stopAudio();
  Future<void> seekTo(Duration position);
  Future<void> setVolume(double volume);
  Stream<AudioStreamModel> getAudioStreamState();
  Future<bool> isBluetoothAudioSupported(String deviceId);
}

class AudioStreamDataSourceImpl implements AudioStreamDataSource {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final StreamController<AudioStreamModel> _audioStateController =
      StreamController<AudioStreamModel>.broadcast();

  AudioStreamModel _currentState = const AudioStreamModel(
    id: '',
    trackName: '',
    filePath: '',
    duration: Duration.zero,
    currentPosition: Duration.zero,
    state: AudioStreamState.stopped,
    volume: 1.0,
    deviceId: '',
  );

  AudioStreamDataSourceImpl() {
    _initializeAudioSession();
    _setupAudioPlayerListeners();
  }

  Future<void> _initializeAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // Configure for Bluetooth audio output
      await session.setActive(true);
    } catch (e) {
      print('Failed to initialize audio session: $e');
    }
  }

  void _setupAudioPlayerListeners() {
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((playerState) {
      AudioStreamState state;
      switch (playerState.processingState) {
        case ProcessingState.idle:
          state = AudioStreamState.stopped;
          break;
        case ProcessingState.loading:
          state = AudioStreamState.loading;
          break;
        case ProcessingState.buffering:
          state = AudioStreamState.buffering;
          break;
        case ProcessingState.ready:
          state = playerState.playing ? AudioStreamState.playing : AudioStreamState.paused;
          break;
        case ProcessingState.completed:
          state = AudioStreamState.stopped;
          break;
      }

      _updateState(_currentState.copyWith(state: state));
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((position) {
      _updateState(_currentState.copyWith(currentPosition: position));
    });

    // Listen to duration changes
    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        _updateState(_currentState.copyWith(duration: duration));
      }
    });

    // Listen to volume changes
    _audioPlayer.volumeStream.listen((volume) {
      _updateState(_currentState.copyWith(volume: volume));
    });
  }

  void _updateState(AudioStreamModel newState) {
    _currentState = newState;
    _audioStateController.add(newState);
  }

  @override
  Future<String?> pickAudioFile() async {
    try {
      final result = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        print('Audio file picked: $filePath');
        return filePath;
      }

      return null;
    } catch (e) {
      print('Audio file picker error: $e');
      throw Exception('Failed to pick audio file: $e');
    }
  }

  @override
  Future<bool> playAudio(String deviceId, String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Audio file does not exist');
      }

      // Check if device supports audio streaming
      final isSupported = await isBluetoothAudioSupported(deviceId);
      if (!isSupported) {
        print('Device does not support Bluetooth audio streaming');
        return false;
      }

      // Configure audio session for Bluetooth output
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // Set audio source
      await _audioPlayer.setFilePath(filePath);

      // Extract track name from file path
      final trackName = filePath.split('/').last.replaceAll(RegExp(r'\.[^.]*$'), '');

      // Update state
      final newState = AudioStreamModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        trackName: trackName,
        filePath: filePath,
        duration: _audioPlayer.duration ?? Duration.zero,
        currentPosition: Duration.zero,
        state: AudioStreamState.loading,
        volume: _audioPlayer.volume,
        deviceId: deviceId,
      );
      _updateState(newState);

      // Start playback
      await _audioPlayer.play();

      print('Started audio playback to device: $deviceId');
      return true;
    } catch (e) {
      print('Audio playback error: $e');
      _updateState(_currentState.copyWith(state: AudioStreamState.error));
      return false;
    }
  }

  @override
  Future<void> pauseAudio() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      print('Audio pause error: $e');
      _updateState(_currentState.copyWith(state: AudioStreamState.error));
    }
  }

  @override
  Future<void> resumeAudio() async {
    try {
      await _audioPlayer.play();
    } catch (e) {
      print('Audio resume error: $e');
      _updateState(_currentState.copyWith(state: AudioStreamState.error));
    }
  }

  @override
  Future<void> stopAudio() async {
    try {
      await _audioPlayer.stop();
      _updateState(_currentState.copyWith(
        state: AudioStreamState.stopped,
        currentPosition: Duration.zero,
      ));
    } catch (e) {
      print('Audio stop error: $e');
      _updateState(_currentState.copyWith(state: AudioStreamState.error));
    }
  }

  @override
  Future<void> seekTo(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      print('Audio seek error: $e');
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      print('Audio volume error: $e');
    }
  }

  @override
  Stream<AudioStreamModel> getAudioStreamState() {
    return _audioStateController.stream;
  }

  @override
  Future<bool> isBluetoothAudioSupported(String deviceId) async {
    try {
      // Get connected devices
      final connectedDevices = fbp.FlutterBluePlus.connectedDevices;
      fbp.BluetoothDevice? targetDevice;

      for (final device in connectedDevices) {
        if (device.remoteId.toString() == deviceId) {
          targetDevice = device;
          break;
        }
      }

      if (targetDevice == null) {
        return false;
      }

      // Discover services to check for audio support
      final services = await targetDevice.discoverServices();

      // Check for A2DP (Advanced Audio Distribution Profile) service
      // A2DP Service UUID: 0x110D
      for (final service in services) {
        final serviceUuid = service.uuid.toString().toLowerCase();

        // Check for A2DP Source/Sink services
        if (serviceUuid.contains('110d') || // A2DP
            serviceUuid.contains('110a') || // Audio Source
            serviceUuid.contains('110b') || // Audio Sink
            serviceUuid.contains('111e')) { // Hands-Free
          print('Found audio service: ${service.uuid}');
          return true;
        }
      }

      // For iOS/macOS, the system handles Bluetooth audio routing automatically
      // if the device is connected and supports audio
      if (Platform.isIOS || Platform.isMacOS) {
        print('iOS/macOS: System will handle Bluetooth audio routing');
        return true;
      }

      print('No audio services found on device');
      return false;
    } catch (e) {
      print('Error checking Bluetooth audio support: $e');
      return false;
    }
  }

  void dispose() {
    _audioPlayer.dispose();
    _audioStateController.close();
  }
}
