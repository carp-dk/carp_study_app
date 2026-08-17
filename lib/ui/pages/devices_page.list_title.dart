part of carp_study_app;

enum DevicesPageTypes { phone, services, devices }

class DevicesPageListTitle extends StatelessWidget {
  const DevicesPageListTitle({super.key, required this.locale, required this.type});

  final RPLocalizations locale;
  final DevicesPageTypes type;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        child: Text(
          locale.translate("pages.devices.${type.name}.title").toUpperCase(),
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(letterSpacing: 1).copyWith(
            color: Colors.grey.shade900,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
