pragma solidity ^0.4.25;

contract Transaction {
	
	mapping (address => string) userType;
	
	function _chooseUserType(string _type) public {  //_type = { buyer, seller, courier }
		require(!userType[msg.sender].used);  //only when the key is not exist can choose userType
		userType[msg.sender] = _type;
	}
	
	
	
	function _something() {
		require(keccak256(userType[msg.sender]) == keccak256(seller));  //check userType
		//something
	}
	
}