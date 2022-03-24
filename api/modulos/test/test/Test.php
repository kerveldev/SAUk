<?php

function peticion($peticion){
  $cuerpo = PETICION_NO_IMPLEMENTADA;
  
  switch ($peticion) {
    // :::::::::::::::::::::::::::::::::::::: Area Nuevo ::::::::::::::::::::::::::::::::::::::::::
    case 'test_nuevo':
      $fields = array("nick","token","datos");// Lista de parametros por recibir
      $box    = new Storer($fields);
      if(empty($x = $box->stocker)){return $cuerpo = FALTAN_PARAMETROS;}// Si retorna null sale de la peticion
      
      $cuerpo = peticion_insertar(
        $x->nick, $x->token, TEST['base'], 
        "modulos_grupo", 
        (array)$x->datos
      );
    
      break;

    case 'test_nuevo_carpeta':
      $fields = array("nick","token","datos");// Lista de parametros por recibir
      $box    = new Storer($fields);
      if(empty($x = $box->stocker)){return $cuerpo = FALTAN_PARAMETROS;}// Si retorna null sale de la peticion
      
      $ruta = $_SERVER['DOCUMENT_ROOT']  ."/test";

      $cuerpo = peticion_insertar_carpeta(
        $x->nick, $x->token, TEST['base'], 
        "modulos_grupo", "Id_Grupo",
        (array)$x->datos, TEST['ruta']
      );
    
      break;
    
    case 'test_carga_archivo':// Crea un archivo en el servidor
        
        $fields = array("nick","token");// Lista de parametros por recibir
        $box = new Storer($fields,TRUE);
        if(empty($x = $box->stocker)){return $cuerpo = FALTAN_PARAMETROS;}// Si retorna null sale de la peticion

        // print_r($box);

        $rt   = TEST['ruta'];
        $rtvp = TEST['ruta_web'];

        $_nombre   = "imgPrueba";

        $d=array(
            "Tipo_archivo" => "IMAGEN", 
            "Tabla"        => "navegantes",
            "Tabla_Id"     => "2"
                );
        
        return peticion_insertar_archivo(
          $x->nick, 
          $x->token, 
          TEST['base'],
          $rt, 
          $rtvp,
          'multimedia',
          $_nombre,
          $d
        );


      break;

    

    // ::::::::::::::::::::::::::::::::::::: Area Elimina :::::::::::::::::::::::::::::::::::::::::
    case 'test_elimina':
      $fields = array("nick","token","id");// Lista de parametros por recibir
      $box    = new Storer($fields);
      if(empty($x = $box->stocker)){return $cuerpo = FALTAN_PARAMETROS;}// Si retorna null sale de la peticion
      
      $cuerpo = peticion_eliminar(
        $x->nick, $x->token, TEST['base'],
        "modulos_grupo", "Id_Grupo", $x->id
      );
      
    
      break;

    case 'test_elimina_archivo':// Crea un archivo en el servidor
        
        $fields = array("nick","token");// Lista de parametros por recibir
        $box = new Storer($fields,TRUE);
        if(empty($x = $box->stocker)){return $cuerpo = FALTAN_PARAMETROS;}// Si retorna null sale de la peticion

        $_nombre   = "imgPrueba";

        return peticion_eliminar_archivo(
          $x->nick, 
          $x->token, 
          TEST['base'],
          'multimedia',
          $_nombre,
          
        );


      break;

    // :::::::::::::::::::::::::::::::::: Area Actualizaciones ::::::::::::::::::::::::::::::::::::
    case 'test_actualiza':
      $fields = array("nick","token","datos");// Lista de parametros por recibir
      $box    = new Storer($fields);
      if(empty($x = $box->stocker)){return $cuerpo = FALTAN_PARAMETROS;}// Si retorna null sale de la peticion
      
      $cuerpo = peticion_actualizar(
        $x->nick, $x->token, TEST['base'],
        "modulos",
        "Id_Modulo", $x->datos->Id_Modulo,
        (array)$x->datos
      );
    
      break;
    
    case 'test_consultaSQL':
      $fields = array("nick","token");// Lista de parametros por recibir
      $box    = new Storer($fields);
      if(empty($x = $box->stocker)){return $cuerpo = FALTAN_PARAMETROS;}// Si retorna null sale de la peticion

      // $sql    = "UPDATE modulos_grupo SET UCrea = 2 WHERE Id_Grupo = 13;";
      $sql    = "SELECT * FROM modulos_grupo;";
      $cuerpo = peticion_estandar($x->nick, $x->token, TEST['base'], $sql);
    
      break;

    // ::::::::::::::::::::::::::::::::::::: Area Consultas :::::::::::::::::::::::::::::::::::::::
    case 'test_lst':
      $fields = array("nick","token");// Lista de parametros por recibir
      $box    = new Storer($fields);
      if(empty($x = $box->stocker)){return $cuerpo = FALTAN_PARAMETROS;}// Si retorna null sale de la peticion

      $sql    = "SELECT * FROM modulos;";
      $cuerpo = peticion_estandar($x->nick, $x->token, TEST['base'], $sql);

      break;
    
    // ::::::::::::::::::::::::::::::::::: Area Logica (Otros) ::::::::::::::::::::::::::::::::::::




    default:
      // No existe la peticion
      $cuerpo = PETICION_INVALIDA;
      break;
  }// Fin switch peticion
    
    return $cuerpo;
}// Fin funcion recurso

// :::::::::::::::::::::::::::::::::: FUNCIONES AUXILIARES :::::::::::::::::::::::::::::::::::::

?>