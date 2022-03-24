<?php

/* ******************************************
 *      Internas                            *
 * ******************************************/
define('IREK',[
            'serv' => 'localhost',
            'us'   => 'sigpol_irek',
            'pass' => '123ilich@irek'
    ]);

// define('ROOT',$_SERVER['DOCUMENT_ROOT'].'/nauta/');
define('ROOT',$_SERVER['DOCUMENT_ROOT'].'/');
// define('ROOT_WEB','https://c5.sigpol.com/');
define('ROOT_WEB','sau.test/');
define('INDEX','sau.test');

define('API',ROOT.'api/');
define('API_CONFIG',API.'apiconfig/');
define('MSJ',API_CONFIG.'msj_cfg.php');
define('RUTAS',API_CONFIG.'rutas_cfg.php');


define('MODULOS',API.'modulos/');

define('UTILIDADES',API.'utilidades/');
define('AUXCTRL',API.'aux_tcontrol.php');
define('NAUTA',UTILIDADES.'Nauta.php');
define('STORER',UTILIDADES.'Storer.php');
define('EXCEPCIONES',UTILIDADES.'ExcepcionApi.php');
define('QRLIB',UTILIDADES.'phpqrcode/qrlib.php');
define('FPDF',UTILIDADES.'fpdf181/fpdf.php');

define('VISTA_JSON',API.'salidas/VistaJson.php');

?>