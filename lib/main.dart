import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fyp_seal/pages/history.dart';
import 'package:fyp_seal/pages/search.dart';
import 'package:fyp_seal/pages/settings.dart';

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
  runApp(
    MaterialApp(
      theme: ThemeData(
          // colorSchemeSeed: Color.fromARGB(255, 49, 83, 97),
          useMaterial3: true),
      home: WebViewContainer(),
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
  "New Mode"
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
const SEARCH_ENGINE_ID_GOOGLE = "35fddaf2d5efb4668";
const SEARCH_ENGINE_ID_YOUTUBE = "07e66762eb98c40c8";
const SEARCH_ENGINE_ID_TWITTER = "d0444b9b194124097";
const SEARCH_ENGINE_ID_FACEBOOK = "a48841f7c9ed94dd6";
const SEARCH_ENGINE_ID_INSTAGRAM = "a74dea74df886441a";
const SEARCH_ENGINE_ID_LINKEDIN = "c1f02371fcab94ca7";

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
  var _theme;

  GlobalKey _webViewKey = GlobalKey();
  var _marqueeKey = UniqueKey();
  var _settingsPageKey = UniqueKey();
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
  final stopwatch = Stopwatch();
  final _redirectStopwatch = Stopwatch();
  int _selectedPageIndex = 0;
  Color _appBarColor = Colors.blue[100]!;
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

  // include only first page
  int _page = 1;
  // counting start, (page=2) => (start=11), (page=3) => (start=21), etc
  int _start = (1 - 1) * 10 + 1;

  void _init() async {
    final prefs = await SharedPreferences.getInstance();
    // final algorithm = await prefs.getInt("searchAlgorithm") ?? SearchAlgorithm.Title.index;
    final algorithm =
        await prefs.getString("searchAlgorithm") ?? SearchAlgorithmList[0];

    final theme = await prefs.getInt("theme") ?? Theme.Light.index;
    setState(() {
      _currentSearchPlatform = "Google";
      _searchAlgorithm = algorithm;
      _theme = theme;
    });
    print("_searchAlgorithm: $_searchAlgorithm | _theme: $_theme");
    // print(SearchAlgorithm.values[_searchAlgorithm].toString().split('.').last);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _init();
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
/*
  _getGalleryImage() async {
    File? _image;

    //get gallery images
    final image_Path =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (image_Path == null) return;
    final imagetemp = File(image_Path.path);
    print(imagetemp);

    setState(() {
      _image = imagetemp;
    });

    _imageSearch(_image, image_Path.path);
  }

  _getCameraImage() async {
    File? _image;

    //get camera images
    final image_Path =
        await ImagePicker().pickImage(source: ImageSource.camera);

    if (image_Path == null) return;
    final imagetemp = File(image_Path.path);
    print(imagetemp);

    setState(() {
      _image = imagetemp;
    });

    _imageSearch(_image, image_Path.path);
  }

  _imageSearch(src, path) async {
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
    bool exist = await io.File(jsonCredential.path).exists();
    if (exist) {
      print("STILL HERE ");
    } else {
      print("JSON CRED doesnt exits");
    }

    try {
      var _client = await CredentialsProvider().client;

      final bytes = io.File(path).readAsBytesSync();
      String img64 = base64Encode(bytes);

      Future<vision.BatchAnnotateImagesResponse> search(String image) async {
        var _vision = vision.VisionApi(await _client);
        var _api = _vision.images;
        var _response =
            await _api.annotate(vision.BatchAnnotateImagesRequest.fromJson({
          "requests": [
            {
              "image": {"content": image},
              "features": [
                {"type": "WEB_DETECTION"}
              ]
            }
          ]
        }));
        // print(entity.entityId);
        List<vision.WebEntity>? entities;
        List<vision.WebImage>? full_match_image;
        List<vision.WebImage>? partial_match_image;
        List<vision.WebPage>? page_with_match_image;
        List<vision.WebImage>? page_with_similar_image;

        var bestguess = vision.WebLabel();

        var imgUrl = vision.WebImage();

        var _label;
        var i = 0;

        _response.responses?.forEach((data) {
          _label = data.webDetection!.bestGuessLabels;

          entities = data.webDetection!.webEntities as List<vision.WebEntity>;

          //full_match_image =
          //  data.webDetection!.fullMatchingImages as List<vision.WebImage>;
          partial_match_image =
              data.webDetection!.partialMatchingImages as List<vision.WebImage>;
          page_with_match_image = data.webDetection!.pagesWithMatchingImages
              as List<vision.WebPage>;
          page_with_similar_image =
              data.webDetection!.visuallySimilarImages as List<vision.WebImage>;

          bestguess = _label!.single;
          //entity = entities!;
        });
        print("best guess label=  " + bestguess.label.toString());
        i = 0;
        var j = 0;
        //for (i; i < 10; i++) {
        print(entities![i].description);
        //  print("Full match url = " + full_match_image![i].url.toString());
        print("Partial match url = " + partial_match_image![i].url.toString());
        print("page with similar iamge = " +
            page_with_similar_image![i].url.toString());
        for (j = 0; j < page_with_match_image!.length; j++) {
          print("page with match image title=" +
              page_with_match_image![j].pageTitle.toString());
          print("page with match image =" +
              page_with_match_image![j].url.toString());
        }

        return _response;
      }

      var response = search(img64);
    } finally {
      await jsonCredential.delete();
      fileExists = jsonCredential.existsSync();
      print("FINALLY = " + fileExists.toString());
      bool exist = await io.File(jsonCredential.path).exists();
      if (exist) {
        print("STILL HERE ");
      } else {
        print("JSON CRED doesnt exits");
      }
    }
  }
  */

  _getSearchQuery() async {
    String query = "";
    switch (_searchAlgorithm) {
      case "Title":
        query = (await _controller_test!.getTitle())!;
        break;
      case "Webpage Content":
        await _controller_test!.runJavascript("""
                        var x = window.innerWidth/2;
                        var y = window.innerHeight/2;
                        var centre = document.elementFromPoint(x, y);
                        Drill.postMessage(centre.innerText);
                      """);
        if (_webpageContent == null || _webpageContent == "") {
          query = (await _controller_test!.getTitle())!;
        } else {
          query = _webpageContent;
        }
        break;
      case "Title With Webpage Content":
        await _controller_test!.runJavascript("""
                        var x = window.innerWidth/2;
                        var y = window.innerHeight/2;
                        var centre = document.elementFromPoint(x, y);
                        Drill.postMessage(centre.innerText);
                      """);
        if (_webpageContent == null || _webpageContent == "") {
          query = (await _controller_test!.getTitle())!;
        } else {
          query = "${await _controller_test!.getTitle()} $_webpageContent";
        }
        break;
      case "Hovered Webpage Content":
        await _controller_test!.runJavascript("""
                        var centre = document.elementFromPoint($_hoverX, $_hoverY);
                        Drill.postMessage(centre.innerText);
                      """);
        if (_webpageContent == null || _webpageContent == "") {
          query = (await _controller_test!.getTitle())!;
        } else {
          query = _webpageContent;
        }
        break;
      case "New Mode":
        await _controller_test!.runJavascript("""
                var elementMouseIsOver = document.elementFromPoint($_hoverX, $_hoverY);
                var content = elementMouseIsOver.innerText;

                if (elementMouseIsOver.nodeName == "A"){
                    Drill.postMessage(elementMouseIsOver.href);
                }

                else if (content == "" || content == "null") {

                    if (elementMouseIsOver.nodeName == "IMG") {

                        if (elementMouseIsOver.alt == "" || elementMouseIsOver.alt == "null") {
                            Drill.postMessage(elementMouseIsOver.src);
                        } else {
                            Drill.postMessage(elementMouseIsOver.alt);
                        }

                    } else {
                        const cssObj = window.getComputedStyle(elementMouseIsOver, null);
                        let bgImage = cssObj.getPropertyValue("background-image");
                        const picUrl = bgImage.slice(5,-2);

                        Drill.postMessage(picUrl);

                    }

                } else {
                    Drill.postMessage(content);
                }
                      """);

        if (_webpageContent == null || _webpageContent == "") {
          query = (await _controller_test!.getTitle())!;
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

    var url = Uri.https('www.googleapis.com', '/customsearch/v1', {
      'key': API_KEY,
      'cx': ENGINE_ID,
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

        print(jsonResponse);
        print(jsonResponse['items']);

        var items = jsonResponse['items'] != null
            ? jsonResponse['items'] as List<dynamic>
            : [];

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
              URLs[keyword][platform]
                  .removeRange(_currentURLIndex + 1, length - _currentURLIndex);
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
    }
  }

  _updateCurrentURLs() async {
    setState(() {
      if (URLs[_searchText] == null) {
        print("no results");
        _searchResult = {};
      } else {
        print("have results ${URLs[_searchText]}");

        _searchResult = URLs[_searchText];
        // print("_searchResult $_searchResult");
        // _currentURLs = URLs[_searchText][_searchResult.keys.toList()[_currentDomainIndex]];
        _currentURLs = URLs[_searchText][_currentSearchPlatform];
        // print("_currentURLs $_currentURLs");
        _currentURLsPlain = _currentURLs.map((e) => e['link']).toList();
      }
    });
  }

  void _loadNewPage() {
    print("loading ${_currentURLs[_currentURLIndex]['link']}");
    _controller_test?.loadUrl(_currentURLs[_currentURLIndex]['link']);
  }

  _moveSwiper() async {
    setState(() {
      if (_isSearching) {
        print("popping...");
        Navigator.of(context).pop();
        // _marqueeKey = UniqueKey();
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

  void _handleSearch(value) async {
    setState(() {
      _searchMode = "Default";
      _appBarColor = Colors.blue[100]!;
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
    print("items $items");
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

  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers = {
    Factory(() => EagerGestureRecognizer())
  };

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
        print("Print ${message.message}");
        // setState(() {
        //   _webpageContent = message.message;
        // });
      },
    );
  }

  JavascriptChannel _getDrillTextChannel(BuildContext context) {
    return JavascriptChannel(
      name: 'Drill',
      onMessageReceived: (JavascriptMessage message) {
        print("DrillText ${message.message}");
        setState(() {
          _webpageContent = message.message;
        });
      },
    );
  }

  _performDrill() async {
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
      print("real drilling | ${await _getSearchQuery()}");

      var items =
          await _performSearch(await _getSearchQuery(), _currentSearchPlatform);

      await _updateURLs('append', _searchText, _currentSearchPlatform, items);
      await _updateCurrentURLs();
      setState(() {
        _currentURLIndex++;
        _swipe = true;
      });
      _loadNewPage();
    }

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
                  color: _appBarColor,
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
            ? GestureDetector(
                onLongPress: () {
                  _performDrill();
                },
                child: Draggable(
                  feedback: FloatingActionButton(
                    isExtended: true,
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
                  childWhenDragging: Container(),
                  onDragStarted: () {},
                  onDragEnd: (details) async {
                    RenderBox webViewBox = _webViewKey.currentContext
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
                        _hoverY = 0;
                        // print("1");
                      } else if (details.offset.dy - webViewY > webViewHeight) {
                        _hoverY = webViewHeight - 1;
                        // print("2");
                      } else {
                        _hoverY = details.offset.dy - webViewY;
                        // print("3");
                      }
                    });

                    // await _controller_test!.runJavascript("""
                    //     var x = window.innerWidth/2;
                    //     var y = window.innerHeight/2;
                    //     var centre = document.elementFromPoint($_hoverX, $_hoverY);
                    //     Drill.postMessage(centre.innerText);
                    //   """);
                    _performDrill();
                  },
                  child: FloatingActionButton(
                    onPressed: () {
                      // if (_searchMode == "Default") {
                      //   print("drill ONCE");
                      //   // drill logic
                      // } else {
                      //   print("already in drill-down mode");
                      // }
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
                              key: _webViewKey,
                              // gestureRecognizers: gestureRecognizers,
                              javascriptMode: JavascriptMode.unrestricted,
                              javascriptChannels: <JavascriptChannel>{
                                _toasterJavascriptChannel(context),
                                _getDrillTextChannel(context),
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

                                print("isar: $isar");

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

                                  _redirectStopwatch.stop();
                                  _redirectStopwatch.reset();
                                  setState(() {
                                    _redirecting = false;
                                  });
                                }

                                print("swiping $_swipe");

                                setState(() {
                                  _previousURL = url;
                                  if (!stopwatch.isRunning) {
                                    print("start stopwatch");
                                    stopwatch.start();
                                  }
                                  _loadingPercentage = 100;
                                });

                                setState(() {
                                  _swipe = false;
                                });
                              },
                            ),
                            // ),
                          ),

                          // Vertical Swiper
                          Container(
                            height: _loadingPercentage < 100 ? 55 : 50,
                            child: GestureDetector(
                                onTap: () {
                                  print("swiper tapped");
                                },
                                child: Container(
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
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            if (_currentURLIndex > 0) {
                                              setState(() {
                                                print("decrease");
                                                _currentURLIndex--;
                                                _swipe = true;
                                              });
                                              _loadNewPage();
                                            }
                                          },
                                          icon:
                                              const Icon(Icons.arrow_back_ios),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            if (_currentURLIndex <
                                                _currentURLs.length - 1) {
                                              setState(() {
                                                print("increase");
                                                _currentURLIndex++;
                                                _swipe = true;
                                              });
                                              _loadNewPage();
                                            }
                                          },
                                          icon: const Icon(
                                              Icons.arrow_forward_ios),
                                        ),
                                        DropdownButton<String>(
                                          value: _currentSearchPlatform,
                                          icon: const Icon(Icons.arrow_drop_up),
                                          elevation: 16,
                                          // style: const TextStyle(color: Colors.deepPurple),
                                          underline: Container(
                                            height: 2,
                                            // color: _appBarColor,
                                          ),
                                          onChanged: (String? value) async {
                                            print("value $value");

                                            setState(() {
                                              _currentSearchPlatform = value!;
                                            });

                                            _handleSearch(_realSearchText);
                                          },
                                          items: SearchPlatformList.map<
                                                  DropdownMenuItem<String>>(
                                              (String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ))
                                // Swiper(
                                //   itemCount: _searchResult.length,
                                //   loop: false,
                                //   scrollDirection: Axis.vertical,

                                //   itemBuilder: (BuildContext context, int index) {
                                //     return Container(
                                //       child: Stack(
                                //         children: <Widget>[
                                //           // Horizontal Swiper
                                //           Swiper(
                                //             itemCount: _currentURLs.length,
                                //             loop: false,
                                //             scrollDirection: Axis.horizontal,
                                //             controller:
                                //                 _swiperControllerHorizontal,
                                //             itemBuilder: (BuildContext context2,
                                //                 int index2) {
                                //               return Container(
                                //                 decoration: BoxDecoration(
                                //                   boxShadow: [
                                //                     BoxShadow(
                                //                       color: const Color.fromARGB(
                                //                               255, 182, 182, 182)
                                //                           .withOpacity(0.1),
                                //                       spreadRadius: 3,
                                //                       blurRadius: 5,
                                //                       // offset: const Offset(0,
                                //                       //     -50), // changes position of shadow
                                //                     ),
                                //                   ],
                                //                 ),
                                //                 child: const Align(
                                //                   alignment: Alignment.center,
                                //                   child: Text(
                                //                     "Swipe here to change page",
                                //                   ),
                                //                 ),
                                //               );
                                //             },
                                //             onIndexChanged: (index2) {
                                //               setState(() {
                                //                 _currentURLIndex = index2;
                                //                 _swipe = true;
                                //               });
                                //               _loadNewPage();
                                //             },
                                //           ),
                                //           if (_loadingPercentage < 100)
                                //             LinearProgressIndicator(
                                //               value: _loadingPercentage / 100.0,
                                //               minHeight: 5,
                                //               color: Colors.yellow,
                                //             ),
                                //         ],
                                //       ),
                                //     );
                                //   },
                                //   onIndexChanged: (index) {
                                //     setState(() {
                                //       _currentURLIndex = 0;
                                //       _currentDomainIndex = index;
                                //       _currentURLs = URLs[_searchText
                                //               .toString()
                                //               .toLowerCase()][
                                //           _searchResult.keys
                                //               .toList()[_currentDomainIndex]];

                                //       // print("_currentURLs $_currentURLs");
                                //       print("index $index");

                                //       _loadNewPage();
                                //     });
                                //   },
                                //   controller: _swiperControllerVertical,
                                //   // pagination: SwiperPagination(),
                                //   // control: SwiperControl(),
                                // ),
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
