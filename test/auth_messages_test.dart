import 'package:flutter_test/flutter_test.dart';
import 'package:oikos/features/auth/auth_messages.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('authErrorMessage', () {
    test('재시도 대기 — 초를 뽑아서 안내', () {
      expect(
        authErrorMessage(const AuthException(
            'For security purposes, you can only request this after 45 seconds.')),
        '보안을 위해 45초 뒤에 다시 시도할 수 있어요.',
      );
    });

    test('로그인 정보 불일치', () {
      expect(
        authErrorMessage(const AuthException('Invalid login credentials')),
        '이메일 또는 비밀번호가 맞지 않아요.',
      );
    });

    test('이미 가입된 이메일', () {
      expect(
        authErrorMessage(const AuthException('User already registered')),
        '이미 가입된 이메일이에요. 로그인으로 시도해 보세요.',
      );
    });

    test('이메일 미인증', () {
      expect(
        authErrorMessage(const AuthException('Email not confirmed')),
        '이메일 인증이 아직 안 됐어요. 받은 메일함(스팸함 포함)을 확인해 주세요.',
      );
    });

    test('메일 발송 한도', () {
      expect(
        authErrorMessage(const AuthException('email rate limit exceeded')),
        '메일 발송 한도에 잠시 닿았어요. 조금 뒤에 다시 시도해 주세요.',
      );
    });

    test('이메일 형식 오류', () {
      expect(
        authErrorMessage(const AuthException(
            'Unable to validate email address: invalid format')),
        '이메일 주소 형식을 확인해 주세요.',
      );
    });

    test('모르는 오류는 원문 그대로', () {
      expect(
        authErrorMessage(const AuthException('Something unusual happened')),
        'Something unusual happened',
      );
    });
  });
}
