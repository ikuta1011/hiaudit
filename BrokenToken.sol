contract BrokenToken {
  mapping(address => uint) public balanceOf;
  uint public totalSupply;

  function deposit(uint amount) {
    balanceOf[msg.sender] += amount;
    totalSupply += amount;
  }

  function transfer(address to, uint value) {
    if (balanceOf[msg.sender] >= value) {
      balanceOf[to] += value;
      balanceOf[msg.sender] -= value;
    }
  }

  function withdraw() {
    uint balance = balanceOf[msg.sender];
    if (msg.sender.call.value(balance)()) {
      balanceOf[msg.sender] = 0;
      totalSupply -= balance;
    }
  }
}
