part of carp_study_app;

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Error", style: TextStyle(fontSize: 18.0)),
            const SizedBox(height: 16.0),
            ElevatedButton(onPressed: () => context.go(CarpAppState.homeRoute), child: const Text('Go back')),
          ],
        ),
      ),
    );
  }
}
