import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

/// A custom loading widget that shows alternating logos in a carousel animation.
/// Used for showing branded loading states.
class LogoCarouselLoading extends StatefulWidget {
  /// Size of the logo container
  final double size;
  
  /// Duration for each logo to be shown
  final Duration animationDuration;
  
  /// Background color of the loading overlay
  final Color backgroundColor;

  const LogoCarouselLoading({
    Key? key,
    this.size = 80,
    this.animationDuration = const Duration(milliseconds: 800),
    this.backgroundColor = const Color(0xFF1565C0),
  }) : super(key: key);

  @override
  State<LogoCarouselLoading> createState() => _LogoCarouselLoadingState();
}

class _LogoCarouselLoadingState extends State<LogoCarouselLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showFirstLogo = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showFirstLogo = !_showFirstLogo;
        });
        _controller.forward(from: 0);
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation,
            child: child,
          ),
        );
      },
      child: _showFirstLogo
          ? Container(
              key: const ValueKey('techcare'),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/logos/logo.png',
                  width: widget.size - 4,
                  height: widget.size - 4,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: widget.size - 4,
                      height: widget.size - 4,
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.local_hospital,
                        color: const Color(0xFF1565C0),
                        size: widget.size * 0.5,
                      ),
                    );
                  },
                ),
              ),
            )
          : Container(
              key: const ValueKey('pch'),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/logos/pchlogo.png',
                  width: widget.size - 4,
                  height: widget.size - 4,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: widget.size - 4,
                      height: widget.size - 4,
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.account_balance,
                        color: Colors.green[700],
                        size: widget.size * 0.5,
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }
}

/// A full-screen loading overlay with the logo carousel animation
class LogoCarouselLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final String? message;
  final bool showProgressRing;
  final bool animateDots;
  final double? progress; // 0.0 to 1.0

  const LogoCarouselLoadingOverlay({
    Key? key,
    required this.isLoading,
    this.message,
    this.showProgressRing = true,
    this.animateDots = true,
    this.progress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Enhanced logo with shimmer ring and pulse
              _EnhancedLogoWithEffects(
                progress: progress,
              ),
              if (message != null || progress != null) ...[
                const SizedBox(height: 24),
                // Progress percentage
                if (progress != null)
                  Text(
                    '${((progress ?? 0) * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                if (message != null) ...[
                  const SizedBox(height: 8),
                  animateDots
                      ? _AnimatedMessage(message: message!)
                      : Text(
                          message!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Enhanced logo with shimmer ring + pulse effect + logo carousel
class _EnhancedLogoWithEffects extends StatefulWidget {
  final double? progress;

  const _EnhancedLogoWithEffects({this.progress});

  @override
  State<_EnhancedLogoWithEffects> createState() => _EnhancedLogoWithEffectsState();
}

class _EnhancedLogoWithEffectsState extends State<_EnhancedLogoWithEffects>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _logoSwitchController;
  bool _showFirstLogo = true;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _logoSwitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    if (widget.progress == null) {
      _rotationController.repeat();
    }
    _pulseController.repeat(reverse: true);

    _logoSwitchController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showFirstLogo = !_showFirstLogo;
        });
        _logoSwitchController.forward(from: 0);
      }
    });
    _logoSwitchController.forward();
  }

  @override
  void didUpdateWidget(_EnhancedLogoWithEffects oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != null) {
      _rotationController.stop();
    } else if (!_rotationController.isAnimating) {
      _rotationController.repeat();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _logoSwitchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasProgress = widget.progress != null;
    final progressValue = widget.progress ?? 0.0;

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer shimmer ring
          RotationTransition(
            turns: _rotationController,
            child: CustomPaint(
              size: const Size(120, 120),
              painter: _ShimmerRingPainter(),
            ),
          ),
          // Progress or background ring
          if (hasProgress)
            CustomPaint(
              size: const Size(110, 110),
              painter: _ProgressRingPainter(
                progress: progressValue,
                color: Colors.white,
              ),
            )
          else
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          // Glow
          Container(
            width: 100,
            height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          // Pulsing logo
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + (_pulseController.value * 0.08);
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                );
              },
              child: _showFirstLogo
                  ? _LogoImage(
                      key: const ValueKey('techcare'),
                      asset: 'assets/logos/logo.png',
                      fallbackIcon: Icons.local_hospital,
                      fallbackColor: const Color(0xFF1565C0),
                    )
                  : _LogoImage(
                      key: const ValueKey('pch'),
                      asset: 'assets/logos/pchlogo.png',
                      fallbackIcon: Icons.account_balance,
                      fallbackColor: Colors.green[700]!,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoImage extends StatelessWidget {
  final String asset;
  final IconData fallbackIcon;
  final Color fallbackColor;

  const _LogoImage({
    required Key key,
    required this.asset,
    required this.fallbackIcon,
    required this.fallbackColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          asset,
          width: 66,
          height: 66,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 66,
              height: 66,
              color: Colors.grey[200],
              child: Icon(
                fallbackIcon,
                color: fallbackColor,
                size: 35,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Shimmer ring painter for rotating glow effect
class _ShimmerRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    final gradient = SweepGradient(
      colors: [
        Colors.transparent,
        Colors.white.withOpacity(0.8),
        Colors.white.withOpacity(0.4),
        Colors.transparent,
      ],
      stops: const [0.0, 0.3, 0.6, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Progress ring painter
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ProgressRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const strokeWidth = 4.0;

    final bgPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = progress * 2 * pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Rotating gradient progress ring around the logo
class _LogoWithProgressRing extends StatefulWidget {
  final Widget child;
  final double? progress; // 0.0 to 1.0, null for indeterminate

  const _LogoWithProgressRing({required this.child, this.progress});

  @override
  State<_LogoWithProgressRing> createState() => _LogoWithProgressRingState();
}

class _LogoWithProgressRingState extends State<_LogoWithProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.progress == null) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(_LogoWithProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != null) {
      _rotationController.stop();
    } else if (!_rotationController.isAnimating) {
      _rotationController.repeat();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasProgress = widget.progress != null;
    final progressValue = widget.progress ?? 0.0;

    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          // Progress ring (determinate) or rotating ring (indeterminate)
          hasProgress
              ? CustomPaint(
                  size: const Size(100, 100),
                  painter: _ProgressRingPainter(
                    progress: progressValue,
                    color: Colors.white,
                  ),
                )
              : RotationTransition(
                  turns: _rotationController,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.8),
                          Colors.white.withOpacity(0.0),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
          // Glow effect
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          // The logo
          widget.child,
        ],
      ),
    );
  }
}

/// Message with animated dots
class _AnimatedMessage extends StatefulWidget {
  final String message;

  const _AnimatedMessage({required this.message});

  @override
  State<_AnimatedMessage> createState() => _AnimatedMessageState();
}

class _AnimatedMessageState extends State<_AnimatedMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotsController;
  int _dotCount = 0;

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _dotsController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _dotCount = (_dotCount + 1) % 4;
        });
        _dotsController.forward(from: 0);
      }
    });
    _dotsController.forward();
  }

  @override
  void dispose() {
    _dotsController.dispose();
    super.dispose();
  }

  String get _dots => '.' * _dotCount;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${widget.message}$_dots',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
