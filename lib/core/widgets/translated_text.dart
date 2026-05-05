import 'package:flutter/material.dart';

import 'package:first_app/services/gemini_translation_service.dart';
import 'package:first_app/services/translation_preferences_service.dart';

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
  static final GeminiTranslationService _translator = GeminiTranslationService();
  static final Map<String, String> _cache = <String, String>{};

  Future<String> _resolveText() async {
    if (!TranslationPreferencesService.isAmharicEnabled.value) {
      return widget.text;
    }

    final original = widget.text.trim();
    if (original.isEmpty) return widget.text;

    final cached = _cache[original];
    if (cached != null && cached.isNotEmpty) return cached;

    try {
      final result = await _translator.translate(text: original);
      _cache[original] = result.am;
      return result.am;
    } catch (_) {
      return widget.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: TranslationPreferencesService.isAmharicEnabled,
      builder: (context, _, __) {
        return FutureBuilder<String>(
          future: _resolveText(),
          builder: (context, snapshot) {
            final display = snapshot.data ?? widget.text;
            return Text(
              display,
              style: widget.style,
              textAlign: widget.textAlign,
              maxLines: widget.maxLines,
              overflow: widget.overflow,
            );
          },
        );
      },
    );
  }
}
