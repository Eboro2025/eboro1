import 'package:date_format/date_format.dart';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/API/ContactUs.dart';
import 'package:eboro/Client/Contact%20Us/ContactDetails.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';

class Contact extends StatefulWidget {
  @override
  Contact2 createState() => Contact2();
}

class Contact2 extends State<Contact> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Column(
      children: <Widget>[
        for (int i = 0; i < ContactUsAPI.contact.length; i++)
          (GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ContactDetails(
                            id: ContactUsAPI.contact[i].id,
                            subject: ContactUsAPI.contact[i].subject)));
              },
              child: Container(
                margin: EdgeInsets.all(MyApp2.W! * .025),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(
                    Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      spreadRadius: 3,
                      blurRadius: 3,
                    ),
                  ],
                ),
                padding: EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.translate("subject") +
                              ' : ',
                          style: TextStyle(
                            fontSize: MyApp2.fontSize16,
                            color: myColor2,
                          ),
                        ),
                        Text(
                          ContactUsAPI.contact[i].subject.toString(),
                          style: TextStyle(
                            fontSize: MyApp2.fontSize16,
                            color: myColor2,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.translate("date") +
                              ' : ',
                          style: TextStyle(
                            fontSize: MyApp2.fontSize16,
                            color: myColor2,
                          ),
                        ),
                        Text(
                          () {
                            final createdAt = ContactUsAPI.contact[i].created_at;
                            if (createdAt != null && createdAt.isNotEmpty) {
                              try {
                                return formatDate(
                                    safeDateParse(createdAt),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.translate("state") +
                              ' : ',
                          style: TextStyle(
                            fontSize: MyApp2.fontSize16,
                            color: myColor2,
                          ),
                        ),
                        Container(
                            child: Text(
                          ContactUsAPI.contact[i].state.toString(),
                          style: TextStyle(
                            fontSize: MyApp2.fontSize16,
                            color: (ContactUsAPI.contact[i].state.toString() ==
                                    'closed')
                                ? Colors.red
                                : Colors.green,
                          ),
                        )),
                      ],
                    ),
                  ],
                ),
              )))
      ],
    ));
  }
}
