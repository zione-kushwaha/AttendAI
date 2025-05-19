import 'dart:convert';
import 'dart:io';
import 'package:flutter_gemini/flutter_gemini.dart';

class DocumentScannerService {
  // Gemini AI instance
  static final Gemini _gemini = Gemini.instance;
  static bool _isGeminiInitialized = false;

  // API key for Gemini
  static const String _apiKey = 'AIzaSyBQOAvo32t1etTBbqXiQqZ3tjSUfX64v-8';

  // Improved prompt template
  static const String _promptTemplate = '''
  Analyze this document image carefully and extract ONLY student names and roll numbers. 
  The document contains student records in a structured format, typically with:
  - Student Name
  - Roll Number
  
  IMPORTANT INSTRUCTIONS:
  1. Extract ONLY name and roll number pairs
  2. Ignore all other information like headers, footers, page numbers, etc.
  3. If a name or roll number is incomplete or unclear, skip that entry
  4. For roll numbers, extract ONLY the numeric portion at the end (e.g., for "PUR078BCT037", extract "037")
  5. Return the data in STRICT JSON format as shown below
  
  REQUIRED OUTPUT FORMAT:
  [
    {"name": "Full Student Name", "rollNumber": "037"},
    {"name": "Another Student Name", "rollNumber": "124"}
  ]
  
  DO NOT include any additional text or explanations in your response.
  ''';

  // Initialize Gemini
  static Future<void> _initGemini() async {
    if (!_isGeminiInitialized) {
      Gemini.init(apiKey: _apiKey);
      _isGeminiInitialized = true;
    }
  }

  // Method to analyze document image
  static Future<List<Map<String, String>>> analyzeImageWithGemini(
    File imageFile,
  ) async {
    await _initGemini();
    print('Starting image analysis...');

    try {
      // Read image bytes
      final imageBytes = await imageFile.readAsBytes();

      // Make the API call
      final response = await _gemini.textAndImage(
        text: _promptTemplate,
        images: [imageBytes],
      );

      if (response == null || response.content == null) {
        throw Exception('Empty response from Gemini API');
      }

      final responseText =
          response.content!.parts?.firstOrNull?.text?.trim() ?? '';
      print('Raw response from Gemini: $responseText');

      if (responseText.isEmpty) {
        throw Exception('No content in Gemini response');
      }

      // Try to find JSON in the response
      final jsonStart = responseText.indexOf('[');
      final jsonEnd = responseText.lastIndexOf(']') + 1;

      if (jsonStart == -1 || jsonEnd == -1) {
        throw Exception('No valid JSON found in response: $responseText');
      }

      final jsonStr = responseText.substring(jsonStart, jsonEnd);
      print('Extracted JSON: $jsonStr');

      // Parse the JSON
      final List<dynamic> parsed;
      try {
        parsed = json.decode(jsonStr) as List;
      } catch (e) {
        throw Exception('Failed to parse JSON: $e');
      }

      // Validate and convert the data
      return parsed.map((item) {
        if (item is! Map<String, dynamic>) {
          throw Exception('Invalid item format in response');
        }
        return {
          'name': item['name']?.toString() ?? '',
          'rollNumber': item['rollNumber']?.toString() ?? '',
        };
      }).toList();
    } catch (e) {
      print('Error in analyzeImageWithGemini: ${e.toString()}');

      // Enhanced error handling
      if (e.toString().contains('network') ||
          e.toString().contains('socket') ||
          e.toString().contains('timed out')) {
        throw Exception(
          'Network error. Please check your internet connection.',
        );
      } else if (e.toString().contains('401') ||
          e.toString().contains('403') ||
          e.toString().contains('API key')) {
        throw Exception('Authentication failed. Check your API key.');
      } else if (e.toString().contains('JSON') ||
          e.toString().contains('format')) {
        throw Exception(
          'Failed to process the response. The document might be unclear.',
        );
      } else {
        throw Exception('Failed to analyze document: ${e.toString()}');
      }
    }
  }
}
