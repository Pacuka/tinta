import 'package:folio/theme/colors/colors.dart';
import 'package:flutter/material.dart';
import 'package:folio_mobile_ui/common/bottom_sheet_menu/rounded_bottom_sheet.dart';
import 'summary_screen.i18n.dart';

import 'pages/allsum_page.dart';
import 'pages/start_page.dart';
import 'pages/grades_page.dart';
import 'pages/lessons_page.dart';
import 'pages/personality_page.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  SummaryScreenState createState() => SummaryScreenState();

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0x00000000),
        elevation: 0,
        isScrollControlled: true,
        useRootNavigator: true,
        builder: (context) => const SummaryScreen(),
      );
}

class SummaryScreenState extends State<SummaryScreen> {
  static const _pageCount = 5;

  late final PageController _pageController;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    _pageController.animateToPage(
      _page + 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _page == _pageCount - 1;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.92,
      child: TintaSheetSurface(
        child: Column(
          children: [
            // Handle
            Container(
              width: 42.0,
              height: 4.0,
              margin: const EdgeInsets.only(top: 12.0, bottom: 8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(45.0),
                color: AppColors.of(context).text.withValues(alpha: 0.12),
              ),
            ),

            // Story-style progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 4.0, 24.0, 0.0),
              child: Row(
                children: List.generate(_pageCount, (index) {
                  final active = index <= _page;
                  return Expanded(
                    child: Container(
                      height: 4.0,
                      margin: const EdgeInsets.symmetric(horizontal: 3.0),
                      decoration: BoxDecoration(
                        color: active
                            ? Theme.of(context).colorScheme.primary
                            : AppColors.of(context)
                                .text
                                .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _page = index),
                children: const [
                  StartBody(),
                  GradesBody(),
                  LessonsBody(),
                  AllSumBody(),
                  PersonalityBody(),
                ],
              ),
            ),

            // Unified next/finish button
            Padding(
              padding: EdgeInsets.fromLTRB(
                24.0,
                12.0,
                24.0,
                MediaQuery.of(context).padding.bottom + 12.0,
              ),
              child: FilledButton.icon(
                onPressed: isLastPage
                    ? () => Navigator.of(context).maybePop()
                    : _goNext,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52.0),
                ),
                icon: Icon(
                  isLastPage
                      ? Icons.check_rounded
                      : Icons.arrow_forward_rounded,
                ),
                label: Text(isLastPage ? 'finish'.i18n : 'next'.i18n),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
