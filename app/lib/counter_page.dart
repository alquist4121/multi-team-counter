import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart'; // IDを生成するためにUUIDを使う

// チームクラス
class Team {
  String id;
  String name;
  int lives;
  int maxLives;

  Team({required this.name, required this.lives, required this.maxLives})
      : id = Uuid().v4(); // ランダムなIDを生成
}

// グローバルなプロバイダ：全てのチームリストを管理
final teamsProvider = StateNotifierProvider<TeamNotifier, List<Team>>((ref) {
  return TeamNotifier();
});

// チーム状態管理クラス
class TeamNotifier extends StateNotifier<List<Team>> {
  TeamNotifier() : super([]);

  // チームを追加
  void addTeam(String name, int maxLives) {
    // 同じ名前のチームが存在するか確認
    if (name.isNotEmpty && !_doesTeamExist(name)) {
      state = [...state, Team(name: name, lives: maxLives, maxLives: maxLives)];
      state = _sortTeamsByLives(state);
    }
  }

  // チームが存在するか確認するヘルパーメソッド
  bool _doesTeamExist(String name) {
    return state.any((team) => team.name.toLowerCase() == name.toLowerCase());
  }

  // チームを削除
  void removeTeam(String id) {
    state = List.from(state)..removeWhere((team) => team.id == id);
  }

  // 残機を増やす
  void incrementLives(String id) {
    state = [
      for (final team in state)
        if (team.id == id && team.lives < team.maxLives)
          Team(name: team.name, lives: team.lives + 1, maxLives: team.maxLives)
        else
          team
    ];
    state = _sortTeamsByLives(state); // ソートを再実行
  }

  // 残機を減らす
  void decrementLives(String id) {
    state = [
      for (final team in state)
        if (team.id == id && team.lives > 0)
          Team(name: team.name, lives: team.lives - 1, maxLives: team.maxLives)
        else
          team
    ];
    state = _sortTeamsByLives(state); // ソートを再実行
  }

  // 残機数が多い順にチームをソート
  List<Team> _sortTeamsByLives(state) =>
      List.from(state)..sort((a, b) => b.lives.compareTo(a.lives));
}

class CounterPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxLivesController = TextEditingController(text: '5');
    final teamNameController = TextEditingController();
    final teams = ref.watch(teamsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Team Lives Display'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Text('Max Lives:'),
                SizedBox(width: 10),
                SizedBox(
                  width: 50,
                  child: TextField(
                    controller: maxLivesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: teamNameController,
                    decoration: InputDecoration(
                      labelText: 'Team Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    String teamName = teamNameController.text.trim();
                    int maxLives = int.tryParse(maxLivesController.text) ?? 5;

                    if (teamName.isEmpty) {
                      // チーム名が空の場合にSnackBarで警告表示
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Team name is required!')),
                      );
                    } else if (ref
                        .read(teamsProvider.notifier)
                        ._doesTeamExist(teamName)) {
                      // 同じ名前のチームが存在する場合に警告
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Team name already exists!')),
                      );
                    } else {
                      // チームを追加
                      ref
                          .read(teamsProvider.notifier)
                          .addTeam(teamName, maxLives);
                      teamNameController.clear(); // チーム名フィールドをクリア
                    }
                  },
                  child: Text('Add Team'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: teams.length,
              itemBuilder: (context, index) => TeamCounter(index: index),
            ),
          ),
        ],
      ),
    );
  }
}

class TeamCounter extends ConsumerWidget {
  final int index;

  TeamCounter({required this.index});

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
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: () {
                        ref
                            .read(teamsProvider.notifier)
                            .decrementLives(team.id);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
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
            ElevatedButton(
              onPressed: () {
                ref.read(teamsProvider.notifier).removeTeam(team.id);
              },
              child: Text('Remove Team'),
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
