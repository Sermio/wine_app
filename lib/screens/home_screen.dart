import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wine_app/blocs/auth/auth_bloc.dart';
import 'package:wine_app/blocs/auth/auth_event.dart';
import '../blocs/poll/poll_bloc.dart';
import '../blocs/poll/poll_event.dart';
import '../blocs/poll/poll_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Votaciones de Vinos'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/history');
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              // Trigger sign out
              BlocProvider.of<AuthBloc>(context).add(SignOutRequested());
            },
          ),
        ],
      ),
      body: BlocProvider(
        create: (context) => PollBloc(context.read())..add(LoadActivePolls()),
        child: BlocBuilder<PollBloc, PollState>(
          builder: (context, state) {
            if (state is PollLoading) {
              return Center(child: CircularProgressIndicator());
            } else if (state is ActivePollsLoaded) {
              return ListView.builder(
                itemCount: state.polls.length,
                itemBuilder: (context, index) {
                  final poll = state.polls[index];
                  return ListTile(
                    title: Text(poll.title),
                    subtitle: Text('Fecha: ${poll.date.toLocal()}'),
                    onTap: () {
                      Navigator.pushNamed(context, '/detail', arguments: poll);
                    },
                  );
                },
              );
            } else {
              return Center(child: Text('No hay votaciones activas'));
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.pushNamed(context, '/create_poll');
        },
      ),
    );
  }
}
