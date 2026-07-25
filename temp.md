feat: added mobile scanner ability for p2p sharing

IMPORTANT

Known follow-on items not addressed in this session:

STUN-only WebRTC won't reliably traverse symmetric NAT/cellular — TURN needed for cross-network
Transactions use local SQLite autoincrement IDs as sync IDs — UUID/origin needed for multi-device
Deleted transactions excluded from sync export
Full transaction set in one DataChannel message — chunking needed for large datasets


note:
- this p2p should work on both android and windows that is cross platform
- the database sync includes images too so it must handle large amount of data via sync
- make debug show all scenario error might happen at for easy detection