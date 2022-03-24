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
	
	$tabla['nombre'] = "navegantes";// <<<<<<<<<<<<< Nombre de la tabla en la BD
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
		case 'nvoUsuario':
			$fields = array("nick","token", "pat", "mat", "nom", "unick", "upass");// Lista de parametros por recibir
			$box    = new Storer($fields);
			if(empty($x = $box->stocker)){return $cuerpo = FALTAN_PARAMETROS;}// Si retorna null sale de la peticion
			if(empty($x->pat)){return $cuerpo = FALTAN_PARAMETROS;}// Si retorna null sale de la peticion
			if(empty($x->mat)){return $cuerpo = FALTAN_PARAMETROS;}// Si retorna null sale de la peticion
			if(empty($x->nom)){return $cuerpo = FALTAN_PARAMETROS;}// Si retorna null sale de la peticion
			if(empty($x->unick)){return $cuerpo = NICK_INVALIDO;}// Si retorna null sale de la peticion
			if(empty($x->upass)){return $cuerpo = PASS_INVALIDO;}// Si retorna null sale de la peticion

			// Primero se crea el registro en la BD
			$Sql = "CALL inserta_usuario('$x->pat','$x->mat','$x->nom','$x->unick','$x->upass')";
			$rNvo = peticion_estandar($x->nick, $x->token, USUARIOS['base'], $Sql);

			if ($rNvo['status']==true) {
				// Segundo se crea la carpeta unica por cada usuario, el nombre de la carpeta seria el 'Id' del usuario
				$rCarpeta = $nave->crea_carpeta(USUARIOS['ruta'].$rNvo['data'][0]['Id']);
				if ($rCarpeta['status']==true) {
					$cuerpo['status'] = $rCarpeta['status'];
					$cuerpo['msj'] 	  = "Usuario y Carpeta creados con exito!.";
					$cuerpo['data']   = array("Id"=>$rNvo['data'][0]['Id']);
				}else{
					// Se borra el registro de la base de datos, sin carpeta no se puede crear el usuario
					$eUs = $nave->eliminar(TABLA['nombre'],TABLA['id'],$rNvo['data'][0]['Id']);
					$cuerpo['status'] = $rCarpeta['status'];// Se manda el status FALSE por no haber sido creada la carpeta
					$cuerpo['msj'] 	  = $rCarpeta['status']." ".$eUs['msj'];
					$cuerpo['data']   = null;
					
				}
			}else{
				return $rNvo;
			}


			break;

		case 'fotoPerfilCargar':
			// Esta peticion carga una nueva foto de perfil para el usuario, en caso de ya existir la sbreescribe
			$fields = array("nick","token", "id");// Lista de parametros por recibir
			$box    = new Storer($fields, true);
			if(empty($x = $box->stocker)){return $cuerpo = FALTAN_PARAMETROS;}// Si retorna null sale de la peticion
			if(empty($x->id)){return $cuerpo = FALTAN_PARAMETROS;}// Si retorna null sale de la peticion

			$rt   = USUARIOS['ruta'].$x->id."/";
			$rtvp = USUARIOS['ruta_web'].$x->id."/";
	
			$_nombre = $x->id."-perfil";
	
			$d = array(
				"Tipo_archivo" => "PERFIL", 
				"Tabla"        => "navegantes",
				"Tabla_Id"     => $x->id
					);
			
			return peticion_insertar_archivo(
			  $x->nick, 
			  $x->token, 
			  USUARIOS['base'],
			  $rt, 
			  $rtvp,
			  'multimedia',
			  $_nombre,
			  $d
			);

			break;
		
		
		// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		// ::::::::::::::::::::::::::::::::::::: Area Elimina :::::::::::::::::::::::::::::::::::::::::
		// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		case 'delUsuario':
			$fields = array("nick","token", "id");// Lista de parametros por recibir
			$box    = new Storer($fields);
			if(empty($x = $box->stocker)){return $cuerpo = FALTAN_PARAMETROS;}// Si retorna null sale de la peticion

			// Primero se elminia el Usuario de la BD
			$rDelUs = peticion_eliminar($x->nick, $x->token, USUARIOS['base'],TABLA['nombre'], TABLA['id'], $x->id);

			if ($rDelUs['status']==true) {
				// Segundo se elimina la Carpeta del Usuario con todos sus archivos
				$rDelCarp = $nave->borra_carpeta($x->id);
				$cuerpo['status'] = $rDelCarp['status'];// Se manda el status FALSE por no haber sido creada la carpeta
				$cuerpo['msj'] 	  = $rDelUs['msj']." ".$rDelCarp['msj'];
				$cuerpo['data']   = $rDelUs['data'];
			} else {
				return $rDelUs;
			}
			


			break;

		// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		// :::::::::::::::::::::::::::::::::: Area Actualizaciones ::::::::::::::::::::::::::::::::::::
		// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
        case 'actUsuario':
			$fields = array("nick","token", "id", "datos");// Lista de parametros por recibir
			$box    = new Storer($fields);
			if(empty($x = $box->stocker)){return $cuerpo = FALTAN_PARAMETROS;}// Si retorna null sale de la peticion

			return peticion_actualizar($x->nick, $x->token, USUARIOS['base'], TABLA['nombre'], TABLA['id'], $x->id,(array)$x->datos);

			break;


		// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		// ::::::::::::::::::::::::::::::::::::: Area Consultas :::::::::::::::::::::::::::::::::::::::
		// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		case 'lstUsuarios':
			$fields = array("nick","token","campos");// Lista de parametros por recibir
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
		
		case 'UsuarioId':
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

		case 'fotoPerfilVer':
			$fields = array("nick","token", "id");// Lista de parametros por recibir
			$box    = new Storer($fields);
			if(empty($x = $box->stocker)){return $cuerpo = FALTAN_PARAMETROS;}// Si retorna null sale de la peticion
			if(empty($x->id)) 		     {return $cuerpo = ID_VALOR_INVALIDO;}// El 'id' no puede estar vacio

			// Se ejecuta la consulta
			$Sql   = "SELECT Ruta, Vista_previa FROM multimedia WHERE Tipo_archivo LIKE 'PERFIL' AND Tabla LIKE 'navegantes' AND Tabla_Id = '$x->id';";
			$cuerpo = peticion_estandar($x->nick, $x->token, USUARIOS['base'], $Sql);

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