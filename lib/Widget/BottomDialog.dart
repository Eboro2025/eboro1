import 'package:eboro/API/Auth.dart';
import 'package:eboro/API/Order.dart';

import 'package:eboro/Delivery/ClickOrderDelivery.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';


class BottomDialog {

  Future<String?> showAlertDialog(BuildContext context, String status, String order) async {
     String?title, message;
     if(status == 'cancelled') {
       title = 'Cancel Order';
       message = 'Are you sure you want to cancel this order?';
     }
     if(status == 'complete') {
       title = 'complete';
       message = 'Are you sure you want to complete this order?';
     }
     if(status == 'refund') {
       title = 'Cancel Order';
       message = 'Are you sure you want to cancel this order?';
     }
     if(status == 'in progress') {
       title = 'Accept Order';
       message = 'Are you sure you want to accept this order?';
     }
     if(status == 'to delivering') {
       title = 'To Delivery';
       message = 'Are you sure you want to put this order to delivery?';
     }
     if(status == 'on way') {
       title = 'On Way';
       message = 'Are you sure you want to take this order?';
     }
     if(status == 'on delivering') {
       title = 'On Delivery';
       message = 'Are you sure you want to put this order on delivery?';
     }
     if(status == 'delivered') {
       title = 'Delivered';
       message = 'Are you sure you delivered this order?';
     }
     if(status == 'User Not Found') {
       title = 'User Not Found';
       message = 'Are you sure that user not found?';
     }
     showGeneralDialog(
      barrierLabel: "Label",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: Duration(milliseconds: 500),
      context: context,
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height*.25,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.25),
                  spreadRadius: 2.5,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    title!,
                    style: TextStyle(
                        fontSize: 20,

                        decoration: TextDecoration.none,
                        color: myColor
                    ),
                  ),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16,
                        decoration: TextDecoration.none,
                        fontWeight: FontWeight.w100,
                        color: myColor2
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                          padding: EdgeInsets.only(right: 10, left: 10),
                          width: MediaQuery.of(context).size.width*.5,
                          height: MediaQuery.of(context).size.width*.125,
                          child:MaterialButton(
                            child: Text(
                              'No',
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                                side: BorderSide(width: 2, color: myColor)
                            ),
                            textColor: myColor,
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          )),
                      Container(
                          padding: EdgeInsets.only(right: 10, left: 10),
                          width: MediaQuery.of(context).size.width*.5,
                          height: MediaQuery.of(context).size.width*.125,
                          child:MaterialButton(
                            child: Text(
                              'Yes',
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            color: myColor,
                            textColor: Colors.white,
                            onPressed: () async {
                              if(status == 'cancelled' || status == 'User Not Found')
                                {
                                  cancelDialog(context, status, order);
                                }
                             else
                                {
                                  // Order2().editOrder(status, order, null);
                                  // حساب deliveryTime للكاشير عند قبول أو إرسال الأوردر
                                  int? deliveryTime;
                                  if (status == 'in progress' || status == 'to delivering') {
                                    deliveryTime = 30; // default 30 دقيقة
                                  }

                                  if (MyApp2.type == '4')//delivery
                                  {
                                    await Order2().editOrder(status, order, null, deliveryTime: deliveryTime);
                                    await DeliveryClickOrder2(int.parse(order)).checkInternetState(context);
                                    Navigator.pop(context);
                                    if(Order2.B != null)
                                      Auth2.show(Order2.B!['message'].toString());
                                  }
                                  else if (MyApp2.type == '3') // cashier
                                  {
                                    await Order2().editOrder(status, order, null, deliveryTime: deliveryTime);

                                    Navigator.pop(context);
                                    if(Order2.B != null)
                                      Auth2.show(Order2.B!['message'].toString());
                                  }
                                  else
                                  {
                                    await Order2().editOrder(status, order, null);
                                    //await ClickOrder(int.parse(order)).checkInternetState(context);
                                    Navigator.pop(context);
                                    if(Order2.B != null)
                                      Auth2.show(Order2.B!['message'].toString());
                                  }
                                }
                            },
                          )),
                    ],
                  )
                ],
              ),),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(begin: Offset(0, 1), end: Offset(0, 0)).animate(anim1),
          child: child,
        );
      },
    );
     return title;
  }

   cancelDialog(BuildContext context, String status, String order) {
     TextEditingController _reasonController = new TextEditingController();
     Widget okButton =
     Container(
         height: MediaQuery.of(context).size.height*.15,
         width: MediaQuery.of(context).size.width,
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
             children: [
               if(status == 'cancelled' || status == 'User Not Found')
               Container(
                 child: TextField(
                   controller: _reasonController,
                   style: TextStyle(fontSize: 18, color: Colors.grey, ),
                   decoration: InputDecoration(
                     filled: true,
                     fillColor: Colors.white,
                     hintText: 'Type Reason...',
                     hintStyle:TextStyle(fontSize: 16, color: Color(0xFFCFCFCF), ),
                     contentPadding: const EdgeInsets.only(left: 30, right: 30, top: 10, bottom: 10),
                     focusedBorder: OutlineInputBorder(
                       borderSide: BorderSide(color: Color(0xFFCFCFCF), width: 0.5),
                       borderRadius: BorderRadius.circular(50),
                     ),
                     enabledBorder: OutlineInputBorder(
                       borderSide: BorderSide(color: Color(0xFFCFCFCF), width: 0.5),
                       borderRadius: BorderRadius.circular(50),
                     ),
                   ),
                 ),
                 padding: EdgeInsets.all(10),
               ),
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 crossAxisAlignment: CrossAxisAlignment.center,
                 children: [
                   Container(
                       padding: EdgeInsets.only(right: 10, left: 10),
                       width: MediaQuery.of(context).size.width*.33,
                       height: MediaQuery.of(context).size.width*.125,
                       child:MaterialButton(
                         child: Text(
                           'No',
                           style: TextStyle(
                             fontSize: 20,

                           ),
                         ),
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(50),
                             side: BorderSide(width: 2, color: myColor)
                         ),
                         textColor: myColor,
                         onPressed: () {
                           Navigator.pop(context, true);
                           Navigator.pop(context, true);
                         },
                       )),
                   Container(
                       padding: EdgeInsets.only(right: 10, left: 10),
                       width: MediaQuery.of(context).size.width*.33,
                       height: MediaQuery.of(context).size.width*.125,
                       child:MaterialButton(
                           child: Text(
                             'Yes',
                             style: TextStyle(
                               fontSize: 20,

                             ),
                           ),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(50),
                           ),
                           color: myColor,
                           textColor: Colors.white,
                           onPressed: () {
                             Order2().editOrder(status, order, _reasonController.text);
                           }))
                 ],
               )
             ]
         )
     );
     AlertDialog alert = AlertDialog(
       title: Text('Are you sure to cancel this order?',
         style: TextStyle(fontSize: 18, color: myColor, ),
       ),
       content: okButton,
       shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular(15)),
     );
     showDialog(
       context: context,
       builder: (BuildContext context) {
         return alert;
       },
     );
   }

}

