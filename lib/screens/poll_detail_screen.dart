import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wine_app/blocs/poll/poll_bloc.dart';
import 'package:wine_app/blocs/poll/poll_event.dart';
import '../models/poll_model.dart';
import '../blocs/poll_detail/poll_detail_bloc.dart';
import '../blocs/poll_detail/poll_detail_event.dart';
import '../blocs/poll_detail/poll_detail_state.dart';
import '../models/wine_model.dart';
import '../models/vote_model.dart';

class PollDetailScreen extends StatefulWidget {
  const PollDetailScreen({super.key});

  @override
  _PollDetailScreenState createState() => _PollDetailScreenState();
}

class _PollDetailScreenState extends State<PollDetailScreen> {
  late Poll poll;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    poll = ModalRoute.of(context)!.settings.arguments as Poll;
    final bloc = BlocProvider.of<PollDetailBloc>(context);
    bloc.add(LoadWines(poll.id));
    bloc.add(LoadVotes(poll.id));
  }

  void _showWineSelectorDialog() {
    final bloc = context.read<PollDetailBloc>();
    final state = bloc.state;

    if (state is WinesLoaded && state.wines.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: const Text('Selecciona un vino'),
            children: state.wines.map((wine) {
              return SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  _showRatingDialog(wine);
                },
                child: Text(wine.name),
              );
            }).toList(),
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay vinos disponibles para votar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showWineSelectorDialog(),
        child: Icon(Icons.add),
      ),
      appBar: AppBar(
        title: Text(poll.title),
        actions: [
          if (!poll.closed)
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                BlocProvider.of<PollBloc>(context).add(ClosePoll(poll.id));
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<PollDetailBloc, PollDetailState>(
              builder: (context, state) {
                if (state is WinesLoaded && state.wines.isNotEmpty) {
                  return ListView.builder(
                    itemCount: state.wines.length,
                    itemBuilder: (context, index) {
                      final wine = state.wines[index];
                      return ListTile(
                        leading: Image.network(wine.imageUrl),
                        title: Text(wine.name),
                        subtitle: Text('Añade tu calificación'),
                        onTap: () {
                          _showRatingDialog(wine);
                        },
                      );
                    },
                  );
                } else {
                  return Center(child: Text('No hay vinos en esta votación'));
                }
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<PollDetailBloc, PollDetailState>(
              builder: (context, state) {
                if (state is VotesLoaded && state.votes.isNotEmpty) {
                  return ListView(
                    children: state.votes.map((vote) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(vote.userPhoto),
                        ),
                        title: Text(vote.userName),
                        subtitle: Text('Votó: ${vote.rating}'),
                      );
                    }).toList(),
                  );
                } else {
                  return Center(child: Text('Esperando votos...'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(Wine wine) {
    final TextEditingController ratingController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Calificar ${wine.name}'),
        content: TextField(
          controller: ratingController,
          decoration: InputDecoration(labelText: 'Puntuación (1-10)'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () {
              int rating = int.parse(ratingController.text);
              final vote = Vote(
                id: '',
                pollId: poll.id,
                wineId: wine.id,
                userId: 'currentUserId', // ID de usuario actual
                rating: rating,
                userName: 'Nombre Usuario', // Nombre del usuario actual
                userPhoto: 'url_foto_perfil', // Foto del usuario actual
              );
              BlocProvider.of<PollDetailBloc>(context).add(VoteWine(vote));
              Navigator.pop(context);
            },
            child: Text('Votar'),
          ),
        ],
      ),
    );
  }
}
