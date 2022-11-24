pragma solidity ^0.5.0;

contract Base {
    // proxy state
    address owner;
    address implementation;    // implementation state
    address public buyer;
    //address[] public buyerList;
    uint256 public payday;

}
contract Implementation is Base {
    function buy() external payable {
        require(buyer == address(0), "Only one item to buy. Someone beat you to it!");
        require(msg.value == 1 ether, "Item price is 1 ETH");

        //buyerList.push(msg.sender); // add address buyer to list of buyer
        
        buyer = msg.sender;
        payday = now + 1 minutes;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function comfirmItemArrived() external {
        require(msg.sender == buyer,
            "Only the buyer can comfirm Item Arrived.");
        require(now >= payday,
            "You must wait until the payday time.");
        // get cashback
        msg.sender.transfer(1 ether * 0.3);
        //msg.sender.transfer(address(this).balance);
        buyer = address(0);
    }
}

contract Proxy is Base {
    constructor(address _implementation) public payable {
        owner = msg.sender;
        implementation = _implementation;
    }    
    
    function setImplementation(address _implementation) external {
        require(msg.sender == owner, 
            "Hanya pemilik kontrak yang dapat melakukan upgrade.");
        require(buyer == address(0), 
            "Transaksi sedang berlangsung tidak dapat melakukan upgrade.");
        implementation = _implementation;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function() external payable {
        address impl = implementation;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, impl, ptr,
                calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)
        
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
         }
    }
}
