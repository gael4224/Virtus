// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title GruposAhorro
 * @notice Contrato para gestionar grupos de ahorro colectivos
 * @dev Permite crear grupos, aportar fondos y retirar cuando se alcance la meta
 */
contract GruposAhorro {
    // ============ Estructuras ============
    
    struct Grupo {
        uint256 id;
        address creador;
        string nombre;
        uint256 objetivo; // Meta en wei
        uint256 totalRecaudado; // Total recaudado en wei
        uint256 fechaObjetivo; // Timestamp de la fecha límite
        string descripcion;
        bool activo;
        bool metaAlcanzada;
        address[] participantes;
        mapping(address => uint256) aportes; // Aportes por participante
    }

    // ============ Variables de Estado ============
    
    uint256 public totalGrupos;
    mapping(uint256 => Grupo) public grupos;
    mapping(address => uint256[]) public gruposPorUsuario; // IDs de grupos por usuario

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
        uint256 totalRecaudado
    );
    
    event MetaAlcanzada(uint256 indexed grupoId, uint256 totalRecaudado);
    
    event FondoRetirado(
        uint256 indexed grupoId,
        address indexed destinatario,
        uint256 cantidad
    );
    
    event ParticipanteAgregado(uint256 indexed grupoId, address indexed participante);

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
        grupo.aportes[msg.sender] += msg.value;
        grupo.totalRecaudado += msg.value;

        // Verificar si se alcanzó la meta
        if (grupo.totalRecaudado >= grupo.objetivo && !grupo.metaAlcanzada) {
            grupo.metaAlcanzada = true;
            emit MetaAlcanzada(_grupoId, grupo.totalRecaudado);
        }

        emit AporteRealizado(_grupoId, msg.sender, msg.value, grupo.totalRecaudado);
    }

    /**
     * @notice Permite al creador retirar los fondos cuando se alcanza la meta o pasa la fecha
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
        
        uint256 cantidad = grupos[_grupoId].totalRecaudado;
        require(cantidad > 0, "No hay fondos para retirar");

        grupos[_grupoId].totalRecaudado = 0;
        grupos[_grupoId].activo = false;

        (bool success, ) = payable(_destinatario).call{value: cantidad}("");
        require(success, "Error al transferir fondos");

        emit FondoRetirado(_grupoId, _destinatario, cantidad);
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

        uint256 miAporte = grupos[_grupoId].aportes[msg.sender];
        require(miAporte > 0, "No tienes aportes para retirar");

        grupos[_grupoId].aportes[msg.sender] = 0;
        grupos[_grupoId].totalRecaudado -= miAporte;

        (bool success, ) = payable(msg.sender).call{value: miAporte}("");
        require(success, "Error al transferir fondos");

        emit FondoRetirado(_grupoId, msg.sender, miAporte);
    }

    // ============ Funciones de Consulta ============

    /**
     * @notice Obtiene la información de un grupo
     * @param _grupoId ID del grupo
     * @return id ID del grupo
     * @return creador Dirección del creador
     * @return nombre Nombre del grupo
     * @return objetivo Meta en wei
     * @return totalRecaudado Total recaudado en wei
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
            grupo.fechaObjetivo,
            grupo.descripcion,
            grupo.activo,
            grupo.metaAlcanzada
        );
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
     * @return Cantidad aportada en wei
     */
    function obtenerAporte(
        uint256 _grupoId,
        address _participante
    ) external view returns (uint256) {
        return grupos[_grupoId].aportes[_participante];
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
        return (grupo.totalRecaudado * 100) / grupo.objetivo;
    }
}

