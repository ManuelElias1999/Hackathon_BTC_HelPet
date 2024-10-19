;; Definir el token HelPet
(define-fungible-token HelPet)

;; Definir variables de datos para almacenar al owner y las donaciones
(define-data-var owner principal tx-sender)
(define-map donations uint { creator: principal, amount: uint, status: bool })

;; Funcion para crear una nueva donacion
(define-public (create-donation (donation-id uint) (amount uint))
  (begin
    ;; Verificar que el id de donacion no exista
    (asserts! (is-none (map-get? donations donation-id)) (err "ID de donacion ya existe"))
    
    ;; Agregar la donacion al mapa
    (map-set donations donation-id { creator: tx-sender, amount: amount, status: true })
    
    (ok "Donacion creada exitosamente")))

;; Funcion para cancelar una donacion (solo el creador o el owner pueden cerrarla)
(define-public (close-donation (donation-id uint))
  (begin
    (let ((donation (map-get donations donation-id)))
      ;; Verificar que la donacion existe
      (asserts! (is-some donation) (err "ID de donacion no existe"))
      (let ((donation-details (unwrap donation)))
        ;; Verificar que el que cierra es el creador o el owner
        (asserts! (or (is-eq tx-sender (get creator donation-details))
                       (is-eq tx-sender (var-get owner))) (err "Solo el creador o owner pueden cerrar la donacion"))
        ;; Actualizar el estado de la donacion
        (map-set donations donation-id { creator: (get creator donation-details), amount: (get amount donation-details), status: false })
        (ok "Donacion cerrada exitosamente")))))

;; Funcion para realizar una donacion
(define-public (donate (donation-id uint) (amount uint))
  (begin
    (let ((donation (map-get donations donation-id)))
      ;; Verificar que la donacion este abierta
      (asserts! (and (is-some donation) (get status (unwrap donation))) (err "La donacion no esta abierta"))
      
      ;; Transferir el monto de la donacion
      (ft-transfer? HelPet amount (get creator (unwrap donation)))
      
      ;; Transferir 3% a la wallet de comision
      (let ((commission (* amount 3/100)))
        (ft-transfer? HelPet commission "ST1FSFVBJ5GTF24MP99P9RPQ34Q42VWES78PCNTQT"))
      
      ;; Transferir 50 tokens HelPet al donante
      (ft-transfer? HelPet 50 tx-sender)
      
      (ok "Donacion realizada exitosamente"))))

;; Funcion de inicializacion para transferir el control del contrato al owner
(define-private (initialize)
  (var-set owner tx-sender))

;; Ejecutar la funcion de inicializacion al desplegar el contrato
(begin
  (initialize))