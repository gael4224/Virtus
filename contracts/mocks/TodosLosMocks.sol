// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TodosLosMocks
 * @notice Todos los contratos Mock necesarios para probar GruposAhorroConAave en un solo archivo
 * @dev Incluye: MockWETH, MockAToken, MockAavePool
 */

// ============ MockWETH ============
contract MockWETH {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }
    
    function withdraw(uint256 amount) external {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        return true;
    }
}

// ============ MockAToken ============
contract MockAToken {
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;
    address public pool;
    
    constructor() {
        pool = msg.sender;
    }
    
    function setPool(address _pool) external {
        pool = _pool;
    }
    
    function mint(address to, uint256 amount) external {
        require(msg.sender == pool, "Only pool can mint");
        balanceOf[to] += amount;
        totalSupply += amount;
    }
    
    function burn(address from, uint256 amount) external {
        require(msg.sender == pool, "Only pool can burn");
        require(balanceOf[from] >= amount, "Insufficient balance");
        balanceOf[from] -= amount;
        totalSupply -= amount;
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        return true;
    }
}

// ============ MockAavePool ============
contract MockAavePool {
    MockWETH public weth;
    MockAToken public aWETH;
    
    constructor(address _weth, address _aWETH) {
        weth = MockWETH(_weth);
        aWETH = MockAToken(_aWETH);
    }
    
    function inicializar() external {
        aWETH.setPool(address(this));
    }
    
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external {
        require(weth.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        aWETH.mint(onBehalfOf, amount);
    }
    
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256) {
        aWETH.burn(msg.sender, amount);
        uint256 amountWithInterests = amount + (amount * 5 / 10000);
        require(weth.transfer(to, amountWithInterests), "Transfer failed");
        return amountWithInterests;
    }
}

