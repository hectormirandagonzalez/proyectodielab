--
-- PostgreSQL database dump
--

-- Dumped from database version 13.7
-- Dumped by pg_dump version 14.2

-- Started on 2022-09-05 20:32:01

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
-- TOC entry 7 (class 2615 OID 165161)
-- Name: clientes; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA clientes;


ALTER SCHEMA clientes OWNER TO postgres;

--
-- TOC entry 5 (class 2615 OID 165162)
-- Name: dielab; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA dielab;


ALTER SCHEMA dielab OWNER TO postgres;

--
-- TOC entry 310 (class 1255 OID 165163)
-- Name: get_consulta_masiva(date, date, bigint, character varying, character varying); Type: FUNCTION; Schema: clientes; Owner: postgres
--

CREATE FUNCTION clientes.get_consulta_masiva(inicio date, fin date, clientex bigint, tipoeppx character varying, emailx character varying) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$
declare
-- si cliente es menor a 0 toma todos los clientes
-- si tipoeppX es distinto de largo 3 toma todos los elementos
myrec			record;
empresa			varchar;
resultado		record;
ncliente		bigint;
consulta_sql	text;
begin

SELECT cliente, multicliente into myrec FROM dielab.usuarios 
join dielab.perfil on usuarios.perfil = perfil.id
where usuario = emailx;
if found then
	if myrec.multicliente then
		ncliente := clienteX;
	else
		ncliente := myrec.cliente;
	end if;
		consulta_sql := 'select nombre_cliente, elemento::text, fecha_ensayo::text,
		codigo::text, cod_elemento::text, cliente::text from clientes.lista_ensayos_emitidos';
		
		if ncliente < 0 then
		-- todos los clientes
			if length(tipoeppX) <> 3 then
				-- ver todos los epp
				consulta_sql := consulta_sql || ' ' || 'where fecha_ensayo between '''  || inicio || ''' and ''' || fin || '''';
			else
				-- ver los epp indicados
				consulta_sql := consulta_sql || ' ' || 'where fecha_ensayo between '''  || inicio || ''' and ''' || fin || ''' and cod_elemento = ''' || tipoeppX || '''';
			end if;
		else
			-- solo cliente indicado
			if length(tipoeppX) <> 3 then
				-- ver todos los epp
				consulta_sql := consulta_sql || ' ' || 'where cliente = ' || ncliente || ' and fecha_ensayo between '''  || inicio || ''' and ''' || fin || '''';
			else
				-- ver los epp indicados
				consulta_sql := consulta_sql || ' ' || 'where cliente = ' || ncliente || ' and fecha_ensayo between '''  || inicio || ''' and ''' || fin || ''' and cod_elemento = ''' || tipoeppX || '''';
			end if;
		end if;
		
		--consulta_sql := consulta_sql || ' ' || 'order by dias asc, epp_ensayado';
		raise notice 'consulta: %', consulta_sql;
		for resultado in execute(consulta_sql) loop
			return next resultado;
		end loop;
else
-- error
end if;

return;
end;

$$;


ALTER FUNCTION clientes.get_consulta_masiva(inicio date, fin date, clientex bigint, tipoeppx character varying, emailx character varying) OWNER TO postgres;

--
-- TOC entry 311 (class 1255 OID 165164)
-- Name: get_elementos_ensayados(date, date, bigint, character varying, character varying); Type: FUNCTION; Schema: clientes; Owner: postgres
--

CREATE FUNCTION clientes.get_elementos_ensayados(inicio date, fin date, clientex bigint, tipoeppx character varying, emailx character varying) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$
declare
-- si cliente es menor a 0 toma todos los clientes
-- si tipoeppX es distinto de largo 3 toma todos los elementos
myrec			record;
empresa			varchar;
resultado		record;
ncliente		bigint;
consulta_sql	text;
begin

SELECT cliente, multicliente into myrec FROM dielab.usuarios 
join dielab.perfil on usuarios.perfil = perfil.id
where usuario = emailx;
if found then
	if myrec.multicliente then
		ncliente := clienteX;
	else
		ncliente := myrec.cliente;
	end if;
		consulta_sql := 'select empresa, elemento, marca,clase,to_char(fecha_ensayo, ''DD/MM/YYYY''::text) as fecha_ensayo,
		informe_ensayo, epp_ensayado,
		(vencimiento - now()::date)::text as dias from dielab.resumen_epp_ensayados';
		if ncliente < 0 then
		-- todos los clientes
			if length(tipoeppX) <> 3 then
				-- ver todos los epp
				consulta_sql := consulta_sql || ' ' || 'where fecha_ensayo between '''  || inicio || ''' and ''' || fin || '''';
			else
				-- ver los epp indicados
				consulta_sql := consulta_sql || ' ' || 'where fecha_ensayo between '''  || inicio || ''' and ''' || fin || ''' and cod_elemento = ''' || tipoeppX || '''';
			end if;
		else
			-- solo cliente indicado
			if length(tipoeppX) <> 3 then
				-- ver todos los epp
				consulta_sql := consulta_sql || ' ' || 'where cliente = ' || ncliente || ' and fecha_ensayo between '''  || inicio || ''' and ''' || fin || '''';
			else
				-- ver los epp indicados
				consulta_sql := consulta_sql || ' ' || 'where cliente = ' || ncliente || ' and fecha_ensayo between '''  || inicio || ''' and ''' || fin || ''' and cod_elemento = ''' || tipoeppX || '''';
			end if;
		end if;
		
		consulta_sql := consulta_sql || ' ' || 'order by dias asc, epp_ensayado';
		--raise notice '%', consulta_sql;
		for resultado in execute(consulta_sql) loop
			return next resultado;
		end loop;
else
-- error

end if;

return;
end;

$$;


ALTER FUNCTION clientes.get_elementos_ensayados(inicio date, fin date, clientex bigint, tipoeppx character varying, emailx character varying) OWNER TO postgres;

--
-- TOC entry 313 (class 1255 OID 165165)
-- Name: get_encabezado_informe(character varying, character varying, character varying); Type: FUNCTION; Schema: clientes; Owner: postgres
--

CREATE FUNCTION clientes.get_encabezado_informe(cod_ensayox character varying, cod_eppx character varying, emailx character varying) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$
declare

myrec			record;
empresa			varchar;
resultado		record;
begin
SELECT nombre into myrec FROM dielab.usuarios join dielab.cliente
on usuarios.cliente = cliente.id_cliente
where usuario = 'cliente1@dielab.cl';
if found then
	empresa := myrec.nombre;
	if length(cod_ensayox) = 13 then
		-- esta ok el largo
		raise notice '(1)';
		if substr(cod_ensayox, 9, 5) = '00000' then
		-- buscar por elemento
			raise notice '(2)';
			if length(cod_eppx) = 9 then
			--largo correcto
				raise notice '(3)';
				if substr(cod_eppx, 5, 5) = '00000' then
				-- no puede ser 00000, ERROR
					raise notice '(4)';
				else
				-- buscar ensayo
					raise notice '(5)';
					SELECT distinct on (epps.serie_epp) 
						encabezado_ensayo.cod_ensayo,
									epps.serie_epp into myrec
								   FROM dielab.detalle_ensayo
									 JOIN dielab.epps ON detalle_ensayo.serie_epp = epps.id_epp
									 JOIN dielab.encabezado_ensayo USING (id_batea)
									 where epps.serie_epp = cod_eppx
									 order by epps.serie_epp, fecha_ejecucion desc;
					if found then
						raise notice '(6)';
						for resultado in SELECT * FROM dielab.lista_informe_pdf where cod_ensayo = myrec.cod_ensayo
								and cliente = empresa loop
								return next resultado;
						end loop;
					else
					-- no encuentra ensayo para el epp, ERROR
						raise exception 'No existe resultado para la búsqueda';
					end if;
				end if;
			else
			-- no tiene el largo correcto, ERROR
				raise exception 'No existe resultado para la búsqueda';
			end if;
		else
		-- buscar por ensayo
			raise notice '(7), %, %',cod_ensayox,empresa;
			for resultado in SELECT * FROM dielab.lista_informe_pdf 
			where cod_ensayo = cod_ensayox
				and cliente = empresa loop
					return next resultado;
			end loop;
		end if;
	else
	-- no tiene el largo correcto
	-- buscar por elemento
			raise notice '(8)';
			if length(cod_eppx) = 9 then
			--largo correcto
				raise notice '(10)';
				if substr(cod_eppx, 5, 5) = '00000' then
				-- no puede ser 00000, ERROR
				else
					raise notice '(11)';
				-- buscar ensayo
					SELECT distinct on (epps.serie_epp) 
						encabezado_ensayo.cod_ensayo,
									epps.serie_epp into myrec
								   FROM dielab.detalle_ensayo
									 JOIN dielab.epps ON detalle_ensayo.serie_epp = epps.id_epp
									 JOIN dielab.encabezado_ensayo USING (id_batea)
									 where epps.serie_epp = cod_eppx
									 order by epps.serie_epp, fecha_ejecucion desc;
					if found then
						raise notice '(12), %, %',myrec.cod_ensayo, empresa;
						for resultado in SELECT * FROM dielab.lista_informe_pdf where cod_ensayo = myrec.cod_ensayo
								and cliente = empresa loop
								return next resultado;
						end loop;
					else
					-- no encuentra ensayo para el epp, ERROR
						raise exception 'No existe resultado para la búsqueda';
					end if;
				end if;
			else
			-- no tiene el largo correcto, ERROR
				raise exception 'No existe resultado para la búsqueda';
			end if;
	end if;
else
-- el usuario no tiene cliente asociado
-- ERROR
	raise exception 'Hay un error con el usuario';
end if;

return;
end;

$$;


ALTER FUNCTION clientes.get_encabezado_informe(cod_ensayox character varying, cod_eppx character varying, emailx character varying) OWNER TO postgres;

--
-- TOC entry 326 (class 1255 OID 165166)
-- Name: get_resumen_ensayos(date, date, character varying); Type: FUNCTION; Schema: clientes; Owner: postgres
--

CREATE FUNCTION clientes.get_resumen_ensayos(inicio date, fin date, emailx character varying) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$
declare

myrec			record;
empresa			varchar;
resultado		record;
ncliente		bigint;

begin

SELECT cliente into myrec FROM dielab.usuarios 
where usuario = emailx;
if found then
	ncliente := myrec.cliente;
else
-- error
end if;

for resultado in
select elementos_informe.nombre, 
case when nombre_elemento is null then '0' else aprobado::text end as aprobado, 
case when nombre_elemento is null then '0' else rechazado::text end as rechazado, 
case when nombre_elemento is null then '0' else total::text end as total,
case when nombre_elemento is null then '0' else to_char((rechazado/total)*100, 'FM999.00') end as tasa_falla
from dielab.elementos_informe left join
(
select nombre_elemento, sum(aprobado) as aprobado, sum(rechazados) as rechazado,
		sum(total) as total  from (
SELECT id, fecha_ensayo, cliente, nombre_elemento, aprobado, rechazados, total
	FROM dielab.resumen_estadistico where fecha_ensayo between inicio and fin
	and cliente = ncliente) as a group by nombre_elemento) as b
on nombre = nombre_elemento
order by prioridad loop
	return next resultado;

end loop;


return;
end;

$$;


ALTER FUNCTION clientes.get_resumen_ensayos(inicio date, fin date, emailx character varying) OWNER TO postgres;

--
-- TOC entry 327 (class 1255 OID 165167)
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
-- TOC entry 328 (class 1255 OID 165168)
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
-- TOC entry 329 (class 1255 OID 165169)
-- Name: actualiza_id(); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.actualiza_id() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare

resultado   record;

begin

select max(id) as valor into resultado from dielab.resumen_estadistico;
if found then
	if resultado.valor is null then
		new.id := 1;
	else
		new.id := resultado.valor + 1;
	end if;
else
	new.id := 1;
end if;

return new;
   
end
$$;


ALTER FUNCTION dielab.actualiza_id() OWNER TO postgres;

--
-- TOC entry 330 (class 1255 OID 165170)
-- Name: actualiza_id_resumen(); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.actualiza_id_resumen() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare

resultado   record;

begin

select max(id) as valor into resultado from dielab.resumen_epp_ensayados;
if found then
	if resultado.valor is null then
		new.id := 1;
	else
		new.id := resultado.valor + 1;
	end if;
else
	new.id := 1;
end if;

return new;
   
end
$$;


ALTER FUNCTION dielab.actualiza_id_resumen() OWNER TO postgres;

--
-- TOC entry 331 (class 1255 OID 165171)
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
-- TOC entry 332 (class 1255 OID 165172)
-- Name: actualiza_total(); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.actualiza_total() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare

resultado   record;

begin

new.total := new.aprobado + new.rechazados;
return new;
   
end
$$;


ALTER FUNCTION dielab.actualiza_total() OWNER TO postgres;

--
-- TOC entry 309 (class 1255 OID 165173)
-- Name: busca_un_ensayo(character varying); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.busca_un_ensayo(cod_ensayox character varying) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare

myrec 			record;
salida			json;
begin


select * into myrec from dielab.encabezado_ensayo where cod_ensayo = cod_ensayoX;
if found then
	salida = '{"error":true, "msg":"' || 'El ensayo codigo: ' || cod_ensayoX || ' ya existe en la base ' || '"}';
else
	salida = '{"error":false, "msg":"' || cod_ensayoX || '"}';
end if;

return salida;
end;

$$;


ALTER FUNCTION dielab.busca_un_ensayo(cod_ensayox character varying) OWNER TO postgres;

--
-- TOC entry 333 (class 1255 OID 165174)
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
-- TOC entry 334 (class 1255 OID 165175)
-- Name: elimina_param(character varying, bigint); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.elimina_param(tipo_tablax character varying, idx bigint) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare

--id_epp			double precision;
salida        	json;
resultado		record;
sql_text		text;
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
elseif tipo_tablaX = 'cliente' then
	select * into resultado from dielab.cliente where id_cliente = idX;
	if found then
		select * into resultado from dielab.cliente_negocio_sucursal 
		join dielab.encabezado_ensayo on id_cliente_n_s = cliente_n_s
		where cliente = idx;
		if found then
		-- desactivar porque tiene ensayos asociados
			update dielab.cliente set suspendido = true where cliente.id_cliente = idX;
		else
		-- eliminar porque no tiene ensayos
			delete from dielab.cliente where cliente.id_cliente = idX;
		end if;
		salida = '{"error":false, "msg":"Operación realizada con éxito"}';
	else
		salida = '{"error":true, "msg":"No existe el cliente en la base"}';
	end if;
elseif tipo_tablaX = 'marca' then
	delete from dielab.cliente where id_marca = idx;
elseif tipo_tablaX = 'cuerpos_aterramiento' then
	delete from dielab.cuerpos_aterramiento where id = idx;
elseif tipo_tablaX = 'cuerpos_pertiga' then
	delete from dielab.largo_pertiga where id = idx;
elseif tipo_tablaX = 'largo_guante' then
	delete from dielab.largo_guante where id_largo = idx;
elseif tipo_tablaX = 'largo_cubrelinea' then
	delete from dielab.largo_cubrelinea where id = idx;
elseif tipo_tablaX = 'largo_manta' then
	delete from dielab.largo_manta where id = idx;
elseif tipo_tablaX = 'largo_cubreposte' then
	delete from dielab.largo_cubreposte where id = idx;
elseif tipo_tablaX = 'negocio' then
	delete from dielab.negocio where id_negocio = idx;
elseif tipo_tablaX = 'usuario' then
	delete from dielab.usuarios where id = idx;
elseif tipo_tablaX = 'caracteristica_aterramiento' then
	delete from dielab.caracteristica_aterramiento where id = idx;
elseif tipo_tablaX = 'caracteristica_pertiga' then
	delete from dielab.caracteristica_pertiga where id = idx;
else
	sql_text = 'delete from dielab.' || tipo_tablaX || ' where id_tipo = ' || idx;
	execute sql_text;
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
-- TOC entry 335 (class 1255 OID 165176)
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
-- TOC entry 336 (class 1255 OID 165177)
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
	
	for myrec in select nombre, sum(case when aprobado then 1 else 0 end) as aprobado,
			sum(case when not aprobado then 1 else 0 end) as rechazado, fecha_ejecucion, cliente from (
			select id_epp, 
			case when cod_clase = '0' or cod_clase = '00' then 'Guantes BT' else 'Guantes MT' end 
			as nombre, id_batea, cod_ensayo, aprobado, cliente, fecha_ejecucion from dielab.epps join dielab.clase_epp on epps.clase_epp = clase_epp.id_clase_epp
			join dielab.tipo_guante on tipo_epp = id_tipo
			join dielab.clase_tipo on id_clase = tipo_guante.clase
			join dielab.detalle_ensayo on id_epp = detalle_ensayo.serie_epp
			join dielab.encabezado_ensayo using (id_batea) 
			join dielab.cliente_negocio_sucursal on encabezado_ensayo.cliente_n_s = id_cliente_n_s
			where clase_epp = 1 and cod_ensayo = cod_ensayox
			UNION
			select id_epp, nombre_menu as nombre, id_batea, cod_ensayo, aprobado, cliente, fecha_ejecucion from dielab.epps 
			join dielab.clase_epp on epps.clase_epp = clase_epp.id_clase_epp
			join dielab.detalle_ensayo on id_epp = detalle_ensayo.serie_epp
			join dielab.encabezado_ensayo using (id_batea) 
			join dielab.cliente_negocio_sucursal on encabezado_ensayo.cliente_n_s = id_cliente_n_s
			where clase_epp <> 1 and cod_ensayo = cod_ensayox) as agrupa
			group by nombre, fecha_ejecucion, cliente loop
				insert into dielab.resumen_estadistico 
				(fecha_ensayo, cliente, nombre_elemento, aprobado, rechazados)
				values (fecha_ejecucion, cliente, nombre, aprobado, rechazado);
		end loop;
		
		---- inserta epps ensayados para informes
		insert into dielab.resumen_epp_ensayados
		( fecha_ensayo, cliente, empresa, elemento, marca, clase, informe_ensayo, epp_ensayado, cod_elemento, vencimiento)
		select fecha_ejecucion,cliente,initcap(nombre_corto) as empresa, 
		initcap(clase_epp.nombre) || case when clase_epp.id_clase_epp = 1 then 
		case when lista_tipo_marca_clase.cod_clase in ('0', '00') then ' BT' else ' MT' end
		else '' end as elemento, marca, clase, cod_ensayo as informe_ensayo, 
		epps.serie_epp as epp_ensayado, cod_serie as cod_elemento,
		(fecha_ejecucion + (periodicidad::text || ' month'::text)::interval)::date as vencimiento
		from dielab.encabezado_ensayo join dielab.detalle_ensayo
		using (id_batea) join dielab.cliente_negocio_sucursal on cliente_n_s = id_cliente_n_s
		join dielab.cliente on cliente.id_cliente = cliente_negocio_sucursal.cliente
		join dielab.epps on id_epp = detalle_ensayo.serie_epp
		join dielab.clase_epp on epps.clase_epp = clase_epp.id_clase_epp
		join dielab.lista_tipo_marca_clase on clase_epp.tabla_detalle = lista_tipo_marca_clase.tipo_epp
		and epps.tipo_epp = lista_tipo_marca_clase.id_tipo
		where cod_ensayo = cod_ensayox;
		
		
	salida = '{"error":false, "msg":"Certificado emitido"}';
else
	salida = '{"error":true, "msg":"No se encuentra el codigo ensayo: ' || cod_ensayox || '"}';
end if;
return salida;
end;

$$;


ALTER FUNCTION dielab.emite_certificado(cod_ensayox character varying) OWNER TO postgres;

--
-- TOC entry 337 (class 1255 OID 165178)
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
-- TOC entry 338 (class 1255 OID 165179)
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
-- TOC entry 339 (class 1255 OID 165180)
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
-- TOC entry 340 (class 1255 OID 165181)
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
-- TOC entry 341 (class 1255 OID 165182)
-- Name: get_caracterisica(character varying); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.get_caracterisica(cod_ensayox character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$
declare

myrec			record;
salida			text;
begin

salida := '';
if substr(cod_ensayox, 1, 7) = 'LAT-ATR' then
	SELECT ca.nombre into myrec
		FROM dielab.detalle_ensayo de
		join dielab.encabezado_ensayo ee using(id_batea)
		join dielab.epps e on e.id_epp = de.serie_epp
		join dielab.tipo_aterramiento ta on ta.id_tipo = e.tipo_epp
		join dielab.caracteristica_aterramiento ca on ca.id = ta.caracteristica
		where cod_ensayo = cod_ensayox limit 1;
		if found then
			salida := myrec.nombre;
		else
			salida := '';
		end if;
elsif substr(cod_ensayox, 1, 7) = 'LAT-PER' then
SELECT ca.nombre into myrec
		FROM dielab.detalle_ensayo de
		join dielab.encabezado_ensayo ee using(id_batea)
		join dielab.epps e on e.id_epp = de.serie_epp
		join dielab.tipo_pertiga ta on ta.id_tipo = e.tipo_epp
		join dielab.caracteristica_pertiga ca on ca.id = ta.caracteristica
		where cod_ensayo = cod_ensayox limit 1;
		if found then
			salida := myrec.nombre;
		else
			salida := '';
		end if;
else
salida := '';
end if;

return salida;

end;

$$;


ALTER FUNCTION dielab.get_caracterisica(cod_ensayox character varying) OWNER TO postgres;

--
-- TOC entry 342 (class 1255 OID 165183)
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
-- TOC entry 343 (class 1255 OID 165184)
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
-- TOC entry 344 (class 1255 OID 165185)
-- Name: get_detalle_pdf_bnq(character varying); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.get_detalle_pdf_bnq(cod_ensayox character varying) RETURNS SETOF record
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
join dielab.tipo_banqueta on tipo_epp = id_tipo
join dielab.clase_tipo on tipo_banqueta.clase = clase_tipo.id_clase
where cod_ensayo = cod_ensayoX) as b
	on a.correlativo = b.num_fila loop
		return next myrec;
end loop;

return;
end;

$_$;


ALTER FUNCTION dielab.get_detalle_pdf_bnq(cod_ensayox character varying) OWNER TO postgres;

--
-- TOC entry 345 (class 1255 OID 165186)
-- Name: get_detalle_pdf_cbl(character varying); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.get_detalle_pdf_cbl(cod_ensayox character varying) RETURNS SETOF record
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
	row_number() over (order by num_serie)::text as num_fila, num_serie, marca, select_largo_cubrelinea.nombre::text as largo, cod_clase, tension_ensayo,
	case when parches ~ '^[0-9\.]+$' then case when parches::numeric > 0 then parches else '--' end else '--' end as parches, 
	case when aprobado = 'RECHAZADO' then 'Falla' else case when i_fuga_1 ~ '^[0-9\.]+$' then to_char(i_fuga_1::numeric, 'FM999.00') else '--' end end as promed_fuga, 
	to_char(corriente_fuga_max, 'FM9.00') as fuga_max, aprobado, estado_uso.nombre_estado::text as usado
	--select *
	from dielab.lista_det_guante
	join dielab.epps on num_serie = serie_epp
	join dielab.encabezado_ensayo using (id_batea)
	join dielab.estado_uso on epps.estado_uso = estado_uso.id
	join dielab.tipo_cubrelinea on tipo_epp = id_tipo
	join dielab.select_largo_cubrelinea on tipo_cubrelinea.largo = select_largo_cubrelinea.id
	join dielab.clase_tipo on tipo_cubrelinea.clase = clase_tipo.id_clase
	where cod_ensayo = cod_ensayoX) as b
	on a.correlativo = b.num_fila loop
		return next myrec;
end loop;

return;
end;

$_$;


ALTER FUNCTION dielab.get_detalle_pdf_cbl(cod_ensayox character varying) OWNER TO postgres;

--
-- TOC entry 346 (class 1255 OID 165187)
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
-- TOC entry 347 (class 1255 OID 165188)
-- Name: get_detalle_pdf_jmp(character varying); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.get_detalle_pdf_jmp(cod_ensayox character varying) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $_$
declare

myrec			record;
begin

for myrec in select case when num_fila is null then '--' else num_fila end as row_number,
case when num_serie is null then '--' else num_serie end as num_serie,
case when marca is null then '--' else marca end as marca,
case when usado is null then '--' else initcap(usado) end as usado,
case when cod_clase is null then '--' else cod_clase end as cod_clase,
case when tension_ensayo is null then '--' else tension_ensayo end as tension_ensayo,
case when visual is null then '--' else visual end as visual,
case when promed_fuga is null then '--' else replace(promed_fuga,'.',',')::text end as promed_fuga,
case when dieresul is null then '--' else dieresul end as dieresul,
case when tramo is null then '--' else tramo end as tramo,
case when seccion is null then '--' else seccion end as seccion,
case when longitud is null then '--' else longitud end as longitud,
case when resismedida is null then '--' else resismedida end as resismedida,
case when resismax is null then '--' else resismax end as resismax,
case when resisresul is null then '--' else resisresul end as resisresul
from
	(select generate_series(1,6)::text as correlativo) as a
	LEFT JOIN
	(select 
	row_number() over (order by num_serie)::text as num_fila, 
	num_serie, 
	marca,
	estado_uso.nombre_estado::text as usado,
	cod_clase, 
	tension_ensayo,
	visual,
	case when i_fuga_1 ~ '^[0-9\.]+$' then to_char(i_fuga_1::numeric, 'FM999.00') else '--' end as promed_fuga,
	dieresul,
	tramo,
	seccion,
	longitud,
	resismedida,
	resismax,
	resisresul
	from dielab.lista_det_jumper
	join dielab.epps on num_serie = serie_epp
	join dielab.encabezado_ensayo using (id_batea)
	join dielab.estado_uso on epps.estado_uso = estado_uso.id
	join dielab.tipo_jumper on tipo_epp = id_tipo
	join dielab.clase_tipo on tipo_jumper.clase = clase_tipo.id_clase
	where cod_ensayo = cod_ensayoX) as b
	on a.correlativo = b.num_fila  loop
		return next myrec;
end loop;

return;
end;

$_$;


ALTER FUNCTION dielab.get_detalle_pdf_jmp(cod_ensayox character varying) OWNER TO postgres;

--
-- TOC entry 348 (class 1255 OID 165189)
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
-- TOC entry 349 (class 1255 OID 165190)
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
-- TOC entry 312 (class 1255 OID 165191)
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
-- TOC entry 350 (class 1255 OID 165192)
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
elseif tablaX = 'cliente' then
	select case when nombre is null then ''::text else nombre end as nombre,
	case when telefono is null then ''::text else telefono end as telefono,
	case when representante is null then ''::text else representante end as representante,
	case when direccion is null then ''::text else direccion end as direccion,
	case when nombre_corto is null then ''::text else nombre_corto end as nombre_corto
	into myrec
	from dielab.cliente where id_cliente = id_paramX;
	if found then
		linea = '{"nombre":"' || myrec.nombre || '", "telefono":"' || myrec.telefono || '", "representante":"' || myrec.representante || '", "direccion":"' || myrec.direccion || '", "nombre_corto":"' || myrec.nombre_corto || '"}';
		linea := '{"error":false, "datos":'  || linea  ||  '}';
		salida = linea::json;
	else
		linea := '{}';
		linea := '{"error":false, "datos":'  || linea  ||  '}';
		salida = linea::json;
	end if;
elseif tablaX = 'marca' then
	select nombre as nombre_marca into myrec
	from dielab.marca where id_marca = id_paramX;
	if found then
		linea := '{"nombre_marca":"' || myrec.nombre_marca || '"}';
		linea := '{"error":false, "datos":'  || linea  ||  '}';
		salida = linea::json;
	else
		linea := '{"nombre_marca":""}';
		linea := '{"error":false, "datos":'  || linea  ||  '}';
		salida = linea::json;
	end if;
elseif tablaX = 'cuerpos_aterramiento' then
	select nombre as cuerpos into myrec
	from dielab.cuerpos_aterramiento where id = id_paramX;
	if found then
		linea := '{"cuerpos":"' || myrec.cuerpos || '"}';
		linea := '{"error":false, "datos":'  || linea  ||  '}';
		salida = linea::json;
	else
		linea := '{"cuerpos":""}';
		linea := '{"error":false, "datos":'  || linea  ||  '}';
		salida = linea::json;
	end if;
elseif tablaX = 'largo_guante' then
	select valor as largo_guante into myrec
	from dielab.largo_guante where id_largo = id_paramX;
	if found then
		linea := '{"largo_guante":"' || myrec.largo_guante || '"}';
		linea := '{"error":false, "datos":'  || linea  ||  '}';
		salida = linea::json;
	else
		linea := '{"largo_guante":""}';
		linea := '{"error":false, "datos":'  || linea  ||  '}';
		salida = linea::json;
	end if;
elseif tablaX = 'cuerpos_pertiga' then
	select nombre as cuerpos into myrec
	from dielab.largo_pertiga where id = id_paramX;
	if found then
		linea := '{"cuerpos":"' || myrec.cuerpos || '"}';
		linea := '{"error":false, "datos":'  || linea  ||  '}';
		salida = linea::json;
	else
		linea := '{"cuerpos":""}';
		linea := '{"error":false, "datos":'  || linea  ||  '}';
		salida = linea::json;
	end if;
elseif tablaX = 'largo_cubrelinea' then
	select nombre as modelo_cubrelinea into myrec
	from dielab.largo_cubrelinea where id = id_paramX;
	if found then
		linea := '{"modelo_cubrelinea":"' || myrec.modelo_cubrelinea || '"}';
		linea := '{"error":false, "datos":'  || linea  ||  '}';
		salida = linea::json;
	else
		linea := '{"modelo_cubrelinea":""}';
		linea := '{"error":false, "datos":'  || linea  ||  '}';
		salida = linea::json;
	end if;
elseif tablaX = 'largo_manta' then
	select nombre as largo_manta into myrec
	from dielab.largo_manta where id = id_paramX;
	if found then
		linea := '{"largo_manta":"' || myrec.largo_manta || '"}';
		linea := '{"error":false, "datos":'  || linea  ||  '}';
		salida = linea::json;
	else
		linea := '{"largo_manta":""}';
		linea := '{"error":false, "datos":'  || linea  ||  '}';
		salida = linea::json;
	end if;
elseif tablaX = 'largo_cubreposte' then
	select nombre as largo_cubreposte into myrec
	from dielab.largo_cubreposte where id = id_paramX;
	if found then
		linea := '{"largo_cubreposte":"' || myrec.largo_cubreposte || '"}';
		linea := '{"error":false, "datos":'  || linea  ||  '}';
		salida = linea::json;
	else
		linea := '{"largo_cubreposte":""}';
		linea := '{"error":false, "datos":'  || linea  ||  '}';
		salida = linea::json;
	end if;
elseif tablaX = 'negocio' then
	select nombre as nombre_negocio into myrec
	from dielab.negocio where id_negocio = id_paramX;
	if found then
		linea := '{"nombre_negocio":"' || myrec.nombre_negocio || '"}';
		linea := '{"error":false, "datos":'  || linea  ||  '}';
		salida = linea::json;
	else
		linea := '{"nombre_negocio":""}';
		linea := '{"error":false, "datos":'  || linea  ||  '}';
		salida = linea::json;
	end if;
elseif tablaX = 'caracteristica_aterramiento' then
	select nombre as modelo into myrec
	from dielab.caracteristica_aterramiento where id = id_paramX;
	if found then
		linea := '{"modelo":"' || myrec.modelo || '"}';
		linea := '{"error":false, "datos":'  || linea  ||  '}';
		salida = linea::json;
	else
		linea := '{"modelo":""}';
		linea := '{"error":false, "datos":'  || linea  ||  '}';
		salida = linea::json;
	end if;
elseif tablaX = 'caracteristica_pertiga' then
	select nombre as modelo into myrec
	from dielab.caracteristica_pertiga where id = id_paramX;
	if found then
		linea := '{"modelo":"' || myrec.modelo || '"}';
		linea := '{"error":false, "datos":'  || linea  ||  '}';
		salida = linea::json;
	else
		linea := '{"modelo":""}';
		linea := '{"error":false, "datos":'  || linea  ||  '}';
		salida = linea::json;
	end if;
elseif tablaX = 'usuario' then
	SELECT usuarios.id,
    usuarios.usuario AS nombre,
    usuarios.id AS num,
    usuarios.usuario AS nombre_usuario,
    personas.nombre AS nombre_persona,
    personas.rut,
    personas.email,
    personas.telefono,
    cliente.nombre_corto::text AS cliente into myrec 
   FROM dielab.personas
     JOIN dielab.usuarios USING (rut)
     JOIN dielab.cliente ON usuarios.cliente = cliente.id_cliente where usuarios.id = id_paramX;
	if found then
		linea = '{"nombre_usuario":"' || myrec.nombre_usuario || '", "nombre_persona":"' || myrec.nombre_persona || '", "rut":"' || myrec.rut || '", "email":"' || myrec.email || '", "telefono":"' || myrec.telefono || '", "cliente":"' || myrec.cliente || '"}';
		linea := '{"error":false, "datos":'  || linea  ||  '}';
		salida = linea::json;
	else
		linea := '{"nombre_negocio":""}';
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
-- TOC entry 351 (class 1255 OID 165193)
-- Name: get_lista_informe(character varying, date, date); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.get_lista_informe(tipo_eppx character varying, fecha_ini date, fecha_fin date) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare

myrec			record;
linea			text;
salida			json;
begin
salida := '{"error":false, "msg":"error 01"}'::json;

return salida;

end;

$$;


ALTER FUNCTION dielab.get_lista_informe(tipo_eppx character varying, fecha_ini date, fecha_fin date) OWNER TO postgres;

--
-- TOC entry 352 (class 1255 OID 165194)
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
-- TOC entry 353 (class 1255 OID 165195)
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
--raise notice 'inicio ';
id_tipo_in := 1;
--raise notice 'inicio 2';
if tabla_tipo_in = 'patron' then
	--raise notice 'inicio 3';
	sql_text := 'select max(id_patron) as val_max from dielab.' || tabla_tipo_in || ';';
	--raise notice 'inicio 4';
	--sql_text = 'id_patron';
	--raise notice 'inicio 5';
elseif tabla_tipo_in = 'tecnicos_ensayo' then
	--raise notice 'inicio 3';
	sql_text := 'select max(id_tecnico) as val_max from dielab.' || tabla_tipo_in || ';';
	--raise notice 'inicio 4';
	--sql_text = 'id_patron';
	--raise notice 'inicio 5';
elseif tabla_tipo_in = 'cliente' then
	sql_text := 'select max(id_cliente) as val_max from dielab.' || tabla_tipo_in || ';';
elseif tabla_tipo_in = 'marca' then
	sql_text := 'select max(id_marca) as val_max from dielab.' || tabla_tipo_in || ';';
elseif tabla_tipo_in = 'cuerpos_aterramiento' then
	sql_text := 'select max(id) as val_max from dielab.' || tabla_tipo_in || ';';
elseif tabla_tipo_in = 'cuerpos_pertiga' then
	sql_text := 'select max(id) as val_max from dielab.largo_pertiga;';
elseif tabla_tipo_in = 'largo_guante' then
	sql_text := 'select max(id_largo) as val_max from dielab.largo_guante;';
elseif tabla_tipo_in = 'largo_cubrelinea' then
	sql_text := 'select max(id) as val_max from dielab.largo_cubrelinea;';
elseif tabla_tipo_in = 'largo_manta' then
	sql_text := 'select max(id) as val_max from dielab.largo_manta;';
elseif tabla_tipo_in = 'largo_cubreposte' then
	sql_text := 'select max(id) as val_max from dielab.largo_cubreposte;';
elseif tabla_tipo_in = 'negocio' then
	sql_text := 'select max(id_negocio) as val_max from dielab.negocio;';
elseif tabla_tipo_in = 'caracteristica_aterramiento' then
	sql_text := 'select max(id) as val_max from dielab.caracteristica_aterramiento;';
elseif tabla_tipo_in = 'caracteristica_pertiga' then
	sql_text := 'select max(id) as val_max from dielab.caracteristica_pertiga;';
else 
	--raise notice 'inicio 6';
	sql_text := 'select max(id_tipo) as val_max from dielab.' || tabla_tipo_in || ';';
	--raise notice 'inicio 7';
	--sql_text = 'id_tipo';
	--raise notice 'inicio 8';
end if;
--raise notice 'sql_text: %', sql_text;
for myrec in execute(sql_text) loop
	if myrec.val_max is not null then
		id_tipo_in := myrec.val_max + 1;
	end if;
end loop;
if tabla_tipo_in = 'patron' then
	sql_text = 'id_patron';
elseif tabla_tipo_in = 'tecnicos_ensayo' then
	sql_text = 'id_tecnico';
elseif tabla_tipo_in = 'cliente' then
	sql_text = 'id_cliente';
elseif tabla_tipo_in = 'marca' then
	sql_text = 'id_marca';
elseif tabla_tipo_in = 'cuerpos_aterramiento' or tabla_tipo_in = 'cuerpos_pertiga' then
	sql_text = 'id';
elseif tabla_tipo_in = 'largo_guante' then
	sql_text = 'id_largo';
elseif tabla_tipo_in = 'largo_cubrelinea' then
	sql_text = 'id';
elseif tabla_tipo_in = 'largo_manta' then
	sql_text = 'id';
elseif tabla_tipo_in = 'largo_cubreposte' then
	sql_text = 'id';
elseif tabla_tipo_in = 'negocio' then
	sql_text = 'id_negocio';
elseif tabla_tipo_in = 'caracteristica_aterramiento' then
	sql_text = 'id';
elseif tabla_tipo_in = 'caracteristica_pertiga' then
	sql_text = 'id';
else
	sql_text = 'id_tipo';
end if;

if tabla_tipo_in = 'cliente' then
	if datojson->'nombre' is not null then
		if sql_text = '' then
			sql_text := 'nombre';
		else
			sql_text := sql_text || ',' || 'nombre';
		end if;
	end if;
	if datojson->'telefono' is not null then
		if sql_text = '' then
			sql_text := 'telefono';
		else
			sql_text := sql_text || ',' || 'telefono';
		end if;
	end if;
	if datojson->'representante' is not null then
		if sql_text = '' then
			sql_text := 'representante';
		else
			sql_text := sql_text || ',' || 'representante';
		end if;
	end if;
	if datojson->'direccion' is not null then
		if sql_text = '' then
			sql_text := 'direccion';
		else
			sql_text := sql_text || ',' || 'direccion';
		end if;
	end if;
	if datojson->'nombre_corto' is not null then
		if sql_text = '' then
			sql_text := 'nombre_corto';
		else
			sql_text := sql_text || ',' || 'nombre_corto';
		end if;
	end if;
elseif tabla_tipo_in = 'marca' then
	if datojson->'nombre_marca' is not null then
		if sql_text = '' then
			sql_text := 'nombre';
		else
			sql_text := sql_text || ',' || 'nombre';
		end if;
	end if;
elseif tabla_tipo_in = 'cuerpos_aterramiento' then
	if datojson->'cuerpos' is not null then
		if sql_text = '' then
			sql_text := 'nombre';
		else
			sql_text := sql_text || ',' || 'nombre';
		end if;
	end if;
elseif tabla_tipo_in = 'cuerpos_pertiga' then
	if datojson->'cuerpos' is not null then
		if sql_text = '' then
			sql_text := 'nombre';
		else
			sql_text := sql_text || ',' || 'nombre';
		end if;
	end if;
elseif tabla_tipo_in = 'largo_guante' then
	if datojson->'largo_guante' is not null then
		if sql_text = '' then
			sql_text := 'valor';
		else
			sql_text := sql_text || ',' || 'valor';
		end if;
	end if;
elseif tabla_tipo_in = 'largo_cubrelinea' then
	if datojson->'modelo_cubrelinea' is not null then
		if sql_text = '' then
			sql_text := 'nombre';
		else
			sql_text := sql_text || ',' || 'nombre';
		end if;
	end if;
elseif tabla_tipo_in = 'largo_manta' then
	if datojson->'largo_manta' is not null then
		if sql_text = '' then
			sql_text := 'nombre';
		else
			sql_text := sql_text || ',' || 'nombre';
		end if;
	end if;
elseif tabla_tipo_in = 'largo_cubreposte' then
	if datojson->'largo_cubreposte' is not null then
		if sql_text = '' then
			sql_text := 'nombre';
		else
			sql_text := sql_text || ',' || 'nombre';
		end if;
	end if;
elseif tabla_tipo_in = 'negocio' then
	if datojson->'nombre_negocio' is not null then
		if sql_text = '' then
			sql_text := 'nombre';
		else
			sql_text := sql_text || ',' || 'nombre';
		end if;
	end if;
elseif tabla_tipo_in = 'caracteristica_aterramiento' then
	if datojson->'modelo' is not null then
		if sql_text = '' then
			sql_text := 'nombre';
		else
			sql_text := sql_text || ',' || 'nombre';
		end if;
	end if;
elseif tabla_tipo_in = 'caracteristica_pertiga' then
	if datojson->'modelo' is not null then
		if sql_text = '' then
			sql_text := 'nombre';
		else
			sql_text := sql_text || ',' || 'nombre';
		end if;
	end if;
else
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
	if datojson->'modelo_cubrelinea' is not null then
		if sql_text = '' then
			sql_text := 'largo';
		else
			sql_text := sql_text || ',' || 'largo';
		end if;
	end if;
	if datojson->'modelo_aterramiento' is not null then
		if sql_text = '' then
			sql_text := 'caracteristica';
		else
			sql_text := sql_text || ',' || 'caracteristica';
		end if;
	end if;
	if datojson->'modelo_pertiga' is not null then
		if sql_text = '' then
			sql_text := 'caracteristica';
		else
			sql_text := sql_text || ',' || 'caracteristica';
		end if;
	end if;
end if;
raise notice 'sql_text(4): %',sql_text;
sql_text = '(' || sql_text || ') VALUES (' || id_tipo_in::text;

-----------------------------------------
-----------------------------------------
--raise notice 'sql_text: %',sql_text;
--raise notice 'clase: %', datojson->>'clase';
if tabla_tipo_in = 'cliente' then
	if datojson->'nombre' is not null then
		sql_text := sql_text || ',' || '''' || (datojson->>'nombre')::text || '''';
	end if;
	if datojson->'telefono' is not null then
		sql_text := sql_text || ',' || '''' || (datojson->>'telefono')::text || '''';
	end if;
	if datojson->'representante' is not null then
		sql_text := sql_text || ',' || '''' || (datojson->>'representante')::text || '''';
	end if;
	if datojson->'direccion' is not null then
		sql_text := sql_text || ',' || '''' || (datojson->>'direccion')::text || '''';
	end if;
	if datojson->'nombre_corto' is not null then
		sql_text := sql_text || ',' || '''' || (datojson->>'nombre_corto')::text || '''';
	end if;
elseif tabla_tipo_in = 'marca' then
	if datojson->'nombre_marca' is not null then
		sql_text := sql_text || ',' || '''' || (datojson->>'nombre_marca')::text || '''';
	end if;
elseif tabla_tipo_in = 'cuerpos_aterramiento' then
	if datojson->'cuerpos' is not null then
		sql_text := sql_text || ',' || '''' || (datojson->>'cuerpos')::text || '''';
	end if;
elseif tabla_tipo_in = 'cuerpos_pertiga' then
	if datojson->'cuerpos' is not null then
		sql_text := sql_text || ',' || '''' || (datojson->>'cuerpos')::text || '''';
	end if;
elseif tabla_tipo_in = 'largo_guante' then
	if datojson->'largo_guante' is not null then
		sql_text := sql_text || ',' || (datojson->>'largo_guante')::text;
	end if;
elseif tabla_tipo_in = 'largo_cubrelinea' then
	if datojson->'modelo_cubrelinea' is not null then
		sql_text := sql_text || ',' || '''' || (datojson->>'modelo_cubrelinea')::text || '''';
	end if;
elseif tabla_tipo_in = 'largo_manta' then
	if datojson->'largo_manta' is not null then
		sql_text := sql_text || ',' || '''' || (datojson->>'largo_manta')::text || '''';
	end if;
elseif tabla_tipo_in = 'largo_cubreposte' then
	if datojson->'largo_cubreposte' is not null then
		sql_text := sql_text || ',' || '''' || (datojson->>'largo_cubreposte')::text || '''';
	end if;
elseif tabla_tipo_in = 'negocio' then
	if datojson->'nombre_negocio' is not null then
		sql_text := sql_text || ',' || '''' || (datojson->>'nombre_negocio')::text || '''';
	end if;
elseif tabla_tipo_in = 'caracteristica_aterramiento' then
	if datojson->'modelo' is not null then
		sql_text := sql_text || ',' || '''' || (datojson->>'modelo')::text || '''';
	end if;
elseif tabla_tipo_in = 'caracteristica_pertiga' then
	if datojson->'modelo' is not null then
		sql_text := sql_text || ',' || '''' || (datojson->>'modelo')::text || '''';
	end if;
else
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
	if datojson->'modelo_aterramiento' is not null then
		sql_text := sql_text || ',' || (datojson->>'modelo_aterramiento')::text;
	end if;
	if datojson->'modelo_cubrelinea' is not null then
		sql_text := sql_text || ',' || (datojson->>'modelo_cubrelinea')::text;
	end if;
	if datojson->'modelo_pertiga' is not null then
		sql_text := sql_text || ',' || (datojson->>'modelo_pertiga')::text;
	end if;
end if;
raise notice 'sql_text(9): %',sql_text;
sql_text := sql_text || ')';
if tabla_tipo_in = 'cuerpos_pertiga' then
	sql_text := 'INSERT INTO dielab.largo_pertiga ' || sql_text  || ';';
else
	sql_text := 'INSERT INTO dielab.' || tabla_tipo_in || ' ' || sql_text  || ';';
end if;

raise notice 'consulta: %', sql_text;
execute sql_text;
salida = '{"error":false, "msg":"Ingreso correcto"}';

return salida;
exception
	WHEN unique_violation THEN
		salida = '{"error":true, "msg":"El dato ya existe en la base de datos"}';
		return salida;
	when others then
		salida = '{"error":true, "msg":"No fue posible grabar el dato"}';
		return salida;
		

end;

$$;


ALTER FUNCTION dielab.ingresa_det_tipo_epp(tabla_tipo_in text, datojson json) OWNER TO postgres;

--
-- TOC entry 354 (class 1255 OID 165197)
-- Name: ingresa_detalle(bigint, json); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.ingresa_detalle(id_batea_in bigint, datojson json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare

myrec			record;
salida        	json;
otro			json;
newDatoJson		json;
detalleJson		json;
id_detalle_auto	bigint;
serie_bigint	bigint;
begin

select * into myrec from dielab.encabezado_ensayo where id_batea = id_batea_in;
if found then
	--ok
	raise notice '(1) %', datojson;
	delete from dielab.detalle_ensayo where id_batea = id_batea_in;
	for i in 0..100 loop
		raise notice '(2)';
		if datojson->'detalle'->i is null then
			raise notice '(2.1)';
			exit;
		end if;
		select nextval('dielab.seq_id_tabla'::regclass) into id_detalle_auto;
		
		select id_epp into serie_bigint from dielab.epps 
		where serie_epp = datojson->'detalle'->i->>'serie_epp';
		if found then
			-- se encuentra el epp
			-- ver si es loadbuster
			if datojson->'detalle'->i->>'patron1' is not null then
				-- trae datos de loadbuster
				--raise notice 'loadbuster: %', datojson->'detalle'->i;
				SELECT ('{ ' || string_agg('"' || key || '" : ' || value, ', ') || ' }')::JSON into detalleJson FROM
				(select * from json_each(datojson->'detalle'->i) where key not in ('patron1', 'patron2', 'patron3')
				UNION ALL 
				 select 'patron1', ('{"num":' || num::text || ', "descripcion":"' || descripcion || '","marca":"' || nombre_marca || '","modelo":"' || 
				modelo || '","serie":"' || serie  || '","calibracion":"' || mes_calibracion || '-' || 
				periodo_calibracion || '"}')::json from dielab.select_patron where num = (datojson->'detalle'->i->>'patron1')::bigint
				UNION ALL 
				 select 'patron2', ('{"num":' || num::text || ', "descripcion":"' || descripcion || '","marca":"' || nombre_marca || '","modelo":"' || 
				modelo || '","serie":"' || serie  || '","calibracion":"' || mes_calibracion || '-' || 
				periodo_calibracion || '"}')::json from dielab.select_patron where num = (datojson->'detalle'->i->>'patron2')::bigint
				UNION ALL 
				 select 'patron3', ('{"num":' || num::text || ', "descripcion":"' || descripcion || '","marca":"' || nombre_marca || '","modelo":"' || 
				modelo || '","serie":"' || serie  || '","calibracion":"' || mes_calibracion || '-' || 
				periodo_calibracion || '"}')::json from dielab.select_patron where num = (datojson->'detalle'->i->>'patron3')::bigint) as t;
				--raise notice 'cambiado %', newDatoJson;
				newDatoJson := '{"detalle":[' || detalleJson || ']}';
				raise notice 'cambiado %', newDatoJson;
			else
				newDatoJson := datojson;
			end if;
			
			raise notice '(3) %', newDatoJson; 
			select * into myrec from dielab.detalle_ensayo where id_batea = id_batea_in
			and serie_epp = serie_bigint;
			if found then
			-- ya existe, actualizar
				raise notice '(4)';
				update dielab.detalle_ensayo 
				set aprobado = case when upper(newDatoJson->'detalle'->i->>'resultado') = 'APROBADO' then true else false end,
				detalle = newDatoJson->'detalle'->i
				where id_batea = id_batea_in
				and serie_epp = serie_bigint;
				raise notice '(5)';
			else
			-- no existe, insertar
				raise notice '(6)';
				insert into dielab.detalle_ensayo 
				VALUES (id_detalle_auto, id_batea_in, serie_bigint, case when upper(newDatoJson->'detalle'->i->>'resultado') = 'APROBADO' then true else false end,
					   newDatoJson->'detalle'->i);
			end if;
			raise notice '(7)';
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
-- TOC entry 355 (class 1255 OID 165198)
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
-- TOC entry 356 (class 1255 OID 165199)
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
-- TOC entry 357 (class 1255 OID 165200)
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
-- TOC entry 358 (class 1255 OID 165201)
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
-- TOC entry 359 (class 1255 OID 165202)
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
-- TOC entry 360 (class 1255 OID 165203)
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
-- TOC entry 361 (class 1255 OID 165204)
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
-- TOC entry 362 (class 1255 OID 165205)
-- Name: ingresa_epp(character varying, integer, integer, character varying, integer, integer, character varying, integer, integer); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.ingresa_epp(cod_epp character varying, tipo integer, clientex integer, sucursalx character varying, negociox integer, valor_estado integer, tipo_epp character varying, periodicidadx integer, estado_usox integer) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare

resulta       	record;
resulta_0       record;
codigo_en		double precision;
idepp		double precision;
salida        	json;
id_cli_n_s		integer;
clase_eppX		bigint;
actualizar		boolean;

begin
actualizar := false;
SELECT id_clase_epp into resulta FROM dielab.clase_epp
where upper(cod_serie) = upper(tipo_epp);
if found then
	select * into resulta_0 from dielab.epps where serie_epp = cod_epp;
	if found then
		-- ya está el epp, actualizar
		actualizar = true;
	end if;

	clase_eppX = resulta.id_clase_epp;
	if not actualizar then
		select nextval('dielab.seq_id_tabla'::regclass) into idepp;
	end if;
	if found then
	--ok
		--select nextval('dielab.seq_cod_ensayo'::regclass) into codigo_en;
		--if found then
			select * into resulta from dielab.cliente_negocio_sucursal where
			cliente = clienteX and negocio = negocioX and sucursal = sucursalX;
			if found then
				id_cli_n_s := resulta.id_cliente_n_s;
				if actualizar then
					update dielab.epps set clase_epp = clase_eppX, tipo_epp = tipo,
					cliente_n_s = id_cli_n_s, estado_epp = valor_estado, periodicidad = periodicidadX,
					estado_uso = estado_usoX where serie_epp = cod_epp;
				else
					INSERT INTO dielab.epps
					VALUES (idepp, cod_epp, clase_eppX, tipo, id_cli_n_s, valor_estado, periodicidadX, estado_usoX);
					salida = '{"error":false, "msg":"Epp ingresado"}';
				end if;
			else
				---salida = '{"error":true, "msg":"(4) Se produjo un error al insertar el epp"}';
				-- no se encuentra la combinacion de cliente/negocio/sucursal
				-- ingresarla
				insert into dielab.cliente_negocio_sucursal (cliente, negocio, sucursal)
				values (clienteX, negocioX, sucursalX);
				select * into resulta from dielab.cliente_negocio_sucursal where
				cliente = clienteX and negocio = negocioX and sucursal = sucursalX;
				if found then
					id_cli_n_s := resulta.id_cliente_n_s;
					if actualizar then
						update dielab.epps set clase_epp = clase_eppX, tipo_epp = tipo,
						cliente_n_s = id_cli_n_s, estado_epp = valor_estado, periodicidad = periodicidadX,
						estado_uso = estado_usoX where serie_epp = cod_epp;
					else
						INSERT INTO dielab.epps
						VALUES (idepp, cod_epp, clase_eppX, tipo, id_cli_n_s, valor_estado, periodicidadX, estado_usoX);
						salida = '{"error":false, "msg":"Epp ingresado"}';
					end if;
				else
					salida = '{"error":true, "msg":"(4) Se produjo un error al insertar el epp"}';
				end if;
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
-- TOC entry 363 (class 1255 OID 165206)
-- Name: ingresa_epp_borrar(character varying, integer, integer, character varying, integer, integer, character varying); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.ingresa_epp_borrar(cod_epp character varying, tipo integer, clientex integer, sucursalx character varying, negociox integer, valor_estado integer, tipo_epp character varying) RETURNS json
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


ALTER FUNCTION dielab.ingresa_epp_borrar(cod_epp character varying, tipo integer, clientex integer, sucursalx character varying, negociox integer, valor_estado integer, tipo_epp character varying) OWNER TO postgres;

--
-- TOC entry 364 (class 1255 OID 165207)
-- Name: ingresa_epp_ldb(character varying, integer, integer, character varying, integer, integer, character varying, integer, integer, text); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.ingresa_epp_ldb(cod_epp character varying, tipo integer, clientex integer, sucursalx character varying, negociox integer, valor_estado integer, tipo_epp character varying, periodicidadx integer, estado_usox integer, serie_fabrica text) RETURNS json
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
				INSERT INTO dielab.serie_loadbuster values (idepp, serie_fabrica);
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


ALTER FUNCTION dielab.ingresa_epp_ldb(cod_epp character varying, tipo integer, clientex integer, sucursalx character varying, negociox integer, valor_estado integer, tipo_epp character varying, periodicidadx integer, estado_usox integer, serie_fabrica text) OWNER TO postgres;

--
-- TOC entry 365 (class 1255 OID 165208)
-- Name: ingresa_usuario(text, text, text, text, text, text, bigint); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.ingresa_usuario(nombre_usuariox text, nombre_personax text, rutx text, emailx text, telefonox text, passwordx text, clientex bigint) RETURNS json
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

insert into dielab.personas (rut, nombre, email, telefono,suspendida)
values (rutX, nombre_personaX, emailX, telefonoX, false);

select max(id) as valor_max into myrec from dielab.usuarios;
if found then
	serie_bigint := myrec.valor_max + 1;
else
	serie_bigint := 0;
end if;
insert into dielab.usuarios values (serie_bigint, 3, rutX, md5(passwordX), 
									clienteX, nombre_usuarioX, false);

salida := '{"error":false, "msg":"Ingreso correcto"}';

return salida;
exception
	WHEN unique_violation THEN
		salida = '{"error":true, "msg":"El dato ya existe en la base de datos"}';
		return salida;
	when others then
		salida = '{"error":true, "msg":"No fue posible grabar el dato, revise que todos los campos esten ingresados"}';
		return salida;

end;

$$;


ALTER FUNCTION dielab.ingresa_usuario(nombre_usuariox text, nombre_personax text, rutx text, emailx text, telefonox text, passwordx text, clientex bigint) OWNER TO postgres;

--
-- TOC entry 366 (class 1255 OID 165209)
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
-- TOC entry 367 (class 1255 OID 165210)
-- Name: test_json(); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.test_json() RETURNS json
    LANGUAGE plpgsql
    AS $$
declare

resulta			record;
salida			json;
dato			json;
linea			text;
linea_data		text;
fila_datos		text;
sql_data		text;
num_campos		integer;
campos			text;
begin

dato := '{"uno":"dato", "dos":"1"}'::json;



return dato->>'dos';
end;

$$;


ALTER FUNCTION dielab.test_json() OWNER TO postgres;

--
-- TOC entry 368 (class 1255 OID 165211)
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
-- TOC entry 369 (class 1255 OID 165212)
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
		select * into resultado from dielab.tecnicos_ensayo where nombre = (datojson->>'tecnico_ensayo')::text;
		if found then
			if id_parametroX = resultado.id_tecnico then
				--- es el mismo tecnico
				update dielab.tecnicos_ensayo set comentario = (datojson->>'comentario')::text
				where id_tecnico = id_parametroX;
				salida = '{"error":false, "msg":"Ingreso correcto"}';
			else
				salida = '{"error":true, "msg":"El nombre de técnico ya existe en la base"}';
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
elseif tabla_tipo_in = 'cliente' then
	select * into myrec from dielab.cliente where id_cliente = id_parametroX;
	if found then
		select * into resultado from dielab.cliente where nombre = (datojson->>'nombre')::text;
		if found then
			if id_parametroX = resultado.id_cliente then
			--mismo cliente, actualizar
				update dielab.cliente set telefono = (datojson->>'telefono')::text,
				representante = (datojson->>'representante')::text,
				direccion = (datojson->>'direccion')::text,
				nombre_corto = (datojson->>'nombre_corto')::text
				where id_cliente = id_parametroX;
				salida = '{"error":false, "msg":"Ingreso correcto"}';
			else
				salida = '{"error":true, "msg":"El nombre de cliente ya existe en la base"}';
			end if;
		else
				update dielab.cliente set nombre = (datojson->>'nombre')::text,
				telefono = (datojson->>'telefono')::text,
				representante = (datojson->>'representante')::text,
				direccion = (datojson->>'direccion')::text,
				nombre_corto = (datojson->>'nombre_corto')::text
				where id_cliente = id_parametroX;
				salida = '{"error":false, "msg":"Ingreso correcto"}';
		end if;
	else
		salida = '{"error":true, "msg":"No existe el ID para el cliente"}';
	end if;
elseif tabla_tipo_in = 'marca' then
	select * into myrec from dielab.marca where id_marca = id_parametroX;
	if found then
		select * into resultado from dielab.marca where nombre = (datojson->>'nombre_marca')::text;
		if found then
			if id_parametroX = resultado.id_marca then
			--mismo registro
				update dielab.marca set nombre = (datojson->>'nombre_marca')::text
				where id_marca = id_parametroX;
				salida = '{"error":false, "msg":"Ingreso correcto"}';
			else
				salida = '{"error":true, "msg":"El nombre ya existe en la base"}';
			end if;
		else
			update dielab.marca set nombre = (datojson->>'nombre_marca')::text
			where id_marca = id_parametroX;
			salida = '{"error":false, "msg":"Ingreso correcto"}';
		end if;
	else
		salida = '{"error":true, "msg":"No existe el ID"}';
	end if;
elseif tabla_tipo_in = 'cuerpos_aterramiento' then
	select * into myrec from dielab.cuerpos_aterramiento where id = id_parametroX;
	if found then
		select * into resultado from dielab.cuerpos_aterramiento 
		where nombre = (datojson->>'cuerpos')::text;
		if found then
			if id_parametroX = resultado.id then
			--mismo registro
				update dielab.cuerpos_aterramiento 
				set nombre = (datojson->>'cuerpos')::text
				where id = id_parametroX;
				salida = '{"error":false, "msg":"Ingreso correcto"}';
			else
				salida = '{"error":true, "msg":"El nombre ya existe en la base"}';
			end if;
		else
			update dielab.cuerpos_aterramiento 
			set nombre = (datojson->>'cuerpos')::text
			where id = id_parametroX;
			salida = '{"error":false, "msg":"Ingreso correcto"}';
		end if;
	else
		salida = '{"error":true, "msg":"No existe el ID"}';
	end if;
elseif tabla_tipo_in = 'cuerpos_pertiga' then
	select * into myrec from dielab.largo_pertiga where id = id_parametroX;
	if found then
		select * into resultado from dielab.largo_pertiga 
		where nombre = (datojson->>'cuerpos')::text;
		if found then
			if id_parametroX = resultado.id then
			--mismo registro
				update dielab.largo_pertiga 
				set nombre = (datojson->>'cuerpos')::text
				where id = id_parametroX;
				salida = '{"error":false, "msg":"Ingreso correcto"}';
			else
				salida = '{"error":true, "msg":"El nombre ya existe en la base"}';
			end if;
		else
			update dielab.largo_pertiga 
			set nombre = (datojson->>'cuerpos')::text
			where id = id_parametroX;
			salida = '{"error":false, "msg":"Ingreso correcto"}';
		end if;
	else
		salida = '{"error":true, "msg":"No existe el ID"}';
	end if;
elseif tabla_tipo_in = 'largo_guante' then
	select * into myrec from dielab.largo_guante where id_largo = id_parametroX;
	if found then
		select * into resultado from dielab.largo_guante 
		where valor = (datojson->>'largo_guante')::integer;
		if found then
			if id_parametroX = resultado.id_largo then
			--mismo registro
				update dielab.largo_guante 
				set valor = (datojson->>'largo_guante')::integer
				where id_largo = id_parametroX;
				salida = '{"error":false, "msg":"Ingreso correcto"}';
			else
				salida = '{"error":true, "msg":"El nombre ya existe en la base"}';
			end if;
		else
			update dielab.largo_guante 
			set valor = (datojson->>'largo_guante')::integer
			where id_largo = id_parametroX;
			salida = '{"error":false, "msg":"Ingreso correcto"}';
		end if;
	else
		salida = '{"error":true, "msg":"No existe el ID"}';
	end if;
elseif tabla_tipo_in = 'largo_cubrelinea' then
	select * into myrec from dielab.largo_cubrelinea where id = id_parametroX;
	if found then
		select * into resultado from dielab.largo_cubrelinea 
		where nombre = (datojson->>'modelo_cubrelinea')::text;
		if found then
			if id_parametroX = resultado.id then
			--mismo registro
				update dielab.largo_cubrelinea 
				set nombre = (datojson->>'modelo_cubrelinea')::text
				where id = id_parametroX;
				salida = '{"error":false, "msg":"Ingreso correcto"}';
			else
				salida = '{"error":true, "msg":"El nombre ya existe en la base"}';
			end if;
		else
			update dielab.largo_cubrelinea 
			set nombre = (datojson->>'modelo_cubrelinea')::text
			where id = id_parametroX;
			salida = '{"error":false, "msg":"Ingreso correcto"}';
		end if;
	else
		salida = '{"error":true, "msg":"No existe el ID"}';
	end if;
elseif tabla_tipo_in = 'largo_manta' then
	select * into myrec from dielab.largo_manta where id = id_parametroX;
	if found then
		select * into resultado from dielab.largo_manta 
		where nombre = (datojson->>'largo_manta')::text;
		if found then
			if id_parametroX = resultado.id then
			--mismo registro
				update dielab.largo_manta 
				set nombre = (datojson->>'largo_manta')::text
				where id = id_parametroX;
				salida = '{"error":false, "msg":"Ingreso correcto"}';
			else
				salida = '{"error":true, "msg":"El nombre ya existe en la base"}';
			end if;
		else
			update dielab.largo_manta 
			set nombre = (datojson->>'largo_manta')::text
			where id = id_parametroX;
			salida = '{"error":false, "msg":"Ingreso correcto"}';
		end if;
	else
		salida = '{"error":true, "msg":"No existe el ID"}';
	end if;
elseif tabla_tipo_in = 'caracteristica_aterramiento' then
	select * into myrec from dielab.caracteristica_aterramiento where id = id_parametroX;
	if found then
		select * into resultado from dielab.caracteristica_aterramiento 
		where nombre = (datojson->>'modelo')::text;
		if found then
			if id_parametroX = resultado.id then
			--mismo registro
				update dielab.caracteristica_aterramiento 
				set nombre = (datojson->>'modelo')::text
				where id = id_parametroX;
				salida = '{"error":false, "msg":"Ingreso correcto"}';
			else
				salida = '{"error":true, "msg":"El nombre ya existe en la base"}';
			end if;
		else
			update dielab.caracteristica_aterramiento 
			set nombre = (datojson->>'modelo')::text
			where id = id_parametroX;
			salida = '{"error":false, "msg":"Ingreso correcto"}';
		end if;
	else
		salida = '{"error":true, "msg":"No existe el ID"}';
	end if;
elseif tabla_tipo_in = 'caracteristica_pertiga' then
	select * into myrec from dielab.caracteristica_pertiga where id = id_parametroX;
	if found then
		select * into resultado from dielab.caracteristica_pertiga 
		where nombre = (datojson->>'modelo')::text;
		if found then
			if id_parametroX = resultado.id then
			--mismo registro
				update dielab.caracteristica_pertiga 
				set nombre = (datojson->>'modelo')::text
				where id = id_parametroX;
				salida = '{"error":false, "msg":"Ingreso correcto"}';
			else
				salida = '{"error":true, "msg":"El nombre ya existe en la base"}';
			end if;
		else
			update dielab.caracteristica_pertiga 
			set nombre = (datojson->>'modelo')::text
			where id = id_parametroX;
			salida = '{"error":false, "msg":"Ingreso correcto"}';
		end if;
	else
		salida = '{"error":true, "msg":"No existe el ID"}';
	end if;
elseif tabla_tipo_in = 'largo_cubreposte' then
	select * into myrec from dielab.largo_cubreposte where id = id_parametroX;
	if found then
		select * into resultado from dielab.largo_cubreposte 
		where nombre = (datojson->>'largo_cubreposte')::integer;
		if found then
			if id_parametroX = resultado.id then
			--mismo registro
				update dielab.largo_cubreposte 
				set nombre = (datojson->>'largo_cubreposte')::integer
				where id = id_parametroX;
				salida = '{"error":false, "msg":"Ingreso correcto"}';
			else
				salida = '{"error":true, "msg":"El nombre ya existe en la base"}';
			end if;
		else
			update dielab.largo_cubreposte 
			set nombre = (datojson->>'largo_cubreposte')::integer
			where id = id_parametroX;
			salida = '{"error":false, "msg":"Ingreso correcto"}';
		end if;
	else
		salida = '{"error":true, "msg":"No existe el ID"}';
	end if;
elseif tabla_tipo_in = 'negocio' then
	select * into myrec from dielab.negocio where id_negocio = id_parametroX;
	if found then
		select * into resultado from dielab.negocio 
		where nombre = (datojson->>'nombre_negocio')::text;
		if found then
			if id_parametroX = resultado.id_negocio then
			--mismo registro
				update dielab.negocio 
				set nombre = (datojson->>'nombre_negocio')::text
				where id_negocio = id_parametroX;
				salida = '{"error":false, "msg":"Ingreso correcto"}';
			else
				salida = '{"error":true, "msg":"El nombre ya existe en la base"}';
			end if;
		else
			update dielab.negocio 
			set nombre = (datojson->>'nombre_negocio')::text
			where id_negocio = id_parametroX;
			salida = '{"error":false, "msg":"Ingreso correcto"}';
		end if;
	else
		salida = '{"error":true, "msg":"No existe el ID"}';
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
-- TOC entry 370 (class 1255 OID 165213)
-- Name: update_usuario(text, text, text, text, text, text, bigint, integer); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.update_usuario(nombre_usuariox text, nombre_personax text, rutx text, emailx text, telefonox text, passwordx text, clientex bigint, id_parametrox integer) RETURNS json
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

select * into myrec from dielab.personas where rut = rutx;
if found then
	-- ya existe, actualizar
	update dielab.personas set nombre=nombre_personaX, 
	email=emailX, telefono=telefonoX where rut = rutx;
else
	insert into dielab.personas (rut, nombre, email, telefono,suspendida)
	values (rutX, nombre_personaX, emailX, telefonoX, false);
end if;

select * into myrec from dielab.usuarios where id = id_parametroX;
if found then
	update dielab.usuarios set rut = rutx, password_md5 = md5(passwordX),
	cliente = clienteX, usuario = nombre_usuarioX
	where id = id_parametroX;
else
	salida := '{"error":true, "msg":"El ID de usuario no está en la base"}';
	return salida;
end if;

salida := '{"error":false, "msg":"Actualizado correctamente"}';

return salida;
exception
	WHEN unique_violation THEN
		salida = '{"error":true, "msg":"El dato ya existe en la base de datos"}';
		return salida;
	when others then
		salida = '{"error":true, "msg":"No fue posible grabar el dato, revise que todos los campos esten ingresados"}';
		return salida;

end;

$$;


ALTER FUNCTION dielab.update_usuario(nombre_usuariox text, nombre_personax text, rutx text, emailx text, telefonox text, passwordx text, clientex bigint, id_parametrox integer) OWNER TO postgres;

--
-- TOC entry 371 (class 1255 OID 165214)
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
-- TOC entry 372 (class 1255 OID 165215)
-- Name: verifica_epp_guante(character varying, integer, character varying, integer); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.verifica_epp_guante(epp character varying, clientex integer, sucursalx character varying, negociox integer) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare

resultado		record;
resulta_0		record;
salida			json;
begin
	select * into resultado from dielab.epps where serie_epp = epp;
	if found then
		select * into resulta_0 from dielab.cliente_negocio_sucursal where
		cliente = clienteX and negocio = negocioX and sucursal = sucursalX;
		if found then
			if resulta_0.id_cliente_n_s <> resultado.cliente_n_s then
				salida = '{"error":true, "msg":"El elemento no perteneca al mismo CLIENTE-NEGOCIO-SUCURSAL que el ensayo"}';
			else
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
			end if;
		else
			salida = '{"error":true, "msg":"Hay un error con la combinación CLIENTE-NEGOCIO-SUCURSAL del ensayo"}';
		end if;
	else
		salida = '{"error":true, "msg":"No existe el elemento"}';
	end if;

return salida;
end;

$$;


ALTER FUNCTION dielab.verifica_epp_guante(epp character varying, clientex integer, sucursalx character varying, negociox integer) OWNER TO postgres;

--
-- TOC entry 373 (class 1255 OID 165216)
-- Name: verifica_epp_guante_borra(character varying); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.verifica_epp_guante_borra(epp character varying) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare

resultado		record;
resulta_0		record;
salida			json;
begin
	select * into resultado from dielab.epps where serie_epp = epp;
	if found then
		select * into resulta_0 from dielab.cliente_negocio_sucursal where
		cliente = clienteX and negocio = negocioX and sucursal = sucursalX;
		if found then
			if resulta_0.id_cliente_n_s <> resultado.cliente_n_s then
				salida = '{"error":true, "msg":"El elemento no perteneca al mismo CLIENTE-NEGOCIO-SUCURSAL que el ensayo"}';
			else
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
			end if;
		else
			salida = '{"error":true, "msg":"Hay un error con la combinación CLIENTE-NEGOCIO-SUCURSAL del ensayo"}';
		end if;
	else
		salida = '{"error":true, "msg":"No existe el elemento"}';
	end if;

return salida;
end;

$$;


ALTER FUNCTION dielab.verifica_epp_guante_borra(epp character varying) OWNER TO postgres;

--
-- TOC entry 374 (class 1255 OID 165217)
-- Name: verifica_epp_guante_borra(character varying, bigint); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.verifica_epp_guante_borra(epp character varying, id_bateax bigint) RETURNS json
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


ALTER FUNCTION dielab.verifica_epp_guante_borra(epp character varying, id_bateax bigint) OWNER TO postgres;

--
-- TOC entry 314 (class 1255 OID 165218)
-- Name: verifica_epp_ldb(character varying); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.verifica_epp_ldb(epp character varying) RETURNS json
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
			if resultado.clase_epp = 6 then
			--ldb, buscar serie de fabrica
				select serie as serie_fabrica into resultado from dielab.serie_loadbuster join dielab.epps using (id_epp)
				where serie_epp = epp;
				if found then
					salida = '{"error":false, "msg":"' || resultado.serie_fabrica || '"}';
				else
					salida = '{"error":true, "msg":"El elemento no tiene serie de fabrica"}';
				end if;	
			else
			-- no es ldb, ne debe entrar aquí
				salida = '{"error":true, "msg":"El elemento no es LoadBuster"}';
			end if;
		end if;
	else
		salida = '{"error":true, "msg":"No existe el elemento"}';
	end if;

return salida;
end;

$$;


ALTER FUNCTION dielab.verifica_epp_ldb(epp character varying) OWNER TO postgres;

--
-- TOC entry 375 (class 1255 OID 165219)
-- Name: verifica_epp_ldb(character varying, integer, character varying, integer); Type: FUNCTION; Schema: dielab; Owner: postgres
--

CREATE FUNCTION dielab.verifica_epp_ldb(epp character varying, clientex integer, sucursalx character varying, negociox integer) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare

resultado		record;
resulta_0		record;
salida			json;
begin
	select * into resultado from dielab.epps where serie_epp = epp;
	if found then
		select * into resulta_0 from dielab.cliente_negocio_sucursal where
		cliente = clienteX and negocio = negocioX and sucursal = sucursalX;
		if found then
			if resulta_0.id_cliente_n_s <> resultado.cliente_n_s then
				salida = '{"error":true, "msg":"El elemento no perteneca al mismo CLIENTE-NEGOCIO-SUCURSAL que el ensayo"}';
			else
							if resultado.estado_epp = 3 then
							-- fue dado de baja
								salida = '{"error":true, "msg":"El elemento fue dado de baja"}';
							else
								if resultado.clase_epp = 6 then
								--ldb, buscar serie de fabrica
									select serie as serie_fabrica into resultado from dielab.serie_loadbuster join dielab.epps using (id_epp)
									where serie_epp = epp;
									if found then
										salida = '{"error":false, "msg":"' || resultado.serie_fabrica || '"}';
									else
										salida = '{"error":true, "msg":"El elemento no tiene serie de fabrica"}';
									end if;	
								else
								-- no es ldb, ne debe entrar aquí
									salida = '{"error":true, "msg":"El elemento no es LoadBuster"}';
								end if;
							end if;
			end if;
		else
			salida = '{"error":true, "msg":"Hay un error con la combinación CLIENTE-NEGOCIO-SUCURSAL del ensayo"}';
		end if;
	else
		salida = '{"error":true, "msg":"No existe el elemento"}';
	end if;

return salida;
end;

$$;


ALTER FUNCTION dielab.verifica_epp_ldb(epp character varying, clientex integer, sucursalx character varying, negociox integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 202 (class 1259 OID 165220)
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
-- TOC entry 3831 (class 0 OID 0)
-- Dependencies: 202
-- Name: TABLE clase_epp; Type: COMMENT; Schema: dielab; Owner: postgres
--

COMMENT ON TABLE dielab.clase_epp IS 'Describe las clases de Epp que existen como guantes, pertigas, banquetas, etc.';


--
-- TOC entry 203 (class 1259 OID 165227)
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
-- TOC entry 204 (class 1259 OID 165234)
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
-- TOC entry 205 (class 1259 OID 165236)
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
-- TOC entry 206 (class 1259 OID 165243)
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
-- TOC entry 207 (class 1259 OID 165249)
-- Name: estado_ensayo; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.estado_ensayo (
    id_estado integer NOT NULL,
    nombre character varying NOT NULL,
    observacion character varying
);


ALTER TABLE dielab.estado_ensayo OWNER TO postgres;

--
-- TOC entry 208 (class 1259 OID 165255)
-- Name: negocio; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.negocio (
    id_negocio integer NOT NULL,
    nombre character varying NOT NULL
);


ALTER TABLE dielab.negocio OWNER TO postgres;

--
-- TOC entry 209 (class 1259 OID 165261)
-- Name: sucursales; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.sucursales (
    cod_sucursal character varying(6) NOT NULL,
    nombre character varying(50) NOT NULL
);


ALTER TABLE dielab.sucursales OWNER TO postgres;

--
-- TOC entry 210 (class 1259 OID 165264)
-- Name: lista_ensayos_emitidos; Type: VIEW; Schema: clientes; Owner: postgres
--

CREATE VIEW clientes.lista_ensayos_emitidos AS
 SELECT initcap((cliente.nombre_corto)::text) AS nombre_cliente,
    clase_epp.nombre_menu AS elemento,
    encabezado_ensayo.fecha_ejecucion AS fecha_ensayo,
    encabezado_ensayo.cod_ensayo AS codigo,
    clase_epp.cod_serie AS cod_elemento,
    cliente.id_cliente AS cliente
   FROM ((((((dielab.encabezado_ensayo
     JOIN dielab.cliente_negocio_sucursal ON ((encabezado_ensayo.cliente_n_s = cliente_negocio_sucursal.id_cliente_n_s)))
     JOIN dielab.cliente ON ((cliente_negocio_sucursal.cliente = cliente.id_cliente)))
     JOIN dielab.sucursales ON (((cliente_negocio_sucursal.sucursal)::text = (sucursales.cod_sucursal)::text)))
     JOIN dielab.negocio ON ((cliente_negocio_sucursal.negocio = negocio.id_negocio)))
     JOIN dielab.estado_ensayo ON ((encabezado_ensayo.cod_estado = estado_ensayo.id_estado)))
     JOIN dielab.clase_epp ON ((clase_epp.id_clase_epp = encabezado_ensayo.tipo_ensayo)))
  WHERE (estado_ensayo.id_estado = 3)
  ORDER BY encabezado_ensayo.id_batea DESC;


ALTER TABLE clientes.lista_ensayos_emitidos OWNER TO postgres;

--
-- TOC entry 211 (class 1259 OID 165269)
-- Name: clase_tipo; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.clase_tipo (
    cod_clase character varying NOT NULL,
    descripcion character varying NOT NULL,
    id_clase bigint NOT NULL
);


ALTER TABLE dielab.clase_tipo OWNER TO postgres;

--
-- TOC entry 3832 (class 0 OID 0)
-- Dependencies: 211
-- Name: TABLE clase_tipo; Type: COMMENT; Schema: dielab; Owner: postgres
--

COMMENT ON TABLE dielab.clase_tipo IS 'Describe las clases de dielectrico: 00, 0 , 1 etc.';


--
-- TOC entry 212 (class 1259 OID 165275)
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
-- TOC entry 213 (class 1259 OID 165281)
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
-- TOC entry 214 (class 1259 OID 165287)
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
-- TOC entry 215 (class 1259 OID 165293)
-- Name: nombres_epp_ensayo_cliente; Type: VIEW; Schema: clientes; Owner: postgres
--

CREATE VIEW clientes.nombres_epp_ensayo_cliente AS
 SELECT elementos.nombre,
    detalle_ensayo.aprobado,
    encabezado_ensayo.fecha_ejecucion,
    cliente_negocio_sucursal.cliente
   FROM (((dielab.detalle_ensayo
     JOIN dielab.encabezado_ensayo USING (id_batea))
     JOIN dielab.cliente_negocio_sucursal ON ((encabezado_ensayo.cliente_n_s = cliente_negocio_sucursal.id_cliente_n_s)))
     JOIN ( SELECT epps.id_epp,
                CASE
                    WHEN (((clase_tipo.cod_clase)::text = '0'::text) OR ((clase_tipo.cod_clase)::text = '00'::text)) THEN 'Guantes BT'::text
                    ELSE 'Guantes MT'::text
                END AS nombre
           FROM (((dielab.epps
             JOIN dielab.clase_epp ON ((epps.clase_epp = clase_epp.id_clase_epp)))
             JOIN dielab.tipo_guante ON ((epps.tipo_epp = tipo_guante.id_tipo)))
             JOIN dielab.clase_tipo ON ((clase_tipo.id_clase = tipo_guante.clase)))
          WHERE (epps.clase_epp = 1)
        UNION
         SELECT epps.id_epp,
            clase_epp.nombre_menu AS nombre
           FROM (dielab.epps
             JOIN dielab.clase_epp ON ((epps.clase_epp = clase_epp.id_clase_epp)))
          WHERE (epps.clase_epp <> 1)) elementos ON ((detalle_ensayo.serie_epp = elementos.id_epp)));


ALTER TABLE clientes.nombres_epp_ensayo_cliente OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 165298)
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
-- TOC entry 217 (class 1259 OID 165304)
-- Name: select_elemento; Type: VIEW; Schema: clientes; Owner: postgres
--

CREATE VIEW clientes.select_elemento AS
 SELECT clase_epp.cod_serie AS id,
    clase_epp.nombre_menu AS nombre
   FROM (dielab.ensayos_tipo
     JOIN dielab.clase_epp ON ((ensayos_tipo.id_ensayo_tipo = clase_epp.tipo_ensayo)))
  WHERE (ensayos_tipo.habilitado AND clase_epp.habilitado)
  ORDER BY clase_epp.prioridad;


ALTER TABLE clientes.select_elemento OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 165308)
-- Name: anual; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.anual (
    id integer NOT NULL,
    nombre character varying NOT NULL
);


ALTER TABLE dielab.anual OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 165314)
-- Name: caracteristica_aterramiento; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.caracteristica_aterramiento (
    id integer NOT NULL,
    nombre character varying NOT NULL
);


ALTER TABLE dielab.caracteristica_aterramiento OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 165320)
-- Name: caracteristica_pertiga; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.caracteristica_pertiga (
    id integer NOT NULL,
    nombre character varying NOT NULL
);


ALTER TABLE dielab.caracteristica_pertiga OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 165326)
-- Name: cuerpos_aterramiento; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.cuerpos_aterramiento (
    id bigint NOT NULL,
    nombre character varying NOT NULL
);


ALTER TABLE dielab.cuerpos_aterramiento OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 165332)
-- Name: elementos_informe; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.elementos_informe (
    id bigint NOT NULL,
    nombre text NOT NULL,
    prioridad integer NOT NULL
);


ALTER TABLE dielab.elementos_informe OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 165338)
-- Name: estado_epp; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.estado_epp (
    id_estado_epp integer NOT NULL,
    descripcion character varying NOT NULL
);


ALTER TABLE dielab.estado_epp OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 165344)
-- Name: estado_uso; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.estado_uso (
    id bigint NOT NULL,
    nombre_estado character varying NOT NULL
);


ALTER TABLE dielab.estado_uso OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 165350)
-- Name: largo_cubrelinea; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.largo_cubrelinea (
    id bigint NOT NULL,
    nombre character varying NOT NULL
);


ALTER TABLE dielab.largo_cubrelinea OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 165356)
-- Name: largo_cubreposte; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.largo_cubreposte (
    id integer NOT NULL,
    nombre integer NOT NULL
);


ALTER TABLE dielab.largo_cubreposte OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 165359)
-- Name: largo_guante; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.largo_guante (
    id_largo integer NOT NULL,
    valor integer NOT NULL
);


ALTER TABLE dielab.largo_guante OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 165362)
-- Name: largo_manta; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.largo_manta (
    id bigint NOT NULL,
    nombre character varying NOT NULL
);


ALTER TABLE dielab.largo_manta OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 165368)
-- Name: largo_pertiga; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.largo_pertiga (
    id bigint NOT NULL,
    nombre character varying NOT NULL
);


ALTER TABLE dielab.largo_pertiga OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 165374)
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
-- TOC entry 231 (class 1259 OID 165378)
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
-- TOC entry 232 (class 1259 OID 165383)
-- Name: lista_det_jumper; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.lista_det_jumper AS
 SELECT detalle_ensayo.id_detalle,
    detalle_ensayo.id_batea,
    (detalle_ensayo.detalle ->> 'serie_epp'::text) AS num_serie,
    (detalle_ensayo.detalle ->> 'fuga1'::text) AS i_fuga_1,
    (detalle_ensayo.detalle ->> 'tension'::text) AS tension_ensayo,
    (detalle_ensayo.detalle ->> 'visual'::text) AS visual,
    (detalle_ensayo.detalle ->> 'dieresul'::text) AS dieresul,
    (detalle_ensayo.detalle ->> 'tramo'::text) AS tramo,
    (detalle_ensayo.detalle ->> 'seccion'::text) AS seccion,
    (detalle_ensayo.detalle ->> 'longitud'::text) AS longitud,
    (detalle_ensayo.detalle ->> 'resismedida'::text) AS resismedida,
    (detalle_ensayo.detalle ->> 'resismax'::text) AS resismax,
    (detalle_ensayo.detalle ->> 'resisresul'::text) AS resisresul
   FROM ((dielab.detalle_ensayo
     JOIN dielab.epps ON ((detalle_ensayo.serie_epp = epps.id_epp)))
     JOIN dielab.clase_epp ON ((epps.clase_epp = clase_epp.id_clase_epp)))
  WHERE (clase_epp.id_clase_epp = 9)
  ORDER BY detalle_ensayo.id_batea, detalle_ensayo.serie_epp;


ALTER TABLE dielab.lista_det_jumper OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 165388)
-- Name: lista_det_loadbuster; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.lista_det_loadbuster AS
 SELECT detalle_ensayo.id_detalle,
    detalle_ensayo.id_batea,
    (detalle_ensayo.detalle ->> 'serie_epp'::text) AS num_serie,
    (detalle_ensayo.detalle ->> 'fuga1'::text) AS i_fuga_1,
    (detalle_ensayo.detalle ->> 'fuga2'::text) AS i_fuga_2,
    (detalle_ensayo.detalle ->> 'fuga3'::text) AS i_fuga_3,
    (detalle_ensayo.detalle ->> 'parches'::text) AS parches,
    (detalle_ensayo.detalle ->> 'promedio'::text) AS promed_fuga,
    (detalle_ensayo.detalle ->> 'tension'::text) AS tension_ensayo,
    (detalle_ensayo.detalle ->> 'resultado'::text) AS aprobado,
    (detalle_ensayo.detalle ->> 'serie_fabrica'::text) AS serie_fabrica,
    ((detalle_ensayo.detalle -> 'patron1'::text) ->> 'descripcion'::text) AS p1descripcion,
    ((detalle_ensayo.detalle -> 'patron1'::text) ->> 'marca'::text) AS p1marca,
    ((detalle_ensayo.detalle -> 'patron1'::text) ->> 'modelo'::text) AS p1modelo,
    ((detalle_ensayo.detalle -> 'patron1'::text) ->> 'serie'::text) AS p1serie,
    ((detalle_ensayo.detalle -> 'patron1'::text) ->> 'calibracion'::text) AS p1calibracion,
    ((detalle_ensayo.detalle -> 'patron2'::text) ->> 'descripcion'::text) AS p2descripcion,
    ((detalle_ensayo.detalle -> 'patron2'::text) ->> 'marca'::text) AS p2marca,
    ((detalle_ensayo.detalle -> 'patron2'::text) ->> 'modelo'::text) AS p2modelo,
    ((detalle_ensayo.detalle -> 'patron2'::text) ->> 'serie'::text) AS p2serie,
    ((detalle_ensayo.detalle -> 'patron2'::text) ->> 'calibracion'::text) AS p2calibracion,
    ((detalle_ensayo.detalle -> 'patron3'::text) ->> 'descripcion'::text) AS p3descripcion,
    ((detalle_ensayo.detalle -> 'patron3'::text) ->> 'marca'::text) AS p3marca,
    ((detalle_ensayo.detalle -> 'patron3'::text) ->> 'modelo'::text) AS p3modelo,
    ((detalle_ensayo.detalle -> 'patron3'::text) ->> 'serie'::text) AS p3serie,
    ((detalle_ensayo.detalle -> 'patron3'::text) ->> 'calibracion'::text) AS p3calibracion,
    (detalle_ensayo.detalle ->> 'tension1'::text) AS tension1,
    (detalle_ensayo.detalle ->> 'tension2'::text) AS tension2,
    (detalle_ensayo.detalle ->> 'tension3'::text) AS tension3,
    (detalle_ensayo.detalle ->> 'medida1'::text) AS medida1,
    (detalle_ensayo.detalle ->> 'medida2'::text) AS medida2,
    (detalle_ensayo.detalle ->> 'AR1'::text) AS ar1,
    (detalle_ensayo.detalle ->> 'AR2'::text) AS ar2,
    (detalle_ensayo.detalle ->> 'AR3'::text) AS ar3,
    (detalle_ensayo.detalle ->> 'ensayoresul'::text) AS ensayoresul,
    (detalle_ensayo.detalle ->> 'carcaz'::text) AS carcaz,
    (detalle_ensayo.detalle ->> 'gancho'::text) AS gancho,
    (detalle_ensayo.detalle ->> 'cancla'::text) AS cancla,
    (detalle_ensayo.detalle ->> 'contop'::text) AS contop,
    (detalle_ensayo.detalle ->> 'apertu'::text) AS apertu,
    (detalle_ensayo.detalle ->> 'anillo'::text) AS anillo,
    (detalle_ensayo.detalle ->> 'extiro'::text) AS extiro,
    (detalle_ensayo.detalle ->> 'citiro'::text) AS citiro,
    (detalle_ensayo.detalle ->> 'seguro'::text) AS seguro,
    (detalle_ensayo.detalle ->> 'cubier'::text) AS cubier,
    (detalle_ensayo.detalle ->> 'contad'::text) AS contad,
    (detalle_ensayo.detalle ->> 'insresultado'::text) AS insresultado
   FROM ((dielab.detalle_ensayo
     JOIN dielab.epps ON ((detalle_ensayo.serie_epp = epps.id_epp)))
     JOIN dielab.clase_epp ON ((epps.clase_epp = clase_epp.id_clase_epp)))
  WHERE (clase_epp.id_clase_epp = 6)
  ORDER BY detalle_ensayo.id_batea, detalle_ensayo.serie_epp;


ALTER TABLE dielab.lista_det_loadbuster OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 165393)
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
-- TOC entry 235 (class 1259 OID 165402)
-- Name: lista_detpdf_ldb; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.lista_detpdf_ldb AS
 SELECT '1'::text AS num_fila,
    lista_det_loadbuster.num_serie,
    tipo_loadbuster.marca,
    (tipo_loadbuster.largo)::text AS largo,
    (estado_uso.nombre_estado)::text AS usado,
    clase_tipo.cod_clase,
    lista_det_loadbuster.tension_ensayo,
        CASE
            WHEN (lista_det_loadbuster.parches ~ '^[0-9\.]+$'::text) THEN
            CASE
                WHEN ((lista_det_loadbuster.parches)::numeric > (0)::numeric) THEN lista_det_loadbuster.parches
                ELSE '--'::text
            END
            ELSE '--'::text
        END AS parches,
        CASE
            WHEN (lista_det_loadbuster.aprobado = 'RECHAZADO'::text) THEN 'Falla'::text
            ELSE
            CASE
                WHEN (lista_det_loadbuster.promed_fuga ~ '^[0-9\.]+$'::text) THEN to_char((lista_det_loadbuster.promed_fuga)::numeric, 'FM9.00'::text)
                ELSE '--'::text
            END
        END AS promed_fuga,
    to_char(tipo_loadbuster.corriente_fuga_max, 'FM9.00'::text) AS fuga_max,
    lista_det_loadbuster.aprobado,
    encabezado_ensayo.cod_ensayo,
    lista_det_loadbuster.serie_fabrica,
    lista_det_loadbuster.p1descripcion,
    lista_det_loadbuster.p1marca,
    lista_det_loadbuster.p1modelo,
    lista_det_loadbuster.p1serie,
    lista_det_loadbuster.p1calibracion,
    lista_det_loadbuster.p2descripcion,
    lista_det_loadbuster.p2marca,
    lista_det_loadbuster.p2modelo,
    lista_det_loadbuster.p2serie,
    lista_det_loadbuster.p2calibracion,
    lista_det_loadbuster.p3descripcion,
    lista_det_loadbuster.p3marca,
    lista_det_loadbuster.p3modelo,
    lista_det_loadbuster.p3serie,
    lista_det_loadbuster.p3calibracion,
    lista_det_loadbuster.tension1,
    lista_det_loadbuster.i_fuga_1,
    lista_det_loadbuster.ar1,
    lista_det_loadbuster.tension2,
    lista_det_loadbuster.medida1,
    lista_det_loadbuster.ar2,
    lista_det_loadbuster.tension3,
    lista_det_loadbuster.medida2,
    lista_det_loadbuster.ar3,
    lista_det_loadbuster.ensayoresul,
    lista_det_loadbuster.carcaz,
    lista_det_loadbuster.gancho,
    lista_det_loadbuster.cancla,
    lista_det_loadbuster.contop,
    lista_det_loadbuster.apertu,
    lista_det_loadbuster.anillo,
    lista_det_loadbuster.extiro,
    lista_det_loadbuster.citiro,
    lista_det_loadbuster.seguro,
    lista_det_loadbuster.cubier,
    lista_det_loadbuster.contad,
    lista_det_loadbuster.insresultado
   FROM (((((dielab.lista_det_loadbuster
     JOIN dielab.epps ON ((lista_det_loadbuster.num_serie = (epps.serie_epp)::text)))
     JOIN dielab.estado_uso ON ((epps.estado_uso = estado_uso.id)))
     JOIN dielab.tipo_loadbuster ON ((epps.tipo_epp = tipo_loadbuster.id_tipo)))
     JOIN dielab.clase_tipo ON ((tipo_loadbuster.clase = clase_tipo.id_clase)))
     JOIN dielab.encabezado_ensayo USING (id_batea));


ALTER TABLE dielab.lista_detpdf_ldb OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 165407)
-- Name: lista_ensayos; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.lista_ensayos AS
 SELECT encabezado_ensayo.id_batea AS id,
    encabezado_ensayo.cod_ensayo AS codigo,
    ((encabezado_ensayo.fecha)::date)::text AS fecha_ingreso,
    cliente.nombre_corto AS cliente,
    negocio.nombre AS negocio,
    estado_ensayo.nombre AS estado,
    encabezado_ensayo.tipo_ensayo,
    estado_ensayo.id_estado AS cod_estado
   FROM (((((dielab.encabezado_ensayo
     JOIN dielab.cliente_negocio_sucursal ON ((encabezado_ensayo.cliente_n_s = cliente_negocio_sucursal.id_cliente_n_s)))
     JOIN dielab.cliente ON ((cliente_negocio_sucursal.cliente = cliente.id_cliente)))
     JOIN dielab.sucursales ON (((cliente_negocio_sucursal.sucursal)::text = (sucursales.cod_sucursal)::text)))
     JOIN dielab.negocio ON ((cliente_negocio_sucursal.negocio = negocio.id_negocio)))
     JOIN dielab.estado_ensayo ON ((encabezado_ensayo.cod_estado = estado_ensayo.id_estado)))
  ORDER BY encabezado_ensayo.id_batea DESC;


ALTER TABLE dielab.lista_ensayos OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 165412)
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
-- TOC entry 238 (class 1259 OID 165417)
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
-- TOC entry 239 (class 1259 OID 165422)
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
-- TOC entry 240 (class 1259 OID 165427)
-- Name: serie_loadbuster; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.serie_loadbuster (
    id_epp integer NOT NULL,
    serie character varying NOT NULL
);


ALTER TABLE dielab.serie_loadbuster OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 165433)
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
    epps.estado_epp,
        CASE
            WHEN (( SELECT serie_loadbuster.serie
               FROM dielab.serie_loadbuster
              WHERE (serie_loadbuster.id_epp = epps.id_epp)) IS NULL) THEN ('000'::text)::character varying
            ELSE ( SELECT serie_loadbuster.serie
               FROM dielab.serie_loadbuster
              WHERE (serie_loadbuster.id_epp = epps.id_epp))
        END AS serie_fabrica
   FROM (dielab.epps
     JOIN dielab.cliente_negocio_sucursal ON ((cliente_negocio_sucursal.id_cliente_n_s = epps.cliente_n_s)));


ALTER TABLE dielab.lista_form_epps OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 165438)
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
-- TOC entry 243 (class 1259 OID 165446)
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
-- TOC entry 244 (class 1259 OID 165453)
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
    ((initcap((ensayos_tipo.descripcion)::text) || ' '::text) || ( SELECT dielab.get_caracterisica(encabezado_ensayo.cod_ensayo) AS get_caracterisica)) AS tipo_epp,
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
-- TOC entry 245 (class 1259 OID 165458)
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
-- TOC entry 246 (class 1259 OID 165462)
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
    cod_marca bigint NOT NULL,
    caracteristica integer
);


ALTER TABLE dielab.tipo_aterramiento OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 165471)
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
-- TOC entry 248 (class 1259 OID 165479)
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
-- TOC entry 249 (class 1259 OID 165486)
-- Name: tipo_cubreposte; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.tipo_cubreposte (
    id_tipo integer NOT NULL,
    marca character varying NOT NULL,
    modelo character varying,
    largo bigint NOT NULL,
    clase bigint NOT NULL,
    corriente_fuga_max double precision DEFAULT 0,
    descripcion character varying,
    cod_marca bigint
);


ALTER TABLE dielab.tipo_cubreposte OWNER TO postgres;

--
-- TOC entry 250 (class 1259 OID 165493)
-- Name: tipo_jumper; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.tipo_jumper (
    id_tipo integer NOT NULL,
    marca character varying,
    modelo character varying,
    largo bigint DEFAULT 0 NOT NULL,
    clase bigint NOT NULL,
    corriente_fuga_max double precision DEFAULT 0,
    descripcion character varying,
    cod_marca bigint
);


ALTER TABLE dielab.tipo_jumper OWNER TO postgres;

--
-- TOC entry 251 (class 1259 OID 165501)
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
-- TOC entry 252 (class 1259 OID 165509)
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
-- TOC entry 253 (class 1259 OID 165516)
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
    cod_marca bigint,
    caracteristica integer
);


ALTER TABLE dielab.tipo_pertiga OWNER TO postgres;

--
-- TOC entry 254 (class 1259 OID 165524)
-- Name: lista_tipo_marca_clase; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.lista_tipo_marca_clase AS
 SELECT tipo_guante.id_tipo,
    tipo_guante.marca,
    clase_tipo.descripcion AS clase,
    'tipo_guante'::text AS tipo_epp,
    clase_tipo.cod_clase
   FROM (dielab.tipo_guante
     JOIN dielab.clase_tipo ON ((tipo_guante.clase = clase_tipo.id_clase)))
UNION
 SELECT tipo_aterramiento.id_tipo,
    tipo_aterramiento.marca,
    clase_tipo.descripcion AS clase,
    'tipo_aterramiento'::text AS tipo_epp,
    clase_tipo.cod_clase
   FROM (dielab.tipo_aterramiento
     JOIN dielab.clase_tipo ON ((tipo_aterramiento.clase = clase_tipo.id_clase)))
UNION
 SELECT tipo_banqueta.id_tipo,
    tipo_banqueta.marca,
    clase_tipo.descripcion AS clase,
    'tipo_banqueta'::text AS tipo_epp,
    clase_tipo.cod_clase
   FROM (dielab.tipo_banqueta
     JOIN dielab.clase_tipo ON ((tipo_banqueta.clase = clase_tipo.id_clase)))
UNION
 SELECT tipo_cubrelinea.id_tipo,
    tipo_cubrelinea.marca,
    clase_tipo.descripcion AS clase,
    'tipo_cubrelinea'::text AS tipo_epp,
    clase_tipo.cod_clase
   FROM (dielab.tipo_cubrelinea
     JOIN dielab.clase_tipo ON ((tipo_cubrelinea.clase = clase_tipo.id_clase)))
UNION
 SELECT tipo_cubreposte.id_tipo,
    tipo_cubreposte.marca,
    clase_tipo.descripcion AS clase,
    'tipo_cubreposte'::text AS tipo_epp,
    clase_tipo.cod_clase
   FROM (dielab.tipo_cubreposte
     JOIN dielab.clase_tipo ON ((tipo_cubreposte.clase = clase_tipo.id_clase)))
UNION
 SELECT tipo_jumper.id_tipo,
    tipo_jumper.marca,
    clase_tipo.descripcion AS clase,
    'tipo_jumper'::text AS tipo_epp,
    clase_tipo.cod_clase
   FROM (dielab.tipo_jumper
     JOIN dielab.clase_tipo ON ((tipo_jumper.clase = clase_tipo.id_clase)))
UNION
 SELECT tipo_loadbuster.id_tipo,
    tipo_loadbuster.marca,
    clase_tipo.descripcion AS clase,
    'tipo_loadbuster'::text AS tipo_epp,
    clase_tipo.cod_clase
   FROM (dielab.tipo_loadbuster
     JOIN dielab.clase_tipo ON ((tipo_loadbuster.clase = clase_tipo.id_clase)))
UNION
 SELECT tipo_manguilla.id_tipo,
    tipo_manguilla.marca,
    clase_tipo.descripcion AS clase,
    'tipo_manguilla'::text AS tipo_epp,
    clase_tipo.cod_clase
   FROM (dielab.tipo_manguilla
     JOIN dielab.clase_tipo ON ((tipo_manguilla.clase = clase_tipo.id_clase)))
UNION
 SELECT tipo_manta.id_tipo,
    tipo_manta.marca,
    clase_tipo.descripcion AS clase,
    'tipo_manta'::text AS tipo_epp,
    clase_tipo.cod_clase
   FROM (dielab.tipo_manta
     JOIN dielab.clase_tipo ON ((tipo_manta.clase = clase_tipo.id_clase)))
UNION
 SELECT tipo_pertiga.id_tipo,
    tipo_pertiga.marca,
    clase_tipo.descripcion AS clase,
    'tipo_pertiga'::text AS tipo_epp,
    clase_tipo.cod_clase
   FROM (dielab.tipo_pertiga
     JOIN dielab.clase_tipo ON ((tipo_pertiga.clase = clase_tipo.id_clase)));


ALTER TABLE dielab.lista_tipo_marca_clase OWNER TO postgres;

--
-- TOC entry 255 (class 1259 OID 165529)
-- Name: marca; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.marca (
    id_marca integer NOT NULL,
    nombre character varying NOT NULL
);


ALTER TABLE dielab.marca OWNER TO postgres;

--
-- TOC entry 256 (class 1259 OID 165535)
-- Name: meses; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.meses (
    id integer NOT NULL,
    nombre character varying NOT NULL
);


ALTER TABLE dielab.meses OWNER TO postgres;

--
-- TOC entry 257 (class 1259 OID 165541)
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
-- TOC entry 258 (class 1259 OID 165552)
-- Name: periodicidad; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.periodicidad (
    id bigint NOT NULL,
    descripcion character varying NOT NULL,
    meses integer NOT NULL
);


ALTER TABLE dielab.periodicidad OWNER TO postgres;

--
-- TOC entry 259 (class 1259 OID 165558)
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
-- TOC entry 260 (class 1259 OID 165565)
-- Name: resumen_epp_ensayados; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.resumen_epp_ensayados (
    id bigint NOT NULL,
    fecha_ensayo date NOT NULL,
    cliente bigint NOT NULL,
    empresa text NOT NULL,
    elemento text NOT NULL,
    marca text NOT NULL,
    clase text NOT NULL,
    informe_ensayo text NOT NULL,
    epp_ensayado text NOT NULL,
    cod_elemento text NOT NULL,
    vencimiento date NOT NULL
);


ALTER TABLE dielab.resumen_epp_ensayados OWNER TO postgres;

--
-- TOC entry 261 (class 1259 OID 165571)
-- Name: resumen_estadistico; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.resumen_estadistico (
    id bigint NOT NULL,
    fecha_ensayo date NOT NULL,
    cliente bigint NOT NULL,
    nombre_elemento text NOT NULL,
    aprobado bigint NOT NULL,
    rechazados bigint NOT NULL,
    total bigint NOT NULL
);


ALTER TABLE dielab.resumen_estadistico OWNER TO postgres;

--
-- TOC entry 262 (class 1259 OID 165577)
-- Name: select_caracteristica_aterramiento; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_caracteristica_aterramiento AS
 SELECT caracteristica_aterramiento.id,
    caracteristica_aterramiento.nombre,
    caracteristica_aterramiento.id AS num,
    caracteristica_aterramiento.nombre AS tipo
   FROM dielab.caracteristica_aterramiento
  ORDER BY caracteristica_aterramiento.id
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_caracteristica_aterramiento OWNER TO postgres;

--
-- TOC entry 263 (class 1259 OID 165581)
-- Name: select_caracteristica_pertiga; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_caracteristica_pertiga AS
 SELECT caracteristica_pertiga.id,
    caracteristica_pertiga.nombre,
    caracteristica_pertiga.id AS num,
    caracteristica_pertiga.nombre AS tipo
   FROM dielab.caracteristica_pertiga
  ORDER BY caracteristica_pertiga.id
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_caracteristica_pertiga OWNER TO postgres;

--
-- TOC entry 264 (class 1259 OID 165585)
-- Name: select_clase; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_clase AS
 SELECT clase_tipo.id_clase AS id,
    clase_tipo.descripcion AS nombre
   FROM dielab.clase_tipo
  ORDER BY clase_tipo.descripcion
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_clase OWNER TO postgres;

--
-- TOC entry 265 (class 1259 OID 165589)
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
-- TOC entry 266 (class 1259 OID 165593)
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
-- TOC entry 267 (class 1259 OID 165597)
-- Name: select_cliente; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_cliente AS
 SELECT cliente.id_cliente AS id,
    cliente.nombre_corto AS nombre,
    cliente.id_cliente AS num,
    cliente.nombre AS nombre_cliente,
    cliente.direccion,
    cliente.representante,
    cliente.telefono,
    cliente.nombre_corto,
    cliente.suspendido
   FROM dielab.cliente
  ORDER BY cliente.nombre_corto
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_cliente OWNER TO postgres;

--
-- TOC entry 268 (class 1259 OID 165601)
-- Name: select_cuerpos_aterramiento; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_cuerpos_aterramiento AS
 SELECT cuerpos_aterramiento.id,
    cuerpos_aterramiento.nombre,
    cuerpos_aterramiento.id AS num,
    cuerpos_aterramiento.nombre AS cuerpos
   FROM dielab.cuerpos_aterramiento
  ORDER BY cuerpos_aterramiento.id
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_cuerpos_aterramiento OWNER TO postgres;

--
-- TOC entry 269 (class 1259 OID 165605)
-- Name: select_cuerpos_pertiga; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_cuerpos_pertiga AS
 SELECT largo_pertiga.id,
    largo_pertiga.nombre,
    largo_pertiga.id AS num,
    largo_pertiga.nombre AS cuerpos
   FROM dielab.largo_pertiga
  ORDER BY largo_pertiga.id
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_cuerpos_pertiga OWNER TO postgres;

--
-- TOC entry 270 (class 1259 OID 165609)
-- Name: select_elemento; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_elemento AS
 SELECT clase_epp.cod_serie AS id,
    clase_epp.nombre_menu AS nombre
   FROM (dielab.ensayos_tipo
     JOIN dielab.clase_epp ON ((ensayos_tipo.id_ensayo_tipo = clase_epp.tipo_ensayo)))
  WHERE (ensayos_tipo.habilitado AND clase_epp.habilitado)
  ORDER BY clase_epp.prioridad;


ALTER TABLE dielab.select_elemento OWNER TO postgres;

--
-- TOC entry 271 (class 1259 OID 165613)
-- Name: select_estado_uso; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_estado_uso AS
 SELECT estado_uso.id,
    estado_uso.nombre_estado AS nombre
   FROM dielab.estado_uso
  ORDER BY estado_uso.nombre_estado;


ALTER TABLE dielab.select_estado_uso OWNER TO postgres;

--
-- TOC entry 272 (class 1259 OID 165617)
-- Name: select_inf_tipo_elementos; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_inf_tipo_elementos AS
 SELECT clase_epp.cod_serie AS id,
    clase_epp.nombre_menu AS nombre
   FROM (dielab.ensayos_tipo
     JOIN dielab.clase_epp ON ((ensayos_tipo.id_ensayo_tipo = clase_epp.tipo_ensayo)))
  WHERE (ensayos_tipo.habilitado AND clase_epp.habilitado)
  ORDER BY clase_epp.prioridad;


ALTER TABLE dielab.select_inf_tipo_elementos OWNER TO postgres;

--
-- TOC entry 273 (class 1259 OID 165621)
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
-- TOC entry 274 (class 1259 OID 165625)
-- Name: select_largo_cubrelinea; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_largo_cubrelinea AS
 SELECT largo_cubrelinea.id,
    largo_cubrelinea.nombre,
    largo_cubrelinea.id AS num,
    largo_cubrelinea.nombre AS modelo_cubrelinea
   FROM dielab.largo_cubrelinea
  ORDER BY largo_cubrelinea.id
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_largo_cubrelinea OWNER TO postgres;

--
-- TOC entry 275 (class 1259 OID 165629)
-- Name: select_largo_cubreposte; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_largo_cubreposte AS
 SELECT largo_cubreposte.id,
    largo_cubreposte.nombre,
    largo_cubreposte.id AS num,
    largo_cubreposte.nombre AS largo_cubreposte
   FROM dielab.largo_cubreposte
  ORDER BY largo_cubreposte.id
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_largo_cubreposte OWNER TO postgres;

--
-- TOC entry 276 (class 1259 OID 165633)
-- Name: select_largo_guante; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_largo_guante AS
 SELECT largo_guante.id_largo AS id,
    largo_guante.valor AS nombre,
    largo_guante.id_largo AS num,
    largo_guante.valor AS largo_guante
   FROM dielab.largo_guante
  ORDER BY largo_guante.id_largo
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_largo_guante OWNER TO postgres;

--
-- TOC entry 277 (class 1259 OID 165637)
-- Name: select_largo_manta; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_largo_manta AS
 SELECT largo_manta.id,
    largo_manta.nombre,
    largo_manta.id AS num,
    largo_manta.nombre AS largo_manta
   FROM dielab.largo_manta
  ORDER BY largo_manta.id
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_largo_manta OWNER TO postgres;

--
-- TOC entry 278 (class 1259 OID 165641)
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
-- TOC entry 279 (class 1259 OID 165645)
-- Name: select_lista_ensayos; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_lista_ensayos AS
 SELECT lista_ensayos.cliente,
    lista_ensayos.fecha_ingreso,
    lista_ensayos.codigo
   FROM dielab.lista_ensayos
  ORDER BY lista_ensayos.fecha_ingreso DESC, lista_ensayos.codigo
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_lista_ensayos OWNER TO postgres;

--
-- TOC entry 280 (class 1259 OID 165649)
-- Name: select_marca; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_marca AS
 SELECT marca.id_marca AS id,
    marca.nombre,
    marca.id_marca AS num,
    marca.nombre AS nombre_marca
   FROM dielab.marca
  ORDER BY marca.nombre
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_marca OWNER TO postgres;

--
-- TOC entry 281 (class 1259 OID 165653)
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
-- TOC entry 282 (class 1259 OID 165657)
-- Name: select_modelo_aterramiento; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_modelo_aterramiento AS
 SELECT caracteristica_aterramiento.id,
    caracteristica_aterramiento.nombre
   FROM dielab.caracteristica_aterramiento
  ORDER BY caracteristica_aterramiento.id
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_modelo_aterramiento OWNER TO postgres;

--
-- TOC entry 283 (class 1259 OID 165661)
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
-- TOC entry 284 (class 1259 OID 165665)
-- Name: select_modelo_pertiga; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_modelo_pertiga AS
 SELECT caracteristica_pertiga.id,
    caracteristica_pertiga.nombre
   FROM dielab.caracteristica_pertiga
  ORDER BY caracteristica_pertiga.id
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_modelo_pertiga OWNER TO postgres;

--
-- TOC entry 285 (class 1259 OID 165669)
-- Name: select_negocio; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_negocio AS
 SELECT negocio.id_negocio AS id,
    negocio.nombre,
    negocio.id_negocio AS num,
    negocio.nombre AS nombre_negocio
   FROM dielab.negocio
  ORDER BY negocio.nombre
  WITH LOCAL CHECK OPTION;


ALTER TABLE dielab.select_negocio OWNER TO postgres;

--
-- TOC entry 286 (class 1259 OID 165673)
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
-- TOC entry 287 (class 1259 OID 165677)
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
-- TOC entry 288 (class 1259 OID 165681)
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
-- TOC entry 289 (class 1259 OID 165686)
-- Name: select_periodicidad; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_periodicidad AS
 SELECT periodicidad.id,
    periodicidad.descripcion AS nombre
   FROM dielab.periodicidad
  ORDER BY periodicidad.id;


ALTER TABLE dielab.select_periodicidad OWNER TO postgres;

--
-- TOC entry 290 (class 1259 OID 165690)
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
-- TOC entry 291 (class 1259 OID 165694)
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
-- TOC entry 292 (class 1259 OID 165698)
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
-- TOC entry 293 (class 1259 OID 165702)
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
-- TOC entry 294 (class 1259 OID 165706)
-- Name: select_tipo_aterramiento; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_tipo_aterramiento AS
 SELECT tipo_aterramiento.id_tipo AS id,
    (((((((marca.nombre)::text || '_'::text) || 'N°_Cuerpos:_'::text) || (cuerpos_aterramiento.nombre)::text) || '_'::text) || 'Modelo:_'::text) || (ca.nombre)::text) AS nombre,
    (tipo_aterramiento.id_tipo)::text AS num,
    (marca.nombre)::text AS marca,
    (cuerpos_aterramiento.nombre)::text AS num_cuerpos,
    (ca.nombre)::text AS modelo_aterramiento
   FROM (((dielab.tipo_aterramiento
     JOIN dielab.cuerpos_aterramiento ON ((tipo_aterramiento.largo = cuerpos_aterramiento.id)))
     JOIN dielab.marca ON ((tipo_aterramiento.cod_marca = marca.id_marca)))
     JOIN dielab.caracteristica_aterramiento ca ON ((tipo_aterramiento.caracteristica = ca.id)))
  ORDER BY marca.nombre, cuerpos_aterramiento.nombre;


ALTER TABLE dielab.select_tipo_aterramiento OWNER TO postgres;

--
-- TOC entry 300 (class 1259 OID 166092)
-- Name: select_tipo_banqueta; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_tipo_banqueta AS
 SELECT tipo_banqueta.id_tipo AS id,
    (((marca.nombre)::text || '__'::text) || (clase_tipo.descripcion)::text) AS nombre,
    (tipo_banqueta.id_tipo)::text AS num,
    (marca.nombre)::text AS marca,
    (clase_tipo.descripcion)::text AS clase
   FROM ((dielab.tipo_banqueta
     JOIN dielab.clase_tipo ON ((tipo_banqueta.clase = clase_tipo.id_clase)))
     JOIN dielab.marca ON ((tipo_banqueta.cod_marca = marca.id_marca)))
  ORDER BY marca.nombre, clase_tipo.descripcion;


ALTER TABLE dielab.select_tipo_banqueta OWNER TO postgres;

--
-- TOC entry 301 (class 1259 OID 166097)
-- Name: select_tipo_cubrelinea; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_tipo_cubrelinea AS
 SELECT tipo_cubrelinea.id_tipo AS id,
    (((((marca.nombre)::text || '_'::text) || (largo_cubrelinea.nombre)::text) || '_'::text) || (clase_tipo.descripcion)::text) AS nombre,
    (tipo_cubrelinea.id_tipo)::text AS num,
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
-- TOC entry 302 (class 1259 OID 166102)
-- Name: select_tipo_cubreposte; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_tipo_cubreposte AS
 SELECT tipo_cubreposte.id_tipo AS id,
    (((((marca.nombre)::text || '_'::text) || (largo_cubreposte.nombre)::text) || '_'::text) || (clase_tipo.descripcion)::text) AS nombre,
    (tipo_cubreposte.id_tipo)::text AS num,
    (marca.nombre)::text AS marca,
    (largo_cubreposte.nombre)::text AS largo,
    (clase_tipo.descripcion)::text AS clase
   FROM (((dielab.tipo_cubreposte
     JOIN dielab.largo_cubreposte ON ((tipo_cubreposte.largo = largo_cubreposte.id)))
     JOIN dielab.clase_tipo ON ((tipo_cubreposte.clase = clase_tipo.id_clase)))
     JOIN dielab.marca ON ((tipo_cubreposte.cod_marca = marca.id_marca)))
  ORDER BY marca.nombre, largo_cubreposte.nombre, clase_tipo.descripcion;


ALTER TABLE dielab.select_tipo_cubreposte OWNER TO postgres;

--
-- TOC entry 303 (class 1259 OID 166107)
-- Name: select_tipo_guante; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_tipo_guante AS
 SELECT tipo_guante.id_tipo AS id,
    (((((((marca.nombre)::text || '__'::text) || (largo_guante.valor)::text) || '__'::text) || (clase_tipo.descripcion)::text) || '__corriente_fuga_max='::text) || (tipo_guante.corriente_fuga_max)::text) AS nombre,
    (tipo_guante.id_tipo)::text AS num,
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
-- TOC entry 304 (class 1259 OID 166112)
-- Name: select_tipo_jumper; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_tipo_jumper AS
 SELECT tipo_jumper.id_tipo AS id,
    (((marca.nombre)::text || '__'::text) || (clase_tipo.descripcion)::text) AS nombre,
    (tipo_jumper.id_tipo)::text AS num,
    (marca.nombre)::text AS marca,
    (clase_tipo.descripcion)::text AS clase
   FROM ((dielab.tipo_jumper
     JOIN dielab.clase_tipo ON ((tipo_jumper.clase = clase_tipo.id_clase)))
     JOIN dielab.marca ON ((tipo_jumper.cod_marca = marca.id_marca)))
  ORDER BY marca.nombre, tipo_jumper.clase;


ALTER TABLE dielab.select_tipo_jumper OWNER TO postgres;

--
-- TOC entry 305 (class 1259 OID 166117)
-- Name: select_tipo_loadbuster; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_tipo_loadbuster AS
 SELECT tipo_loadbuster.id_tipo AS id,
    (marca.nombre)::text AS nombre,
    (tipo_loadbuster.id_tipo)::text AS num,
    (marca.nombre)::text AS marca
   FROM (dielab.tipo_loadbuster
     JOIN dielab.marca ON ((tipo_loadbuster.cod_marca = marca.id_marca)))
  ORDER BY marca.nombre;


ALTER TABLE dielab.select_tipo_loadbuster OWNER TO postgres;

--
-- TOC entry 306 (class 1259 OID 166121)
-- Name: select_tipo_manguilla; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_tipo_manguilla AS
 SELECT tipo_manguilla.id_tipo AS id,
    (((marca.nombre)::text || '__'::text) || (clase_tipo.descripcion)::text) AS nombre,
    (tipo_manguilla.id_tipo)::text AS num,
    (marca.nombre)::text AS marca,
    (clase_tipo.descripcion)::text AS clase
   FROM ((dielab.tipo_manguilla
     JOIN dielab.clase_tipo ON ((tipo_manguilla.clase = clase_tipo.id_clase)))
     JOIN dielab.marca ON ((tipo_manguilla.cod_marca = marca.id_marca)))
  ORDER BY marca.nombre, tipo_manguilla.clase;


ALTER TABLE dielab.select_tipo_manguilla OWNER TO postgres;

--
-- TOC entry 307 (class 1259 OID 166126)
-- Name: select_tipo_manta; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_tipo_manta AS
 SELECT tipo_manta.id_tipo AS id,
    (((((marca.nombre)::text || '_'::text) || (largo_manta.nombre)::text) || '_'::text) || (clase_tipo.descripcion)::text) AS nombre,
    (tipo_manta.id_tipo)::text AS num,
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
-- TOC entry 308 (class 1259 OID 166131)
-- Name: select_tipo_pertiga; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_tipo_pertiga AS
 SELECT tipo_pertiga.id_tipo AS id,
    (((((marca.nombre)::text || '_'::text) || (largo_pertiga.nombre)::text) || '_Modelo:_'::text) || (cp.nombre)::text) AS nombre,
    (tipo_pertiga.id_tipo)::text AS num,
    (marca.nombre)::text AS marca,
    (largo_pertiga.nombre)::text AS largo,
    cp.nombre AS modelo_pertiga
   FROM (((dielab.tipo_pertiga
     JOIN dielab.largo_pertiga ON ((tipo_pertiga.largo = largo_pertiga.id)))
     JOIN dielab.marca ON ((tipo_pertiga.cod_marca = marca.id_marca)))
     JOIN dielab.caracteristica_pertiga cp ON ((cp.id = tipo_pertiga.caracteristica)))
  ORDER BY marca.nombre, largo_pertiga.nombre;


ALTER TABLE dielab.select_tipo_pertiga OWNER TO postgres;

--
-- TOC entry 295 (class 1259 OID 165755)
-- Name: usuarios; Type: TABLE; Schema: dielab; Owner: postgres
--

CREATE TABLE dielab.usuarios (
    id bigint NOT NULL,
    perfil bigint NOT NULL,
    rut character varying NOT NULL,
    password_md5 character varying NOT NULL,
    cliente bigint NOT NULL,
    usuario character varying NOT NULL,
    suspendida boolean DEFAULT false NOT NULL,
    CONSTRAINT cliente_positivo CHECK ((cliente >= 0))
);


ALTER TABLE dielab.usuarios OWNER TO postgres;

--
-- TOC entry 296 (class 1259 OID 165763)
-- Name: select_usuario; Type: VIEW; Schema: dielab; Owner: postgres
--

CREATE VIEW dielab.select_usuario AS
 SELECT usuarios.id,
    usuarios.usuario AS nombre,
    usuarios.id AS num,
    usuarios.usuario AS nombre_usuario,
    personas.nombre AS nombre_persona,
    personas.rut,
    personas.email,
    personas.telefono,
    cliente.nombre_corto AS cliente
   FROM ((dielab.personas
     JOIN dielab.usuarios USING (rut))
     JOIN dielab.cliente ON ((usuarios.cliente = cliente.id_cliente)));


ALTER TABLE dielab.select_usuario OWNER TO postgres;

--
-- TOC entry 297 (class 1259 OID 165768)
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
-- TOC entry 298 (class 1259 OID 165770)
-- Name: myrec; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.myrec (
    descripcion text,
    nombre_marca character varying,
    modelo character varying,
    serie character varying,
    mes_calibracion integer,
    periodo_calibracion integer
);


ALTER TABLE public.myrec OWNER TO postgres;

--
-- TOC entry 299 (class 1259 OID 165776)
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
-- TOC entry 3791 (class 0 OID 165308)
-- Dependencies: 218
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
-- TOC entry 3792 (class 0 OID 165314)
-- Dependencies: 219
-- Data for Name: caracteristica_aterramiento; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.caracteristica_aterramiento (id, nombre) FROM stdin;
1	BT
2	MT
\.


--
-- TOC entry 3793 (class 0 OID 165320)
-- Dependencies: 220
-- Data for Name: caracteristica_pertiga; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.caracteristica_pertiga (id, nombre) FROM stdin;
1	telescópica
\.


--
-- TOC entry 3778 (class 0 OID 165220)
-- Dependencies: 202
-- Data for Name: clase_epp; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.clase_epp (id_clase_epp, nombre, cod_serie, tabla_detalle, nombre_menu, habilitado, tipo_ensayo, prioridad) FROM stdin;
1	guante	GNT	tipo_guante	Guantes	t	1	1
2	manguilla	MNG	tipo_manguilla	Manguillas	t	4	2
3	manta	MNT	tipo_manta	Mantas	t	5	7
4	cubrelinea	CBL	tipo_cubrelinea	Cubrelineas	t	3	6
5	banqueta	BNQ	tipo_banqueta	Banquetas	t	6	8
6	loadbuster	LDB	tipo_loadbuster	LoadBuster	t	2	5
7	aterramiento	ATR	tipo_aterramiento	Aterramiento	t	7	3
8	pertiga	PRT	tipo_pertiga	Pértiga	t	8	4
10	cubreposte	CBP	tipo_cubreposte	Cubreposte	t	10	10
9	jumper	JMP	tipo_jumper	Jumper	t	9	9
11	ecm	ECM	tipo_ecm	Ecm	f	11	11
\.


--
-- TOC entry 3786 (class 0 OID 165269)
-- Dependencies: 211
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
-- TOC entry 3779 (class 0 OID 165227)
-- Dependencies: 203
-- Data for Name: cliente; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.cliente (id_cliente, nombre, telefono, representante, direccion, nombre_corto, suspendido) FROM stdin;
0	Quinta Energy Laboratorios.	9999999	Valeska Madariaga	Avenida Ventisquero 1265, bodega N°4, Renca, Santiago	Quinta	f
1	Serv Integrales Marcos Galleguillos SpA.	9999999	Diego Maldonado	Las Maravillas N°105, Santa Julia. Viña del mar	PVerdes	f
\.


--
-- TOC entry 3781 (class 0 OID 165236)
-- Dependencies: 205
-- Data for Name: cliente_negocio_sucursal; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.cliente_negocio_sucursal (id_cliente_n_s, cliente, negocio, sucursal, direccion) FROM stdin;
1001	1	3	5302	\N
1003	1	3	3101	\N
1011	1	2	8113	\N
\.


--
-- TOC entry 3794 (class 0 OID 165326)
-- Dependencies: 221
-- Data for Name: cuerpos_aterramiento; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.cuerpos_aterramiento (id, nombre) FROM stdin;
2	1 
3	1 de 3
4	2 de 3
5	3 de 3
6	1 de 2
7	2 de 2
\.


--
-- TOC entry 3787 (class 0 OID 165275)
-- Dependencies: 212
-- Data for Name: detalle_ensayo; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.detalle_ensayo (id_detalle, id_batea, serie_epp, aprobado, detalle) FROM stdin;
1006	1005	1004	t	{"serie_epp":"ATR-00408","fuga1":"5.6","parches":"0","tension":"30","resultado":"APROBADO"}
1007	1005	1002	t	{"serie_epp":"ATR-00407","fuga1":"5.1","parches":"0","tension":"30","resultado":"APROBADO"}
1008	1005	1000	t	{"serie_epp":"ATR-00406","fuga1":"5.0","parches":"0","tension":"30","resultado":"APROBADO"}
\.


--
-- TOC entry 3795 (class 0 OID 165332)
-- Dependencies: 222
-- Data for Name: elementos_informe; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.elementos_informe (id, nombre, prioridad) FROM stdin;
\.


--
-- TOC entry 3782 (class 0 OID 165243)
-- Dependencies: 206
-- Data for Name: encabezado_ensayo; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.encabezado_ensayo (id_batea, cod_ensayo, temperatura, humedad, tecnico, fecha, patron, estado, tipo_ensayo, fecha_ejecucion, fecha_emision, cliente_n_s, fecha_ingreso, cod_estado, cod_patron, orden_compra) FROM stdin;
1005	LAT-ATR-00001	18.4	45.5	1	2022-09-02 21:42:33.2553	1	ingreso	7	2022-08-31	\N	1003	2022-08-31	2	1	-
\.


--
-- TOC entry 3790 (class 0 OID 165298)
-- Dependencies: 216
-- Data for Name: ensayos_tipo; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.ensayos_tipo (id_ensayo_tipo, descripcion, cod_informe, habilitado) FROM stdin;
1	guantes	LAT-GNT	t
4	manguillas	LAT-MNG	t
5	mantas	LAT-MNT	t
7	aterramiento	LAT-ATR	t
8	pértiga	LAT-PRT	t
3	cubre_línea	LAT-CBL	t
6	banqueta	LAT-BNQ	t
2	loadbuster	LAT-LDB	t
10	cubreposte	LAT-CBP	t
9	jumper	LAT-JMP	t
11	ecm	LAT-ECM	f
\.


--
-- TOC entry 3788 (class 0 OID 165281)
-- Dependencies: 213
-- Data for Name: epps; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.epps (id_epp, serie_epp, clase_epp, tipo_epp, cliente_n_s, estado_epp, periodicidad, estado_uso) FROM stdin;
1004	ATR-00408	7	1	1003	1	6	1
1002	ATR-00407	7	2	1003	1	6	1
1000	ATR-00406	7	1	1003	1	6	1
1009	ATR-00409	7	7	1003	0	6	2
1010	PRT-00001	8	2	1011	0	6	2
\.


--
-- TOC entry 3783 (class 0 OID 165249)
-- Dependencies: 207
-- Data for Name: estado_ensayo; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.estado_ensayo (id_estado, nombre, observacion) FROM stdin;
0	SIN ESTADO	NO UTILIZADO
1	Ingreso	Estado inicial una vez que se graba un ensayo
2	En revisión	Estado que indica que el ensayo está siendo editado aún
3	Cert. Emitido	Estado que indica que ya se emitió el certificado para el ensayo, no es posible volver a editarlo
\.


--
-- TOC entry 3796 (class 0 OID 165338)
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
-- TOC entry 3797 (class 0 OID 165344)
-- Dependencies: 224
-- Data for Name: estado_uso; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.estado_uso (id, nombre_estado) FROM stdin;
1	usado
2	nuevo
\.


--
-- TOC entry 3798 (class 0 OID 165350)
-- Dependencies: 225
-- Data for Name: largo_cubrelinea; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.largo_cubrelinea (id, nombre) FROM stdin;
1	RIGIDA
2	CON ACOPLE
3	SIN ACOPLE
\.


--
-- TOC entry 3799 (class 0 OID 165356)
-- Dependencies: 226
-- Data for Name: largo_cubreposte; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.largo_cubreposte (id, nombre) FROM stdin;
\.


--
-- TOC entry 3800 (class 0 OID 165359)
-- Dependencies: 227
-- Data for Name: largo_guante; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.largo_guante (id_largo, valor) FROM stdin;
1	410
2	360
3	280
4	460
\.


--
-- TOC entry 3801 (class 0 OID 165362)
-- Dependencies: 228
-- Data for Name: largo_manta; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.largo_manta (id, nombre) FROM stdin;
1	ENTERA 
2	PARTIDA
\.


--
-- TOC entry 3802 (class 0 OID 165368)
-- Dependencies: 229
-- Data for Name: largo_pertiga; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.largo_pertiga (id, nombre) FROM stdin;
1	1 de 7
2	1 de 3
3	2 de 3
4	3 de 3
5	1 de 2
6	2 de 2
\.


--
-- TOC entry 3815 (class 0 OID 165529)
-- Dependencies: 255
-- Data for Name: marca; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.marca (id_marca, nombre) FROM stdin;
1	NOVAX
2	SALISBURY
3	CATU
4	RITZ
5	CHANCE
6	COOFESTE
7	HASTINGS
\.


--
-- TOC entry 3816 (class 0 OID 165535)
-- Dependencies: 256
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
-- TOC entry 3784 (class 0 OID 165255)
-- Dependencies: 208
-- Data for Name: negocio; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.negocio (id_negocio, nombre) FROM stdin;
1	SAE
2	LLEE
3	-
\.


--
-- TOC entry 3805 (class 0 OID 165438)
-- Dependencies: 242
-- Data for Name: patron; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.patron (id_patron, descripcion, marca, modelo, serie, calibracion, mes_calibracion, periodo_calibracion, activo) FROM stdin;
1	Elevador de Tensión	Phenix Technologies	BK 130/36	15-9968	Agosto 2023 	8	2	t
2	Elevador de Tensión	Huazheng	HZAQ	HZ22201090325-01-4	Mayo 2023 	5	2	t
3	Elevador de Tensión	Huazheng	HZAQ	HZ181010900104-02	Noviembre 2022 	11	1	t
4	Medidor de Aislación	Megger	MIT 1025	101425542	Diciembre 2022 	12	1	t
5	Micróhmetro	Megger	DLRO 200	101484972	Diciembre 2022 	12	1	t
\.


--
-- TOC entry 3817 (class 0 OID 165541)
-- Dependencies: 257
-- Data for Name: perfil; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.perfil (id, nombre, multicliente, mantenedor, inventario, ensayo, reportes) FROM stdin;
0	superusuario	t	t	t	t	f
3	cliente	f	f	f	f	t
\.


--
-- TOC entry 3818 (class 0 OID 165552)
-- Dependencies: 258
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
-- TOC entry 3819 (class 0 OID 165558)
-- Dependencies: 259
-- Data for Name: personas; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.personas (rut, nombre, email, telefono, suspendida) FROM stdin;
70.000.000-1	Valeska Madariaga	vmadariaga@quintaenergy.cl	999999999	f
76780080-0	Diego Maldonado	diego.maldonado@praderasverdes.cl	9999999	f
\.


--
-- TOC entry 3820 (class 0 OID 165565)
-- Dependencies: 260
-- Data for Name: resumen_epp_ensayados; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.resumen_epp_ensayados (id, fecha_ensayo, cliente, empresa, elemento, marca, clase, informe_ensayo, epp_ensayado, cod_elemento, vencimiento) FROM stdin;
\.


--
-- TOC entry 3821 (class 0 OID 165571)
-- Dependencies: 261
-- Data for Name: resumen_estadistico; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.resumen_estadistico (id, fecha_ensayo, cliente, nombre_elemento, aprobado, rechazados, total) FROM stdin;
\.


--
-- TOC entry 3804 (class 0 OID 165427)
-- Dependencies: 240
-- Data for Name: serie_loadbuster; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.serie_loadbuster (id_epp, serie) FROM stdin;
\.


--
-- TOC entry 3785 (class 0 OID 165261)
-- Dependencies: 209
-- Data for Name: sucursales; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.sucursales (cod_sucursal, nombre) FROM stdin;
1101	arica
1106	camarones
1201	iquique
1203	pica
1204	pozo almonte
1206	huara
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
3101	chañaral
4105	vicuña
6105	doñihue
7107	hualañe
8110	ñiquen
8301	arauco
8302	curanilahue
8303	lebu
8304	los alamos
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
14505	padre hurtado
14601	melipilla
14602	maria pinto
14603	curacavi
14604	san pedro
14605	alhue
15103	providencia
15108	las condes
15128	la florida
15132	la reina
15151	macul
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
11203	rio ibañez
1208	camiña
14504	peñaflor
15105	ñuñoa
15152	peñalolen
5302	viña del mar
8305	cañete
\.


--
-- TOC entry 3806 (class 0 OID 165446)
-- Dependencies: 243
-- Data for Name: tecnicos_ensayo; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.tecnicos_ensayo (id_tecnico, nombre, comentario, activo) FROM stdin;
1	Juan Bustamante P.	JBP	t
2	Valeska Madariaga G.	VMG	t
3	Marcelo Ortega Z.	MOZ	t
4	José Cortez L.	JCL	t
\.


--
-- TOC entry 3807 (class 0 OID 165462)
-- Dependencies: 246
-- Data for Name: tipo_aterramiento; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.tipo_aterramiento (id_tipo, marca, modelo, largo, clase, corriente_fuga_max, descripcion, cod_marca, caracteristica) FROM stdin;
1	RITZ	\N	3	0	0	\N	4	1
2	RITZ	\N	4	0	0	\N	4	1
3	RITZ	\N	5	0	0	\N	4	1
4	COOFESTE	\N	3	0	0	\N	6	1
5	COOFESTE	\N	4	0	0	\N	6	1
6	COOFESTE	\N	5	0	0	\N	6	1
7	CHANCE	\N	3	0	0	\N	5	1
8	CHANCE	\N	4	0	0	\N	5	1
9	CHANCE	\N	5	0	0	\N	5	1
10	RITZ	\N	2	0	0	\N	4	1
11	COOFESTE	\N	2	0	0	\N	6	1
\.


--
-- TOC entry 3808 (class 0 OID 165471)
-- Dependencies: 247
-- Data for Name: tipo_banqueta; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.tipo_banqueta (id_tipo, marca, modelo, largo, clase, corriente_fuga_max, descripcion, cod_marca) FROM stdin;
\.


--
-- TOC entry 3809 (class 0 OID 165479)
-- Dependencies: 248
-- Data for Name: tipo_cubrelinea; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.tipo_cubrelinea (id_tipo, marca, modelo, largo, clase, corriente_fuga_max, descripcion, cod_marca) FROM stdin;
\.


--
-- TOC entry 3810 (class 0 OID 165486)
-- Dependencies: 249
-- Data for Name: tipo_cubreposte; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.tipo_cubreposte (id_tipo, marca, modelo, largo, clase, corriente_fuga_max, descripcion, cod_marca) FROM stdin;
\.


--
-- TOC entry 3789 (class 0 OID 165287)
-- Dependencies: 214
-- Data for Name: tipo_guante; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.tipo_guante (id_tipo, marca, modelo, largo, clase, corriente_fuga_max, descripcion, cod_marca) FROM stdin;
1	NOVAX	\N	2	0	10	\N	1
2	NOVAX	\N	1	3	16.7	\N	1
3	SALISBURY	\N	1	3	16.7	\N	2
4	SALISBURY	\N	2	0	10	\N	2
5	CATU	\N	1	3	16.7	\N	3
6	COOFESTE	\N	2	3	6	\N	6
\.


--
-- TOC entry 3811 (class 0 OID 165493)
-- Dependencies: 250
-- Data for Name: tipo_jumper; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.tipo_jumper (id_tipo, marca, modelo, largo, clase, corriente_fuga_max, descripcion, cod_marca) FROM stdin;
\.


--
-- TOC entry 3803 (class 0 OID 165393)
-- Dependencies: 234
-- Data for Name: tipo_loadbuster; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.tipo_loadbuster (id_tipo, marca, modelo, largo, clase, corriente_fuga_max, descripcion, cod_marca) FROM stdin;
\.


--
-- TOC entry 3812 (class 0 OID 165501)
-- Dependencies: 251
-- Data for Name: tipo_manguilla; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.tipo_manguilla (id_tipo, marca, modelo, largo, clase, corriente_fuga_max, descripcion, cod_marca) FROM stdin;
1	NOVAX	\N	0	0	0	\N	1
2	NOVAX	\N	0	3	0	\N	1
3	SALISBURY	\N	0	0	0	\N	2
4	SALISBURY	\N	0	3	0	\N	2
\.


--
-- TOC entry 3813 (class 0 OID 165509)
-- Dependencies: 252
-- Data for Name: tipo_manta; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.tipo_manta (id_tipo, marca, modelo, largo, clase, corriente_fuga_max, descripcion, cod_marca) FROM stdin;
\.


--
-- TOC entry 3814 (class 0 OID 165516)
-- Dependencies: 253
-- Data for Name: tipo_pertiga; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.tipo_pertiga (id_tipo, marca, modelo, largo, clase, corriente_fuga_max, descripcion, cod_marca, caracteristica) FROM stdin;
1	RITZ	\N	1	0	0	\N	4	1
2	RITZ	\N	2	0	0	\N	4	1
3	RITZ	\N	3	0	0	\N	4	1
4	RITZ	\N	4	0	0	\N	4	1
5	CHANCE	\N	1	0	0	\N	5	1
6	HASTINGS	\N	1	0	0	\N	7	1
7	COOFESTE	\N	1	0	0	\N	6	1
\.


--
-- TOC entry 3822 (class 0 OID 165755)
-- Dependencies: 295
-- Data for Name: usuarios; Type: TABLE DATA; Schema: dielab; Owner: postgres
--

COPY dielab.usuarios (id, perfil, rut, password_md5, cliente, usuario, suspendida) FROM stdin;
0	0	70.000.000-1	7a71912af813cc0e1be45bd2ea29d9c4	0	quintadmin	f
1	3	76780080-0	330c3520ee37bdd834c4a1d931f5fe13	1	76780080-0	f
\.


--
-- TOC entry 3824 (class 0 OID 165770)
-- Dependencies: 298
-- Data for Name: myrec; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.myrec (descripcion, nombre_marca, modelo, serie, mes_calibracion, periodo_calibracion) FROM stdin;
\.


--
-- TOC entry 3825 (class 0 OID 165776)
-- Dependencies: 299
-- Data for Name: resultado1; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.resultado1 (id_detalle, id_batea, serie_epp, aprobado, detalle) FROM stdin;
\.


--
-- TOC entry 3833 (class 0 OID 0)
-- Dependencies: 297
-- Name: seq_cod_ensayo; Type: SEQUENCE SET; Schema: dielab; Owner: postgres
--

SELECT pg_catalog.setval('dielab.seq_cod_ensayo', 100, false);


--
-- TOC entry 3834 (class 0 OID 0)
-- Dependencies: 204
-- Name: seq_id_tabla; Type: SEQUENCE SET; Schema: dielab; Owner: postgres
--

SELECT pg_catalog.setval('dielab.seq_id_tabla', 1011, true);


--
-- TOC entry 3440 (class 2606 OID 165783)
-- Name: anual anual_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.anual
    ADD CONSTRAINT anual_pkey PRIMARY KEY (id);


--
-- TOC entry 3488 (class 2606 OID 165785)
-- Name: tipo_aterramiento ate_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_aterramiento
    ADD CONSTRAINT ate_unico UNIQUE (cod_marca, largo, corriente_fuga_max, caracteristica);


--
-- TOC entry 3493 (class 2606 OID 165787)
-- Name: tipo_banqueta ban_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_banqueta
    ADD CONSTRAINT ban_unico UNIQUE (cod_marca, clase, corriente_fuga_max);


--
-- TOC entry 3423 (class 2606 OID 165789)
-- Name: detalle_ensayo batea_epp_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.detalle_ensayo
    ADD CONSTRAINT batea_epp_unico UNIQUE (id_batea, serie_epp);


--
-- TOC entry 3442 (class 2606 OID 165791)
-- Name: caracteristica_aterramiento caracteristica_aterramiento_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.caracteristica_aterramiento
    ADD CONSTRAINT caracteristica_aterramiento_pkey PRIMARY KEY (id);


--
-- TOC entry 3444 (class 2606 OID 165793)
-- Name: caracteristica_pertiga caracteristica_pertiga_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.caracteristica_pertiga
    ADD CONSTRAINT caracteristica_pertiga_pkey PRIMARY KEY (id);


--
-- TOC entry 3402 (class 2606 OID 165795)
-- Name: clase_epp clase_epp_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.clase_epp
    ADD CONSTRAINT clase_epp_pkey PRIMARY KEY (id_clase_epp);


--
-- TOC entry 3421 (class 2606 OID 165797)
-- Name: clase_tipo clase_tipo_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.clase_tipo
    ADD CONSTRAINT clase_tipo_pkey PRIMARY KEY (id_clase);


--
-- TOC entry 3409 (class 2606 OID 165799)
-- Name: cliente_negocio_sucursal cliente-negocio-sucursal_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.cliente_negocio_sucursal
    ADD CONSTRAINT "cliente-negocio-sucursal_pkey" PRIMARY KEY (id_cliente_n_s);


--
-- TOC entry 3407 (class 2606 OID 165801)
-- Name: cliente cliente_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.cliente
    ADD CONSTRAINT cliente_pkey PRIMARY KEY (id_cliente);


--
-- TOC entry 3411 (class 2606 OID 165803)
-- Name: encabezado_ensayo cod_ensayo_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.encabezado_ensayo
    ADD CONSTRAINT cod_ensayo_unico UNIQUE (cod_ensayo);


--
-- TOC entry 3498 (class 2606 OID 165805)
-- Name: tipo_cubrelinea cub_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_cubrelinea
    ADD CONSTRAINT cub_unico UNIQUE (cod_marca, clase, largo, corriente_fuga_max);


--
-- TOC entry 3502 (class 2606 OID 165807)
-- Name: tipo_cubreposte cubpos_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_cubreposte
    ADD CONSTRAINT cubpos_unico UNIQUE (cod_marca, clase, largo, corriente_fuga_max);


--
-- TOC entry 3446 (class 2606 OID 165809)
-- Name: cuerpos_aterramiento cuerpos_aterramiento_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.cuerpos_aterramiento
    ADD CONSTRAINT cuerpos_aterramiento_pkey PRIMARY KEY (id);


--
-- TOC entry 3425 (class 2606 OID 165811)
-- Name: detalle_ensayo detalle_ensayo_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.detalle_ensayo
    ADD CONSTRAINT detalle_ensayo_pkey PRIMARY KEY (id_detalle);


--
-- TOC entry 3450 (class 2606 OID 165813)
-- Name: elementos_informe elementos_informe_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.elementos_informe
    ADD CONSTRAINT elementos_informe_pkey PRIMARY KEY (id);


--
-- TOC entry 3532 (class 2606 OID 165815)
-- Name: personas email_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.personas
    ADD CONSTRAINT email_unico UNIQUE (email);


--
-- TOC entry 3413 (class 2606 OID 165817)
-- Name: encabezado_ensayo encabezado_ensayo_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.encabezado_ensayo
    ADD CONSTRAINT encabezado_ensayo_pkey PRIMARY KEY (id_batea);


--
-- TOC entry 3438 (class 2606 OID 165819)
-- Name: ensayos_tipo ensayos_tipo_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.ensayos_tipo
    ADD CONSTRAINT ensayos_tipo_pkey PRIMARY KEY (id_ensayo_tipo);


--
-- TOC entry 3427 (class 2606 OID 165821)
-- Name: epps epps_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.epps
    ADD CONSTRAINT epps_pkey PRIMARY KEY (id_epp);


--
-- TOC entry 3415 (class 2606 OID 165823)
-- Name: estado_ensayo estado_ensayo_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.estado_ensayo
    ADD CONSTRAINT estado_ensayo_pkey PRIMARY KEY (id_estado);


--
-- TOC entry 3452 (class 2606 OID 165825)
-- Name: estado_epp estado_epp_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.estado_epp
    ADD CONSTRAINT estado_epp_pkey PRIMARY KEY (id_estado_epp);


--
-- TOC entry 3454 (class 2606 OID 165827)
-- Name: estado_uso estado_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.estado_uso
    ADD CONSTRAINT estado_unico UNIQUE (nombre_estado);


--
-- TOC entry 3456 (class 2606 OID 165829)
-- Name: estado_uso estado_uso_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.estado_uso
    ADD CONSTRAINT estado_uso_pkey PRIMARY KEY (id);


--
-- TOC entry 3434 (class 2606 OID 165831)
-- Name: tipo_guante gua_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_guante
    ADD CONSTRAINT gua_unico UNIQUE (cod_marca, clase, largo, corriente_fuga_max);


--
-- TOC entry 3371 (class 2606 OID 165832)
-- Name: cliente id_positivo; Type: CHECK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE dielab.cliente
    ADD CONSTRAINT id_positivo CHECK ((id_cliente >= 0)) NOT VALID;


--
-- TOC entry 3506 (class 2606 OID 165834)
-- Name: tipo_jumper jumper_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_jumper
    ADD CONSTRAINT jumper_unico UNIQUE (cod_marca, clase, corriente_fuga_max);


--
-- TOC entry 3458 (class 2606 OID 165836)
-- Name: largo_cubrelinea largo_cubrelinea_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.largo_cubrelinea
    ADD CONSTRAINT largo_cubrelinea_pkey PRIMARY KEY (id);


--
-- TOC entry 3466 (class 2606 OID 165838)
-- Name: largo_manta largo_manta_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.largo_manta
    ADD CONSTRAINT largo_manta_pkey PRIMARY KEY (id);


--
-- TOC entry 3470 (class 2606 OID 165840)
-- Name: largo_pertiga largo_pertiga_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.largo_pertiga
    ADD CONSTRAINT largo_pertiga_pkey PRIMARY KEY (id);


--
-- TOC entry 3462 (class 2606 OID 165842)
-- Name: largo_cubreposte lcubpos_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.largo_cubreposte
    ADD CONSTRAINT lcubpos_pkey PRIMARY KEY (id);


--
-- TOC entry 3464 (class 2606 OID 165844)
-- Name: largo_guante lguante_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.largo_guante
    ADD CONSTRAINT lguante_pkey PRIMARY KEY (id_largo);


--
-- TOC entry 3474 (class 2606 OID 165846)
-- Name: tipo_loadbuster loa_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_loadbuster
    ADD CONSTRAINT loa_unico UNIQUE (cod_marca, corriente_fuga_max);


--
-- TOC entry 3510 (class 2606 OID 165848)
-- Name: tipo_manguilla man_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_manguilla
    ADD CONSTRAINT man_unico UNIQUE (cod_marca, clase, corriente_fuga_max);


--
-- TOC entry 3524 (class 2606 OID 165850)
-- Name: marca marca_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.marca
    ADD CONSTRAINT marca_pkey PRIMARY KEY (id_marca);


--
-- TOC entry 3515 (class 2606 OID 165852)
-- Name: tipo_manta mat_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_manta
    ADD CONSTRAINT mat_unico UNIQUE (cod_marca, largo, clase, corriente_fuga_max);


--
-- TOC entry 3526 (class 2606 OID 165854)
-- Name: meses mese_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.meses
    ADD CONSTRAINT mese_pkey PRIMARY KEY (id);


--
-- TOC entry 3480 (class 2606 OID 165856)
-- Name: patron mmse_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.patron
    ADD CONSTRAINT mmse_unico UNIQUE (marca, modelo, serie);


--
-- TOC entry 3417 (class 2606 OID 165858)
-- Name: negocio negocio_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.negocio
    ADD CONSTRAINT negocio_pkey PRIMARY KEY (id_negocio);


--
-- TOC entry 3460 (class 2606 OID 165860)
-- Name: largo_cubrelinea nombre_cubrelinea_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.largo_cubrelinea
    ADD CONSTRAINT nombre_cubrelinea_unico UNIQUE (nombre);


--
-- TOC entry 3448 (class 2606 OID 165862)
-- Name: cuerpos_aterramiento nombre_cuerpos_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.cuerpos_aterramiento
    ADD CONSTRAINT nombre_cuerpos_unico UNIQUE (nombre);


--
-- TOC entry 3472 (class 2606 OID 165864)
-- Name: largo_pertiga nombre_largo_pertiga_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.largo_pertiga
    ADD CONSTRAINT nombre_largo_pertiga_unico UNIQUE (nombre);


--
-- TOC entry 3468 (class 2606 OID 165866)
-- Name: largo_manta nombre_manta_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.largo_manta
    ADD CONSTRAINT nombre_manta_unico UNIQUE (nombre);


--
-- TOC entry 3484 (class 2606 OID 165868)
-- Name: tecnicos_ensayo nombre_tecnico_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tecnicos_ensayo
    ADD CONSTRAINT nombre_tecnico_unico UNIQUE (nombre);


--
-- TOC entry 3482 (class 2606 OID 165870)
-- Name: patron patron_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.patron
    ADD CONSTRAINT patron_pkey PRIMARY KEY (id_patron);


--
-- TOC entry 3520 (class 2606 OID 165872)
-- Name: tipo_pertiga per_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_pertiga
    ADD CONSTRAINT per_unico UNIQUE (cod_marca, largo, corriente_fuga_max, caracteristica);


--
-- TOC entry 3528 (class 2606 OID 165874)
-- Name: perfil perfil_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.perfil
    ADD CONSTRAINT perfil_pkey PRIMARY KEY (id);


--
-- TOC entry 3530 (class 2606 OID 165876)
-- Name: periodicidad periodicidad_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.periodicidad
    ADD CONSTRAINT periodicidad_pkey PRIMARY KEY (id);


--
-- TOC entry 3534 (class 2606 OID 165878)
-- Name: personas personas_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.personas
    ADD CONSTRAINT personas_pkey PRIMARY KEY (rut);


--
-- TOC entry 3536 (class 2606 OID 165880)
-- Name: resumen_epp_ensayados resumen_epp_ensayados_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.resumen_epp_ensayados
    ADD CONSTRAINT resumen_epp_ensayados_pkey PRIMARY KEY (id);


--
-- TOC entry 3538 (class 2606 OID 165882)
-- Name: resumen_estadistico resumen_estadistico_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.resumen_estadistico
    ADD CONSTRAINT resumen_estadistico_pkey PRIMARY KEY (id);


--
-- TOC entry 3478 (class 2606 OID 165884)
-- Name: serie_loadbuster serie_loadbuster_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.serie_loadbuster
    ADD CONSTRAINT serie_loadbuster_pkey PRIMARY KEY (id_epp);


--
-- TOC entry 3430 (class 2606 OID 165886)
-- Name: epps serie_unica; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.epps
    ADD CONSTRAINT serie_unica UNIQUE (serie_epp);


--
-- TOC entry 3419 (class 2606 OID 165888)
-- Name: sucursales sucursales_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.sucursales
    ADD CONSTRAINT sucursales_pkey PRIMARY KEY (cod_sucursal);


--
-- TOC entry 3486 (class 2606 OID 165890)
-- Name: tecnicos_ensayo tecnicos_ensayo_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tecnicos_ensayo
    ADD CONSTRAINT tecnicos_ensayo_pkey PRIMARY KEY (id_tecnico);


--
-- TOC entry 3491 (class 2606 OID 165892)
-- Name: tipo_aterramiento tipo_aterramiento_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_aterramiento
    ADD CONSTRAINT tipo_aterramiento_pkey PRIMARY KEY (id_tipo);


--
-- TOC entry 3496 (class 2606 OID 165894)
-- Name: tipo_banqueta tipo_banqueta_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_banqueta
    ADD CONSTRAINT tipo_banqueta_pkey PRIMARY KEY (id_tipo);


--
-- TOC entry 3500 (class 2606 OID 165896)
-- Name: tipo_cubrelinea tipo_cubrelinea_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_cubrelinea
    ADD CONSTRAINT tipo_cubrelinea_pkey PRIMARY KEY (id_tipo);


--
-- TOC entry 3504 (class 2606 OID 165898)
-- Name: tipo_cubreposte tipo_cubreposte_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_cubreposte
    ADD CONSTRAINT tipo_cubreposte_pkey PRIMARY KEY (id_tipo);


--
-- TOC entry 3405 (class 2606 OID 165900)
-- Name: clase_epp tipo_ens_unico; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.clase_epp
    ADD CONSTRAINT tipo_ens_unico UNIQUE (tipo_ensayo);


--
-- TOC entry 3436 (class 2606 OID 165902)
-- Name: tipo_guante tipo_guante_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_guante
    ADD CONSTRAINT tipo_guante_pkey PRIMARY KEY (id_tipo);


--
-- TOC entry 3508 (class 2606 OID 165904)
-- Name: tipo_jumper tipo_jumper_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_jumper
    ADD CONSTRAINT tipo_jumper_pkey PRIMARY KEY (id_tipo);


--
-- TOC entry 3476 (class 2606 OID 165906)
-- Name: tipo_loadbuster tipo_loadbuster_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_loadbuster
    ADD CONSTRAINT tipo_loadbuster_pkey PRIMARY KEY (id_tipo);


--
-- TOC entry 3512 (class 2606 OID 165908)
-- Name: tipo_manguilla tipo_manguilla_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_manguilla
    ADD CONSTRAINT tipo_manguilla_pkey PRIMARY KEY (id_tipo);


--
-- TOC entry 3517 (class 2606 OID 165910)
-- Name: tipo_manta tipo_manta_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_manta
    ADD CONSTRAINT tipo_manta_pkey PRIMARY KEY (id_tipo);


--
-- TOC entry 3522 (class 2606 OID 165912)
-- Name: tipo_pertiga tipo_pertiga_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_pertiga
    ADD CONSTRAINT tipo_pertiga_pkey PRIMARY KEY (id_tipo);


--
-- TOC entry 3543 (class 2606 OID 165914)
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);


--
-- TOC entry 3431 (class 1259 OID 165915)
-- Name: fki_fk_clase_epp; Type: INDEX; Schema: dielab; Owner: postgres
--

CREATE INDEX fki_fk_clase_epp ON dielab.tipo_guante USING btree (clase);


--
-- TOC entry 3432 (class 1259 OID 165916)
-- Name: fki_fk_clase_tipo; Type: INDEX; Schema: dielab; Owner: postgres
--

CREATE INDEX fki_fk_clase_tipo ON dielab.tipo_guante USING btree (clase);


--
-- TOC entry 3539 (class 1259 OID 165917)
-- Name: fki_fk_cliente; Type: INDEX; Schema: dielab; Owner: postgres
--

CREATE INDEX fki_fk_cliente ON dielab.usuarios USING btree (cliente);


--
-- TOC entry 3428 (class 1259 OID 165918)
-- Name: fki_fk_estado_uso; Type: INDEX; Schema: dielab; Owner: postgres
--

CREATE INDEX fki_fk_estado_uso ON dielab.epps USING btree (estado_uso);


--
-- TOC entry 3513 (class 1259 OID 165919)
-- Name: fki_fk_largo; Type: INDEX; Schema: dielab; Owner: postgres
--

CREATE INDEX fki_fk_largo ON dielab.tipo_manta USING btree (largo);


--
-- TOC entry 3494 (class 1259 OID 165920)
-- Name: fki_fk_marca; Type: INDEX; Schema: dielab; Owner: postgres
--

CREATE INDEX fki_fk_marca ON dielab.tipo_banqueta USING btree (cod_marca);


--
-- TOC entry 3540 (class 1259 OID 165921)
-- Name: fki_fk_perfil; Type: INDEX; Schema: dielab; Owner: postgres
--

CREATE INDEX fki_fk_perfil ON dielab.usuarios USING btree (perfil);


--
-- TOC entry 3541 (class 1259 OID 165922)
-- Name: fki_fk_rut; Type: INDEX; Schema: dielab; Owner: postgres
--

CREATE INDEX fki_fk_rut ON dielab.usuarios USING btree (rut);


--
-- TOC entry 3403 (class 1259 OID 165923)
-- Name: fki_fk_tipo_ensayo; Type: INDEX; Schema: dielab; Owner: postgres
--

CREATE INDEX fki_fk_tipo_ensayo ON dielab.clase_epp USING btree (tipo_ensayo);


--
-- TOC entry 3489 (class 1259 OID 165924)
-- Name: fki_tipo_ate_carac_fk; Type: INDEX; Schema: dielab; Owner: postgres
--

CREATE INDEX fki_tipo_ate_carac_fk ON dielab.tipo_aterramiento USING btree (caracteristica);


--
-- TOC entry 3518 (class 1259 OID 165925)
-- Name: fki_tipo_per_carac_fk; Type: INDEX; Schema: dielab; Owner: postgres
--

CREATE INDEX fki_tipo_per_carac_fk ON dielab.tipo_pertiga USING btree (caracteristica);


--
-- TOC entry 3586 (class 2620 OID 165926)
-- Name: resumen_epp_ensayados act_valor_id; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER act_valor_id BEFORE INSERT ON dielab.resumen_epp_ensayados FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_id_resumen();


--
-- TOC entry 3577 (class 2620 OID 165927)
-- Name: patron trig_act_calibracion; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_calibracion BEFORE INSERT OR UPDATE ON dielab.patron FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_calibracion();


--
-- TOC entry 3574 (class 2620 OID 165928)
-- Name: encabezado_ensayo trig_act_estado; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_estado AFTER INSERT OR UPDATE ON dielab.encabezado_ensayo FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_estado();


--
-- TOC entry 3588 (class 2620 OID 165929)
-- Name: resumen_estadistico trig_act_id; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_id BEFORE INSERT ON dielab.resumen_estadistico FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_id();


--
-- TOC entry 3578 (class 2620 OID 165930)
-- Name: tipo_aterramiento trig_act_marca; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_marca BEFORE INSERT OR UPDATE ON dielab.tipo_aterramiento FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_nombre_marca();


--
-- TOC entry 3579 (class 2620 OID 165931)
-- Name: tipo_banqueta trig_act_marca; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_marca BEFORE INSERT OR UPDATE ON dielab.tipo_banqueta FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_nombre_marca();


--
-- TOC entry 3580 (class 2620 OID 165932)
-- Name: tipo_cubrelinea trig_act_marca; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_marca BEFORE INSERT OR UPDATE ON dielab.tipo_cubrelinea FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_nombre_marca();


--
-- TOC entry 3581 (class 2620 OID 165933)
-- Name: tipo_cubreposte trig_act_marca; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_marca BEFORE INSERT OR UPDATE ON dielab.tipo_cubreposte FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_nombre_marca();


--
-- TOC entry 3575 (class 2620 OID 165934)
-- Name: tipo_guante trig_act_marca; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_marca BEFORE INSERT OR UPDATE ON dielab.tipo_guante FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_nombre_marca();


--
-- TOC entry 3582 (class 2620 OID 165935)
-- Name: tipo_jumper trig_act_marca; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_marca BEFORE INSERT OR UPDATE ON dielab.tipo_jumper FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_nombre_marca();


--
-- TOC entry 3576 (class 2620 OID 165936)
-- Name: tipo_loadbuster trig_act_marca; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_marca BEFORE INSERT OR UPDATE ON dielab.tipo_loadbuster FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_nombre_marca();


--
-- TOC entry 3583 (class 2620 OID 165937)
-- Name: tipo_manguilla trig_act_marca; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_marca BEFORE INSERT OR UPDATE ON dielab.tipo_manguilla FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_nombre_marca();


--
-- TOC entry 3584 (class 2620 OID 165938)
-- Name: tipo_manta trig_act_marca; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_marca BEFORE INSERT OR UPDATE ON dielab.tipo_manta FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_nombre_marca();


--
-- TOC entry 3585 (class 2620 OID 165939)
-- Name: tipo_pertiga trig_act_marca; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_marca BEFORE INSERT OR UPDATE ON dielab.tipo_pertiga FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_nombre_marca();


--
-- TOC entry 3587 (class 2620 OID 165940)
-- Name: resumen_estadistico trig_act_total; Type: TRIGGER; Schema: dielab; Owner: postgres
--

CREATE TRIGGER trig_act_total BEFORE INSERT OR UPDATE ON dielab.resumen_estadistico FOR EACH ROW EXECUTE FUNCTION dielab.actualiza_total();


--
-- TOC entry 3545 (class 2606 OID 165941)
-- Name: epps fk_clase_epp; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.epps
    ADD CONSTRAINT fk_clase_epp FOREIGN KEY (clase_epp) REFERENCES dielab.clase_epp(id_clase_epp) MATCH FULL;


--
-- TOC entry 3563 (class 2606 OID 165946)
-- Name: tipo_manguilla fk_clase_tipo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_manguilla
    ADD CONSTRAINT fk_clase_tipo FOREIGN KEY (clase) REFERENCES dielab.clase_tipo(id_clase) MATCH FULL ON DELETE RESTRICT;


--
-- TOC entry 3554 (class 2606 OID 165951)
-- Name: tipo_banqueta fk_clase_tipo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_banqueta
    ADD CONSTRAINT fk_clase_tipo FOREIGN KEY (clase) REFERENCES dielab.clase_tipo(id_clase) MATCH FULL ON DELETE RESTRICT;


--
-- TOC entry 3556 (class 2606 OID 165956)
-- Name: tipo_cubrelinea fk_clase_tipo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_cubrelinea
    ADD CONSTRAINT fk_clase_tipo FOREIGN KEY (clase) REFERENCES dielab.clase_tipo(id_clase) MATCH FULL ON DELETE RESTRICT;


--
-- TOC entry 3559 (class 2606 OID 165961)
-- Name: tipo_cubreposte fk_clase_tipo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_cubreposte
    ADD CONSTRAINT fk_clase_tipo FOREIGN KEY (clase) REFERENCES dielab.clase_tipo(id_clase) MATCH FULL ON DELETE RESTRICT;


--
-- TOC entry 3547 (class 2606 OID 165966)
-- Name: tipo_guante fk_clase_tipo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_guante
    ADD CONSTRAINT fk_clase_tipo FOREIGN KEY (clase) REFERENCES dielab.clase_tipo(id_clase) MATCH FULL ON DELETE RESTRICT;


--
-- TOC entry 3561 (class 2606 OID 165971)
-- Name: tipo_jumper fk_clase_tipo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_jumper
    ADD CONSTRAINT fk_clase_tipo FOREIGN KEY (clase) REFERENCES dielab.clase_tipo(id_clase) MATCH FULL ON DELETE RESTRICT;


--
-- TOC entry 3565 (class 2606 OID 165976)
-- Name: tipo_manta fk_clase_tipo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_manta
    ADD CONSTRAINT fk_clase_tipo FOREIGN KEY (clase) REFERENCES dielab.clase_tipo(id_clase) MATCH FULL ON DELETE RESTRICT;


--
-- TOC entry 3571 (class 2606 OID 165981)
-- Name: usuarios fk_cliente; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.usuarios
    ADD CONSTRAINT fk_cliente FOREIGN KEY (cliente) REFERENCES dielab.cliente(id_cliente) MATCH FULL ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3546 (class 2606 OID 165986)
-- Name: epps fk_estado_uso; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.epps
    ADD CONSTRAINT fk_estado_uso FOREIGN KEY (estado_uso) REFERENCES dielab.estado_uso(id) MATCH FULL;


--
-- TOC entry 3551 (class 2606 OID 165991)
-- Name: tipo_aterramiento fk_largo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_aterramiento
    ADD CONSTRAINT fk_largo FOREIGN KEY (largo) REFERENCES dielab.cuerpos_aterramiento(id) MATCH FULL ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3568 (class 2606 OID 165996)
-- Name: tipo_pertiga fk_largo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_pertiga
    ADD CONSTRAINT fk_largo FOREIGN KEY (largo) REFERENCES dielab.largo_pertiga(id) MATCH FULL ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3557 (class 2606 OID 166001)
-- Name: tipo_cubrelinea fk_largo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_cubrelinea
    ADD CONSTRAINT fk_largo FOREIGN KEY (largo) REFERENCES dielab.largo_cubrelinea(id) MATCH FULL ON DELETE RESTRICT;


--
-- TOC entry 3548 (class 2606 OID 166006)
-- Name: tipo_guante fk_largo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_guante
    ADD CONSTRAINT fk_largo FOREIGN KEY (largo) REFERENCES dielab.largo_guante(id_largo) MATCH FULL ON DELETE RESTRICT;


--
-- TOC entry 3566 (class 2606 OID 166011)
-- Name: tipo_manta fk_largo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_manta
    ADD CONSTRAINT fk_largo FOREIGN KEY (largo) REFERENCES dielab.largo_manta(id) MATCH FULL ON DELETE RESTRICT;


--
-- TOC entry 3552 (class 2606 OID 166016)
-- Name: tipo_aterramiento fk_marca; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_aterramiento
    ADD CONSTRAINT fk_marca FOREIGN KEY (cod_marca) REFERENCES dielab.marca(id_marca) MATCH FULL ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3550 (class 2606 OID 166021)
-- Name: tipo_loadbuster fk_marca; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_loadbuster
    ADD CONSTRAINT fk_marca FOREIGN KEY (cod_marca) REFERENCES dielab.marca(id_marca) MATCH FULL ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3569 (class 2606 OID 166026)
-- Name: tipo_pertiga fk_marca; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_pertiga
    ADD CONSTRAINT fk_marca FOREIGN KEY (cod_marca) REFERENCES dielab.marca(id_marca) MATCH FULL ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3564 (class 2606 OID 166031)
-- Name: tipo_manguilla fk_marca; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_manguilla
    ADD CONSTRAINT fk_marca FOREIGN KEY (cod_marca) REFERENCES dielab.marca(id_marca) MATCH FULL ON DELETE RESTRICT;


--
-- TOC entry 3555 (class 2606 OID 166036)
-- Name: tipo_banqueta fk_marca; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_banqueta
    ADD CONSTRAINT fk_marca FOREIGN KEY (cod_marca) REFERENCES dielab.marca(id_marca) MATCH FULL ON DELETE RESTRICT;


--
-- TOC entry 3558 (class 2606 OID 166041)
-- Name: tipo_cubrelinea fk_marca; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_cubrelinea
    ADD CONSTRAINT fk_marca FOREIGN KEY (cod_marca) REFERENCES dielab.marca(id_marca) MATCH FULL ON DELETE RESTRICT;


--
-- TOC entry 3560 (class 2606 OID 166046)
-- Name: tipo_cubreposte fk_marca; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_cubreposte
    ADD CONSTRAINT fk_marca FOREIGN KEY (cod_marca) REFERENCES dielab.marca(id_marca) MATCH FULL ON DELETE RESTRICT;


--
-- TOC entry 3549 (class 2606 OID 166051)
-- Name: tipo_guante fk_marca; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_guante
    ADD CONSTRAINT fk_marca FOREIGN KEY (cod_marca) REFERENCES dielab.marca(id_marca) MATCH FULL ON DELETE RESTRICT;


--
-- TOC entry 3562 (class 2606 OID 166056)
-- Name: tipo_jumper fk_marca; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_jumper
    ADD CONSTRAINT fk_marca FOREIGN KEY (cod_marca) REFERENCES dielab.marca(id_marca) MATCH FULL ON DELETE RESTRICT;


--
-- TOC entry 3567 (class 2606 OID 166061)
-- Name: tipo_manta fk_marca; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_manta
    ADD CONSTRAINT fk_marca FOREIGN KEY (cod_marca) REFERENCES dielab.marca(id_marca) MATCH FULL ON DELETE RESTRICT;


--
-- TOC entry 3572 (class 2606 OID 166066)
-- Name: usuarios fk_perfil; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.usuarios
    ADD CONSTRAINT fk_perfil FOREIGN KEY (perfil) REFERENCES dielab.perfil(id) MATCH FULL ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3573 (class 2606 OID 166071)
-- Name: usuarios fk_rut; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.usuarios
    ADD CONSTRAINT fk_rut FOREIGN KEY (rut) REFERENCES dielab.personas(rut) MATCH FULL ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3544 (class 2606 OID 166076)
-- Name: clase_epp fk_tipo_ensayo; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.clase_epp
    ADD CONSTRAINT fk_tipo_ensayo FOREIGN KEY (tipo_ensayo) REFERENCES dielab.ensayos_tipo(id_ensayo_tipo) MATCH FULL ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 3553 (class 2606 OID 166081)
-- Name: tipo_aterramiento tipo_ate_carac_fk; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_aterramiento
    ADD CONSTRAINT tipo_ate_carac_fk FOREIGN KEY (caracteristica) REFERENCES dielab.caracteristica_aterramiento(id) ON DELETE RESTRICT;


--
-- TOC entry 3570 (class 2606 OID 166086)
-- Name: tipo_pertiga tipo_per_carac_fk; Type: FK CONSTRAINT; Schema: dielab; Owner: postgres
--

ALTER TABLE ONLY dielab.tipo_pertiga
    ADD CONSTRAINT tipo_per_carac_fk FOREIGN KEY (caracteristica) REFERENCES dielab.caracteristica_pertiga(id) ON DELETE RESTRICT;


-- Completed on 2022-09-05 20:32:02

--
-- PostgreSQL database dump complete
--

