import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/audio_stream_entity.dart';
import '../../domain/entities/bluetooth_device_entity.dart';
import '../providers/viewmodel_providers.dart';
import '../viewmodels/audio_player_viewmodel.dart';

class BluetoothAudioPlayer extends ConsumerStatefulWidget {
  final BluetoothDeviceEntity device;

  const BluetoothAudioPlayer({
    super.key,
    required this.device,
  });

  @override
  ConsumerState<BluetoothAudioPlayer> createState() => _BluetoothAudioPlayerState();
}

class _BluetoothAudioPlayerState extends ConsumerState<BluetoothAudioPlayer> {
  @override
  void initState() {
    super.initState();
    // Check audio support when widget loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.device.deviceType == BluetoothDeviceType.speaker ||
          widget.device.deviceType == BluetoothDeviceType.headphones ||
          widget.device.deviceType == BluetoothDeviceType.earbuds) {
        ref.read(audioPlayerViewModelProvider.notifier).checkAudioSupport(widget.device.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioPlayerViewModelProvider);
    final audioPlayer = ref.read(audioPlayerViewModelProvider.notifier);

    // Only show for audio devices
    if (widget.device.deviceType != BluetoothDeviceType.speaker &&
        widget.device.deviceType != BluetoothDeviceType.headphones &&
        widget.device.deviceType != BluetoothDeviceType.earbuds) {
      return const SizedBox.shrink();
    }

    // Show error if device doesn't support audio
    if (!audioState.isSupported) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(
                Icons.music_off,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                'Audio streaming not available for this ${_getDeviceTypeName()}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.music_note,
                  color: Colors.deepOrange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Music Player',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getDeviceTypeName(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Current track info
            if (audioState.hasAudio) ...[
              _buildTrackInfo(audioState.currentStream!),
              const SizedBox(height: 12),
              _buildProgressBar(audioState.currentStream!, audioPlayer),
              const SizedBox(height: 12),
            ],

            // Control buttons
            _buildControlButtons(audioState, audioPlayer),

            // Volume control
            if (audioState.hasAudio) ...[
              const SizedBox(height: 12),
              _buildVolumeControl(audioState.currentStream!, audioPlayer),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrackInfo(AudioStreamEntity stream) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stream.trackName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              _getStateIcon(stream.state),
              size: 16,
              color: _getStateColor(stream.state),
            ),
            const SizedBox(width: 4),
            Text(
              _getStateText(stream.state),
              style: TextStyle(
                color: _getStateColor(stream.state),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar(AudioStreamEntity stream, AudioPlayerViewModel player) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            trackHeight: 4,
          ),
          child: Slider(
            value: stream.progress.clamp(0.0, 1.0),
            onChanged: (value) {
              final position = Duration(
                milliseconds: (value * stream.duration.inMilliseconds).round(),
              );
              player.seekTo(position);
            },
            activeColor: Colors.deepOrange,
            inactiveColor: Colors.grey.shade300,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(stream.currentPosition),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              _formatDuration(stream.duration),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlButtons(AudioPlayerState audioState, AudioPlayerViewModel player) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Stop button
        if (audioState.hasAudio)
          IconButton(
            onPressed: player.stopMusic,
            icon: const Icon(Icons.stop),
            iconSize: 32,
            color: Colors.grey.shade600,
          ),

        const SizedBox(width: 16),

        // Play/Pause button
        Container(
          decoration: BoxDecoration(
            color: Colors.deepOrange,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: audioState.isLoading
                ? null
                : () {
                    if (audioState.isPlaying) {
                      player.pauseMusic();
                    } else if (audioState.isPaused) {
                      player.resumeMusic();
                    } else {
                      player.playMusic(widget.device.id);
                    }
                  },
            icon: audioState.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    audioState.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
            iconSize: 32,
          ),
        ),

        const SizedBox(width: 16),

        // Select music button
        IconButton(
          onPressed: () => player.playMusic(widget.device.id),
          icon: const Icon(Icons.library_music),
          iconSize: 32,
          color: Colors.grey.shade600,
        ),
      ],
    );
  }

  Widget _buildVolumeControl(AudioStreamEntity stream, AudioPlayerViewModel player) {
    return Row(
      children: [
        const Icon(Icons.volume_down, size: 20, color: Colors.grey),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              trackHeight: 4,
            ),
            child: Slider(
              value: stream.volume,
              onChanged: player.setVolume,
              activeColor: Colors.deepOrange,
              inactiveColor: Colors.grey.shade300,
            ),
          ),
        ),
        const Icon(Icons.volume_up, size: 20, color: Colors.grey),
      ],
    );
  }

  String _getDeviceTypeName() {
    switch (widget.device.deviceType) {
      case BluetoothDeviceType.speaker:
        return 'Speaker';
      case BluetoothDeviceType.headphones:
        return 'Headphones';
      case BluetoothDeviceType.earbuds:
        return 'Earbuds';
      default:
        return 'Audio Device';
    }
  }

  IconData _getStateIcon(AudioStreamState state) {
    switch (state) {
      case AudioStreamState.playing:
        return Icons.play_circle_filled;
      case AudioStreamState.paused:
        return Icons.pause_circle_filled;
      case AudioStreamState.loading:
      case AudioStreamState.buffering:
        return Icons.hourglass_empty;
      case AudioStreamState.error:
        return Icons.error;
      case AudioStreamState.stopped:
      return Icons.stop_circle;
    }
  }

  Color _getStateColor(AudioStreamState state) {
    switch (state) {
      case AudioStreamState.playing:
        return Colors.green;
      case AudioStreamState.paused:
        return Colors.orange;
      case AudioStreamState.loading:
      case AudioStreamState.buffering:
        return Colors.blue;
      case AudioStreamState.error:
        return Colors.red;
      case AudioStreamState.stopped:
      return Colors.grey;
    }
  }

  String _getStateText(AudioStreamState state) {
    switch (state) {
      case AudioStreamState.playing:
        return 'Playing';
      case AudioStreamState.paused:
        return 'Paused';
      case AudioStreamState.loading:
        return 'Loading...';
      case AudioStreamState.buffering:
        return 'Buffering...';
      case AudioStreamState.error:
        return 'Error';
      case AudioStreamState.stopped:
      return 'Stopped';
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
}
