// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:english_words/english_words.dart';

// void main() => runApp(MyApp());

// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     // final wordPair = WordPair.random();

//     return MaterialApp(
//         theme: ThemeData(primarySwatch: Colors.green), home: RandomWords());
//   }
// }

// class RandomWords extends StatefulWidget {
//   const RandomWords({Key? key}) : super(key: key);

//   @override
//   RandomWordsState createState() => RandomWordsState();
// }

// class RandomWordsState extends State<RandomWords> {
//   final _randomWordPairs = <WordPair>[];
//   final _savedWordPairs = Set<WordPair>();

//   Widget _buildList() {
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemBuilder: (context, item) {
//         if (item.isOdd) return const Divider();

//         final index = item ~/ 2;

//         if (index >= _randomWordPairs.length) {
//           _randomWordPairs.addAll(generateWordPairs().take(10));
//           // return const Divider();
//         }

//         return _buildRow(_randomWordPairs[index]);
//       },
//     );
//   }

//   Widget _buildRow(WordPair pair) {
//     final alreadySaved = _savedWordPairs.contains(pair);

//     return ListTile(
//         title: Text(pair.asPascalCase, style: const TextStyle(fontSize: 18)),
//         trailing: Icon(alreadySaved ? Icons.favorite : Icons.favorite_border,
//             color: alreadySaved ? Colors.green : null),
//         onTap: () {
//           setState(() {
//             if (alreadySaved) {
//               _savedWordPairs.remove(pair);
//             } else {
//               _savedWordPairs.add(pair);
//             }
//           });
//         });
//   }

//   void _pushSaved() {
//     Navigator.of(context)
//         .push(MaterialPageRoute(builder: (BuildContext context) {
//       final Iterable<ListTile> tiles = _savedWordPairs.map((WordPair pair) {
//         return ListTile(
//             title:
//                 Text(pair.asPascalCase, style: const TextStyle(fontSize: 16)));
//       });

//       final List<Widget> divided =
//           ListTile.divideTiles(context: context, tiles: tiles).toList();

//       return Scaffold(
//           appBar: AppBar(
//             title: Text("Saved WordPairs"),
//           ),
//           body: ListView(children: divided));
//     }));
//   }

//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('WordPair Generator'), actions: <Widget>[
//         IconButton(icon: const Icon(Icons.list), onPressed: _pushSaved)
//       ]),
//       // body: _buildList(),
//       body: const WebView(
//         initialUrl: "https://www.google.com",
//         javascriptMode: JavascriptMode.unrestricted,
//       ),
//     );
//   }
// }

import 'dart:async';
import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:card_swiper/card_swiper.dart';

void main() {
  final Completer<WebViewController> controller;

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

  // final Completer<WebViewController> controller;

  @override
  State<WebViewContainer> createState() => _WebViewContainerState();
}

class _WebViewContainerState extends State<WebViewContainer> {
  // final controller = Completer<WebViewController>();
  final _key = UniqueKey();
  final URL_list = [
    "https://www.cuhk.edu.hk/",
    "https://twitter.com/CUHKofficial?ref_src=twsrc%5Egoogle%7Ctwcamp%5Eserp%7Ctwgr%5Eauthor",
    "https://en.wikipedia.org/wiki/Chinese_University_of_Hong_Kong",
    "https://www.topuniversities.com/universities/chinese-university-hong-kong-cuhk"
  ];

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

  String _searchText = "";
  bool _isSearching = false;
  List _searchResult = [];
  int _currentIndex = 0;
  int _loadingPercentage = 0;

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
  List<WebViewController> controller = [];
  // late WebViewController controller;

  SwiperController _swiperController = new SwiperController();

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

      if (URL_list_test[_searchText.toString().toLowerCase()] == null) {
        _searchResult = [];
      } else {
        _searchResult = URL_list_test[_searchText.toString().toLowerCase()];
      }

      print("result $_searchResult");

      _isSearching = false;

      print("controller ${controller.length}");

      // force reload the webview with new URL
      if (controller.isNotEmpty && _searchResult.isNotEmpty) {
        // _swiperController.move(0, animation: false);
        _swiperController.move(0); // kinda buggy with animation set to false
        controller[0].loadUrl(_searchResult[0]);
        _currentIndex = 0;
      }

      Navigator.of(context).pop();
    });
  }

  void _pushSearchPage() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (BuildContext context) {
      // _searchResult = [];

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
                )),
          ),
          body: Container(
              child: const Align(
                  alignment: Alignment.center,
                  child: Text("Search here", style: TextStyle(fontSize: 22)))));
    }));
  }

  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers = {
    Factory(() => EagerGestureRecognizer())
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _searchText == ""
            ? const Text("Explore")
            : _searchResult.isNotEmpty
                ? Text(
                    'Results for $_searchText (${_currentIndex + 1} of ${_searchResult.length})')
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
                    child: Stack(
                      children: <Widget>[
                        Positioned(
                            bottom: 0,
                            height: 50,
                            width: MediaQuery.of(context).size.width,
                            child: Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromARGB(255, 57, 57, 57)
                                        .withOpacity(0.2),
                                    spreadRadius: 3,
                                    blurRadius: 5,
                                    offset: const Offset(
                                        0, -50), // changes position of shadow
                                  ),
                                ],
                              ),
                              child: const Align(
                                alignment: Alignment.center,
                                child: Text(
                                  "Swipe here to change page",
                                ),
                              ),
                            )),
                        Swiper(
                          itemBuilder: (BuildContext context, int index) {
                            return Container(
                              padding: const EdgeInsets.only(bottom: 50),
                              child: Offstage(
                                offstage: false,
                                child: Stack(
                                  children: <Widget>[
                                    WebView(
                                      key: _key,
                                      gestureRecognizers: gestureRecognizers,
                                      javascriptMode:
                                          JavascriptMode.unrestricted,
                                      initialUrl: _searchResult[index],
                                      onWebViewCreated: (webViewController) {
                                        if (controller.isNotEmpty) {
                                          controller.removeLast();
                                        }
                                        controller.add(webViewController);
                                      },
                                      onPageStarted: (url) {
                                        setState(() {
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
                                          _loadingPercentage = 100;
                                        });
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
                              ),
                            );
                          },
                          itemCount: _searchResult.length,
                          loop: false,
                          onIndexChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                              print("index $index");
                            });
                          },
                          controller: _swiperController,
                          // pagination: SwiperPagination(),
                          // control: SwiperControl(),
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
            icon: Icon(Icons.bookmark),
            label: 'Bookmark',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        // currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[800],
        // onTap: _onItemTapped,
      ),
    );
  }
}

// // Search Page
// class SearchPage extends StatefulWidget {
//   const SearchPage({super.key});

//   @override
//   State<SearchPage> createState() => _SearchPageState();
// }
