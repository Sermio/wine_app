import 'package:equatable/equatable.dart';
import 'package:wine_app/models/wine_model.dart';
import '../../models/poll_model.dart';

abstract class PollEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadActivePolls extends PollEvent {}

class LoadClosedPolls extends PollEvent {}

class RefreshPolls extends PollEvent {}

class CreatePoll extends PollEvent {
  final Poll poll;
  CreatePoll(this.poll);
}

class CreatePollWithWines extends PollEvent {
  final Poll poll;
  final List<Wine> wines;
  CreatePollWithWines(this.poll, this.wines);
}

class ClosePoll extends PollEvent {
  final String pollId;
  ClosePoll(this.pollId);
}
