// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.1;

interface IERC20 {
    function transfer(address _recipient, uint256 _amount) external returns (bool);
    function balanceOf(address _account) external returns (uint256);
}

contract ICO {
    IERC20 public token;
    address payable public owner;
    uint256 public softCap;
    uint256 public hardCap;
    uint256 public rate;
    uint256 public minPurchase;
    uint256 public maxPurchase;
    uint256 public endTimestamp;
    uint256 public totalDeposits;
    bool public successful;
    mapping(address => uint256) public deposits;
    event Deposit(address indexed _investor, uint256 _amount);
    event Withdraw(address indexed _investor, uint256 _amount);
    event Claim(address indexed _investor, uint256 _amount);
    
    constructor(
        address _token,
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _rate,
        uint256 _minPurchase,
        uint256 _maxPurchase,
        uint256 _endTimestamp
    ) {
        require(_softCap > 0, "Soft Cap must be greater than 0");
        require(_hardCap > _softCap, "Hard Cap must be greater than Soft Cap");
        require(_rate > 0, "Rate must be greater than 0");
        require(_minPurchase > 0, "Minimum Purchase must be greater than 0");
        require(_maxPurchase > _minPurchase, "Maximum Purchase must be greater than Minimum Purchase");
        require(_endTimestamp > block.timestamp, "End Timestamp must be in the future");
        token = IERC20(_token);
        softCap = _softCap;
        hardCap = _hardCap;
        rate = _rate;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        endTimestamp = _endTimestamp;
        owner = payable(msg.sender);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier isDuringICO() {
        require(block.timestamp <= endTimestamp, "ICO has ended");
        _;
    }
    
    modifier isAfterICO() {
        require(block.timestamp > endTimestamp, "ICO has not ended yet");
        _;
    }
    
    function deposit() public payable isDuringICO {
        require(msg.value >= minPurchase, "Amount is below Minimum Purchase");
        require(msg.value <= maxPurchase, "Amount is above Maximum Purchase");
        require(totalDeposits + msg.value <= hardCap, "Amount is above Hard Cap");
        deposits[msg.sender] += msg.value;
        totalDeposits += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    function withdraw() public isAfterICO {
        require(successful == false, "ICO was Successful");
        uint256 amount = deposits[msg.sender];
        require(amount > 0, "No Deposits to Withdraw");
        deposits[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }
    
    function claim() public isAfterICO {
        require(successful == true, "ICO was Unsuccessful");
        uint256 depositAmount = deposits[msg.sender];
        require(depositAmount > 0, "No Deposits to Claim");
        uint256 tokenAmount = depositAmount * rate;
        require(token.balanceOf(address(this)) >= tokenAmount, "Not Enough Tokens in Contract");
         deposits[msg.sender] = 0;
        require(token.transfer(msg.sender, tokenAmount), "Token Transfer Failed");
        emit Claim(msg.sender, tokenAmount);
    }
    
    function checkStatus() public isAfterICO {
        if (totalDeposits >= softCap) {
            successful = true;
        } else {
            successful = false;
        }
    }
    
    function withdrawProceeds() public onlyOwner isAfterICO {
        require(successful == true, "ICO was Unsuccessful");
        uint256 balance = address(this).balance;
        require(balance > 0, "No Proceeds to Withdraw");
        owner.transfer(balance);
    }
}