import 'dart:async';
import 'dart:convert';
import 'dart:developer';
// import 'dart:ffi';
import 'dart:io' show Directory, File, Platform, exit;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
import 'package:fyp_searchub/pages/history.dart';
import 'package:fyp_searchub/pages/search.dart';
import 'package:fyp_searchub/pages/settings.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
// import 'package:duration/duration.dart';
import 'package:async/async.dart';
// import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marquee/marquee.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
// import 'package:flutter_native_splash/flutter_native_splash.dart';
// import 'package:crypto/crypto.dart';
import 'package:html/parser.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/vision/v1.dart' as vision;

import 'package:flutter/services.dart';
import 'package:stats/stats.dart';

import 'duck_duck_go_icons.dart';
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
  "Title",
  "Webpage Content",
  "Title With Webpage Content",
  "Hovered Webpage Content",
  // "New Mode",
  // "TEST HIGHLIGHT"
];

List<String> MergeAlgorithmList = [
  "ABAB",
  "Frequency",
  "Original Rank",
  "Further Merge",
];

List<String> VideoMergeAlgorithmList = [
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
  "General",
  "Video",
  "SNS",
];

// ignore: non_constant_identifier_names
List<String> GeneralPlatformList = [
  "Google",
  "Bing",
  "DuckDuckGo",
];

// ignore: non_constant_identifier_names
List<String> VideoPlatformList = [
  "YouTube",
  "Bing Video",
  "Vimeo",
];

// ignore: non_constant_identifier_names
List<String> SNSPlatformList = [
  "Twitter",
  "Facebook",
  "Instagram",
  "LinkedIn",
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
      _videoMergeAlgorithm,
      _preloadNumber,
      _reverseJoystick,
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
  var _tutorial;

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
  List _enabledGeneralPlatforms = [],
      _enabledVideoPlatforms = [],
      _enabledSNSPlatforms = [];
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
  var _isDialOpen = ValueNotifier<bool>(false);

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
    final generalMergeAlgorithm =
        await prefs.getString("generalMergeAlgorithm") ?? MergeAlgorithmList[0];

    final videoMergeAlgorithm = await prefs.getString("videoMergeAlgorithm") ??
        VideoMergeAlgorithmList[0];
    final enabledGeneralPlatforms =
        await prefs.getStringList("enabledGeneralPlatforms") ??
            GeneralPlatformList;
    final enabledVideoPlatforms =
        await prefs.getStringList("enabledVideoPlatforms") ?? VideoPlatformList;
    final enabledSNSPlatforms =
        await prefs.getStringList("enabledSNSPlatforms") ?? SNSPlatformList;

    log("enabledGeneralPlatforms $enabledGeneralPlatforms | enabledVideoPlatforms: $enabledVideoPlatforms | enabledSNSPlatforms: $enabledSNSPlatforms");
    // final preloadNumber = await prefs.getInt("preloadNumber") ?? 1;
    final preloadNumber = await prefs.getBool("preloadNumber") ?? true;
    final reverseJoystick = await prefs.getBool("reverseJoystick") ?? false;
    final autoSwitchPlatform = await prefs.getInt("autoSwitchPlatform") ?? 0;
    final theme = await prefs.getInt("theme") ?? Theme.Light.index;

    await Isar.open([URLSchema, SearchRecordSchema], name: "isar");
    final isar = Isar.getInstance("isar");
    final searchRecords =
        await isar!.searchRecords.where().sortByTimeDesc().findAll();

    // final isarSearchRecords =
    //     await Isar.open([SearchRecordSchema], name: "SearchRecord");

    setState(() {
      _currentSearchPlatform = "General";
      _searchAlgorithm = algorithm;
      _mergeAlgorithm = generalMergeAlgorithm;
      _videoMergeAlgorithm = videoMergeAlgorithm;
      _enabledGeneralPlatforms = enabledGeneralPlatforms;
      _enabledVideoPlatforms = enabledVideoPlatforms;
      _enabledSNSPlatforms = enabledSNSPlatforms;

      _preloadNumber = preloadNumber;
      _reverseJoystick = reverseJoystick;
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
          color: Colors.green,
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

    _tutorial = TutorialCoachMark(
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
      if (_searchCount > 10) {
        setState(() {
          _gg = true;
        });
      }
    }
    log("_gg: $_gg");

    var ENGINE_ID, uri;

    log("page: $page | _start: $_start");

    var response;
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
                    'https://api.bing.microsoft.com/v7.0/custom/search?q=$value&customconfig=6c099879-5079-4eb0-be77-694fffc16ddc&mkt=zh-HK'),
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
        response =
            await http.get(Uri.parse('https://duckduckgo.com/html/?q=$value'));

        // log("ddg response: $response");
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
                    // 'https://api.vimeo.com/videos?page=1&per_page=100&query=$value&sort=relevant'),
                    'https://api.vimeo.com/videos?query=$value&sort=relevant'),
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
      // cleaned.replaceFirst("http://", "https://").replaceFirst("https://", "");
      // ! REAL GOOD?
      // cleaned = cleaned.replaceFirst(RegExp(r'^(http:\/\/)'), "https://");
      // cleaned = cleaned
      //     .replaceFirst(RegExp(r'^(http:\/\/)'), "")
      //     .replaceFirst(RegExp(r'^(https:\/\/)'), "");

      log("cleaned: $cleaned");

      // if (endsWithSlash.hasMatch(cleaned)) {
      //   cleaned = cleaned.substring(0, cleaned.length - 1);
      // }
      return cleaned;
    }

    // if (response != null) {
    //   if (response.statusCode == 200) {
    var jsonResponse;
    try {
      jsonResponse = convert.jsonDecode(response.body) as Map<String, dynamic>;
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
            "snippet": results[i]['snippet']
                .toString()
                .trim()
                .replaceAll(RegExp(r'(\.\.\.)$'), ""),
            "rank": i + 1,
          });
        }

        log("google items: $items");

        // *test data
        // items = [
        //   {
        //     "title": "The Chinese University of Hong Kong",
        //     "link": "https://www.cuhk.edu.hk/",
        //     "snippet":
        //         "The Chinese University of Hong Kong (CUHK) is a top Hong Kong university with strong research emphasis. The university aims to bring together China and the ",
        //     "rank": 1
        //   },
        //   {
        //     "title": "Postgraduate Admissions - CUHK Graduate School",
        //     "link": "https://www.gs.cuhk.edu.hk/admissions/",
        //     "snippet":
        //         "CUHK offers a wide range of study options in various disciplines to cater for the different needs of students, ranging from research degrees of PhD, ",
        //     "rank": 2
        //   },
        //   {
        //     "title": "Chinese University of Hong Kong - Wikipedia",
        //     "link":
        //         "https://en.wikipedia.org/wiki/Chinese_University_of_Hong_Kong",
        //     "snippet":
        //         "The Chinese University of Hong Kong (CUHK) is a public research university in Ma Liu Shui, Hong Kong, formally established in 1963 by a charter granted by ",
        //     "rank": 3
        //   },
        //   {
        //     "title": "CUHK Business School | BBA, MBA & EMBA in Hong Kong",
        //     "link": "https://www.bschool.cuhk.edu.hk/",
        //     "snippet":
        //         "CUHK Business School is a global institution in Hong Kong. We offer various business programmes that help students embrace innovation and nurture their ",
        //     "rank": 4
        //   },
        //   {
        //     "title":
        //         "Undergraduate Admissions - The Chinese University of Hong Kong ...",
        //     "link": "https://admission.cuhk.edu.hk/",
        //     "snippet":
        //         "Getting Started · See Yourself in Us · Where Your Dream Can Be Found · A Day in CUHK · News and Activities.",
        //     "rank": 5
        //   },
        //   {
        //     "title": "CUHK School of Architecture",
        //     "link": "https://www.arch.cuhk.edu.hk/",
        //     "snippet":
        //         "CUHK School of Architecture. ... ALUMNA WINS CUHK YOUNG SCHOLARS THESIS AWARD 2021. PROJECTS. AWARDS. Hong Kong. Local Engagement.",
        //     "rank": 6
        //   },
        //   {
        //     "title": "CUHK LibrarySearch",
        //     "link": "https://julac-cuhk.primo.exlibrisgroup.com/",
        //     "snippet":
        //         " LibrarySearch provides simple, one-stop searching for CUHK library books, e-resources, videos, articles, dissertations, undergraduate past exam papers, ",
        //     "rank": 7
        //   },
        //   {
        //     "title": "CUHK LAW - The Chinese University of Hong Kong",
        //     "link": "https://www.law.cuhk.edu.hk/app/",
        //     "snippet":
        //         "Doing the CUHK JD Programme has been a truly rewarding and enjoyable experience. What I especially love about the Programme are the highly qualified and ",
        //     "rank": 8
        //   },
        //   {
        //     "title": "Career Opportunities @ CUHK - CUHK - HRO",
        //     "link":
        //         "https://www.hro.cuhk.edu.hk/en-gb/career/career-opportunities",
        //     "snippet":
        //         "Career Opportunities @ CUHK ... Copyright @ 2023. All Rights Reserved. The Chinese University of Hong Kong. Web Accessibility Recognition Scheme Family Friendly ",
        //     "rank": 9
        //   },
        //   {
        //     "title":
        //         "CUHK MBA: Top MBA Programme in Hong Kong | Full-time MBA ...",
        //     "link": " https://mba.cuhk.edu.hk/",
        //     "snippet":
        //         "Fast-track learning with the full-time CUHK MBA or part-time MBA programme offers leadership training, and global learning opportunities, ",
        //     "rank": 10
        //   }
        // ];
        break;
      case 'Bing':
        int rank = 1;

        log("bing0: ${jsonResponse['webPages']}");

        if (jsonResponse['webPages'] != null) {
          if (jsonResponse['webPages']['value'] != null) {
            for (int i = 0; i < jsonResponse['webPages']['value'].length; i++) {
              items.add({
                "title": jsonResponse['webPages']['value'][i]['name'],
                "link": cleanUrl(jsonResponse['webPages']['value'][i]['url']),
                "snippet": jsonResponse['webPages']['value'][i]['snippet']
                    .toString()
                    .trim()
                    .replaceAll(RegExp(r'(\.\.\.)$'), ""),
                "rank": rank++,
              });

              var deepLinks = jsonResponse['webPages']['value'][i]["deepLinks"];
              if (deepLinks != null) {
                for (int j = 0; j < deepLinks.length; j++) {
                  items.add({
                    "title": deepLinks[j]['name'],
                    "link": cleanUrl(deepLinks[j]['url']),
                    "snippet": deepLinks[j]['snippet']
                        .toString()
                        .trim()
                        .replaceAll(RegExp(r'(\.\.\.)$'), ""),
                    "rank": rank,
                  });
                  // deep links same rank as parent
                  // rank++;
                }
              }
            }
          }
        }

        log("bing2: ${items}");

        // *test data
        // items = [
        //   {
        //     "title": "The Chinese University of Hong Kong",
        //     "link": "https://www.cuhk.edu.hk/english/index.html",
        //     "snippet":
        //         "The Chinese University of Hong Kong (CUHK) is a top Hong Kong university with strong research emphasis. The university aims to bring together China and the West. CUHK 60 th anniversary Strategic Plan 2021—2025 Search for Senior Academic Appointments",
        //     "rank": 1
        //   },
        //   {
        //     "title": "MyCUHK",
        //     "link": "http://portal.cuhk.edu.hk/",
        //     "snippet": "portal.cuhk.edu.hk",
        //     "rank": 2
        //   },
        //   {
        //     "title": "Library",
        //     "link": "https://www.lib.cuhk.edu.hk/en",
        //     "snippet":
        //         'CUHK Golden Jubilee Celestial Civilian Scholarship on Hong Kong Literature 2022/23 10:00 am - 11:00 pm 23 Mar 21 Apr "Chinese Classic Text Mining and Processing" Workshops (Mar-Apr 2023) 2:30 pm - 5:30 pm 23 Mar 21 Apr "Chinese Classic Text Mining ',
        //     "rank": 2
        //   },
        //   {
        //     "title": "CUHK A-Z",
        //     "link": "https://www.cuhk.edu.hk/english/cuhk-information.html",
        //     "snippet":
        //         "Directory of CUHK's Academic Units, Colleges, Professional and Administrative Services Units, Research Units, Students Organizations and Staff Organizations. A - E | F - M | N - Z Academic and Quality Section Academic Links, Office of Accountancy, The School",
        //     "rank": 2
        //   },
        //   {
        //     "title": "Giving to CUHK",
        //     "link": "https://www.cuhk.edu.hk/english/giving.html",
        //     "snippet":
        //         "Giving to CUHK Over the decades CUHK has benefitted from the goodwill and munificence of many of its friends, corporate allies and alumni. Such support, in various forms ranging from student scholarships, research sponsorships, endowed professorships to funding for infrastructural projects, has helped propel the University forward in its pursuit of excellence and the realization of its missions.",
        //     "rank": 2
        //   },
        //   {
        //     "title": "Shortcuts",
        //     "link": "https://www.gs.cuhk.edu.hk/admissions/",
        //     "snippet":
        //         "CUHK offers a wide range of study options in various disciplines to cater for the different needs of students, ranging from research degrees of PhD, MPhil to Taught Doctoral and Master's degrees, PG Diplomas and PG Certificate. CUHK offers a wide range of study ",
        //     "rank": 2
        //   },
        //   {
        //     "title": "Career Opportunities",
        //     "link":
        //         "https://www.hro.cuhk.edu.hk/en-gb/career/career-opportunities",
        //     "snippet":
        //         "Career Opportunities @ CUHK Professoriate, Teaching & Research Academic Posts Administrative, Professional, Executive, Clerical, Technical & Research Posts Junior Posts Applications Forms and Personal Information Collection Statement Back to top ",
        //     "rank": 2
        //   },
        //   {
        //     "title": "Introducing CUHK",
        //     "link":
        //         "https://www.cuhk.edu.hk/english/aboutus/university-intro.html",
        //     "snippet":
        //         "Introducing CUHK. Founded in 1963, The Chinese University of Hong Kong (CUHK) is a forward-looking comprehensive research university with a global vision and a mission to combine tradition with modernity, and to bring together China and the West. CUHK teachers and students hail from all around the world. CUHK graduates are connected worldwide ",
        //     "rank": 2
        //   },
        //   {
        //     "title": "往內容",
        //     "link": "http://admission.cuhk.edu.hk/",
        //     "snippet":
        //         "WHY CUHK A Unique Learning Experience CUHK in Numbers Studying in Hong Kong Sharing EXPERIENCE CUHK Campus Environment Colleges All-Round Development Events PROGRAMMES New Programmes Individual Programmes CUHK (HK) and CUHK",
        //     "rank": 2
        //   },
        //   {
        //     "title": "香港中文大學 - Chinese University of Hong Kong",
        //     "link": "https://www.cuhk.edu.hk/chinese/index.html",
        //     "snippet":
        //         "香港中文大學是一所研究型綜合大學，提供多類學士、碩士和博士課程。 香港中文大學60周年 策略計劃 2021–2025 高級教學人員徵聘 中大‧環球足跡 中大有晴 校長網誌 香港中文大學（深圳）",
        //     "rank": 2
        //   },
        //   {
        //     "title": "Chinese University of Hong Kong",
        //     "link": "https://portal.cuhk.edu.hk/",
        //     "snippet": "Chinese University of Hong Kong",
        //     "rank": 3
        //   },
        //   {
        //     "title":
        //         "香港中文大學專業進修學院(CUSCS) - 短期課程, 學歷課程, 高級文憑課程, 研究生及學位銜接課程, 遙距課程及網 ...",
        //     "link": "https://cms.scs.cuhk.edu.hk/tc",
        //     "snippet":
        //         "香港中文大學專業進修學院 (CUSCS): 短期課程, 兼讀制學歷課程, 全日制高級文憑課程, 研究生及學位銜接課程, 網上及遙距課程,持續進修基金課程",
        //     "rank": 4
        //   },
        //   {
        //     "title":
        //         "Prospective Students | CUHK - Chinese University of Hong Kong",
        //     "link":
        //         "https://www.cuhk.edu.hk/english/university/prospective-students.html",
        //     "snippet":
        //         "Information about The Chinese University of Hong Kong for local and international prospective students. About CUHK Message from the Vice-Chancellor and President Introducing CUHK Mission & Vision, Motto & Emblem Governance Strategic Plan 2021—2025",
        //     "rank": 5
        //   },
        //   {
        //     "title": "Students | CUHK - Chinese University of Hong Kong",
        //     "link": "https://www.cuhk.edu.hk/english/university/students.html",
        //     "snippet":
        //         "Information about The Chinese University of Hong Kong for current CUHK students. About CUHK Message from the Vice-Chancellor and President Introducing CUHK Mission & Vision, Motto & Emblem Governance Strategic Plan 2021—2025",
        //     "rank": 6
        //   }
        // ];

        break;
      case 'DuckDuckGo':
        String getActualUrl(String url) {
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
        final snippetElements = document.querySelectorAll('.result__snippet');

        // Extract title and URL data
        final titles = titleElements
            .map((element) => element.text.toString().trim())
            .toList();
        final urls = urlElements
            .map((element) =>
                getActualUrl(element.attributes['href'].toString()))
            .toList();
        final snippets = snippetElements
            .map((element) => element.text.toString().trim())
            .toList();

        for (int i = 0; i < titles.length; i++) {
          items.add({
            "title": titles[i],
            "link": cleanUrl(urls[i]),
            "snippet": snippets[i]
                .toString()
                .trim()
                .replaceAll(RegExp(r'(\.\.\.)$'), ""),
            "rank": i + 1
          });
        }

        // *test data
        // items = [
        //   {
        //     "title": "The Chinese University of Hong Kong",
        //     "link": "https://www.cuhk.edu.hk/english/index.html",
        //     "snippet":
        //         "The Chinese University of Hong Kong (CUHK) is a top Hong Kong university with strong research emphasis. The university aims to bring together China and the West.",
        //     "rank": 1
        //   },
        //   {
        //     "title":
        //         "Undergraduate Admissions - The Chinese University of Hong Kong (CUHK)",
        //     "link": "http://admission.cuhk.edu.hk/",
        //     "snippet":
        //         "Undergraduate Admissions - The Chinese University of Hong Kong (CUHK) 11. Professors Named. Most Highly Cited Researchers. 70 +. undergraduate. major programmes. No. 1. Asia Pacific's Most.",
        //     "rank": 2
        //   },
        //   {
        //     "title": "Chinese University of Hong Kong - Wikipedia",
        //     "link":
        //         "https://en.wikipedia.org/wiki/Chinese_University_of_Hong_Kong",
        //     "snippet":
        //         "The Chinese University of Hong Kong (CUHK) is a public research university in Ma Liu Shui, Hong Kong, formally established in 1963 by a charter granted by the Legislative Council of Hong Kong.It is the territory's second-oldest university and was founded as a federation of three existing colleges - Chung Chi College, New Asia College and United College - the oldest of which was founded in ",
        //     "rank": 3
        //   },
        //   {
        //     "title": "Home | CUHK-Shenzhen",
        //     "link": "https://www.cuhk.edu.cn/en",
        //     "snippet":
        //         "CUHK-Shenzhen hosts world's leading scholars and cutting-edge research facilities, fostering an innovative research hub. Learn MORE Research News; Research Fields; Institutes and Laboratories; Scholars; Research Information System; Admissions. Admissions. As China's global university, CUHK-Shenzhen offers first-class education and life ",
        //     "rank": 4
        //   },
        //   {
        //     "title": "Faculty of Arts | Faculties | CUHK",
        //     "link": "https://www.cuhk.edu.hk/english/faculties/arts.html",
        //     "snippet":
        //         "Faculty of Arts. Established in 1963, the same year the Chinese University of Hong Kong was founded, the Faculty of Arts has always been pivotal to CUHK's commitment to integrating Chinese and Western traditions, to bilingual education and innovative interdisciplinary research. Today, CUHK ARTS is the largest Faculty dedicated to humanities ",
        //     "rank": 5
        //   },
        //   {
        //     "title": "Chinese University of Hong Kong in Hong Kong - US News",
        //     "link":
        //         "https://www.usnews.com/education/best-global-universities/chinese-university-of-hong-kong-502973",
        //     "snippet":
        //         "Chinese University of Hong Kong Rankings. # 53. in Best Global Universities. # 5. in Best Global Universities in Asia. # 1. in Best Global Universities in Hong Kong.",
        //     "rank": 6
        //   },
        //   {
        //     "title": "The Chinese University of Hong Kong - LinkedIn",
        //     "link":
        //         "https://www.linkedin.com/school/the-chinese-university-of-hong-kong/",
        //     "snippet":
        //         "The Chinese University of Hong Kong (CUHK) is a research-oriented comprehensive university whose scholarly output and contributions to the community achieve the highest standards of excellence ",
        //     "rank": 7
        //   },
        //   {
        //     "title":
        //         "The Chinese University of Hong Kong - CUHK's Tweets - Twitter",
        //     "link": "https://twitter.com/cuhkofficial",
        //     "snippet":
        //         "The official twitter account for The Chinese University of Hong Kong Connect with us: linktr.ee/CUHK. Education Sha Tin District, Hong Kong cuhk.edu.hk Joined November 2017. 525 Following.",
        //     "rank": 8
        //   },
        //   {
        //     "title": "Chinese University of Hong Kong | UCEAP",
        //     "link":
        //         "https://uceap.universityofcalifornia.edu/programs/chinese-university-hong-kong",
        //     "snippet":
        //         "The CUHK mission is to combine tradition with modernity and bring together China and the West. With faculty and students from all around the world, CUHK is committed to bilingualism, biculturalism, and providing an international study experience. This forward-looking research university has an enviable reputation for quality research that ",
        //     "rank": 9
        //   },
        //   {
        //     "title": "Apply Now - The Chinese University of Hong Kong (CUHK)",
        //     "link":
        //         "http://admission.cuhk.edu.hk/international/application-details.html",
        //     "snippet":
        //         "To facilitate outstanding candidates in making informed decisions among all early offers they receive from various universities, candidates who apply to CUHK on or before 17 November 2022 will be considered for an advance offer. In this round, successful applicants may be given a firm or conditional offer depending on individual merits, and ",
        //     "rank": 10
        //   },
        //   {
        //     "title": "Chinese University of Hong Kong, Shenzhen - Wikipedia",
        //     "link":
        //         "https://en.wikipedia.org/wiki/Chinese_University_of_Hong_Kong,_Shenzhen",
        //     "snippet":
        //         "The Chinese University of Hong Kong, Shenzhen (CUHK-Shenzhen) is a campus of the public research university, the Chinese University of Hong Kong.Located in Shenzhen, on the southern coast of China near Hong Kong, it is a joint venture between the Chinese University of Hong Kong and Shenzhen University, as the local partner. CUHK-Shenzhen was officially founded on 11 October 2012, and approved ",
        //     "rank": 11
        //   },
        //   {
        //     "title": "The Chinese University of Hong Kong (CUHK)",
        //     "link":
        //         "https://www.topuniversities.com/universities/chinese-university-hong-kong-cuhk",
        //     "snippet":
        //         "Mission and Vision. The Chinese University of Hong Kong (CUHK) is a research-oriented comprehensive university whose scholarly output and contributions to the community achieve the highest standards of excellence. Founded in 1963, CUHK has been guided by its mission to assist in the preservation, creation, application and dissemination of knowledge and a global vision to combine tradition with ",
        //     "rank": 12
        //   },
        //   {
        //     "title": "Chinese University of Hong Kong | Global Experiences",
        //     "link": "https://www.abroad.pitt.edu/cuhk",
        //     "snippet":
        //         "THIS PROGRAM IS TEMPORARILY UNAVAILABLE. The Chinese University of Hong Kong (CUHK) (香港中文大學) was founded in 1963 with a mission to combine tradition with modernity and to bring together China and the West.As a comprehensive institution, CUHK has been consistently ranked as one of the top 50 universities in the world by QS World University Ranking as well as one top instituions in Asia.",
        //     "rank": 13
        //   },
        //   {
        //     "title": "CUHK MBA Programmes - CUHK MBA",
        //     "link": "https://mba.cuhk.edu.hk/eng/",
        //     "snippet":
        //         "CUHK Business School was the first in Hong Kong and in the region to offer BBA, MBA and EMBA programmes, with over 40,000 alumni worldwide. We are a global institution that embraces innovation, nurtures an entrepreneurial mindset and promotes social responsibility.",
        //     "rank": 14
        //   },
        //   {
        //     "title": "MY CUHK - Chinese University of Hong Kong",
        //     "link":
        //         "https://portal.cuhk.edu.hk/psp/EPPRD/?cmd=login&languageCd=ENG&",
        //     "snippet":
        //         "Sign in with your organizational account. User Account. Password",
        //     "rank": 15
        //   },
        //   {
        //     "title": "The Chinese University of Hong Kong 香港中文大學 - CUHK",
        //     "link": "https://www.facebook.com/CUHKofficial/",
        //     "snippet":
        //         "The Chinese University of Hong Kong 香港中文大學 - CUHK. 71,637 likes · 29,401 talking about this · 101,944 were here. The official Facebook page of The Chinese University of Hong Kong - CUHK.",
        //     "rank": 16
        //   },
        //   {
        //     "title": "CUHK - HRO - Career Opportunities @ CUHK",
        //     "link":
        //         "https://www.hro.cuhk.edu.hk/en-gb/career/career-opportunities",
        //     "snippet":
        //         "Career Opportunities @ CUHK. Senior Academic Appointments. Vice-Chancellor Early Career Professorship Scheme. Working @ CUHK. Positivity and Staff Wellness. Other Appointments.",
        //     "rank": 17
        //   },
        //   {
        //     "title": "About Us | CUHK-Shenzhen",
        //     "link": "https://www.cuhk.edu.cn/en/about-us",
        //     "snippet":
        //         "About Us. The Chinese University of Hong Kong, Shenzhen （CUHK-Shenzhen）was founded in accordance with the Regulations of the People's Republic of China on Chinese-foreign Cooperation in Running Schools upon approval by the Ministry of Education. The University is committed to providing top-quality higher education that features an ",
        //     "rank": 18
        //   },
        //   {
        //     "title": "Application | Office of Academic Links",
        //     "link": "https://www.oal.cuhk.edu.hk/application/",
        //     "snippet":
        //         'Send the personal particulars page of your passport with your application no. to iasp@cuhk.edu.hk and request for an online debit note by email. The processing time is normally 3 working days. After 3 working days, login to your online application form, view your debit note under "My Task" and pay online.',
        //     "rank": 19
        //   },
        //   {
        //     "title":
        //         "Chinese University of Hong Kong | World University Rankings | THE",
        //     "link":
        //         "https://www.timeshighereducation.com/world-university-rankings/chinese-university-hong-kong",
        //     "snippet":
        //         "Mission and Vision. The Chinese University of Hong Kong (CUHK) is a research-oriented comprehensive university whose scholarly output and contributions to the community achieve the highest standards of excellence. Founded in 1963, CUHK has been guided by its mission to assist in the preservation, creation, application and dissemination of knowledge and a global vision to combine tradition with ",
        //     "rank": 20
        //   },
        //   {
        //     "title":
        //         "The Chinese University of Hong Kong Online Courses | Coursera",
        //     "link": "https://www.coursera.org/cuhk",
        //     "snippet":
        //         "Founded in 1963, The Chinese University of Hong Kong (CUHK) is a forward looking comprehensive research university with a global vision and a mission to combine tradition with modernity, and to bring together China and the West. CUHK teachers and students hail from all corners of the world.",
        //     "rank": 21
        //   },
        //   {
        //     "title": "Academic Staff Directory - CUHK Business School",
        //     "link": "https://www.bschool.cuhk.edu.hk/staff/",
        //     "snippet":
        //         "Honorary Professor of CUHK Business School BCT Distinghished Research Fellow, Institute of Global Economics and Finance. igef@cuhk.edu.hk +852 3943 1660",
        //     "rank": 22
        //   },
        //   {
        //     "title": "CUHK Business School | BBA, MBA & EMBA in Hong Kong",
        //     "link": "https://www.bschool.cuhk.edu.hk/cuhk-business-school/",
        //     "snippet":
        //         "Accreditation. CUHK Business School is one of the first two business schools in Asia accredited by The Association to Advance Collegiate Schools of Business (AACSB). CUHK Business School is accredited by The Association of MBAs (AMBA) for its programmes including EMBA, JD/MBA, MBA, MBA in Finance and MSc in Management.",
        //     "rank": 23
        //   },
        //   {
        //     "title": "CUHK Channel - YouTube",
        //     "link": "https://www.youtube.com/user/CUHKchannel",
        //     "snippet":
        //         "The Chinese University of Hong Kong (CUHK) is a comprehensive research-led university in Hong Kong delivering high-quality education on both undergraduate and postgraduate levels and serving the ",
        //     "rank": 24
        //   },
        //   {
        //     "title":
        //         "CUHK Postgraduate Application - CUHK Graduate School | Postgraduate ...",
        //     "link":
        //         "https://www.gs.cuhk.edu.hk/admissions/admissions/how-to-apply",
        //     "snippet":
        //         "Step 1: Explore CUHK Postgraduate Study Options. Browse the Postgraduate Programme List. Check the Admissions Requirements. Step 2: Prepare for your Application. Prepare the documents/additional information required for application. Check the Application Deadline. (Please refer to individual programme pages for the specific application deadlines.)",
        //     "rank": 25
        //   },
        //   {
        //     "title": "Job Search - Oracle",
        //     "link":
        //         "https://cuhk.taleo.net/careersection/cu_career_teach/jobsearch.ftl?lang=en&portal=10115020119&lang=en",
        //     "snippet":
        //         "Actions. 230000LD. Part-time Instructors (Part-time Programmes -General Courses and other Professional Continuing Education Programmes) School of Continuing and Professional Studies. Apply ‌. Save Job Save Job. Share. 230000LI. Part-time Instructors (Full-time - Higher Diploma and Diploma Programmes)",
        //     "rank": 26
        //   },
        //   {
        //     "title": "The Chinese University of Hong Kong | Piazza",
        //     "link": "https://piazza.com/cuhk.edu.hk",
        //     "snippet":
        //         "Piazza is an intuitive platform for instructors to efficiently manage class Q&A. Students can post questions and collaborate to edit responses to these questions. Instructors can also answer questions, endorse student answers, and edit or delete any posted content. Piazza is designed to simulate real class discussion.",
        //     "rank": 27
        //   }
        // ];

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
          items.add({"title": filteredTitles[i], "link": cleanUrl(urls[i])});
        }

        break;
      case 'YouTube':
        items = jsonResponse['items'] != null
            ? jsonResponse['items'] as List<dynamic>
            : [];
        int i = 1;
        for (var item in items) {
          var videoId = item['id']['videoId'];
          var videoUrl = "https://www.youtube.com/watch?v=$videoId";
          item['title'] = item['snippet']['title'];
          item['link'] = videoUrl;
          item['snippet'] = item['snippet']['description'];
          item['rank'] = i++;
        }

        break;

      case 'Bing Video':
        var results = jsonResponse['value'] != null
            ? jsonResponse['value'] as List<dynamic>
            : [];

        int i = 1;
        for (var result in results) {
          items.add({
            "title": result['name'],
            "link": result['hostPageUrl'],
            "snippet": result['description'],
            "date": result['datePublished'],
            "viewCount": result['viewCount'],
            "rank": i++
          });
        }
        break;
      case 'Vimeo':
        items = jsonResponse['data'] != null
            ? jsonResponse['data'] as List<dynamic>
            : [];

        int i = 1;
        for (var item in items) {
          item['title'] = item['name'];
          item['snippet'] = item['description'];
          item['date'] = item['created_time'];
          item['link'] = item['link'];
          item['rank'] = i++;
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
    log("items: ${items}");

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
    // } else {
    //   log('Request failed with status: ${response.statusCode}.');

    //   // ignore: use_build_context_synchronously
    //   await showDialog(
    //       context: context,
    //       builder: (BuildContext context) {
    //         return AlertDialog(
    //           title: const Text("Request Failed"),
    //           content: Text("Status Code: ${response.statusCode}."),
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
    // return null;
    //   }
    // } else {
    //   log("GG");
    // }

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

              if (_currentSearchPlatform == "General" &&
                  (_mergeAlgorithm == "Original Rank" ||
                      _mergeAlgorithm == "Further Merge")) {
                URLs[keyword][platform]["original"] = list;
              }

              log("URLs[keyword] ${URLs[keyword]}");

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

  void _updateIsTutorial(status) {
    if (!status) {
      _tutorial.finish();
    }

    setState(() {
      _isTutorial = status;
    });
    log("_currentImage $_currentImage");
  }

  void _updateEnabledPlatforms(type, list) {
    if (type == "General") {
      setState(() {
        _enabledGeneralPlatforms = list;
      });
    } else if (type == "Video") {
      setState(() {
        _enabledVideoPlatforms = list;
      });
    } else if (type == "SNS") {
      setState(() {
        _enabledSNSPlatforms = list;
      });
    }
    log("type: $type | list: $list");
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
    SharedPreferences prefs = await SharedPreferences.getInstance();

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
            isTutorial: _isTutorial,
            updateIsTutorial: _updateIsTutorial,
            // generalPlatformList: GeneralPlatformList,
            // videoPlatformList: VideoPlatformList,
            // SNSPlatformList: SNSPlatformList,
            enabledGeneralPlatforms: _enabledGeneralPlatforms,
            enabledVideoPlatforms: _enabledVideoPlatforms,
            enabledSNSPlatforms: _enabledSNSPlatforms,
            updateEnabledPlatforms: _updateEnabledPlatforms,
            prefs: prefs,
          );
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

  void _updateVideoMergeAlgorithm(algorithm) {
    setState(() {
      _videoMergeAlgorithm = algorithm;
    });
  }

  void _updatePreloadNumber(preloadNumber) {
    setState(() {
      _preloadNumber = preloadNumber;
    });
  }

  void _updateAutoSwitchPlatform(value) {
    setState(() {
      _autoSwitchPlatform = value;
    });
  }

  void _updateReverseJoystick(value) {
    setState(() {
      _reverseJoystick = value;
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
            updateGeneralMergeAlgorithm: _updateMergeAlgorithm,
            updateVideoMergeAlgorithm: _updateVideoMergeAlgorithm,
            generalMergeAlgorithm: _mergeAlgorithm,
            videoMergeAlgorithm: _videoMergeAlgorithm,
            SearchAlgorithmList: SearchAlgorithmList,
            MergeAlgorithmList: MergeAlgorithmList,
            VideoMergeAlgorithmList: VideoMergeAlgorithmList,
            updatePreloadNumber: _updatePreloadNumber,
            preloadNumber: _preloadNumber,
            updateAutoSwitchPlatform: _updateAutoSwitchPlatform,
            autoSwitchPlatform: _autoSwitchPlatform,
            updateReverseJoystick: _updateReverseJoystick,
            reverseJoystick: _reverseJoystick,
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
          status: "Performing Text Detection",
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

    keyword = "$currentSearchText ${keyword.trim()}";
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
                    // icon: const FaIcon(FontAwesomeIcons.xmark, size: 20),
                    icon: const Icon(
                      FontAwesome.xmark,
                      size: 20,
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      log("select all");

                      Navigator.pop(context);

                      setState(() {
                        _menuShown = false;
                      });
                    },
                    // icon: const FaIcon(FontAwesomeIcons.borderAll, size: 20),
                    icon: const Icon(
                      FontAwesome.border_all,
                      size: 20,
                    ),
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
                    // icon: const FaIcon(FontAwesomeIcons.copy, size: 20),
                    icon: const Icon(
                      FontAwesome.copy,
                      size: 20,
                    ),
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

  // _getWebpageHash(String link) async {
  //   var response = await http.get(Uri.parse(link));
  //   // log("hash0: ${response.statusCode}");
  //   if (response.statusCode == 200) {
  //     // Parse the HTML content
  //     var document = parse(response.body);
  //     // log("document: ${document.outerHtml}");

  //     // // Inspect the meta-refresh tag
  //     // var metaRefreshTag = document.querySelector('meta[http-equiv="Refresh"]');
  //     // log("metaRefreshTag: $metaRefreshTag");
  //     // if (metaRefreshTag != null) {
  //     //   // Extract the "content" attribute value, which contains the redirect URL
  //     //   var content = metaRefreshTag.attributes['content'];

  //     //   // Extract the URL from the "content" attribute value
  //     //   var redirectUrl = content?.split(';')[1].trim().substring(4);

  //     //   // The web page is being client-side redirected
  //     //   print('Redirect URL: $redirectUrl');
  //     // }

  //     // Convert the content to string
  //     String content = utf8.decode(response.bodyBytes);
  //     // log("hash1: $content");

  //     // Generate an MD5 hash of the content
  //     var hash = md5.convert(utf8.encode(content));
  //     log("hash: $hash | link: $link");
  //     return hash;

  //     // Return the hexadecimal representation of the hash
  //     // return hash.toString();
  //   } else {
  //     throw Exception(
  //         'Failed to fetch web page content: ${response.statusCode}');
  //   }
  // }

  _toggleGeneralResults(String type) async {
    log("type: $type |${URLs[_searchText][_currentSearchPlatform]['original']}");
    List current = URLs[_searchText][_currentSearchPlatform]['original'];
    if (type == "All") {
      setState(() {
        URLs[_searchText][_currentSearchPlatform]["list"] = current;
      });
    } else if (type == "Duplicated") {
      List temp = [];
      for (int i = 0; i < current.length; i++) {
        if (!current[i]["unique"]) {
          temp.add(current[i]);
        }
      }
      log("dup: $temp");
      setState(() {
        URLs[_searchText][_currentSearchPlatform]["list"] = temp;
      });
    } else if (type == "Unique") {
      List temp = [];
      for (int i = 0; i < current.length; i++) {
        if (current[i]["unique"]) {
          temp.add(current[i]);
        }
      }
      log("uni: $temp");

      setState(() {
        URLs[_searchText][_currentSearchPlatform]["list"] = temp;
      });
    }

    await _updateCurrentURLs();
    await _moveSwiper();
  }

  _mergeSearch(String type) async {
    Map platforms = {};
    switch (type) {
      case "General":
        // platforms = {
        //   "Google": {},
        //   "Bing": {},
        //   "DuckDuckGo": {},
        //   // "Yahoo": {},
        // };
        for (int i = 0; i < _enabledGeneralPlatforms.length; i++) {
          platforms.addAll({_enabledGeneralPlatforms[i]: ""});
        }
        break;
      case "Video":
        // platforms = {
        //   "YouTube": {},
        //   "Bing Video": {},
        //   "Vimeo": {},
        // };
        for (int i = 0; i < _enabledVideoPlatforms.length; i++) {
          platforms.addAll({_enabledVideoPlatforms[i]: ""});
        }
        break;
      case "SNS":
        // platforms = {
        //   "Twitter": {},
        //   "Facebook": {},
        //   "Instagram": {},
        //   "LinkedIn": {},
        // };
        for (int i = 0; i < _enabledSNSPlatforms.length; i++) {
          platforms.addAll({_enabledSNSPlatforms[i]: ""});
        }
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

    frequencyMerge() {
      log("frqeuency merge");
      // merge identical results
      Map webpageFrequency = {};
      for (int i = 0; i < mergedResults.length; i++) {
        if (webpageFrequency[mergedResults[i]["link"]] == null) {
          webpageFrequency[mergedResults[i]["link"]] = 1;
        } else {
          webpageFrequency[mergedResults[i]["link"]] += 1;
        }
      }

      List<MapEntry> entries = webpageFrequency.entries.toList();
      entries.sort(
          (a, b) => b.value.compareTo(a.value)); // sort in descending order
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
      log("merged: ${finalSortedList.length} / ${mergedResults.length} ${finalSortedList.length / mergedResults.length}");

      final snackBar = SnackBar(
        content: Text(
            "From ${mergedResults.length} to ${finalSortedList.length} | ${finalSortedList.length / mergedResults.length}"),
        duration: const Duration(seconds: 3),
      );
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

      return finalSortedList;
    }

    rankMerge() {
      log("rank merge");

      /*
          base score: no. of all results / no. of platforms
          score per result: base score / rank

          http://admission.cuhk.edu.hk: {snippet: Undergraduate Admissions - The Chinese University of Hong Kong (CUHK) 11. Professors Named. Most Highly Cited Researchers. 70 +. undergraduate. major programmes. No. 1. Asia Pacific's Most., rank: [3], score: 4.888888888888888},
          https://admission.cuhk.edu.hk: {snippet: Getting Started · See Yourself in Us · Where Your Dream Can Be Found · A Day in CUHK · News and Activities., rank: [5], score: 2.933333333333333}

          */

      Map webpageScore = {};
      double baseScore = mergedResults.length / platforms.length;
      log("baseScore: $baseScore");

      // for every appearance, score will be added
      for (int i = 0; i < mergedResults.length; i++) {
        if (webpageScore[mergedResults[i]["link"]] == null) {
          webpageScore[mergedResults[i]["link"]] = {
            "snippet": mergedResults[i]["snippet"],
            "rank": [mergedResults[i]["rank"]],
            "score": baseScore / mergedResults[i]["rank"]
          };
        } else {
          webpageScore[mergedResults[i]["link"]] = {
            "snippet": mergedResults[i]["snippet"],
            "rank": [
              ...webpageScore[mergedResults[i]["link"]]["rank"],
              mergedResults[i]["rank"]
            ],
            "score": webpageScore[mergedResults[i]["link"]]["score"] +
                (baseScore / mergedResults[i]["rank"])
          };
        }
      }

      // sort in descending order
      List<MapEntry> entries = webpageScore.entries.toList();
      entries.sort((a, b) => b.value["score"].compareTo(a.value["score"]));
      Map sortedWebpageScore = Map.fromEntries(entries);

      log("webpageScore: $webpageScore");
      log("sortedWebpageScore: $sortedWebpageScore");

      // add them to final results
      List links = sortedWebpageScore.keys.toList();
      List finalSortedList = [];
      for (int i = 0; i < sortedWebpageScore.length; i++) {
        finalSortedList.add({
          "title": mergedResults
              .firstWhere((element) => element["link"] == links[i])["title"],
          "link": links[i],
          "unique":
              sortedWebpageScore[links[i]]["rank"].length == 1 ? true : false,
        });
      }

      log("finalSortedList: $finalSortedList");
      log("merged: ${finalSortedList.length} / ${mergedResults.length} ${finalSortedList.length / mergedResults.length}");

      final snackBar = SnackBar(
        content: Text(
            "Merged ${mergedResults.length - finalSortedList.length} results | ${((finalSortedList.length / mergedResults.length) * 100).toStringAsFixed(2)}%"),
        duration: const Duration(seconds: 3),
      );
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return finalSortedList;
    }

    furtherMerge() {
      log("further merge");

      Map webpageScore = {};
      double baseScore = mergedResults.length / platforms.length;
      log("baseScore: $baseScore");

      // for every appearance, score will be added
      for (int i = 0; i < mergedResults.length; i++) {
        if (webpageScore[mergedResults[i]["link"]] == null) {
          webpageScore[mergedResults[i]["link"]] = {
            "snippet": mergedResults[i]["snippet"],
            "rank": [mergedResults[i]["rank"]],
            "score": baseScore / mergedResults[i]["rank"],
            "title": [mergedResults[i]["title"]],
          };
        } else {
          webpageScore[mergedResults[i]["link"]] = {
            "snippet": mergedResults[i]["snippet"],
            "rank": [
              ...webpageScore[mergedResults[i]["link"]]["rank"],
              mergedResults[i]["rank"]
            ],
            "score": webpageScore[mergedResults[i]["link"]]["score"] +
                (baseScore / mergedResults[i]["rank"]),
            "title": [mergedResults[i]["title"]],
          };
        }
      }

      Iterable keys = webpageScore.keys;

      log("test $keys");

      for (int i = 0; i < keys.length; i++) {
        var current = keys.elementAt(i);
        var shortCurrent = current
            .toString()
            .replaceFirst(RegExp(r'^(http:\/\/)|^(https:\/\/)'), "");
        // log("current $current");
        for (int j = i + 1; j < webpageScore.length; j++) {
          var compare = keys.elementAt(j);
          var shortCompare = compare
              .toString()
              .replaceFirst(RegExp(r'^(http:\/\/)|^(https:\/\/)'), "");
          // log("compare $compare");

          // log("regex ${current.toString().replaceFirst(RegExp(r'^(http:\/\/)|^(https:\/\/)'), "")}");

          if (shortCurrent == shortCompare) {
            log("same merged: ${current} ${compare}");
            if (current.length > compare.length) {
              webpageScore.update(
                current,
                (value) => {
                  "rank": [
                    ...webpageScore[current]["rank"],
                    ...webpageScore[compare]["rank"]
                  ],
                  "score": webpageScore[current]["score"] +
                      webpageScore[compare]["score"],
                  "snippet": webpageScore[current]["snippet"],
                  "title": webpageScore[current]["title"],
                },
              );

              webpageScore.update(
                compare,
                (value) => {
                  "rank": [0],
                  "score": 0,
                  "snippet": webpageScore[compare]["snippet"],
                  "title": webpageScore[compare]["title"],
                },
              );
            } else if (compare.length > current.length) {
              webpageScore.update(
                compare,
                (value) => {
                  "rank": [
                    ...webpageScore[current]["rank"],
                    ...webpageScore[compare]["rank"]
                  ],
                  "score": webpageScore[current]["score"] +
                      webpageScore[compare]["score"],
                  "snippet": webpageScore[compare]["snippet"],
                  "title": webpageScore[compare]["title"],
                },
              );

              webpageScore.update(
                current,
                (value) => {
                  "rank": [0],
                  "score": 0,
                  "snippet": webpageScore[current]["snippet"],
                  "title": webpageScore[current]["title"],
                },
              );
            }
          }
          // keep the longer one (longest prefix match)
          else if (shortCompare.contains(shortCurrent)) {
            // log("same 1 $current(${webpageScore[current]['rank'][0]}) is substring of $compare(${webpageScore[compare]['rank'][0]})");
            // log("same 1 $current(${webpageScore[current]['title']}) is substring of $compare(${webpageScore[compare]['title']})");

            if (webpageScore[current]['snippet'].toString().trim().contains(
                    webpageScore[compare]['snippet'].toString().trim()) ||
                webpageScore[compare]['snippet'].toString().trim().contains(
                    webpageScore[current]['snippet'].toString().trim())) {
              log("same merged 1: $current(${webpageScore[current]['snippet'].toString().trim()}) is substring of $compare(${webpageScore[compare]['snippet'].toString().trim()})");
              // log("real same 1.1 ${webpageScore[current]['snippet'].toString().trim().contains(webpageScore[compare]['title'].toString().trim())}");
              // log("real same 1.2 ${webpageScore[compare]['snippet'].toString().trim().contains(webpageScore[current]['title'].toString().trim())}");

              log("same merged 1.1: ${current} ${compare}}");

              webpageScore.update(
                compare,
                (value) => {
                  "rank": [
                    ...webpageScore[current]["rank"],
                    ...webpageScore[compare]["rank"]
                  ],
                  "score": webpageScore[current]["score"] +
                      webpageScore[compare]["score"],
                  "snippet": webpageScore[compare]["snippet"],
                  "title": webpageScore[compare]["title"],
                },
              );

              webpageScore.update(
                current,
                (value) => {
                  "rank": [0],
                  "score": 0,
                  "snippet": webpageScore[current]["snippet"],
                  "title": webpageScore[current]["title"],
                },
              );
            }
          } else if (shortCurrent.contains(shortCompare)) {
            // log("same 2 $current(${webpageScore[current]['rank'][0]}) is substring of $compare(${webpageScore[compare]['rank'][0]})");

            if (webpageScore[current]['snippet'].toString().trim().contains(
                    webpageScore[compare]['snippet'].toString().trim()) ||
                webpageScore[compare]['snippet'].toString().trim().contains(
                    webpageScore[current]['snippet'].toString().trim())) {
              // log("real same 2 $current(${webpageScore[current]['snippet'].toString().trim()}) is substring of $compare(${webpageScore[compare]['snippet'].toString().trim()})");
              // log("real same 2.1 ${webpageScore[current]['snippet'].toString().trim().contains(webpageScore[compare]['snippet'].toString().trim())}");
              // log("real same 2.2 ${webpageScore[compare]['snippet'].toString().trim().contains(webpageScore[current]['snippet'].toString().trim())}");

              log("same merged 2.1: $compare(${webpageScore[compare]['snippet'].toString().trim()}) is substring of $compare(${webpageScore[compare]['snippet'].toString().trim()})");

              log("same merged 2.2: ${current} ${compare}}");
              webpageScore.update(
                current,
                (value) => {
                  "rank": [
                    ...webpageScore[current]["rank"],
                    ...webpageScore[compare]["rank"]
                  ],
                  "score": webpageScore[current]["score"] +
                      webpageScore[compare]["score"],
                  "snippet": webpageScore[current]["snippet"],
                  "title": webpageScore[current]["title"],
                },
              );

              webpageScore.update(
                compare,
                (value) => {
                  "rank": [0],
                  "score": 0,
                  "snippet": webpageScore[compare]["snippet"],
                  "title": webpageScore[compare]["title"],
                },
              );
            }
          }
        }
      }

      // remove the duplicate results as it has been merged above
      webpageScore.removeWhere((key, value) => value["rank"][0] == 0);

      // sort in descending order
      List<MapEntry> entries = webpageScore.entries.toList();
      entries.sort((a, b) => b.value["score"].compareTo(a.value["score"]));
      Map sortedWebpageScore = Map.fromEntries(entries);

      log("webpageScore: $webpageScore");
      log("sortedWebpageScore: $sortedWebpageScore");

      // add them to final results
      List links = sortedWebpageScore.keys.toList();
      List finalSortedList = [];
      for (int i = 0; i < sortedWebpageScore.length; i++) {
        finalSortedList.add({
          "title": mergedResults
              .firstWhere((element) => element["link"] == links[i])["title"],
          "link": links[i],
          "unique":
              sortedWebpageScore[links[i]]["rank"].length == 1 ? true : false,
        });
      }

      log("finalSortedList: $finalSortedList");
      log("merged: ${finalSortedList.length} / ${mergedResults.length} ${finalSortedList.length / mergedResults.length}");

      final snackBar = SnackBar(
        content: Text(
            "Merged ${mergedResults.length - finalSortedList.length} results | ${((finalSortedList.length / mergedResults.length) * 100).toStringAsFixed(2)}%"),
        duration: const Duration(seconds: 3),
      );
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return finalSortedList;
    }

    if (type == "General") {
      switch (_mergeAlgorithm) {
        case "ABAB":
          log("merge algo ABAB");
          return mergedResults;

        case "Frequency":
          log("merge algo freq");

          return frequencyMerge();
        case "Original Rank":
          log("merge algo rank");

          return rankMerge();
        case "Further Merge":
          log("merge algo further");

          return furtherMerge();
      }

      return mergedResults;
    } else if (type == "Video") {
      switch (_videoMergeAlgorithm) {
        case "ABAB":
          log("merge algo ABAB");
          return mergedResults;

        case "Frequency":
          log("merge algo freq");

          return frequencyMerge();
        case "Original Rank":
          log("merge algo rank");

          return rankMerge();
      }

      return mergedResults;
    } else if (type == "SNS") {
      // switch (_videoMergeAlgorithm) {
      //   case "ABAB":
      //     log("merge algo ABAB");
      //     return mergedResults;

      //   case "Frequency":
      //     log("merge algo freq");

      //     return frequencyMerge();
      //   case "Original Rank":
      //     log("merge algo rank");

      //     return rankMerge();
      // }

      return mergedResults;
    }
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
          leading:
              // const FaIcon(
              //   FontAwesomeIcons.arrowTrendDown,
              //   size: 18,
              //   color: Colors.black87,
              // ),
              const Icon(FontAwesome.arrow_trend_down, size: 18),

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
      case "General":
        return const Icon(HeroIcons.globe_alt, size: 24);
      case "Video":
        return const Icon(BoxIcons.bx_video, size: 24);
      case "SNS":
        return const Icon(Icons.connect_without_contact, size: 24);

      case "Google":
        return const Icon(BoxIcons.bxl_google, size: 24);
      case "Bing":
        return const Icon(BoxIcons.bxl_bing, size: 24);
      case "DuckDuckGo":
        return const Icon(DuckDuckGo.duckduckgo, size: 20);

      case "YouTube":
        return const Icon(BoxIcons.bxl_youtube, size: 24);
      case "Bing Video":
        return const Icon(BoxIcons.bxl_bing, size: 24);
      case "Vimeo":
        return const Icon(BoxIcons.bxl_vimeo, size: 24);

      case "Twitter":
        return const Icon(BoxIcons.bxl_twitter, size: 24);
      case "Facebook":
        return const Icon(BoxIcons.bxl_facebook, size: 24);
      case "Instagram":
        return const Icon(BoxIcons.bxl_instagram, size: 24);
      case "LinkedIn":
        return const Icon(BoxIcons.bxl_linkedin, size: 24);

      // case "Yahoo":
      //   return const Icon(BoxIcons.bxl_yahoo, size: 24);
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
                    child:
                        // FloatingActionButton(
                        //   onPressed: () {
                        //     log("fab tapped");
                        //     // _changeSearchPlatform();

                        //     // // count down 5 seconds
                        //     // if (_autoSwitchPlatform == 1) {
                        //     //   if (_platformActivationTimer == null) {
                        //     //     _platformActivationTimer = RestartableTimer(
                        //     //         const Duration(seconds: 2), () async {
                        //     //       _normalSearch();
                        //     //     });
                        //     //   } else {
                        //     //     _platformActivationTimer!.reset();
                        //     //   }
                        //     // }
                        //   },
                        //   // label: Text(_currentSearchPlatform),
                        //   backgroundColor: _fabColor,
                        //   splashColor: Colors.amber[100],
                        //   child: const Icon(MyFlutterApp.drill),
                        //   // child: AnimatedBuilder(
                        //   //   animation: _drillingAnimationController,
                        //   //   builder: (_, child) {
                        //   //     return Transform.rotate(
                        //   //       angle: _drilling
                        //   //           ? _drillingAnimationController.value *
                        //   //               2 *
                        //   //               math.pi
                        //   //           : 0.0,
                        //   //       child: child,
                        //   //     );
                        //   //   },
                        //   //   child: const Icon(MyFlutterApp.drill),
                        //   // ),
                        // ),
                        SpeedDial(
                      spacing: 10,
                      spaceBetweenChildren: 10,
                      openCloseDial: _isDialOpen,
                      // icon: Icons.add,
                      icon: MyFlutterApp.drill,
                      activeIcon: Icons.close,
                      // onOpen: () => debugPrint('OPENING DIAL'),
                      // onClose: () => debugPrint('DIAL CLOSED'),
                      children: _currentSearchPlatform == "General" &&
                              (_mergeAlgorithm == "Original Rank" ||
                                  _mergeAlgorithm == "Further Merge")
                          ? [
                              SpeedDialChild(
                                child: const Icon(BoxIcons.bx_refresh),
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                label: 'Refresh',
                                // visible: true,
                                onTap: () {
                                  log("fab pressed");
                                  _normalSearch(false, true);
                                },
                              ),
                              SpeedDialChild(
                                child: const Icon(BoxIcons.bx_border_all),
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                label: 'All',
                                onTap: () {
                                  debugPrint('FIRST CHILD LONG PRESS');
                                  _toggleGeneralResults("All");
                                },
                              ),
                              SpeedDialChild(
                                child: const Icon(BoxIcons.bx_duplicate),
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                label: 'Duplicated',
                                onTap: () {
                                  debugPrint('SECOND CHILD');
                                  _toggleGeneralResults("Duplicated");
                                },
                              ),
                              SpeedDialChild(
                                child: const Icon(FontAwesome.fingerprint),
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                label: 'Unique',
                                // visible: true,
                                onTap: () {
                                  debugPrint('SECOND CHILD');
                                  _toggleGeneralResults("Unique");
                                },
                              ),
                            ]
                          : [
                              SpeedDialChild(
                                child: const Icon(BoxIcons.bx_refresh),
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                label: 'Refresh',
                                // visible: true,
                                onTap: () {
                                  log("fab pressed");
                                  _normalSearch(false, true);
                                },
                              ),
                            ],
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
                              // if (_currentImage != null)
                              //   Positioned(
                              //     top: 0,
                              //     child: Image.file(
                              //       File(_currentImage.path),
                              //       fit: BoxFit.cover,
                              //       width: MediaQuery.of(context).size.width,
                              //       height: MediaQuery.of(context).size.height,
                              //     ),
                              //   ),

                              // TabBar(
                              //   tabs: [
                              //     Tab(icon: Icon(Icons.directions_car)),
                              //     Tab(icon: Icon(Icons.directions_transit)),
                              //     Tab(icon: Icon(Icons.directions_bike)),
                              //   ],
                              // ),
                              // Positioned(
                              //   top: 0,
                              //   width: MediaQuery.of(context).size.width,
                              //   child: Padding(
                              //     padding: const EdgeInsets.only(
                              //         left: 16.0, right: 16.0, bottom: 16.0),
                              //     child: SegmentedButton(
                              //       // key: _platformsKey,
                              //       segments: GeneralResultType.map(
                              //         (e) => ButtonSegment(
                              //           value: e,
                              //           label: Text(e),
                              //           // icon: widget.platformIconBuilder(e),
                              //         ),
                              //       ).toList(),
                              //       selected: {_generalResultType},
                              //       onSelectionChanged: (newSelection) {
                              //         log("newSelection $newSelection");

                              //         setState(() {
                              //           // By default there is only a single segment that can be
                              //           // selected at one time, so its value is always the first
                              //           // item in the selected set.
                              //           _generalResultType =
                              //               newSelection.first.toString();
                              //         });
                              //       },
                              //     ),
                              //   ),
                              // ),

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
                                                    icon:
                                                        // FaIcon(
                                                        //   FontAwesomeIcons.stairs,
                                                        //   size: 20,
                                                        // ),
                                                        const Icon(
                                                            FontAwesome.stairs,
                                                            size: 20),
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
                                                    icon:
                                                        // const FaIcon(
                                                        //   FontAwesomeIcons
                                                        //       .backwardFast,
                                                        //   size: 20,
                                                        // ),
                                                        const Icon(
                                                            FontAwesome
                                                                .backward_fast,
                                                            size: 20),
                                                  ),
                                                  IconButton(
                                                    key: _backButtonKey,
                                                    onPressed: () async {
                                                      await _currentWebViewController!
                                                          .goBack();
                                                    },
                                                    icon:
                                                        // const FaIcon(
                                                        //     FontAwesomeIcons
                                                        //         .arrowLeft,
                                                        //     size: 20),
                                                        const Icon(
                                                            FontAwesome
                                                                .arrow_left,
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
                                                    icon:
                                                        // const FaIcon(
                                                        //     FontAwesomeIcons
                                                        //         .shareNodes,
                                                        //     size: 20),

                                                        const Icon(
                                                            FontAwesome
                                                                .share_nodes,
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
                                    var posX = _reverseJoystick
                                        ? details.x * -1
                                        : details.x;
                                    if (posX > 0.5) {
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
                                    } else if (posX < -0.5) {
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
        // 'https://api.bing.microsoft.com/v7.0/images/visualsearch?mkt=en-US');
        'https://api.bing.microsoft.com/v7.0/images/visualsearch?mkt=zh-HK&setLang=EN');
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

    // if (response.statusCode == 200) {
    //   final responseJson = jsonDecode(responseString);
    //   imageToken = responseJson['image']['imageInsightsToken'];

    //   final elements = responseJson['tags'][0]['actions'];
    //   var bingVisualObject;
    //   var bingVisualQuery = null;
    //   var bingIncludedPage = null;
    //   var bingBestRepresentation = null;
    //   var bingIncludedName = null;

    //   print("response code ${response.statusCode}");
    //   elements.forEach((data) => {
    //         if (data['actionType'] == "VisualSearch")
    //           {bingVisualObject = data['data']['value']}
    //       });
    //   elements.forEach((data) => {
    //         if (data['actionType'] == "RelatedSearches")
    //           {bingVisualQuery = data['data']['value']}
    //       });
    //   elements.forEach((data) => {
    //         if (data['actionType'] == "PagesIncluding")
    //           {bingIncludedPage = data['data']['value']}
    //       });
    //   elements.forEach((data) => {
    //         if (data['actionType'] == "BestRepresentativeQuery")
    //           {bingBestRepresentation = data['displayName']}
    //       });
    //   print("Bing gust: ${bingBestRepresentation}");

    //   if (bingIncludedPage.length != 0) {
    //     bingIncludedName = bingIncludedPage[0]['name'].toString();
    //     bingIncludedPage.forEach((value) async {
    //       // final isShopping = isShoppingWebsite(value['hostPageUrl']);
    //       // if (isShopping) {
    //       //   shoppingResult.add(value['hostPageUrl']);
    //       // }

    //       Result.add({
    //         'title': value['name'].toString(),
    //         'link': value['hostPageUrl'].toString(),
    //       });
    //       PageIncludedImage.add({
    //         'title': value['name'].toString(),
    //         'thumbnail': value['thumbnailUrl'].toString(),
    //         'website': value['hostPageUrl'].toString(),
    //       });
    //     });
    //   }

    //   bingVisualObject.forEach((value) async {
    //     // print("fetch URL: ==============");
    //     //  print("Website name: ${value['name']}");
    //     // print("website: ${value['hostPageUrl']}");

    //     // final isShopping = isShoppingWebsite(value['hostPageUrl']);
    //     // if (isShopping) {
    //     //   shoppingResult.add(value['hostPageUrl']);
    //     // }
    //     // print('Is the URL a shopping website? $isShopping');

    //     Result.add({
    //       'title': value['name'].toString(),
    //       'link': value['hostPageUrl'].toString(),
    //     });
    //   });

    //   List bestGuessList = [];

    //   if (bingVisualQuery != null) {
    //     bingVisualQuery.forEach((value) async {
    //       // print("Query name: ${value['text']}");
    //       //bestGuessLabel.add(value['text']);

    //       bestGuessList.add({
    //         'bestGuessLabel': value['text'],
    //         'urls': value['thumbnail']['url'],
    //       });
    //     });

    //     if (PageIncludedImage.length > 0) {
    //       bestGuessLabel.add(bingIncludedName);
    //     } else {
    //       // print("NULL bestGuessLabel");
    //       if (bingBestRepresentation != null) {
    //         bestGuessLabel.add(bingBestRepresentation);
    //       } else {
    //         bestGuessLabel.add(bingVisualQuery[0]['displaytext']);
    //         // results.addAll({'BestGuessList': bestGuessList});
    //       }

    //       // if (bestGuessLabel == null) {
    //       //    bestGuessLabel.add(bingBestRepresentation);
    //       //  }
    //     }

    //     print(bestGuessLabel);
    //     results.addAll({'bestGuessList': bestGuessList});
    //     print(bestGuessList);
    //   }
    // } else {
    //   print('Failed to upload image. Error code: ${response.statusCode}');
    // }

    // print("Bing: ${results['bestGuessLabel']}");

    // print("results ${shoppingResult}");
    // if (PageIncludedImage != null) {
    //   results.addAll({'urls': PageIncludedImage});
    // }

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
            bestGuessLabel.add(bingVisualObject[0]['name']);
            // results.addAll({'BestGuessList': bestGuessList});
          }
        }

        print(bestGuessLabel);
        results.addAll({'bestGuessList': bestGuessList});
        print(bestGuessList);
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
      if (bestGuessLabel.length <= 0) {
        bestGuessLabel.add(bingVisualObject[0]['name']);
      }
    } else {
      print('Failed to upload image. Error code: ${response.statusCode}');
    }

    // print("Bing: ${results['bestGuessLabel']}");

    // print("results ${shoppingResult}");
    // if (PageIncludedImage != null) {
    //   results.addAll({'urls': PageIncludedImage});
    // }
    //   results.addAll({'urls': Result});

    //   return results;
    // }
    results.addAll({'urls': Result});

    return results;
  }

  var bingVisualResult = BingSearch(path, img64);
  return bingVisualResult;
}
