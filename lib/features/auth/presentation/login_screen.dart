import 'package:clock/clock.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/models.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/analytics.dart';
import '../../../core/utils/l10n.dart';
import '../../../core/widgets/widgets.dart';
import '../application/auth_session.dart';
import '../application/login_controller.dart';
import '../data/biometric_service.dart';
import '../domain/identifier.dart';
import '../domain/login_state.dart';
import 'widgets/app_logo_mark.dart';
import 'widgets/biometric_login_button.dart';
import 'widgets/enable_biometrics_sheet.dart';
import 'widgets/login_error_banner.dart';
import 'widgets/or_divider.dart';
import 'widgets/sign_up_prompt.dart';

/// Sign-up lives on the web (Login spec §4.11).
final Uri signUpUrl = Uri.parse('https://wavadesk.com/start');

/// Opened from the "workspace suspended" banner (§7).
final Uri manageSubscriptionUrl = Uri.parse('https://app.wavadesk.com/billing');

/// تسجيل الدخول — implements `01 Login Screen.md` on top of the Design System.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  final _identifierFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _identifierKey = GlobalKey();
  final _passwordBlockKey = GlobalKey(); // password … sign-in button

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300 + 4 * 60), // 5 groups, 60ms stagger
  );
  late final AnimationController _shake = AnimationController(vsync: this, duration: AppMotion.slow);

  bool _obscure = true;
  bool _prefilled = false;
  BiometricKind? _biometricKind;
  bool _biometricBusy = false;
  NetworkState _network = NetworkState.online;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final repo = ref.read(authRepositoryProvider);
    if (repo.lastIdentifier != null) {
      _identifier.text = repo.lastIdentifier!;
      _lastIdentifier = _identifier.text;
      _prefilled = true;
    }
    _identifier.addListener(_onIdentifierChanged);
    _password.addListener(_onPasswordChanged);
    _identifierFocus.addListener(_revealFocused);
    _passwordFocus.addListener(_revealFocused);
    _initBiometrics();
    _initConnectivity();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _enter.value = 1;
    } else if (_enter.status == AnimationStatus.dismissed) {
      _enter.forward();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
    _identifier.removeListener(_onIdentifierChanged);
    _password.removeListener(_onPasswordChanged);
    // §13: clear the password from memory.
    _password.clear();
    _identifier.dispose();
    _password.dispose();
    _identifierFocus.dispose();
    _passwordFocus.dispose();
    _enter.dispose();
    _shake.dispose();
    super.dispose();
  }

  // ---- Setup ------------------------------------------------------------------

  Future<void> _initBiometrics() async {
    final repo = ref.read(authRepositoryProvider);
    final kind = await ref.read(biometricServiceProvider).availableKind();
    if (!mounted) return;
    setState(() => _biometricKind = kind);
    Analytics.log('login_view', {
      'prefilled': _prefilled,
      'biometric_available': kind != null && repo.biometricEnabled && repo.refreshToken != null,
    });
  }

  Future<void> _initConnectivity() async {
    NetworkState map(List<ConnectivityResult> r) =>
        r.isEmpty || r.every((x) => x == ConnectivityResult.none) ? NetworkState.offline : NetworkState.online;
    try {
      final connectivity = Connectivity();
      final initial = await connectivity.checkConnectivity();
      if (mounted) setState(() => _network = map(initial));
      _connectivitySub = connectivity.onConnectivityChanged.listen(
        (r) {
          if (mounted) setState(() => _network = map(r));
        },
        onError: (_) {},
      );
    } catch (_) {
      // Plugin unavailable (tests / unsupported platform): assume online.
    }
  }

  // ---- Keyboard & focus -----------------------------------------------------

  /// Keyboard opened/closed: keep the focused field visible (§3).
  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealFocused());
  }

  /// Scrolls the focused field (16dp padding, 200ms) into view. For the
  /// password the whole block down to the sign-in button is revealed, so
  /// the keyboard never covers the button (§15).
  void _revealFocused() {
    final key = _passwordFocus.hasFocus
        ? _passwordBlockKey
        : (_identifierFocus.hasFocus ? _identifierKey : null);
    final box = key?.currentContext?.findRenderObject();
    if (box is RenderBox && box.attached) {
      box.showOnScreen(
        rect: (Offset.zero & box.size).inflate(AppSpacing.lg),
        duration: AppMotion.normal,
        curve: AppMotion.standard,
      );
    }
  }

  // Controllers also notify on selection/composing changes (e.g. when a field
  // loses focus on submit). Only a real text edit may hide errors.
  String _lastIdentifier = '';
  String _lastPassword = '';

  void _onIdentifierChanged() {
    if (_identifier.text == _lastIdentifier) return;
    _lastIdentifier = _identifier.text;
    ref.read(loginControllerProvider.notifier).onIdentifierEdited();
    setState(() {}); // button enablement
  }

  void _onPasswordChanged() {
    if (_password.text == _lastPassword) return;
    _lastPassword = _password.text;
    ref.read(loginControllerProvider.notifier).onPasswordEdited();
    setState(() {});
  }

  // ---- Actions ------------------------------------------------------------------

  bool get _bothFilled => _identifier.text.trim().isNotEmpty && _password.text.isNotEmpty;

  bool get _showBiometric {
    final repo = ref.read(authRepositoryProvider);
    return _biometricKind != null && repo.biometricEnabled && repo.refreshToken != null;
  }

  Future<void> _submit() async {
    final ctrl = ref.read(loginControllerProvider.notifier);
    final s = ref.read(loginControllerProvider);
    if (!_bothFilled || s.submitting || s.locked || s.cooldown) return;

    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus(); // keyboard dismissed while submitting
    final next = await ctrl.submit(_identifier.text, _password.text);
    if (!mounted) return;

    final after = ref.read(loginControllerProvider);
    if (after.identifierError != null) {
      _identifierFocus.requestFocus();
      return;
    }
    if (after.passwordError != null) {
      _passwordFocus.requestFocus();
      return;
    }

    switch (next) {
      case null:
        return;
      case LoginNextRoute(step: LoginNextStep.twoFactor):
        context.push(Routes.loginTwoFactor);
      case LoginNextRoute(step: LoginNextStep.workspacePicker):
        context.push(Routes.loginWorkspace);
      case LoginNextRoute(step: LoginNextStep.conversations):
        break;
      case LoginNextSession():
        await _completeLogin(next);
    }
  }

  Future<void> _completeLogin(LoginNextSession next) async {
    HapticFeedback.mediumImpact();
    TextInput.finishAutofillContext();
    final repo = ref.read(authRepositoryProvider);
    final kind = _biometricKind;
    if (kind != null && !repo.biometricEnabled && !repo.biometricPrompted) {
      final wantsEnable = await showEnableBiometricsSheet(context, kind: kind);
      if (!mounted) return;
      var enabled = false;
      if (wantsEnable) {
        final result =
            await ref.read(biometricServiceProvider).authenticate(context.l10n.login_biometric_reason);
        enabled = result == BiometricResult.success;
        if (enabled) await repo.setBiometricEnabled(true);
      }
      await repo.setBiometricPrompted();
      Analytics.log('login_biometric_enable', {'enabled': enabled});
    }
    // Saving the session flips auth state; the router then replaces the
    // stack with Conversations → لي.
    await ref.read(loginControllerProvider.notifier).commit(next);
  }

  Future<void> _biometricLogin() async {
    setState(() => _biometricBusy = true);
    final l = context.l10n;
    final result = await ref.read(loginControllerProvider.notifier).biometricLogin(l.login_biometric_reason);
    if (!mounted) return;
    setState(() => _biometricBusy = false);
    if (result == BiometricResult.lockedOut) {
      AppSnackbar.show(context, message: l.login_biometric_locked, kind: SnackKind.error);
    }
    // Cancel: nothing visible (§4.10).
  }

  void _forgotPassword() {
    Analytics.log('login_forgot_tap');
    context.push(Routes.forgotPassword, extra: _identifier.text.trim());
  }

  Future<void> _openWeb(Uri url) async {
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Nothing to do when no browser is available.
    }
  }

  // ---- Reactions to controller state ------------------------------------------

  void _onStateChanged(LoginState? prev, LoginState next) {
    if (next.errorSeq == (prev?.errorSeq ?? 0)) return;
    final code = next.errorCode;
    const authErrors = {
      LoginErrorCode.invalidCredentials,
      LoginErrorCode.accountDisabled,
      LoginErrorCode.workspaceSuspended,
    };
    if (authErrors.contains(code)) {
      // Auth error: clear the password, focus it, shake the form (§5, §11).
      // Not an agent edit, so it must not hide the banner it caused.
      _lastPassword = '';
      _password.clear();
      _passwordFocus.requestFocus();
      if (!AppMotion.reduced(context)) _shake.forward(from: 0);
    }
  }

  String _bannerMessage(AppLocalizations l, LoginState s) => switch (s.errorCode!) {
        LoginErrorCode.invalidCredentials => l.login_err_invalid,
        LoginErrorCode.accountDisabled => l.login_err_disabled,
        LoginErrorCode.workspaceSuspended => l.login_err_suspended,
        LoginErrorCode.tooManyAttempts => l.login_err_locked(_countdown(s)),
        LoginErrorCode.server => l.login_err_server,
        LoginErrorCode.network => l.login_err_network,
      };

  String _countdown(LoginState s) {
    final left = s.lockedUntil == null ? Duration.zero : s.lockedUntil!.difference(clock.now());
    final secs = left.isNegative ? 0 : (left.inMilliseconds / 1000).ceil();
    return '${(secs ~/ 60).toString().padLeft(2, '0')}:${(secs % 60).toString().padLeft(2, '0')}';
  }

  String? _identifierErrorText(AppLocalizations l, IdentifierError? e) => switch (e) {
        null => null,
        IdentifierError.required => l.login_val_identifier_required,
        IdentifierError.invalidEmail => l.login_val_email_invalid,
        IdentifierError.invalidPhone => l.login_val_phone_invalid,
      };

  String? _passwordErrorText(AppLocalizations l, PasswordError? e) => switch (e) {
        null => null,
        PasswordError.required => l.login_val_password_required,
        PasswordError.tooShort => l.login_val_password_short,
      };

  // ---- Build ---------------------------------------------------------------------

  /// Fade + 12dp slide-up for staggered group [i] (0 = logo … 4 = footer).
  Widget _enterGroup(int i, Widget child, {bool scaleIn = false}) {
    final start = i * 60 / 540;
    final curve = CurvedAnimation(
      parent: _enter,
      curve: Interval(start, start + 300 / 540, curve: AppMotion.standard),
    );
    return AnimatedBuilder(
      animation: curve,
      child: child,
      builder: (context, child) {
        final v = curve.value;
        Widget w = Opacity(opacity: v, child: child);
        if (scaleIn) {
          w = Transform.scale(scale: 0.9 + 0.1 * v, alignment: AlignmentDirectional.centerStart.resolve(Directionality.of(context)), child: w);
        } else {
          w = Transform.translate(offset: Offset(0, 12 * (1 - v)), child: w);
        }
        return w;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final s = ref.watch(loginControllerProvider);
    ref.listen(loginControllerProvider, _onStateChanged);

    final busy = s.submitting || _biometricBusy;
    final canSubmit = _bothFilled && !s.locked && !s.cooldown;
    final fieldStyle = t.bodyLarge.copyWith(fontSize: 15);
    final ltrAlign = context.isRtl ? TextAlign.end : TextAlign.start;
    final largeText = MediaQuery.textScalerOf(context).scale(10) > 13;

    final banner = AnimatedSize(
      duration: AppMotion.normal,
      curve: AppMotion.standard,
      alignment: AlignmentDirectional.topStart,
      child: AnimatedSwitcher(
        duration: AppMotion.normal,
        child: s.showBanner
            ? Padding(
                key: ValueKey(s.errorCode),
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: LoginErrorBanner(
                  message: _bannerMessage(l, s),
                  actionLabel: switch (s.errorCode) {
                    LoginErrorCode.network => l.login_retry,
                    LoginErrorCode.workspaceSuspended => l.login_manage_subscription,
                    _ => null,
                  },
                  onAction: switch (s.errorCode) {
                    LoginErrorCode.network => _submit,
                    LoginErrorCode.workspaceSuspended => () => _openWeb(manageSubscriptionUrl),
                    _ => null,
                  },
                ),
              )
            : const SizedBox(width: double.infinity),
      ),
    );

    final form = AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          banner,
          KeyedSubtree(
            key: _identifierKey,
            child: AppTextField(
              label: l.login_identifier_label,
              hint: l.login_identifier_hint,
              controller: _identifier,
              focusNode: _identifierFocus,
              autofocus: !_prefilled,
              readOnly: busy,
              style: fieldStyle,
              textDirection: TextDirection.ltr,
              textAlign: ltrAlign,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username, AutofillHints.email],
              autocorrect: false,
              enableSuggestions: false,
              onSubmitted: (_) => _passwordFocus.requestFocus(),
              error: _identifierErrorText(l, s.identifierError),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          KeyedSubtree(
            key: _passwordBlockKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: l.login_password_label,
                  controller: _password,
                  focusNode: _passwordFocus,
                  readOnly: busy,
                  obscure: _obscure,
                  obscuringCharacter: '•',
                  style: _obscure && _password.text.isNotEmpty ? fieldStyle.copyWith(letterSpacing: 3) : fieldStyle,
                  textDirection: TextDirection.ltr,
                  textAlign: ltrAlign,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  autocorrect: false,
                  enableSuggestions: false,
                  onSubmitted: (_) => _submit(),
                  error: _passwordErrorText(l, s.passwordError),
                  suffix: AppIconButton(
                    icon: _obscure ? AppIcons.preview : AppIcons.hidePassword,
                    iconSize: 20,
                    iconColor: c.textTertiary,
                    semanticLabel: _obscure ? l.login_password_show : l.login_password_hide,
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Opacity(
                    opacity: busy ? 0.4 : 1,
                    child: AppButton(
                      label: l.login_forgot,
                      variant: AppButtonVariant.text,
                      size: AppButtonSize.small,
                      horizontalPadding: AppSpacing.xs,
                      textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                      onPressed: busy ? null : _forgotPassword,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                AppButton(
                  label: l.login_submit,
                  size: AppButtonSize.large,
                  expand: true,
                  textStyle: const TextStyle(fontSize: 15.5),
                  loading: s.submitting,
                  onPressed: canSubmit || s.submitting ? _submit : null,
                ),
              ],
            ),
          ),
          if (_showBiometric) ...[
            const SizedBox(height: 18),
            OrDivider(label: l.login_or),
            const SizedBox(height: 18),
            Opacity(
              opacity: s.submitting ? 0.4 : 1,
              child: BiometricLoginButton(
                kind: _biometricKind!,
                loading: _biometricBusy,
                onPressed: busy ? null : _biometricLogin,
              ),
            ),
          ],
        ],
      ),
    );

    return Scaffold(
      backgroundColor: c.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            ConnectionBanner(state: _network, offlineLabel: l.login_offline),
            Expanded(
              child: LayoutBuilder(
                builder: (context, viewport) => SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 420, minHeight: viewport.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: AppSpacing.x4l),
                            _enterGroup(
                              0,
                              const Align(alignment: AlignmentDirectional.centerStart, child: AppLogoMark()),
                              scaleIn: true,
                            ),
                            const SizedBox(height: 26),
                            _enterGroup(
                              1,
                              Semantics(
                                header: true,
                                child: Text(
                                  l.login_title,
                                  style: t.displayLarge.copyWith(fontSize: 30, height: 1.3),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            _enterGroup(
                              2,
                              Text(
                                l.login_subtitle,
                                style: t.bodyLarge.copyWith(fontSize: 15, color: c.textSecondary),
                                maxLines: largeText ? null : 2,
                                overflow: largeText ? null : TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 28),
                            _enterGroup(3, _ShakeX(animation: _shake, child: form)),
                            const Spacer(),
                            const SizedBox(height: AppSpacing.xxl),
                            _enterGroup(
                              4,
                              Opacity(
                                opacity: busy ? 0.4 : 1,
                                child: SignUpPrompt(
                                  onTap: busy
                                      ? null
                                      : () {
                                          Analytics.log('login_signup_tap');
                                          _openWeb(signUpUrl);
                                        },
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.x4l),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal shake: 3 cycles, ±6dp, decaying over 300ms (§11).
class _ShakeX extends StatelessWidget {
  const _ShakeX({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) {
          final t = animation.value;
          final dx = t == 0 || t == 1 ? 0.0 : math.sin(t * 3 * 2 * math.pi) * 6 * (1 - t);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
      );
}
