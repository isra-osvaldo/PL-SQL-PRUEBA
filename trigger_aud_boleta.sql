--CREANDO EL TRIGGER
CREATE OR REPLACE TRIGGER boletas_aud
BEFORE INSERT OR UPDATE OR DELETE ON Boletas
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO aud_boleta (aud_folio, accion, fecha, usuario, monto)
        VALUES (:NEW.folio, 'I', SYSDATE, USER, :NEW.monto_total);
    ELSIF UPDATING THEN
        INSERT INTO aud_boleta (aud_folio, accion, fecha, usuario, monto)
        VALUES (:NEW.folio, 'U', SYSDATE, USER, :NEW.monto_total);
    ELSIF DELETING THEN
        INSERT INTO aud_boleta (aud_folio, accion, fecha, usuario, monto)
        VALUES (:OLD.folio, 'D', SYSDATE, USER, :OLD.monto_total);
    END IF;

EXCEPTION
  	WHEN OTHERS THEN
  		DBMS_OUTPUT.PUT_LINE('Ha ocurrido el siguiente error:'||SQLERRM);
END;

-- BLOQUE ANONIMO USANDO SQL DINAMICO
BEGIN
    -- Insertar boleta
    EXECUTE IMMEDIATE 'INSERT INTO Boletas (folio, fecha, monto_total, Medicamentos_id_med, Detalle_boleta_forma_pago, Clientes_cod_cli, Vendedores_cod_ven) VALUES (8891, SYSDATE, 3000, 1006, 1, 1, 1226)';

    -- Actualizar monto de la boleta
    EXECUTE IMMEDIATE 'UPDATE Boletas SET monto_total = monto_total * 1.2667 WHERE folio = 8891';

    -- Eliminar boleta
    EXECUTE IMMEDIATE 'DELETE FROM Boletas WHERE folio = 8891';

    -- Confirmar las transacciones realizadas
    COMMIT;
    
EXCEPTION
  	WHEN OTHERS THEN
  		DBMS_OUTPUT.PUT_LINE('Ha ocurrido el siguiente error:'||SQLERRM);
END;

select * from  aud_boleta;
select * from  boletas;