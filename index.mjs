import * as stdlib from '@reach-sh/stdlib/ETH.mjs';
import * as backend from './build/index.main.mjs';

(async () => {
  const startingBalance = stdlib.parseCurrency(100);

  const alice = await stdlib.newTestAccount(startingBalance);
  const bob = await stdlib.newTestAccount(startingBalance);

  const ctcAlice = alice.deploy(backend);
  const ctcBob = bob.attach(backend, ctcAlice.getInfo());

  await Promise.all([
    backend.Alice(stdlib, ctcAlice, {
      ...stdlib.hasRandom,
    }),
    backend.Bob(stdlib, ctcBob, {
      ...stdlib.hasRandom,
    }),
  ]);

  console.log('Hello, Alice and Bob!');
})();
