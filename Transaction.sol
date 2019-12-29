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

	modifier inState(uint transactionId, sType _state) {
		require(transactions[transactionId].state == _state, "Invalid state.");
		_;
    }
	modifier onlyBuyer(uint transactionId) {
		require(msg.sender == transactions[transactionId].buyerAddress,	"Only buyer can call this.");
		_;
	}

	enum uType { Initial, Buyer, Seller, Courier }
	enum sType { Created, Locked, Inactive }
	struct Transaction{
		address sellerAddress;
		address buyerAddress;
		address courierAddress;
		uint id;
		// string buyProduct;
		uint buyProductId;
		uint buyAmount;
		uint buyPrice;
		// uint price;
    	sType state;
		// can add fruit type, amount, prize, ...
	}

	string[4] public product = [ 'apple', 'banana', 'cranberry', 'grape' ];
    uint[4] public price = [ 30, 25, 50, 70 ];

	Transaction[] public transactions;
	mapping (address => uType) userType;

	// only owner can call these function
	function setSellerAddress(uint transactionId, address _address) external onlyOwner {
		transactions[transactionId].sellerAddress = _address;
	}
	function setBuyerAddress(uint transactionId, address _address) external onlyOwner {
		transactions[transactionId].buyerAddress = _address;
	}
	function setCourierAddress(uint transactionId, address _address) external onlyOwner {
		transactions[transactionId].courierAddress = _address;
	}
	function setTransactionState(uint transactionId, uint _state) external onlyOwner {
		transactions[transactionId].state = sType(_state);
	}


	// _type = { Initial, Buyer, Seller, Courier } 0 1 2 3
	function chooseUserType(uint _type) public {
		// only when the key is not exist, can choose userType
		require(userType[msg.sender] == uType(0), "userType exist!");
		userType[msg.sender] = uType(_type);
	}

	function buyStuff(uint _transactionId, uint _productChoose, uint _buyNum) public {
		require(userType[msg.sender] == uType.Buyer, "userType error!");
		if (_productChoose < 0 || _productChoose > 3) {
		}
		else {
			transactions[_transactionId].buyProductId = _productChoose;
			// transactions[_transactionId].buyProduct = product[_productChoose];
			transactions[_transactionId].buyAmount = _buyNum;
			transactions[_transactionId].buyPrice = _buyNum * price[_productChoose];
		}
		// pay cryptocurrency
		emit newBuyRequireEvent(msg.sender);
	}

	function createTransaction(address _buyerAddress, uint _buyProductId, uint _buyAmount, uint _buyPrice) public {
		require(userType[msg.sender] == uType.Seller, "userType error!");
		uint transactionId = transactions.length;
		// transactions.push(Transaction(msg.sender, _buyerAddress, address(0), transactionId, 0, State.Created));
		transactions.push(Transaction(msg.sender, _buyerAddress, address(0), transactionId, _buyProductId, _buyAmount, _buyPrice, sType.Created));
		emit newTransactionEvent(transactionId);  //notice couriers to deliver the commodity, and notice buyer the transaction has created.

	}

	function claimTransaction(uint _transactionId) public {  //courier claim the transaction to deliver commodity.
		require(userType[msg.sender] == uType.Seller, "userType error!");
		require(transactions[_transactionId].courierAddress == address(0), "courier exist!");
		transactions[_transactionId].courierAddress = msg.sender;
		emit newTransactionClaimEvent(_transactionId);
	}

	function unclaimTransaction(uint _transactionId) public {  //courier renounce the transaction
		require(msg.sender == transactions[_transactionId].courierAddress, "courier only!");
		transactions[_transactionId].courierAddress = address(0);
		emit transactionUnClaimEvent(_transactionId);
	}

	function deliveryComplete(uint _transactionId) public {
		require(msg.sender == transactions[_transactionId].courierAddress, "courier only!");
		emit deliveryCompleteEvent(_transactionId);
	}

	function transactionComplete(uint _transactionId) public onlyBuyer(_transactionId) {
		require(msg.sender == transactions[_transactionId].buyerAddress, "");
		// courier get some money from transaction, seller get remaining money.
		emit transactionCompleteEvent(_transactionId);
	}

	// purchase function are wrote by the following four part and some new varity are added:
	function confirmPurchase(uint _transactionId, uint buyPrice) public inState(_transactionId, sType.Created) {
		// require(msg.sender.balance > price, "balance not enough!");
		require(msg.sender.balance > transactions[_transactionId].buyPrice, "balance not enough!");
		transactions[_transactionId].buyerAddress = msg.sender;
		transactions[_transactionId].state = sType.Locked;
	}

	function confirmReceived(uint _transactionId, uint buyPrice) public onlyBuyer(_transactionId) inState(_transactionId, sType.Locked) {
		emit ItemReceived();
		address payable buyer = address(uint160(transactions[_transactionId].buyerAddress));
		address payable seller = address(uint160(transactions[_transactionId].sellerAddress));
		transactions[_transactionId].state = sType.Inactive;
		// buyer.transfer(price);
		buyer.transfer(buyPrice);
		seller.transfer(address(this).balance);
	}
}
