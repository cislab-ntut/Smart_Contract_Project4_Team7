# Project7-4_Smart_contract
![](https://i.imgur.com/jeD6XJI.png)
## 程式架構
- TransactionContract
    - addSellerAddress
    - addCourierAddress
    - setCommitteeAddress
    - **buyStuff**
    - **createTransaction**
    - **confirmPurchase**
    - **claimTransaction**
    - unclaimTransaction
    - **deliveryComplete**
    - **confirmReceived**
    - **transactionComplete**
    - **getTransactionInfo**
    - refoundBuyerAmount
    - testPesticide

> 粗體字為合約主要結構，其他setter及modifier等過於繁瑣故不在此列出，請至`Transaction.sol`查看。

## 運作流程

### 首次執行
1. `setCommitteeAddress`，合約首次建立後，須由合約擁有者手動指定農委會的Address
2. `addSellerAddress`，通過農委會驗證過的賣家才可以使用合約進行販賣
3. `addCourierAddress`，通過農委會驗證的物流業者才可以進行接單

### 開始運作
1. `buyStuff`，買家先挑選所需的各產品數量，傳入一大小為4的陣列，代表各產品的購買數量(為方便測試，目前只開放4種產品購買)，回傳訂單編號、已選定之產品數量、總金額等。訂單編號**必須**記住，之後所有操作都必須傳入指定的訂單編號才可運作。
2. `createTransaction`，賣家進行確認並成立訂單。
3. `confirmPurchase`，訂單成立後買家可以進行付款的動作，填入指定的訂單編號，並於value欄位填入付款金額，單位為wei。付款金額可於(1)的回傳內容得知，或是透過訂單編號呼叫`getTransactionInfo`來重新確認訂單資料。
4. `claimTransaction`，物流業者進行主動接單，若接單後因故無法處理，可以透過`unclaimTransaction`棄單，讓其他人接單。
5. `deliveryComplete`，物流業者完成配送。
6. `confirmReceived`，買家確認收貨。
7. `transactionComplete`，賣家確認交易完成，並收到貨款；物流業者從貨款中抽取一部分作為運費。

> 所有訂單皆透過以上方式按照順序運作，若沒依照順序執行，會因為身分不同或訂單狀態不正確而阻擋，因而浪費gas，故使用者呼叫API時請小心。

###


## 部署
> 1. 於線上編譯器編譯通過，並使用JavaScript VM做部署測試，依照以上方法進行操作，功能皆正常運作。之後嘗試將ByteCode導出並於柑橘測試網路部署成功。  
> 2. 嘗試使用Injected Web3做部署測試，才知道此線上編譯器的部署功能也能快速部署至測試網路。  
> 3. 目前只有部署完成的階段，並未使用任何前端進行API呼叫。
<br>

[交易紀錄](https://testnet.tangerine.garden/transaction/0x0e2214d90002da3361d4776e486e6caad9c7315c55e875102da18cdee0f6202c)
[injected Web3部署測試](https://rinkeby.etherscan.io/tx/0x65a4960a7f157a66e045eb80d2748103a5d61ad0efef0d6f37e8a61729cc0570)

## Contribution
[click me](https://hackmd.io/@molrobot/B1AeclryL)
