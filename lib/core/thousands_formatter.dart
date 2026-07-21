import 'package:flutter/services.dart';

import 'formats.dart';

/// 금액 입력 중 천 단위 콤마를 실시간으로 넣는다(FR-208). 숫자만 남기고 재그룹.
/// 기록 시트·예산 설정 등 금액 입력이 있는 곳에서 공용으로 쓴다.
class ThousandsInputFormatter extends TextInputFormatter {
  const ThousandsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final text = groupThousands(digits);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
