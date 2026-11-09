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
        child: Text(title, style: Theme.of(context).textTheme.headlineSmall!),
      ),
    );
  }
}

/// A section heading between the cards of a page, e.g. "TASKS".
class CarpSectionTitle extends StatelessWidget {
  final String title;
  const CarpSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: Theme.of(context).textTheme.titleMedium!),
      ),
    );
  }
}

/// The logo header shared by all pages, with an optional profile button.
class CarpAppBar extends StatelessWidget {
  final bool hasProfileIcon;
  const CarpAppBar({super.key, this.hasProfileIcon = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(padding: const EdgeInsets.only(left: 8), child: SvgPicture.asset('assets/carp_logo.svg', height: 44)),
          if (hasProfileIcon)
            IconButton(
              icon: Icon(Icons.account_circle, color: Theme.of(context).primaryColor, size: 30),
              tooltip: 'Profile',
              onPressed: () => context.push(ProfilePage.route),
            ),
        ],
      ),
    );
  }
}
