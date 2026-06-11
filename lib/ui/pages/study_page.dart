part of carp_study_app;

class StudyPage extends StatefulWidget {
  static const String route = '/study';
  final StudyPageViewModel model;
  const StudyPage({super.key, required this.model});

  @override
  StudyPageState createState() => StudyPageState();
}

class StudyPageState extends State<StudyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).extension<CarpColors>()!.backgroundGray,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
              child: const CarpAppBar(hasProfileIcon: true),
            ),
            Flexible(
              // Re-render when configureStudy completes; until then show loader.
              child: ListenableBuilder(
                listenable: bloc,
                builder: (context, _) {
                  if (!bloc.isConfigured) {
                    return const _ConfiguringStudyLoader();
                  }
                  return StreamBuilder<int>(
                    stream: widget.model.messageStream,
                    builder: (context, AsyncSnapshot<int> snapshot) {
                      final cards = _buildCards(context);
                      return RefreshIndicator(
                        onRefresh: () async {
                          await bloc.refreshMessages();
                          final status = await Sensing().tryDeployment();
                          if (status == StudyStatus.Deployed) {
                            bloc.start();
                          }
                          bloc.deploymentService.getStudyDeploymentStatus(widget.model.studyDeploymentId);
                        },
                        child: ListView.builder(
                          itemCount: cards.length,
                          itemBuilder: (context, index) => cards[index],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCards(BuildContext context) {
    final items = <Widget>[];
    final updateCard = _hasUpdateCard();
    items.add(updateCard);
    items.add(_studyCard(
      context,
      widget.model.studyDescriptionMessage,
      onTap: () {
        context.push(StudyDetailsPage.route);
      },
    ));
    items.add(_studyStatusCard());
    if (LocalSettings().isAnonymous) {
      items.add(AnonymousCard());
    }
    if (widget.model.messages.isNotEmpty) {
      items.add(_buildAnnouncementsTitle(context));
      // Show newest announcements first: sort by timestamp descending
      final messages = List<Message>.from(widget.model.messages)..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      items.addAll(messages.map((message) {
        return _announcementCard(context, message);
      }).toList());
    }
    return items;
  }

  Widget _hasUpdateCard() {
    RPLocalizations locale = RPLocalizations.of(context)!;
    return FutureBuilder<bool?>(
        future: bloc.getAppHasUpdate(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return StudiesMaterial(
              backgroundColor: Theme.of(context).extension<CarpColors>()!.grey50!,
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          locale.translate('pages.about.app_update'),
                          style: fs16fw600.copyWith(
                            color: Theme.of(context).extension<CarpColors>()!.grey900,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: ElevatedButton(
                        onPressed: () async {
                          _redirectToUpdateStore();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CACHET.DEPLOYMENT_DEPLOYING,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          locale.translate("get"),
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return SizedBox.shrink();
          }
        });
  }

  Widget _studyCard(
    BuildContext context,
    Message message, {
    Function? onTap,
  }) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    // Initialization the language of the timeago package
    timeago.setLocaleMessages('da', timeago.DaMessages());
    timeago.setLocaleMessages('es', timeago.EsMessages());

    return StudiesMaterial(
      backgroundColor: Theme.of(context).extension<CarpColors>()!.grey50!,
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap();
          } else {
            context.push('${MessageDetailsPage.route}/${message.id}');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (message.image != null && message.image != '')
                Center(
                  child: Container(
                    height: 150,
                    color: Theme.of(context).colorScheme.secondary,
                    child: widget.model.getMessageImage(message.image),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(locale.translate(message.title!),
                    style: fs24fw700.copyWith(color: Theme.of(context).extension<CarpColors>()!.primary)),
              ),
              if (message.subTitle != null && message.subTitle!.isNotEmpty)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        locale.translate(message.subTitle!),
                        style: fs16fw400.copyWith(
                          color: Theme.of(context).extension<CarpColors>()!.grey700,
                        ),
                      ),
                    ),
                  ],
                ),
              if (message.message != null && message.message!.isNotEmpty)
                Row(children: [
                  Expanded(
                      child: Text(
                    "${locale.translate(message.message!).substring(0, (message.message!.length > 150) ? 150 : null)}...",
                    style: fs16fw400.copyWith(color: Theme.of(context).extension<CarpColors>()!.grey900),
                    textAlign: TextAlign.start,
                  )),
                ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _studyStatusCard() {
    RPLocalizations locale = RPLocalizations.of(context)!;

    return FutureBuilder<StudyDeploymentStatus?>(
      future: bloc.studyDeploymentStatus,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return StudiesMaterial(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return StudiesMaterial(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Text(
                'Error: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          ); // Show an error message if the future fails
        } else if (!snapshot.hasData || snapshot.data == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ); // Handle the case where data is null
        }

        final deploymentStatus = snapshot.data!.status;

        return StudiesMaterial(
          margin: const EdgeInsets.all(16.0),
          backgroundColor: Theme.of(context).extension<CarpColors>()!.grey50!,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 22.0),
                    child: Row(
                      children: [
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: studyStatusColors[deploymentStatus],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0),
                              child: Text(
                                deploymentStatus == StudyDeploymentStatusTypes.DeployingDevices
                                    ? locale.translate('pages.about.status.deploying_devices')
                                    : deploymentStatus.toString().split('.').last,
                                maxLines: 2,
                                style: fs16fw600.copyWith(color: studyStatusColors[deploymentStatus]),
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Text(
                              getStatusText(locale, deploymentStatus, snapshot),
                              style: fs16fw600.copyWith(
                                color: Theme.of(context).extension<CarpColors>()!.grey900,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnnouncementsTitle(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    return Container(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(locale.translate('Announcements'),
                  style: fs24fw700.copyWith(
                    color: Theme.of(context).extension<CarpColors>()!.grey900,
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _announcementCard(
    BuildContext context,
    Message message, {
    Function? onTap,
  }) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    // Initialization the language of the timeago package
    timeago.setLocaleMessages('da', timeago.DaMessages());
    timeago.setLocaleMessages('es', timeago.EsMessages());

    return Container(
      child: StudiesMaterial(
        backgroundColor: Theme.of(context).extension<CarpColors>()!.grey50!,
        child: InkWell(
          onTap: () {
            if (onTap != null) {
              onTap();
            } else {
              context.push('${MessageDetailsPage.route}/${message.id}');
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 8, right: 8),
                        child: Text(
                          locale.translate(message.title!),
                          overflow: TextOverflow.ellipsis,
                          style: fs20fw700.copyWith(
                            color: Theme.of(context).extension<CarpColors>()!.grey900,
                          ),
                        ),
                      ),
                    ),
                    Material(
                      color: CACHET.DEPLOYMENT_DEPLOYING,
                      borderRadius: BorderRadius.circular(100.0),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(message.type.icon, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      if (message.subTitle != null && message.subTitle!.isNotEmpty)
                        Expanded(
                          child: Text(
                            locale.translate(message.subTitle!),
                            style: fs16fw400.copyWith(
                              color: Theme.of(context).extension<CarpColors>()!.grey700,
                            ),
                          ),
                        ),
                      Spacer(),
                      Text(
                        timeago.format(message.timestamp.toLocal()),
                        style: fs10fw600.copyWith(
                          color: Theme.of(context).extension<CarpColors>()!.grey600,
                        ),
                      )
                    ],
                  ),
                ),
                if (message.message != null && message.message!.isNotEmpty)
                  Row(
                    children: [
                      Expanded(
                          child: Text(
                        locale.translate(message.message!).length > 150
                            ? '${locale.translate(message.message!).substring(0, 150)}...'
                            : locale.translate(message.message!),
                        style: fs16fw400,
                        textAlign: TextAlign.start,
                      )),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _redirectToUpdateStore() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    Uri url;
    if (Platform.isAndroid) {
      url = Uri.parse('https://play.google.com/store/apps/details?id=${packageInfo.packageName}');
    } else if (Platform.isIOS) {
      url = Uri.parse('https://apps.apple.com/app/id1569798025');
    } else {
      throw 'Unsupported platform';
    }
    var canLaunch = await canLaunchUrl(url);
    if (canLaunch) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  String getStatusText(
    RPLocalizations locale,
    StudyDeploymentStatusTypes deploymentStatusType,
    AsyncSnapshot<StudyDeploymentStatus?> snapshot,
  ) {
    if (deploymentStatusType == StudyDeploymentStatusTypes.DeployingDevices) {
      return locale.translate('pages.about.status.deploying_devices.message') +
          snapshot.data!.deviceStatusList.first.remainingDevicesToRegisterBeforeDeployment!.join(' | ');
    } else {
      return locale.translate(studyStatusText[deploymentStatusType]!);
    }
  }

  static Map<StudyDeploymentStatusTypes, Color> studyStatusColors = {
    StudyDeploymentStatusTypes.Invited: CACHET.DEPLOYMENT_INVITED,
    StudyDeploymentStatusTypes.DeployingDevices: CACHET.DEPLOYMENT_DEPLOYING,
    StudyDeploymentStatusTypes.Running: CACHET.DEPLOYMENT_RUNNING,
    StudyDeploymentStatusTypes.Stopped: CACHET.DEPLOYMENT_STOPPED,
  };

  static Map<StudyDeploymentStatusTypes, String> studyStatusText = {
    StudyDeploymentStatusTypes.Invited: 'pages.about.status.invited.message',
    StudyDeploymentStatusTypes.DeployingDevices: 'pages.about.status.deploying_devices.message',
    StudyDeploymentStatusTypes.Running: 'pages.about.status.running.message',
    StudyDeploymentStatusTypes.Stopped: 'pages.about.status.stopped.message',
  };
}

extension CopyWithAdditional on DateTime {
  DateTime copyWithAdditional({
    int years = 0,
    int months = 0,
    int days = 0,
    int hours = 0,
    int minutes = 0,
    int seconds = 0,
    int milliseconds = 0,
    int microseconds = 0,
  }) {
    return DateTime(
      year + years,
      month + months,
      day + days,
      hour + hours,
      minute + minutes,
      second + seconds,
      millisecond + milliseconds,
      microsecond + microseconds,
    );
  }
}

/// Placeholder shown while [StudyAppBLoC.configureStudy] is running.
class _ConfiguringStudyLoader extends StatelessWidget {
  const _ConfiguringStudyLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Configuring the study',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
