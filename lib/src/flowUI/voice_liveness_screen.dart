import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

import '../verification/verification.dart';

class VoiceLivenessScreen extends StatefulWidget {
  const VoiceLivenessScreen({super.key});
  @override
  State<VoiceLivenessScreen> createState() => _VoiceLivenessScreenState();
}

class _VoiceLivenessScreenState extends State<VoiceLivenessScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  String? _audioPath;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    if (_audioPath != null) File(_audioPath!).delete().catchError((e) => debugPrint("Error deleting temp file: $e"));
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      _recordingTimer?.cancel();
      final path = await _audioRecorder.stop();
      if (mounted) {
        setState(() {
          _isRecording = false;
          _audioPath = path;
        });
      }
    } else {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.wav';
        await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.wav), path: path);
        if (mounted) {
          setState(() {
            _isRecording = true;
            _audioPath = null;
            _recordingDuration = Duration.zero;
          });
          _startRecordingTimer();
        }
      }
    }
  }

  void _startRecordingTimer() {
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _recordingDuration += const Duration(seconds: 1));
    });
  }

  Future<void> _playRecording() async {
    if (_audioPath != null) {
      await _audioPlayer.play(DeviceFileSource(_audioPath!));
    }
  }

  Future<void> _submit() async {
    if (_audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please record your voice first.")));
      return;
    }

    final get = context.read<Verification>();
    final success = await get.submitVoiceLiveness(context, audioFile: File(_audioPath!));

    if (!mounted) return;
    if (success) {
      get.nextScreen(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(get.errorMessage ?? 'Verification failed.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(children: [
              Text("Please press record button to start recording", textAlign: TextAlign.center),
            ]),
          ),
        ),
        const SizedBox(height: 32),
        _buildRecordingControls(),
        const SizedBox(height: 48),
        ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          onPressed: _audioPath == null || _isRecording ? null : _submit,
          child: const Text('Next'),
        ),
      ],
    );
  }

  Widget _buildRecordingControls() {
    final theme = Theme.of(context);
    return Column(
      children: [
        if (_isRecording) Text(_formatDuration(_recordingDuration), style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        FloatingActionButton.large(
          onPressed: _toggleRecording,
          child: Icon(
            _isRecording ? Icons.stop : Icons.mic,
            size: 48,
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 16),
        if (_audioPath != null && !_isRecording)
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
                icon: const Icon(Icons.play_circle_fill),
                iconSize: 40,
                color: theme.colorScheme.secondary,
                onPressed: _playRecording,
                tooltip: 'Play Recording'),
            IconButton(
                icon: const Icon(Icons.delete),
                iconSize: 40,
                color: theme.colorScheme.secondary,
                onPressed: () => setState(() => _audioPath = null),
                tooltip: 'Delete and Re-record'),
          ]),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
