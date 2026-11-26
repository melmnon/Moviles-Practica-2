import 'package:flutter/material.dart';
import 'package:fludoku/fludoku.dart';

class SudokuScreen extends StatefulWidget {
  const SudokuScreen({super.key});

  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  //dificultad actual (hay normal y difícil)
  PuzzleDifficulty _difficulty = PuzzleDifficulty.medium;

  //tablero inicial de la partida actual (para poder reiniciar sin cambiar de tablero)
  late List<List<int>> _initialBoard;

  //copia editable del tablero para poder jugar
  late List<List<int>> _board;

  //marca las casillas que vienen de inicio y no se pueden editar
  late List<List<bool>> _isFixed;

  //solución del tablero calculada por fludoku (para detectar victoria)
  List<List<int>>? _solutionBoard;

  //guardan la fila y columna con la que el jugador interactúa
  int? _selectedRow;
  int? _selectedCol;

  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _generateNewGame();
  }

  //lee un valor del tablero y convierte null a 0
  int _readCell(Board board, int row, int col) {
    return board.getAt(row: row, col: col) ?? 0;
  }

  List<List<int>> _boardToMatrix(Board board) {
    return List.generate(
      9,
          (r) => List.generate(9, (c) => _readCell(board, r, c)),
    );
  }

  void _generateNewGame() {
    final (puzzle, _) = generateSudokuPuzzle(
      level: _difficulty,
      dimension: 9,
    );

    if (puzzle != null) {
      _initialBoard = _boardToMatrix(puzzle);

      final solutions = findSolutions(puzzle);
      if (solutions.isNotEmpty) {
        _solutionBoard = _boardToMatrix(solutions.first);
      } else {
        _solutionBoard = null;
      }
    } else {
      //por si acaso generateSudokuPuzzle devuelve null se ejecutaría esto
      _initialBoard = [
        [5, 3, 0, 0, 7, 0, 0, 0, 0],
        [6, 0, 0, 1, 9, 5, 0, 0, 0],
        [0, 9, 8, 0, 0, 0, 0, 6, 0],
        [8, 0, 0, 0, 6, 0, 0, 0, 3],
        [4, 0, 0, 8, 0, 3, 0, 0, 1],
        [7, 0, 0, 0, 2, 0, 0, 0, 6],
        [0, 6, 0, 0, 0, 0, 2, 8, 0],
        [0, 0, 0, 4, 1, 9, 0, 0, 5],
        [0, 0, 0, 0, 8, 0, 0, 7, 9],
      ];
      _solutionBoard = null;
    }

    setState(() {
      _loadPuzzleFromMatrix(_initialBoard);
    });
  }

  void _loadPuzzleFromMatrix(List<List<int>> source) {
    _board = List.generate(9, (r) => List<int>.from(source[r]));
    _isFixed = List.generate(
      9,
          (r) => List<bool>.generate(9, (c) => source[r][c] != 0),
    );
    _selectedRow = null;
    _selectedCol = null;
    _isCompleted = false;
  }

  void _selectCell(int row, int col) {
    setState(() {
      _selectedRow = row;
      _selectedCol = col;
    });
  }

  void _setNumber(int value) {
    final r = _selectedRow;
    final c = _selectedCol;
    if (r == null || c == null) return;
    if (_isFixed[r][c]) return; //no se pueden modificar casillas pista

    setState(() {
      _board[r][c] = value;
      _isCompleted = _checkIfCompleted();
    });
  }

  void _resetBoard() {
    setState(() {
      _loadPuzzleFromMatrix(_initialBoard);
    });
  }

  void _changeDifficulty(PuzzleDifficulty newDifficulty) {
    if (_difficulty == newDifficulty) return;
    _difficulty = newDifficulty;
    _generateNewGame();
  }

  //comprueba si el número puesto por el jugador coincide con la solución
  bool _isWrongMove(int row, int col) {
    final value = _board[row][col];
    if (value == 0 || _isFixed[row][col]) return false;
    if (_solutionBoard == null) return false;
    return _solutionBoard![row][col] != value;
  }

  bool _checkIfCompleted() {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (_board[r][c] == 0) return false;
        if (_solutionBoard != null && _solutionBoard![r][c] != _board[r][c]) {
          return false;
        }
      }
    }
    return true;
  }

  Color _getCellColor(int row, int col, ColorScheme scheme) {
    final isSelected = row == _selectedRow && col == _selectedCol;
    if (isSelected) {
      return scheme.primaryContainer;
    }

    final isSameRowOrCol = row == _selectedRow || col == _selectedCol;
    final isSameBox = _selectedRow != null &&
        _selectedCol != null &&
        (row ~/ 3) == (_selectedRow! ~/ 3) &&
        (col ~/ 3) == (_selectedCol! ~/ 3);

    if (isSameRowOrCol || isSameBox) {
      return scheme.primaryContainer.withValues(alpha: 0.3);
    }

    return scheme.surface;
  }

  Border _getCellBorder(int row, int col, ColorScheme scheme) {
    const thin = 0.7;
    const thick = 2.2;
    final borderColor = scheme.outlineVariant;
    final boxBorderColor = scheme.onSurface;

    return Border(
      top: BorderSide(
        width: row == 0 ? thick : (row % 3 == 0 ? thick : thin),
        color: (row == 0 || row % 3 == 0) ? boxBorderColor : borderColor,
      ),
      left: BorderSide(
        width: col == 0 ? thick : (col % 3 == 0 ? thick : thin),
        color: (col == 0 || col % 3 == 0) ? boxBorderColor : borderColor,
      ),
      right: BorderSide(
        width: col == 8 ? thick : thin,
        color: col == 8 ? boxBorderColor : borderColor,
      ),
      bottom: BorderSide(
        width: row == 8 ? thick : thin,
        color: row == 8 ? boxBorderColor : borderColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final difficultyLabel =
    _difficulty == PuzzleDifficulty.medium ? 'Normal' : 'Difícil';

    return Scaffold(
      appBar: AppBar(
        title: Text('Sudoku - $difficultyLabel'),
        actions: [
          IconButton(
            onPressed: _generateNewGame,
            tooltip: 'Nuevo tablero',
            icon: const Icon(Icons.autorenew),
          ),
          IconButton(
            onPressed: _resetBoard,
            tooltip: 'Reiniciar tablero',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              //seleccionar de dificultad
              SegmentedButton<PuzzleDifficulty>(
                segments: const [
                  ButtonSegment(
                    value: PuzzleDifficulty.medium,
                    label: Text('Normal'),
                  ),
                  ButtonSegment(
                    value: PuzzleDifficulty.hard,
                    label: Text('Difícil'),
                  ),
                ],
                selected: {_difficulty},
                onSelectionChanged: (selection) {
                  _changeDifficulty(selection.first);
                },
              ),
              const SizedBox(height: 8),
              if (_isCompleted)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '¡Sudoku completado correctamente!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 81,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 9,
                  ),
                  itemBuilder: (context, index) {
                    final row = index ~/ 9;
                    final col = index % 9;
                    final value = _board[row][col];
                    final fixed = _isFixed[row][col];
                    final wrong = _isWrongMove(row, col);

                    Color textColor;
                    if (fixed) {
                      textColor = colorScheme.onSurface;
                    } else if (wrong) {
                      textColor = colorScheme.error;
                    } else {
                      textColor = colorScheme.primary;
                    }

                    return GestureDetector(
                      onTap: () => _selectCell(row, col),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _getCellColor(row, col, colorScheme),
                          border: _getCellBorder(row, col, colorScheme),
                        ),
                        child: Text(
                          value == 0 ? '' : '$value',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: fixed ? FontWeight.bold : FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              _buildNumberPad(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad(ColorScheme colorScheme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(9, (index) {
            final number = index + 1;
            return SizedBox(
              width: 36,
              height: 46,
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _setNumber(number),
                child: Text(
                  '$number',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _setNumber(0),
            icon: const Icon(Icons.backspace_outlined),
            label: const Text('Borrar celda'),
          ),
        ),
      ],
    );
  }
}