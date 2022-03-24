<?php
/* 
* Modulo para el Sistema de Usuarios
*/
function peticion($peticion){

  	$cuerpo = PETICION_NO_IMPLEMENTADA;
	$nave = new nauta(USUARIOS['base'], IREK, USUARIOS['ruta']);
  
  	switch ($peticion) {
		// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		// :::::::::::::::::::::::::::::::::::::: Area Nuevo ::::::::::::::::::::::::::::::::::::::::::
		// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		
		
		// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		// ::::::::::::::::::::::::::::::::::::: Area Elimina :::::::::::::::::::::::::::::::::::::::::
		// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		

		// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		// :::::::::::::::::::::::::::::::::: Area Actualizaciones ::::::::::::::::::::::::::::::::::::
		// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		case 'cambioPass':
			$fields = array("nick", "token", "uNick", "nvoPass");// Lista de parametros por recibir
			$box    = new Storer($fields);
			if(empty($x = $box->stocker)){return $cuerpo = FALTAN_PARAMETROS;}// Si retorna null sale de la peticion

			// Primero se verifica que el usuario exista y este activo
			$sql = "SELECT Id_Usuario FROM navegantes n WHERE n.Nick LIKE '$x->uNick'";
			$existe = peticion_estandar($x->nick, $x->token, USUARIOS['base'], $sql);
			
			if ($existe['status']==true ) {// Se ejecuto bien la consulta
				$cambio = $nave->consultaSQL_asociativo("SELECT change_pass_x_nick('$x->uNick','$x->nvoPass') AS 'resp';");
				if( $cambio['status']==true && $cambio['data'][0]['resp']=='1' ){
					$cuerpo['status'] = $cambio['status'];
					$cuerpo['msj'] 	  = "Password cambiado con exito!";
					$cuerpo['data']   = null;	
				}else{
					$cuerpo['status'] = $cambio['status'];
					$cuerpo['msj'] 	  = "NO se pudo cambiar el password!";
					$cuerpo['data']   = null;
				}
			} else {
				// Se muestra el error
				$cuerpo['status'] = $existe['status'];
				$cuerpo['msj'] 	  = $existe['msj'];
				$cuerpo['data']   = $existe['data'];
			}

			break;

		case 'cambioNick':
			$fields = array("nick", "token", "uNick", "nvoNick");// Lista de parametros por recibir
			$box    = new Storer($fields);
			if(empty($x = $box->stocker)){return $cuerpo = FALTAN_PARAMETROS;}// Si retorna null sale de la peticion

			// Primero se verifica que el usuario exista y este activo
			$sql = "SELECT Id_Usuario FROM navegantes n WHERE n.Nick LIKE '$x->uNick'";
			$existe = peticion_estandar($x->nick, $x->token, USUARIOS['base'], $sql);
			// print_r($existe);
			if ($existe['status']==true && !empty($existe['data'])) {// Se ejecuto bien la consulta
				$cambio = $nave->actualizar("navegantes","Id_Usuario",$existe['data'][0]['Id_Usuario'],array("Nick"=>$x->nvoNick));
				// print_r($cambio);
				if( $cambio['status']==true ){
					$cuerpo['status'] = $cambio['status'];
					$cuerpo['msj'] 	  = "Nombre de Usuario cambiado con exito! ".$cambio['msj'];
					$cuerpo['data']   = null;	
				}else{
					$cuerpo['status'] = $cambio['status'];
					$cuerpo['msj'] 	  = "NO se pudo cambiar el nombre de Usuario. ".$cambio['msj'];
					$cuerpo['data']   = null;
				}
			} else {
				// Se muestra el error
				$cuerpo['status'] = $existe['status'];
				$cuerpo['msj'] 	  = "No existe el nombre de Usuario (Nick) a cambiar.";
				$cuerpo['data']   = $existe['data'];
			}

			break;

		// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		// ::::::::::::::::::::::::::::::::::::: Area Consultas :::::::::::::::::::::::::::::::::::::::
		// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		case 'verPass':
			$fields = array("nick", "token", "uNick");// Lista de parametros por recibir
			$box    = new Storer($fields);
			if(empty($x = $box->stocker)){return $cuerpo = FALTAN_PARAMETROS;}// Si retorna null sale de la peticion

			// Se verifica el nick y token
			$id = userCheck($x->nick, $x->token);
    		if ($id['status'] == FALSE) { 
				$cuerpo 		= CHECKUSER_INVALIDO;
				$cuerpo['msj'] .= $id['msj'];
				return $cuerpo; 
			}

			$sql = "SELECT decrypt_pass_x_nick('$x->uNick') AS 'Password';";
			$lg  = $nave->consultaSQL_asociativo($sql);
			// print_r($lg);
			if ($lg['status']==true) {
				$cuerpo['status'] = $lg['status'];
				$cuerpo['msj'] 	  = $lg['msj'];
				$cuerpo['data']   = $lg['data'][0]['Password'];
			} else {
				$cuerpo['status'] = $lg['status'];
				$cuerpo['msj'] 	  = "Ver Pass dice: ".$lg['msj'];
				$cuerpo['data']   = $lg['data'];
			}

			break;

		
		
		// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		// ::::::::::::::::::::::::::::::::::: Area Logica (Otros) ::::::::::::::::::::::::::::::::::::
		// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
		case 'login':
			$fields = array("nick", "pass", "fuente", "lat", "lng");// Lista de parametros por recibir
			$box    = new Storer($fields);
			if(empty($x = $box->stocker)){return $cuerpo = FALTAN_PARAMETROS;}// Si retorna null sale de la peticion

			$sql = "CALL login('$x->nick', '$x->pass', '$x->fuente', '$x->lat', '$x->lng');";
			$lg  = $nave->consultaSQL_asociativo($sql);

			if ($lg['status']==true) {

				$dts = $lg['data'][0];

				if ($dts['status']==true) {
					$info = array(
						"nick" 	  	  => $dts['Nick'],
                    	"token" 	  => $dts['Token'],
                    	"Paterno" 	  => $dts['Paterno'],
                    	"Materno" 	  => $dts['Materno'],
                    	"Nombre" 	  => $dts['Nombre'],
                    	"Nivel" 	  => $dts['Nivel'],
                    	"Activo" 	  => $dts['Activo'],
                    	"EnLinea" 	  => $dts['EnLinea'],
                    	"VistaPrevia" => $dts['Vista_previa']
					);


					// Se agrega el menu del usuario
					$sql = "SELECT m.Modulo, m.Ruta, l.Principal, l.Escritura, f.Fuente ".
						   " FROM links l ".
						   " LEFT JOIN modulos m ON (m.Id_Modulo = l.Id_Modulo) ".
						   " LEFT JOIN fuentes f ON (f.Id_Fuente = l.Id_Fuente) ".
						   " WHERE l.Id_Usuario = '".$dts['Id']."' AND f.Fuente LIKE '".$x->fuente."';";
					
					$m = $nave->consultaSQL_asociativo($sql);
					$menu = [];
					// print_r($m);
					if ( $m['status']==true ) {

						foreach ($m['data'] as $k => $v) {
							if ($v['Principal']=='1') {
								$menu['princial'] = $m['data'][$k];
							} else {
								$menu['opciones'][] = $m['data'][$k];
							}
						}
						$info['MenUsuario'] = $menu;
					}
					

					$cuerpo['status'] = $dts['status'];
					$cuerpo['msj'] 	  = $dts['msj'];
					$cuerpo['data']   = $info;




				} else {
					$cuerpo['status'] = $dts['status'];
					$cuerpo['msj'] 	  = $dts['msj'];
					$cuerpo['data']   = null;
				}
			} else {
				$cuerpo['status'] = $lg['status'];
				$cuerpo['msj'] 	  = "login dice: ".$lg['msj'];
				$cuerpo['data']   = $lg['data'];
			}
			

			break;

		case 'logout':
			$fields = array("nick", "fuente", "lat", "lng");// Lista de parametros por recibir
			$box    = new Storer($fields);
			if(empty($x = $box->stocker)){return $cuerpo = FALTAN_PARAMETROS;}// Si retorna null sale de la peticion

			$sql = "CALL logout('$x->nick', '$x->fuente', '$x->lat', '$x->lng');";
			$lg  = $nave->consultaSQL_asociativo($sql);

			if ($lg['status']==true) {

				$dts = $lg['data'][0];

				if ($dts['status']==true) {
					$cuerpo['status'] = $dts['status'];
					$cuerpo['msj'] 	  = $dts['msj'];
					$cuerpo['data']   = null;
				} else {
					$cuerpo['status'] = $dts['status'];
					$cuerpo['msj'] 	  = $dts['msj'];
					$cuerpo['data']   = null;
				}
			} else {
				$cuerpo['status'] = $lg['status'];
				$cuerpo['msj'] 	  = "logou dice: ".$lg['msj'];
				$cuerpo['data']   = $lg['data'];
			}

			break;

        

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