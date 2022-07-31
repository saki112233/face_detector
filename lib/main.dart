import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:async';
import 'package:flutter_face_api/face_api.dart' as Regula;
import 'package:image_picker/image_picker.dart';

void main() => runApp(new MaterialApp(home: new MyApp()));

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var image1 = Regula.MatchFacesImage();
  var image2 = Regula.MatchFacesImage();
  var image3 = Regula.MatchFacesImage();
  var img1 = Image.asset('assets/image.jpg');
  var img2 = Image.asset('assets/image.jpg');
  var img3 = Image.asset('assets/image.jpg');
  String _similarity = "nil";
  String _liveness = "nil";

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {}

  showAlertDialog(BuildContext context, String valu) => showDialog(
      context: context,
      builder: (BuildContext context) =>
          AlertDialog(title: Text("Select option"), actions: [
            // ignore: deprecated_member_use
            FlatButton(
                child: Text("Use gallery"),
                onPressed: () {
                  ImagePicker().pickImage(source: ImageSource.gallery).then(
                          (value) => setImage(
                          valu,
                          io.File(value!.path).readAsBytesSync(),
                          Regula.ImageType.PRINTED));
                  Navigator.pop(context);
                }),
            // ignore: deprecated_member_use
            FlatButton(
                child: Text("Use camera"),
                onPressed: () {
                  Regula.FaceSDK.presentFaceCaptureActivity().then((result) =>
                      setImage(
                          valu,
                          base64Decode(Regula.FaceCaptureResponse.fromJson(
                              json.decode(result))!
                              .image!
                              .bitmap!
                              .replaceAll("\n", "")),
                          Regula.ImageType.LIVE));
                  Navigator.pop(context);
                })
          ]));

  setImage(
      String value,
      List<int> imageFile,
      int type) {
    if (imageFile == null) return;
    setState(() => _similarity = "nil");
    if (value=='first') {
      image1.bitmap = base64Encode(imageFile);
      image1.imageType = type;
      setState(() {
        img1 = Image.memory(base64Decode(imageFile.toString()));
        _liveness = "nil";
      });
    }
    if (value=='third') {
      image3.bitmap = base64Encode(imageFile);
      image3.imageType = type;
      setState(() {
        img3 = Image.memory(base64Decode(imageFile.toString()));
        _liveness = "nil";
      });
    }

    else {
      image2.bitmap = base64Encode(imageFile);
      image2.imageType = type;
      setState(() => img2 = Image.memory(base64Decode(imageFile.toString())));
    }
  }

  clearResults() {
    setState(() {
      img1 = Image.asset('assets/image.jpg');
      img2 = Image.asset('assets/image.jpg');
      _similarity = "nil";
      _liveness = "nil";
    });
    image1 = new Regula.MatchFacesImage();
    image2 = new Regula.MatchFacesImage();
  }

  matchFaces() async{
    if (image1 == null ||
        image1.bitmap == null ||
        image1.bitmap == "" ||
        image2 == null ||
        image2.bitmap == null ||
        image2.bitmap == ""||
    image3.bitmap == null ||
    image3.bitmap == ""
    // image3==null||
    // image3.bitmap==null||
    // image3.bitmap==""
    ) return;
    setState(() => _similarity = "Processing...");
    var request1 =  Regula.MatchFacesRequest();
    request1.images = [image1, image2];
    String rq1='';
    var request2 =  Regula.MatchFacesRequest();
    request2.images = [image2, image3];
    String rq2='';
    await Regula.FaceSDK.matchFaces(jsonEncode(request1)).then((value) {
      var response = Regula.MatchFacesResponse.fromJson(json.decode(value));
      Regula.FaceSDK.matchFacesSimilarityThresholdSplit(
          jsonEncode(response!.results), 0.75)
          .then((str) {
        var split = Regula.MatchFacesSimilarityThresholdSplit.fromJson(
            json.decode(str));
        setState(() => rq1 = split!.matchedFaces.isNotEmpty
            ? ("${(split.matchedFaces[0]!.similarity! * 100).toStringAsFixed(2)}")
            : "error");
      });
    });
   await Regula.FaceSDK.matchFaces(jsonEncode(request2)).then((value) {
      var response = Regula.MatchFacesResponse.fromJson(json.decode(value));
      Regula.FaceSDK.matchFacesSimilarityThresholdSplit(
          jsonEncode(response!.results), 0.75)
          .then((str) {
        var split = Regula.MatchFacesSimilarityThresholdSplit.fromJson(
            json.decode(str));
        setState(() {rq2 = split!.matchedFaces.isNotEmpty
            ? ("${(split.matchedFaces[0]!.similarity! * 100).toStringAsFixed(2)}")
            : "error";
        print(rq2);
        print(rq1);
        double a = double.parse(rq2)+double.parse(rq1);
        double b = a/2;
        _similarity=b.toString();
        });
      });
    });
  }

  liveness() => Regula.FaceSDK.startLiveness().then((value) {
    var result = Regula.LivenessResponse.fromJson(json.decode(value));
    setImage('first', base64Decode(result!.bitmap!.replaceAll("\n", "")),
        Regula.ImageType.LIVE);
    setState(() => _liveness = result.liveness == 0 ? "passed" : "unknown");
  });

  Widget createButton(String text, VoidCallback onPress) => Container(
    // ignore: deprecated_member_use
    child: FlatButton(
        color: Color.fromARGB(50, 10, 10, 10),
        onPressed: onPress,
        child: Text(text)),
    width: 250,
  );

  Widget createImage(image, VoidCallback onPress) => Material(
      child: InkWell(
        onTap: onPress,
        child: Container(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: Image(height: 150, width: 150, image: image),
          ),
        ),
      ));

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
        margin: EdgeInsets.fromLTRB(0, 0, 0, 100),
        width: double.infinity,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              createImage(img1.image, () => showAlertDialog(context, 'first')),
              createImage(img2.image, () => showAlertDialog(context, 'second')),
              createImage(img3.image, () => showAlertDialog(context, 'third')),
              // createImage(
              //     img3.image, () => showAlertDialog(context, false)),
              Container(margin: EdgeInsets.fromLTRB(0, 0, 0, 15)),
              createButton("Match", () => matchFaces()),
              createButton("Liveness", () => liveness()),
              createButton("Clear", () => clearResults()),
              Container(
                  margin: EdgeInsets.fromLTRB(0, 15, 0, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Similarity: " + _similarity,
                          style: TextStyle(fontSize: 18)),
                      Container(margin: EdgeInsets.fromLTRB(20, 0, 0, 0)),
                      Text("Liveness: " + _liveness,
                          style: TextStyle(fontSize: 18))
                    ],
                  ))
            ])),
  );
}
