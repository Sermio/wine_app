import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wine_app/models/poll_model.dart';
import 'poll_event.dart';
import 'poll_state.dart';
import '../../services/firestore_service.dart';

class PollBloc extends Bloc<PollEvent, PollState> {
  final FirestoreService _firestoreService;

  PollBloc(this._firestoreService) : super(PollInitial()) {
    on<LoadActivePolls>((event, emit) async {
      emit(PollLoading());
      try {
        _firestoreService.getActivePolls().listen((polls) {
          add(_ActivePollsUpdated(polls));
        });
      } catch (e) {
        emit(PollError('Error al cargar votaciones activas'));
      }
    });

    on<RefreshPolls>((event, emit) async {
      emit(PollLoading());
      try {
        final polls = await _firestoreService.fetchPolls();
        emit(PollsLoaded(polls));
      } catch (e) {
        emit(PollError('Error al refrescar las votaciones'));
      }
    });

    on<LoadClosedPolls>((event, emit) async {
      emit(PollLoading());
      try {
        _firestoreService.getClosedPolls().listen((polls) {
          add(_ClosedPollsUpdated(polls));
        });
      } catch (e) {
        emit(PollError('Error al cargar historial de votaciones'));
      }
    });

    on<CreatePoll>((event, emit) async {
      emit(PollLoading());
      try {
        await _firestoreService.createPoll(event.poll);
        // ✅ volver a escuchar votaciones activas
        _firestoreService.getActivePolls().listen((polls) {
          add(_ActivePollsUpdated(polls));
        });
      } catch (e) {
        emit(PollError('Error al crear votación'));
      }
    });

    on<ClosePoll>((event, emit) async {
      emit(PollLoading());
      try {
        await _firestoreService.closePoll(event.pollId);
        emit(PollInitial());
      } catch (e) {
        emit(PollError('Error al cerrar votaci\u00f3n'));
      }
    });

    on<_ActivePollsUpdated>((event, emit) {
      emit(ActivePollsLoaded(event.polls));
    });

    on<_ClosedPollsUpdated>((event, emit) {
      emit(ClosedPollsLoaded(event.polls));
    });
  }
}

// Eventos privados para manejar actualizaciones en tiempo real
class _ActivePollsUpdated extends PollEvent {
  final List<Poll> polls;
  _ActivePollsUpdated(this.polls);
}

class _ClosedPollsUpdated extends PollEvent {
  final List<Poll> polls;
  _ClosedPollsUpdated(this.polls);
}
