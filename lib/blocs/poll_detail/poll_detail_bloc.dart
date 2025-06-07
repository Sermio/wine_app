import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wine_app/models/vote_model.dart';
import 'package:wine_app/models/wine_model.dart';
import 'poll_detail_event.dart';
import 'poll_detail_state.dart';
import '../../services/firestore_service.dart';

class PollDetailBloc extends Bloc<PollDetailEvent, PollDetailState> {
  final FirestoreService _firestoreService;

  PollDetailBloc(this._firestoreService) : super(PollDetailInitial()) {
    on<LoadWines>((event, emit) async {
      try {
        _firestoreService.getWines(event.pollId).listen((wines) {
          add(_WinesUpdated(wines));
        });
      } catch (e) {
        emit(PollDetailError('Error al cargar vinos'));
      }
    });

    on<LoadVotes>((event, emit) async {
      try {
        _firestoreService.getVotes(event.pollId).listen((votes) {
          add(_VotesUpdated(votes));
        });
      } catch (e) {
        emit(PollDetailError('Error al cargar votos'));
      }
    });

    on<AddWine>((event, emit) async {
      try {
        await _firestoreService.addWine(event.pollId, event.wine);
      } catch (e) {
        emit(PollDetailError('Error al agregar vino'));
      }
    });

    on<VoteWine>((event, emit) async {
      try {
        await _firestoreService.submitVote(event.vote);
      } catch (e) {
        emit(PollDetailError('Error al registrar voto'));
      }
    });

    on<_WinesUpdated>((event, emit) {
      emit(WinesLoaded(event.wines));
    });

    on<_VotesUpdated>((event, emit) {
      emit(VotesLoaded(event.votes));
    });
  }
}

class _WinesUpdated extends PollDetailEvent {
  final List<Wine> wines;
  _WinesUpdated(this.wines);
}

class _VotesUpdated extends PollDetailEvent {
  final List<Vote> votes;
  _VotesUpdated(this.votes);
}
