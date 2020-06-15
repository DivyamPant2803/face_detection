import 'dart:io';

import 'package:facedetection/models/face_painter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  File pickedImage;
  var imageFile;
  var awaitImage;
  List<Rect> rect = new List<Rect>();
  bool isFaceDetected = false;
  bool isLoading = false;

  Future<void> pickImage(String mode) async{
    if(mode.contains('gallery'))
      awaitImage = await ImagePicker.pickImage(source: ImageSource.gallery);
    else if(mode.contains('camera'))
      awaitImage = await ImagePicker.pickImage(source: ImageSource.camera);
    setState(() {
      isLoading = true;
    });
    imageFile = await awaitImage.readAsBytes();
    imageFile = await decodeImageFromList(imageFile);

    setState(() {
      imageFile = imageFile;
      pickedImage = awaitImage;
    });

    FirebaseVisionImage visionImage = FirebaseVisionImage.fromFile(pickedImage);
    final FaceDetector faceDetector = FirebaseVision.instance.faceDetector();
    final List<Face> faces = await faceDetector.processImage(visionImage);

    if(rect.length > 0){
      rect = new List<Rect>();    //to clear rectangular bounding boxes whenever a new image is selected.
    }

    for(Face face in faces){
      rect.add(face.boundingBox);

      final double rotY = face.headEulerAngleY; // Head is rotated to the right rotY degrees
      final double rotZ = face.headEulerAngleZ; // Head is tilted sideways rotZ degrees
      print('The rotation y is '+rotY.toStringAsFixed(2));
      print('The rotation z is '+rotZ.toStringAsFixed(2));
    }

    setState(() {
      isFaceDetected = true;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Face Detector'),
      ),
      body: isLoading ? Center(child: CircularProgressIndicator(),) : Column(
        children: <Widget>[
          SizedBox(height: 50,),
          isFaceDetected
              ? Expanded(
                child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: const [
                          BoxShadow(blurRadius: 20),
                        ],
                      ),
                      margin: EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: FittedBox(
                        child: SizedBox(
                          width: imageFile.width.toDouble(),
                          height: imageFile.height.toDouble(),
                          child: CustomPaint(
                            painter: FacePainter(rect: rect, imageFile: imageFile),
                          ),
                        ),
                      ),
                    ),
                  ),
              )
              : Container(),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Column(
                    children: <Widget>[
                      IconButton(
                          onPressed: () async{
                            pickImage('gallery');
                          },
                        icon: Icon(Icons.image, size: 60, color: Colors.blue),
                      ),
                      SizedBox(height: 20,),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text('Select from gallery'),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      IconButton(
                        onPressed: () async{
                          pickImage('camera');
                        },
                        icon: Icon(Icons.camera, size: 60, color: Colors.blue,),
                      ),
                      SizedBox(height: 20,),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text('Capture Image'),
                      )
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
