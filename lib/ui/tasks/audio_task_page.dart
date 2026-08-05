part of carp_study_app;

class AudioTaskPage extends StatefulWidget {
  final AudioUserTask? audioUserTask;
  const AudioTaskPage({super.key, this.audioUserTask});

  @override
  AudioTaskPageState createState() => AudioTaskPageState();
}

class AudioTaskPageState extends State<AudioTaskPage> {
  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: PopScope(
          canPop: true,
          child: Scaffold(
            body: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
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
                        color: Theme.of(context).extension<CarpColors>()!.grey900,
                        onPressed: () {
                          _showCancelConfirmationDialog();
                        },
                        icon: const Icon(Icons.close, size: 30),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: const Image(image: AssetImage('assets/icons/audio.png'), width: 220, height: 220),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(locale.translate(widget.audioUserTask!.title), style: Theme.of(context).textTheme.titleLarge!),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    child: Text(
                      '${locale.translate(widget.audioUserTask!.description)}\n\n'
                      '${locale.translate('pages.audio_task.play')}',
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
                            widget.audioUserTask!.onCancel();
                            Navigator.pop(context);
                          },
                          child: Text(locale.translate("Cancel")),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) => AudioPage(audioUserTask: widget.audioUserTask),
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
            ),
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
              onPressed: () {
                context.pop();
              },
            ),
            TextButton(
              child: Text(locale.translate("YES")),
              onPressed: () {
                context.pushReplacement(CarpAppState.homeRoute);
              },
            ),
          ],
        );
      },
    );
  }
}
