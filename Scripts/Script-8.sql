DECLARE
	detalle_tarjeta LONG;

p_asunto VARCHAR(1000);

p_mensaje LONG;

CURSOR TRJVISA IS
    SELECT
	TRUNC(a.entry_date) AS FECHA,
	(
	SELECT
		b.lm_desc
	FROM
		Mercury.Linemt b
	WHERE
		b.lm_id = a.route_id) AS ESTACION,
	a.card_number TARJETA,
	MAX(a.bin) AS BIN,
	MAX(a.last4) AS LAST4,
	count(*) AS CANT
FROM
	Mercury.tbl_trx_utrytopcs a
WHERE
	TRUNC(a.ENTRY_DATE) >= TRUNC(SYSDATE-1)
GROUP BY
	TRUNC(a.entry_date),
	a.short_txt,
	a.route_id,
	a.card_number
HAVING
	COUNT (*) > 4
ORDER BY
	1,
	4 ASC;

BEGIN
	
	FOR i IN trjvisa LOOP	
		
		IF trjvisa%FOUND THEN	
		
			detalle_tarjeta := detalle_tarjeta || 'Fecha := ' || lower(i.fecha) || 
                ' Estacion:= ' || initcap(i.estacion) ||
                ' Bin:= ' || i.bin ||
                ' last4:= ' || i.last4 ||
                ' cantidad = ' || i.cant || CHR(10);

END IF ;
END LOOP;

	IF detalle_tarjeta <> ' ' THEN
		
		p_asunto := TO_CHAR(UPPER('tarjetas visa sospechosas ') || TRUNC(SYSDATE-1));
		p_mensaje := 'Buen Día, ' || CHR(10) || CHR(10) ||
                   'A continuacion se detallara las tarjetas sopechosas que presentaron en el sistema del dia '|| to_char(sysdate-1, 'dd Month' ) || ' :' ||
                   CHR(10) ||CHR(10) || detalle_tarjeta || CHR(10) || CHR(10) ||
                   'Cordialmente.' ||
                   CHR(10) || CHR(10) || CHR(10) || CHR(10) ||
                   'Centro de Procesamiento Transaccional' || CHR(10) ||
                   'Gerencia Soluciones de Recaudo T.I.' || CHR(10) ||
                   'Calle 25N # 2F - 136' || CHR(10) ||
                   'Cali - Valle del Cauca' || CHR(10) || CHR(10) ||
                   CHR(10) ||
                   '**********************NO RESPONDER - Mensaje Generado Automaticamente**********************';
	
	END IF;

	SP_ENVIA_CORREO('dgiraldo@utryt.com.co',
                    'jbarrios@utryt.com.co, ddiez@utryt.com.co',
                    'dgiraldo@utryt.com.co',
                    P_ASUNTO,
                    P_MENSAJE);
END;