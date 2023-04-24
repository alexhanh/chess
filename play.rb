# Simple weekend hack project to play game of chess. Implements all rules except for repetition.
# Uses no classes, just pure functions. I did regret this decision later even tho the aesthetic simplicity feels nice.
# Board is simply stored as string in FEN style notation. Upcased letters = white's pieces, Downcased letters = black's pieces.
# Can play against human or against itself. Implements a random player and very simplistic bot that values material and tries to move pieces toward the enemy king.

require 'byebug'

# Convert x,y to index
def i(x, y)
  y * 8 + x
end

# Convert index to x,y
def xy(i)
  [i % 8, i / 8]
end

# Convert letter number ('E2') to index
def an_i(s)
  letter, y = s.split('')
  x = 'ABCDEFGH'.index(letter.upcase)
  (y.to_i - 1) * 8 + x
end

# Convert index to letter number
def i_an(i)
  x, y = xy(i)
  l = 'ABCDEFGH'.split('')[x]
  "#{l}#{y+1}"
end

# Returns color of piece. White = 1, Black = -1, Empty = 0
def color(p)
  return 0 if p == ' '
  'RNBKQP'.include?(p) ? 1 : -1
end

# Parses FEN position
# Example `b, turn, castles = parse_fen('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1')`
# TODO: parse en passant, halfmoves and fullmoves
def parse_fen(s)
  board, turn, castling, passing, halfmoves, fullmoves = s.split(' ')
  return board.split('/').reverse.join.split('').map { |c| c =~ /\d/ ? ' ' * c.to_i : c }.join, turn == 'w' ? 1 : -1, castling
end

# Creates FEN string for position
# TODO: implement passing, halfmoves and fullmoves
def fen(board, turn, castles=nil)
  s = ''
  7.downto(0).each do |y|
    spaces = 0
    0.upto(7).each do |x|
      u = board[i(x,y)]
      if u == ' '
        spaces += 1
      else
        if spaces > 0
          s << spaces.to_s; spaces = 0
        end
        s << u
      end
    end
    if spaces > 0
      s << spaces.to_s; spaces = 0
    end
    s << '/' if y > 0
  end
  s << ' ' << (turn == 1 ? 'w' : 'b' )
  s << ' ' << (castles && !castles.empty? ? castles : '-')
end

# Returns location of king
def find_king(board, color)
  64.times do |i|
    if board[i] == (color == 1 ? 'K' : 'k')
      return i
    end
  end
  return nil
end

# Returns 'Q' or 'q' if move is queenside castle and 'K' or 'k' for kingside. Returns nil otherwise.
def castle(move)
  from, to, unit = move
  from_x, from_y = xy(from)
  to_x, to_y = xy(to)
  if unit.upcase == 'K' && (from_x - to_x).abs == 2
    return from_x < to_x ? (unit == 'K' ? 'K' : 'k') :  (unit == 'Q' ? 'Q' : 'q')
  end
  return nil
end

# Prints board from white's perspective
# Example output of staring position next to a random game position

# rnbqkbnr        B·bqk·r·
# pppppppp        ··p··p··
# ········        p·P·····
# ········        nN·p··p·
# ········        ·p··P·n·
# ········        B·······
# PPPPPPPP        P··K··pP
# RNBQKBNR        ········

def print_board(board)
  4.times { puts }
  8.times do |y|
    print(' ' * 8)
    8.times do |x|
      p = board[i(x, 7 - y)]
      print(p == ' ' ? '·' : p)
    end
    puts
  end
  4.times { puts }
end

def print_move(move)
  from, to, unit, promo = move
  s = "#{unit}#{i_an(from)}#{i_an(to)} #{promo}"
  
  if c = castle(move)
    s += c.upcase == 'K' ? '0-0' : '0-0-0'
  end

  puts s
end

# Generates available moves as pairs ([from_square_index], [to_square_index]) into certain direction (dx/dy)
def traverse(board, from_i, dx, dy, only_one_move=false)
  x, y = xy(from_i); x += dx; y += dy
  while x < 8 && y < 8 && x >= 0 && y >= 0
    to_i = i(x, y)
    yield([from_i, to_i, board[from_i]]) if color(board[from_i]) != color(board[to_i])
    break if board[to_i] != ' ' || only_one_move
    x += dx; y += dy
  end
end

# Helper method for attacked?() to check if given square (from_i) is attacked by any units (stops)
# TODO: Mechanically similar to traverse(). Commonalities could probably be extracted.
def threat?(board, from_i, dx, dy, stops, only_one_move=false)
  x, y = xy(from_i); x += dx; y += dy
  while x < 8 && y < 8 && x >= 0 && y >= 0
    return stops.include?(board[i(x,y)]) if board[i(x,y)] != ' '
    break if only_one_move
    x += dx; y += dy;
  end
  return false
end

# Checks if given square (i) is attacked by any of color's pieces
def attacked?(board, i, color)
  # N,E,S,W - Only have to check for rooks and queens
  # NE,SE,SW,NW - Only have to check for bishops and queens
  ot = (color == 1 ? 'RQ' : 'rq' ).split('')
  dt = (color == 1 ? 'BQ' : 'bq' ).split('')
  kt = (color == 1 ? 'K' : 'k')
  nt = (color == 1 ? 'N' : 'n')
  pt = (color == 1 ? 'P' : 'p')
  threat?(board, i,  0, +1, ot) ||
  threat?(board, i,  0, -1, ot) ||
  threat?(board, i, +1,  0, ot) ||
  threat?(board, i, -1,  0, ot) ||
  threat?(board, i, +1, +1, dt) ||
  threat?(board, i, -1, -1, dt) ||
  threat?(board, i, +1, -1, dt) ||
  threat?(board, i, -1, +1, dt) ||
  [[0, +1],[+1, +1],[+1, 0],[+1, -1],[0, -1],[-1, -1],[-1, 0],[-1, +1]].any? { |d| threat?(board, i, d[0], d[1], kt, true) } || # Kings
  [[-1, +2], [+1, +2], [+2, +1], [+2, -1], [+1, -2], [-1, -2], [-2, -1], [-2, +1]].any? { |d| threat?(board, i, d[0], d[1], nt, true) } || # Knights
  (color == -1 && (threat?(board, i, -1, +1, pt, true) || threat?(board, i, +1, +1, pt, true))) || # White king and black pawns
  (color ==  1 && (threat?(board, i, -1, -1, pt, true) || threat?(board, i, +1, -1, pt, true)))    # Black king and white pawns
end

# Applies given move to board and returns the captured piece (p)
def apply_move(board, move)
  from, to, unit, promo, passing = move
  to_x, to_y = xy(to)

  p = board[to]
  board[to] = (promo || board[from])
  board[from] = ' '

  if c = castle(move)
    if c.upcase == 'K'
      board[i(5,to_y)] = board[i(7,to_y)]; board[i(7,to_y)] = ' ';
    else
      board[i(3,to_y)] = board[i(0,to_y)]; board[i(0,to_y)] = ' ';
    end
  end

  if passing
    passe_i = i(to_x, unit == 'P' ? to_y-1 : to_y+1 )
    board[passe_i] = ' ' if passing
  end

  return p
end

# Undo move given possibly captured piece (p)
def undo_move(board, move, p)
  from, to, unit, promo, passing = move
  to_x, to_y = xy(to)

  board[from] = promo ? (color(board[to]) == 1 ? 'P' : 'p') : board[to]
  board[to] = p

  if c = castle(move)
    if c.upcase == 'K'
      board[i(7,to_y)] = board[i(5,to_y)]; board[i(5,to_y)] = ' ';
    else
      board[i(0,to_y)] = board[i(3,to_y)]; board[i(3,to_y)] = ' ';
    end
  end

  if passing
    passe_i = i(to_x, unit == 'P' ? to_y-1 : to_y+1 )
    board[passe_i] = (unit == 'P' ? 'p' : 'P') if passing
  end
end

# Finds all legal moves for given board and player (1 = white, -1 = black)
# Remember to supply prev_move and castling availability (oe. "kqKQ") to be able to detect en passants and castles
def legal_moves(board, color, prev_move=nil, castles="")
  pieces = [] # All pieces left on board
  moves = []
  king_moves = []
  64.times do |from_i|
    p = board[from_i]
    next if p == ' '
    pieces << p
    next if color(p) != color

    # Rook
    if p.upcase == 'R'
      traverse(board, from_i, +1,  0) { |m| moves << m }
      traverse(board, from_i,  0, -1) { |m| moves << m }
      traverse(board, from_i, -1,  0) { |m| moves << m }
      traverse(board, from_i,  0, +1) { |m| moves << m }
    end

    # Bishop
    if p.upcase == 'B'
      traverse(board, from_i, +1, +1) { |m| moves << m }
      traverse(board, from_i, +1, -1) { |m| moves << m }
      traverse(board, from_i, -1, -1) { |m| moves << m }
      traverse(board, from_i, -1, +1) { |m| moves << m }
    end

    # Queen
    if p.upcase == 'Q'
      traverse(board, from_i, +1,  0) { |m| moves << m }
      traverse(board, from_i,  0, -1) { |m| moves << m }
      traverse(board, from_i, -1,  0) { |m| moves << m }
      traverse(board, from_i,  0, +1) { |m| moves << m }

      traverse(board, from_i, +1, +1) { |m| moves << m }
      traverse(board, from_i, +1, -1) { |m| moves << m }
      traverse(board, from_i, -1, -1) { |m| moves << m }
      traverse(board, from_i, -1, +1) { |m| moves << m }
    end

    # King
    if p.upcase == 'K'
      traverse(board, from_i, +1,  0, true) { |m| king_moves << m }
      traverse(board, from_i,  0, -1, true) { |m| king_moves << m }
      traverse(board, from_i, -1,  0, true) { |m| king_moves << m }
      traverse(board, from_i,  0, +1, true) { |m| king_moves << m }

      traverse(board, from_i, +1, +1, true) { |m| king_moves << m }
      traverse(board, from_i, +1, -1, true) { |m| king_moves << m }
      traverse(board, from_i, -1, -1, true) { |m| king_moves << m }
      traverse(board, from_i, -1, +1, true) { |m| king_moves << m }
    end

    # White castling
    # Note: Queenside castle should be available even if b8 is under threat
    if p == 'K' && (castles.include?('K') || castles.include?('Q')) && from_i == i(4,0)
      if !attacked?(board, from_i, -color)
        king_moves << [from_i, i(6,0), 'K'] if castles.include?('K') && board[i(7,0)] == 'R' && board[i(5,0)] == ' ' && board[i(6,0)] == ' ' && !attacked?(board, i(5,0), -color) && !attacked?(board, i(6,0), -color)
        king_moves << [from_i, i(2,0), 'K'] if castles.include?('Q') && board[i(0,0)] == 'R' && board[i(1,0)] == ' ' && board[i(2,0)] == ' ' && board[i(3,0)] == ' ' && !attacked?(board, i(2,0), -color) && !attacked?(board, i(3,0), -color)
      end
    end

    # Black castling
    if p == 'k' && (castles.include?('k') || castles.include?('q')) && from_i == i(4,7)
      if !attacked?(board, from_i, -color)
        king_moves << [from_i, i(6,7), 'k'] if castles.include?('k') && board[i(7,7)] == 'R' && board[i(5,7)] == ' ' && board[i(6,7)] == ' ' && !attacked?(board, i(5,7), -color) && !attacked?(board, i(6,7), -color)
        king_moves << [from_i, i(2,7), 'k'] if castles.include?('q') && board[i(0,7)] == 'R' && board[i(1,7)] == ' ' && board[i(2,7)] == ' ' && board[i(3,7)] == ' ' && !attacked?(board, i(2,7), -color) && !attacked?(board, i(3,7), -color)
      end
    end

    # Knight
    if p.upcase == 'N'
      traverse(board, from_i, -1, +2, true) { |m| moves << m }
      traverse(board, from_i, +1, +2, true) { |m| moves << m }
      traverse(board, from_i, +2, +1, true) { |m| moves << m }
      traverse(board, from_i, +2, -1, true) { |m| moves << m }

      traverse(board, from_i, +1, -2, true) { |m| moves << m }
      traverse(board, from_i, -1, -2, true) { |m| moves << m }
      traverse(board, from_i, -2, -1, true) { |m| moves << m }
      traverse(board, from_i, -2, +1, true) { |m| moves << m }
    end

    # haste (done), attack (done), direction (done), promotion (done), en passant (done)
    
    # Promotion is simply considered as 4 different moves, since pawn can be promoted to 4 different pieces

    # Pawn (white)
    if p == 'P'
      x, y = xy(from_i)

      # NOTE: `board[i(x, y + 1)]` with y=7 will produce nil, but it does seem to still work since nil != ' ', but it's not optimal to rely on this
      # Can move forward only if the squares are empty
      if board[i(x, y + 1)] == ' '
        traverse(board, from_i, 0, +1, true) { |m| xy(m[1])[1] == 7 ? 'RNBQ'.split('').each { |pp| moves << m + [pp] } : moves << m }
        traverse(board, from_i, 0, +2, true) { |m| moves << m } if y == 1 && board[i(x, y + 2)] == ' '
      end

      # Can capture only if enemy piece in diagonal squares
      traverse(board, from_i, +1, +1, true) { |m| xy(m[1])[1] == 7 ? 'RNBQ'.split('').each { |pp| moves << m + [pp] } : moves << m if color(board[m[1]]) == -1 }
      traverse(board, from_i, -1, +1, true) { |m| xy(m[1])[1] == 7 ? 'RNBQ'.split('').each { |pp| moves << m + [pp] } : moves << m if color(board[m[1]]) == -1 }

      # En passant
      if prev_move
        pf, pt, pu = prev_move
        pfx, pfy = xy(pf)
        ptx, pty = xy(pt)
        if pu == 'p' && pfy == 6 && pty == 4 && y == 4
          moves << [from_i, i(x+1, y+1), 'P', nil, true] if x == ptx - 1
          moves << [from_i, i(x-1, y+1), 'P', nil, true] if x == ptx + 1
        end
      end
    end

    # Pawn (black)
    if p == 'p'
      x, y = xy(from_i)

      # NOTE: `board[i(x, y + 1)]` with y=7 will produce nil, but it does seem to still work since nil != ' ', but it's not optimal to rely on this
      # Can move forward only if the squares are empty
      if board[i(x, y - 1)] == ' '
        traverse(board, from_i, 0, -1, true) { |m| xy(m[1])[1] == 0 ? 'rnbq'.split('').each { |pp| moves << m + [pp] } : moves << m }
        traverse(board, from_i, 0, -2, true) { |m| moves << m } if y == 6 && board[i(x, y - 2)] == ' '
      end

      # Can capture only if enemy piece in diagonal squares
      traverse(board, from_i, +1, -1, true) { |m| xy(m[1])[1] == 0 ? 'rnbq'.split('').each { |pp| moves << m + [pp] } : moves << m if color(board[m[1]]) == 1 }
      traverse(board, from_i, -1, -1, true) { |m| xy(m[1])[1] == 0 ? 'rnbq'.split('').each { |pp| moves << m + [pp] } : moves << m if color(board[m[1]]) == 1 }

      # En passant
      if prev_move
        pf, pt, pu = prev_move
        pfx, pfy = xy(pf)
        ptx, pty = xy(pt)
        if pu == 'P' && pfy == 1 && pty == 3 && y == 3
          moves << [from_i, i(x+1, y-1), 'p', nil, true] if x == ptx - 1
          moves << [from_i, i(x-1, y-1), 'p', nil, true] if x == ptx + 1
        end
      end
    end

  end

  # Final check to remove moves which would lead our king to be under attack
  final_moves = []
  (moves + king_moves).each do |move|

    p = apply_move(board, move)

    # Find our king
    king_i = find_king(board, color)

    unless king_i && attacked?(board, king_i, -color)
      final_moves << move
    end

    undo_move(board, move, p)
  end

  [final_moves, pieces]
end

# Makes two agents (p1,p2 passed as methods) play indefinitely against each other
def play(start_pos, p1, p2)
  games = 0
  p1_wins, p2_wins, draws = 0,0,0
  loop do
    board = start_pos.dup
    turn = 1
    p1_color = [-1, 1].sample # Toss coin

    prev_move = nil
    castles = 'KQkq' # Available castles
    turns = 0
    loop do
      puts "Game #{games+1}, Turn #{turns+1}"

      moves, pieces = legal_moves(board, turn, prev_move, castles)

      # Game finished
      # TODO: Not perfect, should be improved
      if moves.empty? || pieces.count == 2 || turns > 1000
        print_board(board)

        if attacked?(board, find_king(board, p1_color), -p1_color)
          p1_wins += 1
        elsif attacked?(board, find_king(board, -p1_color), p1_color)
          p2_wins += 1
        else
          draws += 1
        end
        
        puts "P1 #{p1_wins}, P2 #{p2_wins}, Draws: #{draws}"
        puts

        break
      end

      # Ask player to make a move
      move = (p1_color == turn) ? method(p1).call(board, turn, prev_move, castles) : method(p2).call(board, turn, prev_move, castles)

      # Check that the player's move is indeed legal
      unless moves.any? { |f,t,u,p| f == move[0] && t == move[1] && u == move[2] && p == move[3] }
        puts 'Illegal move'
        byebug
      end

      apply_move(board, move)

      # Update castling opportunities. Not very elegant, could be improved, but works.
      x, y = xy(move[0])
      castles = castles.delete('K').delete('Q') if move[2] == 'K'
      castles = castles.delete('K') if move[2] == 'R' && x == 7 && y == 0
      castles = castles.delete('Q') if move[2] == 'R' && x == 0 && y == 0
      castles = castles.delete('k').delete('q') if move[2] == 'k'
      castles = castles.delete('k') if move[2] == 'r' && x == 7 && y == 7
      castles = castles.delete('q') if move[2] == 'r' && x == 0 && y == 7

      prev_move = move

      turn = -turn
      turns += 1

      print_board(board)
      puts fen(board, turn, castles)
      puts
    end

    games += 1
  end
end

# Implements a player that picks a random legal move every turn
def random_player(board, turn, prev_move, castles)
  moves, pieces = legal_moves(board, turn, prev_move, castles)
  moves.sample
end

# Implements human player that asks the move via keyboard
def human_player(board, turn, prev_move, castles)
  print_board(board)
  puts fen(board, turn, castles)
  puts
  moves, pieces = legal_moves(board, turn, prev_move, castles)

  loop do
    puts "Type your move:"
    s = gets.strip
    if s =~ /^[a-h][1-8],[a-h][1-8](,[nrqbNRQB])?$/
      from, to, promo = s.strip.split(',')
      from = an_i(from)
      to = an_i(to)

      move = moves.find { |f,t,u,p| f == from && t == to && p == promo }
      if move
        return move
      else
        puts "Illegal move"
      end
    elsif s == 'm'
      moves.each { |m| print_move(m) }
    else
      puts "Check input"
    end
  end
end

# Simple bot that chooses move with maximum material advantage and also prefers to move its pieces closer to enemy king
def greedy_bot(board, turn, prev_move, castles)
  moves, pieces = legal_moves(board, turn, prev_move, castles)

  eval_moves = []
  board = board.dup # Just to be safe
  moves.each do |move|
    p = apply_move(board, move)
    
    enemy_king_i = find_king(board, -turn)

    # Found a mating move
    if legal_moves(board, -turn, move, castles).first.empty? && attacked?(board, enemy_king_i, turn)
      eval_moves << [999999, move]
      break
    else
      # Use classical weights for pieces
      white_values = { 'Q' => 9, 'R' => 5, 'N' => 3, 'B' => 3, 'P' => 1, ' ' => 0, 'K' => 0 }
      black_values = { 'q' => 9, 'r' => 5, 'n' => 3, 'b' => 3, 'p' => 1, ' ' => 0, 'k' => 0 }
      white_score = 0; black_score = 0
      total_dist = 0.0
      64.times do |i|
        u = board[i]
        white_score += (white_values[u] || 0)
        black_score += (black_values[u] || 0)

        if color(u) == turn
          ex, ey = xy(enemy_king_i)
          x, y = xy(i)

          total_dist += Math.sqrt((x-ex)**2 + (y-ey)**2)
        end
      end

      score = (turn == 1) ? white_score - black_score : black_score - white_score
      score /= 39.0

      # TODO: Although helps to make less draws, minimizing distance also incentivices to put pieces right next to enemy king to be eaten (not good)
      dist = -total_dist/1000.0

      # puts "M #{score}, D #{dist}"

      # Normalize material score and distance score into one
      eval_moves << [score + dist, move]
    end

    undo_move(board, move, p)
  end

  eval_moves.sort_by { |s,m| -s }.first[1]
end

# Classic starting position
board = 'RNBQKBNRPPPPPPPP' + (" " * 32) + 'pppppppprnbqkbnr'

# Random vs Random
# play(board, :random_player, :random_player)

# Human vs Random
# play(board, :human_player, :random_player)

# Greedy bot vs Random (yes, it does win most of the time (yay!), even tho draws surprisingly often against random mover)
play(board, :greedy_bot, :random_player)

# Human vs Greedy
# play(board, :human_player, :greedy_bot)
