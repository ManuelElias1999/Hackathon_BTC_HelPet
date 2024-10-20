;; Definir el token HelPet
(define-fungible-token HelPet)

;; Definir variables de datos para almacenar al owner y las donaciones
(define-data-var owner principal tx-sender)
(define-data-var helPet-contract (optional principal) none) ;; Variable para HelPet
(define-data-var registrar-contract (optional principal) none) ;; Variable para registrar
(define-map donations uint { creator: principal, amount: uint, status: bool })
(define-data-var donation-counter uint u1) ;; Contador de donaciones

;; Wallet de comision
(define-constant commission-wallet 'ST1FSFVBJ5GTF24MP99P9RPQ34Q42VWES78PCNTQT)

;; Funcion para crear una nueva donacion
(define-public (create-donation (amount uint))
  (begin
    ;; Verificar que el id de donacion no exista
    (let ((donation-id (var-get donation-counter)))
      (asserts! (is-none (map-get? donations donation-id)) (err "ID de donacion ya existe"))
      
      ;; Agregar la donacion al mapa
      (map-set donations donation-id { creator: tx-sender, amount: amount, status: true })
      
      ;; Incrementar el contador de donaciones
      (var-set donation-counter (+ donation-id u1))

      (ok "Donacion creada exitosamente"))))

;; Funcion para cancelar una donacion (solo el creador o el owner pueden cerrarla)
(define-public (close-donation (donation-id uint))
  (begin
    (let ((donation (map-get? donations donation-id)))
      ;; Verificar que la donacion existe
      (asserts! (is-some donation) (err "ID de donacion no existe"))
      (let ((donation-details (unwrap-panic donation)))
        ;; Verificar que el que cierra es el creador o el owner
        (asserts! (or (is-eq tx-sender (get creator donation-details))
                       (is-eq tx-sender (var-get owner))) (err "Solo el creador o owner pueden cerrar la donacion"))
        ;; Actualizar el estado de la donacion
        (map-set donations donation-id { creator: (get creator donation-details), amount: (get amount donation-details), status: false })
        (ok "Donacion cerrada exitosamente")))))

;; Funcion para realizar una donacion
(define-public (donate (donation-id uint) (amount uint))
  (begin
    (let ((donation (map-get? donations donation-id)))
      ;; Verificar que la donacion este abierta
      (asserts! (and (is-some donation) (get status (unwrap-panic donation))) (err u0))
      
      ;; Transferir el monto de la donacion
      (try! (ft-transfer? HelPet amount tx-sender (get creator (unwrap-panic donation))))
      
      ;; Calcular y transferir 3% a la wallet de comision
      (let ((commission (/ (* amount u3) u100)))
        (try! (ft-transfer? HelPet commission tx-sender commission-wallet)))
      
      ;; Transferir 50 tokens HelPet al donante desde el contrato
      (try! (ft-transfer? HelPet u50 (as-contract tx-sender) tx-sender))
      
      (ok amount))))

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

;; Inicializacion del contrato para transferir el control del contrato al owner
(define-private (initialize)
  (var-set owner tx-sender))

;; Ejecutar la funcion de inicializacion al desplegar el contrato
(begin
  (initialize))
