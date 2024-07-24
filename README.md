# chess
A chess game in Ruby, designed and built from scratch (no tutorials).

![screenshot03](https://github.com/user-attachments/assets/1e6ddf61-3fa9-4073-b07f-5ede2e0a6bdc)

Challenge undertaken as [Ruby Final Project](https://www.theodinproject.com/lessons/ruby-ruby-final-project) in The Odin Project's [Ruby Course](https://www.theodinproject.com/paths/full-stack-ruby-on-rails/courses/ruby).

## Features
### Functionality:
- [x] Two humans can play in one terminal
- [x] Moves parsed from full coordinate notation (b1c3) or minimal algebraic notation (Nc3)
- [x] Can load a game from a file
- [x] Can save a game to a file
- [x] Each move is validated for legality (including non-endangerment of own King)
- [x] All single-piece moves (including captures) are supported
- [x] Check, checkmate, and draw are recognized and enforced
- [x] Architected to support complex moves (castling, pawn promotions)
- [ ] Castling
- [ ] Pawn promotions
- [ ] Connect to a web API so human can play against a chess engine (e.g. Stockfish)
### UI/UX:
- [x] Command-line interface
- [x] Chess board as colored squares
- [x] Chess pieces as black or white unicode symbols
- [x] Instructions shown contextually
- [x] Board and input prompt fixed on screen (scrolling suppressed)
- [x] Moves animated (path highlighted)
- [x] Move history shown above board in minimal algebraic notation
- [x] Description and feature list in README
- [ ] Screenshots in README
- [ ] Place move history right of board, in columns
- [ ] Show captured pieces
- [ ] Enable options to flip board (on-demand or per-turn)
- [ ] Deploy demo using online terminal (e.g. OnlineGDB, Replit)
- [ ] Deploy demo using a GUI (e.g. Chessboard.js)
### Testing:
- [x] Improve method modularity and ordering
- [x] Distinguish public/private
- [x] Clarify what to test
- [x] Start making tests
- [ ] Continue adding tests over time
  - [ ] Add random tests using imported PGN files from actual games
