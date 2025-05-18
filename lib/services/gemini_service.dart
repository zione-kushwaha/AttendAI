import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String apiKey =
      'YOUR_API_KEY_HERE'; // Replace with your actual API key
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
    );
  }

  Future<List<Map<String, String>>> analyzeStudentData(String text) async {
    try {
      const prompt = '''
        Analyze the following text and extract student information in a structured format.
        For each student entry, identify:
        - Name
        - Roll Number (if available)
        - Class/Grade (if available)
        
        Text to analyze:
      ''';

      final content = [
        Content.text('$prompt\n$text'),
      ];

      final response = await _model.generateContent(content);
      final responseText = response.text;

      // Parse the response into structured data
      List<Map<String, String>> students = [];

      // Split response by student entries and process each
      final entries = responseText?.split('\n\n');
      for (var entry in entries!) {
        if (entry.trim().isEmpty) continue;

        final studentData = <String, String>{};
        final lines = entry.split('\n');

        for (var line in lines) {
          if (line.contains(':')) {
            final parts = line.split(':');
            if (parts.length == 2) {
              final key = parts[0].trim().toLowerCase();
              final value = parts[1].trim();
              studentData[key] = value;
            }
          }
        }

        if (studentData.isNotEmpty) {
          students.add(studentData);
        }
      }

      return students;
    } catch (e) {
      print('Error analyzing text with Gemini: $e');
      return [];
    }
  }
}
