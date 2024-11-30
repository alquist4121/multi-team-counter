import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:multi_team_counter/team.dart';

final teamsProvider = StateNotifierProvider<TeamNotifier, List<Team>>((ref) {
  return TeamNotifier();
});

class TeamNotifier extends StateNotifier<List<Team>> {
  TeamNotifier() : super([]) {
    _loadTeams();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _loadTeams() async {
    final snapshot = await _firestore.collection('teams').get();
    final teams = snapshot.docs.map((doc) {
      final data = doc.data();
      return Team(
        id: doc.id,
        name: data['name'],
        lives: data['lives'],
        maxLives: data['maxLives'],
      );
    }).toList();
    state = _sortTeamsByLives(teams);
  }

  Future<void> addTeam(String name, int maxLives) async {
    if (name.isNotEmpty && !doesTeamExist(name)) {
      final docRef = await _firestore.collection('teams').add({
        'name': name,
        'lives': maxLives,
        'maxLives': maxLives,
      });
      state = [
        ...state,
        Team(id: docRef.id, name: name, lives: maxLives, maxLives: maxLives)
      ];
      state = _sortTeamsByLives(state);
    }
  }

  Future<void> removeTeam(String id) async {
    await _firestore.collection('teams').doc(id).delete();
    state = List.from(state)..removeWhere((team) => team.id == id);
  }

  Future<void> incrementLives(String id) async {
    final team = state.firstWhere((team) => team.id == id);
    if (team.lives < team.maxLives) {
      final newLives = team.lives + 1;
      await _firestore.collection('teams').doc(id).update({'lives': newLives});
      state = [
        for (final team in state)
          if (team.id == id)
            Team(
                id: team.id,
                name: team.name,
                lives: newLives,
                maxLives: team.maxLives)
          else
            team
      ];
      state = _sortTeamsByLives(state);
    }
  }

  Future<void> decrementLives(String id) async {
    final team = state.firstWhere((team) => team.id == id);
    if (team.lives > 0) {
      final newLives = team.lives - 1;
      await _firestore.collection('teams').doc(id).update({'lives': newLives});
      state = [
        for (final team in state)
          if (team.id == id)
            Team(
                id: team.id,
                name: team.name,
                lives: newLives,
                maxLives: team.maxLives)
          else
            team
      ];
      state = _sortTeamsByLives(state);
    }
  }

  bool doesTeamExist(String name) {
    return state.any((team) => team.name.toLowerCase() == name.toLowerCase());
  }

  List<Team> _sortTeamsByLives(List<Team> state) =>
      List.from(state)..sort((a, b) => b.lives.compareTo(a.lives));
}
