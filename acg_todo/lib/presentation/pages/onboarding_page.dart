import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_palette.dart';
import 'package:acg_todo/core/theme/app_scaffold.dart';
import 'package:acg_todo/presentation/providers/notification_providers.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    final scheduler = ref.read(notificationSchedulerProvider);
    scheduler.initialize();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: _finish,
                    child: Text(
                      '跳過',
                      style: TextStyle(color: context.palette.inkMuted),
                    ),
                  ),
                ),
              ),

              // Pages
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    _OnboardingStep(
                      icon: Icons.movie_filter_outlined,
                      color: context.palette.anime,
                      title: '歡迎使用 ACG To-Do',
                      description: '管理你的 Anime、Manga、Light Novel、Game 進度',
                    ),
                    _OnboardingStep(
                      icon: Icons.category_outlined,
                      color: context.palette.manga,
                      title: '進度追蹤',
                      description: '記錄目前看到第幾集、讀到第幾章、玩到多少人百分比',
                    ),
                    _OnboardingStep(
                      icon: Icons.notifications_active_outlined,
                      color: context.palette.lightNovel,
                      title: '不要錯過期限',
                      description: '設定目標完成日，快到期時推播通知提醒你',
                    ),
                  ],
                ),
              ),

              // Dots indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? context.palette.anime
                          : context.palette.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Next / Done button
              Padding(
                padding: EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.palette.anime,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _currentPage < 2 ? '下一步' : '開始使用',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _OnboardingStep extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _OnboardingStep({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: color),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: context.palette.inkSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
