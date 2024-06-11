import 'dart:convert';

import 'package:android_intent_plus/flag.dart';
import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Deep Link LPBS'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _controller1 = TextEditingController();

  @override
  void initState() {
    super.initState();
    initUniLinks();
  }

  void _openAppForm(String token) async {
    final url = 'openLPTrade://open?token=$token';
    if (Theme.of(context).platform == TargetPlatform.android) {
      final AndroidIntent intent = AndroidIntent(
        action: 'action_view',
        data: url,
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
    } else {
      if (await canLaunch(url)) {
        await launch(url);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  getDL(_controller.text);
                },
                child: const Text("Get One Time Token"),
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: "CCCD/CMND",
                ),
                controller: _controller,
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: "One time token",
                ),
                controller: _controller1,
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  _openAppForm(_controller1.text);
                },
                child: const Text("Open App LPBS"),
              )
            ],
          ),
        ),
      ),
    );
  }

  void initUniLinks() {
    getInitialLink().then((String? link) {
      if (link != null) {
        handleDeepLink(link);
      }
    });

    // ignore: deprecated_member_use
    getLinksStream().listen((String? link) {
      if (link != null) {
        handleDeepLink(link);
      }
    }, onError: (err) {});
  }

  void handleDeepLink(String link) {
    print("Deep Link: $link");
  }

  Future<void> getOneTimeToken(String requestData, String requestKey) async {
    final response = await http.post(
      Uri.parse('http://192.168.18.153/sso/internal/authcode/decryptdata'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'RequestKey': requestKey,
        'RequestData': requestData,
      }),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> responseData = jsonDecode(response.body);
      String code = responseData['OneTimeToken'];
      _controller1.text = code;
    } else {
      throw Exception('Failed to load token');
    }
  }

  Future<void> getDL(String number) async {
    final response = await http.post(
      Uri.parse('http://192.168.18.153/sso/internal/auth/create-data'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'data': <String, dynamic>{
          'identityNumber': number,
          'msgId': 'abc123',
        },
      }),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> responseData = jsonDecode(response.body);
      String responseKey = responseData['ResponseKey'];
      String responseDataValue = responseData['ResponseData'];
      getAuthcode(responseKey, responseDataValue);
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> getAuthcode(String requestKey, String requestData) async {
    final response = await http.post(
      Uri.parse('http://192.168.18.153/sso/internal/authcode/create'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'RequestKey': requestKey,
        'RequestData': requestData,
      }),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> responseData = jsonDecode(response.body);
      String responseKey1 = responseData['ResponseKey'];
      String responseDataValue1 = responseData['ResponseData'];

      getOneTimeToken(responseDataValue1, responseKey1);
    } else {
      throw Exception('Failed to load data');
    }
  }
}
