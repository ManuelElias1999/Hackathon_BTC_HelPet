;; Definir el token HelPet
(define-fungible-token HelPet)

;; Definir variables de datos para almacenar al owner, el token HelPet y el contrato del registrar
(define-data-var owner principal tx-sender)
(define-data-var helPet-contract (optional principal) none) ;; Variable para HelPet
(define-data-var registrar-contract (optional principal) none) ;; Variable para registrar
(define-map products uint { creator: principal, stock: uint, price: uint }) ;; Mapa para productos
(define-data-var product-counter uint u1) ;; Contador de productos

;; Inicializar el contrato
(define-private (initialize)
  (var-set owner tx-sender))

;; Ejecutar la funcion de inicializacion al desplegar el contrato
(begin
  (initialize))

;; Funcion para agregar un nuevo producto (solo la empresa puede hacerlo)
(define-public (add-product (stock uint) (price uint))
  (begin
    ;; Obtener el ID del producto
    (let ((product-id (var-get product-counter)))
      ;; Asegurarse de que el stock y el precio sean mayores a cero
      (asserts! (> stock u0) (err "El stock debe ser mayor a 0"))
      (asserts! (> price u0) (err "El precio debe ser mayor a 0"))

      ;; Agregar el producto al mapa
      (map-set products product-id { creator: tx-sender, stock: stock, price: price })

      ;; Incrementar el contador de productos
      (var-set product-counter (+ product-id u1))

      (ok "Producto creado exitosamente"))))

;; Funcion para canjear un producto
(define-public (canjear (product-id uint))
  (let ((product (map-get? products product-id)))
    (asserts! (is-some product) (err "ID de producto no existe"))
    (let ((product-details (unwrap-panic product)))
      ;; Verificar si hay stock disponible
      (asserts! (> (get stock product-details) u0) (err "No hay stock disponible"))

      ;; Obtener el precio del producto
      (let ((price (get price product-details)))
        ;; Verificar que el usuario ha transferido suficientes tokens HelPet
        (asserts! (>= (ft-get-balance HelPet tx-sender) price) (err "No tienes suficientes tokens HelPet"))

        ;; Transferir los tokens HelPet al contrato para su quema
        (match (ft-transfer? HelPet price tx-sender (unwrap-panic (var-get helPet-contract)))
          transfer-success
            (begin
              ;; Quemar los tokens HelPet que se han transferido al contrato
              (match (ft-burn? HelPet price (unwrap-panic (var-get helPet-contract)))
                burn-success
                  (begin
                    ;; Descontar el stock del producto
                    (map-set products product-id { creator: (get creator product-details), stock: (- (get stock product-details) u1), price: price })
                    ;; Retornar el mensaje de exito
                    (ok "Producto canjeado exitosamente"))
                burn-error (err "Error al quemar tokens"))
              (ok "Producto canjeado exitosamente"))
          transfer-error (err "Error al transferir tokens")))))

;; Asignar la direccion del contrato HelPet (solo el owner puede hacerlo)
(define-public (set-helpet-contract (contract principal))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err "Solo el owner puede asignar el contrato HelPet"))
    (var-set helPet-contract (some contract))
    (ok "Contrato HelPet asignado con exito")))

;; Asignar la direccion del contrato Registrar (solo el owner puede hacerlo)
(define-public (set-registrar-contract (contract principal))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err "Solo el owner puede asignar el contrato Registrar"))
    (var-set registrar-contract (some contract))
    (ok "Contrato Registrar asignado con exito")))
