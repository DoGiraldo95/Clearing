create or replace type alertas as object (

       r_remite varchar2(1000),
       r_recibe varchar2(1000),
       p_recibe_copia varchar2(1000),

       member procedure pr_alerta_trx_visa
)
/
CREATE OR REPLACE TYPE BODY alertas AS
    MEMBER PROCEDURE pr_alerta_trx_visa AS
        cat       NUMBER;
        p_mensaje VARCHAR2(1000);
        p_asunto  VARCHAR2(1000);
    BEGIN
        cat := 0;
        SELECT
            COUNT(*)
        INTO cat
        FROM
            mercury.tbl_trx_utrytopcs a
        WHERE
                trunc(a.fecha_ws) >= trunc(sysdate)
            AND a.status = 'A'
            AND a.processed IN ( 'S', 'C' );

        IF cat > 0 THEN
            p_asunto := to_char('TRX VISA A LIQUIDAR ' || trunc(sysdate));
            p_mensaje := 'Buen Día, '
                         || chr(10)
                         || chr(10)
                         || 'La cantidad de trx visa a liquidar son : '
                         || to_char(cat)
                         || chr(10)
                         || chr(10)
                         || 'Cordialmente.'
                         || chr(10)
                         || chr(10)
                         || chr(10)
                         || chr(10)
                         || 'Centro de Procesamiento Transaccional'
                         || chr(10)
                         || 'Gerencia Soluciones de Recaudo T.I.'
                         || chr(10)
                         || 'Calle 25N # 2F - 136'
                         || chr(10)
                         || 'Cali - Valle del Cauca'
                         || chr(10)
                         || chr(10)
                         || chr(10)
                         || '**********************NO RESPONDER - Mensaje Generado Automaticamente**********************';

        ELSE
            p_asunto := to_char('ERROR TRX VISA' || trunc(sysdate));
            p_mensaje := 'Buen Día, '
                         || chr(10)
                         || chr(10)
                         || 'Error descarga trx VISA'
                         || chr(10)
                         || chr(10)
                         || 'Por favor realizar la respectiva revisión'
                         || chr(10)
                         || chr(10)
                         || 'Cordialmente.'
                         || chr(10)
                         || chr(10)
                         || chr(10)
                         || chr(10)
                         || 'Centro de Procesamiento Transaccional'
                         || chr(10)
                         || 'Gerencia Soluciones de Recaudo T.I.'
                         || chr(10)
                         || 'Calle 25N # 2F - 136'
                         || chr(10)
                         || 'Cali - Valle del Cauca'
                         || chr(10)
                         || chr(10)
                         || chr(10)
                         || '**********************NO RESPONDER - Mensaje Generado Automaticamente**********************';

        END IF;

        sp_envia_correo(self.r_remite, self.r_recibe, self.p_recibe_copia, p_asunto, p_mensaje);

    END pr_alerta_trx_visa;

END;
/
