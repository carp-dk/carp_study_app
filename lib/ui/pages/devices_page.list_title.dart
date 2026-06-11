part of carp_study_app;

enum DevicesPageTypes {
  phone,
  services,
  devices,
}

class DevicesPageListTitle extends StatelessWidget {
  const DevicesPageListTitle({
    super.key,
    required this.locale,
    required this.type,
  });

  final RPLocalizations locale;
  final DevicesPageTypes type;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        child: Text(locale.translate("pages.devices.${type.name}.title").toUpperCase(),
            style: fs16fw400ls1.copyWith(
                color: Theme.of(context).extension<CarpColors>()!.grey900, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
