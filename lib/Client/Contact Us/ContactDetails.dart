import 'package:date_format/date_format.dart';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/API/ContactUs.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';

class ContactDetails extends StatefulWidget {
  @override
  final int? id;
  final String? subject;
  ContactDetails({Key? key, this.id, this.subject}) : super(key: key);
  ContactDetails2 createState() => ContactDetails2();
}

class ContactDetails2 extends State<ContactDetails> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: myColor,
          centerTitle: true,
          title: Text(widget.subject.toString(),
              style: TextStyle(color: Colors.white, fontSize: 22)),
          iconTheme: new IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.translate("name"),
                          style: TextStyle(
                            fontSize: MyApp2.fontSize18,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          ContactUsAPI.contact
                              .where((item) =>
                                  item.id.toString() == widget.id.toString())
                              .first
                              .name
                              .toString(),
                          style: TextStyle(
                            fontSize: MyApp2.fontSize16,
                            color: myColor2,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.translate("email"),
                          style: TextStyle(
                            fontSize: MyApp2.fontSize18,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          ContactUsAPI.contact
                              .where((item) =>
                                  item.id.toString() == widget.id.toString())
                              .first
                              .email
                              .toString(),
                          style: TextStyle(
                            fontSize: MyApp2.fontSize16,
                            color: myColor2,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!
                              .translate("mobilenumber"),
                          style: TextStyle(
                            fontSize: MyApp2.fontSize18,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          ContactUsAPI.contact
                              .where((item) =>
                                  item.id.toString() == widget.id.toString())
                              .first
                              .phone
                              .toString(),
                          style: TextStyle(
                            fontSize: MyApp2.fontSize16,
                            color: myColor2,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.translate("subject"),
                          style: TextStyle(
                            fontSize: MyApp2.fontSize18,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          ContactUsAPI.contact
                              .where((item) =>
                                  item.id.toString() == widget.id.toString())
                              .first
                              .subject
                              .toString(),
                          style: TextStyle(
                            fontSize: MyApp2.fontSize16,
                            color: myColor2,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.translate("date"),
                          style: TextStyle(
                            fontSize: MyApp2.fontSize18,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          () {
                            final contact = ContactUsAPI.contact
                                .where((item) =>
                                    item.id.toString() == widget.id.toString())
                                .firstOrNull;
                            if (contact?.created_at != null &&
                                contact!.created_at!.isNotEmpty) {
                              try {
                                return formatDate(
                                    safeDateParse(contact.created_at!),
                                    [dd, '/', mm, '/', yyyy]).toString();
                              } catch (_) {
                                return 'N/A';
                              }
                            }
                            return 'N/A';
                          }(),
                          style: TextStyle(
                            fontSize: MyApp2.fontSize16,
                            color: myColor2,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.translate("state"),
                          style: TextStyle(
                            fontSize: MyApp2.fontSize18,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          ContactUsAPI.contact
                              .where((item) =>
                                  item.id.toString() == widget.id.toString())
                              .first
                              .state
                              .toString(),
                          style: TextStyle(
                            fontSize: MyApp2.fontSize16,
                            color: myColor2,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.translate("message"),
                          style: TextStyle(
                            fontSize: MyApp2.fontSize18,
                            color: Colors.grey,
                          ),
                        ),
                        Container(
                            child: Text(
                          ContactUsAPI.contact
                              .where((item) =>
                                  item.id.toString() == widget.id.toString())
                              .first
                              .message
                              .toString(),
                          style: TextStyle(
                            fontSize: MyApp2.fontSize16,
                            color: myColor2,
                          ),
                        )),
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Replay : ',
                          style: TextStyle(
                            fontSize: MyApp2.fontSize18,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          ContactUsAPI.contact
                              .where((item) =>
                                  item.id.toString() == widget.id.toString())
                              .first
                              .reply
                              .toString(),
                          style: TextStyle(
                            fontSize: MyApp2.fontSize16,
                            color: myColor2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            )));
  }
}
