sealed class AiStreamEvent {
  const AiStreamEvent();
}

final class AiDeltaEvent extends AiStreamEvent {
  const AiDeltaEvent(this.delta);

  final String delta;
}

final class AiDoneEvent extends AiStreamEvent {
  const AiDoneEvent(this.finishReason);

  final String? finishReason;
}

final class AiErrorEvent extends AiStreamEvent {
  const AiErrorEvent(this.message);

  final String message;
}
