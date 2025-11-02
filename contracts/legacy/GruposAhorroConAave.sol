// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ============ Interfaces de Aave ============

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
}

/**
 * @title GruposAhorroConAave
 * @notice Contrato para gestionar grupos de ahorro con generación de rendimiento usando Aave
 * @dev Permite crear grupos, aportar fondos que se depositan en Aave, y retirar con intereses
 */
contract GruposAhorroConAave {

    // ============ Estructuras ============
    
    struct Grupo {
        uint256 id;
        address creador;
        string nombre;
        uint256 objetivo; // Meta en wei
        uint256 totalRecaudado; // Total depositado originalmente
        uint256 totalEnAave; // Total actualmente en Aave (incluye intereses)
        uint256 fechaObjetivo; // Timestamp de la fecha límite
        string descripcion;
        bool activo;
        bool metaAlcanzada;
        address[] participantes;
        mapping(address => uint256) aportes; // Aportes originales por participante
        mapping(address => uint256) aportesConIntereses; // Aportes + intereses proporcionales
    }

    // ============ Variables de Estado ============
    
    uint256 public totalGrupos;
    mapping(uint256 => Grupo) public grupos;
    mapping(address => uint256[]) public gruposPorUsuario;
    
    // Direcciones de Aave (para Arbitrum Sepolia - testnet)
    // NOTA: Estas direcciones son de ejemplo. Debes verificarlas en la testnet
    IAavePool public immutable aavePool;
    IWETH public immutable weth;
    IAToken public immutable aWETH;
    
    // Para Remix VM (simulación local), usaremos direcciones mock
    // En producción, usa las direcciones reales de Aave en la red correspondiente
    bool public usarAave; // Flag para habilitar/deshabilitar Aave (para pruebas en Remix VM)

    // ============ Eventos ============
    
    event GrupoCreado(
        uint256 indexed grupoId,
        address indexed creador,
        string nombre,
        uint256 objetivo,
        uint256 fechaObjetivo
    );
    
    event AporteRealizado(
        uint256 indexed grupoId,
        address indexed participante,
        uint256 cantidad,
        uint256 totalRecaudado,
        uint256 totalEnAave
    );
    
    event MetaAlcanzada(uint256 indexed grupoId, uint256 totalRecaudado);
    
    event FondoRetirado(
        uint256 indexed grupoId,
        address indexed destinatario,
        uint256 cantidad,
        uint256 interesesGenerados
    );
    
    event ParticipanteAgregado(uint256 indexed grupoId, address indexed participante);
    event FondosDepositadosEnAave(uint256 indexed grupoId, uint256 cantidad);
    event FondosRetiradosDeAave(uint256 indexed grupoId, uint256 cantidad);

    // ============ Constructor ============
    
    constructor(
        address _aavePool,
        address _weth,
        address _aWETH,
        bool _usarAave
    ) {
        aavePool = IAavePool(_aavePool);
        weth = IWETH(_weth);
        aWETH = IAToken(_aWETH);
        usarAave = _usarAave;
    }

    // ============ Modificadores ============
    
    modifier soloActivo(uint256 _grupoId) {
        require(grupos[_grupoId].activo, "El grupo no esta activo");
        _;
    }
    
    modifier soloCreador(uint256 _grupoId) {
        require(
            grupos[_grupoId].creador == msg.sender,
            "Solo el creador puede ejecutar esta accion"
        );
        _;
    }
    
    modifier soloParticipante(uint256 _grupoId) {
        bool esParticipante = false;
        for (uint256 i = 0; i < grupos[_grupoId].participantes.length; i++) {
            if (grupos[_grupoId].participantes[i] == msg.sender) {
                esParticipante = true;
                break;
            }
        }
        require(esParticipante, "No eres participante de este grupo");
        _;
    }

    // ============ Funciones Públicas ============

    /**
     * @notice Crea un nuevo grupo de ahorro
     * @param _nombre Nombre del grupo
     * @param _objetivo Meta en wei
     * @param _fechaObjetivo Timestamp de la fecha límite
     * @param _descripcion Descripción del grupo
     * @return grupoId ID del grupo creado
     */
    function crearGrupo(
        string memory _nombre,
        uint256 _objetivo,
        uint256 _fechaObjetivo,
        string memory _descripcion
    ) external returns (uint256) {
        require(_objetivo > 0, "El objetivo debe ser mayor a 0");
        require(
            _fechaObjetivo > block.timestamp,
            "La fecha objetivo debe ser en el futuro"
        );
        require(bytes(_nombre).length > 0, "El nombre no puede estar vacio");

        uint256 nuevoId = totalGrupos++;
        
        Grupo storage nuevoGrupo = grupos[nuevoId];
        nuevoGrupo.id = nuevoId;
        nuevoGrupo.creador = msg.sender;
        nuevoGrupo.nombre = _nombre;
        nuevoGrupo.objetivo = _objetivo;
        nuevoGrupo.fechaObjetivo = _fechaObjetivo;
        nuevoGrupo.descripcion = _descripcion;
        nuevoGrupo.activo = true;
        nuevoGrupo.metaAlcanzada = false;
        nuevoGrupo.totalRecaudado = 0;
        nuevoGrupo.totalEnAave = 0;
        
        // Agregar al creador como primer participante
        nuevoGrupo.participantes.push(msg.sender);
        gruposPorUsuario[msg.sender].push(nuevoId);

        emit GrupoCreado(nuevoId, msg.sender, _nombre, _objetivo, _fechaObjetivo);
        
        return nuevoId;
    }

    /**
     * @notice Permite agregar un participante al grupo (solo el creador)
     * @param _grupoId ID del grupo
     * @param _participante Dirección del nuevo participante
     */
    function agregarParticipante(
        uint256 _grupoId,
        address _participante
    ) external soloActivo(_grupoId) soloCreador(_grupoId) {
        require(_participante != address(0), "Direccion invalida");
        
        // Verificar si ya es participante
        bool yaEsParticipante = false;
        for (uint256 i = 0; i < grupos[_grupoId].participantes.length; i++) {
            if (grupos[_grupoId].participantes[i] == _participante) {
                yaEsParticipante = true;
                break;
            }
        }
        require(!yaEsParticipante, "El usuario ya es participante");

        grupos[_grupoId].participantes.push(_participante);
        gruposPorUsuario[_participante].push(_grupoId);

        emit ParticipanteAgregado(_grupoId, _participante);
    }

    /**
     * @notice Permite a un participante aportar fondos al grupo
     * @dev Los fondos se depositan automáticamente en Aave para generar rendimiento
     * @param _grupoId ID del grupo
     */
    function aportar(
        uint256 _grupoId
    ) external payable soloActivo(_grupoId) soloParticipante(_grupoId) {
        require(msg.value > 0, "Debes enviar una cantidad mayor a 0");
        require(
            !grupos[_grupoId].metaAlcanzada,
            "La meta ya fue alcanzada"
        );
        require(
            block.timestamp <= grupos[_grupoId].fechaObjetivo,
            "La fecha objetivo ya paso"
        );

        Grupo storage grupo = grupos[_grupoId];
        uint256 cantidadOriginal = msg.value;
        
        // Actualizar contadores originales
        grupo.aportes[msg.sender] += cantidadOriginal;
        grupo.totalRecaudado += cantidadOriginal;
        
        // Depositar en Aave para generar rendimiento
        if (usarAave && address(aavePool) != address(0)) {
            _depositarEnAave(cantidadOriginal);
            grupo.totalEnAave += cantidadOriginal;
            emit FondosDepositadosEnAave(_grupoId, cantidadOriginal);
        } else {
            // Si no se usa Aave, simplemente guardar el ETH en el contrato
            grupo.totalEnAave += cantidadOriginal;
        }

        // Verificar si se alcanzó la meta
        uint256 totalActual = obtenerBalanceTotal(_grupoId);
        if (totalActual >= grupo.objetivo && !grupo.metaAlcanzada) {
            grupo.metaAlcanzada = true;
            emit MetaAlcanzada(_grupoId, totalActual);
        }

        emit AporteRealizado(_grupoId, msg.sender, cantidadOriginal, grupo.totalRecaudado, grupo.totalEnAave);
    }

    /**
     * @notice Deposita ETH en Aave convirtiéndolo primero a WETH
     * @param _cantidad Cantidad de ETH a depositar
     */
    function _depositarEnAave(uint256 _cantidad) internal {
        // Convertir ETH a WETH
        weth.deposit{value: _cantidad}();
        
        // Aprobar a Aave para que pueda tomar el WETH
        weth.approve(address(aavePool), _cantidad);
        
        // Depositar en Aave
        // onBehalfOf = address(this) (este contrato)
        // referralCode = 0 (sin referido)
        aavePool.supply(address(weth), _cantidad, address(this), 0);
    }

    /**
     * @notice Permite al creador retirar los fondos cuando se alcanza la meta o pasa la fecha
     * @dev Retira fondos de Aave incluyendo intereses generados
     * @param _grupoId ID del grupo
     * @param _destinatario Dirección donde enviar los fondos
     */
    function retirarFondos(
        uint256 _grupoId,
        address _destinatario
    ) external soloCreador(_grupoId) {
        require(
            grupos[_grupoId].metaAlcanzada || 
            block.timestamp > grupos[_grupoId].fechaObjetivo,
            "No se puede retirar: la meta no se alcanzo y la fecha no ha pasado"
        );
        require(_destinatario != address(0), "Direccion invalida");
        
        Grupo storage grupo = grupos[_grupoId];
        uint256 balanceTotal = obtenerBalanceTotal(_grupoId);
        
        require(balanceTotal > 0, "No hay fondos para retirar");

        uint256 cantidadOriginal = grupo.totalRecaudado;
        uint256 interesesGenerados = 0;

        // Retirar de Aave si se está usando
        if (usarAave && grupo.totalEnAave > 0 && address(aavePool) != address(0)) {
            uint256 cantidadRetirada = _retirarDeAave(type(uint256).max);
            interesesGenerados = cantidadRetirada > cantidadOriginal ? cantidadRetirada - cantidadOriginal : 0;
            emit FondosRetiradosDeAave(_grupoId, cantidadRetirada);
        } else {
            // Si no se usa Aave, simplemente transferir el ETH del contrato
            uint256 ethBalance = address(this).balance;
            if (ethBalance >= balanceTotal) {
                interesesGenerados = balanceTotal > cantidadOriginal ? balanceTotal - cantidadOriginal : 0;
            } else {
                interesesGenerados = 0;
            }
        }

        // Transferir fondos al destinatario
        uint256 cantidadFinal = address(this).balance;
        require(cantidadFinal > 0, "No hay fondos para transferir");
        
        (bool success, ) = payable(_destinatario).call{value: cantidadFinal}("");
        require(success, "Error al transferir fondos");

        // Actualizar estado
        grupo.totalRecaudado = 0;
        grupo.totalEnAave = 0;
        grupo.activo = false;

        emit FondoRetirado(_grupoId, _destinatario, cantidadFinal, interesesGenerados);
    }

    /**
     * @notice Retira fondos de Aave incluyendo intereses
     * @param _cantidadMaxima Cantidad máxima a retirar (usar type(uint256).max para todo)
     * @return Cantidad retirada
     */
    function _retirarDeAave(uint256 _cantidadMaxima) internal returns (uint256) {
        // Obtener balance de aWETH (incluye intereses)
        uint256 balanceAave = aWETH.balanceOf(address(this));
        
        if (balanceAave == 0) {
            return 0;
        }
        
        uint256 cantidadARetirar = _cantidadMaxima > balanceAave ? balanceAave : _cantidadMaxima;
        
        // Retirar de Aave
        uint256 cantidadRetirada = aavePool.withdraw(
            address(weth),
            cantidadARetirar,
            address(this)
        );
        
        // Convertir WETH de vuelta a ETH
        if (cantidadRetirada > 0) {
            weth.withdraw(cantidadRetirada);
        }
        
        return cantidadRetirada;
    }

    /**
     * @notice Permite a un participante retirar su aporte si la fecha pasó y no se alcanzó la meta
     * @param _grupoId ID del grupo
     */
    function retirarMiAporte(uint256 _grupoId) external soloParticipante(_grupoId) {
        require(
            block.timestamp > grupos[_grupoId].fechaObjetivo,
            "La fecha objetivo no ha pasado"
        );
        require(
            !grupos[_grupoId].metaAlcanzada,
            "La meta fue alcanzada, el creador debe retirar"
        );

        Grupo storage grupo = grupos[_grupoId];
        uint256 miAporteOriginal = grupo.aportes[msg.sender];
        require(miAporteOriginal > 0, "No tienes aportes para retirar");

        // Calcular aporte proporcional con intereses
        uint256 balanceTotal = obtenerBalanceTotal(_grupoId);
        uint256 porcentajeAporte = (miAporteOriginal * 100) / grupo.totalRecaudado;
        uint256 miAporteConIntereses = (balanceTotal * porcentajeAporte) / 100;

        // Retirar de Aave si se está usando
        if (usarAave && grupo.totalEnAave > 0) {
            // Retirar proporcional de Aave
            uint256 balanceAave = aWETH.balanceOf(address(this));
            uint256 cantidadRetirarAave = (balanceAave * porcentajeAporte) / 100;
            
            if (cantidadRetirarAave > 0) {
                aavePool.withdraw(address(weth), cantidadRetirarAave, address(this));
                weth.withdraw(cantidadRetirarAave);
            }
        }

        // Actualizar estado
        grupo.aportes[msg.sender] = 0;
        grupo.totalRecaudado -= miAporteOriginal;
        grupo.totalEnAave -= miAporteOriginal;

        // Transferir
        (bool success, ) = payable(msg.sender).call{value: miAporteConIntereses}("");
        require(success, "Error al transferir fondos");

        emit FondoRetirado(_grupoId, msg.sender, miAporteConIntereses, miAporteConIntereses - miAporteOriginal);
    }

    // ============ Funciones de Consulta ============

    /**
     * @notice Obtiene la información de un grupo
     * @param _grupoId ID del grupo
     * @return id ID del grupo
     * @return creador Dirección del creador
     * @return nombre Nombre del grupo
     * @return objetivo Meta en wei
     * @return totalRecaudado Total depositado originalmente
     * @return totalEnAave Total actualmente en Aave (con intereses)
     * @return fechaObjetivo Timestamp de la fecha límite
     * @return descripcion Descripción
     * @return activo Si el grupo está activo
     * @return metaAlcanzada Si se alcanzó la meta
     */
    function obtenerGrupo(
        uint256 _grupoId
    )
        external
        view
        returns (
            uint256 id,
            address creador,
            string memory nombre,
            uint256 objetivo,
            uint256 totalRecaudado,
            uint256 totalEnAave,
            uint256 fechaObjetivo,
            string memory descripcion,
            bool activo,
            bool metaAlcanzada
        )
    {
        Grupo storage grupo = grupos[_grupoId];
        return (
            grupo.id,
            grupo.creador,
            grupo.nombre,
            grupo.objetivo,
            grupo.totalRecaudado,
            grupo.totalEnAave,
            grupo.fechaObjetivo,
            grupo.descripcion,
            grupo.activo,
            grupo.metaAlcanzada
        );
    }

    /**
     * @notice Obtiene el balance total del grupo incluyendo intereses de Aave
     * @param _grupoId ID del grupo
     * @return Balance total en wei (incluye intereses si está en Aave)
     */
    function obtenerBalanceTotal(uint256 _grupoId) public view returns (uint256) {
        Grupo storage grupo = grupos[_grupoId];
        
        if (usarAave && grupo.totalEnAave > 0 && address(aavePool) != address(0)) {
            // Obtener balance actual de Aave (incluye intereses)
            uint256 balanceAave = aWETH.balanceOf(address(this));
            return balanceAave;
        } else {
            // Si no se usa Aave, retornar balance del contrato
            return address(this).balance;
        }
    }

    /**
     * @notice Calcula los intereses generados hasta el momento
     * @param _grupoId ID del grupo
     * @return Intereses generados en wei
     */
    function calcularIntereses(uint256 _grupoId) external view returns (uint256) {
        Grupo storage grupo = grupos[_grupoId];
        uint256 balanceTotal = obtenerBalanceTotal(_grupoId);
        
        if (balanceTotal > grupo.totalRecaudado) {
            return balanceTotal - grupo.totalRecaudado;
        }
        return 0;
    }

    /**
     * @notice Obtiene la lista de participantes de un grupo
     * @param _grupoId ID del grupo
     * @return Lista de direcciones de participantes
     */
    function obtenerParticipantes(
        uint256 _grupoId
    ) external view returns (address[] memory) {
        return grupos[_grupoId].participantes;
    }

    /**
     * @notice Obtiene el aporte de un participante en un grupo
     * @param _grupoId ID del grupo
     * @param _participante Dirección del participante
     * @return Cantidad aportada originalmente en wei
     */
    function obtenerAporte(
        uint256 _grupoId,
        address _participante
    ) external view returns (uint256) {
        return grupos[_grupoId].aportes[_participante];
    }

    /**
     * @notice Obtiene el aporte de un participante con intereses proporcionales
     * @param _grupoId ID del grupo
     * @param _participante Dirección del participante
     * @return Cantidad con intereses en wei
     */
    function obtenerAporteConIntereses(
        uint256 _grupoId,
        address _participante
    ) external view returns (uint256) {
        Grupo storage grupo = grupos[_grupoId];
        uint256 aporteOriginal = grupo.aportes[_participante];
        
        if (aporteOriginal == 0 || grupo.totalRecaudado == 0) {
            return 0;
        }
        
        uint256 balanceTotal = obtenerBalanceTotal(_grupoId);
        uint256 porcentaje = (aporteOriginal * 100) / grupo.totalRecaudado;
        return (balanceTotal * porcentaje) / 100;
    }

    /**
     * @notice Obtiene los grupos de un usuario
     * @param _usuario Dirección del usuario
     * @return Lista de IDs de grupos
     */
    function obtenerGruposPorUsuario(
        address _usuario
    ) external view returns (uint256[] memory) {
        return gruposPorUsuario[_usuario];
    }

    /**
     * @notice Calcula el porcentaje completado de un grupo
     * @param _grupoId ID del grupo
     * @return Porcentaje (0-100)
     */
    function obtenerPorcentajeCompletado(
        uint256 _grupoId
    ) external view returns (uint256) {
        Grupo storage grupo = grupos[_grupoId];
        if (grupo.objetivo == 0) return 0;
        
        uint256 balanceTotal = obtenerBalanceTotal(_grupoId);
        return (balanceTotal * 100) / grupo.objetivo;
    }

    // ============ Funciones de Emergencia ============

    /**
     * @notice Permite al creador retirar emergencia de Aave
     * @param _grupoId ID del grupo
     */
    function retiroEmergenciaAave(uint256 _grupoId) external soloCreador(_grupoId) {
        // Esta función permite retirar de Aave sin las validaciones normales
        // Úsala solo en caso de emergencia
        Grupo storage grupo = grupos[_grupoId];
        if (grupos[_grupoId].totalEnAave > 0 && usarAave) {
            uint256 cantidadRetirada = _retirarDeAave(type(uint256).max);
            grupo.totalEnAave = 0;
            emit FondosRetiradosDeAave(_grupoId, cantidadRetirada);
        }
    }

    // Permitir que el contrato reciba ETH
    receive() external payable {}
}

