<?php
if ( include_once($_SERVER["DOCUMENT_ROOT"]."/api/apiconfig/cnx_cfg.php") ){
    if ( include_once($_SERVER["DOCUMENT_ROOT"]."/api/utilidades/Nauta.php") ){
        $nave = new nauta("sau");
    
        $bsq = $nave->consultaSQL_asociativo("SELECT Id_Usuario FROM navegantes WHERE nick LIKE '".$_GET['nick']."';");
        $_id = $bsq['data'][0]['Id_Usuario'];
    
        $_links = $nave->consultaSQL_asociativo("
        SELECT 
         l.Id_Link,
         m.Ruta
        FROM links l
        LEFT JOIN modulos m ON(m.Id_Modulo = l.Id_Modulo)
        WHERE 
         l.Id_Usuario = '$_id' 
         AND l.Id_Fuente = '1' 
         AND l.Principal = '1'");
        
        if($_links['status']==true){
            header('Location: '.$_links['data'][0]['Ruta']);
        }else{
            header('Location: http://sau.test/');
        }
        
    }else{
        echo "Imposible cargar Nauta";
        exit();
    }
}else{
    echo "Imposible cargar CNX";
    exit();
}




?>