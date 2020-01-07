pragma solidity >=0.5.0 <0.6.0;

import "./Ownable.sol";

contract TransactionContract is Ownable {
	event destroyTransactionEvent(uint id);
	event getTransactionInfoEvent(uint id, transactionState state, address buyer, address seller, address courier, uint[4] items, uint amount);
	event newTransactionEvent(uint transactionId);
	event newBuyRequireEvent(address buyer, uint transactionId, uint[4] items, uint amount);
	event confirmPurchaseEvent(uint transactionId, uint[4] items, uint amount);
	event newTransactionClaimEvent(uint transactionId, address courier);
	event transactionUnClaimEvent(uint transactionId);
	event deliveryCompleteEvent(uint transactionId);
	event confirmReceivedEvent(uint transactionId);
	event transactionCompleteEvent(uint transactionId, uint amount, uint shipCost);
	event refoundBuyerAmountEvent(uint transactionId, address buyer, uint amount);
	event testPesticideEvent(uint transactionId);
	string[4] public productName = [ 'apple', 'banana', 'cranberry', 'grape' ];
    uint[4] public productPrice = [ 300000000, 250000000, 500000000, 700000000 ];

	// save all transactions
	//mapping (uint => Transaction) transactions;
	Transaction[] public transactions;
	mapping (address => uType) userType;
	address committee;

	enum uType { Initial, Buyer, Seller, Courier }
	// 建立訂單、付款、出貨、收貨、完成訂單、異常鎖定
	enum transactionState {Selected, Created, Purchase, Shippment, Received, Confirmed, Excepted, Locked }
	struct Transaction{
    	transactionState state;
		address sellerAddress;
		address buyerAddress;
		address courierAddress;
		uint id;
		uint[4] items;
		uint totalAmount;
	}

	modifier inState(uint transactionId, transactionState _state) {
		require(transactions[transactionId].state == _state, "Invalid state!");
		_;
    }
	modifier onlySellers() {
		require(isSellers(), "Sellers only");
		_;
	}
	modifier onlyCouriers() {
		require(isCouriers(), "Couriers only");
		_;
	}
	modifier onlySeller(uint _id) {
		require(isSeller(_id), "Seller only!");
		_;
	}
	modifier onlyBuyer(uint _id) {
		require(isBuyer(_id),	"Buyer only!");
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
	modifier onlyCommittee() {
		require(isCommittee(), "Committee only!");
		_;
	}

	function isSellers() public view returns (bool) {
		return userType[msg.sender] == uType.Seller;
	}
	function isCouriers() public view returns (bool) {
		return userType[msg.sender] == uType.Courier;
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
	function isCommittee() public view returns (bool) {
		return committee == msg.sender;
	}

	function addSellerAddress(address _address) external onlyCommittee {
		userType[_address] = uType.Seller;
	}
	function addCourierAddress(address _address) external onlyCommittee {
		userType[_address] = uType.Courier;
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
	function setCommitteeAddress(address _address) external onlyOwner {
		committee = _address;
	}
	function setTransactionState(uint _id, uint _state) external onlyOwner {
		transactions[_id].state = transactionState(_state);
	}
	// set transaction state "Locked"
	function destroyTransaction(uint _id) external onlyOwner {
		transactions[_id].state = transactionState.Locked;
		emit destroyTransactionEvent(_id);
	}

	function getContractBalance() public onlyOwner view returns (uint) {
		return address(this).balance;
	}

	function getTransactionInfo(uint _id) public
		returns (transactionState, address, address, address, uint[4] memory, uint) {
		Transaction memory t = transactions[_id];
		emit getTransactionInfoEvent(t.id, t.state, t.buyerAddress, t.sellerAddress,
			t.courierAddress, t.items, t.totalAmount);
		return (t.state, t.sellerAddress, t.buyerAddress, t.courierAddress, t.items, t.totalAmount);
	}

	function buyStuff(uint[4] calldata productAmount) external returns (uint, uint[4] memory, uint) {
		uint total = 0;
		uint transactionId = transactions.length;
		for(uint i = 0; i < 4; i++) {
			total += productAmount[i] * productPrice[i];
		}
		transactions.push(Transaction(transactionState.Selected, address(0), msg.sender,
			address(0), transactionId, productAmount, total));
		emit newBuyRequireEvent(msg.sender, transactionId, productAmount, total);
		return (transactionId, productAmount, total);
	}

	// buyer must remember the transaction ID
	function createTransaction(uint _transactionId) public
		onlySellers()
		inState(_transactionId, transactionState.Selected)
		returns (uint) {
		transactions[_transactionId].state = transactionState.Created;
		transactions[_transactionId].sellerAddress = msg.sender;
		// notice couriers to deliver the commodity, and notice buyer the transaction has created.
		emit newTransactionEvent(_transactionId);
	}

	// purchase function are wrote by the following four part and some new varity are added:
	function confirmPurchase(uint _transactionId) external
		onlyBuyer(_transactionId)
		inState(_transactionId, transactionState.Created) payable {
		uint price = transactions[_transactionId].totalAmount;
		require(msg.sender.balance > price, "balance not enough!");
		require(msg.value == price, "transfer price error!");
		emit confirmPurchaseEvent(_transactionId, transactions[_transactionId].items, price);
		transactions[_transactionId].state = transactionState.Purchase;
	}

	// courier claim the transaction to deliver commodity.
	function claimTransaction(uint _transactionId) public
		onlyCouriers()
		inState(_transactionId, transactionState.Purchase) {
		require(transactions[_transactionId].courierAddress == address(0), "courier exist!");
		transactions[_transactionId].courierAddress = msg.sender;
		transactions[_transactionId].state = transactionState.Shippment;
		emit newTransactionClaimEvent(_transactionId, msg.sender);
	}

 	// courier renounce the transaction
	function unclaimTransaction(uint _transactionId) public
		onlyCourier(_transactionId)
		inState(_transactionId, transactionState.Shippment) {
		transactions[_transactionId].courierAddress = address(0);
		transactions[_transactionId].state = transactionState.Purchase;
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
	}

	// courier get some money from transaction, seller get remaining money.
	function transactionComplete(uint _transactionId) public
		onlySeller(_transactionId)
		inState(_transactionId, transactionState.Confirmed) payable {
		uint totalAmount = transactions[_transactionId].totalAmount;
		uint shipCost = totalAmount / 50;
		totalAmount -= shipCost;
		address payable seller = address(uint160(transactions[_transactionId].sellerAddress));
		address payable courier = address(uint160(transactions[_transactionId].courierAddress));
		// transfer from contract to seller and courier
		seller.transfer(totalAmount);
		courier.transfer(shipCost);
		emit transactionCompleteEvent(_transactionId, totalAmount, shipCost);
	}

	function refoundBuyerAmount(uint _transactionId) public onlyOwner payable {
		address payable buyer = address(uint160(transactions[_transactionId].buyerAddress));
		uint amount = transactions[_transactionId].totalAmount;
		require(address(this).balance > amount, "balance not enough!");
		buyer.transfer(amount);
		transactions[_transactionId].state = transactionState.Locked;
		emit refoundBuyerAmountEvent(_transactionId, buyer, amount);
	}

	// random test the pesticide whenever owner wants
	// if it exceeded, set transaction state "Excepted"
	function testPesticide() public onlyCommittee {
		for(uint i = 0; i < transactions.length; i++){
			if(transactions[i].state != transactionState.Confirmed && transactions[i].state != transactionState.Locked) {
				transactions[i].state = transactionState.Excepted;
			}
		}
	}

}
