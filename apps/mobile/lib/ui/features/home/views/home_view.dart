import 'package:flutter/material.dart';

import '../view_models/home_view_model.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mibu')),
      body: Center(
        child: ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) => Text(
            '${viewModel.counter}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: viewModel.increment,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
