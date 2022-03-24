<?php
// error_reporting(E_ALL);
// ini_set('display_errors', '1');

use function PHPSTORM_META\type;

error_reporting(0);
ini_set('date.timezone','MEXICO/GENERAL');

require_once("apiconfig/cnx_cfg.php");
require_once(NAUTA);
require_once(STORER);
require_once(EXCEPCIONES);
require_once(VISTA_JSON);
require_once(MSJ);
require_once(RUTAS);
require_once(AUXCTRL);

//require_once(USUARIOS['logger']);

$vista    = NULL;
$noemp    = NULL;
$modulo   = NULL;// Este es el modulo al que pertenece la peticion
$recurso  = NULL;// Esta es el grupo al que pertenece la peticion 'consultar', 'modificar', 'crear' o 'eliminar'
$peticion = NULL;// Petición a ejecutar
//$accion   = NULL;
$nick     = NULL;
$token    = NULL;
$url = array();

// EL formato en que se retorna la vista es JSON
$vista = new VistaJson();

// Preparar manejo de excepciones
set_exception_handler(function ($exception) use ($vista) {
    // print_r($exception);// DEBUG
    $cuerpo  = array();
    if (!isset($exception->estado)) {
        $cuerpo = array(
            "status" => 400,
            "msj"    => $exception->getMessage(),
            "data"   => null
        );
    }else{
        $cuerpo = array(
            "status" => $exception->estado,
            "msj"    => $exception->getMessage(),
            "data"   => null
        );
    }
    
    
    if ($exception->getCode()) {
        $vista->est = $exception->getCode();
    } else {
        $vista->est = 500;
    }

    $vista->imprimir($cuerpo);
});


// Extraer segmento de la url
if (isset($_GET['PATH_INFO']))
    $url = explode('/', $_GET['PATH_INFO']);
else
    throw new ExcepcionApi(ESTADO_URL_INCORRECTA, utf8_encode("No existe el endPoint"));

// Se obtiene el metodo
$metodo = strtolower($_SERVER['REQUEST_METHOD']);

// GET, PATCH, PUT y DELETE no es permitidos
if ( $metodo !='post' ) {
    $vista->est=405;
    $vista->imprimir(METODO_NO_PERMITIDO);
    exit();
};

// Obtener modulo
$modulo = strtolower(array_shift($url));

// Obtener recurso
$recurso = array_shift($url);

// Obtener peticion
$peticion = array_shift($url);


// echo "Modulo = $modulo, Recurso = $recurso, Peticion = ".$peticion; //-DEBUG-


/* **************************************************************************************
 * ************************* Se procesa el modulo ***************************************
 * **************************************************************************************/
switch($modulo){

    // ----------------------------------------------------------------------------
    // ----- USUARIOS -------------------------------------------------------------
    // ----------------------------------------------------------------------------
    case 'usuarios':
        $v = include_once(USUARIOS['controlador']);
        if($v==FALSE){
            $vista->est = 400;
            $vista->imprimir(ERROR_CONTROLADOR);
        }
        break;

    // ----------------------------------------------------------------------------
    // ----- TEST -----------------------------------------------------------------
    // ----------------------------------------------------------------------------
    case 'test':
        $v = include_once(TEST['controlador']);
        if($v==FALSE){
            $vista->est = 400;
            $vista->imprimir(ERROR_CONTROLADOR);
        }
        break;

    // ----------------------------------------------------------------------------
    // ----- No existe el MODULO --------------------------------------------------
    // ----------------------------------------------------------------------------
    default:
        $vista->est = 400;
        $vista->imprimir(MODULO_NO_EXISTENTE);

}// Fin switch

?>