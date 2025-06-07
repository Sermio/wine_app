import 'package:equatable/equatable.dart';
import '../../models/wine_model.dart';
import '../../models/vote_model.dart';

abstract class PollDetailEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadWines extends PollDetailEvent {
  final String pollId;
  LoadWines(this.pollId);
}

class LoadVotes extends PollDetailEvent {
  final String pollId;
  LoadVotes(this.pollId);
}

class AddWine extends PollDetailEvent {
  final String pollId;
  final Wine wine;
  AddWine(this.pollId, this.wine);
}

class VoteWine extends PollDetailEvent {
  final Vote vote;
  VoteWine(this.vote);
}
