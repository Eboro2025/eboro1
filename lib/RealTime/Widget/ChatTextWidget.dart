import 'dart:async';

import 'package:eboro/API/Auth.dart';
import 'package:eboro/Delivery/ClickOrderDelivery.dart';
import 'package:eboro/Helper/ChatData.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eboro/RealTime/Provider/ChatProvider.dart';

class ChatTextWidget extends StatefulWidget
{
  @override
  ChatOrder2 createState() => new ChatOrder2();

  final String? id;
  ChatTextWidget({Key? key,required this.id,}) : super(key: key);
}

class ChatOrder2 extends State<ChatTextWidget>
{

  Timer? timer;
  TextEditingController _message = new TextEditingController();
  ScrollController? _scrollController;

  bool get _isAr => MyApp2.apiLang.toString() == '2';

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(Duration(seconds: 20), (Timer t) => checkInternetState());
    _scrollController = ScrollController();
    Timer(Duration(seconds: 3), () {scrollToBottom();});
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  checkInternetState() async {
    final chat = Provider.of<ChatProvider>(context , listen: false);
    await chat.updateOrderChat(widget.id);
  }

  scrollToBottom() async{
    final bottomOffset = _scrollController!.position.maxScrollExtent;
    _scrollController!.animateTo(
      bottomOffset,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: myColor,
          iconTheme: IconThemeData(color: Colors.white),
          centerTitle: true,
          title: Text(
            'Chat Cliente',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DeliveryClickOrder())),
          ),
          elevation: 0,
        ),
        body: Column(
          children: <Widget>[
            chatList(),
            buildInputArea(context),
          ],
        ),
      ),
    );
  }


  Widget buildInputArea(BuildContext context) {
    final chat = Provider.of<ChatProvider>(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -1))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _message,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[100],
                hintText: "Scrivi un messaggio...",
                hintStyle: TextStyle(fontSize: 15, color: Colors.grey[500]),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: myColor, width: 1),
                  borderRadius: BorderRadius.circular(24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
            ),
          ),
          SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: myColor, shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white, size: 22),
              onPressed: () {
                if (_message.text.trim().isEmpty) return;
                chat.addOrderChat(_message.text, widget.id);
                _message.clear();
                scrollToBottom();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget chatList(){
    final chat = Provider.of<ChatProvider>(context);
    return Expanded(
      child: chat.Allchat == null || chat.Allchat!.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[300]),
                  SizedBox(height: 12),
                  Text(
                    'Nessun messaggio ancora',
                    style: TextStyle(color: Colors.grey[500], fontSize: 15),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Inizia la conversazione con il cliente',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              physics: ClampingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: chat.Allchat!.length,
              itemBuilder: (context, i) {
                final OChat = chat.Allchat![i];
                final isMe = Auth2.user!.id.toString() == OChat.user!.id.toString();
                return _buildMessageBubble(OChat, isMe);
              },
            ),
    );
  }

  Widget _buildMessageBubble(ChatData chat, bool isMe) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
          if (!isMe) SizedBox(width: 6),
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? myColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.user?.name?.toString() ?? 'Cliente',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isMe ? Colors.white.withOpacity(0.7) : Colors.grey[500],
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    chat.Message?.toString() ?? '',
                    style: TextStyle(
                      fontSize: 15,
                      color: isMe ? Colors.white : Color(0xFF333333),
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    chat.created_at?.toString() ?? '',
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white.withOpacity(0.6) : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) SizedBox(width: 6),
          if (isMe)
            CircleAvatar(
              radius: 14,
              backgroundColor: myColor.withOpacity(0.2),
              child: Icon(Icons.delivery_dining, size: 16, color: myColor),
            ),
        ],
      ),
    );
  }
}
