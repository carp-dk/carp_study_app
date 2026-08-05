part of carp_study_app;

class CameraTaskPage extends StatefulWidget {
  final VideoUserTask mediaUserTask;

  const CameraTaskPage({super.key, required this.mediaUserTask});

  @override
  CameraTaskPageState createState() => CameraTaskPageState();
}

class CameraTaskPageState extends State<CameraTaskPage> {
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: true,
    child: Scaffold(
      body: SafeArea(
        child: StreamBuilder<UserTaskState>(
          stream: widget.mediaUserTask.stateEvents,
          initialData: UserTaskState.enqueued,
          builder: (context, AsyncSnapshot<UserTaskState> snapshot) {
            RPLocalizations locale = RPLocalizations.of(context)!;
            switch (snapshot.data) {
              case UserTaskState.enqueued:
                return StreamBuilder<UserTaskState>(
                  stream: widget.mediaUserTask.stateEvents,
                  initialData: UserTaskState.enqueued,
                  builder: (context, AsyncSnapshot<UserTaskState> snapshot) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
                              child: const CarpAppBar(hasProfileIcon: false),
                            ),
                            Spacer(),
                            IconButton(
                              color: Colors.grey.shade900,
                              onPressed: () {
                                _showCancelConfirmationDialog();
                              },
                              icon: const Icon(Icons.close, size: 30),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 30),
                              child: const Image(image: AssetImage('assets/icons/camera.png'), width: 220, height: 220),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                locale.translate(widget.mediaUserTask.title),
                                style: Theme.of(context).textTheme.titleLarge!,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                              child: Text(
                                locale.translate(widget.mediaUserTask.description),
                                style: Theme.of(context).textTheme.labelLarge!,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 30),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  OutlinedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text(locale.translate("Cancel")),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (context) => CameraPage(videoUserTask: widget.mediaUserTask),
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                    ),
                                    child: Text(locale.translate("next"), style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              default:
                return const SizedBox.shrink();
            }
          },
        ),
      ),
    ),
  );

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
              onPressed: () => context.pop(), // Dismissing the pop-up
            ),
            TextButton(
              child: Text(locale.translate("YES")),
              onPressed: () {
                // Calling the onCancel method with which the developer can for e.g. save the result on the device.
                // Only call it if it's not null
                //widget.onCancel?.call(_taskResult);
                // Popup dismiss
                context.pop();
                // Exit the Ordered Task
                context.canPop() ? context.pop() : null;
              },
            ),
          ],
        );
      },
    );
  }
}
