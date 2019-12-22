pragma solidity ^0.4.25;

contract TransactionContract {
	
	event newSell();
	event newBuyRequireEvent(string buyerAddress);
	event newTransactionEvent(uint transactionId);  //occur when a new transaction been created.
	event newTransactionClaimEvent(uint transactionId);
	event transactionUnClaimEvent(uint transactionId);
	event deliveryCompleteEvent(uint transactionId);
	event transactionCompleteEvent(uint transactionId);
	
	uint transactionNum = 0;
	
	struct Transaction{
		string sellerAddress;
		string buyerAddress;
		string courierAddress;
		uint id;
		//can add fruit type, amount, prize, ...
	}
	
	Transaction[] public transactions;
	
	mapping (address => string) userType;
	
	
	function chooseUserType(string _type) public {  //_type = { buyer, seller, courier }
		require(!userType[msg.sender].used);  //only when the key is not exist, can choose userType
		userType[msg.sender] = _type;
	}
	
	function buyStuff() public {
		require(keccak256(userType[msg.sender]) == keccak256("buyer"));
		//pay cryptocurrency
		newBuyRequireEvent(msg.sender);
	}
	
	function createTransaction(string _buyerAddress) public {
		require(keccak256(userType[msg.sender]) == keccak256("seller"));
		transactionId = transactions.length;
		transactions.push(Transaction(msg.sender, _buyerAddress, "NULL", transactionId));
		newTransactionEvent(transactionId);  //notice couriers to deliver the commodity, and notice buyer the transaction has created.
		
	}
	
	function claimTransaction(uint transactionId) public {  //courier claim the transaction to deliver commodity.
		require(keccak256(userType[msg.sender]) == keccak256("courier"));
		require(keccak256(transactions[transactionId].courierAddress) == keccak256("NULL"));
		transactions[transactionId].courierAddress = msg.sender;
		newTransactionClaimEvent(transactionId);
	}
	
	function unclaimTransaction(uint transactionId) public {  //courier renounce the transaction
		require(keccak256(msg.sender) == keccak256(transactions[transactionId].courierAddress));
		transactions[transactionId].courierAddress = "NULL";
		transactionUnClaimEvent(transactionId);
	}
	
	function deliveryComplete(uint transactionId) public {
		require(keccak256(msg.sender) == keccak256(transactions[transactionId].courierAddress));
		deliveryCompleteEvent(transactionId);
	}
	
	function transactionComplete(uint transactionId) public {
		require(keccak256(msg.sender) == keccak256(transactions[transactionId].buyerAddress));
		//courier get some money from transaction, seller get remaining money.
		transactionCompleteEvent(transactionId);
	}
	
	
	
}