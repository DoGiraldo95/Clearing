DECLARE
    CURSOR cu_validadoresxestacion IS
        SELECT
            a.tp_id,
            a.ld_id,
            a.ld_desc,
            a.veh_id,
            a.status
        FROM
            (
                SELECT
                    MAX(trunc(cu.cu_datetime) ) AS fechauso,
    --trunc(cu.cu_datetime)AS fechauso,
                    TO_CHAR(cu.cu_datetime,'MM') AS mes,
                    ld.ld_id AS ld_id,
                    ld.ld_desc AS ld_desc,
                    udf.veh_id AS veh_id,
                    udf.tp_id AS tp_id,
                    veh.veh_status AS status
                FROM
                    mercury.cardusage cu,
                    mercury.linedetails ld,
                    mercury.usagedatatripmt udtm,
                    mercury.usagedataservice uds,
                    mercury.usagedatafile udf,
                    mercury.applications app,
                    mercury.vehicles veh
                WHERE
                        1 = 1
                    AND
                        cu.udtm_id = udtm.udtm_id
                    AND
                        udtm.uds_id = uds.uds_id
                    AND
                        uds.udf_id = udf.udf_id
                    AND
                        udf.veh_id = veh.veh_id
                    AND
                        cu.cu_datetime >= TO_DATE('01-02-2023 00:01','dd-mm-yyyy hh24:mi')
                    AND
                        cu.cu_datetime <= TO_DATE('31-03-2023 23:59','dd-mm-yyyy hh24:mi')
                    AND
                        cu.cut_id = 1                      -- Tipos de uso -> 1: Passenger use,5: On-board sale
                    AND
                        nvl(cu.cu_partfareseqnbr,0) <> 2   -- Solo cuenta una vez las transacciones que afectan las dos
                    AND
                        app.app_id = cu.app_id
                    AND
                        ld.ld_id = cu.ld_id
                    AND
                        udf.tp_id IN (
                            3,4
                        )
                    AND
                        veh.veh_status = 'A'
                    AND
                        app.app_id NOT IN (
                            701
                        )
                    AND (
                        (
                                cu.cu_farevalue >= 0
                            OR
                                cu.cu_itg_ctr IS NOT NULL
                        ) OR
                            cu.app_id IN (
                                505,507
                            )
                    ) -- Solo usos sin funcionario
                GROUP BY
                    trunc(cu.cu_datetime),
                    TO_CHAR(cu.cu_datetime,'MM'),
                    ld.ld_id,
                    ld.ld_desc,
                    udf.veh_id,
                    veh.veh_status,
                    udf.tp_id
                ORDER BY 1
            ) a
        GROUP BY
            a.tp_id,
            a.ld_id,
            a.ld_desc,
            a.veh_id,
            a.status;

    validadoresxestacion   tbl_validadores_mrc%rowtype;
BEGIN
    FOR validador IN cu_validadoresxestacion LOOP
        validadoresxestacion.tp_id := validador.tp_id;
        validadoresxestacion.ld_id := validador.ld_id;
        validadoresxestacion.ld_desc := validador.ld_desc;
        validadoresxestacion.veh_id := validador.veh_id;
        validadoresxestacion.status := validador.status;
        INSERT INTO tbl_validadores_mrc VALUES validadoresxestacion;

    END LOOP;

    COMMIT;
END;