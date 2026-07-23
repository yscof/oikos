import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/auth.dart';
import 'password_rules.dart';

/// 로그인 / 가입 화면 (FR-101·102·103). Supabase가 설정된 빌드에서만 뜬다.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signUp = false;
  bool _busy = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_signUp) {
      final ruleError = validatePassword(_password.text);
      if (ruleError != null) {
        setState(() {
          _error = ruleError;
          _notice = null;
        });
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    final auth = ref.read(authServiceProvider);
    try {
      if (_signUp) {
        final res = await auth.signUp(_email.text, _password.text);
        if (res.session == null && mounted) {
          setState(() => _notice = '가입 확인 메일을 보냈어요. 메일을 확인해 주세요.');
        }
      } else {
        await auth.signIn(_email.text, _password.text);
      }
      // 성공하면 authStateProvider가 홈으로 전환한다.
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = '문제가 생겼어요. 잠시 후 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_email.text.trim().isEmpty) {
      setState(() => _error = '비밀번호를 재설정할 이메일을 먼저 입력해 주세요.');
      return;
    }
    try {
      await ref.read(authServiceProvider).resetPassword(_email.text);
      if (mounted) setState(() => _notice = '비밀번호 재설정 메일을 보냈어요.');
    } catch (_) {
      if (mounted) setState(() => _error = '메일 발송에 실패했어요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('오이코스', style: textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  _signUp ? '이메일로 가입해요' : '다시 만나 반가워요',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                TextField(
                  key: const Key('email-field'),
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('password-field'),
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    border: const OutlineInputBorder(),
                    helperText: _signUp ? passwordRulesHint : null,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ],
                if (_notice != null) ...[
                  const SizedBox(height: 12),
                  Text(_notice!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  style:
                      FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: Text(_busy ? '잠시만요…' : (_signUp ? '가입하기' : '로그인')),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            _signUp = !_signUp;
                            _error = null;
                            _notice = null;
                          }),
                  child: Text(_signUp ? '이미 계정이 있어요 · 로그인' : '계정이 없어요 · 가입하기'),
                ),
                if (!_signUp)
                  TextButton(
                    onPressed: _busy ? null : _resetPassword,
                    child: const Text('비밀번호를 잊었어요'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
