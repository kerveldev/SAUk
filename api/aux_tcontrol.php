<?php

// Checa si el usuario tiene un token de sesion
function userCheck($_nick, $_token){    
    $nave   = new nauta(USUARIOS['base']);
    $uCheck = CHECKUSER_INVALIDO;
    $sql    = "CALL checkuser('".$_nick."','".$_token."');";
    $t      = $nave->consultaSQL_asociativo($sql);
    // print_r($t);
    
    // Si la consulta fue un exito
    if( $t['status']==true ){
        $d = $t['data'][0];
        // print_r($d);
        if($d['status']==true) {
            $uCheck = $d;
        }else{
            $uCheck['msj'] .= $d['msj'];
        }
        
        return $uCheck;
        
    }else{
        // print_r($t);
        $eCheck = FALLO_CONSULTA_SQL;
        $eCheck['msj'] .= $t['msj'];
        return $eCheck;
    }
    
}


/***************************************************************
*           Peticion Estandar
****************************************************************
* Devuelve un conjunto de datos.
* Parametros:
*  - _nick  = Nombre de usuario.
*  - _token = Token,  para tenerlo debe estar logueado.
*  - _bd    = Base de datos sobre la que se esta trabajando.
*  - _sql   = Consulta a procesar en la base de datos.
* Devuelve:
*    Conjunto de datos, resultado de la consulta SQL.
****************************************************************/
function peticion_estandar($_nick, $_token, $_bd, $_sql){
    // Estructura de la respuesta
    $resp = array();

    // Se verifica que las variables no esten vacias
    // _nick y _token estan validados desde "storer"
    if( empty($_bd) )   { return BD_INVALIDO; }
    if( empty($_sql) )  { return SQL_INVALIDO; }

    // Se valida el usuario y se obtiene su Id
    $id = userCheck($_nick, $_token);
    if ($id['status'] == FALSE) { return $id; }
    
    // Se conecta a la base de datos
    $nave = new nauta($_bd);
    if( $nave->conectado==TRUE ){
        $t = $nave->consultaSQL_asociativo($_sql);
        // print_r($t);// DEBUG
        // Si la consulta fue un exito
        if( $t['status']==TRUE ){
            $resp['status'] = $t['status'];
            $resp['msj']    = $t['msj'];
            $resp['data']   = $t['data'];
        }else{
            $resp         = ERROR_PETICION_ESTANDAR;
            $resp['msj'] .= $t['msj'];
        }

    }else{
        $resp         = ERROR_CONEXION_BD;
        $resp['msj'] .= $nave->conx_error_msj;
    }
    return $resp;
}


/***************************************************************
*           Peticion Actualizar
****************************************************************
* Actualiza el registro en la tabla solicitada.
* Parametros:
*  - _nick  = Nombre de usuario.
*  - _token = Token,  para tenerlo debe estar logueado.
*  - _bd    = Base de datos sobre la que se esta trabajando.
*  - _tabla = Tabla a procesar.
*  - _id_tabla = Columa indice, ejem: "Id".
*  - _valor_id = Valor para la columna indice, ejem: "123".
*  - _datos = Datos a actualizar.
* Devuelve:
*
*****************************************************************/
function peticion_actualizar(
    $_nick, 
    $_token, 
    $_bd, 
    $_tabla, 
    $_id_tabla, 
    $_valor_id, 
    $_datos
    ){
    // Estructura de la respuesta
    $resp = array();

    // Se verifica que las variables no esten vacias
    // _nick y _token estan validados desde "storer"
    if( empty($_bd) )      { return BD_INVALIDO; }
    if( empty($_tabla) )   { return TABLA_INVALIDO; }
    if( empty($_id_tabla) ){ return ID_TABLA_INVALIDO; }
    if( empty($_valor_id) ){ return ID_VALOR_INVALIDO; }
    if( empty($_datos) )   { return DATOS_INVALIDO; }

    // Se valida el usuario y se obtiene su Id
    $id = userCheck($_nick, $_token);
    if ($id['status'] == FALSE) { return $id; }

    // Se conecta a la base de datos
    $nave = new nauta($_bd);
    if($nave->conectado==TRUE){
        $nave->array_push_assoc($_datos,array("UAct"=>$id['Id_Usuario']));
        $t = $nave->actualizar($_tabla ,$_id_tabla, $_valor_id, $_datos);
        // print_r($t);// DEBUG
        // Si la consulta fue un exito
        if($t['status']==TRUE){
            $resp['status'] = $t['status'];
            $resp['msj']    = $t['msj'];
            $resp['data']   = $t['data'];
        }else{
            $resp         = ERROR_PETICION_ACTUALIZAR;
            $resp['msj'] .= $t['msj'];
            $resp['data'] = $t;
        }

    }else{
        $resp         = ERROR_CONEXION_BD;
        $resp['msj'] .= $nave->conx_error_msj;
    }
    return $resp;

}


/*************************************************************
*           Peticion Insertar
**************************************************************
* Inserta un nuevo registro en la tabla solicitada.
* Parametros:
*  _nick  = Nombre de usuario.
*  _token = Token,  para tenerlo debe estar logueado.
*  _bd    = Base de datos sobre la que se esta trabajando.
*  _tabla = Tabla a procesar.
*  _datos = Datos a insertar.
* Devuelve:
*   last_id = El id del registro creado.
***************************************************************/
function peticion_insertar(
    $_nick, 
    $_token, 
    $_bd, 
    $_tabla, 
    array $_datos
    ){
    // Estructura de la respuesta
    $resp = array();

    // Se verifica que las variables no esten vacias
    // _nick y _token estan validados desde "storer"
    if( empty($_bd) )      { return BD_INVALIDO; }
    if( empty($_tabla) )   { return TABLA_INVALIDO; }
    if( empty($_datos) )   { return DATOS_INVALIDO; }

    // Se valida el usuario y se obtiene su Id
    $id = userCheck($_nick, $_token);
    if ($id['status'] == FALSE) { return $id; }

    // Se conecta a la base de datos
    $nave = new nauta($_bd);
    if($nave->conectado==TRUE){
        $nave->array_push_assoc($_datos,array("UCrea"=>$id['Id_Usuario']));
        $t = $nave->insertar($_tabla, $_datos);
        // print_r($t);// DEBUG
        // Si la consulta fue un exito
        if($t['status']==TRUE){
            $resp['status']  = $t['status'];
            $resp['msj']     = $t['msj'];
            $resp['data']    = $t['data'];
            $resp['last_id'] = $t['last_id'];
        }else{
            $resp         = ERROR_PETICION_INSERTAR;
            $resp['msj'] .= $t['msj'];
        }

    }else{
        $resp         = ERROR_CONEXION_BD;
        $resp['msj'] .= $nave->conx_error_msj;
    }
    return $resp;

}


/*****************************************************************************
*           Peticion Insertar y crear Carpeta
******************************************************************************
* Inserta un nuevo registro en la tabla y crea una carpeta cuyo nombre es el
* Id del registro recien creado. En caso de error se elimina el registro.
*
* Parametros:
*  - _nick  = Nombre de usuario.
*  - _token = Token,  para tenerlo debe estar logueado.
*  - _bd    = Base de datos sobre la que se esta trabajando.
*  - _tabla = Tabla a procesar.
*  - _id_tabla = Columa indice, ejem: "Id".
*  - _datos = Datos a insertar.
*  - _ruta  = Ruta que contendra la nueva carpeta.
*
* Devuelve:
*  - last_id = El id del registro creado.
*******************************************************************************/
function peticion_insertar_carpeta(
    $_nick, 
    $_token, 
    $_bd, 
    $_tabla, 
    $_id_tabla, 
    $_datos, 
    $_ruta
    ){
    // Estructura de la respuesta
    $resp = array();

    // Se verifica que las variables no esten vacias
    // _nick y _token estan validados desde "storer"
    if( empty($_bd) )      { return BD_INVALIDO; }
    if( empty($_tabla) )   { return TABLA_INVALIDO; }
    if( empty($_id_tabla) ){ return ID_TABLA_INVALIDO; }
    if( empty($_datos) )   { return DATOS_INVALIDO; }
    if( empty($_ruta) )    { return RUTA_INVALIDA; }

    // Se valida el usuario y se obtiene su Id
    $id = userCheck($_nick, $_token);
    if ($id['status'] == FALSE) { return $id; }

    // Se conecta a la base de datos
    $nave = new nauta($_bd);
    if($nave->conectado==TRUE){
        $nave->array_push_assoc($_datos,array("UCrea"=>$id['Id_Usuario']));
        $t = $nave->insertar($_tabla, $_datos);
        // print_r($t); // DEBUG
        // Si la consulta fue un exito
        if($t['status']==TRUE){
            // Se crea la carpeta fisica del expediente
            $ar = $nave->crea_carpeta($_ruta.$t['last_id']);
            if($ar['status']==TRUE){
                $resp['status']  = $ar['status'];
                $resp['msj']     = "Registro y carpeta creados con exito.";
                $resp['data']    = $t['data'];
                $resp['last_id'] = $t['last_id'];
            }else {
                // En caso de error al crear la carpeta se elimina el registro recien creado
                $er = $nave->eliminar($_tabla, $_id_tabla,$t['last_id']);
                if ($er['status']==true) {
                    $resp         = ERROR_PETICION_INSERTAR_CARPETA;
                    $resp['msj'] .= "Se elimino el registro. Error al crear la carpeta. ".$ar['msj'];
                } else {
                    $resp         = ERROR_PETICION_INSERTAR_CARPETA;
                    $resp['msj'] .= "No se pudo eliminar el registro. ".$er['msj'];
                }
            }
        }else{
            $resp         = ERROR_PETICION_INSERTAR_CARPETA;
            $resp['msj'] .= $t['msj'];
        }

    }else{
        $resp         = ERROR_CONEXION_BD;
        $resp['msj'] .= $nave->conx_error_msj;
    }
    return $resp;

}




/********************************************************************************
*           Peticion Insertar y cargar un Archivo                               
*********************************************************************************
* Carga un archivo en el servidor, en caso de éxito crea un registro en la
* tabla indicada(_tabla), en caso de no existir el parametro, se intentará
* guardar en la tabla 'multimedia'. Esta tabla es parte de la estructura
* básica nescesaria en la base de datos para que funcione la API Nauta.
*
* Parametros:
*  - _nick  = Nombre de usuario.
*  - _token = Token,  para tenerlo debe estar logueado.
*  - _bd    = Base de datos sobre la que se esta trabajando.
*  - _ruta  = Ruta que contendra la nueva carpeta.                              
*  - _ruta_vista_prev  = Ruta que contendra la nueva carpeta.                   
*
* Opcionales:
*  - _tabla = Tabla a procesar.
*  - _nom   = Nombre del archivo, si se envía el nombre, entonces se no se toma
*           en cuenta el parametro 'rw'.
*  - _datos = Arreglo 'llave'->'valor', que contiene los valores para las demás
*           columnas de la tabla.
*  - _rw    = Si este parametro es TRUE, el nombre del archivo será el de la
*           propiedad 'name' del elemento 'inputfile' del front. Si es FALSE,
*           el nombre será el de la propiedad 'name' de la variable $_FILES.
*
* Devuelve:
*   - last_id = El id del registro creado.
*********************************************************************************/
function peticion_insertar_archivo(
    $_nick, 
    $_token, 
    $_bd, 
    $_ruta, 
    $_ruta_vista_prev,
    $_tabla = "multimedia",
    $_nom   = null,
    $_datos = null
    )
    {
    // Estructura de la respuesta
    $resp = array();

    // Se verifica que las variables no esten vacias
    // _nick y _token estan validados desde "storer"
    if( empty($_bd) )      { return BD_INVALIDO; }
    if( empty($_ruta) )    { return RUTA_INVALIDA; }
    if( empty($_ruta_vista_prev) ){ return RUTA_VISTA_PREVIA_INVALIDA; }

    // Se valida el usuario y se obtiene su Id
    $id = userCheck($_nick, $_token);
    if ($id['status'] == false) { return $id; }

    // Se conecta a la base de datos
    $nave = new nauta($_bd);
    if($nave->conectado==true){
        $_d = array();        
        // En caso de que existan datos, se añaden
        if(!empty($_datos)){
            $nave->array_push_assoc($_d, $_datos);
        }
        // Se agrega el Id_Usuario al arreglo de datos para guardar el usuario creador
        $nave->array_push_assoc($_d,array('UCrea' => $id['Id_Usuario']));
        $t = $nave->carga_archivos(
            $_ruta, 
            $_ruta_vista_prev, 
            $_tabla, 
            $_nom, 
            $_d
        );
        // Si la consulta fue un exito
        if($t['status']==true){
            $resp['status']           = $t['status'];
            $resp['msj']              = "Registro y archivo cargados con exito.";
            $resp['data']['Archivos'] = $t['Archivos'];
            $resp['data']['BD']       = $t['BD'];
            $resp['last_id']          = $t['last_id'];
        }else{
            $resp         = ERROR_PETICION_INSERTAR_ARCHIVO;
            $resp['msj'] .= "Error al cargar el archivo detalles en 'data'";
            $resp['data'] = $t;
        }

    }else{
        $resp         = ERROR_CONEXION_BD;
        $resp['msj'] .= $nave->conx_error_msj;
    }
    return $resp;
}


/******************************************************************************
*           Peticion Eliminar
*******************************************************************************
* Elimina un registro en la tabla solicitada.
*
* Parametros:
*  - _nick  = Nombre de usuario.
*  - _token = Token,  para tenerlo debe estar logueado.
*  - _bd    = Base de datos sobre la que se esta trabajando.
*  - _tabla = Tabla a procesar.
*  - _id_tabla = Columa indice, ejem: "Id".
*  - _valor_id = Valor para la columna indice, ejem: "123".
*
* Devuelve:
*
********************************************************************************/
function peticion_eliminar(
    $_nick, 
    $_token, 
    $_bd, 
    $_tabla, 
    $_id_tabla, 
    $_valor_id
    ){
    // Estructura de la respuesta
    $resp = array();

    // Se verifica que las variables no esten vacias
    // _nick y _token estan validados desde "storer"
    if( empty($_bd) )      { return BD_INVALIDO; }
    if( empty($_tabla) )   { return TABLA_INVALIDO; }
    if( empty($_id_tabla) ){ return ID_TABLA_INVALIDO; }
    if( empty($_valor_id) ){ return ID_VALOR_INVALIDO; }

    // Se valida el usuario y se obtiene su Id
    $id = userCheck($_nick, $_token);
    if ($id['status'] == FALSE) { return $id; }

    // Se conecta a la base de datos
    $nave = new nauta($_bd);
    if($nave->conectado==TRUE){
        $t = $nave->eliminar($_tabla, $_id_tabla,$_valor_id);
        // print_r($t);// DEBUG
        // Si la consulta fue un exito
        if($t['status']==TRUE){
            $resp['status']  = $t['status'];
            $resp['msj']     = $t['msj'];
            $resp['data']    = $t['data'];
        }else{
            $resp         = ERROR_PETICION_ELIMINAR;
            $resp['msj'] .= $t['msj'];
        }

    }else{
        $resp         = ERROR_CONEXION_BD;
        $resp['msj'] .= $nave->conx_error_msj;
    }
    return $resp;

}

/******************************************************************************
*           Peticion Eliminar registro y archivo
*******************************************************************************
* Elimina un registro en la BD y su archivo correspondiente. Se basa en el 
* nombre del archivo.
*
* Parametros:
*  - _nick  = Nombre de usuario.
*  - _token = Token,  para tenerlo debe estar logueado.
*  - _bd    = Base de datos sobre la que se esta trabajando.
*  - _tabla = Tabla a procesar.
*  - _nom   = Nombre del archivo para buscarlo en la BD.
*
* Devuelve:
*   TRUE si el archivo fue eliminado con exito.
********************************************************************************/
function peticion_eliminar_archivo(
    $_nick, 
    $_token, 
    $_bd, 
    $_tabla, 
    $_nom
    ){
    // Estructura de la respuesta
    $resp = array();

    // Se verifica que las variables no esten vacias
    // _nick y _token estan validados desde "storer"
    if( empty($_bd) )      { return BD_INVALIDO; }
    if( empty($_tabla) )   { return TABLA_INVALIDO; }
    if( empty($_nom) )     { return NOMBRE_ARCHIVO_INVALIDO; }

    // Se valida el usuario y se obtiene su Id
    $id = userCheck($_nick, $_token);
    if ($id['status'] == FALSE) { return $id; }

    // Se conecta a la base de datos
    $nave = new nauta($_bd);
    if($nave->conectado==TRUE){

        // Primero se verifica que exista el registro para ese nombre de archivo,
        // y se obtiene la ruta hacia el mismo, para ello se basa en que la estructura
        // de la tabla contiene minimo los campos Nombre, Ruta y Vista_previa

        $b = $nave->buscar($_tabla,'Nombre',$_nom);

        // Si existe el registro para el archivo
        if( $b['status']==true ){

            if ( $b['cant']==1 ) {
                $_ruta = $b['data']['Ruta'];

                // Se elimina el registro de la BD
                $el = $nave->eliminar($_tabla,'Nombre', $_nom);
                if ( $el['status']==true ) {

                    $br = $nave->borra_archivo($_ruta);
                    if ( $br['status']==true ) {
                        $resp['status'] = $br['status'];
                        $resp['msj']    = $br['msj'];
                        $resp['data']   = $el['data'];
                    }else {
                        $resp['status'] = $br['status'];
                        $resp['msj']    = "No se pudo eliminar el archivo: $_nom. Eliminelo manualmente. ".$br['msj'];
                        $resp['data']   = $el['data'];
                    }

                }else{
                    $resp['status'] = $el['status'];
                    $resp['msj']    = "No se pudo eliminar el registro.".$el['msj'];
                    $resp['data']   = $el['data'];
                }    
            } else {
                $resp['status'] = $b['status'];
                $resp['msj']    = "Error, más de un registro con el nombre: $_nom.";
                $resp['data']   = $b['data'];
            }
            
        }else{// No existe registro para el archivo
            $resp['status'] = $b['status'];
            $resp['msj']    = "Error al buscar a $_nom. ".$b['msj'];
            $resp['data']   = null;
        }
        
    }else{
        $resp         = ERROR_CONEXION_BD;
        $resp['msj'] .= $nave->conx_error_msj;
    }
    return $resp;

}







/*******************************************************************************
*           FUNCIONES EXTRAS
********************************************************************************
* Funciones que sirven para diversas acciones y auxilian en la plataforma.
********************************************************************************/

function validarFecha($date, $format = 'd/m/Y'){
   
    $d = DateTime::createFromFormat($format, $date);
    return $d && $d->format($format) == $date;
}


/***************************************************************
*           Peticion Listar Tabla
****************************************************************
* Devuelve un conjunto de datos y permite anexar campos de otras
* tablas al resultado.
* Parametros:
*  - _nick  = Nombre de usuario.
*  - _token = Token,  para tenerlo debe estar logueado.
*  - _bd    = Base de datos sobre la que se esta trabajando.
*  - _tabla = Constante que contiene el nombre de la tabla y el
              de la llave primaria.
*  - _campos = Lista de campos a recibir.
*  - _id     = Valir del campo id de la tabla principal
*  - _joins  = Arreglo de objetos que tiene la siguiente estructura:
*
*    [ 
*        {
*            "tabla" : "nombre de tabla 1",
*                "id": "nombre de la llave primaria",
*           "id_join": "nombre de la llave primaria foranea",
*            "campos": [ "IdTabla1", "campo1Tabla1", "campo2Tabla1" ]
*        },
*        ...
*        {
*            "tabla" : "nombre de tabla n",
*                "id": "nombre de la llave primaria",
*           "id_join": "nombre de la llave primaria foranea",
*            "campos": [ "IdTabla n", "campo1Tabla n", "campo2Tabla n" ]
*        }
*    ]
*  - _where = Se anexa una clausula where a la consulta SQL.
*
* Devuelve:
*    Conjunto de datos, resultado de la consulta SQL.
****************************************************************/
function listarTabla($_nick, $_token, $_nauta, $_bd, $_tabla, $_campos=null, $_id=null, $_joins=null, $_where=null){
    // Estructura de la respuesta
    $resp = array();

    // Se verifica que las variables no esten vacias
    // _nick y _token estan validados desde "storer"
    if( empty($_nauta) )  { return NAUTA_INVALIDO; }
    if( empty($_bd) )     { return BD_INVALIDO; }
    if( empty($_tabla) )  { return TABLA_INVALIDO; }
    // if( empty($_campos) ) { return CAMPOS_INVALIDO; }

    // Se valida el usuario y se obtiene su Id
    $id = userCheck($_nick, $_token);
    if ($id['status'] == FALSE) { return $id; }
    // $cuerpo = $nave->estructuraTabla(TABLA);

    // Se crean las consultas SQL
    $fin_sql   = ";";
    $joins_sql = "";
    $joinsCamp = [];
    $jStrCamp  = "";
    $where     = ""; 
    if(!empty($_where)){$where = $_where;}
    $sql       = "SELECT ".$_tabla['nombre'].".* $jStrCamp FROM ".$_tabla['nombre']." $joins_sql $where".$fin_sql;

    // Primero se evalua si existe el parametro $_joins para crear la cadena joins_sql
    if (!empty($_joins)) {
        $jStrCamp  .= ", ";
        $jValidos = null;
        foreach ($_joins as $tbl) {
            $struct = $_nauta->estructuraTabla($tbl->tabla);
            if(!empty($struct['data'])){
                // Se obtienen los campos validos
                $jCamp = $_nauta->validaCampos($tbl->tabla, $tbl->campos, $_bd);
                isset($jCamp['data']['validos'])
                ? $jValidos = $jCamp['data']['validos']
                : $jValidos = array();

                if($jCamp['status']==true && count($jValidos)>0){

                    foreach ($jValidos as $v) $joinsCamp[] = "$tbl->tabla.".$v; 

                    // Se crean los JOINS
                    $joins_sql .= " LEFT JOIN $tbl->tabla ON($tbl->tabla.$tbl->id = ".$_tabla['nombre'].".$tbl->id_join) ";

                    // Por ultimo se agregan los campos rechzados en caso de existir
                    isset($jCamp['data']['rechazados']) 
                    ? $resp['rechazados'] = $jCamp['data']['rechazados'] 
                    : $resp['rechazados'] = array();

                }else{
                    $resp = $jCamp;
                    $resp['msj'] .= " Todos los campos rechazados ($tbl->tabla).";
                    return $resp;
                }

            }else{
                $resp['msj']  = " La $tbl->tabla no existe.";
                $resp['data'] = $tbl->tabla;
            }
        }
        $jStrCamp  .= implode(",", $joinsCamp);
    }

    // Segundo se evalua si existe el $_id
    if (empty($_id)) {

        // Se verifica si se pidieron campos
        if (!empty($_campos)) {
            $validos = null;
            // Se obtienen los campos validos
            $vCamp = $_nauta->validaCampos($_tabla['nombre'], $_campos, $_bd);
            isset($vCamp['data']['validos'])
            ? $validos = $vCamp['data']['validos']
            : $validos = array();

            if($vCamp['status']==true && count($validos)>0){
                $lstCmp = [];
                foreach ($validos as $z) $lstCmp[] = TABLA['nombre'].".".$z; 
                // Se concatenan los campos validos para la consulta SELECT
                $strCamp = implode(",", $lstCmp);
                
                // Se crea la consulta con los campos pedidos
                $sql = "SELECT $strCamp $jStrCamp FROM ".$_tabla['nombre']." $joins_sql $where".$fin_sql;

                // Por ultimo se agregan los campos rechzados en caso de existir
                isset($vCamp['data']['rechazados']) 
                ? $resp['rechazados'] = $vCamp['data']['rechazados'] 
                : $resp['rechazados'] = array();
            }else{
                $resp = $vCamp;
                $resp['msj'] .= " Todos los campos rechazados.";
                return $resp;
            }
        }
        
    }else{
        // Si existe el $_id
        // Se verifica si existe algo en $_where
        if(!empty($_where)){
            $where = $_where." AND ".$_tabla['id']." = '$_id'";
        }else{
            $where = " WHERE ".$_tabla['id']." = '$_id'";
        }

        // Se verifica si se pidieron campos
        if (empty($_campos)) {
            // Si no se pidieron los campos se devuelven TODOS para ese $_id
            $sql = "SELECT ".$_tabla['nombre'].".* $jStrCamp  FROM ".$_tabla['nombre']." $joins_sql $where".$fin_sql;
        }else{
            // Si se pidieron los campos se devuelven para ese $_id
            $validos = null;
            // Se obtienen los campos validos
            $vCamp = $_nauta->validaCampos($_tabla['nombre'], $_campos, $_bd);
            isset($vCamp['data']['validos'])
            ? $validos = $vCamp['data']['validos']
            : $validos = array();

            if($vCamp['status']==true && count($validos)>0){
                $lstCmp = [];
                foreach ($validos as $z) $lstCmp[] = TABLA['nombre'].".".$z; 
                // Se concatenan los campos validos para la consulta SELECT
                $strCamp = implode(",", $lstCmp);
                
                // Se crea la consulta 
                $sql = "SELECT $strCamp $jStrCamp  FROM ".$_tabla['nombre']." $joins_sql $where".$fin_sql;

                // Por ultimo se agregan los campos rechzados en caso de existir
                isset($vCamp['data']['rechazados']) 
                ? $resp['rechazados'] = $vCamp['data']['rechazados'] 
                : $resp['rechazados'] = array();
            }else{
                $resp = $vCamp;
                $resp['msj'] .= " Todos los campos rechazados.";
                return $resp;
            }

        }

    }
    
    return $_nauta->consultaSQL_asociativo($sql);

}




?>