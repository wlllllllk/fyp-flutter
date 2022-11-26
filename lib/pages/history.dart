import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

class HistoriesPage extends StatefulWidget {
  const HistoriesPage({
    Key? key,
    required this.selectedPageIndex,
    // required this.getHistory,
    required this.urlRecords,
    // required this.showAlertDialog,
    // required this.buildHistoryList
    required this.isar,
  }) : super(key: key);

  // final String title;
  final int selectedPageIndex;
  // final getHistory;
  final List urlRecords;
  // final showAlertDialog;
  // final buildHistoryList;

  final Isar isar;

  @override
  State<HistoriesPage> createState() => _HistoriesPageState();
}

class _HistoriesPageState extends State<HistoriesPage> {
  // int _selectedPageIndex = selectedPageIndex;

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
        // setState(() {
        //   _selectedPageIndex = 0;
        // });
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

  _buildHistoryList() {
    Map list = {};
    for (var item in widget.urlRecords) {
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

  // _getHistory() async {
  //   print("getting history");

  //   // check if the record exist
  //   final urlRecord = await widget.isar.uRLs.where().findAll();

  //   return urlRecord;
  // }

  void _deleteHistory() async {
    print("deleting history");

    await widget.isar.writeTxn(() async {
      widget.isar.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        // setState(() {
        //   _selectedPageIndex = 0;
        // });
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
              // setState(() => {
              //       _selectedPageIndex = 0,
              //     }),
              Navigator.of(context).pop()
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => {
                _showAlertDialog(context),
              },
            ),
          ],
        ),
        body: Container(
          child: Align(
              alignment: Alignment.center,
              child: widget.urlRecords.isNotEmpty
                  ? ListView(
                      children: _buildHistoryList(),
                    )
                  : const Text("Nothing here :(")),
        ),
      ),
    );
  }
}
