import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

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
      title: "BloodTester",
      home: TakePicture(camera: cameras.first),
      theme:ThemeData.dark(),
      debugShowCheckedModeBanner: false,
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
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.landscapeRight]);
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
  //'WBCs': ["Possible causes: "
  //         "An increased production of white blood cells to fight an infection. "
  //         "A reaction to a drug that increases white blood cell production. "
  //         "A disease of bone marrow, causing abnormally high production of white blood cells. "
  //         "An immune system disorder that increases white blood cell production.",
  //         "Possible causes: "
  //         "Viral infections that temporarily disrupt the work of bone marrow. "
  //         "Certain disorders present at birth (congenital) that involve diminished bone marrow function. "
  //         "Autoimmune disorders that destroy white blood cells or bone marrow cells. "
  //         "Severe infections that use up white blood cells faster than they can be produced. "
  //         "Medications, such as antibiotics, that destroy white blood cells."],

  String textresults = '';

  var medItems = {
    "White Blood Count": ['WBC', 'WBCs', 'White Blood Cells', 'White Blood Count', 'White Cell Count', 'White Blood Cell Count'],
    "Neutrophils": ['Neutrophils'],
    "Lymphocytes": ['Lymphocytes', 'Lymphs'],
    "Monocytes": ['Monocytes'],
    "Eosinophils": ['Eosinophils', 'Eos'],
    "Basophils": ['Basophils', 'Basos'],
    "Red Blood Count": ['RBC', 'RBCs', 'Red Blood Cells', 'Red Blood Count', 'Red Cell Count', 'Red Blood Cell Count'],
    "Hemoglobin": ['Hemoglobin', 'Hb'],
    "Hematocrit": ['Hematocrit'],
    "Platelets": ['Platelets']
  };

  List<String> itemsNotFound = ["White Blood Count", "Neutrophils", "Lymphocytes", "Monocytes", "Eosinophils", "Basophils",
    "Red Blood Count", "Hemoglobin", "Hematocrit", "Platelets"];

  bool medItemFound(String item) {
    for (String itemNotFound in itemsNotFound) {
      for (String medItem in medItems[itemNotFound]!) {
        if (item.contains(medItem)) {
          itemsNotFound.remove(medItem);
          return true;
        }
      }
    }
    return false;
  }

  String returnValue(String item) {
    RegExp valuePattern = RegExp(r"\d+(\.\d+)?");
    RegExpMatch? foundPattern = valuePattern.firstMatch(item);
    if (foundPattern == null) {
      return "No result value found.";
    }
    int startPattern = foundPattern.start;
    int endPattern = foundPattern.end;
    return item.substring(startPattern, endPattern);
  }

  String returnRange(String item) {
    RegExp valuePattern = RegExp(r"\d+(\.\d+)?(\sto\s|\s-\s|-)\d+(\.\d+)?");
    RegExpMatch? foundPattern = valuePattern.firstMatch(item);
    if (foundPattern == null) {
      return "No range found.";
    }
    int startPattern = foundPattern.start;
    int endPattern = foundPattern.end;
    return item.substring(startPattern, endPattern);
  }

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
        //var medItems = ["WBCs", "Neutophils", "Lymphocyles", "Monocytes", "Eosinophils", "Basophils", "RBCs", "Hb", "Hematocrit", "Platelets"];

        List<String> newResultList = [];

        for(var item in textLinesList) {
          if (medItemFound(item)) {
            print("Found an important item: " + item);
            try {
              int pos = textLinesList.indexOf(item);
              double result = double.parse(textLinesList[pos + 1]);
              String reference = textLinesList[pos + 2];
              if (returnRange(reference) != "No range found.") {
                List<String> ranges = [];
                if (reference.contains("to")) {
                  ranges = reference.split("to");
                } else if (reference.contains("-")) {
                  ranges = reference.split("-");
                }
                double min = double.parse(ranges![0]);
                double max = double.parse(ranges![1]);
                String decision = "Abnormal";
                if (result >= min && result <= max) {
                  decision = "Normal";
                } else if (result < min) {
                  decision = "Abnormally Low";
                } else if (result > max) {
                  decision = "Abnormally High";
                }
                String newResultStr = item + ": " + decision;
                print(newResultStr);
                newResultList.add(newResultStr);
              }

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
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.save),
        onPressed: () async {
          final Directory? dir = await getExternalStorageDirectory();
          final File file = File('${dir!.path}/results.txt');
          String text =  foundLines.join('\n');
          print(dir.path);
          file.writeAsString(text);
          Share.shareFiles(['${dir!.path}/results.txt']);
        },
      ),
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
