;; Definir el token HelPet y el contrato BuscoA
(define-fungible-token HelPet)

;; Definir variables de datos
(define-data-var owner principal tx-sender)
(define-map posts { id: uint } { owner: principal, reward: uint, found: bool })
(define-data-var post-counter uint u1)

;; Direccion del contrato de sUSDT
(define-constant usdt-contract '0x9726cd7b0e1be8ce4fd749983716ad6aaf98611fb5554ffde61b6ace78c035e6')

;; Wallet de comision
(define-constant commission-wallet 'ST1FSFVBJ5GTF24MP99P9RPQ34Q42VWES78PCNTQT)

;; Porcentaje de comision (3% para la recompensa y 1% para cancelacion)
(define-constant commission-rate u3)
(define-constant cancel-commission-rate u1)

;; Verificar si el usuario es el owner del contrato
(define-read-only (is-owner (user principal))
  (is-eq user (var-get owner)))

;; Crear un nuevo post con la recompensa en USDC, solo si el monto es mayor a cero
(define-public (create-post (reward uint))
  (begin
    (asserts! (> reward u0) (err "El monto de la recompensa debe ser mayor a cero"))
    (let ((id (var-get post-counter)))
      (map-set posts { id: id } { owner: tx-sender, reward: reward, found: false })
      (var-set post-counter (+ id u1))

      ;; Transferir USDC desde el usuario al contrato
      (ft-transfer? 'USDC reward tx-sender contract-principal usdc-contract)

      (ok id)
    )
  )
)

;; Marcar al perro como encontrado y transferir la recompensa en USDC
(define-public (claim-reward (id uint) (finder principal))
  (let (
        (post (map-get? posts { id: id }))
    )
    (match post
      some-post
      (begin
        (asserts! (not (get found some-post)) (err "El perro ya fue encontrado"))
        (asserts! (is-eq tx-sender (get owner some-post)) (err "Solo el dueno del post puede marcar al perro como encontrado"))

        ;; Calcular la recompensa y la comision
        (let (
          (reward (get reward some-post))
          (commission (/ (* reward commission-rate) u100))
          (finder-reward (- reward commission))
        )
          ;; Transferir la recompensa y la comision en USDC
          (ft-transfer? 'USDC commission contract-principal commission-wallet usdc-contract)
          (ft-transfer? 'USDC finder-reward contract-principal finder usdc-contract)

          ;; Marcar como encontrado
          (map-set posts { id: id } { owner: tx-sender, reward: reward, found: true })

          ;; Mint de 50 tokens HelPet para el encontrador
          (ft-mint? HelPet u50 finder)

          (ok "Recompensa reclamada con exito")
        )
      )
      none (err "Post no encontrado")
    )
  )
)

;; Cancelar el post y devolver la recompensa (99% al dueno del post, 1% de comision)
(define-public (cancel-post (id uint))
  (let (
        (post (map-get? posts { id: id }))
    )
    (match post
      some-post
      (begin
        (asserts! (is-eq tx-sender (get owner some-post)) (err "Solo el dueno del post puede cancelarlo"))
        (asserts! (not (get found some-post)) (err "El perro ya fue encontrado"))

        ;; Calcular la comision y el reembolso
        (let (
          (reward (get reward some-post))
          (commission (/ (* reward cancel-commission-rate) u100))
          (refund (- reward commission))
        )
          ;; Transferir la comision y el reembolso en USDC
          (ft-transfer? 'USDC commission contract-principal commission-wallet usdc-contract)
          (ft-transfer? 'USDC refund contract-principal (get owner some-post) usdc-contract)

          ;; Eliminar el post
          (map-delete posts { id: id })
          
          (ok "Post cancelado y recompensa devuelta")
        )
      )
      none (err "Post no encontrado")
    )
  )
)

;; Inicializacion del contrato para establecer el owner
(define-private (initialize)
  (var-set owner tx-sender))

(begin
  (initialize))
