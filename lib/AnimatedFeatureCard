import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnimatedFeatureCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const AnimatedFeatureCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  State<AnimatedFeatureCard> createState() => _AnimatedFeatureCardState();
}

class _AnimatedFeatureCardState extends State<AnimatedFeatureCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Helper method to get an appropriate text color
  Color _getTextColor(Color baseColor) {
    if (baseColor == Colors.orange) return Colors.orange[800] ?? Colors.orange;
    if (baseColor == Colors.pink) return Colors.pink[800] ?? Colors.pink;
    if (baseColor == Colors.blue) return Colors.blue[800] ?? Colors.blue;
    if (baseColor == Colors.purple) return Colors.purple[800] ?? Colors.purple;
    if (baseColor == Colors.teal) return Colors.teal[800] ?? Colors.teal;
    if (baseColor == Colors.green) return Colors.green[800] ?? Colors.green;
    if (baseColor == Colors.indigo) return Colors.indigo[800] ?? Colors.indigo;
    if (baseColor == Colors.red) return Colors.red[800] ?? Colors.red;
    return Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
        _controller.reverse().then((_) {
          widget.onTap();
        });
        HapticFeedback.lightImpact();
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withAlpha(_isPressed ? 30 : 51),
                    blurRadius: _isPressed ? 5 : 8,
                    offset: _isPressed 
                      ? const Offset(0, 2)
                      : const Offset(0, 4),
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.color.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, size: 36, color: widget.color),
            ),
            const SizedBox(height: 12),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _getTextColor(widget.color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}