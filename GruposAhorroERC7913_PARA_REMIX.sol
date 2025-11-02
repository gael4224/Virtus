// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// ============ Interfaces de Aave (Incluidas Directamente) ============

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

// ============ Contrato Principal (sin dependencias de OpenZeppelin para pruebas simples) ============
// NOTA: Para pruebas sin ERC-7913, usa la versión simplificada en contracts/legacy/GruposAhorroConAaveMultisig.sol

// ============ VERSIÓN SIMPLIFICADA SIN ERC-7913 ============
// Para evitar errores de OpenZeppelin en Remix, usa este archivo separado

// Si necesitas la versión completa con ERC-7913, deberás instalar dependencias de OpenZeppelin en Remix

