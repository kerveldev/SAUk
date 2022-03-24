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
	
	$tabla['nombre'] = "navegantes_niveles";// <<<<<<<<<<<<< Nombre de la tabla en la BD
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
		case 'nvoNivel':
			$fields = array("nick","token", "datos");// Lista de parametros por recibir
			$box    = new Storer($fields);
			if(empty($x = $box->stocker)){return $cuerpo = FALTAN_PARAMETROS;}// Si retorna null sale de la peticion

			return peticion_insertar($x->nick, $x->token, USUARIOS['base'], TABLA['nombre'], (array)$x->datos);

			break;
		
		
		// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		// ::::::::::::::::::::::::::::::::::::: Area Elimina :::::::::::::::::::::::::::::::::::::::::
		// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		case 'delNivel':
			$fields = array("nick","token", "id");// Lista de parametros por recibir
			$box    = new Storer($fields);
			if(empty($x = $box->stocker)){return $cuerpo = FALTAN_PARAMETROS;}// Si retorna null sale de la peticion

			return peticion_eliminar($x->nick, $x->token, USUARIOS['base'],TABLA['nombre'], TABLA['id'], $x->id);

			break;

		// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		// :::::::::::::::::::::::::::::::::: Area Actualizaciones ::::::::::::::::::::::::::::::::::::
		// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
        case 'actNivel':
			$fields = array("nick","token", "id", "datos");// Lista de parametros por recibir
			$box    = new Storer($fields);
			if(empty($x = $box->stocker)){return $cuerpo = FALTAN_PARAMETROS;}// Si retorna null sale de la peticion

			return peticion_actualizar($x->nick, $x->token, USUARIOS['base'], TABLA['nombre'], TABLA['id'], $x->id,(array)$x->datos);

			break;


		// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		// ::::::::::::::::::::::::::::::::::::: Area Consultas :::::::::::::::::::::::::::::::::::::::
		// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		case 'lstNiveles':
			$fields = array("nick","token", "campos");// Lista de parametros por recibir
			$box    = new Storer($fields);
			if(empty($x = $box->stocker)){return $cuerpo = FALTAN_PARAMETROS;}// Si retorna null sale de la peticion
			if (!is_array($x->campos)) {return $cuerpo = FALTAN_PARAMETROS;}// Valida que el parametro campos contenga un arreglo

			// Si campos esta vacio
			if ( empty($x->campos) ) {
				$pSql   = "SELECT * FROM ".TABLA['nombre'].";";
				return peticion_estandar($x->nick, $x->token, USUARIOS['base'], $pSql);
			}

			// $cuerpo = $nave->estructuraTabla(TABLA);
			$vCamp = $nave->validaCampos(TABLA['nombre'], $x->campos, USUARIOS['base']);
			
			// Se obtienen los campos validos
			isset($vCamp['data']['validos'])
			?$validos = $vCamp['data']['validos']
			:$validos = array();

			if($vCamp['status']==true && count($validos)>0){
				// Se concatenan los campos validos para la consulta SELECT
				$strCamp = implode(",", $validos);
				
				// Se ejecuta la consulta
				$pSql   = "SELECT $strCamp FROM ".TABLA['nombre'].";";
				$cuerpo = peticion_estandar($x->nick, $x->token, USUARIOS['base'], $pSql);

				// Por ultimo se agregan los campos rechzados en caso de existir
				isset($vCamp['data']['rechazados']) 
						? $cuerpo['rechazados'] = $vCamp['data']['rechazados'] 
						: $cuerpo['rechazados'] = array();
			}else{
				$cuerpo = $vCamp;
				$cuerpo['msj'] .= " Campos rechazados.";
			}
			

			break;
		
		case 'NivelId':
			$fields = array("nick","token", "id", "campos");// Lista de parametros por recibir
			$box    = new Storer($fields);
			if(empty($x = $box->stocker)){return $cuerpo = FALTAN_PARAMETROS;}// Si retorna null sale de la peticion
			if(!is_array($x->campos)) 	 {return $cuerpo = FALTAN_PARAMETROS;}// Valida que el parametro campos contenga un arreglo
			if(empty($x->id)) 		 {return $cuerpo = ID_VALOR_INVALIDO;}// El 'id' no puede estar vacio


			// Si 'campos' esta vacio se retornan todos los campos
			if ( empty($x->campos) ) {
				$sql = "SELECT * FROM ".TABLA['nombre']." WHERE ".TABLA['id']." = '$x->id';";
				return peticion_estandar($x->nick, $x->token, USUARIOS['base'], $sql);
			}else{
				// $cuerpo = $nave->estructuraTabla(TABLA);
				$vCamp = $nave->validaCampos(TABLA['nombre'], $x->campos, USUARIOS['base']);
				
				// Se obtienen los campos validos
				isset($vCamp['data']['validos'])
				?$validos = $vCamp['data']['validos']
				:$validos = array();

				if($vCamp['status']==true && count($validos)>0){
					// Se concatenan los campos validos para la consulta SELECT
					$strCamp = implode(",", $validos);
					
					// Se ejecuta la consulta
					$pSql   = "SELECT $strCamp FROM ".TABLA['nombre']." WHERE ".TABLA['id']." = '$x->id';";
					$cuerpo = peticion_estandar($x->nick, $x->token, USUARIOS['base'], $pSql);

					// Por ultimo se agregan los campos rechzados en caso de existir
					isset($vCamp['data']['rechazados']) 
							? $cuerpo['rechazados'] = $vCamp['data']['rechazados'] 
							: $cuerpo['rechazados'] = array();
				}else{
					$cuerpo = $vCamp;
					$cuerpo['msj'] .= " Campos rechazados.";
				}
			}

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