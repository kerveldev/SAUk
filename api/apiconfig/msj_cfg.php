<?php
/* **************************************
 *      Constantes de estado            *
 * **************************************/
const ESTADO_URL_INCORRECTA = 2;
//const ESTADO_EXISTENCIA_RECURSO = 3;

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> BASE DE DATOS ----------------------------------------------------------------------------------------
const ERROR_CONEXION_BD = [
     'status' => FALSE,
     'msj'    => 'Error al concectar con la base de datos.',
     'data'   => NULL
     ];




// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> VALIDACIONES ------------------------------------------------------------------------------------------
const USUARIO_TOKEN_INVALIDO = [
     'status' => FALSE,
     'msj'    => 'Usuario invalido/Falta token.',
     'data'   => NULL
     ];

const CHECKUSER_INVALIDO = [
     'status' => FALSE,
     'msj'    => 'Nauta - checkuser - dice: ',
     'data'   => NULL
     ];

const FALLO_CONSULTA_SQL = [
     'status' => FALSE,
     'msj'    => 'Nauta - consultaSQL - dice: ',
     'data'   => NULL
     ];

const ERROR_ESTRUCTURA_TABLA = [
     'status' => FALSE,
     'msj'    => 'Nauta - estructuraTabla - dice: ',
     'data'   => NULL
     ];
     
const NAUTA_INVALIDO = [
     'status' => FALSE,
     'msj'    => 'No se encuentra la libreria NAUTA',
     'data'   => NULL
     ];

const MODULO_PRINCIPAL_EXISTENTE = [
     'status' => FALSE,
     'msj'    => 'No pueden existir DOS modulos PRINCIPALES para la misma Fuente o Dispositivo',
     'data'   => NULL
     ];




//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> CABECERA ----------------------------------------------------------------------------------------------
const CONTENIDO_NO_PERMITIDO = [
     'status' => FALSE,
     'msj'    => 'El contenido no es permitido solo: JSON o FORM-DATA.',
     'data'   => NULL
     ];





// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ERRORES EN JSON ---------------------------------------------------------------------------------------
const JSON_ERR_DEPTH = [
     'status' => FALSE,
     'msj'    => 'JSON ha dicho - Excedido tamaño máximo de la pila',
     'data'   => NULL
     ];

const JSON_ERR_STATE_MISMATCH = [
     'status' => FALSE,
     'msj'    => 'JSON ha dicho - Desbordamiento de buffer o los modos no coinciden',
     'data'   => NULL
     ];
const JSON_ERR_CTRL_CHAR = [
     'status' => FALSE,
     'msj'    => 'JSON ha dicho - Encontrado carácter de control no esperado',
     'data'   => NULL
     ];
const JSON_ERR_SYNTAX = [
     'status' => FALSE,
     'msj'    => 'JSON ha dicho - Error de sintaxis, JSON mal formado',
     'data'   => NULL
     ];
const JSON_ERR_UTF8 = [
     'status' => FALSE,
     'msj'    => 'JSON ha dicho - Caracteres UTF-8 malformados, posiblemente codificados de forma incorrecta',
     'data'   => NULL
     ];
const JSON_ERR_DESCONOCIDO = [
     'status' => FALSE,
     'msj'    => 'JSON ha dicho - Error desconocido',
     'data'   => NULL
     ];





// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> METODO ------------------------------------------------------------------------------------------------
const METODO_NO_IMPLEMENTADO = [
     'status' => FALSE,
     'msj'    => 'Metodo no implementado.',
     'data'   => NULL
     ];

const METODO_NO_PERMITIDO = [
     'status' => FALSE,
     'msj'    => 'Metodo no permitido.',
     'data'   => NULL
     ];






// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> MODULO -------------------------------------------------------------------------------------------------
const MODULO_NO_IMPLEMENTADO = [
     'status' => FALSE,
     'msj'    => 'Modulo no implementado.',
     'data'   => NULL
     ];
const MODULO_NO_EXISTENTE = [
     'status' => FALSE,
     'msj'    => 'Modulo no existente.',
     'data'   => NULL
     ];






// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> RECURSO ------------------------------------------------------------------------------------------------
const RECURSO_NO_IMPLEMENTADO = [
     'status' => FALSE,
     'msj'    => 'Recurso no implementado.',
     'data'   => NULL
     ];
const RECURSO_NO_EXISTE = [
     'status' => FALSE,
     'msj'    => 'Recurso no existente.',
     'data'   => NULL
     ];






// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> PETICION -------------------------------------------------------------------------------------------------
const PETICION_INVALIDA = [
     'status' => FALSE,
     'msj'    => 'La peticion es invalida o no es compatible con el metodo solicitado.',
     'data'   => NULL
     ];

const PETICION_NO_IMPLEMENTADA = [
     'status' => FALSE,
     'msj'    => 'La peticion no implementada.',
     'data'   => NULL
     ];

const ERROR_PETICION_ESTANDAR = [
     'status' => FALSE,
     'msj'    => 'PETICION ESTANDAR: ',
     'data'   => NULL
     ];

const ERROR_PETICION_ACTUALIZAR = [
     'status' => FALSE,
     'msj'    => 'PETICION ACTUALIZAR: ',
     'data'   => NULL
     ];

const ERROR_PETICION_INSERTAR = [
     'status' => FALSE,
     'msj'    => 'PETICION INSERTAR: ',
     'data'   => NULL
     ];

const ERROR_PETICION_INSERTAR_CARPETA = [
     'status' => FALSE,
     'msj'    => 'PETICION INSERTAR-CARPETA: ',
     'data'   => NULL
     ];

const ERROR_PETICION_INSERTAR_ARCHIVO = [
     'status' => FALSE,
     'msj'    => 'PETICION INSERTAR-ARCHIVO: ',
     'data'   => NULL
     ];

const ERROR_PETICION_ELIMINAR = [
     'status' => FALSE,
     'msj'    => 'PETICION ELIMINAR: ',
     'data'   => NULL
     ];





// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> PARAMETROS --------------------------------------------------------------------------------------------------
const FALTAN_PARAMETROS = [
     'status' => FALSE,
     'msj'    => 'Faltan Parametros para procesar la peticion.',
     'data'   => NULL
     ];

const FALTAN_PARAMETROS_ACTIVO = [
     'status' => FALSE,
     'msj'    => 'Faltan Parametros para procesar la peticion.',
     'data'   => NULL
     ];

const NO_HAY_ARCHIVOS = [
     'status' => FALSE,
     'msj'    => "No existen Archivos a procesar.",
     'data'   => NULL
     ];

const NICK_INVALIDO = [
     'status' => FALSE,
     'msj'    => 'Falta el nombre de Usuario.',
     'data'   => NULL
     ];

const PASS_INVALIDO = [
     'status' => FALSE,
     'msj'    => 'Falta la Contraseña.',
     'data'   => NULL
     ];

const TOKEN_INVALIDO = [
     'status' => FALSE,
     'msj'    => 'Falta el Token.',
     'data'   => NULL
     ];

const BD_INVALIDO = [
     'status' => FALSE,
     'msj'    => 'Falta nombre de la BD',
     'data'   => NULL
     ];

const SQL_INVALIDO = [
     'status' => FALSE,
     'msj'    => 'Falta la consulta SQL',
     'data'   => NULL
     ];

const TABLA_INVALIDO = [
     'status' => FALSE,
     'msj'    => 'Falta el nombre de la TABLA',
     'data'   => NULL
     ];

const ID_TABLA_INVALIDO = [
     'status' => FALSE,
     'msj'    => 'Falta el ID de la tabla',
     'data'   => NULL
     ];

const ID_VALOR_INVALIDO = [
     'status' => FALSE,
     'msj'    => 'Falta el valor para el ID',
     'data'   => NULL
     ];

const DATOS_INVALIDO = [
     'status' => FALSE,
     'msj'    => 'Faltan los DATOS a procesar',
     'data'   => NULL
     ];

const RUTA_INVALIDA = [
     'status' => FALSE,
     'msj'    => 'Falta la RUTA a procesar',
     'data'   => NULL
     ];

const RUTA_VISTA_PREVIA_INVALIDA = [
     'status' => FALSE,
     'msj'    => 'Falta la ruta VISTA PREVIA a procesar',
     'data'   => NULL
     ];

const CAMPO_TIPO_INVALIDO = [
     'status' => FALSE,
     'msj'    => 'Falta el campo TIPO',
     'data'   => NULL
     ];

const NOMBRE_ARCHIVO_INVALIDO = [
     'status' => FALSE,
     'msj'    => 'Falta el NOMBRE del archivo a procesar',
     'data'   => NULL
     ];

     

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> CONTROLADORES -----------------------------------------------------------------------------------------
const ERROR_CONTROLADOR = [
     'status' => FALSE,
     'msj'    => 'Error al cargar el controlador.',
     'data'   => NULL
     ];


// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> SESIONES ----------------------------------------------------------------------------------------------
const SESION_CADUCADA = [
     'status' => TRUE,
     'msj'    => "La sesion ha caducado. Ingrese nuevamente.",
     'data'   => NULL
     ];

const SESION_ACTIVA = [
     'status' => TRUE,
     'msj'    => "La sesion sigue activa.",
     'data'   => NULL
     ];




?>