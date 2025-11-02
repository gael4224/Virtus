// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Account} from "@openzeppelin/community-contracts/account/Account.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {ERC7739} from "@openzeppelin/community-contracts/utils/cryptography/signers/ERC7739.sol";
import {ERC7821} from "@openzeppelin/community-contracts/account/extensions/ERC7821.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {SignerERC7913} from "@openzeppelin/community-contracts/utils/cryptography/signers/SignerERC7913.sol";
import "../../interfaces/IAaveInterfaces.sol";

/**
 * @title CuentaMultisigGrupo
 * @notice Cuenta multisig ERC-7913 para cada grupo de ahorro
 * @dev Cada grupo tiene su propia cuenta que requiere múltiples firmas de participantes
 */
contract CuentaMultisigGrupo is Account, SignerERC7913, ERC7739, ERC7821, ERC721Holder, ERC1155Holder, Initializable {
    
    // Información del grupo asociado
    uint256 public grupoId;
    address public grupoManager; // Contrato principal de grupos
    
    // Configuración de Aave (usando interfaces importadas)
    IAavePool public immutable aavePool;
    IWETH public immutable weth;
    IAToken public immutable aWETH;
    bool public usarAave;
    
    // Estado del grupo
    uint256 public objetivo; // Meta en wei
    uint256 public totalRecaudado; // Total depositado
    uint256 public totalEnAave; // Total en Aave
    uint256 public fechaObjetivo; // Fecha límite
    bool public activo;
    bool public metaAlcanzada;
    
    address[] public participantes;
    mapping(address => uint256) public aportes;
    
    // Eventos
    event GrupoInicializado(
        uint256 indexed grupoId,
        address indexed cuenta,
        address[] participantes,
        uint256 objetivo,
        uint256 fechaObjetivo
    );
    
    event AporteRealizado(
        address indexed participante,
        uint256 cantidad,
        uint256 totalRecaudado,
        uint256 totalEnAave
    );
    
    event MetaAlcanzada(uint256 indexed grupoId, uint256 totalRecaudado);
    
    event FondoRetirado(
        address indexed destinatario,
        uint256 cantidad,
        uint256 interesesGenerados
    );
    
    event FondosDepositadosEnAave(uint256 cantidad);
    event FondosRetiradosDeAave(uint256 cantidad);
    
    constructor(
        address _aavePool,
        address _weth,
        address _aWETH,
        bool _usarAave
    ) EIP712("CuentaMultisigGrupo", "1") {
        aavePool = IAavePool(_aavePool);
        weth = IWETH(_weth);
        aWETH = IAToken(_aWETH);
        usarAave = _usarAave;
    }
    
    /**
     * @notice Inicializa la cuenta multisig para un grupo
     * @param _signer Bytes que representan los signatarios (formato ERC-7913)
     * @param _grupoId ID del grupo
     * @param _grupoManager Dirección del contrato principal de grupos
     * @param _participantes Lista de participantes del grupo
     * @param _objetivo Meta en wei
     * @param _fechaObjetivo Timestamp de la fecha límite
     */
    function initialize(
        bytes memory _signer,
        uint256 _grupoId,
        address _grupoManager,
        address[] memory _participantes,
        uint256 _objetivo,
        uint256 _fechaObjetivo
    ) public initializer {
        _setSigner(_signer);
        
        grupoId = _grupoId;
        grupoManager = _grupoManager;
        participantes = _participantes;
        objetivo = _objetivo;
        fechaObjetivo = _fechaObjetivo;
        activo = true;
        metaAlcanzada = false;
        totalRecaudado = 0;
        totalEnAave = 0;
        
        // Agregar esta cuenta como participante
        participantes.push(address(this));
        
        emit GrupoInicializado(_grupoId, address(this), _participantes, _objetivo, _fechaObjetivo);
    }
    
    /**
     * @notice Permite actualizar los signatarios del multisig
     * @param _signer Nuevos signatarios
     */
    function setSigner(bytes memory _signer) public onlyEntryPointOrSelf {
        _setSigner(_signer);
    }
    
    /**
     * @notice Permite a un participante aportar fondos (requiere firma del participante)
     * @dev Los fondos se depositan automáticamente en Aave
     */
    function aportar() external payable {
        require(activo, "El grupo no esta activo");
        require(msg.value > 0, "Debes enviar una cantidad mayor a 0");
        require(!metaAlcanzada, "La meta ya fue alcanzada");
        require(block.timestamp <= fechaObjetivo, "La fecha objetivo ya paso");
        require(_esParticipante(msg.sender), "No eres participante de este grupo");
        
        uint256 cantidadOriginal = msg.value;
        
        aportes[msg.sender] += cantidadOriginal;
        totalRecaudado += cantidadOriginal;
        
        // Depositar en Aave para generar rendimiento
        if (usarAave && address(aavePool) != address(0)) {
            _depositarEnAave(cantidadOriginal);
            totalEnAave += cantidadOriginal;
            emit FondosDepositadosEnAave(cantidadOriginal);
        } else {
            totalEnAave += cantidadOriginal;
        }
        
        // Verificar si se alcanzó la meta
        uint256 totalActual = obtenerBalanceTotal();
        if (totalActual >= objetivo && !metaAlcanzada) {
            metaAlcanzada = true;
            emit MetaAlcanzada(grupoId, totalActual);
        }
        
        emit AporteRealizado(msg.sender, cantidadOriginal, totalRecaudado, totalEnAave);
    }
    
    /**
     * @notice Retira fondos del grupo (requiere múltiples firmas)
     * @dev Esta función puede ser llamada a través del entry point con firmas multisig
     * @param _destinatario Dirección donde enviar los fondos
     */
    function retirarFondos(address _destinatario) external onlyEntryPointOrSelf {
        require(
            metaAlcanzada || block.timestamp > fechaObjetivo,
            "No se puede retirar: la meta no se alcanzo y la fecha no ha pasado"
        );
        require(_destinatario != address(0), "Direccion invalida");
        
        uint256 balanceTotal = obtenerBalanceTotal();
        require(balanceTotal > 0, "No hay fondos para retirar");
        
        uint256 cantidadOriginal = totalRecaudado;
        uint256 interesesGenerados = 0;
        
        // Retirar de Aave si se está usando
        if (usarAave && totalEnAave > 0 && address(aavePool) != address(0)) {
            uint256 cantidadRetirada = _retirarDeAave(type(uint256).max);
            interesesGenerados = cantidadRetirada > cantidadOriginal ? cantidadRetirada - cantidadOriginal : 0;
            emit FondosRetiradosDeAave(cantidadRetirada);
        } else {
            uint256 ethBalance = address(this).balance;
            if (ethBalance >= balanceTotal) {
                interesesGenerados = balanceTotal > cantidadOriginal ? balanceTotal - cantidadOriginal : 0;
            }
        }
        
        // Transferir fondos al destinatario
        uint256 cantidadFinal = address(this).balance;
        require(cantidadFinal > 0, "No hay fondos para transferir");
        
        (bool success, ) = payable(_destinatario).call{value: cantidadFinal}("");
        require(success, "Error al transferir fondos");
        
        // Actualizar estado
        totalRecaudado = 0;
        totalEnAave = 0;
        activo = false;
        
        emit FondoRetirado(_destinatario, cantidadFinal, interesesGenerados);
    }
    
    /**
     * @notice Permite a un participante retirar su aporte individual
     * @param _grupoId ID del grupo (para verificación)
     */
    function retirarMiAporte(uint256 _grupoId) external {
        require(_grupoId == grupoId, "ID de grupo incorrecto");
        require(
            block.timestamp > fechaObjetivo,
            "La fecha objetivo no ha pasado"
        );
        require(!metaAlcanzada, "La meta fue alcanzada, se requiere multisig para retirar");
        require(_esParticipante(msg.sender), "No eres participante");
        
        uint256 miAporteOriginal = aportes[msg.sender];
        require(miAporteOriginal > 0, "No tienes aportes para retirar");
        
        // Calcular aporte proporcional con intereses
        uint256 balanceTotal = obtenerBalanceTotal();
        uint256 porcentajeAporte = (miAporteOriginal * 100) / totalRecaudado;
        uint256 miAporteConIntereses = (balanceTotal * porcentajeAporte) / 100;
        
        // Retirar de Aave si se está usando
        if (usarAave && totalEnAave > 0) {
            uint256 balanceAave = aWETH.balanceOf(address(this));
            uint256 cantidadRetirarAave = (balanceAave * porcentajeAporte) / 100;
            
            if (cantidadRetirarAave > 0) {
                aavePool.withdraw(address(weth), cantidadRetirarAave, address(this));
                weth.withdraw(cantidadRetirarAave);
            }
        }
        
        // Actualizar estado
        aportes[msg.sender] = 0;
        totalRecaudado -= miAporteOriginal;
        totalEnAave -= miAporteOriginal;
        
        // Transferir
        (bool success, ) = payable(msg.sender).call{value: miAporteConIntereses}("");
        require(success, "Error al transferir fondos");
        
        emit FondoRetirado(msg.sender, miAporteConIntereses, miAporteConIntereses - miAporteOriginal);
    }
    
    // ============ Funciones Internas ============
    
    function _depositarEnAave(uint256 _cantidad) internal {
        weth.deposit{value: _cantidad}();
        weth.approve(address(aavePool), _cantidad);
        aavePool.supply(address(weth), _cantidad, address(this), 0);
    }
    
    function _retirarDeAave(uint256 _cantidadMaxima) internal returns (uint256) {
        uint256 balanceAave = aWETH.balanceOf(address(this));
        
        if (balanceAave == 0) {
            return 0;
        }
        
        uint256 cantidadARetirar = _cantidadMaxima > balanceAave ? balanceAave : _cantidadMaxima;
        uint256 cantidadRetirada = aavePool.withdraw(address(weth), cantidadARetirar, address(this));
        
        if (cantidadRetirada > 0) {
            weth.withdraw(cantidadRetirada);
        }
        
        return cantidadRetirada;
    }
    
    function _esParticipante(address _direccion) internal view returns (bool) {
        for (uint256 i = 0; i < participantes.length; i++) {
            if (participantes[i] == _direccion) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * @notice Permite al entry point como ejecutor autorizado
     */
    function _erc7821AuthorizedExecutor(
        address caller,
        bytes32 mode,
        bytes calldata executionData
    ) internal view virtual override returns (bool) {
        return caller == address(entryPoint()) || super._erc7821AuthorizedExecutor(caller, mode, executionData);
    }
    
    // ============ Funciones de Consulta ============
    
    function obtenerBalanceTotal() public view returns (uint256) {
        if (usarAave && totalEnAave > 0 && address(aavePool) != address(0)) {
            uint256 balanceAave = aWETH.balanceOf(address(this));
            return balanceAave;
        } else {
            return address(this).balance;
        }
    }
    
    function calcularIntereses() external view returns (uint256) {
        uint256 balanceTotal = obtenerBalanceTotal();
        if (balanceTotal > totalRecaudado) {
            return balanceTotal - totalRecaudado;
        }
        return 0;
    }
    
    function obtenerAporte(address _participante) external view returns (uint256) {
        return aportes[_participante];
    }
    
    function obtenerParticipantes() external view returns (address[] memory) {
        return participantes;
    }
    
    function obtenerInfoGrupo()
        external
        view
        returns (
            uint256 id,
            address manager,
            uint256 objetivoGrupo,
            uint256 totalRecaudadoGrupo,
            uint256 totalEnAaveGrupo,
            uint256 fechaObjetivoGrupo,
            bool activoGrupo,
            bool metaAlcanzadaGrupo,
            address[] memory participantesGrupo
        )
    {
        return (
            grupoId,
            grupoManager,
            objetivo,
            totalRecaudado,
            totalEnAave,
            fechaObjetivo,
            activo,
            metaAlcanzada,
            participantes
        );
    }
    
    // Permitir que el contrato reciba ETH
    receive() external payable {}
}

/**
 * @title GruposAhorroERC7913
 * @notice Contrato principal que gestiona grupos con cuentas multisig ERC-7913
 * @dev Crea una cuenta multisig por cada grupo que requiere firmas múltiples para operaciones
 */
contract GruposAhorroERC7913 {
    
    // Factory para crear cuentas multisig
    address public cuentaFactory;
    
    // Direcciones de Aave (usando interfaces importadas)
    IAavePool public immutable aavePool;
    IWETH public immutable weth;
    IAToken public immutable aWETH;
    bool public usarAave;
    
    // Información de grupos
    uint256 public totalGrupos;
    mapping(uint256 => address) public cuentasGrupos; // grupoId => cuenta multisig
    mapping(address => uint256[]) public gruposPorUsuario;
    
    // Eventos
    event GrupoCreado(
        uint256 indexed grupoId,
        address indexed cuentaMultisig,
        address indexed creador,
        string nombre,
        uint256 objetivo,
        uint256 fechaObjetivo,
        address[] participantes
    );
    
    event ParticipanteAgregado(
        uint256 indexed grupoId,
        address indexed participante
    );
    
    constructor(
        address _aavePool,
        address _weth,
        address _aWETH,
        bool _usarAave,
        address _cuentaFactory
    ) {
        aavePool = IAavePool(_aavePool);
        weth = IWETH(_weth);
        aWETH = IAToken(_aWETH);
        usarAave = _usarAave;
        cuentaFactory = _cuentaFactory;
    }
    
    /**
     * @notice Crea un nuevo grupo con cuenta multisig ERC-7913
     * @param _nombre Nombre del grupo
     * @param _objetivo Meta en wei
     * @param _fechaObjetivo Timestamp de la fecha límite
     * @param _descripcion Descripción del grupo
     * @param _participantes Lista de participantes iniciales
     * @param _signer Bytes que representan los signatarios para el multisig
     * @return grupoId ID del grupo creado
     * @return cuenta Dirección de la cuenta multisig creada
     */
    function crearGrupo(
        string memory _nombre,
        uint256 _objetivo,
        uint256 _fechaObjetivo,
        string memory _descripcion,
        address[] memory _participantes,
        bytes memory _signer
    ) external returns (uint256 grupoId, address cuenta) {
        require(_objetivo > 0, "El objetivo debe ser mayor a 0");
        require(
            _fechaObjetivo > block.timestamp,
            "La fecha objetivo debe ser en el futuro"
        );
        require(bytes(_nombre).length > 0, "El nombre no puede estar vacio");
        require(_participantes.length > 0, "Debe haber al menos un participante");
        
        grupoId = totalGrupos++;
        
        // Crear cuenta multisig para el grupo
        // Nota: En producción, esto se haría usando CREATE2 o un factory pattern
        cuenta = address(new CuentaMultisigGrupo(address(aavePool), address(weth), address(aWETH), usarAave));
        
        // Inicializar la cuenta multisig
        CuentaMultisigGrupo(payable(cuenta)).initialize(
            _signer,
            grupoId,
            address(this),
            _participantes,
            _objetivo,
            _fechaObjetivo
        );
        
        cuentasGrupos[grupoId] = cuenta;
        gruposPorUsuario[msg.sender].push(grupoId);
        
        emit GrupoCreado(grupoId, cuenta, msg.sender, _nombre, _objetivo, _fechaObjetivo, _participantes);
        
        return (grupoId, cuenta);
    }
    
    /**
     * @notice Obtiene la cuenta multisig de un grupo
     * @param _grupoId ID del grupo
     * @return Dirección de la cuenta multisig
     */
    function obtenerCuentaGrupo(uint256 _grupoId) external view returns (address) {
        return cuentasGrupos[_grupoId];
    }
    
    /**
     * @notice Obtiene los grupos de un usuario
     * @param _usuario Dirección del usuario
     * @return Lista de IDs de grupos
     */
    function obtenerGruposPorUsuario(address _usuario) external view returns (uint256[] memory) {
        return gruposPorUsuario[_usuario];
    }
}

