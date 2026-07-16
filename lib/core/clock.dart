import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 시간 소스. 테스트에서 고정 시계로 override해 결정적 검증을 한다.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
