;; Definir el token HelPet y el contrato BuscoA
(define-fungible-token HelPet)

(use-trait usdt-trait 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.token-susdt.token-trait)

;; Definir variables de datos
(define-data-var owner principal tx-sender)
(define-data-var helPet-contract (optional principal) none)
(define-data-var usdt-contract (optional principal) none) ;; Variable para el contrato de USDT
(define-data-var registrar-contract (optional principal) none) ;; Variable para registrar
(define-map posts { id: uint } { owner: principal, reward: uint, found: bool })
(define-data-var post-counter uint u1)

;; Wallet de comision
(define-constant commission-wallet 'ST1FSFVBJ5GTF24MP99P9RPQ34Q42VWES78PCNTQT)

;; Porcentaje de comision (3% para la recompensa y 1% para cancelacion)
(define-constant commission-rate u3)
(define-constant cancel-commission-rate u1)

;; Verificar si el usuario es el owner del contrato
(define-read-only (is-owner (user principal))
  (is-eq user (var-get owner)))

;; Asignar la direccion del contrato de USDT (solo el owner puede hacerlo)
(define-public (set-usdt-contract (contract <usdt-trait>))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err "Solo el owner puede asignar el contrato USDT"))
    (var-set usdt-contract (some contract))
    (ok "Contrato USDT asignado con exito")
  )
)

;; Crear un nuevo post con la recompensa en sUSDT, solo si el monto es mayor a cero
(define-public (create-post (reward uint))
  (begin
    (asserts! (> reward u0) (err "El monto de la recompensa debe ser mayor a cero"))
    (let ((id (var-get post-counter)))
      (map-set posts { id: id } { owner: tx-sender, reward: reward, found: false })
      (var-set post-counter (+ id u1))

      ;; Transferir sUSDT desde el usuario al contrato
      (match (var-get usdt-contract)
        some usdt-contract
        (as-contract (contract-call? usdt-contract transfer reward tx-sender (as-contract tx-sender) none))
        none (err "Contrato USDT no asignado")
      )

      (ok id)
    )
  )
)

;; Marcar al perro como encontrado y transferir la recompensa en sUSDT
(define-public (claim-reward (id uint) (finder principal))
  (let ((post (map-get? posts { id: id })))
    (match post
      some-post
      (begin
        (asserts! (not (get found some-post)) (err "El perro ya fue encontrado"))
        (asserts! (is-eq tx-sender (get owner some-post)) (err "Solo el duenho del post puede marcar al perro como encontrado"))

        (let ((reward (get reward some-post))
              (commission (/ (* reward commission-rate) u100))
              (finder-reward (- reward commission)))
          (match (var-get usdt-contract)
            usdt-contract
            (begin
              (try! (contract-call? usdt-contract transfer commission (as-contract tx-sender) commission-wallet none))
              (try! (contract-call? usdt-contract transfer finder-reward (as-contract tx-sender) finder none))

              (map-set posts { id: id } { owner: tx-sender, reward: reward, found: true })

              (match (var-get helPet-contract)
                helPet-contract (try! (contract-call? helPet-contract mint u50 finder))
                (err "Contrato HelPet no asignado")
              )

              (ok "Recompensa reclamada con exito")
            )
            (err "Contrato USDT no asignado")
          )
        )
      )
      (err "Post no encontrado")
    )
  )
)

;; Cancelar el post y devolver la recompensa (99% al duenho del post, 1% de comision)
(define-public (cancel-post (id uint))
  (let ((post (map-get? posts { id: id })))
    (match post
      some-post
      (begin
        (asserts! (or (is-eq tx-sender (get owner some-post)) (is-eq tx-sender (var-get owner))) (err "Solo el duenho del post o el owner pueden cancelarlo"))
        (asserts! (not (get found some-post)) (err "El perro ya fue encontrado"))

        (let ((reward (get reward some-post))
              (commission (/ (* reward cancel-commission-rate) u100))
              (refund (- reward commission)))
          (match (var-get usdt-contract)
            some usdt-contract
            (begin
              (try! (contract-call? usdt-contract transfer commission (as-contract tx-sender) commission-wallet none))
              (try! (contract-call? usdt-contract transfer refund (as-contract tx-sender) (get owner some-post) none))

              (map-delete posts { id: id })
              
              (ok "Post cancelado y recompensa devuelta")
            )
            none (err "Contrato USDT no asignado")
          )
        )
      )
      none (err "Post no encontrado")
    )
  )
)

;; Asignar la direccion del contrato HelPet (solo el owner puede hacerlo)
(define-public (set-helpet-contract (contract principal))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err "Solo el owner puede asignar el contrato HelPet"))
    (var-set helPet-contract (some contract))
    (ok "Contrato HelPet asignado con exito")
  )
)

;; Asignar la direccion del contrato Registrar (solo el owner puede hacerlo)
(define-public (set-registrar-contract (contract principal))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err "Solo el owner puede asignar el contrato Registrar"))
    (var-set registrar-contract (some contract))
    (ok "Contrato Registrar asignado con exito")
  )
)

;; Verificar si un usuario o empresa esta registrado (se llama al contrato de registro)
(define-public (is-registered (user principal))
  (match (var-get registrar-contract)
    some registrar
    (contract-call? registrar is-registered user)
    none (err "No hay un contrato de registro establecido")
  )
)

;; Inicializacion del contrato para establecer el owner
(define-private (initialize)
  (var-set owner tx-sender))

(begin
  (initialize))
