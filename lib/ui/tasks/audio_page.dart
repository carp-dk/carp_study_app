part of carp_study_app;

class AudioPage extends StatefulWidget {
  final AudioUserTask? audioUserTask;
  const AudioPage({super.key, this.audioUserTask});

  @override
  AudioPageState createState() => AudioPageState();
}

class AudioPageState extends State<AudioPage> {
  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<UserTaskState>(
          stream: widget.audioUserTask!.stateEvents,
          builder: (context, snapshot) {
            return Container(
              child: StreamBuilder<UserTaskState>(
                stream: widget.audioUserTask!.stateEvents,
                initialData: UserTaskState.enqueued,
                builder: (context, AsyncSnapshot<UserTaskState> snapshot) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
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
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (snapshot.data == UserTaskState.enqueued)
                                Expanded(
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 24),
                                        child: Text(
                                          locale.translate(widget.audioUserTask!.title),
                                          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                      StudiesMaterial(
                                        backgroundColor: Colors.white,
                                        child: Scrollbar(
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.vertical, //.horizontal
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text(
                                                locale.translate(widget.audioUserTask!.instructions),
                                                style: Theme.of(context).textTheme.labelLarge!,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Spacer(),
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundColor: Theme.of(context).colorScheme.primary,
                                        child: IconButton(
                                          onPressed: () => widget.audioUserTask!.onRecordStart(),
                                          padding: const EdgeInsets.all(0),
                                          icon: const Icon(Icons.mic, color: Colors.white, size: 30),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8, bottom: 40),
                                        child: Text(locale.translate("pages.audio_task.play"), style: Theme.of(context).textTheme.labelLarge!),
                                      ),
                                    ],
                                  ),
                                )
                              else if (snapshot.data == UserTaskState.started)
                                Expanded(
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 24),
                                        child: Text(
                                          locale.translate(widget.audioUserTask!.title),
                                          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                      StudiesMaterial(
                                        backgroundColor: Colors.white,
                                        child: Scrollbar(
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.vertical, //.horizontal
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text(
                                                locale.translate(widget.audioUserTask!.instructions),
                                                style: Theme.of(context).textTheme.labelLarge!,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Spacer(),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          CircleAvatar(
                                            radius: 30,
                                            backgroundColor: CACHET.RED_1,
                                            child: IconButton(
                                              onPressed: () => widget.audioUserTask!.onRecordStop(),
                                              padding: const EdgeInsets.all(0),
                                              icon: const Icon(Icons.stop, color: Colors.white, size: 30),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8, bottom: 40),
                                        child: Text(locale.translate("pages.audio_task.recording"), style: Theme.of(context).textTheme.titleLarge!),
                                      ),
                                    ],
                                  ),
                                )
                              else if (snapshot.data == UserTaskState.done)
                                Expanded(
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 32),
                                        child: Text(
                                          locale.translate('pages.audio_task.done'),
                                          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 20),
                                        child: Text(
                                          locale.translate('pages.audio_task.recording_completed'),
                                          style: Theme.of(context).textTheme.labelLarge!,
                                        ),
                                      ),
                                      Spacer(),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8, bottom: 40, left: 20, right: 20),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              flex: 1,
                                              child: IconButton(
                                                onPressed: () => widget.audioUserTask!.onRecordReset(),
                                                icon: Icon(
                                                  Icons.replay,
                                                  color: Colors.grey.shade700,
                                                  size: 30,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: CircleAvatar(
                                                radius: 30,
                                                backgroundColor: CACHET.GREEN_1,
                                                child: IconButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                    Navigator.of(context).pop();
                                                  },
                                                  padding: const EdgeInsets.all(0),
                                                  icon: const Icon(
                                                    Icons.check_circle_outline,
                                                    color: Colors.white,
                                                    size: 30,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(flex: 1, child: Container()),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Spacer(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
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
