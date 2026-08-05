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
    final colors = Theme.of(context).extension<CarpColors>()!;

    return Scaffold(
      backgroundColor: colors.backgroundGray,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(locale.translate("pages.profile.title"), style: Theme.of(context).textTheme.headlineSmall!),
                  IconButton(
                    icon: Icon(Icons.close, color: Theme.of(context).colorScheme.primary, size: 28),
                    tooltip: locale.translate('Back'),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),
            if (widget.model.isAnonymous) AnonymousCard(),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  _sectionCard(colors, [
                    _fieldTile(colors, locale.translate('pages.profile.username'), widget.model.username),
                    _fieldTile(
                      colors,
                      locale.translate('pages.profile.account_id'),
                      widget.model.userId,
                      copyable: true,
                    ),
                    _fieldTile(
                      colors,
                      locale.translate('pages.profile.full_name'),
                      widget.model.isAnonymous
                          ? locale.translate('pages.about.anonymous.anonymous')
                          : widget.model.fullName,
                    ),
                    _fieldTile(
                      colors,
                      locale.translate('pages.profile.email'),
                      widget.model.isAnonymous
                          ? locale.translate('pages.about.anonymous.anonymous')
                          : widget.model.email,
                    ),
                  ]),
                  _sectionHeader(colors, 'Study'),
                  _sectionCard(colors, [
                    _fieldTile(
                      colors,
                      locale.translate('pages.profile.study_id'),
                      widget.model.studyId,
                      copyable: true,
                    ),
                    _fieldTile(
                      colors,
                      locale.translate('pages.profile.study_deployment_id'),
                      widget.model.studyDeploymentId,
                      copyable: true,
                    ),
                    _fieldTile(
                      colors,
                      locale.translate('pages.profile.study_name'),
                      locale.translate(widget.model.studyDeploymentTitle),
                      copyable: true,
                    ),
                    _fieldTile(
                      colors,
                      locale.translate('pages.profile.participant_id'),
                      widget.model.participantId,
                      copyable: true,
                    ),
                    _fieldTile(
                      colors,
                      locale.translate('pages.profile.participant_role'),
                      widget.model.participantRole,
                    ),
                    _fieldTile(colors, locale.translate('pages.profile.device_role'), widget.model.deviceRole),
                  ]),
                  _sectionHeader(colors, 'App'),
                  _sectionCard(colors, [
                    _fieldTile(colors, locale.translate('pages.profile.app_version'), appVersion),
                    _fieldTile(colors, locale.translate('pages.profile.app_version_code'), buildNumber),
                    _fieldTile(colors, locale.translate('pages.profile.server_name'), widget.model.currentServer),
                    _fieldTile(colors, locale.translate('pages.profile.device_id'), widget.model.deviceID),
                  ]),
                  const SizedBox(height: 8),
                  _actionCard(
                    colors,
                    icon: Icons.info_outline,
                    iconColor: Theme.of(context).colorScheme.primary,
                    title: locale.translate('pages.profile.study_details'),
                    hasChevron: true,
                    onTap: () => context.push(StudyAboutPage.route),
                  ),
                  const SizedBox(height: 8),
                  _actionCard(
                    colors,
                    icon: Icons.logout,
                    iconColor: Theme.of(context).extension<CarpColors>()!.error,
                    title: locale.translate('pages.profile.leave_study'),
                    onTap: _showLeaveStudyConfirmationDialog,
                  ),
                  _actionCard(
                    colors,
                    icon: Icons.power_settings_new,
                    iconColor: Theme.of(context).extension<CarpColors>()!.error,
                    title: locale.translate('pages.profile.log_out'),
                    onTap: () async {
                      bool isConnected = await widget.model.checkConnectivity();
                      if (isConnected) {
                        _showLogoutConfirmationDialog();
                      } else {
                        _showEnableInternetConnectionDialog();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(CarpColors colors, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium!),
    );
  }

  Widget _sectionCard(CarpColors colors, List<Widget> children) {
    return StudiesMaterial(
      backgroundColor: colors.grey50,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) Divider(height: 1, indent: 16, endIndent: 16, color: colors.grey200),
          ],
        ],
      ),
    );
  }

  Widget _fieldTile(CarpColors colors, String label, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall!.copyWith(color: colors.grey600)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.labelMedium!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (copyable)
            IconButton(
              icon: Icon(Icons.copy_outlined, size: 18, color: colors.grey500),
              visualDensity: VisualDensity.compact,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied')));
              },
            )
          else
            // Keeps copyable and plain rows the same height.
            const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _actionCard(
    CarpColors colors, {
    required IconData icon,
    required Color iconColor,
    required String title,
    bool hasChevron = false,
    required VoidCallback onTap,
  }) {
    return StudiesMaterial(
      backgroundColor: colors.grey50,
      margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: Theme.of(context).textTheme.labelLarge!),
              ),
              if (hasChevron) Icon(Icons.arrow_forward_ios, size: 16, color: colors.grey400),
            ],
          ),
        ),
      ),
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
              },
            ),
            TextButton(
              child: Text(locale.translate("YES")),
              onPressed: () async {
                if (builderContext.mounted) {
                  await widget.model.signOutAndLeaveStudy();
                  builderContext.pop();
                  builderContext.go(CarpAppState.homeRoute);
                }
              },
            ),
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
          title: Text(locale.translate("pages.profile.leave_study.confirmation")),
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
                  await widget.model.leaveStudy();
                  builderContext.pop();
                  builderContext.go(InvitationListPage.route);
                }
              },
            ),
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
