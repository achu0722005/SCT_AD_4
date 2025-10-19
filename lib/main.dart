import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';

void main() {
  runApp(const Myapp());
}

class Myapp extends StatelessWidget {
  const Myapp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Qrcodehomescreen(),
    );
  }
}

class Qrcodehomescreen extends StatefulWidget {
  const Qrcodehomescreen({super.key});

  @override
  State<Qrcodehomescreen> createState() => _QrcodehomescreenState();
}

class _QrcodehomescreenState extends State<Qrcodehomescreen> {

  final TextEditingController _textController = TextEditingController();
  String? qrData;
  final GlobalKey qrKey = GlobalKey();

  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _scannerController.start();
  }

  void _generateQR() {
    setState(() {
      qrData = _textController.text.trim();
    });
  }

  Future<Uint8List?> _captureQrAsBytes() async {
    try {
      RenderRepaintBoundary boundary =
      qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveQrToGallery() async {
    Uint8List? pngBytes = await _captureQrAsBytes();
    if (pngBytes == null) return;

    await ImageGallerySaver.saveImage(
      pngBytes,
      quality: 100,
      name: "qr_${DateTime.now().millisecondsSinceEpoch}",
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR Code saved to gallery!')),
    );
  }

  Future<void> _shareQr() async {
    Uint8List? pngBytes = await _captureQrAsBytes();
    if (pngBytes == null) return;

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/qr_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(pngBytes);

    await Share.shareXFiles([XFile(file.path)], text: 'Here is my QR Code!');
  }

  void _showResultDialog(String resultValue) {
    _scannerController.stop();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("QR Code Scanned"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Value:'),
                const SizedBox(height: 8),
                Text(
                  resultValue,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                _scannerController.start();
                setState(() { _isScanning = true; });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2e4a78),
        title: const Text(
          "QR Scanner / Generator",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.cancel, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                alignment: Alignment.center,
                width: double.infinity,
                height: 250,
                color: Colors.pink,
                child: MobileScanner(
                  controller: _scannerController,
                  onDetect: (capture) {
                    if (!_isScanning) return;

                    final List<Barcode> barcodes = capture.barcodes;

                    if (barcodes.isNotEmpty) {
                      final String? rawValue = barcodes.first.rawValue;

                      if (rawValue != null && mounted) {
                        setState(() { _isScanning = false; });
                        _showResultDialog(rawValue);
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildButton(Icons.camera, "QR History", Colors.blue),
                        _buildButton(Icons.add_circle_outline, "Add QR",
                            const Color(0xFFf37c32)),
                        _buildButton(Icons.access_time_outlined, "Recent",
                            const Color(0xFFa1a5a7)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _textController,
                      cursorColor: Colors.blue,
                      decoration: InputDecoration(
                        hintText: "Enter text or URL to generate QR",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        prefixIcon:
                        const Icon(Icons.link, color: Colors.black),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 12),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                          const BorderSide(color: Colors.grey, width: 1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                          const BorderSide(color: Colors.blue, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _generateQR,
                      icon: const Icon(Icons.qr_code, color: Colors.white),
                      label: const Text("Generate QR"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 340,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 10,
                          )
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          const Text(
                            "QR Generated",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          qrData != null && qrData!.isNotEmpty
                              ? RepaintBoundary(
                            key: qrKey,
                            child: QrImageView(
                              data: qrData!,
                              version: QrVersions.auto,
                              size: 200.0,
                            ),
                          )
                              : const Text(
                            "No QR yet. Enter text above and tap Generate.",
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: qrData == null || qrData!.isEmpty
                                    ? null
                                    : _saveQrToGallery,
                                icon: const Icon(Icons.download,
                                    color: Colors.white),
                                label: const Text(
                                  "Save Image",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: qrData == null || qrData!.isEmpty
                                    ? null
                                    : _shareQr,
                                icon: const Icon(Icons.share_rounded,
                                    color: Colors.white),
                                label: const Text(
                                  "Share",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(IconData icon, String label, Color color) {
    return InkWell(
      onTap: () {},
      splashColor: Colors.blue,
      child: Container(
        width: 90,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 10,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 30),
      ),
    );
  }
}