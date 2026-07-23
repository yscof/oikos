import 'package:flutter_test/flutter_test.dart';
import 'package:oikos/features/auth/password_rules.dart';

void main() {
  group('validatePassword', () {
    test('규칙을 모두 지키면 통과', () {
      expect(validatePassword('Abcd123!'), isNull);
      expect(validatePassword(r'Str0ng$Pass'), isNull);
      expect(validatePassword('한글도Ok1!aa'), isNull); // 한글은 특수문자로 취급
    });

    test('8자 미만은 거절', () {
      expect(validatePassword('Ab1!xyz'), '비밀번호는 8자 이상이어야 해요.');
      expect(validatePassword(''), '비밀번호는 8자 이상이어야 해요.');
    });

    test('대문자 없으면 거절', () {
      expect(validatePassword('abcd123!'), '비밀번호에 대문자를 1자 이상 넣어 주세요.');
    });

    test('소문자 없으면 거절', () {
      expect(validatePassword('ABCD123!'), '비밀번호에 소문자를 1자 이상 넣어 주세요.');
    });

    test('숫자 없으면 거절', () {
      expect(validatePassword('Abcdefg!'), '비밀번호에 숫자를 1자 이상 넣어 주세요.');
    });

    test('특수문자 없으면 거절', () {
      expect(validatePassword('Abcd1234'), '비밀번호에 특수문자를 1자 이상 넣어 주세요.');
    });
  });
}
