import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

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
    controller?.dispose();
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
    );
  }
}

// class MyApp extends StatelessWidget {
//   // This widget is the root of your application.
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         scaffoldBackgroundColor: Colors.white,
//       ),
//       home: MyHomePage(title: 'Home Page of App'),
//     );
//   }
// }
//
// class MyHomePage extends StatefulWidget {
//   MyHomePage({Key? key, required this.title}) : super(key: key);
//
//   final String title;
//
//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }
//
// class _MyHomePageState extends State<MyHomePage> {
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.title),
//       ),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: selectImage,
//           child: Text("Button"),
//         ),
//       ),
//     );
//   }
// }
//
//
//
//
//
