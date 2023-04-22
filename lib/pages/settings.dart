import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:babstrap_settings_screen/babstrap_settings_screen.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    Key? key,
    required this.updateSelectedPageIndex,
    required this.updateSearchAlgorithm,
    required this.searchAlgorithm,
    required this.SearchAlgorithmList,
    required this.updateMergeAlgorithm,
    required this.mergeAlgorithm,
    required this.MergeAlgorithmList,
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
  final updateMergeAlgorithm;
  final mergeAlgorithm;
  final updatePreloadNumber;
  final bool preloadNumber;
  final updateAutoSwitchPlatform;
  final bool reverseJoystick;
  final updateReverseJoystick;
  final int autoSwitchPlatform;
  final List<String> SearchAlgorithmList;
  final List<String> MergeAlgorithmList;
  final SharedPreferences prefs;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  var _searchAlgorithm;
  var _mergeAlgorithm;
  var _preloadNumber;
  var _reverseJoystick;
  var _autoSwitchPlatform;

  @override
  void initState() {
    super.initState();
    _searchAlgorithm = widget.searchAlgorithm;
    _mergeAlgorithm = widget.mergeAlgorithm;
    _preloadNumber = widget.preloadNumber;
    _reverseJoystick = widget.reverseJoystick;
    _autoSwitchPlatform = widget.autoSwitchPlatform;
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
          backgroundColor: Colors.white,
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
          color: Colors.white,
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
                      // subtitle: "",
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
                  ],
                ),
                ListTile(
                  title: const Text("Extraction Method"),
                  subtitle:
                      const Text("How the drill-down content is extracted."),
                  trailing: DropdownButton<String>(
                    value: _searchAlgorithm,
                    icon: const Icon(Icons.arrow_downward),
                    elevation: 16,
                    // style: const TextStyle(color: Colors.deepPurple),
                    underline: Container(
                      height: 2,
                      // color: _appBarColor,
                    ),
                    onChanged: (String? value) async {
                      print("value $value");

                      widget.updateSearchAlgorithm(value);

                      setState(() {
                        _searchAlgorithm = value;
                      });

                      await widget.prefs.setString(
                        "searchAlgorithm",
                        value!,
                      );
                    },
                    items: widget.SearchAlgorithmList.asMap().entries.map(
                      (entry) {
                        return DropdownMenuItem<String>(
                          value: entry.value,
                          child: Text(entry.value),
                        );
                      },
                    ).toList(),
                  ),
                ),
                ListTile(
                  title: const Text("Merge Algorithm"),
                  subtitle: const Text(
                      "How the results from different platforms are merged."),
                  trailing: DropdownButton<String>(
                    value: _mergeAlgorithm,
                    icon: const Icon(Icons.arrow_downward),
                    elevation: 16,
                    // style: const TextStyle(color: Colors.deepPurple),
                    underline: Container(
                      height: 2,
                      // color: _appBarColor,
                    ),
                    onChanged: (String? value) async {
                      print("value $value");

                      widget.updateMergeAlgorithm(value);

                      setState(() {
                        _mergeAlgorithm = value;
                      });

                      await widget.prefs.setString(
                        "mergeAlgorithm",
                        value!,
                      );
                    },
                    items: widget.MergeAlgorithmList.asMap().entries.map(
                      (entry) {
                        return DropdownMenuItem<String>(
                          value: entry.value,
                          child: Text(entry.value),
                        );
                      },
                    ).toList(),
                  ),
                ),
                // ListTile(
                //   title: const Text("Result Preloading"),
                //   subtitle: const Text(
                //       "Number of results to be preloaded. More may increase data usage. Need to restart the app to take effect."),
                //   trailing: DropdownButton<int>(
                //     value: _preloadNumber,
                //     icon: const Icon(Icons.arrow_downward),
                //     elevation: 16,
                //     // style: const TextStyle(color: Colors.deepPurple),
                //     underline: Container(
                //       height: 2,
                //       // color: _appBarColor,
                //     ),
                //     onChanged: (int? value) async {
                //       print("_preloadNumber $value");

                //       widget.updatePreloading(value);

                //       setState(() {
                //         _preloadNumber = value;
                //       });

                //       await widget.prefs.setInt(
                //         "preloadNumber",
                //         value!,
                //       );
                //     },
                //     items: [0, 1].asMap().entries.map(
                //       (entry) {
                //         return DropdownMenuItem<int>(
                //           value: entry.value,
                //           child: Text(entry.value.toString()),
                //         );
                //       },
                //     ).toList(),
                //   ),
                // ),

                // ListTile(
                //   title: const Text("Auto Switch Platform"),
                //   subtitle: const Text(
                //       "Switch platform automatically when a new onw is selected."),
                //   trailing: DropdownButton<int>(
                //     value: _autoSwitchPlatform,
                //     icon: const Icon(Icons.arrow_downward),
                //     elevation: 16,
                //     // style: const TextStyle(color: Colors.deepPurple),
                //     underline: Container(
                //       height: 2,
                //       // color: _appBarColor,
                //     ),
                //     onChanged: (int? value) async {
                //       print("autoSwitchPlatform $value");

                //       widget.updateAutoSwitchPlatform(value);

                //       setState(() {
                //         _autoSwitchPlatform = value;
                //       });

                //       await widget.prefs.setInt(
                //         "autoSwitchPlatform",
                //         value!,
                //       );
                //     },
                //     items: [0, 1].asMap().entries.map(
                //       (entry) {
                //         return DropdownMenuItem<int>(
                //           value: entry.value,
                //           child: Text(entry.value.toString()),
                //         );
                //       },
                //     ).toList(),
                //   ),
                // ),
              ],
            ),
            // SettingsList(
            //   sections: [
            //     SettingsSection(
            //       title: const Text('Common'),
            //       tiles: <SettingsTile>[
            //         SettingsTile.navigation(
            //           leading: const Icon(Icons.language),
            //           title: const Text('Language'),
            //           value: const Text('English'),
            //         ),
            //         SettingsTile.switchTile(
            //           onToggle: (value) {
            //             // setState(() {
            //             //   _test = value;
            //             // });
            //           },
            //           initialValue: false,
            //           leading: const Icon(Icons.format_paint),
            //           title: const Text('Enable custom theme'),
            //           activeSwitchColor: _appBarColor,
            //         ),
            //       ],
            //     ),
            //   ],
            // ),
          ),
        ),
      ),
    );
  }
}
