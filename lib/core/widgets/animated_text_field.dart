import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget para implementar um campo de texto com animação
class AnimatedTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Color? fillColor;
  final Color? focusColor;
  final Color? borderColor;
  final Color? textColor;
  final Color? labelColor;
  final Color? cursorColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? contentPadding;
  final FocusNode? focusNode;
  final Duration animationDuration;
  
  const AnimatedTextField({
    Key? key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.prefixIcon,
    this.suffixIcon,
    this.fillColor,
    this.focusColor,
    this.borderColor,
    this.textColor,
    this.labelColor,
    this.cursorColor,
    this.borderRadius,
    this.contentPadding,
    this.focusNode,
    this.animationDuration = const Duration(milliseconds: 200),
  }) : super(key: key);
  
  @override
  _AnimatedTextFieldState createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<AnimatedTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  
  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }
  
  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }
  
  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fillColor = widget.fillColor ?? theme.colorScheme.surface;
    final focusColor = widget.focusColor ?? theme.colorScheme.primary.withOpacity(0.1);
    final borderColor = widget.borderColor ?? theme.colorScheme.primary;
    final textColor = widget.textColor ?? theme.colorScheme.onSurface;
    final labelColor = widget.labelColor ?? theme.colorScheme.primary;
    final cursorColor = widget.cursorColor ?? theme.colorScheme.primary;
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(8.0);
    final contentPadding = widget.contentPadding ?? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
    
    return AnimatedContainer(
      duration: widget.animationDuration,
      decoration: BoxDecoration(
        color: _isFocused ? focusColor : fillColor,
        borderRadius: borderRadius,
        border: Border.all(
          color: widget.errorText != null
              ? theme.colorScheme.error
              : _isFocused
                  ? borderColor
                  : borderColor.withOpacity(0.5),
          width: _isFocused ? 2.0 : 1.0,
        ),
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onSubmitted,
        validator: widget.validator,
        inputFormatters: widget.inputFormatters,
        maxLength: widget.maxLength,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        cursorColor: cursorColor,
        style: TextStyle(
          color: textColor,
          fontSize: 16.0,
        ),
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          helperText: widget.helperText,
          errorText: widget.errorText,
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.suffixIcon,
          contentPadding: contentPadding,
          border: InputBorder.none,
          labelStyle: TextStyle(
            color: _isFocused ? labelColor : labelColor.withOpacity(0.7),
            fontSize: 16.0,
          ),
          hintStyle: TextStyle(
            color: textColor.withOpacity(0.5),
            fontSize: 16.0,
          ),
          errorStyle: TextStyle(
            color: theme.colorScheme.error,
            fontSize: 12.0,
          ),
          helperStyle: TextStyle(
            color: textColor.withOpacity(0.7),
            fontSize: 12.0,
          ),
          counterStyle: TextStyle(
            color: textColor.withOpacity(0.7),
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }
}
