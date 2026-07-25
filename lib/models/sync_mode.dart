/// Defines how data should be synchronized between devices.
enum SyncMode {
  /// Both devices keep their data and merge incoming changes.
  merge,

  /// Response payload for a 2-way merge.
  mergeResponse,

  /// Send local data to the peer and instruct them to overwrite their local data.
  push,

  /// Instruct the peer to send their data as a push, overwriting local data.
  pull,

  /// Acknowledgement message.
  ack,
}

