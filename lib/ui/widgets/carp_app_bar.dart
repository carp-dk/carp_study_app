part of carp_study_app;

/// The page title shown under the [CarpAppBar] on every shell tab, so all
/// tabs share the same title font and padding.
class CarpPageTitle extends StatelessWidget {
  final String title;
  const CarpPageTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: fs24fw700.copyWith(color: Theme.of(context).extension<CarpColors>()!.grey900)),
      ),
    );
  }
}

class CarpAppBar extends StatelessWidget {
  final bool hasProfileIcon;
  const CarpAppBar({super.key, this.hasProfileIcon = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.only(left: 8),
                    child: Image.asset('assets/carp_logo.png', fit: BoxFit.contain, height: 16),
                  ),
                  if (hasProfileIcon)
                    IconButton(
                      icon: Icon(Icons.account_circle, color: Theme.of(context).primaryColor, size: 30),
                      tooltip: 'Profile',
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).push(SlidePageRoute(ProfilePage(ProfilePageViewModel())));
                      },
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
