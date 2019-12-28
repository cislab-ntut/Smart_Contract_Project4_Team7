pragma solidity >=0.5.0 <0.6.0;

import "./Ownable.sol";

contract TransactionContract is Ownable {
	event newSell();
	event newBuyRequireEvent(address buyerAddress);
	event newTransactionEvent(uint transactionId);  //occur when a new transaction been created.
	event newTransactionClaimEvent(uint transactionId);
	event transactionUnClaimEvent(uint transactionId);
	event deliveryCompleteEvent(uint transactionId);
	event transactionCompleteEvent(uint transactionId);
	event ItemReceived();

	modifier inState(uint transactionId, State _state) {
		require(transactions[transactionId].state == _state, "Invalid state.");
		_;
    }
	modifier onlyBuyer(uint transactionId) {
		require(msg.sender == transactions[transactionId].buyerAddress,	"Only buyer can call this.");
		_;
	}

	enum uType { Initial, Buyer, Seller, Courier }
	enum State { Created, Locked, Inactive }
	struct Transaction{
		address sellerAddress;
		address buyerAddress;
		address courierAddress;
		uint id;
		uint price;
    	State state;
		//can add fruit type, amount, prize, ...
	}
	Transaction[] public transactions;
	mapping (address => uType) userType;

	// _type = { Initial, Buyer, Seller, Courier } 0 1 2 3
	function chooseUserType(uint _type) public {
		// only when the key is not exist, can choose userType
		require(userType[msg.sender] == uType(0), "userType exist!");
		userType[msg.sender] = uType(_type);
	}

	function buyStuff() public {
		require(userType[msg.sender] == uType.Buyer, "userType error!");
		// pay cryptocurrency
		emit newBuyRequireEvent(msg.sender);
	}

	function createTransaction(address _buyerAddress) public {
		require(userType[msg.sender] == uType.Seller, "userType error!");
		uint transactionId = transactions.length;
		transactions.push(Transaction(msg.sender, _buyerAddress, address(0), transactionId, 0, State.Created));
		emit newTransactionEvent(transactionId);  //notice couriers to deliver the commodity, and notice buyer the transaction has created.

	}

	function claimTransaction(uint transactionId) public {  //courier claim the transaction to deliver commodity.
		require(userType[msg.sender] == uType.Seller, "userType error!");
		require(transactions[transactionId].courierAddress == address(0), "courier exist!");
		transactions[transactionId].courierAddress = msg.sender;
		emit newTransactionClaimEvent(transactionId);
	}

	function unclaimTransaction(uint transactionId) public {  //courier renounce the transaction
		require(msg.sender == transactions[transactionId].courierAddress, "courier only!");
		transactions[transactionId].courierAddress = address(0);
		emit transactionUnClaimEvent(transactionId);
	}

	function deliveryComplete(uint transactionId) public {
		require(msg.sender == transactions[transactionId].courierAddress, "courier only!");
		emit deliveryCompleteEvent(transactionId);
	}

	function transactionComplete(uint transactionId) public onlyBuyer(transactionId) {
		require(msg.sender == transactions[transactionId].buyerAddress, "");
		//courier get some money from transaction, seller get remaining money.
		emit transactionCompleteEvent(transactionId);
	}

	// purchase function are wrote by the following four part and some new varity are added:
	function confirmPurchase(uint transactionId, uint price) public inState(transactionId, State.Created) {
		require(msg.sender.balance > price, "balance not enough!");
		transactions[transactionId].buyerAddress = msg.sender;
		transactions[transactionId].state = State.Locked;
	}

	function confirmReceived(uint transactionId, uint price) public onlyBuyer(transactionId) inState(transactionId, State.Locked) {
		emit ItemReceived();
		address payable buyer = address(uint160(transactions[transactionId].buyerAddress));
		address payable seller = address(uint160(transactions[transactionId].sellerAddress));
		transactions[transactionId].state = State.Inactive;
		buyer.transfer(price);
		seller.transfer(address(this).balance);
	}
}
