import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime targetDate;
  final String title;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? accentColor;

  const CountdownTimer({
    Key? key,
    required this.targetDate,
    required this.title,
    this.backgroundColor,
    this.textColor,
    this.accentColor,
  }) : super(key: key);

  @override
  _CountdownTimerState createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  late Duration _remainingTime;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _calculateRemainingTime() {
    final now = DateTime.now();
    if (widget.targetDate.isAfter(now)) {
      _remainingTime = widget.targetDate.difference(now);
      _isExpired = false;
    } else {
      _remainingTime = Duration.zero;
      _isExpired = true;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _calculateRemainingTime();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = _remainingTime.inDays;
    final hours = _remainingTime.inHours.remainder(24);
    final minutes = _remainingTime.inMinutes.remainder(60);
    final seconds = _remainingTime.inSeconds.remainder(60);

    final backgroundColor = widget.backgroundColor ?? AppTheme.darkCardColor;
    final textColor = widget.textColor ?? Colors.white;
    final accentColor = widget.accentColor ?? AppTheme.primaryColor;

    return Card(
      elevation: 4,
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: accentColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Icon(
                  Icons.timer,
                  color: accentColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _isExpired
                ? const Center(
                    child: Text(
                      'Expirado',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTimeUnit(days, 'Dias', textColor, accentColor),
                      _buildDivider(textColor),
                      _buildTimeUnit(hours, 'Horas', textColor, accentColor),
                      _buildDivider(textColor),
                      _buildTimeUnit(minutes, 'Min', textColor, accentColor),
                      _buildDivider(textColor),
                      _buildTimeUnit(seconds, 'Seg', textColor, accentColor),
                    ],
                  ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Data: ${_formatDate(widget.targetDate)}',
                style: TextStyle(
                  fontSize: 14,
                  color: textColor.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeUnit(int value, String label, Color textColor, Color accentColor) {
    return Column(
      children: [
        Text(
          value.toString().padLeft(2, '0'),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textColor.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(Color textColor) {
    return Text(
      ':',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
