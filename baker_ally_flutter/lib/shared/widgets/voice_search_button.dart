import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Mic button for search bars -- on-device speech recognition via
/// `speech_to_text` (00_common_architecture.md §19/§21, Milestone readme/Voice
/// Search.md). Recognized words are pushed into [onResult] the same way a
/// keystroke would be, so callers just wire it into their existing debounced
/// search path -- no separate voice-search codepath to maintain.
class VoiceSearchButton extends StatefulWidget {
  const VoiceSearchButton({super.key, required this.onResult});

  final ValueChanged<String> onResult;

  @override
  State<VoiceSearchButton> createState() => _VoiceSearchButtonState();
}

class _VoiceSearchButtonState extends State<VoiceSearchButton> {
  final _speech = SpeechToText();
  bool _listening = false;

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    widget.onResult(result.recognizedWords);
  }

  void _onSpeechStatus(String status) {
    // "done"/"notListening" fire when the user stops talking or the
    // recognizer times out -- either way the mic should stop looking active.
    if ((status == 'done' || status == 'notListening') && mounted) {
      setState(() => _listening = false);
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    if (!mounted) return;
    setState(() => _listening = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Voice search error: ${error.errorMsg}')),
    );
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    // initialize() also handles the RECORD_AUDIO permission prompt on first
    // use -- returns false if denied or if no recognition service is
    // available on this device, rather than throwing.
    final available = await _speech.initialize(onError: _onSpeechError, onStatus: _onSpeechStatus);
    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Voice search isn't available -- check microphone permission")),
      );
      return;
    }

    setState(() => _listening = true);
    await _speech.listen(onResult: _onSpeechResult);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(_listening ? Icons.mic : Icons.mic_none),
      color: _listening ? Theme.of(context).colorScheme.primary : null,
      tooltip: 'Voice search',
      onPressed: _toggleListening,
    );
  }
}
