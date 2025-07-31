import 'package:flutter/material.dart';
import 'dart:async';
import '../../../models/daily_mission_model.dart';

/// Widget que exibe um cronômetro em tempo real para missões
class MissionTimer extends StatefulWidget {
  final DailyMissionModel mission;
  final VoidCallback? onExpired;
  final bool showIcon;
  final TextStyle? textStyle;
  
  const MissionTimer({
    super.key,
    required this.mission,
    this.onExpired,
    this.showIcon = true,
    this.textStyle,
  });

  @override
  State<MissionTimer> createState() => _MissionTimerState();
}

class _MissionTimerState extends State<MissionTimer> {
  Timer? _timer;
  Duration _timeRemaining = Duration.zero;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _updateTimeRemaining();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimeRemaining();
    });
  }

  void _updateTimeRemaining() {
    final now = DateTime.now();
    final remaining = widget.mission.deadline.difference(now);
    
    setState(() {
      if (remaining.isNegative) {
        _timeRemaining = Duration.zero;
        if (!_isExpired) {
          _isExpired = true;
          widget.onExpired?.call();
        }
      } else {
        _timeRemaining = remaining;
        _isExpired = false;
      }
    });
  }

  Color _getTimerColor() {
    if (_isExpired) return Colors.red;
    
    final totalMinutes = widget.mission.deadline.difference(widget.mission.date).inMinutes;
    final remainingMinutes = _timeRemaining.inMinutes;
    final percentage = remainingMinutes / totalMinutes;
    
    if (percentage > 0.5) return Colors.green;
    if (percentage > 0.25) return Colors.orange;
    return Colors.red;
  }

  String _formatTimeRemaining() {
    if (_isExpired) return 'Expirado';
    
    if (_timeRemaining.inDays > 0) {
      return '${_timeRemaining.inDays}d ${_timeRemaining.inHours % 24}h';
    } else if (_timeRemaining.inHours > 0) {
      return '${_timeRemaining.inHours}h ${_timeRemaining.inMinutes % 60}min';
    } else if (_timeRemaining.inMinutes > 0) {
      return '${_timeRemaining.inMinutes}min';
    } else {
      return '${_timeRemaining.inSeconds}s';
    }
  }

  IconData _getTimerIcon() {
    if (_isExpired) return Icons.timer_off;
    if (widget.mission.isNearDeadline) return Icons.timer;
    return Icons.schedule;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getTimerColor();
    final textStyle = widget.textStyle ?? Theme.of(context).textTheme.bodySmall;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showIcon) ...[  // Corrigido: removido ponto extra
          Icon(
            _getTimerIcon(),
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
        ],
        Text(
          _formatTimeRemaining(),
          style: textStyle?.copyWith(
            color: color,
            fontWeight: _isExpired || widget.mission.isNearDeadline 
                ? FontWeight.bold 
                : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

/// Widget que exibe um cronômetro circular para missões
class CircularMissionTimer extends StatefulWidget {
  final DailyMissionModel mission;
  final double size;
  final VoidCallback? onExpired;
  
  const CircularMissionTimer({
    super.key,
    required this.mission,
    this.size = 60,
    this.onExpired,
  });

  @override
  State<CircularMissionTimer> createState() => _CircularMissionTimerState();
}

class _CircularMissionTimerState extends State<CircularMissionTimer> {
  Timer? _timer;
  double _progress = 0.0;
  Duration _timeRemaining = Duration.zero;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _updateProgress();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateProgress();
    });
  }

  void _updateProgress() {
    final now = DateTime.now();
    final totalDuration = widget.mission.deadline.difference(widget.mission.date);
    final remaining = widget.mission.deadline.difference(now);
    
    setState(() {
      if (remaining.isNegative) {
        _progress = 0.0;
        _timeRemaining = Duration.zero;
        if (!_isExpired) {
          _isExpired = true;
          widget.onExpired?.call();
        }
      } else {
        _progress = remaining.inMilliseconds / totalDuration.inMilliseconds;
        _timeRemaining = remaining;
        _isExpired = false;
      }
    });
  }

  Color _getProgressColor() {
    if (_isExpired) return Colors.red;
    if (_progress > 0.5) return Colors.green;
    if (_progress > 0.25) return Colors.orange;
    return Colors.red;
  }

  String _formatCenterText() {
    if (_isExpired) return 'EXP';
    
    if (_timeRemaining.inHours > 0) {
      return '${_timeRemaining.inHours}h';
    } else if (_timeRemaining.inMinutes > 0) {
      return '${_timeRemaining.inMinutes}m';
    } else {
      return '${_timeRemaining.inSeconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: _isExpired ? 0.0 : _progress,
            strokeWidth: 4,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatCenterText(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getProgressColor(),
                ),
              ),
              if (!_isExpired)
                Text(
                  'restam',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget que exibe uma barra de progresso linear para missões
class LinearMissionTimer extends StatefulWidget {
  final DailyMissionModel mission;
  final double height;
  final VoidCallback? onExpired;
  final bool showText;
  
  const LinearMissionTimer({
    super.key,
    required this.mission,
    this.height = 8,
    this.onExpired,
    this.showText = true,
  });

  @override
  State<LinearMissionTimer> createState() => _LinearMissionTimerState();
}

class _LinearMissionTimerState extends State<LinearMissionTimer> {
  Timer? _timer;
  double _progress = 0.0;
  Duration _timeRemaining = Duration.zero;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _updateProgress();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateProgress();
    });
  }

  void _updateProgress() {
    final now = DateTime.now();
    final totalDuration = widget.mission.deadline.difference(widget.mission.date);
    final remaining = widget.mission.deadline.difference(now);
    
    setState(() {
      if (remaining.isNegative) {
        _progress = 0.0;
        _timeRemaining = Duration.zero;
        if (!_isExpired) {
          _isExpired = true;
          widget.onExpired?.call();
        }
      } else {
        _progress = remaining.inMilliseconds / totalDuration.inMilliseconds;
        _timeRemaining = remaining;
        _isExpired = false;
      }
    });
  }

  Color _getProgressColor() {
    if (_isExpired) return Colors.red;
    if (_progress > 0.5) return Colors.green;
    if (_progress > 0.25) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showText)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tempo restante:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  _isExpired ? 'Expirado' : widget.mission.timeRemainingFormatted,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getProgressColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        LinearProgressIndicator(
          value: _isExpired ? 0.0 : _progress,
          minHeight: widget.height,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
        ),
      ],
    );
  }
}