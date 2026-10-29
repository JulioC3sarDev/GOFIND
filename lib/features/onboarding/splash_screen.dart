import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../onboarding/welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  
  // Controlador de entrada com tempo ideal para suavidade (2.2 segundos)
  late final AnimationController _entranceCtrl;
  
  // Controlador da respiração contínua
  late final AnimationController _breathingCtrl;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _blurAnim;
  late final Animation<Offset> _textOffset;
  late final Animation<double> _textOpacity;
  late final Animation<double> _subtitleOpacity;

  late final Animation<Offset> _floatAnim;
  late final Animation<Alignment> _gradientTop;
  late final Animation<Alignment> _gradientBottom;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _breathingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);

    // O blur desaparece de forma bem suave e orgânica
    _blurAnim = Tween<double>(begin: 16.0, end: 0.0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.0, 0.45, curve: Curves.easeOut)),
    );

    // Entrada da logo muito elegante (sem "dar tranco")
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic)),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.0, 0.35, curve: Curves.easeOut)),
    );

    _textOffset = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.3, 0.75, curve: Curves.easeOutCubic)),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.3, 0.65, curve: Curves.easeOut)),
    );

    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.5, 0.9, curve: Curves.easeOut)),
    );

    // Flutuação contínua e sutil
    _floatAnim = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.02)).animate(
      CurvedAnimation(parent: _breathingCtrl, curve: Curves.easeInOutSine),
    );

    _gradientTop = AlignmentTween(begin: Alignment.topLeft, end: Alignment.topRight).animate(_breathingCtrl);
    _gradientBottom = AlignmentTween(begin: Alignment.bottomRight, end: Alignment.bottomLeft).animate(_breathingCtrl);

    _entranceCtrl.forward();

    // Feedback tátil delicado sincronizado com o surgimento da logo
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) HapticFeedback.lightImpact();
    });

    // Saída fluida e elegante para a tela de boas-vindas (aos 2.4 segundos)
    Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => const WelcomeScreen(),
          transitionsBuilder: (_, anim, __, child) {
            final scale = Tween<double>(begin: 0.98, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(anim),
              child: ScaleTransition(
                scale: scale,
                child: child,
              ),
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _breathingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: AnimatedBuilder(
          animation: Listenable.merge([_entranceCtrl, _breathingCtrl]),
          builder: (context, child) {
            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: _gradientTop.value,
                  end: _gradientBottom.value,
                  colors: const [
                    Color(0xFF2E7BFF),
                    Color(0xFF005CE6),
                    Color(0xFF0044B3),
                  ],
                ),
              ),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: _blurAnim.value,
                  sigmaY: _blurAnim.value,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SlideTransition(
                        position: _floatAnim,
                        child: FadeTransition(
                          opacity: _logoOpacity,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: Container(
                              decoration: const BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x25000000),
                                    blurRadius: 30,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                "assets/icons/icon.png",
                                width: 135,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      FadeTransition(
                        opacity: _textOpacity,
                        child: SlideTransition(
                          position: _textOffset,
                          child: Column(
                            children: [
                              Text(
                                "GoFind",
                                style: GoogleFonts.comfortaa(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.8, 
                                  shadows: const [
                                    BoxShadow(
                                      color: Color(0x1A000000),
                                      blurRadius: 15,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              FadeTransition(
                                opacity: _subtitleOpacity,
                                child: Text(
                                  "Encontre os seus amigos\nmesmo sem internet.",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.comfortaa(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.88),
                                    height: 1.45,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}