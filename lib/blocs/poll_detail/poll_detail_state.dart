import 'package:equatable/equatable.dart';
import '../../models/wine_model.dart';
import '../../models/vote_model.dart';

abstract class PollDetailState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PollDetailInitial extends PollDetailState {}

class PollDetailLoading extends PollDetailState {}

class WinesLoaded extends PollDetailState {
  final List<Wine> wines;
  WinesLoaded(this.wines);
}

class VotesLoaded extends PollDetailState {
  final List<Vote> votes;
  VotesLoaded(this.votes);
}

class PollDetailError extends PollDetailState {
  final String message;
  PollDetailError(this.message);
}
