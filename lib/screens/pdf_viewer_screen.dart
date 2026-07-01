import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends StatefulWidget {
  final String fileName;
  final File localFile;

  const PdfViewerScreen({
    super.key,
    required this.fileName,
    required this.localFile,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  // Syncfusion controller initialization
  late PdfViewerController _pdfViewerController;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey<SfPdfViewerState>();

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
  }

  @override
  void dispose() {
    // Step 4.3: Memory disposal routines to safely unload hefty documents
    _pdfViewerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () => _pdfViewerController.zoomLevel += 0.25,
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () => _pdfViewerController.zoomLevel -= 0.25,
          ),
        ],
      ),
      body: SfPdfViewer.file(
        widget.localFile,
        key: _pdfViewerKey,
        controller: _pdfViewerController,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        enableDoubleTapZooming: true,
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load document stream: ${details.description}'),
              backgroundColor: Colors.red,
            ),
          );
        },
      ),
    );
  }
}