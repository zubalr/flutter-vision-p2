
import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vision_app2/app.dart';
import 'package:vision_app2/services/camera_service.dart';
import 'package:vision_app2/services/ml_service.dart';
import 'package:vision_app2/widgets/bounding_box.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameraService = CameraService();
  await cameraService.initialize();

  final mlService = MLService();
  await mlService.loadModel();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: cameraService),
        Provider.value(value: mlService),
      ],
      child: const App(),
    ),
  );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<dynamic>? _recognitions;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final cameraService = Provider.of<CameraService>(context, listen: false);
    cameraService.cameraController!.startImageStream((image) {
      if (_timer != null && _timer!.isActive) return;
      _timer = Timer(const Duration(milliseconds: 500), () {
        final mlService = Provider.of<MLService>(context, listen: false);
        mlService.predict(image).then((recognitions) {
          setState(() {
            _recognitions = recognitions;
          });
        });
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cameraService = Provider.of<CameraService>(context);
    if (!cameraService.cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Object Detection'),
      ),
      body: Stack(
        children: [
          CameraPreview(cameraService.cameraController!),
          if (_recognitions != null)
            ..._recognitions!.map((rec) {
              final rect = Rect.fromLTWH(
                rec['box'][0],
                rec['box'][1],
                rec['box'][2] - rec['box'][0],
                rec['box'][3] - rec['box'][1],
              );
              return BoundingBox(
                rect: rect,
                color: Colors.blue,
                label: rec['tag'],
              );
            }),
        ],
      ),
    );
  }
}
