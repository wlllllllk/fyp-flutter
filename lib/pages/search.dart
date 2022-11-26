import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:isar/isar.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({
    Key? key,
    required this.realSearchText,
    required this.handleSearch,
  }) : super(key: key);

  final String realSearchText;
  final handleSearch;

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
                          } catch (e) {
                            print("error $e");
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
                          } catch (e) {
                            print("error $e");
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
              widget.handleSearch(value, false);
            },
            autocorrect: false,
            maxLines: 1,
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
  }
}
