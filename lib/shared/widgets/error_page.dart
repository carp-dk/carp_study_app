import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:research_package/research_package.dart';
import 'package:carp_study_app/core/routes.dart';

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(RPLocalizations.of(context)!.translate('pages.error.title'))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(RPLocalizations.of(context)!.translate('pages.error.title'), style: TextStyle(fontSize: 18.0)),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () => context.go(Routes.root),
              child: Text(RPLocalizations.of(context)!.translate('pages.error.go_back')),
            ),
          ],
        ),
      ),
    );
  }
}
