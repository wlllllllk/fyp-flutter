import 'dart:developer';

// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fyp_searchub/main.dart';
import 'package:googleapis/chat/v1.dart';
import 'package:icons_plus/icons_plus.dart';
// import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:babstrap_settings_screen/babstrap_settings_screen.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    Key? key,
    required this.updateSelectedPageIndex,
    required this.updateSearchAlgorithm,
    required this.searchAlgorithm,
    required this.SearchAlgorithmList,
    required this.updateGeneralMergeAlgorithm,
    required this.updateVideoMergeAlgorithm,
    required this.generalMergeAlgorithm,
    required this.videoMergeAlgorithm,
    required this.GeneralMergeAlgorithmList,
    required this.VideoMergeAlgorithmList,
    required this.updatePreloadNumber,
    required this.preloadNumber,
    required this.updateReverseJoystick,
    required this.reverseJoystick,
    required this.updateAutoSwitchPlatform,
    required this.autoSwitchPlatform,
    required this.prefs,
  }) : super(key: key);

  final updateSelectedPageIndex;
  final updateSearchAlgorithm;
  final searchAlgorithm;
  final updateGeneralMergeAlgorithm;
  final updateVideoMergeAlgorithm;
  final generalMergeAlgorithm;
  final videoMergeAlgorithm;
  final updatePreloadNumber;
  final bool preloadNumber;
  final updateAutoSwitchPlatform;
  final bool reverseJoystick;
  final updateReverseJoystick;
  final int autoSwitchPlatform;
  final List<String> SearchAlgorithmList;
  final List<String> GeneralMergeAlgorithmList;
  final List<String> VideoMergeAlgorithmList;
  final SharedPreferences prefs;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  var _searchAlgorithm;
  var _generalMergeAlgorithm;
  var _videoMergeAlgorithm;
  var _preloadNumber;
  var _reverseJoystick;
  var _autoSwitchPlatform;
  final List<bool> _selectedExtractionMethods = <bool>[];
  final List<bool> _selectedGeneralMergeAlgorithms = <bool>[];
  final List<bool> _selectedVideoMergeAlgorithms = <bool>[];

  @override
  void initState() {
    super.initState();
    _searchAlgorithm = widget.searchAlgorithm;
    _generalMergeAlgorithm = widget.generalMergeAlgorithm;
    _videoMergeAlgorithm = widget.videoMergeAlgorithm;
    _preloadNumber = widget.preloadNumber;
    _reverseJoystick = widget.reverseJoystick;
    _autoSwitchPlatform = widget.autoSwitchPlatform;
    for (int i = 0; i < widget.SearchAlgorithmList.length; i++) {
      log("_searchAlgorithm: $_searchAlgorithm | ${widget.SearchAlgorithmList[i]}");
      _selectedExtractionMethods
          .add(_searchAlgorithm == widget.SearchAlgorithmList[i]);
    }
    log("_selectedExtractionMethods: $_selectedExtractionMethods");
    for (int i = 0; i < widget.GeneralMergeAlgorithmList.length; i++) {
      _selectedGeneralMergeAlgorithms
          .add(_generalMergeAlgorithm == widget.GeneralMergeAlgorithmList[i]);
    }
    for (int i = 0; i < widget.VideoMergeAlgorithmList.length; i++) {
      _selectedVideoMergeAlgorithms
          .add(_videoMergeAlgorithm == widget.VideoMergeAlgorithmList[i]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        widget.updateSelectedPageIndex(0);
        return Future.value(true);
      },
      child: Scaffold(
        appBar: AppBar(
          // backgroundColor: Colors.white,
          title: Container(
            child: const Text("Settings"),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () {
              widget.updateSelectedPageIndex(0);
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Container(
          // color: Colors.white,
          child: Align(
            alignment: Alignment.center,
            child: ListView(
              children: [
                SettingsGroup(
                  items: [
                    // SettingsItem(
                    //   onTap: () {},
                    //   icons: CupertinoIcons.pencil_outline,
                    //   iconStyle: IconStyle(),
                    //   title: 'Appearance',
                    //   subtitle: "Make Ziar'App yours",
                    // ),
                    SettingsItem(
                      onTap: () {},
                      backgroundColor: Colors.black,
                      icons: Icons.next_plan,
                      iconStyle: IconStyle(
                        iconsColor: Colors.white,
                        withBackground: true,
                        backgroundColor: Colors.blue,
                      ),
                      title: 'Result Preloading',
                      subtitle: "Restart the app to take effect.",
                      trailing: Switch.adaptive(
                        value: _preloadNumber,
                        onChanged: (value) async {
                          print("_preloadNumber $value");

                          widget.updatePreloadNumber(value);

                          setState(() {
                            _preloadNumber = value;
                          });

                          await widget.prefs.setBool(
                            "preloadNumber",
                            value,
                          );
                        },
                      ),
                    ),
                    SettingsItem(
                      onTap: () {},
                      backgroundColor: Colors.black,
                      icons: BoxIcons.bx_move_horizontal,
                      iconStyle: IconStyle(
                        iconsColor: Colors.white,
                        withBackground: true,
                        backgroundColor: Colors.blue,
                      ),
                      title: 'Reversed Joystick',
                      subtitle: _reverseJoystick
                          ? "Mimics swiping the webpage"
                          : "Mimics dragging the joystick",
                      trailing: Switch.adaptive(
                        value: _reverseJoystick,
                        onChanged: (value) async {
                          print("_reverseJoystick $value");

                          widget.updateReverseJoystick(value);

                          setState(() {
                            _reverseJoystick = value;
                          });

                          await widget.prefs.setBool(
                            "reverseJoystick",
                            value,
                          );
                        },
                      ),
                    ),
                    SettingsItem(
                      backgroundColor: Colors.black,
                      icons: Icons.exit_to_app,
                      iconStyle: IconStyle(
                        iconsColor: Colors.white,
                        withBackground: true,
                        backgroundColor: Colors.orange,
                      ),
                      title: 'Extraction Method',
                      subtitle: _searchAlgorithm,
                      onTap: () async {
                        log("tapped");
                        await showDialog<String>(
                          // barrierDismissible: false,
                          context: context,
                          builder: (BuildContext context) {
                            return StatefulBuilder(
                              builder: (context, setAlertState) {
                                return AlertDialog(
                                  scrollable: true,
                                  title: const Text('Extraction Method'),
                                  content: ToggleButtons(
                                    direction: Axis.vertical,
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(8)),
                                    isSelected: _selectedExtractionMethods,
                                    children: [
                                      ...widget.SearchAlgorithmList.map(
                                          (e) => Text(e)).toList(),
                                    ],
                                    onPressed: (int index) async {
                                      setAlertState(() {
                                        // The button that is tapped is set to true, and the others to false.
                                        for (int i = 0;
                                            i <
                                                _selectedExtractionMethods
                                                    .length;
                                            i++) {
                                          _selectedExtractionMethods[i] =
                                              i == index;
                                        }
                                      });

                                      log("selected: ${SearchAlgorithmList[index]}");

                                      widget.updateSearchAlgorithm(
                                          SearchAlgorithmList[index]);

                                      setState(() {
                                        _searchAlgorithm =
                                            SearchAlgorithmList[index];
                                      });

                                      await widget.prefs.setString(
                                        "searchAlgorithm",
                                        SearchAlgorithmList[index],
                                      );

                                      Navigator.pop(context);
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                    SettingsItem(
                      backgroundColor: Colors.black,
                      icons: HeroIcons.globe_alt,
                      iconStyle: IconStyle(
                        iconsColor: Colors.white,
                        withBackground: true,
                        backgroundColor: Colors.green,
                      ),
                      title: 'General Merge Algorithm',
                      subtitle: _generalMergeAlgorithm,
                      onTap: () async {
                        log("tapped");
                        await showDialog<String>(
                          // barrierDismissible: false,
                          context: context,
                          builder: (BuildContext context) {
                            return StatefulBuilder(
                              builder: (context, setAlertState) {
                                return AlertDialog(
                                  scrollable: true,
                                  title: const Text('General Merge Algorithm'),
                                  content: ToggleButtons(
                                    direction: Axis.vertical,
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(8)),
                                    isSelected: _selectedGeneralMergeAlgorithms,
                                    children: [
                                      ...widget.GeneralMergeAlgorithmList.map(
                                          (e) => Text(e)).toList(),
                                    ],
                                    onPressed: (int index) async {
                                      setAlertState(() {
                                        // The button that is tapped is set to true, and the others to false.
                                        for (int i = 0;
                                            i <
                                                _selectedGeneralMergeAlgorithms
                                                    .length;
                                            i++) {
                                          _selectedGeneralMergeAlgorithms[i] =
                                              i == index;
                                        }
                                      });

                                      widget.updateGeneralMergeAlgorithm(
                                          GeneralMergeAlgorithmList[index]);

                                      setState(() {
                                        _generalMergeAlgorithm =
                                            GeneralMergeAlgorithmList[index];
                                      });

                                      await widget.prefs.setString(
                                        "generalMergeAlgorithm",
                                        GeneralMergeAlgorithmList[index],
                                      );

                                      Navigator.pop(context);
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                    SettingsItem(
                      backgroundColor: Colors.black,
                      icons: BoxIcons.bx_video,
                      iconStyle: IconStyle(
                        iconsColor: Colors.white,
                        withBackground: true,
                        backgroundColor: Colors.green,
                      ),
                      title: 'Video Merge Algorithm',
                      subtitle: _videoMergeAlgorithm,
                      onTap: () async {
                        log("tapped");
                        await showDialog<String>(
                          // barrierDismissible: false,
                          context: context,
                          builder: (BuildContext context) {
                            return StatefulBuilder(
                              builder: (context, setAlertState) {
                                return AlertDialog(
                                  scrollable: true,
                                  title: const Text('Video Merge Algorithm'),
                                  content: ToggleButtons(
                                    direction: Axis.vertical,
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(8)),
                                    isSelected: _selectedVideoMergeAlgorithms,
                                    children: [
                                      ...widget.VideoMergeAlgorithmList.map(
                                          (e) => Text(e)).toList(),
                                    ],
                                    onPressed: (int index) async {
                                      setAlertState(() {
                                        // The button that is tapped is set to true, and the others to false.
                                        for (int i = 0;
                                            i <
                                                _selectedVideoMergeAlgorithms
                                                    .length;
                                            i++) {
                                          _selectedVideoMergeAlgorithms[i] =
                                              i == index;
                                        }
                                      });

                                      widget.updateGeneralMergeAlgorithm(
                                          VideoMergeAlgorithmList[index]);

                                      setState(() {
                                        _videoMergeAlgorithm =
                                            VideoMergeAlgorithmList[index];
                                      });

                                      await widget.prefs.setString(
                                        "videoMergeAlgorithm",
                                        VideoMergeAlgorithmList[index],
                                      );

                                      Navigator.pop(context);
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
