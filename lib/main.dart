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

part 'main.g.dart';

void main() async {
  runApp(
    const MaterialApp(
      home: WebViewContainer(),
    ),
  );
}

final webViewKey = GlobalKey<_WebViewContainerState>();
const API_KEY = "AIzaSyD48Vtn0yJnAIU6SyoIkPJQg3xWKax48dw";
const SEARCH_ENGINE_ID = "a2af9eb17493641ba";

class WebViewContainer extends StatefulWidget {
  // const WebViewContainer({required this.controller, Key? key}): super(key: key);
  const WebViewContainer({super.key});

  @override
  State<WebViewContainer> createState() => _WebViewContainerState();
}

class _WebViewContainerState extends State<WebViewContainer> {
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

  String _searchText = "";
  String _drillText = "";
  bool _isSearching = false;
  Map _searchResult = {};
  Map _backUp = {};
  Map _drillResult = {};
  List _currentURLs = [];
  int _currentDomainIndex = 0;
  int _currentURLIndex = 0;
  int _loadingPercentage = 0;
  Map _activeTime = {};
  String _previousURL = "";
  final stopwatch = Stopwatch();
  int _selectedPageIndex = 0;
  Color _appBarColor = Colors.blue;
  String _searchMode = "Default";

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

  // void _performSearch(value) async {}

  void _handleSearch(value, bool switchMode, bool drilling) async {
    print("search $value");
    String realSearchText = "";
    Map results = {};

    print("_searchMode $_searchMode");

    if (_searchMode == "Default") {
      // if (_searchText == "") {
      _searchText = value;
      // }
      realSearchText = value;
    } else if (_searchMode == "Drill-down") {
      realSearchText = value;
    }

    print("realSearchText $realSearchText");

    var url = Uri.https('www.googleapis.com', '/customsearch/v1', {
      'key': API_KEY,
      'cx': SEARCH_ENGINE_ID,
      'q': realSearchText,
      'start': _start.toString()
    });

    var response = await http.get(url);

    if (response.statusCode == 200) {
      var jsonResponse =
          convert.jsonDecode(response.body) as Map<String, dynamic>;
      var items = jsonResponse['items'] as List<dynamic>;

      // create record for new search text
      if (URLs[_searchText] == null) {
        URLs[_searchText] = {};
      }

      // create record for new search platform
      if (URLs[_searchText]['google'] == null) {
        URLs[_searchText]['google'] = [];
      }

      // remove all previous search results EXCEPT the current one on screen
      int length = URLs[_searchText]['google'].length;
      for (var item in items) {
        URLs[_searchText]['google']
            .add({'title': item['title'], 'link': item['link']});
      }

      results = URLs;
      if (_searchMode == "Drill-down") {
        results[_searchText]['google'].removeRange(1, length);
      }

      // print("URLs[_searchText]['google'] ${URLs[_searchText]['google']}");

      // print('results $results');

      // print('jsonResponse $items');
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }

    setState(() {
      if (results[_searchText.toString().toLowerCase()] == null) {
        _searchResult = {};
      } else {
        _searchResult = results[_searchText.toString().toLowerCase()];
        // print("_searchResult $_searchResult");
        _currentURLs = results[_searchText.toString().toLowerCase()]
            [_searchResult.keys.toList()[_currentDomainIndex]];
        // print("_currentURLs $_currentURLs");
      }

      // print("result ${_searchResult}");
      // print("_currentURLs ${_currentURLs}");
      // print("_currentURLIndex ${_currentURLIndex}");

      _isSearching = false;

      // print("controller ${_controller.length}");

      // force reload the webview with new URL
      // if (_controller.isNotEmpty && _searchResult.isNotEmpty) {
      print("_controller_test?.runtimeType ${_controller_test?.runtimeType}");

      if (_controller_test?.runtimeType != null && !switchMode && !drilling) {
        print("MOVE");
        // _swiperControllerVertical.move(0, animation: false);
        _swiperControllerVertical
            .move(0); // kinda buggy with animation set to false
        _swiperControllerHorizontal
            .move(0); // kinda buggy with animation set to false

        _currentDomainIndex = 0;
        _currentURLIndex = 0;

        if (_searchMode != "Drill-down") _loadNewPage();
      }

      if (!switchMode && _searchMode != "Drill-down") {
        Navigator.of(context).pop();
      }

      // _controller[0].loadUrl(_currentURLs[0]);
      // }
    });
  }

  void _loadNewPage() {
    _controller_test?.loadUrl(_currentURLs[_currentURLIndex]['link']);
  }

  void _pushSearchPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(
              title: Container(
                height: 40,
                padding: const EdgeInsets.only(left: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  textInputAction: TextInputAction.search,
                  autofocus: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter a search term',
                  ),
                  // controller: _handleSearch,
                  onSubmitted: (value) {
                    _handleSearch(value, false, false);
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

  // final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers = {
  //   Factory(() => EagerGestureRecognizer())
  // };

  void _onItemTapped(int index) {
    setState(() {
      _selectedPageIndex = index;
      if (_selectedPageIndex == 1) {
        _pushHistoryPage();
      }
    });

    _getHistory();
  }

  void _onChangeSearchMode() async {
    setState(
      () {
        if (_searchMode == "Default") {
          _searchMode = "Drill-down";
          _appBarColor = Colors.blue[900]!;
        } else {
          _searchMode = "Default";
          _appBarColor = Colors.blue;
        }
      },
    );

    // final title = await _controller_test!.getTitle();
    // _handleSearch(title, true);
  }

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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _appBarColor,
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
        body: Column(
          children: <Widget>[
            Container(
              child: _searchResult.isNotEmpty
                  ? Flexible(
                      child: Column(
                        children: <Widget>[
                          Expanded(
                            child: WebView(
                              key: _key,
                              // gestureRecognizers:
                              //     gestureRecognizers,
                              javascriptMode: JavascriptMode.unrestricted,
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
                                print(stopwatch.isRunning);

                                final isar = Isar.getInstance("url") ??
                                    await Isar.open([URLSchema], name: "url");

                                // check if the record exist
                                final urlRecord = await isar.uRLs
                                    .filter()
                                    .urlEqualTo(_previousURL)
                                    .findAll();

                                print("urlRecord: ${urlRecord}");

                                if (stopwatch.isRunning && _previousURL != "") {
                                  stopwatch.stop();

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
                                  // if (stopwatch.isRunning &&
                                  //     _previousURL != "") {
                                  //   stopwatch.stop();
                                  //   print(
                                  //       "stopwatch ${stopwatch.elapsed.runtimeType}");
                                  //   if (!_activeTime
                                  //       .containsKey(_previousURL)) {
                                  //     _activeTime.addAll(
                                  //         {_previousURL: stopwatch.elapsed});
                                  //   } else {
                                  //     _activeTime[_previousURL] +=
                                  //         stopwatch.elapsed;
                                  //   }

                                  //   print("_activeTime $_activeTime");
                                  //   stopwatch.reset();
                                  // }
                                  _loadingPercentage = 0;
                                });
                              },
                              onProgress: (progress) {
                                setState(() {
                                  _loadingPercentage = progress;
                                });
                              },
                              onPageFinished: (url) async {
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

                                setState(() {
                                  _previousURL = url;
                                  if (!stopwatch.isRunning) {
                                    print("start stopwatch");
                                    stopwatch.start();
                                  }
                                  _loadingPercentage = 100;
                                });

                                if (_searchMode == "Drill-down") {
                                  bool isExist = false;
                                  for (var value in _currentURLs) {
                                    if (value['link'] == url) {
                                      isExist = true;
                                      break;
                                    }
                                  }

                                  // drilling down
                                  if (!isExist) {
                                    _handleSearch(
                                        await _controller_test!.getTitle(),
                                        false,
                                        true);
                                  }
                                }
                              },
                            ),
                          ),

                          // Vertical Swiper
                          Container(
                            height: 50,
                            child: GestureDetector(
                              onLongPress: () {
                                _onChangeSearchMode();

                                final snackBar = SnackBar(
                                  content: Text("$_searchMode mode"),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(0.0),
                                  ),
                                  action: SnackBarAction(
                                    label: 'Undo',
                                    onPressed: () => _onChangeSearchMode(),
                                  ),
                                );

                                // Find the ScaffoldMessenger in the widget tree
                                // and use it to show a SnackBar.
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(snackBar);
                              },
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
                                            });
                                            _loadNewPage();
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
