import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    Key? key,
    required this.updateSelectedPageIndex,
    required this.updateSearchAlgorithm,
    required this.searchAlgorithm,
    required this.SearchAlgorithmList,
    required this.updatePreloading,
    required this.preloadNumber,
    required this.updateAutoSwitchPlatform,
    required this.autoSwitchPlatform,
    required this.prefs,
  }) : super(key: key);

  final updateSelectedPageIndex;
  final updateSearchAlgorithm;
  final searchAlgorithm;
  final updatePreloading;
  final int preloadNumber;
  final updateAutoSwitchPlatform;
  final int autoSwitchPlatform;
  final List<String> SearchAlgorithmList;
  final SharedPreferences prefs;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // int _selectedPageIndex = selectedPageIndex;
  var _searchAlgorithm;
  var _preloadNumber;
  var _autoSwitchPlatform;

  @override
  void initState() {
    super.initState();
    _searchAlgorithm = widget.searchAlgorithm;
    _preloadNumber = widget.preloadNumber;
    _autoSwitchPlatform = widget.autoSwitchPlatform;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        // setState(() {
        //   _selectedPageIndex = 0;
        // });
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
              // setState(() => {
              //       _selectedPageIndex = 0,
              //     }),
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
                ListTile(
                  title: const Text("Search Algorithm"),
                  subtitle: const Text("How the drill-down is performed."),
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
                  title: const Text("Result Preloading"),
                  subtitle: const Text(
                      "Number of results to be preloaded. More may increase data usage. Need to restart the app to take effect."),
                  trailing: DropdownButton<int>(
                    value: _preloadNumber,
                    icon: const Icon(Icons.arrow_downward),
                    elevation: 16,
                    // style: const TextStyle(color: Colors.deepPurple),
                    underline: Container(
                      height: 2,
                      // color: _appBarColor,
                    ),
                    onChanged: (int? value) async {
                      print("_preloadNumber $value");

                      widget.updatePreloading(value);

                      setState(() {
                        _preloadNumber = value;
                      });

                      await widget.prefs.setInt(
                        "preloadNumber",
                        value!,
                      );
                    },
                    items: [0, 1].asMap().entries.map(
                      (entry) {
                        return DropdownMenuItem<int>(
                          value: entry.value,
                          child: Text(entry.value.toString()),
                        );
                      },
                    ).toList(),
                  ),
                ),
                ListTile(
                  title: const Text("Auto Switch Platform"),
                  subtitle: const Text(
                      "Switch platform automatically when a new onw is selected."),
                  trailing: DropdownButton<int>(
                    value: _autoSwitchPlatform,
                    icon: const Icon(Icons.arrow_downward),
                    elevation: 16,
                    // style: const TextStyle(color: Colors.deepPurple),
                    underline: Container(
                      height: 2,
                      // color: _appBarColor,
                    ),
                    onChanged: (int? value) async {
                      print("autoSwitchPlatform $value");

                      widget.updateAutoSwitchPlatform(value);

                      setState(() {
                        _autoSwitchPlatform = value;
                      });

                      await widget.prefs.setInt(
                        "autoSwitchPlatform",
                        value!,
                      );
                    },
                    items: [0, 1].asMap().entries.map(
                      (entry) {
                        return DropdownMenuItem<int>(
                          value: entry.value,
                          child: Text(entry.value.toString()),
                        );
                      },
                    ).toList(),
                  ),
                ),
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
