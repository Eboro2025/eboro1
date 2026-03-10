import 'dart:convert';
import 'dart:io';
import 'package:eboro/API/ContactUs.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class WriteContact extends StatefulWidget {
  @override
  WriteContact2  createState() => WriteContact2();
}

class WriteContact2 extends State <WriteContact> {
  TextEditingController _nameController = new TextEditingController();
  TextEditingController _emailController = new TextEditingController();
  TextEditingController _phoneController = new TextEditingController();
  TextEditingController _topicController = new TextEditingController();
  TextEditingController _messageController = new TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String? _base64Image;
  String? _fileName;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickImage(ImageSource source) async {
    var pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxHeight: 800,
      maxWidth: 800,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _base64Image = base64Encode(_selectedImage!.readAsBytesSync());
        _fileName = pickedFile.path.split(Platform.pathSeparator).last;
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: myColor),
              title: Text(AppLocalizations.of(context)!.translate("camera") ?? "Camera"),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: myColor),
              title: Text(AppLocalizations.of(context)!.translate("gallery") ?? "Gallery"),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: myColor,
        centerTitle: true,
        title: Text(AppLocalizations.of(context)!.translate("contactus"), style: TextStyle( color: Colors.white, fontSize: MyApp2.fontSize20)),
        iconTheme: new IconThemeData(color: Colors.white),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.assignment_outlined,),
            onPressed: () {
              ContactUsAPI().getContacts(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 30, right: 30, top: 0, bottom: 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 20,
            ),
            Container(
              alignment: Alignment.topLeft,
                child: Text(
                    AppLocalizations.of(context)!.translate("contactinformation"),
                    style: TextStyle(fontSize: MyApp2.fontSize20, color: myColor2, )
                ),
            ),

            SizedBox(
              height: 20,
            ),

            Container(
              width: MyApp2.W,
              child: TextField(
                cursorColor: myColor,
                controller: _nameController,
                style: TextStyle(
                  fontSize: MyApp2.fontSize16, color: Colors.grey,),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.translate("name"),
                  labelStyle: TextStyle(fontSize: MyApp2.fontSize16,
                    color: Colors.grey,),
                  contentPadding: new EdgeInsets.symmetric(vertical: MyApp2.W! *.025, horizontal: MyApp2.W! *.025),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey,
                        width: 0.5),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ),

            SizedBox(
              height: 20,
            ),

            Container(
              width: MyApp2.W,
              child: TextField(
                cursorColor: myColor,
                controller: _emailController,
                style: TextStyle(
                  fontSize: MyApp2.fontSize16, color: Colors.grey,),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.translate("email"),
                  labelStyle: TextStyle(fontSize: MyApp2.fontSize16,
                    color: Colors.grey,),
                  contentPadding: new EdgeInsets.symmetric(vertical: MyApp2.W! *.025, horizontal: MyApp2.W! *.025),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey,
                        width: 0.5),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ),

            SizedBox(
              height: 20,
            ),

            Container(
              width: MyApp2.W,
              child: TextField(
                cursorColor: myColor,
                controller: _phoneController,
                style: TextStyle(
                  fontSize: MyApp2.fontSize16, color: Colors.grey,),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.translate("mobilenumber"),
                  labelStyle: TextStyle(fontSize: MyApp2.fontSize16,
                    color: Colors.grey,),
                  contentPadding: new EdgeInsets.symmetric(vertical: MyApp2.W! *.025, horizontal: MyApp2.W! *.025),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey,
                        width: 0.5),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ),

            SizedBox(
              height: 20,
            ),

            Container(
              width: MyApp2.W,
              child: TextField(
                cursorColor: myColor,
                controller: _topicController,
                style: TextStyle(
                  fontSize: MyApp2.fontSize16, color: Colors.grey,),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.translate("subject"),
                  labelStyle: TextStyle(fontSize: MyApp2.fontSize16,
                    color: Colors.grey,),
                  contentPadding: new EdgeInsets.symmetric(vertical: MyApp2.W! *.025, horizontal: MyApp2.W! *.025),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey,
                        width: 0.5),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ),

            SizedBox(
              height: 20,
            ),

            Container(
              width: MyApp2.W,
              child: TextField(
                cursorColor: myColor,
                controller: _messageController,
                style: TextStyle(
                  fontSize: MyApp2.fontSize16, color: Colors.grey,),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.translate("typeyourmessage"),
                  labelStyle: TextStyle(fontSize: MyApp2.fontSize16,
                    color: Colors.grey,),
                  contentPadding: new EdgeInsets.symmetric(vertical: MyApp2.W! *.025, horizontal: MyApp2.W! *.025),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey,
                        width: 0.5),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ),

            SizedBox(
              height: 16,
            ),

            // Image picker section
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                width: MyApp2.W,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 0.5),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  children: [
                    Icon(Icons.camera_alt, color: myColor, size: MyApp2.fontSize20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedImage != null
                            ? _fileName ?? ''
                            : (AppLocalizations.of(context)!.translate("attachphoto") ?? "Allega foto"),
                        style: TextStyle(fontSize: MyApp2.fontSize16, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_selectedImage != null)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImage = null;
                            _base64Image = null;
                            _fileName = null;
                          });
                        },
                        child: Icon(Icons.close, color: Colors.grey, size: MyApp2.fontSize16),
                      ),
                  ],
                ),
              ),
            ),

            // Image preview
            if (_selectedImage != null) ...[
              SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  height: 150,
                  width: 150,
                  fit: BoxFit.cover,
                ),
              ),
            ],

            SizedBox(
              height: 20,
            ),

            Container(
                width: MyApp2.W! *.5,
                child: MaterialButton(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    AppLocalizations.of(context)!.translate("send"),
                    style: TextStyle(
                      fontSize: MyApp2.fontSize20,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  color: myColor,
                  textColor: Colors.white,
                  onPressed: () {
                    ContactUsAPI().writeContact(
                      _emailController.text,
                      _phoneController.text,
                      _nameController.text,
                      _topicController.text,
                      _messageController.text,
                      context,
                      base64Image: _base64Image,
                      fileNames: _fileName,
                    );
                  },
                )
            ),
          ],
        ),
      ),
    );
  }
}
