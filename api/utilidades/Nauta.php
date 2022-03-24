<?php
define('RUTA_INI',$_SERVER['DOCUMENT_ROOT'].'/');
class nauta
{
/*
 * PROPIEDADES------------------------------------------------------------------------------
 */
    public  $conexion  = NULL;
	public  $conectado = NULL;
    private $base      = NULL;

	// Errores
	public $error_no       = 0;
	public $error_msj      = NULL;
	public $conx_error_no  = 0;
	public $conx_error_msj = NULL;

	//Resultados
	public $resultados = array();

    // Globales
    private static $TIPOS_PERMITIDOS = array(
        'jpg'=>'image/jpeg',
        'png'=>'image/png',
        'pdf'=>'application/pdf',
        'avi'=>'video/x-msvideo',
        'wav'=>'audio/x-wav',
        'mpeg'=>'video/x-mpeg',
        'mp4'=>'video/mp4',
        'mp3'=>'audio/mp3');
    // private static $PESO_MAX = 12000000000; //120 MB
    private static $PESO_MAX = 20000000; //20 MB
    private          $dirIni = NULL;
    private static       $rf = array();
    

/*
 * METODOS PARA EL MANEJO DE BD -----------------------------------------------------------
 */


/*****************
 *	CONSTRUCTOR  *
 *****************/
function __construct( $_bd, $_usuario=IREK, $ruta=RUTA_INI ) {
    $this->set_ruta_inicio($ruta);// Se da de alta la ruta de inicio
	$this->conexion = new mysqli($_usuario['serv'],$_usuario['us'],$_usuario['pass'],$_bd);
	mysqli_query($this->conexion,"SET NAMES 'utf8'");
	if($this->conexion->connect_error){
		$this->conectado = FALSE;
		$this->conx_error_no =  $this->conexion->connect_errno;
		$this->conx_error_msj = $this->conexion->connect_error;
		return FALSE;
	}else{
		$this->conectado = TRUE;
		$this->conx_error_msj = "Conexion exitosa!";
        $this->parametros = array();
        $this->base = $_bd;
		return TRUE;
	}
}


/**************
 *	INSERTAR  *
 **************/
//Creamos la función que tomara como parámetro la matriz campo => dato
public function insertar($tabla, $campos_datos){
    mysqli_set_charset( $this->conexion, "utf8");
    if(empty($tabla) || empty($campos_datos)){
        $this->resultados['status'] = FALSE;
        $this->resultados['msj'] = 'Los parametros no pueden estar vacios.';
        $this->resultados['sql'] = '';
        $this->resultados['data'] = NULL;
        $this->resultados['last_id'] = NULL;
		return $this->resultados;
    }

    // Se preparan los campos
    $pcamp = $this->preparar_campos($tabla,$campos_datos);

    if($pcamp['status']==TRUE){
        $sql = "INSERT INTO $tabla (".$pcamp['listos_claves'].") VALUES (".$pcamp['listos_valores'].");";
        //Insertamos los valores en cada campo
        if($this->conexion->query($sql) === TRUE){

            if($this->conexion->affected_rows > 0){
                $this->resultados['status']=TRUE;
                $this->resultados['msj']= "Registro CREADO con exito!";
                $this->resultados['sql'] = $sql;
                $this->resultados['data'] = NULL;
                $this->resultados['last_id'] = mysqli_insert_id($this->conexion);
                return $this->resultados;
            }else{
                $this->resultados['status'] = FALSE;
                $this->resultados['msj'] = "El registro NO pudo ser creado. La operacion no afecto ningun registro.";
                $this->resultados['sql']= $sql;
                $this->resultados['data'] = NULL;
                $this->resultados['last_id'] = NULL;
                return $this->resultados;
            }

        }else{
            $this->resultados['status'] = FALSE;
            $this->resultados['msj'] = "El registro NO pudo ser creado. ".$this->conexion->error;
            $this->resultados['sql']= $sql;
            $this->resultados['data'] = NULL;
            $this->resultados['last_id'] = NULL;
            return $this->resultados;
        }
    }else{
        $this->resultados['status'] = $pcamp['status'];
        $this->resultados['msj'] = $pcamp['msj'];
        $this->resultados['data']= $pcamp['rechazados'];
        $this->resultados['last_id'] = NULL;
        return $this->resultados;
    }


}//Fin insertar

/***************
 *	ELIMINAR  *
 ***************/
//funcion para eliminar un registro de una tabla
public function eliminar($tabla, $campoCve, $valor) {

    if(empty($tabla) || empty($campoCve) || empty($campoCve) ){
        $this->resultados['status']=FALSE;
        $this->resultados['msj'] = 'Los parametros no pueden estar vacios.';
        $this->resultados['sql']= '';
		return $this->resultados;
    }

    // Primero se comprueba la existencia del registro
    $cmp = $this->buscar($tabla,$campoCve,$valor);

    if($cmp['status']==FALSE||($cmp['status']==TRUE && $cmp['cant']==0)){
        $this->resultados['status']=FALSE;
        $this->resultados['msj']= "El registro a procesar no existe.";
        $this->resultados['data'] = $cmp;
        return $this->resultados;
    }

    // Se ejecuta la accion
	$sql = "DELETE FROM $tabla WHERE $campoCve = '$valor';";

	if($this->conexion->query($sql) === TRUE){
        if($this->conexion->affected_rows > 0){
            $this->resultados['status']=TRUE;
            $this->resultados['msj']= "Registro ELIMINADO con exito!";
            $this->resultados['sql'] = $sql;
            $this->resultados['data'] = NULL;
            return $this->resultados;
        }else{
            $this->resultados['status'] = FALSE;
            $this->resultados['msj'] = "El registro NO pudo ser eliminado. La operacion no afecto registros.";
            $this->resultados['sql']= $sql;
            $this->resultados['data'] = NULL;
            return $this->resultados;
        }
	}else{
	    $this->resultados['status'] = FALSE;
		$this->resultados['msj'] = "El registro NO pudo ser eliminado. ".$this->conexion->error;
        $this->resultados['sql']= $sql;
        $this->resultados['data'] = NULL;
		return $this->resultados;
	}

}//Fin eliminar


/******************
 *	ACTUALIZAR  *
 ******************/
 //funcion para actualizar un registro de una tabla
public function actualizar($tabla, $campoCve, $v, $campos_datos) {
    mysqli_set_charset( $this->conexion, "utf8");
    if(empty($tabla) || empty($campoCve) || empty($campoCve) || empty($campos_datos) ){
        $this->resultados['status']=FALSE;
        $this->resultados['msj'] = 'Los parametros no pueden estar vacios.';
        $this->resultados['sql']= '';
        $this->resultados['data']= NULL;
		return $this->resultados;
    }

    // Primero se comprueba la existencia del registro
    $cmp = $this->buscar($tabla,$campoCve,$v);

    if($cmp['status']==FALSE||($cmp['status']==TRUE && $cmp['cant']==0)){
        $this->resultados['status']=FALSE;
        $this->resultados['msj']= "El registro a procesar no existe.";
        $this->resultados['sql']= NULL;
        $this->resultados['data'] = $cmp;
        return $this->resultados;
    }

    // Se preparan los campos
    $pcamp = $this->preparar_campos($tabla,$campos_datos);
    if($pcamp['status']==TRUE){
        $sql = "UPDATE $tabla SET ".$pcamp['listos_actualiza']." WHERE $campoCve = '$v';";
        if($this->conexion->query($sql) === TRUE){
            if($this->conexion->affected_rows > 0){
                $this->resultados['status']=TRUE;
                $this->resultados['msj']= "Registro ACTUALIZADO con exito!";
                $this->resultados['sql']=$sql;
                $this->resultados['data']= NULL;
                return $this->resultados;
            }else{
                $this->resultados['status'] = TRUE;
                $this->resultados['msj'] = "No hay columnas afectadas por la accion. ".$this->conexion->error;
                $this->resultados['sql']= $sql;
                $this->resultados['data']= NULL;
                return $this->resultados;
            }
        }else{
            $this->resultados['status'] = FALSE;
            $this->resultados['msj'] = "El registro NO pudo ser actualizado. ".$this->conexion->error;
            $this->resultados['sql']= $sql;
            $this->resultados['data']= NULL;
            return $this->resultados;
        }
    }else{
        $this->resultados['status'] = $pcamp['status'];
        $this->resultados['msj'] = "Error al preparar los campos. ".$pcamp['msj'];
        $this->resultados['sql']= NULL;
        $this->resultados['data']= $pcamp['rechazados'];
        return $this->resultados;
    }

}//Fin actualizar


/************
 *	BUSCAR  *
 ************/
 //funcion para buscar un registro de una tabla
public function buscar($tabla, $campoCve, $valor) {
    //mysqli_set_charset( $this->conexion, "utf8");
    if(empty($tabla) || empty($campoCve) || empty($valor) ){
        $this->resultados['status']=FALSE;
        $this->resultados['msj'] = 'Los parametros no pueden estar vacios.';
        $this->resultados['sql']= '';
        $this->resultados['data'] = NULL;
        $this->resultados['data_row'] = NULL;
        $this->resultados['cant'] = NULL;
		return $this->resultados;
    }

	$sql = "SELECT * FROM $tabla WHERE $campoCve = '$valor' ;";
	$res = $this->conexion->query($sql);
	if ($res === FALSE) {
		$this->resultados['status']=FALSE;
        $this->resultados['msj'] = "Error al intentar la busqueda. ".$this->conexion->error;
        $this->resultados['sql']= $sql;
        $this->resultados['data'] = NULL;
        $this->resultados['data_row'] = NULL;
        $this->resultados['cant'] = NULL;
        
	}else{
        if ($res->num_rows > 0){
            $this->resultados['status']=TRUE;
            $this->resultados['msj'] = "Consulta exitosa!";
            $this->resultados['sql']= $sql;
            $this->resultados['data'] = $res->fetch_assoc();
            $this->resultados['data_row'] = $res->fetch_row();
            $this->resultados['cant'] = $res->num_rows;
            // Se liberan los resultados
            $res->close();
            if($this->conexion->more_results()){
                $this->conexion->next_result();
            }
        }else{
            $this->resultados['status']=TRUE;
            $this->resultados['msj'] = "No existen registros para el criterio. ";
            $this->resultados['sql']= $sql;
            $this->resultados['data'] = NULL;
            $this->resultados['data_row'] = NULL;
            $this->resultados['cant'] = $res->num_rows;
            // Se liberan los resultados
            $res->close();
            if($this->conexion->more_results()){
                $this->conexion->next_result();
            }
        }
    }
    return $this->resultados;
}//Fin buscar


/*****************
 *	CONSULTA  *
 *****************/
 //funcion para obtener un todos los registros de una tabla
public function todos_tabla($tabla) {
    mysqli_set_charset( $this->conexion, "utf8");
    if(empty($tabla) ){
        $this->resultados['status']=FALSE;
        $this->resultados['msj'] = 'Los parametros no pueden estar vacios.';
        $this->resultados['sql']= '';
        $this->resultados['data'] = NULL;
		return $this->resultados;
    }

	$sql = "SELECT * FROM $tabla;";
	$res = $this->conexion->query($sql);
	if ($res === FALSE){
		$this->resultados['status']=FALSE;
        $this->resultados['msj'] = "Error al buscar los registros en la tabla. ".$this->conexion->error;
        $this->resultados['sql']= $sql;
        $this->resultados['data'] = NULL;
        $this->resultados['cant'] = NULL;
	}else{
        if($res->num_rows>0){
            for ($datos = array (); $fila = $res->fetch_assoc(); $datos[] = $fila);
            $this->resultados['status']=TRUE;
            $this->resultados['msj'] = "Consulta ejecutada con exito!!!";
            $this->resultados['sql']= $sql;
            $this->resultados['data'] = $datos;
            $this->resultados['cant'] = $res->num_rows;
            // Se liberan los resultados
            $res->close();
            if($this->conexion->more_results()){
                $this->conexion->next_result();
            }
        }else{
            $this->resultados['status']=TRUE;
            $this->resultados['msj'] = "No hay registros para la consulta sobre la tabla.";
            $this->resultados['sql']= $sql;
            $this->resultados['data'] = NULL;
            $this->resultados['cant'] = $res->num_rows;
            // Se liberan los resultados
            $res->close();
            if($this->conexion->more_results()){
                $this->conexion->next_result();
            }
        }

    }    
    return $this->resultados;
}//Fin todos


/*****************
 *	 EJECUTAR    *
 *****************/
 //funcion para ejecutar una consulta en la BD
public function consultaSQL($sql) {
    mysqli_set_charset( $this->conexion, "utf8"); //formato de datos utf8
    
    if(empty($sql) ){
        $this->resultados['status'] = FALSE;
        $this->resultados['msj']    = 'Los parametros no pueden estar vacios.';
        $this->resultados['sql']    = '';
        $this->resultados['data']   = NULL;
        $this->resultados['cant']   = NULL;
		return $this->resultados;
    }

	$res = $this->conexion->query($sql);
	if ($res === FALSE){
		$this->resultados['status'] = FALSE;
        $this->resultados['msj']    = 'Error al intentar la consulta. '.$this->conexion->error;
        $this->resultados['sql']    = $sql;
        $this->resultados['data']   = NULL;
        $this->resultados['cant']   = NULL;
    }elseif ($res === true) {
        $this->resultados['status'] = true;
        $this->resultados['msj']    = "Consulta DML ejecutada con exito!!!.";
        $this->resultados['sql']    = $sql;
        $this->resultados['data']   = null;
        $this->resultados['cant']   = 0;
    }else{
        if($this->conexion->affected_rows > 0){
            for ($datos = array (); $fila = $res->fetch_row(); $datos[] = $fila);
            $this->resultados['status'] = TRUE;
            $this->resultados['msj']    = "Consulta ejecutada con exito!!!";
            $this->resultados['sql']    = $sql;
            $this->resultados['data']   = $datos;
            $this->resultados['cant']   = $this->conexion->affected_rows;
            // Se liberan los resultados
            $res->close();
            if($this->conexion->more_results()){
                $this->conexion->next_result();
            }
        }else{
            $this->resultados['status'] = TRUE;
            $this->resultados['msj']    = 'Consulta ejecutada con exito!!!. No hay resultados para la consulta. '.$this->conexion->error;
            $this->resultados['sql']    = $sql;
            $this->resultados['data']   = NULL;
            $this->resultados['cant']   = $this->conexion->affected_rows;
            // Se liberan los resultados
            $res->close();
            if($this->conexion->more_results()){
                $this->conexion->next_result();
            }
        }

    }
    
    return $this->resultados;
}//Fin EJECUTAR


/*****************
 *	EJECUTAR II  *
 *****************/
//funcion para ejecutar una consulta en la BD
public function consultaSQL_asociativo($sql) {
    mysqli_set_charset( $this->conexion, "utf8"); //formato de datos utf8

    if(empty($sql) ){
        $this->resultados['status'] = false;
        $this->resultados['msj']    = 'Los parametros no pueden estar vacios.';
        $this->resultados['sql']    = '';
        $this->resultados['data']   = null;
        $this->resultados['cant']   = null;
        return $this->resultados;
    }

    $res = $this->conexion->query($sql);
	if ($res === false){
        $this->resultados['status'] = false;
		$this->resultados['msj']    = 'Ha ocurrido un error. '.$this->conexion->error;
        $this->resultados['sql']    = $sql;
        $this->resultados['data']   = null;
        $this->resultados['cant']   = null;
	}elseif ($res === true) {
        $this->resultados['status'] = true;
        $this->resultados['msj']    = "Consulta DML ejecutada con exito!!!.";
        $this->resultados['sql']    = $sql;
        $this->resultados['data']   = null;
        $this->resultados['cant']   = 0;
    }else{
        if($this->conexion->affected_rows > 0){
            for ($datos = array(); $fila = $res->fetch_assoc(); $datos[] = $fila);
            $this->resultados['status'] = true;
            $this->resultados['msj']    = "Consulta ejecutada con exito!!!";            
            $this->resultados['sql']    = $sql;
            $this->resultados['data']   = $datos;
            $this->resultados['cant']   = $this->conexion->affected_rows;
            // Se liberan los resultados
            $res->close();
            if($this->conexion->more_results()){
                $this->conexion->next_result();
            }
        }else{
            $this->resultados['status'] = true;
            $this->resultados['msj']    = 'Consulta ejecutada con exito!!!. No hay resultados para la consulta. '.$this->conexion->error;
            $this->resultados['sql']    = $sql;
            $this->resultados['data']   = null;
            $this->resultados['cant']   = $this->conexion->affected_rows;
            // Se liberan los resultados
            $res->close();
            if($this->conexion->more_results()){
                $this->conexion->next_result();
            }
        }
    }
    
    return $this->resultados;
}//Fin EJECUTAR

 /****************
  *	 ULTIMO ID   *
  ****************/
 // Retorna el ultimo Id insertado en una tabla
 public function ultimo_id($tabla, $columna) {
     //mysqli_set_charset( $this->conexion, "utf8"); //formato de datos utf8

     if( empty($tabla) || empty($columna) ){
         $this->resultados['status']=FALSE;
         $this->resultados['msj'] = 'Los parametros no pueden estar vacios.';
         $this->resultados['sql']= '';
         $this->resultados['data'] = NULL;
     }else{
         $sql="SELECT * FROM $tabla ORDER BY $columna DESC LIMIT 1;";// Se prepara la cadena de consulta
         $res = $this->conexion->query($sql);
         if ($res === FALSE){
             $this->resultados['status']=FALSE;
             $this->resultados['msj'] = $this->conexion->error;
             $this->resultados['sql']= $sql;
             $this->resultados['data'] = $res;
         }else{
             //guardamos en un array multidimensional todos los datos de la consulta
             if($res->num_rows > 0){
                 $fila = $res->fetch_assoc();
                 $this->resultados['status']=TRUE;
                 $this->resultados['msj'] = "Consulta ejecutada con exito!!!";
                 $this->resultados['sql']= $sql;
                 $this->resultados['data'] = $fila[$columna];
             }else{
                 $this->resultados['status']=TRUE;
                 $this->resultados['msj'] = 'No hay resultados para la consulta del Id. '.$this->conexion->error;
                 $this->resultados['sql']= $sql;
                 $this->resultados['data'] = $res;
             }

         }
     }
     return $this->resultados;
 }//Fin ULTIMO ID


/**********************
 *	LIBERAR CONEXION  *
 **********************/
 //Funcion para liberar la conexion y que se pueda utilizar para el siguiente comando SELECT
public function liberar_conexion(){
	$this->clearStoredResults($this->conexion);
}

//------------------------------------------
private function clearStoredResults($mysqli_link){
	//------------------------------------------
	while($mysqli_link->next_result()){
		  if($l_result = $mysqli_link->store_result()){
				  $l_result->free();
		  }
	}
}


/***********************************
 *	Combinar arreglos asociativos  *
 ***********************************/
//Funcion para insertar valores en arreglos asociativos
public static function array_push_assoc(array &$arrayDatos, array $values) {
	$arrayDatos = array_merge($arrayDatos, $values);
}



 /*********************************
 *	Almacenar objeto en arreglo   *
 **********************************/
// Almacena los campos del objeto datos en un arreglo
public static function almacenar_objeto_arreglo(array &$_arr, $_obj, $_tabla){
    foreach ($_obj as $c => $v) {
        // Si el dato se corresponde con una columna de la tabla
        // entonces se agrega al listado de datos por cargar
        if(in_array($c, $_tabla )){
            nauta::array_push_assoc($_arr,array($c => $v));
        }
    }
}

 /*********************************
 *	Prepara un listado de campos  *
 **********************************/
/* ********************************************************************
 * Retorna un arreglo con las columnas pertenecientes a la tabla.
 * Ejemplo:
 *
 *  Array    (
            [listos] => Array(
                            [Id_Exp] => 1
                            [AMaterno] => Materno
                            [Nombre] => Nombre
                        )
            [listos_claves] => "Id_Exp,AMaterno,Nombre"
            [listos_valores] => "'1','Materno','Nombre'"
            [rechazados] => Array(
                            [CUR] => AAAA123456789012345678
                            [APaerno] => Paterno
                        )

            [listos_tot] => 3
            [rechazados_tot] => 2
            [status] => TRUE
            [msj] => Preparacion correcta.
    )
 *
 * Para poder ejecutar esta funcion es necesario crear un objeto NAUTA.
***********************************************************************/
public function preparar_campos($_tabla, $_lista){
    $obj_res = array();
    $listos = array();
    $rechazados = array();
    $rechazados_columnas = array();
    $sql = '';
    $tmp = NULL;
    $str = NULL;
    // Se inicializa el arreglo
    $obj_res['listos'] = NULL;
    $obj_res['listos_claves'] = NULL;
    $obj_res['listos_valores'] = NULL;
    $obj_res['listos_actualiza'] = NULL;
    $obj_res['listos_tot'] = NULL;
    $obj_res['rechazados'] = NULL;
    $obj_res['rechazados_tot'] = NULL;
    $obj_res['status'] = NULL;
    $obj_res['msj'] = NULL;

    if(empty($_tabla) || empty($_lista)){// Si los parametros estan vacios
        // Se retorna un objeto vacio
        $obj_res['status'] = FALSE;
        $obj_res['msj'] = 'Llamada con parametros vacíos.';
        return $obj_res;
    }

    $sql=
    "SELECT "
        ."cl.COLUMN_NAME,"
        ."cl.DATA_TYPE,"
        ."cl.CHARACTER_MAXIMUM_LENGTH,"
        ."cl.NUMERIC_PRECISION,"
        ."cl.DATETIME_PRECISION,"
        ."cl.COLUMN_COMMENT "
    ."FROM information_schema.COLUMNS as cl "
    ."WHERE cl.TABLE_SCHEMA LIKE '$this->base' "
    ."AND cl.TABLE_NAME LIKE '$_tabla'; ";

    $tmp = $this->buscar('information_schema.COLUMNS', 'TABLE_NAME', $_tabla);$this->limpia_resultados();
    if($tmp['status']===TRUE){// Si la tabla existe en la Base de Datos

        //------------ Se obtiene las columnas --------------------
        $resp_sql = $this->consultaSQL_asociativo($sql);$this->limpia_resultados();
        $objetos = $resp_sql['data'];
        $ColumnasTabla = array();
        foreach($objetos as $columna){
            $ColumnasTabla[] = $columna['COLUMN_NAME'];
        }
        // --------------------------------------------------------
        

        //$obj_res['originales'] = $_lista;// Solo DEBUG
        // Se depositan en la lista solo las columnas que existan en la tabla
        foreach($_lista as $campo => $valor){
            if(in_array($campo,$ColumnasTabla)){// Se prepara el dato segun el valor
                if(is_null($valor)||empty($valor)){
                    $dato = "NULL";
                }elseif(is_bool($valor)){
                    if($valor===TRUE){
                        $dato = '1';
                    }else{
                        $dato = '0';
                    }
                }else{
                    $dato = "'".$valor."'";
                }
                $str .= $campo."=".$dato.",";
                $obj_res['listos_actualiza'] = trim($str, ',');
                $this->array_push_assoc($listos, array($campo => $dato));
            }else{
                $this->array_push_assoc($rechazados, array($campo => $valor));
                $rechazados_columnas[]= $campo;
            }
        }

        $obj_res['listos'] = $listos;
        $obj_res['listos_claves'] = implode(',',array_keys($obj_res['listos']));
        reset($obj_res['listos']);
        $obj_res['listos_valores'] = implode(',',$obj_res['listos']);

        $obj_res['listos_tot']=count($obj_res['listos']);
        $obj_res['rechazados'] = $rechazados;
        $obj_res['rechazados_tot']=count($obj_res['rechazados']);

        if($obj_res['listos_tot']>0 && $obj_res['rechazados_tot']<=0){// Si existen columnas pertenecientes a la tabla retorna TRUE
            $obj_res['status'] =TRUE;
            $obj_res['msj']='Preparacion correcta.';
        }elseif($obj_res['rechazados_tot']>0 && $obj_res['listos_tot']<=0){
            $obj_res['status'] =FALSE;
            $obj_res['msj']='Ninguna columna se corresponde con las de la tabla: '.$_tabla.'. Columnas: '.implode(',',$rechazados_columnas);
        }elseif($obj_res['rechazados_tot']>0 && $obj_res['listos_tot']>0){
            $obj_res['status'] =FALSE;
            $obj_res['msj']='Algunas columnas no existen en la tabla: '.$_tabla.'. Columnas: '.implode(',',$rechazados_columnas);
        }

        return $obj_res;// Retorna el objeto resultados
    }else{
        $obj_res['status']=FALSE;
        $obj_res['msj'] = 'La tabla no existe en la base de datos '.$this->base.'. '.$this->conexion->error;
        $obj_res['listos_tot']= 0;
        $obj_res['rechazados_tot'] = 0;
        return $obj_res;
    }
}

/**
 * Muestra la estructura de la tabla solicitada
 */
public function estructuraTabla($_tabla, $_base = null){
    if(empty($_base)){
        $_base = $this->base;
    }

    $sql=
    "SELECT "
        ."cl.COLUMN_NAME,"
        ."cl.DATA_TYPE,"
        ."cl.CHARACTER_MAXIMUM_LENGTH,"
        ."cl.NUMERIC_PRECISION,"
        ."cl.DATETIME_PRECISION,"
        ."cl.COLUMN_KEY,"
        ."cl.COLUMN_COMMENT "
    ."FROM information_schema.COLUMNS as cl "
    ."WHERE cl.TABLE_SCHEMA LIKE '$_base' "
    ."AND cl.TABLE_NAME LIKE '$_tabla'; ";

    $resp_sql = $this->consultaSQL_asociativo($sql);

    if ($resp_sql['status']==true && $resp_sql['cant']>0) {
        $this->resultados = $resp_sql;
    }else{
        $this->resultados['status'] =  $resp_sql['status'];
        $this->resultados['msj']    =  "Error al buscar informacion de la tabla '$_tabla', verifique el nombre.";
        $this->resultados['data']   =  null;
        $this->resultados['cant']   =  $resp_sql['cant'];
    }

    return $this->resultados;

}

/**
 * Valida si los campos de la $_lista, existen en la $_tabla
 */
public function validaCampos($_tabla, $_lista, $_base = null){
    $campos = null;

    if(empty($_tabla)){
        $this->resultados['status'] = false;
        $this->resultados['msj']    = "Falta el nombre de la Tabla";
        $this->resultados['data']   = null;
        return $this->resultados;
    }

    if(empty($_base)){
        $this->resultados['status'] = false;
        $this->resultados['msj']    = "Falta el nombre de la Base";
        $this->resultados['data']   = null;
        return $this->resultados;
    }

    if(empty($_base)){
        $_base = $this->base;
    }

    // Se obtiene la estructura de la tabla
    $estrc = $this->estructuraTabla($_tabla, $_base);

    // Se existe la tabla
    if ($estrc['status']==true && $estrc['cant']>0) {
        // Se separan los campos de la tabla
        $campos_tabla = null;
        foreach ($estrc['data'] as $value) {
            $campos_tabla[] = $value['COLUMN_NAME'];
        }

        
        // Se comparan los campos de la tabla con los de la lista
        for ($i=0; $i < count($_lista) ; $i++) { 
            // Se verifican si existen los campos de la lista en la tabla
            if ( in_array($_lista[$i], $campos_tabla) ) {
                $campos['validos'][] = $_lista[$i];
            } else {
                $campos['rechazados'][] = $_lista[$i];
            }
        }
        
        
        $this->resultados['status'] = true;
        $this->resultados['msj']    = "Campos validados.";
        $this->resultados['sql']    = null;
        $this->resultados['data']   = $campos;
        $this->resultados['cant']   = count($_lista);
        
    }else{
        $this->resultados =  $estrc;
    }

    return $this->resultados;

}



// Limpia la propiedad resultados
private function limpia_resultados(){
    $this->resultados = array();
}

/* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 * ++++++++++++++++++++++++++++++++  SECCION PARA EL MANEJO DE ARCHIVOS  ++++++++++++++++++++++++++++++++++++++++++++++++++++++
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 * +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/



public function set_ruta_inicio($_rutaInicio=RUTA_INI) {
    $this->dirIni = $_rutaInicio;
}

public function get_ruta_inicio() {
    return $this->dirIni;
}

public function get_tipos_permitidos(){
    return $this->TIPOS_PERMITIDOS;
}

// Para copiar las carpetas y subcarpetas
public static function copiar( $orig, $dest ) {
    if ( is_dir( $orig ) ) {
        @mkdir( $dest,0777,TRUE );
        $d = dir( $orig );
        while ( FALSE !== ( $dentro = $d->read() ) ) {
            if ( $dentro == '.' || $dentro == '..' ) {
                continue;
            }
            $Dentro = $orig . '/' . $dentro;
            if ( is_dir( $Dentro ) ) {
                self::copiar( $Dentro, $dest . '/' . $dentro );
                continue;
            }
            copy( $Dentro, $dest.'/'.$dentro );
        }

        $d->close();

    }else {
        copy( $orig, $dest );
    }
}

// Crea la estructura de carpetas del expediente electronico
public static function crea_estructura($nombre_carpeta){
    $origen = self::$dirIni."PLANTILLA";
    $destino = self::$dirIni."$nombre_carpeta";
    self::copiar($origen, $destino);
    if(file_exists($destino)===TRUE){
        self::$rf['status'] = TRUE;
        self::$rf['msj']="Carpeta creada con exito!.";
    }else{
        self::$rf['status'] = FALSE;
        self::$rf['msj']="Fallo al crear la carpeta.";
    }

    return self::$rf;
}

// Crea una carpeta con la ruta otorgada
public static function crea_carpeta($_ruta){
    // Validamos si la ruta de destino existe, en caso de no existir la creamos
    if(!file_exists($_ruta)){
        if(mkdir($_ruta, 0777)){
            self::$rf['status'] = TRUE;
            self::$rf['msj']    = 'Carpeta creada con exito. '.$_ruta;
            self::$rf['data']   = null;
            return self::$rf;
        }else{
            self::$rf['status'] = FALSE;
            self::$rf['msj']    = 'La carpeta '.$_ruta.' no pudo ser creada, verifiquela.';
            self::$rf['data']   = null;
            return self::$rf;
        }
    }else{
        self::$rf['status'] = FALSE;
        self::$rf['msj']    = 'La carpeta '.$_ruta.' ya existe.';
        self::$rf['data']   = null;
        return self::$rf;
    }
}

// Renombra una carpeta o archivo
public static function renombrar($viejo_nom,$nuevo_nom){
    if(rename($viejo_nom, $nuevo_nom)===TRUE){
        self::$rf['status'] = TRUE;
        self::$rf['msj']="Archivo o Carpeta renombrados con exito!.";
    }else{
        self::$rf['status'] = FALSE;
        self::$rf['msj']="Error al intentar renombrar el archivo o carpeta.";
    }
    return self::$rf;
}



/******************************************************************************************************
 *  Carga un archivo en el servidor 
 ******************************************************************************************************
 * Esta funcion solo sera utilizada para cargar archivos en el servidor y crear un registro en la base 
 * de datos del nombre, ruta y ruta vista previa.
 *
 * Parametros de la funcion:
 *  - ruta            = Lugar en el directorio donde se guardara el archivo.
 *  - ruta_vista_prev = Direccion tipo url para mostrar la vista previa de la imagen en un control html.
 *
 * Opcionales:
 *  - tabla     = Nombre de la tabla de la base de datos donde se guardarán nombre, ruta y ruta vista
 *                previa, en caso de no indicarlo se tomará la tabla 'multimedia'.
 *         Nota: se tomara la base de datos con la que fue creado el objeto NAUTA.
 *  - nom_archv = Nombre para el archivo, sino se indica se crea un nombre predefinido.
 *  - datos     = Arreglo (campo=>valor) de campos adicionales que se guardan en la tabla indicada en el
 *                parametro 'tabla'.
 *
 * Esta funcion copia la imagen a la carpeta que indica la variable 'ruta'. Y retorna TRUE hubo exito y 
 * FALSE en caso contrario.
 * ***************************************************************************************************/
public function carga_archivos(
    $ruta, 
    $ruta_vista_prev, 
    $tabla     = "multimedia", 
    $nom_archv = null,
    $datos     = null
    ){
    
    // Variables globales de apoyo
    $campos = array();
    $msj    = "";
    
    // Validacion de la estructura de la tabla. La tabla debe contener por lo menos
    // los campos de "Nombre", "Ruta" ,"Vista_previa".
    $list_campos = array('Nombre'=>NULL,'Ruta'=>NULL,'Vista_previa'=>NULL);
    $a = $this->preparar_campos($tabla,$list_campos);
    if( $a['status'] == FALSE ){
        self::$rf['status']   = FALSE;
        self::$rf['msj']      = 'La estructura de la tabla '.$tabla.' no es valida. '.$a['msj'].' Columnas: '.implode(',',$a['rechazados']);
        self::$rf['Archivos'] = null;
        self::$rf['BD']       = null;
        self::$rf['last_id']  = null;
        return self::$rf; // Se interrumpe la funcion
    }

    // Validacion de la ruta
    if( !is_dir($ruta) || (strlen($ruta)<=0) ){
        self::$rf['status']   = FALSE;
        self::$rf['msj']      = 'La ruta '.$ruta.' destino no valida o no existe.';
        self::$rf['Archivos'] = null;
        self::$rf['BD']       = null;
        self::$rf['last_id']  = null;
        return self::$rf; // Se interrumpe la funcion
    }

    // Se valida el campo ruta_vista_previa
    if( empty($ruta_vista_prev) ){
        self::$rf['status']   = FALSE;
        self::$rf['msj']      = "Fala el campo 'ruta vista previa'.";
        self::$rf['Archivos'] = null;
        self::$rf['BD']       = null;
        self::$rf['last_id']  = null;
        return self::$rf; // Se interrumpe la funcion
    }

    // Validar si existen archivos a subir
    if(empty($_FILES)){
        self::$rf['status']   = FALSE;
        self::$rf['msj']      = 'No hay archivos para cargar.';
        self::$rf['Archivos'] = null;
        self::$rf['BD']       = null;
        self::$rf['last_id']  = null;
        return self::$rf; // Se interrumpe la funcion
    }else{

        // Ejecutar la accion por cada archivo cargado
        foreach($_FILES as $cve=>$val){
            
            if(is_array($_FILES[$cve]['tmp_name'])){// En caso de Multiples archivos
                // NO se procesan archivos multiples, solo cargas individuales
                self::$rf['status']   = FALSE;
                self::$rf['msj']      = 'No se permiten archivos multiples.';
                self::$rf['Archivos'] = null;
                self::$rf['BD']       = null;
                self::$rf['last_id']  = null;
                return self::$rf; // Se interrumpe la funcion
            }else{// En caso de un solo archivo

                $vf = self::valida_archivo($cve);// Se valida el archivo

                if( $vf['status']==TRUE ){
                    self::$rf['status'] = TRUE;

                    //:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
                    //:::::::::::::::::: SECCION NOMBRE DE ARCHIVO ::::::::::::::::::::::::::::::::::::::::
                    //:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

                    // Se preparan las variables para cargar el archivo y guardar el registro en la base
                    $trozos      = explode(".", $_FILES[$cve]['name']);
                    $ext         = strtolower(end($trozos));
                    $nombre_temp = $_FILES[$cve]["tmp_name"];
                    $dir         = opendir($ruta);
                    $nom_archivo = "archivo_def";


                    // En caso de existir un nombre personalizado para el archivo ($nom_archv)
                    if( !is_null($nom_archv) ){
                        /* // Se valida que no exista un registro en la BD con ese nombre
                        $bNom = $this->buscar($tabla, 'Nombre', $nom_archv);
                        if ($bNom['status']==true && $bNom['cant']>=1) {
                            self::$rf['status']   = false;
                            self::$rf['msj']      = "Imposible cargar el archivo $nom_archv. Ya existe ese nombre en la BD. Cambie el nombre e intente nuevamente.";
                            self::$rf['Archivos'] = null;
                            self::$rf['BD']       = null;
                            self::$rf['last_id']  = null;
                            return self::$rf;
                        }else{
                            $nom_archivo = $nom_archv;
                        } */
                        $nom_archivo = $nom_archv;
                    }else{
                        $nom_archivo = "Nave_".time();
                    }

                    //Se forma el nombre del archivo
                    $rDestino_nArchivo_Ext = $ruta.$nom_archivo.'.'.$ext;
                    $rVPrevia_nArchivo_Ext = $ruta_vista_prev.$nom_archivo.'.'.$ext;

                    //:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
                    //:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
                    //:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

                    // Se cargan los datos que se quieren insertar o actualizar en el arreglo $campos, 
                    // para cargarlos en la base de datos
                    if(!empty($datos)){
                        $campos = $datos;
                    }
                    // nauta::array_push_assoc($campos,array($campo_cve => $valor_cve));
                    nauta::array_push_assoc($campos,array('Nombre'       => $nom_archivo));
                    nauta::array_push_assoc($campos,array('Ruta'         => $rDestino_nArchivo_Ext));
                    nauta::array_push_assoc($campos,array('Vista_previa' => $rVPrevia_nArchivo_Ext));

                    $columnas = array();
                    $valores  = array();
                    $acc      = "";

                    // SI existe: sobreescribe el archivo en el disco y actualiza los datos en la BD
                    if( file_exists($rDestino_nArchivo_Ext) ){
                            
                        // Se carga el archivo
                        if( move_uploaded_file($nombre_temp, $rDestino_nArchivo_Ext) ) {
                            self::$rf['status']                   = TRUE;
                            self::$rf['Archivos'][$cve]['status'] = TRUE;
                            self::$rf['Archivos'][$cve]['msj']    = 'El archivo '.$nom_archivo.' cargado exitosamente.';
                            $msj .= " Cargado($nom_archivo).";

                            $p = $this->buscar($tabla, "Nombre" ,$nom_archivo);
                            // print_r($p);

                            if ($p['cant'] <= 0) {
                                // No hay registro en la BD para con ese nombre de archivo
                                // entonces se elimina el archivo del servidor.
                                $this->borra_archivo($rDestino_nArchivo_Ext);
                                self::$rf['BD'][$cve]['status']  = false;
                                self::$rf['BD'][$cve]['msj']     = "No existe registro en la BD para el archivo: ".$nom_archivo.". Se procedió a borrar el archivo.";
                                self::$rf['BD'][$cve]['last_id'] = null;
                                return self::$rf;
                            }

                            foreach ($p['data'] as $key => $value) {
                                $columnas[] = $key;
                                $valores[]  = $value;
                            }

                            nauta::array_push_assoc($campos,array($columnas[0]=>$valores[0]));
                            
                            $r   = $this->actualizar($tabla, $columnas[0] ,$valores[0], $campos);// Se ACTUALIZA un registro en la tabla

                            if($r['status']===true){
                                self::$rf['BD'][$cve]['status'] = true;
                                self::$rf['BD'][$cve]['msj']    = "Actualizado con exito. ".$nom_archivo;
                            }else{
                                self::$rf['BD'][$cve]['status'] = false;
                                self::$rf['BD'][$cve]['msj']    = "No se pudo actualizar el registro en la BD para . ".$nom_archivo.". ".$r['msj'];
                            }
                            self::$rf['last_id'] = $valores[0];
                            
                        } else {
                            self::$rf['status']                   = false;
                            self::$rf['Archivos'][$cve]['status'] = false;
                            self::$rf['Archivos'][$cve]['msj']    = 'No se pudo cargar el archivo '.$nom_archivo;
                            self::$rf['BD']                       = null;
                            self::$rf['last_id']                  = null;
                            $msj .= " Error($nom_archivo).";
                        }
                    }else{// NO existe: escribe el archivo en disco e inserta un registro nuevo en la bd
                        // Se carga el archivo
                        if(move_uploaded_file($nombre_temp, $rDestino_nArchivo_Ext)) {
                            self::$rf['status']                   = TRUE;
                            self::$rf['Archivos'][$cve]['status'] = TRUE;
                            self::$rf['Archivos'][$cve]['msj']    = 'El archivo '.$nom_archivo.' cargado exitosamente.';
                            $msj .= " Cargado($nom_archivo).";

                            $r   = $this->insertar($tabla,$campos);// Se inserta un registro en la tabla
                            $acc = " Insertado ";

                            if($r['status']===TRUE){
                                self::$rf['BD'][$cve]['status']  = TRUE;
                                self::$rf['BD'][$cve]['msj']     = "Registrado con exito. ".$nom_archivo;
                                self::$rf['BD'][$cve]['last_id'] = $r['last_id'];
                                self::$rf['last_id']             = $r['last_id'];
                            }else{
                                self::$rf['BD'][$cve]['status']  = FALSE;
                                self::$rf['BD'][$cve]['msj']     = "No se pudo crear el registro en la BD para . ".$nom_archivo.'. '.$r['msj'];
                                self::$rf['BD'][$cve]['last_id'] = $r['last_id'];
                                self::$rf['last_id']             = $r['last_id'];
                            }

                        } else {
                            self::$rf['status']                   = FALSE;
                            self::$rf['Archivos'][$cve]['status'] = FALSE;
                            self::$rf['Archivos'][$cve]['msj']    = 'Error al intentar cargar el archivo '.$nom_archivo;
                            self::$rf['BD']                       = null;
                            self::$rf['last_id']                  = null;
                            $msj .= " Error($nom_archivo).";
                        }
                            
                    }

                    closedir($dir);

                }else{
                    self::$rf['status'] = FALSE;
                    self::$rf['Archivos'] = null;
                    self::$rf['BD']       = null;
                    self::$rf['last_id']  = null;
                    $msj .= $vf['msj'];
                }
            }// End if(is_array($_FILES[$cve]['tmp_name']))
        }// End For

    }// End if(empty($_FILES))

    // Se retorna el resultado
    self::$rf['msj'] = $msj;
    return self::$rf;

}

/**************************
 *	VERIFICA EL ARCHIVO   *
 **************************
 * Parametros de la funcion:
 *
 * $_input = objeto $_FILE
 *
 * Esta funcion verifica que el objeto input file
 * contenga archivos validos. Existencia, carga, peso, tipo.
 * */
public static function valida_archivo($_input){
    $resp = array();
    try {

        // Verificar que no exceda el peso maximo permitido.
        $peso = $_FILES[$_input]['size'];
        if (($peso > self::$PESO_MAX)||($peso <= 0)) {
            $resp['status'] = FALSE;
            $resp['msj'] = 'El peso del archivo ('.$_input.')= '.$peso.' NO es permitido. Max = '.self::$PESO_MAX;
            return $resp;
        }

        // Verificar el nombre del archivo por seguridad
        if(!preg_match("`^[-0-9A-Z_\.]+$`i",$_FILES[$_input]['name'])){
            $resp['status'] = FALSE;
            $resp['msj'] = 'Nombre de archivo invalido, intente cambiar el nombre.';
            return $resp;
        }

        // Verificar que el tipo sea permitido
        $_tipo = $_FILES[$_input]['type'];
        if(!in_array($_tipo,self::$TIPOS_PERMITIDOS)) {
            $resp['status'] = FALSE;
            $resp['msj'] = 'Tipo de archivo no permitido. ';
            return $resp;
        }

        // En caso de no ocurrir ningun error se retorna valido
        $resp['status'] = TRUE;
        $resp['msj'] = 'Archivo permitido.';
        $resp['Files_obj'] = $_FILES;

        // Se retorna el resultado
        return $resp;

    }
    catch (RuntimeException $e) {
        $resp['status'] = FALSE;
        $resp['msj'] = 'Error: '.$e->getMessage();
        return $resp;
    }
}



/******************************************
 *	BORRA EL ARCHIVO DEL SERVIDOR  *
 ******************************************
 * Parametros de la funcion:
 *
 * $r = lugar en el directorio donde se guardara el archivo
 *
 * Esta funcion borra el archivo del disco duro segun la ruta pasada
 * como parametro.
 * */
function borra_archivo($r){
    if(unlink($r)){
        self::$rf['status'] = TRUE;
        self::$rf['msj'] = 'Archivo eliminado con exito.';
        return self::$rf;
    }else{
        self::$rf['status'] = FALSE;
        self::$rf['msj'] = 'Error al intentar borrar el archivo.';
        self::$rf['ruta'] = 'La ruta destino es ='.$r;
        return self::$rf;
    }

}

/************************************************************************
 *	BORRA EL DIRECTORIO DEL SERVIDOR
 ************************************************************************
 * Parametros de la funcion:
 *
 * $_folder = lugar en el directorio donde se guardara el archivo
 *
 * Esta funcion borra el direcorio con los archivos incluidos
 * del disco duro segun la ruta pasada como parametro. 
 * Nota: Si no se envia el parametro $_folder se eliminara el directorio
 *       configurado en dirIni.
 *************************************************************************/
function borra_carpeta($_folder=''){
    $dir = $this->dirIni.$_folder.'/';// Armamos la ruta completa
    if(!empty($dir)){
        if(is_dir($dir)){
            $lst_arch = scandir($dir); // Lista de archivos del directorio
            $cant     = count($lst_arch);
    
            if($cant>=1){// Directorio lleno, borra los archivos dentro
    
                foreach ($lst_arch as $narch) {
                    if(!($narch == '.' || $narch == '..' )){
                        if(!unlink($dir.$narch)){
                            self::$rf['status'] = FALSE;
                            self::$rf['msj']    = 'Error al intentar borrar los archivos del directorio. ';
                            self::$rf['ruta']   = 'La ruta destino es = '.$dir;
                            return self::$rf;
                        }
                    }
    
                }
    
            }
    
            if(rmdir($dir)){// Se borra el directorio
                self::$rf['status'] = TRUE;
                self::$rf['msj']    = 'Directorio eliminado con exito. ';
                self::$rf['ruta']   = 'La ruta destino es = '.$dir;
            }else{
                self::$rf['status'] = FALSE;
                self::$rf['msj']    = 'Error al eliminar el directorio. ';
                self::$rf['ruta']   = 'La ruta destino es = '.$dir;
            }
            return self::$rf;
        }else{
            self::$rf['status'] = FALSE;
            self::$rf['msj']    = 'La carpeta no existe.';
            self::$rf['ruta']   = 'La ruta destino es = '.$dir;
            return self::$rf;
        }
    }else{
        self::$rf['status'] = FALSE;
        self::$rf['msj']    = 'Directorio de inicio no esta configurado (dirIni).';
        self::$rf['ruta']   = 'La ruta destino es = '.$dir;
        return self::$rf;
    }
    
}





}//Fin de clase

?>