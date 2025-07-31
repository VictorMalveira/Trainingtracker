import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../models/skill_model.dart';

class AnimatedSkillsRadar extends StatefulWidget {
  final List<SkillModel> skills;

  const AnimatedSkillsRadar({super.key, required this.skills});

  @override
  State<AnimatedSkillsRadar> createState() => _AnimatedSkillsRadarState();
}

class _AnimatedSkillsRadarState extends State<AnimatedSkillsRadar> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _updateAnimationController;
  late Animation<double> _animation;
  late Animation<double> _updateAnimation;
  List<SkillModel> _previousSkills = [];
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _updateAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    
    _updateAnimation = CurvedAnimation(
      parent: _updateAnimationController,
      curve: Curves.easeInOut,
    );
    
    _previousSkills = List.from(widget.skills);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _updateAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AnimatedSkillsRadar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Verifica se houve mudança real nos pontos das habilidades
    bool hasChanged = false;
    if (oldWidget.skills.length != widget.skills.length) {
      hasChanged = true;
    } else {
      for (int i = 0; i < widget.skills.length; i++) {
        if (oldWidget.skills[i].pointsInvested != widget.skills[i].pointsInvested) {
          hasChanged = true;
          break;
        }
      }
    }
    
    if (hasChanged && !_isUpdating) {
      _isUpdating = true;
      _previousSkills = List.from(oldWidget.skills);
      
      // Animação suave de atualização
      _updateAnimationController.reset();
      _updateAnimationController.forward().then((_) {
        if (mounted) {
          setState(() {
            _isUpdating = false;
            _previousSkills = List.from(widget.skills);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_animation, _updateAnimation]),
      builder: (context, child) {
        // Interpolar entre habilidades antigas e novas durante atualização
        List<SkillModel> displaySkills = widget.skills;
        if (_isUpdating && _previousSkills.isNotEmpty) {
          displaySkills = _interpolateSkills(_previousSkills, widget.skills, _updateAnimation.value);
        }
        
        return Container(
          width: 320,
          height: 320,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CustomPaint(
            size: const Size(320, 320),
            painter: SkillsRadarPainter(
              skills: displaySkills,
              animationValue: _animation.value,
              updateAnimationValue: _isUpdating ? _updateAnimation.value : 1.0,
              isUpdating: _isUpdating,
            ),
          ),
        );
      },
    );
  }
  
  List<SkillModel> _interpolateSkills(List<SkillModel> from, List<SkillModel> to, double t) {
    if (from.length != to.length) return to;
    
    List<SkillModel> interpolated = [];
    for (int i = 0; i < from.length; i++) {
      final fromPoints = from[i].pointsInvested;
      final toPoints = to[i].pointsInvested;
      final interpolatedPoints = (fromPoints + (toPoints - fromPoints) * t).round();
      
      interpolated.add(SkillModel(
        id: to[i].id,
        userId: to[i].userId,
        name: to[i].name,
        pointsInvested: interpolatedPoints,
        maxPoints: to[i].maxPoints,
      ));
    }
    return interpolated;
  }
}

class SkillsRadarPainter extends CustomPainter {
  final List<SkillModel> skills;
  final double animationValue;
  final double updateAnimationValue;
  final bool isUpdating;

  SkillsRadarPainter({
    required this.skills,
    required this.animationValue,
    required this.updateAnimationValue,
    required this.isUpdating,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.85;

    // Desenha os círculos de fundo
    _drawBackgroundCircles(canvas, center, radius);

    // Desenha as linhas de divisão
    _drawDivisionLines(canvas, center, radius);

    // Desenha o polígono das habilidades
    _drawSkillsPolygon(canvas, center, radius);

    // Desenha os pontos e rótulos das habilidades
    _drawSkillPointsAndLabels(canvas, center, radius, size);
  }

  void _drawBackgroundCircles(Canvas canvas, Offset center, double radius) {
    // Círculos de fundo com gradiente sutil
    for (int i = 1; i <= 5; i++) {
      final circleRadius = radius * i / 5;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.grey.withOpacity(0.2 + (i * 0.05))
        ..strokeWidth = i == 5 ? 2.0 : 1.0;
      
      canvas.drawCircle(center, circleRadius, paint);
      
      // Adiciona números nos círculos externos
      if (i == 5) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${i * 2}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            center.dx + circleRadius + 5,
            center.dy - textPainter.height / 2,
          ),
        );
      }
    }
  }

  void _drawDivisionLines(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1.0;

    final skillCount = skills.length;
    final angleStep = 2 * math.pi / skillCount;

    for (int i = 0; i < skillCount; i++) {
      final angle = -math.pi / 2 + i * angleStep;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), paint);
    }
  }

  void _drawSkillsPolygon(Canvas canvas, Offset center, double radius) {
    if (skills.isEmpty) return;

    final skillCount = skills.length;
    final angleStep = 2 * math.pi / skillCount;
    final path = Path();
    
    // Gradiente para o preenchimento
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          Colors.blue.withOpacity(0.4),
          Colors.blue.withOpacity(0.1),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    
    // Contorno com efeito de brilho durante atualização
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = isUpdating 
        ? Colors.green.withOpacity(0.8 + 0.2 * math.sin(updateAnimationValue * math.pi * 4))
        : Colors.blue
      ..strokeWidth = isUpdating ? 3.0 : 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Encontra o valor máximo possível para normalização
    final maxPossibleValue = 10.0;

    List<Offset> points = [];
    for (int i = 0; i < skillCount; i++) {
      final skill = skills[i];
      final normalizedValue = skill.pointsInvested / maxPossibleValue;
      final scaledValue = normalizedValue * animationValue;
      final angle = -math.pi / 2 + i * angleStep;
      final x = center.dx + radius * scaledValue * math.cos(angle);
      final y = center.dy + radius * scaledValue * math.sin(angle);
      
      points.add(Offset(x, y));
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
    
    // Desenha pontos individuais com efeito de pulso durante atualização
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final pointPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = isUpdating 
          ? Colors.green.withOpacity(0.9)
          : Colors.blue;
      
      final pointRadius = isUpdating 
        ? 5.0 + 2.0 * math.sin(updateAnimationValue * math.pi * 6 + i)
        : 4.0;
      
      canvas.drawCircle(point, pointRadius, pointPaint);
      
      // Halo ao redor dos pontos durante atualização
      if (isUpdating) {
        final haloPaint = Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.green.withOpacity(0.3)
          ..strokeWidth = 2.0;
        canvas.drawCircle(point, pointRadius + 3, haloPaint);
      }
    }
  }

  void _drawSkillPointsAndLabels(Canvas canvas, Offset center, double radius, Size size) {
    final skillCount = skills.length;
    final angleStep = 2 * math.pi / skillCount;

    final maxPossibleValue = 10.0;
    final textStyle = TextStyle(
      color: Colors.black87,
      fontSize: size.width * 0.03,
      fontWeight: FontWeight.bold,
    );

    for (int i = 0; i < skillCount; i++) {
      final skill = skills[i];
      final angle = -math.pi / 2 + i * angleStep;

      // Posiciona o rótulo um pouco além do ponto máximo
      final labelRadius = radius * 1.15;
      final labelX = center.dx + labelRadius * math.cos(angle);
      final labelY = center.dy + labelRadius * math.sin(angle);

      // Cria o texto do nome da habilidade
      final nameSpan = TextSpan(
        text: skill.name,
        style: textStyle,
      );
      final namePainter = TextPainter(
        text: nameSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      namePainter.layout();

      // Ajusta a posição do texto para centralizar
      final nameOffset = Offset(
        labelX - namePainter.width / 2,
        labelY - namePainter.height / 2 - 8,
      );
      namePainter.paint(canvas, nameOffset);

      // Desenha o valor da habilidade (pontos atuais)
      final valueText = '${skill.pointsInvested.toInt()}';
      final valueTextSpan = TextSpan(
        text: valueText,
        style: textStyle.copyWith(
          color: isUpdating ? Colors.green : Colors.blue,
          fontSize: size.width * 0.025,
          fontWeight: FontWeight.w600,
        ),
      );
      final valueTextPainter = TextPainter(
        text: valueTextSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      valueTextPainter.layout();
      
      final valueOffset = Offset(
        labelX - valueTextPainter.width / 2,
        labelY - valueTextPainter.height / 2 + 8,
      );
      valueTextPainter.paint(canvas, valueOffset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! SkillsRadarPainter ||
        oldDelegate.skills != skills ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.updateAnimationValue != updateAnimationValue ||
        oldDelegate.isUpdating != isUpdating;
  }
}