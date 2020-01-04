pragma solidity >=0.5.0 <0.6.0;

import "./Ownable.sol";

contract TransactionContract is Ownable {
	event newSell();
	event newBuyRequireEvent(address buyerAddress);
	event newTransactionEvent(uint transactionId);
	event newTransactionClaimEvent(uint transactionId);
	event transactionUnClaimEvent(uint transactionId);
	event deliveryCompleteEvent(uint transactionId);
	event transactionCompleteEvent(uint transactionId);
	event confirmReceivedEvent(uint transactionId);
	event showTransactionInfoEvent(uint transactionId);

	string[4] public productName = [ 'apple', 'banana', 'cranberry', 'grape' ];
    uint[4] public productPrice = [ 300000000, 250000000, 500000000, 700000000 ];

	// save all transactions
	mapping (uint => Transaction) transactions;
	uint[] transactionIdList;
	// Transaction[] public transactions;
	// mapping (address => uType) userType;
	// enum uType { Initial, Buyer, Seller, Courier }

	// 建立訂單、付款、出貨、收貨、完成訂單、異常鎖定
	enum transactionState { Created, Selected, Purchase, Shippment, Received, Confirmed, Locked }
	struct Transaction{
    	transactionState state;
		address sellerAddress;
		address buyerAddress;
		address courierAddress;
		uint id;
		uint[4] items;
		uint totalAmount;
		// uint price;
		// string buyProduct;
		// can add another fruit type, amount, prize, ...
	}

	modifier inState(uint transactionId, transactionState _state) {
		require(transactions[transactionId].state == _state, "Invalid state!");
		_;
    }
	modifier onlyBuyer(uint _id) {
		require(isBuyer(_id),	"Buyer only!");
		_;
	}
	modifier onlySeller(uint _id) {
		require(isSeller(_id), "Seller only!");
		_;
	}
	modifier onlyCourier(uint _id) {
		require(isCourier(_id), "Courier only!");
		_;
	}
	modifier onlyRelationship(uint _id) {
		require(isRelationship(_id), "Relationship only!");
		_;
	}

	function isSeller(uint _id) public view returns (bool) {
		return transactions[_id].sellerAddress == msg.sender;
	}
	function isBuyer(uint _id) public view returns (bool) {
		return transactions[_id].buyerAddress == msg.sender;
	}
	function isCourier(uint _id) public view returns (bool) {
		return transactions[_id].courierAddress == msg.sender;
	}
	function isRelationship(uint _id) public view returns (bool) {
		return isSeller(_id) || isBuyer(_id) || isCourier(_id);
	}

	// only owner can call these function
	function setSellerAddress(uint _id, address _address) external onlyOwner {
		transactions[_id].sellerAddress = _address;
	}
	function setBuyerAddress(uint _id, address _address) external onlyOwner {
		transactions[_id].buyerAddress = _address;
	}
	function setCourierAddress(uint _id, address _address) external onlyOwner {
		transactions[_id].courierAddress = _address;
	}
	function setTransactionState(uint _id, uint _state) external onlyOwner {
		transactions[_id].state = transactionState(_state);
	}
	function showTransactionInfo(uint _id) public onlyRelationship(_id)
		returns (transactionState, address, address, address, uint[4] memory, uint) {
		emit showTransactionInfoEvent(_id);
		return (transactions[_id].state, transactions[_id].sellerAddress, transactions[_id].buyerAddress,
			transactions[_id].courierAddress, transactions[_id].items, transactions[_id].totalAmount);
	}

	// buyer must remember the transaction ID
	function createTransaction(uint _transactionId, address _buyerAddress) public
		returns (uint) {
		require(transactions[_transactionId].id == 0, "Transaction ID exist!");
		transactions[_transactionId].id = _transactionId;
		transactions[_transactionId].state = transactionState.Created;
		transactions[_transactionId].sellerAddress = msg.sender;
		transactions[_transactionId].buyerAddress = _buyerAddress;
		// notice couriers to deliver the commodity, and notice buyer the transaction has created.
		emit newTransactionEvent(_transactionId);
	}

	function buyStuff(uint _transactionId, uint[] memory productAmount) public
		onlyBuyer(_transactionId) returns (uint) {
		uint total = 0;
		for(uint i = 0; i < 4; i++) {
			transactions[_transactionId].items[i] = productAmount[i];
			total += productAmount[i] * productPrice[i];
		}
		transactions[_transactionId].totalAmount = total;
		transactions[_transactionId].state = transactionState.Selected;
		emit newBuyRequireEvent(msg.sender);
		return total;
	}

	// purchase function are wrote by the following four part and some new varity are added:
	function confirmPurchase(uint _transactionId) public
		inState(_transactionId, transactionState.Selected) payable {
		uint price = transactions[_transactionId].totalAmount;
		require(msg.sender.balance > price, "balance not enough!");
		
		transactions[_transactionId].state = transactionState.Purchase;
	}

	// courier claim the transaction to deliver commodity.
	function claimTransaction(uint _transactionId) public {
		require(transactions[_transactionId].courierAddress == address(0), "courier exist!");
		transactions[_transactionId].courierAddress = msg.sender;
		transactions[_transactionId].state = transactionState.Shippment;
		emit newTransactionClaimEvent(_transactionId);
	}

 	// courier renounce the transaction
	function unclaimTransaction(uint _transactionId) public
		onlyCourier(_transactionId) {
		transactions[_transactionId].courierAddress = address(0);
		emit transactionUnClaimEvent(_transactionId);
	}

	function deliveryComplete(uint _transactionId) public
		onlyCourier(_transactionId)
		inState(_transactionId, transactionState.Shippment) {
		transactions[_transactionId].state = transactionState.Received;
		emit deliveryCompleteEvent(_transactionId);
	}

	// buyer received the commodity and confirm this transaction.
	function confirmReceived(uint _transactionId) public
		onlyBuyer(_transactionId)
		inState(_transactionId, transactionState.Received) {
		transactions[_transactionId].state = transactionState.Confirmed;
		emit confirmReceivedEvent(_transactionId);
		transactionComplete(_transactionId);
	}

	// courier get some money from transaction, seller get remaining money.
	function transactionComplete(uint _transactionId) public
		onlyBuyer(_transactionId)
		inState(_transactionId, transactionState.Confirmed) payable {
		uint totalAmount = transactions[_transactionId].totalAmount;
		uint shipCost = totalAmount / 50;
		totalAmount -= shipCost;
		address payable seller = address(uint160(transactions[_transactionId].sellerAddress));
		address payable courier = address(uint160(transactions[_transactionId].courierAddress));
		seller.transfer(totalAmount);
		courier.transfer(shipCost);
		emit transactionCompleteEvent(_transactionId);
	}
}
