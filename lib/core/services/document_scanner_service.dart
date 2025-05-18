import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class DocumentScannerService {
  static final _textRecognizer = TextRecognizer();
  static const String _promptTemplate = '''
  Extract student information from the following text. The text contains student records with the following information:
  - Name
  - Roll Number
  Each line represents a single student. Return the data in the following format:
  [
    {"name": "Student Name", "rollNumber": "123"},
    {"name": "Another Student", "rollNumber": "124"}
  ]
  
  Text to process:
  ''';

  static Future<String> recognizeText(String imagePath) async {
    final inputImage = InputImage.fromFile(File(imagePath));
    final recognizedText = await _textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  static Future<List<Map<String, String>>> analyzeWithGemini(
      String text) async {
    // Replace with your actual API key
    const apiKey = 'AIzaSyAEL4-EdUdkEwq3yU1qZI-yL9IVa522pWg';
    final model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
    );

    try {
      final prompt = '$_promptTemplate\\n$text';
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text == null) {
        throw Exception('No response from Gemini AI');
      }

      // Parse the JSON response
      final responseText = response.text!;
      final jsonStart = responseText.indexOf('[');
      final jsonEnd = responseText.lastIndexOf(']') + 1;

      if (jsonStart == -1 || jsonEnd == -1) {
        throw Exception('Invalid response format from Gemini AI');
      }

      final jsonStr = responseText.substring(jsonStart, jsonEnd);
      final List<dynamic> parsed = json.decode(jsonStr);

      return parsed
          .map<Map<String, String>>((item) => {
                'name': item['name'] as String,
                'rollNumber': item['rollNumber'] as String,
              })
          .toList();
    } catch (e) {
      print('Error analyzing text with Gemini: $e');
      rethrow;
    }
  }
}
