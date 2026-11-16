import 'package:flutter/material.dart';

import 'package:first_app/services/gemini_translation_service.dart';
import 'package:first_app/services/translation_preferences_service.dart';

/// Shows [text], translated to Amharic when the user enabled translation.
/// Any translation failure (offline, timeout, 429/502/503, ...) silently
/// falls back to the original text.
class TranslatedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const TranslatedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  State<TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends State<TranslatedText> {
  static final GeminiTranslationService _translator =
      GeminiTranslationService();

  /// Created only when the text or the translation toggle changes — never in
  /// build, so rebuilds don't fire new requests. (The service also caches.)
  late Future<String> _future;

  @override
  void initState() {
    super.initState();
    _future = _resolveText();
    TranslationPreferencesService.isAmharicEnabled
        .addListener(_onPreferenceChanged);
  }

  @override
  void didUpdateWidget(covariant TranslatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _future = _resolveText();
    }
  }

  @override
  void dispose() {
    TranslationPreferencesService.isAmharicEnabled
        .removeListener(_onPreferenceChanged);
    super.dispose();
  }

  void _onPreferenceChanged() {
    if (!mounted) return;
    setState(() => _future = _resolveText());
  }

  Future<String> _resolveText() async {
    final text = widget.text;
    if (!TranslationPreferencesService.isAmharicEnabled.value) return text;

    final original = text.trim();
    if (original.isEmpty) return text;

    try {
      final result = await _translator.translate(text: original);
      return result.am;
    } catch (_) {
      return text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _future,
      builder: (context, snapshot) {
        // FutureBuilder keeps the previous future's data while a new one is
        // pending, so only trust data from a completed future (else a stale
        // translation of the old text could show).
        final display =
            snapshot.connectionState == ConnectionState.done && snapshot.hasData
                ? snapshot.data!
                : widget.text;
        return Text(
          display,
          style: widget.style,
          textAlign: widget.textAlign,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
        );
      },
    );
  }
}
