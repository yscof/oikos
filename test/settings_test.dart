import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oikos/data/entry.dart';

import 'pump_app.dart';

Entry exp(String id, int amount, DateTime at) => Entry(
      id: id,
      kind: EntryKind.expense,
      amountWon: amount,
      category: Category.meal,
      memo: '',
      occurredAt: at,
      createdAt: at,
    );

void main() {
  testWidgets('데이터 내보내기 → JSON이 클립보드로 간다', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });

    await pumpApp(tester, entries: [
      exp('a', 12000, DateTime(2026, 7, 15, 12)),
      exp('b', 8000, DateTime(2026, 7, 16, 9)),
    ]);
    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('데이터 내보내기'));
    await tester.pumpAndSettle();

    final setData =
        calls.where((c) => c.method == 'Clipboard.setData').toList();
    expect(setData, hasLength(1));
    final text = (setData.single.arguments as Map)['text'] as String;
    final decoded = jsonDecode(text) as List;
    expect(decoded, hasLength(2));
    expect(find.text('기록 2건을 클립보드에 복사했어요'), findsOneWidget);
  });

  testWidgets('기록이 없으면 내보내기가 조용히 알려준다', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('데이터 내보내기'));
    await tester.pumpAndSettle();
    expect(find.text('아직 내보낼 기록이 없어요'), findsOneWidget);
  });

  testWidgets('모든 데이터 삭제 → 확인 → 빈 상태', (tester) async {
    await pumpApp(tester, entries: [exp('a', 12000, DateTime(2026, 7, 15, 12))]);
    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('모든 데이터 삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('첫 기록을 남기면 여기에 하나씩 쌓여요'), findsOneWidget);
  });

  testWidgets('라이선스·버전·로컬 저장 안내가 보인다', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();

    expect(find.text('오픈소스 라이선스'), findsOneWidget);
    expect(find.text('버전'), findsOneWidget);
    expect(find.text('0.1.0'), findsOneWidget);
    expect(find.text('모든 데이터는 이 기기에만 저장됩니다'), findsOneWidget);
  });
}
