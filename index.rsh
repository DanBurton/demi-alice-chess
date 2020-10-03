'reach 0.1';

function all(arr, f) {
  return Array.reduce(Array.map(arr, f), true, and);
}

// The parameters of the game
const Params = Object({
  wager: UInt256, // currency
  delay: UInt256, // timedelta
});

const Player = UInt256;
const players = 2;
const [isPlayer, WHITE, BLACK] = makeEnum(players);

const Row = UInt256;
const rows = 8; // numbered 1 thru 8
const [isRow, ROW_1, ROW_2, ROW_3, ROW_4, ROW_5, ROW_6, ROW_7, ROW_8] = makeEnum(rows);
// Beware: row number = n + 1

const Col = UInt256;
const cols = 4; // lettered A thru D
const [isCol, COL_A, COL_B, COL_C, COL_D] = makeEnum(cols);

const Board = UInt256;
const boards = 2; // lettered A, B
const [isBoard, BOARD_A, BOARD_B] = makeEnum(boards);

const Pos = Object({
  row: Row,
  col: Col,
  board: Board,
});
function isPos(pos) {
  return isRow(pos.row) && isCol(pos.col) && isBoard(pos.board);
}

const Piece = UInt256;
const pieces = 16;
const [isPiece,
  W_KING, W_BISHOP, W_KNIGHT,  W_ROOK,
  W_PAWN1, W_PAWN2, W_PAWN3, W_PAWN4,
  B_KING, B_BISHOP, B_KNIGHT, B_ROOK,
  B_PAWN1, B_PAWN2, B_PAWN3, B_PAWN4,
] = makeEnum(pieces);

const Move = Object({
  piece: Piece,
  to: Pos,
});
function isMove(move) {
  return isPiece(move.piece) && isPos(to);
}

const PieceStatus = UInt256;
const pieceStatuses = 3;
const [isPieceStatus, ALIVE, PROMOTED, DEAD] = makeEnum(pieceStatuses);

const PPos = Object({
  pieceStatus: PieceStatus,
  pos: Pos,
});
function isPPos(ppos) {
  return isPieceStatus(ppos.pieceStatus) && isPos(ppos.pos);
}

const State = Object({
  turn: Player,
  pieces: Array(PPos, pieces),
});
function isState(state) {
  return isPlayer(state.turn) && all(state.pieces, isPPos);
}

const PlayerInterface = {
  ...hasRandom,
  getMove: Fun([State], Move),
};

const opts = {};
const parts = [
  ['Alice', {
    ...PlayerInterface,
    params: Params,
  }],
  ['Bob', {
    ...PlayerInterface,
    acceptParams: Fun([Params], Null),
  }],
];


// TODO: change Reach so that deep declassify is default
function declassifyParams(_params) {
  const wager = declassify(_params.wager);
  const delay = declassify(_params.delay);
  return {wager, delay}
}

function main_impl(Alice, Bob) {
  Alice.only(() => {
    const params = declassifyParams(interact.params);
    const _randomAlice = interact.random();
    const [_commitAlice, _saltAlice] = makeCommitment(interact, _randomAlice)
    const commitAlice = declassify(_commitAlice);
  });
  Alice.publish(params, commitAlice).pay(params.wager);
  commit();

  const {wager, delay} = params;
  function win(winner) {
    transfer(2 * wager).to(winner);
    commit();
  }

  Bob.only(() => {
    interact.acceptParams(params);
    const randomBob = declassify(interact.random());
  });
  Bob.publish(randomBob).pay(wager).timeout(delay, () => {
    Alice.publish();
    transfer(wager).to(Alice);
    commit();
    exit();
  });
  commit();

  Alice.only(() => {
    const randomAlice = declassify(_randomAlice);
    const saltAlice = declassify(_saltAlice);
  });
  Alice.publish(randomAlice, saltAlice).timeout(delay, () => {
    Bob.publish();
    transfer(wager * 2).to(Bob);
    commit();
    exit();
  });
  checkCommitment(commitAlice, saltAlice, randomAlice);
  // An arbitrary boolean based on the 2 random values provided
  const aliceIsWhite = (randomAlice % 2) == (randomBob % 2);


  function nextTurn(turn) {
    if (turn == WHITE) {
      return BLACK;
    } else {
      return WHITE;
    }
  }

  function isValidMove(move, state) {
    return true; // XXX
  }

  function validMoves(state) {
    return 0; // XXX
  }

  function isValidState(state) {
    return isState(state); // XXX
  }

  function isAliceTurn(turn) {
    return (turn == WHITE && aliceIsWhite) ||
           (turn == BLACK && !aliceIsWhite);
  }

  function getMove(interact, state) {
    const move = declassify(interact.getMove(state));
    assume(isValidMove(move, state));
    return move;
  }

  function doMove(move, state) {
    return state; // XXX
  }

  // conveniences for positions on board a
  const p = (col, row) => ({
    pieceStatus: ALIVE,
    pos: { board: BOARD_A, col, row, },
  });
  const p1 = (col) => p(col, ROW_1);
  const p2 = (col) => p(col, ROW_2);
  const p7 = (col) => p(col, ROW_7);
  const p8 = (col) => p(col, ROW_8);

  const initState = {
    turn: WHITE,
    pieces: array(PPos, [
      // W_KING, W_KNIGHT, W_BISHOP, W_ROOK,
      p1(COL_A), p1(COL_B), p1(COL_C), p1(COL_D),
      // W_PAWN1, W_PAWN2, W_PAWN3, W_PAWN4,
      p2(COL_A), p2(COL_B), p2(COL_C), p2(COL_D),
      // B_KING, B_KNIGHT, B_BISHOP, B_ROOK,
      p8(COL_A), p8(COL_B), p8(COL_C), p8(COL_D),
      // B_PAWN1, B_PAWN2, B_PAWN3, B_PAWN4,
      p7(COL_A), p7(COL_B), p7(COL_C), p7(COL_D),
    ]),
  };
  function takeTurn(state) {
    // TODO: reduce duplication
    if (isAliceTurn(state.turn)) {
      commit();
      Alice.only(() => { const move = getMove(interact, state); });
      Alice.publish(move);
      require(isValidMove(move, state));
      const newState = doMove(move, state);
      require(isValidState(newState));
      return newState;
    } else {
      commit();
      Bob.only(() => { const move = getMove(interact, state); });
      Bob.publish(move);
      require(isValidMove(move, state));
      const newState = doMove(move, state);
      require(isValidState(newState));
      return newState;
    }
  }

  var [ state ] = [ initState ];
  invariant(isState(state) && isValidState(state));
  while (validMoves(state) > 0) {
    state = takeTurn(state);
    continue;
  }
  // turn is the loser that got checkmated

  if (isAliceTurn(state.turn)) {
    win(Bob);
  } else {
    win(Alice);
  }
  exit();
}

export const main = Reach.App(opts, parts, (Alice, Bob) => {
  main_impl(Alice, Bob);
});
