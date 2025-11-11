part of carp_study_app;

class ProfilePage extends StatefulWidget {
  static const String route = '/profile';
  final ProfilePageViewModel model;
  const ProfilePage(this.model, {super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  String appName = '';
  String packageName = '';
  String appVersion = '';
  String buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).extension<RPColors>()!.grey100,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 35),
          // Top bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.account_circle,
                      color: Theme.of(context).primaryColor, size: 30),
                  label: Text(locale.translate("pages.profile.title"),
                      style: aboutCardTitleStyle.copyWith(
                          color: Theme.of(context).primaryColor)),
                ),
                IconButton(
                  icon: Icon(Icons.close,
                      color: Theme.of(context).primaryColor, size: 30),
                  tooltip: locale.translate('Back'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
          LocalSettings().isAnonymous ? AnonymousCard() : SizedBox.shrink(),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildSectionCard(
                    context,
                    [
                      _buildListTile(
                        locale.translate('pages.profile.username'),
                        widget.model.username,
                      ),
                      _buildListTile(
                        locale.translate('pages.profile.account_id'),
                        widget.model.userId,
                      ),
                      _buildListTile(
                        locale.translate('pages.profile.full_name'),
                        LocalSettings().isAnonymous
                            ? locale
                                .translate('pages.about.anonymous.anonymous')
                            : widget.model.fullName,
                      ),
                      _buildListTile(
                        locale.translate('pages.profile.email'),
                        LocalSettings().isAnonymous
                            ? locale
                                .translate('pages.about.anonymous.anonymous')
                            : widget.model.email,
                      ),
                    ],
                  ),
                  _buildSectionCard(
                    context,
                    [
                      _buildListTile(
                        locale.translate('pages.profile.study_id'),
                        widget.model.studyId,
                      ),
                      _buildListTile(
                        locale.translate('pages.profile.study_deployment_id'),
                        widget.model.studyDeploymentId,
                      ),
                      _buildListTile(
                        locale.translate('pages.profile.study_name'),
                        locale.translate(widget.model.studyDeploymentTitle),
                      ),
                      _buildListTile(
                        locale.translate('pages.profile.participant_id'),
                        widget.model.participantId,
                      ),
                      _buildListTile(
                        locale.translate('pages.profile.participant_role'),
                        widget.model.participantRole,
                      ),
                      _buildListTile(
                        locale.translate('pages.profile.device_role'),
                        widget.model.deviceRole,
                      ),
                    ],
                  ),
                  _buildSectionCard(context, [
                    _buildListTile(
                      locale.translate('pages.profile.app_version'),
                      appVersion,
                    ),
                    _buildListTile(
                      locale.translate('pages.profile.app_version_code'),
                      buildNumber,
                    ),
                    _buildListTile(
                      locale.translate('pages.profile.server_name'),
                      widget.model.currentServer,
                    ),
                    _buildListTile(
                      locale.translate('pages.profile.device_id'),
                      widget.model.deviceID,
                    ),
                  ]),
                  _buildSectionCard(
                    context,
                    [
                      _buildActionListTile(
                        leading: Icon(Icons.mail,
                            color: Theme.of(context).primaryColor),
                        trailing: const Icon(Icons.arrow_forward_ios,
                            color: CACHET.GREY_6),
                        title: locale.translate('pages.profile.contact'),
                        onTap: () async {
                          _sendEmailToContactResearcher(
                            locale.translate(widget.model.responsibleEmail),
                            'Support for study: ${locale.translate(widget.model.studyDeploymentTitle)} - User: ${widget.model.username}',
                          );
                        },
                      ),
                      _buildActionListTile(
                        leading: Icon(Icons.policy,
                            color: Theme.of(context).primaryColor),
                        trailing: const Icon(Icons.arrow_forward_ios,
                            color: CACHET.GREY_6),
                        title: locale.translate('pages.profile.privacy'),
                        onTap: () async {
                          try {
                            launchUrl(Uri.parse(CarpBackend.carpPrivacyUrl));
                          } finally {}
                        },
                      ),
                      _buildActionListTile(
                        leading: Icon(Icons.public,
                            color: Theme.of(context).primaryColor),
                        trailing: const Icon(Icons.arrow_forward_ios,
                            color: CACHET.GREY_6),
                        title: locale.translate('pages.profile.study_website'),
                        onTap: () async {
                          try {
                            launchUrl(Uri.parse(CarpBackend.carpWebsiteUrl));
                          } finally {}
                        },
                      ),
                    ],
                  ),
                  _buildSectionCard(context, [
                    _buildActionListTile(
                      leading: const Icon(Icons.logout, color: CACHET.RED_1),
                      title: locale.translate('pages.profile.leave_study'),
                      onTap: () {
                        _showLeaveStudyConfirmationDialog();
                      },
                    ),
                  ]),
                  _buildSectionCard(context, [
                    _buildActionListTile(
                      leading: const Icon(Icons.power_settings_new,
                          color: CACHET.RED_1),
                      title: locale.translate('pages.profile.log_out'),
                      onTap: () async {
                        bool isConnected = await bloc.checkConnectivity();
                        if (isConnected) {
                          _showLogoutConfirmationDialog();
                        } else {
                          _showEnableInternetConnectionDialog();
                        }
                      },
                    ),
                  ])
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, List<Widget> children) {
    return Card(
      color: Theme.of(context).extension<RPColors>()!.grey50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: ListTile.divideTiles(
            context: context,
            tiles: children,
            color: Theme.of(context).extension<RPColors>()!.grey400,
          ).toList(),
        ),
      ),
    );
  }

  Widget _buildListTile(String title, String subtitle) {
    return ListTile(
      title: Text(title,
          style: profileSectionStyle.copyWith(color: CACHET.GREY_6)),
      subtitle: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          subtitle,
          style: profileTitleStyle,
          maxLines: 1,
        ),
      ),
    );
  }

// Helper method to build a ListTile for actions with an icon
  Widget _buildActionListTile({
    required Icon leading,
    required String title,
    Icon? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: leading,
      title: Text(title,
          style: profileActionStyle.copyWith(
              color: Theme.of(context).extension<RPColors>()!.grey900)),
      trailing: trailing,
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
    );
  }

  Future<void> _loadPackageInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appName = packageInfo.appName;
      packageName = packageInfo.packageName;
      appVersion = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    });
  }

  /// Sends and email to the researcher with the name of the study + user id
  void _sendEmailToContactResearcher(String email, String subject) async {
    final url = Uri(
            scheme: 'mailto',
            path: email,
            queryParameters: {'subject': subject})
        .toString()
        .replaceAll("+", "%20");
    try {
      await launchUrl(Uri.parse(url));
    } finally {}
  }

  Future<void> _showLogoutConfirmationDialog() {
    RPLocalizations locale = RPLocalizations.of(context)!;

    return showDialog<bool>(
      context: context,
      builder: (BuildContext builderContext) {
        return AlertDialog(
          title: Text(locale.translate("pages.profile.log_out.confirmation")),
          actions: <Widget>[
            TextButton(
                child: Text(locale.translate("NO")),
                onPressed: () async {
                  if (builderContext.mounted) {
                    Navigator.of(builderContext).pop();
                  }
                }),
            TextButton(
                child: Text(locale.translate("YES")),
                onPressed: () async {
                  if (builderContext.mounted) {
                    await bloc.signOutAndLeaveStudy();
                    builderContext.pop();
                    builderContext.go(CarpStudyAppState.homeRoute);
                  }
                }),
          ],
        );
      },
    );
  }

  Future<void> _showLeaveStudyConfirmationDialog() {
    RPLocalizations locale = RPLocalizations.of(context)!;

    return showDialog<bool>(
      context: context,
      builder: (BuildContext builderContext) {
        return AlertDialog(
          title:
              Text(locale.translate("pages.profile.leave_study.confirmation")),
          actions: <Widget>[
            TextButton(
              child: Text(locale.translate("NO")),
              onPressed: () {
                if (builderContext.mounted) {
                  Navigator.of(builderContext).pop();
                }
              },
            ),
            TextButton(
                child: Text(locale.translate("YES")),
                onPressed: () async {
                  if (builderContext.mounted) {
                    await bloc.leaveStudy();
                    builderContext.pop();
                    builderContext.go(InvitationListPage.route);
                  }
                }),
          ],
        );
      },
    );
  }

  Future<void> _showEnableInternetConnectionDialog() async {
    await showDialog<bool>(
      context: context,
      builder: (BuildContext builderContext) {
        return EnableInternetConnectionDialog();
      },
    );
  }
}

class SlidePageRoute extends PageRouteBuilder<Widget> {
  final Widget page;
  SlidePageRoute(this.page)
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var begin = Offset(1.0, 0.0);
            var end = Offset.zero;
            var curve = Curves.easeInOut;
            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
        );
}
