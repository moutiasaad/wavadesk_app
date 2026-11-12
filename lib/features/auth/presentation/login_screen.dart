import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/data/data.dart';
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
import 'sheets/language_sheet.dart';
import 'widgets/enable_biometrics_sheet.dart';
import 'widgets/login_error_banner.dart';
import 'widgets/login_field.dart';
import 'widgets/login_header.dart';
import 'widgets/login_primary_button.dart';
import 'widgets/login_register_band.dart';

/// Sign-up lives on the website (opened in the external browser).
final Uri registerUrl = Uri.parse('https://wavadesk.com/register');

/// Opened from the "workspace suspended" banner.
final Uri manageSubscriptionUrl = Uri.parse('https://app.wavadesk.com/billing');

/// تسجيل الدخول — `01 Login v2.md`: teal wave header, white sheet that
/// overlaps it by 30dp, mint bottom wave. Email + password only.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _emailKey = GlobalKey();
  final _passwordBlockKey = GlobalKey(); // password … sign-in button

  /// First open: the sheet slides up 24dp and fades in (§11).
  late final AnimationController _enter = AnimationController(vsync: this, duration: AppMotion.normal);

  bool _obscure = true;
  bool _prefilled = false;
  bool _sessionExpired = false;
  BiometricKind? _biometricKind;

  // Controllers also notify on selection changes; only real edits count.
  String _lastEmail = '';
  String _lastPassword = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final repo = ref.read(authRepositoryProvider);
    final last = repo.lastIdentifier;
    if (last != null && last.contains('@')) {
      _email.text = last;
      _lastEmail = last;
      _prefilled = true;
    }
    _sessionExpired = ref.read(sessionExpiredProvider);
    _email.addListener(_onEmailChanged);
    _password.addListener(_onPasswordChanged);
    _emailFocus.addListener(_revealFocused);
    _passwordFocus.addListener(_revealFocused);
    _initBiometrics();
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
    _email.removeListener(_onEmailChanged);
    _password.removeListener(_onPasswordChanged);
    _password.clear(); // never keep the password around
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _enter.dispose();
    super.dispose();
  }

  Future<void> _initBiometrics() async {
    // Only for the "enable biometrics" prompt after a successful login; the
    // login screen itself has no biometric button (§4.3).
    final kind = await ref.read(biometricServiceProvider).availableKind();
    if (!mounted) return;
    _biometricKind = kind;
    Analytics.log('login_view', {'prefilled': _prefilled, 'session_expired': _sessionExpired});
  }

  // ---- Keyboard & focus -----------------------------------------------------

  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealFocused());
  }

  /// Keeps the focused field visible; for the password the block down to
  /// the sign-in button, so the keyboard never hides the button (§6).
  void _revealFocused() {
    final key = _passwordFocus.hasFocus ? _passwordBlockKey : (_emailFocus.hasFocus ? _emailKey : null);
    final box = key?.currentContext?.findRenderObject();
    if (box is RenderBox && box.attached) {
      box.showOnScreen(
        rect: (Offset.zero & box.size).inflate(AppSpacing.lg),
        duration: AppMotion.normal,
        curve: AppMotion.standard,
      );
    }
  }

  void _onEmailChanged() {
    if (_email.text == _lastEmail) return;
    _lastEmail = _email.text;
    if (_sessionExpired) setState(() => _sessionExpired = false);
    ref.read(loginControllerProvider.notifier).onIdentifierEdited(_email.text);
  }

  void _onPasswordChanged() {
    if (_password.text == _lastPassword) return;
    _lastPassword = _password.text;
    if (_sessionExpired) setState(() => _sessionExpired = false);
    ref.read(loginControllerProvider.notifier).onPasswordEdited(_password.text);
    setState(() {}); // obscured letter-spacing follows the text
  }

  // ---- Actions ------------------------------------------------------------------

  Future<void> _submit() async {
    final ctrl = ref.read(loginControllerProvider.notifier);
    final s = ref.read(loginControllerProvider);
    if (s.submitting || s.locked || s.status == LoginStatus.success) return;

    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    final next = await ctrl.submit(_email.text, _password.text);
    if (!mounted) return;

    // Validation: focus the first field with an error (§5.1).
    final after = ref.read(loginControllerProvider);
    if (after.identifierError != null) {
      _emailFocus.requestFocus();
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
    // The button shows a white check for 250ms before moving on (§11).
    if (!AppMotion.reduced(context)) await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    final repo = ref.read(authRepositoryProvider);
    final kind = _biometricKind;
    if (kind != null && !repo.biometricEnabled && !repo.biometricPrompted) {
      final wantsEnable = await showEnableBiometricsSheet(context, kind: kind);
      if (!mounted) return;
      var enabled = false;
      if (wantsEnable) {
        final result = await ref.read(biometricServiceProvider).authenticate(context.l10n.login_biometric_reason);
        enabled = result == BiometricResult.success;
        if (enabled) await repo.setBiometricEnabled(true);
      }
      await repo.setBiometricPrompted();
      Analytics.log('login_biometric_enable', {'enabled': enabled});
    }
    // Saving the session flips auth state; the router replaces the stack.
    await ref.read(loginControllerProvider.notifier).commit(next);
  }

  void _forgotPassword() {
    Analytics.log('login_forgot_tap');
    context.push(Routes.forgotPassword, extra: _email.text.trim());
  }

  Future<void> _openWeb(Uri url) async {
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      // No browser available: nothing to do.
    }
  }

  void _register() {
    Analytics.log('login_register_tap');
    _openWeb(registerUrl);
  }

  // ---- Reactions to controller state ------------------------------------------

  void _onStateChanged(LoginState? prev, LoginState next) {
    if (next.errorSeq == (prev?.errorSeq ?? 0)) return;
    final l = context.l10n;
    switch (next.errorCode) {
      case LoginErrorCode.invalidCredentials:
        // Both fields go red (banner explains); the password is cleared and
        // focused. Not a user edit, so it must not hide the banner.
        _lastPassword = '';
        _password.clear();
        _passwordFocus.requestFocus();
      case LoginErrorCode.network:
        AppSnackbar.show(
          context,
          message: l.login_err_offline,
          kind: SnackKind.error,
          actionLabel: l.login_retry,
          onAction: _submit,
        );
      case LoginErrorCode.server:
        AppSnackbar.show(context, message: l.login_err_server, kind: SnackKind.error);
      default:
        break;
    }
  }

  /// Codes shown as the banner card; network / server use a snackbar.
  static const _bannerCodes = {
    LoginErrorCode.invalidCredentials,
    LoginErrorCode.tooManyAttempts,
    LoginErrorCode.accountDisabled,
    LoginErrorCode.workspaceSuspended,
  };

  String _countdown(LoginState s) {
    final left = s.lockedUntil == null ? Duration.zero : s.lockedUntil!.difference(clock.now());
    final secs = left.isNegative ? 0 : (left.inMilliseconds / 1000).ceil();
    return '${(secs ~/ 60).toString().padLeft(2, '0')}:${(secs % 60).toString().padLeft(2, '0')}';
  }

  Widget? _banner(AppLocalizations l, LoginState s) {
    if (s.showBanner && _bannerCodes.contains(s.errorCode)) {
      return LoginErrorBanner(
        key: ValueKey(s.errorCode),
        message: switch (s.errorCode!) {
          LoginErrorCode.invalidCredentials => l.login_err_invalid,
          LoginErrorCode.tooManyAttempts => l.login_err_locked(_countdown(s)),
          LoginErrorCode.accountDisabled => l.login_err_disabled,
          LoginErrorCode.workspaceSuspended => l.login_err_suspended,
          _ => l.login_err_server,
        },
        actionLabel: s.errorCode == LoginErrorCode.workspaceSuspended ? l.login_manage_subscription : null,
        onAction: s.errorCode == LoginErrorCode.workspaceSuspended ? () => _openWeb(manageSubscriptionUrl) : null,
      );
    }
    if (_sessionExpired) {
      return LoginErrorBanner(
        key: const ValueKey('expired'),
        kind: LoginBannerKind.info,
        message: l.login_session_expired,
      );
    }
    return null;
  }

  String? _emailErrorText(AppLocalizations l, IdentifierError? e) => switch (e) {
    null => null,
    IdentifierError.required => l.login_err_email_empty,
    IdentifierError.invalidEmail || IdentifierError.invalidPhone => l.login_err_email_format,
  };

  String? _passwordErrorText(AppLocalizations l, PasswordError? e) => e == null ? null : l.login_err_pw_empty;

  // ---- Build ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final s = ref.watch(loginControllerProvider);
    ref.listen(loginControllerProvider, _onStateChanged);
    final dark = c.isDark;
    final reduced = AppMotion.reduced(context);
    final busy = s.submitting || s.status == LoginStatus.success;
    final wrongCredentials = s.showBanner && s.errorCode == LoginErrorCode.invalidCredentials;
    final langCode = ref.watch(settingsProvider).locale.languageCode;
    final langName = loginLanguageName(langCode);
    final banner = _banner(l, s);

    return PopScope(
      // Android back on the login screen closes the app (§5.4).
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) SystemNavigator.pop();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: appOverlay(context, lightStatusIcons: true),
        child: Scaffold(
          backgroundColor: dark ? const Color(0xFF0F171A) : Colors.white,
          resizeToAvoidBottomInset: true,
          body: GestureDetector(
            // Tap outside the fields hides the keyboard.
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Builder(
              builder: (context) {
                final compact = MediaQuery.sizeOf(context).height < 700;
                return Column(
                  children: [
                    LoginHeader(
                      compact: compact,
                      languageLabel: langName,
                      languageSemantics: l.login_lang_a11y(langName),
                      onLanguage: () => showLoginLanguageSheet(context, ref),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, area) => OverflowBox(
                          // The sheet rides 30dp up over the header and still
                          // reaches the bottom of the screen.
                          alignment: Alignment.topCenter,
                          minHeight: area.maxHeight + 30,
                          maxHeight: area.maxHeight + 30,
                          child: Transform.translate(
                            offset: const Offset(0, -30),
                            child: AnimatedBuilder(
                              animation: _enter,
                              builder: (context, child) {
                                final v = Curves.easeOut.transform(_enter.value);
                                return Opacity(
                                  opacity: v,
                                  child: Transform.translate(
                                    offset: Offset(0, reduced ? 0 : 24 * (1 - v)),
                                    child: child,
                                  ),
                                );
                              },
                              child: _Sheet(dark: dark, child: _content(context, l, s, busy, wrongCredentials, banner)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    AppLocalizations l,
    LoginState s,
    bool busy,
    bool wrongCredentials,
    Widget? banner,
  ) {
    final t = context.text;
    final dark = context.colors.isDark;
    final primary = dark ? const Color(0xFF2BB8AD) : const Color(0xFF0F7E7A);
    final muted = dark ? const Color(0xFF7B8A92) : const Color(0xFF94A3B8);
    final line = dark ? const Color(0xFF243036) : const Color(0xFFE9EEF2);
    final reduced = AppMotion.reduced(context);

    Widget padded(Widget child) => Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: child);

    final form = AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Banner: 150ms fade + slide down (§5.3).
          AnimatedSize(
            duration: reduced ? Duration.zero : const Duration(milliseconds: 150),
            alignment: AlignmentDirectional.topStart,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: reduced
                    ? child
                    : SlideTransition(
                        position: Tween(begin: const Offset(0, -0.15), end: Offset.zero).animate(anim),
                        child: child,
                      ),
              ),
              child: banner == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(key: banner.key, padding: const EdgeInsets.only(bottom: 12), child: banner),
            ),
          ),
          KeyedSubtree(
            key: _emailKey,
            child: LoginField(
              controller: _email,
              focusNode: _emailFocus,
              icon: AppIcons.customer,
              placeholder: l.login_email,
              errorText: _emailErrorText(l, s.identifierError),
              showErrorBorder: wrongCredentials,
              enabled: !busy,
              autofocus: !_prefilled,
              ltrText: true,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              onSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
          ),
          const SizedBox(height: 12),
          KeyedSubtree(
            key: _passwordBlockKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                LoginField(
                  controller: _password,
                  focusNode: _passwordFocus,
                  icon: AppIcons.lock,
                  placeholder: l.login_password_label,
                  errorText: _passwordErrorText(l, s.passwordError),
                  showErrorBorder: wrongCredentials,
                  enabled: !busy,
                  autofocus: _prefilled,
                  obscure: _obscure,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _submit(),
                  trailing: Semantics(
                    button: true,
                    label: _obscure ? l.login_password_show : l.login_password_hide,
                    excludeSemantics: true,
                    child: InkResponse(
                      onTap: () => setState(() => _obscure = !_obscure),
                      radius: 24,
                      child: SizedBox.square(
                        dimension: 48, // 44 visual inside a 48 hit area
                        child: Center(
                          child: AppIcon(
                            _obscure ? AppIcons.showPassword : AppIcons.hidePassword,
                            dp: 20,
                            color: muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Forgot password: end-aligned, margin 10 / 18.
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 18),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: InkWell(
                      onTap: busy ? null : _forgotPassword,
                      borderRadius: BorderRadius.circular(8),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Align(
                            widthFactor: 1,
                            child: Text(
                              l.login_forgot,
                              style: t.buttonSmall.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: primary),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                LoginPrimaryButton(
                  label: l.login_submit,
                  loading: s.submitting,
                  success: s.status == LoginStatus.success,
                  locked: s.locked,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        padded(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Text(
                  l.login_title,
                  style: t.h2.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                    color: dark ? const Color(0xFFE6ECEF) : const Color(0xFF0F172A),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 20),
                child: Text(
                  l.login_subtitle,
                  style: t.bodySmall.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
              form,
              // "ليس لديك حساب؟" divider, margin 18 vertical.
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  children: [
                    Expanded(child: Container(height: 1, color: line)),
                    const SizedBox(width: 12),
                    Text(
                      l.login_no_account,
                      style: t.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: muted),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Container(height: 1, color: line)),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Full-bleed band: outside the 22dp side padding.
        LoginRegisterBand(label: l.login_register, onTap: _register),
      ],
    );
  }
}

/// §4.2 white sheet: top radius 28, vertical white → `#F5F7F8` gradient,
/// soft top shadow, mint bottom wave (150dp) behind the scrolling content.
class _Sheet extends StatelessWidget {
  const _Sheet({required this.dark, required this.child});

  final bool dark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? const [Color(0xFF0F171A), Color(0xFF0F171A), Color(0xFF121C20)]
              : const [Colors.white, Colors.white, Color(0xFFF5F7F8)],
          stops: const [0, 0.55, 1],
        ),
        boxShadow: dark
            ? null
            : const [BoxShadow(offset: Offset(0, -10), blurRadius: 30, spreadRadius: -20, color: Color(0x590F172A))],
      ),
      child: Stack(
        children: [
          // Decorative, behind everything, not tappable; hidden under the
          // keyboard so the form has the room.
          if (!keyboard)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 150,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Opacity(
                    opacity: dark ? 0.12 : 1,
                    child: SvgPicture.asset('assets/images/login_wave_bottom.svg', fit: BoxFit.fill),
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
              padding: EdgeInsets.only(top: 26, bottom: bottomInset + 24),
              child: Center(
                child: ConstrainedBox(
                  // Tablets: content centred, max 440 wide (§6).
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
