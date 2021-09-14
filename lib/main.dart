import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'package:google_ml_kit/google_ml_kit.dart';


late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  cameras = await availableCameras();

  runApp(CameraApp());
}

class CameraApp extends StatefulWidget {
  const CameraApp({Key? key}) : super(key: key);

  @override
  _CameraAppState createState() => _CameraAppState();
}


class _CameraAppState extends State<CameraApp> {


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TakePicture(camera: cameras.first),
      theme:ThemeData.dark()
    );
  }
}

class TakePicture extends StatefulWidget {
  TakePicture({Key? key, required this.camera}) : super(key: key);

  final camera;

  @override
  _TakePictureState createState() => _TakePictureState();
}

class _TakePictureState extends State<TakePicture> {
  late CameraController controller;
  late Future<void> initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    controller = CameraController(cameras[0], ResolutionPreset.max);
    initializeControllerFuture = controller.initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Take A Picture'),
      ),
      body:FutureBuilder<void>(
        future: initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Center(
              child: (CameraPreview(controller)),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator()
            );
          }
        }
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.camera_alt),
        onPressed: () async {
          try {
            await initializeControllerFuture;
            final image = await controller.takePicture();
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return DisplayPicture(
                    imagePath: image.path,
                  );
                }
              )
            );
          } catch (e) {
            print(e);
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class DisplayPicture extends StatefulWidget {
  const DisplayPicture({Key? key, required this.imagePath}) : super(key: key);

  final String imagePath;

  @override
  _DisplayPictureState createState() => _DisplayPictureState();
}

class _DisplayPictureState extends State<DisplayPicture> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Display the picture')
      ),
      body: Center(
        child: Image.file(File(widget.imagePath)),
      ),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.upload),
          onPressed: () {
            Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) {
                      return RecognizeText(file: File(widget.imagePath));
                    }
                )
            );
          }
      ),

    );
  }
}

class RecognizeText extends StatefulWidget {
  const RecognizeText({Key? key, required this.file}) : super(key: key);

  final File file;

  @override
  _RecognizeTextState createState() => _RecognizeTextState();
}

class _RecognizeTextState extends State<RecognizeText> {
  late List<String> foundLines;

  int getItemIndex(medItems, item) {
    int index = -1;
    for(var medItem in medItems) {
      if (item.contains(medItem)) {
        return medItems.indexOf(medItem);
      }
    }
    return index;
  }

  Future<List<String>> processImage() async {
    try {
      final InputImage inputImage = InputImage.fromFile(widget.file);
      final TextDetector textDetector =  GoogleMlKit.vision.textDetector();

      try {
        final RecognisedText recognisedText = await textDetector.processImage(
            inputImage);
        List<String> textLinesList = [];
        for (TextBlock block in recognisedText.blocks) {
          for (TextLine line in block.lines) {
            textLinesList.add(line.text);
            print(line.text);
          }
        }
        var medItems = ["WBCs", "Neutophils", "Lymphocyles", "Monocytes", "Eosinophils", "Basophils", "RBCs", "Hb", "Hematocrit", "Platelets"];

        List<String> newResultList = [];

        for(var item in textLinesList) {
          if (getItemIndex(medItems, item) >= 0) {
            print("Found an important item: " + item);
            try {
              var pos = textLinesList.indexOf(item);
              var result = double.parse(textLinesList[pos + 1]);
              var reference = textLinesList[pos + 2];
              var ranges = reference.split("to");
              var min = double.parse(ranges[0]);
              var max = double.parse(ranges[1]);
              var decision = "Abnormal";
              if (result >= min && result <= max) {
                decision = "Normal";
              }else if (result < min) {
                decision = "Abnormally Low";
              }else if (result > max) {
                decision = "Abnormally High";
              }
              var newResultStr = item + ": " + decision;
              print(newResultStr);
              newResultList.add(newResultStr);
            } catch (e) {
              print("Failed to parse the item");
            }
          }
        }

        print(newResultList);
        return newResultList;
      } catch (e) {
        rethrow;
      } finally {
        textDetector.close();
      }
    } catch (e) {
      print (e);
      return ["Error"];
    }


  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processed Image Text'),
      ),
      body: FutureBuilder(
        future: processImage(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            foundLines = snapshot.data as List<String>;
            return ListView.builder(
              itemBuilder: (context, index) {
                return ListTile (
                  title: Text(foundLines[index]),
                  subtitle: Text(foundLines[index]),
                );
              },
              itemCount: foundLines.length,
            );
          } else {
            return const CircularProgressIndicator();
          }
        }
      )
    );
  }
}

class RegexScreen extends StatefulWidget {
  const RegexScreen({Key? key}) : super(key: key);

  @override
  _RegexScreenState createState() => _RegexScreenState();
}

class _RegexScreenState extends State<RegexScreen> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
