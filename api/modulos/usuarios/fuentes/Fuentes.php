<?php
// error_reporting(E_ALL);
// ini_set('display_errors', '1');
/* 
* Modulo para el Sistema de Usuarios
*/
function peticion($peticion){
	$cuerpo = PETICION_NO_IMPLEMENTADA;
	$nave   = new nauta(USUARIOS['base'], IREK, USUARIOS['ruta']);
	$tabla  = null;

	// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	// :::::::::::::::::::::::::::::::: TABLA DEL MODULO ::::::::::::::::::::::::::::::::::::::::::
	// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	
	$tabla['nombre'] = "fuentes";// <<<<<<<<<<<<< Nombre de la tabla en la BD
	$t = $nave->estructuraTabla($tabla['nombre']);
	if (isset($t['data'])) {
		foreach ($t['data'] as $v) {
			if ($v ['COLUMN_KEY'] == 'PRI') $tabla['id'] = $v ['COLUMN_NAME'];
			$tabla['columnas'][] = $v ['COLUMN_NAME'];
		}
		
	}else {
		$cuerpo 	    = ERROR_ESTRUCTURA_TABLA;
		$cuerpo['msj'] .= " No se encontro informacion para la tabla ".$tabla['nombre'].".";
		return $cuerpo;
	}

	define("TABLA", $tabla);// Se crea la constante TABLA a la que esta ligada este modulo
	
	
	// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	// ::::::::::::::::::::::::::::: ACCIONES DEL MODULO ::::::::::::::::::::::::::::::::::::::::::
	// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  	switch ($peticion) {
		// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		// :::::::::::::::::::::::::::::::::::::: Area Nuevo ::::::::::::::::::::::::::::::::::::::::::
		// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		case 'nvoFuente':
			$fields = array("nick","token", "datos");// Lista de parametros por recibir
			$box    = new Storer($fields);
			if(empty($x = $box->stocker)){return $cuerpo = FALTAN_PARAMETROS;}// Si retorna null sale de la peticion

			return peticion_insertar($x->nick, $x->token, USUARIOS['base'], TABLA['nombre'], (array)$x->datos);

			break;
		
		
		// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		// ::::::::::::::::::::::::::::::::::::: Area Elimina :::::::::::::::::::::::::::::::::::::::::
		// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		case 'delFuente':
			$fields = array("nick","token", "id");// Lista de parametros por recibir
			$box    = new Storer($fields);
			if(empty($x = $box->stocker)){return $cuerpo = FALTAN_PARAMETROS;}// Si retorna null sale de la peticion

			return peticion_eliminar($x->nick, $x->token, USUARIOS['base'],TABLA['nombre'], TABLA['id'], $x->id);

			break;

		// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		// :::::::::::::::::::::::::::::::::: Area Actualizaciones ::::::::::::::::::::::::::::::::::::
		// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
        case 'actFuente':
			$fields = array("nick","token", "id", "datos");// Lista de parametros por recibir
			$box    = new Storer($fields);
			if(empty($x = $box->stocker)){return $cuerpo = FALTAN_PARAMETROS;}// Si retorna null sale de la peticion

			return peticion_actualizar($x->nick, $x->token, USUARIOS['base'], TABLA['nombre'], TABLA['id'], $x->id,(array)$x->datos);

			break;


		// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		// ::::::::::::::::::::::::::::::::::::: Area Consultas :::::::::::::::::::::::::::::::::::::::
		// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		case 'lstFuentes':
			$fields = array("nick","token", "campos");// Lista de parametros por recibir
			$box    = new Storer($fields);
			if(empty($x = $box->stocker)){return $cuerpo = FALTAN_PARAMETROS;}// Si retorna null sale de la peticion
			if (!is_array($x->campos))   {return $cuerpo = FALTAN_PARAMETROS;}// Valida que el parametro campos contenga un arreglo

			$cuerpo = listarTabla($x->nick, $x->token, $nave, USUARIOS['base'], TABLA, $x->campos);
			break;
		
		case 'FuenteId':
			$fields = array("nick","token", "id", "campos");// Lista de parametros por recibir
			$box    = new Storer($fields);
			if(empty($x = $box->stocker)){return $cuerpo = FALTAN_PARAMETROS;}// Si retorna null sale de la peticion
			if(!is_array($x->campos)) 	 {return $cuerpo = FALTAN_PARAMETROS;}// Valida que el parametro campos contenga un arreglo
			if(empty($x->id)) 		     {return $cuerpo = ID_VALOR_INVALIDO;}// El 'id' no puede estar vacio

			$cuerpo = listarTabla($x->nick, $x->token, $nave, USUARIOS['base'], TABLA, $x->campos, $x->id);

			
			break;

		
		// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		// ::::::::::::::::::::::::::::::::::: Area Logica (Otros) ::::::::::::::::::::::::::::::::::::
		// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::



		default:
			// No existe la peticion
			$cuerpo = PETICION_INVALIDA;
			break;
	}// Fin switch peticion
    
	return $cuerpo;
}// Fin funcion recurso


// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
// :::::::::::::::::::::::::::::::::: FUNCIONES AUXILIARES ::::::::::::::::::::::::::::::::::::
// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

?>