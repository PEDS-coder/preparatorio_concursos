import 'package:flutter/material.dart';

/// Widget para implementar animações suaves para transições entre telas
class AnimatedSwitcherScreen extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  
  const AnimatedSwitcherScreen({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  }) : super(key: key);
  
  @override
  _AnimatedSwitcherScreenState createState() => _AnimatedSwitcherScreenState();
}

class _AnimatedSwitcherScreenState extends State<AnimatedSwitcherScreen> {
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: widget.duration,
      switchInCurve: widget.curve,
      switchOutCurve: widget.curve,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
