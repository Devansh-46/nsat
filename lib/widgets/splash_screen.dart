import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _crestCtrl;
  late final AnimationController _wordmarkCtrl;
  late final AnimationController _progressCtrl;
  late final AnimationController _exitCtrl;

  late final Animation<double> _crestScale;
  late final Animation<double> _crestOpacity;

  late final Animation<double> _wordmarkOpacity;
  late final Animation<Offset> _wordmarkSlide;

  late final Animation<double> _subLabelOpacity;

  late final Animation<double> _progress;

  late final Animation<double> _exitOpacity;

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _crestCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _crestScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(parent: _crestCtrl, curve: Curves.easeOutBack),
    );
    _crestOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _crestCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _wordmarkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _wordmarkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _wordmarkCtrl, curve: Curves.easeOut),
    );
    _wordmarkSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _wordmarkCtrl, curve: Curves.easeOutCubic),
    );
    _subLabelOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _wordmarkCtrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _progress = CurvedAnimation(
      parent: _progressCtrl,
      curve: Curves.easeInOutCubic,
    );

    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _exitOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await _crestCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 100));
    _wordmarkCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    await _progressCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 200));

    await _exitCtrl.forward();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    widget.onComplete();
  }

  @override
  void dispose() {
    _crestCtrl.dispose();
    _wordmarkCtrl.dispose();
    _progressCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _crestCtrl,
        _wordmarkCtrl,
        _progressCtrl,
        _exitCtrl,
      ]),
      builder: (context, _) {
        return Stack(
          children: [
            Container(
              color: AppColors.bgBase,
              child: CustomPaint(
                painter: _SplashMeshPainter(),
                size: Size.infinite,
              ),
            ),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: _crestScale.value,
                    child: Opacity(
                      opacity: _crestOpacity.value,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: AppColors.glassBgStrong,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: AppColors.glassBorder,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.forest
                                  .withValues(alpha: 0.18),
                              offset: const Offset(0, 12),
                              blurRadius: 32,
                            ),
                            const BoxShadow(
                              color: Color(0x1AFFFFFF),
                              offset: Offset(0, 1),
                              blurRadius: 0,
                              spreadRadius: -1,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Image.asset(
                          'assets/niu_crest.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  SlideTransition(
                    position: _wordmarkSlide,
                    child: Opacity(
                      opacity: _wordmarkOpacity.value,
                      child: Column(
                        children: [
                          Text(
                            'NSAT',
                            style: AppTheme.display(size: 42),
                          ),
                          const SizedBox(height: 4),
                          Opacity(
                            opacity: _subLabelOpacity.value,
                            child: Text(
                              'Student Aptitude Test',
                              style: AppTheme.body(
                                size: 13.5,
                                color: AppColors.ink4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Opacity(
                            opacity: _subLabelOpacity.value,
                            child: Text(
                              'Noida International University',
                              style: AppTheme.body(
                                size: 11.5,
                                color: AppColors.ink5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 52),

                  Opacity(
                    opacity: _wordmarkOpacity.value,
                    child: SizedBox(
                      width: 180,
                      child: Column(
                        children: [
                          Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppColors.bone,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _progress.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.forest2,
                                      AppColors.forest,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(99),
                                  boxShadow: [
                                    BoxShadow(
                                       color: AppColors.forest
                                           .withValues(alpha: 0.4),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _loadingLabel(_progress.value),
                            style: AppTheme.mono(
                              size: 11,
                              color: AppColors.ink4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_exitCtrl.value > 0)
              Opacity(
                opacity: _exitOpacity.value,
                child: Container(color: AppColors.bgBase),
              ),
          ],
        );
      },
    );
  }

  String _loadingLabel(double progress) {
    if (progress < 0.35) return 'Initialising...';
    if (progress < 0.65) return 'Loading config...';
    if (progress < 0.90) return 'Almost ready...';
    return 'Welcome';
  }
}

class _SplashMeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    void radial(Color color, Alignment center, double frac) {
      final c = Offset(
        size.width * (center.x * 0.5 + 0.5),
        size.height * (center.y * 0.5 + 0.5),
      );
      final radius = size.longestSide * frac;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0.0, 0.7],
        ).createShader(Rect.fromCircle(center: c, radius: radius));
      canvas.drawRect(Offset.zero & size, paint);
    }

    radial(AppColors.mesh1, const Alignment(-0.7, -0.76), 0.55);
    radial(AppColors.mesh2, const Alignment(0.76, -0.64), 0.50);
    radial(AppColors.mesh3, const Alignment(-0.56, 0.84), 0.60);
    radial(AppColors.mesh4, const Alignment(0.90, 0.56), 0.50);
  }

  @override
  bool shouldRepaint(_SplashMeshPainter old) => false;
}
