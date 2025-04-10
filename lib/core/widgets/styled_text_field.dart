import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StyledTextField extends StatefulWidget {
  final String? labelText;
  final String? hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? minLines;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool enabled;
  final TextInputAction? textInputAction;
  final EdgeInsetsGeometry? contentPadding;
  final Color? glowColor;

  const StyledTextField({
    Key? key,
    this.labelText,
    this.hintText,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.minLines,
    this.autofocus = false,
    this.focusNode,
    this.enabled = true,
    this.textInputAction,
    this.contentPadding,
    this.glowColor,
  }) : super(key: key);

  // Construtor alternativo para compatibilidade com código existente
  // Esta implementação será substituída pelo adaptador global
  static StyledTextField legacy({
    Key? key,
    required String label,
    String? hint,
    TextEditingController? controller,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
    Widget? prefixIcon,
    Widget? suffixIcon,
    int? maxLines = 1,
    int? minLines,
    bool autofocus = false,
    FocusNode? focusNode,
    bool enabled = true,
    TextInputAction? textInputAction,
    EdgeInsetsGeometry? contentPadding,
    Color? glowColor,
  }) {
    IconData? iconData;
    if (prefixIcon is Icon) {
      iconData = (prefixIcon as Icon).icon;
    }

    return StyledTextField(
      key: key,
      labelText: label,
      hintText: hint,
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      prefixIcon: iconData,
      suffixIcon: suffixIcon,
      maxLines: maxLines,
      minLines: minLines,
      autofocus: autofocus,
      focusNode: focusNode,
      enabled: enabled,
      textInputAction: textInputAction,
      contentPadding: contentPadding,
      glowColor: glowColor,
    );
  }

  @override
  _StyledTextFieldState createState() => _StyledTextFieldState();
}

class _StyledTextFieldState extends State<StyledTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = widget.glowColor ?? AppTheme.secondaryColor;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: glowColor.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: TextFormField(
        controller: widget.controller,
        obscureText: widget.obscureText && !_showPassword,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onSubmitted,
        maxLines: widget.obscureText ? 1 : widget.maxLines,
        minLines: widget.minLines,
        autofocus: widget.autofocus,
        focusNode: _focusNode,
        enabled: widget.enabled,
        textInputAction: widget.textInputAction,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          contentPadding: widget.contentPadding ??
              EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                    color: _isFocused ? glowColor : Colors.white.withOpacity(0.6),
                  ),
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                )
              : widget.suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: glowColor,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppTheme.errorColor,
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppTheme.errorColor,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: AppTheme.darkCardColor,
          labelStyle: TextStyle(
            color: _isFocused ? glowColor : Colors.white.withOpacity(0.7),
            fontWeight: _isFocused ? FontWeight.bold : FontWeight.normal,
          ),
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.3),
          ),
          errorStyle: TextStyle(
            color: AppTheme.errorColor,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
