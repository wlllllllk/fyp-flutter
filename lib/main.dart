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
import 'package:google_vision/google_vision.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:scroll_snap_list/scroll_snap_list.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:context_menus/context_menus.dart';

// import 'package:rake/rake.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

import 'my_flutter_app_icons.dart';
/*
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import "package:image/src/image.dart";
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io' as io;
import 'package:path/path.dart' as p;
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/vision/v1.dart' as vision;
import 'package:googleapis/storage/v1.dart';*/

part 'main.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

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
  "Linkedin"
];

enum Theme { Light, Dark, Auto }

// const API_KEY = "AIzaSyDMa-bYzmjOHJEZdXxHOyJA55gARPpqOGw";
const API_KEY = "AIzaSyD48Vtn0yJnAIU6SyoIkPJQg3xWKax48dw"; //old
// const API_KEY = "AIzaSyD3D4sYkKkWOsSdFxTywO-0VX5GIfJSBZc"; //old
const SEARCH_ENGINE_ID_GOOGLE = "35fddaf2d5efb4668";
const SEARCH_ENGINE_ID_YOUTUBE = "07e66762eb98c40c8";
const SEARCH_ENGINE_ID_TWITTER = "d0444b9b194124097";
const SEARCH_ENGINE_ID_FACEBOOK = "a48841f7c9ed94dd6";
const SEARCH_ENGINE_ID_INSTAGRAM = "a74dea74df886441a";
const SEARCH_ENGINE_ID_LINKEDIN = "c1f02371fcab94ca7";

int page = 1;

// /// A builder that includes an Offset to draw the context menu at.
// typedef ContextMenuBuilder = Widget Function(
//     BuildContext context, Offset offset);

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

  var _searchAlgorithm;
  var _preloadNumber;
  var _autoSwitchPlatform;
  var _theme;

  // GlobalKey _webViewKey = GlobalKey();

  // var _webViewKeyList = [];

  var _marqueeKey = UniqueKey();
  var _settingsPageKey = UniqueKey();
  var _pageKey = GlobalKey();

  Map URLs = {};
  // Map _drillURLs = {};
  // final Map URL_list = {
  //   'doge': {
  //     'google': [
  //       "https://coinmarketcap.com/currencies/dogecoin/",
  //       "https://finance.yahoo.com/quote/DOGE-USD/",
  //       "https://www.coindesk.com/price/dogecoin/",
  //       "https://dogecoin.com/",
  //       "https://en.wikipedia.org/wiki/Doge_(meme)"
  //     ],
  //     "facebook": [
  //       "https://www.cuhk.edu.hk/",
  //       "https://twitter.com/CUHKofficial?ref_src=twsrc%5Egoogle%7Ctwcamp%5Eserp%7Ctwgr%5Eauthor",
  //       "https://en.wikipedia.org/wiki/Chinese_University_of_Hong_Kong",
  //       "https://www.topuniversities.com/universities/chinese-university-hong-kong-cuhk"
  //     ],
  //     "youtube": [
  //       "https://www.makeuseof.com/tag/3-google-tricks-search/",
  //       "https://www.youtube.com/watch?v=erZ3IyBCXdY",
  //       "https://www.blog.google/products/search/20-things-you-didnt-know-you-could-do-search/",
  //       "https://tenor.com/search/idk-what-to-search-gifs",
  //       "https://cafemom.com/parenting/150248-don't_google_these_freaky_things",
  //       "https://www.indy100.com/viral/never-search-on-google-reddit-2657792751"
  //     ],
  //     "idk": ["https://wlsk.design"]
  //   },
  //   'cuhk': {
  //     'google': [
  //       "https://coinmarketcap.com/currencies/dogecoin/",
  //       "https://finance.yahoo.com/quote/DOGE-USD/",
  //       "https://www.coindesk.com/price/dogecoin/",
  //       "https://dogecoin.com/",
  //       "https://en.wikipedia.org/wiki/Doge_(meme)"
  //     ],
  //     "facebook": [
  //       "https://www.cuhk.edu.hk/",
  //       "https://twitter.com/CUHKofficial?ref_src=twsrc%5Egoogle%7Ctwcamp%5Eserp%7Ctwgr%5Eauthor",
  //       "https://en.wikipedia.org/wiki/Chinese_University_of_Hong_Kong",
  //       "https://www.topuniversities.com/universities/chinese-university-hong-kong-cuhk"
  //     ],
  //     "youtube": [
  //       "https://www.makeuseof.com/tag/3-google-tricks-search/",
  //       "https://www.youtube.com/watch?v=erZ3IyBCXdY",
  //       "https://www.blog.google/products/search/20-things-you-didnt-know-you-could-do-search/",
  //       "https://tenor.com/search/idk-what-to-search-gifs",
  //       "https://cafemom.com/parenting/150248-don't_google_these_freaky_things",
  //       "https://www.indy100.com/viral/never-search-on-google-reddit-2657792751"
  //     ],
  //     "idk": ["https://wlsk.design"]
  //   },
  //   'idk': {
  //     'google': [
  //       "https://coinmarketcap.com/currencies/dogecoin/",
  //     ],
  //     "facebook": [
  //       "https://www.cuhk.edu.hk/",
  //     ],
  //     "youtube": [
  //       "https://www.blog.google/products/search/20-things-you-didnt-know-you-could-do-search/",
  //     ],
  //     "idk": ["https://wlsk.design"]
  //   }
  // };

  String _searchText = "";
  String _realSearchText = "";
  bool _isSearching = false;
  Map _searchResult = {};
  List _currentURLs = [];
  List _currentURLsPlain = [];
  int _currentDomainIndex = 0;
  String _currentSearchPlatform = "";
  int _currentURLIndex = 0;
  int _loadingPercentage = 0;
  String _previousURL = "";
  final activityStopwatch = Stopwatch();
  final _redirectStopwatch = Stopwatch();
  int _selectedPageIndex = 0;
  Color _defaultAppBarColor = Colors.white;
  Color _appBarColor = Colors.blue[100]!;
  Color _themedAppBarColor = Colors.blue[100]!;
  Color _fabColor = Colors.blue[100]!;
  String _searchMode = "Default";
  bool _swipe = false;
  bool _redirecting = false;
  String _webpageContent = "";
  bool _gg = false;
  int _searchCount = 0;
  double _turns = 0.0;
  bool _drilling = false;
  double _hoverX = 0.0, _hoverY = 0.0;
  int _prevPos = 0;
  var _currentWebViewKey = null;
  InAppWebViewController? _currentWebViewController;
  Map _webViewControllers = {};
  int _focusedIndex = 0;
  double _scrollX = 0.0, _scrollY = 0.0;
  String _currentWebViewTitle = "";
  // var _next;
  bool _platformChanged = false;
  List _activatedSearchPlatforms = ["Google"];
  // final rake = Rake();
  PullToRefreshController? _refreshController;
  // include only first page
  // counting start, (page=2) => (start=11), (page=3) => (start=21), etc
  int _start = (page - 1) * 10 + 1;

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

    _refreshController = kIsWeb
        ? null
        : PullToRefreshController(
            settings: PullToRefreshSettings(
              color: Colors.blue,
            ),
            onRefresh: () async {
              if (defaultTargetPlatform == TargetPlatform.android) {
                _currentWebViewController?.reload();
              } else if (defaultTargetPlatform == TargetPlatform.iOS) {
                _currentWebViewController?.loadUrl(
                    urlRequest: URLRequest(
                        url: await _currentWebViewController?.getUrl()));
              }
            },
          );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _init();
  }

  // TextEditingController _handleSearch = TextEditingController();
  List<WebViewController> _webViewController = [];
  // WebViewController? _controller_test;

  SwiperController _swiperControllerVertical = new SwiperController();
  SwiperController _swiperControllerHorizontal = new SwiperController();

  PreloadPageController _preloadPageController = PreloadPageController(
    initialPage: 0,
    // loop: true,
    // preloadPagesCount: 3,
    // autoPlay: true,
    // autoPlayInterval: Duration(seconds: 3),
    // autoPlayAnimationDuration: Duration(milliseconds: 800),
    // autoPlayCurve: Curves.fastOutSlowIn,
    // enlargeCenterPage: true,
    // scrollDirection: Axis.vertical,
    // onPageChanged: (index, reason) {
    //   print("index: $index, reason: $reason");
    // },
  );

  PreloadPageController _preloadPlatformController = PreloadPageController(
    initialPage: 0,
    // loop: true,
    // preloadPagesCount: 3,
    // autoPlay: true,
    // autoPlayInterval: Duration(seconds: 3),
    // autoPlayAnimationDuration: Duration(milliseconds: 800),
    // autoPlayCurve: Curves.fastOutSlowIn,
    // enlargeCenterPage: true,
    // scrollDirection: Axis.vertical,
    // onPageChanged: (index, reason) {
    //   print("index: $index, reason: $reason");
    // },
  );
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

    setState(() {
      _drilling = true;
      _realSearchText = value.toString().trim();
    });

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
      case 'Linkedin':
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
    setState(() {
      _drilling = false;
    });

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

  _updateURLs(mode, keyword, platform, list) async {
    print("updating...");

    keyword = keyword.toString();
    platform = platform.toString();
    print("list length: ${list.length}");

    setState(() {
      _marqueeKey = UniqueKey();

      if (list.length > 0) {
        if (URLs[keyword] == null) {
          URLs[keyword] = {};
        }

        if (URLs[keyword][platform] == null) {
          URLs[keyword][platform] = [];
        }
      }
    });

    switch (mode) {
      case "append":
        {
          int length = URLs[keyword][platform].length;

          setState(() {
            if (_currentURLIndex < length - 1) {
              URLs[keyword][platform].removeRange(_currentURLIndex + 1, length);
            }

            for (var item in list) {
              print("added");
              URLs[keyword][platform]
                  .add({'title': item['title'], 'link': item['link']});
            }

            // URLs[keyword][platform]
            //     .add({'title': 'manual', 'link': 'https://www.google.com'});
          });
          break;
        }
      case "replace":
        {
          // only set the URL list if there are results
          if (list.length > 0) {
            print("platform: $platform");
            setState(() {
              URLs[keyword][platform] = [];

              for (var item in list) {
                URLs[keyword][platform]
                    .add({'title': item['title'], 'link': item['link']});
              }

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
                URLs[keyword][platform]
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
        // print("have results ${URLs[_searchText]}");

        _searchResult = URLs[_searchText];
        // print("_searchResult $_searchResult");
        // _currentURLs = URLs[_searchText][_searchResult.keys.toList()[_currentDomainIndex]];
        print("_currentSearchPlatform $_currentSearchPlatform");
        _currentURLs = URLs[_searchText][_currentSearchPlatform];
        // print("_currentURLs $_currentURLs");
        _currentURLsPlain = _currentURLs.map((e) => e['link']).toList();
      }
    });

    print("_currentURLs ${_currentURLs}");
  }

  // void _loadNewPage() {
  //   print("loading ${_currentURLs[_currentURLIndex]['link']}");
  //   _currentWebViewController?.loadUrl(_currentURLs[_currentURLIndex]['link']);
  // }

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

      // if (_controller_test?.runtimeType != null) {
      // if (_controller_test?.runtimeType != null && !switchMode && !drilling) {
      // print("MOVE");
      // _swiperControllerVertical.move(0, animation: false);
      // _swiperControllerVertical
      //     .move(0); // kinda buggy with animation set to false
      // _swiperControllerHorizontal
      //     .move(0); // kinda buggy with animation set to false

      // _currentDomainIndex = 0;
      _currentURLIndex = 0;

      // print("_preloadPageController.page ${_preloadPageController.page}");
      // print(
      //     "_preloadPageController.positions ${_preloadPageController.positions}");
      // if (_preloadPageController.positions.isNotEmpty) {
      //   _preloadPageController.jumpToPage(0);
      // }
      // _preloadPageController.jumpToPage(0);

      // if (_searchMode != "Drill-down") _loadNewPage();
      // _loadNewPage();
      // }

      // if (!switchMode && _searchMode != "Drill-down") {

      // _pageKey = GlobalKey();
    });
  }

  _handleSearch(value) async {
    setState(() {
      _searchMode = "Default";
      _appBarColor = _defaultAppBarColor;
      _fabColor = Colors.blue[100]!;
    });

    print("search $value");
    String realSearchText = "";
    Map results = {};
    value = value.toString();

    print("_searchMode $_searchMode");

    _searchText = value;
    realSearchText = value;

    print("realSearchText $realSearchText");

    // the search results
    var items = await _performSearch(realSearchText, _currentSearchPlatform);
    // print("items $items");
    // update the URLs
    await _updateURLs('replace', _searchText, _currentSearchPlatform, items);

    // update the current URLs
    await _updateCurrentURLs();

    // move the swiper
    await _moveSwiper();
  }

  void _updateSearchText(searchText) {
    setState(() {
      _realSearchText = searchText;
      _searchText = searchText;
      _currentSearchPlatform = "Google";
    });
  }

  final TextEditingController _searchFieldController = TextEditingController();

  void _pushSearchPage() {
    setState(() {
      _isSearching = true;
    });

    _searchFieldController.text = _realSearchText;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return SearchPage(
              realSearchText: _realSearchText,
              handleSearch: _handleSearch,
              performSearch: _performSearch,
              updateURLs: _updateURLs,
              updateCurrentURLs: _updateCurrentURLs,
              moveSwiper: _moveSwiper,
              updateSearchText: _updateSearchText);
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
    print("getting history");

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
    print("drilling...");
    setState(() {
      if (_fabColor == Colors.amber[300]!) {
        _fabColor = Colors.blue[100]!;
        _appBarColor = _defaultAppBarColor;
        _searchMode = "Default";
      } else {
        _fabColor = Colors.amber[300]!;
        _appBarColor = Colors.amber[300]!;
        _searchMode = "Drill-down";
      }
    });

    if (_searchMode == "Drill-down") {
      // print("real drilling | ${await _getSearchQuery()}");
      var items = await _performSearch(
          selectedText ?? await _getSearchQuery(), _currentSearchPlatform);

      await _updateURLs('append', _searchText, _currentSearchPlatform, items);
      await _updateCurrentURLs();
      setState(() {
        // _currentURLIndex++;
        _swipe = true;
      });

      // await _preloadPageController

      print("current 1 ${await _currentWebViewController?.getUrl()}");

      // await _currentWebViewController.loadUrl(
      //     url: _currentURLs[_currentURLIndex]);

      await _preloadPageController
          .nextPage(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut)
          .whenComplete(() => null);

      print(
          "current 2 ${await _currentWebViewController?.getUrl()} | ${await _currentWebViewController?.getTitle()}");
      await _currentWebViewController?.loadUrl(
          urlRequest:
              URLRequest(url: WebUri(_currentURLs[_currentURLIndex]['link'])));

      // await _currentWebViewController?.loadUrl('https://flutter.dev');

      // _loadNewPage();
    }

    setState(() {
      // _pageKey = GlobalKey();

      if (_fabColor == Colors.amber[300]!) {
        _fabColor = Colors.blue[100]!;
        _appBarColor = _defaultAppBarColor;
        _searchMode = "Default";
      } else {
        _fabColor = Colors.amber[300]!;
        _appBarColor = Colors.amber[300]!;
        _searchMode = "Drill-down";
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
    return showModalBottomSheet(
      barrierColor: Colors.transparent,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(0),
        ),
      ),
      context: context,
      builder: (context) {
        return Container(
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
                      print("select all");

                      Navigator.pop(context);
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

                      final snackBar = SnackBar(
                        content: Text("Copied ${selectedText}"),
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
  }

  Widget _buildWebView(BuildContext context, var data, int position) {
    // print("data $data");
    print("building...");
    // print("building... | ${data}");

    if (data == "") {
      return SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Text("End of Results"),
      );
    } else {
      bool bingo = false;
      if (_currentURLs[_currentURLIndex]['link'] == data['link']) {
        bingo = true;
        // if (position == 0) _next = _currentURLs[_currentURLIndex + 1]['link'];
        print("bingo $bingo");
        // if (!activityStopwatch.isRunning) {
        //   print("start activityStopwatch");
        //   activityStopwatch.start();
        // }
        // _recordActivity();
      }

      // print("building... | bingo: ${bingo} | data: ${data}");

      return SizedBox(
        width: MediaQuery.of(context).size.width,
        // child: Text("test${index}"),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (event) {
            print("onEnter");
          },
          onExit: (event) {
            print("onExit");
          },
          onHover: (event) {
            print("onHover");
          },
          child: InAppWebView(
            pullToRefreshController: _refreshController,
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
              if (bingo) {
                // String title = await _currentWebViewController.getTitle();
                // print("title: $title | data['title']: ${data['title']}");
                setState(() {
                  _loadingPercentage = 100;
                  _currentWebViewTitle = data["title"];
                  // _currentWebViewTitle = title;
                });
                _refreshController?.endRefreshing();
              }
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
                // onCreateContextMenu: (hitTestResult) async {
                //   print("hitTestResult");
                //   var result = await _showSelectMenu(context);
                //   print("result ${await result}");
                // },
                // onContextMenuActionItemClicked: (contextMenuItemClicked) => {
                //   print("contextMenuItemClicked: ${contextMenuItemClicked.id}"),
                // },
                // onHideContextMenu: () {
                //   print("onHideContextMenu");
                //   final snackBar = SnackBar(
                //     content: Text("onHideContextMenu"),
                //     duration: const Duration(seconds: 3),
                //   );
                //   ScaffoldMessenger.of(context).showSnackBar(snackBar);
                // },
                // menuItems: [
                //   ContextMenuItem(
                //     id: 1,
                //     title: "Drill",
                //     action: () async {
                //       String selectedText =
                //           await _currentWebViewController?.getSelectedText() ??
                //               "";
                //       print("selectedText: $selectedText");

                //       final snackBar = SnackBar(
                //         content: Text("Drilling ${selectedText}"),
                //         duration: const Duration(seconds: 3),
                //       );
                //       ScaffoldMessenger.of(context).showSnackBar(snackBar);

                //       _performDrill(selectedText);
                //     },
                //   )
                // ],
                ),
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

  _changeSearchPlatform() {
    int index = SearchPlatformList.indexOf(_currentSearchPlatform);
    int newIndex = (index + 1);
    if (newIndex >= SearchPlatformList.length) {
      newIndex = 0;
    }
    setState(() {
      _currentDomainIndex = newIndex;
      _currentSearchPlatform = SearchPlatformList[newIndex];
    });
    print("new _currentDomainIndex: $_currentDomainIndex");
  }

  switchPlatform() {
    print("new platform: ${_currentSearchPlatform}");
    setState(() {
      // _currentDomainIndex = 0;
      // _currentSearchPlatform = SearchPlatformList[0];
      _platformChanged = true;
    });
  }

  var _platformActivationTimer = null;
  // = RestartableTimer(
  //   const Duration(seconds: 3),
  //   () {
  //     print("3 seconds passed | platform switched");
  //   },
  // );

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
                    text:
                        // '$_realSearchText on ${_searchResult.keys.toList()[_currentDomainIndex]} (${_currentURLIndex + 1} of ${_currentURLs.length})',
                        _searchResult.isNotEmpty
                            ? '$_realSearchText on $_currentSearchPlatform (${_currentURLIndex + 1} of ${_currentURLs.length})'
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
                    // _performDrill();
                    // await _handleSearch(_realSearchText);
                    // print(
                    //     "_currentDomainIndex $_currentDomainIndex | ${SearchPlatformList[_currentDomainIndex]}");
                    // await _preloadPlatformController.animateToPage(
                    //     _currentDomainIndex,
                    //     duration: const Duration(milliseconds: 300),
                    //     curve: Curves.easeIn);
                    if (!_activatedSearchPlatforms
                        .contains(_currentSearchPlatform)) {
                      setState(() {
                        _activatedSearchPlatforms.add(_currentSearchPlatform);
                      });
                    }

                    _platformChanged = true;

                    if (URLs[_searchText][_currentSearchPlatform] == null) {
                      // do search only if it has not been done before
                      var items = await _performSearch(
                          _realSearchText, _currentSearchPlatform);
                      await _updateURLs('replace', _searchText,
                          _currentSearchPlatform, items);
                    }

                    await _updateCurrentURLs();
                    await _moveSwiper();

                    print(
                        "animate to: ${_activatedSearchPlatforms.indexOf(_currentSearchPlatform)}");
                    await _preloadPlatformController.animateToPage(
                        _activatedSearchPlatforms
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

                      RenderBox webViewBox = _pageKey.currentContext
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
                    child: FloatingActionButton.extended(
                      onPressed: () {
                        _changeSearchPlatform();

                        // count down 5 seconds
                        print(_platformActivationTimer == null);
                        if (_autoSwitchPlatform == 1) {
                          if (_platformActivationTimer == null) {
                            _platformActivationTimer = RestartableTimer(
                                const Duration(seconds: 2), () async {
                              if (!_activatedSearchPlatforms
                                  .contains(_currentSearchPlatform)) {
                                setState(() {
                                  _activatedSearchPlatforms
                                      .add(_currentSearchPlatform);
                                });
                              }

                              _platformChanged = true;

                              if (URLs[_searchText][_currentSearchPlatform] ==
                                  null) {
                                // do search only if it has not been done before
                                var items = await _performSearch(
                                    _realSearchText, _currentSearchPlatform);
                                await _updateURLs('replace', _searchText,
                                    _currentSearchPlatform, items);
                              }

                              await _updateCurrentURLs();
                              await _moveSwiper();

                              print(
                                  "animate to: ${_activatedSearchPlatforms.indexOf(_currentSearchPlatform)}");
                              await _preloadPlatformController.animateToPage(
                                  _activatedSearchPlatforms
                                      .indexOf(_currentSearchPlatform),
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeIn);
                            });
                          } else {
                            _platformActivationTimer!.reset();
                          }
                        }
                      },
                      label: Text(_currentSearchPlatform),
                      backgroundColor: _fabColor,
                      splashColor: Colors.amber[100],
                      icon: const Icon(MyFlutterApp.drill),
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
              child: _searchResult.isNotEmpty
                  ? Flexible(
                      child: Column(
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
                          ColoredBox(
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
                          Expanded(
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
                                },
                                scrollDirection: Axis.vertical,
                                physics: const NeverScrollableScrollPhysics(),
                                key: _pageKey,
                                preloadPagesCount: 0,
                                controller: _preloadPlatformController,
                                itemCount: _activatedSearchPlatforms.length,
                                itemBuilder: (BuildContext context,
                                        int platformPosition) =>
                                    PreloadPageView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  preloadPagesCount: _preloadNumber,
                                  controller: _preloadPageController,
                                  itemCount: URLs[_searchText][
                                                  _activatedSearchPlatforms[
                                                      platformPosition]]
                                              ?.length ==
                                          null
                                      ? 0
                                      : URLs[_searchText][
                                              _activatedSearchPlatforms[
                                                  platformPosition]]
                                          .length,
                                  itemBuilder: (BuildContext context,
                                          int urlPosition) =>
                                      _buildWebView(
                                          context,
                                          urlPosition >=
                                                  URLs[_searchText][
                                                          _activatedSearchPlatforms[
                                                              platformPosition]]
                                                      .length
                                              ? ""
                                              : URLs[_searchText][
                                                      _activatedSearchPlatforms[
                                                          platformPosition]]
                                                  [urlPosition]!,
                                          urlPosition),
                                  onPageChanged: (int position) async {
                                    print('page changed. current: $position');
                                    // print(
                                    //     "${_currentURLs[position]!['title']} | $_next");

                                    // var temp = _webViewControllers[_next];

                                    // var temp = _

                                    // print("temp 1 $temp");
                                    // print("temp 2 ${_webViewControllers[temp]}");

                                    setState(() {
                                      _currentURLIndex = position;
                                      _currentWebViewTitle =
                                          _currentURLs[position]!['title'];
                                      _loadingPercentage = 100;

                                      // if (_webViewControllers[
                                      //         _currentURLs[position]!['link']] ==
                                      //     null) {
                                      //   print("add 1");
                                      //   _webViewControllers.addAll({
                                      //     _currentURLs[position]!['link']:
                                      //         _webViewControllers[_next]
                                      //   });
                                      // }

                                      _currentWebViewController =
                                          _webViewControllers[position];

                                      print(
                                          "_webViewControllers $_webViewControllers");
                                    });

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

                                      var items = await _performSearch(
                                          _searchText, _currentSearchPlatform);
                                      print("items $items");
                                      // update the URLs
                                      await _updateURLs('extend', _searchText,
                                          _currentSearchPlatform, items);

                                      // update the current URLs
                                      await _updateCurrentURLs();
                                    }

                                    // print(
                                    //     "prevPos $_prevPos | position $position | length ${_webViewKeyList.length}");

                                    // if (position > _prevPos) {
                                    //   print("next");
                                    //   // setState(() {
                                    //   //   _webViewKeyList.removeAt(0);
                                    //   // });
                                    // } else if (position < _prevPos) {
                                    //   print("prev");
                                    //   // setState(() {
                                    //   //   _webViewKeyList.removeLast();
                                    //   // });
                                    // }

                                    // setState(() {
                                    //   _webViewKeyList.clear();
                                    // });

                                    // print("length ${_webViewKeyList.length}");

                                    // setState(() {
                                    //   _prevPos = position;
                                    // });
                                  },
                                ),
                              ),
                            ),
                          ),

                          // Bottom Bar

                          ColoredBox(
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
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
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
                                                duration: const Duration(
                                                    milliseconds: 300),
                                              ),
                                              context: context,
                                              builder: (BuildContext context) =>
                                                  Container(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.5,
                                                child: Stack(
                                                  children: [
                                                    ListView(
                                                      children: [
                                                        const ListTile(
                                                          title: Text(
                                                            "Drill Histories",
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 20,
                                                            ),
                                                          ),
                                                        ),
                                                        ListTile(
                                                          title: Text(
                                                              _currentSearchPlatform),
                                                        )
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
                                            if (_currentURLIndex > 0) {
                                              print("jump to first page");
                                              setState(() {
                                                _swipe = true;
                                              });

                                              _preloadPageController
                                                  .jumpToPage(0);
                                            }
                                          },
                                          icon: const FaIcon(
                                            FontAwesomeIcons.backwardFast,
                                            size: 20,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () async {
                                            if (_currentURLIndex > 0) {
                                              print("decrease");
                                              setState(() {
                                                // _currentURLIndex--;
                                                _swipe = true;
                                              });

                                              await _preloadPageController
                                                  .previousPage(
                                                      duration: const Duration(
                                                          milliseconds: 300),
                                                      curve: Curves.easeIn);
                                            }
                                          },
                                          icon: const FaIcon(
                                              FontAwesomeIcons.angleLeft,
                                              size: 20),
                                        ),
                                        IconButton(
                                          onPressed: () async {
                                            if (_currentURLIndex <
                                                _currentURLs.length - 1) {
                                              setState(() {
                                                // _currentURLIndex++;
                                                _swipe = true;
                                              });

                                              await _preloadPageController
                                                  .nextPage(
                                                      duration: const Duration(
                                                          milliseconds: 300),
                                                      curve: Curves.easeIn);
                                            }
                                          },
                                          icon: const FaIcon(
                                              FontAwesomeIcons.angleRight,
                                              size: 20),
                                        ),

                                        IconButton(
                                          onPressed: () async {
                                            await _currentWebViewController!
                                                .goBack();
                                          },
                                          icon: const FaIcon(
                                              FontAwesomeIcons.rotateLeft,
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
                                              FontAwesomeIcons.shareNodes,
                                              size: 20),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
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
                    ),
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
