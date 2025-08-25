import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/eva_theme.dart';

/// 炫酷的 EVA 风格悬浮底部导航栏
class EvaFloatingBottomBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<EvaTabItem> items;

  const EvaFloatingBottomBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : super(key: key);

  @override
  State<EvaFloatingBottomBar> createState() => _EvaFloatingBottomBarState();
}

class _EvaFloatingBottomBarState extends State<EvaFloatingBottomBar>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _glowController;
  late Animation<double> _slideAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    // 滑动动画控制器
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // 发光动画控制器
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _slideController.forward();
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_slideAnimation, _glowAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _slideAnimation.value)),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Stack(
              children: [
                // 发光边框 - 放在最底层
                _buildGlowBorder(),
                
                // 机甲斜线背景装饰
                _buildMechBackground(),
                
                // 主要的磨砂容器 - 确保点击事件能正确传递
                ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      height: 60, // 减少高度，更扁平
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            EvaTheme.deepBlack.withOpacity(0.8),
                            EvaTheme.mechGray.withOpacity(0.7),
                            EvaTheme.primaryPurple.withOpacity(0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: EvaTheme.neonGreen.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: widget.items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final isSelected = index == widget.currentIndex;
                          
                          return _buildTabItem(item, index, isSelected);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建机甲斜线背景
  Widget _buildMechBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: MechLinePainter(
          glowIntensity: _glowAnimation.value,
        ),
      ),
    );
  }

  /// 构建发光边框
  Widget _buildGlowBorder() {
    return IgnorePointer(  // 确保发光边框不阻挡点击事件
      child: Container(
        height: 60, // 匹配底边栏高度
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: EvaTheme.neonGreen.withOpacity(0.3 * _glowAnimation.value),
              blurRadius: 20,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: EvaTheme.primaryPurple.withOpacity(0.2 * _glowAnimation.value),
              blurRadius: 30,
              spreadRadius: -5,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建单个 Tab 项
  Widget _buildTabItem(EvaTabItem item, int index, bool isSelected) {
    return GestureDetector(
      onTap: () => widget.onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), // 减少内边距
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected 
            ? EvaTheme.neonGreen.withOpacity(0.2)
            : Colors.transparent,
          border: isSelected 
            ? Border.all(color: EvaTheme.neonGreen.withOpacity(0.5), width: 1)
            : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图标
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                item.icon,
                color: isSelected ? EvaTheme.neonGreen : EvaTheme.textGray,
                size: isSelected ? 22 : 20, // 减小图标尺寸
              ),
            ),
            const SizedBox(height: 4),
            
            // 标签文字
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected ? EvaTheme.neonGreen : EvaTheme.textGray,
                fontSize: isSelected ? 10 : 9, // 减小文字尺寸
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                letterSpacing: 0.5,
              ),
              child: Text(item.label),
            ),
            
            // 选中指示器
            if (isSelected)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(top: 2),
                height: 2,
                width: 20,
                decoration: BoxDecoration(
                  color: EvaTheme.neonGreen,
                  borderRadius: BorderRadius.circular(1),
                  boxShadow: [
                    BoxShadow(
                      color: EvaTheme.neonGreen.withOpacity(0.6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tab 项目数据类
class EvaTabItem {
  final IconData icon;
  final String label;
  
  const EvaTabItem({
    required this.icon,
    required this.label,
  });
}

/// 机甲斜线绘制器
class MechLinePainter extends CustomPainter {
  final double glowIntensity;
  
  MechLinePainter({required this.glowIntensity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = EvaTheme.neonGreen.withOpacity(0.1 * glowIntensity)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = EvaTheme.neonGreen.withOpacity(0.05 * glowIntensity)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    // 绘制机甲风格的斜线
    final path = Path();
    
    // 左上角斜线
    path.moveTo(10, 10);
    path.lineTo(40, 10);
    path.lineTo(50, 20);
    
    // 右上角斜线
    path.moveTo(size.width - 50, 20);
    path.lineTo(size.width - 40, 10);
    path.lineTo(size.width - 10, 10);
    
    // 左下角斜线  
    path.moveTo(10, size.height - 10);
    path.lineTo(40, size.height - 10);
    path.lineTo(50, size.height - 20);
    
    // 右下角斜线
    path.moveTo(size.width - 50, size.height - 20);
    path.lineTo(size.width - 40, size.height - 10);
    path.lineTo(size.width - 10, size.height - 10);

    // 中央装饰线
    path.moveTo(size.width * 0.3, 5);
    path.lineTo(size.width * 0.7, 5);
    
    path.moveTo(size.width * 0.3, size.height - 5);
    path.lineTo(size.width * 0.7, size.height - 5);

    // 绘制发光效果
    canvas.drawPath(path, glowPaint);
    // 绘制主线条
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}