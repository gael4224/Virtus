// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IAaveInterfaces
 * @notice Interfaces compartidas de Aave para todos los contratos
 * @dev Centraliza todas las interfaces de Aave en un solo lugar
 */

interface IAavePool {
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;
    
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
    
    function getReserveData(address asset) 
        external 
        view 
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IAToken is IERC20 {
    // Los aTokens son tokens que representan depósitos en Aave
    // Se acumulan intereses automáticamente
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256) external;
    function approve(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

