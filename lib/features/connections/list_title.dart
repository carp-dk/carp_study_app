import 'package:flutter/material.dart';
import 'package:research_package/research_package.dart';
import 'package:carp_study_app/shared/widgets/carp_app_bar.dart';

enum ConnectionsPageTypes { phone, services, devices }

class ConnectionsPageListTitle extends StatelessWidget {
  const ConnectionsPageListTitle({super.key, required this.locale, required this.type});

  final RPLocalizations locale;
  final ConnectionsPageTypes type;

  @override
  Widget build(BuildContext context) =>
      SliverToBoxAdapter(child: CarpSectionTitle(locale.translate("pages.connections.${type.name}.title")));
}
