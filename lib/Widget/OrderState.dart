
import 'package:eboro/Helper/LightBranchData.dart';
import 'package:eboro/RealTime/Provider/CashierOrderProvider.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OrderState extends StatefulWidget {
  @override
  OrderState2 createState() => OrderState2();
}

class OrderState2 extends State<OrderState> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final cashierOrder =Provider.of<CashierOrderProvider>(context, listen: false);
    LightBranchData OOrderBranch = cashierOrder.OOrder!.branch!;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(

              children: [
                Container(
                  padding: EdgeInsets.all(7.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.deepOrange),
                    borderRadius: BorderRadius.all(Radius.circular(500.0)),
                  ),
                  child: Image.asset(
                    'images/icons/clipboard.png',
                    height: 25,
                    width: 25,
                    color: Colors.deepOrange,
                  ),
                ),
                Text('${cashierOrder.OOrder!.status.toString()}',
                    style: TextStyle(
                      fontSize: MyApp2.fontSize16,
                      color: Colors.deepOrange,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }


}
