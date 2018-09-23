pragma solidity ^0.4.24;


/*============================================================
=            HIGH RISK - GUARANTED REWARD GAME               =
==============================================================
    Rules:
    [X] Maximum 30 unique addresses per round
    [X] Round timer 10 minutes
    [X] Key price is 0.01 ether
    [X] Maximum 1,000 keys per round
    [X] Winner wins 95% of the pot, 5% goes to bankroll (creator of contract / desired address)
    [X] The more keys an address buys, the higher its chances to win the pot.
    [X] At the end of the round, a random key # will be rolled, and the specific address that owns that key will win the pot.
    [X] Created by https://github.com/0x566c6164 [X]
============================================================================================================================*/


contract PvPGame {
  using SafeMath for uint;

  /*=====================================
  =            MODIFIERS                =
  =====================================*/
  modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress]);
        _;
    }

   /*==============================
   =            EVENTS            =
   ==============================*/
   event onKeyPurchase (
        address buyer,
        uint256 amountOfKeys
    );

    event newRound (
      address winner,
      uint256 moneyPot,
      uint256 chance
    );

  /*=====================================
  =            CONFIGURABLES            =
  =====================================*/
  uint constant internal keyPrice = 0.01 ether;
  uint constant internal maxKeys = 1000;
  uint constant internal roundTimer = 10 minutes;
  uint constant internal playerLimit = 30;
  address constant internal bankRoll = 0x6cd532ffdd1ad3a57c3e7ee43dc1dca75ace901b;


   /*================================
   =            DATASETS            =
   ================================*/
   mapping(address => uint256) internal addressKeyCount;
   mapping(address => bool) internal keyOwners;
   uint256 public totalKeys = 0;
   uint256 public roundId = 0;
   uint256 public endTime;
   uint256 public moneyPot;
   uint256 public _winnerIndex;

   bool internal activated = false;

   mapping(address => bool) public administrators;


   address public previousWinner = 0x0;
   uint256 public previousPot;
   uint256 public previousPercent;

    constructor() public {
        // Set admins
        administrators[msg.sender] = true;
    }

    // Fallback function
    function() payable public {
        purchaseKey(msg.value);
    }

    function purchaseKey(uint256 _incomingEthereum) internal {
        // if 10 minutes have passed, start new round & select winner
        if (getTimeLeft() == 0) {
          nextRound();
        }

        // Checks if user sent more than 0.01 eth & less than 30 players already entered
        require(_incomingEthereum >= keyPrice && keyOwners.length < playerLimit);

        // Calculates the amount of keys bought
        uint256 _keysBought = SafeMath.div(_incomingEthereum, keyPrice);

        // Checks if user bought more keys than there are left
        if(_keysBought + totalKeys <= maxKeys) {
          //continue
          addressKeyCount[msg.sender] = addressKeyCount[msg.sender].add(_keysBought);

          moneyPot = moneyPot.add(_incomingEthereum);
          totalKeys = totalKeys.add(_keysBought);
          keyOwners[msg.sender] = true;

          emit onKeyPurchase(msg.sender, _keysBought);

        } else {
          // User bought too many keys, give him the max you can give and send him the rest of the money back
          uint freeKeys = SafeMath.sub(maxKeys, totalKeys);

          addressKeyCount[msg.sender] = addressKeyCount[msg.sender].add(freeKeys);
          // Transfer excess eth back to msg sender
          msg.sender.transfer(SafeMath.mul(SafeMath.sub(_keysBought, freeKeys), keyPrice));

          moneyPot = moneyPot.add(SafeMath.mul(freeKeys, keyPrice));
          totalKeys = totalKeys.add(freeKeys);
          emit onKeyPurchase(msg.sender, freeKeys);
          keyOwners[msg.sender] = true;
        }
    }

    function getAllOwners() public view returns(address[] _address, uint[] keys) {
        uint[] _keys;
        for( uint i = 0; i < keyOwners.length; i++) {
            _keys.push(addressKeyCount[keyOwners[i]]);
        }

        return (keyOwners, _keys);
    }

    function nextRound() private {
        //ROLL!
        _winnerIndex = random(totalKeys);

        // Get winner index inside array of addresses
        uint sumCounter = 0;
        uint keysOwned = 0;

        // prevWinner will change in case the array is bigger than 1.
        previousWinner = keyOwners[0];
        for(uint i = 0; i < keyOwners.length; i++) {
          // Run for each address, and check if he is the winner
          if (sumCounter >= addressKeyCount[keyOwners[i]]) {
            // Winner
            previousWinner = keyOwners[i];
            keysOwned = addressKeyCount[keyOwners[i]];
          } else {
            sumCounter = sumCounter.add(addressKeyCount[keyOwners[i]]);
          }
          // Clear peoples key holdings
          delete addressKeyCount[keyOwners[i]];
        }

        previousPot = SafeMath.div(SafeMath.mul(moneyPot, 95), 100);
        if(keysOwned == 0) {
            // emit 100%
            previousPercent = 100;
            emit newRound(previousWinner, previousPot, previousPercent);

        } else {
            previousPercent = (keysOwned / totalKeys) * 100;
            emit newRound(previousWinner, previousPot, previousPercent);
        }

        // Transfer money to the winner
        payWinner(previousWinner);


        // Advance round, clear key owners & total keys, reset clock
        roundId++;
        delete keyOwners;
        totalKeys = 0;
        endTime = now + roundTimer;
    }

    function payWinner(address _winnerAddress) private {
        // Winner gets 95% of the pot, other 5% goes to bankroll address
        _winnerAddress.transfer(SafeMath.div(SafeMath.mul(moneyPot, 95), 100)); // Pay 95% to WINNER
        bankRoll.transfer(SafeMath.div(SafeMath.mul(moneyPot, 5), 100)); // transfer the remaining 5%
        moneyPot = 0;
    }

    // Attack vector - this function must be replaced by an external oracle
    // or off-chain server-sided logic.
    function random () public view returns (uint256) {
        return uint8(uint256(keccak256(block.timestamp, block.difficulty)) % totalKeys); // Modulate by amount of addreses in keyOwners
    }

    function getTimeLeft() public view returns(uint256) {
        if ((endTime - now) < endTime) {
            return (endTime - now);
        } else return (0);
    }

     // In case one of us dies, we need to replace ourselves.
    function setAdministrator(address _identifier, bool _status) onlyAdministrator() public {
        administrators[_identifier] = _status;
    }

    function activate() public onlyAdministrator {
      require(!activated);
      roundId++;
      endTime = now + roundTimer;
      activated = true;
    }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
