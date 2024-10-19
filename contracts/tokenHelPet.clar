;; Definir el token HelPet
(define-fungible-token HelPet)

;; Definir variables de datos para almacenar al owner y los agentes autorizados
(define-data-var owner principal tx-sender)
(define-map agents principal bool)

;; Funcion para verificar si un usuario es un agente autorizado
(define-read-only (is-agent (agent principal))
  (default-to false (map-get? agents agent)))

;; Funcion para agregar un agente (solo el owner puede agregar)
(define-public (add-agent (agent principal))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err "Solo el owner puede agregar agentes"))
    (map-set agents agent true)
    (ok "Agente agregado con exito")))

;; Funcion para remover un agente (solo el owner puede remover)
(define-public (remove-agent (agent principal))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err "Solo el owner puede remover agentes"))
    (map-delete agents agent)
    (ok "Agente removido con exito")))

;; Funcion para mintear tokens HelPet (solo agentes autorizados pueden mintear)
(define-public (mint (amount uint))
  (begin
    (asserts! (is-agent tx-sender) (err u403))
    (ft-mint? HelPet amount tx-sender)))

;; Funcion de inicializacion para transferir el control del contrato al owner
(define-private (initialize)
  (var-set owner tx-sender))

;; Ejecutar la funcion de inicializacion al desplegar el contrato
(begin
  (initialize))
