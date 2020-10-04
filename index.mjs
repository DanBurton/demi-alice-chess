import {loadStdlib} from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';

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
