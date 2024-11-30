import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:multi_team_counter/team_notifier.dart';

class CounterPage extends HookConsumerWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxLivesController = TextEditingController(text: '5');
    final teamNameController = TextEditingController();
    final teams = ref.watch(teamsProvider);

    final isEditMode = useState(false);

    Future<void> showPasswordDialog() async {
      final passwordController = TextEditingController();
      return showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button for close dialog!
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('運営用です'),
            content: TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  if (passwordController.text == 'jjjjj') {
                    isEditMode.value = !isEditMode.value;
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Incorrect password!')),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('残機カウンタ'),
        actions: [
          IconButton(
            icon: Icon(isEditMode.value ? Icons.edit_off : Icons.edit),
            onPressed: showPasswordDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          if (isEditMode.value)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text('Max Lives:'),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 50,
                    child: TextField(
                      controller: maxLivesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: teamNameController,
                      decoration: const InputDecoration(
                        labelText: 'Team Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      String teamName = teamNameController.text.trim();
                      int maxLives = int.tryParse(maxLivesController.text) ?? 5;
                      if (teamName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Team name is required!')),
                        );
                      } else if (ref
                          .read(teamsProvider.notifier)
                          .doesTeamExist(teamName)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Team name already exists!')),
                        );
                      } else {
                        ref
                            .read(teamsProvider.notifier)
                            .addTeam(teamName, maxLives);
                        teamNameController.clear();
                      }
                    },
                    child: const Text('Add Team'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: teams.length,
              itemBuilder: (context, index) =>
                  TeamCounter(index: index, isEditMode: isEditMode.value),
            ),
          ),
        ],
      ),
    );
  }
}

class TeamCounter extends ConsumerWidget {
  final int index;
  final bool isEditMode;
  const TeamCounter({super.key, required this.index, required this.isEditMode});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref.watch(teamsProvider)[index];
    return Card(
      color: team.lives == 0 ? Colors.grey[300] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(team.name),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${team.lives} / ${team.maxLives}'),
                if (isEditMode)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          ref
                              .read(teamsProvider.notifier)
                              .decrementLives(team.id);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          ref
                              .read(teamsProvider.notifier)
                              .incrementLives(team.id);
                        },
                      ),
                    ],
                  ),
              ],
            ),
            LinearProgressIndicator(
              value: team.lives / team.maxLives,
              color: _getBarColor(team.lives, team.maxLives),
              backgroundColor: Colors.grey[200],
            ),
            if (isEditMode)
              ElevatedButton(
                onPressed: () {
                  ref.read(teamsProvider.notifier).removeTeam(team.id);
                },
                child: const Text('Remove Team'),
              ),
          ],
        ),
      ),
    );
  }

  Color _getBarColor(int lives, int maxLives) {
    double ratio = lives / maxLives;
    if (ratio > 0.66) {
      return Colors.green;
    } else if (ratio > 0.33) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
