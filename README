Simple weekend hack project to play game of chess. Implements all rules except for repetition.

Creates empty board, adds white queen to F3 and prints the board:
```ruby
board = ' ' * 64
board[i(5,2)] = 'Q'
print_board(board)
```

Checks if F6 is attacked by any of white's pieces (spoiler alert; it is, by the queen we just placed):
```ruby
attacked?(board, i(5,5), 1)
```

Finds all possible legal moves for white's pieces and returns all pieces on board:
```ruby
moves, pieces = legal_moves(board, 1)
```

Finds en passant for black pawn:
```
board[i(1,3)] = 'P'; board[i(2,3)] = 'p'
legal_moves(board, -1, [i(1,1),i(1,3),'P'])
```

Finds both castling moves for black:
```ruby
b = ' ' * 64; b[i(0,7)] = 'r'; b[i(4,7)] = 'k'; b[i(7,7)] = 'r'; 
legal_moves(b, -1, nil, 'kq')
```

Apply a random move and undo it:
```ruby
b = ' ' * 64; b[i(4,4)] = 'N'           
move = legal_moves(b, 1, nil, 'kq').sample
p = apply_move(b, move); print_board(b); undo_move(b, move, p);
```

Display all legal moves for white of a position supplied in FEN notation:
```ruby
b, turn, castles = parse_fen('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1')
moves, _ = legal_moves(b, turn, nil, castles)
moves.each do |m|
  p = apply_move(b, m)
  print_board(b)
  undo_move(b, m, p)
end
```

Make two random players play against each other:
```ruby
board = 'RNBQKBNRPPPPPPPP' + ' '*32 + 'pppppppprnbqkbnr'
play(board, :random_player, :random_player)
```

Play against AI:
```ruby
board = 'RNBQKBNRPPPPPPPP' + ' '*32 + 'pppppppprnbqkbnr'
play(board, :human_player, :greedy_bot)
```

See `random_player`, `human_player` or `greedy_bot` for example implementations of players.