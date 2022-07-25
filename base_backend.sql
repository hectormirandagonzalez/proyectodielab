--
-- PostgreSQL database dump
--

-- Dumped from database version 13.7
-- Dumped by pg_dump version 14.2

-- Started on 2022-07-24 22:03:48

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
-- TOC entry 306 (class 1255 OID 82332)
-- Name: actualiza_calibracion(); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.actualiza_calibracion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare

resultado   record;
valor_calibracion	text;

begin
valor_calibracion := '';
select * into resultado from dielab.meses where id = new.mes_calibracion;
if found then
	valor_calibracion := valor_calibracion || resultado.nombre || ' ';
else
end if;
select * into resultado from dielab.anual where id = new.periodo_calibracion;
if found then
	valor_calibracion := valor_calibracion || resultado.nombre || ' ';
else
end if;
new.calibracion := valor_calibracion;
   
return new;

end
$$;


ALTER FUNCTION dielab.actualiza_calibracion() OWNER TO postgres;

--
-- TOC entry 296 (class 1255 OID 16551)
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
-- TOC entry 304 (class 1255 OID 66031)
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
-- TOC entry 322 (class 1255 OID 90454)
-- Name: elimina_epp(bigint, character varying); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.elimina_epp(idx bigint, accionx character varying) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare

--id_epp			double precision;
salida        	json;
resultado		record;
resultado1		record;
--codigo			text;
begin

if accionX = 'borra' then
	select * into resultado from dielab.epps where id_epp = idx;
	if found then
		if resultado.estado_epp = 0 then
			-- solo en estado 0 borrar, pero verificar que no esté asociado a un detalle
			select id_batea, cod_ensayo into resultado1 from dielab.encabezado_ensayo join dielab.detalle_ensayo
			using(id_batea) join dielab.epps on detalle_ensayo.serie_epp = id_epp
			where epps.serie_epp = resultado.serie_epp;
			if found then
				--esta asociado, no es posible borrar
				salida = '{"error":true, "msg":"El epp está asociado al ensayo ' || resultado1.cod_ensayo || '"}';
			else
				-- no esta asociado a ningun ensayo
				delete from dielab.epps where id_epp = idx;
				salida = '{"error":false, "msg":"Operación realizada con éxito"}';
			end if;
		else
			salida = '{"error":true, "msg":"El epp no está en un estado que se pueda borrar"}';
		end if;
	else
		salida = '{"error":false, "msg":"Operación realizada con éxito"}';
	end if;
elseif accionX = 'baja' then
	select * into resultado from dielab.epps where id_epp = idx;
		if found then
		-- lo encuentra , lo da de baja actualizando el estado
			update dielab.epps set estado_epp = 3 where id_epp = idx;
			salida = '{"error":false, "msg":"Operación realizada con éxito"}';
		else
			salida = '{"error":true, "msg":"El epp no se encuentra en la base"}';
		end if;
else
	salida = '{"error":true, "msg":"Operación desconocida"}';
end if;

return salida;

end;

$$;


ALTER FUNCTION dielab.elimina_epp(idx bigint, accionx character varying) OWNER TO postgres;

--
-- TOC entry 321 (class 1255 OID 90442)
-- Name: elimina_param(character varying, bigint); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.elimina_param(tipo_tablax character varying, idx bigint) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare

--id_epp			double precision;
salida        	json;
resultado		record;
--codigo			text;
begin

if tipo_tablaX = 'tecnico' then
	select * into resultado from dielab.tecnicos_ensayo where id_tecnico = idX;
	if found then
		select * into resultado from dielab.tecnicos_ensayo join dielab.encabezado_ensayo
		on tecnicos_ensayo.id_tecnico = encabezado_ensayo.tecnico 
		where tecnicos_ensayo.id_tecnico = idX;
		if found then
		-- desactivar porque tiene ensayos asociados
			update dielab.tecnicos_ensayo set activo = false where tecnicos_ensayo.id_tecnico = idX;
		else
		-- eliminar porque no tiene ensayos
			delete from dielab.tecnicos_ensayo where tecnicos_ensayo.id_tecnico = idX;
		end if;
		salida = '{"error":false, "msg":"Operación realizada con éxito"}';
	else
		salida = '{"error":true, "msg":"No existe el nombre del técnico en la base"}';
	end if;
elseif tipo_tablaX = 'patron' then
	select * into resultado from dielab.patron where id_patron = idX;
	if found then
		select * into resultado from dielab.patron join dielab.encabezado_ensayo
		on patron.id_patron = encabezado_ensayo.cod_patron 
		where patron.id_patron = idX;
		if found then
		-- desactivar porque tiene ensayos asociados
			update dielab.patron set activo = false where patron.id_patron = idX;
		else
		-- eliminar porque no tiene ensayos
			delete from dielab.patron where patron.id_patron = idX;
		end if;
		salida = '{"error":false, "msg":"Operación realizada con éxito"}';
	else
		salida = '{"error":true, "msg":"No existe el patrón en la base"}';
	end if;
else

end if;

return salida;
EXCEPTION
	WHEN others THEN
		salida = '{"error":true, "msg":"Se produjo un error al realizar la operación"}';
		return salida;

end;

$$;


ALTER FUNCTION dielab.elimina_param(tipo_tablax character varying, idx bigint) OWNER TO postgres;

--
-- TOC entry 301 (class 1255 OID 90430)
-- Name: elimina_tecnico(character varying); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.elimina_tecnico(tecnicox character varying) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare

--id_epp			double precision;
salida        	json;
resultado		record;
--codigo			text;
begin

select * into resultado from dielab.tecnicos_ensayo where trim(nombre) = trim(tecnicoX);
if found then
	select * into resultado from dielab.tecnicos_ensayo join dielab.encabezado_ensayo
	on tecnicos_ensayo.id_tecnico = encabezado_ensayo.tecnico 
	where tecnicos_ensayo.nombre = tecnicoX;
	if found then
	-- desactivar porque tiene ensayos asociados
		update dielab.tecnicos_ensayo set activo = false where trim(nombre) = trim(tecnicoX);
	else
	-- eliminar porque no tiene ensayos
		delete from dielab.tecnicos_ensayo where trim(nombre) = trim(tecnicoX);
	end if;
	salida = '{"error":false, "msg":"Operación realizada con éxito"}';
else
-- no existe el tecnico
	salida = '{"error":true, "msg":"No existe el nombre del técnico en la base"}';
end if;

return salida;
EXCEPTION
	WHEN others THEN
		salida = '{"error":true, "msg":"Se produjo un error al realizar la operación"}';
		return salida;
end;

$$;


ALTER FUNCTION dielab.elimina_tecnico(tecnicox character varying) OWNER TO postgres;

--
-- TOC entry 294 (class 1255 OID 24851)
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
-- TOC entry 295 (class 1255 OID 16493)
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
-- TOC entry 292 (class 1255 OID 24791)
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
-- TOC entry 316 (class 1255 OID 66030)
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
-- TOC entry 317 (class 1255 OID 74039)
-- Name: genera_tabla_x_nombre(character varying); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.genera_tabla_x_nombre(tipo_tabla character varying) RETURNS json
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
begin

linea = '';
linea_data = '';
fila_datos = '';
num_campos := 0;
campos = '';

	for resulta in 
		select column_name from information_schema.columns
		where table_schema = 'dielab' and table_name = 'select_' || tipo_tabla
		and column_name not in ('id', 'nombre') loop
			raise notice 'loop: %',resulta.column_name;
			if linea = '' then
				linea = '"' || resulta.column_name || '"';
				campos := resulta.column_name || '::text';
			else
				linea = linea || ',"' || resulta.column_name || '"';
				campos := campos || ',' || resulta.column_name || '::text';
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

return salida;
end;

$$;


ALTER FUNCTION dielab.genera_tabla_x_nombre(tipo_tabla character varying) OWNER TO postgres;

--
-- TOC entry 293 (class 1255 OID 41277)
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
case when usado is null then '--' else initcap(usado) end as usado,
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
-- TOC entry 319 (class 1255 OID 90469)
-- Name: get_detalle_pdf_atr(character varying); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.get_detalle_pdf_atr(cod_ensayox character varying) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $_$
declare

myrec			record;
begin

for myrec in select case when num_fila is null then '--' else num_fila end as row_number,
case when num_serie is null then '--' else num_serie end as num_serie,
case when marca is null then '--' else marca end as marca,
case when largo is null then '--' else largo end as largo,
case when usado is null then '--' else initcap(usado) end as usado,
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
row_number() over (order by num_serie)::text as num_fila, num_serie, marca, select_largo_aterramiento.nombre::text as largo, cod_clase, tension_ensayo,
case when parches ~ '^[0-9\.]+$' then case when parches::numeric > 0 then parches else '--' end else '--' end as parches, 
case when aprobado = 'RECHAZADO' then 'Falla' else case when i_fuga_1 ~ '^[0-9\.]+$' then to_char(i_fuga_1::numeric, 'FM999.00') else '--' end end as promed_fuga, 
to_char(corriente_fuga_max, 'FM9.00') as fuga_max, aprobado, estado_uso.nombre_estado::text as usado
from dielab.lista_det_guante
join dielab.epps on num_serie = serie_epp
join dielab.encabezado_ensayo using (id_batea)
join dielab.estado_uso on epps.estado_uso = estado_uso.id
join dielab.tipo_aterramiento on tipo_epp = id_tipo
join dielab.select_largo_aterramiento on tipo_aterramiento.largo = select_largo_aterramiento.id
join dielab.clase_tipo on tipo_aterramiento.clase = clase_tipo.id_clase
where cod_ensayo = cod_ensayoX) as b
	on a.correlativo = b.num_fila loop
		return next myrec;
end loop;

return;
end;

$_$;


ALTER FUNCTION dielab.get_detalle_pdf_atr(cod_ensayox character varying) OWNER TO postgres;

--
-- TOC entry 313 (class 1255 OID 90465)
-- Name: get_detalle_pdf_gnt(character varying); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.get_detalle_pdf_gnt(cod_ensayox character varying) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $_$
declare

myrec			record;
begin

for myrec in select case when num_fila is null then '--' else num_fila end as row_number,
case when num_serie is null then '--' else num_serie end as num_serie,
case when marca is null then '--' else marca end as marca,
case when largo is null then '--' else largo end as largo,
case when usado is null then '--' else initcap(usado) end as usado,
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
row_number() over (order by num_serie)::text as num_fila, num_serie, marca, select_largo_guante.nombre::text as largo, cod_clase, tension_ensayo,
case when parches ~ '^[0-9\.]+$' then case when parches::numeric > 0 then parches else '--' end else '--' end as parches, 
case when aprobado = 'RECHAZADO' then 'Falla' else case when promed_fuga ~ '^[0-9\.]+$' then to_char(promed_fuga::numeric, 'FM9.00') else '--' end end as promed_fuga, 
to_char(corriente_fuga_max, 'FM9.00') as fuga_max, aprobado, estado_uso.nombre_estado::text as usado
from dielab.lista_det_guante
join dielab.epps on num_serie = serie_epp
join dielab.estado_uso on epps.estado_uso = estado_uso.id
join dielab.tipo_guante on tipo_epp = id_tipo
join dielab.select_largo_guante on tipo_guante.largo = select_largo_guante.id
join dielab.clase_tipo on tipo_guante.clase = clase_tipo.id_clase
join dielab.encabezado_ensayo using (id_batea) where cod_ensayo = cod_ensayoX) as b
on a.correlativo = b.num_fila loop

		return next myrec;
	end loop;

return;
end;

$_$;


ALTER FUNCTION dielab.get_detalle_pdf_gnt(cod_ensayox character varying) OWNER TO postgres;

--
-- TOC entry 318 (class 1255 OID 90468)
-- Name: get_detalle_pdf_mng(character varying); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.get_detalle_pdf_mng(cod_ensayox character varying) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $_$
declare

myrec			record;
begin

for myrec in select case when num_fila is null then '--' else num_fila end as row_number,
case when num_serie is null then '--' else num_serie end as num_serie,
case when marca is null then '--' else marca end as marca,
case when largo is null then '--' else largo end as largo,
case when usado is null then '--' else initcap(usado) end as usado,
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
	case when aprobado = 'RECHAZADO' then 'Falla' else case when i_fuga_1 ~ '^[0-9\.]+$' then to_char(i_fuga_1::numeric, 'FM999.00') else '--' end end as promed_fuga, 
	to_char(corriente_fuga_max, 'FM9.00') as fuga_max, aprobado, estado_uso.nombre_estado::text as usado
	from dielab.lista_det_guante
	join dielab.epps on num_serie = serie_epp
	join dielab.encabezado_ensayo using (id_batea)
	join dielab.estado_uso on epps.estado_uso = estado_uso.id
	join dielab.tipo_manguilla on tipo_epp = id_tipo
	join dielab.clase_tipo on tipo_manguilla.clase = clase_tipo.id_clase
	where cod_ensayo = cod_ensayoX) as b
	on a.correlativo = b.num_fila loop
		return next myrec;
end loop;

return;
end;

$_$;


ALTER FUNCTION dielab.get_detalle_pdf_mng(cod_ensayox character varying) OWNER TO postgres;

--
-- TOC entry 312 (class 1255 OID 90466)
-- Name: get_detalle_pdf_mnt(character varying); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.get_detalle_pdf_mnt(cod_ensayox character varying) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $_$
declare

myrec			record;
begin

for myrec in select case when num_fila is null then '--' else num_fila end as row_number,
case when num_serie is null then '--' else num_serie end as num_serie,
case when marca is null then '--' else marca end as marca,
case when largo is null then '--' else largo end as largo,
case when usado is null then '--' else initcap(usado) end as usado,
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
row_number() over (order by num_serie)::text as num_fila, num_serie, marca, largo_manta.nombre::text as largo, cod_clase, tension_ensayo,
case when parches ~ '^[0-9\.]+$' then case when parches::numeric > 0 then parches else '--' end else '--' end as parches, 
case when aprobado = 'RECHAZADO' then 'Falla' else case when promed_fuga ~ '^[0-9\.]+$' then to_char(promed_fuga::numeric, 'FM9.00') else '--' end end as promed_fuga, 
to_char(corriente_fuga_max, 'FM9.00') as fuga_max, aprobado, estado_uso.nombre_estado::text as usado
from dielab.lista_det_guante
join dielab.epps on num_serie = serie_epp
join dielab.estado_uso on epps.estado_uso = estado_uso.id
join dielab.tipo_manta on tipo_epp = id_tipo
join dielab.clase_tipo on tipo_manta.clase = clase_tipo.id_clase
join dielab.largo_manta on tipo_manta.largo = largo_manta.id
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


ALTER FUNCTION dielab.get_detalle_pdf_mnt(cod_ensayox character varying) OWNER TO postgres;

--
-- TOC entry 320 (class 1255 OID 90470)
-- Name: get_detalle_pdf_prt(character varying); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.get_detalle_pdf_prt(cod_ensayox character varying) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $_$
declare

myrec			record;
begin

for myrec in select case when num_fila is null then '--' else num_fila end as row_number,
case when num_serie is null then '--' else num_serie end as num_serie,
case when marca is null then '--' else marca end as marca,
case when largo is null then '--' else largo end as largo,
case when usado is null then '--' else initcap(usado) end as usado,
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
row_number() over (order by num_serie)::text as num_fila, num_serie, marca, select_largo_pertiga.nombre::text as largo, cod_clase, tension_ensayo,
case when parches ~ '^[0-9\.]+$' then case when parches::numeric > 0 then parches else '--' end else '--' end as parches, 
case when aprobado = 'RECHAZADO' then 'Falla' else case when i_fuga_1 ~ '^[0-9\.]+$' then to_char(i_fuga_1::numeric, 'FM999.00') else '--' end end as promed_fuga, 
to_char(corriente_fuga_max, 'FM9.00') as fuga_max, aprobado, estado_uso.nombre_estado::text as usado
from dielab.lista_det_guante
join dielab.epps on num_serie = serie_epp
join dielab.encabezado_ensayo using (id_batea)
join dielab.estado_uso on epps.estado_uso = estado_uso.id
join dielab.tipo_pertiga on tipo_epp = id_tipo
join dielab.select_largo_pertiga on tipo_pertiga.largo = select_largo_pertiga.id
join dielab.clase_tipo on tipo_pertiga.clase = clase_tipo.id_clase
where cod_ensayo = cod_ensayoX) as b
	on a.correlativo = b.num_fila loop
		return next myrec;
end loop;

return;
end;

$_$;


ALTER FUNCTION dielab.get_detalle_pdf_prt(cod_ensayox character varying) OWNER TO postgres;

--
-- TOC entry 323 (class 1255 OID 90479)
-- Name: get_edit_param(character varying, integer); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.get_edit_param(tablax character varying, id_paramx integer) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare

myrec			record;
linea			text;
salida			json;
begin
salida := '{"error":false, "msg":"error 01"}'::json;
if tablaX = 'tecnicos_ensayo' then
	select nombre as tecnico_ensayo, 
	case when comentario is null then ''::text else comentario end as comentario
	into myrec
	from dielab.tecnicos_ensayo where id_tecnico = id_paramX;
	if found then
		linea := '{"tecnico_ensayo":"' || myrec.tecnico_ensayo || '", "comentario":"' || myrec.comentario || '"}';
		linea := '{"error":false, "datos":'  || linea  ||  '}';
		salida = linea::json;
	else
		linea := '{"tecnico_ensayo":"", "comentario":""}';
		linea := '{"error":false, "datos":'  || linea  ||  '}';
		salida = linea::json;
	end if;
elseif tablaX = 'patron' then
	select case when descripcion is null then ''::text else descripcion end as descripcion,
	case when marca is null then ''::text else marca end as nombre_marca,
	case when modelo is null then ''::text else modelo end as modelo,
	case when serie is null then ''::text else serie end as serie,
	mes_calibracion, periodo_calibracion into myrec from dielab.patron 
	where id_patron = id_paramX;
	if found then
		linea = '{"descripcion":"' || myrec.descripcion || '", "nombre_marca":"' || myrec.nombre_marca || '", "modelo":"' || myrec.modelo || '", "serie":"' || myrec.serie || '", "mes_calibracion":"' || myrec.mes_calibracion || '", "periodo_calibracion":"' || myrec.periodo_calibracion || '"}';
		linea := '{"error":false, "datos":'  || linea  ||  '}';
		salida = linea::json;
	else
		linea := '{}';
		linea := '{"error":false, "datos":'  || linea  ||  '}';
		salida = linea::json;	
	end if;
else

end if;
return salida;

end;

$$;


ALTER FUNCTION dielab.get_edit_param(tablax character varying, id_paramx integer) OWNER TO postgres;

--
-- TOC entry 291 (class 1255 OID 16492)
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
-- TOC entry 309 (class 1255 OID 74000)
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
raise notice 'inicio ';
id_tipo_in := 1;
raise notice 'inicio 2';
if tabla_tipo_in = 'patron' then
	raise notice 'inicio 3';
	sql_text := 'select max(id_patron) as val_max from dielab.' || tabla_tipo_in || ';';
	raise notice 'inicio 4';
	--sql_text = 'id_patron';
	raise notice 'inicio 5';
elseif tabla_tipo_in = 'tecnicos_ensayo' then
	raise notice 'inicio 3';
	sql_text := 'select max(id_tecnico) as val_max from dielab.' || tabla_tipo_in || ';';
	raise notice 'inicio 4';
	--sql_text = 'id_patron';
	raise notice 'inicio 5';
else 
	raise notice 'inicio 6';
	sql_text := 'select max(id_tipo) as val_max from dielab.' || tabla_tipo_in || ';';
	raise notice 'inicio 7';
	--sql_text = 'id_tipo';
	raise notice 'inicio 8';
end if;
raise notice 'sql_text: %', sql_text;
for myrec in execute(sql_text) loop
	if myrec.val_max is not null then
		id_tipo_in := myrec.val_max + 1;
	end if;
end loop;
if tabla_tipo_in = 'patron' then
	sql_text = 'id_patron';
elseif tabla_tipo_in = 'tecnicos_ensayo' then
	sql_text = 'id_tecnico';
else
	sql_text = 'id_tipo';
end if;

if datojson->'largo' is not null then
	if sql_text = '' then
		sql_text := 'largo';
	else
		sql_text := sql_text || ',' || 'largo';
	end if;
end if;
if datojson->'descripcion' is not null then
	if sql_text = '' then
		sql_text := 'descripcion';
	else
		sql_text := sql_text || ',' || 'descripcion';
	end if;
end if;
raise notice 'sql_text(1): %',sql_text;
if datojson->'clase' is not null then
	if sql_text = '' then
		sql_text := 'clase';
	else
		sql_text := sql_text || ',' || 'clase';
	end if;
end if;
raise notice 'sql_text(2): %',sql_text;
if datojson->'max_i_fuga' is not null then
	if sql_text = '' then
		sql_text := 'corriente_fuga_max';
	else
		sql_text := sql_text || ',' || 'corriente_fuga_max';
	end if;
end if;
raise notice 'sql_text(3): %',sql_text;
if datojson->'marca' is not null then
	if sql_text = '' then
		sql_text := 'cod_marca';
	else
		sql_text := sql_text || ',' || 'cod_marca';
	end if;
end if;
if datojson->'nombre_marca' is not null then
	if sql_text = '' then
		sql_text := 'marca';
	else
		sql_text := sql_text || ',' || 'marca';
	end if;
end if;
if datojson->'modelo' is not null then
	if sql_text = '' then
		sql_text := 'modelo';
	else
		sql_text := sql_text || ',' || 'modelo';
	end if;
end if;
if datojson->'serie' is not null then
	if sql_text = '' then
		sql_text := 'serie';
	else
		sql_text := sql_text || ',' || 'serie';
	end if;
end if;
if datojson->'tecnico_ensayo' is not null then
	if sql_text = '' then
		sql_text := 'nombre';
	else
		sql_text := sql_text || ',' || 'nombre';
	end if;
end if;
if datojson->'comentario' is not null then
	if sql_text = '' then
		sql_text := 'comentario';
	else
		sql_text := sql_text || ',' || 'comentario';
	end if;
end if;
if datojson->'mes_calibracion' is not null then
	if sql_text = '' then
		sql_text := 'mes_calibracion';
	else
		sql_text := sql_text || ',' || 'mes_calibracion';
	end if;
end if;
if datojson->'periodo_calibracion' is not null then
	if sql_text = '' then
		sql_text := 'periodo_calibracion';
	else
		sql_text := sql_text || ',' || 'periodo_calibracion';
	end if;
end if;
if datojson->'num_cuerpos' is not null then
	if sql_text = '' then
		sql_text := 'largo';
	else
		sql_text := sql_text || ',' || 'largo';
	end if;
end if;
raise notice 'sql_text(4): %',sql_text;
sql_text = '(' || sql_text || ') VALUES (' || id_tipo_in::text;

--raise notice 'sql_text: %',sql_text;
--raise notice 'clase: %', datojson->>'clase';
raise notice 'sql_text(5): %',sql_text;
if datojson->'largo' is not null then
	sql_text := sql_text || ',' || (datojson->>'largo')::text;
end if;
if datojson->'descripcion' is not null then
	sql_text := sql_text || ',' || '''' || (datojson->>'descripcion')::text || '''';
end if;
raise notice 'sql_text(6): %',sql_text;
if datojson->'clase' is not null then
	sql_text := sql_text || ',' || (datojson->>'clase')::text;
end if;
raise notice 'sql_text(7): %',sql_text;
if datojson->'max_i_fuga' is not null then
	sql_text := sql_text || ',' || (datojson->>'max_i_fuga')::text;
end if;
raise notice 'sql_text(8): %',sql_text;
if datojson->'marca' is not null then
	sql_text := sql_text || ',' || (datojson->>'marca')::text;
end if;
if datojson->'nombre_marca' is not null then
	sql_text := sql_text || ',' || '''' || (datojson->>'nombre_marca')::text || '''';
	raise notice 'sql_text (nombre_marca): %', sql_text;
end if;
if datojson->'tecnico_ensayo' is not null then
	sql_text := sql_text || ',' || '''' || (datojson->>'tecnico_ensayo')::text || '''';
end if;
if datojson->'comentario' is not null then
	sql_text := sql_text || ',' || '''' || (datojson->>'comentario')::text || '''';
end if;
if datojson->'modelo' is not null then
	sql_text := sql_text || ',' || '''' || (datojson->>'modelo')::text || '''';
end if;
if datojson->'serie' is not null then
	sql_text := sql_text || ',' || '''' || (datojson->>'serie')::text || '''';
end if;
if datojson->'mes_calibracion' is not null then
	sql_text := sql_text || ',' || (datojson->>'mes_calibracion')::text;
end if;
if datojson->'periodo_calibracion' is not null then
	sql_text := sql_text || ',' || (datojson->>'periodo_calibracion')::text;
end if;
if datojson->'num_cuerpos' is not null then
	sql_text := sql_text || ',' || (datojson->>'num_cuerpos')::text;
end if;
raise notice 'sql_text(9): %',sql_text;
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
-- TOC entry 307 (class 1255 OID 24785)
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
			update dielab.epps set estado_epp = 1 where id_epp = serie_bigint;

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
-- TOC entry 278 (class 1255 OID 24780)
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
-- TOC entry 299 (class 1255 OID 24777)
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
-- TOC entry 303 (class 1255 OID 57672)
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
-- TOC entry 310 (class 1255 OID 74037)
-- Name: ingresa_enc_ensayo(character varying, integer, character varying, integer, numeric, numeric, integer, integer, character varying, character varying, integer, integer, text); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.ingresa_enc_ensayo(cod_ensayox character varying, clientex integer, sucursalx character varying, negociox integer, temperaturax numeric, humedadx numeric, tecnicox integer, patronx integer, fecha_ejecucionx character varying, fecha_ingresox character varying, valor_estadox integer, tipo_ensayox integer, orden_comprax text) RETURNS json
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
		cod_patron = patronx, orden_compra = orden_compraX
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
				VALUES (idbatea, cod_ensayox, temperaturax, humedadx, tecnicox, now()::timestamp, patronx, 'ingreso', tipo_ensayoX, fecha_ejecucionx::date, null, id_cli_n_s, fecha_ingresox::date, valor_estadox, patronx, orden_compraX);
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


ALTER FUNCTION dielab.ingresa_enc_ensayo(cod_ensayox character varying, clientex integer, sucursalx character varying, negociox integer, temperaturax numeric, humedadx numeric, tecnicox integer, patronx integer, fecha_ejecucionx character varying, fecha_ingresox character varying, valor_estadox integer, tipo_ensayox integer, orden_comprax text) OWNER TO postgres;

--
-- TOC entry 302 (class 1255 OID 16495)
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
-- TOC entry 300 (class 1255 OID 16494)
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
-- TOC entry 305 (class 1255 OID 24847)
-- Name: ingresa_enc_ensayo_borrar(character varying, integer, character varying, integer, numeric, numeric, integer, integer, character varying, character varying, integer); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.ingresa_enc_ensayo_borrar(cod_ensayox character varying, clientex integer, sucursalx character varying, negociox integer, temperaturax numeric, humedadx numeric, tecnicox integer, patronx integer, fecha_ejecucionx character varying, fecha_ingresox character varying, valor_estadox integer) RETURNS json
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


ALTER FUNCTION dielab.ingresa_enc_ensayo_borrar(cod_ensayox character varying, clientex integer, sucursalx character varying, negociox integer, temperaturax numeric, humedadx numeric, tecnicox integer, patronx integer, fecha_ejecucionx character varying, fecha_ingresox character varying, valor_estadox integer) OWNER TO postgres;

--
-- TOC entry 308 (class 1255 OID 24840)
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
-- TOC entry 315 (class 1255 OID 57671)
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
-- TOC entry 298 (class 1255 OID 24852)
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
-- TOC entry 279 (class 1255 OID 41275)
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
-- TOC entry 324 (class 1255 OID 90487)
-- Name: update_det_tipo_epp(text, json, integer); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.update_det_tipo_epp(tabla_tipo_in text, datojson json, id_parametrox integer) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare

myrec			record;
resultado		record;
salida        	json;
otro			json;
id_detalle_auto	bigint;
serie_bigint	bigint;
sql_text		text;
id_tipo_in		integer;
begin
raise notice 'inicio ';
id_tipo_in := 1;
raise notice 'inicio 2';
if tabla_tipo_in = 'patron' then

	select * into myrec from dielab.patron where id_patron = id_parametroX;
	if found then
		-- actualiza
		select * into resultado from dielab.patron where marca::text = (datojson->>'nombre_marca')::text
		and modelo = (datojson->>'modelo')::text and serie = (datojson->>'serie')::text;
		if found then
		-- chequear si es la misma id
			if id_parametroX = resultado.id_patron then
				-- es el mismo, actualizar
				update dielab.patron set descripcion = (datojson->>'descripcion')::text, 
				mes_calibracion = (datojson->>'mes_calibracion')::integer,
				periodo_calibracion = (datojson->>'periodo_calibracion')::integer
				where id_patron = id_parametroX;
				salida = '{"error":false, "msg":"Ingreso correcto"}';
			else
			-- es otro id, error, no puede ingresar 2 veces la misma marca, modelo, serie
				salida = '{"error":true, "msg":"Marca, modelo y serie está repetido"}';
			end if;
		else
		-- no existe la marca, modelo, serie, actualizar todos los datos
				update dielab.patron set descripcion = (datojson->>'descripcion')::text,
				marca = (datojson->>'nombre_marca')::text,
				modelo = (datojson->>'modelo')::text,
				serie = (datojson->>'serie')::text,
				mes_calibracion = (datojson->>'mes_calibracion')::integer,
				periodo_calibracion = (datojson->>'periodo_calibracion')::integer
				where id_patron = id_parametroX;
				salida = '{"error":false, "msg":"Ingreso correcto"}';
		end if;
	else
		salida = '{"error":true, "msg":"No existe el ID para el patron"}';
	end if;
elseif tabla_tipo_in = 'tecnicos_ensayo' then
	select * into myrec from dielab.tecnicos_ensayo where id_tecnico = id_parametroX;
	if found then
		select into resultado from dielab.tecnicos_ensayo where nombre = (datojson->>'tecnico_ensayo')::text;
		if found then
			if id_parametroX = resultado.id_tecnico then
				--- es el mismo tecnico
				update dielab.tecnicos_ensayo set comentario = (datojson->>'comentario')::text
				where id_tecnico = id_parametroX;
				salida = '{"error":false, "msg":"Ingreso correcto"}';
			else
				salida = '{"error":true, "msg":"El nombre de técnico ya existe ne la base"}';
			end if;
		else
			update dielab.tecnicos_ensayo set comentario = (datojson->>'comentario')::text,
			nombre = (datojson->>'tecnico_ensayo')::text
			where id_tecnico = id_parametroX;
			salida = '{"error":false, "msg":"Ingreso correcto"}';
		end if;
	else
		salida = '{"error":true, "msg":"No existe el ID para el tecnico"}';
	end if;
	
else 
	salida = '{"error":true, "msg":"Parametro aún no implementado"}';
end if;

return salida;

		
return salida;
end;

$$;


ALTER FUNCTION dielab.update_det_tipo_epp(tabla_tipo_in text, datojson json, id_parametrox integer) OWNER TO postgres;

--
-- TOC entry 314 (class 1255 OID 33122)
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
-- TOC entry 297 (class 1255 OID 24771)
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
		if resultado.estado_epp = 3 then
		-- fue dado de baja
			salida = '{"error":true, "msg":"El elemento fue dado de baja"}';
		else
			if resultado.clase_epp = 1 then
			--guante, buscar corriente de fuga
				select corriente_fuga_max::text as fuga into resultado from dielab.epps join dielab.tipo_guante
				on tipo_epp = id_tipo where serie_epp = epp;
				if found then
					salida = '{"error":false, "msg":"' || resultado.fuga || '"}';
				else
					salida = '{"error":true, "msg":"No se encuentra el tipo de guante"}';
				end if;		
			else
			-- no es guante, no busca corriente de fuga
				salida = '{"error":false, "msg":"0"}';
			end if;
		end if;
	else
		salida = '{"error":true, "msg":"No existe el elemento"}';
	end if;

return salida;
end;

$$;


ALTER FUNCTION dielab.verifica_epp_guante(epp character varying) OWNER TO postgres;

--
-- TOC entry 311 (class 1255 OID 24850)
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
-- TOC entry 270 (class 1259 OID 82299)
-- Name: anual; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.anual (
    id integer NOT NULL,
    nombre character varying NOT NULL
);


ALTER TABLE dielab.anual OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 24713)
-- Name: clase_epp; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.clase_epp (
    id_clase_epp integer NOT NULL,
    nombre character varying NOT NULL,
    cod_serie character varying NOT NULL,
    tabla_detalle character varying NOT NULL,
    nombre_menu character varying,
    habilitado boolean DEFAULT false,
    tipo_ensayo bigint NOT NULL,
    prioridad integer
);


ALTER TABLE dielab.clase_epp OWNER TO postgres;

--
-- TOC entry 3611 (class 0 OID 0)
-- Dependencies: 220
-- Name: TABLE clase_epp; Type: COMMENT; Schema: dielab; Owner: postgres
--

COMMENT ON TABLE dielab.clase_epp IS 'Describe las clases de Epp que existen como guantes, pertigas, banquetas, etc.';


--
-- TOC entry 222 (class 1259 OID 24737)
-- Name: clase_tipo; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.clase_tipo (
    cod_clase character varying NOT NULL,
    descripcion character varying NOT NULL,
    id_clase bigint NOT NULL
);


ALTER TABLE dielab.clase_tipo OWNER TO postgres;

--
-- TOC entry 3612 (class 0 OID 0)
-- Dependencies: 222
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
-- TOC entry 248 (class 1259 OID 65904)
-- Name: cuerpos_aterramiento; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.cuerpos_aterramiento (
    id bigint NOT NULL,
    nombre character varying NOT NULL
);


ALTER TABLE dielab.cuerpos_aterramiento OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 24703)
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
-- TOC entry 218 (class 1259 OID 24695)
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
-- TOC entry 229 (class 1259 OID 24824)
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
-- TOC entry 216 (class 1259 OID 16541)
-- Name: estado_ensayo; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.estado_ensayo (
    id_estado integer NOT NULL,
    nombre character varying NOT NULL,
    observacion character varying
);


ALTER TABLE dielab.estado_ensayo OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 24753)
-- Name: estado_epp; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.estado_epp (
    id_estado_epp integer NOT NULL,
    descripcion character varying NOT NULL
);


ALTER TABLE dielab.estado_epp OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 57633)
-- Name: estado_uso; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.estado_uso (
    id bigint NOT NULL,
    nombre_estado character varying NOT NULL
);


ALTER TABLE dielab.estado_uso OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 65830)
-- Name: largo_cubrelinea; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.largo_cubrelinea (
    id bigint NOT NULL,
    nombre character varying NOT NULL
);


ALTER TABLE dielab.largo_cubrelinea OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 24800)
-- Name: largo_guante; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.largo_guante (
    id_largo integer NOT NULL,
    valor integer NOT NULL
);


ALTER TABLE dielab.largo_guante OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 65809)
-- Name: largo_manta; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.largo_manta (
    id bigint NOT NULL,
    nombre character varying NOT NULL
);


ALTER TABLE dielab.largo_manta OWNER TO postgres;

--
-- TOC entry 251 (class 1259 OID 65959)
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
-- TOC entry 231 (class 1259 OID 24841)
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
-- TOC entry 241 (class 1259 OID 57628)
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
-- TOC entry 277 (class 1259 OID 90488)
-- Name: lista_ensayos_x_epp; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.lista_ensayos_x_epp AS
 SELECT lista_ensayos.id,
    lista_ensayos.codigo,
    lista_ensayos.fecha_ingreso,
    lista_ensayos.cliente,
    lista_ensayos.negocio,
    lista_ensayos.estado,
    lista_ensayos.tipo_ensayo,
    a.serie_epp
   FROM (dielab.lista_ensayos
     JOIN ( SELECT encabezado_ensayo.cod_ensayo,
            epps.serie_epp
           FROM ((dielab.detalle_ensayo
             JOIN dielab.epps ON ((detalle_ensayo.serie_epp = epps.id_epp)))
             JOIN dielab.encabezado_ensayo USING (id_batea))) a ON (((lista_ensayos.codigo)::text = (a.cod_ensayo)::text)));


ALTER TABLE dielab.lista_ensayos_x_epp OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 24835)
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
-- TOC entry 217 (class 1259 OID 16569)
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
    encabezado_ensayo.cod_estado,
    encabezado_ensayo.orden_compra
   FROM (dielab.encabezado_ensayo
     JOIN dielab.cliente_negocio_sucursal ON ((encabezado_ensayo.cliente_n_s = cliente_negocio_sucursal.id_cliente_n_s)));


ALTER TABLE dielab.lista_form_ensayo OWNER TO postgres;

--
-- TOC entry 275 (class 1259 OID 90461)
-- Name: lista_form_epps; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.lista_form_epps AS
 SELECT epps.id_epp,
    epps.serie_epp,
    epps.tipo_epp,
    cliente_negocio_sucursal.cliente,
    cliente_negocio_sucursal.negocio,
    cliente_negocio_sucursal.sucursal,
    epps.periodicidad,
    epps.estado_uso,
    epps.estado_epp
   FROM (dielab.epps
     JOIN dielab.cliente_negocio_sucursal ON ((cliente_negocio_sucursal.id_cliente_n_s = epps.cliente_n_s)));


ALTER TABLE dielab.lista_form_epps OWNER TO postgres;

--
-- TOC entry 207 (class 1259 OID 16449)
-- Name: patron; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.patron (
    id_patron bigint NOT NULL,
    descripcion text DEFAULT ''::text,
    marca character varying NOT NULL,
    modelo character varying NOT NULL,
    serie character varying NOT NULL,
    calibracion character varying,
    mes_calibracion integer,
    periodo_calibracion integer,
    activo boolean DEFAULT true
);


ALTER TABLE dielab.patron OWNER TO postgres;

--
-- TOC entry 205 (class 1259 OID 16433)
-- Name: tecnicos_ensayo; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.tecnicos_ensayo (
    id_tecnico bigint NOT NULL,
    nombre character varying NOT NULL,
    comentario text,
    activo boolean DEFAULT true
);


ALTER TABLE dielab.tecnicos_ensayo OWNER TO postgres;

--
-- TOC entry 268 (class 1259 OID 82286)
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
    to_char(((now())::date)::timestamp with time zone, 'DD/MM/YYYY'::text) AS fecha_impresion,
    encabezado_ensayo.orden_compra
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
-- TOC entry 224 (class 1259 OID 24792)
-- Name: marca; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.marca (
    id_marca integer NOT NULL,
    nombre character varying NOT NULL
);


ALTER TABLE dielab.marca OWNER TO postgres;

--
-- TOC entry 269 (class 1259 OID 82291)
-- Name: meses; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.meses (
    id integer NOT NULL,
    nombre character varying NOT NULL
);


ALTER TABLE dielab.meses OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 33058)
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
-- TOC entry 243 (class 1259 OID 57655)
-- Name: periodicidad; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.periodicidad (
    id bigint NOT NULL,
    descripcion character varying NOT NULL,
    meses integer NOT NULL
);


ALTER TABLE dielab.periodicidad OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 33048)
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
-- TOC entry 227 (class 1259 OID 24809)
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
-- TOC entry 240 (class 1259 OID 57624)
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
  ORDER BY clase_epp.prioridad;


ALTER TABLE dielab.select_clase_ensayo OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 49499)
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
  ORDER BY clase_epp.prioridad
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
-- TOC entry 245 (class 1259 OID 57667)
-- Name: select_estado_uso; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_estado_uso AS
 SELECT estado_uso.id,
    estado_uso.nombre_estado AS nombre
   FROM dielab.estado_uso
  ORDER BY estado_uso.nombre_estado;


ALTER TABLE dielab.select_estado_uso OWNER TO postgres;

--
-- TOC entry 257 (class 1259 OID 74029)
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
-- TOC entry 255 (class 1259 OID 66044)
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
-- TOC entry 228 (class 1259 OID 24813)
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
-- TOC entry 254 (class 1259 OID 66040)
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
-- TOC entry 256 (class 1259 OID 66048)
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
-- TOC entry 226 (class 1259 OID 24805)
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
-- TOC entry 271 (class 1259 OID 82316)
-- Name: select_mes_calibracion; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_mes_calibracion AS
 SELECT meses.id,
    meses.nombre
   FROM dielab.meses
  ORDER BY meses.id
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_mes_calibracion OWNER TO postgres;

--
-- TOC entry 267 (class 1259 OID 82282)
-- Name: select_modelo_cubrelinea; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_modelo_cubrelinea AS
 SELECT largo_cubrelinea.id,
    largo_cubrelinea.nombre
   FROM dielab.largo_cubrelinea
  ORDER BY largo_cubrelinea.nombre
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_modelo_cubrelinea OWNER TO postgres;

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
-- TOC entry 260 (class 1259 OID 82243)
-- Name: select_num_cuerpos; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_num_cuerpos AS
 SELECT cuerpos_aterramiento.id,
    cuerpos_aterramiento.nombre
   FROM dielab.cuerpos_aterramiento
  ORDER BY cuerpos_aterramiento.id
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_num_cuerpos OWNER TO postgres;

--
-- TOC entry 258 (class 1259 OID 74033)
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
-- TOC entry 276 (class 1259 OID 90472)
-- Name: select_patron; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_patron AS
 SELECT patron.id_patron AS id,
        CASE
            WHEN ((patron.descripcion IS NULL) OR (patron.descripcion = ''::text)) THEN (patron.marca)::text
            ELSE ((patron.descripcion || '/'::text) || (patron.marca)::text)
        END AS nombre,
    patron.id_patron AS num,
    patron.descripcion,
    patron.marca AS nombre_marca,
    patron.modelo,
    patron.serie,
    meses.nombre AS mes_calibracion,
    anual.nombre AS periodo_calibracion,
        CASE
            WHEN patron.activo THEN 'ACTIVO'::text
            ELSE 'INACTIVO'::text
        END AS estado
   FROM ((dielab.patron
     JOIN dielab.meses ON ((patron.mes_calibracion = meses.id)))
     JOIN dielab.anual ON ((patron.periodo_calibracion = anual.id)))
  ORDER BY patron.id_patron DESC, patron.descripcion, patron.marca;


ALTER TABLE dielab.select_patron OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 57663)
-- Name: select_periodicidad; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_periodicidad AS
 SELECT periodicidad.id,
    periodicidad.descripcion AS nombre
   FROM dielab.periodicidad
  ORDER BY periodicidad.id;


ALTER TABLE dielab.select_periodicidad OWNER TO postgres;

--
-- TOC entry 272 (class 1259 OID 82320)
-- Name: select_periodo_calibracion; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_periodo_calibracion AS
 SELECT anual.id,
    anual.nombre
   FROM dielab.anual
  ORDER BY anual.nombre
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_periodo_calibracion OWNER TO postgres;

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
    tecnicos_ensayo.nombre,
    tecnicos_ensayo.nombre AS tecnico_ensayo,
    tecnicos_ensayo.comentario
   FROM dielab.tecnicos_ensayo
  WHERE tecnicos_ensayo.activo
  ORDER BY tecnicos_ensayo.nombre
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_tecnico OWNER TO postgres;

--
-- TOC entry 273 (class 1259 OID 90447)
-- Name: select_tecnicos_ensayo; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_tecnicos_ensayo AS
 SELECT tecnicos_ensayo.id_tecnico AS id,
    tecnicos_ensayo.nombre,
    tecnicos_ensayo.id_tecnico AS num,
    tecnicos_ensayo.nombre AS tecnico_ensayo,
        CASE
            WHEN (tecnicos_ensayo.comentario IS NULL) THEN ''::text
            ELSE tecnicos_ensayo.comentario
        END AS comentario,
        CASE
            WHEN tecnicos_ensayo.activo THEN 'ACTIVO'::text
            ELSE 'INACTIVO'::text
        END AS estado_tecnico
   FROM dielab.tecnicos_ensayo
  ORDER BY tecnicos_ensayo.id_tecnico DESC, tecnicos_ensayo.nombre
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_tecnicos_ensayo OWNER TO postgres;

--
-- TOC entry 249 (class 1259 OID 65914)
-- Name: tipo_aterramiento; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.tipo_aterramiento (
    id_tipo integer NOT NULL,
    marca character varying NOT NULL,
    modelo character varying,
    largo bigint DEFAULT 0 NOT NULL,
    clase bigint DEFAULT 0 NOT NULL,
    corriente_fuga_max double precision DEFAULT 0,
    descripcion character varying,
    cod_marca bigint NOT NULL
);


ALTER TABLE dielab.tipo_aterramiento OWNER TO postgres;

--
-- TOC entry 259 (class 1259 OID 82238)
-- Name: select_tipo_aterramiento; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_tipo_aterramiento AS
 SELECT tipo_aterramiento.id_tipo AS id,
    (((((marca.nombre)::text || '_'::text) || 'N°_Cuerpos:_'::text) || (cuerpos_aterramiento.nombre)::text) || '_'::text) AS nombre,
    (marca.nombre)::text AS marca,
    (cuerpos_aterramiento.nombre)::text AS num_cuerpos
   FROM ((dielab.tipo_aterramiento
     JOIN dielab.cuerpos_aterramiento ON ((tipo_aterramiento.largo = cuerpos_aterramiento.id)))
     JOIN dielab.marca ON ((tipo_aterramiento.cod_marca = marca.id_marca)))
  ORDER BY marca.nombre, cuerpos_aterramiento.nombre;


ALTER TABLE dielab.select_tipo_aterramiento OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 49485)
-- Name: tipo_banqueta; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.tipo_banqueta (
    id_tipo integer NOT NULL,
    marca character varying NOT NULL,
    modelo character varying,
    largo bigint DEFAULT 0 NOT NULL,
    clase bigint NOT NULL,
    corriente_fuga_max double precision DEFAULT 0,
    descripcion character varying,
    cod_marca bigint NOT NULL
);


ALTER TABLE dielab.tipo_banqueta OWNER TO postgres;

--
-- TOC entry 263 (class 1259 OID 82262)
-- Name: select_tipo_banqueta; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_tipo_banqueta AS
 SELECT tipo_banqueta.id_tipo AS id,
    (((marca.nombre)::text || '__'::text) || (clase_tipo.descripcion)::text) AS nombre,
    (marca.nombre)::text AS marca,
    (clase_tipo.descripcion)::text AS clase
   FROM ((dielab.tipo_banqueta
     JOIN dielab.clase_tipo ON ((tipo_banqueta.clase = clase_tipo.id_clase)))
     JOIN dielab.marca ON ((tipo_banqueta.cod_marca = marca.id_marca)))
  ORDER BY marca.nombre, clase_tipo.descripcion;


ALTER TABLE dielab.select_tipo_banqueta OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 49459)
-- Name: tipo_cubrelinea; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.tipo_cubrelinea (
    id_tipo integer NOT NULL,
    marca character varying NOT NULL,
    modelo character varying,
    largo bigint NOT NULL,
    clase bigint NOT NULL,
    corriente_fuga_max double precision DEFAULT 0,
    descripcion character varying,
    cod_marca bigint
);


ALTER TABLE dielab.tipo_cubrelinea OWNER TO postgres;

--
-- TOC entry 266 (class 1259 OID 82277)
-- Name: select_tipo_cubrelinea; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_tipo_cubrelinea AS
 SELECT tipo_cubrelinea.id_tipo AS id,
    (((((marca.nombre)::text || '_'::text) || (largo_cubrelinea.nombre)::text) || '_'::text) || (clase_tipo.descripcion)::text) AS nombre,
    (marca.nombre)::text AS marca,
    (largo_cubrelinea.nombre)::text AS modelo_cubrelinea,
    (clase_tipo.descripcion)::text AS clase
   FROM (((dielab.tipo_cubrelinea
     JOIN dielab.largo_cubrelinea ON ((tipo_cubrelinea.largo = largo_cubrelinea.id)))
     JOIN dielab.clase_tipo ON ((tipo_cubrelinea.clase = clase_tipo.id_clase)))
     JOIN dielab.marca ON ((tipo_cubrelinea.cod_marca = marca.id_marca)))
  ORDER BY marca.nombre, largo_cubrelinea.nombre, clase_tipo.descripcion;


ALTER TABLE dielab.select_tipo_cubrelinea OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 24729)
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
-- TOC entry 253 (class 1259 OID 65999)
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
-- TOC entry 250 (class 1259 OID 65940)
-- Name: tipo_loadbuster; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.tipo_loadbuster (
    id_tipo integer NOT NULL,
    marca character varying NOT NULL,
    modelo character varying,
    largo bigint DEFAULT 0 NOT NULL,
    clase bigint DEFAULT 0 NOT NULL,
    corriente_fuga_max double precision DEFAULT 0,
    descripcion character varying,
    cod_marca bigint NOT NULL
);


ALTER TABLE dielab.tipo_loadbuster OWNER TO postgres;

--
-- TOC entry 264 (class 1259 OID 82267)
-- Name: select_tipo_loadbuster; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_tipo_loadbuster AS
 SELECT tipo_loadbuster.id_tipo AS id,
    (marca.nombre)::text AS nombre,
    (marca.nombre)::text AS marca
   FROM (dielab.tipo_loadbuster
     JOIN dielab.marca ON ((tipo_loadbuster.cod_marca = marca.id_marca)))
  ORDER BY marca.nombre;


ALTER TABLE dielab.select_tipo_loadbuster OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 49438)
-- Name: tipo_manguilla; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.tipo_manguilla (
    id_tipo integer NOT NULL,
    marca character varying,
    modelo character varying,
    largo bigint DEFAULT 0 NOT NULL,
    clase bigint NOT NULL,
    corriente_fuga_max double precision DEFAULT 0,
    descripcion character varying,
    cod_marca bigint
);


ALTER TABLE dielab.tipo_manguilla OWNER TO postgres;

--
-- TOC entry 261 (class 1259 OID 82247)
-- Name: select_tipo_manguilla; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_tipo_manguilla AS
 SELECT tipo_manguilla.id_tipo AS id,
    (((marca.nombre)::text || '__'::text) || (clase_tipo.descripcion)::text) AS nombre,
    (marca.nombre)::text AS marca,
    (clase_tipo.descripcion)::text AS clase
   FROM ((dielab.tipo_manguilla
     JOIN dielab.clase_tipo ON ((tipo_manguilla.clase = clase_tipo.id_clase)))
     JOIN dielab.marca ON ((tipo_manguilla.cod_marca = marca.id_marca)))
  ORDER BY marca.nombre, tipo_manguilla.clase;


ALTER TABLE dielab.select_tipo_manguilla OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 49472)
-- Name: tipo_manta; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.tipo_manta (
    id_tipo integer NOT NULL,
    marca character varying NOT NULL,
    modelo character varying,
    largo bigint NOT NULL,
    clase bigint NOT NULL,
    corriente_fuga_max double precision DEFAULT 0,
    descripcion character varying,
    cod_marca bigint
);


ALTER TABLE dielab.tipo_manta OWNER TO postgres;

--
-- TOC entry 262 (class 1259 OID 82252)
-- Name: select_tipo_manta; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_tipo_manta AS
 SELECT tipo_manta.id_tipo AS id,
    (((((marca.nombre)::text || '_'::text) || (largo_manta.nombre)::text) || '_'::text) || (clase_tipo.descripcion)::text) AS nombre,
    (marca.nombre)::text AS marca,
    (largo_manta.nombre)::text AS largo,
    (clase_tipo.descripcion)::text AS clase
   FROM (((dielab.tipo_manta
     JOIN dielab.largo_manta ON ((tipo_manta.largo = largo_manta.id)))
     JOIN dielab.clase_tipo ON ((tipo_manta.clase = clase_tipo.id_clase)))
     JOIN dielab.marca ON ((tipo_manta.cod_marca = marca.id_marca)))
  ORDER BY marca.nombre, largo_manta.nombre, clase_tipo.descripcion;


ALTER TABLE dielab.select_tipo_manta OWNER TO postgres;

--
-- TOC entry 252 (class 1259 OID 65969)
-- Name: tipo_pertiga; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.tipo_pertiga (
    id_tipo integer NOT NULL,
    marca character varying NOT NULL,
    modelo character varying,
    largo bigint NOT NULL,
    clase bigint DEFAULT 0 NOT NULL,
    corriente_fuga_max double precision DEFAULT 0,
    descripcion character varying,
    cod_marca bigint
);


ALTER TABLE dielab.tipo_pertiga OWNER TO postgres;

--
-- TOC entry 265 (class 1259 OID 82271)
-- Name: select_tipo_pertiga; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_tipo_pertiga AS
 SELECT tipo_pertiga.id_tipo AS id,
    (((marca.nombre)::text || '_'::text) || (largo_pertiga.nombre)::text) AS nombre,
    (marca.nombre)::text AS marca,
    (largo_pertiga.nombre)::text AS largo
   FROM ((dielab.tipo_pertiga
     JOIN dielab.largo_pertiga ON ((tipo_pertiga.largo = largo_pertiga.id)))
     JOIN dielab.marca ON ((tipo_pertiga.cod_marca = marca.id_marca)))
  ORDER BY marca.nombre, largo_pertiga.nombre;


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
-- TOC entry 234 (class 1259 OID 33093)
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
-- TOC entry 274 (class 1259 OID 90455)
-- Name: resultado1; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.resultado1 (
    id_detalle bigint,
    id_batea bigint,
    serie_epp bigint,
    aprobado boolean,
    detalle json
);


ALTER TABLE public.resultado1 OWNER TO postgres;

--
-- TOC entry 3604 (class 0 OID 82299)
-- Dependencies: 270
-- Data for Name: anual; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.anual (id, nombre) FROM stdin;
1	2022
2	2023
3	2024
4	2025
5	2026
6	2027
7	2028
8	2029
9	2030
\.


--
-- TOC entry 3580 (class 0 OID 24713)
-- Dependencies: 220
-- Data for Name: clase_epp; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.clase_epp (id_clase_epp, nombre, cod_serie, tabla_detalle, nombre_menu, habilitado, tipo_ensayo, prioridad) FROM stdin;
9	jumper	JMP	tipo_jumper	Jumper	f	9	\N
1	guante	GNT	tipo_guante	Guantes	t	1	1
2	manguilla	MNG	tipo_manguilla	Manguillas	t	4	2
3	manta	MNT	tipo_manta	Mantas	t	5	7
4	cubrelinea	CBL	tipo_cubrelinea	Cubrelineas	t	3	6
5	banqueta	BNQ	tipo_banqueta	Banquetas	t	6	8
6	loadbuster	LDB	tipo_loadbuster	LoadBuster	t	2	5
7	aterramiento	ATR	tipo_aterramiento	Aterramiento	t	7	3
8	pertiga	PRT	tipo_pertiga	Pértiga	t	8	4
\.


--
-- TOC entry 3582 (class 0 OID 24737)
-- Dependencies: 222
-- Data for Name: clase_tipo; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.clase_tipo (cod_clase, descripcion, id_clase) FROM stdin;
0	Clase 0	0
00	Clase 00	1
1	Clase 1	2
2	Clase 2	3
3	Clase 3	4
4	Clase 4	5
5	Clase 5	6
6	Clase 6	7
\.


--
-- TOC entry 3568 (class 0 OID 16404)
-- Dependencies: 201
-- Data for Name: cliente; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.cliente (id_cliente, nombre, telefono, representante, direccion, nombre_corto, suspendido) FROM stdin;
1	cliente01	23223434	fulano fulano	calle 1 comuna las cabras	cli01	f
2	Cliente 003	cli07	FFFcccc dddd	11111111	calle u	f
3	Energía	34342345	NNHG	Los Condores 2234, Coyhaique	energia	f
4	cliente cuatro	cli04	jjjj oooo	887666	calle u	f
5	cliente cinco	11111111	aaa eee	calle uno 23, osorno	cli05	f
6	cliente seis	456565	rreerer rrgr	calle uno 23, osorno	cli06	f
7	Uno	232344234	aaa eee	calle uno 23, osorno	uno	f
0	Quinta Energy Laboratorios.	99995555	Pedro Soto	Avda. Ventisquero 1265, bodega N°4, Renca, Santiago.	quinta	f
\.


--
-- TOC entry 3574 (class 0 OID 16457)
-- Dependencies: 208
-- Data for Name: cliente_negocio_sucursal; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.cliente_negocio_sucursal (id_cliente_n_s, cliente, negocio, sucursal, direccion) FROM stdin;
1000	0	1	1101	
1001	0	2	1101	
1002	0	3	1101	
1003	0	4	1101	
1004	0	5	1101	
1005	1	1	1101	
1006	1	2	1101	
1007	1	3	1101	
1008	1	4	1101	
1009	1	5	1101	
1010	2	1	1101	
1011	2	2	1101	
1012	2	3	1101	
1013	2	4	1101	
1014	2	5	1101	
1015	3	1	1101	
1016	3	2	1101	
1017	3	3	1101	
1018	3	4	1101	
1019	3	5	1101	
1020	0	1	1106	
1021	0	2	1106	
1022	0	3	1106	
1023	0	4	1106	
1024	0	5	1106	
1025	1	1	1106	
1026	1	2	1106	
1027	1	3	1106	
1028	1	4	1106	
1029	1	5	1106	
1030	2	1	1106	
1031	2	2	1106	
1032	2	3	1106	
1033	2	4	1106	
1034	2	5	1106	
1035	3	1	1106	
1036	3	2	1106	
1037	3	3	1106	
1038	3	4	1106	
1039	3	5	1106	
1040	0	1	1201	
1041	0	2	1201	
1042	0	3	1201	
1043	0	4	1201	
1044	0	5	1201	
1045	1	1	1201	
1046	1	2	1201	
1047	1	3	1201	
1048	1	4	1201	
1049	1	5	1201	
1050	2	1	1201	
1051	2	2	1201	
1052	2	3	1201	
1053	2	4	1201	
1054	2	5	1201	
1055	3	1	1201	
1056	3	2	1201	
1057	3	3	1201	
1058	3	4	1201	
1059	3	5	1201	
1060	0	1	1203	
1061	0	2	1203	
1062	0	3	1203	
1063	0	4	1203	
1064	0	5	1203	
1065	1	1	1203	
1066	1	2	1203	
1067	1	3	1203	
1068	1	4	1203	
1069	1	5	1203	
1070	2	1	1203	
1071	2	2	1203	
1072	2	3	1203	
1073	2	4	1203	
1074	2	5	1203	
1075	3	1	1203	
1076	3	2	1203	
1077	3	3	1203	
1078	3	4	1203	
1079	3	5	1203	
1080	0	1	1204	
1081	0	2	1204	
1082	0	3	1204	
1083	0	4	1204	
1084	0	5	1204	
1085	1	1	1204	
1086	1	2	1204	
1087	1	3	1204	
1088	1	4	1204	
1089	1	5	1204	
1090	2	1	1204	
1091	2	2	1204	
1092	2	3	1204	
1093	2	4	1204	
1094	2	5	1204	
1095	3	1	1204	
1096	3	2	1204	
1097	3	3	1204	
1098	3	4	1204	
1099	3	5	1204	
1100	0	1	1206	
1101	0	2	1206	
1102	0	3	1206	
1103	0	4	1206	
1104	0	5	1206	
1105	1	1	1206	
1106	1	2	1206	
1107	1	3	1206	
1108	1	4	1206	
1109	1	5	1206	
1110	2	1	1206	
1111	2	2	1206	
1112	2	3	1206	
1113	2	4	1206	
1114	2	5	1206	
1115	3	1	1206	
1116	3	2	1206	
1117	3	3	1206	
1118	3	4	1206	
1119	3	5	1206	
1120	0	1	1208	
1121	0	2	1208	
1122	0	3	1208	
1123	0	4	1208	
1124	0	5	1208	
1125	1	1	1208	
1126	1	2	1208	
1127	1	3	1208	
1128	1	4	1208	
1129	1	5	1208	
1130	2	1	1208	
1131	2	2	1208	
1132	2	3	1208	
1133	2	4	1208	
1134	2	5	1208	
1135	3	1	1208	
1136	3	2	1208	
1137	3	3	1208	
1138	3	4	1208	
1139	3	5	1208	
1140	0	1	1210	
1141	0	2	1210	
1142	0	3	1210	
1143	0	4	1210	
1144	0	5	1210	
1145	1	1	1210	
1146	1	2	1210	
1147	1	3	1210	
1148	1	4	1210	
1149	1	5	1210	
1150	2	1	1210	
1151	2	2	1210	
1152	2	3	1210	
1153	2	4	1210	
1154	2	5	1210	
1155	3	1	1210	
1156	3	2	1210	
1157	3	3	1210	
1158	3	4	1210	
1159	3	5	1210	
1160	0	1	1211	
1161	0	2	1211	
1162	0	3	1211	
1163	0	4	1211	
1164	0	5	1211	
1165	1	1	1211	
1166	1	2	1211	
1167	1	3	1211	
1168	1	4	1211	
1169	1	5	1211	
1170	2	1	1211	
1171	2	2	1211	
1172	2	3	1211	
1173	2	4	1211	
1174	2	5	1211	
1175	3	1	1211	
1176	3	2	1211	
1177	3	3	1211	
1178	3	4	1211	
1179	3	5	1211	
1180	0	1	1301	
1181	0	2	1301	
1182	0	3	1301	
1183	0	4	1301	
1184	0	5	1301	
1185	1	1	1301	
1186	1	2	1301	
1187	1	3	1301	
1188	1	4	1301	
1189	1	5	1301	
1190	2	1	1301	
1191	2	2	1301	
1192	2	3	1301	
1193	2	4	1301	
1194	2	5	1301	
1195	3	1	1301	
1196	3	2	1301	
1197	3	3	1301	
1198	3	4	1301	
1199	3	5	1301	
1200	0	1	1302	
1201	0	2	1302	
1202	0	3	1302	
1203	0	4	1302	
1204	0	5	1302	
1205	1	1	1302	
1206	1	2	1302	
1207	1	3	1302	
1208	1	4	1302	
1209	1	5	1302	
1210	2	1	1302	
1211	2	2	1302	
1212	2	3	1302	
1213	2	4	1302	
1214	2	5	1302	
1215	3	1	1302	
1216	3	2	1302	
1217	3	3	1302	
1218	3	4	1302	
1219	3	5	1302	
1220	0	1	2101	
1221	0	2	2101	
1222	0	3	2101	
1223	0	4	2101	
1224	0	5	2101	
1225	1	1	2101	
1226	1	2	2101	
1227	1	3	2101	
1228	1	4	2101	
1229	1	5	2101	
1230	2	1	2101	
1231	2	2	2101	
1232	2	3	2101	
1233	2	4	2101	
1234	2	5	2101	
1235	3	1	2101	
1236	3	2	2101	
1237	3	3	2101	
1238	3	4	2101	
1239	3	5	2101	
1240	0	1	2103	
1241	0	2	2103	
1242	0	3	2103	
1243	0	4	2103	
1244	0	5	2103	
1245	1	1	2103	
1246	1	2	2103	
1247	1	3	2103	
1248	1	4	2103	
1249	1	5	2103	
1250	2	1	2103	
1251	2	2	2103	
1252	2	3	2103	
1253	2	4	2103	
1254	2	5	2103	
1255	3	1	2103	
1256	3	2	2103	
1257	3	3	2103	
1258	3	4	2103	
1259	3	5	2103	
1260	0	1	2201	
1261	0	2	2201	
1262	0	3	2201	
1263	0	4	2201	
1264	0	5	2201	
1265	1	1	2201	
1266	1	2	2201	
1267	1	3	2201	
1268	1	4	2201	
1269	1	5	2201	
1270	2	1	2201	
1271	2	2	2201	
1272	2	3	2201	
1273	2	4	2201	
1274	2	5	2201	
1275	3	1	2201	
1276	3	2	2201	
1277	3	3	2201	
1278	3	4	2201	
1279	3	5	2201	
1280	0	1	2202	
1281	0	2	2202	
1282	0	3	2202	
1283	0	4	2202	
1284	0	5	2202	
1285	1	1	2202	
1286	1	2	2202	
1287	1	3	2202	
1288	1	4	2202	
1289	1	5	2202	
1290	2	1	2202	
1291	2	2	2202	
1292	2	3	2202	
1293	2	4	2202	
1294	2	5	2202	
1295	3	1	2202	
1296	3	2	2202	
1297	3	3	2202	
1298	3	4	2202	
1299	3	5	2202	
1300	0	1	2203	
1301	0	2	2203	
1302	0	3	2203	
1303	0	4	2203	
1304	0	5	2203	
1305	1	1	2203	
1306	1	2	2203	
1307	1	3	2203	
1308	1	4	2203	
1309	1	5	2203	
1310	2	1	2203	
1311	2	2	2203	
1312	2	3	2203	
1313	2	4	2203	
1314	2	5	2203	
1315	3	1	2203	
1316	3	2	2203	
1317	3	3	2203	
1318	3	4	2203	
1319	3	5	2203	
1320	0	1	2206	
1321	0	2	2206	
1322	0	3	2206	
1323	0	4	2206	
1324	0	5	2206	
1325	1	1	2206	
1326	1	2	2206	
1327	1	3	2206	
1328	1	4	2206	
1329	1	5	2206	
1330	2	1	2206	
1331	2	2	2206	
1332	2	3	2206	
1333	2	4	2206	
1334	2	5	2206	
1335	3	1	2206	
1336	3	2	2206	
1337	3	3	2206	
1338	3	4	2206	
1339	3	5	2206	
1340	0	1	2301	
1341	0	2	2301	
1342	0	3	2301	
1343	0	4	2301	
1344	0	5	2301	
1345	1	1	2301	
1346	1	2	2301	
1347	1	3	2301	
1348	1	4	2301	
1349	1	5	2301	
1350	2	1	2301	
1351	2	2	2301	
1352	2	3	2301	
1353	2	4	2301	
1354	2	5	2301	
1355	3	1	2301	
1356	3	2	2301	
1357	3	3	2301	
1358	3	4	2301	
1359	3	5	2301	
1360	0	1	2302	
1361	0	2	2302	
1362	0	3	2302	
1363	0	4	2302	
1364	0	5	2302	
1365	1	1	2302	
1366	1	2	2302	
1367	1	3	2302	
1368	1	4	2302	
1369	1	5	2302	
1370	2	1	2302	
1371	2	2	2302	
1372	2	3	2302	
1373	2	4	2302	
1374	2	5	2302	
1375	3	1	2302	
1376	3	2	2302	
1377	3	3	2302	
1378	3	4	2302	
1379	3	5	2302	
1380	0	1	2303	
1381	0	2	2303	
1382	0	3	2303	
1383	0	4	2303	
1384	0	5	2303	
1385	1	1	2303	
1386	1	2	2303	
1387	1	3	2303	
1388	1	4	2303	
1389	1	5	2303	
1390	2	1	2303	
1391	2	2	2303	
1392	2	3	2303	
1393	2	4	2303	
1394	2	5	2303	
1395	3	1	2303	
1396	3	2	2303	
1397	3	3	2303	
1398	3	4	2303	
1399	3	5	2303	
1400	0	1	3101	
1401	0	2	3101	
1402	0	3	3101	
1403	0	4	3101	
1404	0	5	3101	
1405	1	1	3101	
1406	1	2	3101	
1407	1	3	3101	
1408	1	4	3101	
1409	1	5	3101	
1410	2	1	3101	
1411	2	2	3101	
1412	2	3	3101	
1413	2	4	3101	
1414	2	5	3101	
1415	3	1	3101	
1416	3	2	3101	
1417	3	3	3101	
1418	3	4	3101	
1419	3	5	3101	
1420	0	1	3102	
1421	0	2	3102	
1422	0	3	3102	
1423	0	4	3102	
1424	0	5	3102	
1425	1	1	3102	
1426	1	2	3102	
1427	1	3	3102	
1428	1	4	3102	
1429	1	5	3102	
1430	2	1	3102	
1431	2	2	3102	
1432	2	3	3102	
1433	2	4	3102	
1434	2	5	3102	
1435	3	1	3102	
1436	3	2	3102	
1437	3	3	3102	
1438	3	4	3102	
1439	3	5	3102	
1440	0	1	3201	
1441	0	2	3201	
1442	0	3	3201	
1443	0	4	3201	
1444	0	5	3201	
1445	1	1	3201	
1446	1	2	3201	
1447	1	3	3201	
1448	1	4	3201	
1449	1	5	3201	
1450	2	1	3201	
1451	2	2	3201	
1452	2	3	3201	
1453	2	4	3201	
1454	2	5	3201	
1455	3	1	3201	
1456	3	2	3201	
1457	3	3	3201	
1458	3	4	3201	
1459	3	5	3201	
1460	0	1	3202	
1461	0	2	3202	
1462	0	3	3202	
1463	0	4	3202	
1464	0	5	3202	
1465	1	1	3202	
1466	1	2	3202	
1467	1	3	3202	
1468	1	4	3202	
1469	1	5	3202	
1470	2	1	3202	
1471	2	2	3202	
1472	2	3	3202	
1473	2	4	3202	
1474	2	5	3202	
1475	3	1	3202	
1476	3	2	3202	
1477	3	3	3202	
1478	3	4	3202	
1479	3	5	3202	
1480	0	1	3203	
1481	0	2	3203	
1482	0	3	3203	
1483	0	4	3203	
1484	0	5	3203	
1485	1	1	3203	
1486	1	2	3203	
1487	1	3	3203	
1488	1	4	3203	
1489	1	5	3203	
1490	2	1	3203	
1491	2	2	3203	
1492	2	3	3203	
1493	2	4	3203	
1494	2	5	3203	
1495	3	1	3203	
1496	3	2	3203	
1497	3	3	3203	
1498	3	4	3203	
1499	3	5	3203	
1500	0	1	3301	
1501	0	2	3301	
1502	0	3	3301	
1503	0	4	3301	
1504	0	5	3301	
1505	1	1	3301	
1506	1	2	3301	
1507	1	3	3301	
1508	1	4	3301	
1509	1	5	3301	
1510	2	1	3301	
1511	2	2	3301	
1512	2	3	3301	
1513	2	4	3301	
1514	2	5	3301	
1515	3	1	3301	
1516	3	2	3301	
1517	3	3	3301	
1518	3	4	3301	
1519	3	5	3301	
1520	0	1	3302	
1521	0	2	3302	
1522	0	3	3302	
1523	0	4	3302	
1524	0	5	3302	
1525	1	1	3302	
1526	1	2	3302	
1527	1	3	3302	
1528	1	4	3302	
1529	1	5	3302	
1530	2	1	3302	
1531	2	2	3302	
1532	2	3	3302	
1533	2	4	3302	
1534	2	5	3302	
1535	3	1	3302	
1536	3	2	3302	
1537	3	3	3302	
1538	3	4	3302	
1539	3	5	3302	
1540	0	1	3303	
1541	0	2	3303	
1542	0	3	3303	
1543	0	4	3303	
1544	0	5	3303	
1545	1	1	3303	
1546	1	2	3303	
1547	1	3	3303	
1548	1	4	3303	
1549	1	5	3303	
1550	2	1	3303	
1551	2	2	3303	
1552	2	3	3303	
1553	2	4	3303	
1554	2	5	3303	
1555	3	1	3303	
1556	3	2	3303	
1557	3	3	3303	
1558	3	4	3303	
1559	3	5	3303	
1560	0	1	3304	
1561	0	2	3304	
1562	0	3	3304	
1563	0	4	3304	
1564	0	5	3304	
1565	1	1	3304	
1566	1	2	3304	
1567	1	3	3304	
1568	1	4	3304	
1569	1	5	3304	
1570	2	1	3304	
1571	2	2	3304	
1572	2	3	3304	
1573	2	4	3304	
1574	2	5	3304	
1575	3	1	3304	
1576	3	2	3304	
1577	3	3	3304	
1578	3	4	3304	
1579	3	5	3304	
1580	0	1	4101	
1581	0	2	4101	
1582	0	3	4101	
1583	0	4	4101	
1584	0	5	4101	
1585	1	1	4101	
1586	1	2	4101	
1587	1	3	4101	
1588	1	4	4101	
1589	1	5	4101	
1590	2	1	4101	
1591	2	2	4101	
1592	2	3	4101	
1593	2	4	4101	
1594	2	5	4101	
1595	3	1	4101	
1596	3	2	4101	
1597	3	3	4101	
1598	3	4	4101	
1599	3	5	4101	
1600	0	1	4102	
1601	0	2	4102	
1602	0	3	4102	
1603	0	4	4102	
1604	0	5	4102	
1605	1	1	4102	
1606	1	2	4102	
1607	1	3	4102	
1608	1	4	4102	
1609	1	5	4102	
1610	2	1	4102	
1611	2	2	4102	
1612	2	3	4102	
1613	2	4	4102	
1614	2	5	4102	
1615	3	1	4102	
1616	3	2	4102	
1617	3	3	4102	
1618	3	4	4102	
1619	3	5	4102	
1620	0	1	4103	
1621	0	2	4103	
1622	0	3	4103	
1623	0	4	4103	
1624	0	5	4103	
1625	1	1	4103	
1626	1	2	4103	
1627	1	3	4103	
1628	1	4	4103	
1629	1	5	4103	
1630	2	1	4103	
1631	2	2	4103	
1632	2	3	4103	
1633	2	4	4103	
1634	2	5	4103	
1635	3	1	4103	
1636	3	2	4103	
1637	3	3	4103	
1638	3	4	4103	
1639	3	5	4103	
1640	0	1	4104	
1641	0	2	4104	
1642	0	3	4104	
1643	0	4	4104	
1644	0	5	4104	
1645	1	1	4104	
1646	1	2	4104	
1647	1	3	4104	
1648	1	4	4104	
1649	1	5	4104	
1650	2	1	4104	
1651	2	2	4104	
1652	2	3	4104	
1653	2	4	4104	
1654	2	5	4104	
1655	3	1	4104	
1656	3	2	4104	
1657	3	3	4104	
1658	3	4	4104	
1659	3	5	4104	
1660	0	1	4105	
1661	0	2	4105	
1662	0	3	4105	
1663	0	4	4105	
1664	0	5	4105	
1665	1	1	4105	
1666	1	2	4105	
1667	1	3	4105	
1668	1	4	4105	
1669	1	5	4105	
1670	2	1	4105	
1671	2	2	4105	
1672	2	3	4105	
1673	2	4	4105	
1674	2	5	4105	
1675	3	1	4105	
1676	3	2	4105	
1677	3	3	4105	
1678	3	4	4105	
1679	3	5	4105	
1680	0	1	4106	
1681	0	2	4106	
1682	0	3	4106	
1683	0	4	4106	
1684	0	5	4106	
1685	1	1	4106	
1686	1	2	4106	
1687	1	3	4106	
1688	1	4	4106	
1689	1	5	4106	
1690	2	1	4106	
1691	2	2	4106	
1692	2	3	4106	
1693	2	4	4106	
1694	2	5	4106	
1695	3	1	4106	
1696	3	2	4106	
1697	3	3	4106	
1698	3	4	4106	
1699	3	5	4106	
1700	0	1	4201	
1701	0	2	4201	
1702	0	3	4201	
1703	0	4	4201	
1704	0	5	4201	
1705	1	1	4201	
1706	1	2	4201	
1707	1	3	4201	
1708	1	4	4201	
1709	1	5	4201	
1710	2	1	4201	
1711	2	2	4201	
1712	2	3	4201	
1713	2	4	4201	
1714	2	5	4201	
1715	3	1	4201	
1716	3	2	4201	
1717	3	3	4201	
1718	3	4	4201	
1719	3	5	4201	
1720	0	1	4203	
1721	0	2	4203	
1722	0	3	4203	
1723	0	4	4203	
1724	0	5	4203	
1725	1	1	4203	
1726	1	2	4203	
1727	1	3	4203	
1728	1	4	4203	
1729	1	5	4203	
1730	2	1	4203	
1731	2	2	4203	
1732	2	3	4203	
1733	2	4	4203	
1734	2	5	4203	
1735	3	1	4203	
1736	3	2	4203	
1737	3	3	4203	
1738	3	4	4203	
1739	3	5	4203	
1740	0	1	4204	
1741	0	2	4204	
1742	0	3	4204	
1743	0	4	4204	
1744	0	5	4204	
1745	1	1	4204	
1746	1	2	4204	
1747	1	3	4204	
1748	1	4	4204	
1749	1	5	4204	
1750	2	1	4204	
1751	2	2	4204	
1752	2	3	4204	
1753	2	4	4204	
1754	2	5	4204	
1755	3	1	4204	
1756	3	2	4204	
1757	3	3	4204	
1758	3	4	4204	
1759	3	5	4204	
1760	0	1	4205	
1761	0	2	4205	
1762	0	3	4205	
1763	0	4	4205	
1764	0	5	4205	
1765	1	1	4205	
1766	1	2	4205	
1767	1	3	4205	
1768	1	4	4205	
1769	1	5	4205	
1770	2	1	4205	
1771	2	2	4205	
1772	2	3	4205	
1773	2	4	4205	
1774	2	5	4205	
1775	3	1	4205	
1776	3	2	4205	
1777	3	3	4205	
1778	3	4	4205	
1779	3	5	4205	
1780	0	1	4206	
1781	0	2	4206	
1782	0	3	4206	
1783	0	4	4206	
1784	0	5	4206	
1785	1	1	4206	
1786	1	2	4206	
1787	1	3	4206	
1788	1	4	4206	
1789	1	5	4206	
1790	2	1	4206	
1791	2	2	4206	
1792	2	3	4206	
1793	2	4	4206	
1794	2	5	4206	
1795	3	1	4206	
1796	3	2	4206	
1797	3	3	4206	
1798	3	4	4206	
1799	3	5	4206	
1800	0	1	4301	
1801	0	2	4301	
1802	0	3	4301	
1803	0	4	4301	
1804	0	5	4301	
1805	1	1	4301	
1806	1	2	4301	
1807	1	3	4301	
1808	1	4	4301	
1809	1	5	4301	
1810	2	1	4301	
1811	2	2	4301	
1812	2	3	4301	
1813	2	4	4301	
1814	2	5	4301	
1815	3	1	4301	
1816	3	2	4301	
1817	3	3	4301	
1818	3	4	4301	
1819	3	5	4301	
1820	0	1	4302	
1821	0	2	4302	
1822	0	3	4302	
1823	0	4	4302	
1824	0	5	4302	
1825	1	1	4302	
1826	1	2	4302	
1827	1	3	4302	
1828	1	4	4302	
1829	1	5	4302	
1830	2	1	4302	
1831	2	2	4302	
1832	2	3	4302	
1833	2	4	4302	
1834	2	5	4302	
1835	3	1	4302	
1836	3	2	4302	
1837	3	3	4302	
1838	3	4	4302	
1839	3	5	4302	
1840	0	1	4303	
1841	0	2	4303	
1842	0	3	4303	
1843	0	4	4303	
1844	0	5	4303	
1845	1	1	4303	
1846	1	2	4303	
1847	1	3	4303	
1848	1	4	4303	
1849	1	5	4303	
1850	2	1	4303	
1851	2	2	4303	
1852	2	3	4303	
1853	2	4	4303	
1854	2	5	4303	
1855	3	1	4303	
1856	3	2	4303	
1857	3	3	4303	
1858	3	4	4303	
1859	3	5	4303	
1860	0	1	4304	
1861	0	2	4304	
1862	0	3	4304	
1863	0	4	4304	
1864	0	5	4304	
1865	1	1	4304	
1866	1	2	4304	
1867	1	3	4304	
1868	1	4	4304	
1869	1	5	4304	
1870	2	1	4304	
1871	2	2	4304	
1872	2	3	4304	
1873	2	4	4304	
1874	2	5	4304	
1875	3	1	4304	
1876	3	2	4304	
1877	3	3	4304	
1878	3	4	4304	
1879	3	5	4304	
1880	0	1	5101	
1881	0	2	5101	
1882	0	3	5101	
1883	0	4	5101	
1884	0	5	5101	
1885	1	1	5101	
1886	1	2	5101	
1887	1	3	5101	
1888	1	4	5101	
1889	1	5	5101	
1890	2	1	5101	
1891	2	2	5101	
1892	2	3	5101	
1893	2	4	5101	
1894	2	5	5101	
1895	3	1	5101	
1896	3	2	5101	
1897	3	3	5101	
1898	3	4	5101	
1899	3	5	5101	
1900	0	1	5201	
1901	0	2	5201	
1902	0	3	5201	
1903	0	4	5201	
1904	0	5	5201	
1905	1	1	5201	
1906	1	2	5201	
1907	1	3	5201	
1908	1	4	5201	
1909	1	5	5201	
1910	2	1	5201	
1911	2	2	5201	
1912	2	3	5201	
1913	2	4	5201	
1914	2	5	5201	
1915	3	1	5201	
1916	3	2	5201	
1917	3	3	5201	
1918	3	4	5201	
1919	3	5	5201	
1920	0	1	5202	
1921	0	2	5202	
1922	0	3	5202	
1923	0	4	5202	
1924	0	5	5202	
1925	1	1	5202	
1926	1	2	5202	
1927	1	3	5202	
1928	1	4	5202	
1929	1	5	5202	
1930	2	1	5202	
1931	2	2	5202	
1932	2	3	5202	
1933	2	4	5202	
1934	2	5	5202	
1935	3	1	5202	
1936	3	2	5202	
1937	3	3	5202	
1938	3	4	5202	
1939	3	5	5202	
1940	0	1	5203	
1941	0	2	5203	
1942	0	3	5203	
1943	0	4	5203	
1944	0	5	5203	
1945	1	1	5203	
1946	1	2	5203	
1947	1	3	5203	
1948	1	4	5203	
1949	1	5	5203	
1950	2	1	5203	
1951	2	2	5203	
1952	2	3	5203	
1953	2	4	5203	
1954	2	5	5203	
1955	3	1	5203	
1956	3	2	5203	
1957	3	3	5203	
1958	3	4	5203	
1959	3	5	5203	
1960	0	1	5204	
1961	0	2	5204	
1962	0	3	5204	
1963	0	4	5204	
1964	0	5	5204	
1965	1	1	5204	
1966	1	2	5204	
1967	1	3	5204	
1968	1	4	5204	
1969	1	5	5204	
1970	2	1	5204	
1971	2	2	5204	
1972	2	3	5204	
1973	2	4	5204	
1974	2	5	5204	
1975	3	1	5204	
1976	3	2	5204	
1977	3	3	5204	
1978	3	4	5204	
1979	3	5	5204	
1980	0	1	5205	
1981	0	2	5205	
1982	0	3	5205	
1983	0	4	5205	
1984	0	5	5205	
1985	1	1	5205	
1986	1	2	5205	
1987	1	3	5205	
1988	1	4	5205	
1989	1	5	5205	
1990	2	1	5205	
1991	2	2	5205	
1992	2	3	5205	
1993	2	4	5205	
1994	2	5	5205	
1995	3	1	5205	
1996	3	2	5205	
1997	3	3	5205	
1998	3	4	5205	
1999	3	5	5205	
2000	0	1	5301	
2001	0	2	5301	
2002	0	3	5301	
2003	0	4	5301	
2004	0	5	5301	
2005	1	1	5301	
2006	1	2	5301	
2007	1	3	5301	
2008	1	4	5301	
2009	1	5	5301	
2010	2	1	5301	
2011	2	2	5301	
2012	2	3	5301	
2013	2	4	5301	
2014	2	5	5301	
2015	3	1	5301	
2016	3	2	5301	
2017	3	3	5301	
2018	3	4	5301	
2019	3	5	5301	
2020	0	1	5302	
2021	0	2	5302	
2022	0	3	5302	
2023	0	4	5302	
2024	0	5	5302	
2025	1	1	5302	
2026	1	2	5302	
2027	1	3	5302	
2028	1	4	5302	
2029	1	5	5302	
2030	2	1	5302	
2031	2	2	5302	
2032	2	3	5302	
2033	2	4	5302	
2034	2	5	5302	
2035	3	1	5302	
2036	3	2	5302	
2037	3	3	5302	
2038	3	4	5302	
2039	3	5	5302	
2040	0	1	5303	
2041	0	2	5303	
2042	0	3	5303	
2043	0	4	5303	
2044	0	5	5303	
2045	1	1	5303	
2046	1	2	5303	
2047	1	3	5303	
2048	1	4	5303	
2049	1	5	5303	
2050	2	1	5303	
2051	2	2	5303	
2052	2	3	5303	
2053	2	4	5303	
2054	2	5	5303	
2055	3	1	5303	
2056	3	2	5303	
2057	3	3	5303	
2058	3	4	5303	
2059	3	5	5303	
2060	0	1	5304	
2061	0	2	5304	
2062	0	3	5304	
2063	0	4	5304	
2064	0	5	5304	
2065	1	1	5304	
2066	1	2	5304	
2067	1	3	5304	
2068	1	4	5304	
2069	1	5	5304	
2070	2	1	5304	
2071	2	2	5304	
2072	2	3	5304	
2073	2	4	5304	
2074	2	5	5304	
2075	3	1	5304	
2076	3	2	5304	
2077	3	3	5304	
2078	3	4	5304	
2079	3	5	5304	
2080	0	1	5305	
2081	0	2	5305	
2082	0	3	5305	
2083	0	4	5305	
2084	0	5	5305	
2085	1	1	5305	
2086	1	2	5305	
2087	1	3	5305	
2088	1	4	5305	
2089	1	5	5305	
2090	2	1	5305	
2091	2	2	5305	
2092	2	3	5305	
2093	2	4	5305	
2094	2	5	5305	
2095	3	1	5305	
2096	3	2	5305	
2097	3	3	5305	
2098	3	4	5305	
2099	3	5	5305	
2100	0	1	5306	
2101	0	2	5306	
2102	0	3	5306	
2103	0	4	5306	
2104	0	5	5306	
2105	1	1	5306	
2106	1	2	5306	
2107	1	3	5306	
2108	1	4	5306	
2109	1	5	5306	
2110	2	1	5306	
2111	2	2	5306	
2112	2	3	5306	
2113	2	4	5306	
2114	2	5	5306	
2115	3	1	5306	
2116	3	2	5306	
2117	3	3	5306	
2118	3	4	5306	
2119	3	5	5306	
2120	0	1	5307	
2121	0	2	5307	
2122	0	3	5307	
2123	0	4	5307	
2124	0	5	5307	
2125	1	1	5307	
2126	1	2	5307	
2127	1	3	5307	
2128	1	4	5307	
2129	1	5	5307	
2130	2	1	5307	
2131	2	2	5307	
2132	2	3	5307	
2133	2	4	5307	
2134	2	5	5307	
2135	3	1	5307	
2136	3	2	5307	
2137	3	3	5307	
2138	3	4	5307	
2139	3	5	5307	
2140	0	1	5308	
2141	0	2	5308	
2142	0	3	5308	
2143	0	4	5308	
2144	0	5	5308	
2145	1	1	5308	
2146	1	2	5308	
2147	1	3	5308	
2148	1	4	5308	
2149	1	5	5308	
2150	2	1	5308	
2151	2	2	5308	
2152	2	3	5308	
2153	2	4	5308	
2154	2	5	5308	
2155	3	1	5308	
2156	3	2	5308	
2157	3	3	5308	
2158	3	4	5308	
2159	3	5	5308	
2160	0	1	5309	
2161	0	2	5309	
2162	0	3	5309	
2163	0	4	5309	
2164	0	5	5309	
2165	1	1	5309	
2166	1	2	5309	
2167	1	3	5309	
2168	1	4	5309	
2169	1	5	5309	
2170	2	1	5309	
2171	2	2	5309	
2172	2	3	5309	
2173	2	4	5309	
2174	2	5	5309	
2175	3	1	5309	
2176	3	2	5309	
2177	3	3	5309	
2178	3	4	5309	
2179	3	5	5309	
2180	0	1	5401	
2181	0	2	5401	
2182	0	3	5401	
2183	0	4	5401	
2184	0	5	5401	
2185	1	1	5401	
2186	1	2	5401	
2187	1	3	5401	
2188	1	4	5401	
2189	1	5	5401	
2190	2	1	5401	
2191	2	2	5401	
2192	2	3	5401	
2193	2	4	5401	
2194	2	5	5401	
2195	3	1	5401	
2196	3	2	5401	
2197	3	3	5401	
2198	3	4	5401	
2199	3	5	5401	
2200	0	1	5402	
2201	0	2	5402	
2202	0	3	5402	
2203	0	4	5402	
2204	0	5	5402	
2205	1	1	5402	
2206	1	2	5402	
2207	1	3	5402	
2208	1	4	5402	
2209	1	5	5402	
2210	2	1	5402	
2211	2	2	5402	
2212	2	3	5402	
2213	2	4	5402	
2214	2	5	5402	
2215	3	1	5402	
2216	3	2	5402	
2217	3	3	5402	
2218	3	4	5402	
2219	3	5	5402	
2220	0	1	5403	
2221	0	2	5403	
2222	0	3	5403	
2223	0	4	5403	
2224	0	5	5403	
2225	1	1	5403	
2226	1	2	5403	
2227	1	3	5403	
2228	1	4	5403	
2229	1	5	5403	
2230	2	1	5403	
2231	2	2	5403	
2232	2	3	5403	
2233	2	4	5403	
2234	2	5	5403	
2235	3	1	5403	
2236	3	2	5403	
2237	3	3	5403	
2238	3	4	5403	
2239	3	5	5403	
2240	0	1	5404	
2241	0	2	5404	
2242	0	3	5404	
2243	0	4	5404	
2244	0	5	5404	
2245	1	1	5404	
2246	1	2	5404	
2247	1	3	5404	
2248	1	4	5404	
2249	1	5	5404	
2250	2	1	5404	
2251	2	2	5404	
2252	2	3	5404	
2253	2	4	5404	
2254	2	5	5404	
2255	3	1	5404	
2256	3	2	5404	
2257	3	3	5404	
2258	3	4	5404	
2259	3	5	5404	
2260	0	1	5405	
2261	0	2	5405	
2262	0	3	5405	
2263	0	4	5405	
2264	0	5	5405	
2265	1	1	5405	
2266	1	2	5405	
2267	1	3	5405	
2268	1	4	5405	
2269	1	5	5405	
2270	2	1	5405	
2271	2	2	5405	
2272	2	3	5405	
2273	2	4	5405	
2274	2	5	5405	
2275	3	1	5405	
2276	3	2	5405	
2277	3	3	5405	
2278	3	4	5405	
2279	3	5	5405	
2280	0	1	5406	
2281	0	2	5406	
2282	0	3	5406	
2283	0	4	5406	
2284	0	5	5406	
2285	1	1	5406	
2286	1	2	5406	
2287	1	3	5406	
2288	1	4	5406	
2289	1	5	5406	
2290	2	1	5406	
2291	2	2	5406	
2292	2	3	5406	
2293	2	4	5406	
2294	2	5	5406	
2295	3	1	5406	
2296	3	2	5406	
2297	3	3	5406	
2298	3	4	5406	
2299	3	5	5406	
2300	0	1	5501	
2301	0	2	5501	
2302	0	3	5501	
2303	0	4	5501	
2304	0	5	5501	
2305	1	1	5501	
2306	1	2	5501	
2307	1	3	5501	
2308	1	4	5501	
2309	1	5	5501	
2310	2	1	5501	
2311	2	2	5501	
2312	2	3	5501	
2313	2	4	5501	
2314	2	5	5501	
2315	3	1	5501	
2316	3	2	5501	
2317	3	3	5501	
2318	3	4	5501	
2319	3	5	5501	
2320	0	1	5502	
2321	0	2	5502	
2322	0	3	5502	
2323	0	4	5502	
2324	0	5	5502	
2325	1	1	5502	
2326	1	2	5502	
2327	1	3	5502	
2328	1	4	5502	
2329	1	5	5502	
2330	2	1	5502	
2331	2	2	5502	
2332	2	3	5502	
2333	2	4	5502	
2334	2	5	5502	
2335	3	1	5502	
2336	3	2	5502	
2337	3	3	5502	
2338	3	4	5502	
2339	3	5	5502	
2340	0	1	5503	
2341	0	2	5503	
2342	0	3	5503	
2343	0	4	5503	
2344	0	5	5503	
2345	1	1	5503	
2346	1	2	5503	
2347	1	3	5503	
2348	1	4	5503	
2349	1	5	5503	
2350	2	1	5503	
2351	2	2	5503	
2352	2	3	5503	
2353	2	4	5503	
2354	2	5	5503	
2355	3	1	5503	
2356	3	2	5503	
2357	3	3	5503	
2358	3	4	5503	
2359	3	5	5503	
2360	0	1	5504	
2361	0	2	5504	
2362	0	3	5504	
2363	0	4	5504	
2364	0	5	5504	
2365	1	1	5504	
2366	1	2	5504	
2367	1	3	5504	
2368	1	4	5504	
2369	1	5	5504	
2370	2	1	5504	
2371	2	2	5504	
2372	2	3	5504	
2373	2	4	5504	
2374	2	5	5504	
2375	3	1	5504	
2376	3	2	5504	
2377	3	3	5504	
2378	3	4	5504	
2379	3	5	5504	
2380	0	1	5505	
2381	0	2	5505	
2382	0	3	5505	
2383	0	4	5505	
2384	0	5	5505	
2385	1	1	5505	
2386	1	2	5505	
2387	1	3	5505	
2388	1	4	5505	
2389	1	5	5505	
2390	2	1	5505	
2391	2	2	5505	
2392	2	3	5505	
2393	2	4	5505	
2394	2	5	5505	
2395	3	1	5505	
2396	3	2	5505	
2397	3	3	5505	
2398	3	4	5505	
2399	3	5	5505	
2400	0	1	5506	
2401	0	2	5506	
2402	0	3	5506	
2403	0	4	5506	
2404	0	5	5506	
2405	1	1	5506	
2406	1	2	5506	
2407	1	3	5506	
2408	1	4	5506	
2409	1	5	5506	
2410	2	1	5506	
2411	2	2	5506	
2412	2	3	5506	
2413	2	4	5506	
2414	2	5	5506	
2415	3	1	5506	
2416	3	2	5506	
2417	3	3	5506	
2418	3	4	5506	
2419	3	5	5506	
2420	0	1	5507	
2421	0	2	5507	
2422	0	3	5507	
2423	0	4	5507	
2424	0	5	5507	
2425	1	1	5507	
2426	1	2	5507	
2427	1	3	5507	
2428	1	4	5507	
2429	1	5	5507	
2430	2	1	5507	
2431	2	2	5507	
2432	2	3	5507	
2433	2	4	5507	
2434	2	5	5507	
2435	3	1	5507	
2436	3	2	5507	
2437	3	3	5507	
2438	3	4	5507	
2439	3	5	5507	
2440	0	1	5601	
2441	0	2	5601	
2442	0	3	5601	
2443	0	4	5601	
2444	0	5	5601	
2445	1	1	5601	
2446	1	2	5601	
2447	1	3	5601	
2448	1	4	5601	
2449	1	5	5601	
2450	2	1	5601	
2451	2	2	5601	
2452	2	3	5601	
2453	2	4	5601	
2454	2	5	5601	
2455	3	1	5601	
2456	3	2	5601	
2457	3	3	5601	
2458	3	4	5601	
2459	3	5	5601	
2460	0	1	5602	
2461	0	2	5602	
2462	0	3	5602	
2463	0	4	5602	
2464	0	5	5602	
2465	1	1	5602	
2466	1	2	5602	
2467	1	3	5602	
2468	1	4	5602	
2469	1	5	5602	
2470	2	1	5602	
2471	2	2	5602	
2472	2	3	5602	
2473	2	4	5602	
2474	2	5	5602	
2475	3	1	5602	
2476	3	2	5602	
2477	3	3	5602	
2478	3	4	5602	
2479	3	5	5602	
2480	0	1	5603	
2481	0	2	5603	
2482	0	3	5603	
2483	0	4	5603	
2484	0	5	5603	
2485	1	1	5603	
2486	1	2	5603	
2487	1	3	5603	
2488	1	4	5603	
2489	1	5	5603	
2490	2	1	5603	
2491	2	2	5603	
2492	2	3	5603	
2493	2	4	5603	
2494	2	5	5603	
2495	3	1	5603	
2496	3	2	5603	
2497	3	3	5603	
2498	3	4	5603	
2499	3	5	5603	
2500	0	1	5604	
2501	0	2	5604	
2502	0	3	5604	
2503	0	4	5604	
2504	0	5	5604	
2505	1	1	5604	
2506	1	2	5604	
2507	1	3	5604	
2508	1	4	5604	
2509	1	5	5604	
2510	2	1	5604	
2511	2	2	5604	
2512	2	3	5604	
2513	2	4	5604	
2514	2	5	5604	
2515	3	1	5604	
2516	3	2	5604	
2517	3	3	5604	
2518	3	4	5604	
2519	3	5	5604	
2520	0	1	5605	
2521	0	2	5605	
2522	0	3	5605	
2523	0	4	5605	
2524	0	5	5605	
2525	1	1	5605	
2526	1	2	5605	
2527	1	3	5605	
2528	1	4	5605	
2529	1	5	5605	
2530	2	1	5605	
2531	2	2	5605	
2532	2	3	5605	
2533	2	4	5605	
2534	2	5	5605	
2535	3	1	5605	
2536	3	2	5605	
2537	3	3	5605	
2538	3	4	5605	
2539	3	5	5605	
2540	0	1	5606	
2541	0	2	5606	
2542	0	3	5606	
2543	0	4	5606	
2544	0	5	5606	
2545	1	1	5606	
2546	1	2	5606	
2547	1	3	5606	
2548	1	4	5606	
2549	1	5	5606	
2550	2	1	5606	
2551	2	2	5606	
2552	2	3	5606	
2553	2	4	5606	
2554	2	5	5606	
2555	3	1	5606	
2556	3	2	5606	
2557	3	3	5606	
2558	3	4	5606	
2559	3	5	5606	
2560	0	1	5701	
2561	0	2	5701	
2562	0	3	5701	
2563	0	4	5701	
2564	0	5	5701	
2565	1	1	5701	
2566	1	2	5701	
2567	1	3	5701	
2568	1	4	5701	
2569	1	5	5701	
2570	2	1	5701	
2571	2	2	5701	
2572	2	3	5701	
2573	2	4	5701	
2574	2	5	5701	
2575	3	1	5701	
2576	3	2	5701	
2577	3	3	5701	
2578	3	4	5701	
2579	3	5	5701	
2580	0	1	5702	
2581	0	2	5702	
2582	0	3	5702	
2583	0	4	5702	
2584	0	5	5702	
2585	1	1	5702	
2586	1	2	5702	
2587	1	3	5702	
2588	1	4	5702	
2589	1	5	5702	
2590	2	1	5702	
2591	2	2	5702	
2592	2	3	5702	
2593	2	4	5702	
2594	2	5	5702	
2595	3	1	5702	
2596	3	2	5702	
2597	3	3	5702	
2598	3	4	5702	
2599	3	5	5702	
2600	0	1	5703	
2601	0	2	5703	
2602	0	3	5703	
2603	0	4	5703	
2604	0	5	5703	
2605	1	1	5703	
2606	1	2	5703	
2607	1	3	5703	
2608	1	4	5703	
2609	1	5	5703	
2610	2	1	5703	
2611	2	2	5703	
2612	2	3	5703	
2613	2	4	5703	
2614	2	5	5703	
2615	3	1	5703	
2616	3	2	5703	
2617	3	3	5703	
2618	3	4	5703	
2619	3	5	5703	
2620	0	1	5704	
2621	0	2	5704	
2622	0	3	5704	
2623	0	4	5704	
2624	0	5	5704	
2625	1	1	5704	
2626	1	2	5704	
2627	1	3	5704	
2628	1	4	5704	
2629	1	5	5704	
2630	2	1	5704	
2631	2	2	5704	
2632	2	3	5704	
2633	2	4	5704	
2634	2	5	5704	
2635	3	1	5704	
2636	3	2	5704	
2637	3	3	5704	
2638	3	4	5704	
2639	3	5	5704	
2640	0	1	6101	
2641	0	2	6101	
2642	0	3	6101	
2643	0	4	6101	
2644	0	5	6101	
2645	1	1	6101	
2646	1	2	6101	
2647	1	3	6101	
2648	1	4	6101	
2649	1	5	6101	
2650	2	1	6101	
2651	2	2	6101	
2652	2	3	6101	
2653	2	4	6101	
2654	2	5	6101	
2655	3	1	6101	
2656	3	2	6101	
2657	3	3	6101	
2658	3	4	6101	
2659	3	5	6101	
2660	0	1	6102	
2661	0	2	6102	
2662	0	3	6102	
2663	0	4	6102	
2664	0	5	6102	
2665	1	1	6102	
2666	1	2	6102	
2667	1	3	6102	
2668	1	4	6102	
2669	1	5	6102	
2670	2	1	6102	
2671	2	2	6102	
2672	2	3	6102	
2673	2	4	6102	
2674	2	5	6102	
2675	3	1	6102	
2676	3	2	6102	
2677	3	3	6102	
2678	3	4	6102	
2679	3	5	6102	
2680	0	1	6103	
2681	0	2	6103	
2682	0	3	6103	
2683	0	4	6103	
2684	0	5	6103	
2685	1	1	6103	
2686	1	2	6103	
2687	1	3	6103	
2688	1	4	6103	
2689	1	5	6103	
2690	2	1	6103	
2691	2	2	6103	
2692	2	3	6103	
2693	2	4	6103	
2694	2	5	6103	
2695	3	1	6103	
2696	3	2	6103	
2697	3	3	6103	
2698	3	4	6103	
2699	3	5	6103	
2700	0	1	6104	
2701	0	2	6104	
2702	0	3	6104	
2703	0	4	6104	
2704	0	5	6104	
2705	1	1	6104	
2706	1	2	6104	
2707	1	3	6104	
2708	1	4	6104	
2709	1	5	6104	
2710	2	1	6104	
2711	2	2	6104	
2712	2	3	6104	
2713	2	4	6104	
2714	2	5	6104	
2715	3	1	6104	
2716	3	2	6104	
2717	3	3	6104	
2718	3	4	6104	
2719	3	5	6104	
2720	0	1	6105	
2721	0	2	6105	
2722	0	3	6105	
2723	0	4	6105	
2724	0	5	6105	
2725	1	1	6105	
2726	1	2	6105	
2727	1	3	6105	
2728	1	4	6105	
2729	1	5	6105	
2730	2	1	6105	
2731	2	2	6105	
2732	2	3	6105	
2733	2	4	6105	
2734	2	5	6105	
2735	3	1	6105	
2736	3	2	6105	
2737	3	3	6105	
2738	3	4	6105	
2739	3	5	6105	
2740	0	1	6106	
2741	0	2	6106	
2742	0	3	6106	
2743	0	4	6106	
2744	0	5	6106	
2745	1	1	6106	
2746	1	2	6106	
2747	1	3	6106	
2748	1	4	6106	
2749	1	5	6106	
2750	2	1	6106	
2751	2	2	6106	
2752	2	3	6106	
2753	2	4	6106	
2754	2	5	6106	
2755	3	1	6106	
2756	3	2	6106	
2757	3	3	6106	
2758	3	4	6106	
2759	3	5	6106	
2760	0	1	6107	
2761	0	2	6107	
2762	0	3	6107	
2763	0	4	6107	
2764	0	5	6107	
2765	1	1	6107	
2766	1	2	6107	
2767	1	3	6107	
2768	1	4	6107	
2769	1	5	6107	
2770	2	1	6107	
2771	2	2	6107	
2772	2	3	6107	
2773	2	4	6107	
2774	2	5	6107	
2775	3	1	6107	
2776	3	2	6107	
2777	3	3	6107	
2778	3	4	6107	
2779	3	5	6107	
2780	0	1	6108	
2781	0	2	6108	
2782	0	3	6108	
2783	0	4	6108	
2784	0	5	6108	
2785	1	1	6108	
2786	1	2	6108	
2787	1	3	6108	
2788	1	4	6108	
2789	1	5	6108	
2790	2	1	6108	
2791	2	2	6108	
2792	2	3	6108	
2793	2	4	6108	
2794	2	5	6108	
2795	3	1	6108	
2796	3	2	6108	
2797	3	3	6108	
2798	3	4	6108	
2799	3	5	6108	
2800	0	1	6109	
2801	0	2	6109	
2802	0	3	6109	
2803	0	4	6109	
2804	0	5	6109	
2805	1	1	6109	
2806	1	2	6109	
2807	1	3	6109	
2808	1	4	6109	
2809	1	5	6109	
2810	2	1	6109	
2811	2	2	6109	
2812	2	3	6109	
2813	2	4	6109	
2814	2	5	6109	
2815	3	1	6109	
2816	3	2	6109	
2817	3	3	6109	
2818	3	4	6109	
2819	3	5	6109	
2820	0	1	6110	
2821	0	2	6110	
2822	0	3	6110	
2823	0	4	6110	
2824	0	5	6110	
2825	1	1	6110	
2826	1	2	6110	
2827	1	3	6110	
2828	1	4	6110	
2829	1	5	6110	
2830	2	1	6110	
2831	2	2	6110	
2832	2	3	6110	
2833	2	4	6110	
2834	2	5	6110	
2835	3	1	6110	
2836	3	2	6110	
2837	3	3	6110	
2838	3	4	6110	
2839	3	5	6110	
2840	0	1	6111	
2841	0	2	6111	
2842	0	3	6111	
2843	0	4	6111	
2844	0	5	6111	
2845	1	1	6111	
2846	1	2	6111	
2847	1	3	6111	
2848	1	4	6111	
2849	1	5	6111	
2850	2	1	6111	
2851	2	2	6111	
2852	2	3	6111	
2853	2	4	6111	
2854	2	5	6111	
2855	3	1	6111	
2856	3	2	6111	
2857	3	3	6111	
2858	3	4	6111	
2859	3	5	6111	
2860	0	1	6112	
2861	0	2	6112	
2862	0	3	6112	
2863	0	4	6112	
2864	0	5	6112	
2865	1	1	6112	
2866	1	2	6112	
2867	1	3	6112	
2868	1	4	6112	
2869	1	5	6112	
2870	2	1	6112	
2871	2	2	6112	
2872	2	3	6112	
2873	2	4	6112	
2874	2	5	6112	
2875	3	1	6112	
2876	3	2	6112	
2877	3	3	6112	
2878	3	4	6112	
2879	3	5	6112	
2880	0	1	6113	
2881	0	2	6113	
2882	0	3	6113	
2883	0	4	6113	
2884	0	5	6113	
2885	1	1	6113	
2886	1	2	6113	
2887	1	3	6113	
2888	1	4	6113	
2889	1	5	6113	
2890	2	1	6113	
2891	2	2	6113	
2892	2	3	6113	
2893	2	4	6113	
2894	2	5	6113	
2895	3	1	6113	
2896	3	2	6113	
2897	3	3	6113	
2898	3	4	6113	
2899	3	5	6113	
2900	0	1	6114	
2901	0	2	6114	
2902	0	3	6114	
2903	0	4	6114	
2904	0	5	6114	
2905	1	1	6114	
2906	1	2	6114	
2907	1	3	6114	
2908	1	4	6114	
2909	1	5	6114	
2910	2	1	6114	
2911	2	2	6114	
2912	2	3	6114	
2913	2	4	6114	
2914	2	5	6114	
2915	3	1	6114	
2916	3	2	6114	
2917	3	3	6114	
2918	3	4	6114	
2919	3	5	6114	
2920	0	1	6115	
2921	0	2	6115	
2922	0	3	6115	
2923	0	4	6115	
2924	0	5	6115	
2925	1	1	6115	
2926	1	2	6115	
2927	1	3	6115	
2928	1	4	6115	
2929	1	5	6115	
2930	2	1	6115	
2931	2	2	6115	
2932	2	3	6115	
2933	2	4	6115	
2934	2	5	6115	
2935	3	1	6115	
2936	3	2	6115	
2937	3	3	6115	
2938	3	4	6115	
2939	3	5	6115	
2940	0	1	6116	
2941	0	2	6116	
2942	0	3	6116	
2943	0	4	6116	
2944	0	5	6116	
2945	1	1	6116	
2946	1	2	6116	
2947	1	3	6116	
2948	1	4	6116	
2949	1	5	6116	
2950	2	1	6116	
2951	2	2	6116	
2952	2	3	6116	
2953	2	4	6116	
2954	2	5	6116	
2955	3	1	6116	
2956	3	2	6116	
2957	3	3	6116	
2958	3	4	6116	
2959	3	5	6116	
2960	0	1	6117	
2961	0	2	6117	
2962	0	3	6117	
2963	0	4	6117	
2964	0	5	6117	
2965	1	1	6117	
2966	1	2	6117	
2967	1	3	6117	
2968	1	4	6117	
2969	1	5	6117	
2970	2	1	6117	
2971	2	2	6117	
2972	2	3	6117	
2973	2	4	6117	
2974	2	5	6117	
2975	3	1	6117	
2976	3	2	6117	
2977	3	3	6117	
2978	3	4	6117	
2979	3	5	6117	
2980	0	1	6201	
2981	0	2	6201	
2982	0	3	6201	
2983	0	4	6201	
2984	0	5	6201	
2985	1	1	6201	
2986	1	2	6201	
2987	1	3	6201	
2988	1	4	6201	
2989	1	5	6201	
2990	2	1	6201	
2991	2	2	6201	
2992	2	3	6201	
2993	2	4	6201	
2994	2	5	6201	
2995	3	1	6201	
2996	3	2	6201	
2997	3	3	6201	
2998	3	4	6201	
2999	3	5	6201	
3000	0	1	6202	
3001	0	2	6202	
3002	0	3	6202	
3003	0	4	6202	
3004	0	5	6202	
3005	1	1	6202	
3006	1	2	6202	
3007	1	3	6202	
3008	1	4	6202	
3009	1	5	6202	
3010	2	1	6202	
3011	2	2	6202	
3012	2	3	6202	
3013	2	4	6202	
3014	2	5	6202	
3015	3	1	6202	
3016	3	2	6202	
3017	3	3	6202	
3018	3	4	6202	
3019	3	5	6202	
3020	0	1	6203	
3021	0	2	6203	
3022	0	3	6203	
3023	0	4	6203	
3024	0	5	6203	
3025	1	1	6203	
3026	1	2	6203	
3027	1	3	6203	
3028	1	4	6203	
3029	1	5	6203	
3030	2	1	6203	
3031	2	2	6203	
3032	2	3	6203	
3033	2	4	6203	
3034	2	5	6203	
3035	3	1	6203	
3036	3	2	6203	
3037	3	3	6203	
3038	3	4	6203	
3039	3	5	6203	
3040	0	1	6204	
3041	0	2	6204	
3042	0	3	6204	
3043	0	4	6204	
3044	0	5	6204	
3045	1	1	6204	
3046	1	2	6204	
3047	1	3	6204	
3048	1	4	6204	
3049	1	5	6204	
3050	2	1	6204	
3051	2	2	6204	
3052	2	3	6204	
3053	2	4	6204	
3054	2	5	6204	
3055	3	1	6204	
3056	3	2	6204	
3057	3	3	6204	
3058	3	4	6204	
3059	3	5	6204	
3060	0	1	6205	
3061	0	2	6205	
3062	0	3	6205	
3063	0	4	6205	
3064	0	5	6205	
3065	1	1	6205	
3066	1	2	6205	
3067	1	3	6205	
3068	1	4	6205	
3069	1	5	6205	
3070	2	1	6205	
3071	2	2	6205	
3072	2	3	6205	
3073	2	4	6205	
3074	2	5	6205	
3075	3	1	6205	
3076	3	2	6205	
3077	3	3	6205	
3078	3	4	6205	
3079	3	5	6205	
3080	0	1	6206	
3081	0	2	6206	
3082	0	3	6206	
3083	0	4	6206	
3084	0	5	6206	
3085	1	1	6206	
3086	1	2	6206	
3087	1	3	6206	
3088	1	4	6206	
3089	1	5	6206	
3090	2	1	6206	
3091	2	2	6206	
3092	2	3	6206	
3093	2	4	6206	
3094	2	5	6206	
3095	3	1	6206	
3096	3	2	6206	
3097	3	3	6206	
3098	3	4	6206	
3099	3	5	6206	
3100	0	1	6207	
3101	0	2	6207	
3102	0	3	6207	
3103	0	4	6207	
3104	0	5	6207	
3105	1	1	6207	
3106	1	2	6207	
3107	1	3	6207	
3108	1	4	6207	
3109	1	5	6207	
3110	2	1	6207	
3111	2	2	6207	
3112	2	3	6207	
3113	2	4	6207	
3114	2	5	6207	
3115	3	1	6207	
3116	3	2	6207	
3117	3	3	6207	
3118	3	4	6207	
3119	3	5	6207	
3120	0	1	6208	
3121	0	2	6208	
3122	0	3	6208	
3123	0	4	6208	
3124	0	5	6208	
3125	1	1	6208	
3126	1	2	6208	
3127	1	3	6208	
3128	1	4	6208	
3129	1	5	6208	
3130	2	1	6208	
3131	2	2	6208	
3132	2	3	6208	
3133	2	4	6208	
3134	2	5	6208	
3135	3	1	6208	
3136	3	2	6208	
3137	3	3	6208	
3138	3	4	6208	
3139	3	5	6208	
3140	0	1	6209	
3141	0	2	6209	
3142	0	3	6209	
3143	0	4	6209	
3144	0	5	6209	
3145	1	1	6209	
3146	1	2	6209	
3147	1	3	6209	
3148	1	4	6209	
3149	1	5	6209	
3150	2	1	6209	
3151	2	2	6209	
3152	2	3	6209	
3153	2	4	6209	
3154	2	5	6209	
3155	3	1	6209	
3156	3	2	6209	
3157	3	3	6209	
3158	3	4	6209	
3159	3	5	6209	
3160	0	1	6214	
3161	0	2	6214	
3162	0	3	6214	
3163	0	4	6214	
3164	0	5	6214	
3165	1	1	6214	
3166	1	2	6214	
3167	1	3	6214	
3168	1	4	6214	
3169	1	5	6214	
3170	2	1	6214	
3171	2	2	6214	
3172	2	3	6214	
3173	2	4	6214	
3174	2	5	6214	
3175	3	1	6214	
3176	3	2	6214	
3177	3	3	6214	
3178	3	4	6214	
3179	3	5	6214	
3180	0	1	6301	
3181	0	2	6301	
3182	0	3	6301	
3183	0	4	6301	
3184	0	5	6301	
3185	1	1	6301	
3186	1	2	6301	
3187	1	3	6301	
3188	1	4	6301	
3189	1	5	6301	
3190	2	1	6301	
3191	2	2	6301	
3192	2	3	6301	
3193	2	4	6301	
3194	2	5	6301	
3195	3	1	6301	
3196	3	2	6301	
3197	3	3	6301	
3198	3	4	6301	
3199	3	5	6301	
3200	0	1	6302	
3201	0	2	6302	
3202	0	3	6302	
3203	0	4	6302	
3204	0	5	6302	
3205	1	1	6302	
3206	1	2	6302	
3207	1	3	6302	
3208	1	4	6302	
3209	1	5	6302	
3210	2	1	6302	
3211	2	2	6302	
3212	2	3	6302	
3213	2	4	6302	
3214	2	5	6302	
3215	3	1	6302	
3216	3	2	6302	
3217	3	3	6302	
3218	3	4	6302	
3219	3	5	6302	
3220	0	1	6303	
3221	0	2	6303	
3222	0	3	6303	
3223	0	4	6303	
3224	0	5	6303	
3225	1	1	6303	
3226	1	2	6303	
3227	1	3	6303	
3228	1	4	6303	
3229	1	5	6303	
3230	2	1	6303	
3231	2	2	6303	
3232	2	3	6303	
3233	2	4	6303	
3234	2	5	6303	
3235	3	1	6303	
3236	3	2	6303	
3237	3	3	6303	
3238	3	4	6303	
3239	3	5	6303	
3240	0	1	6304	
3241	0	2	6304	
3242	0	3	6304	
3243	0	4	6304	
3244	0	5	6304	
3245	1	1	6304	
3246	1	2	6304	
3247	1	3	6304	
3248	1	4	6304	
3249	1	5	6304	
3250	2	1	6304	
3251	2	2	6304	
3252	2	3	6304	
3253	2	4	6304	
3254	2	5	6304	
3255	3	1	6304	
3256	3	2	6304	
3257	3	3	6304	
3258	3	4	6304	
3259	3	5	6304	
3260	0	1	6305	
3261	0	2	6305	
3262	0	3	6305	
3263	0	4	6305	
3264	0	5	6305	
3265	1	1	6305	
3266	1	2	6305	
3267	1	3	6305	
3268	1	4	6305	
3269	1	5	6305	
3270	2	1	6305	
3271	2	2	6305	
3272	2	3	6305	
3273	2	4	6305	
3274	2	5	6305	
3275	3	1	6305	
3276	3	2	6305	
3277	3	3	6305	
3278	3	4	6305	
3279	3	5	6305	
3280	0	1	6306	
3281	0	2	6306	
3282	0	3	6306	
3283	0	4	6306	
3284	0	5	6306	
3285	1	1	6306	
3286	1	2	6306	
3287	1	3	6306	
3288	1	4	6306	
3289	1	5	6306	
3290	2	1	6306	
3291	2	2	6306	
3292	2	3	6306	
3293	2	4	6306	
3294	2	5	6306	
3295	3	1	6306	
3296	3	2	6306	
3297	3	3	6306	
3298	3	4	6306	
3299	3	5	6306	
3300	0	1	7101	
3301	0	2	7101	
3302	0	3	7101	
3303	0	4	7101	
3304	0	5	7101	
3305	1	1	7101	
3306	1	2	7101	
3307	1	3	7101	
3308	1	4	7101	
3309	1	5	7101	
3310	2	1	7101	
3311	2	2	7101	
3312	2	3	7101	
3313	2	4	7101	
3314	2	5	7101	
3315	3	1	7101	
3316	3	2	7101	
3317	3	3	7101	
3318	3	4	7101	
3319	3	5	7101	
3320	0	1	7102	
3321	0	2	7102	
3322	0	3	7102	
3323	0	4	7102	
3324	0	5	7102	
3325	1	1	7102	
3326	1	2	7102	
3327	1	3	7102	
3328	1	4	7102	
3329	1	5	7102	
3330	2	1	7102	
3331	2	2	7102	
3332	2	3	7102	
3333	2	4	7102	
3334	2	5	7102	
3335	3	1	7102	
3336	3	2	7102	
3337	3	3	7102	
3338	3	4	7102	
3339	3	5	7102	
3340	0	1	7103	
3341	0	2	7103	
3342	0	3	7103	
3343	0	4	7103	
3344	0	5	7103	
3345	1	1	7103	
3346	1	2	7103	
3347	1	3	7103	
3348	1	4	7103	
3349	1	5	7103	
3350	2	1	7103	
3351	2	2	7103	
3352	2	3	7103	
3353	2	4	7103	
3354	2	5	7103	
3355	3	1	7103	
3356	3	2	7103	
3357	3	3	7103	
3358	3	4	7103	
3359	3	5	7103	
3360	0	1	7104	
3361	0	2	7104	
3362	0	3	7104	
3363	0	4	7104	
3364	0	5	7104	
3365	1	1	7104	
3366	1	2	7104	
3367	1	3	7104	
3368	1	4	7104	
3369	1	5	7104	
3370	2	1	7104	
3371	2	2	7104	
3372	2	3	7104	
3373	2	4	7104	
3374	2	5	7104	
3375	3	1	7104	
3376	3	2	7104	
3377	3	3	7104	
3378	3	4	7104	
3379	3	5	7104	
3380	0	1	7105	
3381	0	2	7105	
3382	0	3	7105	
3383	0	4	7105	
3384	0	5	7105	
3385	1	1	7105	
3386	1	2	7105	
3387	1	3	7105	
3388	1	4	7105	
3389	1	5	7105	
3390	2	1	7105	
3391	2	2	7105	
3392	2	3	7105	
3393	2	4	7105	
3394	2	5	7105	
3395	3	1	7105	
3396	3	2	7105	
3397	3	3	7105	
3398	3	4	7105	
3399	3	5	7105	
3400	0	1	7106	
3401	0	2	7106	
3402	0	3	7106	
3403	0	4	7106	
3404	0	5	7106	
3405	1	1	7106	
3406	1	2	7106	
3407	1	3	7106	
3408	1	4	7106	
3409	1	5	7106	
3410	2	1	7106	
3411	2	2	7106	
3412	2	3	7106	
3413	2	4	7106	
3414	2	5	7106	
3415	3	1	7106	
3416	3	2	7106	
3417	3	3	7106	
3418	3	4	7106	
3419	3	5	7106	
3420	0	1	7107	
3421	0	2	7107	
3422	0	3	7107	
3423	0	4	7107	
3424	0	5	7107	
3425	1	1	7107	
3426	1	2	7107	
3427	1	3	7107	
3428	1	4	7107	
3429	1	5	7107	
3430	2	1	7107	
3431	2	2	7107	
3432	2	3	7107	
3433	2	4	7107	
3434	2	5	7107	
3435	3	1	7107	
3436	3	2	7107	
3437	3	3	7107	
3438	3	4	7107	
3439	3	5	7107	
3440	0	1	7108	
3441	0	2	7108	
3442	0	3	7108	
3443	0	4	7108	
3444	0	5	7108	
3445	1	1	7108	
3446	1	2	7108	
3447	1	3	7108	
3448	1	4	7108	
3449	1	5	7108	
3450	2	1	7108	
3451	2	2	7108	
3452	2	3	7108	
3453	2	4	7108	
3454	2	5	7108	
3455	3	1	7108	
3456	3	2	7108	
3457	3	3	7108	
3458	3	4	7108	
3459	3	5	7108	
3460	0	1	7109	
3461	0	2	7109	
3462	0	3	7109	
3463	0	4	7109	
3464	0	5	7109	
3465	1	1	7109	
3466	1	2	7109	
3467	1	3	7109	
3468	1	4	7109	
3469	1	5	7109	
3470	2	1	7109	
3471	2	2	7109	
3472	2	3	7109	
3473	2	4	7109	
3474	2	5	7109	
3475	3	1	7109	
3476	3	2	7109	
3477	3	3	7109	
3478	3	4	7109	
3479	3	5	7109	
3480	0	1	7201	
3481	0	2	7201	
3482	0	3	7201	
3483	0	4	7201	
3484	0	5	7201	
3485	1	1	7201	
3486	1	2	7201	
3487	1	3	7201	
3488	1	4	7201	
3489	1	5	7201	
3490	2	1	7201	
3491	2	2	7201	
3492	2	3	7201	
3493	2	4	7201	
3494	2	5	7201	
3495	3	1	7201	
3496	3	2	7201	
3497	3	3	7201	
3498	3	4	7201	
3499	3	5	7201	
3500	0	1	7202	
3501	0	2	7202	
3502	0	3	7202	
3503	0	4	7202	
3504	0	5	7202	
3505	1	1	7202	
3506	1	2	7202	
3507	1	3	7202	
3508	1	4	7202	
3509	1	5	7202	
3510	2	1	7202	
3511	2	2	7202	
3512	2	3	7202	
3513	2	4	7202	
3514	2	5	7202	
3515	3	1	7202	
3516	3	2	7202	
3517	3	3	7202	
3518	3	4	7202	
3519	3	5	7202	
3520	0	1	7203	
3521	0	2	7203	
3522	0	3	7203	
3523	0	4	7203	
3524	0	5	7203	
3525	1	1	7203	
3526	1	2	7203	
3527	1	3	7203	
3528	1	4	7203	
3529	1	5	7203	
3530	2	1	7203	
3531	2	2	7203	
3532	2	3	7203	
3533	2	4	7203	
3534	2	5	7203	
3535	3	1	7203	
3536	3	2	7203	
3537	3	3	7203	
3538	3	4	7203	
3539	3	5	7203	
3540	0	1	7204	
3541	0	2	7204	
3542	0	3	7204	
3543	0	4	7204	
3544	0	5	7204	
3545	1	1	7204	
3546	1	2	7204	
3547	1	3	7204	
3548	1	4	7204	
3549	1	5	7204	
3550	2	1	7204	
3551	2	2	7204	
3552	2	3	7204	
3553	2	4	7204	
3554	2	5	7204	
3555	3	1	7204	
3556	3	2	7204	
3557	3	3	7204	
3558	3	4	7204	
3559	3	5	7204	
3560	0	1	7205	
3561	0	2	7205	
3562	0	3	7205	
3563	0	4	7205	
3564	0	5	7205	
3565	1	1	7205	
3566	1	2	7205	
3567	1	3	7205	
3568	1	4	7205	
3569	1	5	7205	
3570	2	1	7205	
3571	2	2	7205	
3572	2	3	7205	
3573	2	4	7205	
3574	2	5	7205	
3575	3	1	7205	
3576	3	2	7205	
3577	3	3	7205	
3578	3	4	7205	
3579	3	5	7205	
3580	0	1	7206	
3581	0	2	7206	
3582	0	3	7206	
3583	0	4	7206	
3584	0	5	7206	
3585	1	1	7206	
3586	1	2	7206	
3587	1	3	7206	
3588	1	4	7206	
3589	1	5	7206	
3590	2	1	7206	
3591	2	2	7206	
3592	2	3	7206	
3593	2	4	7206	
3594	2	5	7206	
3595	3	1	7206	
3596	3	2	7206	
3597	3	3	7206	
3598	3	4	7206	
3599	3	5	7206	
3600	0	1	7207	
3601	0	2	7207	
3602	0	3	7207	
3603	0	4	7207	
3604	0	5	7207	
3605	1	1	7207	
3606	1	2	7207	
3607	1	3	7207	
3608	1	4	7207	
3609	1	5	7207	
3610	2	1	7207	
3611	2	2	7207	
3612	2	3	7207	
3613	2	4	7207	
3614	2	5	7207	
3615	3	1	7207	
3616	3	2	7207	
3617	3	3	7207	
3618	3	4	7207	
3619	3	5	7207	
3620	0	1	7208	
3621	0	2	7208	
3622	0	3	7208	
3623	0	4	7208	
3624	0	5	7208	
3625	1	1	7208	
3626	1	2	7208	
3627	1	3	7208	
3628	1	4	7208	
3629	1	5	7208	
3630	2	1	7208	
3631	2	2	7208	
3632	2	3	7208	
3633	2	4	7208	
3634	2	5	7208	
3635	3	1	7208	
3636	3	2	7208	
3637	3	3	7208	
3638	3	4	7208	
3639	3	5	7208	
3640	0	1	7209	
3641	0	2	7209	
3642	0	3	7209	
3643	0	4	7209	
3644	0	5	7209	
3645	1	1	7209	
3646	1	2	7209	
3647	1	3	7209	
3648	1	4	7209	
3649	1	5	7209	
3650	2	1	7209	
3651	2	2	7209	
3652	2	3	7209	
3653	2	4	7209	
3654	2	5	7209	
3655	3	1	7209	
3656	3	2	7209	
3657	3	3	7209	
3658	3	4	7209	
3659	3	5	7209	
3660	0	1	7210	
3661	0	2	7210	
3662	0	3	7210	
3663	0	4	7210	
3664	0	5	7210	
3665	1	1	7210	
3666	1	2	7210	
3667	1	3	7210	
3668	1	4	7210	
3669	1	5	7210	
3670	2	1	7210	
3671	2	2	7210	
3672	2	3	7210	
3673	2	4	7210	
3674	2	5	7210	
3675	3	1	7210	
3676	3	2	7210	
3677	3	3	7210	
3678	3	4	7210	
3679	3	5	7210	
3680	0	1	7301	
3681	0	2	7301	
3682	0	3	7301	
3683	0	4	7301	
3684	0	5	7301	
3685	1	1	7301	
3686	1	2	7301	
3687	1	3	7301	
3688	1	4	7301	
3689	1	5	7301	
3690	2	1	7301	
3691	2	2	7301	
3692	2	3	7301	
3693	2	4	7301	
3694	2	5	7301	
3695	3	1	7301	
3696	3	2	7301	
3697	3	3	7301	
3698	3	4	7301	
3699	3	5	7301	
3700	0	1	7302	
3701	0	2	7302	
3702	0	3	7302	
3703	0	4	7302	
3704	0	5	7302	
3705	1	1	7302	
3706	1	2	7302	
3707	1	3	7302	
3708	1	4	7302	
3709	1	5	7302	
3710	2	1	7302	
3711	2	2	7302	
3712	2	3	7302	
3713	2	4	7302	
3714	2	5	7302	
3715	3	1	7302	
3716	3	2	7302	
3717	3	3	7302	
3718	3	4	7302	
3719	3	5	7302	
3720	0	1	7303	
3721	0	2	7303	
3722	0	3	7303	
3723	0	4	7303	
3724	0	5	7303	
3725	1	1	7303	
3726	1	2	7303	
3727	1	3	7303	
3728	1	4	7303	
3729	1	5	7303	
3730	2	1	7303	
3731	2	2	7303	
3732	2	3	7303	
3733	2	4	7303	
3734	2	5	7303	
3735	3	1	7303	
3736	3	2	7303	
3737	3	3	7303	
3738	3	4	7303	
3739	3	5	7303	
3740	0	1	7304	
3741	0	2	7304	
3742	0	3	7304	
3743	0	4	7304	
3744	0	5	7304	
3745	1	1	7304	
3746	1	2	7304	
3747	1	3	7304	
3748	1	4	7304	
3749	1	5	7304	
3750	2	1	7304	
3751	2	2	7304	
3752	2	3	7304	
3753	2	4	7304	
3754	2	5	7304	
3755	3	1	7304	
3756	3	2	7304	
3757	3	3	7304	
3758	3	4	7304	
3759	3	5	7304	
3760	0	1	7305	
3761	0	2	7305	
3762	0	3	7305	
3763	0	4	7305	
3764	0	5	7305	
3765	1	1	7305	
3766	1	2	7305	
3767	1	3	7305	
3768	1	4	7305	
3769	1	5	7305	
3770	2	1	7305	
3771	2	2	7305	
3772	2	3	7305	
3773	2	4	7305	
3774	2	5	7305	
3775	3	1	7305	
3776	3	2	7305	
3777	3	3	7305	
3778	3	4	7305	
3779	3	5	7305	
3780	0	1	7306	
3781	0	2	7306	
3782	0	3	7306	
3783	0	4	7306	
3784	0	5	7306	
3785	1	1	7306	
3786	1	2	7306	
3787	1	3	7306	
3788	1	4	7306	
3789	1	5	7306	
3790	2	1	7306	
3791	2	2	7306	
3792	2	3	7306	
3793	2	4	7306	
3794	2	5	7306	
3795	3	1	7306	
3796	3	2	7306	
3797	3	3	7306	
3798	3	4	7306	
3799	3	5	7306	
3800	0	1	7309	
3801	0	2	7309	
3802	0	3	7309	
3803	0	4	7309	
3804	0	5	7309	
3805	1	1	7309	
3806	1	2	7309	
3807	1	3	7309	
3808	1	4	7309	
3809	1	5	7309	
3810	2	1	7309	
3811	2	2	7309	
3812	2	3	7309	
3813	2	4	7309	
3814	2	5	7309	
3815	3	1	7309	
3816	3	2	7309	
3817	3	3	7309	
3818	3	4	7309	
3819	3	5	7309	
3820	0	1	7310	
3821	0	2	7310	
3822	0	3	7310	
3823	0	4	7310	
3824	0	5	7310	
3825	1	1	7310	
3826	1	2	7310	
3827	1	3	7310	
3828	1	4	7310	
3829	1	5	7310	
3830	2	1	7310	
3831	2	2	7310	
3832	2	3	7310	
3833	2	4	7310	
3834	2	5	7310	
3835	3	1	7310	
3836	3	2	7310	
3837	3	3	7310	
3838	3	4	7310	
3839	3	5	7310	
3840	0	1	7401	
3841	0	2	7401	
3842	0	3	7401	
3843	0	4	7401	
3844	0	5	7401	
3845	1	1	7401	
3846	1	2	7401	
3847	1	3	7401	
3848	1	4	7401	
3849	1	5	7401	
3850	2	1	7401	
3851	2	2	7401	
3852	2	3	7401	
3853	2	4	7401	
3854	2	5	7401	
3855	3	1	7401	
3856	3	2	7401	
3857	3	3	7401	
3858	3	4	7401	
3859	3	5	7401	
3860	0	1	7402	
3861	0	2	7402	
3862	0	3	7402	
3863	0	4	7402	
3864	0	5	7402	
3865	1	1	7402	
3866	1	2	7402	
3867	1	3	7402	
3868	1	4	7402	
3869	1	5	7402	
3870	2	1	7402	
3871	2	2	7402	
3872	2	3	7402	
3873	2	4	7402	
3874	2	5	7402	
3875	3	1	7402	
3876	3	2	7402	
3877	3	3	7402	
3878	3	4	7402	
3879	3	5	7402	
3880	0	1	7403	
3881	0	2	7403	
3882	0	3	7403	
3883	0	4	7403	
3884	0	5	7403	
3885	1	1	7403	
3886	1	2	7403	
3887	1	3	7403	
3888	1	4	7403	
3889	1	5	7403	
3890	2	1	7403	
3891	2	2	7403	
3892	2	3	7403	
3893	2	4	7403	
3894	2	5	7403	
3895	3	1	7403	
3896	3	2	7403	
3897	3	3	7403	
3898	3	4	7403	
3899	3	5	7403	
3900	0	1	8101	
3901	0	2	8101	
3902	0	3	8101	
3903	0	4	8101	
3904	0	5	8101	
3905	1	1	8101	
3906	1	2	8101	
3907	1	3	8101	
3908	1	4	8101	
3909	1	5	8101	
3910	2	1	8101	
3911	2	2	8101	
3912	2	3	8101	
3913	2	4	8101	
3914	2	5	8101	
3915	3	1	8101	
3916	3	2	8101	
3917	3	3	8101	
3918	3	4	8101	
3919	3	5	8101	
3920	0	1	8102	
3921	0	2	8102	
3922	0	3	8102	
3923	0	4	8102	
3924	0	5	8102	
3925	1	1	8102	
3926	1	2	8102	
3927	1	3	8102	
3928	1	4	8102	
3929	1	5	8102	
3930	2	1	8102	
3931	2	2	8102	
3932	2	3	8102	
3933	2	4	8102	
3934	2	5	8102	
3935	3	1	8102	
3936	3	2	8102	
3937	3	3	8102	
3938	3	4	8102	
3939	3	5	8102	
3940	0	1	8103	
3941	0	2	8103	
3942	0	3	8103	
3943	0	4	8103	
3944	0	5	8103	
3945	1	1	8103	
3946	1	2	8103	
3947	1	3	8103	
3948	1	4	8103	
3949	1	5	8103	
3950	2	1	8103	
3951	2	2	8103	
3952	2	3	8103	
3953	2	4	8103	
3954	2	5	8103	
3955	3	1	8103	
3956	3	2	8103	
3957	3	3	8103	
3958	3	4	8103	
3959	3	5	8103	
3960	0	1	8104	
3961	0	2	8104	
3962	0	3	8104	
3963	0	4	8104	
3964	0	5	8104	
3965	1	1	8104	
3966	1	2	8104	
3967	1	3	8104	
3968	1	4	8104	
3969	1	5	8104	
3970	2	1	8104	
3971	2	2	8104	
3972	2	3	8104	
3973	2	4	8104	
3974	2	5	8104	
3975	3	1	8104	
3976	3	2	8104	
3977	3	3	8104	
3978	3	4	8104	
3979	3	5	8104	
3980	0	1	8105	
3981	0	2	8105	
3982	0	3	8105	
3983	0	4	8105	
3984	0	5	8105	
3985	1	1	8105	
3986	1	2	8105	
3987	1	3	8105	
3988	1	4	8105	
3989	1	5	8105	
3990	2	1	8105	
3991	2	2	8105	
3992	2	3	8105	
3993	2	4	8105	
3994	2	5	8105	
3995	3	1	8105	
3996	3	2	8105	
3997	3	3	8105	
3998	3	4	8105	
3999	3	5	8105	
4000	0	1	8106	
4001	0	2	8106	
4002	0	3	8106	
4003	0	4	8106	
4004	0	5	8106	
4005	1	1	8106	
4006	1	2	8106	
4007	1	3	8106	
4008	1	4	8106	
4009	1	5	8106	
4010	2	1	8106	
4011	2	2	8106	
4012	2	3	8106	
4013	2	4	8106	
4014	2	5	8106	
4015	3	1	8106	
4016	3	2	8106	
4017	3	3	8106	
4018	3	4	8106	
4019	3	5	8106	
4020	0	1	8107	
4021	0	2	8107	
4022	0	3	8107	
4023	0	4	8107	
4024	0	5	8107	
4025	1	1	8107	
4026	1	2	8107	
4027	1	3	8107	
4028	1	4	8107	
4029	1	5	8107	
4030	2	1	8107	
4031	2	2	8107	
4032	2	3	8107	
4033	2	4	8107	
4034	2	5	8107	
4035	3	1	8107	
4036	3	2	8107	
4037	3	3	8107	
4038	3	4	8107	
4039	3	5	8107	
4040	0	1	8108	
4041	0	2	8108	
4042	0	3	8108	
4043	0	4	8108	
4044	0	5	8108	
4045	1	1	8108	
4046	1	2	8108	
4047	1	3	8108	
4048	1	4	8108	
4049	1	5	8108	
4050	2	1	8108	
4051	2	2	8108	
4052	2	3	8108	
4053	2	4	8108	
4054	2	5	8108	
4055	3	1	8108	
4056	3	2	8108	
4057	3	3	8108	
4058	3	4	8108	
4059	3	5	8108	
4060	0	1	8109	
4061	0	2	8109	
4062	0	3	8109	
4063	0	4	8109	
4064	0	5	8109	
4065	1	1	8109	
4066	1	2	8109	
4067	1	3	8109	
4068	1	4	8109	
4069	1	5	8109	
4070	2	1	8109	
4071	2	2	8109	
4072	2	3	8109	
4073	2	4	8109	
4074	2	5	8109	
4075	3	1	8109	
4076	3	2	8109	
4077	3	3	8109	
4078	3	4	8109	
4079	3	5	8109	
4080	0	1	8110	
4081	0	2	8110	
4082	0	3	8110	
4083	0	4	8110	
4084	0	5	8110	
4085	1	1	8110	
4086	1	2	8110	
4087	1	3	8110	
4088	1	4	8110	
4089	1	5	8110	
4090	2	1	8110	
4091	2	2	8110	
4092	2	3	8110	
4093	2	4	8110	
4094	2	5	8110	
4095	3	1	8110	
4096	3	2	8110	
4097	3	3	8110	
4098	3	4	8110	
4099	3	5	8110	
4100	0	1	8111	
4101	0	2	8111	
4102	0	3	8111	
4103	0	4	8111	
4104	0	5	8111	
4105	1	1	8111	
4106	1	2	8111	
4107	1	3	8111	
4108	1	4	8111	
4109	1	5	8111	
4110	2	1	8111	
4111	2	2	8111	
4112	2	3	8111	
4113	2	4	8111	
4114	2	5	8111	
4115	3	1	8111	
4116	3	2	8111	
4117	3	3	8111	
4118	3	4	8111	
4119	3	5	8111	
4120	0	1	8112	
4121	0	2	8112	
4122	0	3	8112	
4123	0	4	8112	
4124	0	5	8112	
4125	1	1	8112	
4126	1	2	8112	
4127	1	3	8112	
4128	1	4	8112	
4129	1	5	8112	
4130	2	1	8112	
4131	2	2	8112	
4132	2	3	8112	
4133	2	4	8112	
4134	2	5	8112	
4135	3	1	8112	
4136	3	2	8112	
4137	3	3	8112	
4138	3	4	8112	
4139	3	5	8112	
4140	0	1	8113	
4141	0	2	8113	
4142	0	3	8113	
4143	0	4	8113	
4144	0	5	8113	
4145	1	1	8113	
4146	1	2	8113	
4147	1	3	8113	
4148	1	4	8113	
4149	1	5	8113	
4150	2	1	8113	
4151	2	2	8113	
4152	2	3	8113	
4153	2	4	8113	
4154	2	5	8113	
4155	3	1	8113	
4156	3	2	8113	
4157	3	3	8113	
4158	3	4	8113	
4159	3	5	8113	
4160	0	1	8114	
4161	0	2	8114	
4162	0	3	8114	
4163	0	4	8114	
4164	0	5	8114	
4165	1	1	8114	
4166	1	2	8114	
4167	1	3	8114	
4168	1	4	8114	
4169	1	5	8114	
4170	2	1	8114	
4171	2	2	8114	
4172	2	3	8114	
4173	2	4	8114	
4174	2	5	8114	
4175	3	1	8114	
4176	3	2	8114	
4177	3	3	8114	
4178	3	4	8114	
4179	3	5	8114	
4180	0	1	8115	
4181	0	2	8115	
4182	0	3	8115	
4183	0	4	8115	
4184	0	5	8115	
4185	1	1	8115	
4186	1	2	8115	
4187	1	3	8115	
4188	1	4	8115	
4189	1	5	8115	
4190	2	1	8115	
4191	2	2	8115	
4192	2	3	8115	
4193	2	4	8115	
4194	2	5	8115	
4195	3	1	8115	
4196	3	2	8115	
4197	3	3	8115	
4198	3	4	8115	
4199	3	5	8115	
4200	0	1	8116	
4201	0	2	8116	
4202	0	3	8116	
4203	0	4	8116	
4204	0	5	8116	
4205	1	1	8116	
4206	1	2	8116	
4207	1	3	8116	
4208	1	4	8116	
4209	1	5	8116	
4210	2	1	8116	
4211	2	2	8116	
4212	2	3	8116	
4213	2	4	8116	
4214	2	5	8116	
4215	3	1	8116	
4216	3	2	8116	
4217	3	3	8116	
4218	3	4	8116	
4219	3	5	8116	
4220	0	1	8117	
4221	0	2	8117	
4222	0	3	8117	
4223	0	4	8117	
4224	0	5	8117	
4225	1	1	8117	
4226	1	2	8117	
4227	1	3	8117	
4228	1	4	8117	
4229	1	5	8117	
4230	2	1	8117	
4231	2	2	8117	
4232	2	3	8117	
4233	2	4	8117	
4234	2	5	8117	
4235	3	1	8117	
4236	3	2	8117	
4237	3	3	8117	
4238	3	4	8117	
4239	3	5	8117	
4240	0	1	8118	
4241	0	2	8118	
4242	0	3	8118	
4243	0	4	8118	
4244	0	5	8118	
4245	1	1	8118	
4246	1	2	8118	
4247	1	3	8118	
4248	1	4	8118	
4249	1	5	8118	
4250	2	1	8118	
4251	2	2	8118	
4252	2	3	8118	
4253	2	4	8118	
4254	2	5	8118	
4255	3	1	8118	
4256	3	2	8118	
4257	3	3	8118	
4258	3	4	8118	
4259	3	5	8118	
4260	0	1	8119	
4261	0	2	8119	
4262	0	3	8119	
4263	0	4	8119	
4264	0	5	8119	
4265	1	1	8119	
4266	1	2	8119	
4267	1	3	8119	
4268	1	4	8119	
4269	1	5	8119	
4270	2	1	8119	
4271	2	2	8119	
4272	2	3	8119	
4273	2	4	8119	
4274	2	5	8119	
4275	3	1	8119	
4276	3	2	8119	
4277	3	3	8119	
4278	3	4	8119	
4279	3	5	8119	
4280	0	1	8120	
4281	0	2	8120	
4282	0	3	8120	
4283	0	4	8120	
4284	0	5	8120	
4285	1	1	8120	
4286	1	2	8120	
4287	1	3	8120	
4288	1	4	8120	
4289	1	5	8120	
4290	2	1	8120	
4291	2	2	8120	
4292	2	3	8120	
4293	2	4	8120	
4294	2	5	8120	
4295	3	1	8120	
4296	3	2	8120	
4297	3	3	8120	
4298	3	4	8120	
4299	3	5	8120	
4300	0	1	8121	
4301	0	2	8121	
4302	0	3	8121	
4303	0	4	8121	
4304	0	5	8121	
4305	1	1	8121	
4306	1	2	8121	
4307	1	3	8121	
4308	1	4	8121	
4309	1	5	8121	
4310	2	1	8121	
4311	2	2	8121	
4312	2	3	8121	
4313	2	4	8121	
4314	2	5	8121	
4315	3	1	8121	
4316	3	2	8121	
4317	3	3	8121	
4318	3	4	8121	
4319	3	5	8121	
4320	0	1	8201	
4321	0	2	8201	
4322	0	3	8201	
4323	0	4	8201	
4324	0	5	8201	
4325	1	1	8201	
4326	1	2	8201	
4327	1	3	8201	
4328	1	4	8201	
4329	1	5	8201	
4330	2	1	8201	
4331	2	2	8201	
4332	2	3	8201	
4333	2	4	8201	
4334	2	5	8201	
4335	3	1	8201	
4336	3	2	8201	
4337	3	3	8201	
4338	3	4	8201	
4339	3	5	8201	
4340	0	1	8202	
4341	0	2	8202	
4342	0	3	8202	
4343	0	4	8202	
4344	0	5	8202	
4345	1	1	8202	
4346	1	2	8202	
4347	1	3	8202	
4348	1	4	8202	
4349	1	5	8202	
4350	2	1	8202	
4351	2	2	8202	
4352	2	3	8202	
4353	2	4	8202	
4354	2	5	8202	
4355	3	1	8202	
4356	3	2	8202	
4357	3	3	8202	
4358	3	4	8202	
4359	3	5	8202	
4360	0	1	8203	
4361	0	2	8203	
4362	0	3	8203	
4363	0	4	8203	
4364	0	5	8203	
4365	1	1	8203	
4366	1	2	8203	
4367	1	3	8203	
4368	1	4	8203	
4369	1	5	8203	
4370	2	1	8203	
4371	2	2	8203	
4372	2	3	8203	
4373	2	4	8203	
4374	2	5	8203	
4375	3	1	8203	
4376	3	2	8203	
4377	3	3	8203	
4378	3	4	8203	
4379	3	5	8203	
4380	0	1	8204	
4381	0	2	8204	
4382	0	3	8204	
4383	0	4	8204	
4384	0	5	8204	
4385	1	1	8204	
4386	1	2	8204	
4387	1	3	8204	
4388	1	4	8204	
4389	1	5	8204	
4390	2	1	8204	
4391	2	2	8204	
4392	2	3	8204	
4393	2	4	8204	
4394	2	5	8204	
4395	3	1	8204	
4396	3	2	8204	
4397	3	3	8204	
4398	3	4	8204	
4399	3	5	8204	
4400	0	1	8205	
4401	0	2	8205	
4402	0	3	8205	
4403	0	4	8205	
4404	0	5	8205	
4405	1	1	8205	
4406	1	2	8205	
4407	1	3	8205	
4408	1	4	8205	
4409	1	5	8205	
4410	2	1	8205	
4411	2	2	8205	
4412	2	3	8205	
4413	2	4	8205	
4414	2	5	8205	
4415	3	1	8205	
4416	3	2	8205	
4417	3	3	8205	
4418	3	4	8205	
4419	3	5	8205	
4420	0	1	8206	
4421	0	2	8206	
4422	0	3	8206	
4423	0	4	8206	
4424	0	5	8206	
4425	1	1	8206	
4426	1	2	8206	
4427	1	3	8206	
4428	1	4	8206	
4429	1	5	8206	
4430	2	1	8206	
4431	2	2	8206	
4432	2	3	8206	
4433	2	4	8206	
4434	2	5	8206	
4435	3	1	8206	
4436	3	2	8206	
4437	3	3	8206	
4438	3	4	8206	
4439	3	5	8206	
4440	0	1	8207	
4441	0	2	8207	
4442	0	3	8207	
4443	0	4	8207	
4444	0	5	8207	
4445	1	1	8207	
4446	1	2	8207	
4447	1	3	8207	
4448	1	4	8207	
4449	1	5	8207	
4450	2	1	8207	
4451	2	2	8207	
4452	2	3	8207	
4453	2	4	8207	
4454	2	5	8207	
4455	3	1	8207	
4456	3	2	8207	
4457	3	3	8207	
4458	3	4	8207	
4459	3	5	8207	
4460	0	1	8208	
4461	0	2	8208	
4462	0	3	8208	
4463	0	4	8208	
4464	0	5	8208	
4465	1	1	8208	
4466	1	2	8208	
4467	1	3	8208	
4468	1	4	8208	
4469	1	5	8208	
4470	2	1	8208	
4471	2	2	8208	
4472	2	3	8208	
4473	2	4	8208	
4474	2	5	8208	
4475	3	1	8208	
4476	3	2	8208	
4477	3	3	8208	
4478	3	4	8208	
4479	3	5	8208	
4480	0	1	8209	
4481	0	2	8209	
4482	0	3	8209	
4483	0	4	8209	
4484	0	5	8209	
4485	1	1	8209	
4486	1	2	8209	
4487	1	3	8209	
4488	1	4	8209	
4489	1	5	8209	
4490	2	1	8209	
4491	2	2	8209	
4492	2	3	8209	
4493	2	4	8209	
4494	2	5	8209	
4495	3	1	8209	
4496	3	2	8209	
4497	3	3	8209	
4498	3	4	8209	
4499	3	5	8209	
4500	0	1	8210	
4501	0	2	8210	
4502	0	3	8210	
4503	0	4	8210	
4504	0	5	8210	
4505	1	1	8210	
4506	1	2	8210	
4507	1	3	8210	
4508	1	4	8210	
4509	1	5	8210	
4510	2	1	8210	
4511	2	2	8210	
4512	2	3	8210	
4513	2	4	8210	
4514	2	5	8210	
4515	3	1	8210	
4516	3	2	8210	
4517	3	3	8210	
4518	3	4	8210	
4519	3	5	8210	
4520	0	1	8211	
4521	0	2	8211	
4522	0	3	8211	
4523	0	4	8211	
4524	0	5	8211	
4525	1	1	8211	
4526	1	2	8211	
4527	1	3	8211	
4528	1	4	8211	
4529	1	5	8211	
4530	2	1	8211	
4531	2	2	8211	
4532	2	3	8211	
4533	2	4	8211	
4534	2	5	8211	
4535	3	1	8211	
4536	3	2	8211	
4537	3	3	8211	
4538	3	4	8211	
4539	3	5	8211	
4540	0	1	8212	
4541	0	2	8212	
4542	0	3	8212	
4543	0	4	8212	
4544	0	5	8212	
4545	1	1	8212	
4546	1	2	8212	
4547	1	3	8212	
4548	1	4	8212	
4549	1	5	8212	
4550	2	1	8212	
4551	2	2	8212	
4552	2	3	8212	
4553	2	4	8212	
4554	2	5	8212	
4555	3	1	8212	
4556	3	2	8212	
4557	3	3	8212	
4558	3	4	8212	
4559	3	5	8212	
4560	0	1	8301	
4561	0	2	8301	
4562	0	3	8301	
4563	0	4	8301	
4564	0	5	8301	
4565	1	1	8301	
4566	1	2	8301	
4567	1	3	8301	
4568	1	4	8301	
4569	1	5	8301	
4570	2	1	8301	
4571	2	2	8301	
4572	2	3	8301	
4573	2	4	8301	
4574	2	5	8301	
4575	3	1	8301	
4576	3	2	8301	
4577	3	3	8301	
4578	3	4	8301	
4579	3	5	8301	
4580	0	1	8302	
4581	0	2	8302	
4582	0	3	8302	
4583	0	4	8302	
4584	0	5	8302	
4585	1	1	8302	
4586	1	2	8302	
4587	1	3	8302	
4588	1	4	8302	
4589	1	5	8302	
4590	2	1	8302	
4591	2	2	8302	
4592	2	3	8302	
4593	2	4	8302	
4594	2	5	8302	
4595	3	1	8302	
4596	3	2	8302	
4597	3	3	8302	
4598	3	4	8302	
4599	3	5	8302	
4600	0	1	8303	
4601	0	2	8303	
4602	0	3	8303	
4603	0	4	8303	
4604	0	5	8303	
4605	1	1	8303	
4606	1	2	8303	
4607	1	3	8303	
4608	1	4	8303	
4609	1	5	8303	
4610	2	1	8303	
4611	2	2	8303	
4612	2	3	8303	
4613	2	4	8303	
4614	2	5	8303	
4615	3	1	8303	
4616	3	2	8303	
4617	3	3	8303	
4618	3	4	8303	
4619	3	5	8303	
4620	0	1	8304	
4621	0	2	8304	
4622	0	3	8304	
4623	0	4	8304	
4624	0	5	8304	
4625	1	1	8304	
4626	1	2	8304	
4627	1	3	8304	
4628	1	4	8304	
4629	1	5	8304	
4630	2	1	8304	
4631	2	2	8304	
4632	2	3	8304	
4633	2	4	8304	
4634	2	5	8304	
4635	3	1	8304	
4636	3	2	8304	
4637	3	3	8304	
4638	3	4	8304	
4639	3	5	8304	
4640	0	1	8305	
4641	0	2	8305	
4642	0	3	8305	
4643	0	4	8305	
4644	0	5	8305	
4645	1	1	8305	
4646	1	2	8305	
4647	1	3	8305	
4648	1	4	8305	
4649	1	5	8305	
4650	2	1	8305	
4651	2	2	8305	
4652	2	3	8305	
4653	2	4	8305	
4654	2	5	8305	
4655	3	1	8305	
4656	3	2	8305	
4657	3	3	8305	
4658	3	4	8305	
4659	3	5	8305	
4660	0	1	8306	
4661	0	2	8306	
4662	0	3	8306	
4663	0	4	8306	
4664	0	5	8306	
4665	1	1	8306	
4666	1	2	8306	
4667	1	3	8306	
4668	1	4	8306	
4669	1	5	8306	
4670	2	1	8306	
4671	2	2	8306	
4672	2	3	8306	
4673	2	4	8306	
4674	2	5	8306	
4675	3	1	8306	
4676	3	2	8306	
4677	3	3	8306	
4678	3	4	8306	
4679	3	5	8306	
4680	0	1	8307	
4681	0	2	8307	
4682	0	3	8307	
4683	0	4	8307	
4684	0	5	8307	
4685	1	1	8307	
4686	1	2	8307	
4687	1	3	8307	
4688	1	4	8307	
4689	1	5	8307	
4690	2	1	8307	
4691	2	2	8307	
4692	2	3	8307	
4693	2	4	8307	
4694	2	5	8307	
4695	3	1	8307	
4696	3	2	8307	
4697	3	3	8307	
4698	3	4	8307	
4699	3	5	8307	
4700	0	1	8401	
4701	0	2	8401	
4702	0	3	8401	
4703	0	4	8401	
4704	0	5	8401	
4705	1	1	8401	
4706	1	2	8401	
4707	1	3	8401	
4708	1	4	8401	
4709	1	5	8401	
4710	2	1	8401	
4711	2	2	8401	
4712	2	3	8401	
4713	2	4	8401	
4714	2	5	8401	
4715	3	1	8401	
4716	3	2	8401	
4717	3	3	8401	
4718	3	4	8401	
4719	3	5	8401	
4720	0	1	8402	
4721	0	2	8402	
4722	0	3	8402	
4723	0	4	8402	
4724	0	5	8402	
4725	1	1	8402	
4726	1	2	8402	
4727	1	3	8402	
4728	1	4	8402	
4729	1	5	8402	
4730	2	1	8402	
4731	2	2	8402	
4732	2	3	8402	
4733	2	4	8402	
4734	2	5	8402	
4735	3	1	8402	
4736	3	2	8402	
4737	3	3	8402	
4738	3	4	8402	
4739	3	5	8402	
4740	0	1	8403	
4741	0	2	8403	
4742	0	3	8403	
4743	0	4	8403	
4744	0	5	8403	
4745	1	1	8403	
4746	1	2	8403	
4747	1	3	8403	
4748	1	4	8403	
4749	1	5	8403	
4750	2	1	8403	
4751	2	2	8403	
4752	2	3	8403	
4753	2	4	8403	
4754	2	5	8403	
4755	3	1	8403	
4756	3	2	8403	
4757	3	3	8403	
4758	3	4	8403	
4759	3	5	8403	
4760	0	1	8404	
4761	0	2	8404	
4762	0	3	8404	
4763	0	4	8404	
4764	0	5	8404	
4765	1	1	8404	
4766	1	2	8404	
4767	1	3	8404	
4768	1	4	8404	
4769	1	5	8404	
4770	2	1	8404	
4771	2	2	8404	
4772	2	3	8404	
4773	2	4	8404	
4774	2	5	8404	
4775	3	1	8404	
4776	3	2	8404	
4777	3	3	8404	
4778	3	4	8404	
4779	3	5	8404	
4780	0	1	8405	
4781	0	2	8405	
4782	0	3	8405	
4783	0	4	8405	
4784	0	5	8405	
4785	1	1	8405	
4786	1	2	8405	
4787	1	3	8405	
4788	1	4	8405	
4789	1	5	8405	
4790	2	1	8405	
4791	2	2	8405	
4792	2	3	8405	
4793	2	4	8405	
4794	2	5	8405	
4795	3	1	8405	
4796	3	2	8405	
4797	3	3	8405	
4798	3	4	8405	
4799	3	5	8405	
4800	0	1	8406	
4801	0	2	8406	
4802	0	3	8406	
4803	0	4	8406	
4804	0	5	8406	
4805	1	1	8406	
4806	1	2	8406	
4807	1	3	8406	
4808	1	4	8406	
4809	1	5	8406	
4810	2	1	8406	
4811	2	2	8406	
4812	2	3	8406	
4813	2	4	8406	
4814	2	5	8406	
4815	3	1	8406	
4816	3	2	8406	
4817	3	3	8406	
4818	3	4	8406	
4819	3	5	8406	
4820	0	1	8407	
4821	0	2	8407	
4822	0	3	8407	
4823	0	4	8407	
4824	0	5	8407	
4825	1	1	8407	
4826	1	2	8407	
4827	1	3	8407	
4828	1	4	8407	
4829	1	5	8407	
4830	2	1	8407	
4831	2	2	8407	
4832	2	3	8407	
4833	2	4	8407	
4834	2	5	8407	
4835	3	1	8407	
4836	3	2	8407	
4837	3	3	8407	
4838	3	4	8407	
4839	3	5	8407	
4840	0	1	8408	
4841	0	2	8408	
4842	0	3	8408	
4843	0	4	8408	
4844	0	5	8408	
4845	1	1	8408	
4846	1	2	8408	
4847	1	3	8408	
4848	1	4	8408	
4849	1	5	8408	
4850	2	1	8408	
4851	2	2	8408	
4852	2	3	8408	
4853	2	4	8408	
4854	2	5	8408	
4855	3	1	8408	
4856	3	2	8408	
4857	3	3	8408	
4858	3	4	8408	
4859	3	5	8408	
4860	0	1	8409	
4861	0	2	8409	
4862	0	3	8409	
4863	0	4	8409	
4864	0	5	8409	
4865	1	1	8409	
4866	1	2	8409	
4867	1	3	8409	
4868	1	4	8409	
4869	1	5	8409	
4870	2	1	8409	
4871	2	2	8409	
4872	2	3	8409	
4873	2	4	8409	
4874	2	5	8409	
4875	3	1	8409	
4876	3	2	8409	
4877	3	3	8409	
4878	3	4	8409	
4879	3	5	8409	
4880	0	1	8410	
4881	0	2	8410	
4882	0	3	8410	
4883	0	4	8410	
4884	0	5	8410	
4885	1	1	8410	
4886	1	2	8410	
4887	1	3	8410	
4888	1	4	8410	
4889	1	5	8410	
4890	2	1	8410	
4891	2	2	8410	
4892	2	3	8410	
4893	2	4	8410	
4894	2	5	8410	
4895	3	1	8410	
4896	3	2	8410	
4897	3	3	8410	
4898	3	4	8410	
4899	3	5	8410	
4900	0	1	8411	
4901	0	2	8411	
4902	0	3	8411	
4903	0	4	8411	
4904	0	5	8411	
4905	1	1	8411	
4906	1	2	8411	
4907	1	3	8411	
4908	1	4	8411	
4909	1	5	8411	
4910	2	1	8411	
4911	2	2	8411	
4912	2	3	8411	
4913	2	4	8411	
4914	2	5	8411	
4915	3	1	8411	
4916	3	2	8411	
4917	3	3	8411	
4918	3	4	8411	
4919	3	5	8411	
4920	0	1	8412	
4921	0	2	8412	
4922	0	3	8412	
4923	0	4	8412	
4924	0	5	8412	
4925	1	1	8412	
4926	1	2	8412	
4927	1	3	8412	
4928	1	4	8412	
4929	1	5	8412	
4930	2	1	8412	
4931	2	2	8412	
4932	2	3	8412	
4933	2	4	8412	
4934	2	5	8412	
4935	3	1	8412	
4936	3	2	8412	
4937	3	3	8412	
4938	3	4	8412	
4939	3	5	8412	
4940	0	1	8413	
4941	0	2	8413	
4942	0	3	8413	
4943	0	4	8413	
4944	0	5	8413	
4945	1	1	8413	
4946	1	2	8413	
4947	1	3	8413	
4948	1	4	8413	
4949	1	5	8413	
4950	2	1	8413	
4951	2	2	8413	
4952	2	3	8413	
4953	2	4	8413	
4954	2	5	8413	
4955	3	1	8413	
4956	3	2	8413	
4957	3	3	8413	
4958	3	4	8413	
4959	3	5	8413	
4960	0	1	8414	
4961	0	2	8414	
4962	0	3	8414	
4963	0	4	8414	
4964	0	5	8414	
4965	1	1	8414	
4966	1	2	8414	
4967	1	3	8414	
4968	1	4	8414	
4969	1	5	8414	
4970	2	1	8414	
4971	2	2	8414	
4972	2	3	8414	
4973	2	4	8414	
4974	2	5	8414	
4975	3	1	8414	
4976	3	2	8414	
4977	3	3	8414	
4978	3	4	8414	
4979	3	5	8414	
4980	0	1	9101	
4981	0	2	9101	
4982	0	3	9101	
4983	0	4	9101	
4984	0	5	9101	
4985	1	1	9101	
4986	1	2	9101	
4987	1	3	9101	
4988	1	4	9101	
4989	1	5	9101	
4990	2	1	9101	
4991	2	2	9101	
4992	2	3	9101	
4993	2	4	9101	
4994	2	5	9101	
4995	3	1	9101	
4996	3	2	9101	
4997	3	3	9101	
4998	3	4	9101	
4999	3	5	9101	
5000	0	1	9102	
5001	0	2	9102	
5002	0	3	9102	
5003	0	4	9102	
5004	0	5	9102	
5005	1	1	9102	
5006	1	2	9102	
5007	1	3	9102	
5008	1	4	9102	
5009	1	5	9102	
5010	2	1	9102	
5011	2	2	9102	
5012	2	3	9102	
5013	2	4	9102	
5014	2	5	9102	
5015	3	1	9102	
5016	3	2	9102	
5017	3	3	9102	
5018	3	4	9102	
5019	3	5	9102	
5020	0	1	9103	
5021	0	2	9103	
5022	0	3	9103	
5023	0	4	9103	
5024	0	5	9103	
5025	1	1	9103	
5026	1	2	9103	
5027	1	3	9103	
5028	1	4	9103	
5029	1	5	9103	
5030	2	1	9103	
5031	2	2	9103	
5032	2	3	9103	
5033	2	4	9103	
5034	2	5	9103	
5035	3	1	9103	
5036	3	2	9103	
5037	3	3	9103	
5038	3	4	9103	
5039	3	5	9103	
5040	0	1	9104	
5041	0	2	9104	
5042	0	3	9104	
5043	0	4	9104	
5044	0	5	9104	
5045	1	1	9104	
5046	1	2	9104	
5047	1	3	9104	
5048	1	4	9104	
5049	1	5	9104	
5050	2	1	9104	
5051	2	2	9104	
5052	2	3	9104	
5053	2	4	9104	
5054	2	5	9104	
5055	3	1	9104	
5056	3	2	9104	
5057	3	3	9104	
5058	3	4	9104	
5059	3	5	9104	
5060	0	1	9105	
5061	0	2	9105	
5062	0	3	9105	
5063	0	4	9105	
5064	0	5	9105	
5065	1	1	9105	
5066	1	2	9105	
5067	1	3	9105	
5068	1	4	9105	
5069	1	5	9105	
5070	2	1	9105	
5071	2	2	9105	
5072	2	3	9105	
5073	2	4	9105	
5074	2	5	9105	
5075	3	1	9105	
5076	3	2	9105	
5077	3	3	9105	
5078	3	4	9105	
5079	3	5	9105	
5080	0	1	9106	
5081	0	2	9106	
5082	0	3	9106	
5083	0	4	9106	
5084	0	5	9106	
5085	1	1	9106	
5086	1	2	9106	
5087	1	3	9106	
5088	1	4	9106	
5089	1	5	9106	
5090	2	1	9106	
5091	2	2	9106	
5092	2	3	9106	
5093	2	4	9106	
5094	2	5	9106	
5095	3	1	9106	
5096	3	2	9106	
5097	3	3	9106	
5098	3	4	9106	
5099	3	5	9106	
5100	0	1	9107	
5101	0	2	9107	
5102	0	3	9107	
5103	0	4	9107	
5104	0	5	9107	
5105	1	1	9107	
5106	1	2	9107	
5107	1	3	9107	
5108	1	4	9107	
5109	1	5	9107	
5110	2	1	9107	
5111	2	2	9107	
5112	2	3	9107	
5113	2	4	9107	
5114	2	5	9107	
5115	3	1	9107	
5116	3	2	9107	
5117	3	3	9107	
5118	3	4	9107	
5119	3	5	9107	
5120	0	1	9108	
5121	0	2	9108	
5122	0	3	9108	
5123	0	4	9108	
5124	0	5	9108	
5125	1	1	9108	
5126	1	2	9108	
5127	1	3	9108	
5128	1	4	9108	
5129	1	5	9108	
5130	2	1	9108	
5131	2	2	9108	
5132	2	3	9108	
5133	2	4	9108	
5134	2	5	9108	
5135	3	1	9108	
5136	3	2	9108	
5137	3	3	9108	
5138	3	4	9108	
5139	3	5	9108	
5140	0	1	9109	
5141	0	2	9109	
5142	0	3	9109	
5143	0	4	9109	
5144	0	5	9109	
5145	1	1	9109	
5146	1	2	9109	
5147	1	3	9109	
5148	1	4	9109	
5149	1	5	9109	
5150	2	1	9109	
5151	2	2	9109	
5152	2	3	9109	
5153	2	4	9109	
5154	2	5	9109	
5155	3	1	9109	
5156	3	2	9109	
5157	3	3	9109	
5158	3	4	9109	
5159	3	5	9109	
5160	0	1	9110	
5161	0	2	9110	
5162	0	3	9110	
5163	0	4	9110	
5164	0	5	9110	
5165	1	1	9110	
5166	1	2	9110	
5167	1	3	9110	
5168	1	4	9110	
5169	1	5	9110	
5170	2	1	9110	
5171	2	2	9110	
5172	2	3	9110	
5173	2	4	9110	
5174	2	5	9110	
5175	3	1	9110	
5176	3	2	9110	
5177	3	3	9110	
5178	3	4	9110	
5179	3	5	9110	
5180	0	1	9111	
5181	0	2	9111	
5182	0	3	9111	
5183	0	4	9111	
5184	0	5	9111	
5185	1	1	9111	
5186	1	2	9111	
5187	1	3	9111	
5188	1	4	9111	
5189	1	5	9111	
5190	2	1	9111	
5191	2	2	9111	
5192	2	3	9111	
5193	2	4	9111	
5194	2	5	9111	
5195	3	1	9111	
5196	3	2	9111	
5197	3	3	9111	
5198	3	4	9111	
5199	3	5	9111	
5200	0	1	9201	
5201	0	2	9201	
5202	0	3	9201	
5203	0	4	9201	
5204	0	5	9201	
5205	1	1	9201	
5206	1	2	9201	
5207	1	3	9201	
5208	1	4	9201	
5209	1	5	9201	
5210	2	1	9201	
5211	2	2	9201	
5212	2	3	9201	
5213	2	4	9201	
5214	2	5	9201	
5215	3	1	9201	
5216	3	2	9201	
5217	3	3	9201	
5218	3	4	9201	
5219	3	5	9201	
5220	0	1	9202	
5221	0	2	9202	
5222	0	3	9202	
5223	0	4	9202	
5224	0	5	9202	
5225	1	1	9202	
5226	1	2	9202	
5227	1	3	9202	
5228	1	4	9202	
5229	1	5	9202	
5230	2	1	9202	
5231	2	2	9202	
5232	2	3	9202	
5233	2	4	9202	
5234	2	5	9202	
5235	3	1	9202	
5236	3	2	9202	
5237	3	3	9202	
5238	3	4	9202	
5239	3	5	9202	
5240	0	1	9203	
5241	0	2	9203	
5242	0	3	9203	
5243	0	4	9203	
5244	0	5	9203	
5245	1	1	9203	
5246	1	2	9203	
5247	1	3	9203	
5248	1	4	9203	
5249	1	5	9203	
5250	2	1	9203	
5251	2	2	9203	
5252	2	3	9203	
5253	2	4	9203	
5254	2	5	9203	
5255	3	1	9203	
5256	3	2	9203	
5257	3	3	9203	
5258	3	4	9203	
5259	3	5	9203	
5260	0	1	9204	
5261	0	2	9204	
5262	0	3	9204	
5263	0	4	9204	
5264	0	5	9204	
5265	1	1	9204	
5266	1	2	9204	
5267	1	3	9204	
5268	1	4	9204	
5269	1	5	9204	
5270	2	1	9204	
5271	2	2	9204	
5272	2	3	9204	
5273	2	4	9204	
5274	2	5	9204	
5275	3	1	9204	
5276	3	2	9204	
5277	3	3	9204	
5278	3	4	9204	
5279	3	5	9204	
5280	0	1	9205	
5281	0	2	9205	
5282	0	3	9205	
5283	0	4	9205	
5284	0	5	9205	
5285	1	1	9205	
5286	1	2	9205	
5287	1	3	9205	
5288	1	4	9205	
5289	1	5	9205	
5290	2	1	9205	
5291	2	2	9205	
5292	2	3	9205	
5293	2	4	9205	
5294	2	5	9205	
5295	3	1	9205	
5296	3	2	9205	
5297	3	3	9205	
5298	3	4	9205	
5299	3	5	9205	
5300	0	1	9206	
5301	0	2	9206	
5302	0	3	9206	
5303	0	4	9206	
5304	0	5	9206	
5305	1	1	9206	
5306	1	2	9206	
5307	1	3	9206	
5308	1	4	9206	
5309	1	5	9206	
5310	2	1	9206	
5311	2	2	9206	
5312	2	3	9206	
5313	2	4	9206	
5314	2	5	9206	
5315	3	1	9206	
5316	3	2	9206	
5317	3	3	9206	
5318	3	4	9206	
5319	3	5	9206	
5320	0	1	9207	
5321	0	2	9207	
5322	0	3	9207	
5323	0	4	9207	
5324	0	5	9207	
5325	1	1	9207	
5326	1	2	9207	
5327	1	3	9207	
5328	1	4	9207	
5329	1	5	9207	
5330	2	1	9207	
5331	2	2	9207	
5332	2	3	9207	
5333	2	4	9207	
5334	2	5	9207	
5335	3	1	9207	
5336	3	2	9207	
5337	3	3	9207	
5338	3	4	9207	
5339	3	5	9207	
5340	0	1	9208	
5341	0	2	9208	
5342	0	3	9208	
5343	0	4	9208	
5344	0	5	9208	
5345	1	1	9208	
5346	1	2	9208	
5347	1	3	9208	
5348	1	4	9208	
5349	1	5	9208	
5350	2	1	9208	
5351	2	2	9208	
5352	2	3	9208	
5353	2	4	9208	
5354	2	5	9208	
5355	3	1	9208	
5356	3	2	9208	
5357	3	3	9208	
5358	3	4	9208	
5359	3	5	9208	
5360	0	1	9209	
5361	0	2	9209	
5362	0	3	9209	
5363	0	4	9209	
5364	0	5	9209	
5365	1	1	9209	
5366	1	2	9209	
5367	1	3	9209	
5368	1	4	9209	
5369	1	5	9209	
5370	2	1	9209	
5371	2	2	9209	
5372	2	3	9209	
5373	2	4	9209	
5374	2	5	9209	
5375	3	1	9209	
5376	3	2	9209	
5377	3	3	9209	
5378	3	4	9209	
5379	3	5	9209	
5380	0	1	9210	
5381	0	2	9210	
5382	0	3	9210	
5383	0	4	9210	
5384	0	5	9210	
5385	1	1	9210	
5386	1	2	9210	
5387	1	3	9210	
5388	1	4	9210	
5389	1	5	9210	
5390	2	1	9210	
5391	2	2	9210	
5392	2	3	9210	
5393	2	4	9210	
5394	2	5	9210	
5395	3	1	9210	
5396	3	2	9210	
5397	3	3	9210	
5398	3	4	9210	
5399	3	5	9210	
5400	0	1	9211	
5401	0	2	9211	
5402	0	3	9211	
5403	0	4	9211	
5404	0	5	9211	
5405	1	1	9211	
5406	1	2	9211	
5407	1	3	9211	
5408	1	4	9211	
5409	1	5	9211	
5410	2	1	9211	
5411	2	2	9211	
5412	2	3	9211	
5413	2	4	9211	
5414	2	5	9211	
5415	3	1	9211	
5416	3	2	9211	
5417	3	3	9211	
5418	3	4	9211	
5419	3	5	9211	
5420	0	1	9212	
5421	0	2	9212	
5422	0	3	9212	
5423	0	4	9212	
5424	0	5	9212	
5425	1	1	9212	
5426	1	2	9212	
5427	1	3	9212	
5428	1	4	9212	
5429	1	5	9212	
5430	2	1	9212	
5431	2	2	9212	
5432	2	3	9212	
5433	2	4	9212	
5434	2	5	9212	
5435	3	1	9212	
5436	3	2	9212	
5437	3	3	9212	
5438	3	4	9212	
5439	3	5	9212	
5440	0	1	9213	
5441	0	2	9213	
5442	0	3	9213	
5443	0	4	9213	
5444	0	5	9213	
5445	1	1	9213	
5446	1	2	9213	
5447	1	3	9213	
5448	1	4	9213	
5449	1	5	9213	
5450	2	1	9213	
5451	2	2	9213	
5452	2	3	9213	
5453	2	4	9213	
5454	2	5	9213	
5455	3	1	9213	
5456	3	2	9213	
5457	3	3	9213	
5458	3	4	9213	
5459	3	5	9213	
5460	0	1	9214	
5461	0	2	9214	
5462	0	3	9214	
5463	0	4	9214	
5464	0	5	9214	
5465	1	1	9214	
5466	1	2	9214	
5467	1	3	9214	
5468	1	4	9214	
5469	1	5	9214	
5470	2	1	9214	
5471	2	2	9214	
5472	2	3	9214	
5473	2	4	9214	
5474	2	5	9214	
5475	3	1	9214	
5476	3	2	9214	
5477	3	3	9214	
5478	3	4	9214	
5479	3	5	9214	
5480	0	1	9215	
5481	0	2	9215	
5482	0	3	9215	
5483	0	4	9215	
5484	0	5	9215	
5485	1	1	9215	
5486	1	2	9215	
5487	1	3	9215	
5488	1	4	9215	
5489	1	5	9215	
5490	2	1	9215	
5491	2	2	9215	
5492	2	3	9215	
5493	2	4	9215	
5494	2	5	9215	
5495	3	1	9215	
5496	3	2	9215	
5497	3	3	9215	
5498	3	4	9215	
5499	3	5	9215	
5500	0	1	9216	
5501	0	2	9216	
5502	0	3	9216	
5503	0	4	9216	
5504	0	5	9216	
5505	1	1	9216	
5506	1	2	9216	
5507	1	3	9216	
5508	1	4	9216	
5509	1	5	9216	
5510	2	1	9216	
5511	2	2	9216	
5512	2	3	9216	
5513	2	4	9216	
5514	2	5	9216	
5515	3	1	9216	
5516	3	2	9216	
5517	3	3	9216	
5518	3	4	9216	
5519	3	5	9216	
5520	0	1	9217	
5521	0	2	9217	
5522	0	3	9217	
5523	0	4	9217	
5524	0	5	9217	
5525	1	1	9217	
5526	1	2	9217	
5527	1	3	9217	
5528	1	4	9217	
5529	1	5	9217	
5530	2	1	9217	
5531	2	2	9217	
5532	2	3	9217	
5533	2	4	9217	
5534	2	5	9217	
5535	3	1	9217	
5536	3	2	9217	
5537	3	3	9217	
5538	3	4	9217	
5539	3	5	9217	
5540	0	1	9218	
5541	0	2	9218	
5542	0	3	9218	
5543	0	4	9218	
5544	0	5	9218	
5545	1	1	9218	
5546	1	2	9218	
5547	1	3	9218	
5548	1	4	9218	
5549	1	5	9218	
5550	2	1	9218	
5551	2	2	9218	
5552	2	3	9218	
5553	2	4	9218	
5554	2	5	9218	
5555	3	1	9218	
5556	3	2	9218	
5557	3	3	9218	
5558	3	4	9218	
5559	3	5	9218	
5560	0	1	9219	
5561	0	2	9219	
5562	0	3	9219	
5563	0	4	9219	
5564	0	5	9219	
5565	1	1	9219	
5566	1	2	9219	
5567	1	3	9219	
5568	1	4	9219	
5569	1	5	9219	
5570	2	1	9219	
5571	2	2	9219	
5572	2	3	9219	
5573	2	4	9219	
5574	2	5	9219	
5575	3	1	9219	
5576	3	2	9219	
5577	3	3	9219	
5578	3	4	9219	
5579	3	5	9219	
5580	0	1	9220	
5581	0	2	9220	
5582	0	3	9220	
5583	0	4	9220	
5584	0	5	9220	
5585	1	1	9220	
5586	1	2	9220	
5587	1	3	9220	
5588	1	4	9220	
5589	1	5	9220	
5590	2	1	9220	
5591	2	2	9220	
5592	2	3	9220	
5593	2	4	9220	
5594	2	5	9220	
5595	3	1	9220	
5596	3	2	9220	
5597	3	3	9220	
5598	3	4	9220	
5599	3	5	9220	
5600	0	1	9221	
5601	0	2	9221	
5602	0	3	9221	
5603	0	4	9221	
5604	0	5	9221	
5605	1	1	9221	
5606	1	2	9221	
5607	1	3	9221	
5608	1	4	9221	
5609	1	5	9221	
5610	2	1	9221	
5611	2	2	9221	
5612	2	3	9221	
5613	2	4	9221	
5614	2	5	9221	
5615	3	1	9221	
5616	3	2	9221	
5617	3	3	9221	
5618	3	4	9221	
5619	3	5	9221	
5620	0	1	10101	
5621	0	2	10101	
5622	0	3	10101	
5623	0	4	10101	
5624	0	5	10101	
5625	1	1	10101	
5626	1	2	10101	
5627	1	3	10101	
5628	1	4	10101	
5629	1	5	10101	
5630	2	1	10101	
5631	2	2	10101	
5632	2	3	10101	
5633	2	4	10101	
5634	2	5	10101	
5635	3	1	10101	
5636	3	2	10101	
5637	3	3	10101	
5638	3	4	10101	
5639	3	5	10101	
5640	0	1	10102	
5641	0	2	10102	
5642	0	3	10102	
5643	0	4	10102	
5644	0	5	10102	
5645	1	1	10102	
5646	1	2	10102	
5647	1	3	10102	
5648	1	4	10102	
5649	1	5	10102	
5650	2	1	10102	
5651	2	2	10102	
5652	2	3	10102	
5653	2	4	10102	
5654	2	5	10102	
5655	3	1	10102	
5656	3	2	10102	
5657	3	3	10102	
5658	3	4	10102	
5659	3	5	10102	
5660	0	1	10103	
5661	0	2	10103	
5662	0	3	10103	
5663	0	4	10103	
5664	0	5	10103	
5665	1	1	10103	
5666	1	2	10103	
5667	1	3	10103	
5668	1	4	10103	
5669	1	5	10103	
5670	2	1	10103	
5671	2	2	10103	
5672	2	3	10103	
5673	2	4	10103	
5674	2	5	10103	
5675	3	1	10103	
5676	3	2	10103	
5677	3	3	10103	
5678	3	4	10103	
5679	3	5	10103	
5680	0	1	10104	
5681	0	2	10104	
5682	0	3	10104	
5683	0	4	10104	
5684	0	5	10104	
5685	1	1	10104	
5686	1	2	10104	
5687	1	3	10104	
5688	1	4	10104	
5689	1	5	10104	
5690	2	1	10104	
5691	2	2	10104	
5692	2	3	10104	
5693	2	4	10104	
5694	2	5	10104	
5695	3	1	10104	
5696	3	2	10104	
5697	3	3	10104	
5698	3	4	10104	
5699	3	5	10104	
5700	0	1	10105	
5701	0	2	10105	
5702	0	3	10105	
5703	0	4	10105	
5704	0	5	10105	
5705	1	1	10105	
5706	1	2	10105	
5707	1	3	10105	
5708	1	4	10105	
5709	1	5	10105	
5710	2	1	10105	
5711	2	2	10105	
5712	2	3	10105	
5713	2	4	10105	
5714	2	5	10105	
5715	3	1	10105	
5716	3	2	10105	
5717	3	3	10105	
5718	3	4	10105	
5719	3	5	10105	
5720	0	1	10106	
5721	0	2	10106	
5722	0	3	10106	
5723	0	4	10106	
5724	0	5	10106	
5725	1	1	10106	
5726	1	2	10106	
5727	1	3	10106	
5728	1	4	10106	
5729	1	5	10106	
5730	2	1	10106	
5731	2	2	10106	
5732	2	3	10106	
5733	2	4	10106	
5734	2	5	10106	
5735	3	1	10106	
5736	3	2	10106	
5737	3	3	10106	
5738	3	4	10106	
5739	3	5	10106	
5740	0	1	10107	
5741	0	2	10107	
5742	0	3	10107	
5743	0	4	10107	
5744	0	5	10107	
5745	1	1	10107	
5746	1	2	10107	
5747	1	3	10107	
5748	1	4	10107	
5749	1	5	10107	
5750	2	1	10107	
5751	2	2	10107	
5752	2	3	10107	
5753	2	4	10107	
5754	2	5	10107	
5755	3	1	10107	
5756	3	2	10107	
5757	3	3	10107	
5758	3	4	10107	
5759	3	5	10107	
5760	0	1	10108	
5761	0	2	10108	
5762	0	3	10108	
5763	0	4	10108	
5764	0	5	10108	
5765	1	1	10108	
5766	1	2	10108	
5767	1	3	10108	
5768	1	4	10108	
5769	1	5	10108	
5770	2	1	10108	
5771	2	2	10108	
5772	2	3	10108	
5773	2	4	10108	
5774	2	5	10108	
5775	3	1	10108	
5776	3	2	10108	
5777	3	3	10108	
5778	3	4	10108	
5779	3	5	10108	
5780	0	1	10109	
5781	0	2	10109	
5782	0	3	10109	
5783	0	4	10109	
5784	0	5	10109	
5785	1	1	10109	
5786	1	2	10109	
5787	1	3	10109	
5788	1	4	10109	
5789	1	5	10109	
5790	2	1	10109	
5791	2	2	10109	
5792	2	3	10109	
5793	2	4	10109	
5794	2	5	10109	
5795	3	1	10109	
5796	3	2	10109	
5797	3	3	10109	
5798	3	4	10109	
5799	3	5	10109	
5800	0	1	10110	
5801	0	2	10110	
5802	0	3	10110	
5803	0	4	10110	
5804	0	5	10110	
5805	1	1	10110	
5806	1	2	10110	
5807	1	3	10110	
5808	1	4	10110	
5809	1	5	10110	
5810	2	1	10110	
5811	2	2	10110	
5812	2	3	10110	
5813	2	4	10110	
5814	2	5	10110	
5815	3	1	10110	
5816	3	2	10110	
5817	3	3	10110	
5818	3	4	10110	
5819	3	5	10110	
5820	0	1	10111	
5821	0	2	10111	
5822	0	3	10111	
5823	0	4	10111	
5824	0	5	10111	
5825	1	1	10111	
5826	1	2	10111	
5827	1	3	10111	
5828	1	4	10111	
5829	1	5	10111	
5830	2	1	10111	
5831	2	2	10111	
5832	2	3	10111	
5833	2	4	10111	
5834	2	5	10111	
5835	3	1	10111	
5836	3	2	10111	
5837	3	3	10111	
5838	3	4	10111	
5839	3	5	10111	
5840	0	1	10112	
5841	0	2	10112	
5842	0	3	10112	
5843	0	4	10112	
5844	0	5	10112	
5845	1	1	10112	
5846	1	2	10112	
5847	1	3	10112	
5848	1	4	10112	
5849	1	5	10112	
5850	2	1	10112	
5851	2	2	10112	
5852	2	3	10112	
5853	2	4	10112	
5854	2	5	10112	
5855	3	1	10112	
5856	3	2	10112	
5857	3	3	10112	
5858	3	4	10112	
5859	3	5	10112	
5860	0	1	10201	
5861	0	2	10201	
5862	0	3	10201	
5863	0	4	10201	
5864	0	5	10201	
5865	1	1	10201	
5866	1	2	10201	
5867	1	3	10201	
5868	1	4	10201	
5869	1	5	10201	
5870	2	1	10201	
5871	2	2	10201	
5872	2	3	10201	
5873	2	4	10201	
5874	2	5	10201	
5875	3	1	10201	
5876	3	2	10201	
5877	3	3	10201	
5878	3	4	10201	
5879	3	5	10201	
5880	0	1	10202	
5881	0	2	10202	
5882	0	3	10202	
5883	0	4	10202	
5884	0	5	10202	
5885	1	1	10202	
5886	1	2	10202	
5887	1	3	10202	
5888	1	4	10202	
5889	1	5	10202	
5890	2	1	10202	
5891	2	2	10202	
5892	2	3	10202	
5893	2	4	10202	
5894	2	5	10202	
5895	3	1	10202	
5896	3	2	10202	
5897	3	3	10202	
5898	3	4	10202	
5899	3	5	10202	
5900	0	1	10203	
5901	0	2	10203	
5902	0	3	10203	
5903	0	4	10203	
5904	0	5	10203	
5905	1	1	10203	
5906	1	2	10203	
5907	1	3	10203	
5908	1	4	10203	
5909	1	5	10203	
5910	2	1	10203	
5911	2	2	10203	
5912	2	3	10203	
5913	2	4	10203	
5914	2	5	10203	
5915	3	1	10203	
5916	3	2	10203	
5917	3	3	10203	
5918	3	4	10203	
5919	3	5	10203	
5920	0	1	10204	
5921	0	2	10204	
5922	0	3	10204	
5923	0	4	10204	
5924	0	5	10204	
5925	1	1	10204	
5926	1	2	10204	
5927	1	3	10204	
5928	1	4	10204	
5929	1	5	10204	
5930	2	1	10204	
5931	2	2	10204	
5932	2	3	10204	
5933	2	4	10204	
5934	2	5	10204	
5935	3	1	10204	
5936	3	2	10204	
5937	3	3	10204	
5938	3	4	10204	
5939	3	5	10204	
5940	0	1	10205	
5941	0	2	10205	
5942	0	3	10205	
5943	0	4	10205	
5944	0	5	10205	
5945	1	1	10205	
5946	1	2	10205	
5947	1	3	10205	
5948	1	4	10205	
5949	1	5	10205	
5950	2	1	10205	
5951	2	2	10205	
5952	2	3	10205	
5953	2	4	10205	
5954	2	5	10205	
5955	3	1	10205	
5956	3	2	10205	
5957	3	3	10205	
5958	3	4	10205	
5959	3	5	10205	
5960	0	1	10206	
5961	0	2	10206	
5962	0	3	10206	
5963	0	4	10206	
5964	0	5	10206	
5965	1	1	10206	
5966	1	2	10206	
5967	1	3	10206	
5968	1	4	10206	
5969	1	5	10206	
5970	2	1	10206	
5971	2	2	10206	
5972	2	3	10206	
5973	2	4	10206	
5974	2	5	10206	
5975	3	1	10206	
5976	3	2	10206	
5977	3	3	10206	
5978	3	4	10206	
5979	3	5	10206	
5980	0	1	10207	
5981	0	2	10207	
5982	0	3	10207	
5983	0	4	10207	
5984	0	5	10207	
5985	1	1	10207	
5986	1	2	10207	
5987	1	3	10207	
5988	1	4	10207	
5989	1	5	10207	
5990	2	1	10207	
5991	2	2	10207	
5992	2	3	10207	
5993	2	4	10207	
5994	2	5	10207	
5995	3	1	10207	
5996	3	2	10207	
5997	3	3	10207	
5998	3	4	10207	
5999	3	5	10207	
6000	0	1	10301	
6001	0	2	10301	
6002	0	3	10301	
6003	0	4	10301	
6004	0	5	10301	
6005	1	1	10301	
6006	1	2	10301	
6007	1	3	10301	
6008	1	4	10301	
6009	1	5	10301	
6010	2	1	10301	
6011	2	2	10301	
6012	2	3	10301	
6013	2	4	10301	
6014	2	5	10301	
6015	3	1	10301	
6016	3	2	10301	
6017	3	3	10301	
6018	3	4	10301	
6019	3	5	10301	
6020	0	1	10302	
6021	0	2	10302	
6022	0	3	10302	
6023	0	4	10302	
6024	0	5	10302	
6025	1	1	10302	
6026	1	2	10302	
6027	1	3	10302	
6028	1	4	10302	
6029	1	5	10302	
6030	2	1	10302	
6031	2	2	10302	
6032	2	3	10302	
6033	2	4	10302	
6034	2	5	10302	
6035	3	1	10302	
6036	3	2	10302	
6037	3	3	10302	
6038	3	4	10302	
6039	3	5	10302	
6040	0	1	10303	
6041	0	2	10303	
6042	0	3	10303	
6043	0	4	10303	
6044	0	5	10303	
6045	1	1	10303	
6046	1	2	10303	
6047	1	3	10303	
6048	1	4	10303	
6049	1	5	10303	
6050	2	1	10303	
6051	2	2	10303	
6052	2	3	10303	
6053	2	4	10303	
6054	2	5	10303	
6055	3	1	10303	
6056	3	2	10303	
6057	3	3	10303	
6058	3	4	10303	
6059	3	5	10303	
6060	0	1	10304	
6061	0	2	10304	
6062	0	3	10304	
6063	0	4	10304	
6064	0	5	10304	
6065	1	1	10304	
6066	1	2	10304	
6067	1	3	10304	
6068	1	4	10304	
6069	1	5	10304	
6070	2	1	10304	
6071	2	2	10304	
6072	2	3	10304	
6073	2	4	10304	
6074	2	5	10304	
6075	3	1	10304	
6076	3	2	10304	
6077	3	3	10304	
6078	3	4	10304	
6079	3	5	10304	
6080	0	1	10305	
6081	0	2	10305	
6082	0	3	10305	
6083	0	4	10305	
6084	0	5	10305	
6085	1	1	10305	
6086	1	2	10305	
6087	1	3	10305	
6088	1	4	10305	
6089	1	5	10305	
6090	2	1	10305	
6091	2	2	10305	
6092	2	3	10305	
6093	2	4	10305	
6094	2	5	10305	
6095	3	1	10305	
6096	3	2	10305	
6097	3	3	10305	
6098	3	4	10305	
6099	3	5	10305	
6100	0	1	10306	
6101	0	2	10306	
6102	0	3	10306	
6103	0	4	10306	
6104	0	5	10306	
6105	1	1	10306	
6106	1	2	10306	
6107	1	3	10306	
6108	1	4	10306	
6109	1	5	10306	
6110	2	1	10306	
6111	2	2	10306	
6112	2	3	10306	
6113	2	4	10306	
6114	2	5	10306	
6115	3	1	10306	
6116	3	2	10306	
6117	3	3	10306	
6118	3	4	10306	
6119	3	5	10306	
6120	0	1	10307	
6121	0	2	10307	
6122	0	3	10307	
6123	0	4	10307	
6124	0	5	10307	
6125	1	1	10307	
6126	1	2	10307	
6127	1	3	10307	
6128	1	4	10307	
6129	1	5	10307	
6130	2	1	10307	
6131	2	2	10307	
6132	2	3	10307	
6133	2	4	10307	
6134	2	5	10307	
6135	3	1	10307	
6136	3	2	10307	
6137	3	3	10307	
6138	3	4	10307	
6139	3	5	10307	
6140	0	1	10308	
6141	0	2	10308	
6142	0	3	10308	
6143	0	4	10308	
6144	0	5	10308	
6145	1	1	10308	
6146	1	2	10308	
6147	1	3	10308	
6148	1	4	10308	
6149	1	5	10308	
6150	2	1	10308	
6151	2	2	10308	
6152	2	3	10308	
6153	2	4	10308	
6154	2	5	10308	
6155	3	1	10308	
6156	3	2	10308	
6157	3	3	10308	
6158	3	4	10308	
6159	3	5	10308	
6160	0	1	10309	
6161	0	2	10309	
6162	0	3	10309	
6163	0	4	10309	
6164	0	5	10309	
6165	1	1	10309	
6166	1	2	10309	
6167	1	3	10309	
6168	1	4	10309	
6169	1	5	10309	
6170	2	1	10309	
6171	2	2	10309	
6172	2	3	10309	
6173	2	4	10309	
6174	2	5	10309	
6175	3	1	10309	
6176	3	2	10309	
6177	3	3	10309	
6178	3	4	10309	
6179	3	5	10309	
6180	0	1	10401	
6181	0	2	10401	
6182	0	3	10401	
6183	0	4	10401	
6184	0	5	10401	
6185	1	1	10401	
6186	1	2	10401	
6187	1	3	10401	
6188	1	4	10401	
6189	1	5	10401	
6190	2	1	10401	
6191	2	2	10401	
6192	2	3	10401	
6193	2	4	10401	
6194	2	5	10401	
6195	3	1	10401	
6196	3	2	10401	
6197	3	3	10401	
6198	3	4	10401	
6199	3	5	10401	
6200	0	1	10402	
6201	0	2	10402	
6202	0	3	10402	
6203	0	4	10402	
6204	0	5	10402	
6205	1	1	10402	
6206	1	2	10402	
6207	1	3	10402	
6208	1	4	10402	
6209	1	5	10402	
6210	2	1	10402	
6211	2	2	10402	
6212	2	3	10402	
6213	2	4	10402	
6214	2	5	10402	
6215	3	1	10402	
6216	3	2	10402	
6217	3	3	10402	
6218	3	4	10402	
6219	3	5	10402	
6220	0	1	10403	
6221	0	2	10403	
6222	0	3	10403	
6223	0	4	10403	
6224	0	5	10403	
6225	1	1	10403	
6226	1	2	10403	
6227	1	3	10403	
6228	1	4	10403	
6229	1	5	10403	
6230	2	1	10403	
6231	2	2	10403	
6232	2	3	10403	
6233	2	4	10403	
6234	2	5	10403	
6235	3	1	10403	
6236	3	2	10403	
6237	3	3	10403	
6238	3	4	10403	
6239	3	5	10403	
6240	0	1	10404	
6241	0	2	10404	
6242	0	3	10404	
6243	0	4	10404	
6244	0	5	10404	
6245	1	1	10404	
6246	1	2	10404	
6247	1	3	10404	
6248	1	4	10404	
6249	1	5	10404	
6250	2	1	10404	
6251	2	2	10404	
6252	2	3	10404	
6253	2	4	10404	
6254	2	5	10404	
6255	3	1	10404	
6256	3	2	10404	
6257	3	3	10404	
6258	3	4	10404	
6259	3	5	10404	
6260	0	1	10405	
6261	0	2	10405	
6262	0	3	10405	
6263	0	4	10405	
6264	0	5	10405	
6265	1	1	10405	
6266	1	2	10405	
6267	1	3	10405	
6268	1	4	10405	
6269	1	5	10405	
6270	2	1	10405	
6271	2	2	10405	
6272	2	3	10405	
6273	2	4	10405	
6274	2	5	10405	
6275	3	1	10405	
6276	3	2	10405	
6277	3	3	10405	
6278	3	4	10405	
6279	3	5	10405	
6280	0	1	10406	
6281	0	2	10406	
6282	0	3	10406	
6283	0	4	10406	
6284	0	5	10406	
6285	1	1	10406	
6286	1	2	10406	
6287	1	3	10406	
6288	1	4	10406	
6289	1	5	10406	
6290	2	1	10406	
6291	2	2	10406	
6292	2	3	10406	
6293	2	4	10406	
6294	2	5	10406	
6295	3	1	10406	
6296	3	2	10406	
6297	3	3	10406	
6298	3	4	10406	
6299	3	5	10406	
6300	0	1	10407	
6301	0	2	10407	
6302	0	3	10407	
6303	0	4	10407	
6304	0	5	10407	
6305	1	1	10407	
6306	1	2	10407	
6307	1	3	10407	
6308	1	4	10407	
6309	1	5	10407	
6310	2	1	10407	
6311	2	2	10407	
6312	2	3	10407	
6313	2	4	10407	
6314	2	5	10407	
6315	3	1	10407	
6316	3	2	10407	
6317	3	3	10407	
6318	3	4	10407	
6319	3	5	10407	
6320	0	1	10408	
6321	0	2	10408	
6322	0	3	10408	
6323	0	4	10408	
6324	0	5	10408	
6325	1	1	10408	
6326	1	2	10408	
6327	1	3	10408	
6328	1	4	10408	
6329	1	5	10408	
6330	2	1	10408	
6331	2	2	10408	
6332	2	3	10408	
6333	2	4	10408	
6334	2	5	10408	
6335	3	1	10408	
6336	3	2	10408	
6337	3	3	10408	
6338	3	4	10408	
6339	3	5	10408	
6340	0	1	10410	
6341	0	2	10410	
6342	0	3	10410	
6343	0	4	10410	
6344	0	5	10410	
6345	1	1	10410	
6346	1	2	10410	
6347	1	3	10410	
6348	1	4	10410	
6349	1	5	10410	
6350	2	1	10410	
6351	2	2	10410	
6352	2	3	10410	
6353	2	4	10410	
6354	2	5	10410	
6355	3	1	10410	
6356	3	2	10410	
6357	3	3	10410	
6358	3	4	10410	
6359	3	5	10410	
6360	0	1	10415	
6361	0	2	10415	
6362	0	3	10415	
6363	0	4	10415	
6364	0	5	10415	
6365	1	1	10415	
6366	1	2	10415	
6367	1	3	10415	
6368	1	4	10415	
6369	1	5	10415	
6370	2	1	10415	
6371	2	2	10415	
6372	2	3	10415	
6373	2	4	10415	
6374	2	5	10415	
6375	3	1	10415	
6376	3	2	10415	
6377	3	3	10415	
6378	3	4	10415	
6379	3	5	10415	
6380	0	1	10501	
6381	0	2	10501	
6382	0	3	10501	
6383	0	4	10501	
6384	0	5	10501	
6385	1	1	10501	
6386	1	2	10501	
6387	1	3	10501	
6388	1	4	10501	
6389	1	5	10501	
6390	2	1	10501	
6391	2	2	10501	
6392	2	3	10501	
6393	2	4	10501	
6394	2	5	10501	
6395	3	1	10501	
6396	3	2	10501	
6397	3	3	10501	
6398	3	4	10501	
6399	3	5	10501	
6400	0	1	10502	
6401	0	2	10502	
6402	0	3	10502	
6403	0	4	10502	
6404	0	5	10502	
6405	1	1	10502	
6406	1	2	10502	
6407	1	3	10502	
6408	1	4	10502	
6409	1	5	10502	
6410	2	1	10502	
6411	2	2	10502	
6412	2	3	10502	
6413	2	4	10502	
6414	2	5	10502	
6415	3	1	10502	
6416	3	2	10502	
6417	3	3	10502	
6418	3	4	10502	
6419	3	5	10502	
6420	0	1	10503	
6421	0	2	10503	
6422	0	3	10503	
6423	0	4	10503	
6424	0	5	10503	
6425	1	1	10503	
6426	1	2	10503	
6427	1	3	10503	
6428	1	4	10503	
6429	1	5	10503	
6430	2	1	10503	
6431	2	2	10503	
6432	2	3	10503	
6433	2	4	10503	
6434	2	5	10503	
6435	3	1	10503	
6436	3	2	10503	
6437	3	3	10503	
6438	3	4	10503	
6439	3	5	10503	
6440	0	1	10504	
6441	0	2	10504	
6442	0	3	10504	
6443	0	4	10504	
6444	0	5	10504	
6445	1	1	10504	
6446	1	2	10504	
6447	1	3	10504	
6448	1	4	10504	
6449	1	5	10504	
6450	2	1	10504	
6451	2	2	10504	
6452	2	3	10504	
6453	2	4	10504	
6454	2	5	10504	
6455	3	1	10504	
6456	3	2	10504	
6457	3	3	10504	
6458	3	4	10504	
6459	3	5	10504	
6460	0	1	11101	
6461	0	2	11101	
6462	0	3	11101	
6463	0	4	11101	
6464	0	5	11101	
6465	1	1	11101	
6466	1	2	11101	
6467	1	3	11101	
6468	1	4	11101	
6469	1	5	11101	
6470	2	1	11101	
6471	2	2	11101	
6472	2	3	11101	
6473	2	4	11101	
6474	2	5	11101	
6475	3	1	11101	
6476	3	2	11101	
6477	3	3	11101	
6478	3	4	11101	
6479	3	5	11101	
6480	0	1	11102	
6481	0	2	11102	
6482	0	3	11102	
6483	0	4	11102	
6484	0	5	11102	
6485	1	1	11102	
6486	1	2	11102	
6487	1	3	11102	
6488	1	4	11102	
6489	1	5	11102	
6490	2	1	11102	
6491	2	2	11102	
6492	2	3	11102	
6493	2	4	11102	
6494	2	5	11102	
6495	3	1	11102	
6496	3	2	11102	
6497	3	3	11102	
6498	3	4	11102	
6499	3	5	11102	
6500	0	1	11104	
6501	0	2	11104	
6502	0	3	11104	
6503	0	4	11104	
6504	0	5	11104	
6505	1	1	11104	
6506	1	2	11104	
6507	1	3	11104	
6508	1	4	11104	
6509	1	5	11104	
6510	2	1	11104	
6511	2	2	11104	
6512	2	3	11104	
6513	2	4	11104	
6514	2	5	11104	
6515	3	1	11104	
6516	3	2	11104	
6517	3	3	11104	
6518	3	4	11104	
6519	3	5	11104	
6520	0	1	11201	
6521	0	2	11201	
6522	0	3	11201	
6523	0	4	11201	
6524	0	5	11201	
6525	1	1	11201	
6526	1	2	11201	
6527	1	3	11201	
6528	1	4	11201	
6529	1	5	11201	
6530	2	1	11201	
6531	2	2	11201	
6532	2	3	11201	
6533	2	4	11201	
6534	2	5	11201	
6535	3	1	11201	
6536	3	2	11201	
6537	3	3	11201	
6538	3	4	11201	
6539	3	5	11201	
6540	0	1	11203	
6541	0	2	11203	
6542	0	3	11203	
6543	0	4	11203	
6544	0	5	11203	
6545	1	1	11203	
6546	1	2	11203	
6547	1	3	11203	
6548	1	4	11203	
6549	1	5	11203	
6550	2	1	11203	
6551	2	2	11203	
6552	2	3	11203	
6553	2	4	11203	
6554	2	5	11203	
6555	3	1	11203	
6556	3	2	11203	
6557	3	3	11203	
6558	3	4	11203	
6559	3	5	11203	
6560	0	1	11301	
6561	0	2	11301	
6562	0	3	11301	
6563	0	4	11301	
6564	0	5	11301	
6565	1	1	11301	
6566	1	2	11301	
6567	1	3	11301	
6568	1	4	11301	
6569	1	5	11301	
6570	2	1	11301	
6571	2	2	11301	
6572	2	3	11301	
6573	2	4	11301	
6574	2	5	11301	
6575	3	1	11301	
6576	3	2	11301	
6577	3	3	11301	
6578	3	4	11301	
6579	3	5	11301	
6580	0	1	11302	
6581	0	2	11302	
6582	0	3	11302	
6583	0	4	11302	
6584	0	5	11302	
6585	1	1	11302	
6586	1	2	11302	
6587	1	3	11302	
6588	1	4	11302	
6589	1	5	11302	
6590	2	1	11302	
6591	2	2	11302	
6592	2	3	11302	
6593	2	4	11302	
6594	2	5	11302	
6595	3	1	11302	
6596	3	2	11302	
6597	3	3	11302	
6598	3	4	11302	
6599	3	5	11302	
6600	0	1	11303	
6601	0	2	11303	
6602	0	3	11303	
6603	0	4	11303	
6604	0	5	11303	
6605	1	1	11303	
6606	1	2	11303	
6607	1	3	11303	
6608	1	4	11303	
6609	1	5	11303	
6610	2	1	11303	
6611	2	2	11303	
6612	2	3	11303	
6613	2	4	11303	
6614	2	5	11303	
6615	3	1	11303	
6616	3	2	11303	
6617	3	3	11303	
6618	3	4	11303	
6619	3	5	11303	
6620	0	1	11401	
6621	0	2	11401	
6622	0	3	11401	
6623	0	4	11401	
6624	0	5	11401	
6625	1	1	11401	
6626	1	2	11401	
6627	1	3	11401	
6628	1	4	11401	
6629	1	5	11401	
6630	2	1	11401	
6631	2	2	11401	
6632	2	3	11401	
6633	2	4	11401	
6634	2	5	11401	
6635	3	1	11401	
6636	3	2	11401	
6637	3	3	11401	
6638	3	4	11401	
6639	3	5	11401	
6640	0	1	11402	
6641	0	2	11402	
6642	0	3	11402	
6643	0	4	11402	
6644	0	5	11402	
6645	1	1	11402	
6646	1	2	11402	
6647	1	3	11402	
6648	1	4	11402	
6649	1	5	11402	
6650	2	1	11402	
6651	2	2	11402	
6652	2	3	11402	
6653	2	4	11402	
6654	2	5	11402	
6655	3	1	11402	
6656	3	2	11402	
6657	3	3	11402	
6658	3	4	11402	
6659	3	5	11402	
6660	0	1	12101	
6661	0	2	12101	
6662	0	3	12101	
6663	0	4	12101	
6664	0	5	12101	
6665	1	1	12101	
6666	1	2	12101	
6667	1	3	12101	
6668	1	4	12101	
6669	1	5	12101	
6670	2	1	12101	
6671	2	2	12101	
6672	2	3	12101	
6673	2	4	12101	
6674	2	5	12101	
6675	3	1	12101	
6676	3	2	12101	
6677	3	3	12101	
6678	3	4	12101	
6679	3	5	12101	
6680	0	1	12103	
6681	0	2	12103	
6682	0	3	12103	
6683	0	4	12103	
6684	0	5	12103	
6685	1	1	12103	
6686	1	2	12103	
6687	1	3	12103	
6688	1	4	12103	
6689	1	5	12103	
6690	2	1	12103	
6691	2	2	12103	
6692	2	3	12103	
6693	2	4	12103	
6694	2	5	12103	
6695	3	1	12103	
6696	3	2	12103	
6697	3	3	12103	
6698	3	4	12103	
6699	3	5	12103	
6700	0	1	12202	
6701	0	2	12202	
6702	0	3	12202	
6703	0	4	12202	
6704	0	5	12202	
6705	1	1	12202	
6706	1	2	12202	
6707	1	3	12202	
6708	1	4	12202	
6709	1	5	12202	
6710	2	1	12202	
6711	2	2	12202	
6712	2	3	12202	
6713	2	4	12202	
6714	2	5	12202	
6715	3	1	12202	
6716	3	2	12202	
6717	3	3	12202	
6718	3	4	12202	
6719	3	5	12202	
6720	0	1	12204	
6721	0	2	12204	
6722	0	3	12204	
6723	0	4	12204	
6724	0	5	12204	
6725	1	1	12204	
6726	1	2	12204	
6727	1	3	12204	
6728	1	4	12204	
6729	1	5	12204	
6730	2	1	12204	
6731	2	2	12204	
6732	2	3	12204	
6733	2	4	12204	
6734	2	5	12204	
6735	3	1	12204	
6736	3	2	12204	
6737	3	3	12204	
6738	3	4	12204	
6739	3	5	12204	
6740	0	1	12205	
6741	0	2	12205	
6742	0	3	12205	
6743	0	4	12205	
6744	0	5	12205	
6745	1	1	12205	
6746	1	2	12205	
6747	1	3	12205	
6748	1	4	12205	
6749	1	5	12205	
6750	2	1	12205	
6751	2	2	12205	
6752	2	3	12205	
6753	2	4	12205	
6754	2	5	12205	
6755	3	1	12205	
6756	3	2	12205	
6757	3	3	12205	
6758	3	4	12205	
6759	3	5	12205	
6760	0	1	12206	
6761	0	2	12206	
6762	0	3	12206	
6763	0	4	12206	
6764	0	5	12206	
6765	1	1	12206	
6766	1	2	12206	
6767	1	3	12206	
6768	1	4	12206	
6769	1	5	12206	
6770	2	1	12206	
6771	2	2	12206	
6772	2	3	12206	
6773	2	4	12206	
6774	2	5	12206	
6775	3	1	12206	
6776	3	2	12206	
6777	3	3	12206	
6778	3	4	12206	
6779	3	5	12206	
6780	0	1	12301	
6781	0	2	12301	
6782	0	3	12301	
6783	0	4	12301	
6784	0	5	12301	
6785	1	1	12301	
6786	1	2	12301	
6787	1	3	12301	
6788	1	4	12301	
6789	1	5	12301	
6790	2	1	12301	
6791	2	2	12301	
6792	2	3	12301	
6793	2	4	12301	
6794	2	5	12301	
6795	3	1	12301	
6796	3	2	12301	
6797	3	3	12301	
6798	3	4	12301	
6799	3	5	12301	
6800	0	1	12302	
6801	0	2	12302	
6802	0	3	12302	
6803	0	4	12302	
6804	0	5	12302	
6805	1	1	12302	
6806	1	2	12302	
6807	1	3	12302	
6808	1	4	12302	
6809	1	5	12302	
6810	2	1	12302	
6811	2	2	12302	
6812	2	3	12302	
6813	2	4	12302	
6814	2	5	12302	
6815	3	1	12302	
6816	3	2	12302	
6817	3	3	12302	
6818	3	4	12302	
6819	3	5	12302	
6820	0	1	12304	
6821	0	2	12304	
6822	0	3	12304	
6823	0	4	12304	
6824	0	5	12304	
6825	1	1	12304	
6826	1	2	12304	
6827	1	3	12304	
6828	1	4	12304	
6829	1	5	12304	
6830	2	1	12304	
6831	2	2	12304	
6832	2	3	12304	
6833	2	4	12304	
6834	2	5	12304	
6835	3	1	12304	
6836	3	2	12304	
6837	3	3	12304	
6838	3	4	12304	
6839	3	5	12304	
6840	0	1	12401	
6841	0	2	12401	
6842	0	3	12401	
6843	0	4	12401	
6844	0	5	12401	
6845	1	1	12401	
6846	1	2	12401	
6847	1	3	12401	
6848	1	4	12401	
6849	1	5	12401	
6850	2	1	12401	
6851	2	2	12401	
6852	2	3	12401	
6853	2	4	12401	
6854	2	5	12401	
6855	3	1	12401	
6856	3	2	12401	
6857	3	3	12401	
6858	3	4	12401	
6859	3	5	12401	
6860	0	1	13101	
6861	0	2	13101	
6862	0	3	13101	
6863	0	4	13101	
6864	0	5	13101	
6865	1	1	13101	
6866	1	2	13101	
6867	1	3	13101	
6868	1	4	13101	
6869	1	5	13101	
6870	2	1	13101	
6871	2	2	13101	
6872	2	3	13101	
6873	2	4	13101	
6874	2	5	13101	
6875	3	1	13101	
6876	3	2	13101	
6877	3	3	13101	
6878	3	4	13101	
6879	3	5	13101	
6880	0	1	13134	
6881	0	2	13134	
6882	0	3	13134	
6883	0	4	13134	
6884	0	5	13134	
6885	1	1	13134	
6886	1	2	13134	
6887	1	3	13134	
6888	1	4	13134	
6889	1	5	13134	
6890	2	1	13134	
6891	2	2	13134	
6892	2	3	13134	
6893	2	4	13134	
6894	2	5	13134	
6895	3	1	13134	
6896	3	2	13134	
6897	3	3	13134	
6898	3	4	13134	
6899	3	5	13134	
6900	0	1	13135	
6901	0	2	13135	
6902	0	3	13135	
6903	0	4	13135	
6904	0	5	13135	
6905	1	1	13135	
6906	1	2	13135	
6907	1	3	13135	
6908	1	4	13135	
6909	1	5	13135	
6910	2	1	13135	
6911	2	2	13135	
6912	2	3	13135	
6913	2	4	13135	
6914	2	5	13135	
6915	3	1	13135	
6916	3	2	13135	
6917	3	3	13135	
6918	3	4	13135	
6919	3	5	13135	
6920	0	1	13159	
6921	0	2	13159	
6922	0	3	13159	
6923	0	4	13159	
6924	0	5	13159	
6925	1	1	13159	
6926	1	2	13159	
6927	1	3	13159	
6928	1	4	13159	
6929	1	5	13159	
6930	2	1	13159	
6931	2	2	13159	
6932	2	3	13159	
6933	2	4	13159	
6934	2	5	13159	
6935	3	1	13159	
6936	3	2	13159	
6937	3	3	13159	
6938	3	4	13159	
6939	3	5	13159	
6940	0	1	13167	
6941	0	2	13167	
6942	0	3	13167	
6943	0	4	13167	
6944	0	5	13167	
6945	1	1	13167	
6946	1	2	13167	
6947	1	3	13167	
6948	1	4	13167	
6949	1	5	13167	
6950	2	1	13167	
6951	2	2	13167	
6952	2	3	13167	
6953	2	4	13167	
6954	2	5	13167	
6955	3	1	13167	
6956	3	2	13167	
6957	3	3	13167	
6958	3	4	13167	
6959	3	5	13167	
6960	0	1	14107	
6961	0	2	14107	
6962	0	3	14107	
6963	0	4	14107	
6964	0	5	14107	
6965	1	1	14107	
6966	1	2	14107	
6967	1	3	14107	
6968	1	4	14107	
6969	1	5	14107	
6970	2	1	14107	
6971	2	2	14107	
6972	2	3	14107	
6973	2	4	14107	
6974	2	5	14107	
6975	3	1	14107	
6976	3	2	14107	
6977	3	3	14107	
6978	3	4	14107	
6979	3	5	14107	
6980	0	1	14109	
6981	0	2	14109	
6982	0	3	14109	
6983	0	4	14109	
6984	0	5	14109	
6985	1	1	14109	
6986	1	2	14109	
6987	1	3	14109	
6988	1	4	14109	
6989	1	5	14109	
6990	2	1	14109	
6991	2	2	14109	
6992	2	3	14109	
6993	2	4	14109	
6994	2	5	14109	
6995	3	1	14109	
6996	3	2	14109	
6997	3	3	14109	
6998	3	4	14109	
6999	3	5	14109	
7000	0	1	14111	
7001	0	2	14111	
7002	0	3	14111	
7003	0	4	14111	
7004	0	5	14111	
7005	1	1	14111	
7006	1	2	14111	
7007	1	3	14111	
7008	1	4	14111	
7009	1	5	14111	
7010	2	1	14111	
7011	2	2	14111	
7012	2	3	14111	
7013	2	4	14111	
7014	2	5	14111	
7015	3	1	14111	
7016	3	2	14111	
7017	3	3	14111	
7018	3	4	14111	
7019	3	5	14111	
7020	0	1	14113	
7021	0	2	14113	
7022	0	3	14113	
7023	0	4	14113	
7024	0	5	14113	
7025	1	1	14113	
7026	1	2	14113	
7027	1	3	14113	
7028	1	4	14113	
7029	1	5	14113	
7030	2	1	14113	
7031	2	2	14113	
7032	2	3	14113	
7033	2	4	14113	
7034	2	5	14113	
7035	3	1	14113	
7036	3	2	14113	
7037	3	3	14113	
7038	3	4	14113	
7039	3	5	14113	
7040	0	1	14114	
7041	0	2	14114	
7042	0	3	14114	
7043	0	4	14114	
7044	0	5	14114	
7045	1	1	14114	
7046	1	2	14114	
7047	1	3	14114	
7048	1	4	14114	
7049	1	5	14114	
7050	2	1	14114	
7051	2	2	14114	
7052	2	3	14114	
7053	2	4	14114	
7054	2	5	14114	
7055	3	1	14114	
7056	3	2	14114	
7057	3	3	14114	
7058	3	4	14114	
7059	3	5	14114	
7060	0	1	14127	
7061	0	2	14127	
7062	0	3	14127	
7063	0	4	14127	
7064	0	5	14127	
7065	1	1	14127	
7066	1	2	14127	
7067	1	3	14127	
7068	1	4	14127	
7069	1	5	14127	
7070	2	1	14127	
7071	2	2	14127	
7072	2	3	14127	
7073	2	4	14127	
7074	2	5	14127	
7075	3	1	14127	
7076	3	2	14127	
7077	3	3	14127	
7078	3	4	14127	
7079	3	5	14127	
7080	0	1	14155	
7081	0	2	14155	
7082	0	3	14155	
7083	0	4	14155	
7084	0	5	14155	
7085	1	1	14155	
7086	1	2	14155	
7087	1	3	14155	
7088	1	4	14155	
7089	1	5	14155	
7090	2	1	14155	
7091	2	2	14155	
7092	2	3	14155	
7093	2	4	14155	
7094	2	5	14155	
7095	3	1	14155	
7096	3	2	14155	
7097	3	3	14155	
7098	3	4	14155	
7099	3	5	14155	
7100	0	1	14156	
7101	0	2	14156	
7102	0	3	14156	
7103	0	4	14156	
7104	0	5	14156	
7105	1	1	14156	
7106	1	2	14156	
7107	1	3	14156	
7108	1	4	14156	
7109	1	5	14156	
7110	2	1	14156	
7111	2	2	14156	
7112	2	3	14156	
7113	2	4	14156	
7114	2	5	14156	
7115	3	1	14156	
7116	3	2	14156	
7117	3	3	14156	
7118	3	4	14156	
7119	3	5	14156	
7120	0	1	14157	
7121	0	2	14157	
7122	0	3	14157	
7123	0	4	14157	
7124	0	5	14157	
7125	1	1	14157	
7126	1	2	14157	
7127	1	3	14157	
7128	1	4	14157	
7129	1	5	14157	
7130	2	1	14157	
7131	2	2	14157	
7132	2	3	14157	
7133	2	4	14157	
7134	2	5	14157	
7135	3	1	14157	
7136	3	2	14157	
7137	3	3	14157	
7138	3	4	14157	
7139	3	5	14157	
7140	0	1	14158	
7141	0	2	14158	
7142	0	3	14158	
7143	0	4	14158	
7144	0	5	14158	
7145	1	1	14158	
7146	1	2	14158	
7147	1	3	14158	
7148	1	4	14158	
7149	1	5	14158	
7150	2	1	14158	
7151	2	2	14158	
7152	2	3	14158	
7153	2	4	14158	
7154	2	5	14158	
7155	3	1	14158	
7156	3	2	14158	
7157	3	3	14158	
7158	3	4	14158	
7159	3	5	14158	
7160	0	1	14166	
7161	0	2	14166	
7162	0	3	14166	
7163	0	4	14166	
7164	0	5	14166	
7165	1	1	14166	
7166	1	2	14166	
7167	1	3	14166	
7168	1	4	14166	
7169	1	5	14166	
7170	2	1	14166	
7171	2	2	14166	
7172	2	3	14166	
7173	2	4	14166	
7174	2	5	14166	
7175	3	1	14166	
7176	3	2	14166	
7177	3	3	14166	
7178	3	4	14166	
7179	3	5	14166	
7180	0	1	14201	
7181	0	2	14201	
7182	0	3	14201	
7183	0	4	14201	
7184	0	5	14201	
7185	1	1	14201	
7186	1	2	14201	
7187	1	3	14201	
7188	1	4	14201	
7189	1	5	14201	
7190	2	1	14201	
7191	2	2	14201	
7192	2	3	14201	
7193	2	4	14201	
7194	2	5	14201	
7195	3	1	14201	
7196	3	2	14201	
7197	3	3	14201	
7198	3	4	14201	
7199	3	5	14201	
7200	0	1	14202	
7201	0	2	14202	
7202	0	3	14202	
7203	0	4	14202	
7204	0	5	14202	
7205	1	1	14202	
7206	1	2	14202	
7207	1	3	14202	
7208	1	4	14202	
7209	1	5	14202	
7210	2	1	14202	
7211	2	2	14202	
7212	2	3	14202	
7213	2	4	14202	
7214	2	5	14202	
7215	3	1	14202	
7216	3	2	14202	
7217	3	3	14202	
7218	3	4	14202	
7219	3	5	14202	
7220	0	1	14203	
7221	0	2	14203	
7222	0	3	14203	
7223	0	4	14203	
7224	0	5	14203	
7225	1	1	14203	
7226	1	2	14203	
7227	1	3	14203	
7228	1	4	14203	
7229	1	5	14203	
7230	2	1	14203	
7231	2	2	14203	
7232	2	3	14203	
7233	2	4	14203	
7234	2	5	14203	
7235	3	1	14203	
7236	3	2	14203	
7237	3	3	14203	
7238	3	4	14203	
7239	3	5	14203	
7240	0	1	14501	
7241	0	2	14501	
7242	0	3	14501	
7243	0	4	14501	
7244	0	5	14501	
7245	1	1	14501	
7246	1	2	14501	
7247	1	3	14501	
7248	1	4	14501	
7249	1	5	14501	
7250	2	1	14501	
7251	2	2	14501	
7252	2	3	14501	
7253	2	4	14501	
7254	2	5	14501	
7255	3	1	14501	
7256	3	2	14501	
7257	3	3	14501	
7258	3	4	14501	
7259	3	5	14501	
7260	0	1	14502	
7261	0	2	14502	
7262	0	3	14502	
7263	0	4	14502	
7264	0	5	14502	
7265	1	1	14502	
7266	1	2	14502	
7267	1	3	14502	
7268	1	4	14502	
7269	1	5	14502	
7270	2	1	14502	
7271	2	2	14502	
7272	2	3	14502	
7273	2	4	14502	
7274	2	5	14502	
7275	3	1	14502	
7276	3	2	14502	
7277	3	3	14502	
7278	3	4	14502	
7279	3	5	14502	
7280	0	1	14503	
7281	0	2	14503	
7282	0	3	14503	
7283	0	4	14503	
7284	0	5	14503	
7285	1	1	14503	
7286	1	2	14503	
7287	1	3	14503	
7288	1	4	14503	
7289	1	5	14503	
7290	2	1	14503	
7291	2	2	14503	
7292	2	3	14503	
7293	2	4	14503	
7294	2	5	14503	
7295	3	1	14503	
7296	3	2	14503	
7297	3	3	14503	
7298	3	4	14503	
7299	3	5	14503	
7300	0	1	14504	
7301	0	2	14504	
7302	0	3	14504	
7303	0	4	14504	
7304	0	5	14504	
7305	1	1	14504	
7306	1	2	14504	
7307	1	3	14504	
7308	1	4	14504	
7309	1	5	14504	
7310	2	1	14504	
7311	2	2	14504	
7312	2	3	14504	
7313	2	4	14504	
7314	2	5	14504	
7315	3	1	14504	
7316	3	2	14504	
7317	3	3	14504	
7318	3	4	14504	
7319	3	5	14504	
7320	0	1	14505	
7321	0	2	14505	
7322	0	3	14505	
7323	0	4	14505	
7324	0	5	14505	
7325	1	1	14505	
7326	1	2	14505	
7327	1	3	14505	
7328	1	4	14505	
7329	1	5	14505	
7330	2	1	14505	
7331	2	2	14505	
7332	2	3	14505	
7333	2	4	14505	
7334	2	5	14505	
7335	3	1	14505	
7336	3	2	14505	
7337	3	3	14505	
7338	3	4	14505	
7339	3	5	14505	
7340	0	1	14601	
7341	0	2	14601	
7342	0	3	14601	
7343	0	4	14601	
7344	0	5	14601	
7345	1	1	14601	
7346	1	2	14601	
7347	1	3	14601	
7348	1	4	14601	
7349	1	5	14601	
7350	2	1	14601	
7351	2	2	14601	
7352	2	3	14601	
7353	2	4	14601	
7354	2	5	14601	
7355	3	1	14601	
7356	3	2	14601	
7357	3	3	14601	
7358	3	4	14601	
7359	3	5	14601	
7360	0	1	14602	
7361	0	2	14602	
7362	0	3	14602	
7363	0	4	14602	
7364	0	5	14602	
7365	1	1	14602	
7366	1	2	14602	
7367	1	3	14602	
7368	1	4	14602	
7369	1	5	14602	
7370	2	1	14602	
7371	2	2	14602	
7372	2	3	14602	
7373	2	4	14602	
7374	2	5	14602	
7375	3	1	14602	
7376	3	2	14602	
7377	3	3	14602	
7378	3	4	14602	
7379	3	5	14602	
7380	0	1	14603	
7381	0	2	14603	
7382	0	3	14603	
7383	0	4	14603	
7384	0	5	14603	
7385	1	1	14603	
7386	1	2	14603	
7387	1	3	14603	
7388	1	4	14603	
7389	1	5	14603	
7390	2	1	14603	
7391	2	2	14603	
7392	2	3	14603	
7393	2	4	14603	
7394	2	5	14603	
7395	3	1	14603	
7396	3	2	14603	
7397	3	3	14603	
7398	3	4	14603	
7399	3	5	14603	
7400	0	1	14604	
7401	0	2	14604	
7402	0	3	14604	
7403	0	4	14604	
7404	0	5	14604	
7405	1	1	14604	
7406	1	2	14604	
7407	1	3	14604	
7408	1	4	14604	
7409	1	5	14604	
7410	2	1	14604	
7411	2	2	14604	
7412	2	3	14604	
7413	2	4	14604	
7414	2	5	14604	
7415	3	1	14604	
7416	3	2	14604	
7417	3	3	14604	
7418	3	4	14604	
7419	3	5	14604	
7420	0	1	14605	
7421	0	2	14605	
7422	0	3	14605	
7423	0	4	14605	
7424	0	5	14605	
7425	1	1	14605	
7426	1	2	14605	
7427	1	3	14605	
7428	1	4	14605	
7429	1	5	14605	
7430	2	1	14605	
7431	2	2	14605	
7432	2	3	14605	
7433	2	4	14605	
7434	2	5	14605	
7435	3	1	14605	
7436	3	2	14605	
7437	3	3	14605	
7438	3	4	14605	
7439	3	5	14605	
7440	0	1	15103	
7441	0	2	15103	
7442	0	3	15103	
7443	0	4	15103	
7444	0	5	15103	
7445	1	1	15103	
7446	1	2	15103	
7447	1	3	15103	
7448	1	4	15103	
7449	1	5	15103	
7450	2	1	15103	
7451	2	2	15103	
7452	2	3	15103	
7453	2	4	15103	
7454	2	5	15103	
7455	3	1	15103	
7456	3	2	15103	
7457	3	3	15103	
7458	3	4	15103	
7459	3	5	15103	
7460	0	1	15105	
7461	0	2	15105	
7462	0	3	15105	
7463	0	4	15105	
7464	0	5	15105	
7465	1	1	15105	
7466	1	2	15105	
7467	1	3	15105	
7468	1	4	15105	
7469	1	5	15105	
7470	2	1	15105	
7471	2	2	15105	
7472	2	3	15105	
7473	2	4	15105	
7474	2	5	15105	
7475	3	1	15105	
7476	3	2	15105	
7477	3	3	15105	
7478	3	4	15105	
7479	3	5	15105	
7480	0	1	15108	
7481	0	2	15108	
7482	0	3	15108	
7483	0	4	15108	
7484	0	5	15108	
7485	1	1	15108	
7486	1	2	15108	
7487	1	3	15108	
7488	1	4	15108	
7489	1	5	15108	
7490	2	1	15108	
7491	2	2	15108	
7492	2	3	15108	
7493	2	4	15108	
7494	2	5	15108	
7495	3	1	15108	
7496	3	2	15108	
7497	3	3	15108	
7498	3	4	15108	
7499	3	5	15108	
7500	0	1	15128	
7501	0	2	15128	
7502	0	3	15128	
7503	0	4	15128	
7504	0	5	15128	
7505	1	1	15128	
7506	1	2	15128	
7507	1	3	15128	
7508	1	4	15128	
7509	1	5	15128	
7510	2	1	15128	
7511	2	2	15128	
7512	2	3	15128	
7513	2	4	15128	
7514	2	5	15128	
7515	3	1	15128	
7516	3	2	15128	
7517	3	3	15128	
7518	3	4	15128	
7519	3	5	15128	
7520	0	1	15132	
7521	0	2	15132	
7522	0	3	15132	
7523	0	4	15132	
7524	0	5	15132	
7525	1	1	15132	
7526	1	2	15132	
7527	1	3	15132	
7528	1	4	15132	
7529	1	5	15132	
7530	2	1	15132	
7531	2	2	15132	
7532	2	3	15132	
7533	2	4	15132	
7534	2	5	15132	
7535	3	1	15132	
7536	3	2	15132	
7537	3	3	15132	
7538	3	4	15132	
7539	3	5	15132	
7540	0	1	15151	
7541	0	2	15151	
7542	0	3	15151	
7543	0	4	15151	
7544	0	5	15151	
7545	1	1	15151	
7546	1	2	15151	
7547	1	3	15151	
7548	1	4	15151	
7549	1	5	15151	
7550	2	1	15151	
7551	2	2	15151	
7552	2	3	15151	
7553	2	4	15151	
7554	2	5	15151	
7555	3	1	15151	
7556	3	2	15151	
7557	3	3	15151	
7558	3	4	15151	
7559	3	5	15151	
7560	0	1	15152	
7561	0	2	15152	
7562	0	3	15152	
7563	0	4	15152	
7564	0	5	15152	
7565	1	1	15152	
7566	1	2	15152	
7567	1	3	15152	
7568	1	4	15152	
7569	1	5	15152	
7570	2	1	15152	
7571	2	2	15152	
7572	2	3	15152	
7573	2	4	15152	
7574	2	5	15152	
7575	3	1	15152	
7576	3	2	15152	
7577	3	3	15152	
7578	3	4	15152	
7579	3	5	15152	
7580	0	1	15160	
7581	0	2	15160	
7582	0	3	15160	
7583	0	4	15160	
7584	0	5	15160	
7585	1	1	15160	
7586	1	2	15160	
7587	1	3	15160	
7588	1	4	15160	
7589	1	5	15160	
7590	2	1	15160	
7591	2	2	15160	
7592	2	3	15160	
7593	2	4	15160	
7594	2	5	15160	
7595	3	1	15160	
7596	3	2	15160	
7597	3	3	15160	
7598	3	4	15160	
7599	3	5	15160	
7600	0	1	15161	
7601	0	2	15161	
7602	0	3	15161	
7603	0	4	15161	
7604	0	5	15161	
7605	1	1	15161	
7606	1	2	15161	
7607	1	3	15161	
7608	1	4	15161	
7609	1	5	15161	
7610	2	1	15161	
7611	2	2	15161	
7612	2	3	15161	
7613	2	4	15161	
7614	2	5	15161	
7615	3	1	15161	
7616	3	2	15161	
7617	3	3	15161	
7618	3	4	15161	
7619	3	5	15161	
7620	0	1	16106	
7621	0	2	16106	
7622	0	3	16106	
7623	0	4	16106	
7624	0	5	16106	
7625	1	1	16106	
7626	1	2	16106	
7627	1	3	16106	
7628	1	4	16106	
7629	1	5	16106	
7630	2	1	16106	
7631	2	2	16106	
7632	2	3	16106	
7633	2	4	16106	
7634	2	5	16106	
7635	3	1	16106	
7636	3	2	16106	
7637	3	3	16106	
7638	3	4	16106	
7639	3	5	16106	
7640	0	1	16110	
7641	0	2	16110	
7642	0	3	16110	
7643	0	4	16110	
7644	0	5	16110	
7645	1	1	16110	
7646	1	2	16110	
7647	1	3	16110	
7648	1	4	16110	
7649	1	5	16110	
7650	2	1	16110	
7651	2	2	16110	
7652	2	3	16110	
7653	2	4	16110	
7654	2	5	16110	
7655	3	1	16110	
7656	3	2	16110	
7657	3	3	16110	
7658	3	4	16110	
7659	3	5	16110	
7660	0	1	16131	
7661	0	2	16131	
7662	0	3	16131	
7663	0	4	16131	
7664	0	5	16131	
7665	1	1	16131	
7666	1	2	16131	
7667	1	3	16131	
7668	1	4	16131	
7669	1	5	16131	
7670	2	1	16131	
7671	2	2	16131	
7672	2	3	16131	
7673	2	4	16131	
7674	2	5	16131	
7675	3	1	16131	
7676	3	2	16131	
7677	3	3	16131	
7678	3	4	16131	
7679	3	5	16131	
7680	0	1	16153	
7681	0	2	16153	
7682	0	3	16153	
7683	0	4	16153	
7684	0	5	16153	
7685	1	1	16153	
7686	1	2	16153	
7687	1	3	16153	
7688	1	4	16153	
7689	1	5	16153	
7690	2	1	16153	
7691	2	2	16153	
7692	2	3	16153	
7693	2	4	16153	
7694	2	5	16153	
7695	3	1	16153	
7696	3	2	16153	
7697	3	3	16153	
7698	3	4	16153	
7699	3	5	16153	
7700	0	1	16154	
7701	0	2	16154	
7702	0	3	16154	
7703	0	4	16154	
7704	0	5	16154	
7705	1	1	16154	
7706	1	2	16154	
7707	1	3	16154	
7708	1	4	16154	
7709	1	5	16154	
7710	2	1	16154	
7711	2	2	16154	
7712	2	3	16154	
7713	2	4	16154	
7714	2	5	16154	
7715	3	1	16154	
7716	3	2	16154	
7717	3	3	16154	
7718	3	4	16154	
7719	3	5	16154	
7720	0	1	16162	
7721	0	2	16162	
7722	0	3	16162	
7723	0	4	16162	
7724	0	5	16162	
7725	1	1	16162	
7726	1	2	16162	
7727	1	3	16162	
7728	1	4	16162	
7729	1	5	16162	
7730	2	1	16162	
7731	2	2	16162	
7732	2	3	16162	
7733	2	4	16162	
7734	2	5	16162	
7735	3	1	16162	
7736	3	2	16162	
7737	3	3	16162	
7738	3	4	16162	
7739	3	5	16162	
7740	0	1	16163	
7741	0	2	16163	
7742	0	3	16163	
7743	0	4	16163	
7744	0	5	16163	
7745	1	1	16163	
7746	1	2	16163	
7747	1	3	16163	
7748	1	4	16163	
7749	1	5	16163	
7750	2	1	16163	
7751	2	2	16163	
7752	2	3	16163	
7753	2	4	16163	
7754	2	5	16163	
7755	3	1	16163	
7756	3	2	16163	
7757	3	3	16163	
7758	3	4	16163	
7759	3	5	16163	
7760	0	1	16164	
7761	0	2	16164	
7762	0	3	16164	
7763	0	4	16164	
7764	0	5	16164	
7765	1	1	16164	
7766	1	2	16164	
7767	1	3	16164	
7768	1	4	16164	
7769	1	5	16164	
7770	2	1	16164	
7771	2	2	16164	
7772	2	3	16164	
7773	2	4	16164	
7774	2	5	16164	
7775	3	1	16164	
7776	3	2	16164	
7777	3	3	16164	
7778	3	4	16164	
7779	3	5	16164	
7780	0	1	16165	
7781	0	2	16165	
7782	0	3	16165	
7783	0	4	16165	
7784	0	5	16165	
7785	1	1	16165	
7786	1	2	16165	
7787	1	3	16165	
7788	1	4	16165	
7789	1	5	16165	
7790	2	1	16165	
7791	2	2	16165	
7792	2	3	16165	
7793	2	4	16165	
7794	2	5	16165	
7795	3	1	16165	
7796	3	2	16165	
7797	3	3	16165	
7798	3	4	16165	
7799	3	5	16165	
7800	0	1	16301	
7801	0	2	16301	
7802	0	3	16301	
7803	0	4	16301	
7804	0	5	16301	
7805	1	1	16301	
7806	1	2	16301	
7807	1	3	16301	
7808	1	4	16301	
7809	1	5	16301	
7810	2	1	16301	
7811	2	2	16301	
7812	2	3	16301	
7813	2	4	16301	
7814	2	5	16301	
7815	3	1	16301	
7816	3	2	16301	
7817	3	3	16301	
7818	3	4	16301	
7819	3	5	16301	
7820	0	1	16302	
7821	0	2	16302	
7822	0	3	16302	
7823	0	4	16302	
7824	0	5	16302	
7825	1	1	16302	
7826	1	2	16302	
7827	1	3	16302	
7828	1	4	16302	
7829	1	5	16302	
7830	2	1	16302	
7831	2	2	16302	
7832	2	3	16302	
7833	2	4	16302	
7834	2	5	16302	
7835	3	1	16302	
7836	3	2	16302	
7837	3	3	16302	
7838	3	4	16302	
7839	3	5	16302	
7840	0	1	16303	
7841	0	2	16303	
7842	0	3	16303	
7843	0	4	16303	
7844	0	5	16303	
7845	1	1	16303	
7846	1	2	16303	
7847	1	3	16303	
7848	1	4	16303	
7849	1	5	16303	
7850	2	1	16303	
7851	2	2	16303	
7852	2	3	16303	
7853	2	4	16303	
7854	2	5	16303	
7855	3	1	16303	
7856	3	2	16303	
7857	3	3	16303	
7858	3	4	16303	
7859	3	5	16303	
7860	0	1	16401	
7861	0	2	16401	
7862	0	3	16401	
7863	0	4	16401	
7864	0	5	16401	
7865	1	1	16401	
7866	1	2	16401	
7867	1	3	16401	
7868	1	4	16401	
7869	1	5	16401	
7870	2	1	16401	
7871	2	2	16401	
7872	2	3	16401	
7873	2	4	16401	
7874	2	5	16401	
7875	3	1	16401	
7876	3	2	16401	
7877	3	3	16401	
7878	3	4	16401	
7879	3	5	16401	
7880	0	1	16402	
7881	0	2	16402	
7882	0	3	16402	
7883	0	4	16402	
7884	0	5	16402	
7885	1	1	16402	
7886	1	2	16402	
7887	1	3	16402	
7888	1	4	16402	
7889	1	5	16402	
7890	2	1	16402	
7891	2	2	16402	
7892	2	3	16402	
7893	2	4	16402	
7894	2	5	16402	
7895	3	1	16402	
7896	3	2	16402	
7897	3	3	16402	
7898	3	4	16402	
7899	3	5	16402	
7900	0	1	16403	
7901	0	2	16403	
7902	0	3	16403	
7903	0	4	16403	
7904	0	5	16403	
7905	1	1	16403	
7906	1	2	16403	
7907	1	3	16403	
7908	1	4	16403	
7909	1	5	16403	
7910	2	1	16403	
7911	2	2	16403	
7912	2	3	16403	
7913	2	4	16403	
7914	2	5	16403	
7915	3	1	16403	
7916	3	2	16403	
7917	3	3	16403	
7918	3	4	16403	
7919	3	5	16403	
7920	0	1	16404	
7921	0	2	16404	
7922	0	3	16404	
7923	0	4	16404	
7924	0	5	16404	
7925	1	1	16404	
7926	1	2	16404	
7927	1	3	16404	
7928	1	4	16404	
7929	1	5	16404	
7930	2	1	16404	
7931	2	2	16404	
7932	2	3	16404	
7933	2	4	16404	
7934	2	5	16404	
7935	3	1	16404	
7936	3	2	16404	
7937	3	3	16404	
7938	3	4	16404	
7939	3	5	16404	
\.


--
-- TOC entry 3598 (class 0 OID 65904)
-- Dependencies: 248
-- Data for Name: cuerpos_aterramiento; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.cuerpos_aterramiento (id, nombre) FROM stdin;
1	1
\.


--
-- TOC entry 3579 (class 0 OID 24703)
-- Dependencies: 219
-- Data for Name: detalle_ensayo; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.detalle_ensayo (id_detalle, id_batea, serie_epp, aprobado, detalle) FROM stdin;
1	7071	1	t	{"detalle":[{"parches":"1", "fuga1":"2", "fuga2":"3", "fuga3":"4", "promedio":"3", "resultado":"APROBADO"},{"parches":"2", "fuga1":"2", "fuga2":"3", "fuga3":"4", "promedio":"3", "resultado":"APROBADO"},{"parches":"3", "fuga1":"2", "fuga2":"3", "fuga3":"4", "promedio":"3", "resultado":"APROBADO"}]}
7997	7984	7991	t	{"serie_epp":"GNT-00678","fuga1":"2","fuga2":"3","fuga3":"4","parches":"1","promedio":"3.00","tension":"5","resultado":"APROBADO"}
7998	7984	7992	t	{"serie_epp":"GNT-00679","fuga1":"4","fuga2":"2","fuga3":"1","parches":"2","promedio":"2.33","tension":"4","resultado":"APROBADO"}
8039	7999	8037	t	{"serie_epp":"GNT-00684","fuga1":"1","fuga2":"1","fuga3":"1","parches":"0","promedio":"1.00","tension":"10","resultado":"APROBADO"}
8040	7999	7991	t	{"serie_epp":"GNT-00678","fuga1":"1","fuga2":"1","fuga3":"1","parches":"1","promedio":"1.00","tension":"4","resultado":"APROBADO"}
8041	7999	7992	f	{"serie_epp":"GNT-00679","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8042	7999	8028	t	{"serie_epp":"GNT-00682","fuga1":"1","fuga2":"1","fuga3":"1","parches":"0","promedio":"1.00","tension":"5","resultado":"APROBADO"}
8057	8051	7992	f	{"serie_epp":"GNT-00679","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8058	8051	7993	f	{"serie_epp":"GNT-00680","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8059	8051	8027	f	{"serie_epp":"GNT-00681","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8060	8051	8028	f	{"serie_epp":"GNT-00682","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8061	8051	8036	f	{"serie_epp":"GNT-00683","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8062	8051	8037	f	{"serie_epp":"GNT-00684","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8063	8051	8038	f	{"serie_epp":"GNT-00685","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8064	8051	8052	f	{"serie_epp":"GNT-00686","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8065	8051	8053	f	{"serie_epp":"GNT-00687","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8066	8051	8054	f	{"serie_epp":"GNT-00688","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8067	8051	8055	f	{"serie_epp":"GNT-00689","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8070	8069	8055	t	{"serie_epp":"GNT-00689","fuga1":"2","fuga2":"2","fuga3":"2","parches":"1","promedio":"2.00","tension":"10","resultado":"APROBADO"}
8075	8071	8055	f	{"serie_epp":"GNT-00689","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8076	8071	8037	t	{"serie_epp":"GNT-00684","fuga1":"2","fuga2":"3","fuga3":"1","parches":"1","promedio":"2.00","tension":"10","resultado":"APROBADO"}
8077	8071	8038	f	{"serie_epp":"GNT-00685","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8082	8079	7992	f	{"serie_epp":"GNT-00679","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8083	8079	8037	f	{"serie_epp":"GNT-00684","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8084	8079	8055	t	{"serie_epp":"GNT-00689","fuga1":"1","fuga2":"2","fuga3":"3","parches":"1","promedio":"2.00","tension":"10","resultado":"APROBADO"}
8087	8086	8037	t	{"serie_epp":"GNT-00684","fuga1":"2","fuga2":"2","fuga3":"3","parches":"1","promedio":"2.33","tension":"10","resultado":"APROBADO"}
8088	8086	8038	f	{"serie_epp":"GNT-00685","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8126	8122	8123	t	{"serie_epp":"BNQ-00001","fuga1":"5","parches":"0","tension":"10","resultado":"APROBADO"}
8127	8117	8119	t	{"serie_epp":"MNT-00002","fuga1":"3","parches":"1","tension":"12","resultado":"APROBADO"}
8128	8116	8053	f	{"serie_epp":"GNT-00687","fuga1":"5","parches":"0","tension":"10","resultado":"RECHAZADO"}
8132	8129	8131	t	{"serie_epp":"ATR-00003","fuga1":"5","parches":"0","tension":"10","resultado":"APROBADO"}
8133	8129	8130	f	{"serie_epp":"ATR-00002","fuga1":"--","parches":"--","tension":"--","resultado":"RECHAZADO"}
8134	8129	8089	t	{"serie_epp":"ATR-00001","fuga1":"5","parches":"0","tension":"10","resultado":"APROBADO"}
8136	8106	8092	t	{"serie_epp":"MNG-00002","fuga1":"23","parches":"0","tension":"10","resultado":"APROBADO"}
8137	8106	8095	t	{"serie_epp":"MNG-00003","fuga1":"34","parches":"0","tension":"10","resultado":"APROBADO"}
8142	8141	8140	t	{"serie_epp":"PRT-00003","fuga1":"57","parches":"0","tension":"12","resultado":"APROBADO"}
8143	8141	8139	t	{"serie_epp":"PRT-00002","fuga1":"112","parches":"0","tension":"12","resultado":"APROBADO"}
8144	8141	8138	t	{"serie_epp":"PRT-00001","fuga1":"123","parches":"0","tension":"12","resultado":"APROBADO"}
\.


--
-- TOC entry 3576 (class 0 OID 16474)
-- Dependencies: 210
-- Data for Name: encabezado_ensayo; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.encabezado_ensayo (id_batea, cod_ensayo, temperatura, humedad, tecnico, fecha, patron, estado, tipo_ensayo, fecha_ejecucion, fecha_emision, cliente_n_s, fecha_ingreso, cod_estado, cod_patron, orden_compra) FROM stdin;
7965	LAT-GNT-125	21	30	1	2022-06-22 20:16:54.541929	1	ingreso	1	\N	\N	3426	\N	1	1	OC-7965
7966	LAT-GNT-126	20	30	2	2022-06-23 15:06:34.711695	1	ingreso	1	\N	\N	1635	\N	1	1	OC-7966
7967	LAT-GNT-127	21	34	2	2022-06-23 15:18:51.984371	2	ingreso	1	\N	\N	5867	\N	1	2	OC-7967
7968	LAT-GNT-128	25	30	2	2022-06-23 16:24:47.542463	1	ingreso	1	\N	\N	1013	\N	1	1	OC-7968
7969	LAT-GNT-129	23	60	2	2022-06-23 17:36:25.663116	1	ingreso	1	\N	\N	1626	\N	1	1	OC-7969
7970	LAT-GNT-130	12	12	1	2022-06-24 12:28:39.745299	1	ingreso	1	\N	\N	1046	\N	1	1	OC-7970
7971	LAT-GNT-00131	13	24	2	2022-06-25 18:18:18.068948	2	ingreso	1	\N	\N	5869	\N	1	2	OC-7971
7972	LAT-GNT-00132	99	99	3	2022-06-25 18:39:03.424028	2	ingreso	1	\N	\N	1620	\N	1	2	OC-7972
7974	LAT-GNT-00133	89	20	1	2022-06-25 18:52:16.203023	1	ingreso	1	2022-06-10	\N	2800	2022-06-23	1	1	OC-7974
7975	LAT-GNT-00134	14	14	2	2022-06-25 18:55:42.414368	1	ingreso	1	\N	\N	1051	\N	1	1	OC-7975
7976	LAT-GNT-00135	11	11	2	2022-06-25 18:57:15.72688	2	ingreso	1	2022-06-28	\N	3426	2022-06-27	1	2	OC-7976
7977	LAT-GNT-00136	34	34	2	2022-06-26 11:45:32.018391	2	ingreso	1	2022-06-23	\N	6476	2022-06-22	1	2	OC-7977
7982	LAT-GNT-00137	22	22	2	2022-06-26 17:11:35.460726	1	ingreso	1	2022-06-24	\N	1168	2022-06-23	1	1	OC-7982
8043	LAT-GNT-00141	20	30	1	2022-07-05 18:05:15.753354	2	ingreso	1	2022-07-01	\N	2037	2022-07-01	1	1	OC-8043
8035	LAT-GNT-00140	12	12	1	2022-06-30 20:03:32.662131	1	ingreso	1	2022-06-30	\N	5157	2022-06-29	2	1	OC-8035
7984	LAT-GNT-00138	1	1	1	2022-06-26 17:28:32.370987	1	ingreso	1	2022-06-25	2022-06-30	1277	2022-06-24	2	1	OC-7984
8044	LAT-GNT-00142	20	30	2	2022-07-05 18:19:19.860732	2	ingreso	1	2022-07-05	\N	7302	2022-07-04	1	2	OC-8044
8045	LAT-GNT-00143	34	34	2	2022-07-05 18:42:01.686268	2	ingreso	1	2022-07-05	\N	3315	2022-07-01	1	1	OC-8045
8046	LAT-GNT-00144	12	12	2	2022-07-05 18:44:01.036935	2	ingreso	1	2022-07-01	\N	6001	2022-07-01	1	2	OC-8046
8047	LAT-GNT-00145	23	23	2	2022-07-05 18:44:26.874955	2	ingreso	1	2022-07-05	\N	4976	2022-07-02	1	1	OC-8047
8048	LAT-GNT-00146	15	15	2	2022-07-05 19:06:18.848925	1	ingreso	1	2022-07-05	\N	4435	2022-07-05	1	2	OC-8048
7999	LAT-GNT-00139	20	60	1	2022-06-30 13:36:34.946971	1	ingreso	1	2022-06-30	2022-06-30	1260	2022-06-29	2	1	OC-7999
8049	LAT-GNT-00147	14	25	1	2022-07-05 19:06:54.503451	1	ingreso	1	2022-07-05	\N	7817	2022-07-05	1	1	OC-8049
8050	LAT-GNT-00148	23	23	1	2022-07-05 19:09:33.336003	1	ingreso	1	2022-07-04	\N	2377	2022-07-04	1	2	OC-8050
8051	LAT-GNT-00149	22	22	1	2022-07-05 19:12:05.964416	1	ingreso	1	2022-07-04	\N	2697	2022-07-04	2	1	OC-8051
8069	LAT-GNT-00150	20	21	2	2022-07-06 11:40:41.437904	1	ingreso	1	2022-07-06	2022-07-06	1002	2022-07-06	3	1	OC-8069
8086	LAT-GNT-00153	21	21	1	2022-07-06 12:34:05.560884	2	ingreso	1	2022-07-06	2022-07-06	7917	2022-07-06	3	2	OC-8086
8099	LAT-GNT-00154	30	25	1	2022-07-08 16:52:24.632293	1	ingreso	1	2022-07-07	\N	7902	2022-07-07	1	1	OC-8099
8100	LAT-GNT-00155	15	15	1	2022-07-08 16:52:57.568808	2	ingreso	1	2022-07-07	\N	1357	2022-07-07	1	2	OC-8100
8101	LAT-GNT-00156	15	12	1	2022-07-08 16:54:14.356798	1	ingreso	1	2022-07-08	\N	1262	2022-07-08	1	1	OC-8101
8102	LAT-GNT-00157	20	20	1	2022-07-08 17:40:50.125987	2	ingreso	1	2022-07-08	\N	7422	2022-07-07	1	2	OC-8102
8104	LAT-MNG-00001	20	20	1	2022-07-08 19:51:37.462798	1	ingreso	1	2022-07-08	\N	7437	2022-07-08	1	1	OC-8104
8105	LAT-MNG-00002	21	12	1	2022-07-08 20:08:38.930694	1	ingreso	1	2022-07-08	\N	4962	2022-07-08	1	1	OC-8105
8071	LAT-GNT-00151	21	22	1	2022-07-06 11:45:32.286698	1	ingreso	1	2022-07-06	\N	7902	2022-07-05	2	1	OC-8071
8079	LAT-GNT-00152	15	20	3	2022-07-06 12:12:08.845749	2	ingreso	1	2022-07-06	2022-07-06	7915	2022-07-06	3	2	OC-8079
7963	LAT-GNT-123	35	30	2	2022-06-22 19:54:08.269306	1	ingreso	1	\N	\N	2656	\N	1	1	OC-7963
7964	LAT-GNT-124	35	30	2	2022-06-22 19:54:10.524559	1	ingreso	1	\N	\N	2656	\N	1	1	OC-7964
8122	LAT-BNQ-00001	20	20	2	2022-07-20 20:59:20.153973	2	ingreso	6	2022-07-22	\N	1582	2022-07-22	2	2	OC-345
8117	LAT-MNT-00001	21	21	1	2022-07-15 19:08:18.056931	1	ingreso	5	2022-07-15	\N	7917	2022-07-15	2	1	oc-432
8116	LAT-GNT-00158	21	21	2	2022-07-13 21:19:52.595001	1	ingreso	1	2022-07-13	\N	6296	2022-07-13	2	1	OC-345
8129	LAT-ATR-00001	20	20	5	2022-07-23 22:19:37.967433	1	ingreso	7	2022-07-15	\N	1042	2022-07-15	2	1	OC-3687
8106	LAT-MNG-00003	23	23	1	2022-07-08 20:21:39.983645	1	ingreso	4	2022-07-08	\N	6282	2022-07-08	2	1	OC-8106
8141	LAT-PRT-00001	21	21	5	2022-07-24 00:23:09.500848	2	ingreso	8	2022-07-16	\N	1057	2022-07-16	2	2	OC-1245
8145	LAT-GNT-00159	21	11	7	2022-07-24 21:46:30.119373	1	ingreso	1	2022-07-22	\N	4977	2022-07-22	1	1	45678
\.


--
-- TOC entry 3578 (class 0 OID 24695)
-- Dependencies: 218
-- Data for Name: ensayos_tipo; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.ensayos_tipo (id_ensayo_tipo, descripcion, cod_informe, habilitado) FROM stdin;
1	guantes	LAT-GNT	t
4	manguillas	LAT-MNG	t
9	jumper	LAT-JMP	f
5	mantas	LAT-MNT	t
7	aterramiento	LAT-ATR	t
8	pértiga	LAT-PRT	t
2	loadbuster	LAT-LDB	f
3	cubre_línea	LAT-CBL	f
6	banqueta	LAT-BNQ	f
\.


--
-- TOC entry 3586 (class 0 OID 24824)
-- Dependencies: 229
-- Data for Name: epps; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.epps (id_epp, serie_epp, clase_epp, tipo_epp, cliente_n_s, estado_epp, periodicidad, estado_uso) FROM stdin;
8098	MNG-00005	2	5	6857	3	6	2
8096	MNG-00004	2	6	6857	3	6	2
8114	MNT-00001	3	1	4897	3	6	2
8097	GNT-00697	1	6	1357	3	6	2
8123	BNQ-00001	5	1	4157	1	6	2
8119	MNT-00002	3	3	6857	1	10	2
8053	GNT-00687	1	6	7917	1	6	2
8131	ATR-00003	7	1	1042	1	6	2
8130	ATR-00002	7	1	1042	1	6	2
8089	ATR-00001	7	2	5625	1	6	2
8092	MNG-00002	2	4	4897	1	6	2
8095	MNG-00003	2	1	4882	1	6	2
8140	PRT-00003	8	1	1042	1	6	2
8139	PRT-00002	8	1	1042	1	6	2
8138	PRT-00001	8	1	1042	1	6	2
7991	GNT-00678	1	6	4892	0	6	2
7992	GNT-00679	1	1	1357	0	6	2
7993	GNT-00680	1	3	7900	0	6	2
8027	GNT-00681	1	1	5215	0	6	2
8028	GNT-00682	1	6	6462	0	6	2
8036	GNT-00683	1	6	6462	0	6	2
8037	GNT-00684	1	1	4142	0	6	2
8038	GNT-00685	1	1	4575	0	6	2
8052	GNT-00686	1	5	1017	0	6	2
8054	GNT-00688	1	4	1357	0	6	2
8055	GNT-00689	1	1	6857	0	6	2
8056	GNT-00690	1	1	4897	0	6	2
8068	GNT-00691	1	2	1342	0	6	2
8078	GNT-00692	1	2	3495	0	6	2
8090	MNG-00001	2	4	4882	0	6	2
8094	GNT-00696	1	1	4142	0	6	2
8115	CBL-00001	4	1	1342	0	6	2
8091	GNT-00694	1	5	6857	3	6	2
8093	GNT-00695	1	1	4997	3	6	2
8085	GNT-00693	1	6	1355	3	6	2
\.


--
-- TOC entry 3577 (class 0 OID 16541)
-- Dependencies: 216
-- Data for Name: estado_ensayo; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.estado_ensayo (id_estado, nombre, observacion) FROM stdin;
0	SIN ESTADO	NO UTILIZADO
1	Ingreso	Estado inicial una vez que se graba un ensayo
2	En revisión	Estado que indica que el ensayo está siendo editado aún
3	Cert. Emitido	Estado que indica que ya se emitió el certificado para el ensayo, no es posible volver a editarlo
\.


--
-- TOC entry 3583 (class 0 OID 24753)
-- Dependencies: 223
-- Data for Name: estado_epp; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.estado_epp (id_estado_epp, descripcion) FROM stdin;
0	ingresado
1	en ensayo
2	cert. emitido
3	de baja
\.


--
-- TOC entry 3594 (class 0 OID 57633)
-- Dependencies: 242
-- Data for Name: estado_uso; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.estado_uso (id, nombre_estado) FROM stdin;
1	usado
2	nuevo
\.


--
-- TOC entry 3597 (class 0 OID 65830)
-- Dependencies: 247
-- Data for Name: largo_cubrelinea; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.largo_cubrelinea (id, nombre) FROM stdin;
1	RÍGIDO
2	FLEXIBLE
\.


--
-- TOC entry 3585 (class 0 OID 24800)
-- Dependencies: 225
-- Data for Name: largo_guante; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.largo_guante (id_largo, valor) FROM stdin;
1	280
2	360
3	410
\.


--
-- TOC entry 3596 (class 0 OID 65809)
-- Dependencies: 246
-- Data for Name: largo_manta; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.largo_manta (id, nombre) FROM stdin;
1	ENTERA
2	PARTIDA
\.


--
-- TOC entry 3601 (class 0 OID 65959)
-- Dependencies: 251
-- Data for Name: largo_pertiga; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.largo_pertiga (id, nombre) FROM stdin;
1	1 de 3
2	1 de 7
\.


--
-- TOC entry 3584 (class 0 OID 24792)
-- Dependencies: 224
-- Data for Name: marca; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.marca (id_marca, nombre) FROM stdin;
1	Salisbury
2	Novax
3	Chance
4	Regeltex
5	Hastings
99	--
6	Ritz
7	Coofeste
8	SYC
\.


--
-- TOC entry 3603 (class 0 OID 82291)
-- Dependencies: 269
-- Data for Name: meses; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.meses (id, nombre) FROM stdin;
1	Enero
2	Febrero
3	Marzo
4	Abril
5	Mayo
6	Junio
7	Julio
8	Agosto
9	Septiembre
10	Octubre
11	Noviembre
12	Diciembre
\.


--
-- TOC entry 3572 (class 0 OID 16441)
-- Dependencies: 206
-- Data for Name: negocio; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.negocio (id_negocio, nombre) FROM stdin;
1	Sae
2	Medición
3	Laboratorio
4	Negocio 01
5	Negocio 02
\.


--
-- TOC entry 3573 (class 0 OID 16449)
-- Dependencies: 207
-- Data for Name: patron; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.patron (id_patron, descripcion, marca, modelo, serie, calibracion, mes_calibracion, periodo_calibracion, activo) FROM stdin;
1	Hipot AC	Huazheng	HZAQ	HZ181010900104-02	Noviembre 2022	11	1	t
2	Hipot AC	Phoenix Technologies	BK 130/36	15-9968	Noviembre 2022	11	1	t
3	patron01	Super	verde	00000	Noviembre 2023 	11	2	t
\.


--
-- TOC entry 3588 (class 0 OID 33058)
-- Dependencies: 233
-- Data for Name: perfil; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.perfil (id, nombre, multicliente, mantenedor, inventario, ensayo, reportes) FROM stdin;
1	superusuario	t	t	t	t	t
2	admin	t	t	t	f	t
3	cliente	f	f	f	f	t
\.


--
-- TOC entry 3595 (class 0 OID 57655)
-- Dependencies: 243
-- Data for Name: periodicidad; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.periodicidad (id, descripcion, meses) FROM stdin;
1	1 MES	1
4	4 MESES	4
5	5 MESES	5
6	6 MESES	6
7	7 MESES	7
8	8 MESES	8
9	9 MESES	9
10	10 MESES	10
11	11 MESES	11
12	12 MESES	12
2	2 MESES	2
3	3 MESES	3
13	24 MESES	24
\.


--
-- TOC entry 3587 (class 0 OID 33048)
-- Dependencies: 232
-- Data for Name: personas; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.personas (rut, nombre, email, telefono, suspendida) FROM stdin;
1.234.567-0	Usuario prueba 1	user01@dielab.cl	99999999	f
1.234.567-1	usuario demo	usuario@dileab.cl	88888888	f
\.


--
-- TOC entry 3569 (class 0 OID 16412)
-- Dependencies: 202
-- Data for Name: sucursales; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.sucursales (cod_sucursal, nombre) FROM stdin;
1101	arica
1106	camarones
1201	iquique
1203	pica
1204	pozo almonte
1206	huara
1208	camina
1210	colchane
1211	alto hospicio
1301	putre
1302	general lagos
2101	tocopilla
2103	maria elena
2201	antofagasta
2202	taltal
2203	mejillones
2206	sierra gorda
2301	calama
2302	ollague
2303	san pedro de atacama
3101	chanaral
3102	diego de almagro
3201	copiapo
3202	caldera
3203	tierra amarilla
3301	vallenar
3302	freirina
3303	huasco
3304	alto del carmen
4101	la serena
4102	la higuera
4103	coquimbo
4104	andacollo
4105	vicuna
4106	paihuano
4201	ovalle
4203	monte patria
4204	punitaqui
4205	combarbala
4206	rio hurtado
4301	illapel
4302	salamanca
4303	los vilos
4304	canela
5101	isla de pascua
5201	la ligua
5202	petorca
5203	cabildo
5204	zapallar
5205	papudo
5301	valparaiso
5302	vina del mar
5303	villa alemana
5304	quilpue
5305	casablanca
5306	quintero
5307	puchuncavi
5308	juan fernandez
5309	concon
5401	san antonio
5402	santo domingo
5403	cartagena
5404	el tabo
5405	el quisco
5406	algarrobo
5501	quillota
5502	nogales
5503	hijuelas
5504	la calera
5505	la cruz
5506	limache
5507	olmue
5601	san felipe
5602	panquehue
5603	catemu
5604	putaendo
5605	santa maria
5606	llay-llay
5701	los andes
5702	calle larga
5703	san esteban
5704	rinconada
6101	rancagua
6102	machali
6103	graneros
6104	san francisco de mostazal
6105	donihue
6106	coltauco
6107	codegua
6108	peumo
6109	las cabras
6110	san vicente
6111	pichidegua
6112	rengo
6113	requinoa
6114	olivar
6115	malloa
6116	coinco
6117	quinta de tilcoco
6201	san fernando
6202	chimbarongo
6203	nancagua
6204	placilla
6205	santa cruz
6206	lolol
6207	palmilla
6208	peralillo
6209	chepica
6214	pumanque
6301	pichilemu
6302	navidad
6303	litueche
6304	la estrella
6305	marchigue
6306	paredones
7101	curico
7102	teno
7103	romeral
7104	rauco
7105	licanten
7106	vichuquen
7107	hualane
7108	molina
7109	sagrada familia
7201	talca
7202	san clemente
7203	pelarco
7204	rio claro
7205	pencahue
7206	maule
7207	curepto
7208	constitucion
7209	empedrado
7210	san rafael
7301	linares
7302	yerbas buenas
7303	colbun
7304	longavi
7305	parral
7306	retiro
7309	villa alegre
7310	san javier
7401	cauquenes
7402	pelluhue
7403	chanco
8101	chillan
8102	pinto
8103	coihueco
8104	quirihue
8105	ninhue
8106	portezuelo
8107	cobquecura
8108	trehuaco
8109	san carlos
8110	niquen
8111	san fabian
8112	san nicolas
8113	bulnes
8114	san ignacio
8115	quillon
8116	yungay
8117	pemuco
8118	el carmen
8119	ranquil
8120	coelemu
8121	chillan viejo
8201	concepcion
8202	penco
8203	hualqui
8204	florida
8205	tome
8206	talcahuano
8207	coronel
8208	lota
8209	santa juana
8210	san pedro de la paz
8211	chiguayante
8212	hualpen
8301	arauco
8302	curanilahue
8303	lebu
8304	los alamos
8305	canete
8306	contulmo
8307	tirua
8401	los angeles
8402	santa barbara
8403	laja
8404	quilleco
8405	nacimiento
8406	negrete
8407	mulchen
8408	quilaco
8409	yumbel
8410	cabrero
8411	san rosendo
8412	tucapel
8413	antuco
8414	alto biobio
9101	angol
9102	puren
9103	los sauces
9104	renaico
9105	collipulli
9106	ercilla
9107	traiguen
9108	lumaco
9109	victoria
9110	curacautin
9111	lonquimay
9201	temuco
9202	vilcun
9203	freire
9204	cunco
9205	lautaro
9206	perquenco
9207	galvarino
9208	nueva imperial
9209	carahue
9210	saavedra
9211	pitrufquen
9212	gorbea
9213	tolten
9214	loncoche
9215	villarrica
9216	pucon
9217	melipeuco
9218	curarrehue
9219	teodoro schmidt
9220	padre las casas
9221	cholchol
10101	valdivia
10102	mariquina
10103	lanco
10104	los lagos
10105	futrono
10106	corral
10107	mafil
10108	panguipulli
10109	la union
10110	paillaco
10111	rio bueno
10112	lago ranco
10201	osorno
10202	san pablo
10203	puerto octay
10204	puyehue
10205	rio negro
10206	purranque
10207	san juan de la costa
10301	puerto montt
10302	cochamo
10303	puerto varas
10304	fresia
10305	frutillar
10306	llanquihue
10307	maullin
10308	los muermos
10309	calbuco
10401	castro
10402	chonchi
10403	queilen
10404	quellon
10405	puqueldon
10406	ancud
10407	quemchi
10408	dalcahue
10410	curaco de velez
10415	quinchao
10501	chaiten
10502	hualaihue
10503	futaleufu
10504	palena
11101	aysen
11102	cisnes
11104	guaitecas
11201	chile chico
11203	rio ibanez
11301	cochrane
11302	ohiggins
11303	tortel
11401	coyhaique
11402	lago verde
12101	natales
12103	torres del paine
12202	rio verde
12204	san gregorio
12205	punta arenas
12206	laguna blanca
12301	porvenir
12302	primavera
12304	timaukel
12401	cabo de hornos
13101	santiago
13134	santiago oeste
13135	santiago sur
13159	recoleta
13167	independencia
14107	quinta normal
14109	maipu
14111	pudahuel
14113	renca
14114	quilicura
14127	conchali
14155	lo prado
14156	cerro navia
14157	estacion central
14158	huechuraba
14166	cerrillos
14201	colina
14202	lampa
14203	til-til
14501	talagante
14502	isla de maipo
14503	el monte
14504	penaflor
14505	padre hurtado
14601	melipilla
14602	maria pinto
14603	curacavi
14604	san pedro
14605	alhue
15103	providencia
15105	nunoa
15108	las condes
15128	la florida
15132	la reina
15151	macul
15152	penalolen
15160	vitacura
15161	lo barnechea
16106	san miguel
16110	la cisterna
16131	la granja
16153	san ramon
16154	la pintana
16162	pedro aguirre cerda
16163	san joaquin
16164	lo espejo
16165	el bosque
16301	puente alto
16302	pirque
16303	san jose de maipo
16401	san bernardo
16402	calera de tango
16403	buin
16404	paine
\.


--
-- TOC entry 3571 (class 0 OID 16433)
-- Dependencies: 205
-- Data for Name: tecnicos_ensayo; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.tecnicos_ensayo (id_tecnico, nombre, comentario, activo) FROM stdin;
2	Tecnico 02	Tecnico sucursal 2 rut:22222	t
3	Tecnico 03	Tecnico sucursal 3 rut:333333	t
4	Tecnico 04	Tecnico sucursal 4 rut:444444	t
1	Tecnico 01	Tecnico sucursal 1 rut:11111	f
7	Juan Soto1	hola hola	t
5	Miguel Tapia	jjjrree	t
6	otro nuevo	comentario comentario	t
\.


--
-- TOC entry 3599 (class 0 OID 65914)
-- Dependencies: 249
-- Data for Name: tipo_aterramiento; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.tipo_aterramiento (id_tipo, marca, modelo, largo, clase, corriente_fuga_max, descripcion, cod_marca) FROM stdin;
1	Hastings	\N	1	0	0	\N	5
2	Ritz	\N	1	0	0	\N	6
3	Coofeste	\N	1	0	0	\N	7
\.


--
-- TOC entry 3593 (class 0 OID 49485)
-- Dependencies: 238
-- Data for Name: tipo_banqueta; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.tipo_banqueta (id_tipo, marca, modelo, largo, clase, corriente_fuga_max, descripcion, cod_marca) FROM stdin;
1	Hastings	\N	0	0	0	\N	5
\.


--
-- TOC entry 3591 (class 0 OID 49459)
-- Dependencies: 236
-- Data for Name: tipo_cubrelinea; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.tipo_cubrelinea (id_tipo, marca, modelo, largo, clase, corriente_fuga_max, descripcion, cod_marca) FROM stdin;
1	SALISBURY	\N	1	3	5	.	1
\.


--
-- TOC entry 3581 (class 0 OID 24729)
-- Dependencies: 221
-- Data for Name: tipo_guante; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.tipo_guante (id_tipo, marca, modelo, largo, clase, corriente_fuga_max, descripcion, cod_marca) FROM stdin;
1	Salisbury	\N	1	0	5	\N	1
2	Salisbury	\N	2	0	5	\N	1
3	Salisbury	\N	3	0	5	\N	1
4	Novax	\N	1	0	5	\N	2
5	Novax	\N	2	0	5	\N	2
6	Novax	\N	3	0	5	\N	2
7	Regeltex	\N	1	0	5	\N	4
\.


--
-- TOC entry 3600 (class 0 OID 65940)
-- Dependencies: 250
-- Data for Name: tipo_loadbuster; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.tipo_loadbuster (id_tipo, marca, modelo, largo, clase, corriente_fuga_max, descripcion, cod_marca) FROM stdin;
1	Ritz	\N	0	0	0	\N	6
\.


--
-- TOC entry 3590 (class 0 OID 49438)
-- Dependencies: 235
-- Data for Name: tipo_manguilla; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.tipo_manguilla (id_tipo, marca, modelo, largo, clase, corriente_fuga_max, descripcion, cod_marca) FROM stdin;
1	Salisbury	\N	0	0	5	Generica	1
4	Novax	\N	0	0	5	Generica	2
7	Novax	\N	0	0	12	\N	2
8	Hastings	\N	0	0	0	\N	5
\.


--
-- TOC entry 3592 (class 0 OID 49472)
-- Dependencies: 237
-- Data for Name: tipo_manta; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.tipo_manta (id_tipo, marca, modelo, largo, clase, corriente_fuga_max, descripcion, cod_marca) FROM stdin;
1	HASTINGS	\N	1	4	5	.	5
2	Hastings	\N	2	2	5	\N	5
3	Hastings	\N	1	5	10	\N	5
4	Novax	\N	1	0	0	\N	2
\.


--
-- TOC entry 3602 (class 0 OID 65969)
-- Dependencies: 252
-- Data for Name: tipo_pertiga; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.tipo_pertiga (id_tipo, marca, modelo, largo, clase, corriente_fuga_max, descripcion, cod_marca) FROM stdin;
1	Chance	\N	1	0	0	\N	3
\.


--
-- TOC entry 3589 (class 0 OID 33093)
-- Dependencies: 234
-- Data for Name: usuarios; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.usuarios (id, perfil, rut, password_md5, cliente, usuario, suspendida) FROM stdin;
1	1	1.234.567-0	7a71912af813cc0e1be45bd2ea29d9c4	0	user01@dielab.cl	f
2	1	1.234.567-1	7a71912af813cc0e1be45bd2ea29d9c4	0	usuario@dielab.cl	f
\.


--
-- TOC entry 3605 (class 0 OID 90455)
-- Dependencies: 274
-- Data for Name: resultado1; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.resultado1 (id_detalle, id_batea, serie_epp, aprobado, detalle) FROM stdin;
7998	7984	7992	t	{"serie_epp":"GNT-00679","fuga1":"4","fuga2":"2","fuga3":"1","parches":"2","promedio":"2.33","tension":"4","resultado":"APROBADO"}
7997	7984	7991	t	{"serie_epp":"GNT-00678","fuga1":"2","fuga2":"3","fuga3":"4","parches":"1","promedio":"3.00","tension":"5","resultado":"APROBADO"}
8042	7999	8028	t	{"serie_epp":"GNT-00682","fuga1":"1","fuga2":"1","fuga3":"1","parches":"0","promedio":"1.00","tension":"5","resultado":"APROBADO"}
8041	7999	7992	f	{"serie_epp":"GNT-00679","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8040	7999	7991	t	{"serie_epp":"GNT-00678","fuga1":"1","fuga2":"1","fuga3":"1","parches":"1","promedio":"1.00","tension":"4","resultado":"APROBADO"}
8039	7999	8037	t	{"serie_epp":"GNT-00684","fuga1":"1","fuga2":"1","fuga3":"1","parches":"0","promedio":"1.00","tension":"10","resultado":"APROBADO"}
8067	8051	8055	f	{"serie_epp":"GNT-00689","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8066	8051	8054	f	{"serie_epp":"GNT-00688","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8065	8051	8053	f	{"serie_epp":"GNT-00687","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8064	8051	8052	f	{"serie_epp":"GNT-00686","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8063	8051	8038	f	{"serie_epp":"GNT-00685","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8062	8051	8037	f	{"serie_epp":"GNT-00684","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8061	8051	8036	f	{"serie_epp":"GNT-00683","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8060	8051	8028	f	{"serie_epp":"GNT-00682","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8059	8051	8027	f	{"serie_epp":"GNT-00681","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8058	8051	7993	f	{"serie_epp":"GNT-00680","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8057	8051	7992	f	{"serie_epp":"GNT-00679","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8070	8069	8055	t	{"serie_epp":"GNT-00689","fuga1":"2","fuga2":"2","fuga3":"2","parches":"1","promedio":"2.00","tension":"10","resultado":"APROBADO"}
8088	8086	8038	f	{"serie_epp":"GNT-00685","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8087	8086	8037	t	{"serie_epp":"GNT-00684","fuga1":"2","fuga2":"2","fuga3":"3","parches":"1","promedio":"2.33","tension":"10","resultado":"APROBADO"}
8077	8071	8038	f	{"serie_epp":"GNT-00685","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8076	8071	8037	t	{"serie_epp":"GNT-00684","fuga1":"2","fuga2":"3","fuga3":"1","parches":"1","promedio":"2.00","tension":"10","resultado":"APROBADO"}
8075	8071	8055	f	{"serie_epp":"GNT-00689","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8084	8079	8055	t	{"serie_epp":"GNT-00689","fuga1":"1","fuga2":"2","fuga3":"3","parches":"1","promedio":"2.00","tension":"10","resultado":"APROBADO"}
8083	8079	8037	f	{"serie_epp":"GNT-00684","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8082	8079	7992	f	{"serie_epp":"GNT-00679","fuga1":"--","fuga2":"--","fuga3":"--","parches":"--","promedio":"--","tension":"--","resultado":"RECHAZADO"}
8113	8106	8096	t	{"serie_epp":"MNG-00004","fuga1":"2","fuga2":"2","fuga3":"2","parches":"0","promedio":"2.00","tension":"10","resultado":"APROBADO"}
8112	8106	8095	t	{"serie_epp":"MNG-00003","fuga1":"1","fuga2":"1","fuga3":"1","parches":"1","promedio":"1.00","tension":"10","resultado":"APROBADO"}
\.


--
-- TOC entry 3613 (class 0 OID 0)
-- Dependencies: 209
-- Name: seq_cod_ensayo; Type: SEQUENCE SET; Schema: dielab; Owner: postgres
--

SELECT pg_catalog.setval('dielab.seq_cod_ensayo', 145, true);


--
-- TOC entry 3614 (class 0 OID 0)
-- Dependencies: 204
-- Name: seq_id_tabla; Type: SEQUENCE SET; Schema: dielab; Owner: postgres
--

SELECT pg_catalog.setval('dielab.seq_id_tabla', 8145, true);


--
-- TOC entry 3364 (class 2606 OID 82306)
-- Name: anual anual_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.anual
    ADD CONSTRAINT anual_pkey PRIMARY KEY (id);


--
-- TOC entry 3346 (class 2606 OID 74012)
-- Name: tipo_aterramiento ate_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_aterramiento
    ADD CONSTRAINT ate_unico UNIQUE (cod_marca, largo, corriente_fuga_max);


--
-- TOC entry 3323 (class 2606 OID 74014)
-- Name: tipo_banqueta ban_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_banqueta
    ADD CONSTRAINT ban_unico UNIQUE (cod_marca, clase, corriente_fuga_max);


--
-- TOC entry 3271 (class 2606 OID 24712)
-- Name: detalle_ensayo batea_epp_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.detalle_ensayo
    ADD CONSTRAINT batea_epp_unico UNIQUE (id_batea, serie_epp);


--
-- TOC entry 3275 (class 2606 OID 24720)
-- Name: clase_epp clase_epp_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.clase_epp
    ADD CONSTRAINT clase_epp_pkey PRIMARY KEY (id_clase_epp);


--
-- TOC entry 3286 (class 2606 OID 24818)
-- Name: clase_tipo clase_tipo_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.clase_tipo
    ADD CONSTRAINT clase_tipo_pkey PRIMARY KEY (id_clase);


--
-- TOC entry 3261 (class 2606 OID 16464)
-- Name: cliente_negocio_sucursal cliente-negocio-sucursal_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.cliente_negocio_sucursal
    ADD CONSTRAINT "cliente-negocio-sucursal_pkey" PRIMARY KEY (id_cliente_n_s);


--
-- TOC entry 3247 (class 2606 OID 16411)
-- Name: cliente cliente_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.cliente
    ADD CONSTRAINT cliente_pkey PRIMARY KEY (id_cliente);


--
-- TOC entry 3263 (class 2606 OID 16497)
-- Name: encabezado_ensayo cod_ensayo_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.encabezado_ensayo
    ADD CONSTRAINT cod_ensayo_unico UNIQUE (cod_ensayo);


--
-- TOC entry 3314 (class 2606 OID 74016)
-- Name: tipo_cubrelinea cub_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_cubrelinea
    ADD CONSTRAINT cub_unico UNIQUE (cod_marca, clase, largo, corriente_fuga_max);


--
-- TOC entry 3342 (class 2606 OID 65911)
-- Name: cuerpos_aterramiento cuerpos_aterramiento_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.cuerpos_aterramiento
    ADD CONSTRAINT cuerpos_aterramiento_pkey PRIMARY KEY (id);


--
-- TOC entry 3273 (class 2606 OID 24710)
-- Name: detalle_ensayo detalle_ensayo_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.detalle_ensayo
    ADD CONSTRAINT detalle_ensayo_pkey PRIMARY KEY (id_detalle);


--
-- TOC entry 3299 (class 2606 OID 33057)
-- Name: personas email_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.personas
    ADD CONSTRAINT email_unico UNIQUE (email);


--
-- TOC entry 3265 (class 2606 OID 16481)
-- Name: encabezado_ensayo encabezado_ensayo_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.encabezado_ensayo
    ADD CONSTRAINT encabezado_ensayo_pkey PRIMARY KEY (id_batea);


--
-- TOC entry 3269 (class 2606 OID 24702)
-- Name: ensayos_tipo ensayos_tipo_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.ensayos_tipo
    ADD CONSTRAINT ensayos_tipo_pkey PRIMARY KEY (id_ensayo_tipo);


--
-- TOC entry 3294 (class 2606 OID 24831)
-- Name: epps epps_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.epps
    ADD CONSTRAINT epps_pkey PRIMARY KEY (id_epp);


--
-- TOC entry 3267 (class 2606 OID 16548)
-- Name: estado_ensayo estado_ensayo_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.estado_ensayo
    ADD CONSTRAINT estado_ensayo_pkey PRIMARY KEY (id_estado);


--
-- TOC entry 3288 (class 2606 OID 24760)
-- Name: estado_epp estado_epp_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.estado_epp
    ADD CONSTRAINT estado_epp_pkey PRIMARY KEY (id_estado_epp);


--
-- TOC entry 3328 (class 2606 OID 57642)
-- Name: estado_uso estado_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.estado_uso
    ADD CONSTRAINT estado_unico UNIQUE (nombre_estado);


--
-- TOC entry 3330 (class 2606 OID 57640)
-- Name: estado_uso estado_uso_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.estado_uso
    ADD CONSTRAINT estado_uso_pkey PRIMARY KEY (id);


--
-- TOC entry 3282 (class 2606 OID 74018)
-- Name: tipo_guante gua_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_guante
    ADD CONSTRAINT gua_unico UNIQUE (cod_marca, clase, largo, corriente_fuga_max);


--
-- TOC entry 3338 (class 2606 OID 65837)
-- Name: largo_cubrelinea largo_cubrelinea_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.largo_cubrelinea
    ADD CONSTRAINT largo_cubrelinea_pkey PRIMARY KEY (id);


--
-- TOC entry 3334 (class 2606 OID 65816)
-- Name: largo_manta largo_manta_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.largo_manta
    ADD CONSTRAINT largo_manta_pkey PRIMARY KEY (id);


--
-- TOC entry 3354 (class 2606 OID 65966)
-- Name: largo_pertiga largo_pertiga_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.largo_pertiga
    ADD CONSTRAINT largo_pertiga_pkey PRIMARY KEY (id);


--
-- TOC entry 3292 (class 2606 OID 24804)
-- Name: largo_guante lguante_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.largo_guante
    ADD CONSTRAINT lguante_pkey PRIMARY KEY (id_largo);


--
-- TOC entry 3350 (class 2606 OID 74020)
-- Name: tipo_loadbuster loa_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_loadbuster
    ADD CONSTRAINT loa_unico UNIQUE (cod_marca, corriente_fuga_max);


--
-- TOC entry 3310 (class 2606 OID 74024)
-- Name: tipo_manguilla man_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_manguilla
    ADD CONSTRAINT man_unico UNIQUE (cod_marca, clase, corriente_fuga_max);


--
-- TOC entry 3290 (class 2606 OID 24799)
-- Name: marca marca_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.marca
    ADD CONSTRAINT marca_pkey PRIMARY KEY (id_marca);


--
-- TOC entry 3319 (class 2606 OID 74026)
-- Name: tipo_manta mat_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_manta
    ADD CONSTRAINT mat_unico UNIQUE (cod_marca, largo, clase, corriente_fuga_max);


--
-- TOC entry 3362 (class 2606 OID 82298)
-- Name: meses mese_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.meses
    ADD CONSTRAINT mese_pkey PRIMARY KEY (id);


--
-- TOC entry 3257 (class 2606 OID 90481)
-- Name: patron mmse_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.patron
    ADD CONSTRAINT mmse_unico UNIQUE (marca, modelo, serie);


--
-- TOC entry 3255 (class 2606 OID 16448)
-- Name: negocio negocio_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.negocio
    ADD CONSTRAINT negocio_pkey PRIMARY KEY (id_negocio);


--
-- TOC entry 3340 (class 2606 OID 65839)
-- Name: largo_cubrelinea nombre_cubrelinea_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.largo_cubrelinea
    ADD CONSTRAINT nombre_cubrelinea_unico UNIQUE (nombre);


--
-- TOC entry 3344 (class 2606 OID 65913)
-- Name: cuerpos_aterramiento nombre_cuerpos_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.cuerpos_aterramiento
    ADD CONSTRAINT nombre_cuerpos_unico UNIQUE (nombre);


--
-- TOC entry 3356 (class 2606 OID 65968)
-- Name: largo_pertiga nombre_largo_pertiga_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.largo_pertiga
    ADD CONSTRAINT nombre_largo_pertiga_unico UNIQUE (nombre);


--
-- TOC entry 3336 (class 2606 OID 65818)
-- Name: largo_manta nombre_manta_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.largo_manta
    ADD CONSTRAINT nombre_manta_unico UNIQUE (nombre);


--
-- TOC entry 3251 (class 2606 OID 90428)
-- Name: tecnicos_ensayo nombre_tecnico_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tecnicos_ensayo
    ADD CONSTRAINT nombre_tecnico_unico UNIQUE (nombre);


--
-- TOC entry 3259 (class 2606 OID 16456)
-- Name: patron patron_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.patron
    ADD CONSTRAINT patron_pkey PRIMARY KEY (id_patron);


--
-- TOC entry 3358 (class 2606 OID 74028)
-- Name: tipo_pertiga per_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_pertiga
    ADD CONSTRAINT per_unico UNIQUE (cod_marca, largo, corriente_fuga_max);


--
-- TOC entry 3303 (class 2606 OID 33070)
-- Name: perfil perfil_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.perfil
    ADD CONSTRAINT perfil_pkey PRIMARY KEY (id);


--
-- TOC entry 3332 (class 2606 OID 57662)
-- Name: periodicidad periodicidad_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.periodicidad
    ADD CONSTRAINT periodicidad_pkey PRIMARY KEY (id);


--
-- TOC entry 3301 (class 2606 OID 33055)
-- Name: personas personas_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.personas
    ADD CONSTRAINT personas_pkey PRIMARY KEY (rut);


--
-- TOC entry 3297 (class 2606 OID 24833)
-- Name: epps serie_unica; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.epps
    ADD CONSTRAINT serie_unica UNIQUE (serie_epp);


--
-- TOC entry 3249 (class 2606 OID 16416)
-- Name: sucursales sucursales_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.sucursales
    ADD CONSTRAINT sucursales_pkey PRIMARY KEY (cod_sucursal);


--
-- TOC entry 3253 (class 2606 OID 16440)
-- Name: tecnicos_ensayo tecnicos_ensayo_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tecnicos_ensayo
    ADD CONSTRAINT tecnicos_ensayo_pkey PRIMARY KEY (id_tecnico);


--
-- TOC entry 3348 (class 2606 OID 65922)
-- Name: tipo_aterramiento tipo_aterramiento_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_aterramiento
    ADD CONSTRAINT tipo_aterramiento_pkey PRIMARY KEY (id_tipo);


--
-- TOC entry 3326 (class 2606 OID 49492)
-- Name: tipo_banqueta tipo_banqueta_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_banqueta
    ADD CONSTRAINT tipo_banqueta_pkey PRIMARY KEY (id_tipo);


--
-- TOC entry 3316 (class 2606 OID 49466)
-- Name: tipo_cubrelinea tipo_cubrelinea_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_cubrelinea
    ADD CONSTRAINT tipo_cubrelinea_pkey PRIMARY KEY (id_tipo);


--
-- TOC entry 3278 (class 2606 OID 57623)
-- Name: clase_epp tipo_ens_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.clase_epp
    ADD CONSTRAINT tipo_ens_unico UNIQUE (tipo_ensayo);


--
-- TOC entry 3284 (class 2606 OID 24736)
-- Name: tipo_guante tipo_guante_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_guante
    ADD CONSTRAINT tipo_guante_pkey PRIMARY KEY (id_tipo);


--
-- TOC entry 3352 (class 2606 OID 65949)
-- Name: tipo_loadbuster tipo_loadbuster_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_loadbuster
    ADD CONSTRAINT tipo_loadbuster_pkey PRIMARY KEY (id_tipo);


--
-- TOC entry 3312 (class 2606 OID 49445)
-- Name: tipo_manguilla tipo_manguilla_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_manguilla
    ADD CONSTRAINT tipo_manguilla_pkey PRIMARY KEY (id_tipo);


--
-- TOC entry 3321 (class 2606 OID 49479)
-- Name: tipo_manta tipo_manta_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_manta
    ADD CONSTRAINT tipo_manta_pkey PRIMARY KEY (id_tipo);


--
-- TOC entry 3360 (class 2606 OID 65977)
-- Name: tipo_pertiga tipo_pertiga_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_pertiga
    ADD CONSTRAINT tipo_pertiga_pkey PRIMARY KEY (id_tipo);


--
-- TOC entry 3308 (class 2606 OID 33100)
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);


--
-- TOC entry 3279 (class 1259 OID 41262)
-- Name: fki_fk_clase_epp; Type: INDEX; Schema: dielab; Owner: postgres
--

CREATE INDEX fki_fk_clase_epp ON dielab.tipo_guante USING btree (clase);


--
-- TOC entry 3280 (class 1259 OID 41268)
-- Name: fki_fk_clase_tipo; Type: INDEX; Schema: dielab; Owner: postgres
--

CREATE INDEX fki_fk_clase_tipo ON dielab.tipo_guante USING btree (clase);


--
-- TOC entry 3304 (class 1259 OID 33111)
-- Name: fki_fk_cliente; Type: INDEX; Schema: dielab; Owner: postgres
--

CREATE INDEX fki_fk_cliente ON dielab.usuarios USING btree (cliente);


--
-- TOC entry 3295 (class 1259 OID 57654)
-- Name: fki_fk_estado_uso; Type: INDEX; Schema: dielab; Owner: postgres
--

CREATE INDEX fki_fk_estado_uso ON dielab.epps USING btree (estado_uso);


--
-- TOC entry 3317 (class 1259 OID 65824)
-- Name: fki_fk_largo; Type: INDEX; Schema: dielab; Owner: postgres
--

CREATE INDEX fki_fk_largo ON dielab.tipo_manta USING btree (largo);


--
-- TOC entry 3324 (class 1259 OID 65855)
-- Name: fki_fk_marca; Type: INDEX; Schema: dielab; Owner: postgres
--

CREATE INDEX fki_fk_marca ON dielab.tipo_banqueta USING btree (cod_marca);


--
-- TOC entry 3305 (class 1259 OID 33118)
-- Name: fki_fk_perfil; Type: INDEX; Schema: dielab; Owner: postgres
--

CREATE INDEX fki_fk_perfil ON dielab.usuarios USING btree (perfil);


--
-- TOC entry 3306 (class 1259 OID 33112)
-- Name: fki_fk_rut; Type: INDEX; Schema: dielab; Owner: postgres
--

CREATE INDEX fki_fk_rut ON dielab.usuarios USING btree (rut);


--
-- TOC entry 3276 (class 1259 OID 57621)
-- Name: fki_fk_tipo_ensayo; Type: INDEX; Schema: dielab; Owner: postgres
--

CREATE INDEX fki_fk_tipo_ensayo ON dielab.clase_epp USING btree (tipo_ensayo);


--
-- TOC entry 3389 (class 2620 OID 82333)
-- Name: patron trig_act_calibracion; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_calibracion BEFORE INSERT OR UPDATE ON dielab.patron FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_calibracion();


--
-- TOC entry 3390 (class 2620 OID 16553)
-- Name: encabezado_ensayo trig_act_estado; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_estado AFTER INSERT OR UPDATE ON dielab.encabezado_ensayo FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_estado();


--
-- TOC entry 3396 (class 2620 OID 74002)
-- Name: tipo_aterramiento trig_act_marca; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_marca BEFORE INSERT OR UPDATE ON dielab.tipo_aterramiento FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_nombre_marca();


--
-- TOC entry 3395 (class 2620 OID 74003)
-- Name: tipo_banqueta trig_act_marca; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_marca BEFORE INSERT OR UPDATE ON dielab.tipo_banqueta FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_nombre_marca();


--
-- TOC entry 3393 (class 2620 OID 74004)
-- Name: tipo_cubrelinea trig_act_marca; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_marca BEFORE INSERT OR UPDATE ON dielab.tipo_cubrelinea FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_nombre_marca();


--
-- TOC entry 3391 (class 2620 OID 74005)
-- Name: tipo_guante trig_act_marca; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_marca BEFORE INSERT OR UPDATE ON dielab.tipo_guante FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_nombre_marca();


--
-- TOC entry 3397 (class 2620 OID 74006)
-- Name: tipo_loadbuster trig_act_marca; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_marca BEFORE INSERT OR UPDATE ON dielab.tipo_loadbuster FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_nombre_marca();


--
-- TOC entry 3392 (class 2620 OID 74001)
-- Name: tipo_manguilla trig_act_marca; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_marca BEFORE INSERT OR UPDATE ON dielab.tipo_manguilla FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_nombre_marca();


--
-- TOC entry 3394 (class 2620 OID 74007)
-- Name: tipo_manta trig_act_marca; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_marca BEFORE INSERT OR UPDATE ON dielab.tipo_manta FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_nombre_marca();


--
-- TOC entry 3398 (class 2620 OID 74008)
-- Name: tipo_pertiga trig_act_marca; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_marca BEFORE INSERT OR UPDATE ON dielab.tipo_pertiga FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_nombre_marca();


--
-- TOC entry 3369 (class 2606 OID 41269)
-- Name: epps fk_clase_epp; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.epps
    ADD CONSTRAINT fk_clase_epp FOREIGN KEY (clase_epp) REFERENCES dielab.clase_epp(id_clase_epp) MATCH FULL;


--
-- TOC entry 3366 (class 2606 OID 41263)
-- Name: tipo_guante fk_clase_tipo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_guante
    ADD CONSTRAINT fk_clase_tipo FOREIGN KEY (clase) REFERENCES dielab.clase_tipo(id_clase) MATCH FULL;


--
-- TOC entry 3374 (class 2606 OID 49446)
-- Name: tipo_manguilla fk_clase_tipo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_manguilla
    ADD CONSTRAINT fk_clase_tipo FOREIGN KEY (clase) REFERENCES dielab.clase_tipo(id_clase) MATCH FULL;


--
-- TOC entry 3376 (class 2606 OID 49467)
-- Name: tipo_cubrelinea fk_clase_tipo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_cubrelinea
    ADD CONSTRAINT fk_clase_tipo FOREIGN KEY (clase) REFERENCES dielab.clase_tipo(id_clase) MATCH FULL;


--
-- TOC entry 3379 (class 2606 OID 49480)
-- Name: tipo_manta fk_clase_tipo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_manta
    ADD CONSTRAINT fk_clase_tipo FOREIGN KEY (clase) REFERENCES dielab.clase_tipo(id_clase) MATCH FULL;


--
-- TOC entry 3382 (class 2606 OID 49493)
-- Name: tipo_banqueta fk_clase_tipo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_banqueta
    ADD CONSTRAINT fk_clase_tipo FOREIGN KEY (clase) REFERENCES dielab.clase_tipo(id_clase) MATCH FULL;


--
-- TOC entry 3371 (class 2606 OID 33101)
-- Name: usuarios fk_cliente; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.usuarios
    ADD CONSTRAINT fk_cliente FOREIGN KEY (cliente) REFERENCES dielab.cliente(id_cliente) MATCH FULL ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3370 (class 2606 OID 57649)
-- Name: epps fk_estado_uso; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.epps
    ADD CONSTRAINT fk_estado_uso FOREIGN KEY (estado_uso) REFERENCES dielab.estado_uso(id) MATCH FULL;


--
-- TOC entry 3380 (class 2606 OID 65819)
-- Name: tipo_manta fk_largo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_manta
    ADD CONSTRAINT fk_largo FOREIGN KEY (largo) REFERENCES dielab.largo_manta(id) MATCH FULL;


--
-- TOC entry 3377 (class 2606 OID 65840)
-- Name: tipo_cubrelinea fk_largo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_cubrelinea
    ADD CONSTRAINT fk_largo FOREIGN KEY (largo) REFERENCES dielab.largo_cubrelinea(id) MATCH FULL;


--
-- TOC entry 3368 (class 2606 OID 65872)
-- Name: tipo_guante fk_largo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_guante
    ADD CONSTRAINT fk_largo FOREIGN KEY (largo) REFERENCES dielab.largo_guante(id_largo) MATCH FULL;


--
-- TOC entry 3384 (class 2606 OID 65923)
-- Name: tipo_aterramiento fk_largo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_aterramiento
    ADD CONSTRAINT fk_largo FOREIGN KEY (largo) REFERENCES dielab.cuerpos_aterramiento(id) MATCH FULL ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3387 (class 2606 OID 65978)
-- Name: tipo_pertiga fk_largo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_pertiga
    ADD CONSTRAINT fk_largo FOREIGN KEY (largo) REFERENCES dielab.largo_pertiga(id) MATCH FULL ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3383 (class 2606 OID 65850)
-- Name: tipo_banqueta fk_marca; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_banqueta
    ADD CONSTRAINT fk_marca FOREIGN KEY (cod_marca) REFERENCES dielab.marca(id_marca) MATCH FULL;


--
-- TOC entry 3378 (class 2606 OID 65856)
-- Name: tipo_cubrelinea fk_marca; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_cubrelinea
    ADD CONSTRAINT fk_marca FOREIGN KEY (cod_marca) REFERENCES dielab.marca(id_marca) MATCH FULL;


--
-- TOC entry 3367 (class 2606 OID 65861)
-- Name: tipo_guante fk_marca; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_guante
    ADD CONSTRAINT fk_marca FOREIGN KEY (cod_marca) REFERENCES dielab.marca(id_marca) MATCH FULL;


--
-- TOC entry 3375 (class 2606 OID 65886)
-- Name: tipo_manguilla fk_marca; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_manguilla
    ADD CONSTRAINT fk_marca FOREIGN KEY (cod_marca) REFERENCES dielab.marca(id_marca) MATCH FULL;


--
-- TOC entry 3381 (class 2606 OID 65892)
-- Name: tipo_manta fk_marca; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_manta
    ADD CONSTRAINT fk_marca FOREIGN KEY (cod_marca) REFERENCES dielab.marca(id_marca) MATCH FULL;


--
-- TOC entry 3385 (class 2606 OID 65928)
-- Name: tipo_aterramiento fk_marca; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_aterramiento
    ADD CONSTRAINT fk_marca FOREIGN KEY (cod_marca) REFERENCES dielab.marca(id_marca) MATCH FULL ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3386 (class 2606 OID 65950)
-- Name: tipo_loadbuster fk_marca; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_loadbuster
    ADD CONSTRAINT fk_marca FOREIGN KEY (cod_marca) REFERENCES dielab.marca(id_marca) MATCH FULL ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3388 (class 2606 OID 65983)
-- Name: tipo_pertiga fk_marca; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_pertiga
    ADD CONSTRAINT fk_marca FOREIGN KEY (cod_marca) REFERENCES dielab.marca(id_marca) MATCH FULL ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3373 (class 2606 OID 33113)
-- Name: usuarios fk_perfil; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.usuarios
    ADD CONSTRAINT fk_perfil FOREIGN KEY (perfil) REFERENCES dielab.perfil(id) MATCH FULL ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3372 (class 2606 OID 33106)
-- Name: usuarios fk_rut; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.usuarios
    ADD CONSTRAINT fk_rut FOREIGN KEY (rut) REFERENCES dielab.personas(rut) MATCH FULL ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3365 (class 2606 OID 57616)
-- Name: clase_epp fk_tipo_ensayo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.clase_epp
    ADD CONSTRAINT fk_tipo_ensayo FOREIGN KEY (tipo_ensayo) REFERENCES dielab.ensayos_tipo(id_ensayo_tipo) MATCH FULL ON UPDATE RESTRICT ON DELETE RESTRICT;


-- Completed on 2022-07-24 22:03:48

--
-- PostgreSQL database dump complete
--

