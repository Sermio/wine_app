import 'package:equatable/equatable.dart';
import '../../models/poll_model.dart';

abstract class PollState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PollInitial extends PollState {}

class PollsLoaded extends PollState {
  final List<Poll> polls;
  PollsLoaded(this.polls);
}

class PollLoading extends PollState {}

class ActivePollsLoaded extends PollState {
  final List<Poll> polls;
  ActivePollsLoaded(this.polls);
}

class ClosedPollsLoaded extends PollState {
  final List<Poll> polls;
  ClosedPollsLoaded(this.polls);
}

class PollError extends PollState {
  final String message;
  PollError(this.message);
}
