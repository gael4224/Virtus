// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MockAave
 * @notice Contratos mock para probar el contrato GruposAhorroConAave en Remix VM
 * @dev Estos contratos simulan el comportamiento de Aave para pruebas locales
 */

// Mock WETH (Wrapped ETH)
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

// Mock Aave Pool
contract MockAavePool {
    MockWETH public weth;
    MockAToken public aWETH;
    
    constructor(address _weth, address _aWETH) {
        weth = MockWETH(_weth);
        aWETH = MockAToken(_aWETH);
        // Configurar el pool en el aToken después del deploy
        // El deployer debe llamar setPool después
    }
    
    function inicializar() external {
        // Configurar el pool en el aToken
        aWETH.setPool(address(this));
    }
    
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external {
        // Transferir WETH desde el llamador
        require(weth.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        // Dar aTokens (con intereses simulados - 5% APY)
        // Por simplicidad, damos 1:1 pero con crecimiento simulado
        aWETH.mint(onBehalfOf, amount);
    }
    
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256) {
        // Quemar aTokens
        aWETH.burn(msg.sender, amount);
        
        // Transferir WETH de vuelta (con intereses simulados)
        // En una implementación real, el balance de aWETH crece con intereses
        uint256 amountWithInterests = amount + (amount * 5 / 10000); // ~0.05% por bloque
        require(weth.transfer(to, amountWithInterests), "Transfer failed");
        
        return amountWithInterests;
    }
}

// Mock aToken (Token que representa depósitos en Aave)
contract MockAToken {
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;
    address public pool; // Solo el pool puede mintear/quemar
    
    constructor() {
        pool = msg.sender; // Inicialmente el deployer, pero se puede cambiar
    }
    
    function setPool(address _pool) external {
        // Permitir configurar el pool después del deploy
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

