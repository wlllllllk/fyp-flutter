import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

import 'package:image_picker/image_picker.dart';
import 'package:isar/isar.dart';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io' as io;
import 'package:path/path.dart' as p;
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/vision/v1.dart' as vision;
import 'package:googleapis/storage/v1.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart' as dio;
import 'package:stats/stats.dart';

import 'package:typed_data/typed_data.dart';

// import 'package:permission_handler/permission_handler.dart';
// import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class CredentialsProvider {
  CredentialsProvider();

  Future<ServiceAccountCredentials> get _credentials async {
    final directory = await getApplicationDocumentsDirectory();
    bool fileExists = false;
    String filename = "credential.json";
    File jsonCredential = File(directory.path + "/" + filename);
    fileExists = jsonCredential.existsSync();
    print("JSON EXIST?= " + fileExists.toString());

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

class SearchPage extends StatefulWidget {
  const SearchPage({
    Key? key,
    required this.realSearchText,
    required this.handleSearch,
    required this.performSearch,
    required this.updateURLs,
    required this.updateCurrentURLs,
    required this.moveSwiper,
    required this.updateSearchText,
  }) : super(key: key);

  final String realSearchText;
  final handleSearch;
  final performSearch;
  final updateURLs;
  final updateCurrentURLs;
  final moveSwiper;
  final updateSearchText;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchFieldController = TextEditingController();
  // String _realSearchText = "";

  @override
  void initState() {
    super.initState();
    // _realSearchText = widget.realSearchText;
    _searchFieldController.text = widget.realSearchText;
  }

  @override
  Widget build(BuildContext context) {
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
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Enter a search term',
              suffixIcon: Container(
                child: IntrinsicHeight(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        onPressed: _searchFieldController.clear,
                        icon: const Icon(Icons.clear),
                      ),
                      IconButton(
                        onPressed: () async {
                          print("picking...");
                          try {
                            final ImagePicker _picker = ImagePicker();
                            // Pick an image
                            final XFile? image = await _picker.pickImage(
                                source: ImageSource.camera);
                            print("image $image");
                            EasyLoading.showToast('image $image');
                            if (image != null) {
                              EasyLoading.show(status: 'Searching...');
                              Map results = await _cameraSearch(
                                  image, image.path, image.name);
                              print("image $results");

                              var items = null;
                              if (results["urls"].length == 0) {
                                items = await widget.performSearch(
                                    results["urls"], "Bing");
                                await widget.updateURLs(
                                    "replace", results['urls'], "Bing", items);
                              } else {
                                await widget.updateURLs("replace",
                                    results['urls'], "Bing", results['urls']);
                              }
                              await widget.updateCurrentURLs();
                              EasyLoading.dismiss();
                              EasyLoading.showToast(
                                  'results length ${results['urls'].length}');
                              await widget.moveSwiper();
                            }
                          } catch (e) {
                            print("error $e");
                            EasyLoading.showToast('error $e');
                          }
                          print("picked");
                        },
                        icon: const Icon(Icons.photo_camera),
                      ),
                      IconButton(
                        onPressed: () async {
                          print("picking...");
                          try {
                            final ImagePicker _picker = ImagePicker();
                            // Pick an image
                            final XFile? image = await _picker.pickImage(
                              source: ImageSource.gallery,
                              maxHeight: 1000,
                              maxWidth: 1000,
                              //imageQuality: 80,
                            );
                            print("image $image");
                            EasyLoading.showToast('image $image');
                            if (image != null) {
                              EasyLoading.show(status: 'Searching...');
                              Map results = await _imageSearch(
                                  image, image.path, image.name);
                              print("image $results");

                              await widget
                                  .updateSearchText(results["bestGuessLabel"]);
                              var items = null;
                              if (results['urls'].length == 0) {
                                items = await widget.performSearch(
                                    results["bestGuessLabel"], "Google");
                                await widget.updateURLs("replace",
                                    results['bestGuessLabel'], "Google", items);
                              } else {
                                await widget.updateURLs(
                                    "replace",
                                    results['bestGuessLabel'],
                                    "Google",
                                    results['urls']);
                              }
                              await widget.updateCurrentURLs();
                              EasyLoading.dismiss();
                              EasyLoading.showToast(
                                  'results length ${results['urls'].length}');
                              await widget.moveSwiper();
                            }
                          } catch (e) {
                            print("error $e");
                            EasyLoading.showToast('error $e');
                          }
                          print("picked");
                        },
                        icon: const Icon(Icons.photo),
                      ),
                    ],
                  ),
                ),
              ),
              // IconButton(
              //   onPressed: _searchFieldController.clear,
              //   icon: const Icon(Icons.photo),
              // ),
              //   ],
              // ),
            ),
            controller: _searchFieldController,
            onSubmitted: (value) {
              widget.handleSearch(value);
            },
            autocorrect: false,
            maxLines: 1,
          ),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: const Align(
          alignment: Alignment.center,
          child: Text(
            "Search here",
            style: TextStyle(fontSize: 22),
          ),
        ),
      ),
    );
  }
}

class Order {
  int area;
  String description;

  Order({required this.area, required this.description});
}

_imageSearch(src, path, name) async {
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

    Future logoDetection(String image) async {
      var _vision = vision.VisionApi(await _client);
      var _api = _vision.images;
      var _response =
          await _api.annotate(vision.BatchAnnotateImagesRequest.fromJson({
        "requests": [
          {
            "image": {"content": image},
            "features": [
              {
                "type": "LOGO_DETECTION",
              }
            ]
          }
        ]
      }));
      List<vision.EntityAnnotation> entities;
      var logoOutput;
      _response.responses?.forEach((data) {
        entities = data.logoAnnotations as List<vision.EntityAnnotation>;
        logoOutput = entities[0].description;
      });
      print(logoOutput);
    }

    Future TextDetection(String image) async {
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
        print("No words is detected");
        exit(1);
      }

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

        print(area);
        print(entities![j].description);
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

      //print(numberArr);
      orders.sort((a, b) => b.area.compareTo(a.area));
      print("Ordered Output text: ${orders.map((order) => order.description)}");

      print("TEXT: $str_arr");
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
      // print(entity.entityId);
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
          print("not null1 | ${data.webDetection?.partialMatchingImages}");
        } else {
          print("null1");
        }

        if (data.webDetection?.pagesWithMatchingImages != null) {
          pageWithMatchImage = data.webDetection!.pagesWithMatchingImages
              as List<vision.WebPage>;
          print("not null2 | ${data.webDetection?.pagesWithMatchingImages}");
        } else {
          print("null2");
        }

        if (data.webDetection?.visuallySimilarImages != null) {
          pageWithSimilarImage =
              data.webDetection!.visuallySimilarImages as List<vision.WebImage>;
          print("not null3 | ${data.webDetection?.visuallySimilarImages}");
        } else {
          print("null3");
        }

        print("_label 4 | ${_label as List<vision.WebLabel>}");
        bestguess = _label?.single ?? '';
        //entity = entities!;
      });

      // print("best guess label=  " + bestguess.label.toString());
      String bestGuessLabel = bestguess.label.toString();

      i = 0;
      var j = 0;

      Map results = {"bestGuessLabel": bestGuessLabel};
      List urls = [];
      int len = pageWithSimilarImage?.length ?? 0;
      for (j = 0; j < len; j++) {
        // print("page with match image title=" +
        //     page_with_match_image![j].pageTitle.toString());
        // print("page with match image =" +
        //     page_with_match_image![j].url.toString());

        if (pageWithMatchImage != null) {
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

    Future BingSearch(String imgpath, String img64) async {
      final apiKey = "bb1d24eb3001462a9a8bd1b554ad59fa";
      final imageData = base64.encode(File(imgpath).readAsBytesSync());

      var uri =
          Uri.parse('https://api.bing.microsoft.com/v7.0/images/visualsearch');
      var headers = {
        'Ocp-Apim-Subscription-Key': 'bb1d24eb3001462a9a8bd1b554ad59fa'
      };

      var request = http.MultipartRequest('POST', uri)
        ..headers.addAll(headers)
        ..files.add(await http.MultipartFile.fromPath('image', imgpath,
            filename: 'myfile'));
      var response = await request.send();
      // Convert the base64 image to bytes

      final String responseString = await response.stream.bytesToString();

      print(responseString);

      List Result = [];
      // Convert the base64 image to bytes

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(responseString);
        final elements = responseJson['tags'][0]['actions'];
        var bingVisualObject;

        print("response code ${response.statusCode}");
        elements.forEach((data) => {
              if (data['actionType'] == "VisualSearch")
                {bingVisualObject = data['data']['value']}
            });

        bingVisualObject.forEach((value) {
          print("Website name: ${value['name']}");
          print("website: ${value['hostPageUrl']}");
          Result.add({
            'title': value['name'].toString(),
            'link': value['hostPageUrl'].toString(),
          });
        });
      } else {
        print('Failed to upload image. Error code: ${response.statusCode}');
      }
      return Result;
    }

    var bingVisualResult = BingSearch(path, img64);
    //BingVisualSearch(img64, path, name);
    var webResults = webSearch(img64);
    // TextDetection(img64);
    // logoDetection(img64);

    // print("results = ${await Future.value(results)}");
    return await Future.value(webResults);
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

_cameraSearch(src, path, name) async {
  final bytes = io.File(path).readAsBytesSync();
  String img64 = base64Encode(bytes);

  Future BingSearch(String imgpath, String img64) async {
    final apiKey = "bb1d24eb3001462a9a8bd1b554ad59fa";
    final imageData = base64.encode(File(imgpath).readAsBytesSync());

    var uri =
        Uri.parse('https://api.bing.microsoft.com/v7.0/images/visualsearch');
    var headers = {
      'Ocp-Apim-Subscription-Key': 'bb1d24eb3001462a9a8bd1b554ad59fa'
    };

    var request = http.MultipartRequest('POST', uri)
      ..headers.addAll(headers)
      ..files.add(await http.MultipartFile.fromPath('image', imgpath,
          filename: 'myfile'));
    var response = await request.send();
    // Convert the base64 image to bytes

    final String responseString = await response.stream.bytesToString();

    print(responseString);

    Map out = {};
    List results = [];
    // Convert the base64 image to bytes

    if (response.statusCode == 200) {
      final responseJson = jsonDecode(responseString);
      final elements = responseJson['tags'][0]['actions'];
      var bingVisualObject;

      print("response code ${response.statusCode}");
      elements.forEach((data) => {
            if (data['actionType'] == "VisualSearch")
              {bingVisualObject = data['data']['value']}
          });

      bingVisualObject.forEach((value) {
        print("Website name: ${value['name']}");
        print("website: ${value['hostPageUrl']}");
        results.add({
          'title': value['name'].toString(),
          'link': value['hostPageUrl'].toString(),
        });
      });
    } else {
      print('Failed to upload image. Error code: ${response.statusCode}');
    }
    out.addAll({'urls': results});
    return out;
  }

  var bingVisualResult = BingSearch(path, img64);
  return bingVisualResult;
}
/*
_cameraSerach(image, path) async {
  final InputImage inputImage = InputImage.fromFilePath(path);

  const mode = DetectionMode.single;

  Future<String> _getModel(String assetPath) async {
    if (io.Platform.isAndroid) {
      return 'flutter_assets/$assetPath';
    }
    final path = '${(await getApplicationSupportDirectory()).path}/$assetPath';
    await io.Directory(path).create(recursive: true);
    final file = io.File(path);
    if (!await file.exists()) {
      final byteData = await rootBundle.load(assetPath);
      await file.writeAsBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
    return file.path;
  }

  final modelPath = await _getModel(
      'assets/ml/lite-model_on_device_vision_classifier_popular_us_products_V1_1.tflite');
// Options to configure the detector whil1 using a Firebase model.
  final options = LocalObjectDetectorOptions(
    mode: mode,
    modelPath: modelPath,
    classifyObjects: true,
    multipleObjects: true,
  );

  final objectDetector = ObjectDetector(options: options);

  final List<DetectedObject> objects =
      await objectDetector.processImage(inputImage);

  for (DetectedObject detectedObject in objects) {
    final rect = detectedObject.boundingBox;
    final trackingId = detectedObject.trackingId;

    for (Label label in detectedObject.labels) {
      print('${label.text} ${label.confidence}');
    }
  }
  objectDetector.close();
}*/
