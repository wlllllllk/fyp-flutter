import 'dart:async';
import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

void main() {
  runApp(
    const MaterialApp(
      home: WebViewContainer(),
    ),
  );
}

final webViewKey = GlobalKey<_WebViewContainerState>();

class WebViewContainer extends StatefulWidget {
  // const WebViewContainer({required this.controller, Key? key}): super(key: key);
  const WebViewContainer({super.key});

  @override
  State<WebViewContainer> createState() => _WebViewContainerState();
}

class _WebViewContainerState extends State<WebViewContainer> {
  final _key = UniqueKey();
  final Map URL_list_test = {
    'doge': [
      "https://coinmarketcap.com/currencies/dogecoin/",
      "https://finance.yahoo.com/quote/DOGE-USD/",
      "https://www.coindesk.com/price/dogecoin/",
      "https://dogecoin.com/",
      "https://en.wikipedia.org/wiki/Doge_(meme)"
    ],
    "cuhk": [
      "https://www.cuhk.edu.hk/",
      "https://twitter.com/CUHKofficial?ref_src=twsrc%5Egoogle%7Ctwcamp%5Eserp%7Ctwgr%5Eauthor",
      "https://en.wikipedia.org/wiki/Chinese_University_of_Hong_Kong",
      "https://www.topuniversities.com/universities/chinese-university-hong-kong-cuhk"
    ],
    "idk what to search": [
      "https://www.makeuseof.com/tag/3-google-tricks-search/",
      "https://www.youtube.com/watch?v=erZ3IyBCXdY",
      "https://www.blog.google/products/search/20-things-you-didnt-know-you-could-do-search/",
      "https://tenor.com/search/idk-what-to-search-gifs",
      "https://cafemom.com/parenting/150248-don't_google_these_freaky_things",
      "https://www.indy100.com/viral/never-search-on-google-reddit-2657792751"
    ],
    "wlsk": ["https://wlsk.design"]
  };

  final Map URL_list_test2 = {
    'doge': {
      'google': [
        "https://coinmarketcap.com/currencies/dogecoin/",
        "https://finance.yahoo.com/quote/DOGE-USD/",
        "https://www.coindesk.com/price/dogecoin/",
        "https://dogecoin.com/",
        "https://en.wikipedia.org/wiki/Doge_(meme)"
      ],
      "facebook": [
        "https://www.cuhk.edu.hk/",
        "https://twitter.com/CUHKofficial?ref_src=twsrc%5Egoogle%7Ctwcamp%5Eserp%7Ctwgr%5Eauthor",
        "https://en.wikipedia.org/wiki/Chinese_University_of_Hong_Kong",
        "https://www.topuniversities.com/universities/chinese-university-hong-kong-cuhk"
      ],
      "youtube": [
        "https://www.makeuseof.com/tag/3-google-tricks-search/",
        "https://www.youtube.com/watch?v=erZ3IyBCXdY",
        "https://www.blog.google/products/search/20-things-you-didnt-know-you-could-do-search/",
        "https://tenor.com/search/idk-what-to-search-gifs",
        "https://cafemom.com/parenting/150248-don't_google_these_freaky_things",
        "https://www.indy100.com/viral/never-search-on-google-reddit-2657792751"
      ],
      "idk": ["https://wlsk.design"]
    },
    'cuhk': {
      'google': [
        "https://coinmarketcap.com/currencies/dogecoin/",
        "https://finance.yahoo.com/quote/DOGE-USD/",
        "https://www.coindesk.com/price/dogecoin/",
        "https://dogecoin.com/",
        "https://en.wikipedia.org/wiki/Doge_(meme)"
      ],
      "facebook": [
        "https://www.cuhk.edu.hk/",
        "https://twitter.com/CUHKofficial?ref_src=twsrc%5Egoogle%7Ctwcamp%5Eserp%7Ctwgr%5Eauthor",
        "https://en.wikipedia.org/wiki/Chinese_University_of_Hong_Kong",
        "https://www.topuniversities.com/universities/chinese-university-hong-kong-cuhk"
      ],
      "youtube": [
        "https://www.makeuseof.com/tag/3-google-tricks-search/",
        "https://www.youtube.com/watch?v=erZ3IyBCXdY",
        "https://www.blog.google/products/search/20-things-you-didnt-know-you-could-do-search/",
        "https://tenor.com/search/idk-what-to-search-gifs",
        "https://cafemom.com/parenting/150248-don't_google_these_freaky_things",
        "https://www.indy100.com/viral/never-search-on-google-reddit-2657792751"
      ],
      "idk": ["https://wlsk.design"]
    },
    'idk': {
      'google': [
        "https://coinmarketcap.com/currencies/dogecoin/",
      ],
      "facebook": [
        "https://www.cuhk.edu.hk/",
      ],
      "youtube": [
        "https://www.blog.google/products/search/20-things-you-didnt-know-you-could-do-search/",
      ],
      "idk": ["https://wlsk.design"]
    }
  };

  String _searchText = "";
  bool _isSearching = false;
  Map _searchResult = {};
  List _currentURLs = [];
  int _currentDomainIndex = 0;
  int _currentURLIndex = 0;
  int _loadingPercentage = 0;
  Map _activeTime = {};
  String _previousURL = "";
  final stopwatch = Stopwatch();
  int _selectedPageIndex = 0;

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

  void _handleSearch(value) {
    setState(() {
      print("search $value");
      _searchText = value;

      if (URL_list_test2[_searchText.toString().toLowerCase()] == null) {
        _searchResult = {};
      } else {
        _searchResult = URL_list_test2[_searchText.toString().toLowerCase()];
        _currentURLs = URL_list_test2[_searchText.toString().toLowerCase()]
            [_searchResult.keys.toList()[_currentDomainIndex]];
      }

      // print("result ${_searchResult}");
      print("_currentURLs ${_currentURLs}");
      print("_currentURLIndex ${_currentURLIndex}");

      _isSearching = false;

      // print("controller ${_controller.length}");

      // force reload the webview with new URL
      // if (_controller.isNotEmpty && _searchResult.isNotEmpty) {
      print(_controller_test?.runtimeType);

      if (_controller_test?.runtimeType != null) {
        print("MOVE");
        // _swiperControllerVertical.move(0, animation: false);
        _swiperControllerVertical
            .move(0); // kinda buggy with animation set to false
        _swiperControllerHorizontal
            .move(0); // kinda buggy with animation set to false

        _currentDomainIndex = 0;
        _currentURLIndex = 0;
        _loadNewPage();
      }

      // _controller[0].loadUrl(_currentURLs[0]);
      // }

      Navigator.of(context).pop();
    });
  }

  void _loadNewPage() {
    _controller_test?.loadUrl(_currentURLs[_currentURLIndex]);
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
                    _handleSearch(value);
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
                ),
                body: Container(
                  child: Align(
                    alignment: Alignment.center,
                    child: _activeTime.isEmpty
                        ? const Align(
                            alignment: Alignment.center,
                            child: Text(
                              "No history yet...",
                              style: TextStyle(fontSize: 22),
                            ),
                          )
                        : ListView(
                            children: _activeTime
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
                                .toList(),
                          ),
                  ),
                ),
              ));
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
                              initialUrl: _currentURLs[_currentURLIndex],
                              onWebViewCreated: (webViewController) {
                                _controller_test = webViewController;
                                print(_controller_test.runtimeType);

                                // if (_controller.isNotEmpty) {
                                //   _controller.removeLast();
                                // }
                                // _controller.add(webViewController);
                              },
                              onPageStarted: (url) {
                                setState(() {
                                  print(stopwatch.isRunning);
                                  if (stopwatch.isRunning &&
                                      _previousURL != "") {
                                    stopwatch.stop();
                                    print("stopwatch ${stopwatch.elapsed}");
                                    if (!_activeTime
                                        .containsKey(_previousURL)) {
                                      _activeTime.addAll(
                                          {_previousURL: stopwatch.elapsed});
                                    } else {
                                      _activeTime[_previousURL] +=
                                          stopwatch.elapsed;
                                    }

                                    print("_activeTime $_activeTime");
                                    stopwatch.reset();
                                  }
                                  _loadingPercentage = 0;
                                });
                              },
                              onProgress: (progress) {
                                setState(() {
                                  _loadingPercentage = progress;
                                });
                              },
                              onPageFinished: (url) {
                                setState(() {
                                  _previousURL = url;
                                  if (!stopwatch.isRunning) {
                                    print("start stopwatch");
                                    stopwatch.start();
                                  }
                                  _loadingPercentage = 100;
                                });
                              },
                            ),
                          ),

                          // Vertical Swiper
                          Container(
                            height: 50,
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
                                        controller: _swiperControllerHorizontal,
                                        itemBuilder: (BuildContext context2,
                                            int index2) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color.fromARGB(
                                                          255, 57, 57, 57)
                                                      .withOpacity(0.2),
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
                                  _currentURLs = URL_list_test2[
                                          _searchText.toString().toLowerCase()][
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
