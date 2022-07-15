--
-- PostgreSQL database dump
--

-- Dumped from database version 13.7
-- Dumped by pg_dump version 14.2

-- Started on 2022-07-13 20:52:52

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 6 (class 2615 OID 16395)
-- Name: dielab; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA dielab;


ALTER SCHEMA dielab OWNER TO postgres;

--
-- TOC entry 286 (class 1255 OID 16551)
-- Name: actualiza_estado(); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.actualiza_estado() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare

resultado   record;

begin

select * into resultado from dielab.estado_ensayo
where id_estado = new.cod_estado;
if found then
	new.estado := resultado.nombre;
end if;
   
return new;

end
$$;


ALTER FUNCTION dielab.actualiza_estado() OWNER TO postgres;

--
-- TOC entry 294 (class 1255 OID 66031)
-- Name: actualiza_nombre_marca(); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.actualiza_nombre_marca() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare

resultado   record;

begin

select * into resultado from dielab.marca
where id_marca = new.cod_marca;
if found then
	new.marca := resultado.nombre;
end if;
   
return new;

end
$$;


ALTER FUNCTION dielab.actualiza_nombre_marca() OWNER TO postgres;

--
-- TOC entry 284 (class 1255 OID 24851)
-- Name: emite_certificado(character varying); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.emite_certificado(cod_ensayox character varying) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare

--id_epp			double precision;
salida        	json;
resultado		record;
myrec			record;
--codigo			text;
begin

select * into resultado from dielab.encabezado_ensayo where cod_ensayo = cod_ensayox;
if found then
	update dielab.encabezado_ensayo set cod_estado = 3, fecha_emision = now()::date
	where cod_ensayo = cod_ensayox;
	
	for myrec in select id_epp from dielab.encabezado_ensayo 
	join dielab.detalle_ensayo using (id_batea) 
	join dielab.epps on detalle_ensayo.serie_epp = epps.id_epp
	where cod_ensayo = cod_ensayox loop
		update dielab.epps set estado_epp = 3;
	end loop;
	
	salida = '{"error":false, "msg":"Certificado emitido"}';
else
	salida = '{"error":true, "msg":"No se encuentra el codigo ensayo: ' || cod_ensayox || '"}';
end if;
return salida;
end;

$$;


ALTER FUNCTION dielab.emite_certificado(cod_ensayox character varying) OWNER TO postgres;

--
-- TOC entry 285 (class 1255 OID 16493)
-- Name: genera_cod_ensayo(character varying); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.genera_cod_ensayo(epp character varying) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare

idbatea			double precision;
max_cod			varchar;
salida        	json;
codigo			text;
begin

--select nextval('dielab.seq_cod_ensayo'::regclass) into idbatea;
--if found then
----ok
--	codigo = 'LAT-' || epp || '-' || to_char(idbatea, 'FM09999');
--	salida = '{"error":false, "msg":"' || codigo || '"}';
--else
--	salida = '{"error":true, "msg":"no pudo obtener el codigo"}';
--end if;
--	return salida;

	--select substr(max_cod, 9)::double precision + 1 into idbatea;
	select max(substr(cod_ensayo,9)::double precision) + 1 into idbatea
	from dielab.encabezado_ensayo where substr(cod_ensayo,1,7)='LAT-' || epp;

	if found then
	--ok
		if idbatea is null then
			idbatea := 1;
		end if;
		codigo = 'LAT-' || epp || '-' || to_char(idbatea, 'FM09999');
		salida = '{"error":false, "msg":"' || codigo || '"}';
	else
		idbatea := 1;
		codigo = 'LAT-' || epp || '-' || to_char(idbatea, 'FM09999');
		salida = '{"error":false, "msg":"' || codigo || '"}';
	end if;
return salida;
end;

$$;


ALTER FUNCTION dielab.genera_cod_ensayo(epp character varying) OWNER TO postgres;

--
-- TOC entry 282 (class 1255 OID 24791)
-- Name: genera_cod_epp(character varying); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.genera_cod_epp(epp character varying) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare

id_epp			double precision;
salida        	json;
codigo			text;
begin

id_epp := 1;
SELECT max(substr(serie_epp,5)::double precision) + 1 into id_epp
	FROM dielab.epps 
	where substr(serie_epp,1,4) = epp || '-';
if found then
	if id_epp is null then
		id_epp := 1;
	end if;
	raise notice '(1) %', id_epp;
	codigo = epp || '-' || to_char(id_epp, 'FM09999');
else
	raise notice '(2) %', id_epp;
	codigo = epp || '-' || to_char(id_epp, 'FM09999');
end if;
	salida = '{"error":false, "msg":"' || codigo || '"}';
return salida;
end;

$$;


ALTER FUNCTION dielab.genera_cod_epp(epp character varying) OWNER TO postgres;

--
-- TOC entry 300 (class 1255 OID 66030)
-- Name: genera_tabla_x_epp(integer); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.genera_tabla_x_epp(eppx integer) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare


resulta			record;
salida			json;
linea			text;
linea_data		text;
fila_datos		text;
sql_data		text;
num_campos		integer;
campos			text;
tipo_tabla		varchar;
begin

linea = '';
linea_data = '';
fila_datos = '';
num_campos := 0;
campos = '';
select tabla_detalle into tipo_tabla from dielab.clase_epp where id_clase_epp = eppX;
if found then
	for resulta in 
		select column_name from information_schema.columns
		where table_schema = 'dielab' and table_name = 'select_' || tipo_tabla
		and column_name not in ('id', 'nombre') loop
			if linea = '' then
				linea = '"' || resulta.column_name || '"';
				campos := resulta.column_name;
			else
				linea = linea || ',"' || resulta.column_name || '"';
				campos := campos || ',' || resulta.column_name;
			end if;
			num_campos = num_campos + 1;
	end loop;
	linea = '[' || linea  || ']';
	
	raise notice 'campos: %', campos;
	sql_data = 'select array[' || campos || '] as a from dielab.select_' || tipo_tabla;
	for resulta in execute(sql_data) loop
		for i in 1..num_campos loop
			if fila_datos = '' then
				fila_datos = '"' || resulta.a[i] || '"';
			else
				fila_datos = fila_datos || ',"' || resulta.a[i] || '"';
			end if;
		end loop;
		raise notice 'fila_datos: %',fila_datos;
		if linea_data = '' then
			linea_data = '[' || fila_datos || ']';
		else
			linea_data = linea_data || ',' || '[' || fila_datos || ']';
		end if;
		fila_datos = '';
		raise notice 'linea_data: %',linea_data;
	end loop;
	raise notice 'linea_data2: %',linea_data;
	linea_data = '[' || linea_data  || ']';
	raise notice 'linea_data3: %',linea_data;
	linea = '{"error":false,"headers":' || linea ||  ', "datos":'|| linea_data || '}';
	salida = linea::json;
else
	salida = '{"error":true, "msg":"' || 'No se encuentra el código Epp en la base' || '"}';
end if;

return salida;
end;

$$;


ALTER FUNCTION dielab.genera_tabla_x_epp(eppx integer) OWNER TO postgres;

--
-- TOC entry 283 (class 1255 OID 41277)
-- Name: get_detalle_pdf(character varying); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.get_detalle_pdf(cod_ensayox character varying) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $_$
declare

myrec			record;
begin

for myrec in select case when num_fila is null then '--' else num_fila end as row_number,
case when num_serie is null then '--' else num_serie end as num_serie,
case when marca is null then '--' else marca end as marca,
case when largo is null then '--' else largo end as largo,
case when usado is null then '--' else usado end as usado,
case when cod_clase is null then '--' else cod_clase end as cod_clase,
case when tension_ensayo is null then '--' else tension_ensayo end as tension_ensayo,
case when parches is null then '--' else parches end as parches,
case when promed_fuga is null then '--' else promed_fuga end as promed_fuga,
case when fuga_max is null then '--' else fuga_max end as fuga_max,
case when aprobado is null then '--' else aprobado end as aprobado

from
(select generate_series(1,12)::text as correlativo) as a
LEFT JOIN
(select 
row_number() over (order by num_serie)::text as num_fila, num_serie, marca, largo::text, cod_clase, tension_ensayo,
case when parches ~ '^[0-9\.]+$' then case when parches::numeric > 0 then parches else '--' end else '--' end as parches, 
case when aprobado = 'RECHAZADO' then 'Falla' else case when promed_fuga ~ '^[0-9\.]+$' then to_char(promed_fuga::numeric, 'FM9.00') else '--' end end as promed_fuga, 
to_char(corriente_fuga_max, 'FM9.00') as fuga_max, aprobado, estado_uso.nombre_estado::text as usado
from dielab.lista_det_guante
join dielab.epps on num_serie = serie_epp
join dielab.estado_uso on epps.estado_uso = estado_uso.id
join dielab.tipo_guante on tipo_epp = id_tipo
join dielab.clase_tipo on tipo_guante.clase = clase_tipo.id_clase
join dielab.encabezado_ensayo using (id_batea) where cod_ensayo = cod_ensayoX) as b
on a.correlativo = b.num_fila loop

--for myrec in select 
--row_number() over (order by num_serie)::text, num_serie, marca, largo::text, cod_clase, tension_ensayo,
--case when parches ~ '^[0-9\.]+$' then case when parches::numeric > 0 then parches else '--' end else '--' end as parches, 
--case when aprobado = 'RECHAZADO' then 'Falla' else case when promed_fuga ~ '^[0-9\.]+$' then to_char(promed_fuga::numeric, 'FM9.00') else '--' end end as promed_fuga, 
--to_char(corriente_fuga_max, 'FM9.00') as fuga_max, aprobado
--from dielab.lista_det_guante
--join dielab.epps on num_serie = serie_epp
--join dielab.tipo_guante on tipo_epp = id_tipo
--join dielab.clase_tipo on tipo_guante.clase = clase_tipo.id_clase
--join dielab.encabezado_ensayo using (id_batea) where cod_ensayo = cod_ensayoX
--	loop
		return next myrec;
	end loop;

return;
end;

$_$;


ALTER FUNCTION dielab.get_detalle_pdf(cod_ensayox character varying) OWNER TO postgres;

--
-- TOC entry 281 (class 1255 OID 16492)
-- Name: ingresa_cliente(text, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.ingresa_cliente(nombre text, nombre_corto character varying, representante character varying, telefono character varying, direccion character varying) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
resultado 		record;
id_nuevo		bigint;
salida        	json;
begin
select max(id_cliente) as max_id into resultado from dielab.cliente;
if found then
	id_nuevo := resultado.max_id + 1;
else
	id_nuevo := 0;
end if;
insert into dielab.cliente (id_cliente, nombre, telefono, representante, direccion, nombre_corto)
	values (id_nuevo, nombre, substr(telefono,1,10), substr(representante,1,100), 
						   substr(direccion,1,100), substr(nombre_corto,1,7));
salida = '{"error":false, "msg":"Cliente insertado correctamente"}';
return salida;

EXCEPTION
	WHEN others THEN
		salida = '{"error":true, "msg":"Se produjo un error al insertar el cliente"}';
		return salida;
end;
$$;


ALTER FUNCTION dielab.ingresa_cliente(nombre text, nombre_corto character varying, representante character varying, telefono character varying, direccion character varying) OWNER TO postgres;

--
-- TOC entry 301 (class 1255 OID 74000)
-- Name: ingresa_det_tipo_epp(text, json); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.ingresa_det_tipo_epp(tabla_tipo_in text, datojson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare

myrec			record;
salida        	json;
otro			json;
id_detalle_auto	bigint;
serie_bigint	bigint;
sql_text		text;
id_tipo_in		integer;
begin
id_tipo_in := 1;
sql_text := 'select max(id_tipo) as val_max from dielab.' || tabla_tipo_in || ';';
for myrec in execute(sql_text) loop
	id_tipo_in := myrec.val_max + 1;
end loop;

sql_text = 'id_tipo';
if datojson->'largo' is not null then
	if sql_text = '' then
		sql_text := 'largo';
	else
		sql_text := sql_text || ',' || 'largo';
	end if;
end if;
if datojson->'clase' is not null then
	if sql_text = '' then
		sql_text := 'clase';
	else
		sql_text := sql_text || ',' || 'clase';
	end if;
end if;
if datojson->'max_i_fuga' is not null then
	if sql_text = '' then
		sql_text := 'corriente_fuga_max';
	else
		sql_text := sql_text || ',' || 'corriente_fuga_max';
	end if;
end if;
if datojson->'marca' is not null then
	if sql_text = '' then
		sql_text := 'cod_marca';
	else
		sql_text := sql_text || ',' || 'cod_marca';
	end if;
end if;
sql_text = '(' || sql_text || ') VALUES (' || id_tipo_in::text;

--raise notice 'sql_text: %',sql_text;
--raise notice 'clase: %', datojson->>'clase';

if datojson->'largo' is not null then
	sql_text := sql_text || ',' || (datojson->>'largo')::text;
end if;
if datojson->'clase' is not null then
	sql_text := sql_text || ',' || (datojson->>'clase')::text;
end if;
if datojson->'max_i_fuga' is not null then
	sql_text := sql_text || ',' || (datojson->>'max_i_fuga')::text;
end if;
if datojson->'marca' is not null then
	sql_text := sql_text || ',' || (datojson->>'marca')::text;
end if;
sql_text := sql_text || ')';
sql_text := 'INSERT INTO dielab.' || tabla_tipo_in || ' ' || sql_text  || ';';

raise notice 'consulta: %', sql_text;
execute sql_text;
salida = '{"error":false, "msg":"Ingreso correcto"}';

return salida;
exception
	WHEN unique_violation THEN
		salida = '{"error":true, "msg":"El dato ya existe en la base de datos"}';
	when others then
		salida = '{"error":true, "msg":"No fue posible grabar el dato"}';
		
return salida;
end;

$$;


ALTER FUNCTION dielab.ingresa_det_tipo_epp(tabla_tipo_in text, datojson json) OWNER TO postgres;

--
-- TOC entry 295 (class 1255 OID 24785)
-- Name: ingresa_detalle(bigint, json); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.ingresa_detalle(id_batea_in bigint, datojson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare

myrec			record;
salida        	json;
otro			json;
id_detalle_auto	bigint;
serie_bigint	bigint;
begin

select * into myrec from dielab.encabezado_ensayo where id_batea = id_batea_in;
if found then
	--ok
	delete from dielab.detalle_ensayo where id_batea = id_batea_in;
	for i in 0..100 loop
		if datojson->'detalle'->i is null then
			exit;
		end if;
		select nextval('dielab.seq_id_tabla'::regclass) into id_detalle_auto;
		
		select id_epp into serie_bigint from dielab.epps 
		where serie_epp = datojson->'detalle'->i->>'serie_epp';
		if found then
			-- se encuentra el epp
			select * into myrec from dielab.detalle_ensayo where id_batea = id_batea_in
			and serie_epp = serie_bigint;
			if found then
			-- ya existe, actualizar
				update dielab.detalle_ensayo 
				set aprobado = case when upper(datojson->'detalle'->i->>'resultado') = 'APROBADO' then true else false end,
				detalle = datojson->'detalle'->i
				where id_batea = id_batea_in
				and serie_epp = serie_bigint;
			else
			-- no existe, insertar
				insert into dielab.detalle_ensayo 
				VALUES (id_detalle_auto, id_batea_in, serie_bigint, case when upper(datojson->'detalle'->i->>'resultado') = 'APROBADO' then true else false end,
					   datojson->'detalle'->i);
			end if;
			--cambia el estado del epp a en ensayo
			update dielab.epps set estado_epp = 1 where serie_epp = serie_bigint;

			update dielab.encabezado_ensayo set cod_estado = 2 where id_batea = id_batea_in;
			salida = '{"error":false, "msg":"Ingreso correcto"}';
		else
			salida = '{"error":true, "msg":"El epp serie ' || datojson->'detalle'->i->>'serie_epp' || ' no se encuentra en la base"}';
		end if;
	end loop;
ELSE
	salida = '{"error":true, "msg":"El Id_batea ' || id_batea_in || ' no se encuentra en la base"}';
END IF;

return salida;
end;

$$;


ALTER FUNCTION dielab.ingresa_detalle(id_batea_in bigint, datojson json) OWNER TO postgres;

--
-- TOC entry 268 (class 1255 OID 24780)
-- Name: ingresa_detalle_borrar(json); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.ingresa_detalle_borrar(datojson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare

salida        	json;
otro			json;
begin
for i in 0..11 loop
	if datojson->'detalle'->i is null then
		exit;
	end if;
	raise notice '%', datojson->'detalle'->i;
end loop;

	--otro = '{"valor0":"cero", "valor1":"uno"}'::json;
		--raise notice '%', datojson->'uno';
		--raise notice '%', datojson->'dos';
		salida = '{"error":false, "msg":"SALIDA"}';
return salida;
end;

$$;


ALTER FUNCTION dielab.ingresa_detalle_borrar(datojson json) OWNER TO postgres;

--
-- TOC entry 289 (class 1255 OID 24777)
-- Name: ingresa_detalle_borrar(bigint, character varying, character varying, json); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.ingresa_detalle_borrar(id_batea bigint, serie_epp character varying, estado_aprobacion character varying, detalle json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare

salida        	json;
otro			json;
begin
--foreach e in ARRAY datojson->'dos' loop
--	raise notice '%',e;
--end loop;
otro = '{"valor0":"cero", "valor1":"uno"}'::json;
		--raise notice '%', datojson->'uno';
		raise notice '%', datojson->'dos'->'0';
		salida = '{"error":false, "msg":"SALIDA"}';
return salida;
end;

$$;


ALTER FUNCTION dielab.ingresa_detalle_borrar(id_batea bigint, serie_epp character varying, estado_aprobacion character varying, detalle json) OWNER TO postgres;

--
-- TOC entry 292 (class 1255 OID 24847)
-- Name: ingresa_enc_ensayo(character varying, integer, character varying, integer, numeric, numeric, integer, integer, character varying, character varying, integer); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.ingresa_enc_ensayo(cod_ensayox character varying, clientex integer, sucursalx character varying, negociox integer, temperaturax numeric, humedadx numeric, tecnicox integer, patronx integer, fecha_ejecucionx character varying, fecha_ingresox character varying, valor_estadox integer) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare

resulta       	record;
resulta_0		record;
codigo_en		double precision;
idbatea			double precision;
salida        	json;
id_cli_n_s		integer;
begin

--primero chequear si ya existe el codigo de ensayo
select * into resulta from dielab.encabezado_ensayo
where encabezado_ensayo.cod_ensayo = cod_ensayox;
if found then
--es una edición de encabezado
	select * into resulta_0 from dielab.cliente_negocio_sucursal where
	cliente = clienteX and negocio = negocioX and sucursal = sucursalX;
	if found then
		id_cli_n_s := resulta.cliente_n_s;
		update dielab.encabezado_ensayo
		set temperatura = temperaturax, humedad = humedadx, tecnico = tecnicox, patron = patronx, fecha_ejecucion = fecha_ejecucionx::date, cliente_n_s = id_cli_n_s, fecha_ingreso = fecha_ingresox::date, cod_estado = valor_estadox,
		cod_patron = patronx
		where cod_ensayo = cod_ensayox;
		salida = '{"error":false, "msg":"ensayo actualizado"}';
	else
		salida = '{"error":true, "msg":"(4) Se produjo un error al insertar el ensayo"}';
	end if;
else
-- es una inserción
select nextval('dielab.seq_id_tabla'::regclass) into idbatea;
	if found then
	--ok
		--select nextval('dielab.seq_cod_ensayo'::regclass) into codigo_en;
		--if found then
			select * into resulta from dielab.cliente_negocio_sucursal where
			cliente = clienteX and negocio = negocioX and sucursal = sucursalX;
			if found then
				id_cli_n_s := resulta.id_cliente_n_s;
				INSERT INTO dielab.encabezado_ensayo
				VALUES (idbatea, cod_ensayox, temperaturax, humedadx, tecnicox, now()::timestamp, patronx, 'ingreso', 1, fecha_ejecucionx::date, null, id_cli_n_s, fecha_ingresox::date, valor_estadox, patronx);
				salida = '{"error":false, "msg":"ensayo ingresado"}';
			else
				salida = '{"error":true, "msg":"(4) Se produjo un error al insertar el ensayo"}';
			end if;
		--else
		--	salida = '{"error":true, "msg":"(1) Se produjo un error al insertar el ensayo"}';
		--end if;
	else
		salida = '{"error":true, "msg":"(2) Se produjo un error al insertar el ensayo"}';
	end if;
end if;
	return salida;

end;

$$;


ALTER FUNCTION dielab.ingresa_enc_ensayo(cod_ensayox character varying, clientex integer, sucursalx character varying, negociox integer, temperaturax numeric, humedadx numeric, tecnicox integer, patronx integer, fecha_ejecucionx character varying, fecha_ingresox character varying, valor_estadox integer) OWNER TO postgres;

--
-- TOC entry 293 (class 1255 OID 57672)
-- Name: ingresa_enc_ensayo(character varying, integer, character varying, integer, numeric, numeric, integer, integer, character varying, character varying, integer, integer); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.ingresa_enc_ensayo(cod_ensayox character varying, clientex integer, sucursalx character varying, negociox integer, temperaturax numeric, humedadx numeric, tecnicox integer, patronx integer, fecha_ejecucionx character varying, fecha_ingresox character varying, valor_estadox integer, tipo_ensayox integer) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare

resulta       	record;
resulta_0		record;
codigo_en		double precision;
idbatea			double precision;
salida        	json;
id_cli_n_s		integer;
begin

--primero chequear si ya existe el codigo de ensayo
select * into resulta from dielab.encabezado_ensayo
where encabezado_ensayo.cod_ensayo = cod_ensayox;
if found then
--es una edición de encabezado
	select * into resulta_0 from dielab.cliente_negocio_sucursal where
	cliente = clienteX and negocio = negocioX and sucursal = sucursalX;
	if found then
		id_cli_n_s := resulta.cliente_n_s;
		update dielab.encabezado_ensayo
		set temperatura = temperaturax, humedad = humedadx, tecnico = tecnicox, patron = patronx, tipo_ensayo = tipo_ensayoX, fecha_ejecucion = fecha_ejecucionx::date, cliente_n_s = id_cli_n_s, fecha_ingreso = fecha_ingresox::date, cod_estado = valor_estadox,
		cod_patron = patronx
		where cod_ensayo = cod_ensayox;
		salida = '{"error":false, "msg":"ensayo actualizado"}';
	else
		salida = '{"error":true, "msg":"(4) Se produjo un error al insertar el ensayo"}';
	end if;
else
-- es una inserción
select nextval('dielab.seq_id_tabla'::regclass) into idbatea;
	if found then
	--ok
		--select nextval('dielab.seq_cod_ensayo'::regclass) into codigo_en;
		--if found then
			select * into resulta from dielab.cliente_negocio_sucursal where
			cliente = clienteX and negocio = negocioX and sucursal = sucursalX;
			if found then
				id_cli_n_s := resulta.id_cliente_n_s;
				INSERT INTO dielab.encabezado_ensayo
				VALUES (idbatea, cod_ensayox, temperaturax, humedadx, tecnicox, now()::timestamp, patronx, 'ingreso', tipo_ensayoX, fecha_ejecucionx::date, null, id_cli_n_s, fecha_ingresox::date, valor_estadox, patronx);
				salida = '{"error":false, "msg":"ensayo ingresado"}';
			else
				salida = '{"error":true, "msg":"(4) Se produjo un error al insertar el ensayo"}';
			end if;
		--else
		--	salida = '{"error":true, "msg":"(1) Se produjo un error al insertar el ensayo"}';
		--end if;
	else
		salida = '{"error":true, "msg":"(2) Se produjo un error al insertar el ensayo"}';
	end if;
end if;
	return salida;

end;

$$;


ALTER FUNCTION dielab.ingresa_enc_ensayo(cod_ensayox character varying, clientex integer, sucursalx character varying, negociox integer, temperaturax numeric, humedadx numeric, tecnicox integer, patronx integer, fecha_ejecucionx character varying, fecha_ingresox character varying, valor_estadox integer, tipo_ensayox integer) OWNER TO postgres;

--
-- TOC entry 291 (class 1255 OID 16495)
-- Name: ingresa_enc_ensayo_borrar(character varying, integer, character varying, integer, numeric, numeric, integer, integer, date, date); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.ingresa_enc_ensayo_borrar(cod_ensayo character varying, clientex integer, sucursalx character varying, negociox integer, temperatura numeric, humedad numeric, tecnico integer, patron integer, fecha_ejecucion date, fecha_ingreso date) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare

resulta       	record;
codigo_en		double precision;
idbatea			double precision;
salida        	json;
id_cli_n_s		integer;
begin

select nextval('dielab.seq_id_tabla'::regclass) into idbatea;
if found then
--ok
	--select nextval('dielab.seq_cod_ensayo'::regclass) into codigo_en;
	--if found then
		select * into resulta from dielab.cliente_negocio_sucursal where
		cliente = clienteX and negocio = negocioX and sucursal = sucursalX;
		if found then
			id_cli_n_s := resulta.id_cliente_n_s;
				raise notice '%', fecha_ejecucion;
				raise notice '%', fecha_ingreso;
			--raise notice '%', idbatea;
			--raise notice '%', codigo_en;
			--raise notice '%', temperatura;
			--raise notice '%', humedad;
			--raise notice '%', tecnico;
			--raise notice '%', patron;
			--raise notice '(%, %, %, %, %, %, %, %, %)',idbatea, codigo_en, temperatura, humedad, tecnico, now()::timestamp, patron, 'ingresado', 1;
			INSERT INTO dielab.encabezado_ensayo
			VALUES (idbatea, cod_ensayo, temperatura, humedad, tecnico, now()::timestamp, patron, 'ingresado', 1, fecha_ejecucion::date, null, id_cli_n_s, fecha_ingreso::date);
			salida = '{"error":false, "msg":"ensayo ingresado"}';
		else
			salida = '{"error":true, "msg":"(4) Se produjo un error al insertar el ensayo"}';
		end if;
	--else
	--	salida = '{"error":true, "msg":"(1) Se produjo un error al insertar el ensayo"}';
	--end if;
else
	salida = '{"error":true, "msg":"(2) Se produjo un error al insertar el ensayo"}';
end if;
	return salida;

end;

$$;


ALTER FUNCTION dielab.ingresa_enc_ensayo_borrar(cod_ensayo character varying, clientex integer, sucursalx character varying, negociox integer, temperatura numeric, humedad numeric, tecnico integer, patron integer, fecha_ejecucion date, fecha_ingreso date) OWNER TO postgres;

--
-- TOC entry 290 (class 1255 OID 16494)
-- Name: ingresa_enc_ensayo_borrar(character varying, integer, character varying, integer, numeric, numeric, integer, integer, character varying, character varying); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.ingresa_enc_ensayo_borrar(cod_ensayo character varying, clientex integer, sucursalx character varying, negociox integer, temperatura numeric, humedad numeric, tecnico integer, patron integer, fecha_ejecucion character varying, fecha_ingreso character varying) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare

resulta       	record;
codigo_en		double precision;
idbatea			double precision;
salida        	json;
id_cli_n_s		integer;
begin

select nextval('dielab.seq_id_tabla'::regclass) into idbatea;
if found then
--ok
	--select nextval('dielab.seq_cod_ensayo'::regclass) into codigo_en;
	--if found then
		select * into resulta from dielab.cliente_negocio_sucursal where
		cliente = clienteX and negocio = negocioX and sucursal = sucursalX;
		if found then
			id_cli_n_s := resulta.id_cliente_n_s;
			--raise notice '%', idbatea;
			--raise notice '%', codigo_en;
			--raise notice '%', temperatura;
			--raise notice '%', humedad;
			--raise notice '%', tecnico;
			--raise notice '%', patron;
			--raise notice '(%, %, %, %, %, %, %, %, %)',idbatea, codigo_en, temperatura, humedad, tecnico, now()::timestamp, patron, 'ingresado', 1;
			INSERT INTO dielab.encabezado_ensayo
			VALUES (idbatea, cod_ensayo, temperatura, humedad, tecnico, now()::timestamp, patron, 'ingresado', 1, fecha_ejecucion::date, null, id_cli_n_s, fecha_ingreso::date);
			salida = '{"error":false, "msg":"ensayo ingresado"}';
		else
			salida = '{"error":true, "msg":"(4) Se produjo un error al insertar el ensayo"}';
		end if;
	--else
	--	salida = '{"error":true, "msg":"(1) Se produjo un error al insertar el ensayo"}';
	--end if;
else
	salida = '{"error":true, "msg":"(2) Se produjo un error al insertar el ensayo"}';
end if;
	return salida;

end;

$$;


ALTER FUNCTION dielab.ingresa_enc_ensayo_borrar(cod_ensayo character varying, clientex integer, sucursalx character varying, negociox integer, temperatura numeric, humedad numeric, tecnico integer, patron integer, fecha_ejecucion character varying, fecha_ingreso character varying) OWNER TO postgres;

--
-- TOC entry 296 (class 1255 OID 24840)
-- Name: ingresa_epp(character varying, integer, integer, character varying, integer, integer, character varying); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.ingresa_epp(cod_epp character varying, tipo integer, clientex integer, sucursalx character varying, negociox integer, valor_estado integer, tipo_epp character varying) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare

resulta       	record;
codigo_en		double precision;
idepp		double precision;
salida        	json;
id_cli_n_s		integer;
clase_eppX		bigint;

begin
SELECT id_clase_epp into resulta FROM dielab.clase_epp
where upper(cod_serie) = upper(tipo_epp);
if found then
	clase_eppX = resulta.id_clase_epp;
	select nextval('dielab.seq_id_tabla'::regclass) into idepp;
	if found then
	--ok
		--select nextval('dielab.seq_cod_ensayo'::regclass) into codigo_en;
		--if found then
			select * into resulta from dielab.cliente_negocio_sucursal where
			cliente = clienteX and negocio = negocioX and sucursal = sucursalX;
			if found then
				id_cli_n_s := resulta.id_cliente_n_s;
				INSERT INTO dielab.epps
				VALUES (idepp, cod_epp, clase_eppX, tipo, id_cli_n_s, valor_estado);
				salida = '{"error":false, "msg":"Epp ingresado"}';
			else
				salida = '{"error":true, "msg":"(4) Se produjo un error al insertar el epp"}';
			end if;
		--else
		--	salida = '{"error":true, "msg":"(1) Se produjo un error al insertar el ensayo"}';
		--end if;
	else
		salida = '{"error":true, "msg":"(2) Se produjo un error al insertar el ensayo"}';
	end if;
else
	salida = '{"error":true, "msg":"El tipo de epp no se encuentra en la base: ' || upper(tipo_epp) || '"}';
end if;

return salida;

end;

$$;


ALTER FUNCTION dielab.ingresa_epp(cod_epp character varying, tipo integer, clientex integer, sucursalx character varying, negociox integer, valor_estado integer, tipo_epp character varying) OWNER TO postgres;

--
-- TOC entry 299 (class 1255 OID 57671)
-- Name: ingresa_epp(character varying, integer, integer, character varying, integer, integer, character varying, integer, integer); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.ingresa_epp(cod_epp character varying, tipo integer, clientex integer, sucursalx character varying, negociox integer, valor_estado integer, tipo_epp character varying, periodicidadx integer, estado_usox integer) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare

resulta       	record;
codigo_en		double precision;
idepp		double precision;
salida        	json;
id_cli_n_s		integer;
clase_eppX		bigint;

begin
SELECT id_clase_epp into resulta FROM dielab.clase_epp
where upper(cod_serie) = upper(tipo_epp);
if found then
	clase_eppX = resulta.id_clase_epp;
	select nextval('dielab.seq_id_tabla'::regclass) into idepp;
	if found then
	--ok
		--select nextval('dielab.seq_cod_ensayo'::regclass) into codigo_en;
		--if found then
			select * into resulta from dielab.cliente_negocio_sucursal where
			cliente = clienteX and negocio = negocioX and sucursal = sucursalX;
			if found then
				id_cli_n_s := resulta.id_cliente_n_s;
				INSERT INTO dielab.epps
				VALUES (idepp, cod_epp, clase_eppX, tipo, id_cli_n_s, valor_estado, periodicidadX, estado_usoX);
				salida = '{"error":false, "msg":"Epp ingresado"}';
			else
				salida = '{"error":true, "msg":"(4) Se produjo un error al insertar el epp"}';
			end if;
		--else
		--	salida = '{"error":true, "msg":"(1) Se produjo un error al insertar el ensayo"}';
		--end if;
	else
		salida = '{"error":true, "msg":"(2) Se produjo un error al insertar el ensayo"}';
	end if;
else
	salida = '{"error":true, "msg":"El tipo de epp no se encuentra en la base: ' || upper(tipo_epp) || '"}';
end if;

return salida;

end;

$$;


ALTER FUNCTION dielab.ingresa_epp(cod_epp character varying, tipo integer, clientex integer, sucursalx character varying, negociox integer, valor_estado integer, tipo_epp character varying, periodicidadx integer, estado_usox integer) OWNER TO postgres;

--
-- TOC entry 288 (class 1255 OID 24852)
-- Name: obtiene_emision(character varying); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.obtiene_emision(cod_ensayox character varying) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare

salida        	json;
--codigo			text;
resultado		record;
begin

select * into resultado from dielab.encabezado_ensayo 
where cod_ensayo = cod_ensayox;
if found then
	salida = '{"error":false, "msg":"' || resultado.fecha_emision::varchar || '"}';
else
	salida = '{"error":true, "msg":"No existe el codigo enayo en la base"}';
end if;
return salida;
end;

$$;


ALTER FUNCTION dielab.obtiene_emision(cod_ensayox character varying) OWNER TO postgres;

--
-- TOC entry 269 (class 1255 OID 41275)
-- Name: test_record(); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.test_record() RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$
declare

myrec			record;
begin

for myrec in select * from dielab.select_cliente loop
	return next myrec;
end loop;

return;
end;

$$;


ALTER FUNCTION dielab.test_record() OWNER TO postgres;

--
-- TOC entry 298 (class 1255 OID 33122)
-- Name: valida_usuario(character varying, character varying); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.valida_usuario(user_sistema character varying, pass_sistema character varying) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare

resulta			record;
salida			json;
datos			json;
begin

salida = '{"error":true, "msg":"ocurrio un error al autenticar el usuario"}';
select * into resulta from dielab.usuarios where usuario = user_sistema;
if found then
-- usuario existe, verificar la password
	select usuarios.*, personas.suspendida as p_susp, cliente.suspendido as c_susp,
	perfil.* into resulta from dielab.usuarios 
	join dielab.personas on personas.rut = usuarios.rut
	join dielab.cliente on usuarios.cliente = cliente.id_cliente
	join dielab.perfil on usuarios.perfil = perfil.id
	where usuario = user_sistema and password_md5 = md5(pass_sistema);

	if found then
	--ok, verificar que la cuenta, la persona y el cliente no se encuentren suspendidos
		if not resulta.suspendida then
			if not resulta.p_susp then
				if not resulta.c_susp then
					--todo ok
					--datos = '{"usuario":"' || user_sistema || '"}';
					salida = '{"error":false, "usuario":"' || user_sistema || '", "perfil":"' || 
					resulta.nombre || 
					'","mantenedor":"' || resulta.mantenedor  ||
					'","inventario":"' || resulta.inventario  ||
					'","ensayo":"' || resulta.ensayo  ||
					'","reportes":"' || resulta.reportes 
					|| '"}';
				else
					salida = '{"error":true, "msg":"El cliente asociado a la cuent"usuario":"' || user_sistema || '"a está suspendido"}';
				end if;
			else
				salida = '{"error":true, "msg":"la persona asociada a la cuenta está suspendida"}';
			end if;
		else
			salida = '{"error":true, "msg":"la cuenta está suspendida"}';
		end if;
	else
		salida = '{"error":true, "msg":"la password es incorrecta"}';
	end if;
else
	salida = '{"error":true, "msg":"El usuario no existe"}';
end if;
return salida;
end;

$$;


ALTER FUNCTION dielab.valida_usuario(user_sistema character varying, pass_sistema character varying) OWNER TO postgres;

--
-- TOC entry 287 (class 1255 OID 24771)
-- Name: verifica_epp_guante(character varying); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.verifica_epp_guante(epp character varying) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare

resultado		record;
salida			json;
begin
	select * into resultado from dielab.epps where serie_epp = epp;
	if found then
		select corriente_fuga_max::text as fuga into resultado from dielab.epps join dielab.tipo_guante
		on tipo_epp = id_tipo_guante where serie_epp = epp;
		if found then
			salida = '{"error":false, "msg":"' || resultado.fuga || '"}';
		else
			salida = '{"error":false, "msg":"No se encuentra el tipo de guante"}';
		end if;
	else
		salida = '{"error":false, "msg":"No existe el elemento"}';
	end if;

return salida;
end;

$$;


ALTER FUNCTION dielab.verifica_epp_guante(epp character varying) OWNER TO postgres;

--
-- TOC entry 297 (class 1255 OID 24850)
-- Name: verifica_epp_guante(character varying, bigint); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.verifica_epp_guante(epp character varying, id_bateax bigint) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare

resultado		record;
resultado_0		record;
salida			json;
begin
	select * into resultado from dielab.epps where serie_epp = epp;
	if found then
	--chequear que no se encuentre asociado a otro ensayo
		select detalle_ensayo.* into resultado_0 from dielab.detalle_ensayo
		join dielab.epps on detalle_ensayo.serie_epp = id_epp
		where epps.serie_epp = epp;
		if found then
		-- debe ser el mismo codigo de ensayo si no error
			select detalle_ensayo.* into resultado_0 from dielab.detalle_ensayo
			join dielab.epps on detalle_ensayo.serie_epp = id_epp
			where epps.serie_epp = epp and id_batea = id_bateax;
			if found then
				-- es el mismo id_batea => ok
				select corriente_fuga_max::text as fuga into resultado from dielab.epps join dielab.tipo_guante
				on tipo_epp = id_tipo_guante where serie_epp = epp;
				if found then
					salida = '{"error":false, "msg":"' || resultado.fuga || '"}';
				else
					salida = '{"error":false, "msg":"No se encuentra el tipo de guante"}';
				end if;
			else
				-- está asociado a otro id_batea, preguntar
				--salida = '{"error":false, "msg":"El elemento está asociado a otro ensayo"}';
				select corriente_fuga_max::text as fuga into resultado from dielab.epps join dielab.tipo_guante
				on tipo_epp = id_tipo_guante where serie_epp = epp;
				if found then
					salida = '{"error":false, "msg":"' || resultado.fuga || '"}';
				else
					salida = '{"error":false, "msg":"No se encuentra el tipo de guante"}';
				end if;
			end if;
		else
		-- no lo encuentra, ok
			select corriente_fuga_max::text as fuga into resultado from dielab.epps join dielab.tipo_guante
			on tipo_epp = id_tipo_guante where serie_epp = epp;
			if found then
				salida = '{"error":false, "msg":"' || resultado.fuga || '"}';
			else
				salida = '{"error":false, "msg":"No se encuentra el tipo de guante"}';
			end if;
		end if;
	else
		salida = '{"error":false, "msg":"No existe el elemento"}';
	end if;

return salida;
end;

$$;


ALTER FUNCTION dielab.verifica_epp_guante(epp character varying, id_bateax bigint) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 221 (class 1259 OID 24713)
-- Name: clase_epp; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.clase_epp (
    id_clase_epp integer NOT NULL,
    nombre character varying NOT NULL,
    cod_serie character varying NOT NULL,
    tabla_detalle character varying NOT NULL,
    nombre_menu character varying,
    habilitado boolean DEFAULT false,
    tipo_ensayo bigint NOT NULL
);


ALTER TABLE dielab.clase_epp OWNER TO postgres;

--
-- TOC entry 3491 (class 0 OID 0)
-- Dependencies: 221
-- Name: TABLE clase_epp; Type: COMMENT; Schema: dielab; Owner: postgres
--

COMMENT ON TABLE dielab.clase_epp IS 'Describe las clases de Epp que existen como guantes, pertigas, banquetas, etc.';


--
-- TOC entry 223 (class 1259 OID 24737)
-- Name: clase_tipo; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.clase_tipo (
    cod_clase character varying NOT NULL,
    descripcion character varying NOT NULL,
    id_clase bigint NOT NULL
);


ALTER TABLE dielab.clase_tipo OWNER TO postgres;

--
-- TOC entry 3492 (class 0 OID 0)
-- Dependencies: 223
-- Name: TABLE clase_tipo; Type: COMMENT; Schema: dielab; Owner: postgres
--

COMMENT ON TABLE dielab.clase_tipo IS 'Describe las clases de dielectrico: 00, 0 , 1 etc.';


--
-- TOC entry 201 (class 1259 OID 16404)
-- Name: cliente; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.cliente (
    id_cliente bigint NOT NULL,
    nombre text NOT NULL,
    telefono character varying(10) NOT NULL,
    representante character varying(100) NOT NULL,
    direccion character varying(100) NOT NULL,
    nombre_corto character varying(7) NOT NULL,
    suspendido boolean DEFAULT false NOT NULL
);


ALTER TABLE dielab.cliente OWNER TO postgres;

--
-- TOC entry 204 (class 1259 OID 16431)
-- Name: seq_id_tabla; Type: SEQUENCE; Schema: dielab; Owner: postgres
--

CREATE SEQUENCE dielab.seq_id_tabla
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dielab.seq_id_tabla OWNER TO postgres;

--
-- TOC entry 208 (class 1259 OID 16457)
-- Name: cliente_negocio_sucursal; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.cliente_negocio_sucursal (
    id_cliente_n_s integer DEFAULT nextval('dielab.seq_id_tabla'::regclass) NOT NULL,
    cliente integer NOT NULL,
    negocio integer NOT NULL,
    sucursal character varying NOT NULL,
    direccion character varying
);


ALTER TABLE dielab.cliente_negocio_sucursal OWNER TO postgres;

--
-- TOC entry 252 (class 1259 OID 65904)
-- Name: cuerpos_aterramiento; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.cuerpos_aterramiento (
    id bigint NOT NULL,
    nombre character varying NOT NULL
);


ALTER TABLE dielab.cuerpos_aterramiento OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 24703)
-- Name: detalle_ensayo; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.detalle_ensayo (
    id_detalle bigint NOT NULL,
    id_batea bigint NOT NULL,
    serie_epp bigint NOT NULL,
    aprobado boolean,
    detalle json
);


ALTER TABLE dielab.detalle_ensayo OWNER TO postgres;

--
-- TOC entry 210 (class 1259 OID 16474)
-- Name: encabezado_ensayo; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.encabezado_ensayo (
    id_batea bigint NOT NULL,
    cod_ensayo character varying NOT NULL,
    temperatura numeric NOT NULL,
    humedad numeric NOT NULL,
    tecnico integer NOT NULL,
    fecha timestamp without time zone NOT NULL,
    patron character varying NOT NULL,
    estado character varying NOT NULL,
    tipo_ensayo integer NOT NULL,
    fecha_ejecucion date,
    fecha_emision date,
    cliente_n_s integer,
    fecha_ingreso date,
    cod_estado integer NOT NULL,
    cod_patron bigint,
    orden_compra text
);


ALTER TABLE dielab.encabezado_ensayo OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 24695)
-- Name: ensayos_tipo; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.ensayos_tipo (
    id_ensayo_tipo bigint NOT NULL,
    descripcion character varying,
    cod_informe character varying,
    habilitado boolean
);


ALTER TABLE dielab.ensayos_tipo OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 24824)
-- Name: epps; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.epps (
    id_epp bigint NOT NULL,
    serie_epp character varying NOT NULL,
    clase_epp bigint NOT NULL,
    tipo_epp integer NOT NULL,
    cliente_n_s integer NOT NULL,
    estado_epp integer,
    periodicidad integer,
    estado_uso bigint
);


ALTER TABLE dielab.epps OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 16541)
-- Name: estado_ensayo; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.estado_ensayo (
    id_estado integer NOT NULL,
    nombre character varying NOT NULL,
    observacion character varying
);


ALTER TABLE dielab.estado_ensayo OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 24753)
-- Name: estado_epp; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.estado_epp (
    id_estado_epp integer NOT NULL,
    descripcion character varying NOT NULL
);


ALTER TABLE dielab.estado_epp OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 57633)
-- Name: estado_uso; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.estado_uso (
    id bigint NOT NULL,
    nombre_estado character varying NOT NULL
);


ALTER TABLE dielab.estado_uso OWNER TO postgres;

--
-- TOC entry 251 (class 1259 OID 65830)
-- Name: largo_cubrelinea; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.largo_cubrelinea (
    id bigint NOT NULL,
    nombre character varying NOT NULL
);


ALTER TABLE dielab.largo_cubrelinea OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 24800)
-- Name: largo_guante; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.largo_guante (
    id_largo integer NOT NULL,
    valor integer NOT NULL
);


ALTER TABLE dielab.largo_guante OWNER TO postgres;

--
-- TOC entry 249 (class 1259 OID 65809)
-- Name: largo_manta; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.largo_manta (
    id bigint NOT NULL,
    nombre character varying NOT NULL
);


ALTER TABLE dielab.largo_manta OWNER TO postgres;

--
-- TOC entry 256 (class 1259 OID 65959)
-- Name: largo_pertiga; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.largo_pertiga (
    id bigint NOT NULL,
    nombre character varying NOT NULL
);


ALTER TABLE dielab.largo_pertiga OWNER TO postgres;

--
-- TOC entry 203 (class 1259 OID 16417)
-- Name: lista_cliente; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.lista_cliente AS
 SELECT cliente.id_cliente,
    cliente.nombre_corto AS nombre,
    cliente.direccion
   FROM dielab.cliente
  ORDER BY cliente.id_cliente
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.lista_cliente OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 24841)
-- Name: lista_det_guante; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.lista_det_guante AS
 SELECT detalle_ensayo.id_detalle,
    detalle_ensayo.id_batea,
    (detalle_ensayo.detalle ->> 'serie_epp'::text) AS num_serie,
    (detalle_ensayo.detalle ->> 'fuga1'::text) AS i_fuga_1,
    (detalle_ensayo.detalle ->> 'fuga2'::text) AS i_fuga_2,
    (detalle_ensayo.detalle ->> 'fuga3'::text) AS i_fuga_3,
    (detalle_ensayo.detalle ->> 'parches'::text) AS parches,
    (detalle_ensayo.detalle ->> 'promedio'::text) AS promed_fuga,
    (detalle_ensayo.detalle ->> 'tension'::text) AS tension_ensayo,
    (detalle_ensayo.detalle ->> 'resultado'::text) AS aprobado
   FROM ((dielab.detalle_ensayo
     JOIN dielab.epps ON ((detalle_ensayo.serie_epp = epps.id_epp)))
     JOIN dielab.clase_epp ON ((epps.clase_epp = clase_epp.id_clase_epp)))
  ORDER BY detalle_ensayo.id_batea, detalle_ensayo.serie_epp;


ALTER TABLE dielab.lista_det_guante OWNER TO postgres;

--
-- TOC entry 206 (class 1259 OID 16441)
-- Name: negocio; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.negocio (
    id_negocio integer NOT NULL,
    nombre character varying NOT NULL
);


ALTER TABLE dielab.negocio OWNER TO postgres;

--
-- TOC entry 202 (class 1259 OID 16412)
-- Name: sucursales; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.sucursales (
    cod_sucursal character varying(6) NOT NULL,
    nombre character varying(50) NOT NULL
);


ALTER TABLE dielab.sucursales OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 57628)
-- Name: lista_ensayos; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.lista_ensayos AS
 SELECT encabezado_ensayo.id_batea AS id,
    encabezado_ensayo.cod_ensayo AS codigo,
    ((encabezado_ensayo.fecha)::date)::text AS fecha_ingreso,
    cliente.nombre_corto AS cliente,
    negocio.nombre AS negocio,
    estado_ensayo.nombre AS estado,
    encabezado_ensayo.tipo_ensayo
   FROM (((((dielab.encabezado_ensayo
     JOIN dielab.cliente_negocio_sucursal ON ((encabezado_ensayo.cliente_n_s = cliente_negocio_sucursal.id_cliente_n_s)))
     JOIN dielab.cliente ON ((cliente_negocio_sucursal.cliente = cliente.id_cliente)))
     JOIN dielab.sucursales ON (((cliente_negocio_sucursal.sucursal)::text = (sucursales.cod_sucursal)::text)))
     JOIN dielab.negocio ON ((cliente_negocio_sucursal.negocio = negocio.id_negocio)))
     JOIN dielab.estado_ensayo ON ((encabezado_ensayo.cod_estado = estado_ensayo.id_estado)))
  ORDER BY encabezado_ensayo.id_batea DESC;


ALTER TABLE dielab.lista_ensayos OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 24835)
-- Name: lista_epps; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.lista_epps AS
 SELECT epps.id_epp AS id,
    epps.serie_epp AS num_serie,
    cliente.nombre_corto AS cliente,
    negocio.nombre AS negocio,
    sucursales.nombre AS sucursal,
    estado_epp.descripcion AS estado,
    epps.clase_epp
   FROM (((((dielab.epps
     JOIN dielab.cliente_negocio_sucursal ON ((epps.cliente_n_s = cliente_negocio_sucursal.id_cliente_n_s)))
     JOIN dielab.cliente ON ((cliente_negocio_sucursal.cliente = cliente.id_cliente)))
     JOIN dielab.sucursales ON (((cliente_negocio_sucursal.sucursal)::text = (sucursales.cod_sucursal)::text)))
     JOIN dielab.negocio ON ((cliente_negocio_sucursal.negocio = negocio.id_negocio)))
     JOIN dielab.estado_epp ON ((epps.estado_epp = estado_epp.id_estado_epp)))
  ORDER BY epps.id_epp DESC;


ALTER TABLE dielab.lista_epps OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 16569)
-- Name: lista_form_ensayo; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.lista_form_ensayo AS
 SELECT encabezado_ensayo.id_batea,
    cliente_negocio_sucursal.cliente,
    cliente_negocio_sucursal.negocio,
    cliente_negocio_sucursal.sucursal,
    encabezado_ensayo.temperatura,
    encabezado_ensayo.humedad,
    encabezado_ensayo.tecnico,
    encabezado_ensayo.patron,
        CASE
            WHEN (encabezado_ensayo.fecha_ejecucion IS NULL) THEN ((encabezado_ensayo.fecha)::date)::character varying
            ELSE (encabezado_ensayo.fecha_ejecucion)::character varying
        END AS fecha_ejecucion,
        CASE
            WHEN (encabezado_ensayo.fecha_ingreso IS NULL) THEN ((encabezado_ensayo.fecha)::date)::character varying
            ELSE (encabezado_ensayo.fecha_ingreso)::character varying
        END AS fecha_ingreso,
    encabezado_ensayo.cod_estado
   FROM (dielab.encabezado_ensayo
     JOIN dielab.cliente_negocio_sucursal ON ((encabezado_ensayo.cliente_n_s = cliente_negocio_sucursal.id_cliente_n_s)));


ALTER TABLE dielab.lista_form_ensayo OWNER TO postgres;

--
-- TOC entry 207 (class 1259 OID 16449)
-- Name: patron; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.patron (
    id_patron bigint NOT NULL,
    descripcion text NOT NULL,
    marca character varying NOT NULL,
    modelo character varying NOT NULL,
    serie character varying NOT NULL,
    calibracion character varying
);


ALTER TABLE dielab.patron OWNER TO postgres;

--
-- TOC entry 205 (class 1259 OID 16433)
-- Name: tecnicos_ensayo; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.tecnicos_ensayo (
    id_tecnico bigint NOT NULL,
    nombre character varying NOT NULL
);


ALTER TABLE dielab.tecnicos_ensayo OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 41252)
-- Name: lista_informe_pdf; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.lista_informe_pdf AS
 SELECT encabezado_ensayo.cod_ensayo,
    to_char((encabezado_ensayo.fecha_ejecucion)::timestamp with time zone, 'DD/MM/YYYY'::text) AS fecha_ejecucion,
    tecnicos_ensayo.nombre AS tecnico,
    (encabezado_ensayo.temperatura)::text AS temperatura,
    (encabezado_ensayo.humedad)::text AS humedad,
    cliente.nombre AS cliente,
    substr((cliente.direccion)::text, 1, 25) AS dir1,
    substr((cliente.direccion)::text, 26) AS dir2,
    initcap((sucursales.nombre)::text) AS ciudad,
    to_char((encabezado_ensayo.fecha_ingreso)::timestamp with time zone, 'DD/MM/YYYY'::text) AS fecha_ingreso,
    patron.descripcion AS patron,
    patron.marca,
    patron.modelo,
    patron.serie AS serie_patron,
    patron.calibracion,
    initcap((ensayos_tipo.descripcion)::text) AS tipo_epp,
    'Usado'::text AS uso,
    (( SELECT count(*) AS piezas
           FROM (dielab.detalle_ensayo
             JOIN dielab.encabezado_ensayo encabezado_ensayo_1 USING (id_batea))
          WHERE ((encabezado_ensayo_1.cod_ensayo)::text = (encabezado_ensayo.cod_ensayo)::text)))::text AS piezas,
        CASE
            WHEN (encabezado_ensayo.fecha_emision IS NULL) THEN 'PENDIENTE'::text
            ELSE to_char((encabezado_ensayo.fecha_emision)::timestamp with time zone, 'DD/MM/YYYY'::text)
        END AS fecha_emision,
    to_char(((now())::date)::timestamp with time zone, 'DD/MM/YYYY'::text) AS fecha_impresion
   FROM ((((((dielab.encabezado_ensayo
     JOIN dielab.tecnicos_ensayo ON ((encabezado_ensayo.tecnico = tecnicos_ensayo.id_tecnico)))
     JOIN dielab.cliente_negocio_sucursal ON ((encabezado_ensayo.cliente_n_s = cliente_negocio_sucursal.id_cliente_n_s)))
     JOIN dielab.cliente ON ((cliente_negocio_sucursal.cliente = cliente.id_cliente)))
     JOIN dielab.sucursales ON (((cliente_negocio_sucursal.sucursal)::text = (sucursales.cod_sucursal)::text)))
     JOIN dielab.patron ON ((encabezado_ensayo.cod_patron = patron.id_patron)))
     JOIN dielab.ensayos_tipo ON ((encabezado_ensayo.tipo_ensayo = ensayos_tipo.id_ensayo_tipo)));


ALTER TABLE dielab.lista_informe_pdf OWNER TO postgres;

--
-- TOC entry 211 (class 1259 OID 16498)
-- Name: lista_sucursales; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.lista_sucursales AS
 SELECT sucursales.cod_sucursal,
    sucursales.nombre
   FROM dielab.sucursales
  ORDER BY sucursales.nombre
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.lista_sucursales OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 24792)
-- Name: marca; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.marca (
    id_marca integer NOT NULL,
    nombre character varying NOT NULL
);


ALTER TABLE dielab.marca OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 33058)
-- Name: perfil; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.perfil (
    id bigint NOT NULL,
    nombre character varying NOT NULL,
    multicliente boolean DEFAULT false NOT NULL,
    mantenedor boolean DEFAULT false NOT NULL,
    inventario boolean DEFAULT false NOT NULL,
    ensayo boolean DEFAULT false NOT NULL,
    reportes boolean DEFAULT false NOT NULL
);


ALTER TABLE dielab.perfil OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 57655)
-- Name: periodicidad; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.periodicidad (
    id bigint NOT NULL,
    descripcion character varying NOT NULL,
    meses integer NOT NULL
);


ALTER TABLE dielab.periodicidad OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 33048)
-- Name: personas; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.personas (
    rut character varying NOT NULL,
    nombre character varying NOT NULL,
    email character varying NOT NULL,
    telefono character varying NOT NULL,
    suspendida boolean DEFAULT false NOT NULL
);


ALTER TABLE dielab.personas OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 24809)
-- Name: select_clase; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_clase AS
 SELECT clase_tipo.cod_clase AS id,
    clase_tipo.descripcion AS nombre
   FROM dielab.clase_tipo
  ORDER BY clase_tipo.descripcion
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_clase OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 57624)
-- Name: select_clase_ensayo; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_clase_ensayo AS
 SELECT ensayos_tipo.id_ensayo_tipo,
    clase_epp.nombre,
    ensayos_tipo.cod_informe,
    clase_epp.cod_serie,
    clase_epp.tabla_detalle,
    clase_epp.nombre_menu,
    (ensayos_tipo.habilitado AND clase_epp.habilitado) AS habilitado
   FROM (dielab.ensayos_tipo
     JOIN dielab.clase_epp ON ((ensayos_tipo.id_ensayo_tipo = clase_epp.tipo_ensayo)))
  WHERE (ensayos_tipo.habilitado AND clase_epp.habilitado)
  ORDER BY ensayos_tipo.id_ensayo_tipo;


ALTER TABLE dielab.select_clase_ensayo OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 49499)
-- Name: select_clase_epp; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_clase_epp AS
 SELECT clase_epp.id_clase_epp,
    clase_epp.nombre,
    clase_epp.cod_serie,
    clase_epp.tabla_detalle,
    clase_epp.nombre_menu,
    clase_epp.habilitado
   FROM dielab.clase_epp
  WHERE clase_epp.habilitado
  ORDER BY clase_epp.id_clase_epp
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_clase_epp OWNER TO postgres;

--
-- TOC entry 213 (class 1259 OID 16514)
-- Name: select_cliente; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_cliente AS
 SELECT cliente.id_cliente AS id,
    cliente.nombre_corto AS nombre
   FROM dielab.cliente
  ORDER BY cliente.nombre_corto
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_cliente OWNER TO postgres;

--
-- TOC entry 248 (class 1259 OID 57667)
-- Name: select_estado_uso; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_estado_uso AS
 SELECT estado_uso.id,
    estado_uso.nombre_estado AS nombre
   FROM dielab.estado_uso
  ORDER BY estado_uso.nombre_estado;


ALTER TABLE dielab.select_estado_uso OWNER TO postgres;

--
-- TOC entry 266 (class 1259 OID 74029)
-- Name: select_largo_aterramiento; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_largo_aterramiento AS
 SELECT cuerpos_aterramiento.id,
    cuerpos_aterramiento.nombre
   FROM dielab.cuerpos_aterramiento
  ORDER BY cuerpos_aterramiento.id
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_largo_aterramiento OWNER TO postgres;

--
-- TOC entry 264 (class 1259 OID 66044)
-- Name: select_largo_cubrelinea; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_largo_cubrelinea AS
 SELECT largo_cubrelinea.id,
    largo_cubrelinea.nombre
   FROM dielab.largo_cubrelinea
  ORDER BY largo_cubrelinea.id
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_largo_cubrelinea OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 24813)
-- Name: select_largo_guante; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_largo_guante AS
 SELECT largo_guante.id_largo AS id,
    largo_guante.valor AS nombre
   FROM dielab.largo_guante
  ORDER BY largo_guante.id_largo
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_largo_guante OWNER TO postgres;

--
-- TOC entry 263 (class 1259 OID 66040)
-- Name: select_largo_manta; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_largo_manta AS
 SELECT largo_manta.id,
    largo_manta.nombre
   FROM dielab.largo_manta
  ORDER BY largo_manta.id
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_largo_manta OWNER TO postgres;

--
-- TOC entry 265 (class 1259 OID 66048)
-- Name: select_largo_pertiga; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_largo_pertiga AS
 SELECT largo_pertiga.id,
    largo_pertiga.nombre
   FROM dielab.largo_pertiga
  ORDER BY largo_pertiga.id
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_largo_pertiga OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 24805)
-- Name: select_marca; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_marca AS
 SELECT marca.id_marca AS id,
    marca.nombre
   FROM dielab.marca
  ORDER BY marca.nombre
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_marca OWNER TO postgres;

--
-- TOC entry 214 (class 1259 OID 16518)
-- Name: select_negocio; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_negocio AS
 SELECT negocio.id_negocio AS id,
    negocio.nombre
   FROM dielab.negocio
  ORDER BY negocio.nombre
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_negocio OWNER TO postgres;

--
-- TOC entry 267 (class 1259 OID 74033)
-- Name: select_num_cuerpos_aterramiento; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_num_cuerpos_aterramiento AS
 SELECT cuerpos_aterramiento.id,
    cuerpos_aterramiento.nombre
   FROM dielab.cuerpos_aterramiento
  ORDER BY cuerpos_aterramiento.id
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_num_cuerpos_aterramiento OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 16526)
-- Name: select_patron; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_patron AS
 SELECT patron.id_patron AS id,
    ((patron.descripcion || '/'::text) || (patron.marca)::text) AS nombre
   FROM dielab.patron
  ORDER BY patron.descripcion, patron.marca
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_patron OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 57663)
-- Name: select_periodicidad; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_periodicidad AS
 SELECT periodicidad.id,
    periodicidad.descripcion AS nombre
   FROM dielab.periodicidad
  ORDER BY periodicidad.id;


ALTER TABLE dielab.select_periodicidad OWNER TO postgres;

--
-- TOC entry 212 (class 1259 OID 16502)
-- Name: select_sucursal; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_sucursal AS
 SELECT sucursales.cod_sucursal AS id,
    sucursales.nombre
   FROM dielab.sucursales
  ORDER BY sucursales.nombre
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_sucursal OWNER TO postgres;

--
-- TOC entry 215 (class 1259 OID 16522)
-- Name: select_tecnico; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_tecnico AS
 SELECT tecnicos_ensayo.id_tecnico AS id,
    tecnicos_ensayo.nombre
   FROM dielab.tecnicos_ensayo
  ORDER BY tecnicos_ensayo.nombre
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_tecnico OWNER TO postgres;

--
-- TOC entry 253 (class 1259 OID 65914)
-- Name: tipo_aterramiento; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.tipo_aterramiento (
    id_tipo integer NOT NULL,
    marca character varying NOT NULL,
    modelo character varying,
    largo bigint DEFAULT 0 NOT NULL,
    clase bigint DEFAULT 0 NOT NULL,
    corriente_fuga_max double precision NOT NULL,
    descripcion character varying,
    cod_marca bigint NOT NULL
);


ALTER TABLE dielab.tipo_aterramiento OWNER TO postgres;

--
-- TOC entry 258 (class 1259 OID 65994)
-- Name: select_tipo_aterramiento; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_tipo_aterramiento AS
 SELECT tipo_aterramiento.id_tipo AS id,
    (((((((marca.nombre)::text || '_'::text) || 'N°_Cuerpos:_'::text) || (cuerpos_aterramiento.nombre)::text) || '_'::text) || '__corriente_fuga_max='::text) || (tipo_aterramiento.corriente_fuga_max)::text) AS nombre,
    (marca.nombre)::text AS marca,
    (cuerpos_aterramiento.nombre)::text AS num_cuerpos,
    (tipo_aterramiento.corriente_fuga_max)::text AS max_i_fuga
   FROM ((dielab.tipo_aterramiento
     JOIN dielab.cuerpos_aterramiento ON ((tipo_aterramiento.largo = cuerpos_aterramiento.id)))
     JOIN dielab.marca ON ((tipo_aterramiento.cod_marca = marca.id_marca)))
  ORDER BY marca.nombre, cuerpos_aterramiento.nombre;


ALTER TABLE dielab.select_tipo_aterramiento OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 49485)
-- Name: tipo_banqueta; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.tipo_banqueta (
    id_tipo integer NOT NULL,
    marca character varying NOT NULL,
    modelo character varying,
    largo bigint DEFAULT 0 NOT NULL,
    clase bigint NOT NULL,
    corriente_fuga_max double precision NOT NULL,
    descripcion character varying NOT NULL,
    cod_marca bigint NOT NULL
);


ALTER TABLE dielab.tipo_banqueta OWNER TO postgres;

--
-- TOC entry 260 (class 1259 OID 66008)
-- Name: select_tipo_banqueta; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_tipo_banqueta AS
 SELECT tipo_banqueta.id_tipo AS id,
    (((((marca.nombre)::text || '__'::text) || (clase_tipo.descripcion)::text) || '__corriente_fuga_max='::text) || (tipo_banqueta.corriente_fuga_max)::text) AS nombre,
    (marca.nombre)::text AS marca,
    (clase_tipo.descripcion)::text AS clase,
    (tipo_banqueta.corriente_fuga_max)::text AS max_i_fuga
   FROM ((dielab.tipo_banqueta
     JOIN dielab.clase_tipo ON ((tipo_banqueta.clase = clase_tipo.id_clase)))
     JOIN dielab.marca ON ((tipo_banqueta.cod_marca = marca.id_marca)))
  ORDER BY marca.nombre, clase_tipo.descripcion;


ALTER TABLE dielab.select_tipo_banqueta OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 49459)
-- Name: tipo_cubrelinea; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.tipo_cubrelinea (
    id_tipo integer NOT NULL,
    marca character varying NOT NULL,
    modelo character varying,
    largo bigint NOT NULL,
    clase bigint NOT NULL,
    corriente_fuga_max double precision NOT NULL,
    descripcion character varying NOT NULL,
    cod_marca bigint
);


ALTER TABLE dielab.tipo_cubrelinea OWNER TO postgres;

--
-- TOC entry 262 (class 1259 OID 66025)
-- Name: select_tipo_cubrelinea; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_tipo_cubrelinea AS
 SELECT tipo_cubrelinea.id_tipo AS id,
    (((((((marca.nombre)::text || '_'::text) || (largo_cubrelinea.nombre)::text) || '_'::text) || (clase_tipo.descripcion)::text) || '__corriente_fuga_max='::text) || (tipo_cubrelinea.corriente_fuga_max)::text) AS nombre,
    (marca.nombre)::text AS marca,
    (largo_cubrelinea.nombre)::text AS tipo,
    (clase_tipo.descripcion)::text AS clase,
    (tipo_cubrelinea.corriente_fuga_max)::text AS max_i_fuga
   FROM (((dielab.tipo_cubrelinea
     JOIN dielab.largo_cubrelinea ON ((tipo_cubrelinea.largo = largo_cubrelinea.id)))
     JOIN dielab.clase_tipo ON ((tipo_cubrelinea.clase = clase_tipo.id_clase)))
     JOIN dielab.marca ON ((tipo_cubrelinea.cod_marca = marca.id_marca)))
  ORDER BY marca.nombre, largo_cubrelinea.nombre, clase_tipo.descripcion;


ALTER TABLE dielab.select_tipo_cubrelinea OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 24729)
-- Name: tipo_guante; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.tipo_guante (
    id_tipo integer NOT NULL,
    marca character varying NOT NULL,
    modelo character varying,
    largo bigint NOT NULL,
    clase bigint NOT NULL,
    corriente_fuga_max double precision NOT NULL,
    descripcion character varying,
    cod_marca bigint
);


ALTER TABLE dielab.tipo_guante OWNER TO postgres;

--
-- TOC entry 259 (class 1259 OID 65999)
-- Name: select_tipo_guante; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_tipo_guante AS
 SELECT tipo_guante.id_tipo AS id,
    (((((((marca.nombre)::text || '__'::text) || (largo_guante.valor)::text) || '__'::text) || (clase_tipo.descripcion)::text) || '__corriente_fuga_max='::text) || (tipo_guante.corriente_fuga_max)::text) AS nombre,
    (marca.nombre)::text AS marca,
    (largo_guante.valor)::text AS largo,
    (clase_tipo.descripcion)::text AS clase,
    (tipo_guante.corriente_fuga_max)::text AS max_i_fuga
   FROM (((dielab.tipo_guante
     JOIN dielab.clase_tipo ON ((tipo_guante.clase = clase_tipo.id_clase)))
     JOIN dielab.largo_guante ON ((tipo_guante.largo = largo_guante.id_largo)))
     JOIN dielab.marca ON ((tipo_guante.cod_marca = marca.id_marca)))
  ORDER BY marca.nombre, tipo_guante.largo, tipo_guante.clase;


ALTER TABLE dielab.select_tipo_guante OWNER TO postgres;

--
-- TOC entry 254 (class 1259 OID 65940)
-- Name: tipo_loadbuster; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.tipo_loadbuster (
    id_tipo integer NOT NULL,
    marca character varying NOT NULL,
    modelo character varying,
    largo bigint DEFAULT 0 NOT NULL,
    clase bigint DEFAULT 0 NOT NULL,
    corriente_fuga_max double precision NOT NULL,
    descripcion character varying,
    cod_marca bigint NOT NULL
);


ALTER TABLE dielab.tipo_loadbuster OWNER TO postgres;

--
-- TOC entry 255 (class 1259 OID 65955)
-- Name: select_tipo_loadbuster; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_tipo_loadbuster AS
 SELECT tipo_loadbuster.id_tipo AS id,
    (((marca.nombre)::text || '__corriente_fuga_max='::text) || (tipo_loadbuster.corriente_fuga_max)::text) AS nombre,
    (marca.nombre)::text AS marca,
    (tipo_loadbuster.corriente_fuga_max)::text AS max_i_fuga
   FROM (dielab.tipo_loadbuster
     JOIN dielab.marca ON ((tipo_loadbuster.cod_marca = marca.id_marca)))
  ORDER BY marca.nombre;


ALTER TABLE dielab.select_tipo_loadbuster OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 49438)
-- Name: tipo_manguilla; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.tipo_manguilla (
    id_tipo integer NOT NULL,
    marca character varying,
    modelo character varying,
    largo bigint DEFAULT 0 NOT NULL,
    clase bigint NOT NULL,
    corriente_fuga_max double precision NOT NULL,
    descripcion character varying,
    cod_marca bigint
);


ALTER TABLE dielab.tipo_manguilla OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 49503)
-- Name: select_tipo_manguilla; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_tipo_manguilla AS
 SELECT tipo_manguilla.id_tipo AS id,
    (((((marca.nombre)::text || '__'::text) || (clase_tipo.descripcion)::text) || '__corriente_fuga_max='::text) || (tipo_manguilla.corriente_fuga_max)::text) AS nombre,
    (marca.nombre)::text AS marca,
    (clase_tipo.descripcion)::text AS clase,
    (tipo_manguilla.corriente_fuga_max)::text AS max_i_fuga
   FROM ((dielab.tipo_manguilla
     JOIN dielab.clase_tipo ON ((tipo_manguilla.clase = clase_tipo.id_clase)))
     JOIN dielab.marca ON ((tipo_manguilla.cod_marca = marca.id_marca)))
  ORDER BY marca.nombre, tipo_manguilla.clase;


ALTER TABLE dielab.select_tipo_manguilla OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 49472)
-- Name: tipo_manta; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.tipo_manta (
    id_tipo integer NOT NULL,
    marca character varying NOT NULL,
    modelo character varying,
    largo bigint NOT NULL,
    clase bigint NOT NULL,
    corriente_fuga_max double precision NOT NULL,
    descripcion character varying,
    cod_marca bigint
);


ALTER TABLE dielab.tipo_manta OWNER TO postgres;

--
-- TOC entry 250 (class 1259 OID 65825)
-- Name: select_tipo_manta; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_tipo_manta AS
 SELECT tipo_manta.id_tipo AS id,
    (((((((marca.nombre)::text || '_'::text) || (largo_manta.nombre)::text) || '_'::text) || (clase_tipo.descripcion)::text) || '__corriente_fuga_max='::text) || (tipo_manta.corriente_fuga_max)::text) AS nombre,
    (marca.nombre)::text AS marca,
    (largo_manta.nombre)::text AS largo,
    (clase_tipo.descripcion)::text AS clase,
    (tipo_manta.corriente_fuga_max)::text AS max_i_fuga
   FROM (((dielab.tipo_manta
     JOIN dielab.largo_manta ON ((tipo_manta.largo = largo_manta.id)))
     JOIN dielab.clase_tipo ON ((tipo_manta.clase = clase_tipo.id_clase)))
     JOIN dielab.marca ON ((tipo_manta.cod_marca = marca.id_marca)))
  ORDER BY marca.nombre, largo_manta.nombre, clase_tipo.descripcion;


ALTER TABLE dielab.select_tipo_manta OWNER TO postgres;

--
-- TOC entry 257 (class 1259 OID 65969)
-- Name: tipo_pertiga; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.tipo_pertiga (
    id_tipo integer NOT NULL,
    marca character varying NOT NULL,
    modelo character varying,
    largo bigint NOT NULL,
    clase bigint DEFAULT 0 NOT NULL,
    corriente_fuga_max double precision NOT NULL,
    descripcion character varying,
    cod_marca bigint
);


ALTER TABLE dielab.tipo_pertiga OWNER TO postgres;

--
-- TOC entry 261 (class 1259 OID 66020)
-- Name: select_tipo_pertiga; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_tipo_pertiga AS
 SELECT tipo_pertiga.id_tipo AS id,
    (((((marca.nombre)::text || '_'::text) || (largo_manta.nombre)::text) || '__corriente_fuga_max='::text) || (tipo_pertiga.corriente_fuga_max)::text) AS nombre,
    (marca.nombre)::text AS marca,
    (largo_manta.nombre)::text AS largo,
    (tipo_pertiga.corriente_fuga_max)::text AS max_i_fuga
   FROM ((dielab.tipo_pertiga
     JOIN dielab.largo_manta ON ((tipo_pertiga.largo = largo_manta.id)))
     JOIN dielab.marca ON ((tipo_pertiga.cod_marca = marca.id_marca)))
  ORDER BY marca.nombre, largo_manta.nombre;


ALTER TABLE dielab.select_tipo_pertiga OWNER TO postgres;

--
-- TOC entry 209 (class 1259 OID 16466)
-- Name: seq_cod_ensayo; Type: SEQUENCE; Schema: dielab; Owner: postgres
--

CREATE SEQUENCE dielab.seq_cod_ensayo
    START WITH 100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dielab.seq_cod_ensayo OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 33093)
-- Name: usuarios; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.usuarios (
    id bigint NOT NULL,
    perfil bigint NOT NULL,
    rut character varying NOT NULL,
    password_md5 character varying NOT NULL,
    cliente bigint NOT NULL,
    usuario character varying NOT NULL,
    suspendida boolean DEFAULT false NOT NULL
);


ALTER TABLE dielab.usuarios OWNER TO postgres;

--
-- TOC entry 3276 (class 2606 OID 74012)
-- Name: tipo_aterramiento ate_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_aterramiento
    ADD CONSTRAINT ate_unico UNIQUE (cod_marca, largo, corriente_fuga_max);


--
-- TOC entry 3253 (class 2606 OID 74014)
-- Name: tipo_banqueta ban_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_banqueta
    ADD CONSTRAINT ban_unico UNIQUE (cod_marca, clase, corriente_fuga_max);


--
-- TOC entry 3201 (class 2606 OID 24712)
-- Name: detalle_ensayo batea_epp_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.detalle_ensayo
    ADD CONSTRAINT batea_epp_unico UNIQUE (id_batea, serie_epp);


--
-- TOC entry 3205 (class 2606 OID 24720)
-- Name: clase_epp clase_epp_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.clase_epp
    ADD CONSTRAINT clase_epp_pkey PRIMARY KEY (id_clase_epp);


--
-- TOC entry 3216 (class 2606 OID 24818)
-- Name: clase_tipo clase_tipo_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.clase_tipo
    ADD CONSTRAINT clase_tipo_pkey PRIMARY KEY (id_clase);


--
-- TOC entry 3191 (class 2606 OID 16464)
-- Name: cliente_negocio_sucursal cliente-negocio-sucursal_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.cliente_negocio_sucursal
    ADD CONSTRAINT "cliente-negocio-sucursal_pkey" PRIMARY KEY (id_cliente_n_s);


--
-- TOC entry 3181 (class 2606 OID 16411)
-- Name: cliente cliente_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.cliente
    ADD CONSTRAINT cliente_pkey PRIMARY KEY (id_cliente);


--
-- TOC entry 3193 (class 2606 OID 16497)
-- Name: encabezado_ensayo cod_ensayo_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.encabezado_ensayo
    ADD CONSTRAINT cod_ensayo_unico UNIQUE (cod_ensayo);


--
-- TOC entry 3244 (class 2606 OID 74016)
-- Name: tipo_cubrelinea cub_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_cubrelinea
    ADD CONSTRAINT cub_unico UNIQUE (cod_marca, clase, largo, corriente_fuga_max);


--
-- TOC entry 3272 (class 2606 OID 65911)
-- Name: cuerpos_aterramiento cuerpos_aterramiento_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.cuerpos_aterramiento
    ADD CONSTRAINT cuerpos_aterramiento_pkey PRIMARY KEY (id);


--
-- TOC entry 3203 (class 2606 OID 24710)
-- Name: detalle_ensayo detalle_ensayo_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.detalle_ensayo
    ADD CONSTRAINT detalle_ensayo_pkey PRIMARY KEY (id_detalle);


--
-- TOC entry 3229 (class 2606 OID 33057)
-- Name: personas email_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.personas
    ADD CONSTRAINT email_unico UNIQUE (email);


--
-- TOC entry 3195 (class 2606 OID 16481)
-- Name: encabezado_ensayo encabezado_ensayo_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.encabezado_ensayo
    ADD CONSTRAINT encabezado_ensayo_pkey PRIMARY KEY (id_batea);


--
-- TOC entry 3199 (class 2606 OID 24702)
-- Name: ensayos_tipo ensayos_tipo_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.ensayos_tipo
    ADD CONSTRAINT ensayos_tipo_pkey PRIMARY KEY (id_ensayo_tipo);


--
-- TOC entry 3224 (class 2606 OID 24831)
-- Name: epps epps_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.epps
    ADD CONSTRAINT epps_pkey PRIMARY KEY (id_epp);


--
-- TOC entry 3197 (class 2606 OID 16548)
-- Name: estado_ensayo estado_ensayo_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.estado_ensayo
    ADD CONSTRAINT estado_ensayo_pkey PRIMARY KEY (id_estado);


--
-- TOC entry 3218 (class 2606 OID 24760)
-- Name: estado_epp estado_epp_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.estado_epp
    ADD CONSTRAINT estado_epp_pkey PRIMARY KEY (id_estado_epp);


--
-- TOC entry 3258 (class 2606 OID 57642)
-- Name: estado_uso estado_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.estado_uso
    ADD CONSTRAINT estado_unico UNIQUE (nombre_estado);


--
-- TOC entry 3260 (class 2606 OID 57640)
-- Name: estado_uso estado_uso_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.estado_uso
    ADD CONSTRAINT estado_uso_pkey PRIMARY KEY (id);


--
-- TOC entry 3212 (class 2606 OID 74018)
-- Name: tipo_guante gua_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_guante
    ADD CONSTRAINT gua_unico UNIQUE (cod_marca, clase, largo, corriente_fuga_max);


--
-- TOC entry 3268 (class 2606 OID 65837)
-- Name: largo_cubrelinea largo_cubrelinea_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.largo_cubrelinea
    ADD CONSTRAINT largo_cubrelinea_pkey PRIMARY KEY (id);


--
-- TOC entry 3264 (class 2606 OID 65816)
-- Name: largo_manta largo_manta_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.largo_manta
    ADD CONSTRAINT largo_manta_pkey PRIMARY KEY (id);


--
-- TOC entry 3284 (class 2606 OID 65966)
-- Name: largo_pertiga largo_pertiga_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.largo_pertiga
    ADD CONSTRAINT largo_pertiga_pkey PRIMARY KEY (id);


--
-- TOC entry 3222 (class 2606 OID 24804)
-- Name: largo_guante lguante_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.largo_guante
    ADD CONSTRAINT lguante_pkey PRIMARY KEY (id_largo);


--
-- TOC entry 3280 (class 2606 OID 74020)
-- Name: tipo_loadbuster loa_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_loadbuster
    ADD CONSTRAINT loa_unico UNIQUE (cod_marca, corriente_fuga_max);


--
-- TOC entry 3240 (class 2606 OID 74024)
-- Name: tipo_manguilla man_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_manguilla
    ADD CONSTRAINT man_unico UNIQUE (cod_marca, clase, corriente_fuga_max);


--
-- TOC entry 3220 (class 2606 OID 24799)
-- Name: marca marca_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.marca
    ADD CONSTRAINT marca_pkey PRIMARY KEY (id_marca);


--
-- TOC entry 3249 (class 2606 OID 74026)
-- Name: tipo_manta mat_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_manta
    ADD CONSTRAINT mat_unico UNIQUE (cod_marca, largo, clase, corriente_fuga_max);


--
-- TOC entry 3187 (class 2606 OID 16448)
-- Name: negocio negocio_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.negocio
    ADD CONSTRAINT negocio_pkey PRIMARY KEY (id_negocio);


--
-- TOC entry 3270 (class 2606 OID 65839)
-- Name: largo_cubrelinea nombre_cubrelinea_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.largo_cubrelinea
    ADD CONSTRAINT nombre_cubrelinea_unico UNIQUE (nombre);


--
-- TOC entry 3274 (class 2606 OID 65913)
-- Name: cuerpos_aterramiento nombre_cuerpos_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.cuerpos_aterramiento
    ADD CONSTRAINT nombre_cuerpos_unico UNIQUE (nombre);


--
-- TOC entry 3286 (class 2606 OID 65968)
-- Name: largo_pertiga nombre_largo_pertiga_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.largo_pertiga
    ADD CONSTRAINT nombre_largo_pertiga_unico UNIQUE (nombre);


--
-- TOC entry 3266 (class 2606 OID 65818)
-- Name: largo_manta nombre_manta_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.largo_manta
    ADD CONSTRAINT nombre_manta_unico UNIQUE (nombre);


--
-- TOC entry 3189 (class 2606 OID 16456)
-- Name: patron patron_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.patron
    ADD CONSTRAINT patron_pkey PRIMARY KEY (id_patron);


--
-- TOC entry 3288 (class 2606 OID 74028)
-- Name: tipo_pertiga per_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_pertiga
    ADD CONSTRAINT per_unico UNIQUE (cod_marca, largo, corriente_fuga_max);


--
-- TOC entry 3233 (class 2606 OID 33070)
-- Name: perfil perfil_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.perfil
    ADD CONSTRAINT perfil_pkey PRIMARY KEY (id);


--
-- TOC entry 3262 (class 2606 OID 57662)
-- Name: periodicidad periodicidad_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.periodicidad
    ADD CONSTRAINT periodicidad_pkey PRIMARY KEY (id);


--
-- TOC entry 3231 (class 2606 OID 33055)
-- Name: personas personas_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.personas
    ADD CONSTRAINT personas_pkey PRIMARY KEY (rut);


--
-- TOC entry 3227 (class 2606 OID 24833)
-- Name: epps serie_unica; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.epps
    ADD CONSTRAINT serie_unica UNIQUE (serie_epp);


--
-- TOC entry 3183 (class 2606 OID 16416)
-- Name: sucursales sucursales_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.sucursales
    ADD CONSTRAINT sucursales_pkey PRIMARY KEY (cod_sucursal);


--
-- TOC entry 3185 (class 2606 OID 16440)
-- Name: tecnicos_ensayo tecnicos_ensayo_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tecnicos_ensayo
    ADD CONSTRAINT tecnicos_ensayo_pkey PRIMARY KEY (id_tecnico);


--
-- TOC entry 3278 (class 2606 OID 65922)
-- Name: tipo_aterramiento tipo_aterramiento_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_aterramiento
    ADD CONSTRAINT tipo_aterramiento_pkey PRIMARY KEY (id_tipo);


--
-- TOC entry 3256 (class 2606 OID 49492)
-- Name: tipo_banqueta tipo_banqueta_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_banqueta
    ADD CONSTRAINT tipo_banqueta_pkey PRIMARY KEY (id_tipo);


--
-- TOC entry 3246 (class 2606 OID 49466)
-- Name: tipo_cubrelinea tipo_cubrelinea_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_cubrelinea
    ADD CONSTRAINT tipo_cubrelinea_pkey PRIMARY KEY (id_tipo);


--
-- TOC entry 3208 (class 2606 OID 57623)
-- Name: clase_epp tipo_ens_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.clase_epp
    ADD CONSTRAINT tipo_ens_unico UNIQUE (tipo_ensayo);


--
-- TOC entry 3214 (class 2606 OID 24736)
-- Name: tipo_guante tipo_guante_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_guante
    ADD CONSTRAINT tipo_guante_pkey PRIMARY KEY (id_tipo);


--
-- TOC entry 3282 (class 2606 OID 65949)
-- Name: tipo_loadbuster tipo_loadbuster_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_loadbuster
    ADD CONSTRAINT tipo_loadbuster_pkey PRIMARY KEY (id_tipo);


--
-- TOC entry 3242 (class 2606 OID 49445)
-- Name: tipo_manguilla tipo_manguilla_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_manguilla
    ADD CONSTRAINT tipo_manguilla_pkey PRIMARY KEY (id_tipo);


--
-- TOC entry 3251 (class 2606 OID 49479)
-- Name: tipo_manta tipo_manta_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_manta
    ADD CONSTRAINT tipo_manta_pkey PRIMARY KEY (id_tipo);


--
-- TOC entry 3290 (class 2606 OID 65977)
-- Name: tipo_pertiga tipo_pertiga_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_pertiga
    ADD CONSTRAINT tipo_pertiga_pkey PRIMARY KEY (id_tipo);


--
-- TOC entry 3238 (class 2606 OID 33100)
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);


--
-- TOC entry 3209 (class 1259 OID 41262)
-- Name: fki_fk_clase_epp; Type: INDEX; Schema: dielab; Owner: postgres
--

CREATE INDEX fki_fk_clase_epp ON dielab.tipo_guante USING btree (clase);


--
-- TOC entry 3210 (class 1259 OID 41268)
-- Name: fki_fk_clase_tipo; Type: INDEX; Schema: dielab; Owner: postgres
--

CREATE INDEX fki_fk_clase_tipo ON dielab.tipo_guante USING btree (clase);


--
-- TOC entry 3234 (class 1259 OID 33111)
-- Name: fki_fk_cliente; Type: INDEX; Schema: dielab; Owner: postgres
--

CREATE INDEX fki_fk_cliente ON dielab.usuarios USING btree (cliente);


--
-- TOC entry 3225 (class 1259 OID 57654)
-- Name: fki_fk_estado_uso; Type: INDEX; Schema: dielab; Owner: postgres
--

CREATE INDEX fki_fk_estado_uso ON dielab.epps USING btree (estado_uso);


--
-- TOC entry 3247 (class 1259 OID 65824)
-- Name: fki_fk_largo; Type: INDEX; Schema: dielab; Owner: postgres
--

CREATE INDEX fki_fk_largo ON dielab.tipo_manta USING btree (largo);


--
-- TOC entry 3254 (class 1259 OID 65855)
-- Name: fki_fk_marca; Type: INDEX; Schema: dielab; Owner: postgres
--

CREATE INDEX fki_fk_marca ON dielab.tipo_banqueta USING btree (cod_marca);


--
-- TOC entry 3235 (class 1259 OID 33118)
-- Name: fki_fk_perfil; Type: INDEX; Schema: dielab; Owner: postgres
--

CREATE INDEX fki_fk_perfil ON dielab.usuarios USING btree (perfil);


--
-- TOC entry 3236 (class 1259 OID 33112)
-- Name: fki_fk_rut; Type: INDEX; Schema: dielab; Owner: postgres
--

CREATE INDEX fki_fk_rut ON dielab.usuarios USING btree (rut);


--
-- TOC entry 3206 (class 1259 OID 57621)
-- Name: fki_fk_tipo_ensayo; Type: INDEX; Schema: dielab; Owner: postgres
--

CREATE INDEX fki_fk_tipo_ensayo ON dielab.clase_epp USING btree (tipo_ensayo);


--
-- TOC entry 3315 (class 2620 OID 16553)
-- Name: encabezado_ensayo trig_act_estado; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_estado AFTER INSERT OR UPDATE ON dielab.encabezado_ensayo FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_estado();


--
-- TOC entry 3321 (class 2620 OID 74002)
-- Name: tipo_aterramiento trig_act_marca; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_marca BEFORE INSERT OR UPDATE ON dielab.tipo_aterramiento FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_nombre_marca();


--
-- TOC entry 3320 (class 2620 OID 74003)
-- Name: tipo_banqueta trig_act_marca; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_marca BEFORE INSERT OR UPDATE ON dielab.tipo_banqueta FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_nombre_marca();


--
-- TOC entry 3318 (class 2620 OID 74004)
-- Name: tipo_cubrelinea trig_act_marca; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_marca BEFORE INSERT OR UPDATE ON dielab.tipo_cubrelinea FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_nombre_marca();


--
-- TOC entry 3316 (class 2620 OID 74005)
-- Name: tipo_guante trig_act_marca; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_marca BEFORE INSERT OR UPDATE ON dielab.tipo_guante FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_nombre_marca();


--
-- TOC entry 3322 (class 2620 OID 74006)
-- Name: tipo_loadbuster trig_act_marca; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_marca BEFORE INSERT OR UPDATE ON dielab.tipo_loadbuster FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_nombre_marca();


--
-- TOC entry 3317 (class 2620 OID 74001)
-- Name: tipo_manguilla trig_act_marca; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_marca BEFORE INSERT OR UPDATE ON dielab.tipo_manguilla FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_nombre_marca();


--
-- TOC entry 3319 (class 2620 OID 74007)
-- Name: tipo_manta trig_act_marca; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_marca BEFORE INSERT OR UPDATE ON dielab.tipo_manta FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_nombre_marca();


--
-- TOC entry 3323 (class 2620 OID 74008)
-- Name: tipo_pertiga trig_act_marca; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_marca BEFORE INSERT OR UPDATE ON dielab.tipo_pertiga FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_nombre_marca();


--
-- TOC entry 3295 (class 2606 OID 41269)
-- Name: epps fk_clase_epp; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.epps
    ADD CONSTRAINT fk_clase_epp FOREIGN KEY (clase_epp) REFERENCES dielab.clase_epp(id_clase_epp) MATCH FULL;


--
-- TOC entry 3292 (class 2606 OID 41263)
-- Name: tipo_guante fk_clase_tipo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_guante
    ADD CONSTRAINT fk_clase_tipo FOREIGN KEY (clase) REFERENCES dielab.clase_tipo(id_clase) MATCH FULL;


--
-- TOC entry 3300 (class 2606 OID 49446)
-- Name: tipo_manguilla fk_clase_tipo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_manguilla
    ADD CONSTRAINT fk_clase_tipo FOREIGN KEY (clase) REFERENCES dielab.clase_tipo(id_clase) MATCH FULL;


--
-- TOC entry 3302 (class 2606 OID 49467)
-- Name: tipo_cubrelinea fk_clase_tipo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_cubrelinea
    ADD CONSTRAINT fk_clase_tipo FOREIGN KEY (clase) REFERENCES dielab.clase_tipo(id_clase) MATCH FULL;


--
-- TOC entry 3305 (class 2606 OID 49480)
-- Name: tipo_manta fk_clase_tipo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_manta
    ADD CONSTRAINT fk_clase_tipo FOREIGN KEY (clase) REFERENCES dielab.clase_tipo(id_clase) MATCH FULL;


--
-- TOC entry 3308 (class 2606 OID 49493)
-- Name: tipo_banqueta fk_clase_tipo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_banqueta
    ADD CONSTRAINT fk_clase_tipo FOREIGN KEY (clase) REFERENCES dielab.clase_tipo(id_clase) MATCH FULL;


--
-- TOC entry 3297 (class 2606 OID 33101)
-- Name: usuarios fk_cliente; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.usuarios
    ADD CONSTRAINT fk_cliente FOREIGN KEY (cliente) REFERENCES dielab.cliente(id_cliente) MATCH FULL ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3296 (class 2606 OID 57649)
-- Name: epps fk_estado_uso; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.epps
    ADD CONSTRAINT fk_estado_uso FOREIGN KEY (estado_uso) REFERENCES dielab.estado_uso(id) MATCH FULL;


--
-- TOC entry 3306 (class 2606 OID 65819)
-- Name: tipo_manta fk_largo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_manta
    ADD CONSTRAINT fk_largo FOREIGN KEY (largo) REFERENCES dielab.largo_manta(id) MATCH FULL;


--
-- TOC entry 3303 (class 2606 OID 65840)
-- Name: tipo_cubrelinea fk_largo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_cubrelinea
    ADD CONSTRAINT fk_largo FOREIGN KEY (largo) REFERENCES dielab.largo_cubrelinea(id) MATCH FULL;


--
-- TOC entry 3294 (class 2606 OID 65872)
-- Name: tipo_guante fk_largo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_guante
    ADD CONSTRAINT fk_largo FOREIGN KEY (largo) REFERENCES dielab.largo_guante(id_largo) MATCH FULL;


--
-- TOC entry 3310 (class 2606 OID 65923)
-- Name: tipo_aterramiento fk_largo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_aterramiento
    ADD CONSTRAINT fk_largo FOREIGN KEY (largo) REFERENCES dielab.cuerpos_aterramiento(id) MATCH FULL ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3313 (class 2606 OID 65978)
-- Name: tipo_pertiga fk_largo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_pertiga
    ADD CONSTRAINT fk_largo FOREIGN KEY (largo) REFERENCES dielab.largo_pertiga(id) MATCH FULL ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3309 (class 2606 OID 65850)
-- Name: tipo_banqueta fk_marca; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_banqueta
    ADD CONSTRAINT fk_marca FOREIGN KEY (cod_marca) REFERENCES dielab.marca(id_marca) MATCH FULL;


--
-- TOC entry 3304 (class 2606 OID 65856)
-- Name: tipo_cubrelinea fk_marca; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_cubrelinea
    ADD CONSTRAINT fk_marca FOREIGN KEY (cod_marca) REFERENCES dielab.marca(id_marca) MATCH FULL;


--
-- TOC entry 3293 (class 2606 OID 65861)
-- Name: tipo_guante fk_marca; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_guante
    ADD CONSTRAINT fk_marca FOREIGN KEY (cod_marca) REFERENCES dielab.marca(id_marca) MATCH FULL;


--
-- TOC entry 3301 (class 2606 OID 65886)
-- Name: tipo_manguilla fk_marca; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_manguilla
    ADD CONSTRAINT fk_marca FOREIGN KEY (cod_marca) REFERENCES dielab.marca(id_marca) MATCH FULL;


--
-- TOC entry 3307 (class 2606 OID 65892)
-- Name: tipo_manta fk_marca; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_manta
    ADD CONSTRAINT fk_marca FOREIGN KEY (cod_marca) REFERENCES dielab.marca(id_marca) MATCH FULL;


--
-- TOC entry 3311 (class 2606 OID 65928)
-- Name: tipo_aterramiento fk_marca; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_aterramiento
    ADD CONSTRAINT fk_marca FOREIGN KEY (cod_marca) REFERENCES dielab.marca(id_marca) MATCH FULL ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3312 (class 2606 OID 65950)
-- Name: tipo_loadbuster fk_marca; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_loadbuster
    ADD CONSTRAINT fk_marca FOREIGN KEY (cod_marca) REFERENCES dielab.marca(id_marca) MATCH FULL ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3314 (class 2606 OID 65983)
-- Name: tipo_pertiga fk_marca; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_pertiga
    ADD CONSTRAINT fk_marca FOREIGN KEY (cod_marca) REFERENCES dielab.marca(id_marca) MATCH FULL ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3299 (class 2606 OID 33113)
-- Name: usuarios fk_perfil; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.usuarios
    ADD CONSTRAINT fk_perfil FOREIGN KEY (perfil) REFERENCES dielab.perfil(id) MATCH FULL ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3298 (class 2606 OID 33106)
-- Name: usuarios fk_rut; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.usuarios
    ADD CONSTRAINT fk_rut FOREIGN KEY (rut) REFERENCES dielab.personas(rut) MATCH FULL ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3291 (class 2606 OID 57616)
-- Name: clase_epp fk_tipo_ensayo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.clase_epp
    ADD CONSTRAINT fk_tipo_ensayo FOREIGN KEY (tipo_ensayo) REFERENCES dielab.ensayos_tipo(id_ensayo_tipo) MATCH FULL ON UPDATE RESTRICT ON DELETE RESTRICT;


-- Completed on 2022-07-13 20:52:53

--
-- PostgreSQL database dump complete
--

