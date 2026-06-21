import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class RiskScoreBadge extends StatelessWidget {
  final int score;
  final double size;

  const RiskScoreBadge({super.key, required this.score, this.size = 56});

  Color get _color {
    if (score < 20) return SentriColors.riskSafe;
    if (score < 40) return SentriColors.riskLow;
    if (score < 60) return SentriColors.riskMedium;
    if (score < 80) return SentriColors.riskHigh;
    return SentriColors.riskCritical;
  }

  String get _label {
    if (score < 20) return 'Safe';
    if (score < 40) return 'Low';
    if (score < 60) return 'Medium';
    if (score < 80) return 'High';
    return 'Critical';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: score / 100,
            strokeWidth: size * 0.08,
            backgroundColor: _color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(_color),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.w800,
                  color: _color,
                ),
              ),
              Text(
                _label,
                style: TextStyle(
                  fontSize: size * 0.14,
                  color: _color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
