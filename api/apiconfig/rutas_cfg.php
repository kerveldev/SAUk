<?php
/* ***************************************
 *      MODULOS
 * ***************************************/

define('USUARIOS',[
      'base'        => 'sau',
      'ruta'        => ROOT.'multimedia/',
      'ruta_web'    => ROOT_WEB.'multimedia/',
      'controlador' => MODULOS.'usuarios/usuarios_ctrl.php',
      'logger'      => MODULOS.'usuarios/logger/Logger.php',
      'navegante'   => MODULOS.'usuarios/navegantes/Navegante.php',
      'modulo'      => MODULOS.'usuarios/modulos/Modulo.php',
      'grupo'       => MODULOS.'usuarios/grupos/Grupo.php',
      'nivel'       => MODULOS.'usuarios/niveles/Nivel.php',
      'link'        => MODULOS.'usuarios/links/Link.php',
      'fuentes'     => MODULOS.'usuarios/fuentes/Fuentes.php'
 ]);

define('TEST',[
      'base'        => 'sau',
      'ruta'        => ROOT.'testImg/',
      'ruta_web'    => ROOT_WEB.'testImg/',
      'controlador' => MODULOS.'test/test_ctrl.php',
      'test'        => MODULOS.'test/test/Test.php'
 ]);


?>