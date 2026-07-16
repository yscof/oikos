import 'package:flutter_test/flutter_test.dart';
import 'package:oikos/data/entry.dart';
import 'package:oikos/insight/insight_messages.dart';

void main() {
  test('톤 계약: 명령형·판단어·AI가 어떤 문장에도 없다', () {
    // '세요'는 ~하세요/~마세요 류 명령형을 통째로 잡는다.
    const banned = ['세요', '과소비', '낭비', 'AI', '아껴'];
    final sentences = allSentencesForToneCheck();
    expect(sentences, isNotEmpty);
    for (final sentence in sentences) {
      for (final word in banned) {
        expect(
          sentence.contains(word),
          isFalse,
          reason: '금지어 "$word" 발견: "$sentence"',
        );
      }
    }
  });

  test('이/가 조사: 받침 유무를 따른다', () {
    expect(headlineFrequency(Category.meal), '이번 주는 식사가 잦았어요');
    expect(headlineFrequency(Category.delivery), '이번 주는 배달이 잦았어요');
  });
}
