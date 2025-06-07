import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/poll/poll_bloc.dart';
import '../blocs/poll/poll_event.dart';
import '../blocs/poll/poll_state.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Historial de Votaciones')),
      body: BlocProvider(
        create: (context) => PollBloc(context.read())..add(LoadClosedPolls()),
        child: BlocBuilder<PollBloc, PollState>(
          builder: (context, state) {
            if (state is PollLoading) {
              return Center(child: CircularProgressIndicator());
            } else if (state is ClosedPollsLoaded) {
              return ListView.builder(
                itemCount: state.polls.length,
                itemBuilder: (context, index) {
                  final poll = state.polls[index];
                  return ListTile(
                    title: Text(poll.title),
                    subtitle: Text('Fecha: ${poll.date.toLocal()}'),
                    onTap: () {
                      // Ir a detalles o resultados
                    },
                  );
                },
              );
            } else {
              return Center(child: Text('No hay votaciones cerradas'));
            }
          },
        ),
      ),
    );
  }
}
