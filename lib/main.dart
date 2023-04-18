import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'dart:io' show Directory, File, Platform, exit;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fyp_searchub/pages/history.dart';
import 'package:fyp_searchub/pages/search.dart';
import 'package:fyp_searchub/pages/settings.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import 'package:duration/duration.dart';
import 'package:async/async.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marquee/marquee.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:screenshot/screenshot.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:crypto/crypto.dart';
import 'package:html/parser.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/vision/v1.dart' as vision;

import 'package:flutter/services.dart';
import 'package:stats/stats.dart';

import 'my_flutter_app_icons.dart';

part 'main.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
  //   await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  // }

  if (Platform.isAndroid) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

  runApp(
    MaterialApp(
      theme: ThemeData(
          colorSchemeSeed: const Color.fromARGB(255, 74, 137, 164),
          useMaterial3: true),
      home: const WebViewContainer(),
      builder: EasyLoading.init(),
    ),
  );
}

// enum SearchAlgorithm { Title, ClickContent, TitleWithClickContent }
// Map SearchAlgorithm = {"Title": 0, "ClickContent": 1, "TitleWithClickContent": 2};
List<String> SearchAlgorithmList = [
  // "Title",
  // "Webpage Content",
  // "Title With Webpage Content",
  "Hovered Webpage Content",
  // "New Mode",
  // "TEST HIGHLIGHT"
];

List<String> MergeAlgorithmList = [
  "ABAB",
  "Frequency",
  "Original Rank",
];

// ignore: non_constant_identifier_names
List<String> SearchPlatformList = [
  // "SmartText",
  // "Google",
  // "Bing",
  // "YouTube",
  // "Twitter",
  // "Facebook",
  // "Instagram",
  // "LinkedIn",
  // "SmartImage",
  "Webpage",
  "Video",
  "SNS",
];

// // ignore: non_constant_identifier_names
// List<String> SearchPlatformList_Text = [
//   "Google",
//   "Bing",
//   "DuckDuckGo",
//   "Yahoo",
// ];

enum Theme { Light, Dark, Auto }

const API_KEY = "AIzaSyDv7P0-TmysPp39vKIe5syLoQNoCs9yfp4"; // self
// const API_KEY = "AIzaSyDMa-bYzmjOHJEZdXxHOyJA55gARPpqOGw";
// const API_KEY = "AIzaSyD48Vtn0yJnAIU6SyoIkPJQg3xWKax48dw"; //old
// const API_KEY = "AIzaSyD3D4sYkKkWOsSdFxTywO-0VX5GIfJSBZc"; //old
// const SEARCH_ENGINE_ID_GOOGLE = "35fddaf2d5efb4668";
const SEARCH_ENGINE_ID_GOOGLE = "55379d2db84314f83"; // self
// const SEARCH_ENGINE_ID_YOUTUBE = "07e66762eb98c40c8";
const SEARCH_ENGINE_ID_TWITTER = "d0444b9b194124097";
const SEARCH_ENGINE_ID_FACEBOOK = "a48841f7c9ed94dd6";
const SEARCH_ENGINE_ID_INSTAGRAM = "a74dea74df886441a";
const SEARCH_ENGINE_ID_LINKEDIN = "c1f02371fcab94ca7";

int page = 1;

class WebViewContainer extends StatefulWidget {
  const WebViewContainer({super.key});

  @override
  State<WebViewContainer> createState() => _WebViewContainerState();
}

class _WebViewContainerState extends State<WebViewContainer>
    with TickerProviderStateMixin {
  late final AnimationController _drillingAnimationController =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))
        ..repeat();

  // settings
  var _searchAlgorithm,
      _mergeAlgorithm,
      _preloadNumber,
      _autoSwitchPlatform,
      _theme;

  // key
  var _marqueeKey = UniqueKey();
  var _settingsPageKey = UniqueKey();
  final _preloadPageKeys = [];
  var _currentPreloadPageKey;
  final _preloadPlatformKey = GlobalKey();
  final _searchButtonKey = GlobalKey();
  final _drawerKey = GlobalKey();
  final _joyStickKey = GlobalKey();
  final _drillButtonKey = GlobalKey();
  final _historiesButtonKey = GlobalKey();
  final _firstResultButtonKey = GlobalKey();
  final _backButtonKey = GlobalKey();
  final _shareButtonKey = GlobalKey();

  // tutorial
  List<TargetFocus> targets = [], targetsAfter = [];
  // controllers
  InAppWebViewController? _currentWebViewController;
  Map _webViewControllers = {};
  PullToRefreshController? _refreshController;
  final _preloadPageControllers = [];
  var _currentPreloadPageController;
  final PreloadPageController _preloadPlatformController =
      PreloadPageController(
    initialPage: 0,
  );
  PreloadPageController _testPreloadPageController = PreloadPageController(
    initialPage: 0,
  );
  final ScreenshotController _screenshotController = ScreenshotController();

  // search related
  // ignore: non_constant_identifier_names
  Map URLs = {},
      _searchResult = {},
      _activatedSearchPlatforms = {},
      _searchHistory = {};
  String _searchText = "",
      _prevSearchText = "",
      _previousURL = "",
      _currentSearchPlatform = "",
      _prevSearchPlatform = "",
      _webpageContent = "",
      _currentWebViewTitle = "";
  bool _isSearching = false, _gg = false, _isImageSearch = false;
  List _currentURLs = [];
  int _currentURLIndex = 0,
      _loadingPercentage = 0,
      _selectedPageIndex = 0,
      _searchCount = 0;

  //stopwatch
  final activityStopwatch = Stopwatch();
  // final _redirectStopwatch = Stopwatch();

  // colours
  final Color _defaultAppBarColor = Colors.white,
      _searchingAppBarColor = Colors.amber[300]!,
      _themedAppBarColor = Colors.blue[100]!;
  Color _appBarColor = Colors.blue[100]!, _fabColor = Colors.blue[100]!;

  // ?maybe useful
  // bool _swipe = false;
  // bool _redirecting = false;
  // bool _drilling = false;

  // List _activatedSearchPlatformKeys = [GlobalKey()];
  // final rake = Rake();

  // others
  bool _menuShown = false;
  bool _isFetching = false;
  var _currentImage;
  bool _isTutorial = false;

  //regex
  var containNonEnglish = RegExp(r'^\w+');
  var endsWithSlash = RegExp(r'\/$');

  // positions
  double _hoverX = 0.0, _hoverY = 0.0;
  // double _scrollX = 0.0, _scrollY = 0.0;
  double _joystickX = 0,
      _joystickY = 0,
      _joystickBottom = 45,
      _joystickLeft = 0;
  double _joystickHeight = 100, _joystickWidth = 100;
  bool _togglePlatformMode = false;

  // databases
  late Isar _isar;
  List _searchRecords = [];

  // include only first page
  // counting start, (page=2) => (start=11), (page=3) => (start=21), etc
  int _start = (page - 1) * 10 + 1;

  // var _testPreloadPageKey = GlobalKey();

  void _init() async {
    final prefs = await SharedPreferences.getInstance();
    // final algorithm = await prefs.getInt("searchAlgorithm") ?? SearchAlgorithm.Title.index;
    final algorithm =
        await prefs.getString("searchAlgorithm") ?? SearchAlgorithmList[0];
    final mergeAlgorithm =
        await prefs.getString("mergeAlgorithm") ?? MergeAlgorithmList[0];
    // final preloadNumber = await prefs.getInt("preloadNumber") ?? 1;
    final preloadNumber = await prefs.getBool("preloadNumber") ?? true;

    final autoSwitchPlatform = await prefs.getInt("autoSwitchPlatform") ?? 0;
    final theme = await prefs.getInt("theme") ?? Theme.Light.index;

    await Isar.open([URLSchema, SearchRecordSchema], name: "isar");
    final isar = Isar.getInstance("isar");
    final searchRecords =
        await isar!.searchRecords.where().sortByTimeDesc().findAll();

    // final isarSearchRecords =
    //     await Isar.open([SearchRecordSchema], name: "SearchRecord");

    setState(() {
      _currentSearchPlatform = "Webpage";
      _searchAlgorithm = algorithm;
      _mergeAlgorithm = mergeAlgorithm;
      _preloadNumber = preloadNumber;
      _autoSwitchPlatform = autoSwitchPlatform;
      _theme = theme;
      _isar = isar!;
      _searchRecords = searchRecords;
      _joystickLeft =
          (MediaQuery.of(context).size.width / 2) - (_joystickWidth / 2);
    });

    // log("_searchAlgorithm: $_searchAlgorithm | _theme: $_theme");
    // log(SearchAlgorithm.values[_searchAlgorithm].toString().split('.').last);

    // _refreshController = kIsWeb
    //     ? null
    //     : PullToRefreshController(
    //         settings: PullToRefreshSettings(
    //           color: Colors.blue,
    //         ),
    //         onRefresh: () async {
    //           log("refreshing...");
    //           // await _refreshController!.beginRefreshing();
    //           log("refreshing ${await _currentWebViewController!.getUrl()}");
    //           await _currentWebViewController!.reload();
    //           await _refreshController!.endRefreshing();
    //         },
    //       );

    _initTutorial("before");
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _init();
  }

  void _initTutorial(String status) {
    if (status == "before") {
      targets.add(
        TargetFocus(
          identify: "Menu",
          keyTarget: _drawerKey,
          enableOverlayTab: true,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const <Widget>[
                  Text(
                    "Menu",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "This is where you can access the settings page as well as revisiting this tutorial.",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      );

      targets.add(
        TargetFocus(
          identify: "Search Button",
          keyTarget: _searchButtonKey,
          unFocusAnimationDuration: Duration(milliseconds: 100),
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const <Widget>[
                  Text(
                    "Search",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      "Now, click on it to start your first search.",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      );
    } else if (status == "after") {
      targetsAfter.add(
        TargetFocus(
          identify: "Joystick",
          keyTarget: _joyStickKey,
          enableOverlayTab: true,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const <Widget>[
                  Text(
                    "Browse through results with the joystick",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "Swipe horizontally to switch result, vertically to switch platform.",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      );

      targetsAfter.add(
        TargetFocus(
          identify: "Drill Button",
          keyTarget: _drillButtonKey,
          enableOverlayTab: true,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const <Widget>[
                  Text(
                    "Drag-and-drop this button to drill on anything",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0),
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.only(top: 10.0),
                  //   child: Text(
                  //     "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin pulvinar tortor eget maximus iaculis.",
                  //     style: TextStyle(color: Colors.white),
                  //   ),
                  // )
                ],
              ),
            )
          ],
        ),
      );

      targetsAfter.add(
        TargetFocus(
          identify: "Histories Button",
          keyTarget: _historiesButtonKey,
          enableOverlayTab: true,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const <Widget>[
                  Text(
                    "Click to see the search records within the current search session",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0),
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.only(top: 10.0),
                  //   child: Text(
                  //     "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin pulvinar tortor eget maximus iaculis.",
                  //     style: TextStyle(color: Colors.white),
                  //   ),
                  // )
                ],
              ),
            )
          ],
        ),
      );

      targetsAfter.add(
        TargetFocus(
          identify: "First Result Button",
          keyTarget: _firstResultButtonKey,
          enableOverlayTab: true,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const <Widget>[
                  Text(
                    "Click to go back to the first result",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0),
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.only(top: 10.0),
                  //   child: Text(
                  //     "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin pulvinar tortor eget maximus iaculis.",
                  //     style: TextStyle(color: Colors.white),
                  //   ),
                  // )
                ],
              ),
            )
          ],
        ),
      );

      targetsAfter.add(
        TargetFocus(
          identify: "Back Button",
          keyTarget: _backButtonKey,
          enableOverlayTab: true,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const <Widget>[
                  Text(
                    "Click to go back",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0),
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.only(top: 10.0),
                  //   child: Text(
                  //     "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin pulvinar tortor eget maximus iaculis.",
                  //     style: TextStyle(color: Colors.white),
                  //   ),
                  // )
                ],
              ),
            )
          ],
        ),
      );

      targetsAfter.add(
        TargetFocus(
          identify: "Share Button",
          keyTarget: _shareButtonKey,
          enableOverlayTab: true,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const <Widget>[
                  Text(
                    "Click to share the current result",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0),
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.only(top: 10.0),
                  //   child: Text(
                  //     "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin pulvinar tortor eget maximus iaculis.",
                  //     style: TextStyle(color: Colors.white),
                  //   ),
                  // )
                ],
              ),
            )
          ],
        ),
      );
    }
  }

  // @override
  // void dispose() {
  //   // Clean up the controller when the widget is removed from the
  //   // widget tree.
  //   _handleSearch.dispose();
  //   super.dispose();
  // }

  void _showTutorial() {
    setState(() {
      _isTutorial = true;
    });

    TutorialCoachMark tutorial = TutorialCoachMark(
        targets: targets, // List<TargetFocus>
        colorShadow: Colors.blue, // DEFAULT Colors.black
        // alignSkip: Alignment.bottomRight,
        // textSkip: "SKIP",
        // paddingFocus: 10,
        // focusAnimationDuration: Duration(milliseconds: 500),
        // unFocusAnimationDuration: Duration(milliseconds: 500),
        // pulseAnimationDuration: Duration(milliseconds: 500),
        // pulseVariation: Tween(begin: 1.0, end: 0.99),
        // showSkipInLastTarget: false,
        onFinish: () {
          print("finish");
        },
        onClickTargetWithTapPosition: (target, tapDetails) {
          print("target: $target");
          print(
              "clicked at position local: ${tapDetails.localPosition} - global: ${tapDetails.globalPosition}");
        },
        onClickTarget: (target) {
          print(target);
          if (target.identify == "Search Button") {
            _pushSearchPage();
          }
        },
        onSkip: () {
          print("skip");
        })
      ..show(context: context);

    // tutorial.skip();
    // tutorial.finish();
    // tutorial.next(); // call next target programmatically
    // tutorial.previous(); // call previous target programmatically
  }

  void _showTutorialAfter() async {
    log("tutorialing after 1");
    await Future.delayed(const Duration(milliseconds: 3000), () {});
    log("tutorialing after 2");

    _initTutorial("after");

    log("tutorialing after 3");

    TutorialCoachMark tutorial = TutorialCoachMark(
        targets: targetsAfter, // List<TargetFocus>
        colorShadow: Colors.blue, // DEFAULT Colors.black
        // alignSkip: Alignment.bottomRight,
        // textSkip: "SKIP",
        // paddingFocus: 10,
        // focusAnimationDuration: Duration(milliseconds: 500),
        // unFocusAnimationDuration: Duration(milliseconds: 500),
        // pulseAnimationDuration: Duration(milliseconds: 500),
        // pulseVariation: Tween(begin: 1.0, end: 0.99),
        // showSkipInLastTarget: false,
        onFinish: () {
          print("finish");
        },
        onClickTargetWithTapPosition: (target, tapDetails) {
          print("target: $target");
          print(
              "clicked at position local: ${tapDetails.localPosition} - global: ${tapDetails.globalPosition}");
        },
        onClickTarget: (target) {
          print(target);
          if (target.identify == "Search Button") {
            _pushSearchPage();
          }
        },
        onSkip: () {
          print("skip");
        })
      ..show(context: context);

    log("tutorialing after 4");

    // tutorial.skip();
    // tutorial.finish();
    // tutorial.next(); // call next target programmatically
    // tutorial.previous(); // call previous target programmatically

    setState(() {
      _isTutorial = false;
    });
    log("tutorialing after 5");
  }

  final RestartableTimer _searchTimer = RestartableTimer(
    const Duration(seconds: 5),
    () {
      log("5 seconds passed");
    },
  );

  _getSearchQuery() async {
    String query = "";
    switch (_searchAlgorithm) {
      case "TEST HIGHLIGHT":
        await _currentWebViewController!.evaluateJavascript(source: """
                        var element = document.elementFromPoint($_hoverX, $_hoverY);
                        element.style.border = "2px solid red";
                        // Drill.postMessage(element.innerText);
                        window.flutter_inappwebview.callHandler('getDrillText', element.innerText);
                      """);
        log("TEST HIGHLIGHT: $_webpageContent");
        break;
      case "Title":
        query = (await _currentWebViewController!.getTitle())!;
        break;
      case "Webpage Content":
        await _currentWebViewController!.evaluateJavascript(source: """
                        var x = window.innerWidth/2;
                        var y = window.innerHeight/2;
                        var centre = document.elementFromPoint(x, y);
                        // Drill.postMessage(centre.innerText);
                        window.flutter_inappwebview.callHandler('getDrillText', centre.innerText);
                      """);
        if (_webpageContent == null || _webpageContent == "") {
          query = (await _currentWebViewController!.getTitle())!;
        } else {
          query = _webpageContent;
        }
        break;
      case "Title With Webpage Content":
        await _currentWebViewController!.evaluateJavascript(source: """
                        var x = window.innerWidth/2;
                        var y = window.innerHeight/2;
                        var centre = document.elementFromPoint(x, y);
                        // Drill.postMessage(centre.innerText);
                        window.flutter_inappwebview.callHandler('getDrillText', centre.innerText);
                      """);
        if (_webpageContent == null || _webpageContent == "") {
          query = (await _currentWebViewController!.getTitle())!;
        } else {
          query =
              "${await _currentWebViewController!.getTitle()} $_webpageContent";
        }
        break;
      case "Hovered Webpage Content":
        await _currentWebViewController!.evaluateJavascript(source: """
                        var centre = document.elementFromPoint($_hoverX, $_hoverY);
                        // Drill.postMessage(centre.innerText);
                        window.flutter_inappwebview.callHandler('getDrillText', centre.innerText);
                      """);
        if (_webpageContent == null || _webpageContent == "") {
          // query = (await _currentWebViewController!.getTitle())!;
          query = "";
        } else {
          // log(rake.rank(_webpageContent, minChars: 5, minFrequency: 2));
          query = _webpageContent;
          log("_webpageContent: $_webpageContent");
        }
        break;
      case "New Mode":
        await _currentWebViewController!.evaluateJavascript(source: """
                var elementMouseIsOver = document.elementFromPoint($_hoverX, $_hoverY);
                var content = elementMouseIsOver.innerText;

                if (elementMouseIsOver.nodeName == "A"){
                    // Drill.postMessage(elementMouseIsOver.href);
                    window.flutter_inappwebview.callHandler('getDrillText', elementMouseIsOver.href);
                }

                else if (content == "" || content == "null") {

                    if (elementMouseIsOver.nodeName == "IMG") {

                        if (elementMouseIsOver.alt == "" || elementMouseIsOver.alt == "null") {
                            // Drill.postMessage(elementMouseIsOver.src);
                            window.flutter_inappwebview.callHandler('getDrillText', elementMouseIsOver.src);
                        } else {
                            // Drill.postMessage(elementMouseIsOver.alt);
                            window.flutter_inappwebview.callHandler('getDrillText', elementMouseIsOver.alt);
                        }

                    } else {
                        const cssObj = window.getComputedStyle(elementMouseIsOver, null);
                        let bgImage = cssObj.getPropertyValue("background-image");
                        const picUrl = bgImage.slice(5,-2);

                        // Drill.postMessage(picUrl);
                        window.flutter_inappwebview.callHandler('getDrillText', picUrl);
                    }

                } else {
                    // Drill.postMessage(content);
                    window.flutter_inappwebview.callHandler('getDrillText', content);
                }
                      """);

        if (_webpageContent == null || _webpageContent == "") {
          query = (await _currentWebViewController!.getTitle())!;
        } else {
          query = _webpageContent;
        }
        break;
    }

    return query;
  }

  _updateSearchRecord(String searchText, [remove = false]) async {
    // check if the record exist
    final searchRecord = await _isar.searchRecords
        .filter()
        .searchTextEqualTo(searchText)
        .findAll();

    // remove record
    if (remove) {
      await _isar.writeTxn(() async {
        var result = await _isar.searchRecords.delete(searchRecord[0].id);
        log("deleted: $result");
      });

      _searchRecords =
          await _isar.searchRecords.where().sortByTimeDesc().findAll();

      return;
    }

    // add or update record
    // record exists
    if (searchRecord.isNotEmpty) {
      log("exist");
      await _isar.writeTxn(() async {
        final existingRecord =
            await _isar.searchRecords.get(searchRecord[0].id);

        existingRecord!.time = DateTime.now();
        existingRecord.searchCount++;

        await _isar.searchRecords.put(existingRecord);
      });
    }
    // new record
    else {
      log("put new");

      final newSearchRecord = SearchRecord()
        ..searchText = _searchText
        ..time = DateTime.now()
        ..searchCount = 1;

      log("newSearchRecord: $newSearchRecord");
      await _isar.writeTxn(() async {
        await _isar.searchRecords.put(newSearchRecord);
      });
    }

    _searchRecords =
        await _isar.searchRecords.where().sortByTimeDesc().findAll();

    log("searchRecords: ${_searchRecords}");
  }

  _performSearch(value, platform) async {
    log("searching...");

    EasyLoading.show(
      status: 'Searching $value on $platform',
    );

    log("_searchTimer.tick ${_searchTimer.tick}");
    if (_searchCount == 0 || _searchTimer.tick > 0) {
      _searchTimer.reset();
      setState(() {
        _searchCount = 0;
      });
    }

    setState(() {
      _searchCount++;
    });

    await _updateSearchRecord(_searchText);

    log("_searchCount: $_searchCount | _searchTimer.isActive: ${_searchTimer.isActive}");

    if (_searchTimer.isActive) {
      if (_searchCount > 5) {
        setState(() {
          _gg = true;
        });
      }
    }
    log("_gg: $_gg");

    var ENGINE_ID, uri;

    log("page: $page | _start: $_start");

    var response;
    // different uri for different search engines
    switch (platform) {
      case 'Google':
        uri = Uri.https('www.googleapis.com', '/customsearch/v1', {
          'key': API_KEY,
          'cx': SEARCH_ENGINE_ID_GOOGLE,
          'q': value,
          'start': _start.toString(),
        });
        response = !_gg ? await http.get(uri) : null;
        break;
      case 'Bing':
        response = !_gg
            ? await http.get(
                Uri.parse(
                    // 'https://api.bing.microsoft.com/v7.0/search?q=$value&count=100&offset=0&customconfig=6c099879-5079-4eb0-be77-694fffc16ddc&mkt=en-US'),
                    'https://api.bing.microsoft.com/v7.0/custom/search?q=$value&customconfig=6c099879-5079-4eb0-be77-694fffc16ddc&mkt=en-US'),
                // Send authorization headers to the backend.
                headers: {
                  // 'Ocp-Apim-Subscription-Key':
                  // "d24c91d7b0f04d9aad0b07d22a2d9155",

                  'Ocp-Apim-Subscription-Key':
                      'f22755e26efb48f9ad6fa930df61f1cc' // self
                },
              )
            : null;
        break;

      case 'DuckDuckGo':
        // String getActualUrl(String url) {
        //   // String realUrl = Uri.decodeFull(url.toString());
        //   // Extract the actual URL from the intermediate URL
        //   final start = url.indexOf('/l/?uddg=') + '/l/?uddg='.length;
        //   final end = url.indexOf('&rut=');
        //   return Uri.decodeFull(url.substring(start, end));
        // }

        response =
            await http.get(Uri.parse('https://duckduckgo.com/html/?q=$value'));

        // response = !_gg
        //     ? await http.get(
        //         Uri.parse(
        //             'https://api.duckduckgo.com?q=$value&format=json&no_html=1'),

        //         // // Send authorization headers to the backend.
        //         // headers: {
        //         //   'Ocp-Apim-Subscription-Key':
        //         //       "d24c91d7b0f04d9aad0b07d22a2d9155",
        //         // },
        //       )
        //     : null;

        log("ddg response: $response");

        // uri = Uri.https(
        //     'https://api.duckduckgo.com/q=$value&format=json&no_html=1');
        // response = !_gg ? await http.get(uri) : null;
        break;
      case 'Yahoo':
        response = await http
            .get(Uri.parse('https://search.yahoo.com/search?p=$value'));
        break;
      case 'YouTube':
        uri = Uri.https('www.googleapis.com', '/youtube/v3/search', {
          'key': "AIzaSyD48Vtn0yJnAIU6SyoIkPJQg3xWKax48dw",
          'part': "snippet",
          'type': "video",
          'maxResults': "100",
          'q': value,
        });
        response = !_gg ? await http.get(uri) : null;
        break;
      case 'Bing Video':
        response = !_gg
            ? await http.get(
                Uri.parse(
                    'https://api.bing.microsoft.com/v7.0/videos/search?q=$value&count=100&offset=0'),
                // Send authorization headers to the backend.
                headers: {
                  'Ocp-Apim-Subscription-Key':
                      "d24c91d7b0f04d9aad0b07d22a2d9155",
                },
              )
            : null;
        break;
      case 'Vimeo':
        response = !_gg
            ? await http.get(
                Uri.parse(
                    'https://api.vimeo.com/videos?page=1&per_page=100&query=$value&sort=relevant'),
                // Send authorization headers to the backend.
                headers: {
                  'Authorization': "bearer 721697e9ac433826e98951bd7e250647",
                },
              )
            : null;
        log("vimeo response: $response");
        break;
      // TODO: replace with Twitter API
      case 'Twitter':
        uri = Uri.https('www.googleapis.com', '/customsearch/v1', {
          'key': API_KEY,
          'cx': SEARCH_ENGINE_ID_TWITTER,
          'q': value,
          'start': _start.toString(),
        });
        response = !_gg ? await http.get(uri) : null;
        break;
      // TODO: replace with Facebook API
      case 'Facebook':
        uri = Uri.https('www.googleapis.com', '/customsearch/v1', {
          'key': API_KEY,
          'cx': SEARCH_ENGINE_ID_FACEBOOK,
          'q': value,
          'start': _start.toString(),
        });
        response = !_gg ? await http.get(uri) : null;
        break;
      // TODO: replace with Instagram API
      case 'Instagram':
        uri = Uri.https('www.googleapis.com', '/customsearch/v1', {
          'key': API_KEY,
          'cx': SEARCH_ENGINE_ID_INSTAGRAM,
          'q': value,
          'start': _start.toString(),
        });
        response = !_gg ? await http.get(uri) : null;
        break;
      // TODO: replace with LinkedIn API (?)
      case 'LinkedIn':
        uri = Uri.https('www.googleapis.com', '/customsearch/v1', {
          'key': API_KEY,
          'cx': SEARCH_ENGINE_ID_LINKEDIN,
          'q': value,
          'start': _start.toString(),
        });
        response = !_gg ? await http.get(uri) : null;
        break;
    }

    EasyLoading.dismiss();

    log("response: $response");

    String cleanUrl(String url) {
      String cleaned = url;
      // url.replaceFirst("http://", "https://").replaceFirst("https://", "");
      if (endsWithSlash.hasMatch(cleaned)) {
        cleaned = cleaned.substring(0, cleaned.length - 1);
      }
      return cleaned;
    }

    if (response != null) {
      if (response.statusCode == 200) {
        var jsonResponse;
        try {
          jsonResponse =
              convert.jsonDecode(response.body) as Map<String, dynamic>;
        } catch (error) {
          log("error: $error");
        }

        // log("jsonResponse.toString(): ${jsonResponse.toString()}");
        // log(jsonResponse['items']);

        var items = [];
        switch (platform) {
          case 'Google':
            var results = jsonResponse['items'] != null
                ? jsonResponse['items'] as List<dynamic>
                : [];

            for (int i = 0; i < results.length; i++) {
              items.add({
                "title": results[i]['title'],
                "link": cleanUrl(results[i]['link'].toString()),
                "rank": i + 1,
              });
            }

            log("google items: $items");
            break;
          case 'Bing':
            int rank = 1;
            // var results = jsonResponse['webPages'] != null
            //     ? jsonResponse['webPages']['value'][0]['deepLinks'] != null
            //         ? jsonResponse['webPages']['value'][0]['deepLinks']
            //             as List<dynamic>
            //         : jsonResponse['webPages']['value'] as List<dynamic>
            //     : [];

            log("bing0: ${jsonResponse['webPages']}");

            // if (jsonResponse['webPages']['value'][0]['deepLinks'] != null) {
            items.add({
              "title": jsonResponse['webPages']['value'][0]['name'],
              "link":
                  cleanUrl(jsonResponse['webPages']['value'][0]['displayUrl']),
              "rank": 1,
            });

            rank++;

            log("bing1: ${items}");
            // }

            // ! NO displayUrl for deep links
            if (jsonResponse['webPages']['value'][0]['deepLinks'] != null) {
              for (int i = 0;
                  i < jsonResponse['webPages']['value'][0]['deepLinks'].length;
                  i++) {
                var current =
                    jsonResponse['webPages']['value'][0]['deepLinks'][i];
                items.add({
                  "title": current['name'],
                  "link": cleanUrl(current['url']),
                  "rank": rank,
                });
                rank++;

                if (current['deepLinks'] != null) {
                  for (int j = 0; j < current['deepLinks'].length; j++) {
                    var currentDeeper = current['deepLinks'][j];
                    items.add({
                      "title": currentDeeper['name'],
                      "link": cleanUrl(currentDeeper['url']),
                      "rank": rank,
                    });
                    rank++;
                  }
                }
              }
            }

            log("bing2: ${items}");

            // items = jsonResponse['webPages']['value'][0]['deepLinks'] != null
            //     ? [
            //         {
            //           "title": jsonResponse['webPages']['value'][0]['name'],
            //           "link": jsonResponse['webPages']['value'][0]['displayUrl']
            //         },
            //       ]
            //     : [];

            // for (var result in results) {
            //   items.add({"title": result['name'], "link": result['url']});
            // }
            break;
          case "DuckDuckGo":
            String getActualUrl(String url) {
              // String realUrl = Uri.decodeFull(url.toString());
              // Extract the actual URL from the intermediate URL
              final start = url.indexOf('/l/?uddg=') + '/l/?uddg='.length;
              final end = url.indexOf('&rut=');
              return Uri.decodeFull(url.substring(start, end));
            }
            // Parse the HTML response
            final document = parse(response.body);

            // Extract title and URL elements
            final titleElements = document.querySelectorAll('.result__title');
            final urlElements = document.querySelectorAll('.result__url');

            // Extract title and URL data
            final titles = titleElements
                .map((element) => element.text.toString().trim())
                .toList();
            final urls = urlElements
                .map((element) =>
                    getActualUrl(element.attributes['href'].toString()))
                .toList();

            // Print extracted data
            for (int i = 0; i < titles.length; i++) {
              // log('Title: ${titles[i]} | URL: ${urls[i]}');
              items.add({
                "title": titles[i],
                "link": cleanUrl(urls[i]),
                "rank": i + 1
              });
            }

            // log("ddg jsonResponse['RelatedTopics']: ${jsonResponse['RelatedTopics']}");
            // // for (var result in jsonResponse["RelatedTopics"]) {
            // //   final title = result["FirstURL"]
            // //       .replaceFirst("https://", "")
            // //       .replaceFirst("http://", ""); // Extract title from URL
            // //   final link = result["FirstURL"];
            // //   items.add({"title": title, "link": link});
            // // }

            // if (jsonResponse['AbstractURL'] != "") {
            //   items.add({
            //     "title": jsonResponse['Heading'],
            //     "link": jsonResponse['AbstractURL']
            //   });
            // }

            log("ddg results: ${items}");

            break;
          case 'Yahoo':
            log("Yahoo");

            // Parse the HTML response
            final document = parse(response.body);

            // Extract title and URL data
            final titles = document
                .querySelectorAll('.title a')
                .map((element) => element.text)
                .toList();
            final urls = document
                .querySelectorAll('.title a')
                .map((element) => element.attributes['href']!)
                .toList();

            // Filter out unwanted results
            final filteredTitles = <String>[];
            final filteredUrls = <String>[];
            for (int i = 0; i < titles.length; i++) {
              // Exclude results that do not have a valid URL or contain specific keywords
              if (urls[i] != null &&
                  !titles[i].contains('See all results for this question')) {
                // Clean up the extracted title
                String cleanedTitle = titles[i]
                    .trim()
                    .replaceAll(RegExp(r'\s{2,}'), ' '); // Remove extra spaces
                cleanedTitle = cleanedTitle.replaceAll(
                    RegExp(r'\u200B'), ''); // Remove zero-width space
                filteredTitles.add(cleanedTitle);
                filteredUrls.add(urls[i]!);
              }
            }

            // Print extracted data
            for (int i = 0; i < filteredTitles.length; i++) {
              log('Title: ${filteredTitles[i]} | URL: ${urls[i]}');
              items
                  .add({"title": filteredTitles[i], "link": cleanUrl(urls[i])});
            }

            break;
          case 'YouTube':
            items = jsonResponse['items'] != null
                ? jsonResponse['items'] as List<dynamic>
                : [];
            for (var item in items) {
              var videoId = item['id']['videoId'];
              var videoUrl = "https://www.youtube.com/watch?v=$videoId";
              item['title'] = item['snippet']['title'];
              item['link'] = videoUrl;
            }
            break;

          case 'Bing Video':
            var results = jsonResponse['value'] != null
                ? jsonResponse['value'] as List<dynamic>
                : [];

            for (var result in results) {
              items.add({
                "title": result['name'],
                "link": result['hostPageUrl'],
                "description": result['description'],
                "date": result['datePublished'],
                "viewCount": result['viewCount'],
              });
            }
            break;
          case 'Vimeo':
            items = jsonResponse['data'] != null
                ? jsonResponse['data'] as List<dynamic>
                : [];
            for (var item in items) {
              item['title'] = item['name'];
              item['description'] = item['description'];
              item['date'] = item['created_time'];
              item['link'] = item['link'];
            }
            break;
          case 'Twitter':
            // items = jsonResponse['items'] != null
            //     ? jsonResponse['items'] as List<dynamic>
            //     : [];

            var results = jsonResponse['items'] != null
                ? jsonResponse['items'] as List<dynamic>
                : [];

            for (var result in results) {
              items.add({"title": result['title'], "link": result['link']});
            }
            break;
          case 'Facebook':
            // items = jsonResponse['items'] != null
            //     ? jsonResponse['items'] as List<dynamic>
            //     : [];
            var results = jsonResponse['items'] != null
                ? jsonResponse['items'] as List<dynamic>
                : [];

            for (var result in results) {
              items.add({"title": result['title'], "link": result['link']});
            }
            break;
          case 'Instagram':
            // items = jsonResponse['items'] != null
            //     ? jsonResponse['items'] as List<dynamic>
            //     : [];
            var results = jsonResponse['items'] != null
                ? jsonResponse['items'] as List<dynamic>
                : [];

            for (var result in results) {
              items.add({"title": result['title'], "link": result['link']});
            }
            break;
          case 'LinkedIn':
            // items = jsonResponse['items'] != null
            //     ? jsonResponse['items'] as List<dynamic>
            //     : [];
            var results = jsonResponse['items'] != null
                ? jsonResponse['items'] as List<dynamic>
                : [];

            for (var result in results) {
              items.add({"title": result['title'], "link": result['link']});
            }
            break;
        }

        // var items = jsonResponse['items'] != null
        //     ? jsonResponse['items'] as List<dynamic>
        //     : [];
        // log("items: ${items}");

        // if (items.isEmpty) {
        //   // setState(() {
        //   //   _gg = true;
        //   // });
        //   log("no results found | _currentSearchPlatform: $_currentSearchPlatform | _prevSearchPlatform: $_prevSearchPlatform");

        //   // ignore: use_build_context_synchronously
        //   await showDialog(
        //       context: context,
        //       builder: (BuildContext context) {
        //         return AlertDialog(
        //           title: const Text("No results found"),
        //           content: const Text("Please try to change the search query"),
        //           actions: [
        //             TextButton(
        //               child: const Text("OK"),
        //               onPressed: () {
        //                 Navigator.of(context).pop();
        //               },
        //             )
        //           ],
        //         );
        //       });

        //   setState(() {
        //     _searchHistory.remove(_searchText);
        //     _searchText = _prevSearchText;
        //   });

        //   _changeSearchPlatform(_prevSearchPlatform);
        //   return null;
        // } else {
        setState(() {
          _prevSearchText = _searchText;
          _prevSearchPlatform = _currentSearchPlatform;
        });
        // }

        return items;
      } else {
        log('Request failed with status: ${response.statusCode}.');

        // ignore: use_build_context_synchronously
        await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Request Failed"),
                content: Text("Status Code: ${response.statusCode}."),
                actions: [
                  TextButton(
                    child: const Text("OK"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  )
                ],
              );
            });
        return null;
      }
    } else {
      log("GG");
    }

    return null;
  }

  _updateLastViewedPlatform(keyword, platform) async {
    if (URLs[keyword] == null) {
      URLs[keyword] = {"lastViewedPlatform": platform};
    } else {
      URLs[keyword]["lastViewedPlatform"] = platform;
    }
  }

  _resetLastViewedIndex(keyword, platform, [resetAll = false]) async {
    if (URLs[keyword][platform] == null || resetAll) {
      URLs[keyword][platform] = {"lastViewedIndex": 0, "list": []};
    } else {
      URLs[keyword][platform]["lastViewedIndex"] = 0;
    }
  }

  _updateURLs(mode, keyword, platform, list, [imageSearch = false]) async {
    log("updating...");

    keyword = keyword.toString();
    platform = platform.toString();
    // log("searchText: $_searchText | keyword: $keyword | list length: ${list}");

    if (imageSearch) {
      log("from image search");
      setState(() {
        _searchText = keyword;
        _currentSearchPlatform = platform;
      });
    }

    if (list == null) {
      return;
    }

    setState(() {
      _marqueeKey = UniqueKey();

      if (list.length > 0) {
        _updateLastViewedPlatform(keyword, platform);
      }
    });

    switch (mode) {
      // case "append":
      //   {
      //     int length = URLs[keyword][platform].length;

      //     setState(() {
      //       if (_currentURLIndex < length - 1) {
      //         URLs[keyword][platform].removeRange(_currentURLIndex + 1, length);
      //       }

      //       for (var item in list) {
      //         log("added");
      //         URLs[keyword][platform]
      //             .add({'title': item['title'], 'link': item['link']});
      //       }

      //       // URLs[keyword][platform]
      //       //     .add({'title': 'manual', 'link': 'https://www.google.com'});
      //     });
      //     break;
      //   }
      case "replace":
        {
          // only set the URL list if there are results
          if (list.length > 0) {
            log("platform replace: $platform");
            setState(() {
              // URLs[keyword][platform] = {"lastViewedIndex": 0, "list": []};
              _resetLastViewedIndex(keyword, platform, true);

              for (var item in list) {
                URLs[keyword][platform]["list"]
                    .add({'title': item['title'], 'link': item['link']});
              }

              // log("URLs[keyword] ${URLs[keyword]}");

              // URLs[keyword][platform]
              //     .add({'title': 'manual', 'link': 'https://www.google.com'});
            });
          }
          break;
        }
      case "extend":
        {
          // only set the URL list if there are results
          if (list.length > 0) {
            setState(() {
              // URLs[keyword][platform] = [];

              for (var item in list) {
                URLs[keyword][platform]["list"]
                    .add({'title': item['title'], 'link': item['link']});
              }

              // URLs[keyword][platform]
              //     .add({'title': 'manual', 'link': 'https://www.google.com'});
            });
          }
          break;
        }
    }
  }

  _updateCurrentURLs() async {
    setState(() {
      if (URLs[_searchText] == null) {
        log("no results");
        _searchResult = {};
      } else {
        _searchResult = URLs[_searchText];
        log("_searchResult $_searchResult");

        log("_currentSearchPlatform $_currentSearchPlatform");
        if (URLs[_searchText][_currentSearchPlatform] == null) {
          URLs[_searchText][_currentSearchPlatform] = {};
        } else {
          _currentURLs = URLs[_searchText][_currentSearchPlatform]["list"];
        }
      }
    });

    // setState(() {
    //   // _pageKey = GlobalKey();

    //   if (_fabColor == Colors.amber[300]!) {
    //     _fabColor = Colors.blue[100]!;
    //     _appBarColor = _defaultAppBarColor;
    //     log("white");
    //   } else {
    //     _fabColor = Colors.amber[300]!;
    //     _appBarColor = Colors.amber[300]!;
    //   }
    // });
  }

  _moveSwiper([isImageSearch = false]) async {
    setState(() {
      if (_isSearching) {
        log("popping...");
        Navigator.of(context).pop();
        // _marqueeKey = UniqueKey();
        _isSearching = false;
      }

      log("_currentWebViewController?.runtimeType ${_currentWebViewController?.runtimeType}");

      _currentURLIndex = 0;

      // new key to refresh the preloaded webview
      // _pageKey = GlobalKey();
      _activatedSearchPlatforms[_currentSearchPlatform] = GlobalKey();
      log("_activatedSearchPlatforms $_activatedSearchPlatforms");

      _appBarColor = _defaultAppBarColor;
      // log("_appBarColor $_appBarColor");
    });

    if (isImageSearch && _activatedSearchPlatforms.length > 1) {
      await _preloadPlatformController.animateToPage(
          // find the index of the current platform
          _activatedSearchPlatforms.keys
              .toList()
              .indexOf(_currentSearchPlatform),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn);
    }
  }

  _handleSearch(value, [selectedPlatform]) async {
    bool newSearch = false;

    log("selectedPlatform $selectedPlatform");
    if (selectedPlatform != null) {
      setState(() {
        _currentSearchPlatform = selectedPlatform;
      });
    }

    setState(() {
      _searchText = value.toString();
      if (URLs[_searchText] == null && _activatedSearchPlatforms.isEmpty) {
        _isFetching = true;
        newSearch = true;
      }

      // _appBarColor = _defaultAppBarColor;
      // _fabColor = Colors.blue[100]!;
      _appBarColor = _searchingAppBarColor;
      _searchHistory.addAll({value.toString(): false});
    });

    if (kDebugMode) {
      log("URLs[_searchText] ${URLs[_searchText]}");
    }

    _normalSearch(newSearch, false);

    setState(() {
      _appBarColor = _defaultAppBarColor;
    });

    log("_appBarColor $_appBarColor");

    if (_isTutorial) {
      log("tutorialing after");
      _showTutorialAfter();
    }
  }

  void _updateSearchText(searchText) {
    setState(() {
      _searchText = searchText;
      // _currentSearchPlatform = "Google";
    });
  }

  void _setImageSearch(bool state) {
    setState(() {
      _isImageSearch = state;
    });
  }

  void _deleteSearchRecord(String keyword) {
    setState(() {
      _searchRecords.remove(keyword);
    });
  }

  void _updateCurrentImage(image) {
    setState(() {
      _currentImage = image;
    });
    log("_currentImage $_currentImage");
  }

  final TextEditingController _searchFieldController = TextEditingController();

  void _pushSearchPage() async {
    // String url = "https://en.wikipedia.org/wiki/CUHK";
    // // String url =
    // //     "https://en.m.wikipedia.org/wiki/Chinese_University_of_Hong_Kong";
    // var response = await http.get(Uri.parse(url));
    // log("hash0: ${response.statusCode}");
    // if (response.statusCode == 200) {
    //   // Parse the HTML content
    //   var document = parse(response.body);
    //   log("document: ${document.outerHtml}");

    //   // Inspect the meta-refresh tag
    //   var metaRefreshTag = document.querySelector('meta[http-equiv="Refresh"]');
    //   log("metaRefreshTag: $metaRefreshTag");
    //   if (metaRefreshTag != null) {
    //     // Extract the "content" attribute value, which contains the redirect URL
    //     var content = metaRefreshTag.attributes['content'];

    //     // Extract the URL from the "content" attribute value
    //     var redirectUrl = content?.split(';')[1].trim().substring(4);

    //     // The web page is being client-side redirected
    //     print('Redirect URL: $redirectUrl');
    //   }

    //   //   // Convert the content to string
    //   String content = utf8.decode(response.bodyBytes);
    //   log("hash1: $content");

    //   // Generate an MD5 hash of the content
    //   var hash = md5.convert(utf8.encode(content));
    //   log("hash2: $hash");
    //   //e37dba5df01a95de7bfdf4d9a1e83d68
    //   //7bcdf7f1d970b3146aa54bef2aaff7d4

    //   // Return the hexadecimal representation of the hash
    //   // return hash.toString();
    // } else {
    //   throw Exception(
    //       'Failed to fetch web page content: ${response.statusCode}');
    // }

    setState(() {
      _isSearching = true;
    });

    _searchFieldController.text = _searchText;
    // log("_searchRecords: $_searchRecords");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return SearchPage(
              realSearchText: _searchText,
              handleSearch: _handleSearch,
              performSearch: _performSearch,
              updateURLs: _updateURLs,
              updateCurrentURLs: _updateCurrentURLs,
              moveSwiper: _moveSwiper,
              updateSearchText: _updateSearchText,
              searchPlatformList: SearchPlatformList,
              currentPlatform: _currentSearchPlatform,
              setImageSearch: _setImageSearch,
              searchRecords: _searchRecords,
              updateSearchRecord: _updateSearchRecord,
              platformIconBuilder: _platformIconBuilder,
              imageSearchGoogle: _imageSearchGoogle,
              imageSearchBing: _imageSearchBing,
              mergeResults: _mergeResults,
              updateCurrentImage: _updateCurrentImage,
              mergeSearch: _mergeSearch,
              isTutorial: _isTutorial);
        },
      ),
    );
  }

  _getDatabase() async {
    final isar = await Isar.getInstance("url") ??
        await Isar.open([URLSchema], name: "url");

    return isar;
  }

  _getHistory() async {
    if (kDebugMode) {
      log("getting history");
    }

    final isar = await Isar.getInstance("url") ??
        await Isar.open([URLSchema], name: "url");

    // check if the record exist
    final urlRecord = await isar.uRLs.where().findAll();

    return urlRecord;
  }

  void _deleteHistory() async {
    log("deleting history");

    final isar = await Isar.getInstance("url") ??
        await Isar.open([URLSchema], name: "url");

    await isar.writeTxn(() async {
      isar.clear();
    });
  }

  void _updateSelectedPageIndex(index) {
    setState(() {
      _selectedPageIndex = 0;
    });
  }

  void _updateSearchAlgorithm(algorithm) {
    setState(() {
      _searchAlgorithm = algorithm;
    });
  }

  void _updateMergeAlgorithm(algorithm) {
    setState(() {
      _mergeAlgorithm = algorithm;
    });
  }

  void _updatePreloading(preloadNumber) {
    setState(() {
      _preloadNumber = preloadNumber;
    });
  }

  void _updateAutoSwitchPlatform(value) {
    setState(() {
      _autoSwitchPlatform = value;
    });
  }

  void _pushSettingsPage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // ignore: use_build_context_synchronously
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return SettingsPage(
            updateSelectedPageIndex: _updateSelectedPageIndex,
            updateSearchAlgorithm: _updateSearchAlgorithm,
            searchAlgorithm: _searchAlgorithm,
            updateMergeAlgorithm: _updateMergeAlgorithm,
            mergeAlgorithm: _mergeAlgorithm,
            SearchAlgorithmList: SearchAlgorithmList,
            MergeAlgorithmList: MergeAlgorithmList,
            updatePreloading: _updatePreloading,
            preloadNumber: _preloadNumber,
            updateAutoSwitchPlatform: _updateAutoSwitchPlatform,
            autoSwitchPlatform: _autoSwitchPlatform,
            prefs: prefs,
          );
        },
      ),
    );
  }

  void _pushHistoryPage() async {
    final data = await _getHistory();
    final isar = await _getDatabase();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return HistoriesPage(
            selectedPageIndex: _selectedPageIndex,
            urlRecords: data,
            isar: isar,
          );
        },
      ),
    );
  }

  void _onItemTapped(int index) {
    log("index $index");
    setState(() {
      _selectedPageIndex = index;
      // if (_selectedPageIndex == 1) {
      //   _pushHistoryPage();
      // } else if (_selectedPageIndex == 3) {
      //   _pushSettingsPage();
      // }
    });

    // _getHistory();
  }

  // final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers = {
  //   Factory(() => VerticalDragGestureRecognizer()),
  //   Factory(() => HorizontalDragGestureRecognizer()),
  //   Factory(() => LongPressGestureRecognizer()),
  // };

  Future<bool> _onWillPop(BuildContext context) async {
    log("type ${_currentWebViewController?.runtimeType}");
    if (_currentWebViewController?.runtimeType != null) {
      if (await _currentWebViewController!.canGoBack()) {
        log("onwill goback");
        _currentWebViewController!.goBack();
        return Future.value(false);
      } else {
        log("_exit will not go back");
        return Future.value(true);
      }
    }
    return Future.value(false);
  }

  // JavascriptChannel _toasterJavascriptChannel(BuildContext context) {
  //   return JavascriptChannel(
  //     name: 'Print',
  //     onMessageReceived: (JavascriptMessage message) {
  //       log("Print ${message.message}");
  //       // setState(() {
  //       //   _webpageContent = message.message;
  //       // });
  //     },
  //   );
  // }

  // JavascriptChannel _getDrillTextChannel(BuildContext context) {
  //   return JavascriptChannel(
  //     name: 'Drill',
  //     onMessageReceived: (JavascriptMessage message) {
  //       log("DrillText ${message.message}");
  //       setState(() {
  //         _webpageContent = message.message;
  //       });
  //     },
  //   );
  // }

  _performDrill([selectedText = null]) async {
    String currentSearchText = _searchText;
    String keyword = selectedText ?? await _getSearchQuery();
    log("drilling... 1| $keyword");

    if (keyword == "") {
      await _currentWebViewController!.takeScreenshot().then((value) async {
        log("screenshot taken");
        // save the screeenshot
        final tempDir = await getTemporaryDirectory();
        String path = tempDir.path + "/image.png";
        File file = await File(path).create();
        // file.writeAsBytesSync(value!);

        // final picker = ImagePicker();
        // final XFile? image = await picker.pickImage(
        //   source: ImageSource.gallery,
        //   maxHeight: 1000,
        //   maxWidth: 1000,
        //   //imageQuality: 80,
        // );
        // XFile? image =
        //     (await _currentWebViewController!.takeScreenshot()) as XFile?;
        // log("image $image");
        var image = XFile.fromData(value!);
        log("path $path");
        image.saveTo(path);
        log("image $image");
        // EasyLoading.show(status: "Searching...");
        // Map results = await _imageSearchBing(image, path);

        // text detection
        // var detectedText =
        //     await _imageSearchGoogle(image, path, "text_detection");
        // log("detectedText: $detectedText");

        // await _performImageSearch(image, path);

        EasyLoading.show(
          // status: 'Perform Image Search',
          status: "Performing OCR",
        );

        // try OCR first
        var resultsOCR =
            await _imageSearchGoogle(image, path, "text_detection");
        log("OCR:$resultsOCR");
        // log("OCR toString: :${resultsOCR.toString()}");

        log("image search 4");

        // var keywords = await _extractKeywords(resultsOCR.join(' ').toString());
        keyword = resultsOCR;
        log("OCR extracted: $keyword");

        // Map results = await _imageSearchGoogle(image, path);
        EasyLoading.dismiss();
        // log("results google $results");

        // remove the screenshot
        // await file.delete();
        // return;
      });
    }

    keyword = keyword.trim();
    log("drilling... 2| $keyword");

    log("keyword length: ${keyword.split(' ').length}, ${keyword.length}");

    String selectedKeywords = "", selectedPlatform = "";
    List<String> selectedPlatformList = [];

    bool abort = false;
    // false = contain non-english character
    log("regex: ${containNonEnglish.hasMatch(keyword)}");

    // auto keywords extraction if more than 7 words, or characters (non-english)
    if (((!containNonEnglish.hasMatch(keyword) && keyword.length > 7) ||
        keyword.split(' ').length > 10)) {
      var extracted = await _extractKeywords(keyword);

      List<MultiSelectItem> keywords = [];
      for (var i = 0; i < extracted.length; i++) {
        keywords.add(MultiSelectItem(extracted[i], extracted[i]));
      }

      List<MultiSelectItem> platforms = [];
      for (var i = 0; i < SearchPlatformList.length; i++) {
        platforms
            .add(MultiSelectItem(SearchPlatformList[i], SearchPlatformList[i]));
      }

      // List<S2Choice<String>> keywords = [];
      // for (var i = 0; i < extracted.length; i++) {
      //   keywords
      //       .add(S2Choice<String>(value: extracted[i], title: extracted[i]));
      // }

      // ignore: use_build_context_synchronously
      await showDialog<String>(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) => AlertDialog(
          scrollable: true,
          title: const Text('Are you interested in these keywords?'),
          content: Column(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: MultiSelectChipField(
                  title: const Text(
                    "Suggested Keywords",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  items: keywords,
                  showHeader: true,
                  scroll: false,
                  onTap: (values) {
                    log("selected: $values");
                    selectedKeywords = values.join(" ").trim();
                    log("updated $selectedKeywords");
                  },
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: MultiSelectChipField(
                  title: const Text(
                    "Available Platforms",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  items: platforms,
                  showHeader: true,
                  scroll: false,
                  validator: (value) {
                    log("validating $value");
                  },
                  onTap: (values) {
                    log("selected: $values");
                    selectedPlatform = values.isNotEmpty
                        ? values[values.length - 1].toString()
                        : "";
                    log("updated $selectedPlatform");
                  },
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context, 'Cancel');
                abort = true;
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, 'ALL');
              },
              child: const Text('Drill ALL'),
            ),
            TextButton(
              onPressed: () {
                log("final selected keywords: $selectedKeywords");
                if (selectedKeywords == "") {
                  return;
                }
                Navigator.pop(context, 'OK');
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    log("keyword: ${keyword} | selectedKeywords: ${selectedKeywords} | selectedPlatform: ${selectedPlatform}");

    if (abort) return;
    // return;

    setState(() {
      _appBarColor = _searchingAppBarColor;
      _searchText = selectedKeywords == "" ? keyword : selectedKeywords;
      _currentSearchPlatform =
          selectedPlatform == "" ? _currentSearchPlatform : selectedPlatform;

      if (_searchHistory[_searchText.toString()] == false) {
        _searchHistory.update(_searchText.toString(), (value) => true);
      }

      // ! FIX
      // _searchHistory.addAll({keyword.toString(): _searchText.toString()});
      _searchHistory
          .addAll({_searchText.toString(): currentSearchText.toString()});

      // if (_fabColor == Colors.amber[300]!) {
      //   _fabColor = Colors.blue[100]!;
      //   _appBarColor = _defaultAppBarColor;
      // } else {
      //   _fabColor = Colors.amber[300]!;
      //   _appBarColor = Colors.amber[300]!;
      // }
    });

    log("_searchHistory ${_searchHistory.toString()}");

    if (!_activatedSearchPlatforms.containsKey(_currentSearchPlatform)) {
      setState(() {
        _activatedSearchPlatforms.addAll({_currentSearchPlatform: GlobalKey()});
        // _activatedSearchPlatformKeys.add(GlobalKey());
      });
    }

    // if (!_activatedSearchPlatforms.contains(_currentSearchPlatform)) {
    //   setState(() {
    //     _activatedSearchPlatforms.add(_currentSearchPlatform);
    //     _activatedSearchPlatformKeys.add(GlobalKey());
    //   });
    // }

    if (URLs[_searchText] == null) {
      URLs[_searchText] = {};
    }

    if (URLs[_searchText][_currentSearchPlatform] == null) {
      // do search only if it has not been done before
      // var items = await _performSearch(_searchText, _currentSearchPlatform);
      var items = await _mergeSearch(_currentSearchPlatform);
      await _updateURLs('replace', _searchText, _currentSearchPlatform, items);
    }

    await _updateCurrentURLs();

    // log(
    //     "_currentURLs[_currentURLIndex]['link'] ${_currentURLs[_currentURLIndex]['link']}");

    // log(
    //     "animate to: ${_activatedSearchPlatforms.indexOf(_currentSearchPlatform)}");
    await _preloadPlatformController.animateToPage(
        // find the index of the current platform
        _activatedSearchPlatforms.keys.toList().indexOf(_currentSearchPlatform),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn);

    await _moveSwiper();

    setState(() {
      _appBarColor = _defaultAppBarColor;
    });

    // _currentPreloadPageController.jumpToPage(0);

    // setState(() {
    //   // _pageKey = GlobalKey();

    //   if (_fabColor == Colors.amber[300]!) {
    //     _fabColor = Colors.blue[100]!;
    //     _appBarColor = _defaultAppBarColor;
    //   } else {
    //     _fabColor = Colors.amber[300]!;
    //     _appBarColor = Colors.amber[300]!;
    //   }
    // });
  }

  // {
  //   "search query 1": {}
  // }

  // ! FIX
  _recordActivity() async {
    log("begin record...");

    // if (!_redirectStopwatch.isRunning) {
    //   _redirectStopwatch.start();
    //   log("1 onPageStarted");
    // }

    // first stop the activityStopwatch if it is running
    if (activityStopwatch.isRunning) {
      activityStopwatch.stop();
    }

    // get the database
    final isar =
        Isar.getInstance("url") ?? await Isar.open([URLSchema], name: "url");
    log("isar: $isar");

    // check if the record exist
    final urlRecord = await isar.uRLs
        .filter()
        .urlEqualTo(_currentURLs[_currentURLIndex]["title"])
        .findAll();
    log("urlRecord: ${urlRecord}");

    // log(
    //     "activityStopwatch stopped: ${activityStopwatch.elapsed}");

    // final Duration dur = parseDuration(
    //     '2w 5d 23h 59m 59s 999ms 999us');
    // log("dur $dur");

    // record exists
    if (urlRecord.isNotEmpty) {
      await isar.writeTxn(() async {
        final uRL = await isar.uRLs.get(urlRecord[0].id);

        uRL!.duration = activityStopwatch.elapsed.toString();
        uRL!.lastViewed = DateTime.now();
        uRL!.viewCount = uRL!.viewCount++;

        await isar.uRLs.put(uRL);
      });
    }
    // new record
    else {
      final newURL = URL()
        ..url = _previousURL
        ..title = _currentURLs[_currentURLIndex]["title"]
        ..duration = activityStopwatch.elapsed.toString()
        ..viewCount = 1
        ..lastViewed = DateTime.now();
      await isar.writeTxn(() async {
        await isar.uRLs.put(newURL);
      });
    }

    // reset the activityStopwatch
    activityStopwatch.reset();

    // update current url and start activityStopwatch
    setState(() {
      _previousURL = _currentURLs[_currentURLIndex]["link"];
      if (!activityStopwatch.isRunning) {
        log("start activityStopwatch");
        activityStopwatch.start();
      }
    });

////////////////////////////////////
    // final urlRecord = await isar.uRLs.filter().urlEqualTo(url).findAll();

    // if (urlRecord.isNotEmpty) {
    //   await isar.writeTxn(() async {
    //     final uRL = await isar.uRLs.get(urlRecord[0].id);

    //     uRL?.viewCount++;
    //     uRL?.lastViewed = DateTime.now();
    //     uRL?.title = await _controller[index].getTitle();

    //     await isar.uRLs.put(uRL!);
    //   });
    // }
    // // new record
    // else {
    //   final newURL = URL()
    //     ..url = url
    //     ..title = await _controller[index].getTitle();
    //   await isar.writeTxn(() async {
    //     await isar.uRLs.put(newURL);
    //   });
    // }

    // if (_redirectStopwatch.elapsedMilliseconds < 100) {
    //   log("1 redirect");

    //   setState(() {
    //     _redirecting = true;
    //   });
    // } else {
    //   log("2 redirect");

    //   _redirectStopwatch.stop();
    //   _redirectStopwatch.reset();
    //   setState(() {
    //     _redirecting = false;
    //   });
    // }

    // log("swiping $_swipe");

    // setState(() {
    //   _previousURL = url;
    //   if (!activityStopwatch.isRunning) {
    //     log("start activityStopwatch");
    //     activityStopwatch.start();
    //   }
    //   _loadingPercentage = 100;
    // });

    // setState(() {
    //   _swipe = false;
    // });
  }

  _showSelectMenu(BuildContext context) {
    // setState(() {
    //   _menuShown = true;
    // });
    log("show menu");
    // if (!_menuShown) {
    return showModalBottomSheet(
      isDismissible: false,
      barrierColor: Colors.transparent,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(0),
        ),
      ),
      context: context,
      builder: (context) {
        return SizedBox(
          height: Platform.isIOS
              ? (_loadingPercentage < 100 ? 65 : 60)
              : (_loadingPercentage < 100 ? 55 : 50),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () async {
                      log("close menu");

                      Navigator.pop(context);

                      setState(() {
                        _menuShown = false;
                      });
                    },
                    icon: const FaIcon(FontAwesomeIcons.xmark, size: 20),
                  ),
                  IconButton(
                    onPressed: () async {
                      log("select all");

                      Navigator.pop(context);

                      setState(() {
                        _menuShown = false;
                      });
                    },
                    icon: const FaIcon(FontAwesomeIcons.borderAll, size: 20),
                  ),
                  IconButton(
                    onPressed: () async {
                      log("copy");
                      String? selectedText =
                          await _currentWebViewController?.getSelectedText();
                      await Clipboard.setData(
                          ClipboardData(text: selectedText));
                      log("selectedText: $selectedText");

                      Navigator.pop(context);

                      setState(() {
                        _menuShown = false;
                      });

                      final snackBar = SnackBar(
                        content: Text("Copied ${selectedText}"),
                        duration: const Duration(seconds: 3),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    },
                    icon: const FaIcon(FontAwesomeIcons.copy, size: 20),
                  ),
                  IconButton(
                    onPressed: () async {
                      log("drill");
                      String? selectedText =
                          await _currentWebViewController?.getSelectedText();
                      log("selectedText: $selectedText");

                      Navigator.pop(context);

                      setState(() {
                        _menuShown = false;
                      });

                      final snackBar = SnackBar(
                        content: Text("Drilling ${selectedText}"),
                        duration: const Duration(seconds: 3),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);

                      _performDrill(selectedText);
                    },
                    icon: const Icon(MyFlutterApp.drill, size: 20),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    // }
  }

  _handlePageRefresh(position) async {
    // log("position: $position | _currentURLIndex: ${_currentURLIndex}");
    // // if (position == _currentURLIndex) {
    // log("ending... | ${await _refreshController!.isRefreshing()}");
    // await _refreshController!.endRefreshing();
    // log("ended... | ${await _refreshController!.isRefreshing()}");
    // }
  }

  Widget _buildWebView(BuildContext context, var data, int position) {
    // log("data $data");
    log("building... | $position");
    // log("building... | ${data}");

    if (data == "") {
      return SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Text("End of Results"),
      );
    } else {
      bool bingo = false;
      // if (_currentURLs[_currentURLIndex]['link'] == data['link']) {
      if (position == _currentURLIndex) {
        bingo = true;
        // if (position == 0) _next = _currentURLs[_currentURLIndex + 1]['link'];
        log("bingo $bingo | $position");
        // if (!activityStopwatch.isRunning) {
        //   log("start activityStopwatch");
        //   activityStopwatch.start();
        // }
        // _recordActivity();
      }

      // log("building... | bingo: ${bingo} | data: ${data}");
      // return Text("123");
      return SizedBox(
        width: MediaQuery.of(context).size.width,

        // child: Text("test${index}"),
        child:
            //  MouseRegion(
            //   cursor: SystemMouseCursors.click,
            //   onEnter: (event) {
            //     log("onEnter");
            //   },
            //   onExit: (event) {
            //     log("onExit");
            //   },
            //   onHover: (event) {
            //     log("onHover");
            //   },
            //   child:
            InAppWebView(
          // pullToRefreshController: _refreshController,
          gestureRecognizers: {
            Factory<LongPressGestureRecognizer>(
                () => LongPressGestureRecognizer()),
          },
          initialUrlRequest: URLRequest(url: WebUri(data['link'])),
          onWebViewCreated: (controller) {
            controller.addJavaScriptHandler(
                handlerName: 'getDrillText',
                callback: (args) {
                  log("DrillText ${args[0]}");
                  setState(() {
                    _webpageContent = args[0];
                  });
                });
            if (bingo) {
              _currentWebViewController = controller;
            }
            _webViewControllers.addAll({position: controller});
          },
          onLoadStart: (controller, url) {
            if (bingo) {
              setState(() {
                _loadingPercentage = 0;
                _currentWebViewTitle = "Loading...";
              });
            }
          },
          onLoadStop: (controller, url) async {
            if (position == _currentURLIndex) {
              // String title = await _currentWebViewController.getTitle();
              // log("title: $title | data['title']: ${data['title']}");
              setState(() {
                _loadingPercentage = 100;
                _currentWebViewTitle = data["title"];
                // _currentWebViewTitle = title;
              });
              // _refreshController?.endRefreshing();
            }
            // _handlePageRefresh(position);
          },
          onReceivedError: (controller, request, error) {},
          onProgressChanged: (controller, progress) {
            if (bingo) {
              setState(() {
                _loadingPercentage = progress;
              });
            }
          },
          onZoomScaleChanged: (controller, oldScale, newScale) {
            log("zoomScale: $oldScale, $newScale");
          },
          contextMenu: ContextMenu(
            // settings: ContextMenuSettings(
            //   hideDefaultSystemContextMenuItems: true,
            // ),
            onCreateContextMenu: (hitTestResult) async {
              log("hitTestResult");
              if (!_menuShown) {
                log("show menu");
                _showSelectMenu(context);
                setState(() {
                  _menuShown = true;
                });
              } else {
                log("menu already shown");
              }
            },
            onContextMenuActionItemClicked: (contextMenuItemClicked) => {
              log("contextMenuItemClicked: ${contextMenuItemClicked.id}"),
            },
            onHideContextMenu: () {
              log("onHideContextMenu");
              // setState(() {
              //   _menuShown = false;
              // });
              // final snackBar = SnackBar(
              //   content: Text("onHideContextMenu"),
              //   duration: const Duration(seconds: 3),
              // );
              // ScaffoldMessenger.of(context).showSnackBar(snackBar);
            },
            menuItems: [
              ContextMenuItem(
                id: 1,
                title: "Drill",
                action: () async {
                  String selectedText =
                      await _currentWebViewController?.getSelectedText() ?? "";
                  log("selectedText: $selectedText");

                  final snackBar = SnackBar(
                    content: Text("Drilling ${selectedText}"),
                    duration: const Duration(seconds: 3),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);

                  _performDrill(selectedText);
                },
              )
            ],
          ),
        ),
        //     WebView(
        //   gestureRecognizers: Set()
        //     ..add(Factory<VerticalDragGestureRecognizer>(
        //       () => VerticalDragGestureRecognizer(),
        //     ))
        //     ..add(Factory<HorizontalDragGestureRecognizer>(
        //       () => HorizontalDragGestureRecognizer(),
        //     ))
        //     ..add(
        //       (Factory<LongPressGestureRecognizer>(
        //         () => LongPressGestureRecognizer(),
        //       )),
        //     ),
        //   // ),
        //   javascriptMode: JavascriptMode.unrestricted,
        //   javascriptChannels: <JavascriptChannel>{
        //     _toasterJavascriptChannel(context),
        //     _getDrillTextChannel(context),
        //   },
        //   initialUrl: data['link'],
        //   onWebViewCreated: (webViewController) async {
        //     // for initial load only
        //     if (bingo) {
        //       // setState(() {
        //       _currentWebViewController = webViewController;
        //       // });

        //       log(
        //           "bingo ${await webViewController.currentUrl()} | ${data['link']}");
        //     }
        //     log(
        //         "not bingo ${await webViewController.currentUrl()} | ${data['link']}");
        //     _webViewControllers.addAll({position: webViewController});
        //     log("webview controllers ${_webViewControllers}");
        //   },
        //   onPageStarted: (url) async {
        //     log("1 onPageStarted");

        //     /*
        //         if (!_redirectStopwatch.isRunning) {
        //           _redirectStopwatch.start();
        //           log("1 onPageStarted");
        //         }

        //         final isar = Isar.getInstance("url") ??
        //             await Isar.open([URLSchema], name: "url");

        //         // check if the record exist
        //         final urlRecord =
        //             await isar.uRLs.filter().urlEqualTo(_previousURL).findAll();

        //         // log("urlRecord: ${urlRecord}");
        //         // log("_previousURL: ${_previousURL}");

        //         if (activityStopwatch.isRunning && _previousURL != "") {
        //           activityStopwatch.stop();
        //           // log(
        //           //     "activityStopwatch stopped: ${activityStopwatch.elapsed}");

        //           // final Duration dur = parseDuration(
        //           //     '2w 5d 23h 59m 59s 999ms 999us');
        //           // log("dur $dur");

        //           if (urlRecord.isNotEmpty) {
        //             await isar.writeTxn(() async {
        //               final uRL = await isar.uRLs.get(urlRecord[0].id);

        //               uRL!.duration = activityStopwatch.elapsed.toString();

        //               await isar.uRLs.put(uRL);
        //             });
        //           }
        //           // new record
        //           else {
        //             final newURL = URL()
        //               ..url = _previousURL
        //               ..title = await _controller[index].getTitle()
        //               ..duration = activityStopwatch.elapsed.toString();
        //             await isar.writeTxn(() async {
        //               await isar.uRLs.put(newURL);
        //             });
        //           }

        //           activityStopwatch.reset();
        //         }
        // */
        //     if (bingo) {
        //       setState(() {
        //         _loadingPercentage = 0;
        //         _currentWebViewTitle = "Loading...";
        //       });
        //     }
        //   },
        //   onProgress: (progress) {
        //     if (bingo) {
        //       setState(() {
        //         _loadingPercentage = progress;
        //       });
        //     }
        //   },
        //   onPageFinished: (url) async {
        //     log("3 onPageFinished");

        //     /*

        //         _controller[index]
        //             .runJavascript("""window.addEventListener('click', (e) => {
        //                                     var x = e.clientX, y = e.clientY;
        //                                     var elementMouseIsOver = document.elementFromPoint(x, y);
        //                                     var content = elementMouseIsOver.innerText;
        //                                     if (content == undefined || content == null)
        //                                       Print.postMessage("");
        //                                     else
        //                                       Print.postMessage(content);
        //                                 });
        //                               """);

        //         final isar = Isar.getInstance("url") ??
        //             await Isar.open([URLSchema], name: "url");

        //         log("isar: $isar");

        //         final urlRecord =
        //             await isar.uRLs.filter().urlEqualTo(url).findAll();

        //         if (urlRecord.isNotEmpty) {
        //           await isar.writeTxn(() async {
        //             final uRL = await isar.uRLs.get(urlRecord[0].id);

        //             uRL?.viewCount++;
        //             uRL?.lastViewed = DateTime.now();
        //             uRL?.title = await _controller[index].getTitle();

        //             await isar.uRLs.put(uRL!);
        //           });
        //         }
        //         // new record
        //         else {
        //           final newURL = URL()
        //             ..url = url
        //             ..title = await _controller[index].getTitle();
        //           await isar.writeTxn(() async {
        //             await isar.uRLs.put(newURL);
        //           });
        //         }

        //         if (_redirectStopwatch.elapsedMilliseconds < 100) {
        //           log("1 redirect");

        //           setState(() {
        //             _redirecting = true;
        //           });
        //         } else {
        //           log("2 redirect");

        //           _redirectStopwatch.stop();
        //           _redirectStopwatch.reset();
        //           setState(() {
        //             _redirecting = false;
        //           });
        //         }

        //         log("swiping $_swipe");

        //         setState(() {
        //           _previousURL = url;
        //           if (!activityStopwatch.isRunning) {
        //             log("start activityStopwatch");
        //             activityStopwatch.start();
        //           }
        //           _loadingPercentage = 100;
        //         });

        //         setState(() {
        //           _swipe = false;
        //         });
        //         */

        //     if (bingo) {
        //       String title = await _currentWebViewController.getTitle();
        //       log("title: $title | data['title']: ${data['title']}");
        //       setState(() {
        //         _loadingPercentage = 100;
        //         _currentWebViewTitle = data["title"];
        //         // _currentWebViewTitle = title;
        //       });
        //     }
        // },
        // ),
      );
    }
  }

  _buildPlatform(context, platformPosition) {
    if (kDebugMode) {
      log("platformPosition: $platformPosition | ${_activatedSearchPlatforms.keys.toList().indexOf(_currentSearchPlatform)} | ${_activatedSearchPlatforms.length}");
    }
    return PreloadPageView.builder(
      physics: const NeverScrollableScrollPhysics(),
      preloadPagesCount: _preloadNumber ? 1 : 0,
      // controller: _currentPreloadPageController,
      controller: platformPosition ==
              // _activatedSearchPlatforms.indexOf(
              //     _currentSearchPlatform)
              _activatedSearchPlatforms.keys
                  .toList()
                  .indexOf(_currentSearchPlatform)
          ? _testPreloadPageController
          : null,
      // _preloadPageControllers[
      //     platformPosition],
      // key: platformPosition ==
      //         _activatedSearchPlatforms.indexOf(
      //             _currentSearchPlatform)
      //     ? _testPreloadPageKey
      //     : null,
      key: _activatedSearchPlatforms.values.toList()[platformPosition],
      // _activatedSearchPlatformKeys[
      //     platformPosition],
      itemCount: _currentURLs.length,
      // URLs[_searchText] == null ||
      //         URLs[_searchText][
      //                 _activatedSearchPlatforms[
      //                     platformPosition]] ==
      //             null
      //     ? 0
      //     : URLs[_searchText][
      //             _activatedSearchPlatforms[
      //                 platformPosition]]["list"]
      //         .length,
      itemBuilder: (BuildContext context, int urlPosition) => _buildWebView(
          context,
          // urlPosition >=
          //         URLs[_searchText][
          //                     _activatedSearchPlatforms[
          //                         platformPosition]]
          //                 ["list"]
          //             .length
          //     ? ""
          //     : URLs[_searchText][
          //             _activatedSearchPlatforms[
          //                 platformPosition]]
          //         ["list"][urlPosition]!,
          // urlPosition
          urlPosition >= _currentURLs.length ? "" : _currentURLs[urlPosition]!,
          urlPosition),
      onPageChanged: (int position) async {
        log('page changed. current: $position');

        setState(() {
          _currentURLIndex = position;
          URLs[_searchText]
                  [_activatedSearchPlatforms.keys.toList()[platformPosition]]
              ["lastViewedIndex"] = position;
          _currentWebViewTitle = _currentURLs[position]!['title'];
          _loadingPercentage = 100;
          _currentWebViewController = _webViewControllers[position];

          // log(
          //     "_webViewControllers $_webViewControllers");
        });

        // log(
        //     "URLs[_searchText][_activatedSearchPlatforms[platformPosition]] ${URLs[_searchText][_activatedSearchPlatforms[platformPosition]]}");

        // log(
        //     "controller 1 ${_currentURLs[position]!['title']} |  ${_currentURLs[position]!['link']}");
        // log(
        //     "controller 2 ${await _currentWebViewController?.getTitle()} | ${await _currentWebViewController?.getUrl()}");
        // log(
        //     "controller 3 ${await _currentWebViewController}");

        // log(
        //     "same ${await _currentWebViewController?.currentUrl() == _currentURLs[position]!['link']}");

        // fetch more results if we are almost at the end of the list
        if (position + 1 >= _currentURLs.length) {
          log("reached end of list");

          // setState(() {
          //   page++;
          //   _start = (page - 1) * 10 + 1;
          // });

          // var items = await _performSearch(_searchText, _currentSearchPlatform);
          // log("items $items");
          // // update the URLs
          // await _updateURLs(
          //     'extend', _searchText, _currentSearchPlatform, items);

          // // update the current URLs
          // await _updateCurrentURLs();
        }
      },
    );
  }

  _changeSearchPlatform([updatedPlatform = ""]) {
    int index = SearchPlatformList.indexOf(_currentSearchPlatform);
    int newIndex = (index + 1);
    if (newIndex >= SearchPlatformList.length) {
      newIndex = 0;
    }
    setState(() {
      _currentSearchPlatform = updatedPlatform == ""
          ? SearchPlatformList[newIndex]
          : updatedPlatform;
      _marqueeKey = UniqueKey();
    });
    log("new _currentSearchPlatform: $_currentSearchPlatform");
  }

  var _platformActivationTimer = null;
  // = RestartableTimer(
  //   const Duration(seconds: 3),
  //   () {
  //     log("3 seconds passed | platform switched");
  //   },
  // );

  List _mergeResults(List itemsList) {
    List results = [];
    int maxLength = 0;
    for (var items in itemsList) {
      maxLength = items.length > maxLength ? items.length : maxLength;
    }

    log("merge maxLength: $maxLength");

    int mainCounter = 0;
    while (mainCounter < maxLength) {
      for (int i = 0; i < itemsList.length; i++) {
        if (mainCounter < itemsList[i].length) {
          // log("regex slash: ${itemsList[i][mainCounter]['link'].toString()} | ${endsWithSlash.hasMatch(itemsList[i][mainCounter]['link']).toString()}");

          // remove the trailing "/"
          if (endsWithSlash.hasMatch(itemsList[i][mainCounter]['link'])) {
            itemsList[i][mainCounter]['link'] = itemsList[i][mainCounter]
                    ['link']
                .substring(0, itemsList[i][mainCounter]['link'].length - 1);
          }
          results.add(itemsList[i][mainCounter]);
        }
      }
      mainCounter++;
    }

    log("merge results: ${results.length}");

    return results;
  }

  _getWebpageHash(String link) async {
    var response = await http.get(Uri.parse(link));
    // log("hash0: ${response.statusCode}");
    if (response.statusCode == 200) {
      // Parse the HTML content
      var document = parse(response.body);
      // log("document: ${document.outerHtml}");

      // // Inspect the meta-refresh tag
      // var metaRefreshTag = document.querySelector('meta[http-equiv="Refresh"]');
      // log("metaRefreshTag: $metaRefreshTag");
      // if (metaRefreshTag != null) {
      //   // Extract the "content" attribute value, which contains the redirect URL
      //   var content = metaRefreshTag.attributes['content'];

      //   // Extract the URL from the "content" attribute value
      //   var redirectUrl = content?.split(';')[1].trim().substring(4);

      //   // The web page is being client-side redirected
      //   print('Redirect URL: $redirectUrl');
      // }

      // Convert the content to string
      String content = utf8.decode(response.bodyBytes);
      // log("hash1: $content");

      // Generate an MD5 hash of the content
      var hash = md5.convert(utf8.encode(content));
      log("hash: $hash | link: $link");
      return hash;

      // Return the hexadecimal representation of the hash
      // return hash.toString();
    } else {
      throw Exception(
          'Failed to fetch web page content: ${response.statusCode}');
    }
  }

  _mergeSearch(String type) async {
    Map platforms = {};
    switch (type) {
      case "Webpage":
        platforms = {
          "Google": {},
          "Bing": {},
          "DuckDuckGo": {},
          // "Yahoo": {},
        };
        break;
      case "Video":
        platforms = {
          "YouTube": {},
          "Bing Video": {},
          "Vimeo": {},
        };
        break;
      case "SNS":
        platforms = {
          "Twitter": {},
          "Facebook": {},
          "Instagram": {},
          "LinkedIn": {},
        };
        break;
    }

    List results = [];
    int minLength = 100000;

    for (int i = 0; i < platforms.length; i++) {
      log('smart: ${platforms.keys.elementAt(i).toString()}');
      var items =
          await _performSearch(_searchText, platforms.keys.elementAt(i));
      await _updateURLs('replace', _searchText,
          platforms.keys.elementAt(i).toString(), items);
      if (items.length < minLength) {
        minLength = items.length;
      }
      log('smart: ${platforms.keys.elementAt(i).toString()} | ${items.length} | ${items}');
      results.addAll(items);
      platforms[platforms.keys.elementAt(i).toString()] = items;
    }

    log("smart length: $minLength | results: $results");

    // no result on all platforms
    if (results.isEmpty) {
      // ignore: use_build_context_synchronously
      await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("No results found"),
              content: const Text(
                  "Please try to change the search query or platform"),
              actions: [
                TextButton(
                  child: const Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          });

      setState(() {
        _searchHistory.remove(_searchText);
        _searchText = _prevSearchText;
      });

      _changeSearchPlatform(_prevSearchPlatform);
    }

    // log("platforms.values.toList(): ${platforms.values.toList()}");
    // ! PROBLEM(?): results are merged alphabetically (platform name), not in sequence as declared
    // merge the results (ABAB)
    var mergedResults = _mergeResults(platforms.values.toList());

    // Map webpageHashes = {};

    // log("webpageHashes: $webpageHashes");
    // log("mergedResults: $mergedResults");

    log("mergedResults.toList(): ${mergedResults.toList()}");

    // TODO: algorithm to sort
    // rank + frequency
    switch (_mergeAlgorithm) {
      case "ABAB":
        return mergedResults;
      case "Frequency":
        // merge identical (similar?) results
        Map webpageFrequency = {};
        for (int i = 0; i < mergedResults.length; i++) {
          // var hash = await _getWebpageHash(mergedResults[i]["link"]);
          // log("smart hash: $hash");
          // if (webpageHashes[hash] == null) {
          //   webpageHashes[hash] = 1;
          // } else {
          //   webpageHashes[hash] += 1;
          // }
          if (webpageFrequency[mergedResults[i]["link"]] == null) {
            webpageFrequency[mergedResults[i]["link"]] = 1;
          } else {
            webpageFrequency[mergedResults[i]["link"]] += 1;
          }
        }

        List<MapEntry> entries = webpageFrequency.entries.toList();
        entries.sort(
            (a, b) => b.value.compareTo(a.value)); // sort in ascending order
        Map sortedWebpageFrequency = Map.fromEntries(entries);

        log("webpageFrequency: $webpageFrequency");
        log("sortedWebpageFrequency: $sortedWebpageFrequency");

        List finalSortedList = [];
        List links = sortedWebpageFrequency.keys.toList();

        for (int i = 0; i < sortedWebpageFrequency.length; i++) {
          // log("keys[i]: ${links[i]}");

          finalSortedList.add({
            "title": mergedResults
                .firstWhere((element) => element["link"] == links[i])["title"],
            "link": links[i]
          });
        }

        log("finalSortedList: $finalSortedList");

        return finalSortedList;
      case "Original Rank":
        return mergedResults;
    }

    // return mergedResults;

    // List test = [];
    // int i = 0;
    // for (i = 0; i < minLength; i++) {
    //   test.add(platforms["Google"][i]);
    //   test.add(platforms["Bing"][i]);
    // }

    // if (i < platforms["Google"].length) {
    //   log("smart Google longer | $i | ${platforms["Google"].length}");
    //   for (int j = i; j < platforms["Google"].length; j++) {
    //     log("smart: ${platforms["Google"][j]}");
    //     test.add(platforms["Google"][j]);
    //   }
    // }
    // if (i < platforms["Bing"].length) {
    //   log("smart Bing longer | $i | ${platforms["Bing"].length}");
    //   for (int j = i; j < platforms["Bing"].length; j++) {
    //     test.add(platforms["Bing"][j]);
    //   }
    // }

    // sort the results according to frequency
    // for (var result in results) {
    //   if (!test.contains(result["link"])) {
    //     test.add({result["link"]: 1});
    //   } else {
    //     test[result["link"]]++;
    //   }
    // }

    // log("test: $test");

    // return test;
  }

  _normalSearch([newSearch = false, refresh = false]) async {
    log("newSearch: $newSearch @${_currentSearchPlatform}");

    if (!_activatedSearchPlatforms.containsKey(_currentSearchPlatform)) {
      setState(() {
        _activatedSearchPlatforms.addAll({_currentSearchPlatform: GlobalKey()});
      });
    }

    // do search only if it has not been done before or user force refresh
    if (URLs[_searchText] == null ||
        URLs[_searchText][_currentSearchPlatform] == null ||
        refresh) {
      log("null OR refresh");
      var items;
      // merge search (search on all platforms)
      // if (_currentSearchPlatform == "Text") {
      items = await _mergeSearch(_currentSearchPlatform);
      // }

      // only on one platform
      // else {
      //   items = await _performSearch(_searchText, _currentSearchPlatform);
      //   log("_currentSearchPlatform 2 $_currentSearchPlatform");
      // }
      await _updateURLs('replace', _searchText, _currentSearchPlatform, items);
    } else {
      log("not null");
      _updateLastViewedPlatform(_searchText, _currentSearchPlatform);
      _resetLastViewedIndex(_searchText, _currentSearchPlatform);
    }

    await _updateCurrentURLs();

    setState(() {
      _isFetching = false;
    });

    await _moveSwiper();

    // log(
    //     "animate to: ${_activatedSearchPlatforms.indexOf(_currentSearchPlatform)}");
    log("_activatedSearchPlatforms: $_activatedSearchPlatforms");
    if (!newSearch && _activatedSearchPlatforms.length > 1) {
      log("animate to: ${_activatedSearchPlatforms.keys.toList().indexOf(_currentSearchPlatform)}");
      await _preloadPlatformController.animateToPage(
          // _activatedSearchPlatforms
          //     .indexOf(_currentSearchPlatform),
          _activatedSearchPlatforms.keys
              .toList()
              .indexOf(_currentSearchPlatform),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn);
    }
  }

  _buildSearchHistoryList() {
    var result = [];

    backTo(String key, String lastViewedPlatform, int lastViewedIndex) async {
      if (kDebugMode) {
        log("lastPlatform: $lastViewedPlatform | lastViewedIndex: $lastViewedIndex");
      }

      // current result
      if (lastViewedPlatform == _currentSearchPlatform &&
          lastViewedIndex == _currentURLIndex &&
          key == _searchText) {
        return;
      }

      setState(() {
        _searchText = key.toString();
        _currentSearchPlatform = lastViewedPlatform;
        // _activatedSearchPlatforms[lastViewedPlatform] = GlobalKey();
        // _activatedSearchPlatforms.
      });

      _updateCurrentURLs();

      // await _preloadPlatformController.animateToPage(
      //     // _activatedSearchPlatforms.indexOf(lastViewedPlatform),
      //     _activatedSearchPlatforms.keys.toList().indexOf(lastViewedPlatform),
      //     duration: const Duration(milliseconds: 300),
      //     curve: Curves.easeIn);
      _preloadPlatformController.jumpToPage(
          _activatedSearchPlatforms.keys.toList().indexOf(lastViewedPlatform));

      log("before ${lastViewedPlatform} | ${_activatedSearchPlatforms[lastViewedPlatform]}");
      setState(() {
        // _currentPreloadPageKey = GlobalKey();
        // _testPreloadPageKey = GlobalKey();
        _activatedSearchPlatforms[lastViewedPlatform] = GlobalKey();
      });
      log("after ${lastViewedPlatform} | ${_activatedSearchPlatforms[lastViewedPlatform]}");

      // log("page before: ${_currentPreloadPageController.page}");

      // need 2 times
      // if (_loadingPercentage != 100){

      // }

      await _testPreloadPageController.animateToPage(lastViewedIndex,
          duration: const Duration(milliseconds: 300), curve: Curves.easeIn);

      // _testPreloadPageController.jumpToPage(lastViewedIndex);

      await _testPreloadPageController.animateToPage(lastViewedIndex,
          duration: const Duration(milliseconds: 300), curve: Curves.easeIn);

      setState(() {
        // _currentURLIndex = lastViewedIndex;
        // _currentWebViewTitle = _currentURLs[lastViewedIndex]!['title'];
        // _currentWebViewController = _webViewControllers[lastViewedIndex];
        _marqueeKey = UniqueKey();
      });

      // log("page after: ${_currentPreloadPageController.page}");
      // log("page after: ${_testPreloadPageController.page}");
    }

    double position = 0;
    log("search history: $_searchHistory");
    _searchHistory.forEach((key, value) {
      String lastViewedPlatform = URLs[key.toString()]["lastViewedPlatform"];
      int lastViewedIndex =
          URLs[key.toString()][lastViewedPlatform]["lastViewedIndex"];

      // initial keyword
      if (value.runtimeType == bool) {
        result.add(ListTile(
          onTap: () {
            backTo(key, lastViewedPlatform, lastViewedIndex);
            Navigator.pop(context);
          },
          contentPadding:
              EdgeInsets.only(top: position == 0 ? 0 : 15, left: 20),
          title: Text(
              "${key.toString()} ($lastViewedPlatform #${lastViewedIndex + 1})"),
          visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
        ));
      }

      // following drill
      else {
        result.add(ListTile(
          onTap: () {
            backTo(key, lastViewedPlatform, lastViewedIndex);
            Navigator.pop(context);
          },
          visualDensity: VisualDensity(horizontal: 0, vertical: -4),
          // dense: true,
          horizontalTitleGap: 0,
          leading: const FaIcon(
            FontAwesomeIcons.arrowTrendDown,
            size: 18,
            color: Colors.black87,
          ),
          title: Text(
              "${key.toString()} ($lastViewedPlatform #${lastViewedIndex + 1})"),
        ));
      }

      position++;
    });

    return result.toList();
  }

  _platformIconBuilder(String platform) {
    switch (platform) {
      case "Webpage":
        // return const Icon(
        //   FontAwesome.wand_magic_sparkles,
        //   size: 24,
        //   color: Colors.green,
        // );
        return const Icon(HeroIcons.globe_alt, size: 24);
      case "Video":
        return const Icon(BoxIcons.bx_video, size: 24);
      case "SNS":
        return const Icon(Icons.connect_without_contact, size: 24);

      case "Google":
        return const Icon(BoxIcons.bxl_google, size: 24);
      case "YouTube":
        return const Icon(BoxIcons.bxl_youtube, size: 24);
      case "Twitter":
        return const Icon(BoxIcons.bxl_twitter, size: 24);
      case "Facebook":
        return const Icon(BoxIcons.bxl_facebook, size: 24);
      case "Instagram":
        return const Icon(BoxIcons.bxl_instagram, size: 24);
      case "LinkedIn":
        return const Icon(BoxIcons.bxl_linkedin, size: 24);
      case "Bing":
        return const Icon(BoxIcons.bxl_bing, size: 24);
      case "Yahoo":
        return const Icon(BoxIcons.bxl_yahoo, size: 24);
      case "Baidu":
        return const Icon(BoxIcons.bxl_baidu, size: 24);
      // case "SmartImage":
      //   return const Icon(
      //     FontAwesome.photo_film,
      //     size: 24,
      //     color: Colors.green,
      //   );
    }
  }

  _extractKeywords(String content) async {
    // return ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"];
    // return [
    //   "CUHK",
    //   "range",
    //   "study options",
    //   "disciplines",
    //   "students",
    //   "research degrees",
    //   "needs",
    //   "PhD",
    //   "Master's degrees",
    //   "Diplomas",
    //   "Certificate",
    //   "MPhil",
    //   "Taught Doctoral"
    // ];
    log("content: $content");
    final response = await http.post(
      Uri.parse(
          'https://language.googleapis.com/v1/documents:analyzeEntities?key=AIzaSyC3ooNGYaxDyOGVke0fSYCSLAMEe7hQ_UU'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        "document": {
          "type": "PLAIN_TEXT",
          "content": content,
        },
        "encodingType": "UTF8"
      }),
    );

    log("response: $response");

    if (response != null) {
      if (response.statusCode == 200) {
        var jsonResponse =
            convert.jsonDecode(response.body) as Map<String, dynamic>;

        // log("jsonResponse: $jsonResponse");
        // log(jsonResponse['name']);

        var entities = jsonResponse['entities'] != null
            ? jsonResponse['entities'] as List<dynamic>
            : [];
        // log("entities: ${entities}");

        var names = entities.map((e) => e['name']).toList();
        List results = [];
        for (var name in names) {
          if (!results.contains(name)) {
            results.add(name);
          }
        }
        log("results: ${results}");

        // return items;
        return results;
      } else {
        log('Request failed with status: ${response.statusCode}.');
        return null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        drawer: Drawer(
          child: ListView(
            // Important: Remove any padding from the ListView.
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: _themedAppBarColor,
                ),
                child: const Text('Menu'),
              ),
              ListTile(
                trailing: _selectedPageIndex == 0
                    ? Icon(Icons.explore, color: Colors.blue[900])
                    : const Icon(Icons.explore_outlined),
                title: const Text('Explore'),
                onTap: () {
                  _onItemTapped(0);
                  Navigator.pop(context);
                },
              ),
              // ListTile(
              //   trailing: _selectedPageIndex == 1
              //       ? Icon(Icons.history, color: Colors.blue[900])
              //       : const Icon(Icons.history_outlined),
              //   title: const Text('History'),
              //   onTap: () {
              //     _onItemTapped(1);
              //     Navigator.pop(context);
              //     _pushHistoryPage();
              //   },
              // ),
              // ListTile(
              //   trailing: _selectedPageIndex == 2
              //       ? Icon(Icons.bookmark, color: Colors.blue[900])
              //       : const Icon(Icons.bookmark_outline),
              //   title: const Text('Bookmarked'),
              //   onTap: () {
              //     _onItemTapped(2);
              //     Navigator.pop(context);
              //   },
              // ),
              ListTile(
                trailing: _selectedPageIndex == 1
                    ? Icon(Icons.settings, color: Colors.blue[900])
                    : const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () {
                  _onItemTapped(3);
                  Navigator.pop(context);
                  _pushSettingsPage();
                },
              ),
              ListTile(
                trailing: const Icon(BoxIcons.bx_chalkboard),
                title: const Text('Tutorial'),
                onTap: () {
                  // _onItemTapped(3);
                  Navigator.pop(context);
                  _showTutorial();
                },
              ),
            ],
          ),
        ),
        appBar: AppBar(
          backgroundColor: _appBarColor,
          centerTitle: false,
          title: _searchText == ""
              ? const Text("Explore")
              : SizedBox(
                  height: MediaQuery.of(context).size.height * 0.03,
                  // width: MediaQuery.of(context).size.width,
                  child: Marquee(
                    key: _marqueeKey,
                    text: _searchResult.isNotEmpty
                        // ? '$_searchText on $_currentSearchPlatform (${_currentURLIndex + 1} of ${_currentURLs.length})'
                        ? '$_searchText (${_currentURLIndex + 1} of ${_currentURLs.length})'
                        : 'Results for $_searchText',
                    style: const TextStyle(fontSize: 18),
                    scrollAxis: Axis.horizontal, //scroll direction
                    crossAxisAlignment: CrossAxisAlignment.start,
                    blankSpace: 100,
                    velocity: 50.0, //speed
                    pauseAfterRound: const Duration(seconds: 1),
                    // startPadding: 10.0,
                    accelerationDuration: const Duration(seconds: 1),
                    accelerationCurve: Curves.linear,
                    decelerationDuration: const Duration(milliseconds: 500),
                    decelerationCurve: Curves.easeOut,
                  ),
                ),
          leading: Builder(
            builder: (ctx) => IconButton(
              key: _drawerKey,
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          actions: <Widget>[
            IconButton(
                key: _searchButtonKey,
                icon: const Icon(Icons.search),
                onPressed: _pushSearchPage)
          ],
        ),
        floatingActionButton: _searchResult.isNotEmpty
            ? Align(
                alignment: Platform.isIOS
                    ? const Alignment(1, 0.95)
                    : const Alignment(1, 0.88),
                child: GestureDetector(
                  key: _drillButtonKey,
                  onLongPress: () {
                    log("fab long pressed");
                    _normalSearch(false, true);
                  },
                  child: Draggable(
                    feedback: Container(
                      width: 30,
                      height: 30,
                      // margin: EdgeInsets.all(0),
                      // padding: EdgeInsets.only(right: 20),
                      // decoration: BoxDecoration(
                      //     borderRadius: BorderRadius.circular(0),
                      //     border:
                      //         Border.all(width: 2, color: Colors.blue[900]!)),
                      // child: RotationTransition(
                      //   turns: new AlwaysStoppedAnimation(-45 / 360),
                      //   child: FittedBox(
                      child: Transform(
                        transform: Matrix4.translationValues(-15, 5, 0)
                          ..rotateZ(-30 * 3.1415927 / 180),
                        child: const ColorFiltered(
                          colorFilter:
                              ColorFilter.mode(Colors.black87, BlendMode.srcIn),
                          child: Icon(
                            Icons.navigation,
                            size: 30,
                          ),
                        ),
                      ),
                    ),

                    // FloatingActionButton.extended(
                    //   isExtended: true,
                    //   label: Text("123"),
                    //   onPressed: () {
                    //     if (_searchMode == "Default") {
                    //       log("drill ONCE");
                    //       // drill logic
                    //     } else {
                    //       log("already in drill-down mode");
                    //     }
                    //   },
                    //   backgroundColor: _fabColor,
                    //   splashColor: Colors.amber[100],
                    // child: AnimatedBuilder(
                    //   animation: _drillingAnimationController,
                    //   builder: (_, child) {
                    //     return Transform.rotate(
                    //       angle: _drilling
                    //           ? _drillingAnimationController.value *
                    //               2 *
                    //               math.pi
                    //           : 0.0,
                    //       child: child,
                    //     );
                    //   },
                    //   child: const Icon(MyFlutterApp.drill),
                    // ),
                    // ),
                    childWhenDragging: Container(),
                    onDragStarted: () {
                      setState(() {
                        _appBarColor = Colors.red[400]!;
                      });
                    },
                    onDragUpdate: (details) async {
                      log("onDragUpdate ${details.delta} | ${details.globalPosition}");
                    },
                    onDragEnd: (details) async {
                      setState(() {
                        _appBarColor = _defaultAppBarColor;
                      });

                      RenderBox webViewBox = _preloadPlatformKey.currentContext
                          ?.findRenderObject() as RenderBox;
                      Offset webViewPosition =
                          webViewBox.localToGlobal(Offset.zero);
                      double webViewX = webViewPosition.dx;
                      double webViewY = webViewPosition.dy;
                      double webViewWidth = webViewBox.size.width;
                      double webViewHeight = webViewBox.size.height;

                      // log(
                      //     "webViewX: $webViewPosition.dx, webViewY: $webViewPosition.dy, webViewHeight: $webViewHeight");
                      // log(details.offset);

                      setState(() {
                        if (details.offset.dx < webViewX) {
                          _hoverX = webViewX;
                        } else if (details.offset.dx > webViewWidth) {
                          _hoverX = webViewX + webViewWidth;
                        } else {
                          _hoverX = details.offset.dx;
                        }

                        if (details.offset.dy - webViewY < 0) {
                          // _hoverY = 0;
                          _hoverY = -1;
                          // log("1");
                        } else if (details.offset.dy - webViewY >
                            webViewHeight) {
                          // _hoverY = webViewHeight - 1;
                          _hoverY = -1;
                          // log("2");
                        } else {
                          _hoverY = details.offset.dy - webViewY;
                          // _hoverY = -1;

                          // log("3");
                        }
                      });

                      // log("hoverX: $_hoverX, hoverY: $_hoverY");

                      // await _controller_test!.runJavascript("""
                      //     var x = window.innerWidth/2;
                      //     var y = window.innerHeight/2;
                      //     var centre = document.elementFromPoint($_hoverX, $_hoverY);
                      //     Drill.postMessage(centre.innerText);
                      //   """);

                      // _hoverY >= 0 ? await _getSearchQuery() : log("cancel");
                      _hoverY >= 0 ? _performDrill() : log("cancel");
                    },
                    child: FloatingActionButton(
                      onPressed: () {
                        log("fab tapped");
                        // _changeSearchPlatform();

                        // // count down 5 seconds
                        // if (_autoSwitchPlatform == 1) {
                        //   if (_platformActivationTimer == null) {
                        //     _platformActivationTimer = RestartableTimer(
                        //         const Duration(seconds: 2), () async {
                        //       _normalSearch();
                        //     });
                        //   } else {
                        //     _platformActivationTimer!.reset();
                        //   }
                        // }
                      },
                      // label: Text(_currentSearchPlatform),
                      backgroundColor: _fabColor,
                      splashColor: Colors.amber[100],
                      child: const Icon(MyFlutterApp.drill),
                      // child: AnimatedBuilder(
                      //   animation: _drillingAnimationController,
                      //   builder: (_, child) {
                      //     return Transform.rotate(
                      //       angle: _drilling
                      //           ? _drillingAnimationController.value *
                      //               2 *
                      //               math.pi
                      //           : 0.0,
                      //       child: child,
                      //     );
                      //   },
                      //   child: const Icon(MyFlutterApp.drill),
                      // ),
                    ),
                  ),
                ),
              )
            : null,
        body: Column(
          children: <Widget>[
            Container(
              child: !_isFetching
                  ? _searchResult.isNotEmpty
                      ? Flexible(
                          // child: PieCanvas(
                          child: Stack(
                            children: <Widget>[
                              // WebView
                              // Expanded(
                              // child:
                              // GestureDetector(
                              //   onTap: () {
                              //     log("webview tapped");
                              //   },
                              //   onLongPress: () {
                              //     log("webview long pressed");
                              //   },

                              // TODO: show currently searching image
                              if (_currentImage != null)
                                Positioned(
                                  top: 0,
                                  child: Image.file(
                                    File(_currentImage.path),
                                    fit: BoxFit.cover,
                                    width: MediaQuery.of(context).size.width,
                                    height: MediaQuery.of(context).size.height,
                                  ),
                                ),

                              // Title Bar
                              Positioned(
                                top: 0,
                                width: MediaQuery.of(context).size.width,
                                child: ColoredBox(
                                  color: Colors.white,
                                  child: SizedBox(
                                    // height: autoSize(50, context),
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            left: 10.0,
                                            right: 10.0,
                                            top: 5.0,
                                            bottom: 5.0),
                                        child: Text(
                                          _currentWebViewTitle,
                                          style: const TextStyle(
                                            fontSize: 16,
                                          ),
                                          overflow: TextOverflow.visible,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // WebView
                              // Flexible(
                              //   child:
                              Padding(
                                padding: EdgeInsets.only(
                                  top: 30,
                                  bottom: Platform.isIOS
                                      ? (_loadingPercentage < 100 ? 65 : 60)
                                      : (_loadingPercentage < 100 ? 55 : 50),
                                ),
                                child: PreloadPageView.builder(
                                  onPageChanged: (value) {
                                    log("platform changed: $value");
                                    log("${URLs[_searchText][SearchPlatformList[value]]}");
                                    // setState(() {
                                    //   _currentPreloadPageController =
                                    //       _preloadPageControllers[value];
                                    //   _currentPreloadPageKey =
                                    //       _preloadPageKeys[value];
                                    // });
                                  },
                                  scrollDirection: Axis.vertical,
                                  physics: const NeverScrollableScrollPhysics(),
                                  key: _preloadPlatformKey,
                                  preloadPagesCount: 0,
                                  controller: _preloadPlatformController,
                                  itemCount: _activatedSearchPlatforms.length,
                                  itemBuilder: (BuildContext context,
                                          int platformPosition) =>
                                      _buildPlatform(context, platformPosition),
                                ),
                                // ),
                              ),

                              // Bottom Bar
                              Positioned(
                                width: MediaQuery.of(context).size.width,
                                bottom: 0,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 100),
                                  color: _appBarColor,
                                  child: SizedBox(
                                    height: Platform.isIOS
                                        ? (_loadingPercentage < 100 ? 65 : 60)
                                        : (_loadingPercentage < 100 ? 55 : 50),
                                    child: GestureDetector(
                                      onTap: () {
                                        log("swiper tapped");
                                      },
                                      child: Column(
                                        children: [
                                          if (_loadingPercentage < 100)
                                            LinearProgressIndicator(
                                              value: _loadingPercentage / 100.0,
                                              minHeight: 5,
                                              color: Colors.yellow,
                                            ),
                                          Stack(
                                            // alignment: AlignmentGeometry.,
                                            // position element evenly
                                            // clipBehavior: Clip.hardEdge,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  IconButton(
                                                    key: _historiesButtonKey,
                                                    onPressed: () async {
                                                      log("stairs of drill");
                                                      showModalBottomSheet(
                                                        transitionAnimationController:
                                                            AnimationController(
                                                          vsync: this,
                                                          duration:
                                                              const Duration(
                                                                  milliseconds:
                                                                      300),
                                                        ),
                                                        context: context,
                                                        builder: (BuildContext
                                                                context) =>
                                                            Container(
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .height *
                                                              0.5,
                                                          child: Stack(
                                                            children: [
                                                              ListView(
                                                                children: [
                                                                  const ListTile(
                                                                    title: Text(
                                                                      "Search Histories (click to go back)",
                                                                      style:
                                                                          TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontSize:
                                                                            20,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  ..._buildSearchHistoryList(),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    icon: FaIcon(
                                                      FontAwesomeIcons.stairs,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    key: _firstResultButtonKey,
                                                    onPressed: () async {
                                                      if (_currentURLIndex >
                                                          0) {
                                                        log("jump to first page");
                                                        // setState(() {
                                                        //   _swipe = true;
                                                        // });

                                                        _testPreloadPageController
                                                            .jumpToPage(0);
                                                        // _currentPreloadPageController
                                                        //     .jumpToPage(0);
                                                      }
                                                    },
                                                    icon: const FaIcon(
                                                      FontAwesomeIcons
                                                          .backwardFast,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    key: _backButtonKey,
                                                    onPressed: () async {
                                                      await _currentWebViewController!
                                                          .goBack();
                                                    },
                                                    icon: const FaIcon(
                                                        FontAwesomeIcons
                                                            .arrowLeft,
                                                        size: 20),
                                                  ),
                                                  IconButton(
                                                    key: _shareButtonKey,
                                                    onPressed: () async {
                                                      log("share");
                                                      String? title =
                                                          await _currentWebViewController!
                                                              .getTitle();
                                                      WebUri? url =
                                                          (await _currentWebViewController!
                                                              .getUrl());
                                                      await Share.share(
                                                          '${title!}\n${url!}');
                                                    },
                                                    icon: const FaIcon(
                                                        FontAwesomeIcons
                                                            .shareNodes,
                                                        size: 20),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Joystick
                              Positioned(
                                bottom: _joystickBottom,
                                left: _joystickLeft,
                                child: Joystick(
                                  key: _joyStickKey,
                                  mode: _togglePlatformMode
                                      ? JoystickMode.vertical
                                      : JoystickMode.horizontalAndVertical,
                                  base: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: _joystickWidth,
                                    height: _joystickHeight,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      color: _togglePlatformMode
                                          ? Colors.white
                                          : Colors.grey.withOpacity(0.2),
                                      // backgroundBlendMode: BlendMode.multiply,
                                      boxShadow: [
                                        _togglePlatformMode
                                            ? BoxShadow(
                                                color: Colors.grey
                                                    .withOpacity(0.5),
                                                spreadRadius: 5,
                                                blurRadius: 7,
                                                offset: const Offset(0, 3),
                                              )
                                            : const BoxShadow(
                                                color: Colors.transparent,
                                                spreadRadius: 5,
                                                blurRadius: 7,
                                                offset: Offset(0, 3),
                                              ),
                                      ],
                                    ),
                                    child: _togglePlatformMode
                                        ? Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              const Flexible(
                                                child: Icon(
                                                  EvaIcons.close_outline,
                                                  size: 24,
                                                  color: Colors.red,
                                                ),
                                              ),
                                              ...SearchPlatformList.map(
                                                (e) => Flexible(
                                                  child:
                                                      _platformIconBuilder(e),
                                                ),
                                              ).toList(),
                                            ],
                                          )
                                        : null,
                                  ),
                                  stick: GestureDetector(
                                    onDoubleTap: () {
                                      log("joystick double tapped");
                                      if (_joystickBottom == 45) {
                                        setState(() {
                                          _joystickBottom = 20;
                                          _joystickHeight = 40;
                                          _joystickWidth = 40;
                                          _joystickLeft =
                                              (MediaQuery.of(context)
                                                          .size
                                                          .width /
                                                      2) -
                                                  (_joystickWidth / 2);
                                        });
                                      } else {
                                        setState(() {
                                          _joystickBottom = 45;
                                          _joystickHeight = 100;
                                          _joystickWidth = 100;
                                          _joystickLeft =
                                              (MediaQuery.of(context)
                                                          .size
                                                          .width /
                                                      2) -
                                                  (_joystickWidth / 2);
                                        });
                                      }
                                    },
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(50),
                                        color: Colors.grey.withOpacity(0.5),
                                        backgroundBlendMode: BlendMode.multiply,
                                      ),
                                      child: _togglePlatformMode
                                          ? null
                                          : _platformIconBuilder(
                                              _currentSearchPlatform),
                                    ),
                                  ),
                                  period: const Duration(milliseconds: 150),
                                  listener: (details) async {
                                    log("joystick:  ${details.x}, ${details.y}");
                                    // _joystickX = details.x;
                                    // _joystickY = details.y;
                                    if (details.x > 0.5) {
                                      log("next");
                                      if (_currentURLIndex <
                                          _currentURLs.length - 1) {
                                        // await _currentPreloadPageController
                                        await _testPreloadPageController
                                            .nextPage(
                                                duration: const Duration(
                                                    milliseconds: 200),
                                                curve: Curves.easeIn);
                                      }
                                    } else if (details.x < -0.5) {
                                      log("prev");
                                      if (_currentURLIndex > 0) {
                                        log("decrease");

                                        // await _currentPreloadPageController
                                        await _testPreloadPageController
                                            .previousPage(
                                                duration: const Duration(
                                                    milliseconds: 200),
                                                curve: Curves.easeIn);
                                      }
                                    }

                                    if (details.y != 0) {
                                      log("select platform");

                                      setState(() {
                                        _joystickY = details.y;
                                        _togglePlatformMode = true;

                                        if (_joystickBottom == 20) {
                                          setState(() {
                                            _joystickBottom = 45;
                                            _joystickHeight = 100;
                                            _joystickWidth = 100;
                                            _joystickLeft =
                                                (MediaQuery.of(context)
                                                            .size
                                                            .width /
                                                        2) -
                                                    (_joystickWidth / 2);
                                          });
                                        }

                                        _joystickHeight =
                                            SearchPlatformList.length * 70;
                                      });
                                    }
                                  },
                                  onStickDragEnd: () {
                                    if (_togglePlatformMode) {
                                      // area for each option
                                      double step =
                                          2 / (SearchPlatformList.length + 1);

                                      log("_joystickY: $_joystickY | step: $step");

                                      // initialize to topmost action aka cancel
                                      int target =
                                          SearchPlatformList.length + 1;

                                      // upper half
                                      if (_joystickY < 0) {
                                        target =
                                            (((_joystickY - 0.1) / step).abs() +
                                                    (SearchPlatformList.length +
                                                            1) /
                                                        2)
                                                .round();
                                      }

                                      // lower half
                                      else {
                                        target = (((_joystickY - 0.1) / step) -
                                                ((SearchPlatformList.length +
                                                        1) /
                                                    2))
                                            .abs()
                                            .round();
                                      }

                                      // reverse order (7 = Google --> 0 = Google)
                                      target = (target -
                                                  (SearchPlatformList.length +
                                                      1))
                                              .abs() -
                                          1;

                                      if (target >= SearchPlatformList.length) {
                                        target = SearchPlatformList.length - 1;
                                        log("target: $target | platform: ${SearchPlatformList[target]}");
                                      }

                                      if (target >= 0) {
                                        log("target: $target | platform: ${SearchPlatformList[target]}");

                                        _changeSearchPlatform(
                                            SearchPlatformList[target]);
                                        _normalSearch();
                                      } else {
                                        log("cancel");
                                      }

                                      setState(() {
                                        _joystickHeight = 100;
                                        _joystickWidth = 100;
                                        _togglePlatformMode = false;
                                      });
                                    }
                                  },
                                ),
                                // ),
                              ),
                            ],
                            // ),
                          ),
                        )
                      : Flexible(
                          child: Align(
                            alignment: Alignment.center,
                            child: _searchText == ""
                                ? const Text(
                                    "Try to search for something :)",
                                    style: TextStyle(fontSize: 22),
                                  )
                                : const Text(
                                    "No result found",
                                    style: TextStyle(fontSize: 22),
                                  ),
                          ),
                        )
                  : Text("Loading"),
            ),
          ],
        ),
        // ),
      ),
    );
  }

//   _performImageSearch(image, path) async {
//     // final snackBar = SnackBar(
//     //   content: Text("image $image"),
//     //   duration: const Duration(seconds: 3),
//     // );
//     // ScaffoldMessenger.of(context).showSnackBar(snackBar);
//     log("image search 1");
//     if (image != null) {
//       log("image search 2");

//       // // _updateCurrentImage(image);
//       // log("image search 3");

//       EasyLoading.show(
//         status: 'Perform Image Search',
//       );

//       // // try OCR first
//       // var resultsOCR = await _imageSearchGoogle(image, path, "text_detection");
//       // log("OCR:$resultsOCR");
//       // // log("OCR toString: :${resultsOCR.toString()}");

//       // log("image search 4");

//       // // EasyLoading.show(
//       // //   // status: 'Perform Image Search',
//       // //   status: "Searching on Google",
//       // // );

//       // var keywords = _extractKeywords(resultsOCR.toString());
//       // log("OCR extracted: $keywords");

//       // return;

//       var resultsGoogle, resultsBing;
//       resultsGoogle = await _imageSearchGoogle(image, path, "text_detection");
//       log("image search 5");
//       log("image search results Google: $resultsGoogle");

//       EasyLoading.show(
//         status: 'Searching on Bing',
//       );
//       resultsBing = await _imageSearchBing(image, path);
//       log("image search 6");
//       log("image search results Bing: $resultsBing");

//       EasyLoading.show(
//         status: 'Merging Results',
//       );
//       String keyword = resultsGoogle["bestGuessLabel"];
//       var results = _mergeResults([resultsGoogle['urls'], resultsBing['urls']]);
//       log("image search results: $results");
//       await _updateURLs("replace", keyword, "Webpage", results, true);

//       await _updateCurrentURLs();
//       EasyLoading.dismiss();

//       await _moveSwiper(true);
//     }
//   }
}

// flutter pub run build_runner build
@collection
class URL {
  Id id = Isar.autoIncrement; // you can also use id = null to auto increment
  String? url;
  String? title;
  DateTime firstViewed = DateTime.now();
  DateTime lastViewed = DateTime.now();
  int viewCount = 1;
  String duration = Duration(seconds: 0).toString();
  bool bookmarked = false;
}

@collection
class SearchRecord {
  Id id = Isar.autoIncrement; // you can also use id = null to auto increment
  String? searchText;
  DateTime time = DateTime.now();
  int searchCount = 1;
}

//* Image Search
class CredentialsProvider {
  CredentialsProvider();

  Future<ServiceAccountCredentials> get _credentials async {
    final directory = await getApplicationDocumentsDirectory();
    bool fileExists = false;
    String filename = "credential.json";
    File jsonCredential = File(directory.path + "/" + filename);
    fileExists = jsonCredential.existsSync();
    log("JSON EXIST?= " + fileExists.toString());

    String _file = await jsonCredential.readAsStringSync();
    /*String _file = await rootBundle
        .loadString("assets/iron-ripple-361505-0cf917e05a8a.json");*/
    return ServiceAccountCredentials.fromJson(_file);
  }

  Future<AutoRefreshingAuthClient> get client async {
    AutoRefreshingAuthClient _client = await clientViaServiceAccount(
        await _credentials, [vision.VisionApi.cloudVisionScope]).then((c) => c);
    return _client;
  }
}

class Order {
  int area;
  String description;

  Order({required this.area, required this.description});
}

_imageSearchGoogle(src, path, [type]) async {
  Directory dir = (await getApplicationDocumentsDirectory());
  bool fileExists = false;
  String filename = "credential.json";
  File jsonCredential = File(dir.path + "/" + filename);
  jsonCredential.createSync();
  fileExists = jsonCredential.existsSync();
  const myJsonAsString =
      '{ "type": "service_account", "project_id": "iron-ripple-361505", "private_key_id": "0cf917e05a8a26c96d3afd8a8d3715bc80010751", "private_key": "-----BEGIN PRIVATE KEY-----\\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDr+dECe18jdmz1\\nNBG4IH09GxfL7n502s7eY2jnFqd6KJOko/JGQtn6NvxbCHhhubhQqp5dPVw/Ge6h\\nrwFdaQqVvS8z3kQVFaiAdWJjDvSlOZNLL7PLbwrE5CHbhgtC3xD0KUrGUMtLSf4U\\n4svXx3SB1US5vR1Ywtn/tjtlhfKgJD+aP7JeTs2ITT6DpKKyLIdmnUsHnCoQGh6b\\nJN00nDZuG6VB71o5lMy0mhGPFXR20WwP7wKckyI+Vk0n4vRu17kmNojBudFAYVvQ\\nwPcA6XfP/Il5z0fg5pQwEBy8suxZngfIc0jNCLhbAOxk82eC8QK73YFosOrq4KUM\\nzzLwTwBHAgMBAAECggEAH1i/COneRbCLISLgFwoLKPgK4rZqn6zwsxPDO9jDZFO0\\nko02zK+VE4svXbZpK24yNlZb6tM7svmHvNGpyECrvSAgVO8PMzp+ePC0TP1lG/e4\\ngdHd5psjHpbsNSRVevYf40IC+AeD4fCmgHFvlllIDaEzhnWWoD5jcCJt5HrKiWGA\\nsDwICkmCQZju6ZMa78f5XbZKYtFD/Pj+GyhHkZrvs6TGf7x1juGJBEL4WKuL1xVI\\neQiFhsZ04mjYUhdfSgMxblKkhCqpWNM4HsDmexSJOTATUDLgVLPEfy8sy1tzyTir\\nE23PISLUxkjpEXRdu76OiOVxpD7CVrFoFh5Sz0qiAQKBgQD4iB6H3/rjfQI4G69Y\\nt7fx+8hAms+8fEEj8tVN23Es4Bbg7kobO3+dHBqEXNa3ZRcUJXFx/km2IKbnIiyt\\nxY6nDk0lRwAXKAbO1t97GvZlduQvU0Q9nVpxo3sOFHkirTEj+TZXSwWGU9utqNzA\\nPu7SIR4zhb3yM9t/yoBS0042RwKBgQDzERvNG1Fay/FoBwbultO52GhOS3Z++ASp\\n58V4Oqef5e/ifxuwHZQKJ1dSUTocnSufMNBnTzh64uqQyOfJ6VnUICcincbP4BCJ\\n2aCPNB0pZnsHBJG4HLgndhd8fasqo2EsPg0q3DIUkKU48N5XUYbOQQgRNRx3Gfoy\\nzfAui1vmAQKBgD54MHxkvzJZJKqnws5g93p6mB4tC5RMAy+fBSCZzPvDo9yL6NKp\\nhO0fuEaW812Lql5k/vvxN+PwlyM3wtU2+CFjhd6d1xb696Mb/XZ7E33zgW2n11pJ\\naAdyWSbz3HLr55MsPA17DPtzrp8a98nWx77HlkjLEDCF+mFHrDOla15XAoGAVl0/\\n2ZLZRz+rmODWT7P7qs7/0MHzao3Jam1VtrBwmtnicEHlnqAD18++sRr3YO9fboKz\\nqeF2GgPCgItCAHYPWtXJ0fzphTcB6VkQOZG0wt8M26N9+0MJE8xb7/ne9Zlzj3rE\\nxvPSP4hdjGvZNIFdOq/Uo/iREqiCQ8b0jjUqBAECgYEA9IEUdwRaMytZfi2GNdfI\\n+iujVtD6yFqZpiEZA4wX3qmtFR5xjF2WElli9mlfVJbQkzQUmWIAz/KW1X47lbHu\\nUN8HeZo0BITSCz+VnPGOg75o/IiX/bOPaIBY4uVPj7DQZQqZmYDcqy++ZHfVsJRV\\nuXyVCi+0wSsb+JRBhZRk26Y=\\n-----END PRIVATE KEY-----\\n", "client_email": "vision@iron-ripple-361505.iam.gserviceaccount.com", "client_id": "101967982492272397269", "auth_uri": "https://accounts.google.com/o/oauth2/auth","token_uri": "https://oauth2.googleapis.com/token","auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs","client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/vision%40iron-ripple-361505.iam.gserviceaccount.com"}';
  final decoded = json.decode(myJsonAsString);
  jsonCredential.writeAsStringSync(json.encode(decoded));
  bool exist = await File(jsonCredential.path).exists();
  if (exist) {
    log("STILL HERE ");
  } else {
    log("JSON CRED doesnt exits");
  }

  try {
    var _client = await CredentialsProvider().client;

    final bytes = File(path).readAsBytesSync();
    String img64 = base64Encode(bytes);

    // Future logoDetection(String image) async {
    //   var _vision = vision.VisionApi(await _client);
    //   var _api = _vision.images;
    //   var _response =
    //       await _api.annotate(vision.BatchAnnotateImagesRequest.fromJson({
    //     "requests": [
    //       {
    //         "image": {"content": image},
    //         "features": [
    //           {
    //             "type": "LOGO_DETECTION",
    //           }
    //         ]
    //       }
    //     ]
    //   }));
    //   List<vision.EntityAnnotation> entities;
    //   var logoOutput;
    //   _response.responses?.forEach((data) {
    //     entities = data.logoAnnotations as List<vision.EntityAnnotation>;
    //     logoOutput = entities[0].description;
    //   });
    //   log(logoOutput);
    // }

    Future textDetection(String image) async {
      var _vision = vision.VisionApi(await _client);
      var _api = _vision.images;
      var _response =
          await _api.annotate(vision.BatchAnnotateImagesRequest.fromJson({
        "requests": [
          {
            "image": {"content": image},
            "features": [
              {
                "type": "TEXT_DETECTION",
                // "type": "DOCUMENT_TEXT_DETECTION",
              }
            ]
          }
        ]
      }));

      List<vision.EntityAnnotation>? entities;

      _response.responses?.forEach((data) {
        entities = data.textAnnotations as List<vision.EntityAnnotation>?;
      });
      if (entities == null) {
        log("No words is detected");
        exit(1);
      }
      // log("entities1: $entities");
      List ocr = [];
      for (int i = 0; i < entities!.length; i++) {
        ocr.add(entities![i].description?.trim());
      }

      // log("ocr concat: ${ocr}");
      // log("ocr concat: ${ocr.join(' ').replaceAll('\n', '')}");

      return ocr.join(' ').replaceAll('\n', '');

      final acc = [0];
      int count = 0;

      List<String?> str_arr = [''];
      List<String?> original = [''];
      String? string_ent = entities![0].description;
      final separated = string_ent?.split('\n');

      for (int j = 1; j < entities!.length; j++) {
        var vertice = entities![j].boundingPoly!.vertices;
        String? curString = entities![j].description;
        //area of each words
        var max_x = 0, max_y = 0, min_x = vertice![0].x, min_y = vertice[0].y;
        for (int i = 0; i < vertice!.length; i++) {
          if (vertice[i].x! > max_x) {
            max_x = vertice[i].x!;
          }
          if (vertice[i].y! > max_y) {
            max_y = vertice[i].y!;
          }
          if (vertice[i].x! < min_x!) {
            min_x = vertice[i].x!;
          }
          if (vertice[i].y! < min_y!) {
            min_y = vertice[i].y!;
          }
        }

        var length_x = max_x - min_x!;
        var length_y = max_y - min_y!;
        var area = length_x * length_y;

        // log("image $image");
        // log("entities![j].description ${entities![j].description}");
        acc.insert(j, area);
        original.insert(j, entities![j].description);
      }

      final stats = Stats.fromData(acc);
      final numberArr = [0];
      final Map<String, int> outputString = {};

      List<Order> orders = [];

      var countArr = 0;

      for (int j = 0; j < separated!.length; j++) {
        for (int i = 0; i < original.length; i++) {
          if (separated[j].contains(original[i]!)) {
            numberArr[countArr] += acc[i];
          }
        }
        orders.add(Order(area: numberArr[countArr], description: separated[j]));
        countArr++;
        numberArr.insert(countArr, 0);
      }

      //log(numberArr);
      orders.sort((a, b) => b.area.compareTo(a.area));
      log("Ordered Output text: ${orders.map((order) => order.description)}");

      log("TEXT: $str_arr");
      return str_arr;
    }

    // Future<vision.BatchAnnotateImagesResponse> search(String image) async {
    Future<Map> webSearch(String image) async {
      var _vision = vision.VisionApi(await _client);
      var _api = _vision.images;
      var _response =
          await _api.annotate(vision.BatchAnnotateImagesRequest.fromJson({
        "requests": [
          {
            "image": {"content": image},
            "features": [
              {
                "type": "WEB_DETECTION",
                "maxresult": 20,
              }
            ]
          }
        ]
      }));
      // log(entity.entityId);
      List<vision.WebEntity>? entities;
      List<vision.WebImage>? fullMatchImage;
      List<vision.WebImage>? partialMatchImage;
      List<vision.WebPage>? pageWithMatchImage;
      List<vision.WebImage>? pageWithSimilarImage;

      var bestguess = vision.WebLabel();

      var imgUrl = vision.WebImage();

      var _label;
      var i = 0;

      _response.responses?.forEach((data) {
        _label = data.webDetection?.bestGuessLabels ?? '';

        entities = data.webDetection?.webEntities != null
            ? data.webDetection?.webEntities as List<vision.WebEntity>
            : [];

        //full_match_image =
        //  data.webDetection!.fullMatchingImages as List<vision.WebImage>;
        if (data.webDetection?.partialMatchingImages != null) {
          partialMatchImage =
              data.webDetection!.partialMatchingImages as List<vision.WebImage>;
          log("not null1 | ${data.webDetection?.partialMatchingImages}");
        } else {
          log("null1");
        }

        if (data.webDetection?.pagesWithMatchingImages != null) {
          pageWithMatchImage = data.webDetection!.pagesWithMatchingImages
              as List<vision.WebPage>;
          log("not null2 | ${data.webDetection?.pagesWithMatchingImages}");
        } else {
          log("null2");
        }

        if (data.webDetection?.visuallySimilarImages != null) {
          pageWithSimilarImage =
              data.webDetection!.visuallySimilarImages as List<vision.WebImage>;
          log("not null3 | ${data.webDetection?.visuallySimilarImages}");
        } else {
          log("null3");
        }

        log("_label 4 | ${_label as List<vision.WebLabel>}");
        bestguess = _label?.single ?? '';
        //entity = entities!;
      });

      // log("best guess label=  " + bestguess.label.toString());
      String bestGuessLabel = bestguess.label.toString();

      i = 0;
      var j = 0;

      Map results = {"bestGuessLabel": bestGuessLabel};
      List urls = [];
      int len = pageWithSimilarImage?.length ?? 0;
      for (j = 0; j < len; j++) {
        // log("page with match image title=" +
        //     page_with_match_image![j].pageTitle.toString());
        // log("page with match image =" +
        //     page_with_match_image![j].url.toString());

        if (pageWithMatchImage != null) {
          log("pageWithMatchImage: $pageWithMatchImage | len: $len | j: $j");
          urls.add({
            'title': pageWithMatchImage![j].pageTitle.toString(),
            'link': pageWithMatchImage![j].url.toString()
          });
        } else {
          urls.add({
            'title': pageWithSimilarImage![j].toString(),
            'link': pageWithSimilarImage![j].url.toString()
          });
        }
      }

      results.addAll({'urls': urls});

      // return _response;
      return results;
    }

    //BingVisualSearch(img64, path, name);
    var webResults;
    if (type == "text_detection") {
      webResults = textDetection(img64);
    } else {
      webResults = webSearch(img64);
    }

    // textDetection(img64);
    // logoDetection(img64);

    // log("results = ${await Future.value(results)}");
    return await Future.value(webResults);
  } finally {
    await jsonCredential.delete();
    fileExists = jsonCredential.existsSync();
    log("FINALLY = " + fileExists.toString());
    bool exist = await File(jsonCredential.path).exists();
    if (exist) {
      log("STILL HERE ");
    } else {
      log("JSON CRED doesnt exits");
    }
  }
}

_imageSearchBing(src, path) async {
  final bytes = File(path).readAsBytesSync();
  String img64 = base64Encode(bytes);

  // Future BingSearch(String imgpath, String img64) async {
  //   final apiKey = "bb1d24eb3001462a9a8bd1b554ad59fa";
  //   final imageData = base64.encode(File(imgpath).readAsBytesSync());

  //   var uri =
  //       Uri.parse('https://api.bing.microsoft.com/v7.0/images/visualsearch');
  //   var headers = {
  //     'Ocp-Apim-Subscription-Key': 'bb1d24eb3001462a9a8bd1b554ad59fa'
  //   };

  //   var request = http.MultipartRequest('POST', uri)
  //     ..headers.addAll(headers)
  //     ..files.add(await http.MultipartFile.fromPath('image', imgpath,
  //         filename: 'myfile'));
  //   var response = await request.send();
  //   // Convert the base64 image to bytes

  //   final String responseString = await response.stream.bytesToString();

  //   log(responseString);

  //   Map out = {};
  //   List results = [];
  //   // Convert the base64 image to bytes

  //   if (response.statusCode == 200) {
  //     final responseJson = jsonDecode(responseString);
  //     final elements = responseJson['tags'][0]['actions'];
  //     var bingVisualObject;

  //     log("response code ${response.statusCode}");
  //     elements.forEach((data) => {
  //           if (data['actionType'] == "VisualSearch")
  //             {bingVisualObject = data['data']['value']}
  //         });

  //     log("bingVisualObject $bingVisualObject");

  //     if (bingVisualObject == null) {
  //       log("bing search result null");
  //       // return null;
  //     } else {
  //       bingVisualObject.forEach((value) {
  //         log("Website name: ${value['name']}");
  //         log("website: ${value['hostPageUrl']}");
  //         results.add({
  //           'title': value['name'].toString(),
  //           'link': value['hostPageUrl'].toString(),
  //         });
  //       });
  //     }
  //   } else {
  //     log('Failed to upload image. Error code: ${response.statusCode}');
  //   }
  //   out.addAll({'urls': results});
  //   return out;
  // }

  List bestGuessLabel = [];
  Future<Map> BingSearch(String imgpath, String img64,
      [String imgURL = ""]) async {
    final apiKey = "bb1d24eb3001462a9a8bd1b554ad59fa";
    // final imageData = base64.encode(File(imgpath).readAsBytesSync());

    //?mkt=zh-HK&setLang=EN
    var uri = Uri.parse(
        'https://api.bing.microsoft.com/v7.0/images/visualsearch?mkt=en-US');
    var headers = {
      'Ocp-Apim-Subscription-Key': 'bb1d24eb3001462a9a8bd1b554ad59fa',
    };

    final knowledgeRequest = {
      "invokedSkills": ["SimilarImages"],
      "invokedSkillsRequestData": {"enableEntityData": "true"}
    };

    var request = http.MultipartRequest('POST', uri);
    var imageToken = '';

    request.fields
        .addAll({"invokedSkills": "SimilarImages", 'enableEntityData': 'true'});

    request.headers.addAll(headers);

    //URL OR IMG64
    if (imgURL == "") {
      request.files.add(await http.MultipartFile.fromPath('image', imgpath,
          filename: 'myfile'));
    } else {}

    var response = await request.send();
    // Convert the base64 image to bytes

    final String responseString = await response.stream.bytesToString();

    print(responseString);

    List Result = [];
    List PageIncludedImage = [];

    Map results = {"bestGuessLabel": bestGuessLabel};
    // Convert the base64 image to bytes

    if (response.statusCode == 200) {
      final responseJson = jsonDecode(responseString);
      imageToken = responseJson['image']['imageInsightsToken'];

      final elements = responseJson['tags'][0]['actions'];
      var bingVisualObject;
      var bingVisualQuery = null;
      var bingIncludedPage = null;
      var bingBestRepresentation = null;
      var bingIncludedName = null;

      print("response code ${response.statusCode}");
      elements.forEach((data) => {
            if (data['actionType'] == "VisualSearch")
              {bingVisualObject = data['data']['value']}
          });
      elements.forEach((data) => {
            if (data['actionType'] == "RelatedSearches")
              {bingVisualQuery = data['data']['value']}
          });
      elements.forEach((data) => {
            if (data['actionType'] == "PagesIncluding")
              {bingIncludedPage = data['data']['value']}
          });
      elements.forEach((data) => {
            if (data['actionType'] == "BestRepresentativeQuery")
              {bingBestRepresentation = data['displayName']}
          });
      print("Bing gust: ${bingBestRepresentation}");

      if (bingIncludedPage.length != 0) {
        bingIncludedName = bingIncludedPage[0]['name'].toString();
        bingIncludedPage.forEach((value) async {
          // final isShopping = isShoppingWebsite(value['hostPageUrl']);
          // if (isShopping) {
          //   shoppingResult.add(value['hostPageUrl']);
          // }

          Result.add({
            'title': value['name'].toString(),
            'link': value['hostPageUrl'].toString(),
          });
          PageIncludedImage.add({
            'title': value['name'].toString(),
            'thumbnail': value['thumbnailUrl'].toString(),
            'website': value['hostPageUrl'].toString(),
          });
        });
      }

      bingVisualObject.forEach((value) async {
        // print("fetch URL: ==============");
        //  print("Website name: ${value['name']}");
        // print("website: ${value['hostPageUrl']}");

        // final isShopping = isShoppingWebsite(value['hostPageUrl']);
        // if (isShopping) {
        //   shoppingResult.add(value['hostPageUrl']);
        // }
        // print('Is the URL a shopping website? $isShopping');

        Result.add({
          'title': value['name'].toString(),
          'link': value['hostPageUrl'].toString(),
        });
      });

      List bestGuessList = [];

      if (bingVisualQuery != null) {
        bingVisualQuery.forEach((value) async {
          // print("Query name: ${value['text']}");
          //bestGuessLabel.add(value['text']);

          bestGuessList.add({
            'bestGuessLabel': value['text'],
            'urls': value['thumbnail']['url'],
          });
        });

        if (PageIncludedImage.length > 0) {
          bestGuessLabel.add(bingIncludedName);
        } else {
          // print("NULL bestGuessLabel");
          if (bingBestRepresentation != null) {
            bestGuessLabel.add(bingBestRepresentation);
          } else {
            bestGuessLabel.add(bingVisualQuery[0]['displaytext']);
            // results.addAll({'BestGuessList': bestGuessList});
          }

          // if (bestGuessLabel == null) {
          //    bestGuessLabel.add(bingBestRepresentation);
          //  }
        }

        print(bestGuessLabel);
        results.addAll({'bestGuessList': bestGuessList});
        print(bestGuessList);
      }
    } else {
      print('Failed to upload image. Error code: ${response.statusCode}');
    }

    // print("Bing: ${results['bestGuessLabel']}");

    // print("results ${shoppingResult}");
    // if (PageIncludedImage != null) {
    //   results.addAll({'urls': PageIncludedImage});
    // }
    results.addAll({'urls': Result});

    return results;
  }

  var bingVisualResult = BingSearch(path, img64);
  return bingVisualResult;
}
