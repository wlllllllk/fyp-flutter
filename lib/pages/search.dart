import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:fyp_searchub/main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    required this.searchPlatformList,
    required this.currentPlatform,
    required this.setImageSearch,
    required this.searchRecords,
    required this.updateSearchRecord,
    required this.platformIconBuilder,
    required this.imageSearchGoogle,
    required this.imageSearch,
    required this.mergeResults,
    required this.updateCurrentImage,
    required this.mergeSearch,
    required this.isTutorial,
    required this.updateIsTutorial,
    required this.enabledGeneralPlatforms,
    required this.enabledVideoPlatforms,
    required this.enabledSNSPlatforms,
    required this.updateEnabledPlatforms,
    required this.prefs,
  }) : super(key: key);

  final String realSearchText;
  final handleSearch;
  final performSearch;
  final updateURLs;
  final updateCurrentURLs;
  final moveSwiper;
  final updateSearchText;
  final searchPlatformList;
  final currentPlatform;
  final setImageSearch;
  final searchRecords;
  final updateSearchRecord;
  final platformIconBuilder;
  final imageSearchGoogle;
  final imageSearch;
  final mergeResults;
  final updateCurrentImage;
  final mergeSearch;
  final isTutorial;
  final updateIsTutorial;
  final enabledGeneralPlatforms;
  final enabledVideoPlatforms;
  final enabledSNSPlatforms;
  final updateEnabledPlatforms;
  final SharedPreferences prefs;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchFieldController = TextEditingController();
  String _platform = "";
  List _searchRecords = [];
  Set<String> _enabledGeneralPlatforms = {},
      _enabledVideoPlatforms = {},
      _enabledSNSPlatforms = {};
  final List<bool> _selectedGeneralPlatforms = <bool>[];
  final List<bool> _selectedVideoPlatforms = <bool>[];
  final List<bool> _selectedSNSPlatforms = <bool>[];

  // key
  final _textFieldKey = GlobalKey();
  final _cameraKey = GlobalKey();
  final _libraryKey = GlobalKey();
  final _platformsKey = GlobalKey();

  // tutorial
  List<TargetFocus> targets = [];
  var _tutorial;

  @override
  void initState() {
    super.initState();
    // _realSearchText = widget.realSearchText;
    _searchFieldController.text = widget.realSearchText;
    _platform = widget.currentPlatform;
    _searchRecords = widget.searchRecords;
    _enabledGeneralPlatforms = widget.enabledGeneralPlatforms.toSet();
    _enabledVideoPlatforms = widget.enabledVideoPlatforms.toSet();
    _enabledSNSPlatforms = widget.enabledSNSPlatforms.toSet();

    for (int i = 0; i < GeneralPlatformList.length; i++) {
      _selectedGeneralPlatforms
          .add(_enabledGeneralPlatforms.contains(GeneralPlatformList[i]));
    }
    for (int i = 0; i < VideoPlatformList.length; i++) {
      _selectedVideoPlatforms
          .add(_enabledVideoPlatforms.contains(VideoPlatformList[i]));
    }
    for (int i = 0; i < SNSPlatformList.length; i++) {
      _selectedSNSPlatforms
          .add(_enabledSNSPlatforms.contains(SNSPlatformList[i]));
    }

    EasyLoading.instance
      ..displayDuration = const Duration(milliseconds: 2000)
      ..indicatorType = EasyLoadingIndicatorType.ripple
      ..loadingStyle = EasyLoadingStyle.dark
      ..indicatorSize = 45.0
      ..radius = 10.0
      // ..progressColor = Colors.yellow
      // ..backgroundColor = Colors.green
      // ..indicatorColor = Colors.yellow
      // ..textColor = Colors.yellow
      // ..maskColor = Colors.blue.withOpacity(0.5)
      ..userInteractions = true
      ..maskType = EasyLoadingMaskType.black
      ..dismissOnTap = true;

    if (widget.isTutorial) {
      targets.add(
        TargetFocus(
          identify: "Platforms",
          keyTarget: _platformsKey,
          enableOverlayTab: true,
          shape: ShapeLightFocus.RRect,
          radius: 8,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const <Widget>[
                  Text(
                    "First, select what you are looking for",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "You can long-press to select specific platforms to be used",
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
          identify: "Text Field",
          keyTarget: _textFieldKey,
          enableOverlayTab: true,
          shape: ShapeLightFocus.RRect,
          radius: 8,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const <Widget>[
                  Text(
                    "Then, type in what you want to search",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0),
                  ),
                ],
              ),
            )
          ],
        ),
      );

      targets.add(
        TargetFocus(
          identify: "Camera Button",
          keyTarget: _cameraKey,
          enableOverlayTab: true,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const <Widget>[
                  Text(
                    "You can also take a photo",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0),
                  ),
                ],
              ),
            )
          ],
        ),
      );

      targets.add(
        TargetFocus(
          identify: "Library Button",
          keyTarget: _libraryKey,
          enableOverlayTab: true,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const <Widget>[
                  Text(
                    "Or upload an image from your device",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0),
                  ),
                ],
              ),
            )
          ],
        ),
      );

      targets.add(
        TargetFocus(
          identify: "Text Field",
          keyTarget: _textFieldKey,
          enableOverlayTab: true,
          shape: ShapeLightFocus.RRect,
          radius: 8,
          color: Colors.yellow,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "Now, try to perform your first search.",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                        fontSize: 20.0),
                  ),
                ],
              ),
            )
          ],
        ),
      );

      _showTutorial();
    }
  }

  void _showTutorial() async {
    await Future.delayed(const Duration(milliseconds: 300), () {});

    _tutorial = TutorialCoachMark(
        hideSkip: true,
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
          // if (target.identify == "Search Button") {
          //   _pushSearchPage();
          // }
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

  _pickImage(source) async {
    log("picking...");
    // try {
    final ImagePicker picker = ImagePicker();
    // Pick an image
    final XFile? image = source == "camera"
        ? await picker.pickImage(
            source: ImageSource.camera,
            maxHeight: 1000,
            maxWidth: 1000,
            imageQuality: 80,
          )
        : await picker.pickImage(
            source: ImageSource.gallery,
            maxHeight: 1000,
            maxWidth: 1000,
            imageQuality: 80,
          );
    log("image $image");
    // EasyLoading.showToast('image $image');

    final snackBar = SnackBar(
      content: Text("image $image"),
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    _performImageSearch(image);
  }

  _performImageSearch(image, [imgURI = ""]) async {
    log("image $image | imgURI $imgURI");
    if (image != null) {
      // widget.updateCurrentImage(image);

      Map results = {};
      List combinedResults = [];

      EasyLoading.show(
        status: 'Searching',
      );
      results = imgURI == ""
          ? await widget.imageSearch(image, image.path)
          : await widget.imageSearch("", "", imgURI);
      log("image search results1: $results");
      log("image search results2: $results['bestGuessList']");
      log("image search results3: $results['bestGuessListGoogle']");

      if (results["bestGuessList"] != null) {
        combinedResults.addAll(results["bestGuessList"]);
      }
      if (results["bestGuessListGoogle"] != null) {
        combinedResults.addAll(results["bestGuessListGoogle"]);
      }
      log("image search combinedResults: $combinedResults");

      if (combinedResults.isEmpty) {
        EasyLoading.dismiss();

        // ignore: use_build_context_synchronously
        await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("No results found"),
                content: const Text("Please try to change the search query"),
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
      } else {
        List keywords = combinedResults;
        log("keywords: $keywords");

        List<MultiSelectItem> platforms = [];
        for (var i = 0; i < SearchPlatformList.length; i++) {
          platforms.add(
              MultiSelectItem(SearchPlatformList[i], SearchPlatformList[i]));
        }

        EasyLoading.dismiss();

        List selectedKeyword = [];
        String selectedPlatform = "";
        bool abort = false;

        // ignore: use_build_context_synchronously
        await showDialog<String>(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: const Text('Are you looking for one of these?'),
            content: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Column(
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: MultiSelectChipField(
                      title: const Text(
                        "Look for",
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
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: MultiSelectChipField(
                      // key: selectKey,
                      title: const Text(
                        "Suggested Items",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      decoration: const BoxDecoration(
                        border: null,
                      ),
                      items: keywords
                          .map((keyword) => MultiSelectItem(
                                keyword["urls"] ?? keyword["link"],
                                keyword["bestGuessLabel"] ?? keyword["link"],
                              ))
                          .toList(),
                      itemBuilder: (item, state) {
                        return InkWell(
                          onTap: () {
                            log("selected: ${item.label}");
                            if (selectedKeyword.contains(item.label)) {
                              selectedKeyword.clear();
                            } else {
                              selectedKeyword.clear();
                              selectedKeyword.add(item.label);
                            }

                            log("selectedKeyword: ${selectedKeyword}");

                            state.didChange(selectedKeyword);
                            // selectKey.currentState?.validate();
                          },
                          child: ClipRRect(
                            // borderRadius: BorderRadius.circular(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedContainer(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: selectedKeyword.contains(item.label)
                                        ? const Color.fromRGBO(
                                            158, 158, 158, 0.475)
                                        : Colors.transparent,
                                  ),
                                  width: MediaQuery.of(context).size.width / 3 -
                                      10,
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    children: [
                                      Opacity(
                                        opacity:
                                            selectedKeyword.contains(item.label)
                                                ? 0.5
                                                : 1,
                                        child: Image.network(
                                          item.value.toString(),
                                          // height: 100,
                                          width:
                                              MediaQuery.of(context).size.width,
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                          },
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            log("error: $error");
                                            return const Center(
                                              child: Icon(Icons.error),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        item.label,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        );
                      },
                      showHeader: false,
                      scroll: false,
                      // validator: (value) {
                      //   log("value: $value");
                      // },
                      // onTap: (values) {
                      //   log("selected: $values");
                      //   // selectedKeywords = values.join(" ").trim();
                      //   // log("updated $selecßtedKeywords");
                      // },
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context, 'Cancel');
                  abort = true;
                },
                child: const Text('Cancel'),
              ),
              // TextButton(
              //   onPressed: () {
              //     Navigator.pop(context, 'ALL');
              //   },
              //   child: const Text('Drill ALL'),
              // ),
              TextButton(
                onPressed: () {
                  log("final selected keywords: $selectedKeyword");
                  if (selectedKeyword.isEmpty) {
                    return;
                  }
                  Navigator.pop(context, 'OK');
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );

        // widget.updateSearchText(selectedKeyword[0]);
        // await widget.mergeSearch(selectedPlatform);
        if (!abort) {
          if (selectedKeyword[0].toString().startsWith('http')) {
            log("is image url");
            EasyLoading.show(
              status: 'Searching',
            );
            _performImageSearch("", selectedKeyword[0]);
          } else {
            await widget.handleSearch(
                selectedKeyword[0],
                selectedPlatform == ""
                    ? widget.currentPlatform
                    : selectedPlatform);
          }
        }
        EasyLoading.dismiss();
      }
    }
    // } catch (e) {
    //   log("error image search $e");
    //   EasyLoading.showToast('error $e');
    // }
    // log("picked");
  }

  _selectPlatforms(type) async {
    List<String> temp = [];
    List<bool> tempEnabled = [];
    int numOfEnabled = 0;

    if (type == "General") {
      temp = GeneralPlatformList;
      tempEnabled = _selectedGeneralPlatforms;
      numOfEnabled =
          _selectedGeneralPlatforms.where((element) => element == true).length;
    } else if (type == "Video") {
      temp = VideoPlatformList;
      tempEnabled = _selectedVideoPlatforms;
      numOfEnabled =
          _selectedVideoPlatforms.where((element) => element == true).length;
    } else if (type == "SNS") {
      temp = SNSPlatformList;
      tempEnabled = _selectedSNSPlatforms;
      numOfEnabled =
          _selectedSNSPlatforms.where((element) => element == true).length;
    }

    await showDialog<String>(
        // barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setAlertState) {
              return AlertDialog(
                scrollable: true,
                title: const Text('Platforms to be searched on'),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: ToggleButtons(
                    direction: Axis.vertical,
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    isSelected: tempEnabled,
                    children: [
                      ...temp
                          .map(
                            (e) => Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  widget.platformIconBuilder(e),
                                  const SizedBox(width: 10),
                                  Text(e),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ],
                    onPressed: (int index) async {
                      log("pressed $index | ${tempEnabled[index]} | ${tempEnabled.length} | $numOfEnabled");

                      if (numOfEnabled == 1 && tempEnabled[index] == true) {
                        EasyLoading.showToast(
                            "At least one platform must be enabled");
                        return;
                      }

                      if (type == "General") {
                        setAlertState(() {
                          _selectedGeneralPlatforms[index] =
                              !_selectedGeneralPlatforms[index];

                          numOfEnabled = _selectedGeneralPlatforms
                              .where((element) => element == true)
                              .length;
                        });

                        List<String> newEnabledPlatforms =
                            GeneralPlatformList.where((element) =>
                                _selectedGeneralPlatforms[
                                    GeneralPlatformList.indexOf(element)] ==
                                true).toList();

                        log("test: $newEnabledPlatforms");

                        widget.updateEnabledPlatforms(
                            type, newEnabledPlatforms);

                        await widget.prefs.setStringList(
                            "enabledGeneralPlatforms", newEnabledPlatforms);
                      } else if (type == "Video") {
                        setAlertState(() {
                          _selectedVideoPlatforms[index] =
                              !_selectedVideoPlatforms[index];

                          numOfEnabled = _selectedVideoPlatforms
                              .where((element) => element == true)
                              .length;
                        });

                        List<String> newEnabledPlatforms =
                            VideoPlatformList.where((element) =>
                                _selectedVideoPlatforms[
                                    VideoPlatformList.indexOf(element)] ==
                                true).toList();

                        log("test: $newEnabledPlatforms");

                        widget.updateEnabledPlatforms(
                            type, newEnabledPlatforms);

                        await widget.prefs.setStringList(
                            "enabledVideoPlatforms", newEnabledPlatforms);
                      } else if (type == "SNS") {
                        setAlertState(() {
                          _selectedSNSPlatforms[index] =
                              !_selectedSNSPlatforms[index];

                          numOfEnabled = _selectedSNSPlatforms
                              .where((element) => element == true)
                              .length;
                        });

                        List<String> newEnabledPlatforms =
                            SNSPlatformList.where((element) =>
                                _selectedSNSPlatforms[
                                    SNSPlatformList.indexOf(element)] ==
                                true).toList();

                        log("test: $newEnabledPlatforms");

                        widget.updateEnabledPlatforms(
                            type, newEnabledPlatforms);

                        await widget.prefs.setStringList(
                            "enabledSNSPlatforms", newEnabledPlatforms);
                      }
                    },
                  ),
                ),
                actions: <Widget>[
                  // TextButton(
                  //   onPressed: () {
                  //     Navigator.pop(context, 'Cancel');
                  //   },
                  //   child: const Text('Cancel'),
                  // ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, 'OK');
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool pop = true;
        if (widget.isTutorial) {
          await showDialog(
              context: context,
              builder: (BuildContext context) {
                return SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: AlertDialog(
                    title: const Text("Tutorial in progress"),
                    content: const Text("Do you want to end it?"),
                    actions: [
                      TextButton(
                        child: const Text("No"),
                        onPressed: () {
                          pop = false;
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text("Yes"),
                        onPressed: () {
                          // pop = true;
                          _tutorial.finish();
                          widget.updateIsTutorial(false);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );
              });
        }

        // if (end) {
        return Future.value(pop);
        // } else {
        //   return Future.value(false);
        // }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Column(
              // height: 40,
              // padding: const EdgeInsets.only(left: 15),
              // decoration: BoxDecoration(
              // color: Colors.white,
              // borderRadius: BorderRadius.circular(10),
              // ),
              children: <Widget>[
                TextField(
                  key: _textFieldKey,
                  textInputAction: TextInputAction.search,
                  autofocus: true,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter here',
                    // prefixIcon: ClipRRect(
                    //   borderRadius: BorderRadius.circular(10),
                    //   child: MenuButton(
                    //     decoration: BoxDecoration(
                    //       color: Colors.white,
                    //       borderRadius: BorderRadius.circular(10),
                    //     ),
                    //     topDivider: false,
                    //     child: widget.platformIconBuilder(_platform),
                    //     menuButtonBackgroundColor: Colors.white,
                    //     items: SearchPlatformList,
                    //     itemBuilder: (String value) => SizedBox(
                    //       height: 50,
                    //       child: widget.platformIconBuilder(value),
                    //     ),
                    //     onItemSelected: (value) {
                    //       log("value $value");
                    //       // widget.updateCurrentURLs(value);
                    //       // widget.moveSwiper(0);
                    //       setState(() {
                    //         _platform = value as String;
                    //       });
                    //     },
                    //   ),
                    // ),
                    suffixIcon: IntrinsicHeight(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            onPressed: _searchFieldController.clear,
                            icon: const Icon(Icons.clear),
                          ),
                          IconButton(
                            key: _cameraKey,
                            onPressed: () async {
                              _pickImage("camera");
                            },
                            icon: const Icon(Icons.photo_camera),
                          ),
                          IconButton(
                            key: _libraryKey,
                            onPressed: () async {
                              _pickImage("gallery");
                            },
                            icon: const Icon(Icons.photo),
                          ),
                        ],
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
                    if (value != "") widget.handleSearch(value, _platform);
                  },
                  autocorrect: false,
                  maxLines: 1,
                ),
              ]),
        ),
        body: Container(
          color: Colors.white,
          child: Align(
            alignment: Alignment.center,
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      left: 16.0, right: 16.0, bottom: 16.0),
                  child: SegmentedButton(
                    key: _platformsKey,
                    showSelectedIcon: false,
                    segments: SearchPlatformList.map((e) => ButtonSegment(
                          value: e,
                          label: GestureDetector(
                              onLongPress: () {
                                log("$e label long pressed");
                                _selectPlatforms(e);
                              },
                              child: Text(e)),
                          icon: GestureDetector(
                              onLongPress: () {
                                log("$e icon long pressed");
                                _selectPlatforms(e);
                              },
                              child: widget.platformIconBuilder(e)),
                        )).toList(),
                    selected: {_platform},
                    onSelectionChanged: (newSelection) {
                      log("newSelection $newSelection");

                      setState(() {
                        // By default there is only a single segment that can be
                        // selected at one time, so its value is always the first
                        // item in the selected set.
                        _platform = newSelection.first.toString();
                      });
                    },
                  ),
                ),
                ..._searchRecords.map((record) {
                  return ListTile(
                    title: Text(record.searchText,
                        style: const TextStyle(
                          fontSize: 18,
                        )),
                    trailing: Wrap(
                      children: [
                        IconButton(
                          icon: const Icon(EvaIcons.diagonal_arrow_left_up),
                          onPressed: () async {
                            _searchFieldController.text = record.searchText;
                          },
                        ),
                        IconButton(
                          icon: const Icon(EvaIcons.close_outline),
                          onPressed: () async {
                            log("delete");
                            await widget.updateSearchRecord(
                                record.searchText, true);
                            setState(() {
                              _searchRecords.removeWhere(
                                  (r) => r.searchText == record.searchText);
                            });
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      log("record.searchText ${record.searchText}");
                      widget.handleSearch(record.searchText, _platform);
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
