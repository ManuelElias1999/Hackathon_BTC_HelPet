;; Definir variables de datos para almacenar al owner y los roles
(define-data-var owner principal tx-sender)
(define-map roles principal { is-user: bool, is-company: bool })

;; Funcion para asignar un rol a una wallet (solo el owner puede asignar)
(define-public (assign-role (wallet principal) (role-type uint))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err "Solo el owner puede asignar roles"))

    (if (is-eq role-type u1)
        (ok (map-set roles wallet { is-user: true, is-company: false }))
        (if (is-eq role-type u2)
            (ok (map-set roles wallet { is-user: false, is-company: true }))
            (err "Tipo de rol invalido")))
    ))
    
;; Funcion para verificar si una wallet es un usuario
(define-read-only (is-user (wallet principal))
  (default-to false (get is-user (map-get? roles wallet))))

;; Funcion para verificar si una wallet es una empresa
(define-read-only (is-company (wallet principal))
  (default-to false (get is-company (map-get? roles wallet))))

;; Funcion de inicializacion para transferir el control del contrato al owner
(define-private (initialize)
  (var-set owner tx-sender))

;; Ejecutar la funcion de inicializacion al desplegar el contrato
(begin
  (initialize))
