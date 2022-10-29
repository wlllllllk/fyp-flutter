import 'dart:async';
import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:webview_flutter/webview_flutter.dart';
import 'package:card_swiper/card_swiper.dart';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import 'package:duration/duration.dart';
import 'package:async/async.dart';
import 'dart:math' as math;

import 'my_flutter_app_icons.dart';

part 'main.g.dart';

void main() async {
  runApp(
    MaterialApp(
      theme: ThemeData(
          // colorSchemeSeed: Color.fromARGB(255, 49, 83, 97),
          useMaterial3: true),
      home: WebViewContainer(),
    ),
  );
}

final webViewKey = GlobalKey<_WebViewContainerState>();
// const API_KEY = "AIzaSyD48Vtn0yJnAIU6SyoIkPJQg3xWKax48dw";
const API_KEY = "AIzaSyDMa-bYzmjOHJEZdXxHOyJA55gARPpqOGw";
// const SEARCH_ENGINE_ID = "a2af9eb17493641ba";
const SEARCH_ENGINE_ID = "35fddaf2d5efb4668";

class WebViewContainer extends StatefulWidget {
  // const WebViewContainer({required this.controller, Key? key}): super(key: key);
  const WebViewContainer({super.key});

  @override
  State<WebViewContainer> createState() => _WebViewContainerState();
}

class _WebViewContainerState extends State<WebViewContainer>
    with TickerProviderStateMixin {
  late final AnimationController _drillingAnimationController =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))
        ..repeat();

  bool stop = false;

  final _key = UniqueKey();
  Map URLs = {};
  Map _drillURLs = {};
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
  int _TEST = 0;
  String _searchText = "";
  String _drillText = "";
  bool _isSearching = false;
  Map _searchResult = {};
  Map _backUp = {};
  Map _drillResult = {};
  List _currentURLs = [];
  List _currentURLsPlain = [];
  int _currentDomainIndex = 0;
  int _currentURLIndex = 0;
  int _loadingPercentage = 0;
  Map _activeTime = {};
  String _previousURL = "";
  final stopwatch = Stopwatch();
  final _redirectStopwatch = Stopwatch();
  int _selectedPageIndex = 0;
  Color _appBarColor = Colors.blue[100]!;
  Color _fabColor = Colors.blue[100]!;
  String _searchMode = "Default";
  bool _homePage = true;
  bool _swipe = false;
  bool _redirecting = false;
  String _clickContent = "";
  bool _gg = false;
  int _searchCount = 0;
  double _turns = 0.0;
  bool _drilling = false;

  // include only first page
  int _page = 1;
  // counting start, (page=2) => (start=11), (page=3) => (start=21), etc
  int _start = (1 - 1) * 10 + 1;

  void _toggleSearchBar() {
    setState(() {
      if (!_isSearching) {
        _isSearching = true;
      } else if (_isSearching) {
        _isSearching = false;
      }

      print("searching? $_isSearching");
    });
  }

  // TextEditingController _handleSearch = TextEditingController();
  List<WebViewController> _controller = [];
  WebViewController? _controller_test;

  SwiperController _swiperControllerVertical = new SwiperController();
  SwiperController _swiperControllerHorizontal = new SwiperController();

  // @override
  // void dispose() {
  //   // Clean up the controller when the widget is removed from the
  //   // widget tree.
  //   _handleSearch.dispose();
  //   super.dispose();
  // }

  // @override
  // void initState() {
  //   super.initState();
  //   _handleSearch.addListener(() {
  //     setState(() {
  //       _searchText = _handleSearch.text;
  //       print("result ${URL_list_test[_searchText]}");

  //       if (URL_list_test[_searchText] != null) {
  //         _searchResult = URL_list_test[_searchText];
  //       } else {
  //         _searchResult = [];
  //       }
  //     });
  //   });
  // }

  final RestartableTimer _searchTimer = RestartableTimer(
    const Duration(seconds: 5),
    () {
      print("5 seconds passed");
    },
  );

  //  _resetSearchCounter() {
  //   _searchCount = 0;
  // }

  _performSearch(value) async {
    print("searching...");

    setState(() {
      _drilling = true;
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
        "_searchCount: ${_searchCount} | _searchTimer.isActive: ${_searchTimer.isActive}");

    if (_searchTimer.isActive) {
      if (_searchCount > 5) {
        setState(() {
          _gg = true;
        });
      }
    }
    print("_gg: $_gg");

    var url = Uri.https('www.googleapis.com', '/customsearch/v1', {
      'key': API_KEY,
      'cx': SEARCH_ENGINE_ID,
      'q': value,
      'start': _start.toString()
    });

    var response = !_gg ? await http.get(url) : null;

    // print("response: $response");
    setState(() {
      _drilling = false;
    });

    if (response != null) {
      if (response.statusCode == 200) {
        var jsonResponse =
            convert.jsonDecode(response.body) as Map<String, dynamic>;
        var items = jsonResponse['items'] as List<dynamic>;

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

    keyword = keyword.toString().toLowerCase();
    platform = platform.toString().toLowerCase();

    setState(() {
      if (URLs[keyword] == null) {
        URLs[keyword] = {};
      }

      if (URLs[keyword][platform] == null) {
        URLs[keyword][platform] = [];
      }
    });

    switch (mode) {
      case "append":
        {
          int length = URLs[keyword][platform].length;

          setState(() {
            URLs[keyword][platform]
                .removeRange(_currentURLIndex, length - _currentDomainIndex);

            for (var item in list) {
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
          setState(() {
            URLs[keyword][platform] = [];

            for (var item in list) {
              URLs[keyword][platform]
                  .add({'title': item['title'], 'link': item['link']});
            }

            // URLs[keyword][platform]
            //     .add({'title': 'manual', 'link': 'https://www.google.com'});
          });
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
        print("have results");

        _searchResult = URLs[_searchText];
        // print("_searchResult $_searchResult");
        _currentURLs =
            URLs[_searchText][_searchResult.keys.toList()[_currentDomainIndex]];
        // print("_currentURLs $_currentURLs");
        _currentURLsPlain = _currentURLs.map((e) => e['link']).toList();
      }
    });
  }

  void _loadNewPage() {
    _controller_test?.loadUrl(_currentURLs[_currentURLIndex]['link']);
  }

  _moveSwiper() async {
    setState(() {
      if (_isSearching) {
        print("popping...");
        Navigator.of(context).pop();

        _isSearching = false;
      }

      print("_controller_test?.runtimeType ${_controller_test?.runtimeType}");

      // if (_controller_test?.runtimeType != null) {
      // if (_controller_test?.runtimeType != null && !switchMode && !drilling) {
      print("MOVE");
      // _swiperControllerVertical.move(0, animation: false);
      _swiperControllerVertical
          .move(0); // kinda buggy with animation set to false
      _swiperControllerHorizontal
          .move(0); // kinda buggy with animation set to false

      _currentDomainIndex = 0;
      _currentURLIndex = 0;

      // if (_searchMode != "Drill-down") _loadNewPage();
      _loadNewPage();
      // }

      // if (!switchMode && _searchMode != "Drill-down") {
    });
  }

  void _handleSearch(value, bool switchMode) async {
    setState(() {
      _searchMode = "Default";
      _appBarColor = Colors.blue[100]!;
      _fabColor = Colors.blue[100]!;
    });

    print("search $value");
    String realSearchText = "";
    Map results = {};
    value = value.toString().toLowerCase();

    print("_searchMode $_searchMode");

    if (_searchMode == "Default") {
      _searchText = value;
      realSearchText = value;
    } else if (_searchMode == "Drill-down") {
      _searchText = value;
      realSearchText = value;
    }

    print("realSearchText $realSearchText");

    // the search results
    var items = await _performSearch(realSearchText);

    // update the URLs
    await _updateURLs('replace', _searchText, 'google', items);

    // update the current URLs
    await _updateCurrentURLs();

    // move the swiper
    await _moveSwiper();
  }

  void _pushSearchPage() {
    setState(() {
      _isSearching = true;
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(
              title: Container(
                // height: 40,
                // padding: const EdgeInsets.only(left: 15),
                // decoration: BoxDecoration(
                // color: Colors.white,
                // borderRadius: BorderRadius.circular(10),
                // ),
                child: TextField(
                  textInputAction: TextInputAction.search,
                  autofocus: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter a search term',
                  ),
                  // controller: _handleSearch,
                  onSubmitted: (value) {
                    _handleSearch(value, false);
                  },
                  autocorrect: false,
                ),
              ),
            ),
            body: Container(
              child: const Align(
                alignment: Alignment.center,
                child: Text(
                  "Search here",
                  style: TextStyle(fontSize: 22),
                ),
              ),
            ),
          );
        },
      ),
    );
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

  _buildHistoryList(data) {
    Map list = {};
    for (var item in data) {
      list.addAll({item.url: item.duration});
    }

    return list
        .map(
          (key, value) => MapEntry(
            key,
            ListTile(
              title: Text(key),
              subtitle: Text(value.toString()),
            ),
          ),
        )
        .values
        .toList();
  }

  // fake drill function
  // _drill() async {
  //   print("drilling");
  //   Timer(Duration(milliseconds: 3000), () async {
  //     print("drilled");
  //     setState(() {
  //       _fabColor = Colors.blue[100]!;
  //     });
  //   });
  // }

  _showAlertDialog(BuildContext context) {
    Widget cancelButton = TextButton(
      child: const Text("Cancel"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    Widget continueButton = TextButton(
      child: const Text("Delete"),
      onPressed: () {
        _deleteHistory();
        Navigator.of(context).pop();
        Navigator.of(context).pop();
        setState(() {
          _selectedPageIndex = 0;
        });
      },
    );

    AlertDialog alert = AlertDialog(
      title: const Text("Delete All History"),
      content: const Text("Are you sure? This cannot be undone."),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void _pushHistoryPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () {
              setState(() {
                _selectedPageIndex = 0;
              });
              return Future.value(true);
            },
            child: Scaffold(
              appBar: AppBar(
                title: Container(
                  child: const Text("History"),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  onPressed: () => {
                    setState(() => {
                          _selectedPageIndex = 0,
                        }),
                    Navigator.of(context).pop()
                  },
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _showAlertDialog(context),
                  ),
                ],
              ),
              body: Container(
                child: Align(
                  alignment: Alignment.center,
                  child: FutureBuilder(
                    future: _getHistory(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        // print("snapshot ${snapshot.data}");
                        // print("snapshot ${snapshot.data == ''}");
                        return ListView(
                          children: _buildHistoryList(snapshot.data),
                        );
                      } else {
                        return const Text("Nothing here :(");
                      }
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers = {
    Factory(() => EagerGestureRecognizer())
  };

  void _onItemTapped(int index) {
    setState(() {
      _selectedPageIndex = index;
      if (_selectedPageIndex == 1) {
        _pushHistoryPage();
      }
    });

    _getHistory();
  }

  // void _onChangeSearchMode() async {
  //   print("changing search mode");
  //   if (_searchMode == "Default") {
  //     setState(() {
  //       _searchMode = "Drill-down";
  //       _appBarColor = Colors.blue[900]!;
  //     });

  //     var keyword = await _controller_test!.getTitle();
  //     print("keyword $keyword");

  //     var items = await _performSearch(keyword);

  //     await _updateURLs('append', _searchText, 'google', items);
  //     await _updateCurrentURLs();
  //     await _moveSwiper();
  //   } else {
  //     setState(() {
  //       _searchMode = "Default";
  //       _appBarColor = Colors.blue;
  //     });
  //   }

  //   // final title = await _controller_test!.getTitle();
  //   // _handleSearch(title, true);
  // }

  Future<bool> _onWillPop(BuildContext context) async {
    if (_controller_test?.runtimeType != null) {
      if (await _controller_test!.canGoBack()) {
        print("onwill goback");
        _controller_test!.goBack();
        return Future.value(false);
      } else {
        debugPrint("_exit will not go back");
        return Future.value(true);
      }
    }
    return Future.value(false);
  }

  JavascriptChannel _toasterJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
      name: 'Print',
      onMessageReceived: (JavascriptMessage message) {
        print("message1 ${message.message}");
        setState(() {
          _clickContent = message.message;
        });
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text(message.message)),
        // );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _appBarColor,
          centerTitle: false,
          title: _searchText == ""
              ? const Text("Explore")
              : _searchResult.isNotEmpty
                  ? Text(
                      '$_searchText on ${_searchResult.keys.toList()[_currentDomainIndex]} (${_currentURLIndex + 1} of ${_currentURLs.length})')
                  : Text('Results for $_searchText'),
          actions: <Widget>[
            IconButton(
                // icon: const Icon(Icons.search), onPressed: _toggleSearchBar)
                icon: const Icon(Icons.search),
                onPressed: _pushSearchPage)
          ],
        ),
        floatingActionButton: _searchResult.isNotEmpty
            ? GestureDetector(
                onLongPress: () async {
                  print("drill CONTINUOUSLY");
                  setState(() {
                    if (_fabColor == Colors.amber[300]!) {
                      _fabColor = Colors.blue[100]!;
                      _appBarColor = Colors.blue[100]!;
                      _searchMode = "Default";
                    } else {
                      _fabColor = Colors.amber[300]!;
                      _appBarColor = Colors.amber[300]!;
                      _searchMode = "Drill-down";
                    }
                  });

                  if (_searchMode == "Drill-down") {
                    print(
                        "real drilling | ${await _controller_test!.getTitle()}");

                    var items = await _performSearch(
                        await _controller_test!.getTitle());

                    await _updateURLs('append', _searchText, 'google', items);
                    await _updateCurrentURLs();
                  }
                },
                child: FloatingActionButton(
                  onPressed: () {
                    if (_searchMode == "Default") {
                      print("drill ONCE");
                      // drill logic
                    } else {
                      print("already in drill-down mode");
                    }
                  },
                  backgroundColor: _fabColor,
                  splashColor: Colors.amber[100],
                  child: AnimatedBuilder(
                    animation: _drillingAnimationController,
                    builder: (_, child) {
                      return Transform.rotate(
                        angle: _drilling
                            ? _drillingAnimationController.value * 2 * math.pi
                            : 0.0,
                        child: child,
                      );
                    },
                    child: const Icon(MyFlutterApp.drill),
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
                          Expanded(
                            // child:
                            // GestureDetector(
                            //   onTap: () {
                            //     print("webview tapped");
                            //   },
                            //   onLongPress: () {
                            //     print("webview long pressed");
                            //   },
                            child: WebView(
                              key: _key,
                              // gestureRecognizers: gestureRecognizers,
                              javascriptMode: JavascriptMode.unrestricted,
                              javascriptChannels: <JavascriptChannel>{
                                _toasterJavascriptChannel(context),
                              },
                              initialUrl: _currentURLs[_currentURLIndex]
                                  ['link'],
                              onWebViewCreated: (webViewController) {
                                _controller_test = webViewController;
                                print(_controller_test.runtimeType);

                                // if (_controller.isNotEmpty) {
                                //   _controller.removeLast();
                                // }
                                // _controller.add(webViewController);
                              },
                              onPageStarted: (url) async {
                                if (!_redirectStopwatch.isRunning) {
                                  _redirectStopwatch.start();
                                  print("1 onPageStarted");
                                }

                                final isar = Isar.getInstance("url") ??
                                    await Isar.open([URLSchema], name: "url");

                                // check if the record exist
                                final urlRecord = await isar.uRLs
                                    .filter()
                                    .urlEqualTo(_previousURL)
                                    .findAll();

                                // print("urlRecord: ${urlRecord}");
                                // print("_previousURL: ${_previousURL}");

                                if (stopwatch.isRunning && _previousURL != "") {
                                  stopwatch.stop();
                                  // print(
                                  //     "stopwatch stopped: ${stopwatch.elapsed}");

                                  // final Duration dur = parseDuration(
                                  //     '2w 5d 23h 59m 59s 999ms 999us');
                                  // print("dur $dur");

                                  if (urlRecord.isNotEmpty) {
                                    await isar.writeTxn(() async {
                                      final uRL =
                                          await isar.uRLs.get(urlRecord[0].id);

                                      uRL!.duration =
                                          stopwatch.elapsed.toString();

                                      await isar.uRLs.put(uRL);
                                    });
                                  }
                                  // new record
                                  else {
                                    final newURL = URL()
                                      ..url = _previousURL
                                      ..title =
                                          await _controller_test?.getTitle()
                                      ..duration = stopwatch.elapsed.toString();
                                    await isar.writeTxn(() async {
                                      await isar.uRLs.put(newURL);
                                    });
                                  }

                                  stopwatch.reset();
                                }

                                setState(() {
                                  _loadingPercentage = 0;
                                });
                              },
                              onProgress: (progress) {
                                setState(() {
                                  _loadingPercentage = progress;
                                });
                              },
                              onPageFinished: (url) async {
                                print("3 onPageFinished");

                                _controller_test!.runJavascript(
                                    """window.addEventListener('click', (e) => {
                                            var x = e.clientX, y = e.clientY;
                                            var elementMouseIsOver = document.elementFromPoint(x, y);
                                            var content = elementMouseIsOver.innerText;
                                            if (content == undefined || content == null)
                                              Print.postMessage("");
                                            else
                                              Print.postMessage(content);
                                        });
                                      """);

                                final isar = Isar.getInstance("url") ??
                                    await Isar.open([URLSchema], name: "url");

                                print("isar: ${isar}");

                                final urlRecord = await isar.uRLs
                                    .filter()
                                    .urlEqualTo(url)
                                    .findAll();

                                if (urlRecord.isNotEmpty) {
                                  await isar.writeTxn(() async {
                                    final uRL =
                                        await isar.uRLs.get(urlRecord[0].id);

                                    uRL?.viewCount++;
                                    uRL?.lastViewed = DateTime.now();
                                    uRL?.title =
                                        await _controller_test?.getTitle();

                                    await isar.uRLs.put(uRL!);
                                  });
                                }
                                // new record
                                else {
                                  final newURL = URL()
                                    ..url = url
                                    ..title =
                                        await _controller_test?.getTitle();
                                  await isar.writeTxn(() async {
                                    await isar.uRLs.put(newURL);
                                  });
                                }

                                if (_redirectStopwatch.elapsedMilliseconds <
                                    100) {
                                  print("1 redirect");

                                  setState(() {
                                    _redirecting = true;
                                  });
                                } else {
                                  print("2 redirect");

                                  _redirectStopwatch.reset();
                                  _redirectStopwatch.stop();
                                  setState(() {
                                    _redirecting = false;
                                  });
                                }

                                print("swiping ${_swipe}");

                                setState(() {
                                  _previousURL = url;
                                  if (!stopwatch.isRunning) {
                                    print("start stopwatch");
                                    stopwatch.start();
                                  }
                                  _loadingPercentage = 100;
                                });

                                if (!_swipe &&
                                    _searchMode == "Drill-down" &&
                                    !_currentURLsPlain.contains(url) &&
                                    !_redirecting) {
                                  if (_searchMode == "Drill-down") {
                                    print("drill-down");

                                    // var items = await _performSearch(
                                    //     _controller_test!.getTitle());

                                    // await _updateURLs('append', _searchText,
                                    //     'google', items);
                                    // await _updateCurrentURLs();

                                    print("clickContent $_clickContent");

                                    var items = await _performSearch(
                                        _clickContent == ""
                                            ? await _controller_test!.getTitle()
                                            : _clickContent);

                                    await _updateURLs(
                                        'append', _searchText, 'google', items);
                                    await _updateCurrentURLs();
                                  }
                                }

                                setState(() {
                                  _swipe = false;
                                });
                              },
                            ),
                            // ),
                          ),

                          // Vertical Swiper
                          Container(
                            height: 50,
                            child: GestureDetector(
                              onTap: () {
                                print("swiper tapped");
                              },
                              // onLongPress: () {
                              //   _onChangeSearchMode();

                              //   final snackBar = SnackBar(
                              //     content: Text("$_searchMode mode"),
                              //     shape: RoundedRectangleBorder(
                              //       borderRadius: BorderRadius.circular(0.0),
                              //     ),
                              //     action: SnackBarAction(
                              //       label: 'Undo',
                              //       onPressed: () => _onChangeSearchMode(),
                              //     ),
                              //   );

                              //   // Find the ScaffoldMessenger in the widget tree
                              //   // and use it to show a SnackBar.
                              //   ScaffoldMessenger.of(context)
                              //       .showSnackBar(snackBar);
                              // },
                              child: Swiper(
                                itemCount: _searchResult.length,
                                loop: false,
                                scrollDirection: Axis.vertical,

                                itemBuilder: (BuildContext context, int index) {
                                  return Container(
                                    child: Stack(
                                      children: <Widget>[
                                        // Horizontal Swiper
                                        Swiper(
                                          itemCount: _currentURLs.length,
                                          loop: false,
                                          scrollDirection: Axis.horizontal,
                                          controller:
                                              _swiperControllerHorizontal,
                                          itemBuilder: (BuildContext context2,
                                              int index2) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color.fromARGB(
                                                            255, 182, 182, 182)
                                                        .withOpacity(0.1),
                                                    spreadRadius: 3,
                                                    blurRadius: 5,
                                                    // offset: const Offset(0,
                                                    //     -50), // changes position of shadow
                                                  ),
                                                ],
                                              ),
                                              child: const Align(
                                                alignment: Alignment.center,
                                                child: Text(
                                                  "Swipe here to change page",
                                                ),
                                              ),
                                            );
                                          },
                                          onIndexChanged: (index2) {
                                            setState(() {
                                              _currentURLIndex = index2;
                                              _swipe = true;
                                            });
                                            _loadNewPage();
                                            // setState(() {
                                            //   _swipe = false;
                                            // });
                                          },
                                        ),
                                        if (_loadingPercentage < 100)
                                          LinearProgressIndicator(
                                            value: _loadingPercentage / 100.0,
                                            minHeight: 5,
                                            color: Colors.yellow,
                                          ),
                                      ],
                                    ),
                                  );
                                },
                                onIndexChanged: (index) {
                                  setState(() {
                                    _currentURLIndex = 0;
                                    _currentDomainIndex = index;
                                    _currentURLs = URLs[_searchText
                                            .toString()
                                            .toLowerCase()][
                                        _searchResult.keys
                                            .toList()[_currentDomainIndex]];

                                    // print("_currentURLs $_currentURLs");
                                    print("index $index");

                                    _loadNewPage();
                                  });
                                },
                                controller: _swiperControllerVertical,
                                // pagination: SwiperPagination(),
                                // control: SwiperControl(),
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
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.explore),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark),
              label: 'Bookmark',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
          currentIndex: _selectedPageIndex,
          selectedItemColor: Colors.blue[800],
          onTap: _onItemTapped,
          unselectedItemColor: Colors.grey,
        ),
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
