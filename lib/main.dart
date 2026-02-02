import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CV ATS Sjekk',
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool loading = false;
  Map<String, dynamic>? result;

  Future<void> pickAndUploadCV() async {
    final file = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
    );

    if (file == null) return;

    setState(() {
      loading = true;
      result = null;
    });

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://DIN_BACKEND_URL/analyse'),
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.files.single.path!,
      ),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    setState(() {
      loading = false;
      result = json.decode(responseBody);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CV ATS Sjekk')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Last opp CV-en din og få tilbakemelding på ATS-vennlighet.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : pickAndUploadCV,
              child: const Text('Last opp CV (PDF/DOCX)'),
            ),
            const SizedBox(height: 20),
            if (loading) const CircularProgressIndicator(),
            if (result != null) Expanded(child: ResultView(result!)),
          ],
        ),
      ),
    );
  }
}

class ResultView extends StatelessWidget {
  final Map<String, dynamic> data;
  const ResultView(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text('ATS-score: ${data["score"]}/100',
            style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 12),
        section('❌ Problemer', data['problemer']),
        section('⚠️ Forbedringer', data['forbedringer']),
        section('✅ Det som fungerer', data['det_som_funker']),
      ],
    );
  }

  Widget section(String title, List items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ...items.map((e) => Text('- $e')).toList(),
        const SizedBox(height: 10),
      ],
    );
  }
}
