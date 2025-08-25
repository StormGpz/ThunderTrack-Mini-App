import 'package:flutter/material.dart';
import '../theme/eva_theme.dart';

/// EVA 机甲风格装饰组件
class EvaMechDecoration {
  /// 创建机甲斜线背景装饰
  static Widget mechLinesBackground({
    double opacity = 0.1,
    bool animated = true,
  }) {
    return CustomPaint(
      painter: MechBackgroundPainter(
        opacity: opacity,
        animated: animated,
      ),
      child: Container(),
    );
  }

  /// 创建科技感边框装饰
  static BoxDecoration techBorder({
    Color? color,
    double glowIntensity = 0.5,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      border: Border.all(
        color: (color ?? EvaTheme.neonGreen).withOpacity(0.6),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: (color ?? EvaTheme.neonGreen).withOpacity(0.2 * glowIntensity),
          blurRadius: 10,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: (color ?? EvaTheme.neonGreen).withOpacity(0.1 * glowIntensity),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    );
  }

  /// 创建角落装饰元素
  static Widget cornerDecoration({
    double size = 30,
    Color? color,
    AlignmentGeometry alignment = Alignment.topLeft,
  }) {
    return Align(
      alignment: alignment,
      child: CustomPaint(
        size: Size(size, size),
        painter: CornerDecorationPainter(
          color: color ?? EvaTheme.neonGreen,
          alignment: alignment,
        ),
      ),
    );
  }

  /// 创建发光线条
  static Widget glowLine({
    double width = 100,
    double height = 2,
    Color? color,
    bool animated = true,
  }) {
    if (animated) {
      return AnimatedGlowLine(
        width: width,
        height: height,
        color: color ?? EvaTheme.neonGreen,
      );
    } else {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color ?? EvaTheme.neonGreen,
          boxShadow: [
            BoxShadow(
              color: (color ?? EvaTheme.neonGreen).withOpacity(0.6),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      );
    }
  }

  /// 创建机甲面板装饰
  static Widget mechPanel({
    required Widget child,
    EdgeInsetsGeometry? padding,
    double glowIntensity = 1.0,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EvaTheme.mechGray.withOpacity(0.8),
            EvaTheme.deepBlack.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EvaTheme.neonGreen.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: EvaTheme.neonGreen.withOpacity(0.1 * glowIntensity),
            blurRadius: 20,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: EvaTheme.primaryPurple.withOpacity(0.05 * glowIntensity),
            blurRadius: 30,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Stack(
        children: [
          // 背景装饰线条
          CustomPaint(
            painter: PanelDecorationPainter(opacity: 0.1),
            child: Container(),
          ),
          // 角落装饰
          cornerDecoration(size: 20, alignment: Alignment.topRight),
          cornerDecoration(size: 20, alignment: Alignment.bottomLeft),
          // 主要内容
          child,
        ],
      ),
    );
  }
}

/// 机甲背景绘制器
class MechBackgroundPainter extends CustomPainter {
  final double opacity;
  final bool animated;

  MechBackgroundPainter({
    required this.opacity,
    required this.animated,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = EvaTheme.neonGreen.withOpacity(opacity)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = EvaTheme.neonGreen.withOpacity(opacity * 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final path = Path();

    // 对角斜线网格
    final spacing = 50.0;
    
    // 左上到右下的斜线
    for (double x = -size.height; x < size.width + size.height; x += spacing) {
      path.moveTo(x, 0);
      path.lineTo(x + size.height, size.height);
    }
    
    // 右上到左下的斜线（更稀疏）
    for (double x = 0; x < size.width + size.height; x += spacing * 2) {
      path.moveTo(x, 0);
      path.lineTo(x - size.height, size.height);
    }

    // 水平装饰线
    path.moveTo(0, size.height * 0.2);
    path.lineTo(size.width * 0.3, size.height * 0.2);
    
    path.moveTo(size.width * 0.7, size.height * 0.8);
    path.lineTo(size.width, size.height * 0.8);

    // 绘制发光效果
    canvas.drawPath(path, glowPaint);
    // 绘制主线条
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => animated;
}

/// 角落装饰绘制器
class CornerDecorationPainter extends CustomPainter {
  final Color color;
  final AlignmentGeometry alignment;

  CornerDecorationPainter({
    required this.color,
    required this.alignment,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final path = Path();
    
    // 根据对齐方式绘制不同方向的L形装饰
    if (alignment == Alignment.topLeft) {
      // 左上角：从左下到左上到右上
      path.moveTo(0, size.height * 0.7);
      path.lineTo(0, 0);
      path.lineTo(size.width * 0.7, 0);
      
      // 内部装饰线
      path.moveTo(5, size.height * 0.5);
      path.lineTo(5, 5);
      path.lineTo(size.width * 0.5, 5);
    } else if (alignment == Alignment.bottomRight) {
      // 右下角：从右上到右下到左下
      path.moveTo(size.width, size.height * 0.3);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width * 0.3, size.height);
      
      // 内部装饰线
      path.moveTo(size.width - 5, size.height * 0.5);
      path.lineTo(size.width - 5, size.height - 5);
      path.lineTo(size.width * 0.5, size.height - 5);
    }

    // 绘制发光效果
    canvas.drawPath(path, glowPaint);
    // 绘制主线条
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 面板装饰绘制器
class PanelDecorationPainter extends CustomPainter {
  final double opacity;

  PanelDecorationPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = EvaTheme.neonGreen.withOpacity(opacity)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    // 中央装饰线
    path.moveTo(size.width * 0.1, size.height * 0.5);
    path.lineTo(size.width * 0.9, size.height * 0.5);
    
    // 对角装饰
    path.moveTo(size.width * 0.8, size.height * 0.2);
    path.lineTo(size.width * 0.9, size.height * 0.1);
    path.lineTo(size.width * 0.9, size.height * 0.3);
    
    path.moveTo(size.width * 0.2, size.height * 0.8);
    path.lineTo(size.width * 0.1, size.height * 0.9);
    path.lineTo(size.width * 0.1, size.height * 0.7);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 动画发光线条组件
class AnimatedGlowLine extends StatefulWidget {
  final double width;
  final double height;
  final Color color;

  const AnimatedGlowLine({
    Key? key,
    required this.width,
    required this.height,
    required this.color,
  }) : super(key: key);

  @override
  State<AnimatedGlowLine> createState() => _AnimatedGlowLineState();
}

class _AnimatedGlowLineState extends State<AnimatedGlowLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.6 * _glowAnimation.value),
                blurRadius: 6 * _glowAnimation.value,
                spreadRadius: 1 * _glowAnimation.value,
              ),
              BoxShadow(
                color: widget.color.withOpacity(0.3 * _glowAnimation.value),
                blurRadius: 12 * _glowAnimation.value,
                spreadRadius: 2 * _glowAnimation.value,
              ),
            ],
          ),
        );
      },
    );
  }
}