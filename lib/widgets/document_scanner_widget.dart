import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/document_scanner_service.dart';
import '../services/gemini_service.dart';

final documentScannerProvider = Provider((ref) => DocumentScannerService());
final geminiServiceProvider = Provider((ref) => GeminiService());

class DocumentScannerWidget extends ConsumerWidget {
  const DocumentScannerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () async {
            final scanner = ref.read(documentScannerProvider);
            String scannedText = await scanner.scanDocument();
            if (scannedText.isNotEmpty) {
              // First show the raw scanned text
              List<String> structuredData =
                  await scanner.extractStructuredData(scannedText);

              if (context.mounted) {
                // Show loading dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                // Analyze with Gemini
                final gemini = ref.read(geminiServiceProvider);
                final analyzedData =
                    await gemini.analyzeStudentData(scannedText);

                // Remove loading dialog
                if (context.mounted) {
                  Navigator.of(context).pop();

                  // Show results dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Scanned and Analyzed Data'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Raw Scanned Text:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ...structuredData.map((line) => Text(line)),
                            const SizedBox(height: 16),
                            const Text('Analyzed Student Data:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ...analyzedData.map((student) => Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: student.entries
                                          .map((e) =>
                                              Text('${e.key}: ${e.value}'))
                                          .toList(),
                                    ),
                                  ),
                                )),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // TODO: Implement bulk import of analyzed students
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Students imported successfully'),
                              ),
                            );
                          },
                          child: const Text('Import Students'),
                        ),
                      ],
                    ),
                  );
                }
              }
            }
          },
          icon: const Icon(Icons.document_scanner),
          label: const Text('Scan Document'),
        ),
      ],
    );
  }
}
