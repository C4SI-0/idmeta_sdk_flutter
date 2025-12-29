import 'package:flutter/material.dart';
import 'package:idmeta_sdk_flutter/idmeta_sdk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SDK Test App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('IDMeta SDK Test'),
      ),
      body: Center(
        child: IdmetaVerificationButton(
          // userToken: '191|CMlsJeQ3tAUqumgrh8dZnoyuVhy7yzDBXEfLxAdg8167ea12',
          userToken: '192|Rdv37xRch6jHejg3Gg17dedMFfxbcFzo7Mw4kyET5aebd027',
          // templateId: '421',
          templateId: '1121',

          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text('Start My Verification'),
          ),
        ),
      ),
    );
  }
}
