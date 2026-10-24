import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextField extends StatefulWidget {
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextEditingController? controller;

  const AppTextField({
    super.key,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.controller,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  static const _blue = Color(0xFF0066FF);
  static const _border = Color(0xFFD9D9D9);
  static const _hint = Color(0xFF9E9E9E);
  static const _iconColor = Color(0xFF6B6B6B);

  late bool _oculta = widget.isPassword;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 51,
      child: TextField(
        controller: widget.controller,
        obscureText: _oculta,
        keyboardType: widget.keyboardType,
        style: GoogleFonts.comfortaa(fontSize: 16),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: GoogleFonts.comfortaa(
            fontSize: 16,
            fontWeight: FontWeight.w300,
            color: _hint,
          ),
          prefixIcon: Icon(widget.icon, color: _iconColor),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _oculta
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: _iconColor,
                  ),
                  onPressed: () => setState(() => _oculta = !_oculta),
                )
              : null,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: _blue),
          ),
        ),
      ),
    );
  }
}