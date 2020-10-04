import {loadStdlib} from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';

const queens = ['♕', '♛'];
const chessSymbols = [
  // W_KING, W_BISHOP, W_KNIGHT,  W_ROOK,
  '♔', '♗', '♘', '♖',
  // W_PAWN1, W_PAWN2, W_PAWN3, W_PAWN4,
  '♙', '♙', '♙', '♙',
  // B_KING, B_BISHOP, B_KNIGHT, B_ROOK,
  '♚', '♝', '♞', '♜',
  // B_PAWN1, B_PAWN2, B_PAWN3, B_PAWN4,
  '♟', '♟', '♟', '♟',
];
const pieces = 16;
function isWhitePiece(piece) {
  return piece < (pieces / 2);
}

// const [isPlayer, WHITE, BLACK] = makeEnum(players);
const WHITE = 0;
const BLACK = 1;

// const [isPieceStatus, ALIVE, PROMOTED, DEAD] = makeEnum(pieceStatuses);
const ALIVE = 0;
const PROMOTED = 1;
const DEAD = 2;

function displayPiece(piece, status) {
  if (status == PROMOTED) {
    return queens[isWhitePiece(piece) ? WHITE : BLACK];
  } else {
    return chessSymbols[piece];
  }
}

function displayTile(tile) {
  tile = tile || ' '
  return ` ${tile} |`;
}

function displayState(state) {
  const boards = 2;
  const rows = 8;
  const cols = 4;
  const toIndex = ({row, col, board}) => (
    board * (rows * cols) + row * cols + col
  );

  const abcd = '    A   B   C   D  ';
  const hr   = '  -----------------';
  const tiles = Array(boards * cols * rows).fill(null);
  for (const piece in state.pieces) {
    const ppos = state.pieces[piece];
    if (ppos.pieceStatus != DEAD) {
      tiles[toIndex(ppos.pos)] = displayPiece(piece, ppos.status);
    }
  }

  console.log();
  for (const board in Array(boards).fill(null)) {
    const lines = [];
    let line;
    for (const row in Array(rows).fill(null)) {
      line = `${parseInt(row) + 1} |`;
      for (const col in Array(cols).fill(null)) {
        const idx = toIndex({row, col, board});
        line += displayTile(tiles[idx]);
      }
      lines.unshift(hr);
      lines.unshift(line);
    }
    lines.unshift(hr);
    lines.unshift(`     Board ${board == 0 ? 'A' : 'B'}`);
    lines.push(abcd);
    lines.push('');
    lines.push('');
    console.log(lines.join('\n'));
  }
}

(async () => {
  const stdlib = await loadStdlib();
  const {
    parseCurrency, formatCurrency, standardUnit,
    newTestAccount, balanceOf,
    hasRandom,
    eq,
  } = stdlib;

  const startingBalance = parseCurrency(1);

  const alice = await newTestAccount(startingBalance);
  const bob = await newTestAccount(startingBalance);

  async function printBalances() {
    for (const [name, acc] of [['Alice', alice], ['Bob', bob]]) {
      const bal = await balanceOf(acc);
      console.log(`${name} has ${formatCurrency(bal, 4)} ${standardUnit}`);
    }
  }

  await printBalances();
  const ctcAlice = alice.deploy(backend);
  const ctcBob = bob.attach(backend, ctcAlice.getInfo());

  const getMoveFor = (who) => (state) => {
    console.log()
    displayState(state);
    throw Error(`XXX doMove`);
  }
  const playerInterfaceFor = (who) => ({
    ...hasRandom,
    getMove: getMoveFor(who),
  });

  const params = {
    delay: 100, // blocks
    wager: parseCurrency(0.1),
  }

  function acceptParams(p) {
    if (!eq(p.delay, params.delay) || !eq(p.wager, params.wager)) {
      throw Error(`Unexpected params: ${JSON.stringify(p)}`);
    }
    console.log(`Bob accepts the parameters of the game.`);
    console.log(p);
  }

  await Promise.all([
    backend.Alice(stdlib, ctcAlice, {
      ...playerInterfaceFor('Alice'),
      params,
    }),
    backend.Bob(stdlib, ctcBob, {
      ...playerInterfaceFor('Bob'),
      acceptParams,
    }),
  ]);

  await printBalances();
})();
