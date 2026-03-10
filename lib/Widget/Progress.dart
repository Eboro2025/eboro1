library modal_progress_hud;
import 'package:flutter/material.dart';

class Progress {


  static progressDialogue(BuildContext context) async{
    showDialog(barrierDismissible: false,
      context:context,
      builder:(BuildContext context){
        return AlertDialog(
          contentPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              SizedBox(width: 16),
              Text("Loading...", style: TextStyle(fontSize: 14)),
            ],
          ),
        );
      },
    );
  }

  static dimesDialog(BuildContext context) async {
    try {
      final navigator = Navigator.of(context, rootNavigator: true);
      if (navigator.canPop()) {
        navigator.pop();
      }
    } catch (_) {}
  }
}

