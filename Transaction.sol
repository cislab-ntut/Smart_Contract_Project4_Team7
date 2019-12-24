pragma solidity ^0.4.25;

contract TransactionContract {
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

	mapping (address => string) userType;

	// _type = { buyer, seller, courier }
	function chooseUserType(string _type) public {
		// only when the key is not exist, can choose userType
		require(userType[msg.sender] == 0, "userType exist!");
		userType[msg.sender] = _type;
	}

	function buyStuff() public {
		require(keccak256(userType[msg.sender]) == keccak256("buyer"), "userType error!");
		// pay cryptocurrency
		emit newBuyRequireEvent(msg.sender);
	}

	function createTransaction(address _buyerAddress) public {
		require(keccak256(userType[msg.sender]) == keccak256("seller"), "userType error!");
		transactionId = transactions.length;
		transactions.push(Transaction(msg.sender, _buyerAddress, "0x0", transactionId));
		emit newTransactionEvent(transactionId);  //notice couriers to deliver the commodity, and notice buyer the transaction has created.

	}

	function claimTransaction(uint transactionId) public {  //courier claim the transaction to deliver commodity.
		require(keccak256(userType[msg.sender]) == keccak256("courier"), "userType error!");
		require(keccak256(transactions[transactionId].courierAddress) == keccak256("0x0"), "courier exist!");
		transactions[transactionId].courierAddress = msg.sender;
		emit newTransactionClaimEvent(transactionId);
	}

	function unclaimTransaction(uint transactionId) public {  //courier renounce the transaction
		require(msg.sender == transactions[transactionId].courierAddress, "courier only!");
		transactions[transactionId].courierAddress = "0x0";
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
		transactions[transactionId].state = State.Inactive;
		transactions[transactionId].buyerAddress.transfer(price);
		transactions[transactionId].sellerAddress.transfer(address(this).balance);
	}
}
