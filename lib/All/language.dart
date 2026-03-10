import 'package:eboro/app_localizations.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';

class Language extends StatefulWidget {
  @override
  Language2 createState() => Language2();
}

class Language2 extends State<Language> {
  String? selectedLang;

  static const List<Map<String, String>> languages = [
    {'code': 'it', 'key': 'italy', 'native': 'Italiano', 'flag': '\u{1F1EE}\u{1F1F9}'},
    {'code': 'en', 'key': 'english', 'native': 'English', 'flag': '\u{1F1EC}\u{1F1E7}'},
    {'code': 'ar', 'key': 'arabic', 'native': '\u0627\u0644\u0639\u0631\u0628\u064A\u0629', 'flag': '\u{1F1F8}\u{1F1E6}'},
    {'code': 'fr', 'key': 'french', 'native': 'Fran\u00E7ais', 'flag': '\u{1F1EB}\u{1F1F7}'},
    {'code': 'de', 'key': 'german', 'native': 'Deutsch', 'flag': '\u{1F1E9}\u{1F1EA}'},
    {'code': 'es', 'key': 'spanish', 'native': 'Espa\u00F1ol', 'flag': '\u{1F1EA}\u{1F1F8}'},
    {'code': 'pt', 'key': 'portuguese', 'native': 'Portugu\u00EAs', 'flag': '\u{1F1F5}\u{1F1F9}'},
    {'code': 'tr', 'key': 'turkish', 'native': 'T\u00FCrk\u00E7e', 'flag': '\u{1F1F9}\u{1F1F7}'},
    {'code': 'ro', 'key': 'romanian', 'native': 'Rom\u00E2n\u0103', 'flag': '\u{1F1F7}\u{1F1F4}'},
    {'code': 'sq', 'key': 'albanian', 'native': 'Shqip', 'flag': '\u{1F1E6}\u{1F1F1}'},
    {'code': 'zh', 'key': 'chinese', 'native': '\u4E2D\u6587', 'flag': '\u{1F1E8}\u{1F1F3}'},
    {'code': 'hi', 'key': 'hindi', 'native': '\u0939\u093F\u0928\u094D\u0926\u0940', 'flag': '\u{1F1EE}\u{1F1F3}'},
    {'code': 'ru', 'key': 'russian', 'native': '\u0420\u0443\u0441\u0441\u043A\u0438\u0439', 'flag': '\u{1F1F7}\u{1F1FA}'},
  ];

  @override
  void initState() {
    selectedLang = MyApp2.apiLang ?? 'it';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: myColor,
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.translate("language") ?? "Language",
          style: TextStyle(color: Colors.white, fontSize: MyApp2.fontSize20),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: languages.length,
        itemBuilder: (context, index) {
          final lang = languages[index];
          final code = lang['code']!;
          final nativeName = lang['native']!;
          final flag = lang['flag']!;
          final translatedName =
              AppLocalizations.of(context)!.translate(lang['key']!) ?? nativeName;
          final isSelected = selectedLang == code;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              elevation: isSelected ? 4 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: isSelected
                    ? BorderSide(color: myColor, width: 2)
                    : BorderSide.none,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _changeLanguage(code),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? myColor.withValues(alpha: 0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          flag,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nativeName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: isSelected ? myColor : Colors.black87,
                              ),
                            ),
                            if (translatedName != nativeName)
                              Text(
                                translatedName,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Radio<String>(
                        value: code,
                        groupValue: selectedLang,
                        activeColor: myColor,
                        onChanged: (_) => _changeLanguage(code),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _changeLanguage(String code) {
    MyApp2.prefs.setString('apiLang', code);
    MyApp2.apiLang = code;
    MyApp.setLocale(context, code);
    setState(() {
      selectedLang = code;
    });
  }
}
