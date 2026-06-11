part of carp_study_app;

enum ProcessStatus { done, error, other }

class ProcessMessagePage extends StatelessWidget {
  // Type of message to display (e.g Error, Success, Informative)
  final ProcessStatus statusType;

  // Message title
  final String title;

  // Message description
  final String description;

  // Button text
  final String actionText;

  // Button action on pressed. Function called by pressing the button.
  final Function actionFunction;

  // Display cancel button. If true the button is displayed.
  final bool canCancel;

  const ProcessMessagePage({
    super.key,
    required this.statusType,
    required this.title,
    required this.description,
    required this.actionFunction,
    required this.actionText,
    this.canCancel = true,
  });

  @override
  Widget build(BuildContext context) {
    Image messageImage() {
      final Image image;
      switch (statusType) {
        case ProcessStatus.done:
          image = Image(
            image: const AssetImage('assets/icons/done.png'),
            height: MediaQuery.of(context).size.height * 0.35,
          );
          break;
        case ProcessStatus.error:
          image = Image(
            image: const AssetImage('assets/icons/error.png'),
            height: MediaQuery.of(context).size.height * 0.35,
          );
          break;
        case ProcessStatus.other:
          image = Image(
            image: const AssetImage('assets/icons/info.png'),
            height: MediaQuery.of(context).size.height * 0.35,
          );
          break;
      }

      return image;
    }

    RPLocalizations locale = RPLocalizations.of(context)!;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            messageImage(),
            const SizedBox(height: 20),
            Center(child: Text(locale.translate(title), style: fs22fw700)),
            const SizedBox(height: 10),
            Text(locale.translate(description), style: fs16fw600),
          ],
        ),
      ),
      bottomSheet: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          canCancel == true
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 15),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        locale.translate('cancel').toUpperCase(),
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                )
              : const SizedBox.shrink(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                onPressed: () {
                  actionFunction();
                },
                child: Text(locale.translate(actionText).toUpperCase()),
              ),
              const SizedBox(width: 15),
            ],
          ),
        ],
      ),
    );
  }
}
