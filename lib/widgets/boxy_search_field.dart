import 'package:flutter/material.dart';

class BoxySearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final bool autoFocus;
  final String hintText;

  const BoxySearchField({
    super.key,
    required this.onChanged,
    this.autoFocus = false,
    this.hintText = "Buscar...",
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        autofocus: autoFocus,
        onChanged: onChanged,
        style: TextStyle(color: Colors.white, fontFamily: 'Chalet'),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          filled: true,
          fillColor: const Color(0xFF1A1A1A),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Colors.white12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Colors.white12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
