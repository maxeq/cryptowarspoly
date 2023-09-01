// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract GameToken {
    string public constant name = "GameToken";
    string public constant symbol = "GT";
    uint8 public constant decimals = 18;

    uint256 public totalSupply;
    address public owner;
    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public minters;

    event Spent(address indexed user, uint256 value);
    event Burned(uint256 value);

    constructor(uint256 initialSupply) {
        totalSupply = initialSupply;
        balanceOf[msg.sender] = initialSupply;
        owner = msg.sender;
        minters[owner] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "Only minters can call this function");
        _;
    }

    function addMinter(address _minter) external onlyOwner {
        minters[_minter] = true;
    }

    function removeMinter(address _minter) external onlyOwner {
        minters[_minter] = false;
    }

    function spend(uint256 _value) external {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        balanceOf[msg.sender] -= _value;
        balanceOf[owner] += _value; // The tokens are transferred to the owner (game) when spent

        emit Spent(msg.sender, _value);
    }

    function burnForGameEntry(uint256 _value) external {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;

        emit Burned(_value);
    }

    function mint(address _account, uint256 _value) external onlyMinter {
        totalSupply += _value;
        balanceOf[_account] += _value;
    }
}
