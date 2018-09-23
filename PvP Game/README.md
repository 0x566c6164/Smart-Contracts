# PvP Game
Rules:<br/>
[X] Maximum 30 unique addresses per round<br/>
[X] Round timer 10 minutes<br/>
[X] Key price is 0.01 ether<br/>
[X] Maximum 1,000 keys per round<br/>
[X] Winner wins 95% of the pot, 5% goes to bankroll (creator of contract / desired address)<br/>
[X] The more keys an address buys, the higher its chances to win the pot.<br/>
[X] At the end of the round, a random key # will be rolled, and the specific address that owns that key will win the pot.<br/>

## Why wasn't it launched?
It was supposed to launch on RabbitHub but the platform was discontinued and I ditched this project.<br/>
The only thing left to do with this contract is to create a secure-random generation logic, possibly by an external oracle<br/>
because the current random generation function is a possible attack vector, meaning a malicious miner could predict the number that will be rolled<br/>
even before the game itself ends.<br/>
