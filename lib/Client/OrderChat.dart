import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/RealTime/Provider/UserOrderProvider.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class OrderChat extends StatefulWidget {
  final String? id;
  OrderChat({Key? key, required this.id}) : super(key: key);
  Order_order createState() => Order_order();
}

class Order_order extends State<OrderChat> {
  Timer? ordersTimer;
  late Timer timer;
  String? data;
  TextEditingController _message = new TextEditingController();
  ScrollController? _scrollController;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  bool get _isAr => MyApp2.apiLang.toString() == '2';

  @override
  void initState() {
    _scrollController = ScrollController();
    super.initState();
    timer = Timer.periodic(Duration(seconds: 15), (Timer t) => checkInternetState());
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  checkInternetState() async {
    final order = Provider.of<UserOrderProvider>(context, listen: false);
    await order.updateChat(order.selectedOrder.id, context, false);
  }

  scrollToBottom() async {
    final bottomOffset = _scrollController!.position.maxScrollExtent;
    _scrollController!.animateTo(
      bottomOffset,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = Provider.of<UserOrderProvider>(context);
    return Directionality(
      textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: myColor,
          centerTitle: true,
          title: Text(
            'Chat Supporto',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
          ),
          iconTheme: IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: Column(
          children: <Widget>[
            chatList(order),
            buildInputArea(context),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source, maxWidth: 1200, maxHeight: 1200, imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: Text('Fotocamera'),
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: Text('Galleria'),
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInputArea(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Image preview
        if (_selectedImage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            color: Colors.white,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_selectedImage!, height: 120, width: double.infinity, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 4, right: 4,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedImage = null),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Input bar
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -1))],
          ),
          child: Row(
            children: [
              // Image attach button
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.attach_file, color: Colors.grey[600], size: 22),
                  onPressed: _showImagePicker,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
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
                  controller: _message,
                  textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
                ),
              ),
              SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: myColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.send, color: Colors.white, size: 22),
                  onPressed: () {
                    if (_message.text.trim().isEmpty && _selectedImage == null) return;
                    final order = Provider.of<UserOrderProvider>(context, listen: false);
                    order.addChat(widget.id, _message.text.toString(), context, imageFile: _selectedImage);
                    _message.clear();
                    setState(() => _selectedImage = null);
                    scrollToBottom();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget chatList(order) {
    return Expanded(
      child: order.chat == null || order.chat.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[300]),
                  SizedBox(height: 12),
                  Text(
                    'Nessun messaggio ancora',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Inizia la conversazione con il supporto',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              physics: ClampingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: order.chat.length,
              itemBuilder: (context, i) {
                final isMe = order.chat[i].user != null &&
                    order.chat[i].user.id.toString() == Auth2.user!.id.toString();
                return _buildMessageBubble(order.chat[i], isMe);
              },
            ),
    );
  }

  Widget _buildMessageBubble(chat, bool isMe) {
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
              child: Icon(Icons.support_agent, size: 16, color: Colors.white),
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
                    chat.user?.name?.toString() ?? 'Supporto',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isMe ? Colors.white.withOpacity(0.8) : Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  // Chat image
                  if (chat.image != null && chat.image.toString().isNotEmpty) ...[
                    GestureDetector(
                      onTap: () => _showFullImage(context, chat.image.toString()),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: chat.image.toString(),
                          width: 200,
                          height: 150,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            width: 200, height: 150,
                            color: Colors.grey[200],
                            child: Center(child: CircularProgressIndicator(color: myColor, strokeWidth: 2)),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            width: 200, height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(child: Icon(Icons.broken_image, color: Colors.grey[400])),
                          ),
                        ),
                      ),
                    ),
                    if (chat.Message != null && chat.Message.toString().isNotEmpty)
                      SizedBox(height: 6),
                  ],
                  if (chat.Message != null && chat.Message.toString().isNotEmpty)
                    Text(
                      chat.Message.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: isMe ? Colors.white : const Color(0xFF222222),
                        height: 1.4,
                      ),
                    ),
                  SizedBox(height: 5),
                  Text(
                    chat.created_at?.toString() ?? '',
                    style: TextStyle(
                      fontSize: 11,
                      color: isMe ? Colors.white.withOpacity(0.65) : Colors.grey[500],
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
              child: Icon(Icons.person, size: 16, color: myColor),
            ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (_, __) => Center(child: CircularProgressIndicator(color: myColor)),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54, size: 48),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
