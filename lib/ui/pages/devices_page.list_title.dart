part of carp_study_app;

enum DevicesPageTypes { phone, services, devices }

class DevicesPageListTitle extends StatelessWidget {
  const DevicesPageListTitle({super.key, required this.locale, required this.type});

  final RPLocalizations locale;
  final DevicesPageTypes type;

  @override
  Widget build(BuildContext context) =>
      SliverToBoxAdapter(child: CarpSectionTitle(locale.translate("pages.devices.${type.name}.title")));
}
