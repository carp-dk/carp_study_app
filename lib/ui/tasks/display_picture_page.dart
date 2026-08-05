part of carp_study_app;

class DisplayPicturePage extends StatefulWidget {
  final XFile file;
  final bool isVideo;
  final VideoUserTask videoUserTask;

  const DisplayPicturePage({super.key, required this.file, required this.videoUserTask, this.isVideo = false});

  @override
  State<DisplayPicturePage> createState() => DisplayPicturePageState();
}

class DisplayPicturePageState extends State<DisplayPicturePage> {
  VideoPlayerController? _videoPlayerController;

  /// The path of the video file which has been recorded in the [CameraPage].
  String get videoFilePath => widget.file.path;

  @override
  void initState() {
    super.initState();

    // initialize video player controller
    _videoPlayerController = VideoPlayerController.file(File(videoFilePath))
      ..initialize().then((_) {
        setState(() {});
        _videoPlayerController?.setLooping(true);
        _videoPlayerController?.play();
      });
  }

  @override
  void dispose() {
    super.dispose();
    _videoPlayerController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 35),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
                  child: const CarpAppBar(hasProfileIcon: false),
                ),
                Spacer(),
                IconButton(
                  color: Theme.of(context).extension<CarpColors>()!.grey900,
                  onPressed: () {
                    _showCancelConfirmationDialog();
                  },
                  icon: const Icon(Icons.close, size: 30),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: (widget.isVideo && _videoPlayerController != null)
                      ? _videoPlayerController!.value.isInitialized
                            ? AspectRatio(
                                aspectRatio: _videoPlayerController!.value.aspectRatio,
                                child: VideoPlayer(_videoPlayerController!),
                              )
                            : const CircularProgressIndicator()
                      : Image.file(File(videoFilePath)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 30, left: 10, right: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(locale.translate('pages.audio_task.done'), style: Theme.of(context).textTheme.titleLarge!),
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(locale.translate('pages.audio_task.recording_completed'), style: Theme.of(context).textTheme.labelLarge!),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: FractionalOffset.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 30.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 30),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            padding: const EdgeInsets.all(0),
                            icon: const Icon(Icons.replay, size: 25, color: Color(0xff707070)),
                          ),
                          const SizedBox(width: 20),
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Theme.of(context).extension<CarpColors>()!.success,
                            child: IconButton(
                              onPressed: () {
                                widget.videoUserTask.onSave();
                                Navigator.of(context).pop();
                                Navigator.of(context).pop();
                                Navigator.of(context).pop();
                              },
                              padding: const EdgeInsets.all(0),
                              icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 30),
                            ),
                          ),
                          const SizedBox(width: 50),
                          const SizedBox(width: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            TextButton(child: Text(locale.translate("NO")), onPressed: () => Navigator.of(context).pop()),
            TextButton(
              child: Text(locale.translate("YES")),
              onPressed: () {
                // Popup dismiss
                Navigator.of(context).pop();
                // Exit the Ordered Task
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
