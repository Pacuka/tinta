// ignore_for_file: dead_code
import 'dart:math';

import 'package:google_fonts/google_fonts.dart';
import 'package:folio/api/providers/live_card_provider.dart';
import 'package:folio/ui/date_widget.dart';
import 'package:folio/theme/colors/colors.dart';
import 'package:folio/utils/format.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:intl/intl.dart';
import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:folio/api/providers/update_provider.dart';
import 'package:folio/api/providers/sync.dart';
import 'package:confetti/confetti.dart';
import 'package:folio/helpers/celebration.dart';
import 'package:folio/models/settings.dart';
import 'package:folio_kreta_api/providers/absence_provider.dart';
import 'package:folio_kreta_api/providers/event_provider.dart';
import 'package:folio_kreta_api/providers/exam_provider.dart';
import 'package:folio_kreta_api/providers/grade_provider.dart';
import 'package:folio_kreta_api/providers/homework_provider.dart';
import 'package:folio_kreta_api/providers/message_provider.dart';
import 'package:folio_kreta_api/models/message.dart';
import 'package:folio_kreta_api/providers/note_provider.dart';
import 'package:folio/api/providers/user_provider.dart';
import 'package:folio/api/providers/status_provider.dart';
import 'package:folio_kreta_api/providers/timetable_provider.dart';
import 'package:folio_kreta_api/models/week.dart';
import 'package:folio_mobile_ui/common/empty.dart';
import 'package:folio_mobile_ui/common/filter_bar.dart';
import 'package:folio_mobile_ui/common/widgets/update/update_dialog.dart';
import 'package:folio_mobile_ui/common/widgets/update/update_tile.dart';
import 'package:folio_mobile_ui/pages/home/live_card/live_card.dart';
import 'package:folio_mobile_ui/screens/navigation/navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:folio_mobile_ui/common/ink_stroke.dart';
import 'package:folio_mobile_ui/common/ink_motion.dart';
import 'package:folio_mobile_ui/common/haptic.dart';
import 'package:provider/provider.dart';
import 'home_page.i18n.dart';
import 'package:folio/ui/filter/widgets.dart';
import 'package:folio/ui/filter/sort.dart';
// import 'package:dropdown_button2/dropdown_button2.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  late UserProvider user;
  late SettingsProvider settings;
  late UpdateProvider updateProvider;
  late StatusProvider statusProvider;
  late GradeProvider gradeProvider;
  late TimetableProvider timetableProvider;
  late MessageProvider messageProvider;
  late AbsenceProvider absenceProvider;
  late HomeworkProvider homeworkProvider;
  late ExamProvider examProvider;
  late NoteProvider noteProvider;
  late EventProvider eventProvider;

  late PageController _pageController;
  ConfettiController? _confettiController;
  late LiveCardProvider _liveCard;
  late AnimationController _liveCardAnimation;
  bool? _lastLiveCardShow;

  late String greeting;
  late String firstName;

  late List<String> listOrder;
  static const pageCount = 5;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: pageCount, vsync: this);
    _pageController = PageController();
    user = Provider.of<UserProvider>(context, listen: false);
    _liveCard = Provider.of<LiveCardProvider>(context, listen: false);
    _liveCardAnimation = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    _liveCardAnimation.animateTo(_liveCard.show ? 1.0 : 0.0,
        duration: Duration.zero);

    listOrder = List.generate(pageCount, (index) => "$index");

    NameDay.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    // _filterController.dispose();
    _pageController.dispose();
    _tabController.dispose();
    _confettiController?.dispose();
    _liveCardAnimation.dispose();

    super.dispose();
  }

  /// Confetti once per app start, and only on the first start of the day.
  void _celebrate(Duration duration) {
    if (!(NavigationScreen.of(context)?.init("confetti") ?? false)) return;
    confettiAllowedToday().then((allowed) {
      if (!allowed || !mounted) return;
      setState(() => _confettiController = ConfettiController(duration: duration));
      Future.delayed(const Duration(seconds: 1))
          .then((value) => mounted ? _confettiController?.play() : null);
    });
  }

  // Days since epoch, so the picked greeting stays the same all day.
  int _dayNumber(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ 86400000;

  /// On birthdays/name days with lessons, replaces the date line.
  String? greetingSub;

  bool _hasLessonsToday(DateTime now) =>
      Provider.of<TimetableProvider>(context, listen: false)
          .getWeek(Week.current())
          ?.any((l) =>
              l.date.year == now.year &&
              l.date.month == now.month &&
              l.date.day == now.day) ??
      false;

  void setGreeting() {
    DateTime now = DateTime.now();
    List<String> nameParts = user.displayName?.split(" ") ?? ["?"];
    if (!settings.presentationMode) {
      firstName = nameParts.length > 1 ? nameParts[1] : nameParts[0];
    } else {
      firstName = "János";
    }

    bool customWelcome = false;
    greetingSub = null;

    if (now.isBefore(DateTime(now.year, DateTime.august, 31)) &&
        now.isAfter(DateTime(now.year, DateTime.june, 14))) {
      greeting = "goodrest";

      _celebrate(const Duration(seconds: 1));
    } else if (now.month == user.student?.birth.month &&
        now.day == user.student?.birth.day) {
      greeting = "happybirthday";
      final age = now.year - user.student!.birth.year;
      if (age > 0 && age < 100) {
        greeting =
            Localization("happybirthday_age".i18n).fill([age, firstName]);
        customWelcome = true;
      }
      if (_hasLessonsToday(now)) greetingSub = "noschoolruin".i18n;

      _celebrate(const Duration(seconds: 3));
    } else if (!settings.presentationMode &&
        NameDay.isNameDay(nameParts.skip(1), now)) {
      greeting = "happynameday";
      if (_hasLessonsToday(now)) greetingSub = "noschoolruin".i18n;
      _celebrate(const Duration(seconds: 2));
    } else if (now.month == DateTime.october &&
        now.day == 26 &&
        now.year > 2026) {
      final age = now.year - 2026;
      greeting = Localization("folioopen".i18n).fill([age]);
      customWelcome = true;

      _celebrate(const Duration(seconds: 3));
    } else if (now.month == DateTime.december &&
        now.day >= 24 &&
        now.day <= 26) {
      greeting = "merryxmas";
    } else if (now.month == DateTime.january && now.day == 1) {
      greeting = "happynewyear";
    } else if (settings.welcomeMessage.replaceAll(' ', '') != '') {
      greeting = settings.welcomeMessage;
      greeting = localizeFill(
        settings.welcomeMessage,
        [firstName],
      );

      customWelcome = true;
    } else if (_dayNumber(now) % 2 == 0 && now.hour >= 6 && now.hour < 21) {
      greeting = "fun_${(_dayNumber(now) ~/ 2) % 8}";
    } else if (now.hour >= 21 || now.hour < 4) {
      greeting = "goodnight";
    } else if (now.hour >= 18) {
      greeting = "goodevening";
    } else if (now.hour >= 12) {
      greeting = "goodafternoon";
    } else {
      greeting = "goodmorning";
    }

    greeting = customWelcome
        ? greeting
        : Localization(greeting.i18n).fill([firstName]);
  }

  bool _refreshing = false;

  Future<void> _refreshWithPulse() async {
    setState(() => _refreshing = true);
    try {
      await syncAll(context);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  int _upcomingExamCount(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return Provider.of<ExamProvider>(context)
        .exams
        .where((e) => !e.writeDate.isBefore(today))
        .length;
  }

  // Only recent ones: old unread KRÉTA messages would keep the badge stuck.
  int _unreadMessageCount(BuildContext context) {
    final since = DateTime.now().subtract(const Duration(days: 30));
    return Provider.of<MessageProvider>(context)
        .messages
        .where((m) =>
            m.type == MessageType.inbox &&
            !m.seen &&
            !m.deleted &&
            m.date.isAfter(since))
        .length;
  }

  // Ink line (Tinta's page signature) above the filter chips.
  PreferredSizeWidget _withInkStroke(FilterBar bar) => PreferredSize(
        preferredSize:
            Size.fromHeight(bar.preferredSize.height + _inkStrokeHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const InkStroke(
                padding: EdgeInsets.fromLTRB(24.0, 0, 24.0, 4.0),
                motionKey: "home"),
            bar,
          ],
        ),
      );
  static const _inkStrokeHeight = 30.0;

  /// Filter chip with a small count badge (hidden when 0).
  Widget _countTab(BuildContext context, String label, int count) {
    if (count == 0) return Tab(text: label);
    final colorScheme = Theme.of(context).colorScheme;
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 6.0),
          Container(
            constraints: const BoxConstraints(minWidth: 18.0),
            padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.0),
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              borderRadius: BorderRadius.circular(9.0),
            ),
            child: Text(
              count > 99 ? "99+" : "$count",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    user = Provider.of<UserProvider>(context);
    settings = Provider.of<SettingsProvider>(context);
    statusProvider = Provider.of<StatusProvider>(context, listen: false);
    updateProvider = Provider.of<UpdateProvider>(context);
    _liveCard = Provider.of<LiveCardProvider>(context);
    // Rebuild when synced data arrives; otherwise the visible list only
    // updated after switching tabs.
    Provider.of<GradeProvider>(context);
    Provider.of<HomeworkProvider>(context);
    Provider.of<AbsenceProvider>(context);
    Provider.of<NoteProvider>(context);
    Provider.of<EventProvider>(context);
    Provider.of<TimetableProvider>(context);
    gradeProvider = Provider.of<GradeProvider>(context);
    if (_liveCard.show != _lastLiveCardShow) {
      _lastLiveCardShow = _liveCard.show;
      _liveCardAnimation.animateTo(_liveCard.show ? 1.0 : 0.0);
    }

    setGreeting();
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: NestedScrollView(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                headerSliverBuilder: (context, _) => [
                      AnimatedBuilder(
                        animation: _liveCardAnimation,
                        builder: (context, child) {
                          final colorScheme = Theme.of(context).colorScheme;
                          final Color greetingColor =
                              Theme.of(context).textTheme.bodyMedium?.color ??
                                  colorScheme.onSurface;
                          final Color dateColor = AppColors.of(context)
                              .text
                              .withValues(alpha: 0.55);

                          return SliverAppBar(
                            automaticallyImplyLeading: false,
                            backgroundColor:
                                Theme.of(context).scaffoldBackgroundColor,
                            surfaceTintColor: Colors.transparent,
                            scrolledUnderElevation: 0.0,
                            shape: const RoundedRectangleBorder(),
                            centerTitle: false,
                            titleSpacing: 0.0,
                            // Welcome text
                            title: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Long greetings shrink to one line.
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                    greeting,
                                    overflow: TextOverflow.fade,
                                    textAlign: TextAlign.start,
                                    style:
                                        Provider.of<SettingsProvider>(context)
                                                        .fontFamily !=
                                                    '' &&
                                                Provider.of<SettingsProvider>(
                                                        context)
                                                    .titleOnlyFont
                                            ? GoogleFonts.getFont(
                                                Provider.of<SettingsProvider>(
                                                        context)
                                                    .fontFamily,
                                                textStyle: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 24.0,
                                                  color: greetingColor,
                                                ),
                                              )
                                            : TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 24.0,
                                                color: greetingColor,
                                              ),
                                  ),
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                    greetingSub ??
                                        DateFormat('EEEE, MMM d',
                                                I18n.locale.countryCode)
                                            .format(DateTime.now())
                                            .capital(),
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w500,
                                      color: dateColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            expandedHeight: _liveCardAnimation.value *
                                (_liveCard.currentState == LiveCardState.morning
                                    ? 270.0
                                    : (_liveCard.currentState ==
                                            LiveCardState.duringLesson
                                        ? (_liveCard.currentLesson?.description
                                                    .isNotEmpty ==
                                                true
                                            ? 292.0
                                            : 268.0)
                                        : (_liveCard.currentState ==
                                                LiveCardState.duringBreak
                                            ? 268.0
                                            : (_liveCard.currentState ==
                                                    LiveCardState.summary
                                                ? 260.0
                                                : 184.0)))),

                            // Live Card
                            flexibleSpace: FlexibleSpaceBar(
                              background: Container(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: 24.0,
                                    right: 24.0,
                                    top: 32.0 +
                                        MediaQuery.of(context).padding.top,
                                    bottom: 48.0,
                                  ),
                                  child: Transform.scale(
                                    scale: _liveCardAnimation.value,
                                    child: Opacity(
                                      opacity: _liveCardAnimation.value,
                                      child: const LiveCard(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            shadowColor: Colors.black,
                            // Filter Bar
                            bottom: _withInkStroke(
                              FilterBar(
                              items: [
                                Tab(text: "All".i18n),
                                Tab(text: "Grades".i18n),
                                _countTab(context, "Exams".i18n,
                                    _upcomingExamCount(context)),
                                _countTab(context, "Messages".i18n,
                                    _unreadMessageCount(context)),
                                Tab(text: "Absences".i18n),
                              ],
                              controller: _tabController,
                              disableFading: true,
                              pillStyle: true,
                              onTap: (i) async {
                                performHapticFeedback(settings.vibrate);
                                int selectedPage =
                                    _pageController.page!.round();

                                if (i == selectedPage) return;
                                if (_pageController.page?.roundToDouble() !=
                                    _pageController.page) {
                                  _pageController.animateToPage(i,
                                      curve: Curves.easeIn,
                                      duration: kTabScrollDuration);
                                  return;
                                }

                                // swap current page with target page
                                setState(() {
                                  _pageController.jumpToPage(i);
                                  String currentList = listOrder[selectedPage];
                                  listOrder[selectedPage] = listOrder[i];
                                  listOrder[i] = currentList;
                                });
                              },
                            )),
                            pinned: true,
                            floating: false,
                            snap: false,
                          );
                        },
                      ),
                    ],
                body: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      // from flutter source
                      if (notification is ScrollUpdateNotification &&
                          !_tabController.indexIsChanging) {
                        if ((_pageController.page! - _tabController.index)
                                .abs() >
                            1.0) {
                          _tabController.index = _pageController.page!.floor();
                        }
                        _tabController.offset =
                            (_pageController.page! - _tabController.index)
                                .clamp(-1.0, 1.0);
                      } else if (notification is ScrollEndNotification) {
                        _tabController.index = _pageController.page!.round();
                        if (!_tabController.indexIsChanging) {
                          _tabController.offset =
                              (_pageController.page! - _tabController.index)
                                  .clamp(-1.0, 1.0);
                        }
                      }
                      return false;
                    },
                    child: PageView.custom(
                      controller: _pageController,
                      childrenDelegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          return FutureBuilder<List<DateWidget>>(
                            key: ValueKey<String>(listOrder[index]),
                            future: getFilterWidgets(homeFilters[index],
                                context: context),
                            builder: (context, dateWidgets) => dateWidgets
                                        .data !=
                                    null
                                ? Column(
                                    children: [
                                      if (index == 0 &&
                                          updateProvider.available)
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              24.0, 4.0, 24.0, 4.0),
                                          child: UpdateTile(
                                            updateProvider.releases.first,
                                            padding: EdgeInsets.zero,
                                            onTap: () => UpdateDialog.show(
                                                context,
                                                updateProvider.releases.first),
                                          ),
                                        ),
                                      // Breathing ink blot while syncing.
                                      AnimatedSize(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        child: _refreshing
                                            ? const Padding(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 8.0),
                                                child: InkPulse(),
                                              )
                                            : const SizedBox(width: double.infinity),
                                      ),
                                      Expanded(
                                        child: RefreshIndicator.noSpinner(
                                          onRefresh: _refreshWithPulse,
                                          child: ImplicitlyAnimatedList<Widget>(
                                            items: [
                                              if (index == 0)
                                                const SizedBox(
                                                    key: Key("\$premium")),
                                              ...sortDateWidgets(context,
                                                  dateWidgets:
                                                      dateWidgets.data!,
                                                  padding: EdgeInsets.zero),
                                              if (dateWidgets.data!.isEmpty)
                                                Padding(
                                                  key: const Key("\$empty"),
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 48.0),
                                                  child: Empty(
                                                      subtitle:
                                                          "empty".i18n),
                                                ),
                                            ],
                                            itemBuilder: filterItemBuilder,
                                            spawnIsolate: false,
                                            areItemsTheSame: (a, b) =>
                                                a.key == b.key,
                                            physics: const BouncingScrollPhysics(
                                                parent:
                                                    AlwaysScrollableScrollPhysics()),
                                            padding: EdgeInsets.only(
                                              left: 24.0,
                                              right: 24.0,
                                              bottom: MediaQuery.of(context)
                                                      .padding
                                                      .bottom +
                                                  8.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Container(),
                          );
                        },
                        childCount: 5,
                        findChildIndexCallback: (Key key) {
                          final ValueKey<String> valueKey =
                              key as ValueKey<String>;
                          final String data = valueKey.value;
                          return listOrder.indexOf(data);
                        },
                      ),
                      physics: const PageScrollPhysics()
                          .applyTo(const BouncingScrollPhysics()),
                    ),
                  ),
                )),
          ),

          // confetti 🎊
          if (_confettiController != null)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController!,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.02,
                numberOfParticles: 120,
                maxBlastForce: 20,
                minBlastForce: 10,
                gravity: 0.3,
                minimumSize: const Size(5, 5),
                maximumSize: const Size(20, 20),
              ),
            ),
        ],
      ),
    );
  }

  Future<Widget> filterViewBuilder(context, int activeData) async {
    final activeFilter = homeFilters[activeData];

    List<Widget> filterWidgets = sortDateWidgets(
      context,
      dateWidgets: await getFilterWidgets(activeFilter, context: context),
      showDivider: true,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: RefreshIndicator(
        color: Theme.of(context).colorScheme.secondary,
        onRefresh: () => syncAll(context),
        child: ListView.builder(
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            if (filterWidgets.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: filterWidgets[index],
              );
            } else {
              return Empty(subtitle: "empty".i18n);
            }
          },
          itemCount: max(filterWidgets.length, 1),
        ),
      ),
    );
  }
}
