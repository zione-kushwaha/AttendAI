import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';

class DocumentScannerService {
  final textRecognizer = TextRecognizer();
  final ImagePicker _picker = ImagePicker();

  Future<String> scanDocument() async {
    try {
      // Pick an image from camera or gallery
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1800,
        maxHeight: 1800,
      );

      if (image == null) return '';

      // Convert XFile to InputImage
      final inputImage = InputImage.fromFile(File(image.path));

      // Process the image and extract text
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      String scannedText = recognizedText.text;
      return scannedText;
    } catch (e) {
      print('Error scanning document: $e');
      return '';
    } finally {
      textRecognizer.close();
    }
  }

  Future<List<String>> extractStructuredData(String scannedText) async {
    // Split the text into lines
    List<String> lines = scannedText.split('\n');

    // Remove empty lines and trim whitespace
    lines = lines
        .where((line) => line.trim().isNotEmpty)
        .map((line) => line.trim())
        .toList();

    return lines;
  }
}
