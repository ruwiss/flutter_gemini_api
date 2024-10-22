import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/models/urun.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:google_generative_ai/google_generative_ai.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Urun> _urunler = [];

  // Speech to text
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _listening = false;

  // Google Generative AI
  late final GenerativeModel _generativeModel;

  final GenerationConfig _generationConfig = GenerationConfig(
      responseMimeType: "application/json",
      responseSchema: Schema.array(
          items: Schema.object(properties: {
        "isim": Schema.string(),
        "miktar": Schema.number(),
        "miktarTuru": Schema.enumString(enumValues: ["kilo", "adet", "litre"])
      })));

  late final ChatSession _chatSession;

  @override
  void initState() {
    super.initState();
    _speech
        .initialize()
        .then((value) => setState(() => _speechAvailable = true));

    _generativeModel = GenerativeModel(
      apiKey: const String.fromEnvironment("api_key"),
      model: "gemini-1.5-flash-latest",
      generationConfig: _generationConfig,
    );
    _startGeminiSession();
  }

  void _startListening() {
    setState(() => _listening = true);
    _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _sendMessage(result.recognizedWords);
        }
      },
    );
  }

  void _stopListening() {
    _speech.stop().then((value) => setState(() => _listening = false));
  }

  void _startGeminiSession() {
    _chatSession = _generativeModel.startChat(history: [
      Content("user", [
        TextPart(
            "Vereceğim cümlede geçen alışveriş listesini JSON formatında döndür: {isim, miktar, miktarTuru(kilo, adet veya litre)}")
      ]),
    ]);
  }

  void _sendMessage(String message) {
    final Content content = Content.text(message);
    _generativeModel.countTokens([content]).then(
      (CountTokensResponse value) {
        log("${value.totalTokens} token harcandı");
      },
    );

    _chatSession.sendMessage(content).then(
      (GenerateContentResponse value) {
        if (value.text case final String text) {
          final List urunler = jsonDecode(text);
          _urunler = urunler.map((e) => Urun.fromMap(e)).toList();
          setState(() {});
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _urunlerListe(),
            !_listening
                ? IconButton(
                    onPressed: _speechAvailable ? _startListening : null,
                    icon: const Icon(Icons.keyboard_voice, size: 70),
                  )
                : IconButton(
                    onPressed: _stopListening,
                    icon: const Icon(Icons.stop, size: 70),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _urunlerListe() {
    if (_urunler.isEmpty) {
      return const SizedBox.shrink();
    } else {
      return Flexible(
        child: ListView.builder(
          itemCount: _urunler.length,
          itemBuilder: (context, index) {
            final Urun urun = _urunler[index];
            return Card(
              child: ListTile(
                title: Text(urun.isim),
                subtitle: Text("${urun.miktar} ${urun.miktarTuru}"),
              ),
            );
          },
        ),
      );
    }
  }
}
