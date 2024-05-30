-- PROCEDIMIENTO PRINCIPAL
CREATE OR REPLACE PROCEDURE SP_PROCESA_COMISIONES(P_MES NUMBER)
IS
    CURSOR C_VENDEDORES IS SELECT V.COD_VEN,
                                  V.NOM_VEN,
                                  S.NOM_SUC,
                                  Z.DESCRIPCION  
                           FROM VENDEDORES V
                           JOIN SUCURSAL S ON V.SUCURSAL_COD_SUC = S.COD_SUC
                           JOIN ZONAS Z ON V.ZONAS_ID_ZONA = Z.ID_ZONA;
                           
    CURSOR C_BOLETAS IS SELECT FOLIO FROM BOLETAS;
    
    -- VARIABLES ADICIONALES
    V_MONTO_COMISION    COMISIONES_MES.MONTO_COMISION%TYPE;
    V_PORCENTAJE        COMISIONES_MES.PORCENTAJE%TYPE;
    V_MONTO_BOLETAS     NUMBER;
    V_NOM_MAYUSCULA     VENDEDORES.NOM_VEN%TYPE;
    V_CANTIDAD_BOLETAS  NUMBER;
    V_CONTADOR          NUMBER := 0;

BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE COMISIONES_MES';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE VENDEDOR_SIN_COMISION';
    
    DBMS_OUTPUT.PUT_LINE('PROCESANDO LAS COMISIONES DEL MES');
    
    FOR REG_VENDEDORES IN C_VENDEDORES
    LOOP 
        -- ASIGNAR A VARIABLES LOS RESULTADOS DE LAS FUNCIONES CREADAS
        V_NOM_MAYUSCULA := FN_NOMBRE_VENDEDOR(REG_VENDEDORES.COD_VEN);
        V_MONTO_BOLETAS := PKG_COMISIONES.FN_OBTENER_MONTO_BOLETAS(REG_VENDEDORES.COD_VEN, P_MES);
        V_PORCENTAJE := PKG_COMISIONES.FN_PORC_MONTO_COMISION(V_MONTO_BOLETAS);
        V_MONTO_COMISION := PKG_COMISIONES.FN_CALCULAR_COMISION(V_MONTO_BOLETAS, V_PORCENTAJE);
        
        -- RECORRER BOLETAS PARA OBTENER CANTIDAD POR VENDEDOR
        FOR REG_BOLETAS IN C_BOLETAS 
        LOOP
            SELECT COUNT(FOLIO)
            INTO V_CANTIDAD_BOLETAS
            FROM BOLETAS
            WHERE VENDEDORES_COD_VEN = REG_VENDEDORES.COD_VEN AND EXTRACT(MONTH FROM FECHA) = P_MES;
            
        END LOOP;
        
        -- INSERTAR EN TABLA COMISIONES_MES VENDEDORES CON SU COMISIÓN 
        IF V_MONTO_COMISION > 0 THEN
            BEGIN
                INSERT INTO COMISIONES_MES VALUES (
                               REG_VENDEDORES.COD_VEN,
                               V_NOM_MAYUSCULA,
                               V_MONTO_COMISION,
                               V_PORCENTAJE,
                               REG_VENDEDORES.NOM_SUC,
                               REG_VENDEDORES.DESCRIPCION); 
                               
            EXCEPTION
                WHEN OTHERS THEN
                CONTINUE;
            END;
        END IF;
        
        -- INSERTAR EN TABLA VENDEDOR_SIN_COOMISION VENDEDORES SIN VENTAS EN EL MES PROCESADO
        IF V_MONTO_BOLETAS = 0 THEN
             BEGIN
                INSERT INTO VENDEDOR_SIN_COMISION VALUES (
                               REG_VENDEDORES.COD_VEN,
                               V_NOM_MAYUSCULA,
                               V_CANTIDAD_BOLETAS,
                               V_MONTO_BOLETAS);             
            EXCEPTION
                WHEN OTHERS THEN
                CONTINUE;
            END;
        END IF;
        DBMS_OUTPUT.PUT_LINE('=================================================');
        DBMS_OUTPUT.PUT_LINE('Vendedor Número: ' || (V_CONTADOR + 1));
        DBMS_OUTPUT.PUT_LINE('Código Vendedor: ' || REG_VENDEDORES.COD_VEN);
        DBMS_OUTPUT.PUT_LINE('Nombre Vendedor: ' || V_NOM_MAYUSCULA);
        DBMS_OUTPUT.PUT_LINE('Cant.de Boletas: ' || V_CANTIDAD_BOLETAS);
        DBMS_OUTPUT.PUT_LINE('Monto Boletas: ' || V_MONTO_BOLETAS);
        DBMS_OUTPUT.PUT_LINE('=================================================');
        DBMS_OUTPUT.PUT_LINE('');
        
        V_CONTADOR := V_CONTADOR + 1;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('=================================================');
    DBMS_OUTPUT.PUT_LINE('VENDEDORES PROCESADOS EXITOSAMENTE');
    DBMS_OUTPUT.PUT_LINE('=================================================');
    DBMS_OUTPUT.PUT_LINE('Fueron procesados un total de: ' || V_CONTADOR || ' vendedores');
END;
/

-- EJECUTAR STORE PROCEDURE
BEGIN
   SP_PROCESA_COMISIONES(12);
END;


-- COMPROBAR LAS INSERCIONES EN LAS TABLAS
SELECT * FROM COMISIONES_MES;
SELECT * FROM VENDEDOR_SIN_COMISION;


