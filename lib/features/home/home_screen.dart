import 'package:flutter/material.dart';

/// M0 플레이스홀더 홈. M2에서 최근 기록, M4에서 인사이트 헤드라인이 들어온다.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('오이코스', style: textTheme.headlineMedium),
              const SizedBox(height: 12),
              Text(
                '기록이 쌓이면 소비의 흐름을 읽어드릴게요',
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
