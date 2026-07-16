import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// main()에서 실제 인스턴스로 override된다. 테스트에서는
/// SharedPreferences.setMockInitialValues 후 얻은 인스턴스로 override.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider는 override 필수'),
);
