part of carp_study_app;

class CameraPage extends StatefulWidget {
  final VideoUserTask videoUserTask;
  const CameraPage({super.key, required this.videoUserTask});
  @override
  CameraPageState createState() => CameraPageState();
}

class CameraPageState extends State<CameraPage> {
  List<CameraDescription>? cameras;
  late CameraController _cameraController;
  Future<void>? cameraInit;

  IconData flashIcon = Icons.flash_off;
  bool isFlashOff = true;
  bool isRecording = false;
  bool isFrontCamera = false;
  bool isFlashOn = false;

  late File capturedImages;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> initializeCamera() async {
    cameras = await availableCameras();
    _cameraController = CameraController(
      cameras![0],
      ResolutionPreset.max,
      imageFormatGroup: ImageFormatGroup.yuv420,
      enableAudio: true,
    );
    cameraInit = _cameraController.initialize();
    setState(() {});
  }

  void toggleCamera() async {
    int newCameraIndex = isFrontCamera ? 0 : 1;
    _cameraController = CameraController(
      cameras![newCameraIndex],
      ResolutionPreset.max,
      imageFormatGroup: ImageFormatGroup.yuv420,
      enableAudio: true,
    );
    await _cameraController.initialize();
    setState(() {
      isFrontCamera = !isFrontCamera;
    });
  }

  void toggleFlash() {
    if (isFlashOn) {
      _cameraController.setFlashMode(FlashMode.off);
    } else {
      _cameraController.setFlashMode(FlashMode.torch);
    }
    setState(() {
      isFlashOn = !isFlashOn;
      flashIcon = isFlashOn ? Icons.flash_on : Icons.flash_off;
    });
  }

  void takePicture() async {
    var picture = await _cameraController.takePicture();
    widget.videoUserTask.onPictureCapture(picture);
    if (context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => DisplayPicturePage(
            file: picture,
            videoUserTask: widget.videoUserTask,
          ),
        ),
      );
    }

    setState(() {
      capturedImages = File(picture.path);
    });
  }

  void startRecording() async {
    try {
      await _cameraController.startVideoRecording();
      widget.videoUserTask.onRecordStart();
      setState(() {
        isRecording = true;
      });
    } on CameraException catch (e) {
      warning('$runtimeType - error: ${e.code}\n${e.description}');
    }
  }

  void stopRecording(dynamic details) async {
    try {
      var video = await _cameraController.stopVideoRecording();

      widget.videoUserTask.onRecordStop(video);
      if (context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
              builder: (context) =>
                  DisplayPicturePage(file: video, isVideo: true, videoUserTask: widget.videoUserTask)),
        );
      }
      setState(() {
        capturedImages = File(video.path);
        isRecording = false;
      });
    } on CameraException catch (e) {
      warning('$runtimeType - error: ${e.code}\n${e.description}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cameras == null || cameraInit == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Stack(
            children: [
              FutureBuilder<void>(
                future: cameraInit,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) {
                        return SizedBox(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          child: OverflowBox(
                            alignment: Alignment.center,
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _cameraController.value.previewSize!.height,
                                height: _cameraController.value.previewSize!.width,
                                child: CameraPreview(_cameraController),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    return CircularProgressIndicator();
                  }
                },
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  onPressed: () {
                    _showCancelConfirmationDialog();
                  },
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 30,
                    shadows: <Shadow>[
                      Shadow(
                        blurRadius: 3.0,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 30,
                left: 10,
                right: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      onPressed: toggleCamera,
                      icon: const Icon(
                        Icons.flip_camera_android,
                        color: Colors.white,
                        shadows: <Shadow>[
                          Shadow(
                            blurRadius: 3.0,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: takePicture,
                      onLongPress: startRecording,
                      onLongPressEnd: stopRecording,
                      child: isRecording
                          ? Stack(
                              alignment: Alignment.center,
                              children: [
                                const SizedBox(
                                  width: 65,
                                  height: 65,
                                  child: CircularProgressIndicator(
                                    backgroundColor: Colors.white54,
                                    valueColor: AlwaysStoppedAnimation(Colors.black54),
                                    strokeWidth: 5,
                                  ),
                                ),
                                Container(
                                  height: 60,
                                  width: 60,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            )
                          : Container(
                              height: 60,
                              width: 60,
                              decoration: const BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black,
                                    blurRadius: 3.0,
                                  )
                                ],
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    IconButton(
                      onPressed: toggleFlash,
                      icon: Icon(
                        flashIcon,
                        color: Colors.white,
                        shadows: <Shadow>[
                          Shadow(
                            blurRadius: 3.0,
                            color: Colors.black,
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

  Future<void> _showCancelConfirmationDialog() {
    RPLocalizations locale = RPLocalizations.of(context)!;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(locale.translate("pages.audio_task.discard")),
          actions: <Widget>[
            TextButton(
              child: Text(locale.translate("NO")),
              onPressed: () => Navigator.of(context).pop(), // Dismissing the pop-up
            ),
            TextButton(
              child: Text(locale.translate("YES")),
              onPressed: () {
                // Calling the onCancel method with which the developer can for e.g. save the result on the device.
                // Only call it if it's not null
                //widget.onCancel?.call(_taskResult);
                // Popup dismiss
                Navigator.of(context).pop();
                // Exit the Ordered Task
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            )
          ],
        );
      },
    );
  }
}
