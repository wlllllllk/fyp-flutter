import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:isar/isar.dart';

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
import 'package:googleapis/storage/v1.dart';

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
                              Map results =
                                  await _imageSearch(image, image.path);
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
                        icon: const Icon(Icons.photo_camera),
                      ),
                      IconButton(
                        onPressed: () async {
                          print("picking...");
                          try {
                            final ImagePicker _picker = ImagePicker();
                            // Pick an image
                            final XFile? image = await _picker.pickImage(
                                source: ImageSource.gallery);
                            print("image $image");
                            EasyLoading.showToast('image $image');
                            if (image != null) {
                              EasyLoading.show(status: 'Searching...');
                              Map results =
                                  await _imageSearch(image, image.path);
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

    Future<String?> TextDetection(String image) async {
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
      int len = entities!.length;
      print("Output text: ");
      for (int j = 0; j < len; j++) {
        print(entities![j].description);
      }
      return entities![1].description;
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
      List<vision.WebImage>? full_match_image;
      List<vision.WebImage>? partial_match_image;
      List<vision.WebPage>? page_with_match_image;
      List<vision.WebImage>? page_with_similar_image;

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
          partial_match_image =
              data.webDetection!.partialMatchingImages as List<vision.WebImage>;
          print("not null1 | ${data.webDetection?.partialMatchingImages}");
        } else {
          print("null1");
        }

        if (data.webDetection?.pagesWithMatchingImages != null) {
          page_with_match_image = data.webDetection!.pagesWithMatchingImages
              as List<vision.WebPage>;
          print("not null2 | ${data.webDetection?.pagesWithMatchingImages}");
        } else {
          print("null2");
        }

        if (data.webDetection?.visuallySimilarImages != null) {
          page_with_similar_image =
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
      //for (i; i < 10; i++) {
      // print(entities![i].description);
      //  print("Full match url = " + full_match_image![i].url.toString());
      // print("Partial match url = " + partial_match_image![i].url.toString());
      // print("page with similar iamge = " +
      //     page_with_similar_image![i].url.toString());
      Map results = {"bestGuessLabel": bestGuessLabel};
      List urls = [];
      int len = page_with_similar_image?.length ?? 0;
      for (j = 0; j < len; j++) {
        // print("page with match image title=" +
        //     page_with_match_image![j].pageTitle.toString());
        // print("page with match image =" +
        //     page_with_match_image![j].url.toString());
        urls.add({
          'title': page_with_match_image![j].pageTitle.toString(),
          'link': page_with_match_image![j].url.toString()
        });
      }

      results.addAll({'urls': urls});

      // return _response;
      return results;
    }

    var webResults = webSearch(img64);
    TextDetection(img64);

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