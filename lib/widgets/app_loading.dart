import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AppLoading extends StatefulWidget {
  final double size;

  const AppLoading({super.key, this.size = 60});

  @override
  State<AppLoading> createState() => _AppLoadingState();
}

class _AppLoadingState extends State<AppLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Opacity(
            opacity: _animation.value,
            child: Transform.scale(
              scale: 0.8 + (_animation.value * 0.2),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(0.1 * _animation.value),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.2 * _animation.value),
                      blurRadius: 20 * _animation.value,
                      spreadRadius: 5 * _animation.value,
                    ),
                  ],
                ),
                child: Icon(
                  LucideIcons.bookOpen, 
                  color: theme.colorScheme.primary, 
                  size: widget.size,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
