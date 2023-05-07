class MoveInfo {
  final String move;
  final String bestMove;
  final int evaluation;

  MoveInfo(this.move, this.bestMove, this.evaluation);

  @override
  String toString() {
    return '{ move: "$move", bestMove: "$bestMove", evaluation: $evaluation }';
  }
}
