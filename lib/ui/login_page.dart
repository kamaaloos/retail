import 'dart:math' show cos, pi, sin;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../providers/retail_store.dart';
import 'theme.dart';
import 'widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const _gold = Color(0xFFF1BE15);
  static const _goldDeep = Color(0xFFD4A012);

  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController(text: 'admin');
  final _pinCtrl = TextEditingController();
  bool _obscurePin = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final store = context.read<RetailStore>();
    final t = AppStrings.of(store.language);
    final ok = await store.login(
      username: _usernameCtrl.text.trim(),
      pin: _pinCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (!ok) _error = t.invalidCredentials;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    final t = AppStrings.of(store.language);

    if (store.loading) {
      return Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            _LoginBackdrop(gold: _gold),
            Center(child: CircularProgressIndicator(color: _gold)),
          ],
        ),
      );
    }

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 960;
          return Stack(
            fit: StackFit.expand,
            children: [
              _LoginBackdrop(gold: _gold),
              if (wide)
                Row(
                  children: [
                    Expanded(child: _BrandPanel(store: store, strings: t, gold: _gold)),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: _LoginCard(
                            formKey: _formKey,
                            store: store,
                            strings: t,
                            gold: _gold,
                            goldDeep: _goldDeep,
                            usernameCtrl: _usernameCtrl,
                            pinCtrl: _pinCtrl,
                            obscurePin: _obscurePin,
                            submitting: _submitting,
                            error: _error,
                            onTogglePin: () => setState(() => _obscurePin = !_obscurePin),
                            onSubmit: _submit,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _BrandHeader(store: store, strings: t, gold: _gold, compact: true),
                          const SizedBox(height: 24),
                          _LoginCard(
                            formKey: _formKey,
                            store: store,
                            strings: t,
                            gold: _gold,
                            goldDeep: _goldDeep,
                            usernameCtrl: _usernameCtrl,
                            pinCtrl: _pinCtrl,
                            obscurePin: _obscurePin,
                            submitting: _submitting,
                            error: _error,
                            onTogglePin: () => setState(() => _obscurePin = !_obscurePin),
                            onSubmit: _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LoginBackdrop extends StatefulWidget {
  final Color gold;

  const _LoginBackdrop({required this.gold});

  @override
  State<_LoginBackdrop> createState() => _LoginBackdropState();
}

class _LoginBackdropState extends State<_LoginBackdrop> with TickerProviderStateMixin {
  late final AnimationController _drift;
  late final AnimationController _pulse;
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(vsync: this, duration: const Duration(seconds: 28))..repeat();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat(reverse: true);
    _shimmer = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    _pulse.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return AnimatedBuilder(
      animation: Listenable.merge([_drift, _pulse, _shimmer]),
      builder: (context, _) {
        final drift = _drift.value;
        final pulse = _pulse.value;
        final shimmer = _shimmer.value;
        final wave = sin(drift * pi * 2);
        final wave2 = cos(drift * pi * 2);

        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-0.8 + wave * 0.15, -1),
                  end: Alignment(0.9 - wave2 * 0.12, 1),
                  colors: [
                    Color.lerp(const Color(0xFF050910), const Color(0xFF101827), pulse)!,
                    const Color(0xFF0B1220),
                    Color.lerp(const Color(0xFF111827), widget.gold, 0.05 + pulse * 0.07)!,
                  ],
                ),
              ),
            ),
            Positioned(
              top: -140 + wave * 55,
              right: -90 + wave2 * 45,
              child: _GlowOrb(
                color: widget.gold.withValues(alpha: 0.16 + pulse * 0.1),
                size: 340 + pulse * 50,
              ),
            ),
            Positioned(
              bottom: -120 + wave2 * 40,
              left: -70 + wave * 35,
              child: _GlowOrb(
                color: AppColors.accent.withValues(alpha: 0.12 + pulse * 0.08),
                size: 300 + pulse * 36,
              ),
            ),
            Positioned(
              top: screen.height * (0.28 + wave2 * 0.04),
              left: screen.width * (0.12 + wave * 0.03),
              child: _GlowOrb(
                color: widget.gold.withValues(alpha: 0.06 + pulse * 0.05),
                size: 200 + pulse * 24,
              ),
            ),
            Positioned(
              top: screen.height * (0.62 + wave * 0.03),
              right: screen.width * (0.18 - wave2 * 0.02),
              child: _GlowOrb(
                color: Colors.white.withValues(alpha: 0.03 + pulse * 0.02),
                size: 140,
              ),
            ),
            CustomPaint(
              painter: _CinematicBeamPainter(progress: shimmer, gold: widget.gold),
              size: Size.infinite,
            ),
            CustomPaint(
              painter: _StarfieldPainter(progress: drift, gold: widget.gold),
              size: Size.infinite,
            ),
            CustomPaint(
              painter: _GridPainter(
                color: Colors.white.withValues(alpha: 0.025),
                offset: Offset(wave * 12, wave2 * 12),
              ),
              size: Size.infinite,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.15),
                  radius: 1.15,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.18 + pulse * 0.06),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  final Offset offset;

  _GridPainter({required this.color, this.offset = Offset.zero});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const step = 48.0;
    for (var x = -step; x < size.width + step; x += step) {
      canvas.drawLine(Offset(x + offset.dx, 0), Offset(x + offset.dx, size.height), paint);
    }
    for (var y = -step; y < size.height + step; y += step) {
      canvas.drawLine(Offset(0, y + offset.dy), Offset(size.width, y + offset.dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.offset != offset;
}

class _CinematicBeamPainter extends CustomPainter {
  final double progress;
  final Color gold;

  _CinematicBeamPainter({required this.progress, required this.gold});

  @override
  void paint(Canvas canvas, Size size) {
    final angle = -0.55 + progress * 0.35;
    final center = Offset(size.width * (0.2 + progress * 0.6), size.height * 0.5);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final rect = Rect.fromCenter(center: Offset.zero, width: size.width * 1.4, height: 90);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          gold.withValues(alpha: 0.0),
          gold.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.05),
          gold.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0, 0.25, 0.42, 0.5, 0.58, 1],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
    canvas.restore();

    final angle2 = 0.75 - progress * 0.25;
    final center2 = Offset(size.width * (0.85 - progress * 0.55), size.height * 0.35);
    canvas.save();
    canvas.translate(center2.dx, center2.dy);
    canvas.rotate(angle2);
    final rect2 = Rect.fromCenter(center: Offset.zero, width: size.width, height: 60);
    final paint2 = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppColors.accent.withValues(alpha: 0.06),
          AppColors.accent.withValues(alpha: 0.03),
          Colors.transparent,
        ],
      ).createShader(rect2);
    canvas.drawRect(rect2, paint2);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CinematicBeamPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.gold != gold;
}

class _StarfieldPainter extends CustomPainter {
  final double progress;
  final Color gold;

  _StarfieldPainter({required this.progress, required this.gold});

  static const _points = <(double, double, double)>[
    (0.08, 0.12, 1.2),
    (0.18, 0.28, 0.9),
    (0.32, 0.08, 1.0),
    (0.46, 0.22, 0.8),
    (0.58, 0.14, 1.1),
    (0.72, 0.32, 0.7),
    (0.84, 0.18, 1.0),
    (0.12, 0.52, 0.8),
    (0.24, 0.68, 1.1),
    (0.38, 0.58, 0.9),
    (0.52, 0.72, 0.7),
    (0.66, 0.62, 1.0),
    (0.78, 0.78, 0.8),
    (0.9, 0.56, 0.9),
    (0.16, 0.86, 0.7),
    (0.44, 0.88, 1.0),
    (0.7, 0.9, 0.8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final (nx, ny, speed) in _points) {
      final twinkle = (sin((progress * speed + nx) * pi * 2) + 1) / 2;
      final driftY = sin((progress + nx) * pi * 2) * 6;
      final point = Offset(nx * size.width, ny * size.height + driftY);
      final useGold = nx > 0.55;
      final color = (useGold ? gold : Colors.white).withValues(alpha: 0.08 + twinkle * 0.22);
      canvas.drawCircle(point, 1.1 + twinkle * 0.8, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) => oldDelegate.progress != progress;
}

class _BrandPanel extends StatelessWidget {
  final RetailStore store;
  final AppStrings strings;
  final Color gold;

  const _BrandPanel({required this.store, required this.strings, required this.gold});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _BrandHeader(store: store, strings: strings, gold: gold, compact: false),
          const SizedBox(height: 40),
          _FeatureRow(icon: Icons.offline_bolt_rounded, label: strings.posTitle, gold: gold),
          const SizedBox(height: 14),
          _FeatureRow(icon: Icons.lock_outline_rounded, label: strings.pinHint, gold: gold),
          const SizedBox(height: 14),
          _FeatureRow(icon: Icons.insights_rounded, label: strings.reports, gold: gold),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final RetailStore store;
  final AppStrings strings;
  final Color gold;
  final bool compact;

  const _BrandHeader({
    required this.store,
    required this.strings,
    required this.gold,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final logoSize = compact ? 88.0 : 112.0;
    return Column(
      crossAxisAlignment: compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [gold.withValues(alpha: 0.55), gold.withValues(alpha: 0.08)],
            ),
            boxShadow: [
              BoxShadow(
                color: gold.withValues(alpha: 0.25),
                blurRadius: 32,
                spreadRadius: 2,
              ),
            ],
          ),
          child: AppLogo(
            size: logoSize,
            radius: 18,
            storeLogoPath: store.storeLogoPath,
          ),
        ),
        SizedBox(height: compact ? 20 : 28),
        Text(
          store.systemName,
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
                height: 1.1,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          strings.loginSubtitle.replaceAll('{store}', store.storeName),
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.62),
            fontSize: compact ? 14 : 16,
            height: 1.45,
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: gold.withValues(alpha: 0.35)),
            ),
            child: Text(
              store.storeName,
              style: TextStyle(
                color: gold,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color gold;

  const _FeatureRow({required this.icon, required this.label, required this.gold});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: gold.withValues(alpha: 0.22)),
          ),
          child: Icon(icon, color: gold, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final RetailStore store;
  final AppStrings strings;
  final Color gold;
  final Color goldDeep;
  final TextEditingController usernameCtrl;
  final TextEditingController pinCtrl;
  final bool obscurePin;
  final bool submitting;
  final String? error;
  final VoidCallback onTogglePin;
  final VoidCallback onSubmit;

  const _LoginCard({
    required this.formKey,
    required this.store,
    required this.strings,
    required this.gold,
    required this.goldDeep,
    required this.usernameCtrl,
    required this.pinCtrl,
    required this.obscurePin,
    required this.submitting,
    required this.error,
    required this.onTogglePin,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.08),
              Colors.white.withValues(alpha: 0.03),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 40,
              offset: const Offset(0, 24),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      strings.signIn,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      strings.loginHint,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
                    ),
                    const SizedBox(height: 28),
                    _LoginField(
                      controller: usernameCtrl,
                      label: strings.username,
                      icon: Icons.person_outline_rounded,
                      accent: gold,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      validator: (v) => (v == null || v.trim().isEmpty) ? strings.usernameRequired : null,
                    ),
                    const SizedBox(height: 16),
                    _LoginField(
                      controller: pinCtrl,
                      label: strings.pin,
                      hint: strings.pinHint,
                      icon: Icons.lock_outline_rounded,
                      accent: gold,
                      obscureText: obscurePin,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onFieldSubmitted: (_) => onSubmit(),
                      suffix: IconButton(
                        icon: Icon(
                          obscurePin ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                        onPressed: onTogglePin,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return strings.pinRequired;
                        if (v.trim().length < 4) return strings.pinTooShort;
                        return null;
                      },
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.red.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline_rounded, color: AppColors.red, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                error!,
                                style: TextStyle(
                                  color: AppColors.red,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            colors: submitting
                                ? [gold.withValues(alpha: 0.45), goldDeep.withValues(alpha: 0.45)]
                                : [gold, goldDeep],
                          ),
                          boxShadow: submitting
                              ? null
                              : [
                                  BoxShadow(
                                    color: gold.withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                        ),
                        child: ElevatedButton(
                          onPressed: submitting ? null : onSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: const Color(0xFF1A1408),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: submitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1408)),
                                )
                              : Text(
                                  strings.signIn,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      strings.copyrightNotice,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.38), fontSize: 11, height: 1.35),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final Color accent;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool autocorrect;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const _LoginField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.accent,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autocorrect = true,
    this.inputFormatters,
    this.suffix,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autocorrect: autocorrect,
      inputFormatters: inputFormatters,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.45)),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.28)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.red.withValues(alpha: 0.7)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.red, width: 1.5),
        ),
      ),
    );
  }
}
