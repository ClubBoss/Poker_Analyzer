enum NodeCompletionStatus { notStarted, inProgress, completed }

extension NodeCompletionStatusExt on NodeCompletionStatus {
  bool get isCompleted => this == NodeCompletionStatus.completed;
}
