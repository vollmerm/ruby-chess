BL = 0 # blank
WP = 1 # white pawn
WR = 2 # white rook
WN = 3 # white knight
WB = 4 # white bishop
WQ = 5 # white queen
WK = 6 # white king
# skipping 7 
# piece % 7 will yield uncolored type
BP = 8 # black pawn
BR = 9 # black rook
BN = 10 # black knight
BB = 11 # black bishop
BQ = 12 # black queen
BK = 13 # black king

# some constants for high and low score bounds
LOBOUND = -9999
HIBOUND = 9999

# how long to keep the IDS loop going
TIMELIMIT = 3

# piece weights (Shannon, 1949)
# these are how much each piece is "worth" to the computer
# the position in the array corresponds to the piece
# numbers above (white rook is 2, and WEIGHTS[2] == 5)
WEIGHTS = [0, 1, 5, 3, 3, 9, 200, 0, -1, -5, -3, -3, -9, -200]

# names of each piece for when the board is printed
NAMES = ['-', 'p', 'r', 'n', 'b', 'q', 'k', ' ', 'P', 'R', 'N', 'B', 'Q', 'K']

# this should be self-explanatory
INITIALBOARD = [[BR, BN, BB, BQ, BK, BB, BN, BR],
                [BP, BP, BP, BP, BP, BP, BP, BP],
                [BL, BL, BL, BL, BL, BL, BL, BL],
                [BL, BL, BL, BL, BL, BL, BL, BL],
                [BL, BL, BL, BL, BL, BL, BL, BL],
                [BL, BL, BL, BL, BL, BL, BL, BL],
                [WP, WP, WP, WP, WP, WP, WP, WP],
                [WR, WN, WB, WQ, WK, WB, WN, WR]]

# all the functions reference this mutable variable
# it represents the current board state in the search
@board = INITIALBOARD.map{|e| e.dup}

# return the heuristic evaluation of the current board state
def evaluate(color)
  score = 0
  # sum up the weights of the pieces
  @board.each do |row|
    row.each do |piece|
      score += WEIGHTS[piece]
    end
  end
  # netagte the score if it's from black's perspective
  if color == :white
    score
  else 
    -score
  end
end

# print out the current board
def print_board
  @board.each do |row|
    str = ""
    row.each do |piece|
      str += NAMES[piece] + ' '
    end
    puts str
  end
end

# detect if a coordinate pair (i, j) is off the board
def off_board(i, j)
  i < 0 or i > 7 or j < 0 or j > 7
end

# return the color of the piece at (i, j)
# white and black are represented by :white and :black
# if it's blank, return :blank
# if it's off the board, return :off
def color_of(i, j)
  return :off if off_board(i, j)
  piece = @board[i][j]
  if piece == BL
    :blank
  elsif piece < 7
    :white
  else
    :black
  end
end

# is a spot blank? ie. there's no piece there
def blank?(i, j)
  color_of(i, j) == :blank
end

# is there a white piece at this spot?
def white?(i, j)
  color_of(i, j) == :white
end

# is there a black piece at this spot?
def black?(i, j)
  color_of(i, j) == :black
end

# remove moves that jump off the board or attempt to
# capture same-color pieces
def remove_invalid(moves, color)
  moves.find_all do |move|
    i = move[0]
    j = move[1]
    piece_color = color_of(i, j)
    piece_color != color and piece_color != :off
  end
end

# add the starting location to moves
# so, it was [to_i, to_j], and now it's [from_i, from_j, to_i, to_j]
def add_starting_position(moves, i, j)
  moves.map do |move|
    [i, j]  + move
  end
end

# generate moves for the king
def king_moves(color, i, j)
  [[i+1, j+1],
   [i+1, j],
   [i+1, j-1],
   [i-1, j+1],
   [i-1, j],
   [i-1, j-1],
   [i, j+1],
   [i, j-1]]
end

# generate moves for the knight
def knight_moves(color, i, j)
  [[i+1, j+2],
   [i+2, j+1],
   [i+1, j-2],
   [i+2, j-1],
   [i-1, j-2],
   [i-2, j-1],
   [i-1, j+2],
   [i-2, j+1]]
end

# generate moves for the pawn
def pawn_moves(color, i, j)
  moves = []
  if color == :white
    # pawns can move up if it's unoccupied
    moves.push([i-1, j]) if blank?(i-1, j)
    # pawns can move up two spaces if they're in their starting positino
    moves.push([i-2, j]) if i == 6 and blank?(i-2, j)
    # pawns can capture diagonally
    moves.push([i-1, j+1]) if black?(i-1, j+1)
    moves.push([i-1, j-1]) if black?(i-1, j-1)
  else
    # same as above, but for black
    moves.push([i+1, j]) if blank?(i+1, j)
    moves.push([i+2, j]) if i == i and blank?(i+2, j)
    moves.push([i+1, j+1]) if white?(i+1, j+1)
    moves.push([i+1, j-1]) if white?(i+1, j-1)
  end
  moves
end

# generate moves for the rook
def rook_moves(color, i, j)
  moves = []
  # 4 loops for 4 directions
  (i+1).upto(7) do |m_i|
    moves.push([m_i, j])
    # stop if we hit a non-blank square
    break unless blank?(m_i, j)
  end
  (i-1).downto(0) do |m_i|
    moves.push([m_i, j])
    break unless blank?(m_i, j)
  end
  (j+1).upto(7) do |m_j|
    moves.push([i, m_j])
    break unless blank?(i, m_j)
  end
  (j-1).downto(0) do |m_j|
    moves.push([i, m_j])
    break unless blank?(i, m_j)
  end
  moves
end

# generate moves for the bishop
def bishop_moves(color, i, j)
  moves = []
  # moving diagonally is tricky
  # 4 loops for 4 directions
  m_i = i+1
  m_j = j+1
  while m_i <= 7 and m_j <= 7
    moves.push([m_i, m_j])
    break unless blank?(m_i, m_j)
    m_i += 1
    m_j += 1
  end
  m_i = i-1
  m_j = j+1
  while m_i >= 0 and m_j <= 7
    moves.push([m_i, m_j])
    break unless blank?(m_i, m_j)
    m_i -= 1
    m_j += 1
  end
  m_i = i-1
  m_j = j-1
  while m_i >= 0 and m_j >= 0
    moves.push([m_i, m_j])
    break unless blank?(m_i, m_j)
    m_i -= 1
    m_j -= 1
  end
  m_i = i+1
  m_j = j-1
  while m_i <= 7 and m_j >= 0
    moves.push([m_i, m_j])
    break unless blank?(m_i, m_j)
    m_i += 1
    m_j -= 1
  end
  moves
end

# generate moves for the queen
def queen_moves(color, i, j)
  # easy!
  rook_moves(color, i, j) + bishop_moves(color, i, j)
end

# create the final move list by removing invalid moves and adding
# in the starting position for each move
def actual_moves(color, moves, i, j)
  add_starting_position(remove_invalid(moves, color), i, j)
end

# generate all moves for a certain color
def generate_moves(color)
  moves = []
  0.upto(7) do |i|
    0.upto(7) do |j|
      # loop through board pieces
      if color_of(i, j) == color
        # get piece type by modding by 7
        # so 8 becomes 1 (BP -> WP), etc
        piece_type = @board[i][j] % 7
        gen_moves = case piece_type
                    when WP
                      pawn_moves(color, i, j)
                    when WR
                      rook_moves(color, i, j)
                    when WN
                      knight_moves(color, i, j)
                    when WB
                      bishop_moves(color, i, j)
                    when WQ
                      queen_moves(color, i, j)
                    when WK
                      king_moves(color, i, j)
                    end
        moves += actual_moves(color, gen_moves, i, j)
      end
    end
  end
  moves
end

# make a move on the board, returning whatever was in the
# square that was moved to
def make_move(move)
  from_i = move[0]
  from_j = move[1]
  to_i = move[2]
  to_j = move[3]
  from_piece = @board[from_i][from_j]
  to_piece = @board[to_i][to_j]
  @board[from_i][from_j] = BL
  @board[to_i][to_j] = from_piece
  to_piece
end

# unmake a move on the board, replacing the piece that was removed
def unmake_move(move, replaced_piece)
  from_i = move[0]
  from_j = move[1]
  to_i = move[2]
  to_j = move[3]
  moved_piece = @board[to_i][to_j]
  @board[to_i][to_j] = replaced_piece
  @board[from_i][from_j] = moved_piece
end

# get the opposite of a color
def other_color(color)
  if color == :white 
    :black
  else 
    :white
  end
end

# has the king been captured in the search?
def lost_king?(color)
  @board.none? do |row|
    row.any? do |piece|
      if color == :white
        piece == WK
      else
        piece == BK
      end
    end
  end
end

# minimize opponent's potential score
def search_min(level, alpha, beta, color)
  # if we're at our depth limit, return the heuristic evaluation
  return evaluate(color) if level == 0
  # if we lost the  king, return a very low losing score
  return HIBOUND-level if lost_king?(other_color(color))
  moves = generate_moves(other_color(color))
  moves.each do |move|
    # loop through all potential moves
    replaced_piece = make_move(move)
    # call search_max to consider response moves
    score = search_max(level-1, alpha, beta, color)
    beta = [score, beta].min
    unmake_move(move, replaced_piece)
    # if alpha passed beta, we hit a cutoff
    break if beta <= alpha
  end
  beta
end

# maximize the computer's potential score
def search_max(level, alpha, beta, color)
  # same as above, but now we're maximizing
  return evaluate(color) if level == 0
  return LOBOUND+level if lost_king?(color)
  moves = generate_moves(color)
  moves.each do |move|
    replaced_piece = make_move(move)
    score = search_min(level-1, alpha, beta, color)
    alpha = [score, alpha].max
    unmake_move(move, replaced_piece)
    break if beta <= alpha
  end
  alpha
end

# run minimax search to a specific depth
# return [best score, best move]
def depth_limited_search(level, color)
  best = LOBOUND
  moves = generate_moves(color).shuffle
  best_move = nil
  moves.each do |move|
    replaced_piece = make_move(move)
    score = search_min(level-1, LOBOUND, HIBOUND, color)
    if score > best
      best = score
      best_move = move
    end
    unmake_move(move, replaced_piece)
  end
  [best, best_move]
end

# run iterative deepening minimax search
# returns best move
def minimax(color)
  start_time = Time.now
  level = 2
  best = nil
  while Time.now - start_time < TIMELIMIT*0.5
    puts "Searching to level #{level}"
    best = depth_limited_search(level, color)
    puts "Best move at #{level}: " + move_string(best[1])
    puts "Evaluation score at #{level}: #{best[0]}"
    level += 1
  end
  puts "Best move: " + move_string(best[1])
  puts "Evaluation score: #{best[0]}"
  best[1] # return the best move
end

def move_string(move)
  str = ""
  letters = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h']
  str += letters[move[1]]
  str += "#{8-move[0]}"
  str += letters[move[3]]
  str += "#{8-move[2]}"
  str
end

def string_move(str)
  letters = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h']
  from_i = 8-Integer(str[1])
  from_j = letters.find_index(str[0])
  to_i = 8-Integer(str[3])
  to_j = letters.find_index(str[2])
  [from_i, from_j, to_i, to_j]
end

def read_player_move
  letters = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h']
  numbers = ['1', '2', '3', '4', '5', '6', '7', '8']
  inp = gets.chomp
  while (not letters.find_index(inp[0]) or not letters.find_index(inp[2]) or 
    not numbers.find_index(inp[1]) or not numbers.find_index(inp[3]))
    puts "Please enter a move (e.g. a1b2)."
    inp = gets.chomp
  end
  inp
end
    

def play
  puts "ruby-chess.rb"
  puts "v0.1a"
  puts "Mike Vollmer, 2013"
  puts "------------------"
  puts ""
  print "Should the computer go first? (y or n):"
  computer = :white
  inp = gets.chomp
  while inp != "n" and inp != "y"
    print "Please enter y or n:"
    inp = gets.chomp
  end
  if inp == "n"
    computer = :black
    print_board()
    puts "Your move!"
    print "> "
    make_move(string_move(read_player_move()))
  end
  while true
    print_board()
    puts "Computer is thinking..."
    make_move(minimax(computer))
    print_board()
    puts "Your move!"
    print "> "
    make_move(string_move(read_player_move()))
  end
end

play()
