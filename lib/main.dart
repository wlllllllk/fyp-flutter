import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fyp_searchub/pages/history.dart';
import 'package:fyp_searchub/pages/search.dart';
import 'package:fyp_searchub/pages/settings.dart';

import 'package:webview_flutter/webview_flutter.dart';
import 'package:card_swiper/card_swiper.dart';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import 'package:duration/duration.dart';
import 'package:async/async.dart';
import 'dart:math' as math;
// import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marquee/marquee.dart';
// import 'package:google_vision/google_vision.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:scroll_snap_list/scroll_snap_list.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:context_menus/context_menus.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:pie_menu/pie_menu.dart';

// import 'package:rake/rake.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

import 'my_flutter_app_icons.dart';

part 'main.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
  //   await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  // }

  runApp(
    MaterialApp(
      theme: ThemeData(
          // colorSchemeSeed: Color.fromARGB(255, 49, 83, 97),
          useMaterial3: true),
      home: WebViewContainer(),
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
  "New Mode",
  "TEST HIGHLIGHT"
];

List<String> SearchPlatformList = [
  "Google",
  "YouTube",
  "Twitter",
  "Facebook",
  "Instagram",
  "LinkedIn"
];

enum Theme { Light, Dark, Auto }

// const API_KEY = "AIzaSyDMa-bYzmjOHJEZdXxHOyJA55gARPpqOGw";
// const API_KEY = "AIzaSyD48Vtn0yJnAIU6SyoIkPJQg3xWKax48dw"; //old
const API_KEY = "AIzaSyD3D4sYkKkWOsSdFxTywO-0VX5GIfJSBZc"; //old
const SEARCH_ENGINE_ID_GOOGLE = "35fddaf2d5efb4668";
const SEARCH_ENGINE_ID_YOUTUBE = "07e66762eb98c40c8";
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
  var _searchAlgorithm;
  var _preloadNumber;
  var _autoSwitchPlatform;
  var _theme;

  // key
  var _marqueeKey = UniqueKey();
  var _settingsPageKey = UniqueKey();
  final _preloadPageKeys = [];
  var _currentPreloadPageKey;
  final _preloadPlatformKey = GlobalKey();

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
  Map URLs = {};
  String _searchText = "";
  bool _isSearching = false;
  Map _searchResult = {};
  List _currentURLs = [];
  String _currentSearchPlatform = "";
  int _currentURLIndex = 0;
  int _loadingPercentage = 0;
  String _previousURL = "";
  int _selectedPageIndex = 0;
  String _webpageContent = "";
  bool _gg = false;
  int _searchCount = 0;
  String _currentWebViewTitle = "";
  final Map _searchHistory = {};
  Map _activatedSearchPlatforms = {};

  //stopwatch
  final activityStopwatch = Stopwatch();
  // final _redirectStopwatch = Stopwatch();

  // colours
  Color _defaultAppBarColor = Colors.white;
  Color _appBarColor = Colors.blue[100]!;
  Color _themedAppBarColor = Colors.blue[100]!;
  Color _fabColor = Colors.blue[100]!;

  // ?maybe useful
  // bool _swipe = false;
  // bool _redirecting = false;
  // bool _drilling = false;

  // List _activatedSearchPlatformKeys = [GlobalKey()];
  // final rake = Rake();

  // others
  bool _menuShown = false;
  bool _isFetching = false;

  // positions
  double _hoverX = 0.0, _hoverY = 0.0;
  double _scrollX = 0.0, _scrollY = 0.0;
  double _joystickX = 0, _joystickY = 0;

  // include only first page
  // counting start, (page=2) => (start=11), (page=3) => (start=21), etc
  int _start = (page - 1) * 10 + 1;

  // var _testPreloadPageKey = GlobalKey();

  void _init() async {
    final prefs = await SharedPreferences.getInstance();
    // final algorithm = await prefs.getInt("searchAlgorithm") ?? SearchAlgorithm.Title.index;
    final algorithm =
        await prefs.getString("searchAlgorithm") ?? SearchAlgorithmList[0];
    final preloadNumber = await prefs.getInt("preloadNumber") ?? 1;
    final autoSwitchPlatform = await prefs.getInt("autoSwitchPlatform") ?? 0;
    final theme = await prefs.getInt("theme") ?? Theme.Light.index;
    setState(() {
      _currentSearchPlatform = "Google";
      _searchAlgorithm = algorithm;
      _preloadNumber = preloadNumber;
      _autoSwitchPlatform = autoSwitchPlatform;
      _theme = theme;
    });
    print("_searchAlgorithm: $_searchAlgorithm | _theme: $_theme");
    // print(SearchAlgorithm.values[_searchAlgorithm].toString().split('.').last);

    // _refreshController = kIsWeb
    //     ? null
    //     : PullToRefreshController(
    //         settings: PullToRefreshSettings(
    //           color: Colors.blue,
    //         ),
    //         onRefresh: () async {
    //           print("refreshing...");
    //           // await _refreshController!.beginRefreshing();
    //           print("refreshing ${await _currentWebViewController!.getUrl()}");
    //           await _currentWebViewController!.reload();
    //           await _refreshController!.endRefreshing();
    //         },
    //       );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _init();
  }

  // @override
  // void dispose() {
  //   // Clean up the controller when the widget is removed from the
  //   // widget tree.
  //   _handleSearch.dispose();
  //   super.dispose();
  // }

  final RestartableTimer _searchTimer = RestartableTimer(
    const Duration(seconds: 5),
    () {
      print("5 seconds passed");
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
        print("TEST HIGHLIGHT: $_webpageContent");
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
          query = (await _currentWebViewController!.getTitle())!;
        } else {
          // print(rake.rank(_webpageContent, minChars: 5, minFrequency: 2));
          query = _webpageContent;
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

  _performSearch(value, platform) async {
    print("searching...");

    print("_searchTimer.tick ${_searchTimer.tick}");
    if (_searchCount == 0 || _searchTimer.tick > 0) {
      _searchTimer.reset();
      setState(() {
        _searchCount = 0;
      });
    }

    setState(() {
      _searchCount++;
    });

    print(
        "_searchCount: $_searchCount | _searchTimer.isActive: ${_searchTimer.isActive}");

    if (_searchTimer.isActive) {
      if (_searchCount > 5) {
        setState(() {
          _gg = true;
        });
      }
    }
    print("_gg: $_gg");

    var ENGINE_ID;

    switch (platform) {
      case 'Google':
        ENGINE_ID = SEARCH_ENGINE_ID_GOOGLE;
        break;
      case 'YouTube':
        ENGINE_ID = SEARCH_ENGINE_ID_YOUTUBE;
        break;
      case 'Twitter':
        ENGINE_ID = SEARCH_ENGINE_ID_TWITTER;
        break;
      case 'Facebook':
        ENGINE_ID = SEARCH_ENGINE_ID_FACEBOOK;
        break;
      case 'Instagram':
        ENGINE_ID = SEARCH_ENGINE_ID_INSTAGRAM;
        break;
      case 'LinkedIn':
        ENGINE_ID = SEARCH_ENGINE_ID_LINKEDIN;
        break;
    }

    print("page: $page | _start: $_start");

    var url = Uri.https('www.googleapis.com', '/customsearch/v1', {
      'key': API_KEY,
      'cx': ENGINE_ID,
      'q': value,
      'start': _start.toString(),
    });

    var response = !_gg ? await http.get(url) : null;

    print("response: $response");

    if (response != null) {
      if (response.statusCode == 200) {
        var jsonResponse =
            convert.jsonDecode(response.body) as Map<String, dynamic>;

        // print(jsonResponse);
        // print(jsonResponse['items']);

        var items = jsonResponse['items'] != null
            ? jsonResponse['items'] as List<dynamic>
            : [];
        // print("items: ${items}");

        return items;
      } else {
        print('Request failed with status: ${response.statusCode}.');
        return null;
      }
    } else {
      print("GG");
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

  _resetLastViewedIndex(keyword, platform) async {
    if (URLs[keyword][platform] == null) {
      URLs[keyword][platform] = {"lastViewedIndex": 0, "list": []};
    } else {
      URLs[keyword][platform]["lastViewedIndex"] = 0;
    }
  }

  _updateURLs(mode, keyword, platform, list) async {
    print("updating...");

    keyword = keyword.toString();
    platform = platform.toString();
    print("list length: ${list.length}");

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
      //         print("added");
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
            print("platform: $platform");
            setState(() {
              // URLs[keyword][platform] = {"lastViewedIndex": 0, "list": []};
              _resetLastViewedIndex(keyword, platform);

              for (var item in list) {
                URLs[keyword][platform]["list"]
                    .add({'title': item['title'], 'link': item['link']});
              }

              // print("URLs[keyword] ${URLs[keyword]}");

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
        print("no results");
        _searchResult = {};
      } else {
        _searchResult = URLs[_searchText];
        print("_searchResult $_searchResult");

        print("_currentSearchPlatform $_currentSearchPlatform");
        _currentURLs = URLs[_searchText][_currentSearchPlatform]["list"];
      }
    });
  }

  _moveSwiper() async {
    setState(() {
      if (_isSearching) {
        print("popping...");
        Navigator.of(context).pop();
        // _marqueeKey = UniqueKey();
        _isSearching = false;
      }

      print(
          "_currentWebViewController?.runtimeType ${_currentWebViewController?.runtimeType}");

      _currentURLIndex = 0;

      // new key to refresh the preloaded webview
      // _pageKey = GlobalKey();
      _activatedSearchPlatforms[_currentSearchPlatform] = GlobalKey();
      print("_activatedSearchPlatforms $_activatedSearchPlatforms");
    });
  }

  _handleSearch(value, [selectedPlatform = null]) async {
    bool newSearch = false;

    print("selectedPlatform $selectedPlatform");
    if (selectedPlatform != null) {
      setState(() {
        _currentSearchPlatform = selectedPlatform;
      });
    }

    setState(() {
      _searchText = value;
      if (URLs[_searchText] == null && _activatedSearchPlatforms.isEmpty) {
        _isFetching = true;
        newSearch = true;
      }

      _appBarColor = _defaultAppBarColor;
      _fabColor = Colors.blue[100]!;
      _searchHistory.addAll({value.toString(): false});
    });

    if (kDebugMode) {
      print("URLs[_searchText] ${URLs[_searchText]}");
    }

    _normalSearch(newSearch);

    // // the search results
    // var items = await _performSearch(_searchText, _currentSearchPlatform);
    // // print("items $items");

    // // update the URLs
    // await _updateURLs('replace', _searchText, _currentSearchPlatform, items);

    // // update the current URLs
    // await _updateCurrentURLs();

    // setState(() {
    //   _isFetching = false;
    // });

    // // move the swiper
    // await _moveSwiper();
  }

  void _updateSearchText(searchText) {
    setState(() {
      _searchText = searchText;
      _currentSearchPlatform = "Google";
    });
  }

  final TextEditingController _searchFieldController = TextEditingController();

  void _pushSearchPage() {
    setState(() {
      _isSearching = true;
    });

    _searchFieldController.text = _searchText;

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
      print("getting history");
    }

    final isar = await Isar.getInstance("url") ??
        await Isar.open([URLSchema], name: "url");

    // check if the record exist
    final urlRecord = await isar.uRLs.where().findAll();

    return urlRecord;
  }

  void _deleteHistory() async {
    print("deleting history");

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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return SettingsPage(
            updateSelectedPageIndex: _updateSelectedPageIndex,
            updateSearchAlgorithm: _updateSearchAlgorithm,
            searchAlgorithm: _searchAlgorithm,
            SearchAlgorithmList: SearchAlgorithmList,
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
    print("index $index");
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
    print("type ${_currentWebViewController?.runtimeType}");
    if (_currentWebViewController?.runtimeType != null) {
      if (await _currentWebViewController!.canGoBack()) {
        print("onwill goback");
        _currentWebViewController!.goBack();
        return Future.value(false);
      } else {
        debugPrint("_exit will not go back");
        return Future.value(true);
      }
    }
    return Future.value(false);
  }

  // JavascriptChannel _toasterJavascriptChannel(BuildContext context) {
  //   return JavascriptChannel(
  //     name: 'Print',
  //     onMessageReceived: (JavascriptMessage message) {
  //       print("Print ${message.message}");
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
  //       print("DrillText ${message.message}");
  //       setState(() {
  //         _webpageContent = message.message;
  //       });
  //     },
  //   );
  // }

  _performDrill([selectedText = null]) async {
    String keyword = selectedText ?? await _getSearchQuery();
    print("drilling... | $keyword");

    setState(() {
      _searchText = keyword;

      if (_searchHistory[_searchText.toString()] == false) {
        _searchHistory.update(_searchText.toString(), (value) => true);
      }

      _searchHistory.addAll({keyword.toString(): _searchText.toString()});

      if (_fabColor == Colors.amber[300]!) {
        _fabColor = Colors.blue[100]!;
        _appBarColor = _defaultAppBarColor;
      } else {
        _fabColor = Colors.amber[300]!;
        _appBarColor = Colors.amber[300]!;
      }
    });

    print("_searchHistory ${_searchHistory.toString()}");

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
      var items = await _performSearch(_searchText, _currentSearchPlatform);
      await _updateURLs('replace', _searchText, _currentSearchPlatform, items);
    }

    await _updateCurrentURLs();

    // print(
    //     "_currentURLs[_currentURLIndex]['link'] ${_currentURLs[_currentURLIndex]['link']}");

    // print(
    //     "animate to: ${_activatedSearchPlatforms.indexOf(_currentSearchPlatform)}");
    await _preloadPlatformController.animateToPage(
        // find the index of the current platform
        _activatedSearchPlatforms.keys.toList().indexOf(_currentSearchPlatform),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn);

    await _moveSwiper();

    // _currentPreloadPageController.jumpToPage(0);

    setState(() {
      // _pageKey = GlobalKey();

      if (_fabColor == Colors.amber[300]!) {
        _fabColor = Colors.blue[100]!;
        _appBarColor = _defaultAppBarColor;
      } else {
        _fabColor = Colors.amber[300]!;
        _appBarColor = Colors.amber[300]!;
      }
    });
  }

  _recordActivity() async {
    print("begin record...");

    // if (!_redirectStopwatch.isRunning) {
    //   _redirectStopwatch.start();
    //   print("1 onPageStarted");
    // }

    // first stop the activityStopwatch if it is running
    if (activityStopwatch.isRunning) {
      activityStopwatch.stop();
    }

    // get the database
    final isar =
        Isar.getInstance("url") ?? await Isar.open([URLSchema], name: "url");
    print("isar: $isar");

    // check if the record exist
    final urlRecord = await isar.uRLs
        .filter()
        .urlEqualTo(_currentURLs[_currentURLIndex]["title"])
        .findAll();
    print("urlRecord: ${urlRecord}");

    // print(
    //     "activityStopwatch stopped: ${activityStopwatch.elapsed}");

    // final Duration dur = parseDuration(
    //     '2w 5d 23h 59m 59s 999ms 999us');
    // print("dur $dur");

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
        print("start activityStopwatch");
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
    //   print("1 redirect");

    //   setState(() {
    //     _redirecting = true;
    //   });
    // } else {
    //   print("2 redirect");

    //   _redirectStopwatch.stop();
    //   _redirectStopwatch.reset();
    //   setState(() {
    //     _redirecting = false;
    //   });
    // }

    // print("swiping $_swipe");

    // setState(() {
    //   _previousURL = url;
    //   if (!activityStopwatch.isRunning) {
    //     print("start activityStopwatch");
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
    print("show menu");
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
                      print("close menu");

                      Navigator.pop(context);

                      setState(() {
                        _menuShown = false;
                      });
                    },
                    icon: const FaIcon(FontAwesomeIcons.xmark, size: 20),
                  ),
                  IconButton(
                    onPressed: () async {
                      print("select all");

                      Navigator.pop(context);

                      setState(() {
                        _menuShown = false;
                      });
                    },
                    icon: const FaIcon(FontAwesomeIcons.borderAll, size: 20),
                  ),
                  IconButton(
                    onPressed: () async {
                      print("copy");
                      String? selectedText =
                          await _currentWebViewController?.getSelectedText();
                      await Clipboard.setData(
                          ClipboardData(text: selectedText));
                      print("selectedText: $selectedText");

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
                      print("drill");
                      String? selectedText =
                          await _currentWebViewController?.getSelectedText();
                      print("selectedText: $selectedText");

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
    // print("position: $position | _currentURLIndex: ${_currentURLIndex}");
    // // if (position == _currentURLIndex) {
    // print("ending... | ${await _refreshController!.isRefreshing()}");
    // await _refreshController!.endRefreshing();
    // print("ended... | ${await _refreshController!.isRefreshing()}");
    // }
  }

  Widget _buildWebView(BuildContext context, var data, int position) {
    // print("data $data");
    print("building... | $position");
    // print("building... | ${data}");

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
        print("bingo $bingo | $position");
        // if (!activityStopwatch.isRunning) {
        //   print("start activityStopwatch");
        //   activityStopwatch.start();
        // }
        // _recordActivity();
      }

      // print("building... | bingo: ${bingo} | data: ${data}");
      // return Text("123");
      return SizedBox(
        width: MediaQuery.of(context).size.width,

        // child: Text("test${index}"),
        child:
            //  MouseRegion(
            //   cursor: SystemMouseCursors.click,
            //   onEnter: (event) {
            //     print("onEnter");
            //   },
            //   onExit: (event) {
            //     print("onExit");
            //   },
            //   onHover: (event) {
            //     print("onHover");
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
                  print("DrillText ${args[0]}");
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
              // print("title: $title | data['title']: ${data['title']}");
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
            print("zoomScale: $oldScale, $newScale");
          },
          contextMenu: ContextMenu(
            // settings: ContextMenuSettings(
            //   hideDefaultSystemContextMenuItems: true,
            // ),
            onCreateContextMenu: (hitTestResult) async {
              print("hitTestResult");
              if (!_menuShown) {
                print("show menu");
                _showSelectMenu(context);
                setState(() {
                  _menuShown = true;
                });
              } else {
                print("menu already shown");
              }
            },
            onContextMenuActionItemClicked: (contextMenuItemClicked) => {
              print("contextMenuItemClicked: ${contextMenuItemClicked.id}"),
            },
            onHideContextMenu: () {
              print("onHideContextMenu");
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
                  print("selectedText: $selectedText");

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

        //       print(
        //           "bingo ${await webViewController.currentUrl()} | ${data['link']}");
        //     }
        //     print(
        //         "not bingo ${await webViewController.currentUrl()} | ${data['link']}");
        //     _webViewControllers.addAll({position: webViewController});
        //     print("webview controllers ${_webViewControllers}");
        //   },
        //   onPageStarted: (url) async {
        //     print("1 onPageStarted");

        //     /*
        //         if (!_redirectStopwatch.isRunning) {
        //           _redirectStopwatch.start();
        //           print("1 onPageStarted");
        //         }

        //         final isar = Isar.getInstance("url") ??
        //             await Isar.open([URLSchema], name: "url");

        //         // check if the record exist
        //         final urlRecord =
        //             await isar.uRLs.filter().urlEqualTo(_previousURL).findAll();

        //         // print("urlRecord: ${urlRecord}");
        //         // print("_previousURL: ${_previousURL}");

        //         if (activityStopwatch.isRunning && _previousURL != "") {
        //           activityStopwatch.stop();
        //           // print(
        //           //     "activityStopwatch stopped: ${activityStopwatch.elapsed}");

        //           // final Duration dur = parseDuration(
        //           //     '2w 5d 23h 59m 59s 999ms 999us');
        //           // print("dur $dur");

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
        //     print("3 onPageFinished");

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

        //         print("isar: $isar");

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
        //           print("1 redirect");

        //           setState(() {
        //             _redirecting = true;
        //           });
        //         } else {
        //           print("2 redirect");

        //           _redirectStopwatch.stop();
        //           _redirectStopwatch.reset();
        //           setState(() {
        //             _redirecting = false;
        //           });
        //         }

        //         print("swiping $_swipe");

        //         setState(() {
        //           _previousURL = url;
        //           if (!activityStopwatch.isRunning) {
        //             print("start activityStopwatch");
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
        //       print("title: $title | data['title']: ${data['title']}");
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
      print(
          "platformPosition: $platformPosition | ${_activatedSearchPlatforms.keys.toList().indexOf(_currentSearchPlatform)} | ${_activatedSearchPlatforms.length}");
    }
    return PreloadPageView.builder(
      physics: const NeverScrollableScrollPhysics(),
      preloadPagesCount: _preloadNumber,
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
        print('page changed. current: $position');

        setState(() {
          _currentURLIndex = position;
          URLs[_searchText]
                  [_activatedSearchPlatforms.keys.toList()[platformPosition]]
              ["lastViewedIndex"] = position;
          _currentWebViewTitle = _currentURLs[position]!['title'];
          _loadingPercentage = 100;
          _currentWebViewController = _webViewControllers[position];

          // print(
          //     "_webViewControllers $_webViewControllers");
        });

        // print(
        //     "URLs[_searchText][_activatedSearchPlatforms[platformPosition]] ${URLs[_searchText][_activatedSearchPlatforms[platformPosition]]}");

        // print(
        //     "controller 1 ${_currentURLs[position]!['title']} |  ${_currentURLs[position]!['link']}");
        // print(
        //     "controller 2 ${await _currentWebViewController?.getTitle()} | ${await _currentWebViewController?.getUrl()}");
        // print(
        //     "controller 3 ${await _currentWebViewController}");

        // print(
        //     "same ${await _currentWebViewController?.currentUrl() == _currentURLs[position]!['link']}");

        // fetch more results if we are almost at the end of the list
        if (position + 1 >= _currentURLs.length) {
          print("reached end of list");

          setState(() {
            page++;
            _start = (page - 1) * 10 + 1;
          });

          var items = await _performSearch(_searchText, _currentSearchPlatform);
          print("items $items");
          // update the URLs
          await _updateURLs(
              'extend', _searchText, _currentSearchPlatform, items);

          // update the current URLs
          await _updateCurrentURLs();
        }
      },
    );
  }

  _changeSearchPlatform() {
    int index = SearchPlatformList.indexOf(_currentSearchPlatform);
    int newIndex = (index + 1);
    if (newIndex >= SearchPlatformList.length) {
      newIndex = 0;
    }
    setState(() {
      _currentSearchPlatform = SearchPlatformList[newIndex];
      _marqueeKey = UniqueKey();
    });
    print("new _currentSearchPlatform: $_currentSearchPlatform");
  }

  var _platformActivationTimer = null;
  // = RestartableTimer(
  //   const Duration(seconds: 3),
  //   () {
  //     print("3 seconds passed | platform switched");
  //   },
  // );

  _normalSearch([newSearch = false]) async {
    print("newSearch: $newSearch");

    if (!_activatedSearchPlatforms.containsKey(_currentSearchPlatform)) {
      setState(() {
        _activatedSearchPlatforms.addAll({_currentSearchPlatform: GlobalKey()});
      });
    }

    if (URLs[_searchText] == null ||
        URLs[_searchText][_currentSearchPlatform] == null) {
      // do search only if it has not been done before
      var items = await _performSearch(_searchText, _currentSearchPlatform);
      await _updateURLs('replace', _searchText, _currentSearchPlatform, items);
    } else {
      _updateLastViewedPlatform(_searchText, _currentSearchPlatform);
      _resetLastViewedIndex(_searchText, _currentSearchPlatform);
    }

    await _updateCurrentURLs();

    setState(() {
      _isFetching = false;
    });

    await _moveSwiper();

    // print(
    //     "animate to: ${_activatedSearchPlatforms.indexOf(_currentSearchPlatform)}");
    print("_activatedSearchPlatforms: $_activatedSearchPlatforms");
    if (!newSearch && _activatedSearchPlatforms.length > 1) {
      print(
          "animate to: ${_activatedSearchPlatforms.keys.toList().indexOf(_currentSearchPlatform)}");
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
        print(
            "lastPlatform: $lastViewedPlatform | lastViewedIndex: $lastViewedIndex");
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

      print(
          "before ${lastViewedPlatform} | ${_activatedSearchPlatforms[lastViewedPlatform]}");
      setState(() {
        // _currentPreloadPageKey = GlobalKey();
        // _testPreloadPageKey = GlobalKey();
        _activatedSearchPlatforms[lastViewedPlatform] = GlobalKey();
      });
      print(
          "after ${lastViewedPlatform} | ${_activatedSearchPlatforms[lastViewedPlatform]}");

      // print("page before: ${_currentPreloadPageController.page}");

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

      // print("page after: ${_currentPreloadPageController.page}");
      // print("page after: ${_testPreloadPageController.page}");
    }

    double position = 0;
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
              "${key.toString()}, ${lastViewedPlatform}, ${lastViewedIndex}"),
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
              "${key.toString()}, ${lastViewedPlatform}, ${lastViewedIndex}"),
        ));
      }

      position++;
    });

    return result.toList();
  }

  _platformIconBuilder(String platform) {
    switch (platform) {
      case "Google":
        return Icon(BoxIcons.bxl_google);
      case "YouTube":
        return Icon(BoxIcons.bxl_youtube);
      case "Twitter":
        return Icon(BoxIcons.bxl_twitter);
      case "Facebook":
        return Icon(BoxIcons.bxl_facebook);
      case "Instagram":
        return Icon(BoxIcons.bxl_instagram);
      case "LinkedIn":
        return Icon(BoxIcons.bxl_linkedin);
      case "Bing":
        return Icon(BoxIcons.bxl_bing);
      case "Yahoo":
        return Icon(BoxIcons.bxl_yahoo);
      case "Baidu":
        return Icon(BoxIcons.bxl_baidu);
    }
  }

  _testLanguage(String content) async {
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

    print("response: $response");

    if (response != null) {
      if (response.statusCode == 200) {
        var jsonResponse =
            convert.jsonDecode(response.body) as Map<String, dynamic>;

        print("jsonResponse: $jsonResponse");
        // print(jsonResponse['items']);

        //       var items = jsonResponse['items'] != null
        //     ? jsonResponse['items'] as List<dynamic>
        //    : [];
        // print("items: ${items}");

        // return items;
        return response;
      } else {
        print('Request failed with status: ${response.statusCode}.');
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
              ListTile(
                trailing: _selectedPageIndex == 1
                    ? Icon(Icons.history, color: Colors.blue[900])
                    : const Icon(Icons.history_outlined),
                title: const Text('History'),
                onTap: () {
                  _onItemTapped(1);
                  Navigator.pop(context);
                  _pushHistoryPage();
                },
              ),
              ListTile(
                trailing: _selectedPageIndex == 2
                    ? Icon(Icons.bookmark, color: Colors.blue[900])
                    : const Icon(Icons.bookmark_outline),
                title: const Text('Bookmarked'),
                onTap: () {
                  _onItemTapped(2);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                trailing: _selectedPageIndex == 3
                    ? Icon(Icons.settings, color: Colors.blue[900])
                    : const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () {
                  _onItemTapped(3);
                  Navigator.pop(context);
                  _pushSettingsPage();
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
                  // width: MediaQuery.of(context).size.width * 0.8,
                  child: Marquee(
                    key: _marqueeKey,
                    text: _searchResult.isNotEmpty
                        ? '$_searchText on $_currentSearchPlatform (${_currentURLIndex + 1} of ${_currentURLs.length})'
                        : 'Results for $_searchText',
                    style: const TextStyle(fontSize: 18),
                    scrollAxis: Axis.horizontal, //scroll direction
                    crossAxisAlignment: CrossAxisAlignment.start,
                    blankSpace: 50.0,
                    velocity: 50.0, //speed
                    pauseAfterRound: const Duration(seconds: 1),
                    // startPadding: 10.0,
                    accelerationDuration: const Duration(seconds: 1),
                    accelerationCurve: Curves.linear,
                    decelerationDuration: const Duration(milliseconds: 500),
                    decelerationCurve: Curves.easeOut,
                  ),
                ),
          actions: <Widget>[
            IconButton(
                icon: const Icon(Icons.search), onPressed: _pushSearchPage)
          ],
        ),
        floatingActionButton: _searchResult.isNotEmpty
            ? Align(
                alignment: Platform.isIOS
                    ? const Alignment(1, 0.95)
                    : const Alignment(1, 0.88),
                child: GestureDetector(
                  onLongPress: () async {
                    if (!_activatedSearchPlatforms
                        .containsKey(_currentSearchPlatform)) {
                      setState(() {
                        // _activatedSearchPlatforms.add(_currentSearchPlatform);
                        _activatedSearchPlatforms
                            .addAll({_currentSearchPlatform: GlobalKey()});
                      });
                    }

                    if (URLs[_searchText][_currentSearchPlatform] == null) {
                      // do search only if it has not been done before
                      var items = await _performSearch(
                          _searchText, _currentSearchPlatform);
                      await _updateURLs('replace', _searchText,
                          _currentSearchPlatform, items);
                    }

                    await _updateCurrentURLs();
                    await _moveSwiper();

                    // print(
                    //     "animate to: ${_activatedSearchPlatforms.indexOf(_currentSearchPlatform)}");
                    await _preloadPlatformController.animateToPage(
                        // _activatedSearchPlatforms
                        //     .indexOf(_currentSearchPlatform),
                        _activatedSearchPlatforms.keys
                            .toList()
                            .indexOf(_currentSearchPlatform),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn);
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
                    //       print("drill ONCE");
                    //       // drill logic
                    //     } else {
                    //       print("already in drill-down mode");
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
                      print(
                          "onDragUpdate ${details.delta} | ${details.globalPosition}");
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

                      // print(
                      //     "webViewX: $webViewPosition.dx, webViewY: $webViewPosition.dy, webViewHeight: $webViewHeight");
                      // print(details.offset);

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
                          // print("1");
                        } else if (details.offset.dy - webViewY >
                            webViewHeight) {
                          // _hoverY = webViewHeight - 1;
                          _hoverY = -1;
                          // print("2");
                        } else {
                          _hoverY = details.offset.dy - webViewY;
                          // _hoverY = -1;

                          // print("3");
                        }
                      });

                      // print("hoverX: $_hoverX, hoverY: $_hoverY");

                      // await _controller_test!.runJavascript("""
                      //     var x = window.innerWidth/2;
                      //     var y = window.innerHeight/2;
                      //     var centre = document.elementFromPoint($_hoverX, $_hoverY);
                      //     Drill.postMessage(centre.innerText);
                      //   """);

                      // _hoverY >= 0 ? await _getSearchQuery() : print("cancel");
                      _hoverY >= 0 ? _performDrill() : print("cancel");
                    },
                    child: FloatingActionButton(
                      onPressed: () {
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
                              //     print("webview tapped");
                              //   },
                              //   onLongPress: () {
                              //     print("webview long pressed");
                              //   },

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
                                child: GestureDetector(
                                  onTap: () {
                                    print("webview tapped");
                                  },
                                  onDoubleTap: () {
                                    print("webview double tapped");
                                  },
                                  // onPanStart: (details) {
                                  //   print(
                                  //       "webview pan start ${details.globalPosition}");
                                  //   _scrollX = details.globalPosition.dx;
                                  //   _scrollY = details.globalPosition.dy;
                                  // },
                                  // onPanDown: (details) {
                                  //   print(
                                  //       "webview pan end ${details.globalPosition}");
                                  // },
                                  child: PreloadPageView.builder(
                                    onPageChanged: (value) {
                                      print("platform changed: $value");
                                      print(
                                          "${URLs[_searchText][SearchPlatformList[value]]}");
                                      // setState(() {
                                      //   _currentPreloadPageController =
                                      //       _preloadPageControllers[value];
                                      //   _currentPreloadPageKey =
                                      //       _preloadPageKeys[value];
                                      // });
                                    },
                                    scrollDirection: Axis.vertical,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    key: _preloadPlatformKey,
                                    preloadPagesCount: 0,
                                    controller: _preloadPlatformController,
                                    itemCount: _activatedSearchPlatforms.length,
                                    itemBuilder: (BuildContext context,
                                            int platformPosition) =>
                                        _buildPlatform(
                                            context, platformPosition),
                                  ),
                                ),
                                // ),
                              ),

                              // Bottom Bar
                              Positioned(
                                width: MediaQuery.of(context).size.width,
                                bottom: 0,
                                child: ColoredBox(
                                  color: _appBarColor,
                                  child: SizedBox(
                                    height: Platform.isIOS
                                        ? (_loadingPercentage < 100 ? 65 : 60)
                                        : (_loadingPercentage < 100 ? 55 : 50),
                                    child: GestureDetector(
                                      onTap: () {
                                        print("swiper tapped");
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
                                                    onPressed: () async {
                                                      print("stairs of drill");
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
                                                                      "Drill Histories (click to go back)",
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
                                                    icon: const FaIcon(
                                                      FontAwesomeIcons.stairs,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  // IconButton(
                                                  //   onPressed: () async {
                                                  //     print("up platform");

                                                  //     await _preloadPlatformController
                                                  //         .previousPage(
                                                  //             duration: const Duration(
                                                  //                 milliseconds: 300),
                                                  //             curve: Curves.easeIn);
                                                  //   },
                                                  //   icon: const Icon(
                                                  //       Icons.keyboard_arrow_up_rounded,
                                                  //       size: 35),
                                                  // ),
                                                  // IconButton(
                                                  //   onPressed: () async {
                                                  //     print("down platform");
                                                  //     await _preloadPlatformController
                                                  //         .nextPage(
                                                  //             duration: const Duration(
                                                  //                 milliseconds: 300),
                                                  //             curve: Curves.easeIn);
                                                  //   },
                                                  //   icon: const Icon(
                                                  //       Icons.keyboard_arrow_down_rounded,
                                                  //       size: 35),
                                                  // ),
                                                  IconButton(
                                                    onPressed: () async {
                                                      if (_currentURLIndex >
                                                          0) {
                                                        print(
                                                            "jump to first page");
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
                                                  // IconButton(
                                                  //   onPressed: () async {
                                                  //     if (_currentURLIndex >
                                                  //         0) {
                                                  //       print("decrease");

                                                  //       // await _currentPreloadPageController
                                                  //       await _testPreloadPageController
                                                  //           .previousPage(
                                                  //               duration:
                                                  //                   const Duration(
                                                  //                       milliseconds:
                                                  //                           300),
                                                  //               curve: Curves
                                                  //                   .easeIn);
                                                  //     }
                                                  //   },
                                                  //   icon: const FaIcon(
                                                  //       FontAwesomeIcons
                                                  //           .angleLeft,
                                                  //       size: 20),
                                                  // ),
                                                  // IconButton(
                                                  //   onPressed: () async {
                                                  //     if (_currentURLIndex <
                                                  //         _currentURLs.length -
                                                  //             1) {
                                                  //       // await _currentPreloadPageController
                                                  //       // await _testPreloadPageController
                                                  //       //     .nextPage(
                                                  //       //         duration:
                                                  //       //             const Duration(
                                                  //       //                 milliseconds:
                                                  //       //                     300),
                                                  //       //         curve: Curves
                                                  //       //             .easeIn);
                                                  //       print(
                                                  //           "_testPreloadPageController ${_testPreloadPageController}");
                                                  //     }
                                                  //   },
                                                  //   icon: const FaIcon(
                                                  //       FontAwesomeIcons
                                                  //           .angleRight,
                                                  //       size: 20),
                                                  // ),

                                                  IconButton(
                                                    onPressed: () async {
                                                      await _currentWebViewController!
                                                          .goBack();
                                                    },
                                                    icon: const FaIcon(
                                                        FontAwesomeIcons
                                                            .rotateLeft,
                                                        size: 20),
                                                  ),
                                                  IconButton(
                                                    onPressed: () async {
                                                      print("share");
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
                                bottom: 20,
                                left:
                                    MediaQuery.of(context).size.width / 2 - 50,
                                // child: PieMenu(
                                //   onTap: () => print('tap'),
                                //   theme: PieTheme(
                                //     bouncingMenu: false,
                                //     delayDuration: Duration.zero,
                                //   ),
                                //   actions: [
                                //     PieAction(
                                //       tooltip: 'like',
                                //       onSelect: () => print('liked'),
                                //       child: const Icon(Icons
                                //           .favorite), // Not necessarily an icon widget
                                //     ),
                                //   ],
                                child: Joystick(
                                  base: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      // color: Color.fromARGB(117, 224, 224, 224),
                                      color: Colors.grey.withOpacity(0.2),
                                      backgroundBlendMode: BlendMode.multiply,
                                    ),
                                  ),
                                  stick: Container(
                                      width: 45,
                                      height: 45,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(50),
                                        color: Colors.grey.withOpacity(0.5),
                                        backgroundBlendMode: BlendMode.multiply,
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          print("switch platform");
                                          _changeSearchPlatform();

                                          // count down 5 seconds
                                          if (_autoSwitchPlatform == 1) {
                                            if (_platformActivationTimer ==
                                                null) {
                                              _platformActivationTimer =
                                                  RestartableTimer(
                                                      const Duration(
                                                          seconds: 2),
                                                      () async {
                                                _normalSearch();
                                              });
                                            } else {
                                              _platformActivationTimer!.reset();
                                            }
                                          }
                                        },
                                        child: _platformIconBuilder(
                                            _currentSearchPlatform),
                                      )),
                                  period: const Duration(milliseconds: 250),
                                  listener: (details) async {
                                    print(
                                        "joystick:  ${details.x}, ${details.y}");
                                    _joystickX = details.x;
                                    _joystickY = details.y;
                                    if (details.x > 0.5) {
                                      print("next");
                                      if (_currentURLIndex <
                                          _currentURLs.length - 1) {
                                        // await _currentPreloadPageController
                                        await _testPreloadPageController
                                            .nextPage(
                                                duration: const Duration(
                                                    milliseconds: 300),
                                                curve: Curves.easeIn);
                                      }
                                    } else if (details.x < -0.5) {
                                      print("prev");
                                      if (_currentURLIndex > 0) {
                                        print("decrease");

                                        // await _currentPreloadPageController
                                        await _testPreloadPageController
                                            .previousPage(
                                                duration: const Duration(
                                                    milliseconds: 300),
                                                curve: Curves.easeIn);
                                      }
                                    }

                                    if (details.y < -0.5) {
                                      print("select platform");
                                      _testLanguage(
                                          "Finds named entities (currently proper names and common nouns) in the text along with entity types, salience, mentions for each entity, and other properties.");
                                    }
                                  },
                                ),
                                // ),
                              ),
                            ],
                          ),
                          // ),
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
}

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
