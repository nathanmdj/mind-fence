import 'package:flutter/material.dart';
import '../services/permission_service.dart';

/// Animated widget for celebrating successful permission grants
class PermissionSuccessAnimation extends StatefulWidget {
  final PermissionType permissionType;
  final VoidCallback? onComplete;
  final Duration duration;
  final double size;

  const PermissionSuccessAnimation({
    super.key,
    required this.permissionType,
    this.onComplete,
    this.duration = const Duration(milliseconds: 2000),
    this.size = 100,
  });

  @override
  State<PermissionSuccessAnimation> createState() => _PermissionSuccessAnimationState();
}

class _PermissionSuccessAnimationState extends State<PermissionSuccessAnimation>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _checkController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _checkController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _checkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeInOut,
    ));

    _startAnimation();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  Future<void> _startAnimation() async {
    // Start scale and fade animations simultaneously
    await Future.wait([
      _scaleController.forward(),
      _fadeController.forward(),
    ]);
    
    // Start check mark animation
    await _checkController.forward();
    
    // Wait for a moment to show the completed state
    await Future.delayed(Duration(milliseconds: 500));
    
    // Fade out
    await _fadeController.reverse();
    
    // Call completion callback
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: Listenable.merge([_scaleController, _fadeController, _checkController]),
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withOpacity(0.1),
                border: Border.all(
                  color: Colors.green,
                  width: 3,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background pulse effect
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    width: widget.size * 0.8,
                    height: widget.size * 0.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.withOpacity(0.2 * _scaleAnimation.value),
                    ),
                  ),
                  
                  // Permission icon
                  Icon(
                    _getPermissionIcon(),
                    size: widget.size * 0.3,
                    color: Colors.green,
                  ),
                  
                  // Animated check mark
                  Positioned(
                    bottom: widget.size * 0.15,
                    right: widget.size * 0.15,
                    child: Transform.scale(
                      scale: _checkAnimation.value,
                      child: Container(
                        width: widget.size * 0.25,
                        height: widget.size * 0.25,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                        ),
                        child: Icon(
                          Icons.check,
                          size: widget.size * 0.15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getPermissionIcon() {
    switch (widget.permissionType) {
      case PermissionType.notification:
        return Icons.notifications;
      case PermissionType.location:
        return Icons.location_on;
      case PermissionType.usageStats:
        return Icons.analytics;
      case PermissionType.accessibility:
        return Icons.accessibility;
      case PermissionType.deviceAdmin:
        return Icons.admin_panel_settings;
      case PermissionType.overlay:
        return Icons.layers;
      case PermissionType.vpn:
        return Icons.vpn_lock;
    }
  }
}

/// Celebration overlay for when all permissions are granted
class PermissionCompleteOverlay extends StatefulWidget {
  final VoidCallback? onComplete;
  final Duration duration;

  const PermissionCompleteOverlay({
    super.key,
    this.onComplete,
    this.duration = const Duration(milliseconds: 3000),
  });

  @override
  State<PermissionCompleteOverlay> createState() => _PermissionCompleteOverlayState();
}

class _PermissionCompleteOverlayState extends State<PermissionCompleteOverlay>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, 0.3, curve: Curves.easeInOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.1, 0.5, curve: Curves.elasticOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.2, 0.6, curve: Curves.easeOutBack),
    ));

    _startAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startAnimation() async {
    await _controller.forward();
    
    // Hold the animation for a moment
    await Future.delayed(Duration(milliseconds: 1000));
    
    // Fade out
    await _controller.reverse();
    
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: SlideTransition(
                position: _slideAnimation,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Card(
                    elevation: 8,
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Success icon with animation
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green.withOpacity(0.1),
                              border: Border.all(
                                color: Colors.green,
                                width: 3,
                              ),
                            ),
                            child: Icon(
                              Icons.check,
                              size: 40,
                              color: Colors.green,
                            ),
                          ),
                          
                          SizedBox(height: 24),
                          
                          // Success message
                          Text(
                            'All Permissions Granted!',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          SizedBox(height: 8),
                          
                          Text(
                            'Mind Fence is now ready to help you stay focused and productive!',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          SizedBox(height: 24),
                          
                          // Confetti or sparkle effect
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildSparkle(context, 0.0),
                              SizedBox(width: 8),
                              _buildSparkle(context, 0.2),
                              SizedBox(width: 8),
                              Text('🎉', style: TextStyle(fontSize: 24)),
                              SizedBox(width: 8),
                              _buildSparkle(context, 0.4),
                              SizedBox(width: 8),
                              _buildSparkle(context, 0.6),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSparkle(BuildContext context, double delay) {
    final sparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(delay, delay + 0.4, curve: Curves.easeInOut),
    ));

    return AnimatedBuilder(
      animation: sparkleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: sparkleAnimation.value,
          child: Transform.rotate(
            angle: sparkleAnimation.value * 6.28, // 2π for full rotation
            child: Icon(
              Icons.star,
              size: 16,
              color: Colors.amber.withOpacity(sparkleAnimation.value),
            ),
          ),
        );
      },
    );
  }
}

/// Simple feedback animation for individual permission grants
class PermissionGrantedFeedback extends StatefulWidget {
  final Widget child;
  final bool isGranted;
  final Duration duration;

  const PermissionGrantedFeedback({
    super.key,
    required this.child,
    required this.isGranted,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<PermissionGrantedFeedback> createState() => _PermissionGrantedFeedbackState();
}

class _PermissionGrantedFeedbackState extends State<PermissionGrantedFeedback>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.green.withOpacity(0.3),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PermissionGrantedFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (!oldWidget.isGranted && widget.isGranted) {
      _triggerSuccessAnimation();
    }
  }

  Future<void> _triggerSuccessAnimation() async {
    await _controller.forward();
    await _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: _colorAnimation.value,
              borderRadius: BorderRadius.circular(8),
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Utility function to show permission success overlay
void showPermissionSuccessOverlay(BuildContext context, {VoidCallback? onComplete}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    builder: (context) => PermissionCompleteOverlay(
      onComplete: () {
        Navigator.of(context).pop();
        onComplete?.call();
      },
    ),
  );
}