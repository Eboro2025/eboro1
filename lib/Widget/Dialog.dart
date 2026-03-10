library modal_progress_hud;
import 'package:eboro/API/Order.dart';
import 'package:eboro/API/Rates.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';

import '../Helper/OrderData.dart';
import '../app_localizations.dart';

class RateDialog {

  static String?value;


  static showAlertDialog(BuildContext context, OrderData Order) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StarRatingWidget(Order:Order);
      },
    );
  }
}

class StarRatingWidget extends StatefulWidget {

  OrderData Order;
  StarRatingWidget({Key? key, required this.Order}) : super(key: key);

  @override
  _StarRatingWidgetState createState() => _StarRatingWidgetState();
}

class _StarRatingWidgetState extends State<StarRatingWidget> {
  int currentRating = 0;
  TextEditingController _commentController = TextEditingController();
  final List<String> emojis = ['😕', '😐', '😊', '😃', '🤩']; // Different emojis for ratings
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${AppLocalizations.of(context)!.translate("order_rate")}",
            style: TextStyle(
              color: myColor,
              fontSize: 20,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              5,
                  (index) => IconButton(
                onPressed: () {
                  setState(() {
                    currentRating = index + 1;
                  });
                },
                icon: Icon(
                  Icons.star,
                  color: (index + 1) <= currentRating ? Color(0xFFFFD700) : Colors.grey, // Set color based on rating
                ),
                iconSize: 30,
              ),
            ),
          ),
          SizedBox(height: 20),
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              labelText: 'Comment (Optional)',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Rates2.rateProvider(currentRating, _commentController.text , widget.Order.branch?.provider_id, context);
                  Order2().Rate(widget.Order.id,currentRating, _commentController.text);
                },
                child: Text('Rate'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}