import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/poll_detail/poll_detail_bloc.dart';
import '../blocs/poll_detail/poll_detail_event.dart';
import '../blocs/poll_detail/poll_detail_state.dart';
import '../models/poll_model.dart';
import '../models/vote_model.dart';
import '../models/wine_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VoteScreen extends StatefulWidget {
  final Poll poll;

  const VoteScreen({super.key, required this.poll});

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
  @override
  void initState() {
    super.initState();
    final bloc = BlocProvider.of<PollDetailBloc>(context);
    bloc.add(LoadWines(widget.poll.id));
    bloc.add(LoadVotes(widget.poll.id));
  }

  void _vote(Wine wine) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Votar: ${wine.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Puntuación (1-10)'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final rating = int.tryParse(controller.text);
              if (rating != null && rating >= 1 && rating <= 10) {
                final vote = Vote(
                  id: '',
                  pollId: widget.poll.id,
                  wineId: wine.id,
                  userId: user.uid,
                  rating: rating,
                  userName: user.displayName ?? 'Anónimo',
                  userPhoto: user.photoURL ?? '',
                );
                context.read<PollDetailBloc>().add(VoteWine(vote));
                Navigator.pop(context);
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Votación: ${widget.poll.title}')),
      body: BlocBuilder<PollDetailBloc, PollDetailState>(
        builder: (context, state) {
          if (state is WinesLoaded && state.wines.isNotEmpty) {
            return ListView.builder(
              itemCount: state.wines.length,
              itemBuilder: (_, i) {
                final wine = state.wines[i];
                return ListTile(
                  leading: Image.network(
                    wine.imageUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                  title: Text(wine.name),
                  trailing: ElevatedButton(
                    onPressed: () => _vote(wine),
                    child: const Text('Votar'),
                  ),
                );
              },
            );
          } else if (state is PollDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return const Center(child: Text('No hay vinos en esta votación.'));
          }
        },
      ),
    );
  }
}
