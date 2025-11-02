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
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IAToken is IERC20 {
    // Los aTokens son tokens que representan depósitos en Aave
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256) external;
    function approve(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
}

/**
 * @title GruposAhorroConAaveMultisig
 * @notice Contrato para gestionar grupos de ahorro con multisig para aprobación de retiros
 * @dev Permite crear grupos con sistema de multisig donde varios participantes deben aprobar retiros
 */
contract GruposAhorroConAaveMultisig {

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
        mapping(address => uint256) aportes; // Aportes por participante
        
        // Sistema Multisig
        uint256 quorum; // Número mínimo de aprobaciones necesarias (ej: 2 de 3)
        mapping(address => bool) esAprobador; // Quienes pueden aprobar
        mapping(uint256 => SolicitudRetiro) solicitudesRetiro; // Historial de solicitudes
        uint256 totalSolicitudes; // Contador de solicitudes
    }
    
    struct SolicitudRetiro {
        uint256 id;
        uint256 grupoId;
        address solicitante; // Quien solicita el retiro
        address destinatario; // A dónde enviar los fondos
        uint256 cantidad; // Cantidad solicitada
        bool ejecutada; // Si ya se ejecutó
        uint256 timestamp; // Cuándo se solicitó
        mapping(address => bool) aprobaciones; // Quienes han aprobado
        uint256 numAprobaciones; // Contador de aprobaciones
    }

    // ============ Variables de Estado ============
    
    uint256 public totalGrupos;
    mapping(uint256 => Grupo) public grupos;
    mapping(address => uint256[]) public gruposPorUsuario;
    
    // Direcciones de Aave
    IAavePool public immutable aavePool;
    IWETH public immutable weth;
    IAToken public immutable aWETH;
    bool public usarAave;

    // ============ Eventos ============
    
    event GrupoCreado(
        uint256 indexed grupoId,
        address indexed creador,
        string nombre,
        uint256 objetivo,
        uint256 fechaObjetivo,
        uint256 quorum
    );
    
    event AporteRealizado(
        uint256 indexed grupoId,
        address indexed participante,
        uint256 cantidad,
        uint256 totalRecaudado,
        uint256 totalEnAave
    );
    
    event MetaAlcanzada(uint256 indexed grupoId, uint256 totalRecaudado);
    
    event SolicitudRetiroCreada(
        uint256 indexed solicitudId,
        uint256 indexed grupoId,
        address indexed solicitante,
        address destinatario,
        uint256 cantidad
    );
    
    event AprobacionAgregada(
        uint256 indexed solicitudId,
        uint256 indexed grupoId,
        address indexed aprobador,
        uint256 numAprobaciones,
        uint256 quorum
    );
    
    event RetiroEjecutado(
        uint256 indexed solicitudId,
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
    
    modifier soloAprobador(uint256 _grupoId) {
        require(
            grupos[_grupoId].esAprobador[msg.sender],
            "No eres un aprobador autorizado"
        );
        _;
    }

    // ============ Funciones Públicas ============

    /**
     * @notice Crea un nuevo grupo de ahorro con sistema multisig
     * @param _nombre Nombre del grupo
     * @param _objetivo Meta en wei
     * @param _fechaObjetivo Timestamp de la fecha límite
     * @param _descripcion Descripción del grupo
     * @param _quorum Número mínimo de aprobaciones necesarias para retirar fondos
     * @param _aprobadores Lista de direcciones que pueden aprobar retiros
     * @return grupoId ID del grupo creado
     */
    function crearGrupo(
        string memory _nombre,
        uint256 _objetivo,
        uint256 _fechaObjetivo,
        string memory _descripcion,
        uint256 _quorum,
        address[] memory _aprobadores
    ) external returns (uint256) {
        require(_objetivo > 0, "El objetivo debe ser mayor a 0");
        require(
            _fechaObjetivo > block.timestamp,
            "La fecha objetivo debe ser en el futuro"
        );
        require(bytes(_nombre).length > 0, "El nombre no puede estar vacio");
        require(_quorum > 0, "El quorum debe ser mayor a 0");
        require(_aprobadores.length > 0, "Debe haber al menos un aprobador");
        require(
            _quorum <= _aprobadores.length,
            "El quorum no puede ser mayor al numero de aprobadores"
        );

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
        nuevoGrupo.quorum = _quorum;
        
        // Configurar aprobadores
        for (uint256 i = 0; i < _aprobadores.length; i++) {
            require(_aprobadores[i] != address(0), "Direccion invalida");
            nuevoGrupo.esAprobador[_aprobadores[i]] = true;
        }
        
        // Agregar al creador como primer participante
        nuevoGrupo.participantes.push(msg.sender);
        gruposPorUsuario[msg.sender].push(nuevoId);

        emit GrupoCreado(nuevoId, msg.sender, _nombre, _objetivo, _fechaObjetivo, _quorum);
        
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
        
        grupo.aportes[msg.sender] += cantidadOriginal;
        grupo.totalRecaudado += cantidadOriginal;
        
        // Depositar en Aave para generar rendimiento
        if (usarAave && address(aavePool) != address(0)) {
            _depositarEnAave(cantidadOriginal);
            grupo.totalEnAave += cantidadOriginal;
            emit FondosDepositadosEnAave(_grupoId, cantidadOriginal);
        } else {
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
     * @notice Crea una solicitud de retiro que requiere aprobaciones multisig
     * @param _grupoId ID del grupo
     * @param _destinatario Dirección donde enviar los fondos
     * @return solicitudId ID de la solicitud creada
     */
    function solicitarRetiro(
        uint256 _grupoId,
        address _destinatario
    ) external soloActivo(_grupoId) soloParticipante(_grupoId) returns (uint256) {
        require(_destinatario != address(0), "Direccion invalida");
        
        Grupo storage grupo = grupos[_grupoId];
        require(
            grupo.metaAlcanzada || 
            block.timestamp > grupo.fechaObjetivo,
            "No se puede retirar: la meta no se alcanzo y la fecha no ha pasado"
        );
        
        uint256 balanceTotal = obtenerBalanceTotal(_grupoId);
        require(balanceTotal > 0, "No hay fondos para retirar");

        uint256 solicitudId = grupo.totalSolicitudes++;
        SolicitudRetiro storage solicitud = grupo.solicitudesRetiro[solicitudId];
        
        solicitud.id = solicitudId;
        solicitud.grupoId = _grupoId;
        solicitud.solicitante = msg.sender;
        solicitud.destinatario = _destinatario;
        solicitud.cantidad = balanceTotal;
        solicitud.ejecutada = false;
        solicitud.timestamp = block.timestamp;
        solicitud.numAprobaciones = 0;

        emit SolicitudRetiroCreada(solicitudId, _grupoId, msg.sender, _destinatario, balanceTotal);
        
        return solicitudId;
    }

    /**
     * @notice Permite a un aprobador aprobar una solicitud de retiro
     * @param _grupoId ID del grupo
     * @param _solicitudId ID de la solicitud a aprobar
     */
    function aprobarRetiro(
        uint256 _grupoId,
        uint256 _solicitudId
    ) external soloAprobador(_grupoId) {
        Grupo storage grupo = grupos[_grupoId];
        SolicitudRetiro storage solicitud = grupo.solicitudesRetiro[_solicitudId];
        
        require(solicitud.id == _solicitudId, "Solicitud no existe");
        require(!solicitud.ejecutada, "La solicitud ya fue ejecutada");
        require(
            !solicitud.aprobaciones[msg.sender],
            "Ya aprobaste esta solicitud"
        );

        solicitud.aprobaciones[msg.sender] = true;
        solicitud.numAprobaciones++;

        emit AprobacionAgregada(
            _solicitudId,
            _grupoId,
            msg.sender,
            solicitud.numAprobaciones,
            grupo.quorum
        );

        // Si se alcanzó el quorum, ejecutar automáticamente
        if (solicitud.numAprobaciones >= grupo.quorum) {
            _ejecutarRetiro(_grupoId, _solicitudId);
        }
    }

    /**
     * @notice Ejecuta una solicitud de retiro que ya tiene las aprobaciones necesarias
     * @param _grupoId ID del grupo
     * @param _solicitudId ID de la solicitud a ejecutar
     */
    function ejecutarRetiro(
        uint256 _grupoId,
        uint256 _solicitudId
    ) external {
        Grupo storage grupo = grupos[_grupoId];
        SolicitudRetiro storage solicitud = grupo.solicitudesRetiro[_solicitudId];
        
        require(solicitud.id == _solicitudId, "Solicitud no existe");
        require(!solicitud.ejecutada, "La solicitud ya fue ejecutada");
        require(
            solicitud.numAprobaciones >= grupo.quorum,
            "No se ha alcanzado el quorum necesario"
        );

        _ejecutarRetiro(_grupoId, _solicitudId);
    }

    /**
     * @notice Ejecuta internamente el retiro de fondos
     * @param _grupoId ID del grupo
     * @param _solicitudId ID de la solicitud
     */
    function _ejecutarRetiro(uint256 _grupoId, uint256 _solicitudId) internal {
        Grupo storage grupo = grupos[_grupoId];
        SolicitudRetiro storage solicitud = grupo.solicitudesRetiro[_solicitudId];
        
        uint256 cantidadOriginal = grupo.totalRecaudado;
        uint256 interesesGenerados = 0;

        // Retirar de Aave si se está usando
        if (usarAave && grupo.totalEnAave > 0 && address(aavePool) != address(0)) {
            uint256 cantidadRetirada = _retirarDeAave(type(uint256).max);
            interesesGenerados = cantidadRetirada > cantidadOriginal ? cantidadRetirada - cantidadOriginal : 0;
            emit FondosRetiradosDeAave(_grupoId, cantidadRetirada);
        } else {
            uint256 ethBalance = address(this).balance;
            if (ethBalance >= solicitud.cantidad) {
                interesesGenerados = solicitud.cantidad > cantidadOriginal ? solicitud.cantidad - cantidadOriginal : 0;
            }
        }

        // Transferir fondos al destinatario
        uint256 cantidadFinal = address(this).balance;
        require(cantidadFinal > 0, "No hay fondos para transferir");
        
        (bool success, ) = payable(solicitud.destinatario).call{value: cantidadFinal}("");
        require(success, "Error al transferir fondos");

        // Actualizar estado
        grupo.totalRecaudado = 0;
        grupo.totalEnAave = 0;
        grupo.activo = false;
        solicitud.ejecutada = true;

        emit RetiroEjecutado(_solicitudId, _grupoId, solicitud.destinatario, cantidadFinal, interesesGenerados);
    }

    /**
     * @notice Permite a un participante retirar su aporte individual si la fecha pasó y no se alcanzó la meta
     * @param _grupoId ID del grupo
     */
    function retirarMiAporte(uint256 _grupoId) external soloParticipante(_grupoId) {
        require(
            block.timestamp > grupos[_grupoId].fechaObjetivo,
            "La fecha objetivo no ha pasado"
        );
        require(
            !grupos[_grupoId].metaAlcanzada,
            "La meta fue alcanzada, se debe usar el sistema multisig"
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

        emit RetiroEjecutado(0, _grupoId, msg.sender, miAporteConIntereses, miAporteConIntereses - miAporteOriginal);
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

    // ============ Funciones de Consulta ============

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
            bool metaAlcanzada,
            uint256 quorum
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
            grupo.metaAlcanzada,
            grupo.quorum
        );
    }

    function obtenerBalanceTotal(uint256 _grupoId) public view returns (uint256) {
        Grupo storage grupo = grupos[_grupoId];
        
        if (usarAave && grupo.totalEnAave > 0 && address(aavePool) != address(0)) {
            uint256 balanceAave = aWETH.balanceOf(address(this));
            return balanceAave;
        } else {
            return address(this).balance;
        }
    }

    function obtenerSolicitudRetiro(
        uint256 _grupoId,
        uint256 _solicitudId
    )
        external
        view
        returns (
            uint256 id,
            address solicitante,
            address destinatario,
            uint256 cantidad,
            bool ejecutada,
            uint256 timestamp,
            uint256 numAprobaciones,
            uint256 quorum
        )
    {
        Grupo storage grupo = grupos[_grupoId];
        SolicitudRetiro storage solicitud = grupo.solicitudesRetiro[_solicitudId];
        
        return (
            solicitud.id,
            solicitud.solicitante,
            solicitud.destinatario,
            solicitud.cantidad,
            solicitud.ejecutada,
            solicitud.timestamp,
            solicitud.numAprobaciones,
            grupo.quorum
        );
    }

    function verificarAprobacion(
        uint256 _grupoId,
        uint256 _solicitudId,
        address _aprobador
    ) external view returns (bool) {
        return grupos[_grupoId].solicitudesRetiro[_solicitudId].aprobaciones[_aprobador];
    }

    function obtenerParticipantes(
        uint256 _grupoId
    ) external view returns (address[] memory) {
        return grupos[_grupoId].participantes;
    }

    function obtenerAporte(
        uint256 _grupoId,
        address _participante
    ) external view returns (uint256) {
        return grupos[_grupoId].aportes[_participante];
    }

    function obtenerGruposPorUsuario(
        address _usuario
    ) external view returns (uint256[] memory) {
        return gruposPorUsuario[_usuario];
    }

    function esAprobador(
        uint256 _grupoId,
        address _direccion
    ) external view returns (bool) {
        return grupos[_grupoId].esAprobador[_direccion];
    }

    receive() external payable {}
}

